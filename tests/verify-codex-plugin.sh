#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
codex_root=${CODEX_HOME:-"$HOME/.codex"}
validator="$codex_root/skills/.system/plugin-creator/scripts/validate_plugin.py"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/buildroom-plugin-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

mkdir -p "$tmp/test-bin"
real_python=$(command -v python3)
real_uv=$(command -v uv || true)
printf '#!/usr/bin/env sh\nif [ "$1" = -c ] && [ "$2" = "import yaml" ] && [ "${TEST_PYTHON_TOO_OLD:-0}" = 1 ]; then exit 0; fi\nif [ "$1" = -c ] && [ "$2" = "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" ]; then [ "${TEST_PYTHON_TOO_OLD:-0}" = 0 ]; exit; fi\nexec "%s" "$@"\n' "$real_python" > "$tmp/test-bin/python3"
chmod +x "$tmp/test-bin/python3"
printf '#!/usr/bin/env sh\nif [ "$1" = run ] && [ "$2" = --with ] && [ "$3" = pyyaml ]; then\n  shift\n  exec "%s" run --offline "$@"\nfi\nexit 1\n' "$real_uv" > "$tmp/test-bin/uv"
chmod +x "$tmp/test-bin/uv"
PATH="$tmp/test-bin:$PATH"
export PATH

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
test -f "$tmp/plugin/skills/buildroom/references/toolkit/scripts/run-operations.py"
grep -Fq 'graphify extract . --code-only' "$tmp/plugin/skills/buildroom/SKILL.md"
grep -Fq 'graphify query' "$tmp/plugin/skills/buildroom/SKILL.md"
grep -Fq 'graphify update .' "$tmp/plugin/skills/buildroom/SKILL.md"
grep -Fq 'whether or not Buildroom has been initialized' "$tmp/plugin/skills/buildroom/SKILL.md"
grep -Fq 'bounded direct inspection' "$tmp/plugin/skills/buildroom/SKILL.md"
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
printf 'node_modules/\n# keep this comment\n' > "$target/.gitignore"
python3 "$tmp/plugin/scripts/init-project.py" "$target"
grep -Fq '# Existing repository instructions' "$target/AGENTS.md"
grep -Fq '<!-- buildroom:global-plugin:start -->' "$target/AGENTS.md"
grep -Fxq 'node_modules/' "$target/.gitignore"
grep -Fxq '# keep this comment' "$target/.gitignore"
grep -Fxq 'graphify-out/' "$target/.gitignore"
test ! -e "$target/graphify-out"
test -d "$target/product/active"
test -d "$target/product/archive"
test -f "$target/product/memory/index.md"
test -f "$target/product/memory/decision-log.md"
toolkit="$tmp/plugin/skills/buildroom/references/toolkit"
sh "$toolkit/bin/buildroom" start feature TOOLKIT-1 --project "$target"
sh "$toolkit/bin/buildroom" check TOOLKIT-1 --project "$target"
cp "$target/AGENTS.md" "$tmp/agents-before.md"
cp "$target/.gitignore" "$tmp/gitignore-before"
python3 "$tmp/plugin/scripts/init-project.py" "$target"
cmp "$tmp/agents-before.md" "$target/AGENTS.md"
cmp "$tmp/gitignore-before" "$target/.gitignore"

gitignore_existing="$tmp/gitignore-existing"
mkdir "$gitignore_existing"
printf 'graphify-out/\nkeep-me\n' > "$gitignore_existing/.gitignore"
python3 "$tmp/plugin/scripts/init-project.py" "$gitignore_existing" > "$tmp/gitignore-existing-output"
test "$(grep -Fc 'graphify-out/' "$gitignore_existing/.gitignore")" -eq 1
grep -Fxq 'keep-me' "$gitignore_existing/.gitignore"

gitignore_crlf="$tmp/gitignore-crlf"
mkdir "$gitignore_crlf"
printf 'first-line\r\nsecond-line\r\n' > "$gitignore_crlf/.gitignore"
python3 "$tmp/plugin/scripts/init-project.py" "$gitignore_crlf" > "$tmp/gitignore-crlf-output"
python3 -c 'import pathlib, sys; data = pathlib.Path(sys.argv[1]).read_bytes(); assert data.startswith(b"first-line\r\nsecond-line\r\n") and data.endswith(b"graphify-out/\n")' "$gitignore_crlf/.gitignore"

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

symlink_gitignore_target="$tmp/external-gitignore"
printf 'external-pattern/\n' > "$symlink_gitignore_target"
symlink_gitignore_repo="$tmp/symlink-gitignore-target"
mkdir "$symlink_gitignore_repo"
ln -s "$symlink_gitignore_target" "$symlink_gitignore_repo/.gitignore"
if python3 "$tmp/plugin/scripts/init-project.py" "$symlink_gitignore_repo" >"$tmp/symlink-gitignore-output" 2>&1; then
  echo 'Symbolic-link .gitignore should stop initialization.' >&2
  exit 1
fi
grep -Fq 'Expected a regular file or no path' "$tmp/symlink-gitignore-output"
grep -Fxq 'external-pattern/' "$symlink_gitignore_target"
test ! -e "$symlink_gitignore_repo/product"

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

BUILDROOM_PLUGIN_PARENT="$tmp/dry-run-plugins" BUILDROOM_GRAPHIFY_COMMAND="$tmp/not-installed/graphify" BUILDROOM_UV_COMMAND=missing-uv BUILDROOM_PIPX_COMMAND=missing-pipx "$root/bin/install-codex-plugin" --dry-run >"$tmp/graphify-dry-run-output"
grep -Fq 'Graphify is missing and prerequisites are incomplete' "$tmp/graphify-dry-run-output"
test ! -e "$tmp/not-installed"
test ! -e "$tmp/dry-run-plugins"

graphify_register_log="$tmp/graphify-register-args"
mkdir -p "$tmp/bin"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$@" > "%s"\n' "$graphify_register_log" > "$tmp/bin/graphify-installed"
chmod +x "$tmp/bin/graphify-installed"
BUILDROOM_GRAPHIFY_COMMAND="$tmp/bin/graphify-installed" "$root/bin/install-codex-plugin" --dry-run >"$tmp/graphify-present-dry-run-output"
grep -Fq 'Graphify is already installed; would ensure its Codex skill registration' "$tmp/graphify-present-dry-run-output"
test ! -e "$graphify_register_log"

existing_graphify_parent="$tmp/existing-graphify-plugins"
mkdir -p "$existing_graphify_parent/buildroom"
printf 'previous plugin source\n' > "$existing_graphify_parent/buildroom/marker"
existing_graphify_marketplace="$tmp/existing-graphify-marketplace.json"
printf '{"name":"existinggraphify","plugins":[]}\n' > "$existing_graphify_marketplace"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$@" > "%s"\n' "$tmp/existing-graphify-codex-args" > "$tmp/bin/existing-graphify-codex"
chmod +x "$tmp/bin/existing-graphify-codex"
if ! BUILDROOM_PLUGIN_PARENT="$existing_graphify_parent" BUILDROOM_MARKETPLACE_PATH="$existing_graphify_marketplace" BUILDROOM_CODEX_COMMAND="$tmp/bin/existing-graphify-codex" BUILDROOM_GRAPHIFY_COMMAND="$tmp/bin/graphify-installed" BUILDROOM_UV_COMMAND=missing-uv BUILDROOM_PIPX_COMMAND=missing-pipx "$root/bin/install-codex-plugin" >"$tmp/existing-graphify-output" 2>&1; then
  cat "$tmp/existing-graphify-output" >&2
  exit 1
fi
grep -Fq 'preserving its version' "$tmp/existing-graphify-output"
grep -Fxq 'install' "$graphify_register_log"
grep -Fxq -- '--platform' "$graphify_register_log"
grep -Fxq 'codex' "$graphify_register_log"
test -f "$existing_graphify_parent/buildroom/.codex-plugin/plugin.json"

prereq_parent="$tmp/prereq-plugins"
mkdir -p "$prereq_parent/buildroom"
printf 'previous plugin source\n' > "$prereq_parent/buildroom/marker"
prereq_marketplace="$tmp/prereq-marketplace.json"
printf '{"name":"prereq","plugins":[]}\n' > "$prereq_marketplace"
if BUILDROOM_PLUGIN_PARENT="$prereq_parent" BUILDROOM_MARKETPLACE_PATH="$prereq_marketplace" BUILDROOM_GRAPHIFY_COMMAND="$tmp/missing-graphify" BUILDROOM_UV_COMMAND=missing-uv BUILDROOM_PIPX_COMMAND=missing-pipx "$root/bin/install-codex-plugin" >"$tmp/graphify-prereq-output" 2>&1; then
  echo 'Missing Graphify and package managers should stop installation.' >&2
  exit 1
fi
grep -Fq 'Python 3.10+ and either uv or pipx' "$tmp/graphify-prereq-output"
grep -Fq 'previous plugin source' "$prereq_parent/buildroom/marker"

old_python_parent="$tmp/old-python-plugins"
mkdir -p "$old_python_parent/buildroom"
printf 'previous plugin source\n' > "$old_python_parent/buildroom/marker"
old_python_marketplace="$tmp/old-python-marketplace.json"
printf '{"name":"oldpython","plugins":[]}\n' > "$old_python_marketplace"
old_python_codex_home="$tmp/old-python-codex-home"
old_python_plugin_tools="$old_python_codex_home/skills/.system/plugin-creator/scripts"
mkdir -p "$old_python_plugin_tools"
for helper in create_basic_plugin.py validate_plugin.py read_marketplace_name.py update_plugin_cachebuster.py; do
  : > "$old_python_plugin_tools/$helper"
done
printf '#!/usr/bin/env sh\nif [ "$1" = environment ]; then exit 1; fi\nif [ "$1" = install ]; then printf "%%s\\n" "$@" > "%s"; exit 99; fi\nexit 1\n' "$tmp/old-python-pipx-args" > "$tmp/bin/old-python-pipx"
chmod +x "$tmp/bin/old-python-pipx"
if TEST_PYTHON_TOO_OLD=1 CODEX_HOME="$old_python_codex_home" BUILDROOM_PLUGIN_PARENT="$old_python_parent" BUILDROOM_MARKETPLACE_PATH="$old_python_marketplace" BUILDROOM_GRAPHIFY_COMMAND="$tmp/missing-old-python-graphify" BUILDROOM_UV_COMMAND=missing-uv BUILDROOM_PIPX_COMMAND="$tmp/bin/old-python-pipx" "$root/bin/install-codex-plugin" >"$tmp/old-python-output" 2>&1; then
  echo 'An incompatible Python should stop Graphify installation when pipx is used.' >&2
  exit 1
fi
if ! grep -Fq 'Graphify requires Python 3.10 or newer' "$tmp/old-python-output"; then
  cat "$tmp/old-python-output" >&2
  exit 1
fi
test ! -e "$tmp/old-python-pipx-args"
grep -Fq 'previous plugin source' "$old_python_parent/buildroom/marker"

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
if BUILDROOM_PLUGIN_PARENT="$rollback_parent" BUILDROOM_MARKETPLACE_PATH="$rollback_marketplace" BUILDROOM_CODEX_COMMAND="$tmp/bin/fail-codex" BUILDROOM_GRAPHIFY_COMMAND="$tmp/bin/graphify-installed" "$root/bin/install-codex-plugin" >"$tmp/rollback-output" 2>&1; then
  echo 'A failed Codex installation should fail the installer.' >&2
  exit 1
fi
if ! grep -Fq 'restored the previous Buildroom plugin source' "$tmp/rollback-output"; then
  cat "$tmp/rollback-output" >&2
  exit 1
fi
grep -Fq 'previous plugin source' "$rollback_destination/marker"

success_parent="$tmp/success-plugins"
success_destination="$success_parent/buildroom"
success_marketplace="$tmp/success-marketplace.json"
mkdir -p "$success_destination"
printf 'previous plugin source\n' > "$success_destination/marker"
printf '{"name":"localtest","plugins":[]}\n' > "$success_marketplace"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$@" > "%s"\n' "$tmp/success-args" > "$tmp/bin/succeed-codex"
chmod +x "$tmp/bin/succeed-codex"
mkdir "$tmp/installed-graphify-bin"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$@" > "%s"\n' "$tmp/graphify-install-args" > "$tmp/bin/graphify-register"
chmod +x "$tmp/bin/graphify-register"
printf '#!/usr/bin/env sh\nif [ "$1" = run ]; then shift; exec "%s" run --offline "$@"; fi\nif [ "$1" = tool ] && [ "$2" = dir ]; then printf "%%s\\n" "%s"; exit 0; fi\nif [ "$1" = tool ] && [ "$2" = install ]; then printf "%%s\\n" "$@" > "%s"; cp "%s" "%s/graphify"; chmod +x "%s/graphify"; exit 0; fi\nexit 1\n' "$real_uv" "$tmp/installed-graphify-bin" "$tmp/uv-install-args" "$tmp/bin/graphify-register" "$tmp/installed-graphify-bin" "$tmp/installed-graphify-bin" > "$tmp/bin/fake-uv"
chmod +x "$tmp/bin/fake-uv"
BUILDROOM_PLUGIN_PARENT="$success_parent" BUILDROOM_MARKETPLACE_PATH="$success_marketplace" BUILDROOM_CODEX_COMMAND="$tmp/bin/succeed-codex" BUILDROOM_GRAPHIFY_COMMAND="$tmp/installed-graphify-bin/graphify" BUILDROOM_UV_COMMAND="$tmp/bin/fake-uv" BUILDROOM_PIPX_COMMAND=missing-pipx "$root/bin/install-codex-plugin" >"$tmp/success-output"
grep -Fxq 'tool' "$tmp/uv-install-args"
grep -Fxq 'install' "$tmp/uv-install-args"
grep -Fxq 'graphifyy' "$tmp/uv-install-args"
grep -Fxq 'install' "$tmp/graphify-install-args"
grep -Fxq -- '--platform' "$tmp/graphify-install-args"
grep -Fxq 'codex' "$tmp/graphify-install-args"

pipx_parent="$tmp/pipx-plugins"
mkdir -p "$pipx_parent/buildroom"
printf 'previous plugin source\n' > "$pipx_parent/buildroom/marker"
pipx_marketplace="$tmp/pipx-marketplace.json"
printf '{"name":"pipxtest","plugins":[]}\n' > "$pipx_marketplace"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$@" > "%s"\nexit 1\n' "$tmp/pipx-install-args" > "$tmp/bin/fail-pipx"
chmod +x "$tmp/bin/fail-pipx"
if BUILDROOM_PLUGIN_PARENT="$pipx_parent" BUILDROOM_MARKETPLACE_PATH="$pipx_marketplace" BUILDROOM_GRAPHIFY_COMMAND="$tmp/missing-pipx-graphify" BUILDROOM_UV_COMMAND=missing-uv BUILDROOM_PIPX_COMMAND="$tmp/bin/fail-pipx" "$root/bin/install-codex-plugin" >"$tmp/pipx-output" 2>&1; then
  echo 'A failed pipx Graphify installation should stop Buildroom installation.' >&2
  exit 1
fi
grep -Fxq 'install' "$tmp/pipx-install-args"
grep -Fxq 'graphifyy' "$tmp/pipx-install-args"
grep -Fq 'Graphify installation with pipx failed' "$tmp/pipx-output"
grep -Fq 'previous plugin source' "$pipx_parent/buildroom/marker"

fallback_parent="$tmp/fallback-plugins"
mkdir -p "$fallback_parent/buildroom" "$tmp/fallback-pipx-bin"
printf 'previous plugin source\n' > "$fallback_parent/buildroom/marker"
fallback_marketplace="$tmp/fallback-marketplace.json"
printf '{"name":"fallbacktest","plugins":[]}\n' > "$fallback_marketplace"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$@" > "%s"\n' "$tmp/fallback-codex-args" > "$tmp/bin/fallback-codex"
chmod +x "$tmp/bin/fallback-codex"
printf '#!/usr/bin/env sh\nif [ "$1" = run ]; then shift; exec "%s" run --offline "$@"; fi\nif [ "$1" = tool ] && [ "$2" = install ]; then exit 1; fi\nexit 1\n' "$real_uv" > "$tmp/bin/fail-uv-install"
chmod +x "$tmp/bin/fail-uv-install"
printf '#!/usr/bin/env sh\nif [ "$1" = environment ]; then printf "%%s\\n" "%s"; exit 0; fi\nif [ "$1" = install ]; then cp "%s" "%s/graphify"; chmod +x "%s/graphify"; printf "%%s\\n" "$@" > "%s"; exit 0; fi\nexit 1\n' "$tmp/fallback-pipx-bin" "$tmp/bin/graphify-register" "$tmp/fallback-pipx-bin" "$tmp/fallback-pipx-bin" "$tmp/fallback-pipx-args" > "$tmp/bin/succeed-pipx"
chmod +x "$tmp/bin/succeed-pipx"
if ! BUILDROOM_PLUGIN_PARENT="$fallback_parent" BUILDROOM_MARKETPLACE_PATH="$fallback_marketplace" BUILDROOM_CODEX_COMMAND="$tmp/bin/fallback-codex" BUILDROOM_GRAPHIFY_COMMAND="$tmp/missing-fallback-graphify" BUILDROOM_UV_COMMAND="$tmp/bin/fail-uv-install" BUILDROOM_PIPX_COMMAND="$tmp/bin/succeed-pipx" "$root/bin/install-codex-plugin" >"$tmp/fallback-output" 2>&1; then
  cat "$tmp/fallback-output" >&2
  exit 1
fi
grep -Fq 'trying the available pipx fallback' "$tmp/fallback-output"
grep -Fxq 'install' "$tmp/fallback-pipx-args"
grep -Fxq 'graphifyy' "$tmp/fallback-pipx-args"
grep -Fxq 'install' "$tmp/graphify-register-args"
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
BUILDROOM_PLUGIN_PARENT="$legacy_parent" BUILDROOM_MARKETPLACE_PATH="$legacy_marketplace" BUILDROOM_CODEX_COMMAND="$tmp/bin/retire-legacy-codex" BUILDROOM_GRAPHIFY_COMMAND="$tmp/bin/graphify-register" "$root/bin/install-codex-plugin" >"$tmp/legacy-install-output"
grep -Fq 'buildroom@legacytest' "$tmp/legacy-args"
grep -Fq 'product-os@legacytest' "$tmp/legacy-args"
test ! -e "$legacy_destination"
test -f "$legacy_parent/buildroom/.codex-plugin/plugin.json"

registration_parent="$tmp/registration-plugins"
mkdir -p "$registration_parent/buildroom"
printf 'previous plugin source\n' > "$registration_parent/buildroom/marker"
registration_marketplace="$tmp/registration-marketplace.json"
printf '{"name":"registration","plugins":[]}\n' > "$registration_marketplace"
printf '#!/usr/bin/env sh\nexit 1\n' > "$tmp/bin/fail-graphify"
chmod +x "$tmp/bin/fail-graphify"
if BUILDROOM_PLUGIN_PARENT="$registration_parent" BUILDROOM_MARKETPLACE_PATH="$registration_marketplace" BUILDROOM_GRAPHIFY_COMMAND="$tmp/bin/fail-graphify" "$root/bin/install-codex-plugin" >"$tmp/graphify-registration-output" 2>&1; then
  echo 'A failed Graphify Codex registration should stop installation.' >&2
  exit 1
fi
grep -Fq 'Graphify Codex skill registration failed' "$tmp/graphify-registration-output"
grep -Fq 'previous plugin source' "$registration_parent/buildroom/marker"

grep -Fq 'uv tool install --python' "$root/README.md"
grep -Fq 'pipx install graphifyy' "$root/README.md"
grep -Fq 'graphify install --platform codex' "$root/README.md"
grep -Fq 'graphify extract . --code-only' "$root/README.md"
grep -Fq 'graphify update .' "$root/README.md"
grep -Fq 'Required codebase graph' "$root/docs/run-operations.md"
grep -Fq 'graphify update .' "$root/docs/run-operations.md"

echo 'Buildroom Codex plugin verification passed.'
