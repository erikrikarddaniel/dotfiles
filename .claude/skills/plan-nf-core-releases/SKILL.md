---
name: plan-nf-core-releases
description: >
  Use when creating, revising, or re-prioritising a release roadmap (ROADMAP.md) for an
  nf-core / Nextflow pipeline: deciding what goes into the next version, splitting a large
  feature across releases, choosing minor vs major (breaking) version, or mapping open GitHub
  issues, PRs, and a maintainer's to-do list onto upcoming releases. Do not trigger for
  writing the CHANGELOG, cutting/tagging a release, or implementing roadmap items.
---

# Planning nf-core Releases

A roadmap turns three inputs — **open issues, open PRs, the maintainer's agenda** — into a
sequence of small, single-theme releases that each get a quick, to-the-point review. Every
input item ends up in exactly one release or the backlog, and every design fork is either
decided by the maintainer or listed as open.

## Inputs to gather first

1. Repo state: `CHANGELOG.md` (current released version, the `dev` heading),
   `git log --oneline -5`, `modules.json`, `nextflow_schema.json`, `assets/schema_input.json`.
2. `gh issue list -R nf-core/<pipeline> --state open --json number,title,labels` and
   `gh pr list ... --json number,title,changedFiles,isDraft`, then read bodies/comments of
   each open issue (`gh issue view N --json body,comments`) — they hold dependencies
   ("module needed first", "benchmark first") and prior decisions.
3. The maintainer's agenda, numbered. Dedupe against issues (agenda items often *are*
   issues) and note items already delivered by an earlier release.
4. For the headline feature: read the code it replaces (subworkflow, workflow wiring, input
   schema, test profile) and any external tool it integrates, end to end.

## Rules for cutting releases

- **File budget per release**: ask the maintainer; default **< 100 changed files**
  (`git diff --stat main...dev | tail -1`). Estimate with: nf-core module install/bump ≈ 3–5
  files, local module or subworkflow ≈ 4 (main.nf, meta.yml, test, snap), plus pipeline
  tests/snaps, `nextflow_schema.json`, `conf/*.config`, docs/usage + docs/output, CHANGELOG.
  Over budget → split into the next release, never a bigger one.
- **One theme per release.** Riders allowed only if they touch files already in the diff
  (e.g. schema icons when the schema changes anyway).
- **Breaking changes batch into one major.** nf-core semver spec: renamed/removed params,
  added/dropped/renamed *mandatory* samplesheet columns, changed output structure are
  breaking. Pull every known breaking item into that major so users migrate once.
- **External gates first**: new or bumped modules land in nf-core/modules, test data in
  nf-core/test-datasets (pipeline branch). They don't count against the budget but block the
  pipeline PR — list them as PR 0.
- A bug that the headline feature would make worse ships in the same release, before it.
- Research/unscoped items go to a backlog table, not a release.

## Verify, don't recall

- **nf-core rules**: check the specs at source rather than from memory:
  ```bash
  git clone -q --depth 1 --filter=blob:none --sparse https://github.com/nf-core/website.git
  cd website && git sparse-checkout set sites/docs/src/content
  grep -rn "<term>" sites/docs/src/content/docs/specifications
  ```
  Also check sibling nf-core pipelines' `assets/schema_input.json` via `gh api` when a
  naming choice should match the ecosystem, and cite what you found.
- **Param naming**: before proposing a flag, list the pipeline's existing booleans and match
  their convention (commonly `skip_*` for step toggles even when off by default, `save_*`
  for optional outputs, tool-option names for behaviour switches):
  ```bash
  python3 -c "import json;s=json.load(open('nextflow_schema.json'))
  [print(k,v.get('default')) for g in s['\$defs'].values() for k,v in g['properties'].items() if v.get('type')=='boolean']"
  ```

## Decision forks: ask, don't guess

Before writing, ask the maintainer (one batched question, 2–4 options each, recommendation
first) about forks that change the plan: breaking vs additive; minimum required inputs;
where missing data comes from (upstream tool change vs derived in pipeline); how the new
feature interacts with existing steps. Settle defaults they can't care about yourself and
state them. Record every answer in the Decisions log with the date.

## ROADMAP.md structure

1. Header: last revised date, current release, what `dev` already holds.
2. Ground rules: budget, theme rule, external gates, tag legend (`A#n` agenda, `#n` issue).
3. Overview table: release · theme · type (minor/breaking) · est. files · gated by.
4. Headline release in depth: goal; contract (samplesheet/params, with a mapping table when
   two engines share flags); behaviour table per input combination; invariants; bugs and
   riders folded in; **PR plan table with per-PR file estimates**; "Done when" (profiles,
   test cases, lint, migration note).
5. Later releases: short bullets per item, tagged with `A#n` / `#n`, dependencies noted.
6. Backlog table (research, needs scoping, mostly-delivered items).
7. Traceability: agenda → release, open issues → release. Nothing untraced.
8. Decisions log (dated) and Open questions.

## Revising an existing roadmap

Re-pull issues/PRs, diff against the traceability tables, move shipped items out, re-check
budgets for anything re-scoped, and append new decisions instead of rewriting old ones.
Keep old flag/param names out of the file once replaced (`grep` for them).

## Common mistakes

| Mistake | Fix |
| --- | --- |
| Planning only from the agenda | Every open issue and PR appears in a traceability table |
| One giant "next release" | Per-PR file estimates; split at the budget |
| New flag named against convention (`merge_x`, `enable_x`) | Match existing booleans (`skip_x`) |
| Citing an nf-core rule from memory | Grep the specs, cite the file |
| Breaking changes spread over several majors | Batch them into the next major |
| Module/test-data work hidden inside pipeline PRs | PR 0 external gates |
| Design fork silently decided | Ask, or list under Open questions |
