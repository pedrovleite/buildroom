---
id: workflow.no-bullshit-bug-fix
kind: workflow
title: No-Bullshit Bug Fix
summary: Applies a pre-approved, local, reversible defect correction with a proven regression check.
status: active
audience: [human, agent]
tags: [domain/buildroom, artifact/workflow, workflow/bug-fix, workflow/express]
applies_to: [buildroom]
depends_on: [role.engineer]
related: [workflow.bug-fix]
authority: workflow-invocation-is-human-approval
owner: buildroom
updated: 2026-10-18
---

# No-Bullshit Bug Fix

Use this express route only when **every** eligibility check is true. Explicitly invoking this workflow is the human approval for the eligible correction.

## Eligibility — all required

- The expected behaviour, observed defect, affected path, and minimal correction are already clear.
- The correction is local, reversible, and has a clear automated or manual regression check whose pre-change result demonstrates the defect.
- It has no production action, deployment, user-exposure change, external side effect, data/privacy/security effect, migration, external contract/API change, broad customer impact, or incident severity.
- It requires no product decision, research, alternative analysis, or technical design decision.
- Repository instructions and available tests support a safe, bounded change.

If an eligibility check is false or unknown, or the pre-change regression check cannot demonstrate the defect: **stop before implementation**, record why, and route to `bug-fix.md`. Production/security/major-impact conditions use its incident branch. If post-change verification fails, do not close the express route: undo the express correction when possible, record the evidence, and route the remaining work to `bug-fix.md`.

1. Record the eligibility result in `workflow-state.md` and `bug-investigation.md`; set route `express`, owner `Engineer`, status `preflight`, invocation as approval, scope, entry criteria, expected exit criteria, decision authority, evidence links, pause/resume condition, named regression check, and next action. Run the named regression check or document the manual baseline before changing code; if it does not demonstrate the defect, stop and route to `bug-fix.md`.
2. Engineer makes the smallest correction that fixes the known defect. Do not widen scope or refactor adjacent code.
3. Run the named regression check and any directly affected checks. Record commands, results, changed paths, and deviation (if any). If verification fails, undo the express correction when possible, set state to `routed`, and hand off the evidence to `bug-fix.md`.
4. If verification passes, close the run: record expected versus observed result after the fix, evidence links, archive/close-out, and memory/spec link if it changes known behaviour.

**Never skip:** eligibility, regression verification, durable evidence, or close-out. This route deliberately skips research, option analysis, separate QA hand-off, and a second approval only because invocation is approval and the eligibility contract is narrow.
