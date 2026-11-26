<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Build in only the markdown pack; read every other pack from a local folder until pack distribution
@decision local-pack-folders
@supersedes pack-delivery v2
@cites rust-bridge
The markdown pack stays built into Sinter, and in v0.1 the pack of every other language comes from a local folder for that language, which the project's settings name; v0.1 fetches no pack, and pack distribution follows soon after v0.1.

## Context

A language pack is a grammar and the queries that tell Sinter where
tags stand in one language. The record `pack-delivery` v2 built in only
the markdown pack and fetched every other pack from a packs repository,
checked by its SHA-256 hash and recorded in a lock file, with
`sinter pack add` and a user cache, all before the first useful
version.

The scope of v0.1 narrows to the core of Sinter: the command line and
continuous integration. A packs repository, a fetch command, a lock
file, and a cache are a whole subsystem, and none of them is needed to
check a repository when the packs are already on the machine. A fetch
also brings code into Sinter's parser from outside the repository's own
setup, which the Security design must weigh.

## Decision

- The markdown pack stays built into the program and changes with it.
  Plans, decision records, and rule files are markdown, so every
  project can read them with no setup.
- In v0.1, the project's settings name a local folder for each other
  language, which holds that language's pack. Sinter reads each pack from
  its folder and checks it as the design Language packs specifies.
- v0.1 fetches no pack. `sinter pack add`, the lock file, the user
  cache, and the packs repository move to pack distribution, which the
  roadmap holds as a fast-follow after v0.1.

## Alternatives considered

- **Build every pack of v0.1 into the program, and defer pack
  distribution.** Not chosen: it puts every grammar into the binary and
  makes every language but markdown move later from built-in to
  fetched, which the record `pack-delivery` v2 already rejected.
- **Keep fetching every pack but markdown in v0.1** (the record
  `pack-delivery` v2). Not chosen: it puts the whole distribution
  subsystem into v0.1, where a local folder gives the same check.

## Consequences

A project that checks code in a language other than markdown places
that language's pack in a folder and names the folder in its settings.
The Manifest keeps a setting for the pack folder of each language and no
keys for fetched packs. The Security design treats a pack folder as part
of the owner's own setup. In v0.1, nothing checks that two machines
read the same pack; each project's own setup, for example in CI,
provides the folders, and the lock file of pack distribution later adds
that check. Pack distribution also adds fetching and the cache without
changing how a pack is read.
