<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Test evidence
@design evidence=v1
@cites conformance=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites object-store=v1
@cites packs=v1
@cites findings=v1
@cites documents=v1
@cites w3c/rec-xml-20081126
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies report files and imports, the evidence for a tree, JUnit XML
reports and the default reader of JUnit XML with the data of a runner,
the readings of report files and their test entries, the tests that a
test result names and narrowings, the outcomes of tests in an import and
in the evidence for a tree with the suite rule, the sources of outcomes,
the verified groups of conformance vectors, the finding classes `never-ran`,
`failed`, `ambiguous-result`, and `unverified-vector`, and requirements
for conforming programs that read report files, keep imports, and give
outcomes, sources, and these findings.

A test runner, such as pytest or vitest, runs the tests of a repository
and writes report files: files that say which tests ran, and whether
each passed, failed, or was skipped. A person or continuous integration
gives a conforming program the report files of one execution of test
runners together, for one tree: that is an import. The imports that are
given for a tree are the evidence for that tree. Each of those imports
counts alone.

A program reads each report file of an import with the test runner of
the report file. A test runner of a language pack has an adapter of its
own, or a match table. The default reader reads the report files of a
test runner with a match table. The default reader reads JUnit XML. A
reading gives test results, and result links that join a test result to
test entries. Each test entry stands for a test of the tree. From the
test results that name a test, the program gives the outcome of the
test: passed, failed, or not run. With each outcome, the program gives
the sources of the outcome, so that a person can see where the outcome
came from. Some conditions of the evidence for a tree are findings, such
as a `verifies` edge whose test did not run.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405.

From Conformance (`conformance`), the design takes requirements,
conforming programs, inputs, safety obligations, and the general
requirements that bind every conforming program. From Text and notation,
the design takes texts, characters, spaces, places, runs, positions, and
spans; whole numbers and decimal numerals; bytes and byte sequences; the
notation of productions; and results. From Identifiers, the design takes
citation entries, id patterns, valid id patterns, the fit of a text to
an id pattern, and the bindings of `external-namespaces` with the
results that a conforming program of Identifiers gives for those
bindings. From Files and paths, it takes folders, folder trees, valid
paths, and their file names. From Data forms, the design takes hashes;
TOML values; hex texts; and, from the specification `test-vectors` of
Data forms, vector lines, the forms of groups, and the meaning of
vectors. From the Ontology, it takes trees, tests, test results and test
evidence, edges with their sources and cited items, the edges of the
kind `verifies`, declared items and schemas, parameters, the names of
items, conformance vectors, groups of conformance vectors, vector sets,
promises, and finding classes. From Language packs, it takes valid packs
and valid descriptors, test runners with their adapter hashes, match
tables, and runner settings; the bindings of `runner-settings` and the
values of runner settings; the readings of texts, test nodes with their
kinds test case and test suite, the runs of nodes, enclosed nodes, the
order of the parse tree, and the names of test nodes; test entries, the
requests of the function bind, calls, and the results of calls with
their test results and binding objects. From Findings, it takes spots.
From the Object store, it takes local files, the object store of a tree,
and when that object store is valid. From Documents, it takes the
bindings of `file-readers` and of `vector-paths`, the caller input
`kept-object-set`, read files and code files, files that cannot be read,
the tests of a read file, vector files, the edges of a tree, origins and
origin positions, position subjects, the spots of runs, and tree
findings.

From XML 1.0 (Fifth Edition), the W3C Recommendation of 26 November
2008, the design takes well-formed XML documents, their encodings,
document type declarations, encoding declarations, elements with their
names, content, parents, children, and descendants, root elements, start
tags, empty-element tags, attribute specifications, and the normalized
values of attributes of the type CDATA. From RFC 8259, it takes JSON
values, with their objects, members, arrays, strings, numbers, and the
literal names `true` and `false`.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [test runner](sinter:packs#test-runner=v1) | a program that runs tests, gives a test result for each test that it runs, and writes report files, such as vitest; in a descriptor of a language pack, a test runner has an adapter hash or a match table |
| [report file](sinter:#report-file=v1) | a file that a test runner writes about the tests that the test runner ran; as an input, a report file is its report content, which is the bytes of the file, its report name, its pack, and its test runner |
| [import](sinter:#import=v1) | an input that stands for one execution of test runners: the tree of the import (excluding local files), a root, one or more report files, and a narrowing |
| [execution of test runners](sinter:#import=v1) | the runs of test runners whose report files are given together in one import, such as one job of continuous integration, or three jobs that each run a third of the tests |
| [evidence for a tree](sinter:#tree-evidence=v1) | the imports that are given for that tree, one for each time that an import is given for that tree; a tree has evidence when that tree has at least one import |
| [JUnit XML report](sinter:#junit-report=v1) | a report content that is a well-formed XML document in UTF-8 or UTF-16, with no document type declaration, whose root element is `testsuites` or `testsuite` |
| [suite element](sinter:#junit-report=v1), [case element](sinter:#junit-report=v1) | in a JUnit XML report, a `testsuite` element that is the root, a child of the root `testsuites`, or a child of a suite element; a `testcase` element whose parent is a suite element |
| [data of a runner](sinter:#runner-data=v1), [value of a key](sinter:#runner-data-value=v1) | the values of a closed set of keys for a test runner with a match table, from the runner settings of the test runner, from the match table of the test runner, or from defaults; the data of a runner can be valid or not |
| default reader | the reader of JUnit XML reports that a conforming program uses for the report files of a test runner with a match table: what the default reader gives is the default recognition and the default reading |
| [test results of a JUnit XML report](sinter:#case-result=v1) | one test result for each case element, with the name parts, the name, and the status of the test result, and, when the case element gives them, the file, the line, and the duration of the test result |
| [name part of a test result](sinter:#case-result=v1) | a text that the default reader reads for a test result by a member of `path`, such as the value of the attribute `name` of its case element |
| [path parts](sinter:#report-path-match=v1), [match a valid path](sinter:#report-path-match=v1) | the texts between the `/` and `\` of a text, without empty texts, without `.`, and without `..` at the start; a text matches a valid path when the text has path parts, and the shorter of the path parts of the text and the file names of the valid path is equal to the end of the longer; the length of the match is the number of the texts of the shorter |
| [patterns of a test entry](sinter:#name-pattern=v1) | sequences of pattern parts that the default reader compares with the name parts of test results: the names of a prefix, the names of the name path of the test entry, separators, placeholders, and affix slots |
| [match a pattern](sinter:#pattern-match=v1) | the name parts of a test result match a pattern when the name parts are as many as the pattern parts of the pattern, and texts for the placeholders of the pattern, and, for the affix slots of the pattern, texts that are the empty text or instances of affix patterns, make each pattern part equal to the name part of the test result |
| [default recognition](sinter:#default-recognition=v1) | "recognised" or "not recognised": whether the default reader takes a report content as a report file of a test runner |
| [default reading](sinter:#default-reader-result=v1) | "bound", with test results and result links, or "unreadable": what the default reader gives for a report content and test entries |
| [result link](sinter:#reading-of-a-report-file=v1) | a pair of a test result and a test entry that a reading gives with the result "bound" |
| [test entries of a reading](sinter:#reading-entry=v1) | one test entry for each test node of the code files of the tree that can be read and whose pack has, in its descriptor, a test runner with the name of the test runner of the report file, each with the test entry id that the term gives |
| [reading of a report file](sinter:#reading-of-a-report-file=v1) | "bound" with test results and result links, or "unreadable": the call of bind of the adapter of the test runner of the report file, or the default reading |
| [test results of an import](sinter:#linked-test=v1), [linked](sinter:#linked-test=v1) | when the reading of each report file of the import has a result, the test results of those readings with the result "bound"; a test result is linked to a test of the tree when a result link joins the test result to a test entry with the path, the name, and the kind of the test, and the test result has no file or has a file that matches that path; a test result is linked to a test suite only when that test suite holds a test |
| [narrowing](sinter:#import=v1), [valid narrowing](sinter:#narrowing-of-an-import=v1) | a set of triples of the number of a report file of the import, the number of a test result, and a test, each of which can stand for a pair of a test result and a test; a narrowing is valid when each triple stands for a pair, and the test result of each pair is linked to the test of the pair, and to a test alike to no test with which a triple pairs that test result; two tests are alike when they have one file, equal names, and test nodes of one kind, and a test is alike to itself |
| [a test result names a test](sinter:#named-test=v1) | under a valid narrowing and when the reading of each report file of the import has a result, a test result names a test when the test result is linked to that test, and the narrowing has no triple for the pair of the test result and a test alike to that test |
| [says passed, says failed](sinter:#status-meaning=v1) | a test result with the status `pass` says that the tests that the test result names passed; a test result with the status `fail` or `error` says that the tests that the test result names failed; a test result with the status `skip` says neither |
| [hold](sinter:#held-test=v1) | in a tree, a test T holds a test U of the file of T when the test node of T is a test suite that encloses the test node of U |
| [suite rule](sinter:#suite-rule=v1) | the rule by which test evidence shows that a test T that holds other tests passed: T holds at least one test case, each test case that T holds has a test result that names that test case and says passed, and no test result that names T or a test that T holds says failed |
| [outcome in an import](sinter:#import-outcome=v1) | "passed", "failed", or "not run": what the test results of one import say of a test, when the narrowing of the import is valid and the reading of each report file of the import has a result |
| [outcome in the evidence for a tree](sinter:#tree-outcome=v1) | "passed" when the outcome in one or more imports of the evidence is "passed"; otherwise, when the test has an outcome in each import, "failed" when the outcome in one or more imports is "failed" and otherwise "not run"; a test has no outcome in the evidence when it passed in no import and has no outcome in some import |
| [sources of an outcome](sinter:#outcome-source=v1) | when the test has an outcome in the evidence, for each import of the evidence in which the test has an outcome: for each report file of that import, the hash of the report content of that report file and the result of the reading of that report file; the outcome in that import; the triples of the narrowing that remove a pair of the test, of a test that the test holds, or of a test alike to one of these; and the test results that made that outcome (for "not run", the test results with the status `skip`), each test result with the number and the hash of the report content of the report file of that test result, the number of that test result, the name of that test result, and the status of that test result |
| [verified](sinter:#verified-vector=v1) | a group of conformance vectors is verified when that group has at least one conformance vector that says a vector, and a test with a `verifies` edge to that group or to the vector set of that group has the outcome "passed" in the evidence for the tree |
| [`never-ran`](sinter:#never-ran-finding=v1), [`failed`](sinter:#failed-finding=v1) | the finding classes, for a tree that has evidence, of a `verifies` edge to a requirement, a schema, a group, or a vector set, whose source is a test with the outcome "not run", or "failed", in the evidence for the tree |
| [`ambiguous-result`](sinter:#ambiguous-result-finding=v1) | the finding class, for a tree that has evidence, of a test T that a test result names, when the test result also names a test that is not alike to T |
| [`unverified-vector`](sinter:#unverified-vector-finding=v1) | the finding class, for a tree that has evidence, and for a given set S of declared items of the tree, of a group of conformance vectors of a declared item in S, when that group has at least one conformance vector that says a vector, that group is not verified, and each test of the tree with a `verifies` edge to that group or its vector set has an outcome in the evidence |

## 2. Report files, readings, and outcomes

### 2.1 Report files and imports

A report file, such as `out/junit.xml`, is a file that a test runner
writes about the tests that it ran. As an input of a conforming program,
a report file is what the term `report-file` gives, such as the bytes
of `out/junit.xml`, the name `out/junit.xml`, a TypeScript pack, and
its test runner vitest.

An import (term `import`) has the report files that one execution of
test runners wrote, given together. An import is given for one tree: the
tree of a commit, such as in continuous integration, or the tree of a
working tree. An import also has a root, which the request of a call of
bind gives an adapter, and a narrowing (section 2.7). For example, three
machines of continuous integration each run one third of the tests of a
commit, and a person gives the three report files to the program in one
import. The import is then one execution of test runners. When the
person gives each report file in an import of its own, the program has
three imports, and each is one execution. When one run of a test runner
covers the tests of two packs, such as `*.test.js` and `*.test.ts`, and
the descriptors of both packs have a test runner with the name of the
test runner of that run, each reading of that report file takes the test
entries of both packs (term `reading-entry`). So the default reader
links a test result whose name parts match tests of both packs to each
of those tests. The default reader builds the patterns of every test
entry of the reading from the data of the test runner of the report
file. When one of the packs has a test runner that has a match table, a
person can give the report content once with a test runner that has a
match table. A person can also give the report content once with each
test runner that has an adapter, because the code of each adapter is its
own.

The evidence for a tree (term `tree-evidence`) is the imports that are
given for that tree. A program can keep imports from one of its runs to
the next, in a form of its own. The requirement
`take-evidence-for-own-tree` limits where the program counts those
imports. When a person edits a comment or adds a file of `.sinter/`
after an import, the tree changes, and the import is not in the
evidence for the new tree. Adding or changing a local file in
`.sinter/local/` does not change the tree of an import. In a run in
which a conforming program could not take content of a file or a folder
under the term `input` of Conformance, that conforming program keeps no
import of that run for a later run, in `.sinter/local/` or anywhere
else (requirement `write-no-import-after-read-error`).

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

In a language pack, a test runner that has no adapter of its own has a
match table in the descriptor of that pack. The default reader reads the
report files of such a test runner with the data of the runner (schema
`runner-data` and term `runner-data-value`). The schema gives the keys
of the data and when the data is valid. The term gives the value of each
key. A pack can make a key a runner setting, such as `recognise`, so
that a binding of `runner-settings` in a project can change that key.
For example, this is the data of vitest in a TypeScript pack:

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
`skipped` child has the status `fail`. A case element with a `skipped`
child and no `error` or `failure` child, such as a case element whose
only child is `<skipped type="pytest.xfail"/>`, has the status `skip`
whatever the data of the runner is.

The name parts of a test result are the texts that the default reader
reads for that test result by the members of `path`. With
`path = ["classname", "name"]`, the second case element of the report of
section 2.2 has the two name parts `tests.test_math.TestAdd` and
`test_two`, and its name is `tests.test_math.TestAdd test_two`. A test
result with no name parts, such as for a case element that lacks an
attribute that `path` names, is linked to no test.

The term also gives the file, the line, and the duration of a test
result, when the case element gives them. For example, `time="0.0019"`
gives a duration of 1 millisecond. A value such as `1,203.5` or `4e-7`
gives no duration.

### 2.5 The result links of the default reader

The default reader gives result links of each test result to test
entries (term `default-reader-result`). A test result with a file gets
result links only to test entries whose path the file matches (term
`report-path-match`). For example, the files `src/math.test.ts`,
`./src/math.test.ts`, `math.test.ts`, and
`/home/ci/work/src/math.test.ts` all match the valid path
`src/math.test.ts`. The file `test/math.test.ts` does not match
`src/math.test.ts`. When the file `pkg/tests/test_utils.py` matches both
`pkg/tests/test_utils.py` and `tests/test_utils.py`, only the first
counts, because it matches every path part of the file. When the file
`/home/ci/work/src/math.test.ts` matches both `src/math.test.ts` and
`work/src/math.test.ts`, neither matches every path part, so both count.

The name parts of the test result then decide: the test result has a
result link to each of these test entries that has a pattern that those
name parts match (terms `name-pattern` and `pattern-match`). When the
name parts match test entries of two files, the test result has a result
link to each of those test entries. So when pytest writes
`file="tests/test_api.py"`, and the files `packages/a/tests/test_api.py`
and `packages/b/tests/test_api.py` each have a test `test_list`, the
test result is linked to both, and, unless a narrowing removes one of
these pairs, each of them gets a finding of the class
`ambiguous-result`. The line of a test result chooses no result link. A
person can use the line, or anything else that the person knows, to give
a narrowing (section 2.7). A pattern is built from the name path of the
test entry, and, when the data asks for a prefix, from a prefix that
comes from the path of the test entry. The separators of the data join
the names. A separator that the data does not give is a part break: the
names on its two sides stand in two pattern parts.

For example, vitest writes this case element for a test in the file
`src/math.test.ts`:

```xml
<testcase classname="src/math.test.ts" name="outer &gt; each 1 + 2 = 3" time="0.001"/>
```

The test case `it.each(...)('each %i + %i = %i', ...)` in
`describe('outer', ...)` has the name path `outer`, then `each %i + %i =
%i`. With the data of vitest in section 2.3, each `%i` becomes a
placeholder, and the pattern has one pattern part: `outer > each … + … =
…`, where each `…` is a placeholder. The file `src/math.test.ts` matches
the path of the test entry, and the one name part `outer > each 1 + 2 =
3` matches the pattern, so the test result has a result link to the test
entry.

A test result can also have a result link to a test suite. For example,
a Go test `TestFoo` runs the subtest `x`; `x` passes, and then `TestFoo`
fails. The test node of `TestFoo` encloses the test node of `x`, so the
test node of `TestFoo` is a test suite. The report has one case element
with the name `TestFoo` and a `failure` child, and one case element with
the name `TestFoo/x`. With `path` set to `name` and both separators set
to `/`, the one name part `TestFoo` matches the pattern of the test
suite, so its failure counts.

### 2.6 Readings of report files

The reading of a report file of an import (atom
`reading-of-a-report-file`) is the call of the function bind of the
adapter of the test runner of the report file, as Language packs defines
that call, or the default reading, for a test runner with a match table.
The atom gives the result of the reading: "bound", with test results and
result links; or "unreadable", with no test result, such as for a report
file that a job of continuous integration cut short when that job ended
early.

The term `reading-entry` gives the test entries of a reading, with their
test entry ids, such as `src/math.test.ts#3` for the third test node of
the file `src/math.test.ts`. So two conforming programs give an adapter
the same request for the same report file under the same binding of
`file-readers`.

### 2.7 The tests that a test result names

The term `linked-test` says when a test result is linked to a test of
the tree. Two test cases of one file with equal names, such as two
top-level `it("adds")`, are alike. A result link to the test entry of
one of those two test cases links the test result to both of them. A
test case `it("parse")` and a test suite `describe("parse")` that holds
`it("x")`, in one file, are not alike, so a result link to the test
entry of one does not link the test result to the other. The default
reader gives the two test entries equal patterns, so it gives the test
result `parse` a result link to the test entry of each, and each of the
two tests gets a finding of the class `ambiguous-result`, unless a
narrowing removes one of the pairs.

One test result can be linked to two tests with different files. For
example, `src/a.test.ts` and `lib/a.test.ts` each have `it("adds")`, and
a report file that names no folder gives the test result `adds` with the
file `a.test.ts`. That test result is linked to both tests. A program
can take an input, such as an option that a person gives, that removes
some of these pairs: a narrowing, which is part of the import. So two
programs that get the same import give the same outcomes under the same
binding of `file-readers`. The term
`narrowing-of-an-import` says when a narrowing is valid. A valid
narrowing removes a pair for two alike tests together, and it leaves
each test result that it pairs naming at least one test, so no failure
can disappear. When no
narrowing is given, the import has the empty narrowing.

Under a valid narrowing, a test result names a test when the test result
is linked to the test, and the narrowing does not remove that pair (term
`named-test`). A test result that names no test counts for no test.

### 2.8 Outcomes

The term `status-meaning` says which test results say passed and which
say failed. A test result with the status `skip` says neither.

A test can hold other tests (term `held-test`), as a `describe` block
holds the tests whose code is in it. A `verifies` edge on a test that
holds other tests stands for every test case that the test holds, by the
suite rule (term `suite-rule`). For example, `describe("limits")` holds
`it("small")` and `it("large")`. In an import, the test `limits` passed
when `small` and `large` each have a test result that names that test
and says passed, and no test result that names one of the three says
failed. The test `limits` did not run when no test result names `large`
and says passed, and no test result that names one of the three says
failed. The test `limits` failed when a test result that names `limits`
itself, or `small`, or `large`, says failed. A test suite that holds no
test case, such as a `describe` block that holds only an empty
`describe` block, never passes.

The outcome of a test in an import (atom `import-outcome`) is "passed",
"failed", or "not run". Each import counts alone. By the atom
`tree-outcome`, a test passed in the evidence for a tree when that test
passed in one or more imports, even when that test failed in another
import. A test with two test results that say passed and one test result
with the status `skip` passed. A test whose test results all have the
status `skip` did not run.

### 2.9 Sources

With the outcome of a test in the evidence for a tree, a conforming
program gives the sources of that outcome (term `outcome-source`), so
that a person can see where the outcome came from. So a report file
whose reading has the result "unreadable" is visible. When a test passed
in one import and failed in another, the sources show both, and a person
sees a test that passes on one system and fails on another. When a
narrowing removes the pair of a test result that says failed and
`it("adds")` in `lib/a.test.ts`, the source, for that import, of the
outcome of the suite `describe("math")` that holds `it("adds")` has the
triple of the narrowing that stands for that pair. When the program
gives whether a `verifies` promise is kept, the program gives, for each
test whose outcome the promise takes, that outcome and the sources of
that outcome (requirement `give-promise-sources`).

### 2.10 Verified groups of conformance vectors

A test with a `verifies` edge to a group of conformance vectors can make
that group verified, and a test with such an edge to a vector set can
make each group of that vector set verified (term `verified-vector`).
Skips of vectors inside such a test are not visible in a report file:
the pass counts for each of these groups. For example, the test
`test_offsets` with `@verifies data-forms#toml[offsets]` has the outcome
"passed", so the group `offsets` is verified when that group has at
least one conformance vector that says a vector.

### 2.11 Findings

The atoms `never-ran-finding`, `failed-finding`,
`ambiguous-result-finding`, and `unverified-vector-finding` give the
findings of four finding classes. For example, the subject of a finding
of the class `unverified-vector` can be `data-forms#toml[keys]`.

## 3. Definitions

### 3.1 Report files

@term report-file=v1
@cites {
    packs#{valid-pack=v1, test-runner=v1},
    text#{text=v1, byte-sequence=v1},
}

A report file is a file that a test runner writes about the tests that
it ran, such as a JUnit XML file. As an input, a report file is four
things: its report content, its report name, its pack, and its test
runner. The report content is a byte sequence, the bytes of the file.
The report name is a text, such as the path of the file as a person gave
it. The pack is a valid pack. The test runner is a test runner of the
descriptor of that pack.

### 3.2 Imports

@term import=v1
@cites {
    ontology#{tree=v1, test=v1, test-evidence=v1},
    object-store#{store-file=v1},
    conformance#{input=v1},
    text#{text=v1, whole-number=v1},
    #{report-file=v1},
}

An import is an input that stands for one execution of test runners: the
runs of test runners whose report files are given together in the
import. That execution is on the code of one tree, the tree of the
import, which excludes every local file (term `store-file` of the Object
store). An import is given for a tree T when, and only when, the tree of
the import is T without its local files. The import has a root, a
sequence of one or more report files, and a narrowing. The root is a
text, such as the absolute path of the folder of the files of the tree
of the import. The report files in that sequence are the report files
that the execution wrote. One report content can stand more than once in
that sequence, such as with two test runners. The number of a report
file of the import is 1 more than the number of the report files before
it in that sequence. The narrowing is a finite set of triples, each of
the number of a report file of the import, a whole number of 1 or more,
and a test of the tree of the import. The narrowing is given to the
program with the report files, such as by a person. When no narrowing is
given, the narrowing is the empty set. The narrowing is only what is
given with the import: a program derives no narrowing from the report
files or from the tree.

### 3.3 The evidence for a tree

@term tree-evidence=v1
@cites {ontology#{tree=v1}, #{import=v1}}

The evidence for a tree is the imports that are given for that tree, one
for each time that an import is given for that tree. So one import can
stand in that evidence more than once. A tree has evidence when, and
only when, the evidence for it has at least one import.

### 3.4 JUnit XML reports

@term junit-report=v1
@cites {
    w3c/rec-xml-20081126,
    text#{text=v1, code-span=v1},
    packs#{adapter-call=v1},
}

A report content is a JUnit XML report when, and only when, all four of
these conditions are true. First, the report content is a well-formed
XML document, as XML 1.0 (Fifth Edition) defines one. Second, the report
content is in the encoding UTF-8 or UTF-16, as XML 1.0 (Fifth Edition)
gives the encodings of entities. Third, the report content has no
document type declaration. Fourth, the root element of the report
content has the name `testsuites` or the name `testsuite`. The name in
an encoding declaration is compared with no regard to the case of ASCII
letters. These definitions apply to a JUnit XML report:

- A suite element is an element with the name `testsuite` that meets one
  of these three conditions. First, the element is the root element.
  Second, the parent of the element is the root element, and the root
  element has the name `testsuites`. Third, the parent of the element is
  a suite element.
- A case element is an element with the name `testcase` whose parent is
  a suite element.
- The outer suite elements of an element are the suite elements of which
  that element is a descendant, from the outermost to the innermost.
- An element has an attribute with a name when its start tag or its
  empty-element tag has an attribute specification with that name. The
  value of that attribute is its normalized value, as XML 1.0 (Fifth
  Edition) gives the normalized value for an attribute of the type
  CDATA.
- An element has a child with a name when one of the child elements of
  the element has that name.
- The name of an element is the text that its start tag or its
  empty-element tag writes for it. The name of an attribute is the text
  that its attribute specification writes for it.

### 3.5 The data of a runner

@schema runner-data=v1
@cites {
    packs#{
        test-runner=v1, runner-setting=v1, runner-settings=v1,
        runner-setting-value=v1, valid-descriptor=v1,
    },
    ontology#{parameter=v1},
    identifiers#{valid-id-pattern=v1},
    data-forms#{toml-value=v1},
    text#{text=v1, character=v1, code-span=v1},
}

This schema is for a test runner of a valid descriptor that has a
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
- `placeholders`: a TOML array of TOML strings, each of which is a
  valid id pattern (term `valid-id-pattern` of Identifiers); default
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

The data of the test runner meets the schema `runner-data`, and is
valid, when, and only when, all five of these conditions are true.
First, no text is both a key of the match table of the test runner and
the name of one of the runner settings of the test runner. Second, each
key of that match table and each name of those runner settings is one of
the keys of the data of a runner. Third, the value of each of those
runner settings under the binding has the kind of the key that is the
name of that runner setting. Fourth, the TOML value of each key of that
match table has the kind of that key. Fifth, `path` is a key of that
match table or the name of one of those runner settings.

### 3.6 The values of the data of a runner

@term runner-data-value=v1
@cites {
    packs#{
        test-runner=v1, runner-setting=v1, runner-settings=v1,
        runner-setting-value=v1, valid-descriptor=v1,
    },
    ontology#{parameter=v1},
    data-forms#{toml-value=v1},
    text#{code-span=v1},
    #{runner-data=v1},
}

This term is for a test runner of a valid descriptor that has a match
table, under a valid binding of `runner-settings` for that test runner,
when the data of the runner is valid. For a key of the data of the
runner, when the test runner has a runner setting whose name is that
key, the value of that key is the
value of that runner setting under the binding. When the match table has
that key, the value of that key is the TOML value of that key in the
match table. When neither has that key and that key has a default, the
value of that key is the default of that key. Otherwise, that key has no
value.

### 3.7 The test results of a JUnit XML report

@term case-result=v1
@cites {
    ontology#{test-evidence=v1},
    text#{
        text=v1, character=v1, space=v1, whole-number=v1, production=v1,
        rule-name=v1, code-span=v1,
    },
    #{
        junit-report=v1, runner-data=v1, runner-data-value=v1,
        report-path-match=v1,
    },
}

For a JUnit XML report and the valid data of a runner, the test results
of the report are one test result for each case element, in the order of
the document, with these values:

- Its name parts: the texts that the members of `path` give, in their
  order. The member `suites` gives, for each outer suite element of the
  case element, the value of the attribute `name` of that outer suite
  element. Each other member gives the value of the attribute of the
  case element whose name is that member. When an outer suite element
  has no attribute `name` and `path` has the member `suites`, or when
  the case element has no attribute whose name is another member of
  `path`, the test result has no name parts.
- Its name: its name parts, with one space between each two, or the
  empty text when it has no name parts.
- Its status: when the case element has a child with the name `error`,
  the status is `error`. Otherwise, when the case element has a child
  with the name `failure`, the status is `fail`. Otherwise, when the
  case element has a child with the name `skipped`, or when a member of
  `not-run` applies to the case element, the status is `skip`.
  Otherwise, the status is `pass`. A member of `not-run` applies to the
  case element when the case element has the attribute whose name is the
  text before the first `=` of the member, with the value that is the
  text after that `=`.
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
- Its line: when `line` has a value, the case element has the attribute
  whose name is that value, and the value of that attribute matches the
  production `line-text`, k is the whole number that the value of that
  attribute writes in base 10, and b is the value of `line-base`. Under
  those conditions, when k + 1 − b is 1 or more, the line is the whole
  number k + 1 − b. In every other case, the test result has no line.
- Its duration: when the case element has the attribute `time`, and the
  value of that attribute matches the production `duration-text` and
  writes the number x of seconds in base 10, the duration is the
  greatest whole number of milliseconds that is not more than 1000 × x.
  Otherwise, the test result has no duration.

```abnf
line-text      = 1*DIGIT
duration-text  = 1*DIGIT [ "." 1*DIGIT ]
```

### 3.8 Matches of report files with valid paths

@term report-path-match=v1
@cites {
    files#{path=v1},
    text#{text=v1, character=v1, whole-number=v1, code-span=v1},
}

The path parts of a text are the texts that these steps give: replace
each character `\` of the text with `/`; split the text at each `/` into
a sequence of texts; remove each empty text and each text `.`; then
remove each text `..` that has no text other than `..` before it. A text
matches a valid path when, and only when, the text has at least one path
part, and, of the sequence of its path parts and the sequence of the
file names of the valid path, the shorter is equal to the end of the
longer. The length of that match is the number of the texts of the
shorter of the two sequences.

### 3.9 The patterns of test entries

@term name-pattern=v1
@cites {
    packs#{test-entry=v1, test-name=v1},
    identifiers#{id-pattern=v1, fit=v1},
    files#{path=v1},
    text#{
        text=v1, character=v1, run=v1, place=v1, whole-number=v1,
        code-span=v1,
    },
    #{runner-data=v1, runner-data-value=v1},
}

For a test entry and the valid data of a runner, the patterns of the
test entry are sequences of pattern parts, each a sequence of elements.
An element is a character, a placeholder, or an affix slot of one of the
keys `lead`, `suite-suffixes`, and `name-suffixes`. A part break
separates two pattern parts. These steps give the patterns:

1. Rewrite. In each text piece of the name path of the test entry, for
   each pair of `rewrite`, in their order, whose first text is not
   empty, in the text that the pairs before it give: from the start of
   the text, each run equal to the first text that starts at or after
   the end of the run that this pair replaced before it is replaced with
   the second text.
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
   separator before each name other than the first is `prefix-separator`
   when the name before it is a name of the prefix and the name is a
   name of the prefix or a suite name; `suite-separator` when both are
   suite names; and `test-separator` when the name is the own name. A
   separator with no value is a part break; each other separator gives
   its characters as elements.
5. Sequence. The pattern is, in this order: an affix slot of `lead`;
   then, for each of its names in their order, the separator before it,
   the elements of the name, and, after a suite name, an affix slot of
   `suite-suffixes`, or, after the own name, an affix slot of
   `name-suffixes`. Its pattern parts are the runs of this sequence
   between its part breaks.

### 3.10 Matches of patterns

@term pattern-match=v1
@cites {
    ontology#{test-evidence=v1},
    text#{text=v1, character=v1, code-span=v1},
    #{
        name-pattern=v1, case-result=v1, runner-data=v1,
        runner-data-value=v1,
    },
}

An affix pattern is a text. A text is an instance of an affix pattern
when that text is the affix pattern with each character `*` replaced by
some text, the empty text included. The name parts of a test result
match a pattern when, and only when, both of these conditions are true.
First, the name parts of the test result are as many as the pattern
parts of the pattern. Second, some choice of texts makes each pattern
part, with each element replaced by its text, equal to the name part of
the test result at the same index: the choice picks a text for each
placeholder, and, for each affix slot, the choice picks the empty text
or an instance of a member of the key of the slot.

### 3.11 Default recognitions

@atom default-recognition=v1
@cites {
    packs#{
        valid-descriptor=v1, test-runner=v1, runner-settings=v1,
        adapter-call=v1,
    },
    ontology#{parameter=v1},
    text#{text=v1, character=v1, code-span=v1},
    #{junit-report=v1, runner-data=v1, runner-data-value=v1},
}

This atom is for a report content and a test runner of a valid
descriptor that has a match table, under a valid binding of
`runner-settings` for that test runner, when the data of the runner is
valid. When the report content is a JUnit XML report, and either
`recognise` is the empty array or one of the members of `recognise`
applies to the root element, the default recognition is "recognised". In
every other case, the default recognition is "not recognised". A member
with no character `@` applies to the root element when the root element
has the name that is the member. Another member applies to the root
element when the root element has the name that is the text before the
first `@` of the member, and has the attribute whose name is the text
between that `@` and the first `=` after it, with the value that is the
text after that `=`.

### 3.12 Default readings

@term default-reader-result=v1
@cites {
    ontology#{test-evidence=v1, parameter=v1},
    files#{path=v1},
    packs#{
        valid-descriptor=v1, test-runner=v1, runner-settings=v1,
        test-entry=v1, adapter-call=v1,
    },
    text#{text=v1},
    #{
        junit-report=v1, runner-data=v1, case-result=v1,
        report-path-match=v1, name-pattern=v1, pattern-match=v1,
    },
}

This term is for a report content, test entries whose test entry ids are
each a different text, and a test runner of a valid descriptor that has
a match table, under a valid binding of `runner-settings` for that test
runner, when the data of the runner is valid. When the report content is
not a JUnit XML report, the default reading is "unreadable". Otherwise,
the default reading is "bound", and it gives the test results of the
report, in their order, and the result links of the default reading. Each result link is a pair of a test result and a test entry. A
test result with no name parts has no result link. A test result with
name parts has a result link to each test entry that these rules give:

1. The candidates are the test entries. When the test result has a file,
   the candidates are only those whose path the file matches; and when
   the length of the match of one of them is the number of the path
   parts of the file, only those with that length of the match.
2. The test result has a result link to each candidate that has a
   pattern that its name parts match.

### 3.13 The test entries of readings

@term reading-entry=v1
@cites {
    documents#{file-readers=v1, read-file=v1, unreadable-file=v1},
    packs#{
        reading-of-a-text=v1, test-node=v1, test-entry=v1,
        parse-tree-order=v1, test-runner=v1,
    },
    ontology#{tree=v1, parameter=v1},
    files#{path=v1},
    text#{text=v1, decimal-numeral=v1, whole-number=v1, code-span=v1},
    #{report-file=v1, import=v1},
}

Under a valid binding of `file-readers`, the test entries of the reading
of a report file of an import are these: for each code file of the tree
of that import that can be read under that binding and whose pack has,
in its descriptor, a test runner with the name of the test runner of the
report file, and for each test node that the reading of the text of that
code file, with that pack, gives, the test entry of that test node whose
test entry id is the text of the valid path of the code file, then `#`,
then the decimal numeral of the number of the test node. The
number of a test node is 1 more than the number of the test nodes of
that code file before it in the order of the parse tree.

### 3.14 Readings of report files

@atom reading-of-a-report-file=v1
@cites {
    documents#{file-readers=v1},
    ontology#{tree=v1, test-evidence=v1, parameter=v1},
    packs#{
        valid-pack=v1, test-runner=v1, runner-settings=v1,
        test-entry=v1, adapter-request=v1, adapter-call=v1,
        call-result=v1,
    },
    text#{result=v1},
    #{
        report-file=v1, import=v1, runner-data=v1, reading-entry=v1,
        default-reader-result=v1,
    },
}

Under a valid binding of `file-readers` and a valid binding of
`runner-settings` for the test runner of a report file of an import,
when either that test runner has an adapter hash or the data of that
test runner is valid, the reading of that report file has one of the
results "bound" and "unreadable":

- When the test runner has an adapter hash, the reading is the call of
  the function bind of the adapter, with the request, with the report
  content of the report file, and with the test entry ids of the test
  entries of the reading as the test entry ids of the call. When the
  test runner has an adapter hash, the adapter of that call is the
  content of the file `adapters/<r>.wasm` of the pack of the report
  file, where `<r>` is the name of the test runner. When the test runner
  has an adapter hash, the request of that call is the request of the
  function bind for that test runner, that valid binding of
  `runner-settings`, the report name of the report file, the root of the
  import, and the test entries of the reading. When the result of the
  call is "bound", the result of the reading is "bound". When the result
  of the call is "failed", the result of the reading is "unreadable".
  When the result of the reading is "bound", the test results of the
  reading are the test results of the call. When the result of the
  reading is "bound", the result links of the reading are, for each
  binding object of the call, the pair of the test result of the binding
  object and the test entry whose test entry id that binding object
  gives.
- When the test runner has a match table, the reading is the default
  reading of the report content with the test entries of the reading,
  for that test runner, under that valid binding of `runner-settings`.
  The result of the reading is the result of the default reading. When
  the result of the reading is "bound", the test results and the result
  links of the reading are the test results and the result links of the
  default reading.

A result link of a reading is one of the pairs of a test result and a
test entry that the reading gives with the result "bound".

### 3.15 Linked tests

@term linked-test=v1
@cites {
    documents#{file-readers=v1, file-test=v1},
    packs#{test-entry=v1, test-name=v1, test-node=v1},
    ontology#{test=v1, test-evidence=v1, tree=v1, parameter=v1},
    files#{path=v1},
    text#{whole-number=v1, result=v1},
    #{
        report-file=v1, import=v1, reading-of-a-report-file=v1,
        report-path-match=v1, held-test=v1,
    },
}

Under a valid binding of `file-readers`, for an import in which the
reading of each report file has a result, the test results of the import
are the test results of those readings, under that binding, that have
the result "bound". The test
results of an import are the test results, as the Ontology means them,
of the execution of test runners for which the import stands. The number
of a test result is 1 more than the number of the test results before it
in its reading. A test result of an import is linked to a test of the
tree of the import when, and only when, all three of these conditions
are true:

- the reading of the test result has a result link of that test result and a test entry whose path is the valid path of the file of that test, whose name path is equal to the name of that test, and whose kind is the kind of the test node of that test;
- the test result has no file, or has a file that matches the valid path of the file of that test;
- when the test node of that test is a test suite, that test holds a test.

### 3.16 Valid narrowings

@term narrowing-of-an-import=v1
@cites {
    ontology#{test=v1, test-evidence=v1},
    documents#{file-test=v1},
    packs#{test-name=v1, test-node=v1},
    text#{whole-number=v1},
    #{import=v1, linked-test=v1},
}

For a triple of the narrowing of an import, when the import has a test
result whose report file has the number that is the first whole number
of the triple and whose number is the second whole number of the triple,
that triple stands for the pair of that test result and the test of the
triple. Two tests are alike when they have one file, equal names, and
test nodes of one kind. A test is alike to itself. The narrowing of an
import is valid when, and only when, all three of these conditions are
true:

- each triple of the narrowing stands for a pair of a test result and a test;
- for each of these pairs, the test result of the pair is linked to the test of the pair;
- for each of these pairs, the test result of the pair is linked to a test that is not alike to the test of any of these pairs whose test result is that test result.

### 3.17 The tests that a test result names

@term named-test=v1
@cites {
    ontology#{test=v1, test-evidence=v1, tree=v1},
    text#{result=v1},
    #{
        report-file=v1, import=v1, reading-of-a-report-file=v1,
        linked-test=v1, narrowing-of-an-import=v1,
    },
}

For an import whose narrowing is valid and in which the reading of each
report file has a result, a test result of that import
names a test of the tree of that import, as the Ontology means it, when,
and only when, both of these conditions are true:

- the test result is linked to that test;
- the narrowing has no triple that stands for the pair of that test result and a test that is alike to that test.

A test result names no other test.

### 3.18 What statuses say

@term status-meaning=v1
@cites {
    ontology#{test=v1, test-evidence=v1},
    packs#{call-result=v1},
    #{named-test=v1},
}

As the Ontology means it, a test result with the status `pass` says that
the tests that the test result names passed. As the Ontology means it, a
test result with the status `fail` or the status `error` says that the
tests that the test result names failed. A test result with the status
`skip` says neither.

### 3.19 Held tests

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

### 3.20 The suite rule

@term suite-rule=v1
@cites {
    ontology#{test=v1, test-evidence=v1, promise=v1, tree=v1},
    packs#{test-node=v1},
    #{
        import=v1, linked-test=v1, held-test=v1, named-test=v1,
        status-meaning=v1,
    },
}

The suite rule is the rule, for a test of which one or more other tests
are a part, that the term `promise` of the Ontology leaves to a design.
By the suite rule, the test evidence of the execution for which an
import stands shows that a test T of the tree of the import that holds
one or more tests passed when, and only when, all three of these
conditions are true:

- T holds at least one test whose test node is a test case;
- each test U that T holds and whose test node is a test case has a test result of the import that names U and says that U passed;
- no test result of the import names T, or a test that T holds, and says that the tests that the test result names failed.

### 3.21 The outcomes of tests in an import

@atom import-outcome=v1
@refines ontology#promise=v1
@cites {
    ontology#{test=v1, test-evidence=v1, tree=v1},
    text#{result=v1},
    #{
        report-file=v1, import=v1, reading-of-a-report-file=v1,
        linked-test=v1, held-test=v1, narrowing-of-an-import=v1,
        named-test=v1, status-meaning=v1, suite-rule=v1,
    },
}

For an import whose narrowing is valid and in which the reading of each
report file has a result, the outcome of a test T of the
tree of that import, in that import, is one of these:

- "passed" when the test evidence of the execution for which the import
  stands shows that T passed: by the term `promise` of the Ontology when
  T holds no test, and by the suite rule when T holds one or more tests;
- otherwise, "failed" when a test result of the import names T, or a
  test that T holds, and says that the tests that the test result names
  failed;
- otherwise, "not run".

### 3.22 The outcomes of tests in the evidence for a tree

@atom tree-outcome=v1
@cites {
    ontology#{test=v1, tree=v1},
    #{tree-evidence=v1, import=v1, import-outcome=v1},
}

The outcome of a test of a tree in the evidence for that tree is "passed"
when the outcome of that test in one or more imports of the evidence is
"passed". When that test has an outcome in each import of the evidence
and its outcome in the evidence is not "passed", its outcome in the
evidence is "failed" when its outcome in one or more imports of the
evidence is "failed", and otherwise "not run". In each other case, the
test has no outcome in the evidence for that tree.

### 3.23 The sources of outcomes

@term outcome-source=v1
@cites {
    data-forms#{hash=v1},
    ontology#{test=v1, test-evidence=v1, tree=v1},
    #{
        report-file=v1, import=v1, tree-evidence=v1,
        reading-of-a-report-file=v1, linked-test=v1, held-test=v1,
        named-test=v1, status-meaning=v1, import-outcome=v1,
        tree-outcome=v1, narrowing-of-an-import=v1,
    },
}

When a test T of a tree has an outcome in the evidence for that tree,
the sources of that outcome are one source for each import of the
evidence in which T has an outcome, each time the
import stands in the evidence, with these values:

- for each report file of the import, in their order, the hash of its
  report content and the result of its reading;
- the outcome of T in that import;
- each triple of the narrowing of that import that stands for the pair
  of a test result and a test that is T, a test that T holds, or a test
  alike to T or to a test that T holds;
- these test results of the import:
  - when the outcome of T in that import is "passed", each test result
    of the import that names T, or a test that T holds, and says that
    the tests that the test result names passed;
  - when the outcome of T in that import is "failed", each test result
    of the import that names T, or a test that T holds, and says that
    the tests that the test result names failed;
  - when the outcome of T in that import is "not run", each test result
    of the import that names T, or a test that T holds, and has the
    status `skip`. These test results stand in the order of the numbers
    of their report files, and then of the numbers of the test results.

Each of these test results is given with the number of its report file,
the hash of the report content of that report file, and the number, the
name, and the status of the test result.

### 3.24 Verified groups of conformance vectors

@term verified-vector=v1
@cites {
    documents#{tree-edge=v1},
    ontology#{
        edge=v1, verifies-edge=v1, edge-source=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1, test=v1, tree=v1,
    },
    #{tree-evidence=v1, tree-outcome=v1},
}

A group of conformance vectors of a vector set of a tree is verified in
the evidence for that tree when, and only when, both of these conditions
are true:

- that group of conformance vectors has at least one conformance vector that says a vector;
- the tree has an edge of the kind `verifies` whose cited item is that group of conformance vectors or that vector set, and whose source is a test of the tree with the outcome "passed" in the evidence for the tree.

### 3.25 Findings of the class `never-ran`

@atom never-ran-finding=v1
@cites {
    identifiers#{citation-entry=v1},
    ontology#{
        edge=v1, edge-source=v1, verifies-edge=v1, schema=v1, test=v1,
        tree=v1, conformance-vector-group=v1, vector-set=v1,
    },
    conformance#{requirement=v1},
    documents#{
        tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
    #{tree-evidence=v1, tree-outcome=v1},
}

A tree that has evidence has one tree finding of the class `never-ran`
for each edge of the tree of the kind `verifies` whose source is a test
of the tree with the outcome "not run" in the evidence for the tree, and
whose cited item is an item of the kind requirement, a schema, a group
of conformance vectors, or a vector set. A tree that has no evidence has
no tree finding of the class `never-ran`. The subject of the finding is
the position subject of the origin position of the citation entry of the
edge. Its spot is the spot of the run of that citation entry in the text
of the file.

### 3.26 Findings of the class `failed`

@atom failed-finding=v1
@cites {
    identifiers#{citation-entry=v1},
    ontology#{
        edge=v1, edge-source=v1, verifies-edge=v1, schema=v1, test=v1,
        tree=v1, conformance-vector-group=v1, vector-set=v1,
    },
    conformance#{requirement=v1},
    documents#{
        tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
    #{tree-evidence=v1, tree-outcome=v1},
}

A tree that has evidence has one tree finding of the class `failed` for
each edge of the tree of the kind `verifies` whose source is a test of
the tree with the outcome "failed" in the evidence for the tree, and
whose cited item is an item of the kind requirement, a schema, a group
of conformance vectors, or a vector set. A tree that has no evidence has
no tree finding of the class `failed`. The subject of the finding is the
position subject of the origin position of the citation entry of the
edge. Its spot is the spot of the run of that citation entry in the text
of the file.

### 3.27 Findings of the class `ambiguous-result`

@atom ambiguous-result-finding=v1
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
the tree that is not alike to T. A tree that has no evidence has no tree
finding of the class `ambiguous-result`. The subject of the finding is
the position subject of the position of the start of the code of T,
which is the run of the test node of T, in the file of T. The spot of
the finding is the spot of that run.

### 3.28 Findings of the class `unverified-vector`

@atom unverified-vector-finding=v1
@cites {
    ontology#{
        conformance-vector=v1, conformance-vector-group=v1,
        vector-set=v1, declared-item=v1, item-name=v1, tree=v1,
        test=v1, edge=v1, verifies-edge=v1, edge-source=v1,
    },
    documents#{tree-edge=v1, vector-file=v1, tree-finding=v1},
    findings#{spot=v1},
    files#{path=v1},
    text#{span=v1, code-span=v1},
    #{tree-evidence=v1, tree-outcome=v1, verified-vector=v1},
}

When a tree T has evidence, T has, for a set S of declared items of T,
one tree finding of the class `unverified-vector` for each group of
conformance vectors of the vector set that a declared item in S has in
T, when that group has at least one conformance vector that says a
vector, that group is not verified in the evidence for T, and each test
of T that is the source of a `verifies` edge whose cited item is that
group or the vector set of that group has an outcome in the evidence
for T. A tree
that has no evidence has no tree finding of the class `unverified-vector`
for any set of its declared items. The subject of the finding is the
name of the item of the vector set of the group of conformance vectors,
then `[`, then the name of the group of conformance vectors, then `]`.
The spot of the finding is the valid path of the vector file of that
item alone, with no span.

## 4. Requirements

### 4.1 Default recognitions

@req recognise-junit-reports=v1
@cites {
    packs#{
        valid-descriptor=v1, test-runner=v1, runner-settings=v1,
        adapter-call=v1,
    },
    ontology#{parameter=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{runner-data=v1, default-recognition=v1},
}

When a conforming program gives the default recognition of a report
content for a test runner of a valid descriptor that has a match table,
under a valid binding of `runner-settings` for that test runner and
when the data of the runner is valid, the conforming program must give
exactly one result, and only "recognised" or "not recognised": the
default recognition of that report content for that test runner under
that binding.

### 4.2 The results of readings

@req give-reading-results=v1
@cites {
    documents#{file-readers=v1},
    ontology#{tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{report-file=v1, import=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, when a conforming program
gives, under that binding, the result of the reading of a report file
of an import, the conforming program must give exactly one result, and
only "bound" or "unreadable": the result of that reading under that
binding.

### 4.3 The test results of readings

@req give-reading-test-results=v1
@cites {
    documents#{file-readers=v1},
    ontology#{tree=v1, test-evidence=v1, parameter=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{report-file=v1, import=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, when, with the result "bound"
of the reading of a report file of an import under that binding, a
conforming program gives the test results of that reading, it must give
each test result of that reading under that binding once, in their
order, with its name, its status, and its file, its line, and its
duration when it has them, and no other test result of that reading.

### 4.4 The result links of readings

@req give-reading-result-links=v1
@cites {
    documents#{file-readers=v1},
    ontology#{tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{report-file=v1, import=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, when the reading of a report
file of an import under that binding has the result "bound" and a
conforming program gives the result links of that reading, the
conforming program must give each result link of that reading under
that binding once, and no other result link of that reading.

### 4.5 No values of readings that do not bind

@req omit-reading-values=v1
@cites {
    documents#{file-readers=v1},
    ontology#{tree=v1, test-evidence=v1, parameter=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{report-file=v1, import=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, a conforming program must give
no test results and no result links of the reading of a report file of
an import under that binding when the result of that reading under that
binding is not "bound".

### 4.6 The requests of readings

@req give-reading-requests=v1
@cites {
    documents#{file-readers=v1},
    ontology#{tree=v1, parameter=v1},
    packs#{adapter-request=v1, adapter-call=v1, test-entry=v1},
    conformance#{conforming-program=v1},
    #{report-file=v1, import=v1, reading-entry=v1, reading-of-a-report-file=v1},
}

Under a valid binding of `file-readers`, when a conforming program makes
a call of the function bind of an adapter for the reading of a report
file of an import under that binding, the conforming program must make
that call with the request that the atom `reading-of-a-report-file`
gives under that binding, with the test entries of that reading under
that binding and no other test entry, and with the test entry ids of
these test entries as the test entry ids of the call.

### 4.7 Bytes only from the report content

@req read-only-report-content=v1
@cites {
    w3c/rec-xml-20081126,
    packs#{adapter-call=v1},
    conformance#{conforming-program=v1},
    text#{byte=v1},
    #{default-recognition=v1, default-reader-result=v1},
}

For a default recognition or a default reading of a report content, a
conforming program must take the XML document only from the bytes of
that report content. For a default recognition or a default reading of a
report content, a conforming program must take nothing from a file or
from a resource of a network that the report content names.

### 4.8 Readings that end

@req end-report-readings=v1
@cites {
    conformance#{conforming-program=v1},
    #{reading-of-a-report-file=v1},
}

A conforming program must end each reading of a report file that it
makes.

### 4.9 The evidence for each tree

@req take-evidence-for-own-tree=v1
@cites {
    ontology#{tree=v1},
    conformance#{conforming-program=v1},
    #{import=v1, tree-evidence=v1},
}

A conforming program must count an import in the evidence for a tree
only when that import is given for that tree.

### 4.10 Outcomes

@req give-test-outcomes=v1
@cites {
    documents#{file-readers=v1},
    ontology#{test=v1, tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{import=v1, tree-evidence=v1, import-outcome=v1, tree-outcome=v1},
}

Under a valid binding of `file-readers`, when a conforming program
gives, under that binding, the outcome of a test of a tree in an import
of that tree, the conforming program must give exactly one outcome, and
only "passed", "failed", or "not run": the outcome of that test in that
import under that binding. Under a valid binding of `file-readers`,
when a conforming program gives, under that binding, the outcome of a
test of a tree in the evidence for that tree, the conforming program
must give exactly one outcome, and only "passed", "failed", or "not
run": the outcome of that test in that evidence under that binding.

### 4.11 The sources of outcomes

@req give-outcome-sources=v1
@cites {
    documents#{file-readers=v1},
    ontology#{test=v1, tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    #{tree-evidence=v1, tree-outcome=v1, outcome-source=v1},
}

Under a valid binding of `file-readers`, when a conforming program
gives, under that binding, the outcome of a test of a tree in the
evidence for that tree, the conforming program must give with that
outcome each source of that outcome under that binding once, and no
other source.

### 4.12 The sources of kept promises

@req give-promise-sources=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        tree-edge=v1,
    },
    object-store#{tree-object-store=v1},
    ontology#{
        promise=v1, verifies-edge=v1, edge-source=v1, test=v1, tree=v1,
        parameter=v1,
    },
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{tree-evidence=v1, tree-outcome=v1, outcome-source=v1},
}

Under a valid binding of `file-readers`, a valid binding of
`vector-paths`, a binding of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid", a
valid object store of the tree, and a valid `kept-object-set`, when a
conforming program gives, under these bindings, whether a `verifies`
promise is kept in a tree that has evidence, for each test that, under
these bindings, is the source of an edge of that tree that is such an
edge for that promise as the term `promise` of the Ontology states, the
conforming program must give once for that test, with what the
conforming program gives for whether that promise is kept in that tree,
the outcome of that test in the evidence for that tree under these
bindings, which is "passed", "failed", or "not run", and each source of
that outcome under these bindings once. Under a valid binding of
`file-readers`, a valid binding of `vector-paths`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid object store of the tree,
and a valid `kept-object-set`, when a conforming program gives, under
these bindings, whether a `verifies` promise is kept in a tree that has
evidence, the conforming program must give, with what the conforming
program gives for whether that promise is kept in that tree, no outcome
and no source for any test that, under these bindings, is not the source
of an edge of that tree that is such an edge for that promise as the
term `promise` of the Ontology states.

### 4.13 Findings of the classes `never-ran`, `failed`, and `ambiguous-result`

@req give-evidence-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        tree-finding=v1,
    },
    object-store#{tree-object-store=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{
        tree-evidence=v1, never-ran-finding=v1, failed-finding=v1,
        ambiguous-result-finding=v1,
    },
}

Under a valid binding of `file-readers`, a valid binding of
`vector-paths`, a binding of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid", a
valid object store of the tree, and a valid `kept-object-set`, when a
conforming program gives, under these bindings, the findings of a tree
of one of the classes `never-ran`, `failed`, and `ambiguous-result`,
which rest on the evidence for that tree, it must give each tree finding
of that class that the tree has under these bindings once, and no other
finding of that class.

### 4.14 Findings of the class `unverified-vector`

@req give-unverified-vector-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        tree-finding=v1,
    },
    object-store#{tree-object-store=v1},
    ontology#{declared-item=v1, finding-class=v1, tree=v1, parameter=v1},
    conformance#{conforming-program=v1, input=v1},
    text#{result=v1},
    #{tree-evidence=v1, unverified-vector-finding=v1},
}

Under a valid binding of `file-readers`, a valid binding of
`vector-paths`, a binding of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid", a
valid object store of the tree, and a valid `kept-object-set`, when a
conforming program gives, under these bindings, the findings of a tree
of the class `unverified-vector`, which rest on the evidence for that
tree, it must take a set S of declared items of that tree as an input,
and it must give each tree finding of that class that the tree has for S
under these bindings once, and no other finding of that class.

### 4.15 No kept import in a run with a read error

@req write-no-import-after-read-error=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1, input=v1},
    files#{folder=v1, folder-tree=v1},
    ontology#{tree=v1},
    text#{code-span=v1},
    #{import=v1},
}

In a run in which content of a file or a folder is a part that an input
lacks under the term `input` of Conformance because a conforming program
could not take that content, that conforming program must keep no import
of that run for a later run, neither in the folder `.sinter/local/` of
the folder tree of a working tree nor anywhere else.

## 5. Conformance

A program conforms to this design when it is a
[conforming program](sinter:conformance#conforming-program=v1) of this design.

The vectors of this design are in the file
[`evidence.test-vectors.jsonl`](evidence.test-vectors.jsonl), in the
same folder as this design. The file is a test-vector set, as the
specification [`test-vectors`](sinter:data-forms#test-vectors=v1) of
Data forms gives it. A vector is an input and what a conforming program
gives for it. Each vector follows from the requirements and adds nothing
to them. The vectors are in four groups: `recognitions`, `readings`,
`outcomes`, and `findings`. Each subsection below gives the forms of one
group, as the term
[`group-form-list`](sinter:data-forms#group-form-list=v1) gives those
forms. No vector follows from the requirements `give-reading-requests`,
`read-only-report-content`, `end-report-readings`,
`take-evidence-for-own-tree`, `give-promise-sources`, and
`write-no-import-after-read-error`.

Each requirement from which vectors follow applies only when a program
gives the thing that the requirement names, such as the result of a
reading. So a vector binds a program only to what the program gives for
the input.

### 5.1 Recognitions

@schema recognition-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1},
    text#{
        text=v1, character=v1, byte-sequence=v1, utf-8-encoding=v1,
        result=v1, code-span=v1,
    },
    data-forms#{
        hex-text=v1, toml-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    packs#{
        test-runner=v1, runner-setting=v1, runner-settings=v1,
        runner-setting-value=v1, adapter-call=v1,
    },
    ontology#{parameter=v1},
    #{
        report-file=v1, runner-data=v1, default-recognition=v1,
        recognise-junit-reports=v1,
    },
}

The group `recognitions` has the vectors of the requirement
`recognise-junit-reports`. Each vector gives a report content and the
data of a test runner, and, when the data of the runner is valid, the
default recognition. The binding of `runner-settings` of each vector is
valid: each runner setting has the type of its value in `settings`.
Each vector holds when the program reaches no limit of its own. The
group uses no need, so these forms give no need names.

The JSON values, objects, members, arrays, strings, numbers, and the
literal names `true` and `false` of this schema are as RFC 8259 defines
them. Inside the members `input`, `result`, and `values`, the JSON
values have these forms:

- A text, such as a result, a name, or a test entry id, is a JSON string
  whose characters are the characters of the text, in order.
- A byte sequence, such as a report content, is a JSON string when the
  byte sequence is the UTF-8 encoding of a text: the JSON string of that
  text. Otherwise, the byte sequence is a JSON object with one member,
  `bytes`, whose value is the [hex text](sinter:data-forms#hex-text=v1)
  of the byte sequence, as a JSON string.
- A TOML value is a JSON value of the same kind. A TOML string is a JSON
  string. A TOML boolean is the literal name `true` for true or `false`
  for false. A TOML integer is a JSON number of the same integer. A TOML
  array is a JSON array of the JSON values of its elements, in order. A
  TOML table is a JSON object with one member for each of its keys.

The members of a vector line have these forms:

- `input`: a JSON object with the members `match`, `settings`, and
  `report`. The member `match` is the match table of the test runner, a
  TOML table. The member `settings` is a JSON object with one member for
  each runner setting of the test runner. For each runner setting of the
  test runner, the key of the member for that runner setting is the name
  of that runner setting, and the value of that member is the value of
  that runner setting under the binding of `runner-settings`, a TOML
  value. The member `report` is the report content, a byte sequence.
- `result`: "recognised" or "not recognised": the default recognition
  of the report content for the test runner, when the data of the
  runner is valid. A vector whose data of the runner is not valid has
  no member `result`.
- `values`: the empty JSON object, `{}`. When the vector has a member
  `result`, `values` stands for no value other than the default
  recognition. When the vector has no member `result`, `values` stands
  for reporting that the data of the runner is not valid and where, and
  for giving neither "recognised" nor "not recognised".

When the vector has a member `result` and a conforming program gives
the default recognition of the report content of the input for the test
runner of the input, the conforming program gives the result that
`result` gives, and no other result. When the vector has no member
`result`, the data of the runner of the input is not valid, and a
conforming program reports that the data of the runner is not valid and
where, and gives neither "recognised" nor "not recognised".

```
{"form":"#recognition-vector=v1","group":"recognitions","input":{"match":{"path":["name"]},"report":"<testsuites name=\"vitest tests\"><testsuite name=\"a\"/></testsuites>","settings":{"recognise":["testsuites@name=vitest tests"]}},"note":"the attribute name of the root element has the value that the member gives","result":"recognised","values":{}}
```

### 5.2 Readings

@schema reading-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1},
    text#{
        text=v1, byte-sequence=v1, whole-number=v1, code-point-order=v1,
        result=v1, code-span=v1,
    },
    data-forms#{
        toml-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    ontology#{tree=v1, test-evidence=v1, parameter=v1},
    packs#{
        test-runner=v1, runner-setting=v1, runner-settings=v1,
        test-entry=v1, test-name=v1, test-node=v1, adapter-call=v1,
    },
    #{
        recognition-vector=v1, report-file=v1, import=v1,
        runner-data=v1, case-result=v1, default-reader-result=v1,
        reading-of-a-report-file=v1, give-reading-results=v1,
        give-reading-test-results=v1, give-reading-result-links=v1,
        omit-reading-values=v1,
    },
}

The group `readings` has the vectors of the requirements
`give-reading-results`, `give-reading-test-results`,
`give-reading-result-links`, and `omit-reading-values`, for test runners
with a match table. Each vector gives a report content, the data of a
test runner, and test entries, and the default reading: its result, its
test results, and its result links. The binding of `file-readers` is
valid. A conforming program of the design Identifiers gives the result
"valid" for the binding of `external-namespaces`. The binding of `runner-settings` is valid: each runner setting has the
type of its value in `settings`. Each vector holds when the program
reaches no limit of its own. The group uses no need, so these forms
give no need names.

The JSON values, objects, members, arrays, strings, numbers, and the
literal names `true` and `false` of this schema are as RFC 8259 defines
them. Inside the members `input`, `result`, and `values`, a text, a byte
sequence, and a TOML value have the forms that `recognition-vector`
gives. Inside the members `input`, `result`, and `values`, a name path
and a test entry have these forms:

- A name path is a JSON array with one JSON array for each name, in
  their order. The array of a name has one JSON object for each piece,
  in their order: `{"text": ...}` for a text piece and
  `{"placeholder": ...}` for a placeholder, with the text of the piece
  as a JSON string.
- A test entry is a JSON object with the members `id`, `path`, `line`,
  `eline`, `suite`, and `names`. The member `id` is the test entry id of
  the test entry. The member `path` is the path of the test entry. The
  member `line` is the first line of the test entry. The member `eline`
  is the last line of the test entry. The member `suite` is true for the
  kind test suite and false for the kind test case. The member `names`
  is the name path of the test entry. The test labels of the test entry
  are empty.

The members of a vector line have these forms:

- `input`: a JSON object with the members `match`, `settings`, `report`,
  and `tests`. The members `match`, `settings`, and `report` are as in
  `recognition-vector`. The member `tests` is a JSON array of the test
  entries, each a test entry, in the code point order of their test
  entry ids.
- `result`: "bound" or "unreadable": the result of the reading of a
  report file that has that report content and whose test runner has
  that match table and those runner settings, when the data of the
  runner is valid and the test entries of that reading, under the
  binding of `file-readers`, are those of `tests`. A vector whose data
  of the runner is not valid has no member `result`.
- `values`: with "bound", a JSON object with the members `results` and
  `links`. `results` is a JSON array with one JSON object for each test
  result, in their order. Each JSON object in `results` has the member
  `name`, which is the name of the test result, and the member `status`,
  which is the status of the test result. Each JSON object in `results`
  also has the member `file`, which is the file of the test result, only
  when the test result has a file. Each JSON object in `results` also
  has the member `line`, which is the line of the test result, only when
  the test result has a line. Each JSON object in `results` also has the
  member `ms`, which is the duration of the test result in whole
  milliseconds, only when the test result has a duration. `links` is a
  JSON array with one JSON array of two members for each result link.
  The two members of each JSON array in `links` are the number of the
  test result and the test entry id of the test entry. The number of a
  test result is 1 more than the number of the test results before that
  test result. The JSON arrays in `links` stand in increasing order of
  the number of the test result, then in the code point order of the
  test entry id. With "unreadable", or when the vector has no member
  `result`, `values` is the empty JSON object, `{}`.

When the vector has a member `result` and a conforming program gives
the result of that reading, the conforming program gives the result
that `result` gives, and no other result. When the vector has a member
`result` and a conforming program gives the test results of the
reading, the conforming program gives the test results that `results`
gives, in their order, with the values that `results` gives, and no
other test result. When the vector has a member `result` and a
conforming program gives the result links of the reading, the
conforming program gives the result links that `links` gives, and no
other result link. When `values` is `{}` and the vector has a member
`result`, a conforming program gives no test result of that reading and
no result link of that reading. When the vector has no member `result`,
the data of the runner of the input is not valid, and a conforming
program reports that the data of the runner is not valid and where, and
gives no result of that reading, no test result of that reading, and no
result link of that reading.

```
{"form":"#reading-vector=v1","group":"readings","input":{"match":{"file":["classname"],"path":["name"],"placeholders":["%[sdifjoOc]","[$][A-Za-z_][A-Za-z0-9_.]*"],"suite-separator":" > ","test-separator":" > "},"report":"<testsuites name=\"vitest tests\"><testsuite name=\"src/math.test.ts\"><testcase classname=\"src/math.test.ts\" name=\"outer &gt; each 1 + 2 = 3\" time=\"0.001\"/></testsuite></testsuites>","settings":{"recognise":["testsuites@name=vitest tests"]},"tests":[{"eline":9,"id":"src/math.test.ts#1","line":1,"names":[[{"text":"outer"}]],"path":"src/math.test.ts","suite":true},{"eline":4,"id":"src/math.test.ts#2","line":2,"names":[[{"text":"outer"}],[{"text":"each %i + %i = %i"}]],"path":"src/math.test.ts","suite":false}]},"note":"each %i becomes a placeholder, and the file matches the path","result":"bound","values":{"links":[[1,"src/math.test.ts#2"]],"results":[{"file":"src/math.test.ts","ms":1,"name":"outer > each 1 + 2 = 3","status":"pass"}]}}
```

### 5.3 Outcomes

@schema outcome-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1},
    text#{text=v1, whole-number=v1, result=v1, code-span=v1},
    files#{path=v1},
    data-forms#{
        hash=v1, vector-line=v1, group-form-list=v1, vector-meaning=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, vector-paths=v1, kept-object-set=v1},
    object-store#{tree-object-store=v1},
    ontology#{
        test=v1, test-evidence=v1, tree=v1, finding-class=v1,
        parameter=v1,
    },
    packs#{
        runner-settings=v1, test-runner=v1, test-name=v1,
        test-node=v1, test-entry=v1,
    },
    #{
        recognition-vector=v1, report-file=v1, import=v1,
        tree-evidence=v1, case-result=v1, reading-of-a-report-file=v1,
        linked-test=v1, held-test=v1, narrowing-of-an-import=v1,
        named-test=v1, import-outcome=v1, tree-outcome=v1,
        outcome-source=v1, ambiguous-result-finding=v1,
        give-test-outcomes=v1, give-outcome-sources=v1,
        give-evidence-findings=v1,
    },
}

The group `outcomes` has the vectors of the requirements
`give-test-outcomes` and `give-outcome-sources`, and, for the class
`ambiguous-result`, of the requirement `give-evidence-findings`. Each
vector gives tests of a tree, the evidence for that tree, and one test.
When the test has an outcome in the evidence, the vector also
gives the outcome of that test in the evidence, with the sources of
that outcome, and whether the tree has a finding of the class
`ambiguous-result` for that test. The readings of the report files are
given by the results, the test results, and the result links of those
readings. The tests are given by their valid paths, their names, their
kinds, and the tests that hold them. The tree of each vector has no
other test that a test result names. The binding of `file-readers` is
valid. The binding of `vector-paths` is valid. The object store of the
tree is valid, and the kept object set (`kept-object-set`) is valid. A
conforming program of the design Identifiers gives the result "valid"
for the binding of `external-namespaces`. The binding of
`runner-settings` for each test runner is valid. Each vector holds when
the program reaches no limit of its own. The group uses no need, so
these forms give no need names.

The JSON values, objects, members, arrays, strings, numbers, and the
literal names `true` and `false` of this schema are as RFC 8259 defines
them. Inside the members `input`, `result`, and `values`, a text has the
form that `recognition-vector` gives.

The members of a vector line have these forms:

- `input`: a JSON object with the members `tests`, `imports`, and
  `test`.
  - `tests` is a JSON array of tests of the tree. A test is a JSON
    object with the members `path`, `name`, `suite`, and `suites`. The
    member `path` is the valid path of the file of that test. The member
    `name` is the name of that test: a JSON array with a JSON string for
    each of the names in the name of that test, in their order. Each
    JSON string in the member `name` is for a name of one text piece
    with the text of that JSON string. The member `suite` is true when
    the test node of that test is a test suite, and false when that test
    node is a test case. The member `suites` is a JSON array of the
    indexes in `tests`, from 0, of the tests that hold that test.
  - `imports` is a JSON array of the imports of the evidence for the
    tree. An import is a JSON object with the member `files` and, when
    the narrowing of that import is not empty, the member `narrowing`.
    The member `files` is a JSON array of the report files of that
    import, in their order. When the narrowing of that import is not
    empty, the member `narrowing` is a JSON array of the triples of that
    narrowing. Each triple in the member `narrowing` is a JSON array of
    the number of a report file, the number of a test result, and the
    index in `tests` of a test. A report file is a JSON object with the
    members `hash` and `reading`, and, when the result of the reading of
    that report file is "bound", the member `results`. The member `hash`
    is the hash of the report content of that report file, a text. The
    member `reading` is the result of the reading of that report file,
    "bound" or "unreadable". When the result of the reading of that
    report file is "bound", the member `results` is a JSON array of the
    test results of that reading, in their order. A test result is a
    JSON object with the members `name` and `status`, the member `file`
    only when that test result has a file, and the member `links`. The
    member `name` is the name of that test result. The member `status`
    is the status of that test result. When that test result has a file,
    the member `file` is that file. The member `links` is a JSON array
    with, for each result link of that test result, the index in `tests`
    of one test whose path, name, and kind are the path, name, and kind
    of the test entry of that result link.
  - `test` is the index in `tests` of the test whose outcome the vector
    gives.
- `result`: "passed", "failed", or "not run": the outcome of that test
  in the evidence for the tree, when that test has an outcome in the
  evidence for the tree. A vector in which that test has no outcome in
  the evidence for the tree has no member `result`.
- `values`: when that test has an outcome in the evidence for the tree,
  a JSON object with the members `ambiguous` and `sources`. The member
  `ambiguous` is true when the tree has a finding of the class
  `ambiguous-result` for that test, and false when the tree has none.
  The member `sources` is a JSON array of the sources of the outcome,
  with one source for each import in which that test has an outcome. In
  the vector, the elements of `sources` stand in the order of `imports`.
  A source is a JSON object
  with the members `files`, `narrowing`, `outcome`, and `results`. The
  member `files` is a JSON array with a JSON object for each report file
  of the import, in the order of the report files of the import. Each
  JSON object in the member `files` has the members `hash` and
  `reading`. The member `narrowing` is a JSON array of the triples of
  the source, in increasing order of the number of the report file, then
  of the number of the test result, then of the index in `tests`. Each
  triple in the member `narrowing` is in the form of the input. The
  member `outcome` is the outcome of the test in that import. The member
  `results` is a JSON array of the test results of the source, in their
  order. Each test result in the member `results` is a JSON object with
  the members `report-number`, `report`, `n`, `name`, and `status`. The
  member `report-number` is the number of the report file of that test
  result. The member `report` is the hash of the report content of that
  report file. The member `n` is the number of that test result. When
  that test has no outcome in the evidence for the tree, `values` is
  the empty JSON object, `{}`.

When the vector has a member `result` and a conforming program gives the
outcome of that test in the evidence for the tree, it gives the outcome
that `result` gives, and no other outcome. With that outcome, that
conforming program gives the sources that `sources` gives, and no other
source. The order of the sources, and of the triples of a source, is not
part of what that conforming program gives. When the vector has a member
`result` and a conforming program gives the findings of the class
`ambiguous-result` of the tree, that conforming program gives one
finding of that class for that test when `ambiguous` is true, and none
for that test when `ambiguous` is false. When the vector has no member
`result`, an import of the input has a narrowing that is not valid and
that test has no outcome in the evidence for the tree, and a conforming
program reports the narrowing and where, and gives no outcome, no
source, and no finding of the class `ambiguous-result` for that import.

```
{"form":"#outcome-vector=v1","group":"outcomes","input":{"imports":[{"files":[{"hash":"0000000000000000000000000000000000000000000000000000000000000001","reading":"bound","results":[{"links":[1],"name":"small","status":"pass"},{"links":[2],"name":"large","status":"pass"}]}]}],"test":0,"tests":[{"name":["limits"],"path":"t.ts","suite":true,"suites":[]},{"name":["limits","small"],"path":"t.ts","suite":false,"suites":[0]},{"name":["limits","large"],"path":"t.ts","suite":false,"suites":[0]}]},"note":"a test that holds tests passed: each test that it holds passed","result":"passed","values":{"ambiguous":false,"sources":[{"files":[{"hash":"0000000000000000000000000000000000000000000000000000000000000001","reading":"bound"}],"narrowing":[],"outcome":"passed","results":[{"n":1,"name":"small","report":"0000000000000000000000000000000000000000000000000000000000000001","report-number":1,"status":"pass"},{"n":2,"name":"large","report":"0000000000000000000000000000000000000000000000000000000000000001","report-number":1,"status":"pass"}]}]}}
```

### 5.4 Findings

@schema finding-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, input=v1, requirement=v1},
    text#{text=v1, code-point-order=v1, result=v1, code-span=v1},
    data-forms#{vector-line=v1, group-form-list=v1, vector-meaning=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, citation-entry=v1,
    },
    documents#{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        tree-edge=v1, origin-position=v1, position-subject=v1,
        vector-file=v1,
    },
    object-store#{tree-object-store=v1},
    ontology#{
        tree=v1, test=v1, edge=v1, verifies-edge=v1, edge-source=v1,
        schema=v1, declared-item=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1, item-name=v1,
        finding-class=v1, parameter=v1,
    },
    packs#{runner-settings=v1, test-runner=v1},
    #{
        recognition-vector=v1, tree-evidence=v1, tree-outcome=v1,
        reading-of-a-report-file=v1, never-ran-finding=v1,
        failed-finding=v1, unverified-vector-finding=v1,
        give-evidence-findings=v1, give-unverified-vector-findings=v1,
    },
}

The group `findings` has the vectors of the requirement
`give-evidence-findings` for the classes `never-ran` and `failed`, and
of the requirement `give-unverified-vector-findings` for the class
`unverified-vector`. Each vector gives, as its input, the outcomes of
tests in the evidence for a tree, the edges of the kind `verifies` of
the tree, the conformance vectors of vector sets of the tree, and, for a
set S of declared items of the tree, whether the item of each vector set
is in S. For that input, the vector gives the findings of the classes
`never-ran` and `failed` that the tree has and the findings of the class
`unverified-vector` that the tree has for S. The outcome of each test in
the evidence for the tree, when that test has one, is given as an input.
The tree of each vector has no other edge of the kind `verifies` and no
other vector set. The binding of `file-readers` is valid. The binding of
`vector-paths` is valid. The object store of the tree is valid, and the
kept object set (`kept-object-set`) is valid. A conforming program of
the design Identifiers gives the result "valid" for the binding of
`external-namespaces`. The binding of `runner-settings` for each test
runner is valid. Each vector holds when the program reaches no limit of
its own. Each vector of the group has
the member `values`. No vector of the group has the member `result`.
These forms name no question for `result`. The group uses no need, so
these forms give no need names.

The JSON values, objects, members, arrays, strings, numbers, and the
literal names `true` and `false` of this schema are as RFC 8259 defines
them. Inside the members `input` and `values`, a text has the form that
`recognition-vector` gives.

The members of a vector line have these forms:

- `input`: a JSON object with the members `evidence`, `tests`, `edges`,
  and `sets`.
  - `evidence` is true when the tree has evidence, and false when the
    tree has none.
  - `tests` is a JSON array of tests of the tree. Each test in `tests`
    is a JSON object. That object has the member `outcome` when, and
    only when, that test has an outcome in the evidence for the tree,
    and that object has no other member. The member `outcome` is that
    outcome: "passed", "failed", or "not run".
  - `edges` is a JSON array of the edges of the kind `verifies` of the
    tree. An edge is a JSON object with the members `source`, `subject`,
    and `cited`. The member `source` is the index in `tests`, from 0, of
    the source of that edge, a test. The member `subject` is the
    position subject of the origin position of the citation entry of
    that edge, a text. The member `cited` is the cited item of that
    edge: a JSON object with the member `kind`. For an item of the kind
    requirement, the member `kind` is `requirement`. For a schema, the
    member `kind` is `schema`. For a group of conformance vectors, the
    member `kind` is `group`, and `cited` has the members `set` and
    `group`. For that group of conformance vectors, the member `set` is
    the name of the item of the vector set of that group. For that group
    of conformance vectors, the member `group` is the name of that
    group. For a vector set, the member `kind` is `set`, and `cited` has
    the member `set`. For an item of another kind, the member `kind` is
    `other`. When that edge has no cited item, the member `kind` is
    `none`.
  - `sets` is a JSON array of the vector sets of the tree. A vector set
    is a JSON object with the members `name`, `in-force`, and `vectors`.
    The member `name` is the name of the item of that vector set. The
    member `in-force` is true when that item is in the set S of the
    input, and false when that item is not in the set S of the input.
    The member `vectors` is a JSON array of the conformance vectors of
    that vector set. Each conformance vector in the member `vectors` is
    a JSON object with the members `group` and `says`. The member
    `group` is the name of the group of that conformance vector. The
    member `says` is true when that conformance vector says a vector,
    and false when that conformance vector says no vector.
- `values`: a JSON object with one member, `findings`. The member
  `findings` is a JSON array of the findings of the classes `never-ran`
  and `failed` that the tree has and the findings of the class
  `unverified-vector` that the tree has for the set S of the input, in
  the code point order of the class and then of the subject. Each
  finding in the member `findings` is a JSON array of the slug of the
  class of that finding and the subject of that finding.

When a conforming program gives the findings of one of these classes of
the tree, taking the set S of the input as the input of that conforming
program when the class is `unverified-vector`, that conforming program
gives, for each element of `findings` with that class, one finding of
that class with the subject of that element, and no other finding of
that class.

```
{"form":"#finding-vector=v1","group":"findings","input":{"edges":[{"cited":{"group":"offsets","kind":"group","set":"data-forms#toml"},"source":0,"subject":"t.py@L1C3"}],"evidence":true,"sets":[{"in-force":true,"name":"data-forms#toml","vectors":[{"group":"offsets","says":true},{"group":"offsets","says":true},{"group":"keys","says":true},{"group":"keys","says":false}]}],"tests":[{"outcome":"passed"}]},"note":"a pass of a test that cites a group verifies that group; the group keys has a vector that says a vector, and no passing test cites it, so it gives an unverified-vector finding","values":{"findings":[["unverified-vector","data-forms#toml[keys]"]]}}
```
