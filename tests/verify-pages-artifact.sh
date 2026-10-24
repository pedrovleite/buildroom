#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

check="$root/bin/verify-pages-artifact.sh"
workflow="$root/.github/workflows/docs.yml"
grep -Fq 'sh bin/verify-pages-artifact.sh .buildroom-site' "$workflow"
grep -Fq 'sh "$root/tests/verify-pages-artifact.sh"' "$root/tests/verify.sh"

make_expected_site() {
  site=$1
  mkdir -p "$site/docs/project-installer" "$site/docs/run-operations"
  : > "$site/docs/project-installer/index.html"
  : > "$site/docs/run-operations/index.html"
}

make_expected_site "$tmp/valid"
sh "$check" "$tmp/valid"

make_expected_site "$tmp/missing"
rm "$tmp/missing/docs/project-installer/index.html"
if sh "$check" "$tmp/missing" >"$tmp/output" 2>&1; then
  echo 'Artifact check must reject a missing expected guide' >&2
  exit 1
fi
grep -Fq 'Missing expected documentation page:' "$tmp/output"
if grep -Fq 'Unexpected documentation pages' "$tmp/output"; then
  echo 'A missing guide must have a distinct diagnostic' >&2
  exit 1
fi

make_expected_site "$tmp/unexpected"
: > "$tmp/unexpected/docs/third-guide.html"
if sh "$check" "$tmp/unexpected" >"$tmp/output" 2>&1; then
  echo 'Artifact check must reject an unexpected third page' >&2
  exit 1
fi
grep -Fq 'Unexpected documentation pages' "$tmp/output"

make_expected_site "$tmp/symlink"
ln -s project-installer/index.html "$tmp/symlink/docs/installer-link.html"
if sh "$check" "$tmp/symlink" >"$tmp/output" 2>&1; then
  echo 'Artifact check must reject symbolic links' >&2
  exit 1
fi
grep -Fq 'Symbolic links reached the Pages artifact' "$tmp/output"

echo 'Pages artifact boundary verification passed.'
