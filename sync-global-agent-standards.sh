#!/usr/bin/env bash
# Sync canonical skills (~/.claude/skills) and rules (~/.cursor/rules) to all agents
# and mirror rules/agents/commands templates into this repo (Documents/code/rule).
#
# Skills path mapping:
#   ~/Documents/code/skill/codeskill/*       →  ~/.claude/skills/*  (rsync)
#   ~/Documents/code/skill/ui-skills/skills/* →  ~/.claude/skills/*  (symlink)
#   ~/.claude/skills/*                       →  agent dirs (symlink)
#   ~/.claude/skills/*                       →  ~/Documents/code/skill/global/* (rsync mirror)
set -euo pipefail

HOME="${HOME:-$HOME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULE_REPO="${SCRIPT_DIR}"
SYNC_SCRIPT="${RULE_REPO}/sync-global-agent-standards.sh"

CANONICAL_SKILLS="${HOME}/.claude/skills"
CANONICAL_RULES="${HOME}/.cursor/rules"
SKILL_REPO="${HOME}/Documents/code/skill"
CODESKILL_DIR="${SKILL_REPO}/codeskill"
UISKILLS_DIR="${SKILL_REPO}/ui-skills/skills"
GLOBAL_MIRROR="${SKILL_REPO}/global"

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

# template_name:dest_path  (claude-CLAUDE.md also copied to claude.md)
AGENT_DEPLOYS=(
  "codex-AGENTS.md:${HOME}/.codex/AGENTS.md"
  "claude-CLAUDE.md:${HOME}/.claude/CLAUDE.md"
  "trae-AGENTS.md:${HOME}/.trae-cn/AGENTS.md"
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
    # Replace symlink with real dir before rsync
    if [[ -L "$dest" ]]; then
      rm "$dest"
    fi
    mkdir -p "$dest"
    rsync -a --delete "${src}/" "${dest}/"
    synced=$((synced + 1))
  done

  echo "codeskills: synced ${synced} skill(s) from ${CODESKILL_DIR} -> ${CANONICAL_SKILLS}"
}

sync_uiskills() {
  if [[ ! -d "$UISKILLS_DIR" ]]; then
    echo "warning: missing ui-skills dir: $UISKILLS_DIR" >&2
    return 0
  fi

  mkdir -p "$CANONICAL_SKILLS"

  local linked=0
  for src in "${UISKILLS_DIR}"/*/; do
    [[ -d "$src" ]] || continue
    local name
    name="$(basename "$src")"
    if [[ ! -f "${src}/SKILL.md" ]]; then
      echo "warning: skip ui-skill without SKILL.md: $src" >&2
      continue
    fi
    local dest="${CANONICAL_SKILLS}/${name}"
    if [[ -L "$dest" ]]; then
      rm "$dest"
    elif [[ -d "$dest" ]]; then
      rm -rf "$dest"
    elif [[ -e "$dest" ]]; then
      rm -f "$dest"
    fi
    ln -sfn "$src" "$dest"
    linked=$((linked + 1))
  done

  echo "uiskills: linked ${linked} skill(s) from ${UISKILLS_DIR} -> ${CANONICAL_SKILLS}"
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
    [[ -d "$src" || -L "${src%/}" ]] || continue
    local name
    name="$(basename "$src")"
    [[ "$name" == ".system" ]] && continue
    if [[ ! -f "${CANONICAL_SKILLS}/${name}/SKILL.md" ]]; then
      echo "warning: skip skill without SKILL.md: $name" >&2
      continue
    fi
    for target in "${SKILL_TARGETS[@]}"; do
      # Never touch Codex system skills directory contents via name collision
      if [[ "$target" == "${HOME}/.codex/skills" && "$name" == ".system" ]]; then
        continue
      fi
      link_skill "$name" "$target"
    done
    linked=$((linked + 1))
  done

  echo "skills: linked ${linked} skill(s) to ${#SKILL_TARGETS[@]} agent directories"
}

mirror_skills_to_repo() {
  mkdir -p "$GLOBAL_MIRROR"

  local mirrored=0
  for src in "${CANONICAL_SKILLS}"/*/; do
    local name
    name="$(basename "$src")"
    [[ "$name" == ".system" ]] && continue
    if [[ ! -f "${CANONICAL_SKILLS}/${name}/SKILL.md" ]]; then
      continue
    fi
    local dest="${GLOBAL_MIRROR}/${name}"
    mkdir -p "$dest"
    # -L: copy through symlinks so global/ holds real files (ui-skills etc.)
    rsync -aL --delete "${CANONICAL_SKILLS}/${name}/" "${dest}/"
    mirrored=$((mirrored + 1))
  done

  # Drop mirror dirs that no longer exist in canonical
  for dest in "${GLOBAL_MIRROR}"/*/; do
    [[ -d "$dest" ]] || continue
    local name
    name="$(basename "$dest")"
    if [[ ! -e "${CANONICAL_SKILLS}/${name}/SKILL.md" ]]; then
      rm -rf "$dest"
      echo "global: removed stale mirror ${name}"
    fi
  done

  if [[ ! -f "${GLOBAL_MIRROR}/README.md" ]]; then
    cat > "${GLOBAL_MIRROR}/README.md" <<'EOF'
# global — runtime skills mirror

Full copy of `~/.claude/skills` for Git backup.

- **Do not edit here** as the primary source.
- Edit `../codeskill/<name>/` for engineering skills, `../ui-skills/skills/<name>/` for UI Skills, or `~/.claude/skills/<name>/` for other globals.
- Then run `~/Documents/code/rule/sync-global-agent-standards.sh`.
EOF
  fi

  echo "global: mirrored ${mirrored} skill(s) -> ${GLOBAL_MIRROR}"
}

count_skills() {
  local dir="$1"
  local n=0
  if [[ ! -d "$dir" ]]; then
    echo 0
    return
  fi
  for p in "${dir}"/*/; do
    [[ -e "$p" || -L "${p%/}" ]] || continue
    local name
    name="$(basename "$p")"
    [[ "$name" == ".system" ]] && continue
    if [[ -f "${dir}/${name}/SKILL.md" ]]; then
      n=$((n + 1))
    fi
  done
  echo "$n"
}

verify_skill_counts() {
  local canon
  canon="$(count_skills "$CANONICAL_SKILLS")"
  local global_n
  global_n="$(count_skills "$GLOBAL_MIRROR")"
  echo "verify: canonical=${canon} global=${global_n}"
  local target
  for target in "${SKILL_TARGETS[@]}"; do
    local n
    n="$(count_skills "$target")"
    echo "verify: ${target}=${n}"
    if [[ "$n" != "$canon" ]]; then
      echo "warning: count mismatch for ${target} (got ${n}, want ${canon})" >&2
    fi
  done
  if [[ "$global_n" != "$canon" ]]; then
    echo "warning: global mirror count mismatch (got ${global_n}, want ${canon})" >&2
  fi
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

    # Claude Code also reads claude.md
    if [[ "$src_name" == "claude-CLAUDE.md" ]]; then
      cp "$src" "${HOME}/.claude/claude.md"
      echo "agents: also deployed claude.md"
    fi
  done

  echo "agents: deployed ${deployed} template(s) from ${AGENTS_REPO}/"
}

main() {
  sync_codeskills
  sync_uiskills
  sync_skills
  mirror_skills_to_repo
  sync_rules_to_agents
  sync_rules_to_repo
  deploy_agents_files
  verify_skill_counts
  if [[ -x "${RULE_REPO}/sync-global-commands.sh" ]]; then
    "${RULE_REPO}/sync-global-commands.sh" || echo "warning: sync-global-commands.sh failed" >&2
  fi
  if [[ -x "${RULE_REPO}/sync-global-mcp.sh" ]]; then
    "${RULE_REPO}/sync-global-mcp.sh" || echo "warning: sync-global-mcp.sh failed" >&2
  fi
  if [[ -x "${RULE_REPO}/sync-global-env.sh" ]]; then
    "${RULE_REPO}/sync-global-env.sh" || echo "warning: sync-global-env.sh failed (skills/rules already synced)" >&2
  fi
  echo "Done."
  echo "  codeskill repo   : $CODESKILL_DIR"
  echo "  ui-skills dir    : $UISKILLS_DIR"
  echo "  skills canonical : $CANONICAL_SKILLS"
  echo "  skills global    : $GLOBAL_MIRROR"
  echo "  rules canonical  : $CANONICAL_RULES"
  echo "  rules repo mirror: $RULE_REPO/global/"
  echo "  commands repo    : $RULE_REPO/commands/"
  echo "  sync script      : $SYNC_SCRIPT"
}

main "$@"
