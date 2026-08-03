---
name: todo
description: Daniel's persistent priority TODO list. Reads and updates ~/.claude/todo/todo.md, auto-closes items whose source work has landed, and suggests new items from Linear, GitHub, and Slack — including commitments he made in threads. Priorities are his; the skill never re-ranks. Use for "todo", "what should I work on", "my list", "add to my todo", "bump X to urgent", or the daily morning digest.
user_invocable: true
argument-hint: "[digest | add <text> | done <id> | bump <id> <urgent|high|medium|low> | dismiss <id> | suggest]"
---

# TODO

A persistent, human-owned priority list that Claude maintains but does not own.

**The list lives at `~/.claude/todo/todo.md`** — machine-local, deliberately *not*
in the dotfiles repo, which is public and would leak customer names, ticket
detail, and Slack context. Create the directory on first run. Never move this file
into `~/.claude/skills/` or anywhere under `~/dotfiles/`.

## The one rule

**Daniel owns the priorities. The skill never re-ranks.**

Whatever section an item sits in is its priority, whether he typed it there or
asked for it. The skill may *suggest* a change — "T-07 has been Medium 12 days and
its Linear ticket went Urgent; bump?" — and then leave it alone. An auto-generated
list that keeps overruling its owner's judgment gets abandoned in a week.

Same for wording: if he rewrote an item, keep his text verbatim.

## File format

```markdown
# TODO
_updated 2026-08-03 · 2 urgent · 3 high · 4 medium · 1 low_

## Urgent
- [ ] **T-04** "None of the above" no longer screens out immediately (Gap study)
      live participant impact · [OUT-9739](url) · added 08-02 · 1d

## High
- [ ] **T-07** Reply to Fred on the quota-recompute PR
      [#3817](url) · added 07-30 · 4d

## Medium
## Low

## Suggested
<!-- Claude's picks. Daniel promotes with `bump`, or kills with `dismiss`. -->
- **S-02** Review request waiting 3d — [#3902](url) from @haivo-outset

## Done (last 7 days)
- [x] **T-01** Ship the screener soft-delete fix · closed 08-02 (#3645 merged)

## Dismissed
<!-- never suggest these again -->
- `pr-3361` — "closing that PR instead" (08-01)
```

Rules for the format:

- **Stable IDs.** `T-nn` for list items, `S-nn` for suggestions. Never reuse a
  number, so "bump T-04" always means the same thing. Track the high-water mark.
- **Two lines per item, max.** Title line, then a context line: why it matters,
  the link, when added, age. Anything longer belongs in the Linear ticket.
- **Age every item.** Days since added. It's the signal that something is rotting.
- Keep `Done` to the last 7 days, then drop. It exists so the morning digest can
  say what landed, not as an archive.

## Modes

### `digest` (default, and what the daily run uses)

1. **Read the file first.** Always. Never regenerate from scratch — his edits and
   priorities are the source of truth.
2. **Auto-close what's landed** (below).
3. **Refresh ages** and re-emit the counts line.
4. **Suggest** up to **5** new items (below).
5. **Print the digest** (below). Don't print the whole file.

### `add <text>`
Append to the section he names, or **Medium** if unspecified. Assign the next `T-nn`.

### `done <id>` / `bump <id> <priority>` / `dismiss <id>`
Exactly what they say. `dismiss` on a suggestion moves its source key into
**Dismissed** permanently. `bump` on an `S-nn` promotes it into the list as a `T-nn`.

### `suggest`
Just the suggestion pass, no digest.

## Auto-close: detect completion, don't ask for it

Ticking boxes by hand is how lists die. Each pass, check whether an item's source
work has landed and close it without being asked:

- **PR item** → `gh pr view <n> --json state,mergedAt`; `MERGED` → Done.
- **Linear item** → `mcp__claude_ai_Linear__get_issue`; status Done/Canceled → Done.
- **Slack commitment** → can't be auto-detected. Leave it; flag at 7 days
  ("you said you'd take this a week ago — still yours?").

Note in the Done entry *what* closed it (`#3645 merged`, `OUT-9196 → Done`), so the
digest can report it and he can spot a wrong auto-close.

## Suggestions — three sources, capped at 5

Land them in **Suggested**, never straight into the prioritized list. Prioritizing
is his call; the skill's job is to make sure nothing reaches him unnoticed.

**Linear** — issues assigned to him that aren't Done:
```
mcp__claude_ai_Linear__list_issues(assignee="me", state="started")
```
Prefer ones with no recent activity, or whose priority is above where they sit on
his list.

**GitHub** — the gap `pr-drain` doesn't cover:
- **Review requests on him**: `gh pr list --search "review-requested:@me --state=open"`.
  `pr-drain` only handles PRs he *authors*, so this is the genuinely additive one —
  and someone else is blocked on each.
- His own PRs: **read `pr-drain`'s output rather than re-deriving it** — its
  ready-to-flip list and `~/.claude/pr-drain/needs-me.md`. Don't duplicate that
  skill's logic or its findings.

**Slack** — two patterns, in priority order:
1. **Commitments he made.** Threads where he said "I'll take this", "I'll look",
   "let me check", "I'll follow up" and nothing shipped since. These are the
   highest-value suggestions and nothing else tracks them — search
   `from:@Daniel "I'll"` and similar, then check whether the thread resolved.
2. **Direct asks awaiting him** — `@`-mentions with a question and no reply from
   him.

**Dedup, hard:**
- Skip anything already on the list (match by ticket ID / PR number / thread ts,
  not by title text).
- Skip anything in **Dismissed**, forever. A suggestion that reappears after he
  killed it is worse than no suggestion.
- **5 per pass, maximum.** Rank by "someone is blocked" > "he promised it" >
  "it's aging". If more qualify, say how many were held back rather than silently
  truncating.

## The digest

Short. It's a morning glance, not a report.

```
TODO — 3 Aug · 2 urgent · 3 high · 4 medium

Urgent
  T-04  "None of the above" screen-out regression (Gap)      2d
  T-09  Reply to Fred — quota recompute PR                   1d

Aging  T-07 High, 12d — no movement since 22 Jul
Landed T-01 (#3645 merged), T-03 (OUT-9196 → Done)

Suggested (2, 1 held back)
  S-05  Review request 3d old — #3902 from @haivo-outset
  S-06  You said "I'll take this" on the transcode thread 6d ago
```

- Lead with **Urgent + High only**. Medium and Low are in the file; the digest
  doesn't recite them.
- **Aging**: anything untouched past ~10 days at High or above.
- **Landed**: what auto-closed since last run — the "you made progress" line.
- End with suggestions and the count held back.

Don't post the digest anywhere. It's for Daniel. If he wants it in Slack, route it
through `slack-post`.

## Running it daily

`/todo` on demand works. For the automatic morning surface, the two options differ
in what they cost:

- **A scheduled cloud routine** (the `schedule` skill) — runs without a session
  held open. Preferred.
- **`CronCreate` in a long-running local session** — works, but only fires while a
  Claude session is open and idle, and a long-lived session accumulates context.
  That's what makes `oncall-autopilot` expensive; don't repeat it here. If it must
  be local, run it as a fresh short session per day, not a standing one.
