# Journal: CI efficiency

## Run each mutant under the test groups that can reach it

- The job "Plan the mutation run" makes the mutants with
  `dune build @check --instrument-with mutaml`. That build writes the
  same mutation files, byte for byte, as the build of the parts, and it
  builds no part of the bridge crate.
- The count of the mutants on changed lines comes from
  `mutaml-runner --changed-since` with the test command `true`, so the
  count follows the rule of the runner itself and not a copy of it.
- `MUTANTS_PER_PART` is set to 2,500 from a CI full run of 6,179
  mutants in three parts (about 2,060 mutants per part), whose parts
  took 2 h 30 min, 1 h 52 min, and 1 h 16 min. At 2,500 mutants per
  part, even a slower imbalanced part stays near 3 hours.
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
