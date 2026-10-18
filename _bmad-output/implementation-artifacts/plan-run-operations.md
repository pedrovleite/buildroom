---
title: 'Add explicit Buildroom run operations'
type: 'feature'
ticket: ''
created: '2026-10-18'
status: 'built'
route: 'full'
route_source: 'auto'
review: 'thorough'
review_source: 'auto'
lenses_ran: ['blind-hunter', 'edge-case-hunter', 'verification-gap', 'intent-alignment']
review_loop_iteration: 0
baseline_revision: '655f7f3b5afded355560ad5f670cdc810e80e271'
context:
  - '/Users/pedrovleite/Documents/Codex/2026-10-17/que/product-os/AGENTS.md'
  - '/Users/pedrovleite/Documents/Codex/2026-10-17/que/product-os/product/active/BR-001-run-operations/prd.md'
  - '/Users/pedrovleite/Documents/Codex/2026-10-17/que/product-os/product/active/BR-001-run-operations/tech-spec.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Opening a Buildroom run and discovering whether it is ready to progress currently requires manual folder creation, template copying, and reading several artefacts. That makes the file-first workflow easy to start inconsistently and hard to inspect quickly.

**Approach:** Add explicit portable `start` and read-only `check` commands to the existing Buildroom CLI. They create or inspect one durable run while preserving every workflow's ownership, approval, and human-decision boundaries.

## Boundaries & Constraints

**Always:** Require an explicit workflow, work ID, and initialized target project; use existing `product/active/`, templates, registry aliases, and workflow contracts; keep `check` deterministic and read-only; report concrete corrections without treating an approval as granted; ship identical behavior in the portable package and global plugin bundle.

**Never:** Implicitly initialize a project, choose/advance a workflow, overwrite a run, create a database or background service, deploy, use network access, or replace substantive human review. No-Bullshit Bug Fix must require explicit `--approve-express` and retain its eligibility/regression checks.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Start a normal run | Known workflow, valid new ID, initialized project | One atomic `product/active/<id>/workflow-state.md` with correct workflow, owner, route, and next action | Success, no other artefacts |
| Unsafe start | Unknown/non-workflow name, invalid or duplicate ID, symlink/wrong type/uninitialized target | No state is created or replaced | Actionable error and non-zero exit |
| Start express route | `no-bullshit-bug-fix` with `--approve-express` | Preflight state is created for Engineer | Missing flag fails before write |
| Check fresh run | Valid initial state | `READY` or advisory `WARNING` output, no file change | Exit `0` |
| Check blocked run | Missing state/section/link, unaccepted owner hand-off, or awaiting approval | One `BLOCKER` per issue with a next action; no file change | Exit `1`; invalid/unsafe invocation exits `2` |

</frozen-after-approval>

## Code Map

- `bin/buildroom` -- existing POSIX-shell public interface; retain `list`/`resolve` behavior and dispatch `start`/`check` to the helper.
- `scripts/run-operations.py` -- new standard-library implementation for registry resolution, project/path safety, atomic state creation, and read-only checks.
- `templates/workflow-state.md`, `templates/handoff.md`, `registry.tsv`, `workflows/*.md` -- canonical contracts to read, not rewrite; route map and validation fixtures must remain aligned with them.
- `bin/build-codex-plugin` -- copies the CLI and selected canonical sources into the global toolkit; must include the new helper.
- `plugins/buildroom/skills/buildroom/SKILL.md`, `README.md`, `codex/AGENTS.md.snippet`, `example-project/README.md` -- user and agent routing guidance for explicit run operations and their governance limits.
- `tests/verify.sh`, `tests/verify-codex-plugin.sh`, `tests/verify-run-operations.sh` -- existing package/plugin suites plus the new focused safety and behavior regression suite.

## Tasks & Acceptance

**Execution:**
- [ ] `scripts/run-operations.py` -- add the portable, dependency-free engine: exact registry workflow lookup, strict work-ID/project validation, atomic initial-state creation, and read-only state/link/handoff/approval visibility checks.
- [ ] `bin/buildroom` -- document and dispatch `start`/`check`, forwarding the package root and preserving list/resolve output and errors.
- [ ] `bin/build-codex-plugin` -- bundle the helper so the global plugin toolkit executes the same command path.
- [ ] `tests/verify-run-operations.sh`, `tests/verify.sh`, `tests/verify-codex-plugin.sh` -- prove normal/express creation, all unsafe writes, blocker output, no-mutation behavior, portable invocation, and bundled-helper inclusion.
- [ ] `README.md`, `codex/AGENTS.md.snippet`, `example-project/README.md`, `plugins/buildroom/skills/buildroom/SKILL.md` -- explain command syntax, run-level scope, and that checks surface rather than satisfy gates.

**Acceptance Criteria:**
- Given an initialized project, when a user starts a supported normal workflow with a valid ID, then exactly one valid run state is created with its documented first owner.
- Given unsafe workflow/ID/path/project inputs, when start runs, then it changes nothing and tells the user how to correct the request.
- Given a valid fresh run, when check runs, then it is read-only and exits successfully with clear readiness output.
- Given missing state, unreadable internal links, an incomplete owner hand-off, or an awaiting approval, when check runs, then it reports every structural blocker without claiming the gate passed.
- Given a portable copy or the bundled global plugin, when the same commands run, then their behavior and durable output are equivalent.

## Implementation Notes

## Plan Change Log

## Review Triage Log

- blind-hunter / start race — **medium, patch**: `os.replace` can replace a concurrently-created empty destination directory after the preflight existence check, contradicting the no-overwrite safety contract; claim the destination exclusively before exposing the run.
- blind-hunter / return-to-initial-owner hand-off — **maybe-false**: a state owned by the initial role is also the normal untouched initial state, and the approved checker design has no durable transition record from which to infer a completed loop; no demonstrated bad outcome at this structural-validation scope.
- blind-hunter / incomplete accepted hand-off — **medium, patch**: a matching status and checkbox currently suffice even when the hand-off lacks required structural fields, sections, or readable links; an accepted transfer can therefore be reported READY without a recoverable record.
- blind-hunter / hand-off link coverage — **medium, patch**: evidence and input links in a hand-off are durable run links but are not inspected; a broken local link can be missed on a transferred run.
- blind-hunter / Markdown-link coverage — **medium, patch**: local non-Markdown, image, titled, and reference-style links can be silently skipped, despite the requirement to surface unreadable internal links.
- blind-hunter / invented workflow-state values — **false**: the approved design deliberately checks a small structural subset rather than each workflow's semantic progression; owner and status legitimately change during a run, while the immutable route can be validated directly.
- blind-hunter / approval after status change — **false**: the approved contract makes an `awaiting-*-approval` status visible and blocks it; it does not define a durable approval-history schema that would let `check` reconstruct an approval removed from a later state.
- blind-hunter / hard-coded route map — **false**: the approved plan explicitly fixes the five current route mappings in the dependency-free helper; registry lookup remains canonical for selecting a supported workflow.
- edge-case-hunter / start race — **medium, carried, patch**: same verified `os.replace` destination race as the blind-hunter finding.
- edge-case-hunter / unreadable links — **medium, carried, patch**: same verified gap for local non-Markdown and non-state links as the blind-hunter findings.
- edge-case-hunter / incomplete hand-off — **medium, carried, patch**: same verified accepted-handoff completeness gap as the blind-hunter finding.
- verification-gap / PRD-to-tech-spec mapping — **medium, patch**: no focused fixture exercises the Architect/draft/standard mapping, so an incorrect route table entry could pass all current tests.
- verification-gap / readable evidence link — **medium, patch**: only a rejected escaping link is tested; a valid local link has no acceptance-path regression test.
- verification-gap / accepted hand-off — **medium, patch**: only a proposed hand-off is tested; an accepted, complete transfer has no positive-path test.
- verification-gap / full-project read-only check — **medium, patch**: current snapshots compare individual state files rather than every path and file body in the target project, so an unrelated write could escape regression coverage.
- intent-alignment / workflow-contract divergence — **false**: the frozen intent and approved design explicitly define `check` as structural visibility rather than semantic workflow adjudication; the implementation preserves that boundary and does not claim workflow-specific gate satisfaction.

## Design Notes

The shell remains the stable public command because existing users invoke it directly. A standard-library Python helper isolates structured-file parsing and filesystem safety without introducing an install dependency. The checker uses a deliberately small frontmatter subset and validates record visibility, not the substance of research, evidence, or human judgment.

## Verification

**Commands:**
- `sh -n bin/buildroom` -- expected: the expanded dispatcher is valid POSIX shell.
- `PYTHONPYCACHEPREFIX=/tmp/buildroom-pyc python3 -m py_compile scripts/run-operations.py` -- expected: helper parses without writing into user caches.
- `sh tests/verify-run-operations.sh` -- expected: creation, safety, validation, portable, and no-mutation fixtures pass.
- `bin/build-knowledge --check && bin/build-docs --write && bin/build-docs --check` -- expected: canonical metadata and public documentation staging remain current.
- `bin/build-codex-plugin --write && bin/build-codex-plugin --check && sh tests/verify-codex-plugin.sh && sh tests/verify.sh` -- expected: bundle and complete regression contracts pass.
- `uv run --with-requirements requirements-docs.txt python -m mkdocs build --strict --config-file mkdocs.yml` -- expected: the public site builds strictly.
