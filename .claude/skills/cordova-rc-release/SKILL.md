---
name: cordova-rc-release
description: >-
  Maps the intended AppsFlyer Cordova RC release pipeline (RC prep, E2E, publish, smoke, promote,
  production) to workflow files. Use when planning or adding rc-release/rc-smoke/promote workflows;
  not for day-to-day feature work.
globs: >-
  .github/workflows/android-e2e.yml,.github/workflows/ios-e2e.yml,.github/workflows/pre-release-workflow.yml,
  .github/workflows/release-Production-workflow.yml,.af-e2e/**,.af-smoke/rc-test-plan.json,scripts/af-scenario-runner.sh
---

# RC release pipeline — AppsFlyer Cordova plugin (target + current)

Use when:

- Adding **`rc-release.yml`**, **`rc-smoke.yml`**, **`promote-release.yml`**, or **`production-release.yml`**.
- Wiring **`workflow_call`** from RC into **lint + Android E2E + iOS E2E**.
- Explaining why promotion should wait on **`rc-smoke/npm`** check-run (Flutter parity).

## Sources of truth (tooling repo)

- [`contracts/rc-release-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/rc-release-contract.md)
- [`contracts/e2e-test-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/e2e-test-contract.md)
- [`contracts/smoke-test-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/smoke-test-contract.md)
- Live reference: **AppsFlyerSDK/appsflyer-flutter-plugin** `.github/workflows/`

## Current vs target (this repo)

| Stage | Target workflow (Flutter parity) | Cordova repo **today** |
|-------|----------------------------------|-------------------------|
| Lint / unit / build gate | `lint-test-build` composite | Legacy **`pre-release-workflow.yml`** / **`mac-os-unit-test-runner.yml`** — not yet unified |
| Pre-publish E2E | `android-e2e.yml`, `ios-e2e.yml` | **Present** — callable via `workflow_dispatch` / `workflow_call` |
| RC publish + tagging | `rc-release.yml` | **Not present** — see `release-Production-workflow.yml` / historical flows |
| Post-publish smoke | `rc-smoke.yml` + npm resolve | **Not present** |
| Promote (strip `-rcN`) | `promote-release.yml` gated on `rc-smoke/npm` | **Not present** |
| Production | `production-release.yml` | Partially covered by **`release-Production-workflow.yml`** (verify before changing) |

Track incremental adoption in **`docs/SCENARIO_RUNNER_ADOPTION_WORKPLAN.md`** (Phase 4 / 6).

## Secrets (names only)

| Secret | Typical use |
|--------|-------------|
| `ENV_FILE` | Multiline `.env` for E2E sibling + smoke app (`DEV_KEY`, `APP_ID`) |
| Registry / npm tokens | Publish jobs when implemented |

## Do not

- Do not bypass **`rc-smoke`** success requirement for promotion if the org adopts Flutter-style gates.
- Do not duplicate long contract text in skills — link tooling + Flutter repo.
