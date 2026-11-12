/** Keyboard/dock lockstep verdict from the numbers-only probe lines of an E2E run (owner QA 2026-11-12).
 *  Usage: node tools/kbd-lockstep.mjs <ios-perf.log>
 *  Reads `tx_kbd_event` (kind 1 show / 0 hide) and `tx_kbd_spacer_layout` (h = height laid out). While the keyboard is SHOWING the spacer height must never fall by more than
 *  TOLERANCE pt between two commits (it may only rise); while HIDING it must never rise. A fall while showing is the dock dropping under the keyboard (the measured bug).
 *  Prints one line per transition and exits 1 on a violation. Numbers only: nothing from the app's content travels here. */
import { readFileSync } from 'node:fs';
const TOLERANCE = 8;
const WINDOW_MS = 1200;
const rows = readFileSync(process.argv[2], 'utf8').split('\n').map((line) => {
  const m = /^(tx_kbd_event|tx_kbd_spacer_layout)_ms ms=([0-9.]+)(.*)$/.exec(line.trim());
  if (!m) return null;
  const kv = Object.fromEntries([...m[3].matchAll(/([a-z_]+)=([0-9.]+)/g)].map((x) => [x[1], Number(x[2])]));
  return { type: m[1], t: Number(m[2]), ...kv };
}).filter(Boolean);
let bad = 0, n = 0;
rows.forEach((row, i) => {
  if (row.type !== 'tx_kbd_event') return;
  n += 1;
  const end = row.t + WINDOW_MS;
  const layouts = rows.slice(i + 1).filter((r) => r.type === 'tx_kbd_spacer_layout' && r.t <= end && r.t >= row.t);
  let worst = 0, commits = layouts.length, prev = null;
  for (const r of layouts) {
    if (prev !== null) worst = Math.max(worst, row.kind === 1 ? prev - r.h : r.h - prev);
    prev = r.h;
  }
  const verdict = worst > TOLERANCE ? 'VIOLATION' : 'ok';
  if (verdict !== 'ok') bad += 1;
  console.log(`${row.kind === 1 ? 'show' : 'hide'} @${Math.round(row.t)}: commits=${commits} first=${layouts[0]?.h ?? '-'} last=${prev ?? '-'} worstWrongWayStep=${Math.round(worst)}pt ${verdict}`);
});
console.log(`transitions=${n} violations=${bad}`);
process.exit(bad ? 1 : 0);
