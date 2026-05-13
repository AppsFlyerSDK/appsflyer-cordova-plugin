#!/usr/bin/env bash
# Create the E2E sibling `.env` from `.af-e2e/env.example` if missing (never overwrites).
# Matches the body you paste into the GitHub Actions secret ENV_FILE.
#
# Usage (from plugin repo root):
#   ./scripts/bootstrap-e2e-env.sh
#
# Requires a prior sync so `.af-e2e/e2e_copy_dest.txt` exists (this script runs sync if missing).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE="${ROOT}/.af-e2e/env.example"
DEST_FILE="${ROOT}/.af-e2e/e2e_copy_dest.txt"

if [[ ! -f "$EXAMPLE" ]]; then
  echo "missing: $EXAMPLE" >&2
  exit 1
fi

if [[ ! -f "$DEST_FILE" ]]; then
  "${ROOT}/scripts/sync-test-app-e2e-copy.sh"
fi

DEST="$(cat "$DEST_FILE")"
mkdir -p "$DEST"

if [[ -f "${DEST}/.env" ]]; then
  echo "[bootstrap-e2e-env] keep existing ${DEST}/.env"
  exit 0
fi

cp "$EXAMPLE" "${DEST}/.env"
echo "[bootstrap-e2e-env] created ${DEST}/.env from .af-e2e/env.example — set DEV_KEY and APP_ID (same text as GitHub secret ENV_FILE)."
