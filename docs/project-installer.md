# Project-local installer

Buildroom's Node.js installer prepares one target repository for Codex, GitHub Copilot CLI, or Claude Code. It is distributed in the Buildroom Git checkout; v1 is not published to npm. Node.js 20+ and an already-installed, authenticated provider CLI/client are required. The installer does not install provider clients or change their global settings.

## Install

```sh
git clone https://github.com/pedrovleite/buildroom.git
cd buildroom
node bin/buildroom-install.mjs install --provider codex --project /path/to/project
```

The provider is required. Supported values are:

| Provider value | Host | Project skill | Role profiles | Project instructions | Graphify registration |
|---|---|---|---|---|---|
| `codex` | Codex | `.agents/skills/buildroom/` | `.codex/agents/` | `AGENTS.md` | `graphify codex install --project` (`.codex/skills/graphify/`) |
| `copilot` | GitHub Copilot CLI | `.github/skills/buildroom/` | `.github/agents/*.agent.md` | `AGENTS.md` | `graphify copilot install --project` (`.copilot/skills/graphify/`) |
| `claude-code` | Claude Code | `.claude/skills/buildroom/` | `.claude/agents/` | `CLAUDE.md` plus an `AGENTS.md` bridge for Buildroom's shared run helper | `graphify claude install --project` (`.claude/skills/graphify/`) |

Copilot means the Copilot CLI in v1, not VS Code Copilot Chat. V1 supports one selected provider per target repository; uninstall that provider before switching. Provider role profiles are adapters to the canonical Buildroom role cards; delegation capabilities and behavior vary by host.

## What is installed

- Shared, versioned Buildroom sources under `.buildroom/`: roles, workflows, templates, discovery metadata, orchestration instructions, and local helper commands.
- A native Buildroom Master skill and nine lightweight role-agent profiles for the selected provider, including conditional Hypatia (product design) and Shannon (security/privacy review) specialists.
- A marked routing block in `AGENTS.md` (Codex/Copilot); Claude Code gets both `CLAUDE.md` and an `AGENTS.md` bridge because the shared run helper validates `AGENTS.md`. Existing surrounding instructions are preserved.
- Missing `product/active`, `product/archive`, and `product/memory` scaffolding, without replacing existing memory or runs.
- Project-local Graphify registration for the selected provider.

If the Graphify CLI is already installed, its version is preserved. If absent, the installer uses `uv tool install --python '>=3.10' graphifyy` or `pipx install graphifyy`; Python 3.10+ and one supported package manager are required. Graphify remains a separate Python tool. The installer registers only the selected project/provider integration; Graphify may also add a small host instruction/settings registration, which is shown in the dry-run and remains Graphify-owned.

## Preview, update, and remove

Preview a full plan without writing files, installing packages, or registering Graphify:

```sh
node bin/buildroom-install.mjs install --provider copilot --project /path/to/project --dry-run
```

Repeat the install command after pulling an updated Buildroom checkout. Unchanged managed files are refreshed; locally modified managed files cause a conflict instead of being overwritten. Put project-specific additions in `.buildroom/custom/skills/`, `.buildroom/custom/agents/`, or `.buildroom/custom/workflows/`.

Remove the selected project installation:

```sh
node bin/buildroom-install.mjs uninstall --project /path/to/project
```

Uninstall removes only unchanged Buildroom-managed files and its intact marked instruction block. Modified files are kept. `product/` records, Graphify CLI, Graphify provider registration, and `graphify-out/` are deliberately preserved; Graphify may be shared with other tools and repositories. Use `--dry-run` with `uninstall` to preview removal.

## Safety and limitations

- The installer refuses symlinked paths, malformed managed markers, and unmanaged filename collisions.
- A failed Graphify registration leaves Buildroom files uncommitted. Graphify may have partially changed its own project files; inspect its output and rerun its provider install command. Buildroom never runs a broad Graphify uninstall as rollback.
- A provider is supported only after its native skill/agent discovery has been smoke-tested. The automated file-generation tests do not substitute for a native host smoke test.
- No provider CLI installation, API key, Agents API runtime, npm publication, remote deployment, or release is included.

## Primary references

- [GitHub Copilot CLI custom agents](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli)
- [GitHub Copilot CLI skills](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
- [Claude Code project subagents](https://code.claude.com/docs/en/sub-agents)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Graphify install](https://graphiffy.com/docs/install)
