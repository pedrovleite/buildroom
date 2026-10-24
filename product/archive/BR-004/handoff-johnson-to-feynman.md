---
work_id: BR-004
from_role: Johnson — Lead Engineer
to_role: Feynman — QA Reviewer
status: accepted
risk_class: standard
decision_authority: human
pause_reason: ''
resume_condition: ''
created: 2026-10-24
required_inputs: [approved specialist plan, canonical role cards, relevant workflows, verification evidence]
related: [FEAT-BR-004]
---

# Hand-off

## Requested outcome

Independently verify that Hypatia and Shannon are discoverable, conditionally routed, bounded by their role authority, represented in generated/provider artifacts, and do not bypass existing human gates or QA ownership. Return acceptance or specific findings to Johnson.

## Entry criteria

- Human-approved implementation scope and acceptance criteria are available in the plan.
- Johnson has integrated the changes and completed the listed repository checks.
- Feynman reviews read-only; implementation changes return to Johnson.

## Completed work

- Added the two canonical role cards, registry entries and aliases, taxonomy metadata, and generated knowledge packs.
- Added conditional workflow routing, explicit output/approval boundaries, provider role adapters, docs, and regression/evaluation coverage.
- Addressed review findings in the PRD-to-tech-spec trigger, bug-investigation evidence requirement, workflow metadata, Master guidance duplication, and routing evaluation numbering.

## Exit criteria

- Each approved acceptance criterion is checked against canonical source and relevant tests.
- Automated verification evidence is checked and accurately represented.
- Any actual defect is returned to Johnson with an actionable location; unverified native-provider behavior is not reported as verified.
- QA verdict and remaining limitations are recorded in the feature record and workflow state.

## Inputs to read

- [Approved implementation plan](../../../_bmad-output/implementation-artifacts/plan-hypatia-shannon-specialists.md)
- [Feature record](feature-record.md)
- [Hypatia role card](../../../agents/hypatia.md)
- [Shannon role card](../../../agents/shannon.md)
- [PRD-to-Tech-Spec](../../../workflows/prd-to-tech-spec.md), [Feature Delivery](../../../workflows/feature-delivery.md), and [Bug Fix](../../../workflows/bug-fix.md)
- [Project installer tests](../../../tests/project-installer.test.mjs) and [routing evaluation](../../../tests/master-routing-eval.md)

## Evidence links

- `bin/build-knowledge --check` — passed.
- `sh tests/verify.sh` — passed; includes 15/15 project-installer tests.
- `bin/build-docs --write && bin/build-docs --check` — passed.
- `git diff --check` — passed.
- Graphify was refreshed and queried after implementation; native Copilot/Claude discovery remains unverified.

## Decisions already made

- The only new roles in scope are Hypatia and Shannon.
- Their invocation is conditional; they do not replace Curie, Turing, Johnson, Feynman, or human decision authority.
- No release, publication, deployment, or production enablement is authorized by this hand-off.

## Assumptions, risks, and open questions

- Static project-generation tests do not establish native Copilot CLI or Claude Code discovery/invocation; those remain unverified and must stay documented as such.
- The routing evaluation is a manual behavioral evaluation document, not an automated conversational test.

## Pause and resume condition

Pause if a required acceptance check fails or evidence is insufficient. Resume after Johnson addresses a specific return and updates the evidence; otherwise return an accepted or blocked verdict with the unresolved limitation clearly stated.

## Acceptance checks for recipient

- Confirm the names and aliases resolve to the correct canonical role cards.
- Confirm relevant workflows invoke the specialists conditionally, capture outputs, and preserve human gates and Feynman's independent QA role.
- Confirm generated knowledge and provider installer tests represent both roles and that the full automated suite passes.
- Confirm review findings are resolved or explicitly deferred, and native-provider limitations are not overstated.

## Recipient acknowledgement

- [x] Inputs are complete and readable.
- [x] Scope and next output are understood.
- [x] Accepted, or returned with the missing information named above.

Feynman accepted on 2026-10-24. The canonical sources, resolver/knowledge outputs, generated provider profiles, documentation, and automated evidence match the approved scope. Native Copilot/Claude discovery and fresh-session conversational delegation remain unverified and are not represented as passed.
