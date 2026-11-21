<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Language packs
@design packs=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
@cites posix/2024
@cites tree-sitter/language-format
@cites tree-sitter/abi-versions
@cites tree-sitter/query-language
@cites wasm-core/2.0
@cites ecma/262-2025
Specifies language packs, with their files, pack paths, and pack hashes;
descriptors, with pack names, release numbers, comment sigils, foreign
tag words, name separators, grammars, test runners, and runner settings;
usable grammars, query files, and valid packs;
the readings of texts with packs, with parse trees, parse failures,
comment nodes, definition nodes, decoration nodes, and test nodes, and
the names and test labels of test nodes; runner adapters, with the
instances that run their code, the requests, and the results of their
calls; and requirements for conforming programs that validate packs and
adapters, give pack hashes, read descriptors, read texts with packs,
call adapters, and keep the code of a pack from what lies outside it.

A language pack, or pack, holds the support for one programming
language: the grammars that parse the files of the programming language, the query files that find
the comments, the definitions, and the tests in these files, a
descriptor, license texts, and runner adapters. A pack is a folder of
files. Its pack hash is the SHA-256 hash of a listing of its files, so
the pack hash names the content of the pack. The descriptor is the
content of the file `pack.toml`: a TOML document that names the pack and
its release, and lists its grammars, its comment sigils, its foreign tag
words, and its test runners.

A grammar is a tree-sitter grammar, compiled to WebAssembly. A program
reads a text with a pack as follows. First, the program parses the text
with the grammar that the name of the file selects. Next, the program
runs the query files of that grammar over the parse tree. Then the
program gives the comments, the definitions, the decorations, and the
test nodes of the text. A runner adapter is a WebAssembly module that
reads the report files of one test runner and binds their test results
to test entries, which stand for test nodes. A program calls an adapter
with a request and a report content, such as the content of a report
file. The program then reads the response of the adapter. The code of a
grammar and of an adapter can read no file, write no file and not the
output of the process, use no network, read no clock, and start no
process.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405.

From Text and notation, the design takes characters, code points, texts,
places, boundaries, runs, and code point order; bytes, byte sequences,
valid UTF-8, the text of a byte sequence, and UTF-8 encodings; bodies,
line feeds, lines, line numbers, positions, and spans; whole numbers and
decimal numerals; the notation of productions; and conforming programs,
inputs, and results. From Identifiers, the design takes tag words. From
Files and paths, the design takes folder trees, folders, regular files,
symbolic links, and files of another kind, with their contents and
attributes; valid paths and the files that they name; valid globs and
the valid paths that fit them; the bytes that a program takes from a
file; the system of a program; and file objects, folder tree objects,
and stored folder trees. From Data forms, the design takes TOML
documents, their root tables, the texts of TOML keys, and TOML values;
hashes and the hash form; hex texts; JSON values, key order, their
canonical byte sequences, and the JSON values of byte sequences;
indexes; and test-vector sets, with the forms of a group, needs and need
names, and what a vector line states. From the Ontology, the design
takes schemas, tests, test results, and parameters and their bindings.

From RFC 8259, the design takes JSON texts. An adapter writes its
response as a JSON text. The files that hold the conformance vectors of
the design hold one JSON text on each line. From POSIX.1-2024, the
design takes the permissions and the appropriate privileges of a
process, and the portable filename character set. From tree-sitter, the
design takes the format of languages, with the parse trees that the
parsing of a language gives; and the query language, as tree-sitter's
documentation of the query language defines the query language, with
patterns, captures, predicates, quantifiers, and the matches of a query.
From the page on ABI versions of tree-sitter's documentation
(`docs/src/using-parsers/7-abi-versions.md`), the design takes the ABI
versions 13 to 15 of the format of languages. From the WebAssembly Core
Specification 2.0, the design takes modules, their validation, and their
binary format; imports, exports, functions and their types, memories,
tables, globals, instances, traps, and the execution of code. From
ECMA-262 2025, the design takes RegExp patterns, with the flag `u`, and
their matching.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [pack](sinter:#pack=v1) | a language pack: a folder tree, such as one that holds the grammars, the query files, the descriptor, the license texts, and the runner adapters of one programming language |
| pack root | the root of the folder tree of a pack |
| [file of a pack](sinter:#pack=v1) | a valid path, such as `queries/rust/tags.scm`, whose last file name names a regular file in the folder tree of the pack, and a content, which is the content of that regular file |
| [have a file](sinter:#pack=v1) | a pack has the file p when it has a file whose valid path is p |
| [code point order](sinter:text#code-point-order=v1) | the order of texts by the code points of their characters, place by place, in which a text A comes before each longer text that starts with A |
| [pack path](sinter:#pack-path=v1) | a valid path whose characters are each a printable ASCII character other than `\`, such as `grammars/rust.wasm` |
| [paths of a pack](sinter:#well-named-pack=v1) | the valid paths of the files of the pack, and each part of one of those valid paths from the start of that valid path to right before a `/`, such as `queries` and `queries/rust` for the file `queries/rust/tags.scm` |
| [ASCII case folding](sinter:#well-named-pack=v1) | the change of each letter from `A` to `Z` of a text to the same letter from `a` to `z`, with no change to any other character |
| [well named](sinter:#well-named-pack=v1) | a pack is well named when the entry name of each folder entry on the way to a regular file of the folder tree of the pack is the UTF-8 encoding of a file name, each path of the pack is a pack path, and no two paths of the pack are the same text after ASCII case folding |
| [pack listing](sinter:#pack-hash=v1) | the text with one line for each file of a well-named pack, in the code point order of the valid paths of the files: the hash of the content of the file, two spaces, the valid path of the file, and a line feed |
| [pack hash](sinter:#pack-hash=v1) | the hash of the UTF-8 encoding of the pack listing of a well-named pack |
| [use of a pack](sinter:#pack-use=v1) | an operation that a program makes to give, for a pack, whether the pack is well named, the valid paths of the files of the pack, the pack listing of the pack, the pack hash of the pack, whether the pack is valid, a value of the content of the file `pack.toml` of the pack as a descriptor, the result of a reading of a text with the pack, the content of one of the files of the pack, or the result of a call of the adapter of one of the test runners of the pack |
| [descriptor](sinter:#valid-pack=v1) | the content of the file `pack.toml` of a pack, which is a valid descriptor in a valid pack |
| [valid descriptor](sinter:#valid-descriptor=v1) | a byte sequence that is a TOML document whose root table holds the keys of a descriptor, each with a TOML value of the right form |
| [pack name](sinter:#pack-name=v1) | a text of lower-case ASCII letters, ASCII digits, and `-` that starts with a letter, with no `-` at the start or the end, and no two `-` side by side, such as `typescript`; the name of a pack and the name of a test runner are pack names |
| [grammar name](sinter:#grammar-name=v1) | a text of lower-case ASCII letters, ASCII digits, and `_` that starts with a letter, such as `ocaml_interface` |
| [release number](sinter:#release-number=v1) | the number of a release of a pack: three decimal numerals joined by `.`, such as `1.0.3` |
| [spec version](sinter:#spec-version=v1) | two decimal numerals joined by `.`, such as `1.0`, which name a version of the specifications of Sinter |
| [comment sigil](sinter:#comment-sigil=v1) | a text that, by a valid descriptor, opens a comment, closes a comment, or starts a line of a block comment after its first line, such as `//`, `/*`, `*/`, or `*` |
| [line sigil, block pair, inner sigil](sinter:#comment-sigil=v1) | the three kinds of comment sigil: a line sigil opens a comment that ends at the end of its line; a block pair is an opening sigil and a closing sigil; an inner sigil can start a line of a block comment after its first line |
| [foreign tag word](sinter:#foreign-tag-word=v1) | a text that matches the production `tag-word`, such as `@param`, and that, by a valid descriptor, the language of the pack, or a tool of that language, uses in comments with a meaning of its own |
| [name separator](sinter:#name-separator=v1) | a text, not empty, that a pack gives to join names into one text, such as `.` |
| [grammar of a descriptor](sinter:#descriptor-grammar=v1) | one table of the array `grammar` of a descriptor: a grammar name, a hash, a license, and file-name globs |
| [file-name glob](sinter:#descriptor-grammar=v1) | one of the valid globs of a grammar of a descriptor, such as `*.ts`, which the last file name of a valid path can fit |
| [file grammar](sinter:#file-grammar=v1) | the first grammar of a descriptor that has a file-name glob that the last file name of a valid path fits |
| [test runner](sinter:#test-runner=v1) | a program that runs tests and gives a test result for each test that it runs, and that writes report files, such as vitest or cargo-nextest; a valid descriptor describes its test runners |
| [adapter hash, adapter license](sinter:#test-runner=v1) | the hash that the descriptor gives for the adapter file of a test runner, and the license of that adapter, which a descriptor gives for a test runner that has an adapter of its own |
| [match table](sinter:#test-runner=v1) | the table of `match` in the table of a test runner of a valid descriptor, which a test runner has when it has no adapter hash |
| [runner setting](sinter:#runner-setting=v1) | a name and a default value, for a value that configuration can give for a test runner: a TOML string, a TOML boolean, or a TOML array of TOML strings |
| tree-sitter | a project that defines a format of languages compiled to WebAssembly, the parse trees that its parsing gives for a language and a text, and a query language that finds parts of parse trees |
| [WebAssembly module](sinter:#webassembly-module=v1) | a byte sequence that is a valid module in the binary format of the WebAssembly Core Specification 2.0 |
| [usable grammar](sinter:#usable-grammar=v1) | a WebAssembly module that gives, as the format of languages of tree-sitter defines, a language from the export `tree_sitter_<g>` of that WebAssembly module, with an ABI version from 13 to 15 and symbol names in valid UTF-8 |
| [ABI version](sinter:#usable-grammar=v1) | the whole number that a language in the format of tree-sitter gives as the version of that format |
| [query file](sinter:#query-file=v1) | a byte sequence that holds a tree-sitter query, of one of three kinds: comment, definition, and test |
| [pattern, capture, capture name, predicate, directive, quantifier](sinter:#query-language=v1) | the things of the query language of tree-sitter with these names: a query is a sequence of patterns; a pattern captures nodes under capture names, such as `@comment`; a predicate, such as `#eq?`, tests the texts of captured nodes, and a directive, such as `#set!`, sets a property; a quantifier says how many times a pattern captures under a capture name |
| [text predicate](sinter:#text-predicate=v1) | one of the ten predicates that a conforming program applies to the matches of the query language, such as `#eq?` or `#match?`, with the arguments of that predicate and the condition under which that predicate holds |
| [role name, role node](sinter:#joined-match=v1) | the capture name of a match that gives the kind of thing that the match finds, such as `comment` or `case`, and the node that the match captures under that capture name |
| [valid pack](sinter:#valid-pack=v1) | a pack that is well named, holds only folders and regular files, and has a valid descriptor; for each grammar of the descriptor, a usable grammar with the hash of the grammar, a valid `tags.scm`, and valid other query files; for each test runner with an adapter hash, an adapter file with that hash; and a file under `licenses/` |
| [parse text](sinter:#parse-tree=v1) | a text, with a line feed after the text when the text does not end with a line feed |
| [parse tree](sinter:#parse-tree=v1) | the tree of nodes that the parsing of tree-sitter gives for the language of a usable grammar and the UTF-8 encoding of a parse text, with the nodes of hidden symbols left out and the children of those nodes in the place of those nodes, when the start byte and the end byte of each node each count the bytes before a boundary of the parse text, each start byte is at most its end byte, and the runs of its nodes in the text nest in their parents and follow each other in order |
| [node](sinter:#parse-tree-order=v1) | a node of a parse tree: the root node of the parse tree, or a child of one of the nodes of the parse tree, such as a comment or a function |
| [node type](sinter:#node-type=v1) | the name of the symbol of a node, as a text, such as `line_comment` |
| [order of the parse tree](sinter:#parse-tree-order=v1) | the order of the nodes of a parse tree in which each node comes before its children, and the children of a node come in their order |
| [run of a node](sinter:#node-run=v1) | the run of the text that a node takes up, without a line feed that only the parse text has, and without the byte order mark of the text |
| [parse failure](sinter:#parse-failure=v1) | a text has a parse failure with a usable grammar when the text has no parse tree with that usable grammar, or when the root node of the parse tree of the text with that usable grammar has an error |
| [query match](sinter:#query-match=v1) | for a valid query file and a text whose parse tree has no error, a match of the query of the query file without the predicates of that query over that parse tree, as the query language defines the matches, in which each text predicate of the pattern of that match holds |
| [joined match](sinter:#joined-match=v1) | the query matches of one pattern that give one node the same role, taken as one match |
| [kept match](sinter:#joined-match=v1) | a joined match whose pattern comes first among the joined matches that give one node the same role |
| [comment node](sinter:#comment-node=v1) | the role node of a kept match of the query file of the kind comment |
| [tagged](sinter:#comment-node=v1) | a comment node is tagged when it can carry tags: a kept match captures it as `comment`, and no kept match captures it as `untagged` |
| [definition node](sinter:#definition-node=v1) | the role node of a kept match with the role name `definition` of the query file of the kind definition, such as a function, a type, a module, or a class |
| [name node, body node](sinter:#definition-node=v1) | a node that the kept match of a definition node captures as `name`, and a node that the kept match captures as `body`; when that kept match captures no `body` node, the definition node is its own body node |
| [decoration node](sinter:#decoration-node=v1) | the role node of a kept match with the role name `decoration` of the query file of the kind definition, such as a Rust attribute |
| [test node](sinter:#test-node=v1) | the role node of a kept match of the query file of the kind test, which, by the query file, is the code of one test of the file: of one unit, for a test case, or of a set of units that the code groups under one name, for a test suite |
| [test case, test suite](sinter:#test-node=v1) | the two kinds of test node: a test node is a test suite, such as a vitest `describe`, when one of its kept matches has the role name `suite`, or when it encloses a test node that has a kept match with the role name `case`; each other test node is a test case, such as a Rust function with `#[test]` |
| [enclose](sinter:#enclosed-node=v1) | a node A encloses a different node B when the run of A starts at or before the start of the run of B, the run of A ends at or after the end of the run of B, and B does not come before A in the order of the parse tree |
| [piece, text piece, placeholder](sinter:#test-name=v1) | a part of the own name of a test node, from a node that a kept match of the test node captures as `name` or as `placeholder`: a text piece is text as the text of the file writes it; a placeholder stands for the text that the test runner puts in the name when it runs the test |
| [name path](sinter:#test-name=v1) | the own names of the test suites that enclose a test node, outermost first, then the own name of the test node; by the query file, the name path is the name of the test of the test node, as the code writes that name |
| [test label](sinter:#test-label=v1) | a word, such as `each`, that a kept match of a test node gives the test node by the capture name `label.<word>`, such as for a test case that the test runner runs once for each row of a table |
| [result of a reading](sinter:#reading-result=v1) | the result of a reading of a text, as the text of a file at a valid path, with a valid pack: "no grammar", "parse failure", or "parsed" |
| [reading](sinter:#reading-of-a-text=v1) | the reading of a text, as the text of a file at a valid path, with a valid pack: its result, "no grammar", "parse failure", or "parsed"; with "parsed", the nodes of the text and their values |
| import, export, instance, trap, embedder | the things of the WebAssembly Core Specification 2.0 with these names |
| [instance of an adapter](sinter:#adapter-instance=v1) | a new instance of a WebAssembly module that a program makes with no import, in which code runs as the WebAssembly Core Specification 2.0 defines, with the program as the embedder; an instantiation or an invocation in the instance fails when that instantiation or invocation traps, or when the execution of its code, as the WebAssembly Core Specification 2.0 defines it, does not terminate |
| [choice of the program in a decision whether a pack is valid](sinter:#validate-packs=v1) | the result "invalid" for a pack in which the file of a grammar is a WebAssembly module with an import that the program does not provide, or in which a query file holds a pattern that, without the predicates of that pattern, matches no part of any parse tree that the language of the grammar of that query file can give |
| [adapter module](sinter:#adapter-module=v1) | a WebAssembly module that imports nothing and exports `memory`, `sinter_interface`, `sinter_alloc`, `sinter_recognise`, and `sinter_bind` with the types of the interface |
| [valid adapter](sinter:#valid-adapter=v1) | in one decision of a program, an adapter module that gives the version 1 of the interface: the decision runs, in a new instance of the module, only the instantiation and one invocation of `sinter_interface` |
| [adapter of a test runner](sinter:#valid-pack=v1) | the content of the file `adapters/<r>.wasm` of a valid pack, for the test runner `<r>` with an adapter hash |
| [binding of `runner-settings`](sinter:#runner-settings=v1) | a finite set of pairs that gives values for some of the runner settings of one test runner; each pair is a name, which is a text, and a TOML value |
| [value of a runner setting](sinter:#runner-setting-value=v1) | under a valid binding of `runner-settings`, the TOML value of the pair whose name is the name of the runner setting, or the default value of the runner setting when no pair has the name of the runner setting |
| [test entry](sinter:#test-entry=v1) | a test entry id, a path, a first and a last line, a kind, a name path, and test labels, which a call of the function bind gives an adapter for one test node |
| [request](sinter:#adapter-request=v1) | the canonical byte sequence of a request object: a JSON object with the version 1 of the interface, the test runner, the values of its runner settings, the report name, and, for bind, the root and the test entries |
| report file | a file that a test runner writes, such as a JUnit XML file |
| [report content](sinter:#adapter-call=v1) | the byte sequence that a program gives an adapter, unchanged, in a call, such as the content of a report file |
| [report name](sinter:#adapter-request=v1) | a text, such as the path of a report file as a person gave it, which the request of a call gives the adapter |
| [test result](sinter:ontology#test-evidence=v1) | what a test runner gives for one test that the test runner runs; by the adapter, each element of the value of `results` of the response of a call of bind is a test result that the report content holds, with the name and the status of the test result, and, when the test result has them, the file, the line, and the duration of the test result |
| [call](sinter:#adapter-call=v1) | a call of the function recognise or the function bind of a byte sequence as an adapter, with a request, a report content, and, for bind, the test entry ids of the call: the call fails when, in the decision of the program that the call uses, the byte sequence is not a valid adapter; otherwise the call runs in a new instance of an adapter and gives a response or fails |
| [response](sinter:#adapter-call=v1) | the bytes that a call of an adapter gives back |
| [adapter response](sinter:#adapter-response=v1) | a byte sequence that is a recognise response, a bind response, or an error response; a call whose response is no adapter response has the result "failed" |
| [JSON value of a response](sinter:#adapter-response=v1) | the JSON value of the response as a byte sequence, as Data forms defines the JSON value of a byte sequence |
| [result of a call](sinter:#call-result=v1) | "recognised", "not recognised", or "failed" for the function recognise; "bound" or "failed" for the function bind |
| [result object, binding object](sinter:#adapter-response=v1) | an object of the response of bind that gives one test result, with its name and its status, and an object that binds one test result to one test entry, with a reason |
| [schema](sinter:ontology#schema=v1) | a declared item whose declaration word is `@schema`; it gives the form of a thing that crosses the boundary of a conforming program: its layout and every constraint that is a property of the thing itself |
| [forms of a group](sinter:data-forms#group-form-list=v1) | five things that a schema that a specification declares under a name, or that a design declares under a name outside its specifications, gives for a group: the requirements of the group; what the value of `input` stands for, and its fixed form; the question that the value of `result` answers, the inputs that it is about, and the conditions under which the requirements oblige that result (the forms can name no question instead); what the value of `values` stands for, and its fixed form (the forms can give no fixed form for `values`); and the need names that the group uses, each with the need that it stands for |
| [need](sinter:data-forms#group-form-list=v1) | a condition on the environment in which a conforming program operates that a check of the vectors can be unable to make hold, such as that the file system stores a given entry name; the forms of a group give each need with a need name |
| [need name](sinter:data-forms#group-form-list=v1) | a text that matches the production `group-name`, such as `no-privilege`, that stands for a need; the member `needs` of a vector object holds texts of this form, and the forms of the group give the need that each of them stands for, if any |

## 2. Packs, descriptors, readings, and adapters

### 2.1 Packs and their files

A pack is a folder tree. The root of that folder tree is the pack root.
A file of the pack has a valid path, such as `grammars/rust.wasm`, whose
last file name names a regular file in the folder tree. The content of
that file of the pack is the content of that regular file. The paths of
the pack are the valid paths of the files of the pack and the paths of
the folders that hold those files. For the file `queries/rust/tags.scm`,
those paths are `queries`, `queries/rust`, and `queries/rust/tags.scm`.

These are the files of a pack, by their valid paths. The texts `<g>` and
`<r>` stand for the name of a grammar and the name of a test runner of
the descriptor.

| file | content | required |
|---|---|---|
| `pack.toml` | the descriptor | yes |
| `grammars/<g>.wasm` | the grammar `<g>` | one for each grammar of the descriptor |
| `queries/<g>/tags.scm` | the query file of the kind comment of the grammar `<g>` | one for each grammar |
| `queries/<g>/definitions.scm` | the query file of the kind definition | no |
| `queries/<g>/tests.scm` | the query file of the kind test | no |
| `adapters/<r>.wasm` | the adapter of the test runner `<r>` | one for each test runner with an adapter hash |
| `licenses/...` | the license texts and the notices that the licenses require | at least one file |

A pack can have other files, such as `README.md`. The pack hash covers
them too. A valid pack holds only folders and regular files: no
symbolic link, and no file of another kind.

A pack is well named when it meets the conditions of a
[well-named pack](sinter:#well-named-pack=v1). For example, a pack
cannot have both `queries/rust/tags.scm` and `queries/Rust/tests.scm`,
because the paths `queries/rust` and `queries/Rust` are the same text
after ASCII case folding. An empty folder is no path of the pack, so the
name of the empty folder breaks no rule.

A use of a pack is an operation that a program makes to give, for the
pack, whether the pack is well named, the valid paths of the files of
the pack, the pack listing of the pack, the pack hash of the pack,
whether the pack is valid, a value of the content of the file
`pack.toml` of the pack as a descriptor, the result of a reading of a
text with the pack, the content of one of the files of the pack, or the
result of a call of the adapter of one of the test runners of the pack.
In each use of a pack, a conforming program follows no symbolic link of
the folder tree of the pack. From the files of that folder tree, the
conforming program takes bytes only from the folders and the regular
files of that folder tree. The conforming program does not wait for
another process or for a device to act on a file of another kind, such
as a pipe, of that folder tree. The conforming program changes no file
of that folder tree. The conforming program uses no permission and no
privilege that its process did not have. When another process changes a
pack during a use, what a program gives from that pack is a matter of
the quality of an implementation. When the results of a grammar depend
on what the WebAssembly Core Specification 2.0 leaves to its embedder,
what a program gives with that grammar is a matter of the quality of an
implementation. In those cases, the rules of this paragraph still hold.

### 2.2 The pack hash

The pack listing of a well-named pack is a text with one line for each
file of the pack, in the code point order of the valid paths of the
files. Code point order compares two texts by the code points of their
characters, place by place, and puts a text A before each longer text
that starts with A. For pack paths, which are ASCII, code point order is
the order of their bytes. Each line holds, in this order:

1. the hash of the content of the file, as 64 lower-case hex digits;
2. two spaces;
3. the valid path of the file, with `/` between its file names and
   with no `./` at its start;
4. a line feed.

The pack hash is the hash of the UTF-8 encoding of the pack listing.
Only a well-named pack has a pack listing and a pack hash.

### 2.3 The descriptor

The descriptor of a pack is the content of its file `pack.toml`. A
valid descriptor is a TOML document whose root table holds the keys,
each with a TOML value of the right form, that the definition of a
[valid descriptor](sinter:#valid-descriptor=v1) gives.

The table `comments` can hold three keys: `line`, an array of line
sigils; `block`, an array of block pairs, each an array of an opening
sigil and a closing sigil; and `inner`, an array of inner sigils. A
comment sigil opens a comment, closes a comment, or starts a line of a
block comment after its first line. A comment sigil can be any text,
the empty text included.

Each table of the array `grammar` describes one
[grammar of the descriptor](sinter:#descriptor-grammar=v1). No two
grammars of a descriptor have the same name. A file-name glob is fitted
against the last file name of a valid path, and not against the whole
path. The file grammar of a valid path is the first grammar, in the
order of the array, that has a file-name glob that the last file name
fits. A valid path whose last file name fits no file-name glob has no
file grammar.

The table `runner` holds one table for each test runner, under the name
of the test runner. That name is a pack name. A test runner is a program
that runs tests and gives a test result for each test that it runs, and
that writes report files. The table of a test runner holds exactly one
of `adapter` and `match`. That table can hold `settings`. The
definitions of a [test runner](sinter:#test-runner=v1) and of a
[runner setting](sinter:#runner-setting=v1) give the values that these
keys hold.

The descriptor gives each license as a TOML string. A valid descriptor
puts no rule on the form of that string. A runner setting is a name and
a default value. The parameter `runner-settings` (section 3.1) gives
values for the runner settings of a test runner. The type of a runner
setting is the kind of its default value.

In a table whose keys the definition of a valid descriptor names,
another key makes the descriptor not valid. A TOML value of the wrong
kind, and a value that breaks the rule of its key, also make the
descriptor not valid. The value of `match` is any table. No rule of a
valid descriptor applies to the keys and values of that table. This is
the descriptor of a TypeScript pack with two grammars and one test
runner:

```toml
sinter-spec = "1.0"
name = "typescript"
version = "1.0.0"
license = "Apache-2.0"
name-separator = "."
foreign-tags = ["param", "returns", "throws", "example", "see", "type"]

[comments]
line = ["//"]
block = [["/*", "*/"], ["/**", "*/"]]
inner = ["*"]

[[grammar]]
name = "typescript"
sha256 = "778025db5a8be0e70f8ccc3671e486dfeddd048c25d9e8a70c26de2e1bf6f97d"
license = "MIT"
names = ["*.ts", "*.mts", "*.cts"]

[[grammar]]
name = "tsx"
sha256 = "79e5da75ea62855a0cd67177685f0164eac87d5f630b3cbe1e0a099751ad30f8"
license = "MIT"
names = ["*.tsx"]

[runner.vitest.match]
path = ["name"]
suite-separator = " > "

[runner.vitest.settings]
recognise = ["testsuites@name=vitest tests"]
```

With this descriptor, the file grammar of `src/a.test.ts` is
`typescript`, the file grammar of `ui/App.tsx` is `tsx`, and
`src/a.js` has no file grammar.

### 2.4 Grammars and query files

A grammar of a pack is a tree-sitter grammar, compiled to WebAssembly.
In a valid pack, the content of the file `grammars/<g>.wasm` is a
[usable grammar](sinter:#usable-grammar=v1) with the grammar name `<g>`.
In a valid pack, the hash of that content is the hash that the
descriptor gives for the grammar. A program runs the code of a usable
grammar in an instance of the WebAssembly module of that usable grammar.

A query file holds a tree-sitter query: a sequence of patterns. A
program runs the query over the parse tree of a text. A match is one
part of the parse tree where one pattern matches. That match has the
nodes that the pattern captures, each under a capture name. A capture
name that starts with `_` is for the predicates of a pattern alone. No
other rule takes the nodes of that capture name. There are three kinds
of query file. Each kind has its own capture names. The role names are
the capture names that give the kind of thing that a match finds. The
definition of a [query file](sinter:#query-file=v1) gives the capture
names of each kind, and how many times a pattern captures each of them.

A pattern can use only these ten predicates, the text predicates, which
a conforming program applies to the matches of the query language:
`#eq?`, `#not-eq?`, `#any-eq?`, `#any-not-eq?`, `#match?`,
`#not-match?`, `#any-match?`, `#any-not-match?`, `#any-of?`, and
`#not-any-of?`. The regular expression of a match predicate is a RegExp
pattern of ECMA-262 2025, with the flag `u`. The match predicate
searches the whole text of a node for a match of that regular
expression. A query with another predicate, such as `#is?`, or with a
directive, such as `#set!`, is not valid.

This example of a query file of the kind comment is for OCaml, in
which a doc comment `(** *)` carries no tags and a plain comment `(* *)`
carries them:

```scheme
((comment) @untagged (#match? @untagged "^\\(\\*\\*[^*]"))
(comment) @comment
```

This example of a query file of the kind definition is for Rust:

```scheme
(function_item name: (identifier) @name body: (block) @body) @definition
(attribute_item) @decoration
```

A pack is valid when the pack is well named, holds only folders and
regular files, and has each required file with the right content: a
valid descriptor; for each grammar, a usable grammar with the hash of
the descriptor and a valid query file of the kind comment, and valid
query files of the kinds definition and test when the pack has those
query files; for each test runner with an adapter hash, an adapter file
with that hash; and at least one file under `licenses/`. For an adapter
file, a valid pack needs only that hash: the content of the file need
not be a valid adapter.

### 2.5 The reading of a text

A program reads a text, as the text of a file at a valid path, with a
valid pack. The file grammar of the path selects the grammar. When the
path has no file grammar, the reading gives the result "no grammar".

The parse text is the text, with a line feed after the text when the
text does not end with a line feed. The program parses the UTF-8
encoding of the parse text with the language of the usable grammar. The
program runs the code of that language in an instance of the WebAssembly
module of the grammar. The text has no parse tree when the parsing of
tree-sitter gives no result, such as when the instantiation or an
invocation in that instance fails or a trap occurs in a WebAssembly
instance whose code runs for that parsing, or when the tree of nodes
that the parsing gives breaks the conditions of a parse tree. The
program ends each reading. The text has a parse failure when the text
has no parse tree, or when the root node of the parse tree has an error.
The root node has an error when the root node, or a node inside the root
node, nodes of hidden symbols included, is an `ERROR` node or a
`MISSING` node. A reading of a text with a parse failure gives the
result "parse failure", and no node of the text.

Each other reading gives the result "parsed". The program runs each
query file of the grammar over the parse tree. The query language of
tree-sitter can give the pieces of one name in two matches of one
pattern. So the query matches of one pattern that give one node the same
role form one joined match. That joined match takes each node that those
query matches capture, each node once, in the order of the parse tree.
Two joined matches of two different patterns can also give one node the
same role, such as when two patterns of `definitions.scm` capture one
node as `definition`. Then the joined match of the pattern that comes
first in the query file is the kept match. In that case, the program
takes no other joined match for that node and that role.

A reading with the result "parsed" gives these nodes, each with its run
and its node type:

- the comment nodes, the role nodes of the kept matches of the query
  file of the kind comment, each with whether it is tagged. A comment
  node is tagged when a kept match captures the comment node as
  `comment`, and no kept match captures the comment node as `untagged`.
  A comment node that is not tagged is still a comment node;
- the definition nodes, each with its name nodes and its body nodes.
  When the kept match of a definition node captures no node as `body`,
  the body node of that definition node is the definition node itself;
- the decoration nodes;
- the test nodes, each with whether it is a test case or a test suite,
  its name path, and its test labels.

The run of a node is the run of the text that the node takes up. The
parsing of tree-sitter gives the start and the end of a node in bytes of
the UTF-8 encoding of the parse text. The run counts characters. The run
of a node leaves out a line feed that only the parse text has, and the
byte order mark of the text. So the run of each node is a span of the
text.

### 2.6 Test cases, test suites, and their names

By the query file, a test node is the code of one test of the file: a
unit of code that a test runner runs and that can pass or fail, or a set
of such units that the code groups under one name. A test node is a test
case or a test suite. A test case is a test node for one such unit, such
as a Rust function with the attribute `#[test]`, or a call
`it("adds", ...)` in TypeScript. A node encloses a different node when
all three of these conditions hold. First, the run of the node starts at
or before the start of the run of the other node. Second, the run of the
node ends at or after the end of the run of the other node. Third, the
other node does not come before the node in the order of the parse tree.
So, of two nodes with the same run, the node that comes first in the
order of the parse tree encloses the other. A test node is a test suite,
such as a vitest `describe`, a Rust `mod tests`, or a test class, when
one of its kept matches captures it as `suite`, or when it encloses a
test node that a kept match captures as `case`. So, when one test case
encloses another, the outer one is a test suite.

The own name of a test node is a sequence of pieces. Each node that a
kept match of the test node captures as `name` or `placeholder` gives
one piece, in the order of the parse tree. A `name` node gives a text
piece: the text of the node, as the text of the file writes it. A
`placeholder` node gives a placeholder: text that the test runner puts
in the name of the test when it runs the test, such as for a template
substitution `${n}`. A placeholder can stand for any text, the empty
text included. A reading decodes nothing in a name: it removes no quote,
and it reads no escape sequence. The name path of a test node is the own
names of the test suites that enclose it, outermost first, then its own
name. By the query file, the name path is the name of the test of the
test node, as the code writes it.

The test labels of a test node come from the capture names
`label.<word>` of its kept matches, such as `label.each` for a test case
that the test runner runs once for each row of a table.

This example of a query file of the kind test is for vitest in
TypeScript:

```scheme
(call_expression
  function: [(identifier) @_fn
             (member_expression object: (identifier) @_fn)]
  arguments: (arguments .
    (string [(string_fragment) @name (escape_sequence) @placeholder]*))
  (#any-of? @_fn "it" "test")) @case

(call_expression
  function: [(identifier) @_fn
             (member_expression object: (identifier) @_fn)]
  arguments: (arguments .
    (template_string [(string_fragment) @name (escape_sequence) @placeholder
                      (template_substitution) @placeholder]*))
  (#any-of? @_fn "it" "test")) @case

(call_expression
  function: [(identifier) @_fn
             (member_expression object: (identifier) @_fn)]
  arguments: (arguments . (string [(string_fragment) @name (escape_sequence) @placeholder]*))
  (#eq? @_fn "describe")) @suite
```

With this query file, the text ``describe("math", () => {
it(`adds ${n}`, () => {}) })`` gives a test suite with the own name
`math`, a text piece, and, in that test suite, a test case whose own
name is the text piece `adds ` and the placeholder `${n}`. The name path
of the test case is these two own names.

### 2.7 Runner adapters

A runner adapter is a WebAssembly module that reads the report files of
one test runner and binds their test results to test entries, which
stand for test nodes. A pack has at most one adapter for each test
runner: the file `adapters/<r>.wasm`. In a decision of a program, the
module is a [valid adapter](sinter:#valid-adapter=v1) when the module
meets all four of these conditions. First, the module is a WebAssembly
module of the WebAssembly Core Specification 2.0. Second, the module
imports nothing (no function, no memory, no table, and no global).
Third, the module exports the five names `memory`, `sinter_interface`,
`sinter_alloc`, `sinter_recognise`, and `sinter_bind`, with the types
that the definition of an [adapter module](sinter:#adapter-module=v1)
gives. Fourth, the module gives the version of the interface, as the
next paragraph says.

The module can export other names, such as the globals `__data_end` and
`__heap_base` that some compilers add. This is version 1 of the
interface. A module gives that version when all three of these
conditions hold. First, in a new instance of the module, the decision of
the program runs the instantiation, then one invocation of
`sinter_interface`, and nothing else in that instance. Second, neither
the instantiation nor the invocation fails. Third, the invocation gives
the value 1.

A call runs one function of an adapter, with a request, a report
content, and, for the function bind, its test entry ids. The report
content is a byte sequence, such as the content of a report file. The
call uses one decision of the program whether the adapter is a valid
adapter, made in another instance, such as a decision that the program
made before the call. When that decision is that the adapter is not
valid, the call fails. The call then runs in a new instance of the
module of the adapter, so nothing that one call leaves in its instance
gets to the next call. In that instance, the program does only this, and
it changes no byte of the memory other than by the writes of steps 2 and
3:

1. makes the instance, which runs the start function of the module
   when it has one;
2. invokes `sinter_alloc` for the number of bytes of the request, and
   writes the request at the address that it gives;
3. invokes `sinter_alloc` for the number of bytes of the report
   content, and writes the report content, unchanged, at the address
   that it gives;
4. invokes the function with four arguments: the address and the number
   of bytes of the request, then the address and the number of bytes of
   the report content;
5. reads the value that the function gives: the high 32 bits are the
   address, and the low 32 bits are the length, of the response in
   `memory`.

Each address and each length is an unsigned number. A call fails when
its code traps, when `sinter_alloc` gives `0` or an address whose bytes
do not lie inside `memory`, or when the bytes of the response do not lie
inside `memory`. A call of an adapter that is not a valid adapter has
the result "failed".

The code of an instance of an adapter runs as the WebAssembly Core
Specification 2.0 defines, with the program as its embedder. The program
ends the code of each call.

The code of an adapter imports nothing, so it can read no file, use no
network, see no clock, and start no process. No file, network, clock, or
process gets to the code of an adapter.

### 2.8 Requests and responses

The request is the canonical byte sequence of a JSON object, so the
members of each object of the request stand in key order. The
definition of a [request](sinter:#adapter-request=v1) gives the members
of the request objects of the functions recognise and bind. For example,
the request of a call of recognise for the test runner `vitest`, with
the runner setting `recognise` at its default value, and the report
name `out/junit.xml`, is the UTF-8 encoding of this text:

```
{"interface":1,"report":"out/junit.xml","runner":"vitest","settings":{"recognise":["testsuites@name=vitest tests"]}}
```

The response is a JSON text in UTF-8. The definition of the
[result of a call](sinter:#call-result=v1) gives the result of a call
from its response, and the test results, the binding objects, the
warnings, and the error text of the adapter that the call gives. This
response of bind binds one test result to one test entry:

```
{"bindings":[{"reason":"name and file match","result":0,"test":"t1"}],"results":[{"file":"src/math.test.ts","ms":3,"name":"math > adds","status":"pass"}],"warnings":[]}
```

## 3. Parameters

### 3.1 `runner-settings`

@schema runner-settings=v1
@cites {
    ontology#{parameter=v1},
    data-forms#{toml-value=v1},
    text#{text=v1, code-span=v1},
    #{valid-descriptor=v1, test-runner=v1, runner-setting=v1},
}

The parameter `runner-settings` gives values for the runner settings of
a test runner of a valid descriptor. A binding of the parameter
`runner-settings`, for a test runner of a valid descriptor, is a finite
set of pairs. Each pair is a name, which is a text, and a TOML value.
The binding can be the empty set.

A binding of `runner-settings`, for a test runner of a valid descriptor,
meets the schema `runner-settings` when, and only when, the binding
meets all three of these conditions. First, the name of each pair is the
name of a runner setting of that test runner. Second, no two pairs have
the same name. Third, for each pair, the TOML value of the pair is a
TOML string when the type of the runner setting of that test runner with
the name of the pair is string; the TOML value of the pair is a TOML
boolean when the type of that runner setting is boolean; and the TOML
value of the pair is a TOML array of TOML strings when the type of that
runner setting is array of strings.

## 4. Definitions

### 4.1 Packs

@term pack=v1
@cites {files#{folder-tree=v1, regular-file=v1, path=v1, path-file=v1}, text#{text=v1}}

A pack is a folder tree. A file of a pack has a valid path and a
content. For each valid path whose last file name names a regular file
in the folder tree of the pack, the pack has one file, whose valid path
is that valid path and whose content is the content of that regular
file. The pack has no other file. A pack has the file p, for a text p,
when, and only when, it has a file whose valid path is p.

### 4.2 Pack paths

@term pack-path=v1
@cites text#{production=v1, rule-name=v1, code-span=v1, text=v1}

A pack path is a text that matches the production `pack-path`:

```abnf
pack-path       = pack-path-name *( "/" pack-path-name )
pack-path-name  = *"." pack-path-char *( pack-path-char / "." ) / 3*"."
pack-path-char  = %x20-2D / %x30-5B / %x5D-7E
```

### 4.3 Well-named packs

@term well-named-pack=v1
@cites {
    files#{folder-tree=v1, folder=v1, regular-file=v1, path=v1},
    text#{
        text=v1, character=v1, code-point=v1, place=v1, boundary=v1, run=v1,
        utf-8-encoding=v1, production=v1, code-span=v1,
    },
    #{pack=v1, pack-path=v1},
}

The paths of a pack are the valid paths of its files, and the text of
each run of one of these valid paths that starts at boundary 0 and ends
at the boundary right before a place of that valid path whose character
is `/`. ASCII case folding
changes each character of a text whose code point is from 65 to 90 to
the character whose code point is 32 more, and it changes no other
character. A pack is well named when, and only when, it meets each of
these conditions:

- For each folder entry of the root or of a folder of the folder tree of
  the pack, when the file of that folder entry is a regular file, or is
  a folder that is the root of a folder tree with a regular file among
  the files of that folder tree, that folder entry has an entry name
  that is the UTF-8 encoding of a text that matches the production
  `file-name`.
- Each path of the pack is a pack path.
- No two different paths of the pack are the same text after ASCII case
  folding.

### 4.4 Pack hashes

@term pack-hash=v1
@cites {
    files#{path=v1},
    data-forms#{hash=v1},
    text#{
        text=v1, character=v1, space=v1, line-feed=v1, utf-8-encoding=v1,
        byte=v1, code-point-order=v1,
    },
    #{pack=v1, well-named-pack=v1},
}

The pack listing of a well-named pack is the text that holds, for each
file of the pack, in the code point order of the valid paths of the
files, the hash of the content of the file, then two spaces, then the
valid path of the file, then a line feed, and no other character. The
pack hash of a well-named pack is the hash of the UTF-8 encoding of its
pack listing. A pack that is not well named has no pack listing and no
pack hash.

### 4.5 Uses of packs

@term pack-use=v1
@cites {
    files#{path=v1},
    text#{result=v1, text=v1},
    #{
        pack=v1, well-named-pack=v1, pack-hash=v1, valid-pack=v1,
        valid-descriptor=v1, test-runner=v1, reading-result=v1,
        adapter-call=v1, call-result=v1,
    },
}

A use of a pack is an operation that a program makes to give, for that
pack, one of these: a result for whether the pack is well named; the
valid paths of its files; its pack listing; its pack hash; a result for
whether the pack is valid; a value of the content of its file
`pack.toml` as a descriptor; a result of a reading of a text with the
pack; the content of one of its files; or a result of a call of the
adapter of a test runner of the descriptor of the pack. Such an
operation is a use of the pack also when the program gives another thing
in that operation, or gives nothing.

### 4.6 WebAssembly modules

@term webassembly-module=v1
@cites {wasm-core/2.0, text#{byte-sequence=v1}}

A WebAssembly module is a byte sequence that is a module in the binary
format of the WebAssembly Core Specification 2.0, and that is valid by
that specification.

### 4.7 Usable grammars

@term usable-grammar=v1
@cites {
    tree-sitter/language-format, tree-sitter/abi-versions, wasm-core/2.0,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text=v1, whole-number=v1,
        code-span=v1,
    },
    #{webassembly-module=v1, grammar-name=v1},
}

This definition uses the format of languages that tree-sitter defines,
in its ABI versions 13 to 15. In that format, a language has an ABI
version, which is a whole number. In that format, a language has
symbols, which are all the entries of its table of symbols, its aliases
included. Each of those symbols has a name, which is a byte sequence,
and each of those symbols is named or anonymous, visible or hidden, and
a supertype or not. In that format, a language has fields, and each of
those fields has a name, which is a byte sequence. In that format, at
the ABI version 15, a language has, for each supertype, a list of
symbols, which are the subtypes of that supertype. A byte sequence is a
usable grammar with a grammar name g when, and only when, it meets each
of these conditions:

1. It is a WebAssembly module.
2. It gives, as that format defines, a language from its export whose
   name is `tree_sitter_` followed by g, of an ABI version from 13 to 15.
3. The name of each symbol of that language is valid UTF-8.

The language of a usable grammar with the grammar name g is that
language. The ABI version of a usable grammar with the grammar name g is
the ABI version of that language.

### 4.8 The query language

@term query-language=v1
@cites {
    tree-sitter/query-language,
    text#{text=v1, code-span=v1, whole-number=v1},
    #{usable-grammar=v1, parse-tree=v1},
}

The query language is the language of queries that tree-sitter's
documentation of it defines. A query for a language is a text that is a
query for that language by tree-sitter's documentation of the query
language. A query for a language is a sequence of zero or more patterns.
A pattern captures nodes under capture names, each written `@` followed
by the capture name. Each capture name of a pattern has a quantifier in
that pattern: zero, zero or one, zero or more, one, or one or more. Each
of these five stands for a set of whole numbers: zero for 0 alone, zero
or one for 0 and 1, zero or more for every whole number, one for 1
alone, and one or more for every whole number from 1. The quantifier of
a capture name in a pattern is the one of the five whose set is the
smallest that holds each number of nodes that the pattern captures under
that name, over each choice of one alternative of each alternation of
the pattern and each number of repetitions that each `?`, `*`, and `+`
of the pattern allows. A capture name written after an element of a
pattern, before or after the `?`, `*`, or `+` of that element, captures
the node of each repetition of that element.

The matches of a query over a parse tree are the parts of the parse tree
where a pattern of the query matches, each with that pattern and with
the nodes that it captures under each capture name.

### 4.9 Text predicates

@term text-predicate=v1
@cites {
    ecma/262-2025,
    data-forms#{index=v1, utf-16-code-unit=v1},
    text#{text=v1, run=v1, character=v1, code-span=v1},
    #{query-language=v1, parse-tree-order=v1, node-run=v1},
}

The text predicates are ten predicates of the query language. These are
their names and their arguments:

- `#eq?`, `#not-eq?`, `#any-eq?`, and `#any-not-eq?`: a capture, then a
  capture or a string;
- `#match?`, `#not-match?`, `#any-match?`, and `#any-not-match?`: a
  capture, then a string, which is a RegExp pattern of ECMA-262 2025
  that is valid with the flag `u`;
- `#any-of?` and `#not-any-of?`: a capture, then one or more strings.

The text of a node is the text of its run. In a match, when the second
argument is not a capture, each node that the match captures under the
first capture pairs with the string or the strings of the predicate. In
a match, when the second argument is a capture, each node that the match
captures under the first capture pairs with the node that the match
captures under that second capture at the same index, in the order of
the parse tree. In a match, a node with no partner is not compared. For
a pair:

- `#eq?` and `#any-eq?` hold when the text of the node is the text of
  the string or of the other node. `#not-eq?` and `#any-not-eq?` hold
  when the text of the node is not the text of the string or of the
  other node;
- `#match?` and `#any-match?` hold when a RegExp of the pattern, with
  the flag `u` and no other flag, finds a match in the text of the node,
  as a String of the UTF-16 code units of that text, with that whole
  text as the input of that RegExp and the search starting at index 0,
  as `RegExp.prototype.test` of ECMA-262 2025 does. `#not-match?` and
  `#any-not-match?` hold when that RegExp finds no match in that search.
  The character classes of the pattern, such as `\w`, match as ECMA-262
  2025 defines them;
- `#any-of?` holds when the text of the node is the text of one of the
  strings. `#not-any-of?` holds when the text of the node is the text of
  none of those strings.

A text predicate whose name does not start with `#any-` holds in a match
when it holds for each pair, and so when there is no pair; `#any-of?`
also holds so. Each other text predicate holds when it holds for at
least one pair.

### 4.10 Query files

@term query-file=v1
@cites {
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        text=v1, production=v1, rule-name=v1, code-span=v1,
    },
    #{
        grammar-name=v1, usable-grammar=v1, query-language=v1,
        text-predicate=v1,
    },
}

A query file is of one of three kinds, each with its role names
and its other capture names:

- The kind comment has the role names `comment` and `untagged`, and no
  other capture name.
- The kind definition has the role names `definition` and `decoration`,
  and the other capture names `name` and `body`.
- The kind test has the role names `case` and `suite`, and the other
  capture names `name`, `placeholder`, and each text that matches the
  production `label-capture`:

  ```abnf
  label-capture  = %s"label." label-word
  label-word     = %x61-7A *( %x61-7A / DIGIT / "-" )
  ```

A byte sequence is a valid query file of a kind for a usable grammar
with a grammar name g when, and only when, it meets each of these
conditions:

1. It is valid UTF-8.
2. Its text is a query of the query language for the language of that
   usable grammar with the grammar name g.
3. Each predicate and each directive of each pattern of the query is a
   text predicate, with the arguments that its name gives it.
4. Each capture name of the query that does not start with `_` is a role
   name or another capture name of that kind.
5. For each pattern of the query, the quantifiers of the capture names,
   where a capture name that the pattern does not have has the
   quantifier zero, meet the rule of that kind:
   - comment: one of `comment` and `untagged` has the quantifier one,
     and the other has the quantifier zero;
   - definition: one of two cases holds. In the first case, `definition`
     has the quantifier one, `decoration` has the quantifier zero, and
     `name` and `body` each have the quantifier zero, zero or one, or
     one. In the second case, `decoration` has the quantifier one, and
     `definition`, `name`, and `body` each have the quantifier zero;
   - test: one of `case` and `suite` has the quantifier one, and the
     other has the quantifier zero.

### 4.11 Valid packs

@schema valid-pack=v1
@cites {
    files#{folder-tree=v1, folder=v1, regular-file=v1, path=v1},
    data-forms#{hash=v1},
    text#{text=v1, code-span=v1},
    #{
        pack=v1, well-named-pack=v1, valid-descriptor=v1, grammar-name=v1,
        descriptor-grammar=v1, test-runner=v1, usable-grammar=v1,
        query-file=v1,
    },
}

In this definition, for a text g, `grammars/<g>.wasm` is the text
`grammars/`, then g, then `.wasm`. In this definition, for a text g,
`queries/<g>/tags.scm` is the text `queries/`, then g, then `/tags.scm`.
In this definition, for a text g, `queries/<g>/definitions.scm` is the
text `queries/`, then g, then `/definitions.scm`. In this definition,
for a text g, `queries/<g>/tests.scm` is the text `queries/`, then g,
then `/tests.scm`. In this definition, for a text r, `adapters/<r>.wasm`
is the text `adapters/`, then r, then `.wasm`. A pack is valid when, and
only when, it meets each of these conditions:

1. Each file of the folder tree of the pack, other than the root of that
   folder tree, is a folder or a regular file.
2. It is well named.
3. The pack has the file `pack.toml`. The content of that file is a
   valid descriptor.
4. For each grammar of that valid descriptor, with the name g:
   - The pack has the file `grammars/<g>.wasm`. The hash of the content
     of that file is the hash of that grammar. The content of that file
     is a usable grammar with the grammar name g.
   - The pack has the file `queries/<g>/tags.scm`. The content of that
     file is a valid query file of the kind comment for that usable
     grammar with the grammar name g.
   - When the pack has the file `queries/<g>/definitions.scm`, the
     content of that file is a valid query file of the kind definition
     for that usable grammar with the grammar name g.
   - When the pack has the file `queries/<g>/tests.scm`, the content of
     that file is a valid query file of the kind test for that usable
     grammar with the grammar name g.
5. For each test runner of that valid descriptor that has an adapter
   hash, with the name r, the pack has the file `adapters/<r>.wasm`. For
   each test runner of that valid descriptor that has an adapter hash,
   with the name r, the hash of the content of the file
   `adapters/<r>.wasm` of the pack is that adapter hash.
6. It has at least one file whose valid path starts with the text
   `licenses/`.

For a valid pack, the descriptor of that pack is the valid descriptor
that is the content of the file `pack.toml` of that pack. For a valid
pack and a grammar of the descriptor of that pack, with the name g, the
usable grammar of that grammar is the content of the file
`grammars/<g>.wasm` of that pack, as a usable grammar with the grammar
name g. For a valid pack and a grammar of the descriptor of that pack,
the language of that grammar is the language of the usable grammar of
that grammar. For a valid pack and a grammar of the descriptor of that
pack, with the name g, the query file of the kind comment of that
grammar is the content of the file `queries/<g>/tags.scm` of that pack.
For a valid pack and a grammar of the descriptor of that pack, with the
name g, when that pack has the file `queries/<g>/definitions.scm`, the
query file of the kind definition of that grammar is the content of that
file. For a valid pack and a grammar of the descriptor of that pack,
with the name g, when that pack does not have the file
`queries/<g>/definitions.scm`, that grammar has no query file of the
kind definition. For a valid pack and a grammar of the descriptor of
that pack, with the name g, when that pack has the file
`queries/<g>/tests.scm`, the query file of the kind test of that grammar
is the content of that file. For a valid pack and a grammar of the
descriptor of that pack, with the name g, when that pack does not have
the file `queries/<g>/tests.scm`, that grammar has no query file of the
kind test. For a valid pack and a test runner of the descriptor of that
pack that has an adapter hash, with the name r, the adapter of that test
runner is the content of the file `adapters/<r>.wasm` of that pack.

### 4.12 Parse trees

@term parse-tree=v1
@cites {
    tree-sitter/language-format, wasm-core/2.0,
    text#{
        text=v1, character=v1, boundary=v1, run=v1, body=v1,
        line-feed=v1, utf-8-encoding=v1, byte=v1, byte-sequence=v1,
        whole-number=v1, code-span=v1,
    },
    #{webassembly-module=v1, usable-grammar=v1, grammar-name=v1},
}

This definition uses the parsing that the format of languages of
tree-sitter defines. For a language and a byte sequence, that parsing
gives a tree of nodes or no result. This parsing runs the code of the
language in the instance of the WebAssembly module in which that module
gave that language. The parsing gives no result when the instantiation
of that module fails, when an invocation in that instance fails, or when
a trap occurs in a WebAssembly instance whose code runs for that
parsing, such as the instance of the grammar or an instance that runs
parsing code of tree-sitter. Each tree of nodes that this parsing gives
has a root node. For each tree of nodes that this parsing gives, the
children of each node of that tree of nodes are the named and the
anonymous child nodes of that node, in their order. A node of a hidden
symbol is no node of that tree of nodes. The children of a node of a
hidden symbol stand in the place of that node. Each node has a symbol.
Each symbol has a name. Each node has a start byte and an end byte,
which are whole numbers. An `ERROR` node is a node of the symbol
`ERROR`. A `MISSING` node is a node that the parsing inserts for a token
that the text lacks. A node has an error when that node, or a node that
the parsing gives inside that node, nodes of hidden symbols included, is
an `ERROR` node or a `MISSING` node.

The parse text of a text is that text, followed by a line feed when the
text does not end with a line feed. So the parse text of the empty text
is one line feed.

For a text and a usable grammar with a grammar name g, let b be the
boundary where the body of the text starts. Let l be the last boundary
of that text. The tree of nodes that this parsing gives for the language
of that usable grammar and the UTF-8 encoding of the parse text of that
text is the parse tree of that text with that usable grammar when, and
only when, its nodes (with the nodes of hidden symbols left out and
their children standing in their place) meet all four of these
conditions:

1. For each node, the start byte of the node is the number of bytes of
   the UTF-8 encoding of the characters of the parse text before a
   boundary of the parse text. For each node, the end byte of the node
   is the number of bytes of the UTF-8 encoding of the characters of the
   parse text before a boundary of the parse text.
2. For each node, the start byte of the node is less than or equal to
   the end byte of the node.
3. For each node and each child of that node, the run of the child in
   the text starts at or after the boundary where the run of the node in
   the text starts, and ends at or before the boundary where the run of
   the node in the text ends.
4. For each node and each two children of that node, when the first
   comes before the second in the order of the children of that node,
   the run of the first in the text ends at or before the boundary where
   the run of the second in the text starts.

For a node that meets conditions 1 and 2, the run of that node in the
text is the run of the text that starts at the greater of b and the
lesser of s and l, and that ends at the greater of b and the lesser of
e and l, where s and e are the boundaries of the parse text that
condition 1 gives for the start byte and the end byte of that node.
When this parsing gives no result, or gives a tree of nodes that breaks
any of these four conditions, the text has no parse tree with that
usable grammar.

### 4.13 The order of the parse tree

@term parse-tree-order=v1
@cites #{parse-tree=v1}

The nodes of a parse tree are its root node and each child of each of
its nodes. The descendants of a node are its children and the
descendants of its children. In the order of the parse tree, each node
comes before each of its descendants. In the order of the parse tree,
for each two children of one node, the first of those two children and
each descendant of the first of those two children come before the
second of those two children.

### 4.14 The runs of nodes

@term node-run=v1
@cites {
    text#{text=v1, boundary=v1, run=v1, code-span=v1},
    #{parse-tree=v1, parse-tree-order=v1},
}

The run of a node of the parse tree of a text is the run of that node in
the text, as `parse-tree` gives that run. So, for two nodes A and B of a
parse tree, when A comes before B in the order of the parse tree, one of
two things holds. The first thing is that the run of B starts at or
after the boundary where the run of A starts, and the run of B ends at
or before the boundary where the run of A ends. The second thing is that
the run of A ends at or before the boundary where the run of B starts.
Two nodes can have the same run, such as a node and its only child. Two
nodes can each have a run that starts and ends at one boundary, the same
boundary for both nodes.

### 4.15 Node types

@term node-type=v1
@cites {
    text#{text=v1, text-of-a-byte-sequence=v1},
    #{usable-grammar=v1, parse-tree=v1, parse-tree-order=v1},
}

The node type of a node of a parse tree is the text of the name of its
symbol.

### 4.16 Parse failures

@term parse-failure=v1
@cites {text#{text=v1}, #{usable-grammar=v1, parse-tree=v1}}

A text has a parse failure with a usable grammar when, and only when,
the text has no parse tree with that usable grammar, or the root node of
its parse tree with that usable grammar has an error.

### 4.17 Query matches

@term query-match=v1
@cites {
    text#{code-span=v1},
    #{
        usable-grammar=v1, grammar-name=v1, query-language=v1,
        query-file=v1, text-predicate=v1, parse-tree=v1,
        parse-tree-order=v1,
    },
}

For a valid query file of a kind for a usable grammar with a grammar
name g, and a text that has a parse tree with that usable grammar such
that the root node of that parse tree has no error, the query matches
are those matches of the query of that query file, without the
predicates of that query, over that parse tree, as the query language
defines those matches, in which each text predicate of the pattern of
the match holds. Each query match has one pattern of the query. A
pattern A comes before another pattern B when A stands before B in the
query file. The captures of a query match are the captures of that query
match whose capture names do not start with `_`. Each of those captures
is a capture name and a node of the parse tree.

### 4.18 Joined matches and kept matches

@term joined-match=v1
@cites {
    text#{text=v1},
    #{query-file=v1, query-match=v1, parse-tree=v1, parse-tree-order=v1},
}

A query match of a valid query file has exactly one capture whose
capture name is a role name of the kind of that query file. The role
name of the query match is the capture name of that capture. The role
node of the query match is the node of that capture. The query matches
of one query file over one text that have the same pattern, the same
role name, and the same role node form one joined match. A joined match
has that pattern, that role name, and that role node. For each capture
name, that joined match has the nodes that the query matches of that
joined match capture under that capture name, each node once, in the
order of the parse tree. The kept matches of a query file over a text
are the joined matches of that query file over that text that meet this
condition: the pattern of the joined match comes before the pattern of
each other joined match of that query file over that text that has the
same role name and the same role node.

### 4.19 Comment nodes

@term comment-node=v1
@cites {
    text#{text=v1, code-span=v1},
    #{
        usable-grammar=v1, query-file=v1, valid-pack=v1,
        descriptor-grammar=v1, parse-tree=v1, joined-match=v1,
        parse-tree-order=v1,
    },
}

This definition is for a valid pack, a grammar of its descriptor, and a
text that has a parse tree with the usable grammar of that grammar. The
comment nodes of the text are the role nodes of the kept matches of the
query file of the kind comment of that grammar over the text, each node
once, in the order of the parse tree. A comment node is tagged when, and
only when, it is the role node of a kept match with the role name
`comment`, and of no kept match with the role name `untagged`.

### 4.20 Definition nodes

@term definition-node=v1
@cites {
    text#{text=v1, code-span=v1},
    #{
        usable-grammar=v1, query-file=v1, valid-pack=v1,
        descriptor-grammar=v1, parse-tree=v1, joined-match=v1,
        parse-tree-order=v1,
    },
}

This definition is for a valid pack, a grammar of its descriptor, and a
text that has a parse tree with the usable grammar of that grammar. The
definition nodes of the text are the role nodes of the kept matches with
the role name `definition` of the query file of the kind definition of
that grammar over the text, in the order of the parse tree. The text has
no definition node when that grammar has no query file of the kind
definition. The name nodes of a definition node are the nodes that its
kept match with the role name `definition` captures under `name`, in the
order of the parse tree. The body nodes of a definition node are the
nodes that this kept match captures under `body`, in the order of the
parse tree, or, when it captures no node under `body`, the definition
node alone.

### 4.21 Decoration nodes

@term decoration-node=v1
@cites {
    text#{text=v1, code-span=v1},
    #{
        usable-grammar=v1, query-file=v1, valid-pack=v1,
        descriptor-grammar=v1, parse-tree=v1, joined-match=v1,
        parse-tree-order=v1,
    },
}

This definition is for a valid pack, a grammar of its descriptor, and a
text that has a parse tree with the usable grammar of that grammar. The
decoration nodes of the text are the role nodes of the kept matches with
the role name `decoration` of the query file of the kind definition of
that grammar over the text, in the order of the parse tree. The text has
no decoration node when that grammar has no query file of the kind
definition.

### 4.22 Enclosed nodes

@term enclosed-node=v1
@cites {text#{run=v1, boundary=v1}, #{parse-tree=v1, parse-tree-order=v1, node-run=v1}}

A node A of the parse tree of a text encloses a different node B of that
parse tree when, and only when, all three of these conditions hold.
First, the run of A starts at the boundary where the run of B starts, or
at a boundary before that boundary. Second, the run of A ends at the
boundary where the run of B ends, or at a boundary after that boundary.
Third, B does not come before A in the order of the parse tree. For a
node A and a different node B of the parse tree of a text, B is an
enclosed node of A when, and only when, A encloses B.

### 4.23 Test nodes

@term test-node=v1
@cites {
    ontology#{test=v1},
    files#{path=v1},
    text#{text=v1, code-span=v1},
    #{
        usable-grammar=v1, query-file=v1, valid-pack=v1,
        descriptor-grammar=v1, parse-tree=v1, joined-match=v1,
        parse-tree-order=v1, enclosed-node=v1,
    },
}

This definition is for a valid pack, a grammar of its descriptor, and a
text, as the text of a file at a valid path, that has a parse tree with
the usable grammar of that grammar. The test nodes of the text are the
role nodes of the kept matches of the query file of the kind test of
that grammar over the text, each node once, in the order of the parse
tree. By the query file of the kind test, each test node is the code of
one test of the file at that valid path, its test: of one unit, for a
test case, or of a set of units that the code groups under one name, for
a test suite. The text has no test node when that grammar has no query
file of the kind test. The kept matches of a test node are the kept
matches whose role node is that test node. A test node is a test suite
when, and only when, one of the kept matches of that test node has the
role name `suite`, or that test node encloses a test node that has a
kept match with the role name `case`. Each other test node is a test
case. The test suites that enclose a test node are the test nodes that
are test suites and that enclose it, in the order of the parse tree.

### 4.24 The names of test nodes

@term test-name=v1
@cites {
    ontology#{test=v1},
    text#{text=v1, run=v1, code-span=v1},
    data-forms#{index=v1},
    #{
        joined-match=v1, parse-tree=v1, parse-tree-order=v1, node-run=v1,
        enclosed-node=v1, test-node=v1, test-runner=v1,
    },
}

A piece is a text piece or a placeholder. A piece has a text. A text
piece stands for its text, as the text of the file writes it. A
placeholder stands for text that a test runner puts in the name of a
test when that test runner runs that test. The text that a placeholder
stands for can be any text, the empty text included. The own name of a
test node is a sequence of pieces, one for each node that one of the
kept matches of that test node captures under `name` or under
`placeholder`, in the order of the parse tree. A node that one of these
kept matches captures under `placeholder` gives a placeholder. Each
other of these nodes gives a text piece. The text of each piece is the
text of the run of its node. The name path of a test node is the own
names of the test suites that enclose that test node, in the order of
the parse tree, followed by the own name of that test node. By the query
file, the name path of a test node is the name of the test of that test
node, as the code writes that name. Two name paths are equal when, and
only when, all three of these conditions hold. First, the two name paths
have the same number of names. Second, at each index of the two name
paths, the two names at that index have the same number of pieces.
Third, for each pair of names at the same index of the two name paths,
at each index of the pieces of those two names, the two pieces at that
index are of the same kind and have the same text.

### 4.25 The test labels of test nodes

@term test-label=v1
@cites {
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
    #{query-file=v1, joined-match=v1, test-node=v1},
}

The test labels of a test node are the texts w that match the production
`label-word` and such that one of the kept matches of the test node
captures a node under the capture name that is the text `label.`
followed by w.

### 4.26 Results of readings

@atom reading-result=v1
@cites {
    files#{path=v1},
    text#{text=v1, result=v1},
    #{
        grammar-name=v1, valid-pack=v1, descriptor-grammar=v1,
        file-grammar=v1, parse-failure=v1,
    },
}

A reading of a text, as the text of a file at a valid path p, with a
valid pack, has one of three results. When p has a file grammar for the
descriptor of the pack, g is that file grammar. The results are:

1. "no grammar" when p has no file grammar for the descriptor of the
   pack;
2. "parse failure" when the text has a parse failure with the usable
   grammar of g, with the name of g as the grammar name of that usable
   grammar;
3. "parsed" otherwise.

### 4.27 Readings

@term reading-of-a-text=v1
@cites {
    files#{path=v1},
    text#{text=v1, result=v1, run=v1, code-span=v1},
    #{
        valid-pack=v1, descriptor-grammar=v1, file-grammar=v1,
        reading-result=v1, node-run=v1, node-type=v1, comment-node=v1,
        definition-node=v1, decoration-node=v1, test-node=v1,
        test-name=v1, test-label=v1,
    },
}

A reading of a text, as the text of a file at a valid path p, with a
valid pack, has the result that `reading-result` gives that reading.
When p has a file grammar for the descriptor of the pack, g is that file
grammar. A reading with the result "parsed" gives the comment nodes, the
definition nodes, the decoration nodes, and the test nodes of the text
for g, each with its run and its node type. With each comment node, a
reading with the result "parsed" gives whether that comment node is
tagged. With each definition node, a reading with the result "parsed"
gives the name nodes and the body nodes of that definition node, each of
those name nodes and body nodes with its run and its node type. With
each test node, a reading with the result "parsed" gives whether that
test node is a test case or a test suite, the name path of that test
node, and the test labels of that test node. A reading with the result
"parse failure" or "no grammar" gives no node of the text.

### 4.28 Values of runner settings

@term runner-setting-value=v1
@cites {
    ontology#{parameter=v1},
    data-forms#{toml-value=v1},
    text#{code-span=v1},
    #{
        runner-settings=v1, valid-descriptor=v1, test-runner=v1,
        runner-setting=v1,
    },
}

Under a valid binding of the parameter `runner-settings` for a test
runner of a valid descriptor, when a pair of that binding has the name
of a runner setting of that test runner, the value of that runner
setting is the TOML value of that pair. Under a valid binding of the
parameter `runner-settings` for a test runner of a valid descriptor,
when no pair of that binding has the name of a runner setting of that
test runner, the value of that runner setting is the default value of
that runner setting. When the binding is the empty set, each runner
setting of that test runner has its default value.

## 5. The descriptor
@spec descriptor=v1

When a conforming program decides whether a byte sequence is a valid
descriptor, the program gives "valid" when the byte sequence is a valid
descriptor, and the program gives "invalid" when the byte sequence is
not a valid descriptor. When a conforming program gives a value of a
valid descriptor, the program gives the value that the descriptor gives:
the spec version, the pack name, the release number, the license, the
name separator, the foreign tag words, the comment sigils, the grammars,
and the test runners with their runner settings. A conforming program
gives none of these values for a byte sequence that is not a valid
descriptor. A conforming program gives no adapter hash, adapter license,
or match table for a test runner that has none. When it gives a grammar
as the file grammar of a valid path for a valid descriptor, it gives the
file grammar of that path, and it gives no grammar when the path has
none.

A valid descriptor is a TOML document. The rules of a valid descriptor
are on the root table of that document and on TOML values. The rules
name keys by the texts of the TOML keys. The rules put conditions on
TOML values of four kinds: TOML strings, TOML booleans, TOML arrays, and
tables.

### 5.1 Definitions

#### 5.1.1 Pack names

@term pack-name=v1
@cites text#{production=v1, rule-name=v1, code-span=v1, text=v1}

A pack name is a text that matches the production `pack-name`:

```abnf
pack-name  = %x61-7A *( %x61-7A / DIGIT ) *( "-" 1*( %x61-7A / DIGIT ) )
```

#### 5.1.2 Grammar names

@term grammar-name=v1
@cites text#{production=v1, rule-name=v1, code-span=v1, text=v1}

A grammar name is a text that matches the production `grammar-name`:

```abnf
grammar-name  = %x61-7A *( %x61-7A / DIGIT / "_" )
```

#### 5.1.3 Release numbers

@term release-number=v1
@cites text#{production=v1, rule-name=v1, code-span=v1, text=v1, decimal-numeral=v1}

A release number is a text that matches the production
`release-number`:

```abnf
release-number  = decimal-numeral "." decimal-numeral "." decimal-numeral
```

#### 5.1.4 Spec versions

@term spec-version=v1
@cites text#{production=v1, rule-name=v1, code-span=v1, text=v1, decimal-numeral=v1}

A spec version is a text that matches the production `spec-version`:

```abnf
spec-version  = decimal-numeral "." decimal-numeral
```

A spec version names a version of the specifications of Sinter.

#### 5.1.5 Name separators

@term name-separator=v1
@cites {text#{text=v1, code-span=v1}, #{pack=v1}}

A name separator is a text, not empty, that a pack gives to join names
into one text. Examples of name separators are `.` and `::`.

#### 5.1.6 Valid descriptors

@schema valid-descriptor=v1
@cites {
    data-forms#{toml-document=v1, root-table=v1, toml-value=v1, hash-form=v1},
    files#{glob=v1},
    text#{
        production=v1, rule-name=v1, code-span=v1, text=v1, byte-sequence=v1,
    },
    #{
        pack=v1, pack-name=v1, grammar-name=v1, release-number=v1,
        spec-version=v1, name-separator=v1, query-file=v1,
    },
}

A valid descriptor is a byte sequence that is a TOML document whose root
table meets each of these rules:

1. The root table holds the texts `sinter-spec`, `name`, `version`,
   `license`, `name-separator`, `comments`, and `grammar`. The root
   table can hold the texts `foreign-tags` and `runner`. The root table
   holds no other text.
2. The TOML value of `sinter-spec` is a TOML string whose text is a spec
   version.
3. The TOML value of `name` is a TOML string whose text is a pack name.
4. The TOML value of `version` is a TOML string whose text is a release
   number.
5. The TOML value of `license` is a TOML string.
6. The TOML value of `name-separator` is a TOML string whose text is not
   the empty text.
7. The TOML value of `foreign-tags`, when the root table holds that
   text, is a TOML array of TOML strings whose texts each match the
   production `foreign-tag`:

   ```abnf
   foreign-tag  = 1*( ALPHA / DIGIT / "-" )
   ```

8. The TOML value of `comments` is a table that holds no text other than
   `line`, `block`, and `inner`. When that table holds the text `line`,
   the TOML value of `line` is a TOML array of TOML strings. When that
   table holds the text `inner`, the TOML value of `inner` is a TOML
   array of TOML strings. The TOML value of `block`, when that table
   holds that text, is a TOML array of TOML arrays, each of exactly two
   TOML strings.
9. The TOML value of `grammar` is a TOML array of one or more tables.
   Each of these tables holds the texts `name`, `sha256`, `license`, and
   `names`, and no other text. In each of these tables, the TOML value
   of `name` is a TOML string whose text is a grammar name. In each of
   these tables, the TOML value of `sha256` is a TOML string whose text
   fits the hash form. In each of these tables, the TOML value of
   `license` is a TOML string. In each of these tables, the TOML value
   of `names` is a TOML array of TOML strings whose texts are each a
   valid glob. No two of these tables have TOML strings of `name` whose
   texts are the same text.
10. When the root table holds the text `runner`, the TOML value of
    `runner` is a table. When the root table holds the text `runner`,
    each text that the table of `runner` holds is a pack name. When the
    root table holds the text `runner`, the TOML value of each text that
    the table of `runner` holds is a table. When the root table holds
    the text `runner`, each of those tables holds exactly one of the
    texts `adapter` and `match`. When the root table holds the text
    `runner`, each of those tables can hold the text `settings`. When
    the root table holds the text `runner`, each of those tables holds
    no other text. In each table that is the TOML value of a text that
    the table of `runner` holds, the TOML value of `adapter` is a table
    that holds the texts `sha256` and `license`, and no other text. In
    that table of `adapter`, the TOML value of `sha256` is a TOML string
    whose text fits the hash form. In that table of `adapter`, the TOML
    value of `license` is a TOML string. In each table that is the TOML
    value of a text that the table of `runner` holds, the TOML value of
    `match` is a table. In each table that is the TOML value of a text
    that the table of `runner` holds, the TOML value of `settings` is a
    table whose TOML values are each a TOML string, a TOML boolean, or a
    TOML array of TOML strings.

The spec version of a valid descriptor is the text of the TOML string of
`sinter-spec` in the root table of the valid descriptor. The name of a
valid descriptor is the text of the TOML string of `name` in the root
table of the valid descriptor. The release number of a valid descriptor
is the text of the TOML string of `version` in the root table of the
valid descriptor. The license of a valid descriptor is the text of the
TOML string of `license` in the root table of the valid descriptor. The
name separator of a valid descriptor is the text of the TOML string of
`name-separator` in the root table of the valid descriptor. By the
descriptor, its spec version names the oldest version of the
specifications of Sinter that the pack needs. By the descriptor, its
license is the license of the descriptor and of the query files of the
pack.

#### 5.1.7 Comment sigils

@term comment-sigil=v1
@cites {
    data-forms#{root-table=v1, toml-value=v1},
    text#{text=v1, line=v1, code-span=v1},
    #{pack=v1, valid-descriptor=v1, reading-of-a-text=v1},
}

The comment sigils of a valid descriptor are texts that, by the
descriptor, open a comment, close a comment, or start a line of a block
comment after its first line, in the files that a program reads with the
pack. A valid descriptor gives comment sigils of three kinds, from the
table of `comments` in its root table:

- Each line sigil, such as `//`, opens a comment that ends at the end of
  its line. When the table of `comments` holds the text `line`, the line
  sigils are the texts of the TOML strings of the TOML array of `line`,
  in the order of that array. When the table of `comments` does not hold
  the text `line`, the valid descriptor gives no line sigils.
- Each block pair is an opening sigil and a closing sigil, such as `/*`
  and `*/`. When the table of `comments` holds the text `block`, the
  block pairs are one block pair for each TOML array of the TOML array
  of `block`, in the order of the TOML array of `block`. When the table
  of `comments` holds the text `block`, each of those TOML arrays gives
  one block pair whose opening sigil is the text of the first TOML
  string of that TOML array and whose closing sigil is the text of the
  second TOML string of that TOML array. When the table of `comments`
  does not hold the text `block`, the valid descriptor gives no block
  pairs.
- Each inner sigil, such as `*`, can start a line of a block comment
  after its first line. When the table of `comments` holds the text
  `inner`, the inner sigils are the texts of the TOML strings of the
  TOML array of `inner`, in the order of that array. When the table of
  `comments` does not hold the text `inner`, the valid descriptor gives
  no inner sigils.

#### 5.1.8 Foreign tag words

@term foreign-tag-word=v1
@cites {
    identifiers#{tag-word=v1},
    data-forms#{root-table=v1, toml-value=v1},
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
    #{pack=v1, valid-descriptor=v1},
}

When the root table of a valid descriptor holds the text `foreign-tags`,
the foreign tag words of the valid descriptor are, for each TOML string
of the TOML array of `foreign-tags`, in the order of that array, the
text `@` followed by the text of that TOML string. Each foreign tag word
is a text that matches the production `tag-word`. By the descriptor, the
language of the pack, or a tool of that language, uses each foreign tag
word in comments with a meaning of its own, such as `@param`. A valid
descriptor whose root table does not hold the text `foreign-tags` gives
no foreign tag word.

#### 5.1.9 The grammars of a descriptor

@term descriptor-grammar=v1
@cites {data-forms#{root-table=v1, toml-value=v1}, text#{text=v1, code-span=v1}, #{valid-descriptor=v1}}

The grammars of a valid descriptor are, for each table of the TOML array
of `grammar` in the root table of the valid descriptor, in the order of
that array, one grammar of the descriptor. A grammar of the descriptor
has four values from its table. The name of the grammar is the text of
the TOML string of `name` in the table of the grammar. The hash of the
grammar is the text of the TOML string of `sha256` in the table of the
grammar. The license of the grammar is the text of the TOML string of
`license` in the table of the grammar. The file-name globs of the
grammar are the texts of the TOML strings of the TOML array of `names`
in the table of the grammar, in the order of that array.

#### 5.1.10 Test runners

@term test-runner=v1
@cites {
    ontology#{test=v1, test-evidence=v1},
    data-forms#{root-table=v1, toml-value=v1},
    text#{text=v1, code-span=v1},
    #{valid-descriptor=v1},
}

The test runners of a valid descriptor are, for each text that the table
of `runner` in the root table of the valid descriptor holds, one test
runner whose name is that text. By the descriptor, a test runner, such
as vitest, is a program that runs tests, gives a test result for each
test that the program runs, and writes report files. A valid descriptor
whose root table does not hold the text `runner` has no test runner. The
table of a test runner is the TOML value of the name of the test runner
in the table of `runner`. A test runner has these values from its table:

- When the table of a test runner holds the text `adapter`, the adapter
  hash of the test runner is the text of the TOML string of `sha256` in
  the table of `adapter`. When the table of a test runner holds the text
  `adapter`, the adapter license of the test runner is the text of the
  TOML string of `license` in the table of `adapter`.
- When its table holds the text `match`, its match table is the table of
  `match`.

#### 5.1.11 Runner settings

@term runner-setting=v1
@cites {data-forms#{toml-key-text=v1, toml-value=v1}, text#{text=v1, code-span=v1}, #{valid-descriptor=v1, test-runner=v1}}

A runner setting of a test runner is a name and a default value, for a
value that configuration can give for that test runner. The runner
settings of a test runner of a valid descriptor are, for each pair of
the table of `settings` in the table of that test runner, one runner
setting. For each such pair, the name of the runner setting is the text
of the TOML key of that pair. For each such pair, the default value of
the runner setting is the TOML value of that pair. A test runner whose
table does not hold the text `settings` has no runner setting. The type
of a runner setting is string when its default value is a TOML string,
boolean when its default value is a TOML boolean, and array of strings
when its default value is a TOML array.

#### 5.1.12 File grammars

@term file-grammar=v1
@cites {files#{path=v1, glob-fit=v1}, #{valid-descriptor=v1, descriptor-grammar=v1}}

For a valid descriptor and a valid path, the file grammar of that valid
path is the first grammar of the descriptor, in the order of the
grammars of the descriptor, that has a file-name glob that the last file
name of that valid path fits, where that file name is taken as a valid
path of one file name. When no grammar of the descriptor has such a
file-name glob, that valid path has no file grammar.

### 5.2 Descriptors as input

@req read-descriptor=v1
@cites {text#{conforming-program=v1, result=v1, byte-sequence=v1}, #{valid-descriptor=v1}}

When a conforming program gives a result for whether a byte sequence is
a valid descriptor, the program must give exactly one result: "valid"
when the byte sequence is a valid descriptor, and "invalid" when the
byte sequence is not a valid descriptor.

### 5.3 The values of a descriptor

@req give-descriptor-values=v1
@cites {
    data-forms#{toml-value=v1, toml-value-equality=v1},
    text#{conforming-program=v1},
    #{
        spec-version=v1, release-number=v1, valid-descriptor=v1,
        comment-sigil=v1, foreign-tag-word=v1, name-separator=v1,
        descriptor-grammar=v1, test-runner=v1, runner-setting=v1,
    },
}

When a conforming program gives one of these values of a valid
descriptor, it must give the value that the valid descriptor gives, with
each list that comes from a TOML array in its order, and no other value
instead of it: the spec version, the name, the release number, the
license, the name separator, the foreign tag words, the line sigils, the
block pairs, the inner sigils, the grammars, and, of each grammar, its
name, its hash, its license, and its file-name globs, the test runners,
and, of each test runner, its name, its adapter hash, its adapter
license, its match table, as a table that is equal to it, and its runner
settings, each with its name and, as a TOML value that is equal to it,
its default value.

### 5.4 No values of a byte sequence that is not a valid descriptor

@req omit-invalid-descriptor-values=v1
@cites {
    text#{conforming-program=v1, byte-sequence=v1},
    #{
        spec-version=v1, release-number=v1, valid-descriptor=v1,
        name-separator=v1, comment-sigil=v1, foreign-tag-word=v1,
        descriptor-grammar=v1, test-runner=v1, runner-setting=v1,
    },
}

For a byte sequence that is not a valid descriptor, a conforming program
must give none of these values: the spec version, the name, the release
number, the license, the name separator, the foreign tag words, the line
sigils, the block pairs, the inner sigils, and the grammars. For a byte
sequence that is not a valid descriptor, a conforming program must give
none of these values of a grammar: the name, the hash, the license, and
the file-name globs. For a byte sequence that is not a valid descriptor,
a conforming program must give no test runners. For a byte sequence that
is not a valid descriptor, a conforming program must give none of these
values of a test runner: the name, the adapter hash, the adapter
license, the match table, and the runner settings. For a byte sequence
that is not a valid descriptor, a conforming program must give neither
the name nor the default value of a runner setting.

### 5.5 No adapter values for a test runner with no adapter hash

@req omit-absent-adapter-values=v1
@cites {text#{conforming-program=v1}, #{valid-descriptor=v1, test-runner=v1}}

A conforming program must give no adapter hash and no adapter license
for a test runner of a valid descriptor that has no adapter hash.

### 5.6 No match table for a test runner with none

@req omit-absent-match-tables=v1
@cites {text#{conforming-program=v1}, #{valid-descriptor=v1, test-runner=v1}}

A conforming program must give no match table for a test runner of a
valid descriptor that has no match table.

### 5.7 The grammar of a file

@req give-file-grammars=v1
@cites {
    files#{path=v1},
    text#{conforming-program=v1},
    #{valid-descriptor=v1, descriptor-grammar=v1, file-grammar=v1},
}

When a conforming program gives a grammar of a valid descriptor as the
file grammar of a valid path that has a file grammar, the program must
give the file grammar of that valid path, and no other grammar.

### 5.8 No grammar for a file with no file grammar

@req omit-file-grammars=v1
@cites {
    files#{path=v1},
    text#{conforming-program=v1},
    #{valid-descriptor=v1, descriptor-grammar=v1, file-grammar=v1},
}

A conforming program must give no grammar of a valid descriptor as the
file grammar of a valid path that has no file grammar.

### 5.9 Conformance

A program conforms to the specification `descriptor` when it is a
[conforming program](sinter:text#conforming-program=v1) of this
specification.

The vectors of this specification are in the file
[`packs.descriptor.test-vectors.jsonl`](packs.descriptor.test-vectors.jsonl),
in the same folder as this design. The file is a test-vector set, in the
form that the specification
[`data-forms#test-vectors`](sinter:data-forms#test-vectors=v1) gives. No
group of this specification uses a need, so the forms of each group give
no need names.

Each subsection below gives the forms of one group: the requirements of
the group, and what the members `input`, `result`, and `values` of its
vectors stand for, each in a fixed form.

#### 5.9.1 Descriptors

@schema descriptor-vector=v1
@cites {
    data-forms#{
        hex-text=v1, json-value=v1, toml-value=v1, toml-key-text=v1,
        group-form-list=v1, vector-meaning=v1,
    },
    text#{
        conforming-program=v1, byte-sequence=v1, text=v1, result=v1,
        code-span=v1, code-point-order=v1,
    },
    #{
        valid-descriptor=v1, read-descriptor=v1,
        give-descriptor-values=v1, omit-invalid-descriptor-values=v1,
        omit-absent-adapter-values=v1, omit-absent-match-tables=v1,
        spec-version=v1, release-number=v1, name-separator=v1,
        comment-sigil=v1, foreign-tag-word=v1, descriptor-grammar=v1,
        test-runner=v1, runner-setting=v1,
    },
}

In `input` and `values`, a byte sequence is its hex text, as a string,
such as `"6e616d65"` for the four bytes of `name`. In `input` and
`values`, a text is a string of the characters of the text. A TOML value
of the kinds that the vectors use has one of these four forms. A TOML
string is an object with one member, `string`, whose value is the text
of the TOML string. A TOML boolean is an object with one member,
`boolean`, whose value is `true` or `false`. A TOML array is an object
with one member, `array`, whose value is an array of the forms of the
TOML values of that TOML array, in their order. A table is an object
with one member, `table`, whose value is an object with one member for
each pair of the table. For each pair of the table, the key of that
member is the text of the TOML key of the pair, and the value of that
member is the form of the TOML value of the pair.

The group `descriptors` holds the vectors that each give a byte sequence
and what a conforming program gives for that byte sequence as a
descriptor. The requirements of the group are `read-descriptor`,
`give-descriptor-values`, `omit-invalid-descriptor-values`,
`omit-absent-adapter-values`, and `omit-absent-match-tables`.

- `input`: the byte sequence.
- `result`: the result for whether the byte sequence is a valid
  descriptor, when a conforming program gives that result: "valid" when
  the byte sequence is a valid descriptor, and "invalid" when it is not.
- `values`: with "valid", an object with these members, for the values
  of the valid descriptor: `spec-version`, `name`, `release`, `license`,
  `name-separator`, `foreign-tag-words`, `line-sigils`, `inner-sigils`,
  `block-pairs`, `grammars`, and `runners`. The members `spec-version`,
  `name`, `release`, `license`, and `name-separator` are each a text.
  The members `foreign-tag-words`, `line-sigils`, and `inner-sigils` are
  each an array of texts, in order. The member `block-pairs` is an array
  with one array of two texts, the opening sigil and the closing sigil,
  for each block pair, in order. The member `grammars` is an array with
  one object for each grammar, in order. Each object for a grammar has
  the members `name`, `hash`, `license`, and `globs`. In each object for
  a grammar, `name`, `hash`, and `license` are each a text. In each
  object for a grammar, `globs` is an array of the file-name globs of
  that grammar, in order. The member `runners` is an array with one
  object for each test runner, in the code point order of the names of
  the test runners. Each object for a test runner has the member `name`,
  which is a text. When the test runner has an adapter hash, the object
  for that test runner has the members `adapter-hash` and
  `adapter-license`, which are each a text. When the test runner has a
  match table, the object for that test runner has the member `match`,
  which is the form of the match table of that test runner. Each object
  for a test runner has the member `settings`, which is an array with
  one object for each runner setting of that test runner, in the code
  point order of the names of the runner settings. Each object for a
  runner setting has the members `name` and `default`. In each object
  for a runner setting, `name` is a text. In each object for a runner
  setting, `default` is the form of the default value of that runner
  setting. With "invalid", the empty object, `{}`.

With "valid", a conforming program gives each of these values as the
value of the valid descriptor that it names, and no other value for it,
when it gives that value. An absent member `adapter-hash`,
`adapter-license`, or `match` means that a conforming program gives no
such value for the test runner. The order of the elements of `runners`,
and of `settings` in each test runner, is not a value that a conforming
program gives, so a program that runs the vectors compares the elements
of `runners`, and the elements of `settings` in each test runner, as
sets. With `{}`, a conforming program gives none of these values.

```
{"form":"#descriptor-vector=v1","group":"descriptors","input":"73696e7465722d73706563203d2022312e30220a6e616d65203d202278220a76657273696f6e203d2022302e312e30220a6c6963656e7365203d20224d4954220a6e616d652d736570617261746f72203d20223a3a220a0a6772616d6d6172203d205b5d0a0a5b636f6d6d656e74735d0a0a","note":"the array grammar of the root table holds one or more tables","result":"invalid","values":{}}
```

#### 5.9.2 File grammars

@schema file-grammar-vector=v1
@cites {
    files#{path=v1},
    data-forms#{
        hex-text=v1, json-value=v1, group-form-list=v1, vector-meaning=v1,
    },
    text#{conforming-program=v1, byte-sequence=v1, text=v1, code-span=v1},
    #{
        descriptor-vector=v1, valid-descriptor=v1, descriptor-grammar=v1,
        file-grammar=v1, give-file-grammars=v1, omit-file-grammars=v1,
    },
}

In `input` and `values`, a byte sequence is its hex text, as a string,
as `descriptor-vector` gives. In `input` and `values`, a text is a
string of the characters of the text, as `descriptor-vector` gives.

The group `file-grammars` holds the vectors that each give a valid
descriptor, a valid path, and the file grammar of that valid path. The
requirements of the group are `give-file-grammars` and
`omit-file-grammars`.

- `input`: an object with two members: `descriptor`, the byte sequence
  of a valid descriptor, and `path`, the valid path, as a text.
- `result`: no vector of the group has this member.
- `values`: when the valid path has a file grammar, an object with one
  member, `grammar`, the name of that file grammar, as a text. When the
  valid path has no file grammar, the empty object, `{}`.

When a conforming program gives a grammar as the file grammar of the
valid path, the program gives the grammar whose name `grammar` holds,
and no other grammar as the file grammar of the valid path. With `{}`, a
conforming program gives no grammar as the file grammar of the valid
path.

## 6. Runner adapters
@spec adapters=v1

When a conforming program decides whether a byte sequence is a valid
adapter, the program gives "valid" when the byte sequence is a valid
adapter in that decision, and the program gives "invalid" when the byte
sequence is not a valid adapter in that decision. When a conforming
program gives the result of a call of a function of an adapter with a
request and a report content, the program gives "recognised", "not
recognised", or "failed" for the function recognise, and the program
gives "bound" or "failed" for the function bind. When a conforming
program makes a call of a function of a byte sequence as the adapter of
a test runner of a valid descriptor, under a valid binding of
`runner-settings` for that test runner, the request of the call is the
request of that function for that test runner, that binding, the report
name, and, for the function bind, the root and the test entries. A
conforming program runs the code of an adapter only in an instance of
the adapter. The program ends that code in each call and in each
decision whether a byte sequence is a valid adapter.

### 6.1 Definitions

#### 6.1.1 Instances of adapters

@term adapter-instance=v1
@cites {wasm-core/2.0, #{webassembly-module=v1}}

An instance of an adapter of a WebAssembly module, for a program, is a
new instance of that module that the program makes with no import, and
in which code runs as the WebAssembly Core Specification 2.0 defines its
execution, with the program as its embedder. An instantiation or an
invocation fails when that instantiation or invocation traps, or when
the execution of its code, as the WebAssembly Core Specification 2.0
defines it, does not terminate.

#### 6.1.2 Adapter modules

@schema adapter-module=v1
@cites {
    wasm-core/2.0,
    text#{byte-sequence=v1, code-span=v1},
    #{webassembly-module=v1},
}

An adapter module is a byte sequence that meets each of these
conditions:

1. It is a WebAssembly module.
2. The module has no import.
3. The module exports `memory` as a memory, `sinter_interface` as a
   function of the type `[] -> [i32]`, `sinter_alloc` as a function of
   the type `[i32] -> [i32]`, `sinter_recognise` as a function of the
   type `[i32 i32 i32 i32] -> [i64]`, and `sinter_bind` as a function of
   the type `[i32 i32 i32 i32] -> [i64]`. The module can export other
   names.

By the interface, when `sinter_alloc` can reserve the given number of
bytes in the memory, `sinter_alloc` reserves those bytes and gives an
address other than 0: the address of the first of those bytes, and an
address other than 0 also when the given number of bytes is 0. By the
interface, when `sinter_alloc` cannot reserve the given number of bytes
in the memory, `sinter_alloc` gives 0.

#### 6.1.3 Valid adapters

@atom valid-adapter=v1
@cites {
    wasm-core/2.0,
    text#{
        byte-sequence=v1, code-span=v1, conforming-program=v1,
        result=v1,
    },
    #{adapter-module=v1, adapter-instance=v1},
}

A byte sequence is a valid adapter, in one decision of a program whether
the byte sequence is a valid adapter, when, and only when, the byte
sequence meets each of these conditions:

1. The byte sequence is an adapter module.
2. In a new instance of an adapter of the module, for that program, the
   decision runs the instantiation and then one invocation of
   `sinter_interface`, and nothing else in that instance. The
   instantiation and the invocation do not fail. The invocation gives
   the `i32` value 1, which is the version of the interface.

In a decision of a program whether a byte sequence is a valid adapter,
the result is "valid" when the byte sequence is a valid adapter in that
decision, and "invalid" when it is not.

#### 6.1.4 Test entries

@term test-entry=v1
@cites {
    files#{path=v1},
    text#{
        text=v1, result=v1, whole-number=v1, run=v1, span=v1, position=v1,
        line-number=v1,
    },
    #{
        node-run=v1, test-node=v1, test-name=v1, test-label=v1,
        reading-of-a-text=v1, adapter-call=v1,
    },
}

A test entry is a test entry id, which is a text; a path, which is a
valid path; a first line and a last line, which are whole numbers; a
kind, which is test case or test suite; a name path, which is a sequence
of names, each a sequence of pieces; and test labels, which are a finite
set of texts. The test entry id names the test entry in a call. When a
reading with the result "parsed" of a text, as the text of a file at a
valid path p, gives a test node, and t is a text, the test entry of that
test node with the test entry id t has the test entry id t and the path
p. The first line of that test entry is the line number of the start of
the run of that test node, as a span of the text. The last line of that
test entry is the line number of the end of the run of that test node,
as a span of the text. The kind of that test entry is test case when
that test node is a test case, and test suite when that test node is a
test suite. The name path of that test entry is the name path of that
test node. The test labels of that test entry are the test labels of
that test node.

#### 6.1.5 Requests

@schema adapter-request=v1
@cites {
    data-forms#{json-value=v1, canonical-byte-sequence=v1, toml-value=v1},
    text#{text=v1, byte-sequence=v1, code-span=v1, code-point-order=v1},
    #{
        valid-descriptor=v1, test-runner=v1, runner-setting=v1,
        runner-settings=v1, runner-setting-value=v1, test-node=v1,
        test-entry=v1, test-name=v1, test-label=v1, adapter-call=v1,
    },
}

This definition is for a test runner of a valid descriptor, a valid
binding of `runner-settings` for that test runner, a report name, which
is a text, such as the path of a report file as a person gave it, and,
for the function bind, a root, which is a text, such as the absolute
path of the root of a repository, and test entries whose test entry ids
are each a different text. The request object of the function recognise
is a JSON object with these members, and no other member:

- `interface`: the integer 1.
- `runner`: the name of the test runner, as a string.
- `settings`: an object with one member for each runner setting of the
  test runner. The key of that member is the name of that runner
  setting. The value of that member is the value of that runner setting
  under the binding. When the value of that runner setting is a TOML
  string, the value of that member is a string of the text of that TOML
  string. When the value of that runner setting is a TOML boolean, the
  value of that member is a boolean. When the value of that runner
  setting is a TOML array, the value of that member is an array with a
  string of the text of each TOML string of that TOML array, in the
  order of those TOML strings.
- `report`: the report name, as a string.

The request object of the function bind has the same members as the
request object of the function recognise, the member `root`, and the
member `tests`, and no other member. The value of `root` is the root, as
a string. The value of `tests` is an array with one object for each test
entry, in the code point order of the test entry ids of the test
entries. Each object has these members, and no other member:

- `id` and `path`: the test entry id and the path of the test entry,
  each as a string.
- `line` and `eline`: the first line and the last line of the test
  entry, each as an integer.
- `suite`: true when the kind of the test entry is test suite, and false
  when the kind of the test entry is test case.
- `names`: an array with one array for each name of the name path of the
  test entry, in the order of the names of that name path. The array of
  a name has one object for each piece of that name, in the order of the
  pieces of that name. The object of a piece has one member, whose key
  is `text` for a text piece and `placeholder` for a placeholder, and
  whose value is the text of the piece, as a string.
- `labels`: an array with a string of each test label of the test entry,
  in code point order.

The request of a call of the function recognise or of the function bind
is the canonical byte sequence of the request object of that function.

#### 6.1.6 Calls

@term adapter-call=v1
@cites {
    wasm-core/2.0,
    text#{byte-sequence=v1, byte=v1, whole-number=v1, code-span=v1},
    #{webassembly-module=v1, adapter-instance=v1, valid-adapter=v1},
}

A program makes a call with a byte sequence as the adapter of the call,
one of the two functions recognise and bind, a byte sequence as the
request of the call, and a byte sequence as the report content of the
call, such as the content of a report file. For the function bind, the
program also makes the call with the test entry ids of the call, which
are a finite set of texts. The export of the function recognise is
`sinter_recognise`, and the export of the function bind is
`sinter_bind`. A call uses one decision of the program whether the
adapter of the call is a valid adapter. An earlier decision of the
program can serve. When that decision makes an instance, the instance of
that decision is not the instance of the steps of the call. When the
adapter of the call is not a valid adapter in that decision, the call
fails. Otherwise, the call runs these steps in a new instance of an
adapter of the module of the adapter of the call, for that program. When
one of these steps fails, the call fails. In that instance, the program
makes only the instantiation and the invocations of steps 2 to 4, in
that order. In that instance, the program changes no byte of the memory
of the instance other than by the writes of steps 2 and 3. The memory of
the instance is its memory, which it exports as `memory`, and the size
of that memory is its number of bytes when a step reads it.

1. The instantiation of the module.
2. An invocation of `sinter_alloc` with the `i32` value whose bits are
   those of the number of bytes of the request. The `i32` value that it
   gives, taken as a whole number from 0 to 4,294,967,295, is the
   address of the request. The call fails when that address is 0, or
   when that address together with the number of bytes of the request is
   more than the size of the memory of the instance. Otherwise, the
   bytes of the request are put into that memory, in their order, from
   that address on.
3. An invocation of `sinter_alloc` with the `i32` value whose bits are
   those of the number of bytes of the report content. The address of
   the report content comes from the value that it gives, in the same
   way as the address of the request, and the call fails under the same
   conditions. Otherwise, the bytes of the report content, unchanged,
   are put into the memory of the instance, in their order, from that
   address on.
4. An invocation of the export of the function with the four `i32`
   values whose bits are those of the address of the request, of the
   number of bytes of the request, of the address of the report content,
   and of the number of bytes of the report content. The `i64` value
   that it gives, taken as a whole number v from 0 to
   18,446,744,073,709,551,615, gives an address, which is the
   whole-number quotient of v divided by 4,294,967,296, and a length,
   which is the remainder. The call fails when that address together
   with that length is more than the size of the memory of the instance.
   Otherwise, the response of the call is the byte sequence of the
   length bytes of that memory from that address on, in their order.

#### 6.1.7 Adapter responses

@schema adapter-response=v1
@cites {
    data-forms#{json-value=v1, json-value-of-a-byte-sequence=v1},
    text#{byte-sequence=v1, line-feed=v1, code-span=v1},
}

The JSON value of a response is the JSON value of the response as a byte
sequence. An adapter response is a byte sequence that is a recognise
response, a bind response, or an error response:

- A recognise response is a byte sequence whose JSON value is an object
  with exactly one member, `recognised`, whose value is a boolean.
- A bind response is a byte sequence whose JSON value is an object that
  has exactly the members `results`, `bindings`, and `warnings`, and
  these rules hold:
  1. The value of `results` is an array of result objects. A result
     object is an object that has the members `name` and `status`, can
     have the members `file`, `line`, and `ms`, and has no other member.
     The value of `name` is a string. The value of `status` is the
     string `pass`, `fail`, `error`, or `skip`. The value of `file` is a
     string. The value of `line` is an integer of 1 or more. The value
     of `ms` is an integer of 0 or more.
  2. The value of `bindings` is an array of binding objects. A binding
     object is an object that has exactly the members `result`, `test`,
     and `reason`. The value of `result` is an integer of 0 or more that
     is less than the number of the elements of the value of `results`.
     The value of `test` is a string. The value of `reason` is a string
     that holds no line feed.
  3. No two binding objects have the same value of `result` and the same
     value of `test`.
  4. The value of `warnings` is an array of strings.
- An error response is a byte sequence whose JSON value is an object
  with exactly one member, `error`, whose value is a string.

#### 6.1.8 The results of calls

@atom call-result=v1
@cites {
    ontology#{test=v1, test-evidence=v1},
    data-forms#{json-value=v1, index=v1},
    text#{text=v1, result=v1, whole-number=v1, code-span=v1},
    #{
        test-runner=v1, adapter-request=v1, adapter-call=v1,
        adapter-response=v1, test-entry=v1,
    },
}

When a call of the function recognise gives a response that is a
recognise response and the value of `recognised` in the JSON value of
that response is true, the result of the call is "recognised". When a
call of the function recognise gives a response that is a recognise
response and the value of `recognised` in the JSON value of that
response is false, the result of the call is "not recognised". In each
other case, the result of a call of the function recognise is "failed".

When a call of the function bind gives a response that is a bind
response, and the value of `test` of each binding object in the value of
`bindings` of the JSON value of that response is one of the test entry
ids of the call, the result of the call is "bound". In each other case,
the result of a call of the function bind is "failed".

A call with the result "bound" gives its test results, its binding
objects, and its warnings. The test results of that call are the
elements of the value of `results`, in the order of those elements. Each
test result has a name, which is the value of `name`, and a status,
which is the value of `status`. When the result object has the member
`file`, the test result has a file, which is the value of `file`. When
the result object has the member `line`, the test result has a line,
which is the value of `line`. When the result object has the member
`ms`, the test result has a duration in whole milliseconds, which is the
value of `ms`. By the adapter, each test result of a call is a test
result that the report content holds: what a test runner gave for one
test that it ran. The binding objects of a call with the result "bound"
are the elements of the value of `bindings`, in the order of those
elements. Each binding object has a test result, which is the element of
the value of `results` whose index is 1 more than the value of `result`.
Each binding object has a test entry id, which is one of the test entry
ids of the call and is the value of `test`. Each binding object has a
reason, which is the value of `reason`. The warnings of a call with the
result "bound" are the texts of the value of `warnings`, in the order of
those texts. A call with the result "failed" whose response is an error
response gives the value of `error` in the JSON value of that response
as the error text of the adapter.

By the interface, the function recognise says whether the report content
is the content of a report file of the test runner that the member
`runner` of the request names. The test results of a call stand in the
order of the report content. A test result has no file, no line, or no
duration when the report content gives none. The reason of a binding
object says why the test result of that binding object binds to the test
entry of that binding object. A warning is a text for the person who
runs the program.

### 6.2 The validation of adapters

@req validate-adapters=v1
@cites {text#{conforming-program=v1, result=v1, byte-sequence=v1}, #{valid-adapter=v1}}

When a conforming program gives a result for whether a byte sequence is
a valid adapter, the program must give exactly one result: "valid" when
the byte sequence is a valid adapter in that decision, and "invalid"
when the byte sequence is not a valid adapter in that decision.

### 6.3 The requests of calls

@req give-requests=v1
@cites {
    text#{conforming-program=v1, byte-sequence=v1, text=v1},
    #{
        valid-descriptor=v1, test-runner=v1, runner-settings=v1,
        adapter-request=v1, adapter-call=v1, test-entry=v1,
    },
}

When a conforming program makes a call of the function recognise of a
byte sequence as the adapter of a test runner of a valid descriptor,
under a valid binding of `runner-settings` for that test runner, and for
a report name, the program must make the call with the request of the
function recognise for that test runner, that binding, and that report
name as the request of the call, and with no other byte sequence as that
request. When a conforming program makes a call of the function bind of
a byte sequence as the adapter of a test runner of a valid descriptor,
under a valid binding of `runner-settings` for that test runner, for a
report name, for a root, and for test entries whose test entry ids are
each a different text, the program must make the call with the request
of the function bind for that test runner, that binding, that report
name, that root, and those test entries as the request of the call, and
with no other byte sequence as that request. In that call of the
function bind, the program must also make the call with the test entry
ids of those test entries as the test entry ids of the call.

### 6.4 The results of calls

@req give-call-results=v1
@cites {
    text#{conforming-program=v1, result=v1, byte-sequence=v1},
    #{adapter-call=v1, call-result=v1},
}

When a conforming program gives a result of a call that the program
makes of a function of a byte sequence as an adapter, with a request and
a report content, the program must give exactly one result: the result
of that call. The result of that call is "recognised", "not recognised",
or "failed" for the function recognise, and "bound" or "failed" for the
function bind.

### 6.5 The values of the results of calls

@req give-call-values=v1
@cites {
    ontology#{test-evidence=v1},
    text#{conforming-program=v1, result=v1, text=v1, byte-sequence=v1},
    #{adapter-call=v1, call-result=v1},
}

When a conforming program makes a call of a function of a byte sequence
as an adapter, with a request and a report content, and gives, with the
result of that call, the test results, the binding objects, the
warnings, or the error text of the adapter of that call, the program
must give those that the call gives, in their order, and no other
instead.

### 6.6 No values of calls that do not bind

@req omit-call-values=v1
@cites {
    ontology#{test-evidence=v1},
    text#{conforming-program=v1, result=v1, byte-sequence=v1},
    #{adapter-call=v1, call-result=v1},
}

When a conforming program makes a call of a function of a byte sequence
as an adapter, with a request and a report content, and the result of
that call is not "bound", the program must give no test results, no
binding objects, and no warnings of that call.

### 6.7 Error texts of the adapter

@req omit-adapter-error-texts=v1
@cites {
    text#{conforming-program=v1, result=v1, byte-sequence=v1},
    #{adapter-call=v1, call-result=v1},
}

For a call that a conforming program makes of a function of a byte
sequence as an adapter, with a request and a report content, the program
must give an error text of the adapter only when the result of that call
is "failed" and the call gives that error text.

### 6.8 Where the code of an adapter runs

@req isolate-adapters=v1
@cites {
    text#{conforming-program=v1, byte-sequence=v1},
    #{webassembly-module=v1, adapter-instance=v1},
}

A conforming program must run the code of each byte sequence that the
program uses as an adapter only in an instance of an adapter of the
module of that byte sequence.

### 6.9 Code of adapters that ends

@req end-adapter-code=v1
@cites {
    text#{conforming-program=v1, byte-sequence=v1},
    #{adapter-instance=v1, adapter-call=v1, valid-adapter=v1},
}

A conforming program must end the code of an adapter that it runs, in
each call and in each decision whether a byte sequence is a valid
adapter.

### 6.10 Conformance

A program conforms to the specification `adapters` when it is a
[conforming program](sinter:text#conforming-program=v1) of this
specification. The requirement `isolate-adapters` has no vectors.

The vectors of this specification are in the file
[`packs.adapters.test-vectors.jsonl`](packs.adapters.test-vectors.jsonl),
in the same folder as this design. The file is a test-vector set, in the
form that the specification
[`data-forms#test-vectors`](sinter:data-forms#test-vectors=v1) gives. No
group of this specification uses a need, so the forms of each group give
no need names.

Each subsection below gives the forms of one group: the requirements of
the group, and what the members `input`, `result`, and `values` of its
vectors stand for, each in a fixed form.

#### 6.10.1 Adapters

@schema adapter-vector=v1
@cites {
    data-forms#{
        hex-text=v1, json-value=v1, group-form-list=v1, vector-meaning=v1,
    },
    text#{
        conforming-program=v1, byte-sequence=v1, text=v1, result=v1,
        code-span=v1,
    },
    #{valid-adapter=v1, validate-adapters=v1, end-adapter-code=v1},
}

In `input` and `values`, a byte sequence is its hex text, as a string,
and a text is a string of the characters of the text.

The group `adapters` holds the vectors that each give a byte sequence
and what a conforming program gives for that byte sequence when the
conforming program decides whether the byte sequence is a valid adapter.
The requirements of the group are `validate-adapters` and
`end-adapter-code`.

- `input`: the byte sequence.
- `result`: the result of the decision whether the byte sequence is a
  valid adapter, when a conforming program gives that result: "valid"
  when the byte sequence is a valid adapter in that decision, and
  "invalid" when the byte sequence is not.
- `values`: no vector of the group has this member.

```
{"form":"#adapter-vector=v1","group":"adapters","input":"0061736d01000000","note":"a module with no export","result":"invalid"}
```

#### 6.10.2 Requests

@schema request-vector=v1
@cites {
    data-forms#{
        hex-text=v1, json-value=v1, toml-value=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    text#{
        conforming-program=v1, byte-sequence=v1, text=v1,
        utf-8-encoding=v1, code-span=v1,
    },
    #{
        adapter-vector=v1, valid-descriptor=v1, test-runner=v1,
        runner-setting=v1, runner-settings=v1, runner-setting-value=v1,
        test-entry=v1, adapter-request=v1, adapter-call=v1,
        give-requests=v1,
    },
}

In `input` and `values`, a byte sequence is its hex text, as a string,
and a text is a string of the characters of the text, as
`adapter-vector` gives.

The group `requests` holds the vectors that each give the things of a
call of a function of the adapter of a test runner, and the request of
that call. The requirement of the group is `give-requests`.

- `input`: an object with these members: `function`, `runner`,
  `settings`, `report`, and, for the function bind only, `root` and
  `tests`. The value of `function` is the text `recognise` or `bind`.
  The value of `runner` is the name of the test runner, as a text. The
  value of `settings` is an object with one member for each runner
  setting of the test runner. For each runner setting of the test
  runner, the key of the member for that runner setting is the name of
  that runner setting. For each runner setting of the test runner, the
  value of the member for that runner setting is the value of that
  runner setting under the binding: a string for a TOML string, a
  boolean for a TOML boolean, and an array of strings for a TOML array
  of TOML strings. The value of `report` is the report name, as a text.
  For the function bind only, the value of `root` is the root, as a
  text. For the function bind only, the value of `tests` is an array
  with one object for each test entry, in any order. The object of a
  test entry has the members `id`, `path`, `line`, `eline`, `suite`,
  `names`, and `labels`, in the forms that the request object gives
  them, except that `labels` can be in any order. The call is for a test
  runner of a valid descriptor, under a valid binding of
  `runner-settings`. The name of that test runner is the value of
  `runner`. Under that binding, the runner settings of that test runner
  and their values are exactly the members of `settings`.
- `result`: no vector of the group has this member.
- `values`: an object with one member, `request`: the text whose UTF-8
  encoding is the request of the call.

A conforming program makes the call with the UTF-8 encoding of the text
of `request` as the request of the call, and with no other byte
sequence as that request.

```
{"form":"#request-vector=v1","group":"requests","input":{"function":"recognise","report":"out/junit.xml","runner":"vitest","settings":{}},"values":{"request":"{\"interface\":1,\"report\":\"out/junit.xml\",\"runner\":\"vitest\",\"settings\":{}}"}}
```

#### 6.10.3 Responses

@schema response-vector=v1
@cites {
    ontology#{test-evidence=v1},
    data-forms#{
        hex-text=v1, json-value=v1, index=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    text#{
        conforming-program=v1, byte-sequence=v1, text=v1, result=v1,
        code-span=v1,
    },
    #{
        adapter-vector=v1, valid-adapter=v1, adapter-call=v1,
        adapter-response=v1, call-result=v1, test-entry=v1,
        give-call-results=v1, give-call-values=v1, omit-call-values=v1,
        omit-adapter-error-texts=v1,
    },
}

In `input` and `values`, a byte sequence is its hex text, as a string,
and a text is a string of the characters of the text, as
`adapter-vector` gives.

The group `responses` holds the vectors that each give the function of a
call of a valid adapter, the test entry ids of the call, and the
response that the call gives, and what a conforming program gives for
the call. The requirements of the group are `give-call-results`,
`give-call-values`, `omit-call-values`, and `omit-adapter-error-texts`.

- `input`: an object with these members: `function`, the text
  `recognise` or `bind`; `ids`, for the function bind only, an array of
  the test entry ids of the call, as texts; and `response`, the byte
  sequence of the response.
- `result`: the result of the call, when a conforming program gives a
  result for it: "recognised", "not recognised", or "failed" for the
  function recognise, and "bound" or "failed" for the function bind. The
  call is a call of an adapter that is valid in the decision that the
  call uses. In that call, the invocation of the export of the function
  gives the response, with no failure before that invocation.
- `values`: with "bound", an object with three members: `results`,
  `bindings`, and `warnings`. With "bound", the value of `results` is an
  array with one object for each test result of the call, in order. Each
  object in `results` has the members `name` and `status`, each a text.
  When a test result of the call has a file, the object for that test
  result in `results` has the member `file`, a text. When a test result
  of the call has a line, the object for that test result in `results`
  has the member `line`, an integer. When a test result of the call has
  a duration, the object for that test result in `results` has the
  member `ms`, an integer. With "bound", the value of `bindings` is an
  array with one object for each binding object of the call, in order.
  The object in `bindings` for a binding object has the members
  `result`, `test`, and `reason`. In that object, the value of `result`
  is 1 less than the index of the test result of that binding object in
  `results`, as an integer. In that object, the values of `test` and
  `reason` are each a text. With "bound", the value of `warnings` is an
  array of the warnings of the call, as texts, in order. With "failed",
  when the call gives an error text of the adapter, an object with one
  member, `error`, that error text, as a text; otherwise the empty
  object, `{}`. With "recognised" and "not recognised", the empty
  object, `{}`.

When a conforming program gives the test results, the binding objects,
the warnings, or the error text of the adapter of the call, it gives
those of `values`, and no other instead. With `{}`, it gives none of
these.

```
{"form":"#response-vector=v1","group":"responses","input":{"function":"recognise","response":"7b227265636f676e69736564223a747275657d"},"result":"recognised","values":{}}
```

#### 6.10.4 Calls

@schema call-vector=v1
@cites {
    ontology#{test-evidence=v1},
    data-forms#{
        hex-text=v1, json-value=v1, group-form-list=v1, vector-meaning=v1,
    },
    text#{
        conforming-program=v1, byte-sequence=v1, text=v1, result=v1,
        code-span=v1,
    },
    #{
        adapter-vector=v1, response-vector=v1, adapter-call=v1,
        call-result=v1, test-entry=v1, give-call-results=v1,
        give-call-values=v1, omit-call-values=v1,
        omit-adapter-error-texts=v1, end-adapter-code=v1,
    },
}

In `input` and `values`, a byte sequence is its hex text, as a string,
and a text is a string of the characters of the text, as
`adapter-vector` gives.

The group `calls` holds the vectors that each give the things of a call
and what a conforming program gives for the call. Those things of a call
are a byte sequence as the adapter, the function, the request, the
report content, and, for the function bind, the test entry ids of the
call. The requirements of the group are `give-call-results`,
`give-call-values`, `omit-call-values`, `omit-adapter-error-texts`, and
`end-adapter-code`.

- `input`: an object with these members: `adapter`, the byte sequence
  of the adapter; `function`, the text `recognise` or `bind`; `request`,
  the byte sequence of the request; `report-content`, the byte sequence
  of the report content; and `ids`, for the function bind only, an array
  of the test entry ids of the call, as texts.
- `result`: the result of the call, when a conforming program gives a
  result for it: "recognised", "not recognised", or "failed" for the
  function recognise, and "bound" or "failed" for the function bind.
- `values`: in the form of the member `values` of the group
  `responses`.

When a conforming program gives the test results, the binding objects,
the warnings, or the error text of the adapter of the call, it gives
those of `values`, and no other instead. With `{}`, it gives none of
these.

```
{"form":"#call-vector=v1","group":"calls","input":{"adapter":"0061736d01000000011a056000017f60017f017f60047f7f7f7f017e60017e017f600000030504000102020503010001074d05066d656d6f727902001073696e7465725f696e7465726661636500000c73696e7465725f616c6c6f6300011073696e7465725f7265636f676e69736500020b73696e7465725f62696e6400030a1b04040041010b040041000b0a0042938080808080010b040042000b0b1a01004180080b137b227265636f676e69736564223a747275657d","function":"recognise","report-content":"3c74657374737569746573206e616d653d22766974657374207465737473223e3c2f746573747375697465733e","request":"7b22696e74657266616365223a312c227265706f7274223a226f75742f6a756e69742e786d6c222c2272756e6e6572223a22766974657374222c2273657474696e6773223a7b7d7d"},"note":"sinter_alloc gives the address 0","result":"failed","values":{}}
```

## 7. Requirements

### 7.1 Whether packs are well named

@req decide-well-named-packs=v1
@cites {
    text#{conforming-program=v1, result=v1},
    #{pack=v1, well-named-pack=v1},
}

When a conforming program gives a result for whether a pack is well
named, it must give exactly one result: "well named" when the pack is
well named, and "not well named" when it is not.

### 7.2 The files of a pack

@req give-pack-files=v1
@cites {
    files#{path=v1},
    text#{conforming-program=v1, text=v1},
    #{pack=v1, well-named-pack=v1},
}

When a conforming program gives the valid paths of the files of a
well-named pack, it must give the valid path of each file of the pack,
and no other text as the valid path of a file of the pack.

### 7.3 The contents of the files of a pack

@req give-pack-file-contents=v1
@cites {
    text#{conforming-program=v1, byte-sequence=v1},
    #{pack=v1},
}

When a conforming program gives the content of a file of a pack, it
must give that content, and no other byte sequence as that content.

### 7.4 Pack listings as output

@req give-pack-listings=v1
@cites {
    text#{conforming-program=v1, text=v1},
    #{pack=v1, well-named-pack=v1, pack-hash=v1},
}

When a conforming program gives the pack listing of a pack that has a
pack listing, it must give the pack listing of that pack, and no other
text, as the pack listing of that pack.

### 7.5 No pack listing for a pack that has none

@req omit-pack-listings=v1
@cites {
    text#{conforming-program=v1},
    #{pack=v1, pack-hash=v1},
}

A conforming program must give no text as the pack listing of a pack
that has no pack listing.

### 7.6 Pack hashes as output

@req give-pack-hashes=v1
@cites {
    text#{conforming-program=v1, text=v1},
    #{pack=v1, well-named-pack=v1, pack-hash=v1},
}

When a conforming program gives a pack hash for a pack that has a pack
hash, it must give the pack hash of that pack, and no other text, as the
pack hash of that pack.

### 7.7 No pack hash for a pack that has none

@req omit-pack-hashes=v1
@cites {
    text#{conforming-program=v1},
    #{pack=v1, pack-hash=v1},
}

A conforming program must give no text as the pack hash of a pack that
has no pack hash.

### 7.8 The validation of packs

@req validate-packs=v1
@cites {
    wasm-core/2.0,
    text#{conforming-program=v1, result=v1},
    #{
        pack=v1, valid-pack=v1, webassembly-module=v1, usable-grammar=v1,
        query-language=v1, query-file=v1, parse-tree=v1,
    },
}

When a conforming program gives a result for whether a pack is valid,
the program must give exactly one result: "valid" or "invalid". When the
program gives that result for a pack that is not valid, the program must
give "invalid". When the program gives that result for a valid pack, the
program must give "valid", except that the program can give "invalid" in
two cases. First, when the program gives that result, the program can
give "invalid" when the content of the file of a grammar of the pack is
a WebAssembly module with an import that the program does not provide.
Second, when the program gives that result, the program can give
"invalid" when a query file of the pack holds a pattern that, without
the predicates of that pattern, matches no part of any parse tree that
the language of the grammar of that query file can give. The result
"invalid" in either of those two cases is a choice of the program in a
decision whether a pack is valid.

### 7.9 The values of the descriptor of a valid pack

@req give-pack-descriptor-values=v1
@cites {
    data-forms#{toml-value=v1, toml-value-equality=v1},
    text#{conforming-program=v1},
    #{
        pack=v1, valid-pack=v1, valid-descriptor=v1, spec-version=v1,
        release-number=v1,
        name-separator=v1, comment-sigil=v1, foreign-tag-word=v1,
        descriptor-grammar=v1, test-runner=v1, runner-setting=v1,
    },
}

When a conforming program gives a value of the descriptor of a valid
pack, it must give the value that the valid descriptor that is the
content of the file `pack.toml` of that pack gives, a match table or a
default value as a TOML value that is equal to it, and no other value
instead of it.

### 7.10 No reading with a pack that is not valid

@req omit-readings-for-invalid-packs=v1
@cites {
    text#{conforming-program=v1, result=v1, text=v1},
    #{
        pack=v1, valid-pack=v1, parse-tree-order=v1, reading-result=v1,
        reading-of-a-text=v1,
    },
}

A conforming program must give no result of a reading, and no node, of
a text with a pack that is not valid.

### 7.11 The results of readings

@req give-reading-results=v1
@cites {
    files#{path=v1},
    text#{conforming-program=v1, result=v1, text=v1},
    #{valid-pack=v1, reading-result=v1},
}

When a conforming program gives a result of a reading of a text, as the
text of a file at a valid path, with a valid pack, the program must give
exactly one result: the result of that reading. The result of that
reading is "no grammar", "parse failure", or "parsed".

### 7.12 The nodes of readings

@req give-reading-nodes=v1
@cites {
    text#{conforming-program=v1, result=v1, text=v1},
    #{
        pack=v1, reading-of-a-text=v1, parse-tree-order=v1,
        comment-node=v1, definition-node=v1, decoration-node=v1,
        test-node=v1,
    },
}

When a reading of a text with a pack has the result "parsed", and a
conforming program gives the comment nodes, the definition nodes, the
decoration nodes, or the test nodes of that reading, for each node of
that kind that the reading gives, the program must give that node once.
When a reading of a text with a pack has the result "parsed", and a
conforming program gives the comment nodes, the definition nodes, the
decoration nodes, or the test nodes of that reading, the program must
give no other node as a node of that kind.

### 7.13 The values of the nodes of readings

@req give-reading-node-values=v1
@cites {
    text#{conforming-program=v1, result=v1, run=v1, text=v1},
    #{
        pack=v1, reading-of-a-text=v1, parse-tree-order=v1,
        node-run=v1, node-type=v1, comment-node=v1, definition-node=v1,
        decoration-node=v1, test-node=v1, test-name=v1, test-label=v1,
    },
}

For a node that a reading of a text with a pack gives with the result
"parsed", when a conforming program gives the run of that node, the node
type of that node, whether that node is tagged, the name nodes of that
node, the body nodes of that node, whether that node is a test case or a
test suite, the name path of that node, or the test labels of that node,
the conforming program must give the value that the reading gives with
that node, and no other value instead of that value.

### 7.14 No nodes of the other readings

@req omit-nodes-of-unparsed-readings=v1
@cites {
    text#{conforming-program=v1, result=v1, text=v1},
    #{
        valid-pack=v1, reading-result=v1, reading-of-a-text=v1,
        comment-node=v1, definition-node=v1, decoration-node=v1,
        test-node=v1,
    },
}

When the result of a reading of a text with a valid pack is not
"parsed", a conforming program must give no comment node, definition
node, decoration node, or test node of that reading. When a conforming
program stops a reading of a text with a valid pack for limits of its
own, the conforming program must give no comment node, definition node,
decoration node, or test node of that reading.

### 7.15 What the code of a grammar can touch

@req isolate-grammars=v1
@cites {
    files#{taken-byte=v1},
    text#{conforming-program=v1, byte-sequence=v1},
    #{usable-grammar=v1},
}

A conforming program must run the code of each byte sequence that the
conforming program uses as a grammar so that neither that code nor the
language that the byte sequence gives takes bytes from a file, writes a
file or any output of the process, uses a network, reads a clock, or
starts a process.

### 7.16 The instances in which the code of a grammar runs

@req confine-grammars=v1
@cites {
    wasm-core/2.0,
    text#{conforming-program=v1, byte-sequence=v1},
    #{webassembly-module=v1, adapter-instance=v1},
}

A conforming program must run the code of each byte sequence that the
conforming program uses as a grammar only in an instance of the module
of that byte sequence. The conforming program must run that code so that
the code, and each function that the conforming program gives that
instance as an import, reads no byte and changes no byte of a memory,
reads no element and changes no element of a table, and reads no value
and changes no value of a global, of another instance of a module that
the conforming program uses as a grammar or of an instance of an
adapter.

### 7.17 Readings and decisions that end

@req end-readings=v1
@cites {
    text#{conforming-program=v1, text=v1},
    #{pack=v1, valid-pack=v1, reading-of-a-text=v1},
}

A conforming program must end each reading of a text with a pack, and
each decision whether a pack is valid.

### 7.18 Code of grammars that ends

@req end-grammar-code=v1
@cites {text#{conforming-program=v1, byte-sequence=v1}, #{usable-grammar=v1}}

A conforming program must end the code of each byte sequence that it
uses as a grammar.

### 7.19 No symbolic link followed in a pack

@req follow-no-pack-links=v1
@cites {files#{folder-tree=v1, symbolic-link=v1}, text#{conforming-program=v1}, #{pack=v1, pack-use=v1}}

In each use of a pack, a conforming program must follow no symbolic link
that is a file of the folder tree of the pack. In each use of a pack, a
conforming program must find no file by the reference of a symbolic link
that is a file of the folder tree of the pack.

### 7.20 Bytes only from the folders and the regular files of a pack

@req read-only-pack-files=v1
@cites {
    files#{folder-tree=v1, folder=v1, regular-file=v1, taken-byte=v1},
    text#{conforming-program=v1},
    #{pack=v1, pack-use=v1},
}

In each use of a pack, a conforming program must take bytes from the
files of the folder tree of the pack only from its folders and from its
regular files.

### 7.21 No wait for another process in a pack

@req avoid-pack-waits=v1
@cites {files#{folder-tree=v1, file-of-another-kind=v1}, text#{conforming-program=v1}, #{pack=v1, pack-use=v1}}

In each use of a pack, a conforming program must not wait for another
process or for a device to act on a file of another kind that is a file
of the folder tree of the pack, such as for a process to open the other
end of a pipe.

### 7.22 No change to the files of a pack

@req keep-packs-unchanged=v1
@cites {
    files#{
        file-system=v1, folder-tree=v1, folder=v1, regular-file=v1,
        symbolic-link=v1, file-of-another-kind=v1, attribute=v1,
    },
    text#{conforming-program=v1},
    #{pack=v1, pack-use=v1},
}

In each use of a pack, a conforming program must change no file of the
folder tree of the pack: not the content of a regular file, the folder
entries of a folder, the reference of a symbolic link, the data of a
file of another kind, or an attribute of a file, other than by a change
that the file system makes by itself when the program uses that file,
such as a change of the time of last access.

### 7.23 No permission or privilege that the process did not have

@req gain-no-pack-privileges=v1
@cites {
    posix/2024,
    files#{system=v1},
    text#{conforming-program=v1},
    #{pack=v1, pack-use=v1},
}

This requirement uses the permissions and the appropriate privileges as
POSIX.1-2024 defines them, such as a capability on a system that gives
capabilities to processes. In each use of a pack, a conforming program
must use only the permissions and the appropriate privileges that the
process of the conforming program has without a change by the conforming
program. In each use of a pack, a conforming program must use no
permission and no appropriate privilege that the conforming program gets
by a change of the user IDs, the group IDs, or the appropriate
privileges of the process of the conforming program, or through another
process that acts for the conforming program.

## 8. Conformance

A program conforms to this design when it is a
[conforming program](sinter:text#conforming-program=v1) of this design.
The vectors of the requirements
that the design holds directly, outside its specifications, are in the
file [`packs.test-vectors.jsonl`](packs.test-vectors.jsonl), in the same
folder as this design. The file is a test-vector set, in the form that
the specification
[`data-forms#test-vectors`](sinter:data-forms#test-vectors=v1) gives.

These requirements that the design holds directly have no vectors:
`give-pack-file-contents`, `give-pack-descriptor-values`,
`omit-readings-for-invalid-packs`, `give-reading-results`,
`give-reading-nodes`, `give-reading-node-values`,
`omit-nodes-of-unparsed-readings`, `isolate-grammars`,
`confine-grammars`, `end-readings`, `end-grammar-code`,
`follow-no-pack-links`, `read-only-pack-files`, `avoid-pack-waits`,
`keep-packs-unchanged`, and `gain-no-pack-privileges`. No vector of this
file holds a valid pack or a reading.

Each subsection below gives the forms of one group: the requirements of
the group, what the members `input`, `result`, and `values` of its
vectors stand for, each in a fixed form, and the need names that the
group uses, each with the need that it stands for.

### 8.1 Invalid packs

@schema invalid-pack-vector=v1
@cites {
    files#{
        system=v1, file-system=v1, folder-tree=v1, folder=v1,
        regular-file=v1, symbolic-link=v1, file-of-another-kind=v1,
        read-permission=v1, search-permission=v1, file-object=v1,
        folder-tree-object=v1, stored-folder-tree=v1,
    },
    data-forms#{
        hex-text=v1, json-value=v1, hash=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    text#{
        conforming-program=v1, byte-sequence=v1, byte=v1, text=v1,
        result=v1, code-span=v1,
    },
    #{
        pack=v1, pack-use=v1, valid-pack=v1, valid-descriptor=v1,
        usable-grammar=v1, query-file=v1, validate-packs=v1,
    },
}

In `input` and `values`, a byte sequence is its hex text, as a string,
and a text is a string of the characters of the text. A pack is its
folder tree, as a folder tree object. That folder tree object is the
file object of the root of that folder tree. The member `type` of that
file object is `"directory"`. These are the members of a file object in
the vectors:

- `type`: `"directory"` for a folder, `"regular file"` for a regular
  file, `"symbolic link"` for a symbolic link, and `"FIFO special file"`
  for a FIFO special file, which is a file of another kind.
- `entries`, for a folder only: an array with one entry object for each
  folder entry of the folder, in increasing order of the bytes of their
  entry names. An entry object has two members: `name`, the entry name,
  as a byte sequence, and `file`, the file object of the file of the
  folder entry.
- `content`, for a regular file only: its content as pieces, an array of
  objects that each have the members `bytes`, a byte sequence, and
  `times`, an integer of 1 or more. The content is the bytes of each
  piece, `times` times in a row, piece after piece.
- `reference`, for a symbolic link only: its reference, as a byte
  sequence.

A folder tree object stands for each file of its folder tree, each
folder included, and for no other file. No file object of the vectors
has the member `read`, `search`, `write`, or `owned-by-other`. For a
vector whose input is a pack, the requirements of the group of the
vector oblige the result and the values of the vector in each use of the
pack in which a file system stores the folder tree of the folder tree
object, for the process of the program, as Files defines a stored folder
tree, from the start of the use to the end of the use. So the process of
the program has the read permission for each file of the folder tree
other than a symbolic link, and the search permission for each folder. A
check of the vectors makes such a stored folder tree for each vector
whose input is a pack.

The group `invalid-packs` holds the vectors that each give a pack that
is not valid. The requirement of the group is `validate-packs`. No pack
of the group has a usable grammar, so each pack whose descriptor is
valid breaks the condition of a valid pack on usable grammars. The note
of each vector names one condition of a valid pack that the pack breaks
and that a program can decide without running the code of a grammar,
such as that the pack has the file `pack.toml`. Apart from that
condition, the pack has a valid descriptor with one grammar, a
file of that grammar whose content has the hash of that grammar, a query
file of the kind comment for that grammar, and a file under `licenses/`.

- `input`: the folder tree object of the pack.
- `result`: the result for whether the pack is valid, when a conforming
  program gives that result: "valid" when the pack is valid, and
  "invalid" when it is not. Each vector of the group has the result
  "invalid".
- `values`: no vector of the group has this member.

A need of a vector is a condition on the system or on the file system
that stores its folder tree. This is the need name that the group
`invalid-packs` uses, with the need that the need name stands for and
when a vector has that need:

- `case-distinct-names`: the folder tree is on a file system on which
  two entry names that differ only in the case of ASCII letters name two
  different files. A vector has this need when two entry names of one
  folder of its folder tree differ only in the case of ASCII letters,
  such as `README.md` and `readme.md`.

A vector of the group has the member `needs` when, and only when, the
vector has this need. When a vector of the group has the member `needs`,
that member names this need and no other.

```
{"form":"#invalid-pack-vector=v1","group":"invalid-packs","input":{"entries":[{"file":{"entries":[{"file":{"content":[{"bytes":"0061736d01000000","times":1}],"type":"regular file"},"name":"782e7761736d"}],"type":"directory"},"name":"6772616d6d617273"},{"file":{"entries":[{"file":{"content":[{"bytes":"4d4954204c6963656e73650a","times":1}],"type":"regular file"},"name":"4d49542e747874"}],"type":"directory"},"name":"6c6963656e736573"},{"file":{"entries":[{"file":{"entries":[{"file":{"content":[{"bytes":"28636f6d6d656e74292040636f6d6d656e740a","times":1}],"type":"regular file"},"name":"746167732e73636d"}],"type":"directory"},"name":"78"}],"type":"directory"},"name":"71756572696573"}],"type":"directory"},"note":"the pack has no file pack.toml","result":"invalid"}
```

### 8.2 Pack hashes

@schema pack-hash-vector=v1
@cites {
    posix/2024,
    files#{
        system=v1, file-system=v1, folder-tree=v1, folder=v1, path=v1,
        file-object=v1, folder-tree-object=v1, stored-folder-tree=v1,
    },
    data-forms#{
        json-value=v1, key-order=v1, group-form-list=v1, vector-meaning=v1,
    },
    text#{
        conforming-program=v1, byte-sequence=v1, byte=v1, text=v1,
        character=v1, 0x-numeral=v1, result=v1, code-span=v1,
        code-point-order=v1,
    },
    #{
        invalid-pack-vector=v1, pack=v1, pack-use=v1, pack-hash=v1,
        give-pack-files=v1, give-pack-listings=v1, omit-pack-listings=v1,
        give-pack-hashes=v1, omit-pack-hashes=v1,
    },
}

The rules that `invalid-pack-vector` gives for a vector whose input is a
pack hold for each vector of this group: the forms of byte sequences,
texts, folder tree objects, and file objects in `input` and `values`;
the uses of the pack in which the requirements of the group oblige the
result and the values of the vector; and the stored folder tree that a
check of the vectors makes for the vector.

The group `pack-hashes` holds the vectors that each give a pack and,
when it has a pack hash, the valid paths of its files, its pack listing,
and its pack hash. The requirements of the group are `give-pack-files`,
`give-pack-listings`, `omit-pack-listings`, `give-pack-hashes`, and
`omit-pack-hashes`.

- `input`: the folder tree object of the pack.
- `result`: no vector of the group has this member.
- `values`: when the pack has a pack hash, an object with three members:
  `files`, an array of the valid paths of the files of the pack, as
  texts, in code point order; `hash`, the pack hash of the pack, as a
  text; and `listing`, the pack listing of the pack, as a text. When the
  pack has no pack listing, and so no pack hash, the empty object, `{}`.

When a conforming program gives the valid paths of the files, the pack
listing, or the pack hash of the pack, it gives those of `values`, and
no other instead. The order of `files` is not a value that a conforming
program gives. With `{}`, a conforming program gives no pack listing and
no pack hash for the pack.

A need of a vector is a condition on the system or on the file system
that stores its folder tree. These are the need names that the group
`pack-hashes` uses, in key order, each need name with the need that the
need name stands for and when a vector has that need:

- `case-distinct-names`: the folder tree is on a file system on which
  two entry names that differ only in the case of ASCII letters name two
  different files. A vector has this need when two entry names of one
  folder of its folder tree differ only in the case of ASCII letters,
  such as `README.md` and `readme.md`.
- `non-portable-names`: the folder tree is on a file system on which the
  check can make each entry name of the folder tree. A vector has this
  need when an entry name of its folder tree holds a byte of less than
  0x80 that is not the byte of a character of the portable filename
  character set of POSIX.1-2024: `A` to `Z`, `a` to `z`, `0` to `9`,
  `.`, `_`, and `-`.

A vector of the group has the member `needs` when, and only when, it has
one or more of these needs, and the member names each need of the vector
and no other.

```
{"form":"#pack-hash-vector=v1","group":"pack-hashes","input":{"entries":[],"type":"directory"},"note":"the pack listing is the empty text","values":{"files":[],"hash":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","listing":""}}
```

### 8.3 Well-named packs

@schema well-named-pack-vector=v1
@cites {
    posix/2024,
    files#{
        system=v1, file-system=v1, folder-tree=v1, folder=v1,
        file-object=v1, folder-tree-object=v1, stored-folder-tree=v1,
    },
    data-forms#{
        json-value=v1, key-order=v1, group-form-list=v1, vector-meaning=v1,
    },
    text#{
        conforming-program=v1, byte-sequence=v1, byte=v1,
        valid-utf-8=v1, text=v1, character=v1, 0x-numeral=v1, result=v1,
        code-span=v1,
    },
    #{
        invalid-pack-vector=v1, pack=v1, pack-use=v1,
        well-named-pack=v1, decide-well-named-packs=v1,
    },
}

The rules that `invalid-pack-vector` gives for a vector whose input is a
pack hold for each vector of this group: the forms of byte sequences,
texts, folder tree objects, and file objects in `input` and `values`;
the uses of the pack in which the requirements of the group oblige the
result and the values of the vector; and the stored folder tree that a
check of the vectors makes for the vector.

The group `well-named-packs` holds the vectors that each give a pack
and whether it is well named. The requirement of the group is
`decide-well-named-packs`.

- `input`: the folder tree object of the pack.
- `result`: the result for whether the pack is well named, when a
  conforming program gives that result: "well named" when the pack is
  well named, and "not well named" when it is not.
- `values`: no vector of the group has this member.

A need of a vector is a condition on the system or on the file system
that stores its folder tree. These are the need names that the group
`well-named-packs` uses, in key order, each need name with the need that
the need name stands for and when a vector has that need:

- `case-distinct-names`: the folder tree is on a file system on which
  two entry names that differ only in the case of ASCII letters name two
  different files. A vector has this need when two entry names of one
  folder of its folder tree differ only in the case of ASCII letters,
  such as `README.md` and `readme.md`.
- `names-kept`: the folder tree is on a file system that keeps each
  entry name of the folder tree as the check makes that entry name, byte
  for byte. A vector has this need when an entry name of its folder tree
  is valid UTF-8 and holds a byte of 0x80 or more.
- `non-portable-names`: the folder tree is on a file system on which the
  check can make each entry name of the folder tree. A vector has this
  need when an entry name of its folder tree holds a byte of less than
  0x80 that is not the byte of a character of the portable filename
  character set of POSIX.1-2024: `A` to `Z`, `a` to `z`, `0` to `9`,
  `.`, `_`, and `-`.
- `non-utf-8-names`: the folder tree is on a file system that keeps each
  entry name of the folder tree that is not valid UTF-8 as the check
  makes that entry name, byte for byte. A vector has this need when an
  entry name of its folder tree is not valid UTF-8.

A vector of the group has the member `needs` when, and only when, it has
one or more of these needs, and the member names each need of the vector
and no other.

```
{"form":"#well-named-pack-vector=v1","group":"well-named-packs","input":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"7061636b2e746f6d6c"}],"type":"directory"},"result":"well named"}
```

The two entry names of this vector, `README.md` and `readme.md`, differ
only in the case of ASCII letters, so the vector has the need
`case-distinct-names`:

```
{"form":"#well-named-pack-vector=v1","group":"well-named-packs","input":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"524541444d452e6d64"},{"file":{"content":[],"type":"regular file"},"name":"726561646d652e6d64"}],"type":"directory"},"needs":["case-distinct-names"],"note":"two files whose paths are the same text after ASCII case folding","result":"not well named"}
```
