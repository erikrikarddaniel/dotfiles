# CLAUDE.md

Global instructions for Claude Code, applied across all projects on this machine.

## nf-core pipeline repos (e.g. nf-core/ampliseq and similar)

Before considering any change ready / before a PR, run all of the following (the user often forgets the first one, so do it proactively):

1. `prek run -a` — pre-commit hooks (prettier, trailing-whitespace, end-of-file-fixer, nextflow-lint). Available in the `nf-core` conda env if not on PATH (`conda activate nf-core`).
2. `nf-core pipelines lint` (add `--release` when the PR targets `master`/`main`) — nf-core community pipeline-standards lint. Also in the `nf-core` conda env.
3. `nextflow lint .` — Nextflow "strict syntax" lint. Run it with two Nextflow versions: the minimum declared in the pipeline's `nextflow.config` (`nextflowVersion = '!>=X.Y.Z'`) and the latest available. Use `NXF_VER=<version> nextflow lint .` to target a version. The `lint` subcommand only exists on Nextflow binaries >=26.04, so:
   - If the pipeline's declared minimum is itself >=26.04 (e.g. ampliseq's `26.04.0`), `NXF_VER=<that version>` downloads and runs that exact binary directly — it has `lint` built in, so this just works.
   - If the declared minimum is <26.04, you can't run that ancient binary at all (no `lint`). Per the user: keep a >=26.04 nextflow launcher and pass `NXF_VER=<old version>` as a target-compatibility hint to `lint` instead of switching the actual executed binary — unconfirmed exact mechanism, verify when this case is actually hit.
