<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Documents
@design documents=v1
@cites conformance=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites object-store=v1
@cites packs=v1
@cites findings=v1
@cites commonmark/0.31.2
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies the files of a tree that a conforming program reads, with their readers; the parameter `vector-paths` and the caller input `kept-object-set`; the files that cannot be read; the front matter, sections, list items, and paragraph lines of markdown files; the runs of comments, comment lines, attachment, and tests of code files; tag texts, the places that their characters come from, and the inputs that they give; declared items in both the text encoding and the `.sinter/` encoding; the claims, extents, hashed lines, containment, names, written lines, written tag lines, written text of inline elements, canonical objects, and group description objects of a tree; what citation entries, inline citations, and content ids name; extern marks, vector files, code texts, code hashes, sites, and edges; the subject forms `position-subject` and `edge-finding-subject`; the finding classes `parse-error`, `typo-tag`, `ignored-tag`, `invalid-target`, `duplicate`, `dangling`, `wrong-source`, `wrong-kind`, `misplaced-declaration`, `req-outside-design`, `extern-mismatch`, `pin-cycle`, `ambiguous-pin`, `unmatched-vector-file`, and `ambiguous-vector-file`; and requirements for conforming programs that give these.

A conforming program reads the files of a tree in both defined encodings
to find the objects and items that Sinter traces and the edges between
them. A binding of the parameter `file-readers` says which files of the
tree outside `.sinter/` the program reads in the text encoding, and how.
A binding of the parameter `vector-paths` says which files of the tree
outside `.sinter/` the program searches for test-vector files. The
Object store design defines the `.sinter/` encoding: valid object files
in `.sinter/` hold declared items, records, work item objects, scope
objects, and computed identity objects. A caller can also supply kept
objects of the log branch (`kept-object-set`) for resolving exact pins and
content-id citations to earlier revisions.

The program reads a markdown file by CommonMark 0.31.2, and reads a code
file with a language pack. In a markdown file, the program reads tags in
the first paragraph of each section and of each list item. In a code
file, the program reads tags in the comments that the pack finds. Each
of these paragraphs, and each run of comments that has a tagged comment
node, gives one tag text. A conforming program of Identifiers gives a
result for each input of the tree. Each declaration with the result
"valid" declares a declared item in the text encoding, and each
unwithdrawn, unreplaced declared-item object in a valid object file of
`.sinter/` is a declared item in the `.sinter/` encoding. Each declared
item has one canonical object (holding its normalized `text`, optional
`label`, optional `status`, and `edges` targeting content ids) and one
content hash and content id computed from that canonical object. Each
citation entry of a citation with the result "valid", each inline
citation with the result "valid", each citation edge of a stored
declared item in `.sinter/`, and each vector line of a vector set gives
an edge. Some conditions of these files and canonical objects are
findings, such as a citation that names no item, a pin cycle, or an
unmatched vector file.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405. A production, such as
`front-matter-line = ( "+++" / "---" ) *WSP`, gives the texts that its
rule name matches.

From Conformance (`conformance`), the design takes conforming programs,
inputs, dependence, objects, encodings, valid program's own stores, and
the general requirements that bind every conforming program, including
`end-runs-at-limits`, `reject-invalid-inputs`, `report-missing-parts`,
`give-results-over-canonical-objects`, and `read-defined-encodings`.
From Text and notation, the design takes characters, texts, places,
boundaries, runs, bodies, line endings, lines, line numbers, positions,
and spans; whole numbers, decimal numerals, and hex digits; bytes and 0x
numerals; valid UTF-8 and UTF-8 encodings; code point order; the
notation of productions and code spans; sequences and algorithms; and
results. From Identifiers, the design takes tag lines, tag words, and
Sinter tag words; declarations, citations, citation entries, status
tags, directives, and continuation lines; links, inline citations, their
destinations, the raw content and the link texts of paragraphs and
headings, the plain string content of link texts, and the markdown
document of a text; the texts of tag lines and inline descriptions;
targets, names, slugs, segments, part names, full names, kind words,
labels, revisions, vector selections, external ids, content ids, and
object kind words; the productions of the forms of tag lines and of
inline citations; the parameter `external-namespaces`; and the inputs of
a conforming program of Identifiers and the results that the program
gives. From Files and paths, the design takes valid paths with their
numbered file names, path sets, valid path sets, and the set of a path
set. From Data forms, the design takes JSON values, canonical forms,
canonical byte sequences, line objects, hashes, hash ids, indexes, hex
texts, group names, test-vector file names, test-vector sets, vector
lines, vector objects, form pins, the forms of a group, and the meaning
of a vector. From the Ontology, the design takes trees and their files;
parameters; objects, the schema table of object kinds (`object-kind`),
content hashes, content ids, computed identity objects, encodings, and
object withdrawal (counting voids, withdrawn objects, and replaced
objects); items and their kinds, declared items, containment, and the
names of declared items; tests and comments on tests; sites; external
items; vector sets and groups of conformance vectors; revised content
and item revisions; edges, pinned edges, claims from code, their kinds,
sources, and cited items, and the item in which a line, a citation, or
an inline citation stands; and findings and finding classes. From Object
store (`object-store`), the design takes store files, valid object
files, needed identity files, the object store of a tree, the finding
classes `invalid-object-file` and `missing-identity-file`, and the
requirements `give-store-objects` and `give-store-findings`. From
Language packs, the design takes packs and valid packs; the reading of a
text with a pack; comment nodes, definition nodes with their body nodes,
decoration nodes, and test nodes with their name paths; the runs of
nodes, enclosed nodes, and the order of the parse tree; and descriptors,
with their comment sigils and foreign tag words. From Findings, the
design takes the subjects, the spots, and the other parts of a finding.

From CommonMark 0.31.2, the design takes its lines, blocks, paragraphs,
ATX headings, setext headings, thematic breaks, code blocks with their
info strings and content, HTML blocks, block quotes, lists with their
start numbers, list items, and link reference definitions; and its
inline elements: textual content, backslash escapes, entity and numeric
character references, code spans, emphasis, strong emphasis, links with
their link destinations and link titles, autolinks, images, raw HTML,
and hard and soft line breaks. From RFC 8259, the design takes JSON
values, with their objects, members, arrays, strings, numbers, and the
literal names `true` and `false`.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [tree](sinter:ontology#tree=v1), [file of a tree](sinter:ontology#tree=v1) | a set of files, each a valid path with a content, which is a byte sequence; no two files of a tree have the same valid path |
| [text of a file](sinter:ontology#tree=v1) | the text of the content of a file of a tree, when that content is valid UTF-8 |
| [valid path](sinter:files#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [path set](sinter:files#path-set=v1), [set of a path set](sinter:files#path-set-membership=v1) | a finite sequence of texts, such as `docs/` followed by `!docs/old/`; its set is the valid paths that it gives, such as `docs/a.md` and not `docs/old/a.md` |
| [pack](sinter:packs#pack=v1), [valid pack](sinter:packs#valid-pack=v1) | a language pack: a folder tree that has the support for one language, such as its grammars and query files; a pack is valid when it has all its required files, each with the right content |
| [reading of a text](sinter:packs#reading-of-a-text=v1) | the reading of a text, as the text of a file at a valid path, with a valid pack: the result of the reading, "no grammar", "parse failure", or "parsed", and, with "parsed", the nodes that the pack finds in the text |
| [comment node](sinter:packs#comment-node=v1), [tagged](sinter:packs#comment-node=v1) | a node of a reading that the pack finds as a comment; a comment node is tagged when it can carry tags |
| [definition node](sinter:packs#definition-node=v1), [body node](sinter:packs#definition-node=v1), [decoration node](sinter:packs#decoration-node=v1) | a node that the pack finds as a definition, such as a function or a module, with the nodes of its body; and a node that the pack finds as a decoration, such as a Rust attribute |
| [test node](sinter:packs#test-node=v1), [name path](sinter:packs#test-name=v1) | a node that the pack finds as the code of one test, with the name of that test as the code writes it |
| [run of a node](sinter:packs#node-run=v1) | the run of the text that a node takes up |
| [order of the parse tree](sinter:packs#parse-tree-order=v1) | the order of the nodes of a parse tree in which each node comes before its descendants, and the first of two children of one node, with the descendants of that first child, comes before the second child |
| [enclose](sinter:packs#enclosed-node=v1) | a node A encloses a different node B when the run of A starts at or before the start of the run of B, the run of A ends at or after the end of the run of B, and B does not come before A in the order of the parse tree |
| [descriptor](sinter:packs#valid-pack=v1) | the valid descriptor of a valid pack, which gives the comment sigils, the foreign tag words, and the grammars of the pack |
| [comment sigil](sinter:packs#comment-sigil=v1) | a line sigil, such as `//`; the opening sigil and the closing sigil of a block pair, such as `/*` and `*/`; or an inner sigil, such as `*` |
| [foreign tag word](sinter:packs#foreign-tag-word=v1) | a tag word, such as `@param`, that the language of a pack, or a tool of that language, uses in comments with a meaning of its own |
| [binding of `file-readers`](sinter:#file-readers=v1), [reader](sinter:#file-reader=v1) | a finite sequence of pairs, each a reader and a path set; a reader is the text `markdown` or a pack; a binding is valid when each of its path sets is a valid path set and each of its packs is a valid pack; `file-readers` binds only the text encoding and never reads files under `.sinter/`; the reader of a valid path is the reader of the first pair whose path set has that valid path in its set |
| [binding of `vector-paths`](sinter:#vector-paths=v1) | a path set that locates test-vector files outside `.sinter/`; a binding is valid when it is a valid path set |
| [kept object set](sinter:#kept-object-set=v1) | a caller input holding kept objects of the log branch (kept declared-item objects and kept computed identity objects, without `seq` or `by`) used to resolve exact pins and content-id citations to earlier revisions; empty when omitted |
| [read file](sinter:#read-file=v1) | under a valid binding of `file-readers`, a file of a tree whose valid path has a reader, does not start with `.sinter/`, has no line feed, and does not start or end with a space or a tab |
| [markdown file](sinter:#read-file=v1), [code file](sinter:#read-file=v1) | a read file whose reader is the text `markdown`; a read file whose reader is a pack |
| [object store of a tree](sinter:object-store#tree-object-store=v1), [store file](sinter:object-store#store-file=v1), [valid object file](sinter:object-store#valid-object-file=v1) | the set of all store files of a tree (files inside `.sinter/` outside `.sinter/local/`); a valid object file holds the canonical byte sequence of one valid canonical object at its content-hash path |
| [object](sinter:ontology#object=v1), [object kind](sinter:ontology#object-kind=v1), [content hash](sinter:ontology#content-hash=v1), [content id](sinter:ontology#content-id=v1) | an entity of one of the twenty-five object kinds in `ontology#object-kind` in canonical line-object form without `id`; its SHA-256 hash; its `<kind>:<first 32 hex digits>` identifier |
| [computed identity](sinter:ontology#computed-identity=v1) | an object of one of the five kinds `name`, `pin`, `ext`, `vector-set`, and `vector-group`, holding only `kind`, `v` (1), and its key |
| [counting void](sinter:ontology#object-withdrawal=v1), [withdrawn](sinter:ontology#object-withdrawal=v1), [replaced](sinter:ontology#object-withdrawal=v1) | a `void` object in `.sinter/` that counts under `ontology#object-withdrawal`; an object named by a counting void's `withdraws` edge; a declared-item object in `.sinter/` named by a `revises` edge of an unwithdrawn declared-item object of the same name or of a counting void of a declared-item kind |
| [cannot be read](sinter:#unreadable-file=v1) | a read file cannot be read when its content is not valid UTF-8, or when it is a code file whose reading has the result "no grammar" or "parse failure" |
| [markdown line](sinter:#markdown-line=v1) | a line of the body of a text as CommonMark 0.31.2 gives it |
| [front matter](sinter:#front-matter=v1), [markdown text](sinter:#front-matter=v1) | the markdown lines from a first line that has only `+++` or `---`, with spaces and tabs after them, to the next such line with the same three characters; the text of a markdown file after its front matter |
| [section](sinter:#markdown-section=v1), [heading that opens a section](sinter:#markdown-section=v1) | the markdown lines from the first line of an ATX heading or a setext heading that no block quote and no list item contains, up to the line before the next such heading of the same or a smaller level, or to the end of the markdown text; the lines before the first such heading are the section of level 0 |
| [first paragraph](sinter:#markdown-section=v1) | after the heading of a section, the first block that no block quote, no list, and no list item contains, or, for the section of level 0, the first such block of the markdown document; or the first block that a list item contains and that no block quote, no list, and no list item inside that list item contains; each only when that block is a paragraph |
| [list item](sinter:#markdown-list-item=v1) | a list item of CommonMark 0.31.2 that no block quote contains |
| [line of a paragraph](sinter:#paragraph-line=v1), task marker | the part of a markdown line that a paragraph takes: the first line starts at the first character of the paragraph that is not a space or a tab, and, in the first paragraph of a list item, after a task marker such as `[x]`; each other line is a whole markdown line |
| [code character](sinter:#code-character=v1) | a character of a code file that is in no comment node and in no line ending, and that is not a space or a tab |
| [lines of a run](sinter:#run-line=v1) | for each line that has a place of a run of a text, the places of the run on that line; and the empty lines inside the run |
| [run of comments](sinter:#comment-run=v1) | a sequence of the comment nodes that no other comment node encloses, each of which starts on the last line of the one before it or on the next line, with only spaces, tabs, and line endings between them; a comment node that starts on a line with a code character is a run of comments by itself, and no other comment node joins that run of comments |
| [comment line](sinter:#comment-line=v1) | a line of a tagged comment node, without its comment sigils and without the indentation of the comment itself |
| [tag text](sinter:#tag-text=v1) | the lines of a first paragraph in a markdown file, or the comment lines of the tagged comment nodes of one run of comments that has a tagged comment node in a code file, joined by line feeds |
| [origin](sinter:#origin=v1), [origin position](sinter:#origin-position=v1) | the places of the text of a file that a part of a tag text or of a markdown text comes from; the position at which that part starts, which is the position of the `@` for the text of a tag line |
| [file line](sinter:#file-line=v1) | a markdown line of a markdown file, or a line that a tag text of a code file joins |
| [input of a tree](sinter:#accepted-input=v1), [accepted input](sinter:#accepted-input=v1), [file of an input](sinter:#accepted-input=v1) | a line of a tag text, with its continuation lines, or a link of a markdown text or of a tag text of a code file, to which a conforming program of Identifiers gives a result; an accepted input gets the result "valid"; the file of an input is the read file of the tag text or the markdown text in which that input is |
| [blank line](sinter:#blank-line=v1) | a line of any kind whose text has no character other than spaces and tabs |
| [block of a tag text](sinter:#tag-text-block=v1), trailing prose | a tag line, the tag lines and continuation lines right after that tag line, and the trailing prose of the block: the lines after those tag lines and continuation lines up to the next tag line or the end of the tag text |
| [attachment target](sinter:#attachment=v1), [attach](sinter:#attachment=v1), unattached | a definition node or a test node; a run of comments R attaches to the first attachment target T after R, when no code character stands before R on the first line of R, each code character between R and T is in a decoration node, and each line between R and T has a code character in a decoration node, or has in that line a line of the run of a comment node; a run of comments that attaches to no attachment target is unattached |
| [tests of a read file](sinter:#file-test=v1) | the tests whose code is a test node of a code file that can be read; a markdown file and a read file that cannot be read have none |
| [declaration of a declared item](sinter:#item-file=v1), [file of a declared item](sinter:#item-file=v1), [text declared item](sinter:#item-file=v1), [stored declared item](sinter:#item-file=v1) | a text declared item is what an accepted declaration declares in a read file; a stored declared item is an unwithdrawn, unreplaced declared-item object in a valid object file of `.sinter/`; the file of a declared item is that read file or that valid object file |
| [claim](sinter:#claim=v1) | the lines that a declaration D claims in the text encoding: in markdown, the section or the list item of D, from the tag line of D when another declaration of the paragraph of D comes before D, up to the next declaration of the paragraph of D; in code, for D, its part of its block of a tag text; in both, without the blank lines at the end of the claim |
| [scope](sinter:#item-scope=v1) | the file lines in which a text design or a text specification gathers its items: in markdown, the markdown lines of the section or the list item whose first paragraph has its declaration; in code, for a design, its claim, and for a specification, the lines of its tag text, with the file lines in the run of the attachment target of its run of comments, or every file line of the file when its run of comments is unattached and no code character comes before that run of comments |
| [innermost](sinter:#innermost-item=v1) | of some text declared items whose claims, or whose scopes, have a thing in them, the declared item whose claim, or scope, is a subset of the claim, or scope, of each of the other declared items, when the claim, or scope, of exactly one of those declared items is such a subset |
| [design of a slug](sinter:#slug-design=v1) | the item of the kind design of the tree (in either encoding) whose name is the slug, when no other item of the kind design and no decision record of the tree has that name |
| [home design](sinter:#home-design=v1) | for a tag line or an inline citation, the innermost text item of the kind design in whose scope that tag line or inline citation is; otherwise, in a code file, when the declaration of the innermost requirement, schema, atom, or term in whose claim that tag line or inline citation is names that requirement, schema, atom, or term by a full name whose slug has a design, that design; otherwise, when the declaration of the innermost specification in whose scope that tag line or inline citation is names that specification by a full name whose slug has a design, that design; otherwise none |
| [text containment](sinter:#text-containment=v1), [belong to](sinter:#tree-containment=v1), [hold](sinter:ontology#containment=v1) | design containment across both encodings together with text specification containment; full containment in a tree adds stored specification containment by exact `items` edges |
| [extent](sinter:#extent=v1) | the file lines that a text declared item d takes up: the claim of d, without the claims of the other text declared items inside the claim of d that d does not hold, and with the extents of the text declared items in the same file that d holds |
| [section number](sinter:#section-number=v1) | the text that the production `section-number` matches, such as `2.1 ` in `## 2.1 Amount limit` |
| [hashed lines](sinter:#hashed-line=v1) | the lines of the extent of a text declared item, without the lines of the extents of the items that belong to it when it is a `design` or a `spec` |
| [written lines](sinter:#written-line=v1) | the lines that a block of a markdown document gives for the canonical `text` of a text declared item, each an indent, a mark, such as `heading +1:`, `paragraph:`, `break`, or `|` for a line of code, and, after most marks, a text |
| [written tag lines](sinter:#written-line=v1), [cluster](sinter:#written-line=v1) | the lines that a tag text gives for the canonical `text` of a text declared item: for each cluster, task markers on non-declaration lines, non-accepted tag lines, and the written lines of prose (dropping all accepted Sinter tag lines and `@extern` inline descriptions) |
| [written text](sinter:#written-inline=v1) | the text that a sequence of inline elements gives on one line for a text declared item: textual content with each run of spaces, tabs, and soft line breaks as one space, and the other inline elements in marks between `{` and `}`, such as `{em:steps}` and `{link{the limit}{sinter:name:...}}`, where the destination of a valid inline citation is `sinter:` followed by its canonical target content id, with `\`, `{`, `}`, and line feeds escaped |
| [valid inline citation](sinter:#written-inline=v1) | an inline citation to which a conforming program of Identifiers gives the result "valid" for the destination of that inline citation and the plain string content of the link text of that inline citation |
| [canonical object of a tree](sinter:#canonical-object=v1) | the canonical JSON line object (without `id`) of each declared item (text or `.sinter/`), each group description object (`vector-group-def`), and each computed identity object of the tree, together with the rules of exact pins, `pin` objects, `name` objects, `ext`, `vector-set`, `vector-group`, non-identity content ids, and missing parts |
| [code text](sinter:#code-hash=v1), [code hash](sinter:#code-hash=v1) | the text of the code of an attachment target, or of the body nodes of a definition node, line by line, without the spaces and tabs at the end of each line and without the indentation that its lines share; the hash of the UTF-8 encoding of the code text of the attachment target to which a run of comments with a tagged comment node attaches |
| [set of names](sinter:#name-set=v1) | a set of declared items (across text and `.sinter/`): the shared set, which has the items of the kind `design`, the `decision` records, and the `spec`, `req`, `schema`, `atom`, and `term` items that belong to no design and whose names are slugs; or the set of the `spec`, `req`, `schema`, `atom`, and `term` items that belong to one item of the kind `design` |
| [kind word states](sinter:#stated-kind=v1) | the kinds of item that a written kind word, such as `req`, says that a text citation entry or inline citation names |
| [name names](sinter:#named-item=v1) | the item, or nothing, that the entry name of a citation entry, or the name or external id of an inline citation, names in a tree, for a home design |
| [vector file](sinter:#vector-file=v1), [vector set](sinter:#vector-file=v1) | under a valid binding of `vector-paths`, for an item of the kind `design`, or for an item of the kind `spec` that belongs to one (in either encoding), the one file in `vector-paths` outside `.sinter/` whose valid path equals or ends with `/` followed by its test-vector file name, when it matches no other item; the vector set is the content of that vector file when that content is a test-vector set |
| [selected item](sinter:#selected-item=v1) | the group of conformance vectors or the vector set that a citation entry with a vector selection names |
| [part of a declared item](sinter:#item-part=v1) | a line, a citation, or an inline citation whose file lines are all lines of the extent of a text declared item |
| [sites of a read file](sinter:#tree-site=v1) | the file lines around citations, inline citations, and `@ack` lines that are outside every extent and every comment on a test, without the lines of extents: in markdown, the lines from a heading that opens a section, or from the start of the markdown text, up to the next such heading or to the end of the markdown text; in code, the lines of runs of comments that are no comments on tests; such parts that share a line of the text, directly or through other such parts, are one site |
| [site](sinter:ontology#site=v1) | a part of a file of a tree that is outside every declared item and every comment on a test, and that has a citation, an inline citation, or an `@ack` line |
| [extern mark](sinter:#extern-mark=v1), [valid extern mark](sinter:#valid-extern-mark=v1) | what an `@extern` line that stands in a text item of the kind `design` states: that the design holds a text item of the kind of the kind word of that `@extern` line, with the part name of that `@extern` line, in another read file; an extern mark is valid when the design holds such a text item in another read file, directly when that item is a `req`, `schema`, `atom`, or `term` |
| [edges of a tree](sinter:#tree-edge=v1), [form run](sinter:#tree-edge=v1), [form position](sinter:#tree-edge=v1) | the citation edges (`cites`, `satisfies`, `verifies`, `refines`, `supersedes`) that accepted text citations, accepted inline citations, vector lines of vector sets, and stored declared items in `.sinter/` give (ignoring `items`, `about`, `revises`, and all edges of records and `scope` objects); the form run and form position of a vector-line edge |
| [position subject](sinter:#position-subject=v1) | the subject of a finding at a position in a read file or in the vector file of a declared item, such as `docs/guide.md@L3C5` |
| [edge finding subject](sinter:#edge-finding-subject=v1) | the subject of a canonical-object finding on a citation edge whose source is a declared item: `<source-content-id> <edge-kind> <target-content-id>`, such as `req:0dc878fd2dc3c179e4b8fa1829666011 cites name:44e2541d838e3d62bc292978d4a0267f` |
| [order of positions](sinter:#position-order=v1) | one position comes before another when its line number is less, or when the two line numbers are the same and its column is less |
| [spot of a run](sinter:#run-spot=v1) | the spot whose span is a run of the text of a read file or of the vector file of a declared item |
| [tree finding](sinter:#tree-finding=v1) | a finding of a tree with a given class, a given subject, and a given spot or no spot, that is not ackable, and whose message, mark, related messages, and fix are those that the program that gives the finding gives |
| [edit distance](sinter:#edit-distance=v1) | the least number of insertions, removals, replacements, and swaps of characters next to each other that change one text into another |
| [finding](sinter:ontology#finding-class=v1), [finding class](sinter:ontology#finding-class=v1) | a report of one condition at one part of a repository; a kind of finding, which a slug names |
| [subject of a finding](sinter:findings#finding-subject=v1) | the text that names what a finding is about |
| [spot](sinter:findings#spot=v1) | a valid path of a file of a tree, alone or with a span of the text of that file |
| [mark of a finding](sinter:findings#mark=v1) | a spot whose span is the part of the spot of a finding that is at fault, with a message |
| [tag line](sinter:identifiers#tag-line=v1), [tag word](sinter:identifiers#tag-word=v1) | a line whose first character after the spaces and tabs at its start is `@`; the tag word of a tag line is that `@` with the longest run of ASCII letters, ASCII digits, and `-` right after that `@`, such as `@req` |
| [Sinter tag word](sinter:identifiers#sinter-tag-word=v1) | one of the fifteen tag words of Sinter, such as `@req`, `@cites`, `@deprecated`, and `@extern` |
| [declaration](sinter:identifiers#declaration=v1), [citation](sinter:identifiers#citation=v1), [status tag](sinter:identifiers#status-tag=v1), [directive](sinter:identifiers#directive=v1) | a tag line whose tag word is a declaration word, such as `@req`; a citation word, such as `@cites`; a status word, such as `@deprecated`; or `@ack` or `@extern` |
| [continuation line](sinter:identifiers#continuation-line=v1) | a line that continues the target list or the scoped list of a citation on a line before that continuation line |
| [link](sinter:identifiers#link=v1), [inline citation](sinter:identifiers#inline-citation=v1) | an inline link, a reference link, or an autolink of the markdown document of a text; an inline citation is a link whose destination starts with `sinter:` |
| [citation entry](sinter:identifiers#citation-entry=v1), [entry name](sinter:identifiers#citation-entry=v1) | one entry of the target of a citation, such as `billing#limit-amount=v2`; the entry name of a citation entry is its name, external id, or content id |
| [declared item](sinter:ontology#declared-item=v1) | an item of one of the seven kinds `design`, `spec`, `schema`, `req`, `atom`, `term`, and `decision`, in either the text encoding or the `.sinter/` encoding |
| [schema](sinter:ontology#schema=v1) | a declared item of the kind `schema`; it gives the form of a thing that crosses the boundary of a conforming program: its layout and every constraint that is a property of the thing itself |
| [atom](sinter:ontology#atom=v1) | a declared item of the kind `atom`; it defines a named result that a conforming program gives, with the condition under which it gives that name |
| [name of a declared item](sinter:ontology#item-name=v1) | the value of its canonical member `name`, such as `billing` or `billing#limit-amount` |
| [test](sinter:ontology#test=v1), [comment on a test](sinter:ontology#test=v1) | a unit of code that a test runner runs, or a set of such units that the code groups under one name; a comment that is attached to the code of a test |
| [edge](sinter:ontology#edge=v1), [stand in](sinter:ontology#edge-source=v1) | a relation of one kind of edge from its source to its target; a line, a citation, or an inline citation stands in the innermost declared item of which it is a part, otherwise in the innermost test such that a comment on that test has it, otherwise in the site that has it, otherwise in no item |
| [line](sinter:text#line=v1), [line ending](sinter:text#line-ending=v1) | one of the runs into which the line endings of a text divide its body; a line ending is a line feed, with the carriage return right before it when there is one |
| [position](sinter:text#position=v1) | a pair of a line number and a column, such as line 3, column 7 |
| [hash](sinter:data-forms#hash=v1) | the SHA-256 digest of a byte sequence, as 64 hex digits |
| [forms of a group](sinter:data-forms#group-form-list=v1) | five things that a schema that a specification declares under a name, or that a design declares under a name outside its specifications, gives for a group: the requirements of the group; what the value of `input` stands for, and its fixed form; the question that the value of `result` answers, the inputs that it is about, and the conditions under which the requirements oblige that result (the forms can name no question instead); what the value of `values` stands for, and its fixed form (the forms can give no fixed form for `values`); and the need names of the group, as `group-form-list` states |

## 2. Files, tag texts, items, and edges

### 2.1 Read files, `.sinter/`, and readers

A [binding of `file-readers`](sinter:#file-readers=v1) gives the
[read files](sinter:#read-file=v1) of a tree and the reader of each read
file. `file-readers` binds only the text encoding and never reads files
inside `.sinter/`, so a wide path set such as `**` reads neither store
files nor files inside `.sinter/local/`. The reader of a read file makes
that read file a markdown file or a code file. For example, under the
binding with the pair of the text `markdown` and the path set `docs/`,
and then the pair of a pack for OCaml and the path set `lib/**/*.ml`,
the file `docs/a.md` is a markdown file, the file `lib/x.ml` is a code
file whose pack is the pack for OCaml, and the file `README.md` is not
read.

A read file that [cannot be read](sinter:#unreadable-file=v1), such as
one whose content is not valid UTF-8, gives a finding of the class
[`parse-error`](sinter:#parse-error-finding=v1).

The [object store of a tree](sinter:object-store#tree-object-store=v1)
holds objects in the `.sinter/` encoding. Under a binding of
`file-readers` that is not valid, a conforming program gives nothing
that depends on `file-readers` — including every result over the objects
of the tree — while checks that read only `.sinter/` (such as
`object-store#give-store-findings`) remain intact. A conforming program
that takes objects only from a valid program's own store needs no
binding of `file-readers`. When the object store of a tree is not valid,
a conforming program gives no result over the objects of the tree, while
independent text-file results (such as read files, tests, code hashes,
and file findings) remain intact.

### 2.2 Markdown files

A markdown file is read by CommonMark 0.31.2. CommonMark 0.31.2 divides
the text of the markdown file into
[markdown lines](sinter:#markdown-line=v1). The positions of the
subjects of findings are always the positions of the text.

A markdown file can start with [front matter](sinter:#front-matter=v1),
such as lines of metadata between two lines of `---`. The rest of the
text of the markdown file is its markdown text. CommonMark 0.31.2 parses
that markdown text into blocks.

The tag lines of a markdown file are inputs of the tree only in the
[tag texts](sinter:#tag-text=v1) of that markdown file. The inline
citations of that markdown file are inputs in all of its markdown text.
An inline citation in a heading is an
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
[lines](sinter:#paragraph-line=v1) after that heading. The second tag
text is the two lines after `## 1. Invoices`. The third tag text is the
two lines after `### 1.1 Amount limit`. The section of level 0 is empty.

Another paragraph gives no tag text. Each tag line of that paragraph can
be a finding of the class
[`ignored-tag`](sinter:#ignored-tag-finding=v1), such as a line
`@req r=v1` in the second paragraph of a section. For example, the lines
`@req r=v1`, `Text.`, and `---` make a setext heading of level 2. The
line `@req r=v1` of that setext heading is such a finding too. As a
block of the document itself, the heading opens a
[section](sinter:#markdown-section=v1). The same lines in an indented
code block are no finding. A Sinter tag word in the inline description
of a tag line is such a finding too, such as `@cites` in the line
`@req r=v1 @cites x=v1 Text.` or in the line `@cites a=v1 @cites b=v1`,
which two tag lines give when they are joined into one line. A Sinter
tag word in a code span of such an inline description is no finding.

### 2.3 Code files

A code file is read with its pack. For that code file, the
[reading of its text](sinter:packs#reading-of-a-text=v1) gives the nodes
of its comments and of its code. The comment nodes of the code file form
[runs of comments](sinter:#comment-run=v1), the comments next to each
other in the file. For example, the lines `// a`, an empty line, and
`// b` give two runs of comments. The lines `// a`, `f();`, and `// b`
also give two runs of comments. In those lines, `f();` has
[code characters](sinter:#code-character=v1).

Each tagged comment node gives its
[comment lines](sinter:#comment-line=v1): its lines without the
[comment sigils](sinter:packs#comment-sigil=v1) of the descriptor of the
pack. For example, with the block pair `/*` and `*/` and the inner sigil
`*`, this comment node gives the comment lines ` @req a=v1`, ` A text.`,
and a line of one space:

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
after that run of comments. That code, such as a function, is the
attachment target of that run of comments. So in this Rust text, the run
of comments attaches to the test node of the function, and the
`@verifies` line is in a comment on that test:

```rust
// @verifies billing#limit-amount=v2
#[test]
fn rejects_large_amounts() {
    assert!(check(10_001).is_err());
}
```

A blank line between the comment and the attribute would leave the run
of comments unattached. The test nodes of a code file give its
[tests](sinter:#file-test=v1) and the comments on those tests.

### 2.4 Inputs, origins, and file lines

A conforming program of the design Identifiers reads the tag texts and
the markdown texts of a tree under a binding of `external-namespaces`,
and it gives a result for each of their
[inputs](sinter:#accepted-input=v1). The inputs with the result "valid"
are the accepted inputs. Together with the valid object store of the
tree (`object-store#tree-object-store`), the binding of
[`vector-paths`](sinter:#vector-paths=v1), and the caller input
[`kept-object-set`](sinter:#kept-object-set=v1), those accepted inputs give
the [declared items](sinter:#item-file=v1), the
[canonical objects](sinter:#canonical-object=v1), the
[edges](sinter:#tree-edge=v1), the
[extern marks](sinter:#extern-mark=v1), and the
[status tags](sinter:identifiers#status-tag=v1) of the tree. The binding
of `external-namespaces` governs external targets in both the text
encoding and the `.sinter/` encoding.

The [origin](sinter:#origin=v1) of a part of a tag text or of a markdown
text is the places of the text of the file of that tag text or markdown
text from which that part comes. The
[origin position](sinter:#origin-position=v1) of that part is where that
part starts. For example, the origin position of the text of the tag
line in `(* @req x=v1 *)` is the position of the `@` of that tag line,
not the position of the space before that `@`.

The [file lines](sinter:#file-line=v1) of a read file are the lines on
which claims, extents, scopes, and sites are built.

### 2.5 Claims and extents

Each accepted declaration declares one declared item. The
[claim](sinter:#claim=v1) of a declared item is the lines that its
declaration claims, such as the section of the heading before that
declaration in markdown. The [extent](sinter:#extent=v1) of a declared
item is the part of its file that the declared item takes up. The claim
of the declared item and the items that the declared item holds decide
that extent. In the example of section 2.2, the requirement claims the
lines from `### 1.1 Amount limit` to the end. In that example, the
specification and the design claim their sections. The specification
holds the requirement, so the extent of the specification is its whole
section.

In this OCaml text, with the block pair `(*` and `*)`, the specification
`journal#entry-ids` holds the requirement `id-form`:

```ocaml
(* @spec journal#entry-ids=v2
   Each entry of the journal has an id that its own bytes fix. *)
module Entry_id = struct
  (* @req id-form=v1
     An id is "e-" and the first hex digits of a SHA-256. *)
  let of_line line = digest line
end
```

The first run of comments attaches to the definition node of the module.
The [scope](sinter:#item-scope=v1) of the specification is its tag text,
with the file lines in the run of that module. The requirement `id-form`
is declared by one segment. The declaration of the requirement `id-form`
is in no scope of an item of the kind design. That declaration is in the
scope of the specification. The declaration of that specification has
the full name `journal#entry-ids`. So, when the slug `journal` has a
[design](sinter:#slug-design=v1), that design is its
[home design](sinter:#home-design=v1), and the requirement belongs to
that design and to the specification. The name of the requirement is
`journal#id-form`. The extent of the specification is its two comment
lines and the two comment lines of the requirement.

### 2.6 Containment and names

Containment says to which design, and to which specification, a declared
item belongs across both encodings, as
[containment in a tree](sinter:#tree-containment=v1) gives it. For
example, `@req billing#limit-amount=v2` in text, or a stored `req`
object in `.sinter/` whose member `name` is `billing#limit-amount`,
belongs to the design `billing` when the slug `billing` has a
[design](sinter:#slug-design=v1) in either encoding. In the text
encoding, a specification holds the declared items in its scope; in the
`.sinter/` encoding, a specification holds each declared item whose
current canonical object is the target of one of its `items` edges.

Names come in [sets of names](sinter:#name-set=v1) spanning both
encodings. Two declared items in one set whose names match after ASCII
case folding give one [`duplicate`](sinter:#duplicate-finding=v1)
finding for their folded name (with no spot), whether they stand in
text, in `.sinter/`, or one in each encoding. In `.sinter/`, a newer
revision of an item replaces an older revision of the same name through
a `revises` edge, and a counting void (`ontology#object-withdrawal`) can
withdraw a stored declared-item object while keeping what it replaced
replaced through the void's copied `revises` edges; moving an item
between text and `.sinter/` adds no `revises` edge. A citation entry or
an inline citation names an item as
[what names name](sinter:#named-item=v1) says. The written kind word of
a text citation entry or inline citation
[states](sinter:#stated-kind=v1) kinds of item; the text-only condition
of [`wrong-kind`](sinter:#wrong-kind-finding=v1) checks that written
kind word.

### 2.7 Extern marks and vector files

A text design can hold text items whose declarations are in other read
files. An `@extern` line in that text design, such as
`@extern spec:descriptor`, states an
[extern mark](sinter:#extern-mark=v1) of the design for such a text
item. The class [`extern-mismatch`](sinter:#extern-mismatch-finding=v1)
reports where the extern marks of a text design and its text items in
other read files do not agree. Because `@extern` is part of text-file
layout, a design in `.sinter/` carries no `@extern` marks, a held item
in `.sinter/` needs no `@extern` mark in a text design, an `@extern`
line naming a held item in `.sinter/` gives `extern-mismatch`, and an
`@extern` line does not enter the canonical object of its design. For
example, `@req billing#limit=v1` in a markdown file `notes.md` that has
no other declaration is a finding of the class
[`misplaced-declaration`](sinter:#misplaced-declaration-finding=v1),
also when the design `billing`, in another file, has the extern mark
`@extern req:limit`. In a code file, in the comment lines
`@req billing#limit=v1` and, on the next line, `@cites #{amount=v1}`,
the entry `#amount` names the item `billing#amount`, because `billing`
is the home design of that citation.

Under a valid binding of [`vector-paths`](sinter:#vector-paths=v1), a
conforming program locates the [vector file](sinter:#vector-file=v1) of
each design and each specification of a design (in either encoding) by
matching its test-vector file name among the files of `vector-paths`
outside `.sinter/`. For example, under `vector-paths` equal to `["**"]`,
the file `docs/billing.test-vectors.jsonl` matches the design `billing`,
and `docs/billing.invoice.test-vectors.jsonl` matches its specification
`billing#invoice`. When two or more files in `vector-paths` match one
design or specification, neither is its vector file and the tree gets an
[`ambiguous-vector-file`](sinter:#ambiguous-vector-file-finding=v1)
finding for that item's name. When a file in `vector-paths` outside
`.sinter/` ends with `.test-vectors.jsonl` and matches no design and no
specification of the tree, the tree gets an
[`unmatched-vector-file`](sinter:#unmatched-vector-file-finding=v1)
finding for that file. A citation entry with a vector selection names a
[selected item](sinter:#selected-item=v1). For example,
`billing#invoice[basic]` names the group of conformance vectors with the
name `basic` of the vector set of that specification.

### 2.8 Edges, sites, and status tags

The accepted text citations, the accepted inline citations, the vector
lines of the vector sets, and the citation edges (`cites`, `satisfies`,
`verifies`, `refines`, and `supersedes`) of stored declared items in
`.sinter/` give the [edges](sinter:#tree-edge=v1) of a tree. Structural,
scope, and record edge kinds (`items`, `about`, `revises`, and all edges
of records and `scope` objects) are not citation edges and are ignored
by citation findings. Citations and inline citations that stand in a
test or a site give claims from code whose location (file and line)
stays beside the edge. For example, in a file `README.md` with this
text, the `@cites` line is outside every extent, so it stands in the
[site](sinter:#tree-site=v1) of the file, which is its three lines, and
that site is the source of its edge:

```markdown
# Notes
@cites billing#limit-amount=v2
The limit protects new customers.
```

The file has the same site when Identifiers gives that `@cites` line the
result "invalid". A line `@deprecated` right after that `@cites` line
would stand in that site.

### 2.9 Canonical objects and code hashes

Every declared item (in text or in `.sinter/`), every group description
object (`vector-group-def`), and every computed identity object (`name`,
`pin`, `ext`, `vector-set`, `vector-group`) has one canonical JSON line
object without `id`, one content hash, and one content id
([canonical objects of a tree](sinter:#canonical-object=v1)). For a
declared item in the text encoding, the canonical object holds `kind`
(its short object kind word: `design`, `spec`, `schema`, `req`, `atom`,
`term`, or `decision`), `v` (1), `name`, `label` (optional on `term`),
`text`, optional `status` (sorted set of status words without `@`,
absent when empty), and `edges` (sorted set of `{"kind","to"}` flat
objects holding `about` naming its `name` object, `items` naming each
held item's exact canonical object when it is a `spec`, and each
citation edge standing in it).

The member `text` of a text declared item comes from its
[hashed lines](sinter:#hashed-line=v1) — its extent without the extents
of held items for both `design` and `spec` — normalized through
[written lines](sinter:#written-line=v1),
[written tag lines](sinter:#written-line=v1), and
[written text](sinter:#written-inline=v1). Accepted Sinter tag lines
(declarations, citations, status tags, `@extern`, and `@ack`) emit no
`tag:` line into `text`, and `@extern` inline descriptions do not enter
`text`. Non-accepted tag lines (such as foreign tags) and task markers
on non-declaration lines stay in `text`. The destination of a valid
inline citation in `text` is written as `sinter:` followed by its
canonical target content id `<to>` (and as shown text for an autolink),
so equivalent writings give one `text` and one content hash, and a kind
change of an unpinned target (`=*`) leaves the citing item's canonical
object and content hash unchanged.

In the example of section 2.2, the heading `### 1.1 Amount limit` gives
no line in the `text` of `billing#limit-amount`, and the `text` of
`billing#invoice` excludes the extent of `billing#limit-amount`:

- `billing#limit-amount` has the canonical object
  `{"edges":[{"kind":"about","to":"name:47097fff5449b36c49e87fc6fe62819a"}],"kind":"req","label":"v2","name":"billing#limit-amount","text":"paragraph: A conforming program must reject an invoice whose amount is more than 10,000 euros.\n","v":1}`
  and content id `req:bbb32b368ef46accea2129cbde39edd8`.
- `billing#invoice` has the canonical object
  `{"edges":[{"kind":"about","to":"name:b4ed52ed154d38c219d0ad079ad2113a"},{"kind":"items","to":"req:bbb32b368ef46accea2129cbde39edd8"}],"kind":"spec","label":"v2","name":"billing#invoice","text":"paragraph: An invoice asks a customer to pay a sum of money.\n","v":1}`
  and content id `spec:9ad9d30c9db7d9227d6dd810eee8a5d0`.
- `billing` has the canonical object
  `{"edges":[{"kind":"about","to":"name:4792925e51aabf3df653a6bd0bd32c2d"}],"kind":"design","label":"v4","name":"billing","text":"paragraph: Specifies the invoices that a billing service sends.\n","v":1}`
  and content id `design:4e8555c29f8659f4c9669824a843cd5c`.

An edit that CommonMark 0.31.2 reads as the same blocks and inline
elements, or a rewrite of citations into another order or form that
yields the same canonical `edges`, leaves the canonical object and
content id unchanged. Moving a declared item between text and `.sinter/`
with the same canonical object keeps the same content id and the same
canonical-object findings, changing only places.

The [code hash](sinter:#code-hash=v1) of a run of comments is the hash
of the UTF-8 encoding of the code text of the attachment target to which
that run of comments attaches. The code text leaves out the indentation
that the lines of the code share, so a function moved one level deeper,
such as into a module, keeps its code hash.

### 2.10 Findings

Each of these fifteen classes has an atom that gives its findings, each
a [tree finding](sinter:#tree-finding=v1):

| class | atom |
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
| `pin-cycle` | [`pin-cycle-finding`](sinter:#pin-cycle-finding=v1) |
| `ambiguous-pin` | [`ambiguous-pin-finding`](sinter:#ambiguous-pin-finding=v1) |
| `unmatched-vector-file` | [`unmatched-vector-file-finding`](sinter:#unmatched-vector-file-finding=v1) |
| `ambiguous-vector-file` | [`ambiguous-vector-file-finding`](sinter:#ambiguous-vector-file-finding=v1) |

## 3. Parameters

### 3.1 `file-readers`

@schema file-readers=v1
@cites {
    files#{path-set=v1, valid-path-set=v1},
    packs#{pack=v1, valid-pack=v1},
    ontology#{parameter=v1, encoding=v1},
    conformance#{own-store=v1},
    text#{text=v1, code-span=v1},
}

A binding of the parameter `file-readers` is a finite sequence of pairs.
Each pair has a reader and a path set. A reader is the text `markdown`
or a pack. A binding of `file-readers` meets the schema `file-readers`
when, and only when, each of its path sets is a valid path set and each
of its packs is a valid pack. `file-readers` binds only the text
encoding and never applies to `.sinter/` or to a program's own store; a
program that takes objects only from a valid program's own store needs
no binding of `file-readers`.

### 3.2 `vector-paths`

@schema vector-paths=v1
@cites {
    files#{path-set=v1, valid-path-set=v1},
    ontology#{parameter=v1},
    text#{code-span=v1},
}

A binding of the parameter `vector-paths` is a path set. A binding of
`vector-paths` meets the schema `vector-paths` when, and only when, it
is a valid path set. `vector-paths` locates test-vector files of a tree
outside `.sinter/`.

## 4. Definitions

### 4.1 Readers of valid paths

@term file-reader=v1
@cites {
    files#{path=v1, path-set=v1, path-set-membership=v1},
    ontology#{parameter=v1},
    #{file-readers=v1},
}

Under a valid binding of `file-readers`, the reader of a valid path is
the reader of the first pair of the binding whose path set has that
valid path in its set. A valid path that is in the set of no path set
of the binding has no reader.

### 4.2 Read files

@term read-file=v1
@cites {
    files#{path=v1},
    ontology#{tree=v1, parameter=v1},
    text#{text=v1, character=v1, line-feed=v1, space=v1, tab=v1, code-span=v1, whole-number=v1},
    #{file-readers=v1, file-reader=v1},
}

Under a valid binding of `file-readers`, a read file of a tree is a file
of the tree whose valid path meets all four of these conditions:

- its valid path has a reader;
- its valid path does not have two or more file names with file name 1
  equal to `.sinter` (no read file lies inside `.sinter/`, neither store
  files nor files inside `.sinter/local/`);
- its valid path has no line feed;
- its valid path has no space and no tab as its first character or as
  its last character.

The reader of a read file is the reader of its valid path. A read file
is a markdown file when its reader is the text `markdown`. A read file
is a code file when its reader is a pack. The reader of a code file is
the pack of that code file.

### 4.3 Files that cannot be read

@term unreadable-file=v1
@cites {
    files#{path=v1},
    packs#{reading-of-a-text=v1},
    text#{valid-utf-8=v1, text=v1, result=v1},
    ontology#{tree=v1, parameter=v1},
    #{read-file=v1, file-readers=v1},
}

This term is for a tree and a valid binding of `file-readers`. A read
file of the tree cannot be read when, and only when, one or both of
these conditions is true:
- the content of the read file is not valid UTF-8;
- the read file is a code file, and the reading of its text, as the text
  of a file at its valid path, with its pack has the result "no grammar"
  or the result "parse failure".

Each other read file can be read.

### 4.4 Markdown lines

@term markdown-line=v1
@cites {
    commonmark/0.31.2,
    text#{text=v1, run=v1, boundary=v1, body=v1},
}

A markdown line ending of a text is a run of its body that is a line
ending of CommonMark 0.31.2. A markdown line of a text is a run of its
body that is a line of CommonMark 0.31.2, without the line ending that
follows it. A run that ends at the boundary where the body ends is a
markdown line only when that run is not empty. The markdown lines of a
text are in the order of the boundaries where they start.

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

A markdown file that can be read starts with front matter when, and only
when, the first markdown line of its text is a front-matter line, and a
later markdown line of its text is a front-matter line whose first three
characters are the first three characters of that first markdown line.
The front matter of that markdown file is then the markdown lines of the
text of that markdown file from the first markdown line to the first
such later markdown line.

The markdown run of a markdown file that can be read is a run of its
text. When the file has no front matter, its markdown run starts at
boundary 0. Otherwise, the markdown run of the file starts at the
boundary where the markdown line ending right after the last line of the
front matter of the file ends, or at the last boundary of the text of
the file when no markdown line ending comes after that line. The
markdown run of the file ends at the last boundary of the text of the
file. The markdown text of the file is the text of its markdown run. The
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

This term is for a markdown file that can be read, and for the blocks
of its markdown document as CommonMark 0.31.2 parses that document. A
blank line is no block, and a link reference definition is a block. A
block of the document itself is a block that no block quote, no list,
and no list item contains. The k-th line of CommonMark 0.31.2 of
the markdown document comes from the k-th markdown line of the markdown
text. The markdown lines that a block takes are the markdown lines that
the lines of CommonMark 0.31.2 that the block takes come from.

A heading that opens a section is a block of the document itself that is
an ATX heading or a setext heading. The line of a heading that opens a
section is the first markdown line that the heading takes. For a heading
H that opens a section, the section of H is the markdown lines from the
line of H to the markdown line right before the line of the next heading
that opens a section and whose level is the same as the level of H or
less, or to the last markdown line of the markdown text when no such
heading comes after H. The section of level 0 is the markdown lines of
the markdown text that come before the line of the first heading that
opens a section, or all of the markdown lines of the markdown text when
no heading opens a section. The section of level 0 can be empty. The
first line of a section is the first markdown line of that section. The
last line of a section is the last markdown line of that section.

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
the lists that it contains. The first line of a list item is the first
of the markdown lines of that list item. The last line of a list item is
the last of the markdown lines of that list item. The first paragraph of
a list item is the first block that the list item contains and that no
block quote, no list, and no list item inside the list item contains,
when that block is a paragraph.

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

- The first line of the paragraph is a run of the first of these
  markdown lines. That run starts at the place of the first character of
  that markdown line that CommonMark 0.31.2 gives to the content of the
  paragraph and that is not a space or a tab. That run ends where that
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
place of the body of the text of that code file such that:
- the place is a place of the run of no comment node of the reading of
  the text of that code file with its pack;
- the character is not a space or a tab;
- the place is a place of no line ending.

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
its run starts. The last line number of a comment node is the line
number of the line that has the last place of the run of that comment
node that is a place of a line, or the first line number of that comment
node when no place of the run of that comment node is a place of a line.
So the last line number of a comment node whose run has the line ending
after its last line is the line number of that last line. A line number
has a code character when the line of the text with that line number has
one. An outer comment node is a comment node that no other comment node
encloses. A comment node that another comment node encloses is in no run
of comments.

The runs of comments of the file are sequences of outer comment nodes.
These rules give the runs of comments of the file, for each outer
comment node in turn, in the order of the boundaries where the runs of
the outer comment nodes start, and, of two outer comment nodes whose
runs start at one boundary, in the order of the parse tree:

1. When the first line number of the comment node has a code character,
   the comment node starts a new run of comments, and no other comment
   node joins that run of comments.
2. Otherwise, when an outer comment node P comes right before the
   comment node and each of these conditions is true, the comment node
   joins the run of comments of P:
- the first line number of the comment node is the last line number of P
  or 1 more;
- the boundary where the run of the comment node starts is not before
  the boundary where the run of P ends, and the run of the text between
  these two boundaries has no character other than spaces, tabs, and the
  characters of line endings;
- rule 1 did not start the run of comments of P.
3. Otherwise, the comment node starts a new run of comments.

A run of comments starts at the boundary where the run of its first
comment node starts. The run of comments ends at the boundary where the
run of its last comment node ends. The first line number of a run of
comments is the first line number of its first comment node. The last
line number of a run of comments is the last line number of its last
comment node.

### 4.12 Comment lines

@term comment-line=v1
@cites {
    packs#{comment-sigil=v1, comment-node=v1, valid-pack=v1},
    text#{
        text=v1, run=v1, boundary=v1, space=v1, tab=v1, character=v1,
        sequence=v1,
    },
    #{read-file=v1, unreadable-file=v1, run-line=v1},
}

This term is for a tagged comment node of a code file that can be read,
and for the comment sigils of the descriptor of the pack of that file.
To remove a text from the start of a run is to make the run start after
that text. To remove a text from the end of a run is to make the run end
before that text. The comment lines of the comment node are the lines of
its run, each made shorter as these rules say:

- On the first line of the run, remove the spaces and tabs at the start
  of that line. Then remove the longest text, among the line sigils and
  the opening sigils, that the rest starts with. When that removed text
  is a line sigil, the comment node is a line comment. When that removed
  text is an opening sigil and no line sigil, the comment node is a
  block comment of the first block pair whose opening sigil is that
  removed text. When the rest starts with no line sigil and no opening
  sigil, the comment node is a comment with no sigil. When the first
  line is also the last line of the run, the comment node is a block
  comment, and what remains ends with the closing sigil of the block
  pair of the comment node, remove that closing sigil from the end of
  what remains.
- On each other line of a block comment, when the line is the last line
  of the run and ends with the closing sigil of the block pair of the
  block comment, remove that closing sigil from the end of the line.
  Then, when what remains starts, after the spaces and tabs at the start
  of what remains, with an inner sigil, remove these spaces and tabs,
  and then remove the longest inner sigil that the rest starts with.
- On each other line of a line comment, remove the spaces and tabs at
  the start of the line. Then, when what remains starts with a line
  sigil, remove the longest line sigil that what remains starts with.

The margin of a sequence r of texts is the empty text when no text of r
has a character other than a space or a tab. Otherwise, it is the
longest text of only spaces and tabs with which each text of r that has
a character other than a space or a tab starts.

The bare lines of the comment node are each other line of a block
comment from which these rules remove no inner sigil, and each other
line of a comment with no sigil. Last, let m be the margin of the
sequence of the texts of the bare lines, in the order of the bare lines,
with each bare line as the rules of the list make that bare line. From
each bare line that starts with m as the rules of the list make that
bare line, remove m from the start of that bare line. From each other
bare line, remove the spaces and tabs at the start of that bare line.

### 4.13 Tag texts

@term tag-text=v1
@cites {
    ontology#{parameter=v1},
    text#{text=v1, line=v1, line-feed=v1, run=v1},
    #{
        read-file=v1, unreadable-file=v1, markdown-section=v1,
        markdown-list-item=v1, paragraph-line=v1, comment-run=v1,
        comment-line=v1, file-readers=v1,
    },
}

Under a valid binding of `file-readers`, the tag texts of a read file of
a tree that can be read are these texts, and the file has no other tag
text:

- for a markdown file: one for each first paragraph of a section and
  each first paragraph of a list item. That tag text joins the lines of
  that paragraph.
- for a code file: one for each run of comments that has a tagged
  comment node. That tag text joins the comment lines of the tagged
  comment nodes of that run of comments, with the comment lines of each
  comment node in their order and the comment nodes in their order in
  the run of comments.

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
that citation. That run is the run that `cites-single`,
`verifies-single`, `fixed-single`, or `supersedes-single` matches for
that citation entry. When a part of a scoped list stands for the
citation entry, the run of the citation entry is instead the run that
`cites-part`, `verifies-part`, or `fixed-part` matches for that part. A
link of a markdown document is the run of that document from the
character at which CommonMark 0.31.2 starts the link, `[` or `<`, to the
last character of the link.

The origin of a run r of one of these texts is the set of the places
that the characters of r come from. Examples of such runs are a line of
a tag text, the text of a tag line, a citation entry, a link, and the
first line of a paragraph, which is a run of the text of the file. When
the origin of r is not empty, the run of r in the text of the file
starts at the boundary right before the first place of the origin of r,
and that run ends at the boundary right after the last place of the
origin of r. For the text of a tag line, that run starts instead at the
boundary right before the place that the `@` of that tag line comes
from.

### 4.15 Origin positions

@term origin-position=v1
@cites {
    identifiers#{tag-line=v1, tag-word=v1, tag-line-text=v1},
    text#{position=v1, place=v1, text=v1},
    #{origin=v1, read-file=v1, tag-text=v1},
}

For a run r of the text of a read file, of a tag text, of the text of a
tag line, or of a markdown document of a tag text or of a markdown text,
when the origin of r is not empty, the origin position of r is the
position of the first place of the origin of r in the text of the file.
The origin position of the text of a tag line is instead the position of
the place that its `@` comes from.

### 4.16 File lines

@term file-line=v1
@cites {
    text#{text=v1, run=v1, boundary=v1, place=v1, line=v1},
    #{
        read-file=v1, unreadable-file=v1, markdown-line=v1, tag-text=v1,
        origin=v1,
    },
}

The file lines of a read file that can be read are runs of the text of
that file. For a markdown file that can be read, its file lines are its
markdown lines. For a code file that can be read, its file lines are the
lines that its tag texts join. The file lines are in the order of the
boundaries where those file lines start. Two file lines that start at
one boundary are in the order of the boundaries where those two file
lines end.

The file lines of a thing of the file are these:

- of a file line: that file line;
- of a line l of a tag text of a code file: the line that l comes from;
- of a line l of a tag text of a markdown file: the markdown line that
  starts at or before the boundary where the line that l comes from
  starts, and that ends at or after the boundary where the line that l
  comes from ends;
- of the text of a tag line of a tag text: the file lines of the lines
  of the tag text that the tag line and its continuation lines are;
- of each other run r of a tag text, of the text of a tag line, or of a
  markdown document of a tag text or a markdown text: the file lines
  that have a place of the origin of r.

A thing is in a set of file lines when each of its file lines is a line
of that set. It is outside a set of file lines when none of its file
lines is a line of that set.

### 4.17 Inputs and accepted inputs

@term accepted-input=v1
@cites {
    identifiers#{
        input=v1, external-namespaces=v1, link=v1, continuation-line=v1,
        citation=v1, validate-bindings=v1, give-line-results=v1,
        give-link-results=v1, line-result=v1, link-result=v1,
    },
    conformance#{conforming-program=v1},
    text#{result=v1, line=v1},
    ontology#{tree=v1, parameter=v1},
    #{
        read-file=v1, unreadable-file=v1, tag-text=v1, front-matter=v1,
        file-readers=v1,
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
  together with the continuation lines of that line when that line is a
  citation;
- each link of the markdown document of the markdown text of each of
  these markdown files;
- each link of the markdown document of each tag text of each of these
  code files.

The result of an input of the tree is the result that such a program
gives for that input. An accepted input of the tree is an input of the
tree whose result is "valid". The file of an input of the tree is the
read file of the tag text or of the markdown text in which that input
is.

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
    #{tag-text=v1},
}

A block of a tag text starts at each tag line of the tag text that
either is the first line of the tag text or comes right after a line
that is neither a tag line nor a continuation line. Let H be the line at
which the block starts, together with each line right after that line,
one after another, that is a tag line or a continuation line. The
trailing prose of the block is each line right after the last line of H,
one after another, that is not a tag line. The lines of the block are
the lines of H and then the lines of the trailing prose of the block.
The lines of a block are in their order in the tag text. The first line
of a block is the line at which the block starts. The last line of a
block is the last of its lines in that order.

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
2. No code character is at a place before the boundary where R starts on
   the line of the text whose line number is the first line number of R.
3. Each code character at a place after the boundary where R ends and
   before the boundary where the run of T starts is at a place of the
   run of a decoration node. Each line L of the text whose line number
   is greater than the last line number of R and less than the first
   line number of T has a code character at a place of the run of a
   decoration node, or has in L a line of the run of a comment node.

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

A markdown file has no test. A read file that cannot be read has no
test. For a code file that can be read, each test node of the reading of
its text with its pack is the code of one test of the file, and the file
has no other test. The name of that test is the name path of its test
node. The code of that test is the run of its test node. A comment on
that test is a run of comments of the file that attaches to an
attachment target whose run is the run of the test node of that test.

### 4.22 The files of declared items

@term item-file=v1
@cites {
    identifiers#{declaration=v1},
    ontology#{
        declared-item=v1, tree=v1, object-withdrawal=v1, object=v1,
        object-kind=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    #{read-file=v1, tag-text=v1, accepted-input=v1},
}

In a tree, each accepted input that is a declaration declares one text
declared item of the tree, and the tree has no other text declared item.
That accepted input is the declaration of that text declared item. The
file of that text declared item is the read file whose tag text has that
declaration.

When the object store of the tree (`object-store#tree-object-store`) is
valid, each declared-item object in a valid object file of `.sinter/` of
the tree that is neither withdrawn nor replaced in that tree
(`ontology#object-withdrawal`) is one stored declared item of the tree,
and the tree has no other stored declared item. The file of that stored
declared item is that valid object file.

The declared items of a tree are its text declared items together with
its stored declared items, and the tree has no other declared item.

### 4.23 Claims

@term claim=v1
@cites {
    ontology#{declared-item=v1},
    text#{line=v1},
    #{
        item-file=v1, tag-text=v1, file-line=v1, markdown-line=v1,
        markdown-section=v1, markdown-list-item=v1,
        tag-text-block=v1, blank-line=v1,
    },
}

The claim of a text declared item d of a tree is a set of file lines of
the file of d. In this term, the declarations of a tag text are the
lines of that tag text that are the declarations of text declared items,
in their order in that tag text. In this term, the line of a declaration
is the file line of that declaration. These rules give the claim of d:

1. When the file of d is a markdown file: the declaration of d is in the
   tag text of the first paragraph of a section or of a list item S.
   When the declaration of d is the first declaration of that tag text,
   the claim starts at the first line of S. Otherwise, the claim starts
   at the line of the declaration of d. When there is a next declaration
   of that tag text after the declaration of d, the claim ends at the
   markdown line right before the line of that next declaration.
   Otherwise, the claim ends at the last line of S. The claim is the
   markdown lines from the line at which the claim starts to the line at
   which the claim ends.
2. When the file of d is a code file: the declaration of d is a line of
   a block B of a tag text. When the declaration of d is the first
   declaration in B, the claim starts at the first line of B. Otherwise,
   the claim starts at the line that is the declaration of d. When there
   is a next declaration in B after the declaration of d, the claim ends
   at the line of B right before that next declaration. Otherwise, the
   claim ends at the last line of B. The claim is the file lines of the
   lines of B from the line at which the claim starts to the line at
   which the claim ends.

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

The scope of a text declared item d of the kind `design` or of the kind
`spec` of a tree is a set of file lines of the file of d:

- When the file of d is a markdown file, and S is the section or the
  list item whose first paragraph gives the tag text that has the
  declaration of d, the scope of d is the markdown lines of S.
- When the file of d is a code file and d is of the kind `design`, the
  scope of d is the lines of the claim of d.
- When its file is a code file, d is of the kind `spec`, and R is the
  run of comments whose tag text has the declaration of d: when R
  attaches to an attachment target T, the lines that the tag text of R
  joins, with each file line whose run starts at or after the boundary
  where the run of T starts and ends at or before the boundary where the
  run of T ends; when R is unattached and no code character of the file
  is at a place before the boundary where R starts, each file line of
  the file; otherwise, the lines that the tag text of R joins.

A thing is in the scope of d when that thing is in this set of file
lines.

### 4.25 Innermost items

@term innermost-item=v1
@cites {
    ontology#{declared-item=v1},
    #{file-line=v1, item-scope=v1},
}

Take a thing and some text declared items, each with a set of file lines
in which the thing is. When exactly one of these declared items has a
set that is a subset of the set of each of the other declared items,
that declared item is the innermost of these declared items by these
sets. Otherwise, none of these declared items is the innermost. The
innermost item of the kind `design`, or of the kind `spec`, in whose
scope a thing is, is the innermost, by their scopes, of the text
declared items of that kind in whose scopes the thing is.

### 4.26 The designs of slugs

@term slug-design=v1
@cites {
    identifiers#{slug=v1},
    ontology#{item-name=v1, declared-item=v1, decision-record=v1},
    #{item-file=v1},
}

In a tree, the design of a slug is the declared item of the kind
`design` of the tree (in either the text encoding or the `.sinter/`
encoding) whose name is that slug, when no other declared item of the
tree that is of the kind `design` or of the kind `decision` has that
slug as its name. Otherwise, the slug has no design.

### 4.27 Home designs

@term home-design=v1
@cites {
    identifiers#{
        tag-line=v1, inline-citation=v1, full-name=v1, slug=v1,
        target=v1,
    },
    ontology#{item-name=v1, declared-item=v1, schema=v1, atom=v1, term=v1},
    #{
        accepted-input=v1, item-file=v1, claim=v1,
        item-scope=v1, file-line=v1, innermost-item=v1,
        slug-design=v1, read-file=v1, tag-text=v1,
    },
}

The home design of a tag line of a tag text, or of an inline citation,
of a tree is the first of these that applies:

1. When the text declared items of the kind `design` in whose scopes the
   tag line or the inline citation is have an innermost item, the home
   design is that innermost item.
2. The home design is D when each of these conditions is true:
   - the tag line or the inline citation is in a code file;
   - the text declared items of the kinds `req`, `schema`, `atom`, and
     `term` in whose claims the tag line or the inline citation is have
     an innermost item by their claims;
   - the name in the target of the declaration of that innermost item is
     a full name;
   - the slug of that full name has a design, and that design is D.
3. The home design is D when each of these conditions is true:
   - the text declared items of the kind `spec` in whose scopes the tag
     line or the inline citation is have an innermost item;
   - the name in the target of the declaration of that innermost item is
     a full name;
   - the slug of that full name has a design, and that design is D.
4. Otherwise, the tag line or the inline citation has no home design.

### 4.28 Text containment and design containment

@term text-containment=v1
@cites {
    identifiers#{target=v1, full-name=v1, slug=v1, segment=v1},
    ontology#{
        containment=v1, item-name=v1, declared-item=v1, schema=v1,
        atom=v1, term=v1,
    },
    #{
        item-file=v1, home-design=v1, item-scope=v1,
        innermost-item=v1, slug-design=v1,
    },
}

In a tree, design containment (across both encodings) and text
specification containment hold only in these ways:

- A declared item d of one of the kinds `spec`, `req`, `schema`, `atom`,
  and `term` belongs to an item of the kind `design` in this way. When d
  is a stored declared item whose member `name` is a full name and the
  slug of that full name has a design, d belongs to the design of that
  slug. When d is a text declared item whose target name is a full name
  and the slug of that full name has a design, d belongs to the design
  of that slug. When d is a text declared item whose target name is a
  segment and the declaration of d has a home design, d belongs to that
  home design. Otherwise, d belongs to no item of the kind `design`.
- Take a text declared item d of one of the kinds `req`, `schema`,
  `atom`, and `term`. When the text declared items of the kind `spec` in
  whose scopes the declaration of d is have an innermost item S, and
  either d and S belong to the same item of the kind `design` or both d
  and S belong to no item of the kind `design`, d also belongs to S by
  text containment.

### 4.29 Extents

@term extent=v1
@cites {
    ontology#{containment=v1, declared-item=v1},
    #{item-file=v1, claim=v1, file-line=v1, text-containment=v1},
}

The extent of a text declared item d of a tree is the set of these file
lines of the file of d:

- each line of the claim of d that is not a line of the claim of a text
  declared item e, other than d, whose claim is a subset of the claim of
  d and that does not belong to d under `text-containment`;
- each line of the extent of each text declared item that belongs to d
  under `text-containment` and whose file is the file of d.

The lines of an extent are in the order of the file lines.

### 4.30 Hashed lines

@term hashed-line=v1
@cites {
    ontology#{declared-item=v1, containment=v1, tree=v1},
    #{extent=v1, text-containment=v1, file-line=v1},
}

When a text declared item d of a tree is of the kind `design` or of the
kind `spec`, the hashed lines of d are the lines of the extent of d
without the lines of the extent of each text declared item that belongs
to d under `text-containment`. When a text declared item d of a tree is
of another kind (`req`, `schema`, `atom`, `term`, or `decision`), the
hashed lines of d are the lines of the extent of d.

### 4.31 Section numbers

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

### 4.32 Code hashes

@term code-hash=v1
@cites {
    data-forms#{hash=v1},
    packs#{
        definition-node=v1, test-node=v1, node-run=v1, comment-node=v1,
    },
    text#{
        text=v1, run=v1, boundary=v1, space=v1, tab=v1, line-feed=v1,
        utf-8-encoding=v1, algorithm=v1, sequence=v1, line=v1,
        character=v1,
    },
    #{
        read-file=v1, run-line=v1, attachment=v1, comment-run=v1,
        comment-line=v1,
    },
}

When a line of the text of a code file starts at the boundary where a
run r of that text starts, the measured lines of r are the lines of the
run r that have a character other than a space or a tab. When no line of
the text starts at that boundary, the measured lines of r are the lines
of the run r, without the first line of r, that have a character other
than a space or a tab.

The code text of an attachment target *a* is the text that these steps
give.

1. Let *r* be the run of *a*.
2. If *a* is a definition node, set *r* to the run of the text of the
   file of *a* from the least boundary where the run of a body node of
   *a* starts to the greatest boundary where the run of a body node of
   *a* ends.
3. Let *l* be the line of the text of the file of *a* that starts at or
   before the boundary where *r* starts and that ends at or after that
   boundary.
4. If each character of the run of the text of the file of *a* from the
   boundary where *l* starts to the boundary where *r* starts is a space
   or a tab, set *r* to the run of the text of the file of *a* from the
   boundary where *l* starts to the boundary where *r* ends.
5. Let *shared* be the margin of the sequence of the texts of the
   measured lines of *r*, in their order.
6. Let *c* be the empty text.
7. For each *x* of the lines of the run *r*, in order:
   1. Let *t* be the text of *x* without the spaces and tabs at its end.
   2. If *x* is a measured line of *r*, remove the first characters of
      *t*, as many as *shared* has, from *t*.
   3. Append *t* to *c*.
   4. Append a line feed to *c*.
8. Give *c*.

A run of comments that has a tagged comment node and that attaches to
an attachment target has a code hash: the hash of the UTF-8 encoding of
the code text of that attachment target. Each other run of comments has
no code hash.

### 4.33 Sets of names

@term name-set=v1
@cites {
    identifiers#{slug=v1},
    ontology#{
        item-name=v1, declared-item=v1, schema=v1, atom=v1, term=v1,
        decision-record=v1,
    },
    #{item-file=v1, text-containment=v1},
}

The sets of names of a tree span both encodings and are these:

- the shared set, which has:
  - each declared item of the kind `design` of the tree;
  - each declared item of the kind `decision` of the tree;
  - each declared item of the tree of one of the kinds `spec`, `req`,
    `schema`, `atom`, and `term`, that belongs to no item of the kind
    `design`, and whose name is a slug;
- for each declared item of the kind `design` D of the tree, the set of
  D: the declared items of the kinds `spec`, `req`, `schema`, `atom`,
  and `term` that belong to D.

### 4.34 What kind words state

@term stated-kind=v1
@cites {
    identifiers#{kind-word=v1},
    ontology#{
        declared-item=v1, schema=v1, atom=v1, term=v1,
        decision-record=v1, external-item=v1,
        conformance-vector-group=v1, vector-set=v1,
    },
}

A written kind word states these kinds of item:

- `design` states an item of the kind `design`.
- `spec` states an item of the kind `spec` or an external item.
- `req` states an item of the kind `req`.
- `schema` states an item of the kind `schema`.
- `atom` states an item of the kind `atom`.
- `term` states an item of the kind `term` or an external item.
- `decision` states an item of the kind `decision`.

No kind word states a group of conformance vectors, a vector set, or an
object of another kind.

### 4.35 Vector files

@term vector-file=v1
@cites {
    files#{path=v1, path-set-membership=v1},
    data-forms#{test-vector-file-name=v1, test-vector-set=v1},
    ontology#{item-name=v1, vector-set=v1, declared-item=v1, parameter=v1},
    text#{text=v1, code-span=v1, whole-number=v1},
    #{vector-paths=v1, item-file=v1, text-containment=v1},
}

This term is for a tree and a valid binding of `vector-paths`. The
candidate vector files of the tree are the files of the tree whose valid
path is in the set of that binding of `vector-paths` and does not have
two or more file names with file name 1 equal to `.sinter` (so
`vector-paths` never includes files inside `.sinter/`, neither store
files nor files inside `.sinter/local/`).

For a declared item of the kind `design` D of the tree (in either
encoding), the test-vector file name of D is the test-vector file name
of the name of D alone (`data-forms#test-vector-file-name`). For a
declared item of the kind `spec` S of the tree (in either encoding) that
belongs to an item of the kind `design` D, the test-vector file name of
S is the test-vector file name of the name of D and the part name of the
name of S. A specification that belongs to no item of the kind `design`
has no test-vector file name.

A candidate vector file F matches a declared item x that has a
test-vector file name fn when the valid path of F equals fn or ends with
`/` followed by fn. When exactly one candidate vector file F matches x,
and F matches no other declared item of the tree, the vector file of x
is F. When x has a vector file and the content of that vector file is a
test-vector set, the vector set of x in the tree is that content.
Otherwise, x has no vector file and no vector set.

### 4.36 Kept object set

@term kept-object-set=v1
@cites {
    conformance#{input=v1},
    ontology#{
        object=v1, object-kind=v1, content-id=v1, log-branch=v1,
        declared-item=v1, computed-identity=v1,
    },
    text#{code-span=v1},
}

`kept-object-set` is a caller input holding a set of canonical objects from
the log branch: kept declared-item objects (the seven declared-item
kinds) and kept computed identity objects (the five computed identity
kinds), each conforming to its row of `ontology#object-kind` without
`seq` or `by`, and deduplicated by content id. When a caller supplies no
kept objects, `kept-object-set` is the empty set.

### 4.37 Parts of declared items

@term item-part=v1
@cites {
    ontology#{edge-source=v1, declared-item=v1, test=v1, tree=v1},
    #{
        extent=v1, file-line=v1, file-test=v1, comment-run=v1,
        tag-text=v1, markdown-line=v1,
    },
}

In a tree, a markdown line, a line of a tag text, the text of a tag line
with its continuation lines, or an inline citation is a part of a text
declared item d when, and only when, it is in the extent of d. A comment
on a test has such a thing when, and only when, each file line of the
thing is a line that the tag text of that comment joins. A line of a tag
text stands in an item, or in none, by the same rule as a line of a file
of a tree.

### 4.38 Sites

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

In this term, a line of an extent is a line of the extent of a text
declared item of the tree. In this term, a thing is outside every extent
when that thing is outside the extent of each text declared item of the
tree. The sites of a read file of a tree are these sets of file lines of
the file:

- In a markdown file: take each citation of a tag text of the file, each
  `@ack` line of a tag text of the file, and each inline citation of the
  markdown document of the markdown text of the file, when that
  citation, `@ack` line, or inline citation is outside every extent. For
  each of them, X, the site lines of X are the markdown lines that are
  not lines of an extent and that are from a first line to a last line.
  When there is a heading that opens a section and whose line is the
  first file line of X or comes before the first file line of X, the
  first line is the line of the last such heading. When there is no such
  heading, the first line is the first markdown line of the markdown
  text. The last line is the markdown line right before the line of the
  next heading that opens a section, or the last markdown line of the
  markdown text when no such heading is. Two such sets of site lines are
  linked when a line of the text of the file has a place of a markdown
  line of each of them. For each largest group of such sets of site
  lines in which each two are linked, directly or through others of the
  group, the set of the markdown lines of its sets is a site.
- In a code file: take each run of comments that is not a comment on a
  test and whose tag text has a thing that is outside every extent and
  that is a citation, an `@ack` line, or an inline citation of the
  markdown document of that tag text. The site lines of such a run of
  comments are the lines that its tag text joins and that are not lines
  of an extent. Two such runs of comments are linked when a line of the
  text of the file has a place of the run of a comment node of each of
  them. For each largest group of such runs of comments in which each
  two are linked, directly or through others of the group, the set of
  the site lines of its runs of comments is a site.

A site has a markdown line, a line of a tag text, a citation, an `@ack`
line, or an inline citation when, and only when, it is in that site.

### 4.39 The written text of inline elements

@term written-inline=v1
@cites {
    commonmark/0.31.2,
    identifiers#{
        link=v1, destination=v1, inline-citation=v1, link-text=v1,
        plain-string-content=v1, input=v1, external-namespaces=v1,
        give-link-results=v1, link-result=v1, target=v1,
    },
    conformance#{conforming-program=v1},
    text#{
        text=v1, character=v1, space=v1, tab=v1, line-feed=v1,
        code-span=v1, result=v1, algorithm=v1, sequence=v1,
    },
    ontology#{declared-item=v1, parameter=v1, content-id=v1},
    #{
        file-readers=v1, markdown-line=v1, accepted-input=v1, item-file=v1,
    },
}

This term is for a tree, a valid binding of `file-readers`, a binding of
`external-namespaces` as in `accepted-input`, and a mapping *m* that
gives a canonical target content id for each valid inline citation. The
inline elements are those of CommonMark 0.31.2: textual content, code
spans, emphasis, strong emphasis, links, images, raw HTML, hard line
breaks, and soft line breaks, where a link is a link as the term `link`
gives it. An inline citation is valid when a conforming program of the
design Identifiers, under that binding of `external-namespaces`, gives
the result "valid" for an inline citation with the same destination and
the same plain string content of its link text.

The text of textual content is its characters, with each backslash
escape, entity reference, and numeric character reference replaced by
the characters that CommonMark 0.31.2 gives for it. The content of a
code span of CommonMark 0.31.2 is its content as CommonMark 0.31.2 gives
it. The destination of an image is the destination that the term
`destination` gives for an inline link with the same link destination.
The written destination of an inline link, a reference link, or an image
is its destination. The written destination of a URI autolink is the
text of that autolink between `<` and `>`. The written destination of an
email autolink is `mailto:`, then the text of that autolink between `<`
and `>`. The title of a link or of an image that has a link title is
that link title as CommonMark 0.31.2 gives it, without the characters
that enclose it and with each backslash escape, entity reference, and
numeric character reference replaced by the characters that CommonMark
0.31.2 gives for it, and then with each markdown line ending of that
text replaced by a line feed. Another link or image, and each autolink,
has no title. The raw text of raw HTML is its characters, with each
markdown line ending of them replaced by a line feed.

The inline elements of emphasis and of strong emphasis are the inline
elements that they hold. The inline elements of an inline link or a
reference link are the inline elements between the `[` that starts that
link and the `]` that closes that `[`, in their order. The inline
elements of an image are the inline elements of the description of that
image, in their order.

The escaped text of a text *t* is the text that these steps give.

1. Let *u* be the empty text.
2. For each *c* of *t*, in order:
   1. If *c* is a line feed, append `\n` to *u*.
   2. Otherwise:
      1. If *c* is `\`, `{`, or `}`, append `\` to *u*.
      2. Append *c* to *u*.
3. Give *u*.

The single-spaced text of a text *t* is the text that these steps give.

1. Let *u* be the empty text.
2. For each *c* of *t*, in order:
   1. If *c* is a space or a tab, then:
      1. If *u* is empty or the last character of *u* is not a space,
         append a space to *u*.
   2. Otherwise, append *c* to *u*.
3. Give *u*.

The written text of a sequence *s* of inline elements for a text
declared item *d* under target mapping *m* is the text that these steps
give.

1. Let *w* be the empty text.
2. Let *run* be the empty text.
3. For each *x* of *s*, in order:
   1. If *x* is textual content, append the text of *x* to *run*.
   2. If *x* is a soft line break, append a space to *run*.
   3. If *x* is neither textual content nor a soft line break, then:
      1. Append the escaped text of the single-spaced text of *run* to
         *w*.
      2. Set *run* to the empty text.
   4. If *x* is a code span of CommonMark 0.31.2, then:
      1. Append `{code:` to *w*.
      2. Append the escaped text of the content of *x* to *w*.
      3. Append `}` to *w*.
   5. If *x* is emphasis, then:
      1. Append `{em:` to *w*.
      2. Append the written text of the inline elements of *x* for *d*
         under *m* to *w*.
      3. Append `}` to *w*.
   6. If *x* is strong emphasis, then:
      1. Append `{strong:` to *w*.
      2. Append the written text of the inline elements of *x* for *d*
         under *m* to *w*.
      3. Append `}` to *w*.
   7. If *x* is a link or an image, then:
      1. Let *to* be the written destination of *x*.
      2. If *x* is a valid inline citation, set *to* to `sinter:`
         followed by the canonical target content id that *m* gives for
         *x*.
      3. If *x* is a link, append `{link{` to *w*.
      4. Otherwise, append `{image{` to *w*.
      5. If *x* is an autolink, then:
         1. Let *shown* be the text of *x* between `<` and `>`.
         2. If *x* is a valid inline citation, set *shown* to *to*.
         3. Append the escaped text of *shown* to *w*.
      6. Otherwise, append the written text of the inline elements of
         *x* for *d* under *m* to *w*.
      7. Append `}{` to *w*.
      8. Append the escaped text of *to* to *w*.
      9. If *x* has a title, then:
         1. Append `}{` to *w*.
         2. Append the escaped text of the title of *x* to *w*.
      10. Append `}}` to *w*.
   8. If *x* is raw HTML, then:
      1. Append `{html:` to *w*.
      2. Append the escaped text of the raw text of *x* to *w*.
      3. Append `}` to *w*.
   9. If *x* is a hard line break, append `{br}` to *w*.
4. Append the escaped text of the single-spaced text of *run* to *w*.
5. Give *w*.

### 4.40 Written lines

@term written-line=v1
@cites {
    commonmark/0.31.2,
    identifiers#{
        tag-line=v1, tag-word=v1, sinter-tag-word=v1, declaration=v1,
        citation=v1, continuation-line=v1, tag-line-text=v1,
        inline-description=v1, target=v1, directive=v1,
        status-tag=v1, link=v1, link-text=v1,
    },
    ontology#{declared-item=v1, parameter=v1},
    text#{
        text=v1, character=v1, run=v1, space=v1, tab=v1, line-feed=v1,
        code-span=v1, decimal-numeral=v1, whole-number=v1, algorithm=v1,
        sequence=v1,
    },
    #{
        file-readers=v1, written-inline=v1, read-file=v1,
        unreadable-file=v1, markdown-line=v1, front-matter=v1,
        markdown-section=v1, markdown-list-item=v1, tag-text=v1,
        file-line=v1, accepted-input=v1, item-file=v1, section-number=v1,
        paragraph-line=v1, comment-line=v1, hashed-line=v1,
    },
}

This term is for a tree, a valid binding of `file-readers`, a binding of
`external-namespaces` as in `accepted-input`, and a target mapping *m*
as in `written-inline`. A block in this term is a block of CommonMark
0.31.2 of a markdown document: of the markdown document of a markdown
file that can be read, as the term `markdown-section` gives these
blocks, or of a markdown document that the steps of this term parse. A
blank line is no block, and a link reference definition is a block. A
heading of a markdown document that the steps of this term parse opens
no section.

When the file of a text declared item d is a markdown file and a heading
that opens a section has a line that comes before the file line of the
declaration of d, the base level of d is the level of the last such
heading. Otherwise, the base level of d is 0. The own heading of a text
declared item d is the heading that opens a section whose first
paragraph gives the tag text that has the declaration of d.

The children of a block quote or of a list item are the blocks that it
contains and that no other block inside it contains, in their order. The
children of a list are its list items, in their order. The start number
of an ordered list is the start number that CommonMark 0.31.2 gives it.
The info string of a fenced code block is the info string that
CommonMark 0.31.2 gives for that fenced code block, without the spaces
and tabs at the start and end of that info string, and with each
backslash escape, entity reference, and numeric character reference
replaced by the characters that CommonMark 0.31.2 gives for that escape
or reference. A code block has an info string only when it is a fenced
code block and this text is not empty.

The content lines of a code block or of an HTML block are the markdown
lines of the content that CommonMark 0.31.2 gives the block, in their
order. CommonMark 0.31.2 gives each content line from one line of
CommonMark 0.31.2 that the block takes. That content line comes from the
markdown line from which that line of CommonMark 0.31.2 comes. A block
of the markdown document of a markdown file starts in a set of file
lines when the first markdown line that the block takes is in that set.
A content line of a block of the markdown document of a markdown file
comes from a set of file lines when the markdown line that the content
line comes from is in that set. Each block of another markdown document
starts in each set of file lines. Each content line of a block of
another markdown document comes from each set of file lines.

The content text of a line of a tag text of a markdown file is the text of
the characters of the file line of that line that CommonMark 0.31.2
gives to the content of the paragraph, in their order, without the
spaces and tabs at the start of the text of those characters. The prose
text of a line of a tag text of a code file is the text of the line.

A line of a tag text of a markdown file has a task marker when it comes
from the first line of the first paragraph of a list item, and the term
`paragraph-line` gives that first line as the part of its run after the
longest run at the start of that run whose text matches `task-marker`.
The task marker of the line is then the text of that longest run without
the spaces and tabs at the end of that text. The written task marker of
the line is its task marker with each `X` replaced by `x`.

The indent of a whole number *k* is the text that these steps give.

1. If *k* is less than 1, give the empty text.
2. Let *j* be *k* minus 1.
3. Let *pad* be the indent of *j*.
4. Append a space to *pad*.
5. Append a space to *pad*.
6. Give *pad*.

The written lines of a block *b* at depth *k* for a text declared item
*d* in a set *e* of file lines under *m* is the sequence that these
steps give.

1. Let *lines* be the empty sequence.
2. Let *pad* be the indent of *k*.
3. If *b* is an ATX heading or a setext heading, *b* starts in *e*, and
   no text declared item of the tree has *b* as its own heading, then:
   1. Let *inlines* be the inline elements of *b*.
   2. If *b* is a heading that opens a section, then:
      1. Let *content* be the raw content of *b*.
      2. Remove the characters of the longest run at the start of
         *content* whose text, with each line feed of it replaced by a
         space, is a section number from *content*.
      3. Set *inlines* to the inline elements that CommonMark 0.31.2
         gives for a heading whose raw content is *content*, with the
         link reference definitions of the markdown document that holds
         *b*.
   3. Let *line* be *pad*.
   4. Append `heading ` to *line*.
   5. If the level of *b* is greater than the base level of *d*, then:
      1. Append `+` to *line*.
      2. Append the decimal numeral of the level of *b* minus the base
         level of *d* to *line*.
   6. If the level of *b* is the base level of *d*, append `0` to
      *line*.
   7. If the level of *b* is less than the base level of *d*, then:
      1. Append `-` to *line*.
      2. Append the decimal numeral of the base level of *d* minus the
         level of *b* to *line*.
   8. Append `: ` to *line*.
   9. Append the written text of *inlines* for *d* under *m* to *line*.
   10. Append *line* to *lines*.
4. If *b* is a paragraph that gives a tag text that holds a tag line,
   then:
   1. For each *w* of the written tag lines of the tag text that *b*
      gives at depth *k* for *d* in *e* under *m*, in order:
      1. Append *w* to *lines*.
5. If *b* is a paragraph that gives no tag text that holds a tag line,
   and *b* starts in *e*, then:
   1. Let *line* be *pad*.
   2. Append `paragraph: ` to *line*.
   3. Append the written text of the inline elements of *b* for *d*
      under *m* to *line*.
   4. Append *line* to *lines*.
6. If *b* is a code block and *b* starts in *e*, then:
   1. Let *line* be *pad*.
   2. Append `code` to *line*.
   3. If *b* has an info string, then:
      1. Append a space to *line*.
      2. Append the info string of *b* to *line*.
   4. Append `:` to *line*.
   5. Append *line* to *lines*.
   6. For each *c* of the content lines of *b*, in order:
      1. If *c* comes from *e*, then:
         1. Let *row* be *pad*.
         2. Append `| ` to *row*.
         3. Append the text of *c* to *row*.
         4. Append *row* to *lines*.
7. If *b* is an HTML block and *b* starts in *e*, then:
   1. Let *line* be *pad*.
   2. Append `html:` to *line*.
   3. Append *line* to *lines*.
   4. For each *c* of the content lines of *b*, in order:
      1. If *c* comes from *e*, then:
         1. Let *row* be *pad*.
         2. Append `| ` to *row*.
         3. Append the text of *c* to *row*.
         4. Append *row* to *lines*.
8. If *b* is a thematic break and *b* starts in *e*, then:
   1. Let *line* be *pad*.
   2. Append `break` to *line*.
   3. Append *line* to *lines*.
9. If *b* is a block quote, a list, or a list item, then:
   1. Let *inner* be the empty sequence.
   2. For each *child* of the children of *b*, in order:
      1. For each *w* of the written lines of *child* at depth *k* plus
         1 for *d* in *e* under *m*, in order:
         1. Append *w* to *inner*.
   3. If *inner* is not empty, then:
      1. Let *line* be *pad*.
      2. If *b* is a block quote, append `quote:` to *line*.
      3. If *b* is a bullet list, append `bullet list:` to *line*.
      4. If *b* is an ordered list, then:
         1. Append `ordered list from ` to *line*.
         2. Append the decimal numeral of the start number of *b* to
            *line*.
         3. Append `:` to *line*.
      5. If *b* is a list item, append `item:` to *line*.
      6. Append *line* to *lines*.
      7. For each *w* of *inner*, in order:
         1. Append *w* to *lines*.
10. Give *lines*.

A tag line of a tag text is accepted when the input of the tree that is
that line, together with its continuation lines, is an accepted input.

The clusters of a tag text t in a set e of file lines are sequences of
lines. Let L be the sequence of the lines of t that are in e and that
are neither `@ack` lines, accepted `@extern` lines, nor continuation
lines, in their order. L is cut right before each tag line of L that
comes right after a line of L that is not a tag line, and right before
each declaration of a text declared item when the lines of L from the
last cut before it, or from the first line of L when there is no such
cut, hold another declaration of a text declared item. The clusters of t
in e are the sequences of the lines of L from the first line of L or a
cut to the next cut or the last line of L, in their order.

The written tag lines of a tag text *t* at depth *k* for a text declared
item *d* in a set *e* of file lines under *m* is the sequence that these
steps give.

1. Let *lines* be the empty sequence.
2. For each *c* of the clusters of *t* in *e*, in order:
   1. Let *tags* be the empty sequence.
   2. Let *notes* be the empty sequence.
   3. Let *shared* be the empty text.
   4. If the file of *d* is a code file, set *shared* to the margin of
      the sequence of the texts of the lines of *c*, as lines of *t*, in
      their order.
   5. For each *l* of *c*, in order:
      1. If *l* is a tag line, then:
         1. Append *l* to *tags*.
         2. If *l* is accepted and is a declaration, a citation, or a
            status tag (not an `@extern` line), and the inline
            description of *l* is not empty, append the inline
            description of *l* to *notes*.
      2. Otherwise:
         1. Let *y* be the content text of *l*.
         2. If *y* starts with *shared*, remove the first characters of
            *y*, as many as *shared* has, from *y*.
         3. Otherwise, set *y* to the empty text.
         4. Append *y* to *notes*.
   6. For each *w* of the written cluster of *tags* and *notes* for *t*
      at depth *k*, *d*, and *e* under *m*, in order:
      1. Append *w* to *lines*.
3. Give *lines*.

The written cluster of a sequence *p* of tag lines and a sequence *r* of
texts for a tag text *t* at depth *k*, a text declared item *d*, and a
set *e* of file lines under *m* is the sequence that these steps give.

1. Let *lines* be the empty sequence.
2. Let *pad* be the indent of *k*.
3. For each *l* of *p*, in order:
   1. If *l* has a task marker and *l* is not the declaration of *d*,
      then:
      1. Let *line* be *pad*.
      2. Append `task: ` to *line*.
      3. Append the written task marker of *l* to *line*.
      4. Append *line* to *lines*.
4. For each *l* of *p*, in order:
   1. If *l* is not accepted, then:
      1. Let *flat* be the empty text.
      2. For each *c* of the text of the tag line *l*, in order:
         1. If *c* is a line feed, append a space to *flat*.
         2. Otherwise, append *c* to *flat*.
      3. Set *flat* to the single-spaced text of *flat*.
      4. Remove the spaces at the start and at the end of *flat* from
         *flat*.
      5. Let *line* be *pad*.
      6. Append `tag: ` to *line*.
      7. Append *flat* to *line*.
      8. Append *line* to *lines*.
5. For each *w* of the written prose of *r* after *p* for *t* at depth
   *k*, *d*, and *e* under *m*, in order:
   1. Append *w* to *lines*.
6. Give *lines*.

Accepted Sinter tag lines (declarations, citations, status tags,
`@extern`, and `@ack`) emit no `tag:` line in a written cluster.

The written prose of a sequence *r* of texts after a sequence *p* of tag
lines, for a tag text *t* at depth *k*, a text declared item *d*, and a
set *e* of file lines under *m*, is the sequence that these steps give.

1. Let *lines* be the empty sequence.
2. Let *raw* be the empty text.
3. Let *gap* be the empty text.
4. For each *note* of *r*, in order:
   1. Append *gap* to *raw*.
   2. Append *note* to *raw*.
   3. Set *gap* to a line feed.
5. If the file of *d* is a markdown file, then:
   1. Remove the spaces and tabs at the start and at the end of *raw*
      from *raw*.
   2. If *raw* is not empty, then:
      1. Let *line* be the indent of *k*.
      2. Append `paragraph: ` to *line*.
      3. Let *inner* be the inline elements that CommonMark 0.31.2 gives
         when it parses *raw* as inlines, as it parses the raw content of
         a paragraph, with the link reference definitions of the markdown
         document of the file of *d*.
      4. Append the written text of *inner* for *d* under *m* to *line*.
      5. Append *line* to *lines*.
6. If the file of *d* is a code file, then:
   1. Let *doc* be the empty text.
   2. If *p* is not empty, then:
      1. Append `x` to *doc*.
      2. Append a line feed to *doc*.
   3. Append *raw* to *doc*.
   4. For each *b* of the blocks of the markdown document of *doc* that
      no other block contains, as CommonMark 0.31.2 parses that document
      with the link reference definitions of the markdown document of *t*
      before its own, so that a link label takes the first of these
      definitions whose link label it matches, in order:
      1. If *p* is not empty and *b* takes the first line of *doc*, then:
         1. Let *rest* be the raw content of *b*.
         2. Remove the first character of *rest* from *rest*.
         3. Remove the line feeds, spaces, and tabs at the start and at
            the end of *rest* from *rest*.
         4. Let *inner* be the inline elements that CommonMark 0.31.2
            gives when it parses *rest* as inlines, as it parses the raw
            content of a paragraph, with the link reference definitions
            of the markdown document of *t* before those of the markdown
            document of *doc*.
         5. Let *line* be the indent of *k*.
         6. If *b* is a setext heading, then:
            1. Append `heading +` to *line*.
            2. Append the decimal numeral of the level of *b* minus the
               base level of *d* to *line*.
            3. Append `: ` to *line*.
            4. Append the written text of *inner* for *d* under *m* to
               *line*.
            5. Append *line* to *lines*.
         7. If *b* is a paragraph and *rest* is not empty, then:
            1. Append `paragraph: ` to *line*.
            2. Append the written text of *inner* for *d* under *m* to
               *line*.
            3. Append *line* to *lines*.
      2. Otherwise:
         1. For each *w* of the written lines of *b* at depth *k* for
            *d* in *e* under *m*, in order:
            1. Append *w* to *lines*.
7. Give *lines*.

The normalized text of a text declared item *d* under target mapping *m*
is the text that these steps give.

1. Let *e* be the hashed lines of *d*.
2. Let *lines* be the empty sequence.
3. If the file of *d* is a markdown file, then:
   1. Let *blocks* be the sequence of the blocks of the document itself
      of the markdown document of the file of *d* in their order, or,
      when the declaration of *d* is in the tag text of the first
      paragraph of a list item, the children of that list item in their
      order.
   2. For each *b* of *blocks*, in order:
      1. For each *w* of the written lines of *b* at depth 0 for *d* in
         *e* under *m*, in order:
         1. Append *w* to *lines*.
4. If the file of *d* is a code file, then:
   1. Let *texts* be the sequence of the tag texts of the file of *d* in
      the order of the boundaries where their first lines start.
   2. For each *t* of *texts*, in order:
      1. For each *w* of the written tag lines of *t* at depth 0 for *d*
         in *e* under *m*, in order:
         1. Append *w* to *lines*.
5. Let *out* be the empty text.
6. For each *w* of *lines*, in order:
   1. Append *w* to *out*.
   2. Append a line feed to *out*.
7. Give *out*.

### 4.41 Canonical objects of a tree

@term canonical-object=v1
@cites {
    conformance#{encoding=v1, input=v1, report-missing-parts=v1},
    data-forms#{
        line-object=v1, canonical-form=v1, canonical-byte-sequence=v1,
        vector-line=v1, form-pin=v1,
    },
    identifiers#{
        citation=v1, citation-entry=v1, inline-citation=v1,
        inline-destination=v1, status-tag=v1, content-id=v1,
        external-id=v1, vector-selection=v1, revision=v1, label=v1,
        external-namespaces=v1, validate-bindings=v1,
    },
    ontology#{
        tree=v1, encoding=v1, object=v1, object-kind=v1,
        content-hash=v1, content-id=v1, computed-identity=v1,
        object-withdrawal=v1, declared-item=v1, item-name=v1,
        revised-content=v1, item-revision=v1, edge=v1, pinned-edge=v1,
        edge-source=v1, vector-set=v1, conformance-vector-group=v1,
    },
    object-store#{
        tree-object-store=v1, valid-object-file=v1,
        needed-identity-file=v1,
    },
    text#{code-point-order=v1, code-span=v1, result=v1},
    #{
        file-readers=v1, vector-paths=v1, read-file=v1,
        accepted-input=v1, item-file=v1, text-containment=v1,
        extent=v1, hashed-line=v1, written-inline=v1, written-line=v1,
        vector-file=v1, kept-object-set=v1, item-part=v1, tree-site=v1,
        file-test=v1, home-design=v1, slug-design=v1,
    },
}

In the sense of `conformance#encoding` and `ontology#encoding`, the read
files of a tree (together with its candidate vector files) constitute
one input in the text encoding. That input is valid when the bindings of
`file-readers` and `external-namespaces` (and, for vector files and
`vector-group-def` objects, `vector-paths`) are valid. The canonical
objects of a tree come from that valid text encoding together with the
valid object store of the tree (`object-store#tree-object-store`), using
`kept-object-set` for earlier revisions.

**Known computed identity objects.** An input of the run supplies a
computed identity object (`name`, `pin`, `ext`, `vector-set`, or
`vector-group`, as `ontology#computed-identity` defines its canonical
line object) when:

- a valid object file of `.sinter/` of the tree holds that computed
  identity object;
- `kept-object-set` holds that computed identity object;
- a declared item of the tree (text or `.sinter/`) or a kept declared
  item holds its own `name` key, supplying `{"kind":"name","name":n,"v":1}`;
- a text citation entry, inline citation, or vector line in the tree
  writes that key (an expanded name for `name`, an exact pin `(n, l)`
  for `pin`, an external ref for `ext`, or a vector selection or vector
  set owner/group for `vector-set` or `vector-group`).

**Pin-cycle graph.** In the directed graph over the declared items of
the tree (`ontology#edge`), add an arrow:

- from each text `spec` to each text declared item that belongs to it
  under `text-containment`, and from each stored `spec` to each stored
  declared item named by one of its `items` edges;
- from each text declared item *u* to each declared item *v* of the tree
  whose name is *n* and whose label is *l*, whenever *u* holds an exact
  pin with expanded name *n* and label *l*, or holds a text citation
  written as a `pin:` content id whose `pin` object `(n, l)` an input
  of the run supplies;
- from each stored declared item *u* to each declared item *v* of the
  tree when a citation edge of *u* names *v*'s content id directly or
  names a `pin:` content id whose `pin` object `(v.name, v.label)` an
  input of the run supplies.

A pinned citation edge from declared item *u* targeting `(n, l)` lies on
a cycle of the tree's own objects when at least one declared item *v* of
the tree with name *n* and label *l* can reach *u* in that graph
(including `u = v`, a cycle of length 1).

**Canonical target of a citation or vector-line edge.** For a citation
entry or inline citation with home design *h* (or empty when none)
standing in source *s* (where *u* is the declared item when *s* is a
declared item, and none otherwise):

1. **Exact pin `(n, l)`** (where *n* is the entry name, prefixed by the
   name of *h* when the entry name starts with `#` and *h* is present;
   and *l* is the label; also for a text citation written by a `pin:`
   content id whose `pin` object `(n, l)` an input of the run supplies):
   - When *u* is a declared item and `(n, l)` lies on a cycle of the
     tree's own objects, the canonical target is the content id of
     `{"kind":"pin","label":l,"name":n,"v":1}` (`pin-cycle`).
   - Otherwise, check these three sets in order:
     1. the distinct canonical objects of the declared items of the tree
        whose name is *n* and whose label is *l* (if any such declared
        item lacks its own canonical object because of a missing part,
        this pin is also a missing part);
     2. when the first set is empty, the distinct canonical objects of
        the replaced, unwithdrawn declared-item objects in valid object
        files of `.sinter/` of the tree (`ontology#object-withdrawal`)
        whose name is *n* and whose label is *l*;
     3. when the first two sets are empty, the distinct canonical
        objects of the unwithdrawn declared-item objects in
        `kept-object-set` whose name is *n* and whose label is *l*.
     In the first non-empty set among those three: when it holds exactly
     one canonical object, the canonical target is that object's content
     id; when it holds two or more distinct canonical objects, the pin
     is ambiguous (`ambiguous-pin`) and its canonical target is the
     content id of `{"kind":"pin","label":l,"name":n,"v":1}`.
   - When all three sets are empty: if no declared item of the tree has
     name *n* (including `#part-name` with no home design), the
     canonical target is the content id of
     `{"kind":"pin","label":l,"name":n,"v":1}`; otherwise (a declared
     item of the tree has name *n*, such as at another label), the pin
     names no object and is a missing part (`conformance#input`).
2. **Unknown `pin:` content id in text** (no input of the run supplies a
   `pin` object with that content id): the canonical target is that
   `pin:` content id directly; it is not a missing part and resolves to
   no object.
3. **Unpinned citation (`=*`) or `name:` content id:** for `=*` with
   expanded name *n*, the canonical target is the content id of
   `{"kind":"name","name":n,"v":1}`; for a written `name:` content id,
   that content id directly.
4. **External target or `ext:` content id:** for an external target with
   `external-ref` *r* (dropping any written kind word), the canonical
   target is the content id of `{"external-ref":r,"kind":"ext","v":1}`;
   for a written `ext:` content id, that content id directly.
5. **Vector selection or `vector-set:` / `vector-group:` content id:**
   for a vector selection `[*]` on expanded name *owner*, the content id
   of `{"kind":"vector-set","owner":owner,"v":1}`; for `[g]`, the
   content id of `{"group":g,"kind":"vector-group","owner":owner,"v":1}`;
   for a written `vector-set:` or `vector-group:` content id, that
   content id directly.
6. **Non-identity content id** (any of the other twenty object kinds):
   the canonical target is that content id directly.

For a vector line of a vector set of a `design` D or of a `spec` S
belonging to D, with form pin `#part=label`, its canonical target is the
canonical target that rule 1 of this term gives for the exact pin
`(D.name + "#" + part, label)` with no declared-item source.

For a citation edge of a stored declared item in `.sinter/`, its
canonical target is the `to` content id that the stored object holds;
when `to` is a `pin:` content id and an input of the run supplies that
`pin` object `(n, l)`, the edge resolves in the tree under rule 1 (for
pin cycles, ambiguity, and missing parts), while keeping its stored
`pin:` content id. When a stored object's edge targets a computed
identity content id that no input of the run supplies, that computed
identity object is a missing part (`object-store#tree-object-store`),
and only the results that need its key are withheld.

**Canonical object of each declared item.**
- For a stored declared item, its canonical object is the canonical
  object of its valid object file in `.sinter/`.
- For a text declared item *d*, when no citation standing in *d*, no
  valid inline citation in *d*'s hashed lines, and (when *d* is a
  `spec`) no text declared item belonging to *d* under
  `text-containment` is a missing part, the canonical object of *d* is
  the line object holding:
  - `kind`: the short object kind word of *d* (`design`, `spec`,
    `schema`, `req`, `atom`, `term`, or `decision`);
  - `v`: the integer 1;
  - `name`: the name of *d*;
  - `label`: the label of *d* when its declaration carries a label
    (omitted for a `term` with no label);
  - `text`: the normalized text of *d* (`written-line`) under the target
    mapping *m* that maps each valid inline citation to its canonical
    target content id;
  - `status`: the set of the tag words without `@` of the accepted
    status tags standing in *d*, sorted in code point order of their
    canonical forms, omitted when empty;
  - `edges`: the set of `{"kind","to"}` flat objects, sorted in code
    point order of their canonical forms, holding `{"kind":"about","to":c}`
    where *c* is the content id of `{"kind":"name","name":d.name,"v":1}`,
    plus `{"kind":"items","to":h}` for the content id *h* of each text
    declared item belonging to *d* under `text-containment` when *d* is
    a `spec`, plus `{"kind":k,"to":t}` for each citation entry and each
    inline citation standing in *d* (with no `revises` edge).
  When any such pin or held item is a missing part, the canonical object
  (and content hash and content id) of *d* is withheld under
  `conformance#report-missing-parts`.

**Canonical object of each group description (`vector-group-def`).**
Under a valid binding of `vector-paths`, for each `design` or `spec` *x*
of the tree that has a vector set, and for each group *g* of that vector
set, when no vector line of *g* has a missing-part form pin, the group
description object (`vector-group-def`) of *g* is the line object
holding `kind` (`"vector-group-def"`), `v` (1), `owner` (the name of
*x*), `group` (*g*), and `edges` (sorted set holding `{"kind":"about","to":vg}`
where *vg* is the content id of `{"group":g,"kind":"vector-group","owner":x.name,"v":1}`,
plus `{"kind":"cites","to":t}` for the canonical target *t* of each
vector line of *g*). When any vector line of *g* has a missing-part form
pin, that `vector-group-def` object is withheld.

The content hash and content id of every canonical object follow
`ontology#content-hash` and `ontology#content-id`.

### 4.42 Containment in a tree

@term tree-containment=v1
@cites {
    ontology#{
        containment=v1, item-name=v1, declared-item=v1, schema=v1,
        atom=v1, term=v1, item-revision=v1,
    },
    #{item-file=v1, text-containment=v1, canonical-object=v1},
}

In a tree, a declared item belongs to a declared item only in these
ways:

- Every design containment relation and every text specification
  containment relation of `text-containment` holds.
- Take a declared item d (text or stored) of one of the kinds `req`,
  `schema`, `atom`, and `term` that belongs to no text specification and
  whose canonical object is the current declared-item object of its name
  in the tree (`ontology#item-revision`). When there is exactly one
  stored declared item S of the kind `spec` in the tree such that d and
  S belong to the same item of the kind `design` (or both belong to no
  item of the kind `design`) and S holds an `items` edge whose `to` is
  the content id of d, then d belongs to S.

### 4.43 What names name

@term named-item=v1
@cites {
    identifiers#{
        citation-entry=v1, inline-citation=v1, inline-destination=v1,
        destination=v1, name=v1, slug=v1, full-name=v1, part-name=v1,
        external-id=v1, external-target=v1, match=v1, input-match=v1,
    },
    ontology#{external-item=v1, item-name=v1},
    text#{text=v1},
    #{accepted-input=v1, name-set=v1, home-design=v1, slug-design=v1},
}

In a tree, for a home design h, which is an item of the kind `design` of
the tree, or the empty text for no home design, each of these texts
names one item or nothing: the entry name of a citation entry of an
accepted citation (when that citation entry does not match `content-id`),
and the text that `name` or `external-ref` matches in the match of the
destination of an inline citation, when that match is a match of an
input, whether or not that inline citation is an accepted input. The
home design h only gives the set in which rule 4 looks. The home design
h is no fact about the item that the text names. For h, such a text
names the item that the first of these rules that applies gives:

1. When the match of the citation entry, or of the destination, uses
   `external-ref`, the text is an external id, with its `#` and part
   name when that external id has them. When that match uses
   `external-ref`, the text names the external item that this external
   id names.
2. A slug names the item of the shared set whose name is that slug.
3. When the slug of a full name has a design, that full name names the
   item, in the set of that design, whose name is that full name. When
   the slug of a full name has no design, that full name names nothing.
4. `#` and a part name p name the item, in the set of h, whose name is
   the name of h, `#`, and p. When h is the empty text, they name
   nothing.

The entry name of a citation entry of an accepted citation names what
that entry name names for the home design of that citation, or for the
empty text when that citation has no home design. For an accepted inline
citation, the text that `name` or `external-ref` matches in the match of
the destination of that inline citation names what that text names for
the home design of that inline citation, or for the empty text when that
inline citation has no home design. When two or more items of the set in
which a rule looks for a name have that name, that name names none of
those items. When no item of the set in which a rule looks for a name
has that name, that name names nothing. Two names are the same name only
when they are the same text.

### 4.44 Selected items

@term selected-item=v1
@cites {
    identifiers#{citation-entry=v1, vector-selection=v1, match=v1},
    ontology#{conformance-vector-group=v1, vector-set=v1},
    text#{code-span=v1},
    #{accepted-input=v1, named-item=v1, vector-file=v1},
}

In a tree, when the match of a citation entry of an accepted citation
uses `vector-selection`, that citation entry names one item, or nothing.
When the entry name of that citation entry names an item of the kind
`spec` or of the kind `design` that has a vector set, the citation entry
names this item of that vector set, or nothing when the vector set has
none:

- when the match uses `group-name`: the group of conformance vectors
  whose name is the text that `group-name` matches;
- otherwise: the vector set.

When the entry name of the citation entry does not name an item of the
kind `spec` or of the kind `design` that has a vector set, the citation
entry names nothing.

### 4.45 The edges of a tree

@term tree-edge=v1
@cites {
    rfc/8259,
    identifiers#{
        citation=v1, citation-entry=v1, inline-citation=v1,
        inline-destination=v1, vector-selection=v1, full-name=v1,
        content-id=v1, external-id=v1, external-namespaces=v1, fit=v1,
        match=v1,
    },
    data-forms#{vector-line=v1, vector-object=v1, form-pin=v1},
    ontology#{
        edge=v1, edge-source=v1, tree=v1, declared-item=v1,
        containment=v1, item-name=v1, vector-set=v1,
        conformance-vector-group=v1, computed-identity=v1,
        object-withdrawal=v1, object=v1, object-kind=v1,
        external-item=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    text#{
        text=v1, line=v1, run=v1, boundary=v1, position=v1,
        code-span=v1,
    },
    #{
        accepted-input=v1, item-file=v1, named-item=v1,
        selected-item=v1, vector-paths=v1, vector-file=v1, kept-object-set=v1,
        canonical-object=v1, tree-containment=v1, item-part=v1,
        tree-site=v1, file-test=v1,
    },
}

The edges of a tree are the citation edges (`cites`, `satisfies`,
`verifies`, `refines`, and `supersedes`) from these four sources:

- each citation entry of each accepted citation in a read file;
- each accepted inline citation in a read file;
- each vector line of the vector set of each `design` or `spec` of the
  tree (under a valid binding of `vector-paths`);
- each edge of one of the five citation kinds in the member `edges` of
  each stored declared item in `.sinter/` of the tree.

Edges of structural, scope, and record kinds (`items`, `about`,
`revises`, and all edges of records and `scope` objects) are not edges
of a tree in this term and are ignored by citation findings. When a
citation or inline citation stands in a test or a site, it gives a claim
from code whose location (file and line) stays beside the edge, never
inside the edge (`ontology#edge`).

The file of a text citation edge is the read file of its accepted input;
the file of a vector-line edge is that vector file; the file of a stored
edge is the valid object file of its stored declared item.

For an edge whose canonical target *to* is neither a missing part nor an
ambiguous pin (`canonical-object`), its cited item in the tree is given
by these rules (or none when they give nothing):

- **Vector-line edge:** for a vector line of the vector set of a `spec`
  S belonging to a `design` D, or of a `design` D, let *n* be the full
  name made of the name of D, `#`, and the schema part name of the form
  of that vector line. When *n* names one declared item *x* in the tree
  and either the vector set is of S and S holds *x* (`tree-containment`),
  or the vector set is of D and D holds *x* directly, the cited item is
  *x*; otherwise none.
- **Target `pin:`:** when the edge is an unknown `pin:` content id in
  text, none; when an input of the run supplies the `pin` object `(n, l)`,
  the one declared item of the tree whose name is *n* (in its name set
  as `named-item` looks up *n*), or none when zero or two or more exist.
- **Target `name:`:** when an input of the run supplies the `name`
  object with member `name` *n*, the one declared item of the tree whose
  name is *n*, or none when zero or two or more exist (the presence of a
  `name` object never implies that a declared item of that name exists
  in the tree); when it is a text citation of an unknown `name:` content
  id (no declared item of the tree has that `name` id), none.
- **Target `ext:`:** when an input of the run supplies the `ext` object
  with member `external-ref` *r* and *r*'s namespace is in the binding
  of `external-namespaces` with its id fitting that namespace's id
  pattern (`identifiers#fit`), the external item named by *r*; otherwise
  none.
- **Target `vector-set:` or `vector-group:`:** when an input of the run
  supplies that computed identity object with `owner` (and `group`), the
  vector set or group of conformance vectors of the one declared item of
  the tree with name `owner` when that item is a `design` or `spec` with
  a vector set (and that group exists); otherwise none.
- **Target non-identity content id:** look first in the tree (current
  text declared items, valid unwithdrawn `.sinter/` objects of any kind,
  and `vector-group-def` objects of the tree), and otherwise in
  unwithdrawn objects of `kept-object-set`. If *to* is not a text declared
  item of the tree and a counting void in `.sinter/` withdraws *to*, the
  resolution of that edge is a missing part and its cited item is
  withheld. Otherwise, when *to* resolves to a declared-item object *O*,
  the cited item is the one declared item of the tree whose name is the
  member `name` of *O*, or none; when *to* resolves to any other object
  *O* (`task`, `plan`, `scope`, `vector-group-def`, or a record), the
  cited item is *O*; when *to* resolves to no object, none.

When a citation edge is an ambiguous pin or lacks its canonical target
or needed computed identity key as a missing part, its cited item is
withheld.

For an edge that a vector line of the vector set of an item gives, the
form run of that edge is the run of the text of the vector file of that
item, on the line of that vector line, that starts at the boundary right
after the opening `"` of the JSON string of the value of the member
`form` of the object of that vector line and ends at the boundary right
before the closing `"` of that JSON string. The form position of that
edge is the position of the boundary where the form run of that edge
starts in the text of that vector file.

### 4.46 Extern marks

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
input of a tree, and that stands in a text declared item of the kind
`design` D, states one extern mark of D. The kind word of the extern
mark is the text that `kind-word` matches in the match of that line by
`extern-line`. The part name of the extern mark is the text that
`part-name` matches in the match of that line by `extern-line`. An
`@extern` line that stands in no text item of the kind `design` states
no extern mark. A stored item of the kind `design` in `.sinter/` carries
no extern mark.

### 4.47 Valid extern marks

@term valid-extern-mark=v1
@cites {
    identifiers#{kind-word=v1, part-name=v1},
    ontology#{
        containment=v1, item-name=v1, schema=v1, atom=v1, term=v1,
        declared-item=v1,
    },
    text#{code-span=v1},
    #{extern-mark=v1, item-file=v1, tree-containment=v1},
}

The name of an extern mark of a text item of the kind `design` D is the
name of D, `#`, and the part name of the extern mark. That extern mark
is valid when, and only when, one of these is true for a text declared
item x (never a stored declared item in `.sinter/`):

- its kind word is `spec`, and D holds a text declared item x of the
  kind `spec` whose name is the name of the extern mark and whose file
  is not the file of D;
- its kind word is `req`, and D holds directly a text declared item x of
  the kind `req` whose name is the name of the extern mark and whose
  file is not the file of D;
- its kind word is `schema`, and D holds directly a text declared item x
  of the kind `schema` whose name is the name of the extern mark and
  whose file is not the file of D;
- its kind word is `atom`, and D holds directly a text declared item x
  of the kind `atom` whose name is the name of the extern mark and whose
  file is not the file of D;
- its kind word is `term`, and D holds directly a text declared item x
  of the kind `term` whose name is the name of the extern mark and whose
  file is not the file of D.

### 4.48 Position subjects

@term position-subject=v1
@cites {
    files#{path=v1},
    ontology#{declared-item=v1},
    text#{text=v1, position=v1, decimal-numeral=v1, code-span=v1},
    #{read-file=v1, vector-file=v1},
}

The position subject of a position, with the line number l and the
column c, in a read file or in the vector file of a declared item is the
text of the valid path of the file, then `@L`, then the decimal numeral
of l, then `C`, then the decimal numeral of c.

### 4.49 The order of positions

@term position-order=v1
@cites text#{position=v1, line-number=v1, whole-number=v1}

One position comes before another position when, and only when, its
line number is less than the line number of the other, or the two line
numbers are the same and its column is less than the column of the
other.

### 4.50 The spots of runs

@term run-spot=v1
@cites {
    findings#{spot=v1},
    files#{path=v1},
    ontology#{declared-item=v1},
    text#{run=v1, boundary=v1, span=v1, body=v1},
    #{read-file=v1, vector-file=v1},
}

For a run r of the text of a read file, or of the text of the vector
file of a declared item, that starts and ends at boundaries of the body,
the spot of r is the spot with the valid path of the file and the span
r.

### 4.51 Edge finding subjects

@term edge-finding-subject=v1
@cites {
    conformance#{own-store=v1},
    findings#{finding-subject=v1, spot=v1},
    files#{path=v1},
    ontology#{content-id=v1, edge=v1, declared-item=v1},
    text#{text=v1, space=v1, code-span=v1},
    #{item-file=v1, tree-edge=v1, origin=v1, run-spot=v1},
}

For a canonical citation edge of one of the five citation kinds
(`cites`, `satisfies`, `verifies`, `refines`, and `supersedes`) whose
source is a declared item with content id *s* and whose canonical target
is content id *t*, the edge finding subject of that canonical edge is
*s*, then a space, then the edge kind *k*, then a space, then *t*:
`<source-content-id> <edge-kind> <target-content-id>`.

The declared-item edge spot of that canonical edge in a tree is:

- when the source declared item stands in a read file (text encoding)
  and exactly one citation entry or inline citation standing in that
  declared item gives that canonical edge (and no other declared item in
  the tree gives that same canonical edge): the spot of the run of that
  citation entry or inline citation in the text of that read file;
- when two or more occurrences in that text declared item (or in two
  declared items with equal canonical objects) give that same canonical
  edge: no spot;
- when the source declared item stands in a valid object file of
  `.sinter/` (and no text declared item has that same canonical object):
  the valid path of that valid object file alone, with no span;
- when the source declared item comes from a program's own store: no
  spot.

### 4.52 Tree findings

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
subject s and either a spot p or no spot, is a finding whose tree is
that tree, whose finding class is the class that c names, whose subject
is s, whose spot is p when a spot p is given and none when no spot is
given, and that is not ackable. The message, the mark, the related
messages, and the fix of that tree finding are those that the program
that gives that tree finding gives.

### 4.53 Edit distance

@term edit-distance=v1
@cites text#{text=v1, character=v1, whole-number=v1}

An edit of a text inserts one character into it, removes one character
from it, replaces one of its characters with another character, or
swaps two of its characters that are next to each other. The edit
distance of two texts a and b is the least whole number n such that a
sequence of n edits changes a into b, where each edit of the sequence
changes the text that the edits before it give.

### 4.54 Findings of the class `parse-error`

@atom parse-error-finding=v1
@cites {
    files#{path=v1},
    #{read-file=v1, unreadable-file=v1, tree-finding=v1},
}

A tree has one tree finding of the class `parse-error` for each read
file of the tree that cannot be read. The subject of the finding is the
valid path of the file. The spot of the finding is the valid path of the
file alone, with no span.

### 4.55 Findings of the class `typo-tag`

@atom typo-tag-finding=v1
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
tag text of a read file of the tree when that line is a tag line and the
tag word of that line meets each of these three conditions. The tag word
is not a Sinter tag word. When the file is a code file, the tag word is
not a foreign tag word of the descriptor of the pack of the file. The
edit distance of the tag word from at least one Sinter tag word is 1 or
2. The subject of the finding is the position subject of the origin
position of the text of that tag line. The spot of the finding is the
spot of the run of the text of that tag line in the text of the file.

### 4.56 Findings of the class `ignored-tag`

@atom ignored-tag-finding=v1
@cites {
    commonmark/0.31.2,
    identifiers#{
        tag-line=v1, tag-word=v1, sinter-tag-word=v1, declaration=v1,
        citation=v1, status-tag=v1, directive=v1, tag-line-text=v1,
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

The heading lines of a setext heading are runs of the text of the file.
A setext heading has one heading line for each markdown line that the
heading takes, other than the last markdown line that the heading takes.
For each such markdown line, take the characters of that markdown line
that CommonMark 0.31.2 gives to the content of the heading. The heading
line for that markdown line is the run of that markdown line from the
first of those characters that is not a space or a tab to the end of
that markdown line.

A tree has one tree finding of the class `ignored-tag` for each line L
of each block B of the markdown document of a markdown file of the tree
that can be read, when each of these is true:

- B is a paragraph and L is one of the lines of that paragraph, or B is
  a setext heading and L is one of its heading lines;
- no block quote contains B;
- B is a block of the document itself, or a block that a list item
  contains and that no block quote, no list, and no list item inside
  that list item contains;
- when B is a paragraph, it is not the first paragraph of a section or
  of a list item;
- L is a tag line, and its tag word is a Sinter tag word or has an edit
  distance of 1 or 2 from a Sinter tag word.

Let A be the run of the text of the file that starts at the boundary
right before the first `@` of L and ends where L ends. The subject of
the finding is the position subject of the origin position of A. The
spot of the finding is the spot of A.

A tag word of an inline description is the text of a run of the inline
description that starts at the boundary where the inline description
starts, or right after a space or a tab, and that is the longest run
that starts there and whose text matches `tag-word`. A tree also has one
tree finding of the class `ignored-tag` for each tag line M of a tag
text of a read file of the tree that can be read, when M is a
declaration, a citation, a status tag, or an `@extern` line, and a tag
word of the inline description of M is a Sinter tag word whose `@` comes
from a place from which no character of a code span of CommonMark 0.31.2
comes. For a markdown file, the code spans of CommonMark 0.31.2 in that
condition are the code spans of the markdown document of the markdown
text of the file. For a code file, the code spans of CommonMark 0.31.2
in that condition are the code spans of the markdown document of the tag
text. Let R be the run of the text of M from the `@` of the first such
tag word to the end of the text of M. Let C be the run of R in the text
of the file, as the term `origin` gives runs in the text of the file.
The subject of the finding is the position subject of the origin
position of C. The spot of the finding is the spot of C.

### 4.57 Findings of the class `invalid-target`

@atom invalid-target-finding=v1
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

When X is a tag line, let Y be the text of the tag line. Otherwise, let
Y be X itself: the link, the citation entry, or the inline citation. The
subject of the finding is the position subject of the origin position of
Y. The spot of the finding is the spot of the run of Y in the text of
the file.

### 4.58 Findings of the class `duplicate`

@atom duplicate-finding=v1
@cites {
    files#{path=v1},
    ontology#{declared-item=v1, item-name=v1},
    text#{character=v1, code-span=v1},
    #{
        item-file=v1, name-set=v1, vector-file=v1, tree-finding=v1,
    },
}

The ASCII lowercase folding of a text changes each ASCII upper-case
letter, from `A` to `Z`, to the same letter in lower case. Two names are
the same name after case folding when their ASCII lowercase foldings are
equal. A tree has these tree findings of the class `duplicate`:

- For each set of names of the tree (spanning both text and `.sinter/`),
  and each largest group of two or more declared items of that set whose
  names are the same name after case folding (including two declarations
  with equal canonical objects, or one in text and one in `.sinter/`):
  the tree has one tree finding for that group. For the shared set, the
  subject of the finding is the ASCII lowercase folding of their names.
  For the set of a design D, the subject of the finding is the exact
  name of D, then `#`, then the ASCII lowercase folding of their part
  names. The finding has no spot.
- For each candidate vector file of the tree (`vector-file`) that
  matches two or more declared items of the tree: the tree has one tree
  finding. The subject of the finding is the valid path of that file.
  The spot of the finding is that valid path alone, with no span.

### 4.59 Findings of the class `dangling`

@atom dangling-finding=v1
@cites {
    identifiers#{citation-entry=v1, inline-citation=v1, part-name=v1},
    data-forms#{vector-line=v1},
    ontology#{edge=v1, declared-item=v1},
    #{
        tree-edge=v1, canonical-object=v1, home-design=v1, origin=v1,
        origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

This finding class reads only the five citation edge kinds (`cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`) and ignores
`items`, `about`, `revises`, and all edges of records and `scope`
objects.

A tree has one tree finding of the class `dangling` for each citation
edge of the tree whose cited item is neither present nor withheld (so
not an ambiguous pin and not lacking its canonical target, withdrawn
target, or needed identity key as a missing part), other than the edges
in these two text cases: a citation entry whose entry name is `#` and a
part name when its citation has no home design, and an inline citation
whose destination matches `#` and a part name when it has no home design.

- When the source of the edge is a declared item (in text, in `.sinter/`,
  or from a program's own store) whose canonical object is not withheld:
  the tree has one tree finding per distinct canonical edge
  `<source-content-id> <edge-kind> <target-content-id>`. Its subject is
  the edge finding subject of that canonical edge, and its spot is the
  declared-item edge spot of that canonical edge (`edge-finding-subject`).
- When the source of the edge is a test, a site, or none: its subject is
  the position subject of the origin position of its citation entry or
  inline citation, and its spot is the spot of the run of that citation
  entry or inline citation in the text of the file.
- When the edge comes from a vector line: its subject is the position
  subject of its form position in its vector file, and its spot is the
  spot of its form run in the text of its vector file.

### 4.60 Findings of the class `wrong-source`

@atom wrong-source-finding=v1
@cites {
    identifiers#{citation-entry=v1},
    ontology#{
        edge=v1, edge-source=v1, declared-item=v1, cites-edge=v1,
        satisfies-edge=v1, verifies-edge=v1, refines-edge=v1,
        supersedes-edge=v1,
    },
    #{
        tree-edge=v1, canonical-object=v1, kept-object-set=v1,
        origin=v1, origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

This finding class reads only the five citation edge kinds (`cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`) and ignores
`items`, `about`, `revises`, and all edges of records and `scope`
objects.

A tree has one tree finding of the class `wrong-source` for each
citation edge of the tree that has no source, or whose source is not of
a kind of item that its kind of edge is for as its source:

- When the source of the edge is a declared item (in text, in `.sinter/`,
  or from a program's own store) whose canonical object and canonical
  edge target are not withheld: the tree has one tree finding per
  distinct canonical edge `<source-content-id> <edge-kind> <target-content-id>`
  (for example, a `verifies` edge whose source is a declared item, even
  when its target is a missing identity file in `.sinter/`). Its subject
  is the edge finding subject of that canonical edge, and its spot is
  the declared-item edge spot of that canonical edge
  (`edge-finding-subject`).
- When the edge has no source or its source is a test or a site: its
  subject is the position subject of the origin position of its citation
  entry or inline citation, and its spot is the spot of the run of that
  citation entry or inline citation in the text of the file.

### 4.61 Findings of the class `wrong-kind`

@atom wrong-kind-finding=v1
@cites {
    identifiers#{
        citation-line=v1, citation-entry=v1, inline-citation=v1,
        external-target=v1, kind-word=v1,
    },
    data-forms#{vector-line=v1},
    ontology#{
        edge=v1, edge-source=v1, declared-item=v1, cites-edge=v1,
        satisfies-edge=v1, verifies-edge=v1, refines-edge=v1,
        supersedes-edge=v1,
    },
    #{
        tree-edge=v1, canonical-object=v1, stated-kind=v1, origin=v1,
        origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

This finding class reads only the five citation edge kinds (`cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`) and ignores
`items`, `about`, `revises`, and all edges of records and `scope`
objects. It checks two conditions on each citation edge of the tree that
has a cited item (neither ambiguous nor withheld by a missing part):

1. **Cited kind condition (canonical objects, both encodings, plus
   tests, sites, vector lines, and no source):** the cited item is not
   of a kind of item or object that the kind of edge of that edge is for
   as its cited item. For an edge of the kind `refines` or `supersedes`
   that has no source, or whose source is not a declared item, this
   condition is instead that the cited item is not a declared item.
2. **Written kind word condition (text encoding only):** the edge comes
   from a text citation entry or inline citation that starts with a
   written kind word (`identifiers#kind-word`) that does not state
   (`stated-kind`) the kind of item of that cited item (including before
   an external target).

The tree has these tree findings of the class `wrong-kind`:

- When the source of the edge is a declared item (in text, in `.sinter/`,
  or from a program's own store) whose canonical object is not withheld:
  condition 1 gives one tree finding per distinct canonical edge
  `<source-content-id> <edge-kind> <target-content-id>`, with its edge
  finding subject and declared-item edge spot (`edge-finding-subject`);
  condition 2 (in text only) gives one tree finding with the position
  subject of the origin position of its citation entry or inline
  citation and the spot of the run of that citation entry or inline
  citation in the text of the file.
- When the source of the edge is a test, a site, or none, and condition
  1 or condition 2 (or both) holds: one tree finding with the position
  subject of the origin position of its citation entry or inline
  citation and the spot of the run of that citation entry or inline
  citation in the text of the file.
- When the edge comes from a vector line and condition 1 holds: one tree
  finding with the position subject of its form position in its vector
  file and the spot of its form run in the text of its vector file.

### 4.62 Findings of the class `misplaced-declaration`

@atom misplaced-declaration-finding=v1
@cites {
    identifiers#{
        declaration=v1, extern-line=v1, target=v1, full-name=v1,
        tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, schema=v1, atom=v1, term=v1,
        containment=v1, edge-source=v1,
    },
    #{
        read-file=v1, accepted-input=v1, item-file=v1, tag-text=v1,
        item-scope=v1, tree-containment=v1, item-part=v1, tree-site=v1,
        origin=v1, origin-position=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1, innermost-item=v1,
    },
}

This finding class applies only to the text encoding. A tree has one
tree finding of the class `misplaced-declaration` for each declaration
of a text declared item d of the tree that meets one or more of these
conditions, and for each `@extern` line that meets the last of them:

- d is of the kind `design`, and its file is a code file;
- d is of the kind `design`, and its declaration is in the scope of
  another text item of the kind `design`;
- d is of the kind `spec`, `req`, `schema`, `atom`, or `term`; the
  innermost text item of the kind `design` in whose scope its
  declaration is, is an item D; and d belongs to an item of the kind
  `design` other than D;
- d is of the kind `req`, `schema`, `atom`, or `term`; its declaration
  is in the scope of a text item of the kind `spec` S that is the
  innermost text item of the kind `spec` in whose scope that declaration
  is; and d belongs to an item of the kind `design` to which S does not
  belong;
- d is of the kind `spec`, and its declaration is in the scope of
  another text item of the kind `spec`;
- d is of the kind `spec`, `schema`, `atom`, or `term`, and it belongs
  to no item of the kind `design`;
- d is of the kind `req`, `schema`, `atom`, or `term`; d belongs to an
  item of the kind `design` D; the name in the target of the declaration
  of d is a full name; the file of d is a markdown file; the file of d
  is not the file of D; and, when d belongs to an item of the kind
  `spec`, the file of d is not the file of that item of the kind `spec`;
- the line is an `@extern` line that is a line of a tag text, that is an
  accepted input, and that stands in no text item of the kind `design`.

The subject of the finding is the position subject of the origin
position of the text of the declaration or of the `@extern` line. The
spot of the finding is the spot of the run of that text in the text of
the file.

### 4.63 Findings of the class `req-outside-design`

@atom req-outside-design-finding=v1
@cites {
    conformance#{own-store=v1},
    identifiers#{tag-line-text=v1},
    ontology#{declared-item=v1, containment=v1, content-id=v1},
    #{
        item-file=v1, canonical-object=v1, tree-containment=v1,
        origin=v1, run-spot=v1, tree-finding=v1,
    },
}

A tree has one tree finding of the class `req-outside-design` for each
distinct content id of a declared item of the kind `req` of the tree (in
text, in `.sinter/`, or from a program's own store) that belongs to no
item of the kind `design` and whose canonical object is not withheld by
a missing part. The subject of the finding is that content id
(`req:<32 hex>`). The spot of the finding is:

- when exactly one declared item of the tree has that content id and it
  is a text declared item: the spot of the run of the text of its
  declaration in the text of its file;
- when exactly one declared item of the tree has that content id and it
  is a stored declared item in `.sinter/`: the valid path of its valid
  object file alone, with no span;
- when two or more declared items of the tree share that content id, or
  when the item comes from a program's own store: no spot.

### 4.64 Findings of the class `extern-mismatch`

@atom extern-mismatch-finding=v1
@cites {
    identifiers#{tag-line-text=v1, kind-word=v1, part-name=v1},
    ontology#{
        containment=v1, item-name=v1, schema=v1, atom=v1, term=v1,
        declared-item=v1,
    },
    #{
        item-file=v1, tree-containment=v1, extern-mark=v1,
        valid-extern-mark=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

This finding class applies only to the text encoding. A tree has these
tree findings of the class `extern-mismatch`:

- one for each extern mark of the tree that is not valid (including an
  extern mark whose part name names a held item stored in `.sinter/`).
  The subject of the finding is the position subject of the origin
  position of the text of the `@extern` line of that extern mark. The
  spot of the finding is the spot of the run of that text in the text of
  the file of that `@extern` line.
- one for each text item of the kind `design` D and each text declared
  item x (never a stored declared item in `.sinter/`) that is either an
  item of the kind `spec` that D holds, or an item that D holds directly
  and that is of the kind `req`, `schema`, `atom`, or `term`, when both
  of these conditions hold. The first condition is that the file of x is
  not the file of D. The second condition is that D has no extern mark
  whose part name is the part name of the name of x and whose kind word
  equals the short object kind word of x (`spec`, `req`, `schema`,
  `atom`, or `term`). The subject of the finding is the position subject
  of the origin position of the text of the declaration of x. The spot
  of the finding is the spot of the run of that text in the text of the
  file of x.

### 4.65 Findings of the class `pin-cycle`

@atom pin-cycle-finding=v1
@cites {
    ontology#{edge=v1, declared-item=v1, computed-identity=v1},
    #{
        tree-edge=v1, canonical-object=v1, edge-finding-subject=v1,
        tree-finding=v1,
    },
}

This finding class reads only the five citation edge kinds (`cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`) and ignores
`items`, `about`, `revises`, and all edges of records and `scope`
objects.

A tree has one tree finding of the class `pin-cycle` for each distinct
canonical pinned citation edge `<source-content-id> <edge-kind> <pin-content-id>`
of a declared item (in text, in `.sinter/`, or from a program's own
store, whose canonical object is not withheld) whose pin lies on a cycle
of the tree's own objects (`canonical-object`, `ontology#edge`). Its
subject is the edge finding subject of that canonical edge, and its spot
is the declared-item edge spot of that canonical edge
(`edge-finding-subject`).

### 4.66 Findings of the class `ambiguous-pin`

@atom ambiguous-pin-finding=v1
@cites {
    data-forms#{vector-line=v1},
    ontology#{edge=v1, declared-item=v1, computed-identity=v1},
    #{
        tree-edge=v1, canonical-object=v1, kept-object-set=v1, origin=v1,
        origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

This finding class reads only the five citation edge kinds (`cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`) and vector-line
edges, and ignores `items`, `about`, `revises`, and all edges of records
and `scope` objects.

A tree has one tree finding of the class `ambiguous-pin` for each
citation edge (or vector-line edge) whose exact pin or resolved `pin:`
edge is ambiguous under `canonical-object` (matching two or more
distinct canonical objects in whichever of the three sets applies:
current declared items of the tree, replaced unwithdrawn declared-item
objects in `.sinter/`, or unwithdrawn objects in `kept-object-set`). An
ambiguous pin withholds dependent results (`dangling`, `wrong-kind`, and
`cited`) for that edge.

- When the source of the edge is a declared item (in text, in `.sinter/`,
  or from a program's own store) whose canonical object is not withheld:
  the tree has one tree finding per distinct canonical edge
  `<source-content-id> <edge-kind> <pin-content-id>`. Its subject is the
  edge finding subject of that canonical edge, and its spot is the
  declared-item edge spot of that canonical edge
  (`edge-finding-subject`).
- When the source of the edge is a test, a site, or none: its subject is
  the position subject of the origin position of its citation entry or
  inline citation, and its spot is the spot of the run of that citation
  entry or inline citation in the text of the file.
- When the edge comes from a vector line: its subject is the position
  subject of its form position in its vector file, and its spot is the
  spot of its form run in the text of its vector file.

### 4.67 Findings of the class `unmatched-vector-file`

@atom unmatched-vector-file-finding=v1
@cites {
    files#{path=v1},
    text#{code-span=v1},
    #{vector-paths=v1, vector-file=v1, tree-finding=v1},
}

Under a valid binding of `vector-paths`, a tree has one tree finding of
the class `unmatched-vector-file` for each candidate vector file of the
tree (`vector-file`, outside `.sinter/`) whose valid path ends with
`.test-vectors.jsonl` and that matches no item of the kind `design` and
no item of the kind `spec` of the tree. The subject of the finding is
the valid path of that file. The spot of the finding is that valid path
alone, with no span.

### 4.68 Findings of the class `ambiguous-vector-file`

@atom ambiguous-vector-file-finding=v1
@cites {
    ontology#{declared-item=v1, item-name=v1},
    #{vector-paths=v1, vector-file=v1, tree-finding=v1},
}

Under a valid binding of `vector-paths`, a tree has one tree finding of
the class `ambiguous-vector-file` for each distinct name of a declared
item of the kind `design`, or of a declared item of the kind `spec` that
belongs to a `design`, of the tree whose test-vector file name matches
two or more candidate vector files of the tree (`vector-file`). The
subject of the finding is that name (such as `billing` or
`billing#invoice`). The finding has no spot.

## 5. Requirements

### 5.1 Read files

@req give-read-files=v1
@cites {
    ontology#{tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    #{read-file=v1, file-readers=v1},
}

Under a valid binding of `file-readers`, when a conforming program gives
the read files of a tree under that binding, that conforming program
must give each read file of the tree once, with the reader of that read
file, and no other read file.

### 5.2 Declared items

@req give-declared-items=v1
@cites {
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, tag-line-text=v1,
    },
    ontology#{declared-item=v1, item-name=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1, read-defined-encodings=v1},
    text#{result=v1},
    #{
        file-readers=v1, item-file=v1, tree-containment=v1,
        origin-position=v1,
    },
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and a valid object store of the
tree (`object-store#tree-object-store`), when a conforming program gives
the declared items of a tree under these bindings, that conforming
program must give each declared item of the tree (in both the text
encoding and the `.sinter/` encoding) once, with the kind of item of
that declared item, the name of that declared item, the file of that
declared item, and (for each text declared item) the origin position of
the text of the declaration of that declared item, and no other declared
item.

### 5.3 Extents

@req give-extents=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{declared-item=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{file-readers=v1, extent=v1, file-line=v1},
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and a valid object store of the
tree, when a conforming program gives the extent of a text declared item
of a tree under these bindings, that conforming program must give the
extent of that item, and nothing else as that extent.

### 5.4 Canonical objects

@req give-canonical-objects=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, tree=v1, parameter=v1, object=v1,
        content-hash=v1, content-id=v1,
    },
    object-store#{tree-object-store=v1},
    conformance#{
        conforming-program=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    text#{result=v1},
    #{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        canonical-object=v1,
    },
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid object store of the tree,
and `kept-object-set`:

- When a conforming program gives the canonical object, content hash, or
  content id of a declared item of the tree whose canonical object is
  not withheld by a missing part (`canonical-object`), that conforming
  program must give that canonical object, content hash, or content id,
  and nothing else. When the canonical object of a text declared item is
  withheld by a missing part, that conforming program must give no
  canonical object, content hash, or content id for that item.
- Under a valid binding of `vector-paths`, when a conforming program
  gives the group description objects (`vector-group-def`) of the tree,
  that conforming program must give once each `vector-group-def` object
  of the tree whose vector lines have no missing-part form pin, with its
  canonical object and content id, and no other `vector-group-def`
  object.

### 5.5 Code hashes

@req give-code-hashes=v1
@cites {
    ontology#{tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    text#{boundary=v1},
    #{file-readers=v1, code-hash=v1, comment-run=v1, read-file=v1},
}

Under a valid binding of `file-readers`, when a conforming program gives
the code hashes of a tree under that binding, that conforming program
must give once each run of comments of a code file of the tree that has
a code hash, with the file of that run of comments, the boundaries where
that run of comments starts and ends, and the code hash of that run of
comments, and no other run of comments with a code hash.

### 5.6 Containment

@req give-containment=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{declared-item=v1, containment=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{file-readers=v1, kept-object-set=v1, tree-containment=v1},
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid object store of the tree,
and `kept-object-set`, when a conforming program gives the item of the kind
`design`, or the item of the kind `spec`, to which a declared item of a
tree belongs under these bindings, that conforming program must give the
item of that kind to which the declared item belongs, or that the
declared item belongs to no item of that kind when the declared item
belongs to none, and nothing else as that item.

### 5.7 Tests

@req give-tests=v1
@cites {
    ontology#{test=v1, tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    #{file-readers=v1, file-test=v1, read-file=v1},
}

Under a valid binding of `file-readers`, when a conforming program gives
the tests of a tree under that binding, that conforming program must
give each test of each read file of the tree once, with the file of that
test, the name of that test, the code of that test, and each comment on
that test, and no other test and no other comment on a test.

### 5.8 Sites

@req give-sites=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{site=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{file-readers=v1, tree-site=v1, read-file=v1, file-line=v1},
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and a valid object store of the
tree, when a conforming program gives the sites of a tree under these
bindings, that conforming program must give each site of each read file
of the tree once, with the file of that site and the file lines of that
site, and no other site.

### 5.9 Edges

@req give-edges=v1
@cites {
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, citation-entry=v1,
        inline-citation=v1,
    },
    data-forms#{vector-line=v1},
    ontology#{edge=v1, edge-source=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1, report-missing-parts=v1},
    text#{result=v1},
    #{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        accepted-input=v1, tree-edge=v1, canonical-object=v1,
        named-item=v1, selected-item=v1, vector-file=v1, item-part=v1,
        tree-site=v1, file-test=v1, origin-position=v1,
    },
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid binding of `vector-paths`,
a valid object store of the tree, and `kept-object-set`, when a conforming
program gives the edges of a tree under these bindings, that conforming
program must give each edge of the tree (`tree-edge`) once, with the
file of that edge, (for a text citation, inline citation, or vector-line
edge) the origin position of its citation entry or inline citation or
the form position of its vector line, the kind of edge of that edge, its
canonical target content id (unless withheld by a missing part), the
source of that edge or that the edge has none, and the cited item of
that edge or that the edge has none (unless withheld because the pin is
ambiguous or a target or needed identity key is a missing part), and no
other edge.

### 5.10 The items in which status tags stand

@req give-status-tag-items=v1
@cites {
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, status-tag=v1,
        tag-line-text=v1,
    },
    ontology#{edge-source=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{
        file-readers=v1, accepted-input=v1, item-part=v1,
        tree-site=v1, file-test=v1, origin-position=v1,
    },
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and a valid object store of the
tree, when a conforming program gives the items in which the status tags
of a tree stand under these bindings, that conforming program must give
once each status tag that is an accepted input of the tree, with the
file of that status tag, the origin position of the text of that status
tag, and the item in which that status tag stands or that the status tag
stands in no item, and no other status tag.

### 5.11 Extern marks

@req give-extern-marks=v1
@cites {
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, tag-line-text=v1,
    },
    ontology#{tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{
        file-readers=v1, accepted-input=v1, extern-mark=v1,
        valid-extern-mark=v1, origin-position=v1,
    },
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and a valid object store of the
tree, when a conforming program gives the extern marks of a tree under
these bindings, that conforming program must give each extern mark of
the tree once, with the file and the origin position of the text of the
`@extern` line of that extern mark, the item of the kind `design` of
that extern mark, and whether that extern mark is valid, and no other
extern mark.

### 5.12 Vector files

@req give-vector-files=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{declared-item=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1},
    text#{result=v1},
    #{file-readers=v1, vector-paths=v1, vector-file=v1},
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid binding of `vector-paths`,
and a valid object store of the tree, when a conforming program gives
the vector file of an item of the kind `design` or of the kind `spec` of
a tree under these bindings, that conforming program must give the
vector file of that item, or that the item has none when the item has
none, and nothing else as that vector file.

### 5.13 The findings of a tree

@req give-tree-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{
        conforming-program=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
    },
    text#{result=v1},
    #{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        tree-finding=v1,
        invalid-target-finding=v1, duplicate-finding=v1,
        dangling-finding=v1, wrong-source-finding=v1,
        wrong-kind-finding=v1, misplaced-declaration-finding=v1,
        req-outside-design-finding=v1, extern-mismatch-finding=v1,
        pin-cycle-finding=v1, ambiguous-pin-finding=v1,
        unmatched-vector-file-finding=v1,
        ambiguous-vector-file-finding=v1,
    },
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid object store of the tree,
and `kept-object-set`:

- When a conforming program gives the findings of the tree of one of the
  classes `invalid-target`, `misplaced-declaration`,
  `req-outside-design`, `extern-mismatch`, and `pin-cycle`, that
  conforming program must give once each tree finding of that class that
  the tree has, and no other finding of that class.
- Under a valid binding of `vector-paths`, when a conforming program
  gives the findings of the tree of one of the classes `duplicate`,
  `dangling`, `wrong-source`, `wrong-kind`, `ambiguous-pin`,
  `unmatched-vector-file`, and `ambiguous-vector-file`, that conforming
  program must give once each tree finding of that class that the tree
  has, and no other finding of that class.

When a computed identity object missing from `.sinter/` or
`kept-object-set` is supplied by another input of the run, every finding
of those classes is given; when no input of the run supplies its key, only the
findings that need its key are withheld (`conformance#report-missing-parts`).

### 5.14 The file findings of a tree

@req give-file-findings=v1
@cites {
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    #{
        file-readers=v1, tree-finding=v1, parse-error-finding=v1,
        typo-tag-finding=v1, ignored-tag-finding=v1,
    },
}

Under a valid binding of `file-readers`, when a conforming program gives
the findings of a tree of one of the classes `parse-error`, `typo-tag`,
and `ignored-tag` under that binding, that conforming program must give
once each tree finding of that class that the tree has, and no other
finding of that class.

### 5.15 Code texts

@req give-code-texts=v1
@cites {
    ontology#{tree=v1, parameter=v1},
    conformance#{conforming-program=v1},
    #{
        file-readers=v1, code-hash=v1, comment-run=v1,
        attachment=v1, read-file=v1,
    },
}

Under a valid binding of `file-readers`, when a conforming program gives
the code text of the attachment target to which a run of comments of a
code file of the tree that has a code hash attaches, under that binding,
that conforming program must give the code text of that attachment
target, and nothing else as that code text.

## 6. Conformance

A program conforms to this design when it is a
[conforming program](sinter:conformance#conforming-program=v1) of this design.

The vectors of this design are in the file
[`documents.test-vectors.jsonl`](documents.test-vectors.jsonl), in the
same folder as this design. The file is a test-vector set, as the
specification [`test-vectors`](sinter:data-forms#test-vectors=v1) of
Data forms gives it. A vector is an input and what a conforming program
gives for that input. Each vector follows from the requirements and adds
nothing to them. Each schema below gives the forms of one group, as the
term [`group-form-list`](sinter:data-forms#group-form-list=v1) gives
them.

Several requirements apply only when a program gives the thing that they
name, such as the extent of a declared item. So a vector checks a
program only on what the program gives for the input. When a program
gives the declared items of a tree, and not their extents, a vector
checks that program only on the declared items.

### 6.1 Markdown files

@schema markdown-vector=v1
@cites {
    rfc/8259,
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
    },
    text#{
        text=v1, character=v1, whole-number=v1, decimal-numeral=v1,
        boundary=v1, run=v1, line-number=v1, position=v1,
        byte-order-mark=v1, valid-utf-8=v1, result=v1,
        code-point-order=v1, code-span=v1,
    },
    files#{path=v1, path-set=v1, path-set-membership=v1},
    data-forms#{
        index=v1, hex-text=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, status-tag=v1,
        citation-entry=v1, inline-citation=v1, tag-line-text=v1,
    },
    ontology#{
        tree=v1, declared-item=v1, containment=v1, site=v1, edge=v1,
        edge-source=v1, external-item=v1, conformance-vector-group=v1,
        vector-set=v1, finding-class=v1, parameter=v1, object=v1,
        content-id=v1, object-kind=v1,
    },
    object-store#{tree-object-store=v1},
    findings#{spot=v1},
    #{
        file-readers=v1, vector-paths=v1, kept-object-set=v1, read-file=v1,
        accepted-input=v1, origin-position=v1, position-order=v1,
        item-file=v1, extent=v1, canonical-object=v1,
        tree-containment=v1, tree-site=v1, tree-edge=v1, extern-mark=v1,
        valid-extern-mark=v1, vector-file=v1, edge-finding-subject=v1,
        tree-finding=v1, give-read-files=v1, give-declared-items=v1,
        give-extents=v1, give-canonical-objects=v1, give-containment=v1,
        give-sites=v1, give-edges=v1, give-status-tag-items=v1,
        give-extern-marks=v1, give-vector-files=v1,
        give-tree-findings=v1, give-file-findings=v1,
    },
}

The group `markdown` has the vectors of trees that have no code file and
no file under `.sinter/`, with an empty set of kept objects
(`kept-object-set`). Its vectors follow from the requirements
`give-read-files`, `give-declared-items`, `give-extents`,
`give-canonical-objects`, `give-containment`, `give-sites`, `give-edges`,
`give-status-tag-items`, `give-extern-marks`, `give-vector-files`,
`give-tree-findings`, and `give-file-findings`, and from the requirements
`reject-invalid-inputs` and `report-missing-parts` of Conformance. Each
vector of the group has the member `values`, and no vector has the member
`result`.

The JSON values, objects, arrays, strings, and numbers of this schema
are as RFC 8259 defines them. Inside the members `input` and `values`,
each JSON value that this schema names as a text, a whole number, a run,
a position, a path set, a binding of `external-namespaces`, or a tree
has this form:

- A text, such as a valid path, a name, a subject, a content id, or a
  hash, is a JSON string whose characters are the characters of the text,
  in order. So the text `a`, a line feed, `b` is `"a\nb"`.
- A whole number of 0 or more, such as a boundary or an index, is a JSON
  number, such as `12`, written as the decimal numeral of that whole
  number.
- A run of the text of a file is a JSON object with two members: `from`,
  the boundary where the run starts, and `to`, the boundary where the
  run ends, such as `{"from":1,"to":4}`. The boundaries are those of the
  text of the file, so a byte order mark at place 1 is before boundary
  1.
- A position is a JSON object with two members: `line`, its line number,
  and `column`, its column, such as `{"column":7,"line":3}`.
- A path set is a JSON array of its path set members, each a text, in
  their order.
- A binding of `external-namespaces` is a JSON array with one element
  for each pair of the binding, in no meaningful order. Each element is
  a JSON object with two members: `namespace-name`, the namespace name
  of the pair, and `id-pattern`, the id pattern of the pair.
- A tree is a JSON object with one member for each file of the tree. The
  key is the valid path of the file. When the content of the file is
  valid UTF-8, the value is the text of that content. When the content
  of the file is not valid UTF-8, the value is a JSON object with one
  member, `bytes`: the [hex text](sinter:data-forms#hex-text=v1) of the
  content, as a JSON string.

The member `input` is a JSON object with four members. `files` is the
tree. `file-readers` is a JSON array with one element for each pair of a
binding of `file-readers`, in the order of the pairs in that binding.
The element for each pair is the path set of that pair, and the reader
of that pair is `markdown`. `vector-paths` is a path set that stands for
a binding of `vector-paths`. `external-namespaces` is a binding of
`external-namespaces`. The program reads the tree under these three
bindings, with an empty set of kept objects.

The member `values` of a vector is the empty JSON object, `{}`, when the
binding of `file-readers` of the input is not valid. When the binding of
`file-readers` of the input is valid and a conforming program of the
design Identifiers gives the result "invalid" for the binding of
`external-namespaces` of the input, the member `values` is a JSON object
with only the two members `read-files` and `findings`, where `findings`
holds only the tree findings of the classes `parse-error`, `typo-tag`,
and `ignored-tag`. When the binding of `file-readers` is valid, the
binding of `external-namespaces` is valid, and the binding of
`vector-paths` is not valid, the member `values` omits `edges` and
`vector-group-defs`, each element of `items` omits `vector-file`, and
`findings` holds only the tree findings of the classes `parse-error`,
`typo-tag`, `ignored-tag`, `invalid-target`, `misplaced-declaration`,
`req-outside-design`, `extern-mismatch`, and `pin-cycle`. Otherwise, the
member `values` is a JSON object with these eight members. When the
member `values` has a member whose value is an empty JSON array or an
empty JSON object, that empty value says that the tree has none of the
things that the member covers. In each JSON array, the elements stand in
the order that the list gives. In each JSON array, the index of an
element, as Data forms defines the [index](sinter:data-forms#index=v1),
refers to that element from other members. So the first element of an
array has the index 1. A file is given by its valid path. Where this
schema orders elements by positions, it uses the
[order of positions](sinter:#position-order=v1). A member that the list
gives only for some elements, such as `design`, `source`, or `spot`, is
not in an element for which the list does not give that member. The
element of a thing that has no such item has no such member.

- `read-files`: a JSON object with one member for each read file of the
  tree. The key of that member is the valid path of the file. The value
  of that member is the index, in the member `file-readers` of the
  input, of the first pair whose path set has that valid path in the set
  of that path set: the pair whose reader is the reader of the file.
- `items`: a JSON array with one element for each declared item of the
  tree, in the code point order of the valid paths of the files of the
  declared items and then in the order of the origin positions of the
  declarations of the declared items (an item from `.sinter/` has no
  origin position and is ordered before any text item of the same file
  path, though no file path holds both). Each element is a JSON object
  for one declared item, with these members. `kind` is the kind name of
  the kind of item of that declared item: one of `design`, `spec`,
  `req`, `term`, `schema`, `atom`, and `decision`. `name` is the name of
  that declared item. `file` is the file of that declared item. When the
  declared item comes from a text declaration, and only then, the
  element has `at` (the origin position of the text of the declaration
  of that declared item) and `extent` (a JSON array of the file lines of
  the extent of that declared item, each a run, in the order of those
  file lines). Unless the canonical object of that declared item is
  withheld by a missing part (`conformance#report-missing-parts`), the
  element has `content-id` (the content id of the canonical object of
  that declared item) and `object` (the canonical object of that
  declared item, as a JSON object). When that declared item belongs to
  an item of the kind `design`, and only then, the element has the
  member `design`, which is the index of that item of the kind `design`.
  When that declared item belongs to an item of the kind `spec`, and
  only then, the element has the member `specification`, which is the
  index of that item of the kind `spec`. When the binding of
  `vector-paths` is valid and that declared item is an item of the kind
  `design` or `spec` that has a vector file, and only then, the element
  has the member `vector-file`, which is the vector file of that
  declared item.
- `sites`: a JSON array with one element for each site of each read file
  of the tree, in the code point order of the valid paths of the files
  of the sites and then in the order of the boundaries where the first
  file lines of the sites start. Each element is a JSON object for one
  site, with two members: `file`, the file of that site, and `lines`, a
  JSON array of the file lines of that site, each a run, in the order of
  those file lines.
- `edges`: a JSON array with one element for each edge of the tree
  (`tree-edge`), in the code point order of the valid paths of the files
  of the edges, then edges with a position before edges without a
  position, then in the order of the origin positions of the citation
  entries or inline citations of the edges or the form positions of the
  vector lines of the edges, then in the code point order of the kinds
  of edges, and then in the code point order of the canonical target
  content ids (with an absent target ordered before any target). Each
  element is a JSON object for one edge, with these members. `kind` is
  the kind of edge, as a text. `file` is the file of that edge. When
  that edge comes from a text citation, an inline citation, or a vector
  line, and only then, the element has the member `at`, which is the
  origin position of the citation entry or inline citation of that edge,
  or the form position of the vector line of that edge. Unless the
  canonical target content id of that edge is withheld by a missing
  part, the element has the member `to`, which is that canonical target
  content id. When that edge has a source, and only then, the element
  has the member `source`, which is the source of that edge, as a
  reference. When that edge has a cited item that is not withheld by a
  missing part or by an ambiguous pin, and only then, the element has
  the member `cited`, which is the cited item of that edge, as a
  reference.
- `vector-group-defs`: a JSON object with one member for each
  `vector-group-def` canonical object of the tree that is not withheld
  by a missing part. The key of that member is the content id of that
  `vector-group-def` object. The value of that member is that
  `vector-group-def` object, as a JSON object.
- `status-tags`: a JSON array with one element for each accepted input
  of the tree that is a status tag, in the code point order of the valid
  paths of the files of the status tags and then in the order of the
  origin positions of the status tags. Each element is a JSON object for
  one status tag, with these members. `file` is the file of that status
  tag. `at` is the origin position of the text of that status tag. When
  that status tag stands in an item, and only then, the element has the
  member `item`, which is the item in which that status tag stands, as a
  reference.
- `extern-marks`: a JSON array with one element for each extern mark of
  the tree, in the code point order of the valid paths of the files of
  the `@extern` lines of the extern marks and then in the order of the
  origin positions of the texts of those `@extern` lines. Each element
  is a JSON object for one extern mark, with these members. `file` is
  the file of the `@extern` line of that extern mark. `at` is the origin
  position of the text of that `@extern` line. `design` is the index of
  the item of the kind `design` of that extern mark in `items`. `valid`
  is the JSON value `true` when that extern mark is valid, and the JSON
  value `false` when that extern mark is not valid.
- `findings`: a JSON array with one element for each tree finding that
  the tree has, of the classes that the requirements
  `give-file-findings` and `give-tree-findings` name and whose
  dependencies are valid and not withheld by a missing part. The
  elements stand in the code point order of the slugs of the classes of
  the tree findings and then in the code point order of the subjects of
  the tree findings. Each element is a JSON object for one tree finding,
  with these members. `class` is the slug of the class of that tree
  finding. `subject` is the subject of that tree finding. When that tree
  finding has a spot, and only then, the element has the member `spot`:
  a JSON object with the member `path`, which is the valid path of that
  spot, and, when that spot has a span, the member `span`, which is that
  span, as a run.

A reference to an item is a JSON object of one of these six forms.
`{"item":k}` refers to the declared item with the index k in `items`.
`{"site":k}` refers to the site with the index k in `sites`.
`{"external":t}` refers to the external item whose external id, with the
`#` and part name of that external id when that external id has them, is
the text t. `{"group":g,"of":k}` refers to the group of conformance
vectors with the name g of the vector set of the declared item with the
index k. `{"vector-set":k}` refers to the vector set of the declared
item with the index k. `{"object":c}` refers to a non-declared-item
canonical object whose content id is the text c.

For the input of a vector, when a conforming program reaches no limit of
its own and reads the tree under the three bindings of the input and an
empty set of kept objects, that conforming program gives what `values`
states. For each member that this schema gives for `values` and that
`values` omits, the conforming program gives, for the tree, none of the
things that that member names (by `reject-invalid-inputs` of Conformance
when `file-readers`, `external-namespaces`, or `vector-paths` is not
valid; when `values` omits `items`, the conforming program also gives no
extent, no canonical object, no item to which a declared item belongs,
and no vector file). When `values` has a member and the conforming
program gives the things that that member names, the conforming program
gives what that member states for those things:

- When the conforming program gives the read files, the conforming
  program gives the keys of `read-files`, each once, with the reader of
  the pair at the index of that key, and no other read file.
- When it gives the declared items, it gives one for each element of
  `items`, with its kind of item, its name, its file, and (for a text
  declared item) the origin position of the text of its declaration, and
  no other declared item.
- When it gives the extent, the canonical object, the item of the kind
  `design` or of the kind `spec` to which a declared item belongs, or
  the vector file of a declared item, it gives what the element of that
  item states, and for a member that the element does not have, that the
  item belongs to no such item, or has no vector file, or that its
  canonical object is withheld by a missing part.
- When it gives the `vector-group-def` canonical objects of the tree, it
  gives one for each member of `vector-group-defs`, with the content id
  and object that the member states, and no other.
- When the conforming program gives the sites, the edges, the items in
  which status tags stand, or the extern marks, the conforming program
  gives one for each element of the member, with what that element
  states, and no other. For an element of `edges` without `source`, the
  conforming program gives that the edge has no source. For an element
  of `edges` without `cited`, the conforming program gives that the edge
  has no cited item (or withholds the cited item when a pin is ambiguous
  or a needed object is missing). For an element of `status-tags`
  without `item`, the conforming program gives that the status tag
  stands in no item.
- When the conforming program gives the tree findings of one of the
  classes that the requirements `give-file-findings` and
  `give-tree-findings` name: if a binding on which that class depends is
  not valid, the conforming program gives no tree finding of that class
  (by `reject-invalid-inputs` of Conformance); otherwise, the conforming
  program gives one for each element of `findings` of that class, with
  the class and the subject that the element states, and no other tree
  finding of that class (except findings withheld by a missing part).
  When the conforming program gives the spot of such a finding, the
  conforming program gives the spot that the element states, or that the
  finding has no spot when the element has no `spot` member.

These lines of the file are vectors of the group:

```
{"form":"#markdown-vector=v1","group":"markdown","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"GH"}],"file-readers":[["docs/**/*.md","*.md"]],"files":{"docs/a.md":"# A\n@design a=v1\n"},"vector-paths":["**"]},"note":"a namespace name with an upper-case letter makes the binding of external-namespaces invalid: read files and independent findings are still given, and dependent outputs are omitted","values":{"findings":[],"read-files":{"docs/a.md":1}}}
{"form":"#markdown-vector=v1","group":"markdown","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["docs/**/*.md","*.md"]],"files":{"README.md":"@cites b=v1\n","docs/bad.md":{"bytes":"4064657369676e20623d76310aff"}},"vector-paths":["**"]},"note":"a file that is not valid UTF-8 cannot be read: one parse-error finding, and no declared item","values":{"edges":[{"at":{"column":8,"line":1},"file":"README.md","kind":"cites","source":{"site":1},"to":"pin:877cd5a3ff97b6d1c5f1fbd9cd087d69"}],"extern-marks":[],"findings":[{"class":"dangling","spot":{"path":"README.md","span":{"from":7,"to":11}},"subject":"README.md@L1C8"},{"class":"parse-error","spot":{"path":"docs/bad.md"},"subject":"docs/bad.md"}],"items":[],"read-files":{"README.md":1,"docs/bad.md":1},"sites":[{"file":"README.md","lines":[{"from":0,"to":11}]}],"status-tags":[],"vector-group-defs":{}}}
{"form":"#markdown-vector=v1","group":"markdown","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["docs/**/*.md","*.md"]],"files":{"docs/top.md":"@design top=v1\nIntro.\n\n# Part\nMore.\n"},"vector-paths":["**"]},"note":"a declaration in the first paragraph of the section of level 0 claims that section","values":{"edges":[],"extern-marks":[],"findings":[],"items":[{"at":{"column":1,"line":1},"content-id":"design:1e14ecbf655a29be1917c97bde656d10","extent":[{"from":0,"to":14},{"from":15,"to":21}],"file":"docs/top.md","kind":"design","name":"top","object":{"edges":[{"kind":"about","to":"name:cd257dac79a7145f2235117d59371df2"}],"kind":"design","label":"v1","name":"top","text":"paragraph: Intro.\n","v":1}}],"read-files":{"docs/top.md":1},"sites":[],"status-tags":[],"vector-group-defs":{}}}
```

### 6.2 Code files

@schema code-vector=v1
@cites {
    rfc/8259,
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
    },
    text#{
        text=v1, whole-number=v1, run=v1, boundary=v1, position=v1,
        valid-utf-8=v1, code-point-order=v1, code-span=v1,
    },
    files#{path=v1, path-set=v1, path-set-membership=v1},
    data-forms#{index=v1, group-form-list=v1, vector-meaning=v1},
    identifiers#{external-namespaces=v1},
    ontology#{tree=v1, test=v1, parameter=v1},
    packs#{
        valid-pack=v1, reading-of-a-text=v1, comment-node=v1,
        definition-node=v1, decoration-node=v1, test-node=v1,
        test-name=v1, node-run=v1, parse-tree-order=v1,
        comment-sigil=v1, foreign-tag-word=v1,
    },
    #{
        markdown-vector=v1, file-readers=v1, vector-paths=v1,
        read-file=v1, file-test=v1, code-hash=v1, comment-run=v1,
        attachment=v1, give-read-files=v1, give-declared-items=v1,
        give-extents=v1, give-canonical-objects=v1, give-containment=v1,
        give-sites=v1, give-edges=v1, give-status-tag-items=v1,
        give-extern-marks=v1, give-vector-files=v1,
        give-tree-findings=v1, give-file-findings=v1, give-tests=v1,
        give-code-hashes=v1, give-code-texts=v1,
    },
}

The group `code` has the vectors of trees that can have code files and
have no file under `.sinter/`, with an empty set of kept objects. Its
vectors follow from the requirements `give-read-files`,
`give-declared-items`, `give-extents`, `give-canonical-objects`,
`give-containment`, `give-sites`, `give-edges`, `give-status-tag-items`,
`give-extern-marks`, `give-vector-files`, `give-tree-findings`,
`give-file-findings`, `give-tests`, `give-code-hashes`, and
`give-code-texts`, and from the requirements `reject-invalid-inputs` and
`report-missing-parts` of Conformance. Each vector of the group has the
member `values`, and no vector has the member `result`.

Inside the members `input` and `values`, each JSON value that this
schema names as a text, a whole number, a run, a position, a path set, a
binding of `external-namespaces`, or a tree has the form that
`markdown-vector` gives for it.

- `input`: a JSON object with four members. `files` is the tree.
  `vector-paths` is a path set that stands for a binding of
  `vector-paths`. `external-namespaces` is a binding of
  `external-namespaces`. `file-readers` is a JSON array with one element
  for each pair of a binding of `file-readers`, in their order. Each
  element is a JSON object with two members: `paths` and `reader`.
  `paths` is the path set of the pair. `reader` is the text `markdown`
  or a JSON object that stands for a valid pack. The JSON object that
  stands for a valid pack has these members: `line`, `inner`,
  `foreign-tags`, `block`, and `readings`. `line` is a JSON array of
  texts: the line sigils of the descriptor of the pack, in their order.
  `inner` is a JSON array of texts: the inner sigils of the descriptor
  of the pack, in their order. `foreign-tags` is a JSON array of texts:
  the foreign tag words of the descriptor of the pack, in their order,
  each foreign tag word with its `@`. `block` is a JSON array with one
  element for each block pair of the descriptor of the pack, in their
  order. Each element of `block` is a JSON array of two texts: the
  opening sigil and the closing sigil of that block pair. `readings` is
  a JSON object with one member for each read file of the tree whose
  content is valid UTF-8 and whose valid path is in the set of the path
  set of this pair and of no pair before this pair. For each member of
  `readings`, the key is the valid path of the file. The value of that
  member is the reading of the text of the file with the pack: a JSON
  object with the member `result` and, only when the result of the
  reading is "parsed", the member `nodes`. The member `result` is the
  result of the reading, as a text.
- `nodes` is a JSON array with one element for each node of the reading
  that is a comment node, a definition node, a decoration node, or a
  test node, in the order of the parse tree. Each element is a JSON
  object with the member `run`, which is the run of the node, and with
  these members for what the node is. For a comment node, the element
  has the member `comment`, which is the text `tagged` or the text
  `untagged`. For a definition node, the element has the member `body`,
  which is a JSON array of the runs of the body nodes of the definition
  node, in the order of the parse tree. For a decoration node, the
  element has the member `decoration`, which is the JSON value `true`.
  For a test node, the element has the member `test`, which is the name
  path of the test node. A node that is a definition node and a test
  node has the members `body` and `test`. For each element of the array
  and each element after it, at least one of two conditions holds, as
  the term [`node-run`](sinter:packs#node-run=v1) of Language packs
  gives for two nodes in the
  [order of the parse tree](sinter:packs#parse-tree-order=v1). The first
  condition is that the run of the later element starts at or after the
  boundary where the run of the earlier element starts, and the run of
  the later element ends at or before the boundary where the run of the
  earlier element ends. The second condition is that the run of the
  earlier element ends at or before the boundary where the run of the
  later element starts.
- `values`: as `markdown-vector` defines it, with the reference form
  `{"test":k}` for the test with the index k in `tests`, and, when the
  binding of `file-readers` of the input is valid, with these two
  additional members:
  - `tests`: a JSON array with one element for each test of each read
    file of the tree. The elements stand in the code point order of the
    valid paths of the files of the tests, then in the order of the
    boundaries where the codes of the tests start, and, for two tests
    whose codes start at one boundary, in the order of the parse tree of
    the test nodes of those two tests. Each element is a JSON object
    with these members: `file`, `name`, `code`, and `comments`. `file`
    is the file of the test. `name` is the name of the test, as a name
    path. `code` is the code of the test, as a run. `comments` is a JSON
    array with one element for each comment on the test, in the order of
    the boundaries where these runs of comments start. For each comment
    on the test, its element in `comments` is the run of the text from
    the boundary where that run of comments starts to the boundary where
    that run of comments ends.
  - `code-hashes`: a JSON array with one element for each run of
    comments of the tree that has a code hash. The elements stand in the
    code point order of the valid paths of the files of these runs of
    comments, and then in the order of the boundaries where these runs
    of comments start. Each element is a JSON object with these members:
    `file`, `comments`, `code-text`, and `code-hash`. `file` is the file
    of the run of comments. `comments` is the run of the text from the
    boundary where that run of comments starts to the boundary where
    that run of comments ends. `code-text` is the code text of the
    attachment target to which the run of comments attaches. `code-hash`
    is the code hash of the run of comments.

  The rules that `markdown-vector` gives for the members of `values`,
  their order, their indexes, and their files hold for `tests` and
  `code-hashes` too.

A name path is a JSON array of its own names, in their order. An own
name is a JSON array of its pieces, in their order. A text piece is the
JSON object `{"text":t}`, where t is the text of the piece. A
placeholder is the JSON object `{"placeholder":t}`, where t is the text
of the piece.

The input stands for each binding of `file-readers` that meets each of
these conditions. First, the pairs of the binding have these path sets.
Second, for each pair where the input gives `markdown`, the reader of
that pair is `markdown`. Third, the packs of the binding have
descriptors with these comment sigils and foreign tag words. Fourth,
those packs give these readings of these texts at these valid paths.

For the input of a vector, when a conforming program reaches no limit of
its own and reads the tree under a binding of `file-readers` that the
input stands for, the binding of `vector-paths` of the input, and the
binding of `external-namespaces` of the input, with an empty set of kept
objects, that conforming program gives what `values` states. For each
member that `markdown-vector` defines for `values`, the conforming
program gives what `markdown-vector` states. When `values` omits `tests`
and `code-hashes`, the conforming program also gives no test, no code
text, and no code hash for the tree. Otherwise:

- When the conforming program gives the tests, the conforming program
  gives one for each element of `tests`, with what that element states,
  and no other. When the conforming program gives the code hashes, the
  conforming program gives one for each element of `code-hashes`, with
  what that element states, and no other.
- When the conforming program gives the code text of the attachment
  target to which a run of comments that has a code hash attaches, the
  conforming program gives the `code-text` of the element of
  `code-hashes` for that run of comments.

This line of the file is a vector of the group:

```
{"form":"#code-vector=v1","group":"code","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[{"paths":["docs/"],"reader":"markdown"},{"paths":["lib/"],"reader":{"block":[],"foreign-tags":[],"inner":[],"line":["//"],"readings":{"lib/c.rs":{"nodes":[{"comment":"tagged","run":{"from":14,"to":38}},{"comment":"tagged","run":{"from":40,"to":52}},{"body":[{"from":60,"to":62}],"run":{"from":53,"to":62}}],"result":"parsed"}}}}],"files":{"docs/d.md":"# D\n@design d=v1\n@extern spec:s\n","lib/c.rs":"use std::io;\n\n// @spec d#s=v1\n// Text.\n\n// @req r=v1\nfn f() {}\n"},"vector-paths":["**"]},"note":"the scope of a specification whose run of comments is unattached and comes after code is its tag text alone","values":{"code-hashes":[{"code-hash":"ca3d163bab055381827226140568f3bef7eaac187cebd76878e0b63e9e442356","code-text":"{}\n","comments":{"from":40,"to":52},"file":"lib/c.rs"}],"edges":[],"extern-marks":[{"at":{"column":1,"line":3},"design":1,"file":"docs/d.md","valid":true}],"findings":[{"class":"req-outside-design","spot":{"path":"lib/c.rs","span":{"from":43,"to":52}},"subject":"req:572d3bac1a22bc599c047afeadacf89b"}],"items":[{"at":{"column":1,"line":2},"content-id":"design:24af7bd7bbc2a5147415610fde95c778","extent":[{"from":0,"to":3},{"from":4,"to":16},{"from":17,"to":31}],"file":"docs/d.md","kind":"design","name":"d","object":{"edges":[{"kind":"about","to":"name:cd4cd021e421cfa87cc98279597862f7"}],"kind":"design","label":"v1","name":"d","text":"","v":1}},{"at":{"column":4,"line":3},"content-id":"spec:18efe9516ddcec64a8cc6608d740fbd4","design":1,"extent":[{"from":16,"to":29},{"from":32,"to":38}],"file":"lib/c.rs","kind":"spec","name":"d#s","object":{"edges":[{"kind":"about","to":"name:d1435e742a893585351e8211323db0ae"}],"kind":"spec","label":"v1","name":"d#s","text":"paragraph: Text.\n","v":1}},{"at":{"column":4,"line":6},"content-id":"req:572d3bac1a22bc599c047afeadacf89b","extent":[{"from":42,"to":52}],"file":"lib/c.rs","kind":"req","name":"r","object":{"edges":[{"kind":"about","to":"name:f870bbfb28cec2d086848a71eb787455"}],"kind":"req","label":"v1","name":"r","text":"","v":1}}],"read-files":{"docs/d.md":1,"lib/c.rs":2},"sites":[],"status-tags":[],"tests":[],"vector-group-defs":{}}}
```

### 6.3 Objects and `.sinter/`

@schema objects-vector=v1
@cites {
    rfc/8259,
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1, give-results-over-canonical-objects=v1,
    },
    text#{
        text=v1, whole-number=v1, run=v1, boundary=v1, position=v1,
        valid-utf-8=v1, code-point-order=v1,
    },
    files#{path=v1, path-set=v1},
    data-forms#{index=v1, group-form-list=v1, vector-meaning=v1},
    identifiers#{external-namespaces=v1},
    ontology#{
        tree=v1, declared-item=v1, object=v1, content-id=v1,
        object-kind=v1, object-withdrawal=v1, computed-identity=v1,
        parameter=v1,
    },
    object-store#{
        tree-object-store=v1, give-store-objects=v1,
        give-store-findings=v1, invalid-object-file-finding=v1,
        missing-identity-file-finding=v1,
    },
    findings#{spot=v1},
    #{
        markdown-vector=v1, file-readers=v1, vector-paths=v1,
        kept-object-set=v1, extent=v1, canonical-object=v1,
        edge-finding-subject=v1,
        give-read-files=v1, give-declared-items=v1, give-extents=v1,
        give-canonical-objects=v1, give-containment=v1, give-sites=v1,
        give-edges=v1, give-status-tag-items=v1, give-extern-marks=v1,
        give-vector-files=v1, give-tree-findings=v1,
        give-file-findings=v1,
    },
}

The group `objects` has the vectors of trees that have no code file and
that can hold objects in `.sinter/` and kept objects supplied by the
caller (`kept-object-set`). Its vectors follow from the requirements
`give-read-files`, `give-declared-items`, `give-extents`,
`give-canonical-objects`, `give-containment`, `give-sites`, `give-edges`,
`give-status-tag-items`, `give-extern-marks`, `give-vector-files`,
`give-tree-findings`, and `give-file-findings`, from the requirements
`give-store-objects` and `give-store-findings` of Object store, and from
the requirements `reject-invalid-inputs`, `report-missing-parts`, and
`give-results-over-canonical-objects` of Conformance. Each vector of the
group has the member `values`, and no vector has the member `result`.

In this group, no list of persons is bound, so every valid `void` object
in `.sinter/` that has no `agent` member and copies the required edges
of the withdrawn object meets the acceptance rule of `void`
(`ontology#object-withdrawal`).

Inside the members `input` and `values`, each JSON value that this
schema names as a text, a whole number, a run, a position, a path set, a
binding of `external-namespaces`, or a tree has the form that
`markdown-vector` gives for it.

- `input`: a JSON object with five members. `files`, `file-readers`,
  `vector-paths`, and `external-namespaces` are as `markdown-vector`
  defines them. `kept-objects` is a JSON array of valid canonical
  objects (declared-item objects and computed identity objects) that
  gives the set `kept-object-set` supplied by the caller.
- `values`: as `markdown-vector` defines it, with these rules for the
  object store of the tree:
  - `findings` also includes the object-store findings of the tree
    (`invalid-object-file` and `missing-identity-file`) given by Object
    store (`object-store#give-store-findings`), sorted with the tree
    findings by `(class, subject)`.
  - When the binding of `file-readers` of the input is not valid,
    `values` is a JSON object with only the member `findings`, holding
    the object-store findings of the tree.
  - When the binding of `file-readers` is valid and the object store of
    the tree is not valid (that is, `.sinter/` has an
    `invalid-object-file` finding), `values` has only `read-files` and
    `findings`, where `findings` holds the object-store findings and the
    tree findings of the classes `parse-error`, `typo-tag`, and
    `ignored-tag`.
  - When `file-readers`, `external-namespaces`, and the object store of
    the tree are valid, `items` includes the unwithdrawn, unreplaced
    declared-item objects of `.sinter/` alongside the text declared
    items (without `at` and `extent`), and `edges` (when `vector-paths`
    is valid) includes the citation edges of those `.sinter/` declared
    items (without `at`).

For the input of a vector, when a conforming program reaches no limit of
its own and reads the tree under the three bindings and `kept-object-set`
of the input, that conforming program gives what `values` states, under
the rules of `markdown-vector` and `object-store#give-store-findings`.

This line of the file is a vector of the group:

```
{"form":"#objects-vector=v1","group":"objects","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["docs/"]],"files":{".sinter/24/24c9b7000870ac77b16104bf78726e19.json":"{\"edges\":[{\"kind\":\"about\",\"to\":\"name:4792925e51aabf3df653a6bd0bd32c2d\"}],\"kind\":\"design\",\"label\":\"v1\",\"name\":\"billing\",\"text\":\"paragraph: Billing design.\\n\",\"v\":1}","docs/invoice.md":"# Invoice\n@spec billing#invoice=v1\nInvoices.\n\n## Cap\n@req cap=v1\nLimit amounts.\n"},"kept-objects":[],"vector-paths":["**"]},"note":"a stored design in .sinter/ holds a text specification and its requirement in docs/ with no extern-mismatch","values":{"edges":[],"extern-marks":[],"findings":[],"items":[{"content-id":"design:24c9b7000870ac77b16104bf78726e19","file":".sinter/24/24c9b7000870ac77b16104bf78726e19.json","kind":"design","name":"billing","object":{"edges":[{"kind":"about","to":"name:4792925e51aabf3df653a6bd0bd32c2d"}],"kind":"design","label":"v1","name":"billing","text":"paragraph: Billing design.\n","v":1}},{"at":{"column":1,"line":2},"content-id":"spec:2898960a47d3932e46e780fa6f25e90f","design":1,"extent":[{"from":0,"to":9},{"from":10,"to":34},{"from":35,"to":44},{"from":45,"to":45},{"from":46,"to":52},{"from":53,"to":64},{"from":65,"to":79}],"file":"docs/invoice.md","kind":"spec","name":"billing#invoice","object":{"edges":[{"kind":"about","to":"name:b4ed52ed154d38c219d0ad079ad2113a"},{"kind":"items","to":"req:4911fcff555b0258562dbf9686de714d"}],"kind":"spec","label":"v1","name":"billing#invoice","text":"paragraph: Invoices.\n","v":1}},{"at":{"column":1,"line":6},"content-id":"req:4911fcff555b0258562dbf9686de714d","design":1,"extent":[{"from":46,"to":52},{"from":53,"to":64},{"from":65,"to":79}],"file":"docs/invoice.md","kind":"req","name":"billing#cap","object":{"edges":[{"kind":"about","to":"name:0f17c8dd86ac60f052972d0be8ace0c2"}],"kind":"req","label":"v1","name":"billing#cap","text":"paragraph: Limit amounts.\n","v":1},"specification":2}],"read-files":{"docs/invoice.md":1},"sites":[],"status-tags":[],"vector-group-defs":{}}}
```
