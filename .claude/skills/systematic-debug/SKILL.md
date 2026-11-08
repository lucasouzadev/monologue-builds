---
name: systematic-debug
description: Four-step root-cause protocol for bugs, regressions, defects that came back after a fix, or behaviour only seen on a device or video. Use when the cause is not obvious, when one fix already failed, or when the report is only a symptom.
---

# Systematic debugging

Guessing costs hours; root cause costs minutes. Detail: `docs/agents/standard/MODES.md#fixer`, project rework ledger.

1. **Boundaries.** Where the data/behaviour enters, leaves, and every independent driver in between (UI, state, API, auth/RLS, worker, native view, timer, animation, layout pass). Which side is wrong?
2. **Reproduce and instrument.** Failing test, capture, or probes that print numbers at the boundaries. No reproduction, no root cause. Tests must never fake an event the platform does not emit.
3. **Isolate.** The surviving hypothesis explains **all** symptoms, including ones not reported. "Worked before" → `git log -S` / bisect. Library involved → read the installed version's source. Same pattern elsewhere? Remove probes afterwards.
4. **One owner, one fix.** Smallest change; one module owns the behaviour (delete competing paths); the failing test now passes; neighbours unchanged; canonical checks green; guard added; ledger row updated.

Rules: **two failed attempts = stop**, bring evidence and a recommendation, never a third attempt of the same kind. One round = one root cause; other bugs go to a list. Present cause + planned change and wait for approval before editing.
