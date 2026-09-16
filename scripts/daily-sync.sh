#!/usr/bin/env bash
# Daily LaunchAgent entry (canonical copy lives in rule/scripts/; installed to
# ~/Library/Application Support/agent-standards-sync/daily-sync.sh).
#
# 1) Pull upstream skill sources (ui-skills / skill monorepo)
# 2) Import MCP (optional)
# 3) Deploy skills/rules/commands/env to all agents
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin${PATH:+:$PATH}"
export HOME="${HOME:-/Users/marui}"

RULE_REPO="${HOME}/Documents/code/rule"
SKILL_REPO="${HOME}/Documents/code/skill"
UISKILLS_DIR="${SKILL_REPO}/ui-skills"
UISKILLS_GIT="${UISKILLS_DIR}/.git-upstream"
LOG_DIR="${HOME}/Library/Logs/agent-standards-sync"
mkdir -p "$LOG_DIR"

STAMP="$(date '+%Y-%m-%d %H:%M:%S')"
DAY_LOG="${LOG_DIR}/daily-$(date '+%Y-%m-%d').log"

log() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }

# Tee key lines into dated log as well (LaunchAgent already captures stdout/stderr).
exec > >(tee -a "$DAY_LOG") 2> >(tee -a "$DAY_LOG" >&2)

log "===== agent-standards daily sync start ${STAMP} ====="

# --- TCC preflight (Documents is protected for background /bin/bash) ---
if [[ ! -r "${RULE_REPO}/sync-global-agent-standards.sh" ]]; then
  cat >&2 <<'MSG'
error: cannot read ~/Documents/code/rule (macOS TCC / Full Disk Access).

Fix:
  System Settings → Privacy & Security → Full Disk Access
  → enable /bin/bash  (and/or Terminal / iTerm if you kickstart manually)

Then:
  launchctl kickstart -k "gui/$(id -u)/com.user.agent-standards-daily-sync"

Until FDA is granted, run interactively instead:
  ~/Documents/code/rule/daily-sync-agent-standards.sh
MSG
  exit 77
fi

if [[ ! -r "${SKILL_REPO}" ]]; then
  warn "cannot read ~/Documents/code/skill (TCC) — skipping upstream pulls"
fi

# --- Upstream: ui-skills (ibelick) ---
pull_ui_skills() {
  if [[ ! -d "$UISKILLS_DIR" ]]; then
    warn "missing ui-skills dir: $UISKILLS_DIR"
    return 0
  fi

  if [[ -d "$UISKILLS_GIT" ]]; then
    log "ui-skills: fetch ibelick/ui-skills (via .git-upstream)"
    if ! git --git-dir="$UISKILLS_GIT" --work-tree="$UISKILLS_DIR" fetch --prune origin; then
      warn "ui-skills fetch failed (network?)"
      return 0
    fi
    # Only refresh skills/ so local dirty files (e.g. src/) do not block updates
    if git --git-dir="$UISKILLS_GIT" --work-tree="$UISKILLS_DIR" checkout "origin/main" -- skills/ 2>/dev/null; then
      log "ui-skills: updated skills/ from origin/main"
    else
      warn "ui-skills: checkout origin/main -- skills/ failed"
    fi
    return 0
  fi

  # Fallback: skills CLI (updates global install; sync step re-links from local tree)
  if command -v npx >/dev/null 2>&1; then
    log "ui-skills: no .git-upstream — npx skills add ibelick/ui-skills"
    npx --yes skills add ibelick/ui-skills -g -y || warn "npx skills add ui-skills failed"
  else
    warn "ui-skills: neither .git-upstream nor npx available"
  fi
}

# --- Upstream: skill monorepo (codeskill / router / index on origin) ---
pull_skill_monorepo() {
  if [[ ! -d "${SKILL_REPO}/.git" ]]; then
    warn "skill repo is not a git checkout — skip monorepo pull"
    return 0
  fi
  log "skill: git pull --ff-only (monorepo)"
  if ! git -C "$SKILL_REPO" pull --ff-only; then
    warn "skill monorepo pull failed (dirty tree or non-ff). Local codeskill still deploys as-is."
  fi
}

# --- Upstream: npx skills lock packages (addyosmani / obra / taste / …) ---
update_npx_skills() {
  if ! command -v npx >/dev/null 2>&1; then
    warn "npx missing — skip skills update"
    return 0
  fi
  log "skills: npx skills update -g -y"
  if ! npx --yes skills update -g -y; then
    warn "npx skills update failed (continuing with local copies)"
  fi
}

if [[ -r "$SKILL_REPO" ]]; then
  pull_ui_skills
  pull_skill_monorepo
fi
update_npx_skills

cd "$RULE_REPO"

# --- MCP import (best-effort) ---
if [[ -x "${RULE_REPO}/sync-global-mcp.sh" ]]; then
  if ! "${RULE_REPO}/sync-global-mcp.sh" --import; then
    warn "sync-global-mcp.sh --import failed (continuing)"
  fi
else
  warn "missing sync-global-mcp.sh"
fi

# --- Deploy to all agents ---
"${RULE_REPO}/sync-global-agent-standards.sh"

log "===== agent-standards daily sync done $(date '+%Y-%m-%d %H:%M:%S') ====="
