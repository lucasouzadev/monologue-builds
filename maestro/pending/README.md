# Flows pending triage (not run by CI)

Authored 2026-10-19 without simulator access and run once on Android (build run 39257622593, staging OTA).
They fail, and the failing steps below are all the public log shows. The screenshots are encrypted, so triage
needs the decrypted evidence of the runs named here. Move a flow back to `maestro/flows/` once it passes.

| Flow | Last Android result (run) | Failing step |
| --- | --- | --- |
| 89-recycle-bin | FAIL (39265459338) | `conversation-selection-bar` not visible after long-press on the row (then "Delete") |
| 90-edit-message | FAIL (39265459338) | `.*Corrected wording.*` not visible after Edit > erase > type > "Save edit" |
| 91-search-filters | FAIL (39265459338, 39262875204) | `search-chip-favorite` not visible after More creation options > Wide search |

Passing in the same runs and left in `maestro/flows/`: 88-draft-relaunch, 92-persistence-relaunch.
Flow 89 also failed once earlier inside support/new-chat.yaml ("New conversation" not visible, run 39262875204); it passed that step on the next run, so that was likely emulator flakiness.
