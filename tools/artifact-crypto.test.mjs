// Synthetic-only tests for encrypt-artifact.mjs / decrypt-artifact.mjs. Run: node --test tools/
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, readFileSync, existsSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';

const here = new URL('.', import.meta.url).pathname;
const run = (tool, args, pass) => spawnSync('node', [join(here, tool), ...args], {
  encoding: 'utf8',
  env: { PATH: process.env.PATH, ...(pass === undefined ? {} : { ARTIFACT_PASSPHRASE: pass }) },
  stdin: 'ignore',
});
const enc = (a, p) => run('encrypt-artifact.mjs', a, p);
const dec = (a, p) => run('decrypt-artifact.mjs', a, p);
const PASS = 'synthetic-passphrase-0123456789abcdef';

function fixture() {
  const dir = mkdtempSync(join(tmpdir(), 'artifact-crypto-'));
  const plain = join(dir, 'plain.bin');
  writeFileSync(plain, Buffer.concat([Buffer.from('synthetic payload '), randomBytes(200_000)]));
  return { dir, plain, f: (n) => join(dir, n) };
}

test('GCM round trip', () => {
  const { dir, plain, f } = fixture();
  assert.equal(enc([plain, f('a.enc')], PASS).status, 0);
  assert.equal(readFileSync(f('a.enc')).subarray(0, 8).toString(), 'MQAAR001');
  assert.equal(dec([f('a.enc'), f('a.out')], PASS).status, 0);
  assert.deepEqual(readFileSync(f('a.out')), readFileSync(plain));
  rmSync(dir, { recursive: true });
});

test('GCM is randomized (fresh salt and nonce)', () => {
  const { dir, plain, f } = fixture();
  enc([plain, f('1.enc')], PASS); enc([plain, f('2.enc')], PASS);
  assert.notDeepEqual(readFileSync(f('1.enc')).subarray(8, 36), readFileSync(f('2.enc')).subarray(8, 36));
  rmSync(dir, { recursive: true });
});

test('empty file round trips', () => {
  const { dir, f } = fixture();
  writeFileSync(f('empty'), '');
  assert.equal(enc([f('empty'), f('e.enc')], PASS).status, 0);
  assert.equal(dec([f('e.enc'), f('e.out')], PASS).status, 0);
  assert.equal(readFileSync(f('e.out')).length, 0);
  rmSync(dir, { recursive: true });
});

for (const [label, where] of [['ciphertext', 100], ['salt', 10], ['nonce', 30], ['last magic byte', 7], ['tag', -1]]) {
  test(`tampered ${label} is rejected and leaves no output`, () => {
    const { dir, plain, f } = fixture();
    enc([plain, f('t.enc')], PASS);
    const b = readFileSync(f('t.enc'));
    b[where < 0 ? b.length + where : where] ^= 1;
    writeFileSync(f('t.enc'), b);
    const r = dec([f('t.enc'), f('t.out')], PASS);
    assert.notEqual(r.status, 0);
    assert.equal(existsSync(f('t.out')), false);
    rmSync(dir, { recursive: true });
  });
}

test('truncated container is rejected', () => {
  const { dir, plain, f } = fixture();
  enc([plain, f('t.enc')], PASS);
  writeFileSync(f('t.enc'), readFileSync(f('t.enc')).subarray(0, 40));
  assert.notEqual(dec([f('t.enc'), f('t.out')], PASS).status, 0);
  assert.equal(existsSync(f('t.out')), false);
  rmSync(dir, { recursive: true });
});

test('wrong passphrase is rejected (GCM and legacy)', () => {
  const { dir, plain, f } = fixture();
  enc([plain, f('a.enc')], PASS);
  assert.notEqual(dec([f('a.enc'), f('a.out')], PASS + 'x').status, 0);
  assert.equal(existsSync(f('a.out')), false);
  const o = spawnSync('openssl', ['enc', '-aes-256-cbc', '-pbkdf2', '-iter', '600000', '-salt', '-pass', 'env:P', '-in', plain, '-out', f('l.enc')], { env: { PATH: process.env.PATH, P: PASS } });
  assert.equal(o.status, 0);
  assert.notEqual(dec([f('l.enc'), f('l.out')], PASS + 'x').status, 0);
  assert.equal(existsSync(f('l.out')), false);
  rmSync(dir, { recursive: true });
});

test('legacy openssl CBC artifacts are still read', () => {
  const { dir, plain, f } = fixture();
  const o = spawnSync('openssl', ['enc', '-aes-256-cbc', '-pbkdf2', '-iter', '600000', '-salt', '-pass', 'env:P', '-in', plain, '-out', f('l.enc')], { env: { PATH: process.env.PATH, P: PASS } });
  assert.equal(o.status, 0);
  assert.equal(readFileSync(f('l.enc')).subarray(0, 8).toString(), 'Salted__');
  const r = dec([f('l.enc'), f('l.out')], PASS);
  assert.equal(r.status, 0);
  assert.deepEqual(readFileSync(f('l.out')), readFileSync(plain));
  rmSync(dir, { recursive: true });
});

test('missing or short passphrase fails closed', () => {
  const { dir, plain, f } = fixture();
  assert.equal(enc([plain, f('m.enc')], undefined).status, 2);
  assert.equal(enc([plain, f('s.enc')], 'short').status, 2);
  assert.equal(enc([plain, f('s23.enc')], 'x'.repeat(23)).status, 2);
  assert.equal(existsSync(f('m.enc')) || existsSync(f('s.enc')) || existsSync(f('s23.enc')), false);
  enc([plain, f('a.enc')], PASS);
  assert.equal(dec([f('a.enc'), f('a.out')], undefined).status, 2);
  assert.equal(dec([f('a.enc'), f('a.out')], 'short').status, 2);
  assert.equal(existsSync(f('a.out')), false);
  rmSync(dir, { recursive: true });
});

test('the passphrase as a command-line argument is refused', () => {
  const { dir, plain, f } = fixture();
  enc([plain, f('a.enc')], PASS);
  const r = dec([f('a.enc'), f('a.out'), PASS], PASS);
  assert.equal(r.status, 2);
  assert.equal(existsSync(f('a.out')), false);
  assert.equal(enc([plain, f('b.enc'), PASS], PASS).status, 2);
  rmSync(dir, { recursive: true });
});

test('existing output is never overwritten or deleted', () => {
  const { dir, plain, f } = fixture();
  enc([plain, f('a.enc')], PASS);
  writeFileSync(f('keep'), 'keep me');
  assert.equal(dec([f('a.enc'), f('keep')], PASS).status, 2);
  assert.equal(enc([plain, f('keep')], PASS).status, 2);
  assert.equal(readFileSync(f('keep'), 'utf8'), 'keep me');
  rmSync(dir, { recursive: true });
});

test('the passphrase never appears in tool output', () => {
  const { dir, plain, f } = fixture();
  const a = enc([plain, f('a.enc')], PASS), b = dec([f('a.enc'), f('a.out')], PASS), c = dec([f('a.enc'), f('a.out2')], PASS + 'x');
  for (const r of [a, b, c]) assert(!(r.stdout + r.stderr).includes(PASS));
  rmSync(dir, { recursive: true });
});
