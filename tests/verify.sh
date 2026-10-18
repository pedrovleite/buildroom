#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

require_text() {
  file=$1
  text=$2
  grep -Fq -- "$text" "$root/$file" || {
    echo "Missing '$text' in $file" >&2
    exit 1
  }
}

require_file() {
  test -f "$root/$1" || {
    echo "Missing required file: $1" >&2
    exit 1
  }
}

for file in \
  README.md \
  registry.tsv bin/product-os codex/AGENTS.md.snippet \
  agents/researcher.md agents/product-manager.md agents/architect.md agents/engineer.md agents/qa-reviewer.md \
  workflows/research-to-prd.md workflows/prd-to-tech-spec.md workflows/feature-delivery.md workflows/bug-fix.md workflows/no-bullshit-bug-fix.md \
  templates/workflow-state.md templates/handoff.md templates/memory-index.md \
  memory/README.md example-project/README.md; do
  require_file "$file"
done

# New product idea: research, PRD, and an approval gate.
require_text workflows/research-to-prd.md 'research-note.md'
require_text workflows/research-to-prd.md 'prd.md'
require_text workflows/research-to-prd.md 'classification (`light`, `standard`, or `high-impact`)'
require_text workflows/research-to-prd.md 'success metric'
require_text workflows/research-to-prd.md 'Human approves, rejects, or narrows'

# New feature: spec, implementation record, and verification.
require_text workflows/prd-to-tech-spec.md 'tech-spec.md'
require_text workflows/prd-to-tech-spec.md 'behaviour delta'
require_text workflows/prd-to-tech-spec.md 'time-boxed spike'
require_text workflows/prd-to-tech-spec.md 'high-impact route requires human design approval'
require_text workflows/feature-delivery.md 'feature-record.md'
require_text workflows/feature-delivery.md 'independent peer/agent review'
require_text workflows/feature-delivery.md 'workflow-state.md'
require_text workflows/feature-delivery.md 'Engineer-to-QA hand-off'
require_text workflows/feature-delivery.md 'release readiness'
require_text workflows/feature-delivery.md 'not applicable'
require_text workflows/feature-delivery.md 'high-impact route always records the named risk evidence'
require_text workflows/feature-delivery.md 'decision authority'
require_text workflows/feature-delivery.md 'pause/resume condition'
require_text workflows/feature-delivery.md 'archive the run'
require_text templates/feature-record.md 'Governing decision and specification'
require_text templates/feature-record.md 'Acceptance criteria'
require_text templates/feature-record.md 'Release readiness (conditional)'
require_text templates/feature-record.md 'Production enablement (conditional)'
require_text templates/feature-record.md 'Monitoring and planned outcome check (conditional)'
require_text templates/feature-record.md 'Close-out and archive'

# Reported bug: reproduction, root-cause hypothesis, and regression coverage.
require_text workflows/bug-fix.md 'attempts reproduction'
require_text workflows/bug-fix.md 'QA-to-Engineer hand-off'
require_text workflows/bug-fix.md 'Human approves every standard fix plan'
require_text workflows/bug-fix.md 'workflow-state.md'
require_text workflows/bug-fix.md '## Incident branch'
require_text workflows/bug-fix.md 'blameless postmortem'
require_text workflows/bug-fix.md 'no-bullshit-bug-fix.md'
require_text workflows/bug-fix.md 'pause/resume condition'
require_text templates/bug-investigation.md 'Root-cause hypothesis'
require_text templates/bug-investigation.md 'Regression coverage'
require_text templates/bug-investigation.md 'Governing decision and specification'
require_text templates/bug-investigation.md 'Acceptance criteria for the fix'
require_text templates/bug-investigation.md 'Incident handling'
require_text templates/bug-investigation.md 'Close-out, archive, and preventative follow-up'

# Express bug fix: narrow eligibility, invocation approval, regression proof, and fail-closed escalation.
require_text workflows/no-bullshit-bug-fix.md '## Eligibility — all required'
require_text workflows/no-bullshit-bug-fix.md 'Explicitly invoking this workflow is the human approval'
require_text workflows/no-bullshit-bug-fix.md 'data/privacy/security effect'
require_text workflows/no-bullshit-bug-fix.md 'stop before implementation'
require_text workflows/no-bullshit-bug-fix.md 'route to `bug-fix.md`'
require_text workflows/no-bullshit-bug-fix.md 'Run the named regression check'
require_text workflows/no-bullshit-bug-fix.md 'entry criteria'
require_text workflows/no-bullshit-bug-fix.md 'pause/resume condition'

# Agent hand-off: sender/recipient, inputs, decisions, unknowns, outcome, and acknowledgement.
for heading in \
  'Requested outcome' \
  'Inputs to read' \
  'Decisions already made' \
  'Assumptions, risks, and open questions' \
  'Recipient acknowledgement'; do
  require_text templates/handoff.md "$heading"
done
require_text templates/workflow-state.md 'owner_role'
require_text templates/workflow-state.md 'Open questions and blockers'
require_text templates/workflow-state.md 'risk_class'
require_text templates/workflow-state.md 'decision_authority'
require_text templates/workflow-state.md 'Entry criteria'
require_text templates/workflow-state.md 'Exit criteria'
require_text templates/workflow-state.md 'Evidence links'
require_text templates/workflow-state.md 'Run trace'
require_text templates/handoff.md 'Entry criteria'
require_text templates/handoff.md 'Exit criteria'
require_text templates/handoff.md 'Evidence links'
require_text templates/handoff.md 'Pause and resume condition'
require_text workflows/research-to-prd.md 'exit criteria'
require_text workflows/research-to-prd.md 'pause/resume condition'
require_text workflows/prd-to-tech-spec.md 'exit criteria'
require_text workflows/prd-to-tech-spec.md 'evidence links'
require_text workflows/prd-to-tech-spec.md 'pause/resume condition'

# New installation and no graph backend: portable instructions plus a Markdown fallback.
require_text README.md 'Install in another project'
require_text README.md 'no secrets, API key'
require_text README.md 'Choose the right route'
require_text README.md 'No-Bullshit Bug Fix'
require_text memory/README.md 'future graph adapter'
require_text templates/memory-index.md 'Retrieval rules'

# Name routing: all public roles/workflows have a registry entry and aliases resolve deterministically.
require_text registry.tsv 'Researcher'
require_text registry.tsv 'Product Manager'
require_text registry.tsv 'Bug Fix'
require_text registry.tsv 'No-Bullshit Bug Fix'
require_text codex/AGENTS.md.snippet 'registry.tsv'
require_text README.md 'Name registry'

resolve_output=$(sh "$root/bin/product-os" resolve Researcher)
printf '%s\n' "$resolve_output" | grep -Fq 'Type: agent'
printf '%s\n' "$resolve_output" | grep -Fq 'product-os/agents/researcher.md'

resolve_output=$(sh "$root/bin/product-os" resolve 'Product Manager')
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Product Manager'

resolve_output=$(sh "$root/bin/product-os" resolve pesquisador)
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Researcher'

resolve_output=$(sh "$root/bin/product-os" resolve PM)
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Product Manager'

resolve_output=$(sh "$root/bin/product-os" resolve qa)
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: QA Reviewer'

resolve_output=$(sh "$root/bin/product-os" resolve 'correção de bug')
printf '%s\n' "$resolve_output" | grep -Fq 'Type: workflow'
printf '%s\n' "$resolve_output" | grep -Fq 'product-os/workflows/bug-fix.md'

resolve_output=$(sh "$root/bin/product-os" resolve 'no bullshit bug fix')
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: No-Bullshit Bug Fix'
printf '%s\n' "$resolve_output" | grep -Fq 'product-os/workflows/no-bullshit-bug-fix.md'

resolve_output=$(sh "$root/bin/product-os" resolve 'No-Bullshit Bug Fix')
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: No-Bullshit Bug Fix'

resolve_output=$(sh "$root/bin/product-os" resolve 'correção rápida')
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: No-Bullshit Bug Fix'

list_output=$(sh "$root/bin/product-os" list)
printf '%s\n' "$list_output" | grep -Fq 'agent: Researcher'
printf '%s\n' "$list_output" | grep -Fq 'workflow: Bug Fix'
printf '%s\n' "$list_output" | grep -Fq 'workflow: No-Bullshit Bug Fix'

test -x "$root/bin/product-os"
"$root/bin/product-os" list >/dev/null
if unknown_output=$(sh "$root/bin/product-os" resolve 'not an agent' 2>&1); then
  echo 'Unknown names must fail resolution' >&2
  exit 1
fi
printf '%s\n' "$unknown_output" | grep -Fq 'explicit `product-os/...` Markdown path'

echo 'product-os verification passed'
