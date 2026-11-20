#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The Sinter Authors

set -eu

usage() {
  echo "Usage: test/mutant-groups.sh" >&2
  echo "Prints one line for each mutation file: the mutation file, a tab, and the test groups that can reach its code." >&2
  echo "The groups are a filter that test/run-mutants.sh takes after the word test, or the word all for every test." >&2
  echo "Start it at the root of the project, after a build with --instrument-with mutaml." >&2
  exit 2
}

[ "$#" -eq 0 ] || usage

build=_build/default
list=_build/.mutaml/default/mutaml-mut-files.txt
suite=$build/test/test_sinter.exe
groups=test/test_sinter.ml
programs='main.exe bin/.main.eobjs
generate.exe bench/.generate.eobjs
run.exe bench/.run.eobjs'

if [ ! -f "$list" ] || [ ! -x "$suite" ] || [ ! -f "$groups" ]; then
  echo "mutant-groups.sh: there is no build with the code instrumented here." >&2
  echo "Build the tests with the code instrumented, at the root of the project:" >&2
  echo "  dune build @runtest --force --instrument-with mutaml" >&2
  exit 2
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/mutant-groups.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' HUP INT TERM

if ! (cd "$build/test" && unset MUTAML_MUTANT && ./test_sinter.exe list) \
  >"$tmp/listed" 2>"$tmp/error"; then
  echo "mutant-groups.sh: the test suite could not list its tests:" >&2
  sed 's/^/  /' "$tmp/error" >&2
  exit 1
fi

find "$build" -path '*/.*objs/native/*.cmx' -type f >"$tmp/found"
LC_ALL=C sort "$tmp/found" >"$tmp/units"
if [ ! -s "$tmp/units" ]; then
  echo "mutant-groups.sh: the build holds no compiled module." >&2
  exit 1
fi
: >"$tmp/imports"
while IFS= read -r unit; do
  if ! ocamlobjinfo "$unit" >>"$tmp/imports" 2>"$tmp/error"; then
    echo "mutant-groups.sh: ocamlobjinfo could not read $unit:" >&2
    sed 's/^/  /' "$tmp/error" >&2
    exit 1
  fi
done <"$tmp/units"

printf '%s\n' "$programs" >"$tmp/programs"

LC_ALL=C awk -v build="$build" -v list="$list" -v groups="$groups" \
  -v listed="$tmp/listed" -v programs="$tmp/programs" \
  -v tests="$build/test/.test_sinter.eobjs" '
  function fail(message) {
    print "mutant-groups.sh: " message > "/dev/stderr"
    failed = 1
    exit 1
  }
  function dirname(path) {
    sub(/\/[^\/]*$/, "", path)
    return path
  }
  function exists(path,   line, status) {
    status = (getline line < path)
    if (status >= 0) close(path)
    return status >= 0
  }
  function key(name, objects) {
    return name ~ /^Dune__exe(__|$)/ ? objects ":" name : name
  }
  function uncapitalize(name) {
    return tolower(substr(name, 1, 1)) substr(name, 2)
  }
  function escape(text,   out, i, c) {
    out = ""
    for (i = 1; i <= length(text); i++) {
      c = substr(text, i, 1)
      if (index("\\^$.|?*+()[]{}", c)) out = out "\\"
      out = out c
    }
    return out
  }
  function source_of(unit,   module, dir, at) {
    module = unit_name[unit]
    while ((at = index(module, "__")) > 0) module = substr(module, at + 2)
    if (module == "") return ""
    dir = unit_dir[unit]
    if (exists(build "/" dir uncapitalize(module) ".ml")) return dir uncapitalize(module) ".ml"
    if (exists(build "/" dir module ".ml")) return dir module ".ml"
    return ""
  }
  function scan(unit, path,   line, number, rest, word) {
    number = 0
    while ((getline line < (build "/" path)) > 0) {
      number++
      rest = line
      while (match(rest, /[A-Za-z0-9_.-]*\.exe([^A-Za-z0-9_]|$)/)) {
        word = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        sub(/[^A-Za-z0-9_]$/, "", word)
        if (word in program_dir) spawns[unit] = 1
        else unknown = unknown "\n  " path ":" number ": " word
      }
    }
    close(build "/" path)
  }
  function walk(count,   seen, todo, top, unit, i) {
    split("", seen)
    split("", reached)
    walked_spawns = 0
    top = 0
    for (i = 1; i <= count; i++) todo[++top] = roots[i]
    while (top > 0) {
      unit = todo[top--]
      if ((unit in seen) || !(unit in unit_name)) continue
      seen[unit] = 1
      if (unit in alias) continue
      for (i = 1; i <= import_count[unit]; i++) todo[++top] = imports[unit, i]
    }
    split("", walked)
    for (unit in seen) {
      walked[unit] = 1
      if (unit in spawns) walked_spawns = 1
      if (unit in source) reached[source[unit]] = 1
    }
  }

  /^File / {
    path = substr($0, 6)
    objects = dirname(dirname(path))
    directory = dirname(objects)
    directory = directory == build ? "" : substr(directory, length(build) + 2) "/"
    in_imports = 0
    next
  }
  /^Name: / {
    name = substr($0, 7)
    current = key(name, objects)
    if (current in unit_name) fail("two compiled modules have the name " name ".")
    unit_name[current] = name
    unit_objects[current] = objects
    unit_dir[current] = directory
    import_count[current] = 0
    in_imports = 0
    next
  }
  /^Interfaces imported:/ { in_imports = 1; next }
  in_imports && /^\t/ {
    n = split($0, field, "\t")
    imported = key(field[n], unit_objects[current])
    if (imported != current) imports[current, ++import_count[current]] = imported
    next
  }
  { in_imports = 0 }

  END {
    if (failed) exit 1

    while ((getline line < programs) > 0) {
      split(line, field, " ")
      program_dir[field[1]] = build "/" field[2]
    }
    close(programs)

    for (unit in unit_name) {
      path = source_of(unit)
      if (path != "") {
        source[unit] = path
        has_source[path] = 1
      }
      name = unit_name[unit]
      for (i = 1; i < length(name); i++)
        if (substr(name, i + 1, 2) == "__")
          namespace[key(substr(name, 1, i), unit_objects[unit])] = 1
    }
    for (unit in unit_name)
      if (!(unit in source) && ((unit in namespace) || unit_name[unit] ~ /__$/))
        alias[unit] = 1

    count = 0
    for (unit in unit_name)
      if (unit_objects[unit] == tests) roots[++count] = unit
    if (count == 0) fail("the build holds no compiled module of the test suite.")
    walk(count)
    unknown = ""
    for (unit in walked)
      if (unit in source) scan(unit, source[unit])
    if (unknown != "")
      fail("these lines name a program that a test may start, and the map knows no such program:" \
        unknown "\nAdd the program and the folder of its compiled modules to the programs of this script.")

    split("", program_reach)
    for (program in program_dir) {
      count = 0
      for (unit in unit_name)
        if (unit_objects[unit] == program_dir[program]) roots[++count] = unit
      if (count == 0) fail("the build holds no compiled module of the program " program ".")
      walk(count)
      for (path in reached) program_reach[path] = 1
    }

    group_count = 0
    while ((getline line < listed) > 0) {
      at = index(line, "        ")
      if (at < 2 || substr(line, at) !~ /^ +[0-9]+   /) continue
      name = substr(line, 1, at - 1)
      if (name in listed_group) continue
      listed_group[name] = 1
      group[++group_count] = name
    }
    close(listed)
    if (group_count == 0) fail("the test suite listed no test group.")

    text = ""
    while ((getline line < groups) > 0) text = text line "\n"
    close(groups)
    at = index(text, "Alcotest.run")
    if (at == 0) fail("the source of the test suite holds no call of Alcotest.run.")
    rest = substr(text, at)
    entry = "[(][ \t\n]*\"[^\"\\\\]*\"[ \t\n]*,"
    simple = "^[ \t\n]*[A-Z][A-Za-z0-9_]*[.]tests[ \t\n]*[)][ \t\n]*;?[ \t\n]*"
    if (!match(rest, entry)) fail("the source of the test suite names no test group.")
    rest = substr(rest, RSTART)
    while (1) {
      match(rest, entry)
      head = substr(rest, 1, RLENGTH)
      tail = substr(rest, RLENGTH + 1)
      more = match(tail, entry)
      if (more) {
        body = substr(tail, 1, RSTART - 1)
        rest = substr(tail, RSTART)
      } else body = tail
      name = head
      sub(/^[(][ \t\n]*"/, "", name)
      sub(/"[ \t\n]*,$/, "", name)
      source_group[name] = 1
      tied = 0
      if (match(body, simple) && (more ? RLENGTH == length(body) : substr(body, RLENGTH + 1) ~ /^\]/)) {
        module = body
        sub(/^[ \t\n]*/, "", module)
        sub(/[.]tests.*/, "", module)
        root = key("Dune__exe__" module, tests)
        if (root in unit_name) {
          root_of[name, ++root_count[name]] = root
          tied = 1
        }
      }
      if (!tied) everything[name] = 1
      if (!more) break
    }

    mismatch = ""
    for (name in listed_group)
      if (!(name in source_group)) mismatch = mismatch "\n  " name " (in the list of the suite only)"
    for (name in source_group)
      if (!(name in listed_group)) mismatch = mismatch "\n  " name " (in the source only)"
    if (mismatch != "")
      fail("the test groups that the suite lists are not the groups that its source names:" mismatch)

    for (g = 1; g <= group_count; g++) {
      name = group[g]
      if (name in everything) continue
      for (i = 1; i <= root_count[name]; i++) roots[i] = root_of[name, i]
      walk(root_count[name])
      for (path in reached) reach[name, path] = 1
      if (walked_spawns) {
        for (path in program_reach) reach[name, path] = 1
      }
    }

    wide = ""
    for (g = 1; g <= group_count; g++)
      if (group[g] in everything) wide = wide (wide == "" ? "" : ", ") group[g]
    if (wide != "")
      print "These test groups count as reaching every mutation file: " wide "." > "/dev/stderr"

    while ((getline file < list) > 0) {
      if (file == "" || (file in printed)) continue
      printed[file] = 1
      if (file !~ /[.]muts$/) fail("the list of mutation files names " file ", which is not a mutation file.")
      path = substr(file, 1, length(file) - 5) ".ml"
      filter = ""
      count = 0
      if (path in has_source)
        for (g = 1; g <= group_count; g++) {
          name = group[g]
          if ((name in everything) || ((name, path) in reach)) {
            filter = filter (count ? "|" : "") escape(name)
            count++
          }
        }
      else
        print "No compiled module comes from " path ", so its mutants run under every test." > "/dev/stderr"
      if (count == 0 && (path in has_source))
        print "No test group can reach " path ", so its mutants run under every test." > "/dev/stderr"
      if (count == 0 || count == group_count) print file "\tall"
      else print file "\t^(" filter ")$"
    }
    close(list)
  }
' "$tmp/imports" >"$tmp/map"

LC_ALL=C sort "$tmp/map"
