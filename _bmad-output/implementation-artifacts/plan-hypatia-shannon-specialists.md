---
title: 'Add Hypatia and Shannon specialist agents'
type: 'feature'
ticket: ''
created: '2026-10-24'
status: 'built'
route: 'full'
route_source: 'auto'
baseline_revision: '88c311f783a32301f4d1f56b82fdd75c7dcca8d6'
review: 'thorough'
review_source: 'auto'
lenses_ran: [blind-hunter, edge-case-hunter, verification-gap, intent-alignment]
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Buildroom has no dedicated UX/accessibility designer or security/privacy reviewer, leaving recurring design and risk work without a clear specialist owner.

**Approach:** Add Hypatia — Product Designer and Shannon — Security & Privacy Reviewer as selectively invoked specialists. Connect their canonical role cards to name resolution, provider profiles, applicable workflows, generated knowledge, docs, and checks.

## Boundaries & Constraints

**Always:** Keep delegation conditional and bounded; preserve Curie's product ownership, Turing's technical-design ownership, Johnson's implementation/integration ownership, Feynman's independent QA, and explicit human decision gates. Shannon reports risks and evidence but cannot waive them or approve a release. Hypatia proposes interaction/accessibility guidance but cannot silently expand approved scope.

**Never:** Do not add Knuth, Ramanujan, or Gauss in this change; do not create always-on agents, deploy, publish, or overwrite existing user changes. Preserve the user's existing installer and documentation work.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| UX_RELEVANT_FEATURE | Approved feature changes user-facing behavior, onboarding, or accessibility | Johnson may request a bounded Hypatia design/accessibility review before implementation; no UX change silently alters scope | Return unresolved product decisions to Curie/human |
| SECURITY_RELEVANT_CHANGE | Auth, permissions, sensitive data, external trust boundary, dependency risk, or high-impact security/privacy classification | Shannon supplies threat/risk findings and evidence before the applicable human gate; workflow records disposition | Stop consequential work when required evidence or named human decision is missing |
| ROUTING_AND_INSTALL | User resolves either name or installs Buildroom for a supported provider | Canonical role, context, and provider profile are discoverable; unrelated profiles and local edits remain untouched | Unknown names keep the documented explicit-path fallback; installer collision behavior remains safe |

</frozen-after-approval>

## Code Map

- `agents/` -- canonical role-card source; follow existing frontmatter and concise Mission/Receives/Produces/Must/Must-not format.
- `registry.tsv`, `knowledge/schema.yml`, `knowledge/catalog.yml`, `knowledge/context/` -- name routing, metadata contract, and generated discovery packs; edit source metadata then regenerate, not generated files.
- `workflows/feature-delivery.md`, `workflows/prd-to-tech-spec.md`, `workflows/bug-fix.md` -- add conditional role triggers and complete hand-offs while retaining current owners and gates.
- `plugins/buildroom/skills/buildroom/references/agent-profiles/`, `scripts/project-installer.mjs`, `plugins/buildroom/skills/buildroom/SKILL.md` -- native profile adapters, generated provider role roster, and natural-language routing names.
- `README.md`, `docs/run-operations.md`, `docs/project-installer.md`, `docs/public-content.yml`, `tests/verify.sh`, `tests/project-installer.test.mjs`, `tests/verify-codex-plugin.sh` -- published roster, explicit-publication list, and source/install/runtime regression checks. Several are already dirty from user work; make additive, minimal edits and preserve all existing hunks.

## Tasks & Acceptance

**Execution:**
- [ ] `agents/hypatia.md`, `agents/shannon.md` -- author role cards with scope, authority, evidence, hand-off, and stop rules.
- [ ] `registry.tsv`, canonical workflow files, and affected profile/config sources -- register both specialists and define conditional triggers, sequenced reviews, output records, and human gates.
- [ ] Knowledge generation inputs and provider adapters -- expose canonical roles consistently in catalog, context packs, Codex profiles, and generated Codex/Copilot/Claude project installs.
- [ ] README, user docs, explicit public-content manifest, and tests -- document routing/triggers and verify listings, generated metadata, profile generation, and unchanged safety behavior.

**Acceptance Criteria:**
- Given an ordinary feature with no UX or security relevance, when Feature Delivery runs, then neither specialist is mandatory or invoked by default.
- Given a user-facing interaction change, when the feature meets the documented UX trigger, then Hypatia can return bounded design/accessibility guidance without taking product or implementation ownership.
- Given a security/privacy-relevant design or change, when its trigger is met, then Shannon records risks, evidence, mitigations, and verification needs before the named human gate; no specialist can approve or waive that gate.
- Given either canonical or supported alias name, when resolved or installed for Codex, Copilot CLI, or Claude Code, then the correct role card and provider agent adapter are discoverable.
- Given the repository already contains user-owned profiles or unrelated dirty changes, when verification/installation fixtures run, then they remain preserved and all existing installer safety tests continue to pass.
- Given documentation is built from the public allowlist, when the site content is generated, then both new role pages and updated role counts are published without exposing non-allowlisted files.

## Implementation Notes

## Plan Change Log

## Review Triage Log

| Verdict / route | Finding and evidence |
|---|---|
| medium — patch (fixed) | `tests/master-routing-eval.md` had 15 scenarios but a 10-of-12 threshold, duplicate case number 12, and a recovery reference to the wrong case; the denominator is now 15, the threshold preserves the prior ~83% bar, and case 15 is unique. |
| low — patch (fixed) | `master-orchestration.md` repeated the Hypatia/Shannon routing paragraph verbatim; removed the duplicate. |
| maybe-false — defer | Native Copilot/Claude discovery and role invocation are not exercised by the installer tests; they only validate generated files. Existing notes explicitly say native smoke validation remains outstanding, so actual host incompatibility is unverified and requires those clients for resolution. |
| maybe-false — defer | README and run-operation text describe Codex profile use, but fresh-session conversational delegation has not been validated. Existing BR-002 notes identify this exact runtime check as outstanding. |
| false | The mandatory run/state packet does not create a reachable no-run delegation conflict: the Master contract explicitly says answer directly and do not spawn when no workflow is needed. |
| medium — patch (fixed) | `bug-fix.md` required Shannon review before human approval but did not explicitly preserve its evidence; it now requires findings, mitigations, verification needs, unresolved risks, and human disposition in `bug-investigation.md`. |
| low — patch (fixed) | The three edited workflow files retained stale `updated` metadata; dates are now 2026-10-24 and generated knowledge was refreshed. |
| false | Unchecked execution boxes describe the plan, not runtime behavior; the review rule explicitly rejects findings whose remedy is editing this plan. |
| medium — defer | Manual routing cases 7 and 15 depend on repository/run records but the evaluation document does not prescribe a fixture state; this predates the specialist change and can be settled when the conversational evaluation is run. |
| false | Case 2's initial “Add a settings page” is itself an explicit request to begin; the Master still asks for any material missing product decision before implementation. |
| medium — defer | `project-installer.mjs` uninstall whitespace normalization can alter user-authored blank lines outside managed blocks; this behavior is in the pre-existing installer work and was not introduced by specialist profiles. |
| medium — defer | Uninstall trusts manifest paths and matching hashes without restricting them to installer-created paths; this is a pre-existing installer integrity concern, outside the role integration. |
| medium — defer | An I/O error after an earlier managed-file deletion can leave uninstall partially applied with its manifest; this is pre-existing installer behavior, not caused by the new roles. |
| medium — defer | Initialization writes outputs sequentially, so a later profile-write failure may leave earlier files behind; the initializer already had the same partial-write behavior before this role addition. |
| medium — patch (fixed) | `prd-to-tech-spec.md` did not explicitly route a design classified high-impact for security/privacy to Shannon; its trigger now covers that classification before design approval. |

## Design Notes

Use precise triggers rather than universal participation: Hypatia focuses on user journeys, interaction states, content clarity, keyboard/screen-reader access, and accessibility acceptance criteria; Shannon focuses on threat models, trust boundaries, sensitive data, auth/authorization, dependency/supply-chain concerns, mitigations, and security verification. Their returns inform but do not replace existing workflow owners or human decisions.

## Verification

**Commands:**
- `bin/build-knowledge --check` -- expected: all role metadata, relations, aliases, and generated packs are valid and current.
- `sh tests/verify.sh` -- expected: full repository suite passes, including resolver, workflow, docs, and installer tests.
- `bin/build-docs --write && bin/build-docs --check` -- expected: public docs build successfully and match the explicit allowlist.
- `git diff --check` -- expected: no whitespace errors; inspect that pre-existing user changes remain intact.
