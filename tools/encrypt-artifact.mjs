/**
 * Encrypt a build artifact (APK/IPA) before upload to a PUBLIC GitHub repo.
 * Format "MQAAR001": magic(8) + salt(16) + nonce(12) + AES-256-GCM ciphertext + tag(16).
 * The header is bound to the tag as additional authenticated data, so any change to it is detected.
 * Key: scrypt(N=2^17, r=8, p=1). Passphrase ONLY in ARTIFACT_PASSPHRASE (>= 24 chars); never a CLI argument.
 * Usage: ARTIFACT_PASSPHRASE=... node encrypt-artifact.mjs <input> <output.enc>
 */
import { createCipheriv, randomBytes, scryptSync } from 'node:crypto';
import { createReadStream, createWriteStream, existsSync, rmSync } from 'node:fs';
import { pipeline } from 'node:stream/promises';

const args = process.argv.slice(2);
const [input, output] = args;
const secret = process.env.ARTIFACT_PASSPHRASE;
if (args.length !== 2 || !input || !output) {
  console.error('Usage: ARTIFACT_PASSPHRASE=... node encrypt-artifact.mjs <input> <output.enc> (the passphrase is never an argument)');
  process.exit(2);
}
if (!secret || secret.length < 24) {
  console.error('Artifact encryption refused: ARTIFACT_PASSPHRASE is missing or shorter than 24 characters.');
  process.exit(2);
}
if (existsSync(output)) { console.error('Output already exists; refusing to overwrite.'); process.exit(2); }
const salt = randomBytes(16), nonce = randomBytes(12);
const header = Buffer.concat([Buffer.from('MQAAR001', 'ascii'), salt, nonce]);
const key = scryptSync(secret, salt, 32, { N: 1 << 17, r: 8, p: 1, maxmem: 256 * 1024 * 1024 });
const cipher = createCipheriv('aes-256-gcm', key, nonce);
cipher.setAAD(header);
async function* sealed(source) {
  yield header;
  for await (const chunk of source) yield cipher.update(chunk);
  yield cipher.final();
  yield cipher.getAuthTag();
}
try {
  await pipeline(createReadStream(input), sealed, createWriteStream(output, { mode: 0o600, flags: 'wx' }));
  console.log('OK -> encrypted (AES-256-GCM)');
} catch {
  rmSync(output, { force: true });
  console.error('Artifact encryption failed; refusing upload.');
  process.exitCode = 1;
}
