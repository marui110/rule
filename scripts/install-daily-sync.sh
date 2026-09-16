#!/usr/bin/env bash
# Install / refresh the LaunchAgent daily sync entry (outside Documents for TCC).
# Canonical script: rule/scripts/daily-sync.sh
set -euo pipefail

RULE_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${RULE_REPO}/scripts/daily-sync.sh"
DEST_DIR="${HOME}/Library/Application Support/agent-standards-sync"
DEST="${DEST_DIR}/daily-sync.sh"
PLIST_SRC="${RULE_REPO}/scripts/com.user.agent-standards-daily-sync.plist"
PLIST_DEST="${HOME}/Library/LaunchAgents/com.user.agent-standards-daily-sync.plist"
LABEL="com.user.agent-standards-daily-sync"

if [[ ! -f "$SRC" ]]; then
  echo "error: missing $SRC" >&2
  exit 1
fi

mkdir -p "$DEST_DIR" "${HOME}/Library/LaunchAgents" "${HOME}/Library/Logs/agent-standards-sync"
cp "$SRC" "$DEST"
chmod +x "$DEST"

if [[ -f "$PLIST_SRC" ]]; then
  # Substitute HOME for portability
  sed "s|/Users/marui|${HOME}|g" "$PLIST_SRC" >"$PLIST_DEST"
else
  echo "warning: missing $PLIST_SRC — leaving existing LaunchAgent plist untouched" >&2
fi

# Load / reload agent (ignore errors if already loaded)
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST" 2>/dev/null \
  || launchctl load -w "$PLIST_DEST" 2>/dev/null \
  || true

echo "installed: $DEST"
echo "plist:     $PLIST_DEST"
echo "schedule:  daily 09:00"
echo "logs:      ~/Library/Logs/agent-standards-sync/"
echo
echo "If background runs fail with Operation not permitted:"
echo "  System Settings → Privacy & Security → Full Disk Access → enable /bin/bash"
echo "Manual run: ${RULE_REPO}/daily-sync-agent-standards.sh"
echo "Kickstart:  launchctl kickstart -k \"gui/\$(id -u)/${LABEL}\""
