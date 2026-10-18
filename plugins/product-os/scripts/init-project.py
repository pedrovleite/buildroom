#!/usr/bin/env python3
"""Initialize only the durable, repository-local state required by Product OS."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


START = "<!-- product-os:global-plugin:start -->"
END = "<!-- product-os:global-plugin:end -->"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Initialize Product OS state in one target repository."
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
        plugin_root() / "skills" / "product-os" / "references" / "toolkit" / "codex"
        / "AGENTS.global-plugin.snippet"
    )
    try:
        content = snippet.read_text(encoding="utf-8").strip()
    except OSError as error:
        raise ValueError(f"Cannot read bundled Product OS routing snippet: {snippet}") from error
    if content.count(START) != 1 or content.count(END) != 1:
        raise ValueError("Bundled Product OS routing snippet has invalid markers.")
    return content + "\n"


def merge_agents(existing: str, block: str) -> str:
    starts = existing.count(START)
    ends = existing.count(END)
    if starts != ends or starts > 1:
        raise ValueError(
            "AGENTS.md has malformed Product OS markers. Repair or remove the marked block before retrying."
        )
    if starts == 0:
        separator = "" if not existing or existing.endswith("\n\n") else "\n"
        return existing + separator + block
    start = existing.index(START)
    end = existing.index(END, start) + len(END)
    suffix = existing[end:]
    if suffix.startswith("\n"):
        suffix = suffix[1:]
    return existing[:start] + block + suffix


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
