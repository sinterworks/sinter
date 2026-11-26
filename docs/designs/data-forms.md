<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Data forms
@design data-forms=v1
@cites {
    conformance=v1, text=v1, rfc/3339, rfc/5234, rfc/7405, rfc/8259,
    rfc/2781, toml-lang/1.1.0, ieee/754-2019, fips/180-4,
}
Canonical JSON values, canonical lines, TOML documents with key and value spans, SHA-256 hashes, hash IDs, and test-vector sets represent structured records, configuration files, cryptographic digests, and conformance vectors with exact byte layouts and decoded values.

Structured records serialize to canonical UTF-8 JSON byte sequences with
fixed key ordering and escaping. Configuration files arrive as UTF-8 TOML
documents that decode into typed tables with line-and-column spans for
keys and values. SHA-256 hashes and prefixed hash IDs map byte sequences
to fixed-length hex texts. Test-vector sets store grouped conformance
vectors as vector lines.

## Definitions

### Index

@term index=v1

The **index** of an element of a finite sequence is its 1-based number in
the order of the sequence. The first element has index 1, and each
following element has an index 1 greater than the preceding element.

### Hex text

@term hex-text=v1
@cites text#{hex-digit=v1, byte-sequence=v1, text=v1}

The **hex text** of a byte is a text of two hex digits: the hex digit of
the integer quotient of the byte divided by 16, then the hex digit of the
remainder. The **hex text** of a byte sequence is the text that joins the
hex texts of its bytes in order. The hex text of the empty byte sequence is
the empty text.

### JSON value

@term json-value=v1
@cites text#text=v1

A **JSON value** is a string, an integer, a boolean, an array, or an
object. Neither `null` nor any non-integer number is a JSON value.

- A **string** is a text.
- An **integer** is a signed integer from `-9,007,199,254,740,991`
  (`-(2^53 - 1)`) to `9,007,199,254,740,991` (`2^53 - 1`).
- A **boolean** is `true` or `false`.
- An **array** is a finite sequence of JSON values (its **elements**).
- An **object** is a finite set of **members**. Each **member** pairs a
  **key** (a text) with a **value** (a JSON value). No two members of one
  object have the same key.

### Key order

@term key-order=v1
@cites {rfc/2781, text#{character=v1, text=v1}, #index=v1}

The **UTF-16 code-unit sequence** of a text is the sequence of 16-bit
unsigned integers that UTF-16 (RFC 2781) assigns to each character of the
text, in order.

In **key order**, text `t` comes before a different text `u` when either
condition holds:

- At the first index where the UTF-16 code-unit sequences of `t` and `u`
  differ, the code unit of `t` is less than the code unit of `u`.
- The UTF-16 code-unit sequence of `t` has fewer code units than the UTF-16
  code-unit sequence of `u`, and every code unit of `t` equals the code
  unit of `u` at the same index.

@example In key order, the supplementary
[character](sinter:text#character=v1) U+10000 (UTF-16 code units `0xD800`,
`0xDC00` per [RFC 2781](sinter:rfc/2781)) comes before the BMP character
U+E000 (UTF-16 code unit `0xE000`), because `0xD800 < 0xE000`. In
[code point order](sinter:text#code-point-order=v1), U+E000 comes before
U+10000.

### Canonical form

@term canonical-form=v1
@cites {
    text#{character=v1, text=v1, byte-sequence=v1, decimal-numeral=v1},
    #{json-value=v1, hex-text=v1, key-order=v1},
}

The **canonical form** of a JSON value is the text that these rules
produce:

- **String:** `"`, then the **string form** of each character of the string
  in order, then `"`. The string form of `"` is `\"`, and the string form
  of `\` is `\\`. The string form of U+0008 is `\b`, of U+0009 is `\t`, of
  U+000A is `\n`, of U+000C is `\f`, and of U+000D is `\r`. The string form
  of every other character from U+0000 to U+001F is `\u00` followed by the
  hex text of its code point as a byte. The string form of every other
  character is that character itself.
- **Integer:** for an integer `>= 0`, its decimal numeral; for an integer
  `< 0`, `-` followed by the decimal numeral of its absolute value.
- **Boolean:** `true` for true, and `false` for false.
- **Array:** `[`, then the canonical forms of its elements in order
  separated by `,`, then `]`.
- **Object:** `{`, then the canonical forms of its members in the key order
  of their keys separated by `,`, then `}`. The canonical form of a member
  is the canonical form of its key as a string, then `:`, then the
  canonical form of its value.

@example Canonical forms of [JSON values](sinter:#json-value=v1) (each
written as a JSON text), with keys sorted in
[key order](sinter:#key-order=v1) and lowercase
[hex-text](sinter:#hex-text=v1) escapes for control characters:

| JSON value | canonical form |
|---|---|
| `{ "b": 1, "a": [true, false] }` | `{"a":[true,false],"b":1}` |
| `{ "ab": 1, "a": 2 }` | `{"a":2,"ab":1}` |
| `"a/b"` | `"a/b"` |
| `"x\u000By"` | `"x\u000by"` |
| `-42` | `-42` |

### Canonical byte sequence

@term canonical-byte-sequence=v1
@cites {text#utf-8-encoding=v1, #{json-value=v1, canonical-form=v1}}

The **canonical byte sequence** of a JSON value is the UTF-8 encoding of
its canonical form.

## Test vectors
@spec test-vectors=v1

Conformance test vectors pair concrete inputs with the results and values
that a conforming program returns. A test-vector set holds vector lines in
named groups. Each vector line holds the canonical byte sequence of one
vector object. A group schema specifies the meaning of a group's vector
lines. A vector line can also name needs.

### Definitions

#### Form pin

@term form-pin=v1
@cites text#{production=v1, text=v1}

A **form pin** is a text that matches the production `form-pin`:

```abnf
form-pin  = "#" segment "=" label
segment   = 1*alnum *( ( "-" / "_" / "." ) 1*alnum )
alnum     = ALPHA / DIGIT
label     = 1*( %x21-22 / %x24-29 / %x2B / %x2D-2E / %x30-3C
              / %x3E-3F / %x41-5A / %x5C / %x5E-7A / %x7C / %x7E )
```

The **schema part name** of a form pin is the text that `segment` matches
between `#` and `=`. The **schema label** of a form pin is the text that
`label` matches after `=`.

#### Group name

@term group-name=v1
@cites text#{production=v1, text=v1}

A **group name** is a text that matches the production `group-name`:

```abnf
group-name  = %x61-7A *( %x61-7A / DIGIT ) *( "-" 1*( %x61-7A / DIGIT ) )
```

#### Vector object

@term vector-object=v1
@cites #{json-value=v1, form-pin=v1, group-name=v1, key-order=v1}

A **vector object** is a JSON object with no members other than those in
this table. Every vector object has `form`, `group`, `input`, and at least
one of `result` or `values`.

| member | presence | value |
|---|---|---|
| `form` | required | string that is a `form-pin` |
| `group` | required | string that is a `group-name` |
| `input` | required | any `json-value` |
| `result` | optional | string |
| `values` | optional | any `json-value` |
| `needs` | optional | non-empty array of strings, each a `group-name`, with each element strictly before the next in `key-order` |
| `note` | optional | string |

#### Vector line

@term vector-line=v1
@cites {
    text#byte-sequence=v1,
    #{canonical-byte-sequence=v1, vector-object=v1},
}

A **vector line** is the canonical byte sequence of a vector object
followed by the single byte `0x0A`. The **object** of a vector line is that
vector object. The **form** of a vector line is the value of the `form`
member of its object. The **group** of a vector line is the value of the
`group` member of its object.

#### Test-vector set

@schema test-vector-set=v1
@cites {text#{byte-sequence=v1, text=v1}, #{form-pin=v1, vector-line=v1}}

A **test-vector set** is a byte sequence that holds zero or more vector
lines in sequence, with no other bytes, where all vector lines with the
same group have the same schema part name in their form. Vector lines with
the same group can have different schema labels in their form, and vector
lines with different groups can share a schema part name.

A **group** of a test-vector set is a text that appears as the group of one
or more vector lines of that test-vector set. The **vector lines of a
group** of a test-vector set are the vector lines of that test-vector set
whose group is that group, in order.

#### Group schema

@term group-schema=v1
@cites {
    conformance#{design=v1, conforming-program=v1, input=v1},
    #{json-value=v1, group-name=v1, vector-object=v1},
}

A **test-vector scope** is either a design `D` or a specification `S` of a
design:

- For a design `D`, the schemas and requirements in scope are all schemas
  and requirements declared anywhere in `D`, whether at design level or
  inside any specification of `D`.
- For a specification `S`, the schemas and requirements in scope are the
  schemas and requirements declared in `S`.

For a test-vector scope `T`, a schema `Q` in scope `T`, and a group name
`g`, `Q` **is a group schema for group `g`** of `T` when `Q` specifies
these five elements for `g`:

1. **Requirements of the group:** the requirements in scope `T` that `Q`
   directly cites. A requirement reached only through another cited item is
   not a requirement of the group.
2. **Input encoding:** which input or inputs of a conforming program of `T`
   the `input` member of a vector object represents, together with the
   fixed form of `input`.
3. **Result meaning:** either the question that the `result` member answers
   and which of those inputs the question is about—along with any condition
   (other than a need) under which the requirements of the group oblige
   that result—or that the group has no `result` question. When a group
   schema specifies its fields in a table that omits `result`, the group
   has no `result` question.
4. **Values encoding:** what output or absence of output of a conforming
   program of `T` the `values` member represents (including optional
   outputs or permitted alternatives) and the fixed form of `values`, or
   that the group specifies no fixed form for `values`. When a group schema
   specifies its fields in a table that omits `values`, the group has no
   `values` member and specifies no fixed form for `values`.
5. **Needs:** the **need names** that group `g` uses, if any, and the
   **need** that each need name represents. Each need name is a
   `group-name`. A **need** is an environment condition under which a
   conforming program of `T` operates that a program that checks vectors
   can be unable to establish (such as a file-system capability); a
   condition on what a conforming program returns is not a need. Within
   scope `T`, a need name represents the same need in every group schema of
   `T`. When `Q` names no needs for `g`, group `g` has no need names.

A **fixed form** is a structural shape of JSON values (their JSON kinds,
object members, the texts of their strings, or integer ranges, or a union
of such shapes across cases). Whether a JSON value has a fixed form depends
on that value alone, not on other members of the vector object.

#### Vector meaning

@term vector-meaning=v1
@cites {
    conformance#{design=v1, conforming-program=v1, input=v1},
    #{
        form-pin=v1, vector-object=v1, vector-line=v1,
        test-vector-set=v1, group-schema=v1,
    },
}

For a test-vector scope `T` (a design `D` or a specification `S`), a
**vector** of `T` pairs one or more inputs of a conforming program of `T`
with what requirements in scope `T` oblige that program to return or
withhold for those inputs.

Let `L` be a vector line with group `g` whose form has the schema part name
`p`. The object of `L` **states a vector** of `T` when all of these
conditions hold, independently of any other vector line in a test-vector
set:

- A schema `Q` in scope `T` has name `p` and is a group schema for group
  `g` of `T`.
- The value of `input` has the fixed form that `Q` specifies for `input`.
- If the object has `values`, `Q` specifies a fixed form for `values` and
  the value of `values` has that fixed form.

Otherwise, the object of `L` **states no vector** of `T`.

When the object of `L` states a vector of `T` by `Q`, that object states
these facts:

- **Input:** The input of the vector is the input or inputs of a conforming
  program of `T` that `input` represents under `Q`.
- **Needs:** The needs of the vector are the needs that `Q` maps to the
  strings in `needs`. A vector without `needs` has no needs. A string in
  `needs` that `Q` maps to no need represents no need.
- **Result:** When the object has `result` and `Q` specifies a `result`
  question, the requirements of group `g` oblige a conforming program of
  `T` to return the string value of `result` (and no other result) for that
  question about the inputs that `Q` specifies for it whenever every
  condition that `Q` states for `result` holds and every need of the vector
  holds. When `Q` specifies no `result` question, `result` states nothing.
  When the object omits `result`, that object states no result beyond what
  `values` represents.
- **Values:** When the object has `values`, the requirements of group `g`
  oblige a conforming program of `T` to return or withhold what `values`
  represents for the vector's input whenever every need of the vector
  holds. When the object omits `values`, that object states nothing beyond
  what `result` represents.
- **Note and needs:** The `note` member explains the vector line for
  readers. Neither `note` nor `needs` is part of the vector's input,
  result, or values.

A **vector check** of a test-vector set for scope `T` decides, for each
vector of `T` stated by a vector line in the set, whether a program that
runs while every need of that vector holds returns what the vector states.
A skip of a vector decides nothing about that vector only when the vector
check cannot establish a need of that vector and reports that need. Every
other skip—including a skip for a string in `needs` that `Q` maps to no
need—counts as a decision that the program does not return what the vector
states. Every decision, including a decision on a skip, belongs to the
vector check itself rather than to a reader of its report.

### Reading test-vector sets

@req read-test-vector-set=v1
@cites {
    conformance#conforming-program=v1,
    text#byte-sequence=v1,
    #{vector-object=v1, vector-line=v1, test-vector-set=v1},
}

When a conforming program reads a byte sequence as a test-vector set:

- If the byte sequence is a `test-vector-set`, the program must return
  `"valid"` and the ordered sequence of vector objects of its vector lines
  (the empty sequence when the byte sequence is empty).
- Otherwise, the program must return `"invalid"` and no sequence of vector
  objects.

### Conformance

@schema read-set-vector=v1
@cites {
    text#byte-sequence=v1,
    #{
        json-value=v1, hex-text=v1, vector-object=v1, vector-line=v1,
        test-vector-set=v1, group-schema=v1, vector-meaning=v1,
        read-test-vector-set=v1,
    },
}

`read-set-vector` is a group schema for group `read-set` of specification
`test-vectors` and tests `read-test-vector-set`. The file
[`data-forms.test-vectors.test-vectors.jsonl`](data-forms.test-vectors.test-vectors.jsonl)
holds this group as a `test-vector-set` of `vector-line` entries whose
meaning follows `vector-meaning`. No vector uses `needs`.

| field | type | meaning |
|---|---|---|
| `input` | string | `hex-text` of the input `byte-sequence` (`""` for empty) |
| `result` | string | `"valid"` when the byte sequence is a `test-vector-set`, `"invalid"` otherwise |
| `values.objects` | array of `vector-object` (optional) | ordered objects of the `vector-line`s when `result` is `"valid"`; absent (`values` is `{}`) when `result` is `"invalid"` (no sequence returned) |

@example Sample lines testing
[read-test-vector-set](sinter:#read-test-vector-set=v1) on valid and
invalid [test-vector-set](sinter:#test-vector-set=v1) inputs encoded as
[hex-text](sinter:#hex-text=v1):

```json
{"form":"#read-set-vector=v1","group":"read-set","input":"7b22666f726d223a2223613d7631222c2267726f7570223a2261222c22696e707574223a2278222c22726573756c74223a2276616c6964227d0a","result":"valid","values":{"objects":[{"form":"#a=v1","group":"a","input":"x","result":"valid"}]}}
{"form":"#read-set-vector=v1","group":"read-set","input":"7b22726576223a227631227d0a","note":"a vector object has no member `rev` and requires `form`, `group`, and `input`","result":"invalid","values":{}}
```

## JSON lines
@spec json-lines=v1

Canonical lines store structured JSON records as single-line UTF-8 objects
with one fixed byte layout. Two programs that encode the same line objects
in the same order produce the same bytes.

### Definitions

#### Line object

@term line-object=v1
@cites #json-value=v1

A **scalar** is a `json-value` string, integer, or boolean. A **flat
object** is a `json-value` object in which every member value is a scalar.
A **line object** is a `json-value` object in which every member value is
one of these three forms:

- a scalar;
- a `json-value` array whose elements are all scalars; or
- a `json-value` array whose elements are all flat objects.

@example `{}`, `{"a":[]}`, and `{"a":[{}]}` are line objects
([json-value](sinter:#json-value=v1)). These JSON objects are not line
objects:

| object | reason |
|---|---|
| `{"a":{"b":1}}` | member `a` holds an object |
| `{"a":[[1]]}` | member `a` holds an array of arrays |
| `{"a":[1,{"b":1}]}` | member `a` mixes a scalar and an object |
| `{"a":[{"b":[1]}]}` | object `{"b":[1]}` is not a flat object |

#### Canonical line

@schema canonical-line=v1
@cites {
    text#byte-sequence=v1,
    #{line-object=v1, canonical-byte-sequence=v1},
}

The **canonical line** of a `line-object` is the `byte-sequence` that
holds the `canonical-byte-sequence` of that `line-object` followed by the
single byte `0x0A`. A `byte-sequence` is a **canonical line** when that
`byte-sequence` is the canonical line of a `line-object`.

@example None of these [byte sequences](sinter:text#byte-sequence=v1) is a
canonical line under
[canonical-byte-sequence](sinter:#canonical-byte-sequence=v1),
[canonical-form](sinter:#canonical-form=v1),
[key-order](sinter:#key-order=v1), [json-value](sinter:#json-value=v1),
and [line-object](sinter:#line-object=v1) (each row shows the ASCII bytes
in code spans followed by any trailing bytes):

| byte sequence | reason |
|---|---|
| `{"b":1,"a":2}`, `0x0A` | keys are not in key order |
| `{"a": 2}`, `0x0A` | a space appears outside a string |
| `{"a":2}` | the trailing `0x0A` byte is absent |
| `{"a":2}`, `0x0D`, `0x0A` | `0x0D` appears before `0x0A` |
| `{"a":1.0}`, `0x0A` | `1.0` is not the canonical form of an integer |
| `{"a":null}`, `0x0A` | `null` is not a JSON value |
| `{"a":"\u0041"}`, `0x0A` | the string form of `A` is `A` |
| `[1]`, `0x0A` | the value is not a line object |

#### Decoded JSON

@term decoded-json=v1
@cites {
    rfc/8259,
    rfc/2781,
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-text=v1, character=v1,
        text=v1,
    },
    #json-value=v1,
}

A `byte-sequence` `b` has a **decoded JSON** value when `b` satisfies all
of these narrowings of RFC 8259:

| aspect | rule |
|---|---|
| UTF-8 and U+FEFF | `b` is `valid-utf-8`, and the `utf-8-text` of `b` does not start with U+FEFF. |
| JSON grammar | The `utf-8-text` of `b` matches the `JSON-text` rule of RFC 8259. |
| no `null` | No value anywhere in the JSON text is `null`. |
| integers | Every JSON number has no fraction (`frac`) and no exponent (`exp`) and represents a `json-value` integer. Each such number decodes to that integer (`-0` decodes to `0`). |
| strings and surrogates | Every JSON string and every object member name decodes per RFC 8259 (a `\u` escape sequence takes uppercase or lowercase hexadecimal digits). Every `\u` escape sequence in `0xD800` to `0xDBFF` immediately precedes a `\u` escape sequence in `0xDC00` to `0xDFFF`, and every `\u` escape sequence in `0xDC00` to `0xDFFF` immediately follows a `\u` escape sequence in `0xD800` to `0xDBFF`. Each such adjacent pair decodes to the single `character` whose UTF-16 encoding (RFC 2781) is those two 16-bit code units. |
| unique object keys | No JSON object anywhere in the JSON text has two members whose decoded names are equal `text`s (comparing characters directly with no Unicode normalization). |

When `b` satisfies all of those rules, the **decoded JSON** value of `b`
is the `json-value` formed recursively from the root value of the JSON
text: `true` and `false` decode to the booleans true and false, each
number decodes to its integer, each string decodes to its `text`, each
array decodes to the `json-value` array of its decoded elements in order,
and each object decodes to the `json-value` object holding one member per
JSON member with its decoded name and decoded value. Otherwise, `b` has no
decoded JSON value.

@example Under [utf-8-encoding](sinter:text#utf-8-encoding=v1), the UTF-8
bytes of `{ "b": 1, "a": "\u00e9" }` followed by `0x0A` decode to the
[json-value](sinter:#json-value=v1) whose
[canonical-form](sinter:#canonical-form=v1) is `{"a":"é","b":1}`. The
UTF-8 bytes of `-0` decode to `0`, the UTF-8 bytes of `"\uD83D\uDE00"`
decode to `"😀"`, and the UTF-8 bytes of `{"é":1,"e\u0301":2}` decode to
an object with two distinct keys (`U+00E9` and `e` followed by `U+0301`).
The UTF-8 bytes of `{"a":1.0}`, `{"a":1,"\u0061":2}`, and `"\ud800"` have
no decoded JSON value.

### Encoding canonical JSON

@req write-canonical-json=v1
@cites {
    conformance#conforming-program=v1,
    #{json-value=v1, canonical-byte-sequence=v1},
}

When a conforming program encodes a `json-value` as canonical JSON, the
program must return the `canonical-byte-sequence` of that `json-value`.

### Encoding canonical lines

@req write-canonical-line=v1
@cites {
    conformance#conforming-program=v1,
    #{json-value=v1, line-object=v1, canonical-line=v1},
}

When a conforming program encodes a `json-value` as a `canonical-line`
and that `json-value` is a `line-object`, the program must return the
`canonical-line` of that `line-object`. When that `json-value` is not a
`line-object`, the program must return no `canonical-line`.

### Decoding canonical lines

@req read-canonical-line=v1
@cites {
    conformance#conforming-program=v1,
    text#byte-sequence=v1,
    #{line-object=v1, canonical-line=v1},
}

When a conforming program decodes a `byte-sequence` as a `canonical-line`
and that `byte-sequence` is a `canonical-line`, the program must return
`"valid"` and the `line-object` whose `canonical-line` that
`byte-sequence` is. When that `byte-sequence` is not a `canonical-line`,
the program must return `"invalid"` and no `line-object`.

### Decoding JSON text

@req read-json-text=v1
@cites {
    conformance#conforming-program=v1,
    text#byte-sequence=v1,
    #{json-value=v1, decoded-json=v1},
}

When a conforming program decodes a `byte-sequence` as JSON text and that
`byte-sequence` has a `decoded-json` value, the program must return
`"valid"` and that `decoded-json` value. When that `byte-sequence` has no
`decoded-json` value, the program must return `"invalid"` and no
`json-value`.

### Test vectors

The file
[`data-forms.json-lines.test-vectors.jsonl`](data-forms.json-lines.test-vectors.jsonl)
holds the test vectors of `json-lines`. No group uses `needs`. Every
vector field that holds a byte sequence encodes that byte sequence as a
`hex-text` string (`""` for the empty byte sequence).

#### Canonical JSON encoding vectors

@schema write-json-vector=v1
@cites {
    text#utf-8-encoding=v1,
    #{
        write-canonical-json=v1, json-value=v1, decoded-json=v1,
        canonical-byte-sequence=v1, hex-text=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1,
    },
}

`write-json-vector` is a group schema for group `write-json` of
specification `json-lines` and tests `write-canonical-json`. Each line is
a `vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input` | string | JSON text whose `utf-8-encoding` has a `decoded-json` value; that value is the input `json-value` |
| `values.canonical-byte-sequence` | string | expected `canonical-byte-sequence` of the input, encoded as `hex-text` |

@example Sample lines testing
[write-canonical-json](sinter:#write-canonical-json=v1) with
[canonical-byte-sequence](sinter:#canonical-byte-sequence=v1) and
[hex-text](sinter:#hex-text=v1):

```json
{"form":"#write-json-vector=v1","group":"write-json","input":"{ \"ab\": 1, \"a\": 2 }","values":{"canonical-byte-sequence":"7b2261223a322c226162223a317d"}}
{"form":"#write-json-vector=v1","group":"write-json","input":"{ \"\\ue000\": 1, \"\\ud83d\\ude00\": 2 }","values":{"canonical-byte-sequence":"7b22f09f9880223a322c22ee8080223a317d"}}
```

#### Canonical line encoding vectors

@schema write-line-vector=v1
@cites {
    text#utf-8-encoding=v1,
    #{
        write-canonical-line=v1, json-value=v1, decoded-json=v1,
        line-object=v1, canonical-line=v1, hex-text=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1,
    },
}

`write-line-vector` is a group schema for group `write-line` of
specification `json-lines` and tests `write-canonical-line`. Each line is
a `vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input` | string | JSON text whose `utf-8-encoding` has a `decoded-json` value; that value is the input `json-value` |
| `values.canonical-line` | string (optional) | expected `canonical-line` of the input, encoded as `hex-text`, when the input is a `line-object`; absent (`values` is `{}` for no `canonical-line`) otherwise |

@example Sample lines testing
[write-canonical-line](sinter:#write-canonical-line=v1) with
[line-object](sinter:#line-object=v1),
[canonical-line](sinter:#canonical-line=v1), and
[hex-text](sinter:#hex-text=v1):

```json
{"form":"#write-line-vector=v1","group":"write-line","input":"{}","values":{"canonical-line":"7b7d0a"}}
{"form":"#write-line-vector=v1","group":"write-line","input":"{ \"a\": { \"b\": 1 } }","note":"the value of `a` is an object","values":{}}
```

#### Canonical line decoding vectors

@schema read-line-vector=v1
@cites {
    text#byte-sequence=v1,
    #{
        read-canonical-line=v1, json-value=v1, line-object=v1,
        canonical-line=v1, hex-text=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
}

`read-line-vector` is a group schema for group `read-line` of specification
`json-lines` and tests `read-canonical-line`. Each line is a `vector-line`
whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input` | string | input `byte-sequence`, encoded as `hex-text` |
| `result` | string | `"valid"` when `input` is a `canonical-line`, `"invalid"` otherwise |
| `values.line-object` | object (optional) | decoded `line-object` when `result` is `"valid"`; absent (`values` is `{}` for no `line-object`) when `result` is `"invalid"` |

@example Sample lines testing
[read-canonical-line](sinter:#read-canonical-line=v1) with
[canonical-line](sinter:#canonical-line=v1),
[line-object](sinter:#line-object=v1), and
[hex-text](sinter:#hex-text=v1):

```json
{"form":"#read-line-vector=v1","group":"read-line","input":"7b2261223a322c2262223a317d0a","result":"valid","values":{"line-object":{"a":2,"b":1}}}
{"form":"#read-line-vector=v1","group":"read-line","input":"7b2261223a20327d0a","note":"a space stands outside a string","result":"invalid","values":{}}
```

#### JSON text decoding vectors

@schema read-json-vector=v1
@cites {
    text#byte-sequence=v1,
    #{
        read-json-text=v1, json-value=v1, decoded-json=v1, hex-text=v1,
        vector-line=v1, group-schema=v1, vector-meaning=v1,
    },
}

`read-json-vector` is a group schema for group `read-json` of specification
`json-lines` and tests `read-json-text`. Each line is a `vector-line` whose
meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input` | string | input `byte-sequence`, encoded as `hex-text` |
| `result` | string | `"valid"` when `input` has a `decoded-json` value, `"invalid"` otherwise |
| `values.json-value` | JSON value (optional) | `decoded-json` value (a `json-value`) when `result` is `"valid"`; absent (`values` is `{}` for no `json-value`) when `result` is `"invalid"` |

@example Sample lines testing
[read-json-text](sinter:#read-json-text=v1) with
[decoded-json](sinter:#decoded-json=v1),
[json-value](sinter:#json-value=v1), and [hex-text](sinter:#hex-text=v1):

```json
{"form":"#read-json-vector=v1","group":"read-json","input":"7b20226222203a205b312c20325d202c092261223a74727565207d0d0a","note":"spaces, a tab, a carriage return, and a line feed stand around values and around `:` and `,`, and the members do not stand in key order","result":"valid","values":{"json-value":{"a":true,"b":[1,2]}}}
{"form":"#read-json-vector=v1","group":"read-json","input":"312e30","note":"the number has a fraction","result":"invalid","values":{}}
```

## TOML
@spec toml=v1

TOML files store structured configuration data as UTF-8 text made of
tables, arrays, and typed scalar values. A parser decodes a valid TOML
byte sequence into a root table of nested key-value entries. A parser can
also record the line and column span of each key and value in the document.

### Definitions

#### TOML key

@term toml-key=v1
@cites {toml-lang/1.1.0, text#text=v1}

In TOML 1.1.0, a key is either a simple key (a bare key or a quoted key)
or a dotted key that joins two or more simple keys with `.`.

- A **TOML key** is a key of TOML 1.1.0 that is not a dotted key.
- The **key** of a key/value pair or a table header is the key of TOML
  1.1.0 in that key/value pair or table header.
- When a key is a TOML key, the **TOML keys** of that key are that
  single TOML key. When a key is a dotted key, the **TOML keys** of that
  key are the TOML keys that the dotted key joins with `.`, in order.
- The **text** of a TOML key is the `text` that TOML 1.1.0 produces for
  that TOML key after escape decoding, with no Unicode normalization or
  other change. The quoted keys `""` and `''` each have the empty text.

#### TOML value

@term toml-value=v1
@cites {
    toml-lang/1.1.0, ieee/754-2019, rfc/3339,
    text#text=v1,
    #toml-key=v1,
}

A **TOML value** is a value in the data model that TOML 1.1.0 reads from
a document: the value of a TOML 1.1.0 value expression, the root table
of a document, a table that a table header or a dotted key creates, a
TOML array that array-of-tables headers create, or any TOML value inside
one of those containers.

Each TOML value belongs to one of ten kinds:

| kind | data |
|---|---|
| TOML string | a `text` |
| TOML integer | a signed 64-bit integer from `-9,223,372,036,854,775,808` (`-2^63`) to `9,223,372,036,854,775,807` (`2^63 - 1`), inclusive |
| TOML float | an IEEE 754-2019 `binary64` value |
| TOML boolean | `true` or `false` |
| local date | a year, a month, and a day |
| local time | an hour, a minute, a second, and a fraction of a second |
| local date-time | a local date and a local time |
| offset date-time | a local date-time and an offset (either a signed number of minutes or the unknown local offset of RFC 3339, section 4.3, which is distinct from `0` minutes) |
| TOML array | a finite sequence of TOML values |
| table | a finite, unordered set of entries, each pairing the text of a `toml-key` with a TOML value, with no duplicate key text |

A table holds each key text in its entries and maps each held key text
to its paired TOML value.

#### TOML reading rule

@term toml-reading-rule=v1
@cites {
    toml-lang/1.1.0, ieee/754-2019, rfc/3339,
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-text=v1, slice=v1,
        body=v1, character=v1,
    },
    #toml-value=v1,
}

The **TOML reading rules** settle the encoding, range, and
implementation-defined choices of TOML 1.1.0:

| aspect | rule |
|---|---|
| byte order mark | For a `valid-utf-8` `byte-sequence`, TOML 1.1.0 reads the text of the `body` `slice` of its `utf-8-text`. |
| integer range | The integer of every TOML integer literal is from `-9,223,372,036,854,775,808` (`-2^63`) to `9,223,372,036,854,775,807` (`2^63 - 1`), inclusive. |
| float value | For any TOML 1.1.0 float other than `inf`, `+inf`, `-inf`, `nan`, `+nan`, and `-nan`, the resulting TOML float is the IEEE 754-2019 `binary64` value whose sign bit is `1` when the literal starts with `-` and `0` otherwise, and whose magnitude is the `binary64` value that rounding the literal's absolute value to nearest, ties to even, produces. |
| second fraction | When digits `d1` through `dk` follow `.` in the second field of a local time, local date-time, or offset date-time, the fraction of a second is the sum of `di / 10^i` for `i` from `1` to `min(k, 9)`. |
| leap second | This rule replaces the leap-second restriction of RFC 3339, section 5.7. Every second from `0` to `60` is valid in a local time, a local date-time, and an offset date-time, on every date and at every hour and minute. |
| offset date-time | The offset `-00:00` produces the unknown local offset of RFC 3339, section 4.3. The offsets `Z` and `z` produce offset `0` minutes. Every other numeric offset produces its signed number of minutes (for example, `0` for `+00:00` and `-420` for `-07:00`). An offset date-time keeps the local date-time written before its offset and does not convert that local date-time to UTC. |
| multi-line string newline | Every newline in a multi-line basic string or multi-line literal string that TOML 1.1.0 does not trim stays in the TOML string as its exact `character` sequence: `U+000A`, or `U+000D` followed by `U+000A`. |

@example Under these reading rules, `1979-05-27T07:32:00Z` and
`1979-05-27T07:32:00+00:00` both decode to a [TOML value](sinter:#toml-value=v1)
with offset `0` minutes, `1979-05-27T07:32:00-00:00` decodes to the
unknown local offset, and `1979-05-27T00:32:00-07:00` keeps local time
`00:32:00` with offset `-420` minutes. The local time
`00:00:00.1234567891` truncates to fraction `0.123456789`, and the float
`1e309` rounds to positive infinity.

#### TOML value equality

@term toml-value-equality=v1
@cites {
    ieee/754-2019,
    text#text=v1,
    #{index=v1, toml-value=v1},
}

Two TOML values are **equal** when they have the same kind and satisfy
the rule for that kind:

- **TOML strings**: their `text` values are equal.
- **TOML integers**: they are the same integer.
- **TOML booleans**: both are `true` or both are `false`.
- **TOML floats**: their IEEE 754-2019 `binary64` values have the same
  64-bit representation, or both are NaN.
- **local dates, local times, local date-times, or offset date-times**:
  every part that belongs to their kind (year, month, day, hour, minute,
  second, fraction of a second, and offset) is the same.
- **TOML arrays**: they hold the same number of elements, and their
  elements at each 1-based `index` are equal.
- **tables**: they hold the same set of key texts, and for each held key
  text their paired TOML values are equal.

@example Under the [TOML reading rules](sinter:#toml-reading-rule=v1),
the [TOML values](sinter:#toml-value=v1) for `-0.0` and `0.0` are not
equal, `+nan` and `-nan` are equal, `1.0` and `1` have different kinds
and are not equal, `1979-05-27T07:32:00Z` and
`1979-05-27T07:32:00+00:00` are equal, and neither equals
`1979-05-27T07:32:00-00:00` or `1979-05-27T00:32:00-07:00`.

#### TOML document

@schema toml-document=v1
@cites {
    toml-lang/1.1.0, rfc/3339,
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-text=v1, slice=v1,
        body=v1,
    },
    #{toml-value=v1, toml-reading-rule=v1},
}

A **TOML document** is a `byte-sequence` that meets all of these
conditions:

1. The byte sequence is `valid-utf-8`.
2. The text of the `body` `slice` of its `utf-8-text` matches the ABNF
   rule `toml` of TOML 1.1.0.
3. Every TOML integer literal in the body meets the integer range of
   `toml-reading-rule`.
4. Every local date, local time, local date-time, and offset date-time
   in the body satisfies the calendar, time, and offset range rules of
   RFC 3339, sections 5.6 and 5.7, with the leap-second rule of
   `toml-reading-rule` in place of RFC 3339's leap-second restriction.
5. The keys, tables, arrays, and strings of the body break no semantic
   rule of TOML 1.1.0 (such as redefining a key or table, modifying an
   inline table or static array after its definition, or writing a
   non-scalar Unicode code point in an escape sequence).

#### Root table

@term root-table=v1
@cites {
    toml-lang/1.1.0,
    #{toml-value=v1, toml-reading-rule=v1, toml-document=v1},
}

The **root table** of a `toml-document` is the top-level `table` that
TOML 1.1.0 produces for that document under `toml-reading-rule`. In the
root table, every table that a table header, a dotted key, or an inline
table creates is a TOML value of kind `table`. Every array that
array-of-tables headers or `[` and `]` brackets create is a TOML value
of kind `TOML array`.

#### TOML location

@term toml-location=v1
@cites #{
    index=v1, toml-key=v1, toml-value=v1, toml-document=v1,
    root-table=v1,
}

The **location** of a TOML value in a `toml-document` is the finite
sequence of steps that leads from the document's `root-table` to that
TOML value. Each step is either the text of a `toml-key` (entering a
table entry) or a 1-based `index` (entering an element of a TOML array).

- The location of the `root-table` is the empty sequence of steps.
- When a table at location `L` holds key text `k`, the paired TOML value
  has location `L` followed by `k`.
- When a TOML array at location `L` holds a TOML value at 1-based
  `index` `i`, that TOML value has location `L` followed by `i`.
- Two tables in a `toml-document` are the same table when they have the
  same location, and two tables at different locations are distinct even
  when their entries are equal.

#### TOML span

@term toml-span=v1
@cites {
    toml-lang/1.1.0,
    text#{utf-8-text=v1, slice=v1, body=v1, position=v1, span=v1},
    #{
        index=v1, toml-key=v1, toml-value=v1, toml-document=v1,
        root-table=v1, toml-location=v1,
    },
}

Every span in this definition is a `span` (a `slice` with boundaries in
the `body`) of the `utf-8-text` of a `toml-document`. The start and end of
each span are its start and end positions under `text#span`.

The TOML 1.1.0 ABNF rules determine the `slice` of each syntactic part:

- **Key**: the `slice` that the ABNF rule `key` matches for the key of a
  key/value pair or a table header. For a dotted key, this slice
  includes spaces or tabs around `.`; it omits spaces or tabs before or
  after the whole `key`.
- **TOML key**: the `slice` that the ABNF rule `simple-key` matches for
  a `toml-key` of such a key. For a quoted key, this slice includes its
  enclosing quotes.
- **Value expression**: the `slice` that the ABNF rule `val` matches for
  the value of a key/value pair or an element of a bracketed array. This
  slice includes the quotes of a string, the brackets of an array, and
  the braces of an inline table, and omits surrounding whitespace or
  comments.

A **TOML span** of a `toml-document` pairs one `span` of the document's
`utf-8-text` with its target. A `toml-document` has these TOML spans and
no others:

- **Value span**: for each TOML value produced by a `val` expression,
  its `val` span paired with that TOML value at its `toml-location`.
- **Key span**: for the key of each key/value pair, its `key` span
  paired with the key leading to the `toml-location` of that pair's TOML
  value; and for the key of each table header (`[...]` or `[[...]]`),
  its `key` span paired with the key leading to the `toml-location` of
  the table that the table header defines.
- **TOML-key span**: for each `toml-key` at 1-based `index` `i` among
  the TOML keys of a key/value pair's key or a table header's key, its
  `simple-key` span paired with the `i`-th `toml-key` of the key leading
  to that same `toml-location`.

These TOML values have no value span: the `root-table`, every table that
a table header creates (including super-tables and tables from `[[...]]`
headers), every table that a dotted key creates, and every TOML array
that array-of-tables headers create.

@example In the [TOML document](sinter:#toml-document=v1)
`a . b = { c = 1 }` on line 1 of its [body](sinter:text#body=v1), the
dotted key's `key` [span](sinter:text#span=v1) covers `a . b`
([positions](sinter:text#position=v1) line 1, columns 1 to 6) for
[location](sinter:#toml-location=v1) `["a", "b"]`. Its two `simple-key`
spans cover the [TOML keys](sinter:#toml-key=v1) `a` (columns 1 to 2,
[index](sinter:#index=v1) 1) and `b` (columns 5 to 6, index 2). The
inline table's `val` span covers `{ c = 1 }` (columns 9 to 18) for
location `["a", "b"]`, while the intermediate table at location `["a"]`
that the dotted key creates has no value span.

### Reading TOML documents

@req read-toml=v1
@cites {
    conformance#conforming-program=v1,
    text#byte-sequence=v1,
    #{
        toml-value=v1, toml-value-equality=v1, toml-document=v1,
        root-table=v1,
    },
}

When a conforming program reads a `byte-sequence` as a TOML document and
the byte sequence matches `toml-document`, the program must return
`"valid"` and a table equal to the document's `root-table` under
`toml-value-equality`. When a conforming program reads a `byte-sequence`
that does not match `toml-document`, the program must return `"invalid"`
and no root table.

### Returning TOML spans

@req give-toml-spans=v1
@cites {
    conformance#conforming-program=v1,
    text#{byte-sequence=v1, line=v1, position=v1, span=v1},
    #{toml-document=v1, toml-location=v1, toml-span=v1},
}

A conforming program may return TOML spans for a `byte-sequence` that
matches `toml-document`. When a conforming program returns a span (or its
start or end `position` line number or column) for a TOML value, key, or
TOML key of a `toml-document`, the span and its start and end positions
must match the corresponding `toml-span` of that document. A conforming
program must return no value span for a `toml-location` that has no value
span under `toml-span`. For a `byte-sequence` that does not match
`toml-document`, a conforming program must return no TOML span.

### Test vectors

The file
[`data-forms.toml.test-vectors.jsonl`](data-forms.toml.test-vectors.jsonl)
holds the test vectors of `toml`. No group uses `needs`. Every byte
sequence appears as its `hex-text` string.

#### TOML document vectors

@schema toml-document-vector=v1
@cites {
    ieee/754-2019,
    text#{byte-sequence=v1, text=v1, decimal-numeral=v1},
    #{
        index=v1, hex-text=v1, json-value=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1, toml-key=v1, toml-value=v1,
        toml-reading-rule=v1, toml-value-equality=v1, toml-document=v1,
        root-table=v1, read-toml=v1,
    },
}

`toml-document-vector` is a group schema for groups `give-root-table` and
`reject-byte-sequence` of specification `toml` and tests `read-toml`. Each
line is a `vector-line` whose meaning follows `vector-meaning`.

A **table** appears as a JSON object with one member per entry: the
member key is the text of the `toml-key`, and the member value is the
JSON form of the paired `toml-value`. Each **TOML value** appears as a
single-member JSON object:

| kind | member key | member value |
|---|---|---|
| TOML string | `string` | the `text` of the TOML string as a JSON string |
| TOML integer | `integer` | a JSON string with `-` (when negative) followed by the `decimal-numeral` of the absolute value, such as `"-17"` |
| TOML float | `float` | a JSON string in the float string form |
| TOML boolean | `boolean` | `true` or `false` |
| local date | `local-date` | a JSON string in the date-time string form |
| local time | `local-time` | a JSON string in the date-time string form |
| local date-time | `local-date-time` | a JSON string in the date-time string form |
| offset date-time | `offset-date-time` | a JSON string in the date-time string form |
| TOML array | `array` | a JSON array of the JSON forms of its elements in 1-based `index` order |
| table | `table` | the JSON form of the table |

In the **float string form**, NaN is `"nan"`, positive infinity is
`"inf"`, negative infinity is `"-inf"`, and negative zero is `"-0"`. For
every other TOML float, the string holds `-` when negative, then the
`decimal-numeral` of the integer part of its absolute value, then (when
the absolute value is not an integer) `.` followed by the exact base-10
fractional digits of the IEEE 754-2019 `binary64` value with no trailing
`0` (such as `"0"`, `"0.5"`, and `"100000000000000000000"`).

In the **date-time string form**:

- A **local date** is four year digits, `-`, two month digits, `-`, and
  two day digits (such as `"1600-02-29"`).
- A **local time** is two hour digits, `:`, two minute digits, `:`, and
  two second digits, followed when the fraction of a second is nonzero
  by `.` and the base-10 fractional digits with no trailing `0` (such as
  `"12:30:00"` for `12:30` and `"12:30:00.5"` for `12:30:00.50`).
- A **local date-time** is its local date string, `T`, and its local
  time string.
- An **offset date-time** is its local date-time string followed by its
  offset string: `"+00:00"` for offset `0` minutes (`Z`, `z`, or
  `+00:00`), `"-00:00"` for the unknown local offset under
  `toml-reading-rule`, and otherwise `+` for a positive offset or `-` for
  a negative offset, then the two-digit integer quotient of
  `|offset| / 60`, `:`, and the two-digit remainder (such as
  `"1979-05-27T00:32:00-07:00"`).

Two tables are equal under `toml-value-equality` when their JSON forms
are the same `json-value`.

| field | type | meaning |
|---|---|---|
| `input` | string | `byte-sequence` as its `hex-text` (`""` for empty) |
| `result` | string | `"valid"` in group `give-root-table` (`input` matches `toml-document`); `"invalid"` in group `reject-byte-sequence` (`input` does not match `toml-document`) |
| `values.root-table` | object (optional) | JSON form of the document's `root-table` in group `give-root-table`; absent (`values` is `{}`) in group `reject-byte-sequence` |

@example Sample lines testing [read-toml](sinter:#read-toml=v1) on valid
and invalid signed 64-bit integer boundaries under
[toml-reading-rule](sinter:#toml-reading-rule=v1),
[toml-document](sinter:#toml-document=v1), and
[root-table](sinter:#root-table=v1):

```json
{"form":"#toml-document-vector=v1","group":"give-root-table","input":"61203d202d393232333337323033363835343737353830380a","note":"minimum signed 64-bit integer (-2^63)","result":"valid","values":{"root-table":{"a":{"integer":"-9223372036854775808"}}}}
{"form":"#toml-document-vector=v1","group":"reject-byte-sequence","input":"61203d20393232333337323033363835343737353830380a","note":"integer above the signed 64-bit maximum (2^63)","result":"invalid","values":{}}
```

#### TOML span vectors

@schema toml-span-vector=v1
@cites {
    toml-lang/1.1.0,
    text#{byte-sequence=v1, line=v1, position=v1, span=v1},
    #{
        index=v1, hex-text=v1, json-value=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1, toml-key=v1, toml-value=v1,
        toml-document=v1, root-table=v1, toml-location=v1, toml-span=v1,
        read-toml=v1, give-toml-spans=v1,
    },
}

`toml-span-vector` is a group schema for groups `give-span` and
`omit-span` of specification `toml` and tests `read-toml` and
`give-toml-spans`. Each line is a `vector-line` whose meaning follows
`vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input` | string | valid `toml-document` `byte-sequence` as its `hex-text` |
| `result` | string | `"valid"` |
| `values.of` | string (`give-span`) | span target kind: `"toml-value"` for the value at `location`, `"key"` for the TOML 1.1.0 key leading to `location`, or `"toml-key"` for the `index`-th `toml-key` of that key |
| `values.location` | array (`give-span`) | `toml-location` as an array of key-text strings and 1-based `index` integers (`[]` for `root-table`) |
| `values.index` | integer (`give-span`, optional) | 1-based `index` of the `toml-key` within the key; present only when `values.of` is `"toml-key"` |
| `values.start.line` | integer (`give-span`, `>= 1`) | 1-based `line` number of the `span` start `position` |
| `values.start.column` | integer (`give-span`, `>= 1`) | 1-based column of the `span` start `position` |
| `values.end.line` | integer (`give-span`, `>= 1`) | 1-based `line` number of the `span` end `position` |
| `values.end.column` | integer (`give-span`, `>= 1`) | 1-based column of the `span` end `position` |
| `values.no-span-at` | array (`omit-span`) | `toml-location` (same array form as `values.location`) at which the document has no value span |

Each `give-span` vector checks only the start and end positions of the
named `toml-span` and states nothing about other spans of the document.
Each `omit-span` vector checks that no value span appears at
`values.no-span-at`.

@example Sample lines testing [read-toml](sinter:#read-toml=v1) and
[give-toml-spans](sinter:#give-toml-spans=v1) with
[toml-span](sinter:#toml-span=v1) and
[toml-location](sinter:#toml-location=v1):

```json
{"form":"#toml-span-vector=v1","group":"give-span","input":"5b2061202e202262206322205d0a","note":"the text of the span is `\"b c\"`","result":"valid","values":{"end":{"column":12,"line":1},"index":2,"location":["a","b c"],"of":"toml-key","start":{"column":7,"line":1}}}
{"form":"#toml-span-vector=v1","group":"omit-span","input":"5b615d0a62203d20310a","note":"a table header makes the table `a`","result":"valid","values":{"no-span-at":["a"]}}
```

## Hashes
@spec hashes=v1

SHA-256 maps any byte sequence to a fixed-length cryptographic digest. A
hash writes that 32-byte digest as hex text.

### Definitions

#### Hash

@term hash=v1
@cites {fips/180-4, text#byte-sequence=v1, #hex-text=v1}

The **hash** of a byte sequence is the hex text of the 32-byte message
digest that SHA-256 (FIPS 180-4) produces for that byte sequence.

#### Hash form

@term hash-form=v1
@cites text#{text=v1, production=v1, hex-digit=v1}

A text **matches the hash form** when the text matches the production
`hash-form`:

```abnf
hash-form  = 64hex-digit
```

@example The [text](sinter:text#text=v1)
`ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` matches
the hash form.
`BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD` does not
match the hash form because uppercase letters are not
[hex digits](sinter:text#hex-digit=v1).

### Computing a hash

@req compute-hash=v1
@cites {
    conformance#conforming-program=v1,
    text#byte-sequence=v1,
    #hash=v1,
}

When a conforming program computes the hash of a byte sequence, the
program must return the hash of that byte sequence.

### Validating a hash

@req validate-hash=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    #hash-form=v1,
}

When a conforming program validates whether a text matches the hash form,
the program must return `"valid"` when the text matches the hash form, and
must return `"invalid"` otherwise.

### Test vectors

The file
[`data-forms.hashes.test-vectors.jsonl`](data-forms.hashes.test-vectors.jsonl)
holds the test vectors of `hashes`. Neither group uses `needs`.

#### Hash computation vectors

@schema compute-hash-vector=v1
@cites {
    text#byte-sequence=v1,
    #{
        compute-hash=v1, hash=v1, hex-text=v1, json-value=v1,
        vector-line=v1, group-schema=v1, vector-meaning=v1,
    },
}

`compute-hash-vector` is a group schema for group `compute` of
specification `hashes` and tests `compute-hash`. Each line is a
`vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input` | string | input `byte-sequence` encoded as its `hex-text` (`""` for empty) |
| `values.hash` | string | expected `hash` of the input byte sequence |

@example Sample lines testing [compute-hash](sinter:#compute-hash=v1) on
[byte-sequence](sinter:text#byte-sequence=v1) inputs encoded as
[hex-text](sinter:#hex-text=v1), producing each expected
[hash](sinter:#hash=v1):

```json
{"form":"#compute-hash-vector=v1","group":"compute","input":"","values":{"hash":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}}
{"form":"#compute-hash-vector=v1","group":"compute","input":"616263","values":{"hash":"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"}}
```

#### Hash validation vectors

@schema validate-hash-vector=v1
@cites {
    text#text=v1,
    #{
        validate-hash=v1, hash-form=v1, json-value=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1,
    },
}

`validate-hash-vector` is a group schema for group `validate` of
specification `hashes` and tests `validate-hash`. Each line is a
`vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input` | string | `text` to validate |
| `result` | string | `"valid"` when `input` matches the hash form, `"invalid"` otherwise |

@example Sample lines testing [validate-hash](sinter:#validate-hash=v1)
against [hash-form](sinter:#hash-form=v1) on valid and invalid
[text](sinter:text#text=v1) inputs:

```json
{"form":"#validate-hash-vector=v1","group":"validate","input":"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad","result":"valid"}
{"form":"#validate-hash-vector=v1","group":"validate","input":"BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD","note":"uppercase letters are not hex digits","result":"invalid"}
```

## Hash IDs
@spec hash-ids=v1

A hash ID combines an ID prefix ending in a colon with leading hex digits
from the SHA-256 hash of a byte sequence. Prefixes such as `req:` and
`task-def:` label distinct kinds of hash IDs.

### Definitions

#### ID prefix

@term id-prefix=v1
@cites text#{text=v1, production=v1}

An **ID prefix** is a text that matches the production `id-prefix`:

```abnf
id-prefix  = 1*%x61-7A *( "-" 1*%x61-7A ) ":"
```

#### Hash ID

@term hash-id=v1
@cites {
    text#{byte-sequence=v1, character=v1, text=v1, slice=v1},
    #{id-prefix=v1, hash=v1},
}

For an ID prefix `p`, an integer `k` from 1 to 64, and a byte sequence
`b`, the **hash ID** of `b` with `p` and `k` is the text that joins `p`
and the text of the slice `(0, k)` of the hash of `b` (the first `k`
characters of that hash).

@example For the [byte sequence](sinter:text#byte-sequence=v1)
`0x61, 0x62, 0x63` (`abc`), the [hash](sinter:#hash=v1) is
`ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`. With
the [ID prefix](sinter:#id-prefix=v1) `req:` and `k = 32`, the hash ID
is `req:ba7816bf8f01cfea414140de5dae2223`
([slice](sinter:text#slice=v1) `(0, 32)`). With the ID prefix
`task-def:` and `k = 12`, the same byte sequence produces
`task-def:ba7816bf8f01` from the same hash.

#### Hash-id form

@term hash-id-form=v1
@cites {text#{text=v1, hex-digit=v1}, #id-prefix=v1}

For an ID prefix `p` and an integer `k` from 1 to 64, a text `t`
**matches the hash-id form** with `p` and `k` when `t` consists of `p`
followed by exactly `k` hex digits.

### Computing a hash ID

@req compute-hash-id=v1
@cites {
    conformance#conforming-program=v1,
    text#byte-sequence=v1,
    #{id-prefix=v1, hash-id=v1},
}

When a conforming program computes the hash ID of a byte sequence `b`
with an ID prefix `p` and an integer `k` from 1 to 64, the program must
return the hash ID of `b` with `p` and `k`.

### Validating a hash ID

@req validate-hash-id=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    #{id-prefix=v1, hash-id-form=v1},
}

When a conforming program validates whether a text `t` matches the
hash-id form with an ID prefix `p` and an integer `k` from 1 to 64, the
program must return `"valid"` when `t` matches the hash-id form with `p`
and `k`, and must return `"invalid"` otherwise.

### Test vectors

The file
[`data-forms.hash-ids.test-vectors.jsonl`](data-forms.hash-ids.test-vectors.jsonl)
holds the test vectors of `hash-ids`. Neither group uses `needs`.

#### Hash ID computation vectors

@schema compute-hash-id-vector=v1
@cites {
    text#{byte-sequence=v1, hex-digit=v1},
    #{
        vector-line=v1, group-schema=v1, vector-meaning=v1, json-value=v1,
        hex-text=v1, compute-hash-id=v1, id-prefix=v1, hash-id=v1,
    },
}

`compute-hash-id-vector` is a group schema for group `compute` of
specification `hash-ids` and tests `compute-hash-id`. Each line is a
`vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.byte-sequence` | string | `byte-sequence` encoded as its `hex-text` (`""` for empty) |
| `input.id-prefix` | string | `id-prefix` |
| `input.number-of-hex-digits` | integer (`1` to `64`) | number of `hex-digit` characters `k` |
| `values.hash-id` | string | expected `hash-id` of `input.byte-sequence` with `input.id-prefix` and `input.number-of-hex-digits` |

@example Sample line testing
[compute-hash-id](sinter:#compute-hash-id=v1) with
[byte-sequence](sinter:text#byte-sequence=v1),
[hex-text](sinter:#hex-text=v1), [id-prefix](sinter:#id-prefix=v1), and
[hash-id](sinter:#hash-id=v1):

```json
{"form":"#compute-hash-id-vector=v1","group":"compute","input":{"byte-sequence":"616263","id-prefix":"req:","number-of-hex-digits":32},"values":{"hash-id":"req:ba7816bf8f01cfea414140de5dae2223"}}
```

#### Hash ID validation vectors

@schema validate-hash-id-vector=v1
@cites {
    text#{text=v1, hex-digit=v1},
    #{
        vector-line=v1, group-schema=v1, vector-meaning=v1, json-value=v1,
        validate-hash-id=v1, id-prefix=v1, hash-id-form=v1,
    },
}

`validate-hash-id-vector` is a group schema for group `validate` of
specification `hash-ids` and tests `validate-hash-id`. Each line is a
`vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.id-prefix` | string | `id-prefix` |
| `input.number-of-hex-digits` | integer (`1` to `64`) | number of `hex-digit` characters `k` |
| `input.text` | string | `text` to validate |
| `result` | string | `"valid"` when `input.text` matches the hash-id form with `input.id-prefix` and `input.number-of-hex-digits`; `"invalid"` otherwise |

@example Sample lines testing
[validate-hash-id](sinter:#validate-hash-id=v1) with
[id-prefix](sinter:#id-prefix=v1) and
[hash-id-form](sinter:#hash-id-form=v1):

```json
{"form":"#validate-hash-id-vector=v1","group":"validate","input":{"id-prefix":"req:","number-of-hex-digits":12,"text":"req:5b1c0a9d2e11"},"result":"valid"}
{"form":"#validate-hash-id-vector=v1","group":"validate","input":{"id-prefix":"req:","number-of-hex-digits":12,"text":"req:5b1c0a9d2e1"},"note":"11 hex digits","result":"invalid"}
```
