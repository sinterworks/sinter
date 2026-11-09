<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Data forms
@design data-forms=v1
@cites rfc/3629
@cites rfc/5234
@cites rfc/7405
@cites toml/1.1.0
@cites fips/180-4
An implementation writes JSON values in one canonical form, reads canonical lines and TOML documents, and computes SHA-256 hashes and hash ids.

A JSON value is a string, an integer, a boolean, an array, or an object.
Each JSON value has one canonical form: a JSON text with its keys in a
fixed order and with no space between its tokens. A canonical line
holds the canonical form of one object and ends with a line feed. So a
file of canonical lines holds one object on each line, and two programs
that write the same objects write the same bytes.

A TOML document is a document in the format of TOML 1.1.0, with one
more rule for dotted keys. SHA-256 is a hash function: it gives a
digest of 32 bytes for any sequence of bytes. A hash is a digest
written as 64 lower-case hex digits. A hash id is a short prefix, such
as `e-`, and the first hex digits of a hash.

The productions in section 3 are written in ABNF, the notation of
RFC 5234. A production, such as `hash = 64hex-digit`, gives the texts
that its name matches. `64hex-digit` repeats the element `hex-digit`
exactly 64 times, and `1*` repeats the element after it one or more
times. In a production, `/` separates two alternatives. `%x61` is the
character U+0061, and `%x61-7A` is any one character from U+0061 to
U+007A. `DIGIT` is the core rule of RFC 5234 for the characters `0` to
`9`.

From the standards that it cites, the design takes these parts:

| standard | what the design takes from it |
|---|---|
| RFC 3629 | the UTF-8 encoding of a text |
| RFC 5234, RFC 7405 | the notation of the productions |
| TOML 1.1.0 | TOML documents, their tables and keys, and their values |
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
| line feed | the character U+000A, whose UTF-8 encoding is the byte 0x0A |
| byte order mark | the character U+FEFF, whose UTF-8 encoding is the bytes 0xEF, 0xBB, and 0xBF |
| result | what a conforming implementation gives for an input that it reads: valid or invalid |
| JSON value | a string, an integer, a boolean, an array, or an object |
| string | a text, as a value |
| integer | a whole number from −(2^53 − 1) to 2^53 − 1, as a JSON value |
| boolean | true or false, as a value |
| array | a sequence of values, its elements |
| object | a set of members in which no two members have the same key |
| member | a key and a JSON value, which is the value of the member |
| key | the text that names a member of an object, or a value in a table of a TOML document |
| scalar | a string, an integer, or a boolean |
| flat object | an object in which the value of each member is a scalar |
| line object | an object in which the value of each member is a scalar, an array of scalars, or an array of flat objects |
| UTF-16 code unit | a number from 0 to 65535; a character has one or two of them, as UTF-16 encodes it |
| key order | the order of texts by their UTF-16 code units, in which the keys of an object stand in its canonical form |
| canonical form | the one text that the rules of section 2.3 give for a JSON value |
| canonical bytes | the UTF-8 encoding of the canonical form of a JSON value |
| canonical line | the canonical bytes of a line object, then the byte 0x0A |
| TOML document | a sequence of bytes that is a valid document of TOML 1.1.0 and that meets the rule for dotted keys of section 2.6 |
| table, inline table, table header, dotted key, array of tables | the things of TOML 1.1.0 that have these names |
| TOML value | a value of a TOML document, of one of the types of TOML 1.1.0, such as a TOML integer or a table |
| root table | the top-level table of a TOML document |
| super-table | a table that holds another table, directly or through other tables, such as `a` and `a.b` for `a.b.c` |
| holding table | the table that holds a dotted key: an inline table, the table that a table header names, or the root table |
| path of a dotted key | the tables that the keys of a dotted key, apart from its last key, lead to, one after another |
| hex digit | one of the characters `0` to `9` and `a` to `f` |
| hex text | a sequence of bytes written as hex digits, two for each byte |
| digest | the 32 bytes that SHA-256 gives for a sequence of bytes |
| hash | the hex text of a digest: 64 hex digits |
| id prefix | one or more lower-case ASCII letters and then `-`, such as `e-` |
| hash id | an id prefix, then the first hex digits of a hash, such as `e-ba7816bf8f01` |

## 2. The data forms

### 2.1 Characters, texts, and bytes

A character is one Unicode scalar value: a code point from U+0000 to
U+D7FF, or from U+E000 to U+10FFFF. A text is a sequence of characters.
Two texts are the same text only when they hold the same characters in
the same order.

A conforming implementation keeps each text as it is. It normalizes no
Unicode, and it changes the case of no letter. So the text U+00E9 and
the text of U+0065 and U+0301 are two different texts, although both
show as the letter e with an acute accent. The texts `a` and `A` are
two different texts too.

A byte is a whole number from 0 to 255. The UTF-8 encoding of a text
is the sequence of bytes that RFC 3629 gives for its characters. The
UTF-8 encoding of a text holds no byte order mark that the text does
not hold.

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
| string | `"`, then the escape of each character of the string, in order, then `"` |
| integer | the decimal digits of its absolute value, with no leading zero, after `-` when the integer is less than 0; `0` for 0 |
| boolean | `true` or `false` |
| array | `[`, then the canonical forms of the elements in their order, with `,` between two of them, then `]` |
| object | `{`, then the members in key order, with `,` between two of them, then `}`; each member is the canonical form of its key as a string, `:`, and the canonical form of its value |

The escape of a character of a string is one of these:

| character | escape |
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
themselves, and the escapes `\/` and `\u0041` never stand in a
canonical form.

A canonical form holds no tab and no line feed, and it holds a space
only inside a string. The members of an object stand in key order. Key order compares
two keys by their UTF-16 code units, as the encoding UTF-16 gives them:

- A character whose code point is less than 0x10000 has one code unit:
  its code point.
- A character whose code point c is 0x10000 or more has two code units:
  first 0xD800 plus the quotient of c − 0x10000 divided by 0x400, then
  0xDC00 plus the remainder.

One key comes before another when, at the first position where their
code units differ, its code unit is less. A key also comes before every
longer key whose code units start with all of its code units, so `a`
comes before `ab`.

Key order is not the order of code points, and not the order of the
bytes of UTF-8. The two orders differ for a character from U+E000 to
U+FFFF and a character from U+10000. For example, the key U+1F600 (the
code units 0xD83D and 0xDE00) comes before the key U+E000 (the code unit
0xE000) in key order, but after it in the order of code points.

The canonical bytes of a JSON value are the UTF-8 encoding of its
canonical form. Two different JSON values never have the same canonical
form. Each canonical form is a JSON text, as RFC 8259 defines JSON
texts. It is also the text that the JSON Canonicalization Scheme of
RFC 8785 gives for the JSON value.

Examples, with each JSON value written as a JSON text:

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
string has the escape `\n`, and the UTF-8 encoding of no other
character holds the byte 0x0A. So the byte 0x0A ends each canonical
line, and a sequence of canonical lines divides into its lines at each
byte 0x0A.

A conforming implementation reads a sequence of bytes as a canonical
line. It gives the result valid and the line object when the bytes are
the canonical line of a line object. It gives the result invalid for
every other sequence of bytes. These sequences of bytes are not
canonical lines. When a row names the byte 0x0A, the row gives all the
bytes. Otherwise, the bytes end with one byte 0x0A after the bytes that
the row gives.

| bytes | why they are not a canonical line |
|---|---|
| `{"b":1,"a":2}` | the keys are not in key order |
| `{"a": 2}` | a space stands outside a string |
| `{"a":2}`, and no byte 0x0A | the bytes do not end with the byte 0x0A |
| `{"a":2}`, 0x0D, and 0x0A | the byte 0x0D stands before the byte 0x0A |
| `{"a":1.0}` | `1.0` is not the canonical form of an integer |
| `{"a":null}` | null is not a JSON value |
| `{"a":"\u0041"}` | the canonical form of `A` is `A` |
| `[1]` | the JSON value is not an object |

### 2.5 TOML documents

A TOML document is a sequence of bytes that is a valid document of
TOML 1.1.0, read with three rules:

- One byte order mark at the start of the bytes is not part of the
  document.
- Two keys are the same key only when they are the same text after
  their escapes resolve. So the keys `"\u00e9"` and `"e\u0301"` are two
  different keys.
- A table that table headers make only as a super-table of the tables
  that they name is not defined by those table headers (section 2.6).

A TOML document also meets the rule for dotted keys of section 2.6.

The root table of a TOML document is its top-level table, with its keys
and their TOML values, as TOML 1.1.0 gives them. Each key and each
string of the root table is the text that TOML 1.1.0 gives after its
escapes resolve, with no other change. The root table depends only on
the keys and the TOML values, and not on the form that writes them. So
these three documents give the same root table, in which the key `a`
holds a table that holds the key `b` with the TOML integer 1:

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

A conforming implementation reads a sequence of bytes as a TOML
document. It gives the result valid and the root table when the bytes
are a TOML document, and the result invalid otherwise.

### 2.6 Dotted keys under a later table header

A table header names one table. The header `[a.b.c]` names the table at
the keys `a`, `b`, `c` from the root table. It also makes the tables `a`
and `a.b` when they do not exist yet. The tables `a` and `a.b` are the
super-tables of the table `a.b.c`. A header of an array of tables, such
as `[[a.b]]`, names the table that it adds to the array of tables at the
keys `a`, `b`.

A dotted key, such as `b.c.x = 1`, names a path of tables and then one
key. The path starts at the holding table of the dotted key: the inline
table that holds it, or else the table that the last table header
before it names, or else the root table. Each key of the dotted key
before its last key leads to the next table of the path: the table that
is the value of that key, or the last table of an array of tables that
is the value of that key. Under the header `[a]`, the dotted key
`b.c.x = 1` has the path `a.b`, `a.b.c`, and then the key `x`.

The rule for dotted keys: the path of a dotted key holds no table that a
table header before the dotted key names. This text is not a TOML
document, because the header on line 1 names the table `a.b.c`, and the
path of the dotted key on line 4 holds `a.b.c`:

```toml
[a.b.c]
z = 9
[a]
b.c.x = 1
```

To write the key, put it under the header that names the table:

```toml
[a.b.c]
z = 9
x = 1
```

The path of a dotted key can hold a table that headers only made as a
super-table of the tables that they name. This text is a TOML document.
The header on line 1 made the table `a.b` only as a super-table of
`a.b.c`. So the dotted key on line 4 adds the key `ct` to the table
`a.b`, and the dotted key on line 5 makes the new table `a.b.x`:

```toml
[a.b.c]
z = 9
[a]
b.ct = 1
b.x.y = 1
```

The rule applies to a header of an array of tables too. This text is
not a TOML document. The path of the dotted key on line 3 holds the last
table of the array `a.b`, and the header on line 1 names that table:

```toml
[[a.b]]
[a]
b.y = 2
```

### 2.7 Hashes

A hex digit is one of the sixteen characters `0` to `9` and `a` to `f`,
for the numbers 0 to 15. The hex text of a byte is two hex digits: the
digit of the quotient of the byte divided by 16, then the digit of the
remainder. So the hex text of the byte 0x3F is `3f`. The hex text of a
sequence of bytes is the hex texts of its bytes, in their order.

The digest of a sequence of bytes is the 32 bytes of the message digest
that SHA-256 gives for it, as FIPS 180-4 defines SHA-256. The hash of a
sequence of bytes is the hex text of its digest: 64 hex digits. For
example, the hash of the three bytes of `abc` is
`ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`.

A text has the form of a hash when it holds exactly 64 hex digits and
nothing else. Upper-case letters are not hex digits, so
`BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD` does
not have the form of a hash.

### 2.8 Hash ids

An id prefix is one or more lower-case ASCII letters and then `-`, such
as `e-` or `t-`. For an id prefix, a length from 1 to 64, and a
sequence of bytes, the hash id is the id prefix, then the first hex
digits of the hash of the bytes, as many as the length. For example,
with the id prefix `e-` and the length 12, the hash id of the three
bytes of `abc` is `e-ba7816bf8f01`.

A text has the form of a hash id with an id prefix and a length when it
is the id prefix and then exactly that number of hex digits. So with
the id prefix `e-` and the length 12, `e-5b1c0a9d2e11` has the form of a
hash id, and `e-5b1c0a9d2e1`, `e-5B1C0A9D2E11`, and `t-5b1c0a9d2e11` do
not.

### 2.9 What an implementation gives

| input | what a conforming implementation gives |
|---|---|
| a JSON value | its canonical bytes |
| a sequence of bytes, as a canonical line | valid and the line object, or invalid |
| a sequence of bytes, as a TOML document | valid and the root table, or invalid |
| a sequence of bytes | its hash |
| a text, as a hash | valid or invalid |
| an id prefix, a length, and a sequence of bytes | the hash id |
| a text, an id prefix, and a length, as a hash id | valid or invalid |

## 3. Requirements

### 3.1 Characters, texts, and bytes

@req characters=v1
@cites rfc/3629

A character is a Unicode scalar value: a code point from U+0000 to
U+D7FF, or from U+E000 to U+10FFFF. A text is a finite sequence of
characters. Two texts are the same text when they have the same number
of characters and the same character at each position. A byte is a
whole number from 0 to 255. The UTF-8 encoding of a text is the
sequence of bytes that RFC 3629 gives for the characters of the text,
in their order. The byte order mark is the character U+FEFF.

### 3.2 Notation

@req notation=v1
@cites rfc/5234
@cites rfc/7405
@cites #characters=v1

The productions of this design are rules of ABNF, the notation of
RFC 5234, with the case-sensitive strings of RFC 7405. They use the core
rules of RFC 5234, Appendix B.1. Each terminal value of a production is
the code point of one character. A text matches a production when the
production matches the whole of the text.

### 3.3 Hex digits

@req hex=v1
@cites #characters=v1
@cites #notation=v1

This production gives a hex digit:

```abnf
hex-digit  = DIGIT / %x61-66
```

The hex digit of a number from 0 to 15 is the character `0`, `1`, `2`,
`3`, `4`, `5`, `6`, `7`, `8`, `9`, `a`, `b`, `c`, `d`, `e`, or `f`, in
that order: `0` for 0, and `f` for 15. The hex text of a byte is two
hex digits: the hex digit of the quotient of the byte divided by 16,
then the hex digit of the remainder. The hex text of a sequence of
bytes is the hex texts of its bytes, in their order, one after another.

### 3.4 JSON values

@req json-values=v1
@cites #characters=v1

A JSON value is a string, an integer, a boolean, an array, or an object.
A string is a text. An integer is a whole number from
−9007199254740991 to 9007199254740991. A boolean is true or false. An
array is a finite sequence of JSON values, which are its elements. An
object is a finite set of members. A member is a pair of a key, which is
a text, and a JSON value, which is the value of the member. No two
members of one object have the same key.

### 3.5 Key order

@req key-order=v1
@cites #characters=v1

The UTF-16 code units of a character whose code point c is less than
0x10000 are the one number c. The UTF-16 code units of a character
whose code point c is 0x10000 or more are two numbers: first 0xD800
plus the quotient of c − 0x10000 divided by 0x400, then 0xDC00 plus the
remainder of that division. The UTF-16 code units of a text are the
code units of its characters, in their order. In key order, a text t
comes before a different text u when one of these holds:

- At the first position where the code units of t and of u differ, the
  code unit of t is less than the code unit of u.
- The code units of t are fewer than the code units of u, and they are
  the same as the first code units of u.

### 3.6 The canonical form

@req canonical-form=v1
@cites #characters=v1
@cites #hex=v1
@cites #json-values=v1
@cites #key-order=v1

The canonical form of a JSON value is a text that these rules give:

- The canonical form of a string is `"`, then the escape of each
  character of the string, in their order, then `"`.
- The escape of `"` is `\"`, and the escape of `\` is `\\`. The escape
  of U+0008 is `\b`, of U+0009 is `\t`, of U+000A is `\n`, of U+000C
  is `\f`, and of U+000D is `\r`. The escape of each other character
  from U+0000 to U+001F is `\u00`, then the hex text of its code point
  as a byte. The escape of every other character is that character.
- The canonical form of an integer that is 0 or more is its decimal
  numeral: the decimal digits of the integer, with no leading `0`
  unless the integer is 0. The canonical form of an integer that is less
  than 0 is `-`, then the decimal numeral of its absolute value.
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

### 3.7 Writing the canonical form

@req canonical-writing=v1
@cites #json-values=v1
@cites #canonical-form=v1

For each JSON value, a conforming implementation must give its
canonical bytes.

### 3.8 Line objects

@req line-objects=v1
@cites #json-values=v1

A scalar is a string, an integer, or a boolean. A flat object is an
object in which the value of each member is a scalar. A line object is
an object in which the value of each member is one of these three:

- a scalar;
- an array in which each element is a scalar;
- an array in which each element is a flat object.

### 3.9 Canonical lines

@req canonical-lines=v1
@cites #canonical-form=v1
@cites #line-objects=v1

The canonical line of a line object is the sequence of bytes that holds
the canonical bytes of the line object and then the byte 0x0A. A
sequence of canonical lines is zero or more canonical lines, one after
another.

### 3.10 Reading canonical lines

@req line-reading=v1
@cites #line-objects=v1
@cites #canonical-lines=v1

For each sequence of bytes, a conforming implementation must give the
result valid and the line object whose canonical line the bytes are,
when the bytes are the canonical line of a line object. For every other
sequence of bytes, it must give the result invalid.

### 3.11 Tables and dotted keys in TOML

@req toml-paths=v1
@cites toml/1.1.0

These definitions use the terms of TOML 1.1.0: key, dotted key, table,
root table, inline table, table header, and array of tables.

- The keys k1 to kn lead from a table t0 to a table tn when, for each i
  from 1 to n, the table ti is the value of the key ki in the table
  t(i−1), or the last table of the array of tables that is that value.
- A table header `[k1.k2.….kn]` names the table that the keys k1 to kn
  lead to from the root table. A table header `[[k1.k2.….kn]]` names the
  table that it adds to the array of tables that is the value of the key
  kn in the table that the keys k1 to k(n−1) lead to from the root
  table.
- The super-tables of the table that the keys k1 to kn lead to from the
  root table are the tables that the keys k1 to ki lead to from the root
  table, for each i from 1 to n − 1. A table header makes each
  super-table of the table that it names when that super-table does not
  exist yet.
- The holding table of a dotted key is the inline table that holds the
  dotted key. When no inline table holds it, the holding table is the
  table that the last table header before the dotted key names. When no
  table header comes before the dotted key, the holding table is the
  root table.
- The path of a dotted key `k1.k2.….kn = v` is the sequence of the
  tables that the keys k1 to ki lead to from its holding table, for each
  i from 1 to n − 1, in that order.

### 3.12 TOML documents

@req toml-documents=v1
@cites toml/1.1.0
@cites #characters=v1
@cites #toml-paths=v1

A TOML document is a sequence of bytes that meets both of these
conditions:

1. Without the UTF-8 encoding of a byte order mark at its start, when it
   starts with one, it is a valid document of TOML 1.1.0, read with
   these two rules:
   - Two keys are the same key only when they are the same text after
     their escapes resolve.
   - A table that table headers make only as a super-table of the
     tables that they name is a table that no table header defines. A
     dotted key can define such a table and add keys to it.
2. The path of no dotted key holds a table that a table header before
   that dotted key names.

The root table of a TOML document is the top-level table that TOML
1.1.0 gives for the document: its keys, each with its value and the
type of TOML 1.1.0 of that value. Each key and each string in the root
table, and in each table and array within it, is the text that TOML
1.1.0 gives for it after its escapes resolve, with no other change.

### 3.13 Reading TOML documents

@req toml-reading=v1
@cites #toml-documents=v1

For each sequence of bytes, a conforming implementation must give the
result valid and the root table of the TOML document when the bytes are
a TOML document. For every other sequence of bytes, it must give the
result invalid.

### 3.14 Hashes

@req hashes=v1
@cites fips/180-4
@cites #notation=v1
@cites #hex=v1

A sequence of bytes makes a message of FIPS 180-4: 8 bits for each byte,
in the order of the bytes, the most significant bit of each byte first.
The digest of the sequence of bytes is the message digest of 256 bits
that SHA-256, as FIPS 180-4 defines it, gives for that message, as 32
bytes: 8 bits for each byte, in their order, the most significant bit
of each byte first. The hash of a sequence of bytes is the hex
text of its digest. This production gives the form of a hash:

```abnf
hash  = 64hex-digit
```

### 3.15 Computing hashes

@req hashing=v1
@cites #hashes=v1

For each sequence of bytes, a conforming implementation must give its
hash.

### 3.16 The form of a hash

@req hash-form=v1
@cites #notation=v1
@cites #hashes=v1

For each text, a conforming implementation must give the result valid
when the text matches `hash`, and the result invalid when it does not.

### 3.17 Hash ids

@req hash-ids=v1
@cites #notation=v1
@cites #hex=v1
@cites #hashes=v1

This production gives the form of an id prefix:

```abnf
id-prefix  = 1*%x61-7A "-"
```

An id prefix is a text that matches `id-prefix`. For an id prefix p, a
whole number n from 1 to 64, and a sequence of bytes b, the hash id of b
with p and n is the text p, then the first n characters of the hash of
b. A text has the form of a hash id with p and n when it is the text p,
then exactly n characters that each match `hex-digit`.

### 3.18 Computing hash ids

@req hash-id-writing=v1
@cites #hash-ids=v1

For each id prefix p, each whole number n from 1 to 64, and each
sequence of bytes b, a conforming implementation must give the hash id
of b with p and n.

### 3.19 The form of a hash id

@req hash-id-form=v1
@cites #hash-ids=v1

For each text t, each id prefix p, and each whole number n from 1 to
64, a conforming implementation must give the result valid when t has
the form of a hash id with p and n, and the result invalid when it does
not.

## 4. Conformance

An implementation conforms to this design when it meets every
requirement of section 3.

Each vector below gives an input and what a conforming implementation
gives for it. These conventions apply:

- A JSON value is written as a JSON text of RFC 8259 that holds no key
  twice in one object, and no number that is not an integer. The JSON
  value is the one that the JSON text gives.
- A sequence of bytes is written as texts, which stand for their UTF-8
  encodings, and bytes named as hex numbers, such as 0x0A.
- A character that does not show is named by its code point, such as
  U+E000.
- The text after "invalid:" explains the result. An implementation
  does not give it.

### 4.1 Canonical forms

Each row gives a JSON value and its canonical bytes, as a text.

| JSON value | canonical form |
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

Each row gives a sequence of bytes and the result. When a row names the
byte 0x0A, the row gives all the bytes. Otherwise, the bytes end with
one byte 0x0A after the bytes that the row gives.

| bytes | result |
|---|---|
| `{"a":2,"b":1}` | valid: the line object `{"a":2,"b":1}` |
| `{}` | valid: the empty line object |
| `{"a":[1,"x",true]}` | valid: the line object `{"a":[1,"x",true]}` |
| `{"a":[{"b":1},{"c":"x"}]}` | valid: the line object `{"a":[{"b":1},{"c":"x"}]}` |
| `{"a":[]}` | valid: the line object `{"a":[]}` |
| `{"a":-9007199254740991}` | valid: the line object `{"a":-9007199254740991}` |
| `{"a":"\u000b"}` | valid: the line object in which `a` holds the string U+000B |
| `{"a":"`, U+1F600, `"}` | valid: the line object in which `a` holds the string U+1F600 |
| `{"`, U+1F600, `":2,"`, U+E000, `":1}` | valid: the line object with the key U+1F600 and the integer 2, and the key U+E000 and the integer 1 |
| `{"`, U+E000, `":1,"`, U+1F600, `":2}` | invalid: the keys are not in key order |
| `{"b":1,"a":2}` | invalid: the keys are not in key order |
| `{"a":1,"a":1}` | invalid: an object holds no key twice |
| `{"a":2,"b":1}`, and no byte 0x0A | invalid: the bytes do not end with 0x0A |
| `{"a":2,"b":1}`, 0x0D, and 0x0A | invalid: the canonical form holds no 0x0D after its `}` |
| `{"a":2}`, 0x0A, `{"b":1}`, and 0x0A | invalid: the bytes hold two canonical lines |
| 0xEF, 0xBB, 0xBF, and `{}` | invalid: a canonical line holds no byte order mark |
| `{"a": 2}` | invalid: a space stands outside a string |
| `{"a":1.0}` | invalid: `1.0` is not the canonical form of an integer |
| `{"a":1e2}` | invalid: `1e2` is not the canonical form of an integer |
| `{"a":-0}` | invalid: `-0` is not the canonical form of an integer |
| `{"a":01}` | invalid: the canonical form of an integer has no leading `0` |
| `{"a":9007199254740992}` | invalid: the number is greater than 9007199254740991 |
| `{"a":null}` | invalid: null is not a JSON value |
| `{"a":True}` | invalid: `True` is not the canonical form of a boolean |
| `{"a":"\u0041"}` | invalid: the escape of `A` is `A` |
| `{"a":"\/"}` | invalid: the escape of `/` is `/` |
| `{"a":"\u000A"}` | invalid: the escape of the line feed is `\n` |
| `{"a":"\u000B"}` | invalid: the hex digits of `\u000b` are lower case |
| `{"a":"\u007f"}` | invalid: the escape of U+007F is the character U+007F |
| `{"a":"\ud83d\ude00"}` | invalid: the escape of U+1F600 is the character U+1F600 |
| `{"a":"`, 0x09, `"}` | invalid: the escape of the tab is `\t` |
| `{"a":"`, 0xFF, `"}` | invalid: the bytes are not the UTF-8 encoding of a text |
| `[1]` | invalid: the JSON value is not an object |
| `"a"` | invalid: the JSON value is not an object |
| `{"a":{"b":1}}` | invalid: the value of `a` is an object |
| `{"a":[[1]]}` | invalid: the value of `a` is an array that holds an array |
| `{"a":[1,{"b":1}]}` | invalid: the value of `a` mixes a scalar and an object |
| `{"a":[{"b":[1]}]}` | invalid: `{"b":[1]}` is not a flat object |

### 4.3 TOML documents

Each item gives a sequence of bytes and the result. A text in an item
stands for its UTF-8 encoding, with the byte 0x0A at the end of each of
its lines. For a valid TOML document, the item gives the root table.

- `a = 1`: valid: `a` holds the TOML integer 1.
- Each of these three texts: valid, with the same root table: `a` holds
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

- The lines `a = 1` and `A = 2`: valid: `a` holds the TOML integer 1,
  and `A` holds the TOML integer 2.
- The lines `"\u00e9" = 1` and `"e\u0301" = 2`: valid: the key
  U+00E9 holds the TOML integer 1, and the key of U+0065 and U+0301
  holds the TOML integer 2.
- `a = "e\u0301"`: valid: `a` holds the string of U+0065 and U+0301.
- The bytes 0xEF, 0xBB, and 0xBF, then `a = 1`: valid: `a` holds the
  TOML integer 1.
- `a = 1`, then the bytes 0xEF, 0xBB, and 0xBF: invalid: a byte order
  mark stands after the start.
- `a = "`, the byte 0xFF, and `"`: invalid: the bytes are not the UTF-8
  encoding of a text.
- `a = { b = 1, }`: valid: `a` holds a table in which `b` holds the TOML
  integer 1.
- `t = 12:30`: valid: `t` holds the local time 12:30:00.
- `s = "\x41\e"`: valid: `s` holds the string of `A` and U+001B.
- This text: invalid: the path of the dotted key `b.c.x` holds the table
  `a.b.c`, which the header on line 1 names.

  ```toml
  [a.b.c]
  z = 9
  [a]
  b.c.x = 1
  ```

- This text: invalid: the path of the dotted key `b.c.d.k.t` holds the
  table `a.b.c.d`, which the header on line 1 names.

  ```toml
  [a.b.c.d]
  z = 9
  [a]
  b.c.d.k.t = 1
  ```

- This text: invalid: the path of the dotted key `b.c.t` holds the
  table `a.b.c`, which the header on line 1 names.

  ```toml
  [a.b.c]
  z = 9
  [[x]]
  [a]
  b.c.t = 1
  ```

- This text: invalid: the path of the dotted key `b.y` holds the last
  table of the array of tables `a.b`, which the header on line 1 names.

  ```toml
  [[a.b]]
  [a]
  b.y = 2
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

- This text: valid: `a` holds a table in which `x` holds a table, in
  which `b` holds a table, in which `c` holds the TOML integer 1.

  ```toml
  [a]
  x = { b.c = 1 }
  ```

- This text: invalid: the header on line 3 defines the table `a.b`,
  which the dotted key on line 2 defines.

  ```toml
  [a]
  b.c = 1
  [a.b]
  ```

### 4.4 Hashes and hash ids

Each row gives a sequence of bytes, written as a text, and its hash.

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

Each row gives an id prefix, a length, a sequence of bytes, and the
hash id.

| id prefix | length | bytes | hash id |
|---|---|---|---|
| `e-` | 12 | `abc` | `e-ba7816bf8f01` |
| `t-` | 12 | the empty sequence | `t-e3b0c44298fc` |
| `run-` | 1 | `abc` | `run-b` |
| `e-` | 64 | `abc` | `e-ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` |

Each row gives a text, an id prefix, a length, and the result as a hash
id.

| text | id prefix | length | result |
|---|---|---|---|
| `e-5b1c0a9d2e11` | `e-` | 12 | valid |
| `e-5b1c0a9d2e1` | `e-` | 12 | invalid: 11 hex digits |
| `e-5b1c0a9d2e11a` | `e-` | 12 | invalid: 13 hex digits |
| `e-5B1C0A9D2E11` | `e-` | 12 | invalid: upper-case letters are not hex digits |
| `t-5b1c0a9d2e11` | `e-` | 12 | invalid: the text does not start with `e-` |
| `5b1c0a9d2e11` | `e-` | 12 | invalid: the text does not start with `e-` |
