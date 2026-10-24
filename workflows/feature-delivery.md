---
id: workflow.feature-delivery
kind: workflow
title: Feature Delivery
summary: Delivers an approved feature with independent verification and conditional release gates.
status: active
audience: [human, agent]
tags: [domain/buildroom, artifact/workflow, workflow/delivery, risk/standard, risk/high-impact]
applies_to: [buildroom]
depends_on: [role.engineer, role.product-designer, role.security-reviewer, role.frontend-engineer, role.backend-engineer, role.qa-reviewer]
related: [workflow.prd-to-tech-spec]
authority: human-release-approval
owner: buildroom
updated: 2026-10-24
---

# Feature Delivery

1. Johnson — Lead Engineer accepts approved inputs only after a readiness check in `workflow-state.md`: repository instructions, environment access, entry criteria, immutable PRD/spec/decisions, and no unresolved blocker. Set state owner `Johnson — Lead Engineer`, status `implementing`.
2. In `feature-record.md`, record classification, behaviour delta, governing artefacts, exact acceptance criteria, verification strategy, release/exposure scope, and Johnson’s split decision. If the feature materially changes user journeys, navigation, interaction, onboarding, content comprehension, or accessibility, Johnson requests a bounded Hypatia review before implementation. Record its guidance, accessibility criteria, unresolved choices, and Johnson’s disposition in implementation notes; route scope changes to Curie and the human.
3. When scope touches authentication, authorization, sensitive data, external trust boundaries, security-relevant dependencies, or is classified high-impact for security/privacy, Johnson requests Shannon’s threat/risk review before the first consequential implementation action. Record findings, mitigations, verification needs, unresolved risks, and the named human decision in the feature record. Shannon cannot accept or waive risk. For active incidents, do not delay containment for review.
4. Johnson plans and implements small slices, proving unknown or high-risk integration early. When a bounded frontend or backend slice helps, Johnson creates a complete accepted Johnson-to-Lovelace or Johnson-to-Euler hand-off. The specialist returns a complete **proposed** hand-off; Johnson accepts it, regains ownership, integrates it, and records the result before delegating another slice. When both surfaces are needed, use this sequence one specialist at a time; never give two specialists simultaneous ownership.
5. Johnson records deviations, outputs, blockers, integration evidence, and next action in state. No specialist hand-off may go directly to Feynman.
6. Johnson runs developer verification and a self-review against the linked spec; attach commands and results to the feature record.
7. For meaningful changes, obtain independent peer/agent review and triage findings as fixed, deferred with rationale, or rejected with evidence. If Shannon was triggered, include a focused review of the implemented security-sensitive diff and record the disposition before QA.
8. Only Johnson creates the Johnson-to-Feynman hand-off, after all delegated returns are accepted and integrated. It includes entry/exit criteria, decision authority, changed paths, evidence links, pause/resume condition, risks, unresolved items, and acceptance checks. Feynman validates end-to-end criteria, regressions, and relevant negative/accessibility paths.
9. A high-impact route always records the named risk evidence and named human gate before its first consequential action. If deployment or user exposure is in scope, complete release readiness: migration, rollback, release note, monitoring/alert, feature-flag state, support impact, and named human approval. Otherwise record release readiness, production enablement, and monitoring/outcome check as `not applicable` and why.
10. If production enablement is in scope, the named human approves it and state records version, environment, time, and owner. This workflow never deploys automatically; otherwise retain the `not applicable` record from step 9.
11. If released, monitor operational health and the planned outcome signal for the agreed window; return or create follow-up work when evidence fails. Otherwise retain the `not applicable` record from step 9.
12. Feynman sets state to `accepted`, `returned`, or `blocked`. On acceptance, archive the run, update the governing spec/memory links, and record close-out evidence.

**Stop conditions:** acceptance criteria conflict with the spec; a specialist hand-off is missing, unclear, or unaccepted; required checks cannot run; release risk lacks evidence or human approval; production impact is outside the approved scope.
