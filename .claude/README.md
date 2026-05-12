# `.claude` — shared agent guidance (Claude Code + Cursor)

This directory holds **project skills** (`skills/*/SKILL.md`) so the same markdown can be used from:

- **Claude Code** — load skills from the project `.claude/` tree (per Claude Code project conventions).
- **Cursor** — the same skill folders are **symlinked** under `.cursor/skills/` so Cursor’s skill discovery picks them up. Do not duplicate `SKILL.md` bodies in two places; edit files under **`.claude/skills/`** only.

## Layout

| Path | Role |
|------|------|
| `.claude/skills/<name>/SKILL.md` | Canonical skill source |
| `.cursor/skills/<name>` | Symlink → `../../.claude/skills/<name>` |

If a symlink is missing after clone on Windows, enable `git config core.symlinks true` before checkout, or recreate the link from `.cursor/skills/` to `.claude/skills/`.

## Upstream templates

Skills were adapted from [`appsflyer-mobile-plugin-tooling/templates/`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/tree/main/templates) (`claude-skills/`, `cursor-skills/`). When contracts change, refresh content from a new tooling tag and update `scripts/TOOLING_PIN.txt` for the vendored runner.
