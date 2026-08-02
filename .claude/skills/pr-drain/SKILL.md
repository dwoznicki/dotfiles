---
name: pr-drain
description: Sweep every open PR you author and drive each to its next state — dispatch swarms to CI, fix conflicts and red CI, harvest and fix review findings, re-request review, mark green PRs ready — then report the short list needing your decision. Fast fire-and-collect passes, designed to run on a loop. Use for "drain my PRs", "what needs me", or "check my open PRs".
user_invocable: true
argument-hint: "[--report] [--pr <n>] [--needs-me] [--local]"
---

# PR drain

Your open PRs accumulate faster than you check them. This drains the queue in
**short passes** and hands back only what needs your judgment.

## Execution model: fire-and-collect, not block-and-wait

The expensive part of draining a PR is the **review** (~16 min per swarm run,
measured). The cheap parts are classifying, fixing, and pushing.

So never block on a review. **Dispatch it to CI and collect the result on a later
pass.** `review-swarm.yml` runs on GitHub's runners:

- **Off your box.** Your machine has 8 cores → a 6-agent cap, and one swarm spawns
  8 lanes. Local swarms already saturate it; running two PRs at once just makes
  both slower. Local parallelism is not available. CI's is.
- **Parallel across PRs.** All 9 stale PRs can swarm simultaneously on GitHub.
- **Two triggers:** automatically on `ready_for_review`, or any time by posting a
  `/review-swarm` comment (`review-swarm-listen.yml` dispatches it — works on
  drafts too).

A drain pass is therefore **minutes**, not hours: it fires what needs firing,
harvests what has landed, and exits. Pair it with `/loop 30m /pr-drain` and the
queue drains itself.

**Cost:** ~$0.50–$2 per CI swarm. A first full sweep of a stale queue is real money
(9 PRs ≈ $10–20); steady state is near-zero because only moved SHAs re-dispatch.
Say what you're about to spend if dispatching more than ~5 at once.

Composes `pr-resolve` (fix conventions) and `pr-swarm-fix` (the local, blocking
alternative — use it when actively iterating on one PR and you want the findings
now). Don't reimplement either.

## Arguments

- *(none)* — full pass: classify, dispatch, harvest, fix, report.
- `--report` — classify and report only. No dispatches, no pushes. Good first run.
- `--pr <n>` — one PR.
- `--needs-me` — print the outstanding decision list and exit.
- `--local` — run swarms locally via `pr-swarm-fix` instead of dispatching to CI.
  Slow (~16 min each, serial). Only when CI is unavailable.

## Step 1 — Classify (seconds, read-only)

```bash
gh pr list --author "@me" --state open --limit 100 \
  --json number,title,isDraft,headRefName,baseRefName,updatedAt,\
mergeable,mergeStateStatus,reviewDecision,labels,statusCheckRollup
```

**Compute swarm coverage per PR** — this is what decides whether a review is owed,
and it's the check that keeps the sweep cheap. Compare the last commit's
`committedDate` against the most recent Review Swarm review's `submittedAt`:

```bash
gh pr view <n> --json commits,reviews
```

- last swarm **≥** last push → **covered**, no review needed
- pushed after the last swarm → **stale**
- no swarm review at all → **never swarmed**

On a typical queue most PRs are already covered (13 of 22, when this was written)
— skipping those is the difference between a 2-minute pass and an all-day one.

Bucket each PR, first match wins:

| Bucket | Condition | Action |
|---|---|---|
| **Needs you** | unresolved thread that's a question, scope call, or worth pushing back on | none — Step 4 |
| **Findings to fix** | swarm/reviewer findings not yet addressed | fix + re-dispatch (Step 3) |
| **Conflicts** | `mergeable == CONFLICTING` | `pr-resolve --conflicts`, then re-dispatch |
| **CI red** | failing aggregate check | `pr-resolve --ci`, then re-dispatch |
| **Awaiting swarm** | swarm dispatched, no result yet | skip — collect next pass |
| **Needs swarm** | stale or never swarmed | dispatch (Step 2) |
| **Ready** | covered, clean, CI green, draft | mark ready (Step 2) |
| **Mergeable** | ready, approved, no conflicts | report only — never merge |

Print the classification before acting.

## Step 2 — Dispatch and mark ready

**Dispatch a swarm** for anything stale or never-swarmed:

```bash
gh pr comment <n> --body "/review-swarm"
```

Returns immediately. Record that you dispatched it (and the head SHA at dispatch)
so the next pass knows what it's waiting for and doesn't double-fire.

**Mark ready** when the PR is covered by a clean swarm at the current head SHA and
CI is green:

```bash
gh pr ready <n>
```

This is the one status change allowed — **never move a PR back to draft**, ever.

Marking ready **auto-fires a CI swarm** on that SHA, so it doubles as a dispatch.
That's the design: the swarm that would have caught something is now running
before any human looks. Don't use `no-review-swarm` to dodge it.

Two guards on marking ready:
- Only when the last **completed, clean** swarm covers the **current** head SHA.
- Never with unresolved Critical/High/Medium findings.
- The `review-swarmed` label is **not** evidence of either — it's re-applied every
  pass regardless of outcome. Judge by the coverage comparison in Step 1.

## Step 3 — Harvest findings and fix

For each PR whose swarm has landed since the last pass (author `github-actions`,
or a coworker's), and for human review comments:

1. **Split the findings:**
   - **Mechanical** — real defect, missing test, convention violation, concrete
     suggested change → fix.
   - **Judgment** — a question, scope challenge, architectural opinion, or
     anything you'd push back on → Step 4. Never guess, and never implement a
     change you think is wrong just to clear a thread.
2. **Fix the mechanical ones** via `pr-resolve --comments` (owns the conventions:
   follow-up commits, no force-push, pre-commit, no summary comment). Reject wrong
   findings with a one-line rationale; track rejections so they aren't re-litigated
   next pass.
3. **Re-dispatch after pushing.** The CI trigger is `[opened, ready_for_review,
   reopened]` — **not** `synchronize` — so your fix commit is *not* automatically
   re-reviewed. Post `/review-swarm` again to cover the new SHA. Skipping this is
   how unreviewed code reaches a human.
4. **Re-request review** from any human reviewer so the ball is visibly theirs:
   ```bash
   gh pr edit <n> --add-reviewer <login>
   ```
5. **Don't auto-resolve threads** — that's the reviewer's call.

If a PR returns findings in the same area twice, stop looping and escalate to
Step 4: two rounds on one topic is a disagreement, not a defect.

## Step 4 — Track what needs you

Persist to `~/.claude/pr-drain/needs-me.md`, keyed by PR + thread, so items survive
passes and accumulate an age. Each pass: add new, drop resolved, age the rest.

```markdown
## PR #3690 — [OUT-7506] Bind Stripe setup to subscription
- **Waiting:** 4 days
- **Who:** @fred (review comment)
- **Decision:** Should the webhook retry on a failed setup, or fail closed?
- **My read:** fail closed — retrying double-charges. Low confidence, it's billing.
- **Link:** <thread url>
```

- One line for the decision, phrased as a question with options.
- **Always give your read and your confidence** — a recommendation takes ten
  seconds to accept; an open question takes ten minutes.
- Anything over 3 days sorts to the top, flagged.
- If Daniel would look at an entry and say "just do it," it shouldn't be here.

## Step 5 — Report

1. **Needs you (N)** — Step 4 list, oldest first. Say so plainly if empty.
2. **Drained (N)** — one line per PR: what it was, what you did, new state.
3. **In flight** — swarms dispatched and awaiting results (collect next pass), CI
   still running.
4. **Mergeable now** — **never merge.** Report and let Daniel do it.

Don't post any of this to Slack or the PRs. If he wants it in Slack, route it
through `slack-post`.

## On a loop

Idempotent — every pass re-derives state from GitHub. `/loop 30m /pr-drain` is the
intended mode: each pass collects the previous pass's swarms and fires the next
round. Report only what **changed** since the last pass plus new "needs you" items;
don't reprint a stable queue every 30 minutes.
