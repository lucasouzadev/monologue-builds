# Verification status of the templates

Honest record. "Static" = `actionlint` with `shellcheck` (workflow syntax, expressions, contexts). "Runner" = actually executed on a GitHub-hosted runner against a real app. Nothing here is certified to work for your project: expect to tune selectors, SDK levels and scheme names on the first run.

| Template | Static (actionlint 1.7.12 + shellcheck 0.11) | Runner |
|---|---|---|
| `check.yml` | clean | not yet |
| `android-apk.yml` (expo / react-native / capacitor / native) | clean | not yet |
| `ios-simulator.yml` | clean | not yet |
| `e2e-android.yml` | clean | not yet |
| `e2e-ios.yml` | clean | not yet |
| `expo-ota.yml` | clean | not yet |
| `eas-build.yml` | clean | not yet |
| `ios-testflight.yml` | clean | not yet |
| scripts: `checkout-private-source.sh`, `install-deps.sh` | syntax checked | not yet |
| scripts: `encrypt-artifact.mjs` / `decrypt-artifact.mjs` | round-trip and tamper tests in `tests/run.sh` | n/a |

The patterns come from workflows that run in production in the author's own CI repositories; these templates are generalized copies and have not been re-run in their generic form.

## Help verify
Run a template on a small real app and open an issue with the "CI run report" template: which template, framework, runner image, what you had to change, link to the run (no secrets, no private logs). Verified rows get updated here with the date and the kit version.
