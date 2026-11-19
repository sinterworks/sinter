<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Mutation testing

Install the project's fork of `mutaml` as the section "Mutation
testing" of `CONTRIBUTING.md` says.

**A full pass.** From the repository root:

```
MUTAML_MUT_RATE=100 MUTAML_SEED=42 \
  dune build @runtest --force --instrument-with mutaml
cores=$(getconf _NPROCESSORS_ONLN)
number=$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')
echo "The seeds are ${number}1 and ${number}2."
mutaml-runner --build-context _build/default \
  -j "$(( cores > 1 ? cores - 1 : 1 ))" \
  --repeat 2 --test-env "QCHECK_SEED=${number}{}" \
  --baseline-env "QCHECK_SEED=${number}2" \
  test/run-mutants.sh
mutaml-report --fail-under 95 \
  --markdown _mutations/summary.md \
  --json-report _mutations/report.json
```

One runner tests every mutant under the whole suite, and the pass takes
some hours. A machine has no time limit for one command, so this pass
needs no split. The `mutation` job splits the same pass into parts, and
it tests each mutant only under the test groups that can reach it, as
"The CI job" and "The selection of tests" below say.

**A pass on a branch.** Run `git fetch origin`, and put
`--changed-since origin/main` in front of the script name in the
`mutaml-runner` line. The runner then tests only the mutants on the
lines that the branch changed, and the score counts only those. When
no mutant sits on a changed line, `mutaml-report` says that the run has
no score and exits 0. The `mutation` job makes this pass on a pull
request. It makes the full pass on a pull request that changes a
dependency, and it skips a pull request that changed no dependency and
no file under `lib/` or `bin/`
(`docs/decisions/mutation-job-scope.md`).

**What each command and option does.**

- `--instrument-with mutaml` switches the instrumentation on. Without
  it, a build carries no instrumentation and costs nothing.
  `MUTAML_MUT_RATE=100` puts a mutant at every place that can hold
  one. `MUTAML_SEED` fixes the draw, which decides anything only at a
  rate below 100. The build writes one **mutation file** for each
  instrumented source file in `_build/.mutaml/default`: a `.muts` file
  that lists the mutants of that source file and its marked places,
  and the list `mutaml-mut-files.txt` of the mutation files.
- `test/run-mutants.sh` is the test command. The suite reads its
  fixtures from paths relative to its own folder under `_build`, so
  the script starts at the root, where the runner starts it, and runs
  the suite in that folder. The script gives the suite its own
  arguments, and then `--bail`, which stops the suite at its first
  failing test: one failure kills the mutant. So
  `test/run-mutants.sh test '^(json|toml)$'` runs only the test groups
  `json` and `toml`. The arguments come first because the suite refuses
  `--bail` in front of the word `test`. On Linux, the script also
  limits the data of the suite to 2 GiB (`ulimit -d`). A mutant that
  makes a loop allocate without end then stops with an error of memory,
  and the machine keeps its memory. The suite needs less than 200 MiB.
  macOS does not enforce this limit, so the script sets it only on
  Linux.
- `-j` is the number of mutants that the runner tests at one time: the
  number of cores less one, and never below 1.
  `getconf _NPROCESSORS_ONLN` gives the number of cores on macOS and on
  Linux; the `mutation` job uses `nproc`.
- `QCHECK_SEED` is the seed of the property tests. `od` reads a
  random number from `/dev/urandom`, and the seeds are that number
  with the digit 1 after it and with the digit 2 after it. The seed
  must fit in an OCaml `int`. The property tests read a value that
  does not fit as no seed, and draw a seed of their own, which the
  runner cannot repeat. A number of 17 digits or fewer, with one digit
  after it, always fits.
- `--repeat 2` with `--test-env "QCHECK_SEED=${number}{}"` runs a
  mutant up to two times. The runner replaces `{}` with the number of
  the run, 1 or 2, so a mutant runs under the two seeds. A mutant that
  either run kills is killed. One fixed seed can miss a change that
  another seed catches, and a seed that changes from pass to pass
  tries new inputs on each pass.
- `--baseline-env "QCHECK_SEED=${number}2"` checks the suite itself.
  The runner runs the suite twice with no mutant, under the two seeds,
  and stops when the two runs disagree, because a suite that answers
  differently under two seeds gives the score no meaning. The runner
  also replaces `{}` with 1 and 2 in these two runs, so the option
  gives the second run the seed that it already has; it makes that
  seed plain in the command.
- The runner sets the time limit of one run: five times the run with
  no mutant, and never less than 10 seconds. Give `--timeout` only to
  set the limit yourself, and never near the time that the suite
  really takes: a run cut short counts as a kill, and the score then
  reads higher than it is.
- `mutaml-report` reads `mutaml-report.json`, which the runner writes at
  the root. It prints the score and, for each survivor, its name and a
  diff of the change. `--markdown` writes the same report with one row
  per source file. `--json-report` writes the mutation-testing-elements
  format that Stryker, Infection, and Mull also write. Run the report
  after a pass of the runner: the runner makes the folder `_mutations/`,
  and the report does not.

**The CI job.** A job on GitHub stops after six hours, and a full
pass takes longer than that on one runner of GitHub. So the `mutation`
job runs as a plan, a number of parts that run at the same time, and a
report:

1. "Plan the mutation run" decides what the run measures: every
   mutant, the mutants on the lines that the pull request changed, or
   no mutant, as "A pass on a branch" above says. It makes the mutants
   with `dune build @check --instrument-with mutaml`, which writes the
   mutation files without a build of the programs, and
   `test/mutant-count.sh` counts the mutants that the run tests. For
   the changed lines, the script runs `mutaml-runner --changed-since`
   with a test command that always passes, so that the count follows
   the rule of the runner. The number of parts is that count divided
   by `MUTANTS_PER_PART` in `build.yml`, rounded up, and at least 1.
   One run on GitHub holds at most 256 parts.
2. Each **part**, "Measure the mutation score (part 1 of 3)" and so on,
   builds the tests with the code instrumented and runs
   `test/mutant-shares.sh <parts> <part>`. The script reads the list of
   mutation files that the build wrote, counts the mutants in each
   file, and gives the files to as many **shares** as there are parts.
   A share is a set of mutation files, and each part tests one share.
   The script takes the files from the most mutants to the fewest, and
   gives each file to the share with the fewest mutants so far. Files
   with the same number of mutants go in the order of their paths.
   Every part computes the same shares, so each file is in exactly one
   share. A file with no mutant and no marked place is in no share,
   because it has nothing to report.
3. Each part runs `test/run-mutant-share.sh` on the files of its
   share. The script runs `mutaml-runner --muts <file>` once for each
   file, with the options of the full pass, and with
   `--changed-since` when the run measures the changed lines. The test
   command of each file runs only the test groups that can reach its
   code, as "The selection of tests" below says. Each run writes
   `mutaml-report.json`, so the script moves that file away after each
   run. At the end, `test/join-mutant-reports.sh` joins the reports
   into one report of the part, and the part keeps it as an artifact.
4. "Report the mutation score" runs after the parts, also when a part
   fails. It joins the reports of the parts, checks that the parts
   tested as many mutants as the plan counted, and runs `mutaml-report`
   on the joined report with `--fail-under`. It fails when the plan
   failed, a part failed, a report is missing, or the two counts differ,
   and it passes at once when the run measures no mutant. It keeps the
   joined report and the JSON report as the artifact `mutation-report`.

The joined report holds the same results as the report of one runner
over all the files, so the score is the score of the full pass. The
join refuses two reports that hold the same mutant. Each run of the
runner on one file runs its test command twice without a mutant before
it tests a mutant of that file. A run with `--changed-since` that finds
no mutant on a changed line in its file runs no test at all.

**The selection of tests.** A **test group** is one entry of the list
in `test/test_sinter.ml`, such as `("json", Test_json.tests)`. A mutant
can change the result of a test only when the test runs the code of the
mutant. `test/mutant-groups.sh` finds, for each mutation file, the test
groups whose code can call into that file:

1. It reads, with `ocamlobjinfo`, the interfaces that each compiled
   module of the build imports.
2. From the module of each test group, it follows the imports to each
   module that the group can call, directly or through other modules.
   It does not follow the alias module of a library, such as
   `Sinter_core`, which names every module of the library. A module
   that uses a module of a library imports that module itself.
3. A group that reaches a source that names `main.exe`,
   `generate.exe`, or `run.exe` starts that program, and it reaches
   every module of the three programs.
4. A group whose entry in the list does not have the form
   `("<name>", <Module>.tests)` reaches every file. Today these groups
   are `mode` and `cases`.

The script prints one line for each mutation file: the file, a tab, and
a filter of test groups, such as `^(json|toml)$`, or the word `all`.
`test/run-mutant-share.sh` then gives the runner the test command
`test/run-mutants.sh test '<filter>'`, or `test/run-mutants.sh` for
`all`. It prints that command in the log before the mutants of the
file. The two runs without a mutant use the same command, so the time
limit of a mutant comes from the selected groups.

A wrong selection could make a mutant survive falsely or die falsely.
These rules make each such error stop the run:

1. The script stops when the test groups that `test_sinter.exe list`
   prints differ from the groups that it reads in
   `test/test_sinter.ml`.
2. The script stops when a source that the suite links names a program
   other than the three above. A program that a test starts goes into
   the list of programs in the script, with the folder of its compiled
   modules.
3. A mutation file that no group reaches, or that no compiled module
   comes from, gets `all`: the whole suite, never an empty filter.
   alcotest exits with status 1 when a filter selects no test, and the
   runner reads that status as a kill.
4. The runner stops when a run without a mutant fails. alcotest exits
   with status 124 when it refuses its command line, and the runner
   reads that status as a timeout, which counts as a kill. A command
   line that the suite refuses therefore stops the pass at the first
   run without a mutant.

**The seeds of the CI job.** Each part draws its own random number and
prints the seeds at the start of the log of its step "Run the tests
for each mutant of this part under two seeds". For the number 2807,
the seeds are 28071 and 28072. The summary of "Report the mutation
score" names each mutant that survived. To test a survivor again under
the same seeds:

1. Find the part whose log names the mutation file of the survivor,
   and read its seeds.
2. Build the tests with the code instrumented, as in "A full pass".
3. Find, in the same log, the test command of the mutation file of
   the survivor. The log prints it in the line
   `Testing the mutants of <file> (... of ...) with the test command:`.
4. Run that command at the root, with the name of the survivor from the
   summary and each of the two seeds, for example:

   ```
   MUTAML_MUTANT='<name of the survivor>' QCHECK_SEED=28071 test/run-mutants.sh test '^(json|toml)$'
   MUTAML_MUTANT='<name of the survivor>' QCHECK_SEED=28072 test/run-mutants.sh test '^(json|toml)$'
   ```

   `test/run-mutants.sh` without arguments runs every test.

The joined report in the artifact, `mutaml-report.json`, also holds a
seed for each mutant that ran, in its field `test_env`: the seed of the
run that ended the mutant. For a survivor, that is the second seed. The
random number that the part drew is that seed without its last digit. To
test a share again on a machine under the seeds of its part, give that
number to `test/run-mutant-share.sh` with `-s`. The seeds change from
run to run, so the score of one tree can change between two runs: a
mutant that only some seeds kill survives in one run and not in another.
Such a mutant is a gap in the tests.

**Rules for a pass.**

1. Start the runner at the repository root. Started anywhere else, it
   finds no mutation file and tests nothing, and `mutaml-report` then
   prints `Found no test results` and exits 1. A full pass makes
   several thousand mutants; a much smaller number means that the pass
   missed some of the tree.
2. Run no other `dune` command while a pass runs, and build again with
   `--instrument-with mutaml` after any ordinary `dune` command. An
   ordinary build links the executables again without the
   instrumentation. After an ordinary build of the whole tree, almost
   every mutant survives. A build beside a pass can leave one
   executable with the instrumentation and the other without it; every
   mutant of one source file then reads as a survivor, and that is the
   sign of this mistake.
3. A `dune` command during a pass also does a second harm. The suite
   writes its logs in one folder per run under
   `_build/default/test/_build/_tests`, and `dune` removes those
   folders. A run whose folder goes away dies, and the runner counts
   any run that fails as a kill, so the score then holds kills that no
   test made. `dune clean`, or the next ordinary build, removes the
   folders after a pass.
4. Run `dune clean` first when `MUTAML_MUT_RATE` or `MUTAML_SEED`
   differs from the last pass. `dune` does not always build again when
   only an environment variable changed.
5. Hold one core back. The runner takes the time limit from the run
   with no mutant, which it makes before any worker starts, on an idle
   machine. On a machine whose every core is busy, a later run can pass
   the limit through waiting alone, and the run then counts as a kill.
   The mutants that hang the suite are the same on every pass of one
   tree, so the column "timed out" of the report gives the same count
   on every pass of one tree. A larger count on another pass of the
   same tree means that the machine was too busy.

The section "Mutation testing" of `CONTRIBUTING.md` holds two more rules
for a pass: keep the suite safe to run in parallel, and keep a value
that only a release build can set out of the measured code.
