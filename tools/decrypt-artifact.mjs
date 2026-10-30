// Decrypts build artifacts. Two formats, detected by the first 8 bytes:
//   "MQAAR001"  AES-256-GCM, scrypt (written by encrypt-artifact.mjs; authenticated)
//   "Salted__"  legacy `openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt` (NOT authenticated; kept so that
//               artifacts built before the GCM rollout, retained 7 days, can still be read)
// Usage: ARTIFACT_PASSPHRASE=... node decrypt-artifact.mjs <input.enc> <output>
// The passphrase is read ONLY from ARTIFACT_PASSPHRASE (or a hidden prompt on a TTY); a third CLI argument is refused
// because command lines are visible in process lists and logs.
import { createDecipheriv, pbkdf2Sync, scryptSync } from 'node:crypto';
import { closeSync, createReadStream, createWriteStream, existsSync, openSync, readFileSync, readSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';

const args = process.argv.slice(2);
const [input, output] = args;
if (args.length !== 2 || !input || !output) {
  console.error('Usage: ARTIFACT_PASSPHRASE=... node decrypt-artifact.mjs <input.enc> <output> (the passphrase is never an argument)');
  process.exit(2);
}

async function passphrase() {
  if (process.env.ARTIFACT_PASSPHRASE) return process.env.ARTIFACT_PASSPHRASE;
  if (!process.stdin.isTTY) return '';
  process.stderr.write('Passphrase (hidden): ');
  return new Promise((resolve) => {
    let value = '';
    process.stdin.setRawMode(true);
    process.stdin.resume();
    process.stdin.on('data', function onData(chunk) {
      for (const ch of chunk.toString('utf8')) {
        if (ch === '\r' || ch === '\n' || ch === '\u0004') {
          process.stdin.setRawMode(false); process.stdin.pause(); process.stdin.off('data', onData);
          process.stderr.write('\n'); return resolve(value);
        }
        if (ch === '\u0003') process.exit(130);
        value = ch === '\u007f' ? value.slice(0, -1) : value + ch;
      }
    });
  });
}

const secret = await passphrase();
if (!secret) { console.error('ARTIFACT_PASSPHRASE is required.'); process.exit(2); }

if (existsSync(output)) { console.error('Output already exists; refusing to overwrite.'); process.exit(2); }
const size = statSync(input).size;
const fd = openSync(input, 'r');
const magic = Buffer.alloc(8);
readSync(fd, magic, 0, 8, 0);
const kind = magic.toString('latin1');

if (kind === 'MQAAR001') {
  if (secret.length < 24) { closeSync(fd); console.error('ARTIFACT_PASSPHRASE must have at least 24 characters.'); process.exit(2); }
  if (size < 52) { closeSync(fd); console.error('Invalid artifact container.'); process.exit(1); }
  const header = Buffer.alloc(36), tag = Buffer.alloc(16);
  readSync(fd, header, 0, 36, 0);
  readSync(fd, tag, 0, 16, size - 16);
  closeSync(fd);
  const key = scryptSync(secret, header.subarray(8, 24), 32, { N: 1 << 17, r: 8, p: 1, maxmem: 256 * 1024 * 1024 });
  const decipher = createDecipheriv('aes-256-gcm', key, header.subarray(24, 36));
  decipher.setAAD(header);
  decipher.setAuthTag(tag);
  try {
    // Plaintext is streamed to disk before the tag is checked; on any failure the output is deleted.
    const body = size > 52 ? createReadStream(input, { start: 36, end: size - 17 }) : Readable.from([]);
    await pipeline(body, decipher, createWriteStream(output, { flags: 'wx', mode: 0o600 }));
    console.log('OK ->', output, '(AES-256-GCM, authenticated)');
  } catch {
    rmSync(output, { force: true });
    console.error('Wrong passphrase, corrupted or tampered file.');
    process.exit(1);
  }
} else if (kind === 'Salted__') {
  closeSync(fd);
  console.error('Note: legacy openssl AES-256-CBC artifact (no integrity protection).');
  const data = readFileSync(input);
  const key = pbkdf2Sync(secret, data.subarray(8, 16), 600000, 48, 'sha256'); // 32-byte key + 16-byte IV, as openssl derives them
  const decipher = createDecipheriv('aes-256-cbc', key.subarray(0, 32), key.subarray(32));
  try {
    writeFileSync(output, Buffer.concat([decipher.update(data.subarray(16)), decipher.final()]), { flag: 'wx', mode: 0o600 });
    console.log('OK ->', output, '(legacy CBC)');
  } catch {
    rmSync(output, { force: true });
    console.error('Wrong passphrase or corrupted file.');
    process.exit(1);
  }
} else {
  closeSync(fd);
  console.error('Unknown artifact format.');
  process.exit(1);
}
