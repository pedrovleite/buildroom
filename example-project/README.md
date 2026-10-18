# Example target-project layout

When using the globally installed Codex plugin, ask Codex to **initialize Buildroom in this repository**. It creates the durable folders below and adds only its marked routing block to the existing `AGENTS.md`; it never creates a run until you start work.

Create this alongside your application code after copying `buildroom/` when using the portable-package mode:

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

After initialization, start a run instead of manually copying the state template: `sh buildroom/bin/buildroom start <workflow-name-or-id> <work-id>`. Add `--project <path>` when needed, and use `--approve-express` only for an explicitly invoked No-Bullshit Bug Fix. `sh buildroom/bin/buildroom check <work-id>` is a read-only structural report; it reveals missing state, evidence, hand-offs, and visible approval requirements without satisfying any of those gates. Keep `product/` under version control. The target project's `AGENTS.md` and coding standards remain authoritative for code changes.

The global plugin already lets a new Codex conversation recognise `Researcher`, `PM`, `QA`, and workflow names. The initializer inserts `codex/AGENTS.global-plugin.snippet` as a marked block so the repository explains where durable state belongs; it must not replace the host project's instructions.

For portable-package mode, merge `buildroom/codex/AGENTS.md.snippet` into the target project's existing `AGENTS.md`. That snippet only adds Buildroom name routing; it must not replace the host project's instructions.

At the start of each run, choose `light`, `standard`, or `high-impact` in `workflow-state.md`. Use the express `no-bullshit-bug-fix` workflow only for a known, local, reversible correction with a regression check; its invocation is approval, but any production, data, security/privacy, migration, contract, uncertainty, or broad-impact condition routes to the standard Bug Fix workflow.
