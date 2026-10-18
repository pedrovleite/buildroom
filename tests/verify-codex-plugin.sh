#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
codex_root=${CODEX_HOME:-"$HOME/.codex"}
validator="$codex_root/skills/.system/plugin-creator/scripts/validate_plugin.py"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-plugin-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

"$root/bin/build-knowledge" --check
"$root/bin/build-codex-plugin" --output "$tmp/plugin" --write
uv run --with pyyaml python "$validator" "$tmp/plugin"

test -f "$tmp/plugin/.codex-plugin/plugin.json"
test -f "$tmp/plugin/skills/buildroom/SKILL.md"
test -f "$tmp/plugin/skills/buildroom-init/SKILL.md"
test -f "$tmp/plugin/scripts/init-project.py"
test -f "$tmp/plugin/skills/buildroom/references/toolkit/knowledge/catalog.yml"
test -f "$tmp/plugin/skills/buildroom/references/toolkit/workflows/bug-fix.md"
test -f "$tmp/plugin/skills/buildroom/references/toolkit/codex/AGENTS.global-plugin.snippet"
cmp "$root/knowledge/catalog.yml" "$tmp/plugin/skills/buildroom/references/toolkit/knowledge/catalog.yml"

stale="$tmp/stale-plugin"
"$root/bin/build-codex-plugin" --output "$stale" --write
stale_file="$stale/skills/buildroom/references/toolkit/knowledge/catalog.yml"
python3 - "$stale_file" <<'PY'
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
metadata = path.stat()
content = path.read_bytes()
replacement = b"x" if content[:1] != b"x" else b"y"
path.write_bytes(replacement + content[1:])
os.utime(path, ns=(metadata.st_atime_ns, metadata.st_mtime_ns))
PY
if "$root/bin/build-codex-plugin" --output "$stale" --check >"$tmp/stale-output" 2>&1; then
  echo 'Plugin checks must compare bytes even when file size and mtime match.' >&2
  exit 1
fi
grep -Fq 'out of date' "$tmp/stale-output"

backup_output="$tmp/backup-output"
"$root/bin/build-codex-plugin" --output "$backup_output" --write
mkdir "$tmp/.backup-output.backup"
if "$root/bin/build-codex-plugin" --output "$backup_output" --write >"$tmp/backup-output-log" 2>&1; then
  echo 'Plugin builds must not delete an existing backup directory.' >&2
  exit 1
fi
grep -Fq 'backup path already exists' "$tmp/backup-output-log"

if "$root/bin/build-codex-plugin" --output "$root/plugins" --write >"$tmp/source-parent-output" 2>&1; then
  echo 'Plugin builds must reject an output that contains the source plugin.' >&2
  exit 1
fi
grep -Fq 'must not replace the Buildroom source directory' "$tmp/source-parent-output"

target="$tmp/target"
mkdir -p "$target"
printf '# Existing repository instructions\n' > "$target/AGENTS.md"
python3 "$tmp/plugin/scripts/init-project.py" "$target"
grep -Fq '# Existing repository instructions' "$target/AGENTS.md"
grep -Fq '<!-- buildroom:global-plugin:start -->' "$target/AGENTS.md"
test -d "$target/product/active"
test -d "$target/product/archive"
test -f "$target/product/memory/index.md"
test -f "$target/product/memory/decision-log.md"
cp "$target/AGENTS.md" "$tmp/agents-before.md"
python3 "$tmp/plugin/scripts/init-project.py" "$target"
cmp "$tmp/agents-before.md" "$target/AGENTS.md"

bad="$tmp/bad-target"
mkdir -p "$bad"
printf '%s\n' '<!-- buildroom:global-plugin:start -->' > "$bad/AGENTS.md"
if python3 "$tmp/plugin/scripts/init-project.py" "$bad" >"$tmp/bad-output" 2>&1; then
  echo 'Malformed AGENTS.md markers should stop initialization.' >&2
  exit 1
fi
grep -Fq 'malformed Buildroom markers' "$tmp/bad-output"
test ! -e "$bad/product"

legacy="$tmp/legacy-target"
mkdir "$legacy"
printf '%s\n%s\n%s\n%s\n%s\n' '# Existing repository instructions' '<!-- product-os:global-plugin:start -->' 'Legacy routing that must be replaced' '<!-- product-os:global-plugin:end -->' '# Trailing host instruction' > "$legacy/AGENTS.md"
mkdir -p "$legacy/product/active"
printf 'keep this state\n' > "$legacy/product/active/existing.md"
python3 "$tmp/plugin/scripts/init-project.py" "$legacy"
grep -Fq '# Existing repository instructions' "$legacy/AGENTS.md"
grep -Fq '# Trailing host instruction' "$legacy/AGENTS.md"
grep -Fq '<!-- buildroom:global-plugin:start -->' "$legacy/AGENTS.md"
grep -Fq '<!-- buildroom:global-plugin:end -->' "$legacy/AGENTS.md"
if grep -Fq '<!-- product-os:global-plugin:start -->' "$legacy/AGENTS.md"; then
  echo 'Legacy Product OS markers should be migrated to Buildroom.' >&2
  exit 1
fi
if grep -Fq 'Legacy routing that must be replaced' "$legacy/AGENTS.md"; then
  echo 'Legacy Product OS routing content should be replaced by Buildroom.' >&2
  exit 1
fi
grep -Fq 'keep this state' "$legacy/product/active/existing.md"

reversed_current="$tmp/reversed-current-target"
mkdir "$reversed_current"
printf '%s\n%s\n' '<!-- buildroom:global-plugin:end -->' '<!-- buildroom:global-plugin:start -->' > "$reversed_current/AGENTS.md"
if python3 "$tmp/plugin/scripts/init-project.py" "$reversed_current" >"$tmp/reversed-current-output" 2>&1; then
  echo 'Reversed Buildroom markers should stop initialization.' >&2
  exit 1
fi
grep -Fq 'malformed Buildroom markers' "$tmp/reversed-current-output"
test ! -e "$reversed_current/product"

reversed_legacy="$tmp/reversed-legacy-target"
mkdir "$reversed_legacy"
printf '%s\n%s\n' '<!-- product-os:global-plugin:end -->' '<!-- product-os:global-plugin:start -->' > "$reversed_legacy/AGENTS.md"
if python3 "$tmp/plugin/scripts/init-project.py" "$reversed_legacy" >"$tmp/reversed-legacy-output" 2>&1; then
  echo 'Reversed legacy Product OS markers should stop initialization.' >&2
  exit 1
fi
grep -Fq 'malformed legacy Product OS markers' "$tmp/reversed-legacy-output"
test ! -e "$reversed_legacy/product"

mixed="$tmp/mixed-target"
mkdir "$mixed"
printf '%s\n%s\n%s\n%s\n' '<!-- buildroom:global-plugin:start -->' '<!-- buildroom:global-plugin:end -->' '<!-- product-os:global-plugin:start -->' '<!-- product-os:global-plugin:end -->' > "$mixed/AGENTS.md"
if python3 "$tmp/plugin/scripts/init-project.py" "$mixed" >"$tmp/mixed-output" 2>&1; then
  echo 'Mixed Buildroom and legacy markers should stop initialization.' >&2
  exit 1
fi
grep -Fq 'both Buildroom and legacy Product OS markers' "$tmp/mixed-output"
test ! -e "$mixed/product"

symlink_target="$tmp/external-agents.md"
printf '# External instructions\n' > "$symlink_target"
symlink_target_repo="$tmp/symlink-target"
mkdir "$symlink_target_repo"
ln -s "$symlink_target" "$symlink_target_repo/AGENTS.md"
if python3 "$tmp/plugin/scripts/init-project.py" "$symlink_target_repo" >"$tmp/symlink-output" 2>&1; then
  echo 'Symbolic-link AGENTS.md should stop initialization.' >&2
  exit 1
fi
grep -Fq 'Expected a regular file or no path' "$tmp/symlink-output"
test ! -e "$symlink_target_repo/product"

wrong_type="$tmp/wrong-type-target"
mkdir -p "$wrong_type/product"
printf 'not a directory\n' > "$wrong_type/product/active"
if python3 "$tmp/plugin/scripts/init-project.py" "$wrong_type" >"$tmp/wrong-type-output" 2>&1; then
  echo 'A file in place of a Buildroom directory should stop initialization.' >&2
  exit 1
fi
grep -Fq 'Expected a directory or no path' "$tmp/wrong-type-output"

"$root/bin/install-codex-plugin" --dry-run >"$tmp/install-output"
grep -Fq 'dry-run: would install validated plugin' "$tmp/install-output"

if PRODUCT_OS_PLUGIN_PARENT="$tmp/unsafe-legacy-override" "$root/bin/install-codex-plugin" --dry-run >"$tmp/legacy-override-output" 2>&1; then
  echo 'Legacy Product OS installer overrides should fail safely.' >&2
  exit 1
fi
grep -Fq 'PRODUCT_OS_* installer overrides are no longer supported' "$tmp/legacy-override-output"

rollback_parent="$tmp/rollback-plugins"
rollback_destination="$rollback_parent/buildroom"
rollback_marketplace="$tmp/rollback-marketplace.json"
mkdir -p "$rollback_destination" "$tmp/bin"
printf 'previous plugin source\n' > "$rollback_destination/marker"
printf '{"name":"personal","plugins":[]}\n' > "$rollback_marketplace"
printf '#!/usr/bin/env sh\nexit 1\n' > "$tmp/bin/fail-codex"
chmod +x "$tmp/bin/fail-codex"
if BUILDROOM_PLUGIN_PARENT="$rollback_parent" BUILDROOM_MARKETPLACE_PATH="$rollback_marketplace" BUILDROOM_CODEX_COMMAND="$tmp/bin/fail-codex" "$root/bin/install-codex-plugin" >"$tmp/rollback-output" 2>&1; then
  echo 'A failed Codex installation should fail the installer.' >&2
  exit 1
fi
grep -Fq 'restored the previous Buildroom plugin source' "$tmp/rollback-output"
grep -Fq 'previous plugin source' "$rollback_destination/marker"

success_parent="$tmp/success-plugins"
success_destination="$success_parent/buildroom"
success_marketplace="$tmp/success-marketplace.json"
mkdir -p "$success_destination"
printf 'previous plugin source\n' > "$success_destination/marker"
printf '{"name":"localtest","plugins":[]}\n' > "$success_marketplace"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$@" > "%s"\n' "$tmp/success-args" > "$tmp/bin/succeed-codex"
chmod +x "$tmp/bin/succeed-codex"
BUILDROOM_PLUGIN_PARENT="$success_parent" BUILDROOM_MARKETPLACE_PATH="$success_marketplace" BUILDROOM_CODEX_COMMAND="$tmp/bin/succeed-codex" "$root/bin/install-codex-plugin" >"$tmp/success-output"
grep -Fxq 'plugin' "$tmp/success-args"
grep -Fxq 'add' "$tmp/success-args"
grep -Fxq 'buildroom@localtest' "$tmp/success-args"
grep -Fq './plugins/buildroom' "$success_marketplace"
test ! -e "$success_destination/marker"
test -f "$success_destination/.codex-plugin/plugin.json"
grep -Fq '+codex.' "$success_destination/.codex-plugin/plugin.json"

legacy_parent="$tmp/legacy-plugins"
legacy_destination="$legacy_parent/product-os"
legacy_marketplace="$tmp/legacy-marketplace.json"
mkdir -p "$legacy_destination"
printf 'legacy plugin source\n' > "$legacy_destination/marker"
printf '{"name":"legacytest","plugins":[]}\n' > "$legacy_marketplace"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$@" >> "%s"\n' "$tmp/legacy-args" > "$tmp/bin/retire-legacy-codex"
chmod +x "$tmp/bin/retire-legacy-codex"
BUILDROOM_PLUGIN_PARENT="$legacy_parent" BUILDROOM_MARKETPLACE_PATH="$legacy_marketplace" BUILDROOM_CODEX_COMMAND="$tmp/bin/retire-legacy-codex" "$root/bin/install-codex-plugin" >"$tmp/legacy-install-output"
grep -Fq 'buildroom@legacytest' "$tmp/legacy-args"
grep -Fq 'product-os@legacytest' "$tmp/legacy-args"
test ! -e "$legacy_destination"
test -f "$legacy_parent/buildroom/.codex-plugin/plugin.json"

echo 'Buildroom Codex plugin verification passed.'
