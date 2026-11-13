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
@cites tree-sitter/0.26.13
@cites wasmtime/36.0.19
@cites wasm-core/2.0
@cites crates/regex-1.13.1
Specifies language packs, with their files, pack paths, and pack hashes; descriptors, with pack names, release numbers, comment sigils, foreign tag words, name separators, grammars, test runners, and runner settings; usable grammars, query files, and valid packs; the readings of texts with packs, with parse trees, parse failures, comment nodes, definition nodes, decoration nodes, and test nodes, and the names and test labels of test nodes; runner adapters, with the instances that run their code, the requests, and the results of their calls; and requirements for conforming programs that validate packs and adapters, give pack hashes, read descriptors, read texts with packs, call adapters, and keep the code of a pack from what lies outside it.

A language pack, or pack, holds the support for one language: the
grammars that parse the files of the language, the query files that find
the comments, the definitions, and the tests in these files, a
descriptor, license texts, and runner adapters. A pack is a folder of
files. Its pack hash is the SHA-256 hash of a listing of its files, so
the pack hash names the content of the pack. The descriptor is the
content of the file `pack.toml`: a TOML document that names the pack and
its release, and lists its grammars, its comment sigils, its foreign tag
words, and its test runners.

A grammar is a tree-sitter grammar, compiled to WebAssembly. A program
reads a text with a pack: it parses the text with the grammar that the
name of the file selects, it runs the query files of that grammar over
the parse tree, and it gives the comments, the definitions, the
decorations, and the test nodes of the text. A runner adapter is a
WebAssembly module that reads the report files of one test runner and
binds their test results to test entries, which stand for test nodes. A
program calls an adapter with a request and a report content, such as
the content of a report file, and reads its response. The code of a
grammar and of an adapter can reach no file, no network, and no clock.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405. A production, such as
`grammar-name = %x61-7A *( %x61-7A / DIGIT / "_" )`, gives the texts
that its rule name matches. In a production, `/` separates two
alternatives, and `( )` groups elements. `*` repeats the element after
it any number of times, zero included, `1*` repeats it one or more
times, and `3*` repeats it three or more times. `%x61` is the character
U+0061, and `%x61-7A` is any one character from U+0061 to U+007A. A
quoted string such as `"-"` is its characters, and `%s"label."` matches
its letters only in the same case. `ALPHA` and `DIGIT` are core rules of
RFC 5234: an ASCII letter and an ASCII digit.

From Text and notation, the design takes characters, code points, texts,
places, boundaries, runs, and code point order; bytes, byte sequences,
valid UTF-8, the text of a byte sequence, and UTF-8 encodings; bodies,
line feeds, lines, line numbers, positions, and spans; whole numbers and
decimal numerals; the notation of productions; and conforming programs,
inputs, and results. From Identifiers, it takes tag words. From Files
and paths, it takes folder trees, folders, regular files, symbolic
links, and files of another kind, with their contents and attributes;
valid paths and the files that they name; valid globs and the valid
paths that fit them; the bytes that a program takes from a file; the
system of a program; and file objects, folder tree objects, and stored
folder trees. From Data forms, it takes TOML documents, their root
tables, and TOML values; hashes and the hash form; JSON values, their
canonical byte sequences, and the JSON values of byte sequences;
indexes; and test-vector sets. From the Ontology, it takes tests, test
results, and parameters and their bindings.

From RFC 8259, the design takes JSON texts: an adapter writes its
response as a JSON text, and the files that hold the conformance vectors
of the design hold one JSON text on each line. From POSIX.1-2024, it
takes the permissions and the appropriate privileges of a process, the
portable filename character set, the value `{_POSIX_NAME_MAX}`, and the
error [EILSEQ]. The design relies on the behavior of four dependencies,
at fixed versions. From tree-sitter 0.26.13, its Rust library with the
feature `wasm`, it takes the loading of grammars, parse trees and their
nodes, queries with their patterns, captures, predicates, and
quantifiers, and the matches of a query. From wasmtime 36.0.19, the
WebAssembly runtime of that library, as the feature `wasm` of
tree-sitter 0.26.13 builds it, with the Cranelift compiler and its
default configuration otherwise, it takes its engine and the compilation
of modules. From the WebAssembly Core Specification 2.0, it takes
modules, their validation, imports, exports, functions, memories,
tables, instances, traps, and the execution of code. From the Rust crate
regex 1.13.1, it takes the regular expressions of the predicates of
queries.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [pack](sinter:#pack=v1) | a language pack: a folder tree, such as one that holds the grammars, the query files, the descriptor, the license texts, and the runner adapters of one language |
| pack root | the root of the folder tree of a pack |
| [file of a pack](sinter:#pack=v1) | a valid path, such as `queries/rust/tags.scm`, whose last file name names a regular file in the folder tree of the pack, and a content, which is the content of that regular file |
| [have a file](sinter:#pack=v1) | a pack has the file p when it has a file whose valid path is p |
| [code point order](sinter:text#code-point-order=v1) | the order of texts by the code points of their characters, place by place, in which a text comes before each longer text that starts with it |
| [pack path](sinter:#pack-path=v1) | a valid path of at most 255 characters, each a printable ASCII character other than `\`, such as `grammars/rust.wasm` |
| [paths of a pack](sinter:#well-named-pack=v1) | the valid paths of the files of the pack, and each part of one of them from its start to right before a `/`, such as `queries` and `queries/rust` for the file `queries/rust/tags.scm` |
| [ASCII case folding](sinter:#well-named-pack=v1) | the change of each letter from `A` to `Z` of a text to the same letter from `a` to `z`, with no change to any other character |
| [well named](sinter:#well-named-pack=v1) | a pack is well named when the entry name of each folder entry on the way to a regular file of its folder tree is the UTF-8 encoding of a file name, each path of the pack is a pack path, and no two paths of the pack are the same text after ASCII case folding |
| [pack listing](sinter:#pack-hash=v1) | the text with one line for each file of a well-named pack, in the code point order of their valid paths: the hash of the content of the file, two spaces, its valid path, and a line feed |
| [pack hash](sinter:#pack-hash=v1) | the hash of the UTF-8 encoding of the pack listing of a well-named pack |
| [use of a pack](sinter:#pack-use=v1) | an operation that a program makes to give, for a pack, whether it is well named, the valid paths of its files, its pack listing, its pack hash, whether it is valid, a value of the content of its file `pack.toml` as a descriptor, the result of a reading of a text with it, the content of one of its files, or the result of a call of the adapter of one of its test runners |
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
| [test runner](sinter:#test-runner=v1) | a program that runs tests and writes report files on them, such as vitest or cargo-nextest; a valid descriptor describes its test runners |
| [adapter hash, adapter license](sinter:#test-runner=v1) | the hash that the descriptor gives for the adapter file of a test runner, and the license of that adapter, which a descriptor gives for a test runner that has an adapter of its own |
| [match table](sinter:#test-runner=v1) | the table of `match` in the table of a test runner of a valid descriptor, which a test runner has when it has no adapter hash |
| [runner setting](sinter:#runner-setting=v1) | a name and a default value, for a value that configuration can give for a test runner: a TOML string, a TOML boolean, or a TOML array of TOML strings |
| tree-sitter | a library that parses texts by grammars and finds parts of the parse trees by queries; here, the Rust library of tree-sitter 0.26.13, with its feature `wasm` |
| [WebAssembly module](sinter:#webassembly-module=v1) | a byte sequence that is a valid module in the binary format of the WebAssembly Core Specification 2.0 |
| [usable grammar](sinter:#usable-grammar=v1) | a WebAssembly module with no import whose name, after its module name, is `tree_sitter_debug_message`, which tree-sitter 0.26.13 loads as the language of a grammar name, with an ABI version from 13 to 15, and whose node types are each valid UTF-8 |
| [ABI version](sinter:#usable-grammar=v1) | the whole number that tree-sitter 0.26.13 gives as the version of the format of the language of a usable grammar |
| [query file](sinter:#query-file=v1) | a byte sequence that holds a tree-sitter query, of one of three kinds: comment, definition, and test |
| pattern, capture, capture name, predicate, directive, quantifier | the things of a query of tree-sitter 0.26.13 with these names: a query is a sequence of patterns; a pattern captures nodes under capture names, such as `@comment`; a predicate, such as `#eq?`, tests the texts of captured nodes, and a directive, such as `#set!`, sets a property; a quantifier says how many times a pattern captures under a capture name |
| [role name, role node](sinter:#joined-match=v1) | the capture name of a match that gives the kind of thing that the match finds, such as `comment` or `case`, and the node that the match captures under it |
| [depth of a query text](sinter:#query-depth=v1) | the number of levels of nesting that are open after a token of a query text |
| [depth limit](sinter:#query-depth=v1) | a query text passes the depth limit when its depth after one of its tokens is more than 100; it passes the depth limit at the first character of the first such token |
| [query name](sinter:#query-depth=v1) | a token of a query text, such as `_` or `function_item`: a name start character and the name characters after it, when they do not start a field name |
| [valid pack](sinter:#valid-pack=v1) | a pack that is well named, holds only folders and regular files, and has a valid descriptor; for each grammar of the descriptor, a usable grammar with the hash of the grammar, a valid `tags.scm`, and valid other query files; for each test runner with an adapter hash, an adapter file with that hash; and a file under `licenses/` |
| [parse text](sinter:#parse-tree=v1) | a text, with a line feed after it when it does not end with one |
| [parse tree](sinter:#parse-tree=v1) | the `Tree`, a structure of nodes, that tree-sitter 0.26.13 gives when it parses a parse text with a usable grammar |
| [node](sinter:#parse-tree-order=v1) | a node of a parse tree: its root node, or a child of one of its nodes, such as a comment or a function |
| [node type](sinter:#node-type=v1) | the text that tree-sitter 0.26.13 gives as the kind of a node, such as `line_comment` |
| [order of the parse tree](sinter:#parse-tree-order=v1) | the order of the nodes of a parse tree in which each node comes before its children, and the children of a node come in their order |
| [run of a node](sinter:#node-run=v1) | the run of the text that a node takes up, without a line feed that only the parse text has, and without the byte order mark of the text |
| [parse failure](sinter:#parse-failure=v1) | a text has a parse failure with a grammar when tree-sitter gives no parse tree for it, or when the root node of the parse tree has an error |
| [failure node](sinter:#parse-failure=v1) | the node at which a parse failure is: the first `ERROR` or `MISSING` node of the parse tree, or, when the parse tree has no such node, the first lowest node with an error |
| [query match](sinter:#query-match=v1) | a match that tree-sitter 0.26.13 gives for a query over a parse tree: one part of the parse tree where one pattern matches |
| [joined match](sinter:#joined-match=v1) | the query matches of one pattern that give one node the same role, taken as one match |
| [kept match](sinter:#joined-match=v1) | a joined match whose pattern comes first among the joined matches that give one node the same role |
| [comment node](sinter:#comment-node=v1) | the role node of a kept match of the query file of the kind comment |
| [tagged](sinter:#comment-node=v1) | a comment node is tagged when it can carry tags: a kept match captures it as `comment`, and no kept match captures it as `untagged` |
| [definition node](sinter:#definition-node=v1) | the role node of a kept match with the role name `definition` of the query file of the kind definition, such as a function, a type, a module, or a class |
| [name node, body node](sinter:#definition-node=v1) | a node that the kept match of a definition node captures as `name`, and a node that it captures as `body`; when that kept match captures no `body` node, the definition node is its own body node |
| [decoration node](sinter:#decoration-node=v1) | the role node of a kept match with the role name `decoration` of the query file of the kind definition, such as a Rust attribute |
| [test node](sinter:#test-node=v1) | the role node of a kept match of the query file of the kind test, which, by the query file, is the code of one test of the file: of one unit, for a test case, or of a set of units that the code groups under one name, for a test suite |
| [test case, test suite](sinter:#test-node=v1) | the two kinds of test node: a test node is a test suite, such as a vitest `describe`, when one of its kept matches has the role name `suite`, or when it encloses a test node that has a kept match with the role name `case`; each other test node is a test case, such as a Rust function with `#[test]` |
| [enclose](sinter:#enclosed-node=v1) | a node encloses a different node when its run starts at or before the start of the run of the other node, ends at or after its end, and the other node does not come before it in the order of the parse tree |
| [piece, text piece, placeholder](sinter:#test-name=v1) | a part of the name of a test node, from a node that a kept match of the test node captures as `name` or as `placeholder`: a text piece is text as the text of the file writes it; a placeholder stands for the text that the test runner puts in the name when it runs the test |
| [name path](sinter:#test-name=v1) | the names of the test suites that enclose a test node, outermost first, then its own name; by the query file, it stands for the name of the test of the test node |
| [test label](sinter:#test-label=v1) | a word, such as `each`, that a kept match of a test node gives it by the capture name `label.<word>`, such as for a test case that the test runner runs once for each row of a table |
| [reading](sinter:#reading-of-a-text=v1) | the reading of a text, as the text of a file at a valid path, with a valid pack: its result, "no grammar", "parse failure", or "parsed"; with "parsed", the nodes of the text and their values; with "parse failure", the run of the failure node, when there is one |
| import, export, instance, trap, page, embedder | the things of the WebAssembly Core Specification 2.0 with these names |
| [instance of an adapter](sinter:#adapter-instance=v1) | a new instance of a WebAssembly module that a program makes with no import, in which code runs as the WebAssembly Core Specification 2.0 defines, with the program as its embedder, under limits that the program has of its own on its resources |
| [choice of the program](sinter:#adapter-instance=v1) | an outcome in an instance of an adapter that the program decides: a stop for its limits, a refused growth of a memory or of a table within its maximum, the depth at which the call stack is exhausted, or the bits of a NaN |
| [valid adapter](sinter:#valid-adapter=v1) | in one decision of a program, a WebAssembly module that wasmtime 36.0.19 compiles, that imports nothing, that exports the five names of the interface with their types, and that gives the version 1 of the interface in an instance that the program makes for that decision |
| [adapter of a test runner](sinter:#valid-pack=v1) | the content of the file `adapters/<r>.wasm` of a valid pack, for the test runner `<r>` with an adapter hash |
| [binding of `runner-settings`](sinter:#runner-setting-binding=v1) | a finite set of pairs, each a name, which is a text, and a TOML value, which gives values for some of the runner settings of one test runner |
| [test entry](sinter:#test-entry=v1) | an id, a path, a first and a last line, a kind, a name path, and test labels, which a call of the function bind gives an adapter for one test node |
| [request](sinter:#adapter-request=v1) | the canonical byte sequence of a request object: a JSON object with the version 1 of the interface, the test runner, the values of its runner settings, the report name, and, for bind, the root and the test entries |
| report file | a file that a test runner writes, such as a JUnit XML file |
| [report content](sinter:#adapter-call=v1) | the byte sequence that a program gives an adapter, unchanged, in a call, such as the content of a report file |
| [report name](sinter:#adapter-request=v1) | a text, such as the path of a report file as a person gave it, which the request of a call gives the adapter |
| [test result](sinter:#call-result=v1) | an element of the value of `results` of the response of a call of bind, with its name, its status, and, when it has them, its file, its line, and its duration; by the adapter, it is a test result, in the sense of the Ontology, that the report content holds |
| [call](sinter:#adapter-call=v1) | a call of the function recognise or the function bind of a byte sequence as an adapter, with a request and a report content: it fails when the request or the report content has 4,294,967,296 bytes or more, or when, in the decision of the program that the call uses, the byte sequence is not a valid adapter; otherwise it runs in a new instance of an adapter and gives a response or fails |
| [response](sinter:#adapter-call=v1) | the bytes that a call of an adapter gives back |
| [JSON value of a response](sinter:#call-result=v1) | the JSON value of the response as a byte sequence, as Data forms defines it; a response that is not valid UTF-8, that is not a JSON text, or whose JSON text holds `null`, a number with a fraction or an exponent, an integer outside the range of a JSON integer, an escape `\u` of a surrogate that is not one of a pair, or an object with two names that stand for the same text has no JSON value |
| [result of a call](sinter:#call-result=v1) | "recognised", "not recognised", or "failed" for the function recognise; "bound" or "failed" for the function bind |
| [result object, binding object](sinter:#call-result=v1) | an object of the response of bind that gives one test result, with its name and its status, and an object that binds one test result to one test entry, with a reason |

## 2. Packs, descriptors, readings, and adapters

### 2.1 Packs and their files

A pack is a folder tree. The root of that folder tree is the pack root.
A file of the pack has a valid path, such as `grammars/rust.wasm`, whose
last file name names a regular file in the folder tree, and its content
is the content of that regular file. The paths of the pack are the valid
paths of its files and the paths of the folders that hold them: for the
file `queries/rust/tags.scm`, the paths `queries`, `queries/rust`, and
`queries/rust/tags.scm`.

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

A pack is well named when it meets three rules. With these rules, each
file of the pack gives exactly one line of the pack listing, and no two
paths of the pack can be one file on a file system that ignores the case
of ASCII letters. First, the entry name of each folder entry on the way
to a regular file of the folder tree is the UTF-8 encoding of a file
name. So a valid path names each regular file, and two folder entries of
one regular file, such as two hard links, give two files of the pack.
Second, each path of the pack is a pack path: at most 255 characters,
each a printable ASCII character from U+0020 to U+007E other than `\`,
with no file name `.` or `..`. So a pack path can hold a space, and it
holds no line feed. Third, no two paths of the pack are the same text
after ASCII case folding, which changes each letter from `A` to `Z` to
the same letter from `a` to `z`. So a pack cannot have both
`queries/rust/tags.scm` and `queries/Rust/tests.scm`, because the paths
`queries/rust` and `queries/Rust` are the same text after ASCII case
folding. An empty folder is no path of the pack, so its name breaks no
rule.

A use of a pack is an operation that a program makes to give, for the
pack, whether it is well named, the valid paths of its files, its pack
listing, its pack hash, whether it is valid, a value of the content of
its file `pack.toml` as a descriptor, the result of a reading of a text
with it, the content of one of its files, or the result of a call of the
adapter of one of its test runners. In each use of a pack, a conforming
program follows no symbolic link of the folder tree of the pack. From
the files of that folder tree, it takes bytes only from its folders and
its regular files. It does not wait for another process or for a device
to act on a file of another kind, such as a pipe, of that folder tree.
It changes no file of that folder tree. It uses no permission and no
privilege that its process did not have. A program that cannot take the
bytes of a file of the folder tree, such as for lack of a permission,
gives a result of that use only when that result is the one that the
requirements give; it can give no result. When another process changes
the folder tree of a pack during a use of the pack, no requirement
applies to the results of that use, and these guarantees still hold.

### 2.2 The pack hash

The pack listing of a well-named pack is a text with one line for each
file of the pack, in the code point order of their valid paths. Code
point order compares two texts by the code points of their characters,
place by place, and puts a text before each longer text that starts with
it. For pack paths, which are ASCII, it is the order of their bytes.
Each line holds, in this order:

1. the hash of the content of the file, as 64 lower-case hex digits;
2. two spaces;
3. the valid path of the file, with `/` between its file names and
   with no `./` at its start;
4. a line feed.

The pack hash is the hash of the UTF-8 encoding of the pack listing.
Each line of the pack listing has the form of a line that the command
`sha256sum` prints. So, in the root of a well-named pack that has at
least one file, this command prints the pack hash, then two spaces and
`-`:

```
find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sed 's|  \./|  |' | sha256sum
```

The command gives the paths to `xargs` with a NUL byte after each path,
because a path can hold a space. Each path that `find` gives starts with
`./`, so `sha256sum` reads no path as an option, and `sed` takes the
`./` away from each line.

A pack hash names one set of files with their contents. A path with a
line feed could add a line of its own to the pack listing, and then two
different packs could give one pack hash. Only a well-named pack has a
pack listing and a pack hash, and the paths of a well-named pack hold no
line feed.

### 2.3 The descriptor

The descriptor of a pack is the content of its file `pack.toml`. A
valid descriptor is a TOML document, and its root table holds these
keys. A key with the default "none" can be absent.

| key | TOML value | default | value |
|---|---|---|---|
| `sinter-spec` | string | required | a spec version: the oldest version of the specifications of Sinter that the pack needs, such as `1.0` |
| `name` | string | required | the name of the pack: a pack name |
| `version` | string | required | the release number of the pack, such as `1.0.3` |
| `license` | string | required | the license of the descriptor and the query files: a TOML string, such as an SPDX license expression |
| `name-separator` | string, not empty | required | the name separator |
| `foreign-tags` | array of strings | none | the foreign tag words, each without its `@` |
| `comments` | table | required | the comment sigils |
| `grammar` | array of one or more tables | required | the grammars |
| `runner` | table | none | the test runners |

The table `comments` can hold three keys: `line`, an array of line
sigils; `block`, an array of block pairs, each an array of an opening
sigil and a closing sigil; and `inner`, an array of inner sigils. A
comment sigil opens a comment, closes a comment, or starts a line of a
block comment after its first line. A comment sigil can be any text,
the empty text included.

Each table of the array `grammar` describes one grammar, with four
keys, all required:

| key | TOML value | value |
|---|---|---|
| `name` | string | the grammar name `<g>`. The file of the grammar is `grammars/<g>.wasm`, and it exports the function `tree_sitter_<g>` |
| `sha256` | string | the hash that the descriptor gives for the file of the grammar, as 64 lower-case hex digits |
| `license` | string | the license of the grammar: a TOML string, such as an SPDX license expression |
| `names` | array of strings | the file-name globs: valid globs, such as `*.ts` |

No two grammars of a descriptor have one name. A file-name glob is
fitted against the last file name of a valid path, and not against the
whole path. The file grammar of a valid path is the first grammar, in
the order of the array, that has a file-name glob that the last file
name fits. A valid path whose last file name fits no file-name glob has
no file grammar.

The table `runner` holds one table for each test runner, under the name
of the test runner, which is a pack name. A test runner is a program
that runs tests and writes report files on them. The table of a test
runner holds exactly one of `adapter` and `match`, and it can hold
`settings`:

| key | TOML value | value |
|---|---|---|
| `adapter.sha256` | string | the adapter hash: the hash that the descriptor gives for the file `adapters/<r>.wasm` |
| `adapter.license` | string | the adapter license: the license of the adapter, a TOML string, such as an SPDX license expression |
| `match` | table | the match table: data that describes how the test results of the report files of the test runner bind to test entries, for a test runner that has no adapter of its own |
| `settings` | table | the runner settings, each with its default value: a string, a boolean, or an array of strings |

The descriptor gives each license as a TOML string, and a valid
descriptor puts no rule on the form of that string. A runner setting is
a name and a default value. The parameter `runner-settings` (section
3.1) gives values for the runner settings of a test runner. The type of
a runner setting is the kind of its default value.

In a table whose keys this section names, another key makes the
descriptor not valid. A TOML value of the wrong kind, and a value that
breaks the rule of its key, also make the descriptor not valid. The
value of `match` is any table: no rule of a valid descriptor applies to
its keys and values. This is the descriptor of a TypeScript
pack with two grammars and one test runner:

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

A grammar of a pack is a tree-sitter grammar, compiled to WebAssembly,
in one file that serves every platform. The content of the file
`grammars/<g>.wasm` is a usable grammar when it is a WebAssembly module,
when it has no import whose name, after its module name, is
`tree_sitter_debug_message`, when tree-sitter 0.26.13 loads it as the
language `<g>`, through its export `tree_sitter_<g>`, when the ABI
version of that language is from 13 to 15, and when the name of each
node type of that language is valid UTF-8. The function that tree-sitter
0.26.13 gives a grammar for that import writes to the standard output of
the process. In a valid pack, the hash of the file is the hash that the
descriptor gives for the grammar.

A query file holds a tree-sitter query: a sequence of patterns. A
program runs the query over the parse tree of a text. A match is one
part of the parse tree where one pattern matches, and it has the nodes
that the pattern captures, each under a capture name. A capture name
that starts with `_` is for the predicates of a pattern alone: no
other rule takes its nodes. There are three kinds of query file, and
each kind has its own capture names. The role names are the capture
names that give the kind of thing that a match finds.

| kind | file | role names | other capture names |
|---|---|---|---|
| comment | `tags.scm` | `comment`: a comment; `untagged`: a comment that carries no tags | none |
| definition | `definitions.scm` | `definition`: a definition; `decoration`: a decoration | `name`: the node whose text is the name of the definition; `body`: the body of the definition |
| test | `tests.scm` | `case`: a test case; `suite`: a test suite | `name`: a text piece of the name; `placeholder`: a placeholder of the name; `label.<word>`: the test label `<word>` |

Each pattern captures exactly one role name, once. A pattern of the kind
definition with the role name `definition` captures `name` once or not
at all, and `body` once or not at all. A pattern with the role name
`decoration` captures no `definition`, `name`, or `body`. A word of a
test label starts with a lower-case ASCII letter, and it holds
lower-case ASCII letters, ASCII digits, and `-`.

A pattern can use only these ten predicates, which the Rust library of
tree-sitter 0.26.13 applies to each match itself: `#eq?`, `#not-eq?`,
`#any-eq?`, `#any-not-eq?`, `#match?`, `#not-match?`, `#any-match?`,
`#any-not-match?`, `#any-of?`, and `#not-any-of?`. The regular
expression of a match predicate follows the syntax of the crate regex
1.13.1. A query with another predicate, or with a directive such as
`#set!`, is not valid.

The patterns of a query nest. A query file whose text nests more than
100 levels deep is not valid. Each opening parenthesis `(`, each opening
bracket `[`, and each field name before a `:`, such as `key:` in
`(pair key: (string))`, adds one level. A closing parenthesis or bracket
ends the level that its opening one added, and the levels of the field
names right before that opening one. A pattern that is a query name or a
string, such as `_` or `"if"`, ends the levels of the field names right
before it. A parenthesis or a bracket inside a string or a query comment
adds no level. So the greatest depth after a token of `((a) (b (c)))` is
3, and a query text of 101 `(` passes the depth limit at its 101st
character.

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

A pack is valid when it is well named, holds only folders and regular
files, and has each required file with the right content: a valid
descriptor; for each grammar, a usable grammar with the hash of the
descriptor and a valid query file of the kind comment, and valid query
files of the kinds definition and test when it has them; for each
test runner with an adapter hash, an adapter file with that hash; and at
least one file under `licenses/`. For an adapter file, a valid pack
needs only that hash: the content of the file need not be a valid
adapter.

### 2.5 The reading of a text

A program reads a text, as the text of a file at a valid path, with a
valid pack. The file grammar of the path selects the grammar. When the
path has no file grammar, the reading gives the result "no grammar".

The parse text is the text, with a line feed after it when the text does
not end with one. The program parses the UTF-8 encoding of the parse
text with the usable grammar. tree-sitter 0.26.13 can give no parse
tree. When the code of the grammar exhausts the call stack, whether the
text has a parse tree can differ between conforming programs. When the
parse tree has an `ERROR` node or a `MISSING` node, the error flag of
its root node, which `Node::has_error` gives, is set. A `MISSING` node
takes up no text. A `MISSING` node of a hidden token is in no list of
the children of a node, and then only the error flag of the root node
shows it. So the text has a parse failure when tree-sitter gives no
parse tree, or when the error flag of the root node is set. A reading of
a text with a parse failure gives the result "parse failure". It gives
the run of the failure node, when the parse failure has one, and it
gives no node of the text. The failure node is the first `ERROR` or
`MISSING` node in the order of the parse tree. When the parse tree has
no such node, it is the first node in the order of the parse tree whose
error flag is set and that has no child whose error flag is set. A parse
failure with no parse tree has no failure node.

Each other reading gives the result "parsed". The program runs each
query file of the grammar over the parse tree. tree-sitter can return
the pieces of one name in two matches of one pattern. So the query
matches of one pattern that give one node the same role form one joined
match, which takes each node that they capture once, in the order of the
parse tree. Two joined matches of two different patterns can also give
one node the same role, such as when two patterns of `definitions.scm`
capture one node as `definition`. Then the joined match of the pattern
that comes first in the query file is the kept match, and the program
takes no other joined match for that node and that role.

A reading with the result "parsed" gives these nodes, each with its run
and its node type:

- the comment nodes, the role nodes of the kept matches of the query
  file of the kind comment, each with whether it is tagged. A comment
  node is tagged when a kept match captures it as `comment`, and no kept
  match captures it as `untagged`; a comment node that is not tagged is
  still a comment node;
- the definition nodes, each with its name nodes and its body nodes.
  When its kept match captures no node as `body`, its body node is the
  definition node itself;
- the decoration nodes;
- the test nodes, each with whether it is a test case or a test suite,
  its name path, and its test labels.

The run of a node is the run of the text that the node takes up. The
parser gives the start and the end of a node in bytes of the UTF-8
encoding of the parse text, and the run counts characters. The run of a
node leaves out a line feed that only the parse text has, and the byte
order mark of the text. So the run of each node is a span of the text.

### 2.6 Test cases, test suites, and their names

By the query file, a test node is the code of one test of the file: a
unit of code that a test runner runs and that can pass or fail, or a set
of such units that the code groups under one name. A test node is a test
case or a test suite. A test case is a test node for one such unit, such
as a Rust function with the attribute `#[test]`, or a call
`it("adds", ...)` in TypeScript. A test suite is a test node that the
query file captures as `suite`, or that encloses a test node that the
query file captures as `case`, such as a vitest `describe`, a Rust
`mod tests`, or a test class. A node encloses a
different node when the run of the node starts at or before the start
of the run of the other node, ends at or after its end, and the other
node does not come before the node in the order of the parse tree. So,
of two nodes with the same run, the node that comes first in the order
of the parse tree encloses the other. A test node is a test suite when
one of its kept matches captures it as `suite`, or when it encloses a
test node that a kept match captures as `case`. So, when one test case
encloses another, the outer one is a test suite.

The name of a test node is a sequence of pieces. Each node that a kept
match of the test node captures as `name` or `placeholder` gives one
piece, in the order of the parse tree. A `name` node gives a text piece:
the text of the node, as the text of the file writes it. A `placeholder`
node gives a placeholder: text that the test runner puts in the name of
the test when it runs the test, such as for a template substitution
`${n}`. A placeholder can stand for any text, the empty text included. A
reading decodes nothing in a name: it removes no quote, and it reads no
escape sequence. The name path of a test node is the names of the test
suites that enclose it, outermost first, then its own name. The name
path stands for the name of the test of the test node: that name, with,
in place of each placeholder, the text that the test runner puts in.

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

With it, the text
``describe("math", () => { it(`adds ${n}`, () => {}) })`` gives a test
suite with the name `math`, a text piece, and, in it, a test case whose
name is the text piece `adds ` and the placeholder `${n}`. The name path
of the test case is these two names.

### 2.7 Runner adapters

A runner adapter is a WebAssembly module that reads the report files of
one test runner and binds their test results to test entries, which
stand for test nodes. A pack has at most one adapter for each test
runner: the file `adapters/<r>.wasm`.
The module is a valid adapter when wasmtime 36.0.19 compiles it, when it
imports nothing (no function, no memory, no table, and no global), and
when it exports these five names, with these types:

| export | type | what it does |
|---|---|---|
| `memory` | memory | the linear memory of the module |
| `sinter_interface` | `[] -> [i32]` | gives the version of the interface: `1` |
| `sinter_alloc` | `[i32] -> [i32]` | reserves the given number of bytes in `memory`, and gives the address of the first byte, an address other than `0`, also for 0 bytes; gives `0` only when it cannot reserve the bytes |
| `sinter_recognise` | `[i32 i32 i32 i32] -> [i64]` | the function recognise: says whether the report content is the content of a report file of the test runner |
| `sinter_bind` | `[i32 i32 i32 i32] -> [i64]` | the function bind: reads the test results of the report content and binds them to test entries |

The module can export other names, such as the globals `__data_end` and
`__heap_base` that the Rust compiler adds. This is version 1 of the
interface. A valid adapter also gives that version. A program decides
whether a byte sequence is a valid adapter in an instance of its module
that it makes for that decision, in which it makes only the
instantiation and then an invocation of `sinter_interface`: these do not
fail, and the invocation gives the value 1. Two decisions can differ
when a choice of the program, such as a stop for its limits, changes
them.

A call runs one function of an adapter, with a request and a report
content. The report content is a byte sequence, such as the content of
a report file. The call uses one decision of the program whether the
adapter is a valid adapter, made in another instance, such as a decision
that the program made before the call, and the call fails when that
decision is that the adapter is not valid. The call then runs in a new
instance of its module, so nothing that one call leaves in its instance
reaches the next call. In that instance, the program does only this,
and it changes no byte of the memory other than by the writes of steps
2 and 3:

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
Specification 2.0 defines, under limits that the program has of its own
on the resources of the instance, such as the size of its memory. The
limits of a program bound the time that the code runs too. The program
can stop a call whose code goes past these limits, and that call then
fails. The program ends the code of each call. Which calls go past the
limits of a program can differ between conforming programs. A growth of
a memory past its maximum does not make the call fail: the instruction
`memory.grow` gives −1 to the code, as the WebAssembly Core
Specification 2.0 defines, and the call goes on.

The code of an adapter imports nothing, so it can read no file, use no
network, see no clock, and start no process. No file, network, clock,
or process reaches the code of an adapter; only the choices of the
program can make two runs of one call give different results.

### 2.8 Requests and responses

The request is the canonical byte sequence of a JSON object, so the
members of each object of the request stand in key order. For the
function recognise, it has the members `interface`, the integer `1`;
`runner`, the name of the test runner; `settings`, the value of each
runner setting under the binding of `runner-settings`; and
`report`, the report name: a text, such as the path of a report file as
a person gave it. For the function bind,
it also has `root`, a text such as the absolute path of the root of the
repository, and `tests`: one object for each test entry, in the code
point order of their ids.

A test entry gives an adapter one test node: an id, which names the test
node in the call; a path, the valid path at which the reading read the
text of the test node; the line numbers of the start and the end of its
run, `line` and `eline`; `suite`, true for a test suite and false for a
test case; `names`, its name path, one array for each name, with one
object for each piece, `{"text": ...}` for a text piece and
`{"placeholder": ...}` for a placeholder; and `labels`, its test labels,
in code point order. For example, the request of a call of recognise for
the test runner `vitest`, with the runner setting `recognise` at its
default value, and the report name `out/junit.xml`, is the UTF-8
encoding of this text:

```
{"interface":1,"report":"out/junit.xml","runner":"vitest","settings":{"recognise":["testsuites@name=vitest tests"]}}
```

The response is a JSON text in UTF-8. The response of recognise is
`{"recognised":true}` or `{"recognised":false}`. The response of bind
is an object with three members, all required:

| member | value |
|---|---|
| `results` | an array of result objects: each test result that the adapter read, in the order of the report content |
| `bindings` | an array of binding objects: each binding of a test result to a test entry |
| `warnings` | an array of strings: texts for the person who runs the program, such as about a kind of test result that the adapter cannot bind; it can be empty |

A result object has these members:

| member | value |
|---|---|
| `name` | a string: the name of the test result, as the report content writes it |
| `status` | the string `pass`, `fail`, `error`, or `skip` |
| `file` | a string: the file of the test result, as the report content writes it; absent when the report content gives none |
| `line` | an integer of 1 or more: the line of the test result; absent when the report content gives none |
| `ms` | an integer of 0 or more: the duration of the test result in whole milliseconds; absent when the report content gives none |

A binding object has these members, all required:

| member | value |
|---|---|
| `result` | an integer: 1 less than the index of the test result in `results`, so 0 for the first test result |
| `test` | a string: the id of a test entry of the request |
| `reason` | a string with no line feed: why the test result binds to the test entry |

When the adapter cannot read the report content, the response is
`{"error": <text>}`, and the result of the call is "failed", with that
error text. The result of a call is also "failed" when its response
breaks these rules, such as: when the response has no JSON value, as
Data forms defines the JSON value of a byte sequence, for example when
it is not valid UTF-8, when it is not a JSON text, or when it holds
`null` or a number with a fraction; when a member is missing, of the
wrong type, or not one of the members above; when the value of `result`
of a binding object is not less than the number of test results; when a
test id is not the id of a test entry of the request; or when one pair
of a test result and a test entry occurs twice. This response of bind
binds one test result to one test entry:

```
{"bindings":[{"reason":"name and file match","result":0,"test":"t1"}],"results":[{"file":"src/math.test.ts","ms":3,"name":"math > adds","status":"pass"}],"warnings":[]}
```

## 3. Parameters

### 3.1 `runner-settings`

The parameter `runner-settings` gives values for the runner settings of
a test runner of a pack. A binding of it, for one test runner, is a
finite set of pairs, each a name, which is a text, and a TOML value. In
a valid binding, each name is the name of a runner setting of that test
runner, no two pairs have the same name, and each TOML value is of the
type of that runner setting. The value of a runner setting under a valid
binding is the TOML value of the pair with its name, or its default
value when no pair has its name. The binding can be the empty set, and
then each runner setting has its default value.

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
@cites text#{production=v1, rule-name=v1, code-span=v1, text=v1, character=v1}

A pack path is a text of at most 255 characters that matches the
production `pack-path`:

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

- Each folder entry of the root or of a folder of its folder tree has an
  entry name that is the UTF-8 encoding of a text that matches the
  production `file-name`, when the file of that folder entry is a
  regular file, or is a folder that is the root of a folder tree with a
  regular file among its files.
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
pack hash of a well-named pack is the hash of the
UTF-8 encoding of its pack listing. A pack that is not well named, and a
pack that has a file whose content has 2^61 bytes or more, have no pack
listing and no pack hash. A well-named pack whose pack listing has a
UTF-8 encoding of 2^61 bytes or more has no pack hash.

### 4.5 Uses of packs

@term pack-use=v1
@cites {
    files#{path=v1},
    text#{result=v1, text=v1},
    #{
        pack=v1, well-named-pack=v1, pack-hash=v1, valid-pack=v1,
        valid-descriptor=v1, test-runner=v1, reading-of-a-text=v1,
        adapter-call=v1, call-result=v1,
    },
}

A use of a pack is an operation that a program makes to give, for that
pack, one of these: a result for whether the pack is well named; the
valid paths of its files; its pack listing; its pack hash; a result for
whether the pack is valid; a value of the content of its file
`pack.toml` as a descriptor; a result of a reading of a text with the
pack; the content of one of its files; or a
result of a call of the adapter of a test runner of its descriptor. Such
an operation is a use of the pack also when the program gives another
thing in it, or nothing.

### 4.6 WebAssembly modules

@term webassembly-module=v1
@cites {wasm-core/2.0, text#{byte-sequence=v1}}

A WebAssembly module is a byte sequence that is a module in the binary
format of the WebAssembly Core Specification 2.0, and that is valid by
that specification. This definition and each term that cites it use
these things of that specification: modules, imports, exports,
functions, function types, memories and their memory types, tables and
their table types, globals, instances, embedders, the instantiation of a
module and its start function, the invocation of a function, traps,
pages, the instructions `memory.grow` and `table.grow`, and the value
types `i32` and `i64`.

### 4.7 Usable grammars

@term usable-grammar=v1
@cites {
    tree-sitter/0.26.13, wasmtime/36.0.19, wasm-core/2.0,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text=v1, whole-number=v1,
        code-span=v1, conforming-program=v1,
    },
    #{webassembly-module=v1, grammar-name=v1},
}

This definition uses the Rust library of tree-sitter 0.26.13, with its
feature `wasm`, which runs WebAssembly code with wasmtime 36.0.19, as
that feature builds it, with the Cranelift compiler and its default
configuration otherwise. A store is a new `WasmStore` that
`WasmStore::new` of that library makes from an `Engine` of that build of
wasmtime with its default configuration. A byte sequence is a usable
grammar with a grammar name g when, and only when, it meets each of
these conditions:

1. It is a WebAssembly module.
2. It has no import whose name, after its module name, is
   `tree_sitter_debug_message`.
3. `WasmStore::load_language` of that library, on a store, with the
   text g as its name and that byte sequence as its bytes, gives a
   language.
4. `Language::abi_version` of that library gives, for that language, a
   whole number from 13 to 15.
5. For each whole number i from 0 to 1 less than the number that
   `Language::node_kind_count` gives for that language,
   `Language::node_kind_for_id` reads, for i, no name, or a name whose
   bytes are valid UTF-8. So `Node::kind` gives a text for each node
   whose language is that language.

The language of a usable grammar with the grammar name g is that
language, and its ABI version is that whole number. That library takes
the language from the export of the module whose name is `tree_sitter_`
followed by g. A usable grammar is a module of the WebAssembly Core
Specification 2.0, so the features beyond that specification that the
default configuration of that build of wasmtime turns on do not change
which byte sequences are usable grammars. When the code of the module
exhausts the call stack during `WasmStore::load_language`, whether the
byte sequence is a usable grammar can differ between conforming
programs. For each import of a module, `WasmStore::load_language` of
that library gives the module a function, a memory, a table, or a global
by the name of the import after its module name, or it gives no
language. The function that it gives for the name
`tree_sitter_debug_message` writes to the standard output of the
process. The other imports that it gives give the code of the module no
means to take bytes from a file, to write a file or the output of the
process, to use a network, to read a clock, or to start a process.

### 4.8 The depth of a query text

@term query-depth=v1
@cites text#{
    text=v1, character=v1, code-point=v1, place=v1, run=v1, line-feed=v1,
    carriage-return=v1, space=v1, tab=v1, whole-number=v1, code-span=v1,
}

The tokens of a query text follow one another from place 1 of the text
to its end. Each token starts at the place right after the end of the
token before it, and these are the tokens:

- A query comment is the character `;` and each character after it up
  to the next line feed, without that line feed, or up to the end of the
  text.
- A string is the character `"` and each character after it up to, and
  with, the next `"` that is not escaped; when no such `"` follows, it
  is the character `"` and each character after it to the end of the
  text. In a string, a `\` that is not escaped escapes the character
  right after it.
- An opening is the character `(` or `[`, and a closing is the character
  `)` or `]`.
- A reference is the character `@`, `#`, or `!`, and the longest run of
  name characters right after it, which can be empty.
- A field name is a name start character, the longest run of name
  characters right after it, the longest run after these of spaces,
  tabs, line feeds, carriage returns, form feeds, and query comments,
  and then the character `:`. A form feed is the character whose code
  point is 12.
- A query name is a name start character and the longest run of name
  characters right after it, when these are not the start of a field
  name, with the longest run after them of spaces, tabs, line feeds,
  carriage returns, form feeds, and query comments.
- Each other character is a token by itself.

The name start characters are the characters `A` to `Z`, `a` to `z`, `0`
to `9`, `_`, and `-`, and each character whose code point is 128 or
more. The name characters are the name start characters and the
characters `.`, `?`, and `!`.

For the tokens of a query text, in their order, a sequence L of whole
numbers and a whole number f change. Before the first token, L holds no
number and f is 0. An opening appends f + 1 to the end of L and makes f
0. A closing removes the last number of L, when L holds a number, and
makes f 0. A field name adds 1 to f. A string or a query name makes f 0.
Each other token changes neither L nor f. The depth after a token is the
sum of the numbers of L, together with f, after that token. A query text
passes the depth limit when, and only when, the depth after one of its
tokens is more than 100. The place where a query text passes the depth
limit is the place of the first character of the first token after
which the depth is more than 100.

### 4.9 Query files

@term query-file=v1
@cites {
    tree-sitter/0.26.13, crates/regex-1.13.1,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        text=v1, production=v1, rule-name=v1, code-span=v1,
    },
    #{grammar-name=v1, usable-grammar=v1, query-depth=v1},
}

This definition uses these things of queries of the Rust library of
tree-sitter 0.26.13: patterns, captures, capture names, predicates, and
the quantifiers that `Query::capture_quantifiers` gives:
Zero, ZeroOrOne, ZeroOrMore, One, and OneOrMore. A query file is of one
of three kinds, each with its role names and its other capture names:

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

1. It is valid UTF-8, and its text does not pass the depth limit.
2. `Query::new` of that library, with the language of that usable
   grammar with the grammar name g and the text of the byte sequence,
   gives a query, and no error. That
   library compiles the regular expression of each predicate `#match?`,
   `#not-match?`, `#any-match?`, and `#any-not-match?` with the crate
   regex 1.13.1.
3. For each pattern of the query, `Query::general_predicates`,
   `Query::property_predicates`, and `Query::property_settings` of that
   library give no element. So each predicate of the query is one of the
   ten text predicates that the library applies itself: `#eq?`,
   `#not-eq?`, `#any-eq?`, `#any-not-eq?`, `#match?`, `#not-match?`,
   `#any-match?`, `#any-not-match?`, `#any-of?`, and `#not-any-of?`.
4. Each capture name of the query that does not start with `_` is a role
   name or another capture name of that kind.
5. For each pattern of the query, the quantifiers of the capture names,
   where a capture name that the query does not have has the quantifier
   Zero, meet the rule of that kind:
   - comment: one of `comment` and `untagged` has the quantifier One,
     and the other has the quantifier Zero;
   - definition: `definition` has the quantifier One, `decoration` has
     the quantifier Zero, and `name` and `body` each have the quantifier
     Zero, ZeroOrOne, or One; or `decoration` has the quantifier One,
     and `definition`, `name`, and `body` each have the quantifier Zero;
   - test: one of `case` and `suite` has the quantifier One, and the
     other has the quantifier Zero.

### 4.10 Valid packs

@term valid-pack=v1
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

In this definition, for a text g and a text r, `grammars/<g>.wasm` is
the text `grammars/`, then g, then `.wasm`; `queries/<g>/tags.scm`,
`queries/<g>/definitions.scm`, and `queries/<g>/tests.scm` are the text
`queries/`, then g, then `/tags.scm`, `/definitions.scm`, or
`/tests.scm`; and `adapters/<r>.wasm` is the text `adapters/`, then r,
then `.wasm`. A pack is valid when, and only when, it meets each of
these conditions:

1. Each file of its folder tree, other than its root, is a folder or a
   regular file.
2. It is well named.
3. It has the file `pack.toml`, and the content of that file is a valid
   descriptor.
4. For each grammar of that valid descriptor, with the name g:
   - It has the file `grammars/<g>.wasm`, whose content has the hash of
     that grammar as its hash and is a usable grammar with the grammar
     name g.
   - It has the file `queries/<g>/tags.scm`, whose content is a valid
     query file of the kind comment for that usable grammar with the
     grammar name g.
   - When it has the file `queries/<g>/definitions.scm`, its content is
     a valid query file of the kind definition for that usable grammar
     with the grammar name g.
   - When it has the file `queries/<g>/tests.scm`, its content is a
     valid query file of the kind test for that usable grammar with the
     grammar name g.
5. For each test runner of that valid descriptor that has an adapter
   hash, with the name r, it has the file `adapters/<r>.wasm`, whose
   content has that adapter hash as its hash.
6. It has at least one file whose valid path starts with the text
   `licenses/`.

For a valid pack: its descriptor is the valid descriptor that is the
content of its file `pack.toml`; the usable grammar of a grammar of its
descriptor, with the name g, is the content of its file
`grammars/<g>.wasm`, as a usable grammar with the grammar name g; the
language of that grammar is the language that its usable grammar gives
with the grammar name g; the query file of the kind comment of that
grammar is the content of its file `queries/<g>/tags.scm`; the query
file of the kind definition, or of the kind test, of that grammar is the
content of its file `queries/<g>/definitions.scm`, or
`queries/<g>/tests.scm`, when it has that file, and that grammar has
none when it does not; and the adapter of a test runner of its
descriptor that has an adapter hash, with the name r, is the content of
its file `adapters/<r>.wasm`.

### 4.11 Parse trees

@term parse-tree=v1
@cites {
    tree-sitter/0.26.13, wasmtime/36.0.19,
    text#{text=v1, line-feed=v1, utf-8-encoding=v1, byte=v1, code-span=v1},
    #{usable-grammar=v1, grammar-name=v1},
}

The parse text of a text is that text, followed by a line feed when the
text does not end with a line feed. So the parse text of the empty text
is one line feed. The store of a usable grammar with a grammar name g is
a new `WasmStore` that `WasmStore::new` of the Rust library of
tree-sitter 0.26.13 makes from an `Engine` of wasmtime 36.0.19, as the
feature `wasm` of that library builds it, with the Cranelift compiler
and its default configuration otherwise, and that then loads the usable
grammar with the name g. The parser of that usable grammar is a new
`Parser` of that library that has that store as its WebAssembly store,
the language that this store loads as its language, and no other
setting. For that usable grammar and a text, the parse tree is the
`Tree` that `Parser::parse` of that parser gives for the UTF-8 encoding
of the parse text of that text, with no old `Tree`. When `Parser::parse`
gives no `Tree`, the text has no parse tree with that usable grammar. A
text whose parse text has a UTF-8 encoding of 4,294,967,296 bytes or
more has no parse tree. When the code of the usable grammar exhausts the
call stack, whether the text has a parse tree with that usable grammar
can differ between conforming programs.

### 4.12 The order of the parse tree

@term parse-tree-order=v1
@cites {tree-sitter/0.26.13, text#{whole-number=v1, code-span=v1}, #{parse-tree=v1}}

The nodes of a parse tree are its root node, which `Tree::root_node` of
tree-sitter 0.26.13 gives, and each child of each of its nodes. The
children of a node are the nodes that `Node::child` gives for that node,
for each whole number from 0 to 1 less than the number that
`Node::child_count` gives, in the order of these whole numbers. The
descendants of a node are its children and the descendants of its
children. In the order of the parse tree, each node comes before each of
its descendants, and, for each two children of one node, the first of
them and each of its descendants come before the second of them.

### 4.13 The runs of nodes

@term node-run=v1
@cites {
    tree-sitter/0.26.13,
    text#{
        text=v1, character=v1, boundary=v1, run=v1, body=v1,
        utf-8-encoding=v1, byte=v1, code-span=v1,
    },
    #{parse-tree=v1, parse-tree-order=v1},
}

For each node of the parse tree of a text, tree-sitter 0.26.13 gives a
start byte, `Node::start_byte`, and an end byte, `Node::end_byte`. Each
of these is the number of bytes of the UTF-8 encoding of the characters
of the parse text before a boundary of the parse text: s for the start
byte, and e for the end byte. For a text, b is the boundary where the
body of the text starts, and l is the last boundary of the text. The run
of a node of the parse tree of a text is the run of that text that
starts at the greater of b and the lesser of s and l, and that ends at
the greater of b and the lesser of e and l.

### 4.14 Node types

@term node-type=v1
@cites {tree-sitter/0.26.13, text#{text=v1, code-span=v1}, #{parse-tree=v1, parse-tree-order=v1}}

The node type of a node of a parse tree is the text that `Node::kind` of
tree-sitter 0.26.13 gives for that node.

### 4.15 Parse failures

@term parse-failure=v1
@cites {tree-sitter/0.26.13, text#{text=v1, code-span=v1}, #{usable-grammar=v1, parse-tree=v1, parse-tree-order=v1}}

A node of a parse tree has an error when, and only when,
`Node::has_error` of tree-sitter 0.26.13 gives true for it. A node is an
`ERROR` node when, and only when, `Node::is_error` gives true for it,
and a `MISSING` node when, and only when, `Node::is_missing` gives true
for it. A text has a parse failure with a usable grammar when, and only
when, the text has no parse tree with that usable grammar, or the root
node of its parse tree with that usable grammar has an error. The
failure node of a parse failure with a parse tree is the first `ERROR`
node or `MISSING` node of that parse tree in the order of the parse
tree. When that parse tree has no such node, the failure node is the
first node, in the order of the parse tree, that has an error and that
has no child that has an error. A parse failure with no parse tree has
no failure node.

### 4.16 Query matches

@term query-match=v1
@cites {
    tree-sitter/0.26.13, crates/regex-1.13.1,
    text#{utf-8-encoding=v1, code-span=v1},
    #{usable-grammar=v1, query-file=v1, parse-tree=v1, parse-tree-order=v1},
}

For a valid query file of a usable grammar, and a text that has a parse
tree with that usable grammar, the query matches are the matches that
`QueryCursor::matches` of the Rust library of tree-sitter 0.26.13 gives
for the query of that query file, over the root node of that parse tree,
with the UTF-8 encoding of the parse text as the text of the nodes, from
a new `QueryCursor` that has no setting. That library applies the
predicates of each pattern to each match itself, and it matches regular
expressions with the crate regex 1.13.1. The pattern of a query match is
the pattern whose index `QueryMatch::pattern_index` gives, and one
pattern comes before another when its index is less. The captures of a
query match are its captures whose capture names do not start with `_`:
each is a capture name and a node of the parse tree.

### 4.17 Joined matches and kept matches

@term joined-match=v1
@cites {
    text#{text=v1},
    #{query-file=v1, query-match=v1, parse-tree=v1, parse-tree-order=v1},
}

A query match of a valid query file has exactly one capture whose
capture name is a role name of the kind of that query file. The role
name and the role node of the query match are the capture name and the
node of that capture. The query matches of one query file over one text
that have the same pattern, the same role name, and the same role node
form one joined match. A joined match has that pattern, that role name,
and that role node, and, for each capture name, the nodes that its query
matches capture under that capture name, each node once, in the order of
the parse tree. The kept matches of a query file over a text are its
joined matches whose pattern comes before the pattern of each other
joined match of that query file over that text that has the same role
name and the same role node.

### 4.18 Comment nodes

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

### 4.19 Definition nodes

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

### 4.20 Decoration nodes

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

### 4.21 Enclosed nodes

@term enclosed-node=v1
@cites {text#{run=v1, boundary=v1}, #{parse-tree=v1, parse-tree-order=v1, node-run=v1}}

A node A of the parse tree of a text encloses a different node B of that
parse tree, and B is an enclosed node of A, when, and only when, the run
of A starts at the boundary where the run of B starts or at a boundary
before it, the run of A ends at the boundary where the run of B ends or
at a boundary after it, and B does not come before A in the order of the
parse tree.

### 4.22 Test nodes

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
test case, or of a set of units that the code groups under one name,
for a test suite. The text has no test node
when that grammar has no query file of the kind test. The kept matches
of a test node are the kept matches whose role node it is. A test node
is a test suite when, and only when, one of its kept matches has the
role name `suite`, or it encloses a test node that has a kept match with
the role name `case`. Each other test node is a test case. The test
suites that enclose a test node are the test nodes that are test suites
and that enclose it, in the order of the parse tree.

### 4.23 The names of test nodes

@term test-name=v1
@cites {
    ontology#{test=v1},
    text#{text=v1, run=v1, code-span=v1},
    data-forms#{index=v1},
    #{
        test-runner=v1, joined-match=v1, parse-tree=v1, parse-tree-order=v1,
        node-run=v1, enclosed-node=v1, test-node=v1,
    },
}

A piece is a text piece or a placeholder, and it has a text. A text
piece stands for its text, as the text of the file writes it. A
placeholder stands for text that the test runner puts in the name of a
test when it runs the test, which can be any text, the empty text
included. The name of a test node is a sequence of pieces, one for each
node that one of its kept matches captures under `name` or under
`placeholder`, in the order of the parse tree. A node that one of these
kept matches captures under `placeholder` gives a placeholder, and each
other of these nodes gives a text piece. The text of each piece is the
text of the run of its node. The name path of a test node is the names
of the test suites that enclose it, in the order of the parse tree,
followed by its own name. By the query file, the name path of a test
node stands for the name of its test: that name, with, in place of each
placeholder, the text that the test runner puts in. Two name paths are
equal when, and only when, they have the same number of names and, at
each index, names with the same number of pieces whose pieces, at each
index, are of the same kind and have the same text.

### 4.24 The test labels of test nodes

@term test-label=v1
@cites {
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
    #{query-file=v1, joined-match=v1, test-node=v1},
}

The test labels of a test node are the texts w that match the production
`label-word` and such that one of the kept matches of the test node
captures a node under the capture name that is the text `label.`
followed by w.

### 4.25 Readings

@term reading-of-a-text=v1
@cites {
    files#{path=v1},
    text#{text=v1, result=v1, run=v1},
    #{
        grammar-name=v1, valid-pack=v1, file-grammar=v1, parse-failure=v1,
        node-run=v1, node-type=v1, comment-node=v1, definition-node=v1,
        decoration-node=v1, test-node=v1, test-name=v1, test-label=v1,
    },
}

A reading of a text, as the text of a file at a valid path p, with a
valid pack, has one of three results. When p has a file grammar for the
descriptor of the pack, g is that file grammar. The results are:

1. "no grammar" when p has no file grammar for the descriptor of the
   pack;
2. "parse failure" when the text has a parse failure with the usable
   grammar of g, with the name of g as its grammar name;
3. "parsed" otherwise.

A reading with the result "parsed" gives the comment nodes, the
definition nodes, the decoration nodes, and the test nodes of the text
for g, each with its run and its node type. It gives, with each comment
node, whether it is tagged; with each definition node, its name nodes
and its body nodes, each with its run and its node type; and with each
test node, whether it is a test case or a test suite, its name path, and
its test labels. A reading with the result "parse failure" gives the run
of the failure node of that parse failure, when that parse failure has a
failure node, and it gives no node of the text. A reading with the
result "no grammar" gives no node of the text.

## 5. The descriptor
@spec descriptor=v1

When a conforming program decides whether a byte sequence is a valid
descriptor, it gives "valid" when it is one, and "invalid" when it is
not. When it gives a value of a valid descriptor, it gives the value
that the descriptor gives: the spec version, the pack name, the release
number, the license, the name separator, the foreign tag words, the
comment sigils, the grammars, and the test runners with their runner
settings. It gives none of these values for a byte sequence that
is not a valid descriptor, and no adapter hash, adapter license, or
match table for a test runner that has none. When it gives a grammar as
the file grammar of a valid path for a valid descriptor, it gives the
file grammar of that path, and it gives no grammar when the path has
none.

A valid descriptor is a TOML document, and its rules are on the root
table of that document and on TOML values. The rules name keys by the
texts of the TOML keys. They put conditions on TOML values of four
kinds: TOML strings, TOML booleans, TOML arrays, and tables.

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

@term valid-descriptor=v1
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
   `license`, `name-separator`, `comments`, and `grammar`, it can hold
   the texts `foreign-tags` and `runner`, and it holds no other text.
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

8. The TOML value of `comments` is a table that holds no text other
   than `line`, `block`, and `inner`. The TOML values of `line` and of
   `inner`, when that table holds these texts, are each a TOML array of
   TOML strings. The TOML value of `block`, when that table holds that
   text, is a TOML array of TOML arrays, each of exactly two TOML
   strings.
9. The TOML value of `grammar` is a TOML array of one or more tables.
   Each of these tables holds the texts `name`, `sha256`, `license`, and
   `names`, and no other text. In each of them, the TOML value of `name`
   is a TOML string whose text is a grammar name; the TOML value of
   `sha256` is a TOML string whose text fits the hash form; the TOML
   value of `license` is a TOML string; and the TOML value of `names` is
   a TOML array of TOML strings whose texts are each a valid glob. No
   two of these tables have TOML strings of `name` whose texts are the
   same text.
10. The TOML value of `runner`, when the root table holds that text, is
    a table in which each text that the table holds is a pack name, and
    the TOML value of each of these texts is a table that holds exactly
    one of the texts `adapter` and `match`, can hold the text
    `settings`, and holds no other text. In each of these tables, the
    TOML value of `adapter` is a table that holds the texts `sha256` and
    `license`, and no other text, in which the TOML value of `sha256` is
    a TOML string whose text fits the hash form, and the TOML value of
    `license` is a TOML string; the TOML value of `match` is a table;
    and the TOML value of `settings` is a table whose TOML values are
    each a TOML string, a TOML boolean, or a TOML array of TOML
    strings.

The spec version, the name, the release number, the license, and the
name separator of a valid descriptor are the texts of the TOML strings
of `sinter-spec`, `name`, `version`, `license`, and `name-separator` in
its root table. By the descriptor, its spec version names the oldest
version of the specifications of Sinter that the pack needs, and its
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

- The line sigils, each of which opens a comment that ends at the end of
  its line, such as `//`, are the texts of the TOML strings of the TOML
  array of `line`, in their order; none when that table does not hold
  the text `line`.
- The block pairs, each an opening sigil and a closing sigil, such as
  `/*` and `*/`, are, for each TOML array of the TOML array of `block`,
  in their order, the texts of its first and of its second TOML string;
  none when that table does not hold the text `block`.
- The inner sigils, each of which can start a line of a block comment
  after its first line, such as `*`, are the texts of the TOML strings
  of the TOML array of `inner`, in their order; none when that table
  does not hold the text `inner`.

#### 5.1.8 Foreign tag words

@term foreign-tag-word=v1
@cites {
    identifiers#{tag-word=v1},
    data-forms#{root-table=v1, toml-value=v1},
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
    #{pack=v1, valid-descriptor=v1},
}

The foreign tag words of a valid descriptor are, for each TOML string of
the TOML array of `foreign-tags` in its root table, in their order, the
text `@` followed by the text of that TOML string: texts that match the
production `tag-word`, and that, by the descriptor, the language of the
pack, or a tool of that language, uses in comments with a meaning of its
own, such as `@param`. A valid descriptor whose root table does not hold
the text `foreign-tags` gives no foreign tag word.

#### 5.1.9 The grammars of a descriptor

@term descriptor-grammar=v1
@cites {data-forms#{root-table=v1, toml-value=v1}, text#{text=v1, code-span=v1}, #{valid-descriptor=v1}}

The grammars of a valid descriptor are, for each table of the TOML array
of `grammar` in its root table, in their order, one grammar of the
descriptor. A grammar of the descriptor has four values, from its table:
its name, the text of the TOML string of `name`; its hash, the text of
the TOML string of `sha256`; its license, the text of the TOML string of
`license`; and its file-name globs, the texts of the TOML strings of the
TOML array of `names`, in their order.

#### 5.1.10 Test runners

@term test-runner=v1
@cites {
    ontology#{test=v1},
    data-forms#{root-table=v1, toml-value=v1},
    text#{text=v1, code-span=v1},
    #{valid-descriptor=v1},
}

The test runners of a valid descriptor are, for each text that the table
of `runner` in its root table holds, one test runner whose name is that
text. By the descriptor, a test runner is a program that runs tests and
writes report files on them, such as vitest. A valid descriptor whose
root table does not hold the text `runner` has no test runner. The table
of a test runner is the TOML value of its name in the table of `runner`,
and a test runner has these values from its table:

- When its table holds the text `adapter`, its adapter hash is the text
  of the TOML string of `sha256`, and its adapter license is the text of
  the TOML string of `license`, in the table of `adapter`.
- When its table holds the text `match`, its match table is the table
  of `match`.

#### 5.1.11 Runner settings

@term runner-setting=v1
@cites {data-forms#{toml-key-text=v1, toml-value=v1}, text#{text=v1, code-span=v1}, #{valid-descriptor=v1, test-runner=v1}}

A runner setting of a test runner is a name and a default value, for a
value that configuration can give for that test runner. The runner
settings of a test runner of a valid descriptor are, for each pair of
the table of `settings` in the table of that test runner, one runner
setting: its name is the text of the TOML key of that pair, and its
default value is the TOML value of that pair. A test runner whose table
does not hold the text `settings` has no runner setting. The type of a
runner setting is string when its default value is a TOML string,
boolean when its default value is a TOML boolean, and array of strings
when its default value is a TOML array.

#### 5.1.12 File grammars

@term file-grammar=v1
@cites {files#{path=v1, glob-fit=v1}, #{valid-descriptor=v1, descriptor-grammar=v1}}

For a valid descriptor and a valid path, the file grammar of that valid
path is the first grammar of the descriptor, in the order of its
grammars, that has a file-name glob that the last file name of that
valid path fits, where that file name is taken as a valid path of one
file name. When no grammar of the descriptor has such a file-name glob,
that valid path has no file grammar.

### 5.2 Descriptors as input

@req read-descriptor=v1
@cites {text#{conforming-program=v1, result=v1, byte-sequence=v1}, #{valid-descriptor=v1}}

When a conforming program gives a result for whether a byte sequence is
a valid descriptor, it must give exactly one result: "valid" when the
byte sequence is a valid descriptor, and "invalid" when it is not.

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

A conforming program must give, for a byte sequence that is not a valid
descriptor, none of these values: the spec version, the name, the
release number, the license, the name separator, the foreign tag words,
the line sigils, the block pairs, the inner sigils, the grammars, and,
of each grammar, its name, its hash, its license, and its file-name
globs, the test runners, and, of each test runner, its name, its adapter
hash, its adapter license, its match table, and its runner settings,
each with its name and its default value.

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
file grammar of a valid path that has a file grammar, it must give the
file grammar of that valid path, and no other grammar.

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
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The vectors of this specification are in the file
[`packs.descriptor.test-vectors.jsonl`](packs.descriptor.test-vectors.jsonl),
in the same directory as this design. The file is a
[test-vector set](sinter:data-forms#test-vector-set=v1). Each line of the
file is the canonical byte sequence of one JSON object, then the byte
0x0A, so each line is a JSON text, as RFC 8259 defines it. Only a line
feed ends a line of the file. A string of the file can hold U+0085,
U+2028, or U+2029, and these characters do not end a line.

The first line of the file is the set line. Its object has one member,
`rev`: the revision of the test-vector set. Then each group has one
group line, in the key order of the group names. The object of a group
line has two members: `group`, the group name, and `rev`, the revision
of the group. Then each vector has one vector line, in increasing order
of the numbers of the vectors. The object of a vector line has these
members:

- `n`: the number of the vector, an integer of 1 or more.
- `rev`: the revision of the vector.
- `group`: the group name of the vector.
- `input`: the input of the vector.
- `result`: a result, as a string of the characters of the result
  without its double quotes.
- `values`: what a conforming program gives, or does not give, for the
  input, other than the result that `result` stands for.
- `note`: an explanation of the vector, which a conforming program does
  not give. Only some vectors have this member.

A revision is a string of `v` and the decimal numeral of a whole number
of 1 or more, such as `"v1"`. The vectors follow from the requirements
of this specification and add nothing to them. Each subsection below
gives the forms of one group: the requirements of the group, and what
the members `input`, `result`, and `values` of its vectors stand for,
each in a fixed form. A vector without the member `result` states no
result. A vector without the member `values` states nothing that a
conforming program gives for the input, other than its result.

In `input` and `values`, a byte sequence is its hex text, as a string,
such as `"6e616d65"` for the four bytes of `name`, and a text is a
string of the characters of the text. A TOML value of the kinds that the
vectors use has this form: a TOML string is an object with one member,
`string`, whose value is the text of the TOML string; a TOML boolean is
an object with one member, `boolean`, whose value is `true` or `false`;
a TOML array is an object with one member, `array`, whose value is an
array of the forms of its TOML values, in their order; and a table is
an object with one member, `table`, whose value is an object with one
member for each pair of the table, whose key is the text of the TOML
key of the pair and whose value is the form of the TOML value of the
pair.

#### 5.9.1 Descriptors

The group `descriptors` holds the vectors that each give a byte sequence
and what a conforming program gives for it as a descriptor. The
requirements of the group are `read-descriptor`,
`give-descriptor-values`, `omit-invalid-descriptor-values`,
`omit-absent-adapter-values`, and `omit-absent-match-tables`.

- `input`: the byte sequence.
- `result`: the result for whether the byte sequence is a valid
  descriptor, when a conforming program gives that result: "valid" when
  the byte sequence is a valid descriptor, and "invalid" when it is not.
- `values`: with "valid", an object with these members, for the values
  of the valid descriptor: `spec-version`, `name`, `release`, `license`,
  and `name-separator`, each a text; `foreign-tag-words`, `line-sigils`,
  and `inner-sigils`, each an array of texts, in order; `block-pairs`,
  an array with one array of two texts, the opening sigil and the
  closing sigil, for each block pair, in order; `grammars`, an array
  with one object for each grammar, in order, with the members `name`,
  `hash`, `license`, each a text, and `globs`, an array of its file-name
  globs, in order; and `runners`, an array with one object for each test
  runner, in the code point order of their names, with the member
  `name`, a text, the members `adapter-hash` and `adapter-license`, each
  a text, when the test runner has an adapter hash, the member `match`,
  the form of its match table, when it has a match table, and the member
  `settings`, an array with one object for each runner setting, in the
  code point order of their names, with the members `name`, a text, and
  `default`, the form of its default value. With "invalid", the empty
  object, `{}`.

With "valid", a conforming program gives each of these values as the
value of the valid descriptor that it names, when it gives that value.
An absent member `adapter-hash`, `adapter-license`, or `match` means
that a conforming program gives no such value for the test runner. The
order of the elements of `runners`, and of `settings` in each test
runner, is not a value that a conforming program gives, so a program
that runs the vectors compares them as sets. With `{}`, it gives none of
these values.

```
{"group":"descriptors","input":"ff","n":52,"note":"not valid UTF-8","result":"invalid","rev":"v1","values":{}}
```

#### 5.9.2 File grammars

The group `file-grammars` holds the vectors that each give a valid
descriptor, a valid path, and the file grammar of that valid path. The
requirements of the group are `give-file-grammars` and
`omit-file-grammars`.

- `input`: an object with two members: `descriptor`, the byte sequence
  of a valid descriptor, and `path`, the valid path, as a text.
- `result`: no vector of the group has this member.
- `values`: when the valid path has a file grammar, an object with one
  member, `grammar`, the name of that file grammar, as a text. When it
  has no file grammar, the empty object, `{}`.

When a conforming program gives a grammar as the file grammar of the
valid path, it gives the grammar whose name `grammar` holds. With `{}`,
it gives no grammar as the file grammar of the valid path.

## 6. Runner adapters
@spec adapters=v1

When a conforming program decides whether a byte sequence is a valid
adapter, it gives "valid" when it is one in that decision, and "invalid"
when it is not.
When it gives the result of a call of a function of an adapter with a
request and a report content, it gives "recognised", "not recognised",
or "failed" for the function recognise, and "bound" or "failed" for the
function bind. When it makes a call of a function of a byte sequence as
the adapter of a test runner of a valid descriptor, under a valid
binding of `runner-settings` for that test runner, the request of the
call is the request of that function for that test runner, binding,
report name, and, for bind, root and test entries. It runs the code of
an adapter only in an instance of the adapter, it ends that code in each
call and in each decision whether a byte sequence is a valid adapter,
and it gives −1 to that code at a growth of a memory or of a table past
its maximum.

### 6.1 Definitions

#### 6.1.1 Instances of adapters

@term adapter-instance=v1
@cites {
    wasm-core/2.0,
    text#{whole-number=v1, code-span=v1},
    #{webassembly-module=v1},
}

An instance of an adapter of a WebAssembly module, for a program, is a
new instance of that module that the program makes with no import, and
in which code runs as the WebAssembly Core Specification 2.0 defines its
execution, with the program as its embedder. The limits of a program are
limits of its own on the resources of an instance of an adapter. The
choices of the program in an instance of an adapter are the outcomes
that that specification leaves to the embedder, and they are these:

- a stop of the instantiation, or of an invocation, whose code goes past
  the limits of the program;
- a refusal of a growth of a memory or of a table within its maximum, at
  which the code gets −1;
- the depth of calls at which the call stack is exhausted;
- the bits of a NaN.

An instantiation or an invocation fails when it traps, or when the
program stops it. The maximum of a memory is the maximum of its memory
type, or 65,536 pages when its memory type has none. The maximum of a
table is the maximum of its table type, or 4,294,967,295 elements when
its table type has none. A growth of a memory or of a table past its
maximum gives −1 to the code, as that specification defines, and it is
not a choice of the program.

#### 6.1.2 Valid adapters

@term valid-adapter=v1
@cites {
    wasm-core/2.0, wasmtime/36.0.19, tree-sitter/0.26.13,
    text#{byte-sequence=v1, code-span=v1, conforming-program=v1},
    #{webassembly-module=v1, adapter-instance=v1},
}

A byte sequence is a valid adapter, in one decision of a program whether
it is one, when, and only when, it meets each of these conditions:

1. It is a WebAssembly module, and wasmtime 36.0.19 compiles it:
   `Module::new` of wasmtime 36.0.19, as the feature `wasm` of
   tree-sitter 0.26.13 builds it, with the Cranelift compiler and its
   default configuration otherwise, with an `Engine` with its default
   configuration, gives a module for it, and no error.
2. The module has no import.
3. The module exports `memory` as a memory, `sinter_interface` as a
   function of the type `[] -> [i32]`, `sinter_alloc` as a function of
   the type `[i32] -> [i32]`, `sinter_recognise` as a function of the
   type `[i32 i32 i32 i32] -> [i64]`, and `sinter_bind` as a function of
   the type `[i32 i32 i32 i32] -> [i64]`. It can export other names.
4. In an instance of an adapter of the module that the program makes
   for this decision, in which the program makes only the instantiation
   and then an invocation of `sinter_interface`, the instantiation and
   that invocation do not fail, and the invocation gives the `i32` value
   1, which is the version of the interface.

A choice of the program can change that instantiation or that
invocation, so two decisions whether a byte sequence is a valid adapter,
of one program or of two conforming programs, can differ. By the
interface, `sinter_alloc` reserves the given number of bytes in the
memory and gives the address of the first of them, an address other
than 0 also for 0 bytes, or gives 0 when it cannot reserve them.

#### 6.1.3 Bindings of `runner-settings`

@term runner-setting-binding=v1
@cites {
    ontology#{parameter=v1},
    data-forms#{toml-value=v1},
    text#{text=v1, code-span=v1},
    #{valid-descriptor=v1, test-runner=v1, runner-setting=v1},
}

A binding of the parameter `runner-settings`, for a test runner of a
valid descriptor, is a finite set of pairs, each a name, which is a
text, and a TOML value. The binding is valid when, and only when, the
name of each pair is the name of a runner setting of that test runner,
no two pairs have the same name, and the TOML value of each pair is a
TOML string when the type of that runner setting is string, a TOML
boolean when it is boolean, and a TOML array of TOML strings when it is
array of strings. Under a valid binding, the value of a runner setting
of that test runner is the TOML value of the pair whose name is its
name, or its default value when no pair has its name.

#### 6.1.4 Test entries

@term test-entry=v1
@cites {
    files#{path=v1},
    text#{
        text=v1, whole-number=v1, run=v1, span=v1, position=v1,
        line-number=v1,
    },
    #{
        node-run=v1, test-node=v1, test-name=v1, test-label=v1,
        reading-of-a-text=v1, adapter-call=v1,
    },
}

A test entry is an id, which is a text; a path, which is a valid path; a
first line and a last line, which are whole numbers; a kind, which is
test case or test suite; a name path, which is a sequence of names, each
a sequence of pieces; and test labels, which are a finite set of texts.
The id names the test entry in a call. For a test node that a reading
with the result "parsed" of a text, as the text of a file at a valid
path p, gives, and for an id, the test entry of that test node with that
id has that id; the path p; as its first line and as its last line, the
line numbers of the start and of the end of the run of the node, as a
span of the text; as its kind, test case when the test node is a test
case, and test suite when it is a test suite; its name path; and its
test labels.

#### 6.1.5 Requests

@term adapter-request=v1
@cites {
    data-forms#{json-value=v1, canonical-byte-sequence=v1, toml-value=v1},
    text#{text=v1, byte-sequence=v1, code-span=v1, code-point-order=v1},
    #{
        valid-descriptor=v1, test-runner=v1, runner-setting=v1,
        runner-setting-binding=v1, test-node=v1, test-entry=v1,
        test-name=v1, test-label=v1, adapter-call=v1,
    },
}

This definition is for a test runner of a valid descriptor, a valid
binding of `runner-settings` for that test runner, a report name, which
is a text, and, for the function bind, a root, which is a text, and test
entries whose ids are each a different text. The report name is a text,
such as the path of a report file as a person gave it. The root is a
text, such as the absolute path of the root of a repository. The request
object of the function recognise is a JSON object with these members,
and no other member:

- `interface`: the integer 1.
- `runner`: the name of the test runner, as a string.
- `settings`: an object with one member for each runner setting of the
  test runner, whose key is the name of that runner setting, and whose
  value is the value of that runner setting under the binding: a string
  of its text for a TOML string; a boolean for a TOML boolean; and, for
  a TOML array, an array with a string of the text of each of its TOML
  strings, in their order.
- `report`: the report name, as a string.

The request object of the function bind has these members, and the
members `root`, the root, as a string, and `tests`, and no other
member. The value of `tests` is an array with one object for each test
entry, in the code point order of their ids, with these members, and no
other member:

- `id` and `path`: the id and the path of the test entry, each as a
  string.
- `line` and `eline`: the first line and the last line of the test
  entry, each as an integer.
- `suite`: true when the kind of the test entry is test suite, and false
  when it is test case.
- `names`: an array with one array for each name of the name path of the
  test entry, in their order. The array of a name has one object for
  each piece of that name, in their order. The object of a piece has one
  member, whose key is `text` for a text piece and `placeholder` for a
  placeholder, and whose value is the text of the piece, as a string.
- `labels`: an array with a string of each test label of the test entry,
  in code point order.

The request of a call of the function recognise, or of the function
bind, is the canonical byte sequence of its request object.

#### 6.1.6 Calls

@term adapter-call=v1
@cites {
    wasm-core/2.0,
    text#{byte-sequence=v1, byte=v1, whole-number=v1, code-span=v1},
    #{webassembly-module=v1, adapter-instance=v1, valid-adapter=v1},
}

A call is made by a program with a byte sequence as its adapter, one of
the two functions recognise and bind, a byte sequence as its request,
and a byte sequence as its report content, such as the content of a
report file. The export of the function recognise is `sinter_recognise`,
and the export of the function bind is `sinter_bind`. A call fails when
its request or its report content has 4,294,967,296 bytes or more. A
call uses one decision of the program whether its adapter is a valid
adapter, which the program makes in an instance of an adapter other than
the instance of the steps of the call; an earlier decision of the
program can serve. The call fails when, in that decision, its adapter is
not a valid adapter. Otherwise, the call runs these steps in a new
instance of an adapter of the module of its adapter, for that program,
and it fails when one of them fails, such as when the program stops it
for its limits. In that instance, the program makes only the
instantiation and the invocations of steps 2 to 4, in that order, and it
changes no byte of the memory of the instance other than by the writes
of steps 2 and 3. The memory of the instance is its memory, which it
exports as `memory`, and the size of that memory is its number of bytes
when a step reads it.

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

#### 6.1.7 The results of calls

@term call-result=v1
@cites {
    ontology#{test=v1, test-evidence=v1},
    data-forms#{json-value=v1, json-value-of-a-byte-sequence=v1, index=v1},
    text#{text=v1, result=v1, line-feed=v1, whole-number=v1, code-span=v1},
    #{test-runner=v1, adapter-call=v1, test-entry=v1},
}

The JSON value of a response is the JSON value of the response as a byte
sequence. The result of a call of the function recognise is "recognised"
when the call gives a response whose JSON value is an object with
exactly one member, `recognised`, whose value is true; "not recognised"
when the call gives a response whose JSON value is an object with
exactly one member, `recognised`, whose value is false; and "failed" in
each other case.

The result of a call of the function bind, for test entries, is "bound"
when the call gives a response whose JSON value is an object that has
exactly the members `results`, `bindings`, and `warnings`, and these
rules hold:

1. The value of `results` is an array of result objects. A result object
   is an object that has the members `name` and `status`, can have the
   members `file`, `line`, and `ms`, and has no other member. The value
   of `name` is a string. The value of `status` is the string `pass`,
   `fail`, `error`, or `skip`. The value of `file` is a string. The
   value of `line` is an integer of 1 or more. The value of `ms` is an
   integer of 0 or more.
2. The value of `bindings` is an array of binding objects. A binding
   object is an object that has exactly the members `result`, `test`,
   and `reason`. The value of `result` is an integer of 0 or more that
   is less than the number of the elements of the value of `results`.
   The value of `test` is a string that is the id of one of the test
   entries. The value of `reason` is a string that holds no line feed.
3. No two binding objects have the same value of `result` and the same
   value of `test`.
4. The value of `warnings` is an array of strings.

In each other case, the result of a call of the function bind is
"failed".

A call with the result "bound" gives its test results, its bindings, and
its warnings. Its test results are the elements of the value of
`results`, in their order, each with its name, the value of `name`; its
status, the value of `status`; and, when the result object has these
members, its file, the value of `file`, its line, the value of `line`,
and its duration in whole milliseconds, the value of `ms`. By the
adapter, each test result of a call is a test result that the report
content holds: what a test runner gave for one test that it ran. Its
bindings are the elements of the value of `bindings`, in their order,
each with its test result, which is the element of the value of
`results` whose index is 1 more than the value of `result`; the id of a
test entry, which is the value of `test`; and a reason, which is the
value of `reason`. Its warnings are the texts of the value of
`warnings`, in their order. A call with the result "failed" whose
response has a JSON value that is an object with exactly one member,
`error`, whose value is a string, gives that string as the error text of
the adapter.

By the interface, the function recognise says whether the report
content is the content of a report file of the test runner of the
adapter. The test results of a call stand in the order of the report
content, and a test result has no file, no line, or no duration when the
report content gives none. The reason of a binding says why its test
result binds to its test entry, and a warning is a text for the person
who runs the program.

### 6.2 The validation of adapters

@req validate-adapters=v1
@cites {text#{conforming-program=v1, result=v1, byte-sequence=v1}, #{valid-adapter=v1}}

When a conforming program gives a result for whether a byte sequence is
a valid adapter, it must give exactly one result: "valid" when the byte
sequence is a valid adapter in that decision, and "invalid" when it is
not.

### 6.3 The requests of calls

@req give-requests=v1
@cites {
    text#{conforming-program=v1, byte-sequence=v1, text=v1},
    #{
        valid-descriptor=v1, test-runner=v1, runner-setting-binding=v1,
        adapter-request=v1, adapter-call=v1, test-entry=v1,
    },
}

When a conforming program makes a call of a function of a byte sequence
as the adapter of a test runner of a valid descriptor, under a valid
binding of `runner-settings` for that test runner, for a report name
and, for the function bind, a root and test entries whose ids are each a
different text, it must make the call with the request of that function
for that test runner, binding, report name, root, and test entries as
the request of the call, and with no other byte sequence as that
request.

### 6.4 The results of calls

@req give-call-results=v1
@cites {
    text#{conforming-program=v1, result=v1, byte-sequence=v1},
    #{adapter-call=v1, call-result=v1, test-entry=v1},
}

When a conforming program gives a result of a call that it makes of a
function of a byte sequence as an adapter, with a request and a report
content, it must give exactly one result: the result of that call, for
the test entries for which the program made the call when the function
is bind, which is "recognised", "not recognised", or "failed" for the
function recognise, and "bound" or "failed" for the function bind.

### 6.5 The values of the results of calls

@req give-call-values=v1
@cites {
    ontology#{test-evidence=v1},
    text#{conforming-program=v1, result=v1, text=v1, byte-sequence=v1},
    #{adapter-call=v1, call-result=v1, test-entry=v1},
}

When, with the result of a call that it makes of a function of a byte
sequence as an adapter, with a request and a report content, a
conforming program gives the test results, the bindings, the warnings,
or the error text of the adapter of that call, it must give those that
the call gives, for the test entries for which the program made the call
when the function is bind, in their order, and no other instead.

### 6.6 No values of calls that do not bind

@req omit-call-values=v1
@cites {
    ontology#{test-evidence=v1},
    text#{conforming-program=v1, result=v1, byte-sequence=v1},
    #{adapter-call=v1, call-result=v1, test-entry=v1},
}

A conforming program must give no test results, no bindings, and no
warnings of a call that it makes of a function of a byte sequence as an
adapter, with a request and a report content, when the result of that
call, for the test entries for which the program made the call when the
function is bind, is not "bound".

### 6.7 Error texts of the adapter

@req omit-adapter-error-texts=v1
@cites {
    text#{conforming-program=v1, result=v1, byte-sequence=v1},
    #{adapter-call=v1, call-result=v1, test-entry=v1},
}

A conforming program must give an error text of the adapter for a call
that it makes of a function of a byte sequence as an adapter, with a
request and a report content, only when the result of that call, for the
test entries for which the program made the call when the function is
bind, is "failed" and the call gives that error text.

### 6.8 Where the code of an adapter runs

@req isolate-adapters=v1
@cites {
    text#{conforming-program=v1, byte-sequence=v1},
    #{webassembly-module=v1, adapter-instance=v1},
}

A conforming program must run the code of each byte sequence that it
uses as an adapter only in an instance of an adapter of its module.

### 6.9 Code of adapters that ends

@req end-calls=v1
@cites {
    text#{conforming-program=v1, byte-sequence=v1},
    #{adapter-instance=v1, adapter-call=v1, valid-adapter=v1},
}

A conforming program must end the code of an adapter that it runs, in
each call and in each decision whether a byte sequence is a valid
adapter.

### 6.10 Growths past the maximum

@req answer-growth-past-maximum=v1
@cites {text#{conforming-program=v1, whole-number=v1}, #{adapter-instance=v1}}

A conforming program must give −1 to the code of an adapter at a growth
of a memory or of a table past its maximum, and must not stop that code
there.

### 6.11 Conformance

A program conforms to the specification `adapters` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares. The requirement
`isolate-adapters` has no vectors.

The vectors of this specification are in the file
[`packs.adapters.test-vectors.jsonl`](packs.adapters.test-vectors.jsonl),
in the same directory as this design. The file is a
[test-vector set](sinter:data-forms#test-vector-set=v1). Each line of the
file is the canonical byte sequence of one JSON object, then the byte
0x0A, so each line is a JSON text, as RFC 8259 defines it. Only a line
feed ends a line of the file. A string of the file can hold U+0085,
U+2028, or U+2029, and these characters do not end a line.

The first line of the file is the set line. Its object has one member,
`rev`: the revision of the test-vector set. Then each group has one
group line, in the key order of the group names. The object of a group
line has two members: `group`, the group name, and `rev`, the revision
of the group. Then each vector has one vector line, in increasing order
of the numbers of the vectors. The object of a vector line has these
members:

- `n`: the number of the vector, an integer of 1 or more.
- `rev`: the revision of the vector.
- `group`: the group name of the vector.
- `input`: the input of the vector.
- `result`: a result, as a string of the characters of the result
  without its double quotes.
- `values`: what a conforming program gives, or does not give, for the
  input, other than the result that `result` stands for.
- `note`: an explanation of the vector, which a conforming program does
  not give. Only some vectors have this member.

A revision is a string of `v` and the decimal numeral of a whole number
of 1 or more, such as `"v1"`. The vectors follow from the requirements
of this specification and add nothing to them. Each subsection below
gives the forms of one group: the requirements of the group, and what
the members `input`, `result`, and `values` of its vectors stand for,
each in a fixed form. A vector without the member `result` states no
result. A vector without the member `values` states nothing that a
conforming program gives for the input, other than its result. In
`input` and `values`, a byte sequence is its hex text, as a string, and
a text is a string of the characters of the text.

#### 6.11.1 Adapters

The group `adapters` holds the vectors that each give a byte sequence
and what a conforming program gives for it when it decides whether the
byte sequence is a valid adapter. The requirements of the group are
`validate-adapters`, `end-calls`, and `answer-growth-past-maximum`.

- `input`: the byte sequence.
- `result`: the result of the decision whether the byte sequence is a
  valid adapter, when a conforming program gives that result: "valid"
  when the byte sequence is a valid adapter in that decision, and
  "invalid" when it is not. A conforming program gives the result
  "valid" under the condition that no choice of the program (a stop for
  its limits, a refused growth of a memory or of a table within its
  maximum, the depth at which the call stack is exhausted, or the bits
  of a NaN) changes the instantiation or the invocation of the decision.
  It gives the result "invalid" with no condition.
- `values`: no vector of the group has this member.

```
{"group":"adapters","input":"0061736d01000000","n":1,"note":"a module with no export","result":"invalid","rev":"v1"}
```

#### 6.11.2 Requests

The group `requests` holds the vectors that each give the things of a
call of a function of the adapter of a test runner, and the request of
that call. The requirement of the group is `give-requests`.

- `input`: an object with these members: `function`, the text
  `recognise` or `bind`; `runner`, the name of the test runner, as a
  text; `settings`, an object with one member for each runner setting of
  the test runner, whose key is its name and whose value is its value
  under the binding, as a string for a TOML string, a boolean for a TOML
  boolean, and an array of strings for a TOML array of TOML strings;
  `report`, the report name, as a text; and, for the function bind only,
  `root`, the root, as a text, and `tests`, an array with one object for
  each test entry, in any order. The object of a test entry has the
  members `id`, `path`, `line`, `eline`, `suite`, `names`, and `labels`,
  in the forms that the request object gives them, except that `labels`
  can be in any order.
- `result`: no vector of the group has this member.
- `values`: an object with one member, `request`: the text whose UTF-8
  encoding is the request of the call.

A conforming program makes the call with the UTF-8 encoding of the text
of `request` as the request of the call, and with no other byte
sequence as that request.

```
{"group":"requests","input":{"function":"recognise","report":"out/junit.xml","runner":"vitest","settings":{}},"n":13,"rev":"v1","values":{"request":"{\"interface\":1,\"report\":\"out/junit.xml\",\"runner\":\"vitest\",\"settings\":{}}"}}
```

#### 6.11.3 Responses

The group `responses` holds the vectors that each give the function of
a call of a valid adapter, the ids of the test entries of the call, and
the response that the call gives, and what a conforming program gives
for the call. The requirements of the group are `give-call-results`,
`give-call-values`, `omit-call-values`, and `omit-adapter-error-texts`.

- `input`: an object with these members: `function`, the text
  `recognise` or `bind`; `ids`, for the function bind only, an array of
  the ids of the test entries, as texts; and `response`, the byte
  sequence of the response.
- `result`: the result of the call, when a conforming program gives a
  result for it: "recognised", "not recognised", or "failed" for the
  function recognise, and "bound" or "failed" for the function bind. The
  call is a call of a valid adapter whose invocation of the export of
  the function gives the response, with no failure before it.
- `values`: with "bound", an object with three members: `results`, an
  array with one object for each test result of the call, in order,
  with the members `name` and `status`, each a text, and the members
  `file`, a text, `line`, and `ms`, each an integer, when the test
  result has them; `bindings`, an array with one object for each binding
  of the call, in order, with the members `result`, 1 less than the
  index of its test result in `results`, as an integer, `test`, a
  text, and `reason`, a text; and `warnings`, an array of the warnings
  of the call, as texts, in order. With "failed", when the call gives an
  error text of the adapter, an object with one member, `error`, that
  error text, as a text; otherwise the empty object, `{}`. With
  "recognised" and "not recognised", the empty object, `{}`.

When a conforming program gives the test results, the bindings, the
warnings, or the error text of the adapter of the call, it gives those
of `values`. With `{}`, it gives none of these.

```
{"group":"responses","input":{"function":"recognise","response":"7b227265636f676e69736564223a747275657d"},"n":22,"result":"recognised","rev":"v1","values":{}}
```

#### 6.11.4 Calls

The group `calls` holds the vectors that each give the things of a call:
a byte sequence as the adapter, the function, the request, the report
content, and, for the function bind, the ids of the test entries for
which the program makes the call; and what a conforming program gives
for the call. The requirements of the group are `give-call-results`,
`give-call-values`, `omit-call-values`, `omit-adapter-error-texts`,
`end-calls`, and `answer-growth-past-maximum`.

- `input`: an object with these members: `adapter`, the byte sequence
  of the adapter; `function`, the text `recognise` or `bind`; `request`,
  the byte sequence of the request; `report-content`, the byte sequence
  of the report content; and `ids`, for the function bind only, an array
  of the ids of the test entries, as texts.
- `result`: the result of the call, when a conforming program gives a
  result for it: "recognised", "not recognised", or "failed" for the
  function recognise, and "bound" or "failed" for the function bind. A
  conforming program gives a result other than "failed" under the
  condition that no choice of the program (a stop for its limits, a
  refused growth of a memory or of a table within its maximum, the depth
  at which the call stack is exhausted, or the bits of a NaN) changes
  the instantiation or an invocation of the call, or of the decision
  whether its adapter is a valid adapter that the call uses. It gives
  the result "failed" with no condition.
- `values`: in the form of the member `values` of the group
  `responses`.

When a conforming program gives the test results, the bindings, the
warnings, or the error text of the adapter of the call, it gives those
of `values`. With `{}`, it gives none of these.

```
{"group":"calls","input":{"adapter":"0061736d01000000011a056000017f60017f017f60047f7f7f7f017e60017e017f600000030504000102020503010001074d05066d656d6f727902001073696e7465725f696e7465726661636500000c73696e7465725f616c6c6f6300011073696e7465725f7265636f676e69736500020b73696e7465725f62696e6400030a1b04040041010b040041000b0a0042938080808080010b040042000b0b1a01004180080b137b227265636f676e69736564223a747275657d","function":"recognise","report-content":"3c74657374737569746573206e616d653d22766974657374207465737473223e3c2f746573747375697465733e","request":"7b22696e74657266616365223a312c227265706f7274223a226f75742f6a756e69742e786d6c222c2272756e6e6572223a22766974657374222c2273657474696e6773223a7b7d7d"},"n":62,"note":"sinter_alloc gives the address 0","result":"failed","rev":"v1","values":{}}
```

## 7. Requirements

### 7.1 Whether packs are well named

@req decide-well-named-packs=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, result=v1},
    #{pack=v1, well-named-pack=v1, pack-use=v1},
}

When a conforming program gives a result for whether a pack is well
named, in a use of that pack during which no other process changes a
file of the folder tree of the pack, it must give exactly one result:
"well named" when the pack is well named, and "not well named" when it
is not.

### 7.2 The files of a pack

@req give-pack-files=v1
@cites {
    files#{folder-tree=v1, path=v1},
    text#{conforming-program=v1, text=v1},
    #{pack=v1, well-named-pack=v1, pack-use=v1},
}

When a conforming program gives the valid paths of the files of a
well-named pack, in a use of that pack during which no other process
changes a file of the folder tree of the pack, it must give the valid
path of each file of the pack, and no other text as the valid path of a
file of the pack.

### 7.3 The contents of the files of a pack

@req give-pack-file-contents=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, byte-sequence=v1},
    #{pack=v1, pack-use=v1},
}

When a conforming program gives the content of a file of a pack, in a
use of that pack during which no other process changes a file of the
folder tree of the pack, it must give that content, and no other byte
sequence as that content.

### 7.4 Pack listings as output

@req give-pack-listings=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, text=v1},
    #{pack=v1, well-named-pack=v1, pack-hash=v1, pack-use=v1},
}

When a conforming program gives the pack listing of a pack that has a
pack listing, in a use of that pack during which no other process
changes a file of the folder tree of the pack, it must give the pack
listing of that pack, and no other text, as its pack listing.

### 7.5 No pack listing for a pack that has none

@req omit-pack-listings=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1},
    #{pack=v1, pack-hash=v1, pack-use=v1},
}

In each use of a pack that has no pack listing, during which no other
process changes a file of the folder tree of the pack, a conforming
program must give no text as the pack listing of that pack.

### 7.6 Pack hashes as output

@req give-pack-hashes=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, text=v1},
    #{pack=v1, well-named-pack=v1, pack-hash=v1, pack-use=v1},
}

When a conforming program gives a pack hash for a pack that has a pack
hash, in a use of that pack during which no other process changes a
file of the folder tree of the pack, it must give the pack hash of that
pack, and no other text, as its pack hash.

### 7.7 No pack hash for a pack that has none

@req omit-pack-hashes=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1},
    #{pack=v1, pack-hash=v1, pack-use=v1},
}

In each use of a pack that has no pack hash, during which no other
process changes a file of the folder tree of the pack, a conforming
program must give no text as the pack hash of that pack.

### 7.8 The validation of packs

@req validate-packs=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, result=v1},
    #{pack=v1, pack-use=v1, valid-pack=v1},
}

When a conforming program gives a result for whether a pack is valid, in
a use of that pack during which no other process changes a file of the
folder tree of the pack, it must give exactly one result: "valid" when
the pack is valid, and "invalid" when it is not.

### 7.9 The values of the descriptor of a valid pack

@req give-pack-descriptor-values=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1},
    #{
        pack=v1, pack-use=v1, valid-pack=v1, valid-descriptor=v1,
        spec-version=v1, release-number=v1, name-separator=v1,
        comment-sigil=v1, foreign-tag-word=v1, descriptor-grammar=v1,
        test-runner=v1, runner-setting=v1,
    },
}

When a conforming program gives a value of the descriptor of a valid
pack, in a use of that pack during which no other process changes a file
of the folder tree of the pack, it must give the value that the valid
descriptor that is the content of the file `pack.toml` of that pack
gives, and no other value instead of it.

### 7.10 No reading with a pack that is not valid

@req omit-readings-for-invalid-packs=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, result=v1, text=v1, run=v1},
    #{
        pack=v1, pack-use=v1, valid-pack=v1, parse-tree-order=v1, node-run=v1,
        parse-failure=v1, reading-of-a-text=v1,
    },
}

In a use of a pack during which no other process changes a file of the
folder tree of the pack, a conforming program must give no result of a
reading, no node, and no run of a failure node, of a text with that pack
when the pack is not valid.

### 7.11 The results of readings

@req give-reading-results=v1
@cites {
    files#{folder-tree=v1, path=v1},
    text#{conforming-program=v1, result=v1, text=v1},
    #{pack-use=v1, valid-pack=v1, reading-of-a-text=v1},
}

When a conforming program gives a result of a reading of a text, as the
text of a file at a valid path, with a valid pack, in a use of that pack
during which no other process changes a file of the folder tree of the
pack, it must give exactly one result, the result of that reading: "no
grammar", "parse failure", or "parsed".

### 7.12 The nodes of readings

@req give-reading-nodes=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, result=v1, text=v1},
    #{
        pack=v1, pack-use=v1, reading-of-a-text=v1, comment-node=v1,
        definition-node=v1, decoration-node=v1, test-node=v1,
    },
}

When, for a reading of a text with a pack whose result is "parsed", in a
use of that pack during which no other process changes a file of the
folder tree of the pack, a conforming program gives the comment nodes,
the definition nodes, the decoration nodes, or the test nodes, it must
give each node of that kind that the reading gives once, and no other
node as a node of that kind.

### 7.13 The values of the nodes of readings

@req give-reading-node-values=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, result=v1, run=v1, text=v1},
    #{
        pack=v1, pack-use=v1, reading-of-a-text=v1, node-run=v1,
        node-type=v1, comment-node=v1, definition-node=v1,
        decoration-node=v1, test-node=v1, test-name=v1, test-label=v1,
    },
}

When, for a node that a reading of a text with a pack gives with the
result "parsed", in a use of that pack during which no other process
changes a file of the folder tree of the pack, a conforming program
gives its run, its node type, whether it is tagged, its name nodes, its
body nodes, whether it is a test case or a test suite, its name path,
or its test labels, it must give the value that the reading gives with
that node, and no other value instead of it.

### 7.14 No nodes of the other readings

@req omit-nodes-of-unparsed-readings=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, result=v1, text=v1},
    #{
        pack-use=v1, valid-pack=v1, reading-of-a-text=v1, comment-node=v1,
        definition-node=v1, decoration-node=v1, test-node=v1,
    },
}

In a use of a valid pack during which no other process changes a file of
the folder tree of the pack, a conforming program must give no comment
node, definition node, decoration node, or test node of a reading of a
text with that pack whose result is not "parsed".

### 7.15 The runs of failure nodes

@req give-failure-runs=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, result=v1, run=v1, text=v1},
    #{
        pack=v1, pack-use=v1, reading-of-a-text=v1, parse-failure=v1,
        node-run=v1,
    },
}

When, for a reading of a text with a pack whose result is "parse
failure" and whose parse failure has a failure node, in a use of that
pack during which no other process changes a file of the folder tree of
the pack, a conforming program gives a run as the run of the failure
node, it must give the run of the failure node of that parse failure.

### 7.16 No run of a failure node for the other readings

@req omit-failure-runs=v1
@cites {
    files#{folder-tree=v1},
    text#{conforming-program=v1, result=v1, run=v1, text=v1},
    #{
        pack=v1, pack-use=v1, valid-pack=v1, reading-of-a-text=v1,
        parse-failure=v1, node-run=v1,
    },
}

In a use of a valid pack during which no other process changes a file of
the folder tree of the pack, a conforming program must give no run as
the run of a failure node of a reading of a text with that pack whose
result is not "parse failure", or whose parse failure has no failure
node.

### 7.17 The depth of query texts

@req decide-query-depth=v1
@cites {text#{conforming-program=v1, result=v1, text=v1}, #{query-depth=v1}}

When a conforming program gives a result for whether a text, as a query
text, passes the depth limit, it must give exactly one result: "too
deep" when the text passes the depth limit, and "not too deep" when it
does not.

### 7.18 The place where a query text passes the depth limit

@req give-query-depth-places=v1
@cites {
    text#{
        conforming-program=v1, result=v1, text=v1, character=v1, place=v1,
        position=v1,
    },
    #{query-depth=v1},
}

When, with the result "too deep" for a text as a query text, a
conforming program gives a line number for the place where the text
passes the depth limit, it must give the line number of the position of
the character at that place, and no other line number, for that place.
When it gives a column for that place, it must give the column of the
position of the character at that place, and no other column, for that
place.

### 7.19 What the code of a grammar can reach

@req isolate-grammars=v1
@cites {
    wasm-core/2.0,
    files#{taken-byte=v1},
    text#{conforming-program=v1, byte-sequence=v1},
    #{pack=v1, pack-use=v1, webassembly-module=v1},
}

In each use of a pack, a conforming program must run the code of each
byte sequence that it loads as a grammar of the pack only as the
WebAssembly Core Specification 2.0 defines its execution, in an instance
whose imports give that code no means to take bytes from a file, to
write a file or the output of the process, to use a network, to read a
clock, or to start a process.

### 7.20 No symbolic link followed in a pack

@req follow-no-pack-links=v1
@cites {files#{folder-tree=v1, symbolic-link=v1}, text#{conforming-program=v1}, #{pack=v1, pack-use=v1}}

In each use of a pack, a conforming program must follow no symbolic
link that is a file of the folder tree of the pack: it must find no file
by the reference of such a symbolic link.

### 7.21 Bytes only from the folders and the regular files of a pack

@req read-only-pack-files=v1
@cites {
    files#{folder-tree=v1, folder=v1, regular-file=v1, taken-byte=v1},
    text#{conforming-program=v1},
    #{pack=v1, pack-use=v1},
}

In each use of a pack, a conforming program must take bytes from the
files of the folder tree of the pack only from its folders and from its
regular files.

### 7.22 No wait for another process in a pack

@req avoid-pack-waits=v1
@cites {files#{folder-tree=v1, file-of-another-kind=v1}, text#{conforming-program=v1}, #{pack=v1, pack-use=v1}}

In each use of a pack, a conforming program must not wait for another
process or for a device to act on a file of another kind that is a file
of the folder tree of the pack, such as for a process to open the other
end of a pipe.

### 7.23 No change to the files of a pack

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

### 7.24 No permission or privilege that the process did not have

@req gain-no-pack-privileges=v1
@cites {
    posix/2024,
    files#{system=v1},
    text#{conforming-program=v1},
    #{pack=v1, pack-use=v1},
}

In each use of a pack, a conforming program must use only the
permissions and the appropriate privileges, as POSIX.1-2024 defines
these, such as a capability on a system that gives capabilities to
processes, that its process has without a change by the program: not
one that it gets by a change of the user IDs, the group IDs, or the
appropriate privileges of its process, or through another process that
acts for it.

## 8. Conformance

A program, or a part of a program, conforms to this design when it is a
[conforming program](sinter:text#conforming-program=v1) of this design:
when it meets every requirement of this design, those of its
specifications included. The vectors of the requirements that the
design holds directly, outside its specifications, are in the file
[`packs.test-vectors.jsonl`](packs.test-vectors.jsonl), in the same
directory as this design. The file is a
[test-vector set](sinter:data-forms#test-vector-set=v1). Each line of the
file is the canonical byte sequence of one JSON object, then the byte
0x0A, so each line is a JSON text, as RFC 8259 defines it. Only a line
feed ends a line of the file. A string of the file can hold U+0085,
U+2028, or U+2029, and these characters do not end a line.

These requirements that the design holds directly have no vectors:
`give-pack-file-contents`, `give-pack-descriptor-values`,
`omit-readings-for-invalid-packs`, `give-reading-results`,
`give-reading-nodes`, `give-reading-node-values`,
`omit-nodes-of-unparsed-readings`, `give-failure-runs`,
`omit-failure-runs`, `isolate-grammars`, `follow-no-pack-links`,
`read-only-pack-files`, `avoid-pack-waits`, `keep-packs-unchanged`, and
`gain-no-pack-privileges`. No vector of this file holds a grammar
compiled to WebAssembly, so no vector tests the requirements on usable
grammars, query files that tree-sitter compiles, readings, nodes, or
failure runs.

The first line of the file is the set line. Its object has one member,
`rev`: the revision of the test-vector set. Then each group has one
group line, in the key order of the group names. The object of a group
line has two members: `group`, the group name, and `rev`, the revision
of the group. Then each vector has one vector line, in increasing order
of the numbers of the vectors. The object of a vector line has these
members:

- `n`: the number of the vector, an integer of 1 or more.
- `rev`: the revision of the vector.
- `group`: the group name of the vector.
- `input`: the input of the vector.
- `result`: a result, as a string of the characters of the result
  without its double quotes.
- `values`: what a conforming program gives, or does not give, for the
  input, other than the result that `result` stands for.
- `note`: an explanation of the vector, which a conforming program does
  not give. Only some vectors have this member.
- `needs`: the need names of the needs of the vector, in key order, with
  no name twice. Only a vector with a need has this member.

A revision is a string of `v` and the decimal numeral of a whole number
of 1 or more, such as `"v1"`. The vectors follow from the requirements
of this design that it holds directly and add nothing to them. Each
subsection below gives the forms of one group: the requirements of the
group, and what the members `input`, `result`, and `values` of its
vectors stand for, each in a fixed form. A vector without the member
`result` states no result. A vector without the member `values` states
nothing that a conforming program gives for the input, other than its
result.

In `input` and `values`, a byte sequence is its hex text, as a string,
a text is a string of the characters of the text, and a position is an
object with two members: `line`, the line number, and `column`, the
column, each as an integer. A pack is its folder tree, as a
[folder tree object](sinter:files#folder-tree-object=v1): the
[file object](sinter:files#file-object=v1) of its root, whose member
`type` is `"directory"`. These are the members of a file object in the
vectors:

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
vector whose input is a pack, the requirements of its group oblige the
result and the values of the vector in each use of the pack in which
these conditions hold:

1. A file system stores the folder tree of the folder tree object, for
   the process of the program, as Files defines a
   [stored folder tree](sinter:files#stored-folder-tree=v1), from the
   start of the use to its end. So the process of the program has the
   read permission for each file of the folder tree other than a
   symbolic link, and the search permission for each folder.
2. No other process changes the folder tree during the use.

A check of the vectors makes such a stored folder tree for each vector
whose input is a pack. A need of a vector is a condition on the file
system that stores its folder tree, which a check of the vectors can be
unable to make hold. These are the need names of this design, in key
order, each with the need that it stands for and when a vector has it:

- `case-distinct-names`: the folder tree is on a file system on which
  two entry names that differ only in the case of ASCII letters name two
  different files. A vector has this need when two entry names of one
  folder of its folder tree differ only in the case of ASCII letters,
  such as `README.md` and `readme.md`.
- `long-names`: the folder tree is on a file system that allows each
  entry name of the folder tree, with all its bytes. A vector has this
  need when an entry name of its folder tree has more than 14 bytes:
  `{_POSIX_NAME_MAX}`, 14, is the least value that POSIX.1-2024 allows
  for `{NAME_MAX}`, the greatest number of bytes in a filename.
- `names-kept`: the folder tree is on a file system that keeps each
  entry name of the folder tree as the check makes it, byte for byte:
  for example, the file system does not change an entry name into a
  decomposed form of Unicode normalization. A vector has this need when
  an entry name of its folder tree is valid UTF-8 and holds a byte of
  0x80 or more.
- `non-portable-names`: the folder tree is on a file system on which
  the check can make each entry name of the folder tree that is not a
  portable filename. A portable filename, as POSIX.1-2024 defines it, is
  a filename of characters of the portable filename character set: `A`
  to `Z`, `a` to `z`, `0` to `9`, `.`, `_`, and `-`. By POSIX.1-2024,
  `open()` with `O_CREAT`, `mkdir()`, `mkfifo()`, and `symlink()` fail
  with [EILSEQ] when the last component of the pathname is not a
  portable filename and cannot be created in the target directory. A
  vector has this need when an entry name of its folder tree holds a
  byte that is not the byte of one of these characters, such as a space,
  a line feed, or a byte of 0x80 or more. A byte of 0x80 or more in an
  entry name also gives the vector the need `names-kept` or the need
  `non-utf-8-names`.
- `non-utf-8-names`: the folder tree is on a file system that keeps each
  entry name of the folder tree that is not valid UTF-8 as the check
  makes it, byte for byte. A vector has this need when an entry name of
  its folder tree is not valid UTF-8.

A vector has the member `needs` when, and only when, it has one or more
of these needs, and the member names each need of the vector and no
other. A name in the member `needs` that this list does not hold stands
for no need, and it allows no skip of the vector.

### 8.1 Invalid packs

The group `invalid-packs` holds the vectors that each give a pack that
is not valid. The requirement of the group is `validate-packs`. No pack
of the group has a usable grammar, so each pack whose descriptor is
valid breaks the condition of a valid pack on usable grammars. The note
of each vector names one condition, of a valid pack or of a usable
grammar, that the pack breaks and that a program can decide with no
compiled grammar, such as that the file of a grammar has no import whose
name, after its module name, is `tree_sitter_debug_message`. Apart from
that condition, the pack has a valid descriptor with one grammar, a file
of that grammar whose content has the hash of that grammar, a query file
of the kind comment for that grammar, and a file under `licenses/`.

- `input`: the folder tree object of the pack.
- `result`: the result for whether the pack is valid, when a conforming
  program gives that result: "valid" when the pack is valid, and
  "invalid" when it is not. Each vector of the group has the result
  "invalid".
- `values`: no vector of the group has this member.

```
{"group":"invalid-packs","input":{"entries":[{"file":{"entries":[{"file":{"content":[{"bytes":"0061736d01000000","times":1}],"type":"regular file"},"name":"782e7761736d"}],"type":"directory"},"name":"6772616d6d617273"},{"file":{"entries":[{"file":{"content":[{"bytes":"4d4954204c6963656e73650a","times":1}],"type":"regular file"},"name":"4d49542e747874"}],"type":"directory"},"name":"6c6963656e736573"},{"file":{"entries":[{"file":{"entries":[{"file":{"content":[{"bytes":"28636f6d6d656e74292040636f6d6d656e740a","times":1}],"type":"regular file"},"name":"746167732e73636d"}],"type":"directory"},"name":"78"}],"type":"directory"},"name":"71756572696573"}],"type":"directory"},"n":1,"note":"the pack has no file pack.toml","result":"invalid","rev":"v1"}
```

### 8.2 Pack hashes

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
listing, or the pack hash of the pack, it gives those of `values`. The
order of `files` is not a value that a conforming program gives. With
`{}`, it gives no pack listing and no pack hash for the pack.

```
{"group":"pack-hashes","input":{"entries":[],"type":"directory"},"n":16,"note":"the pack listing is the empty text","rev":"v1","values":{"files":[],"hash":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","listing":""}}
```

### 8.3 The depth of query texts

The group `query-depths` holds the vectors that each give a text and
what a conforming program gives for it as a query text. The
requirements of the group are `decide-query-depth` and
`give-query-depth-places`.

- `input`: the text.
- `result`: the result for whether the text, as a query text, passes the
  depth limit, when a conforming program gives that result: "too deep"
  when the text passes the depth limit, and "not too deep" when it does
  not.
- `values`: with "too deep", an object with one member, `position`: the
  position of the character at the place where the text passes the
  depth limit. With "not too deep", no vector of the group has this
  member.

With "too deep", when a conforming program gives a line number or a
column for the place where the text passes the depth limit, it gives the
line number or the column of `position`.

```
{"group":"query-depths","input":"(a)","n":25,"result":"not too deep","rev":"v1"}
```

### 8.4 Well-named packs

The group `well-named-packs` holds the vectors that each give a pack
and whether it is well named. The requirement of the group is
`decide-well-named-packs`.

- `input`: the folder tree object of the pack.
- `result`: the result for whether the pack is well named, when a
  conforming program gives that result: "well named" when the pack is
  well named, and "not well named" when it is not.
- `values`: no vector of the group has this member.

```
{"group":"well-named-packs","input":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"7061636b2e746f6d6c"}],"type":"directory"},"n":51,"result":"well named","rev":"v1"}
```

The two entry names of this vector, `README.md` and `readme.md`, differ
only in the case of ASCII letters, so the vector has the need
`case-distinct-names`:

```
{"group":"well-named-packs","input":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"524541444d452e6d64"},{"file":{"content":[],"type":"regular file"},"name":"726561646d652e6d64"}],"type":"directory"},"n":55,"needs":["case-distinct-names"],"note":"two files whose paths are the same text after ASCII case folding","result":"not well named","rev":"v1"}
```
