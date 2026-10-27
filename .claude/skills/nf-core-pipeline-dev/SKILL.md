---
name: nf-core-pipeline-dev
description: >
  Use when developing inside one of the user's nf-core pipeline repos (magmap, metatdenovo,
  phyloplace, taxmarker): adding or renaming params, editing nextflow.config, conf/test*.config,
  CHANGELOG.md, docs/ pages, test data in nf-core/test-datasets, DuckDB/parquet conversion,
  errorStrategy or memory settings, AWS full tests, or wiring workflow/subworkflow inputs.
  Not for module or subworkflow component work (nf-core-modules) or syncs and releases (nf-core-sync-release).
---

# nf-core pipeline repos: the user's conventions

These are the user's own conventions for magmap, metatdenovo, phyloplace and taxmarker.
In another maintainer's pipeline (ampliseq, mag, sarek), check that repo's own conventions first.

## Parameters

**Naming**
- A threshold says its bound: `min_*` or `max_*`. E-value thresholds end in `_evalue_cutoff`.
- A step that runs by default is turned off with `skip_<step>` (default `false`). An optional step is turned on with `run_<step>` (default `false`). Never a `skip_*` that defaults to `true`.
- A setting with more than two states is one enum param, not several booleans that can contradict. List the options in a comment after the default: `family_merging = 'all' // ['all', 'created_only', 'none']`.
- Keep the schema groups and the `params` block of `nextflow.config` in pipeline order.
- Name after the stage, not the tool, where tools are swappable (`recruit_min_model_coverage`). But renaming breaks command lines: do it only at a major release, and then set `failUnrecognisedParams = true` in `validation {}`. Without it nf-schema only warns and the run uses the default.
- Keep per-output `save_*` flags rather than one `--save_intermediates`. Several guard huge files (BAMs, trimmed reads).

**Typed `params {}` block in `main.nf`:** declare every optional param nullable, `Type?`.
A `String`, `Integer` or `Float` with no value is required. Nextflow 26.04 tolerates a config `null`; 26.09 edge and 26.10 stop at launch with `Parameter 'x' is required but no value was provided`.
`Boolean` without a default is fine. A non-nullable param defaulted from `getGenomeAttribute()` is required on both versions when that returns null.
Check when adding a param and whenever defaults move out of `nextflow.config`.
taxmarker has six non-nullable numeric params without a default in `main.nf` (2026-10-09), safe only because `nextflow.config` supplies values.

**Two places for a default:** `nextflow_schema.json` and the top-level `params {}` of `nextflow.config`.
The schema default doesn't backfill at runtime. If a new param "isn't doing anything", check this first, and run `nf-core pipelines lint`.

## Params flow in as values

`main.nf` passes `params.*` into `workflows/<pipeline>.nf` as explicit `take:` arguments. Nothing at or below that workflow reads `params.*` directly. (Not ampliseq, a deliberate exception.)
This keeps everything below reusable and testable under another config. The cost is a long positional signature. Accept it, don't reach back into `params`.

## Channel variables

Name every `Channel`-typed variable with a `ch_` prefix. Plain values (booleans, strings, bare paths, numbers) get none.
Raw-input channels are created in one place, `PIPELINE_INITIALISATION` in `subworkflows/local/utils_nfcore_<pipeline>_pipeline/main.nf`: plain params in via `take:`, channels out via `emit:`.
`main.nf` never touches a channel.

## `conf/test*.config` header

The "Use as follows:" line must name the profile the file defines (`-profile test_gzipped,<docker/singularity>` in `conf/test_gzipped.config`), not the `test` profile copied from the file it started from.
Nothing lints this. When adding or touching a test config, sweep the directory: `grep -n 'Use as follows' -A1 conf/test*.config`.

## CHANGELOG.md

- Within each `### \`Section\``, order entries by PR number **descending**: the newest at the top, right after the heading. Check the existing order hasn't drifted.
- Entries are user-facing. Skip CI plumbing such as action digests or SHAs.
- Handles: author, plus a reviewer who shaped the PR (requested changes, found a bug, substantive comments that led to changes). A bare approval or one nit doesn't count. Style `(@author, reviewed by @reviewer)`. Sweep `pulls/N/reviews` and `pulls/N/comments` and propose the list to the user before writing.

## Docs pages

**nf-co.re publishes a `docs/*.md` page only if its path contains `usage` or `output`** (`getDocFiles` in nf-core/website). Anything else 404s there while rendering fine on GitHub, and nothing warns.
Put extra pages under `docs/usage/` (e.g. `docs/usage/large_datasets.md`). Don't touch `docs/README.md`: it is template-managed.
A blanket "publish all of `docs/`" would expose internal planning files in ~20 pipelines (website#4408).

**Cross-doc links** between a pipeline's own pages use plain relative `page.md#anchor` (`usage/resource_guidance.md`, `usage.md#some-anchor`). The site rewrites them to version-preserving URLs.
These stay absolute: the parameters page (`https://nf-co.re/<pipeline>/parameters`), the results page, anything outside `docs/`, the "read this on the nf-core website" banner in `docs/usage.md`, and links in `README.md` and `docs/CONTRIBUTING.md`.
An absolute `nf-co.re/<pipeline>/<page>` link resolves to the released docs, so an anchor that exists only on `dev` returns 200 and silently lands at the page top.

## Test data

The pipeline repo carries **no** test data: no fixture files, no local file paths in nf-test cases, module-level included.
Everything lives in `<org>/test-datasets` (often the user's fork, `erikrikarddaniel/test-datasets`), on a branch named after the pipeline, fetched via `params.pipelines_testdata_base_path` + a path.
Local symlinks into a sibling test-datasets clone break when its branch changes.
If a fixture is missing, add it there first, never commit it to the pipeline as a stopgap. Check first whether a parallel session is pushing to that repo.
Where a module test needs a small input, build it inline in the test's `process {}` block with Groovy.

Document every dataset in that branch's `README.md`, under `## Datasets for nf-core/<pipeline>`, one `###` per dataset: what it is, how it was made (source, selection method, tools), what consumes it. Match the `magmap` branch's style: prose plus the exact filenames.

**Commit straight to the fork's per-pipeline branch, never a topic branch.** Fast-forward the fork's branch (`erikrikarddaniel/test-datasets:metatdenovo`) to its upstream namesake, commit, push, and open the PR between the two same-named branches. Never delete that branch after the merge.
To test against the fork before the merge, swap the org in `pipelines_testdata_base_path` (`erikrikarddaniel` and `nf-core`).

## DuckDB parquet conversion of R tables

`DUCKDB_TABLE2PARQUET` reads `read_csv`, which types a column from the first 20480 rows and treats only the empty string as missing.
An `NA` after that sample fails a numeric column (`Could not convert string "NA" to 'DOUBLE'`). An `NA` inside it makes the column text, with the literal kept.
R writes `NA`, so a table written by R needs `ext.args = "nullstr=['NA','']"` (`ext.args` is for `read_csv` options, `ext.args2` for `COPY`). Don't add `-` to `nullstr`: it is a strand value in magmap's counts tables.
For an aliased module (phyloplace's `DUCKDB_TABLE2PARQUET_TBLOUT`) use `withName: 'DUCKDB_TABLE2PARQUET.*'`.
Check the pipeline's real tables first. phyloplace converts awk-built HMMER tables with no `NA`, so it doesn't need the line; taxmarker has no DuckDB. magmap (#292) and metatdenovo (#608) carry it with a test.
A test that reads `conf/modules.config` directly fails on Nextflow 25.10.4 (`Unknown config attribute process.params.*`): load `nextflow.config`.

## `errorStrategy` and memory

**Template `retry` past `maxRetries` kills running tasks.** Nextflow turns it into `TERMINATE`, not `finish`. The template's `conf/base.config` answers `retry` for exit codes 130-145 on every attempt including the last, so one task failing twice on memory aborts the run (a small task's second OOM killed a two-day KofamScan).
Fix (metatdenovo#588, template fix nf-core/tools#4506):
```groovy
errorStrategy = { task.exitStatus in ((130..145) + 104 + (175..177)) && task.attempt <= task.maxRetries ? 'retry' : 'finish' }
```
The other three pipelines get it at the first sync after #4506 is released: check the line then. Until then, put it in a big run's own config before resuming a run with long tasks in flight (it isn't part of the task hash).

**A task just under its memory limit crawls for hours before the kill.** Near the cgroup limit the kernel keeps evicting and re-reading pages, so runtime says nothing about progress. On an OOM kill raise the limit well above the estimated need, not in small steps.
Never set a flat override (`memory = { 100.GB }`) in a big run's config: without `* task.attempt` the retry gets the same limit. Memory isn't part of the task hash, so raising it costs no cache.
(`SUM_DIAMONDTAX` over 443M rows: at 100 GB, runs of 53 min to 5.6 h before being killed; at 300 GB, 30-35 min, peaking at 157-163 GB.)

## AWS full tests

A green `awsfulltest` job in GitHub Actions only means the Platform launch succeeded. The result is on Platform or in Slack.
Fusion spot snapshots (`sending incremental snapshot signal (SIGUSR1)`, every 5 min) can break a step reading through a pipe: BBMap lost a block from its `bgzip -dc` subprocess and Prokka's `parallel --pipe hmmscan` died. `fusion { snapshots = false }` in the `nextflow_config` block of `awsfulltest.yml` fixed both (metatdenovo#584). Suspect this first when a task dies at a multiple of 5 min.
The website's AWS results tab shows only `results-<release tag sha>`. To fill a release's tab after a failed release run, resume it on Platform with a corrected config, keeping its revision and outdir.

## `nf-core-utils` plugin (idea, not attempted)

`nf-core/nf-core-utils` (`0.5.0`, 2026-05) replaces the three vendored boilerplate subworkflows (`utils_nfcore_pipeline`, `utils_nextflow_pipeline`, `utils_nfschema_plugin`) with plugin functions, and `softwareVersionsToYAML(...)` replaces the hand-rolled `channel.topic("versions")` dance in `workflows/<pipeline>.nf`. That dance caused two past bugs (`groovy.json.JsonGenerator.Options is not defined`; the GString corruption in `nextflow-gotchas`).
Not in the nf-core template yet. Raise it at the next template sync or boilerplate-touching PR.
