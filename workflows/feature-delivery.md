---
id: workflow.feature-delivery
kind: workflow
title: Feature Delivery
summary: Delivers an approved feature with independent verification and conditional release gates.
status: active
audience: [human, agent]
tags: [domain/buildroom, artifact/workflow, workflow/delivery, risk/standard, risk/high-impact]
applies_to: [buildroom]
depends_on: [role.engineer, role.qa-reviewer]
related: [workflow.prd-to-tech-spec]
authority: human-release-approval
owner: buildroom
updated: 2026-10-18
---

# Feature Delivery

1. Engineer accepts approved inputs only after a readiness check in `workflow-state.md`: repository instructions, environment access, entry criteria, immutable PRD/spec/decisions, and no unresolved blocker. Set state owner `Engineer`, status `implementing`.
2. In `feature-record.md`, record classification, behaviour delta, governing artefacts, exact acceptance criteria, verification strategy, and whether release/exposure is in scope.
3. Plan and implement small slices, proving unknown or high-risk integration early. Record deviations, outputs, blockers, and next action in state.
4. Run developer verification and a self-review against the linked spec; attach commands and results to the feature record.
5. For meaningful changes, obtain independent peer/agent review and triage findings as fixed, deferred with rationale, or rejected with evidence.
6. Create an Engineer-to-QA hand-off with entry/exit criteria, decision authority, changed paths, evidence links, pause/resume condition, risks, unresolved items, and acceptance checks. QA validates end-to-end criteria, regressions, and relevant negative/accessibility paths.
7. A high-impact route always records the named risk evidence and named human gate before its first consequential action. If deployment or user exposure is in scope, complete release readiness: migration, rollback, release note, monitoring/alert, feature-flag state, support impact, and named human approval. Otherwise record release readiness, production enablement, and monitoring/outcome check as `not applicable` and why.
8. If production enablement is in scope, the named human approves it and state records version, environment, time, and owner. This workflow never deploys automatically; otherwise retain the `not applicable` record from step 7.
9. If released, monitor operational health and the planned outcome signal for the agreed window; return or create follow-up work when evidence fails. Otherwise retain the `not applicable` record from step 7.
10. QA sets state to `accepted`, `returned`, or `blocked`. On acceptance, archive the run, update the governing spec/memory links, and record close-out evidence.

**Stop conditions:** acceptance criteria conflict with the spec; required checks cannot run; release risk lacks evidence or human approval; production impact is outside the approved scope.
