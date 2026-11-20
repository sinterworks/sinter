<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Performance

Start the benchmark as the section "Performance" of `CONTRIBUTING.md`
says.

`@bench` measures Sinter itself, the trees of 1,000 and 10,000
declarations, and the three ledgers. `@bench-large` adds the tree of
100,000 declarations, which takes several minutes. `dune test` runs
neither. The trees go to a temporary folder outside `_build`, and the
run removes them at its end. Each command runs once to warm up and
then five times, three for `@bench-large`. The run prints a JSON
object and a table of the medians and their spread, and checks the
budgets.

The executables are `bench/run.exe` and `bench/generate.exe`, and
`--help` gives the options and the output of each. To compare two
builds, give each build's `sinter` to `run.exe` with `--sinter`, and
keep the trees between the runs with `--trees`. To check the budgets
against the JSON object of an earlier run, such as the artifact of the
CI job, give that file to `run.exe` with `--results`.

On Linux, GNU `time` gives the peak memory, and `perf stat` counts the
instructions when `perf` is installed and can count them. On macOS,
`time -l` gives the peak memory, and the instruction count when the
machine reports one. The two platforms count different processes, so
compare numbers from one platform only. The instruction counts are
information only; no budget reads them.

The option `--time` of `run.exe` names the program `time`. The default
is `/usr/bin/time`. When no file is at that path, the run measures no
peak memory and no peak footprint, and on macOS no instructions. The
run still counts the words of each phase and checks the budgets. The
JSON object then holds null for each measure that the run did not
make, and the table shows `-`.

When the environment variable `SINTER_PHASE_WORDS` names a file,
`sinter scan` and `sinter check` write to it the words of memory that
the OCaml runtime allocated in each phase of the command (a word is 8
bytes on a 64-bit machine): `repository`, `read`, `parse`, `facts`,
`records` (scan) or `findings` (check), and `output`. `check` also has
`base-read`, which reads the base. `check --diff` also has
`base-facts` and `base-findings`, which make the facts and the
findings of the whole base. `sinter ledger log` and
`sinter ledger verify` write the phases `repository`, `ledger` (the
read and the check of the ledger), and `output`. The runner sets
the variable for each run. The count is the
same on every run of one input at one path. The counts of `repository`
and `read` also grow with the length of the path of the tree.

The CI job "Measure performance" runs on each push to `main`, on the
daily schedule of the workflow, and on a pull request that changes
`lib/`, `bin/`, `bridge/`, `bench/`, or a dependency. It writes the
numbers to the job summary, and keeps the JSON object as the artifact
`performance`. Before it measures, the job downloads that artifact
from the newest run on `main` that has one, and gives it to `run.exe`
with `--baseline`. The summary then shows the peak memory of each
command next to the peak memory of `main`. When the job finds no such
artifact, or the artifact does not read, the job measures with no
baseline, and the summary says so.
