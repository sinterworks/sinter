#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The Sinter Authors

set -eu

tree_sitter=$1
sources=$2
toolchain=$3
out=$4

clang=${SINTER_WASM_CC:-clang}
fix="Install LLVM's clang (on macOS: brew install llvm), and set SINTER_WASM_CC to its path."
if ! command -v "$clang" >/dev/null 2>&1; then
  echo "The core of the grammars needs a C compiler with the WebAssembly back end, and $clang is not on the PATH. $fix" >&2
  exit 1
fi
if ! printf '' | "$clang" --target=wasm32 -x c -c - -o probe.o >/dev/null 2>&1; then
  echo "The core of the grammars needs a C compiler with the WebAssembly back end, and $clang has no back end for the target wasm32. $fix" >&2
  exit 1
fi

channel=$(sed -n 's/^channel *= *"\([^"]*\)" *$/\1/p' "$toolchain")
if [ -z "$channel" ]; then
  echo "The Rust toolchain of the WebAssembly engine names no channel." >&2
  exit 1
fi
RUSTUP_TOOLCHAIN=$channel
export RUSTUP_TOOLCHAIN
sysroot=$(rustc --print sysroot)
host=$(rustc -vV | sed -n 's/^host: *//p')
linker=$sysroot/lib/rustlib/$host/bin/rust-lld
if [ ! -x "$linker" ]; then
  echo "The Rust toolchain $channel has no rust-lld at $linker." >&2
  exit 1
fi

flags="--target=wasm32 -O2 -mcpu=mvp -mmutable-globals -msign-ext -mnontrapping-fptoint -mbulk-memory -mmultivalue -mreference-types -std=c11 -ffreestanding -nostdlib -fvisibility=hidden -DTREE_SITTER_WASM_STDLIB -DNDEBUG"
includes="-I$tree_sitter/lib/src -I$tree_sitter/lib/include -I$tree_sitter/crates/language/wasm/include"

"$clang" $flags $includes -c "$tree_sitter/lib/src/lib.c" -o lib.o
"$clang" $flags $includes -c "$sources/alloc.c" -o alloc.o
"$clang" $flags $includes -c "$sources/driver.c" -o driver.o
"$linker" -flavor wasm --no-entry --stack-first -z stack-size=1048576 \
  --export-table --growable-table --export=__stack_pointer --strip-all \
  -o "$out" lib.o alloc.o driver.o
