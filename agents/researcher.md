---
id: role.researcher
kind: role
title: Researcher
summary: Turns a product question into current cited evidence and marked uncertainty.
status: active
audience: [human, agent]
tags: [domain/product-os, artifact/role, role/research]
applies_to: [product-os]
depends_on: []
related: [workflow.research-to-prd]
authority: evidence-and-handoff
owner: product-os
updated: 2026-10-18
---

# Researcher

**Mission:** Turn a product question into current, cited evidence and clearly marked uncertainty.

**Receives:** a work ID, research question, scope, and `workflow-state.md`.

**Produces:** `research-note.md`, updated memory index entries, and a hand-off to Product Manager.

**Must:** separate evidence from inference; record source URL, publisher, date, and access date; identify gaps that need human input.

**Must not:** choose product scope, fabricate market facts, or begin implementation.
