#!/usr/bin/env bash
# Sync canonical skills (~/.claude/skills) and rules (~/.cursor/rules) to all agents
# and mirror rules/agents/commands templates into this repo (Documents/code/rule).
#
# Skills path mapping:
#   ~/Documents/code/skill/codeskill/*       →  ~/.claude/skills/*  (rsync)
#   ~/Documents/code/skill/ui-skills/skills/* →  ~/.claude/skills/*  (symlink)
#   ~/.claude/skills/*                       →  agent dirs (symlink)
#   ~/.claude/skills/*                       →  ~/.workbuddy/skills/* (symlink)
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
  "${HOME}/.codex/skills"
  "${HOME}/.workbuddy/skills"
)

RULE_AGENT_TARGETS=(
  "${HOME}/.claude/rules"
)

RULE_REPO_CURSOR="${RULE_REPO}/global/cursor"
AGENTS_REPO="${RULE_REPO}/agents"

# WorkBuddy target: converted rules (full dump + injected summary block)
WB_RULES_FILE="${HOME}/.workbuddy/RULES.md"
WB_MEMORY_FILE="${HOME}/.workbuddy/MEMORY.md"
WB_BLOCK_START="<!-- WB-RULES:START -->"
WB_BLOCK_END="<!-- WB-RULES:END -->"

# template_name:dest_path  (claude-CLAUDE.md also copied to claude.md)
AGENT_DEPLOYS=(
  "codex-AGENTS.md:${HOME}/.codex/AGENTS.md"
  "claude-CLAUDE.md:${HOME}/.claude/CLAUDE.md"
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

# Remove stale symlinks in a target dir whose canonical source no longer exists.
# Safety: only touches symlinks pointing into CANONICAL_SKILLS; real dirs (e.g.
# tool-managed skills like WorkBuddy's own) and dotfiles are never touched.
prune_stale_links() {
  local target="$1"
  local pruned=0
  shopt -s nullglob
  local entry name real
  for entry in "${target}"/*; do
    name="$(basename "$entry")"
    [[ "$name" == .* ]] && continue            # never touch dotfiles (tool-managed)
    [[ -L "$entry" ]] || continue              # never touch real dirs/files
    real="$(readlink "$entry")"
    case "$real" in
      "${CANONICAL_SKILLS}"/*) ;;              # points into canonical — ours
      *) continue ;;                           # foreign symlink — leave it
    esac
    if [[ ! -e "${CANONICAL_SKILLS}/${name}/SKILL.md" ]]; then
      rm -f "$entry"
      echo "skills: pruned stale link ${target}/${name}" >&2
      pruned=$((pruned + 1))
    fi
  done
  shopt -u nullglob
  echo "$pruned"
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

  local pruned_total=0
  local target
  for target in "${SKILL_TARGETS[@]}"; do
    pruned_total=$((pruned_total + $(prune_stale_links "$target")))
  done

  echo "skills: linked ${linked} skill(s) to ${#SKILL_TARGETS[@]} agent directories; pruned ${pruned_total} stale link(s)"
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

  # expected file names (base + .md)
  local expected=()
  local base
  for rule in "${GLOBAL_RULES[@]}"; do
    base="$(basename "$rule" .mdc)"
    expected+=("${base}.md")
  done

  local target
  for target in "${RULE_AGENT_TARGETS[@]}"; do
    mkdir -p "$target"
  done

  local copied=0
  for rule in "${GLOBAL_RULES[@]}"; do
    base="$(basename "$rule" .mdc)"
    for target in "${RULE_AGENT_TARGETS[@]}"; do
      cp "$rule" "${target}/${base}.md"
    done
    copied=$((copied + 1))
  done

  # prune stale copies no longer in canonical
  shopt -s nullglob
  for target in "${RULE_AGENT_TARGETS[@]}"; do
    local f name keep e
    for f in "${target}"/*.md; do
      name="$(basename "$f")"
      keep=0
      for e in "${expected[@]}"; do
        [[ "$e" == "$name" ]] && keep=1 && break
      done
      if [[ "$keep" == "0" ]]; then
        rm -f "$f"
        echo "rules: removed stale ${target}/${name}"
      fi
    done
  done
  shopt -u nullglob

  echo "rules: copied ${copied} global rule(s) to ${#RULE_AGENT_TARGETS[@]} agent directories"
}

sync_rules_to_repo() {
  collect_global_rules

  mkdir -p "$RULE_REPO_CURSOR"

  local expected=()
  local base
  for rule in "${GLOBAL_RULES[@]}"; do
    expected+=("$(basename "$rule")")
  done

  local copied=0
  for rule in "${GLOBAL_RULES[@]}"; do
    base="$(basename "$rule" .mdc)"
    cp "$rule" "${RULE_REPO_CURSOR}/${base}.mdc"
    copied=$((copied + 1))
  done

  if [[ -f "${CANONICAL_RULES}/README.md" ]]; then
    cp "${CANONICAL_RULES}/README.md" "${RULE_REPO_CURSOR}/README.md"
  fi

  # prune stale mirror rules
  shopt -s nullglob
  local f name keep e
  for f in "${RULE_REPO_CURSOR}"/global-*.mdc; do
    name="$(basename "$f")"
    keep=0
    for e in "${expected[@]}"; do
      [[ "$e" == "$name" ]] && keep=1 && break
    done
    if [[ "$keep" == "0" ]]; then
      rm -f "$f"
      echo "repo: removed stale mirror ${name}"
    fi
  done
  shopt -u nullglob

  echo "repo: mirrored ${copied} global rule(s) to ${RULE_REPO}/global/"
}

# --- WorkBuddy rules target -------------------------------------------------
# Converts canonical global-*.mdc (Cursor format) into WorkBuddy-readable form:
#   1. ~/.workbuddy/RULES.md        — full dump (frontmatter stripped), regenerated every sync
#   2. ~/.workbuddy/MEMORY.md       — auto-maintained block between
#                                     <!-- WB-RULES:START --> / <!-- WB-RULES:END -->
#                                     (injected each session; guides agent to RULES.md)
# Canonical source stays ~/.cursor/rules/global-*.mdc (single source of truth).

# Strip YAML frontmatter (first `---` block); body is markdown, kept as-is.
extract_mdc_body() {
  awk '
    NR == 1 && $0 == "---" { fm = 1; next }
    fm == 1 && $0 == "---" { fm = 0; next }
    fm == 0 { print }
  ' "$1"
}

# Pull the frontmatter `description:` line (quotes stripped).
mdc_description() {
  awk -v q="'" '
    /^description:[[:space:]]*/ {
      line = $0
      sub(/^description:[[:space:]]*/, "", line)
      gsub(/"/, "", line)
      gsub(q, "", line)
      print line
      exit
    }
  ' "$1"
}

sync_rules_to_workbuddy() {
  if [[ ! -d "$CANONICAL_RULES" ]]; then
    echo "error: missing canonical rules dir: $CANONICAL_RULES" >&2
    exit 1
  fi

  collect_global_rules
  mkdir -p "${HOME}/.workbuddy"

  # 1. Full dump -> RULES.md (overwrite every sync)
  local gen_ts
  gen_ts="$(date '+%Y-%m-%d %H:%M:%S %z')"
  {
    echo "# WorkBuddy 全局规则（自动同步产物）"
    echo
    echo "- 权威源：\`${CANONICAL_RULES}/global-*.mdc\`（Cursor 格式，单一权威源；仓库镜像 \`${RULE_REPO}/global/cursor/\`）"
    echo "- 生成时间：${gen_ts}，由 \`${SYNC_SCRIPT}\` 自动生成"
    echo "- **勿手改本文件**：改规则请编辑权威源，再重跑同步脚本"
    echo "- 优先级：**项目规则 > 全局规则**"
    echo
    echo "## 目录"
    echo
    local rule base desc
    for rule in "${GLOBAL_RULES[@]}"; do
      base="$(basename "$rule" .mdc)"
      desc="$(mdc_description "$rule")"
      echo "- \`${base}.mdc\` — ${desc:-（无描述）}"
    done
    echo
    echo "---"
    echo
    for rule in "${GLOBAL_RULES[@]}"; do
      base="$(basename "$rule" .mdc)"
      echo "## ${base}"
      echo
      extract_mdc_body "$rule"
      echo
      echo "---"
      echo
    done
  } > "$WB_RULES_FILE"

  # 2. Summary block -> MEMORY.md (only the START/END section, user content untouched)
  local summary_file
  summary_file="$(mktemp "${TMPDIR:-/tmp}/wb-rules.XXXXXX")"
  {
    echo "## 全局规则自动同步（脚本维护，勿手改此区块）"
    echo
    echo "- 权威源：\`${CANONICAL_RULES}/global-*.mdc\`；WorkBuddy 产物 **\`~/.workbuddy/RULES.md\`**（跑同步脚本自动刷新）"
    echo "- 使用：每会话先扫 RULES.md 目录，命中主题再读对应段落；项目规则优先于全局。"
    echo "- 规则清单："
    local rule base desc
    for rule in "${GLOBAL_RULES[@]}"; do
      base="$(basename "$rule" .mdc)"
      desc="$(mdc_description "$rule")"
      echo "  - \`${base}\` — ${desc:-（无描述）}"
    done
  } > "$summary_file"

  python3 - "$summary_file" "$WB_MEMORY_FILE" "$WB_BLOCK_START" "$WB_BLOCK_END" <<'PY'
import sys, pathlib

summary_file, mem_file, block_start, block_end = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
block = f"{block_start}\n" + pathlib.Path(summary_file).read_text().rstrip() + f"\n{block_end}\n"

p = pathlib.Path(mem_file)
content = p.read_text() if p.exists() else ""
if block_start in content and block_end in content:
    head = content.split(block_start)[0]
    tail = content.split(block_end, 1)[1].lstrip("\n")
    new = head.rstrip() + "\n\n" + block + tail
else:
    new = content.rstrip() + "\n\n" + block
p.write_text(new)
PY
  rm -f "$summary_file"

  echo "rules: workbuddy RULES.md regenerated (${#GLOBAL_RULES[@]} rule(s)) -> ${WB_RULES_FILE}"
  echo "rules: workbuddy MEMORY.md block updated -> ${WB_MEMORY_FILE}"
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
  sync_rules_to_workbuddy
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
  echo "  skills workbuddy : ${HOME}/.workbuddy/skills"
  echo "  rules canonical  : $CANONICAL_RULES"
  echo "  rules repo mirror: $RULE_REPO/global/"
  echo "  rules workbuddy  : $WB_RULES_FILE (+ MEMORY.md block)"
  echo "  commands repo    : $RULE_REPO/commands/"
  echo "  sync script      : $SYNC_SCRIPT"
}

main "$@"
