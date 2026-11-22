#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The Sinter Authors

set -eu

# @cites bridge-build-folders
# Cargo builds the bridge outside _build, in a directory named from the
# content of the crate. Checkouts with the same crate content share one
# directory, and each build removes other directories unused for 7 days.
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
exec sh "$here/../cargo-build.sh" \
  --cache-name sinter-bridge-build \
  --require-cmake \
  "$@"
