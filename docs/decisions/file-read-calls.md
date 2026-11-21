<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Make the POSIX calls of the file read through C stubs of Sinter's own
@decision file-read-calls
@cites repository-file-reads
@cites licensing
@cites current-dependencies
The library `sinter.file_read`, which makes the file read of the design Files and paths, makes the POSIX calls that the OCaml `Unix` library lacks, or cannot report correctly, through C stubs of Sinter's own: small C functions that OCaml code calls through an `external` declaration.

## Context

POSIX (POSIX.1-2024) is the standard interface of Unix-like systems.
The design Files and paths (`docs/designs/files.md`) defines a file read that follows no symbolic
link of the folder tree, also while another process changes the folder
tree, and that works for a path longer than the system allows in one
pathname. So the read opens one folder at a time, and it finds the
file that each file name names relative to the folder that is open. The
read also compares the UTF-8 encoding of each file name, byte for byte,
with the names in the listing of its folder. File name and listing have
the meanings of the design. The caller of the file read gives the root
as a pathname. A symbolic link in that pathname is not a file of the
folder tree, so the system can follow it.

Besides `fstat`, `read`, and `close`, which the `Unix` library has, the
read needs these POSIX calls:

| call | what the file read uses it for |
|---|---|
| `openat` from the current folder with `O_DIRECTORY` | opens the root |
| `openat` with `O_DIRECTORY` and `O_NOFOLLOW` | opens the next folder relative to the open folder, and fails on a symbolic link |
| `openat` with `O_NOFOLLOW` and `O_NONBLOCK` | opens the file that the last file name names, fails on a symbolic link, and does not wait for a process at the other end of a pipe |
| `fstatat` with `AT_SYMLINK_NOFOLLOW` | gives the type of a file of the folder tree, not of the file that a symbolic link leads to |
| `faccessat` with `AT_EACCESS` | tells whether the program has the search permission for a folder |
| `fcntl` with `F_DUPFD_CLOEXEC`, `fdopendir`, `rewinddir`, `readdir`, and `closedir` | give the listing of an open folder, from a copy of its file descriptor, for the comparison byte for byte |

The `Unix` library of OCaml 5.5 has none of the calls `openat`,
`fstatat`, `fdopendir`, and `faccessat`, and none of the flags
`O_DIRECTORY`, `O_NOFOLLOW`, `AT_SYMLINK_NOFOLLOW`, and `AT_EACCESS`. Its
`readdir` reports the end of the folder when the system gives an error,
so a read error looks like a short listing. It has no constructor for
the error `EILSEQ`, which a system can give when the file system does
not accept a name as an entry name (the byte sequence that names a file
in a folder). It reports that error as `EUNKNOWNERR` with the number of
the error, and that number is not the same on each system. For a name
that the file system does not accept, the file read of the design gives
"no file", and the error is not a failure of the system.

The record `repository-file-reads` made the
same choice for the read of repository files (`lib/repo_file.ml`), with
one C stub for `openat`.

## Decision

- The library `sinter.file_read` has its own C stubs for `openat`,
  `fstatat`, `faccessat`, and the listing of a folder, and a stub that
  gives the number of the error `EILSEQ`.
- The stub for the listing tells a read error from the end of the
  folder.
- The C stubs make the calls. The OCaml code of the library chooses
  every result of the file read, so that the coverage measurement and
  the mutation tests reach each such choice.

## Alternatives considered

A package binds a C call when it gives an OCaml function that makes the
call.

- **The opam packages `posix-stat` and `posix-unistd` 4.0.2** (MIT,
  built on `ctypes`, an OCaml library for calling C functions). Not
  chosen. They do not bind `openat`, the open flags, `fdopendir`, or
  `faccessat`. The system gives each open file a number, its file
  descriptor. Their `fstatat` takes the file descriptor 0 to mean the
  current folder. When standard input is closed, the system can give 0
  to a folder that the read opens, and the read then looks up a name in
  the wrong folder. A failed system
  call stores the number of its error in the C variable `errno`. They
  read `errno` in a separate call after the system call, so OCaml code
  that runs between the two calls, such as a handler of a signal, can
  change `errno` before they read it. They have one maintainer, and no
  users on opam other than `posix-bindings`, which bundles them.
- **The opam package `posixat` v0.17.0** (MIT). Not chosen. It binds
  `openat`, `fstatat`, `faccessat`, and `fdopendir`, but not a
  `readdir` that tells an error from the end of the folder, so Sinter
  would still have its own C. Its opam file accepts only the v0.17 line
  of `base`, `ppx_optcomp`, and `ppx_sexp_conv`, and its last release
  is from May 2024. So, under `current-dependencies`, Sinter could not
  move `base`, `ppx_optcomp`, or `ppx_sexp_conv` past the v0.17 line
  until `posixat` had a new release.
  The unreleased code on its `master` branch includes
  the Linux header `linux/openat2.h` on every system, not only on
  Linux, so its next release may not build on macOS.
- **The opam package `eio_posix` 1.6** (ISC). Not chosen. It binds
  `openat`, `fstatat`, and a listing of a folder, but with them it
  brings Eio, a library for concurrent input and output for OCaml 5, and the packages that Eio
  needs. It has no `faccessat`, so Sinter would still have its own C.
- **The opam package `extunix` 0.4.4** (LGPL-2.1 with the OCaml linking
  exception). Not chosen. It binds `openat` and `fstatat`, but
  `licensing` allows LGPL only for the OCaml runtime.
- **Only the `Unix` library, with no C.** Not chosen. Without `openat`
  and `O_NOFOLLOW`, the system finds each file from a pathname, and it
  can follow a symbolic link that another process puts in place during
  the read. A pathname from the root also fails when it is longer than
  the system allows.

## Consequences

The library holds about 150 lines of C, which the coverage measurement
and the mutation tests do not reach. Only tests that read real folder trees,
on Linux and on macOS, check the C code.
Sinter has two reads of files, `lib/repo_file.ml` for repository files
and `sinter.file_read` for the file read of the design. Each has its own
C stub that calls `openat`: `lib/repo_file_stubs.c` and
`lib/file_read/file_read_stubs.c`. Sinter builds C in any case,
for the parser bridge.
