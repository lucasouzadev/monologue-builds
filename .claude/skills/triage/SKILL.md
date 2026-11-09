---
name: triage
description: Turns a message with several asks (a list, a QA round, feedback with many points, "e também...") into a prioritized work list - small items batched and done fast, large items given spec/plan options before any code. Use when the owner sends 3+ distinct requests, a bug list, a QA report, review comments, or says "prioriza", "lista", "o que faço primeiro".
---

# Triage

The owner sends everything at once, in the order it came to mind. You turn it into the order it should be **done**.

## 1. Split
One line per distinct ask, in the owner's words (short). Merge duplicates; split items that hide two changes. Include asks from attached media (skill `media-investigation`) and from the handoff "sobrou" list if the owner says "e o resto".

## 2. Size and score each item
| Field | Values |
|---|---|
| Size | **XS** (≤ 15 min, one file, no decision) · **S** (≤ 1 h, clear fix) · **M** (half day, several files or one decision) · **L** (needs spec/plan, architecture, data or UX decision) |
| Impact | blocks the user / data or security risk / visible defect / polish |
| Risk | touches money, auth, data, migrations, release, public repo → high |
| Depends on | other item IDs or an owner decision |

## 3. Order
1. **Blockers and risk first:** data loss, security, privacy, broken release, anything that blocks testing.
2. **Quick wins batch:** all XS/S items with no open decision, grouped by area/file so one pass and one test run covers them.
3. **Large items:** for each L (and M with a decision), do not start coding. Offer 2–3 options (smallest viable, recommended, ideal) with cost and risk; recommend one; when approved, write a short spec/plan (project template, task contract) before code.
4. **Parked:** unclear, out of scope or blocked items, each with the single question that unblocks it.

## 4. Present (caveman, ≤ 15 lines)
```
Agora (rápidos, 1 lote): #2 #5 #6 — ~40 min, 1 rodada de teste
Antes deles: #4 (risco: vaza dado)
Precisam de decisão: #1 → A) mínimo  B) recomendado  C) ideal
Parado: #3 — falta saber X
```
Then ask **one** question: approve the order (and the option for each L). The approval gate still applies before writes; an approved order is recorded in the handoff with the IDs.

## QA rounds on a device
When the list is the owner's device QA ("rodada", "round", "retest"):
- Give each item a stable ID `R<round>.<n>`; keep it across retests and record `retest N` and `occurrence N`.
- Second occurrence of the same symptom → skill `systematic-debug` and the project rework ledger, not another patch.
- Before fixing, run `.claude/agent-kit/hotspots.py <files>`: a hotspot (many earlier fix commits) gets a regression test first.
- Group items by **shared cause**, not by screen; one cause fixed = several IDs closed, each with its own evidence.
- Close the round with: fixed (evidence) / still open / needs device (the owner's physical test list).

## 5. While executing
- Close quick wins in one batch, one commit per logical change, evidence per item (PASS/FAIL/BLOCKED).
- Re-triage when something new arrives or an item turns out bigger than its size (say so; do not silently grow an XS into an L).
- At the end, report by ID: done / pending / parked, and move leftovers to the handoff.
