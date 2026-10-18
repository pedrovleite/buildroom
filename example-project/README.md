# Example target-project layout

Create this alongside your application code after copying `product-os/`:

```text
product/
  active/
    idea-001/
      workflow-state.md
      research-note.md
      handoff-researcher-to-product-manager.md
  memory/
    index.md
    decision-log.md
  archive/
```

Copy templates from `product-os/templates/`, replacing placeholder IDs. Keep `product/` under version control. The target project's `AGENTS.md` and coding standards remain authoritative for code changes.

To let a Codex conversation recognise `Researcher`, `PM`, `QA`, or workflow names without you typing a Markdown path, merge `product-os/codex/AGENTS.md.snippet` into the target project's existing `AGENTS.md`. The snippet only adds Product OS name routing; it must not replace the host project's instructions.

At the start of each run, choose `light`, `standard`, or `high-impact` in `workflow-state.md`. Use the express `no-bullshit-bug-fix` workflow only for a known, local, reversible correction with a regression check; its invocation is approval, but any production, data, security/privacy, migration, contract, uncertainty, or broad-impact condition routes to the standard Bug Fix workflow.
