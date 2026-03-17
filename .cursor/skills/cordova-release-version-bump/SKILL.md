---
name: cordova-release-version-bump
description: Performs a simple version-bump release of the AppsFlyer Cordova plugin (no public API changes). Use when the user wants to release a new Cordova plugin version that only updates SDK dependencies (Android, iOS) and plugin version.
---

# Cordova Plugin Version Bump Release

This skill guides a **simple version bump release** — no public API changes, only Cordova plugin version and native SDK dependency updates.

---

## Step 0: Gather Versions (First Action)

**Before doing anything else**, ask the user for these three versions:

1. **Cordova plugin version** (e.g., `6.17.9`)
2. **Android SDK version** (e.g., `6.17.5`)
3. **iOS SDK version** (e.g., `6.17.8`)

Example prompt:
> To proceed with the version bump release, I need:
> - **Cordova plugin version** (e.g., 6.17.9):
> - **Android SDK version** (e.g., 6.17.5):
> - **iOS SDK version** (e.g., 6.17.8):

Use RC number `1` for the release branch unless the user specifies otherwise (e.g., `6.17.9-rc2`).

---

## Step 1: Manual — Create Jira Fixed Version

**Stop and ask the user** to create the Jira fixed version before continuing:

> Before I proceed, please create the Jira fixed version **Cordova SDK v{major}.{minor}.{patch}** (e.g., Cordova SDK v6.17.9) in Jira and associate any relevant tickets with it. The release workflows require this to exist.
>
> Reply when done.

Do not continue until the user confirms.

---

## Step 2: Update Version Files

Apply the versions to these files:

| File | What to update |
|------|----------------|
| `package.json` | `"version": "{cordova_version}"` |
| `plugin.xml` | `version="{cordova_version}"` (root plugin element) |
| `plugin.xml` | `<pod name="AppsFlyerFramework" spec="{ios_version}"/>` |
| `src/android/cordovaAF.gradle` | `implementation 'com.appsflyer:af-android-sdk:{android_version}@aar'` |
| `src/android/com/appsflyer/cordova/plugin/AppsFlyerConstants.java` | `PLUGIN_VERSION = "{android_version}"` |
| `src/ios/AppsFlyerPlugin.m` | `pluginVersion:@"{ios_version}"` in `setPluginInfoWith:AFSDKPluginCordova` |
| `README.md` | In "This plugin is built for" section: `iOS AppsFlyerSDK **v{ios_version}**` and `Android AppsFlyerSDK **v{android_version}**` |

---

## Step 3: Manual — Test Changes and Verify NPM Token Before Push

**Stop and ask the user** to:

1. **Test the changes locally** (e.g., build the example app, verify the plugin works).
2. **Verify the NPM access token is not expired**: The token is stored in [GitHub Actions secrets](https://github.com/AppsFlyerSDK/appsflyer-cordova-plugin/settings/secrets/actions) as `CI_NPM_TOKEN`. It is used to publish to https://www.npmjs.com/ — if expired, the QA and production pipelines will fail.

> I've updated all version files. Before we push the release branch, please:
> 1. Test the changes locally (e.g., build the example app, verify the plugin works).
> 2. Confirm that the NPM access token (`CI_NPM_TOKEN`) in [GitHub Actions secrets](https://github.com/AppsFlyerSDK/appsflyer-cordova-plugin/settings/secrets/actions) is not expired.
>
> Reply when you've verified both and are ready to push.

Do not continue to Step 4 until the user confirms.

---

## Step 4: Create Release Branch and Push

```bash
git checkout master
git pull origin master
git checkout -b releases/{major}.x.x/{major}.{minor}.x/{cordova_version}-rc1
git add package.json plugin.xml src/android/cordovaAF.gradle src/android/com/appsflyer/cordova/plugin/AppsFlyerConstants.java src/ios/AppsFlyerPlugin.m README.md
git commit -m "Bump version to {cordova_version}"
git push -u origin releases/{major}.x.x/{major}.{minor}.x/{cordova_version}-rc1
```

**Branch name pattern**: `releases/6.x.x/6.17.x/6.17.9-rc1` — the pipeline triggers only when the name matches this format.

---

## Step 5: Manual — QA Pipeline Running

**Inform the user**:

> The release branch has been pushed. The QA pipeline is now running (build, deploy to QA, NPM publish with `QA` tag).
>
> Would you like me to open a PR to master? (This triggers the pre-release workflow to update RELEASENOTES.md from Jira.)

If yes:
- **If GitHub CLI is available**, run:
  ```bash
  gh pr create --base master --head releases/{major}.x.x/{major}.{minor}.x/{cordova_version}-rc1 --title "Release {cordova_version}-rc1"
  ```
- **If GitHub CLI is not available**, ask the user to create the PR manually and provide:
  - **Branch to use**: `releases/{major}.x.x/{major}.{minor}.x/{cordova_version}-rc1`
  - **Base branch**: `master`

---

## Step 6: Manual — Merge to Production

**Inform the user**:

> When QA is approved, merge the PR to master. Merging will trigger the production release (GitHub release, NPM `latest`, Slack report).

Provide the PR link for convenience.

---

## Summary Checklist

- [ ] User provided: Cordova version, Android SDK version, iOS SDK version
- [ ] User created Jira fixed version and confirmed
- [ ] Updated: package.json, plugin.xml, cordovaAF.gradle, AppsFlyerConstants.java, AppsFlyerPlugin.m, README.md
- [ ] User tested changes locally and confirmed NPM token (`CI_NPM_TOKEN`) is valid
- [ ] Created and pushed release branch (correct naming)
- [ ] (Optional) Opened PR to master
- [ ] User merges PR when QA approved

---

## Reference

For full release process details, troubleshooting, or non-version-bump releases, see [docs/RELEASE_PROCESS.md](../../docs/RELEASE_PROCESS.md).
