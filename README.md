# Buildroom for Codex

`buildroom` is a portable, file-first operating system for moving work from an idea or bug report to an approved, verified change. It is designed for a single ChatGPT/Codex subscription: a human starts a role in Codex, reviews its output, and explicitly approves each consequential hand-off.

## What it contains

- Five role cards in `agents/`.
- Five workflows in `workflows/`.
- Reusable artefact, hand-off, state, and memory templates in `templates/`.
- A memory contract in `memory/`.
- A validated knowledge catalog and workflow context packs in `knowledge/`.

The durable files, not prior chat messages, are the source of truth. Every workflow run has one `workflow-state.md`; every role-to-role transfer creates a `handoff-<from>-to-<to>.md`.

## Use in this repository

1. Read `knowledge/catalog.yml` to select a route by stable ID, tags, authority, and relationships. For a workflow, use its `context` field to open the generated pack in the listed order.
2. Start one explicit run with the canonical workflow and a work ID, for example `sh buildroom/bin/buildroom start feature WORK-101`. The command creates only `product/active/WORK-101/workflow-state.md` and prepares its first owner and next action.
3. Inspect a run without changing it with `sh buildroom/bin/buildroom check WORK-101`. A check surfaces structural blockers and the correction needed; it never approves a gate, accepts a hand-off, or advances the workflow.
4. Resolve a role or workflow by name when useful, then give Codex the run-folder path. For example, run `sh buildroom/bin/buildroom resolve Researcher` or `sh buildroom/bin/buildroom resolve 'bug fix'`. The response contains the canonical Markdown link and a ready-to-use Codex instruction. You may still name the role card and workflow file directly.
5. At each role transition, copy `templates/handoff.md`, link the produced artefacts, and change the state owner. A recipient must reject an incomplete hand-off instead of guessing.
6. Record material decisions in `product/memory/decision-log.md` and relationships in `product/memory/index.md`.

## Choose the right route

- **Light:** local, low-risk work with clear evidence. Keep the state and verification, but skip conditional discovery, release, and incident stages.
- **Standard:** the default for product work and non-trivial bugs. Use the full research/design or bug investigation path.
- **High-impact:** use when data, privacy/security, production, release, migration, external contracts, or broad customer impact is involved. Resolve the named risk and obtain the human gate before the consequential action.
- **No-Bullshit Bug Fix:** use `no-bullshit-bug-fix.md` only for a known, local, reversible correction with a clear regression check. Starting it is your approval to implement. It never deploys, alters data, handles security/privacy, changes an external contract, or covers unclear/broad-impact defects; any such condition routes immediately to `bug-fix.md` and, when required, its incident branch.

Every route records classification, owner, entry/exit criteria, decision authority, evidence, pause/resume condition, next action, and close-out. Release readiness, production enablement, monitoring, and postmortems are conditional stages: record `not applicable` and why when they are outside a run's scope.

## Install once for Codex (recommended)

Buildroom can be installed once as a personal Codex plugin, so a new Codex chat can use its roles and workflows in any repository without copying this toolkit first.

From a checkout of this repository, run:

```sh
bin/install-codex-plugin
```

The installer builds and validates an ignored bundle, creates the default personal marketplace on first use, installs the plugin at `~/plugins/buildroom`, and adds `buildroom@personal` to Codex. It does not modify any target repository. Start a **new Codex thread** after installation so its skills are loaded.

In a target repository, ask Codex to **initialize Buildroom in this repository**. The explicit initializer creates only:

```text
product/
  active/
  archive/
  memory/
    index.md
    decision-log.md
```

It also adds a delimited Buildroom block to `AGENTS.md`, preserving every existing instruction. A workflow run, PRD, tech spec, hand-off, or decision is created only when you ask to start that work. Buildroom never stores project state in the global plugin.

To update after pulling a newer version of this repository, run the same command again. It stages and validates the replacement before changing the installed source; if Codex cannot reinstall it, the previous plugin source is restored. Use `bin/install-codex-plugin --dry-run` to validate the installation path without changing your Codex setup.

### Upgrade from Product OS

Rename a portable `product-os/` checkout to `buildroom/` (or update its subtree/submodule path), then update any repository routing snippet to use `buildroom` commands. Re-run `bin/install-codex-plugin`: after Buildroom is installed, it retires a legacy `~/plugins/product-os` source and `product-os@personal` registration when found. Finally, in every existing target repository, ask Codex to **initialize Buildroom in this repository**. That explicit migration replaces only one legacy Product OS marked block in `AGENTS.md`; it preserves surrounding instructions and all `product/` state.

## Install in another project (portable package)

Copy the `buildroom/` directory into the target repository. Then create the folders shown in `example-project/README.md`; no secrets, API key, BMad runtime, or path from this repository is required. Buildroom needs only Python 3 from the host standard installation to validate and regenerate its knowledge catalog. Keep the package as a Git subtree, submodule, or copied directory if you want versioned upgrades.

For name-first use in Codex without the global plugin, merge `buildroom/codex/AGENTS.md.snippet` into the target repository's existing `AGENTS.md`. It tells Codex to resolve names through `registry.tsv` before asking you for a file path, while leaving the repository's own coding instructions in charge. This is routing guidance, not native slash commands or background agents.

## Knowledge catalog

The canonical instructions stay in `agents/` and `workflows/`; their YAML frontmatter is validated against `knowledge/schema.yml` and the controlled vocabulary in `knowledge/taxonomy.yml`. `knowledge/catalog.yml` is the agent's first read; each workflow entry's `context` field points to its small generated navigation pack. Edit source frontmatter, never generated files.

After changing metadata, run:

```sh
buildroom/bin/build-knowledge --write
buildroom/bin/build-knowledge --check
```

The builder rejects duplicate or malformed IDs, unknown tags, invalid kinds/statuses, self-references, and broken `depends_on` or `related` links. It also generates `knowledge/catalog.md` and `knowledge/taxonomy.md` for the curated documentation site. This metadata layer is Git-native and private by default; only the separate allowlist below is eligible for publication.

## Curated documentation site

The public documentation site is a presentation layer, not another source of truth. `docs/public-content.yml` is the explicit allowlist: only its Markdown files, plus a generated landing page, can enter `.buildroom-docs/`. Templates, memory, tests, local runs, and any new files remain private by default.

After changing source material, build and verify the staged documentation locally:

```sh
buildroom/bin/build-knowledge --write
buildroom/bin/build-docs --write
buildroom/bin/build-docs --check
python3 -m pip install --requirement buildroom/requirements-docs.txt
python3 -m mkdocs build --strict --config-file buildroom/mkdocs.yml
```

The static result is written to `.buildroom-site/`; both directories are ignored. For a local preview after the first build, run `python3 -m mkdocs serve --config-file buildroom/mkdocs.yml`.

GitHub Actions publishes only `.buildroom-site/` after a push to `main`, using the Pages artifact flow. Before the first deployment, enable **GitHub Actions** as the GitHub Pages publishing source in the repository settings. The repository is private, but this Pages site is deliberately public, so add a file to `docs/public-content.yml` only after deciding it is safe to disclose.

## Name registry

`registry.tsv` is the single mapping between human-friendly names and Buildroom files. It includes the five roles and five workflows, with English, Portuguese, and short aliases. Inspect available entries with:

```sh
sh buildroom/bin/buildroom list
```

Resolve a name with:

```sh
sh buildroom/bin/buildroom resolve PM
sh buildroom/bin/buildroom resolve 'bug fix'
sh buildroom/bin/buildroom resolve 'no bullshit bug fix'
```

Resolution is case-insensitive and deterministic. Unknown names fail with the valid-name command instead of selecting a near match; the user can still continue by naming an explicit `buildroom/...` Markdown path.

## Run operations

For command reference, examples, exit codes, and the express-route boundary, read the public [Run operations guide](https://pedrovleite.github.io/buildroom/run-operations/). The public documentation navigation also exposes this guide directly.

For a future BMad distribution, package these role cards and workflows as a custom module. The workflow artefacts remain valid whether invoked from BMad, Paperclip, or a direct Codex chat.

## Operating rules

- A role may only write the artefacts owned by its current workflow stage.
- Every claim from research must cite a source in the research note.
- Every implementation stage must link to acceptance criteria and verification evidence.
- The human approves PRDs, technical designs, and production-affecting actions.
- No workflow assumes a background runner, external model API, or graph database.

## Memory now and later

The file-backed memory index is required. A graph backend such as Graphiti is optional: it may ingest IDs, links, timestamps, and decisions from these Markdown files later, but it must never become the only record of a workflow.

## Verify the package

Run `bin/build-knowledge --check`, `bin/build-codex-plugin --write`, `bin/build-codex-plugin --check`, `bin/build-docs --write`, `bin/build-docs --check`, `sh tests/verify.sh`, and `sh tests/verify-codex-plugin.sh` from this repository root. They check the knowledge metadata, global-plugin package, generated discovery/context pages, public allowlist boundary, workflows, communication, portability, and file-memory contracts. Install `requirements-docs.txt` as shown above when also running the strict Material static-site build.

## License

MIT. See `LICENSE`.
