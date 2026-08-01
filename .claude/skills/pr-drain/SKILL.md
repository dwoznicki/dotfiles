---
name: pr-drain
description: Sweep every open PR you author and drive each one to its next state — fix conflicts and red CI, run the swarm before marking ready, fix incoming review comments and re-request review, mark green PRs ready — then report the short list of things that genuinely need your decision. Use for "drain my PRs", "what needs me", "check my open PRs", or on a loop.
user_invocable: true
argument-hint: "[--report] [--pr <n>] [--needs-me]"
---

# PR drain

Your open PRs accumulate faster than you check them — 15+ sitting in draft, some
idle for days, all of them green. This drains that queue autonomously and hands
back only what actually needs your judgment.

Three principles, in priority order:

1. **Quality up front beats a review cycle.** Every round trip starts with a
   finding that a swarm would have caught before anyone looked. Never mark a PR
   ready that hasn't been swarmed clean.
2. **Act on anything reversible.** Conflicts, red CI, mechanical review findings,
   marking ready — just do them and report. Don't stall a whole sweep on a
   four-second decision.
3. **Escalate only genuine decisions**, and make them impossible to lose track of.

Composes `pr-resolve`, `pr-swarm-fix`, and `review-swarm`. Don't reimplement them.

## Arguments

- *(none)* — full sweep: classify every open PR you author, act, report.
- `--report` — classify and report only. No pushes, no edits. Good first run.
- `--pr <n>` — drain a single PR.
- `--needs-me` — print the outstanding decision list and exit. No sweep.

## Step 1 — Classify (fast, read-only)

```bash
gh pr list --author "@me" --state open --limit 100 \
  --json number,title,isDraft,headRefName,baseRefName,createdAt,updatedAt,\
mergeable,mergeStateStatus,reviewDecision,labels,statusCheckRollup
```

For anything with review activity, also pull unresolved threads (the GraphQL
`reviewThreads` query in `pr-resolve` Step 3).

Bucket each PR. First match wins:

| Bucket | Condition | Action |
|---|---|---|
| **Needs you** | unresolved thread that's a question, a scope call, or a suggestion worth pushing back on | no action — Step 4 |
| **Review comments** | unresolved threads, all mechanical | review-fix loop (Step 3) |
| **Conflicts** | `mergeable == CONFLICTING` | `pr-resolve --conflicts` |
| **CI red** | failing aggregate check | `pr-resolve --ci` |
| **Unswarmed** | draft, CI green, no `review-swarmed` label | `pr-swarm-fix` → then Ready |
| **Ready** | draft, CI green, swarm clean | mark ready (Step 2) |
| **Mergeable** | ready, approved, no conflicts | report only — never merge |
| **In flight** | CI still running | skip this pass |

Work them in table order: someone waiting on you first, then what rots fastest.
Print the classification before acting so the plan is visible.

## Step 2 — Mark ready when green

Daniel has explicitly authorized this: **a draft whose CI is green and whose swarm
is clean gets marked ready** (`gh pr ready <n>`).

```bash
gh pr ready <n>
```

This is the one status change that's allowed. The standing rule that a PR is
**never moved back to draft** still holds absolutely — no `gh pr ready --undo`,
ever.

Two guards:
- **Never mark ready unswarmed.** If there's no `review-swarmed` label, run
  `pr-swarm-fix` first. A PR that goes out unswarmed is how a review cycle starts.
- **Never mark ready with unresolved findings** at Critical/High/Medium.

## Step 3 — The review-fix loop

When a reviewer (human or their AI swarm) leaves findings, close the loop in one
pass instead of over three days:

1. **Read every unresolved thread.** Split them:
   - **Mechanical** — a real defect, a missing test, a convention violation, a
     concrete suggested change. Fix it.
   - **Judgment** — a question, a scope challenge ("is this in scope?"), an
     architectural opinion, or anything you'd push back on. → Step 4. Do **not**
     guess at these, and do not implement a change you think is wrong just to
     clear a thread.
2. **Fix the mechanical ones** via `pr-resolve --comments` (it owns the
   conventions: follow-up commits, no force-push, pre-commit, no summary comment).
3. **Re-request review** so the ball is visibly back in their court — this is the
   step that actually ends the cycle:
   ```bash
   gh pr edit <n> --add-reviewer <original-reviewer-login>
   ```
4. **Don't auto-resolve the threads.** Resolving is the reviewer's call; doing it
   for them hides whether they agreed.

If a PR comes back a second time with findings in the same area, stop looping and
escalate it to Step 4 — two rounds on one topic means there's a disagreement, not
a defect.

## Step 4 — Track what needs you

The point of the sweep is that this list is *short* and *nothing falls off it*.

Persist to `~/.claude/pr-drain/needs-me.md`, keyed by PR + thread, so items survive
between runs and accumulate an age. Update it every sweep: add new items, drop
resolved ones, and age the rest.

Each entry:

```markdown
## PR #3690 — [OUT-7506] Bind Stripe setup to subscription
- **Waiting:** 4 days
- **Who:** @fred (review comment)
- **Decision:** Should the webhook retry on a failed setup, or fail closed?
- **My read:** fail closed — retrying double-charges. Low confidence, it's billing.
- **Link:** <thread url>
```

Rules that keep it useful:
- **One line for the decision**, phrased as a question with options — not a summary
  of the discussion.
- **Always give your read and your confidence.** A decision presented with a
  recommendation takes ten seconds; one presented as an open question takes ten
  minutes.
- **Age everything.** Anything over 3 days goes at the top and gets flagged.
- **Keep it to genuine decisions.** If it's on this list and Daniel would say "just
  do it," it shouldn't have been here — that's the failure mode to avoid.

## Step 5 — Report

Lead with the two things that matter:

1. **Needs you (N)** — the Step 4 list, oldest first. If empty, say so plainly.
2. **Drained (N)** — one line per PR: what it was, what you did, the new state.

Then, briefly: still in flight (CI running), and mergeable-now PRs.

**Never merge.** Merging is the one irreversible step; report that a PR is
mergeable and let Daniel do it.

Don't post any of this to Slack or the PRs — it's a report for him. (If he does
want it in Slack, route it through `slack-post`.)

## Running it on a loop

The sweep is idempotent and safe to repeat — every run re-derives state from
GitHub. `/loop 30m /pr-drain` keeps the queue drained continuously. On a loop,
report only what *changed* since the previous pass, plus any new "needs you"
items; don't re-print a stable queue every 30 minutes.
