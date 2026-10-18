# Product OS for Codex

`product-os` is a portable, file-first operating system for moving work from an idea or bug report to an approved, verified change. It is designed for a single ChatGPT/Codex subscription: a human starts a role in Codex, reviews its output, and explicitly approves each consequential hand-off.

## What it contains

- Five role cards in `agents/`.
- Five workflows in `workflows/`.
- Reusable artefact, hand-off, state, and memory templates in `templates/`.
- A memory contract in `memory/`.
- A validated knowledge catalog and workflow context packs in `knowledge/`.

The durable files, not prior chat messages, are the source of truth. Every workflow run has one `workflow-state.md`; every role-to-role transfer creates a `handoff-<from>-to-<to>.md`.

## Use in this repository

1. Read `knowledge/catalog.yml` to select a route by stable ID, tags, authority, and relationships. For a workflow, use its `context` field to open the generated pack in the listed order.
2. Choose the canonical workflow from `workflows/` and create a run folder under `product/active/<work-id>/`.
3. Copy `templates/workflow-state.md` to that folder and complete it before asking Codex to act.
4. Resolve a role or workflow by name when useful, then give Codex the run-folder path. For example, run `sh product-os/bin/product-os resolve Researcher` or `sh product-os/bin/product-os resolve 'bug fix'`. The response contains the canonical Markdown link and a ready-to-use Codex instruction. You may still name the role card and workflow file directly.
5. At each role transition, copy `templates/handoff.md`, link the produced artefacts, and change the state owner. A recipient must reject an incomplete hand-off instead of guessing.
6. Record material decisions in `product/memory/decision-log.md` and relationships in `product/memory/index.md`.

## Choose the right route

- **Light:** local, low-risk work with clear evidence. Keep the state and verification, but skip conditional discovery, release, and incident stages.
- **Standard:** the default for product work and non-trivial bugs. Use the full research/design or bug investigation path.
- **High-impact:** use when data, privacy/security, production, release, migration, external contracts, or broad customer impact is involved. Resolve the named risk and obtain the human gate before the consequential action.
- **No-Bullshit Bug Fix:** use `no-bullshit-bug-fix.md` only for a known, local, reversible correction with a clear regression check. Starting it is your approval to implement. It never deploys, alters data, handles security/privacy, changes an external contract, or covers unclear/broad-impact defects; any such condition routes immediately to `bug-fix.md` and, when required, its incident branch.

Every route records classification, owner, entry/exit criteria, decision authority, evidence, pause/resume condition, next action, and close-out. Release readiness, production enablement, monitoring, and postmortems are conditional stages: record `not applicable` and why when they are outside a run's scope.

## Install in another project

Copy the `product-os/` directory into the target repository. Then create the folders shown in `example-project/README.md`; no secrets, API key, BMad runtime, or path from this repository is required. Product OS needs only Python 3 from the host standard installation to validate and regenerate its knowledge catalog. Keep the package as a Git subtree, submodule, or copied directory if you want versioned upgrades.

For name-first use in Codex, merge `product-os/codex/AGENTS.md.snippet` into the target repository's existing `AGENTS.md`. It tells Codex to resolve names through `registry.tsv` before asking you for a file path, while leaving the repository's own coding instructions in charge. This is routing guidance, not native slash commands or background agents.

## Knowledge catalog

The canonical instructions stay in `agents/` and `workflows/`; their YAML frontmatter is validated against `knowledge/schema.yml` and the controlled vocabulary in `knowledge/taxonomy.yml`. `knowledge/catalog.yml` is the agent's first read; each workflow entry's `context` field points to its small generated navigation pack. Edit source frontmatter, never generated files.

After changing metadata, run:

```sh
product-os/bin/build-knowledge --write
product-os/bin/build-knowledge --check
```

The builder rejects duplicate or malformed IDs, unknown tags, invalid kinds/statuses, self-references, and broken `depends_on` or `related` links. It also generates `knowledge/catalog.md` and `knowledge/taxonomy.md` for the curated documentation site. This metadata layer is Git-native and private by default; only the separate allowlist below is eligible for publication.

## Curated documentation site

The public documentation site is a presentation layer, not another source of truth. `docs/public-content.yml` is the explicit allowlist: only its Markdown files, plus a generated landing page, can enter `.product-os-docs/`. Templates, memory, tests, local runs, and any new files remain private by default.

After changing source material, build and verify the staged documentation locally:

```sh
product-os/bin/build-knowledge --write
product-os/bin/build-docs --write
product-os/bin/build-docs --check
python3 -m pip install --requirement product-os/requirements-docs.txt
python3 -m mkdocs build --strict --config-file product-os/mkdocs.yml
```

The static result is written to `.product-os-site/`; both directories are ignored. For a local preview after the first build, run `python3 -m mkdocs serve --config-file product-os/mkdocs.yml`.

GitHub Actions publishes only `.product-os-site/` after a push to `main`, using the Pages artifact flow. Before the first deployment, enable **GitHub Actions** as the GitHub Pages publishing source in the repository settings. The repository is private, but this Pages site is deliberately public, so add a file to `docs/public-content.yml` only after deciding it is safe to disclose.

## Name registry

`registry.tsv` is the single mapping between human-friendly names and Product OS files. It includes the five roles and five workflows, with English, Portuguese, and short aliases. Inspect available entries with:

```sh
sh product-os/bin/product-os list
```

Resolve a name with:

```sh
sh product-os/bin/product-os resolve PM
sh product-os/bin/product-os resolve 'bug fix'
sh product-os/bin/product-os resolve 'no bullshit bug fix'
```

Resolution is case-insensitive and deterministic. Unknown names fail with the valid-name command instead of selecting a near match; the user can still continue by naming an explicit `product-os/...` Markdown path.

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

Run `product-os/bin/build-knowledge --check`, `product-os/bin/build-docs --write`, `product-os/bin/build-docs --check`, and `sh product-os/tests/verify.sh` from the repository root. They check the knowledge metadata, generated discovery/context pages, public allowlist boundary, workflows, communication, portability, and file-memory contracts. Install `requirements-docs.txt` as shown above when also running the strict Material static-site build.

## License

MIT. See `LICENSE`.
