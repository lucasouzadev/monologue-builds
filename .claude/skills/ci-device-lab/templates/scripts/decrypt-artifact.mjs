#!/usr/bin/env node
// Decrypt a file made by encrypt-artifact.mjs. Run on a PRIVATE machine.
// read -rs ARTIFACT_PASSPHRASE; export ARTIFACT_PASSPHRASE; node decrypt-artifact.mjs in.enc out; unset ARTIFACT_PASSPHRASE
import { readFileSync, writeFileSync } from 'node:fs';
import { scryptSync, createDecipheriv } from 'node:crypto';
const [inp, out] = process.argv.slice(2);
const pass = process.env.ARTIFACT_PASSPHRASE || '';
if (!inp || !out || !pass) { console.error('usage: ARTIFACT_PASSPHRASE=... decrypt-artifact.mjs <in.enc> <out>'); process.exit(2); }
const b = readFileSync(inp);
if (b.subarray(0, 8).toString() !== 'AKENC001') { console.error('not an AKENC001 file'); process.exit(1); }
const salt = b.subarray(8, 24), nonce = b.subarray(24, 36), tag = b.subarray(b.length - 16), body = b.subarray(36, b.length - 16);
const key = scryptSync(pass, salt, 32, { N: 2 ** 17, r: 8, p: 1, maxmem: 256 * 1024 * 1024 });
const d = createDecipheriv('aes-256-gcm', key, nonce); d.setAAD(b.subarray(0, 36)); d.setAuthTag(tag);
writeFileSync(out, Buffer.concat([d.update(body), d.final()]));
console.log(`decrypted ${inp} -> ${out}`);
