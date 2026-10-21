---
name: buildroom
description: Route a product idea, PRD, technical design, feature delivery, bug fix, or Buildroom role request through the installed Buildroom workflow system. Use when the user mentions Buildroom or the legacy name Product OS, asks for Noether/Researcher, Curie/Product Manager/PM, Turing/Architect, Johnson/Lead Engineer/Engineer/developer/dev, Lovelace/Frontend Engineer, Euler/Backend Engineer, Feynman/QA, research-to-PRD, PRD-to-tech-spec, feature delivery, bug fix, or no-bullshit bug fix.
---

# Buildroom

Use the bundled canonical references in `references/toolkit/`; they are global capability material, never a place to store project work.

1. Read `references/toolkit/knowledge/catalog.yml` first. Select an exact role or workflow by its ID, title, documented aliases in `references/toolkit/registry.tsv`, tags, authority, and relationships. Do not guess an unknown or ambiguous name: list recognised titles and ask the user to select one.
2. For a selected workflow, read its generated context pack named by `context`, in order, then the canonical role and workflow files linked there. For a selected role, read its canonical role card before acting.
3. Keep every project-specific run, decision, hand-off, evidence item, and memory entry inside `<target-repository>/product/`. Never write that material inside this plugin.
4. If the target repository has not been initialized, explain that Buildroom needs explicit initialization and invoke the `buildroom-init` skill only after the user asks to initialize it. Do not create files merely because the workflow was named.
5. Once initialized, open a new run only when the user explicitly asks, using the bundled `bin/buildroom start <workflow-name-or-id> <work-id> [--project <path>]` command. The No-Bullshit Bug Fix route additionally requires `--approve-express`. For an existing run, use `bin/buildroom check <work-id> [--project <path>]` to surface structural blockers without changing state, then load `<target-repository>/product/active/<work-id>/workflow-state.md` before continuing. A check never grants approval, accepts a hand-off, or advances a run. Johnson is the sole technical owner: optional bounded slices go Johnson → Lovelace/Euler → Johnson, and only Johnson may send integrated work to Feynman. Follow the selected workflow's ownership, hand-off, evidence, stop-condition, and human-approval rules. Repository instructions remain authoritative.

The express No-Bullshit Bug Fix route is valid only when all eligibility rules in its canonical workflow are true. Its invocation is the scoped approval to implement; all other standard fixes still require their named human approval.

For a legacy Product OS repository, explain that the explicit Buildroom initializer upgrades only its marked routing block while preserving the repository's `product/` state and other instructions.

## Codebase navigation with Graphify

Graphify is a required companion for code-focused work, whether or not Buildroom has been initialized in the repository. Before broad source exploration, work from the repository root: if `graphify-out/graph.json` does not exist, create the local code-only graph with `graphify extract . --code-only`; if it exists, refresh changed code incrementally with `graphify update .`. Query it first with `graphify query "<the code question>"`; use `graphify path "<source>" "<destination>"` or `graphify explain "<node>"` when those views help answer the question. Code extraction skips documents and media and needs no model/API credentials. Treat the repository's `product/` Markdown as authoritative for decisions, run state, evidence, and hand-offs.

If Graphify is missing, the repository is unsupported, or extraction/query fails, say what failed and continue with bounded direct inspection; do not imply that the graph was consulted. Refresh incrementally with `graphify update .` after code changes before using the graph again. The generated `graphify-out/` directory is ignored by Git and is created lazily on the first code-focused task, not during repository initialization.
