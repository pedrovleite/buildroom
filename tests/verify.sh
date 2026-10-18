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
  bin/build-knowledge knowledge/taxonomy.yml knowledge/schema.yml knowledge/README.md knowledge/catalog.yml \
  agents/researcher.md agents/product-manager.md agents/architect.md agents/engineer.md agents/qa-reviewer.md \
  workflows/research-to-prd.md workflows/prd-to-tech-spec.md workflows/feature-delivery.md workflows/bug-fix.md workflows/no-bullshit-bug-fix.md \
  templates/workflow-state.md templates/handoff.md templates/memory-index.md \
  memory/README.md example-project/README.md; do
  require_file "$file"
done

# Knowledge contract: source metadata is validated and generated agent context remains current.
for file in \
  knowledge/context/research-to-prd.md knowledge/context/prd-to-tech-spec.md knowledge/context/feature-delivery.md \
  knowledge/context/bug-fix.md knowledge/context/no-bullshit-bug-fix.md; do
  require_file "$file"
done

test -x "$root/bin/build-knowledge"
"$root/bin/build-knowledge" --check
require_text knowledge/catalog.yml 'workflow.bug-fix'
require_text knowledge/catalog.yml 'role.engineer'
require_text knowledge/catalog.yml 'workflow.no-bullshit-bug-fix'
require_text knowledge/catalog.yml 'context: "knowledge/context/bug-fix.md"'
require_text codex/AGENTS.md.snippet 'knowledge/catalog.yml'
require_text codex/AGENTS.md.snippet 'context` field'

require_in_order() {
  file=$1
  shift
  previous=0
  for text in "$@"; do
    line=$(grep -n -F -- "$text" "$root/$file" | head -n 1 | cut -d: -f1)
    test -n "$line" && test "$line" -gt "$previous" || {
      echo "Missing or out-of-order '$text' in $file" >&2
      exit 1
    }
    previous=$line
  done
}

require_in_order knowledge/context/research-to-prd.md workflows/research-to-prd.md agents/researcher.md agents/product-manager.md agents/architect.md
require_in_order knowledge/context/prd-to-tech-spec.md workflows/prd-to-tech-spec.md agents/architect.md agents/engineer.md
require_in_order knowledge/context/feature-delivery.md workflows/feature-delivery.md agents/engineer.md agents/qa-reviewer.md
require_in_order knowledge/context/bug-fix.md workflows/bug-fix.md agents/qa-reviewer.md agents/engineer.md
require_in_order knowledge/context/no-bullshit-bug-fix.md workflows/no-bullshit-bug-fix.md agents/engineer.md

make_knowledge_fixture() {
  destination=$1
  cp -R "$root/agents" "$root/workflows" "$root/knowledge" "$destination/"
}

tmp_tag=$(mktemp -d "${TMPDIR:-/tmp}/product-os-tag.XXXXXX")
tmp_relation=$(mktemp -d "${TMPDIR:-/tmp}/product-os-relation.XXXXXX")
tmp_stale=$(mktemp -d "${TMPDIR:-/tmp}/product-os-stale.XXXXXX")
tmp_write=$(mktemp -d "${TMPDIR:-/tmp}/product-os-write.XXXXXX")
tmp_self=$(mktemp -d "${TMPDIR:-/tmp}/product-os-self.XXXXXX")
tmp_kind=$(mktemp -d "${TMPDIR:-/tmp}/product-os-kind.XXXXXX")
tmp_status=$(mktemp -d "${TMPDIR:-/tmp}/product-os-status.XXXXXX")
tmp_orphan=$(mktemp -d "${TMPDIR:-/tmp}/product-os-orphan.XXXXXX")
tmp_nested=$(mktemp -d "${TMPDIR:-/tmp}/product-os-nested.XXXXXX")
tmp_quoted=$(mktemp -d "${TMPDIR:-/tmp}/product-os-quoted.XXXXXX")
tmp_scalar=$(mktemp -d "${TMPDIR:-/tmp}/product-os-scalar.XXXXXX")
tmp_dependency=$(mktemp -d "${TMPDIR:-/tmp}/product-os-dependency.XXXXXX")
tmp_collision=$(mktemp -d "${TMPDIR:-/tmp}/product-os-collision.XXXXXX")
trap 'rm -rf "$tmp_tag" "$tmp_relation" "$tmp_stale" "$tmp_write" "$tmp_self" "$tmp_kind" "$tmp_status" "$tmp_orphan" "$tmp_nested" "$tmp_quoted" "$tmp_scalar" "$tmp_dependency" "$tmp_collision"' EXIT HUP INT TERM

expect_knowledge_error() {
  fixture=$1
  expected=$2
  if "$root/bin/build-knowledge" --root "$fixture" --check >"$fixture/output" 2>&1; then
    echo "Knowledge validation should have failed: $expected" >&2
    exit 1
  fi
  grep -Fq -- "$expected" "$fixture/output"
}

make_knowledge_fixture "$tmp_tag"
awk 'BEGIN { changed = 0 } { if (!changed && /domain\/product-os/) { sub("domain/product-os", "invalid/tag"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_tag/agents/researcher.md" > "$tmp_tag/researcher.md" && mv "$tmp_tag/researcher.md" "$tmp_tag/agents/researcher.md"
expect_knowledge_error "$tmp_tag" 'unknown tag invalid/tag'

make_knowledge_fixture "$tmp_relation"
awk 'BEGIN { changed = 0 } { if (!changed && /role\.engineer/) { sub("role.engineer", "role.missing"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_relation/workflows/feature-delivery.md" > "$tmp_relation/feature-delivery.md" && mv "$tmp_relation/feature-delivery.md" "$tmp_relation/workflows/feature-delivery.md"
expect_knowledge_error "$tmp_relation" 'depends_on references missing id role.missing'

make_knowledge_fixture "$tmp_stale"
awk 'BEGIN { changed = 0 } { if (!changed && /Turns a product question into current cited evidence/) { sub("current cited evidence", "validated cited evidence"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_stale/agents/researcher.md" > "$tmp_stale/researcher.md" && mv "$tmp_stale/researcher.md" "$tmp_stale/agents/researcher.md"
expect_knowledge_error "$tmp_stale" 'Out of date: knowledge/catalog.yml'

make_knowledge_fixture "$tmp_write"
awk 'BEGIN { changed = 0 } { if (!changed && /authority: human-release-approval/) { sub("human-release-approval", "human-release-approval-v2"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_write/workflows/feature-delivery.md" > "$tmp_write/feature-delivery.md" && mv "$tmp_write/feature-delivery.md" "$tmp_write/workflows/feature-delivery.md"
"$root/bin/build-knowledge" --root "$tmp_write" --write >/dev/null
grep -Fq 'human-release-approval-v2' "$tmp_write/knowledge/context/feature-delivery.md"
"$root/bin/build-knowledge" --root "$tmp_write" --check >/dev/null

make_knowledge_fixture "$tmp_self"
awk 'BEGIN { changed = 0 } { if (!changed && /related: \[workflow.prd-to-tech-spec\]/) { sub("workflow.prd-to-tech-spec", "workflow.feature-delivery"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_self/workflows/feature-delivery.md" > "$tmp_self/feature-delivery.md" && mv "$tmp_self/feature-delivery.md" "$tmp_self/workflows/feature-delivery.md"
expect_knowledge_error "$tmp_self" 'related must not reference itself (workflow.feature-delivery)'

make_knowledge_fixture "$tmp_kind"
awk 'BEGIN { changed = 0 } { if (!changed && /^kind: workflow$/) { sub("workflow", "route"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_kind/workflows/feature-delivery.md" > "$tmp_kind/feature-delivery.md" && mv "$tmp_kind/feature-delivery.md" "$tmp_kind/workflows/feature-delivery.md"
expect_knowledge_error "$tmp_kind" "invalid kind 'route'"

make_knowledge_fixture "$tmp_status"
awk 'BEGIN { changed = 0 } { if (!changed && /^status: active$/) { sub("active", "retired"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_status/workflows/feature-delivery.md" > "$tmp_status/feature-delivery.md" && mv "$tmp_status/feature-delivery.md" "$tmp_status/workflows/feature-delivery.md"
expect_knowledge_error "$tmp_status" "invalid status 'retired'"

make_knowledge_fixture "$tmp_orphan"
touch "$tmp_orphan/knowledge/context/orphan.md"
expect_knowledge_error "$tmp_orphan" 'Orphaned generated context pack: knowledge/context/orphan.md'
"$root/bin/build-knowledge" --root "$tmp_orphan" --write >/dev/null
test ! -e "$tmp_orphan/knowledge/context/orphan.md"

make_knowledge_fixture "$tmp_nested"
mkdir -p "$tmp_nested/agents/team"
mv "$tmp_nested/agents/researcher.md" "$tmp_nested/agents/team/researcher.md"
"$root/bin/build-knowledge" --root "$tmp_nested" --write >/dev/null
grep -Fq 'source: "agents/team/researcher.md"' "$tmp_nested/knowledge/catalog.yml"
"$root/bin/build-knowledge" --root "$tmp_nested" --check >/dev/null

make_knowledge_fixture "$tmp_quoted"
awk 'BEGIN { changed = 0 } { if (!changed && /applies_to: \[product-os\]/) { sub("\\[product-os\\]", "[\"product, os\"]"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_quoted/agents/researcher.md" > "$tmp_quoted/researcher.md" && mv "$tmp_quoted/researcher.md" "$tmp_quoted/agents/researcher.md"
"$root/bin/build-knowledge" --root "$tmp_quoted" --write >/dev/null
grep -Fq 'applies_to: ["product, os"]' "$tmp_quoted/knowledge/catalog.yml"

make_knowledge_fixture "$tmp_scalar"
awk 'BEGIN { changed = 0 } { if (!changed && /^owner: product-os$/) { sub("product-os", "{team: platform}"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_scalar/agents/researcher.md" > "$tmp_scalar/researcher.md" && mv "$tmp_scalar/researcher.md" "$tmp_scalar/agents/researcher.md"
expect_knowledge_error "$tmp_scalar" 'unsupported scalar syntax'

make_knowledge_fixture "$tmp_dependency"
awk 'BEGIN { changed = 0 } { if (!changed && /depends_on: \[role.engineer, role.qa-reviewer\]/) { sub("\\[role.engineer, role.qa-reviewer\\]", "[workflow.bug-fix]"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_dependency/workflows/feature-delivery.md" > "$tmp_dependency/feature-delivery.md" && mv "$tmp_dependency/feature-delivery.md" "$tmp_dependency/workflows/feature-delivery.md"
expect_knowledge_error "$tmp_dependency" 'workflow depends_on must reference a role id (workflow.bug-fix)'

make_knowledge_fixture "$tmp_collision"
mkdir -p "$tmp_collision/workflows/nested"
cp "$tmp_collision/workflows/bug-fix.md" "$tmp_collision/workflows/nested/bug-fix.md"
awk 'BEGIN { changed = 0 } { if (!changed && /^id: workflow.bug-fix$/) { sub("workflow.bug-fix", "workflow.nested-bug-fix"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_collision/workflows/nested/bug-fix.md" > "$tmp_collision/nested-bug-fix.md" && mv "$tmp_collision/nested-bug-fix.md" "$tmp_collision/workflows/nested/bug-fix.md"
expect_knowledge_error "$tmp_collision" 'duplicate context-pack output: knowledge/context/bug-fix.md'

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
