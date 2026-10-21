---
name: buildroom-init
description: Explicitly initialize Buildroom durable state in the current target repository without replacing its existing instructions or creating a workflow run. Use only when the user asks to initialize, set up, or add Buildroom to a repository, or to migrate a legacy Product OS repository.
---

# Initialize Buildroom in a repository

This skill is intentionally explicit: never initialize a repository merely because Buildroom was mentioned.

1. Confirm the target repository directory from the current workspace. If it is unclear, ask the user; do not initialize a parent directory by assumption.
2. From this skill's installed plugin root, run `scripts/init-project.py` with the target repository as its only argument. The script is idempotent: it creates only `product/active`, `product/archive`, `product/memory/index.md`, and `product/memory/decision-log.md` when absent, inserts or refreshes only its own delimited block in `AGENTS.md`, and adds `graphify-out/` to `.gitignore` without changing existing lines. A single legacy Product OS block is replaced with the Buildroom block. Repository initialization does not create the graph; Buildroom generates the local code-only graph lazily when the first code-focused task needs it.
3. If the script reports malformed Buildroom or legacy Product OS markers, stop and show the repair instruction. Never replace surrounding `AGENTS.md` content or an existing workflow run.
4. Report the repository path and the files created or preserved. Explain that a workflow run is created only when the user starts specific work.

Graphify is a required companion and needs Python 3.10+ plus `uv` or `pipx`; install the `graphifyy` package and register its Codex skill with `graphify install --platform codex`. Its code-only graph is generated locally and needs no model/API credentials. The global plugin supplies roles and workflows. The repository owns all product memory, hand-offs, decisions, evidence, and active runs.
