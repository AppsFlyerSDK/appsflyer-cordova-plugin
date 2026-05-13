# `test-app/` — automation shell (Cordova, **reference only**)

This folder is the **source of truth** for the small Cordova app used by **`.af-e2e/test-plan.json`** and (after CI synthesis) **`.af-smoke/rc-test-plan.json`**.

- **`examples/cordovatestapp/`** stays the **manual / legacy** sample; scenario runner targets **`test-app`** contract work, not that tree.
- **`widget id`** is **`com.appsflyer.qa.cordova`** (D5). HQ app + **`.env`** — see repo **`docs/SCENARIO_RUNNER_ADOPTION_WORKPLAN.md`** §0.5.
- **Phase 3 (contract)** is implemented in **`www/js/index.js`**: **`[AF_QA]`** structured logs, **`shouldStartSdk: false`** + **`startSdk()`**, three standard events + **`af_qa_custom_purchase`** + identity + **`Stop(true/false)`** cycle, marker **`[AF_QA][AUTO_APIS] --- Auto run complete ---`**. Normative doc: [**test-app contract**](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/test-app-contract.md).

### `.env` and `www/af-qa-env.js`

- **Where the hook looks:** **`hooks/emit-af-qa-env.js`** runs on **`cordova prepare`** / **`build`**, reads **the Cordova project root’s** **`.env`**, and writes **`www/af-qa-env.js`** (`window.__AF_QA_ENV__`). **`www/index.html`** loads that file before **`js/index.js`**. For E2E, the project root is the **sibling** (path in **`.af-e2e/e2e_copy_dest.txt`**), not `test-app/` in the plugin repo unless you build there.
- **Credentials:** **`./scripts/e2e-cordova-build.sh`** runs **`scripts/write-e2e-env-to-dir.sh`** after sync and **before** **`npm install` / `cordova build`**, writing the E2E sibling **`.env`**: **`ENV_FILE`** env (GitHub: **`secrets.ENV_FILE`** on the build step), else **`.af-e2e/.env.local`**, else **`test-app/.env`**. **`hooks/emit-af-qa-env.js`** runs on **`before_prepare`** and writes **`www/af-qa-env.js`** so keys are present when www is copied into native projects.
- **E2E sibling only (no `test-app/.env`):** template **`.af-e2e/env.example`**. Run **`./scripts/bootstrap-e2e-env.sh`** once to seed **`$(cat .af-e2e/e2e_copy_dest.txt)/.env`** (from plugin repo root) if missing, then edit. Paste the same two **`KEY=value`** lines into the GitHub Actions secret **`ENV_FILE`** (multiline).
- Never commit **`.env`**. If you still see **`[AF_QA][CONFIG] DEV_KEY missing`**, the sibling **`.env`** was empty or missing at **`cordova prepare`** time — re-sync (or edit sibling **`.env`**) and rebuild.

### Plugins used by the QA shell only

- **`cordova-plugin-file`** — append **`[AF_QA]`** lines to **`af_qa_logs.txt`** under **`cordova.file.dataDirectory`** (iOS Documents / Android `files/`) so **`af-scenario-runner.sh`** can read the same markers as **`simctl log`** / **`adb logcat`**.
- **`cordova-plugin-customurlscheme`** — registers **`afqa-cordova://`** for deep-link phases (see **`.af-e2e`** `deep_link_url` values).

### iOS deep link: `simctl launch … -deepLinkURL`

E2E **phase_2+** uses **`xcrun simctl launch <UDID> <BUNDLE_ID> -deepLinkURL "<url>"`** so CI avoids the iOS Simulator **“Open in …?”** sheet that **`simctl openurl`** shows for custom schemes. That launch flag does **not** call `application:openURL:options:`.

**Flutter parity:** the Flutter **example** app patches **`AppDelegate.swift`** to read **`-deepLinkURL`** from **`ProcessInfo`** (and optionally **`UserDefaults` `deepLinkURL`**) and, after a **5s** delay, replay through **`application(_:open:options:)`**. This repo’s **`test-app`** does the same in **`hooks/afqa-ios-simctl-deeplink-replay.js`**: on **`after_prepare`**, it injects a small block into the generated **`platforms/ios/**/AppDelegate.m`** that schedules **`[[AppsFlyerAttribution shared] handleOpenUrl:… options:@{}]`** — the same queue the AppsFlyer Cordova plugin uses for real URL opens. Re-run **`cordova prepare ios`** (or **`e2e-cordova-build.sh ios`**) after upgrading **cordova-ios** if the stock **`AppDelegate.m`** template changes (the hook looks for a specific `return [super application:…]` line).

## Why you should not `cordova build` here

This directory lives **inside** the plugin repository. Cordova resolves **`file:..`** / **`spec=".."`** by copying the **entire plugin tree** into **`test-app/plugins/`**. That tree **still contains `test-app/`**, so the copy can recurse and hit **`ENAMETOOLONG`**.

**Workflow:** keep editing **`test-app/`** in-repo, then **sync to a sibling directory** (outside this repo folder) and run Cordova there. **`scripts/sync-test-app-e2e-copy.sh`** does the copy and patches **`file:`** + **`config.xml`** to point at the real plugin root.

## Default sibling layout

If the plugin repo directory is **`…/appsflyer-cordova-plugin`**, the default E2E copy is:

```text
…/appsflyer-cordova-plugin/          ← plugin root (this repo)
…/appsflyer-cordova-plugin-e2e/      ← rsync destination (not committed; outside plugin tree)
```

The copy is created next to the plugin folder: **`<parent>/<basename>-e2e`**. If your clone is **not** named `appsflyer-cordova-plugin`, the sibling becomes **`<that-name>-e2e`** — then update **`.af-e2e/test-plan.json`** `apk_path` / `app_path` to match, **or** set **`TEST_APP_E2E_COPY_DEST`** to an absolute path and adjust JSON paths accordingly.

## Commands (always from **plugin repo root**)

**Sync only** (refresh the sibling tree from `test-app/`):

```sh
./scripts/sync-test-app-e2e-copy.sh
```

**Sync + `npm install` + add platform if missing + build** (what **`.af-e2e`** `build_cmd` uses — **build only**, no simulator/emulator launch):

```sh
./scripts/e2e-cordova-build.sh android
./scripts/e2e-cordova-build.sh ios
```

**Build and run** on emulator / simulator — **optional, for local sanity checks** only (see below; **automated E2E** should **not** rely on **`run`**):

```sh
./scripts/e2e-cordova-build.sh android run
./scripts/e2e-cordova-build.sh ios run
```

Second argument **`run`** runs **`cordova run … --emulator`** (forces simulator/emulator so a USB device does not steal **`cordova run android`**). **`ios run`** passes the same **`build.json`** as **`ios`** when present (**`-destination generic/platform=iOS Simulator`**).

### How automated E2E distinguishes tests (Flutter-style)

You do **not** get separate “tests” by calling **`cordova run`** repeatedly. **`cordova run`** builds/installs/launches **one** app shell; it has no notion of **`E2E-001`** vs **`E2E-002`**.

**Separation matches Flutter:** **`build_cmd`** in **`.af-e2e/test-plan.json`** should stay **`./scripts/e2e-cordova-build.sh ios`** (and **`android`**) — **produce the `.app` / APK only**. Then **`./scripts/af-scenario-runner.sh --plan .af-e2e/test-plan.json`** (with **`--build`** omitted once the artifact exists, or with **`--build`** if you want the runner to invoke **`build_cmd`**) **installs, launches, sends deep links / intents, tails logs, and asserts** per **phase** in the JSON. Each phase has **`scenario_ref`** (**`E2E-*`**, **`SMOKE-*`**) and step definitions; that is how runs differ — same binary, different scripted interactions and assertions.

Use **`ios run` / `android run`** when you want to **click around manually** or confirm the app boots. Use **build + runner** for CI and contract coverage.

**Run on device / emulator** (after a successful build, from the **sibling** directory):

```sh
cd ../appsflyer-cordova-plugin-e2e
cordova run android --debug
cordova run ios --debug
```

(Adjust the path if you use **`TEST_APP_E2E_COPY_DEST`**. You can read the last sync target from **`.af-e2e/e2e_copy_dest.txt`** in the plugin repo.)

**Android APK install without `cordova run`** (paths assume default sibling name):

```sh
adb install -r ../appsflyer-cordova-plugin-e2e/platforms/android/app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.appsflyer.qa.cordova/.MainActivity
```

**Incremental Android rebuild** (after **`platforms/android`** exists, faster than a full **`cordova build`** for native-only tweaks): from the **sibling** project, use the same JDK as **`e2e-cordova-build.sh`** (JDK **17** + **`GRADLE_OPTS=-Dorg.gradle.java.home=$JAVA_HOME`** if your global **`~/.gradle/gradle.properties`** pins another JDK), then:

```sh
cd ../appsflyer-cordova-plugin-e2e/platforms/android
./tools/gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Adjust the sibling path if **`TEST_APP_E2E_COPY_DEST`** is not the default.

## Environment variables

| Variable | Purpose |
|----------|---------|
| **`TEST_APP_E2E_COPY_DEST`** | Absolute path of the sync destination. Overrides **`<parent>/<basename>-e2e`**. If you change it, update **`.af-e2e/test-plan.json`** paths to the same location (relative to repo root). |
| **`CORDOVA_E2E_ANDROID_JAVA_HOME`** | Android only: force **`JAVA_HOME`** (e.g. JDK 17). Use when the default JDK is too new for Cordova’s Gradle/AGP and you are not on macOS auto-pick. |
| **`CORDOVA_E2E_RESPECT_JAVA_HOME`** | Set to **`1`** to skip auto-switching **`JAVA_HOME`** on Android (see below). |
| **`CORDOVA_E2E_IOS_BUILDCONFIG`** | Optional absolute path to a Cordova **`build.json`** for iOS. If unset and **`build.json`** exists in the E2E app root, **`e2e-cordova-build.sh`** uses it (generic simulator destination). |
| **`SMOKE_PLUGIN_VERSION`** | RC smoke only: exact npm version for **`cordova-plugin-appsflyer-sdk`** in **`test-app_rc_smoke/`** (default: root **`package.json`** **`version`**). |

### Android: JDK / Gradle (`Unsupported class file major version 69`)

That message means **bytecode for Java 25** (major 69) met a **JVM that cannot load it** — often **Gradle’s daemon is not the same JDK as `java` on your shell**.

**Typical cause:** **`~/.gradle/gradle.properties`** sets **`org.gradle.java.home`** to a **newer JDK** (e.g. Android Studio’s JBR or JDK 25). The **`gradlew`** script may start with **Java 17** from `PATH`, but Gradle then **forks a daemon** using that property, loads **AGP / Kotlin** jars built for a newer classfile version, and the **older** daemon JVM hits **`Unsupported class file major version 69`**.

**Fix:**

1. Run **`./scripts/e2e-cordova-build.sh android`** again after updating the script: it sets **`GRADLE_OPTS=-Dorg.gradle.java.home=…`** from **`JAVA_HOME`** (on macOS it prefers **`/usr/libexec/java_home -v 17`**, then **21**), which **overrides** the global Gradle JDK for this build, and stops existing daemons under **`platforms/android/tools`** first.
2. Or edit **`~/.gradle/gradle.properties`**: remove or point **`org.gradle.java.home`** at JDK **17**.
3. If **`platforms/android/tools/.gradle`** still mentions the wrong Gradle version vs **`gradle/wrapper/gradle-wrapper.properties`**, remove that folder in the E2E sibling and rebuild:

```sh
rm -rf "$(cat .af-e2e/e2e_copy_dest.txt)/platforms/android/tools/.gradle"
```

### iOS: CocoaPods `AppsFlyerFramework` / deployment target

If **`pod install`** fails with **“required a higher minimum deployment target”** for **`AppsFlyerFramework`**, the Cordova app’s **`IPHONEOS_DEPLOYMENT_TARGET`** is below the SDK pod’s minimum ( **`AppsFlyerFramework` 6.18.x** declares **iOS 12.0** in its podspec). **`test-app/config.xml`** sets **`<preference name="deployment-target" value="12.0" />`** under **`<platform name="ios">`**. After changing it, from the **sibling** tree run **`cordova platform rm ios`** then **`cordova platform add ios`**, or wipe **`platforms/ios`** and run **`./scripts/e2e-cordova-build.sh ios`** again.

### iOS: `xcodebuild` destination / “no available devices matched the request”

Cordova’s default simulator (**often iPhone SE (3rd generation)**) is passed to **`xcodebuild`** as **name only**; newer Xcode then uses **`OS:latest`**, which may not match any installed runtime for that device type.

**`test-app/build.json`** (copied into the E2E sibling by **`sync-test-app-e2e-copy.sh`**) sets **`buildFlag`** to **`-destination generic/platform=iOS Simulator`** so the debug build does not depend on a specific simulator model. **`e2e-cordova-build.sh`** passes **`--buildConfig=…/build.json`** when that file exists in the E2E app root.

Override with **`CORDOVA_E2E_IOS_BUILDCONFIG=/path/to/other-build.json`**, or add your own **`buildFlag`** **`-destination …`** there (e.g. **`platform=iOS Simulator,id=<UDID>`** from **`xcrun simctl list devices available`**).

The CocoaPods warnings about **`LD_RUNPATH_SEARCH_PATHS`** are common with Cordova + Pods; they do not block a typical debug simulator build.

## Scenario runner

From **plugin repo root** (runner resolves **`apk_path`** / **`app_path`** relative to this root):

```sh
./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json --dry-run
./scripts/af-scenario-runner.sh --platform android --plan .af-e2e/test-plan.json --build --verbose
./scripts/af-scenario-runner.sh --platform ios --plan .af-e2e/test-plan.json --dry-run
```

Use **`--build`** only when you want the runner to execute the plan’s **`build_cmd`**; otherwise build with **`e2e-cordova-build.sh`** first, then run the runner without **`--build`** for faster iteration.

## RC smoke (CI + local)

**`.af-smoke/rc-test-plan.json`** expects artifacts under **`test-app_rc_smoke/`** (gitignored). **`build_cmd`** runs **`./scripts/smoke-cordova-build.sh android`** / **`ios`**, which:

1. **`scripts/sync-test-app-rc-smoke.sh`** — **`rsync`** from **`test-app/`** (same excludes as E2E sync), then pins **`cordova-plugin-appsflyer-sdk`** in **`package.json`** and **`config.xml`** to an **npm semver** (default: root **`package.json`** **`version`**; override with **`SMOKE_PLUGIN_VERSION`** for **`X.Y.Z-rcN`**).
2. **`npm install`**, **`cordova platform add`** if needed, **`cordova build`** (same JDK / **`build.json`** behaviour as **`e2e-cordova-build.sh`** on Android/iOS).

**Local smoke build** (from plugin repo root, after the version exists on npm):

```sh
./scripts/smoke-cordova-build.sh android
./scripts/smoke-cordova-build.sh ios
```

Then **`find test-app_rc_smoke/platforms/...`** and confirm **`.af-smoke/rc-test-plan.json`** **`apk_path`** / **`app_path`** match.

CI mirrors the same idea: **`rsync`** + pin to the **published RC** version + **`ENV_FILE`** → **`.env`**, then **`smoke-cordova-build.sh`** (or inline equivalent).
