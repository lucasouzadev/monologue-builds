# Architecture and hardening

## Layout A — same repository
Workflows live next to the app. Simple; uses the repo's Actions minutes (macOS minutes cost more on private repos). Good default for public projects.

## Layout B — private source + public CI repository
```
 owner / agent                        app (PRIVATE)
     │  Run workflow                    ▲  read-only clone (deploy key)
     ▼                                  │
 app-builds (PUBLIC) ───────────────────┘
     ├─ build ........ Android APK · iOS simulator app · TestFlight
     ├─ e2e-android .. emulator + Maestro
     ├─ e2e-ios ...... simulator + Maestro
     ├─ ota .......... Expo update (or verify a web-hosted OTA bundle)
     ├─ deploy-* ..... backend deploys (dry run first)
     └─ check ........ lints the workflows and flows (no secrets)
```
- The public repo holds **only** workflows, E2E flows and small scripts. No app source, no assets, no config with secrets.
- Each run clones the private repo with a **read-only** credential, builds, and discards the tree (`templates/scripts/checkout-private-source.sh`).
- Logs and artifacts are readable by anyone: build errors can quote file names, code lines or SQL. Run deploys with a dry run first; treat a failure log as public.
- A merge in the private repo does not deploy anything from here: someone dispatches the workflow.

## Hardening (do before adding secrets)
| Setting | Value |
|---|---|
| Actions → General → Fork pull request workflows | Require approval for all outside collaborators; secrets never go to forks |
| Actions → General → Workflow permissions | Read repository contents; each workflow requests only what it needs (`permissions:` block) |
| Environments | `release` (signing, store upload) and `production` (deploys), each with the owner as **required reviewer**; put those secrets inside the Environment |
| Branch protection | Protect `main`, require PRs: whoever edits a workflow can read the secrets it uses |
| Third-party actions | Pin by full commit SHA (`uses: owner/action@<sha> # vX`); update with Dependabot/Renovate |
| Concurrency | `concurrency: { group: <workflow>-<ref>, cancel-in-progress: false }` for builds; at most one run per platform in flight |
| Artifacts | Short retention (`retention-days: 3–7`), encrypted when sensitive |

## Build numbers
Stores reject a build number lower than one already seen. Use `BUILD_NUMBER = BUILD_NUMBER_OFFSET + github.run_number` with a repository **variable** `BUILD_NUMBER_OFFSET`; raise the offset when moving to a new CI repo.

## OTA vs new build
OTA can change only the JS/web layer compatible with the installed native runtime. New native modules, permissions, entitlements, manifest/plist changes, SDK upgrades → new build. Keep a written decision tree in the app repo and declare the delivery channel on every change.
