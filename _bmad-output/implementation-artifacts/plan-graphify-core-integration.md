---
title: 'Make Graphify a required Buildroom companion'
type: 'feature'
ticket: ''
created: '2026-10-21'
status: 'built'
route: 'full'
route_source: 'auto'
review: 'thorough'
review_source: 'auto'
lenses_ran: [blind-hunter, edge-case-hunter, verification-gap, intent-alignment]
review_loop_iteration: 0
context: []
baseline_revision: '8a2363d4bf9eb263e2cbfde0706229cd102ac3a3'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Buildroom currently has no integrated code graph, so agents repeatedly rediscover repository structure and consume context reading broad source files. The user wants Graphify included as a standard capability, not an optional add-on, and has only their existing ChatGPT/Codex subscription.

**Approach:** Provision Graphify's open-source CLI and Codex skill as a required companion during the normal Buildroom plugin install. Make Buildroom code workflows build or refresh a local code-only graph and query it before broad source exploration; document the equivalent required setup for portable installs.

## Boundaries & Constraints

**Always:** Use Graphify-Labs/graphify (`graphifyy` package); prefer `uv`, fall back to `pipx`; register its global Codex skill; run code-only extraction locally without requiring model/API credentials; keep generated graph output out of Git by default; keep Buildroom `product/` Markdown as authority for decisions, run state, and hand-offs; leave an already-installed Graphify version untouched.

**Never:** Make Graphify Cloud, another subscription, a graph database, semantic document extraction, or automatic Git hooks prerequisites. Do not vendor Graphify's runtime or overwrite unrelated Codex/repository instructions. On Graphify failure, surface the issue and allow clearly disclosed source-reading fallback rather than pretending the graph was used.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Fresh standard install | Python 3.10+ and `uv` or `pipx` available; Graphify absent | Install Graphify CLI, register Codex skill, then install Buildroom | Any required setup failure stops before replacing the existing Buildroom plugin and names the repair |
| Existing Graphify | CLI already installed | Preserve its version and idempotently ensure Codex integration | Registration failure is reported as install failure |
| Dry run | `bin/install-codex-plugin --dry-run` | Report whether Graphify is present and what would be provisioned; make no changes | Missing prerequisites are reported without installation |
| First Buildroom code task | Local graph absent | Build `graphify-out/` from code only, then query it before broad source reads | If extraction/query fails, disclose why and continue with bounded direct exploration |
| Portable setup | Buildroom copied into another repository | Treat Graphify as a required companion and provide the same local setup steps | Explain the `uv`/`pipx` prerequisite; never suggest Cloud as necessary |

</frozen-after-approval>

## Code Map

- `bin/install-codex-plugin` -- standard install/upgrade lifecycle, dry-run exit, validated bundle swap, rollback, and Codex plugin registration. Provision Graphify before destructive replacement.
- `plugins/buildroom/skills/buildroom/SKILL.md` -- global Buildroom router; add mandatory code-graph discovery/query guidance without changing workflow selection or authority rules.
- `plugins/buildroom/scripts/init-project.py` and `plugins/buildroom/skills/buildroom-init/SKILL.md` -- explicit project setup contract and safe additive edits; reserve `graphify-out/` from accidental commits while preserving existing `.gitignore` content.
- `README.md` and `docs/run-operations.md` -- standard Codex and portable install instructions; distinguish required Graphify code navigation from optional Graphiti memory indexing and publish the supported use pattern.
- `tests/verify-codex-plugin.sh` -- existing installer behavior fixtures and dry-run checks; integration must remain testable without a real package download.
- `bin/build-codex-plugin` -- packages versioned plugin sources and canonical toolkit; Graphify remains a separately installed companion, not vendored bundle content.
- `plugins/buildroom/.codex-plugin/plugin.json` -- Buildroom-only manifest; do not claim Graphify is bundled inside this manifest.

## Tasks & Acceptance

**Execution:**
- [x] `bin/install-codex-plugin` -- detect Graphify; install `graphifyy` through `uv` or `pipx` only when absent; run the official Codex registration; preserve dry-run purity and stop before plugin replacement on prerequisite failure.
- [x] `plugins/buildroom/skills/buildroom/SKILL.md` -- require a local code-only graph and `query`/`path`/`explain` before broad source exploration; refresh after code changes; disclose and fall back if unavailable.
- [x] `plugins/buildroom/scripts/init-project.py`, `plugins/buildroom/skills/buildroom-init/SKILL.md` -- idempotently add `graphify-out/` to `.gitignore` without changing unrelated lines, and document that the graph is generated lazily on first code task rather than during initialization.
- [x] `README.md` and `docs/run-operations.md` -- make Graphify a required companion in global and portable setup instructions; explain local-only code extraction and distinguish Graphify from optional Graphiti memory indexing.
- [x] `tests/verify-codex-plugin.sh` -- adapt existing installer fixtures to simulate Graphify present/absent, missing package managers, registration failure, and dry-run without network access.

**Acceptance Criteria:**
- Given a clean Codex setup with Python 3.10+ and `uv` or `pipx`, when the standard Buildroom installer runs, then it installs Graphify only if missing, registers the Codex skill, and installs Buildroom without requiring a second ChatGPT subscription.
- Given Graphify is already installed, when Buildroom is installed or updated, then the existing Graphify version and unrelated Codex configuration remain unchanged apart from idempotent skill registration.
- Given no `uv`, `pipx`, or usable Graphify CLI, when installation starts, then it fails with actionable instructions before replacing an existing Buildroom installation.
- Given any repository where Buildroom is handling code-focused work, initialized or not, when its first such task starts, then a local code-only graph is available and consulted before broad source exploration; no model credential is required for the code graph.
- Given a Graphify error or unsupported repository, when a code workflow runs, then the agent reports the limitation and uses a bounded direct-inspection fallback without claiming graph coverage.
- Given Buildroom is installed from its portable package, when the user follows its documented setup, then Graphify is described as required and the same local-only behavior applies.

## Implementation Notes

## Plan Change Log

## Review Triage Log

- **Patch — intent-alignment:** Graph guidance was limited to initialized repositories. Removed that condition so all Buildroom code-focused tasks require query-first use; README, public docs, and acceptance wording now agree.
- **Patch — edge-case-hunter:** `uv` failure previously stopped setup despite available `pipx`. Added pipx fallback and a successful simulated fallback test.
- **Patch — edge-case-hunter / blind-hunter:** Existing `.gitignore` CRLF could be rewritten incorrectly on Windows. Write merged content as UTF-8 bytes and retain a CRLF fixture.
- **Patch — verification-gap:** Added symlinked `.gitignore` and incompatible-Python fixtures; they verify no external target or old plugin is modified.
- **Patch — blind-hunter:** Test `uv` shim used to skip generated-plugin validation. It now delegates validation to real `uv` in offline mode; full verification passed.
- **Patch — blind-hunter:** A custom `BUILDROOM_UV_COMMAND` was not used for validator bootstrap. Prefer it, with ordinary `uv` as fallback; tests exercise both.
- **Patch — blind-hunter:** `uv` installs now request Python `>=3.10`, allowing uv's version selection instead of rejecting a compatible managed runtime based on system `python3`.
- **Patch — matrix coverage:** Added an installer test for an already-installed Graphify CLI, proving Buildroom registers the Codex skill without reinstalling Graphify.
- **No patch — blind-hunter:** An existing `graphify` executable resolved from the user's configured command/PATH is treated as their installed Graphify CLI, matching the approved “preserve existing Graphify” behavior; the installer invokes it only for the user-requested Codex registration.
- **Patch — blind-hunter:** `.gitignore` write failure could occur after other initialization writes. The `.gitignore` update is now the first write, after all path/type/content validation, so that failure leaves the other project files untouched.

## Design Notes

Graphify is a companion CLI/skill, not bundled code. The standard installer owns provisioning and Codex registration; Buildroom's global router owns required use on source-code work. Per-project graph creation is lazy to avoid making project initialization slow, and `graphify-out/` is ignored because it is generated derivative data. Buildroom's file-backed decisions, approvals, evidence, and run state remain authoritative; the roadmap's optional Graphiti memory backend is a separate product choice.

## Verification

**Commands:**
- `sh tests/verify-codex-plugin.sh` -- passed; installer fixtures use mocked Graphify/pipx and offline PyYAML validation, without changing the user's Codex installation.
- `bin/build-codex-plugin --check` -- passed; staged global plugin matches canonical sources.
- `bin/build-docs --check` -- passed; public docs staging is current.
- `bin/build-knowledge --check`, shell/Python syntax checks, and `git diff --check` -- passed.

**Manual checks:**
- Installer dry-run and mocked Graphify flows passed; no real Graphify package install or extraction was run because that would alter global Codex setup and requires a real package/network operation.
- Generated skill and initialized-target fixtures confirm global Graphify guidance, ignored graph output, and preservation of existing `AGENTS.md`/`.gitignore` content.
