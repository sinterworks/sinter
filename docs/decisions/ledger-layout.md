<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Keep statements as fixed content-addressed files in `.sinter/`, and number only the job's observations
@decision ledger-layout v2
@cites json-handling
@cites ledger-event-log
Each object of `.sinter/` is one file that holds its canonical bytes at a path from its content id and never changes; only the job's `delivered` and `progress` observations carry a number; an unknown kind is not valid; and any file that is not a valid object file holds back every result over the objects of its tree.

## Context

The record `ledger-event-log` splits the records of the work: statements
live in `.sinter/` on ordinary branches, and only the job writes the log
branch. States follow from edges, so a number that orders statements has
no reader. The earlier layout numbered every entry from 1 to n, ordered
the ledger by that number, wrote a repair entry at each dropped entry,
and ignored an entry of an unknown kind with a warning. In the split
ledger, every branch writes its own statements, and two branches can
never agree on one order. The objects of `.sinter/` are fixed once
written: `.sinter/` is a store of objects named by their content.

## Decision

- **One file for each object.** A file of `.sinter/` holds only the
  canonical bytes of one object, with no id and no final line feed. Its
  path comes from the object's content id: a folder of the first two
  hexadecimal digits, and a file named by the 32 digits. `.sinter/` holds
  declared items, statements, work item objects, `scope` objects, and
  the computed identity objects that they need. An object that holds the
  key of an identity object needs no file for that identity object.
- **Only observations carry a number.** The `delivered` and `progress`
  observations of the log branch carry `seq`. Statements, kept copies,
  and identity objects carry none, and no state depends on `seq`.
- **No unknown kinds.** A file or a line of a kind that the program does
  not know is not valid. A store file is in a newer form, and asks for a
  newer program, only when its path is an object path, its SHA-256 hash
  matches that path, and its bytes are a JSON object whose `v` is an
  integer greater than 1. Every other file that is not a valid object
  file is broken. A regular file at `.sinter/local` is a store file, so
  it fails the check "Form".
- **One bad file holds back the store.** When any store file is not a
  valid object file, the program gives no result over the objects of
  that tree, and the class `invalid-object-file` reports the file. A
  missing identity file keeps the store valid: the class
  `missing-identity-file` reports it, and only the results that need its
  key wait.
- **Writes.** A write of bytes that are already in place succeeds and
  changes nothing. Other bytes, a link, a folder, or a special file in
  the way change nothing and give a report. A failed write of several
  objects leaves no new object whose identity file is missing.
- **Git entries.** The check of a commit reports a symbolic link, a
  submodule, or a name that is not UTF-8 at `.sinter` or inside
  `.sinter/` outside `.sinter/local/`. An executable file mode is
  accepted.
- **Safety.** A program writes and deletes only inside `.sinter/`, never
  through a link, and never changes the content of an existing store
  file, valid or not. In a run that could not read a file, it writes no
  file in `.sinter/`, `.sinter/local/` included. After it reaches a limit
  of its own, it writes and deletes nothing further in that run. It
  deletes only the file of an object that a counting void withdraws, or
  an identity file that no object needs when every store file is valid.
- **Voids instead of repairs.** A void copies the edges of the object
  that it withdraws, apart from edges to computed identity objects, so
  that the graph keeps its shape. No void withdraws a void, an identity
  object, or a `vector-group-def`. The check "Only added" allows the two
  deletions above and nothing else.
- **The log branch** keeps its lines in chunk files under `entries/`,
  and its default name is `sinter-log`.

## Alternatives considered

- **Kept copies carry `seq` and `by` like observations.** Not chosen: no
  state or check reads them on a copy, the envelope would differ from
  the one that Interchange uses, and a retry would renumber the copies.
- **A file name with the kind word, or with 30 digits.** Not chosen: a
  file name of the full 32 digits fits the form of a content id, so a
  search for a content id finds its file.
- **A file that holds an envelope keyed by the id.** Put forward and not
  chosen; no further reason was recorded.
- **Typed subfolders of `.sinter/`.** Not chosen: they invite more
  subfolders and limit which records can go there and how they relate.
- **Newer form by path and JSON object only, or also a canonical line
  object.** Not chosen: the first calls a damaged file newer, so a person
  updates Sinter and the file stays wrong; the second calls a later form
  that widens the object broken.
- **Unknown kinds valid and reported, or ignored with no report.** Not
  chosen: two conforming programs would give different states for the
  same objects, and the second loses records with no word.
- **A broken file holds back only the results that read statements, or
  only that file is skipped.** Not chosen: the first misses a duplicate
  or gives a wrong current revision; the second ignores a newer or
  mistyped decline or `abandoned`.
- **A missing identity file makes the store not valid.** Not chosen: one
  absent file would hold back results that do not need it.
- **Any existing file stops a write.** Not chosen: a program would have
  to look for each identity file first, and two writers of the same
  object would fail.
- **No check of git entries, or the Object store checks them.** Not
  chosen: a checkout without symbolic links gets a stray store file that
  holds back every result, and the Object store would depend on Changes.
- **Safety only for valid object files, or no rule for deletions.** Not
  chosen: the rule would not bind where a program is most likely to
  overwrite a file, and a committed link such as
  `.sinter/local -> ../../..` would let a deletion remove files outside
  the repository.
- **No deletion by any program.** Not chosen: a person would have to find
  which identity files no object needs.
- **Voids of work item objects or of every identity object.** Not chosen:
  records and waits would lose the thing that they name, and a void could
  ban an identity key from `.sinter/` for good.
- **The name `sinter-ledger`.** Not chosen: the branch holds only the
  job's records, and `sinter-log` matches the term.

## Consequences

A new kind of object needs a new version of the designs, and every clone
and run of CI must update before Sinter gives results over a store that
holds it. One bad file in `.sinter/` holds back the results on text items
too, but only in a tree whose failed check "Form" somebody merged. No
program repairs a broken file in place; a person repairs it in a change.
A program that keeps a cache in `.sinter/local/` cannot update it in a
run that could not read a file. An implementation writes a store file in
`.sinter/local/` and then renames it into place, so that a partial write
never leaves a broken store file.
