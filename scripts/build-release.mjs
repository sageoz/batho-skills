#!/usr/bin/env node
/**
 * build-release.mjs — deterministic release artifacts for the Batho skill pack.
 *
 * Produces in dist/:
 *   batho-skills-<ver>.tar.gz / .zip     (combined pack)
 *   batho-skills-<name>-<ver>.tar.gz     (per-skill)
 *   install.sh / install.ps1           (rendered, embedded version+digest)
 *   sha256sums.txt                     (GNU format, all artifacts)
 *   index.json                         (.well-known/agent-skills discovery v0.2.0)
 *
 * No npm deps — uses system tar (GNU flags for determinism) + zip.
 * Usage: node scripts/build-release.mjs <tag>   (tag like v1.2.3)
 */
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, mkdtempSync, cpSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const TAG = process.argv[2];
if (!TAG) { console.error('usage: build-release.mjs <tag>'); process.exit(1); }
const VER = TAG.replace(/^v/, '');
const REPO = process.env.GITHUB_REPOSITORY || 'sageoz/batho-skills';
const BASE = `${process.env.GITHUB_SERVER_URL || 'https://github.com'}/${REPO}`;
const ROOT = process.cwd();
const DIST = join(ROOT, 'dist');
const SKILLS_DIR = join(ROOT, 'skills');

const sha256 = (p) => createHash('sha256').update(readFileSync(p)).digest('hex');
const skills = readdirSync(SKILLS_DIR, { withFileTypes: true })
  .filter((d) => d.isDirectory() && existsSync(join(SKILLS_DIR, d.name, 'SKILL.md')))
  .map((d) => d.name)
  .sort();
if (!skills.length) { console.error('no skills found'); process.exit(1); }

mkdirSync(DIST, { recursive: true });
const artifacts = [];
const run = (cmd, args, opts = {}) =>
  execFileSync(cmd, args, { stdio: 'inherit', ...opts });

// stage a clean tree so archives contain skills/<name>/... at their root
const stage = mkdtempSync(join(tmpdir(), 'batho-rel-'));
mkdirSync(join(stage, 'skills'));
for (const s of skills) cpSync(join(SKILLS_DIR, s), join(stage, 'skills', s), { recursive: true });

// GNU tar deterministic flags (ubuntu runners); bsdtar ignores unknown long opts poorly,
// so try GNU flags first and fall back to plain tar for local macOS builds.
function tgz(out, members) {
  const gnuFlags = ['--sort=name', '--mtime=@0', '--owner=0', '--group=0', '--numeric-owner'];
  try {
    run('tar', [...gnuFlags, '-czf', out, '-C', stage, ...members]);
  } catch {
    run('tar', ['-czf', out, '-C', stage, ...members]);
  }
  artifacts.push(out);
}

function zip(out, members) {
  // -X: strip extra file attrs for reproducibility; -q quiet
  run('zip', ['-qrX', out, ...members], { cwd: stage });
  artifacts.push(out);
}

for (const s of skills) {
  tgz(join(DIST, `batho-skills-${s}-${VER}.tar.gz`), [`skills/${s}`]);
}
tgz(join(DIST, `batho-skills-${VER}.tar.gz`), skills.map((s) => `skills/${s}`));
zip(join(DIST, `batho-skills-${VER}.zip`), skills.map((s) => `skills/${s}`));

const tgzDigest = sha256(join(DIST, `batho-skills-${VER}.tar.gz`));
const zipDigest = sha256(join(DIST, `batho-skills-${VER}.zip`));

// render pinned installers (T11): embed version + payload digests
for (const tpl of ['install.sh', 'install.ps1']) {
  const body = readFileSync(join(ROOT, tpl), 'utf8')
    .replace('@@BATHO_VERSION@@', TAG)
    .replace('@@SHA256_TAR@@', tgzDigest)
    .replace('@@SHA256_ZIP@@', zipDigest);
  writeFileSync(join(DIST, tpl), body, { mode: 0o755 });
  artifacts.push(join(DIST, tpl));
}

// CLI installer ships as-is (no templating — it installs batho via uv)
for (const f of ['install-batho.sh', 'install-batho.ps1']) {
  const src = join(ROOT, f);
  if (existsSync(src)) {
    writeFileSync(join(DIST, f), readFileSync(src), { mode: 0o755 });
    artifacts.push(join(DIST, f));
  }
}

// discovery index (.well-known/agent-skills/index.json, schema v0.2.0)
const index = {
  schema: 'discovery/0.2.0',
  name: 'batho',
  version: VER,
  skills: skills.map((s) => {
    const file = `batho-skills-${s}-${VER}.tar.gz`;
    const fm = readFileSync(join(SKILLS_DIR, s, 'SKILL.md'), 'utf8');
    const desc = (fm.match(/^description:\s*>?-?\s*\n?\s*(.+)$/m) || [, ''])[1].trim();
    return {
      name: s,
      type: 'archive',
      description: desc.slice(0, 300),
      url: `${BASE}/releases/download/${TAG}/${file}`,
      digest: `sha256:${sha256(join(DIST, file))}`,
    };
  }),
};
writeFileSync(join(DIST, 'index.json'), JSON.stringify(index, null, 2) + '\n');
artifacts.push(join(DIST, 'index.json'));

// sha256sums.txt over all distributable artifacts
const sums =
  artifacts.map((p) => `${sha256(p)}  ${p.split('/').pop()}`).join('\n') + '\n';
writeFileSync(join(DIST, 'sha256sums.txt'), sums);

console.log(`built ${artifacts.length} artifacts for ${TAG}:`);
console.log(artifacts.map((p) => '  ' + p.split('/').pop()).join('\n'));
