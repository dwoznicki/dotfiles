---
name: pr-resolve
description: Take an existing GitHub PR and drive it back to green — resolve merge conflicts, fix failing CI, and address review comments — respecting Daniel's PR conventions (keep status, merge not rebase, no force-push, no summary comments). Use when handed a PR URL/number with "resolve conflicts", "failing CI", "has review comments", "changes requested", or similar.
user_invocable: true
argument-hint: "<pr-url|number> [--conflicts | --ci | --comments]"
---

# Resolve PR

Take an already-open pull request and unblock it. Auto-detects what's wrong —
merge conflicts, red CI, unresolved review comments — and resolves each. This is
the counterpart to the repo's `pr` skill: `pr` opens/updates a PR from your local
diff; `pr-resolve` fixes a PR that already exists.

This skill is for the Outset monorepo (`Outset-AI/outset`).

## Arguments

- **PR** (required): a URL (`https://github.com/Outset-AI/outset/pull/3417`) or a
  bare number (`3417`).
- Optional focus flags — by default the skill triages and fixes **all** blockers.
  Pass one to scope the work:
  - `--conflicts` — only resolve merge conflicts / bring the branch up to base.
  - `--ci` — only fix failing checks.
  - `--comments` — only address review comments.

## House rules (do not violate)

These encode standing preferences. They override any generic instinct:

- **Never re-draft an open PR.** `--draft` is only for *opening* a new PR. After
  pushing a fix, do **not** run `gh pr ready --undo`. Leave whatever
  ready/draft state the PR is already in.
- **Never force-push.** Once a branch is on the remote, every further change is a
  **new follow-up commit** + plain `git push`. No `git commit --amend`, no
  `--force`/`--force-with-lease`, even on drafts, even as sole author.
- **Resolve conflicts with `git merge main`, not rebase.** Rebase + force-push
  detaches existing review comments from their lines and forces reviewers to
  re-read the whole diff. A merge commit costs nothing (squash-merge discards it).
- **Don't post a summary comment after pushing.** No `gh pr comment` / issues API
  "here's what I changed". Put that context in the commit message. Only reply on
  the PR when Daniel explicitly says to ("reply to Fred", "leave a comment").
- **Run pre-commit before every push** (`pre-commit run --files <changed>`).
  Gitleaks + formatters run in CI too; catching them locally avoids a red run.
- **Don't re-run `/review-swarm`** while resolving — one swarm pass per scope.

## Steps

### 1. Preflight & fetch PR state

```bash
gh auth status                      # stop and tell Daniel to `gh auth login` if this fails
```

Resolve the PR number from the arg, then pull its state:

```bash
gh pr view <pr> --json number,title,url,state,isDraft,author,headRefName,baseRefName,mergeable,mergeStateStatus,reviewDecision
```

If `state` != `OPEN`, stop and report (a closed/merged PR has nothing to resolve).
Note `isDraft` and `reviewDecision` — you'll preserve the former and use the
latter to decide merge-vs-rebase in step 3.

### 2. Get the branch into a working checkout

Check whether the current directory is already this PR's branch:

```bash
git branch --show-current      # == headRefName ?
```

- **If yes**, work here.
- **If no**, prefer an isolated worktree so you don't disturb the current one.
  Use the repo's `worktree` skill to create one for `headRefName`, or fall back to:
  ```bash
  gh pr checkout <pr>
  ```
  If the worktree is bare (no root `.env`) **and** you'll need to boot services or
  run backend tests, run `python3 scripts/worktree.py init` first (see root
  `CLAUDE.md`). Skip init for pure code edits / frontend-unit / lint.

Always use the checkout's own absolute path in subsequent commands — never `cd`
back to the main checkout, or you'll commit to the wrong branch.

### 3. Triage — decide what's actually blocking

Determine the base branch (`baseRefName`; usually `main`, but the PR may be
stacked on a feature branch — respect what GitHub reports). Then gather all three
signals up front so you fix in one pass:

- **Behind base / conflicts:** `mergeable == CONFLICTING` or `mergeStateStatus in
  {BEHIND, DIRTY}`.
- **CI:** `gh pr checks <pr>` — treat the **aggregate** jobs (`backend_ci_result`,
  `frontend_e2e`, `frontend_test`, `pre-commit`) as the source of truth; shard
  jobs sometimes show `pending` after the parent has moved on.
- **Review comments:** `reviewDecision == CHANGES_REQUESTED`, plus unresolved
  review threads:
  ```bash
  gh api graphql -f query='
    query($owner:String!,$repo:String!,$pr:Int!){
      repository(owner:$owner,name:$repo){
        pullRequest(number:$pr){
          reviewThreads(first:100){nodes{
            isResolved isOutdated
            comments(first:20){nodes{author{login} body path line}}
          }}
        }}}' -F owner=Outset-AI -F repo=outset -F pr=<pr>
  ```

Report the triage to Daniel before large changes: "This PR has {conflicts / N
failing checks / M unresolved threads}. Resolving all." Honor a focus flag if one
was passed.

### 4. Resolve conflicts / bring up to base

Only if conflicts or behind-base (or `--conflicts`):

```bash
git fetch origin <base>
git merge origin/<base>          # MERGE, not rebase — see house rules
```

Resolve each conflict by understanding both sides. Two recurring Outset cases:

- **Migration conflicts** (two migration heads on the same app): the fix is a
  merge migration, *not* hand-editing either file — after merging main, run
  `docker compose exec -T backend python manage.py makemigrations --merge` (or the
  app's `make` target) and commit the generated merge migration.
- **Phantom pending migration after merging main:** if `makemigrations --check`
  reports a migration nobody wrote, the container's venv predates the merged
  `uv.lock`. **Do not generate it.** Run `docker compose exec -T backend uv sync
  --frozen`, then re-check. CI installs from the lock and never sees this.

Commit the merge. If `--comments`/`--ci` was the only focus and there were no
conflicts, skip this step.

### 5. Fix failing CI

Only if checks are red (or `--ci`). For each failing aggregate job, pull the
failing log and fix the real cause — don't assume flake on the first failure:

```bash
gh pr checks <pr>
gh run view <run-id> --log-failed
```

- Reproduce locally where practical: run the failing app's lint/test per its
  `apps/<app>/CLAUDE.md`. For a backend test, run it in the worktree's stack.
- Before treating a failure as environmental, rule out the worktree footguns in
  root `CLAUDE.md` (offset-port `file_url` refusals, `POSTHOG_ENABLED` null-vs-false,
  stale `node_modules`, missing `BACKEND_JUPYTER_PORT`) — those are green in CI.
- A genuinely flaky shard can be re-run: `gh run rerun <run-id> --failed`. Say so
  explicitly when you do — don't silently paper over a real failure as flake.

Loop: fix → pre-commit → push → wait → `gh pr checks` again, until the aggregates
are green.

### 6. Address review comments

Only if there are unresolved threads (or `--comments`). For each thread:

- **Implement the requested change** as a follow-up commit. Put the "why" in the
  commit message, not a PR comment.
- If a comment is a **question** or a **suggestion you'd push back on**, don't
  guess — surface it to Daniel and let him decide/reply. He replies to reviewers
  himself unless he tells you otherwise.
- Do **not** auto-resolve the review threads; leave that to the author/reviewer.

Keep each logical fix a separate commit (readable "addressed X, then Y" history).

### 7. Pre-push checks

After the final edit, before pushing:

```bash
git diff origin/<base>...HEAD --stat        # THREE dots — confirm only intended files
pre-commit run --files <changed files>
```

- The three-dot diff shows *your* changes vs the merge base; a two-dot diff can
  misread main's own new commits as branch pollution. Confirm nothing unexpected
  (e.g. Layup auto-id drift in files you didn't touch — `git checkout origin/<base>
  -- <file>` to revert those).
- If `core.hooksPath` is set (Husky), `git config --unset-all core.hooksPath`
  first. If pre-commit isn't installed: `pre-commit install --install-hooks`.
- For a **backend-only** diff where the orval pre-commit hook fails locally,
  `git push --no-verify` is acceptable (the hook regenerates the frontend client
  the diff doesn't touch).
- Frontend changes: run `npm run prepare-pr`, but only commit auto-id changes in
  files you actually modified.

### 8. Push

```bash
git push                    # plain push — NO --force, NO amend
```

The merge in step 4 may make this a non-fast-forward relative to a stale local
view; that's fine, a normal push of new commits still applies. If git genuinely
rejects it, investigate — do **not** reach for `--force`.

### 9. Report

Print:
- The PR URL (clickable).
- What was resolved: conflicts merged / which checks were fixed / which comments
  addressed.
- Current check status (`gh pr checks <pr>`), or note if a re-run is still running.
- **Anything left for Daniel:** reviewer questions to answer, threads to resolve,
  or a suggestion you deliberately didn't implement.
- Confirm the PR's draft/ready state was left unchanged.
