// Tripwire: a public repo must never push raw Maestro screenshots or log artifacts.
import { readFileSync } from 'node:fs';
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
