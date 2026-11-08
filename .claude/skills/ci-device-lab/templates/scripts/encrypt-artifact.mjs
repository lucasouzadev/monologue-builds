#!/usr/bin/env node
// Encrypt a file with AES-256-GCM (scrypt key). Passphrase only from ARTIFACT_PASSPHRASE (>= 24 chars).
// Usage: node encrypt-artifact.mjs <in> <out.enc>     Format: "AKENC001" | salt16 | nonce12 | ciphertext | tag16
import { readFileSync, writeFileSync } from 'node:fs';
import { randomBytes, scryptSync, createCipheriv } from 'node:crypto';
const [inp, out] = process.argv.slice(2);
const pass = process.env.ARTIFACT_PASSPHRASE || '';
if (!inp || !out) { console.error('usage: encrypt-artifact.mjs <in> <out.enc>'); process.exit(2); }
if (pass.length < 24) { console.error('ARTIFACT_PASSPHRASE must have at least 24 characters'); process.exit(1); }
const magic = Buffer.from('AKENC001'); const salt = randomBytes(16); const nonce = randomBytes(12);
const key = scryptSync(pass, salt, 32, { N: 2 ** 17, r: 8, p: 1, maxmem: 256 * 1024 * 1024 });
const c = createCipheriv('aes-256-gcm', key, nonce); c.setAAD(Buffer.concat([magic, salt, nonce]));
const body = Buffer.concat([c.update(readFileSync(inp)), c.final()]);
writeFileSync(out, Buffer.concat([magic, salt, nonce, body, c.getAuthTag()]));
console.log(`encrypted ${inp} -> ${out}`);
