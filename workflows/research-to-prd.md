---
id: workflow.research-to-prd
kind: workflow
title: Research to PRD
summary: Turns a product question into evidence, a bounded PRD, and an approved hand-off.
status: active
audience: [human, agent]
tags: [domain/product-os, artifact/workflow, workflow/research, risk/standard]
applies_to: [product-os]
depends_on: [role.researcher, role.product-manager, role.architect]
related: [workflow.prd-to-tech-spec]
authority: human-product-approval
owner: product-os
updated: 2026-10-18
---

# Research to PRD

1. Intake the idea and initialise `workflow-state.md`: set owner `Researcher`, classification (`light`, `standard`, or `high-impact`), user/problem, desired outcome, known constraints, and next action.
2. Frame the decision: record target user or job, pain, assumptions, non-goals, baseline signal, and the human decision required. Pause if the user/problem is unknown.
3. Create a research plan naming the questions, credible source types, and evidence needed to support a commitment.
4. Researcher writes `research-note.md`; every factual claim has a source, every inference is labelled, and missing evidence remains an open question.
5. Product Manager shapes one to three directions: smallest viable scope, appetite, non-goals, dependencies, risks/rabbit holes, and any technical spike required before commitment.
6. Product Manager writes `prd.md` with acceptance criteria and, for customer-facing or experimental work, a success metric, guardrail metric, leading signal, and review window.
7. Human approves, rejects, or narrows the commitment. Record the decision and reason in state; a high-impact route must resolve data, security, production, or release risk before proceeding.
8. Hand off to Architect with entry criteria, exit criteria, immutable inputs, decision authority, evidence links, pause/resume condition, open risks, and requested output. Record a future learning checkpoint only when the work has a measurable outcome.

**Stop conditions:** no credible evidence; unresolved target user/problem; no bounded direction; human rejection; high-impact risk without an owner or decision.
