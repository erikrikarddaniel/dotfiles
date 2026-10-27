---
name: nf-core-sync-release
description: >
  Use for nf-core pipeline template syncs (nf-core pipelines sync, TEMPLATE branch, merge conflicts,
  modules/subworkflows update after a sync) and for pipeline releases (release PR, patch release,
  version bump, CHANGELOG date, GitHub release notes, thanking contributors) in the user's pipelines:
  magmap, metatdenovo, phyloplace, taxmarker.
---

# Template syncs and releases

## Template sync

nf-core/tools periodically releases a new template. The user syncs **locally** (`nf-core pipelines sync`, no `--pull-request`), then wants to discuss merge conflicts together rather than have them resolved unilaterally.

1. **Check `nf-core --version` against the latest.** bioconda lags PyPI: `pip install --upgrade nf-core` inside the conda env may be needed.
2. **Make `origin/TEMPLATE` current first.** The sync always tries `git checkout origin/TEMPLATE -b TEMPLATE`, and falls back to a stale *local* `TEMPLATE` if that fails (missing `origin/TEMPLATE`, or a local one already exists). A stale base gives a huge, confusing conflict set.
   `git fetch upstream && git checkout -B TEMPLATE upstream/TEMPLATE && git push origin TEMPLATE`
   (magmap had no `origin/TEMPLATE` and a local one five versions behind; metatdenovo's fork was stuck at 2.2.dev0.)
3. **Never run `git clean -fd` mid-recovery without a dry run.** It destroyed real storeDir caches (`genomes/`, `magmap_prokka/`).
4. With much in-flight work on the target branch, sync on a new branch cut from it, so template conflicts and later update conflicts aren't tangled together.
5. **After a successful sync, push `TEMPLATE` to `origin` immediately.** A stale fork `TEMPLATE` also makes nf-core's automated sync PRs show a diff far larger than the real delta.
6. Then `nf-core modules update --all --no-preview` and `nf-core subworkflows update --all --no-preview`.
   - A local patch (`*.diff`; `git log <module>/environment.yml` shows a `patch` commit) can fail to reapply when upstream changed around the patched lines. Redo the change by hand on the new base, then `nf-core modules patch <module>` (`rm modules/nf-core/<module>/*.diff` first if `--remove` refuses).
7. `nf-core pipelines lint`, then `nf-core pipelines lint --fix <test-name>` for what it flags (`rocrate_readme_sync`, `container_configs`). `--fix` refuses with *any* uncommitted or untracked change: commit or gitignore first.
8. **Pre-patch version strings in snapshots** before the first `nf-test` run: grep `tests/*.nf.test.snap` for the old tool versions from the `environment.yml` diff (`grep -rn '"<tool>":' tests/*.snap`) and change them. Check which tools actually appear.
9. Run `nf-test test --profile=+docker` (**with the `+`**). Without it the CLI value replaces the test's own profile (`test`), dropping its params and producing a failure that looks like a pipeline bug. Check the repo's nf-test CI action for the same pattern.

**CHANGELOG for a sync batch** (PR number not yet known): exactly **one** entry under `Changed`, e.g. "Template update to X.Y.Z and software updates (by @user)", linking `.../pull/NN`, even if the sync and updates are several commits.
Fill the `Dependencies` table with only the tools whose version changed (read off the `environment.yml` diffs, or `git diff <start-ref> HEAD -- '*environment.yml'`). Leave it empty if none. Leave `#NN` for the user.

## Release

Follow https://nf-co.re/docs/developing/pipelines/release-procedure. The default branch may be `master`, not `main`.

Rough order:
1. **Final comment and doc pass over the whole repo**, not just files the release's PRs touched (concise, to the point, clear, sufficiently detailed). It is the last checkpoint before things become visible and permanent.
2. Pre-release issue triage.
3. `nf-core pipelines lint --release`.
4. CHANGELOG finalised: no leftover `#NN`. Name significant reviewers in entries (see `nf-core-pipeline-dev`), before the release PR is reviewed.
5. `nf-core pipelines bump-version`.
6. `dev` → `master` release PR, two reviews via `#release-review-trading`. Often a one-for-one trade with another maintainer.
7. Tag the GitHub release with the bare version (no `v`).
8. Bump `dev` to the next `X.Y.Zdev`.

**The CHANGELOG release date is set last.** Leave `## vX.Y.Z - [yyyy-mm-dd]` as the literal placeholder through the version-bump PR and the release PR, and say in the PR body that the date will follow. Approvals take days.
Once approved, push a "Set release date for vX.Y.Z" commit to `upstream/dev`, then merge. That push is a direct push to upstream `dev`: ask first (see global CLAUDE.md).

**A patch release (X.Y.Z) comes from a branch named exactly `patch`**, not `patch*`, not `patch-1.3.1`. `.github/workflows/branch.yml` (template-managed; don't edit) allows a PR into `master` only from `dev` on the nf-core repo or from a branch named `patch`, and a PR's head can't be changed later.
Cut it from the previous release tag, cherry-pick the fixes' merge commits with `git cherry-pick -m 1 <merge sha>`, expect CHANGELOG conflicts, and fix the version string in test snapshots (`"nf-core/<pipeline>": "vX.Y.Z"`). Afterwards merge `master` back into `dev`.

**GitHub release description:** thank everyone who contributed code or reviewed a PR in the cycle, except the user. Sweep the merged PRs (`gh pr list --state merged`, `gh api .../pulls/N/reviews`, co-author trailers) across the CHANGELOG's PR links, plus the release PR's reviewers.
