# Secrets and variables — names, purpose, origin

The agent lists names and origins; **the owner** creates values in GitHub → Settings → Secrets and variables → Actions (or inside an Environment). Values never go in the chat, an issue, a commit or a log. GitHub never shows a secret again after saving: keep originals in a password manager.

Name with a project prefix if you like (`APP_…`); keep the meaning.

## Source access (Layout B)
| Secret | Purpose | How to obtain | Safer choice |
|---|---|---|---|
| `SOURCE_DEPLOY_KEY` | read-only clone of the private repo | `ssh-keygen -t ed25519 -N "" -C ci-builds -f ci-key` → `ci-key.pub` in the **private** repo's *Deploy keys* **without** write access; whole `ci-key` file (or its base64) as the secret; delete both local files | SSH deploy key (read-only enforced by GitHub). A fine-grained token limited to that repo with *Contents: read-only* also works; never a classic token |

## Android
| Secret | Purpose | How to obtain |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | stable signing (installed app updates over the new APK) | `base64 -w0 release.jks` (macOS: `base64 -i release.jks`) |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | unlock the keystore | chosen when the keystore was created |
Use a **separate key** for public debug APKs: a debug APK signed with the store key can replace the real app on anyone's device. Without a keystore the build still works with a throwaway debug key (installs will not update over each other).

## iOS / App Store Connect
| Secret | Purpose | How to obtain |
|---|---|---|
| `ASC_KEY_ID`, `ASC_ISSUER_ID` | App Store Connect API key identity | App Store Connect → Users and Access → Integrations → Keys |
| `ASC_API_KEY_P8` (or `_BASE64`) | the `.p8` content | downloaded **once** when the key is created; minimum role that can upload builds (App Manager or Developer per need) |
| `APPLE_TEAM_ID` | team for signing | Apple Developer → Membership |
| `IOS_DIST_CERT_P12_BASE64`, `IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64` | manual signing (if not using automatic signing via the API key / EAS credentials) | Keychain export of the distribution certificate; App Store profile from the Developer portal |
Simulator builds need **no** Apple secrets. Only TestFlight/store uploads do; keep these in the `release` Environment.

## Expo / EAS
| Secret | Purpose | How to obtain |
|---|---|---|
| `EXPO_TOKEN` | `eas update` / `eas build` non-interactive | expo.dev → Account settings → Access tokens (robot user preferred) |
EAS-managed credentials stay on Expo's side; `eas build --local` needs the signing secrets above on the runner.

## E2E (optional)
| Secret | Purpose |
|---|---|
| `E2E_EMAIL`, `E2E_PASSWORD` | a **dedicated, empty** test account (never the owner's account); flows only navigate and read |
| `ARTIFACT_PASSPHRASE` | ≥ 24 random chars; encrypts screenshots/logs/builds in public repos |

## Variables (not secret)
`BUILD_NUMBER_OFFSET` (e.g. `100`). Public client config (`EXPO_PUBLIC_*`, `VITE_*`, publishable keys) may be variables — they ship in the app anyway.

## Never put in the CI repo
Backend service-role/admin keys, payment provider secrets, database superuser URLs, e-mail provider keys, or anything the build does not need. If a deploy job needs a backend token, scope it to deploy only and keep it in the `production` Environment.

## If a secret leaks
Revoke/rotate it at the source first (deleting the text is not enough), then update the GitHub secret, then check recent runs/logs.
