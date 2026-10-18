---
id: workflow.bug-fix
kind: workflow
title: Bug Fix
summary: Investigates and corrects a defect with explicit approval and independent verification.
status: active
audience: [human, agent]
tags: [domain/buildroom, artifact/workflow, workflow/bug-fix, risk/standard, risk/high-impact]
applies_to: [buildroom]
depends_on: [role.qa-reviewer, role.engineer]
related: [workflow.no-bullshit-bug-fix]
authority: human-fix-approval
owner: buildroom
updated: 2026-10-18
---

# Bug Fix

1. Intake and classify the defect in `bug-investigation.md` and `workflow-state.md`: expected versus observed behaviour, environment/version, impact, severity, owner, route, evidence, and next action.
2. Decide the route. A production-impacting, security-sensitive, broad-impact, or severity-threshold defect enters the incident branch below; a known small local correction may be assessed against `no-bullshit-bug-fix.md`; every other defect stays on this standard route.
3. QA Reviewer attempts reproduction and bounds the issue. If it cannot reproduce, state remains `triage`, names the missing evidence, and does not hand off implementation.
4. Record diagnosis: root-cause hypothesis and confidence, affected area, contributing conditions, governing decision/spec link, safe fix options, acceptance criteria, and regression coverage.
5. QA Reviewer creates a QA-to-Engineer hand-off with complete entry/exit criteria, evidence links, decision authority, pause/resume condition, risks, and requested output. Set owner `Engineer`, status `awaiting-approval`.
6. Human approves every standard fix plan before implementation. Rejection or changed scope returns the hand-off with the required decision.
7. Engineer implements the approved plan, records outputs/blockers, runs the regression check, and creates an Engineer-to-QA hand-off with entry/exit criteria, decision authority, evidence links, pause/resume condition, patch, and requested verification.
8. QA independently verifies the original reproduction no longer fails, acceptance criteria, negative/error cases where relevant, and the named regression check.
9. Close only with verification evidence: update memory/spec links, set state `accepted`, `returned`, or `blocked`, and archive the run. Recurring or high-severity defects create a tracked preventative follow-up.

## Incident branch

1. Assign coordinator, mitigation owner, and communications owner; maintain a timestamped run trace and stakeholder update cadence.
2. Contain or mitigate first, then investigate; record each action, owner, outcome, and recovery evidence.
3. Independently verify recovery before closure.
4. Create a blameless postmortem with impact, timeline, contributors, preventative actions, owners, priorities, measurable end states, and tracking links.

**Stop conditions:** no reproduction; insufficient logs; unresolved severity; missing approval; incident response requires an operational decision outside this workflow.
