<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Name each cargo build folder from the content of its crate
@decision bridge-build-folders
@cites rust-bridge
Cargo writes the output of the Rust bridge to a build folder whose name is a hash of the content of the crate, so that checkouts with the same content share the folder, and a build removes the build folders that no build used in the last 7 days.

## Context

A checkout is a clone or a git worktree of the repository.
Contributors, and the coding agents that work for them, work on Sinter
in many checkouts at once.

The `sinter` binary links the Rust bridge, a Rust crate in `bridge/`
that loads tree-sitter grammars (record `rust-bridge`). A crate is a
unit of Rust code that cargo, the build tool of Rust, compiles. The
crates that the bridge uses are its dependencies. Dune, the build
system of the OCaml code of Sinter, builds the bridge in a dune rule,
which is one step of the build. In this record, a build is one run of
that dune rule. The dune rule runs cargo. Then the dune rule copies the
static library that cargo makes, `libsinter_bridge.a`, into `_build`,
the folder where dune keeps its output.

Cargo writes its own output to a build folder outside `_build`. Dune
empties the folder of a dune rule before the dune rule runs. So a build
folder inside `_build` would make cargo compile the bridge and all its
dependencies, 128 crates in total, again after each edit of a file in
`bridge/` (record `parser-bridge`).

All build folders are in one parent folder. The parent folder is the
folder that `CARGO_TARGET_DIR` names when that variable is set. In
cargo, `CARGO_TARGET_DIR` names the build folder itself; here it names
the parent folder. When `CARGO_TARGET_DIR` is not set, the parent folder
is `$XDG_CACHE_HOME/sinter-bridge-build` when `XDG_CACHE_HOME` is set,
and `~/.cache/sinter-bridge-build` when `XDG_CACHE_HOME` is not set.

Before this record, the dune rule used path naming: each checkout had a
build folder of its own, named from a hash of the path of the crate. A
cold build is a build that compiles every dependency. A cold build took
68 seconds and used 480 MB in the measurement of `parser-bridge`, and 28
to 29 seconds and about 640 MB in the measurement below. `dune clean`
does not remove a build folder. `CONTRIBUTING.md` gave a shell loop,
which a contributor ran by hand, that removed a build folder only when
its checkout was gone. Contributors delete few checkouts, so on one
machine the build folders grew to hundreds of GB.

The checkouts cannot simply share one build folder. Cargo decides that
a crate from a local folder needs no new compilation when its source
files are older than the last build in the build folder. When
checkouts share one build folder, a checkout whose source files are
older than the last build gets the static library that cargo built for
another checkout, and nothing warns. `parser-bridge` reports this fault
("Alternatives considered").

## Decision

- **Scope.** Every crate that a dune rule builds with cargo follows
  content naming, in the same parent folder. Today that crate is the
  bridge.
- **Content naming.** The name of a build folder is the first 32
  lowercase hexadecimal digits of a SHA-256 hash of the content of the
  crate. The content includes the path of each subfolder of the crate,
  relative to the folder of the crate. For each file, the content
  includes its relative path, its bytes, and its executable bit. For
  each symbolic link that does not point to a folder, the content
  includes its relative path and the target that the link names. When
  the link reaches a file, the content also includes the bytes of that
  file. The content includes changes that are not committed, files that
  git does not track, and files that git ignores. The content leaves out
  three things: the folder `target/` at the top of the crate, where a
  run of cargo by hand writes its output; the folder or file `.git` at
  the top of the crate; and every file named `.DS_Store`. The path of the checkout and the times
  of the files are not part of the name. When the crate holds a
  symbolic link to a folder, the build stops with an error.
- **Sharing.** Checkouts whose crates have the same content use the
  same build folder. A build folder holds the output of the crate for
  only one content: the content that its name hashes. So cargo's check
  by file times cannot give one checkout the static library of other
  content.
- **Cargo on each build.** The dune rule never skips cargo, even when
  the build folder already holds a finished library. Cargo keeps a
  record of the inputs of each compilation. With that record, cargo
  compiles again when the configuration that cargo uses changes, when
  the compiler changes, or when an environment variable changes that a
  build script declares. A build script is a program that a crate runs
  before cargo compiles that crate.
- **A new build folder starts as a copy.** Each build folder holds a
  file `package` that names its crate. When no build folder exists for
  the content of the crate, the build copies the build folder of the
  same crate that a build on the machine used most recently, whatever
  the content of that folder. When the file system supports
  copy-on-write copies, the build makes a copy-on-write copy: each
  copied file shares the disk blocks of its original until one of the
  two files changes. Before cargo
  writes to the copy, the build removes all output of the crate itself
  from the copy. Cargo then compiles the crate and each dependency that
  changed, and keeps the other compiled dependencies. The crate
  registry is the public store from which cargo downloads dependencies.
  Cargo decides whether a dependency from the crate registry or from a
  git repository is up to date from its version or its commit, the
  optional parts of the dependency that the build turns on, and the
  compiler, not from file times. So cargo never uses a copied dependency
  that is out of date.
- **Removal after 7 days.** Each build sets the modification time of a
  file `last-used` in its build folder. A build first makes or copies
  its own build folder and runs cargo. Then the build removes each other
  folder of the parent folder that meets all of these conditions:
  - its name has the form of a name of content naming or of path
    naming, which is 16 or more lowercase hexadecimal digits;
  - when it holds the file `last-used`, that file is 7 days old or
    older;
  - when it holds no file `last-used`, it holds at least one of the
    files that content naming, path naming, or cargo write into a build
    folder (`package`, `checkout`, `native-static-libs.log`, or
    `CACHEDIR.TAG`), and each of those files that it holds is 7 days old
    or older;
  - no build holds the lock of that folder;
  - it is not a symbolic link.
  A build that runs holds a lock on its build folder, and a build that
  copies a build folder holds a lock on that folder during the copy.
  The output that other programs write to the parent folder, such as
  the folders `release/` and `debug/` of cargo, has no such name, so the
  removal never touches it.
- **The pinned toolchain.** The pinned toolchain is the exact Rust
  version that the file `rust-toolchain.toml` of the crate names. Cargo
  starts in the folder of the crate, so rustup, the installer of Rust
  toolchains, reads that file. The pinned toolchain then compiles the
  crate. Before this record, the dune rule started cargo outside the
  folder of the crate. So rustup did not read the file, and a build used
  the default toolchain of the machine, although `parser-bridge` and
  `rust-bridge` choose the pinned toolchain. This record makes that
  choice apply to builds.
- **The earlier records.** Content naming replaces one choice of
  `parser-bridge` that the first revision of `rust-bridge` kept: one
  build folder for each checkout. The second revision of `rust-bridge`
  names this record and keeps the other choices of both records.

## Alternatives considered

- **Path naming: one build folder for each checkout.** Not chosen: the
  disk use grows with the number of checkouts, and each new checkout
  needs a cold build.
- **Path naming with automatic removal of the build folders whose
  checkout is gone or that no build used for a set time.** Not chosen:
  the disk use still grows with the number of checkouts that builds
  used in that time, and each new checkout still needs a cold build.
- **No change to the build.** Contributors would remove finished
  checkouts and empty the parent folder from time to time. Not chosen:
  a cleanup by hand depends on habit, and the parent folder grows with
  each new checkout until the next cleanup.
- **One build folder that all checkouts share, with no hash of the
  content in its name.** Not chosen, as `parser-bridge` reports: a
  checkout can link the static library of another checkout without a
  warning.
- **Skip cargo when the build folder already holds a finished library,
  and add the configuration of cargo to the hash, so that a change of
  the configuration gives a new build folder.** Not chosen: cargo and
  the build scripts of the dependencies read configuration files and
  environment variables that no fixed list covers. In a test of this
  alternative, each of three inputs outside such a list gave a wrong
  library without a warning: the variable `CARGO_BUILD_RUSTFLAGS`, the
  variable `CARGO_TARGET_<TRIPLE>_RUSTFLAGS` (where `<TRIPLE>` is the
  name of the target platform, such as `AARCH64_APPLE_DARWIN`), and a
  `.cargo/config.toml` in a parent folder of the crate. In a second
  checkout of the same commit, a build that skipped cargo took about
  0.3 seconds. A build that runs cargo takes about 0.4 seconds when the
  files of the checkout are older than the last build, and about 1.7
  seconds when they are newer, because cargo then compiles the crate
  again.
- **Copy only a build folder with the same `Cargo.lock`.** Not chosen:
  cargo checks each dependency from the crate registry by its version,
  not by file times, so a copy with another `Cargo.lock` gives the
  right library. With this condition, each update of the dependencies
  would need a cold build.
- **Removal after 14 days without use.** Not chosen: the build folders
  of old content would stay twice as long. A build folder that a build
  needs again after 7 days costs little, because the next build copies
  another build folder of the crate. Seven days cover a pause of a
  working week in a checkout.

## Consequences

The project measured these numbers on 2026-11-20 on an Apple silicon
machine with the APFS file system and rustc 1.99.1. Each time is the
time of the build of the bridge alone:

| case | time to build the bridge | new disk use |
|---|---|---|
| cold build in an empty parent folder | 28 to 29 seconds | about 640 MB |
| a second checkout of the same commit | 0.4 seconds; about 1.7 seconds when its files are newer than the last build | none |
| a build after an edit of one line of the crate | 1.7 to 1.9 seconds | about 107 MB |

- The disk use grows with the number of different crate contents that
  builds used in the last 7 days, not with the number of checkouts.
- On a file system without copy-on-write copies, such as `ext4`, each
  new crate content needs a full copy of about 640 MB. A full copy of
  that size took 0.47 seconds on the measured machine. The copy stays
  until the first build that runs 7 days or more after its last use.
- When a build needs a build folder that another build removed, the
  build copies another build folder of the crate and compiles the crate
  again. The build needs a cold build only when no build folder of the
  crate remains.
- The first build under content naming on a machine removes the build
  folders of path naming that no build used in the last 7 days. On a
  machine with many such folders, that build takes longer.
  `CONTRIBUTING.md` no longer gives the shell loop, because each build
  removes old build folders.
- A contributor needs the pinned toolchain, installed with rustup. When
  cargo does not come from rustup, cargo does not read
  `rust-toolchain.toml` and uses the compiler on the `PATH`. Cargo's
  record of each compilation still notices a change of that compiler.
- The build needs a SHA-256 program, `sha256sum` or `shasum`. When
  neither is present, the build stops with an error. The build also
  needs a program that can lock a file, `perl` or `flock`. When neither
  is present, the build stops with an error.
- `dune clean` still does not remove the build folders.
- A crate under content naming must not read a source file from outside
  its folder, and must not depend on another crate from a local folder.
  If the hash missed a file, a checkout could link a static library of
  other content, with no warning. A contributor runs the by-hand check
  in `bridge/README.md` after each change of `lib/cargo-build.sh` or
  `lib/bridge/build.sh`. That check confirms that each of two checkouts with
  different content links the static library of its own content. A step
  of CI checks that a change of a file of the crate changes the name of
  its build folder.
