/**
 * Encrypt a private CI evidence archive before upload to a PUBLIC GitHub repo.
 * Format: magic(8) + salt(16) + nonce(12) + AES-256-GCM(ciphertext) + tag(16).
 * Private passphrase MUST be in ARTIFACT_PASSPHRASE, never a CLI arg or repo variable.
 * Refuses missing/short passphrases. Authenticated encryption detects modification.
 */
import { createCipheriv, randomBytes, scryptSync } from 'node:crypto';
import { createReadStream, createWriteStream, rmSync } from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { Transform } from 'node:stream';

const [input, output] = process.argv.slice(2);
const secret = process.env.ARTIFACT_PASSPHRASE;
if (!input || !output || !secret || secret.length < 24) {
  console.error('Evidence encryption unavailable: missing paths or required strong secret.');
  process.exit(2);
}
const magic = Buffer.from('MQAEV001', 'ascii');
const salt = randomBytes(16), nonce = randomBytes(12);
const key = scryptSync(secret, salt, 32, { N: 1 << 15, maxmem: 64 * 1024 * 1024 });
const cipher = createCipheriv('aes-256-gcm', key, nonce);
const header = Buffer.concat([magic, salt, nonce]);
let started = false;
const prepend = new Transform({
  transform(chunk, _enc, cb) {
    if (!started) { this.push(header); started = true; }
    this.push(chunk);
    cb();
  },
  flush(cb) {
    if (!started) this.push(header);
    this.push(cipher.getAuthTag());
    cb();
  },
});
try {
  await pipeline(createReadStream(input), cipher, prepend, createWriteStream(output, { mode: 0o600, flags: 'wx' }));
  console.log('Encrypted QA evidence prepared (no plaintext diagnostics published).');
} catch {
  rmSync(output, { force: true });
  console.error('Evidence encryption failed; refusing upload.');
  process.exitCode = 1;
}
