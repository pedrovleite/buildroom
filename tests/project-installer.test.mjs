import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, rm, stat, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { assertSupportedNodeVersion, commitFiles, installProject, uninstallProject } from '../scripts/project-installer.mjs';

async function fixture(t) {
  const parent = await mkdtemp(path.join(os.tmpdir(), 'buildroom-installer-test-'));
  const project = path.join(parent, 'project');
  await mkdir(project);
  t.after(() => rm(parent, { recursive: true, force: true }));
  return project;
}

function fakeIO({ graphify = true, registrationStatus = 0 } = {}) {
  const calls = [];
  return {
    calls,
    findExecutable(name) {
      if ((name === 'graphify' || name === '/fake/graphify') && graphify) return '/fake/graphify';
      if (name === 'uv' || name === 'pipx') return null;
      return null;
    },
    run(command, args, cwd, options = {}) {
      calls.push({ command, args, cwd, options });
      if (args[0] === '--version') return { status: 0, stdout: 'graphify 0.9.test', stderr: '' };
      return { status: registrationStatus, stdout: '', stderr: '' };
    },
  };
}

test('dry-run previews a provider setup without writes or registration', async (t) => {
  const project = await fixture(t);
  await writeFile(path.join(project, 'AGENTS.md'), '# Existing instructions\n');
  const io = fakeIO();
  const lines = [];
  await installProject({ projectPath: project, provider: 'copilot', dryRun: true, io, report: (line) => lines.push(line) });
  assert.equal(io.calls.filter((call) => call.args.includes('install')).length, 0);
  assert.match(lines.join('\n'), /\.github\/agents\/buildroom-noether\.agent\.md/);
  assert.match(lines.join('\n'), /\.github\/agents\/buildroom-hypatia\.agent\.md/);
  assert.match(lines.join('\n'), /\.github\/agents\/buildroom-shannon\.agent\.md/);
  assert.match(lines.join('\n'), /\.copilot\/skills\/graphify\/SKILL\.md/);
  assert.match(lines.join('\n'), /dry-run: no files or external commands changed/);
  await assert.rejects(readFile(path.join(project, '.buildroom/install.json')));
  assert.equal(await readFile(path.join(project, 'AGENTS.md'), 'utf8'), '# Existing instructions\n');
});

for (const provider of ['codex', 'copilot', 'claude-code']) {
  test(`installs ${provider} project files, Graphify registration, and is idempotent`, async (t) => {
    const project = await fixture(t);
    const originalInstructions = '# Team instructions\n\nDo not overwrite me.\n';
    await writeFile(path.join(project, 'AGENTS.md'), originalInstructions);
    const io = fakeIO();
    await installProject({ projectPath: project, provider, io, report: () => {} });
    const manifest = JSON.parse(await readFile(path.join(project, '.buildroom/install.json'), 'utf8'));
    assert.equal(manifest.provider, provider);
    assert.equal(manifest.graphify.registered, true);
    assert.equal(io.calls.at(-1).args.join(' '), `${provider === 'claude-code' ? 'claude' : provider} install --project`);
    const skillPath = provider === 'codex'
      ? '.agents/skills/buildroom/SKILL.md'
      : provider === 'copilot'
        ? '.github/skills/buildroom/SKILL.md'
        : '.claude/skills/buildroom/SKILL.md';
    assert.match(await readFile(path.join(project, skillPath), 'utf8'), /\.buildroom\/skills\/buildroom\/SKILL\.md/);
    assert.match(await readFile(path.join(project, '.buildroom/skills/buildroom/SKILL.md'), 'utf8'), /Project customization/);
    assert.match(await readFile(path.join(project, '.buildroom/skills/buildroom/SKILL.md'), 'utf8'), /\.buildroom\/knowledge\/catalog\.yml/);
    assert.match(await readFile(path.join(project, '.buildroom/agents/hypatia.md'), 'utf8'), /Hypatia — Product Designer/);
    assert.match(await readFile(path.join(project, '.buildroom/agents/shannon.md'), 'utf8'), /Shannon — Security & Privacy Reviewer/);
    const providerAgents = provider === 'codex' ? '.codex/agents' : provider === 'copilot' ? '.github/agents' : '.claude/agents';
    const providerExtension = provider === 'copilot' ? '.agent.md' : provider === 'claude-code' ? '.md' : '.toml';
    for (const slug of ['hypatia', 'shannon']) {
      const profile = await readFile(path.join(project, providerAgents, `buildroom-${slug}${providerExtension}`), 'utf8');
      assert.match(profile, new RegExp(`buildroom-${slug}`));
      assert.match(profile, /bounded|only a bounded/i);
      assert.match(profile, /Do not [^.\n]*(implement|scope|risk|approve)/i);
    }
    assert.equal(await readFile(path.join(project, 'AGENTS.md'), 'utf8').then((value) => value.startsWith(originalInstructions)), true);
    assert.equal(await readFile(path.join(project, 'product/memory/index.md'), 'utf8').then((value) => value.startsWith('# Product Memory Index')), true);

    const oldManifest = await readFile(path.join(project, '.buildroom/install.json'));
    await installProject({ projectPath: project, provider, io, report: () => {} });
    assert.equal(io.calls.filter((call) => call.args.includes('install')).length, 2);
    assert.equal(await readFile(path.join(project, '.buildroom/install.json'), 'utf8').then((value) => JSON.parse(value).provider), provider);
    assert.notDeepEqual(await readFile(path.join(project, '.buildroom/install.json')), oldManifest);
  });
}

for (const provider of ['codex', 'copilot', 'claude-code']) {
  test(`fresh ${provider} install creates runnable Buildroom state and instruction files`, async (t) => {
    const project = await fixture(t);
    await installProject({ projectPath: project, provider, io: fakeIO(), report: () => {} });
    for (const directory of ['product/active', 'product/archive', 'product/memory']) {
      assert.equal((await stat(path.join(project, directory))).isDirectory(), true);
    }
    assert.match(await readFile(path.join(project, 'AGENTS.md'), 'utf8'), /buildroom:project:start/);
    if (provider === 'claude-code') {
      assert.match(await readFile(path.join(project, 'CLAUDE.md'), 'utf8'), /buildroom:project:start/);
    }
    const started = spawnSync('sh', [path.join(project, '.buildroom/bin/buildroom'), 'start', 'feature', 'SMOKE-1', '--project', project], {
      encoding: 'utf8',
    });
    assert.equal(started.status, 0, `${started.stdout}\n${started.stderr}`);
    assert.match(await readFile(path.join(project, 'product/active/SMOKE-1/workflow-state.md'), 'utf8'), /id: SMOKE-1/);

    await uninstallProject({ projectPath: project, report: () => {} });
    await assert.rejects(readFile(path.join(project, 'AGENTS.md')));
    await assert.rejects(readFile(path.join(project, 'CLAUDE.md')));
    assert.match(await readFile(path.join(project, 'product/active/SMOKE-1/workflow-state.md'), 'utf8'), /id: SMOKE-1/);
  });
}

test('requires Node.js 20 or newer', () => {
  assert.throws(() => assertSupportedNodeVersion('18.20.8'), /Node\.js 20 or newer is required/);
  assert.doesNotThrow(() => assertSupportedNodeVersion('20.0.0'));
  assert.doesNotThrow(() => assertSupportedNodeVersion('22.1.0'));
});

test('refuses unmanaged collisions before invoking Graphify', async (t) => {
  const project = await fixture(t);
  const collision = path.join(project, '.claude/skills/buildroom/SKILL.md');
  await mkdir(path.dirname(collision), { recursive: true });
  await writeFile(collision, 'user-owned skill\n');
  const io = fakeIO();
  await assert.rejects(
    installProject({ projectPath: project, provider: 'claude-code', io, report: () => {} }),
    /Refusing to overwrite unmanaged file/,
  );
  assert.equal(io.calls.length, 0);
  assert.equal(await readFile(collision, 'utf8'), 'user-owned skill\n');
});

test('registration failure leaves no partial Buildroom files', async (t) => {
  const project = await fixture(t);
  const io = fakeIO({ registrationStatus: 1 });
  await assert.rejects(
    installProject({ projectPath: project, provider: 'codex', io, report: () => {} }),
    /Graphify registration failed/,
  );
  await assert.rejects(readFile(path.join(project, '.buildroom/install.json')));
  await assert.rejects(readFile(path.join(project, '.agents/skills/buildroom/SKILL.md')));
});

test('missing Graphify prerequisites fail before writing the project', async (t) => {
  const project = await fixture(t);
  const io = fakeIO({ graphify: false });
  await assert.rejects(
    installProject({ projectPath: project, provider: 'codex', io, report: () => {} }),
    /Graphify is missing.*Python 3\.10\+ and either uv or pipx/,
  );
  await assert.rejects(readFile(path.join(project, '.buildroom/install.json')));
  await assert.rejects(readFile(path.join(project, 'AGENTS.md')));
});

test('staged writes roll back files already committed when a later rename fails', async (t) => {
  const project = await fixture(t);
  await mkdir(path.join(project, 'blocked'));
  await assert.rejects(commitFiles(project, new Map([
    ['created-before-failure.txt', Buffer.from('temporary')],
    ['blocked', Buffer.from('cannot replace directory')],
  ])));
  await assert.rejects(readFile(path.join(project, 'created-before-failure.txt')));
});

test('uninstall preserves product records, Graphify files, and locally modified managed files', async (t) => {
  const project = await fixture(t);
  const io = fakeIO();
  await installProject({ projectPath: project, provider: 'copilot', io, report: () => {} });
  const productState = path.join(project, 'product/active/KEEP.md');
  await mkdir(path.dirname(productState), { recursive: true });
  await writeFile(productState, 'user-owned decision\n');
  const modifiedCanonical = path.join(project, '.buildroom/workflows/feature-delivery.md');
  await writeFile(modifiedCanonical, `${await readFile(modifiedCanonical, 'utf8')}\nLocal customization\n`);
  await writeFile(path.join(project, 'AGENTS.md'), `${await readFile(path.join(project, 'AGENTS.md'), 'utf8')}\nAdditional user instruction\n`);
  const output = [];
  const result = await uninstallProject({ projectPath: project, provider: 'copilot', report: (line) => output.push(line) });
  assert.ok(result.protectedFiles.includes('.buildroom/workflows/feature-delivery.md'));
  assert.match(await readFile(productState, 'utf8'), /user-owned decision/);
  assert.match(await readFile(modifiedCanonical, 'utf8'), /Local customization/);
  assert.match(await readFile(path.join(project, 'AGENTS.md'), 'utf8'), /Additional user instruction/);
  assert.doesNotMatch(await readFile(path.join(project, 'AGENTS.md'), 'utf8'), /buildroom:project:start/);
  assert.match(output.join('\n'), /Graphify registration, graph data, and product\/ records were preserved/);
});

test('uninstall dry-run reports removals but makes no changes', async (t) => {
  const project = await fixture(t);
  const io = fakeIO();
  await installProject({ projectPath: project, provider: 'claude-code', io, report: () => {} });
  const before = await readFile(path.join(project, '.buildroom/install.json'));
  const lines = [];
  await uninstallProject({ projectPath: project, dryRun: true, report: (line) => lines.push(line) });
  assert.match(lines.join('\n'), /preserve Graphify CLI/);
  assert.deepEqual(await readFile(path.join(project, '.buildroom/install.json')), before);
  assert.equal(await readFile(path.join(project, '.claude/skills/buildroom/SKILL.md'), 'utf8').then((value) => value.includes('Buildroom project entry point')), true);
});

test('rejects switching a project to another provider without first uninstalling', async (t) => {
  const project = await fixture(t);
  const io = fakeIO();
  await installProject({ projectPath: project, provider: 'codex', io, report: () => {} });
  await assert.rejects(
    installProject({ projectPath: project, provider: 'copilot', io, report: () => {} }),
    /Uninstall that provider first/,
  );
});
