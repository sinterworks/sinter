<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Test evidence
@design evidence=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites packs=v1
@cites findings=v1
@cites documents=v1
@cites w3c/rec-xml-20081126
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies report files and imports, the evidence for a tree, JUnit XML reports and the default reader of JUnit XML with the data of a runner, the readings of report files and their test entries, the tests that a test result names and narrowings, the outcomes of tests in an import and in the evidence for a tree with the suite rule, the sources of outcomes, the verified conformance vectors, the finding classes `never-ran`, `failed`, `ambiguous-result`, and `unverified-vector`, and requirements for conforming programs that read report files and give outcomes, sources, and these findings.

A test runner, such as pytest or vitest, runs the tests of a repository
and writes report files: files that say which tests ran, and whether
each passed, failed, or was skipped. A person or continuous integration
gives a conforming program the report files of one execution of test
runners together, for one tree: that is an import. The imports that are
given for a tree are the evidence for that tree, and each of them counts
alone.

A program reads each report file of an import with the test runner of
the report file. A test runner of a language pack has an adapter of its
own, or a match table. The report files of a test runner with a match
table are read by the default reader, which reads JUnit XML. A reading
gives test results, and result links that join a test result to test
entries, each of which stands for a test of the tree. From the test
results that name a test, the program gives the outcome of the test:
passed, failed, or not run. With each outcome, it gives its sources, so
that a person can see where the outcome came from. Some conditions of the evidence for a tree are
findings, such as a `verifies` edge whose test did not run.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405. In a production, `*` and `1*` repeat
an element zero or more times and one or more times, and `[ ]` makes an
element optional. `DIGIT` is an ASCII digit, a core rule of RFC 5234.

From Text and notation, the design takes texts, characters, spaces,
places, runs, line feeds, positions, and spans; whole
numbers and decimal numerals; bytes and byte sequences; the notation of
productions; and conforming programs, inputs, and results. From
Identifiers, it takes citation entries, id patterns, the fit of a text
to an id pattern, and the bindings of `external-namespaces` with the
results that a conforming program of Identifiers gives for them. From Files and paths, it takes
valid paths and their file names. From Data forms, it takes hashes; TOML
values; and vector lines. From the Ontology, it takes trees, tests, test
results and test evidence, edges with their sources and cited items, the
edges of the kind `verifies`, the names of items, conformance vectors,
groups of conformance vectors, vector sets, promises, and finding
classes. From Language packs, it takes valid packs and valid
descriptors, test runners with their adapter hashes, match tables, and
runner settings; the bindings of `runner-settings`; the readings of
texts, test nodes, the runs of nodes, enclosed nodes, the order of the
parse tree, and
the names of test nodes; test entries, the requests of the function
bind, calls, valid adapters, instances of adapters, and the results of
calls with their test results and binding objects. From Findings, it
takes spots. From Documents, it takes the bindings of `file-readers`,
read files and code files, files that cannot be read, the tests of a
read file, vector files, the edges of a tree, origins and origin
positions, position subjects, the spots of runs, and tree findings.

From XML 1.0 (Fifth Edition), the W3C Recommendation of 26 November
2008, the design takes well-formed XML documents, their encodings,
document type declarations, encoding declarations, elements with their names, content, parents,
children, and descendants, root elements, start tags, empty-element
tags, attribute specifications, and the normalized values of attributes
of the type CDATA. From RFC 8259, it takes JSON texts: each line of the
file of the conformance vectors of the design is a JSON text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [test runner](sinter:packs#test-runner=v1) | a program that runs tests, gives a test result for each test that it runs, and writes report files, such as vitest; in a descriptor of a language pack, a test runner has an adapter hash or a match table |
| [report file](sinter:#report-file=v1) | a file that a test runner writes about the tests that it ran; as an input, its report content, which is its bytes, its report name, its pack, and its test runner |
| [import](sinter:#import=v1) | an input that stands for one execution of test runners: the tree for which it is given, a root, one or more report files, and a narrowing |
| execution of test runners | the runs of test runners whose report files are given together in one import, such as one job of continuous integration, or three jobs that each run a third of the tests |
| [evidence for a tree](sinter:#tree-evidence=v1) | the imports that are given for that tree, one for each time that an import is given for it; a tree has evidence when it has at least one |
| [JUnit XML report](sinter:#junit-report=v1) | a report content that is a well-formed XML document in UTF-8 or UTF-16, with no document type declaration, whose root element is `testsuites` or `testsuite` |
| [suite element](sinter:#junit-report=v1), [case element](sinter:#junit-report=v1) | in a JUnit XML report, a `testsuite` element that is the root, a child of the root `testsuites`, or a child of a suite element; a `testcase` element whose parent is a suite element |
| [data of a runner](sinter:#runner-data=v1) | the values of a closed set of keys for a test runner with a match table, from its runner settings, from its match table, or from defaults; it can be valid or not |
| default reader | the reader of JUnit XML reports that a conforming program uses for the report files of a test runner with a match table: what it gives is the default recognition and the default reading |
| [test results of a JUnit XML report](sinter:#case-result=v1) | one test result for each case element, with its parts, its name, its status, and, when the case element gives them, its file, its line, and its duration |
| [part of a test result](sinter:#case-result=v1) | a text that the default reader reads for a test result by a member of `path`, such as the value of the attribute `name` of its case element |
| [path parts](sinter:#report-path-match=v1), [match a valid path](sinter:#report-path-match=v1) | the texts between the `/` and `\` of a text, without empty texts, without `.`, and without `..` at the start; a text matches a valid path when it has path parts, and the shorter of its path parts and the file names of the valid path is equal to the end of the longer; the length of the match is the number of the shorter |
| [patterns of a test entry](sinter:#name-pattern=v1) | for a test case, sequences of parts that the default reader compares with the parts of test results: the names of a prefix, the names of its name path, separators, placeholders, and affix slots |
| [match a pattern](sinter:#pattern-match=v1) | the parts of a test result match a pattern when they are as many as its parts, and texts for its placeholders, and for its affix slots texts that are the empty text or instances of affix patterns, make each part of the pattern equal to the part of the test result |
| [default recognition](sinter:#default-recognition=v1) | "recognised", "not recognised", or "failed": whether the default reader takes a report content as a report file of a test runner |
| [default reading](sinter:#default-reader-result=v1) | "bound", with test results and result links, or "unreadable": what the default reader gives for a report content and test entries |
| [result link](sinter:#reading-of-a-report-file=v1) | a pair of a test result and a test entry, which a reading gives: by the reader, the test result is about the test of that test entry |
| [test entries of a reading](sinter:#reading-entry=v1) | one test entry for each test node of the code files of the tree that can be read and whose pack is the pack of the report file, with the test entry id that the term gives |
| [reading of a report file](sinter:#reading-of-a-report-file=v1) | "bound" with test results and result links, "unreadable", or "stopped": the call of bind of the adapter of its test runner, or the default reading |
| [test results of an import](sinter:#linked-test=v1), [linked](sinter:#linked-test=v1) | the test results of the readings of its report files with the result "bound"; a test result is linked to a test of the tree when a result link joins it to a test entry with the path and the name of the test, and it has no file or a file that matches that path |
| [narrowing](sinter:#import=v1), [valid narrowing](sinter:#narrowing-of-an-import=v1) | a set of triples of the number of a report file of the import, the number of a test result, and a test, each of which can stand for a pair of a test result and a test; it is valid when each triple stands for a pair, and the test result of each pair is linked to the test of the pair, and to a test alike to no test with which a triple pairs it; two tests are alike when they have one file and equal names, and a test is alike to itself |
| [names](sinter:#named-test=v1) | a test result names a test when it is linked to it, and the narrowing, when it is valid, has no triple for the pair of the test result and a test alike to that test |
| [says passed, says failed](sinter:#status-meaning=v1) | a test result with the status `pass` says that the tests that it names passed; one with `fail` or `error` says that they failed; one with `skip` says neither |
| [hold](sinter:#held-test=v1) | in a tree, a test T holds a test U of its file when the test node of T is a test suite that encloses the test node of U |
| [suite rule](sinter:#suite-rule=v1) | the rule by which test evidence shows that a test that holds other tests passed: each test that it holds and that holds no test has a test result that names it and says passed, and no test result that names it or a test that it holds says failed |
| [outcome in an import](sinter:#import-outcome=v1) | "passed", "failed", or "not run": what the test results of one import say of a test |
| [outcome in the evidence for a tree](sinter:#tree-outcome=v1) | "passed" when the outcome in one or more imports of the evidence is "passed"; otherwise "failed" when it is "failed" in one or more; otherwise "not run" |
| [sources of an outcome](sinter:#outcome-source=v1) | for each import of the evidence, for each of its report files the hash of its report content and the result of its reading, the outcome in that import, and the test results that made it, each with the number and the hash of the report content of its report file, its number, its name, and its status |
| [verified](sinter:#verified-vector=v1) | a conformance vector is verified when it says a vector and a test with a `verifies` edge to the vector, to its group, or to its vector set has the outcome "passed" in the evidence for the tree |
| [`never-ran`](sinter:#never-ran-finding=v1), [`failed`](sinter:#failed-finding=v1) | the finding classes of a `verifies` edge to a requirement, a conformance vector, a group, or a vector set, whose source is a test with the outcome "not run", or "failed", in the evidence for the tree |
| [`ambiguous-result`](sinter:#ambiguous-result-finding=v1) | the finding class of a test that a test result names, when the test result also names a test that is not alike to it |
| [`unverified-vector`](sinter:#unverified-vector-finding=v1) | the finding class of a conformance vector that says a vector and that is not verified |

## 2. Report files, readings, and outcomes

### 2.1 Report files and imports

A report file, such as `out/junit.xml`, is a file that a test runner
writes about the tests that it ran. As an input of a conforming program,
a report file has four things (term `report-file`): its report content,
its report name, its pack, and its test runner. How a program comes to the test
runner of a report file, such as by a call of the function recognise of
each adapter, or by an option that a person gives, is its own choice.

An import (term `import`) has the report files that one execution of
test runners wrote, given together. It is given for one tree: the tree
of a commit, such as in continuous integration, or the tree of a working
tree. It also has a root, which the request of a call of bind gives an
adapter, and a narrowing (section 2.7). For example, three machines of
continuous integration each run one third of the tests of a commit, and
a person gives the three report files to the program in one import. The
import is then one execution of test runners. When the person gives
each report file in an import of its own, the program has three
imports, and each is one execution. When one vitest run covers the
tests of two packs, the import has its report content twice, once with
the test runner of each pack.

The evidence for a tree (term `tree-evidence`) is the imports that are
given for that tree. A program can keep imports between its
executions, in a form of its own; the requirement
`take-evidence-for-own-tree` limits where it counts them. When a person
edits a comment after an import, the tree changes, and the import is not
in the evidence for the new tree.

A report file or a tree that changes while a program reads it is a
matter of the quality of the implementation.

### 2.2 JUnit XML reports

No authoritative specification of JUnit XML exists: test runners write
it in several forms. The default reader relies only on the facts that
the term `junit-report` states. This is a report content that pytest
writes for two tests, one of which fails, and it is a JUnit XML report:

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

A report content with a document type declaration is not a JUnit XML
report. The requirement `read-only-report-content` keeps the default
reader from files and networks that a report content names.

### 2.3 The data of a runner

A test runner of a language pack that has no adapter of its own has a
match table in the descriptor of its pack. The default reader reads the
report files of such a test runner with the data of the runner (term
`runner-data`). The term gives the keys of the data, the value of each
key, and when the data is valid. A pack can make a key a runner setting,
such as `recognise`, so that a binding of `runner-settings` in a project
can change it. For example, this is the data of vitest in a TypeScript
pack:

```toml
[runner.vitest.match]
path = ["name"]
suite-separator = " > "
test-separator = " > "
placeholders = ["%[sdifjoOc]", "[$][A-Za-z_][A-Za-z0-9_.]*"]
file = ["classname"]

[runner.vitest.settings]
recognise = ["testsuites@name=vitest tests"]
```

### 2.4 The test results of a JUnit XML report

The default reader gives one test result for each case element, in the
order of the document (term `case-result`). The term gives the status of
a test result from the children and the attributes of its case element.
For example, a case element that has both a `failure` child and a
`skipped` child has the status `fail`, a case element with a `skipped`
child and no `error` or `failure` child has the status `skip` whatever
the data of the runner is, and pytest writes a test that is
expected to fail, and fails, as `<skipped type="pytest.xfail">`, which
has the status `skip`.

The parts of a test result are the texts that the default reader reads
for it by the members of `path`. With
`path = ["classname", "name"]`, the second case element of the report
of section 2.2 has the two parts `tests.test_math.TestAdd` and
`test_two`, and its name is `tests.test_math.TestAdd test_two`. A test
result with no parts, such as for a case element that lacks an
attribute that `path` names, is linked to no test.

The term also gives the file, the line, and the duration of a test
result, when the case element gives them. For example, `time="0.0019"`
gives a duration of 1 millisecond, and a value such as `1,203.5` or
`4e-7` gives no duration.

### 2.5 The result links of the default reader

The default reader gives result links of each test result to test
entries of the kind test case (term `default-reader-result`). A test
result with a file gets result links only to test entries whose path the
file matches (term `report-path-match`). For example, the files
`src/math.test.ts`, `./src/math.test.ts`, `math.test.ts`, and
`/home/ci/work/src/math.test.ts` all match the valid path
`src/math.test.ts`, and `test/math.test.ts` does not. When the file
`pkg/tests/test_utils.py` matches both `pkg/tests/test_utils.py` and
`tests/test_utils.py`, only the longer match counts.

When the test result also has a line that is in the lines of one or
more of these test entries, the line decides, for each valid path
alone. So when pytest writes `file="tests/test_api.py"` and `line="11"`,
and the files `packages/a/tests/test_api.py` and
`packages/b/tests/test_api.py` each have a test on that line, the test
result has a result link to a test of each file. Otherwise, the parts
of the test result decide: they must match a pattern of the test entry
(terms `name-pattern` and `pattern-match`). A pattern is built from the
name path of the test entry, and, when the data asks for one, from a
prefix that comes from its path. The separators of the data join the
names. A separator that the data does not give is a part break: the
names on its two sides stand in two parts.

For example, vitest writes this case element for a test in the file
`src/math.test.ts`:

```xml
<testcase classname="src/math.test.ts" name="outer &gt; each 1 + 2 = 3" time="0.001"/>
```

The test case `it.each(...)('each %i + %i = %i', ...)` in
`describe('outer', ...)` has the name path `outer`, then
`each %i + %i = %i`. With the data of vitest in section 2.3, each `%i`
becomes a placeholder, and the pattern has one part:
`outer > each … + … = …`, where each `…` is a placeholder. The file
`src/math.test.ts` matches the path of the test entry, the case element
has no line, and the one part `outer > each 1 + 2 = 3` matches the
pattern, so the test result has a result link to the test entry.

### 2.6 Readings of report files

The reading of a report file of an import (term
`reading-of-a-report-file`) is the call of the function bind of the
adapter of its test runner, as Language packs defines it, or the default
reading, for a test runner with a match table. The term gives its
result: "bound", with test results and result links; "unreadable",
with no test result, such as for a report file that a job of continuous
integration cut short when it ended early; or "stopped". The program can stop a
reading for its limits, such as a reading of a very large report file,
or refuse memory to the adapter. The reading then has the result
"stopped", and the program gives nothing from the
evidence for that tree that the requirement
`give-nothing-for-stopped-readings` names. Which readings a program
stops can differ between conforming programs.

The term `reading-entry` gives the test entries of a reading, with
their test entry ids, such as `src/math.test.ts#3` for the third test
node of the file `src/math.test.ts`. So two conforming programs give an
adapter the same request for the same report file.

### 2.7 The tests that a test result names

A test result is linked to a test of the tree (term `linked-test`) by a
result link to a test entry with the path and the name of that test,
when the file of the test result, if it has one, matches that path.
Two tests of one file with equal names, such as two top-level
`it("adds")`, are linked to the same test results.

One test result can be linked to two tests with different files. For
example, `src/a.test.ts` and `lib/a.test.ts` each have `it("adds")`,
and a report file that names no folder gives the test result `adds`
with the file `a.test.ts`. That test result is linked to both tests. A
program can take an input of its own, such as an option that a person
gives, that removes some of these pairs: a narrowing, which is part of
the import. So two programs that get the same import give the same
outcomes. The term `narrowing-of-an-import`
says when a narrowing is valid. A valid narrowing removes a pair for
two tests of one file with equal names together, and it leaves each
test result that it pairs naming at least one test, so no failure can
disappear. A narrowing that is not valid removes no pair. A program with
no such input gives the import the empty narrowing.

A test result names a test when it is linked to the test, and a valid
narrowing does not remove that pair (term `named-test`). A test result
that names no test counts for no test.

### 2.8 Outcomes

The term `status-meaning` says which test results say passed and which
say failed. A test result with the status `skip` says neither.

A test can hold other tests (term `held-test`), as a `describe` block
holds the tests whose code is in it. A `verifies` edge on a test that
holds other tests stands for every test that it holds, by the suite
rule (term `suite-rule`). For example, `describe("limits")` holds `it("small")`
and `it("large")`. In an import, the test `limits` passed when `small`
and `large` each have a test result that says passed and no test result
that names one of the three says failed. It did not run when `large` has
no test result and no test result that names one of the three says
failed. It failed when a test result that names `limits` itself, or
`small`, or `large`, says failed.

The outcome of a test in an import (term `import-outcome`) is "passed",
"failed", or "not run". Each import counts alone: by the term
`tree-outcome`, a test passed in the evidence for a tree when it passed
in one or more imports, even when it failed in another. A test with two
test results that say passed and one with the status `skip` passed. A
test whose test results all have the status `skip` did not run.

### 2.9 Sources

With the outcome of a test in the evidence for a tree, a conforming
program gives its sources (term `outcome-source`), so that a person can
see where the outcome came from. So a report file whose reading has the
result "unreadable" is visible. When a test passed in one import and
failed in another, the sources show both, and a person sees a test that passes on
one system and fails on another. When the program gives whether a
`verifies` promise is kept, it gives, for each test whose outcome the
promise takes, that outcome and its sources (requirement
`give-promise-sources`).

### 2.10 Verified conformance vectors

A test with a `verifies` edge to a conformance vector, to a group of
conformance vectors, or to a vector set can make the conformance vectors
that it cites verified (term `verified-vector`). Skips of vectors inside
such a test are not visible in a report file: the pass counts for each
vector. For example, the test `test_offsets` with
`@verifies data-forms#toml[offsets][*]=v2` has the outcome "passed", so
each conformance vector of the group `offsets` that says a vector is
verified.

### 2.11 Findings

The terms `never-ran-finding`, `failed-finding`,
`ambiguous-result-finding`, and `unverified-vector-finding` give the
findings of four finding classes. The conformance vectors of an item
that is retired give no finding of the class `unverified-vector`. For
example, the subject of a finding of
the class `unverified-vector` can be `data-forms#toml[12]`.

## 3. Definitions

### 3.1 Report files

@term report-file=v1
@cites {
    packs#{valid-pack=v1, test-runner=v1},
    text#{text=v1, byte-sequence=v1},
}

A report file is a file that a test runner writes about the tests that
it ran, such as a JUnit XML file. As an input, a report file is four
things: its report content, which is a byte sequence, the bytes of the
file; its report name, which is a text, such as the path of the file as
a person gave it; its pack, which is a valid pack; and its test runner,
which is a test runner of the descriptor of its pack.

### 3.2 Imports

@term import=v1
@cites {
    ontology#{tree=v1, test=v1, test-evidence=v1},
    text#{text=v1, input=v1, whole-number=v1},
    #{report-file=v1},
}

An import is an input that stands for one execution of test runners on
the code of one tree: the tree of the import, for which it is given. It
has a root, which is a text, such as the absolute path of the folder of
the files of that tree; a sequence of one or more report files, the
report files that the execution wrote, in which one report content can
stand more than once, such as with two test runners; and a narrowing.
The number of a report file of the import is 1 more than the number of
the report files before it in that sequence. The narrowing is a finite
set of triples, each of the number of a report file of the import, a
whole number of 1 or more, and a test of that tree. The narrowing is
given to the program with the report files, such as by a person, and it
is the empty set when none is given.

### 3.3 The evidence for a tree

@term tree-evidence=v1
@cites {ontology#{tree=v1}, #{import=v1}}

The evidence for a tree is the imports that are given for that tree,
one for each time that an import is given for it, so one import can
stand in it more than once. A tree has evidence when, and only when, the
evidence for it has at least one import.

### 3.4 JUnit XML reports

@term junit-report=v1
@cites {
    w3c/rec-xml-20081126,
    text#{byte-sequence=v1, byte=v1, 0x-numeral=v1, text=v1, code-span=v1},
    packs#{adapter-call=v1},
}

A report content is a JUnit XML report when, and only when, it is a
well-formed XML document, as XML 1.0 (Fifth Edition) defines one, in
the encoding UTF-8 or UTF-16, that has no document
type declaration, and whose root element has the name `testsuites` or
the name `testsuite`. A report content that starts with the bytes 0xFE
0xFF, or with the bytes 0xFF 0xFE, is in UTF-16 when, and only when, its
encoding declaration is absent or names `UTF-16`. A report content that
does not start with these bytes is in UTF-8 when, and only when, its
encoding declaration is absent or names `UTF-8`. The name
in an encoding declaration is compared with no regard to the case of
ASCII letters. These definitions apply to a JUnit XML report:

- A suite element is an element with the name `testsuite` that is the
  root element, or whose parent is the root element and the root element
  has the name `testsuites`, or whose parent is a suite element.
- A case element is an element with the name `testcase` whose parent is
  a suite element.
- The outer suite elements of an element are the suite elements of
  which that element is a descendant, from the outermost to the
  innermost.
- An element has an attribute with a name when its start tag or its
  empty-element tag has an attribute specification with that name. The
  value of that attribute is its normalized value, as XML 1.0 (Fifth
  Edition) gives it for an attribute of the type CDATA.
- An element has a child with a name when one of the child elements of
  the element has that name.
- The name of an element or of an attribute is the text that its start
  tag, its empty-element tag, or its attribute specification writes for
  it, with no namespace processing.

### 3.5 The data of a runner

@term runner-data=v1
@cites {
    packs#{
        test-runner=v1, runner-setting=v1, runner-setting-binding=v1,
        valid-descriptor=v1,
    },
    identifiers#{id-pattern=v1},
    data-forms#{toml-value=v1},
    text#{text=v1, character=v1, code-span=v1},
}

This definition is for a test runner of a valid descriptor that has a
match table, and a valid binding of `runner-settings` for that test
runner. The keys of the data of a runner are these, each with the kind
of its value and its default:

- `path`: a TOML array of one or more TOML strings; no default.
- `anchor`: the TOML string `whole` or `tail`; default `whole`.
- `prefix`: the TOML string `none`, `path`, or `folders`; default
  `none`.
- `prefix-separator`, `suite-separator`, and `test-separator`: a TOML
  string; no default.
- `lead`, `suite-suffixes`, and `name-suffixes`: a TOML array of TOML
  strings; default the empty array.
- `placeholders`: a TOML array of TOML strings, each of which matches the
  production `pattern` of the term `id-pattern` of Identifiers; default
  the empty array.
- `rewrite`: a TOML array of TOML arrays, each of exactly two TOML
  strings; default the empty array.
- `file`: a TOML array of TOML strings; default the empty array.
- `line`: a TOML string; no default.
- `line-base`: the TOML integer 0 or 1; default 1.
- `not-run`: a TOML array of TOML strings, each of which has the
  character `=`; default the empty array.
- `recognise`: a TOML array of TOML strings, each of which has no
  character `@` or has the character `=` after its first `@`; default
  the empty array.

The data of the test runner is valid when, and only when, no text is
both a key of its match table and the name of one of its runner
settings, each key of its match table and each name of its runner
settings is one of these keys, the value that these rules give for each
key has the kind of that key, and `path` has a value. The value of a key
is the value of the runner setting whose name is that key, under the
binding, when the test runner has one; otherwise, the TOML value of that
key in the match table, when the match table has that key; otherwise,
its default; and a key with no default has no value.

### 3.6 The test results of a JUnit XML report

@term case-result=v1
@cites {
    ontology#{test-evidence=v1},
    text#{
        text=v1, character=v1, space=v1, whole-number=v1, production=v1,
        rule-name=v1, code-span=v1,
    },
    #{junit-report=v1, runner-data=v1, report-path-match=v1},
}

For a JUnit XML report and the valid data of a runner, the test results
of the report are one test result for each case element, in the order
of the document, with these values:

- Its parts: the texts that the members of `path` give, in their
  order. The member `suites` gives, for each outer suite element of the
  case element, the value of its attribute `name`. Each other member
  gives the value of the attribute of the case element whose name is
  that member. When an outer suite element has no attribute `name` and
  `path` has the member `suites`, or when the case element has no
  attribute whose name is another member of `path`, the test result has
  no parts.
- Its name: its parts, with one space between each two, or the empty
  text when it has no parts.
- Its status: `error` when the case element has a child with the name
  `error`; otherwise, `fail` when it has a child with the name
  `failure`; otherwise, `skip` when it has a child with the name
  `skipped`, or when a member of `not-run` applies to it; otherwise,
  `pass`. A member of `not-run` applies to the case element when the
  case element has the attribute whose name is the text before the first
  `=` of the member, with the value that is the text after that `=`.
- Its file: the first text, in the order of the members of `file`, that
  a member gives and that has at least one path part, or no file when no
  member gives such a text. A member that is `suite:` followed by a text
  a gives the value of the attribute with the name a of the innermost
  outer suite element of the case element that has that attribute. A
  member that is `document:` followed by a text a gives the value of the
  attribute with the name a of the first suite element of the document,
  in the order of the document, that has that attribute. Each other
  member gives the value of the attribute of the case element whose name
  is that member.
- Its line: when `line` has a value, and the case element has the
  attribute whose name is that value, and the value of that attribute
  matches the production `line-text`, and k is the whole number that it
  writes in base 10, the whole number k + 1 − b, where b is the value of
  `line-base`, when that number is 1 or more; otherwise, no line.
- Its duration: when the case element has the attribute `time`, and its
  value matches the production `duration-text` and writes the number x
  of seconds in base 10, the greatest whole number of milliseconds that
  is not more than 1000 × x; otherwise, no duration.

```abnf
line-text      = 1*DIGIT
duration-text  = 1*DIGIT [ "." 1*DIGIT ]
```

### 3.7 Matches of report files with valid paths

@term report-path-match=v1
@cites {files#{path=v1}, text#{text=v1, character=v1, whole-number=v1, code-span=v1}}

The path parts of a text are the texts that these steps give: replace
each character `\` of the text with `/`; split the text at each `/`
into a sequence of texts; remove each empty text and each text `.`;
then remove each text `..` that has no text other than `..` before it.
A text matches a valid path when, and only when, the text has at least
one path part, and, of the sequence of its path parts and the sequence
of the file names of the valid path, the shorter is equal to the end of
the longer. The length of that match is the number of the texts of the
shorter of the two sequences.

### 3.8 The patterns of test entries

@term name-pattern=v1
@cites {
    packs#{test-entry=v1, test-name=v1},
    identifiers#{id-pattern=v1, fit=v1},
    files#{path=v1},
    text#{text=v1, character=v1, run=v1, place=v1, whole-number=v1, code-span=v1},
    #{runner-data=v1},
}

For a test entry of the kind test case and the valid data of a runner,
the patterns of the test entry are sequences of parts, each a sequence
of elements. An element is a character, a placeholder, or an affix slot
of one of the keys `lead`, `suite-suffixes`, and `name-suffixes`. A part
break separates two parts. These steps give the patterns:

1. Rewrite. In each text piece of the name path of the test entry, for
   each pair of `rewrite`, in their order, whose first text is not
   empty: from the start of the text, each run equal to the first text
   that starts at or after the end of the run that this pair replaced
   before it is replaced with the second text.
2. Placeholders. Each text piece becomes a sequence of elements: from
   its start, at each place, the longest run that starts there, is not
   empty, and fits an id pattern of `placeholders` becomes a
   placeholder, and the steps go on at the end of that run; when no such
   run starts there, the character after the place is an element. Each
   placeholder of the name path is a placeholder. The elements of a name
   of the name path are the elements of its pieces, in their order.
3. Names. The names of the prefix are: when `prefix` is `path`, the file
   names of the path of the test entry other than its last, in their
   order, then its last file name up to its last `.`, when that `.` is
   not its first character, or else its last file name; when `prefix` is
   `folders`, the file names of the path of the test entry other than
   its last, in their order; and none when `prefix` is `none`. The
   elements of a name of the prefix are its characters. The suite names
   are the names of the name path other than its last, in their order,
   and the own name is its last name.
4. Join. For each whole number k from 1 to 1 more than the number of the
   names of the prefix when `anchor` is `tail`, and for k = 1 alone when
   `anchor` is `whole`, the names of one pattern are the names of the
   prefix from the k-th on, then the suite names, then the own name. The
   separator before each name other than the first is
   `prefix-separator` when the name before it is a name of the prefix
   and the name is a name of the prefix or a suite name;
   `suite-separator` when both are suite names; and `test-separator`
   when the name is the own name. A separator with no value is a part
   break; each other separator gives its characters as elements.
5. Sequence. The pattern is, in this order: an affix slot of `lead`;
   then, for each of its names in their order, the separator before it,
   the elements of the name, and, after a suite name, an affix slot of
   `suite-suffixes`, or, after the own name, an affix slot of
   `name-suffixes`. Its parts are the runs of this sequence between its
   part breaks.

### 3.9 Matches of patterns

@term pattern-match=v1
@cites {
    ontology#{test-evidence=v1},
    text#{text=v1, character=v1, code-span=v1},
    #{name-pattern=v1, case-result=v1, runner-data=v1},
}

A text is an instance of an affix pattern, which is a text, when the
text is the affix pattern with each character `*` replaced by some
text, the empty text included. The parts of a test result match a
pattern when, and only when, they are as many as the parts of the
pattern, and some choice of a text for each placeholder, and, for each
affix slot, of the empty text or an instance of a member of the key of
the slot, makes each part of the pattern, with each element replaced by
its text, equal to the part of the test result at the same index.

### 3.10 Default recognitions

@term default-recognition=v1
@cites {
    packs#{
        valid-descriptor=v1, test-runner=v1, runner-setting-binding=v1,
        adapter-call=v1,
    },
    text#{text=v1, character=v1, code-span=v1},
    #{junit-report=v1, runner-data=v1},
}

For a report content and a test runner of a valid descriptor that has a
match table, under a valid binding of `runner-settings` for that test
runner, the default recognition is "failed" when the data of the runner
is not valid; "recognised" when it is valid, the report content is a
JUnit XML report, and `recognise` is the empty array or one of its
members applies to the root element; and "not recognised" otherwise. A
member with no character `@` applies to the root element when the root
element has the name that is the member. Another member applies to the
root element when the root element has the name that is the text before
the first `@` of the member, and has the attribute whose name is the
text between that `@` and the first `=` after it, with the value that is
the text after that `=`.

### 3.11 Default readings

@term default-reader-result=v1
@cites {
    ontology#{test-evidence=v1},
    files#{path=v1},
    packs#{
        valid-descriptor=v1, test-runner=v1, runner-setting-binding=v1,
        test-entry=v1, adapter-call=v1,
    },
    text#{text=v1},
    #{
        junit-report=v1, runner-data=v1, case-result=v1,
        report-path-match=v1, name-pattern=v1, pattern-match=v1,
    },
}

For a report content, test entries whose test entry ids are each a
different text, and a test runner of a valid descriptor that has a
match table, under a valid binding of `runner-settings` for that test
runner, the default reading is "unreadable" when the data of the runner
is not valid or the report content is not a JUnit XML report. Otherwise,
it is "bound", and it gives the test results of the report, in their
order, and its result links: pairs of a test result and a test entry. A
test result with no parts has no result link. A test result with parts
has a result link to each test entry that these rules give:

1. The candidates are the test entries of the kind test case. When the
   test result has a file, the candidates are only those whose path the
   file matches, with the greatest length of the match among them.
2. A candidate contains a line when its first line is not after that
   line and its last line is not before it. When the test result has a
   file and a line, and at least one candidate contains the line, then,
   for each valid path, the test result has a result link to each
   candidate with that path that contains the line and whose first line
   is not before the first line of any other candidate with that path
   that contains the line.
3. Otherwise, it has a result link to each candidate that has a pattern
   that its parts match.

### 3.12 The test entries of readings

@term reading-entry=v1
@cites {
    documents#{file-reader-binding=v1, read-file=v1, unreadable-file=v1},
    packs#{
        reading-of-a-text=v1, test-node=v1, test-entry=v1,
        parse-tree-order=v1,
    },
    ontology#{tree=v1},
    files#{path=v1},
    text#{text=v1, decimal-numeral=v1, whole-number=v1, code-span=v1},
    #{report-file=v1, import=v1},
}

Under a valid binding of `file-readers`, the test entries of the reading
of a report file of an import are these: for each code file of the tree
of the import whose pack is the pack of the report file and that can be
read, and for each test node that the reading of the text of that code
file, with that pack, gives, the test entry of that test node whose test
entry id is the text of the valid path of the code file, then `#`, then
the decimal numeral of the number of the test node. The number of a test
node is 1 more than the number of the test nodes of that code file
before it in the order of the parse tree.

### 3.13 Readings of report files

@term reading-of-a-report-file=v1
@cites {
    documents#{file-reader-binding=v1},
    ontology#{test-evidence=v1},
    packs#{
        valid-pack=v1, test-runner=v1, runner-setting-binding=v1,
        test-entry=v1, adapter-request=v1, adapter-call=v1,
        adapter-instance=v1, valid-adapter=v1, call-result=v1,
    },
    text#{result=v1},
    #{report-file=v1, import=v1, reading-entry=v1, default-reader-result=v1},
}

Under a valid binding of `file-readers`, and a binding of
`runner-settings` for the test runner of a report file of an import, the
reading of that report file has one of the results "bound",
"unreadable", and "stopped". It is "unreadable" when the binding of
`runner-settings` is not valid. Otherwise:

- When the test runner has an adapter hash, the reading is the call of
  the function bind of the content of the file `adapters/<r>.wasm` of the
  pack of the report file, where `<r>` is the name of the test runner,
  as the adapter, with the request of the function bind for that test
  runner, that binding, the report name of the report file, the root of
  the import, and the test entries of the reading, with the report
  content of the report file, and with the test entry ids of the test
  entries of the reading as its test entry ids. Its result is "stopped"
  when, in that call or in the decision whether the adapter is a valid
  adapter that the call uses, the program stops the instantiation or an
  invocation, the program refuses a growth of a memory or of a table
  within its maximum, or the call stack is exhausted; otherwise, it is "bound" when the
  result of the call is "bound", and "unreadable" when it is "failed".
  With "bound", its test results are the test results of the call, and
  its result links are, for each binding object of the call, the pair of
  the test result of the binding object and the test entry whose test
  entry id it gives.
- When the test runner has a match table, the reading is the default
  reading of the report content with the test entries of the reading,
  for that test runner, under that binding. Its result is "stopped" when
  the program stops that reading, such as for its limits; otherwise, it
  is the result of the default reading. With "bound", its test results
  and its result links are those of the default reading.

A result link of a reading is one of the pairs of a test result and a
test entry that the reading gives with the result "bound".

### 3.14 Linked tests

@term linked-test=v1
@cites {
    documents#{file-reader-binding=v1, file-test=v1},
    packs#{test-entry=v1, test-name=v1},
    ontology#{test=v1, test-evidence=v1, tree=v1},
    files#{path=v1},
    text#{whole-number=v1},
    #{import=v1, reading-of-a-report-file=v1, report-path-match=v1},
}

Under a valid binding of `file-readers`, the test results of an import
are the test results of the readings of its report files that have the
result "bound". They are the test results, as the Ontology means them,
of the execution of test runners for which the import stands. The
number of a test result is 1 more than the number of the test results
before it in its reading. A test result of an import is linked to a test
of the tree of the import when, and only when, its reading has a result
link of that test result and a test entry whose path is the valid path
of the file of that test and whose name path is equal to the name of
that test, and the test result has no file, or has a file that matches
that valid path.

### 3.15 Valid narrowings

@term narrowing-of-an-import=v1
@cites {
    ontology#{test=v1, test-evidence=v1},
    packs#{test-name=v1},
    #{import=v1, linked-test=v1},
}

A triple of the narrowing of an import stands for the pair of the test
result of the import whose report file has the number that is the first
whole number of the triple, and whose number is the second whole number
of the triple, and the test of the triple, when the import has that test
result. Two tests are alike when they have one file and equal names,
and a test is alike to itself.
The narrowing of an import is valid when, and only when, each of its
triples stands for a pair, and, for each of these pairs, the test result
is linked to that test, and is linked to a test that is alike to the
test of no pair of that test result.

### 3.16 The tests that a test result names

@term named-test=v1
@cites {
    ontology#{test=v1, test-evidence=v1, tree=v1},
    #{import=v1, linked-test=v1, narrowing-of-an-import=v1},
}

A test result of an import names a test of the tree of the import, as
the Ontology means it, when, and only when, it is linked to that test,
and, when the narrowing of the import is valid, the narrowing has no
triple that stands for the pair of that test result and a test that is
alike to that test. A test result names no other test.

### 3.17 What statuses say

@term status-meaning=v1
@cites {
    ontology#{test=v1, test-evidence=v1},
    packs#{call-result=v1},
    #{named-test=v1},
}

As the Ontology means it, a test result with the status `pass` says that
the tests that it names passed, and a test result with the status `fail`
or the status `error` says that the tests that it names failed. A test
result with the status `skip` says neither.

### 3.18 Held tests

@term held-test=v1
@cites {
    documents#{file-test=v1},
    packs#{test-node=v1, enclosed-node=v1},
    ontology#{test=v1, tree=v1},
}

In a tree, a test T holds a test U when, and only when, U is in the file
of T, and the test node of T, whose run is the code of T, is one of the
test suites that enclose the test node of U. A test U of the tree is a
part of a test T of the tree, as the Ontology means it, when, and only
when, T holds U.

### 3.19 The suite rule

@term suite-rule=v1
@cites {
    ontology#{test=v1, test-evidence=v1, promise=v1, tree=v1},
    #{import=v1, linked-test=v1, held-test=v1, named-test=v1, status-meaning=v1},
}

The suite rule is the rule, for a test of which one or more other tests
are a part, that the term `promise` of the Ontology leaves to a design.
By the suite rule, the test evidence of the execution for which an
import stands shows that a test T of the tree of the import that holds
one or more tests passed when, and only when, each test that T holds and
that holds no test has a test result of the import that names it and
says that it passed, and no test result of the import names T, or a test
that T holds, and says that the tests that it names failed.

### 3.20 The outcomes of tests in an import

@term import-outcome=v1
@cites {
    ontology#{test=v1, test-evidence=v1, promise=v1, tree=v1},
    #{
        import=v1, linked-test=v1, held-test=v1, named-test=v1,
        status-meaning=v1, suite-rule=v1,
    },
}

The outcome of a test T of the tree of an import, in that import, is
one of these:

- "passed" when the test evidence of the execution for which the import
  stands shows that T passed: by the term `promise` of the Ontology when
  T holds no test, and by the suite rule when T holds one or more tests;
- otherwise, "failed" when a test result of the import names T, or a
  test that T holds, and says that the tests that it names failed;
- otherwise, "not run".

### 3.21 The outcomes of tests in the evidence for a tree

@term tree-outcome=v1
@cites {ontology#{test=v1, tree=v1}, #{tree-evidence=v1, import-outcome=v1}}

The outcome of a test of a tree in the evidence for that tree is
"passed" when its outcome in one or more imports of the evidence is
"passed"; otherwise, "failed" when its outcome in one or more imports
of the evidence is "failed"; otherwise, "not run".

### 3.22 The sources of outcomes

@term outcome-source=v1
@cites {
    data-forms#{hash=v1},
    ontology#{test=v1, test-evidence=v1, tree=v1},
    #{
        report-file=v1, import=v1, tree-evidence=v1,
        reading-of-a-report-file=v1, linked-test=v1, held-test=v1,
        named-test=v1, status-meaning=v1, import-outcome=v1,
        tree-outcome=v1,
    },
}

The sources of the outcome of a test T of a tree in the evidence for
that tree are one source for each import of the evidence, each time
that it stands in the evidence, with these values:

- for each report file of the import, in their order, the hash of its
  report content and the result of its reading;
- the outcome of T in that import;
- when that outcome is "passed", each test result of the import that
  names T, or a test that T holds, and says that the tests that it names
  passed; when it is "failed", each test result of the import that names
  T, or a test that T holds, and says that the tests that it names
  failed; and when it is "not run", no test result. These test results
  stand in the order of the numbers of their report files, and then of
  their numbers.

Each of these test results is given with the number of its report file,
the hash of the report content of that report file, its number, its
name, and its status.

### 3.23 Verified conformance vectors

@term verified-vector=v1
@cites {
    documents#{tree-edge=v1},
    ontology#{
        verifies-edge=v1, edge-source=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1, test=v1, tree=v1,
    },
    #{tree-evidence=v1, tree-outcome=v1},
}

A conformance vector of a vector set of a tree is verified in the
evidence for that tree when, and only when, it says a vector, and a test
of the tree that is the source of an edge of the tree of the kind
`verifies` whose cited item is that conformance vector, the group of
conformance vectors of that vector set that has it, or that vector set
has the outcome "passed" in the evidence for the tree.

### 3.24 Findings of the class `never-ran`

@term never-ran-finding=v1
@cites {
    identifiers#{citation-entry=v1},
    ontology#{
        edge=v1, edge-source=v1, verifies-edge=v1, test=v1, tree=v1,
        conformance-vector=v1, conformance-vector-group=v1, vector-set=v1,
    },
    text#{requirement=v1},
    documents#{
        tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
    #{tree-evidence=v1, tree-outcome=v1},
}

A tree that has evidence has one tree finding of the class `never-ran`
for each edge of the tree of the kind `verifies` whose source is a test
of the tree with the outcome "not run" in the evidence for the tree, and
whose cited item is an item of the kind requirement, a conformance
vector, a group of conformance vectors, or a vector set. A tree that has
no evidence has no tree finding of the class `never-ran`. The subject of
the finding is the position subject of the origin position of the
citation entry of the edge. Its spot is the spot of the run of that
citation entry in the text of the file.

### 3.25 Findings of the class `failed`

@term failed-finding=v1
@cites {
    identifiers#{citation-entry=v1},
    ontology#{
        edge=v1, edge-source=v1, verifies-edge=v1, test=v1, tree=v1,
        conformance-vector=v1, conformance-vector-group=v1, vector-set=v1,
    },
    text#{requirement=v1},
    documents#{
        tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
    #{tree-evidence=v1, tree-outcome=v1},
}

A tree that has evidence has one tree finding of the class `failed`
for each edge of the tree of the kind `verifies` whose source is a test
of the tree with the outcome "failed" in the evidence for the tree, and
whose cited item is an item of the kind requirement, a conformance
vector, a group of conformance vectors, or a vector set. A tree that has
no evidence has no tree finding of the class `failed`. The subject of
the finding is the position subject of the origin position of the
citation entry of the edge. Its spot is the spot of the run of that
citation entry in the text of the file.

### 3.26 Findings of the class `ambiguous-result`

@term ambiguous-result-finding=v1
@cites {
    packs#{test-node=v1, node-run=v1},
    documents#{file-test=v1, position-subject=v1, run-spot=v1, tree-finding=v1},
    ontology#{test=v1, test-evidence=v1, tree=v1},
    text#{position=v1, run=v1},
    #{tree-evidence=v1, import=v1, named-test=v1, narrowing-of-an-import=v1},
}

A tree that has evidence has one tree finding of the class
`ambiguous-result` for each test T of the tree that a test result of an
import of the evidence names, when that test result also names a test of
the tree that is not alike to T. A tree that has no evidence has no tree finding of the
class `ambiguous-result`. The subject of the finding is the position
subject of the position of the start of the code of T, which is the run
of its test node, in its file. Its spot is the spot of that run.

### 3.27 Findings of the class `unverified-vector`

@term unverified-vector-finding=v1
@cites {
    data-forms#{vector-line=v1},
    ontology#{
        conformance-vector=v1, vector-set=v1, item-name=v1, tree=v1,
        test=v1, in-force-item=v1, ledger=v1,
    },
    documents#{vector-file=v1, tree-finding=v1},
    findings#{spot=v1},
    files#{path=v1},
    text#{decimal-numeral=v1, span=v1, text-of-a-byte-sequence=v1, line-feed=v1, code-span=v1},
    #{tree-evidence=v1, verified-vector=v1},
}

A tree that has evidence has one tree finding of the class
`unverified-vector` for each conformance vector of the vector set of an
item that is in force in the tree at the end of the ledger of the
repository, when that conformance vector says a vector and is not
verified in the evidence for the tree. A tree that has no evidence has
no tree finding of the class `unverified-vector`. The subject of the finding is the
name of the item of its vector set, then `[`, then the decimal numeral
of the number of the conformance vector, then `]`. Its spot is the
valid path of the vector file of that item, with the span of the text of
its content whose characters are the text of the vector line of the
conformance vector without its line feed.

## 4. Requirements

### 4.1 Default recognitions

@req recognise-junit-reports=v1
@cites {
    packs#{
        valid-descriptor=v1, test-runner=v1, runner-setting-binding=v1,
        adapter-call=v1,
    },
    text#{conforming-program=v1, result=v1},
    #{default-recognition=v1},
}

When a conforming program gives the default recognition of a report
content for a test runner of a valid descriptor that has a match table,
under a valid binding of `runner-settings` for that test runner, it must
give exactly one result: the default recognition of that report content
for that test runner under that binding.

### 4.2 The results of readings

@req give-reading-results=v1
@cites {
    documents#{file-reader-binding=v1},
    text#{conforming-program=v1, result=v1},
    #{report-file=v1, import=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, when a conforming program gives
the result of the reading of a report file of an import, it must give
exactly one result: the result of that reading.

### 4.3 The test results of readings

@req give-reading-test-results=v1
@cites {
    documents#{file-reader-binding=v1},
    ontology#{test-evidence=v1},
    text#{conforming-program=v1, result=v1},
    #{report-file=v1, import=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, when, with the result "bound"
of the reading of a report file of an import, a conforming program gives
the test results of that reading, it must give each test result of that
reading once, in their order, with its name, its status, and its file,
its line, and its duration when it has them, and no other test result
of that reading.

### 4.4 The result links of readings

@req give-reading-result-links=v1
@cites {
    documents#{file-reader-binding=v1},
    ontology#{test-evidence=v1},
    packs#{test-entry=v1},
    text#{conforming-program=v1, result=v1},
    #{report-file=v1, import=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, when, with the result "bound"
of the reading of a report file of an import, a conforming program gives
the result links of that reading, it must give each result link of that
reading once, and no other result link of that reading.

### 4.5 No values of readings that do not bind

@req omit-reading-values=v1
@cites {
    documents#{file-reader-binding=v1},
    ontology#{test-evidence=v1},
    text#{conforming-program=v1, result=v1},
    #{report-file=v1, import=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, a conforming program must give
no test results and no result links of the reading of a report file of
an import when the result of that reading is not "bound".

### 4.6 The requests of readings

@req give-reading-requests=v1
@cites {
    documents#{file-reader-binding=v1},
    packs#{adapter-request=v1, adapter-call=v1, test-entry=v1},
    text#{conforming-program=v1},
    #{report-file=v1, import=v1, reading-entry=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, when a conforming program makes
a call of the function bind of an adapter for the reading of a report
file of an import, it must make it with the request that the term
`reading-of-a-report-file` gives, with the test entries of that reading and no
other test entry, and with the test entry ids of these test entries as
the test entry ids of the call.

### 4.7 Bytes only from the report content

@req read-only-report-content=v1
@cites {
    w3c/rec-xml-20081126,
    packs#{adapter-call=v1},
    text#{conforming-program=v1, byte=v1},
    #{default-recognition=v1, default-reader-result=v1},
}

For a default recognition or a default reading of a report content, a
conforming program must take the XML document only from the bytes of
that report content, and it must take nothing from a file or from a
resource of a network that the report content names.

### 4.8 Readings that end

@req end-report-readings=v1
@cites {text#{conforming-program=v1}, #{reading-of-a-report-file=v1}}

A conforming program must end each reading of a report file that it
makes.

### 4.9 The evidence for each tree

@req take-evidence-for-own-tree=v1
@cites {
    ontology#{tree=v1},
    text#{conforming-program=v1},
    #{import=v1, tree-evidence=v1},
}

A conforming program must count an import in the evidence for a tree
only when that import is given for that tree.

### 4.10 Outcomes

@req give-test-outcomes=v1
@cites {
    documents#{file-reader-binding=v1},
    ontology#{test=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{import=v1, tree-evidence=v1, import-outcome=v1, tree-outcome=v1},
}

Under a valid binding of `file-readers`, when a conforming program gives
the outcome of a test of a tree in an import of that tree, or in the
evidence for that tree, it must give exactly one outcome: the outcome of
that test in that import, or in that evidence.

### 4.11 The sources of outcomes

@req give-outcome-sources=v1
@cites {
    documents#{file-reader-binding=v1},
    ontology#{test=v1, tree=v1},
    text#{conforming-program=v1},
    #{tree-evidence=v1, tree-outcome=v1, outcome-source=v1},
}

Under a valid binding of `file-readers`, when a conforming program gives
the outcome of a test of a tree in the evidence for that tree, it must
give with it each source of that outcome once, and no other source.

### 4.12 The sources of kept promises

@req give-promise-sources=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    documents#{file-reader-binding=v1, tree-edge=v1},
    ontology#{promise=v1, verifies-edge=v1, edge-source=v1, test=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{tree-evidence=v1, tree-outcome=v1, outcome-source=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
whether a `verifies` promise is kept in a tree that has evidence, it
must give with it, once for each test that is the source of an edge of
the tree that is such an edge for that promise as the term `promise` of
the Ontology states, the outcome of that test in the evidence for that
tree and each source of that outcome once, and it must give no outcome
and no source for another test with it.

### 4.13 Nothing from evidence with a stopped reading

@req give-nothing-for-stopped-readings=v1
@cites {
    ontology#{promise=v1, tree=v1, test=v1},
    text#{conforming-program=v1, result=v1},
    #{
        report-file=v1, import=v1, reading-of-a-report-file=v1,
        tree-evidence=v1, import-outcome=v1, tree-outcome=v1,
        outcome-source=v1, never-ran-finding=v1, failed-finding=v1,
        ambiguous-result-finding=v1, unverified-vector-finding=v1,
    },
}

When the reading of a report file of an import of the evidence for a
tree has the result "stopped", a conforming program must give, from that
evidence, no
outcome of a test of that tree in that evidence or in that import, no
source of such an outcome, no result for whether a `verifies` promise is
kept in that tree, and no finding of that tree of the classes
`never-ran`, `failed`, `ambiguous-result`, and `unverified-vector`.

### 4.14 Nothing under bindings that are not valid

@req give-nothing-under-invalid-bindings=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    documents#{file-reader-binding=v1},
    packs#{runner-setting-binding=v1, test-entry=v1},
    ontology#{promise=v1, tree=v1, test=v1, test-evidence=v1},
    text#{conforming-program=v1, result=v1},
    #{
        report-file=v1, import=v1, tree-evidence=v1,
        reading-of-a-report-file=v1, import-outcome=v1, tree-outcome=v1,
        outcome-source=v1, never-ran-finding=v1, failed-finding=v1,
        ambiguous-result-finding=v1, unverified-vector-finding=v1,
    },
}

Under a binding of `file-readers` that is not valid, or a binding of
`external-namespaces` for which a conforming program of the design
Identifiers does not give the result "valid", a conforming program must
give no result of a reading of a report file, no test result or result
link of such a reading, no outcome of a test in an import or in the
evidence for a tree, no source of such an outcome, no result for whether
a `verifies` promise is kept in a tree that has evidence, and no finding
of the classes `never-ran`, `failed`, `ambiguous-result`, and
`unverified-vector`. When the binding of `runner-settings` for the test
runner of a report file of an import of the evidence for a tree is not
valid, it must give none of these from that evidence.

### 4.15 The findings of the evidence for a tree

@req give-evidence-findings=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    documents#{file-reader-binding=v1, tree-finding=v1},
    ontology#{finding-class=v1, tree=v1, in-force-item=v1, ledger=v1, vector-set=v1},
    text#{conforming-program=v1, result=v1},
    #{
        tree-evidence=v1, never-ran-finding=v1, failed-finding=v1,
        ambiguous-result-finding=v1, unverified-vector-finding=v1,
    },
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the findings of a tree of one of the classes `never-ran`, `failed`,
`ambiguous-result`, and `unverified-vector`, which rest on the evidence
for that tree, it must give each tree finding of that class that the
tree has once, and no other finding of that class. It must give findings
of the class `unverified-vector` only when it gives, for the item of
each vector set of the tree, whether that item is in force in the tree
at the end of the ledger.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 4.

The vectors of this design are in the file
[`evidence.test-vectors.jsonl`](evidence.test-vectors.jsonl), in the
same folder as this design. A vector is an input and what a conforming
program gives for it. Each vector follows from the requirements and adds
nothing to them. The vectors are in four groups, `recognitions`,
`readings`, `outcomes`, and `findings`, and each group has a subsection
below. The
subsection names the requirements that the vectors of the group follow
from, and it describes their inputs, results, and values. No vector
follows from the requirements `give-reading-requests`,
`read-only-report-content`, `end-report-readings`,
`take-evidence-for-own-tree`, `give-promise-sources`,
`give-nothing-for-stopped-readings`, and
`give-nothing-under-invalid-bindings`.

Each requirement from which vectors follow applies only when a program
gives the thing that it names, such as the result of a reading. So a
vector binds a program only to what the program gives for the input.

The file is a [test-vector set](sinter:data-forms#test-vector-set=v1).
Each line of the file is the
[canonical byte sequence](sinter:data-forms#canonical-byte-sequence=v1)
of one JSON object, then the byte 0x0A, so each line is a JSON text, as
RFC 8259 defines it. The file has three kinds of line, in this order:

1. The first line is the set line. Its JSON object has one member,
   `rev`: the revision of the whole set of vectors.
2. Then each group has a group line, in this order: `findings`,
   `outcomes`, `readings`, `recognitions`. Its JSON object has two members: `group`,
   the name of the group, as a JSON string, and `rev`, the revision of
   the group.
3. Then each vector has a vector line, in increasing order of the
   numbers of the vectors.

The JSON object of a vector line has these members:

- `n`: the number of the vector, a JSON number written as the decimal
  numeral of a whole number of 1 or more. No other vector of the file
  has this number. A number is given to one vector only: when a vector
  leaves the file, no later vector gets its number, and a new vector
  gets a number greater than each number before it.
- `rev`: the revision of the vector.
- `group`: the name of the group of the vector, as a JSON string.
- `input`: the input.
- `result`: the result that a conforming program gives when it gives a
  result for the input.
- `values`: a JSON object that gives what a conforming program gives
  for the input, other than the result. The subsection of the group says
  what it gives.
- `note`: an explanation of the vector, as a JSON string, which a
  conforming program does not give. A vector has this member only when
  it has an explanation.

No vector has the member `needs`: the vectors of this design have no
need names.

A revision is a JSON string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. The revision of the set line is the
revision of the whole set, the revision of a group line is the revision
of the group, and the revision of a vector line is the revision of the
vector. A revision rises, to a greater number after its `v`, when the
vectors that it covers change, join, or leave. When the text of this
section, other than its headings and the vector lines that it shows,
changes, the revisions of every vector, every group, and the set rise.
When only the note of a vector changes, no revision rises. A program
does not need the revisions to run the vectors.

Inside the members `input`, `result`, and `values`, the JSON values have
these forms:

- A text, such as a result, a name, or a test entry id, is a JSON string
  whose characters are the characters of the text, in order.
- A byte sequence, such as a report content, is a JSON string when it is
  the UTF-8 encoding of a text: the JSON string of that text. Otherwise,
  it is a JSON object with one member, `bytes`, whose value is a JSON
  string of hex digits: for each byte, in order, the hex digit of the
  whole-number quotient of the byte divided by 16, then the hex digit of
  the remainder.
- A TOML value is a JSON value of the same kind: a TOML string is a JSON
  string, a TOML boolean is a JSON boolean, a TOML integer is a JSON
  number of the same integer, a TOML array is a JSON array of the JSON
  values of its elements, in order, and a TOML table is a JSON object
  with one member for each of its keys.
- A name path is a JSON array with one JSON array for each name, in
  their order. The array of a name has one JSON object for each piece,
  in their order: `{"text": ...}` for a text piece and
  `{"placeholder": ...}` for a placeholder, with the text of the piece
  as a JSON string.
- A test entry is a JSON object with the members `id`, `path`, `line`,
  `eline`, `suite`, and `names`: its test entry id, its path, its first
  line, its last line, true for the kind test suite and false for the
  kind test case, and its name path. Its test labels are empty.

### 5.1 Recognitions

The group `recognitions` has the vectors of the requirement
`recognise-junit-reports`. Each vector gives a report content and the
data of a test runner, and the default recognition.

- `input`: a JSON object with the members `match`, the match table of the
  test runner, a TOML table; `settings`, a JSON object with one member
  for each runner setting of the test runner, whose key is its name and
  whose value is its value under the binding of `runner-settings`, a
  TOML value; and `report`, the report content, a byte sequence.
- `result`: "recognised", "not recognised", or "failed": the default
  recognition of the report content for the test runner.
- `values`: the empty JSON object, `{}`.

When a conforming program gives the default recognition of the report
content of the input for its test runner, it gives the result that
`result` gives, and no other result.

```
{"group":"recognitions","input":{"match":{"path":["name"]},"report":"<testsuites name=\"vitest tests\"><testsuite name=\"a\"/></testsuites>","settings":{"recognise":["testsuites@name=vitest tests"]}},"n":1,"note":"the attribute name of the root element has the value that the member gives","result":"recognised","rev":"v1","values":{}}
```

### 5.2 Readings

The group `readings` has the vectors of the requirements
`give-reading-results`, `give-reading-test-results`,
`give-reading-result-links`, and `omit-reading-values`, for test runners with a match table. Each vector
gives a report content, the data of a test runner, and test entries,
and the default reading: its result, its test results, and its result
links.

- `input`: a JSON object with the members `match`, `settings`, and
  `report`, as in the group `recognitions`, and `tests`, a JSON array of
  the test entries, each a test entry, in the code point order of their
  test entry ids.
- `result`: "bound" or "unreadable": the result of the reading of a report
  file with that report content, whose test runner has that match table
  and those runner settings, when its test entries are those of `tests`
  and the program does not stop it.
- `values`: with "bound", a JSON object with the members `results` and
  `links`. `results` is a JSON array with one JSON object for each test
  result, in their order, with the members `name`, the name of the test
  result, and `status`, its status, and with the members `file`, its
  file, `line`, its line, and `ms`, its duration in whole milliseconds,
  each only when the test result has it. `links` is a JSON array with
  one JSON array for each result link, of two members: the number of the test
  result, which is 1 more than the number of the test results before it,
  and the test entry id of the test entry, in increasing order of the
  number, then in the code point order of the test entry id. With
  "unreadable", the empty JSON object, `{}`.

When a conforming program gives the result of that reading, it gives the
result that `result` gives, and no other result. When it gives the test
results of the reading, it gives the test results that `results` gives,
in their order, with the values that `results` gives, and no other test
result. When it gives the result links of the reading, it gives the result
links that `links` gives, and no other result link. When `values` is
`{}`, it gives no test result and no result link.

```
{"group":"readings","input":{"match":{"file":["classname"],"path":["name"],"placeholders":["%[sdifjoOc]","[$][A-Za-z_][A-Za-z0-9_.]*"],"suite-separator":" > ","test-separator":" > "},"report":"<testsuites name=\"vitest tests\"><testsuite name=\"src/math.test.ts\"><testcase classname=\"src/math.test.ts\" name=\"outer &gt; each 1 + 2 = 3\" time=\"0.001\"/></testsuite></testsuites>","settings":{"recognise":["testsuites@name=vitest tests"]},"tests":[{"eline":9,"id":"src/math.test.ts#1","line":1,"names":[[{"text":"outer"}]],"path":"src/math.test.ts","suite":true},{"eline":4,"id":"src/math.test.ts#2","line":2,"names":[[{"text":"outer"}],[{"text":"each %i + %i = %i"}]],"path":"src/math.test.ts","suite":false}]},"n":101,"note":"each %i becomes a placeholder, and the file matches the path","result":"bound","rev":"v1","values":{"links":[[1,"src/math.test.ts#2"]],"results":[{"file":"src/math.test.ts","ms":1,"name":"outer > each 1 + 2 = 3","status":"pass"}]}}
```

### 5.3 Outcomes

The group `outcomes` has the vectors of the requirements
`give-test-outcomes` and `give-outcome-sources`, and, for the class
`ambiguous-result`, of the requirement `give-evidence-findings`. Each
vector gives tests of a tree, the evidence for that tree, and one test,
and the outcome of that test in the evidence, with its sources, and
whether the tree has a finding of the class `ambiguous-result` for that
test. The readings of the report files are given by their results,
their test results, and their result links, and the tests are given by
their valid paths, their names, and the tests that hold them. The tree
of each vector has no other test that a test result names, and the
bindings of `file-readers` and of `external-namespaces` are valid.

- `input`: a JSON object with the members `tests`, `imports`, and
  `test`.
  - `tests` is a JSON array of tests of the tree. A test is a JSON
    object with the members `path`, the valid path of its file; `name`,
    its name, a JSON array with a JSON string for each of its names, in
    their order, for a name of one text piece with that text; and
    `suites`, a JSON array of the indexes in `tests`, from 0, of the
    tests that hold it.
  - `imports` is a JSON array of the imports of the evidence for the
    tree. An import is a JSON object with the member `files`, a JSON
    array of its report files, in their order, and, when its narrowing
    is not empty, the member `narrowing`, a JSON array of its triples,
    each a JSON array of the number of a report file, the number of a
    test result, and the index in `tests` of a test. A report file is a
    JSON object with the members `hash`, the hash of its report content,
    a text; `reading`, the result of its reading, "bound" or
    "unreadable"; and, with "bound", `results`, a JSON array of the test
    results of its reading, in their order. A test result is a JSON
    object with the members `name`, its name; `status`, its status;
    `file`, its file, only when it has one; and `links`, a JSON array
    with, for each of its result links, the index in `tests` of one test
    whose path and name are those of the test entry of that result link.
  - `test` is the index in `tests` of the test whose outcome the vector
    gives.
- `result`: "passed", "failed", or "not run": the outcome of that test
  in the evidence for the tree.
- `values`: a JSON object with the members `ambiguous`, true when the
  tree has a finding of the class `ambiguous-result` for that test, and
  false when it has none; and `sources`, a JSON array of the sources of
  the outcome, one for each import, in the vector in the order of
  `imports`. A source
  is a JSON object with the members `files`, a JSON array with a JSON
  object for each report file of the import, in their order, with the
  members `hash` and `reading`; `outcome`, the outcome of the test in
  that import; and `results`, a JSON array of the test results of the
  source, in their order, each a JSON object with the members
  `report-number`, the number of its report file, `report`, the hash of
  the report content of that report file, `n`, its number, `name`, and
  `status`.

When a conforming program gives the outcome of that test in the
evidence for the tree, it gives the outcome that `result` gives, and no
other outcome. With that outcome, it gives the sources that `sources`
gives, and no other source; the order of the sources is not part of
what it gives. When it gives the findings of the class
`ambiguous-result` of the tree, it gives one for that test when
`ambiguous` is true, and none for that test when it is false.

```
{"group":"outcomes","input":{"imports":[{"files":[{"hash":"0000000000000000000000000000000000000000000000000000000000000001","reading":"bound","results":[{"links":[1],"name":"small","status":"pass"},{"links":[2],"name":"large","status":"pass"}]}]}],"test":0,"tests":[{"name":["limits"],"path":"t.ts","suites":[]},{"name":["limits","small"],"path":"t.ts","suites":[0]},{"name":["limits","large"],"path":"t.ts","suites":[0]}]},"n":201,"note":"a test that holds tests passed: each test that it holds passed","result":"passed","rev":"v1","values":{"ambiguous":false,"sources":[{"files":[{"hash":"0000000000000000000000000000000000000000000000000000000000000001","reading":"bound"}],"outcome":"passed","results":[{"n":1,"name":"small","report":"0000000000000000000000000000000000000000000000000000000000000001","report-number":1,"status":"pass"},{"n":2,"name":"large","report":"0000000000000000000000000000000000000000000000000000000000000001","report-number":1,"status":"pass"}]}]}}
```

### 5.4 Findings

The group `findings` has the vectors of the requirement
`give-evidence-findings` for the classes `never-ran`, `failed`, and
`unverified-vector`. Each vector gives the outcomes of tests in the
evidence for a tree, the edges of the kind `verifies` of the tree, and
the conformance vectors of vector sets of the tree, and the findings of
these classes that the tree has. The outcomes come from the group
`outcomes`, and the edges and the vectors are given by what the terms
of these classes take from them.

- `input`: a JSON object with the members `evidence`, `tests`, `edges`,
  and `sets`.
  - `evidence` is true when the tree has evidence, and false when it has
    none.
  - `tests` is a JSON array of tests of the tree, each a JSON object
    with one member, `outcome`, its outcome in the evidence for the
    tree.
  - `edges` is a JSON array of the edges of the kind `verifies` of the
    tree. An edge is a JSON object with the members `source`, the index
    in `tests`, from 0, of its source, a test; `subject`, the position
    subject of the origin position of its citation entry, a text; and
    `cited`, its cited item: a JSON object whose member `kind` is
    `requirement` for an item of the kind requirement; `vector`, with
    the members `set`, the name of the item of its vector set, and `n`,
    its number, for a conformance vector; `group`, with the members
    `set` and `group`, its name, for a group of conformance vectors;
    `set`, with the member `set`, for a vector set; `other` for an item
    of another kind; and `none` when the edge has no cited item.
  - `sets` is a JSON array of vector sets of the tree. A vector set is a
    JSON object with the members `name`, the name of its item; `in-force`,
    true when that item is in force in the tree at the end of the ledger,
    and false when it is not; and `vectors`, a JSON array of its
    conformance vectors, each a JSON object with the members `n`, its
    number, `group`, the name of its group, and `says`, true when it says
    a vector, and false when it says no vector.
- `values`: a JSON object with one member, `findings`: a JSON array of
  the findings of the classes `never-ran`, `failed`, and
  `unverified-vector` that the tree has, each a JSON array of the slug
  of its class and its subject, in the code point order of the class and
  then of the subject.

The vectors of this group have no member `result`. When a conforming
program gives the findings of one of these classes of the tree, it gives
one finding of that class for each element of `findings` with that
class, with that subject, and no other finding of that class.

```
{"group":"findings","input":{"edges":[{"cited":{"group":"offsets","kind":"group","set":"data-forms#toml"},"source":0,"subject":"t.py@L1C3"}],"evidence":true,"sets":[{"in-force":true,"name":"data-forms#toml","vectors":[{"group":"offsets","n":1,"says":true},{"group":"offsets","n":2,"says":true},{"group":"keys","n":3,"says":true},{"group":"keys","n":4,"says":false}]}],"tests":[{"outcome":"passed"}]},"n":304,"note":"a pass of a test that cites a group verifies each vector of the group; a vector that says no vector gives no finding","rev":"v1","values":{"findings":[["unverified-vector","data-forms#toml[3]"]]}}
```
