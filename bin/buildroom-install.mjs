#!/usr/bin/env node
import { installProject, providers, uninstallProject } from '../scripts/project-installer.mjs';

function usage() {
  return `Buildroom project installer

Usage:
  node bin/buildroom-install.mjs install --provider <codex|copilot|claude-code> --project <path> [--dry-run]
  node bin/buildroom-install.mjs uninstall --project <path> [--provider <codex|copilot|claude-code>] [--dry-run]

Providers: ${providers().join(', ')}
Install or repeat install to update. Uninstall removes unchanged Buildroom-managed files only;
Graphify registration/data and product/ records are preserved.
`;
}

function parseArgs(args) {
  const [command, ...rest] = args;
  if (command === '--help' || command === '-h' || command === undefined) return { help: true };
  if (!['install', 'uninstall'].includes(command)) throw new Error(`Unknown command "${command}".`);
  const options = { command, dryRun: false };
  for (let index = 0; index < rest.length; index += 1) {
    const arg = rest[index];
    if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg === '--provider' || arg === '--project') {
      const value = rest[index + 1];
      if (!value || value.startsWith('--')) throw new Error(`${arg} requires a value.`);
      options[arg.slice(2)] = value;
      index += 1;
    } else if (arg === '--help' || arg === '-h') {
      return { help: true };
    } else {
      throw new Error(`Unknown option "${arg}".`);
    }
  }
  if (!options.project) throw new Error('Missing required --project <path>.');
  if (command === 'install' && !options.provider) throw new Error('Missing required --provider <codex|copilot|claude-code>.');
  if (options.provider && !providers().includes(options.provider)) {
    throw new Error(`Unsupported provider "${options.provider}". Choose ${providers().join(', ')}.`);
  }
  return options;
}

try {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    process.stdout.write(usage());
  } else if (options.command === 'install') {
    await installProject({ ...options, projectPath: options.project });
  } else {
    await uninstallProject({ ...options, projectPath: options.project });
  }
} catch (error) {
  process.stderr.write(`Buildroom installer: ${error.message}\n\n${usage()}`);
  process.exitCode = 1;
}
