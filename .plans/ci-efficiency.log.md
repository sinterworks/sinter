# Journal: CI efficiency

## Run each mutant under the test groups that can reach it

- The job "Plan the mutation run" makes the mutants with
  `dune build @check --instrument-with mutaml`. That build writes the
  same mutation files, byte for byte, as the build of the parts, and it
  builds no part of the bridge crate.
- The count of the mutants on changed lines comes from
  `mutaml-runner --changed-since` with the test command `true`, so the
  count follows the rule of the runner itself and not a copy of it.
- `MUTANTS_PER_PART` was first set to 2,500 from a CI full run of
  6,179 mutants on the tree of pull request #207, whose slowest part
  took 2 h 30 min for about 2,060 mutants. A full run of the tree of
  `main` with this job was slower: 5,358 mutants in three parts took 3 h 06 min, 1 h 40 min,
  and 1 h 19 min, about 6.25 seconds for each mutant in the slowest
  part. At 2,500 mutants, such a part would take about 4 h 20 min, so
  the number is now 1,700, which keeps a part near 3 hours.
- A group whose entry in the list of `test/test_sinter.ml` is not
  `("<name>", <Module>.tests)` counts as reaching every file: today
  `mode` and `cases`. `cases` starts `main.exe` through an argument
  that the walk cannot follow.
- The canary fails when the two tests disagree in either direction,
  including when the selection kills a mutant that the whole suite does
  not kill, because such a kill raises the score falsely.
- The tests of the scripts are a test executable of their own,
  `test/scripts/`, so that the runs of the mutants do not run them and
  the map does not read the names of their fake programs.
- Left for later: in a run of changed lines, the shares still weigh
  each file by all its mutants, not by the mutants on changed lines.
- Left for later: `cases` is in the selection of every file, because
  its entry passes `binary` to `Fixture.tests`. It takes about 5 s, and
  a survivor pays it twice. The map could tie it to `Fixture` and to
  the programs, as a group that starts a program.
