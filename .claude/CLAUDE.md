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

When filling in `CHANGELOG.md` for a sync + module/subworkflow-update batch (before the PR
exists yet, so before a real PR number is known): add one entry under `Changed` with a
placeholder PR number (`#NN`, linking to `.../pull/NN`) describing the sync + updates, and
fill in the `Dependencies` table with **only** the tools whose version actually changed
(read off each affected module's `environment.yml` diff) — previous version, new version,
one row per tool. Leave the placeholder for the user to fill in once the PR number is real.

### Opening PRs (`gh pr create --web`)

nf-core pipeline repos have a `.github/PULL_REQUEST_TEMPLATE.md` (instructions comment + checklist). Passing `--body` to `gh pr create` replaces it entirely, which loses the template. Instead, read the template file and build the body as **template content, then your description appended after it** (e.g. under a `## Description` heading) — don't just write your own body from scratch. This applies whether or not `--web` is used.
