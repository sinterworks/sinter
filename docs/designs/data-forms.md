<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Data forms
@design data-forms=v1
@cites rfc/3339
@cites rfc/3629
@cites rfc/5234
@cites rfc/7405
@cites toml/1.1.0
@cites ieee/754-2019
@cites fips/180-4
Specifies the canonical form of JSON values and of canonical lines, the TOML documents that Sinter reads, SHA-256 hashes, and hash ids, and the requirements for conforming implementations that write, read, compute, and check them.

A JSON value is a string, an integer, a boolean, an array, or an object.
Each JSON value has one canonical form: a JSON text, as RFC 8259
defines it, with its keys in a fixed order and with no space, tab, line
feed, or carriage return outside its strings. A canonical line holds the
canonical bytes of one line object, which is an object of the restricted
shape that section 2.2 gives, and ends with the byte 0x0A. So a file of
canonical lines holds one line object on each line, and two programs
that write the same line objects in the same order write the same bytes.

A TOML document is a sequence of bytes that TOML 1.1.0 reads as a valid
document, with some further rules on tables. At each point where
TOML 1.1.0 lets an implementation choose, such as the range of a TOML
integer, a conforming implementation makes one fixed choice. SHA-256 is
a hash function: it gives a digest of 32 bytes for a sequence of bytes.
The hash of a sequence of bytes is its digest as 64 hex digits. A hash
id is an id prefix, such as `e-`, and then the first hex digits of a
hash.

The productions in section 3 use ABNF, the notation of RFC 5234. A
production, such as `hash = 64hex-digit`, gives the texts that its name
matches. `64hex-digit` repeats the element `hex-digit` exactly 64 times,
and `1*` repeats the element after it one or more times. In a
production, `/` separates two alternatives. `%x61` is the character
U+0061, and `%x61-7A` is any one character from U+0061 to U+007A. `"-"`
is the character `-`. `DIGIT` is the core rule of RFC 5234 for the
characters `0` to `9`.

From the standards that it cites, the design takes these parts:

| standard | what the design takes from it |
|---|---|
| RFC 3339 | the meaning of the offset of an offset date-time |
| RFC 3629 | the UTF-8 encoding of a text |
| RFC 5234, RFC 7405 | the notation of the productions |
| TOML 1.1.0 | TOML documents, their tables, their TOML keys, and their TOML values |
| IEEE 754-2019 | the binary64 format of floating-point numbers, and rounding to nearest with ties to even |
| FIPS 180-4 | the hash function SHA-256 |

## 1. Terms

| term | meaning |
|---|---|
| conforming implementation | a program that meets every requirement of section 3 |
| must | states an obligation of a conforming implementation |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| production | a rule of ABNF, such as `hash = 64hex-digit`, which gives the texts that its name matches |
| character | one Unicode scalar value: a code point that is not from U+D800 to U+DFFF |
| text | a sequence of characters |
| byte | a whole number from 0 to 255 |
| UTF-8 encoding | the sequence of bytes that RFC 3629 gives for a text |
| byte order mark | the bytes 0xEF, 0xBB, and 0xBF, which are the UTF-8 encoding of the character U+FEFF |
| line feed | the character U+000A, whose UTF-8 encoding is the byte 0x0A |
| result | what a conforming implementation gives for an input that it reads or checks: valid or invalid |
| JSON value | a string, an integer, a boolean, an array, or an object |
| string | a text, as a JSON value |
| integer | a whole number from −(2^53 − 1) to 2^53 − 1, as a JSON value |
| boolean | true or false, as a JSON value |
| array | a sequence of JSON values, its elements |
| object | a set of members in which no two members have the same key |
| member | a key and a JSON value, which is the value of the member |
| key | the text that a member of an object holds beside its JSON value |
| scalar | a string, an integer, or a boolean |
| flat object | an object in which the value of each member is a scalar |
| line object | an object in which the value of each member is a scalar, an array of scalars, or an array of flat objects |
| UTF-16 code unit | a number from 0 to 65535; a character has one or two of them, as UTF-16 encodes it |
| key order | the order of texts by their UTF-16 code units, in which the keys of an object stand in its canonical form |
| canonical form | the one text that the rules of section 2.3 give for a JSON value |
| string form | the text that stands for one character of a string in the canonical form of the string, such as `\n` for the line feed and `a` for `a` |
| escape sequence | in a JSON text, a basic string, a multi-line basic string, or a quoted key of TOML 1.1.0, a sequence of characters that starts with `\` and stands for a character, such as `\n` for the line feed |
| noncharacter | a character from U+FDD0 to U+FDEF, or a character whose code point ends in FFFE or FFFF in hex, such as U+FFFF |
| canonical bytes | the UTF-8 encoding of the canonical form of a JSON value |
| canonical line | the canonical bytes of a line object, then the byte 0x0A |
| TOML document | a sequence of bytes that TOML 1.1.0 reads as a valid document, with all the rules of TOML 1.1.0 and with the rules of sections 2.5 and 2.6, which add to them |
| key/value pair, inline table, table header, array of tables, quoted key, basic string, multi-line basic string, literal string, multi-line literal string | the parts of a document that TOML 1.1.0 calls by these names |
| integer of TOML 1.1.0, float of TOML 1.1.0 | the parts of a document that TOML 1.1.0 calls integers and floats, such as `-17` and `1e400` |
| TOML key | a key of TOML 1.1.0 that is not a dotted key, such as `a` or `"a"`; it is the key of a TOML value in a table |
| dotted key | a key of TOML 1.1.0 that joins two or more TOML keys with `.`, such as `b.c.x`; these are the TOML keys of the dotted key |
| TOML value | a value of a TOML document, of one of ten kinds: a TOML string, a TOML integer, a TOML float, a TOML boolean, a local date, a local time, a local date-time, an offset date-time, a TOML array, or a table |
| TOML string, TOML integer, TOML float, TOML boolean, TOML array | a TOML value of the type string, integer, float, boolean, or array of TOML 1.1.0 |
| local date, local time, local date-time, offset date-time | the TOML values of TOML 1.1.0 that have these names |
| table | a TOML value that is a set of pairs, each the text of a TOML key and its TOML value, with no order |
| equal | the relation of two TOML values of the same kind whose parts match: texts that are the same text, numbers that are the same number, and TOML values that are equal; two TOML floats are equal when their binary64 values have the same bits or both are NaN |
| newline | in a TOML document, the character U+000A, or the characters U+000D and U+000A |
| line ending backslash | in a multi-line basic string, a `\` that starts no escape sequence and is the last character on its line apart from tabs and spaces |
| root table | the top-level table of a TOML document |
| place | a position before, between, or after the characters of a document |
| location | the sequence of steps from the root table to a table: texts of TOML keys and positions in TOML arrays; two tables with the same location are the same table |
| super-table | a table on the way from the root table to the table that a table header names, such as `a` and `a.b` for `[a.b.c]` |
| undefined super-table | at a place in a TOML document, a super-table of a table that a table header before that place names, when no table header, no key/value pair, and no inline table before that place defines the super-table |
| holding table | the table at which the key of a key/value pair starts: the table of the innermost inline table that holds the key/value pair, else the table that the last table header before it names, else the root table |
| path of a dotted key | the tables that the TOML keys of the dotted key of a key/value pair, apart from its last TOML key, lead to from the holding table of the key/value pair, one after another |
| hex digit | one of the characters `0` to `9` and `a` to `f` |
| hex text | the hex digits that stand for a sequence of bytes, two for each byte |
| digest | the 32 bytes that SHA-256 gives for a sequence of fewer than 2^61 bytes |
| hash | the hex text of a digest: 64 hex digits |
| id prefix | one or more lower-case ASCII letters and then `-`, such as `e-` |
| hash id | an id prefix, then the first hex digits of a hash, such as `e-ba7816bf8f01` |

## 2. The data forms

### 2.1 Characters, texts, and bytes

A character is one Unicode scalar value: a code point from U+0000 to
U+D7FF, or from U+E000 to U+10FFFF. A text is a sequence of characters.
Two texts are the same text when, and only when, they hold the same
characters in the same order.

A conforming implementation keeps each text as it is. It normalizes no
Unicode, and it changes the case of no letter. So the text U+00E9 and
the text of U+0065 and U+0301 are two different texts, although both
show as the letter e with an acute accent. The texts `a` and `A` are
two different texts too.

A byte is a whole number from 0 to 255. The UTF-8 encoding of a text
is the sequence of bytes that RFC 3629 gives for its characters, and no
other bytes. The byte order mark is the three bytes 0xEF, 0xBB, and
0xBF, which are the UTF-8 encoding of the character U+FEFF. So the UTF-8
encoding of a text starts with the byte order mark only when the text
starts with the character U+FEFF.

### 2.2 JSON values

A JSON value is one of five things:

| JSON value | what it is |
|---|---|
| string | a text |
| integer | a whole number from −9007199254740991 to 9007199254740991, which is from −(2^53 − 1) to 2^53 − 1 |
| boolean | true or false |
| array | a sequence of JSON values, its elements; it can be empty |
| object | a set of members; it can be empty |

A member of an object is a key, which is a text, and a JSON value, the
value of the member. No two members of one object have the same key.
Because two texts are the same only when they hold the same characters,
an object can hold the key U+00E9 and the key of U+0065 and U+0301 as
two members.

A JSON value is never null, and it is never a number that is not an
integer, such as `1.5`.

A scalar is a string, an integer, or a boolean. A flat object is an
object in which the value of each member is a scalar. A line object is
an object in which the value of each member is one of these:

- a scalar;
- an array whose elements are all scalars, such as `[1,"a",true]`;
- an array whose elements are all flat objects, such as
  `[{"a":1},{"b":"x"}]`.

An empty array is an array of scalars and also an array of flat
objects. A line object can be empty. These are not line objects:

| object | why it is not a line object |
|---|---|
| `{"a":{"b":1}}` | the value of `a` is an object |
| `{"a":[[1]]}` | the value of `a` is an array that holds an array |
| `{"a":[1,{"b":1}]}` | the value of `a` mixes a scalar and an object |
| `{"a":[{"b":[1]}]}` | the object `{"b":[1]}` is not a flat object |

### 2.3 The canonical form

The canonical form of a JSON value is a text. These rules give it:

| JSON value | canonical form |
|---|---|
| string | `"`, then the string form of each character of the string, in order, then `"` |
| integer | the decimal digits of its absolute value, with no leading zero, after `-` when the integer is less than 0; `0` for 0 |
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
| each other character from U+0000 to U+001F | `\u00` and two lower-case hex digits, such as `\u001f` for U+001F |
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
  first 0xD800 plus the quotient of c − 0x10000 divided by 0x400, then
  0xDC00 plus the remainder.

One key comes before another when, at the first position where their
code units differ, its code unit is less. A key also comes before every
longer key whose code units start with all of its code units, so `a`
comes before `ab`.

Key order agrees with the order of code points and with the order of
the bytes of UTF-8, except in one case: at the first position where two
keys differ, one key has a character from U+E000 to U+FFFF, and the
other key has a character from U+10000 to U+10FFFF. For example, the key
U+1F600 (the code units 0xD83D and 0xDE00) comes before the key U+E000
(the code unit 0xE000) in key order, but after it in the order of code
points.

The canonical bytes of a JSON value are the UTF-8 encoding of its
canonical form. Two different JSON values never have the same canonical
form. Each canonical form is a JSON text, as RFC 8259 defines it.

A noncharacter is a character from U+FDD0 to U+FDEF, or a character
whose code point ends in FFFE or FFFF in hex, such as U+FFFF or
U+10FFFE. For a JSON value in whose strings and keys no character is a
noncharacter, the canonical form is also the text that the JSON
Canonicalization Scheme of RFC 8785 gives for the JSON value.

In these examples, a JSON text gives each JSON value:

| JSON value | canonical form |
|---|---|
| `{ "b": 1, "a": [true, false] }` | `{"a":[true,false],"b":1}` |
| `{ "ab": 1, "a": 2 }` | `{"a":2,"ab":1}` |
| `"a/b"` | `"a/b"` |
| `"x\u000by"` | `"x\u000by"` |
| `-42` | `-42` |

### 2.4 Canonical lines

A canonical line is the canonical bytes of a line object, then the byte
0x0A. The canonical bytes never hold the byte 0x0A: a line feed in a
string has the string form `\n`, and the UTF-8 encoding of no other
character holds the byte 0x0A. So the byte 0x0A ends each canonical
line, and a file of canonical lines divides into its lines at each byte
0x0A.

A conforming implementation reads a sequence of bytes as a canonical
line. It gives the result valid and the line object when the bytes are
the canonical line of a line object. It gives the result invalid for
every other sequence of bytes. These sequences of bytes are not
canonical lines. A row that mentions the byte 0x0A, or that says "and
no byte 0x0A", gives all the bytes. Every other row gives the bytes
before one last byte 0x0A, which the row leaves out.

| bytes | why they are not a canonical line |
|---|---|
| `{"b":1,"a":2}` | the keys are not in key order |
| `{"a": 2}` | a space stands outside a string |
| `{"a":2}`, and no byte 0x0A | the bytes do not end with the byte 0x0A |
| `{"a":2}`, 0x0D, and 0x0A | the byte 0x0D stands before the byte 0x0A |
| `{"a":1.0}` | `1.0` is not the canonical form of an integer |
| `{"a":null}` | null is not a string, an integer, a boolean, an array, or an object |
| `{"a":"\u0041"}` | the string form of `A` is `A` |
| `[1]` | the JSON value is not an object |

### 2.5 TOML documents

In this section and in section 2.6, a text in a code block stands for
its UTF-8 encoding.

A TOML document is a sequence of bytes that TOML 1.1.0 reads as a valid
document, with all the rules of TOML 1.1.0 and with the rules of this
section and of section 2.6, which add to them.

When the bytes start with the byte order mark, a conforming
implementation reads only the bytes after the byte order mark by the
rules of TOML 1.1.0. Elsewhere in the bytes, the bytes 0xEF, 0xBB, and
0xBF are the UTF-8 encoding of the character U+FEFF, which TOML 1.1.0
allows in a string and in a comment.

A TOML key is a key of TOML 1.1.0 that is not a dotted key, such as `a`,
`"a"`, or `"\u00e9"`. A dotted key joins two or more TOML keys with
`.`, such as `b.c.x`, and these are the TOML keys of the dotted key. The
text of a TOML key is the text that TOML 1.1.0 gives for it after its
escape sequences resolve, with no other change. Two TOML keys are the
same key of TOML 1.1.0 when, and only when, their texts are the same
text. So the TOML keys `a` and `"a"` are the same key of TOML 1.1.0, and
the TOML keys `"\u00e9"` and `"e\u0301"` are two different keys of
TOML 1.1.0.

The root table of a TOML document is its top-level table. A table is a
set of pairs. Each pair is the text of a TOML key and the TOML value of
that TOML key, and no two pairs of one table have the same text. The
pairs of a table have no order. A TOML value is of one of ten kinds:

| kind | what a TOML value of the kind is |
|---|---|
| TOML string | a text |
| TOML integer | a whole number from −2^63 to 2^63 − 1 |
| TOML float | an IEEE 754 binary64 value |
| TOML boolean | true or false |
| local date | a year, a month, and a day |
| local time | an hour, a minute, a second, and a fraction of a second |
| local date-time | a local date and a local time |
| offset date-time | a local date-time and an offset |
| TOML array | a sequence of TOML values |
| table | a set of pairs, each the text of a TOML key and a TOML value |

A document gives each TOML value in the syntax of TOML 1.1.0. For
example, the integer `0x1F` of TOML 1.1.0 gives the TOML integer 31,
and the float `1e3` of TOML 1.1.0 gives a TOML float. A basic string, a multi-line
basic string, a literal string, or a multi-line literal string gives a
TOML string.

At some points, TOML 1.1.0 lets an implementation choose. A conforming
implementation makes these choices:

| point | choice |
|---|---|
| bytes that are not the UTF-8 encoding of a text | the bytes are not a TOML document, and a conforming implementation replaces no byte with U+FFFD |
| the range of a TOML integer | from −9223372036854775808 to 9223372036854775807, which is from −2^63 to 2^63 − 1; an integer of TOML 1.1.0 that stands for a number outside the range makes the bytes not a TOML document |
| the TOML float of a float of TOML 1.1.0 other than `inf`, `+inf`, `-inf`, `nan`, `+nan`, and `-nan` | the IEEE 754 binary64 value that rounding to nearest, with ties to even, gives for the number that the float of TOML 1.1.0 stands for; its sign bit is 1 when, and only when, the float of TOML 1.1.0 starts with `-`, so `-0.0` gives negative zero |
| a float of TOML 1.1.0 that rounds to an infinity, such as `1e400` | the bytes are not a TOML document |
| the floats `inf`, `+inf`, `-inf`, `nan`, `+nan`, and `-nan` of TOML 1.1.0 | `inf` and `+inf` give positive infinity, and `-inf` gives negative infinity; `nan`, `+nan`, and `-nan` each give a TOML float that is NaN |
| more than nine digits in the fraction of a second | a local time, a local date-time, and an offset date-time keep the first nine digits, and the further digits do not change the fraction |
| the second 60 | a valid second of a local time, a local date-time, and an offset date-time, on every date and at every hour and minute |
| a newline in a multi-line basic string or a multi-line literal string | each newline that TOML 1.1.0 does not trim stays in the TOML string as its characters: U+000A, or U+000D and U+000A |
| an escape sequence that TOML 1.1.0 reserves, such as `\q`, in a basic string or a multi-line basic string | the bytes are not a TOML document |

So `00:00:00.123456789123` and `00:00:00.123456789` give equal local
times.

TOML 1.1.0 writes an offset date-time in the form of RFC 3339, and
RFC 3339, section 4.3, gives the meaning of its offset. The offset of an
offset date-time is the unknown local offset when the document gives
the offset as `-00:00`. Otherwise, the offset is a signed number of
minutes: 0 for `Z` and `z`, and the number of minutes that the document
gives for each other offset, such as 0 for `+00:00` and −420 for
`-07:00`. The unknown local offset is not a number of minutes, so it is
not the offset 0. So the offset date-times `1979-05-27T07:32:00Z` and
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

The text of a TOML string is the text that TOML 1.1.0 gives for its
basic string, multi-line basic string, literal string, or multi-line
literal string after the escape sequences resolve, with no other change.
When the document gives no second for a local time, a local date-time,
or an offset date-time, its second is 0. When the document gives no
fraction of a second for it, its fraction of a second is 0. So `12:30`,
`12:30:00`, and `12:30:00.000` give equal local times.

Two TOML values are equal when, and only when, they are of the same kind
and their parts match: texts are the same text, numbers are the same
number, and TOML values in them are equal. Two TOML floats are equal
when, and only when, their binary64 values have the same bits, or both
are NaN. So `-0.0` and `0.0` give two TOML floats that are not equal.

The root table depends only on the TOML keys and the TOML values, and
not on the syntax of TOML 1.1.0 that gives them. A table header, a
dotted key, and an inline table each give a table. So these three texts
give equal root tables, in which the TOML key `a` holds a table that
holds the TOML key `b` with the TOML integer 1:

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
`]` around TOML values give a TOML array. So these two texts give equal
root tables, in which the TOML key `a` holds a TOML array of one table,
and that table holds the TOML key `b` with the TOML integer 1:

```toml
a = [{ b = 1 }]
```

```toml
[[a]]
b = 1
```

A conforming implementation reads a sequence of bytes as a TOML
document. It gives the result valid and the root table when the bytes
are a TOML document, and the result invalid otherwise.

### 2.6 Table headers, key/value pairs, and inline tables

A place in a document is a position before, between, or after its
characters. The tables and TOML values at a place are those that the
text before that place makes, as TOML 1.1.0 reads that text in its
order. So a table can hold more TOML keys at a later place than at an
earlier place.

The location of a table is the sequence of steps that leads to it from
the root table. Each step is the text of a TOML key, or the position of
a table in a TOML array. Two tables of a document are the same table
when, and only when, they have the same location. So two empty tables
with different locations are two different tables.

A table header names one table. The table header `[a.b.c]` names the
table at the TOML keys `a`, `b`, `c` from the root table. It also makes
the tables `a` and `a.b` when they do not exist yet. The tables `a` and
`a.b` are the super-tables of the table `a.b.c`. A table header of an
array of tables, such as `[[a.b]]`, names the new table that it adds to
the array of tables at the TOML keys `a`, `b`.

A conforming implementation reads each table header and each key/value
pair at its place in the document. Where a TOML key leads to an array of
tables, it leads to the last table that a table header before that place
adds to the array of tables. In this text, the table header on line 2
names the table `b` in the first table of the array of tables `a`, and
the key/value pair on line 5 makes the table `b` in the second table of
that array of tables. The text is a TOML document:

```toml
[[a]]
[a.b]
z = 1
[[a]]
b.x = 1
```

The key of a key/value pair starts at the holding table of the
key/value pair: the table of the innermost inline table that holds the
key/value pair, or else the table that the last table header before it
names, or else the root table. An inline table holds each key/value
pair and each inline table between its braces. The key of a key/value
pair can be a dotted key, such as `b.c.x` in `b.c.x = 1`. Each TOML key of the dotted key before its last TOML key
leads to the next table of the path of the dotted key. Under the table
header `[a]`, the dotted key `b.c.x` has the path `a.b`, `a.b.c`, and
its last TOML key is `x`.

TOML 1.1.0 itself has these rules on tables:

- A document defines no table twice, and it adds no TOML key twice to
  one table.
- An inline table defines all the TOML keys and tables in it, and no
  TOML key or table is added to it outside its braces. So an inline
  table, and each table in it, holds no table that a table header names.
- A dotted key does not define again a table that a table header defines.
- A table header can define a table in a table that dotted keys define.

These rules of TOML 1.1.0 do not say exactly which table header,
key/value pair, or inline table defines a table. A conforming
implementation reads a document with these further rules:

- A table header defines the table that it names, and no other table.
  So a table header does not define the super-tables that it makes.
- At a place in a document, an undefined super-table is a table that is
  a super-table of a table that a table header before that place names,
  and that no table header, no key/value pair, and no inline table
  before that place defines.
- A key/value pair defines each table of the path of its dotted key
  that, at the place right before the key/value pair, does not exist yet
  or is an undefined super-table. Through its dotted key, a key/value
  pair defines no other table.
- An inline table defines its table.
- No two of the table headers, the key/value pairs, and the inline
  tables of a document define the same table.
- At the place right before a key/value pair, the TOML keys of its key
  lead from its holding table to no TOML value: the key/value pair adds
  a TOML key that the table does not hold yet.
- No table of the path of a dotted key is a table that a table header
  before the key/value pair of the dotted key names.
- When no inline table holds a key/value pair, a document is not invalid
  only because a table that the key/value pair defines holds a table
  that a table header names, before or after the key/value pair.

So this text is a TOML document. Before line 2, the table `a` is an
undefined super-table, and the table header on line 2 defines it:

```toml
[a.b]
[a]
x = 1
```

This text is not a TOML document, because the table headers on lines 2
and 3 both define the table `a`:

```toml
[a.b]
[a]
[a]
```

This text is not a TOML document either. Before line 3, the tables
`a.b` and `a.b.c` of the path of the dotted key `b.c.e` are undefined
super-tables, so the key/value pair on line 3 defines both of them. Then
the table header on line 4 defines the table `a.b` a second time:

```toml
[a.b.c.d]
[a]
b.c.e = 1
[a.b]
```

This text is not a TOML document, because the inline table on line 1
and the table header on line 2 both define the table `a`:

```toml
a = {}
[a]
```

This text is not a TOML document either. The key/value pair on line 1
defines the table `a`, and its inline table defines the table `a.b`.
Then the table header on line 2 defines the table `a.b` a second time:

```toml
a.b = {}
[a.b]
```

This text is not a TOML document, because the table header on line 2
adds the table `x.b.d` to the table `x.b`, which is in the inline table
on line 1:

```toml
x = { b.c = 1 }
[x.b.d]
```

This text is not a TOML document, because the table `a` already holds
the TOML key `b` before line 3. The table header on line 1 makes the
super-table `a.b`, so the key/value pair on line 3 cannot add the TOML
key `b` to the table `a`:

```toml
[a.b.c]
[a]
b = { d = 1 }
```

The path of a dotted key does not go into a table that a table header
names. This text is not a TOML document, because the table `a.b.c`,
which the table header on line 1 names, is in the path of the dotted
key `b.c.x` on line 4:

```toml
[a.b.c]
z = 9
[a]
b.c.x = 1
```

To add the TOML key `x` to the table `a.b.c`, put it under the table
header that names the table:

```toml
[a.b.c]
z = 9
x = 1
```

The rule applies to a table header of an array of tables too. This text
is not a TOML document, because the last table of the array of tables
`a.b`, which the table header on line 1 names, is in the path of the
dotted key `b.y` on line 3:

```toml
[[a.b]]
[a]
b.y = 2
```

The key of a table header can be a dotted key too, such as `q.r` in
`[q.r]`. The table header names a table from the root table, so that
dotted key has no holding table and no path. If the dotted key `q.r` in
this text started at the table `p`, its path would hold the table `p.q`,
which the table header on line 1 names. But the table header `[q.r]`
names the table `q.r` from the root table. The tables `p.q` and `q.r`
are both empty, and they have different locations, so they are two
different tables. The text is a TOML document:

```toml
[p.q]
[p]
[q.r]
```

When no inline table holds a key/value pair, a table that the key/value
pair defines can hold tables that table headers name, before or after
the key/value pair. In this text, the table header on line 1 makes the
table `a.b` as a super-table of `a.b.c`. Before line 4, `a.b` is an
undefined super-table, so the key/value pair on line 4 defines `a.b` and
adds the TOML key `ct` to it. Then `a.b` holds both the TOML key `ct`
and the table `a.b.c`, which a table header names. The key/value pair on
line 5 makes and defines the new table `a.b.x`. The text is a TOML
document:

```toml
[a.b.c]
z = 9
[a]
b.ct = 1
b.x.y = 1
```

After the key/value pair on line 4 defines `a.b`, the table header
`[a.b]` on line 5 defines it a second time. So this text is not a TOML
document:

```toml
[a.b.c]
z = 9
[a]
b.ct = 1
[a.b]
```

### 2.7 Hashes

A hex digit is one of the sixteen characters `0` to `9` and `a` to `f`,
for the numbers 0 to 15. The hex text of a byte is two hex digits: the
hex digit of the quotient of the byte divided by 16, then the hex digit
of the remainder. So the hex text of the byte 0x3F is `3f`. The hex text
of a sequence of bytes is the hex texts of its bytes, in their order.

FIPS 180-4 defines SHA-256 for each message of fewer than 2^64 bits,
so it gives a digest for each sequence of fewer than 2^61 bytes. The
digest of such a sequence of bytes is the 32 bytes of the message
digest that SHA-256 gives for it. The hash of the sequence of bytes is
the hex text of its digest: 64 hex digits. For example, the hash of the
three bytes of `abc` is
`ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`.

A text has the form of a hash when it holds exactly 64 hex digits and
nothing else. Upper-case letters are not hex digits, so
`BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD` does
not have the form of a hash.

### 2.8 Hash ids

An id prefix is one or more lower-case ASCII letters and then `-`, such
as `e-` or `t-`. For an id prefix, a number n of hex digits from 1 to
64, and a sequence of fewer than 2^61 bytes, the hash id is the id
prefix, then the first n hex digits of the hash of the bytes. For
example, with the id prefix `e-` and 12 hex digits, the hash id of the
three bytes of `abc` is `e-ba7816bf8f01`.

A text has the form of a hash id with an id prefix and a number n of hex
digits when it is the id prefix and then exactly n hex digits. So with
the id prefix `e-` and 12 hex digits, `e-5b1c0a9d2e11` has the form of
a hash id, and `e-5b1c0a9d2e1`, `e-5B1C0A9D2E11`, and `t-5b1c0a9d2e11`
do not.

### 2.9 What an implementation gives

| input | what a conforming implementation gives |
|---|---|
| a JSON value | its canonical bytes |
| a sequence of bytes, as a canonical line | valid and the line object, or invalid |
| a sequence of bytes, as a TOML document | valid and the root table, or invalid |
| a sequence of fewer than 2^61 bytes | its hash |
| a text, as a hash | valid or invalid |
| an id prefix, a number of hex digits, and a sequence of fewer than 2^61 bytes | the hash id |
| a text, an id prefix, and a number of hex digits, as a hash id | valid or invalid |

## 3. Requirements

### 3.1 Characters and texts

@req characters=v1

A character is a Unicode scalar value: a code point from U+0000 to
U+D7FF, or from U+E000 to U+10FFFF. A text is a finite sequence of
characters. Two texts are the same text when, and only when, they have
the same number of characters and the same character at each position.

### 3.2 Bytes

@req bytes=v1
@cites {rfc/3629, #{characters=v1}}

A byte is a whole number from 0 to 255. The UTF-8 encoding of a text is
the sequence of bytes that RFC 3629 gives for the characters of the
text, in their order, and no other bytes.

### 3.3 The byte order mark

@req byte-order-mark=v1
@cites #bytes=v1

The byte order mark is the sequence of the three bytes 0xEF, 0xBB, and
0xBF, in that order.

### 3.4 Notation

@req notation=v1
@cites {rfc/5234, rfc/7405, #{characters=v1}}

The productions of this design are rules of ABNF, the notation of
RFC 5234, with the case-sensitive strings of RFC 7405. They use the core
rules of RFC 5234, Appendix B.1. Each terminal value of a production is
the code point of one character. A text matches a production when, and
only when, the production matches the whole of the text.

### 3.5 Results

@req results=v1

A result is one of two values: valid and invalid.

### 3.6 Hex digits

@req hex-digits=v1
@cites #{notation=v1, characters=v1}

This production gives a hex digit:

```abnf
hex-digit  = DIGIT / %x61-66
```

The hex digit of a number from 0 to 15 is the character `0`, `1`, `2`,
`3`, `4`, `5`, `6`, `7`, `8`, `9`, `a`, `b`, `c`, `d`, `e`, or `f`, in
that order: `0` for 0, and `f` for 15.

### 3.7 Hex texts

@req hex-text=v1
@cites #{hex-digits=v1, bytes=v1, characters=v1}

The hex text of a byte is two hex digits: the hex digit of the quotient
of the byte divided by 16, then the hex digit of the remainder. The hex
text of a sequence of bytes is the hex texts of its bytes, in their
order, one after another.

### 3.8 JSON values

@req json-values=v1
@cites #characters=v1

A JSON value is a string, an integer, a boolean, an array, or an object.
A string is a text. An integer is a whole number from
−9007199254740991 to 9007199254740991. A boolean is true or false. An
array is a finite sequence of JSON values, which are its elements. An
object is a finite set of members. A member is a pair of a key, which is
a text, and a JSON value, which is the value of the member. No two
members of one object have the same key.

### 3.9 Key order

@req key-order=v1
@cites #characters=v1

The UTF-16 code units of a character whose code point c is less than
0x10000 are the one number c. The UTF-16 code units of a character
whose code point c is 0x10000 or more are two numbers: first 0xD800
plus the quotient of c − 0x10000 divided by 0x400, then 0xDC00 plus the
remainder of that division. The UTF-16 code units of a text are the
code units of its characters, in their order. In key order, a text t
comes before a different text u when, and only when, one of these
holds:

- At the first position where the code units of t and of u differ, the
  code unit of t is less than the code unit of u.
- The code units of t are fewer than the code units of u, and they are
  the same as the first code units of u.

### 3.10 The canonical form

@req canonical-form=v1
@cites #{
    json-values=v1, characters=v1, hex-text=v1, key-order=v1,
    bytes=v1,
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
- The decimal numeral of a whole number n that is 0 or more is `0` when
  n is 0. Otherwise, it is the decimal digits of n, the first of which
  is not `0`. The canonical form of an integer that is 0 or more is its
  decimal numeral. The canonical form of an integer that is less than 0
  is `-`, then the decimal numeral of its absolute value.
- The canonical form of the boolean true is `true`, and of the boolean
  false is `false`.
- The canonical form of an array is `[`, then the canonical forms of its
  elements in their order, with `,` between each two of them, then `]`.
- The canonical form of an object is `{`, then the canonical forms of
  its members in the key order of their keys, with `,` between each two
  of them, then `}`. The canonical form of a member is the canonical
  form of its key as a string, then `:`, then the canonical form of its
  value.

The canonical bytes of a JSON value are the UTF-8 encoding of its
canonical form.

### 3.11 Writing the canonical form

@req write-canonical-json=v1
@cites #{json-values=v1, canonical-form=v1}

For each JSON value, a conforming implementation must give its
canonical bytes.

### 3.12 Line objects

@req line-objects=v1
@cites #json-values=v1

A scalar is a string, an integer, or a boolean. A flat object is an
object in which the value of each member is a scalar. A line object is
an object in which the value of each member is one of these three:

- a scalar;
- an array in which each element is a scalar;
- an array in which each element is a flat object.

### 3.13 Canonical lines

@req canonical-lines=v1
@cites #{line-objects=v1, canonical-form=v1, bytes=v1}

The canonical line of a line object is the canonical bytes of the line
object, then the byte 0x0A.

### 3.14 Reading canonical lines

@req read-canonical-line=v1
@cites #{bytes=v1, results=v1, line-objects=v1, canonical-lines=v1}

For each sequence of bytes, a conforming implementation must give the
result valid and the line object whose canonical line the bytes are,
when the bytes are the canonical line of a line object. For every other
sequence of bytes, it must give the result invalid.

### 3.15 TOML keys

@req toml-keys=v1
@cites {toml/1.1.0, #{characters=v1}}

These definitions use the terms key, dotted key, and escape sequence of
TOML 1.1.0.

- A TOML key is a key of TOML 1.1.0 that is not a dotted key.
- The TOML keys of a key of TOML 1.1.0 are the key itself when it is a
  TOML key. When it is a dotted key, they are the TOML keys that the
  dotted key joins with `.`, in their order.
- The text of a TOML key is the text that TOML 1.1.0 gives for the TOML
  key after its escape sequences resolve, with no other change.
- Two TOML keys are the same key of TOML 1.1.0 when, and only when,
  their texts are the same text.

### 3.16 TOML values

@req toml-values=v1
@cites {toml/1.1.0, ieee/754-2019, #{characters=v1, toml-keys=v1}}

These definitions use the terms value, string, integer, float, boolean,
array, local date, local time, local date-time, offset date-time, and
table of TOML 1.1.0.

- A TOML value is a value of TOML 1.1.0. A TOML string, a TOML integer,
  a TOML float, a TOML boolean, and a TOML array are the TOML values of
  the types string, integer, float, boolean, and array of TOML 1.1.0.
- Each TOML value is of one of these ten kinds: a TOML string, which is
  a text; a TOML integer, which is a whole number; a TOML float, which
  is an IEEE 754 binary64 value; a TOML boolean, which is true or false;
  a local date, which is a year, a month, and a day; a local time, which
  is an hour, a minute, a second, and a fraction of a second; a local
  date-time, which is a local date and a local time; an offset
  date-time, which is a local date-time and an offset; a TOML array,
  which is a sequence of TOML values; and a table.
- A table is a set of pairs. Each pair is the text of a TOML key and a
  TOML value, which is the TOML value of that text in the table. No two
  pairs of one table have the same text. The pairs of a table have no
  order.

### 3.17 Equal TOML values

@req toml-value-equality=v1
@cites {ieee/754-2019, #{toml-values=v1, characters=v1}}

Two TOML values are equal when, and only when, they are of the same kind
and one of these holds:

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
  their TOML values at each position are equal.
- They are tables with the same texts of TOML keys, and their TOML
  values of each of these texts are equal.

### 3.18 The encoding of a TOML document

@req toml-encoding=v1
@cites {toml/1.1.0, #{bytes=v1, characters=v1}}

A sequence of bytes that is not the UTF-8 encoding of a text is not a
valid document of TOML 1.1.0.

### 3.19 The byte order mark in TOML

@req toml-byte-order-mark=v1
@cites {toml/1.1.0, #{bytes=v1, byte-order-mark=v1}}

When a sequence of bytes starts with the byte order mark, a conforming
implementation reads only the bytes after the byte order mark by the
rules of TOML 1.1.0.

### 3.20 The range of a TOML integer

@req toml-integer-range=v1
@cites {toml/1.1.0, #{toml-values=v1}}

A TOML integer is a whole number from −9223372036854775808 to
9223372036854775807. When an integer of TOML 1.1.0 in a document stands
for a number outside that range, the document is not a valid document
of TOML 1.1.0.

### 3.21 The values of TOML floats

@req toml-float-values=v1
@cites {toml/1.1.0, ieee/754-2019, #{toml-values=v1}}

For a float of TOML 1.1.0 other than `inf`, `+inf`, `-inf`, `nan`,
`+nan`, and `-nan`, the TOML float that it gives is the IEEE 754
binary64 value that rounding to nearest, with ties to even, gives for
the number that the float of TOML 1.1.0 stands for. The sign bit of that
binary64 value is 1 when, and only when, the float of TOML 1.1.0 starts
with `-`. When that binary64 value is an infinity, the document that
holds the float of TOML 1.1.0 is not a valid document of TOML 1.1.0.

### 3.22 Infinities and NaN in TOML

@req toml-special-floats=v1
@cites {toml/1.1.0, ieee/754-2019, #{toml-values=v1}}

The floats `inf` and `+inf` of TOML 1.1.0 give the TOML float positive
infinity, and the float `-inf` of TOML 1.1.0 gives the TOML float
negative infinity. The floats `nan`, `+nan`, and `-nan` of TOML 1.1.0
each give a TOML float that is NaN.

### 3.23 Fractions of a second in TOML

@req toml-second-fractions=v1
@cites {toml/1.1.0, #{toml-values=v1}}

In a document, the digits after the `.` of the second of a local time, a
local date-time, or an offset date-time give its fraction of a second.
When there are more than nine of these digits, only the first nine of
them give the fraction.

### 3.24 Leap seconds in TOML

@req toml-leap-seconds=v1
@cites {toml/1.1.0, #{toml-values=v1}}

Each second from 0 to 60 is a valid second of a local time, a local
date-time, and an offset date-time, on every date and at every hour and
minute.

### 3.25 Offsets in TOML

@req toml-offsets=v1
@cites {toml/1.1.0, rfc/3339, #{toml-values=v1}}

The offset of an offset date-time is the unknown local offset of
RFC 3339, section 4.3, when the document gives the offset as `-00:00`.
Otherwise, the offset is a signed number of minutes: 0 when the document
gives the offset as `Z` or `z`, and the number of minutes that the
document gives for each other offset, such as 0 for `+00:00` and −420
for `-07:00`. The unknown local offset is not a number of minutes.

### 3.26 Newlines in TOML strings

@req toml-string-newlines=v1
@cites {toml/1.1.0, #{toml-values=v1, characters=v1}}

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

### 3.27 Escape sequences in TOML

@req toml-escapes=v1
@cites toml/1.1.0

These rules use the terms basic string, multi-line basic string, and
escape sequence of TOML 1.1.0. When a basic string or a multi-line basic
string in a document holds an escape sequence that TOML 1.1.0 reserves,
such as `\q`, the document is not a valid document of TOML 1.1.0.

### 3.28 Places in a TOML document

@req toml-places=v1
@cites {toml/1.1.0, #{characters=v1, toml-values=v1, toml-keys=v1}}

These definitions use the terms document, root table, table header, and
array of tables of TOML 1.1.0.

- A place in a document is a position before, between, or after the
  characters of the document.
- The tables and TOML values at a place are those that the text of the
  document before that place makes, as TOML 1.1.0 reads that text in its
  order.
- The location of a table of a document is the sequence of steps that
  leads to it from the root table. Each step is the text of a TOML key,
  or the position of a table in a TOML array. Two tables of a document
  are the same table when, and only when, they have the same location.
- At a place in a document, the TOML keys k1 to kn lead from a table v0
  to a TOML value vn when, and only when, for each i from 1 to n, the
  TOML value v(i−1) is a table that holds the text of ki, and vi is the
  TOML value of that text in v(i−1) at that place. When the table
  headers of an array of tables make that TOML value, vi is instead the
  last table that a table header before that place adds to that TOML
  array. When no such TOML values exist, the TOML keys k1 to kn lead
  from v0 to no TOML value.

### 3.29 Table headers in TOML

@req toml-table-headers=v1
@cites {toml/1.1.0, #{toml-values=v1, toml-keys=v1, toml-places=v1}}

These definitions use the terms table header, array of tables, and root
table of TOML 1.1.0.

- A table header `[k1.k2.….kn]` or `[[k1.k2.….kn]]` names the table that
  the TOML keys k1 to kn lead to from the root table at the place right
  after the table header.
- The super-tables of the table that a table header `[k1.k2.….kn]` or
  `[[k1.k2.….kn]]` names are the tables that the TOML keys k1 to ki lead
  to from the root table at the place right after the table header, for
  each i from 1 to n − 1.

### 3.30 Paths in TOML

@req toml-paths=v1
@cites {
    toml/1.1.0,
    #{
        toml-values=v1, toml-table-headers=v1, toml-keys=v1,
        toml-places=v1,
    },
}

These definitions use the terms key/value pair, inline table, table
header, and root table of TOML 1.1.0.

- An inline table holds each key/value pair and each inline table
  between its braces.
- The holding table of a key/value pair is the table of the innermost
  inline table that holds the key/value pair. When no inline table holds
  the key/value pair, the holding table is the table that the last table
  header before the key/value pair names. When no table header comes
  before the key/value pair, the holding table is the root table.
- The path of the dotted key `k1.k2.….kn` of a key/value pair is the
  sequence of the tables that the TOML keys k1 to ki lead to from the
  holding table of the key/value pair at the place right after the
  key/value pair, for each i from 1 to n − 1, in that order.

### 3.31 TOML documents

@req toml-documents=v1
@cites {
    toml/1.1.0,
    #{
        bytes=v1, toml-byte-order-mark=v1, toml-encoding=v1,
        toml-integer-range=v1, toml-float-values=v1,
        toml-special-floats=v1, toml-second-fractions=v1,
        toml-leap-seconds=v1, toml-offsets=v1, toml-string-newlines=v1,
        toml-escapes=v1, toml-table-headers=v1, toml-places=v1,
        toml-keys=v1, toml-paths=v1, toml-values=v1,
    },
}

A TOML document is a sequence of bytes that meets both of these
conditions:

1. TOML 1.1.0 reads the bytes as a valid document, with all its rules,
   with the rules of `toml-byte-order-mark`, `toml-encoding`,
   `toml-integer-range`, `toml-float-values`, `toml-special-floats`,
   `toml-second-fractions`, `toml-leap-seconds`, `toml-offsets`,
   `toml-string-newlines`, and `toml-escapes`, and with these rules,
   which add to the rules of TOML 1.1.0:
   - A table header defines the table that it names, and no other
     table.
   - At a place in the document, an undefined super-table is a table
     that is a super-table of a table that a table header before that
     place names, and that no table header, no key/value pair, and no
     inline table before that place defines.
   - For a key/value pair whose key is the dotted key `k1.k2.….kn`, and
     for each i from 1 to n − 1, the key/value pair defines the table
     that the TOML keys k1 to ki lead to from the holding table of the
     key/value pair at the place right after the key/value pair when,
     and only when, at the place right before the key/value pair, the
     TOML keys k1 to ki lead from that holding table to no TOML value or
     to an undefined super-table. Through its dotted key, a key/value
     pair defines no other table.
   - An inline table defines its table.
   - No two of the table headers, the key/value pairs, and the inline
     tables of the document define the same table.
   - At the place right before a key/value pair, the TOML keys of its
     key lead from the holding table of the key/value pair to no TOML
     value.
   - When no inline table holds a key/value pair, the document is not
     invalid only because a table that the key/value pair defines holds
     a table that a table header names, before or after the key/value
     pair.
2. No table of the path of the dotted key of a key/value pair is a table
   that a table header before that key/value pair names.

### 3.32 Root tables

@req root-tables=v1
@cites {
    toml/1.1.0,
    #{
        toml-documents=v1, toml-byte-order-mark=v1, toml-encoding=v1,
        toml-integer-range=v1, toml-float-values=v1,
        toml-special-floats=v1, toml-second-fractions=v1,
        toml-leap-seconds=v1, toml-offsets=v1, toml-string-newlines=v1,
        toml-escapes=v1, toml-values=v1, characters=v1,
    },
}

The root table of a TOML document is the root table that TOML 1.1.0
gives for the document, with all its rules and with the rules of
`toml-byte-order-mark`, `toml-encoding`, `toml-integer-range`,
`toml-float-values`, `toml-special-floats`, `toml-second-fractions`,
`toml-leap-seconds`, `toml-offsets`, `toml-string-newlines`, and
`toml-escapes`. These rules give the tables and the TOML values in the
root table:

- A table header, a dotted key, and an inline table each give a table.
  Both the table headers of an array of tables and the brackets `[` and
  `]` around TOML values give a TOML array.
- The text of a TOML string is the text that TOML 1.1.0 gives for its
  basic string, multi-line basic string, literal string, or multi-line
  literal string after the escape sequences resolve, with no other
  change.
- The local date-time of an offset date-time is the local date-time
  that the document gives before the offset.
- When the document gives no second for a local time, a local
  date-time, or an offset date-time, its second is 0. When the document
  gives no fraction of a second for it, its fraction of a second is 0.

### 3.33 Reading TOML documents

@req read-toml=v1
@cites #{
    bytes=v1, results=v1, toml-values=v1, toml-value-equality=v1,
    root-tables=v1, toml-documents=v1,
}

For each sequence of bytes, a conforming implementation must give the
result valid and a table that is equal to the root table of the TOML
document when the bytes are a TOML document. For every other sequence
of bytes, it must give the result invalid.

### 3.34 Hashes

@req hashes=v1
@cites {fips/180-4, #{bytes=v1, hex-text=v1}}

A sequence of fewer than 2^61 bytes makes a message of FIPS 180-4: 8
bits for each byte, in the order of the bytes, the most significant bit
of each byte first. The digest of the sequence of bytes is the message
digest of 256 bits that SHA-256, as FIPS 180-4 defines it, gives for
that message, as 32 bytes: 8 bits for each byte, in their order, the
most significant bit of each byte first. The hash of the sequence of
bytes is the hex text of its digest.

### 3.35 Computing hashes

@req compute-hash=v1
@cites #{bytes=v1, hashes=v1}

For each sequence of fewer than 2^61 bytes, a conforming implementation
must give its hash.

### 3.36 The grammar of a hash

@req hash-grammar=v1
@cites #{notation=v1, hex-digits=v1}

This production gives the form of a hash:

```abnf
hash  = 64hex-digit
```

### 3.37 Checking the form of a hash

@req check-hash=v1
@cites #{characters=v1, results=v1, notation=v1, hash-grammar=v1}

For each text, a conforming implementation must give the result valid
when the text matches `hash`, and the result invalid when it does not.

### 3.38 Id prefixes

@req id-prefixes=v1
@cites #{notation=v1, characters=v1}

This production gives the form of an id prefix:

```abnf
id-prefix  = 1*%x61-7A "-"
```

An id prefix is a text that matches `id-prefix`.

### 3.39 Hash ids

@req hash-ids=v1
@cites #{id-prefixes=v1, bytes=v1, characters=v1, hashes=v1}

For an id prefix p, a whole number n from 1 to 64, and a sequence b of
fewer than 2^61 bytes, the hash id of b with p and n is the text p,
then the first n characters of the hash of b.

### 3.40 Computing hash ids

@req compute-hash-id=v1
@cites #{id-prefixes=v1, bytes=v1, hash-ids=v1}

For each id prefix p, each whole number n from 1 to 64, and each
sequence b of fewer than 2^61 bytes, a conforming implementation must
give the hash id of b with p and n.

### 3.41 The form of a hash id

@req hash-id-forms=v1
@cites #{id-prefixes=v1, characters=v1, notation=v1, hex-digits=v1}

For an id prefix p and a whole number n from 1 to 64, a text has the
form of a hash id with p and n when, and only when, it is the text p,
then exactly n characters that each match `hex-digit`.

### 3.42 Checking the form of a hash id

@req check-hash-id=v1
@cites #{characters=v1, id-prefixes=v1, results=v1, hash-id-forms=v1}

For each text t, each id prefix p, and each whole number n from 1 to
64, a conforming implementation must give the result valid when t has
the form of a hash id with p and n, and the result invalid when it does
not.

## 4. Conformance

An implementation conforms to this design when it meets every
requirement of section 3.

Each vector below gives an input and what a conforming implementation
gives for it. These conventions apply:

- A vector gives a JSON value as a JSON text, as RFC 8259 defines it,
  that holds no key twice in one object and no number that is not an
  integer. The JSON value is the one that the JSON text gives.
- A vector gives a sequence of bytes as texts, which stand for their
  UTF-8 encodings, and as bytes in hex numbers, such as 0x0A.
- A vector gives each character that does not show, such as U+E000, by
  its code point.
- The text after "valid:" describes the value, and the text after
  "invalid:" explains the result. An implementation does not give these
  texts.

### 4.1 Canonical forms

Each row gives a JSON value, and its canonical bytes as a text.

| JSON value | canonical bytes |
|---|---|
| `{ "b": 1, "a": [true, false] }` | `{"a":[true,false],"b":1}` |
| `{ "ab": 1, "a": 2 }` | `{"a":2,"ab":1}` |
| `{}` | `{}` |
| `[]` | `[]` |
| `{ "": 0 }` | `{"":0}` |
| `{ "z": [{ "b": true, "a": false }], "a": [] }` | `{"a":[],"z":[{"a":false,"b":true}]}` |
| `[1, [2, [3]], {"k": {"j": "x"}}]` | `[1,[2,[3]],{"k":{"j":"x"}}]` |
| `9007199254740991` | `9007199254740991` |
| `-9007199254740991` | `-9007199254740991` |
| `0` | `0` |
| `"a/b"` | `"a/b"` |
| `"\"\\"` | `"\"\\"` |
| `"\b\t\n\f\r"` | `"\b\t\n\f\r"` |
| `"\u0000\u000b\u001F"` | `"\u0000\u000b\u001f"` |
| `"\u0041"` | `"A"` |
| `"\u007f"` | `"`, U+007F, and `"` |
| `"\u2028"` | `"`, U+2028, and `"` |
| `"\ud83d\ude00"` | `"`, U+1F600, and `"` |
| `{ "\ue000": 1, "\ud83d\ude00": 2 }` | `{"`, U+1F600, `":2,"`, U+E000, `":1}` |
| `{ "\u00e9": 1, "e\u0301": 2 }` | `{"e`, U+0301, `":2,"`, U+00E9, `":1}` |
| `{ "B": 1, "a": 2 }` | `{"B":1,"a":2}` |

### 4.2 Canonical lines

Each row gives a sequence of bytes and the result. A row that mentions
the byte 0x0A, or that says "and no byte 0x0A", gives all the bytes.
Every other row gives the bytes before one last byte 0x0A, which the
row leaves out.

| bytes | result |
|---|---|
| `{"a":2,"b":1}` | valid: the line object `{"a":2,"b":1}` |
| `{}` | valid: the empty line object |
| `{"a":[1,"x",true]}` | valid: the line object `{"a":[1,"x",true]}` |
| `{"a":[{"b":1},{"c":"x"}]}` | valid: the line object `{"a":[{"b":1},{"c":"x"}]}` |
| `{"a":[{"a":1}]}` | valid: the line object `{"a":[{"a":1}]}` |
| `{"a":[{}]}` | valid: the line object in which `a` holds an array of one empty flat object |
| `{"a":[]}` | valid: the line object `{"a":[]}` |
| `{"a":-9007199254740991}` | valid: the line object `{"a":-9007199254740991}` |
| `{"a":"\u000b"}` | valid: the line object in which `a` holds the string U+000B |
| `{"a":"`, U+1F600, `"}` | valid: the line object in which `a` holds the string U+1F600 |
| `{"`, U+1F600, `":2,"`, U+E000, `":1}` | valid: the line object with the key U+1F600 and the integer 2, and the key U+E000 and the integer 1 |
| `{"`, U+E000, `":1,"`, U+1F600, `":2}` | invalid: the keys are not in key order |
| `{"b":1,"a":2}` | invalid: the keys are not in key order |
| `{"a":[{"b":1,"a":2}]}` | invalid: the keys of a flat object are not in key order |
| `{"a":1,"a":1}` | invalid: an object holds no key twice |
| `{"a":[{"b":1,"b":2}]}` | invalid: an object holds no key twice |
| `{"a":2,"b":1}`, and no byte 0x0A | invalid: the bytes do not end with 0x0A |
| `{"a":2,"b":1}`, 0x0D, and 0x0A | invalid: the byte 0x0D stands before the byte 0x0A |
| `{"a":2}`, 0x0A, `{"b":1}`, and 0x0A | invalid: the bytes hold two canonical lines |
| 0xEF, 0xBB, 0xBF, and `{}` | invalid: the bytes 0xEF, 0xBB, and 0xBF stand before `{` |
| `{"a": 2}` | invalid: a space stands outside a string |
| `{"a":1.0}` | invalid: `1.0` is not the canonical form of an integer |
| `{"a":1e2}` | invalid: `1e2` is not the canonical form of an integer |
| `{"a":-0}` | invalid: `-0` is not the canonical form of an integer |
| `{"a":01}` | invalid: the canonical form of an integer has no leading `0` |
| `{"a":9007199254740992}` | invalid: the number is greater than 9007199254740991 |
| `{"a":null}` | invalid: null is not a string, an integer, a boolean, an array, or an object |
| `{"a":True}` | invalid: `True` is not the canonical form of a boolean |
| `{"a":"\u0041"}` | invalid: the string form of `A` is `A` |
| `{"a":"\/"}` | invalid: the string form of `/` is `/` |
| `{"a":"\u000A"}` | invalid: the string form of the line feed is `\n` |
| `{"a":"\u000B"}` | invalid: the string form of U+000B is `\u000b`, with lower-case hex digits |
| `{"a":"\u007f"}` | invalid: the string form of U+007F is the character U+007F |
| `{"a":"\ud83d\ude00"}` | invalid: the string form of U+1F600 is the character U+1F600 |
| `{"a":"`, 0x09, `"}` | invalid: the string form of the tab is `\t` |
| `{"a":"`, 0xFF, `"}` | invalid: the bytes are not the UTF-8 encoding of a text |
| `[1]` | invalid: the JSON value is not an object |
| `"a"` | invalid: the JSON value is not an object |
| `{"a":{"b":1}}` | invalid: the value of `a` is an object |
| `{"a":[[1]]}` | invalid: the value of `a` is an array that holds an array |
| `{"a":[1,{"b":1}]}` | invalid: the value of `a` mixes a scalar and an object |
| `{"a":[{"b":[1]}]}` | invalid: `{"b":[1]}` is not a flat object |

### 4.3 TOML documents

Each item gives a sequence of bytes and the result. A text stands for
its UTF-8 encoding, and the items give a byte by a hex number, such as
0x0D. A code block, and an item that mentions "the lines", give lines,
and the byte 0x0A ends each line. An item that mentions the byte 0x0A
gives all the bytes. Every other item gives a sequence of bytes, and one
byte 0x0A follows them. For a valid TOML document, the item gives the
root table.

- `a = 1`: valid: `a` holds the TOML integer 1.
- Each of these three texts: valid, with equal root tables: `a` holds
  a table in which `b` holds the TOML integer 1.

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

- Each of these two texts: valid, with equal root tables: `a` holds a
  TOML array of one table, in which `b` holds the TOML integer 1.

  ```toml
  a = [{ b = 1 }]
  ```

  ```toml
  [[a]]
  b = 1
  ```

- The lines `a = 1` and `A = 2`: valid: `a` holds the TOML integer 1,
  and `A` holds the TOML integer 2.
- The lines `a = 1` and `"a" = 2`: invalid: the TOML keys `a` and `"a"`
  are the same key of TOML 1.1.0.
- The lines `"\u00e9" = 1` and `"e\u0301" = 2`: valid: the TOML key
  U+00E9 holds the TOML integer 1, and the TOML key of U+0065 and U+0301
  holds the TOML integer 2.
- `a = "e\u0301"`: valid: `a` holds the TOML string of U+0065 and
  U+0301.
- The bytes 0xEF, 0xBB, and 0xBF, then `a = 1`: valid: `a` holds the
  TOML integer 1.
- `a = 1`, then the bytes 0xEF, 0xBB, and 0xBF: invalid: the character
  U+FEFF stands after `a = 1`, where TOML 1.1.0 allows only spaces,
  tabs, a comment, or a newline.
- `a = "`, the bytes 0xEF, 0xBB, and 0xBF, then `"`: valid: `a` holds
  the TOML string of U+FEFF.
- `a = 1 # `, then the bytes 0xEF, 0xBB, and 0xBF: valid: `a` holds the
  TOML integer 1.
- `a = { b = 1, }`: valid: `a` holds a table in which `b` holds the TOML
  integer 1.
- Each of these three texts: valid, with equal root tables: `t` holds
  the local time with the hour 12, the minute 30, the second 0, and the
  fraction of a second 0.

  ```toml
  t = 12:30
  ```

  ```toml
  t = 12:30:00
  ```

  ```toml
  t = 12:30:00.000
  ```

- `s = "\x41\e"`: valid: `s` holds the TOML string of `A` and U+001B.
- `a = "`, the byte 0xFF, and `"`: invalid: the bytes are not the UTF-8
  encoding of a text.
- `a = 9223372036854775807`: valid: `a` holds the TOML integer
  9223372036854775807.
- `a = 9223372036854775808`: invalid: the integer of TOML 1.1.0 stands
  for a number greater than 9223372036854775807.
- `a = -0.0`: valid: `a` holds the TOML float negative zero.
- `a = 1e400`: invalid: the float of TOML 1.1.0 rounds to an infinity.
- `a = -nan`: valid: `a` holds the TOML float NaN.
- `t = 00:00:00.123456789123`: valid: `t` holds the local time
  00:00:00.123456789.
- `t = 12:00:60`: valid: `t` holds the local time 12:00:60.
- `t = 23:59:60`: valid: `t` holds the local time 23:59:60.
- `a = 1979-05-27T07:32:00-00:00`: valid: `a` holds the offset date-time
  1979-05-27T07:32:00 with the unknown local offset, which is not the
  offset 0.
- Each of these two texts: valid, with equal root tables: `a` holds the
  offset date-time 1979-05-27T07:32:00 with the offset 0.

  ```toml
  a = 1979-05-27T07:32:00Z
  ```

  ```toml
  a = 1979-05-27T07:32:00+00:00
  ```

- `s = """a`, the bytes 0x0D and 0x0A, then `b"""` and the byte 0x0A:
  valid: `s` holds the TOML string of `a`, U+000D, U+000A, and `b`.
- `s = '''a`, the bytes 0x0D and 0x0A, then `b'''` and the byte 0x0A:
  valid: `s` holds the TOML string of `a`, U+000D, U+000A, and `b`.
- `s = """a\`, the byte 0x0A, then `  b"""` and the byte 0x0A: valid:
  `s` holds the TOML string `ab`.
- `s = "\q"`: invalid: TOML 1.1.0 reserves the escape sequence `\q`.
- This text: invalid: the table `a.b.c`, which the table header on
  line 1 names, is in the path of the dotted key `b.c.x`.

  ```toml
  [a.b.c]
  z = 9
  [a]
  b.c.x = 1
  ```

- This text: invalid: the table `a.b.c.d`, which the table header on
  line 1 names, is in the path of the dotted key `b.c.d.k.t`.

  ```toml
  [a.b.c.d]
  z = 9
  [a]
  b.c.d.k.t = 1
  ```

- This text: invalid: the table `a.b.c`, which the table header on
  line 1 names, is in the path of the dotted key `b.c.t`.

  ```toml
  [a.b.c]
  z = 9
  [[x]]
  [a]
  b.c.t = 1
  ```

- This text: invalid: the last table of the array of tables `a.b`, which
  the table header on line 1 names, is in the path of the dotted key
  `b.y`.

  ```toml
  [[a.b]]
  [a]
  b.y = 2
  ```

- This text: invalid: the last table of the array of tables `a.b`, which
  the table header on line 1 names, is in the path of the dotted key
  `b.c.y`.

  ```toml
  [[a.b]]
  [a]
  b.c.y = 2
  ```

- This text: invalid: the table `a.b`, which the table header on line 2
  names, is in the path of the dotted key `b.x`.

  ```toml
  [a.b.c]
  [a.b]
  [a]
  b.x = 1
  ```

- This text: valid: `a` holds a table in which `b` holds a table. In
  that table, `c` holds a table in which `z` holds the TOML integer 9,
  `ct` holds the TOML integer 1, and `x` holds a table in which `y`
  holds the TOML integer 1.

  ```toml
  [a.b.c]
  z = 9
  [a]
  b.ct = 1
  b.x.y = 1
  ```

- This text: valid: `a` holds a table in which `b` holds a table. In
  that table, `c` holds the TOML integer 1, and `d` holds a table in
  which `e` holds the TOML integer 2.

  ```toml
  [a]
  b.c = 1
  [a.b.d]
  e = 2
  ```

- This text: valid: `a` holds a table in which `b` holds a table. In
  that table, `x` holds the TOML integer 1, and `c` holds an empty
  table.

  ```toml
  a.b.x = 1
  [a.b.c]
  ```

- This text: valid: `a` holds a table in which `b` holds a table. In
  that table, `c` and `e` each hold an empty table, and `x` holds the
  TOML integer 1.

  ```toml
  [a.b.c]
  [a]
  b.x = 1
  [a.b.e]
  ```

- This text: valid: `a` holds a table in which `b` holds a table. In
  that table, `c` holds a table in which `d` holds an empty table, and
  `x` holds the TOML integer 1.

  ```toml
  [a.b.c]
  [a]
  b.x = 1
  [a.b.c.d]
  ```

- This text: valid: `a` holds a table in which `b` holds a table. In
  that table, `c` holds a table in which `d` holds an empty table and
  `e` holds the TOML integer 1, and `f` holds an empty table.

  ```toml
  [a.b.c.d]
  [a]
  b.c.e = 1
  [a.b.f]
  ```

- This text: valid: `a` holds a table in which `x` holds a table, in
  which `b` holds a table, in which `c` holds the TOML integer 1.

  ```toml
  [a]
  x = { b.c = 1 }
  ```

- This text: invalid: the table header on line 3 defines the table
  `a.b`, which the key/value pair on line 2 defines.

  ```toml
  [a]
  b.c = 1
  [a.b]
  ```

- This text: invalid: the table headers on lines 2 and 3 both define the
  table `a`.

  ```toml
  [a.b]
  [a]
  [a]
  ```

- This text: invalid: the table header on line 5 defines the table
  `a.b`, which the key/value pair on line 4 defines.

  ```toml
  [a.b.c]
  z = 9
  [a]
  b.ct = 1
  [a.b]
  ```

- This text: invalid: the table header on line 4 defines the table
  `a.b`, which the key/value pair on line 3 defines.

  ```toml
  [a.b.c.d]
  [a]
  b.c.e = 1
  [a.b]
  ```

- This text: invalid: the table header on line 4 defines the table
  `a.b.c`, which the key/value pair on line 3 defines.

  ```toml
  [a.b.c.d]
  [a]
  b.c.e = 1
  [a.b.c]
  ```

- This text: invalid: the table header on line 3 defines the table `a`,
  which the key/value pair on line 1 defines.

  ```toml
  a.b.x = 1
  [a.b.c]
  [a]
  ```

- This text: invalid: the table header on line 2 defines the table `a`,
  which the inline table on line 1 defines.

  ```toml
  a = {}
  [a]
  ```

- This text: invalid: the table header on line 2 defines the table
  `a.b`, which the inline table on line 1 defines.

  ```toml
  a.b = {}
  [a.b]
  ```

- This text: invalid: the table header on line 2 adds the table `x.b.d`
  to the table `x.b`, which is in the inline table on line 1.

  ```toml
  x = { b.c = 1 }
  [x.b.d]
  ```

- This text: invalid: before line 3, the table `x` already holds the
  TOML key `a`, because the table header on line 1 makes the super-table
  `x.a`.

  ```toml
  [x.a.b]
  [x]
  a = { c = 1 }
  ```

- This text: invalid: before line 3, the table `a` already holds the
  TOML key `b`, because the table header on line 1 makes the super-table
  `a.b`.

  ```toml
  [a.b.c]
  [a]
  b = { d = 1 }
  ```

- This text: valid: `a` holds a table in which `b` holds an empty table,
  and `x` holds the TOML integer 1.

  ```toml
  [a.b]
  [a]
  x = 1
  ```

- This text: valid: `a` holds a TOML array of two tables. In the first
  table, `b` holds a table in which `z` holds the TOML integer 1. In the
  second table, `b` holds a table in which `x` holds the TOML integer 1.

  ```toml
  [[a]]
  [a.b]
  z = 1
  [[a]]
  b.x = 1
  ```

- This text: valid: `a` holds a table in which `b` holds a TOML array of
  two tables. In the first table, `c` holds a table in which `z` holds
  the TOML integer 1. In the second table, `c` holds a table in which
  `x` holds the TOML integer 1.

  ```toml
  [[a.b]]
  [a.b.c]
  z = 1
  [[a.b]]
  c.x = 1
  ```

- This text: valid: `p` holds a table in which `q` holds an empty table,
  and `q` holds a table in which `r` holds an empty table.

  ```toml
  [p.q]
  [p]
  [q.r]
  ```

### 4.4 Hashes and hash ids

Each row gives a sequence of bytes as a text, and its hash.

| bytes | hash |
|---|---|
| the empty sequence | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `abc` | `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` |
| `abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq` | `248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1` |

Each row gives a text and its result as a hash.

| text | result |
|---|---|
| `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` | valid |
| `BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD` | invalid: upper-case letters are not hex digits |
| `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015a` | invalid: 63 hex digits |
| `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad0` | invalid: 65 hex digits |
| `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ag` | invalid: `g` is not a hex digit |

Each row gives an id prefix, a number of hex digits, a sequence of
bytes, and the hash id.

| id prefix | number of hex digits | bytes | hash id |
|---|---|---|---|
| `e-` | 12 | `abc` | `e-ba7816bf8f01` |
| `t-` | 12 | the empty sequence | `t-e3b0c44298fc` |
| `run-` | 1 | `abc` | `run-b` |
| `e-` | 64 | `abc` | `e-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` |

Each row gives a text, an id prefix, a number of hex digits, and the
result as a hash id.

| text | id prefix | number of hex digits | result |
|---|---|---|---|
| `e-5b1c0a9d2e11` | `e-` | 12 | valid |
| `e-5b1c0a9d2e1` | `e-` | 12 | invalid: 11 hex digits |
| `e-5b1c0a9d2e11a` | `e-` | 12 | invalid: 13 hex digits |
| `e-5B1C0A9D2E11` | `e-` | 12 | invalid: upper-case letters are not hex digits |
| `t-5b1c0a9d2e11` | `e-` | 12 | invalid: the text does not start with `e-` |
| `5b1c0a9d2e11` | `e-` | 12 | invalid: the text does not start with `e-` |
