#!/usr/bin/env bash
# Sync canonical skills (~/.claude/skills) and rules (~/.cursor/rules) to all agents
# and mirror rules/agents/commands templates into this repo (Documents/code/rule).
#
# Skills path mapping:
#   ~/Documents/code/skill/codeskill/*  →  ~/.claude/skills/*  →  agent symlink dirs
#   (rule/skills/ removed; codeskill repo is the git backup for project skills)
set -euo pipefail

HOME="${HOME:-$HOME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULE_REPO="${SCRIPT_DIR}"
SYNC_SCRIPT="${RULE_REPO}/sync-global-agent-standards.sh"

CANONICAL_SKILLS="${HOME}/.claude/skills"
CANONICAL_RULES="${HOME}/.cursor/rules"
SKILL_REPO="${HOME}/Documents/code/skill"
CODESKILL_DIR="${SKILL_REPO}/codeskill"

SKILL_TARGETS=(
  "${HOME}/.agents/skills"
  "${HOME}/.cursor/skills"
  "${HOME}/.trae-cn/skills"
  "${HOME}/.codex/skills"
)

RULE_AGENT_TARGETS=(
  "${HOME}/.trae-cn/rules"
)

RULE_REPO_CURSOR="${RULE_REPO}/global/cursor"
RULE_REPO_TRAE="${RULE_REPO}/global/trae-cn"
AGENTS_REPO="${RULE_REPO}/agents"

AGENT_DEPLOYS=(
  "codex-AGENTS.md:${HOME}/.codex/AGENTS.md"
)

link_skill() {
  local name="$1"
  local src="${CANONICAL_SKILLS}/${name}"
  local target="$2"
  local dest="${target}/${name}"

  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -d "$dest" ]]; then
    rm -rf "$dest"
  elif [[ -e "$dest" ]]; then
    rm -f "$dest"
  fi

  ln -sf "$src" "$dest"
}

sync_codeskills() {
  if [[ ! -d "$CODESKILL_DIR" ]]; then
    echo "warning: missing codeskill dir: $CODESKILL_DIR" >&2
    return 0
  fi

  mkdir -p "$CANONICAL_SKILLS"

  local synced=0
  for src in "${CODESKILL_DIR}"/*/; do
    [[ -d "$src" ]] || continue
    local name
    name="$(basename "$src")"
    if [[ ! -f "${src}/SKILL.md" ]]; then
      echo "warning: skip codeskill without SKILL.md: $src" >&2
      continue
    fi
    local dest="${CANONICAL_SKILLS}/${name}"
    mkdir -p "$dest"
    rsync -a --delete "${src}/" "${dest}/"
    synced=$((synced + 1))
  done

  echo "codeskills: synced ${synced} skill(s) from ${CODESKILL_DIR} -> ${CANONICAL_SKILLS}"
}

sync_skills() {
  if [[ ! -d "$CANONICAL_SKILLS" ]]; then
    echo "error: missing canonical skills dir: $CANONICAL_SKILLS" >&2
    exit 1
  fi

  for target in "${SKILL_TARGETS[@]}"; do
    mkdir -p "$target"
  done

  local linked=0
  for src in "${CANONICAL_SKILLS}"/*/; do
    [[ -d "$src" ]] || continue
    local name
    name="$(basename "$src")"
    [[ "$name" == ".system" ]] && continue
    for target in "${SKILL_TARGETS[@]}"; do
      link_skill "$name" "$target"
    done
    linked=$((linked + 1))
  done

  echo "skills: linked ${linked} skill(s) to ${#SKILL_TARGETS[@]} agent directories"
}

collect_global_rules() {
  shopt -s nullglob
  GLOBAL_RULES=( "${CANONICAL_RULES}"/global-*.mdc )
  shopt -u nullglob

  if (( ${#GLOBAL_RULES[@]} == 0 )); then
    echo "error: no global-*.mdc rules found in $CANONICAL_RULES" >&2
    exit 1
  fi
}

sync_rules_to_agents() {
  if [[ ! -d "$CANONICAL_RULES" ]]; then
    echo "error: missing canonical rules dir: $CANONICAL_RULES" >&2
    exit 1
  fi

  collect_global_rules

  local copied=0
  for target in "${RULE_AGENT_TARGETS[@]}"; do
    mkdir -p "$target"
  done

  for rule in "${GLOBAL_RULES[@]}"; do
    local base
    base="$(basename "$rule" .mdc)"
    for target in "${RULE_AGENT_TARGETS[@]}"; do
      cp "$rule" "${target}/${base}.md"
    done
    copied=$((copied + 1))
  done

  echo "rules: copied ${copied} global rule(s) to ${#RULE_AGENT_TARGETS[@]} agent directories"
}

sync_rules_to_repo() {
  collect_global_rules

  mkdir -p "$RULE_REPO_CURSOR" "$RULE_REPO_TRAE"

  local copied=0
  for rule in "${GLOBAL_RULES[@]}"; do
    local base
    base="$(basename "$rule" .mdc)"
    cp "$rule" "${RULE_REPO_CURSOR}/${base}.mdc"
    cp "$rule" "${RULE_REPO_TRAE}/${base}.md"
    copied=$((copied + 1))
  done

  if [[ -f "${CANONICAL_RULES}/README.md" ]]; then
    cp "${CANONICAL_RULES}/README.md" "${RULE_REPO_CURSOR}/README.md"
  fi

  echo "repo: mirrored ${copied} global rule(s) to ${RULE_REPO}/global/"
}

deploy_agents_files() {
  local deployed=0
  for mapping in "${AGENT_DEPLOYS[@]}"; do
    local src_name="${mapping%%:*}"
    local dest="${mapping#*:}"
    local src="${AGENTS_REPO}/${src_name}"

    if [[ ! -f "$src" ]]; then
      echo "warning: missing agents template: $src" >&2
      continue
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    deployed=$((deployed + 1))
  done

  echo "agents: deployed ${deployed} template(s) from ${AGENTS_REPO}/"
}

main() {
  sync_codeskills
  sync_skills
  sync_rules_to_agents
  sync_rules_to_repo
  deploy_agents_files
  if [[ -x "${RULE_REPO}/sync-global-commands.sh" ]]; then
    "${RULE_REPO}/sync-global-commands.sh"
  fi
  if [[ -x "${RULE_REPO}/sync-global-mcp.sh" ]]; then
    "${RULE_REPO}/sync-global-mcp.sh"
  fi
  if [[ -x "${RULE_REPO}/sync-global-env.sh" ]]; then
    "${RULE_REPO}/sync-global-env.sh"
  fi
  echo "Done."
  echo "  codeskill repo   : $CODESKILL_DIR"
  echo "  skills canonical : $CANONICAL_SKILLS"
  echo "  rules canonical  : $CANONICAL_RULES"
  echo "  rules repo mirror: $RULE_REPO/global/"
  echo "  commands repo    : $RULE_REPO/commands/"
  echo "  sync script      : $SYNC_SCRIPT"
}

main "$@"
