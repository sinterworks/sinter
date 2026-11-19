# Journal: Contributing procedures

## Move the measuring procedures

- Two rules of "Rules for a pass" bind the code and not the pass: a
  suite safe to run in parallel, and values that only a release build
  sets kept out of the measured code. They stay in the guide.
- The new documents keep the license that the text had in the guide,
  Apache-2.0. The section "Licensing of contributions" now names the
  folders that use CC-BY-4.0, as `REUSE.toml` does.
- The record `mutation-job-scope` points at the new procedure, so its
  revision rose to v5.
- Left for later: the guide does not say whether the author of a
  dependency update runs a local mutation pass first.
