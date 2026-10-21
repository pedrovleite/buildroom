---
id: workflow.feature-delivery
kind: workflow
title: Feature Delivery
summary: Delivers an approved feature with independent verification and conditional release gates.
status: active
audience: [human, agent]
tags: [domain/buildroom, artifact/workflow, workflow/delivery, risk/standard, risk/high-impact]
applies_to: [buildroom]
depends_on: [role.engineer, role.frontend-engineer, role.backend-engineer, role.qa-reviewer]
related: [workflow.prd-to-tech-spec]
authority: human-release-approval
owner: buildroom
updated: 2026-10-21
---

# Feature Delivery

1. Johnson — Lead Engineer accepts approved inputs only after a readiness check in `workflow-state.md`: repository instructions, environment access, entry criteria, immutable PRD/spec/decisions, and no unresolved blocker. Set state owner `Johnson — Lead Engineer`, status `implementing`.
2. In `feature-record.md`, record classification, behaviour delta, governing artefacts, exact acceptance criteria, verification strategy, release/exposure scope, and Johnson’s split decision. A split is optional and must name the bounded surface, specialist, return evidence, next owner, and next action.
3. Johnson plans and implements small slices, proving unknown or high-risk integration early. When a bounded frontend or backend slice helps, Johnson creates a complete accepted Johnson-to-Lovelace or Johnson-to-Euler hand-off. The specialist returns a complete **proposed** hand-off; Johnson accepts it, regains ownership, integrates it, and records the result before delegating another slice. When both surfaces are needed, use this sequence one specialist at a time; never give two specialists simultaneous ownership.
4. Johnson records deviations, outputs, blockers, integration evidence, and next action in state. No specialist hand-off may go directly to Feynman.
5. Johnson runs developer verification and a self-review against the linked spec; attach commands and results to the feature record.
6. For meaningful changes, obtain independent peer/agent review and triage findings as fixed, deferred with rationale, or rejected with evidence.
7. Only Johnson creates the Johnson-to-Feynman hand-off, after all delegated returns are accepted and integrated. It includes entry/exit criteria, decision authority, changed paths, evidence links, pause/resume condition, risks, unresolved items, and acceptance checks. Feynman validates end-to-end criteria, regressions, and relevant negative/accessibility paths.
8. A high-impact route always records the named risk evidence and named human gate before its first consequential action. If deployment or user exposure is in scope, complete release readiness: migration, rollback, release note, monitoring/alert, feature-flag state, support impact, and named human approval. Otherwise record release readiness, production enablement, and monitoring/outcome check as `not applicable` and why.
9. If production enablement is in scope, the named human approves it and state records version, environment, time, and owner. This workflow never deploys automatically; otherwise retain the `not applicable` record from step 8.
10. If released, monitor operational health and the planned outcome signal for the agreed window; return or create follow-up work when evidence fails. Otherwise retain the `not applicable` record from step 8.
11. Feynman sets state to `accepted`, `returned`, or `blocked`. On acceptance, archive the run, update the governing spec/memory links, and record close-out evidence.

**Stop conditions:** acceptance criteria conflict with the spec; a specialist hand-off is missing, unclear, or unaccepted; required checks cannot run; release risk lacks evidence or human approval; production impact is outside the approved scope.
