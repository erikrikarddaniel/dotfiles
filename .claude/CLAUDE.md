# CLAUDE.md

Global instructions for Claude Code, applied across all projects on this machine.

## AGENTS.md

If a project's root contains an `AGENTS.md` file, treat it as you would a `CLAUDE.md` — read and follow its instructions for that repo, in addition to this global file. This is how the user wants agent-specific instruction-loading configured: centrally, per-user, rather than via a repo-committed `CLAUDE.md`.

## nf-core pipeline repos (e.g. nf-core/ampliseq and similar)

**Do not add a `CLAUDE.md` file to nf-core pipeline repos.** nf-core core-team consensus (as of 2026-07) is not to allow `CLAUDE.md` in pipeline repos — it could balloon for other coding agents and clutter the repo root. Use `AGENTS.md` only (see above); it's loaded the same way via the instruction just above. If a repo already has a committed `CLAUDE.md`, that's leftover from before this consensus — remove it (folded into whatever PR/branch is already in flight for that repo unless told otherwise).

Before considering any change ready / before a PR, run all of the following (the user often forgets the first one, so do it proactively):

1. `prek run -a` — pre-commit hooks (prettier, trailing-whitespace, end-of-file-fixer, nextflow-lint). Available in the `nf-core` conda env if not on PATH (`conda activate nf-core`).
2. `nf-core pipelines lint` (add `--release` when the PR targets `master`/`main`) — nf-core community pipeline-standards lint. Also in the `nf-core` conda env.
3. `nextflow lint .` — Nextflow "strict syntax" lint. Run it with two Nextflow versions: the minimum declared in the pipeline's `nextflow.config` (`nextflowVersion = '!>=X.Y.Z'`) and the latest available. Use `NXF_VER=<version> nextflow lint .` to target a version — confirmed (nf-core/magmap, minimum `25.10.4`) that `NXF_VER` actually downloads and switches to that exact binary (verify with `NXF_VER=<version> nextflow -version`), and `lint` exists well below 26.04 too — the earlier assumption that it's a 26.04+-only subcommand was wrong, no special-casing needed for older declared minimums.

### Test data

Pipeline repos should carry **no test data of their own** — no fixture files committed
to the pipeline repo, and no local-only file paths in `nf-test` cases either. All of it
belongs in the corresponding `<org>/test-datasets` repo (often the user's own fork, e.g.
`erikrikarddaniel/test-datasets`), on a branch named after the pipeline, fetched remotely
at test time via `params.pipelines_testdata_base_path` + a path — exactly how
`conf/test.config` already builds its `taxonomy`/`alignment`/etc. URLs. This applies to
module-level `nf-test` fixtures too, not just the pipeline-level `-profile test` config —
a module test reading `file("$projectDir/some/local/dir/fixture.tsv")` is the same
violation as a pipeline test with a local path, just at smaller scope.

Confirmed on nf-core/sativa (2026-07-26): a fixtures directory (`run_sativa_tests/`)
accumulated over module development, several of whose files started as symlinks into a
*sibling local clone* of the test-datasets repo on that machine — those symlinks broke
every time that separate local checkout's branch got switched for unrelated work, which
is exactly the kind of local-machine fragility this policy exists to avoid. If a needed
fixture doesn't exist in test-datasets yet, add it there first (on the correct branch)
rather than committing it into the pipeline repo as a stopgap — and check whether a
parallel session might already be pushing to that test-datasets repo before touching it.

### Template syncs

nf-core/tools periodically releases a new version of the pipeline template (the scaffold
`nf-core pipelines create` generates new pipelines from). Keeping a pipeline's boilerplate
current with that template is a "sync" (https://nf-co.re/docs/developing/template-syncs/overview) —
nf-core's GitHub Action opens an automated PR per repo for this, but the user prefers doing
it locally (`nf-core pipelines sync`, no `--pull-request` flag) rather than through the
GitHub web UI, since they're not that comfortable navigating it there. Local sync mechanics:
a `TEMPLATE` branch (shared history with `dev`/`master`, holding only unmodified template
code) gets regenerated, then merged into whatever branch is currently checked out — expect
real merge conflicts wherever the pipeline's own code diverges from the template, which the
user wants to discuss/resolve together rather than have resolved unilaterally. Before
syncing, check `nf-core --version` against the latest available — bioconda's build often
lags a release behind PyPI, so `pip install --upgrade nf-core` inside the conda env may be
needed to get the version that actually has the new template.

When there's a lot of in-flight custom work already on the target branch, sync on a new
branch cut from it first (not directly on top of work you don't want conflict-tangled),
so template conflicts and any later module/subworkflow-update conflicts don't have to be
untangled twice from the same merge.

After a sync, `nf-core modules update --all --no-preview` and
`nf-core subworkflows update --all --no-preview` bring vendored `modules/nf-core/` and
`subworkflows/nf-core/` content current too. Local patches (a module's `*.diff` file, for a
pipeline-specific customization on top of the vendored code — check with
`git log <module>/environment.yml` for a `patch`-labeled commit, or just watch the update
output) sometimes fail to auto-reapply if the upstream module changed enough around the
patched lines (e.g. magmap's `wget` module patch failed after upstream rewrote its
version-reporting mechanism, unrelated to the patched interface itself) — this is a normal
patch-application failure mode, not a sign anything went wrong with the update itself.
Reapply the same functional change by hand against the new base, then regenerate the patch
file properly with `nf-core modules patch <module>` (remove the stale `.diff` first if
`--remove` refuses due to disabled prompts: `rm modules/nf-core/<module>/*.diff`).

Afterwards, run `nf-core pipelines lint`; fix anything it flags with
`nf-core pipelines lint --fix <test-name>` — safe even for generated/boilerplate files like
`ro-crate-metadata.json` (test name `rocrate_readme_sync`) or stale container config files
(test name `container_configs`, shows up after module container versions change). `--fix`
refuses to run with ANY uncommitted or untracked changes present, including untracked files
that should just be gitignored (e.g. local scratch dirs) — commit/gitignore first rather
than fighting it.

Before the first real `nf-test` run after a module update, grep the affected
`tests/*.nf.test.snap` files for the OLD tool versions (from the module's
`environment.yml` diff, e.g. `"samtools": "1.23.1"`) and pre-patch them to the new value —
same principle as the pipeline-version-bump snapshot staleness case, generalized to any
dependency-version bump a module update carries. Cannot hide a real behavioral change (any
other genuine diff still fails the run and needs a real look), but eliminates an entire
wasted run/fail/update-snapshot/rerun cycle when the version string is the only thing that
changed. Not every updated tool's version ends up embedded in snapshots — check which ones
actually appear (`grep -rn '"<tool>":' tests/*.snap`) before assuming.

When running `nf-test` manually to verify a sync/update before committing, pass container
profiles with a `+` prefix — `nf-test test --profile=+docker` — not `--profile docker`.
Without the `+`, the CLI value replaces whatever profile the test itself declares (e.g.
`profile "test"` inside a `.nf.test` file, or a pipeline-wide default `profile = "test"` in
`nf-test.config`) instead of adding to it, silently dropping the test's own params and
producing a failure that looks like a real pipeline bug but is just a wrong invocation.
Confirmed on nf-core/phyloplace, whose `.github/actions/nf-test/action.yml` invokes it as
`nf-test test --profile=+${{ inputs.profile }}` for exactly this reason — check a repo's own
nf-test CI action for the same pattern before assuming plain `--profile <name>` is correct.

When filling in `CHANGELOG.md` for a sync + module/subworkflow-update batch (before the PR
exists yet, so before a real PR number is known): add **exactly one** entry under `Changed`
with a placeholder PR number (`#NN`, linking to `.../pull/NN`), phrased simply, e.g. "Template
update to X.Y.Z and software updates (by @user)" — even if the sync and the module/subworkflow
updates land as separate git commits (they normally do, one per `nf-core pipelines sync` /
`nf-core modules update` / `nf-core subworkflows update` step). Do not add one CHANGELOG line
per commit; the whole batch is one PR-sized unit from the changelog's point of view. Fill in
the `Dependencies` table with **only** the tools whose version actually changed (read off each
affected module's `environment.yml` diff, or confirm via `git diff <start-ref> HEAD --
'*environment.yml'` across the whole batch) — previous version, new version, one row per tool;
leave it empty if nothing changed (e.g. an update was metadata-only, no version bump). Leave
the PR-number placeholder for the user to fill in once the PR number is real.

### Adding modules and subworkflows

Always scaffold new components with the nf-core CLI rather than hand-writing files — it
registers the component in `modules.json`/tracking correctly and matches the expected
structure for later `nf-core modules update`/`nf-core subworkflows update` runs.

- New vendored module from nf-core/modules: `nf-core modules install <name>` (e.g.
  `hmmer/hmmrank`).
- New **local** subworkflow (no official nf-core/modules equivalent, or starting local
  before eventually proposing it upstream): `nf-core subworkflows create <name> --dir .
  --author @<handle>`. In a pipeline repo this scaffolds under `subworkflows/local/<name>/`
  by default (`main.nf`, `meta.yml`, `tests/main.nf.test`) — the generated `main.nf` is
  boilerplate (e.g. a placeholder `SAMTOOLS_SORT`/`SAMTOOLS_INDEX` chain) that still needs
  its `take:`/`main:`/`emit:` filled in with the real logic.
- Before creating a local subworkflow, check nf-core/modules doesn't already have an
  official one for that purpose (`gh api "search/code?q=<name>+repo:nf-core/modules+path:subworkflows/nf-core"`)
  — confirmed absent (nf-core/metatdenovo, `transdecoder`, 2026-07-26) before scaffolding
  the local version.

### Avoid separate (de)compression modules between pipeline steps

The user prefers gzip/gunzip done *inside* the module that actually processes the file,
not as a separate bridging `PIGZ_COMPRESS`/`PIGZ_UNCOMPRESS` step in between two tool
modules — chaining `UNPIGZ -> TOOL -> PIGZ_COMPRESS` leaves a large uncompressed
intermediate sitting in that task's `work/` dir for no reason. If the tool a module wraps
can't read/write gzip natively (verify empirically — don't assume; confirmed on
nf-core/metatdenovo that KofamScan's `exec_annotation` can't read `.gz` input directly,
*and* that a `<(gunzip -c ...)` process-substitution FIFO doesn't work either, since it
invokes the underlying search tool once per profile against the same path and a FIFO can
only be read once), patch the vendored module (`nf-core modules patch <name>`) to
gunzip its own input at the top of the script and gzip its own output at the bottom,
`rm`-ing any decompressed intermediate once the tool is done with it — matching the
pattern nf-core's own `eggnogmapper` module already uses for its input. This does mean
the patched module can no longer realistically be proposed upstream as-is later.

### Opening PRs (`gh pr create --web`)

nf-core pipeline repos have a `.github/PULL_REQUEST_TEMPLATE.md` (instructions comment + checklist). Passing `--body` to `gh pr create` replaces it entirely, which loses the template. Instead, read the template file and build the body as **template content, then your description appended after it** (e.g. under a `## Description` heading) — don't just write your own body from scratch. This applies whether or not `--web` is used.

Always include `--web` when running `gh pr create`, for any repo — it opens a pre-filled browser compose form the user must manually submit, giving them a final edit/review gate before the PR is actually filed, rather than filing it immediately via the API.
