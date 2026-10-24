---
id: FEAT-BR-004
status: implementing
related: []
---

# Feature Record

## Objective

Add Hypatia — Product Designer and Shannon — Security & Privacy Reviewer as conditional Buildroom specialists.

## Risk classification and route

Standard, documentation/toolkit behavior only. No deployment, user data processing, release, or production enablement is in scope.

## Governing decision and specification

- Human-approved implementation plan: [plan-hypatia-shannon-specialists.md](../../../_bmad-output/implementation-artifacts/plan-hypatia-shannon-specialists.md).

## Behaviour delta

Buildroom will resolve and provide both canonical role cards and provider-native adapters. Relevant workflows can request each role only when its documented trigger applies; existing owners and human approval gates remain authoritative.

## Acceptance criteria

- Ordinary features do not require or automatically invoke either specialist.
- UX-relevant work can receive bounded design/accessibility guidance from Hypatia without transferring product or implementation authority.
- Security/privacy-relevant work receives Shannon's findings before applicable human risk gates; Shannon cannot waive or approve risk.
- Both role names resolve and supported project installers generate their provider adapters.
- Existing user changes and installer collision/preservation guarantees remain intact.
- Explicitly published documentation includes both role cards and accurate team counts.

## Implementation notes

## Changed areas

- Canonical role cards, registry aliases, taxonomy, generated knowledge/catalog/context packs, and Codex project-agent profiles for Hypatia and Shannon.
- Conditional workflow triggers and bounded duties in PRD-to-Tech-Spec, Feature Delivery, Bug Fix, and the conversational Master.
- Project installer/provider adapters, documentation, routing evaluation scenarios, and verification coverage; existing installer work was preserved.

## Verification evidence

- `bin/build-knowledge --check` — passed after regenerating `knowledge/catalog.yml`.
- `sh tests/verify.sh` — passed, including all 15 project-installer tests.
- `bin/build-docs --write && bin/build-docs --check` — passed; curated allowlist is current.
- `git diff --check` — passed.
- `graphify update .` and a follow-up query — graph rebuilt (1,095 nodes / 2,574 edges) and returned the new role, provider, documentation, and verification nodes.
- Native Copilot/Claude discovery and conversational specialist invocation remain unverified; see review triage and existing provider-status notes.

## QA verdict

Accepted by Feynman on 2026-10-24. Source and generated artifacts match the approved scope; all recorded automated checks passed. Native Copilot/Claude discovery and fresh-session conversational delegation remain unverified.

## Release readiness (conditional)

Not applicable: no release or user exposure is in scope.

## Production enablement (conditional)

Not applicable: this change does not deploy or enable a production feature.

## Monitoring and planned outcome check (conditional)

Not applicable: no production rollout or outcome metric is in scope.

## Close-out and archive
