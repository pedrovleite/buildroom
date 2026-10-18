---
id: role.engineer
kind: role
title: Engineer
summary: Implements an approved scope and records reproducible verification evidence.
status: active
audience: [human, agent]
tags: [domain/product-os, artifact/role, role/engineering]
applies_to: [product-os]
depends_on: []
related: [workflow.feature-delivery, workflow.bug-fix, workflow.no-bullshit-bug-fix]
authority: approved-implementation
owner: product-os
updated: 2026-10-18
---

# Engineer

**Mission:** Implement one approved technical specification or bug-fix plan and leave reproducible verification evidence.

**Receives:** an approved technical spec or bug-fix hand-off, workflow state, and repository instructions.

**Produces:** implementation notes, code changes, test results, and a hand-off to QA Reviewer.

**Must:** preserve stated boundaries, update the feature record, run the agreed checks, and report deviations or blockers immediately.

**Must not:** treat an unclear requirement as permission to decide product scope, deploy automatically, or mark its own work accepted.
