---
name: cordova-release-version-bump
description: Performs a simple version-bump release of the AppsFlyer Cordova plugin (no public API changes). Use when the user wants to release a new Cordova plugin version that only updates SDK dependencies (Android, iOS) and plugin version.
---

# Cordova Plugin Version Bump Release

This skill guides a **simple version bump release** — no public API changes, only Cordova plugin version and native SDK dependency updates.

Release notes are **authored in the repo** (`RELEASENOTES.md`). CI reads the section for the target version to populate Slack notifications; it does **not** call Jira.

---

## Step 0: Gather Versions and Release Notes (First Action)

**Before doing anything else**, collect:

1. **Cordova plugin version** (e.g., `6.17.9`)
2. **Android SDK version** (e.g., `6.17.5`)
3. **iOS SDK version** (e.g., `6.17.8`)
4. **Release notes** for this version: short bullet list (or prose) describing what shipped. This will be added to `RELEASENOTES.md` and used by QA/production Slack steps.

Example prompt:

> To proceed with the version bump release, I need:
> - **Cordova plugin version** (e.g., 6.17.9):
> - **Android SDK version** (e.g., 6.17.5):
> - **iOS SDK version** (e.g., 6.17.8):
> - **Release notes** (bullets for `RELEASENOTES.md`, e.g. dependency bumps, fixes):

Use RC number `1` for the release branch unless the user specifies otherwise (e.g., `6.17.9-rc2`).

---

## Step 1: Update Version Files and RELEASENOTES.md

### Version files

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

Run `npm install` at the repo root if needed so `package-lock.json` stays in sync with `package.json`.

### RELEASENOTES.md

**Prepend** a new section for `{cordova_version}` at the top of `RELEASENOTES.md` (before all existing `##` headings). Use the project’s usual shape, for example:

```markdown
## {cordova_version}
 Release date: *YYYY-MM-DD*

- {release note bullet}
- {optional more bullets}
```

Use the **current calendar date** for `Release date` unless the user specifies otherwise.

**Required for CI**: The section **`## {cordova_version}`** must exist on the release branch **before** QA deploy runs. The heading line must match the semver extracted from the branch name (e.g., `6.17.9` from `.../6.17.9-rc1`). The section must contain at least one non-whitespace line after the heading (e.g., the release date line and/or bullets), otherwise the QA/production workflows will fail when building the Slack payload.

---

## Step 2: Manual — Test Changes and Verify NPM Token Before Push

**Stop and ask the user** to:

1. **Test the changes locally** (e.g., build the example app, verify the plugin works).
2. **Verify the NPM access token is not expired**: The token is stored in [GitHub Actions secrets](https://github.com/AppsFlyerSDK/appsflyer-cordova-plugin/settings/secrets/actions) as `CI_NPM_TOKEN`. It is used to publish to https://www.npmjs.com/ — if expired, the QA and production pipelines will fail.

> I've updated all version files and `RELEASENOTES.md`. Before we push the release branch, please:
> 1. Test the changes locally (e.g., build the example app, verify the plugin works).
> 2. Confirm that the NPM access token (`CI_NPM_TOKEN`) in [GitHub Actions secrets](https://github.com/AppsFlyerSDK/appsflyer-cordova-plugin/settings/secrets/actions) is not expired.
>
> Reply when you've verified both and are ready to push.

Do not continue to Step 3 until the user confirms.

---

## Step 3: Create Release Branch and Push

### When to create `releases/...` (use the provided release version name)

The **release version name** is the Cordova semver the user gave you (e.g. `6.18.0`). The Git branch must embed that version so QA pipelines can parse it.

**If the current branch is `master` or `develop`:**

1. Sync the base branch: `git pull origin master` or `git pull origin develop` (whichever you are on).
2. Create the release branch from current `HEAD` using that semver and the usual `rc` suffix from Step 0 (default `rc1`):
   ```bash
   git checkout -b releases/{major}.x.x/{major}.{minor}.x/{cordova_version}-rc{rc}
   ```
   Example: for release version `6.18.0` and `rc1` → `releases/6.x.x/6.18.x/6.18.0-rc1`.

**If the current branch is not `master` or `develop`:** do **not** create `releases/...` unless the user explicitly asks. Ask which branch to base the release on (normally `master` or `develop`), check it out, pull, then run the `git checkout -b releases/...` command above.

Never invent the release version: it must match what the user provided and must match the `## {cordova_version}` heading in `RELEASENOTES.md`.

### Commit and push

Stage the version bump, `RELEASENOTES.md`, and `package-lock.json` when it changed after `npm install`:

```bash
git add package.json package-lock.json plugin.xml src/android/cordovaAF.gradle src/android/com/appsflyer/cordova/plugin/AppsFlyerConstants.java src/ios/AppsFlyerPlugin.m README.md RELEASENOTES.md
git commit -m "Bump version to {cordova_version}"
git push -u origin releases/{major}.x.x/{major}.{minor}.x/{cordova_version}-rc{rc}
```

**Branch name pattern**: `releases/6.x.x/6.18.x/6.18.0-rc1` — the pipeline triggers only when the name matches this format.

---

## Step 4: Manual — QA Pipeline Running

**Inform the user**:

> The release branch has been pushed. The QA pipeline is now running (build, deploy to QA, NPM publish with `QA` tag). Slack uses the top **`RELEASENOTES.md`** section matching the semver from the branch name.
>
> Would you like me to open a PR to master? (This triggers the pre-release workflow to align `package.json` on the branch with the final version via `npm version`.)

If yes:

- **If GitHub CLI is available**, run:
  ```bash
  gh pr create --base master --head releases/{major}.x.x/{major}.{minor}.x/{cordova_version}-rc1 --title "Release {cordova_version}-rc1"
  ```
- **If GitHub CLI is not available**, ask the user to create the PR manually and provide:
  - **Branch to use**: `releases/{major}.x.x/{major}.{minor}.x/{cordova_version}-rc1`
  - **Base branch**: `master`

---

## Step 5: Manual — Merge to Production

**Inform the user**:

> When QA is approved, merge the PR to `master`. Merging will trigger the production release (GitHub release, NPM `latest`, Slack report using the same `RELEASENOTES.md` section).

Provide the PR link for convenience.

---

## Summary Checklist

- [ ] User provided: Cordova version, Android SDK version, iOS SDK version, and release notes
- [ ] Updated: `package.json`, `plugin.xml`, `cordovaAF.gradle`, `AppsFlyerConstants.java`, `AppsFlyerPlugin.m`, `README.md`, `RELEASENOTES.md` (new top section for the Cordova version), `package-lock.json` if applicable
- [ ] User tested changes locally and confirmed NPM token (`CI_NPM_TOKEN`) is valid
- [ ] On `master` or `develop`: created `releases/{major}.x.x/{major}.{minor}.x/{cordova_version}-rc{rc}` from synced base; committed and pushed (correct naming)
- [ ] (Optional) Opened PR to master
- [ ] User merges PR when QA approved

---

## Reference

For full release process details, troubleshooting, or non-version-bump releases, see [docs/RELEASE_PROCESS.md](../../docs/RELEASE_PROCESS.md).
