---
title: 'Preserve source-relative paths in published docs'
type: 'bugfix'
ticket: ''
created: '2026-10-24'
status: 'built'
route: 'oneshot'
route_source: 'auto'
review: 'quick'
review_source: 'auto'
lenses_ran: ['quick']
review_loop_iteration: 0
context: []
baseline_revision: 'd6a8a4b6601d86f287965f26b69d6e7ba2732be3'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The strict MkDocs build fails because the published operating model links to `docs/project-installer.md`, while the installer page is staged at the site root. The same link must also remain valid in the repository README.

**Approach:** Preserve the `docs/` directory in the published destinations for the run-operations and project-installer guides, align the navigation, and add fixture assertions for the staged paths and relative links.

</frozen-after-approval>

## Implementation Notes

Oneshot is appropriate: this is a small, mechanical documentation-path correction touching the allowlist, MkDocs navigation, the published Run operations URL, and regression assertions. Independent review caught a README public link to the old generated route; updated it to match the retained `docs/` path.

## Review Triage Log

- 1 finding: patched — `README.md` linked to `/run-operations/`, but preserving the source directory moves the generated route to `/docs/run-operations/`; updated the public link.

## Verification

**Commands:**
- `bin/build-docs --write && bin/build-docs --check` -- expected: documentation is staged and current.
- `python -m mkdocs build --strict --config-file mkdocs.yml` -- expected: strict build succeeds without warnings.
- `sh tests/verify.sh` -- expected: complete repository verification succeeds.
- `git diff --check` -- expected: no whitespace errors.
