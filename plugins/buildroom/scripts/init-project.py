#!/usr/bin/env python3
"""Initialize only the durable, repository-local state required by Buildroom."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


START = "<!-- buildroom:global-plugin:start -->"
END = "<!-- buildroom:global-plugin:end -->"
LEGACY_START = "<!-- product-os:global-plugin:start -->"
LEGACY_END = "<!-- product-os:global-plugin:end -->"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Initialize Buildroom state in one target repository."
    )
    parser.add_argument("repository", help="Target repository directory")
    parser.add_argument(
        "--dry-run", action="store_true", help="Describe changes without writing files"
    )
    return parser.parse_args()


def plugin_root() -> Path:
    return Path(__file__).resolve().parents[1]


def managed_block() -> str:
    snippet = (
        plugin_root() / "skills" / "buildroom" / "references" / "toolkit" / "codex"
        / "AGENTS.global-plugin.snippet"
    )
    try:
        content = snippet.read_text(encoding="utf-8").strip()
    except OSError as error:
        raise ValueError(f"Cannot read bundled Buildroom routing snippet: {snippet}") from error
    if content.count(START) != 1 or content.count(END) != 1:
        raise ValueError("Bundled Buildroom routing snippet has invalid markers.")
    return content + "\n"


def marker_count(existing: str, start: str, end: str, label: str) -> int:
    starts = existing.count(start)
    ends = existing.count(end)
    if starts != ends or starts > 1:
        raise ValueError(
            f"AGENTS.md has malformed {label} markers. Repair or remove the marked block before retrying."
        )
    if starts and existing.index(start) > existing.index(end):
        raise ValueError(
            f"AGENTS.md has malformed {label} markers. Repair or remove the marked block before retrying."
        )
    return starts


def replace_marked_block(existing: str, start_marker: str, end_marker: str, block: str) -> str:
    start = existing.index(start_marker)
    end = existing.index(end_marker, start) + len(end_marker)
    suffix = existing[end:]
    if suffix.startswith("\n"):
        suffix = suffix[1:]
    return existing[:start] + block + suffix


def merge_agents(existing: str, block: str) -> str:
    current = marker_count(existing, START, END, "Buildroom")
    legacy = marker_count(existing, LEGACY_START, LEGACY_END, "legacy Product OS")
    if current and legacy:
        raise ValueError(
            "AGENTS.md has both Buildroom and legacy Product OS markers. Keep one marked block before retrying."
        )
    if not current and not legacy:
        separator = "" if not existing or existing.endswith("\n\n") else "\n"
        return existing + separator + block
    if current:
        return replace_marked_block(existing, START, END, block)
    return replace_marked_block(existing, LEGACY_START, LEGACY_END, block)


def write_if_missing(path: Path, content: str, dry_run: bool, changes: list[str]) -> None:
    if path.exists():
        changes.append(f"preserved {path}")
        return
    changes.append(f"created {path}")
    if not dry_run:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


def require_regular_file_or_missing(path: Path) -> None:
    if path.is_symlink() or (path.exists() and not path.is_file()):
        raise ValueError(f"Expected a regular file or no path at: {path}")


def require_directory_or_missing(path: Path) -> None:
    if path.is_symlink() or (path.exists() and not path.is_dir()):
        raise ValueError(f"Expected a directory or no path at: {path}")


def main() -> None:
    args = parse_args()
    repository = Path(args.repository).expanduser().resolve()
    if not repository.is_dir():
        raise SystemExit(f"Target repository is not a directory: {repository}")

    product = repository / "product"
    agents_path = repository / "AGENTS.md"
    require_regular_file_or_missing(agents_path)
    require_directory_or_missing(product)
    for directory in (product / "active", product / "archive", product / "memory"):
        require_directory_or_missing(directory)
    for memory_file in (product / "memory" / "index.md", product / "memory" / "decision-log.md"):
        require_regular_file_or_missing(memory_file)

    existing = agents_path.read_text(encoding="utf-8") if agents_path.exists() else ""
    merged = merge_agents(existing, managed_block())

    changes: list[str] = []
    for directory in (product / "active", product / "archive"):
        if directory.exists():
            changes.append(f"preserved {directory}")
        else:
            changes.append(f"created {directory}")
            if not args.dry_run:
                directory.mkdir(parents=True, exist_ok=True)

    write_if_missing(
        product / "memory" / "index.md",
        "# Product Memory Index\n\n## Decisions\n\n## Artefacts and relationships\n",
        args.dry_run,
        changes,
    )
    write_if_missing(
        product / "memory" / "decision-log.md",
        "# Product Decision Log\n\nRecord material decisions with links to their evidence and affected runs.\n",
        args.dry_run,
        changes,
    )

    if merged == existing:
        changes.append(f"preserved {agents_path}")
    else:
        changes.append(f"updated {agents_path}")
        if not args.dry_run:
            agents_path.write_text(merged, encoding="utf-8")

    for change in changes:
        print(change)
    if args.dry_run:
        print("dry-run: no files were written")


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(2)
