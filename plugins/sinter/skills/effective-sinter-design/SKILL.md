---
name: effective-sinter-design
description: >-
  Write and revise software designs and specifications that use Sinter's tag
  vocabulary and conformance test vectors. Use when authoring a new Sinter
  design or revising an existing design or specification section for clarity,
  precision, and human editability. (To review or critique an existing Sinter
  design, use the companion skill `review-sinter-design`.)
---

# Effective Design and Specification Using Sinter

Follow any writing conventions that the host repository sets; otherwise write
clear, direct technical prose. A Sinter design aims to be easy for the human
author to edit, direct enough for future agents to use when implementing or
investigating code, and exact enough for conformance tests to check. (To review
or critique a design, use the companion skill `review-sinter-design`.)

## Core model: three-tier specification

Each tier of a Sinter design is more precise than the tier before it, with a
distinct audience and job:

| tier | primary audience | job | precision level |
|---|---|---|---|
| **Non-normative prose** (design intro, `@spec` intro, `@example` blocks) | Readers and the human author | Orient the reader on what the part does and illustrate concrete cases. | Brief and readable so the human author can edit it directly. Editing a `@design` or `@spec` introduction changes the hash of that `@design` or `@spec` but never the hashes of its child items (`@schema`, `@req`, `@atom`, `@term`), and editing an `@example` block never changes its parent item's hash. |
| **Normative items** (`@spec`, `@schema`, `@req`, `@atom`, `@term`) | Engineers and future agents that implement or investigate code | State directly what is or must be true; ground code and reviews in declared behavior. | Precise within reason for plain language; consistent with and covering the test vectors. |
| **Test vectors** (JSON Lines vector files linked in `sinter.toml` and vector-group `@schema`s) | Implementations and conformance suites | Decide whether an implementation conforms on exact inputs and boundary cases. | Exact concrete inputs, boundary values, and subtle interactions. |

Plain language cannot match the arbitrary precision of code or structured data
without turning into unreadable legal prose. Do not force normative prose to do
the job of test vectors. Keep normative items clear, direct, and consistent
with every vector, and let test vectors settle fine edge cases. When a vector
and a normative item disagree, the design has a defect that the author must
resolve.

In Sinter, a **pin** is a citation that names an item at one revision, such as
`#retry-policy=v1`. A **layer** is a level in a dependency stack of designs: a
**cited design** sits below a **citing design**.

## Before you write: know your reader

The most common failure in agent-written designs is writing defensively against
a bad-faith critic. Real design work serves cooperative engineers who want to
build a correct program and future agents that need direct grounding in
declared behavior.

Before drafting or revising a design, think about each reader:

1. **Identify the reader and the questions they bring.** Ask what an engineer
   implementing this component needs to know, what an agent investigating a bug
   later will look up, and what the human author editing the prose wants to see.
2. **Gather missing context through questions first.** When the audience,
   boundaries, open behavior choices, or relationship to existing standards are
   unclear, ask the author before drafting. Do not paper over missing context
   with bloated summaries or invented constraints. When a written task
   description already answers these questions, use that description; if a real
   gap blocks a sound design, stop and report the gap.
3. **Hold every clause to the cooperative-engineer test.** Before keeping a
   qualification or edge-case rule in prose, ask whether a cooperative engineer
   would genuinely misread the behavior without that clause. If the edge case
   is real, settle it in a test vector. If only a contrived reading produces
   the problem, omit the clause.

## Writing each tier

### 1. Non-normative prose and `@example` blocks (primarily for humans)

Non-normative prose orients readers and stays easy for the human author to edit
in final passes.

- **Orient on the domain, not on the document.** Open a design or `@spec` by
  stating what the mechanism or format does in the system and why it exists in
  the domain. Do not open with prose about "this document", and do not walk
  step by step through rules that the normative items state right below.
- **State rules once, in normative items.** Non-normative prose never lists
  requirements or summarizes definitions that follow. If deleting a prose
  sentence removes a behavioral rule, move that rule into the appropriate
  normative item.
- **Use `@example` selectively.** Most items need no `@example` block at all.
  Add an `@example` block only when a concrete input-output pair or short
  scenario resolves a genuine subtlety, boundary case, or non-obvious
  interaction that a reader could misread from the rule alone. Skip `@example`
  on straightforward definitions and obligations where the rule already speaks
  for itself. Place each `@example` block after the normative text of its
  parent declared item (`@design`, `@spec`, `@schema`, `@req`, `@atom`, or
  `@term`). For a `@spec` or `@design`, place `@example` blocks at the end of
  its introduction, before its first child item.
- **Track example dependencies accurately.** Sinter extracts and hashes each
  `@example` as its own anonymous, uncitable `example` object with a 1-based
  index attached to its parent item, outside the parent item's hashed text.
  Editing an `@example` never changes the parent item's hash or revision.
  Because each `example` object carries its own edges, write inline citations
  (`[label](sinter:...)`) inside an `@example` for any other item whose syntax
  or semantics the example relies on—even when the parent item already pins
  that target in `@cites`. Never add `@cites` on the parent item solely for an
  `@example`. Sinter does not flag an `@example` when its own parent item
  changes, so re-read every `@example` on an item that you revise.
- **Skip mechanical inventories.** Let the `@cites` tag block record
  dependencies rather than listing every cited design and standard in prose.
  Omit a Glossary section unless several sections share project-local words
  that genuinely need quick reference; never copy basic terms from cited
  designs into a Glossary.
- **Let structure speak directly.** Start sections and lists with their
  substance rather than sentences that announce how many rules follow or praise
  their virtues.

### 2. Normative items (for humans and future agents)

Future agents use normative items directly when writing code, writing tests, or
investigating how a module behaves. Write every normative item so that a reader
can act on it without decoding legal jargon.

**Slice into focused `@spec` units.** Divide a design into cohesive `@spec`
sections—one focused feature or data format per `@spec`—so an agent
investigating one behavior can read one small unit instead of an entire
subsystem. A small design on one topic can use plain Definitions, Requirements,
and Test vectors sections without `@spec`.

**Choose the right item kind:**

| kind | use it for | decision test |
|---|---|---|
| `@spec` | One cohesive feature or data format with its own definitions, requirements, and vectors | Can an engineer understand, implement, or look up this capability as one unit? |
| `@schema` | The layout and self-contained constraints of a whole concrete input, output, parameter binding, or vector group | Does this define the complete shape of something crossing a boundary? |
| `@req` | One testable obligation or optional permission on a conforming program | Does this bind what a conforming program must do, may do, return, or avoid? |
| `@atom` | An observable outcome, state, result word, or finding class, plus the condition that produces it | Does a requirement oblige a program to emit this named outcome or classification? |
| `@term` | A shared concept, grammar production, relation, or computed value | Do two or more normative items—or a citing design—depend on this exact meaning? |

Apply the **single-use test** to `@term`: if only one requirement or schema
uses a detail, keep that detail inside that item instead of declaring a
separate `@term`. Likewise, group tightly paired behaviors—such as validating
an input and returning its decoded value—into one `@req` unless callers
genuinely implement them independently.

**Write direct obligations and definitions:**

- **Keep definitions declarative; put `must` and `may` in `@req`.** Write
  `@term`, `@schema`, and `@atom` in declarative present tense. Place program
  obligations (`must`) and optional permissions (`may`) only in `@req` items.
- **Assume ordinary engineering meaning.** Do not define ordinary verbs such as
  "return", "give", or "represent" for values.
- **Use standard engineering vocabulary.** Use the standard technical words and
  phrases that software engineers expect. Standard technical words improve
  clarity even when two designs use the same plain word for different concepts,
  because each declared item belongs to a named design (for example,
  `config#location` and `diagnostics#location`). Within one design, use one term
  for one meaning, and use that term the same way every time. All `@spec`
  sections of a design share the terms of that design, and the definitions that
  a design cites count as terms of that design. Do not coin a substitute or
  folksy word only because another design uses the standard word. Prefer the
  word that software engineers, a cited standard, a cited format, or a cited
  design already use for that meaning. When two meanings of one standard word
  meet in one design, give each meaning a plain fixed phrase (such as "config
  location" and "diagnostic location"), and use that fixed phrase every time.
- **Distinguish routine input handling from safety obligations.** State invalid
  input behavior plainly as part of the operation's contract (for example, the
  operation rejects the input and returns no value). Reserve unqualified
  one-sentence safety guarantees—stating what a conforming program never
  does—for genuine safety invariants such as refusing side effects, network
  calls, path escapes, or continuing to process input or reporting success
  after reaching a resource limit.
- **Account for resource limits on untrusted input.** For operations that read
  external or untrusted input, check whether resource limits (such as depth,
  size, or time) are settled by a cited design or require an explicit choice
  from the author.
- **State multiplicity or exclusivity only when genuinely ambiguous.** Write
  plain obligations first. Add an explicit uniqueness or completeness condition
  only when a cooperative implementation could otherwise emit duplicates or
  extra outputs.
- **Match exactness to the boundary.** Write exact ABNF grammars, tables, or
  step-by-step algorithms where bytes, wire formats, hashes, or shared
  identifiers must match across implementations. For behavioral features, state
  the rule plainly and let test vectors settle fine combinations.
- **Cite external standards only when they simplify.** When a published
  standard fits cleanly, cite it, verify every cited section number against the
  standard, and state only the project's narrowings or departures in a short
  table or list. You may briefly note a simplified consequence of your narrowed
  domain or clarify a known caveat in the cited standard so implementers avoid
  real bugs, without restating the standard's ordinary rules. Skip any
  secondary standard whose exceptions take more prose than stating the rules
  directly against the primary standard.
- **Keep `@cites` accurate and acyclic.** Pin every normative item and standard
  that the item's own text depends on, form no pin cycles, never point at prose
  or section numbers, and drop unused `@cites` pins so changes to unrelated
  items do not trigger false review noise.

### 3. Test vectors (conformance arbiter)

Treat each test-vector JSON Lines file (linked explicitly in a root or nested
`sinter.toml` via `[designs.<design>]` or `[designs.<design>.specs.<spec>]`
with `test-vectors = "<path>"`) as part of the specification, not an
afterthought. A design-level `test-vectors` file tests schemas and cited
requirements anywhere in that design (including inside `@spec` sections); a
`@spec`-level `test-vectors` file tests schemas and requirements declared in
that `@spec`.

- **Cover normal inputs and real edge cases thoroughly.** Every boundary value,
  error case, derivation rule, and non-obvious interaction that a real user or
  implementation can hit belongs in the vector file. Supply raw inputs before
  declared derivation rules rather than precomputed intermediate values that
  leave the derivation untested.
- **Keep normative text and vectors aligned.** Normative items must agree with
  every vector and must cover the behaviors the vectors test, while leaving
  exhaustive enumeration of boundary combinations to the vectors.
- **Write compact vector-group schemas.** State shared vector-file conventions
  (the Markdown reference to the file, byte encoding, and `needs`) once per
  `@spec` (or once in a design-level `## Test vectors` section), without
  repeating conformance boilerplate paragraphs in every specification. Define each group in a compact
  `field | type | meaning` table (using path notation such as `events[].id` for
  nested objects and omitting `result` when a group does not use it). If you
  include one or two sample JSONL lines at the end of a vector-group `@schema`,
  place them in a trailing `@example` block with a short lead line inline-citing
  the tested requirement (and any key definition) above the verbatim line copied
  from the test-vector file.

See [references/syntax.md](./references/syntax.md) for Sinter core terms, tag
syntax, revision and hashing rules, `@example` mechanics, brief-line
conventions, item naming, partial-rewrite rules, and formatting conventions.
See [examples/before-after.md](./examples/before-after.md) for annotated worked
contrasts across a behavioral feature, a data format, and a vector-group
schema.

## Root impulses behind weak designs

Recognize the underlying impulses that produce bloated designs and replace each
impulse with sound craft:

| root impulse | typical symptom | remedy |
|---|---|---|
| **Adversarial defense** | Dense clauses closing contrived loopholes; definitions of ordinary verbs such as "return" or "represent"; unnecessary exclusivity qualifiers. | Apply the cooperative-engineer test. Settle real edge cases in test vectors; cut clauses that exist only for contrived readings. |
| **Conflating validation with safety** | Rewriting ordinary invalid-input rejection as dramatic `"never"` safety rules. | State invalid-input rejection directly as the operation's result. Reserve unqualified `"never"` obligations for real safety invariants. |
| **Fear of leaving context out** | Introductions that recap every requirement; rule-counting opening lines; copy-pasted Glossaries from cited designs; prose lists repeated inside normative items. | Trust the three-tier model. Keep non-normative prose brief for humans, state rules once in normative items, put examples in `@example`, and rely on `@cites`. |
| **Over-atomizing** | Single-use `@term` declarations; artificial splits between validating and returning a value; repeated conformance boilerplate in every `@spec`. | Apply the single-use test, group paired operations into one `@req` where natural, and state conformance links compactly. |

## Scope boundaries

Never put any of the following forbidden content inside a design: project
history, rejected alternatives, reasons for past rulings, internal process
notes, references to citing (higher-layer) designs, or any other content that
the host repository forbids in a design (such as specific tool or library
names, or explanatory `"because"` notes). Set no arbitrary length or item-count
targets: write what clarity and precision require, and stop.

## Self-check before finishing

Before handing a design to the human author or a reviewer, check these points:

1. **Human edit check:** Read only the non-normative prose and `@example`
   blocks. Can the human author understand the orientation quickly and edit
   those paragraphs cleanly without untangling restated rules? Cut any
   `@example` block that merely restates an obvious rule, and re-read every
   `@example` on any item you revised.
2. **Single-source check:** Does every behavioral rule live in a normative item
   rather than only in prose or inside an `@example` block, and appear once
   rather than twice?
3. **Cooperative-engineer check:** Can you cut any clause, definition, unused
   `@cites` pin, or boilerplate paragraph without causing a cooperative
   engineer or future agent to misimplement the feature?
4. **Vector and standard check:** Does every test vector agree with the
   normative items, supply raw inputs for derivation rules, and settle the real
   boundary cases that prose leaves concise? Does every section number of a
   cited standard point to the right section?
5. **Scope check:** Are project history, rejected alternatives, reasons for
   past rulings, internal process notes, references to citing (higher-layer)
   designs, mechanical dependency inventories, and any host-forbidden content
   absent?
