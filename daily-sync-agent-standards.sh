#!/usr/bin/env bash
# Thin wrapper → prefer rule canonical script; fallback to Application Support install.
set -euo pipefail
RULE_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANON="${RULE_REPO}/scripts/daily-sync.sh"
INSTALLED="${HOME}/Library/Application Support/agent-standards-sync/daily-sync.sh"
if [[ -x "$CANON" ]]; then
  exec "$CANON" "$@"
fi
exec "$INSTALLED" "$@"
