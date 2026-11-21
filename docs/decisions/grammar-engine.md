<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Run grammars in Sinter's own WebAssembly store, with tree-sitter's core compiled to WebAssembly
@decision grammar-engine
@cites rust-bridge
@cites current-dependencies
Sinter parses a text with a grammar inside a store of Sinter's own WebAssembly engine, where the code of the grammar and tree-sitter's core, compiled to WebAssembly, run together, and it matches ECMA-262 patterns with QuickJS's libregexp.

## Context

The design Language packs (`docs/designs/packs.md`) requires that the
code of a grammar reaches nothing outside its WebAssembly sandbox
(requirement `isolate-grammars`), and that a program can stop that code
(requirement `end-grammar-code`). The bridge of the record `rust-bridge`
parses through the WebAssembly support of tree-sitter itself. A review
of tree-sitter 0.26.13 found three gaps in that support:

1. Its native code reads the parse tables of a grammar with no check of
   the indices in them, so a malformed grammar can make it read outside
   the memory of the grammar.
2. It calls the lex and scanner functions of a grammar through indices
   that the grammar gives, with no check of their types.
3. It makes the wasmtime store of a grammar itself, so Sinter can set
   no fuel and no memory limit on it, and the code of a grammar can run
   without end.

## Decision

- tree-sitter's core (its C library, version 0.27.2) is compiled to a
  WebAssembly module, the core module. Each parse runs in Sinter's own
  engine, in a new instance of the core module, with the grammar linked
  to it. Sinter itself links the grammar, gives it only the imports that
  the core module exports, and copies each result out of the memory of
  the instance with a check.
- The store of the instances runs under fuel (a count that falls as
  code runs and stops the code at zero) and a memory limit. Fuel now
  works for grammars because the store is Sinter's: Sinter gives it
  fuel before tree-sitter's code starts. In `rust-bridge`, tree-sitter
  made the store, and its start code ran out of fuel.
- The engine is wasmtime, at its newest release, set to exactly
  WebAssembly Core 2.0. The reference interpreter (the opam package
  `wasm`) checks the validity of WebAssembly modules in the tests.
- tree-sitter's C query engine runs inside the core module. Sinter
  applies the ten predicates of the design to its raw matches, in OCaml.
- QuickJS's libregexp matches texts against ECMA-262 patterns (the
  regular expressions of the JavaScript standard), in a small library of
  its own, under a fixed limit of steps. A pattern that reaches the
  limit fails the parse.
- Each build compiles the core module from the C source of
  tree-sitter. The repository holds no built core module. On macOS,
  the build may require LLVM's own `clang`, because the `clang` of
  Xcode can lack the WebAssembly back end; that requirement holds until
  the `clang` of Xcode can compile WebAssembly.
- Sinter keeps no cache of compiled modules: it compiles the core
  module and each grammar at each start.

## Alternatives considered

- **Check the tables of each grammar when it loads, and change
  tree-sitter so that it sets limits on the store of each grammar.** Not
  chosen: the check is only as good as an audit of tree-sitter's native
  code, and each release of tree-sitter needs the audit again.
- **Parse in a helper process, under the sandbox of the operating
  system.** Not chosen: each platform needs a sandbox of its own, a
  timer must kill a process that runs too long, and each parse needs a
  process start or a pool of processes.
- **Epochs (a signal that stops code after a time) in place of fuel.**
  Not chosen: fuel stops the same code at the same point on every
  machine, and it costs little more (measured below).
- **wasmi, or the reference interpreter, as the engine.** Not chosen:
  both are slower than wasmtime.
- **The Rust crate `regress` for patterns.** Not chosen: its limit of
  steps is in no release (not in 0.12.0). **The opam package
  `ecma-regex`.** Not chosen: it is new, it has one author, and it has
  no limit of steps.
- **A query engine of Sinter's own.** Not chosen: it would be some
  thousands of lines, and its results could differ from those of
  tree-sitter, which the authors of packs use.
- **wasi-sdk, a toolchain made for WebAssembly, in place of `clang`.**
  Not chosen: a `clang` with the WebAssembly back end compiles the core
  module on each platform (on macOS, LLVM's own `clang`), and wasi-sdk
  would be one more download.
- **A built core module in the repository, checked by CI, alone or
  beside a build from the source.** Not chosen: CI gives the same bytes
  only with the `clang` that built the module, and two ways to make the
  module must both keep working.
- **A cache of compiled modules.** Not chosen for now: wasmtime runs
  such a cache as native code with no check, so the cache would need a
  file that only Sinter writes. The Security design weighs such a cache
  later.

Nobody put forward another choice for the setting of exactly Core 2.0,
or for a new core instance for each parse.

## Consequences

A fault in a grammar, or a parse that does not end, stops inside the
store, and no native code reads the tables of a grammar. Each developer,
CI job, and user who builds Sinter needs a `clang` with the WebAssembly
back end. tree-sitter no longer fixes the version of wasmtime (0.27.2
pins wasmtime 48; Sinter's engine uses 50.0.1). Until Sinter's commands
parse with this engine, they parse through the bridge of `rust-bridge`,
which keeps its cache of compiled modules.

Measured on 2026-11-15 on an Apple M5 with macOS 27.2, as warm medians,
on the grammars and files of the repository at 383a813b: a parse in the
core module, with fuel on its store, takes 0.52 to 0.70 times the time
of the same parse through the bridge, and with epochs in place of fuel
0.52 to 0.65 times. The core module compiles in 105 ms and the markdown
grammar in 82 ms; from a cache, either would load in under 0.1 ms.
