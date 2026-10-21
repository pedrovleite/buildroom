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

make_accepted_handoff() {
  run=$1
  identifier=$2
  filename=$3
  sender=$4
  recipient=$5
  cp "$root/templates/handoff.md" "$run/$filename"
  sed -e "s/work_id: WORK-000/work_id: $identifier/" -e "s/from_role: Researcher/from_role: $sender/" -e "s/to_role: Product Manager/to_role: $recipient/" -e 's/status: proposed/status: accepted/' -e 's/- \[ \] Accepted,/- [x] Accepted,/' "$run/$filename" > "$tmp/accepted-handoff"
  mv "$tmp/accepted-handoff" "$run/$filename"
  populate_handoff "$run/$filename"
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
grep -Fxq 'owner_role: Johnson — Lead Engineer' "$state"
grep -Fxq 'route: standard' "$state"
cp -R "$normal" "$tmp/normal-before"
expect_exit 0 sh "$root/bin/buildroom" check WORK-101 --project "$normal"
grep -Fq 'READY: run WORK-101 is structurally ready for Johnson — Lead Engineer.' "$tmp/output"
diff -ru "$tmp/normal-before" "$normal"

for route_map in \
  'research-to-prd|RESEARCH-1|Noether — Researcher|draft|standard' \
  'prd-to-tech-spec|SPEC-1|Turing — Architect|draft|standard' \
  'bug-fix|BUG-1|Feynman — QA Reviewer|triage|standard'; do
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
grep -Fxq 'owner_role: Johnson — Lead Engineer' "$express/product/active/FIX-1/workflow-state.md"
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
sed 's/owner_role: Johnson — Lead Engineer/owner_role: Feynman — QA Reviewer/' "$handoff_state" > "$tmp/handoff-state" && mv "$tmp/handoff-state" "$handoff_state"
cp "$root/templates/handoff.md" "$handoff/product/active/HAND-1/handoff-engineer-to-qa.md"
sed -e 's/work_id: WORK-000/work_id: HAND-1/' -e 's/from_role: Researcher/from_role: Johnson — Lead Engineer/' -e 's/to_role: Product Manager/to_role: Feynman — QA Reviewer/' "$handoff/product/active/HAND-1/handoff-engineer-to-qa.md" > "$tmp/unaccepted-handoff" && mv "$tmp/unaccepted-handoff" "$handoff/product/active/HAND-1/handoff-johnson-to-feynman.md"
expect_exit 1 sh "$root/bin/buildroom" check HAND-1 --project "$handoff"
grep -Fq 'no accepted matching hand-off' "$tmp/output"

accepted="$tmp/accepted"
make_project "$accepted"
expect_exit 0 sh "$root/bin/buildroom" start feature ACCEPT-1 --project "$accepted"
accepted_state="$accepted/product/active/ACCEPT-1/workflow-state.md"
sed 's/owner_role: Johnson — Lead Engineer/owner_role: Feynman — QA Reviewer/' "$accepted_state" > "$tmp/accepted-state" && mv "$tmp/accepted-state" "$accepted_state"
cp "$root/templates/handoff.md" "$accepted/product/active/ACCEPT-1/handoff-engineer-to-qa.md"
sed -e 's/work_id: WORK-000/work_id: ACCEPT-1/' -e 's/from_role: Researcher/from_role: Johnson — Lead Engineer/' -e 's/to_role: Product Manager/to_role: Feynman — QA Reviewer/' -e 's/status: proposed/status: accepted/' -e 's/- \[ \] Accepted,/- [x] Accepted,/' "$accepted/product/active/ACCEPT-1/handoff-engineer-to-qa.md" > "$tmp/accepted-handoff" && mv "$tmp/accepted-handoff" "$accepted/product/active/ACCEPT-1/handoff-johnson-to-feynman.md"
populate_handoff "$accepted/product/active/ACCEPT-1/handoff-johnson-to-feynman.md"
printf 'handoff evidence\n' > "$accepted/product/active/ACCEPT-1/handoff-note.txt"
printf '\n[handoff evidence](handoff-note.txt)\n' >> "$accepted/product/active/ACCEPT-1/handoff-johnson-to-feynman.md"
expect_exit 0 sh "$root/bin/buildroom" check ACCEPT-1 --project "$accepted"
grep -Fq 'READY: run ACCEPT-1 is structurally ready for Feynman — QA Reviewer.' "$tmp/output"

specialist="$tmp/specialist"
make_project "$specialist"
expect_exit 0 sh "$root/bin/buildroom" start feature SPECIALIST-1 --project "$specialist"
specialist_run="$specialist/product/active/SPECIALIST-1"
specialist_state="$specialist_run/workflow-state.md"
sed 's/owner_role: Johnson — Lead Engineer/owner_role: Lovelace — Frontend Engineer/' "$specialist_state" > "$tmp/specialist-state" && mv "$tmp/specialist-state" "$specialist_state"
make_accepted_handoff "$specialist_run" SPECIALIST-1 handoff-johnson-to-lovelace.md 'Johnson — Lead Engineer' 'Lovelace — Frontend Engineer'
expect_exit 0 sh "$root/bin/buildroom" check SPECIALIST-1 --project "$specialist"
sed 's/owner_role: Lovelace — Frontend Engineer/owner_role: Johnson — Lead Engineer/' "$specialist_state" > "$tmp/specialist-return-state" && mv "$tmp/specialist-return-state" "$specialist_state"
expect_exit 1 sh "$root/bin/buildroom" check SPECIALIST-1 --project "$specialist"
grep -Fq 'has no accepted return to Johnson' "$tmp/output"
make_accepted_handoff "$specialist_run" SPECIALIST-1 handoff-lovelace-to-johnson.md 'Lovelace — Frontend Engineer' 'Johnson — Lead Engineer'
expect_exit 0 sh "$root/bin/buildroom" check SPECIALIST-1 --project "$specialist"

backend="$tmp/backend"
make_project "$backend"
expect_exit 0 sh "$root/bin/buildroom" start feature BACKEND-1 --project "$backend"
backend_run="$backend/product/active/BACKEND-1"
backend_state="$backend_run/workflow-state.md"
sed 's/owner_role: Johnson — Lead Engineer/owner_role: Euler — Backend Engineer/' "$backend_state" > "$tmp/backend-state" && mv "$tmp/backend-state" "$backend_state"
make_accepted_handoff "$backend_run" BACKEND-1 handoff-johnson-to-euler.md 'Johnson — Lead Engineer' 'Euler — Backend Engineer'
expect_exit 0 sh "$root/bin/buildroom" check BACKEND-1 --project "$backend"
sed 's/owner_role: Euler — Backend Engineer/owner_role: Johnson — Lead Engineer/' "$backend_state" > "$tmp/backend-return-state" && mv "$tmp/backend-return-state" "$backend_state"
expect_exit 1 sh "$root/bin/buildroom" check BACKEND-1 --project "$backend"
make_accepted_handoff "$backend_run" BACKEND-1 handoff-euler-to-johnson.md 'Euler — Backend Engineer' 'Johnson — Lead Engineer'
expect_exit 0 sh "$root/bin/buildroom" check BACKEND-1 --project "$backend"

parallel="$tmp/parallel"
make_project "$parallel"
expect_exit 0 sh "$root/bin/buildroom" start feature PARALLEL-1 --project "$parallel"
parallel_run="$parallel/product/active/PARALLEL-1"
parallel_state="$parallel_run/workflow-state.md"
sed 's/owner_role: Johnson — Lead Engineer/owner_role: Lovelace — Frontend Engineer/' "$parallel_state" > "$tmp/parallel-state" && mv "$tmp/parallel-state" "$parallel_state"
make_accepted_handoff "$parallel_run" PARALLEL-1 handoff-johnson-to-lovelace.md 'Johnson — Lead Engineer' 'Lovelace — Frontend Engineer'
make_accepted_handoff "$parallel_run" PARALLEL-1 handoff-johnson-to-euler.md 'Johnson — Lead Engineer' 'Euler — Backend Engineer'
expect_exit 1 sh "$root/bin/buildroom" check PARALLEL-1 --project "$parallel"
grep -Fq 'more than one specialist has an unreturned Johnson hand-off' "$tmp/output"

invalid_transition="$tmp/invalid-transition"
make_project "$invalid_transition"
expect_exit 0 sh "$root/bin/buildroom" start feature INVALID-1 --project "$invalid_transition"
invalid_run="$invalid_transition/product/active/INVALID-1"
invalid_state="$invalid_run/workflow-state.md"
sed 's/owner_role: Johnson — Lead Engineer/owner_role: Euler — Backend Engineer/' "$invalid_state" > "$tmp/invalid-transition-state" && mv "$tmp/invalid-transition-state" "$invalid_state"
make_accepted_handoff "$invalid_run" INVALID-1 handoff-feynman-to-euler.md 'Feynman — QA Reviewer' 'Euler — Backend Engineer'
expect_exit 1 sh "$root/bin/buildroom" check INVALID-1 --project "$invalid_transition"
grep -Fq 'not an allowed owner transition' "$tmp/output"

express_delegation="$tmp/express-delegation"
make_project "$express_delegation"
expect_exit 0 sh "$root/bin/buildroom" start no-bullshit-bug-fix EXPRESS-1 --approve-express --project "$express_delegation"
express_run="$express_delegation/product/active/EXPRESS-1"
express_state="$express_run/workflow-state.md"
sed 's/owner_role: Johnson — Lead Engineer/owner_role: Lovelace — Frontend Engineer/' "$express_state" > "$tmp/express-delegation-state" && mv "$tmp/express-delegation-state" "$express_state"
make_accepted_handoff "$express_run" EXPRESS-1 handoff-johnson-to-lovelace.md 'Johnson — Lead Engineer' 'Lovelace — Frontend Engineer'
expect_exit 1 sh "$root/bin/buildroom" check EXPRESS-1 --project "$express_delegation"
grep -Fq 'express route must not accept hand-offs' "$tmp/output"

invalid_accepted="$tmp/invalid-accepted"
make_project "$invalid_accepted"
expect_exit 0 sh "$root/bin/buildroom" start feature ACCEPT-2 --project "$invalid_accepted"
invalid_state="$invalid_accepted/product/active/ACCEPT-2/workflow-state.md"
sed 's/owner_role: Johnson — Lead Engineer/owner_role: Feynman — QA Reviewer/' "$invalid_state" > "$tmp/invalid-state" && mv "$tmp/invalid-state" "$invalid_state"
cp "$accepted/product/active/ACCEPT-1/handoff-johnson-to-feynman.md" "$invalid_accepted/product/active/ACCEPT-2/handoff-johnson-to-feynman.md"
awk 'BEGIN { in_exit = 0 } $0 == "## Exit criteria" { in_exit = 1 } in_exit && $0 == "Recorded hand-off detail." { in_exit = 0; next } { print }' "$invalid_accepted/product/active/ACCEPT-2/handoff-johnson-to-feynman.md" | sed 's/work_id: ACCEPT-1/work_id: ACCEPT-2/' > "$tmp/invalid-accepted-handoff" && mv "$tmp/invalid-accepted-handoff" "$invalid_accepted/product/active/ACCEPT-2/handoff-johnson-to-feynman.md"
expect_exit 1 sh "$root/bin/buildroom" check ACCEPT-2 --project "$invalid_accepted"
grep -Fq 'accepted hand-off `handoff-johnson-to-feynman.md` required section `Exit criteria` is empty' "$tmp/output"

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
