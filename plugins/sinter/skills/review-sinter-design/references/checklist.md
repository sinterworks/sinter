# Sinter design critique reference

## Finding classes and decision tests

Classify every finding with one of four letters, or drop it entirely:

| class | meaning | decision test |
|---|---|---|
| **A** | Blocking defect | A concrete real input produces a wrong result or omits a required result; two normative texts or a normative item and a vector contradict each other; an item contradicts a cited standard or cited design such that a cooperative engineer could follow either text and produce a different result on a real input; a behavioral rule lives only in prose or `@example` (including text after an `@example` line); an `@example` contradicts its parent or vectors; a genuine ambiguity splits cooperative implementations; a real safety gap exists; a program obligation (`must` or `may`) sits inside `@term`, `@schema`, or `@atom`; or the design contains forbidden content (project history, rejected alternatives, reasons for past rulings, internal process notes, references to citing (higher-layer) designs, or any other content that the host repository forbids in a design, such as specific tool or library names or explanatory `"because"` notes). Note briefly when a Class `A` fix is trivial (such as deleting one stray sentence). |
| **B** | Clarity, structural, or coverage defect | Behavior is sound (or a real minor edge case exists), but a real gap hurts implementers or maintainers: unclear wording, an undefined project-local word, duplicated prose rules, a missing or unused `@cites` pin, a missing inline `sinter:` citation in an `@example`, parent `@cites` added only for an `@example`, a wrong cited standard section number, an unmarked departure where the design states its own rule clearly (and vectors settle it) and only the departure label is missing, an inaccurate vector schema table, untagged or drifted sample vector lines inside `@schema`, a misleading vector `"note"`, precomputed vector inputs that leave a derivation rule untested, or missing vector coverage for a real boundary case. |
| **C** | Polish or bloat trim | Style, grammar, terminology drift in vector notes, redundant `@term` or superfluous `@example` cleanup, or defensive wording that can be shortened without changing meaning. |
| **O** | Open choice for the author | An unresolved choice of core behavior, policy, resource limits on external input (when not settled by a cited design), or scope that the sources do not decide. State concrete options, any unread sibling section that may already settle it, and your recommendation; never decide it yourself. |
| **Drop** | Contrived or out-of-tier objection | A bad-faith loophole, a demand to define ordinary verbs such as "return" or "represent", a request to restate a cited standard, or a request to duplicate vector edge cases in prose. Do not file it. |

## Section-by-section audit checklist

### 1. Non-normative prose

- Opens on the domain purpose rather than meta-narration about "this document"
  or rule-counting lead-ins. (The single-line brief attached to `@design` for
  citation indexes is structural; check that it is a complete sentence with a
  subject about the domain rather than a subjectless fragment or prose about
  "this document".)
- States no behavioral rule that is absent from the normative items.
- Does not recap lists of requirements or mechanically inventory `@cites`
  targets.
- Keeps any Glossary limited to project-local words shared across sections,
  never copying basic terms from cited designs or cited standards.
- Contains no forbidden content: project history, rejected alternatives,
  reasons for past rulings, internal process notes, references to citing
  (higher-layer) designs, or any other content that the host repository forbids
  in a design (such as specific tool or library names, or explanatory
  `"because"` notes). A sentence in orientation prose that states why a
  mechanism exists in the domain is allowed; a sentence that states why the
  author chose a rule, or why a sentence exists, is not.

### 2. `@example` blocks

- Appears only where a concrete input-output pair or scenario resolves a
  genuine subtlety or multi-item interaction. Flag obvious restatements as
  Class `C` (delete).
- Stands after the normative text of its parent declared item (`@design`,
  `@spec`, `@schema`, `@req`, `@atom`, or `@term`). For a `@spec` or `@design`,
  stands at the end of its introduction, before its first child item. Every
  line after an `@example` line, up to the end of the item, belongs to the
  example; any behavioral rule written there is outside the parent item's
  hashed text and is a stranded rule (Class `A`).
- Agrees completely with its parent item, with every other normative item it
  touches, and with the test vectors. Any disagreement is Class `A`. (Sinter
  does not flag an `@example` when its own parent item changes, so always check
  examples on revised items against their parent text.)
- Holds no behavioral rule missing from the normative items. Any rule stranded
  only in `@example` is Class `A`.
- Uses checked inline citations (`[label](sinter:...)`) for other items whose
  syntax or semantics the example relies on (even when the parent item already
  pins them), and does not force the parent item to add `@cites` entries used
  only by the example. Missing inline citations or parent `@cites` pollution
  are Class `B`.

### 3. Normative items (`@spec`, `@schema`, `@req`, `@atom`, `@term`)

- Uses the right item kind: `@term`, `@schema`, and `@atom` stay declarative
  present tense; program obligations (`must`) and optional permissions (`may`)
  live in `@req`.
- **Scoped engineering vocabulary (`B`/`C`):** Uses the standard technical words
  and phrases that software engineers expect, even when another design uses the
  same word in its own scope (because each item belongs to a named design, such
  as `config#location` and `diagnostics#location`). Keeps one meaning per term
  within the design (including all of its `@spec` sections) and its cited
  definitions, and uses plain fixed phrases whenever two meanings meet in one
  design (such as "config location" and "diagnostic location"). Flag folksy
  substitutes or same-design term clashes as `B` or `C` (class `A` when the
  clash splits cooperative implementations); do not demand synonyms solely to
  avoid cross-design overlap.
- Passes the single-use test for `@term` and avoids artificial splits of
  tightly paired operations.
- Pin hygiene (`B`): pins every normative item and external standard that the
  item's own text depends on (checking that cited terms match the domain range
  needed, such as signed vs. non-negative numbers), carries no unused `@cites`
  pins, forms no pin cycles, and never points at prose or section numbers. (In
  an excerpt review, flag an unpinned word when it names a cited-design item or
  an item declared inside the excerpt, and note when a word may come from an
  unread sibling section.)
- Distinguishes routine invalid-input handling (stated directly in the
  operation's contract) from genuine safety invariants (unqualified one-sentence
  guarantees of what a conforming program never does).
- For operations reading external or untrusted input, checks whether resource
  limits (depth, size, time) are handled by a cited design or leave a genuine
  interoperability open question (`O`).
- Matches exactness to the boundary: exact grammars, tables, or algorithms for
  wire formats, hashes, and identifiers; plain rules paired with thorough
  vectors for behavioral features.
- For cited external standards: checks that every cited section number points
  to the right section, that departures from the standard are marked cleanly,
  that ordinary standard rules are not restated, and that secondary standards
  whose exceptions cost more prose than narrowing the primary standard directly
  are skipped.

### 4. Test vectors and vector-group schemas

- Every vector's `input`, `result`, and `values` agrees with the normative
  items. Any disagreement is Class `A`. For large files, check every line with
  a small independent script built from the normative items, and also inspect
  boundary cases manually.
- Every behavioral rule exercised by the vectors has a home in the normative
  items. Any unmentioned feature tested by vectors is Class `A`.
- Derivation-rule check (`B`): vector inputs supply the raw values that a
  derivation rule consumes, not precomputed intermediate results.
- Real boundary values, error cases, and subtle interactions are settled in the
  vector file. Missing coverage for a real boundary case is Class `B` (propose
  the concrete vector) rather than a demand for legalistic prose.
- Vector `"note"` fields are non-normative human aids: a note that states a
  false or misleading reason is Class `B`; terminology drift in notes is
  Class `C`.
- Test-vector files are linked explicitly in `sinter.toml` via
  `[designs.<design>]` or `[designs.<design>.specs.<spec>]` with
  `test-vectors = "<path>"` (never matched by filename convention). A
  design-level file tests schemas and cited requirements anywhere in the design
  (including inside `@spec` sections), while a `@spec`-level file tests schemas
  and cited requirements in that `@spec`.
- Vector-group `@schema` sections name the test-vector file with a Markdown link
  (matching the path that `sinter.toml` links) once per `@spec` or once in a
  design-level `## Test vectors` section. When a `@spec` has only one group,
  place the file reference and the single `@schema` directly under
  `### Test vectors` without an extra wrapper heading. Each group table matches
  the JSON fields in the test-vector file accurately (`field | type | meaning`
  with path notation, omitting `result` when unused, marking optional fields and
  empty `"values":{}` cases clearly), and states `needs` conventions once per
  `@spec` (or once in a design-level `## Test vectors` section).
- Any sample JSONL lines embedded at the end of a vector-group `@schema` stand
  inside a trailing `@example` block with a lead line inline-citing the tested
  requirement (and any key definition) and match the vector file verbatim
  (including `"note"` if present). Untagged, uncited, or drifted sample lines
  are Class `B`.

## Choosing the simplest fix

Match every finding to a remedy that simplifies or anchors the design instead
of bloating it:

| defect pattern | right remedy | wrong remedy (avoid) |
|---|---|---|
| Real ambiguity between two cooperative readings | Rewrite the sentence as the simplest stronger rule, and add a test vector settling the chosen reading (or file Class `O` if unruled). | Append a multi-clause caveat or `"when, and only when"` wrapper. |
| Missing real boundary case or untested derivation rule | Add concrete test vector(s) to the test-vector file. | Expand normative prose to enumerate every combination. |
| Normative item contradicts vectors | Check which side the schema table, the other vectors, and any `@example` support; propose fixing the single disagreeing sentence (noting the reverse as an `O` fallback if the author intended that sentence). | Rewrite both without checking the surrounding evidence. |
| Behavioral rule stranded in prose or `@example` | Move the rule once into the owning normative item; trim the prose sentence. | Copy the rule into the normative item while leaving the duplicate in prose. |
| Contrived bad-faith loophole (e.g., emitting duplicate results) | Drop the finding. | Demand `"once and only once, and no other X"`. |
| Missing or unused `@cites` pin | Add the missing pin or delete the unused pin; delete sentences that duplicate another design's rule in prose. | Leave dead pins or restate the cited design's definition inline. |
| Stale, uncited, or untagged sample vector lines | Wrap verbatim lines in `@example` with a lead inline citation, or delete the sample block if the table and file reference suffice. | Leave drifted copies inside normative `@schema` text. |

## Report structure

Put what the author or lead must act on first, and give every finding across
all classes (`A`, `B`, `C`, `O`) the same four parts—**location**, **quoted
text** (copied verbatim from the source), **defect / evidence** (with any
unread-source condition stated explicitly), and **simplest fix** (or options +
recommendation for `O`):

1. **Summary and finding counts:** Counts by class (`A`, `B`, `C`, `O`), overall
   readiness verdict, and what you verified (which sections, cited sources,
   read boundaries, and vector counts).
2. **Class `A` findings (if any):** Numbered (`A-1`, `A-2`, ...). Note briefly
   if a blocking fix is trivial (such as deleting one forbidden sentence).
3. **Class `O` questions (if any):** Numbered (`O-1`, ...). State the question,
   facts, concrete options, any unread sibling section that may already decide
   it, and your recommendation.
4. **Class `B` findings (if any):** Numbered (`B-1`, ...). Include concrete
   proposed JSON vector lines for coverage gaps.
5. **Class `C` findings (if any):** Numbered (`C-1`, ...). Polish or bloat to
   trim.
6. **Verification notes:** Always include a concise per-group or per-vector
   trace summary (so clean verdicts are auditable), explicit assumptions
   resting on unread cited designs, and any borderline objections you evaluated
   and dropped.
