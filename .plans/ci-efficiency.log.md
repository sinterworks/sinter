# Journal: CI efficiency

## Run each mutant under the test groups that can reach it

- A group whose entry in the list of `test/test_sinter.ml` is not
  `("<name>", <Module>.tests)` counts as reaching every file: today
  `mode` and `cases`. `cases` starts `main.exe` through an argument
  that the walk cannot follow.
- The tests of the scripts are a test executable of their own,
  `test/scripts/`, so that the runs of the mutants do not run them and
  the map does not read the names of their fake programs.
- Left for later: `cases` is in the selection of every file, because
  its entry passes `binary` to `Fixture.tests`. It takes about 5 s, and
  a survivor pays it twice. The map could tie it to `Fixture` and to
  the programs, as a group that starts a program.
