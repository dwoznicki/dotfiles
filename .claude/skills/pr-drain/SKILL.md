---
name: pr-drain
description: Sweep every open PR you author and drive each as far as it can go without you — dispatch swarms to CI, fix conflicts and red CI, harvest and fix review findings, re-request review — then report which PRs are ready for you to mark ready, plus the short list needing your decision. Never changes draft state. Fast fire-and-collect passes, designed to run on a loop. Use for "drain my PRs", "what needs me", or "check my open PRs".
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
| **Ready to flip** | draft, CI green, clean swarm covers current SHA | **report only — Daniel flips it** (Step 2) |
| **Mergeable** | ready, approved, no conflicts | report only — never merge |

Print the classification before acting.

## Step 2 — Dispatch swarms; never touch draft state

**Never change a PR's draft/ready state.** No `gh pr ready`, no `gh pr ready
--undo`, in either direction. Flipping a PR out of draft is the moment Daniel says
"this is worth someone else's time," and he makes that call himself. The drain's
job is to get each PR *to* that line and tell him which ones are standing on it.

**Dispatch a swarm** for anything stale or never-swarmed:

```bash
gh pr comment <n> --body "/review-swarm"
```

Returns immediately. Record that you dispatched it (and the head SHA at dispatch)
so the next pass knows what it's waiting for and doesn't double-fire.

This comment path is what makes the no-flip rule workable. `review-swarm.yml`
auto-fires on `ready_for_review` — which now never happens on the drain's watch —
but `review-swarm-listen.yml` turns a `/review-swarm` comment into the same
workflow run, and it works on drafts. Coverage never depends on flipping anything.

**A PR is "ready to flip"** when all three hold. Report it; don't act on it:

- CI green (judge by the aggregate jobs, not shard rows), **and**
- the last **completed, clean** swarm covers the **current** head SHA, **and**
- no unresolved Critical/High/Medium findings.

The `review-swarmed` label is **not** evidence of any of those — it's re-applied on
every pass regardless of outcome. Judge by the Step 1 coverage comparison and
`pr-swarm-fix`'s report.

**When Daniel flips one, a CI swarm fires on that SHA** (`ready_for_review` is a
trigger; 18 of the last 25 merged PRs carry a `github-actions` swarm review). A
later pass sees those findings as an unharvested review — pick them up in Step 3
like any other. Don't use the `no-review-swarm` label to suppress the trigger; it
hides the review rather than improving the PR.

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

1. **Ready to flip (N)** — the PRs Daniel can mark ready right now. This is the
   headline: it's the one action the drain deliberately leaves to him, so it goes
   first and never gets buried. One line each — PR number, title, and *why* it
   qualifies (CI green + swarm clean at `<short-sha>`). Give him the command:

   ```bash
   gh pr ready <n>    # or the whole batch
   ```

2. **Needs you (N)** — Step 4 decision list, oldest first. Say so plainly if empty.
3. **Drained (N)** — one line per PR: what it was, what you did, new state.
4. **In flight** — swarms dispatched and awaiting results (collect next pass), CI
   still running.
5. **Mergeable now** — **never merge.** Report and let Daniel do it.

Don't post any of this to Slack or the PRs. If he wants it in Slack, route it
through `slack-brief`.

## On a loop

Idempotent — every pass re-derives state from GitHub. `/loop 30m /pr-drain` is the
intended mode: each pass collects the previous pass's swarms and fires the next
round. Report only what **changed** since the last pass — don't reprint a stable
queue every 30 minutes.

**Two exceptions to the changed-only rule**, because both are waiting on Daniel and
silence reads as "nothing to do":

- **Any PR newly entering "ready to flip"** is always announced, with the
  `gh pr ready` command.
- **The standing counts are always shown**, even when nothing changed — one line:
  `3 ready to flip · 2 need you · 4 in flight`. A count is cheap; a forgotten
  queue is what this skill exists to prevent.
