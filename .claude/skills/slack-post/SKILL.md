---
name: slack-post
description: Write and post a Slack message that busy colleagues will actually read — short, plain-language, structured, impact-first. Use whenever posting findings, an investigation result, a status update, or a bug explanation to a Slack channel, thread, or DM. Drafts for review before sending.
user_invocable: true
argument-hint: "<channel | thread-url | @person> [what to say] [--post]"
---

# Slack post

Turn findings into a message a busy person reads in 15 seconds. The default
failure mode this skill exists to prevent: a 4,000-character investigation
write-up posted where a 5-line answer belonged.

## Who reads these

Colleagues at Outset — PMs, CS, designers, leadership, engineers. They are
**data-oriented but not all programmers**. That cuts both ways:

- **Give them numbers.** How many users, studies, orgs, over what window. They
  trust and want quantities.
- **Don't give them code.** No stack traces, no file paths, no ORM/model names,
  no internal shorthand, unless an engineer specifically asked for it.

They are busy. They want the answer and what it means for them — not the
investigation that produced it.

## Workflow

1. **Compose** the message per the rules below.
2. **Show it in the conversation** and stop. Let Daniel read it.
3. **Post only on confirmation** — with `mcp__claude_ai_Slack__slack_send_message`.
   Use `slack_send_message_draft` if he wants it parked in Slack instead.

Skip the review gate only when `--post` was passed or he already said "post it".
Posting is outward-facing and effectively irreversible — when in doubt, show first.

If given a thread URL, reply **in the thread** (`thread_ts` = the parent's ts from
the URL's `p1784…` → `1784….######`). Don't start a new channel message. Use
`reply_broadcast` only if the channel genuinely needs to see it.

## The shape

Four parts, in this order. Drop any that don't apply.

1. **The answer — one sentence, first line.** What's true. Not "I investigated X."
2. **Impact, quantified.** Who/how many are affected, over what period. This is
   the part this audience actually wants.
3. **Cause — one plain sentence.** Only if it helps them decide something.
4. **The ask.** What you need from them, or explicitly "no action needed."

## Length budget

- **Findings / status post: under ~150 words.** Roughly 1,000 characters.
- **Quick answer in a thread: 1–3 sentences.** No structure, no headers.
- Hard cap is 5,000 chars, but anything over ~1,500 means you're writing a
  document, not a message.

If the detail genuinely matters, post the short version and put the depth in a
**threaded reply** — or link the Linear ticket / PR and let them click. Never make
the top-level message carry the full analysis.

## Plain language

Translate every internal term. If a PM wouldn't recognize it, rewrite it:

| Don't write | Write |
|---|---|
| N+1 query | the page makes one database call per row, so it slows down as data grows |
| race condition | two requests updated the same record at once and one overwrote the other |
| `ScreenerQuestionOption` hard-deleted | the researcher deleted the answer choice after the interview ran |
| Survey / Chat | study / interview (the public names — always) |
| p90 latency 6.5mo | half of these finish in X; the slowest 10% take over 6 months |
| BACKEND-6BX, is:new poll, 12-combo matrix | say what happened, link the ticket |

More rules:
- **Never post a bare ticket ID.** `OUT-8774` means nothing to most readers —
  write what it is and link it: `[OUT-8774](url) — screener answers not saving`.
- **No process narration.** Cut "I checked Hex, then queried CloudWatch, then…".
  They want the conclusion, not the path.
- **Say how sure you are** when it matters: "confirmed" vs "likely — still checking".
  Don't present a hypothesis as fact.
- **No hedging padding.** Cut "It's worth noting that", "I wanted to flag that",
  "Hopefully this helps". Start with the noun.

## Slack formatting (get this right)

`slack_send_message` takes **standard markdown** in its `message` param — not
Slack's older mrkdwn. Mixing them is the most common rendering bug:

| Use | Not | Why |
|---|---|---|
| `**bold**` | `*bold*` | single asterisk renders *italic* |
| `[text](url)` | `<url\|text>` | angle form renders as literal text |
| `- item` | `• item` | plain bullets render fine |

- **Tables work** — standard `|` pipes. Good for per-org / per-day counts, which
  this audience likes. Don't escape the structural pipes.
- **Headers work** (`##`) but are usually overkill at this length. Bold a line instead.
- `:emoji:` shortcodes work. One as a status marker is fine; a row of them is noise.
- **User mentions are the exception** — `<@U067K5DTP4L>` is Slack-native and
  required. A literal `@name` does not notify. Look IDs up with `slack_search_users`.
- Never `@channel` / `@here`.

## Worked example

**Before** (real shape, 340 words — too long, jargon-first, no ask):

> I investigated the matrix question issue. After querying Hex with a per-day
> LATERAL to avoid replica conflicts, I found that `matrix_selections` is null on
> Message rows where the participant answered by voice. The root cause is that the
> grid gate is client-only, so the backend advances the interview on a bare
> transcript without validating that selections were persisted…

**After** (98 words):

> **Matrix questions answered out loud aren't saving the participant's selections.**
>
> Last 30 days: **674 answers across 265 interviews, 28 studies, 7 organizations.**
> Happens on voice, video, and screenshare — not limited to one interview type.
>
> Cause: the check that requires picking a grid option only runs in the
> participant's browser. When someone answers by speaking, nothing enforces it and
> the interview moves on with the selection blank.
>
> Fix needs to be server-side. Tracking in [OUT-9003](url).
>
> **CS:** affected studies are listed in the thread — worth a heads-up to those
> accounts before they spot gaps in their data.

Note what changed: impact and numbers moved to the top, the mechanism is one plain
sentence, the query technique is gone entirely, and it ends with a specific ask.

## Report

After posting, give Daniel the message permalink. Don't re-paste the body.
