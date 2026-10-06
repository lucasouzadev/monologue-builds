// Decrypts the .enc build artifacts (openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt) without needing openssl.
// Usage: node decrypt-artifact.mjs <input.enc> <output> [passphrase]   (or set ARTIFACT_PASSPHRASE; otherwise it asks)
import { createDecipheriv, pbkdf2Sync } from 'node:crypto';
import { createInterface } from 'node:readline';
import { readFileSync, writeFileSync } from 'node:fs';

const [input, output, argPass] = process.argv.slice(2);
if (!input || !output) { console.error('Usage: node decrypt-artifact.mjs <input.enc> <output> [passphrase]'); process.exit(2); }

async function passphrase() {
  if (argPass) return argPass;
  if (process.env.ARTIFACT_PASSPHRASE) return process.env.ARTIFACT_PASSPHRASE;
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => rl.question('Passphrase: ', (answer) => { rl.close(); resolve(answer); }));
}

const data = readFileSync(input);
if (data.subarray(0, 8).toString('latin1') !== 'Salted__') { console.error('Not an openssl "Salted__" file.'); process.exit(1); }
const salt = data.subarray(8, 16);
const key = pbkdf2Sync(await passphrase(), salt, 600000, 48, 'sha256'); // 32-byte key + 16-byte IV, as openssl derives them
const decipher = createDecipheriv('aes-256-cbc', key.subarray(0, 32), key.subarray(32));
try {
  writeFileSync(output, Buffer.concat([decipher.update(data.subarray(16)), decipher.final()]));
  console.log('OK ->', output);
} catch { console.error('Wrong passphrase or corrupted file.'); process.exit(1); }
