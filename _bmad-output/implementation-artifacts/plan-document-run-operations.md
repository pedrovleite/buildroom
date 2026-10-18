---
title: 'Document Buildroom run operations'
type: 'feature'
ticket: ''
created: '2026-10-18'
status: 'built'
route: 'oneshot'
route_source: 'auto'
review: 'quick'
review_source: 'auto'
lenses_ran: ['quick']
review_loop_iteration: 0
baseline_revision: '75d4fe572b51ae184f7dcb1dd4e8d4c090a16d03'
context:
  - '/Users/pedrovleite/Documents/Codex/2026-10-17/que/product-os/README.md'
  - '/Users/pedrovleite/Documents/Codex/2026-10-17/que/product-os/docs/public-content.yml'
  - '/Users/pedrovleite/Documents/Codex/2026-10-17/que/product-os/mkdocs.yml'
  - '/Users/pedrovleite/Documents/Codex/2026-10-17/que/product-os/scripts/run-operations.py'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The public site contains only a compact run-operations section inside the operating model, so the new `start` and `check` commands are hard to discover and lack an approachable reference.

**Approach:** Add one dedicated public guide, link to it from the operating model, and register it in the explicit publication allowlist and MkDocs navigation. The guide explains the exact commands, outcomes, safety boundaries, and express-route governance without exposing private project state.

</frozen-after-approval>

## Implementation Notes

This is a small documentation-only change: the existing allowlisted-docs builder and navigation verification already provide the needed publication checks.

- Added `docs/run-operations.md` as the focused public reference, then registered its source-to-destination mapping and top-level navigation entry.
- Replaced the duplicated README command reference with one link to the public guide, keeping the operating model concise.
- The strict site build rejected a repository-relative link after staging README as `operating-model.md`; the README now uses the canonical public-page URL so the repository and published site both resolve it.

## Plan Change Log

## Review Triage Log

- quick / malformed workflow state — **medium, patch**: a malformed state file is unreadable and exits `2`, not `1`; the public guide now names that `ERROR` outcome rather than presenting it as a structural blocker.

## Verification

**Commands:**
- `bin/build-docs --write && bin/build-docs --check` -- expected: the new guide is safely staged and current.
- `sh tests/verify.sh` -- expected: package and documentation-navigation contracts pass.
- `uv run --with-requirements requirements-docs.txt python -m mkdocs build --strict --config-file mkdocs.yml` -- expected: the public site builds strictly with the new page.
