#!/usr/bin/env bash
# Sync canonical skills (~/.claude/skills) and rules (~/.cursor/rules) to all agents
# and mirror rules/agents/commands + agent_KB tooling into this repo (Documents/code/rule).
#
# Skills path mapping:
#   ~/Documents/code/skill/codeskill/*       →  ~/.claude/skills/*  (rsync)
#   ~/Documents/code/skill/ui-skills/skills/* →  ~/.claude/skills/*  (symlink)
#   ~/.claude/skills/*                       →  agent dirs (symlink)
#   ~/.claude/skills/*                       →  ~/Documents/code/skill/global/* (rsync mirror)
# agent_KB tooling:
#   ~/Documents/code/agent_KB/scripts|templates → rule/agent_KB/ (mirror)
#   rule/agent_KB → restore missing runtime files; install Cursor hooks
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
  "${HOME}/.cursor/skills"
  "${HOME}/.codex/skills"
)
# NOTE: ~/.agents/skills is the `npx skills` install store (real copies).
# Do NOT symlink over it from ~/.claude — that caused mass dangling links.

RULE_AGENT_TARGETS=(
  "${HOME}/.claude/rules"
)

RULE_REPO_CURSOR="${RULE_REPO}/global/cursor"
AGENTS_REPO="${RULE_REPO}/agents"

# template_name:dest_path  (claude-CLAUDE.md also copied to claude.md)
AGENT_DEPLOYS=(
  "codex-AGENTS.md:${HOME}/.codex/AGENTS.md"
  "claude-CLAUDE.md:${HOME}/.claude/CLAUDE.md"
)

VSCODE_DIR="${HOME}/.vscode"
VSCODE_SETTINGS="${HOME}/Library/Application Support/Code/User/settings.json"
AGENT_KB_DIR="${HOME}/Documents/code/agent_KB"

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
# Safety: only touches symlinks pointing into CANONICAL_SKILLS; real dirs and dotfiles are never touched.
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

# Bridge `npx skills` store (~/.agents/skills) into Claude canonical (~/.claude/skills).
bridge_agents_skills_into_claude() {
  local agents_dir="${HOME}/.agents/skills"
  mkdir -p "$CANONICAL_SKILLS"
  if [[ ! -d "$agents_dir" ]]; then
    echo "bridge: no $agents_dir — skip"
    return 0
  fi

  local linked=0
  local skipped=0
  local name dest src
  for src in "${agents_dir}"/*/; do
    [[ -d "$src" ]] || continue
    name="$(basename "$src")"
    [[ -f "${src}/SKILL.md" ]] || continue
    dest="${CANONICAL_SKILLS}/${name}"
    if [[ -L "$dest" ]]; then
      if [[ -f "${dest}/SKILL.md" ]]; then
        skipped=$((skipped + 1))
        continue
      fi
      rm -f "$dest"
    elif [[ -d "$dest" ]]; then
      if [[ -f "${dest}/SKILL.md" ]]; then
        skipped=$((skipped + 1))
        continue
      fi
      rm -rf "$dest"
    elif [[ -e "$dest" ]]; then
      rm -f "$dest"
    fi
    ln -sfn "$src" "$dest"
    linked=$((linked + 1))
  done
  echo "bridge: linked ${linked} agents skill(s) into ${CANONICAL_SKILLS} (skipped existing ${skipped})"
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

  # prune stale copies no longer in canonical.
  # Only consider global-*.md so user-authored personal rules in target dirs
  # (e.g. ~/.claude/rules/my-note.md) are never deleted.
  shopt -s nullglob
  for target in "${RULE_AGENT_TARGETS[@]}"; do
    local f name keep e
    for f in "${target}"/global-*.md; do
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

sync_vscode_copilot() {
  mkdir -p "$VSCODE_DIR"

  # Symlinks: rules, skills, agent_KB
  ln -sfn "$CANONICAL_RULES" "${VSCODE_DIR}/rules"
  ln -sfn "${HOME}/.codex/skills" "${VSCODE_DIR}/skills"
  ln -sfn "$AGENT_KB_DIR" "${VSCODE_DIR}/agent_KB"

  # Deploy copilot-instructions.md
  local src="${AGENTS_REPO}/vscode-copilot-instructions.md"
  if [[ -f "$src" ]]; then
    cp "$src" "${VSCODE_DIR}/copilot-instructions.md"
  else
    echo "warning: missing vscode-copilot-instructions.md template" >&2
  fi

  # Deploy deploy-copilot.sh
  local deploy_script="${RULE_REPO}/scripts/deploy-copilot.sh"
  if [[ -f "$deploy_script" ]]; then
    cp "$deploy_script" "${VSCODE_DIR}/deploy-copilot.sh"
    chmod +x "${VSCODE_DIR}/deploy-copilot.sh"
  fi

  # Update VSCode settings.json (merge copilot instructions, preserve existing keys)
  local settings_dir
  settings_dir="$(dirname "$VSCODE_SETTINGS")"
  mkdir -p "$settings_dir"

  python3 - "$VSCODE_SETTINGS" <<'PYEOF'
import json, sys, os

settings_path = sys.argv[1]
COPILOT_CODEGEN = "You are a senior engineer following global agent standards shared across Cursor, Claude Code, Codex, and VSCode Copilot.\n\n## Resources (read on demand)\n- Rules: ~/.vscode/rules/global-*.mdc\n- Skills: ~/.vscode/skills/<name>/SKILL.md (150+ skills)\n- Skill router: ~/Documents/code/skill/SKILL_ROUTER.md\n- Knowledge base: ~/.vscode/agent_KB/ (protocol: AGENTS.md; writable: inbox/ only)\n\n## Workflow\n- Project-local rules (AGENTS.md, .cursor/rules/, README.md, package.json) override globals.\n- Non-trivial changes: spec first, then implement, then verify.\n- Phase A (plan): explore -> spec -> task breakdown -> plan\n- Phase B (implement): TDD (red -> green -> refactor) + thin slices; UI tasks start with ui-skills-root\n- Phase C (review): verify against acceptance criteria -> code-review-and-quality -> verification-before-completion\n- Phase G (governance): diagnose -> simplify -> verify (behavior unchanged)\n\n## Next.js SaaS\n- Server Components first; Server Actions over API routes (except webhooks/cron)\n- Server Action rules: 'use server' on top, derive userId from session (never accept as arg), auth on first line, Zod validate, DB queries filter by userId, revalidate after mutation\n- Component layers: components/ui/ (shadcn) -> components/shared/ -> components/{domain}/\n- Personalized pages: force-dynamic; never cache user-data RSC\n\n## Security\n- RLS + app-layer userId filter (double insurance)\n- Zod validate all external input\n- Rate limit by userId + operation type; store in DB/Redis\n- AI quota: deduct after success only\n- Secrets via env, never in code\n\n## Performance\n- Same-page UI state (tabs/filters/pagination): setState + history.replaceState, NEVER router.push\n- Write operations: optimistic UI -> persist -> rollback on failure\n- Merge DB reads (Promise.all or CTE)\n- Auth middleware: local session fast-path, remote refresh only when token expiring\n\n## UI Conventions\n- shadcn + CSS variables; semantic tokens (background, foreground, muted, accent, destructive, border, ring)\n- accent = brand color; destructive = independent red; hover uses muted not accent\n- Typography: ui-text-title / ui-text-section / ui-text-body / ui-text-caption\n- Focus rings visible; aria-label on icon buttons; support prefers-reduced-motion\n- Button hover: CSS only (no scale); list entrance: framer-motion stagger; motion vars in lib/motion.ts\n\n## Skill Routing (read SKILL.md when intent matches)\n- Bug: systematic-debugging -> test-driven-development\n- New feature: spec-driven-development -> writing-plans -> incremental-implementation\n- UI task: ui-skills-root (MANDATORY first) -> design-taste-frontend / baseline-ui / improve-ui\n- Review: code-review-and-quality -> verification-before-completion\n- Deploy: deploy-to-vercel -> vercel-post-deploy-verify\n- Simplify: code-simplification / ponytail\n- Security: security-and-hardening\n\n## agent_KB\n- Protocol: ~/Documents/code/agent_KB/AGENTS.md (writable: inbox/ only)\n- Read _meta/index.md, profile/preferences.md, playbooks/, projects/ at start\n- File valuable answers to inbox/; lint via playbooks/wiki-lint\n- New/unhooked repo under ~/Documents/code/: run ~/Documents/code/agent_KB/scripts/hook-project.sh <dir> immediately (creates full AGENTS.md)\n- Tooling backup: ~/Documents/code/rule/agent_KB/"
COPILOT_SELECTION = "Follow ~/.vscode/rules/global-*.mdc. UI: shadcn + CSS vars, muted hover not accent, CSS for button hover. Server Actions: 'use server', auth first, Zod validate, userId from session. Same-page state: setState not router.push. New code repos: hook-project.sh for AGENTS.md + agent_KB."

try:
    with open(settings_path, 'r') as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

settings["github.copilot.chat.codeGeneration.instructions"] = [{"text": COPILOT_CODEGEN}]
settings["github.copilot.chat.editor.selection.instructions"] = [{"text": COPILOT_SELECTION}]

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=4, ensure_ascii=False)
    f.write("\n")
PYEOF

  echo "vscode: deployed symlinks (rules/skills/agent_KB) + copilot-instructions.md + settings.json"
}

refresh_project_copilot() {
  # Refresh .github/copilot-instructions.md in all ~/Documents/code/ projects that already have one
  local code_dir="${HOME}/Documents/code"
  local src="${VSCODE_DIR}/copilot-instructions.md"
  if [[ ! -f "$src" ]]; then
    echo "warning: no copilot-instructions.md to refresh from" >&2
    return 0
  fi
  local refreshed=0
  shopt -s nullglob
  local target
  for target in "$code_dir"/*/.github/copilot-instructions.md; do
    [[ -f "$target" ]] || continue
    cp "$src" "$target"
    refreshed=$((refreshed + 1))
  done
  shopt -u nullglob
  echo "vscode: refreshed copilot-instructions.md in ${refreshed} project(s)"
}

# Mirror agent_KB hook scripts/templates into this repo for backup / manual reinstall.
mirror_agent_kb_tooling() {
  local dest="${RULE_REPO}/agent_KB"
  mkdir -p "${dest}/scripts" "${dest}/templates"

  if [[ ! -d "$AGENT_KB_DIR" ]]; then
    echo "warning: agent_KB missing at $AGENT_KB_DIR — skip tooling mirror" >&2
    return 0
  fi

  local f
  for f in hook-project.sh cursor-auto-hook-agent-kb.sh install-cursor-auto-hook.sh; do
    if [[ -f "${AGENT_KB_DIR}/scripts/${f}" ]]; then
      cp "${AGENT_KB_DIR}/scripts/${f}" "${dest}/scripts/${f}"
      chmod +x "${dest}/scripts/${f}"
    else
      echo "warning: missing ${AGENT_KB_DIR}/scripts/${f}" >&2
    fi
  done

  if [[ -f "${AGENT_KB_DIR}/_templates/project-agents.md" ]]; then
    cp "${AGENT_KB_DIR}/_templates/project-agents.md" "${dest}/templates/project-agents.md"
  fi
  if [[ -f "${AGENT_KB_DIR}/_templates/project.md" ]]; then
    cp "${AGENT_KB_DIR}/_templates/project.md" "${dest}/templates/project.md"
  fi
  if [[ -f "${AGENT_KB_DIR}/projects/_POINTER_TEMPLATE.md" ]]; then
    cp "${AGENT_KB_DIR}/projects/_POINTER_TEMPLATE.md" "${dest}/templates/POINTER_TEMPLATE.md"
  fi

  # Keep README / hooks snippet if already authored in repo; do not overwrite README from empty
  if [[ ! -f "${dest}/README.md" ]]; then
    echo "warning: ${dest}/README.md missing — add install docs" >&2
  fi
  if [[ ! -f "${dest}/hooks.json.snippet" ]]; then
    cat >"${dest}/hooks.json.snippet" <<'EOF'
{
  "version": 1,
  "hooks": {
    "workspaceOpen": [
      { "command": "./hooks/auto-hook-agent-kb.sh", "timeout": 30 }
    ],
    "sessionStart": [
      { "command": "./hooks/auto-hook-agent-kb.sh", "timeout": 30 }
    ]
  }
}
EOF
  fi

  echo "agent_KB: mirrored tooling -> ${dest}/"
}

# Refresh LaunchAgent daily-sync script from rule/scripts (plist reload only if installer asked).
deploy_daily_sync_agent() {
  local src="${RULE_REPO}/scripts/daily-sync.sh"
  local dest_dir="${HOME}/Library/Application Support/agent-standards-sync"
  local dest="${dest_dir}/daily-sync.sh"
  if [[ ! -f "$src" ]]; then
    echo "warning: missing $src" >&2
    return 0
  fi
  mkdir -p "$dest_dir" "${HOME}/Library/Logs/agent-standards-sync"
  cp "$src" "$dest"
  chmod +x "$dest"
  echo "daily-sync: refreshed $dest"
}

# Ensure runtime scripts exist (restore from rule backup if needed) and install Cursor hooks.
deploy_agent_kb_cursor_hook() {
  mkdir -p "${AGENT_KB_DIR}/scripts" "${AGENT_KB_DIR}/_templates"

  local backup="${RULE_REPO}/agent_KB"
  local f
  for f in hook-project.sh cursor-auto-hook-agent-kb.sh install-cursor-auto-hook.sh; do
    if [[ ! -f "${AGENT_KB_DIR}/scripts/${f}" && -f "${backup}/scripts/${f}" ]]; then
      cp "${backup}/scripts/${f}" "${AGENT_KB_DIR}/scripts/${f}"
      echo "agent_KB: restored scripts/${f} from rule backup"
    fi
    if [[ -f "${AGENT_KB_DIR}/scripts/${f}" ]]; then
      chmod +x "${AGENT_KB_DIR}/scripts/${f}"
    fi
  done

  if [[ ! -f "${AGENT_KB_DIR}/_templates/project-agents.md" && -f "${backup}/templates/project-agents.md" ]]; then
    cp "${backup}/templates/project-agents.md" "${AGENT_KB_DIR}/_templates/project-agents.md"
    echo "agent_KB: restored _templates/project-agents.md from rule backup"
  fi

  local installer="${AGENT_KB_DIR}/scripts/install-cursor-auto-hook.sh"
  if [[ -x "$installer" ]]; then
    "$installer" || echo "warning: install-cursor-auto-hook.sh failed" >&2
  elif [[ -x "${backup}/scripts/install-cursor-auto-hook.sh" ]]; then
    # Point installer at live agent_KB via AGENT_KB env
    AGENT_KB="$AGENT_KB_DIR" "${backup}/scripts/install-cursor-auto-hook.sh" \
      || echo "warning: backup install-cursor-auto-hook.sh failed" >&2
  else
    echo "warning: no install-cursor-auto-hook.sh found" >&2
  fi
}

main() {
  sync_codeskills
  sync_uiskills
  bridge_agents_skills_into_claude
  sync_skills
  mirror_skills_to_repo
  sync_rules_to_agents
  sync_rules_to_repo
  deploy_agents_files
  verify_skill_counts
  sync_vscode_copilot
  refresh_project_copilot
  mirror_agent_kb_tooling
  deploy_agent_kb_cursor_hook
  deploy_daily_sync_agent
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
  echo "  agent_KB tooling : $RULE_REPO/agent_KB/"
  echo "  daily-sync       : $HOME/Library/Application Support/agent-standards-sync/daily-sync.sh"
  echo "  commands repo    : $RULE_REPO/commands/"
  echo "  sync script      : $SYNC_SCRIPT"
  echo "  vscode copilot   : $VSCODE_DIR (symlinks + copilot-instructions.md + settings.json)"
}

main "$@"
