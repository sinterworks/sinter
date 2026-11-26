<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Test evidence
@design evidence=v1
@cites {
    conformance=v1, text=v1, identifiers=v1, files=v1, data-forms=v1,
    ontology=v1, object-store=v1, findings=v1, packs=v1, documents=v1,
    w3c/rec-xml-20081126, rfc/5234, rfc/7405,
}
Conforming programs read test-runner report files for a tree, evaluate
test outcomes and outcome sources across imports, and return evidence
findings for `verifies` edges, ambiguous test results, and conformance
vector groups.

A test runner executes the tests of a repository and writes report files
that record test statuses. A caller supplies the report files from one
execution of test runners for a tree together as an import, with an
optional narrowing to resolve ambiguous test results. The imports
supplied for a tree form the evidence for that tree, and each import
counts independently.

A program reads each report file with either the test runner's
WebAssembly adapter or the default JUnit XML reader using a match table
and runner settings. That reading produces test results and result links
to test entries from the tree's code files. From those links, a program
derives each test's outcome and its outcome sources, and returns
findings when a tree's evidence shows failing tests, tests that did not
run, ambiguous test results, or unverified conformance vector groups.

## Definitions

### Report file

@term report-file=v1
@cites {
    packs#{test-runner=v1, valid-pack=v1},
    text#{byte-sequence=v1, text=v1},
}

A **report file** is a file that a `test-runner` writes about the tests
that it ran, such as a JUnit XML file. As an input, a report file holds
four parts:

- **report content:** a `byte-sequence` holding the bytes of the file;
- **report name:** a `text`, such as the path of the file as supplied by
  a caller;
- **pack:** a `valid-pack`; and
- **test runner:** a `test-runner` of the descriptor of that valid pack.

### Import

@term import=v1
@cites {
    conformance#input=v1,
    object-store#store-file=v1,
    ontology#{test=v1, test-evidence=v1, tree=v1},
    text#text=v1,
    #report-file=v1,
}

An **import** is an `input` representing one execution of test runners
(`test-evidence`): the runs of test runners whose report files are
supplied together in that import. That execution runs on the code of one
`tree`, the **tree of the import**, which holds no local file
(`store-file`). An import is **given for a tree** when, and only when,
the tree of the import is that tree without its local files.

An import holds four parts:

- **tree of the import:** that `tree` with no local file;
- **root:** a `text`, such as the absolute path of the root directory of
  the tree's files;
- **report files:** a sequence of one or more `report-file` values
  written by that execution (the same report content can appear more
  than once in the sequence, such as with two test runners), where the
  **number** of a report file is its 1-based position in that sequence
  (1 for the first, increasing by 1 for each following report file); and
- **narrowing:** a finite set of triples `(f, n, T)`, where `f` is the
  number of a report file of the import, `n` is a positive integer
  (`>= 1`), and `T` is a `test` of the tree of the import.

When no narrowing is supplied with the import, the narrowing is the
empty set. The narrowing consists solely of the triples supplied with
the import and is not derived from the report files or from the tree.

### Evidence for a tree

@term tree-evidence=v1
@cites {ontology#tree=v1, #import=v1}

The **evidence for a tree** is the multiset of all `import`s given for
that `tree`, counting each import once for each time it is given for
that tree (so the same import can appear more than once). A tree **has
evidence** when, and only when, the evidence for that tree holds at
least one import.

### Report path match

@term report-path-match=v1
@cites {
    files#path=v1,
    text#{character=v1, text=v1},
}

The **path parts** of a `text` are the sequence of texts produced by
these four steps in order:

1. Replace each `\` `character` in the text with `/`.
2. Split the resulting text at each `/` into a sequence of texts.
3. Remove every empty text and every text equal to `.`.
4. Remove every leading `..` (every text equal to `..` that has no text
   other than `..` before it).

A text **matches** a valid `files#path` when, and only when, both of
these conditions hold:

- The text has at least one path part.
- Between the sequence of the text's path parts and the sequence of the
  valid path's path segments (`files#path`), the shorter sequence equals
  the end of the longer sequence.

The **length of the match** is the number of texts in the shorter of
those two sequences.

## Report reading

@spec report-reading=v1

Report reading turns the report file of a test runner into test results
and result links to test entries. Each test runner of a language pack
has either a WebAssembly adapter or a match table, which the default
JUnit XML reader uses.

### Definitions

#### JUnit XML report

@term junit-report=v1
@cites {
    w3c/rec-xml-20081126,
    text#{byte-sequence=v1, text=v1},
    #report-file=v1,
}

A `byte-sequence` (such as the report content of a `report-file`) is a
**JUnit XML report** when, and only when, all four of these conditions
hold:

1. It is a well-formed XML document as XML 1.0 (Fifth Edition) defines
   one.
2. Its encoding is UTF-8 or UTF-16 as XML 1.0 (Fifth Edition) determines
   entity encodings, comparing any encoding declaration name without
   regard to ASCII letter case.
3. It contains no document type declaration.
4. Its root element has the name `testsuites` or the name `testsuite`.

These definitions apply to a JUnit XML report:

- The **name of an element** is the `text` written for that element in
  its start tag or empty-element tag. The **name of an attribute** is
  the `text` written for that attribute in its attribute specification.
- A **suite element** is an element named `testsuite` that is the root
  element, is a child of a root element named `testsuites`, or is a
  child of another suite element.
- A **case element** is an element named `testcase` whose parent is a
  suite element.
- The **outer suite elements** of an element are the suite elements of
  which that element is a descendant, ordered from outermost to
  innermost.
- An element **has an attribute** with a name when its start tag or
  empty-element tag holds an attribute specification with that name. The
  **value** of that attribute is its normalized value for an attribute
  of type CDATA under XML 1.0 (Fifth Edition).
- An element **has a child** with a name when at least one child element
  of that element has that name.

@example This [XML 1.0 (Fifth Edition)](sinter:w3c/rec-xml-20081126)
output from pytest is a JUnit XML report with one suite element and two
case elements:

```xml
<?xml version="1.0" encoding="utf-8"?>
<testsuites name="pytest tests">
  <testsuite name="pytest" tests="2" failures="1">
    <testcase classname="tests.test_math.TestAdd" name="test_one" time="0.001"/>
    <testcase classname="tests.test_math.TestAdd" name="test_two" time="0.002">
      <failure message="assert 3 == 4">...</failure>
    </testcase>
  </testsuite>
</testsuites>
```

#### Runner data

@schema runner-data=v1
@cites {
    data-forms#toml-value=v1,
    identifiers#valid-id-pattern=v1,
    ontology#parameter=v1,
    packs#{
        runner-setting=v1, runner-settings=v1, runner-setting-value=v1,
        test-runner=v1, valid-descriptor=v1,
    },
    text#text=v1,
}

This schema applies to a `test-runner` of a `valid-descriptor` that has
a match table, together with a valid binding of the `parameter`
`runner-settings` for that test runner. The sixteen keys of **runner
data**, their required `toml-value` kinds and constraints, and their
defaults are:

| key | value kind and constraints | default |
|---|---|---|
| `path` | TOML array of one or more TOML strings | none |
| `anchor` | TOML string `"whole"` or `"tail"` | `"whole"` |
| `prefix` | TOML string `"none"`, `"path"`, or `"directories"` | `"none"` |
| `prefix-separator` | TOML string | none |
| `suite-separator` | TOML string | none |
| `test-separator` | TOML string | none |
| `lead` | TOML array of TOML strings | `[]` |
| `suite-suffixes` | TOML array of TOML strings | `[]` |
| `name-suffixes` | TOML array of TOML strings | `[]` |
| `placeholders` | TOML array of TOML strings, each a `valid-id-pattern` | `[]` |
| `rewrite` | TOML array of TOML arrays, each holding exactly two TOML strings | `[]` |
| `file` | TOML array of TOML strings | `[]` |
| `line` | TOML string | none |
| `line-base` | TOML integer `0` or `1` | `1` |
| `not-run` | TOML array of TOML strings, each containing `=` | `[]` |
| `recognize` | TOML array of TOML strings, each containing no `@` or containing `=` after its first `@` | `[]` |

The runner data meets the schema `runner-data` (and is **valid**) when,
and only when, all five of these conditions hold:

1. No `text` is both a key of the test runner's match table and the name
   of a `runner-setting` of that test runner.
2. Every key of that match table and every name of a `runner-setting` of
   that test runner is one of the sixteen keys in the table.
3. For each `runner-setting` of that test runner, its
   `runner-setting-value` under the binding satisfies the value kind and
   constraints for the key equal to its name.
4. For each key of that match table, its paired `toml-value` satisfies
   the value kind and constraints for that key.
5. `path` is either a key of that match table or the name of a
   `runner-setting` of that test runner.

Otherwise, the runner data is invalid.

When the runner data is valid, the **value** of each key is determined
by the first matching rule:

1. When the test runner has a `runner-setting` whose name equals that
   key, the key's value is that runner setting's `runner-setting-value`
   under the binding.
2. When the test runner's match table holds that key, the key's value is
   the `toml-value` paired with that key in that match table.
3. When neither holds that key and the key has a default in the table,
   the key's value is that default.
4. Otherwise, that key has **no value**.

@example Valid runner data for a `vitest`
[test runner](sinter:packs#test-runner=v1) in a pack
[descriptor](sinter:packs#valid-descriptor=v1), placing `recognize` in
[runner settings](sinter:packs#runner-setting=v1) so a
[runner-settings](sinter:packs#runner-settings=v1) binding can override
it:

```toml
[runner.vitest.match]
path = ["name"]
suite-separator = " > "
test-separator = " > "
placeholders = ["%[sdifjoOc]", "[$][A-Za-z_][A-Za-z0-9_.]*"]
file = ["classname"]

[runner.vitest.settings]
recognize = ["testsuites@name=vitest tests"]
```

#### Case result

@term case-result=v1
@cites {
    rfc/5234,
    ontology#test-evidence=v1,
    text#{character=v1, production=v1, text=v1},
    #{junit-report=v1, report-path-match=v1, runner-data=v1},
}

For a `junit-report` and valid `runner-data`, the **test results**
(`test-evidence`) of the report are one test result for each case
element (`junit-report`), in document order, each carrying these fields:

- **name parts:** the sequence of `text` values yielded by the members
  of `path`, in array order. A member equal to `suites` yields, for each
  outer suite element of the case element in outermost-to-innermost
  order, the value of that outer suite element's `name` attribute. Any
  other member yields the value of the case element's attribute with
  that name. When `path` holds `suites` and an outer suite element lacks
  the attribute `name`, or when the case element lacks the attribute
  named by another member of `path`, the test result has **no name
  parts** (the empty sequence).
- **name:** the test result's name parts joined with one space (U+0020,
  `character`) between each adjacent pair, or the empty text when the
  test result has no name parts.
- **status:** determined by the first matching case:
  1. `"error"` when the case element has a child named `error`;
  2. `"fail"` when the case element has a child named `failure`;
  3. `"skip"` when the case element has a child named `skipped`, or when
     at least one member of `not-run` applies to the case element;
  4. `"pass"` otherwise.
  A member of `not-run` **applies** to a case element when the case
  element has an attribute whose name equals the text before the first
  `=` of that member and whose value equals the text after that first
  `=`.
- **file:** the first `text` yielded by a member of `file`, in array
  order, that has at least one path part (`report-path-match`), or **no
  file** when no member yields such a text:
  - A member starting with `suite:` followed by `a` yields the value of
    attribute `a` on the innermost outer suite element of the case
    element that has attribute `a`.
  - A member starting with `document:` followed by `a` yields the value
    of attribute `a` on the first suite element of the report in
    document order that has attribute `a`.
  - Any other member yields the value of the case element's attribute
    with that name.
  When the target XML element lacks that attribute, the member yields no
  text.
- **line:** when `line` has a value, the case element has an attribute
  with that name, and that attribute's value matches the `production`
  `line-text` writing non-negative base-10 integer `k`: let `b` be the
  value of `line-base`; when `k + 1 - b >= 1`, the line is `k + 1 - b`.
  In every other case, the test result has **no line**.
- **duration:** when the case element has an attribute named `time`
  whose value matches the `production` `duration-text` writing
  non-negative base-10 number `x` of seconds, the duration is the
  greatest integer not exceeding `1000 * x` (in whole milliseconds).
  Otherwise, the test result has **no duration**.

```abnf
line-text      = 1*DIGIT
duration-text  = 1*DIGIT [ "." 1*DIGIT ]
```

#### Name pattern

@term name-pattern=v1
@cites {
    data-forms#index=v1,
    files#path=v1,
    identifiers#{id-match=v1, id-pattern=v1},
    packs#{test-entry=v1, test-name=v1},
    text#{character=v1, slice=v1, text=v1},
    #{case-result=v1, runner-data=v1},
}

For a `test-entry` and valid `runner-data`, each **pattern** is a
sequence of **pattern parts**, where each pattern part is a sequence of
**pattern elements**. Each pattern element is a `character`, a
**placeholder**, or an **affix slot** for one of the keys `lead`,
`suite-suffixes`, or `name-suffixes`. A **part break** separates two
adjacent pattern parts.

These five steps produce the **patterns** of a `test-entry` under valid
`runner-data`:

1. **Rewrite:** For each text piece (`test-name`) of each name in the
   test entry's name path, apply each pair `[a, b]` of `rewrite` in
   array order whose first string `a` is non-empty. Scan the text from
   boundary `0`: repeatedly take the earliest `slice` equal to `a` whose
   start boundary is at or after the end boundary of the preceding
   matched slice (or `0` for the first), replace each matched slice with
   `b`, and pass the resulting text to the next pair.
2. **Placeholders:** Convert each rewritten text piece of length `n`
   into a sequence of pattern elements by scanning from boundary `0` to
   boundary `n`. At boundary `i < n`, consider every non-empty `slice`
   `(i, j)` (`i < j <= n`) whose text matches (`id-match`) at least one
   `id-pattern` member of `placeholders`. When at least one such slice
   exists, choose the longest such slice `(i, j)`, emit one placeholder
   pattern element, and continue at boundary `j`; otherwise, emit the
   `character` at 1-based character index `i + 1` as a character pattern
   element, and continue at boundary `i + 1`. Each placeholder piece
   (`test-name`) of the name path becomes one placeholder pattern
   element. The pattern elements of each name in the name path are the
   pattern elements of its pieces in order.
3. **Names:** Let `segments` be the path segments of the test entry's
   valid `files#path`, in order. The **prefix names** are:
   - when `prefix` is `"path"`: every path segment of `segments` except
     the last, in order, followed by the prefix of the last path segment
     before its last `.` when that last `.` lies at a 1-based character
     index greater than `1`, or the whole last path segment otherwise;
   - when `prefix` is `"directories"`: every path segment of `segments`
     except the last, in order; and
   - when `prefix` is `"none"`: the empty sequence.
   The pattern elements of each prefix name are its characters in order.
   The **suite names** are all names of the test entry's name path
   except its last name, in order, and the **own name** is its last
   name.
4. **Join:** Let `m` be the number of prefix names. Produce one pattern
   for `k = 1` when `anchor` is `"whole"`, and one pattern for each
   integer `k` from `1` to `m + 1` when `anchor` is `"tail"`. For a
   given `k`, the pattern's names are prefix names `k` through `m` (none
   when `k = m + 1`), followed by the suite names, followed by the own
   name. Before each name after the first stands a separator:
   - `prefix-separator` when the preceding name is a prefix name and
     this name is a prefix name or a suite name;
   - `suite-separator` when both the preceding name and this name are
     suite names; and
   - `test-separator` when this name is the own name.
   A separator key with no value produces a part break; any other
   separator produces the characters of its string as pattern elements
   in order.
5. **Sequence:** Form the sequence consisting of an affix slot for
   `lead`, followed for each of the pattern's names in order by its
   preceding separator (if any), the pattern elements of that name, and
   an affix slot for `suite-suffixes` after a suite name or an affix
   slot for `name-suffixes` after the own name. Splitting this sequence
   at its part breaks produces the pattern's **pattern parts** in order
   (a sequence with `p` part breaks yields `p + 1` pattern parts, each
   possibly empty).

An **affix pattern** is a `text`. A `text` is an **instance** of an
affix pattern when that text equals the result of replacing each `*` in
the affix pattern with some `text` (including the empty text).

The name parts of a `case-result` **match** a pattern when, and only
when, both of these conditions hold:

1. The number of name parts equals the number of pattern parts in the
   pattern.
2. There exists a choice of a `text` for every pattern element of every
   pattern part—each `character` pattern element taking its own
   character, each placeholder taking any `text` (including the empty
   text), and each affix slot taking either the empty text or an
   instance of a member of that slot's key (`lead`, `suite-suffixes`, or
   `name-suffixes`)—such that for every 1-based `index`, concatenating
   the chosen texts in pattern part `index` equals the name part at that
   same `index`.

@example With `vitest` [runner data](sinter:#runner-data=v1)
(`path = ["name"]`, `suite-separator = " > "`, `test-separator = " > "`,
`file = ["classname"]`, and `placeholders` holding `"%[sdifjoOc]"`),
consider a [test entry](sinter:packs#test-entry=v1) for
`it.each(...)("each %i + %i = %i", ...)` inside `describe("outer", ...)`
in `src/math.test.ts` (whose [name path](sinter:packs#test-name=v1) is
`outer` then `each %i + %i = %i`) and this case element:

```xml
<testcase classname="src/math.test.ts" name="outer &gt; each 1 + 2 = 3" time="0.001"/>
```

Each `%i` matches `"%[sdifjoOc]"` under
[id-match](sinter:identifiers#id-match=v1) and becomes a placeholder,
producing one pattern part (`outer > each <placeholder> + <placeholder>
= <placeholder>`), where `lead`, `suite-suffixes`, and `name-suffixes`
are empty so every affix slot takes only the empty text. That pattern
matches the [case-result](sinter:#case-result=v1)'s single name part
`outer > each 1 + 2 = 3`.

#### Default recognition

@atom default-recognition=v1
@cites {
    ontology#parameter=v1,
    packs#{runner-settings=v1, test-runner=v1, valid-descriptor=v1},
    text#{byte-sequence=v1, character=v1, text=v1},
    #{junit-report=v1, runner-data=v1},
}

This atom applies to a report content (`byte-sequence`), a `test-runner`
of a `valid-descriptor` that has a match table, and a valid binding of
the `parameter` `runner-settings` for that test runner, where the runner
data meets `runner-data`.

The **default recognition** result is one of two values:

- `"recognized"` when the report content is a `junit-report` and either
  `recognize` is the empty array or at least one member of `recognize`
  applies to the root element of that JUnit XML report;
- `"not recognized"` otherwise.

A member of `recognize` **applies** to the root element under these
rules:

- When the member contains no `@` `character`, it applies when the root
  element's name equals that member.
- When the member contains `@`, it applies when the root element's name
  equals the `text` before the first `@` and the root element has an
  attribute whose name equals the `text` between that first `@` and the
  first `=` after it, with value equal to the `text` after that `=`.

#### Default reader result

@term default-reader-result=v1
@cites {
    files#path=v1,
    ontology#{parameter=v1, test-evidence=v1},
    packs#{
        runner-settings=v1, test-entry=v1, test-runner=v1,
        valid-descriptor=v1,
    },
    text#byte-sequence=v1,
    #{
        case-result=v1, junit-report=v1, name-pattern=v1,
        report-path-match=v1, runner-data=v1,
    },
}

This term applies to a report content (`byte-sequence`), a finite set of
`test-entry` values with distinct test entry ids, a `test-runner` of a
`valid-descriptor` that has a match table, and a valid binding of the
`parameter` `runner-settings` for that test runner, where the runner
data meets `runner-data`.

When the report content is not a `junit-report`, the **default reading**
has **reading result** `"unreadable"` and produces no test results and
no result links.

When the report content is a `junit-report`, the **default reading** has
**reading result** `"bound"` and produces:

- the **test results** (`test-evidence`) of the report (`case-result`),
  in document order; and
- the **result links** of the default reading, each pairing one of those
  test results with one of the input `test-entry` values.

A test result with no name parts has no result link. For a test result
with name parts, its result links are determined in two steps:

1. **Path filtering:** Start with all input `test-entry` values as
   candidates. When the test result has a file, keep only the candidates
   whose valid `files#path` that file matches (`report-path-match`). If
   at least one of those kept candidates has a match length equal to the
   number of path parts of that file, keep only the candidates with that
   match length.
2. **Pattern matching:** Produce one result link from the test result to
   each remaining candidate that has at least one pattern
   (`name-pattern`) matched by the test result's name parts.

@example Suppose a [case-result](sinter:#case-result=v1) has file
`pkg/tests/test_utils.py` (three path parts under
[report-path-match](sinter:#report-path-match=v1)) and name `test_load`,
while the input [test entries](sinter:packs#test-entry=v1) are
`test_save` in `pkg/tests/test_utils.py` (match length 3) and
`test_load` in `tests/test_utils.py` (match length 2). Path filtering
keeps only `pkg/tests/test_utils.py` before
[name-pattern](sinter:#name-pattern=v1) matching runs, so the test
result produces no result link.

#### Report test entry

@term report-test-entry=v1
@cites {
    data-forms#index=v1,
    documents#{
        file-readers=v1, file-test=v1, read-file=v1, unreadable-file=v1,
    },
    files#path=v1,
    ontology#{parameter=v1, tree=v1},
    packs#{
        file-parse=v1, parse-tree-order=v1, test-entry=v1, test-node=v1,
        test-runner=v1, valid-descriptor=v1, valid-pack=v1,
    },
    text#{decimal-numeral=v1, text=v1},
    #{import=v1, report-file=v1},
}

Under a valid binding of the `parameter` `file-readers`, for a
`report-file` of an `import`, consider every readable
(`unreadable-file`) code file (`read-file`) of the `tree` of that import
whose `valid-pack` has a `valid-descriptor` holding a `test-runner` with
the same name as the report file's test runner.

For each such code file at valid `files#path` `p`, take the `test-node`
values produced by the `file-parse` of that code file's text with its
pack (the test nodes defining the `file-test`s of that file), ordered in
`parse-tree-order`. The **report test entries** (the test entries of the
reading of that report file) are, for each such code file and each such
`test-node` at 1-based `index` `n` in that order, the `test-entry` of
that `test-node` (carrying `line`, `end-line`, kind, name path, and test
labels as `test-entry` defines) whose test entry id is the `text` formed
by `p`, then `#`, then the `decimal-numeral` of `n`.

#### Report read result

@atom report-read-result=v1
@cites {
    documents#file-readers=v1,
    ontology#{parameter=v1, test-evidence=v1},
    packs#{
        adapter-call=v1, adapter-request=v1, call-result=v1,
        runner-settings=v1, test-entry=v1, test-runner=v1,
        valid-pack=v1,
    },
    #{
        default-reader-result=v1, import=v1, report-file=v1,
        report-test-entry=v1, runner-data=v1,
    },
}

This atom applies under valid bindings of the `parameter`s
`file-readers` and `runner-settings` for the `test-runner` of a
`report-file` of an `import`, when either that test runner has an
adapter hash or its runner data meets `runner-data`. A `report-file`
**has a report read result** when this atom applies to it.

The **reading of a report file** has one of two **reading results**,
`"bound"` or `"unreadable"`:

- **Adapter test runner** (the test runner has an adapter hash):
  The reading makes a `bind` `adapter-call` with:
  - the content of `adapters/<r>.wasm` of the report file's `valid-pack`
    (where `<r>` is the test runner's name) as the adapter;
  - the bind `adapter-request` for that test runner, that valid binding
    of `runner-settings`, the report name of the report file, the root
    of the import, and the `report-test-entry` set of that reading as
    the request;
  - the report content of the report file as the report content; and
  - the set of test entry ids of those `report-test-entry` values as the
    call's test entry ids.

  When the `call-result` of that `adapter-call` is `"bound"`, the
  reading result is `"bound"`, its **test results** (`test-evidence`)
  are the test results of that call in order, and its **result links**
  are, for each binding object of that call, the pair of that binding
  object's test result and the `report-test-entry` whose test entry id
  equals that binding object's `test` string. When the `call-result` is
  `"failed"` (including when the request or the report content has
  `4,294,967,296` (`2^32`) bytes or more), the reading result is
  `"unreadable"`, with no test results and no result links.
- **Match-table test runner** (the test runner has a match table):
  The reading is the default reading (`default-reader-result`) for the
  report content of the report file, the `report-test-entry` set of that
  reading, that test runner, and that valid binding of
  `runner-settings`. Its reading result is the reading result of that
  default reading (`"bound"` or `"unreadable"`). When the reading result
  is `"bound"`, its **test results** and **result links** are those of
  that default reading; when `"unreadable"`, it produces no test results
  and no result links.

A **result link** of a reading of a report file is any pair of a test
result and a `test-entry` produced by that reading when its reading
result is `"bound"`.

### Recognizing JUnit reports

@req recognize-junit-reports=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    ontology#parameter=v1,
    packs#{runner-settings=v1, test-runner=v1, valid-descriptor=v1},
    text#byte-sequence=v1,
    #{default-recognition=v1, runner-data=v1},
}

When a conforming program recognizes a report content (`byte-sequence`)
for a `test-runner` of a `valid-descriptor` that has a match table under
a valid binding of the `parameter` `runner-settings` for that test
runner:

- When the runner data meets `runner-data`, the program must return the
  `default-recognition` result (`"recognized"` or `"not recognized"`).
- When the runner data does not meet `runner-data`, the program must
  return neither `"recognized"` nor `"not recognized"`
  (`reject-invalid-inputs`).

### Reading report files

@req read-report-file=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    documents#file-readers=v1,
    ontology#{parameter=v1, test-evidence=v1},
    packs#{
        adapter-call=v1, adapter-request=v1, runner-settings=v1,
        test-entry=v1, test-runner=v1, valid-descriptor=v1,
    },
    text#byte-sequence=v1,
    #{
        default-reader-result=v1, import=v1, report-file=v1,
        report-read-result=v1, report-test-entry=v1, runner-data=v1,
    },
}

When a conforming program reads a `report-file` of an `import` under
valid bindings of the `parameter`s `file-readers` and `runner-settings`
for the report file's `test-runner`:

- When that test runner has a match table and its runner data does not
  meet `runner-data`, the program must return no reading result, no test
  results, and no result links (`reject-invalid-inputs`).
- When that test runner has an adapter hash and the program makes the
  `bind` `adapter-call` for that reading of the report file, the program
  must make that call with the exact bind `adapter-request` defined by
  `report-read-result`, with the `report-test-entry` set of that reading
  and no other test entry, with the set of their test entry ids as the
  call's test entry ids, and with the report file's report content.
- When returning the reading result of that reading of the report file,
  the program must return the `report-read-result` reading result
  (`"bound"` or `"unreadable"`).
- When that reading result is `"bound"` and the program returns the test
  results (`test-evidence`) of that reading, the program must return
  each test result of that `report-read-result` once, in order, with its
  name, its status, and its file, line, and duration when present.
- When that reading result is `"bound"` and the program returns the
  result links of that reading, the program must return each result link
  of that `report-read-result` once.
- When that reading result is `"unreadable"`, the program must return no
  test results and no result links for that reading.

When a conforming program performs a default reading of a report content
(`byte-sequence`) against a finite set of `test-entry` values with
distinct test entry ids for a `test-runner` of a `valid-descriptor` that
has a match table under a valid binding of `runner-settings` for that
test runner:

- When the runner data does not meet `runner-data`, the program must
  return no reading result, no test results, and no result links
  (`reject-invalid-inputs`).
- When the runner data meets `runner-data`, the program must return the
  `default-reader-result` reading result (`"bound"` or `"unreadable"`).
  When that reading result is `"bound"`, the program must return each
  test result of that default reading once, in order (with its name, its
  status, and its file, line, and duration when present), and each
  result link of that default reading once. When that reading result is
  `"unreadable"`, the program must return no test results and no result
  links.

### Reading only report content

@req read-only-report-content=v1
@cites {
    w3c/rec-xml-20081126,
    conformance#{conforming-program=v1, safety-obligation=v1},
    text#byte-sequence=v1,
    #{default-reader-result=v1, default-recognition=v1},
}

In any `default-recognition` or default reading
(`default-reader-result`) of a report content (`byte-sequence`), a
conforming program must read the XML document solely from the bytes of
that report content and must never read any external file or network
resource named by that report content.

### Ending report readings

@req end-report-readings=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    #{
        default-reader-result=v1, default-recognition=v1,
        report-read-result=v1,
    },
}

A conforming program must end every `default-recognition`, every default
reading (`default-reader-result`), and every reading of a report file
(`report-read-result`) that it starts.

### Test vectors

Test vectors for `report-reading` live in
[evidence.test-vectors.jsonl](evidence.test-vectors.jsonl) as a
test-vector set under
[test-vectors](sinter:data-forms#test-vectors=v1). Neither group uses
`needs`.

#### Recognition vectors

@schema recognition-vector=v1
@cites {
    data-forms#{
        group-schema=v1, hex-text=v1, json-value=v1, toml-value=v1,
        vector-line=v1, vector-meaning=v1,
    },
    ontology#parameter=v1,
    packs#{
        runner-setting=v1, runner-settings=v1, runner-setting-value=v1,
        test-runner=v1,
    },
    text#{byte-sequence=v1, utf-8-text=v1, valid-utf-8=v1},
    #{
        default-recognition=v1, recognize-junit-reports=v1,
        runner-data=v1,
    },
}

`recognition-vector` is a `group-schema` for group `recognitions` and
tests `recognize-junit-reports`. Each line is a `vector-line` whose
meaning follows `vector-meaning`. In each vector, `input.settings`
represents a valid binding of the `parameter` `runner-settings` (each
`runner-setting` has the type of its value in `input.settings`), and
each `toml-value` in `input.match` and `input.settings` appears as a
`json-value` of the same kind (string, boolean, integer, array, or
object for a table).

| field | type | meaning |
|---|---|---|
| `input.match` | object | match table (`toml-value` table) of the `test-runner` |
| `input.settings` | object | map from each `runner-setting` name of the test runner to its `runner-setting-value` (`toml-value`) under the binding |
| `input.report` | string or `{"bytes": string}` | report content (`byte-sequence`): its `utf-8-text` when `valid-utf-8`, or `{"bytes": <hex-text>}` otherwise |
| `result` | string (optional) | `"recognized"` or `"not recognized"` (`default-recognition`) when the runner data meets `runner-data`; absent when the runner data is invalid |
| `values` | object | always `{}`; when `result` is present, represents no additional output; when `result` is absent, represents reporting that the runner data is invalid and where, while returning neither `"recognized"` nor `"not recognized"` |

@example Sample lines testing
[recognize-junit-reports](sinter:#recognize-junit-reports=v1) with
[default-recognition](sinter:#default-recognition=v1) and
[runner-data](sinter:#runner-data=v1) on a recognized report and on
invalid runner data ([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#recognition-vector=v1","group":"recognitions","input":{"match":{"path":["name"]},"report":"<testsuites name=\"vitest tests\"><testsuite name=\"a\"/></testsuites>","settings":{"recognize":["testsuites@name=vitest tests"]}},"note":"the attribute name of the root element has the value that the member gives","result":"recognized","values":{}}
{"form":"#recognition-vector=v1","group":"recognitions","input":{"match":{"path":[]},"report":"<testsuite/>","settings":{}},"note":"path is the empty array","values":{}}
```

#### Reading vectors

@schema reading-vector=v1
@cites {
    data-forms#{
        group-schema=v1, hex-text=v1, index=v1, json-value=v1,
        toml-value=v1, vector-line=v1, vector-meaning=v1,
    },
    files#path=v1,
    ontology#{parameter=v1, test-evidence=v1},
    packs#{
        runner-setting=v1, runner-settings=v1, runner-setting-value=v1,
        test-entry=v1, test-name=v1, test-runner=v1,
    },
    text#{
        byte-sequence=v1, code-point-order=v1, text=v1, utf-8-text=v1,
        valid-utf-8=v1,
    },
    #{
        case-result=v1, default-reader-result=v1, read-report-file=v1,
        runner-data=v1,
    },
}

`reading-vector` is a `group-schema` for group `readings` and tests
`read-report-file` for a default reading with a match-table
`test-runner`. Each line is a `vector-line` whose meaning follows
`vector-meaning`. In each vector, `input.settings` represents a valid
binding of the `parameter` `runner-settings` (each `runner-setting` has
the type of its value in `input.settings`), each `toml-value` in
`input.match` and `input.settings` appears as a `json-value` of the same
kind (string, boolean, integer, array, or object for a table), and each
`test-entry` in `input.tests` has empty test labels.

| field | type | meaning |
|---|---|---|
| `input.match` | object | match table (`toml-value` table) of the `test-runner` |
| `input.settings` | object | map from each `runner-setting` name of the test runner to its `runner-setting-value` (`toml-value`) under the binding |
| `input.report` | string or `{"bytes": string}` | report content (`byte-sequence`): its `utf-8-text` when `valid-utf-8`, or `{"bytes": <hex-text>}` otherwise |
| `input.tests[]` | array of objects | `test-entry` values, sorted in `code-point-order` of `id`, each with empty test labels |
| `input.tests[].id` | string | test entry id (`text`) |
| `input.tests[].path` | string | valid `files#path` of the test entry |
| `input.tests[].line` | integer | `line` of the test entry |
| `input.tests[].end-line` | integer | `end-line` of the test entry |
| `input.tests[].suite` | boolean | `true` for test suite; `false` for test case |
| `input.tests[].names` | array of arrays | name path (`test-name`): one array per name in order, holding `{"text": string}` for each text piece and `{"placeholder": string}` for each placeholder |
| `result` | string (optional) | reading result (`"bound"` or `"unreadable"`, `default-reader-result`) when the runner data meets `runner-data`; absent (`values` is `{}`, representing reporting that the runner data is invalid and where, and returning no reading result, no test results, and no result links) when the runner data is invalid |
| `values.results[]` | array of objects (optional) | ordered test results (`case-result`, `test-evidence`) when `result` is `"bound"`; absent (`values` is `{}`) when `result` is `"unreadable"` or absent |
| `values.results[].name` | string | `name` of the test result |
| `values.results[].status` | string | `status` of the test result (`"pass"`, `"fail"`, `"error"`, or `"skip"`) |
| `values.results[].file` | string (optional) | `file` of the test result, present only when the test result has a file |
| `values.results[].line` | integer (optional) | `line` of the test result, present only when the test result has a line |
| `values.results[].ms` | integer (optional) | `duration` of the test result in whole milliseconds, present only when the test result has a duration |
| `values.links[]` | array of `[integer, string]` pairs (optional) | result links `[n, id]` pairing the test result at 1-based `index` `n` in `values.results` with the `test-entry` whose test entry id is `id`, sorted by `n` ascending then `code-point-order` of `id`, when `result` is `"bound"`; absent (`values` is `{}`) when `result` is `"unreadable"` or absent |

@example Sample lines testing
[read-report-file](sinter:#read-report-file=v1) with
[default-reader-result](sinter:#default-reader-result=v1),
[case-result](sinter:#case-result=v1), and
[runner-data](sinter:#runner-data=v1) on a bound report and on an
unreadable report ([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#reading-vector=v1","group":"readings","input":{"match":{"file":["classname"],"path":["name"],"placeholders":["%[sdifjoOc]","[$][A-Za-z_][A-Za-z0-9_.]*"],"suite-separator":" > ","test-separator":" > "},"report":"<testsuites name=\"vitest tests\"><testsuite name=\"src/math.test.ts\"><testcase classname=\"src/math.test.ts\" name=\"outer &gt; each 1 + 2 = 3\" time=\"0.001\"/></testsuite></testsuites>","settings":{"recognize":["testsuites@name=vitest tests"]},"tests":[{"end-line":9,"id":"src/math.test.ts#1","line":1,"names":[[{"text":"outer"}]],"path":"src/math.test.ts","suite":true},{"end-line":4,"id":"src/math.test.ts#2","line":2,"names":[[{"text":"outer"}],[{"text":"each %i + %i = %i"}]],"path":"src/math.test.ts","suite":false}]},"note":"each %i becomes a placeholder, and the file matches the path","result":"bound","values":{"links":[[1,"src/math.test.ts#2"]],"results":[{"file":"src/math.test.ts","ms":1,"name":"outer > each 1 + 2 = 3","status":"pass"}]}}
{"form":"#reading-vector=v1","group":"readings","input":{"match":{"path":["name"]},"report":"<testsuite><testcase name=\"a\"></testsuite>","settings":{},"tests":[]},"note":"not well-formed","result":"unreadable","values":{}}
```

## Test outcomes and sources

@spec outcomes=v1

Outcome evaluation links test results from readings of report files to
tests in a tree, filters those links with any caller-supplied narrowing,
and derives whether each test passed, failed, or did not run in each
import and across the tree's evidence.

### Definitions

#### Enclosed tests

@term enclosed-test=v1
@cites {
    documents#file-test=v1,
    ontology#{test=v1, tree=v1},
    packs#{enclosed-node=v1, node-slice=v1, test-node=v1},
}

In a `tree`, a `test` `T` **encloses** a `test` `U` (and `U` is an
**enclosed test** of `T`) when, and only when, `U` lies in the file of
`T` (`file-test`) and the `test-node` of `T`, whose `node-slice` is the
code of `T`, is one of the test suites that enclose (`test-node`) the
`test-node` of `U`. A `test` `U` of the tree is a part of a `test` `T`
of the tree, as `ontology#test` defines enclosing tests, when, and only
when, `T` encloses `U`.

#### Linked tests

@term linked-test=v1
@cites {
    documents#{file-readers=v1, file-test=v1},
    files#path=v1,
    ontology#{test=v1, test-evidence=v1, tree=v1},
    packs#{test-entry=v1, test-name=v1, test-node=v1},
    #{
        enclosed-test=v1, import=v1, report-file=v1,
        report-path-match=v1, report-read-result=v1,
    },
}

Under a valid binding of `file-readers`, for an `import` in which each
`report-file` has a report read result (`report-read-result`), the
**test results of the import** are the test results of those readings of
report files whose reading result is `"bound"`. The test results of an
import are the test results (`test-evidence`) of the execution of test
runners that the import represents. The **number** of a test result is 1
more than the number of test results before it in the reading of its
report file.

A test result of an import is **linked** to a `test` `T` of the `tree`
of the import when, and only when, all three of these conditions hold:

- the reading of the test result's report file has a result link pairing
  that test result with a `test-entry` whose `path` equals the valid
  `path` of the file of `T` (`file-test`), whose name path is equal
  (`test-name`) to the name of `T`, and whose kind equals the kind of
  the `test-node` of `T`;
- the test result has no file, or has a file that matches
  (`report-path-match`) the valid `path` of the file of `T`; and
- when the `test-node` of `T` is a test suite, `T` encloses
  (`enclosed-test`) at least one test.

#### Import narrowings

@term import-narrowing=v1
@cites {
    documents#file-test=v1,
    ontology#{test=v1, test-evidence=v1, tree=v1},
    packs#{test-name=v1, test-node=v1},
    #{import=v1, linked-test=v1},
}

For an `import` whose test results are defined (`linked-test`), a triple
`(f, n, T)` of the import's narrowing **stands for** the pair `(r, T)`
when the import has a test result `r` whose report file has number `f`
and whose number in the reading of its report file is `n`.

Two tests of a `tree` are **alike** when they lie in the same file
(`file-test`), have equal names (`test-name`), and have `test-node`s of
the same kind (both test cases or both test suites).

The narrowing of an `import` is **valid** when, and only when, all three
of these conditions hold:

- every triple of the narrowing stands for a pair of a test result of
  the import and a test;
- for every such pair `(r, T)`, `r` is linked (`linked-test`) to `T`;
  and
- for every test result `r` that appears in at least one such pair, `r`
  is linked to at least one test that is not alike to any test paired
  with `r` by a triple of the narrowing.

Otherwise, the narrowing is **invalid**.

#### Named tests and ambiguous results

@term named-test=v1
@cites {
    ontology#{test=v1, test-evidence=v1, tree=v1},
    #{
        import=v1, import-narrowing=v1, linked-test=v1, report-file=v1,
        report-read-result=v1, tree-evidence=v1,
    },
}

For an `import` whose narrowing is valid (`import-narrowing`) and in
which each `report-file` has a report read result
(`report-read-result`), a test result `r` of that import **names** a
`test` `T` of the `tree` of that import (as `test-evidence` uses
"names") when, and only when, both of these conditions hold:

- `r` is linked (`linked-test`) to `T`; and
- the narrowing of the import has no triple that stands for
  (`import-narrowing`) the pair of `r` and a test alike to `T`.

A test result names no other test.

In an `import` whose narrowing is valid and in which each `report-file`
has a report read result, a `test` `T` of the `tree` **has an ambiguous
result** when some test result of that import names `T` and also names a
test of the tree that is not alike (`import-narrowing`) to `T`.

In the `tree-evidence` for a `tree`, a `test` `T` of the tree **has an
ambiguous result** when `T` has an ambiguous result in at least one
`import` of that evidence.

#### Import outcomes

@atom import-outcome=v1
@refines ontology#promise=v1
@cites {
    ontology#{test=v1, test-evidence=v1, tree=v1},
    packs#{call-result=v1, test-node=v1},
    #{
        enclosed-test=v1, import=v1, import-narrowing=v1,
        linked-test=v1, named-test=v1, report-file=v1,
        report-read-result=v1,
    },
}

For a test result (`test-evidence`, `call-result`):

- status `pass` **states that the tests it names passed**;
- status `fail` or `error` **states that the tests it names failed**;
  and
- status `skip` states neither.

By the **suite rule** (the rule that `ontology#promise` leaves to a
design for a test that encloses other tests), the test evidence of the
execution represented by an `import` shows that a `test` `T` enclosing
one or more tests (`enclosed-test`) passed when, and only when, all
three of these conditions hold:

- `T` encloses at least one test whose `test-node` is a test case;
- every test `U` that `T` encloses and whose `test-node` is a test case
  has a test result of the import that names (`named-test`) `U` and
  states that `U` passed; and
- no test result of the import names `T`, or any test that `T` encloses,
  and states that its named tests failed.

For an `import` whose narrowing is valid (`import-narrowing`) and in
which each `report-file` has a report read result
(`report-read-result`), the **outcome in that import** of a `test` `T`
of the `tree` of that import is one of three values:

- `"passed"`: when `T` encloses no test, the test evidence of the import
  shows that `T` passed under `ontology#promise`; when `T` encloses one
  or more tests, the suite rule holds for `T`.
- `"failed"`: otherwise, when at least one test result of the import
  names `T`, or a test that `T` encloses, and states that its named
  tests failed.
- `"not run"`: otherwise.

When the narrowing of an import is invalid or any `report-file` of the
import lacks a report read result, a test has no outcome in that import.

@example Suppose `describe("limits")`
[encloses](sinter:#enclosed-test=v1) `it("small")` and `it("large")`. In
an [import](sinter:#import=v1), `limits` has outcome `"passed"` when
`small` and `large` each have a test result that
[names](sinter:#named-test=v1) that test case with status `pass`, and no
test result naming `limits`, `small`, or `large` has status `fail` or
`error`. `limits` has outcome `"not run"` when no test result names
`large` with status `pass` and no test result naming any of the three
has status `fail` or `error`. `limits` has outcome `"failed"` when any
test result naming `limits`, `small`, or `large` has status `fail` or
`error`. A [test suite](sinter:packs#test-node=v1) that encloses no test
case—such as a `describe` block enclosing only an empty `describe`
block—never has outcome `"passed"`.

#### Tree outcomes

@atom tree-outcome=v1
@cites {
    ontology#{test=v1, tree=v1},
    #{import=v1, import-outcome=v1, tree-evidence=v1},
}

The **outcome in the evidence for a tree** of a `test` of a `tree` is
one of three values:

- `"passed"` when the test has `import-outcome` `"passed"` in at least
  one `import` of the `tree-evidence`;
- `"failed"` when the test does not have `import-outcome` `"passed"` in
  any `import` of the `tree-evidence`, has an `import-outcome` in every
  `import` of the `tree-evidence`, and has `import-outcome` `"failed"`
  in at least one `import` of the `tree-evidence`; and
- `"not run"` when the test has `import-outcome` `"not run"` in every
  `import` of the `tree-evidence` (including when the `tree-evidence`
  contains zero imports).

Otherwise—when the test has `import-outcome` `"passed"` in no import and
lacks an `import-outcome` in at least one import—the test has no outcome
in the `tree-evidence`.

#### Outcome sources

@term outcome-source=v1
@cites {
    data-forms#hash=v1,
    ontology#{test=v1, test-evidence=v1, tree=v1},
    #{
        enclosed-test=v1, import=v1, import-narrowing=v1,
        import-outcome=v1, linked-test=v1, named-test=v1,
        report-file=v1, report-read-result=v1, tree-evidence=v1,
        tree-outcome=v1,
    },
}

When a `test` `T` of a `tree` has a `tree-outcome` in the
`tree-evidence` for that tree, the **sources of that outcome** are one
source for each occurrence of an `import` in the `tree-evidence` in
which `T` has an `import-outcome`. Each source contains these four
parts:

- for each `report-file` of the import, in import order, the `hash` of
  its report content and the reading result (`"bound"` or
  `"unreadable"`) of its `report-read-result`;
- the `import-outcome` of `T` in that import;
- each triple of the import's narrowing that stands for
  (`import-narrowing`) the pair of a test result and a test that is `T`,
  a test that `T` encloses (`enclosed-test`), or a test alike
  (`import-narrowing`) to `T` or to a test that `T` encloses; and
- the contributing test results (`test-evidence`) of the import, ordered
  by increasing report-file number (`import`) and then by increasing
  test-result number (`linked-test`):
  - when `T`'s `import-outcome` is `"passed"`, each test result of the
    import that names (`named-test`) `T`, or a test that `T` encloses,
    and states that its named tests passed;
  - when `T`'s `import-outcome` is `"failed"`, each test result of the
    import that names `T`, or a test that `T` encloses, and states that
    its named tests failed; and
  - when `T`'s `import-outcome` is `"not run"`, each test result of the
    import that names `T`, or a test that `T` encloses, and has status
    `skip`.

Each contributing test result carries the number of its report file, the
`hash` of that report file's report content, and the number, name, and
status of the test result.

### Isolating tree evidence

@req isolate-tree-evidence=v1
@cites {
    conformance#conforming-program=v1,
    ontology#tree=v1,
    #{import=v1, tree-evidence=v1},
}

A conforming program must count an `import` in the `tree-evidence` for a
`tree` only when that import is given for that tree.

### Returning test outcomes and sources

@req give-test-outcomes=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    documents#file-readers=v1,
    ontology#{test=v1, tree=v1},
    #{
        import=v1, import-narrowing=v1, import-outcome=v1,
        named-test=v1, outcome-source=v1, report-file=v1,
        report-read-result=v1, tree-evidence=v1, tree-outcome=v1,
    },
}

Under a valid binding of `file-readers`:

- When returning the outcome of a `test` `T` of a `tree` in an `import`
  of that tree, a conforming program must return `T`'s `import-outcome`
  (`"passed"`, `"failed"`, or `"not run"`), and no other outcome, when
  `T` has an `import-outcome` in that import. When that import's
  narrowing is invalid (`import-narrowing`) or any `report-file` of that
  import lacks a report read result (`report-read-result`), the program
  must return no outcome for `T` in that import.
- When returning the outcome of a `test` `T` of a `tree` in the
  `tree-evidence` for that tree, a conforming program must return `T`'s
  `tree-outcome` (`"passed"`, `"failed"`, or `"not run"`), and no other
  outcome, together with each `outcome-source` of that outcome once and
  no other source, and whether `T` has an ambiguous result
  (`named-test`) in the `tree-evidence`, when `T` has a `tree-outcome`.
  When `T` has no `tree-outcome`, the program must return no tree
  outcome, no source, and no ambiguous-result status.

Invalid bindings and invalid narrowings follow `reject-invalid-inputs`.

### Returning promise sources

@req give-promise-sources=v1
@cites {
    conformance#conforming-program=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, tree-edge=v1,
        vector-files=v1,
    },
    identifiers#external-namespaces=v1,
    object-store#tree-object-store=v1,
    ontology#{
        edge-source=v1, promise=v1, test=v1, tree=v1, verifies-edge=v1,
    },
    #{outcome-source=v1, tree-evidence=v1, tree-outcome=v1},
}

Under valid bindings of `file-readers`, `vector-files`, and
`external-namespaces`, a valid `tree-object-store`, and a valid
`kept-object-set`, when returning whether a `verifies` `promise` is kept
in a `tree` that has evidence (`tree-evidence`):

- For each `test` of the tree that is the `edge-source` of a promised
  `tree-edge` (`promise`, `verifies-edge`) for that promise and has a
  `tree-outcome` in the `tree-evidence`, a conforming program must
  return once for that test its `tree-outcome` (`"passed"`, `"failed"`,
  or `"not run"`) and each `outcome-source` of that outcome once.
- The program must return no outcome and no source with that promise
  result for any test that lacks a `tree-outcome` or is not the
  `edge-source` of such a promised edge.

### Keeping no import after a read error

@req write-no-import-after-read-error=v1
@cites {
    conformance#{conforming-program=v1, input=v1, safety-obligation=v1},
    files#{directory=v1, directory-tree=v1},
    ontology#tree=v1,
    #import=v1,
}

In a run in which content of a file or a `directory` is a part that an
`input` lacks because a conforming program could not read that content,
the program must keep no `import` of that run for a later run, neither
in the `directory` `.sinter/local/` of the `directory-tree` of any
working `tree` nor anywhere else.

### Test vectors

Test vectors for `outcomes` live in
[evidence.test-vectors.jsonl](evidence.test-vectors.jsonl) as a
test-vector set under
[test-vectors](sinter:data-forms#test-vectors=v1). Group `outcomes` uses
no `needs`.

#### Outcome vectors

@schema outcome-vector=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    data-forms#{
        group-schema=v1, hash=v1, json-value=v1, vector-line=v1,
        vector-meaning=v1,
    },
    documents#file-readers=v1,
    files#path=v1,
    ontology#{test=v1, test-evidence=v1, tree=v1},
    packs#{
        runner-settings=v1, test-entry=v1, test-name=v1, test-node=v1,
    },
    #{
        enclosed-test=v1, give-test-outcomes=v1, import=v1,
        import-narrowing=v1, import-outcome=v1, linked-test=v1,
        named-test=v1, outcome-source=v1, report-file=v1,
        report-read-result=v1, tree-evidence=v1, tree-outcome=v1,
    },
}

`outcome-vector` is a `group-schema` for group `outcomes` and tests
`give-test-outcomes` (with invalid narrowings governed by
`reject-invalid-inputs`). Each line is a `vector-line` whose meaning
follows `vector-meaning`. Each vector stands for a `tree` that has no
test outside `input.tests` that a test result names. The vector assumes
valid bindings of `file-readers` and `runner-settings` (with valid
runner data for every match-table runner) producing the
`report-read-result` values in `input.imports`. JSON values follow
`json-value`.

| field | type | meaning |
|---|---|---|
| `input.tests[]` | array of objects | tests (`ontology#test`) of the tree |
| `input.tests[].path` | string | valid `files#path` of the test's file |
| `input.tests[].name` | array of strings | `test-name` of the test, one string per own name in order (each a single text piece) |
| `input.tests[].suite` | boolean | `true` for a test suite `test-node`, `false` for a test case |
| `input.tests[].suites` | array of integers | 0-based indices in `input.tests` of the tests that enclose (`enclosed-test`) this test |
| `input.imports[]` | array of objects | imports (`import`) of the `tree-evidence` |
| `input.imports[].files[]` | array of objects | report files (`report-file`) of the import in order (1-based report-file numbers follow array position) |
| `input.imports[].files[].hash` | string | `data-forms#hash` of the report content |
| `input.imports[].files[].reading` | string | reading result (`"bound"` or `"unreadable"`, `report-read-result`) |
| `input.imports[].files[].results[]` | array of objects (optional) | test results (`test-evidence`, `linked-test`) in order when `reading` is `"bound"` (1-based test-result numbers follow array position); absent when `"unreadable"` |
| `input.imports[].files[].results[].name` | string | name of the test result |
| `input.imports[].files[].results[].status` | string | `"pass"`, `"fail"`, `"error"`, or `"skip"` |
| `input.imports[].files[].results[].file` | string (optional) | file of the test result, present only when the test result has a file |
| `input.imports[].files[].results[].links` | array of integers | 0-based index in `input.tests` of one test whose path, name, and kind equal those of the `test-entry` of the result link, one index for each result link |
| `input.imports[].narrowing` | array of 3-integer arrays (optional) | `[report-number, result-number, test-index]` triples (`import-narrowing`), with 1-based `report-number` and `result-number` and 0-based `test-index` in `input.tests`; absent when empty |
| `input.test` | integer | 0-based index in `input.tests` of the target test |
| `result` | string (optional) | `"passed"`, `"failed"`, or `"not run"` (`tree-outcome`) of `input.tests[input.test]` when it has a `tree-outcome`; absent when it has no `tree-outcome` |
| `values.ambiguous` | boolean (optional) | `true` when `input.tests[input.test]` has an ambiguous result in the `tree-evidence` (`named-test`), `false` otherwise; absent (`values` is `{}`) when `result` is absent |
| `values.sources[]` | array of objects (optional) | `outcome-source` records for `input.tests[input.test]`, in `input.imports` order in the vector file (order among sources is not part of the obligation); absent (`values` is `{}`) when `result` is absent |
| `values.sources[].files[]` | array of objects | `{"hash": string, "reading": "bound" \| "unreadable"}` for each `report-file` of the import, in import order |
| `values.sources[].narrowing` | array of 3-integer arrays | triples of the source in input form, sorted by `report-number`, `result-number`, `test-index` in the vector file (order among triples is not part of the obligation) |
| `values.sources[].outcome` | string | `"passed"`, `"failed"`, or `"not run"` (`import-outcome` in that import) |
| `values.sources[].results[]` | array of objects | contributing test results in report-number then result-number order, each with `report-number` (1-based integer), `report` (`data-forms#hash`), `n` (1-based test-result number), `name` (string), and `status` (`"pass"`, `"fail"`, `"error"`, or `"skip"`) |

When an import has an invalid narrowing (`import-narrowing`), a
conforming program reports that narrowing and where
(`reject-invalid-inputs`), and that import contributes no outcome, no
source, and no ambiguous result.

@example Sample lines testing
[give-test-outcomes](sinter:#give-test-outcomes=v1) for a test with no
imports ([tree-outcome](sinter:#tree-outcome=v1)) and for an invalid
[import-narrowing](sinter:#import-narrowing=v1) governed by
[reject-invalid-inputs](sinter:conformance#reject-invalid-inputs=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#outcome-vector=v1","group":"outcomes","input":{"imports":[],"test":0,"tests":[{"name":["t"],"path":"t.ts","suite":false,"suites":[]}]},"note":"no import: no source","result":"not run","values":{"ambiguous":false,"sources":[]}}
{"form":"#outcome-vector=v1","group":"outcomes","input":{"imports":[{"files":[{"hash":"0000000000000000000000000000000000000000000000000000000000000001","reading":"bound","results":[{"links":[0],"name":"a","status":"fail"}]}],"narrowing":[[1,1,0]]}],"test":0,"tests":[{"name":["a"],"path":"t.ts","suite":false,"suites":[]}]},"note":"a narrowing with one triple that removes the only linked test is not valid","values":{}}
```

## Evidence findings

@spec findings=v1

When a tree has evidence, the evidence findings report `verifies` edges
whose tests did not pass, ambiguous test results, and groups of
conformance vectors that no passing test verifies.

### Definitions

#### Never-ran findings

@atom never-ran-finding=v1
@cites {
    identifiers#citation-entry=v1,
    ontology#{
        edge=v1, edge-source=v1, verifies-edge=v1, declared-item=v1,
        test=v1, tree=v1, conformance-vector-group=v1, vector-set=v1,
    },
    documents#{
        tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, slice-location=v1, tree-finding=v1,
    },
    #{tree-evidence=v1, tree-outcome=v1},
}

A `tree` that has evidence (`tree-evidence`) has one `tree-finding` of
the class `never-ran` for each `tree-edge` of the kind `verifies`
(`verifies-edge`, `edge`) that meets both of these conditions:

- its source (`edge-source`) is a `test` of the tree with `tree-outcome`
  `"not run"` in the `tree-evidence` for the tree; and
- its cited item is a `declared-item` of the kind requirement or schema,
  a `conformance-vector-group`, or a `vector-set`.

A tree that has no evidence has no `tree-finding` of the class
`never-ran`. The subject of the finding is the `position-subject` of the
`origin-position` of the `citation-entry` of the edge. Its location is
the `slice-location`, in the file of the edge (`tree-edge`), of the
slice in the file's text (`origin`) of the slice of that
`citation-entry`.

#### Failed findings

@atom failed-finding=v1
@cites {
    identifiers#citation-entry=v1,
    ontology#{
        edge=v1, edge-source=v1, verifies-edge=v1, declared-item=v1,
        test=v1, tree=v1, conformance-vector-group=v1, vector-set=v1,
    },
    documents#{
        tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, slice-location=v1, tree-finding=v1,
    },
    #{tree-evidence=v1, tree-outcome=v1},
}

A `tree` that has evidence (`tree-evidence`) has one `tree-finding` of
the class `failed` for each `tree-edge` of the kind `verifies`
(`verifies-edge`, `edge`) that meets both of these conditions:

- its source (`edge-source`) is a `test` of the tree with `tree-outcome`
  `"failed"` in the `tree-evidence` for the tree; and
- its cited item is a `declared-item` of the kind requirement or schema,
  a `conformance-vector-group`, or a `vector-set`.

A tree that has no evidence has no `tree-finding` of the class `failed`.
The subject of the finding is the `position-subject` of the
`origin-position` of the `citation-entry` of the edge. Its location is
the `slice-location`, in the file of the edge (`tree-edge`), of the
slice in the file's text (`origin`) of the slice of that
`citation-entry`.

#### Ambiguous-result findings

@atom ambiguous-result-finding=v1
@cites {
    packs#{test-node=v1, node-slice=v1},
    documents#{
        file-test=v1, position-subject=v1, slice-location=v1,
        tree-finding=v1,
    },
    ontology#{test=v1, tree=v1},
    text#{position=v1, slice=v1},
    #{tree-evidence=v1, import=v1, named-test=v1},
}

A `tree` that has evidence (`tree-evidence`) has one `tree-finding` of
the class `ambiguous-result` for each `test` `T` of the tree that has an
ambiguous result (`named-test`) in at least one `import` of that
evidence. A tree that has no evidence has no `tree-finding` of the class
`ambiguous-result`.

The subject of the finding is the `position-subject` of the `position`
of the start boundary of the code `slice` of `T` (the `node-slice` of
the `test-node` of `T`, `file-test`) in the file of `T`. Its location is
the `slice-location` of that `slice` in the file of `T`.

#### Unverified-vector findings

@atom unverified-vector-finding=v1
@cites {
    ontology#{
        conformance-vector=v1, conformance-vector-group=v1,
        vector-set=v1, declared-item=v1, item-name=v1, tree=v1,
        test=v1, edge=v1, verifies-edge=v1, edge-source=v1,
    },
    documents#{
        tree-edge=v1, vector-file=v1, vector-files=v1, tree-finding=v1,
    },
    findings#location=v1,
    files#path=v1,
    #{tree-evidence=v1, tree-outcome=v1},
}

When a `tree` `T` has evidence (`tree-evidence`), `T` has, for a set `S`
of `declared-item`s of `T`, one `tree-finding` of the class
`unverified-vector` for each `conformance-vector-group` of the
`vector-set` that a `declared-item` in `S` has in `T` (`vector-file`,
`vector-files`) when all three of these conditions hold:

- the group has at least one `conformance-vector` that states a vector;
- no `test` of `T` with `tree-outcome` `"passed"` in the `tree-evidence`
  for `T` is the source (`edge-source`) of a `tree-edge` of the kind
  `verifies` (`verifies-edge`, `edge`) whose cited item is that group or
  that `vector-set`; and
- every `test` of `T` that is the source (`edge-source`) of a
  `tree-edge` of the kind `verifies` whose cited item is that group or
  that `vector-set` has a `tree-outcome` in the `tree-evidence` for `T`.

A `tree` that has no evidence has no `tree-finding` of the class
`unverified-vector` for any set of its declared items. The subject of
the finding is the `item-name` of the `declared-item` of that
`vector-set`, then `[`, then the name of that
`conformance-vector-group`, then `]`. Its `location` is the valid `path`
of the `vector-file` of that `declared-item` alone, with no span.

### Returning evidence findings

@req give-evidence-findings=v1
@cites {
    conformance#{
        conforming-program=v1, input=v1, reject-invalid-inputs=v1,
    },
    identifiers#external-namespaces=v1,
    documents#{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        tree-finding=v1,
    },
    object-store#tree-object-store=v1,
    ontology#{declared-item=v1, finding-class=v1, tree=v1},
    #{
        tree-evidence=v1, never-ran-finding=v1, failed-finding=v1,
        ambiguous-result-finding=v1, unverified-vector-finding=v1,
    },
}

Given a `tree`, its `tree-evidence`, and a valid binding of
`file-readers`:

- When a conforming program returns the findings of the tree of the
  `finding-class` `ambiguous-result`, the program must return each
  `tree-finding` of that class that the tree has
  (`ambiguous-result-finding`) once, and no other finding of that class.
- When bindings of `vector-files` and `external-namespaces`, the
  `tree-object-store` of the tree, and `kept-object-set` are also valid,
  and a conforming program returns the findings of the tree of one of
  the classes `never-ran`, `failed`, or `unverified-vector`, the program
  must return each `tree-finding` of that class that the tree has
  (`never-ran-finding`, `failed-finding`, `unverified-vector-finding`)
  once, and no other finding of that class. For `unverified-vector`, the
  program must take a set `S` of `declared-item`s of that tree as an
  `input`, and the findings are those that the tree has for `S`.

When `file-readers` is invalid, the program must return no finding of
any of these four classes (`reject-invalid-inputs`). When any of
`vector-files`, `external-namespaces`, `tree-object-store`, or
`kept-object-set` is invalid, the program must return no finding of the
classes `never-ran`, `failed`, or `unverified-vector`
(`reject-invalid-inputs`).

### Test vectors

Test vectors for `findings` live in
[evidence.test-vectors.jsonl](evidence.test-vectors.jsonl) as a
test-vector set under
[test-vectors](sinter:data-forms#test-vectors=v1). Group `findings` uses
no `needs`.

#### Finding vectors

@schema finding-vector=v1
@cites {
    conformance#conforming-program=v1,
    text#code-point-order=v1,
    data-forms#{
        json-value=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    identifiers#{external-namespaces=v1, citation-entry=v1},
    documents#{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        tree-edge=v1, origin-position=v1, position-subject=v1,
    },
    object-store#tree-object-store=v1,
    findings#finding-subject=v1,
    ontology#{
        tree=v1, test=v1, edge=v1, verifies-edge=v1, edge-source=v1,
        declared-item=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1, item-name=v1,
        finding-class=v1,
    },
    packs#{runner-settings=v1, test-runner=v1},
    #{
        tree-evidence=v1, tree-outcome=v1, never-ran-finding=v1,
        failed-finding=v1, unverified-vector-finding=v1,
        give-evidence-findings=v1,
    },
}

`finding-vector` is a `group-schema` for group `findings` and tests
`give-evidence-findings` for the finding classes `never-ran`, `failed`,
and `unverified-vector`. Each line is a `vector-line` whose meaning
follows `vector-meaning` and omits `result`.

Each vector stands for a `tree` and input set `S` of `declared-item`s of
that tree under valid bindings of `file-readers`, `vector-files`,
`external-namespaces`, and `runner-settings` (for each `test-runner`), a
valid `tree-object-store`, and a valid `kept-object-set`. The tree has
no other `verifies` edge (`verifies-edge`) and no other `vector-set`,
and the `tree-outcome` of each `test` (when it has one) is given as an
input. Each `json-value` object in `input` and `values` holds only the
members listed in this table.

| field | type | meaning |
|---|---|---|
| `input.evidence` | boolean | `true` when the `tree` has evidence (`tree-evidence`); `false` when it has no evidence |
| `input.tests[]` | array of objects | `test`s of the tree, indexed from `0` |
| `input.tests[].outcome` | string (optional) | `tree-outcome` of that test (`"passed"`, `"failed"`, or `"not run"`); absent (`{}`) when that test has no outcome |
| `input.edges[]` | array of objects | `tree-edge`s of the kind `verifies` (`edge`) of the tree |
| `input.edges[].source` | integer (`>= 0`) | 0-based index in `input.tests` of the `test` that is the `edge-source` of that edge |
| `input.edges[].subject` | string | `position-subject` of the `origin-position` of the `citation-entry` of that edge |
| `input.edges[].cited.kind` | string | cited item kind: `"requirement"` or `"schema"` (`declared-item`), `"group"` (`conformance-vector-group`), `"set"` (`vector-set`), `"other"` (another kind), or `"none"` (no cited item) |
| `input.edges[].cited.set` | string (optional) | `item-name` of the item of the `vector-set`; present when, and only when, `cited.kind` is `"group"` or `"set"` |
| `input.edges[].cited.group` | string (optional) | name of the `conformance-vector-group`; present when, and only when, `cited.kind` is `"group"` |
| `input.sets[]` | array of objects | `vector-set`s of the tree |
| `input.sets[].name` | string | `item-name` of the `declared-item` of that `vector-set` |
| `input.sets[].in-force` | boolean | `true` when that `declared-item` is in the input set `S`; `false` otherwise |
| `input.sets[].vectors[]` | array of objects | `conformance-vector`s of that `vector-set` |
| `input.sets[].vectors[].group` | string | name of the `conformance-vector-group` of that `conformance-vector` |
| `input.sets[].vectors[].states-vector` | boolean | `true` when that `conformance-vector` states a vector; `false` when it states no vector |
| `values.findings[]` | array of 2-string arrays | `[class, subject]` (`finding-class` slug and `finding-subject`) for every `never-ran-finding` and `failed-finding` of the tree and every `unverified-vector-finding` of the tree for `S`, sorted in `code-point-order` of `class`, then `subject` |

For each of the three classes (`never-ran`, `failed`, and
`unverified-vector` taking the input set `S`), a conforming program
returning findings of that class for the tree returns one finding of
that class with the subject of each matching entry in `values.findings`,
and no other finding of that class.

@example Sample lines testing
[give-evidence-findings](sinter:#give-evidence-findings=v1) for a tree
that has no [evidence](sinter:#tree-evidence=v1) and for a tree with
both a [failed-finding](sinter:#failed-finding=v1) and an
[unverified-vector-finding](sinter:#unverified-vector-finding=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#finding-vector=v1","group":"findings","input":{"edges":[{"cited":{"kind":"requirement"},"source":0,"subject":"t.py@L3C3"}],"evidence":false,"sets":[{"in-force":true,"name":"billing","vectors":[{"group":"g","states-vector":true}]}],"tests":[{"outcome":"not run"}]},"note":"a tree with no evidence has no finding of these classes","values":{"findings":[]}}
{"form":"#finding-vector=v1","group":"findings","input":{"edges":[{"cited":{"kind":"set","set":"data-forms#toml"},"source":0,"subject":"t.py@L1C3"},{"cited":{"group":"keys","kind":"group","set":"data-forms#toml"},"source":1,"subject":"t.py@L5C3"}],"evidence":true,"sets":[{"in-force":true,"name":"data-forms#toml","vectors":[{"group":"offsets","states-vector":true},{"group":"offsets","states-vector":true},{"group":"keys","states-vector":true},{"group":"keys","states-vector":false}]}],"tests":[{"outcome":"failed"},{"outcome":"passed"}]},"note":"a test that cites the set failed, so it verifies nothing; a passing test that cites the group keys verifies it","values":{"findings":[["failed","t.py@L1C3"],["unverified-vector","data-forms#toml[offsets]"]]}}
```
