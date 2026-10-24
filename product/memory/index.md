# Product Memory Index

## Active work

| ID | Workflow | Summary | Status | Related |
|---|---|---|---|---|
| [BR-001](../active/BR-001-run-operations/workflow-state.md) | Feature Delivery | Explicit run creation and readiness checking. | awaiting Engineer readiness | [RES-001](../active/BR-001-run-operations/research-note.md), [PRD-001](../active/BR-001-run-operations/prd.md), [SPEC-001](../active/BR-001-run-operations/tech-spec.md) |
| [BR-002](../active/BR-002/workflow-state.md) | Feature Delivery | Conversational Buildroom Master and specialist delegation pilot. | verifying under approved SPEC-002 | [RES-002](../active/BR-002/research-note.md), [PRD-002](../active/BR-002/prd.md), [SPEC-002](../active/BR-002/tech-spec.md), [DEC-002](../active/BR-002/decision-record.md) |
| [BR-003](../active/BR-003/workflow-state.md) | Research to PRD | Node installer for provider-specific Buildroom and Graphify setup. | Codex native smoke passed; Copilot/Claude acceptance conditional | [RES-003](../active/BR-003/research-note.md), [PRD-003](../active/BR-003/prd.md), [SPEC-003](../active/BR-003/tech-spec.md), [Codex smoke](../active/BR-003/codex-native-smoke.md) |

## Decisions

See [decision log](decision-log.md).

## Completed work

| ID | Workflow | Summary | Outcome |
|---|---|---|---|
| [BR-004](../archive/BR-004/workflow-state.md) | Feature Delivery | Conditional Hypatia product-design and Shannon security/privacy specialists. | Feynman accepted; automated checks passed. Copilot/Claude native discovery and fresh-session conversational delegation remain unverified. |

## Artefacts and relationships

- `RES-001` supports approved `PRD-001`; approved `SPEC-001` is handed to Engineering and preserves the file-first model, explicit human gates, and portable command surface.
- `RES-002` supports approved `PRD-002`, `SPEC-002`, and `DEC-002`; implementation and independent code QA are complete in `BR-002`, with fresh-session/runtime and rendered-site validation outstanding before close-out.
- `RES-003` supports approved `PRD-003` and `SPEC-003` for a Node-based Codex/Copilot CLI/Claude Code project installer; automated acceptance, Feynman code verification, and Codex native skill/routing smoke pass. Copilot CLI is unavailable and Claude Master skill discovery remains unverified. Do not release or publish without closing those gaps and receiving human approval.
