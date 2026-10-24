---
title: 'Allow only curated documentation pages in Pages artifact'
type: 'bugfix'
ticket: ''
created: '2026-10-24'
status: 'built'
route: 'oneshot'
route_source: 'auto'
review: 'thorough'
review_source: 'auto'
lenses_ran: ['blind-hunter', 'edge-case-hunter', 'verification-gap', 'intent-alignment']
review_loop_iteration: 0
context: []
baseline_revision: '7aebd58cf3d67a634c5e8fea97050cd7991319b7'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Pages artifact boundary check rejects the entire `docs/` directory, but MkDocs now correctly publishes the two allowlisted guides beneath `.buildroom-site/docs/` to preserve relative links. This makes CI fail after the new guide paths are included.

**Approach:** Keep the existing exclusions for private repository material, replace the blanket `docs/` exclusion with an explicit check that only the two curated guide pages are present, and assert the expected public output in the verification suite.

</frozen-after-approval>

## Implementation Notes

Oneshot is appropriate: the bug is localized to the GitHub Actions artifact-boundary check and its existing textual regression assertions. The allowlist and MkDocs output layout are already the source of truth; do not change their paths.

Implemented an exact rendered-page check for `.buildroom-site/docs/project-installer/index.html` and `.buildroom-site/docs/run-operations/index.html`, while preserving the exclusions for private repository material. Extended `tests/verify.sh` to assert both paths, the retained exclusions, and the exact-list comparison.

Verification passed: `sh tests/verify.sh`, `bin/build-docs --write`, `uv run --with-requirements requirements-docs.txt python -m mkdocs build --strict --config-file mkdocs.yml`, and `git diff --check`. The built `.buildroom-site/docs/` contains exactly the two allowlisted rendered pages.

Independent quick review: no findings.

Thorough review patches: moved the Pages boundary logic into `bin/verify-pages-artifact.sh`, added explicit missing/unexpected/symlink diagnostics, and added `tests/verify-pages-artifact.sh` covering the exact allowlist and rejection cases. Post-patch `sh tests/verify.sh`, the focused artifact test, and `git diff --check` passed. A final strict MkDocs rerun was blocked because the local uv cache is outside the permitted filesystem and network access to fetch dependencies is unavailable; the strict build had passed before this review-only workflow/test change.

## Review Triage Log

- Medium / patch — Blind Hunter: `find -type f` missed symlinks under the public docs tree; the dedicated checker now rejects links.
- Medium / patch — Blind Hunter: textual assertions did not execute the artifact guard; focused behavioral tests now exercise the checker.
- Medium / patch — Blind Hunter: tests did not demonstrate rejection of a third page; the fixture now verifies that case.
- Medium / patch — Edge Case Hunter: symlinks could evade the allowlist; fixed by explicitly finding and rejecting them.
- Medium / patch — Edge Case Hunter: the “only two pages” claim was not backed by behavioral coverage; the checker and negative fixture now enforce it.
- Low / patch — Edge Case Hunter: a missing guide produced a generic unexpected-pages diagnostic; the checker now reports missing pages separately.
- Medium / patch — Edge Case Hunter: symlink omission was independently reported again; same verified root cause and fix as above.
- Medium / patch — Edge Case Hunter: the ignored-link scenario was independently reported again; same verified root cause and fix as above.
- Medium / patch — Intent Alignment: the approved intent requires output behavior to be covered, while the initial suite only searched workflow text; the new test executes the checker against valid and invalid artifact trees.

## Verification

**Commands:**
- `sh tests/verify.sh` -- expected: complete repository verification succeeds and the workflow assertions cover the allowlisted artifact paths.
- `bin/build-docs --write && uv run --with-requirements requirements-docs.txt python -m mkdocs build --strict --config-file mkdocs.yml` -- expected: MkDocs emits only the curated site, with the two guides under `docs/`.
- `git diff --check` -- expected: no whitespace errors.

**Manual checks:** Confirm the workflow preserves private-path exclusions and rejects unexpected entries beneath `.buildroom-site/docs/`.
