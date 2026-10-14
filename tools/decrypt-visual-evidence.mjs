/** Decrypt AES-256-GCM evidence locally. Never print secret or decrypted content. */
import { createDecipheriv, scryptSync } from 'node:crypto';
import { createReadStream, createWriteStream, openSync, readSync, statSync, rmSync, closeSync } from 'node:fs';
import { pipeline } from 'node:stream/promises';
const [input, output] = process.argv.slice(2);
const secret = process.env.ARTIFACT_PASSPHRASE;
if (!input || !output || !secret || secret.length < 24) {
  console.error('Paths and ARTIFACT_PASSPHRASE are required.');
  process.exit(2);
}
const size = statSync(input).size;
if (size <= 52) throw new Error('Invalid evidence container.');
const fd = openSync(input, 'r');
const header = Buffer.alloc(36), tag = Buffer.alloc(16);
readSync(fd, header, 0, 36, 0);
readSync(fd, tag, 0, 16, size - 16);
closeSync(fd);
if (header.subarray(0, 8).toString('ascii') !== 'MQAEV001') throw new Error('Invalid evidence format.');
const key = scryptSync(secret, header.subarray(8,24), 32, { N: 1 << 15, maxmem: 64 * 1024 * 1024 });
const decipher = createDecipheriv('aes-256-gcm', key, header.subarray(24,36));
decipher.setAuthTag(tag);
try {
  await pipeline(createReadStream(input, { start: 36, end: size - 17 }), decipher,
    createWriteStream(output, { flags: 'wx', mode: 0o600 }));
  console.log('Evidence decrypted locally. Handle plaintext as private data.');
} catch {
  rmSync(output, { force: true });
  console.error('Decryption/authentication failed.');
  process.exitCode = 1;
}
