---
name: nf-core-modules
description: >
  Use when adding, scaffolding, patching, testing or linting an nf-core module or subworkflow
  (vendored or local), writing nf-test files for them, changing a module's container or
  environment.yml, or contributing a fix to nf-core/modules.
---

# nf-core modules and subworkflows

## Adding components

Always scaffold with the nf-core CLI. It registers the component in `modules.json` and matches the structure `modules update` expects.

- Vendored module from nf-core/modules: `nf-core modules install <name>`.
- Local module, even pure glue with no upstream equivalent: `nf-core modules create <tool>/<subtool> --dir . --author @<handle> --label <process_label> --meta --empty-template`, then replace the body. Never start from a blank file or a copied sibling: a copy carries its frozen mistakes (e.g. the older `workflow.containerEngine == 'singularity'` guard, which skips the image under Apptainer; current is `in ['singularity', 'apptainer']`).
- Local subworkflow: `nf-core subworkflows create <name> --dir . --author @<handle>`. The generated body is a placeholder (a `SAMTOOLS_SORT`/`SAMTOOLS_INDEX` chain) to be replaced.
- **Check for an existing nf-core subworkflow before chaining modules yourself:** `nf-core subworkflows list remote | grep -i <topic>` and `gh api "search/code?q=<name>+repo:nf-core/modules+path:subworkflows/nf-core"`. An official one encodes details a hand-wired chain lacks (mmseqs: `mmseqs_fasta_cluster` joins createdb output with the clustering result, correct for more than one input file).
- Take the CLI's naming (lowercase, no underscores: `format/locusfaa`, `FORMAT_LOCUSFAA`) rather than "matching" a badly named sibling.
- Keep the generated `tests/main.nf.test` for local modules too. Build fixtures inline in the `process {}` block.

## Tests

**Always `sanitizeOutput`**, in every `then` block, stub included:
```nextflow
assertAll(
    { assert process.success },
    { assert snapshot(sanitizeOutput(process.out)).match() }
)
```
Don't snapshot `versions` channels separately. For an unstable raw md5 (BAM), use `sanitizeOutput(process.out, readsMD5Keys: ["bam"])`; the key is the **emit name**, and a key matching no channel is silently ignored, leaving a raw md5.

**Run at the Nextflow version CI pins**, not the local default: `NXF_VER=<ci version>` (the failing job prints `N E X T F L O W ~ version X.Y.Z`). Older versions are stricter: 25.10.2 rejected an undefined `params.module_args` that 26.04.6 tolerated (`Unknown config attribute process.withName:...params.module_args`).
Copy the `when` block's `params`/`config` scaffolding from sibling tests, not just the `process` block.
A failure identical across conda, docker and singularity is a test problem, not an engine problem.

**Module-level nf-test cases earn their keep for awk and container behaviour**, since they run in the real container (see `nextflow-gotchas`).

## Containers

**A Wave Singularity image may hold only what `environment.yml` declares.** The Docker build sits on an OS base (`gzip`, `tar`, `sed`, `awk` present); the Singularity build can be the bare conda env under `/opt/wave/.pixi/envs/default/bin`.
A script calling anything not declared works under Docker and dies under Singularity/Apptainer with `command not found`, exit 127. Declare every command the `script:` block runs, and re-check when a change *removes* a tool (the container keeps the old spec until rebuilt).
Some Wave images are Ubuntu-based (`coreutils_hmmer` was), and biocontainers images are Debian-based, so check: `apptainer exec <uri> sh -c 'command -v gunzip tar'`.

**Rebuilding a local module's container:** `nf-core modules containers create <tool>/<subtool>` (beta, tools 4.1.0) writes a `containers:` block to `meta.yml`, per-arch lock files in `.conda-lock/` and the `container` line. It assumes an nf-core/modules checkout, so:
- For `modules/local/`, run it from a scratch dir with `modules/nf-core` symlinked to the repo's `modules/local`.
- Correct the `lock_file:` paths it writes from `modules/nf-core/...` to `modules/local/...`.
- It emits the `container` ternary with `?` and `:` at line starts; rewrite it in the usual shape.
- `nf-core pipelines lint` then fails `container_configs`: fix with `nf-core pipelines lint --fix container_configs`.
- Prefer the `https://community-cr-prod.seqera.io/.../data` form over `oras://` for the Singularity branch.

## Version extraction

A tool's `--version` can report the enclosing git repository. Some tools run `git describe --tags` and fall back to a constant only on failure. Under conda the package sits inside the pipeline checkout, so it reports the pipeline's tag (`emapper-1.4.1-184-g1b3550e`, where `1.4.1` was a metatdenovo tag). Containers usually lack git, so profiles disagree, and a module's own tests can't catch it (nf-core/modules has no tags).
Prefer a source nothing outside the environment can influence: `python -c "from importlib.metadata import version; import sys; print(version(sys.argv[1]))" <dist>`. Pass the arg through `sys.argv`: `nf-core modules lint` compares the eval string with `meta.yml` verbatim and mismatches on escaped quotes and `__dunder__` names.

**Changing an `eval(...)` version string in `main.nf` needs `meta.yml` updated in the same commit** (`correct_meta_outputs`/`correct_meta_topics`), even for a pure simplification. Run `nf-core modules lint <module> --fix`, one module at a time.

## Contributing a fix to nf-core/modules

A real bug in a vendored component (intended behaviour broken) goes straight to a PR, no issue first. New functionality or rework (e.g. adding gzip input) gets an issue first, as a design discussion.
Example: `eggnogmapper`'s `fasta.extension == '.gz'` is always false (`Path.extension` has no leading dot), masked for the default `diamond` mode because DIAMOND reads gzip natively.

**Self-check before requesting review:** bioconda dependency at latest, all optional params routed through `$args`, correct compression for large outputs, tests for every output including optional ones, `meta.yml` with correct EDAM and bio.tools links, version command optimised, comments trimmed (nothing in `script:` that ends up in `.command.sh`).
Review bar for components is stricter than for pipelines: see `review-github-pr`.
