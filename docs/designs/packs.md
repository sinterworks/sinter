<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Language packs
@design packs=v1
@cites {
    conformance=v1, text=v1, identifiers=v1, files=v1, data-forms=v1,
    ontology=v1, rfc/5234, rfc/7405, posix/2024,
    tree-sitter/language-format, tree-sitter/abi-versions,
    tree-sitter/query-language, wasm-core/2.0, ecma/262-2025,
}
A language pack supplies the descriptor, directory layout, compiled
tree-sitter grammars, query files, and WebAssembly runner adapters that
a conforming program uses to validate packs, parse source files, and
call test-runner adapters in isolation.

Each pack is a directory tree that holds the files supporting one
programming language: a TOML descriptor in `pack.toml`, license texts,
compiled WebAssembly tree-sitter grammars, tree-sitter query files for
comments, definitions, and tests, and optional WebAssembly runner
adapters. File listings and SHA-256 pack hashes identify a pack's
content. Parsing selects a file's grammar from the descriptor, builds a
parse tree, and runs the grammar's queries to extract comments,
definitions, decorations, and tests. A runner adapter recognizes a test
runner's report files and binds reported test results to test entries
through JSON requests and responses in linear memory.

## Definitions

### WebAssembly module

@term webassembly-module=v1
@cites {wasm-core/2.0, text#byte-sequence=v1}

A **WebAssembly module** is a `byte-sequence` that is a module in the
binary format of the WebAssembly Core Specification 2.0 and is valid
under that specification.

## Descriptor

@spec descriptor=v1

A pack descriptor is a UTF-8 TOML document that identifies a pack and
declares its comment sigils, foreign tag words, grammars with file-name
globs, and test runners with default runner settings. Reading a
descriptor validates that document and decodes its entries, and
file-grammar lookup selects the grammar for a valid path.

### Parameters

@schema runner-settings=v1
@cites {
    ontology#parameter=v1,
    data-forms#toml-value=v1,
    text#text=v1,
    #{valid-descriptor=v1, test-runner=v1, runner-setting=v1},
}

A binding of the `parameter` `runner-settings` supplies values for the
runner settings of one `test-runner` of a `valid-descriptor`. A binding
is a finite set of pairs, each pairing a setting name (a `text`) with a
`toml-value`. A binding can be empty.

A binding meets the schema `runner-settings` for a `test-runner` of a
`valid-descriptor` when all of these conditions hold:

- The name of each pair is the name of a `runner-setting` of that test
  runner.
- No two pairs in the binding have the same name.
- For each pair, the `toml-value` has the kind for the type of the
  `runner-setting` with that name: a TOML string for type string, a TOML
  boolean for type boolean, or a TOML array of TOML strings for type
  array of strings.

Otherwise, the binding does not meet the schema `runner-settings` and is
invalid.

### Definitions

#### Grammar name

@term grammar-name=v1
@cites text#{text=v1, production=v1}

A **grammar name** is a `text` that matches the `production`
`grammar-name`:

```abnf
grammar-name  = %x61-7A *( %x61-7A / DIGIT / "_" )
```

#### Valid descriptor

@schema valid-descriptor=v1
@cites {
    data-forms#{
        toml-document=v1, root-table=v1, toml-value=v1, hash-form=v1,
    },
    files#glob=v1,
    text#{
        byte-sequence=v1, text=v1, production=v1, decimal-numeral=v1,
    },
    #grammar-name=v1,
}

These `production` rules define the text forms used inside a descriptor:

```abnf
pack-name       = %x61-7A *( %x61-7A / DIGIT )
                  *( "-" 1*( %x61-7A / DIGIT ) )
release-number  = decimal-numeral "." decimal-numeral "." decimal-numeral
spec-version    = decimal-numeral "." decimal-numeral
foreign-tag     = 1*( ALPHA / DIGIT / "-" )
```

A **valid descriptor** is a `byte-sequence` that matches `toml-document`
and whose `root-table` holds only the keys in this table, with every
required key present and every value meeting its rule:

| key | presence | TOML value rule |
|---|---|---|
| `sinter-spec` | required | TOML string matching `spec-version` |
| `name` | required | TOML string matching `pack-name` |
| `version` | required | TOML string matching `release-number` |
| `license` | required | any TOML string |
| `name-separator` | required | non-empty TOML string |
| `comments` | required | table meeting the `comments` rules |
| `grammar` | required | non-empty TOML array of tables meeting the `grammar` rules |
| `foreign-tags` | optional | TOML array of TOML strings, each matching `foreign-tag` |
| `runner` | optional | table meeting the `runner` rules |

The nested tables meet these rules:

- **`comments`:** holds only the optional keys `line` (TOML array of
  TOML strings), `block` (TOML array of TOML arrays, each of exactly two
  TOML strings), and `inner` (TOML array of TOML strings).
- **`grammar`:** each element is a table holding only the required keys
  `name` (TOML string matching `grammar-name`), `sha256` (TOML string
  matching `hash-form`), `license` (any TOML string), and `names` (TOML
  array of TOML strings, each a valid `glob`). No two grammar tables
  hold the same `name` text.
- **`runner`:** every key text held by `runner` matches `pack-name` and
  maps to a runner table. Each runner table holds exactly one of
  `adapter` or `match`, optionally `settings`, and no other key:
  - `adapter` is a table holding only the required keys `sha256` (TOML
    string matching `hash-form`) and `license` (any TOML string).
  - `match` is any table, with no rule on its keys or values.
  - `settings` is a table whose every value is a TOML string, a TOML
    boolean, or a TOML array of TOML strings.

For a valid descriptor, its **spec version** is the text of
`sinter-spec`, its **name** is the text of `name`, its **release
number** is the text of `version`, its **license** is the text of
`license`, and its **name separator** is the text of `name-separator`.
The spec version names the oldest version of the Sinter specifications
that the pack needs. The license names the license of the descriptor and
the query files. The name separator joins names into one text.

@example A valid descriptor
([toml-document](sinter:data-forms#toml-document=v1)) with two
grammars—each with a [grammar name](sinter:#grammar-name=v1), a hash
matching the [hash form](sinter:data-forms#hash-form=v1), and
[globs](sinter:files#glob=v1)—and one `match` test runner:

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
recognize = ["testsuites@name=vitest tests"]
```

#### Comment sigil

@term comment-sigil=v1
@cites {
    data-forms#{root-table=v1, toml-value=v1},
    text#{text=v1, line=v1},
    #valid-descriptor=v1,
}

A **comment sigil** of a `valid-descriptor` is a `text` (which can be
empty) that opens a comment, closes a comment, or starts a later `line`
of a block comment. The table `comments` in the `root-table` of a valid
descriptor defines three ordered sequences of comment sigils (each
sequence is empty when its key is absent from `comments`):

- **Line sigils** (from `line`): the texts of the TOML strings in
  `line`, in array order. Each line sigil, such as `//`, opens a comment
  that ends at the end of its `line`.
- **Block pairs** (from `block`): one pair per inner TOML array in
  `block`, in array order. Each block pair holds an **opening sigil**
  (the text of the first TOML string) and a **closing sigil** (the text
  of the second TOML string), such as `/*` and `*/`.
- **Inner sigils** (from `inner`): the texts of the TOML strings in
  `inner`, in array order. Each inner sigil, such as `*`, can start a
  `line` of a block comment after its first `line`.

#### Foreign tag word

@term foreign-tag-word=v1
@cites {
    identifiers#tag-word=v1,
    data-forms#{root-table=v1, toml-value=v1},
    text#{text=v1, production=v1},
    #valid-descriptor=v1,
}

When the `root-table` of a `valid-descriptor` holds `foreign-tags`, the
**foreign tag words** of that descriptor are, for each TOML string in
`foreign-tags` in array order, the `text` `@` followed by the text of
that TOML string. Each foreign tag word matches the `production`
`tag-word` and names a tag word, such as `@param`, that the pack's
language or its tools use in comments with a meaning of their own. When
the `root-table` does not hold `foreign-tags`, the descriptor has no
foreign tag words.

#### Descriptor grammar

@term descriptor-grammar=v1
@cites {
    data-forms#{root-table=v1, toml-value=v1},
    text#text=v1,
    #valid-descriptor=v1,
}

The **grammars** of a `valid-descriptor` are one **descriptor grammar**
for each table in the TOML array `grammar` of its `root-table`, in
array order. Each descriptor grammar has four values from its table:

- **name**: the `text` of `name`;
- **hash**: the `text` of `sha256`;
- **license**: the `text` of `license`; and
- **file-name globs**: the texts of the TOML strings in `names`, in
  array order (each element is a **file-name glob** of that grammar).

#### Test runner

@term test-runner=v1
@cites {
    ontology#{test=v1, test-evidence=v1},
    data-forms#{root-table=v1, toml-value=v1},
    text#text=v1,
    #valid-descriptor=v1,
}

A **test runner**, such as vitest, is a program that runs `test`s,
produces a test result (`test-evidence`) for each test that it runs,
and writes report files.

When the `root-table` of a `valid-descriptor` holds `runner`, the
descriptor has one **test runner** for each key text held by `runner`,
with that key `text` as its **name** and its paired TOML table as the
**table of that test runner**. When `runner` is absent from the
`root-table`, the descriptor has no test runners. From its table, a
test runner has one of these two configurations:

- When the table holds `adapter`, the test runner has an **adapter
  hash** (the text of `sha256` in `adapter`) and an **adapter license**
  (the text of `license` in `adapter`), and no match table.
- When the table holds `match`, the test runner has a **match table**
  (the table of `match`), and no adapter hash or adapter license.

#### Runner setting

@term runner-setting=v1
@cites {
    data-forms#{toml-key=v1, toml-value=v1},
    text#text=v1,
    #{valid-descriptor=v1, test-runner=v1},
}

A **runner setting** of a `test-runner` pairs a **name** (a `text`)
with a **default value** (a `toml-value`) for a configurable setting of
that test runner.

When the table of a `test-runner` of a `valid-descriptor` holds
`settings`, the test runner has one runner setting for each entry of
`settings`: its **name** is the text of that entry's `toml-key`, and
its **default value** is that entry's paired `toml-value`. When
`settings` is absent from the test runner's table, the test runner has
no runner settings. The **type** of a runner setting is:

- **string** when its default value is a TOML string;
- **boolean** when its default value is a TOML boolean; or
- **array of strings** when its default value is a TOML array.

#### Runner-setting value

@term runner-setting-value=v1
@cites {
    ontology#parameter=v1,
    data-forms#toml-value=v1,
    #{
        runner-settings=v1, valid-descriptor=v1, test-runner=v1,
        runner-setting=v1,
    },
}

Under a valid binding of the `parameter` `runner-settings` for a
`test-runner` of a `valid-descriptor`, the **value** of a
`runner-setting` of that test runner is:

- the `toml-value` paired with that runner setting's name in the
  binding, when the binding holds a pair with that name; or
- the default value of that runner setting, when the binding holds no
  pair with that name (including when the binding is empty).

#### File grammar

@term file-grammar=v1
@cites {
    files#{path=v1, glob-match=v1},
    #{valid-descriptor=v1, descriptor-grammar=v1},
}

For a `valid-descriptor` and a valid `path`, the **file grammar** of
that valid path is the first `descriptor-grammar`, in the order of the
descriptor's grammars, that has a file-name glob that the last path
segment of the valid path, as a one-segment valid `path`, matches under
`glob-match`. When no grammar of the descriptor has such a file-name
glob, that valid path has no file grammar.

@example Under [glob-match](sinter:files#glob-match=v1), file-grammar
lookup matches each file-name glob against only the last path segment of
a valid [path](sinter:files#path=v1) as a one-segment valid path:

- For `src/a.x`, the file-name glob `src/*.x` does not match the
  one-segment valid path `a.x`, whereas `**/a.x` matches `a.x` (a
  non-final `**` matches zero path segments).
- When two grammars
  ([descriptor-grammar](sinter:#descriptor-grammar=v1)) list `["*"]`
  first and `["*.x"]` second, the file grammar of `a.x` is the first
  grammar.

### Reading descriptors

@req read-descriptor=v1
@cites {
    conformance#conforming-program=v1,
    data-forms#{toml-value=v1, toml-value-equality=v1},
    text#byte-sequence=v1,
    #{
        valid-descriptor=v1, comment-sigil=v1, foreign-tag-word=v1,
        descriptor-grammar=v1, test-runner=v1, runner-setting=v1,
    },
}

When a conforming program reads a `byte-sequence` as a descriptor:

- When the `byte-sequence` is a `valid-descriptor`, the program must
  return `"valid"` and the values defined by that valid descriptor:
  - its spec version, name, release number, license, and name separator;
  - its foreign tag words (`foreign-tag-word`), in order;
  - its line sigils, block pairs, and inner sigils (`comment-sigil`),
    each in order;
  - its grammars (`descriptor-grammar`), in order, each with its name,
    hash, license, and file-name globs in order; and
  - its test runners (`test-runner`), each with its name, its runner
    settings (`runner-setting`), and its adapter or match values:
    - for each runner setting, its name and its default value as a
      `toml-value` equal under `toml-value-equality`;
    - when the test runner has an adapter hash, its adapter hash and
      adapter license (and neither when it has no adapter hash); and
    - when the test runner has a match table, its match table as a table
      equal under `toml-value-equality` (and no match table when it has
      none).
- When the `byte-sequence` is not a `valid-descriptor`, the program must
  return `"invalid"` and none of those descriptor, grammar, test-runner,
  or runner-setting values.

### Returning file grammars

@req give-file-grammars=v1
@cites {
    conformance#conforming-program=v1,
    files#path=v1,
    #{valid-descriptor=v1, descriptor-grammar=v1, file-grammar=v1},
}

When a conforming program looks up the `file-grammar` of a valid `path`
for a `valid-descriptor`, the program must return that `file-grammar`
when the valid path has one, and must return no `descriptor-grammar`
otherwise.

### Test vectors

The file
[`packs.descriptor.test-vectors.jsonl`](packs.descriptor.test-vectors.jsonl)
holds the test vectors of `descriptor`. Neither group uses `needs`.

#### Descriptor vectors

@schema descriptor-vector=v1
@cites {
    data-forms#{
        index=v1, hex-text=v1, json-value=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1, toml-key=v1, toml-value=v1,
        toml-reading-rule=v1, toml-value-equality=v1,
    },
    text#{
        byte-sequence=v1, text=v1, code-point-order=v1,
        decimal-numeral=v1,
    },
    #{
        valid-descriptor=v1, comment-sigil=v1, foreign-tag-word=v1,
        descriptor-grammar=v1, test-runner=v1, runner-setting=v1,
        read-descriptor=v1,
    },
}

`descriptor-vector` is a `group-schema` for group `descriptors` of
specification `descriptor` and tests `read-descriptor`. Each line is a
`vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input` | string | input `byte-sequence`, encoded as `hex-text` (`""` for empty) |
| `result` | string | `"valid"` when `input` is a `valid-descriptor`, `"invalid"` otherwise |
| `values.spec-version` | string (optional) | spec version when `result` is `"valid"`; absent (`values` is `{}`) when `result` is `"invalid"` |
| `values.name` | string (optional) | descriptor name when `result` is `"valid"` |
| `values.release` | string (optional) | release number when `result` is `"valid"` |
| `values.license` | string (optional) | descriptor license when `result` is `"valid"` |
| `values.name-separator` | string (optional) | name separator when `result` is `"valid"` |
| `values.foreign-tag-words[]` | string (optional) | `foreign-tag-word` values in order when `result` is `"valid"` (`[]` when none) |
| `values.line-sigils[]` | string (optional) | line sigils (`comment-sigil`) in order when `result` is `"valid"` (`[]` when none) |
| `values.block-pairs[]` | 2-element array of strings (optional) | block pairs (`[opening sigil, closing sigil]`) in order when `result` is `"valid"` (`[]` when none) |
| `values.inner-sigils[]` | string (optional) | inner sigils (`comment-sigil`) in order when `result` is `"valid"` (`[]` when none) |
| `values.grammars[].name` | string (optional) | `descriptor-grammar` name, grammars in array order, when `result` is `"valid"` |
| `values.grammars[].hash` | string (optional) | `descriptor-grammar` hash when `result` is `"valid"` |
| `values.grammars[].license` | string (optional) | `descriptor-grammar` license when `result` is `"valid"` |
| `values.grammars[].globs[]` | string (optional) | `descriptor-grammar` file-name globs in order when `result` is `"valid"` |
| `values.runners[].name` | string (optional) | `test-runner` name, with `runners` sorted in `code-point-order` of `name`, when `result` is `"valid"` |
| `values.runners[].adapter-hash` | string (optional) | adapter hash when the `test-runner` has an adapter; absent otherwise (no adapter hash returned) |
| `values.runners[].adapter-license` | string (optional) | adapter license when the `test-runner` has an adapter; absent otherwise (no adapter license returned) |
| `values.runners[].match` | object (optional) | JSON form of the match table (`{"table": ...}`) when the `test-runner` has a match table; absent otherwise (no match table returned) |
| `values.runners[].settings[].name` | string (optional) | `runner-setting` name, with `settings` sorted in `code-point-order` of `name`, when `result` is `"valid"` |
| `values.runners[].settings[].default` | object (optional) | JSON form of the `runner-setting` default value (`toml-value`) when `result` is `"valid"` |

When `result` is `"valid"`, `values` holds all eleven top-level fields
(`spec-version`, `name`, `release`, `license`, `name-separator`,
`foreign-tag-words`, `line-sigils`, `block-pairs`, `inner-sigils`,
`grammars`, and `runners`), with `runners` equal to `[]` when the
descriptor has no test runners. Each runner object holds `name`,
`settings` (`[]` when that test runner has no runner settings), and
either `adapter-hash` with `adapter-license` or `match`. When `result`
is `"invalid"`, `values` is `{}` (no descriptor, grammar, test-runner,
or runner-setting value is returned). A vector check compares the
elements of `runners`, and of each runner's `settings`, as sets.

In `values.runners[].match` and `values.runners[].settings[].default`,
each `toml-value` appears as a single-member JSON object, and a table
appears as a JSON object mapping each held `toml-key` text to the JSON
form of its paired `toml-value`:

| TOML value kind | member key | member value |
|---|---|---|
| TOML string | `string` | the `text` as a JSON string |
| TOML integer | `integer` | JSON string with `-` (when negative) followed by the `decimal-numeral` of its absolute value |
| TOML float | `float` | JSON string: `"nan"`, `"inf"`, `"-inf"`, `"-0"`, or `-` when negative, then the `decimal-numeral` of the integer part of its absolute value, then (when the absolute value is not an integer) `.` followed by the exact base-10 fractional digits of the IEEE 754-2019 `binary64` value with no trailing `0` |
| TOML boolean | `boolean` | `true` or `false` |
| local date | `local-date` | `"YYYY-MM-DD"` (four year digits, `-`, two month digits, `-`, two day digits) |
| local time | `local-time` | `"HH:MM:SS"` (two digits each), plus `.` and base-10 fractional digits with no trailing `0` when the fraction is nonzero |
| local date-time | `local-date-time` | local date string, `T`, and local time string |
| offset date-time | `offset-date-time` | local date-time string plus offset string: `"+00:00"` for offset 0 minutes, `"-00:00"` for the unknown local offset under `toml-reading-rule`, or `+` for a positive offset or `-` for a negative offset, then the two-digit integer quotient of the absolute offset divided by 60, `:`, and the two-digit remainder |
| TOML array | `array` | JSON array of the JSON forms of its elements in 1-based `index` order |
| table | `table` | JSON object mapping each held `toml-key` text to the JSON form of its paired `toml-value` |

Two TOML values or tables are equal under `toml-value-equality` when
their JSON forms are the same `json-value`.

@example Sample lines testing
[read-descriptor](sinter:#read-descriptor=v1) on a
[valid-descriptor](sinter:#valid-descriptor=v1) with both `match` and
`adapter` [test runners](sinter:#test-runner=v1) and
[runner settings](sinter:#runner-setting=v1), and on an invalid
descriptor encoded as [hex-text](sinter:data-forms#hex-text=v1):

```json
{"form":"#descriptor-vector=v1","group":"descriptors","input":"73696e7465722d73706563203d2022312e30220a6e616d65203d202278220a76657273696f6e203d2022302e312e30220a6c6963656e7365203d20224d4954220a6e616d652d736570617261746f72203d20223a3a220a0a5b636f6d6d656e74735d0a0a5b5b6772616d6d61725d5d0a6e616d65203d202278220a736861323536203d202230303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030220a6c6963656e7365203d20224d4954220a6e616d6573203d205b222a2e78225d0a0a5b72756e6e65722e6e6578746573745d0a61646170746572203d207b20736861323536203d202230303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030222c206c6963656e7365203d20224170616368652d322e30204f52204d495422207d0a73657474696e6773203d207b20737472696374203d2066616c73652c2064697273203d205b5d2c20746167203d20227422207d0a0a5b72756e6e65722e636172676f2d746573745d0a6d61746368203d207b20736570617261746f72203d20223a3a22207d0a","note":"two runners, in the code point order of their names in values","result":"valid","values":{"block-pairs":[],"foreign-tag-words":[],"grammars":[{"globs":["*.x"],"hash":"0000000000000000000000000000000000000000000000000000000000000000","license":"MIT","name":"x"}],"inner-sigils":[],"license":"MIT","line-sigils":[],"name":"x","name-separator":"::","release":"0.1.0","runners":[{"match":{"table":{"separator":{"string":"::"}}},"name":"cargo-test","settings":[]},{"adapter-hash":"0000000000000000000000000000000000000000000000000000000000000000","adapter-license":"Apache-2.0 OR MIT","name":"nextest","settings":[{"default":{"array":[]},"name":"dirs"},{"default":{"boolean":false},"name":"strict"},{"default":{"string":"t"},"name":"tag"}]}],"spec-version":"1.0"}}
{"form":"#descriptor-vector=v1","group":"descriptors","input":"73696e7465722d73706563203d2022312e30220a6e616d65203d202278220a76657273696f6e203d2022302e312e30220a6c6963656e7365203d20224d4954220a6e616d652d736570617261746f72203d20223a3a220a0a6772616d6d6172203d205b5d0a0a5b636f6d6d656e74735d0a0a","note":"the array grammar of the root table holds one or more tables","result":"invalid","values":{}}
```

#### File-grammar vectors

@schema file-grammar-vector=v1
@cites {
    data-forms#{
        hex-text=v1, json-value=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    files#path=v1,
    text#{byte-sequence=v1, text=v1},
    #{
        valid-descriptor=v1, descriptor-grammar=v1, file-grammar=v1,
        give-file-grammars=v1,
    },
}

`file-grammar-vector` is a `group-schema` for group `file-grammars` of
specification `descriptor` and tests `give-file-grammars`. Each line is
a `vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.descriptor` | string | `byte-sequence` of a `valid-descriptor`, encoded as `hex-text` |
| `input.path` | string | valid `path` (`text`) |
| `values.grammar` | string (optional) | name of the `file-grammar` (`descriptor-grammar`) of `input.path`; absent (`values` is `{}`) when `input.path` has no file grammar (no grammar returned) |

@example Sample lines testing
[give-file-grammars](sinter:#give-file-grammars=v1) for a matched
[file-grammar](sinter:#file-grammar=v1) and an unmatched valid
[path](sinter:files#path=v1) against a
[valid-descriptor](sinter:#valid-descriptor=v1) encoded as
[hex-text](sinter:data-forms#hex-text=v1):

```json
{"form":"#file-grammar-vector=v1","group":"file-grammars","input":{"descriptor":"73696e7465722d73706563203d2022312e30220a6e616d65203d202278220a76657273696f6e203d2022302e312e30220a6c6963656e7365203d20224d4954220a6e616d652d736570617261746f72203d20223a3a220a0a5b636f6d6d656e74735d0a0a5b5b6772616d6d61725d5d0a6e616d65203d202278220a736861323536203d202230303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030220a6c6963656e7365203d20224d4954220a6e616d6573203d205b224d616b6566696c65225d0a","path":"sub/Makefile"},"values":{"grammar":"x"}}
{"form":"#file-grammar-vector=v1","group":"file-grammars","input":{"descriptor":"73696e7465722d73706563203d2022312e30220a6e616d65203d202278220a76657273696f6e203d2022302e312e30220a6c6963656e7365203d20224d4954220a6e616d652d736570617261746f72203d20222e220a5b636f6d6d656e74735d0a5b5b6772616d6d61725d5d0a6e616d65203d202278220a736861323536203d202230303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030220a6c6963656e7365203d20224d4954220a6e616d6573203d205b22612a61225d0a","path":"a"},"note":"the characters before and after * do not overlap","values":{}}
```

## Pack files

@spec pack-files=v1

A pack is a directory tree that holds the files that support one
programming language, such as a descriptor, grammars, queries, adapters,
and license texts. What a conforming program returns while another
process modifies a pack directory tree is a matter of quality of
implementation; the safety obligations still hold.

### Definitions

#### Pack

@term pack=v1
@cites {
    files#{
        directory-tree=v1, file-kind=v1, path=v1, path-resolution=v1,
    },
    text#text=v1,
}

A **pack** is a `directory-tree`. A **file of a pack** consists of a
valid `path` and a content. For each valid `path` whose last path
segment names a regular file (`file-kind`) in the pack's
`directory-tree` under `path-resolution`, the pack has one file with
that valid path and the content of that regular file, and no other
files. For a `text` `p`, a pack **has the file `p`** when the pack has a
file whose valid path is `p`.

#### Well-named pack

@term well-named-pack=v1
@cites {
    files#{directory=v1, directory-tree=v1, file-kind=v1, path=v1},
    text#{
        character=v1, text=v1, slice=v1, utf-8-encoding=v1,
        production=v1,
    },
    #pack=v1,
}

A **pack path** is a `text` that matches the `production` `pack-path`:

```abnf
pack-path       = pack-path-name *( "/" pack-path-name )
pack-path-name  = *"." pack-path-char *( pack-path-char / "." ) / 3*"."
pack-path-char  = %x20-2D / %x30-5B / %x5D-7E
```

The **paths of a pack** are the valid paths of the pack's files together
with the text of every `slice` `(0, k - 1)` of one of those valid paths
where 1-based character index `k` holds `/`. **ASCII case folding**
replaces each `character` of a `text` whose code point is from 65 to 90
(`A` to `Z`) with the character whose code point is 32 greater (`a` to
`z`), leaving every other character unchanged.

A `pack` is **well named** when all three of these conditions hold:

- For every directory entry of the root or of any `directory` of the
  pack's `directory-tree`, if the file of that directory entry is a
  regular file (`file-kind`) or is a `directory` that is the root of a
  `directory-tree` containing at least one regular file, that directory
  entry's entry name is the `utf-8-encoding` of a `text` that matches
  the `path-segment` production of `files#path`.
- The valid path of every file of the pack is a pack path.
- No two distinct paths of the pack produce equal texts after ASCII case
  folding.

Otherwise, the pack is **not well named**.

@example A [pack](sinter:#pack=v1) holding `queries/rust/tags.scm` and
`queries/Rust/tests.scm` is not well named: its paths include the
directory prefixes `queries/rust` and `queries/Rust`, which fold to the
same [text](sinter:text#text=v1) under ASCII case folding. Likewise, a
pack holding a [regular file](sinter:files#file-kind=v1) `A` and a
[directory](sinter:files#directory=v1) `a` containing `b` is not well
named: `A` and `a` fold to the same text. By contrast, an empty
directory or a symbolic link named `é` leads to no regular file and does
not prevent a pack from being well named.

#### Pack hash

@term pack-hash=v1
@cites {
    data-forms#hash=v1,
    files#path=v1,
    text#{
        character=v1, text=v1, code-point-order=v1, utf-8-encoding=v1,
    },
    #{pack=v1, well-named-pack=v1},
}

The **pack listing** of a well-named `pack` is the `text` formed by
concatenating, for each file of the pack in `code-point-order` of the
files' valid `path` values, the `hash` of the file's content, two spaces
(U+0020), the valid path of the file, and one line feed (U+000A).

The **pack hash** of a well-named pack is the `hash` of the
`utf-8-encoding` of its pack listing. A pack that is not well named has
no pack listing and no pack hash.

### Deciding whether packs are well named

@req decide-well-named-packs=v1
@cites {
    conformance#conforming-program=v1,
    #{pack=v1, well-named-pack=v1},
}

When a conforming program decides whether a `pack` is well named, the
program must return `"well named"` when the pack is well named, and must
return `"not well named"` otherwise.

### Returning pack files and contents

@req give-pack-files=v1
@cites {
    conformance#conforming-program=v1,
    files#path=v1,
    text#byte-sequence=v1,
    #{pack=v1, well-named-pack=v1},
}

When a conforming program returns the valid paths of the files of a
well-named `pack`, the program must return the valid `path` of every
file of the pack, with no missing or extra paths. When a conforming
program returns the content of a file of a `pack`, the program must
return the content `byte-sequence` of that file.

### Computing pack hashes

@req compute-pack-hashes=v1
@cites {
    conformance#conforming-program=v1,
    #{pack=v1, well-named-pack=v1, pack-hash=v1},
}

When a conforming program computes the pack listing of a `pack`, the
program must return the pack listing (`pack-hash`) when the pack is well
named, and must return no pack listing otherwise. When a conforming
program computes the pack hash of a `pack`, the program must return the
pack hash (`pack-hash`) when the pack is well named, and must return no
pack hash otherwise.

### Following no pack symbolic links

@req follow-no-pack-links=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#{directory-tree=v1, file-kind=v1},
    #pack=v1,
}

In any operation that reads a directory tree as a `pack`, a conforming
program must never follow a symbolic link (`file-kind`) of that
`directory-tree` or resolve any file through a symbolic link's
reference.

### Reading only pack directories and regular files

@req read-only-pack-files=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#{directory=v1, directory-tree=v1, file-kind=v1, read-byte=v1},
    #pack=v1,
}

In any operation that reads a directory tree as a `pack`, a conforming
program must read bytes (`read-byte`) from files of that
`directory-tree` only when those files are directories (`directory`) or
regular files (`file-kind`), and must never block on a file of another
kind in that directory tree to wait for another process or a device
(such as for a process to open the other end of a FIFO special file).

### Keeping packs unchanged

@req keep-packs-unchanged=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#directory-tree=v1,
    #pack=v1,
}

In any operation that reads a directory tree as a `pack`, a conforming
program must never modify any file of that `directory-tree`, apart from
automatic metadata updates that the file system makes on its own when
the program accesses that file, such as an update to the time of last
access.

### Gaining no pack privileges

@req gain-no-pack-privileges=v1
@cites {
    posix/2024,
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#directory-tree=v1,
    #pack=v1,
}

In any operation that reads a directory tree as a `pack`, a conforming
program must use only the POSIX.1-2024 permissions and appropriate
privileges that its process holds without a change by the program.

### Test vectors

The file
[`packs.pack-files.test-vectors.jsonl`](packs.pack-files.test-vectors.jsonl)
holds the test vectors of `pack-files`.

#### Well-named pack vectors

@schema well-named-pack-vector=v1
@cites {
    posix/2024,
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    files#{directory=v1, directory-tree=v1, directory-tree-object=v1},
    text#valid-utf-8=v1,
    #{pack=v1, well-named-pack=v1, decide-well-named-packs=v1},
}

`well-named-pack-vector` is a group schema (`group-schema`) for group
`well-named-packs` of specification `pack-files` and tests
`decide-well-named-packs`. Each line is a `vector-line` whose meaning
follows `vector-meaning`. The requirement binds when a file system
stores the `directory-tree` of `input` for the program's process
(`directory-tree-object`) from the start through the end of the
operation with no concurrent modification.

| field | type | meaning |
|---|---|---|
| `input` | `directory-tree-object` | stored `directory-tree` of the `pack`, with no `read`, `search`, `write`, or `owned-by-other` member on any file object |
| `result` | string | `"well named"` when the pack is a `well-named-pack`, `"not well named"` otherwise |
| `needs` | array of strings (optional) | applicable need names for this group (present when one or more apply) |

Group `well-named-packs` uses these four need names:

| need | environment condition | when a vector carries this need |
|---|---|---|
| `case-distinct-names` | The file system treats two entry names in one `directory` that differ only in ASCII letter case as distinct files. | One `directory` in `input` holds two entry names differing only in ASCII letter case. |
| `names-kept` | The file system keeps every `valid-utf-8` entry name of `input` byte for byte. | An entry name in `input` is `valid-utf-8` and holds a byte `>= 0x80`. |
| `non-portable-names` | The file system permits creating every entry name of `input`. | An entry name in `input` holds a byte `< 0x80` outside the POSIX.1-2024 portable filename character set (`A`–`Z`, `a`–`z`, `0`–`9`, `.`, `_`, `-`). |
| `non-utf-8-names` | The file system keeps every non-UTF-8 entry name of `input` byte for byte. | An entry name in `input` is not `valid-utf-8`. |

@example Sample lines testing
[decide-well-named-packs](sinter:#decide-well-named-packs=v1) and
[well-named-pack](sinter:#well-named-pack=v1) on
[directory-tree-object](sinter:files#directory-tree-object=v1) inputs:

```json
{"form":"#well-named-pack-vector=v1","group":"well-named-packs","input":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"7061636b2e746f6d6c"}],"type":"directory"},"result":"well named"}
{"form":"#well-named-pack-vector=v1","group":"well-named-packs","input":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"524541444d452e6d64"},{"file":{"content":[],"type":"regular file"},"name":"726561646d652e6d64"}],"type":"directory"},"needs":["case-distinct-names"],"note":"two files whose paths are the same text after ASCII case folding","result":"not well named"}
```

#### Pack hash vectors

@schema pack-hash-vector=v1
@cites {
    posix/2024,
    data-forms#{
        group-schema=v1, hash-form=v1, vector-line=v1,
        vector-meaning=v1,
    },
    files#{
        directory=v1, directory-tree=v1, directory-tree-object=v1,
        path=v1,
    },
    text#code-point-order=v1,
    #{
        pack=v1, well-named-pack=v1, pack-hash=v1, give-pack-files=v1,
        compute-pack-hashes=v1,
    },
}

`pack-hash-vector` is a group schema (`group-schema`) for group
`pack-hashes` of specification `pack-files` and tests `give-pack-files`
and `compute-pack-hashes`. Each line is a `vector-line` whose meaning
follows `vector-meaning`. The requirements bind when a file system
stores the `directory-tree` of `input` for the program's process
(`directory-tree-object`) from the start through the end of the
operation with no concurrent modification.

| field | type | meaning |
|---|---|---|
| `input` | `directory-tree-object` | stored `directory-tree` of the `pack`, with no `read`, `search`, `write`, or `owned-by-other` member on any file object |
| `values.files` | array of strings (optional) | valid `path` values of the pack's files in `code-point-order` when the pack is well named (the array order is canonical to the vector, not an output-order obligation); absent when the pack is not well named; the vector then states nothing about file paths |
| `values.hash` | string (optional) | expected `pack-hash` (matching the hash form of `hash-form`) when the pack is well named; absent (`values` is `{}`) when the pack is not well named (no pack hash returned) |
| `values.listing` | string (optional) | expected pack listing (`pack-hash`) when the pack is well named; absent (`values` is `{}`) when the pack is not well named (no pack listing returned) |
| `needs` | array of strings (optional) | applicable need names for this group (present when one or more apply) |

In `values`, either all three of `files`, `hash`, and `listing` are
present together (when the pack is well named), or `values` is `{}`
(when the pack is not well named).

Group `pack-hashes` uses these two need names:

| need | environment condition | when a vector carries this need |
|---|---|---|
| `case-distinct-names` | The file system treats two entry names in one `directory` that differ only in ASCII letter case as distinct files. | One `directory` in `input` holds two entry names differing only in ASCII letter case. |
| `non-portable-names` | The file system permits creating every entry name of `input`. | An entry name in `input` holds a byte `< 0x80` outside the POSIX.1-2024 portable filename character set (`A`–`Z`, `a`–`z`, `0`–`9`, `.`, `_`, `-`). |

@example Sample lines testing
[give-pack-files](sinter:#give-pack-files=v1) and
[compute-pack-hashes](sinter:#compute-pack-hashes=v1) with
[pack-hash](sinter:#pack-hash=v1) on
[directory-tree-object](sinter:files#directory-tree-object=v1) inputs:

```json
{"form":"#pack-hash-vector=v1","group":"pack-hashes","input":{"entries":[{"file":{"content":[{"bytes":"610a","times":1}],"type":"regular file"},"name":"7061636b2e746f6d6c"}],"type":"directory"},"note":"the pack listing is the hash of the content, two spaces, pack.toml, and a line feed","values":{"files":["pack.toml"],"hash":"beaeab094a1c0fc028e5e9c88d867c74e190c2cdbe3f6753a6a413588b45a070","listing":"87428fc522803d31065e7bce3cf03fe475096631e5e07bbd7a0fde60c4cf25c7  pack.toml\n"}}
{"form":"#pack-hash-vector=v1","group":"pack-hashes","input":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"524541444d452e6d64"},{"file":{"content":[],"type":"regular file"},"name":"726561646d652e6d64"}],"type":"directory"},"needs":["case-distinct-names"],"note":"a pack that is not well named has no pack hash","values":{}}
```

## Grammars and parsing

@spec parsing=v1

A pack bundles compiled tree-sitter WebAssembly grammars and tree-sitter
query files for one programming language. Parsing a file selects its
grammar from the pack descriptor, builds a parse tree, and runs the
grammar's queries to extract comments, definitions, decorations, and
tests.

### Definitions

#### Usable grammar

@term usable-grammar=v1
@cites {
    tree-sitter/language-format, tree-sitter/abi-versions,
    wasm-core/2.0,
    text#{byte-sequence=v1, valid-utf-8=v1, text=v1},
    #{webassembly-module=v1, grammar-name=v1},
}

This definition uses the tree-sitter language format
(`tree-sitter/language-format`) at ABI versions 13 to 15
(`tree-sitter/abi-versions`). In that format, a language has an **ABI
version** (a non-negative integer), **symbols** (all entries of its
symbol table, including aliases), and **fields**. Each symbol has a
**name** (a `byte-sequence`) and is named or anonymous, visible or
hidden, and a supertype or not. Each field has a **name** (a
`byte-sequence`). At ABI version 15, each supertype also has a list of
**subtypes** (symbols).

A `byte-sequence` is a **usable grammar** with a `grammar-name` `g`
when all three of these conditions hold:

1. The byte sequence is a `webassembly-module`.
2. The module produces a language of an ABI version from 13 to 15 from
   its export `tree_sitter_<g>` (the text `tree_sitter_` followed by
   `g`), as the tree-sitter language format defines.
3. The name of every symbol of that language is `valid-utf-8`.

The **language** of that usable grammar with grammar name `g` is that
language, and its **ABI version** is the ABI version of that language.

#### Parse tree

@term parse-tree=v1
@cites {
    tree-sitter/language-format, wasm-core/2.0,
    text#{
        character=v1, text=v1, slice=v1, body=v1, byte-sequence=v1,
        utf-8-text=v1, utf-8-encoding=v1,
    },
    #{webassembly-module=v1, usable-grammar=v1, grammar-name=v1},
}

Tree-sitter parsing (`tree-sitter/language-format`) takes a language
and a `byte-sequence` and produces either a tree of nodes or no result.
Parsing runs the language's code inside the instance of the
`webassembly-module` from which that module produced that language.
Parsing produces no result when module instantiation or an invocation in
that instance fails, or when a WebAssembly trap occurs in any
WebAssembly instance running code for that parsing (such as the
grammar's instance or an instance running tree-sitter parsing code).

Each resulting tree of nodes has a **root node**. The **children** of a
node are its named and anonymous child nodes in order. Nodes of hidden
symbols are excluded from the tree, with their children standing in
their place. Each node has a **symbol**, a **start byte**, and an **end
byte** (non-negative integers). The **node type** of a node in a parse
tree is the `utf-8-text` of its symbol's name.

An **`ERROR` node** is a node whose symbol is `ERROR`. A **`MISSING`
node** is a node inserted by parsing for a token missing from the text.
A node **has an error** when that node, or any node produced by parsing
inside that node (including nodes of hidden symbols), is an `ERROR`
node or a `MISSING` node.

The **parse text** of a `text` is that text when it ends with a line
feed (`U+000A`), or that text followed by a line feed (`U+000A`)
otherwise.

For a `text` `t` and a `usable-grammar` with `grammar-name` `g`, let
`b` be the start boundary of the `body` of `t`, and let `l` be the last
boundary of `t`. The tree of nodes produced by parsing the
`utf-8-encoding` of the parse text of `t` with the language of that
usable grammar (with nodes of hidden symbols excluded and their
children standing in their place) is the **parse tree** of `t` with
that usable grammar when all four of these conditions hold:

1. For every node, its start byte equals the number of bytes in the
   `utf-8-encoding` of the text of the `slice` `(0, s)` of the parse
   text for some boundary `s` of the parse text, and its end byte
   equals the number of bytes in the `utf-8-encoding` of the text of
   the `slice` `(0, e)` of the parse text for some boundary `e` of the
   parse text.
2. For every node, its start byte is less than or equal to its end
   byte.
3. For every node and each child of that node, the child's slice in `t`
   starts at or after the start boundary of the parent node's slice in
   `t`, and ends at or before the end boundary of the parent node's
   slice in `t`.
4. For every node and any two children of that node where the first
   precedes the second in child order, the first child's slice in `t`
   ends at or before the start boundary of the second child's slice in
   `t`.

For any node satisfying conditions 1 and 2, the **slice of that node in
`t`** is the `slice` `(max(b, min(s, l)), max(b, min(e, l)))` of `t`,
where `s` and `e` are the boundaries of the parse text identified by
condition 1 for that node's start byte and end byte. When parsing
produces no result or produces a tree of nodes that breaks any of these
four conditions, `t` has **no parse tree** with that usable grammar.

#### Parse-tree order

@term parse-tree-order=v1
@cites #parse-tree=v1

The **nodes** of a `parse-tree` are its root node and recursively every
child of every node of that parse tree. The **descendants** of a node
are its children and recursively the descendants of its children.

In **parse-tree order**:

- Each node comes before every one of its descendants.
- For any two children of one node where the first precedes the second
  in child order, the first child and each of its descendants come
  before the second child and each of the second child's descendants.

#### Node slice

@term node-slice=v1
@cites {text#{text=v1, slice=v1}, #parse-tree=v1}

The **node slice** of a node in a `parse-tree` of a `text` is the
`slice` of that node in that text defined by `parse-tree`.

#### Query language

@term query-language=v1
@cites {tree-sitter/query-language, text#text=v1, #parse-tree=v1}

The **query language** is the query language defined by
`tree-sitter/query-language`. A **query** for a language is a `text`
that is a valid query for that language under
`tree-sitter/query-language`. A query is a sequence of zero or more
**patterns**. A pattern captures nodes under **capture names**, each
written `@` followed by the capture name.

Each capture name has one of five **quantifiers** in a pattern, each
standing for a set of non-negative integers: `zero` (`{0}`), `zero or
one` (`{0, 1}`), `zero or more` (every non-negative integer), `one`
(`{1}`), and `one or more` (every integer `>= 1`). The **quantifier**
of a capture name in a pattern is the quantifier whose set is the
smallest set containing every count of nodes that the pattern can
capture under that capture name across all choices of alternatives in
alternations and all repetition counts allowed by `?`, `*`, and `+`. A
capture name written after a quantified element—before or after its
`?`, `*`, or `+`—captures the node of each repetition of that element.

The **matches** of a query over a `parse-tree` are the parts of that
parse tree where a pattern of the query matches under
`tree-sitter/query-language`, each carrying its pattern and the nodes
captured under each capture name.

#### Text predicate

@term text-predicate=v1
@cites {
    ecma/262-2025,
    data-forms#{index=v1, key-order=v1},
    text#{text=v1, slice=v1},
    #{query-language=v1, parse-tree-order=v1, node-slice=v1},
}

The **text predicates** are ten predicates of the `query-language`. The
**text of a node** is the text of its `node-slice`.

| predicates | arguments | pair condition |
|---|---|---|
| `#eq?`, `#any-eq?` | capture, then capture or string | the node's text equals the string or partner node's text |
| `#not-eq?`, `#any-not-eq?` | capture, then capture or string | the node's text does not equal the string or partner node's text |
| `#match?`, `#any-match?` | capture, then string (valid ECMA-262 2025 RegExp pattern with flag `u`) | an ECMA-262 2025 RegExp for the pattern with flag `u` and no other flag matches the node's text |
| `#not-match?`, `#any-not-match?` | capture, then string (valid ECMA-262 2025 RegExp pattern with flag `u`) | that RegExp finds no match in the node's text |
| `#any-of?` | capture, then one or more strings | the node's text equals at least one of the argument strings |
| `#not-any-of?` | capture, then one or more strings | the node's text equals none of the argument strings |

In a match, pairing works as follows:

- When the second argument is a string (or strings, for `#any-of?` and
  `#not-any-of?`), each node captured under the first capture pairs
  with that string or those strings.
- When the second argument is a capture, the nodes captured under the
  first capture and the nodes captured under the second capture are
  each ordered in `parse-tree-order`, and each node pairs with the node
  at the same 1-based `index` in the other sequence. Any node with no
  partner at its index is not compared.

For `#match?`, `#not-match?`, `#any-match?`, and `#any-not-match?`, the
RegExp searches the node's entire text—represented as an ECMA-262 2025
String holding the UTF-16 code-unit sequence (`key-order`) of that
text—starting at index 0, as `RegExp.prototype.test` of ECMA-262 2025
defines. Character classes in the pattern (such as `\w`) match as
ECMA-262 2025 defines.

In a match:

- `#eq?`, `#not-eq?`, `#match?`, `#not-match?`, `#any-of?`, and
  `#not-any-of?` hold when the pair condition holds for every pair (and
  therefore hold when there are zero pairs).
- `#any-eq?`, `#any-not-eq?`, `#any-match?`, and `#any-not-match?` hold
  when the pair condition holds for at least one pair.

#### Query file

@term query-file=v1
@cites {
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-text=v1, text=v1,
        production=v1,
    },
    #{
        grammar-name=v1, usable-grammar=v1, query-language=v1,
        text-predicate=v1,
    },
}

A **query file** has one of three kinds, each with its **role names**
and **other capture names**:

| kind | role names | other capture names |
|---|---|---|
| `comment` | `comment`, `untagged` | none |
| `definition` | `definition`, `decoration` | `name`, `body` |
| `test` | `case`, `suite` | `name`, `placeholder`, and any `text` matching `label-capture` |

```abnf
label-capture  = %s"label." label-word
label-word     = %x61-7A *( %x61-7A / DIGIT / "-" )
```

A `byte-sequence` is a **valid query file** of a kind for a
`usable-grammar` with `grammar-name` `g` when all five of these
conditions hold:

1. The byte sequence is `valid-utf-8`.
2. Its `utf-8-text` is a query of the `query-language` for the language
   of that usable grammar.
3. Every predicate and every directive in every pattern of the query is
   a `text-predicate` with valid arguments for its name.
4. Every capture name in the query that does not start with `_` is a
   role name or another capture name of that kind.
5. In every pattern of the query, the capture-name quantifiers
   (treating any capture name absent from the pattern as having
   quantifier `zero`) satisfy the rule for that kind:
   - `comment`: one of `comment` and `untagged` has quantifier `one`,
     and the other has quantifier `zero`.
   - `definition`: either `definition` has quantifier `one`,
     `decoration` has quantifier `zero`, and `name` and `body` each
     have quantifier `zero`, `zero or one`, or `one`; or `decoration`
     has quantifier `one`, and `definition`, `name`, and `body` each
     have quantifier `zero`.
   - `test`: one of `case` and `suite` has quantifier `one`, and the
     other has quantifier `zero`.

@example Two valid query files of the
[query-language](sinter:#query-language=v1); the OCaml file uses the
[text-predicate](sinter:#text-predicate=v1) `#match?`. This `comment`
query file for OCaml marks doc comments `(** *)` as `untagged` and
plain comments as `comment`:

```scheme
((comment) @untagged (#match? @untagged "^\\(\\*\\*[^*]"))
(comment) @comment
```

This `definition` query file for Rust captures function definitions
with `name` and `body` and attributes as `decoration`:

```scheme
(function_item name: (identifier) @name body: (block) @body) @definition
(attribute_item) @decoration
```

#### Valid pack

@schema valid-pack=v1
@cites {
    files#{directory=v1, directory-tree=v1, file-kind=v1, path=v1},
    data-forms#hash=v1,
    text#text=v1,
    #{
        pack=v1, well-named-pack=v1, valid-descriptor=v1,
        grammar-name=v1, descriptor-grammar=v1, test-runner=v1,
        usable-grammar=v1, query-file=v1,
    },
}

In this schema, for a `text` `g`, `grammars/<g>.wasm`,
`queries/<g>/tags.scm`, `queries/<g>/definitions.scm`, and
`queries/<g>/tests.scm` denote the paths formed by substituting `g` for
`<g>`; for a `text` `r`, `adapters/<r>.wasm` denotes the path formed by
substituting `r` for `<r>`.

A `pack` is a **valid pack** when all six of these conditions hold:

1. Every file in the pack's `directory-tree` other than the root is a
   `directory` or a regular file (`file-kind`).
2. The pack is a `well-named-pack`.
3. The pack has the file `pack.toml`, and its content is a
   `valid-descriptor`.
4. For every grammar (`descriptor-grammar`) of that valid descriptor,
   with `grammar-name` `g`:
   - The pack has `grammars/<g>.wasm`, the `hash` of its content equals
     that grammar's hash, and its content is a `usable-grammar` with
     grammar name `g`.
   - The pack has `queries/<g>/tags.scm`, and its content is a valid
     `query-file` of kind `comment` for that usable grammar.
   - When the pack has `queries/<g>/definitions.scm`, its content is a
     valid `query-file` of kind `definition` for that usable grammar.
   - When the pack has `queries/<g>/tests.scm`, its content is a valid
     `query-file` of kind `test` for that usable grammar.
5. For every `test-runner` of that valid descriptor that has an adapter
   hash, with name `r`, the pack has `adapters/<r>.wasm`, and the
   `hash` of its content equals that adapter hash.
6. The pack has at least one file whose valid `path` starts with
   `licenses/`.

For a valid pack:

- Its **descriptor** is the `valid-descriptor` in `pack.toml`.
- For each grammar of its descriptor with name `g`: its **usable
  grammar** is `grammars/<g>.wasm` as a `usable-grammar` with grammar
  name `g`; its **language** is the language of that usable grammar;
  its **query file of kind `comment`** is the content of
  `queries/<g>/tags.scm`; its **query file of kind `definition`** is
  the content of `queries/<g>/definitions.scm` when present (otherwise
  that grammar has no query file of kind `definition`); and its **query
  file of kind `test`** is the content of `queries/<g>/tests.scm` when
  present (otherwise that grammar has no query file of kind `test`).
- For each `test-runner` of its descriptor with an adapter hash and
  name `r`, the **adapter** of that test runner is the content of
  `adapters/<r>.wasm`.

#### Joined match

@term joined-match=v1
@cites {
    text#text=v1,
    #{
        usable-grammar=v1, grammar-name=v1, query-language=v1,
        query-file=v1, text-predicate=v1, parse-tree=v1,
        parse-tree-order=v1,
    },
}

For a valid `query-file` of a kind for a `usable-grammar` with
`grammar-name` `g`, and a `text` that has a `parse-tree` with that
usable grammar whose root node has no error, the **query matches** are
the matches of the query (ignoring predicates under `query-language`)
over that parse tree in which every `text-predicate` of the match's
pattern holds. Each query match comes from one pattern of the query;
pattern `A` **comes before** pattern `B` when `A` precedes `B` in the
query file. The **captures** of a query match are its captures whose
capture names do not start with `_`, each pairing a capture name with a
node of the parse tree.

Every query match of a valid query file has exactly one capture whose
capture name is a role name of that query file's kind. That capture
name is the **role name** of the query match, and that captured node is
the **role node** of the query match.

All query matches of one query file over one text that share the same
pattern, the same role name, and the same role node form one **joined
match** with that pattern, role name, and role node. For each capture
name, the joined match holds every node captured under that capture
name by its constituent query matches, each node once, in
`parse-tree-order`.

The **kept matches** of a query file over a text are the joined matches
of that query file over that text whose pattern comes before the
pattern of every other joined match of that query file over that text
with the same role name and the same role node.

#### Comment node

@term comment-node=v1
@cites {
    text#text=v1,
    #{
        usable-grammar=v1, query-file=v1, valid-pack=v1,
        descriptor-grammar=v1, parse-tree=v1, parse-tree-order=v1,
        joined-match=v1,
    },
}

For a `valid-pack`, a `descriptor-grammar` of its descriptor, and a
`text` that has a `parse-tree` with that grammar's `usable-grammar`
whose root node has no error, the **comment nodes** of the text are the
role nodes of the kept matches (`joined-match`) of that grammar's
`query-file` of kind `comment` over the text, each node once, in
`parse-tree-order`.

A comment node is **tagged** when it is the role node of a kept match
with role name `comment` and of no kept match with role name
`untagged`. A comment node that is not tagged remains a comment node.

#### Definition node

@term definition-node=v1
@cites {
    text#text=v1,
    #{
        usable-grammar=v1, query-file=v1, valid-pack=v1,
        descriptor-grammar=v1, parse-tree=v1, parse-tree-order=v1,
        joined-match=v1,
    },
}

For a `valid-pack`, a `descriptor-grammar` of its descriptor, and a
`text` that has a `parse-tree` with that grammar's `usable-grammar`
whose root node has no error:

- When that grammar has no `query-file` of kind `definition`, the text
  has no definition nodes.
- When that grammar has a `query-file` of kind `definition`, the
  **definition nodes** of the text are the role nodes of the kept
  matches (`joined-match`) with role name `definition` of that query
  file over the text, in `parse-tree-order`.
- The **name nodes** of a definition node are the nodes captured under
  `name` by its kept match with role name `definition`, in
  `parse-tree-order`.
- The **body nodes** of a definition node are the nodes captured under
  `body` by that kept match, in `parse-tree-order`, or the single-node
  sequence holding the definition node itself when that kept match
  captures no node under `body`.

#### Decoration node

@term decoration-node=v1
@cites {
    text#text=v1,
    #{
        usable-grammar=v1, query-file=v1, valid-pack=v1,
        descriptor-grammar=v1, parse-tree=v1, parse-tree-order=v1,
        joined-match=v1,
    },
}

For a `valid-pack`, a `descriptor-grammar` of its descriptor, and a
`text` that has a `parse-tree` with that grammar's `usable-grammar`
whose root node has no error, the **decoration nodes** of the text are
the role nodes of the kept matches (`joined-match`) with role name
`decoration` of that grammar's `query-file` of kind `definition` over
the text, in `parse-tree-order`. When that grammar has no `query-file`
of kind `definition`, the text has no decoration nodes.

#### Enclosed node

@term enclosed-node=v1
@cites {
    text#slice=v1,
    #{parse-tree=v1, parse-tree-order=v1, node-slice=v1},
}

In a `parse-tree` of a text, a node `A` **encloses** a distinct node
`B` (and `B` is an **enclosed node** of `A`) when all three of these
conditions hold:

1. The `node-slice` of `A` starts at or before the start boundary of
   the `node-slice` of `B`.
2. The `node-slice` of `A` ends at or after the end boundary of the
   `node-slice` of `B`.
3. `B` does not precede `A` in `parse-tree-order`.

#### Test node

@term test-node=v1
@cites {
    ontology#test=v1,
    files#path=v1,
    text#text=v1,
    #{
        usable-grammar=v1, query-file=v1, valid-pack=v1,
        descriptor-grammar=v1, parse-tree=v1, parse-tree-order=v1,
        joined-match=v1, enclosed-node=v1,
    },
}

For a `valid-pack`, a `descriptor-grammar` of its descriptor, and a
`text` (taken as the text of a file at a valid `path`) that has a
`parse-tree` with that grammar's `usable-grammar` whose root node has
no error:

- When that grammar has no `query-file` of kind `test`, the text has no
  test nodes.
- When that grammar has a `query-file` of kind `test`, the **test
  nodes** of the text are the role nodes of the kept matches
  (`joined-match`) of that query file over the text, each node once, in
  `parse-tree-order`. Under that query file, each test node represents
  the code of one `test` of the file at that valid path (its **test**):
  one unit for a test case, or a group of units under one name for a
  test suite.
- The **kept matches of a test node** are the kept matches whose role
  node is that test node.
- A test node is a **test suite** when either one of its kept matches
  has role name `suite`, or that test node encloses (`enclosed-node`) a
  test node that has a kept match with role name `case`. Every other
  test node is a **test case**.
- The **test suites that enclose** a test node are the test nodes that
  are test suites and enclose that test node, in `parse-tree-order`.

#### Test name

@term test-name=v1
@cites {
    ontology#test=v1,
    text#{text=v1, slice=v1},
    data-forms#index=v1,
    #{
        joined-match=v1, parse-tree=v1, parse-tree-order=v1,
        node-slice=v1, enclosed-node=v1, test-node=v1, test-runner=v1,
    },
}

A **piece** is either a **text piece** or a **placeholder**, and holds
a `text`. A text piece stands for its text literally as written in the
file, with no quote removal or escape decoding. A placeholder stands
for text that a `test-runner` inserts into a `test`'s name when running
that test (which can be any text, including the empty text).

The **own name** of a `test-node` is a sequence of pieces containing
one piece for each node captured under `name` or `placeholder` by any
of that test node's kept matches (`joined-match`), each node once, in
`parse-tree-order`. A node captured under `placeholder` by any of those
kept matches produces a placeholder; every other such node produces a
text piece. Each piece's text is the text of its node's `node-slice`.

The **name path** of a test node is the sequence of the own names of
the test suites that enclose (`enclosed-node`) that test node, in
`parse-tree-order`, followed by the own name of that test node. Under
the test query file, the name path is the name of the test node's
`test` as written in code.

Two name paths are **equal** when they have the same number of own
names, each pair of own names at the same `index` has the same number
of pieces, and each pair of pieces at the same `index` within those own
names has the same kind (both text pieces or both placeholders) and
equal `text`.

@example With this `test` [query-file](sinter:#query-file=v1) for
vitest in TypeScript (using
[text-predicate](sinter:#text-predicate=v1) `#any-of?` and `#eq?`):

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
    (template_string [(string_fragment) @name
                      (escape_sequence) @placeholder
                      (template_substitution) @placeholder]*))
  (#any-of? @_fn "it" "test")) @case

(call_expression
  function: [(identifier) @_fn
             (member_expression object: (identifier) @_fn)]
  arguments: (arguments .
    (string [(string_fragment) @name (escape_sequence) @placeholder]*))
  (#eq? @_fn "describe")) @suite
```

For the source text ``describe("math", () => { it(`adds ${n}`, () =>
{}) })``, the outer call is a test suite
([test-node](sinter:#test-node=v1)) whose own name is the single text
piece `math` (from its [node-slice](sinter:#node-slice=v1)). The inner
call is a test case enclosed ([enclosed-node](sinter:#enclosed-node=v1))
by that suite, and its own name consists of the text piece `adds `
followed by the placeholder `${n}`. The test case's name path consists
of the suite's own name followed by the test case's own name.

#### Test label

@term test-label=v1
@cites {
    text#{text=v1, production=v1},
    #{query-file=v1, joined-match=v1, test-node=v1},
}

The **test labels** of a `test-node` are the set of `text` values `w`
matching the `production` `label-word` (`query-file`) such that at
least one kept match (`joined-match`) of that test node captures a node
under the capture name `label.` followed by `w`.

#### Parse result

@atom parse-result=v1
@cites {
    files#path=v1,
    text#text=v1,
    #{
        grammar-name=v1, valid-pack=v1, descriptor-grammar=v1,
        file-grammar=v1, usable-grammar=v1, parse-tree=v1,
    },
}

A `text` has a **parse failure** with a `usable-grammar` when the text
has no `parse-tree` with that usable grammar, or when the root node of
its `parse-tree` with that usable grammar has an error.

For a `text` (taken as the text of a file at a valid `path` `p`) and a
`valid-pack`, let `g` be the `file-grammar` of `p` for the pack's
descriptor when `p` has one. The **parse result** of that text at `p`
with that valid pack is one of three outcomes:

1. `"no grammar"` when `p` has no `file-grammar` for the pack's
   descriptor;
2. `"parse failure"` when `p` has a `file-grammar` `g` and the text has
   a parse failure with the `usable-grammar` of `g` (with `g`'s
   `grammar-name`);
3. `"parsed"` otherwise.

#### File parse

@term file-parse=v1
@cites {
    files#path=v1,
    text#text=v1,
    #{
        valid-pack=v1, descriptor-grammar=v1, file-grammar=v1,
        parse-tree=v1, node-slice=v1, comment-node=v1,
        definition-node=v1, decoration-node=v1, test-node=v1,
        test-name=v1, test-label=v1, parse-result=v1,
    },
}

The **file parse** of a `text` (taken as the text of a file at a valid
`path` `p`) with a `valid-pack` has the `parse-result` of that text at
`p` with that valid pack.

When that `parse-result` is `"parsed"` (with `file-grammar` `g` of `p`
for the pack's descriptor), the file parse contains these extracted
nodes of the text for `g`, each with its `node-slice` and its node type
(`parse-tree`):

- the comment nodes (`comment-node`), each with whether it is tagged;
- the definition nodes (`definition-node`), each with its name nodes
  and its body nodes, and each name node and body node with its
  `node-slice` and its node type;
- the decoration nodes (`decoration-node`);
- the test nodes (`test-node`), each with whether it is a test case or
  a test suite, its name path (`test-name`), and its test labels
  (`test-label`).

When the `parse-result` is `"no grammar"` or `"parse failure"`, the
file parse contains no nodes.

### Validating packs

@req validate-packs=v1
@cites {
    wasm-core/2.0,
    conformance#conforming-program=v1,
    #{
        pack=v1, valid-pack=v1, descriptor-grammar=v1,
        webassembly-module=v1, usable-grammar=v1, query-language=v1,
        query-file=v1, parse-tree=v1,
    },
}

When a conforming program validates a `pack`, the program must return
`"invalid"` when the pack is not a `valid-pack`, and must return
`"valid"` when the pack is a `valid-pack`, except that the program may
return `"invalid"` for a `valid-pack` in either of these two cases:

- The `usable-grammar` of a `descriptor-grammar` of the pack's
  descriptor is a `webassembly-module` declaring a WebAssembly import
  (`wasm-core/2.0`) that the program does not provide.
- A `query-file` of a `descriptor-grammar` of the pack's descriptor
  holds a pattern that, ignoring its predicates (`query-language`),
  matches no part of any `parse-tree` that the language of that grammar
  can produce.

### Parsing files

@req parse-files=v1
@cites {
    conformance#conforming-program=v1,
    files#path=v1,
    text#text=v1,
    #{
        pack=v1, valid-pack=v1, parse-tree=v1, node-slice=v1,
        comment-node=v1, definition-node=v1, decoration-node=v1,
        test-node=v1, test-name=v1, test-label=v1, parse-result=v1,
        file-parse=v1,
    },
}

When a conforming program parses a `text` as the text of a file at a
valid `path` with a `pack`:

- If the pack is not a `valid-pack`, the program must return no
  `parse-result` and no nodes.
- If the pack is a `valid-pack`, the program must return the
  `parse-result` of the `file-parse` (`"no grammar"`, `"parse failure"`,
  or `"parsed"`).
- When the `parse-result` is `"parsed"` and the program returns the
  comment nodes, definition nodes, decoration nodes, or test nodes of
  the `file-parse`, the program must return each node of that kind once,
  with no missing or extra nodes. For any node attribute that the
  program returns—its `node-slice`, its node type (`parse-tree`),
  whether a `comment-node` is tagged, the name nodes and body nodes of
  a `definition-node` (each with its `node-slice` and node type),
  whether a `test-node` is a test case or a test suite, its name path
  (`test-name`), or its test labels (`test-label`)—the program must
  return the exact value defined by the `file-parse`.
- When the `parse-result` is `"no grammar"` or `"parse failure"`, the
  program must return no comment node, definition node, decoration
  node, or test node.

### Isolating grammars

@req isolate-grammars=v1
@cites {
    wasm-core/2.0,
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#read-byte=v1,
    text#byte-sequence=v1,
    #{webassembly-module=v1, usable-grammar=v1, parse-tree=v1},
}

A conforming program must run the code of every `byte-sequence` used as
a grammar (`usable-grammar`) only inside an instance of its
`webassembly-module` (`wasm-core/2.0`). A conforming program must
prevent that code and its language from reading bytes from a file
(`read-byte`), writing to a file or process output, using a network,
reading a clock, or starting a process. A conforming program must also
prevent that code and any import function provided to that instance from
reading or modifying any memory byte, table element, or global value of
any other WebAssembly instance, other than an instance that runs code
for the same parsing (`parse-tree`) as that code.

### Ending parses

@req end-parses=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    text#{byte-sequence=v1, text=v1},
    #{pack=v1, valid-pack=v1, usable-grammar=v1, file-parse=v1},
}

A conforming program must end every validation of a `pack` against
`valid-pack`, every `file-parse` of a `text` with a `pack`, and every
execution of the code of a `byte-sequence` used as a grammar
(`usable-grammar`).

### Test vectors

@schema invalid-pack-vector=v1
@cites {
    files#{directory=v1, directory-tree=v1, directory-tree-object=v1},
    data-forms#{
        vector-line=v1, test-vector-set=v1, group-schema=v1,
        vector-meaning=v1,
    },
    #{pack=v1, valid-pack=v1, validate-packs=v1},
}

`invalid-pack-vector` is a `group-schema` for group `invalid-packs` of
specification `parsing` and tests `validate-packs`. The file
[`packs.parsing.test-vectors.jsonl`](packs.parsing.test-vectors.jsonl)
holds this group as a `test-vector-set` of `vector-line` entries whose
meaning follows `vector-meaning`.

No file object in `input` has `read`, `search`, `write`, or
`owned-by-other`. The requirement `validate-packs` obliges `result`
under both of these conditions:

- A file system stores the `directory-tree` of `input` for the program's
  process (`directory-tree-object`) from the start through the end of
  the validation.
- No other process modifies the directory tree during the validation.

| field | type | meaning |
|---|---|---|
| `input` | `directory-tree-object` | stored `directory-tree` of the input `pack`, omitting permission and ownership fields |
| `result` | string | `"valid"` or `"invalid"`, answering whether `input` is a `valid-pack` under `validate-packs` |
| `needs` | array of strings (optional) | need names from the needs table for this group |

Only this need name is valid in `needs` for group `invalid-packs`:

| need | environment condition | when a vector carries this need |
|---|---|---|
| `case-distinct-names` | The file system treats two entry names in one `directory` that differ only in ASCII letter case as distinct files. | One `directory` in `input` holds two entry names differing only in ASCII letter case. |

@example Sample lines testing
[validate-packs](sinter:#validate-packs=v1) against
[valid-pack](sinter:#valid-pack=v1) and
[well-named-pack](sinter:#well-named-pack=v1), with `input` encoded as
a [directory-tree-object](sinter:files#directory-tree-object=v1):

```json
{"form":"#invalid-pack-vector=v1","group":"invalid-packs","input":{"entries":[{"file":{"entries":[{"file":{"content":[{"bytes":"0061736d01000000","times":1}],"type":"regular file"},"name":"782e7761736d"}],"type":"directory"},"name":"6772616d6d617273"},{"file":{"entries":[{"file":{"content":[{"bytes":"4d4954204c6963656e73650a","times":1}],"type":"regular file"},"name":"4d49542e747874"}],"type":"directory"},"name":"6c6963656e736573"},{"file":{"entries":[{"file":{"entries":[{"file":{"content":[{"bytes":"28636f6d6d656e74292040636f6d6d656e740a","times":1}],"type":"regular file"},"name":"746167732e73636d"}],"type":"directory"},"name":"78"}],"type":"directory"},"name":"71756572696573"}],"type":"directory"},"note":"the pack has no file pack.toml","result":"invalid"}
{"form":"#invalid-pack-vector=v1","group":"invalid-packs","input":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"524541444d452e6d64"},{"file":{"entries":[{"file":{"content":[{"bytes":"0061736d01000000","times":1}],"type":"regular file"},"name":"782e7761736d"}],"type":"directory"},"name":"6772616d6d617273"},{"file":{"entries":[{"file":{"content":[{"bytes":"4d4954204c6963656e73650a","times":1}],"type":"regular file"},"name":"4d49542e747874"}],"type":"directory"},"name":"6c6963656e736573"},{"file":{"content":[{"bytes":"73696e7465722d73706563203d2022312e30220a6e616d65203d202278220a76657273696f6e203d2022312e302e30220a6c6963656e7365203d20224d4954220a6e616d652d736570617261746f72203d20222e220a0a5b636f6d6d656e74735d0a6c696e65203d205b222f2f225d0a0a5b5b6772616d6d61725d5d0a6e616d65203d202278220a736861323536203d202239336134346262623936633735313231386534633030643437396534633134333538313232613338396163636131363230356231653464306463356639343736220a6c6963656e7365203d20224d4954220a6e616d6573203d205b222a2e78225d0a","times":1}],"type":"regular file"},"name":"7061636b2e746f6d6c"},{"file":{"entries":[{"file":{"entries":[{"file":{"content":[{"bytes":"28636f6d6d656e74292040636f6d6d656e740a","times":1}],"type":"regular file"},"name":"746167732e73636d"}],"type":"directory"},"name":"78"}],"type":"directory"},"name":"71756572696573"},{"file":{"content":[],"type":"regular file"},"name":"726561646d652e6d64"}],"type":"directory"},"needs":["case-distinct-names"],"note":"the pack is not well named","result":"invalid"}
```

## Runner adapters

@spec adapters=v1

A runner adapter is a WebAssembly module that recognizes a test runner's
report files and binds reported test results to test entries derived
from source test nodes. Each call runs in an isolated WebAssembly
instance and exchanges UTF-8 JSON requests and responses through the
module's linear memory.

### Definitions

#### Adapter instance

@term adapter-instance=v1
@cites {wasm-core/2.0, #webassembly-module=v1}

An **adapter instance** of a `webassembly-module`, for a program, is a
fresh instance of that module that the program instantiates with no
imports and in which code executes as the WebAssembly Core Specification
2.0 defines, with the program as embedder. Narrowing `wasm-core/2.0`, in
an adapter instance `memory.grow` fails only when the new size would
exceed the maximum of the memory.

An instantiation or invocation in an adapter instance **fails** when
that instantiation or invocation traps, or when execution of its code
under the WebAssembly Core Specification 2.0 does not terminate.

#### Adapter module

@schema adapter-module=v1
@cites {wasm-core/2.0, text#byte-sequence=v1, #webassembly-module=v1}

An **adapter module** is a `byte-sequence` that meets all three of these
conditions:

1. The byte sequence is a `webassembly-module`.
2. The module has no imports.
3. The module exports these five names with their exact kinds and types
   (the module can export additional names):

| export name | kind | type |
|---|---|---|
| `memory` | memory | — |
| `sinter_interface` | function | `[] -> [i32]` |
| `sinter_alloc` | function | `[i32] -> [i32]` |
| `sinter_recognize` | function | `[i32 i32 i32 i32] -> [i64]` |
| `sinter_bind` | function | `[i32 i32 i32 i32] -> [i64]` |

Under the adapter interface, when `sinter_alloc` can reserve the
requested number of bytes in `memory`, `sinter_alloc` reserves those
bytes and returns a non-zero byte address of the first reserved byte
(including a non-zero address when the requested byte count is `0`).
When `sinter_alloc` cannot reserve those bytes in `memory`,
`sinter_alloc` returns `0`.

#### Valid adapter

@atom valid-adapter=v1
@cites {
    wasm-core/2.0,
    text#byte-sequence=v1,
    #{adapter-instance=v1, adapter-module=v1},
}

A `byte-sequence` is a **valid adapter** in a program's validation
decision when both of these conditions hold:

1. The byte sequence meets the schema `adapter-module`.
2. In a fresh `adapter-instance` of that module, the decision performs
   instantiation followed by one invocation of `sinter_interface`, and
   nothing else in that instance; neither instantiation nor that
   invocation fails; and that invocation returns the `i32` value `1`
   (interface version 1).

In a program's validation decision for a byte sequence, the
`valid-adapter` outcome is `"valid"` when the byte sequence is a valid
adapter in that decision, and `"invalid"` otherwise.

#### Test entry

@term test-entry=v1
@cites {
    files#path=v1,
    text#{text=v1, slice=v1, line=v1, position=v1, span=v1},
    #{
        node-slice=v1, test-node=v1, test-name=v1, test-label=v1,
        parse-result=v1, file-parse=v1,
    },
}

A **test entry** holds six parts:

- **test entry id**: a `text` identifying the test entry;
- **path**: a valid `files#path`;
- **line** and **end-line**: non-negative integers;
- **kind**: either test case or test suite;
- **name path**: a sequence of names, each a sequence of pieces
  (`test-name`); and
- **test labels**: a finite set of `text` values.

When a `file-parse` with `parse-result` `"parsed"` of a `text` at valid
`path` `p` produces a `test-node`, the **test entry** of that
`test-node` with test entry id `t` has:

- test entry id `t` and path `p`;
- **line** equal to the 1-based line number of the start `position` of
  the node's `node-slice`, taken as a `span` of that text;
- **end-line** equal to the 1-based line number of the end `position` of
  that `node-slice`, taken as a `span` of that text;
- **kind** equal to test case when the `test-node` is a test case, and
  test suite when the `test-node` is a test suite;
- **name path** equal to the name path of the `test-node`; and
- **test labels** equal to the `test-label` set of the `test-node`.

#### Adapter request

@schema adapter-request=v1
@cites {
    data-forms#{
        json-value=v1, canonical-byte-sequence=v1, toml-value=v1,
    },
    text#{text=v1, byte-sequence=v1, code-point-order=v1},
    #{
        valid-descriptor=v1, test-runner=v1, runner-setting=v1,
        runner-settings=v1, runner-setting-value=v1, test-entry=v1,
        test-name=v1,
    },
}

This schema applies to a `test-runner` of a `valid-descriptor`, a valid
binding of `runner-settings` for that test runner, a **report name** (a
`text`, such as a report file path), and—for `bind`—a **root** (a
`text`, such as a repository root path) and a finite set of `test-entry`
values whose test entry ids are distinct and whose `line` and `end-line`
values are `json-value` integers.

The **recognize request object** is a `json-value` object holding only
these four members:

| member | JSON type | value |
|---|---|---|
| `interface` | integer | `1` |
| `runner` | string | name of the `test-runner` |
| `settings` | object | one member per `runner-setting` of the test runner, keyed by the setting's name; its value is the setting's `runner-setting-value` converted from `toml-value` (string for TOML string, boolean for TOML boolean, or array of strings in order for TOML array of TOML strings) |
| `report` | string | the report name |

The **bind request object** is a `json-value` object holding only the
four members of the recognize request object plus `root` and `tests`:

| member | JSON type | value |
|---|---|---|
| `root` | string | the root |
| `tests` | array of objects | one object per `test-entry`, sorted in `code-point-order` of test entry id |

Each object in `tests` holds only these seven members:

| member | JSON type | value |
|---|---|---|
| `id` | string | test entry id |
| `path` | string | path of the test entry |
| `line` | integer | `line` of the test entry |
| `end-line` | integer | `end-line` of the test entry |
| `suite` | boolean | `true` for test suite; `false` for test case |
| `names` | array of arrays | one array per name in the test entry's name path, in order; each inner array holds one single-member object per piece in order, keyed by `text` for a text piece or `placeholder` for a placeholder (`test-name`), with the piece's text as value |
| `labels` | array of strings | test labels of the test entry, sorted in `code-point-order` |

The **recognize request** is the `canonical-byte-sequence` of the
recognize request object. The **bind request** is the
`canonical-byte-sequence` of the bind request object. An **adapter
request** is a recognize request or a bind request.

@example For a [test-runner](sinter:#test-runner=v1) named `vitest`
with one [runner-setting](sinter:#runner-setting=v1) `strict = false`
and report name `out/junit.xml`, the recognize request under
[canonical-byte-sequence](sinter:data-forms#canonical-byte-sequence=v1)
is the [UTF-8 encoding](sinter:text#utf-8-encoding=v1) of:

```json
{"interface":1,"report":"out/junit.xml","runner":"vitest","settings":{"strict":false}}
```

#### Adapter call

@term adapter-call=v1
@cites {
    wasm-core/2.0,
    text#{byte-sequence=v1, text=v1},
    #{
        webassembly-module=v1, adapter-instance=v1, adapter-module=v1,
        valid-adapter=v1,
    },
}

An **adapter call** invokes one of the two adapter functions—`recognize`
(exported as `sinter_recognize`) or `bind` (exported as
`sinter_bind`)—on a `byte-sequence` as the **adapter**, a
`byte-sequence` as the **request**, a `byte-sequence` as the **report
content** (such as a report file's bytes), and—for `bind`—a finite set
of `text` values as the call's **test entry ids**.

A call uses one `valid-adapter` validation decision of the program for
the adapter; an earlier decision can serve, and any instance created by
that decision is separate from the instance used by the call's steps.
The call **fails** when the adapter is not a valid adapter in that
decision, or when the request or the report content has `4,294,967,296`
(`2^32`) bytes or more.

Otherwise, the call executes these four steps in order in a fresh
`adapter-instance` of the adapter's `webassembly-module`. If any step
fails, the call fails. In that instance, the program performs only
instantiation and the invocations in steps 2 through 4, in that order,
and modifies no byte of the exported `memory` other than by the writes
in steps 2 and 3. At each step, let *memory-size* be the byte length of
the instance's exported `memory` when that step reads it:

1. Instantiate the module.
2. Let *request-length* be the byte length of the request. Invoke
   `sinter_alloc` with the `i32` value whose unsigned 32-bit
   representation equals *request-length*. Let *req-addr* be the
   returned `i32` interpreted as an unsigned integer from `0` to
   `4,294,967,295`. The step fails when *req-addr* `= 0` or when
   *req-addr* `+` *request-length* `>` *memory-size*. Otherwise, write
   the request bytes in order into `memory` starting at *req-addr*.
3. Let *report-length* be the byte length of the report content. Invoke
   `sinter_alloc` with the `i32` value whose unsigned 32-bit
   representation equals *report-length*. Let *rep-addr* be the
   returned `i32` interpreted as an unsigned integer from `0` to
   `4,294,967,295`. The step fails when *rep-addr* `= 0` or when
   *rep-addr* `+` *report-length* `>` *memory-size*. Otherwise, write
   the report content bytes unchanged and in order into `memory`
   starting at *rep-addr*.
4. Invoke the function's export (`sinter_recognize` or `sinter_bind`)
   with four `i32` arguments whose unsigned 32-bit representations equal
   *req-addr*, *request-length*, *rep-addr*, and *report-length*. Let
   *v* be the returned `i64` interpreted as an unsigned integer from `0`
   to `18,446,744,073,709,551,615`, let *address* be the integer
   quotient *v* `/ 4,294,967,296` (high 32 bits), and let *length* be
   the remainder *v* `mod 4,294,967,296` (low 32 bits). The step fails
   when *address* `+` *length* `>` *memory-size*. Otherwise, the
   **response** of the call is the `byte-sequence` of *length* bytes
   from `memory` starting at *address*, in order.

#### Adapter response

@schema adapter-response=v1
@cites {
    data-forms#{json-value=v1, decoded-json=v1},
    text#{byte-sequence=v1, character=v1},
}

An **adapter response** is a `byte-sequence` that has a `decoded-json`
value matching one of three response forms:

- **Recognize response:** a `json-value` object holding only one member,
  `recognized`, whose value is a boolean.
- **Bind response:** a `json-value` object holding only the three
  members `results`, `bindings`, and `warnings`, subject to all four of
  these rules:
  1. `results` is an array of **result objects**. Each result object
     holds the required members `name` (string) and `status` (`"pass"`,
     `"fail"`, `"error"`, or `"skip"`), can hold the optional members
     `file` (string), `line` (integer `>= 1`), and `ms` (integer
     `>= 0`), and holds no other member.
  2. `bindings` is an array of **binding objects**. Each binding object
     holds only the three members `result` (integer `>= 0` and less than
     the number of elements in `results`), `test` (string), and `reason`
     (string containing no line feed, U+000A).
  3. No two binding objects in `bindings` share both the same `result`
     integer and the same `test` string.
  4. `warnings` is an array of strings.
- **Error response:** a `json-value` object holding only one member,
  `error`, whose value is a string.

@example A bind response
([decoded-json](sinter:data-forms#decoded-json=v1)) that binds one test
result to [test entry](sinter:#test-entry=v1) `t1`:

```json
{"bindings":[{"reason":"name and file match","result":0,"test":"t1"}],"results":[{"file":"src/math.test.ts","ms":3,"name":"math > adds","status":"pass"}],"warnings":[]}
```

#### Call result

@atom call-result=v1
@cites {
    ontology#{test=v1, test-evidence=v1},
    data-forms#{json-value=v1, decoded-json=v1, index=v1},
    text#text=v1,
    #{
        test-runner=v1, test-entry=v1, adapter-request=v1,
        adapter-call=v1, adapter-response=v1,
    },
}

For an `adapter-call`, the `call-result` outcome depends on the function
and the call's response:

- For `recognize`: the outcome is `"recognized"` when the call produces
  a recognize response with `recognized` equal to `true`,
  `"not recognized"` when the call produces a recognize response with
  `recognized` equal to `false`, and `"failed"` in every other case.
- For `bind`: the outcome is `"bound"` when the call produces a bind
  response whose `decoded-json` value has every binding object's `test`
  string equal to one of the call's test entry ids, and `"failed"` in
  every other case.

A call with outcome `"bound"` produces three ordered outputs from its
bind response's `decoded-json` value:

- **test results**: one entry per element of `results`, in order, each
  carrying `name`, `status`, and—when present on the result object—
  `file`, `line`, and duration in whole milliseconds (`ms`). Under the
  adapter interface, each test result represents a reported test result
  (`ontology#test-evidence`) for one `ontology#test` that a
  `test-runner` ran, in report order, omitting `file`, `line`, or
  duration when the report content provides none.
- **binding objects**: one entry per element of `bindings`, in order,
  each pairing the test result at 1-based `data-forms#index`
  `result + 1` in `results` with the test entry id `test` and the
  `reason` explaining why that test result binds to that `test-entry`.
- **warnings**: the strings of `warnings`, in order, each a message for
  the person running the program.

A call with outcome `"failed"` whose response is an error response
produces the string value of `error` in that response's `decoded-json`
value as the **adapter error text**. No other call produces an adapter
error text.

Under the adapter interface, `recognize` decides whether the report
content is a report file of the test runner named by the `runner` member
of the `adapter-request`.

### Validating adapters

@req validate-adapters=v1
@cites {
    conformance#conforming-program=v1,
    text#byte-sequence=v1,
    #valid-adapter=v1,
}

When validating a `byte-sequence` as an adapter, a conforming program
must return the `valid-adapter` outcome for that byte sequence in that
decision.

### Supplying adapter requests

@req give-requests=v1
@cites {
    conformance#conforming-program=v1,
    data-forms#json-value=v1,
    text#byte-sequence=v1,
    #{
        valid-descriptor=v1, test-runner=v1, runner-settings=v1,
        test-entry=v1, adapter-request=v1, adapter-call=v1,
    },
}

When making an `adapter-call` of a `byte-sequence` as the adapter of a
`test-runner` of a `valid-descriptor` under a valid binding of
`runner-settings` for that test runner, a conforming program must pass
the exact `adapter-request` bytes for that function:

- For `recognize` with a report name, the program must pass the
  recognize `adapter-request` for that test runner, that binding, and
  that report name.
- For `bind` with a report name, a root, and test entries whose test
  entry ids are distinct and whose `line` and `end-line` values are
  `json-value` integers, the program must pass the bind
  `adapter-request` for that test runner, that binding, that report
  name, that root, and those test entries, and must pass the set of
  their test entry ids as the call's test entry ids.

### Returning call results

@req give-call-results=v1
@cites {
    conformance#conforming-program=v1,
    text#{byte-sequence=v1, text=v1},
    #{adapter-call=v1, call-result=v1},
}

When a conforming program makes an `adapter-call` of a `byte-sequence`
as an adapter with a request and report content (and test entry ids for
`bind`), the program must obey these rules for the call's `call-result`:

- When returning the call's outcome, the program must return the
  `call-result` outcome of that call: `"recognized"`,
  `"not recognized"`, or `"failed"` for `recognize`, and `"bound"` or
  `"failed"` for `bind`.
- When the outcome is `"bound"` and the program returns the call's test
  results, binding objects, or warnings, the program must return the
  values produced by the call, in order.
- When the outcome is not `"bound"`, the program must return no test
  results, no binding objects, and no warnings for that call.
- When the outcome is `"failed"`, the call produces an adapter error
  text, and the program returns an adapter error text for that call,
  the program must return that adapter error text. When the outcome is
  not `"failed"` or the call produces no adapter error text, the
  program must return no adapter error text for that call.

### Isolating adapters

@req isolate-adapters=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    text#byte-sequence=v1,
    #{webassembly-module=v1, adapter-instance=v1},
}

A conforming program must run the code of a `byte-sequence` used as an
adapter only inside an `adapter-instance` of that byte sequence's
`webassembly-module`.

### Ending adapter code

@req end-adapter-code=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    #{valid-adapter=v1, adapter-call=v1},
}

A conforming program must end the execution of any adapter code that it
runs in an `adapter-call` or in a `valid-adapter` validation decision.

### Test vectors

The file
[`packs.adapters.test-vectors.jsonl`](packs.adapters.test-vectors.jsonl)
holds the test vectors of `adapters`. No group uses `needs`. The
requirement `isolate-adapters` has no test vectors.

#### Adapter validation vectors

@schema adapter-vector=v1
@cites {
    data-forms#{
        hex-text=v1, vector-line=v1, group-schema=v1, vector-meaning=v1,
    },
    text#byte-sequence=v1,
    #{valid-adapter=v1, validate-adapters=v1, end-adapter-code=v1},
}

`adapter-vector` is a `group-schema` for group `adapters` of
specification `adapters` and tests `validate-adapters` and
`end-adapter-code`. Each line is a `vector-line` whose meaning follows
`vector-meaning` and omits `values`.

| field | type | meaning |
|---|---|---|
| `input` | string | input `byte-sequence`, encoded as `hex-text` |
| `result` | string | `valid-adapter` outcome: `"valid"` or `"invalid"` |

@example Sample lines testing
[validate-adapters](sinter:#validate-adapters=v1) and
[end-adapter-code](sinter:#end-adapter-code=v1) with
[valid-adapter](sinter:#valid-adapter=v1) and
[hex-text](sinter:data-forms#hex-text=v1):

```json
{"form":"#adapter-vector=v1","group":"adapters","input":"0061736d01000000","note":"a module with no export","result":"invalid"}
{"form":"#adapter-vector=v1","group":"adapters","input":"0061736d01000000011a056000017f60017f017f60047f7f7f7f017e60017e017f600000030504000102020503010001074d05066d656d6f727902001073696e7465725f696e7465726661636500000c73696e7465725f616c6c6f6300011073696e7465725f7265636f676e697a6500020b73696e7465725f62696e6400030a1504040041010b040041100b040042000b040042000b","note":"a module that exports the five names with their types, and whose sinter_interface gives 1","result":"valid"}
```

#### Adapter request vectors

@schema request-vector=v1
@cites {
    files#path=v1,
    data-forms#{
        json-value=v1, toml-value=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    text#{text=v1, utf-8-encoding=v1},
    #{
        valid-descriptor=v1, test-runner=v1, runner-setting=v1,
        runner-settings=v1, runner-setting-value=v1, test-entry=v1,
        test-name=v1, adapter-request=v1, adapter-call=v1,
        give-requests=v1,
    },
}

`request-vector` is a `group-schema` for group `requests` of
specification `adapters` and tests `give-requests`. Each line is a
`vector-line` whose meaning follows `vector-meaning` and omits `result`.
Each vector represents a call for a `test-runner` of a
`valid-descriptor` under a valid binding of `runner-settings` whose
runner settings and values are the members of `input.settings`.

| field | type | meaning |
|---|---|---|
| `input.function` | string | `"recognize"` or `"bind"` |
| `input.runner` | string | name of the `test-runner` |
| `input.settings` | object | map from each `runner-setting` name of the test runner to its `runner-setting-value` (string for TOML string, boolean for TOML boolean, or array of strings for TOML array of TOML strings) |
| `input.report` | string | report name |
| `input.root` | string (`bind` only) | root text |
| `input.tests[]` | array of objects (`bind` only) | `test-entry` values in any order, with distinct `id` strings |
| `input.tests[].id` | string | test entry id |
| `input.tests[].path` | string | valid `files#path` |
| `input.tests[].line` | integer | `line` of the test entry (`json-value` integer) |
| `input.tests[].end-line` | integer | `end-line` of the test entry (`json-value` integer) |
| `input.tests[].suite` | boolean | `true` for test suite; `false` for test case |
| `input.tests[].names[][]` | array of arrays | name path pieces in order (`{"text": string}` or `{"placeholder": string}` per `test-name`) |
| `input.tests[].labels[]` | array of strings | distinct test labels in any order |
| `values.request` | string | `text` whose `utf-8-encoding` is the exact `adapter-request` byte sequence passed to the `adapter-call` |

@example Sample lines testing [give-requests](sinter:#give-requests=v1)
with [adapter-request](sinter:#adapter-request=v1) and
[test-entry](sinter:#test-entry=v1):

```json
{"form":"#request-vector=v1","group":"requests","input":{"function":"recognize","report":"out/junit.xml","runner":"vitest","settings":{}},"values":{"request":"{\"interface\":1,\"report\":\"out/junit.xml\",\"runner\":\"vitest\",\"settings\":{}}"}}
{"form":"#request-vector=v1","group":"requests","input":{"function":"bind","report":"out/junit.xml","root":"/w","runner":"vitest","settings":{},"tests":[{"end-line":5,"id":"test:src/m.test.ts#math.adds ${n}","labels":["table","each"],"line":3,"names":[[{"text":"math"}],[{"text":"adds "},{"placeholder":"${n}"}]],"path":"src/m.test.ts","suite":false},{"end-line":6,"id":"test:src/m.test.ts#math","labels":[],"line":1,"names":[[{"text":"math"}]],"path":"src/m.test.ts","suite":true}]},"note":"the test entries stand in the code point order of their ids, and the test labels of each in code point order","values":{"request":"{\"interface\":1,\"report\":\"out/junit.xml\",\"root\":\"/w\",\"runner\":\"vitest\",\"settings\":{},\"tests\":[{\"end-line\":6,\"id\":\"test:src/m.test.ts#math\",\"labels\":[],\"line\":1,\"names\":[[{\"text\":\"math\"}]],\"path\":\"src/m.test.ts\",\"suite\":true},{\"end-line\":5,\"id\":\"test:src/m.test.ts#math.adds ${n}\",\"labels\":[\"each\",\"table\"],\"line\":3,\"names\":[[{\"text\":\"math\"}],[{\"text\":\"adds \"},{\"placeholder\":\"${n}\"}]],\"path\":\"src/m.test.ts\",\"suite\":false}]}"}}
```

#### Adapter response vectors

@schema response-vector=v1
@cites {
    data-forms#{
        hex-text=v1, json-value=v1, index=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1,
    },
    text#{byte-sequence=v1, text=v1},
    #{
        valid-adapter=v1, adapter-call=v1, adapter-response=v1,
        call-result=v1, test-entry=v1, give-call-results=v1,
    },
}

`response-vector` is a `group-schema` for group `responses` of
specification `adapters` and tests `give-call-results`. Each line is a
`vector-line` whose meaning follows `vector-meaning`. Each vector
represents an `adapter-call` of a `valid-adapter` whose function export
invocation produces `input.response` with no earlier step failure. When
`result` is `"recognized"`, `"not recognized"`, or `"failed"` with no
adapter error text, `values` is `{}` (meaning the program returns no
test results, binding objects, warnings, or adapter error text).

| field | type | meaning |
|---|---|---|
| `input.function` | string | `"recognize"` or `"bind"` |
| `input.ids[]` | array of strings (`bind` only) | distinct test entry ids of the call |
| `input.response` | string | response `byte-sequence`, encoded as `hex-text` |
| `result` | string | `call-result` outcome: `"recognized"`, `"not recognized"`, or `"failed"` for `recognize`; `"bound"` or `"failed"` for `bind` |
| `values.results[]` | array of objects (when `"bound"`) | ordered test results (`name`, `status`, and optional `file`, `line`, `ms` per `adapter-response`) |
| `values.bindings[]` | array of objects (when `"bound"`) | ordered binding objects (`result`: the `index` of the bound test result in `values.results`, less 1; `test` and `reason` as strings) |
| `values.warnings[]` | array of strings (when `"bound"`) | ordered warnings |
| `values.error` | string (optional, when `"failed"`) | adapter error text when the call produces one |

@example Sample lines testing
[give-call-results](sinter:#give-call-results=v1) with
[adapter-response](sinter:#adapter-response=v1),
[call-result](sinter:#call-result=v1), and
[hex-text](sinter:data-forms#hex-text=v1):

```json
{"form":"#response-vector=v1","group":"responses","input":{"function":"recognize","response":"7b227265636f676e697a6564223a747275657d"},"result":"recognized","values":{}}
{"form":"#response-vector=v1","group":"responses","input":{"function":"recognize","response":"7b226572726f72223a22746865207265706f7274206973206e6f74204a556e697420584d4c227d"},"note":"the error text of the adapter","result":"failed","values":{"error":"the report is not JUnit XML"}}
```

#### Adapter call vectors

@schema call-vector=v1
@cites {
    data-forms#{
        hex-text=v1, json-value=v1, index=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1,
    },
    text#{byte-sequence=v1, text=v1},
    #{
        adapter-call=v1, adapter-response=v1, call-result=v1,
        test-entry=v1, give-call-results=v1, end-adapter-code=v1,
    },
}

`call-vector` is a `group-schema` for group `calls` of specification
`adapters` and tests `give-call-results` and `end-adapter-code`. Each
line is a `vector-line` whose meaning follows `vector-meaning`. Each
vector represents an `adapter-call` with these inputs. When `result` is
`"recognized"`, `"not recognized"`, or `"failed"` with no adapter error
text, `values` is `{}` (meaning the program returns no test results,
binding objects, warnings, or adapter error text).

| field | type | meaning |
|---|---|---|
| `input.adapter` | string | adapter `byte-sequence`, encoded as `hex-text` |
| `input.function` | string | `"recognize"` or `"bind"` |
| `input.request` | string | request `byte-sequence`, encoded as `hex-text` |
| `input.report-content` | string | report content `byte-sequence`, encoded as `hex-text` |
| `input.ids[]` | array of strings (`bind` only) | distinct test entry ids of the call |
| `result` | string | `call-result` outcome: `"recognized"`, `"not recognized"`, or `"failed"` for `recognize`; `"bound"` or `"failed"` for `bind` |
| `values.results[]` | array of objects (when `"bound"`) | ordered test results (`name`, `status`, and optional `file`, `line`, `ms` per `adapter-response`) |
| `values.bindings[]` | array of objects (when `"bound"`) | ordered binding objects (`result`: the `index` of the bound test result in `values.results`, less 1; `test` and `reason` as strings) |
| `values.warnings[]` | array of strings (when `"bound"`) | ordered warnings |
| `values.error` | string (optional, when `"failed"`) | adapter error text when the call produces one |

@example Sample lines testing
[give-call-results](sinter:#give-call-results=v1) and
[end-adapter-code](sinter:#end-adapter-code=v1) with
[adapter-call](sinter:#adapter-call=v1),
[call-result](sinter:#call-result=v1), and
[hex-text](sinter:data-forms#hex-text=v1):

```json
{"form":"#call-vector=v1","group":"calls","input":{"adapter":"0061736d01000000011a056000017f60017f017f60047f7f7f7f017e60017e017f600000030504000102020503010001074d05066d656d6f727902001073696e7465725f696e7465726661636500000c73696e7465725f616c6c6f6300011073696e7465725f7265636f676e697a6500020b73696e7465725f62696e6400030a1b04040041010b040041000b0a0042938080808080010b040042000b0b1a01004180080b137b227265636f676e697a6564223a747275657d","function":"recognize","report-content":"3c74657374737569746573206e616d653d22766974657374207465737473223e3c2f746573747375697465733e","request":"7b22696e74657266616365223a312c227265706f7274223a226f75742f6a756e69742e786d6c222c2272756e6e6572223a22766974657374222c2273657474696e6773223a7b7d7d"},"note":"sinter_alloc gives the address 0","result":"failed","values":{}}
{"form":"#call-vector=v1","group":"calls","input":{"adapter":"0061736d01000000011a056000017f60017f017f60047f7f7f7f017e60017e017f600000030504000102020503010001074d05066d656d6f727902001073696e7465725f696e7465726661636500000c73696e7465725f616c6c6f6300011073696e7465725f7265636f676e697a6500020b73696e7465725f62696e6400030a2104040041010b040041100b0a0042938080808080010b0a0042f18080808080020b0b910102004180080b137b227265636f676e697a6564223a747275657d004180100b717b2262696e64696e6773223a5b7b22726561736f6e223a226e616d65222c22726573756c74223a302c2274657374223a227431227d5d2c22726573756c7473223a5b7b226e616d65223a2261646473222c22737461747573223a2270617373227d5d2c227761726e696e6773223a5b5d7d","function":"bind","ids":["t1"],"report-content":"3c74657374737569746573206e616d653d22766974657374207465737473223e3c2f746573747375697465733e","request":"7b22696e74657266616365223a312c227265706f7274223a226f75742f6a756e69742e786d6c222c2272756e6e6572223a22766974657374222c2273657474696e6773223a7b7d7d"},"note":"the call invokes sinter_bind, whose response lies at the address 2,048, and not sinter_recognize","result":"bound","values":{"bindings":[{"reason":"name","result":0,"test":"t1"}],"results":[{"name":"adds","status":"pass"}],"warnings":[]}}
```
