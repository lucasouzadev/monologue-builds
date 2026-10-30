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

// Build artifacts: authenticated encryption only, and the passphrase never on a command line (SEC-23).
const wfDir = new URL('../.github/workflows/', import.meta.url);
for (const file of readdirSync(wfDir).filter((f) => f.endsWith('.yml'))) {
  const text = readFileSync(new URL(file, wfDir), 'utf8');
  assert(!/openssl\s+enc\b/.test(text), `Unauthenticated openssl enc is forbidden for artifacts: ${file}`);
  assert(!/decrypt-artifact\.mjs[^\n]*\$\{?ARTIFACT_PASSPHRASE/.test(text),
    `Passphrase must come from the environment, never a command-line argument: ${file}`);
}
const buildYml = readFileSync(new URL('build.yml', wfDir), 'utf8');
assert((buildYml.match(/encrypt-artifact\.mjs/g) || []).length === 3, 'build.yml must encrypt the APK, its link file and the IPA with encrypt-artifact.mjs');
console.log('PASS: build artifacts use AES-256-GCM tooling; no passphrase on command lines');

// SEC-22: the logs are public; build.yml must never print the APK link, only store it in the encrypted artifact.
const buildSrc = readFileSync(new URL('../.github/workflows/build.yml', import.meta.url), 'utf8');
for (const line of buildSrc.split('\n')) {
  if (/(echo|aws s3 presign)[^\n]*(APK:|APK \(signed|Stable APK|presign)/.test(line)) {
    assert(/apk-link\.txt|link="\$\(aws s3 presign/.test(line), `APK link must not be printed to the public log: ${line.trim().slice(0, 80)}`);
  }
}
assert(buildSrc.includes('::add-mask::') && buildSrc.includes('apk-link.txt.enc'), 'build.yml must mask the APK link and ship it encrypted');
console.log('PASS: APK link is masked and only stored in the encrypted artifact');
