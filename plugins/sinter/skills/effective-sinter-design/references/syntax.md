# Sinter design syntax and formatting reference

## Sinter basics and core terms

Sinter reads declared items and citation tags in Markdown documents (and code
comments), computes a content hash for each item's canonical object, and checks
citations and conformance test vectors across a repository.

| term | meaning |
|---|---|
| **declared item** | A named, versioned unit declared by a tag (`@design`, `@spec`, `@schema`, `@req`, `@atom`, or `@term`). |
| **revision label** | A version string attached to a declaration (such as `=v1` or `=v2`). |
| **content hash** | The hash of an item's canonical object: its kind, text (excluding trailing `@example` blocks), status tags, and edges. |
| **pin** | A citation naming a declared item at one specific revision (for example, `#retry-policy=v1` or `other#item=v2`). |
| **edge** | A directed link extracted from a tag (`@cites`, `@refines`, `@satisfies`, `@verifies`, `@supersedes`), from an inline `sinter:` citation, or from `@spec` item containment. |
| **`needs-revision`** | Sinter finding reported when a declared item's content hash changed relative to its base revision while its revision label stayed unchanged. |
| **`suspect`** | Sinter finding reported when a pinned citation names an older revision than the target item's current revision, flagging the citing item or `@example` for inspection. |
| **`dangling`** | Sinter finding reported when a citation names a target that does not exist in the repository. |
| **`retired`** | Sinter finding reported when a citation names a target item that is retired or superseded. |
| **canonical JSON line** | One compact UTF-8 JSON object with no insignificant whitespace and keys sorted in UTF-16 code-unit order (RFC 8785 key order), ended by a single LF (`0x0A`). |
| **result word** | A short discrete classification string returned by an operation (for example, `"valid"` or `"invalid"`). |
| **`form`** | Vector-line member naming the pinned vector-group schema (`"#<group>-vector=<rev>"`). |
| **`group`** | Vector-line member holding the lowercase hyphenated group name matching the vector-group schema. |
| **`values`** | Optional vector-line member holding structured expected outputs. |
| **`needs`** | Optional vector-line member holding a sorted array of one or more lowercase hyphenated environment-precondition names. |
| **`note`** | Optional non-normative vector-line string explaining what the vector tests for human readers. |

**Revisions and content hashes:** For a `@schema`, `@req`, `@atom`, or `@term`,
Sinter hashes the item's own text (excluding trailing `@example` blocks), status
tags, and edges. For a `@design` or `@spec`, Sinter hashes its own header and
introduction text (excluding child items and trailing `@example` blocks) plus
its edges (`@spec` also carries `items` edges to its child items; `@design`
does not). When you change an item's hashed content compared to the base
revision, you must change its revision label (for example, `=v1` to `=v2`), or
Sinter reports `needs-revision`. Changing a revision label marks every existing
pin to the old label as `suspect` so maintainers inspect citing items and
update their pins.

## Design header and brief line

Start a design file with its license header (when required by the host
repository), title, declaration tag, citations, and a one-sentence brief
attached directly to the header tag block:

```markdown
# <Title>
@design <slug>=<rev>
@cites {
    <cited-design>=<rev>,
    <external-standard>,
}
<One complete sentence stating the domain subject matter.>

<Concise non-normative orientation paragraphs.>
```

- Attach the one-sentence brief immediately after the last header tag line with
  no blank line so that Sinter and citation indexes read it as the design's
  opening description. Write a complete sentence with a subject about the
  domain (for example, `Services write each audit event as a single-line UTF-8
  JSON object with a UTC timestamp.`) rather than a subjectless fragment or
  prose about "this document". Keep the brief on a single unwrapped line
  (exempt from the 72–80 character wrap limit).
- Place a blank line between the brief line and the non-normative orientation
  paragraphs.
- `@cites` on the `@design` header lists the cited designs and external
  standards on which the design as a whole depends. Individual normative items
  still pin each specific item and standard that their own text uses.
- A blank line between a Markdown heading and its opening tag block is optional
  (both forms attach the tag block to that heading). Never place a blank line
  inside a tag block, because a blank line ends the Markdown paragraph and
  closes the tag block.
- A single braced `@cites { ... }` block and multiple single-target `@cites`
  lines are semantically equivalent; prefer one `@cites` block per item or
  header unless matching an untouched surrounding convention.

## Normative tag blocks

Every normative declaration carries an explicit revision label (such as `=v1`).
Keep `@term`, `@schema`, and `@atom` definitions in declarative present tense,
and reserve `must` and `may` for `@req` items.

| tag | purpose | naming convention |
|---|---|---|
| `@design <slug>=<rev>` | Declares the design document | lowercase hyphenated slug (`audit-log`, `webhooks`) |
| `@spec <name>=<rev>` | Declares a focused sub-specification | short hyphenated topic noun phrase (`retries`, `audit-record`) |
| `@schema <name>=<rev>` | Declares a concrete data shape | singular hyphenated noun phrase (`audit-envelope`) |
| `@schema <group>-vector=<rev>` | Declares a test-vector group shape | `<group>-vector`, where `<group>` equals the JSON `"group"` string (`retry-schedule-vector`) |
| `@req <name>=<rev>` | Declares one testable obligation (or optional permission) | imperative verb-object phrase (`schedule-retry`, `decode-audit-envelope`) |
| `@atom <name>=<rev>` | Declares an observable outcome, state, or finding class | singular hyphenated noun phrase (`delivery-state`, `expired-token-finding`) |
| `@term <name>=<rev>` | Declares a shared definition, grammar rule, or computed value | singular hyphenated noun phrase (`retry-policy`, `backoff-delay`) |

## `@example` blocks

Most items need no `@example` block. Add an `@example` block at the end of a
declared item (`@design`, `@spec`, `@schema`, `@req`, `@atom`, or `@term`) only
when a concrete case clarifies a genuine subtlety or non-obvious interaction.
Example text may start right after `@example ` on the same line, or on the next
line for multi-paragraph, tabular, or fenced-code examples:

```markdown
### Backoff delay

@term backoff-delay=v1
@cites #{retry-policy=v1}

The backoff delay after failed 1-based attempt `n` (shared by `schedule-retry`
and `estimate-retry-window`) is `min(base-delay * 2^(n - 1), max-delay)`.

@example Under `base-delay = 10s` and `max-delay = 60s`
([retry-policy](sinter:#retry-policy=v1)), after failed attempts 1, 2, 3, and
4, the next attempt waits 10s, 20s, 40s, and 60s.
```

- Place each `@example` block after the normative text of its parent declared
  item. For a `@spec` or `@design`, place `@example` blocks at the end of its
  introduction, before its first child item.
- An `@example` block runs from its `@example` line (outside fenced code blocks
  and block quotes) until the next `@example` line or the end of the parent
  item's section (for a `@spec` or `@design`, until the next `@example` line or
  its first child item). Every line after the first `@example` line belongs to
  an example block, never to the parent item's normative text.
- Sinter extracts and hashes each `@example` block as its own anonymous,
  uncitable `example` object with a 1-based index attached to its parent item.
  It does not enter the parent item's hashed lines, so editing an example never
  changes the parent item's hash or revision.
- Inline citations (`[label](sinter:...)`) inside an `@example` block attach as
  checked `cites` edges on the `example` object itself (never on the parent
  item), so Sinter reports `suspect`, `dangling`, or `retired` when a cited
  target changes and the example needs inspection. Add an inline citation
  inside an `@example` for any other item whose syntax or semantics the example
  relies on—even if the parent item already pins that target in `@cites`. Never
  add `@cites` on the parent item for something referenced only inside an
  `@example`.
- Sinter does not flag an `@example` when its own parent item changes, so
  re-read every `@example` on an item that you revise.

## Citations (`@cites`) and inline links

- **Same-design items:** omit the design slug in `@cites`
  (`@cites #{a=v1, b=v1}`) and in inline links (`[label](sinter:#a=v1)`).
- **Cited-design items:** include the design slug in `@cites`
  (`@cites other#{c=v2, d=v1}`) and in inline links
  (`[label](sinter:other#c=v2)`).
- **External standards:** write `<namespace>/<id>` (such as `rfc/8259`,
  `rfc/9110`, `commonmark/0.31.2`, `iso/8601`) in `@cites` and in inline links
  (`[RFC 8259](sinter:rfc/8259)`). External namespaces and their id patterns
  are declared in the project's Sinter configuration (`sinter.toml`). Always
  verify that every cited section number points to the right section of the
  standard.
- **Optional kind prefix:** any target may carry a kind word with `:` (such as
  `req:other#c=v2` in `@cites` or `[label](sinter:req:other#c=v2)`).
- **Mixed targets:** join mixed targets in one `@cites` tag per item:
  `@cites {rfc/8259, other#{c=v2}, #{a=v1}}`.
- **Wrapping long lists:** wrap citation lists longer than about 72 characters
  across lines with a trailing comma before `}`. A long scoped list
  (`other#{ ... }` or `#{ ... }`) may also wrap across lines inside its braces
  with a trailing comma:

```markdown
@cites {
    other#{
        first-item=v1, second-item=v1, third-item=v1,
    },
    #{local-item=v1},
}
```

- **Accuracy and acyclicity:** list an item or standard in `@cites` only when
  the tagged item's own normative text depends on that target. Remove unused
  pins, form no pin cycles, and never point at prose or section numbers.

## Test-vector files and vector-group schemas

Test vectors live in a sidecar JSON Lines file (`<slug>.test-vectors.jsonl` or
`<slug>.<spec>.test-vectors.jsonl`). Each line is a canonical JSON object with:

- `"form"`: pinned schema reference (`"#<group>-vector=<rev>"`)
- `"group"`: lowercase hyphenated group name matching the schema
- `"input"`: raw input payload
- `"result"` (optional): discrete result word when the group tests one
- `"values"` (optional): structured expected outputs (at least one of `result`
  or `values` appears on every line)
- `"needs"` (optional): sorted array of one or more lowercase hyphenated
  environment-precondition names
- `"note"` (optional): short human note on what the vector tests

**Structuring vector schemas inside a `@spec`:**

- When a `@spec` has multiple vector groups, place a short `### Test vectors`
  intro once, linking to the `.test-vectors.jsonl` file and stating any shared
  conventions (such as hex-encoded byte sequences or whether any group uses
  `needs`), followed by one `####` subsection per group `@schema` (without
  repeating the file link in each group).
- When a `@spec` has only one vector group, place the file link and the single
  group `@schema` directly under `### Test vectors` without an extra wrapper
  heading.
- Document each group's fields in one compact `field | type | meaning` table.
  Use dot and bracket path notation (such as `events[].id` or
  `input.policy.max-delay`) for nested objects. Omit `result` from the table
  when the group does not use `"result"`. When rejected vectors keep an empty
  `"values":{}` object instead of omitting `"values"`, mark the nested output
  field `(optional)` and note ``absent (`values` is `{}`)``.
- When including one or two sample JSONL lines at the end of a vector-group
  `@schema`, place them in a trailing `@example` block with a short lead line
  inline-citing the tested requirement (and any key definition) above the
  fenced JSON block, and copy each line verbatim from the `.test-vectors.jsonl`
  file (including `"note"`, if present). Placing sample lines in `@example`
  keeps edits to samples out of the `@schema` hash; when a copied vector
  changes, update the sample or delete it.

## Formatting and partial-rewrite conventions

- **Line wrapping:** Wrap prose paragraphs cleanly around 72 to 80 characters
  so that diffs and human edits stay readable. Markdown table rows, the
  single-line `@design` brief, long links, inline code that cannot break, and
  copied vector lines are exempt.
- **Tables:** Concise, parallel noun phrases in table cells are acceptable and
  often clearer than repeated full sentences.
- **Headings:** For a new full design, prefer unnumbered headings unless the
  host repository requires numbered sections (item tag names `#name` are the
  stable anchors, not section numbers).
- **Partial rewrites of existing designs:**
  - Match the operation verbs (such as `return` vs. `produce`) and result-word
    quoting of the surrounding sections and cited designs so the file stays
    consistent.
  - Preserve existing `#name` anchors that untouched sibling sections or citing
    designs cite. If you merge or retire an anchor (such as folding a redundant
    requirement into its pair), note every retired anchor explicitly for
    follow-up citation updates.
  - Keep the surrounding heading structure during a partial rewrite, do not
    copy repeated conformance boilerplate into new sections, and report
    boilerplate in untouched sections as a follow-up cleanup.
