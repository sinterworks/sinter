<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Make every item and record an object with one canonical form and one hash, whatever its encoding
@decision canonical-objects
@cites ledger-event-log
@cites ledger-layout
@cites sha256
Every item and every record of Sinter is an object with one canonical byte sequence and one SHA-256 content hash; text in files and the store `.sinter/` are two encodings of the same objects; every result is defined over the canonical objects; and a program that could not read a file, or that reached a limit of its own, gives no result that rests on what it missed.

## Context

The designs hashed a declared item by the normalized text of its extent,
kept the records of the work in one sequence under a ref of its own, and
treated a JSON line as something derived from text, never a source. The
split ledger (record `ledger-event-log`) puts statements as files in
`.sinter/` (record `ledger-layout`), and an item can then live either in
a text file or in `.sinter/`. When the hash depends on where an item
lives, a move from one place to the other changes every result that
names the item, and two programs can disagree about the same item.

## Decision

- **Objects and encodings.** Every item and every record is an object
  with one canonical form: one canonical byte sequence and one SHA-256
  content hash. Text in files and `.sinter/` are two encodings of
  objects. Findings are not objects, because Sinter computes them. Tests,
  sites, persons, agents, and commits get no object now. A claim from
  code keeps its file and line beside the edge, not inside it. In v0.1,
  no record uses the text encoding: definitions, judgments, and voids
  live in `.sinter/`, and observations live on the log branch.
- **Results over canonical objects.** Every result is defined over the
  canonical objects. Every conforming program reads the encodings that
  the designs define. A program's own store is valid only when it gives
  exactly the canonical objects. Places in inputs, such as spots and
  fixes, and the rules that read an encoding itself, follow the
  encoding. So a promise is kept only by a citation in a text file inside
  the task's paths.
- **Ids.** A content id is the object's own `kind` word, a colon, and the
  first 32 hexadecimal digits of its content hash. The kind word never
  enters a hash, and no kind is called `object`. A citation by content
  id resolves against the tree and the unwithdrawn kept objects, as a
  pin does.
- **Items in `.sinter/`** follow the rules of items in text: two current
  revisions of one name give `duplicate`, and a void may withdraw an
  item.
- **Vector files.** A parameter `vector-paths` locates vector files. It
  never includes files of `.sinter/`, and a file whose name ends with
  `.test-vectors.jsonl` that no design names gets a finding.
- **Read errors.** A refused permission, an input or output error, or a
  system that offers no operation that keeps the program's safety
  obligations makes the unread content a missing part. In a run that
  could not read a file, a program writes nothing durable and makes no
  fix.
- **Limits.** When a program reaches a limit of its own, it ends that
  run, reports where it reached the limit as far as it can, gives no
  other result of that run, and writes nothing durable after it reaches
  that limit. Code that a program ends at its own bound on time, steps,
  or call depth counts as code that never ends, which is a fault of the
  input. An adapter call fails when its request or its report has 4 GiB
  or more.
- **Fetches.** A check fetches no ref and calls no host, but git may
  fetch the objects that a partial clone left out.
- **Acknowledgments.** In v0.1, only the finding `retired` takes an
  acknowledgment, and only when the cited item has no successor.
- **Removed features.** The edge member `outcome` and the feature
  `every-part` go.

## Alternatives considered

- **A principle for v0.1 only, with other encodings on the roadmap.** Not
  chosen: this is how Sinter works in every part, so the settled designs
  take the cost of the change now.
- **The hash of whatever bytes are stored.** Not chosen in favor of one
  hash of the canonical form, so that a move between encodings keeps the
  hash.
- **Only the listed kinds are objects, or findings are objects too.** Not
  chosen: the first needs an exception in the rule of canonical objects;
  the second lets `.sinter/` hold kinds that have no meaning there and
  stores what Sinter computes.
- **Only spots, marks, and fixes follow the encoding, or the earlier
  terms widen to both encodings.** Not chosen: the first needs new
  mechanisms that nobody designed; the second lets a move between
  encodings change the findings on an object.
- **A text form for task and plan definitions, or for every record.** Not
  chosen: checks would read definitions that change in place, and a
  judgment would lose its target when a person edits the definition. A
  text form for definitions is on the roadmap.
- **Two hashes, one of normalized text and one of canonical bytes.** Not
  chosen: one canonical form needs one hash.
- **Ids with a prefix such as `o-`.** Not chosen: the dash style does not
  fit the other forms.
- **Items in `.sinter/` follow the rules of statements.** Not chosen: the
  same fault would give `duplicate` in text and a conflict in `.sinter/`.
- **Vector files found by name alone, or a move of a design that needs a
  second move of its vectors.** Not chosen: the first loses tests
  silently, and the second is a smaller trap of the same kind. A
  misnamed vector file gets a finding instead of a silent skip.
- **A read error as a limit, as a class of its own, or split by cause.**
  Not chosen: two runs with the same permissions could give different
  findings, and the other two add rules for one observable result.
- **For a missing safe system operation: widen the term of limits, bind
  only where the operations exist, or a rule for safety obligations
  alone.** Not chosen: under those rules a run could still write durable
  state that does not rest on the skipped file, which the rule on read
  errors declines to trust.
- **A fix that needs no missing part is allowed after a read error.** Not
  chosen: each program would judge which fixes need the unread file, and
  a wrong judgment edits a file from a partial view.
- **Best-effort results at a limit.** Not chosen: the rules for partial
  results grew complex, and ending the run gives the same safety.
- **An adapter input of 4 GiB or more is not valid, or no rule.** Not
  chosen: the first makes a sharp step between readers, and the second
  leaves the later steps undefined.
- **No fetch at all during a check.** Not chosen: it bans ordinary
  behavior of git.
- **A citation by content id stays `dangling` when the tree lacks the
  object, or gives neither `suspect` nor `dangling`.** Not chosen: two
  identical canonical edges would give different findings.
- **An edge of an item in `.sinter/` keeps a promise, or task paths name
  `.sinter/`.** Not chosen: a promise could be kept with no work.
- **No acknowledgments in v0.1.** Not chosen: a tag whose only effect is
  a failure is a trap.
- **`every-part` and `outcome` as members of edges.** Not chosen: no use
  was clear, and the structure of edges gives the same conclusion.

## Consequences

The change reaches the settled designs of the lowest layers now, and it
widens v0.1 beyond its core for this part. A new label, a pin update, or
a new `supersedes` edge makes a new object that needs its own approval.
An agent that writes its work as items in `.sinter/` cannot keep a
`satisfies` promise. Each design must say which results need which files,
so that a missing part holds back only those results. The design notes,
which said that JSON lines are never a source, are retired.
