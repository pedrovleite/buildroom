# Run operations

Run operations create or inspect one durable Buildroom run. They are deliberate, local commands: they do not initialise a project, choose a workflow for you, advance a workflow, or grant a human approval.

## Commands

```sh
sh buildroom/bin/buildroom start <workflow-name-or-id> <work-id> [--project <path>] [--approve-express]
sh buildroom/bin/buildroom check <work-id> [--project <path>]
```

`--project` defaults to the current directory. Discover recognised workflow names with:

```sh
sh buildroom/bin/buildroom list
```

`start` accepts a workflow's canonical name, documented alias, slug, or `workflow.<slug>` ID. It never accepts a role name such as `Researcher`.

## Conversational Master and Codex subagents

With the Buildroom plugin installed, users can describe the desired outcome in ordinary language. The Buildroom skill acts as one conversational Master: it resolves the canonical route, asks only material questions, owns user communication and durable run state, and delegates independent bounded tasks to Codex-native subagents only when useful and available. The Master validates and synthesizes every return; subagents do not approve human gates or own the overall run.

Project initialization installs Buildroom-managed role profiles under `.codex/agents/`. Profiles identify Noether, Curie, Turing, Johnson, Lovelace, Euler, Feynman, Hypatia, and Shannon and inherit the parent Codex session's permissions; they are not separate sandboxes. Hypatia is called selectively for user-facing design/accessibility work; Shannon for security/privacy risk reviews. Neither is invoked for every task, owns implementation, or replaces human gates or Feynman's independent QA. Re-run the initializer after updating Buildroom to refresh only marked Buildroom profiles. Unrelated profiles are preserved; an unmanaged filename collision stops initialization instead of overwriting user work.

Subagents consume additional tokens/usage compared with a single-agent run, so delegation is selective and sequential stages/shared-file edits are not parallelized. If the current Codex session has subagents disabled or unavailable, the Master continues directly when safe or explains why work must pause. Buildroom never falls back to the Agents API, API credentials, or a separately billed runtime. Existing Markdown role cards and accepted hand-offs remain authoritative; custom roles/workflows continue through the catalog/registry and can use a manually added Codex profile or the supplied task-level role instructions.

For conversation behavior, return validation, approvals, and fallback rules, see the installed plugin's `skills/buildroom/references/master-orchestration.md`.

## Start a run

```sh
sh buildroom/bin/buildroom start feature WORK-101 --project .
```

This creates exactly one file:

```text
product/active/WORK-101/workflow-state.md
```

The state is prefilled with the selected workflow, initial owner, status, route, and next action. It is the durable record for the run; create PRDs, hand-offs, and other artefacts only when the applicable workflow calls for them.

The target repository must already be initialised. It needs `AGENTS.md`, `product/active/`, `product/archive/`, `product/memory/`, and the two memory files. `start` refuses unknown workflows, role names, invalid or duplicate IDs, symbolic links, unsafe paths, and uninitialised projects. It never overwrites a run.

Work IDs are required, start with a letter or digit, and contain 1–64 ASCII letters, digits, dots, underscores, or hyphens.

## Inspect a run

```sh
sh buildroom/bin/buildroom check WORK-101 --project .
```

`check` is read-only. It reports structural readiness by inspecting a readable workflow state, its required frontmatter and headings, route consistency, readable in-project links, accepted hand-offs, owner transitions, and visible awaiting-approval states.

It emits these outcomes:

- `READY` — the run is structurally ready. Advisory `WARNING` lines may still appear, such as for empty evidence or current-output sections.
- `BLOCKER` — the run needs correction; every blocker includes a next action. The command exits `1`.
- `ERROR` — the invocation is invalid or unsafe, or Buildroom cannot safely read the state file. The command exits `2` without changing the project.

`READY` and warnings-only results exit `0`.

## Required codebase graph

Graphify is a required local code-navigation companion for Buildroom code tasks; it is separate from Buildroom's product memory and works whether or not the repository has been initialized for Buildroom. The personal Codex plugin installer provisions its CLI and registers its Codex skill. The project installer can instead register it locally for Codex, GitHub Copilot CLI, or Claude Code; see the [project installer guide](project-installer.md). For a manual portable setup, install `graphifyy` with `uv tool install --python '>=3.10' graphifyy` or `pipx install graphifyy`, then use the Graphify install command for the selected provider.

On the first code-focused task, create the graph from the repository root with `graphify extract . --code-only`. Before later queries, refresh changed code incrementally with `graphify update .`, then use `graphify query`, `graphify path`, or `graphify explain` to locate relevant source before broad exploration. The code-only graph is parsed locally, needs no model/API credentials, and is generated under `graphify-out/`; Buildroom initialization adds that directory to `.gitignore` without creating the graph.

If Graphify is unavailable, extraction/query fails, or the repository is unsupported, state the limitation and fall back to bounded direct source inspection. Do not claim the graph was consulted. Buildroom's `product/` records remain authoritative for decisions, approvals, evidence, and run state; Graphify does not require Graphify Cloud or replace that record.

## Express bug fixes

The No-Bullshit Bug Fix route is explicit:

```sh
sh buildroom/bin/buildroom start no-bullshit-bug-fix FIX-42 --approve-express --project .
```

`--approve-express` records the narrow approval to invoke this route. It does not waive eligibility checks, pre-change or post-change regression evidence, human gates outside this route, or the workflow's stop conditions. Use it only for a known, local, reversible correction with a clear regression check. Security, privacy, data, migration, external-contract, production, broad-impact, or uncertain work belongs in the standard Bug Fix workflow.

## What a check cannot do

`check` surfaces structural conditions; it cannot judge the quality of evidence, approve a decision, accept a hand-off on a person's behalf, or move the workflow forward. The workflow artefacts and the named human decision authority remain the source of truth.
