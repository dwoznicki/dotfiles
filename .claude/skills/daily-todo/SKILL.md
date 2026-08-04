---
name: daily-todo
description: Daniel's daily priority list, stored on the private Notion page "🪢 Daily sched" and backed by a verbose per-day memory file. Clears items he checked off, auto-checks work that landed (PR merged, review submitted, issue Done), refreshes ages, and suggests new items from Linear, GitHub, and Slack — including review requests waiting on him and commitments he made in threads. `--load` pulls today's memory into the session so he can discuss it. Priorities are his; the skill never re-ranks. Use for "todo", "what should I work on", "my list", "add to my todo", "bump X", "load my todo context", or the daily morning run.
user_invocable: true
argument-hint: "[digest | --load [date] | add <text> | bump <title> <urgent|high|medium|low> | drop <title> | suggest]"
---

# TODO

A daily priority list that Claude maintains and Daniel owns.

## Where it lives

The private Notion page **`🪢 Daily sched`** —
`283267e9292747a8a49353cfe5252e71`
([open](https://app.notion.com/p/283267e9292747a8a49353cfe5252e71)).

Top-level page, no parent, outside any database. Read it with
`notion-fetch`; write with `notion-update-page`.

## The memory file

Every run also writes **`~/.claude/daily-todo/YYYY-MM-DD.md`** — the long version
behind the short Notion list: why each item matters, the evidence, what's already
been ruled out, durable facts worth not re-deriving, and open questions.

Deliberately **not** in the standard memory directory
(`~/.claude/projects/*/memory/`) — that's for small single-fact files loaded into
every session. This is a verbose per-day working record, loaded only on request.
Deliberately **not** in the dotfiles repo either: that repo is public and this file
names customers.

Two rules that make it useful:

- **Each day's file is a complete snapshot, not a delta.** Carry forward the full
  context of every still-open item, so loading any single date gives a whole picture
  without reading back through history. Verbose is fine — that's the point.
- **Record what you couldn't determine, not just what you found.** "I did not query
  the blast radius" and "the log can't distinguish these two causes" are the most
  valuable lines in the file, because they stop the next session from mistaking an
  unchecked assumption for a settled fact.

Write it *after* the Notion update, so the file reflects the state the page ended in.

**Prefer `update_content`** (search-and-replace pairs) over `replace_content` —
flipping one checkbox shouldn't rewrite the page and risk clobbering an edit he
made in the app five minutes ago. Use `insert_content` with `position` to add
items. Reach for `replace_content` only when restructuring the whole page, and
only right after a fresh read.

## Notion-flavored markdown — the parts that matter here

Not standard markdown. Don't guess; the rules that bite:

- **To-do:** `- [ ] text` / `- [x] text`. This is the checkbox — the whole
  mechanism depends on it.
- **Children indent with TABS**, not spaces. An item's explanation and metadata
  lines are tab-indented children of its to-do block.
- **Escape outside code blocks:** `\ * ~ \` $ [ ] < > { } | ^`. Link syntax
  `[text](url)` is fine; a *literal* bracket needs escaping.
- **Blank lines are stripped.** Use `<empty-block/>` on its own line if one is
  genuinely needed — usually it isn't, Notion spaces blocks itself.
- **Due dates use a real date mention:** `<mention-date start="2026-08-06"/>`.
  Native, clickable — don't write dates as plain text.
- **`<details><summary>…</summary>`** for a collapsed section (used for *Not doing*).
- **`<callout icon="⚠️" color="red_bg">`** for a warning that must not be missed.
- **Never use a `<page>` tag** — it would move a real page in as a subpage, and
  removing the tag later deletes it.

## The one rule

**Daniel owns the priorities. The skill never re-ranks.**

Whatever section an item sits in is its priority, whether he put it there or asked
for it. The skill may *suggest* a change — "🎫 OUT-9182 went Urgent in Linear but
sits in Medium here; bump?" — then leave it alone. If he rewrote an item's wording,
keep his text verbatim.

## Icon set

Three axes. Severity and source always; flags only when true.

**Severity** — the same scale `review-swarm` posts on PRs, so it reads identically:
🔴 Urgent · 🟠 High · 🟡 Medium · 🟢 Low

**Source** — what kind of thing this is:
🔀 pull request · 🎫 Linear issue · 💬 Slack thread · 🐛 Sentry / prod error ·
📊 data / analysis · 🛠 your own tooling, skills, infra

**Flags** — only when they apply:
🤝 you committed to this in a thread · 👀 someone is blocked waiting on you ·
🚫 you're blocked on someone else · ⏰ past due · 🕸 stale, 10+ days no movement ·
🤖 auto-checked by the job, not by you

Don't invent icons outside this set. A key that grows weekly stops being a key.

## Item format

A to-do block with two tab-indented children:

```
- [ ] 🔴 🔀 **"None of the above" no longer screens out immediately** ⏰ <mention-date start="2026-08-06"/>
	Participants who pick it now finish the whole screener instead of being dropped, so a Gap study is collecting responses it should have rejected.
	[OUT-9739](https://linear.app/…) · [#3821](https://github.com/…) · 👀 CS waiting · 2d
```

- **Line 2 is one sentence, and it says why it matters** — not what the thing is.
  Two sentences means it belongs in the ticket instead.
- **Due date only when something real sets one** — a customer commitment, a
  release, a promise in a thread. An invented due date trains him to ignore the
  real ones.
- **Age** = days since added, on the metadata line.
- No item IDs. Refer to items by their bolded title ("bump the screener one").

Page structure:

```
## 🔴 Urgent
## 🟠 High
## 🟡 Medium
## 🟢 Low
## Suggested
<details><summary>Not doing</summary> … </details>
```

## The daily run (`digest` — the default)

In order:

**1. Read the page first.** Always. His edits are the source of truth; never
regenerate from memory.

**2. Clear what's checked.** Every `- [x]` item is **removed**, children and all.
Checked items do not survive to the next day — that's the point, the page only ever
shows live work. Report what you cleared in the digest so there's one moment of
visibility before it's gone.

**3. Auto-check what landed.** Flip to `- [x]`, add 🤖, so tomorrow's run clears it:

| item | done when |
|---|---|
| 🔀 PR he authored | `gh pr view <n> --json state` → `MERGED` |
| 🔀 review requested of him | `gh pr view <n> --json reviews` contains a review by `dan-woz` |
| 🎫 Linear issue | `get_issue` status is Done or Canceled |
| 💬 Slack commitment | not detectable — leave it, flag 🕸 at 7 days |

This is the only place the skill decides something is finished, so **record what
closed it** on the metadata line (`#3645 merged`, `OUT-9196 → Done`). A wrong
auto-check is invisible otherwise.

**4. Refresh ages and flags.** Recompute `d`; add 🕸 past 10 days, ⏰ past due.

**5. Suggest** — up to 5, into **Suggested** only.

**6. Report the digest.** Short. Don't print the page back.

## Suggestions — three sources, 5 max

Never write a suggestion into a priority section. Prioritising is his call; the
skill's job is only to make sure nothing reaches him unnoticed.

**GitHub** — the gap `pr-drain` doesn't cover:

- **Review requests on him** — `gh pr list --search "review-requested:@me" --state open`.
  This is the big one: `pr-drain` only handles PRs he *authors*, so these are
  invisible today and someone is blocked on every one → 👀. There were **25** when
  this skill was written. Don't list 25 items; surface the **oldest few** and give
  the total.
- His own PRs — read `pr-drain`'s ready-to-flip list and
  `~/.claude/pr-drain/needs-me.md`; don't re-derive them.

**Linear** — `list_issues(assignee="me", state="started")`. Favour issues with no
recent activity, or whose Linear priority outranks where they sit here.

**Slack** — in priority order:
1. **Commitments he made** — threads where he said "I'll take this", "I'll look",
   "let me check", and nothing shipped since → 🤝. Nothing else tracks these.
2. **Direct asks awaiting him** — an `@`-mention with a question and no reply.

**Dedup, hard:**
- Skip anything already on the page — match on ticket ID / PR number / thread ts,
  never on title text.
- Skip anything under **Not doing**, permanently. A suggestion that returns after
  he killed it is worse than no suggestion.
- **5 per run, max**, ranked 👀 blocked-on-you > 🤝 promised > 🕸 aging. If more
  qualify, say how many were held back — never truncate silently.

## The digest

A morning glance, not a report. Printed to stdout (the timer mails/logs it); the
page is the durable copy.

```
TODO · 4 Aug · 🔴 2 · 🟠 3 · 🟡 4

🔴 🔀 "None of the above" screen-out regression (Gap)   ⏰ 6 Aug · 2d
🟠 💬 Reply to Fred — quota recompute                    🤝 4d
🟠 👀 25 PRs awaiting your review, oldest 4d (#3872)

🤖 Cleared 3: #3645 merged · OUT-9196 → Done · reviewed #3902
🕸 Aging: 🟠 "Publish-validation error union" — 12d

Suggested 2 (3 held back)
  👀 🔀 #3872 review requested 4d ago — bstanfield waiting
  🤝 💬 "I'll take this" on the transcode thread, 6d ago
```

Lead with **Urgent + High**. Medium and Low live on the page; the digest doesn't
recite them.

**If a connector's token has gone stale, say so at the top** — in a red `<callout>`
on the page and as the first line of stdout. A digest silently missing its Linear
and Slack halves looks like a quiet day.

Don't post the digest anywhere else. If he wants it in Slack, route it through
`slack-post`.

## `--load` — pull today's context into the session

For when he wants to *talk* about the list rather than read it. Read-only: no Notion
write, no suggestion pass, no clearing.

1. Read `~/.claude/daily-todo/<today>.md`.
2. **If today's file doesn't exist** (before the morning run, or a non-weekday),
   fall back to the most recent file present — and **say which date you loaded**.
   Silently serving stale context as today's is the failure mode here.
3. Also read the Notion page, so the live checkbox state is current — he may have
   ticked things since the file was written.
4. Summarise in a few lines: what's open, what changed since the file was written,
   and any **open questions** the file records. Then stop and let him drive.

`--load <date>` loads a specific day (`--load 2026-08-01`) for looking back.

If the two disagree — an item checked off in Notion that the file still describes as
open — **trust Notion** for state and the file for context, and point out the
divergence rather than quietly reconciling it.

## Other modes

- **`add <text>`** — into the section he names, else 🟡 Medium. Fill in the source
  icon, the one-sentence why, and links from context.
- **`bump <title> <priority>`** — move between sections. Nothing else changes.
- **`drop <title>`** — move into **Not doing** with his reason and the date.
- **`suggest`** — suggestion pass only; no clearing, no digest.

## The daily timer

Runs on Daniel's devbox (`i-0d6d39cbed0bcc4b2`) as a **systemd user timer**, not
cron — `Persistent=true` means a run missed while the box was down fires on next
boot, which cron would silently skip. User linger is enabled, so it needs no login
session. Units:

- `~/.config/systemd/user/claude-todo.service`
- `~/.config/systemd/user/claude-todo.timer` — `OnCalendar=Mon-Fri 09:00 America/Los_Angeles`

The timer carries its own timezone, so it doesn't drift at the DST change. Output
goes to the journal: `journalctl --user -u claude-todo -n 50`.
