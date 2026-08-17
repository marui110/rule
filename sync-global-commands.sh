#!/usr/bin/env bash
# Sync slash commands from rule repo to Cursor / Claude Code / Codex.
set -euo pipefail

HOME="${HOME:-$HOME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULE_REPO="${SCRIPT_DIR}"
CANONICAL_COMMANDS="${RULE_REPO}/commands"

COMMAND_TARGETS=(
  "${HOME}/.cursor/commands"
  "${HOME}/.claude/commands"
  "${HOME}/.codex/commands"
)

if [[ ! -d "$CANONICAL_COMMANDS" ]]; then
  echo "error: missing commands dir: $CANONICAL_COMMANDS" >&2
  exit 1
fi

shopt -s nullglob
COMMAND_FILES=( "${CANONICAL_COMMANDS}"/*.md )
shopt -u nullglob

if (( ${#COMMAND_FILES[@]} == 0 )); then
  echo "warning: no *.md commands in $CANONICAL_COMMANDS" >&2
  exit 0
fi

for target in "${COMMAND_TARGETS[@]}"; do
  mkdir -p "$target"
done

copied=0
for cmd in "${COMMAND_FILES[@]}"; do
  base_name="$(basename "$cmd")"
  for target in "${COMMAND_TARGETS[@]}"; do
    cp "$cmd" "${target}/${base_name}"
  done
  copied=$((copied + 1))
done

# prune stale commands no longer in canonical
for target in "${COMMAND_TARGETS[@]}"; do
  for f in "${target}"/*.md; do
    [[ -e "$f" ]] || continue
    name="$(basename "$f")"
    keep=0
    for cmd in "${COMMAND_FILES[@]}"; do
      [[ "$(basename "$cmd")" == "$name" ]] && keep=1 && break
    done
    if [[ "$keep" == "0" ]]; then
      rm -f "$f"
      echo "commands: removed stale ${target}/${name}"
    fi
  done
done

echo "commands: copied ${copied} command(s) to ${#COMMAND_TARGETS[@]} agent directories"
echo "  canonical : $CANONICAL_COMMANDS"
echo "  targets   : ${COMMAND_TARGETS[*]}"
