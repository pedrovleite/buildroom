#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
codex_root=${CODEX_HOME:-"$HOME/.codex"}
validator="$codex_root/skills/.system/plugin-creator/scripts/validate_plugin.py"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/product-os-plugin-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

"$root/bin/build-knowledge" --check
"$root/bin/build-codex-plugin" --output "$tmp/plugin" --write
uv run --with pyyaml python "$validator" "$tmp/plugin"

test -f "$tmp/plugin/.codex-plugin/plugin.json"
test -f "$tmp/plugin/skills/product-os/SKILL.md"
test -f "$tmp/plugin/skills/product-os-init/SKILL.md"
test -f "$tmp/plugin/scripts/init-project.py"
test -f "$tmp/plugin/skills/product-os/references/toolkit/knowledge/catalog.yml"
test -f "$tmp/plugin/skills/product-os/references/toolkit/workflows/bug-fix.md"
test -f "$tmp/plugin/skills/product-os/references/toolkit/codex/AGENTS.global-plugin.snippet"
cmp "$root/knowledge/catalog.yml" "$tmp/plugin/skills/product-os/references/toolkit/knowledge/catalog.yml"

stale="$tmp/stale-plugin"
"$root/bin/build-codex-plugin" --output "$stale" --write
stale_file="$stale/skills/product-os/references/toolkit/knowledge/catalog.yml"
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
grep -Fq 'must not replace the Product OS source directory' "$tmp/source-parent-output"

target="$tmp/target"
mkdir -p "$target"
printf '# Existing repository instructions\n' > "$target/AGENTS.md"
python3 "$tmp/plugin/scripts/init-project.py" "$target"
grep -Fq '# Existing repository instructions' "$target/AGENTS.md"
grep -Fq '<!-- product-os:global-plugin:start -->' "$target/AGENTS.md"
test -d "$target/product/active"
test -d "$target/product/archive"
test -f "$target/product/memory/index.md"
test -f "$target/product/memory/decision-log.md"
cp "$target/AGENTS.md" "$tmp/agents-before.md"
python3 "$tmp/plugin/scripts/init-project.py" "$target"
cmp "$tmp/agents-before.md" "$target/AGENTS.md"

bad="$tmp/bad-target"
mkdir -p "$bad"
printf '%s\n' '<!-- product-os:global-plugin:start -->' > "$bad/AGENTS.md"
if python3 "$tmp/plugin/scripts/init-project.py" "$bad" >"$tmp/bad-output" 2>&1; then
  echo 'Malformed AGENTS.md markers should stop initialization.' >&2
  exit 1
fi
grep -Fq 'malformed Product OS markers' "$tmp/bad-output"
test ! -e "$bad/product"

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
  echo 'A file in place of a Product OS directory should stop initialization.' >&2
  exit 1
fi
grep -Fq 'Expected a directory or no path' "$tmp/wrong-type-output"

"$root/bin/install-codex-plugin" --dry-run >"$tmp/install-output"
grep -Fq 'dry-run: would install validated plugin' "$tmp/install-output"

rollback_parent="$tmp/rollback-plugins"
rollback_destination="$rollback_parent/product-os"
rollback_marketplace="$tmp/rollback-marketplace.json"
mkdir -p "$rollback_destination" "$tmp/bin"
printf 'previous plugin source\n' > "$rollback_destination/marker"
printf '{"name":"personal","plugins":[]}\n' > "$rollback_marketplace"
printf '#!/usr/bin/env sh\nexit 1\n' > "$tmp/bin/fail-codex"
chmod +x "$tmp/bin/fail-codex"
if PRODUCT_OS_PLUGIN_PARENT="$rollback_parent" PRODUCT_OS_MARKETPLACE_PATH="$rollback_marketplace" PRODUCT_OS_CODEX_COMMAND="$tmp/bin/fail-codex" "$root/bin/install-codex-plugin" >"$tmp/rollback-output" 2>&1; then
  echo 'A failed Codex installation should fail the installer.' >&2
  exit 1
fi
grep -Fq 'restored the previous Product OS plugin source' "$tmp/rollback-output"
grep -Fq 'previous plugin source' "$rollback_destination/marker"

success_parent="$tmp/success-plugins"
success_destination="$success_parent/product-os"
success_marketplace="$tmp/success-marketplace.json"
mkdir -p "$success_destination"
printf 'previous plugin source\n' > "$success_destination/marker"
printf '{"name":"localtest","plugins":[]}\n' > "$success_marketplace"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$@" > "%s"\n' "$tmp/success-args" > "$tmp/bin/succeed-codex"
chmod +x "$tmp/bin/succeed-codex"
PRODUCT_OS_PLUGIN_PARENT="$success_parent" PRODUCT_OS_MARKETPLACE_PATH="$success_marketplace" PRODUCT_OS_CODEX_COMMAND="$tmp/bin/succeed-codex" "$root/bin/install-codex-plugin" >"$tmp/success-output"
grep -Fxq 'plugin' "$tmp/success-args"
grep -Fxq 'add' "$tmp/success-args"
grep -Fxq 'product-os@localtest' "$tmp/success-args"
grep -Fq './plugins/product-os' "$success_marketplace"
test ! -e "$success_destination/marker"
test -f "$success_destination/.codex-plugin/plugin.json"
grep -Fq '+codex.' "$success_destination/.codex-plugin/plugin.json"

echo 'Product OS Codex plugin verification passed.'
