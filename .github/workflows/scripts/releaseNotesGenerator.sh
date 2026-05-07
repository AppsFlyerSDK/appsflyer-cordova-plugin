#!/usr/bin/env bash
set -euo pipefail

RELEASE_VERSION="${1:-}"
OUTPUT_FILE="${2:-}"

if [ -z "$RELEASE_VERSION" ]; then
  echo "Usage: $0 <release_version> [output_file]"
  exit 1
fi

if [ -z "$OUTPUT_FILE" ]; then
  OUTPUT_FILE="${RELEASE_VERSION}-releasenotes.txt"
fi

echo "Extracting release notes for ${RELEASE_VERSION} from RELEASENOTES.md"

RELEASE_NOTES=$(awk -v ver="$RELEASE_VERSION" '
  $0 ~ "^## " ver "$" { in_section=1; next }
  in_section && /^## / { exit }
  in_section { print }
' RELEASENOTES.md | sed '/^[[:space:]]*$/d')

if [ -z "$RELEASE_NOTES" ]; then
  echo "Release notes for ${RELEASE_VERSION} are missing or empty."
  exit 1
fi

printf '%s\n' "$RELEASE_NOTES" > "$OUTPUT_FILE"
cat "$OUTPUT_FILE"