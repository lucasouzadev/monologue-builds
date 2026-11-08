# Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `error in libcrypto` / `Permission denied (publickey)` on private checkout | deploy key pasted with CRLF/no final newline, public key pasted, key with passphrase, or key not added to the private repo | store the base64 of the key file; regenerate with `-N ""`; compare the printed fingerprint with *Deploy keys* |
| Installed app does not update over the new APK | lower versionCode or different signing key | raise `BUILD_NUMBER_OFFSET`; use the same keystore secret every time |
| `-PversionCode` ignored | `build.gradle` does not read it | make `versionCode` read `project.findProperty("versionCode")` (or set it in `app.json` for Expo) |
| TestFlight rejects the build number | number already used or lower | raise `BUILD_NUMBER_OFFSET` before the next run |
| Upload "succeeded" but no build appears | Apple processing or a validation e-mail | check App Store Connect / the e-mail; the job cannot see processing |
| Emulator disappears mid-run (`device not found`) | runner out of memory | 4 cores / ≥ 6 GB RAM for the AVD, fewer flows per run, `-no-snapshot` |
| Maestro cannot find an element | text changed, locale, animation, slow screen | use ids, `extendedWaitUntil`, disable animations, read the failing screenshot |
| `pod install` fails on the runner | Xcode/CocoaPods version mismatch | pin `macos-<version>` and select Xcode with `sudo xcode-select -s /Applications/Xcode_<v>.app` |
| OTA reached users but crashed | update needs native code the installed build lacks | runtime version policy per native change; ship a build first; validate on `preview` |
| Secret printed in a log | `echo`/`set -x`/a tool's debug output | rotate the secret at the source now; remove the print; re-run |
