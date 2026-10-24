# Product Decision Log

Record material decisions with links to their evidence and affected runs.

| Date | Decision | Record | Why it matters |
|---|---|---|---|
| 2026-10-18 | Begin research for explicit run creation and run-readiness checking. | [BR-001](../active/BR-001-run-operations/workflow-state.md) | The user selected this as Buildroom's first operational improvement. |
| 2026-10-18 | Approve the bounded run-operations product scope. | [PRD-001](../active/BR-001-run-operations/prd.md) | Allows technical design while preserving all existing approval gates. |
| 2026-10-18 | Approve the portable standard-library helper design. | [SPEC-001](../active/BR-001-run-operations/tech-spec.md) | Allows Engineering to implement start/check without a new dependency or second state model. |
| 2026-10-23 | Approve PRD-002 for technical design only. | [BR-002](../active/BR-002/workflow-state.md), [PRD-002](../active/BR-002/prd.md) | Authorizes Turing to produce a proposed technical design; implementation still requires separate approval. |
| 2026-10-23 | Propose Codex-native subagents/custom-agent profiles with honest single-agent fallback. | [DEC-002](../active/BR-002/decision-record.md) | Reuses documented Codex delegation without an API runtime; subagents consume additional tokens/usage; subsequently approved under SPEC-002. |
| 2026-10-23 | Approve SPEC-002 and authorize implementation of the conversational Master pilot. | [BR-002](../active/BR-002/workflow-state.md), [SPEC-002](../active/BR-002/tech-spec.md) | Starts Buildroom-native conversational coordination and Codex subagent profiles; release/deployment remains outside scope. |
| 2026-10-23 | Approve PRD-003 for technical design; select Copilot CLI only and defer npm distribution. | [BR-003](../active/BR-003/workflow-state.md), [PRD-003](../active/BR-003/prd.md) | Bounds provider adapters and distribution for the first Node installer; implementation still requires SPEC-003 approval. |
| 2026-10-23 | Approve SPEC-003 and authorize bounded implementation of the project-local provider installer. | [BR-003](../active/BR-003/workflow-state.md), [SPEC-003](../active/BR-003/tech-spec.md) | Authorizes code and test work for Codex, Copilot CLI, and Claude Code only; npm publication, release, and deployment remain out of scope. |
