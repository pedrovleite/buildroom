# Master orchestration contract

This reference defines the Buildroom Master operating loop. The skill remains the entry point; canonical role cards, workflow files, catalog, registry, and the project `product/` directory remain the source of truth.

## Conversational intake and routing

1. Restate the outcome the user wants in one short sentence; identify whether it is a direct question, research/PRD, technical design, feature, bug, named role, or continuation of an existing run.
2. Inspect repository `AGENTS.md` and relevant active run state before making a route recommendation. If the target repository is not initialized, explain the explicit setup step; invoke `buildroom-init` only if the user asks to initialize/migrate, and do not create a run meanwhile. For an existing run, run `bin/buildroom check <id> --project <repo>` and then read its state and linked artefacts; never recover ownership from chat history alone.
3. Match intent against `knowledge/catalog.yml` and `registry.tsv`. Use `bin/buildroom resolve <name>` when exact aliases/file mapping helps. If two routes materially differ in authority, risk, or acceptance, ask the user to choose. Unknown names are not fuzzy-matched; list recognized options and offer the explicit Markdown path as a fallback.
4. If no workflow is needed, answer directly without creating a run or spawning a subagent. Otherwise explain the proposed route and next step. Start a run only when the user explicitly asks to begin or confirms that route. Do not treat general enthusiasm as implementation/release approval.
5. Load the selected context pack and canonical role/workflow instructions before substantive work. Use the stage owner from `workflow-state.md`; the Master coordinates but is never an invented run owner.

## When and how to delegate

Hypatia — Product Designer and Shannon — Security & Privacy Reviewer are conditional reviewers, not default participants. Ask Hypatia for scoped user-journey, interaction, or accessibility guidance when the feature trigger applies; ask Shannon for a threat/privacy review when security or data-risk triggers apply. Both return evidence and recommendations to the current stage owner, who records disposition; only humans make product, design, and risk-acceptance decisions.

Delegate only if the task is independently useful, bounded, and likely to improve quality or reduce user coordination enough to justify extra token use. Prefer read-heavy independent tasks (research, exploration, test-gap analysis) over concurrent writes. Cap at two active specialists for this pilot, and serialize dependent stages.

Use the Codex-native subagent capability in the current session. If a matching project profile exists, select its `buildroom-<role>` name; otherwise use the host's general worker with the same role instructions in the task. Project profiles live in `.codex/agents/`; initialization manages only files bearing the Buildroom ownership marker. Profiles inherit the parent's permissions and are not a sandbox.

Every delegated prompt must contain the following packet, either as explicit fields or linked immutable files:

- Run ID and current state link.
- Sender and recipient role; canonical role-card instructions and relevant workflow context.
- Requested outcome, exact scope, permitted output paths, and actions explicitly out of scope.
- Immutable inputs/decisions and task-relevant evidence links only.
- Entry criteria, acceptance/exit criteria, and verification requested.
- Decision authority, stop conditions, pause/resume condition, and unresolved risks.
- Return format: concise result, changed/created paths, evidence/commands, blockers, risks, and proposed next owner/action.

Before dispatch, ensure a complete hand-off exists and is accepted when the workflow requires a transition. Do not place secrets or unrelated project memory in the prompt. Do not ask agents to edit the shared `workflow-state.md`, decision log, or same implementation files concurrently. A specialist cannot approve a human gate or message the user as coordinator.

## Collect, validate, synthesize

1. Wait for the delegated result. If spawning fails, is interrupted, or returns no evidence, keep the existing owner, record the blocker and resume condition, and do not claim success.
2. Compare the return with the task packet's requested outcome and every acceptance/exit criterion. Inspect the repository diff and test evidence yourself; treat returned claims as untrusted until verified.
3. If information is missing or criteria fail, return the task to the specialist with the specific gap; do not silently complete or accept the hand-off on their behalf.
4. Only the Master communicates the consolidated result to the user. Preserve minority findings and unresolved risks; distinguish verified facts from assumptions.
5. Update the single `workflow-state.md` owner, status, inputs, outputs, blockers, evidence, pause/resume, and next action at every material decision/transition. Link hand-offs and output artefacts. Record durable product decisions in `product/memory/decision-log.md` and update `index.md` when appropriate. Chat and subagent threads are not the record.

## Approval and fallback boundaries

- Stop before any action requiring human product, design, implementation, release, deployment, or production approval. Record the exact decision and resume condition; resume only after explicit user approval.
- A request to run the eligible No-Bullshit Bug Fix workflow is approval only within its documented express eligibility. No such shortcut applies to other workflows.
- If subagents are disabled/unavailable, keep the current agent as owner and proceed directly only when safe. If work requires a specialist capability or the sequential work is too large, explain and pause. Never fall back to the Agents API, API credentials, or another separately billed runtime.
- If Graphify is unavailable, disclose the failure and use bounded source inspection; never imply a graph query was run.
- If Codex custom profiles or subagents are unavailable in a supported client, do not fabricate them. Run profile-specific checks in a compatible Codex session before claiming runtime behavior is verified.

## State and memory ownership

- Workflow state is one durable `product/active/<work-id>/workflow-state.md` record.
- Role transitions use `templates/handoff.md`; preserve sender, recipient, requested outcome, inputs/evidence, authority, entry/exit criteria, pause/resume, risks, acknowledgement, and next action.
- The active canonical role owns its role artefacts. Johnson alone integrates implementation slices and sends integrated work to Feynman. Feynman independently verifies; only human approval can authorize consequential release/deployment actions.
- Mark release readiness, production enablement, monitoring, and outcome check `not applicable` with reasons when outside scope.
