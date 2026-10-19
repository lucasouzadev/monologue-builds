# Flows pending triage (not run by CI)

Flows that do not pass yet live here, out of the numeric suite. Move one back to `maestro/flows/` once it passes.

## 89-recycle-bin
Journey: swipe a fixture conversation to delete, find it in the Recycle Bin sheet, restore it, see it on Home.
Android result, run 39292595375 (and 39290444986): the row is still on Home after `swipe` RIGHT from the row text
(`swipe-delete-action` never appears; the tap on it was made optional and warned "not found").
What the code says (apps/mobile/src/features/home/swipe-to-delete.tsx, home-screen.tsx:302): the pan gesture activates with
`activeOffsetX(12)`, fails on a left swipe and on |dy| > 12, and `SwipeToDelete` wraps the row only when `onSwipeDelete` is set and no selection is active.
So the gesture is a swipe to the RIGHT; what is not known is why the Maestro swipe does not trigger it (swipe speed/length, or the row's Pressable winning the touch).
Next step: read the screenshots of those runs (decrypt, see SECURE_QA_ARTIFACTS.md) or try `swipe` with explicit start/end percentages and `duration`.
Other deletion paths for reference: Android row long-press opens a preview whose menu "Delete" asks a system Alert ("Move to Recycle Bin?"); on iOS the row menu is native and not reachable by Maestro.
