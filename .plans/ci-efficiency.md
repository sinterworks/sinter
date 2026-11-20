# CI efficiency
@plan ci-efficiency@06b01d
@scope .github/workflows/**, test/**, docs/contributing/mutation-testing.md, CONTRIBUTING.md
Keep the caches of `main` in use between pushes, and shorten the wait
in the CLI tests that start a process with a time limit.

## Run the cached jobs in the daily run
@scope .github/workflows/**
Run the build, format, coverage, and bridge crate jobs in the daily
scheduled run too, so that a run reads each cache of `main` every day.
GitHub removes a cache that no run reads for seven days.

## Check the child process sooner in the CLI tests
@scope test/**
Wait 1 ms before the first check of a child process, and double the
wait after each check, up to 50 ms. The time limit of each test stays
the same.

## Run each mutant under the test groups that can reach it
@scope .github/workflows/**, test/**, docs/contributing/mutation-testing.md, CONTRIBUTING.md
Test the mutants of each mutation file under the test groups whose code
can call into that file, from the import lists of the compiled modules.
Set the number of parts of the mutation job from the count of mutants
of the run, so that no part has much more than 3 hours of work. On the
daily run, each part also tests a few drawn mutants under the whole
suite and under the selection, and fails when the two disagree.
