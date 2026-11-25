# Annotated before-and-after examples

The examples below use two invented domains—a webhook delivery service and a
structured audit-log envelope—to contrast weak and strong Sinter designs across
a behavioral feature, a data format, `@example` blocks, and a test-vector
schema.

---

## Example 1: Behavioral feature (webhook retries)

### Before (weak)

```markdown
## Retries

@spec retries=v1

Webhook delivery can fail when a receiver is temporarily unavailable, so the
dispatcher retries failed deliveries with exponential backoff and stops after
a bounded number of attempts so that dead endpoints do not consume resources
forever. Three concrete rules make retry scheduling predictable and safe:

1. **Retryable responses only:** Only transport timeouts and HTTP 5xx or 429
   responses trigger a retry. HTTP 4xx responses other than 429 are permanent
   failures and never retry.
2. **Respect `Retry-After`:** When a 429 or 503 response includes a valid
   integer `Retry-After` header, the dispatcher waits at least that many
   seconds, capped at the maximum delay.
3. **Stop at the attempt limit:** After `max-attempts` total attempts, the
   dispatcher marks the delivery `exhausted` and schedules no further retry.

### Definitions

#### Retryable failure

@term retryable-failure=v1
@cites #{delivery-outcome=v1}

A delivery attempt produces a retryable failure when, and only when, all two
conditions hold:
1. The attempt ended in a transport timeout, HTTP 429, or HTTP 5xx status.
2. The attempt count is strictly less than `max-attempts`.

### Requirements

#### Scheduling retries

@req schedule-retry=v1
@cites #{retryable-failure=v1, retry-delay=v1}

When a delivery attempt produces a `retryable-failure`, a conforming program
must schedule exactly one next attempt at the computed `retry-delay` and no
other attempt. When an attempt does not produce a `retryable-failure`, a
conforming program must schedule no next attempt and must mark the delivery
`exhausted` if `max-attempts` was reached or `failed` otherwise.

### Conformance

A program conforms to the specification `retries` when the program is a
conforming program of that specification: the program meets every requirement
that the specification declares. The vectors of this specification stand in
`webhooks.test-vectors.jsonl`.
```

**Why this fails:**

- The opening paragraph and `"Three concrete rules make retry scheduling
  predictable and safe:"` recap the rules that follow, forcing the human author
  to edit every change in two places.
- Rule 2 (`Retry-After` cap) appears only in non-normative prose and disappears
  from the normative items.
- `"when, and only when, all two conditions hold"` and `"exactly one next
  attempt ... and no other attempt"` are adversarial padding rather than plain
  engineering statements.
- `@term retryable-failure` is used by only one requirement (`schedule-retry`),
  failing the single-use test.
- `@req schedule-retry` relies on HTTP status codes and `Retry-After` without
  pinning `rfc/9110` or `rfc/6585`.
- The `### Conformance` paragraph repeats boilerplate that adds no information.

### After (strong)

```markdown
## Retries

@spec retries=v1

Receivers occasionally fail or throttle incoming webhooks. The dispatcher
retries temporary failures with bounded backoff and stops on permanent errors
or exhausted deliveries.

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

@example Under `base-delay = 10s`, `max-delay = 60s`, and `max-attempts = 3`
([retry-policy](sinter:#retry-policy=v1)), a first attempt returning HTTP 429
with `Retry-After: 45` schedules attempt 2 at 45s. A third attempt returning
HTTP 503 marks the delivery `exhausted`
([delivery-state](sinter:#delivery-state=v1)).
```

(Example 3 shows the single-group `### Test vectors` `@schema` section that
closes `retries`.)

**Why this works:**

- **Non-normative prose (2 sentences):** Orients readers on purpose and takes
  ten seconds for the human author to edit.
- **Normative item (stated once, complete `must` sentences):** Combines the
  single-use condition, the `Retry-After` rule (no longer stranded in prose),
  the `rfc/9110` and `rfc/6585` pins, and the complete failure partition (every
  non-temporary failed HTTP status is permanent).
- **`@example` at the end of the item:** Sits directly beside `schedule-retry`,
  hashes separately from `schedule-retry`, and carries checked inline citations
  to both `#retry-policy=v1` and `#delivery-state=v1`.
- **Test vectors settle edge cases:** Malformed `Retry-After` strings, HTTP 408
  vs. 429, `Retry-After: 0`, and `Retry-After > max-delay` live cleanly in
  `webhooks.test-vectors.jsonl`.

---

## Example 2: Data-format specification (audit-log envelope)

### Before (weak)

```markdown
# Audit log
@design audit-log=v1
@cites {rfc/8259, rfc/7493, rfc/3339}
Specifies the JSON envelope format for audit log entries.

An audit record is a UTF-8 byte sequence that matches RFC 8259 JSON-text with
no leading byte order mark, meets RFC 7493 section 2 except that top-level
non-objects are rejected and noncharacters are allowed, holds an object with
keys `ts`, `actor`, and `action`, where `ts` is an RFC 3339 UTC timestamp with
`Z` offset and no leap seconds... From RFC 8259, this design takes JSON syntax.
From RFC 7493, this design takes I-JSON constraints. From RFC 3339, this design
takes timestamp syntax.

## Glossary
| word or phrase | meaning |
|---|---|
| byte | a whole number from 0 to 255 |
| UTF-8 | Unicode encoding per RFC 3629 |
| timestamp | an instant in time; a program gives a timestamp when it gives a value that uniquely identifies that instant |

## Requirements

### Checking envelope bytes

@req check-envelope=v1

When a conforming program checks whether a byte sequence is an audit envelope,
the program must give "valid" when valid and "invalid" otherwise.

### Reading envelope values

@req read-envelope=v1

When a conforming program reads an audit envelope, the program must give that
envelope and no other envelope. A conforming program never gives an envelope
for a byte sequence that is not a valid audit envelope.
```

**Why this fails:**

- The `@design` brief (`Specifies the JSON envelope format...`) is a
  subjectless fragment about the document instead of a complete sentence about
  the domain.
- The introduction restates every normative byte-level rule in non-normative
  prose and appends a mechanical inventory of every cited RFC.
- The Glossary copies basic definitions (`byte`, `UTF-8`) and defines ordinary
  verbs with a tautology (`"gives a value that uniquely identifies that
  instant"`).
- Citing RFC 7493 adds exceptions rather than saving explanation compared to
  narrowing RFC 8259 directly.
- Validation and decoding are split into two artificial `@req` items, and
  ordinary invalid-input rejection is dressed up as a solemn `"never"` safety
  obligation.

### After (strong)

```markdown
# Audit log
@design audit-log=v1
@cites {rfc/8259, rfc/3339}
Services write each audit event as a single-line UTF-8 JSON object with a UTC timestamp.

Log collectors parse and sort these envelopes the same way across programming
languages.

## Audit records

@spec audit-record=v1

### Envelope schema

@schema audit-envelope=v1
@cites {rfc/8259, rfc/3339}

An audit envelope is a valid UTF-8 byte sequence matching an RFC 8259 JSON
object, with these narrowings:

| aspect | rule |
|---|---|
| encoding | No leading UTF-8 byte order mark (`U+FEFF`). |
| object members | No duplicate member names in any object (after escape decoding, without Unicode normalization). |
| required keys | `ts` (string), `actor` (non-empty string), and `action` (non-empty string); no other top-level keys. |
| `ts` format | RFC 3339 `date-time` with uppercase `T` and uppercase `Z` offset (no numeric offsets and no leap second `60`). |

@example `{"action":"login","actor":"ada","ts":"2026-05-01T12:00:00Z"}` is a
valid audit envelope.
`{"action":"login","actor":"ada","ts":"2026-05-01T12:00:00+00:00"}` is invalid
because the timestamp uses a numeric offset instead of `Z`.

### Decoding audit envelopes

@req decode-audit-envelope=v1
@cites #{audit-envelope=v1}

When decoding a byte sequence as an audit envelope, a conforming program must
return the decoded audit envelope if the bytes match `audit-envelope`, and
reject the input with no audit envelope otherwise.
```

**Why this works:**

- **Complete domain brief and 1-sentence intro:** The brief line is a complete
  domain sentence with a subject, the intro adds non-redundant context, and
  `@cites` records the RFC dependencies without a prose inventory.
- **Distinct design and schema names:** The design slug (`audit-log`) and
  schema name (`audit-envelope`) stay distinct in citations and vector file
  names.
- **No unnecessary Glossary or secondary RFC:** Drops basic lower-layer terms,
  drops tautological verb definitions, and narrows RFC 8259 directly instead of
  fighting RFC 7493's mismatches.
- **Declarative `@schema` with trailing `@example`:** States the format
  declaratively, puts concrete valid and invalid inputs in an `@example` block
  hashed separately from the schema, and keeps `must` inside
  `@req decode-audit-envelope`.
- **One direct requirement:** Combines validation and decoding naturally,
  stating invalid-input rejection plainly rather than as a safety invariant.

---

## Example 3: Compact single-group vector schema

### Before (weak)

```markdown
### Test vectors

Vectors for `retries` stand in `webhooks.test-vectors.jsonl`.

#### Retry scheduling vectors

@schema retry-schedule-vector=v1
@cites {rfc/8259, #{schedule-retry=v1}}

The group `retry-schedule` holds the vector lines whose vectors each give a
delivery attempt input and the scheduling output that a conforming program
gives for that input. The requirement of the group is `schedule-retry`.
Durations appear as whole seconds. Each vector has an `input` member, which is
a JSON object with `status` (integer or `"timeout"`), `attempt` (integer >= 1),
`policy` (object with `base-delay`, `max-delay`, and `max-attempts` integers),
and optional `retry-after` (string). Each vector has no `result` member. Each
vector has a `values` member, which is a JSON object with `state` (`"retry"`,
`"exhausted"`, or `"failed"`) and optional `delay` (integer, present only when
`state` is `"retry"`).
```

**Why this fails:**

- Because `retries` has only one vector group, splitting `### Test vectors` and
  `#### Retry scheduling vectors` adds an unnecessary wrapper heading.
- `@cites` pins `rfc/8259` even though this schema never references RFC 8259
  directly (vector-file JSON encoding belongs to the shared test-vector
  format).
- A dense paragraph describes every field instead of a scannable
  `field | type | meaning` table.

### After (strong)

````markdown
### Test vectors

@schema retry-schedule-vector=v1
@cites #{schedule-retry=v1}

Group `retry-schedule` in
[`webhooks.test-vectors.jsonl`](webhooks.test-vectors.jsonl) tests
`schedule-retry`. No vector uses `needs`. Durations are whole seconds.

| field | type | meaning |
|---|---|---|
| `input.status` | integer or `"timeout"` | HTTP status code or transport timeout |
| `input.attempt` | integer (`>= 1`) | 1-based attempt number that just failed |
| `input.policy.base-delay` | integer | initial backoff delay |
| `input.policy.max-delay` | integer | upper bound on retry delay |
| `input.policy.max-attempts` | integer | maximum total attempts |
| `input.retry-after` | string (optional) | raw `Retry-After` response header value |
| `values.state` | string | `"retry"`, `"exhausted"`, or `"failed"` |
| `values.delay` | integer (optional) | scheduled delay; present only when `state` is `"retry"` |

@example Sample line testing [schedule-retry](sinter:#schedule-retry=v1) with
[retry-policy](sinter:#retry-policy=v1) and
[delivery-state](sinter:#delivery-state=v1):

```json
{"form":"#retry-schedule-vector=v1","group":"retry-schedule","input":{"attempt":1,"policy":{"base-delay":10,"max-attempts":3,"max-delay":60},"retry-after":"45","status":429},"note":"429 Retry-After overrides shorter exponential backoff","values":{"delay":45,"state":"retry"}}
```
````

**Why this works:**

- Because `retries` has one vector group, the file link and group `@schema` sit
  directly under `### Test vectors` without an extra wrapper heading.
- The unused `rfc/8259` pin is removed.
- One `field | type | meaning` table with path notation replaces a wall of
  prose, and `result` is omitted because this group does not use it.
- The sample vector line stands inside a trailing `@example` block copied
  verbatim from the vector file, with a lead line inline-citing
  `#schedule-retry=v1`, `#retry-policy=v1`, and `#delivery-state=v1` so Sinter
  flags the sample when those items change while keeping sample edits out of
  the `@schema` hash.
