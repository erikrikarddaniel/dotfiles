---
name: review-github-pr
description: >
  Use when reviewing someone else's GitHub PR (any repo, nf-core or not): drafting review comments,
  posting a pending review via the GitHub API, writing the review body, or choosing the verdict
  (approve, comment, request changes). Do not trigger for writing or filing the user's own PR.
---

# Reviewing someone else's PR

## Disclosure

Say up front that the review had AI help: "reviewed with Claude Code" or "analysis done with Claude Code".
The agent normally does the whole analysis and the user discusses it before it is final, so "some help from" is wrong.

## Inline comments

A finding that is a small, literal, single-spot text fix (typo, wrong flag, one-line glob or regex bug, anything with an exact replacement) goes as an inline comment with a ```` ```suggestion ```` fence, so the author gets "Apply suggestion".
Post through `gh api repos/OWNER/REPO/pulls/NUMBER/reviews` with a `comments` array, as a **pending, unsubmitted** review: no `event`.
The user reads every comment in "Files changed", edits, and submits.
Nothing becomes visible to the author before that.

Findings that are not a clean replacement (missing coverage, behaviour traced across files, "is this intentional?") are ordinary comments or prose.

Accepting a suggestion that changes what a snapshot contains also needs the `.snap` regenerated, or CI fails on the next push.

## Review body

- **Leave `body` out of the POST.** The web UI never shows an API-set pending body in "Finish your review". It stays behind as a separate unposted comment.
  Give the body in chat, as the only copy.
- **Paste it verbatim and in full**, never shortened. An inline comment that points to "the review body" relies on it.
- **Put it in a four-backtick fenced block tagged `markdown`.** Copying rendered chat text drops inline backticks.
- `PUT .../reviews/{id}` replaces the body wholesale, it does not append. To extend a pending review, rebuild the full body.
- A submitted review's type can't be changed (`PATCH` edits only the body). To undo a mistaken "Request changes", dismiss it (needs push access): inline comments stay.

## Checks worth running

- Two variants of a test (option on and off) with byte-identical snapshots: diff them. The new option's test then cannot fail (rnasplice#245).
- Tests that cannot fail on the tool's behaviour, inputs no test exercises, wrong `meta.yml` descriptions.
- For channel changes, ask whether each relationship is 1:1, 1:many or a deliberate cartesian, and whether the operator matches (see `nextflow-gotchas`).

## Choosing the verdict

Recommend one and name it; leave the final call to the user.

- **Author maintains the code, findings real but non-blocking** (inconsistencies, nits, questions, no demonstrated bug): **Approve with comments**. The maintainer owns the code, and review queues are long. Say so rather than handing it back as "your judgement".
- **Exception, invested author:** if an Approve risks being read as "good to merge, comments optional", a plain **Comment** can be better. This applies to an author visibly deep in verifying that piece of code, where the findings are test-coverage requests. Flag it as a live consideration.
- **Exception, nf-core/modules and subworkflow components:** stricter bar. Anyone who submits a component becomes its maintainer and many pipelines may vendor it. No-op tests, inputs no test exercises or wrong `meta.yml` descriptions mean at least **Comment**, never Approve with comments. Substantial ones justify Request changes.
- **External contributor, or blocking asks already outstanding from other reviewers:** plain **Comment**.
- **Request changes** is for a defect actually demonstrated to break behaviour, or a correctness risk that can't be settled in comments.
  If CI is already red from that defect and the author has presumably seen it, the user may downgrade to Comment. When drafting, still name Request changes as the recommendation.
