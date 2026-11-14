<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Documents
@design documents=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites packs=v1
@cites findings=v1
@cites commonmark/0.31.2
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies the files of a tree that a conforming program reads, with their readers; the front matter, sections, list items, and paragraph lines of markdown files; the runs of comments, comment lines, attachment, and tests of code files; tag texts, the places that their characters come from, and the inputs that they give; the claims, extents, hash texts, extent hashes, containment, and names of declared items; the Conformance parts of designs and specifications; what citation entries and inline citations name; extern marks, vector files, code texts, code hashes, sites, and edges; the finding classes `parse-error`, `typo-tag`, `ignored-tag`, `invalid-target`, `duplicate`, `dangling`, `wrong-source`, `wrong-kind`, `misplaced-declaration`, `req-outside-design`, and `extern-mismatch`; and requirements for conforming programs that give these.

A conforming program reads the files of a tree to find the items that
Sinter traces and the edges between them. A binding of the parameter
`file-readers` says which files of the tree the program reads, and how.
It reads a markdown file by CommonMark 0.31.2, and a code file with a
language pack. In a markdown file, it reads tags in the first paragraph
of each section and of each list item. In a code file, it reads tags in
the comments that the pack finds. Each of these paragraphs, and each
run of comments that has a tagged comment node, gives one tag text. A
conforming program of Identifiers gives a result for each input of the
tree. Each declaration with the result "valid"
declares an item, which takes up a part of its file: its extent. Each
citation entry of a citation with the result "valid", and each inline
citation with the result "valid", gives an edge. Some conditions of
these texts are findings, such as a citation that names no item.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405. A production, such as
`front-matter-line = ( "+++" / "---" ) *WSP`, gives the texts that its
rule name matches. In a production, `/` separates two alternatives, and
`( )` groups elements. `*` repeats the element after it any number of
times, zero included, and `1*` repeats it one or more times. `[ ]` makes
an element optional. A quoted string such as `"+++"` is its characters,
and `%s"x"` matches its letter only in the same case. `WSP` is a space
or a tab, `SP` is a space, and `DIGIT` is an ASCII digit: these are core
rules of RFC 5234.

From Text and notation, the design takes characters, texts, places,
boundaries, runs, bodies, line endings, lines, line numbers, positions,
and spans; whole numbers and decimal numerals; valid UTF-8 and UTF-8
encodings; the notation of productions; sequences and algorithms; and
conforming programs, inputs, and results. From Identifiers, it takes tag lines, tag words, and Sinter
tag words; declarations, citations, citation entries, status tags,
directives, and continuation lines; links, inline citations, and the
markdown document of a text; the texts of tag lines and inline
descriptions; targets, names, slugs, segments, part names, full names,
kind words, labels, revisions, vector selections, every-part targets,
and external ids; the productions of the forms of tag lines and of
inline citations; the parameter `external-namespaces`; and the inputs of
a conforming program of Identifiers and the results that it gives. From
Files and paths, it takes valid paths, path sets, valid path sets, and
the set of a path set. From Data forms, it takes hashes, indexes, hex
texts, canonical byte sequences, test-vector file names, test-vector
sets, and vector lines. From the Ontology, it takes trees and their
files; parameters; items and their kinds, declared items, containment,
and the names of declared items; tests and comments on tests; sites;
external items; vector sets, conformance vectors, and groups of
conformance vectors; revised content; edges, their kinds, sources, and
cited items, and the item in which a line, a citation, or an inline
citation stands; and findings and finding classes. From Language packs,
it takes packs and valid packs; the reading of a text with a pack;
comment nodes, definition nodes with their body nodes, decoration nodes,
and test nodes with their name paths; the runs of nodes, enclosed nodes,
and the order of the parse tree; and descriptors, with their comment
sigils and foreign tag words. From Findings, it takes the subjects, the
spots, and the other parts of a finding.

From CommonMark 0.31.2, the design takes its lines, blocks, paragraphs,
ATX headings, setext headings, code blocks, block quotes, lists, list
items, link reference definitions, links, and code spans. From RFC 8259, it takes
JSON texts, with their objects, members, arrays, strings, numbers, and
the literal names `true`, `false`, and `null`: each line of the file of
the conformance vectors of the design is a JSON text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [tree](sinter:ontology#tree=v1), [file of a tree](sinter:ontology#tree=v1) | a set of files, each a valid path with a content, which is a byte sequence; no two files of a tree have the same valid path |
| [text of a file](sinter:ontology#tree=v1) | the text of the content of a file of a tree, when that content is valid UTF-8 |
| [valid path](sinter:files#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [path set](sinter:files#path-set=v1), [set of a path set](sinter:files#path-set-membership=v1) | a finite sequence of texts, such as `docs/` followed by `!docs/old/`; its set is the valid paths that it gives, such as `docs/a.md` and not `docs/old/a.md` |
| [pack](sinter:packs#pack=v1), [valid pack](sinter:packs#valid-pack=v1) | a language pack: a folder tree that has the support for one language, such as its grammars and query files; it is valid when it has all its required files, each with the right content |
| [reading of a text](sinter:packs#reading-of-a-text=v1) | the reading of a text, as the text of a file at a valid path, with a valid pack: its result, "no grammar", "parse failure", or "parsed", and, with "parsed", the nodes that the pack finds in the text |
| [comment node](sinter:packs#comment-node=v1), [tagged](sinter:packs#comment-node=v1) | a node of a reading that the pack finds as a comment; it is tagged when it can carry tags |
| [definition node](sinter:packs#definition-node=v1), [body node](sinter:packs#definition-node=v1), [decoration node](sinter:packs#decoration-node=v1) | a node that the pack finds as a definition, such as a function or a module, with the nodes of its body; and a node that the pack finds as a decoration, such as a Rust attribute |
| [test node](sinter:packs#test-node=v1), [name path](sinter:packs#test-name=v1) | a node that the pack finds as the code of one test, with the name of that test as the code writes it |
| [run of a node](sinter:packs#node-run=v1) | the run of the text that a node takes up |
| [order of the parse tree](sinter:packs#parse-tree-order=v1) | the order of the nodes of a parse tree in which each node comes before its descendants, and the first of two children of one node, with its descendants, comes before the second |
| [enclose](sinter:packs#enclosed-node=v1) | a node encloses a different node when its run starts at or before the start of the run of the other node, ends at or after its end, and the other node does not come before it in the order of the parse tree |
| [descriptor](sinter:packs#valid-pack=v1) | the valid descriptor of a valid pack, which gives the comment sigils, the foreign tag words, and the grammars of the pack |
| [comment sigil](sinter:packs#comment-sigil=v1) | a line sigil, such as `//`; the opening sigil and the closing sigil of a block pair, such as `/*` and `*/`; or an inner sigil, such as `*` |
| [foreign tag word](sinter:packs#foreign-tag-word=v1) | a tag word, such as `@param`, that the language of a pack, or a tool of that language, uses in comments with a meaning of its own |
| [binding of `file-readers`](sinter:#file-reader-binding=v1), [reader](sinter:#file-reader-binding=v1) | a finite sequence of pairs, each a reader and a path set; a reader is the text `markdown` or a pack; a binding is valid when each of its path sets is a valid path set and each of its packs is a valid pack; the reader of a valid path is the reader of the first pair whose path set has that valid path in its set |
| [read file](sinter:#read-file=v1) | under a valid binding of `file-readers`, a file of a tree whose valid path has a reader, has no line feed, and does not start or end with a space or a tab |
| [markdown file](sinter:#read-file=v1), [code file](sinter:#read-file=v1) | a read file whose reader is the text `markdown`; a read file whose reader is a pack |
| [cannot be read](sinter:#unreadable-file=v1) | a read file cannot be read when its content is not valid UTF-8, or when it is a code file whose reading has the result "no grammar" or "parse failure" |
| [markdown line](sinter:#markdown-line=v1) | a line of the body of a text as CommonMark 0.31.2 gives it: a line feed, a carriage return with a line feed right after it, and a carriage return that no line feed follows each end one |
| [front matter](sinter:#front-matter=v1), [markdown text](sinter:#front-matter=v1) | the markdown lines from a first line that has only `+++` or `---`, with spaces and tabs after them, to the next such line with the same three characters; the text of a markdown file after its front matter |
| [section](sinter:#markdown-section=v1), [heading that opens a section](sinter:#markdown-section=v1) | the markdown lines from an ATX heading that no block quote and no list item contains, up to the line before the next such heading of the same or a smaller level, or to the end of the markdown text; the lines before the first such heading are the section of level 0 |
| [first paragraph](sinter:#markdown-section=v1) | the first block after the heading of a section that no block quote, no list, and no list item contains, or the first such block of the markdown document for the section of level 0; or the first block of a list item that no block quote, no list, and no list item inside that list item contains; each only when that block is a paragraph |
| [list item](sinter:#markdown-list-item=v1) | a list item of CommonMark 0.31.2 that no block quote contains |
| [line of a paragraph](sinter:#paragraph-line=v1), task marker | the part of a markdown line that a paragraph takes: the first line starts at the first character of the paragraph that is not a space or a tab, and, in the first paragraph of a list item, after a task marker such as `[x]`; each other line is a whole markdown line |
| [code character](sinter:#code-character=v1) | a character of a code file that is in no comment node and in no line ending, and that is not a space or a tab |
| [lines of a run](sinter:#run-line=v1) | for each line that has a place of a run of a text, the places of the run on that line, and the empty lines inside the run |
| [run of comments](sinter:#comment-run=v1) | a sequence of the comment nodes that no other comment node encloses, each of which starts on the last line of the one before it or on the next line, with only spaces, tabs, and line endings between them; a comment node that starts on a line with a code character is a run of comments by itself, and no other comment node joins that run of comments |
| [comment line](sinter:#comment-line=v1) | a line of a tagged comment node without its comment sigils and the spaces and tabs before them |
| [tag text](sinter:#tag-text=v1) | the lines of a first paragraph in a markdown file, or the comment lines of the tagged comment nodes of one run of comments that has a tagged comment node in a code file, joined by line feeds |
| [origin](sinter:#origin=v1), [origin position](sinter:#origin-position=v1) | the places of the text of a file that a part of a tag text or of a markdown text comes from; the position at which that part starts, which is the position of the `@` for the text of a tag line |
| [file line](sinter:#file-line=v1) | a markdown line of a markdown file, or a line that a tag text of a code file joins |
| [input of a tree](sinter:#accepted-input=v1), [accepted input](sinter:#accepted-input=v1), [file of an input](sinter:#accepted-input=v1) | a line of a tag text, with its continuation lines, or a link of a markdown text or of a tag text of a code file, to which a conforming program of Identifiers gives a result; an accepted input gets the result "valid"; the file of an input is the read file of the tag text or the markdown text in which it is |
| [blank line](sinter:#blank-line=v1) | a line of any kind whose text has no character other than spaces and tabs |
| [block of a tag text](sinter:#tag-text-block=v1), trailing prose | a tag line, the tag lines and continuation lines right after it, and its trailing prose: the lines after them up to a blank line, the next tag line, or the end of the tag text |
| [attachment target](sinter:#attachment=v1), [attach](sinter:#attachment=v1), unattached | a definition node or a test node; a run of comments attaches to the first attachment target after it, when no code character stands before it on its first line, each code character between the two is in a decoration node, and each line between them has a code character in a decoration node, or has in it a line of the run of a comment node; a run of comments that attaches to no attachment target is unattached |
| [tests of a read file](sinter:#file-test=v1) | the tests whose code is a test node of a code file that can be read; a markdown file and a read file that cannot be read have none |
| [declaration of a declared item](sinter:#item-file=v1), [file of a declared item](sinter:#item-file=v1) | the accepted input that declares a declared item, and the read file whose tag text has it |
| [claim](sinter:#claim=v1) | the lines that a declaration claims: in markdown, its section or its list item, from its own tag line when another declaration of its paragraph comes before it, up to the next declaration of its paragraph; in code, its part of its block of a tag text; in both, without the blank lines at its end; in markdown, for a declared finding class that is the only declaration of the first paragraph of the section of level 0, every line of its file |
| [scope](sinter:#item-scope=v1) | the file lines in which a design or a specification gathers its items: in markdown, the markdown lines of the section or the list item whose first paragraph has its declaration; in code, for a design, its claim, and for a specification, the lines of its tag text, with the file lines in the run of the attachment target of its run of comments, or every file line of the file when its run of comments is unattached and no code character comes before it |
| [innermost](sinter:#innermost-item=v1) | of some declared items whose claims, or whose scopes, have a thing in them, the one whose claim, or scope, is a subset of that of each of the others, when exactly one is |
| [design of a slug](sinter:#slug-design=v1) | the item of the kind design whose name is the slug, when no other item of the kind design and no decision record has that name |
| [home design](sinter:#home-design=v1) | the innermost item of the kind design in whose scope a tag line or an inline citation is; otherwise, in a code file, when the declaration of the innermost requirement or term in whose claim it is names that requirement or term by a full name whose slug has a design, that design; otherwise, when the declaration of the innermost specification in whose scope it is names it by a full name whose slug has a design, that design; otherwise none |
| [belong to](sinter:#tree-containment=v1), [hold](sinter:ontology#containment=v1) | the relation of containment of the Ontology, in which an item of the kind design or specification holds the declared items that belong to it |
| [extent](sinter:#extent=v1) | the file lines that a declared item takes up: its claim, without the claims of the other declared items inside it that it does not hold, and with the extents of the declared items in the same file that it holds |
| [section number](sinter:#section-number=v1) | the text that the production `section-number` matches, such as `2.1 `, at the start of the text of a heading |
| [hash text](sinter:#extent-hash=v1), [extent hash](sinter:#extent-hash=v1) | the text that the lines of the revised content of a declared item give after some changes, such as the change of the line of its declaration to its inline description; and the hash of the UTF-8 encoding of that text, which is the measure of revised content |
| [code text](sinter:#code-hash=v1), [code hash](sinter:#code-hash=v1) | the text of the code of an attachment target, line by line; the hash of the UTF-8 encoding of the code text of the attachment target to which a run of comments with a tagged comment node attaches |
| [Conformance part](sinter:#conformance-part=v1) | the markdown lines of the Conformance section of a design, or of the Conformance part of a specification: the last section inside its section whose level is one more than the level of its heading; a design has none when the first paragraph of that section declares a specification that belongs to it, and an item whose declaration is in a list item, in the section of level 0, or in a code file has none |
| [set of names](sinter:#name-set=v1) | a set of declared items: the shared set, which has the items of the kind design, the decision records, and the specifications, requirements, and terms that belong to no design and whose names are slugs; the set of the declared finding classes; or the set of the specifications, requirements, and terms that belong to one item of the kind design |
| [kind word states](sinter:#stated-kind=v1) | the kinds of item that a kind word, such as `req`, says that a citation entry or an inline citation names |
| [name names](sinter:#named-item=v1) | the item, or nothing, that the entry name of a citation entry, or the name or the external id of an inline citation, names in a tree |
| [vector path](sinter:#vector-file=v1), [vector file](sinter:#vector-file=v1) | for an item of the kind design, or for an item of the kind specification that belongs to one, the text of the valid path of the file of the design up to its last `/`, that `/` included, or the empty text when that valid path has no `/`, followed by the test-vector file name of the design, or of the design and the specification; a specification that belongs to no design has none; the file of the tree at that valid path, when no other item has that vector path |
| [selected item](sinter:#selected-item=v1) | the conformance vector, the group of conformance vectors, or the vector set that a citation entry with a vector selection names |
| [part of a declared item](sinter:#item-part=v1) | a line, a citation, or an inline citation whose file lines are all lines of the extent of the item |
| [sites of a read file](sinter:#tree-site=v1) | the file lines around citations, inline citations, and `@ack` lines that are outside every extent and every comment on a test, without the lines of extents: in markdown, the lines from a heading that opens a section, or from the start of the markdown text, up to the next such heading or to the end of the markdown text; in code, the lines of runs of comments that are no comments on tests; such parts that share a line of the text, directly or through other such parts, are one site |
| [site](sinter:ontology#site=v1) | a part of a file of a tree that is outside every declared item and every comment on a test, and that has a citation, an inline citation, or an `@ack` line |
| [extern mark](sinter:#extern-mark=v1), [valid extern mark](sinter:#valid-extern-mark=v1) | what an `@extern` line that stands in an item of the kind design states: that the design holds an item of the kind of its kind word, with its part name, in another file; it is valid when the design holds such an item, directly when it is a requirement or a term |
| [edges of a tree](sinter:#tree-edge=v1) | the edges that the citation entries of the accepted citations, and the accepted inline citations, of a tree give |
| [position subject](sinter:#position-subject=v1) | the subject of a finding at a position, such as `docs/guide.md@L3C5` |
| [order of positions](sinter:#position-order=v1) | one position comes before another when its line number is less, or when the two line numbers are the same and its column is less |
| [spot of a run](sinter:#run-spot=v1) | the spot whose span is a run of the text of a read file |
| [tree finding](sinter:#tree-finding=v1) | a finding of a tree with a given class, subject, and spot, that is not ackable, and whose message, mark, related messages, and fix are those that the program that gives it gives |
| [edit distance](sinter:#edit-distance=v1) | the least number of insertions, removals, replacements, and swaps of characters next to each other that change one text into another |
| [finding](sinter:ontology#finding-class=v1), [finding class](sinter:ontology#finding-class=v1) | a report of one condition at one part of a repository; a kind of finding, which a slug names |
| [subject of a finding](sinter:findings#finding-subject=v1) | the text that names what a finding is about |
| [spot](sinter:findings#spot=v1) | a valid path of a file of a tree, alone or with a span of the text of that file |
| [mark of a finding](sinter:findings#mark=v1) | a spot whose span is the part of the spot of a finding that is at fault, with a message |
| [tag line](sinter:identifiers#tag-line=v1), [tag word](sinter:identifiers#tag-word=v1) | a line whose first character after the spaces and tabs at its start is `@`; its tag word is that `@` with the longest run of ASCII letters, ASCII digits, and `-` right after it, such as `@req` |
| [Sinter tag word](sinter:identifiers#sinter-tag-word=v1) | one of the sixteen tag words of Sinter, such as `@req`, `@cites`, `@deprecated`, and `@extern` |
| [declaration](sinter:identifiers#declaration=v1), [citation](sinter:identifiers#citation=v1), [status tag](sinter:identifiers#status-tag=v1), [directive](sinter:identifiers#directive=v1) | a tag line whose tag word is a declaration word, such as `@req`; a citation word, such as `@cites`; a status word, such as `@deprecated`; or `@ack` or `@extern` |
| [continuation line](sinter:identifiers#continuation-line=v1) | a line that continues the target list or the scoped list of a citation on a line before it |
| [link](sinter:identifiers#link=v1), [inline citation](sinter:identifiers#inline-citation=v1) | an inline link, a reference link, or an autolink of the markdown document of a text; an inline citation is a link whose destination starts with `sinter:` |
| [citation entry](sinter:identifiers#citation-entry=v1), [entry name](sinter:identifiers#citation-entry=v1) | one entry of the target of a citation, such as `billing#limit-amount=v2`; its entry name is its name or its external id, such as `billing#limit-amount` |
| [declared item](sinter:ontology#declared-item=v1) | what a declaration declares: an item of the kind design, specification, or requirement, a term, a decision record, or a declared finding class |
| [name of a declared item](sinter:ontology#item-name=v1) | the name in the target of its declaration, such as `billing` or `billing#limit-amount`; or, for an item of the kind specification, requirement, or term whose declaration names it by one segment and that belongs to an item of the kind design, the name of that design, `#`, and that segment |
| [test](sinter:ontology#test=v1), [comment on a test](sinter:ontology#test=v1) | a unit of code that a test runner runs, or a set of such units that the code groups under one name; a comment that is attached to the code of a test |
| [edge](sinter:ontology#edge=v1), [stand in](sinter:ontology#edge-source=v1) | a relation of one kind of edge from its source to its cited item; a line, a citation, or an inline citation stands in the innermost declared item of which it is a part, otherwise in the innermost test such that a comment on that test has it, otherwise in the site that has it, otherwise in no item |
| [every-part target](sinter:identifiers#citation-line=v1) | a slug, `=`, a label, and `#*`, such as `docs=v3#*` |
| [line](sinter:text#line=v1), [line ending](sinter:text#line-ending=v1) | one of the runs into which the line endings of a text divide its body; a line ending is a line feed, with the carriage return right before it when there is one |
| [position](sinter:text#position=v1) | a pair of a line number and a column, such as line 3, column 7 |
| [hash](sinter:data-forms#hash=v1) | the SHA-256 digest of a byte sequence, as 64 hex digits |

## 2. Files, tag texts, items, and edges

### 2.1 Read files and their readers

A [binding of `file-readers`](sinter:#file-reader-binding=v1) gives the
[read files](sinter:#read-file=v1) of a tree, the files that a
conforming program reads, and the reader of each, which makes it a
markdown file or a code file. For example, under the binding with the
pair of the text `markdown` and the path set `docs/`, and then the pair
of a pack for OCaml and the path set `lib/**/*.ml`, the file `docs/a.md`
is a markdown file, the file `lib/x.ml` is a code file whose pack is the
pack for OCaml, and the file `README.md` is not read.

A read file that [cannot be read](sinter:#unreadable-file=v1), such as
one whose content is not valid UTF-8, gives a finding of the class
[`parse-error`](sinter:#parse-error-finding=v1).

### 2.2 Markdown files

A markdown file is read by CommonMark 0.31.2, which divides its text
into [markdown lines](sinter:#markdown-line=v1). A markdown line can
differ from a line of the text: for example, a lone carriage return ends
a markdown line, but not a line of the text. The positions of the
subjects of findings are always the positions of the text.

A markdown file can start with [front matter](sinter:#front-matter=v1),
such as lines of metadata between two lines of `---`. The rest of its
text is its markdown text, which CommonMark 0.31.2 parses into blocks.

The tag lines of a markdown file are inputs of the tree only in its
[tag texts](sinter:#tag-text=v1). Its inline citations are inputs in all
of its markdown text: an inline citation in a heading is an
[input of the tree](sinter:#accepted-input=v1).

This file has three tag texts:

```markdown
# Billing
@design billing=v4
Specifies the invoices that a billing service sends.

## 1. Invoices
@spec invoice=v2
An invoice asks a customer to pay a sum of money.

### 1.1 Amount limit
@req limit-amount=v2
A conforming program must reject an invoice whose amount is more than 10,000 euros.
```

The first tag text is the first paragraph of the
[section](sinter:#markdown-section=v1) of `# Billing`: its two
[lines](sinter:#paragraph-line=v1) after that heading. The second and
the third are the two lines after `## 1. Invoices` and the two lines
after `### 1.1 Amount limit`. The section of level 0 is empty.

Another paragraph gives no tag text, and each of its tag lines can be a
finding of the class [`ignored-tag`](sinter:#ignored-tag-finding=v1),
such as a line `@req r=v1` in the second paragraph of a section. For
example, the lines `@req r=v1`, `Text.`, and `---` make a setext
heading, whose line `@req r=v1` is such a finding too, and the same
lines in an indented code block are no finding. A Sinter tag word in
the inline description of a declaration is such a finding too, such as
`@cites` in the line `@req r=v1 @cites x=v1 Text.`, which a formatter
gives when it joins two tag lines. A Sinter tag word in a code span of
that inline description is no finding.

### 2.3 Code files

A code file is read with its pack: the
[reading of its text](sinter:packs#reading-of-a-text=v1) gives the nodes
of its comments and of its code. Its comment nodes form
[runs of comments](sinter:#comment-run=v1), the comments next to each
other in the file. For example, the lines `// a`, an empty line,
and `// b` give two runs of comments, and so do the lines `// a`,
`f();`, and `// b`, where `f();` has
[code characters](sinter:#code-character=v1).

Each tagged comment node gives its
[comment lines](sinter:#comment-line=v1): its lines without the
[comment sigils](sinter:packs#comment-sigil=v1) of the descriptor of the
pack. For example, with the block pair `/*` and `*/` and the inner sigil
`*`, this comment node gives the comment lines ` @req a=v1`, ` A text.`,
and the empty line:

```c
/* @req a=v1
 * A text.
 */
```

The tags of a code file count in the [tag texts](sinter:#tag-text=v1)
that its runs of comments give. A tag text has
[blocks](sinter:#tag-text-block=v1), which give the claims of
declarations in code. For example, `@param x` is a tag line of a block
too. A line `@deprecated` in a tagged comment node of a JavaScript file
is a status tag, also when the pack has `@deprecated` as a foreign tag
word for JSDoc.

A run of comments can [attach](sinter:#attachment=v1) to the code right
after it, its attachment target, such as a function. So in this Rust
text, the run of comments attaches to the test node of the function, and
the `@verifies` line is in a comment on that test:

```rust
// @verifies billing#limit-amount=v2
#[test]
fn rejects_large_amounts() {
    assert!(check(10_001).is_err());
}
```

A blank line between the comment and the attribute would leave the run
of comments unattached. The test nodes of a code file give its
[tests](sinter:#file-test=v1) and the comments on them.

### 2.4 Inputs, origins, and file lines

A conforming program of the design Identifiers reads the tag texts and
the markdown texts of a tree under a binding of `external-namespaces`,
and it gives a result for each of their
[inputs](sinter:#accepted-input=v1). The inputs with the result "valid",
the accepted inputs, give the [declared items](sinter:#item-file=v1),
the [edges](sinter:#tree-edge=v1), the
[extern marks](sinter:#extern-mark=v1), and the
[status tags](sinter:identifiers#status-tag=v1) of the tree. Under
bindings that are not valid, a conforming program gives none of the
things that
[`give-nothing-under-invalid-bindings`](sinter:#give-nothing-under-invalid-bindings=v1)
names.

The [origin](sinter:#origin=v1) of a part of a tag text or of a markdown
text is the places of the text of its file that it comes from, and its
[origin position](sinter:#origin-position=v1) is where it starts. For
example, the origin position of the text of the tag line in
`(* @req x=v1 *)` is the position of its `@`, not that of the space
before it.

The [file lines](sinter:#file-line=v1) of a read file are the lines on
which claims, extents, scopes, and sites are built.

### 2.5 Claims and extents

Each accepted declaration declares one declared item. Its
[claim](sinter:#claim=v1) is the lines that the declaration claims, such
as the section of the heading before it in markdown. The
[extent](sinter:#extent=v1) of a declared item is the part of its file
that it takes up, which its claim and the items that it holds decide. In
the example of section 2.2, the requirement claims the lines from
`### 1.1 Amount limit` to the end, and the specification and the design
claim their sections. The specification holds the requirement, so the
extent of the specification is its whole section.

In this OCaml text, with the block pair `(*` and `*)`, the specification
`ledger#entry-ids` holds the requirement `id-form`:

```ocaml
(* @spec ledger#entry-ids=v2
   Each entry of the ledger has an id that its own bytes fix. *)
module Entry_id = struct
  (* @req id-form=v1
     An id is "e-" and the first twelve hex digits of a SHA-256. *)
  let of_line line = digest line
end
```

The first run of comments attaches to the definition node of the module.
The [scope](sinter:#item-scope=v1) of the specification is its
tag text, with the file lines in the run of that module. The requirement
`id-form` is declared by one segment. Its declaration is in no scope of
an item of the kind design, and it is in the scope of the specification,
whose declaration has the full name `ledger#entry-ids`. So, when the
slug `ledger` has a [design](sinter:#slug-design=v1), that design is its
[home design](sinter:#home-design=v1), and the requirement belongs to
that design and to the specification. Its name is `ledger#id-form`. The
extent of the specification is its two comment lines and the two comment
lines of the requirement.

### 2.6 Containment and names

Containment says to which design, and to which specification, a declared
item belongs, as [containment in a tree](sinter:#tree-containment=v1)
gives it. For example, `@req billing#limit-amount=v2` belongs to the
design `billing`, when the slug `billing` has a
[design](sinter:#slug-design=v1).

Names come in [sets of names](sinter:#name-set=v1). A citation entry or
an inline citation names an item as
[what names name](sinter:#named-item=v1) says. Its kind word
[states](sinter:#stated-kind=v1) kinds of item, which the class
[`wrong-kind`](sinter:#wrong-kind-finding=v1) checks. For example,
`billing#limit-amount` names the item with that name in the set of the
design of the slug `billing`, and `#limit-amount` names the item with
the name `billing#limit-amount` when `billing` is the home design of the
citation.

### 2.7 Extern marks and vector files

A design can hold items whose declarations are in other files. An
`@extern` line in the design, such as `@extern spec:descriptor`, states
an [extern mark](sinter:#extern-mark=v1) of the design for such an item,
and the class [`extern-mismatch`](sinter:#extern-mismatch-finding=v1)
reports where the extern marks of a design and these items do not agree.
For example, `@req billing#limit=v1` in a markdown file `notes.md` that
has no other declaration is a finding of the class
[`misplaced-declaration`](sinter:#misplaced-declaration-finding=v1),
also when the design `billing`, in another file, has the extern mark
`@extern req:limit`. In a code file, in the comment lines
`@req billing#limit=v1` and, on the next line, `@cites #{amount=v1}`,
the entry `#amount` names the item `billing#amount`, because `billing`
is the home design of that citation.

Each design, and each specification of a design, has a
[vector path](sinter:#vector-file=v1) beside the file of the design. For
example, for the design `billing` declared in `docs/billing.md`, the
vector path of the design is `docs/billing.test-vectors.jsonl`, and that
of its specification `billing#invoice` is
`docs/billing.invoice.test-vectors.jsonl`. A citation entry with a
vector selection names a [selected item](sinter:#selected-item=v1): for
example, `billing#invoice[12]=v1` names the conformance vector whose
vector line is the vector line with the number 12 of the vector set of
that specification.

The [Conformance part](sinter:#conformance-part=v1) of a design or of a
specification in a markdown file is a section inside its own section.
In the example of section 2.2, the design `billing` has none,
because the first paragraph of `## 1. Invoices` declares a specification
that belongs to it. The Conformance part of that specification is the
section of `### 1.1 Amount limit`.

### 2.8 Edges, sites, and status tags

The accepted citations and inline citations of a tree give its
[edges](sinter:#tree-edge=v1). For example, in a file `README.md` with
this text, the `@cites` line is outside every extent, so it stands in
the [site](sinter:#tree-site=v1) of the file, which is its three lines,
and that site is the source of its edge:

```markdown
# Notes
@cites billing#limit-amount=v2
The limit protects new customers.
```

The file has the same site when Identifiers gives that `@cites` line the
result "invalid". A line `@deprecated` right after that `@cites` line
would stand in that site.

### 2.9 Extent hashes and code hashes

The [extent hash](sinter:#extent-hash=v1) of a declared item is the hash
of its hash text, which its revised content gives. For example, for the
requirement of section 2.2, the hash text is the line
`### Amount limit`, an empty line, and the line of its text, each with a
line feed after it. Its extent hash is
`39096d6a3499d398332a59e6882377d2f0b81e206429b16f163df9cb16c00656`.

The [code hash](sinter:#code-hash=v1) of a run of comments is the hash
of the code text of the attachment target to which it attaches.

### 2.10 Findings

Each of these classes has a term that gives its findings, each a
[tree finding](sinter:#tree-finding=v1):

| class | term |
|---|---|
| `parse-error` | [`parse-error-finding`](sinter:#parse-error-finding=v1) |
| `typo-tag` | [`typo-tag-finding`](sinter:#typo-tag-finding=v1) |
| `ignored-tag` | [`ignored-tag-finding`](sinter:#ignored-tag-finding=v1) |
| `invalid-target` | [`invalid-target-finding`](sinter:#invalid-target-finding=v1) |
| `duplicate` | [`duplicate-finding`](sinter:#duplicate-finding=v1) |
| `dangling` | [`dangling-finding`](sinter:#dangling-finding=v1) |
| `wrong-source` | [`wrong-source-finding`](sinter:#wrong-source-finding=v1) |
| `wrong-kind` | [`wrong-kind-finding`](sinter:#wrong-kind-finding=v1) |
| `misplaced-declaration` | [`misplaced-declaration-finding`](sinter:#misplaced-declaration-finding=v1) |
| `req-outside-design` | [`req-outside-design-finding`](sinter:#req-outside-design-finding=v1) |
| `extern-mismatch` | [`extern-mismatch-finding`](sinter:#extern-mismatch-finding=v1) |

## 3. Parameters

### 3.1 `file-readers`

The parameter `file-readers` gives the files of a tree that a conforming
program reads, and the reader of each of them, by its
[bindings](sinter:#file-reader-binding=v1).

## 4. Definitions

### 4.1 Bindings of `file-readers`

@term file-reader-binding=v1
@cites {
    files#{
        path=v1, path-set=v1, valid-path-set=v1, path-set-membership=v1,
    },
    packs#{pack=v1, valid-pack=v1},
    ontology#{parameter=v1},
    text#{text=v1, code-span=v1},
}

A binding of the parameter `file-readers` is a finite sequence of
pairs. Each pair has a reader and a path set. A reader is the text
`markdown` or a pack. A binding of `file-readers` is valid when, and
only when, each of its path sets is a valid path set and each of its
packs is a valid pack. Under a valid binding of `file-readers`, the
reader of a valid path is the reader of the first pair of the binding
whose path set has that valid path in its set. A valid path that is in
the set of no path set of the binding has no reader.

### 4.2 Read files

@term read-file=v1
@cites {
    files#{path=v1},
    ontology#{tree=v1},
    text#{text=v1, character=v1, line-feed=v1, space=v1, tab=v1},
    #{file-reader-binding=v1},
}

Under a valid binding of `file-readers`, a read file of a tree is a
file of the tree whose valid path has a reader, has no line feed, and
has no space and no tab as its first character or as its last
character. The reader of a read file is the reader of its valid path. A
read file is a markdown file when its reader is the text `markdown`. It
is a code file when its reader is a pack, and that pack is the pack of
the code file.

### 4.3 Files that cannot be read

@term unreadable-file=v1
@cites {
    files#{path=v1},
    packs#{reading-of-a-text=v1},
    text#{valid-utf-8=v1, text=v1, result=v1},
    ontology#{tree=v1},
    #{read-file=v1},
}

A read file of a tree cannot be read when, and only when, its content is
not valid UTF-8, or it is a code file and the reading of its text, as
the text of a file at its valid path, with its pack has the result "no
grammar" or the result "parse failure". Each other read file can be
read.

### 4.4 Markdown lines

@term markdown-line=v1
@cites {
    commonmark/0.31.2,
    text#{
        text=v1, run=v1, boundary=v1, body=v1, character=v1, place=v1,
        line-feed=v1, carriage-return=v1,
    },
}

A markdown line ending of a text is a run of its body that has only
one of these: a line feed that no carriage return comes right before; a
carriage return and the line feed right after it; or a carriage return
that no line feed comes right after. A markdown line of a text is a run
of its body that starts at the boundary where the body starts or at the
boundary where a markdown line ending ends, and that ends at the first
boundary, at or after the boundary where it starts, where a markdown
line ending starts, or at the boundary where the body ends when no
markdown line ending starts at or after the boundary where it starts. A
run that ends at the boundary where the body ends is a markdown line
only when it is not empty. The markdown lines of a text are in the order
of the boundaries where they start. So they are the lines of CommonMark
0.31.2 of the body of the text.

### 4.5 Front matter and markdown texts

@term front-matter=v1
@cites {
    rfc/5234,
    identifiers#{link=v1},
    text#{
        text=v1, run=v1, boundary=v1, character=v1, code-span=v1,
        production=v1, rule-name=v1,
    },
    #{read-file=v1, unreadable-file=v1, markdown-line=v1},
}

A front-matter line is a markdown line whose text matches the production
`front-matter-line`:

```abnf
front-matter-line  = ( "+++" / "---" ) *WSP
```

A markdown file that can be read starts with front matter when, and
only when, the first markdown line of its text is a front-matter line,
and a later markdown line of its text is a front-matter line whose first
three characters are the first three characters of that first markdown
line. Its front matter is then the markdown lines of its text from the
first one to the first such later one.

The markdown run of a markdown file that can be read is a run of its
text. When the file has no front matter, its markdown run starts at
boundary 0. Otherwise, its markdown run starts at the boundary where the
markdown line ending right after the last line of its front matter ends,
or at the last boundary of its text when no markdown line ending comes
after that line. Its markdown run ends at the last boundary of its text.
The markdown text of the file is the text of its markdown run. The
markdown lines of the markdown text are the markdown lines of the text
of the file that start at or after the boundary where the markdown run
starts. The markdown document of the file is the markdown document of
its markdown text.

### 4.6 Sections

@term markdown-section=v1
@cites {
    commonmark/0.31.2,
    text#{text=v1, line=v1},
    #{
        markdown-line=v1, front-matter=v1, read-file=v1,
        unreadable-file=v1,
    },
}

This term is for a markdown file that can be read, and for the blocks of
its markdown document as CommonMark 0.31.2 parses that document. A blank
line is no block, and a link reference definition is a block. A block
of the document itself is a block that no block quote, no list, and no
list item contains. The k-th line of CommonMark 0.31.2 of the markdown
document comes from the k-th markdown line of the markdown text. The
markdown lines that a block takes are the markdown lines that the lines
of CommonMark 0.31.2 that the block takes come from.

A heading that opens a section is an ATX heading that is a block of the
document itself. Its line is the markdown line that it takes. Its level
is the number of `#` of its opening sequence. Its section is the
markdown lines from its line to the markdown line right before the line
of the next heading that opens a section and whose level is the same as
its level or less, or to the last markdown line of the markdown text
when no such heading comes after it. The section of level 0 is the
markdown lines of the markdown text that come before the line of the
first heading that opens a section, or all of these markdown lines when
no heading opens a section; it can be empty. The first line of a section
is its first markdown line, and its last line is its last markdown line.

The first paragraph of the section of a heading that opens a section is
the first block of the document itself after that heading, when that
block is a paragraph. The first paragraph of the section of level 0 is
the first block of the document itself, when that block is a paragraph.
Each other section has no first paragraph.

### 4.7 List items

@term markdown-list-item=v1
@cites {
    commonmark/0.31.2,
    #{
        markdown-section=v1, front-matter=v1, read-file=v1,
        unreadable-file=v1, markdown-line=v1,
    },
}

This term is for a markdown file that can be read. Its list items are
the list items of CommonMark 0.31.2 of its markdown document, at each
depth of lists, that no block quote contains. The markdown lines of a
list item are the markdown lines that it takes, together with those of
the lists that it contains. Its first line is the first of these
markdown lines, and its last line is the last of them. The first
paragraph of a list item is the first block that the list item contains
and that no block quote, no list, and no list item inside the list item
contains, when that block is a paragraph.

### 4.8 The lines of a paragraph

@term paragraph-line=v1
@cites {
    rfc/5234,
    rfc/7405,
    commonmark/0.31.2,
    text#{
        text=v1, run=v1, boundary=v1, place=v1, character=v1, space=v1,
        tab=v1, code-span=v1, production=v1, rule-name=v1,
    },
    #{markdown-line=v1, markdown-section=v1, markdown-list-item=v1},
}

A task marker is a text that matches the production `task-marker`:

```abnf
task-marker  = "[" ( SP / %s"x" / %s"X" ) "]" 1*WSP
```

The lines of a paragraph of the markdown document of a markdown file
are runs of the text of the file. They come, in their order, from the
markdown lines that the paragraph takes:

- Its first line is the run of the first of these markdown lines that
  starts at the place of the first character, among the characters of
  that markdown line that CommonMark 0.31.2 gives to the content of the
  paragraph, that is not a space or a tab, and that ends where that
  markdown line ends. For the first paragraph of a list item, when this
  run starts with a run whose text matches `task-marker`, the first line
  is the part of this run after the longest such run.
- Each other line is the whole markdown line.

### 4.9 Code characters

@term code-character=v1
@cites {
    packs#{reading-of-a-text=v1, comment-node=v1, node-run=v1},
    text#{
        text=v1, character=v1, place=v1, body=v1, line-ending=v1,
        space=v1, tab=v1,
    },
    #{read-file=v1, unreadable-file=v1},
}

A code character of a code file that can be read is a character at a
place of the body of its text that is a place of the run of no comment
node of the reading of its text with its pack, that is not a space or a
tab, and that is a place of no line ending.

### 4.10 The lines of a run

@term run-line=v1
@cites text#{text=v1, run=v1, line=v1, boundary=v1, place=v1}

The lines of a run r of a text are these runs of the text, in the order
of the boundaries where they start:

- for each line of the text that has a place of r, the run of the
  text from the greater of the boundaries where r and that line start
  to the lesser of the boundaries where r and that line end;
- each empty line of the text whose boundary comes after the boundary
  where r starts and before the boundary where r ends.

### 4.11 Runs of comments

@term comment-run=v1
@cites {
    packs#{
        reading-of-a-text=v1, comment-node=v1, enclosed-node=v1,
        node-run=v1, parse-tree-order=v1,
    },
    text#{
        text=v1, run=v1, boundary=v1, span=v1, position=v1, line=v1,
        line-number=v1, character=v1, space=v1, tab=v1, line-ending=v1,
    },
    #{read-file=v1, unreadable-file=v1, code-character=v1},
}

This term is for a code file that can be read, and for the comment nodes
of the reading of its text with its pack. The first line number of a
comment node is the line number of the position of the boundary where
its run starts. Its last line number is the line number of the line that
has the last place of its run that is a place of a line, or its first
line number when no place of its run is a place of a line. So the last
line number of a comment node whose run has the line ending after its
last line is the line number of that last line. A line number has a
code character when the line of the text with that line number has
one. An outer comment node is a comment node that no other comment node
encloses. A comment node that another comment node encloses is in no run
of comments.

The runs of comments of the file are sequences of outer comment nodes.
These rules give them, for each outer comment node in turn, in the order
of the boundaries where their runs start, and, of two whose runs start
at one boundary, in the order of the parse tree:

1. When the first line number of the comment node has a code
   character, the comment node starts a new run of comments, and no
   other comment node joins that run of comments.
2. Otherwise, the comment node joins the run of comments of the outer
   comment node right before it when each of these is true: its first
   line number is the last line number of that comment node or 1 more;
   the boundary where its run starts is not before the boundary where
   the run of that comment node ends, and the run of the text between
   these two boundaries has no character other than spaces, tabs, and
   the characters of line endings; and rule 1 did not start that run of
   comments.
3. Otherwise, the comment node starts a new run of comments.

A run of comments starts at the boundary where the run of its first
comment node starts. The run of comments ends at the boundary where the
run of its last comment node ends. Its first line number is the first
line number of its first comment node, and its last line number is the
last line number of its last comment node.

### 4.12 Comment lines

@term comment-line=v1
@cites {
    packs#{comment-sigil=v1, comment-node=v1, valid-pack=v1},
    text#{text=v1, run=v1, boundary=v1, space=v1, tab=v1},
    #{read-file=v1, unreadable-file=v1, run-line=v1},
}

This term is for a tagged comment node of a code file that can be read,
and for the comment sigils of the descriptor of the pack of that file.
The comment lines of the comment node are the lines of its run, each
made shorter as these rules say, where to remove a text from the start
or from the end of a run is to make the run start after it or end before
it:

- On its first line, remove the spaces and tabs at its start. Then
  remove the longest text, among the line sigils and the opening sigils,
  that the rest starts with. The comment node is a line comment when
  that text is a line sigil; a block comment of the first block pair
  whose opening sigil is that text, when that text is an opening sigil
  and no line sigil; and a comment with no sigil when the rest starts
  with no line sigil and no opening sigil. When the first line is also
  the last line of the run and the comment node is a block comment, then
  remove the closing sigil of its block pair from the end of what
  remains, when what remains ends with it.
- On each other line of a block comment, remove the spaces and tabs at
  its start. When it is the last line of the run, then remove the
  closing sigil of its block pair from its end, when what remains ends
  with it. Then remove the longest inner sigil that what remains starts
  with, when it starts with one.
- On each other line of a line comment, remove the spaces and tabs at
  its start, and then the longest line sigil that what remains starts
  with, when it starts with one.
- On each other line of a comment with no sigil, remove the spaces and
  tabs at its start.

### 4.13 Tag texts

@term tag-text=v1
@cites {
    text#{text=v1, line=v1, line-feed=v1, run=v1},
    #{
        read-file=v1, unreadable-file=v1, markdown-section=v1,
        markdown-list-item=v1, paragraph-line=v1, comment-run=v1,
        comment-line=v1, file-reader-binding=v1,
    },
}

Under a valid binding of `file-readers`, the tag texts of a read file of
a tree that can be read are these texts, and the file has no other tag
text:

- for a markdown file: one for each first paragraph of a section and
  each first paragraph of a list item, which joins the lines of that
  paragraph;
- for a code file: one for each run of comments that has a tagged
  comment node, which joins the comment lines of its tagged comment
  nodes, the comment lines of each comment node in their order and the
  comment nodes in their order in the run of comments.

A tag text that joins runs is the text of these runs, in their order,
with a line feed between each two of them. The lines that it joins are
these runs. The k-th line of a tag text comes from the k-th line that it
joins. A read file that cannot be read has no tag text.

### 4.14 Origins

@term origin=v1
@cites {
    commonmark/0.31.2,
    identifiers#{
        link=v1, tag-line=v1, tag-word=v1, tag-line-text=v1,
        continuation-line=v1, citation-entry=v1, citation-line=v1,
    },
    text#{
        text=v1, character=v1, place=v1, boundary=v1, run=v1, body=v1,
        position=v1, line-feed=v1,
    },
    #{read-file=v1, tag-text=v1, front-matter=v1},
}

For a read file, these characters each come from one place of its text,
or from no place:

- Each character of the text of the file comes from its own place.
- Each line feed of a tag text of the file that stands between two of
  the lines that the tag text joins comes from no place. Each other
  character of the tag text is a character of one of the runs that the
  tag text joins, and it comes from the place of that character in the
  text of the file.
- The k-th character of the markdown text of a markdown file comes from
  the k-th place of its markdown run.
- The k-th character of the markdown document of a tag text or of a
  markdown text comes from the place that the k-th character of the body
  of that text comes from.
- Each character of the text of a tag line of a tag text is a character
  of the tag text: a character of the line of the tag line or of one of
  its continuation lines, or the line feed of the tag text before a
  continuation line. It comes from the place that this character of the
  tag text comes from.

A citation entry of a citation of a tag text has a run in the text of
that citation: the run that `cites-single`, `verifies-single`,
`fixed-single`, or `supersedes-single` matches for it; or, for a
citation entry for which a part of a scoped list stands, the run that
`cites-part`, `verifies-part`, or `fixed-part` matches for that part. A
link of a markdown document is the run of that document from the
character at which CommonMark 0.31.2 starts the link, `[` or `<`, to the
last character of the link.

The origin of a run of one of these texts, such as a line of a tag text,
the text of a tag line, a citation entry, a link, or the first line of a
paragraph, which is a run of the text of the file, is the set of the
places that its characters come from. When its origin is not empty, its
run in the text of the file starts at the boundary right before the
first place of its origin, and it ends at the boundary right after the
last place of its origin. For the text of a tag line, that run starts
instead at the boundary right before the place that its `@` comes from.

### 4.15 Origin positions

@term origin-position=v1
@cites {
    identifiers#{tag-line=v1, tag-word=v1, tag-line-text=v1},
    text#{position=v1, place=v1, text=v1},
    #{origin=v1, read-file=v1, tag-text=v1},
}

The origin position of a run of the text of a read file, of a tag text,
of the text of a tag line, or of a markdown document of a tag text or of
a markdown text, when its origin is not empty, is the position of the
first place of its origin in the text of the file. The origin position
of the text of a tag line is instead the position of the place that its
`@` comes from.

### 4.16 File lines

@term file-line=v1
@cites {
    text#{text=v1, run=v1, boundary=v1, place=v1, line=v1},
    #{
        read-file=v1, unreadable-file=v1, markdown-line=v1, tag-text=v1,
        origin=v1,
    },
}

The file lines of a read file that can be read are runs of its text:
for a markdown file, its markdown lines; for a code file, the lines that
its tag texts join. The file lines are in the order of the boundaries
where they start.

The file lines of a thing of the file are these:

- of a file line: that file line;
- of a line of a tag text of a code file: the line that it comes from;
- of a line of a tag text of a markdown file: the markdown line that
  starts at or before the boundary where the line that it comes from
  starts, and that ends at or after the boundary where that line ends;
- of the text of a tag line of a tag text: the file lines of the lines
  of the tag text that the tag line and its continuation lines are;
- of each other run of a tag text, of the text of a tag line, or of a
  markdown document of a tag text or a markdown text: the file lines
  that have a place of its origin.

A thing is in a set of file lines when each of its file lines is a line
of that set. It is outside a set of file lines when none of its file
lines is a line of that set.

### 4.17 Inputs and accepted inputs

@term accepted-input=v1
@cites {
    identifiers#{
        input=v1, binding=v1, link=v1, continuation-line=v1,
        citation=v1, accept-inputs=v1,
    },
    text#{conforming-program=v1, result=v1, line=v1},
    ontology#{tree=v1},
    #{
        read-file=v1, unreadable-file=v1, tag-text=v1, front-matter=v1,
        file-reader-binding=v1,
    },
}

This term is for a tree, a valid binding of `file-readers`, and a
binding of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid". The inputs of the tree are
these inputs of a conforming program of the design Identifiers that
reads, under that binding of `external-namespaces`, each tag text of
each read file of the tree that can be read, and the markdown text of
each markdown file of the tree that can be read:

- each line of each of these tag texts, other than a continuation line,
  together with its continuation lines when it is a citation;
- each link of the markdown document of the markdown text of each of
  these markdown files;
- each link of the markdown document of each tag text of each of these
  code files.

The result of an input of the tree is the result that such a program
gives for it. An accepted input of the tree is an input of the tree
whose result is "valid". The file of an input of the tree is the read
file of the tag text or of the markdown text in which it is.

### 4.18 Blank lines

@term blank-line=v1
@cites {
    text#{text=v1, line=v1, character=v1, space=v1, tab=v1},
    #{markdown-line=v1, tag-text=v1, file-line=v1},
}

A line of each kind, such as a line of a text, a markdown line, a line
of a tag text, or a file line, is blank, and is a blank line, when, and
only when, its text has no character other than spaces and tabs.

### 4.19 Blocks of tag texts

@term tag-text-block=v1
@cites {
    identifiers#{tag-line=v1, continuation-line=v1},
    text#{text=v1, line=v1},
    #{tag-text=v1, blank-line=v1},
}

A block of a tag text starts at each line of the tag text that is a tag
line and that is the first line of the tag text or comes right after a
line that is neither a tag line nor a continuation line. The lines of
the block are that line; each line right after it, one after another,
that is a tag line or a continuation line; and then its trailing prose:
each line right after these, one after another, that is neither a tag
line nor a blank line. The lines of a block are in their order in the
tag text. Its first line is the line at which it starts, and its last
line is its last line in that order.

### 4.20 Attachment

@term attachment=v1
@cites {
    packs#{
        definition-node=v1, test-node=v1, decoration-node=v1,
        node-run=v1, parse-tree-order=v1, comment-node=v1,
    },
    text#{
        boundary=v1, line=v1, line-number=v1, position=v1, span=v1,
        place=v1,
    },
    #{
        read-file=v1, unreadable-file=v1, code-character=v1,
        comment-run=v1, run-line=v1,
    },
}

This term is for a code file that can be read. Its attachment targets
are the definition nodes and the test nodes of the reading of its text
with its pack. The first line number of an attachment target is the line
number of the position of the boundary where its run starts. A run of
comments R attaches to the attachment target T when, and only when, each
of these is true:

1. Of the attachment targets whose runs start at or after the boundary
   where R ends, T is one whose run starts at the first such boundary;
   of these, T is one whose run ends at the last boundary; and of these,
   T comes first in the order of the parse tree.
2. No code character is at a place before the boundary where R starts
   on the line of the text whose line number is the first line number of
   R.
3. Each code character at a place after the boundary where R ends and
   before the boundary where the run of T starts is at a place of the
   run of a decoration node. Each line of the text whose line number is
   greater than the last line number of R and less than the first line
   number of T has a code character at a place of the run of a
   decoration node, or has in it a line of the run of a comment node.

A run of comments that attaches to no attachment target is unattached.
Two or more runs of comments can attach to one attachment target. For
example, when `#[test]` is a decoration node and the function is the
attachment target, each of the two runs of comments in these lines
attaches to the function `t`:

```rust
// @verifies x#y=v2
#[test]
// @satisfies a#b=v1
fn t() {}
```

### 4.21 The tests of a read file

@term file-test=v1
@cites {
    packs#{reading-of-a-text=v1, test-node=v1, test-name=v1, node-run=v1},
    ontology#{test=v1},
    #{read-file=v1, unreadable-file=v1, attachment=v1, comment-run=v1},
}

A markdown file has no test, and a read file that cannot be read has no
test. For a code file that can be read, each test node of the reading
of its text with its pack is the code of one test of the file, and the
file has no other test. The name of that test is the name path of its
test node. The code of that test is the run of its test node. A comment
on that test is a run of comments of the file that attaches to an
attachment target whose run is the run of its test node.

### 4.22 The files of declared items

@term item-file=v1
@cites {
    identifiers#{declaration=v1},
    ontology#{declared-item=v1, tree=v1},
    #{read-file=v1, tag-text=v1, accepted-input=v1},
}

Each accepted input of a tree that is a declaration declares one
declared item of the tree, and the tree has no other declared item. That
accepted input is the declaration of the declared item. The file of the
declared item is the read file whose tag text has its declaration.

### 4.23 Claims

@term claim=v1
@cites {
    ontology#{declared-finding-class=v1, declared-item=v1},
    text#{line=v1},
    #{
        item-file=v1, tag-text=v1, file-line=v1, markdown-line=v1,
        front-matter=v1, markdown-section=v1, markdown-list-item=v1,
        tag-text-block=v1, blank-line=v1,
    },
}

The claim of a declared item d of a tree is a set of file lines of its
file. In this term, the declarations of a tag text are those of its
lines that are the declarations of declared items, in their order, and
the line of a declaration is its file line. These rules give the claim
of d:

1. When d is a declared finding class, its file is a markdown file, and
   its declaration is the only declaration of the tag text of the first
   paragraph of the section of level 0: every markdown line of the file,
   the lines of its front matter included.
2. When the file of d is a markdown file and rule 1 does not apply: the
   declaration of d is in the tag text of the first paragraph of a
   section or of a list item S. The claim starts at the first line of S
   when the declaration of d is the first declaration of that tag text,
   and otherwise at the line of the declaration of d. It ends at the
   markdown line right before the line of the next declaration of that
   tag text, when there is one, and otherwise at the last line of S. The
   claim is the markdown lines from the line at which it starts to
   the line at which it ends.
3. When the file of d is a code file: the declaration of d is a line of
   a block B of a tag text. The claim starts at the first line of B when
   the declaration of d is the first declaration in B, and otherwise at
   the line that is the declaration of d. It ends at the line of B right
   before the next declaration in B, when there is one, and otherwise at
   the last line of B. The claim is the file lines of the lines of
   B from the line at which it starts to the line at which it ends.

Then the claim loses its blank lines after its last line that is not
blank, in the order of the file lines.

### 4.24 The scopes of designs and specifications

@term item-scope=v1
@cites {
    ontology#{declared-item=v1},
    text#{boundary=v1, run=v1, place=v1},
    #{
        read-file=v1, item-file=v1, claim=v1, file-line=v1, tag-text=v1,
        comment-run=v1, attachment=v1, code-character=v1,
        markdown-line=v1, markdown-section=v1, markdown-list-item=v1,
    },
}

The scope of an item d of the kind design or of the kind specification
of a tree is a set of file lines of its file:

- When its file is a markdown file, and S is the section or the list
  item whose first paragraph gives the tag text that has the declaration
  of d: the markdown lines of S.
- When its file is a code file and d is of the kind design: the lines of
  its claim.
- When its file is a code file, d is of the kind specification, and R is
  the run of comments whose tag text has the declaration of d: when R
  attaches to an attachment target T, the lines that the tag text of R
  joins, with each file line whose run starts at or after the boundary
  where the run of T starts and ends at or before the boundary where the
  run of T ends; when R is unattached and no code character of the file
  is at a place before the boundary where R starts, each file line of the
  file; otherwise, the lines that the tag text of R joins.

A thing is in the scope of d when it is in this set of file lines.

### 4.25 Innermost items

@term innermost-item=v1
@cites {
    ontology#{declared-item=v1},
    #{file-line=v1, item-scope=v1},
}

Take a thing and some declared items, each with a set of file lines in
which the thing is. The innermost of these declared items by these sets
is the one whose set is a subset of the set of each of the others, when
exactly one of them is; otherwise, none of them is the innermost. The
innermost item of the kind design, or of the kind specification, in
whose scope a thing is, is the innermost, by their scopes, of the items
of that kind in whose scopes the thing is.

### 4.26 The designs of slugs

@term slug-design=v1
@cites {
    identifiers#{slug=v1},
    ontology#{item-name=v1, declared-item=v1, decision-record=v1},
    #{item-file=v1},
}

In a tree, the design of a slug is the item of the kind design whose
name is that slug, when no other declared item of the tree that is an
item of the kind design or a decision record has that slug as its name.
Otherwise, the slug has no design.

### 4.27 Home designs

@term home-design=v1
@cites {
    identifiers#{
        tag-line=v1, inline-citation=v1, full-name=v1, slug=v1,
        target=v1,
    },
    ontology#{item-name=v1, declared-item=v1, term=v1},
    #{
        accepted-input=v1, item-file=v1, claim=v1,
        item-scope=v1, file-line=v1, innermost-item=v1,
        slug-design=v1, read-file=v1, tag-text=v1,
    },
}

The home design of a tag line of a tag text, or of an inline citation,
of a tree is the first of these that applies:

1. When the items of the kind design in whose scopes it is have an
   innermost item: that innermost item.
2. When it is in a code file, and the items of the kind requirement and
   the terms in whose claims it is have an innermost item by their
   claims, the name in the target of the declaration of that innermost
   item is a full name, and the slug of that full name has a design:
   that design.
3. When the items of the kind specification in whose scopes it is have
   an innermost item, the name in the target of the declaration of that
   innermost item is a full name, and the slug of that full name has a
   design: that design.
4. Otherwise, it has no home design.

### 4.28 Containment in a tree

@term tree-containment=v1
@cites {
    identifiers#{target=v1, full-name=v1, slug=v1, segment=v1},
    ontology#{containment=v1, item-name=v1, declared-item=v1, term=v1},
    #{
        item-file=v1, home-design=v1, item-scope=v1,
        innermost-item=v1, slug-design=v1,
    },
}

In a tree, a declared item belongs to a declared item only in these
ways:

- An item of the kind specification, an item of the kind requirement,
  or a term belongs to an item of the kind design in this way. When the
  name in the target of its declaration is a full name, it belongs to
  the design of the slug of that full name, when that slug has a
  design. When that name is a segment, it belongs to the home design of
  its declaration, when its declaration has one. Otherwise, it belongs
  to no item of the kind design.
- An item of the kind requirement or a term also belongs to the
  innermost item of the kind specification in whose scope its
  declaration is, when there is one, and when the two belong to the same
  item of the kind design or both belong to none.

### 4.29 Extents

@term extent=v1
@cites {
    ontology#{containment=v1, declared-item=v1},
    #{item-file=v1, claim=v1, file-line=v1, tree-containment=v1},
}

The extent of a declared item d of a tree is the set of these file lines
of its file:

- each line of the claim of d that is not a line of the claim of a
  declared item e, other than d, whose claim is a subset of the claim of
  d and that d does not hold;
- each line of the extent of each declared item that d holds and whose
  file is the file of d.

The lines of an extent are in the order of the file lines.

### 4.30 Section numbers

@term section-number=v1
@cites {
    rfc/5234,
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

A section number is a text that matches the production
`section-number`:

```abnf
section-number  = 1*DIGIT "." [ 1*DIGIT *( "." 1*DIGIT ) [ "." ] ] 1*WSP
```

### 4.31 Extent hashes

@term extent-hash=v1
@cites {
    data-forms#{hash=v1},
    identifiers#{
        tag-line=v1, tag-word=v1, inline-description=v1, target=v1,
        citation=v1, citation-entry=v1, citation-line=v1, label=v1,
    },
    ontology#{revised-content=v1, containment=v1, declared-item=v1},
    text#{
        text=v1, character=v1, place=v1, run=v1, space=v1, tab=v1,
        line-feed=v1, utf-8-encoding=v1, code-span=v1,
    },
    #{
        item-file=v1, extent=v1, tree-containment=v1, file-line=v1,
        origin=v1, accepted-input=v1, markdown-section=v1,
        section-number=v1, blank-line=v1, tag-text=v1,
    },
}

The hash text of a declared item d of a tree is the text that these
steps give. The steps start from the texts of the lines of the revised
content of d, in the order of the file lines: for an item of the kind
design, the lines of its extent that are not lines of the extent of a
declared item that it holds; for each other declared item, the lines of
its extent. Each step changes the texts that the steps before it leave,
and each character of these texts keeps the place that it comes from.

1. Leave out each line that is a file line of a line of a tag text of
   the file that is a tag line whose tag word is `@ack`.
2. Leave out the blank lines after the last line that is not blank.
3. When the file of d is a markdown file, change the text of each line
   of a heading that opens a section. Its heading text starts after the
   spaces before its opening sequence of `#`, that sequence, and the
   spaces and tabs after that sequence. Remove the longest run at the
   start of its heading text whose text is a section number.
4. Remove the spaces and tabs at the end of the text of each line.
5. Replace the text of the file line of the declaration of d with the
   inline description of that declaration, without the spaces and tabs
   at its end.
6. When d is of the kind specification: for each declared item that d
   holds and whose declaration has a `=` in its target, remove each
   character that comes from the place of a character of that target
   from its `=` to its end.
7. For each accepted input whose file is the file of d and that is a
   citation, and for each of its citation entries whose run in the text
   of the citation has a `=`: remove each character that comes from the
   place of that `=`, or from the place of a character of that run after
   that `=`, up to the end of that run or, when the citation entry is an
   every-part target, up to the `#` after that `=`, which stays.
8. Join the texts of the lines that remain, in their order, each
   followed by one line feed.

The extent hash of d is the hash of the UTF-8 encoding of its hash text.
The extent hash is the measure of revised content: two revised contents
of the same declared item are the same when, and only when, their extent
hashes are equal.

### 4.32 Code hashes

@term code-hash=v1
@cites {
    data-forms#{hash=v1},
    packs#{
        definition-node=v1, test-node=v1, node-run=v1, comment-node=v1,
    },
    text#{
        text=v1, run=v1, boundary=v1, space=v1, tab=v1, line-feed=v1,
        utf-8-encoding=v1, algorithm=v1, sequence=v1,
    },
    #{run-line=v1, attachment=v1, comment-run=v1},
}

The code text of an attachment target *a* is the text that these steps
give.

1. Let *r* be the run of *a*.
2. If *a* is a definition node, set *r* to the run of the text of the
   file of *a* from the least boundary where the run of a body node of
   *a* starts to the greatest boundary where the run of a body node of
   *a* ends.
3. Let *c* be the empty text.
4. For each *x* of the lines of the run *r*, in order:
   1. Let *t* be the text of *x* without the spaces and tabs at its end.
   2. Append *t* to *c*.
   3. Append a line feed to *c*.
5. Give *c*.

A run of comments that has a tagged comment node and that attaches to
an attachment target has a code hash: the hash of the UTF-8 encoding of
the code text of that attachment target. Each other run of comments has
no code hash.

### 4.33 Sets of names

@term name-set=v1
@cites {
    identifiers#{slug=v1},
    ontology#{
        item-name=v1, declared-item=v1, term=v1, decision-record=v1,
        declared-finding-class=v1,
    },
    #{item-file=v1, tree-containment=v1},
}

The sets of names of a tree are these:

- the shared set, which has each item of the kind design of the
  tree, each decision record of the tree, and each item of the kind
  specification, each item of the kind requirement, and each term of the
  tree that belongs to no item of the kind design and whose name is a
  slug;
- the set of its declared finding classes;
- for each of its items of the kind design, the set of that item: the
  items of the kind specification, the items of the kind requirement,
  and the terms that belong to it.

### 4.34 What kind words state

@term stated-kind=v1
@cites {
    identifiers#{kind-word=v1},
    ontology#{
        declared-item=v1, term=v1, decision-record=v1,
        declared-finding-class=v1, external-item=v1,
        conformance-vector=v1, conformance-vector-group=v1,
        vector-set=v1,
    },
}

A kind word states these kinds of item: `design`, an item of the kind
design; `spec`, an item of the kind specification or an external item;
`req`, an item of the kind requirement; `term`, a term or an external
item; `decision`, a decision record; and `finding-class`, a declared
finding class. No kind word states a conformance vector, a group of
conformance vectors, or a vector set.

### 4.35 What names name

@term named-item=v1
@cites {
    identifiers#{
        citation-entry=v1, inline-citation=v1, inline-destination=v1,
        destination=v1, name=v1, slug=v1, full-name=v1, part-name=v1,
        kind-word=v1, external-id=v1, external-target=v1, match=v1,
    },
    ontology#{external-item=v1, item-name=v1, declared-finding-class=v1},
    text#{text=v1},
    #{accepted-input=v1, name-set=v1, home-design=v1, slug-design=v1},
}

In a tree, the entry name of a citation entry of an accepted citation,
and the text that `name` or `external-ref` matches in the match of the
destination of an accepted inline citation, each name one item or
nothing, by the first of these rules that applies:

1. When the match of the citation entry, or of the destination, uses
   `external-ref`: the text is an external id, with its `#` and part
   name when it has them, and it names the external item that this
   external id names.
2. A slug, when the citation entry, or the target of the inline
   citation, starts with the kind word `finding-class`, names the
   declared finding class whose name is that slug. Each other slug names
   the item of the shared set whose name is that slug.
3. A full name names the item of the set of the design of its slug
   whose name is that full name. When its slug has no design, it names
   nothing.
4. `#` and a part name p name the item, in the set of the home design of
   the citation or of the inline citation, whose name is the name of
   that home design, `#`, and p. With no home design, they name nothing.

A name that two or more items of the set in which a rule looks for it
have names none of them, and a name that no item of that set has names
nothing. Two names are the same name only when they are the same text.

### 4.36 Vector files

@term vector-file=v1
@cites {
    files#{path=v1},
    data-forms#{test-vector-file-name=v1, test-vector-set=v1},
    ontology#{item-name=v1, vector-set=v1, declared-item=v1},
    text#{text=v1},
    #{item-file=v1, tree-containment=v1},
}

The vector path of an item of the kind design D of a tree is the text of
the valid path of the file of D up to its last `/`, that `/` included,
or the empty text when that valid path has no `/`, followed by the
test-vector file name of the name of D alone. The vector path of an item
of the kind specification that belongs to an item of the kind design D
is that same text for D, followed by the test-vector file name of the
name of D and the part name of the name of the specification. An item
of the kind specification that belongs to no item of the kind design
has no vector path. The vector file of an item is the file of the tree
whose valid path is its vector path, when the tree has that file and
that valid path is the vector path of no other item. The vector set of
an item, in that tree, is the content of its vector file, when it has a
vector file and that content is a test-vector set.

### 4.37 Selected items

@term selected-item=v1
@cites {
    identifiers#{citation-entry=v1, vector-selection=v1, match=v1},
    data-forms#{vector-line=v1},
    ontology#{
        conformance-vector=v1, conformance-vector-group=v1,
        vector-set=v1,
    },
    text#{decimal-numeral=v1, whole-number=v1, code-span=v1},
    #{accepted-input=v1, named-item=v1, vector-file=v1},
}

In a tree, a citation entry of an accepted citation whose match uses
`vector-selection` names one item, or nothing. When its entry name names
an item of the kind specification or of the kind design that has a
vector set, the citation entry names this item of that vector set, or
nothing when the vector set has none:

- when the match uses `vector-number`: the conformance vector whose
  vector line is the vector line of that vector set with the number n,
  where n is the whole number that the text that `vector-number` matches
  writes as a decimal numeral;
- when the match uses `group-name`: the group of conformance vectors
  whose name is the text that `group-name` matches;
- otherwise: the vector set.

Otherwise, the citation entry names nothing.

### 4.38 The edges of a tree

@term tree-edge=v1
@cites {
    identifiers#{
        citation=v1, citation-entry=v1, inline-citation=v1,
        inline-destination=v1, vector-selection=v1, match=v1,
    },
    ontology#{edge=v1, edge-source=v1, tree=v1},
    #{accepted-input=v1, named-item=v1, selected-item=v1},
}

The edges of a tree are the edges that the accepted inputs of the tree
that are citations or inline citations give. The file of such an edge
is the file of the accepted input that gives it. The cited item of such
an edge is the item that these rules give, or none when they give
nothing:

- for a citation entry whose match uses `vector-selection`, the item
  that the citation entry names as a selected item;
- for each other citation entry, the item that its entry name names;
- for an inline citation, the item that the text that `name` or
  `external-ref` matches in the match of its destination names.

### 4.39 Parts of declared items

@term item-part=v1
@cites {
    ontology#{edge-source=v1, declared-item=v1, test=v1, tree=v1},
    #{
        extent=v1, file-line=v1, file-test=v1, comment-run=v1,
        tag-text=v1, markdown-line=v1,
    },
}

In a tree, a markdown line, a line of a tag text, the text of a tag line
with its continuation lines, or an inline citation is a part of a
declared item d when, and only when, it is in the extent of d. A comment
on a test has such a thing when, and only when, each file line of the
thing is a line that the tag text of that comment joins. A line of a tag
text stands in an item, or in none, by the same rule as a line of a file
of a tree.

### 4.40 Sites

@term tree-site=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1, directive=v1},
    packs#{comment-node=v1, node-run=v1},
    ontology#{site=v1, test=v1},
    text#{text=v1, line=v1, place=v1, run=v1},
    #{
        read-file=v1, tag-text=v1, front-matter=v1, markdown-section=v1,
        comment-run=v1, file-test=v1, file-line=v1, extent=v1,
        origin=v1, markdown-line=v1,
    },
}

In this term, a line of an extent is a line of the extent of a declared
item of the tree, and a thing is outside every extent when it is
outside the extent of each declared item of the tree. The sites of a
read file of a tree are these sets of file lines of the file:

- In a markdown file: take each citation and each `@ack` line of a tag
  text of the file, and each inline citation of the markdown document of
  its markdown text, that is outside every extent. For each of them, X,
  the site lines of X are the markdown lines that are not lines of an
  extent and that are from a first line to a last line. The first line
  is the line of the last heading that opens a section and whose line is
  the first file line of X or comes before it, or the first markdown
  line of the markdown text when no such heading is. The last line is
  the markdown line right before the line of the next heading that opens
  a section, or the last markdown line of the markdown text when no such
  heading is. Two such sets of site lines are linked when a line of the
  text of the file has a place of a markdown line of each of them. For
  each largest group of such sets of site lines in which each two are
  linked, directly or through others of the group, the set of the
  markdown lines of its sets is a site.
- In a code file: take each run of comments that is not a comment on a
  test and whose tag text has a citation, an `@ack` line, or an inline
  citation of the markdown document of that tag text that is outside
  every extent. The site lines of such a run of comments are the lines
  that its tag text joins and that are not lines of an extent. Two such
  runs of comments are linked when a line of the text of the file has
  a place of the run of a comment node of each of them. For each largest
  group of such runs of comments in which each two are linked, directly
  or through others of the group, the set of the site lines of its runs
  of comments is a site.

A site has a markdown line, a line of a tag text, a citation, an `@ack`
line, or an inline citation when, and only when, it is in that site.

### 4.41 Extern marks

@term extern-mark=v1
@cites {
    identifiers#{
        extern-line=v1, directive=v1, kind-word=v1, part-name=v1,
    },
    ontology#{edge-source=v1, declared-item=v1},
    #{
        accepted-input=v1, item-part=v1, tree-site=v1, file-test=v1,
        tag-text=v1,
    },
}

An `@extern` line that is a line of a tag text, that is an accepted
input of a tree, and that stands in an item of the kind design D, states
one extern mark of D. The kind word and the part name of the extern mark
are the texts that `kind-word` and `part-name` match in the match of
that line by `extern-line`. An `@extern` line that stands in no item of
the kind design states no extern mark.

### 4.42 Valid extern marks

@term valid-extern-mark=v1
@cites {
    identifiers#{kind-word=v1, part-name=v1},
    ontology#{containment=v1, item-name=v1, term=v1, declared-item=v1},
    text#{code-span=v1},
    #{extern-mark=v1, item-file=v1, tree-containment=v1},
}

An extern mark of an item of the kind design D is valid when, and only
when, one of these is true, where the name of the extern mark is the
name of D, `#`, and the part name of the extern mark:

- its kind word is `spec`, and D holds an item of the kind specification
  whose name is the name of the extern mark and whose file is not the
  file of D;
- its kind word is `req`, and D holds directly an item of the kind
  requirement whose name is the name of the extern mark and whose file
  is not the file of D;
- its kind word is `term`, and D holds directly a term whose name is the
  name of the extern mark and whose file is not the file of D.

### 4.43 Position subjects

@term position-subject=v1
@cites {
    files#{path=v1},
    text#{text=v1, position=v1, decimal-numeral=v1, code-span=v1},
    #{read-file=v1},
}

The position subject of a position, with the line number l and the
column c, in a read file is the text of the valid path of the file,
then `@L`, then the decimal numeral of l, then `C`, then the decimal
numeral of c.

### 4.44 The order of positions

@term position-order=v1
@cites text#{position=v1, line-number=v1, whole-number=v1}

One position comes before another position when, and only when, its
line number is less than the line number of the other, or the two line
numbers are the same and its column is less than the column of the
other.

### 4.45 The spots of runs

@term run-spot=v1
@cites {
    findings#{spot=v1},
    files#{path=v1},
    text#{run=v1, boundary=v1, span=v1, body=v1},
    #{read-file=v1},
}

For a run r of the text of a read file that starts and ends at
boundaries of the body, the spot of r is the spot with the valid path of
the file and the span r.

### 4.46 Tree findings

@term tree-finding=v1
@cites {
    findings#{
        finding-subject=v1, spot=v1, finding-part=v1,
        ackable-finding=v1, message=v1, mark=v1, related-message=v1,
        fix=v1,
    },
    ontology#{finding-class=v1, tree=v1},
    identifiers#{slug=v1},
}

A tree finding of a tree, of the class that a slug c names, with a
subject s and a spot p, is a finding whose tree is that tree, whose
finding class is the class that c names, whose subject is s, whose spot
is p, and that is not ackable. Its message, its mark, its related
messages, and its fix are those that the program that gives it gives.

### 4.47 Edit distance

@term edit-distance=v1
@cites text#{text=v1, character=v1, whole-number=v1}

An edit of a text inserts one character into it, removes one character
from it, replaces one of its characters with another character, or
swaps two of its characters that are next to each other. The edit
distance of two texts a and b is the least whole number n such that a
sequence of n edits changes a into b, where each edit of the sequence
changes the text that the edits before it give. So an edit can change a
character that an earlier edit inserted or moved. The edit distance of
`ca` and `abc` is 2.

### 4.48 Findings of the class `parse-error`

@term parse-error-finding=v1
@cites {
    files#{path=v1},
    #{read-file=v1, unreadable-file=v1, tree-finding=v1},
}

A tree has one tree finding of the class `parse-error` for each read
file of the tree that cannot be read. Its subject is the valid path of
the file, and its spot is the valid path of the file alone, with no
span.

### 4.49 Findings of the class `typo-tag`

@term typo-tag-finding=v1
@cites {
    identifiers#{
        tag-line=v1, tag-word=v1, sinter-tag-word=v1, tag-line-text=v1,
    },
    packs#{foreign-tag-word=v1, valid-pack=v1},
    #{
        read-file=v1, tag-text=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
        edit-distance=v1,
    },
}

A tree has one tree finding of the class `typo-tag` for each line of a
tag text of a read file of the tree that is a tag line and whose tag
word meets each of these conditions: it is not a Sinter tag word; it is
not a foreign tag word of the descriptor of the pack of the file, when
the file is a code file; and its edit distance from at least one Sinter
tag word is 1 or 2. Its subject is the position subject of the origin
position of the text of that tag line. Its spot is the spot of the run
of the text of that tag line in the text of the file.

### 4.50 Findings of the class `ignored-tag`

@term ignored-tag-finding=v1
@cites {
    commonmark/0.31.2,
    identifiers#{
        tag-line=v1, tag-word=v1, sinter-tag-word=v1, declaration=v1,
        inline-description=v1, link=v1,
    },
    text#{
        text=v1, run=v1, character=v1, space=v1, tab=v1, boundary=v1,
        place=v1, code-span=v1,
    },
    #{
        read-file=v1, unreadable-file=v1, markdown-section=v1,
        markdown-list-item=v1, paragraph-line=v1, origin=v1,
        origin-position=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1, edit-distance=v1, markdown-line=v1,
        tag-text=v1, front-matter=v1,
    },
}

The content lines of a setext heading are runs of the text of the file:
for each markdown line that the heading takes, other than the last one,
the run of that markdown line from the first character, among the
characters of that markdown line that CommonMark 0.31.2 gives to the
content of the heading, that is not a space or a tab, to the end of that
markdown line.

A tree has one tree finding of the class `ignored-tag` for each line L
of each block B of the markdown document of a markdown file of the tree
that can be read, when each of these is true:

- B is a paragraph and L is one of the lines of that paragraph, or B is
  a setext heading and L is one of its content lines;
- no block quote contains B;
- B is a block of the document itself, or a block that a list item
  contains and that no block quote, no list, and no list item inside
  that list item contains;
- when B is a paragraph, it is not the first paragraph of a section or
  of a list item;
- L is a tag line, and its tag word is a Sinter tag word or has an edit
  distance of 1 or 2 from a Sinter tag word.

Let A be the run of the text of the file that starts at the boundary
right before the first `@` of L and ends where L ends. Its subject is
the position subject of the origin position of A. Its spot is the spot
of A.

A tag word of an inline description is the text of a run of the inline
description that starts at the boundary where the inline description
starts, or right after a space or a tab, and that is the longest run
that starts there and whose text matches `tag-word`. A tree also has one
tree finding of the class `ignored-tag` for each line M of a tag text of
a read file of the tree that can be read, when M is a declaration and a
tag word of the inline description of M is a Sinter tag word whose `@`
comes from a place from which no character of a code span of CommonMark
0.31.2 comes. For a markdown file, these are the code spans of the
markdown document of its markdown text; for a code file, the code spans
of the markdown document of the tag text. Let B be the run, in the text
of the file, of the run of M from the `@` of the first such tag word to
the end of M, as the term `origin` gives runs in the text of the file.
Its subject is the position subject of the origin position of B. Its
spot is the spot of B.

### 4.51 Findings of the class `invalid-target`

@term invalid-target-finding=v1
@cites {
    identifiers#{
        tag-line=v1, link=v1, citation=v1, citation-entry=v1,
        inline-citation=v1, inline-destination=v1, part-name=v1,
        match=v1, tag-line-text=v1,
    },
    text#{result=v1, code-span=v1},
    #{
        accepted-input=v1, origin=v1, origin-position=v1,
        home-design=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1,
    },
}

A tree has one tree finding of the class `invalid-target` for each of
these things X:

- each input of the tree that is a tag line, with its continuation lines,
  and whose result is "invalid";
- each input of the tree that is a link and whose result is "invalid";
- each citation entry of an accepted input that is a citation, whose
  entry name is `#` and a part name, when that citation has no home
  design;
- each accepted input that is an inline citation, when the text that
  `name` matches in the match of its destination is `#` and a part name,
  and the inline citation has no home design.

Let Y be the text of the tag line when X is a tag line, and X itself
otherwise: the link, the citation entry, or the inline citation. Its
subject is the position subject of the origin position of Y. Its spot is
the spot of the run of Y in the text of the file.

### 4.52 Findings of the class `duplicate`

@term duplicate-finding=v1
@cites {
    files#{path=v1},
    identifiers#{tag-line-text=v1},
    text#{code-point-order=v1, position=v1, character=v1},
    #{
        item-file=v1, name-set=v1, origin=v1, origin-position=v1,
        vector-file=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1, position-order=v1,
    },
}

Two names are the same name after case folding when they are the same
text after each ASCII upper-case letter, from `A` to `Z`, is changed to
the same letter in lower case. A tree has these tree findings of the
class `duplicate`:

- For each set of names of the tree, and each largest group of two or
  more of its declared items whose names are the same name after case
  folding: order the declared items of the group by the valid paths of
  their files, in code point order, and then by the origin positions of
  the texts of their declarations, in the order of positions. Each
  declared item after the first gives one tree finding. Its subject is
  the position subject of the origin position of the text of its
  declaration. Its spot is the spot of the run of the text of its
  declaration in the text of its file.
- For each file of the tree whose valid path is the vector path of two
  or more items: one tree finding, whose subject is the valid path of
  that file and whose spot is that valid path alone, with no span.

### 4.53 Findings of the class `dangling`

@term dangling-finding=v1
@cites {
    identifiers#{citation-entry=v1, inline-citation=v1, part-name=v1},
    ontology#{edge=v1},
    #{
        tree-edge=v1, home-design=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

A tree has one tree finding of the class `dangling` for each edge of the
tree that has no cited item, other than an edge whose citation entry has
an entry name that is `#` and a part name, when its citation has no home
design, and other than an edge whose inline citation has a destination
in whose match `name` matches `#` and a part name, when that inline
citation has no home design. Its subject is the position subject of the
origin position of the citation entry or of the inline citation of the
edge. Its spot is the spot of the run of that citation entry or inline
citation in the text of the file.

### 4.54 Findings of the class `wrong-source`

@term wrong-source-finding=v1
@cites {
    identifiers#{citation-entry=v1},
    ontology#{
        edge=v1, edge-source=v1, cites-edge=v1, satisfies-edge=v1,
        verifies-edge=v1, refines-edge=v1, supersedes-edge=v1,
    },
    #{
        tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

A tree has one tree finding of the class `wrong-source` for each edge of
the tree that has no source, or whose source is not of a kind of item
that its kind of edge is for as its source. Its subject is the position
subject of the origin position of the citation entry or of the inline
citation of the edge. Its spot is the spot of the run of that citation
entry or inline citation in the text of the file.

### 4.55 Findings of the class `wrong-kind`

@term wrong-kind-finding=v1
@cites {
    identifiers#{
        citation-line=v1, citation-entry=v1, inline-citation=v1,
        external-target=v1, kind-word=v1,
    },
    ontology#{
        edge=v1, edge-source=v1, declared-item=v1, cites-edge=v1,
        satisfies-edge=v1, verifies-edge=v1, refines-edge=v1,
        supersedes-edge=v1,
    },
    #{
        tree-edge=v1, stated-kind=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

A tree has one tree finding of the class `wrong-kind` for each edge of
the tree that has a cited item, when that cited item is not of a kind of
item that its kind of edge is for as its cited item, or when the
citation entry, or the target of the inline citation, of the edge starts
with a kind word that does not state the kind of item of that cited
item. For an edge of the kind `supersedes` that has no source, or whose
source is not a declared item, the first condition is instead: its cited
item is not of the kind design when the production `every-part` matches
its citation entry, and is not a declared item otherwise.
Its subject is the position subject of the origin position of the
citation entry or of the inline citation of the edge. Its spot is the
spot of the run of that citation entry or inline citation in the text
of the file.

### 4.56 Findings of the class `misplaced-declaration`

@term misplaced-declaration-finding=v1
@cites {
    identifiers#{
        declaration=v1, extern-line=v1, target=v1, full-name=v1,
        tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, term=v1, declared-finding-class=v1,
        containment=v1, edge-source=v1,
    },
    #{
        read-file=v1, accepted-input=v1, item-file=v1, tag-text=v1,
        markdown-section=v1, item-scope=v1,
        tree-containment=v1, item-part=v1, tree-site=v1, origin=v1,
        origin-position=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1, innermost-item=v1,
    },
}

A tree has one tree finding of the class `misplaced-declaration` for
each declaration of a declared item d of the tree that meets one or more
of these conditions, and for each `@extern` line that meets the last of
them:

- d is of the kind design, and its file is a code file;
- d is of the kind design, and its declaration is in the scope of
  another item of the kind design;
- d is of the kind specification, requirement, or term; the innermost
  item of the kind design in whose scope its declaration is, is an item
  D; and d belongs to an item of the kind design other than D;
- d is of the kind requirement or term; its declaration is in the scope
  of an item of the kind specification S that is the innermost item of
  the kind specification in whose scope that declaration is; and d
  belongs to an item of the kind design to which S does not belong;
- d is of the kind specification, and its declaration is in the scope of
  another item of the kind specification;
- d is of the kind specification or term, and it belongs to no item of
  the kind design;
- d is of the kind requirement or term, it belongs to an item of the
  kind design D, the name in the target of its declaration is a full
  name, its file is a markdown file, and its file is not the file of D
  and not the file of the item of the kind specification to which d
  belongs, when d belongs to one;
- d is a declared finding class, and its file is a code file, or its
  declaration is not the only declaration of a declared item in the tag
  text of the first paragraph of the section of level 0 of its file;
- the line is an `@extern` line that is a line of a tag text, that is an
  accepted input, and that stands in no item of the kind design.

Its subject is the position subject of the origin position of the text
of the declaration or of the `@extern` line. Its spot is the spot of the
run of that text in the text of the file.

### 4.57 Findings of the class `req-outside-design`

@term req-outside-design-finding=v1
@cites {
    identifiers#{tag-line-text=v1},
    ontology#{declared-item=v1, containment=v1},
    #{
        item-file=v1, tree-containment=v1, origin=v1,
        origin-position=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1,
    },
}

A tree has one tree finding of the class `req-outside-design` for each
item of the kind requirement of the tree that belongs to no item of the
kind design. Its subject is the position subject of the origin position
of the text of its declaration. Its spot is the spot of the run of that
text in the text of its file.

### 4.58 Findings of the class `extern-mismatch`

@term extern-mismatch-finding=v1
@cites {
    identifiers#{tag-line-text=v1, kind-word=v1, part-name=v1},
    ontology#{containment=v1, item-name=v1, term=v1, declared-item=v1},
    #{
        item-file=v1, tree-containment=v1, extern-mark=v1,
        valid-extern-mark=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

A tree has these tree findings of the class `extern-mismatch`:

- one for each extern mark of the tree that is not valid, whose subject
  is the position subject of the origin position of the text of its
  `@extern` line, and whose spot is the spot of the run of that text in
  the text of its file;
- one for each item of the kind specification that an item of the kind
  design D holds, and for each item of the kind requirement and each
  term that D holds directly, whose file is not the file of D and for
  which D has no extern mark whose part name is the part name of its
  name and
  whose kind word is `spec` for an item of the kind specification, `req`
  for an item of the kind requirement, and `term` for a term.
  Its subject is the position subject of the origin position of the
  text of its declaration, and its spot is the spot of the run of that
  text in the text of its file.

### 4.59 Conformance parts

@term conformance-part=v1
@cites {
    ontology#{declared-item=v1, containment=v1},
    #{
        read-file=v1, item-file=v1, tag-text=v1, markdown-line=v1,
        markdown-section=v1, markdown-list-item=v1, tree-containment=v1,
    },
}

The Conformance part of an item x of the kind design or of the kind
specification of a tree is a set of markdown lines of its file, or none.
When the file of x is a markdown file, let S be the section or the list
item whose first paragraph gives the tag text that has the declaration
of x. When S is the section of a heading H that opens a section, and
the lines of S have the line of at least one heading that opens a
section and whose level is the level of H plus 1, let C be the last of
these headings. Then the
Conformance part of x is the markdown lines of the section of C, unless
x is of the kind design and the tag text of the first paragraph of the
section of C has the declaration of an item of the kind specification
that belongs to x; then x has none. In each other case, x has none.

## 5. Requirements

### 5.1 Nothing under bindings that are not valid

@req give-nothing-under-invalid-bindings=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1, status-tag=v1},
    ontology#{
        tree=v1, declared-item=v1, containment=v1, test=v1, site=v1,
        edge=v1, finding-class=v1,
    },
    text#{conforming-program=v1, result=v1},
    #{
        file-reader-binding=v1, read-file=v1, item-file=v1, extent=v1,
        extent-hash=v1, code-hash=v1, tree-containment=v1, file-test=v1,
        tree-site=v1, tree-edge=v1, accepted-input=v1, extern-mark=v1,
        vector-file=v1, parse-error-finding=v1, typo-tag-finding=v1,
        ignored-tag-finding=v1, invalid-target-finding=v1,
        duplicate-finding=v1, dangling-finding=v1,
        wrong-source-finding=v1, wrong-kind-finding=v1,
        misplaced-declaration-finding=v1, req-outside-design-finding=v1,
        extern-mismatch-finding=v1,
    },
}

Under a binding of `file-readers` that is not valid, or under a binding
of `external-namespaces` for which a conforming program of the design
Identifiers gives the result "invalid", a conforming program must give,
for any tree, no read file, no declared item, no extent, no hash text,
no extent hash, no code text, no code hash, no item to which a declared item belongs, no test, no
site, no edge, no status tag, no extern mark, no vector file, and no
finding of the classes `parse-error`, `typo-tag`, `ignored-tag`,
`invalid-target`, `duplicate`, `dangling`, `wrong-source`, `wrong-kind`,
`misplaced-declaration`, `req-outside-design`, and `extern-mismatch`.

### 5.2 Read files

@req give-read-files=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{tree=v1},
    text#{conforming-program=v1, result=v1},
    #{read-file=v1, file-reader-binding=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the read files of a tree under these bindings, it must give each read
file of the tree once, with its reader, and no other read file.

### 5.3 Declared items

@req give-declared-items=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1, tag-line-text=v1},
    ontology#{declared-item=v1, item-name=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{
        file-reader-binding=v1, item-file=v1, tree-containment=v1,
        origin-position=v1,
    },
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the declared items of a tree under these bindings, it must give each
declared item of the tree once, with its kind of item, its name, its
file, and the origin position of the text of its declaration, and no
other declared item.

### 5.4 Extents

@req give-extents=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{declared-item=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{file-reader-binding=v1, extent=v1, file-line=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the extent of a declared item of a tree under these bindings, it must
give the extent of that item, and nothing else as that extent.

### 5.5 Extent hashes

@req give-extent-hashes=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{declared-item=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{file-reader-binding=v1, extent-hash=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the extent hash of a declared item of a tree under these bindings, it
must give the extent hash of that item, and nothing else as that extent
hash.

### 5.6 Code hashes

@req give-code-hashes=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{tree=v1},
    text#{conforming-program=v1, result=v1, boundary=v1},
    #{file-reader-binding=v1, code-hash=v1, comment-run=v1, read-file=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the code hashes of a tree under these bindings, it must give each run of
comments of a code file of the tree that has a code hash once, with its
file, the boundaries where that run of comments starts and ends, and its
code hash, and no other run of comments with a code hash.

### 5.7 Containment

@req give-containment=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{declared-item=v1, containment=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{file-reader-binding=v1, tree-containment=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the item of the kind design, or the item of the kind specification, to
which a declared item of a tree belongs under these bindings, it must
give the item of that kind to which the declared item belongs, or that
it belongs to no item of that kind when it belongs to none, and nothing
else as that item.

### 5.8 Tests

@req give-tests=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{test=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{file-reader-binding=v1, file-test=v1, read-file=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the tests of a tree under these bindings, it must give each test of each
read file of the tree once, with its file, its name, its code, and each
comment on it, and no other test and no other comment on a test.

### 5.9 Sites

@req give-sites=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{site=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{file-reader-binding=v1, tree-site=v1, read-file=v1, file-line=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the sites of a tree under these bindings, it must give each site of each
read file of the tree once, with its file and its file lines, and no
other site.

### 5.10 Edges

@req give-edges=v1
@cites {
    identifiers#{
        binding=v1, accept-inputs=v1, citation-entry=v1,
        inline-citation=v1,
    },
    ontology#{edge=v1, edge-source=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{
        file-reader-binding=v1, accepted-input=v1, tree-edge=v1,
        named-item=v1, selected-item=v1, item-part=v1, tree-site=v1,
        file-test=v1, origin-position=v1,
    },
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the edges of a tree under these bindings, it must give each edge of the
tree once, with its file, the origin position of its citation entry or
inline citation, its kind of edge, its source or that it has none, and
its cited item or that it has none, and no other edge.

### 5.11 The items in which status tags stand

@req give-status-tag-items=v1
@cites {
    identifiers#{
        binding=v1, accept-inputs=v1, status-tag=v1, tag-line-text=v1,
    },
    ontology#{edge-source=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{
        file-reader-binding=v1, accepted-input=v1, item-part=v1,
        tree-site=v1, file-test=v1, origin-position=v1,
    },
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the items in which the status tags of a tree stand under these bindings,
it must give each status tag that is an accepted input of the tree once,
with its file, the origin position of its text, and the item in which it
stands or that it stands in no item, and no other status tag.

### 5.12 Extern marks

@req give-extern-marks=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1, tag-line-text=v1},
    ontology#{tree=v1},
    text#{conforming-program=v1, result=v1},
    #{
        file-reader-binding=v1, accepted-input=v1, extern-mark=v1,
        valid-extern-mark=v1, origin-position=v1,
    },
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the extern marks of a tree under these bindings, it must give each
extern mark of the tree once, with the file and the origin position of
the text of its `@extern` line, its item of the kind design, and whether
it is valid, and no other extern mark.

### 5.13 Vector files

@req give-vector-files=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{declared-item=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{file-reader-binding=v1, vector-file=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the vector file of an item of the kind design or of the kind
specification of a tree under these bindings, it must give the vector
file of that item, or that it has none when it has none, and nothing
else as that vector file.

### 5.14 The findings of a tree

@req give-tree-findings=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{finding-class=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{
        file-reader-binding=v1, tree-finding=v1, parse-error-finding=v1,
        typo-tag-finding=v1, ignored-tag-finding=v1,
        invalid-target-finding=v1, duplicate-finding=v1,
        dangling-finding=v1, wrong-source-finding=v1,
        wrong-kind-finding=v1, misplaced-declaration-finding=v1,
        req-outside-design-finding=v1, extern-mismatch-finding=v1,
    },
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the findings of a tree of one of the classes `parse-error`, `typo-tag`,
`ignored-tag`, `invalid-target`, `duplicate`, `dangling`,
`wrong-source`, `wrong-kind`, `misplaced-declaration`,
`req-outside-design`, and `extern-mismatch` under these bindings, it
must give each tree finding of that class that the tree has once, and no
other finding of that class.

### 5.15 Hash texts

@req give-hash-texts=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{declared-item=v1, tree=v1},
    text#{conforming-program=v1, result=v1},
    #{file-reader-binding=v1, extent-hash=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the hash text of a declared item of a tree under these bindings, it must
give the hash text of that item, and nothing else as that hash text.

### 5.16 Code texts

@req give-code-texts=v1
@cites {
    identifiers#{binding=v1, accept-inputs=v1},
    ontology#{tree=v1},
    text#{conforming-program=v1, result=v1},
    #{
        file-reader-binding=v1, code-hash=v1, comment-run=v1,
        attachment=v1, read-file=v1,
    },
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the code text of the attachment target to which a run of comments of a
code file of the tree that has a code hash attaches, under these
bindings, it must give the code text of that attachment target, and
nothing else as that code text.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

The vectors of this design are in the file
[`documents.test-vectors.jsonl`](documents.test-vectors.jsonl), in the
same folder as this design. The file is a
[test-vector set](sinter:data-forms#test-vector-set=v1). A vector is an
input and what a conforming program gives for it. Each vector follows
from the requirements and adds nothing to them.

Several requirements apply only when a program gives the thing that they
name, such as the extent of a declared item. So a vector checks a
program only on what the program gives for the input: a program that
gives the declared items of a tree, and not their extents, is checked
only on the declared items.

The file is a sequence of the
[canonical byte sequences](sinter:data-forms#canonical-byte-sequence=v1)
of JSON objects, each followed by the byte 0x0A. So each line of the
text of the file is a JSON text, as RFC 8259 defines it. The file is
valid UTF-8, its text has no byte order mark and no carriage return, and
only a line feed ends a line of the file. U+0085, U+2028, and U+2029 can
be in JSON strings of the file, and they do not end a line. No JSON
value of the file is the literal name `null`. The file has three kinds
of line, in this order:

1. The first line is the set line. Its JSON object has one member,
   `rev`: the revision of the whole set of vectors.
2. Then each group has a group line, in this order: `code`, `markdown`.
   Its JSON object has two members: `group`, the name of the group, as a
   JSON string, and `rev`, the revision of the group.
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
- `values`: a JSON object that states what a conforming program gives
  for the input. Each vector has this member.
- `note`: an explanation of the vector, as a JSON string, which a
  conforming program does not give. A vector has this member only when
  it has an explanation.

No vector has the member `result` or the member `needs`.

A revision is a JSON string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. The revision of the set line is the
revision of the whole set, the revision of a group line is the revision
of the group, and the revision of a vector line is the revision of the
vector. A revision rises, to a greater number after its `v`, when the
vectors that it covers change, join, or leave. When the text of this
section or of its subsections changes, other than their headings and the
vector lines that they show, the revisions of every vector, every group,
and the set rise. A change of a note alone changes no revision. A
program does not need the revisions to run the vectors.

Inside the members `input` and `values`, each JSON value that this
section or its subsections name as a text, a whole number, a run, a
position, a path set, a binding of `external-namespaces`, or a tree has
this form:

- A text, such as a valid path, a name, a subject, or a hash, is a JSON
  string whose characters are the characters of the text, in order. So
  the text `a`, a line feed, `b` is `"a\nb"`.
- A whole number, such as a boundary or an index, is a JSON number
  written as its decimal numeral, such as `12`.
- A run of the text of a file is a JSON object with two members: `from`,
  the boundary where the run starts, and `to`, the boundary where the
  run ends, such as `{"from":1,"to":4}`. The boundaries are those of the
  text of the file, so a byte order mark at place 1 is before boundary
  1.
- A position is a JSON object with two members: `line`, its line number,
  and `column`, its column, such as `{"column":7,"line":3}`.
- A path set is a JSON array of its path set members, each a text, in
  their order.
- A binding of `external-namespaces` is a JSON array with one element for
  each pair of the binding, in no meaningful order. Each element is a
  JSON object with two members: `namespace-name`, the namespace name of
  the pair, and `id-pattern`, the id pattern of the pair.
- A tree is a JSON object with one member for each file of the tree. The
  key is the valid path of the file. When the content of the file is
  valid UTF-8, the value is the text of that content. When it is not,
  the value is a JSON object with one member, `bytes`: the
  [hex text](sinter:data-forms#hex-text=v1) of the content, as a JSON
  string, which has two lower-case hex digits for each byte, in the
  order of the bytes.

The member `values` of a vector is the empty JSON object, `{}`, when the
binding of `file-readers` of the input is not valid, or a conforming
program of the design Identifiers gives the result "invalid" for its
binding of `external-namespaces`. Otherwise, it
is a JSON object with the members of the list below, and an empty JSON
array in one of them says that the tree has none of these things. In
each JSON array, the elements stand in the order that the list gives,
and the index of an element, as Data forms defines the
[index](sinter:data-forms#index=v1), refers to it from other members. So
the first element of an array has the index 1. A file is given by its
valid path. Where this section orders elements by positions, it uses
the [order of positions](sinter:#position-order=v1).
A member that the list gives only for some elements, such as `design` or
`source`, is not in an element for which the list does not give it: the
element of a thing that has no such item has no such member.

- `read-files`: a JSON object with one member for each read file of the
  tree. Its key is the valid path of the file. Its value is the index,
  in the member `file-readers` of the input, of the first pair whose path
  set has that valid path in its set: the pair whose reader is the
  reader of the file.
- `items`: a JSON array with one element for each declared item of the
  tree, in the code point order of the valid paths of their files and
  then in the order of the origin positions of their declarations. Each
  element is a JSON object with these members: `kind`, the kind of item,
  one of the texts `design`, `specification`, `requirement`, `term`,
  `decision record`, and `declared finding class`; `name`, its name;
  `file`, its file; `at`, the origin position of the text of its
  declaration; `extent`, a JSON array of the file lines of its extent,
  each a run, in their order; `hash-text`, its hash text; `extent-hash`,
  its extent hash; `design`,
  the index of the item of the kind design to which it belongs, only
  when it belongs to one; `specification`, the index of the item of the
  kind specification to which it belongs, only when it belongs to one;
  and `vector-file`, its vector file, only for an item of the kind
  design or specification that has a vector file.
- `sites`: a JSON array with one element for each site of each read file
  of the tree, in the code point order of the valid paths of their files
  and then in the order of the boundaries where their first file lines
  start. Each element is a JSON object with two members: `file`, its
  file, and `lines`, a JSON array of its file lines, each a run, in their
  order.
- `edges`: a JSON array with one element for each edge of the tree, in
  the code point order of the valid paths of their files and then in the
  order of the origin positions of their citation entries or inline
  citations. Each element is a JSON object with these members: `kind`,
  the kind of edge, as a text; `file`, the file of its citation entry or
  inline citation; `at`, the origin position of that citation entry or
  inline citation; `source`, its source, as a reference, only when it has
  a source; and `cited`, its cited item, as a reference, only when it has
  a cited item.
- `status-tags`: a JSON array with one element for each accepted input
  of the tree that is a status tag, in the code point order of the valid
  paths of their files and then in the order of their origin positions.
  Each element is a JSON object with these members: `file`, its file;
  `at`, the origin position of its text; and `item`, the item in which
  it stands, as a reference, only when it stands in an item.
- `extern-marks`: a JSON array with one element for each extern mark of
  the tree, in the code point order of the valid paths of the files of
  their `@extern` lines and then in the order of the origin positions of
  the texts of these lines. Each element is a JSON object with these
  members: `file`, the file of its `@extern` line; `at`, the origin
  position of the text of that line; `design`, the index of its item of
  the kind design in `items`; and `valid`, the JSON value `true` when
  the extern mark is valid, and `false` when it is not.
- `findings`: a JSON array with one element for each tree finding that
  the tree has, of one of the classes that the requirement
  `give-tree-findings` names, in the code point order of the slugs of
  their classes and then in the code point order of their subjects. Each
  element is a JSON object with these members: `class`, the slug of its
  class; `subject`, its subject; and `spot`, its spot: a JSON object
  with the member `path`, its valid path, and, when the spot has a span,
  the member `span`, that span, as a run.

In the group `code`, the JSON object also has these members:

- `tests`: a JSON array with one element for each test of each read file
  of the tree, in the code point order of the valid paths of their files,
  then in the order of the boundaries where their codes start, and, of
  two whose codes start at one boundary, in the order of the parse tree
  of their test nodes. Each element is a JSON object with these members:
  `file`, its file; `name`, its name, as a name path; `code`, its code,
  as a run; and `comments`, a JSON array with one element for each
  comment on it, in the order of the boundaries where these runs of
  comments start: the run of the text from the boundary where that run
  of comments starts to the boundary where that run of comments ends.
- `code-hashes`: a JSON array with one element for each run of comments
  of the tree that has a code hash, in the code point order of the valid
  paths of their files and then in the order of the boundaries where
  these runs of comments start. Each element is a JSON object with these
  members: `file`, its file; `comments`, the run of the text from the
  boundary where that run of comments starts to the boundary where that
  run of comments ends; `code-text`, the code text of the attachment
  target to which it attaches; and `code-hash`, its code hash.

A reference to an item is a JSON object of one of these forms:
`{"item":k}`, the declared item with the index k in `items`;
`{"test":k}`, the test with the index k in `tests`; `{"site":k}`, the
site with the index k in `sites`; `{"external":t}`, the external item
whose external id, with its `#` and part name when it has them, is the
text t; `{"of":k,"vector":v}`, the conformance vector whose vector line
is the vector line with the number v of the vector set of the declared
item with the index k;
`{"group":g,"of":k}`, the group of conformance vectors with the name g
of that vector set; and `{"vector-set":k}`, the vector set of the
declared item with the index k.

A name path is a JSON array of its own names, in their order. An own
name is a JSON array of its pieces, in their order. A text piece is the
JSON object `{"text":t}` and a placeholder is the JSON object
`{"placeholder":t}`, where t is the text of the piece.

For the input of a vector, a conforming program that reads the tree
under the two bindings of the input gives what `values` states. When
`values` is `{}`, it gives, for the tree, none of the things that the
members above name. Otherwise, when it gives one of the things that a
member names, it gives what that member states for it:

- When it gives the read files, it gives the keys of `read-files`, each
  with the reader of the pair at its index, and no other read file.
- When it gives the declared items, it gives one for each element of
  `items`, with its kind of item, its name, its file, and the origin
  position of the text of its declaration, and no other declared item.
- When it gives the extent, the hash text, the extent hash, the item of
  the kind design or of the kind specification to which a declared item
  belongs, or the vector file of a declared item, it gives what the
  element of that item states, and for a member that the element does not
  have, that the item belongs to no such item or has no vector file.
- When it gives the sites, the edges, the items in which status tags
  stand, the extern marks, the tests, or the code hashes, it gives one
  for each element of the member, with what that element states, and no
  other.
  For an element of `edges` without `source` or without `cited`, it
  gives that the edge has no source or no cited item. For an element of
  `status-tags` without `item`, it gives that the status tag stands in no
  item.
- When it gives the code text of the attachment target to which a run
  of comments that has a code hash attaches, it gives the `code-text` of
  the element of `code-hashes` for that run of comments.
- When it gives the tree findings of one of the classes that the
  requirement `give-tree-findings` names, it gives one for each element
  of `findings` of that class, with the class and the subject that the
  element states, and no other tree finding of that class. When it gives
  the spot of such a finding, it gives the spot that the element states.

### 6.1 Markdown files

The group `markdown` has the vectors of trees that have no code file.
Its vectors follow from the requirements
`give-nothing-under-invalid-bindings`, `give-read-files`,
`give-declared-items`, `give-extents`, `give-extent-hashes`,
`give-hash-texts`, `give-containment`, `give-sites`, `give-edges`,
`give-status-tag-items`, `give-extern-marks`, `give-vector-files`, and
`give-tree-findings`.

- `input`: a JSON object with three members. `files` is the tree.
  `file-readers` is a JSON array with one element for each pair of a
  binding of `file-readers`, in their order: the path set of that pair,
  whose reader is `markdown`. `external-namespaces` is a binding of
  `external-namespaces`. The program reads the tree under these two
  bindings.
- `values`: as the section above describes, without the members `tests`
  and `code-hashes`.

These lines of the file are vectors of the group:

```
{"group":"markdown","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"GH"}],"file-readers":[["docs/**/*.md","*.md"]],"files":{"docs/a.md":"# A\n@design a=v1\n"}},"n":2,"note":"a namespace name with an upper-case letter makes the binding of external-namespaces invalid","rev":"v1","values":{}}
{"group":"markdown","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["docs/**/*.md","*.md"]],"files":{"README.md":"@cites b=v1\n","docs/bad.md":{"bytes":"4064657369676e20623d76310aff"}}},"n":8,"note":"a file that is not valid UTF-8 cannot be read: one parse-error finding, and no declared item","rev":"v1","values":{"edges":[{"at":{"column":8,"line":1},"file":"README.md","kind":"cites","source":{"site":1}}],"extern-marks":[],"findings":[{"class":"dangling","spot":{"path":"README.md","span":{"from":7,"to":11}},"subject":"README.md@L1C8"},{"class":"parse-error","spot":{"path":"docs/bad.md"},"subject":"docs/bad.md"}],"items":[],"read-files":{"README.md":1,"docs/bad.md":1},"sites":[{"file":"README.md","lines":[{"from":0,"to":11}]}],"status-tags":[]}}
{"group":"markdown","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["docs/**/*.md","*.md"]],"files":{"docs/top.md":"@design top=v1\nIntro.\n\n# Part\nMore.\n"}},"n":17,"note":"a declaration in the first paragraph of the section of level 0 claims that section","rev":"v1","values":{"edges":[],"extern-marks":[],"findings":[],"items":[{"at":{"column":1,"line":1},"extent":[{"from":0,"to":14},{"from":15,"to":21}],"extent-hash":"63b969dd84c36a464f6003892afe796144b01af0a813773b0126952b67ac6a2a","file":"docs/top.md","kind":"design","name":"top"}],"read-files":{"docs/top.md":1},"sites":[],"status-tags":[]}}
```

### 6.2 Code files

The group `code` has the vectors of trees that can have code files.
Its vectors follow from the requirements of the group `markdown`, and
from the requirements `give-tests`, `give-code-hashes`, and
`give-code-texts`.

- `input`: a JSON object with three members. `files` is the tree.
  `external-namespaces` is a binding of `external-namespaces`.
  `file-readers` is a JSON array with one element for each pair of a
  binding of `file-readers`, in their order. Each element is a JSON
  object with two members: `paths`, the path set of the pair, and
  `reader`, the text `markdown`, or a JSON object that stands for a
  valid pack. That JSON object has these members: `line`, `inner`, and
  `foreign-tags`, each a JSON array of texts: the line sigils, the inner
  sigils, and the foreign tag words of the descriptor of the pack, in
  their order, each foreign tag word with its `@`; `block`, a JSON array
  with one element for each block pair of the descriptor, in their
  order, each a JSON array of two texts, the opening sigil and the
  closing sigil; and `readings`, a JSON object with one member for each
  read file of the tree whose content is valid UTF-8 and whose valid
  path is in the set of the path set of this pair and of no pair before
  it. The key of that member is the valid path of the file, and its
  value is the reading of the text of the file with the pack: a JSON
  object with the member `result`, the result of the reading, as a text,
  and, only when that result is "parsed", the member `nodes`.
- `nodes` is a JSON array with one element for each node of the reading
  that is a comment node, a definition node, a decoration node, or a
  test node, in the order of the parse tree. Each element is a JSON
  object with the member `run`, the run of the node, and with these
  members for what the node is: `comment`, the text `tagged` or the text
  `untagged`, for a comment node; `body`, a JSON array of the runs of its
  body nodes, in the order of the parse tree, for a definition node;
  `decoration`, the JSON value `true`, for a decoration node; and `test`,
  its name path, for a test node. A node that is a definition node and a
  test node has the members `body` and `test`.
- `values`: as the section above describes, with the members `tests` and
  `code-hashes`.

The input stands for each binding of `file-readers` whose pairs have
these path sets, whose reader is `markdown` where the input gives
`markdown`, and whose packs have descriptors with these comment sigils
and foreign tag words and give these readings of these texts at these
valid paths.

This line of the file is a vector of the group:

```
{"group":"code","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[{"paths":["lib/"],"reader":{"block":[],"foreign-tags":[],"inner":[],"line":["//"],"readings":{"lib/a.rs":{"result":"parse failure"},"lib/b.rs":{"result":"no grammar"}}}}],"files":{"lib/a.rs":"// @req a=v1\n","lib/b.rs":"// @req b=v1\n","lib/c.rs":{"bytes":"2f2f20ff0a"}}},"n":66,"note":"a code file cannot be read when its reading has the result no grammar or parse failure, or when its content is not valid UTF-8","rev":"v1","values":{"code-hashes":[],"edges":[],"extern-marks":[],"findings":[{"class":"parse-error","spot":{"path":"lib/a.rs"},"subject":"lib/a.rs"},{"class":"parse-error","spot":{"path":"lib/b.rs"},"subject":"lib/b.rs"},{"class":"parse-error","spot":{"path":"lib/c.rs"},"subject":"lib/c.rs"}],"items":[],"read-files":{"lib/a.rs":1,"lib/b.rs":1,"lib/c.rs":1},"sites":[],"status-tags":[],"tests":[]}}
```
