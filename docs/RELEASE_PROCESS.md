# Cordova Plugin Minor Release Process

This document describes the step-by-step process for performing a minor release of the AppsFlyer Cordova plugin. The release branch naming convention is **critical** because it triggers the corresponding GitHub Actions pipelines.

---

## Overview

The release process involves:

1. **Creating a release branch** from the latest `master` commit (include version bumps and a new top section in `RELEASENOTES.md`)
2. **Pushing the branch** → triggers QA pipeline (build, deploy to QA, publish to NPM with `QA` tag, Slack uses `RELEASENOTES.md`)
3. **Opening a PR** to `master` → triggers pre-release workflow (updates `package.json` on the release branch via `npm version`)
4. **Merging the PR** to `master` → triggers production release (creates GitHub release, publishes to NPM as `latest`, Slack uses `RELEASENOTES.md`)

---

## Prerequisites

Before starting a release:

1. **`RELEASENOTES.md` must contain a section for the release semver** before you push the release branch. The heading must be exactly `## {major}.{minor}.{patch}` matching the version in the branch name (for example `6.18.0` for branch `.../6.18.0-rc1`). The section must include at least one line of body text (for example the release date line and/or bullets). QA and production read this section for Slack; the workflow does not fetch Jira.

2. **Ensure you're on latest master**:
   ```bash
   git checkout master
   git pull origin master
   ```

---

## Step 1: Create Release Branch from Latest Master

### Branch Naming Convention

The release branch name **must** follow this pattern to trigger the pipelines:

```
releases/{major}.x.x/{major}.{minor}.x/{major}.{minor}.{patch}-rc{rc_number}
```

**Examples:**

- `releases/6.x.x/6.17.x/6.17.8-rc1` — patch release 6.17.8, first release candidate
- `releases/6.x.x/6.17.x/6.17.9-rc1` — patch release 6.17.9, first release candidate
- `releases/6.x.x/6.18.x/6.18.0-rc1` — minor release 6.18.0, first release candidate

### Commands

```bash
# 1. Ensure you're on latest master
git checkout master
git pull origin master

# 2. Create and checkout the release branch
# Replace {major}.{minor}.{patch} with your target version (e.g., 6.17.9)
# Replace {rc_number} with 1 for first RC, 2 for second, etc.
git checkout -b releases/6.x.x/6.17.x/6.17.9-rc1

# 3. Push the branch to origin (this triggers the QA pipeline)
git push -u origin releases/6.x.x/6.17.x/6.17.9-rc1
```

### Pipeline Triggered by Push

When you push to a release branch matching the pattern, **Release plugin to QA** (`.github/workflows/release-QA-workflow.yml`) runs:

- **Trigger**: `push` to branches matching `releases/[0-9].x.x/[0-9].[0-9]+.x/[0-9].[0-9]+.[0-9]+-rc[0-9]+`
- **Note**: Pushes that only change `**.md`, `**.yml`, `examples/**`, `hooks/**`, `resources/**`, `testsScripts/**`, or `docs/**` are ignored (paths-ignore)
- **Actions**:
  1. Build sample apps
  2. Deploy to QA (updates `package.json`/`plugin.xml` to RC version, publishes to NPM with `QA` tag, sends Slack report using the matching `RELEASENOTES.md` section)

---

## Step 2: Open PR to Master (Optional but Recommended)

Opening a PR from the release branch to `master` triggers the **Prepare plugin for production** workflow:

- **Trigger**: PR `opened` targeting `master`, when `github.head_ref` starts with `releases/`
- **Actions**:
  1. Updates `package.json` version via `npm version`
  2. Force-pushes changes back to the release branch

`RELEASENOTES.md` is **not** modified by CI; maintain it on the release branch when you prepare the version bump.

```bash
# Create PR via GitHub UI: release branch → master
# Or use GitHub CLI:
gh pr create --base master --head releases/6.x.x/6.17.x/6.17.9-rc1 --title "Release 6.17.9-rc1"
```

---

## Step 3: Merge to Master (Production Release)

When the PR from the release branch is merged to `master`:

- **Trigger**: PR `closed` (merged) on `master` branch
- **Actions** (Release plugin to production — `.github/workflows/release-Production-workflow.yml`):
  1. Extracts version from PR branch name (e.g., `6.17.9` from `6.17.9-rc1`)
  2. Creates GitHub release with that tag
  3. Publishes to NPM as `latest`
  4. Sends Slack report; **changes/fixes** text comes from the `RELEASENOTES.md` section for that version

---

## Quick Reference: Branch Name Template

| Component | Example | Description |
|-----------|---------|-------------|
| Major line | `6.x.x` | Major version family |
| Minor line | `6.17.x` | Minor version family |
| Full version | `6.17.9-rc1` | Semantic version + release candidate number |

**Full example**: `releases/6.x.x/6.17.x/6.17.9-rc1`

---

## Workflow Files Reference

| Workflow | File | Trigger |
|----------|------|---------|
| Release to QA | `release-QA-workflow.yml` | Push to release branch (matching pattern) |
| Prepare for production | `pre-release-workflow.yml` | PR opened to master (branch starts with `releases/`) |
| Release to production | `release-Production-workflow.yml` | PR merged to master |

---

## Troubleshooting

1. **QA pipeline didn't run**: Ensure the branch name exactly matches the pattern. Check that your push modified files outside `paths-ignore` (e.g., not only `.md` or `.yml`).

2. **QA or production fails on release notes**: Ensure `RELEASENOTES.md` has a `## {version}` section matching the semver from the branch (without `-rc`), with non-empty body text under that heading.

3. **Multiple RCs**: For a second release candidate (e.g., after QA feedback), create a new branch: `releases/6.x.x/6.17.x/6.17.9-rc2` from the same base, or from the previous RC branch.

---

## Summary: Minimal Release Checklist

- [ ] New top section in `RELEASENOTES.md` for `## {major}.{minor}.{patch}` with body text
- [ ] `git checkout master && git pull origin master`
- [ ] Create branch: `git checkout -b releases/{major}.x.x/{major}.{minor}.x/{major}.{minor}.{patch}-rc{rc}`
- [ ] Push: `git push -u origin releases/...`
- [ ] (Optional) Open PR to master for pre-release workflow
- [ ] Merge PR to master when ready for production
