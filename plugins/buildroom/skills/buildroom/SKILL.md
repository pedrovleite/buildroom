---
name: buildroom
description: Route a product idea, PRD, technical design, feature delivery, bug fix, or Buildroom role request through the installed Buildroom workflow system. Use when the user mentions Buildroom or the legacy name Product OS, asks for Researcher, Product Manager/PM, Architect, Engineer, QA, research-to-PRD, PRD-to-tech-spec, feature delivery, bug fix, or no-bullshit bug fix.
---

# Buildroom

Use the bundled canonical references in `references/toolkit/`; they are global capability material, never a place to store project work.

1. Read `references/toolkit/knowledge/catalog.yml` first. Select an exact role or workflow by its ID, title, documented aliases in `references/toolkit/registry.tsv`, tags, authority, and relationships. Do not guess an unknown or ambiguous name: list recognised titles and ask the user to select one.
2. For a selected workflow, read its generated context pack named by `context`, in order, then the canonical role and workflow files linked there. For a selected role, read its canonical role card before acting.
3. Keep every project-specific run, decision, hand-off, evidence item, and memory entry inside `<target-repository>/product/`. Never write that material inside this plugin.
4. If the target repository has not been initialized, explain that Buildroom needs explicit initialization and invoke the `buildroom-init` skill only after the user asks to initialize it. Do not create files merely because the workflow was named.
5. Once initialized, load `<target-repository>/product/active/<work-id>/workflow-state.md` before continuing an existing run. Follow the selected workflow's ownership, hand-off, evidence, stop-condition, and human-approval rules. Repository instructions remain authoritative.

The express No-Bullshit Bug Fix route is valid only when all eligibility rules in its canonical workflow are true. Its invocation is the scoped approval to implement; all other standard fixes still require their named human approval.

For a legacy Product OS repository, explain that the explicit Buildroom initializer upgrades only its marked routing block while preserving the repository's `product/` state and other instructions.
