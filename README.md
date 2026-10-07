# monologue-builds

Public CI repository for the private `lucasouzadev/monologue` app: native builds, OTA updates and Maestro E2E on
GitHub-hosted runners. It contains **no app source** (the workflows check the private repo out with `SOURCE_REPO_TOKEN`).
Everything is `workflow_dispatch` (manual); nothing runs on push/PR/schedule.

| Workflow | Purpose | Needs owner permission |
| --- | --- | --- |
| `ota.yml` | JS/asset-only EAS Update to channel `development` / `preview` / `production`, platform `all/ios/android` | No (standing authorization) |
| `build.yml` | Signed native builds (APK, IPA → TestFlight), encrypted artifacts | **Yes, every execution** |
| `e2e-android.yml` | Installs the APK of a `build.yml` run, warms the OTA, runs Maestro flows on an emulator (light + dark pass) | No (no compile) |
| `e2e-ios.yml` | Compiles (cached) an iOS **simulator** build and runs the Maestro flows | **Yes** (native build) |
| `android-smoke.yml` | Tiny launch-and-create smoke test of the APK | No |

Helper: `tools/ci.sh` (REST only; `gh workflow run` does not work in Claude Code cloud sessions).
Maestro flows: `maestro/flows/NN-*.yaml`, runner `maestro/run.sh`, Android harness `maestro/android-e2e.sh`.
Screenshots of the latest E2E are force-pushed to branches `screens-android` and `screens-ios` of this repo.

Full operating guide for agents: `docs/agents/TOOLING_AND_E2E_RUNBOOK.md` in the private repo.

## Flows 16–25 (the 2026-10-07 branch)

They run in order after 00–15 and share state through one conversation, "Novidades", created by 16 and deleted by 24 (so the older flows
and the dark pass keep their data). They need the **baseline 08** binary and an OTA published with `native_baseline=08`.

| Flow | What it covers |
| --- | --- |
| 16 | create "Novidades", three messages (one with a link), Favorite (More face) and Pin (chip) from the message menu |
| 17 | Favourites Focus (header "…" → "Favorites · N"), tap a message to land on it |
| 18 | conversation panel: Pinned / Favorites lists, Media tab with the real link, jump to the message, Activity |
| 19 | Wide search with the Favorites and Pinned chips |
| 20 | Merge two messages (one favourite): selection, reveal, combined message |
| 21 | Settings > Font: Lora, JetBrains Mono, Atkinson, Inter, Home and chat in Inter, back to the system font |
| 22 | Profile > Activity: display-only heatmap, calendar day selection |
| 23 | Spatial: "+", footer buttons, Delete balloon (dismiss, then confirm) |
| 24 | Home selection: the pill asks before deleting (back out, then confirm); deletes "Novidades" |
| 25 | composer "+" menu (Camera, Scan document), the app's camera (options, flash, flip, shutter, close), the system scanner |

Camera and scanner limits on CI: the iOS simulator and the AOSP Android emulator have no camera scene, and the Android emulator image
has no Google Play services, so the ML Kit scanner can only report a failure there; they are judged on a real device.
