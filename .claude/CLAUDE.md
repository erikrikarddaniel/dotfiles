# CLAUDE.md

Global instructions for Claude Code, applied across all projects on this machine.
Task-specific procedures live in skills under `~/dotfiles/.claude/skills/` (symlinked from `~/.claude/skills/`).
Load the matching skill before starting that kind of work:

- `nextflow-gotchas`: editing any Nextflow code (channel joins, reference inputs, awk in modules, GString, templates, `stageAs`).
- `nf-core-pipeline-dev`: working in a pipeline repo (params, CHANGELOG, docs, test data, test configs, AWS full tests, `errorStrategy`).
- `nf-core-modules`: adding, patching or testing modules and subworkflows, or contributing to nf-core/modules.
- `nf-core-sync-release`: template syncs and pipeline releases.
- `review-github-pr`: reviewing someone else's PR.

## This file's location

`~/.claude/CLAUDE.md` is a symlink to `~/dotfiles/.claude/CLAUDE.md`.
The Edit tool refuses to write through a symlink, so edit the real path.

## AGENTS.md

If a project's root contains an `AGENTS.md`, treat it as a `CLAUDE.md`: read and follow it, in addition to this file.

If the local `AGENTS.md` carries nf-core's pointer to a remote instruction file, actually fetch it fresh each session and follow it.
The URL is `https://raw.githubusercontent.com/nf-core/agents/main/resources/pipeline/AGENTS.md`.
Don't note the pointer and move on, and don't rely on a cached summary.
These takeaways hold regardless of its current wording:

- **Self-disclosure.** Keep the `Co-Authored-By` trailer on commits.
  Say up front, without hedging, that a review or an autonomously opened PR had AI help: "reviewed with Claude Code", "analysis done with Claude Code", not "with some help from".
- **`[skip ci]`** goes in the title of intermediate/WIP pushes only.
  Never on the final review-ready commit, and never on a follow-up commit to an open PR: a `[skip ci]` head leaves the PR with no checks, permanently.
- **Meta map.** Vendored nf-core modules and subworkflows may read only `id` and `single_end` from the meta map.
  Any other field is read or written only by local modules, subworkflows and workflows.
- **Reviews.** One approval for PRs into `dev`, two for `main`/`master`.
- **Snapshots: editing by hand is allowed, overriding the remote file.**
  Work test-first: edit the snapshot to the expected output, see the test fail, then fix the code.
  `--update-snapshot` is fine, but read the diff and decide the new output is right before accepting it.
  If the task bumps the version of a tool, module or container, do that first, so version-only snapshot changes are separate.
  Pair md5s with real content assertions on the same output.
  Regenerate on the CI CPU architecture when an md5 depends on the environment.

A change to a repo's `AGENTS.md` gets its own PR, branched off the target branch.
Never bundle it with other work, however small.

## Locating software

If a command isn't on `PATH`, or several installs exist, ask the user where it is instead of searching the filesystem.
Known locations: `prek`, `nf-core` and `nf-test` are in the `nf-core` conda env (`~/miniconda3/envs/nf-core`).

## Waiting for a background process

Never use `until ! pgrep -f "<pattern>"; do sleep N; done`: the waiter's own command line matches `<pattern>`, so it never ends.
Wait on the PID (`while kill -0 <pid> 2>/dev/null; do sleep N; done`), or bracket one character of the pattern (`pgrep -f "[n]f-test test ..."`).

## Never delete a branch or commit behind a large run

A large run (days of compute, analysed afterwards) must stay reproducible from its code.
Never delete, rebase over, force-push or garbage-collect a branch, tag or commit that such a run launched from, and never clean one up as "merged" or "stale".

Before removing any branch, look for `-r <branch>` in `.nextflow.log` files of the user's run directories, and for the branch name in `~/.nextflow/assets/.repos/<org>/<repo>/clones/`.
If a run used it, keep it or ask.

When a run starts from a branch, also pin it with a tag `run/<project>-<yyyy-mm>` (never a version-like name) and push it to the user's fork.
Nextflow's cached clone is a convenience, not an archive: it doesn't hold a branch deleted on the remote.

## Markdown style

In Markdown files, write one sentence per line.
It is the user's preference, so a changed sentence shows as a one-line diff.
Apply it to new content; don't reformat existing paragraphs unless asked.

## Referring to figures and tables in prose

State the fact first, then point to the display item in parentheses at the end of the sentence.
"Transmembrane architectures were found in 12 genera (@tbl-n)." Not "Transmembrane architectures can be found in @tbl-n."
Applies to figures, tables and supplementary items in any manuscript or Quarto text.

## Code Comments

- Default to no comment. Code shows *how*; comment only to carry *why*: a non-obvious constraint, deliberate deviation, gotcha or workaround.
- Never narrate the code, restate names/types/signatures, or mark block ends.
- Never narrate the change ("fixed X", "updated to Y", "as requested"), and never cite a task, issue or PR number as the reason.
  A comment must read correctly to someone seeing the file fresh. Change context belongs in the commit message.
- State the invariant as a plain fact about the code as it stands: what breaks, and under what condition.
- Delete by default. A comment restating a decision the code already reflects is dead weight, even when it points to a doc.
- Comments must stand on their own with any link removed.
  Banned: specs, section numbers, design docs (they rot). Fine: a maintained doc at a stable path; tickets, RFCs and permalinks as trailing breadcrumbs.
  A system-level "why it's built this way" is extracted into a doc, not left inline or reduced to a pointer.
- Razor every comment you keep. A genuine *why* can still be 3x too long: keep the one fact a reader needs at that line, in the fewest words. A 5-line block almost never survives intact.
- A one-line summary on a public function is fine. TODOs are fine without issue IDs, but a TODO doesn't replace in-scope work.
- In a Nextflow `script:`/`stub:` block, a comment is copied into `.command.sh`, so it is user-visible. Keep those shortest.

## Verifying claims with scripts

When a script written to verify a claim throws on real input, the exception is a finding about the input: the data has a shape the model doesn't cover.
Never patch the crash by narrowing the data (taking `[0]`, coercing a type, dropping a branch) just to finish the run.
Any claim resting on such a script inherits every shortcut taken.
Where the evidence is thin, state the general risk rather than manufacturing a specific instance.

(nf-core/mag#1103: a `TypeError` on a union type `["boolean","string"]` was patched with `st[0]`, which manufactured a type mismatch that went into a posted review.)

## Testing classifier functions: cover the feature space

For an `isX(...)`-style detector, list the 2-4 signals it branches on and write one test per combination of them.
Then ask whether the suite would fail if a simpler, wrong signal had been used. If not for every plausible wrong signal, there is a gap.
Detect on the property that determines the answer, not one merely correlated with it.

(metatdenovo#508: `TCS_ID=` was used as the "raw" signal, but normalised output still contains it. The missing cell, `TCS_ID=` and `ID=` both present, crashed resume.)

Two variants of a test with byte-identical snapshots is the same smell: diff the option-on and option-off snapshots.

## Snapshots show "unchanged", value assertions show "right"

Keep explicit value assertions even when a snapshot or md5 of the same output exists.
A snapshot is generated from the code under test, so a wrong result gets frozen into it, and `--update-snapshot` then accepts any later change unseen.
Assert the specific values a logic change is about, and keep the snapshot beside them as a change detector.
If a reviewer calls the assertions redundant with the md5, explain the difference rather than deleting them.
This holds alongside nf-core/modules' `sanitizeOutput` rule.

## Show the user the tests, every time

The user rarely reads the code, and says tests are where it matters most.
Whenever a change adds or edits a test, or updates a snapshot, show it in chat before calling the work done:

- each test added or changed, by name: what it feeds in, what it asserts, in plain words;
- for each snapshot change: which entries changed and why that is expected (a snapshot that only grew or only changed md5s still gets a line);
- what would make each new assertion fail, i.e. the bug it catches.

End with a one-line reminder to read the test files, naming them.

## Review-worthiness: when to offer an independent review

Review-worthy regardless of diff size: (1) its data flows into a shared or vendored component with an implicit contract; (2) it touches architecture known to be intricate in this codebase.

Offer an independent review in one line, when the work starts or before the PR is filed, if any of these applies:

- a shared or vendored component is touched;
- a rewrite keeps the output identical but changes an assumption about the input (e.g. "per file" instead of "per sample");
- resource labels or defaults change for downstream users (ask for the largest realistic input first);
- test data is built inline, or an edge-case guard is added.

A review by the same model shares its blind spots. Brief a fresh agent with the diff and "what breaks for another pipeline?", never with the reasoning behind the change.

When a codebase has a documented fragile area, self-test new code against it before calling verification complete.
Trace every consumer's contract, not just the path already tested.
When unsure something is a bug, first isolate and run just the suspicious expression; reserve full-scale runs for confirming a fix.

## Bibliographies in analysis projects

Projects from `dltemplates` carry `grateful-refs.bib` (generated, never edited), `tools.bib` (shared tool and database citations, keyed by the tool's own name: `hmmer`, `gtdb`) and `bibliography.bib` (everything else).
Add recurring tools to `tools.bib`, copy it over `~/dev/dltemplates/misc/tools.bib`, and tell the user, who commits that repo. A one-project tool goes in `bibliography.bib`.
Never write a bib entry from memory. Fetch it: `curl -sLH "Accept: application/x-bibtex" "https://doi.org/<doi>"`.
Read what comes back: older records can lack authors (Berman et al. 2000 on the PDB; cite Burley et al. instead).

## nf-core pipeline repos (the user's own: magmap, metatdenovo, phyloplace, taxmarker)

The conventions in the skills are the user's own for these repos. In someone else's pipeline, follow that repo's conventions.
nf-core/taxmarker was renamed from nf-core/sativa: older notes naming sativa mean the same pipeline.

- **No `CLAUDE.md` in nf-core pipeline repos** (core-team consensus, 2026-07). Use `AGENTS.md`. Remove a leftover committed `CLAUDE.md` in whatever PR is in flight.
- **Before any change is ready or goes to a PR, run all four** (the user often forgets the first, so do it proactively):
  1. `prek run -a`
  2. `nf-core pipelines lint` (`--release` when the PR targets `master`/`main`)
  3. `NXF_VER=<min from nextflow.config> nextflow lint .` and again with the latest Nextflow
  4. A comment pass over every changed file, per "Code Comments" above, hunting for AI-narration comments. A comment sitting in a `script:` block ends up in `.command.sh`.

  The `ponytail` and `caveman` plugins were installed 2026-09-17 to curb comment bloat. Whether they help is not yet observed.
- **A new param needs its default in two places**: `nextflow_schema.json` and the top-level `params {}` block of `nextflow.config`.
  The schema default does not backfill at runtime. Skipping the config one makes the param `null` and the feature silently behave as if off.
- **CHANGELOG, parameters, docs, test data, template syncs, modules, releases**: see the skills above.

## Opening PRs (`gh pr create`)

- **Always pass `--web`**, in any repo. It opens a pre-filled compose page the user must submit. In gh 2.45 it does not create the PR.
  After running it, say the page is open and wait. Never follow with a plain `gh pr create` as a "fallback": it makes the PR via the API and the open tab then errors with "PR already exists".
- Repos with `.github/PULL_REQUEST_TEMPLATE.md`: build the body as the template content, then your description under `## Description`. `--body` alone drops the template.
- Fill in the checklist. Tick what is done, delete what doesn't apply, leave unticked only what is applicable and unverified.
- To fix a filed PR body, `gh pr edit --body-file` fails in gh 2.45. Use `gh api -X PATCH repos/OWNER/REPO/pulls/N -F body=@file`.
- Keep the AI-disclosure line.

### PR descriptions: short, first person, shown in chat first

Reviewers read it to decide whether to approve, not to reconstruct the investigation. Two reviewers on two repos said a description was longer than its change.
Put the rest in the commit message.

- Open with two short sentences: the rule, then the violation. No jargon, no mechanism. ("Every ORF should belong to exactly one locus. A spliced gene could end up in two.")
- Then: why (the mechanism, not the path taken to find it), what changed, how it was verified (a list of what was run).
- Cut: benchmark tables, sample data, quoted code, per-finding headings, restating the diff, "first I tried X" stories, and the private run the bug was found on (machine, dataset, fork branch, resume instructions). Describe the failure as a property of the code.
- Keep the linked issue and the CHANGELOG note (including a deliberate absence, with the reason).
- Plain words: "I changed X because Y", not "This PR introduces". No headings.
- Show the draft in chat in a four-backtick `markdown` fence, wait for edits, and use the user's final text.
- A one-file spec or doc fix earns a few lines, however much investigation sits behind it.
- State the invariant before the mechanism. One idea per sentence.

## Direct pushes to upstream dev/master

Always ask for explicit confirmation before `git push upstream dev`, or any direct push to a pipeline's upstream `dev`/`master`, even for routine commits (review feedback, release date, post-release dev bump).
Commit locally, ask, then push. The user doing it themselves without a second thought doesn't mean they want an agent doing it unprompted.

## Process specifications

- Review requests go to `#request-review` on Slack, release PRs to `#release-review-trading`. That is the user's action, never via `gh`.
- A normal PR needs one positive review and no unresolved concerns. Release PRs to `master` need two.
- nf-core prefers merge commits over squashing. Delete feature branches right after merge.
- Authors may dismiss stale "request changes" reviews. A PR with an approval and minor open questions may merge once addressed "to common-sense satisfaction".
