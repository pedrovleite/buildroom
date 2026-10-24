#!/usr/bin/env sh
set -eu

site_root=${1:?Usage: verify-pages-artifact.sh SITE_ROOT}
docs_root="$site_root/docs"
expected_docs=$(printf '%s\n' \
  "$docs_root/project-installer/index.html" \
  "$docs_root/run-operations/index.html")

if ! test -d "$docs_root"; then
  printf '%s\n' "$expected_docs" | while IFS= read -r page; do
    echo "Missing expected documentation page: $page" >&2
  done
  exit 1
fi

symbolic_links=$(find "$docs_root" -type l -print)
if test -n "$symbolic_links"; then
  echo "Symbolic links reached the Pages artifact documentation directory:" >&2
  printf '%s\n' "$symbolic_links" >&2
  exit 1
fi

missing_docs=$(printf '%s\n' "$expected_docs" | while IFS= read -r page; do
  test -f "$page" || printf '%s\n' "$page"
done)
if test -n "$missing_docs"; then
  printf '%s\n' "$missing_docs" | while IFS= read -r page; do
    echo "Missing expected documentation page: $page" >&2
  done
  exit 1
fi

actual_docs=$(find "$docs_root" -type f -print | sort)
unexpected_docs=$(printf '%s\n' "$actual_docs" | while IFS= read -r page; do
  if ! printf '%s\n' "$expected_docs" | grep -Fqx -- "$page"; then
    printf '%s\n' "$page"
  fi
done)
if test -n "$unexpected_docs"; then
  echo "Unexpected documentation pages reached the Pages artifact:" >&2
  printf '%s\n' "$unexpected_docs" >&2
  exit 1
fi
