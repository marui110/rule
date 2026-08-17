#!/usr/bin/env bash
# Thin wrapper → LaunchAgent entry lives outside Documents (TCC).
exec "$HOME/Library/Application Support/agent-standards-sync/daily-sync.sh" "$@"
