import { createHash } from 'node:crypto';
import { statSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { constants as fsConstants } from 'node:fs';
import {
  access,
  lstat,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  realpath,
  rename,
  rm,
  rmdir,
  writeFile,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const MANIFEST_RELATIVE = '.buildroom/install.json';
const MARKERS = {
  routing: ['<!-- buildroom:project:start -->', '<!-- buildroom:project:end -->'],
  ignore: ['# buildroom:graphify-ignore:start', '# buildroom:graphify-ignore:end'],
};

const ROLE_PROFILES = [
  ['noether', 'researcher', 'Noether — Researcher', 'Researches a product question and returns cited evidence.'],
  ['curie', 'product-manager', 'Curie — Product Manager', 'Shapes approved evidence and user intent into testable product requirements.'],
  ['turing', 'architect', 'Turing — Architect', 'Produces bounded, testable technical designs from approved requirements.'],
  ['johnson', 'engineer', 'Johnson — Lead Engineer', 'Owns approved implementation, integration, and reproducible verification.'],
  ['lovelace', 'frontend-engineer', 'Lovelace — Frontend Engineer', 'Delivers bounded user-facing implementation slices under Johnson.'],
  ['euler', 'backend-engineer', 'Euler — Backend Engineer', 'Delivers bounded service, data, and integration slices under Johnson.'],
  ['feynman', 'qa-reviewer', 'Feynman — QA Reviewer', 'Independently verifies agreed behavior and release evidence.'],
  ['hypatia', 'hypatia', 'Hypatia — Product Designer', 'Provides bounded user-journey, interaction, content, and accessibility guidance.'],
  ['shannon', 'shannon', 'Shannon — Security & Privacy Reviewer', 'Identifies security and privacy risks, mitigations, and verification evidence.'],
];

const PAYLOAD_ITEMS = [
  ['agents', '.buildroom/agents'],
  ['workflows', '.buildroom/workflows'],
  ['templates', '.buildroom/templates'],
  ['knowledge', '.buildroom/knowledge'],
  ['memory', '.buildroom/memory'],
  ['registry.tsv', '.buildroom/registry.tsv'],
  ['bin/buildroom', '.buildroom/bin/buildroom'],
  ['scripts/run-operations.py', '.buildroom/scripts/run-operations.py'],
  ['codex/AGENTS.md.snippet', '.buildroom/codex/AGENTS.md.snippet'],
  ['plugins/buildroom/skills/buildroom/SKILL.md', '.buildroom/skills/buildroom/SKILL.md'],
  ['plugins/buildroom/skills/buildroom/references/master-orchestration.md', '.buildroom/skills/buildroom/references/master-orchestration.md'],
  ['plugins/buildroom/skills/buildroom/references/agent-profiles', '.buildroom/agent-profiles'],
];

const PROVIDERS = {
  codex: {
    label: 'Codex',
    skill: '.agents/skills/buildroom/SKILL.md',
    agents: '.codex/agents',
    instructions: ['AGENTS.md'],
    graphify: 'codex',
    next: 'Open a new Codex session in the target repository and ask Buildroom to help.',
  },
  copilot: {
    label: 'GitHub Copilot CLI',
    skill: '.github/skills/buildroom/SKILL.md',
    agents: '.github/agents',
    instructions: ['AGENTS.md'],
    graphify: 'copilot',
    next: 'Start Copilot CLI in the target repository; Buildroom is available as a skill and custom agents.',
  },
  'claude-code': {
    label: 'Claude Code',
    skill: '.claude/skills/buildroom/SKILL.md',
    agents: '.claude/agents',
    // The run helper validates AGENTS.md for every provider. Claude Code
    // additionally reads CLAUDE.md natively, so keep both entry points aligned.
    instructions: ['CLAUDE.md', 'AGENTS.md'],
    graphify: 'claude',
    next: 'Start Claude Code in the target repository and invoke /buildroom or describe the work.',
  },
};

function expectedGraphifyPaths(provider) {
  const skillRoot = provider === 'codex'
    ? '.codex/skills/graphify'
    : provider === 'copilot'
      ? '.copilot/skills/graphify'
      : '.claude/skills/graphify';
  const paths = [
    `${skillRoot}/SKILL.md`,
    `${skillRoot}/references/`,
    `${skillRoot}/.graphify_version`,
  ];
  if (provider === 'codex') paths.push('.codex/hooks.json', 'AGENTS.md (Graphify-managed section)');
  if (provider === 'copilot') paths.push('Copilot CLI project skill registration');
  if (provider === 'claude-code') paths.push('.claude/settings.json', '.claude/CLAUDE.md', 'CLAUDE.md (Graphify-managed section)');
  return paths;
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

function safeRelative(value) {
  if (typeof value !== 'string' || !value || path.isAbsolute(value)) {
    throw new Error(`Unsafe managed path in installer manifest: ${String(value)}`);
  }
  const normalized = path.normalize(value);
  if (normalized === '..' || normalized.startsWith(`..${path.sep}`)) {
    throw new Error(`Unsafe managed path in installer manifest: ${value}`);
  }
  return normalized;
}

async function assertSafePath(project, relative, { allowMissing = true } = {}) {
  const normalized = safeRelative(relative);
  const absolute = path.join(project, normalized);
  const relativeCheck = path.relative(project, absolute);
  if (relativeCheck.startsWith(`..${path.sep}`) || relativeCheck === '..') {
    throw new Error(`Managed path escapes target project: ${relative}`);
  }
  let current = project;
  const parts = normalized.split(path.sep);
  for (const part of parts) {
    current = path.join(current, part);
    try {
      const info = await lstat(current);
      if (info.isSymbolicLink()) throw new Error(`Refusing to follow symbolic link: ${current}`);
      if (current !== absolute && !info.isDirectory()) {
        throw new Error(`Expected a directory in managed path: ${current}`);
      }
      if (current === absolute && !info.isFile() && !info.isDirectory()) {
        throw new Error(`Expected a regular file or directory: ${current}`);
      }
    } catch (error) {
      if (error.code !== 'ENOENT' || !allowMissing) throw error;
      break;
    }
  }
  return absolute;
}

async function walkSource(source, destination, desired) {
  const info = await lstat(source);
  if (info.isSymbolicLink()) throw new Error(`Buildroom source contains a symbolic link: ${source}`);
  if (info.isDirectory()) {
    for (const entry of (await readdir(source)).sort()) {
      await walkSource(path.join(source, entry), path.posix.join(destination, entry), desired);
    }
    return;
  }
  if (!info.isFile()) throw new Error(`Buildroom source is not a regular file: ${source}`);
  desired.set(destination, await readFile(source));
}

async function makePayload() {
  const desired = new Map();
  for (const [sourceRelative, destination] of PAYLOAD_ITEMS) {
    await walkSource(path.join(ROOT, sourceRelative), destination, desired);
  }
  const projectSkill = desired.get('.buildroom/skills/buildroom/SKILL.md').toString('utf8')
    .replaceAll('references/toolkit/', '.buildroom/');
  const customization = '\n\n## Project customization\n\nKeep custom Buildroom additions under `.buildroom/custom/skills/`, `.buildroom/custom/agents/`, or `.buildroom/custom/workflows/`. Do not edit canonical files to customize a project; installer updates preserve the custom directories.\n';
  desired.set('.buildroom/skills/buildroom/SKILL.md', Buffer.from(`${projectSkill.trimEnd()}${customization}`));
  const projectCli = desired.get('.buildroom/bin/buildroom').toString('utf8').replaceAll('buildroom/', '.buildroom/');
  desired.set('.buildroom/bin/buildroom', Buffer.from(projectCli));
  const routingSnippet = desired.get('.buildroom/codex/AGENTS.md.snippet').toString('utf8').replaceAll('buildroom/', '.buildroom/');
  desired.set('.buildroom/codex/AGENTS.md.snippet', Buffer.from(routingSnippet));
  desired.set('.buildroom/custom/README.md', Buffer.from([
    '# Project-local Buildroom customizations',
    '',
    'Add project-specific skills, role profiles, and workflows under `skills/`, `agents/`, and `workflows/` respectively. Canonical Buildroom sources remain under `.buildroom/agents`, `.buildroom/workflows`, and `.buildroom/skills`; keep local changes in this overlay so updates can preserve them.',
    '',
  ].join('\n')));
  for (const category of ['skills', 'agents', 'workflows']) {
    desired.set(`.buildroom/custom/${category}/.gitkeep`, Buffer.from(''));
  }
  return desired;
}

function masterEntry(provider) {
  return [
    '---',
    'name: buildroom',
    'description: Conversational Buildroom Master for product discovery, research, specifications, delivery, and bug fixes. Coordinates specialists while preserving human approval gates and project memory.',
    '---',
    '',
    '# Buildroom project entry point',
    '',
    'Read and follow `.buildroom/skills/buildroom/SKILL.md` before acting on Buildroom work. Its canonical role cards, workflows, templates, registry, and orchestration references live under `.buildroom/`; durable project runs, decisions, and memory live under `product/`.',
    '',
    `This project adapter targets ${PROVIDERS[provider].label}. Use only capabilities actually available in this host; never claim unsupported delegation. Keep all human approval, implementation, release, and deployment gates intact.`,
    '',
  ].join('\n');
}

function hostAgent(profile, provider) {
  const [slug, roleFile, roleName, description] = profile;
  const specialistLimits = slug === 'hypatia'
    ? 'Do not implement or redefine approved product scope.'
    : slug === 'shannon'
      ? 'Do not implement fixes or accept/waive security or privacy risk.'
      : '';
  const body = `Perform only a bounded ${roleName} assignment. Read the canonical role card at .buildroom/agents/${roleFile}.md and the linked workflow/context files before acting. Follow approved hand-offs and product/ workflow state. ${specialistLimits} Do not expand scope or approve human gates. Return evidence, changed paths, verification, blockers, and the proposed next action to the Buildroom Master.`;
  if (provider === 'copilot') {
    return [
      '---',
      `name: buildroom-${slug}`,
      `description: "Buildroom ${roleName}: ${description}"`,
      '---',
      '',
      body,
      '',
    ].join('\n');
  }
  return [
    '---',
    `name: buildroom-${slug}`,
    `description: "Buildroom ${roleName}: ${description}"`,
    '---',
    '',
    body,
    '',
  ].join('\n');
}

function routingBlock(provider, instructionPath) {
  const [start, end] = MARKERS.routing;
  return [
    start,
    '## Buildroom (project installation)',
    '',
    'When the user asks for Buildroom, first read `.buildroom/skills/buildroom/SKILL.md` and follow its routing, approval, and durable-state rules. Canonical roles, workflows, templates, and registry are under `.buildroom/`; all project runs, decisions, hand-offs, evidence, and memory belong under `product/`.',
    '',
    `This project includes the ${PROVIDERS[provider].label} adapter. This instruction block is in ${instructionPath}. Use its documented native skill/agent features only; do not claim unavailable delegation or skip human approval gates.`,
    '',
    'The repository’s own instructions, coding standards, and approval gates remain authoritative.',
    end,
  ].join('\n');
}

function graphifyIgnoreBlock() {
  return [MARKERS.ignore[0], 'graphify-out/', MARKERS.ignore[1]].join('\n');
}

function extractBlock(text, start, end, filename) {
  const startCount = text.split(start).length - 1;
  const endCount = text.split(end).length - 1;
  if (startCount !== endCount || startCount > 1) {
    throw new Error(`${filename} has malformed Buildroom markers. Repair the marked block before retrying.`);
  }
  if (!startCount) return null;
  const from = text.indexOf(start);
  const to = text.indexOf(end, from);
  if (to < from) throw new Error(`${filename} has reversed Buildroom markers. Repair the marked block before retrying.`);
  return text.slice(from, to + end.length);
}

function mergeBlock(existing, block, [start, end], filename, expectedHash) {
  const current = extractBlock(existing, start, end, filename);
  if (current && expectedHash && sha256(current) !== expectedHash) {
    throw new Error(`The Buildroom-managed block in ${filename} was edited locally; preserve it and resolve the change before updating.`);
  }
  if (current && !expectedHash) {
    throw new Error(`Found an unmanaged Buildroom marker in ${filename}; refusing to overwrite it.`);
  }
  if (!current) {
    const separator = !existing || existing.endsWith('\n\n') ? '' : existing.endsWith('\n') ? '\n' : '\n\n';
    return `${existing}${separator}${block}\n`;
  }
  return existing.replace(current, block);
}

function removeBlock(existing, markers, filename, expectedHash) {
  const current = extractBlock(existing, markers[0], markers[1], filename);
  if (!current) return existing;
  if (!expectedHash || sha256(current) !== expectedHash) {
    throw new Error(`The Buildroom-managed block in ${filename} was edited locally; preserving it during uninstall.`);
  }
  const removed = existing.replace(current, '').replace(/\n{3,}/g, '\n\n');
  return removed.trim() ? `${removed.replace(/\n+$/, '')}\n` : '';
}

async function readManifest(project) {
  const filename = await assertSafePath(project, MANIFEST_RELATIVE);
  try {
    const info = await lstat(filename);
    if (!info.isFile() || info.isSymbolicLink()) throw new Error(`Installer manifest is not a regular file: ${filename}`);
    const value = JSON.parse(await readFile(filename, 'utf8'));
    if (value.schemaVersion !== 1 || !value.provider || !value.files || !value.blocks) {
      throw new Error(`Unsupported or malformed Buildroom installer manifest: ${filename}`);
    }
    return value;
  } catch (error) {
    if (error.code === 'ENOENT') return null;
    throw error;
  }
}

async function readOptionalText(project, relative) {
  const filename = await assertSafePath(project, relative);
  try {
    const info = await lstat(filename);
    if (!info.isFile()) throw new Error(`Expected a regular file: ${filename}`);
    return await readFile(filename, 'utf8');
  } catch (error) {
    if (error.code === 'ENOENT') return '';
    throw error;
  }
}

async function buildDesiredFiles(provider, previous, project) {
  const descriptor = PROVIDERS[provider];
  if (!descriptor) throw new Error(`Unsupported provider "${provider}". Choose codex, copilot, or claude-code.`);
  const files = await makePayload();
  files.set(descriptor.skill, Buffer.from(masterEntry(provider)));

  if (provider === 'codex') {
    for (const profile of ROLE_PROFILES) {
      const source = path.join(ROOT, 'plugins/buildroom/skills/buildroom/references/agent-profiles', `buildroom-${profile[0]}.toml`);
      files.set(path.posix.join(descriptor.agents, `buildroom-${profile[0]}.toml`), await readFile(source));
    }
  } else {
    const extension = provider === 'copilot' ? '.agent.md' : '.md';
    for (const profile of ROLE_PROFILES) {
      files.set(path.posix.join(descriptor.agents, `buildroom-${profile[0]}${extension}`), Buffer.from(hostAgent(profile, provider)));
    }
  }

  const providerBlocks = {};
  const previousProviderBlocks = previous?.blocks ?? {};
  for (const instructionPath of descriptor.instructions) {
    const instructionText = await readOptionalText(project, instructionPath);
    let preexisting = previousProviderBlocks[instructionPath]?.preexisting;
    if (preexisting === undefined) {
      try {
        const info = await lstat(await assertSafePath(project, instructionPath));
        preexisting = info.isFile();
      } catch (error) {
        if (error.code !== 'ENOENT') throw error;
        preexisting = false;
      }
    }
    const instructionBlock = routingBlock(provider, instructionPath);
    const mergedInstructions = mergeBlock(
      instructionText,
      instructionBlock,
      MARKERS.routing,
      instructionPath,
      previousProviderBlocks[instructionPath]?.hash,
    );
    providerBlocks[instructionPath] = { hash: sha256(instructionBlock), markers: MARKERS.routing, preexisting };
    files.set(instructionPath, Buffer.from(mergedInstructions));
  }

  const ignoreText = await readOptionalText(project, '.gitignore');
  const alreadyIgnored = ignoreText.split(/\r?\n/).some((line) => line.trim() === 'graphify-out/');
  if (!alreadyIgnored) {
    const block = graphifyIgnoreBlock();
    const mergedIgnore = mergeBlock(ignoreText, block, MARKERS.ignore, '.gitignore', previousProviderBlocks['.gitignore']?.hash);
    providerBlocks['.gitignore'] = { hash: sha256(block), markers: MARKERS.ignore };
    files.set('.gitignore', Buffer.from(mergedIgnore));
  } else if (previousProviderBlocks['.gitignore']) {
    // Keep ownership only if the installer originally added its exact block.
    providerBlocks['.gitignore'] = previousProviderBlocks['.gitignore'];
  }

  return { files, blocks: providerBlocks, descriptor };
}

async function checkTarget(project, desired, previous) {
  for (const relative of desired.keys()) await assertSafePath(project, relative);
  for (const [relative, content] of desired) {
    const filename = path.join(project, relative);
    let info;
    try {
      info = await lstat(filename);
    } catch (error) {
      if (error.code === 'ENOENT') continue;
      throw error;
    }
    if (info.isDirectory()) throw new Error(`A directory blocks installer file ${relative}.`);
    const oldHash = previous?.files?.[relative];
    if (!oldHash) {
      const blockInfo = previous?.blocks?.[relative];
      if (blockInfo) continue;
      if (['AGENTS.md', 'CLAUDE.md', '.gitignore'].includes(relative)) continue;
      throw new Error(`Refusing to overwrite unmanaged file ${relative}. Move it or choose another target, then retry.`);
    }
    const currentHash = sha256(await readFile(filename));
    if (currentHash !== oldHash && relative !== 'AGENTS.md' && relative !== 'CLAUDE.md' && relative !== '.gitignore') {
      throw new Error(`Buildroom-managed file ${relative} has local edits. Move custom changes to .buildroom/custom/ and restore the managed file before updating.`);
    }
    if (oldHash && (relative === 'AGENTS.md' || relative === 'CLAUDE.md' || relative === '.gitignore')) {
      const block = previous?.blocks?.[relative];
      if (block) {
        const text = await readFile(filename, 'utf8');
        const extracted = extractBlock(text, block.markers[0], block.markers[1], relative);
        if (!extracted || sha256(extracted) !== block.hash) {
          throw new Error(`The Buildroom-managed block in ${relative} has local edits; resolve it before updating.`);
        }
      }
    }
    void content;
  }
}

async function listMissingDirectories(project, relativePaths) {
  const missing = new Set();
  for (const relative of relativePaths) {
    let cursor = path.dirname(path.join(project, relative));
    while (cursor !== project && cursor.startsWith(`${project}${path.sep}`)) {
      try {
        const info = await lstat(cursor);
        if (info.isSymbolicLink() || !info.isDirectory()) throw new Error(`Unsafe directory in target path: ${cursor}`);
      } catch (error) {
        if (error.code !== 'ENOENT') throw error;
        missing.add(cursor);
      }
      cursor = path.dirname(cursor);
    }
  }
  return [...missing].sort((a, b) => a.length - b.length);
}

async function ensureProductScaffold(project) {
  const directories = ['product', 'product/active', 'product/archive', 'product/memory'];
  const missingDirectories = new Set();
  for (const relative of directories) {
    const absolute = path.join(project, relative);
    try {
      const info = await lstat(absolute);
      if (info.isSymbolicLink() || !info.isDirectory()) throw new Error(`Expected a regular directory or no path at: ${absolute}`);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
      missingDirectories.add(relative);
    }
  }
  const files = new Map([
    ['product/memory/index.md', '# Product Memory Index\n\n## Active work\n\n## Decisions\n\n## Artefacts and relationships\n'],
    ['product/memory/decision-log.md', '# Product Decision Log\n\nRecord material decisions with links to their evidence and affected runs.\n'],
  ]);
  const createdFiles = new Map();
  for (const relative of ['product/active', 'product/archive']) {
    if (missingDirectories.has(relative)) {
      createdFiles.set(`${relative}/.gitkeep`, Buffer.from('Buildroom durable state directory.\n'));
    }
  }
  for (const [relative, content] of files) {
    const absolute = await assertSafePath(project, relative);
    try {
      const info = await lstat(absolute);
      if (info.isSymbolicLink() || !info.isFile()) throw new Error(`Expected a regular file or no path at: ${absolute}`);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
      createdFiles.set(relative, Buffer.from(content));
    }
  }
  return createdFiles;
}

function commandResult(command, args, cwd, io, options = {}) {
  return io.run(command, args, cwd, options);
}

function getDefaultIO() {
  const findExecutable = (name) => {
    if (!name) return null;
    if (path.isAbsolute(name)) {
      try {
        const info = statSync(name);
        return info.isFile() && (process.platform === 'win32' || (info.mode & 0o111)) ? name : null;
      } catch { return null; }
    }
    const candidates = (process.env.PATH ?? '').split(path.delimiter).filter(Boolean);
    const extensions = process.platform === 'win32' ? (process.env.PATHEXT ?? '.EXE;.CMD;.BAT').split(';') : [''];
    for (const directory of candidates) {
      for (const extension of extensions) {
        const filename = path.join(directory, `${name}${extension}`);
        try {
          const info = statSync(filename);
          if (info.isFile() && (process.platform === 'win32' || (info.mode & 0o111))) return filename;
        } catch {}
      }
    }
    return null;
  };
  return {
    findExecutable,
    run(command, args, cwd, { capture = false } = {}) {
      const result = spawnSync(command, args, {
        cwd,
        encoding: capture ? 'utf8' : undefined,
        stdio: capture ? 'pipe' : 'inherit',
        maxBuffer: 4 * 1024 * 1024,
        env: process.env,
      });
      return {
        status: result.status ?? 1,
        stdout: result.stdout ?? '',
        stderr: result.stderr ?? '',
        error: result.error,
      };
    },
  };
}

async function findGraphify(io) {
  const override = process.env.BUILDROOM_GRAPHIFY_COMMAND;
  const command = override || 'graphify';
  const executable = io.findExecutable(command);
  if (executable) {
    const version = commandResult(executable, ['--version'], process.cwd(), io, { capture: true });
    if (version.status === 0) {
      const label = `${version.stdout}${version.stderr}`.trim().replace(/^graphify\s+/i, '') || 'installed';
      return { command: executable, version: label };
    }
  }
  return null;
}

async function resolveManagedTool(io, managerName, executableName) {
  const manager = io.findExecutable(managerName);
  if (!manager) return null;
  const result = commandResult(manager, managerName === 'uv' ? ['tool', 'dir', '--bin'] : ['environment', '--value', 'PIPX_BIN_DIR'], process.cwd(), io, { capture: true });
  if (result.status !== 0) return null;
  const binDirectory = result.stdout.trim();
  if (!binDirectory) return null;
  const tool = path.join(binDirectory, executableName);
  return io.findExecutable(tool) ? tool : null;
}

function hasPython310(io, project) {
  for (const name of ['python3', 'python']) {
    const python = io.findExecutable(name);
    if (!python) continue;
    const result = commandResult(python, ['-c', 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)'], project, io, { capture: true });
    if (result.status === 0) return true;
  }
  return false;
}

async function provisionGraphify(project, io, dryRun) {
  const existing = await findGraphify(io);
  if (existing) return { ...existing, installed: false };
  const uv = io.findExecutable(process.env.BUILDROOM_UV_COMMAND || 'uv');
  const pipx = io.findExecutable(process.env.BUILDROOM_PIPX_COMMAND || 'pipx');
  if (dryRun) {
    const method = uv ? 'uv tool install --python ">=3.10" graphifyy' : pipx ? 'pipx install graphifyy' : null;
    if (!method) return { missing: true, message: 'Graphify is missing; installation requires Python 3.10+ and uv or pipx.' };
    if (!uv && !hasPython310(io, project)) return { missing: true, message: 'Graphify is missing; pipx installation requires Python 3.10+.' };
    return { missing: true, planned: method };
  }
  if (!uv && !pipx) throw new Error('Graphify is missing. Install Python 3.10+ and either uv or pipx, then rerun Buildroom installer.');
  if (!uv && !hasPython310(io, project)) throw new Error('Graphify requires Python 3.10+ for pipx installation. Install or select Python 3.10+ and retry.');
  let installed = false;
  if (uv) {
    const result = commandResult(uv, ['tool', 'install', '--python', '>=3.10', 'graphifyy'], project, io);
    installed = result.status === 0;
    if (!installed && pipx) {
      if (!hasPython310(io, project)) throw new Error('Graphify requires Python 3.10+ for the pipx fallback. Install or select Python 3.10+ and retry.');
      const fallback = commandResult(pipx, ['install', 'graphifyy'], project, io);
      installed = fallback.status === 0;
    }
  } else {
    installed = commandResult(pipx, ['install', 'graphifyy'], project, io).status === 0;
  }
  if (!installed) throw new Error('Graphify installation failed with the available package managers. Repair uv/pipx and retry.');
  let command = io.findExecutable(process.env.BUILDROOM_GRAPHIFY_COMMAND || 'graphify');
  if (!command) command = await resolveManagedTool(io, 'uv', 'graphify') || await resolveManagedTool(io, 'pipx', 'graphify');
  if (!command) throw new Error('Graphify was installed, but its CLI is not on PATH. Add the uv/pipx tool bin directory and rerun.');
  return { command, installed: true, version: 'newly installed' };
}

async function normalizeProject(projectPath) {
  if (!projectPath) throw new Error('Missing required --project <path>.');
  const expanded = projectPath.startsWith('~/') ? path.join(os.homedir(), projectPath.slice(2)) : projectPath;
  const absolute = path.resolve(expanded);
  const info = await lstat(absolute);
  if (info.isSymbolicLink() || !info.isDirectory()) throw new Error(`Target project must be a real existing directory: ${absolute}`);
  return realpath(absolute);
}

export async function commitFiles(project, files) {
  const stage = await mkdtemp(path.join(project, '.buildroom-install-stage-'));
  const created = [];
  const prior = new Map();
  try {
    for (const [relative, content] of files) {
      const staged = path.join(stage, safeRelative(relative));
      await mkdir(path.dirname(staged), { recursive: true });
      await writeFile(staged, content, { mode: 0o644 });
    }
    const directories = await listMissingDirectories(project, [...files.keys()]);
    for (const directory of directories) {
      await mkdir(directory);
      created.push(directory);
    }
    for (const relative of files.keys()) {
      const destination = path.join(project, safeRelative(relative));
      try {
        const data = await readFile(destination);
        prior.set(relative, data);
      } catch (error) {
        if (error.code !== 'ENOENT') throw error;
        prior.set(relative, null);
      }
      await rename(path.join(stage, safeRelative(relative)), destination);
    }
    return { prior, created };
  } catch (error) {
    await restoreFiles(project, prior, created);
    throw error;
  } finally {
    await rm(stage, { recursive: true, force: true });
  }
}

async function restoreFiles(project, prior, createdDirectories = []) {
  for (const [relative, content] of [...prior.entries()].reverse()) {
    const destination = path.join(project, safeRelative(relative));
    if (content === null) await rm(destination, { force: true });
    else await writeFile(destination, content);
  }
  for (const directory of [...createdDirectories].reverse()) {
    try { await rmdir(directory); } catch {}
  }
}

async function getBuildVersion() {
  try {
    const pkg = JSON.parse(await readFile(path.join(ROOT, 'plugins/buildroom/.codex-plugin/plugin.json'), 'utf8'));
    return pkg.version;
  } catch {
    return '0.0.0';
  }
}

async function prepareInstall(project, provider, previous) {
  const { files, blocks, descriptor } = await buildDesiredFiles(provider, previous, project);
  const productFiles = await ensureProductScaffold(project);
  for (const [relative, content] of productFiles) {
    if (!files.has(relative)) files.set(relative, content);
  }
  await checkTarget(project, files, previous);
  return { files, blocks, descriptor };
}

export async function installProject({ projectPath, provider, dryRun = false, io = getDefaultIO(), report = console.log }) {
  assertSupportedNodeVersion();
  if (!PROVIDERS[provider]) throw new Error(`Unsupported provider "${provider}". Choose codex, copilot, or claude-code.`);
  const project = await normalizeProject(projectPath);
  const previous = await readManifest(project);
  if (previous && previous.provider !== provider) {
    throw new Error(`This project is already managed for ${previous.provider}. Uninstall that provider first; multi-provider installs are not supported in v1.`);
  }
  const plan = await prepareInstall(project, provider, previous);
  const graphifyCommand = process.env.BUILDROOM_GRAPHIFY_COMMAND || 'graphify';

  if (dryRun) {
    report(`Buildroom ${PROVIDERS[provider].label} project install preview (${project})`);
    for (const [relative, content] of plan.files) {
      const exists = await assertSafePath(project, relative).then(async (filename) => {
        try { await access(filename, fsConstants.F_OK); return true; } catch { return false; }
      });
      report(`  ${exists ? 'update' : 'create'} ${relative} (${content.length} bytes)`);
    }
    const graphify = await provisionGraphify(project, io, true);
    if (graphify.version) report(`  Graphify ${graphify.version}: preserve existing version`);
    else if (graphify.planned) report(`  would run: ${graphify.planned}`);
    else report(`  prerequisite: ${graphify.message}`);
    report(`  would run: ${graphifyCommand} ${PROVIDERS[provider].graphify} install --project`);
    report('  Graphify-managed project paths expected for the current integration:');
    for (const relative of expectedGraphifyPaths(provider)) report(`    ${relative}`);
    report('  Graphify manages these registration files; exact behavior follows the installed Graphify version.');
    report('dry-run: no files or external commands changed');
    return { project, provider, dryRun: true, graphify };
  }

  const graphify = await provisionGraphify(project, io, false);
  const graphifyArgs = [PROVIDERS[provider].graphify, 'install', '--project'];
  const graphifyResult = commandResult(graphify.command, graphifyArgs, project, io);
  if (graphifyResult.status !== 0) {
    throw new Error(`Graphify registration failed for ${PROVIDERS[provider].label}. Buildroom files were not committed. Graphify may have partial project changes; inspect its output and rerun: ${graphify.command} ${graphifyArgs.join(' ')}`);
  }

  // Graphify can add its own section to AGENTS.md/CLAUDE.md. Re-read those files
  // and merge Buildroom's block after registration, then re-check local races.
  const refreshed = await prepareInstall(project, provider, previous);
  const manifest = {
    schemaVersion: 1,
    buildroomVersion: await getBuildVersion(),
    provider,
    installedAt: new Date().toISOString(),
    files: {},
    blocks: refreshed.blocks,
    graphify: { registered: true, platform: PROVIDERS[provider].graphify, command: graphify.command },
  };
  for (const [relative, content] of refreshed.files) {
    if (relative !== MANIFEST_RELATIVE && !relative.startsWith('product/')) manifest.files[relative] = sha256(content);
  }
  refreshed.files.set(MANIFEST_RELATIVE, Buffer.from(`${JSON.stringify(manifest, null, 2)}\n`));
  await commitFiles(project, refreshed.files);
  report(`Installed Buildroom for ${PROVIDERS[provider].label} in ${project}`);
  report(`Graphify ${graphify.version}; project registration complete`);
  report(PROVIDERS[provider].next);
  return { project, provider, dryRun: false, graphify, manifest };
}

export async function uninstallProject({ projectPath, provider, dryRun = false, report = console.log }) {
  assertSupportedNodeVersion();
  const project = await normalizeProject(projectPath);
  const manifest = await readManifest(project);
  if (!manifest) throw new Error(`No Buildroom installation manifest found in ${project}.`);
  if (provider && provider !== manifest.provider) {
    throw new Error(`The project is installed for ${manifest.provider}, not ${provider}.`);
  }
  const protectedFiles = [];
  const removeFiles = [];
  for (const [relative, expectedHash] of Object.entries(manifest.files)) {
    const filename = await assertSafePath(project, relative);
    try {
      const info = await lstat(filename);
      if (!info.isFile() || info.isSymbolicLink()) {
        protectedFiles.push(relative);
        continue;
      }
      if (sha256(await readFile(filename)) === expectedHash) removeFiles.push(relative);
      else protectedFiles.push(relative);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
  }
  const blockChanges = new Map();
  for (const [relative, blockInfo] of Object.entries(manifest.blocks)) {
    const text = await readOptionalText(project, relative);
    try {
      const cleaned = removeBlock(text, blockInfo.markers, relative, blockInfo.hash);
      if (cleaned !== text) {
        if (!cleaned && blockInfo.preexisting === false) {
          if (!removeFiles.includes(relative)) removeFiles.push(relative);
          blockChanges.delete(relative);
        } else {
          blockChanges.set(relative, Buffer.from(cleaned));
        }
      }
    } catch (error) {
      protectedFiles.push(`${relative} managed block`);
      report(error.message);
    }
  }
  if (dryRun) {
    report(`Buildroom ${manifest.provider} uninstall preview (${project})`);
    for (const relative of removeFiles) report(`  remove ${relative}`);
    for (const relative of blockChanges.keys()) report(`  remove Buildroom block from ${relative}`);
    for (const relative of protectedFiles) report(`  preserve locally modified ${relative}`);
    report('  preserve Graphify CLI, Graphify project registration, graph data, and product/ records');
    report('dry-run: no files changed');
    return { project, removed: [], protectedFiles, dryRun: true };
  }
  const stage = await mkdtemp(path.join(project, '.buildroom-uninstall-stage-'));
  const removed = [];
  try {
    for (const relative of removeFiles) {
      await rm(path.join(project, relative), { force: true });
      removed.push(relative);
    }
    for (const [relative, content] of blockChanges) await writeFile(path.join(project, relative), content);
    await rm(path.join(project, MANIFEST_RELATIVE), { force: true });
    const candidateDirectories = new Set();
    for (const relative of [...removeFiles, MANIFEST_RELATIVE]) {
      let directory = path.dirname(path.join(project, relative));
      while (directory !== project && directory.startsWith(`${project}${path.sep}`)) {
        candidateDirectories.add(directory);
        directory = path.dirname(directory);
      }
    }
    for (const directory of [...candidateDirectories].sort((a, b) => b.length - a.length)) {
      try { await rmdir(directory); } catch {}
    }
  } finally {
    await rm(stage, { recursive: true, force: true });
  }
  report(`Removed Buildroom-managed files from ${project}`);
  if (protectedFiles.length) report(`Preserved locally edited files: ${protectedFiles.join(', ')}`);
  report('Graphify registration, graph data, and product/ records were preserved.');
  return { project, removed, protectedFiles, dryRun: false };
}

export function providers() {
  return Object.keys(PROVIDERS);
}

export function assertSupportedNodeVersion(version = process.versions.node) {
  const major = Number.parseInt(String(version).split('.')[0], 10);
  if (!Number.isFinite(major) || major < 20) {
    throw new Error(`Node.js 20 or newer is required; detected ${version}.`);
  }
}
