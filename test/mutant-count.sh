#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The Sinter Authors

set -eu

usage() {
  echo "Usage: test/mutant-count.sh [-c <revision>]" >&2
  echo "Prints the number of mutants that a pass tests: every mutant, or with -c, the mutants on the lines that changed since <revision>." >&2
  echo "With -c, it runs mutaml-runner with a test command that always passes, and it replaces the file mutaml-report.json." >&2
  echo "Start it at the root of the project, after a build with --instrument-with mutaml." >&2
  exit 2
}

since=
while getopts c: option; do
  case $option in
    c) since=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ "$#" -eq 0 ] || usage

side=_build/.mutaml/default
list=$side/mutaml-mut-files.txt
if [ ! -f "$list" ]; then
  echo "mutant-count.sh: there is no list of mutation files at $list." >&2
  echo "Build the code instrumented, at the root of the project:" >&2
  echo "  dune build @check --instrument-with mutaml" >&2
  exit 2
fi

if [ -z "$since" ]; then
  files=$(LC_ALL=C sort -u "$list")
  if [ -z "$files" ]; then
    echo "mutant-count.sh: the list $list names no mutation file." >&2
    exit 1
  fi
  set --
  while IFS= read -r file; do
    set -- "$@" "$file"
  done <<EOF
$files
EOF
  (cd "$side" && jq -n '[inputs | .mutants | length] | add' "$@")
  exit 0
fi

log=_mutations/count.log
mkdir -p _mutations
rm -f mutaml-report.json
status=0
mutaml-runner --build-context _build/default \
  -j "$(getconf _NPROCESSORS_ONLN)" \
  --changed-since "$since" true >"$log" 2>&1 || status=$?
if [ "$status" != 0 ] || [ ! -f mutaml-report.json ]; then
  echo "mutant-count.sh: mutaml-runner could not choose the mutants on the changed lines:" >&2
  sed 's/^/  /' "$log" >&2
  exit 1
fi
if grep -q '^Skipping ' "$log"; then
  echo "mutant-count.sh: mutaml-runner skipped a mutation file:" >&2
  grep '^Skipping ' "$log" | sed 's/^/  /' >&2
  echo "Run dune clean and build again." >&2
  exit 1
fi
jq '[.results[] | select(.not_run != true)] | length' mutaml-report.json
rm -f mutaml-report.json
