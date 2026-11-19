# Journal: CI efficiency

## Run each mutant under the test groups that can reach it

- The tests of the scripts are a test executable of their own,
  `test/scripts/`, so that the runs of the mutants do not run them and
  the map does not read the names of their fake programs.
