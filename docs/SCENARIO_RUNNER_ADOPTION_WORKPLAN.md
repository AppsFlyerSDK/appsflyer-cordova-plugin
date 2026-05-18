# Workplan: AppsFlyer scenario runner adoption (Cordova)

This document is the step-by-step implementation guide for bringing the shared **E2E + RC smoke** flow from [`appsflyer-mobile-plugin-tooling`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling) into **appsflyer-cordova-plugin**.

**Default target:** match the **live Flutter reference app** [`AppsFlyerSDK/appsflyer-flutter-plugin`](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin) (same layout as the workspace clone: vendored `scripts/af-scenario-runner.sh`, `.af-e2e/` + `.af-smoke/` JSON, `workflow_call` E2E jobs, **`workflow_run` RC smoke** that **synthesizes** a smoke app tree in CI, **`ENV_FILE`** → `.env`, artifacts under `.af-e2e/reports/` and `.af-smoke/reports/`). Deviations need a one-line rationale in the PR.

Static copies in tooling [`examples/flutter/*.json`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/tree/main/examples/flutter) and [`docs/ci-alignment-guide.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/docs/ci-alignment-guide.md) remain the contract docs; the Flutter **repo** is the procedural reference for CI wiring.

## 1. What we are adopting (summary)

| Piece | Role |
|--------|------|
| `af-scenario-runner.sh` | Single entrypoint: install/launch app, optional `--build`, run phases from JSON, collect logs, assert patterns, write JSON report + `latest.json`. |
| `.af-e2e/test-plan.json` | Pre-publish E2E: `scenario_ref` values `E2E-*`, build uses **plugin source** (path/file dependency). |
| `.af-smoke/rc-test-plan.json` | Post-publish smoke: `scenario_ref` values `SMOKE-*`, build uses **registry-pinned RC** (npm tag/version). |
| `schemas/smoke-test-plan.schema.json` | Validate plan JSON in CI or locally (`jq` + manual review minimum). |
| Normative contracts | Especially [`contracts/test-app-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/test-app-contract.md), [`e2e-test-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/e2e-test-contract.md), smoke scenario docs under `docs/smoke-scenarios/`. |

**Runner (Flutter default):** **vendored** `scripts/af-scenario-runner.sh` in this repo, copied from a **pinned** [`appsflyer-mobile-plugin-tooling`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling) release tag, `chmod +x`, committed. CI always invokes `./scripts/af-scenario-runner.sh` (same as Flutter’s `android-e2e.yml` / `ios-e2e.yml` / `rc-smoke.yml`). Optionally keep a sibling tooling clone **locally** for comparing runner behavior without bumping the vendored file.

**Host requirements:** bash 4+, `jq`, `adb` (Android), `xcrun` / Xcode (iOS), booted emulator/simulator.

## 2. Gap analysis vs current Cordova repo

| Area | Today | Target |
|------|--------|--------|
| Manual / legacy (`examples/cordovatestapp`) | Unit tests / paramedic / old **`com.appsflyer.cordovatry`** id; not aligned with runner | **Leave unchanged** — not the E2E/smoke target for this ticket |
| Automation shell (`test-app/`) | New minimal Cordova tree at repo root (**reference** only; E2E **`cordova build`** runs from a **sibling copy** with **`file:`** plugin URL — see **`test-app/README.md`**) | **`com.appsflyer.qa.cordova`**, [**test-app contract**](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/test-app-contract.md) (`[AF_QA]`, `.env` from **`ENV_FILE`**, deep links, iOS file log) — **documented deviation** from Flutter’s single committed `example/` (Cordova keeps a separate small automation app) |
| iOS log capture | Runner prefers `Documents/af_qa_logs.txt` for `[AF_QA]` on iOS | Must implement dual logging (see §4.2); `log show` alone is insufficient per tooling troubleshooting |
| Deep links | Not aligned with `afqa-cordova://` + plan URLs | `config.xml` / iOS URL types + Android intent filters matching `deep_link_url` in plans; SMOKE-002 may need **terminate + `simctl launch … -deepLinkURL`** pattern like Flutter (see Flutter `rc-test-plan` phase_2 notes) |
| Manual start | Plugin supports `shouldStartSdk: false` then `startSdk()` (Android `SHOULD_START_SDK`, iOS `shouldStartSdk`) | Test app must use this for contract order: listeners → pre-start APIs → `--- Pre-start ---` → `startSdk` → post-start APIs → events |
| CI | Legacy pre-release / production workflows | **Mirror appsflyer-flutter-plugin:** `rc-release` + `workflow_call` lint/build + **iOS/Android E2E**; **`rc-smoke`** on `workflow_run` + npm resolve poll; **`promote-release`** gated on **`rc-smoke/npm`** check-run; **`production-release`** on merge |

**JSON templates:** start from **`appsflyer-mobile-plugin-tooling/examples/flutter/e2e-test-plan.json`** and **`rc-test-plan.json`**, then align field-for-field with **`.af-e2e/test-plan.json`** and **`.af-smoke/rc-test-plan.json`** in **appsflyer-flutter-plugin** (paths under `example/` vs `example_rc_smoke/` map to Cordova **`test-app/`** vs the **CI-synthesized** **`test-app_rc_smoke/`** — see Phase 4).

### Dedicated `test-app/` (documented deviation from Flutter’s single `example/`)

**Cordova keeps `examples/cordovatestapp/` for legacy manual flows and unit/paramedic work** and does **not** retarget it for **`af-scenario-runner`**.

- **E2E + contract QA** use **`test-app/`** at repo root as the **editable reference**: **`widget id` `com.appsflyer.qa.cordova`**, plugin **`file:..` / `spec=".."`** for humans only — **do not** run **`cordova build`** there with that spec (see §2.1). **`scripts/sync-test-app-e2e-copy.sh`** copies to a **sibling** tree and patches the plugin to an absolute **`file:`** URL. From Phase 3 onward, implement the full [**test-app contract**](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/test-app-contract.md) in **`test-app/`** (sync picks up **`www/`** etc.).
- The **second** path is **`test-app_rc_smoke/`** (gitignored): CI **`rsync`s** from **`test-app/`**, pins **`cordova-plugin-appsflyer-sdk`** to the published RC on npm, writes **`.env`**, and runs smoke (Phase 4 / D4).

**Rationale:** avoids churn in the long-lived example app while still giving the runner a clean, minimal surface area. **Trade-off:** two Cordova trees to reason about (`examples/cordovatestapp` vs `test-app`) — acceptable when called out in PRs and this doc.

## 3. Implementation phases

### Phase 0 — Decisions and repo hygiene

**Status**

| Step | State |
|------|--------|
| Branch `DELIVERY-<n>-…` created and checked out | Done — `DELIVERY-115745-plugin-test-automation` |
| Jira id matches branch | Done — **DELIVERY-115745** |
| `.gitignore` entries for secrets & reports | Done — see repo root `.gitignore` |
| Recorded decisions (table below) | **Phase 0 decisions complete** (D1–D6) |

**Decision sequence (do in order; update the log table as each row closes)**

| # | Topic | § | Status |
|---|--------|---|--------|
| D1 | Jira ticket ↔ branch | 0.1 | **Done** |
| D2 | Runner source (A vs B) | 0.2 | **Done** — **B** (same as Flutter) |
| D3 | MVP scope (Full vs Bootstrap) | 0.3 | **Done** — **Full** (Flutter parity) |
| D4 | RC smoke layout + directory name | 0.4 | **Done** — CI-synthesized, **`test-app_rc_smoke/`** |
| D5 | Android/iOS app id (Keep vs Rename) | 0.5 | **Done** — **`com.appsflyer.qa.cordova`** (+ HQ app / keys — §0.5) |
| D6 | npm resolve + promote **check_run** name + package id for polling | 0.6 | **Done** — defaults (§0.6 **Recorded**) |

#### 0.1 Jira / branch

Repo convention: branch name `DELIVERY-<ticket-number>-<description>`. The ticket is the traceability link for CI gates and release notes. No repo file needs the ticket id unless you add it to the PR template or `RELEASENOTES.md`; optional: one-line comment in the operator doc in Phase 7.

#### 0.2 Runner source (Flutter uses **vendored**)

| Criterion | **A — Sibling clone** (tooling repo next to plugin) | **B — Vendored** (`./scripts/af-scenario-runner.sh`, from tooling **tag**) |
|-----------|-----------------------------------------------------|----------------------------------------------------------------------------|
| **Flutter reference** | Not used in CI | **Yes** — committed script, workflows call `./scripts/af-scenario-runner.sh` |
| **Reproducibility** | Good if Actions pin a **SHA/tag** on the tooling checkout | **Best** — runner bytes in git until you bump |
| **Runner fixes** | Bump checkout ref in workflow | Copy script from newer tooling tag + commit |
| **CI** | Second checkout + path wiring | **Single repo** (matches Flutter) |

**Adoption default for Cordova:** **B — Vendored**, identical to Flutter. Document the tooling **git tag** each time you refresh `scripts/af-scenario-runner.sh` (and optional helpers like Flutter’s `scripts/dump-android-logs.sh` if you want the same Android failure diagnostics).

**Optional local-only A:** clone `appsflyer-mobile-plugin-tooling` beside the plugin and run `../appsflyer-mobile-plugin-tooling/scripts/af-scenario-runner.sh` while iterating; CI should still use **B**.

**Recorded (Cordova):** **B — Vendored** — same as **appsflyer-flutter-plugin** (`./scripts/af-scenario-runner.sh` in repo; CI never depends on a sibling tooling clone). When copying the file in Phase 1, note the **appsflyer-mobile-plugin-tooling git tag** (or commit SHA) in the PR / operator doc so bumps are traceable.

#### 0.3 MVP scope

| Scope | Phases / scenarios | When to use |
|-------|-------------------|-------------|
| **Full (Flutter reference)** | `E2E-001`–`E2E-006` + `SMOKE-001`–`SMOKE-003` | **Target** — same breadth as **appsflyer-flutter-plugin** `.af-e2e/test-plan.json` once the Cordova test app implements all auto-run / `[AF_QA]` markers |
| **Bootstrap slice** | `E2E-001`–`E2E-003` + smoke 001–003 only | Temporary first PR if you need a green pipeline before implementing E2E-004–006; trim plan phases and document “parity gap” |

**Adoption default:** aim for **Full** parity with Flutter’s committed plan; use **Bootstrap slice** only as a labeled interim state.

**Recorded (Cordova):** **Full** — `E2E-001`–`E2E-006` + `SMOKE-001`–`SMOKE-003` (same breadth as **appsflyer-flutter-plugin** `.af-e2e` / `.af-smoke` plans). **`test-app/`** must implement all corresponding auto-run / `[AF_QA]` markers before those phases can pass.

#### 0.4 RC smoke app layout (**Flutter: CI-synthesized tree**)

Flutter’s **`rc-smoke.yml`** does **not** commit `example_rc_smoke/`. On each smoke run it:

1. **`rsync`s** `example/` → `example_rc_smoke/` with excludes (`pubspec.yaml`, `pubspec.lock`, `build/`, `.dart_tool/`, `ios/Pods/`, `.env`, …).
2. **Patches** `example_rc_smoke/pubspec.yaml` so `appsflyer_sdk:` is the **exact RC version** string from the registry (no `path:`).
3. Writes **`example_rc_smoke/.env`** from **`ENV_FILE`**.
4. Builds and runs **`./scripts/af-scenario-runner.sh --plan .af-smoke/rc-test-plan.json`** with `config.*` paths pointing at **`example_rc_smoke/`** outputs.

**Adoption default for Cordova:** mirror that pattern:

- **Git** tracks **`test-app/`** (E2E **source**; **`config.xml` `<plugin spec="..">`** is reference-only — real E2E builds use the **sibling copy** from **`sync-test-app-e2e-copy.sh`**).
- **Smoke job** copies to **`test-app_rc_smoke/`** (stable name for `.af-smoke/rc-test-plan.json`), excludes `package-lock.json` / `node_modules/` / `platforms/` / `plugins/` / `.env` as appropriate, then **patches** `package.json` (and **`config.xml` `<plugin … spec=`** if required) so the AppsFlyer plugin resolves from **npm at exact `X.Y.Z-rcN`**, not `file:../../`.
- Add **`test-app_rc_smoke/`** to **`.gitignore`** so local experiments are never committed (Flutter’s smoke dir is ephemeral in CI; ignoring avoids accidental commits).

**Optional deviation:** maintain a second committed example app only if Cordova/npm resolution makes ephemeral copy unworkable — document why.

**Recorded (Cordova):** **CI-synthesized (Flutter)** — smoke workflow **`rsync`s** `test-app/` → **`test-app_rc_smoke/`**, patches npm/plugin spec to the published RC, writes `.env`; dir is **gitignored** (already in repo `.gitignore`).

#### 0.5 Android package / iOS bundle id

| Choice | When to use |
|--------|-------------|
| **Keep** `com.appsflyer.cordovatry` (current `widget id`) | Less churn; `config.*` in JSON plans must match this exactly |
| **Rename** to `com.appsflyer.qa.cordova` per [test-app contract](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/test-app-contract.md) | QA naming convention; requires `config.xml` + clean native rebuild; **`.af-e2e` / `.af-smoke` `package_name` / `bundle_id` must match** |

**Recorded (Cordova):** **Rename** — Android **`package_name`** and iOS **`bundle_id`** = **`com.appsflyer.qa.cordova`** (already set on **`test-app/config.xml`** `<widget id="…">`; Phase 3 implements the rest of the contract in **`test-app/www/`** and native hooks as needed).

**AppsFlyer HQ prerequisite (blocking real SDK traffic):**

1. In **AppsFlyer HQ**, create (or request) an app whose **Android package** and **iOS bundle ID** match **`com.appsflyer.qa.cordova`** (iOS app record must use that exact bundle id for `APP_ID` / Store id used by the SDK).
2. Copy the app’s **Dev key** → **`DEV_KEY`** in `.env` (never commit; CI via **`ENV_FILE`** secret, same pattern as Flutter).
3. Copy the **iOS App ID** (Apple App Store id string the SDK expects, e.g. `idXXXXXXXX`) → **`APP_ID`** in `.env`.
4. Share **`ENV_FILE`** with whoever configures GitHub Actions (and local developers via your usual secrets channel).

Until HQ + `.env` exist, the test app can still be developed, but **E2E/smoke phases that hit the network** will fail or block on **`[AF_QA][CONFIG] DEV_KEY missing`**.

#### 0.6 npm / RC alignment (**mirror Flutter’s `resolve` job**)

Flutter **`rc-smoke.yml`** `resolve` job: after **`workflow_run`** on **`RC - Release Candidate`** success, checks out the **release branch head**, reads **RC version from `pubspec.yaml`**, then **polls pub.dev’s HTTP API** until that version appears (or timeout → **skipped** check-run so promotion cannot treat silence as green).

**Cordova analogue:**

- Read **`version`** from root **`package.json`** / **`plugin.xml`** on the release branch (same source your RC workflow already bumps).
- Poll **npm** until `cordova-plugin-appsflyer-sdk@<that-version>` is installable (HTTP to `registry.npmjs.org`, or `npm view <pkg>@<version> version`, or `npm install --dry-run` — pick one and document).
- **`workflow_dispatch`** on smoke: accept **`rc_version`** + **`release_branch`** inputs (same shape as Flutter) for manual reruns.
- **`ENV_FILE`** secret: for E2E, write **`.env`** into the **E2E sibling** directory (same path **`build_cmd`** uses — default **`../appsflyer-cordova-plugin-e2e/.env`**, or **`$TEST_APP_E2E_COPY_DEST/.env`**); for smoke, write **`<smoke_dir>/.env`** after rsync (Flutter pattern).

Record **dist-tag** behavior only if you publish RCs under a non-default tag; the **resolve** logic should key off the **exact semver** that was published, same as Flutter’s version string check.

**Recorded (Cordova) — D6 defaults:**

| Item | Value |
|------|--------|
| **Promote-gate `check_run` name** | **`rc-smoke/npm`** (Flutter uses `rc-smoke/pub.dev`; **`promote-release`** must query this exact name) |
| **npm package for resolve / smoke patches** | **`cordova-plugin-appsflyer-sdk`** (matches root **`package.json` `name`**) |
| **Registry visibility poll** | **`npm view cordova-plugin-appsflyer-sdk@<version> version`** — exit **0** and stdout equals `<version>` when the tarball is published (same role as Flutter’s pub.dev HTTP poll). Use **`registry.npmjs.org`**; document any **auth** if the package is private (unlikely for this plugin). |

---

**Flutter parity checklist (Cordova)**

- [ ] AppsFlyer **HQ** app for **`com.appsflyer.qa.cordova`**; **`ENV_FILE`** secret with **`DEV_KEY`** + **`APP_ID`** (§0.5)
- [x] `scripts/af-scenario-runner.sh` vendored + executable; **`scripts/dump-android-logs.sh`** (Cordova defaults)
- [x] `.af-e2e/test-plan.json` + `.af-smoke/rc-test-plan.json` committed (`_meta.plugin`: `cordova`)
- [x] E2E: **`scripts/sync-test-app-e2e-copy.sh`** + sibling **`../<repo-basename>-e2e/`** (default **`../appsflyer-cordova-plugin-e2e/`**) with **`file:`** plugin URL; **`.af-e2e`** `build_cmd` uses **`scripts/e2e-cordova-build.sh`**
- [x] Smoke: **`scripts/sync-test-app-rc-smoke.sh`** ( **`rsync`** **`test-app/`** → **`test-app_rc_smoke/`** ) + **`SMOKE_PLUGIN_VERSION`** / root **`package.json`** pin; **`build_cmd`** **`scripts/smoke-cordova-build.sh`**; **no** committed smoke tree
- [x] **§2.6 E2E:** **`.github/workflows/android-e2e.yml`** + **`ios-e2e.yml`** (`workflow_dispatch` / **`workflow_call`** / weekly **`schedule`**), sibling **`.env`** from **`ENV_FILE`**, **`.af-e2e/reports/`** artifacts
- [x] **`ios-e2e` on GitHub Actions:** full **`cordova-e2e`** plan **PASS** with **`ENV_FILE`** (verified CI run, 2026-05-13).
- [ ] **`android-e2e` on GitHub Actions:** full plan green — **CI failed 2026-05-13** in **`phase_3`** (`is_first_launch_true`): SDK saw **`is_first_launch=false`** / **`counter":"2"`** after `requires_fresh_install`; operator device run remains **38/38** (see §3 / open follow-up).
- [ ] **Phase 6 release gate:** **`lint-test-build`** (or your quality gate) + **`rc-release`** calling both E2E; **`skip_e2e`**-style input **blocks publish** when E2E is required
- [ ] **`rc-smoke`**: `workflow_run` on RC workflow + dispatch; **resolve** + skipped check-run on dry-run / missing tarball; post **`check_run` `rc-smoke/npm`**
- [ ] **`promote-release`**: verify **`rc-smoke/npm`** check-run **`success`** on PR head SHA before stripping `-rcN`
- [x] Artifacts: **`.af-e2e/reports/`** from **`android-e2e` / `ios-e2e`** (`if: always()`, `if-no-files-found: warn`)
- [ ] **`.af-smoke/reports/`** from **`rc-smoke`** (`if: always()` where Flutter does)

**Phase 0 decision log (copy into PR or keep updated here)**

| Topic | Choice | Owner / date | Notes |
|--------|--------|----------------|-------|
| **D1 — Jira / branch** | **DELIVERY-115745** | | Branch: **`DELIVERY-115745-plugin-test-automation`** (matches ticket prefix) |
| **D2 — Runner source** | **B** (vendored), Flutter parity | | `scripts/af-scenario-runner.sh`; tooling **tag/SHA** noted at Phase 1 vendor commit |
| **D3 — MVP scope** | **Full** (Flutter parity) | | `E2E-001`–`E2E-006` + `SMOKE-001`–`SMOKE-003` |
| **D4 — RC smoke app** | **CI-synthesized** (Flutter) | | **`test-app_rc_smoke/`** (gitignored) |
| **D5 — Package / bundle id** | **Rename** | | **`com.appsflyer.qa.cordova`** — create app in **AppsFlyer HQ**, provision **`DEV_KEY`** + **`APP_ID`** → **`ENV_FILE`** / `.env` (§0.5) |
| **D6 — npm / promote gate** | **Defaults** | | **`check_run`:** `rc-smoke/npm`; **package:** `cordova-plugin-appsflyer-sdk`; **poll:** `npm view <pkg>@<version> version` |

### Phase 1 — Directory layout and plan skeletons

1. **Vendor the runner (Flutter pattern):** copy [`appsflyer-mobile-plugin-tooling/scripts/af-scenario-runner.sh`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/scripts/af-scenario-runner.sh) from a **pinned release tag** into **`scripts/af-scenario-runner.sh`**, `chmod +x`, commit. Optionally add **`scripts/dump-android-logs.sh`** the same way if you want parity with Flutter’s Android failure dumps.
2. Create **`.af-e2e/`** with `test-plan.json` — adapt from **appsflyer-flutter-plugin** `.af-e2e/test-plan.json` (or tooling `examples/flutter/e2e-test-plan.json`), then fix **`config.*`** paths to the **sibling E2E Cordova tree** (default **`../appsflyer-cordova-plugin-e2e/`** relative to repo root, produced by **`scripts/sync-test-app-e2e-copy.sh`**).
3. Create **`.af-smoke/`** with `rc-test-plan.json` — same, but **`config.*`** must reference the **CI-synthesized** smoke directory (same relative layout Flutter uses for `example_rc_smoke/` vs `example/`).
4. Update `_meta`: set `"plugin": "cordova"`, `plan_id` values (e.g. `cordova-e2e`, `cordova-rc-smoke`), bump plan `version` when phases change.
5. Validate JSON against `smoke-test-plan.schema.json` (CI step or `ajv`/`check-jsonschema`).
6. **`.gitignore`:** list the smoke synthesis dir (default **`test-app_rc_smoke/`**) — already added at repo root for that path; adjust if you pick a different directory name.

**Phase 1 — done on branch `DELIVERY-115745-plugin-test-automation`**

| Deliverable | Notes |
|---------------|--------|
| `scripts/af-scenario-runner.sh` | Vendored from **appsflyer-mobile-plugin-tooling**; pin recorded in **`scripts/TOOLING_PIN.txt`** (`COMMIT=c996200…`). |
| `scripts/dump-android-logs.sh` | Cordova-oriented default package **`com.appsflyer.qa.cordova`**; `chmod +x`. |
| `.af-e2e/test-plan.json` | **`cordova-e2e`**, paths under **`../<repo-basename>-e2e/`** (default **`../appsflyer-cordova-plugin-e2e/`**), **`build_cmd`** = **`scripts/e2e-cordova-build.sh`**, **`afqa-cordova://`** deep links. **`pre_start_apis`** on phase_5 removed vs Flutter copy so the plan matches **`smoke-test-plan.schema.json`**. E2E-005 behavior remains the test app’s responsibility (same as Flutter). |
| `.af-smoke/rc-test-plan.json` | **`cordova-rc-smoke`**, paths under **`test-app_rc_smoke/`**, **`build_cmd`** = **`./scripts/smoke-cordova-build.sh`** ( **`sync-test-app-rc-smoke.sh`** + npm-pinned plugin). |
| Validate JSON | **`./scripts/af-scenario-runner.sh --plan .af-e2e/test-plan.json --dry-run`** parses both plans. Full **`ajv-cli`** validate may need `--strict=false` / URI format plugins until CI picks a validator. |

**Next:** **Phase 4** — RC smoke app synthesis + **`rc-smoke.yml`** parity (and **Phase 6** wiring **`rc-release`** / **`promote-release`** when ready). **Phase 3** test-app contract is implemented in **`test-app/`** (`[AF_QA]`, `.env` → hook → **`af-qa-env.js`**, **`afqa-cordova://`**, **`af_qa_logs.txt`** via **`cordova-plugin-file`**). **§2.6** E2E workflows (**`android-e2e.yml`**, **`ios-e2e.yml`**) are in place. **Full `cordova-e2e`:** **Android** **38/38** **PASS** (operator device); **GitHub Actions `android-e2e`** may still fail **`phase_3`** until fresh-install / first-launch behavior matches emulator CI (logs: **`is_first_launch=false`**). **iOS** **38/38** **PASS** (Simulator + **GitHub Actions `ios-e2e`** with **`ENV_FILE`**, 2026-05-13) — **`hooks/afqa-ios-simctl-deeplink-replay.js`** AppDelegate replay for **`simctl launch -deepLinkURL`**. See Phase 5 for local commands.

### Phase 2 — Cordova `config` block (build outputs)

**Status (path / `build_cmd` / runner install):** **Done** for **`.af-e2e`** (sibling **`../appsflyer-cordova-plugin-e2e/`**) and **`.af-smoke`** (**`test-app_rc_smoke/`**): **`apk_path` / `app_path`** match **`find`** on built trees; **`build_cmd`** uses **`e2e-cordova-build.sh`** / **`smoke-cordova-build.sh`**; **`af-scenario-runner`** **`--dry-run`** and **`--build --phase phase_1`** exercised on E2E for Android + iOS. Log scenario assertions remain **Phase 3**.

Phase 2 makes **`.af-e2e/test-plan.json`** and **`.af-smoke/rc-test-plan.json`** tell the truth for **this** repo’s Cordova CLI, `cordova-android` / `cordova-ios` versions, and **D5** bundle id **`com.appsflyer.qa.cordova`**. Until Phase 3, builds may still fail or the runner may find no `[AF_QA]` lines — that is OK; Phase 2 is about **paths and commands**, not passing E2E yet.

#### 2.0 Prerequisites

- **Repo root:** all `build_cmd` examples below assume commands run from **`appsflyer-cordova-plugin`** (plugin root), not from inside `test-app` unless stated.
- **Automation app directory:** **`test-app/`** (E2E). For smoke, use the **same** `config.*` **paths relative to repo root** pointing at **`test-app_rc_smoke/`** — that folder is CI-synthesized; locally you can **`rsync`** once to test Phase 2 smoke paths (dir is gitignored).
- **Tooling:** `node` / `npm`, **Cordova CLI** (`npm i -g cordova` or `npx cordova`), **Java** (match future CI, e.g. **17**), **Android SDK** + **`adb`**, **Xcode** + **`xcrun`** for iOS simulator builds.
- **Plugin install for E2E (sibling copy):** Do **not** run **`cordova platform add` / `cordova build`** from **`test-app/` inside this repo** with **`file:..`**: Cordova copies the plugin tree into **`test-app/plugins/`**, which still contains **`test-app/`** and triggers **`ENAMETOOLONG`**. Instead, **`scripts/sync-test-app-e2e-copy.sh`** **`rsync`s** the reference **`test-app/`** to a directory **outside** the plugin tree (default **`<parent>/<repo-basename>-e2e`**, e.g. **`../appsflyer-cordova-plugin-e2e`**). The copy’s **`package.json`** / **`config.xml`** are patched to **`cordova-plugin-appsflyer-sdk`** = **`file:`** URL of the plugin root. **`.af-e2e`** `build_cmd` runs **`scripts/e2e-cordova-build.sh`**, which syncs then **`npm install`** + **`cordova build`**. See **`test-app/README.md`**.

#### 2.1 Align `package_name`, `bundle_id`, and `activity`

In **both** JSON files, under `config.android` / `config.ios`:

| Field | Rule |
|--------|------|
| **`package_name`** (Android) | Must equal the **applicationId** / app id installed on device. **`test-app/config.xml`** already uses **`com.appsflyer.qa.cordova`** (D5). **`examples/cordovatestapp`** remains **`com.appsflyer.cordovatry`** for legacy flows — do not mix IDs across trees. |
| **`bundle_id`** (iOS) | Same: must match **`CFBundleIdentifier`** of the built `.app`. |
| **`activity`** (Android) | Cordova default is usually **`.MainActivity`**. If launch fails, open **`platforms/android/app/src/main/AndroidManifest.xml`** (after `cordova prepare android`) and confirm the launcher activity name; use **`com.appsflyer.qa.cordova/.MainActivity`** only if your manifest uses fully-qualified activity. |

#### 2.2 Android — discover `apk_path`

1. From **plugin repo root**, sync and build once (same as **`build_cmd`**):

   ```sh
   ./scripts/e2e-cordova-build.sh android
   ```

2. Locate the APK under the **sibling copy** (default **`../appsflyer-cordova-plugin-e2e/`** relative to repo root):

   ```sh
   find ../appsflyer-cordova-plugin-e2e/platforms/android -name "*.apk" 2>/dev/null
   ```

   Common locations:

   - **`../appsflyer-cordova-plugin-e2e/platforms/android/app/build/outputs/apk/debug/app-debug.apk`**

3. Set **`config.android.apk_path`** in **`.af-e2e/test-plan.json`** to a path **relative to repo root** (must match **`TEST_APP_E2E_COPY_DEST`** / default sibling name).

4. Repeat the same **relative** path pattern for **`.af-smoke/rc-test-plan.json`**, but under **`test-app_rc_smoke/`** once **`./scripts/smoke-cordova-build.sh android`** has produced **`platforms/`** (see §2.4).

5. **`build_cmd` (Android, E2E):** **`./scripts/e2e-cordova-build.sh android`**. **`e2e-cordova-build.sh`** adds **`cordova platform add android`** when **`platforms/android`** is missing.

#### 2.3 iOS — discover `app_path` (simulator)

1. From **plugin repo root**:

   ```sh
   ./scripts/e2e-cordova-build.sh ios
   ```

2. Find the **`.app`** bundle under the sibling copy:

   ```sh
   find ../appsflyer-cordova-plugin-e2e/platforms/ios/build -name "*.app" -type d 2>/dev/null
   ```

3. Set **`config.ios.app_path`** relative to repo root, e.g.  
   `../appsflyer-cordova-plugin-e2e/platforms/ios/build/Debug-iphonesimulator/AFQACordova.app`.

4. Mirror **`app_path`** for **`.af-smoke/rc-test-plan.json`** under **`test-app_rc_smoke/`** after **`./scripts/smoke-cordova-build.sh ios`** (§2.4).

5. **`build_cmd` (iOS, E2E):** **`./scripts/e2e-cordova-build.sh ios`**. **`e2e-cordova-build.sh`** adds **`cordova platform add ios`** when **`platforms/ios`** is missing.

#### 2.4 Smoke plan vs E2E plan

| Plan | `config.*` paths prefix | `build_cmd` `cd` target |
|------|-------------------------|-------------------------|
| **`.af-e2e/test-plan.json`** | **`../appsflyer-cordova-plugin-e2e/...`** (or your **`TEST_APP_E2E_COPY_DEST`** + matching JSON edits) | **`<synced-copy>`** (default sibling folder) |
| **`.af-smoke/rc-test-plan.json`** | **`test-app_rc_smoke/...`** | **`./scripts/smoke-cordova-build.sh`** (runs from repo root; internally **`cd`** into **`test-app_rc_smoke/`** after **`sync-test-app-rc-smoke.sh`**) |

**§2.4 implementation:** **`scripts/sync-test-app-rc-smoke.sh`** **`rsync`s** **`test-app/`** → **`test-app_rc_smoke/`** and pins **`cordova-plugin-appsflyer-sdk`** to an npm semver (default: root **`package.json`** **`version`**; override **`SMOKE_PLUGIN_VERSION`** for **`X.Y.Z-rcN`**). **`scripts/smoke-cordova-build.sh`** runs that sync, then **`write-e2e-env-to-dir.sh`** (same **`ENV_FILE`** / **`.af-e2e/.env.local`** / **`test-app/.env`** precedence as E2E), then **`npm install`**, **`cordova platform add`** if needed, and **`cordova build`** (same Android JDK / iOS **`build.json`** behaviour as **`e2e-cordova-build.sh`**).

#### 2.5 Validate Phase 2 (runner + installability)

From **repo root** (with Android emulator **or** iOS simulator already booted when not using `--dry-run`):

```sh
./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json --dry-run
./scripts/af-scenario-runner.sh --platform ios --plan .af-e2e/test-plan.json --dry-run
./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json --build --phase phase_1
```

- **`--build`**: runs your plan’s **`build_cmd`** then installs. Use **`--phase phase_1`** to avoid running all phases while paths are still wrong.
- If **`--build`** fails: fix **`build_cmd`** or local Cordova/Android setup first.
- If install fails: **`package_name`** / **`activity`** / APK path mismatch — fix `config.android`.
- **iOS:** boot a simulator **before** non-`--dry-run` runs (see **Phase 5 — iOS**); then **`--platform ios`** with the same **`--build` / `--phase`** pattern.

**Definition of done for Phase 2**

- [x] **`.af-e2e/test-plan.json`**: `config.android` and `config.ios` match **verified** artifacts under the **E2E sibling copy** (default **`../appsflyer-cordova-plugin-e2e/`**).
- [x] **`.af-smoke/rc-test-plan.json`**: same under **`test-app_rc_smoke/`** after **`smoke-cordova-build.sh`** (paths match **`find`** on **`test-app_rc_smoke/platforms/...`**).
- [x] **`build_cmd`** for each platform is copy-pasteable from a clean state and matches what you intend to encode in **GitHub Actions** later.
- [x] **Android:** successful **`--build`** + **`--phase phase_1`** (and full multi-phase E2E **PASS** on device — see Phase 3).
- [x] **iOS:** successful **`--build`** + **`--phase phase_1`** and full **`cordova-e2e`** plan (**38/38** on Simulator — see Phase 3).
- [ ] Optional for **smoke** plan: same **`--build --phase phase_1`** with **`.af-smoke/rc-test-plan.json`** before CI.

**Phase 2 — E2E CI (§2.6):** **`.github/workflows/android-e2e.yml`** and **`ios-e2e.yml`** call **`e2e-cordova-build.sh`** with **`ENV_FILE`** on the build step (written into the sibling **`.env`** by **`write-e2e-env-to-dir.sh`**), optional **`af-scenario-runner.sh`** (`workflow_dispatch` + **`workflow_call`**), and upload **`.af-e2e/reports/`**. **RC smoke** workflows (**`smoke-cordova-build.sh`** + **`.af-smoke`**) remain **Phase 4 / Phase 6**.

#### 2.6 CI alignment

**Shipped (E2E):** **`android-e2e.yml`** mirrors the Flutter-style Android job: **`ubuntu-latest`**, **Java 17**, **`android-actions/setup-android@v4`** (platform **34** + build-tools), **`npm install -g cordova`**, **`ENV_FILE`** on the build step → **`e2e-cordova-build.sh android`** (which writes **`$(dirname $GITHUB_WORKSPACE)/$(basename $GITHUB_WORKSPACE)-e2e/.env`** via **`write-e2e-env-to-dir.sh`**), then **`reactivecircus/android-emulator-runner@v2`** with **KVM** udev workaround, **`-dns-server 8.8.8.8,1.1.1.1`**, **`nslookup appsflyersdk.com`** before **`./scripts/af-scenario-runner.sh`**, and **`./scripts/dump-android-logs.sh`** on runner failure. Inputs: **`ref`**, **`run_scenarios`** (default true), optional **`scenario_phase`** (passed as **`--phase`**); weekly **`schedule`**. **`ios-e2e.yml`**: **`macos-14`**, CocoaPods + Cordova, same **`ENV_FILE`** → build → sibling **`.env`**, **`./scripts/e2e-cordova-build.sh ios`**, boot first available **iPhone** simulator, then the runner; same **`ref`** / **`run_scenarios`** / **`scenario_phase`** / **`schedule`**. **`ios-e2e`** **PASS** on GitHub Actions with **`ENV_FILE`** (2026-05-13); **`android-e2e`** same run **failed** **`phase_3`** (`is_first_launch_true` vs fresh install — see Phase 3 DoD). Both jobs **`upload-artifact`** **`.af-e2e/reports/`** with **`if: always()`** / **`if-no-files-found: warn`**.

**`sync-test-app-e2e-copy.sh`** (and **`sync-test-app-rc-smoke.sh`**) use **`rsync --filter='protect .env'`** so a pre-created sibling **`.env`** is not deleted on the next sync.

**Still to mirror Flutter (later):** **`rc-smoke.yml`** (**`sync-test-app-rc-smoke.sh`** + **`SMOKE_PLUGIN_VERSION`** + **`smoke-cordova-build.sh`** + **`.af-smoke/rc-test-plan.json`**), **`rc-release`** calling lint + both E2E with **`skip_e2e`**, **`promote-release`**, **`production-release`**.

### Phase 3 — Test app contract (largest engineering chunk)

**Status:** **Implemented in `test-app/`** — `[AF_QA]` auto-run (initSdk `shouldStartSdk: false` → pre/post APIs → `startSdk` → standard + identity + custom + stop-cycle events), **`.env`** via **`hooks/emit-af-qa-env.js`** → **`www/af-qa-env.js`** on **`before_prepare`**, **`cordova-plugin-file`** mirror to **`af_qa_logs.txt`** (Documents / Android `files/`), **`cordova-plugin-customurlscheme`** + **`afqa-cordova://`**. **iOS `simctl launch … -deepLinkURL`:** **`hooks/afqa-ios-simctl-deeplink-replay.js`** (**`after_prepare`**) patches **`AppDelegate.m`** to replay the URL into **`AppsFlyerAttribution`** (Flutter **`example/ios/Runner/AppDelegate.swift`** parity) — **`test-app/README.md`**.

Implement [`test-app-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/test-app-contract.md) in **`test-app/`** (D5 **`widget id`** is already **`com.appsflyer.qa.cordova`** in **`test-app/config.xml`**): load **`DEV_KEY`** / **`APP_ID`** from **`.env`** (HQ-backed — §0.5). Track these items explicitly:

1. **`.env` loading in JS**  
   - Keys: `DEV_KEY`, `APP_ID`.  
   - Never commit `.env`; provide `.env.example`.  
   - On missing `DEV_KEY`, log **`[AF_QA][CONFIG] DEV_KEY missing`** and fail fast (contract).

2. **`[AF_QA]` logging**  
   - Wrap every SDK call, success/error path, and each AppsFlyer callback in structured lines, e.g. `[AF_QA][startSDK] result: SUCCESS`, `[AF_QA][CALLBACK][onInstallConversionData] received: ...`.  
   - Match patterns already used in Flutter reference plans to minimize plan drift.

3. **Auto-run sequence**  
   - `shouldStartSdk: false` on `initSdk`, register **onInstallConversionData**, **onAppOpenAttribution**, **onDeepLinking** (per contract naming), run pre-start APIs, log `--- Pre-start auto APIs complete ---`, then `startSdk()`, then post-start APIs and three events (`af_demo_launch`, `af_purchase`, `af_content_view`) with the same log patterns as Flutter examples.

4. **Deep link scheme**  
   - Prefer `afqa-cordova://` (or keep legacy scheme but then **identical** scheme in all `deep_link_url` fields in both plans).

5. **E2E-only phases (E2E-004..006)**  
   - If the Cordova example app does not yet implement custom events / identity / stop-toggle auto-run, either add them to JS or **temporarily trim** those phases from `cordova-e2e` plan and document as a follow-up (contract still lists scenarios; plan should not claim coverage you do not implement).

**iOS: `Documents/af_qa_logs.txt` (required)**

Cordova UI code is JS; the contract still requires an **append-only file** under the app sandbox. **Implemented:** **`cordova-plugin-file`** from JS appends each **`[AF_QA]`** line to **`af_qa_logs.txt`** under **`cordova.file.dataDirectory`** (iOS Documents / Android app **`files/`**), which matches what **`af-scenario-runner.sh`** discovers. A custom native helper remains optional if tooling path resolution drifts — follow [`docs/troubleshooting.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/docs/troubleshooting.md) if paths differ.

**Definition of done (Phase 3)**

- [x] **`.env.example`** in **`test-app/`**; **`.env`** gitignored; **`hooks/emit-af-qa-env.js`** + **`config.xml`** **`before_prepare`** → **`www/af-qa-env.js`** (gitignored).
- [x] **`www/js/index.js`**: **`[AF_QA]`** logs, missing **`DEV_KEY`** → **`[AF_QA][CONFIG] DEV_KEY missing`**, manual **`startSdk`** flow, standard + E2E-style events, **`Stop(true/false)`** cycle, completion marker **`[AF_QA][AUTO_APIS] --- Auto run complete ---`**.
- [x] **`afqa-cordova://`** via **`cordova-plugin-customurlscheme`**; **`allow-intent`** on Android as needed.
- [x] **File mirror** for runner log collection on iOS (and Android parity).
- [x] **Android — full E2E plan:** **`.af-e2e/test-plan.json`** end-to-end on a real device or emulator with real **`DEV_KEY` / `APP_ID`** (via sibling **`.env`** or **`ENV_FILE`** in CI) — **verified** (operator run: **38/38** checks **PASS**, `cordova-e2e` / Android). **GitHub Actions `android-e2e`:** **not** fully green yet — **2026-05-13** run **ABORTED** in **`phase_3`** (`Foreground deep link`): check **`is_first_launch_true`** could not find **`[AF_QA][CALLBACK][onInstallConversionData]`** with **`is_first_launch=true`** (logcat showed **`is_first_launch=false`**, **`counter":"2"`** — process not treated as first launch after `requires_fresh_install`).
- [x] **iOS:** full **`cordova-e2e`** **`.af-e2e/test-plan.json`** on a **booted** Simulator — **verified** (**38/38** checks **PASS**, UDID `E27C6A56-189C-4039-B966-6839D58DF70F`; operator run 2026-05-13). **GitHub Actions `ios-e2e`:** **PASS** with **`ENV_FILE`** (CI verified 2026-05-13).

**iOS: SMOKE-002 / E2E deep link delivery (`-deepLinkURL`)**

**Done (test-app):** **`hooks/afqa-ios-simctl-deeplink-replay.js`** injects a Flutter-style **`AppDelegate.m`** replay (argv **`-deepLinkURL`**, optional **`UserDefaults` `deepLinkURL`**, **`dispatch_after(5s)`**, **`[[AppsFlyerAttribution shared] handleOpenUrl:… options:@{}]`**). E2E / smoke plans keep **`simctl terminate` + `sleep 2`** then **`simctl launch … -deepLinkURL`** (see **`.af-e2e`** / **`.af-smoke`** JSON). **`test-app/README.md`** documents behavior and Cordova template drift.

### Phase 4 — RC smoke app (**Flutter `rc-smoke.yml` pattern**)

Do **not** commit a long-lived duplicate of the example app for smoke. Instead:

1. **Synthesize** a directory (e.g. `test-app_rc_smoke/`) in the smoke workflow: **`rsync -a`** from **`test-app/`** with excludes mirroring Flutter’s intent — drop **`node_modules/`**, **`platforms/`**, **`plugins/`** (regenerated by `cordova prepare`), lockfiles if you regenerate them, **`.env`**, IDE junk — but **keep `www/`** (Cordova web assets are source, not a rebuild artifact like Flutter’s `build/`).
2. **Patch dependency:** set the AppsFlyer Cordova plugin spec in **`package.json`** / **`config.xml`** to the **exact published RC version** (no `file:../../`). Use the **`rc_version`** string from the **`resolve`** job (manual dispatch) or from **`package.json`/`plugin.xml` on the release branch** (automatic path), same split as Flutter.
3. Pass **`ENV_FILE`** into **`smoke-cordova-build.sh`** (same as E2E: the script runs **`write-e2e-env-to-dir.sh`** and writes **`<smoke_dir>/.env`** before **`cordova prepare`**), or pre-write **`<smoke_dir>/.env`** after the copy if you prefer a discrete workflow step.
4. **`npm ci`** / **`cordova prepare`** / **`cordova build …`** from **`<smoke_dir>`**, then **`./scripts/af-scenario-runner.sh --platform <android|ios> --plan .af-smoke/rc-test-plan.json`** (add `--build` only if the plan does not already embed build in `build_cmd`).
5. **`resolve` job parity:** implement the same branches as Flutter: parent workflow not success → skip; **dry-run RC** / version never appears on npm within timeout → post **`skipped`** **check_run** on the release head SHA so **`promote-release`** cannot treat “never ran” as success; only **`success`** when smoke passes.
6. Upload **`.af-smoke/reports/`** artifacts; post **`check_run`** (name e.g. **`rc-smoke/npm`**) on **`needs.resolve.outputs.head_sha`** for the promote workflow to query (mirror **`promote-release.yml`** + **`rc-smoke/pub.dev`** in Flutter).

Reference files: **appsflyer-flutter-plugin** `.github/workflows/rc-smoke.yml`, `.github/workflows/promote-release.yml`.

### Phase 5 — Local verification

From **plugin repo root**, use the **vendored** runner (Flutter default):

```sh
chmod +x scripts/af-scenario-runner.sh scripts/sync-test-app-e2e-copy.sh scripts/e2e-cordova-build.sh scripts/write-e2e-env-to-dir.sh scripts/sync-test-app-rc-smoke.sh scripts/smoke-cordova-build.sh scripts/ci-android-e2e-scenario.sh   # once after clone

./scripts/af-scenario-runner.sh \
  --platform android --plan .af-e2e/test-plan.json --dry-run

./scripts/af-scenario-runner.sh \
  --platform android --plan .af-e2e/test-plan.json --build --verbose
```

#### iOS — build and run E2E locally

The runner resolves **`{{UDID}}`** from the **currently booted** simulator (`ios_get_booted_udid` inside **`af-scenario-runner.sh`**). If none is booted, it errors with a hint to **`xcrun simctl boot <UDID>`**. **`./scripts/e2e-cordova-build.sh ios`** does not start a simulator — match **`.github/workflows/ios-e2e.yml`**: shut down stray sims, boot one **iPhone** sim, wait until ready, build, then run the plan.

1. **Credentials** — same as Android: ensure the **E2E sibling** has **`.env`** with **`DEV_KEY`** and **`APP_ID`** before **`cordova prepare`** (e.g. **`./scripts/bootstrap-e2e-env.sh`**, or **`ENV_FILE=… ./scripts/write-e2e-env-to-dir.sh`**, or copy **`.af-e2e/.env.local`** / **`test-app/.env`** per **`test-app/README.md`**).

2. **Boot a simulator** (example: first available **iPhone**; pick a **`UDID`** from **`xcrun simctl list devices available`** if you prefer a fixed model):

```sh
xcrun simctl shutdown all || true
UDID="$(xcrun simctl list devices available -j | jq -r '
  [(.devices // {}) | to_entries[] | .value[]
    | select(.isAvailable == true and ((.name // "") | contains("iPhone")))]
  | if length == 0 then "" else .[0].udid end
')"
test -n "$UDID" || { echo "No iPhone simulator"; exit 1; }
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
```

3. **Build** the E2E app (sync sibling + **`cordova build ios`** for Simulator — same as CI **`Build Cordova E2E (iOS)`** step):

```sh
./scripts/e2e-cordova-build.sh ios
```

4. **Run** all phases (install / launch / deep links / log assertions). CI omits **`--build`** here because step 3 already built; locally you can use either pattern:

```sh
# Same as ios-e2e.yml "Run af-scenario-runner (iOS)" — all phases
./scripts/af-scenario-runner.sh --platform ios --plan .af-e2e/test-plan.json --verbose

# Optional: one phase while debugging
./scripts/af-scenario-runner.sh --platform ios --plan .af-e2e/test-plan.json --verbose --phase phase_1

# Optional: let the runner invoke the plan’s build_cmd first (rebuild + run)
./scripts/af-scenario-runner.sh --platform ios --plan .af-e2e/test-plan.json --build --verbose
```

5. **Manual launch only** (no scenario assertions) — after a successful **`e2e-cordova-build.sh ios`**, **`cd`** to the E2E sibling (path is **`$(cat .af-e2e/e2e_copy_dest.txt)`** from repo root; default **`../appsflyer-cordova-plugin-e2e`**), then **`cordova run ios --debug`**. Or from repo root: **`./scripts/e2e-cordova-build.sh ios run`** (forces a simulator destination; see **`test-app/README.md`**).

**Smoke locally (optional):** **`./scripts/smoke-cordova-build.sh android|ios`**, then **`./scripts/af-scenario-runner.sh --platform android --plan .af-smoke/rc-test-plan.json --dry-run`** (or **`--build --phase phase_1`**).

**Alternate (no vendored script yet):** `../appsflyer-mobile-plugin-tooling/scripts/af-scenario-runner.sh` from a sibling clone — not the CI default once **B** is merged.

### Phase 6 — CI integration (**mirror appsflyer-flutter-plugin**)

Use **appsflyer-flutter-plugin** `.github/workflows/` as the template tree:

| Flutter workflow | Cordova analogue |
|------------------|------------------|
| `lint-test-build.yml` | Your existing lint/unit + **release-style** Android/iOS builds (or new composite workflow); expose **`skip_unit`** / **`skip_builds`**-style flags only if you need parity with Flutter’s RC inputs |
| `ios-e2e.yml` | **Shipped:** **`.github/workflows/ios-e2e.yml`** (**`macos-14`**, first booted **iPhone** sim, **`ENV_FILE`** on build step → **`e2e-cordova-build.sh ios`**, **`af-scenario-runner.sh`**, **`upload-artifact`** **`.af-e2e/reports/`**). Optional **`af_qa_logs.txt`** / simctl dumps on failure — add when tightening parity with Flutter. |
| `android-e2e.yml` | **Shipped:** **`.github/workflows/android-e2e.yml`** (**`ubuntu-latest`**, **`android-actions/setup-android`**, **`reactivecircus/android-emulator-runner`**, KVM, DNS + **`nslookup`**, **`ENV_FILE`** on build step → **`e2e-cordova-build.sh android`**, runner, **`dump-android-logs`** on failure). |
| `rc-release.yml` | Orchestrate **`workflow_call`** into lint + **both E2E** workflows; **`skip_e2e`** must **block npm publish** when E2E is required (same gate semantics as Flutter); inputs for **`dry_run`**, version bumps, etc. |
| `rc-smoke.yml` | **`workflow_run`** on the RC workflow name; **`resolve`** + npm poll; **synthesize** smoke app dir; iOS + Android smoke jobs; artifacts **`.af-smoke/reports/`**; **`check_run`** for promote |
| `promote-release.yml` | **`github-script`** (or equivalent) verifying **`rc-smoke/npm`** is **`success`** on PR head SHA before stripping **`-rcN`** |
| `production-release.yml` | Post-merge **npm** publish + GitHub release (registry differs from pub.dev; structure mirrors Flutter) |

**Dependencies in jobs:** ensure **`jq`**, **Android SDK / Cordova CLI**, **Node**, and **Java/Xcode** versions match what the example app requires.

**Do not** bypass the runner for assertions in CI; fail the job on non-zero **`af-scenario-runner.sh`** exit (Flutter pattern).

### Phase 7 — Documentation and skills (optional but recommended)

1. Short **operator doc** in `docs/`: mirror Flutter’s operator story — **`ENV_FILE`** secret shape, how to trigger **RC** vs **smoke** dispatch, where **`latest.json`** lands under **`.af-e2e/reports/`** / **`.af-smoke/reports/`**, and how to refresh **`scripts/af-scenario-runner.sh`** from a new tooling tag.
2. **Agent skills:** Cordova-specific skills live under **`.claude/skills/`** (canonical `SKILL.md` files for **Claude Code** and documentation) with **symlinks** from **`.cursor/skills/`** so **Cursor** discovers the same content — see **`.claude/README.md`**. Names: **`cordova-scenario-runner`**, **`cordova-smoke-ci-alignment`**, **`cordova-test-app-contract`**, **`cordova-rc-release`** (adapted from `appsflyer-mobile-plugin-tooling/templates/{claude-skills,cursor-skills}/`). Legacy **`cordova-release-version-bump`** remains a real directory under **`.cursor/skills/`** only unless you relocate it the same way.

## 4. Open questions (need your input)

**Phase 0 (D1–D6)** is **closed** — see **§3 Phase 0 decision log** and **§0.6 Recorded**.

**Still external / operational (not “open” decisions):**

- **AppsFlyer HQ** — create app **`com.appsflyer.qa.cordova`**, populate **`ENV_FILE`** (§0.5).

**Next implementation step:** **§3 Phase 4** (RC smoke synthesis + **`rc-smoke`** workflow) and **Phase 6** (wire **`rc-release`** / promote gates). **E2E:** **`cordova-e2e`** **38/38** operator-verified on **Android** + **iOS**; **GitHub Actions `ios-e2e`** green with **`ENV_FILE`**; **`android-e2e`** CI needs **`phase_3`** / **`requires_fresh_install`** alignment (first-launch assertion) on emulator.

**Repo hygiene (unchanged):** `.gitignore` has `.env`, `.env.local`, `.af-e2e/reports/`, `.af-smoke/reports/`, **`test-app_rc_smoke/`**, **`test-app/www/af-qa-env.js`**. **`test-app/.env.example`** is committed (template only).

## 5. Reference index (read during implementation)

| Document | Where |
|----------|--------|
| **Flutter plugin (live CI + plans)** | [`AppsFlyerSDK/appsflyer-flutter-plugin`](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin) — especially `.github/workflows/{android-e2e,ios-e2e,rc-smoke,rc-release,promote-release,production-release,lint-test-build}.yml`, `.af-e2e/test-plan.json`, `.af-smoke/rc-test-plan.json`, `scripts/af-scenario-runner.sh` |
| Runner usage | [`appsflyer-mobile-plugin-tooling/scripts/README.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/scripts/README.md) |
| CI stages / gates | [`appsflyer-mobile-plugin-tooling/docs/ci-alignment-guide.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/docs/ci-alignment-guide.md) |
| Test app normative rules | [`appsflyer-mobile-plugin-tooling/contracts/test-app-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/test-app-contract.md) |
| E2E scenario IDs | [`appsflyer-mobile-plugin-tooling/contracts/e2e-test-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/e2e-test-contract.md) |
| Smoke scenario IDs | [`appsflyer-mobile-plugin-tooling/contracts/smoke-test-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/smoke-test-contract.md), `docs/smoke-scenarios/SMOKE-*.md` |
| JSON schema | [`appsflyer-mobile-plugin-tooling/schemas/smoke-test-plan.schema.json`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/schemas/smoke-test-plan.schema.json) |
| Static Flutter JSON copies | [`appsflyer-mobile-plugin-tooling/examples/flutter/e2e-test-plan.json`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/examples/flutter/e2e-test-plan.json), [`rc-test-plan.json`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/examples/flutter/rc-test-plan.json) |
| Failure playbook | [`appsflyer-mobile-plugin-tooling/docs/troubleshooting.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/docs/troubleshooting.md) |

---

*Phase 0 (§4) is closed. For later phases, tick items in §3 in PR descriptions for traceability.*
