---
name: write-as-daniel
description: Draft documentation, proposals, process docs, and RFCs in Daniel's own voice, so the result reads as if he wrote it rather than as if it was generated. Covers structure, register, punctuation, the good/bad example pattern, callouts, RFC 2119 usage, and how he handles open questions. Use whenever writing or editing prose that will go out under his name, especially Notion docs and specs. Also use when reviewing a draft for whether it sounds like him.
user_invocable: true
argument-hint: "[doc-url-or-path] [--exemplars]"
---

# Write as Daniel

Draft prose that reads as if Daniel wrote it. The test is not "is this good
writing," it is "would a colleague who knows his docs notice a difference."

Reviewers of his spec docs have said outright that copy which looks AI-authored
is a problem. Treat every rule below as a way of failing that test less often.

## The one rule

**No em dashes. Ever.** Not in prose, not inside code-block examples, not in a
PR body or a commit message. He does not use them, and an em dash is the single
most reliable tell that a passage was drafted rather than written.

Pick the punctuation that actually fits the join:

| what you want | use |
|---|---|
| a parenthetical aside | parentheses |
| a list, expansion, or definition | a colon |
| two independent clauses, closely linked | a semicolon |
| two independent clauses, less linked | a period |
| a light pause | a comma |

He writes semicolons happily: *"Our codebase is expansive; it's easy to miss
something crucial when speccing out a new feature."* Reach for one before you
reach for a dash.

## Structure

- `##` for top-level sections, `###` for subsections, `####` for individual
  named conventions or rules.
- Open a section with **one sentence that defines the thing**, then stop.
  "In a sentence:" ends its own line; the definition lands on the next line as a
  **standalone italic sentence**, quotable on its own:

  > Every project reaches a point where product and design hand the work to
  > engineering. In a sentence:
  > *Engineering should start scoping once the direction is settled and the
  > designs aren't expected to change much.*

- **Standalone italic lines** carry any principle meant to be quoted back:
  *Each code owner will be responsible for modularizing and speccing their
  domain.*
- **Do not add an italic clarifier** of the *X, not Y* form after a definition.
  It reads like his, but it comes from the tech-lead section of "Project
  Collaboration With Engineering", which he does not own. He deleted the one
  drafted for him.
- Numbered lists for anything sequenced or countable ("The four jobs", a quick
  reference). Bulleted lists for everything else.
- Bulleted items lead with a **short label, a colon, then the explanation**. How
  the label is bolded varies and is not worth agonizing over. All three of these
  are his:

      - Ship fewer bugs: AI is all too happy to implement without proper care.
      - **Greenfield projects**: Medium-large, net new addition to our codebase.
      - **REST and WebSocket routes:** One line per route in a plain code block.

  Plain labels suit prose-heavy argument lists; bold suits reference material a
  reader scans for one row.
- **Open a proposal with an unheaded paragraph**, two sentences, saying why now.
  No "## Summary" above it. *"We've been experimenting with spec driven
  development systems somewhat in isolation for a month or so now. It's time to
  pool our learnings and build out our shared system."*
- **Goals, then Non-goals.** Non-goals is where he defuses the objections he
  expects, before anyone raises them: dogmatic enforcement, a perfect plan, full
  coverage on day one.
- **A blockquote holds a worked example of a proposed process**, introduced by
  something like "One possible system:". It keeps an illustration visibly
  separate from the rule it illustrates.
- End a proposal with a section that names what is still unresolved. He calls it
  **Missing pieces**. Do not pretend completeness.

## Register

Plain and direct, conversational without being chatty. Specifics:

- **"We" for team norms, "you" for instructions, "I" for his own judgment.**
  *"We're trying to associate each spec file with a module"*, *"It's up to you to
  decide whether your changes belong in the base spec"*, *"That said, I doubt
  anyone would say AI is at a point where we're comfortable with..."*. He owns an
  opinion in the first person rather than hiding it behind the team.
- **Argue a goal with a concrete story, not an abstract claim.** The rollout
  proposal's long-term goals are three present-tense narratives with invented
  props: a `cool_thing` module missing a database index, a paginated endpoint
  the frontend only reads the first page of, and a future Anthropic model called
  "Magnum Opus 8". Specificity is doing the persuading, and the invented names
  carry the humor.
- **Short declaratives.** One idea per sentence. If a sentence has two commas
  and a subordinate clause, split it.
- **Dry asides are in character**, sparingly: "kinda clunky", "Looks cool, but
  not well known", "gobs of completely impenetrable text", "Plenty of open
  questions to ponder."
- **"That said,"** is his pivot into a qualification.
- An exclamation mark is allowed, about once per doc: *"Don't simply accept all
  its recommendations!"*
- **Contractions throughout.** "don't", "it's", "we're".
- **Frame a rule around what the reader should do, not what another team owes.**
  "Engineering should start scoping once the direction is settled" replaced
  "product and design hand over once the direction is settled". Same trigger, no
  finger pointing at the other function. He also cut the contrastive jab that
  followed it ("not when they're pixel-final").
- **Plain repeated words beat elegant variation.** "Expect details to change
  afterward, and expect engineering to ask questions that change them" replaced
  a version that used "keep moving" and "move them" to avoid the repeat.

## What he cuts from a draft

Learned from diffing his edits against what was handed to him. These are the
highest-yield things to not write in the first place:

- **Meta-commentary about the document itself.** He deleted "they're
  deliberately not restated here so there's only one source of truth." The doc
  should do the thing, not narrate its own design.
- **Hedging and throat-clearing.** "it's best not to completely offload the spec
  writing to AI" became "don't offload the spec writing to AI."
- **Reassurance nobody asked for.** He deleted a whole paragraph reassuring
  readers that agents would do the drafting work.
- **Explaining the obvious consequence.** State the rule, trust the reader.
- **Rhetorical flourishes.** He deleted the parallel pair "None of that needs
  final pixels. All of it needs settled direction." Make the point once.
- **Consequence clauses that editorialize.** "It moves the same scoping work into
  whatever days are left, which is how a project ends up with its plan written
  under deadline" became "It shifts out the scoping work by however many days are
  needed to finalize." Give the mechanism, skip the moral.
- **Over-prescription.** "Direction, not deliverables. Enough for engineering to
  size the work and find the risk:" became "This will be case-by-case, but
  direction is usually enough." He leaves room for judgment where a rule would
  be brittle.
- **Whole sections that over-elaborate**, however well argued. A per-scale
  breakdown of when to hand off (Planet / Country / City, one bullet each) was
  cut outright; a single clause referencing the scale survived in the prose
  above it. If the point is already made, the section is padding.

## Examples: the ✅ / ❌ block

His signature device. A single fenced block, good case first, each case labelled
with **why it is good or bad**, never a bare "good"/"bad".

````markdown
✅ Easy to reference later
- **FR-1:** A thing MUST have a name.
- **FR-1a:** The name MUST be capitalized.

❌ Easier to parse visually, but harder to reference
- **FR-1:** A thing MUST have a name.
  - The name MUST be capitalized.
````

Two things that make these read as his:

- **A running toy example reused across the whole doc.** In the spec flow
  proposal it is a `Thing` whose name must not be "Tim". Invent one per doc and
  keep using it; it makes examples cohere and is quietly funny.
- **Notion cannot nest a fence inside a fenced block.** Writing one through the
  API silently corrupts the block into escaped rich text. When an example needs
  its own language tag, emit separate top-level code blocks with the ✅/❌ labels
  as plain lines between them.

## Callouts (Notion)

- `<callout icon="ℹ️" color="blue_bg">` for an aside or a parked open question.
- `<callout icon="⚠️" color="yellow_bg">` for something that must not be missed.
- `<callout icon="✅" color="green_bg">` / `<callout icon="❌" color="red_bg">`
  for a good/bad pair too long to sit in a code block.

## RFC 2119: match the surrounding doc

MUST / SHOULD / MAY / MUST NOT / NEED NOT / IFF, capitalized, in **normative**
docs that set rules. He uses IFF where it genuinely means if-and-only-if.

**Process and narrative docs do not use them.** "Project Collaboration With
Engineering" says "Decide prior to engineering work commencing where possible",
not "MUST decide". Read the doc you are adding to and match its register rather
than importing caps from elsewhere.

## Open questions

He parks what is unresolved instead of resolving it silently or omitting it. Two
forms:

- A **Missing pieces** section at the end of a proposal, bulleted, each item a
  bold label and the question in plain terms.
- An **ℹ️ callout** at the end of a section, for a question local to that section.

State both sides briefly. From the handoff section: *"A bar makes it checkable
and harder to skip, but it also risks recreating the pixel-final problem one
rung further down."*

## Exemplars

Fetch these when a draft needs close mimicry, or when this guide does not cover
the case. Listed best-first for voice.

| doc | why it is a good sample |
|---|---|
| [Spec driven development flow proposal](https://app.notion.com/p/3b8543209c1380d394b3dd6d780faeba) | The fullest sample. Conventions with ✅/❌ blocks, RFC 2119, all four callout types, a running toy example, a Missing pieces section. |
| [Spec driven development rollout proposal](https://app.notion.com/p/3b4543209c1380bb9974f9ed779f9fe5) | Goals / Non-goals framing, standalone italic principle lines, a phased plan with explicit time bounds. |
| [Project Collaboration With Engineering](https://app.notion.com/p/32c8a097f8e340bcbe7afe33d385df88) | Process-doc register with no RFC 2119. **Only the "Handoff from product and design" section is a voice sample.** The tech-lead section above it is owned by someone else and uses em dashes; do not learn from it. |

Related but not voice samples: [Eng Project Review
Process](https://app.notion.com/p/3a3543209c138005acf3e93987c54c82) defines the
Planet / Country / City scale, which his docs reference.

### Frozen sample

Kept here so the skill still works when the Notion connector is unauthorized or
a doc moves. Verbatim from the flow proposal, 2026-08-19:

> #### Prefer number + letter for requirement subitems
>
> Using whitespace to delineate subsections reads nicely, but makes the item
> harder to reference.

Note the shape: a `####` naming the rule as an instruction, then exactly one
sentence that concedes the alternative's appeal before saying why it loses. Then
the example block. No preamble, no summary afterward.

## Keeping this current

**His edits to a draft are the signal, and they arrive before he articulates the
rule.** The em-dash rule was visible in three separate edits (an em dash swapped
for a period, one for a colon, one for a comma) before he said it out loud.

So: after he edits something drafted here, diff his version against the draft,
and fold anything that generalizes back into this file. Ask before adding a rule
that is really a one-off preference for a single doc.

Update by editing this file directly, then `cd ~/dotfiles && git commit`. The
skill is symlinked into `~/.claude/skills/`, so an edit at either path is the
same file, and committing is what propagates it to his other machines.
