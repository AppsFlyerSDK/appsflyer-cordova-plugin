---
name: cordova-smoke-ci-alignment
description: >-
  Maps AppsFlyer Cordova CI (android/ios E2E workflows, ENV_FILE, sibling copy, smoke scripts) to
  the tooling smoke/E2E story. Use when editing .github/workflows/*e2e*, rc-smoke (when added),
  or debugging scenario CI.
globs: >-
  .github/workflows/android-e2e.yml,.github/workflows/ios-e2e.yml,.github/workflows/lint-test-build.yml,
  scripts/ci-android-e2e-scenario.sh,
  scripts/af-scenario-runner.sh,scripts/e2e-cordova-build.sh,scripts/smoke-cordova-build.sh,
  scripts/sync-test-app-e2e-copy.sh,scripts/sync-test-app-rc-smoke.sh,.af-e2e/**,.af-smoke/**
---

# Smoke / E2E CI alignment — AppsFlyer Cordova plugin

Use when:

- Editing or debugging **`android-e2e.yml`** / **`ios-e2e.yml`**.
- Explaining **`ENV_FILE`**, sibling **`.env`**, or artifact paths.
- Preparing or debugging **`rc-smoke.yml`** / **`promote-release.yml`**.

## What exists today

| Workflow | Role |
|----------|------|
| `.github/workflows/android-e2e.yml` | Ubuntu: Java 17, Android SDK, `e2e-cordova-build.sh android`, then emulator + **`bash …/ci-android-e2e-scenario.sh`** (single `script:` line) |
| `.github/workflows/ios-e2e.yml` | macOS: CocoaPods, `e2e-cordova-build.sh ios`, boot iPhone sim, `af-scenario-runner.sh` |

Triggers: `workflow_dispatch`, `workflow_call` (e.g. from **`rc-release.yml`**). Secrets: **`ENV_FILE`** (optional but required for real SDK checks).

**Note:** **`lint-test-build.yml`** is **`workflow_call` only** (invoked from **`rc-release.yml`** today).

## E2E vs smoke directories

| Flow | App directory | Plan | Build command in plan |
|------|---------------|------|------------------------|
| E2E | Sibling `../appsflyer-cordova-plugin-e2e/` (rsync + `file:` plugin URL) | `.af-e2e/test-plan.json` | `./scripts/e2e-cordova-build.sh <android\|ios>` |
| RC smoke | `test-app_rc_smoke/` (gitignored; `sync-test-app-rc-smoke.sh`) | `.af-smoke/rc-test-plan.json` | `./scripts/smoke-cordova-build.sh <android\|ios>` |

## Android emulator runner quirks

- **`script:` must be a single physical line** — use **`bash "${GITHUB_WORKSPACE}/scripts/ci-android-e2e-scenario.sh"`** (dash `sh` cannot run `set -o pipefail`; logic lives in bash).
- **KVM:** udev + `chmod 666 /dev/kvm` so the job does not fall back to **`-accel off`** (multi‑minute boots).
- **`emulator-options`:** include `-gpu swiftshader_indirect` and `-no-boot-anim` if you override defaults (full override replaces action defaults).

## Artifacts

Upload **`.af-e2e/reports/`** on both workflows (`if: always()`, `if-no-files-found: warn`). When smoke CI exists, mirror **`.af-smoke/reports/`**.

## Do not

- Do not bypass **`af-scenario-runner.sh`** for release assertions; JSON reports are the contract output.
- Do not commit **`.env`** or embed dev keys in YAML.
- Do not add `SMOKE-*` / `E2E-*` phases to JSON without updating the tooling contracts and test app.

## Cross-reference

- `docs/SCENARIO_RUNNER_ADOPTION_WORKPLAN.md`
- `appsflyer-mobile-plugin-tooling/docs/ci-alignment-guide.md`
