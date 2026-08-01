---
name: swarm-fix
description: Run review-swarm on a PR, let it post its findings to GitHub, then fix the Critical/High/Medium findings and push — as follow-up commits, respecting Daniel's PR conventions (keep status, no force-push, no summary comment, pre-commit before push). Low findings are skipped. Use when asked to "run review-swarm, post findings, then fix high/medium", "run the swarm and fix the findings", or similar.
user_invocable: true
argument-hint: "<pr-url|number> [--sev=critical,high,medium] [--update-desc]"
---

# Swarm-fix

The one-shot version of a workflow Daniel runs constantly: **run `review-swarm`
on a PR, post its findings as a GitHub comment, fix the high-severity findings,
and push the fixes.** This skill orchestrates the two existing skills — it does
not re-implement either:

1. **`review-swarm`** (the repo skill) does the reviewing, consolidation, and
   posting. Don't duplicate its lanes or its GitHub-posting logic — invoke it.
2. **`resolve-pr`** (personal) owns the fix-and-push conventions. This skill
   reuses the same house rules for the fix phase.

This is for the Outset monorepo (`Outset-AI/outset`).

## Arguments

- **PR** (required): URL or bare number.
- `--sev=<list>` — which severities to fix. Default: `critical,high,medium`.
  Low is **never** fixed automatically (it's noise for this flow). Pass
  `--sev=critical,high` if you only want the top tier.
- `--update-desc` — after fixing, update the PR title/description to match the
  current state. Off by default (Daniel asks for this only sometimes).

## House rules (inherited — do not violate)

Same standing preferences `resolve-pr` enforces:

- **Never re-draft an open PR** — no `gh pr ready --undo`.
- **Never force-push** — every fix is a new follow-up commit + plain `git push`.
- **Resolve any conflicts with `git merge main`, not rebase.**
- **No summary comment after pushing.** The `review-swarm` findings comment is
  already the record; do not add a "here's what I fixed" comment. Context goes in
  commit messages.
- **Run pre-commit before pushing.**

## Steps

### 1. Preflight & get the PR branch checked out

```bash
gh auth status
gh pr view <pr> --json number,title,url,state,isDraft,author,headRefName,baseRefName
```

Stop if the PR isn't `OPEN`. Then ensure you're working **on the PR's branch in a
committable checkout** (not a detached temp worktree — you need to commit and push
the fixes here):

- If the current directory is already the PR branch with a clean tree, work here.
  `review-swarm` will reuse this cwd for its lanes (its reuse-cwd fast path).
- Otherwise check the branch out — via the repo's `worktree` skill for
  `headRefName`, or `gh pr checkout <pr>`. Make the tree clean before running the
  swarm, so the swarm reviews the real PR head and not uncommitted edits.

Being on the branch with a clean tree is what lets `review-swarm` reuse this
worktree instead of spinning up a detached one you couldn't push from.

### 2. Run review-swarm and let it post

Invoke the **`review-swarm`** skill (Skill tool, `skill: "review-swarm"`) with the
PR reference. Let it run its full 8-lane pass and consolidate.

When it reaches its posting step it will detect that you (`gh api user --jq
.login`) are the PR author and offer a **comment-only self-review** — that's the
"post findings as a comment" step Daniel wants, so **confirm it**. The swarm posts
the consolidated findings and chains the `review-swarmed` label. Do not use
approve/request-changes on your own PR (GitHub 422s).

Capture the swarm's consolidated findings list — each finding's **severity**,
**`file:line`**, headline, and suggested fix — from its Step 4 output. That list
is the work queue for step 3.

### 3. Triage and fix the in-scope findings

Work queue = findings whose severity is in `--sev` (default Critical/High/Medium).
Skip Low. For each one, **don't fix blindly** — decide first:

- **Correct and in-scope** → fix it. Read the cited code, implement the real fix
  (not a band-aid that silences the finding), at the right altitude.
- **Wrong or irrelevant** (false positive, already handled elsewhere, out of this
  PR's scope) → **reject it**, and record a one-line reason. A swarm finding is a
  single reviewer's opinion, not a gate — the surface-completeness and codex lanes
  in particular can over-fire. Rejecting a bad finding is correct, not skipping work.

Group fixes into readable follow-up commits (one per finding, or per logical
cluster). Put the reasoning in the commit message. If any fix surfaces a genuine
new problem outside this PR's scope, note it for a follow-up ticket rather than
expanding the diff.

### 4. Pre-push checks

Same as `resolve-pr` step 7:

```bash
git diff origin/<base>...HEAD --stat        # THREE dots — confirm only intended files
pre-commit run --files <changed files>
```

- Revert any Layup auto-id drift in files you didn't touch (`git checkout
  origin/<base> -- <file>`).
- Run the changed apps' lint/tests per their `apps/<app>/CLAUDE.md`.
- Backend-only diff where the orval hook fails locally → `git push --no-verify` is
  acceptable.

### 5. Push

```bash
git push        # plain — NO --force, NO amend
```

Keep the PR's draft/ready state exactly as it was.

### 6. (Optional) Update the PR description

Only if `--update-desc` was passed, or the diff has changed materially enough that
the title/body is now misleading:

```bash
gh pr edit <pr> --title "..." --body "..."
```

Editing the PR body is allowed (it's not a review comment) — but don't do it by
default.

### 7. Report

Print:
- The PR URL and that the swarm findings were posted (+ `review-swarmed` label).
- **Fixed:** each Critical/High/Medium finding fixed, with the commit sha.
- **Rejected:** each in-scope finding you did *not* fix, with the one-line reason.
- **Skipped:** count of Low findings left for Daniel's judgment.
- CI status (`gh pr checks <pr>`) or note that a run is still in flight.
- Any follow-up tickets worth filing.
- Confirm draft/ready state was left unchanged.

Do **not** post any of this as a PR comment — it's a conversation report.
