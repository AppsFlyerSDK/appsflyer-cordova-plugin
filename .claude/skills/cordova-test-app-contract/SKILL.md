---
name: cordova-test-app-contract
description: >-
  Build or review test-app/ for AppsFlyer Cordova against the tooling test-app contract: .env,
  [AF_QA] logs, auto-run SDK order, afqa-cordova deep links, iOS af_qa_logs.txt. Use when
  implementing Phase 3 or reviewing test-app PRs.
globs: test-app/**,.af-e2e/test-plan.json,.af-smoke/rc-test-plan.json
---

# Test app contract — AppsFlyer Cordova (`test-app/`)

Use when:

- Implementing **Phase 3** in `test-app/` (`www/`, `config.xml`, native hooks if needed).
- Reviewing PRs that touch the automation shell, logging, or deep links.
- Explaining why E2E/smoke **phase_1** checks fail (missing `[AF_QA]` lines or iOS file log).

## Contract source

Normative: [`appsflyer-mobile-plugin-tooling/contracts/test-app-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/test-app-contract.md).

## Cordova layout

| Item | Location |
|------|----------|
| Widget / bundle id | `com.appsflyer.qa.cordova` — `test-app/config.xml` |
| JS entry | `test-app/www/js/index.js` (and `www/index.html`) |
| E2E execution | **Sibling copy** only — `scripts/sync-test-app-e2e-copy.sh` + `scripts/e2e-cordova-build.sh`; do not `cordova build` from in-repo `test-app/` with `file:..` (`ENAMETOOLONG` risk) |
| `.env` (E2E sibling) | `../appsflyer-cordova-plugin-e2e/.env` (CI: `ENV_FILE` secret) |
| Deep link scheme (plan) | `afqa-cordova://` — must match `deep_link_url` entries in `.af-e2e` / `.af-smoke` JSON |

## Required behaviors (summary)

1. Load **`DEV_KEY`**, **`APP_ID`** from `.env` at runtime; never commit `.env`. Provide `test-app/.env.example`. On missing key, log **`[AF_QA][CONFIG]`** and fail fast per contract.
2. Prefix structured lines with **`[AF_QA]`** — e.g. `[AF_QA][startSDK] result: SUCCESS`, `[AF_QA][CALLBACK][onInstallConversionData] …`.
3. **Auto-run** on launch (no UI): `shouldStartSdk: false` / manual start pattern per Cordova plugin API → register **onInstallConversionData**, **onAppOpenAttribution**, **onDeepLinking** → pre-start APIs → log **`--- Pre-start auto APIs complete ---`** → **`startSdk()`** → post-start APIs → three events (`af_demo_launch`, `af_purchase`, `af_content_view`).
4. **iOS:** append the same `[AF_QA]` lines to **`Documents/af_qa_logs.txt`** (Cordova: small native plugin, hook, or `cordova-plugin-file` — see workplan §Phase 3). The scenario runner prefers this file on iOS because `simctl log show` often misses WebView `console.log` output.

## Scenario runner “ready” markers

Plans poll / grep for lines including:

- `[AF_QA][startSDK] result: SUCCESS`
- `[AF_QA][AUTO_APIS] --- Auto run complete ---` (or pre/post complete lines per plan JSON — keep spelling identical to `.af-e2e/test-plan.json`)

Until the test app emits these, **phase_1 will fail** even when install/launch succeeds.

## Reviewer checklist (Cordova)

- [ ] Bundle/package id matches `.af-e2e` / `.af-smoke` `config.*`
- [ ] No hardcoded keys; `.env` documented
- [ ] Callbacks registered **before** `startSdk`
- [ ] `[AF_QA]` strings match plan patterns exactly
- [ ] Standard event names unchanged
- [ ] `afqa-cordova` URL scheme on Android + iOS
- [ ] iOS **`af_qa_logs.txt`** implemented and flushed
- [ ] Fresh install on clean device passes SMOKE/E2E cold-launch checks when plans are enabled

## Do not

- Do not change `[AF_QA]` prefix or plan regexes ad hoc.
- Do not gate auto-run behind a button — CI does not tap UI.
