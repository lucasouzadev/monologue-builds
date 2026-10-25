#!/usr/bin/env node
/**
 * Performance gate (owner plan A8). Reads the numbers-only transition log an E2E run prints (`tx_<name>_<step>_ms ms=<n> [frames=… jank=… worst=… r_<component>=…]`),
 * takes the MEDIAN per metric (one run repeats a transition several times and a CI machine is noisy), and compares it with `maestro/perf-budget.json`.
 *
 *   node tools/perf-gate.mjs <perf.log> <ios|android> [--enforce]
 *
 * Budget file: { "<platform>": { "<metric>": { "max": <ms or count>, "note": "…" } } }. A metric without a budget is only reported ("no budget"): record its
 * numbers first, then add a limit (about 25 % above a healthy run). Without --enforce the gate never fails the job, it prints REGRESSION lines; with --enforce a
 * REGRESSION exits 1. Counts (`jank`, `r_*` renders) use the same file under the names `<metric>.jank` / `<metric>.r_<component>`.
 * Content-free by construction: the log only has durations and counts.
 */
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const [, , logPath, platform, ...flags] = process.argv;
if (!logPath || !['ios', 'android'].includes(platform ?? '')) {
  console.error('usage: perf-gate.mjs <perf.log> <ios|android> [--enforce]');
  process.exit(2);
}
const enforce = flags.includes('--enforce');
const budgetPath = join(dirname(fileURLToPath(import.meta.url)), '..', 'maestro', 'perf-budget.json');
const budget = existsSync(budgetPath) ? (JSON.parse(readFileSync(budgetPath, 'utf8'))[platform] ?? {}) : {};
const lines = existsSync(logPath) ? readFileSync(logPath, 'utf8').split('\n') : [];

const samples = new Map();
const add = (key, value) => { if (Number.isFinite(value)) (samples.get(key) ?? samples.set(key, []).get(key)).push(value); };
for (const line of lines) {
  const match = /^(tx_[a-z_]+_ms) ms=([0-9.]+)((?: [a-z_]+=[0-9]+)*)$/.exec(line.trim());
  if (!match) continue;
  const metric = match[1];
  add(metric, Number(match[2]));
  for (const pair of match[3].trim().split(' ').filter(Boolean)) {
    const [name, value] = pair.split('=');
    add(`${metric}.${name}`, Number(value));
  }
}
const median = (values) => { const sorted = [...values].sort((a, b) => a - b); const mid = sorted.length >> 1; return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2; };

let regressions = 0;
console.log(`Performance gate (${platform}, ${enforce ? 'enforcing' : 'report only'}): ${samples.size} metrics`);
for (const [metric, values] of [...samples.entries()].sort(([a], [b]) => a.localeCompare(b))) {
  const value = median(values);
  const limit = budget[metric]?.max;
  const verdict = limit === undefined ? 'no budget' : value <= limit ? `ok (<= ${limit})` : `REGRESSION (> ${limit})`;
  if (verdict.startsWith('REGRESSION')) regressions += 1;
  console.log(`${metric.padEnd(58)} median=${String(Math.round(value * 10) / 10).padStart(8)} n=${String(values.length).padStart(2)}  ${verdict}`);
}
for (const metric of Object.keys(budget)) if (!samples.has(metric)) console.log(`${metric.padEnd(58)} not measured in this run`);
if (regressions > 0) console.log(`::${enforce ? 'error' : 'warning'}::${regressions} performance budget(s) exceeded`);
process.exit(enforce && regressions > 0 ? 1 : 0);
