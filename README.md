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
