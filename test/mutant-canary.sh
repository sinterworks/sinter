#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The Sinter Authors

set -eu

usage() {
  echo "Usage: test/mutant-canary.sh [-n <count>] [-j <workers>] [-s <number>] <mutation file>..." >&2
  echo "Draws mutants from the mutation files and tests each one under two seeds, once with every test and once with the test groups of its file." >&2
  echo "Fails when the two tests of a mutant disagree: one kills the mutant and the other does not." >&2
  echo "  -n <count>     the number of mutants to draw; the default is 5" >&2
  echo "  -j <workers>   the number of mutants to test at one time; the default is 1" >&2
  echo "  -s <number>    the seeds are <number>1 and <number>2, and the number also decides the draw; the default is a random number" >&2
  echo "Start it at the root of the project, after a build with --instrument-with mutaml." >&2
  exit 2
}

count=5
workers=1
number=
while getopts n:j:s: option; do
  case $option in
    n) count=$OPTARG ;;
    j) workers=$OPTARG ;;
    s) number=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ "$#" -ge 1 ] || usage

case $count in '' | *[!0-9]* | 0) usage ;; esac
case $workers in '' | *[!0-9]* | 0) usage ;; esac
if [ -z "$number" ]; then
  number=$(od -An -N4 -tu4 /dev/urandom | tr -d ' \n')
fi
case $number in
  '' | *[!0-9]*)
    echo "mutant-canary.sh: the value of -s must hold only digits." >&2
    exit 2
    ;;
esac
if [ "${#number}" -gt 17 ]; then
  echo "mutant-canary.sh: the value of -s must hold 17 digits or fewer." >&2
  exit 2
fi

side=_build/.mutaml/default
for file in "$@"; do
  if [ ! -f "$side/$file" ]; then
    echo "mutant-canary.sh: there is no mutation file $file in $side." >&2
    exit 2
  fi
done

echo "The canary draws $count mutants with the number $number."
echo "The seeds of the property tests are ${number}1 and ${number}2."
echo "To make the same draw again, give the option -s $number and the same mutation files."

dir=_mutations/canary
rm -rf "$dir"
mkdir -p "$dir"

sh test/mutant-groups.sh >"$dir/groups"

: >"$dir/candidates"
for file in "$@"; do
  jq -r --arg file "$file" '.mutants[] | "\($file)\t\(.number)"' "$side/$file" \
    >>"$dir/candidates"
done
if [ ! -s "$dir/candidates" ]; then
  echo "The mutation files hold no mutant, so the canary has nothing to test."
  exit 0
fi

LC_ALL=C awk -v count="$count" -v number="$number" '
  { line[NR] = $0 }
  END {
    x = substr(number, length(number) > 9 ? length(number) - 8 : 1) % 2147483646 + 1
    chosen = 0
    while (chosen < count && chosen < NR) {
      x = (x * 48271) % 2147483647
      i = x % NR + 1
      if (!(i in taken)) {
        taken[i] = 1
        print line[i]
        chosen++
      }
    }
  }' "$dir/candidates" >"$dir/drawn"

quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

run() {
  rm -f mutaml-report.json "$dir/status"
  {
    status=0
    mutaml-runner --build-context _build/default -j "$workers" \
      --repeat 2 --test-env "QCHECK_SEED=${number}{}" \
      --baseline-env "QCHECK_SEED=${number}2" \
      --muts "$(pwd)/$1" "$2" || status=$?
    echo "$status" >"$dir/status"
  } 2>&1 | tee "$1.log"
  status=$(cat "$dir/status" 2>/dev/null || echo unknown)
  if [ "$status" != 0 ] || [ ! -f mutaml-report.json ]; then
    echo "The canary could not test its mutants with the test command: $2"
    echo "mutaml-runner ended with status $status. Its output is above."
    exit 1
  fi
  if grep -q '^Skipping ' "$1.log"; then
    echo "The runner skipped the mutants of a source file that is gone. Run dune clean and build again."
    exit 1
  fi
  mv mutaml-report.json "$3"
}

LC_ALL=C awk -F '\t' '!seen[$1]++ { print $1 }' "$dir/drawn" >"$dir/files"
: >"$dir/whole.list"
index=0
while IFS= read -r file; do
  index=$((index + 1))
  filter=$(awk -F '\t' -v file="$file" '$1 == file { print $2 }' "$dir/groups")
  case $filter in
    all) command=test/run-mutants.sh ;;
    ^*) command="test/run-mutants.sh test $(quote "$filter")" ;;
    *)
      echo "The map of test groups names no test group for $file."
      exit 1
      ;;
  esac
  awk -F '\t' -v file="$file" '$1 == file { print $2 }' "$dir/drawn" >"$dir/numbers"
  jq -c --slurpfile numbers "$dir/numbers" \
    '.mutants[] | select(.number as $n | any($numbers[]; . == $n))' \
    "$side/$file" >"$dir/part-$index.list"
  cat "$dir/part-$index.list" >>"$dir/whole.list"
  jq -s '{mutants: .}' "$dir/part-$index.list" >"$dir/part-$index.muts"
  printf '%s\n' "$file" >"$dir/part-$index.file"
  printf '%s\n' "$command" >"$dir/part-$index.command"
done <"$dir/files"
jq -s '{mutants: .}' "$dir/whole.list" >"$dir/whole.muts"
parts=$index

echo "The canary tests these mutants with every test:"
sed 's/^/  /' "$dir/drawn"
run "$dir/whole.muts" test/run-mutants.sh "$dir/whole.json"

set -- "$dir/whole.json"
index=0
while [ "$index" -lt "$parts" ]; do
  index=$((index + 1))
  file=$(cat "$dir/part-$index.file")
  command=$(cat "$dir/part-$index.command")
  echo "The canary tests the mutants of $file with the test command: $command"
  run "$dir/part-$index.muts" "$command" "$dir/part-$index.json"
  set -- "$@" "$dir/part-$index.json"
done

jq -r -s '
  def key: "\(.mutant.loc.loc_start.pos_fname) mutant \(.mutant.number)";
  def outcomes: map({key: key, value: (.status != 0)}) | from_entries;
  (.[0].results | outcomes) as $every
  | ([.[1:][] | .results[]] | outcomes) as $selected
  | ($every + $selected | keys[]) as $key
  | [$key,
     (if $every | has($key) then (if $every[$key] then "killed" else "survived" end) else "missing" end),
     (if $selected | has($key) then (if $selected[$key] then "killed" else "survived" end) else "missing" end)]
  | @tsv' "$@" >"$dir/outcomes"

echo "The outcome of each mutant, with every test and with the test groups of its file:"
sed 's/^/  /' "$dir/outcomes"
drawn=$(wc -l <"$dir/drawn" | tr -d ' ')
agree=$(awk -F '\t' '$2 == $3 && $2 != "missing"' "$dir/outcomes" | wc -l | tr -d ' ')
outcomes=$(wc -l <"$dir/outcomes" | tr -d ' ')
if [ "$agree" != "$drawn" ] || [ "$outcomes" != "$drawn" ]; then
  echo "The canary failed: the two tests disagree on a mutant, or a report lacks a mutant."
  echo "When every test kills a mutant and its test groups do not, the map of test groups misses a way to reach its code."
  echo "When its test groups kill a mutant and every test does not, the selection kills a mutant falsely."
  exit 1
fi
echo "The canary passed: the two tests agree on each of the $drawn mutants."
