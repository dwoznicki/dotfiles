---
name: pr-swarm-fix
description: Harden a PR with repeated AI review before a human sees it — a review-swarm → fix → re-swarm loop (max 3 cycles) driving Critical/High/Medium to zero, then a final two-lane different-model gate (Fable + GPT-5.6). Posts findings to GitHub and pushes fixes as follow-up commits. Use for "run review-swarm and fix the findings", "harden this PR", or before marking a PR ready for review.
user_invocable: true
argument-hint: "<pr-url|number> [--sev=critical,high,medium] [--cycles=3] [--no-final] [--update-desc]"
---

# PR swarm-fix

Drive a PR to the point where a human reviewer — or their AI swarm — finds
nothing. One swarm pass does **not** get you there.

**Why one pass isn't enough — the concrete reason.** `.github/workflows/review-swarm.yml`
fires **automatically on `ready_for_review`**. A second swarm isn't optional or
hypothetical: the repo runs one on your PR the moment you mark it ready, on
`claude-opus-5[1m]` (the `REVIEW_SWARM_MODEL` repo var). Of the last 25 merged
PRs, **18 carry a `github-actions` Review Swarm review** — more than all
human-posted swarms combined.

That CI swarm reviews **your final SHA** — which your local swarm never saw. The
sequence that burns you:

> swarm the draft → fix findings → push (**new SHA**) → mark ready → CI swarms
> that new SHA → new findings → round trip

So the target isn't "N passes." It's: **the last local swarm must cover the exact
SHA you mark ready**, so CI's independent pass finds nothing. Anything you push
after your last clean swarm is unreviewed code that CI *will* review.

A secondary effect: same-SHA re-runs still differ (LLM sampling), and a different
model has a different blind spot — which is what the optional final gate is for.
That's diminishing returns; the SHA alignment above is the real lever.

This costs real machine time (three swarm cycles plus a two-lane final review can
run 30–60 min). That's the trade: burn machine time to avoid a human round trip
that costs days.

Composes `review-swarm` (the 8-lane reviewer) and `pr-resolve` (push conventions).
Don't reimplement either.

## Arguments

- **PR** (required): URL or bare number.
- `--sev=<list>` — severities that gate the loop. Default `critical,high,medium`.
  **Low/nit never gates** — note them, don't let them force another cycle.
- `--cycles=<n>` — max swarm cycles. Default 3.
- `--no-final` — skip the Fable + GPT-5.6 gate (loop only).
- `--update-desc` — refresh PR title/body at the end.

## House rules (inherited)

From `pr-resolve`, non-negotiable: **never re-draft an open PR**, **never
force-push** (fixes are follow-up commits + plain `git push`), **conflicts get
`git merge main`, not rebase**, **no summary comment after pushing**, **run
pre-commit before every push**. And: **never push red** — tests pass before each
cycle's push.

## Step 1 — Preflight

```bash
gh auth status
gh pr view <pr> --json number,title,url,state,isDraft,author,headRefName,baseRefName
```

Stop if not `OPEN`. Get onto the PR's branch in a **committable** checkout (not a
detached worktree — you push from here), clean tree. Being on the branch clean is
what lets `review-swarm` reuse this worktree instead of spinning up its own.

## Step 2 — The swarm loop (max `--cycles`, default 3)

Run **non-interactively** — never stop to ask mid-loop:

- Invoke `review-swarm` with the **PR number**.
- You're the PR author, so GitHub rejects `--approve`/`--request-changes` (422).
  Take `review-swarm`'s **author path automatically**: post the consolidated
  findings as a comment-only review. Don't ask which action to post.
- **Auto-spawn the fix round.** Don't ask "want me to fix these?".
- Between cycles, strip the label: `gh pr edit <pr> --remove-label review-swarmed`.
  This is hygiene, not a re-run gate — `review-swarm` reviews whatever head SHA it
  fetches regardless, but it re-applies the label as a marker, and clearing it each
  cycle keeps that marker honest about *which SHA* was actually reviewed.

Each cycle:

1. **Run `review-swarm`**; take its severity-tagged findings as this cycle's work list.
2. **Triage every in-scope finding against the real code:**
   - **Fix** it if real — minimum change, matching surrounding style.
   - **Reject** it if incorrect or irrelevant, with a one-line rationale. A
     confidently-wrong finding is not a license to churn code. The
     surface-completeness and codex lanes over-fire; rejecting is correct work.
   - Track rejections across cycles and **don't re-litigate them** — a finding
     already rejected that reappears is dismissed by reference, or the loop
     never converges.
3. **Run the tests** (changed apps, per their `apps/<app>/CLAUDE.md`), then
   pre-commit, commit, and push — so the *next* cycle reviews the fixed head.

**Exit** when a swarm run **that demonstrably completed** surfaces no in-scope
findings that are neither fixed nor rejected — **and that run's head SHA is still
the current head SHA.** Verify it:

```bash
git rev-parse HEAD          # must equal the SHA the clean swarm reviewed
```

If you pushed anything after the last clean swarm — even a one-line fix, even a
test-only change — that code is unreviewed, and CI's `ready_for_review` swarm will
review it. Run one more cycle. **This is the condition that actually matters**;
the cycle cap is just a runaway guard.

**A crashed swarm also reports zero findings.** A dead subagent lane, a codex 401,
a timed-out Lane F, or a "degraded consensus" verdict all look like a clean pass.
Before accepting zero as clean, confirm the run actually completed across its
lanes. A degraded run is a **re-run**, not an exit.

If the last cycle still leaves genuine (not-rejected) in-scope findings open,
**stop and surface them** — don't silently ship past the cap.

## Step 3 — Final gate: two lanes, different models

Once the loop settles, one final review over the PR diff. Skip only with
`--no-final`. Both lanes run concurrently.

- **Claude lane (Fable)** — `Agent` (`general-purpose`, **`model: "fable"`**)
  instructed to invoke the builtin `code-review` skill on the PR diff
  (branch vs `origin/<base>`) and return findings. The Agent `model` override is
  what pins it to Fable 5; the skill itself runs on whatever model hosts it, so
  the subagent wrapper is how you choose the model.
- **GPT lane (GPT-5.6)** — background Bash, read-only:

  ```bash
  log=/tmp/pr-swarm-fix-final-<PR>.log; : >|"$log"
  ( cd "$(git rev-parse --show-toplevel)" && \
    timeout 1200 codex review --base "origin/<base>" \
      -c model="gpt-5.6-sol" -c model_reasoning_effort="xhigh" ) >|"$log" 2>&1
  echo "===CODEX-EXIT $?===" >>"$log"
  ```

  `codex review` has no `-m`; pin the model with `-c`. There's no bare `gpt-5.6`
  slug — use **`gpt-5.6-sol`** (the flagship). Guard the result the way
  `review-swarm`'s Lane F does: check the `===CODEX-EXIT===` sentinel and for a
  401/auth-shaped or stale-workdir failure. **A false clean here is the worst
  place for one** — this is the last gate before a human. A failed lane is a
  re-run or a surfaced warning, never a pass.

Triage and fix these findings the same way (fix / reject with rationale), then
test, pre-commit, push.

## Step 4 — Report

- **Per cycle:** findings by severity, how many fixed vs rejected, the head SHA
  it converged on.
- **Final gate:** what each lane found, and explicitly whether each lane
  *completed* (a skipped or crashed lane is a gap in coverage — say so).
- **Fixed** (with SHAs) / **Rejected** (with reasons) / **Low findings left**.
- Whether the loop converged or hit the cap with findings still open.
- CI status. Draft/ready state unchanged.

Don't post this as a PR comment — the swarm's own findings comments are the record.

## Step 5 — Optional

`--update-desc`: refresh the PR title/body to match the final state. Editing the
body is fine (it's not a review comment); off by default.
