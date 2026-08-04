---
name: todo
description: Daniel's daily priority list, stored as a private Linear document. Clears items he checked off, auto-checks work that landed (PR merged, review submitted, issue Done), refreshes ages, and suggests new items from Linear, GitHub, and Slack — including commitments he made in threads. Priorities are his; the skill never re-ranks. Use for "todo", "what should I work on", "my list", "add to my todo", "bump X", or the daily morning run.
user_invocable: true
argument-hint: "[digest | add <text> | bump <id> <urgent|high|medium|low> | drop <id> | suggest]"
---

# TODO

A daily priority list that Claude maintains and Daniel owns.

## Where it lives

A **private Linear document** titled exactly **`Daniel — Daily TODO`**.

Find it every run — no local state, so this works from any machine or a cloud
routine:

```
mcp__claude_ai_Linear__list_documents(query="Daniel — Daily TODO", fields=["title","url","content"])
```

**If it doesn't exist, stop and ask Daniel to create it.** Don't create it yourself:
`save_document` requires a parent (`team` / `project` / `issue` / `initiative` /
`cycle`) on create and has **no private flag**, so anything this skill creates would
be visible to whoever can see that parent. Two docs in the workspace already have
all-null parents, so Linear supports genuinely personal pages — the MCP just can't
make one. He creates it once in the Linear UI as a private page; from then on this
skill only ever **updates by `id`**, which doesn't touch the parent and so can't
leak it.

Prefer `patch` over `content` for edits — flipping one checkbox shouldn't resend
the whole document.

## The one rule

**Daniel owns the priorities. The skill never re-ranks.**

Whatever section an item sits in is its priority, whether he put it there or asked
for it. The skill may *suggest* a change — "🎫 OUT-9182 went Urgent in Linear but
sits in Medium here; bump?" — then leave it alone. Same for wording: if he rewrote
an item, keep his text verbatim.

## Icon set

Three axes. Severity and source always present; flags only when true.

**Severity** — same scale `review-swarm` posts on PRs, so it reads the same way:

| | |
|---|---|
| 🔴 | Urgent |
| 🟠 | High |
| 🟡 | Medium |
| 🟢 | Low |

**Source** — what kind of thing this is:

| | |
|---|---|
| 🔀 | pull request |
| 🎫 | Linear issue |
| 💬 | Slack thread |
| 🐛 | Sentry / production error |
| 📊 | data / analysis question |
| 🛠 | your own tooling, skills, infra |

**Flags** — only shown when they apply:

| | |
|---|---|
| 🤝 | you committed to this in a thread |
| 👀 | someone is blocked waiting on you |
| 🚫 | blocked on someone else |
| ⏰ | past its due date |
| 🕸 | stale — no movement in 10+ days |
| 🤖 | auto-checked by the job, not by you |

Don't invent icons outside this set. A key that grows every week stops being a key.

## Item format

Three lines. Severity + source + title + due on line 1, one sentence of why on
line 2, links and flags and age on line 3.

```markdown
- [ ] 🔴 🔀 **"None of the above" no longer screens out immediately** ⏰ 4 Aug
  Participants who pick it now finish the whole screener instead of being dropped, so a Gap study is collecting responses it should have rejected.
  [OUT-9739](url) · [#3821](url) · 👀 CS waiting · added 2 Aug · 2d
```

- **One sentence on line 2**, and it says *why it matters*, not what the thing is.
  If it needs two sentences it belongs in the Linear ticket.
- **Due date** only when something real sets it — a customer commitment, a release,
  a promise in a thread. Don't invent due dates; an invented one trains him to
  ignore the real ones.
- **Age** in days since added. It's what makes rot visible.
- Stable IDs aren't needed — Linear anchors on text, and `patch` matches on it.
  Refer to items by their bolded title when he says "bump the screener one".

Document shape:

```markdown
## 🔴 Urgent
## 🟠 High
## 🟡 Medium
## 🟢 Low

## Suggested
<!-- Claude's picks. Daniel moves them up, or moves them to Not doing. -->

## Not doing
<!-- never suggest these again -->
- 🔀 #3361 — closing the PR instead (1 Aug)
```

## The daily run (`digest`, the default)

In this order:

**1. Read the document first.** Always. His edits are the source of truth; never
regenerate from scratch.

**2. Clear what's checked.** Every `- [x]` item is **removed** — checked items do
not survive to the next day. That's the point: the list only ever shows live work.
Report what you cleared in the run summary so there's one moment of visibility
before it's gone.

**3. Auto-check what landed.** Mark `- [x]` and add 🤖, so tomorrow's run clears it:

| item | done when |
|---|---|
| 🔀 PR he authored | `gh pr view <n> --json state` → `MERGED` |
| 🔀 review requested of him | he submitted a review — `gh pr view <n> --json reviews` contains one by `dan-woz` at/after the request |
| 🎫 Linear issue | `get_issue` status is Done or Canceled |
| 💬 Slack commitment | not detectable — leave it, and flag 🕸 at 7 days |

Auto-checking is the one place the skill decides something is finished, so record
*what* closed it (`#3645 merged`, `OUT-9196 → Done`) on line 3. A wrong auto-check
is invisible otherwise.

**4. Refresh ages and flags.** Recompute `d`, add 🕸 past 10 days, ⏰ past due.

**5. Suggest** — up to 5, into **Suggested** only (below).

**6. Report the digest** — short (below). Don't print the document back.

## Suggestions — three sources, 5 max

Never write suggestions into a priority section. Prioritising is his call; the
skill's job is only to make sure nothing reaches him unnoticed.

**Linear** — `list_issues(assignee="me", state="started")`. Favour issues with no
recent activity, or whose Linear priority outranks where they sit here.

**GitHub** — the gap `pr-drain` doesn't cover:
- **Review requests on him**: `gh pr list --search "review-requested:@me" --state open`.
  `pr-drain` only handles PRs he *authors*, so these are invisible today and
  someone is blocked on each → 👀.
- His own PRs: read `pr-drain`'s ready-to-flip list and
  `~/.claude/pr-drain/needs-me.md` rather than re-deriving them.

**Slack** — in priority order:
1. **Commitments he made** — threads where he said "I'll take this", "I'll look",
   "let me check", and nothing shipped since. → 🤝. Nothing else tracks these and
   they're the highest-value suggestions.
2. **Direct asks awaiting him** — an `@`-mention with a question and no reply.

**Dedup, hard:**
- Skip anything already on the list — match on ticket ID / PR number / thread ts,
  never on title text.
- Skip anything under **Not doing**, permanently. A suggestion that returns after
  he killed it is worse than no suggestion.
- **5 per run, max**, ranked 👀 blocked-on-you > 🤝 promised > 🕸 aging. If more
  qualify, say how many were held back — never truncate silently.

## The digest

A morning glance, not a report.

```
TODO · 4 Aug · 🔴 2 · 🟠 3 · 🟡 4

🔴 🔀 "None of the above" screen-out regression (Gap)   ⏰ 4 Aug · 2d
🔴 🎫 Rotate expired EmailVerify rows                    3d
🟠 💬 Reply to Fred — quota recompute                    🤝 4d
🟠 🛠 Wire the daily todo timer                          1d

🤖 Cleared 3 done: #3645 merged · OUT-9196 → Done · reviewed #3902
🕸 Aging: 🟠 "Publish-validation error union" — 12d, no movement

Suggested 2 (3 held back)
  👀 🔀 #3902 review requested 3d ago — haivo-outset is waiting
  🤝 💬 You said "I'll take this" on the transcode thread 6d ago
```

Lead with **Urgent + High**. Medium and Low live in the document; the digest
doesn't recite them.

**If a connector's token has gone stale, say so loudly at the top.** A digest
silently missing its Linear and Slack halves looks like a quiet day.

Don't post the digest anywhere. If he wants it in Slack, route it through
`slack-post`.

## Other modes

- **`add <text>`** — into the section he names, else 🟡 Medium. Fill in source icon,
  the one-sentence why, and links from context.
- **`bump <title> <priority>`** — move between sections. Nothing else changes.
- **`drop <title>`** — move to **Not doing** with his reason and the date.
- **`suggest`** — suggestion pass only, no clearing or digest.
