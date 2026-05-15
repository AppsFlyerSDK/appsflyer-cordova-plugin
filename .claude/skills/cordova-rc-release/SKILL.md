---
name: cordova-rc-release
description: >-
  Maps the AppsFlyer Cordova RC pipeline (RC prep, lint-test-build, E2E, npm publish, rc-smoke,
  promote) to workflow files in this repo. Use when editing rc-release, rc-smoke, promote-release,
  or lint-test-build; not for day-to-day feature work.
globs: >-
  .github/workflows/rc-release.yml,.github/workflows/rc-smoke.yml,.github/workflows/promote-release.yml,
  .github/workflows/lint-test-build.yml,
  .github/workflows/android-e2e.yml,.github/workflows/ios-e2e.yml,
  .github/workflows/pre-release-workflow.yml,.github/workflows/release-Production-workflow.yml,
  .af-e2e/**,.af-smoke/rc-test-plan.json,scripts/af-scenario-runner.sh
---

# RC release pipeline — AppsFlyer Cordova plugin

Use when:

- Editing **`rc-release.yml`**, **`rc-smoke.yml`**, **`promote-release.yml`**, or **`lint-test-build.yml`**.
- Wiring **`workflow_call`** from RC into **lint-test-build** + **Android E2E** + **iOS E2E**.
- Explaining why promotion should wait on **`rc-smoke/npm`** check-run **success** on the release branch head.

## Contract sources (shared tooling repo)

- [`contracts/rc-release-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/rc-release-contract.md)
- [`contracts/e2e-test-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/e2e-test-contract.md)
- [`contracts/smoke-test-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/smoke-test-contract.md)

## Stages in this repo (Cordova)

| Stage | Workflow(s) |
|-------|----------------|
| RC pre-publish | **`rc-release.yml`**: **`lint-test-build.yml`** (`workflow_call` only) + **`ios-e2e.yml`** + **`android-e2e.yml`**, then npm **`QA`** publish, prerelease, PR to `master` |
| Post-publish smoke | **`rc-smoke.yml`** → check **`rc-smoke/npm`** |
| Promote | **`promote-release.yml`** (label + **`rc-smoke/npm`** gate) → **`rc-promote-strip-rc.sh`** |
| Production (legacy) | **`release-Production-workflow.yml`** on merge to `master` — verify before changing |

Track adoption details in **`docs/SCENARIO_RUNNER_ADOPTION_WORKPLAN.md`**.

## Secrets (names only)

| Secret | Typical use |
|--------|-------------|
| `ENV_FILE` | Multiline `.env` for E2E sibling + smoke (`DEV_KEY`, `APP_ID`) |
| `CI_NPM_TOKEN` | `npm publish` in RC Release |
| `CI_DEV_GITHUB_TOKEN` | Branch push, PR, prerelease, promote, `gh` in smoke |

## Do not

- Do not bypass **`rc-smoke/npm` success** for promotion when using the designed promote gate.
- Do not duplicate long contract text in skills — link tooling contracts above.
