---
name: review-sinter-design
description: >-
  Critique and review software designs and specifications that use Sinter's tag
  vocabulary and conformance test vectors. Use when reviewing a new or revised
  Sinter design, running a requirements critique or cold read, checking
  normative text against test vectors, or verifying that a design stays clear,
  sound, and editable by humans without adversarial bloat. (To write or revise
  a Sinter design, use the companion skill `effective-sinter-design`.)
---

# Critiquing Software Designs and Specifications Using Sinter

Follow any review or writing conventions that the host repository sets;
otherwise write clear, direct technical prose. A grounded design review catches
every real engineering defect, contradiction, and structural gap while keeping
designs concise, workable, and easy for the human author to edit. (To write or
revise a design, use the companion skill `effective-sinter-design`; see
`effective-sinter-design/references/syntax.md` for Sinter core terms, tag
syntax, revision and hashing rules, `@example` extent rules, and vector-file
format.)

## Core model: cooperative-engineer critique across three tiers

A Sinter design serves cooperative engineers building a working program, future
agents investigating or implementing declared behavior, and the human author
editing the prose. It does not exist to defeat a bad-faith adversary who tries
to misread ordinary English.

In Sinter, a **pin** is a citation that names an item at one revision, such as
`#retry-policy=v1`. A **layer** is a level in a dependency stack of designs: a
**cited design** sits below a **citing design**.

Evaluate each tier of a design against its own job:

| tier | what to verify | what not to demand |
|---|---|---|
| **Non-normative prose and `@example` blocks** | Concise domain orientation; zero behavioral rules absent from normative items; every `@example` agrees with its parent and cited items; `@example` blocks appear only where a concrete case resolves a real subtlety. | Exhaustive rule summaries, mechanical inventories of `@cites` targets, mandatory Glossaries for basic words, or `@example` blocks on straightforward items. |
| **Normative items** (`@spec`, `@schema`, `@req`, `@atom`, `@term`) | Direct, consistent rules that cover all behaviors tested by the vectors; standard engineering vocabulary with one meaning per term inside the design and its cited definitions; declarative definitions with `must` and `may` reserved for `@req`; accurate, acyclic `@cites` pins (neither missing nor unused); accurate section numbers and declared departures for cited standards; genuine safety invariants stated cleanly. | Legalistic closure of contrived loopholes, definitions of ordinary verbs such as "return" or "represent", renaming standard engineering words solely because another design uses the same word in its own scope, restatement of cited standards, or boilerplate exclusivity clauses (`"once and only once"`). |
| **Test vectors** (JSON Lines vector files linked in `sinter.toml` and vector-group `@schema`s) | Agreement with normative items; coverage of normal inputs, error cases, derivation rules, and real boundary interactions; accurate `field \| type \| meaning` tables and one Markdown file reference (matching `sinter.toml`) per `@spec` or design-level `## Test vectors` section; any sample lines inside `@schema` tagged `@example` with a lead inline citation and copied verbatim. | Prose restating every boundary combination that the vectors already settle. |

## Two review lenses

Apply both lenses deliberately to catch real defects while keeping restraint:

1. **Specification and vector audit.** Trace the normative items against the
   test vectors, the cited standards, and the cited designs. For a large vector
   file, write a small independent script from the normative items to check
   every line (keeping in mind that a script written by one reader can share
   the design's blind spots, so inspect boundary cases directly too). Hunt
   concrete real inputs that break agreement, rules stranded in prose or
   `@example`, internal contradictions, undeclared standard departures, wrong
   standard section numbers, missing or unused `@cites` pins, precomputed
   vector inputs that leave derivation rules untested, and genuine ambiguities.
2. **Outside-reader and editability audit.** Read the design cold as a
   cooperative engineer with no conversation history, and again as the human
   author. Flag undefined local words, confusing jumps in context, duplicated
   rules between prose and normative items, host-forbidden explanatory
   `"because"` notes, and defensive padding that should be cut.

## Four gate tests before filing a Class `A` finding

Gate tests 1 to 3 apply to behavioral and textual-meaning findings. Two
structural rule violations—a program obligation (`must` or `may`) placed inside
a definition (`@term`, `@schema`, or `@atom`), and forbidden design content—are
Class `A` by rule and require no failing input.

1. **The cooperative-engineer test.** Exhibit a concrete, realistic input—or an
   honest misreading that a cooperative engineer could genuinely make. If only
   a bad-faith or surreal implementation triggers the problem, do not file a
   Class `A` finding; drop it.
2. **The three-tier allocation test.** Check whether a test vector, a cited
   external standard, or a cited design already decides the case. If a real
   boundary case is genuinely unsettled, prefer adding a test vector over
   bloating normative prose.
3. **The simplest-fix test.** Propose the simplest stronger rule, a structural
   cut, or a concrete test vector. Never propose a hedging caveat, an extra
   qualifier, or an `"and no other X"` clause when a simpler rule or a vector
   solves the problem.
4. **The severity-calibration test.** Reserve Class `A` strictly for real
   defects: wrong results on real inputs, contradictions, stranded rules,
   genuine implementation ambiguity, real safety gaps, a program obligation
   (`must` or `may`) inside a definition, or forbidden design content. Put
   clarity gaps, pin defects (missing or unused `@cites`, missing `@example`
   inline citations, or parent `@cites` added only for an `@example`), untagged
   or drifted sample vector lines, and missing vector coverage in Class `B`;
   put polish or bloat trimming in Class `C`; put unresolved behavior or
   resource-limit choices in Class `O`.

## Defects that you must catch

Restraint against contrived objections never means rubber-stamping concise text.
Hunt and file every real defect you find:

- **Wrong results on real inputs (`A`).** A realistic input causes a
  cooperative implementation of the normative text to produce the wrong output,
  or violates a declared safety invariant.
- **Normative–vector disagreement or uncovered behavior (`A`).** A vector
  expects a result or value that contradicts the normative items, or tests a
  feature or decision rule that no normative item states at all.
- **Stranded behavioral rules (`A`).** A rule appears only in non-normative
  prose or inside an `@example` block (including any rule placed after an
  `@example` line), so deleting the prose or example changes required behavior.
- **Contradictory `@example` blocks (`A`).** An `@example` disagrees with its
  parent item, with a cited item, or with the test vectors.
- **Genuine implementation ambiguity (`A`).** Two cooperative engineers reading
  the normative items and test vectors would still build incompatible programs
  on a real input.
- **Internal or cross-design contradictions (`A`).** Two items in the design
  disagree, or an item contradicts a cited external standard or cited design
  such that a cooperative engineer could follow either text and produce a
  different result on a real input.
- **Misplaced obligations and forbidden content (`A`).** Program obligations
  (`must` or `may`) placed inside `@term`, `@schema`, or `@atom`; or forbidden
  content inside a design: project history, rejected alternatives, reasons for
  past rulings, internal process notes, references to citing (higher-layer)
  designs, or any other content that the host repository forbids in a design
  (such as specific tool or library names, or explanatory `"because"` notes).
- **Quiet structural and coverage defects (`B`).** Missing or unused `@cites`
  pins on normative items; missing inline `[label](sinter:...)` citations in an
  `@example` that relies on another item; parent `@cites` polluted solely for
  an `@example`; wrong section numbers in standard references; unmarked
  departures where the design states its own rule clearly (and vectors settle
  it) and only the departure label is missing; precomputed vector inputs that
  leave a derivation rule untested; misleading vector `"note"` strings;
  untagged or drifted sample vector lines inside `@schema`; or missing vectors
  for real boundary cases.
- **Editability bloat to cut (`B` or `C`).** Restated rules in non-normative
  prose, rule-counting lead-ins, copy-pasted Glossaries from cited designs,
  single-use `@term` clutter, or superfluous `@example` blocks that merely
  repeat an obvious rule. Flag bloat for removal so the text gets cleaner, not
  denser.

## Reviewing an excerpt or unread sources

When your read boundary excludes sibling sections, cited designs, or cited
standards:

- **Do not invent defects** about unread cited-design terms; treat established
  cited designs as given unless you have concrete evidence of a mismatch.
- **State conditions explicitly.** If a finding depends on an unread source
  (such as whether a cited term covers negative integers, or whether a sibling
  section already decides an open question), file the finding at the
  appropriate class (`B` or `O`), state explicitly that you did not inspect the
  source, and state the exact condition that upgrades the finding to `A` or
  closes it.
- **Record assumptions in verification notes** whenever a clean verdict rests
  on behavior assumed to live in an unread cited design.

## Root impulses behind weak critiques

Recognize the impulses that derail design reviews—in both directions—and
replace each impulse with grounded engineering judgment:

| reviewer impulse | typical symptom | grounded alternative |
|---|---|---|
| **Adversarial loophole hunting** | Inventing malicious conforming programs (emitting duplicates, choosing perverse representations, exploiting literalist puns) to prove a rule is "incomplete". | Run the cooperative-engineer test. Ask whether an engineer trying to build a working program would actually make that mistake. If not, drop the objection. |
| **Demanding legal closure in prose** | Filing Class `A` findings whenever prose omits a boundary combination that test vectors already settle. | Check the vectors first. If a real boundary case is missing from the vectors, propose adding a vector (`B`) rather than expanding prose. |
| **Standard re-litigation** | Demanding that a design define basic words (`byte`, `UTF-8`), restate rules of a cited RFC or standard, or close undocumented corner cases of an external format. | Check only the design's declared narrowings, departures, section numbers, and real caveats. Leave ordinary standard rules to the cited standard. |
| **Severity inflation** | Filing wording preferences, contrived loopholes, or pin hygiene as blocking Class `A` defects so fixers must appease them. | Calibrate strictly: `A` for real behavioral defects, contradictions, misplaced obligations (`must`/`may`) in definitions, and forbidden content; `B` for clarity, pin, and coverage gaps; `C` for polish and bloat cuts; `O` for open behavior choices. |
| **Patchwork fixing** | Recommending extra qualifiers, disclaimer sentences, or `"once and only once"` clauses to patch an ambiguous sentence. | Recommend the simplest stronger rule, a structural simplification, or a concrete test vector. Never prescribe bloat. |
| **Rubber-stamping concise text** | Excusing real ambiguities, missing rules, or unchecked vectors in the name of keeping text short. | Trace every vector against the normative items (using a small script for large files), verify every `@example`, and check that no rule lives only in prose. |
| **Skimming past quiet structural defects** | Dismissing unused or missing `@cites` pins, wrong RFC section numbers, precomputed vector inputs, or untagged sample vector lines as "pedantry". | Check pin hygiene, standard section numbers, unmarked departures, schema tables, and derivation-rule vector coverage systematically; file real gaps cleanly as Class `B`. |

See [references/checklist.md](./references/checklist.md) for severity
definitions, the section-by-section audit checklist, simple-fix patterns, and
report layout. See
[examples/findings-before-after.md](./examples/findings-before-after.md) for
worked contrasts across restraint, behavioral bug catching, and quiet
structural hygiene. For Sinter syntax and vector-file conventions, see
`effective-sinter-design/references/syntax.md`.

## Reviewer self-check before sending your report

Before delivering a review report, check these points:

1. **Cooperative-engineer check:** For every behavioral Class `A` finding,
   could a cooperative engineer or real input actually trigger this defect?
   Drop any finding that depends on bad-faith reading. Downgrade a finding
   whose input is real but whose impact is minor.
2. **Anti-bloat check:** Does every proposed fix simplify, clarify, or add a
   vector rather than stapling on defensive clauses?
3. **Vector trace check:** Did you trace the normative items directly against
   every vector and include the concise verification summary?
4. **Stranded-rule and structural check:** If you deleted all non-normative
   prose and every `@example` block, would every required behavior still stand
   intact? Did you also check pin hygiene, standard section numbers, and
   whether vector inputs supply raw values for derivation rules?
5. **Scope and restraint check:** Did you avoid demanding restatement of cited
   standards, unnecessary Glossaries, or superfluous `@example` blocks, and
   state explicit conditions for any finding resting on unread sources?
