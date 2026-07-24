# CLAUDE.md

Global instructions for Claude Code, applied across all projects on this machine.

## nf-core pipeline repos (e.g. nf-core/ampliseq and similar)

Before considering any change ready / before a PR, run all of the following (the user often forgets the first one, so do it proactively):

1. `prek run -a` — pre-commit hooks (prettier, trailing-whitespace, end-of-file-fixer, nextflow-lint). Available in the `nf-core` conda env if not on PATH (`conda activate nf-core`).
2. `nf-core pipelines lint` (add `--release` when the PR targets `master`/`main`) — nf-core community pipeline-standards lint. Also in the `nf-core` conda env.
3. `nextflow lint .` — Nextflow "strict syntax" lint. Run it with two Nextflow versions: the minimum version declared in the pipeline's `nextflow.config` (`nextflowVersion = '!>=X.Y.Z'`) and the latest available. (This linter only supports Nextflow >=26.04, so pipelines with an older stated minimum can't be tested at that exact floor — use the oldest >=26.04 available in that case.) Use `NXF_VER=<version> nextflow lint .` to pin the version for a run.
