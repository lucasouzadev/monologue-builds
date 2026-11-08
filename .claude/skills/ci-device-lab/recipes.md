# Recipes — which template for which need

Copy into the CI repo: `templates/workflows/*.yml` → `.github/workflows/`, `templates/scripts/` → `scripts/`, `templates/maestro/` → `maestro/`. Take only what the project needs.

| Need | Template | Runner | Secrets (see secrets.md) | Real build? |
|---|---|---|---|---|
| Lint workflows + flows on every PR | `check.yml` | ubuntu | none | no |
| Installable Android APK (Expo prebuild, RN, Capacitor, native) | `android-apk.yml` | ubuntu | keystore (optional), `ARTIFACT_PASSPHRASE` if public | debug: test build · release signed with store key: **real** |
| iOS app for the simulator (no Mac, no Apple account) | `ios-simulator.yml` | macOS | none | no |
| Maestro on Android emulator | `e2e-android.yml` (uses an `android-apk` run) | ubuntu + KVM | `E2E_*` optional, `ARTIFACT_PASSPHRASE` | no |
| Maestro on iOS simulator | `e2e-ios.yml` | macOS | `E2E_*` optional, `ARTIFACT_PASSPHRASE` | no |
| Expo OTA update | `expo-ota.yml` | ubuntu | `EXPO_TOKEN` | no, but reaches users: staging channel first, `production` behind an Environment |
| Expo build, cloud or `--local` | `eas-build.yml` | ubuntu / macOS | `EXPO_TOKEN` (+ signing for local) | store/internal profiles: **real** (guard input) |
| TestFlight upload without EAS | `ios-testflight.yml` | macOS | ASC API key, team id | **real** (Environment `release` + typed confirmation) |
| Private source, public CI | add `SOURCE_REPO` variable + `SOURCE_DEPLOY_KEY` | — | deploy key | — |

## Typical journeys
- **"I only have Windows/Linux and an Android phone"**: `android-apk` (debug) → download the artifact (decrypt locally if public) → install. iOS: `ios-simulator` + `e2e-ios` for screenshots; TestFlight later with an Apple Developer account.
- **"I have no phone at all"**: `e2e-android` + `e2e-ios` with smoke flows; review screenshots from the (decrypted) evidence.
- **"Expo app, ship fast"**: `expo-ota` to `preview` → test → `production`; `eas-build` only when native code changes.
- **"Out of Actions minutes on a private repo"**: Layout B (architecture.md), same templates.

## Maestro tips
- Prefer `testID` / accessibility ids over visible text; texts change with locale and copy.
- First real run: smoke flow only; expect to fix selectors and timeouts; then add flows.
- Flows read, they do not change data (unless a dedicated staging backend exists).
- Pin the CLI version on the runner when stability matters (`MAESTRO_VERSION` env before the install script).
- iOS simulators have no real push, camera or biometrics: test those on a device.

## Agent workflow
Dispatch, read the job summary (flow names only), download and decrypt evidence **locally** when needed, fix, rerun the smallest flow that fails; full suite once at the end. At most one run per platform in flight. Never dispatch a real build without the owner's order for that run.
