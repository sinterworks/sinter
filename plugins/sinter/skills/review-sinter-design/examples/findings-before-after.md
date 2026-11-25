# Worked critique examples: unreasonable vs. grounded findings

The examples below use two invented domains—a webhook delivery service and a
structured audit-log envelope—to contrast weak and grounded critique across
restraint against contrived objections, behavioral defect detection, and quiet
structural hygiene.

---

## Case 1: Restraint — rejecting a contrived loophole (webhook retries)

### Text under review

```markdown
### Scheduling retries

@req schedule-retry=v1
@cites {rfc/9110, rfc/6585, #{retry-policy=v1, delivery-state=v1}}

After a failed delivery attempt under a valid `retry-policy`, a conforming
program must act according to the failure kind:

- **Temporary failure** (transport timeout, HTTP 429 per RFC 6585 section 4, or
  HTTP 5xx): when fewer than `max-attempts` attempts ran, the program must
  schedule the next attempt after the retry delay below. When `max-attempts`
  attempts ran, the program must mark the delivery `exhausted` and schedule no
  retry.
- **Permanent failure** (any other failed HTTP status): the program must mark
  the delivery `failed` and schedule no retry.

The computed delay after failed 1-based attempt `n` is
`min(base-delay * 2^(n - 1), max-delay)`. When an HTTP 429 or 503 response
includes a `Retry-After` header with a valid `delay-seconds` value (RFC 9110,
section 10.2.3), the program must use
`min(max(computed-delay, retry-after), max-delay)` as the retry delay.
```

### Weak critique (adversarial — do not write this)

> **A-1 (`schedule-retry`):** `schedule-retry` says "must schedule the next
> attempt" without stating that the program schedules *only one* next attempt
> and *no other* attempt. A conforming implementation could schedule three
> duplicate retries and still satisfy the text.
>
> **Fix:** Change to "must schedule exactly one next attempt, and no other
> attempt, after the retry delay below."
>
> **A-2 (`schedule-retry`):** `schedule-retry` never defines what
> `delay-seconds` means for negative integers, HTTP-date values, or leading
> whitespace.
>
> **Fix:** Add a new `@term retry-after-integer=v1` with an ABNF grammar for
> integer header values, and state in prose that negative values, HTTP-date
> strings, and leading whitespace are rejected.

**Why this critique fails:**

- **A-1** fails the cooperative-engineer test. No engineer implementing webhook
  retries deliberately schedules three duplicate retries when told to schedule
  "the next attempt". The proposed fix injects defensive bloat (`"exactly one
  ... and no other"`).
- **A-2** violates the three-tier allocation test. RFC 9110 section 10.2.3
  already defines `delay-seconds = 1*DIGIT` (non-negative decimal seconds,
  excluding negative integers and `HTTP-date` values). Instead of checking the
  cited standard and checking whether `webhooks-vectors.jsonl` covers
  those inputs, the critic demands a redundant single-use `@term` and prose
  bloat.

### Grounded critique (right approach)

- **Drop A-1 completely.** Ordinary engineering reading already means one next
  attempt.
- **Check the cited standard and the vectors first.** RFC 9110 section 10.2.3
  already decides `"-5"` and `HTTP-date` strings, so no prose change is needed.
  If `webhooks-vectors.jsonl` already tests `"-5"` and an HTTP-date
  string, file nothing (record it in verification notes). If those real
  boundary inputs are missing from the vector file, file Class `B` with
  concrete proposed vector lines:

> **B-1 (`schedule-retry` and `webhooks-vectors.jsonl`, group `retry-schedule`):**
> - **Quoted text:** "includes a `Retry-After` header with a valid
>   `delay-seconds` value (RFC 9110, section 10.2.3)"
> - **Defect:** RFC 9110 section 10.2.3 excludes negative numbers and
>   separates `HTTP-date` from `delay-seconds`, so a conforming program ignores
>   both and uses `computed-delay`. However, group `retry-schedule` has no
>   vector testing a negative integer (`"-5"`) or an `HTTP-date` header value,
>   leaving two common real-world inputs untested.
> - **Simplest fix:** Add two vectors to group `retry-schedule` (no prose
>   change needed):
>   - `{"form":"#retry-schedule-vector=v1","group":"retry-schedule","input":{"attempt":1,"policy":{"base-delay":10,"max-attempts":3,"max-delay":60},"retry-after":"-5","status":429},"note":"negative Retry-After is not delay-seconds and is ignored","values":{"delay":10,"state":"retry"}}`
>   - `{"form":"#retry-schedule-vector=v1","group":"retry-schedule","input":{"attempt":1,"policy":{"base-delay":10,"max-attempts":3,"max-delay":60},"retry-after":"Wed, 21 Oct 2026 07:28:00 GMT","status":503},"note":"HTTP-date Retry-After is not delay-seconds and is ignored","values":{"delay":10,"state":"retry"}}`

---

## Case 2: Sharpness — catching a stranded rule in concise text (webhook retries)

### Text under review

```markdown
### Scheduling retries

@req schedule-retry=v1
@cites {rfc/9110, rfc/6585, #{retry-policy=v1, delivery-state=v1}}

After a failed delivery attempt under a valid `retry-policy`, a conforming
program must act according to the failure kind:

- **Temporary failure** (transport timeout, HTTP 429 per RFC 6585 section 4, or
  HTTP 5xx): when fewer than `max-attempts` attempts ran, the program must
  schedule the next attempt after `min(base-delay * 2^(n - 1), max-delay)`
  for failed 1-based attempt `n`. When `max-attempts` attempts ran, the
  program must mark the delivery `exhausted` and schedule no retry.
- **Permanent failure** (any other failed HTTP status): the program must mark
  the delivery `failed` and schedule no retry.

@example Under `base-delay = 10s`, `max-delay = 60s`, and `max-attempts = 3`,
a first attempt returning HTTP 429 with `Retry-After: 45` overrides the
computed 10s delay and schedules attempt 2 at 45s (capped at `max-delay`).
```

Vector line 14 in `webhooks-vectors.jsonl`:

```json
{"form":"#retry-schedule-vector=v1","group":"retry-schedule","input":{"attempt":1,"policy":{"base-delay":10,"max-attempts":3,"max-delay":60},"retry-after":"45","status":429},"note":"429 Retry-After overrides shorter exponential backoff","values":{"delay":45,"state":"retry"}}
```

### Weak critique (rubber-stamping — do not write this)

> Looks concise, clear, and easy for the human author to edit. No Class `A`
> findings.

**Why this critique fails:**

- It skipped the stranded-rule check and the vector trace check. The normative
  text of `schedule-retry` already contradicts vector line 14 (computing `10`,
  not `45`); only the non-normative `@example` states the `Retry-After`
  override.

### Grounded critique (right approach)

> **A-1 (`schedule-retry`, `@example`, and `webhooks-vectors.jsonl:14`):**
> - **Quoted text:** "the program must schedule the next attempt after
>   `min(base-delay * 2^(n - 1), max-delay)` for failed 1-based attempt `n`."
> - **Defect:** Stranded rule and normative–vector contradiction. The normative
>   text of `schedule-retry` never mentions `Retry-After`. Vector line 14 gives
>   `attempt: 1`, `base-delay: 10`, `status: 429`, and `retry-after: "45"`,
>   expecting `values.delay: 45`. The `Retry-After` override appears only inside
>   the non-normative `@example` block. A cooperative engineer implementing
>   `schedule-retry` produces `delay: 10` and fails vector 14.
> - **Simplest fix:** Move the `Retry-After` rule into the normative text of
>   `schedule-retry` (one sentence naming HTTP 429 and 503, RFC 9110 section
>   10.2.3 `delay-seconds`, and
>   `min(max(computed-delay, retry-after), max-delay)`).
>
> **B-1 (`schedule-retry`, `@example`):**
> - **Quoted text:** ``@example Under `base-delay = 10s`, `max-delay = 60s`, and `max-attempts = 3`,``
> - **Defect:** The `@example` relies on fields of `retry-policy` without an
>   inline `[retry-policy](sinter:#retry-policy=v1)` citation, so Sinter does
>   not flag the example when `retry-policy` changes.
> - **Simplest fix:** Add `([retry-policy](sinter:#retry-policy=v1))` inside
>   the `@example` block.

---

## Case 3: Restraint + sharpness on a data format (audit-log envelope)

### Text under review

```markdown
### Envelope schema

@schema audit-envelope=v1
@cites {rfc/8259, rfc/3339}

An audit envelope is a valid UTF-8 byte sequence matching an RFC 8259 JSON
object, with these narrowings:

| aspect | rule |
|---|---|
| encoding | No leading UTF-8 byte order mark (`U+FEFF`). |
| object members | No duplicate member names in any object (after escape decoding, without Unicode normalization). |
| required keys | `ts` (string), `actor` (non-empty string), and `action` (non-empty string). Unknown top-level keys are rejected. |
| `ts` format | RFC 3339 `date-time` with uppercase `T` and uppercase `Z` offset (no numeric offsets and no leap second `60`). |

### Decoding audit envelopes

@req decode-audit-envelope=v1
@cites #{audit-envelope=v1}

When decoding a byte sequence as an audit envelope, a conforming program must
return the decoded audit envelope if the bytes match `audit-envelope`, and
reject the input with no audit envelope otherwise.
```

Vector line 9 in `audit-log-vectors.jsonl`:

```json
{"form":"#decode-envelope-vector=v1","group":"decode-envelope","input":"7b22616374696f6e223a226c6f67696e222c226163746f72223a22616461222c227473223a22323032362d30352d30315431323a30303a30302e3530305a227d","note":"fractional seconds in ts are rejected","result":"invalid","values":{}}
```

### Weak critique (adversarial + standard re-litigation — do not write this)

> **A-1 (`audit-envelope`):** The schema does not define UTF-8, JSON string
> escape sequences, or Unicode surrogate pairs, and there is no Glossary
> defining `byte` or `string`.
>
> **A-2 (`decode-audit-envelope`):** The requirement says "return the decoded
> audit envelope" without defining what it means for a program to "return" an
> envelope or forbidding the program from returning a different envelope.
>
> **A-3 (`audit-envelope`):** The schema uses "are rejected" without using
> `must` and does not specify what error code a program returns when rejecting.

**Why this critique fails:**

- **A-1** re-litigates RFC 8259 and demands a Glossary for basic words.
- **A-2** demands tautological definitions of ordinary verbs and closes a
  bad-faith loophole.
- **A-3** misunderstands the model: `@schema` is declarative (reserving `must`
  for `@req`), and error codes are outside a black-box data format unless the
  design declares them.
- This critique also misses the real Class `A` defect in vector line 9.

### Grounded critique (right approach)

> **A-1 (`audit-envelope` and `audit-log-vectors.jsonl:9`):**
> - **Quoted text:** "RFC 3339 `date-time` with uppercase `T` and uppercase `Z`
>   offset (no numeric offsets and no leap second `60`)."
> - **Defect:** Normative–vector contradiction on fractional seconds. RFC 3339
>   `date-time` allows optional `time-secfrac` (such as `.500`). Vector line 9
>   sends `"ts":"2026-05-01T12:00:00.500Z"` and expects `"result":"invalid"` with
>   note `"fractional seconds in ts are rejected"`. A cooperative engineer
>   following `audit-envelope` accepts fractional seconds and fails vector 9.
> - **Simplest fix:** Add "no fractional seconds" to the `ts` format row of
>   `audit-envelope` (supported by vector line 9 and its note), or file Class
>   `O` if fractional seconds remain unruled.
>
> **C-1 (`audit-envelope`, `required keys` row):**
> - **Quoted text:** "Unknown top-level keys are rejected."
> - **Defect:** Passive operational wording inside a declarative `@schema`.
> - **Simplest fix:** Write "No top-level keys other than `ts`, `actor`, and
>   `action`."

---

## Case 4: Quiet structural defects in a clean design (pins, section numbers, sample lines)

Suppose a behaviorally sound draft passes every test vector, yet contains
quiet structural flaws (`backoff-delay` is shared by both `schedule-retry` and
`estimate-retry-window`):

````markdown
### Backoff delay

@term backoff-delay=v1
@cites {#{retry-policy=v1, delivery-state=v1}}

The backoff delay after failed 1-based attempt `n` (shared by `schedule-retry`
and `estimate-retry-window`) is `min(base-delay * 2^(n - 1), max-delay)`
(RFC 9110, section 10.2.3).

@example Under `base-delay = 10s` and `max-delay = 60s`, after failed attempts
1, 2, 3, and 4, the next attempt waits 10s, 20s, 40s, and 60s.

### Test vectors

@schema retry-schedule-vector=v1
@cites #{schedule-retry=v1}

Group `retry-schedule` in
[`webhooks-vectors.jsonl`](webhooks-vectors.jsonl) tests
`schedule-retry`.

| field | type | meaning |
|---|---|---|
| `input.computed-delay` | integer | already-computed exponential delay |
| `values.delay` | integer | final scheduled delay |

```json
{"form":"#retry-schedule-vector=v1","group":"retry-schedule","input":{"computed-delay":10},"values":{"delay":10}}
```
````

### Weak critique (two opposite errors — avoid both)

- **Over-restraint (rubber-stamping):** *"No behavioral bug, so skip these as
  pedantry."* That leaves unused and missing pins, a wrong RFC section
  reference, a missing `@example` inline citation, an untested formula, and an
  untagged copy of a vector line.
- **Severity inflation:** *"File all four findings as Class `A` blockers."*
  None of them causes a wrong answer on a real input; inflating them to `A`
  blurs the blocking gate.

### Grounded critique (Class `B` structural findings)

> **B-1 (`backoff-delay`, `@cites` and RFC reference):**
> - **Quoted text:** "`@cites {#{retry-policy=v1, delivery-state=v1}}`" and
>   "`(RFC 9110, section 10.2.3)`"
> - **Defect:** `backoff-delay` never uses `delivery-state`, and cites RFC 9110
>   in prose without pinning `rfc/9110` in `@cites`. Furthermore, RFC 9110
>   section 10.2.3 covers `Retry-After`, not exponential backoff. Unused pins
>   cause false review churn, and a wrong section reference misleads
>   implementers.
> - **Simplest fix:** Remove `delivery-state=v1` from `@cites`, remove the
>   incorrect RFC 9110 reference from `backoff-delay`, and cite `rfc/9110`
>   (section 10.2.3) in `schedule-retry` where `Retry-After` lives.
>
> **B-2 (`backoff-delay`, `@example`):**
> - **Quoted text:** ``@example Under `base-delay = 10s` and `max-delay = 60s`,``
> - **Defect:** The example relies on fields of `retry-policy` without an
>   inline `[retry-policy](sinter:#retry-policy=v1)` citation, so Sinter does
>   not flag the example when `retry-policy` changes.
> - **Simplest fix:** Add `([retry-policy](sinter:#retry-policy=v1))` inside
>   the `@example` block.
>
> **B-3 (`retry-schedule-vector`, `input.computed-delay`):**
> - **Quoted text:** ``| `input.computed-delay` | integer | already-computed exponential delay |``
> - **Defect:** The vector input supplies a precomputed delay instead of the
>   raw `attempt`, `base-delay`, and `max-delay` values, leaving the
>   `backoff-delay` formula untested by any vector.
> - **Simplest fix:** Replace `input.computed-delay` with the raw policy and
>   attempt fields so vectors test the derivation directly.
>
> **B-4 (`retry-schedule-vector`, trailing `json` block):**
> - **Quoted text:** ``{"form":"#retry-schedule-vector=v1","group":"retry-schedule","input":{"computed-delay":10},"values":{"delay":10}}``
> - **Defect:** The fenced `json` block has no `@example` tag, omits the
>   vector's `"note"` field, and carries no lead inline citation. Sample edits
>   therefore change the `@schema` hash, and the copy already differs from the
>   vector file.
> - **Simplest fix:** Place the verbatim vector line inside a trailing
>   `@example` block with a lead line inline-citing
>   `[schedule-retry](sinter:#schedule-retry=v1)` (and any key definition), or
>   delete the sample block.

---

## Case 5: Simple fix for genuine ambiguity (`A`) with an open choice (`O`)

Suppose a design states:

> "A conforming program rejects any audit envelope whose `actor` string exceeds
> 16 characters."

A reviewer spots a genuine implementation ambiguity (`A`): in UTF-8,
"characters" can mean UTF-8 bytes, Unicode scalar values, or grapheme clusters,
and two cooperative engineers reading this sentence for `"é"` (`U+00E9`, 2
UTF-8 bytes, 1 scalar value) disagree at the boundary. Because the sources do
not say which unit the author wants, the unit choice is also an open choice
(`O`) that the reviewer recommends rather than decides unilaterally.

- **Patchwork fix (avoid):** *"Add a paragraph explaining that characters do
  not mean UTF-8 bytes, UTF-16 code units, or grapheme clusters, and define a
  new `@term actor-character-count=v1` specifying how to iterate over decoded
  strings."*
- **Simple grounded finding (right):**
  - **Class `A` + `O`:** Flag the ambiguity as Class `A` and present the unit
    choice as Class `O` with two concrete options (`16 Unicode scalar values`
    vs. `16 UTF-8 bytes`), recommending `16 Unicode scalar values` because
    JSON strings decode to Unicode scalar values across languages.
  - **Simplest fix (under the recommended option):** Replace `16 characters`
    with `16 Unicode scalar values`, and add one boundary vector with a
    16-scalar multi-byte `actor` string (15 `"a"` characters plus `"é"`,
    17 UTF-8 bytes, `"result":"valid"`):
    `{"form":"#decode-envelope-vector=v1","group":"decode-envelope","input":"7b22616374696f6e223a226c6f67696e222c226163746f72223a22616161616161616161616161616161c3a9222c227473223a22323032362d30352d30315431323a30303a30305a227d","note":"16 Unicode scalar values (17 UTF-8 bytes) is valid","result":"valid","values":{}}`

---

## Case 6: Flagging bloat for removal (protecting human editability)

Suppose a draft contains:

```markdown
## Retries

@spec retries=v1

Three rules govern webhook retries cleanly and predictably:
1. Only temporary failures retry.
2. `Retry-After` overrides backoff up to `max-delay`.
3. Deliveries stop after `max-attempts` attempts.

### Delivery state

@atom delivery-state=v1

A delivery is in state `retry`, `exhausted`, or `failed`.

@example A delivery that retries has state `retry`.
```

### Grounded critique (right approach)

> **B-1 (`@spec retries=v1`, opening list):**
> - **Quoted text:** ``Three rules govern webhook retries cleanly and predictably: 1. Only temporary failures retry. 2. `Retry-After` overrides backoff up to `max-delay`. 3. Deliveries stop after `max-attempts` attempts.``
> - **Defect:** The opening prose uses a rule-counting lead-in and restates the
>   three rules that `@req schedule-retry` declares below, forcing the human
>   author to edit every change in two places.
> - **Simplest fix:** Replace the opening list with one or two
>   domain-orientation sentences explaining why the dispatcher retries temporary
>   failures and stops on permanent errors.
>
> **C-1 (`delivery-state`, `@example`):**
> - **Quoted text:** ``@example A delivery that retries has state `retry`.``
> - **Defect:** The `@example` block merely repeats the obvious one-line
>   definition and adds noise for human readers.
> - **Simplest fix:** Delete this `@example` block.
