#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-runs.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

make_project() {
  project=$1
  mkdir -p "$project/product/active" "$project/product/archive" "$project/product/memory"
  printf '# Target instructions\n' > "$project/AGENTS.md"
  : > "$project/product/memory/index.md"
  : > "$project/product/memory/decision-log.md"
}

populate_handoff() {
  handoff=$1
  awk '{ print; if ($0 == "## Evidence links") print "\nNot applicable for this hand-off."; else if ($0 ~ /^## /) print "\nRecorded hand-off detail." }' "$handoff" > "$tmp/populated-handoff"
  mv "$tmp/populated-handoff" "$handoff"
}

expect_exit() {
  expected=$1
  shift
  if "$@" >"$tmp/output" 2>&1; then actual=0; else actual=$?; fi
  test "$actual" -eq "$expected" || {
    cat "$tmp/output" >&2
    echo "Expected exit $expected, got $actual: $*" >&2
    exit 1
  }
}

normal="$tmp/normal"
make_project "$normal"
expect_exit 0 sh "$root/bin/buildroom" start feature WORK-101 --project "$normal"
test -d "$normal/product/active/WORK-101"
test "$(find "$normal/product/active/WORK-101" -type f | wc -l | tr -d ' ')" = 1
state="$normal/product/active/WORK-101/workflow-state.md"
grep -Fxq 'id: WORK-101' "$state"
grep -Fxq 'workflow: feature-delivery' "$state"
grep -Fxq 'owner_role: Engineer' "$state"
grep -Fxq 'route: standard' "$state"
cp -R "$normal" "$tmp/normal-before"
expect_exit 0 sh "$root/bin/buildroom" check WORK-101 --project "$normal"
grep -Fq 'READY: run WORK-101 is structurally ready for Engineer.' "$tmp/output"
diff -ru "$tmp/normal-before" "$normal"

for route_map in \
  'research-to-prd|RESEARCH-1|Researcher|draft|standard' \
  'prd-to-tech-spec|SPEC-1|Architect|draft|standard' \
  'bug-fix|BUG-1|QA Reviewer|triage|standard'; do
  IFS='|' read -r workflow identifier owner status route <<EOF
$route_map
EOF
  project="$tmp/$identifier"
  make_project "$project"
  expect_exit 0 sh "$root/bin/buildroom" start "$workflow" "$identifier" --project "$project"
  mapped_state="$project/product/active/$identifier/workflow-state.md"
  grep -Fxq "owner_role: $owner" "$mapped_state"
  grep -Fxq "status: $status" "$mapped_state"
  grep -Fxq "route: $route" "$mapped_state"
done

printf 'image evidence\n' > "$normal/product/active/WORK-101/evidence.png"
printf 'guide\n' > "$normal/product/active/WORK-101/guide.txt"
printf '\n![image](evidence.png "Evidence image")\n[guide]: guide.txt "Guide"\n' >> "$state"
expect_exit 0 sh "$root/bin/buildroom" check WORK-101 --project "$normal"

express="$tmp/express"
make_project "$express"
expect_exit 2 sh "$root/bin/buildroom" start no-bullshit-bug-fix FIX-1 --project "$express"
grep -Fq -- '--approve-express' "$tmp/output"
test ! -e "$express/product/active/FIX-1"
expect_exit 0 sh "$root/bin/buildroom" start no-bullshit-bug-fix FIX-1 --approve-express --project "$express"
grep -Fxq 'owner_role: Engineer' "$express/product/active/FIX-1/workflow-state.md"
grep -Fxq 'status: preflight' "$express/product/active/FIX-1/workflow-state.md"
grep -Fxq 'route: express' "$express/product/active/FIX-1/workflow-state.md"
grep -Fq 'eligibility and regression checks remain required' "$express/product/active/FIX-1/workflow-state.md"

unsafe="$tmp/unsafe"
make_project "$unsafe"
expect_exit 2 sh "$root/bin/buildroom" start unknown-workflow BAD-1 --project "$unsafe"
expect_exit 2 sh "$root/bin/buildroom" start Researcher BAD-2 --project "$unsafe"
expect_exit 2 sh "$root/bin/buildroom" start feature ../BAD --project "$unsafe"
test ! -e "$unsafe/product/active/BAD-1"
test ! -e "$unsafe/product/active/BAD-2"
cp "$normal/product/active/WORK-101/workflow-state.md" "$tmp/duplicate-before"
expect_exit 2 sh "$root/bin/buildroom" start feature WORK-101 --project "$normal"
grep -Fq 'already exists' "$tmp/output"
cmp "$tmp/duplicate-before" "$normal/product/active/WORK-101/workflow-state.md"
ln -s "$tmp/external" "$unsafe/product/active/LINK-1"
expect_exit 2 sh "$root/bin/buildroom" start feature LINK-1 --project "$unsafe"
grep -Fq 'unsafe destination' "$tmp/output"
printf 'not a directory\n' > "$unsafe/product/active/BAD-TYPE"
expect_exit 2 sh "$root/bin/buildroom" start feature BAD-TYPE --project "$unsafe"
uninitialized="$tmp/uninitialized"
mkdir "$uninitialized"
expect_exit 2 sh "$root/bin/buildroom" start feature NEW-1 --project "$uninitialized"
test ! -e "$uninitialized/product"

concurrent="$tmp/concurrent"
make_project "$concurrent"
set +e
sh "$root/bin/buildroom" start feature RACE-1 --project "$concurrent" >"$tmp/race-one" 2>&1 &
first=$!
sh "$root/bin/buildroom" start feature RACE-1 --project "$concurrent" >"$tmp/race-two" 2>&1 &
second=$!
wait "$first"; first_status=$?
wait "$second"; second_status=$?
set -e
test "$first_status" -eq 0 || test "$second_status" -eq 0
test "$first_status" -eq 2 || test "$second_status" -eq 2
test "$(find "$concurrent/product/active/RACE-1" -type f | wc -l | tr -d ' ')" = 1

missing="$tmp/missing"
make_project "$missing"
mkdir "$missing/product/active/MISS-1"
expect_exit 1 sh "$root/bin/buildroom" check MISS-1 --project "$missing"
grep -Fq 'workflow-state.md is missing' "$tmp/output"

blocked="$tmp/blocked"
make_project "$blocked"
expect_exit 0 sh "$root/bin/buildroom" start feature BLOCK-1 --project "$blocked"
state="$blocked/product/active/BLOCK-1/workflow-state.md"
sed '/## Exit criteria/d' "$state" > "$tmp/state-without-section" && mv "$tmp/state-without-section" "$state"
cp "$state" "$tmp/blocked-before"
expect_exit 1 sh "$root/bin/buildroom" check BLOCK-1 --project "$blocked"
grep -Fq 'missing required section `Exit criteria`' "$tmp/output"
cmp "$tmp/blocked-before" "$state"
awk '{ print; if ($0 == "## Evidence links") print "\n[escaped](../../../../outside.md)" }' "$state" > "$tmp/state-with-link" && mv "$tmp/state-with-link" "$state"
expect_exit 1 sh "$root/bin/buildroom" check BLOCK-1 --project "$blocked"
grep -Fq 'unreadable or escapes the project' "$tmp/output"

route_mismatch="$tmp/route-mismatch"
make_project "$route_mismatch"
expect_exit 0 sh "$root/bin/buildroom" start feature ROUTE-1 --project "$route_mismatch"
route_state="$route_mismatch/product/active/ROUTE-1/workflow-state.md"
sed 's/route: standard/route: express/' "$route_state" > "$tmp/route-state" && mv "$tmp/route-state" "$route_state"
expect_exit 1 sh "$root/bin/buildroom" check ROUTE-1 --project "$route_mismatch"
grep -Fq 'requires route `standard`' "$tmp/output"

handoff="$tmp/handoff"
make_project "$handoff"
expect_exit 0 sh "$root/bin/buildroom" start feature HAND-1 --project "$handoff"
handoff_state="$handoff/product/active/HAND-1/workflow-state.md"
sed 's/owner_role: Engineer/owner_role: QA Reviewer/' "$handoff_state" > "$tmp/handoff-state" && mv "$tmp/handoff-state" "$handoff_state"
cp "$root/templates/handoff.md" "$handoff/product/active/HAND-1/handoff-engineer-to-qa.md"
sed -e 's/work_id: WORK-000/work_id: HAND-1/' -e 's/from_role: Researcher/from_role: Engineer/' -e 's/to_role: Product Manager/to_role: QA Reviewer/' "$handoff/product/active/HAND-1/handoff-engineer-to-qa.md" > "$tmp/unaccepted-handoff" && mv "$tmp/unaccepted-handoff" "$handoff/product/active/HAND-1/handoff-engineer-to-qa.md"
expect_exit 1 sh "$root/bin/buildroom" check HAND-1 --project "$handoff"
grep -Fq 'no accepted matching hand-off' "$tmp/output"

accepted="$tmp/accepted"
make_project "$accepted"
expect_exit 0 sh "$root/bin/buildroom" start feature ACCEPT-1 --project "$accepted"
accepted_state="$accepted/product/active/ACCEPT-1/workflow-state.md"
sed 's/owner_role: Engineer/owner_role: QA Reviewer/' "$accepted_state" > "$tmp/accepted-state" && mv "$tmp/accepted-state" "$accepted_state"
cp "$root/templates/handoff.md" "$accepted/product/active/ACCEPT-1/handoff-engineer-to-qa.md"
sed -e 's/work_id: WORK-000/work_id: ACCEPT-1/' -e 's/from_role: Researcher/from_role: Engineer/' -e 's/to_role: Product Manager/to_role: QA Reviewer/' -e 's/status: proposed/status: accepted/' -e 's/- \[ \] Accepted,/- [x] Accepted,/' "$accepted/product/active/ACCEPT-1/handoff-engineer-to-qa.md" > "$tmp/accepted-handoff" && mv "$tmp/accepted-handoff" "$accepted/product/active/ACCEPT-1/handoff-engineer-to-qa.md"
populate_handoff "$accepted/product/active/ACCEPT-1/handoff-engineer-to-qa.md"
printf 'handoff evidence\n' > "$accepted/product/active/ACCEPT-1/handoff-note.txt"
printf '\n[handoff evidence](handoff-note.txt)\n' >> "$accepted/product/active/ACCEPT-1/handoff-engineer-to-qa.md"
expect_exit 0 sh "$root/bin/buildroom" check ACCEPT-1 --project "$accepted"
grep -Fq 'READY: run ACCEPT-1 is structurally ready for QA Reviewer.' "$tmp/output"

invalid_accepted="$tmp/invalid-accepted"
make_project "$invalid_accepted"
expect_exit 0 sh "$root/bin/buildroom" start feature ACCEPT-2 --project "$invalid_accepted"
invalid_state="$invalid_accepted/product/active/ACCEPT-2/workflow-state.md"
sed 's/owner_role: Engineer/owner_role: QA Reviewer/' "$invalid_state" > "$tmp/invalid-state" && mv "$tmp/invalid-state" "$invalid_state"
cp "$accepted/product/active/ACCEPT-1/handoff-engineer-to-qa.md" "$invalid_accepted/product/active/ACCEPT-2/handoff-engineer-to-qa.md"
awk 'BEGIN { in_exit = 0 } $0 == "## Exit criteria" { in_exit = 1 } in_exit && $0 == "Recorded hand-off detail." { in_exit = 0; next } { print }' "$invalid_accepted/product/active/ACCEPT-2/handoff-engineer-to-qa.md" | sed 's/work_id: ACCEPT-1/work_id: ACCEPT-2/' > "$tmp/invalid-accepted-handoff" && mv "$tmp/invalid-accepted-handoff" "$invalid_accepted/product/active/ACCEPT-2/handoff-engineer-to-qa.md"
expect_exit 1 sh "$root/bin/buildroom" check ACCEPT-2 --project "$invalid_accepted"
grep -Fq 'accepted hand-off `handoff-engineer-to-qa.md` required section `Exit criteria` is empty' "$tmp/output"

approval="$tmp/approval"
make_project "$approval"
expect_exit 0 sh "$root/bin/buildroom" start bug-fix APPROVE-1 --project "$approval"
approval_state="$approval/product/active/APPROVE-1/workflow-state.md"
sed 's/status: triage/status: awaiting-approval/' "$approval_state" > "$tmp/approval-state" && mv "$tmp/approval-state" "$approval_state"
awk '{ print; if ($0 == "## Decisions in force") print "human decision required: approve the change." }' "$approval_state" > "$tmp/approval-with-decision" && mv "$tmp/approval-with-decision" "$approval_state"
cp "$approval_state" "$tmp/approval-before"
expect_exit 1 sh "$root/bin/buildroom" check APPROVE-1 --project "$approval"
grep -Fq 'awaits a human approval' "$tmp/output"
cmp "$tmp/approval-before" "$approval_state"

expect_exit 2 sh "$root/bin/buildroom" check ../invalid --project "$approval"

portable="$tmp/portable"
mkdir "$portable"
cp -R "$root/bin" "$root/scripts" "$root/templates" "$root/registry.tsv" "$portable/"
portable_project="$tmp/portable-project"
make_project "$portable_project"
expect_exit 0 sh "$portable/bin/buildroom" start research-to-prd PORT-1 --project "$portable_project"
expect_exit 0 sh "$portable/bin/buildroom" check PORT-1 --project "$portable_project"

echo 'Buildroom run operations verification passed.'
