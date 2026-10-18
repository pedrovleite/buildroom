---
id: workflow.prd-to-tech-spec
kind: workflow
title: PRD to Technical Spec
summary: Converts an approved PRD into an implementation-ready technical design.
status: active
audience: [human, agent]
tags: [domain/product-os, artifact/workflow, workflow/specification, risk/standard, risk/high-impact]
applies_to: [product-os]
depends_on: [role.architect, role.engineer]
related: [workflow.research-to-prd, workflow.feature-delivery]
authority: human-design-approval
owner: product-os
updated: 2026-10-18
---

# PRD to Technical Spec

1. Accept a human-approved PRD and classify technical impact in `workflow-state.md`: surface area, data, security/privacy, third-party, compatibility, and release exposure.
2. Architect performs repository reconnaissance: current behaviour, conventions, owners, tests, integrations, and constraints. Record evidence rather than assumptions.
3. Define the behaviour delta: what is added, modified, or removed relative to the governing specification or current implementation.
4. Explore options. Compare alternatives when cost, reversibility, data, security, or operational consequences differ; use a time-boxed spike when repository facts cannot settle the choice.
5. Write `tech-spec.md` with the selected design, interfaces, data effects, failure modes, non-functional requirements, observability, rollback/recovery, acceptance mapping, and test strategy.
6. Create a delivery plan: implementation slices, dependency order, acceptance-to-test mapping, required environments/test data, and expected evidence.
7. Record a `decision-record.md` only for a decision that matters beyond this change; link minor choices from the tech spec and state instead.
8. A high-impact route requires human design approval; standard work records human acknowledgement. Update state with the decision, blockers, and pause/resume condition.
9. Hand off to Engineer only when entry criteria are met, with exit criteria, immutable inputs, decision authority, evidence links, pause/resume condition, exact requested output, and verification checklist.

**Stop conditions:** missing repository context; no feasible bounded option; unresolved security, cost, data, compatibility, or release decision.
