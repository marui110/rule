#!/usr/bin/env bash
# Deploy copilot-instructions.md to a project (copy full version)
# Usage: ~/.vscode/deploy-copilot.sh [project_dir]
#   Default: current directory

set -euo pipefail

PROJECT_DIR="${1:-.}"
TARGET="$PROJECT_DIR/.github/copilot-instructions.md"
SOURCE="$HOME/.vscode/copilot-instructions.md"

mkdir -p "$PROJECT_DIR/.github"

if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  echo "Already exists (real file): $TARGET"
  exit 0
fi

# Remove old symlink if present
rm -f "$TARGET"
cp "$SOURCE" "$TARGET"
echo "Deployed: $TARGET (copied from $SOURCE)"
