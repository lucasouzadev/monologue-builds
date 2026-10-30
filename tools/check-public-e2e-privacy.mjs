// Tripwire: a public repo must never push raw Maestro screenshots or log artifacts.
import { readFileSync, readdirSync } from 'node:fs';
import assert from 'node:assert/strict';
for (const platform of ['android', 'ios']) {
  const workflow = readFileSync(new URL(`../.github/workflows/e2e-${platform}.yml`, import.meta.url), 'utf8');
  assert(!/git push[^\n]*screens-(android|ios)/.test(workflow),
    `Public screenshot branch publication is forbidden: ${platform}`);
  assert(workflow.includes('visual-evidence.tgz.enc'),
    `Only encrypted QA evidence may be uploaded: ${platform}`);
  assert(workflow.includes('encrypt-visual-evidence.mjs'),
    `Evidence encryption is required: ${platform}`);
  assert(workflow.includes('ARTIFACT_PASSPHRASE: ${{ secrets.M2_QA_EVIDENCE_PASSPHRASE }}'),
    `Encryption must fail closed without a GitHub secret: ${platform}`);
  assert(!/path:\s*[^\n]*\.(?:png|jpg|mp4|log|xml)(?:\s|$)/im.test(workflow),
    `Raw screenshot/video/log upload forbidden: ${platform}`);
}
console.log('PASS: no plaintext visual artifact or public screenshot branches in E2E workflows');

// Workflow hardening tripwires (SEC-24/SEC-25).
const dir = new URL('../.github/workflows/', import.meta.url);
const workflows = readdirSync(dir).filter((f) => f.endsWith('.yml'));
for (const file of workflows) {
  const text = readFileSync(new URL(file, dir), 'utf8');
  for (const [, ref] of text.matchAll(/^\s*(?:-\s+)?uses:\s*(\S+)/gm)) {
    if (ref.startsWith('./')) continue;
    assert(/@[0-9a-f]{40}$/.test(ref), `Action must be pinned to a full commit SHA (${file}): ${ref}`);
  }
  assert(!/^\s*contents:\s*write\b/m.test(text), `contents: write is not needed, nothing pushes: ${file}`);
}
const build = readFileSync(new URL('build.yml', dir), 'utf8');
assert(!/Remove signing[^\n]*\n\s*if:[^\n]*steps\.signing/.test(build),
  'Signing cleanup must run on always(), not only after a successful restore');
const ota = readFileSync(new URL('ota.yml', dir), 'utf8');
assert(/native_baseline:[\s\S]*?default: select-baseline/.test(ota),
  'ota.yml native_baseline must default to select-baseline');
assert((ota.match(/BASELINE" = select-baseline/g) || []).length === 2,
  'Both OTA jobs must reject select-baseline');
console.log(`PASS: ${workflows.length} workflows: SHA-pinned actions, read-only contents, always() cleanup, explicit OTA baseline`);
