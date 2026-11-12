---
name: nextflow-gotchas
description: >
  Use when writing, editing or reviewing Nextflow code (any project, nf-core or not): combining or
  joining channels, passing a reference/database/index as a separate process input, awk or shell
  inside a module script, Groovy GString interpolation in a script block, process template files,
  stageAs, or gzip handling between modules. Also for tests of channel ordering and concurrency,
  for upgrading the Nextflow version of a project or a running large run (26.10 changes), and for
  static typing (`nextflow.enable.types`, typed processes, records, the `output {}` block).
---

# Nextflow gotchas

All of these fail silently, usually only at production scale.

## Joining channels

Pair two channels that must match by identity with `.join()` on a real key (usually `meta.id`).
Never rely on emission order: it is not guaranteed to match submission order once tasks run concurrently.
Two separate process inputs, plain `.merge()` and manual indexing all pair by order.
(TransDecoder: `contigs.1`'s fasta got `contigs.78`'s LongOrfs folder on a real run.)

Choose the operator by relationship:

| Relationship | Operator |
|---|---|
| 1:1 | keyed `.join()` |
| 1:many | `.combine()` + `.filter()` |
| deliberate cartesian broadcast | plain `.combine()` |

- `.join()` silently drops left items with no match, and misbehaves when a key repeats on one side. It is safe only when the left channel has at most one item per key.
- An unkeyed `.combine()` for a relationship that is always 1:1 is safe only by accident. Make it a keyed `.join()`.
- Ask this explicitly each time a channel combination is added or reviewed.

**Testing the race.** A happy-path test can't catch ordering bugs. Force it:
- two or more batches of very different cost (50-100x, e.g. ~150 kb vs ~2 kb of seeded random DNA), so the small one finishes first although submitted second;
- pin cpus and memory low (1 cpu / 1 GB) so a small CI runner actually runs them concurrently.

This gives a fast, deterministic red test.

## A reference, database or index as its own process input

Inputs beside the per-sample data are separate channels and pair by arrival order. Ask, in a module call, a subworkflow `take:` or a review:

1. One shared item, or one per sample? A shared item must be a value channel (`.first()` or `channel.value()`). A one-item queue channel pairs with the first sample only and the rest never run.
2. If one per sample, join it to the sample on a key. Positional pairing gives samples each other's reference and changes on every resume (cached tasks emit in submission order, new ones in completion order).
3. Does the tool use it at all? The input is part of the task hash even if ignored, so a large or mispaired one breaks `-resume` and stages gigabytes for nothing. If unused, pass an empty value.

To diagnose a resume miss, `diff` the `.command.sh` of the same sample's task between two launches.

## awk in a module

- **The container's awk is not the host's.** Modules run mawk or busybox awk, the host has gawk. Host verification proves little. Hex escapes like `\x1f` are not POSIX: use `SUBSEP` or an octal escape.
- **`arr[k] = (k in arr) ? arr[k] SEP v : v` is broken in mawk.** It creates the element before evaluating the right side, so the `in` test is already true and an empty member is prepended. Write an explicit `if (k in arr) ... else ...`.
- **An apostrophe anywhere in the awk program, comments included, ends the shell string** (`awk: Unexpected end of string` at the comment line). Grep new awk for `'`.

Module-level nf-test cases earn their keep here: they run in the real container.

## GString: backtick plus backslash in a script comment

A `script: """ ... """` block is one GString with several `${...}`.
A backtick together with a backslash escape (e.g. `` `grep -v '^\*'` ``) in a comment shifts every later `${...}` slot: values land in the wrong place and the last renders empty.
It shows up as a confusing error far downstream, and is not a heap or OOM artifact (reproduced on two machines).
Don't combine them anywhere in the GString. If the symptom is values in the wrong slots, bisect recent comment edits before blaming the logic.

## Process `template` files

`script: template 'my_script.sh'` (default dir `templates/` next to the module) substitutes `${var}`/`$var` from the process scope. It gives a real, lintable file instead of a long inline block. Propose it when an inline script grows long.

- **A topic-tagged `eval()` output needs a Bash script.** With a `#!/usr/bin/env python3` or `Rscript` template, Nextflow errors `Process output of type 'eval' is only allowed with Bash process scripts`. Write `versions.yml` from the template and declare `path "versions.yml", emit: versions_x, topic: versions`.
- **A `def` from the `script:` block is invisible in the template** (`No such property 'prefix'`). Compute it in the template from the raw bindings, e.g. `prefix = "${meta.id}" if "${task.ext.prefix}" == "null" else "${task.ext.prefix}"`.

## `stageAs`

To stage an input under a known name, declare `path(x, stageAs: "name")` instead of a script-level `mv` first.
For a private writable copy of a staged directory you are about to change, `path(taskdir, stageAs: "input")` keeps the upstream task's output pristine, which protects `-resume`.

## Small file reshaping without a process

For trivial file work (renaming or writing a small file to satisfy a convention such as MultiQC's `*_mqc.*`), use a built-in operator, e.g. `collectFile { meta, f -> [name, content] }`, instead of a process.
No container pull, no executor queueing. metatdenovo already does this for `_mqc.yaml`.

## Compression inside the module

Do gunzip and gzip inside the module that processes the file, not in separate `PIGZ_*` modules between steps: a bridging step leaves a large uncompressed intermediate in `work/`.
If the tool can't read gzip natively (check empirically; KofamScan can't, and a `<(gunzip -c ...)` FIFO fails because it is read once per profile), patch the vendored module (`nf-core modules patch`): gunzip the input at the top, gzip the output at the bottom, `rm` the intermediate.
The patched module can then no longer go upstream as is.

## Upgrading Nextflow (26.10 and later)

From the official 26.10 migration page (docs.seqera.io/nextflow/migrations/26-10), read 2026-11-12, not yet run-tested in the user's pipelines.

- **Don't upgrade Nextflow under a large run you intend to `-resume`.** The hash of `eval` commands changed in 26.10, so every process with an `eval` output re-executes on the first resume. nf-core modules declare their versions with `eval(...)` topic outputs, so that is nearly every task. Finish or pin the run on its old `NXF_VER`.
- **Console output goes to stderr**, also for `nextflow config` and `nextflow run -output-format json`. Capture everything with `> out.log 2>&1`; `-bg` runs still write to stdout.
- **`executor.cpus` and `executor.memory` now apply to grid executors**: a task asking for more fails. To limit only the local executor, use `executor.$local.cpus` and `executor.$local.memory`.
- **Removed:** `-with-weblog` (use the nf-weblog plugin), the `echo` directive (use `debug`). The Kubernetes executor uses Jobs, not Pods, by default (`k8s.computeResourceType = 'Pod'` restores it).
- **Deprecated:** the process `when:` section (use workflow logic or the `process.when` config setting), the `storeDir` directive, `seqera.executor.autoLabels` (use `tower.autoLabels`). Every nf-core module has `when: task.ext.when == null || task.ext.when`, so expect lint warnings until the template changes; don't edit vendored modules for it.
- **Useful additions:** `nextflow logfile <run name|last> [-level ERROR] [-f]`; the `accelerator` directive on the local executor; the formatter keeps comments.
- Not documented in any page read: when static typing or the strict parser becomes the default.

## Static typing (stable in 26.10, opt-in)

Syntax is unchanged since 26.04. Source: docs.seqera.io/nextflow/{static-typing,workflow-typed,process-typed,typed-parameters,static-typing-prep}, 2026-11-12. **No pipeline of the user's is typed yet**; treat this as a map for a spike, not a tested recipe.

- **Enable:** `nextflow.enable.types = true` in every script that has typed processes or workflows (legacy and typed definitions can't share a script). The `params {}` and `output {}` blocks work without it. The static-typing page also asks for `NXF_SYNTAX_PARSER=v2`, while the strict-syntax page says the strict parser is the default since 26.04; check on the Nextflow in use.
- **Checking:** `nextflow lint` reports type errors. `nextflow run` only warns. No documented flag makes `run` fail, so keep `nextflow lint` as a CI step.
- **Typed process:** `input: sample: Sample` or `tuple(id: String, fastq: Path)`; `Path?` is nullable (a null input otherwise fails the task); `output: out: Path = file('x.txt')`, `stdout()`, `env('X')`, `file('x', optional: true)` gives `null`; `record(...)` and `tuple(...)` for structure. `topic:` section: `tuple('bash', eval('bash --version')) >> 'versions'`. `stage:` section for `env`, `stdin`, `stageAs`.
- **Record:** `record Sample { id: String; fastq: Path }`. Missing fields fail the run, extra fields are ignored, `Path` fields are staged. Same-named files from a `List<Sample>` collide: use `stageAs 'fastq?/*'`, and `stageAs` rejects nulls.
- **Forbidden in typed workflows:** the `Channel` factory (use `channel`), implicit `it`, `set`/`tap`, `|` and `&`, `.out` on process/workflow calls (assign the call: `x = P()`), the `each` input qualifier. Legacy operators run but aren't type-checked (e.g. `splitCsv` becomes `flatMap { it.splitCsv(...) }` with a named parameter).
- **`output {}` replaces `publishDir`**: assign in the entry workflow's `publish:` section, declare in `output { name: Channel<T> { path '...'; index { path 'index.csv' } } }`. A path closure may return a map of file to directory; `file >> (cond ? "dir/" : null)` routes single files. One `output` block per script.
- **Typed `params {}`:** no default means required; `Boolean` without default is `false`; `Path` params must exist at launch (use `String` for created paths); reference them only in the entry workflow or the `output` block (matches the "params flow in as values" rule in `nf-core-pipeline-dev`).
- **Pipeline composition** (26.10, experimental): a typed pipeline with `params`/`output` can be included as a workflow (`params` = `take`, `output` = `emit`); must be aliased, config selectors use the alias (`withName: 'RNASEQ:STAR_ALIGN'`), no `publishDir`, no `lib`/`projectDir`/`bin`.

What stands in the way for the user's nf-core pipelines (checked on taxmarker, 2026-11-12):
- `.out` is used throughout `workflows/taxmarker.nf` and the subworkflows; every module has `when: task.ext.when`; modules use `tuple val(meta), path(...)` and the meta-map rule, not records. A typed `main` workflow calling untyped vendored modules is not documented either way: test with a one-process spike before planning.
- `publishDir` lives in `conf/modules.config` (default rule per process name plus many overrides); the `output {}` block would move it into code, and nf-core template tooling still expects `publishDir`.
- The nf-core template and nf-core/modules are untyped; convert only after they move, or in a branch that can follow the template.
- Agent helper: `migrate-nextflow-code` in `nextflow-io/agent-skills` (`/plugin install nextflow@nextflow-io-agent-skills`) iterates with `nextflow lint`. Read its output before accepting; it rewrites signatures and `publishDir`.
