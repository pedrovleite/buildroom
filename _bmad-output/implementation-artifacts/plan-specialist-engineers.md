---
title: 'Specialist engineering roles'
type: 'feature'
ticket: ''
created: '2026-10-21'
status: 'built'
baseline_revision: 'f6f9f63599a10e627925c943ae15549e345cb91b'
route: 'full'
route_source: 'auto'
review: 'thorough'
review_source: 'pinned'
lenses_ran: [blind-hunter, edge-case-hunter, verification-gap, intent-alignment]
review_loop_iteration: 1
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Buildroom has one undifferentiated Engineer role. It cannot clearly route frontend and backend work, while preserving a single technical owner for integration and accountability.

**Approach:** Present the existing roles with the agreed mathematician/physicist names, evolve Engineer into Johnson — Lead Engineer, and add Lovelace — Frontend Engineer and Euler — Backend Engineer. Johnson assesses approved work, delegates bounded specialist slices through durable hand-offs, integrates their work, and is the only engineering sender to Feynman QA.

## Boundaries & Constraints

**Always:** Keep human approval gates, durable workflow state, complete hand-offs, independent QA, generated knowledge files, and the portable plugin in sync. Preserve existing Engineer resolution as an alias to Johnson. Use the named roles: Noether (Researcher), Curie (Product Manager), Turing (Architect), Johnson (Lead Engineer), Lovelace (Frontend Engineer), Euler (Backend Engineer), and Feynman (QA Reviewer).

**Never:** Add automatic delegation, allow specialists to broaden approved scope or self-accept work, make the express bug route delegate, weaken release/security/approval gates, or store project state in the global plugin.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Simple approved change | Feature or standard bug needs no specialist split | Johnson implements, verifies, and hands off to Feynman | Existing gates still apply |
| Frontend/backend slice | Johnson identifies a bounded surface in an approved scope | A complete Johnson-to-specialist hand-off is accepted; specialist returns a complete hand-off to Johnson; Johnson integrates before QA | Missing/unclear hand-off leaves state with Johnson and blocked/awaiting information |
| Mixed change | Both surfaces are needed | Johnson may coordinate two independent specialist hand-offs and records the next owner/action | No QA hand-off until integrated verification is complete |
| Express correction | No-Bullshit Bug Fix | Johnson alone makes the smallest correction | Any uncertainty or failed eligibility routes to standard Bug Fix before implementation |
| Existing invocation | User says Engineer, developer, dev, or Johnson | Resolver selects Johnson — Lead Engineer | Unknown names retain the existing explicit failure path |

</frozen-after-approval>

## Code Map

- `agents/*.md` -- canonical role cards and frontmatter consumed by the knowledge generator; retain `agents/engineer.md` as the Lead Engineer’s stable file/ID and add the two specialist cards.
- `registry.tsv` and `bin/buildroom` -- public-name resolver; canonical names and aliases are read from this registry.
- `workflows/prd-to-tech-spec.md`, `workflows/feature-delivery.md`, `workflows/bug-fix.md`, `workflows/no-bullshit-bug-fix.md` -- authoritative ownership, approval, hand-off, and stop-condition instructions.
- `scripts/run-operations.py` -- initial owner/next action in `ROUTES` and the authoritative allowed sender/recipient graph for accepted hand-offs.
- `knowledge/catalog.yml`, `knowledge/catalog.md`, `knowledge/context/*.md` -- generated outputs; regenerate with `bin/build-knowledge --write`, do not hand-edit.
- `plugins/buildroom/skills/buildroom/SKILL.md` and `bin/build-codex-plugin` -- installed skill description and packaging of the full toolkit.
- `README.md`, `mkdocs.yml`, `docs/public-content.yml` -- public discovery and GitHub Pages exposure.
- `tests/verify.sh`, `tests/verify-run-operations.sh`, `tests/verify-codex-plugin.sh` -- contract tests for source inventory, resolution, generated knowledge, plugin package, initial owners, and accepted owner hand-offs.

## Tasks & Acceptance

**Execution:**
- [ ] `agents/engineer.md`, `agents/frontend-engineer.md`, `agents/backend-engineer.md`, and existing role cards -- name all roles, define Johnson’s orchestration/integration authority, and bound specialist responsibilities and outputs.
- [ ] `registry.tsv`, `README.md`, and `plugins/buildroom/skills/buildroom/SKILL.md` -- expose all seven named roles while resolving legacy Engineer terms to Johnson.
- [ ] `workflows/prd-to-tech-spec.md`, `workflows/feature-delivery.md`, `workflows/bug-fix.md`, and `workflows/no-bullshit-bug-fix.md` -- route normal technical delivery to Johnson; define sequential two-specialist work with Johnson regaining ownership between slices; require proposed specialist returns that Johnson accepts; keep No-Bullshit Johnson-only; and update changed frontmatter dates.
- [ ] `scripts/run-operations.py` and `tests/verify-run-operations.sh` -- create every run with its canonical named owner; enforce the allowed engineering graph (Johnson→Lovelace/Euler→Johnson→Feynman), reject invalid sender/recipient pairs and express delegation, and prove both positive and negative ownership cases.
- [ ] `tests/verify.sh`, generated `knowledge/*`, `mkdocs.yml`, and `docs/public-content.yml` -- validate and publish all role cards/context order; rebuild the plugin and ensure its verification still passes.

**Acceptance Criteria:**
- Given an approved feature, when it starts, then the durable state assigns Johnson — Lead Engineer and names readiness/integration as the next action.
- Given a bounded frontend or backend slice, when Johnson delegates it, then the workflow requires a full accepted hand-off in both directions before Feynman receives the integrated result.
- Given a specialist or QA hand-off bypasses Johnson, when `buildroom check` reads the state, then it reports a structural blocker rather than marking the run ready.
- Given a simple feature or eligible express correction, when no delegation is required, then Johnson can complete engineering work alone without adding specialist ceremony.
- Given a caller uses legacy Engineer vocabulary or a new person/role name, when resolving it, then it selects the intended canonical role and canonical Markdown card.
- Given Buildroom is installed as a plugin or published as docs, when its catalog is read, then the same seven roles and the same routing rules are available.
- Given the repository checks run, when source and generated artefacts are current, then knowledge, plugin, run-operation, and documentation verification pass.

## Implementation Notes

## Plan Change Log

- Review finding: the original plan required complete specialist round trips but did not require the structural checker to validate sender/recipient transitions, express-route ownership, canonical owners, or sequential coordination for two slices. Amended the delivery and verification tasks to define and test the allowed graph; this avoids a ready state that bypasses Johnson’s integration gate. **KEEP:** named role cards, legacy Engineer resolution, durable hand-offs, public docs, plugin packaging, and independent QA.

## Review Triage Log

- `high | bad_plan | scripts/run-operations.py` — verified that accepted hand-offs matched only recipient/work ID/status, so Feynman→specialist and specialist→Feynman could pass; the amended plan requires an allowed graph.
- `high | bad_plan | scripts/run-operations.py` — verified that returning owner to default Johnson required no accepted specialist return, so integration could be skipped; the amended plan requires the return leg.
- `medium | bad_plan | scripts/run-operations.py` — verified that express ownership could be moved to a specialist with a matching hand-off; the amended plan requires express rejection.
- `medium | bad_plan | scripts/run-operations.py` — verified that three initial owners retained legacy role titles after canonical cards were renamed; the amended plan requires canonical initial owners.
- `medium | bad_plan | workflows/feature-delivery.md` — verified that “both” lacked a durable single-owner coordination rule; the amended plan specifies sequential slices with Johnson between them.
- `medium | bad_plan | workflows/bug-fix.md` — verified that wording let a specialist create an already-accepted return contrary to its role card; the amended plan requires a proposed return accepted by Johnson.
- `medium | bad_plan | workflows/bug-fix.md` — verified that a delegated bug lacked the feature record’s split decision trail; the amended plan requires the same durable state/record.
- `medium | bad_plan | tests/verify-run-operations.sh` — verified that invalid sender and missing-return cases were absent; the amended plan requires negative coverage.
- `low | patch | tests/verify.sh` — resolver coverage omitted several published names and generic role aliases; extend direct resolver checks while implementing.
- `low | patch | plugins/buildroom/skills/buildroom/SKILL.md` — legacy `developer` and `dev` were absent from skill activation text; retain them while updating the description.
- `false | none | plugin bundle` — the bundle is generated and ignored by design; canonical-source packaging plus `verify-codex-plugin.sh` already verifies the installed toolkit.
- `low | patch | agent/workflow frontmatter` — changed source cards retained an old `updated` date; refresh the metadata before regenerating knowledge.

## Design Notes

Keep technical IDs and paths stable where they already represent a public compatibility surface: `role.engineer` / `agents/engineer.md` become Johnson’s Lead Engineer card. New specialist IDs and files make their roles independently discoverable. This avoids breaking existing selected-role links while allowing all new workflow prose and state ownership to use the explicit names. The durable state has one active owner: when both specialist surfaces are needed, Johnson delegates one bounded slice, accepts its proposed return and integrates it, then delegates the next slice; only Johnson may hand the integrated result to Feynman.

## Verification

**Commands:**
- `bin/build-knowledge --write && bin/build-knowledge --check` -- generated catalog and context packs are current.
- `bin/build-codex-plugin --write && bin/build-codex-plugin --check` -- packaged toolkit mirrors canonical source.
- `tests/verify.sh` -- repository, metadata, resolver, generated knowledge, and docs contract passes.
- `tests/verify-run-operations.sh` -- initial ownership and hand-off validation pass.
- `tests/verify-codex-plugin.sh` -- installed-plugin package contract passes.
