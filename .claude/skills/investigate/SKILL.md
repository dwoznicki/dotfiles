---
name: investigate
description: Investigate a reported issue from a Slack thread, Sentry issue, or Linear ticket — reads the source, checks whether it's already known, right-sizes the investigation, and reports back through slack-post. Use whenever handed a Slack thread URL with "please investigate", "is this serious?", "what's your read?", "let's debug this", "is this a known issue?", or "why is X stuck?".
user_invocable: true
argument-hint: "<slack-thread-url | sentry-url | OUT-####> [the question] [--post]"
---

# Investigate

The front door for "here's a thread, what's going on?" — the single most common
task Daniel hands over. It does three things the underlying skills don't:

1. **Extracts the context from the source** instead of asking for it.
2. **Right-sizes the work** — most of these need a 5-minute answer, not a full
   production triage.
3. **Reports back through `slack-post`**, so the write-up is short and readable.

It composes existing skills; it does not reimplement them. **`oncall-triage` is the
general fallback, not the default** — check the specialist table in Step 3 first.
A specialist already knows the tables, the failure modes, and the queries for its
subsystem; reaching for `oncall-triage` when one applies means re-deriving all of
that by hand.

- **`slack-post`** owns anything posted to Slack. Always.
- **`code-owners`** answers "who should pick this up?".
- **`cs-bug-summary`** produces the CS/customer-facing version.

## Step 1 — Read the source first

Never ask for context that's in the thread. From a Slack URL
(`…/archives/<CHANNEL>/p<TS>`), the channel is the path segment and `thread_ts`
is the `p` number with a decimal inserted before the last 6 digits
(`p1784823856211579` → `1784823856.211579`). Read it with `slack_read_thread`,
including replies — the answer is often already half-written by a colleague.

Pull out whatever's there, and note what's missing rather than stalling:
study/interview IDs, org or customer name, timestamps (**and their timezone** —
CMS/admin screenshots are Pacific), which surface (backend / frontend / webrtc /
transcoder / mobile), environment (assume **Prod**; EU/Ipsos is `eu-west-1`), and
who reported it.

Screenshots in the thread usually carry the actual error text and the study URL —
read them.

## Step 2 — Check whether it's already known

Do this **before** investigating. Daniel asks "is this a known issue?" often
enough that it should be automatic, and it frequently ends the task in two minutes.

- Search Linear for an existing ticket (`list_issues` on keywords, the study ID,
  the error string).
- Search Slack for prior threads on the same symptom
  (`slack_search_public_and_private`).
- If a Sentry issue is referenced, check whether it's already resolved/ignored and
  whether the fix shipped (compare the fix's deploy date to the event timestamps —
  a recurrence *after* a deploy is a different, more urgent finding).

If it's known: say so, link the ticket/PR and its status, and stop. Don't
re-investigate a solved problem.

## Step 3 — Classify the ask, then right-size

Match the effort to the question. Running a full triage on "what's a maxdiff
question?" wastes twenty minutes; answering "why is this report stuck?" from
intuition gets it wrong.

| The ask | What to do |
|---|---|
| "What is X?" / "Is autopilot's read correct?" | Read the code, answer. No triage. |
| "Is this serious?" / "What's your read?" | Scope it: how many affected, is it ongoing. Enough to make a call. |
| "Is this a known issue?" | Step 2 only. |
| "Who should pick this up?" | `code-owners`, skip the investigation. |
| "Do we have a ticket?" | Step 2, then create one if not (see Step 5). |
| "Please investigate" / "why is this stuck?" / "debug this" | Route by **subsystem** — the table below. |

### Route to the specialist before reaching for `oncall-triage`

Match on the subsystem the symptom names, not on the words "investigate" or
"debug". These skills each encode the schema, failure modes, and queries for one
surface — work a matching one by hand and you'll redo all of it, worse.

| The symptom names… | Use |
|---|---|
| The **AI study agent** did something odd on a study (wrong questions, bad screener, wrong structure) | `debug-study-agent <survey_id \| thread_id>` — per-turn transcript + the LLM calls behind each turn |
| A **report / Insights** merged or deduped questions oddly across a template's studies | `debug-question-merge` |
| A **Figma prototype heatmap** ("Interaction Maps") missing or broken on Insights | `debug-figma-heatmap` |
| Something **visually** wrong — clipped, overflowing, misaligned, wrong size | `debug-css-layout` (real browser + CDP; source alone won't settle it) |
| **Whitelabel / iframe** chrome, branding, or settings visibility wrong | `spotcheck-whitelabel` |
| A **CI test** flaking | `fix-flaky-backend-tests` / `fix-flaky-frontend-tests` |
| A bug you want **pinned by a failing test** before fixing | `write-e2e-test --reproduce <OUT-####> [slack-url]` |
| A **ticket** whose real blast radius looks undescribed | `refine-ticket` |
| **Anything else** — prod errors, latency, stuck jobs, OOMs, disconnects, data questions | `oncall-triage` (CloudWatch / Sentry / Hex / codebase) |

Invoke the chosen skill with everything Step 1 gathered pre-filled (study ID,
thread ID, timestamps, org) so it skips its own context-gathering. More than one
can apply — a study-agent bug with a visual symptom wants both.

If a specialist comes back empty or says the case is out of its scope (e.g.
`debug-study-agent` on a v1 one-shot study with no thread), say so plainly and
fall back to `oncall-triage` — don't quietly present "no data" as "no problem."

**State confidence honestly.** "Confirmed — here's the log line" and "likely, but
I couldn't reproduce" are different answers. Never dress a hypothesis as a finding.

## Step 4 — Local knowledge that saves time

Verified specifics that aren't in `oncall-triage`, or that correct it:

- **Prod CloudWatch from the devbox needs `aws --profile outset`** — it authenticates
  via instance metadata, so no `aws sso login` is required (contrary to
  `oncall-triage` Step 2). Bare `aws` hits the empty devbox account; the `-admin`
  profile has expired SSO. If `--profile outset` genuinely fails, *then* it's an
  auth problem.
- **Hex queries against `interviews_chat.metadata`** — `metadata ? 'key'` has no
  GIN index, so it seq-scans the whole table and the read replica kills it with a
  recovery conflict. Narrow by `survey_id` / `type` / `created_at` first. For
  wide time ranges use a per-day `LATERAL` instead of one big scan.
- **Hex's catalog hides real columns** (e.g. `users_organization.name`,
  `interviews_message.text`). Give the Hex agent the schema explicitly and have it
  run raw SQL rather than trusting `ViewTables`.
- **Interview modality** is `interview_method`, not `v2v_model` — V2 is set on
  non-voice interviews too, so `v2v_model` misclassifies.
- **Public names in anything user-visible**: the `Survey` model is a **study**, the
  `Chat` model is an **interview**. Use the public names when writing up.

## Step 5 — Ticket, if one is warranted

If it's a real bug with no ticket, offer to create one (Daniel usually wants this,
and often assigned to himself). Put the **detailed** evidence — log lines, file
paths, query output, affected IDs — in the Linear ticket, not in Slack.

Bug tickets on the Engineering team need a `Source` label: `Source ▸ external` if a
customer/participant/CS reported it, `Source ▸ internal` if engineering, Sentry, or
monitoring caught it. It's reporter-based, not impact-based. Leave it unset if
genuinely unclear rather than guessing.

Never put real customer IDs into test fixtures if the fix comes next — use
synthetic placeholders.

## Step 6 — Report back

**In the conversation**, give Daniel the answer directly: what's happening, how
bad, what to do. This part can be technical — he's the audience.

**For Slack, always go through `slack-post`** (`Skill(skill="slack-post")`) — pass
it the thread URL so it replies in-thread, plus the findings. That skill owns
length, structure, plain language, and Slack's markdown quirks. Do not hand-write
the Slack message here, and do not paste the conversation write-up into Slack —
it's calibrated for Daniel, not for the thread.

Post only when Daniel asks, or confirms the draft. `slack-post` drafts for review
by default; `--post` on this skill passes through.

Then, when they apply:
- **Customer-facing?** Offer `/cs-bug-summary` for the CS-ready version.
- **Needs an owner?** Include the `code-owners` result — and say so plainly if it
  came back with no clear owner.
- **Wants a fix now?** Hand off to `/ship-ticket` (or `--hotfix` for production).
