#!/usr/bin/env python3
"""Create and structurally inspect one durable Buildroom run."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import sys
import tempfile
from dataclasses import dataclass
from datetime import date
from pathlib import Path


WORK_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")
APPROVAL_STATUS = re.compile(r"^awaiting(?:-[A-Za-z0-9_]+)*-approval$")
REQUIRED_STATE_KEYS = (
    "id", "workflow", "status", "owner_role", "risk_class", "route",
    "decision_authority", "updated", "related",
)
REQUIRED_SECTIONS = (
    "Objective", "Immutable inputs", "Entry criteria", "Current output",
    "Exit criteria", "Evidence links", "Decisions in force",
    "Open questions and blockers", "Next action", "Close-out and archive", "Run trace",
)
HANDOFF_REQUIRED_KEYS = (
    "work_id", "from_role", "to_role", "status", "risk_class",
    "decision_authority", "pause_reason", "resume_condition", "created",
    "required_inputs", "related",
)
HANDOFF_EMPTY_ALLOWED = {"pause_reason", "resume_condition"}
HANDOFF_REQUIRED_SECTIONS = (
    "Requested outcome", "Entry criteria", "Completed work", "Exit criteria",
    "Inputs to read", "Evidence links", "Decisions already made",
    "Assumptions, risks, and open questions", "Pause and resume condition",
    "Acceptance checks for recipient", "Recipient acknowledgement",
)


@dataclass(frozen=True)
class Route:
    slug: str
    owner: str
    status: str
    route: str
    next_action: str


ROUTES = {
    "research-to-prd": Route("research-to-prd", "Noether — Researcher", "draft", "standard", "Frame the decision and record the target user, problem, and desired outcome."),
    "prd-to-tech-spec": Route("prd-to-tech-spec", "Turing — Architect", "draft", "standard", "Perform repository reconnaissance and record the evidence before choosing a design."),
    "feature-delivery": Route("feature-delivery", "Johnson — Lead Engineer", "draft", "standard", "Confirm the approved inputs, entry criteria, implementation readiness, and integration plan."),
    "bug-fix": Route("bug-fix", "Feynman — QA Reviewer", "triage", "standard", "Attempt reproduction and record the confirming or missing evidence."),
    "no-bullshit-bug-fix": Route("no-bullshit-bug-fix", "Johnson — Lead Engineer", "preflight", "express", "Record every eligibility check and run the pre-change regression check."),
}

ALLOWED_HANDOFFS = {
    ("Noether — Researcher", "Curie — Product Manager"),
    ("Curie — Product Manager", "Turing — Architect"),
    ("Turing — Architect", "Johnson — Lead Engineer"),
    ("Feynman — QA Reviewer", "Johnson — Lead Engineer"),
    ("Johnson — Lead Engineer", "Lovelace — Frontend Engineer"),
    ("Johnson — Lead Engineer", "Euler — Backend Engineer"),
    ("Lovelace — Frontend Engineer", "Johnson — Lead Engineer"),
    ("Euler — Backend Engineer", "Johnson — Lead Engineer"),
    ("Johnson — Lead Engineer", "Feynman — QA Reviewer"),
}
SPECIALISTS = {"Lovelace — Frontend Engineer", "Euler — Backend Engineer"}


class InvocationError(ValueError):
    """An invalid or unsafe command invocation."""


def normalise(value: str) -> str:
    return " ".join(value.lower().split())


def reject_symlink(path: Path, description: str) -> None:
    if path.is_symlink():
        raise InvocationError(f"Unsafe symbolic link for {description}: {path}")


def require_directory(path: Path, description: str) -> None:
    reject_symlink(path, description)
    if not path.is_dir():
        raise InvocationError(f"Expected directory for {description}: {path}")


def require_regular_file(path: Path, description: str) -> None:
    reject_symlink(path, description)
    if not path.is_file():
        raise InvocationError(f"Expected regular file for {description}: {path}")


def within(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
    except ValueError:
        return False
    return True


def absolute_path(value: str) -> Path:
    path = Path(value).expanduser()
    return path if path.is_absolute() else Path.cwd() / path


def initialized_project(value: str) -> Path:
    project = absolute_path(value)
    require_directory(project, "target project")
    project = project.resolve()
    require_regular_file(project / "AGENTS.md", "AGENTS.md")
    product = project / "product"
    require_directory(product, "product state")
    for name in ("active", "archive", "memory"):
        require_directory(product / name, f"product/{name}")
    for name in ("index.md", "decision-log.md"):
        require_regular_file(product / "memory" / name, f"product/memory/{name}")
    return project


def parse_frontmatter(path: Path) -> tuple[dict[str, str], str]:
    try:
        content = path.read_text(encoding="utf-8")
    except OSError as error:
        raise InvocationError(f"Cannot read {path}: {error}") from error
    if not content.startswith("---\n"):
        raise InvocationError(f"Missing frontmatter in {path}")
    end = content.find("\n---\n", 4)
    if end < 0:
        raise InvocationError(f"Unclosed frontmatter in {path}")
    fields: dict[str, str] = {}
    for line in content[4:end].splitlines():
        if not line or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            raise InvocationError(f"Unsupported frontmatter in {path}: {line}")
        key, value = line.split(":", 1)
        key, value = key.strip(), value.strip()
        if not re.fullmatch(r"[A-Za-z0-9_-]+", key):
            raise InvocationError(f"Unsupported frontmatter key in {path}: {key}")
        if (value.startswith("'") and value.endswith("'")) or (value.startswith('"') and value.endswith('"')):
            value = value[1:-1]
        elif value.startswith("[") and value.endswith("]"):
            pass
        elif value.startswith(("[", "'", '"')) or value.endswith(("]", "'", '"')):
            raise InvocationError(f"Unsupported frontmatter value in {path}: {key}")
        fields[key] = value
    return fields, content[end + 5 :]


def registry_workflow(package_root: Path, requested: str) -> Route:
    registry = package_root / "registry.tsv"
    require_regular_file(registry, "Buildroom registry")
    target = normalise(requested)
    matches: list[Route] = []
    try:
        rows = registry.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise InvocationError(f"Cannot read Buildroom registry: {error}") from error
    for row in rows[1:]:
        fields = row.split("\t")
        if len(fields) != 5 or fields[0] != "workflow":
            continue
        _, canonical, aliases, path, _ = fields
        slug = Path(path).stem
        candidates = [canonical, slug, f"workflow.{slug}", *aliases.split(",")]
        if any(normalise(candidate) == target for candidate in candidates):
            route = ROUTES.get(slug)
            if route:
                matches.append(route)
    if not matches:
        raise InvocationError(f"Unknown Buildroom workflow: {requested}. Use `sh buildroom/bin/buildroom list` to see workflows.")
    if len(matches) != 1:
        raise InvocationError(f"Ambiguous Buildroom workflow: {requested}. Repair registry aliases.")
    return matches[0]


def render_initial_state(template: Path, work_id: str, route: Route) -> str:
    require_regular_file(template, "workflow-state template")
    try:
        content = template.read_text(encoding="utf-8")
    except OSError as error:
        raise InvocationError(f"Cannot read workflow-state template: {error}") from error
    substitutions = {
        "id: WORK-000": f"id: {work_id}",
        "workflow: research-to-prd": f"workflow: {route.slug}",
        "status: draft": f"status: {route.status}",
        "owner_role: Researcher": f"owner_role: {route.owner}",
        "route: standard": f"route: {route.route}",
        "updated: YYYY-MM-DD": f"updated: {date.today().isoformat()}",
    }
    for old, new in substitutions.items():
        if old not in content:
            raise InvocationError(f"Unexpected workflow-state template; missing {old!r}")
        content = content.replace(old, new, 1)
    marker = "## Next action\n"
    if marker not in content:
        raise InvocationError("Unexpected workflow-state template; missing Next action section")
    content = content.replace(marker, f"{marker}\n{route.next_action}\n", 1)
    if route.route == "express":
        decision_marker = "## Decisions in force\n"
        if decision_marker not in content:
            raise InvocationError("Unexpected workflow-state template; missing Decisions in force section")
        content = content.replace(
            decision_marker,
            f"{decision_marker}\nExpress invocation approval was confirmed with --approve-express; eligibility and regression checks remain required.\n",
            1,
        )
    return content


def start(args: argparse.Namespace, package_root: Path) -> int:
    if not WORK_ID.fullmatch(args.work_id):
        raise InvocationError("Invalid work ID. Use 1-64 ASCII letters, digits, dots, underscores, or hyphens, starting with a letter or digit.")
    route = registry_workflow(package_root, args.workflow)
    if route.route == "express" and not args.approve_express:
        raise InvocationError("No-Bullshit Bug Fix requires --approve-express before a run is created.")
    project = initialized_project(args.project)
    active = project / "product" / "active"
    destination = active / args.work_id
    if destination.exists() or destination.is_symlink():
        raise InvocationError(f"Run already exists or has an unsafe destination: {destination}. Choose a new work ID.")
    state = render_initial_state(package_root / "templates" / "workflow-state.md", args.work_id, route)
    claimed = False
    temporary: Path | None = None
    try:
        try:
            destination.mkdir(mode=0o700)
        except FileExistsError as error:
            raise InvocationError(f"Run already exists or has an unsafe destination: {destination}. Choose a new work ID.") from error
        claimed = True
        descriptor, temporary_name = tempfile.mkstemp(prefix=".workflow-state-", dir=destination)
        temporary = Path(temporary_name)
        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            output.write(state)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, destination / "workflow-state.md")
        temporary = None
    except BaseException:
        if claimed:
            shutil.rmtree(destination, ignore_errors=True)
        raise
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    print(f"READY: created run {args.work_id} for {route.slug}.")
    print(f"Next action: {route.next_action}")
    return 0


def sections(body: str) -> dict[str, str]:
    found = list(re.finditer(r"(?m)^## ([^\n]+)\s*$", body))
    return {match.group(1): body[match.end() : found[index + 1].start() if index + 1 < len(found) else len(body)] for index, match in enumerate(found)}


def markdown_links(content: str) -> list[str]:
    targets: list[str] = []
    inline = re.compile(r"!?\[[^\]]*\]\(\s*(?:<([^>]+)>|([^\s)]+))(?:\s+(?:\"[^\"]*\"|'[^']*'|\([^)]*\)))?\s*\)")
    reference = re.compile(r"(?m)^\s*\[[^\]]+\]:\s*(?:<([^>]+)>|(\S+))(?:\s+.*)?$")
    for match in [*inline.finditer(content), *reference.finditer(content)]:
        targets.append(match.group(1) or match.group(2))
    return targets


def readable_relative_link(target: str, source: Path, project: Path) -> bool:
    target = target.strip()
    if not target or target.startswith(("#", "//")) or re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", target):
        return True
    target = target.split("#", 1)[0].strip()
    candidate = source.parent / target
    try:
        resolved = candidate.resolve(strict=True)
    except OSError:
        return False
    return within(resolved, project) and not candidate.is_symlink() and resolved.is_file()


def handoff_issues(handoff: Path, project: Path) -> tuple[dict[str, str], list[str]]:
    try:
        fields, body = parse_frontmatter(handoff)
    except InvocationError as error:
        return {}, [str(error)]
    issues = [
        f"missing required frontmatter `{key}`"
        for key in HANDOFF_REQUIRED_KEYS
        if key not in fields or (key not in HANDOFF_EMPTY_ALLOWED and not fields[key])
    ]
    handoff_sections = sections(body)
    for heading in HANDOFF_REQUIRED_SECTIONS:
        if heading not in handoff_sections:
            issues.append(f"missing required section `{heading}`")
        elif not handoff_sections[heading].strip():
            issues.append(f"required section `{heading}` is empty")
    issues.extend(f"local link `{target}` is unreadable or escapes the project" for target in markdown_links(body) if not readable_relative_link(target, handoff, project))
    if not re.search(r"(?mi)^- \[x\] Accepted(?:,|$)", body):
        issues.append("recipient acknowledgement is not accepted")
    return fields, issues


def accepted_handoffs(run: Path, project: Path) -> list[dict[str, str]]:
    accepted: list[dict[str, str]] = []
    for handoff in sorted(run.glob("handoff-*.md")):
        if handoff.is_symlink() or not handoff.is_file():
            continue
        fields, issues = handoff_issues(handoff, project)
        if not issues and fields.get("status") == "accepted":
            accepted.append(fields)
    return accepted


def has_accepted_handoff(handoffs: list[dict[str, str]], work_id: str, sender: str | None, recipient: str) -> bool:
    return any(
        handoff.get("work_id") == work_id
        and handoff.get("to_role") == recipient
        and (sender is None or handoff.get("from_role") == sender)
        for handoff in handoffs
    )


def check(args: argparse.Namespace, package_root: Path) -> int:
    if not WORK_ID.fullmatch(args.work_id):
        raise InvocationError("Invalid work ID. Use the exact run folder name created by start.")
    project = initialized_project(args.project)
    active = project / "product" / "active"
    run = active / args.work_id
    require_directory(run, f"run {args.work_id}")
    if run.parent.resolve() != active.resolve() or not within(run.resolve(), active.resolve()):
        raise InvocationError(f"Unsafe run path: {run}")
    state_path = run / "workflow-state.md"
    if not state_path.exists():
        print(f"BLOCKER: workflow-state.md is missing. Next action: create {state_path} from the workflow-state template.")
        return 1
    require_regular_file(state_path, "workflow state")
    fields, body = parse_frontmatter(state_path)
    blockers: list[tuple[str, str]] = []
    warnings: list[str] = []
    for key in REQUIRED_STATE_KEYS:
        if not fields.get(key):
            blockers.append((f"workflow-state.md is missing required frontmatter `{key}`", f"add `{key}` to {state_path}"))
    if fields.get("id") and fields["id"] != args.work_id:
        blockers.append(("run folder and workflow-state.md IDs disagree", f"set `id: {args.work_id}` in {state_path}"))
    route: Route | None = None
    workflow = fields.get("workflow")
    if workflow:
        try:
            route = registry_workflow(package_root, workflow)
        except InvocationError:
            blockers.append((f"workflow-state.md names unknown workflow `{workflow}`", "set `workflow` to a registered workflow ID"))
    state_sections = sections(body)
    for heading in REQUIRED_SECTIONS:
        if heading not in state_sections:
            blockers.append((f"workflow-state.md is missing required section `{heading}`", f"add `## {heading}` to {state_path}"))
    for target in markdown_links(body):
        if not readable_relative_link(target, state_path, project):
            blockers.append((f"Local link `{target}` is unreadable or escapes the project", f"replace it with a readable file inside {project}"))
    evidence = state_sections.get("Evidence links", "")
    for handoff in sorted(run.glob("handoff-*.md")):
        if handoff.is_symlink() or not handoff.is_file():
            continue
        handoff_fields, issues = handoff_issues(handoff, project)
        if handoff_fields.get("status") == "accepted":
            for issue in issues:
                blockers.append((f"accepted hand-off `{handoff.name}` {issue}", f"complete {handoff}"))
    owner = fields.get("owner_role", "")
    accepted = accepted_handoffs(run, project)
    for handoff in accepted:
        sender, recipient = handoff.get("from_role", ""), handoff.get("to_role", "")
        if route and route.route == "express":
            blockers.append((f"express route must not accept hand-offs ({sender} to {recipient})", "remove the hand-off and keep Johnson as the sole owner"))
        elif (sender, recipient) not in ALLOWED_HANDOFFS:
            blockers.append((f"accepted hand-off `{sender}` to `{recipient}` is not an allowed owner transition", "return the work to its allowed owner before creating another accepted hand-off"))
    if route and fields.get("route") and fields["route"] != route.route:
        blockers.append((f"workflow `{route.slug}` requires route `{route.route}`, not `{fields['route']}`", f"set `route: {route.route}` in {state_path}"))
    if route and owner and owner != route.owner and not has_accepted_handoff(accepted, args.work_id, None, owner):
        blockers.append((f"owner `{owner}` has no accepted matching hand-off", f"add an accepted hand-off to {run} for {owner}"))
    pending_specialists = [
        specialist for specialist in SPECIALISTS
        if has_accepted_handoff(accepted, args.work_id, "Johnson — Lead Engineer", specialist)
        and not has_accepted_handoff(accepted, args.work_id, specialist, "Johnson — Lead Engineer")
    ]
    if len(pending_specialists) > 1:
        blockers.append(("more than one specialist has an unreturned Johnson hand-off", "wait for Johnson to accept and integrate one specialist return before delegating the next slice"))
    if owner not in SPECIALISTS:
        for specialist in pending_specialists:
            blockers.append((f"specialist `{specialist}` has no accepted return to Johnson", f"add an accepted {specialist}-to-Johnson hand-off before integration or QA"))
    if owner == "Feynman — QA Reviewer" and not has_accepted_handoff(accepted, args.work_id, "Johnson — Lead Engineer", owner):
        blockers.append(("Feynman may receive engineering work only from Johnson", f"add an accepted Johnson-to-Feynman hand-off to {run}"))
    status = fields.get("status", "")
    decisions = state_sections.get("Decisions in force", "")
    if APPROVAL_STATUS.fullmatch(status):
        if "human decision required" not in decisions.lower():
            blockers.append((f"status `{status}` has no explicit human decision required record", f"record `human decision required` in Decisions in force in {state_path}"))
        blockers.append((f"status `{status}` awaits a human approval", f"record the named human decision in {state_path} before continuing"))
    elif "human decision required" in decisions.lower():
        warnings.append("a human decision is required; this check does not grant it")
    if not evidence.strip():
        warnings.append("Evidence links is empty")
    if not state_sections.get("Current output", "").strip():
        warnings.append("Current output is empty")
    if status == "draft" and "TODO" in body.upper():
        warnings.append("draft state contains placeholders")
    for issue, action in blockers:
        print(f"BLOCKER: {issue}. Next action: {action}")
    for warning in warnings:
        print(f"WARNING: {warning}.")
    if blockers:
        return 1
    print(f"READY: run {args.work_id} is structurally ready for {owner}.")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-root", required=True, type=Path)
    commands = parser.add_subparsers(dest="command", required=True)
    start_parser = commands.add_parser("start")
    start_parser.add_argument("workflow")
    start_parser.add_argument("work_id")
    start_parser.add_argument("--project", default=".")
    start_parser.add_argument("--approve-express", action="store_true")
    check_parser = commands.add_parser("check")
    check_parser.add_argument("work_id")
    check_parser.add_argument("--project", default=".")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    package_root = args.package_root.expanduser().resolve()
    require_directory(package_root, "Buildroom package root")
    return start(args, package_root) if args.command == "start" else check(args, package_root)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except InvocationError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(2)
