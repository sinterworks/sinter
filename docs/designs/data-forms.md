<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Data forms
@design data-forms=v1
@cites text=v1
@cites rfc/3339
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
@cites toml-lang/1.1.0
@cites ieee/754-2019
@cites fips/180-4
Specifies the canonical form of JSON values and canonical lines; the TOML documents that Sinter reads, with the spans of their keys and values; SHA-256 hashes and hash ids; test-vector sets and their version sequences; and requirements for conforming programs that write, read, compute, and validate them.

A JSON value is a string, an integer, a boolean, an array, or an object.
Each JSON value has one canonical form: a JSON text, as RFC 8259 defines
it, with the members of each object in a fixed order and with no space,
tab, line feed, or carriage return outside its strings. A canonical line
holds the canonical byte sequence of one line object, which is an object
of a restricted shape, and ends with the byte 0x0A. So two programs that
write the same line objects in the same order write the same bytes.

A TOML document is a byte sequence whose text, as TOML 1.1.0 reads it
with the reading rules of TOML, matches the rule `toml` of TOML 1.1.0,
and that has no value error, no key error, and no structure error: no
value that breaks a rule on values, no key that breaks a rule on keys,
and no key/value pair or table header that breaks a rule on tables. At
each point where TOML 1.1.0 lets an implementation choose, such as the
range of a TOML integer, a conforming program makes one fixed choice.
For a TOML document, a conforming program gives the result "valid", the
root table, and the spans of its keys and values, with their locations.
For every other byte sequence, it gives the result "invalid".

SHA-256 is a hash function: it gives a digest of 32 bytes for a byte
sequence. The hash of a byte sequence is its digest as 64 hex digits. A
hash id is an id prefix, such as `e-`, and then the first hex digits of
a hash. A test-vector set is a byte sequence that holds the vectors of
a specification, each vector as the JSON object of a vector line. In a
version sequence of test-vector sets, the revisions rise by fixed rules
when the vectors change.

From Text and notation, the design takes characters, texts, and their
places, boundaries, and runs; bytes, byte sequences, and UTF-8; byte
order marks and bodies; lines, line numbers, positions, and spans; whole
numbers, decimal numerals, 0x numerals, U+ numerals, and hex digits;
code spans and the notation of productions; and conforming programs,
inputs, and results.

From RFC 8259, the design takes JSON texts, in which canonical forms and
vectors write JSON values. From TOML 1.1.0, it takes documents, their
tables, their keys, and their values, and the rules `toml`, `key`,
`simple-key`, and `val` of its ABNF. From RFC 3339, it takes the ranges
of the months, days, hours, minutes, seconds, and offsets of dates and
times, the meaning of the offset of an offset date-time, and its
statement on leap seconds, which a reading rule of TOML replaces. From
IEEE 754-2019, it takes the binary64 format of floating-point numbers,
and rounding to nearest with ties to even. From FIPS 180-4, it takes the
hash function SHA-256.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405. A production, such as
`hash-form = 64hex-digit`, gives the texts that its name matches.
`64hex-digit` repeats the element `hex-digit` exactly 64 times, `1*`
repeats the element after it one or more times, and `*` repeats it any
number of times, zero included. In a production, `/` separates two
alternatives, and `( )` groups elements. `%x61` is the character U+0061,
and `%x61-7A` is any one character from U+0061 to U+007A. `"-"` is the
character `-`. `DIGIT` is the core rule of RFC 5234 for the characters
`0` to `9`. In RFC 5234, a quoted string such as `"v"` matches its
letters in either case. RFC 7405 adds the string `%s"…"`, which matches
its letters only in the same case.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [conforming program](sinter:text#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design, or every requirement that a specification of a design declares; in a specification, a conforming program of that specification |
| must | states an obligation of a conforming program |
| [input](sinter:text#input=v1) | a thing that a conforming program takes, such as a byte sequence or a text |
| [result](sinter:text#result=v1) | a text that a requirement shows between two double quotes, such as "valid", as one of the cases of what a conforming program gives for an input; the double quotes are not part of the result; a conforming program gives a result when it gives something that stands for that result and for no other result |
| [whole number](sinter:text#whole-number=v1) | a number with no fractional part, such as −7, 0, or 42 |
| [decimal numeral](sinter:text#decimal-numeral=v1) | a text of the characters `0` to `9` that writes a whole number of 0 or more in base 10, and whose first character is not `0` unless the text is `0`, such as `42` |
| [0x numeral](sinter:text#0x-numeral=v1), [U+ numeral](sinter:text#u-numeral=v1) | a text that writes a whole number in base 16, such as 0x0A for 10 and U+0041 for 65; a U+ numeral also names the character that has that code point |
| [hex digit](sinter:text#hex-digit=v1) | one of the characters `0` to `9` and `a` to `f`, which write the whole numbers 0 to 15 |
| [character](sinter:text#character=v1) | a unit of text that has one code point, a Unicode scalar value: from U+0000 to U+D7FF, or from U+E000 to U+10FFFF |
| [code point order](sinter:text#code-point-order=v1) | the order of characters by their code points |
| [space](sinter:text#space=v1), [tab](sinter:text#tab=v1), [line feed](sinter:text#line-feed=v1), [carriage return](sinter:text#carriage-return=v1) | the characters U+0020, U+0009, U+000A, and U+000D |
| [code span](sinter:text#code-span=v1) | the characters between two backticks in a definition or a requirement, which stand for those characters and not for the backticks |
| [text](sinter:text#text=v1) | a finite sequence of characters |
| [place](sinter:text#place=v1) | a whole number, from 1 to the number of the characters of a text, at which a character is in the text |
| [boundary](sinter:text#boundary=v1) | a whole number from 0 to the number of characters of a text: boundary 0 is before place 1, and each other boundary is right after the place with the same number |
| [run](sinter:text#run=v1) | a part of a text that starts at a boundary and ends at the same boundary or at a later boundary |
| [byte](sinter:text#byte=v1) | a whole number from 0 to 255 |
| [byte sequence](sinter:text#byte-sequence=v1) | a finite sequence of bytes |
| [valid UTF-8](sinter:text#valid-utf-8=v1) | a byte sequence is valid UTF-8 when it is the UTF-8 encoding of a text |
| [UTF-8 encoding](sinter:text#utf-8-encoding=v1) | the byte sequence that encodes a text in UTF-8 |
| [text of a byte sequence](sinter:text#text-of-a-byte-sequence=v1) | the text whose UTF-8 encoding a byte sequence is |
| [byte order mark](sinter:text#byte-order-mark=v1) | the character U+FEFF at place 1 of a text |
| [body](sinter:text#body=v1) | the run of a text without its byte order mark |
| [line ending](sinter:text#line-ending=v1) | a run of a text that holds a line feed of the body and, when a carriage return of the body is right before that line feed, that carriage return, and that holds no other character |
| [line](sinter:text#line=v1) | one of the runs into which the line endings divide a body, except an empty run that ends at the boundary where the body ends |
| [line number](sinter:text#line-number=v1) | the number of a line: 1 for the first line of a text, and 1 more for each later line |
| [position](sinter:text#position=v1) | a line number and a column, such as line 3, column 7 |
| [span](sinter:text#span=v1) | a run of a text that starts and ends at boundaries of the body; its start and its end are positions |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| [production](sinter:text#production=v1) | a rule of ABNF that a definition or a requirement holds, such as `hash-form = 64hex-digit`, which gives the texts that its name matches |
| [index](sinter:#index=v1) | the number, counted from 1, of an element of a finite sequence in the order of the sequence |
| [hex text](sinter:#hex-text=v1) | the hex digits that write a byte sequence, two for each byte |
| [JSON value](sinter:#json-value=v1) | a string, an integer, a boolean, an array, or an object |
| [string](sinter:#json-value=v1) | a text, as a JSON value |
| [integer](sinter:#json-value=v1) | a whole number from −(2^53 − 1) to 2^53 − 1, as a JSON value |
| [boolean](sinter:#json-value=v1) | true or false, as a JSON value |
| [array](sinter:#json-value=v1) | a finite sequence of JSON values, its elements |
| [object](sinter:#json-value=v1) | a finite set of members in which no two members have the same key |
| [member](sinter:#json-value=v1) | a key, which is a text, and a JSON value, which is the value of the member |
| [UTF-16 code unit](sinter:#utf-16-code-unit=v1) | a number from 0 to 65,535; a character has one or two of them, as UTF-16 encodes it |
| [key order](sinter:#key-order=v1) | the order of texts by their UTF-16 code units, in which the members of an object stand in its canonical form |
| [canonical form](sinter:#canonical-form=v1) | the one text that the rules of the canonical form give for a JSON value |
| [string form](sinter:#canonical-form=v1) | the text that stands for one character of a string in the canonical form of the string, such as `\n` for the line feed and `a` for `a` |
| escape sequence | a `\` and the characters that TOML 1.1.0 or RFC 8259 reads with it as one escape, such as `\n`, which stands for the line feed, or `\q`, which TOML 1.1.0 reserves |
| noncharacter | a character from U+FDD0 to U+FDEF, or a character whose code point ends in FFFE or FFFF in base 16, such as U+FFFF |
| [canonical byte sequence](sinter:#canonical-byte-sequence=v1) | the UTF-8 encoding of the canonical form of a JSON value |
| [hash](sinter:#hash=v1) | the hex text of the digest that SHA-256 gives for a byte sequence: 64 hex digits |
| [scalar](sinter:#line-object=v1) | a string, an integer, or a boolean |
| [flat object](sinter:#line-object=v1) | an object in which the value of each member is a scalar |
| [line object](sinter:#line-object=v1) | an object in which the value of each member is a scalar, an array of scalars, or an array of flat objects |
| [canonical line](sinter:#canonical-line=v1) | the canonical byte sequence of a line object, then the byte 0x0A |
| [TOML document](sinter:#toml-document=v1) | a byte sequence whose text, as TOML 1.1.0 reads it with the reading rules of TOML, matches the rule `toml` of TOML 1.1.0, and that has no value error, no key error, and no structure error |
| key/value pair, inline table, table header, quoted key, basic string, multi-line basic string, literal string, multi-line literal string | the runs of the text of a document that TOML 1.1.0 calls by these names |
| integer of TOML 1.1.0, float of TOML 1.1.0 | the runs of the text of a document that TOML 1.1.0 calls integers and floats, such as `-17` and `1e400`; the integer part and the exponent part of a float are not integers of TOML 1.1.0 |
| string of TOML 1.1.0, array of TOML 1.1.0 | the runs of the text of a document that TOML 1.1.0 calls strings and arrays, such as `"a"` and `[1, 2]` |
| value of TOML 1.1.0 | a run of the text of a document that the rule `val` of TOML 1.1.0 matches, such as the value of a key/value pair or an element of an array of TOML 1.1.0 |
| array of tables | what TOML 1.1.0 calls an array of tables: a TOML array that table headers with double brackets, such as `[[a]]`, make; the table header of an array of tables is such a table header |
| [TOML key](sinter:#toml-key=v1) | a key of TOML 1.1.0 that is not a dotted key, such as `a` or `"a"` |
| [dotted key](sinter:#toml-key=v1) | a key of TOML 1.1.0 that joins two or more TOML keys with `.`, such as `b.c.x`; these are the TOML keys of the dotted key |
| [key of a key/value pair](sinter:#toml-key=v1), [key of a table header](sinter:#toml-key=v1) | the key of TOML 1.1.0 in it: a TOML key or a dotted key |
| [TOML value](sinter:#toml-value=v1) | a value of the data that TOML 1.1.0 reads from a document: the value that a value of TOML 1.1.0 gives, the root table of a document, a table that a table header makes, a table that a dotted key makes, a TOML array that the table headers of an array of tables make, or a TOML value in one of these; each TOML value is of one of ten kinds |
| [TOML string](sinter:#toml-value=v1), [TOML integer](sinter:#toml-value=v1), [TOML float](sinter:#toml-value=v1), [TOML boolean](sinter:#toml-value=v1), [TOML array](sinter:#toml-value=v1) | a TOML value of the type string, integer, float, boolean, or array of TOML 1.1.0 |
| [local date](sinter:#toml-value=v1), [local time](sinter:#toml-value=v1), [local date-time](sinter:#toml-value=v1), [offset date-time](sinter:#toml-value=v1) | the TOML values of TOML 1.1.0 that have these names |
| [table](sinter:#toml-value=v1) | a TOML value that holds a set of pairs, each the text of a TOML key and a TOML value, with no order |
| [equal](sinter:#toml-value-equality=v1) | the relation of two TOML values of the same kind whose parts match: texts that are the same text, numbers that are the same number, and TOML values that are equal; two TOML floats are equal when their binary64 values have the same bits or both are NaN |
| newline | in a document, a line feed, or a carriage return and a line feed: the name of TOML 1.1.0 for a line ending |
| line ending backslash | in a multi-line basic string, a `\` that is not part of an escape sequence and is the last character on its line apart from tabs and spaces |
| [depth](sinter:#toml-nesting-limit=v1) | how many arrays of TOML 1.1.0 and inline tables stand around an array of TOML 1.1.0 or an inline table, itself included: 1 for one that is in no array of TOML 1.1.0 and no inline table |
| [reading rules of TOML](sinter:#toml-reading-rule-list=v1) | the rules on the encoding, on the byte order mark, and on the second 60; the choices at the points where TOML 1.1.0 lets an implementation choose; the limit on depths and on TOML keys; and the rules on offsets and on newlines in strings |
| [table rules of TOML](sinter:#toml-table-rule-list=v1) | the rules on which table header, key/value pair, or inline table defines a table, and that no two of them define the same table; on the TOML keys that a key/value pair adds; on the tables in the path of a dotted key; on the tables of inline tables; and on the TOML values to which the TOML keys of a key/value pair or of a table header lead; they replace three statements of TOML 1.1.0 on tables, in part or in full |
| [root table](sinter:#root-table=v1) | the top-level table of a TOML document |
| [part of a document](sinter:#toml-part=v1) | a key/value pair, a table header, or an inline table of a document; each key/value pair and each inline table in the value of a key/value pair is a part of its own |
| [boundary of a document](sinter:#toml-boundary=v1) | a boundary of the body that TOML 1.1.0 reads as the document |
| [before](sinter:#toml-boundary=v1) | a part is before a boundary when it ends at that boundary or before it, and before another part when it is before the boundary where the other part starts |
| [tables and TOML values at a boundary](sinter:#toml-boundary-state=v1) | the root table, the tables that the parts before a boundary make, one part after another, also when a part breaks a rule, and the TOML values that these tables hold at that boundary; a table exists at a boundary when it is one of these tables |
| [location](sinter:#toml-location=v1) | the sequence of steps from the root table to a TOML value at the boundary where the body ends: texts of TOML keys and indexes in TOML arrays; two tables with the same location are the same table |
| [super-table](sinter:#toml-super-table=v1) | a table on the way from the root table to the table that a table header names, such as `a` and `a.b` for `[a.b.c]` |
| [undefined super-table](sinter:#undefined-super-table=v1) | at a boundary of a document, a super-table of a table that a table header before that boundary names, when no table header before that boundary names it, it is not the table of an inline table before that boundary, and it is not a table of the path of the dotted key of a key/value pair before that boundary |
| [enclose](sinter:#inline-table-enclosure=v1) | the relation of an inline table to each key/value pair and each inline table between its braces |
| [holding table](sinter:#toml-boundary-state=v1) | the table at which the key of a key/value pair starts: the table of the innermost inline table that encloses the key/value pair, else the root table when no table header comes before it, else the table that the last table header before it names; when that table header names no table, the key/value pair has no holding table |
| [path of a dotted key](sinter:#dotted-key-path=v1) | the tables to which the TOML keys of the dotted key of a key/value pair, apart from its last TOML key, lead from the holding table of the key/value pair at the boundary right after the key/value pair, one after another |
| [span of a key](sinter:#toml-span=v1), [span of a value](sinter:#toml-span=v1) | the run that the rule `key`, `simple-key`, or `val` of TOML 1.1.0 matches for a key, a TOML key, or a value of TOML 1.1.0 |
| [value error](sinter:#toml-value-error=v1) | a value of TOML 1.1.0 that breaks a rule on values, such as an integer of TOML 1.1.0 outside the range of a TOML integer, or an array of TOML 1.1.0 or an inline table with a depth greater than 64; a value error gives no TOML value, and neither does an array of TOML 1.1.0 with an element that gives no TOML value |
| [key error](sinter:#toml-key-error=v1) | a key with more than 64 TOML keys, or a TOML key that has no text |
| [structure rule](sinter:#toml-structure-rule=v1) | a table rule of TOML that a key/value pair or a table header can break, with the parts of a document before it: the rules of `single-definition`, `new-key`, `header-free-path`, `closed-inline-table`, `table-on-the-way`, `header-target`, and `array-header-target` |
| [structure error](sinter:#toml-structure-error=v1) | a key/value pair or a table header that breaks a structure rule |
| fit | a text fits a form when it has the form that a production or a rule gives |
| [hash form](sinter:#hash-form=v1) | the form of a text of exactly 64 hex digits |
| [id prefix](sinter:#id-prefix=v1) | one or more of the letters `a` to `z`, then `-`, such as `e-` |
| [hash id](sinter:#hash-id=v1) | an id prefix, then the first hex digits of a hash, such as `e-ba7816bf8f01` |
| [hash-id form](sinter:#hash-id-form=v1) | the form of a text that is an id prefix, then a given number of hex digits |
| [specification](sinter:text#specification=v1) | a part of a design that has a name of its own and that declares some of the obligations and definitions of the design |
| [vector](sinter:#vector-meaning=v1) | an input and what requirements of a specification, or of a design, oblige a conforming program to give for that input; the object of a vector line states one vector by the forms of its group |
| [test-vector file name](sinter:#test-vector-file-name=v1) | for the name x of a design and the name a of a specification of that design, the text x, `.`, a, and `.test-vectors.jsonl`, such as `a.b.test-vectors.jsonl`; for the name x of a design alone, x and `.test-vectors.jsonl`, such as `a.test-vectors.jsonl` |
| [test-vector revision](sinter:#test-vector-revision=v1) | a text of `v` and the decimal numeral of a whole number of 1 or more, such as `v2` |
| [group name](sinter:#group-name=v1) | a text of the letters `a` to `z`, the digits `0` to `9`, and `-` that starts with a letter, with no `-` at the start or the end, and no two `-` one after the other, such as `offsets` or `g-2` |
| [group](sinter:#vector-line=v1) | the group name that the member `group` of the object of a vector line or of a group line holds, such as `offsets` |
| [the vectors of a group](sinter:#test-vector-set=v1) | the vector lines of a test-vector set whose group is that group |
| [forms of a group](sinter:#group-form-list=v1) | four things that the Conformance section of a design, or the Conformance part of a specification, gives for a group: the requirements of the group, what the value of `input` stands for, which input the value of `result` is the result of, and what the value of `values` stands for |
| [vector object](sinter:#vector-object=v1), [group object](sinter:#vector-object=v1), [set object](sinter:#vector-object=v1) | the object of one vector, of one group, or of the whole test-vector set, each with fixed members; a vector object always has the members `n`, `rev`, `group`, and `input`, has the member `result`, the member `values`, or both, and can have the member `note` |
| [vector line](sinter:#vector-line=v1), [group line](sinter:#vector-line=v1), [set line](sinter:#vector-line=v1) | the canonical byte sequence of a vector object, of a group object, or of a set object, then the byte 0x0A |
| [test-vector set](sinter:#test-vector-set=v1) | a byte sequence of one set line, then zero or more group lines, then zero or more vector lines, in a fixed order |
| [version](sinter:#test-vector-version-sequence=v1) | a test-vector set together with a text for each of its groups, which gives the forms of that group; the elements of a version sequence are versions |
| [version sequence](sinter:#test-vector-version-sequence=v1) | a sequence of versions, from the earliest to the latest, whose numbers and revisions change by fixed rules when the vectors or the forms of their groups change |

## 2. Results, JSON values, and canonical forms

For each input that it reads or validates, a conforming program gives
one of two results: "valid" or "invalid". With "valid", it can give
more, such as the line object of a canonical line or the root table of a
TOML document.

The index of an element of a finite sequence is its number in the order
of the sequence, counted from 1. So the first element of an array has
the index 1, and the second element has the index 2.

A JSON value is one of five things:

| JSON value | what it is |
|---|---|
| string | a text |
| integer | a whole number from −9,007,199,254,740,991 to 9,007,199,254,740,991, which is from −(2^53 − 1) to 2^53 − 1 |
| boolean | true or false |
| array | a finite sequence of JSON values, its elements; it can be empty |
| object | a finite set of members; it can be empty |

A member of an object is a key, which is a text, and a JSON value, the
value of the member. No two members of one object have the same key. Two
texts are the same text only when they have the same characters at the
same places. So an object can hold the key U+00E9 and the key `e`,
U+0301 as two members, although both keys show as the letter e with an
acute accent. It can also hold the keys `a` and `A` as two members. A
conforming program keeps each text as it is: it applies no Unicode
normalization, and it changes the case of no letter.

A JSON value is never null, and it is never a number that is not an
integer, such as `1.5`.

The canonical form of a JSON value is a text. These rules give it:

| JSON value | canonical form |
|---|---|
| string | `"`, then the string form of each character of the string, in order, then `"` |
| integer | the decimal numeral of the integer when it is 0 or more; `-`, then the decimal numeral of its absolute value, when it is less than 0 |
| boolean | `true` or `false` |
| array | `[`, then the canonical forms of the elements in their order, with `,` between each two of them, then `]` |
| object | `{`, then the members in key order, with `,` between each two of them, then `}`; each member is the canonical form of its key as a string, `:`, and the canonical form of its value |

The string form of a character of a string is one of these:

| character | string form |
|---|---|
| `"` (U+0022) | `\"` |
| `\` (U+005C) | `\\` |
| U+0008 | `\b` |
| U+0009, the tab | `\t` |
| U+000A, the line feed | `\n` |
| U+000C | `\f` |
| U+000D, the carriage return | `\r` |
| each other character from U+0000 to U+001F | `\u00`, then the hex text of its code point as a byte, such as `\u001f` for U+001F |
| each other character | the character itself |

So `/`, U+007F, U+2028, and every character from U+0080 stand as
themselves, and the escape sequences `\/` and `\u0041` never stand in a
canonical form.

A canonical form holds no tab and no line feed, and it holds a space
only inside a string. The members of an object stand in key order. Key
order compares two keys by their UTF-16 code units, as the encoding
UTF-16 gives them:

- A character whose code point is less than 0x10000 has one code unit:
  its code point.
- A character whose code point c is 0x10000 or more has two code units:
  first 0xD800 plus the whole-number quotient of c − 0x10000 divided
  by 0x400, then 0xDC00 plus the remainder.

One key comes before another when, at the first index at which their
code units differ, its code unit is less. A key also comes before every
longer key whose code units start with all of its code units, so `a`
comes before `ab`.

Key order agrees with code point order, applied to the characters of two
keys one place after another, and with the order of the bytes of their
UTF-8 encodings, except in one case: at the first place where two keys
differ, one key has a character from U+E000 to U+FFFF, and the other key
has a character from U+10000 to U+10FFFF. For example, the key U+1F600
(the code units 0xD83D and 0xDE00) comes before the key U+E000 (the code
unit 0xE000) in key order, but U+1F600 comes after U+E000 in code point
order.

The canonical byte sequence of a JSON value is the UTF-8 encoding of its
canonical form. Two different JSON values never have the same canonical
form. Each canonical form is a JSON text, as RFC 8259 defines it.

A noncharacter is a character from U+FDD0 to U+FDEF, or a character
whose code point ends in FFFE or FFFF in base 16, such as U+FFFF or
U+10FFFE. For a JSON value whose strings and keys hold no noncharacter,
this canonical form is the same text as the output of the JSON
Canonicalization Scheme of RFC 8785.

In these examples, a JSON text gives each JSON value:

| JSON value | canonical form |
|---|---|
| `{ "b": 1, "a": [true, false] }` | `{"a":[true,false],"b":1}` |
| `{ "ab": 1, "a": 2 }` | `{"a":2,"ab":1}` |
| `"a/b"` | `"a/b"` |
| `"x\u000by"` | `"x\u000by"` |
| `-42` | `-42` |

The hex text of a byte is two hex digits: the hex digit of the
whole-number quotient of the byte divided by 16, then the hex digit of
the remainder. So the hex text of the byte 0x3F is `3f`. The hex text of
a byte sequence is the hex texts of its bytes, in their order, so the
hex text of the byte sequence 0x00, 0xFF is `00ff`.

## 3. Definitions

### 3.1 Indexes

@term index=v1
@cites text#{whole-number=v1}

The index of an element of a finite sequence is its number in the order
of the sequence, counted from 1: the first element has the index 1, and
each other element has 1 more than the index of the element before it.

### 3.2 Hex texts

@term hex-text=v1
@cites text#{
    hex-digit=v1, byte=v1, byte-sequence=v1, text=v1, whole-number=v1,
}

The hex text of a byte is the text of two hex digits: the hex digit of
the whole-number quotient of the byte divided by 16, then the hex digit
of the remainder. The hex text of a byte sequence is the text of the hex
texts of its bytes, in their order, one after another.

### 3.3 JSON values

@term json-value=v1
@cites text#{text=v1, whole-number=v1}

A JSON value is a string, an integer, a boolean, an array, or an object.
A string is a text. An integer is a whole number
from −9,007,199,254,740,991 to 9,007,199,254,740,991. A boolean is true
or false. An array is a finite sequence of JSON values, which are its
elements. An object is a finite set of members. A member is a pair of a
key, which is a text, and a JSON value, which is the value of the
member. No two members of one object have the same key.

### 3.4 UTF-16 code units

@term utf-16-code-unit=v1
@cites text#{
    character=v1, code-point=v1, text=v1, 0x-numeral=v1,
    whole-number=v1,
}

The UTF-16 code units of a character whose code point c is less than
0x10000 are the one number c. The UTF-16 code units of a character whose
code point c is 0x10000 or more are two numbers: first 0xD800 plus the
whole-number quotient of c − 0x10000 divided by 0x400, then 0xDC00 plus
the remainder of that division. The UTF-16 code units of a text are the
UTF-16 code units of its characters, in their order.

### 3.5 Key order

@term key-order=v1
@cites {text#{text=v1}, #{utf-16-code-unit=v1, index=v1}}

In key order, a text t comes before a different text u when, and only
when, one of these is true:

- At the first index at which the UTF-16 code units of t and of u
  differ, the code unit of t is less than the code unit of u.
- The UTF-16 code units of t are fewer than the UTF-16 code units of u,
  and they are the same as the first code units of u.

### 3.6 Canonical forms

@term canonical-form=v1
@cites {
    text#{
        character=v1, code-point=v1, text=v1, byte=v1, u-numeral=v1,
        decimal-numeral=v1, code-span=v1,
    },
    #{json-value=v1, hex-text=v1, key-order=v1},
}

The canonical form of a JSON value is a text that these rules give:

- The canonical form of a string is `"`, then the string form of each
  character of the string, in their order, then `"`.
- The string form of `"` is `\"`, and the string form of `\` is `\\`.
  The string form of U+0008 is `\b`, of U+0009 is `\t`, of U+000A is
  `\n`, of U+000C is `\f`, and of U+000D is `\r`. The string form of
  each other character from U+0000 to U+001F is `\u00`, then the hex
  text of its code point as a byte. The string form of every other
  character is that character.
- The canonical form of an integer that is 0 or more is its decimal
  numeral. The canonical form of an integer that is less than 0 is `-`,
  then the decimal numeral of its absolute value.
- The canonical form of the boolean true is `true`, and of the boolean
  false is `false`.
- The canonical form of an array is `[`, then the canonical forms of its
  elements in their order, with `,` between each two of them, then `]`.
- The canonical form of an object is `{`, then the canonical forms of
  its members in the key order of their keys, with `,` between each two
  of them, then `}`. The canonical form of a member is the canonical
  form of its key as a string, then `:`, then the canonical form of its
  value.

### 3.7 Canonical byte sequences

@term canonical-byte-sequence=v1
@cites {text#{utf-8-encoding=v1}, #{json-value=v1, canonical-form=v1}}

The canonical byte sequence of a JSON value is the UTF-8 encoding of its
canonical form.

### 3.8 Hashes

@term hash=v1
@cites {fips/180-4, text#{byte=v1, byte-sequence=v1}, #{hex-text=v1}}

A byte sequence of fewer than 2^61 bytes makes a message of
FIPS 180-4: 8 bits for each byte, in the order of the bytes, the most
significant bit of each byte first. The digest of the byte sequence is
the message digest of 256 bits that SHA-256, as FIPS 180-4 defines it,
gives for that message, as 32 bytes: 8 bits for each byte, in their
order, the most significant bit of each byte first. The hash of the byte
sequence is the hex text of its digest.

## 4. JSON lines
@spec json-lines=v1

For each JSON value, a conforming program gives its canonical byte
sequence, and for each line object, its canonical line. It gives no
canonical byte sequence for a thing that is not a JSON value, such as
null, and no canonical line for a thing that is not a line object. It
reads a byte sequence as a canonical line: it gives the result "valid"
and the line object when the byte sequence is the canonical line of a
line object, and the result "invalid" for every other byte sequence.

A scalar is a string, an integer, or a boolean. A flat object is an
object in which the value of each member is a scalar. A line object is
an object in which the value of each member is one of these:

- a scalar;
- an array whose elements are all scalars, such as `[1,"a",true]`;
- an array whose elements are all flat objects, such as
  `[{"a":1},{"b":"x"}]`.

An empty array is an array of scalars and also an array of flat objects.
A line object can be empty. These are not line objects:

| object | why it is not a line object |
|---|---|
| `{"a":{"b":1}}` | the value of `a` is an object |
| `{"a":[[1]]}` | the value of `a` is an array that holds an array |
| `{"a":[1,{"b":1}]}` | the value of `a` mixes a scalar and an object |
| `{"a":[{"b":[1]}]}` | the object `{"b":[1]}` is not a flat object |

A canonical line is the canonical byte sequence of a line object, then
the byte 0x0A. The canonical byte sequence never holds the byte 0x0A: a
line feed in a string has the string form `\n`, and the UTF-8 encoding
of no other character holds the byte 0x0A. So the byte 0x0A ends each
canonical line, and a byte sequence of canonical lines, one after
another, divides into them at each byte 0x0A.

These byte sequences are not canonical lines. Each row gives every byte
of the byte sequence, the final 0x0A included:

| byte sequence | why it is not a canonical line |
|---|---|
| `{"b":1,"a":2}`, 0x0A | the keys are not in key order |
| `{"a": 2}`, 0x0A | a space stands outside a string |
| `{"a":2}` | the byte sequence does not end with the byte 0x0A |
| `{"a":2}`, 0x0D, 0x0A | the byte 0x0D stands before the byte 0x0A |
| `{"a":1.0}`, 0x0A | `1.0` is not the canonical form of an integer |
| `{"a":null}`, 0x0A | null is not a string, an integer, a boolean, an array, or an object |
| `{"a":"\u0041"}`, 0x0A | the string form of `A` is `A` |
| `[1]`, 0x0A | the JSON value is not an object |

### 4.1 Definitions

#### 4.1.1 Line objects

@term line-object=v1
@cites #{json-value=v1}

A scalar is a string, an integer, or a boolean. A flat object is an
object in which the value of each member is a scalar. A line object is
an object in which the value of each member is one of these three:

- a scalar;
- an array in which each element is a scalar;
- an array in which each element is a flat object.

#### 4.1.2 Canonical lines

@term canonical-line=v1
@cites {
    text#{byte=v1, byte-sequence=v1, 0x-numeral=v1},
    #{line-object=v1, canonical-byte-sequence=v1},
}

The canonical line of a line object is the byte sequence of the
canonical byte sequence of the line object, then the byte 0x0A.

### 4.2 Canonical byte sequences as output

@req write-canonical-json=v1
@cites {
    text#{requirement=v1, conforming-program=v1},
    #{json-value=v1, canonical-byte-sequence=v1},
}

For each JSON value, a conforming program must give the canonical byte
sequence of that JSON value, and no other byte sequence, as the
canonical byte sequence of that JSON value.

### 4.3 Canonical lines as output

@req write-canonical-line=v1
@cites {
    text#{requirement=v1, conforming-program=v1},
    #{line-object=v1, canonical-line=v1},
}

For each line object, a conforming program must give the canonical line
of that line object, and no other byte sequence, as the canonical line
of that line object.

### 4.4 No canonical line or byte sequence for other things

@req omit-non-canonical-lines=v1
@cites {
    text#{requirement=v1, conforming-program=v1, byte-sequence=v1},
    #{
        json-value=v1, canonical-byte-sequence=v1, line-object=v1,
        canonical-line=v1,
    },
}

A conforming program must give no byte sequence as the canonical line of
a thing that is not a line object, and no byte sequence as the canonical
byte sequence of a thing that is not a JSON value.

### 4.5 Canonical lines as input

@req read-canonical-line=v1
@cites {
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        result=v1,
    },
    #{line-object=v1, canonical-line=v1},
}

For each byte sequence that is the canonical line of a line object, a
conforming program must give the result "valid" and that line object,
and no other result and no other line object. For every other byte
sequence, it must give the result "invalid", and no other result and no
line object.

### 4.6 Conformance

A program conforms to the specification `json-lines` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The vectors of this specification are in the file
[`data-forms.json-lines.test-vectors.jsonl`](data-forms.json-lines.test-vectors.jsonl),
in the same directory as this design. The file is a test-vector set, as
section 8 defines it. Each line of the file is the canonical byte
sequence of one object, then the byte 0x0A, so each line is a JSON text,
as RFC 8259 defines it. Only a line feed ends a line of the file. A
string of the file can hold U+0085, U+2028, or U+2029, and these
characters do not end a line.

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
gives the forms of one group, as section 8 defines them: the
requirements of the group, and what the members `input`, `result`, and
`values` of its vectors stand for, each in a fixed form. A vector
without the member `result` states no result. In `input` and `values`, a
byte sequence is its hex text, as a string, such as `"7b7d0a"` for the
UTF-8 encoding of `{}`, then the byte 0x0A.

#### 4.6.1 Canonical byte sequences

The group `write-json` holds the vectors that each give a JSON value, or
a thing that is not a JSON value, and the canonical byte sequence that a
conforming program gives for it. The requirements of the group are
`write-canonical-json` and `omit-non-canonical-lines`.

- `input`: a string whose characters are a JSON text, as RFC 8259
  defines it, that holds no key twice in one object. The input is what
  the JSON text gives by RFC 8259 and by the rules below. When that is a
  JSON value, the spaces of the JSON text, and the order in which it
  writes the members of an object, are no part of the input.
- `result`: no vector of the group has this member.
- `values`: when the input is a JSON value, an object with one member,
  `canonical-byte-sequence`: the canonical byte sequence of the input.
  When the input is not a JSON value, the empty object, `{}`.

These rules give what a JSON number and a string of the JSON text give:

- A JSON number of the JSON text, as RFC 8259 defines it, gives an
  integer when, and only when, it writes a whole number from −(2^53 − 1)
  to 2^53 − 1, and that integer is the whole number that it writes. So
  `1.0` gives the integer 1, `1e2` gives the integer 100, and `-0` gives
  the integer 0. Every other JSON number, such as `1.5` or
  `9007199254740992`, gives no integer.
- In a string of the JSON text, an escape sequence of `\u` and four
  digits in base 16 writes the number that these four digits write. When
  that number is not from 0xD800 to 0xDFFF, the escape sequence writes
  the character with that code point. Two escape sequences, one right
  after the other, that write a number from 0xD800 to 0xDBFF and then a
  number from 0xDC00 to 0xDFFF write the one character whose UTF-16 code
  units are these two numbers. Each other escape sequence that writes a
  number from 0xD800 to 0xDFFF, such as `\ud800` alone, writes no
  character, and a string that holds it gives no text.

So the JSON text gives a thing that is not a JSON value when one of
these stands in it: `null`, a JSON number that gives no integer, or a
string that gives no text.

A conforming program gives the byte sequence of
`canonical-byte-sequence` as the canonical byte sequence of the input,
and no other byte sequence. When `values` is `{}`, it gives no byte
sequence as the canonical byte sequence of the input.

```
{"group":"write-json","input":"{ \"ab\": 1, \"a\": 2 }","n":2,"rev":"v1","values":{"canonical-byte-sequence":"7b2261223a322c226162223a317d"}}
{"group":"write-json","input":"null","n":22,"note":"null is not a JSON value","rev":"v1","values":{}}
{"group":"write-json","input":"1.0","n":79,"note":"the JSON number `1.0` writes the whole number 1, so it gives the integer 1","rev":"v1","values":{"canonical-byte-sequence":"31"}}
{"group":"write-json","input":"\"\\ud800\"","n":80,"note":"the escape sequence `\\ud800` is not one of the two escape sequences of a character, so the string is not a text","rev":"v1","values":{}}
```

#### 4.6.2 Canonical lines as output

The group `write-line` holds the vectors that each give a line object,
or a thing that is not a line object, and the canonical line that a
conforming program gives for it. The requirements of the group are
`write-canonical-line` and `omit-non-canonical-lines`.

- `input`: a string whose characters are a JSON text, as in the group
  `write-json`. The input is what the JSON text gives, as in that group.
- `result`: no vector of the group has this member.
- `values`: when the input is a line object, an object with one member,
  `canonical-line`: the canonical line of the input. When the input is
  not a line object, the empty object, `{}`.

A conforming program gives the byte sequence of `canonical-line` as the
canonical line of the input, and no other byte sequence. When `values`
is `{}`, it gives no byte sequence as the canonical line of the input.

```
{"group":"write-line","input":"{}","n":27,"rev":"v1","values":{"canonical-line":"7b7d0a"}}
{"group":"write-line","input":"{ \"a\": { \"b\": 1 } }","n":31,"note":"the value of `a` is an object","rev":"v1","values":{}}
```

#### 4.6.3 Canonical lines as input

The group `read-line` holds the vectors that each give a byte sequence
and what a conforming program gives when it reads the byte sequence as a
canonical line. The requirement of the group is `read-canonical-line`.

- `input`: the byte sequence.
- `result`: "valid" when the byte sequence is the canonical line of a
  line object, and "invalid" when it is not.
- `values`: with the result "valid", an object with one member,
  `line-object`: the line object whose canonical line the byte sequence
  is. With the result "invalid", the empty object, `{}`.

With the result "valid", a conforming program gives the line object of
`line-object`, and no other line object. When `values` is `{}`, it gives
no line object.

```
{"group":"read-line","input":"7b2261223a322c2262223a317d0a","n":35,"result":"valid","rev":"v1","values":{"line-object":{"a":2,"b":1}}}
{"group":"read-line","input":"7b2261223a20327d0a","n":56,"note":"a space stands outside a string","result":"invalid","rev":"v1","values":{}}
```

## 5. TOML
@spec toml=v1

A conforming program reads a byte sequence as a TOML document. When the
byte sequence is a TOML document, the program gives the result "valid",
the root table, and the spans of the keys of TOML 1.1.0 and of the
values of TOML 1.1.0 in the document, with their locations. For every
other byte sequence, it gives the result "invalid". With the result
"invalid", a conforming program can also give a position, and this
specification does not specify that position.

In this specification, a text in a code block stands for the UTF-8
encoding of its lines, each line then the byte 0x0A.

A TOML document is a byte sequence whose text, as TOML 1.1.0 reads it
with the reading rules of TOML, matches the rule `toml` of the ABNF of
TOML 1.1.0, and that has no value error, no key error, and no structure
error. A value error is a value that breaks a rule on values, such as an
integer outside the range of a TOML integer. A key error is a key that
breaks a rule on keys, such as a key with more than 64 TOML keys. A
structure error is a key/value pair or a table header that breaks a
structure rule: a rule on tables that a key/value pair or a table header
can break, such as the rule that a key/value pair adds no text to a
table that already holds that text.

TOML 1.1.0 reads a text. By a reading rule of TOML, a byte sequence that
is not valid UTF-8 is not a TOML document, so a conforming program
replaces no byte with U+FFFD. By another reading rule of TOML, for a
byte sequence that is valid UTF-8, TOML 1.1.0 reads the body of its
text, so it does not read a byte order mark. So when a byte sequence
starts with the bytes 0xEF, 0xBB, 0xBF, TOML 1.1.0 reads the characters
after the U+FEFF that these bytes encode. Elsewhere in a byte sequence,
the bytes 0xEF, 0xBB, 0xBF encode a U+FEFF that TOML 1.1.0 allows in a
string of TOML 1.1.0, in a quoted key, and in a comment.

A TOML key is a key of TOML 1.1.0 that is not a dotted key, such as `a`,
`"a"`, or `"\u00e9"`. A dotted key joins two or more TOML keys with `.`,
such as `b.c.x`, and these are the TOML keys of the dotted key. The text
of a TOML key is the text that TOML 1.1.0 gives for it after its escape
sequences resolve, with no other change. The quoted keys `""` and `''`
have the empty text, which has no characters. Two TOML keys are the same
key of TOML 1.1.0 when, and only when, their texts are the same text. So
the TOML keys `a` and `"a"` are the same key of TOML 1.1.0, and the TOML
keys `"\u00e9"` and `"e\u0301"` are two different keys of TOML 1.1.0.

The root table of a TOML document is its top-level table. A value of
TOML 1.1.0 is a run of the text of a document that the rule `val` of
TOML 1.1.0 matches, such as the value of a key/value pair or an element
of an array of TOML 1.1.0. A TOML value is a value of the data that
TOML 1.1.0 reads from a document: the value that a value of TOML 1.1.0
gives, the root table of a document, a table that a table header makes,
a table that a dotted key makes, a TOML array that the table headers
of an array of tables make, or a TOML value in one of these. A table
holds a set of pairs. Each pair is the text of a TOML key and the TOML
value of that TOML key. No two pairs that a table holds have the same
text, and the pairs have no order. Each TOML value is of one of ten
kinds:

| kind | what a TOML value of the kind is |
|---|---|
| TOML string | a text |
| TOML integer | a whole number from −2^63 to 2^63 − 1 |
| TOML float | an IEEE 754-2019 binary64 value |
| TOML boolean | true or false |
| local date | a year, a month, and a day |
| local time | an hour, a minute, a second, and a fraction of a second |
| local date-time | a local date and a local time |
| offset date-time | a local date-time and an offset |
| TOML array | a sequence of TOML values; the index of each of them is its number in the order of the TOML array, counted from 1 |
| table | a TOML value that holds a set of pairs, each the text of a TOML key and a TOML value |

A document gives each TOML value in the syntax of TOML 1.1.0. For
example, the integer `0x1F` of TOML 1.1.0 gives the TOML integer 31, and
the float `1e3` of TOML 1.1.0 gives a TOML float. A basic string, a
multi-line basic string, a literal string, or a multi-line literal
string gives a TOML string.

At some points, TOML 1.1.0 lets an implementation choose. A conforming
program makes these choices:

| point | choice |
|---|---|
| a byte sequence that is not valid UTF-8 | the byte sequence is not a TOML document, and a conforming program replaces no byte with U+FFFD |
| the range of a TOML integer | from −9,223,372,036,854,775,808 to 9,223,372,036,854,775,807, which is from −2^63 to 2^63 − 1; an integer of TOML 1.1.0 that stands for a number outside the range makes the byte sequence not a TOML document |
| the TOML float of a float of TOML 1.1.0 other than `inf`, `+inf`, `-inf`, `nan`, `+nan`, and `-nan` | the IEEE 754-2019 binary64 value whose sign bit is 1 when, and only when, the float of TOML 1.1.0 starts with `-`, and whose magnitude is the binary64 value that rounding to nearest, with ties to even, gives for the absolute value of the number that the float of TOML 1.1.0 stands for; so `-0.0` and `-1e-400` give negative zero |
| a float of TOML 1.1.0 that rounds to an infinity, such as `1e400` | the byte sequence is not a TOML document |
| the floats `inf`, `+inf`, `-inf`, `nan`, `+nan`, and `-nan` of TOML 1.1.0 | `inf` and `+inf` give positive infinity, and `-inf` gives negative infinity; `nan`, `+nan`, and `-nan` each give a TOML float that is NaN |
| more than nine digits in the fraction of a second | a local time, a local date-time, and an offset date-time keep the first nine digits, and the further digits do not change the fraction |
| a newline in a multi-line basic string or a multi-line literal string | each newline that TOML 1.1.0 does not trim stays in the TOML string as its characters: a line feed, or a carriage return and a line feed |

The depth of an array of TOML 1.1.0 or an inline table measures how
deep it stands. An array of TOML 1.1.0 or an inline table that is in no
array of TOML 1.1.0 and no inline table has the depth 1. An array of
TOML 1.1.0 or an inline table that is a value in an array of TOML 1.1.0
or an inline table has a depth 1 more than the depth of that array of
TOML 1.1.0 or inline table. So in `a = [[1], 2]`, the array of
TOML 1.1.0 `[[1], 2]` has the depth 1, and `[1]` has the depth 2.

A conforming program also limits the depth: an array of TOML 1.1.0 or
an inline table with a depth greater than 64, or a key of TOML 1.1.0
with more than 64 TOML keys, makes the byte sequence not a TOML
document. A table that a table header or a dotted key makes has no
depth. The limit of 64 TOML keys applies to each key of TOML 1.1.0
alone, so such tables can nest more than 64 deep.

The fraction of a second is the number that the first nine digits after
the `.` stand for as a decimal fraction. So `12:30:00.5` and
`12:30:00.50` give equal local times, and so do `00:00:00.123456789123`
and `00:00:00.123456789`.

TOML 1.1.0 bases local times, local date-times, and offset date-times on
RFC 3339. RFC 3339, section 5.7, allows the second 60 only at a leap
second. A conforming program accepts the second 60 in a local time, a
local date-time, and an offset date-time, on every date and at every
hour and minute.

RFC 3339, section 4.2, gives the meaning of a numeric offset, local time
minus UTC, and section 4.3 gives the meaning of the offset `-00:00`. The
offset of an offset date-time is the unknown local offset when the
document gives the offset as `-00:00`. Otherwise, the offset is a signed
number of minutes: 0 for `Z` and `z`, and the number of minutes that the
document gives for each other offset, such as 0 for `+00:00` and −420
for `-07:00`. The unknown local offset is not a number of minutes, so it
is not the offset 0. So the offset date-times `1979-05-27T07:32:00Z` and
`1979-05-27T07:32:00+00:00` are equal, and `1979-05-27T07:32:00-00:00`
is equal to neither of them. No offset date-time changes to UTC, so
`1979-05-27T07:32:00-07:00` and `1979-05-27T14:32:00Z` are not equal.

TOML 1.1.0 trims the newline right after the opening delimiter of a
multi-line basic string or a multi-line literal string. In a multi-line
basic string, it also trims each line ending backslash, with all the
tabs, spaces, and newlines after it up to the next other character or
the closing delimiter. So in this text, `s` holds the TOML string `ab`:

```toml
s = """a\
  b"""
```

The rules on the encoding, on the byte order mark, and on the second 60,
the choices listed above, the limit on depths and on TOML keys,
and the rules on offsets and on newlines in strings are the reading
rules of TOML.

These values of TOML 1.1.0 are value errors:

- an integer of TOML 1.1.0 outside the range of a TOML integer, such as
  `9223372036854775808`;
- a float of TOML 1.1.0 that rounds to an infinity, such as `1e400`;
- a local date, a local time, a local date-time, or an offset date-time
  of TOML 1.1.0 with a year, a month, a day, an hour, a minute, a
  second, or an offset outside the range that RFC 3339 allows, with the
  second 60 on every date, such as the local date `1979-02-30`;
- a string of TOML 1.1.0 with an escape sequence whose digits in base 16
  write a number that is not the code point of a character;
- an array of TOML 1.1.0 or an inline table with a depth greater than
  64.

These keys are key errors:

- a key of a key/value pair or of a table header with more than 64
  TOML keys;
- a quoted key with an escape sequence whose digits in base 16 write a
  number that is not the code point of a character. Such a quoted key
  has no text.

The text of a TOML string is the text that TOML 1.1.0 gives for its
basic string, multi-line basic string, literal string, or multi-line
literal string after the escape sequences resolve, with no change other
than the trims of newlines and of line ending backslashes that
TOML 1.1.0 makes. When the document gives no second for a local time, a
local date-time, or an offset date-time, its second is 0. When the
document gives no fraction of a second for it, its fraction of a second
is 0. So `12:30`, `12:30:00`, and `12:30:00.000` give equal local times.

Two TOML values are equal when, and only when, they are of the same kind
and their parts match: texts are the same text, numbers are the same
number, and TOML values in them are equal. Two TOML floats are equal
when, and only when, their binary64 values have the same bits, or both
are NaN. So `-0.0` and `0.0` give two TOML floats that are not equal.

The root table depends only on the texts of the TOML keys and on the
TOML values, and not on the syntax of TOML 1.1.0 that makes them. A
table header, a dotted key, and an inline table each make a table. So
these three texts give equal root tables, in which `a` holds a table in
which `b` holds the TOML integer 1:

```toml
[a]
b = 1
```

```toml
a.b = 1
```

```toml
a = { b = 1 }
```

Both the table headers of an array of tables and the brackets `[` and
`]` around TOML values make a TOML array. So these two texts give equal
root tables, in which `a` holds a TOML array of one table, in which `b`
holds the TOML integer 1:

```toml
a = [{ b = 1 }]
```

```toml
[[a]]
b = 1
```

A boundary of a document is a boundary of the body that TOML 1.1.0
reads. A part of a document is a key/value pair, a table header, or an
inline table, and each key/value pair and each inline table in the value
of a key/value pair is a part of its own. A part is before a boundary
when it ends at that boundary or before it, and a part is before another
part when it is before the boundary where the other part starts. The
tables and TOML values at a boundary are the root table, the tables that
the parts before that boundary make, and the TOML values that these
tables hold at that boundary. The parts make their tables and TOML
values, and add texts to tables, one part after another, in the order of
the boundaries where they end, also when a part breaks a rule. A table
exists at a boundary when it is one of the tables at that boundary.

The location of a TOML value is the sequence of steps that leads to it
from the root table at the boundary where the body ends. Each step is
the text of a TOML key, or the index of a TOML value in a TOML array. So
in the text `a = [1, { b = 2 }]`, the TOML integer 2 has a location of
three steps: the text `a`, the index 2, and the text `b`. Two tables of
a document that have locations are the same table when, and only when,
they have the same location. So two empty tables with different
locations are two different tables.

The table header `[a.b.c]` names the table at the TOML keys `a`, `b`,
`c` from the root table. It also makes the tables `a` and `a.b` when
they do not exist yet. The tables `a` and `a.b` are the super-tables of
the table `a.b.c`.

An inline table encloses each key/value pair and each inline table
between its braces. The key of a key/value pair starts at the holding
table of the key/value pair. When an inline table encloses the key/value
pair, the holding table is the table of the innermost inline table that
encloses it. Else, when no table header comes before the key/value pair,
the holding table is the root table. Else, the holding table is the
table that the last table header before the key/value pair names, when
that table header names one. When that table header names no table, the
key/value pair has no holding table. The key of a key/value pair can be
a dotted key, such as `b.c.x` in `b.c.x = 1`. Each TOML key of the
dotted key before its last TOML key leads to the next table of the path
of the dotted key at the boundary right after the key/value pair. Under
the table header `[a]`, the dotted key `b.c.x` has the path `a.b`,
`a.b.c`, and its last TOML key is `x`.

A key/value pair walks the TOML keys of its key from its holding table.
For each TOML key before the last one, when the table at which the walk
stands does not hold the text of the TOML key, the key/value pair makes
a new table and adds the text to that table, with the new table. Then
the walk goes on to the TOML value of the text. When that TOML value is
a TOML array that the table headers of an array of tables make, the walk
goes on to the last table of that TOML array. When the walk comes to a
TOML value that is not a table, it stops. When the walk does not stop,
the key/value pair adds the text of its last TOML key to the table at
which the walk stands, with the TOML value that its value gives, when
that table does not hold that text yet. A key/value pair that has no
holding table makes nothing.

A table header walks in the same way from the root table. Then, when the
table at which the walk stands does not hold the text of its last TOML
key, the table header makes a new table and adds the text to that table,
with the new table. The table header of an array of tables instead makes
a new table each time. It adds the new table to the end of a TOML array:
the TOML array that table headers make and that is the TOML value of the
text of its last TOML key, or else a new TOML array that it adds with
that text. So a part takes away no table and no TOML value that an
earlier part makes, and it replaces the TOML value of no text that a
table already holds. A table can hold more texts, and a TOML array that
table headers make can hold more tables, at a later boundary than at an
earlier boundary.

The table of an inline table exists before the inline table ends: at
each boundary from the boundary right after its `{` to the boundary
right before its `}`. At such a boundary, that table holds the texts
that the key/value pairs whose holding table it is, and that are before
that boundary, add to it. So at the boundary right before the `}` of
`t = { x = 1, y.z = "s" }`, the table of the inline table holds two
texts: `x`, which holds the TOML integer 1, and `y`, which holds a table
in which `z` holds the TOML string `s`.

A table header names the table to which the TOML keys of its key lead at
the boundary right after the table header, so the table header `[[a.b]]`
names the table that it adds. When these TOML keys lead to a TOML value
that is not a table, or to no TOML value, the table header names no
table. Then a key/value pair after it and before the next table header
has no holding table, unless an inline table encloses the key/value
pair. The key of a key/value pair starts at its holding table at the
boundary right before the key/value pair. Where a TOML key leads to a
TOML array that the table headers of an array of tables make, it leads
to the last table that a table header before that boundary adds to that
TOML array. In this text, the table header on line number 2 names the
table `b` in the first table of the TOML array `a` that the table
headers `[[a]]` make. The key/value pair on line number 5 makes the
table `b` in the second table of that TOML array. The text is a TOML
document:

```toml
[[a]]
[a.b]
z = 1
[[a]]
b.x = 1
```

TOML 1.1.0 itself makes these statements on keys and tables. In each of
them, a key or a table is defined when TOML 1.1.0 calls it defined:

- No key is defined twice, and no table is defined twice.
- An inline table defines all the keys and the sub-tables within its
  braces. The table rules of TOML replace this statement.
- No key and no sub-table is added to the table of an inline table
  outside its braces. So the table of an inline table, and each table in
  it, holds no table that a table header names.
- Dotted keys create and define a table for each TOML key before the
  last one. Of this statement, the table rules of TOML replace only that
  dotted keys define these tables. Dotted keys still create these
  tables: they make the tables of their paths.
- Dotted keys do not define again a table that a table header defines.
- A table header can define a sub-table in a table that dotted keys
  define.
- A table that dotted keys define has all its key/value pairs under the
  current table header, in the root table, or in one inline table. The
  table rules of TOML replace this statement.

The table rules of TOML say exactly which table header, key/value pair,
or inline table defines a table, and which key/value pair or table
header breaks a rule.

At a boundary of a document, a super-table t of a table that a table
header before that boundary names is an undefined super-table when no
table header before that boundary names t, t is not the table of an
inline table before that boundary, and t is not a table of the path of
the dotted key of a key/value pair before that boundary.

These are the table rules of TOML:

- A table header defines the table that it names, and no other table. So
  a table header does not define the super-tables that it makes.
- A key/value pair defines the tables of the path of its dotted key
  that, at the boundary right before the key/value pair, do not exist or
  are undefined super-tables, and no other table.
- An inline table defines its table, and no other table.
- No two of the table headers, the key/value pairs, and the inline
  tables of a document define the same table.
- At the boundary right before a key/value pair, the TOML keys of the
  key of the key/value pair lead from its holding table to no TOML
  value. So a key/value pair gives no new TOML value to a text that a
  table already holds.
- No table of the path of a dotted key is a table that a table header
  before the key/value pair of the dotted key names.
- At the boundary right before a key/value pair whose key has the TOML
  keys k1 to kn, for no i from 1 to n − 1 do the TOML keys k1 to ki lead
  from its holding table to the table of an inline table that does not
  enclose the key/value pair, or to a table whose location starts with
  the location of the table of such an inline table. At the boundary
  right before a table header whose key has the TOML keys k1 to kn, for
  no i from 1 to n do the TOML keys k1 to ki lead from the root table to
  the table of an inline table, or to a table whose location starts with
  the location of the table of an inline table.
- At the boundary right before a key/value pair whose key has the TOML
  keys k1 to kn, for each i from 1 to n − 1, the TOML keys k1 to ki lead
  from its holding table to a table or to no TOML value. At the boundary
  right before a table header whose key has the TOML keys k1 to kn, for
  each i from 1 to n − 1, the TOML keys k1 to ki lead from the root
  table to a table or to no TOML value.
- At the boundary right before a table header that is not the table
  header of an array of tables, the TOML keys of its key lead from the
  root table to a table or to no TOML value.
- At the boundary right before the table header of an array of tables
  whose key has the TOML keys k1 to kn, the TOML keys k1 to kn lead from
  the root table to no TOML value, or to a table in a TOML array that
  table headers make.

In their order, these are the rules of `header-definition`,
`dotted-key-definition`, `inline-table-definition`, `single-definition`,
`new-key`, `header-free-path`, `closed-inline-table`,
`table-on-the-way`, `header-target`, and `array-header-target`. The last
seven of these rules are the structure rules. A key/value pair or a
table header breaks a structure rule when, with the parts of the
document before it, the rule does not hold for it. When two parts define
the same table, the one of the two parts that starts at the later
boundary breaks the rule.

It follows from the definition of an undefined super-table and from the
first three of these rules that no table header, no key/value pair, and
no inline table before a boundary defines an undefined super-table at
that boundary. So the part that breaks the rule `single-definition` is
always a table header: a key/value pair defines only tables that, at the
boundary right before it, do not exist or that no part before it
defines, and an inline table defines only its own new table.

In this text, the key/value pair on line number 2 defines the tables
`a.b` and `a.b.c`. These tables exist at the boundary right before line
number 3, so the key/value pair on line number 3 does not define them a
second time. The text is a TOML document:

```toml
[a]
b.c.d = 1
b.c.e = 2
```

In the text `x = { b.c = 1 }`, the inline table defines the table `x`,
and the key/value pair `b.c = 1` defines the table `x.b`. The text is a
TOML document.

The text `x = { b.c = 1, b = 2 }` is not a TOML document. At the
boundary right before the key/value pair `b = 2`, the table of the
inline table already holds the text `b`, because `b` is the first TOML
key of the dotted key `b.c`. So the TOML key `b` of the key/value pair
`b = 2` leads to the table `x.b`.

This text is a TOML document. Before line number 2, the table `a` is an
undefined super-table, and the table header on line number 2 defines it:

```toml
[a.b]
[a]
x = 1
```

This text is not a TOML document, because the table headers on line
numbers 2 and 3 both define the table `a`:

```toml
[a.b]
[a]
[a]
```

This text is not a TOML document either. Before line number 3, the
tables `a.b` and `a.b.c` of the path of the dotted key `b.c.e` are
undefined super-tables, so the key/value pair on line number 3 defines
both of them. Then the table header on line number 4 defines the table
`a.b` a second time:

```toml
[a.b.c.d]
[a]
b.c.e = 1
[a.b]
```

This text is not a TOML document, because the inline table on line
number 1 and the table header on line number 2 both define the table
`a`:

```toml
a = {}
[a]
```

This text is not a TOML document either. The key/value pair on line
number 1 defines the table `a`, and its inline table defines the table
`a.b`. Then the table header on line number 2 defines the table `a.b` a
second time:

```toml
a.b = {}
[a.b]
```

This text is not a TOML document, because the table header on line
number 2 adds the table `x.b.d` to the table `x.b`, which is in the
inline table on line number 1:

```toml
x = { b.c = 1 }
[x.b.d]
```

This text is not a TOML document, because the table `a` already holds
the text `b` before line number 3. The table header on line number 1
makes the super-table `a.b`, so the key/value pair on line number 3
cannot add the text `b` to the table `a`:

```toml
[a.b.c]
[a]
b = { d = 1 }
```

The path of a dotted key does not go into a table that a table header
names. This text is not a TOML document, because the table `a.b.c`,
which the table header on line number 1 names, is in the path of the
dotted key `b.c.x` on line number 4:

```toml
[a.b.c]
z = 9
[a]
b.c.x = 1
```

This text, which puts the key/value pair `x = 1` under the table header
that names `a.b.c`, is a TOML document:

```toml
[a.b.c]
z = 9
x = 1
```

The rule applies to a table header of an array of tables too. This text
is not a TOML document, because the table header `[[a.b]]` on line
number 1 names the last table of the TOML array `a.b`, and that table is
in the path of the dotted key `b.y` on line number 3:

```toml
[[a.b]]
[a]
b.y = 2
```

The key of a table header can be a dotted key too, such as `q.r` in
`[q.r]`. The table header names a table from the root table, so that
dotted key has no holding table and no path.

The table header `[q.r]` names the table `q.r` from the root table, also
when it stands after the table header `[p]`. In this text, the tables
`p.q` and `q.r` are both empty, and they have different locations, so
they are two different tables. The text is a TOML document:

```toml
[p.q]
[p]
[q.r]
```

When no inline table encloses a key/value pair, a table that the
key/value pair defines can hold tables that table headers make, before
or after the key/value pair: a table that a table header names, and a
super-table of such a table. In this text, the table header on line
number 1 makes the table `a.b` as a super-table of `a.b.c`. Before line
number 4, `a.b` is an undefined super-table, so the key/value pair on
line number 4 defines `a.b` and adds the text `ct` to it. Then `a.b`
holds two texts: `ct`, and `c`, whose TOML value is the table `a.b.c`
that the table header on line number 1 names. The key/value pair on line
number 5 makes and defines the new table `a.b.x`. The text is a TOML
document:

```toml
[a.b.c]
z = 9
[a]
b.ct = 1
b.x.y = 1
```

After the key/value pair on line number 4 defines `a.b`, the table
header `[a.b]` on line number 5 defines it a second time. So this text
is not a TOML document:

```toml
[a.b.c]
z = 9
[a]
b.ct = 1
[a.b]
```

The TOML value that a table header makes can also be a super-table of
the table that the table header names. In this text, the key/value pair
on line number 3 defines the table `a.b`. The table `a.b` holds the
super-table `a.b.c` of the table `a.b.c.d`, which the table header on
line number 1 names. The text is a TOML document:

```toml
[a.b.c.d]
[a]
b.e = 1
```

With the result "valid", a conforming program gives spans of the text of
the byte sequence: the span of the key of each key/value pair and of
each table header, of each TOML key of these keys, and of each value of
TOML 1.1.0. The span of the key of a key/value pair or of a table header
is the run that the rule `key` of TOML 1.1.0 matches, the span of a TOML
key is the run that the rule `simple-key` matches, and the span of a
value of TOML 1.1.0 is the run that the rule `val` matches. A span holds
the quotes of a quoted key and of a string of TOML 1.1.0, the brackets
of an array of TOML 1.1.0, and the braces of an inline table. It holds
no space or tab before or after the key of TOML 1.1.0 or the value of
TOML 1.1.0, but the span of the dotted key `a . b` holds the spaces
around its `.`. The start of a span is the position of the boundary
where it starts, and its end is the position of the boundary right after
its last character. So in the text `a = 1`, the key `a` of the key/value
pair starts at line 1, column 1, and ends at line 1, column 2, and the
value `1` starts at line 1, column 5, and ends at line 1, column 6. A
table that a table header makes, a table of the path of a dotted key, a
TOML array that the table headers of an array of tables make, and the
root table have no span. So in the text `a.b = { c = 1 }`, the table `a`
has no span, and the table `a.b`, which the inline table gives, has the
span of the inline table.

A byte order mark has no position, so it adds no column: when a byte
sequence starts with the bytes 0xEF, 0xBB, 0xBF and then holds `a = 1`,
the key `a` of the key/value pair also starts at line 1, column 1.

With each span, a conforming program gives what the span is the span of.
The span of a value of TOML 1.1.0 is the span of the TOML value at the
location of the TOML value that the value gives. The span of the key of
a key/value pair is the span of the key of TOML 1.1.0 that leads to a
location of these steps: the steps of the location of the holding table
of the key/value pair, then the texts of the TOML keys of that key, in
their order. So in the text `a = [{ b = 1 }]`, the span of the key `b`
is the span of the key of TOML 1.1.0 that leads to a location of three
steps: the text `a`, the index 1, and the text `b`. The span of the key
of a table header is the span of the key of TOML 1.1.0 that leads to the
location of the table that the table header names. The span of the TOML
key with the index i of such a key is the span of the TOML key with the
index i of the key of TOML 1.1.0 that leads to that location. So in the
text `[[a]]`, the span of the key `a` of the table header is the span of
the key of TOML 1.1.0 that leads to a location of two steps, the text
`a` and the index 1. The span of its TOML key `a` is the span of the
TOML key with the index 1 of that key of TOML 1.1.0.

### 5.1 Definitions

#### 5.1.1 TOML keys

@term toml-key=v1
@cites {toml-lang/1.1.0, text#{code-span=v1}}

These definitions use the terms key, dotted key, key/value pair, and
table header of TOML 1.1.0.

- A TOML key is a key of TOML 1.1.0 that is not a dotted key.
- The key of a key/value pair or of a table header is the key of
  TOML 1.1.0 in it.
- The TOML keys of a key of TOML 1.1.0 are the key itself when it is a
  TOML key. When it is a dotted key, they are the TOML keys that the
  dotted key joins with `.`, in their order.

#### 5.1.2 The texts of TOML keys

@term toml-key-text=v1
@cites {
    toml-lang/1.1.0,
    text#{text=v1, character=v1, code-point=v1, code-span=v1},
    #{toml-key=v1},
}

These definitions use the terms quoted key and escape sequence of
TOML 1.1.0.

- The text of a TOML key is the text that TOML 1.1.0 gives for the TOML
  key after its escape sequences resolve, with no other change.
- The text of the quoted key `""` and of the quoted key `''` is the
  empty text, which has no characters. So these quoted keys have a text.
- A quoted key that has an escape sequence whose digits in base 16 write
  a number that is not the code point of a character has no text.

#### 5.1.3 TOML values

@term toml-value=v1
@cites {
    toml-lang/1.1.0,
    ieee/754-2019,
    text#{text=v1, whole-number=v1},
    #{toml-key=v1, toml-key-text=v1, toml-integer-range=v1},
}

These definitions use the terms document, root table, value, table
header, dotted key, array of tables, string, integer, float, boolean,
array, local date, local time, local date-time, offset date-time, and
table of TOML 1.1.0.

- A TOML value is a value of the data that TOML 1.1.0 reads from a
  document: the value that a value of TOML 1.1.0 gives, the root table
  of a document, a table that a table header makes, a table that a
  dotted key makes, a TOML array that the table headers of an array of
  tables make, or a TOML value in one of these.
- A TOML string, a TOML integer, a TOML float, a TOML boolean, and a
  TOML array are the TOML values of the types string, integer, float,
  boolean, and array of TOML 1.1.0.
- Each TOML value is of one of these ten kinds: a TOML string, which is
  a text; a TOML integer, which is a whole number in the range of a TOML
  integer; a TOML float, which is an IEEE 754-2019 binary64 value; a
  TOML boolean, which is true or false; a local date, which is a year, a
  month, and a day; a local time, which is an hour, a minute, a second,
  and a fraction of a second; a local date-time, which is a local date
  and a local time; an offset date-time, which is a local date-time and
  an offset; a TOML array, which is a sequence of TOML values; and a
  table.
- A table holds a set of pairs. Each pair is the text of a TOML key and
  a TOML value. No two pairs that a table holds have the same text. The
  pairs have no order.
- A table holds the text of each pair that it holds, and the TOML value
  of that pair is the TOML value of that text in the table.

#### 5.1.4 Equal TOML values

@term toml-value-equality=v1
@cites {
    ieee/754-2019,
    text#{text=v1, whole-number=v1},
    #{toml-value=v1, index=v1},
}

Two TOML values are equal when, and only when, they are of the same kind
and one of these is true:

- They are TOML strings that are the same text, TOML integers that are
  the same whole number, or TOML booleans that are both true or both
  false.
- They are TOML floats, and their binary64 values have the same bits or
  are both NaN.
- They are local dates, local times, local date-times, or offset
  date-times, with the same year, month, day, hour, minute, second,
  fraction of a second, and offset, for each of these parts that their
  kind has.
- They are TOML arrays that hold the same number of TOML values, and
  their TOML values at each index are equal.
- They are tables that hold the same texts, and the TOML values of each
  of these texts in the two tables are equal.

#### 5.1.5 The encoding of a TOML document

@term toml-encoding=v1
@cites {toml-lang/1.1.0, text#{byte-sequence=v1, valid-utf-8=v1}}

With this rule, TOML 1.1.0 reads no text for a byte sequence that is not
valid UTF-8.

#### 5.1.6 The byte order mark in TOML

@term toml-byte-order-mark=v1
@cites {
    toml-lang/1.1.0,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        byte-order-mark=v1, body=v1,
    },
}

With this rule, TOML 1.1.0 reads, for a byte sequence that is valid
UTF-8, the body of the text of the byte sequence. So when that text has
a byte order mark, TOML 1.1.0 reads the text without its byte order
mark.

#### 5.1.7 The range of a TOML integer

@term toml-integer-range=v1
@cites {toml-lang/1.1.0, text#{code-span=v1}}

This rule uses the terms integer, float, integer part, and exponent part
of TOML 1.1.0. An integer of TOML 1.1.0 is a value of the type integer,
such as `-17` or `0x1F`. The integer part and the exponent part of a
float of TOML 1.1.0 are not integers of TOML 1.1.0. The range of a TOML
integer is from −9,223,372,036,854,775,808 to 9,223,372,036,854,775,807.
An integer of TOML 1.1.0 is outside the range of a TOML integer when it
stands for a number less than −9,223,372,036,854,775,808 or greater
than 9,223,372,036,854,775,807.

#### 5.1.8 The values of TOML floats

@term toml-float-value=v1
@cites {
    toml-lang/1.1.0,
    ieee/754-2019,
    text#{code-span=v1},
    #{toml-value=v1},
}

For a float of TOML 1.1.0 other than `inf`, `+inf`, `-inf`, `nan`,
`+nan`, and `-nan`, the TOML float that it gives is the IEEE 754-2019
binary64 value whose sign bit is 1 when, and only when, the float of
TOML 1.1.0 starts with `-`, and whose magnitude is the binary64 value
that rounding to nearest, with ties to even, gives for the absolute
value of the number that the float of TOML 1.1.0 stands for.

#### 5.1.9 Floats that round to an infinity

@term toml-float-overflow=v1
@cites {
    toml-lang/1.1.0,
    ieee/754-2019,
    text#{code-span=v1},
    #{toml-value=v1, toml-float-value=v1},
}

A float of TOML 1.1.0 rounds to an infinity when the TOML float that it
gives, by the rule `toml-float-value`, is an infinity.

#### 5.1.10 Infinities and NaN in TOML

@term toml-special-float=v1
@cites {
    toml-lang/1.1.0,
    ieee/754-2019,
    text#{code-span=v1},
    #{toml-value=v1},
}

The floats `inf` and `+inf` of TOML 1.1.0 give the TOML float positive
infinity, and the float `-inf` of TOML 1.1.0 gives the TOML float
negative infinity. The floats `nan`, `+nan`, and `-nan` of TOML 1.1.0
each give a TOML float that is NaN.

#### 5.1.11 Fractions of a second in TOML

@term toml-second-fraction=v1
@cites {toml-lang/1.1.0, text#{code-span=v1}, #{toml-value=v1}}

In a document, the digits after the `.` of the second of a local time, a
local date-time, or an offset date-time give its fraction of a second.
When these digits are d1 to dk, the fraction of a second is the sum of
the numbers di / 10^i for each i from 1 to m, where m is the smaller of
k and 9.

#### 5.1.12 Leap seconds in TOML

@term toml-leap-second=v1
@cites {rfc/3339, toml-lang/1.1.0, #{toml-value=v1}}

With this rule, which replaces the statement of RFC 3339, section 5.7,
on leap seconds, TOML 1.1.0 reads each second from 0 to 60 as a valid
second of a local time, a local date-time, and an offset date-time, on
every date and at every hour and minute.

#### 5.1.13 Offsets in TOML

@term toml-offset=v1
@cites {
    toml-lang/1.1.0,
    rfc/3339,
    text#{code-span=v1},
    #{toml-value=v1},
}

The offset of an offset date-time is the unknown local offset of
RFC 3339, section 4.3, when the document gives the offset as `-00:00`.
Otherwise, the offset is a signed number of minutes: 0 when the document
gives the offset as `Z` or `z`, and the number of minutes that the
document gives for each other offset, such as 0 for `+00:00` and −420
for `-07:00`. The unknown local offset is not a number of minutes.

#### 5.1.14 Newlines in TOML strings

@term toml-string-newline=v1
@cites {
    toml-lang/1.1.0,
    text#{character=v1, u-numeral=v1},
    #{toml-value=v1},
}

These rules use the terms multi-line basic string, multi-line literal
string, newline, and line ending backslash of TOML 1.1.0.

- TOML 1.1.0 trims a newline right after the opening delimiter of a
  multi-line basic string or a multi-line literal string.
- In a multi-line basic string, TOML 1.1.0 trims each line ending
  backslash with all the tabs, spaces, and newlines after it up to the
  next other character or the closing delimiter.
- Each other newline of a multi-line basic string or a multi-line
  literal string stays in the TOML string as its characters: U+000A, or
  U+000D and then U+000A.

#### 5.1.15 The nesting limit of TOML

@term toml-nesting-limit=v1
@cites {toml-lang/1.1.0, #{toml-key=v1, inline-table-enclosure=v1}}

This rule uses the terms value, array, inline table, key/value pair,
key, and table header of TOML 1.1.0.

- The values in an array of TOML 1.1.0 are its elements. The values in
  an inline table are the values of the key/value pairs that it encloses
  and that no other inline table in it encloses.
- An array of TOML 1.1.0 or an inline table of a document that is a
  value in no array of TOML 1.1.0 and no inline table has the depth 1.
  An array of TOML 1.1.0 or an inline table that is a value in an array
  of TOML 1.1.0 or an inline table has a depth 1 more than the depth of
  that array of TOML 1.1.0 or inline table.
- The nesting limit of TOML is 64. It limits the depth of an array of
  TOML 1.1.0 or an inline table, and the number of the TOML keys of the
  key of a key/value pair or of a table header.

#### 5.1.16 The reading rules of TOML

@term toml-reading-rule-list=v1
@cites {
    text#{code-span=v1},
    #{
        toml-encoding=v1, toml-byte-order-mark=v1,
        toml-integer-range=v1, toml-float-value=v1,
        toml-float-overflow=v1, toml-special-float=v1,
        toml-second-fraction=v1, toml-leap-second=v1, toml-offset=v1,
        toml-string-newline=v1, toml-nesting-limit=v1,
    },
}

The reading rules of TOML are the rules of `toml-encoding`,
`toml-byte-order-mark`, `toml-integer-range`, `toml-float-value`,
`toml-float-overflow`, `toml-special-float`, `toml-second-fraction`,
`toml-leap-second`, `toml-offset`, `toml-string-newline`, and
`toml-nesting-limit`.

#### 5.1.17 Parts of a TOML document

@term toml-part=v1
@cites toml-lang/1.1.0

This definition uses the terms document, key/value pair, table header,
inline table, and value of TOML 1.1.0. A part of a document is a
key/value pair, a table header, or an inline table of the document. Each
key/value pair and each inline table in the value of a key/value pair is
a part of its own.

#### 5.1.18 Boundaries of a TOML document

@term toml-boundary=v1
@cites {
    toml-lang/1.1.0,
    text#{boundary=v1, body=v1},
    #{toml-byte-order-mark=v1, toml-part=v1},
}

This definition uses the term document of TOML 1.1.0.

- A boundary of a document is a boundary of the body that TOML 1.1.0
  reads as that document.
- A part of a document is before a boundary of the document when it ends
  at that boundary or before it.
- A part is before another part when it is before the boundary where the
  other part starts.

#### 5.1.19 What inline tables enclose

@term inline-table-enclosure=v1
@cites toml-lang/1.1.0

This definition uses the terms inline table and key/value pair of
TOML 1.1.0.

An inline table encloses each key/value pair and each inline table
between its braces.

#### 5.1.20 The tables and TOML values at a boundary, the TOML values that TOML keys lead to, and holding tables

@term toml-boundary-state=v1
@cites {
    toml-lang/1.1.0,
    text#{boundary=v1, code-span=v1},
    #{
        toml-boundary=v1, toml-part=v1, toml-key=v1, toml-key-text=v1,
        toml-value=v1, inline-table-enclosure=v1,
    },
}

These definitions use the terms document, key/value pair, table header,
array of tables, inline table, value, array, and root table of
TOML 1.1.0.

- The parts of a document act one after another, in the order of the
  boundaries where they end. A key/value pair whose value is an inline
  table ends at the same boundary as that inline table, and it comes
  after that inline table in this order. A part acts also when it breaks
  a rule. When a part acts, each table holds the texts that the parts
  that act before it add to that table, each with the TOML value that
  the part adds with it, and no other text.
- The tables at a boundary of a document are the root table and the
  tables that the parts before that boundary make. At that boundary,
  each table holds the texts that the parts before that boundary add to
  it, each with the TOML value that the part adds with it, and no other
  text. The TOML values at a boundary are the tables at that boundary
  and the TOML values that these tables hold at that boundary.
- A table exists at a boundary when it is one of the tables at that
  boundary.
- An inline table makes its table. At each boundary from the boundary
  right after its `{` to the boundary right before its `}`, the table of
  the inline table is also one of the tables at that boundary.
- A key/value pair whose key has the TOML keys k1 to kn, and that has a
  holding table t0, walks from t0 when it acts, for each i from 1 to
  n − 1, one after another. When t(i−1) does not hold the text of ki,
  the key/value pair makes a new table ti and adds the text of ki to
  t(i−1), with the TOML value ti. When t(i−1) holds the text of ki with
  a TOML array that the table headers of an array of tables make, ti is
  the last TOML value in that TOML array. When t(i−1) holds the text of
  ki with another TOML value, ti is that TOML value. When ti is not a
  table, the walk stops, and the key/value pair makes nothing more and
  adds nothing more.
- When the walk of a key/value pair does not stop, t(n−1) does not hold
  the text of kn, and the value of the key/value pair gives a TOML
  value, the key/value pair adds the text of kn to t(n−1), with that
  TOML value.
- A table header whose key has the TOML keys k1 to kn walks in the same
  way from the root table t0 when it acts, for each i from 1 to n − 1.
  When its walk does not stop, t(n−1) does not hold the text of kn, and
  it is not the table header of an array of tables, the table header
  makes a new table and adds the text of kn to t(n−1), with that table.
- When the walk of the table header of an array of tables does not stop
  and t(n−1) does not hold the text of kn, the table header makes a new
  table and a new TOML array that holds that table, and it adds the text
  of kn to t(n−1), with that TOML array. When its walk does not stop and
  t(n−1) holds the text of kn with a TOML array that the table headers
  of an array of tables make, the table header makes a new table and
  adds it to the end of that TOML array.
- A key/value pair that has no holding table makes no table and adds no
  text. A key/value pair or a table header whose key has a TOML key that
  has no text makes no table and adds no text either.
- When an inline table gives a TOML value, the table of the inline table
  is that TOML value.
- So a part takes away no table and no TOML value that a part before it
  makes, and a part replaces the TOML value of no text that a table
  already holds.

At a boundary of a document, the TOML keys k1 to kn lead from a table v0
to a TOML value vn when, and only when, there are TOML values v1 to vn
for which these are true for each i from 1 to n:

- At that boundary, v(i−1) is a table that holds the text of ki. Let wi
  be the TOML value of that text in v(i−1) at that boundary.
- When the table headers of an array of tables make wi, vi is the last
  table that a table header that ends at that boundary or before it adds
  to wi. Otherwise, vi is wi.

When there are no such TOML values, the TOML keys k1 to kn lead from v0
to no TOML value. So when one of k1 to kn has no text, they lead from v0
to no TOML value.

Each table header, also the table header of an array of tables, names
the table to which the TOML keys of the key of the table header lead
from the root table at the boundary right after the table header, when
they lead to a table. When they lead to a TOML value that is not a
table, or to no TOML value, the table header names no table.

The holding table of a key/value pair is one of these:

- When an inline table encloses the key/value pair, the holding table is
  the table of the innermost inline table that encloses it.
- When no inline table encloses the key/value pair and no table header
  comes before it, the holding table is the root table.
- When no inline table encloses the key/value pair and the last table
  header before it names a table, the holding table is that table.
- When no inline table encloses the key/value pair and the last table
  header before it names no table, the key/value pair has no holding
  table. Then the TOML keys of its key lead to no TOML value at any
  boundary.

#### 5.1.21 The locations of TOML values

@term toml-location=v1
@cites {
    toml-lang/1.1.0,
    text#{body=v1, boundary=v1},
    #{
        toml-value=v1, toml-key-text=v1, toml-key=v1, index=v1,
        toml-boundary-state=v1,
    },
}

These definitions use the terms document and root table of TOML 1.1.0.

- The location of a TOML value of a document is the sequence of steps
  that leads to it from the root table at the boundary where the body
  ends. Each step is the text of a TOML key, or the index of a TOML
  value in a TOML array.
- The location of the root table is the sequence of no steps. When a
  table with the location L holds a text x, the TOML value of x in that
  table has the location of the steps of L and then the step x. When a
  TOML array with the location L holds a TOML value at the index i, that
  TOML value has the location of the steps of L and then the step i.
- Two tables of a document that have locations are the same table when,
  and only when, they have the same location. Two tables with different
  locations are two different tables, also when they hold the same
  pairs.

#### 5.1.22 Super-tables

@term toml-super-table=v1
@cites {
    toml-lang/1.1.0,
    #{
        toml-key=v1, toml-value=v1, toml-boundary-state=v1,
        toml-boundary=v1,
    },
}

This definition uses the terms table header and root table of
TOML 1.1.0.

For a table header that names a table and whose key has the TOML keys
k1 to kn, the super-tables of the table that the table header names are
the tables that the TOML keys k1 to ki lead to from the root table at
the boundary right after the table header, for each i from 1 to n − 1.

#### 5.1.23 The paths of dotted keys

@term dotted-key-path=v1
@cites {
    toml-lang/1.1.0,
    #{
        toml-key=v1, toml-value=v1, toml-boundary-state=v1,
        toml-boundary=v1,
    },
}

This definition uses the terms dotted key and key/value pair of
TOML 1.1.0.

For a key/value pair whose key is a dotted key with the TOML keys k1 to
kn, the path of the dotted key is the sequence of the tables to which
the TOML keys k1 to ki lead from the holding table of the key/value pair
at the boundary right after the key/value pair, for each i from 1 to
n − 1 for which they lead to a table, in the order of i.

#### 5.1.24 Undefined super-tables

@term undefined-super-table=v1
@cites {
    toml-lang/1.1.0,
    #{
        toml-boundary=v1, toml-value=v1, toml-super-table=v1,
        toml-boundary-state=v1, toml-location=v1, dotted-key-path=v1,
    },
}

This definition uses the terms document, table header, inline table, and
key/value pair of TOML 1.1.0.

At a boundary of a document, a table t is an undefined super-table when,
and only when, all of these are true:

- t is a super-table of a table that a table header before that boundary
  names.
- No table header before that boundary names t.
- t is not the table of an inline table before that boundary.
- t is not a table of the path of the dotted key of a key/value pair
  before that boundary.

#### 5.1.25 The tables that table headers define

@term header-definition=v1
@cites {toml-lang/1.1.0, #{toml-boundary-state=v1}}

This rule uses the term table header of TOML 1.1.0. A table header
defines the table that it names, and no other table.

#### 5.1.26 The tables that key/value pairs define

@term dotted-key-definition=v1
@cites {
    toml-lang/1.1.0,
    #{
        dotted-key-path=v1, toml-boundary=v1, toml-boundary-state=v1,
        toml-location=v1, undefined-super-table=v1,
    },
}

This rule uses the terms key/value pair and dotted key of TOML 1.1.0. A
key/value pair defines the tables of the path of its dotted key that, at
the boundary right before the key/value pair, do not exist or are
undefined super-tables, and no other table.

#### 5.1.27 The tables that inline tables define

@term inline-table-definition=v1
@cites toml-lang/1.1.0

This rule uses the term inline table of TOML 1.1.0. An inline table
defines its table, and no other table.

#### 5.1.28 Single definitions of tables

@term single-definition=v1
@cites {
    toml-lang/1.1.0,
    text#{code-span=v1, boundary=v1},
    #{
        header-definition=v1, dotted-key-definition=v1,
        inline-table-definition=v1, toml-location=v1,
    },
}

This rule uses the terms document, table header, key/value pair, and
inline table of TOML 1.1.0. By this rule, no two of the table headers,
the key/value pairs, and the inline tables of a document define the same
table by the rules of `header-definition`, `dotted-key-definition`, and
`inline-table-definition`. When two of them define the same table, the
one of the two that starts at the later boundary breaks this rule.

#### 5.1.29 New TOML keys

@term new-key=v1
@cites {
    toml-lang/1.1.0,
    #{
        toml-boundary=v1, toml-key=v1, toml-boundary-state=v1,
        toml-value=v1,
    },
}

This rule uses the terms document and key/value pair of TOML 1.1.0. By
this rule, at the boundary right before a key/value pair of a document,
the TOML keys of the key of the key/value pair lead from the holding
table of the key/value pair to no TOML value. A key/value pair for which
they lead to a TOML value breaks this rule.

#### 5.1.30 Paths of dotted keys and named tables

@term header-free-path=v1
@cites {
    toml-lang/1.1.0,
    #{
        dotted-key-path=v1, toml-boundary-state=v1, toml-location=v1,
        toml-boundary=v1,
    },
}

This rule uses the terms document, key/value pair, dotted key, and table
header of TOML 1.1.0. By this rule, no table of the path of the dotted
key of a key/value pair of a document is a table that a table header
before that key/value pair names. A key/value pair for which a table of
that path is such a table breaks this rule.

#### 5.1.31 Closed inline tables

@term closed-inline-table=v1
@cites {
    toml-lang/1.1.0,
    #{
        toml-boundary=v1, toml-key=v1, toml-boundary-state=v1,
        inline-table-enclosure=v1, toml-location=v1, toml-value=v1,
    },
}

This rule uses the terms document, key/value pair, table header, inline
table, and root table of TOML 1.1.0. By this rule, these statements hold
for the key/value pairs and the table headers of a document:

- At the boundary right before a key/value pair whose key has the TOML
  keys k1 to kn, for no i from 1 to n − 1 do the TOML keys k1 to ki lead
  from its holding table to the table of an inline table that does not
  enclose the key/value pair, or to a table whose location starts with
  the location of the table of such an inline table.
- At the boundary right before a table header whose key has the TOML
  keys k1 to kn, for no i from 1 to n do the TOML keys k1 to ki lead
  from the root table to the table of an inline table, or to a table
  whose location starts with the location of the table of an inline
  table.

A key/value pair or a table header for which its statement does not hold
breaks this rule.

#### 5.1.32 Tables on the way of a key

@term table-on-the-way=v1
@cites {
    toml-lang/1.1.0,
    #{
        toml-boundary=v1, toml-key=v1, toml-boundary-state=v1,
        toml-value=v1,
    },
}

This rule uses the terms document, key/value pair, table header, and
root table of TOML 1.1.0. By this rule, these statements hold for the
key/value pairs and the table headers of a document:

- At the boundary right before a key/value pair whose key has the TOML
  keys k1 to kn, for each i from 1 to n − 1, the TOML keys k1 to ki lead
  from its holding table to a table or to no TOML value.
- At the boundary right before a table header whose key has the TOML
  keys k1 to kn, for each i from 1 to n − 1, the TOML keys k1 to ki lead
  from the root table to a table or to no TOML value.

A key/value pair or a table header for which its statement does not hold
breaks this rule.

#### 5.1.33 The TOML values to which table headers lead

@term header-target=v1
@cites {
    toml-lang/1.1.0,
    #{
        toml-boundary=v1, toml-key=v1, toml-boundary-state=v1,
        toml-value=v1,
    },
}

This rule uses the terms document, table header, array of tables, and
root table of TOML 1.1.0. By this rule, at the boundary right before a
table header of a document that is not the table header of an array of
tables, the TOML keys of its key lead from the root table to a table or
to no TOML value. A table header for which they lead to a TOML value
that is not a table breaks this rule.

#### 5.1.34 The TOML values to which headers of arrays of tables lead

@term array-header-target=v1
@cites {
    toml-lang/1.1.0,
    #{
        toml-boundary=v1, toml-key=v1, toml-boundary-state=v1,
        toml-value=v1,
    },
}

This rule uses the terms document, table header, array of tables, and
root table of TOML 1.1.0. By this rule, at the boundary right before the
table header of an array of tables of a document, the TOML keys of its
key lead from the root table to no TOML value, or to a table in a TOML
array that table headers make. A table header of an array of tables for
which they lead to another TOML value breaks this rule.

#### 5.1.35 The table rules of TOML

@term toml-table-rule-list=v1
@cites {
    toml-lang/1.1.0,
    text#{code-span=v1},
    #{
        header-definition=v1, dotted-key-definition=v1,
        inline-table-definition=v1, single-definition=v1, new-key=v1,
        header-free-path=v1, closed-inline-table=v1,
        table-on-the-way=v1, header-target=v1, array-header-target=v1,
    },
}

These definitions use the terms dotted key, inline table, key/value
pair, table header, and root table of TOML 1.1.0.

- The table rules of TOML are the rules of `header-definition`,
  `dotted-key-definition`, `inline-table-definition`,
  `single-definition`, `new-key`, `header-free-path`,
  `closed-inline-table`, `table-on-the-way`, `header-target`, and
  `array-header-target`.
- The table rules of TOML replace three statements of TOML 1.1.0, or
  parts of them: that an inline table defines all the keys of TOML 1.1.0
  and the sub-tables within its braces; that dotted keys define a table
  for each TOML key of the dotted key before the last one, but not that
  dotted keys create these tables, which they still make; and that a
  table that dotted keys define has all its key/value pairs under the
  current table header, in the root table, or in one inline table.

#### 5.1.36 Structure rules

@term toml-structure-rule=v1
@cites {
    text#{code-span=v1},
    #{
        single-definition=v1, new-key=v1, header-free-path=v1,
        closed-inline-table=v1, table-on-the-way=v1, header-target=v1,
        array-header-target=v1,
    },
}

The structure rules are the rules of `single-definition`, `new-key`,
`header-free-path`, `closed-inline-table`, `table-on-the-way`,
`header-target`, and `array-header-target`.

#### 5.1.37 The texts of TOML strings

@term toml-string-text=v1
@cites {
    toml-lang/1.1.0,
    text#{text=v1},
    #{toml-value=v1, toml-string-newline=v1},
}

This definition uses the terms basic string, multi-line basic string,
literal string, multi-line literal string, and escape sequence of
TOML 1.1.0. The text of a TOML string is the text that TOML 1.1.0 gives
for its basic string, multi-line basic string, literal string, or
multi-line literal string after the escape sequences resolve, with no
change other than the trims of `toml-string-newline`.

#### 5.1.38 The local date-times of offset date-times

@term toml-offset-date-time=v1
@cites {toml-lang/1.1.0, #{toml-value=v1}}

The local date-time of an offset date-time of a document is the local
date-time that the document gives before the offset.

#### 5.1.39 Omitted seconds in TOML

@term toml-omitted-second=v1
@cites {toml-lang/1.1.0, #{toml-value=v1, toml-second-fraction=v1}}

When a document gives no second for a local time, a local date-time, or
an offset date-time, its second is 0. When a document gives no fraction
of a second for a local time, a local date-time, or an offset date-time,
its fraction of a second is 0.

#### 5.1.40 Spans in a TOML document

@term toml-span=v1
@cites {
    toml-lang/1.1.0,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        body=v1, run=v1, span=v1, code-span=v1,
    },
    #{
        toml-key=v1, toml-value=v1, toml-byte-order-mark=v1,
        dotted-key-path=v1,
    },
}

These definitions use the terms key, key/value pair, table header,
value, string, quoted key, array, inline table, and array of tables of
TOML 1.1.0, and the rules `toml`, `key`, `simple-key`, and `val` of the
ABNF of TOML 1.1.0. They apply to a byte sequence that is valid UTF-8
and for which the text of the body of its text matches the rule `toml`,
such as a TOML document. Its spans are spans of the text of the byte
sequence:

- The span of the key of a key/value pair or of a table header is the
  run that the rule `key` matches for that key.
- The span of a TOML key of such a key is the run that the rule
  `simple-key` matches for that TOML key. The run holds the quotes of a
  quoted key.
- The span of a value of TOML 1.1.0 is the run that the rule `val`
  matches for that value. The run holds the quotes of a string of
  TOML 1.1.0, the brackets of an array of TOML 1.1.0, and the braces of
  an inline table. Each element of an array of TOML 1.1.0 and the value
  of each key/value pair is a value of TOML 1.1.0.
- The TOML value that a value of TOML 1.1.0 gives has the span of that
  value. A table that a table header makes, a table of the path of a
  dotted key, a TOML array that the table headers of an array of tables
  make, and the root table have no span.

#### 5.1.41 Value errors

@term toml-value-error=v1
@cites {
    toml-lang/1.1.0,
    rfc/3339,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        body=v1, character=v1, code-point=v1, code-span=v1,
    },
    #{
        toml-integer-range=v1, toml-float-overflow=v1,
        toml-leap-second=v1, toml-nesting-limit=v1, toml-value=v1,
    },
}

These definitions use the terms value, integer, float, local date, local
time, local date-time, offset date-time, string, escape sequence, array,
and inline table of TOML 1.1.0, and the rule `toml` of the ABNF of
TOML 1.1.0. They apply to a byte sequence that is valid UTF-8 and for
which the text of the body of its text matches the rule `toml`.

- A value error of such a byte sequence is each value of TOML 1.1.0 in
  the body of its text that is one of these: an integer of TOML 1.1.0
  that is outside the range of a TOML integer; a float of TOML 1.1.0
  that rounds to an infinity; a local date, a local time, a local
  date-time, or an offset date-time of TOML 1.1.0 whose year, month,
  day, hour, minute, second, or offset is outside the range that
  RFC 3339, sections 5.6 and 5.7, allows, with the rule
  `toml-leap-second` in place of the statement of RFC 3339 on leap
  seconds; a string of TOML 1.1.0 that has an escape sequence whose
  digits in base 16 write a number that is not the code point of a
  character; and an array of TOML 1.1.0 or an inline table that has a
  depth greater than 64.
- A value error gives no TOML value, and neither does an array of
  TOML 1.1.0 that has an element that gives no TOML value.

#### 5.1.42 Key errors

@term toml-key-error=v1
@cites {
    toml-lang/1.1.0,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        body=v1, code-span=v1,
    },
    #{toml-key=v1, toml-key-text=v1, toml-nesting-limit=v1},
}

This definition uses the terms key, key/value pair, and table header of
TOML 1.1.0, and the rule `toml` of the ABNF of TOML 1.1.0. It applies to
a byte sequence that is valid UTF-8 and for which the text of the body
of its text matches the rule `toml`. A key error of such a byte sequence
is each of these:

- the key of a key/value pair or of a table header with more than 64
  TOML keys;
- a TOML key that has no text.

#### 5.1.43 Structure errors

@term toml-structure-error=v1
@cites {
    toml-lang/1.1.0,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        body=v1, code-span=v1,
    },
    #{toml-structure-rule=v1},
}

This definition uses the terms key/value pair and table header of
TOML 1.1.0, and the rule `toml` of the ABNF of TOML 1.1.0. It applies to
a byte sequence that is valid UTF-8 and for which the text of the body
of its text matches the rule `toml`. A structure error of such a byte
sequence is each key/value pair and each table header in the body of its
text that breaks a structure rule.

#### 5.1.44 TOML documents

@term toml-document=v1
@cites {
    toml-lang/1.1.0,
    text#{byte-sequence=v1, text=v1, code-span=v1},
    #{
        toml-reading-rule-list=v1, toml-value-error=v1,
        toml-key-error=v1, toml-structure-error=v1,
    },
}

This definition uses the rule `toml` of the ABNF of TOML 1.1.0. A TOML
document is a byte sequence that meets each of these conditions:

- TOML 1.1.0, with the reading rules of TOML, reads a text for the byte
  sequence, and that text matches the rule `toml`.
- The byte sequence has no value error, no key error, and no structure
  error.

#### 5.1.45 Root tables

@term root-table=v1
@cites {
    toml-lang/1.1.0,
    text#{code-span=v1},
    #{
        toml-document=v1, toml-reading-rule-list=v1,
        toml-table-rule-list=v1, toml-string-text=v1,
        toml-offset-date-time=v1, toml-omitted-second=v1,
        toml-value=v1, dotted-key-path=v1,
    },
}

This definition uses the terms root table, table header, dotted key,
inline table, and array of tables of TOML 1.1.0. The root table of a
TOML document is the root table that TOML 1.1.0 gives for the document,
with the reading rules of TOML and the table rules of TOML, and with the
rules of `toml-string-text`, `toml-offset-date-time`, and
`toml-omitted-second`. In this root table, each table that a table
header makes, each table of the path of a dotted key, and the table of
each inline table is a TOML value of the kind table, and each TOML array
that the table headers of an array of tables make, and each TOML array
that the brackets `[` and `]` around TOML values make, is a TOML value
of the kind TOML array.

### 5.2 TOML documents as input

@req read-toml=v1
@cites {
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        result=v1,
    },
    #{
        toml-value=v1, toml-value-equality=v1, root-table=v1,
        toml-document=v1,
    },
}

For each byte sequence that is a TOML document, a conforming program
must give the result "valid" and a table that is equal to the root table
of the TOML document, and no other result and no other table. For every
other byte sequence, it must give the result "invalid", and no other
result and no table. A conforming program gives a table when it gives
something that stands for that table, and for no table that is not equal
to that table.

### 5.3 Spans as output

@req give-toml-spans=v1
@cites {
    toml-lang/1.1.0,
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        result=v1, span=v1, position=v1,
    },
    #{
        toml-document=v1, toml-key=v1, toml-key-text=v1, toml-span=v1,
        toml-value=v1, toml-location=v1, toml-boundary-state=v1,
        index=v1,
    },
}

When a conforming program gives the result "valid" for a byte sequence
as a TOML document, it must give with that result the start and the end
of each of these spans, each as a line number and a column, together
with what the span is the span of, and it must give no other pair of a
span and what it is the span of, and no other line number and no other
column, with that result:

- for each TOML value of the document that has a span, its span, as the
  span of the TOML value at the location of that TOML value;
- for the key of each key/value pair of the document, its span, as the
  span of the key of TOML 1.1.0 that leads to the location of these
  steps: the steps of the location of the holding table of the
  key/value pair, then the texts of the TOML keys of that key, in their
  order;
- for the key of each table header of the document, its span, as the
  span of the key of TOML 1.1.0 that leads to the location of the table
  that the table header names;
- for each TOML key of each of these keys, its span, as the span of the
  TOML key with the index i of the key of TOML 1.1.0 that leads to that
  location, where i is the index of that TOML key among the TOML keys of
  that key.

A conforming program gives a TOML value, a key, a TOML key, or a
location of this list when it gives something that stands for it, and
for no other TOML value, key, TOML key, or location.

### 5.4 Conformance

A program conforms to the specification `toml` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The vectors of this specification are in the file
[`data-forms.toml.test-vectors.jsonl`](data-forms.toml.test-vectors.jsonl),
in the same directory as this design. The file is a test-vector set, as
section 8 defines it. Each line of the file is the canonical byte
sequence of one object, then the byte 0x0A, so each line is a JSON text,
as RFC 8259 defines it. Only a line feed ends a line of the file. A
string of the file can hold U+0085, U+2028, or U+2029, and these
characters do not end a line.

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
gives the forms of one or more groups, as section 8 defines them: the
requirements of the group, and what the members `input`, `result`, and
`values` of its vectors stand for, each in a fixed form.

In `input` and `values`, these fixed forms apply:

- A byte sequence is its hex text, as a string. So the UTF-8 encoding of
  `a = 1` and a line feed is `"61203d20310a"`.
- A position is an object with two members: `line`, the line number,
  and `column`, the column, each as an integer. So the position line 2,
  column 5 is `{"column":5,"line":2}`.
- A location is an array of its steps, in order: the text of a TOML key
  as a string, and an index as an integer. So the location of the TOML
  integer 2 in the text `a = [1, { b = 2 }]` is `["a",2,"b"]`, and the
  location of the root table is the empty array, `[]`.
- The form of a table is an object with one member for each pair that
  the table holds. The key of the member is the text of the TOML key of
  the pair, and the value of the member is the form of the TOML value of
  the pair.
- The form of a TOML value is an object with one member. The key of
  that member names the kind of the TOML value, and its value gives the
  TOML value, as this table and the two paragraphs below it say.

| kind of the TOML value | key of the member | value of the member |
|---|---|---|
| TOML string | `string` | the text of the TOML string, as a string |
| TOML integer | `integer` | a string of the decimal numeral of the absolute value of the TOML integer, after `-` when the TOML integer is less than 0, such as `"-17"` |
| TOML float | `float` | a string, in the form that the first paragraph below gives |
| TOML boolean | `boolean` | `true` or `false` |
| local date | `local-date` | a string, in the form that the second paragraph below gives |
| local time | `local-time` | a string, in the form that the second paragraph below gives |
| local date-time | `local-date-time` | a string, in the form that the second paragraph below gives |
| offset date-time | `offset-date-time` | a string, in the form that the second paragraph below gives |
| TOML array | `array` | an array of the forms of the TOML values of the TOML array, in the order of their indexes |
| table | `table` | the form of the table |

The string of a TOML float is `nan` for NaN, `inf` for positive
infinity, `-inf` for negative infinity, and `-0` for negative zero. For
each other TOML float, the string is the exact value of the TOML float
in base 10: `-` when the value is less than 0; then the decimal numeral
of the whole-number part of its absolute value; then, when the absolute
value is not a whole number, `.` and the digits of the fractional part,
with no `0` at the end. So positive zero is `"0"`, the TOML float 0.5 is
`"0.5"`, and the TOML float 100,000,000,000,000,000,000 is
`"100000000000000000000"`.

The string of a local date is the year as four digits, `-`, the month
as two digits, `-`, and the day as two digits, such as `"1600-02-29"`.
The string of a local time is the hour, `:`, the minute, `:`, and the
second, each as two digits; then, when the fraction of the second is not
0, `.` and the digits of the fraction after the decimal point, with no
`0` at the end. So the local time of `12:30` is `"12:30:00"`, and the
local time of `12:30:00.50` is `"12:30:00.5"`. The string of a local
date-time is the string of its local date, `T`, and the string of its
local time. The string of an offset date-time is the string of its local
date-time, then its offset: `+00:00` for the offset 0, and `-00:00` for
the unknown local offset. For each other offset, the string of the
offset is `+` when the offset is greater than 0, and `-` when it is less
than 0; then the whole-number quotient of the absolute value of the
offset divided by 60, and the remainder, each as two digits, with `:`
between them. So the offset
date-time of `1979-05-27T07:32:00Z` is `"1979-05-27T07:32:00+00:00"`,
and the offset date-time of `1979-05-27T00:32:00-07:00` is
`"1979-05-27T00:32:00-07:00"`.

So the form of the root table in which `a` holds a table in which `b`
holds the TOML integer 1 is `{"a":{"table":{"b":{"integer":"1"}}}}`. Two
tables are equal when, and only when, their forms are the same JSON
value.

#### 5.4.1 TOML documents

Each vector of the groups `give-root-table` and `reject-byte-sequence`
gives a byte sequence and what a conforming program gives for it as a
TOML document. The byte sequence decides which of the two groups holds
the vector. Together, the vectors of the two groups test which byte
sequences are TOML documents, and the root tables of TOML documents.
The vectors of the group `reject-byte-sequence` give byte sequences
that are not valid UTF-8, byte sequences whose text does not match the
rule `toml`, and byte sequences with a value error, a key error, or a
structure error.

The group `give-root-table` holds the vectors that each give a TOML
document and its root table. The requirement of the group is
`read-toml`.

- `input`: the byte sequence of the TOML document.
- `result`: "valid".
- `values`: an object with one member, `root-table`: the form of the
  root table of the TOML document.

With the result "valid", a conforming program gives a table whose form
is the form of `root-table`, and no other table.

```
{"group":"give-root-table","input":"61203d20310a","n":1,"result":"valid","rev":"v1","values":{"root-table":{"a":{"integer":"1"}}}}
```

The group `reject-byte-sequence` holds the vectors that each give a
byte sequence that is not a TOML document. The requirement of the group
is `read-toml`.

- `input`: the byte sequence.
- `result`: "invalid".
- `values`: the empty object, `{}`.

When `values` is `{}`, a conforming program gives no table. A vector of
the group states nothing about a position that a conforming program
gives with the result "invalid".

```
{"group":"reject-byte-sequence","input":"61203d20393232333337323033363835343737353830380a","n":30,"note":"the integer of TOML 1.1.0 stands for a number greater than 9,223,372,036,854,775,807","result":"invalid","rev":"v1","values":{}}
```

#### 5.4.2 Spans

The group `give-span` holds the vectors that each give a TOML document
and one of the spans that a conforming program gives for it with the
result "valid", together with what the span is the span of. The
requirements of the group are `read-toml` and `give-toml-spans`.

- `input`: the byte sequence of the TOML document.
- `result`: "valid".
- `values`: an object with these members:
  - `of`: a string that says what the span is the span of: `toml-value`
    for the TOML value at the location of `location`; `key` for the key
    of TOML 1.1.0 that leads to that location; or `toml-key` for the
    TOML key with the index of `index` of the key of TOML 1.1.0 that
    leads to that location.
  - `location`: a location.
  - `index`: an index, as an integer. Only a vector whose member `of`
    holds `toml-key` has this member.
  - `start`: the start of the span, as a position.
  - `end`: the end of the span, as a position.

With the result "valid", a conforming program gives the line numbers and
the columns of `start` and `end` as the start and the end of the span of
what `of`, `location`, and `index` name. A vector of the group states
nothing about the other spans that a conforming program gives for the
TOML document. The note of each vector gives the text of the span.

```
{"group":"give-span","input":"61203d20310a","n":104,"note":"the text of the span is `a`","result":"valid","rev":"v1","values":{"end":{"column":2,"line":1},"index":1,"location":["a"],"of":"toml-key","start":{"column":1,"line":1}}}
{"group":"give-span","input":"61203d205b312c205b322c20335d5d0a","n":119,"note":"the text of the span is `1`","result":"valid","rev":"v1","values":{"end":{"column":7,"line":1},"location":["a",1],"of":"toml-value","start":{"column":6,"line":1}}}
```

The group `omit-span` holds the vectors that each give a TOML document
and the location of a TOML value of it that has no span. The
requirements of the group are `read-toml` and `give-toml-spans`.

- `input`: the byte sequence of the TOML document.
- `result`: "valid".
- `values`: an object with one member, `no-span-at`: a location.

With the result "valid", a conforming program gives no span as the span
of the TOML value at the location of `no-span-at`.

```
{"group":"omit-span","input":"5b615d0a62203d20310a","n":140,"note":"a table header makes the table `a`","result":"valid","rev":"v1","values":{"no-span-at":["a"]}}
```

## 6. Hashes
@spec hashes=v1

For each byte sequence of fewer than 2^61 bytes, a conforming program
gives its hash. For each text, it gives "valid" when the text fits the
hash form, and "invalid" when it does not.

FIPS 180-4 defines SHA-256 for each message of fewer than 2^64 bits, so
it gives a digest for each byte sequence of fewer than 2^61 bytes. The
digest of such a byte sequence is the 32 bytes of the message digest
that SHA-256 gives for it. The hash of the byte sequence is the hex text
of its digest: 64 hex digits. For example, the hash of the three bytes
of `abc` is
`ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`.

A text fits the hash form when it holds exactly 64 hex digits and
nothing else. Upper-case letters are not hex digits, so
`BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD` does
not fit the hash form.

### 6.1 Definitions

#### 6.1.1 The hash form

@term hash-form=v1
@cites text#{
    production=v1, rule-name=v1, hex-digit=v1, text=v1, code-span=v1,
}

A text fits the hash form when, and only when, it matches the production
`hash-form`:

```abnf
hash-form  = 64hex-digit
```

### 6.2 Hashes as output

@req compute-hash=v1
@cites {
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        text=v1,
    },
    #{hash=v1},
}

For each byte sequence of fewer than 2^61 bytes, a conforming program
must give the hash of that byte sequence, and no other text, as the hash
of that byte sequence.

### 6.3 The validation of hashes

@req validate-hash=v1
@cites {
    text#{requirement=v1, conforming-program=v1, text=v1, result=v1},
    #{hash-form=v1},
}

For each text, a conforming program must give exactly one result:
"valid" when the text fits the hash form, and "invalid" when the text
does not fit the hash form.

### 6.4 Conformance

A program conforms to the specification `hashes` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The vectors of this specification are in the file
[`data-forms.hashes.test-vectors.jsonl`](data-forms.hashes.test-vectors.jsonl),
in the same directory as this design. The file is a test-vector set, as
section 8 defines it. Each line of the file is the canonical byte
sequence of one object, then the byte 0x0A, so each line is a JSON text,
as RFC 8259 defines it. Only a line feed ends a line of the file. A
string of the file can hold U+0085, U+2028, or U+2029, and these
characters do not end a line.

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
gives the forms of one group, as section 8 defines them: the
requirements of the group, and what the members `input`, `result`, and
`values` of its vectors stand for, each in a fixed form. A vector
without the member `result` states no result. A vector without the
member `values` states nothing that a conforming program gives for the
input, other than its result. In `input` and `values`, a byte sequence
is its hex text, as a string, such as `"616263"` for the three bytes of
`abc`, and a text is a string of the characters of the text.

#### 6.4.1 Hashes

The group `compute` holds the vectors that each give a byte sequence and
its hash. The requirement of the group is `compute-hash`.

- `input`: the byte sequence.
- `result`: no vector of the group has this member.
- `values`: an object with one member, `hash`: the hash of the byte
  sequence, as a text.

A conforming program gives the text of `hash` as the hash of the byte
sequence, and no other text.

```
{"group":"compute","input":"616263","n":2,"rev":"v1","values":{"hash":"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"}}
```

#### 6.4.2 The hash form

The group `validate` holds the vectors that each give a text and the
result that a conforming program gives for it when it validates the text
as a hash. The requirement of the group is `validate-hash`.

- `input`: the text.
- `result`: "valid" when the text fits the hash form, and "invalid" when
  it does not.
- `values`: no vector of the group has this member.

```
{"group":"validate","input":"BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD","n":6,"note":"upper-case letters are not hex digits","result":"invalid","rev":"v1"}
```

## 7. Hash ids
@spec hash-ids=v1

For an id prefix, a number of hex digits from 1 to 64, and a byte
sequence of fewer than 2^61 bytes, a conforming program gives the hash
id. For a text, an id prefix, and a number of hex digits, it gives
"valid" when the text fits the hash-id form, and "invalid" when it does
not.

An id prefix is one or more of the letters `a` to `z`, and then `-`,
such as `e-` or `t-`. For an id prefix, a number n of hex digits from 1
to 64, and a byte sequence of fewer than 2^61 bytes, the hash id is the
id prefix, then the first n hex digits of the hash of the byte sequence.
For example, with the id prefix `e-` and 12 hex digits, the hash id of
the three bytes of `abc` is `e-ba7816bf8f01`.

A text fits the hash-id form with an id prefix and a number n of hex
digits when it is the id prefix and then exactly n hex digits. So with
the id prefix `e-` and 12 hex digits, `e-5b1c0a9d2e11` fits the hash-id
form, and `e-5b1c0a9d2e1`, `e-5B1C0A9D2E11`, and `t-5b1c0a9d2e11` do
not.

### 7.1 Definitions

#### 7.1.1 Id prefixes

@term id-prefix=v1
@cites text#{production=v1, rule-name=v1, text=v1, code-span=v1}

An id prefix is a text that matches the production `id-prefix`:

```abnf
id-prefix  = 1*%x61-7A "-"
```

#### 7.1.2 Hash ids

@term hash-id=v1
@cites {
    text#{whole-number=v1, byte-sequence=v1, text=v1, character=v1},
    #{id-prefix=v1, hash=v1},
}

For an id prefix p, a whole number n from 1 to 64, and a byte sequence b
of fewer than 2^61 bytes, the hash id of b with p and n is the text p,
then the first n characters of the hash of b.

#### 7.1.3 The hash-id form

@term hash-id-form=v1
@cites {
    text#{whole-number=v1, text=v1, character=v1, hex-digit=v1},
    #{id-prefix=v1},
}

For an id prefix p and a whole number n from 1 to 64, a text fits the
hash-id form with p and n when, and only when, it is the text p, then
exactly n characters that are each a hex digit.

### 7.2 Hash ids as output

@req compute-hash-id=v1
@cites {
    text#{
        requirement=v1, conforming-program=v1, whole-number=v1,
        byte-sequence=v1, text=v1,
    },
    #{id-prefix=v1, hash-id=v1},
}

For each id prefix p, each whole number n from 1 to 64, and each byte
sequence b of fewer than 2^61 bytes, a conforming program must give the
hash id of b with p and n, and no other text, as the hash id of b with p
and n.

### 7.3 The validation of hash ids

@req validate-hash-id=v1
@cites {
    text#{
        requirement=v1, conforming-program=v1, text=v1,
        whole-number=v1, result=v1,
    },
    #{id-prefix=v1, hash-id-form=v1},
}

For each text t, each id prefix p, and each whole number n from 1 to 64,
a conforming program must give exactly one result: "valid" when t fits
the hash-id form with p and n, and "invalid" when t does not fit the
hash-id form with p and n.

### 7.4 Conformance

A program conforms to the specification `hash-ids` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The vectors of this specification are in the file
[`data-forms.hash-ids.test-vectors.jsonl`](data-forms.hash-ids.test-vectors.jsonl),
in the same directory as this design. The file is a test-vector set, as
section 8 defines it. Each line of the file is the canonical byte
sequence of one object, then the byte 0x0A, so each line is a JSON text,
as RFC 8259 defines it. Only a line feed ends a line of the file. A
string of the file can hold U+0085, U+2028, or U+2029, and these
characters do not end a line.

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
gives the forms of one group, as section 8 defines them: the
requirements of the group, and what the members `input`, `result`, and
`values` of its vectors stand for, each in a fixed form. A vector
without the member `result` states no result. A vector without the
member `values` states nothing that a conforming program gives for the
input, other than its result. In `input` and `values`, a byte sequence
is its hex text, as a string, such as `"616263"` for the three bytes of
`abc`; a text, such as an id prefix, is a string of the characters of
the text; and a whole number is an integer.

#### 7.4.1 Hash ids

The group `compute` holds the vectors that each give an id prefix, a
number of hex digits, a byte sequence, and the hash id of the byte
sequence with that id prefix and that number of hex digits. The
requirement of the group is `compute-hash-id`.

- `input`: an object with three members: `id-prefix`, the id prefix;
  `number-of-hex-digits`, the number of hex digits; and
  `byte-sequence`, the byte sequence.
- `result`: no vector of the group has this member.
- `values`: an object with one member, `hash-id`: the hash id, as a
  text.

A conforming program gives the text of `hash-id` as the hash id of the
byte sequence with the id prefix and the number of hex digits, and no
other text.

```
{"group":"compute","input":{"byte-sequence":"616263","id-prefix":"e-","number-of-hex-digits":12},"n":1,"rev":"v1","values":{"hash-id":"e-ba7816bf8f01"}}
```

#### 7.4.2 The hash-id form

The group `validate` holds the vectors that each give a text, an id
prefix, a number of hex digits, and the result that a conforming program
gives for them when it validates the text as a hash id. The requirement
of the group is `validate-hash-id`.

- `input`: an object with three members, one for each of the three
  inputs: `text`, the text; `id-prefix`, the id prefix; and
  `number-of-hex-digits`, the number of hex digits.
- `result`: the result of the three inputs together: "valid" when the
  text fits the hash-id form with the id prefix and the number of hex
  digits, and "invalid" when it does not.
- `values`: no vector of the group has this member.

```
{"group":"validate","input":{"id-prefix":"e-","number-of-hex-digits":12,"text":"e-5b1c0a9d2e1"},"n":6,"note":"11 hex digits","result":"invalid","rev":"v1"}
```

## 8. Test vectors
@spec test-vectors=v1

A vector of a specification is an input and what requirements of that
specification oblige a conforming program of that specification to give
for that input. A test-vector set is a byte sequence that holds vectors
of one specification of a design, or of the requirements that a design
holds outside its specifications. A conforming program reads a byte
sequence as a test-vector set. It also validates a sequence of versions
of the vectors as a version sequence: a sequence of versions, from the
earliest to the latest, whose revisions follow the changes of the
vectors.

For a design with the name `a` and a specification of that design with
the name `b`, the test-vector file name of `a` and `b` is
`a.b.test-vectors.jsonl`, and the test-vector file name of `a` alone is
`a.test-vectors.jsonl`.

A test-vector set holds JSON objects as their canonical byte sequences,
each then the byte 0x0A, so a test-vector set has exactly one form for
its objects. It starts with its set line, which holds the set object,
such as `{"rev":"v3"}`, with the revision of the whole test-vector set.
Then it holds one group line for each group, such as
`{"group":"offsets","rev":"v2"}`, in the key order of the group names.
Then it holds one vector line for each vector, in increasing order of
the numbers `n` of the vectors, such as
`{"group":"offsets","input":"x","n":12,"result":"valid","rev":"v1"}`.
The objects of the vector lines can hold any JSON value in `input` and
in `values`, so a vector object need not be a line object.

The forms of its group give the meaning of each vector line. The forms
of a group are four things that the Conformance section of the design of
the vectors gives for that group, or, for the vectors of a
specification, the Conformance part of that specification. The text of
the forms of a group is the whole text of that Conformance section or
part, so a change anywhere in it changes the forms of every group that
it gives:

1. the requirements of the group, from which the vectors of the group
   follow;
2. what the value of `input` stands for: one input of a conforming
   program, such as a byte sequence as its hex text, or several inputs,
   such as a text and a place of that text;
3. which of these inputs, or which of them together, the value of
   `result` is the result of, and the conditions under which the
   requirements oblige that result, if any, such as that a conforming
   program gives a result for that input, or a condition on the run of
   the program;
4. what the value of `values` stands for, such as the results of the
   other inputs. It can stand for a thing that a conforming program
   gives when it gives a thing of that kind, for things of which a
   conforming program gives one in place of another, and for a thing
   that a conforming program does not give.

By the forms of its group, the object of a vector line states an input
and what the requirements of the group oblige a conforming program to
give for that input. The value of `result` is the result that these
requirements oblige a conforming program to give for the input, or for
the inputs together, that the forms name for `result`, whenever the
conditions hold that the forms name for that result. The value of
`values` stands for what these requirements oblige a conforming program
to give for the input, other than the result that the value of `result`
stands for, such as the results of the other inputs. A vector object
without the member `result` states no result other than those that the
value of `values` stands for, and a vector object without the member
`values` states nothing about what a conforming program gives for the
input, other than the result that the value of `result` stands for. Each
vector object has the member `result` or the member `values`, or both.
The value of `note` explains the vector, and it is no part of the input,
the result, or the values.

Each vector, each group, and the whole test-vector set have a revision,
such as `v2`. The forms of a group are part of the meaning of each
vector of the group. So a version of the vectors is a test-vector set
together with the forms of each of its groups, given as texts: the whole
text of the Conformance section or part that gives them. From one
version to the next, when the group, the input, the result, or the
values of a vector change, the revision of the vector rises. So does the
revision of the group of the vector in each of the two versions, when
that group is in both versions, and so does the revision of the
test-vector set. When the forms of a group that is in both versions
change, the revision of each vector that has that group in both versions
rises, and so do the revision of the group and the revision of the
test-vector set. When a vector joins or leaves the test-vector set, the
revision of the test-vector set rises, and so does the revision of the
group of the vector when that group is in both versions. Without such a
change, no revision changes, so a change of a note alone changes no
revision. A revision can rise by more than 1. A new vector, and a group
that is in no earlier version, can have any revision. A group that comes
back after it left gets a revision higher than each revision that it had
before. A number `n` is given once: a vector that leaves takes its
number with it, and a new vector gets a number greater than each number
before it.

### 8.1 Definitions

#### 8.1.1 Test-vector file names

@term test-vector-file-name=v1
@cites text#{design=v1, specification=v1, text=v1, code-span=v1}

For the name x of a design and the name a of a specification of that
design, the test-vector file name of x and a is the text x, then `.`,
then the text a, then `.test-vectors.jsonl`. For the name x of a design,
the test-vector file name of x alone is the text x, then
`.test-vectors.jsonl`. So, for a design with the name `a` and a
specification of that design with the name `b`, the test-vector file
name of `a` and `b` is `a.b.test-vectors.jsonl`, and the test-vector
file name of `a` alone is `a.test-vectors.jsonl`.

#### 8.1.2 Test-vector revisions

@term test-vector-revision=v1
@cites text#{
    production=v1, rule-name=v1, decimal-numeral=v1, whole-number=v1,
    text=v1, code-span=v1,
}

A test-vector revision is a text that matches the production
`test-vector-revision`:

```abnf
test-vector-revision  = %s"v" %x31-39 *DIGIT
```

The number of a test-vector revision is the whole number that the
decimal numeral after its `v` writes. A test-vector revision r is higher
than a test-vector revision s when, and only when, the number of r is
greater than the number of s.

#### 8.1.3 Group names

@term group-name=v1
@cites text#{production=v1, rule-name=v1, text=v1, code-span=v1}

A group name is a text that matches the production `group-name`:

```abnf
group-name  = %x61-7A *( %x61-7A / DIGIT ) *( "-" 1*( %x61-7A / DIGIT ) )
```

#### 8.1.4 Vector objects, group objects, and set objects

@term vector-object=v1
@cites {
    text#{text=v1, code-span=v1},
    #{json-value=v1, test-vector-revision=v1, group-name=v1},
}

A member that a code span names, such as the member `n`, is the member
whose key is the text of the code span, and the value of `n` is the
value of the member `n`.

- A vector object is an object that has the members `n`, `rev`, `group`,
  and `input`, has the member `result` or the member `values` or both,
  can have the member `note`, and has no other member. The value of `n`
  is an integer of 1 or more. The value of `rev` is a string that is a
  test-vector revision. The value of `group` is a string that is a group
  name. The value of `input` is a JSON value. The value of `result` is a
  string. The value of `values` is a JSON value. The value of `note` is
  a string.
- A group object is an object that has the members `group` and `rev`,
  and no other member. The value of `group` is a string that is a group
  name. The value of `rev` is a string that is a test-vector revision.
- A set object is an object that has the member `rev`, and no other
  member. The value of `rev` is a string that is a test-vector revision.

#### 8.1.5 Vector lines, group lines, and set lines

@term vector-line=v1
@cites {
    text#{byte=v1, 0x-numeral=v1, code-span=v1},
    #{json-value=v1, canonical-byte-sequence=v1, vector-object=v1},
}

A vector line is the canonical byte sequence of a vector object, then
the byte 0x0A. A group line is the canonical byte sequence of a group
object, then the byte 0x0A. A set line is the canonical byte sequence of
a set object, then the byte 0x0A. The object of a vector line, of a
group line, or of a set line is the object whose canonical byte sequence
it holds. The number of a vector line is the value of `n` of its object.
The group of a vector line or of a group line is the value of `group` of
its object. The revision of a vector line, of a group line, or of a set
line is the value of `rev` of its object.

#### 8.1.6 Test-vector sets

@term test-vector-set=v1
@cites {
    text#{byte-sequence=v1, byte=v1, text=v1},
    #{key-order=v1, vector-line=v1},
}

A test-vector set is a byte sequence that holds, in this order, and no
other bytes: one set line; then zero or more group lines; then zero or
more vector lines, each with a greater number than the vector line
before it. The group lines are one group line for each text that is the
group of one of these vector lines, and no other group line, in the key
order of their groups. A group of a test-vector set is the group of one
of its group lines. The vector lines of a group of a test-vector set are
its vector lines whose group is that group. The revision of a group of a
test-vector set is the revision of the group line of that group, and
the revision of a test-vector set is the revision of its set line.

#### 8.1.7 The forms of a group

@term group-form-list=v1
@cites {
    text#{
        design=v1, specification=v1, requirement=v1,
        conforming-program=v1, input=v1, result=v1, text=v1, place=v1,
        byte-sequence=v1, line=v1, code-span=v1,
    },
    #{json-value=v1, hex-text=v1, group-name=v1, vector-object=v1},
}

For a specification S of a design and a group name g, the forms of the
group g of S are these four things, which the Conformance part of S
gives for g, and the text of these forms is the whole text of that
Conformance part:

1. the requirements of the group g, which are requirements that S
   declares;
2. what the value of `input` of a vector object in which the value of
   `group` is g stands for: one input of a conforming program of S, or
   several inputs of it, such as a text and a place of that text; and
   the fixed form in which the value of `input` holds them, such as the
   hex text of a byte sequence;
3. which of these inputs, or which of them together, the value of
   `result` of such a vector object is the result of; and the conditions
   under which the requirements of the group g oblige that result, if
   they oblige it only under some conditions, such as that a conforming
   program of S gives a result for that input, or a condition on the run
   of the program;
4. what the value of `values` of such a vector object stands for: what
   a conforming program of S gives, or does not give, for these inputs,
   other than the result that the value of `result` stands for, such as
   the results of the other inputs; and the fixed form in which the
   value of `values` holds it. The value of `values` can stand for a
   thing that the program gives when it gives a thing of that kind,
   such as the text of a byte sequence when the program gives a text
   for that byte sequence; for things of which the program gives one in
   place of another, such as a line and the text of that line; and for
   a thing that the program does not give.

For a design D and a group name g, the forms of the group g of D are the
same four things, which the Conformance section of D gives for g, with
the requirements that D holds outside its specifications in place of the
requirements that S declares, and with a conforming program of D in
place of a conforming program of S. The text of these forms is the
whole text of the Conformance section of D.

#### 8.1.8 The meaning of a vector

@term vector-meaning=v1
@cites {
    text#{
        design=v1, specification=v1, requirement=v1,
        conforming-program=v1, input=v1, result=v1, code-span=v1,
    },
    #{
        json-value=v1, vector-object=v1, vector-line=v1,
        test-vector-set=v1, group-form-list=v1,
    },
}

For a specification S of a design, a vector of S is an input and what
requirements that S declares oblige a conforming program of S to give
for that input, and a test-vector set of S is a test-vector set that
holds vectors of S. For a design D, a vector of D is an input and what
requirements that D holds outside its specifications oblige a
conforming program of D to give for that input, and a test-vector set
of D is a test-vector set that holds vectors of D.

For a vector line of a test-vector set of S, or of D, and the group g of
that vector line, the object of the vector line states one vector of S,
or of D, by the forms of the group g of S, or of D. By these forms, the
object states this:

- The input of the vector is what the value of `input` stands for: one
  input of a conforming program of S, or of D, or several.
- The value of `result` is the text of a result, without the double
  quotes that a requirement writes around that result, such as `valid`
  for the result "valid".
- When the object has the member `result`, the requirements of the group
  g oblige a conforming program of S, or of D, to give the value of
  `result`, and no other result, as its result for the input, or for
  the inputs together, that the forms name for `result`, whenever the
  conditions hold that the forms name for that result; when the forms
  name no condition, they oblige it always. The object states nothing
  about a result for another of these inputs, other than what the value
  of `values` stands for.
- When the object has the member `values`, the requirements of the
  group g oblige a conforming program of S, or of D, to give, for the
  input of the vector, what the value of `values` stands for.
- An object without the member `result` states no result other than
  those that the value of `values` stands for. An object without the
  member `values` states nothing about what a conforming program gives
  for the input of the vector, other than the result that the value of
  `result` stands for.
- The value of `note` explains the vector, and it is no part of the
  input, the result, or the values.

#### 8.1.9 Version sequences

@term test-vector-version-sequence=v1
@cites {
    text#{byte-sequence=v1, text=v1, code-span=v1},
    #{
        json-value=v1, vector-object=v1, vector-line=v1,
        test-vector-set=v1, test-vector-revision=v1,
        canonical-byte-sequence=v1, group-form-list=v1,
    },
}

A version is a test-vector set together with a text for each group of
that test-vector set: the text of the forms of that group in that
version, which is the whole text of the Conformance section or part
that gives these forms. The vector lines, the groups, and the revision
of a version are those of its test-vector set, and the revision of a
group in a version is the revision of that group of its test-vector
set.

A version sequence is a finite sequence of versions, from the earliest
to the latest, in which each of the rules of this definition holds for
each version l after the first version and the version e right before
it. In the rules, a vector line of l changes when e holds a vector line
with the same number, and one of these is true:

- For one of the members `group`, `input`, `result`, and `values`, only
  one of the objects of these two vector lines has that member, or both
  have it and the canonical byte sequences of the values of that member
  in the two objects differ.
- The forms of the group of the vector line of e, in e, and the forms of
  the group of the vector line of l, in l, are different texts.

These are the rules:

- Each number of a vector line of l that is the number of no vector line
  of e is greater than the number of each vector line of each version
  before l.
- The revision of each vector line of l that changes is higher than the
  revision of the vector line of e with the same number. The revision of
  each other vector line of l whose number is the number of a vector
  line of e is the same as the revision of that vector line of e.
- For each group of both e and l: when a vector line of l of that group
  changes, when l has a vector line of that group whose number is the
  number of no vector line of that group in e, or when e has a vector
  line of that group whose number is the number of no vector line of
  that group in l, the revision of that group in l is higher than its
  revision in e. Otherwise, the revision of that group in l is the same
  as its revision in e.
- For each group of l that is not a group of e, the revision of that
  group in l is higher than its revision in each version before l that
  has that group.
- When a vector line of l changes, or when e or l has a vector line
  whose number is the number of no vector line of the other version, the
  revision of l is higher than the revision of e. Otherwise, the
  revision of l is the same as the revision of e.

### 8.2 Test-vector sets as input

@req read-test-vector-set=v1
@cites {
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        result=v1,
    },
    #{json-value=v1, vector-line=v1, test-vector-set=v1},
}

For each byte sequence that is a test-vector set, a conforming program
must give the result "valid" and the objects of the set line, the group
lines, and the vector lines of the byte sequence, in their order, and no
other result and no other object. For every other byte sequence, it must
give the result "invalid", and no other result and no object.

### 8.3 The validation of version sequences

@req validate-version-sequences=v1
@cites {
    text#{requirement=v1, conforming-program=v1, result=v1},
    #{test-vector-version-sequence=v1},
}

For each finite sequence of versions, a conforming program must give
the result "valid", and no other result, when the sequence is a version
sequence, and the result "invalid", and no other result, when the
sequence is not a version sequence.

### 8.4 Conformance

A program conforms to the specification `test-vectors` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The vectors of this specification are in the file
[`data-forms.test-vectors.test-vectors.jsonl`](data-forms.test-vectors.test-vectors.jsonl),
in the same directory as this design. The file is a test-vector set, as
section 8 defines it. Each line of the file is the canonical byte
sequence of one object, then the byte 0x0A, so each line is a JSON text,
as RFC 8259 defines it. Only a line feed ends a line of the file. A
string of the file can hold U+0085, U+2028, or U+2029, and these
characters do not end a line.

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
gives the forms of one group, as section 8 defines them: the
requirements of the group, and what the members `input`, `result`, and
`values` of its vectors stand for, each in a fixed form. A vector
without the member `values` states nothing that a conforming program
gives for the input, other than its result. In `input` and `values`, a
byte sequence is its hex text, as a string, such as
`"7b22726576223a227631227d0a"` for the UTF-8 encoding of `{"rev":"v1"}`,
then the byte 0x0A.

#### 8.4.1 Test-vector sets

The group `read-set` holds the vectors that each give a byte sequence
and what a conforming program gives when it reads the byte sequence as a
test-vector set. The requirement of the group is `read-test-vector-set`.

- `input`: the byte sequence.
- `result`: "valid" when the byte sequence is a test-vector set, and
  "invalid" when it is not.
- `values`: with the result "valid", an object with one member,
  `objects`: an array of the objects of the set line, the group lines,
  and the vector lines of the byte sequence, in their order. With the
  result "invalid", the empty object, `{}`.

With the result "valid", a conforming program gives the objects of
`objects`, in their order, and no other object. When `values` is `{}`,
it gives no object.

```
{"group":"read-set","input":"7b22726576223a227631227d0a","n":1,"result":"valid","rev":"v1","values":{"objects":[{"rev":"v1"}]}}
{"group":"read-set","input":"","n":7,"note":"the byte sequence holds no set line","result":"invalid","rev":"v1","values":{}}
```

#### 8.4.2 Version sequences

The group `validate-sequence` holds the vectors that each give a finite
sequence of versions and the result that a conforming program gives for
it when it validates the sequence as a version sequence. The requirement
of the group is `validate-version-sequences`.

- `input`: an array of the versions of the sequence, in their order.
  Each version is an object with two members:
  - `set`: an array of the objects of the set line, the group lines, and
    the vector lines of the test-vector set of the version, in their
    order. The test-vector set is the byte sequence of the canonical
    byte sequences of these objects, in their order, each then the byte
    0x0A.
  - `forms`: an object with one member for each group of that
    test-vector set. The key of the member is the group name, and its
    value is the text of the forms of that group in the version, as a
    string.
- `result`: "valid" when the sequence is a version sequence, and
  "invalid" when it is not.
- `values`: no vector of the group has this member.

```
{"group":"validate-sequence","input":[{"forms":{"a":"text 1"},"set":[{"rev":"v1"},{"group":"a","rev":"v1"},{"group":"a","input":"x","n":1,"result":"valid","rev":"v1"}]}],"n":46,"note":"a sequence of one version","result":"valid","rev":"v1"}
```
