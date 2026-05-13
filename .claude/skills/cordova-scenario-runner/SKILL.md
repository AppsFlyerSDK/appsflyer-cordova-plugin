---
name: cordova-scenario-runner
description: >-
  Run or triage AppsFlyer Cordova E2E/smoke via ./scripts/af-scenario-runner.sh, sibling E2E copy,
  smoke dir, and JSON reports. Use for local reproduction, CI log triage, or report summaries.
---

# Scenario runner — AppsFlyer Cordova plugin

Use when:

- Android/iOS E2E or smoke failed in CI and you need to reproduce or summarize reports.
- Changing `.af-e2e/test-plan.json`, `.af-smoke/rc-test-plan.json`, or build scripts used by the runner.
- Validating install/launch paths after editing `test-app/` or sync scripts.

## Cordova-specific layout

| Piece | Location |
|-------|----------|
| Runner (vendored) | `scripts/af-scenario-runner.sh` (pin in `scripts/TOOLING_PIN.txt`) |
| E2E plan | `.af-e2e/test-plan.json` — build uses **sibling** `../<repo-basename>-e2e/` (default `../appsflyer-cordova-plugin-e2e/`) via `scripts/e2e-cordova-build.sh` |
| Smoke plan | `.af-smoke/rc-test-plan.json` — paths under `test-app_rc_smoke/` via `scripts/smoke-cordova-build.sh` |
| Reference app (do not `cordova build` here with `file:..`) | `test-app/` |
| Android CI scenario entry | **`.github/workflows/android-e2e.yml`** — one-line `script:` (see below) |
| Reports | `.af-e2e/reports/`, `.af-smoke/reports/` |

## Preconditions

- **Android:** booted emulator; `adb devices` shows `device`.
- **iOS:** booted simulator (`xcrun simctl list devices booted`).
- **`.env`:** for E2E, on the **sibling** copy (e.g. `../appsflyer-cordova-plugin-e2e/.env`) — CI writes from `ENV_FILE`; `sync-test-app-e2e-copy.sh` **protects** `.env` on rsync.
- **`jq`** installed.

## Commands (repo root)

Dry-run parse:

```sh
./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json --dry-run
./scripts/af-scenario-runner.sh --platform ios --plan .af-e2e/test-plan.json --dry-run
```

Build + single phase (paths / install smoke):

```sh
./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json --build --phase phase_1
./scripts/af-scenario-runner.sh --platform ios --plan .af-e2e/test-plan.json --build --phase phase_1
```

Smoke (after `scripts/sync-test-app-rc-smoke.sh` + local build):

```sh
./scripts/af-scenario-runner.sh --platform android --plan .af-smoke/rc-test-plan.json --build --phase phase_1
```

## Read the JSON report

```sh
jq '.overall_status, .total_checks, .passed, .failed' .af-e2e/reports/latest.json
```

Failed checks:

```sh
jq -r '
  .phases[]
  | .phase_id as $pid
  | .checks | to_entries[]
  | select(.value.status != "PASS")
  | "\($pid)/\(.key): \(.value.evidence)"
' .af-e2e/reports/latest.json
```

## CI: Android `script:` must be one line

`reactivecircus/android-emulator-runner` runs **each line** of `with: script:` as a **separate** `sh -c` invocation (same as **appsflyer-flutter-plugin** `android-e2e.yml`). Multi-line `if`/`fi` **breaks**. **`android-e2e.yml`** keeps **one physical line**: `set -euo pipefail;` … `nslookup` … `adb devices` … optional `--phase` … `af-scenario-runner` \|\| `dump-android-logs`.

## Rules

- Do not edit generated `latest.json` / phase JSON as “fixes”; fix the app, plan, or environment.
- Exit non-zero from the runner means FAIL — do not report PASS.
- No secrets or raw `DEV_KEY` in summaries.
- Contract docs: `appsflyer-mobile-plugin-tooling` — `contracts/e2e-test-contract.md`, `contracts/smoke-test-contract.md`, `docs/troubleshooting.md`.

## Repo workplan

See `docs/SCENARIO_RUNNER_ADOPTION_WORKPLAN.md` for phases (E2E CI, test-app contract, RC smoke).
