#!/usr/bin/env bash
# Sync MCP servers from Documents/code/rule/mcp/canonical.json to all agents.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/scripts/sync-global-mcp.py"

if [[ ! -f "$PYTHON_SCRIPT" ]]; then
  echo "error: missing $PYTHON_SCRIPT" >&2
  exit 1
fi

exec python3 "$PYTHON_SCRIPT" "$@"
