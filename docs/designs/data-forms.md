<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Data forms
@design data-forms=v2
@cites text=v1
@cites rfc/3339
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
@cites rfc/2781
@cites toml-lang/1.1.0
@cites ieee/754-2019
@cites fips/180-4
Specifies the canonical form of JSON values and canonical lines, and the JSON values of byte sequences that hold JSON texts; the TOML documents that Sinter reads, with the spans of their keys and values; SHA-256 hashes and hash ids; test-vector sets; and requirements for conforming programs that write, read, compute, and validate them.

A JSON value is a string, an integer, a boolean, an array, or an object.
Each JSON value has one canonical form: a JSON text, as RFC 8259 defines
it, with the members of each object in a fixed order and with no space,
tab, line feed, or carriage return outside its strings. A canonical line
holds the canonical byte sequence of one line object, which is an object
of a restricted shape, and ends with the byte 0x0A. So two programs that
give the canonical lines of the same line objects, in the same order,
give the same bytes.

A TOML document is a byte sequence whose text, as TOML 1.1.0 reads it
with the reading rules of TOML, matches the rule `toml` of TOML 1.1.0,
that has no value error, and whose keys, tables, and strings break no
statement of TOML 1.1.0. At the points where TOML 1.1.0 lets an
implementation choose, such as the number of digits of a fraction of a
second, a conforming program makes the choices of the reading rules of
TOML. When a conforming program gives a result for whether a byte
sequence is a TOML document, it gives the result "valid" for a TOML
document and "invalid" for every other byte sequence. For a TOML
document, it can also give the root table and the spans of its keys and
values, with their locations.

SHA-256 is a hash function: it gives a digest of 32 bytes for a byte
sequence. The hash of a byte sequence is its digest as 64 hex digits. A
hash id is an id prefix, such as `e-`, and then the first hex digits of
a hash. A test-vector set is a byte sequence that holds vector lines,
and the object of a vector line can state a vector.

From Text and notation, the design takes characters, texts, and their
places, boundaries, and runs; bytes, byte sequences, and UTF-8; byte
order marks and bodies; lines, line numbers, positions, and spans; whole
numbers, decimal numerals, 0x numerals, U+ numerals, and hex digits;
code spans and the notation of productions; and conforming programs,
inputs, and results.

From RFC 8259, the design takes JSON texts and the rule `JSON-text` of
its ABNF: canonical forms and vector lines write JSON values in JSON
texts, and a conforming program reads the JSON value of a byte sequence
from its JSON text. From RFC 2781, it takes the code units of the
encoding UTF-16, by which key order compares keys. From TOML 1.1.0, it
takes documents, their tables, their keys, and their values, and the
rules `toml`, `key`, `simple-key`, and `val` of its ABNF. From RFC 3339,
it takes the ranges of the months, days, hours, minutes, seconds, and
offsets of dates and times, the meaning of the offset of an offset
date-time, and its statement on leap seconds, which a reading rule of
TOML replaces. From IEEE 754-2019, it takes the binary64 format of
floating-point numbers, and rounding to nearest with ties to even. From
FIPS 180-4, it takes the hash function SHA-256.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405.

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
| [UTF-16 code unit](sinter:#utf-16-code-unit=v1) | a code unit, as a whole number, that UTF-16, as RFC 2781 defines it, gives for a character |
| [key order](sinter:#key-order=v1) | the order of texts by their UTF-16 code units, in which the members of an object stand in its canonical form |
| [canonical form](sinter:#canonical-form=v1) | the one text that the rules of the canonical form give for a JSON value |
| [string form](sinter:#canonical-form=v1) | the text that stands for one character of a string in the canonical form of the string, such as `\n` for the line feed and `a` for `a` |
| [canonical byte sequence](sinter:#canonical-byte-sequence=v1) | the UTF-8 encoding of the canonical form of a JSON value |
| [hash](sinter:#hash=v1) | the hex text of the digest that SHA-256 gives for a byte sequence: 64 hex digits |
| [scalar](sinter:#line-object=v1) | a string, an integer, or a boolean |
| [flat object](sinter:#line-object=v1) | an object in which the value of each member is a scalar |
| [line object](sinter:#line-object=v1) | an object in which the value of each member is a scalar, an array of scalars, or an array of flat objects |
| [canonical line](sinter:#canonical-line=v2) | the canonical byte sequence of a line object, then the byte 0x0A |
| [JSON value of a byte sequence](sinter:#json-value-of-a-byte-sequence=v1) | the JSON value that the value of the JSON text of a byte sequence gives, when the byte sequence is valid UTF-8, its text is a JSON text of RFC 8259, and that JSON text has no value `null`, no number with a fraction or an exponent or outside the range of an integer, no escape sequence `\u` of a number from 0xD800 to 0xDFFF that is not one of two that write the UTF-16 code units of one character, and no object with two names that stand for the same text |
| [TOML document](sinter:#toml-document=v2) | a byte sequence whose text, as TOML 1.1.0 reads it with the reading rules of TOML, matches the rule `toml` of TOML 1.1.0, that has no value error, and whose keys, tables, and strings break no statement of TOML 1.1.0 |
| key/value pair, table header, inline table, array of tables, quoted key, basic string, multi-line basic string, literal string, multi-line literal string, escape sequence, newline; integer, float, string, array, and value of TOML 1.1.0 | the things that TOML 1.1.0 calls by these names; in a JSON text, an escape sequence is what RFC 8259 calls by that name |
| [TOML key](sinter:#toml-key=v1) | a key of TOML 1.1.0 that is not a dotted key, such as `a` or `"a"` |
| [dotted key](sinter:#toml-key=v1) | a key of TOML 1.1.0 that joins two or more TOML keys with `.`, such as `b.c.x`; these are the TOML keys of the dotted key |
| [key of a key/value pair](sinter:#toml-key=v1), [key of a table header](sinter:#toml-key=v1) | the key of TOML 1.1.0 in it: a TOML key or a dotted key |
| [TOML value](sinter:#toml-value=v1) | a value of the data that TOML 1.1.0 reads from a document: the value that a value of TOML 1.1.0 gives, the root table of a document, a table that a table header makes, a table that a dotted key makes, a TOML array that the table headers of an array of tables make, or a TOML value in one of these; each TOML value is of one of ten kinds |
| [TOML string](sinter:#toml-value=v1), [TOML integer](sinter:#toml-value=v1), [TOML float](sinter:#toml-value=v1), [TOML boolean](sinter:#toml-value=v1), [TOML array](sinter:#toml-value=v1) | a TOML value of the type string, integer, float, boolean, or array of TOML 1.1.0 |
| [local date](sinter:#toml-value=v1), [local time](sinter:#toml-value=v1), [local date-time](sinter:#toml-value=v1), [offset date-time](sinter:#toml-value=v1) | the TOML values of TOML 1.1.0 that have these names |
| [table](sinter:#toml-value=v1) | a TOML value that holds a set of pairs, each the text of a TOML key and a TOML value, with no order |
| [equal](sinter:#toml-value-equality=v1) | the relation of two TOML values of the same kind whose parts match: texts that are the same text, numbers that are the same number, and TOML values that are equal; two TOML floats are equal when their binary64 values have the same bits or both are NaN |
| [reading rules of TOML](sinter:#toml-reading-rule-list=v1) | the rules on the byte order mark and on the second 60; the choices at the points where TOML 1.1.0 lets an implementation choose; and the rules on offsets and on newlines in strings |
| [root table](sinter:#root-table=v2) | the top-level table of a TOML document |
| [location](sinter:#toml-location=v2) | the sequence of steps from the root table of a TOML document to a TOML value: texts of TOML keys and indexes in TOML arrays; two tables with the same location are the same table |
| [span of a key](sinter:#toml-span=v2), [span of a value](sinter:#toml-span=v2) | the run that the rule `key`, `simple-key`, or `val` of TOML 1.1.0 matches for a key, a TOML key, or a value of TOML 1.1.0 |
| [span pair](sinter:#toml-span-pair=v2) | a span of the text of a TOML document together with what it is the span of: a TOML value at a location, the key of TOML 1.1.0 that leads to a location, or a TOML key of such a key |
| [value error](sinter:#toml-value-error=v1) | a local date, a local time, a local date-time, or an offset date-time of TOML 1.1.0 that RFC 3339 does not allow, with the second 60 on every date, such as the local date `1979-02-30` |
| fit | a text fits a form when it has the form that a production or a rule gives |
| [hash form](sinter:#hash-form=v1) | the form of a text of exactly 64 hex digits |
| [id prefix](sinter:#id-prefix=v1) | one or more of the letters `a` to `z`, then `-`, such as `e-` |
| [hash id](sinter:#hash-id=v1) | an id prefix, then the first hex digits of a hash, such as `e-ba7816bf8f01` |
| [hash-id form](sinter:#hash-id-form=v1) | the form of a text that is an id prefix, then a given number of hex digits |
| [specification](sinter:text#specification=v1) | a part of a design that has a name of its own and that declares some of the obligations and definitions of the design |
| [vector](sinter:#vector-meaning=v2) | an input and what the requirements of a specification, or the requirements that a design holds outside its specifications, oblige a conforming program to give for that input; the object of a vector line states one vector by the forms of its group, when the schema declared under the schema part name of its form in the Conformance part of the specification, or in the Conformance section of the design, gives the first four things of the forms of that group, and the value of `input`, and the value of `values` when the object has that member, have the fixed forms that these forms give (a value of `values` has no fixed form when these forms give none); otherwise it states no vector |
| [test-vector file name](sinter:#test-vector-file-name=v1) | for the name x of a design and the name y of a specification of that design, the text x, `.`, y, and `.test-vectors.jsonl`, such as `a.b.test-vectors.jsonl`; for the name x of a design alone, x and `.test-vectors.jsonl`, such as `a.test-vectors.jsonl` |
| [form pin](sinter:#form-pin=v1) | `#`, a schema part name, `=`, and a schema label, such as `#offsets-vector=v1`, which pins the schema of a group |
| [group name](sinter:#group-name=v1) | a text of the letters `a` to `z`, the digits `0` to `9`, and `-` that starts with a letter, with no `-` at the start or the end, and no two `-` one after the other, such as `offsets` or `g-2` |
| [group](sinter:#vector-line=v2) | the group name that the member `group` of the object of a vector line holds, such as `offsets` |
| [the vector lines of a group](sinter:#test-vector-set=v2) | the vector lines of a test-vector set whose group is that group |
| [forms of a group](sinter:#group-form-list=v2) | five things that a schema in the Conformance section of a design, or in the Conformance part of a specification, together with the need names of that section or part, gives for a group: the requirements of the group; what the value of `input` stands for, and its fixed form; the question that the value of `result` answers, the inputs that it is about, and the conditions under which the requirements oblige that result (the forms can name no question instead); what the value of `values` stands for, and its fixed form (the forms can give no fixed form for `values`); and the need names, each with the need that it stands for |
| [fixed form](sinter:#group-form-list=v2) | a shape of JSON values that the forms of a group give for the value of `input` or of `values`, or any of several such shapes: which of a string, an integer, a boolean, an array, or an object each value is, their members, the values of their integers, and the texts of their strings; whether a value has a fixed form depends on that value alone |
| [Conformance part](sinter:#group-form-list=v2), [Conformance section](sinter:#group-form-list=v2) | the conformance part of a specification, or the conformance section of a design, which holds the schemas of its groups and gives its need names |
| [need](sinter:#group-form-list=v2) | a condition on the environment in which a conforming program operates that a check of the vectors can be unable to make hold, such as that the file system stores a given entry name; the forms of a group give each need with a need name |
| [need name](sinter:#group-form-list=v2) | a text that matches the production `group-name`, such as `no-privilege`, that stands for a need; the member `needs` of a vector object holds texts of this form, and the forms of the group give the need that each of them stands for, if any |
| [check of the vectors](sinter:#vector-meaning=v2) | the act of deciding, for each vector of a specification, or of a design, that the object of a vector line of a test-vector set states, whether a program, when it operates while each need of the vector holds, gives what the object of its vector line states; a skip of a vector decides nothing about it when the check cannot make a need of the vector hold and reports that need, and each other skip counts as a decision that the program does not give what the object states; each of these decisions, a decision about a skip included, is a decision of the check, such as one run of a test that checks the vectors, and not of a reader of what the check reports |
| [vector object](sinter:#vector-object=v2) | an object with fixed members: it always has the members `form`, `group`, and `input`, has the member `result`, the member `values`, or both, and can have the members `needs` and `note` |
| [vector line](sinter:#vector-line=v2) | the canonical byte sequence of a vector object, then the byte 0x0A |
| [test-vector set](sinter:#test-vector-set=v2) | a byte sequence of zero or more vector lines in which all vector lines with the same group have the same schema part name in their form |

## 2. Results, JSON values, and canonical forms

When a conforming program gives a result for an input that it reads or
validates, it gives one of two results: "valid" or "invalid". It can
also give more, such as the line object of a canonical line or the root
table of a TOML document.

A conforming program may refuse an input beyond its own limits, such as
a byte sequence too long for it to hash, a number that it cannot hold,
or arrays, objects, or inline tables nested deeper than it reads; it
then gives no result for that input.

The term `index` gives the index of an element of a finite sequence,
counted from 1. So the first element of an array has the index 1, and
the second element has the index 2.

The term `json-value` gives the JSON values: strings, integers,
booleans, arrays, and objects. An object can hold the key U+00E9 and the
key `e`, U+0301 as two members, although both keys show as the letter e
with an acute accent. It can also hold the keys `a` and `A` as two
members.

The term `canonical-form` gives the canonical form of a JSON value, a
text, and the term `canonical-byte-sequence` gives its UTF-8 encoding.
In a canonical form, the members of an object stand in key order, which
compares two keys by their UTF-16 code units, as the terms `key-order`
and `utf-16-code-unit` give. For example, the key U+1F600 (the code
units 0xD83D and 0xDE00) comes before the key U+E000 (the code unit
0xE000) in key order, but U+1F600 comes after U+E000 in code point
order.

In these examples, a JSON text gives each JSON value:

| JSON value | canonical form |
|---|---|
| `{ "b": 1, "a": [true, false] }` | `{"a":[true,false],"b":1}` |
| `{ "ab": 1, "a": 2 }` | `{"a":2,"ab":1}` |
| `"a/b"` | `"a/b"` |
| `"x\u000by"` | `"x\u000by"` |
| `-42` | `-42` |

The term `hex-text` gives the hex text of a byte and of a byte
sequence. So the hex text of the byte 0x3F is `3f`, and the hex text of
the byte sequence 0x00, 0xFF is `00ff`.

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
member. No two members of one object have the same key. A program gives
a JSON value when it gives something that stands for that JSON value,
and for no other JSON value.

### 3.4 UTF-16 code units

@term utf-16-code-unit=v1
@cites {rfc/2781, text#{character=v1, text=v1, whole-number=v1}}

The UTF-16 code units of a character are the code units, each a whole
number, that UTF-16, as RFC 2781 defines it, gives for the character.
The UTF-16 code units of a text are the UTF-16 code units of its
characters, in their order.

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

The hash of a byte sequence is the hex text of the digest, as 32 bytes,
that SHA-256 of FIPS 180-4 gives for it.

## 4. JSON lines
@spec json-lines=v2

When a conforming program gives a byte sequence as the canonical byte
sequence of a JSON value, it gives the canonical byte sequence of that
JSON value. When it gives a byte sequence as the canonical line of a
line object, it gives the canonical line of that line object. It gives
no canonical line for a thing that is not a line object. When it gives a
result for whether a byte sequence is the canonical line of a line
object, it gives the result "valid" when the byte sequence is the
canonical line of a line object, and the result "invalid" when it is
not. It can also give the line object whose canonical line the byte
sequence is.

The term `line-object` gives the line objects.
These are not line objects:

| object | why it is not a line object |
|---|---|
| `{"a":{"b":1}}` | the value of `a` is an object |
| `{"a":[[1]]}` | the value of `a` is an array that holds an array |
| `{"a":[1,{"b":1}]}` | the value of `a` mixes a scalar and an object |
| `{"a":[{"b":[1]}]}` | the object `{"b":[1]}` is not a flat object |

A canonical line is the canonical byte sequence of a line object, then
the byte 0x0A, as the schema `canonical-line` gives.

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

A conforming program can also read a byte sequence as a JSON text, such
as the output of another program. When it gives a result for whether the
byte sequence has a JSON value, it gives the result "valid" when the
byte sequence has one, and the result "invalid" when it has none. It can
also give the JSON value of the byte sequence, as the term
`json-value-of-a-byte-sequence` gives it. For example, the UTF-8
encoding of `{ "b": 1, "a": "\u00e9" }`, then the byte 0x0A, has the
JSON value whose canonical form is `{"a":"é","b":1}`, and the UTF-8
encodings of `{"a":1.0}`, of `{"a":1,"a":2}`, and of `"\ud800"` have no
JSON value.

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

@schema canonical-line=v2
@cites {
    text#{byte=v1, byte-sequence=v1, 0x-numeral=v1},
    #{line-object=v1, canonical-byte-sequence=v1},
}

The canonical line of a line object is the byte sequence of the
canonical byte sequence of the line object, then the byte 0x0A.

#### 4.1.3 The JSON values of byte sequences

@term json-value-of-a-byte-sequence=v1
@cites {
    rfc/8259,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        text=v1, character=v1, whole-number=v1, 0x-numeral=v1,
        code-span=v1,
    },
    #{json-value=v1, utf-16-code-unit=v1},
}

These definitions use the JSON texts of RFC 8259, with their values,
objects, members, names, arrays, strings, escape sequences, numbers,
fractions, exponents, and the literal names `true`, `false`, and
`null`, and the rule `JSON-text` of the ABNF of RFC 8259.

- The JSON text of a byte sequence is the text of the byte sequence,
  when the byte sequence is valid UTF-8 and its text matches the rule
  `JSON-text`. Every other byte sequence has no JSON text.
- A string or a name of a JSON text stands for the text that RFC 8259
  gives for it. A string or a name with an escape sequence `\u` of a
  number from 0xD800 to 0xDFFF that is not one of two, one right after
  the other, that write the UTF-16 code units of one character stands
  for no text.
- The value `true` of a JSON text gives the JSON value true, and the
  value `false` gives the JSON value false. The value `null` gives no
  JSON value.
- A number of a JSON text with no fraction and no exponent gives the
  integer that is the whole number that it writes, when that whole
  number is an integer. Every other number of a JSON text gives no JSON
  value.
- A string of a JSON text gives the string that is the text that it
  stands for. A string of a JSON text that stands for no text gives no
  JSON value.
- An array of a JSON text gives the array whose elements are the JSON
  values that its values give, in their order, when each of its values
  gives a JSON value. Otherwise, it gives no JSON value.
- An object of a JSON text gives the object that has one member for each
  member of the object of the JSON text, and no other member: the key
  of that member is the text that the name of the member of the JSON
  text stands for, and its value is the JSON value that the value of the
  member of the JSON text gives. An object of a JSON text gives no JSON
  value when one of its names stands for no text, when the value of one
  of its members gives no JSON value, or when two of its names stand for
  the same text.
- The JSON value of a byte sequence is the JSON value that the value of
  its JSON text gives. A byte sequence that has no JSON text, or whose
  JSON text has a value that gives no JSON value, has no JSON value.

### 4.2 Canonical byte sequences as output

@req write-canonical-json=v1
@cites {
    text#{requirement=v1, conforming-program=v1, byte-sequence=v1},
    #{json-value=v1, canonical-byte-sequence=v1},
}

A conforming program must give, as the canonical byte sequence of a
thing, only the canonical byte sequence of that thing.

### 4.3 Canonical lines as output

@req write-canonical-line=v2
@cites {
    text#{requirement=v1, conforming-program=v1, byte-sequence=v1},
    #{line-object=v1, canonical-line=v2},
}

A conforming program must give, as the canonical line of a thing, only
the canonical line of that thing.

### 4.4 Canonical lines as input

@req read-canonical-line=v2
@cites {
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        result=v1,
    },
    #{line-object=v1, canonical-line=v2},
}

When a conforming program gives a result for whether a byte sequence is
the canonical line of a line object, it must give exactly one result:
"valid" when the byte sequence is the canonical line of a line object,
and "invalid" when it is not.

### 4.5 Only the line objects of canonical lines

@req give-only-line-objects=v2
@cites {
    text#{requirement=v1, conforming-program=v1, byte-sequence=v1},
    #{line-object=v1, canonical-line=v2},
}

A conforming program must give, as the line object of a byte sequence,
only the line object whose canonical line the byte sequence is.

### 4.6 JSON texts as input

@req read-json-text=v1
@cites {
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        result=v1,
    },
    #{json-value=v1, json-value-of-a-byte-sequence=v1},
}

When a conforming program gives a result for whether a byte sequence
has a JSON value, it must give exactly one result: "valid" when the byte
sequence has a JSON value, and "invalid" when it has none.

### 4.7 Only the JSON values of byte sequences

@req give-only-json-values=v1
@cites {
    text#{requirement=v1, conforming-program=v1, byte-sequence=v1},
    #{json-value=v1, json-value-of-a-byte-sequence=v1},
}

A conforming program must give, as the JSON value of a byte sequence,
only the JSON value of that byte sequence.

### 4.8 Conformance

A program conforms to the specification `json-lines` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The file
[`data-forms.json-lines.test-vectors.jsonl`](data-forms.json-lines.test-vectors.jsonl),
in the same directory as this design, is a test-vector set, as the
specification `test-vectors` defines it. By the term `vector-meaning`,
the object of each vector line of the file states one vector of this
specification. This specification gives no need names.

The vectors follow from the requirements of this specification and add
nothing to them. Each subsection below gives the forms of one group, as
the term `group-form-list` gives them.

#### 4.8.1 Canonical byte sequences

@schema write-json-vector=v1
@cites {
    text#{
        conforming-program=v1, input=v1, byte=v1, byte-sequence=v1,
        character=v1, utf-8-encoding=v1, 0x-numeral=v1, code-span=v1,
    },
    #{
        write-canonical-json=v1, json-value=v1,
        json-value-of-a-byte-sequence=v1, canonical-byte-sequence=v1,
        hex-text=v1, vector-line=v2, group-form-list=v2,
        vector-meaning=v2,
    },
}

The group `write-json` holds the vector lines whose vectors each give a
JSON value and its canonical byte sequence. The requirement of the group
is `write-canonical-json`. In `input` and `values`, a byte sequence is
its hex text, as a string, such as `"7b7d0a"` for the UTF-8 encoding of
`{}`, then the byte 0x0A.

- `input`: a string whose characters are a JSON text whose UTF-8
  encoding has a JSON value, as the term
  [`json-value-of-a-byte-sequence`](sinter:#json-value-of-a-byte-sequence=v1)
  gives it; the input is that JSON value.
- `result`: the forms of the group name no question for `result`.
- `values`: an object with one member, `canonical-byte-sequence`: the
  canonical byte sequence of the input.

When a conforming program gives a byte sequence as the canonical byte
sequence of the input, it gives the byte sequence of
`canonical-byte-sequence`, and no other byte sequence.

```
{"form":"#write-json-vector=v1","group":"write-json","input":"{ \"ab\": 1, \"a\": 2 }","values":{"canonical-byte-sequence":"7b2261223a322c226162223a317d"}}
```

#### 4.8.2 Canonical lines as output

@schema write-line-vector=v1
@cites {
    text#{
        conforming-program=v1, input=v1, byte-sequence=v1,
        character=v1, code-span=v1,
    },
    #{
        write-json-vector=v1, write-canonical-line=v2, json-value=v1,
        line-object=v1, canonical-line=v2, hex-text=v1, vector-line=v2,
        group-form-list=v2, vector-meaning=v2,
    },
}

The group `write-line` holds the vector lines whose vectors each give a
line object and its canonical line, or a JSON value that is not a line
object. The requirement of the group is `write-canonical-line`. In
`input` and `values`, a byte sequence is its hex text, as a string, as
`write-json-vector` gives.

- `input`: a string whose characters are a JSON text, as in the group
  `write-json`. The input is what the JSON text gives, as in that group.
- `result`: the forms of the group name no question for `result`.
- `values`: when the input is a line object, an object with one member,
  `canonical-line`: the canonical line of the input. When the input is
  not a line object, the empty object, `{}`.

When a conforming program gives a byte sequence as the canonical line
of the input, it gives the byte sequence of `canonical-line`, and no
other byte sequence. When `values` is `{}`, it gives no byte sequence as
the canonical line of the input.

```
{"form":"#write-line-vector=v1","group":"write-line","input":"{}","values":{"canonical-line":"7b7d0a"}}
{"form":"#write-line-vector=v1","group":"write-line","input":"{ \"a\": { \"b\": 1 } }","note":"the value of `a` is an object","values":{}}
```

#### 4.8.3 Canonical lines as input

@schema read-line-vector=v1
@cites {
    text#{
        conforming-program=v1, byte-sequence=v1, result=v1,
        code-span=v1,
    },
    #{
        write-json-vector=v1, read-canonical-line=v2,
        give-only-line-objects=v2, json-value=v1, line-object=v1,
        canonical-line=v2, hex-text=v1, vector-line=v2,
        vector-meaning=v2,
    },
}

The group `read-line` holds the vector lines whose vectors each give a
byte sequence and what a conforming program gives when it reads the byte
sequence as a canonical line. The requirements of the group are
`read-canonical-line` and `give-only-line-objects`. In `input` and
`values`, a byte sequence is its hex text, as a string, as
`write-json-vector` gives.

- `input`: the byte sequence.
- `result`: when a conforming program gives a result for whether the
  byte sequence is the canonical line of a line object, that result:
  "valid" when the byte sequence is the canonical line of a line object,
  and "invalid" when it is not.
- `values`: when `result` is "valid", an object with one member,
  `line-object`: the line object whose canonical line the byte sequence
  is. When `result` is "invalid", the empty object, `{}`.

When a conforming program gives a line object as the line object of the
byte sequence, it gives the line object of `line-object`, and no other
line object. When `values` is `{}`, it
gives no line object as the line object of the byte sequence.

```
{"form":"#read-line-vector=v1","group":"read-line","input":"7b2261223a322c2262223a317d0a","result":"valid","values":{"line-object":{"a":2,"b":1}}}
{"form":"#read-line-vector=v1","group":"read-line","input":"7b2261223a20327d0a","note":"a space stands outside a string","result":"invalid","values":{}}
```

#### 4.8.4 JSON texts as input

@schema read-json-vector=v1
@cites {
    text#{
        conforming-program=v1, byte-sequence=v1, result=v1,
        code-span=v1,
    },
    #{
        write-json-vector=v1, read-json-text=v1,
        give-only-json-values=v1, json-value=v1,
        json-value-of-a-byte-sequence=v1, hex-text=v1, vector-line=v2,
        vector-meaning=v2,
    },
}

The group `read-json` holds the vector lines whose vectors each give a
byte sequence and what a conforming program gives when it reads the byte
sequence as a JSON text. The requirements of the group are
`read-json-text` and `give-only-json-values`. In `input` and `values`, a
byte sequence is its hex text, as a string, as `write-json-vector`
gives.

- `input`: the byte sequence.
- `result`: when a conforming program gives a result for whether the
  byte sequence has a JSON value, that result: "valid" when the byte
  sequence has one, and "invalid" when it has none.
- `values`: when `result` is "valid", an object with one member,
  `json-value`: the JSON value of the byte sequence. When `result` is
  "invalid", the empty object, `{}`.

When a conforming program gives a JSON value as the JSON value of the
byte sequence, it gives the JSON value of `json-value`, and no other
JSON value. When `values` is `{}`, it gives no JSON value as the JSON
value of the byte sequence.

```
{"form":"#read-json-vector=v1","group":"read-json","input":"7b20226222203a205b312c20325d202c092261223a74727565207d0d0a","note":"spaces, a tab, a carriage return, and a line feed stand around values and around `:` and `,`, and the members do not stand in key order","result":"valid","values":{"json-value":{"a":true,"b":[1,2]}}}
{"form":"#read-json-vector=v1","group":"read-json","input":"312e30","note":"the number has a fraction","result":"invalid","values":{}}
```

## 5. TOML
@spec toml=v2

A conforming program can read a byte sequence as a TOML document. When
it gives a result for whether the byte sequence is a TOML document, it
gives the result "valid" when the byte sequence is a TOML document, and
the result "invalid" when it is not. For a TOML document, it can also
give the root table, and the spans of the keys of TOML 1.1.0 and of the
values of TOML 1.1.0 in the document, with their locations.

In this specification, a text in a code block stands for the UTF-8
encoding of its lines, each line then the byte 0x0A.

A TOML document is a byte sequence whose text, as TOML 1.1.0 reads it
with the reading rules of TOML, matches the rule `toml` of the ABNF of
TOML 1.1.0, that has no value error, and whose keys, tables, and strings
break no statement of TOML 1.1.0, such as the statement that no key is
defined twice. A value error is a date or a time that RFC 3339 does not
allow, such as the local date `1979-02-30`.

TOML 1.1.0 reads a text. By a reading rule of TOML, for a byte sequence
that is valid UTF-8, TOML 1.1.0 reads the body of its text, so it does
not read a byte order mark. So when a byte sequence starts with the
bytes 0xEF, 0xBB, 0xBF, TOML 1.1.0 reads the characters after the
U+FEFF that these bytes encode.

The terms `toml-key` and `toml-key-text` give the TOML keys of a key of
TOML 1.1.0 and their texts. So the TOML keys `a` and `"a"` have the same
text, and the TOML keys `"\u00e9"` and `"e\u0301"` have two different
texts.

The term `toml-value` gives the TOML values and their ten kinds, and the
term `root-table` gives the root table of a TOML document. For example,
the integer `0x1F` of TOML 1.1.0 gives the TOML integer 31.

At the points where TOML 1.1.0 lets an implementation choose, a
conforming program makes the choices of the reading rules of TOML, as
the term `toml-reading-rule-list` gives them. For example, `12:30:00.5`
and `12:30:00.50` give equal local times.

TOML 1.1.0 bases local times, local date-times, and offset date-times on
RFC 3339. RFC 3339, section 5.7, allows the second 60 only at a leap
second. A conforming program accepts the second 60 in a local time, a
local date-time, and an offset date-time, on every date and at every
hour and minute.

RFC 3339, section 4.2, gives the meaning of a numeric offset, local time
minus UTC, and section 4.3 gives the meaning of the offset `-00:00`.
Apart from `-00:00`, the offset of an offset date-time is a signed
number of minutes: 0 for `Z` and `z`, and the number of minutes that the
document gives for each other offset, such as 0 for `+00:00` and −420
for `-07:00`. So the offset date-times `1979-05-27T07:32:00Z` and
`1979-05-27T07:32:00+00:00` are equal. No offset date-time changes to
UTC, so `1979-05-27T07:32:00-07:00` and `1979-05-27T14:32:00Z` are not
equal.

The term `toml-value-equality` says when two TOML values are equal. So
`-0.0` and `0.0` give two TOML floats that are not equal.

These three texts give equal root tables, in which `a` holds a table in
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

These two texts give equal root tables, in which `a` holds a TOML array
of one table, in which `b` holds the TOML integer 1:

```toml
a = [{ b = 1 }]
```

```toml
[[a]]
b = 1
```

For a TOML document, a conforming program can give spans of the text of
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
table that a table header makes, a table that a dotted key makes, a
TOML array that the table headers of an array of tables make, and the
root table have no span. So in the text `a.b = { c = 1 }`, the table `a`
has no span, and the table `a.b`, which the inline table gives, has the
span of the inline table.

A byte order mark has no position, so it adds no column: when a byte
sequence starts with the bytes 0xEF, 0xBB, 0xBF and then holds `a = 1`,
the key `a` of the key/value pair also starts at line 1, column 1.

A span pair is a span together with what the span is the span of. The
span of a value of TOML 1.1.0 is the span of the TOML value at the
location of the TOML value that the value gives. The span of the key of
a key/value pair is the span of the key of TOML 1.1.0 that leads to the
location of the TOML value that the value of the key/value pair gives.
So in the text `a = [{ b = 1 }]`, the span of the key `b` is the span of
the key of TOML 1.1.0 that leads to a location of three steps: the text
`a`, the index 1, and the text `b`. The span of the key of a table
header is the span of the key of TOML 1.1.0 that leads to the location
of the table that the table header defines. The span of the TOML key
with the index i of the key of a key/value pair or of a table header is
the span of the TOML key with the index i of the key of TOML 1.1.0 that
leads to the location of that key. So in the text `[[a]]`, the span of
the key `a` of the table header is the span of the key of TOML 1.1.0
that leads to a location of two steps, the text `a` and the index 1. The
span of its TOML key `a` is the span of the TOML key with the index 1 of
that key of TOML 1.1.0.

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
    text#{text=v1, character=v1, code-span=v1},
    #{toml-key=v1},
}

These definitions use the terms quoted key and escape sequence of
TOML 1.1.0.

- The text of a TOML key is the text that TOML 1.1.0 gives for the TOML
  key after its escape sequences resolve, with no other change.
- The text of the quoted key `""` and of the quoted key `''` is the
  empty text, which has no characters. So these quoted keys have a text.

#### 5.1.3 TOML values

@term toml-value=v1
@cites {
    toml-lang/1.1.0,
    ieee/754-2019,
    text#{text=v1, whole-number=v1},
    #{toml-key=v1, toml-key-text=v1},
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
  a text; a TOML integer, which is a whole number; a TOML float, which
  is an IEEE 754-2019 binary64 value; a TOML boolean, which is true or
  false; a local date, which is a year, a month, and a day; a local
  time, which is an hour, a minute, a second, and a fraction of a
  second; a local date-time, which is a local date and a local time; an
  offset date-time, which is a local date-time and an offset; a TOML
  array, which is a sequence of TOML values; and a table.
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

A program gives a TOML value when it gives something that stands for
that TOML value, and for no TOML value that is not equal to it. Two TOML
values are equal when, and only when, they are of the same kind and one
of these is true:

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

#### 5.1.5 The byte order mark in TOML

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

#### 5.1.6 The values of TOML floats

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

#### 5.1.7 Fractions of a second in TOML

@term toml-second-fraction=v1
@cites {toml-lang/1.1.0, text#{code-span=v1}, #{toml-value=v1}}

In a document, the digits after the `.` of the second of a local time, a
local date-time, or an offset date-time give its fraction of a second.
When these digits are d1 to dk, the fraction of a second is the sum of
the numbers di / 10^i for each i from 1 to m, where m is the smaller of
k and 9.

#### 5.1.8 Leap seconds in TOML

@term toml-leap-second=v1
@cites {rfc/3339, toml-lang/1.1.0, #{toml-value=v1}}

With this rule, which replaces the statement of RFC 3339, section 5.7,
on leap seconds, TOML 1.1.0 reads each second from 0 to 60 as a valid
second of a local time, a local date-time, and an offset date-time, on
every date and at every hour and minute.

#### 5.1.9 Offsets in TOML

@term toml-offset=v1
@cites {
    toml-lang/1.1.0,
    rfc/3339,
    text#{code-span=v1},
    #{toml-value=v1},
}

The offset of an offset date-time is a signed number of minutes: 0 when
the document gives the offset as `Z` or `z`, and the number of minutes
that the document gives for each other offset, such as 0 for `+00:00`
and −420 for `-07:00`, except for `-00:00`, whose meaning
RFC 3339, section 4.3, gives.

#### 5.1.10 Newlines in TOML strings

@term toml-string-newline=v1
@cites {
    toml-lang/1.1.0,
    text#{character=v1, u-numeral=v1},
    #{toml-value=v1},
}

This rule uses the terms multi-line basic string, multi-line literal
string, and newline of TOML 1.1.0. Each newline of a multi-line basic
string or a multi-line literal string that TOML 1.1.0 does not trim
stays in the TOML string as its characters: U+000A, or U+000D and then
U+000A.

#### 5.1.11 The reading rules of TOML

@term toml-reading-rule-list=v1
@cites {
    text#{code-span=v1},
    #{
        toml-byte-order-mark=v1, toml-float-value=v1,
        toml-second-fraction=v1, toml-leap-second=v1, toml-offset=v1,
        toml-string-newline=v1,
    },
}

The reading rules of TOML are the rules of `toml-byte-order-mark`,
`toml-float-value`, `toml-second-fraction`, `toml-leap-second`,
`toml-offset`, and `toml-string-newline`.

#### 5.1.12 The locations of TOML values

@term toml-location=v2
@cites #{
    toml-value=v1, toml-key-text=v1, toml-key=v1, index=v1,
    toml-document=v2, root-table=v2,
}

- The location of a TOML value of a TOML document is the sequence of
  steps that leads to it from the root table of the TOML document. Each
  step is the text of a TOML key, or the index of a TOML value in a TOML
  array.
- The location of the root table is the sequence of no steps. When a
  table with the location L holds a text x, the TOML value of x in that
  table has the location of the steps of L and then the step x. When a
  TOML array with the location L holds a TOML value at the index i, that
  TOML value has the location of the steps of L and then the step i.
- Two tables of a TOML document that have locations are the same table
  when, and only when, they have the same location. Two tables with
  different locations are two different tables, also when they hold the
  same pairs.

#### 5.1.13 The texts of TOML strings

@term toml-string-text=v1
@cites {
    toml-lang/1.1.0,
    text#{text=v1},
    #{toml-value=v1},
}

This definition uses the terms basic string, multi-line basic string,
literal string, multi-line literal string, and escape sequence of
TOML 1.1.0. The text of a TOML string is the text that TOML 1.1.0 gives
for its basic string, multi-line basic string, literal string, or
multi-line literal string after the escape sequences resolve, with no
change other than the trims that TOML 1.1.0 makes.

#### 5.1.14 The local date-times of offset date-times

@term toml-offset-date-time=v1
@cites {toml-lang/1.1.0, #{toml-value=v1}}

The local date-time of an offset date-time of a document is the local
date-time that the document gives before the offset.

#### 5.1.15 Spans in a TOML document

@term toml-span=v2
@cites {
    toml-lang/1.1.0,
    text#{
        byte-sequence=v1, text-of-a-byte-sequence=v1, run=v1, span=v1,
        code-span=v1,
    },
    #{
        toml-key=v1, toml-value=v1, toml-byte-order-mark=v1,
        toml-document=v2,
    },
}

These definitions use the terms key, key/value pair, table header,
dotted key, value, string, quoted key, array, inline table, and array of
tables of TOML 1.1.0, and the rules `key`, `simple-key`, and `val` of
the ABNF of TOML 1.1.0. They apply to a TOML document. Its spans are
spans of the text of the byte sequence that is the TOML document:

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
  value. A table that a table header makes, a table that a dotted key
  makes, a TOML array that the table headers of an array of tables make,
  and the root table have no span.

#### 5.1.16 Value errors

@term toml-value-error=v1
@cites {
    toml-lang/1.1.0,
    rfc/3339,
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        body=v1, code-span=v1,
    },
    #{toml-leap-second=v1, toml-value=v1},
}

This definition uses the terms local date, local time, local date-time,
and offset date-time of TOML 1.1.0, and the rule `toml` of the ABNF of
TOML 1.1.0. It applies to a byte sequence that is valid UTF-8 and for
which the text of the body of its text matches the rule `toml`.

A value error of such a byte sequence is each local date, local time,
local date-time, or offset date-time of TOML 1.1.0 in the body of its
text that RFC 3339, sections 5.6 and 5.7, does not allow, with the rule
`toml-leap-second` in place of the statement of RFC 3339 on leap
seconds.

#### 5.1.17 TOML documents

@schema toml-document=v2
@cites {
    toml-lang/1.1.0,
    text#{byte-sequence=v1, valid-utf-8=v1, text=v1, code-span=v1},
    #{toml-reading-rule-list=v1, toml-value-error=v1},
}

This definition uses the rule `toml` of the ABNF of TOML 1.1.0. A TOML
document is a byte sequence that meets each of these conditions:

- The byte sequence is valid UTF-8, as TOML 1.1.0 requires of a
  document, and the text that TOML 1.1.0 reads for it, with the reading
  rules of TOML, matches the rule `toml`.
- The byte sequence has no value error.
- The keys, the tables, and the strings of that text break no statement
  of TOML 1.1.0, such as the statements that no key or table is defined
  twice and that each escape sequence writes a Unicode scalar value.

#### 5.1.18 Root tables

@term root-table=v2
@cites {
    toml-lang/1.1.0,
    text#{code-span=v1},
    #{
        toml-document=v2, toml-reading-rule-list=v1,
        toml-string-text=v1, toml-offset-date-time=v1, toml-value=v1,
    },
}

This definition uses the terms root table, table header, dotted key,
inline table, and array of tables of TOML 1.1.0. The root table of a
TOML document is the root table that TOML 1.1.0 gives for the document,
with the reading rules of TOML, and with the rules of `toml-string-text`
and `toml-offset-date-time`. In this root table, each table that a table
header makes, each table that a dotted key makes, and the table of each
inline table is a TOML value of the kind table, and each TOML array that
the table headers of an array of tables make, and each TOML array that
the brackets `[` and `]` around TOML values make, is a TOML value of the
kind TOML array.

#### 5.1.19 Span pairs

@term toml-span-pair=v2
@cites {
    toml-lang/1.1.0,
    text#{span=v1},
    #{
        toml-document=v2, toml-key=v1, toml-span=v2, toml-value=v1,
        toml-location=v2, index=v1,
    },
}

This definition uses the terms key, key/value pair, and table header of
TOML 1.1.0, and the table that TOML 1.1.0 says a table header defines. A
span pair of a TOML document is a span of the text of the document
together with what the span is the span of. The span pairs of a TOML
document are these, and no others:

- for each TOML value of the document that has a span, its span, as the
  span of the TOML value at the location of that TOML value;
- for the key of each key/value pair of the document, its span, as the
  span of the key of TOML 1.1.0 that leads to the location of the TOML
  value that the value of the key/value pair gives;
- for the key of each table header of the document, its span, as the
  span of the key of TOML 1.1.0 that leads to the location of the table
  that the table header defines;
- for each TOML key of each of these keys, its span, as the span of the
  TOML key with the index i of the key of TOML 1.1.0 that leads to that
  location, where i is the index of that TOML key among the TOML keys of
  that key.

A program gives the TOML value, the key, the TOML key, or the location
of a span pair when it gives something that stands for it, and for no
other TOML value, key, TOML key, or location.

### 5.2 TOML documents as input

@req read-toml=v2
@cites {
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        result=v1,
    },
    #{toml-document=v2},
}

When a conforming program gives a result for whether a byte sequence is
a TOML document, it must give exactly one result: "valid" when the byte
sequence is a TOML document, and "invalid" when it is not.

### 5.3 Only the root tables of TOML documents

@req give-only-root-tables=v2
@cites {
    text#{requirement=v1, conforming-program=v1, byte-sequence=v1},
    #{
        toml-value=v1, toml-value-equality=v1, root-table=v2,
        toml-document=v2,
    },
}

A conforming program must give, as the root table of a byte sequence,
only the root table of the TOML document that the byte sequence is.

### 5.4 Only the span pairs of TOML documents

@req give-only-toml-spans=v2
@cites {
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        text-of-a-byte-sequence=v1, result=v1, span=v1, position=v1,
    },
    #{toml-document=v2, toml-span-pair=v2},
}

When a conforming program does not give the result "invalid" for
whether a byte sequence is a TOML document, it must give, as a span of
the text of the byte sequence together with what the span is the span
of, only a span pair of the TOML document that the byte sequence is;
as the line number of the start or of the end of the span of such a
pair, only the line number of that start or that end; and as the column
of that start or that end, only that column.

### 5.5 Conformance

A program conforms to the specification `toml` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The file
[`data-forms.toml.test-vectors.jsonl`](data-forms.toml.test-vectors.jsonl),
in the same directory as this design, is a test-vector set, as the
specification `test-vectors` defines it. By the term `vector-meaning`,
the object of each vector line of the file states one vector of this
specification. This specification gives no need names.

The vectors follow from the requirements of this specification and add
nothing to them. Each subsection below gives the forms of one or more
groups, as the term `group-form-list` gives them.

#### 5.5.1 TOML documents

@schema toml-document-vector=v1
@cites {
    text#{
        conforming-program=v1, byte-sequence=v1, utf-8-encoding=v1,
        text=v1, line-feed=v1, whole-number=v1, decimal-numeral=v1,
        result=v1, code-span=v1,
    },
    #{
        read-toml=v2, give-only-root-tables=v2, toml-document=v2,
        root-table=v2, toml-value=v1, toml-value-equality=v1,
        toml-key=v1, toml-key-text=v1, toml-offset=v1,
        toml-second-fraction=v1, json-value=v1, hex-text=v1,
        index=v1, vector-line=v2, vector-meaning=v2,
    },
}

Each vector that the object of a vector line of the groups
`give-root-table` and `reject-byte-sequence` states gives a byte
sequence and what a conforming program gives for it as a TOML document.
The byte sequence decides which of the two groups the vector line has.
Together, the vectors that these objects state test which byte sequences
are TOML documents, and the root tables of TOML documents.

In `input` and `values`, these fixed forms apply:

- A byte sequence is its hex text, as a string. So the UTF-8 encoding of
  `a = 1` and a line feed is `"61203d20310a"`.
- The form of a table is an object with one member for each pair that
  the table holds. The key of the member is the text of the TOML key of
  the pair, and the value of the member is the form of the TOML value of
  the pair.
- The form of a TOML value is an object with one member. The key of
  that member names the kind of the TOML value, and its value gives the
  TOML value, as this table and the two paragraphs after it say.

| kind of the TOML value | key of the member | value of the member |
|---|---|---|
| TOML string | `string` | the text of the TOML string, as a string |
| TOML integer | `integer` | a string of the decimal numeral of the absolute value of the TOML integer, after `-` when the TOML integer is less than 0, such as `"-17"` |
| TOML float | `float` | a string, in the form that the first paragraph after this table gives |
| TOML boolean | `boolean` | `true` or `false` |
| local date | `local-date` | a string, in the form that the second paragraph after this table gives |
| local time | `local-time` | a string, in the form that the second paragraph after this table gives |
| local date-time | `local-date-time` | a string, in the form that the second paragraph after this table gives |
| offset date-time | `offset-date-time` | a string, in the form that the second paragraph after this table gives |
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
date-time, then its offset: `+00:00` for the offset 0. For each other
offset, the string of the offset is `+` when the offset is greater than
0, and `-` when it is less than 0; then the whole-number quotient of the
absolute value of the offset divided by 60, and the remainder, each as
two digits, with `:` between them. So the offset date-time of
`1979-05-27T07:32:00Z` is `"1979-05-27T07:32:00+00:00"`, and the offset
date-time of `1979-05-27T00:32:00-07:00` is
`"1979-05-27T00:32:00-07:00"`.

So the form of the root table in which `a` holds a table in which `b`
holds the TOML integer 1 is `{"a":{"table":{"b":{"integer":"1"}}}}`. Two
tables are equal when, and only when, their forms are the same JSON
value.

The group `give-root-table` holds the vector lines whose vectors each
give a TOML document and its root table. The requirements of the group
are `read-toml` and `give-only-root-tables`.

- `input`: the byte sequence of the TOML document.
- `result`: "valid", which is the result when a conforming program gives
  a result for whether the byte sequence is a TOML document.
- `values`: an object with one member, `root-table`: the form of the
  root table of the TOML document.

When a conforming program gives a table as the root table of the byte
sequence, it gives a table whose form is the form of `root-table`, and
no other table.

```
{"form":"#toml-document-vector=v1","group":"give-root-table","input":"61203d20310a","result":"valid","values":{"root-table":{"a":{"integer":"1"}}}}
```

The group `reject-byte-sequence` holds the vector lines whose vectors
each give a byte sequence that is not a TOML document. The requirements
of the group are `read-toml` and `give-only-root-tables`.

- `input`: the byte sequence.
- `result`: "invalid", which is the result when a conforming program
  gives a result for whether the byte sequence is a TOML document.
- `values`: the empty object, `{}`.

When `values` is `{}`, a conforming program gives no table as the root
table of the byte sequence.

```
{"form":"#toml-document-vector=v1","group":"reject-byte-sequence","input":"61203d2022620a","note":"the text does not match `toml`, because a basic string holds no line feed","result":"invalid","values":{}}
```

#### 5.5.2 Spans

@schema toml-span-vector=v1
@cites {
    toml-lang/1.1.0,
    text#{
        conforming-program=v1, byte-sequence=v1, text=v1, span=v1,
        position=v1, line-number=v1, result=v1, code-span=v1,
    },
    #{
        toml-document-vector=v1, read-toml=v2, give-only-toml-spans=v2,
        toml-document=v2, root-table=v2, toml-key=v1, toml-key-text=v1,
        toml-value=v1, toml-location=v2, toml-span=v2,
        toml-span-pair=v2, json-value=v1, hex-text=v1, index=v1,
        vector-line=v2, vector-meaning=v2,
    },
}

In `input` and `values`, these fixed forms apply:

- A byte sequence is its hex text, as a string, as
  `toml-document-vector` gives.
- A position is an object with two members: `line`, the line number,
  and `column`, the column, each as an integer. So the position line 2,
  column 5 is `{"column":5,"line":2}`.
- A location is an array of its steps, in order: the text of a TOML key
  as a string, and an index as an integer. So the location of the TOML
  integer 2 in the text `a = [1, { b = 2 }]` is `["a",2,"b"]`, and the
  location of the root table is the empty array, `[]`.

The group `give-span` holds the vector lines whose vectors each give a
TOML document and one of its span pairs: a span, together with what the
span is the span of. The requirements of the group are `read-toml` and
`give-only-toml-spans`.

- `input`: the byte sequence of the TOML document.
- `result`: "valid", which is the result when a conforming program gives
  a result for whether the byte sequence is a TOML document.
- `values`: an object with these members:
  - `of`: a string that says what the span is the span of: `toml-value`
    for the TOML value at the location of `location`; `key` for the key
    of TOML 1.1.0 that leads to that location; or `toml-key` for the
    TOML key with the index of `index` of the key of TOML 1.1.0 that
    leads to that location.
  - `location`: a location.
  - `index`: an index, as an integer. Only a value of `values` whose
    member `of` holds `toml-key` has this member.
  - `start`: the start of the span, as a position.
  - `end`: the end of the span, as a position.

When a conforming program gives a line number or a column as the line
number or the column of the start of the span of what `of`, `location`,
and `index` name, it gives the line number or the column of `start`.
When it gives a line number or a column as the line number or the column
of the end of that span, it gives the line number or the column of
`end`. The object of a vector line of the group states nothing about the
other spans that a conforming program gives for the TOML document. The
note of each vector line of the group whose object states a vector gives
the text of the span.

```
{"form":"#toml-span-vector=v1","group":"give-span","input":"61203d20310a","note":"the text of the span is `a`","result":"valid","values":{"end":{"column":2,"line":1},"index":1,"location":["a"],"of":"toml-key","start":{"column":1,"line":1}}}
{"form":"#toml-span-vector=v1","group":"give-span","input":"61203d205b312c205b322c20335d5d0a","note":"the text of the span is `1`","result":"valid","values":{"end":{"column":7,"line":1},"location":["a",1],"of":"toml-value","start":{"column":6,"line":1}}}
```

The group `omit-span` holds the vector lines whose vectors each give a
TOML document and the location of a TOML value of it that has no span.
The requirements of the group are `read-toml` and
`give-only-toml-spans`.

- `input`: the byte sequence of the TOML document.
- `result`: "valid", which is the result when a conforming program gives
  a result for whether the byte sequence is a TOML document.
- `values`: an object with one member, `no-span-at`: a location.

A conforming program gives no span as the span of the TOML value at the
location of `no-span-at`.

```
{"form":"#toml-span-vector=v1","group":"omit-span","input":"5b615d0a62203d20310a","note":"a table header makes the table `a`","result":"valid","values":{"no-span-at":["a"]}}
```

## 6. Hashes
@spec hashes=v2

A conforming program can give the hash of a byte sequence, as the term
`hash` gives it. When it gives a result for whether a text fits the hash
form, it gives "valid" when the text fits the hash form, and "invalid"
when it does not.

For example, the hash of the three bytes of `abc` is
`ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`.
Upper-case letters are not hex digits, so
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
    text#{requirement=v1, conforming-program=v1, byte-sequence=v1},
    #{hash=v1},
}

A conforming program must give, as the hash of a byte sequence, only
the hash of that byte sequence.

### 6.3 The validation of hashes

@req validate-hash=v1
@cites {
    text#{requirement=v1, conforming-program=v1, text=v1, result=v1},
    #{hash-form=v1},
}

When a conforming program gives a result for whether a text fits the
hash form, it must give exactly one result: "valid" when the text fits
the hash form, and "invalid" when the text does not fit the hash form.

### 6.4 Conformance

A program conforms to the specification `hashes` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The file
[`data-forms.hashes.test-vectors.jsonl`](data-forms.hashes.test-vectors.jsonl),
in the same directory as this design, is a test-vector set, as the
specification `test-vectors` defines it. By the term `vector-meaning`,
the object of each vector line of the file states one vector of this
specification. This specification gives no need names.

The vectors follow from the requirements of this specification and add
nothing to them. Each subsection below gives the forms of one group, as
the term `group-form-list` gives them.

#### 6.4.1 Hashes

@schema compute-hash-vector=v1
@cites {
    text#{
        conforming-program=v1, byte=v1, byte-sequence=v1, text=v1,
        character=v1, code-span=v1,
    },
    #{
        compute-hash=v1, hash=v1, json-value=v1, hex-text=v1,
        vector-line=v2, group-form-list=v2, vector-meaning=v2,
    },
}

The group `compute` holds the vector lines whose vectors each give a
byte sequence and its hash. The requirement of the group is
`compute-hash`. In `input` and `values`, a byte sequence is its hex
text, as a string, such as `"616263"` for the three bytes of `abc`, and
a text is a string of the characters of the text.

- `input`: the byte sequence.
- `result`: the forms of the group name no question for `result`.
- `values`: an object with one member, `hash`: the hash of the byte
  sequence, as a text.

When a conforming program gives a text as the hash of the byte
sequence, it gives the text of `hash`, and no other text.

```
{"form":"#compute-hash-vector=v1","group":"compute","input":"616263","values":{"hash":"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"}}
```

#### 6.4.2 The hash form

@schema validate-hash-vector=v1
@cites {
    text#{
        conforming-program=v1, text=v1, character=v1, result=v1,
        code-span=v1,
    },
    #{
        compute-hash-vector=v1, validate-hash=v1, hash-form=v1,
        json-value=v1, vector-line=v2, group-form-list=v2,
        vector-meaning=v2,
    },
}

The group `validate` holds the vector lines whose vectors each give a
text and the result that a conforming program gives for it when it
validates the text as a hash. The requirement of the group is
`validate-hash`. In `input`, a text is a string of the characters of the
text, as `compute-hash-vector` gives.

- `input`: the text.
- `result`: when a conforming program gives a result for whether the
  text fits the hash form, that result: "valid" when the text fits the
  hash form, and "invalid" when it does not.
- `values`: the forms of the group give no fixed form for `values`.

```
{"form":"#validate-hash-vector=v1","group":"validate","input":"BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD","note":"upper-case letters are not hex digits","result":"invalid"}
```

## 7. Hash ids
@spec hash-ids=v2

A conforming program can give the hash id of a byte sequence with an id
prefix and a number of hex digits from 1 to 64. When it gives a result
for whether a text fits the hash-id form with an id prefix and a number
of hex digits, it gives "valid" when the text fits the hash-id form, and
"invalid" when it does not.

The term `id-prefix` gives the id prefixes, such as `e-` or `t-`, and
the terms `hash-id` and `hash-id-form` give the hash ids and the hash-id
form. For example, with the id prefix `e-` and 12 hex digits, the hash
id of the three bytes of `abc` is `e-ba7816bf8f01`, the text
`e-5b1c0a9d2e11` fits the hash-id form, and `e-5b1c0a9d2e1`,
`e-5B1C0A9D2E11`, and `t-5b1c0a9d2e11` do not.

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

For an id prefix p, a whole number n from 1 to 64, and a byte sequence
b, the hash id of b with p and n is the text p, then the first n
characters of the hash of b.

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
    #{hash-id=v1},
}

A conforming program must give, as the hash id of a byte sequence b
with a text p and a whole number n, only the hash id of b with p and n.

### 7.3 The validation of hash ids

@req validate-hash-id=v1
@cites {
    text#{
        requirement=v1, conforming-program=v1, text=v1,
        whole-number=v1, result=v1,
    },
    #{id-prefix=v1, hash-id-form=v1},
}

When a conforming program gives a result for whether a text t fits the
hash-id form with an id prefix p and a whole number n from 1 to 64, it
must give exactly one result: "valid" when t fits the hash-id form with
p and n, and "invalid" when t does not fit the hash-id form with p and
n.

### 7.4 Conformance

A program conforms to the specification `hash-ids` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The file
[`data-forms.hash-ids.test-vectors.jsonl`](data-forms.hash-ids.test-vectors.jsonl),
in the same directory as this design, is a test-vector set, as the
specification `test-vectors` defines it. By the term `vector-meaning`,
the object of each vector line of the file states one vector of this
specification. This specification gives no need names.

The vectors follow from the requirements of this specification and add
nothing to them. Each subsection below gives the forms of one group, as
the term `group-form-list` gives them.

#### 7.4.1 Hash ids

@schema compute-hash-id-vector=v1
@cites {
    text#{
        conforming-program=v1, byte=v1, byte-sequence=v1, text=v1,
        character=v1, whole-number=v1, hex-digit=v1, code-span=v1,
    },
    #{
        compute-hash-id=v1, id-prefix=v1, hash-id=v1, json-value=v1,
        hex-text=v1, vector-line=v2, group-form-list=v2,
        vector-meaning=v2,
    },
}

The group `compute` holds the vector lines whose vectors each give an id
prefix, a number of hex digits, a byte sequence, and the hash id of the
byte sequence with that id prefix and that number of hex digits. The
requirement of the group is `compute-hash-id`. In `input` and `values`,
a byte sequence is its hex text, as a string, such as `"616263"` for
the three bytes of `abc`; a text, such as an id prefix, is a string of
the characters of the text; and a whole number is an integer.

- `input`: an object with three members: `id-prefix`, the id prefix;
  `number-of-hex-digits`, the number of hex digits; and
  `byte-sequence`, the byte sequence.
- `result`: the forms of the group name no question for `result`.
- `values`: an object with one member, `hash-id`: the hash id, as a
  text.

When a conforming program gives a text as the hash id of the byte
sequence with the id prefix and the number of hex digits, it gives the
text of `hash-id`, and no other text.

```
{"form":"#compute-hash-id-vector=v1","group":"compute","input":{"byte-sequence":"616263","id-prefix":"e-","number-of-hex-digits":12},"values":{"hash-id":"e-ba7816bf8f01"}}
```

#### 7.4.2 The hash-id form

@schema validate-hash-id-vector=v1
@cites {
    text#{
        conforming-program=v1, input=v1, text=v1, character=v1,
        whole-number=v1, hex-digit=v1, result=v1, code-span=v1,
    },
    #{
        compute-hash-id-vector=v1, validate-hash-id=v1, id-prefix=v1,
        hash-id-form=v1, json-value=v1, vector-line=v2,
        group-form-list=v2, vector-meaning=v2,
    },
}

The group `validate` holds the vector lines whose vectors each give a
text, an id prefix, a number of hex digits, and the result that a
conforming program gives for them when it validates the text as a hash
id. The requirement of the group is `validate-hash-id`. In `input`, a
text, such as an id prefix, is a string of the characters of the text,
and a whole number is an integer, as `compute-hash-id-vector` gives.

- `input`: an object with three members, one for each of the three
  inputs: `text`, the text; `id-prefix`, the id prefix; and
  `number-of-hex-digits`, the number of hex digits.
- `result`: the result of the three inputs together, when a conforming
  program gives a result for whether the text fits the hash-id form with
  the id prefix and the number of hex digits: "valid" when it fits, and
  "invalid" when it does not.
- `values`: the forms of the group give no fixed form for `values`.

```
{"form":"#validate-hash-id-vector=v1","group":"validate","input":{"id-prefix":"e-","number-of-hex-digits":12,"text":"e-5b1c0a9d2e1"},"note":"11 hex digits","result":"invalid"}
```

## 8. Test vectors
@spec test-vectors=v2

A vector is as the term `vector-meaning` gives it, and the object of a
vector line can state a vector. A conforming program can read a byte
sequence as a test-vector set.

By the term `test-vector-file-name`, the test-vector file name of a
design with the name `a` and of its specification with the name `b` is
`a.b.test-vectors.jsonl`, and that of `a` alone is
`a.test-vectors.jsonl`.

A test-vector set holds zero or more vector lines, as the schema
`test-vector-set` gives, and each vector line holds the canonical byte
sequence of a vector object, such as
`{"form":"#offsets-vector=v1","group":"offsets","input":"x","result":"valid"}`,
as the terms `vector-line` and `vector-object` give. All vector lines
with the same group in one test-vector set have the same schema part
name in their form pin, as the term `form-pin` gives, while their schema
labels may differ.

The forms of a group are as the term `group-form-list` gives them: a
schema declared in the Conformance section of a design, or in the
Conformance part of a specification, gives the first four things of the
forms of each group, and each vector line pins that schema in its member
`form`.

A vector object can also have the member `needs`, as in
`{"form":"#offsets-vector=v1","group":"offsets","input":"x","needs":["no-privilege"],"result":"valid"}`,
as the term `vector-object` gives. A need, and the check of the vectors
with its skips, are as the terms `group-form-list` and `vector-meaning`
give.

### 8.1 Definitions

#### 8.1.1 Test-vector file names

@term test-vector-file-name=v1
@cites text#{design=v1, specification=v1, text=v1, code-span=v1}

For the name x of a design and the name y of a specification of that
design, the test-vector file name of x and y is the text x, then `.`,
then the text y, then `.test-vectors.jsonl`. For the name x of a design,
the test-vector file name of x alone is the text x, then
`.test-vectors.jsonl`. So, for a design with the name `a` and a
specification of that design with the name `b`, the test-vector file
name of `a` and `b` is `a.b.test-vectors.jsonl`, and the test-vector
file name of `a` alone is `a.test-vectors.jsonl`.

#### 8.1.2 Form pins

@term form-pin=v1
@cites text#{production=v1, rule-name=v1, text=v1, code-span=v1}

A form pin is a text that matches the production `form-pin`:

```abnf
form-pin  = "#" segment "=" label
segment   = 1*alnum *( ( "-" / "_" / "." ) 1*alnum )
alnum     = ALPHA / DIGIT
label     = 1*( %x21-22 / %x24-29 / %x2B / %x2D-2E / %x30-3C
              / %x3E-3F / %x41-5A / %x5C / %x5E-7A / %x7C / %x7E )
```

The schema part name of a form pin is the text that `segment` matches
between its `#` and its `=`. The schema label of a form pin is the text
that `label` matches after its `=`.

#### 8.1.3 Group names

@term group-name=v1
@cites text#{production=v1, rule-name=v1, text=v1, code-span=v1}

A group name is a text that matches the production `group-name`:

```abnf
group-name  = %x61-7A *( %x61-7A / DIGIT ) *( "-" 1*( %x61-7A / DIGIT ) )
```

#### 8.1.4 Vector objects

@term vector-object=v2
@cites {
    text#{text=v1, code-span=v1},
    #{json-value=v1, form-pin=v1, group-name=v1, key-order=v1},
}

A member that a code span names, such as the member `group`, is the
member whose key is the text of the code span, and the value of `group`
is the value of the member `group`.

A vector object is an object that has the members `form`, `group`, and
`input`, has the member `result` or the member `values` or both, can
have the members `needs` and `note`, and has no other member. The value
of `form` is a string that is a form pin. The value of `group` is a
string that is a group name. The value of `input` is a JSON value. The
value of `result` is a string. The value of `values` is a JSON value.
The value of `note` is a string. The value of `needs` is an array of
one or more strings, each a text that matches the production
`group-name`, in which each string comes before the string after it in
key order.

#### 8.1.5 Vector lines

@term vector-line=v2
@cites {
    text#{byte=v1, 0x-numeral=v1, code-span=v1},
    #{json-value=v1, canonical-byte-sequence=v1, vector-object=v2},
}

A vector line is the canonical byte sequence of a vector object, then
the byte 0x0A. The object of a vector line is the object whose
canonical byte sequence it holds. The form of a vector line is the
value of `form` of its object. The group of a vector line is the value
of `group` of its object.

#### 8.1.6 Test-vector sets

@schema test-vector-set=v2
@cites {
    text#{byte-sequence=v1, text=v1},
    #{form-pin=v1, vector-line=v2},
}

A test-vector set is a byte sequence that holds zero or more vector
lines, one after another, and no other bytes, in which all vector lines
with the same group have the same schema part name in their form. The
schema labels of their forms may differ. A group of a test-vector set
is a text that is the group of one or more of its vector lines. The
vector lines of a group of a test-vector set are its vector lines whose
group is that group.

#### 8.1.7 The forms of a group

@term group-form-list=v2
@cites {
    text#{
        design=v1, specification=v1, requirement=v1,
        conforming-program=v1, input=v1, result=v1, text=v1, place=v1,
        byte-sequence=v1, line=v1, code-span=v1,
    },
    #{json-value=v1, hex-text=v1, group-name=v1, vector-object=v2},
}

For a specification S of a design and a group name g, the forms of the
group g of S are these five things. A schema declared in the
Conformance part of S gives the first four things for g, and the
Conformance part of S gives the fifth thing once for every group of S:

1. the requirements of the group g, which are requirements that S
   declares;
2. what the value of `input` of a vector object in which the value of
   `group` is g stands for: one input of a conforming program of S, or
   several inputs of it, such as a text and a place of that text; and
   the fixed form in which the value of `input` holds them, such as the
   hex text of a byte sequence;
3. the question that the value of `result` of such a vector object
   answers, such as whether a byte sequence is a TOML document, or no
   question for `result`; which of these inputs, or which of them
   together, that question is about; and the conditions under which the
   requirements of the group g oblige that result, if they oblige it
   only under some conditions, such as that a conforming program of S
   gives a result for that question. A need, the fifth thing, is never
   one of these conditions;
4. what the value of `values` of such a vector object stands for: what
   a conforming program of S gives, or does not give, for these inputs,
   other than the result that the value of `result` stands for, such as
   the results of the other inputs; and the fixed form in which the
   value of `values` holds it. The value of `values` can stand for a
   thing that the program gives when it gives a thing of that kind,
   such as the text of a byte sequence when the program gives a text
   for that byte sequence; for things of which the program gives one in
   place of another, such as a line and the text of that line; and for
   a thing that the program does not give. The forms can also give no
   fixed form for `values`; then no value of `values` has a fixed form,
   and the forms need not say what such a value stands for;
5. the need names of S, each a text that matches the production
   `group-name`, and for each need name, the need that it stands for: a
   condition on the environment in which a conforming program of S
   operates that a check of the vectors can be unable to make hold, such
   as that the file system stores a given entry name. A condition on
   what a conforming program gives, such as that it gives a result, is
   never a need. The Conformance part of S gives the need names once,
   and they are the same for each group of S. When the Conformance part
   of S gives no need name, S has no need names.

A fixed form, in the second and the fourth thing, is a shape of JSON
values: which of a string, an integer, a boolean, an array, or an object
each value is, their members, the values of their integers, and the
texts of their strings, such as a string that is the hex text of a byte
sequence, or an integer of 1 or more. When the forms give a shape for
each of several cases, such as one shape for each result, the fixed form
is any of these shapes. Whether a value has a fixed form depends on that
value alone: not on what it stands for, and not on the value of another
member, such as `input` or `result`.

For a design D and a group name g, the forms of the group g of D are the
same five things, where a schema declared in the Conformance section of
D gives the first four things for g and the Conformance section of D
gives the need names of D, with the requirements that D holds outside
its specifications in place of the requirements that S declares, with
the need names of D in place of the need names of S, and with a
conforming program of D in place of a conforming program of S.

#### 8.1.8 The meaning of a vector

@term vector-meaning=v2
@cites {
    text#{
        design=v1, specification=v1, requirement=v1,
        conforming-program=v1, input=v1, result=v1, code-span=v1,
    },
    #{
        json-value=v1, form-pin=v1, vector-object=v2, vector-line=v2,
        test-vector-set=v2, group-form-list=v2,
    },
}

For a specification S of a design, a vector of S is an input and what
requirements that S declares oblige a conforming program of S to give
for that input. For a design D, a vector of D is an input and what
requirements that D holds outside its specifications oblige a
conforming program of D to give for that input.

For a specification S, or a design D, and a vector line whose group is
g and whose form has the schema part name p, the object of the vector
line states one vector of S, or of D, when the schema declared under
the name p in the Conformance part of S, or in the Conformance section
of D, gives the first four things of the forms of the group g, and the
value of `input`, and the value of `values` when the object has that
member, have the fixed forms that these forms give; a value of `values`
has no fixed form when these forms give none. It then states that vector
by these forms, whatever other vector lines a test-vector set that holds
it has. Otherwise, the object of the vector line states no vector of S,
or of D. By the forms of the group g, the object of a vector line that
states a vector states this:

- The input of the vector is what the value of `input` stands for: one
  input of a conforming program of S, or of D, or several.
- The needs of the vector are the needs that the forms of the group g
  give for the strings of the value of `needs`. A string for which these
  forms give no need stands for no need, and a skip of a vector because
  of it counts as a decision that the program does not give what the
  object of its vector line states. A vector that an object without the
  member `needs` states has no needs.
- When the object has the member `result` and the forms name a question
  for `result`, the requirements of the group g oblige a conforming
  program of S, or of D, to give the result that is the value of
  `result`, such as `valid` for the result "valid", and no other result,
  as its result for the question that the forms name for `result`, about
  the input, or the inputs together, that the forms name for that
  question, whenever the conditions hold that the forms name for that
  result and each need of the vector holds; when the forms name no
  condition and the vector has no needs, they oblige it always. The
  object states nothing about a result for another question, or for
  another of these inputs, other than what the value of `values` stands
  for. When the forms name no question for `result`, the value of
  `result` states nothing.
- When the object has the member `values`, the requirements of the group
  g oblige a conforming program of S, or of D, to give, or not to give,
  for the input of the vector, what the value of `values` stands for,
  whenever each need of the vector holds.
- An object without the member `result` states no result other than
  those that the value of `values` stands for. An object without the
  member `values` states nothing about what a conforming program gives
  for the input of the vector, other than the result that the value of
  `result` stands for.
- The value of `note` explains the vector line, and it is no part of the
  input, the result, or the values. The value of `needs` is also no
  part of the input, the result, or the values.
- A check of the vectors of S, or of D, in a test-vector set decides,
  for each vector of S, or of D, that the object of a vector line of the
  test-vector set states, whether a program, when it operates while each
  need of the vector holds, gives what the object of its vector line
  states. A skip of a vector decides nothing about it when the check
  cannot make a need of the vector hold and reports that need. Each
  other skip of a vector counts as a decision that the program does not
  give what the object of its vector line states. Each of these
  decisions, a decision about a skip included, is a decision of the
  check, such as one run of a test that checks the vectors, and not of a
  reader of what the check reports.

### 8.2 Test-vector sets as input

@req read-test-vector-set=v2
@cites {
    text#{
        requirement=v1, conforming-program=v1, byte-sequence=v1,
        result=v1,
    },
    #{test-vector-set=v2},
}

When a conforming program gives a result for whether a byte sequence is
a test-vector set, it must give exactly one result: "valid" when the
byte sequence is a test-vector set, and "invalid" when it is not.

### 8.3 The objects of test-vector sets

@req give-objects-of-test-vector-sets=v2
@cites {
    text#{requirement=v1, conforming-program=v1, byte-sequence=v1},
    #{json-value=v1, vector-line=v2, test-vector-set=v2},
}

When a conforming program gives objects as the objects of a byte
sequence, it must give all the objects of the vector lines of the
test-vector set that the byte sequence is, each once and in their order,
and no other object.

### 8.4 Conformance

A program conforms to the specification `test-vectors` when it is a
[conforming program](sinter:text#conforming-program=v1) of that
[specification](sinter:text#specification=v1): it meets every
requirement that the specification declares.

The file
[`data-forms.test-vectors.test-vectors.jsonl`](data-forms.test-vectors.test-vectors.jsonl),
in the same directory as this design, is a test-vector set: its lines
are as the schema `test-vector-set` and the term `vector-line` give, so
the text of each line of the file is a JSON text, as RFC 8259 defines
it, and the members of their objects are as the term `vector-object`
gives. By the term `vector-meaning`, the object of each vector line of
the file states one vector of this specification. This specification
gives no need names.

The vectors follow from the requirements of this specification and add
nothing to them. Each subsection below gives the forms of one group, as
the term `group-form-list` gives them.

#### 8.4.1 Test-vector sets

@schema read-set-vector=v1
@cites {
    text#{
        conforming-program=v1, byte=v1, byte-sequence=v1,
        utf-8-encoding=v1, 0x-numeral=v1, result=v1, code-span=v1,
    },
    #{
        read-test-vector-set=v2, give-objects-of-test-vector-sets=v2,
        test-vector-set=v2, vector-line=v2, vector-meaning=v2,
        json-value=v1, hex-text=v1,
    },
}

The group `read-set` holds the vector lines whose vectors each give a
byte sequence and what a conforming program gives when it reads the byte
sequence as a test-vector set. The requirements of the group are
`read-test-vector-set` and `give-objects-of-test-vector-sets`. In
`input` and `values`, a byte sequence is its hex text, as a string, such
as
`"7b22666f726d223a2223613d7631222c2267726f7570223a2261222c22696e707574223a2278222c22726573756c74223a2276616c6964227d0a"`
for the UTF-8 encoding of
`{"form":"#a=v1","group":"a","input":"x","result":"valid"}`, then the
byte 0x0A.

- `input`: the byte sequence.
- `result`: when a conforming program gives a result for whether the
  byte sequence is a test-vector set, that result: "valid" when the byte
  sequence is a test-vector set, and "invalid" when it is not.
- `values`: when `result` is "valid", an object with one member,
  `objects`: an array of the objects of the vector lines of the byte
  sequence, in their order. When `result` is "invalid", the empty
  object, `{}`.

When a conforming program gives objects as the objects of the byte
sequence, it gives each object of `objects` once, in their order, and no
other object. When `values` is `{}`, it gives no object as an object of
the byte sequence.

```
{"form":"#read-set-vector=v1","group":"read-set","input":"7b22666f726d223a2223613d7631222c2267726f7570223a2261222c22696e707574223a2278222c22726573756c74223a2276616c6964227d0a","result":"valid","values":{"objects":[{"form":"#a=v1","group":"a","input":"x","result":"valid"}]}}
{"form":"#read-set-vector=v1","group":"read-set","input":"7b22726576223a227631227d0a","note":"a vector object has no member `rev` and requires `form`, `group`, and `input`","result":"invalid","values":{}}
```
