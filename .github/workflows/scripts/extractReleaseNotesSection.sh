#!/usr/bin/env bash
set -euo pipefail

RELEASENOTES_FILE="${1:-RELEASENOTES.md}"
VERSION="${2:?version required}"

if [[ ! -f "$RELEASENOTES_FILE" ]]; then
  echo "Release notes file not found: ${RELEASENOTES_FILE}" >&2
  exit 1
fi

CONTENT="$(awk -v ver="$VERSION" '
  $0 == "## " ver { found=1; next }
  found && $0 ~ /^## / { exit }
  found { print }
' "$RELEASENOTES_FILE")"

if [[ -z "$(echo "$CONTENT" | tr -d "[:space:]")" ]]; then
  echo "::error::No RELEASENOTES.md section found for version ${VERSION} (expected a '## ${VERSION}' heading with body text)." >&2
  exit 1
fi

printf '%s\n' "$CONTENT"
