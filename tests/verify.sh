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
  README.md docs/project-installer.md \
  registry.tsv bin/buildroom bin/buildroom-install.mjs scripts/project-installer.mjs tests/project-installer.test.mjs codex/AGENTS.md.snippet \
  codex/AGENTS.global-plugin.snippet bin/build-knowledge bin/build-docs bin/build-codex-plugin bin/install-codex-plugin mkdocs.yml requirements-docs.txt docs/public-content.yml .github/workflows/docs.yml \
  plugins/buildroom/.codex-plugin/plugin.json plugins/buildroom/skills/buildroom/SKILL.md plugins/buildroom/skills/buildroom/references/master-orchestration.md plugins/buildroom/skills/buildroom-init/SKILL.md plugins/buildroom/scripts/init-project.py scripts/run-operations.py tests/verify-codex-plugin.sh tests/verify-run-operations.sh tests/master-routing-eval.md \
  knowledge/taxonomy.yml knowledge/taxonomy.md knowledge/schema.yml knowledge/README.md knowledge/catalog.yml knowledge/catalog.md \
  agents/researcher.md agents/product-manager.md agents/architect.md agents/engineer.md agents/frontend-engineer.md agents/backend-engineer.md agents/qa-reviewer.md agents/hypatia.md agents/shannon.md \
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
test -x "$root/bin/build-docs"
test -x "$root/bin/build-codex-plugin"
test -x "$root/bin/install-codex-plugin"
test -x "$root/bin/buildroom-install.mjs"
test -x "$root/tests/verify-codex-plugin.sh"
test -x "$root/tests/verify-run-operations.sh"
"$root/bin/build-knowledge" --check
"$root/bin/build-codex-plugin" --write
"$root/bin/build-codex-plugin" --check
require_text knowledge/catalog.yml 'workflow.bug-fix'
require_text knowledge/catalog.yml 'role.engineer'
require_text knowledge/catalog.yml 'workflow.no-bullshit-bug-fix'
require_text knowledge/catalog.yml 'context: "knowledge/context/bug-fix.md"'
require_text codex/AGENTS.md.snippet 'knowledge/catalog.yml'
require_text codex/AGENTS.md.snippet 'context` field'
require_text codex/AGENTS.global-plugin.snippet 'globally installed `buildroom` Codex plugin'
require_text codex/AGENTS.global-plugin.snippet '<!-- buildroom:global-plugin:start -->'
require_text README.md 'Install once for Codex (recommended)'
require_text README.md 'bin/install-codex-plugin'
require_text README.md 'bin/buildroom-install.mjs install --provider codex'
require_text docs/project-installer.md 'GitHub Copilot CLI'
require_text docs/project-installer.md 'Graphify registration'
require_text mkdocs.yml 'Project installer: docs/project-installer.md'
require_text docs/public-content.yml 'source: docs/project-installer.md'
require_text README.md 'nine Buildroom-managed Codex custom-agent profiles'
require_text docs/run-operations.md 'Conversational Master and Codex subagents'
require_text docs/run-operations.md 'never falls back to the Agents API'
require_text plugins/buildroom/skills/buildroom/SKILL.md 'single user-facing coordinator'
require_text plugins/buildroom/skills/buildroom/SKILL.md 'Never claim a subagent was started when it was not'
require_text plugins/buildroom/skills/buildroom/SKILL.md 'Hypatia and Shannon are conditional design/security reviewers'
require_text plugins/buildroom/skills/buildroom/references/master-orchestration.md 'Hypatia — Product Designer and Shannon — Security & Privacy Reviewer are conditional reviewers'
require_text plugins/buildroom/skills/buildroom/SKILL.md 'use `buildroom-init` only after the user asks to initialize/migrate'
require_text plugins/buildroom/skills/buildroom/references/master-orchestration.md 'Every delegated prompt must contain the following packet'
require_text tests/master-routing-eval.md '## Pass criteria'
require_text tests/master-routing-eval.md 'Redesign the sign-in and recovery flow'
require_text tests/master-routing-eval.md 'Store sensitive customer data'
require_text tests/master-routing-eval.md 'ordinary backend-only preference field'
require_text knowledge/catalog.md '# Buildroom catalog'
require_text knowledge/catalog.md 'No-Bullshit Bug Fix'
require_text knowledge/catalog.md 'open generated pack'
require_text knowledge/taxonomy.md '# Buildroom taxonomy'
require_text docs/public-content.yml 'workflows/no-bullshit-bug-fix.md'
require_text mkdocs.yml 'name: material'
require_text mkdocs.yml 'Context packs:'
require_text mkdocs.yml 'BUILDROOM_SITE_URL'
require_text mkdocs.yml 'http://localhost:8000/'
require_text mkdocs.yml 'BUILDROOM_REPOSITORY_URL'
require_text mkdocs.yml 'https://example.invalid/buildroom'
require_text requirements-docs.txt 'mkdocs-material==9.*'
require_text .github/workflows/docs.yml 'branches: [main]'
require_text .github/workflows/docs.yml 'pages: read'
require_text .github/workflows/docs.yml 'bin/build-knowledge --check'
require_text .github/workflows/docs.yml 'bin/build-docs --write'
require_text .github/workflows/docs.yml 'BUILDROOM_SITE_URL: ${{ steps.pages.outputs.base_url }}'
require_text .github/workflows/docs.yml 'if: github.ref == format('
require_text .github/workflows/docs.yml 'for excluded in templates memory tests bin .github registry.tsv knowledge/catalog.yml; do'
require_text .github/workflows/docs.yml 'sh bin/verify-pages-artifact.sh .buildroom-site'
sh "$root/tests/verify-pages-artifact.sh"
require_text .github/workflows/docs.yml 'path: .buildroom-site'
require_text .github/workflows/docs.yml 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1'
require_text .github/workflows/docs.yml 'actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0'
require_text .github/workflows/docs.yml 'actions/configure-pages@983d7736d9b0ae728b81ab479565c72886d7745b # v5'
require_text .github/workflows/docs.yml 'actions/upload-pages-artifact@7b1f4a764d45c48632c6b24a0339c27f5614fb0b # v4'
require_text .github/workflows/docs.yml 'actions/deploy-pages@d6db90164ac5ed86f2b6aed7e0febac5b3c0c03e # v4'

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
require_in_order knowledge/context/prd-to-tech-spec.md workflows/prd-to-tech-spec.md agents/architect.md agents/hypatia.md agents/shannon.md agents/engineer.md
require_in_order knowledge/context/feature-delivery.md workflows/feature-delivery.md agents/engineer.md agents/hypatia.md agents/shannon.md agents/frontend-engineer.md agents/backend-engineer.md agents/qa-reviewer.md
require_in_order knowledge/context/bug-fix.md workflows/bug-fix.md agents/qa-reviewer.md agents/engineer.md agents/shannon.md agents/frontend-engineer.md agents/backend-engineer.md
require_in_order knowledge/context/no-bullshit-bug-fix.md workflows/no-bullshit-bug-fix.md agents/engineer.md

make_knowledge_fixture() {
  destination=$1
  cp -R "$root/agents" "$root/workflows" "$root/knowledge" "$destination/"
}

tmp_tag=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-tag.XXXXXX")
tmp_relation=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-relation.XXXXXX")
tmp_stale=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-stale.XXXXXX")
tmp_write=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-write.XXXXXX")
tmp_self=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-self.XXXXXX")
tmp_kind=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-kind.XXXXXX")
tmp_status=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-status.XXXXXX")
tmp_orphan=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-orphan.XXXXXX")
tmp_nested=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-nested.XXXXXX")
tmp_quoted=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-quoted.XXXXXX")
tmp_scalar=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-scalar.XXXXXX")
tmp_dependency=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-dependency.XXXXXX")
tmp_collision=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-collision.XXXXXX")
tmp_docs=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-docs.XXXXXX")
tmp_docs_invalid=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-docs-invalid.XXXXXX")
tmp_taxonomy=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-taxonomy.XXXXXX")
tmp_markdown=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-markdown.XXXXXX")
tmp_docs_source_link=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-docs-source-link.XXXXXX")
trap 'rm -rf "$tmp_tag" "$tmp_relation" "$tmp_stale" "$tmp_write" "$tmp_self" "$tmp_kind" "$tmp_status" "$tmp_orphan" "$tmp_nested" "$tmp_quoted" "$tmp_scalar" "$tmp_dependency" "$tmp_collision" "$tmp_docs" "$tmp_docs_invalid" "$tmp_taxonomy" "$tmp_markdown" "$tmp_docs_source_link"' EXIT HUP INT TERM

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
awk 'BEGIN { changed = 0 } { if (!changed && /domain\/buildroom/) { sub("domain/buildroom", "invalid/tag"); changed = 1 } print } END { if (!changed) exit 2 }' \
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
awk 'BEGIN { changed = 0 } { if (!changed && /applies_to: \[buildroom\]/) { sub("\\[buildroom\\]", "[\"product, os\"]"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_quoted/agents/researcher.md" > "$tmp_quoted/researcher.md" && mv "$tmp_quoted/researcher.md" "$tmp_quoted/agents/researcher.md"
"$root/bin/build-knowledge" --root "$tmp_quoted" --write >/dev/null
grep -Fq 'applies_to: ["product, os"]' "$tmp_quoted/knowledge/catalog.yml"

make_knowledge_fixture "$tmp_scalar"
awk 'BEGIN { changed = 0 } { if (!changed && /^owner: buildroom$/) { sub("buildroom", "{team: platform}"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_scalar/agents/researcher.md" > "$tmp_scalar/researcher.md" && mv "$tmp_scalar/researcher.md" "$tmp_scalar/agents/researcher.md"
expect_knowledge_error "$tmp_scalar" 'unsupported scalar syntax'

make_knowledge_fixture "$tmp_dependency"
awk 'BEGIN { changed = 0 } { if (!changed && /depends_on: \[role.engineer, role.product-designer, role.security-reviewer, role.frontend-engineer, role.backend-engineer, role.qa-reviewer\]/) { sub("\\[role.engineer, role.product-designer, role.security-reviewer, role.frontend-engineer, role.backend-engineer, role.qa-reviewer\\]", "[workflow.bug-fix]"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_dependency/workflows/feature-delivery.md" > "$tmp_dependency/feature-delivery.md" && mv "$tmp_dependency/feature-delivery.md" "$tmp_dependency/workflows/feature-delivery.md"
expect_knowledge_error "$tmp_dependency" 'workflow depends_on must reference a role id (workflow.bug-fix)'

make_knowledge_fixture "$tmp_collision"
mkdir -p "$tmp_collision/workflows/nested"
cp "$tmp_collision/workflows/bug-fix.md" "$tmp_collision/workflows/nested/bug-fix.md"
awk 'BEGIN { changed = 0 } { if (!changed && /^id: workflow.bug-fix$/) { sub("workflow.bug-fix", "workflow.nested-bug-fix"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_collision/workflows/nested/bug-fix.md" > "$tmp_collision/nested-bug-fix.md" && mv "$tmp_collision/nested-bug-fix.md" "$tmp_collision/workflows/nested/bug-fix.md"
expect_knowledge_error "$tmp_collision" 'duplicate context-pack output: knowledge/context/bug-fix.md'

make_knowledge_fixture "$tmp_taxonomy"
awk 'BEGIN { changed = 0 } { if (!changed && /domain\/buildroom/) { sub("domain/buildroom", "domain|invalid"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_taxonomy/knowledge/taxonomy.yml" > "$tmp_taxonomy/taxonomy.yml" && mv "$tmp_taxonomy/taxonomy.yml" "$tmp_taxonomy/knowledge/taxonomy.yml"
expect_knowledge_error "$tmp_taxonomy" "invalid taxonomy tag 'domain|invalid'"

make_knowledge_fixture "$tmp_markdown"
mv "$tmp_markdown/agents/researcher.md" "$tmp_markdown/agents/researcher (guide).md"
awk 'BEGIN { changed = 0 } { if (!changed && /^title: Noether — Researcher$/) { sub("Noether — Researcher", "Researcher [guide]"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_markdown/agents/researcher (guide).md" > "$tmp_markdown/researcher.md" && mv "$tmp_markdown/researcher.md" "$tmp_markdown/agents/researcher (guide).md"
"$root/bin/build-knowledge" --root "$tmp_markdown" --write >/dev/null
grep -Fq '[Researcher \[guide\]](<../agents/researcher%20%28guide%29.md>)' "$tmp_markdown/knowledge/catalog.md"

# Documentation source: a generated, explicit allowlist is the only publication boundary.
make_docs_fixture() {
  destination=$1
  cp -R "$root/agents" "$root/workflows" "$root/knowledge" "$root/docs" "$destination/"
  cp "$root/README.md" "$destination/"
  mkdir -p "$destination/templates" "$destination/memory" "$destination/tests"
  printf '# private template\n' > "$destination/templates/private-template.md"
  printf '# private memory\n' > "$destination/memory/private-memory.md"
  printf '# private test\n' > "$destination/tests/private-test.md"
}

make_docs_fixture "$tmp_docs"
test -f "$tmp_docs/templates/private-template.md"
test -f "$tmp_docs/memory/private-memory.md"
test -f "$tmp_docs/tests/private-test.md"
"$root/bin/build-docs" --root "$tmp_docs" --write >/dev/null
"$root/bin/build-docs" --root "$tmp_docs" --check >/dev/null
test -f "$tmp_docs/.buildroom-docs/index.md"
test -f "$tmp_docs/.buildroom-docs/docs/run-operations.md"
test -f "$tmp_docs/.buildroom-docs/docs/project-installer.md"
grep -Fq '(docs/project-installer.md)' "$tmp_docs/.buildroom-docs/operating-model.md"
grep -Fq '(project-installer.md)' "$tmp_docs/.buildroom-docs/docs/run-operations.md"
test -f "$tmp_docs/.buildroom-docs/workflows/no-bullshit-bug-fix.md"
test -f "$tmp_docs/.buildroom-docs/knowledge/context/no-bullshit-bug-fix.md"
test ! -e "$tmp_docs/.buildroom-docs/templates"
test ! -e "$tmp_docs/.buildroom-docs/memory"
test ! -e "$tmp_docs/.buildroom-docs/tests"
test ! -e "$tmp_docs/.buildroom-docs/templates/private-template.md"
test ! -e "$tmp_docs/.buildroom-docs/memory/private-memory.md"
test ! -e "$tmp_docs/.buildroom-docs/tests/private-test.md"
printf '# private by default\n' > "$tmp_docs/unlisted.md"
ln -s ../unlisted.md "$tmp_docs/.buildroom-docs/unlisted-link.md"
if "$root/bin/build-docs" --root "$tmp_docs" --check >"$tmp_docs/output" 2>&1; then
  echo 'Documentation checks must reject symbolic links in the staging directory' >&2
  exit 1
fi
grep -Fq 'documentation output must not contain symbolic links' "$tmp_docs/output"
"$root/bin/build-docs" --root "$tmp_docs" --write >/dev/null
test ! -e "$tmp_docs/.buildroom-docs/unlisted.md"

if "$root/bin/build-docs" --root "$tmp_docs" --output "$tmp_docs/agents" --write >"$tmp_docs/output" 2>&1; then
  echo 'Documentation assembly must reject canonical source directories as output' >&2
  exit 1
fi
grep -Fq 'dedicated .buildroom-docs staging directory' "$tmp_docs/output"
test -f "$tmp_docs/agents/researcher.md"

make_docs_fixture "$tmp_docs_source_link"
mv "$tmp_docs_source_link/README.md" "$tmp_docs_source_link/README-source.md"
ln -s README-source.md "$tmp_docs_source_link/README.md"
if "$root/bin/build-docs" --root "$tmp_docs_source_link" --write >"$tmp_docs_source_link/output" 2>&1; then
  echo 'Documentation assembly must reject allowlisted source symbolic links' >&2
  exit 1
fi
grep -Fq 'allowlisted source must be a regular file' "$tmp_docs_source_link/output"
test ! -e "$tmp_docs_source_link/.buildroom-docs"

make_docs_fixture "$tmp_docs_invalid"
awk 'BEGIN { changed = 0 } { if (!changed && /domain\/buildroom/) { sub("domain/buildroom", "invalid/tag"); changed = 1 } print } END { if (!changed) exit 2 }' \
  "$tmp_docs_invalid/agents/researcher.md" > "$tmp_docs_invalid/researcher.md" && mv "$tmp_docs_invalid/researcher.md" "$tmp_docs_invalid/agents/researcher.md"
if "$root/bin/build-docs" --root "$tmp_docs_invalid" --write >"$tmp_docs_invalid/output" 2>&1; then
  echo 'Documentation assembly must fail when knowledge metadata is invalid' >&2
  exit 1
fi
grep -Fq 'knowledge validation failed; documentation source was not assembled' "$tmp_docs_invalid/output"
test ! -e "$tmp_docs_invalid/.buildroom-docs"

while IFS= read -r destination; do
  grep -Fq -- ": $destination" "$root/mkdocs.yml" || {
    echo "Allowlisted destination is missing from navigation: $destination" >&2
    exit 1
  }
done <<EOF
$(awk '/^    destination: / { print $2 }' "$root/docs/public-content.yml")
EOF

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
require_text workflows/feature-delivery.md 'Johnson-to-Feynman hand-off'
require_text workflows/feature-delivery.md 'Johnson-to-Lovelace'
require_text workflows/feature-delivery.md 'simultaneous ownership'
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
require_text workflows/bug-fix.md 'Feynman-to-Johnson hand-off'
require_text workflows/bug-fix.md 'proposed hand-off'
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
require_text registry.tsv 'Johnson — Lead Engineer'
require_text registry.tsv 'Lovelace — Frontend Engineer'
require_text registry.tsv 'Euler — Backend Engineer'
require_text registry.tsv 'Hypatia — Product Designer'
require_text registry.tsv 'Shannon — Security & Privacy Reviewer'
require_text registry.tsv 'Bug Fix'
require_text registry.tsv 'No-Bullshit Bug Fix'
require_text workflows/feature-delivery.md 'Johnson requests a bounded Hypatia review'
require_text workflows/feature-delivery.md 'materially changes user journeys, navigation, interaction, onboarding, content comprehension, or accessibility'
require_text workflows/feature-delivery.md 'Johnson requests Shannon’s threat/risk review'
require_text workflows/feature-delivery.md 'authentication, authorization, sensitive data, external trust boundaries, security-relevant dependencies'
require_text workflows/feature-delivery.md 'before the first consequential implementation action'
require_text workflows/feature-delivery.md 'Shannon cannot accept or waive risk'
require_text workflows/prd-to-tech-spec.md 'obtain Shannon’s threat/risk assessment'
require_text workflows/bug-fix.md 'Shannon reviews the threat and privacy implications'
require_text workflows/bug-fix.md 'never delay urgent containment for review'
require_text agents/hypatia.md 'Must not:** silently redefine product requirements'
require_text agents/shannon.md 'Must not:** accept or waive risk'
require_text agents/shannon.md 'distinguish observed facts from hypotheses'
require_text tests/master-routing-eval.md 'Keep Hypatia and Shannon out unless their documented UX/security triggers apply; never delegate by default.'
require_text tests/master-routing-eval.md 'before the named human gate'
require_text docs/project-installer.md 'nine lightweight role-agent profiles'
require_text codex/AGENTS.md.snippet 'registry.tsv'
require_text README.md 'Name registry'

resolve_output=$(sh "$root/bin/buildroom" resolve Researcher)
printf '%s\n' "$resolve_output" | grep -Fq 'Type: agent'
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Noether — Researcher'
printf '%s\n' "$resolve_output" | grep -Fq 'buildroom/agents/researcher.md'

resolve_output=$(sh "$root/bin/buildroom" resolve 'Product Manager')
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Curie — Product Manager'

resolve_output=$(sh "$root/bin/buildroom" resolve pesquisador)
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Noether — Researcher'

resolve_output=$(sh "$root/bin/buildroom" resolve PM)
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Curie — Product Manager'

resolve_output=$(sh "$root/bin/buildroom" resolve qa)
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Feynman — QA Reviewer'

resolve_output=$(sh "$root/bin/buildroom" resolve accessibility)
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Hypatia — Product Designer'

resolve_output=$(sh "$root/bin/buildroom" resolve 'privacy reviewer')
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: Shannon — Security & Privacy Reviewer'

list_output=$(sh "$root/bin/buildroom" list)
printf '%s\n' "$list_output" | grep -Fq 'agent: Hypatia — Product Designer'
printf '%s\n' "$list_output" | grep -Fq 'agent: Shannon — Security & Privacy Reviewer'

for name in Curie Turing Feynman Hypatia Shannon Engineer developer dev 'Lead Engineer' Lovelace 'Frontend Engineer' Euler 'Backend Engineer'; do
  sh "$root/bin/buildroom" resolve "$name" | grep -Fq 'Type: agent'
done

resolve_output=$(sh "$root/bin/buildroom" resolve 'correção de bug')
printf '%s\n' "$resolve_output" | grep -Fq 'Type: workflow'
printf '%s\n' "$resolve_output" | grep -Fq 'buildroom/workflows/bug-fix.md'

resolve_output=$(sh "$root/bin/buildroom" resolve 'no bullshit bug fix')
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: No-Bullshit Bug Fix'
printf '%s\n' "$resolve_output" | grep -Fq 'buildroom/workflows/no-bullshit-bug-fix.md'

resolve_output=$(sh "$root/bin/buildroom" resolve 'No-Bullshit Bug Fix')
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: No-Bullshit Bug Fix'

resolve_output=$(sh "$root/bin/buildroom" resolve 'correção rápida')
printf '%s\n' "$resolve_output" | grep -Fq 'Resolved: No-Bullshit Bug Fix'

list_output=$(sh "$root/bin/buildroom" list)
printf '%s\n' "$list_output" | grep -Fq 'agent: Noether — Researcher'
printf '%s\n' "$list_output" | grep -Fq 'agent: Johnson — Lead Engineer'
printf '%s\n' "$list_output" | grep -Fq 'workflow: Bug Fix'
printf '%s\n' "$list_output" | grep -Fq 'workflow: No-Bullshit Bug Fix'

test -x "$root/bin/buildroom"
"$root/bin/buildroom" list >/dev/null
if unknown_output=$(sh "$root/bin/buildroom" resolve 'not an agent' 2>&1); then
  echo 'Unknown names must fail resolution' >&2
  exit 1
fi
printf '%s\n' "$unknown_output" | grep -Fq 'explicit `buildroom/...` Markdown path'

sh "$root/tests/verify-run-operations.sh"
node --test "$root/tests/project-installer.test.mjs"

echo 'buildroom verification passed'
