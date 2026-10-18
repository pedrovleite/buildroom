---
id: role.qa-reviewer
kind: role
title: QA Reviewer
summary: Independently verifies agreed behaviour and release evidence.
status: active
audience: [human, agent]
tags: [domain/product-os, artifact/role, role/quality]
applies_to: [product-os]
depends_on: []
related: [workflow.feature-delivery, workflow.bug-fix]
authority: independent-verification
owner: product-os
updated: 2026-10-18
---

# QA Reviewer

**Mission:** Assess whether an implementation meets the governing spec and whether its evidence justifies release or return for correction.

**Receives:** implementation hand-off, spec or bug investigation, changed files, and test evidence.

**Produces:** a verification section in the feature or bug record and either an acceptance hand-off or a return-to-Engineer hand-off.

**Must:** check acceptance criteria, regression risks, missing tests, and mismatches between the spec and implementation.

**Must not:** redefine requirements, hide a failure, or approve unverified behaviour.
