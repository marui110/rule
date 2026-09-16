#!/usr/bin/env bash
# hook-project.sh — 将业务仓库挂接到 agent_KB
# 用法:
#   ~/Documents/code/agent_KB/scripts/hook-project.sh <project_dir> [--name <repo-name>] [--dry-run]
#   ~/Documents/code/agent_KB/scripts/hook-project.sh .   # 在项目根执行
#
# 幂等：已存在的 pointer / 项目页 / AGENTS 段落不会覆盖正文，仅补缺。
# 兼容 macOS 默认 bash 3.2（不用 mapfile / ${var,,} / |&）。

set -euo pipefail

AGENT_KB="${AGENT_KB:-$HOME/Documents/code/agent_KB}"
TODAY="$(date +%Y-%m-%d)"
DRY_RUN=0
PROJECT_DIR=""
REPO_NAME=""

usage() {
  cat <<'EOF'
Usage: hook-project.sh <project_dir> [--name <repo-name>] [--dry-run]

Creates / updates:
  <project>/.cursor/rules/agent_KB-pointer.mdc
  <project>/AGENTS.md          (append KB section if missing)
  <project>/CLAUDE.md          (thin pointer if missing)
  agent_KB/projects/<name>.md  (from template if missing)
  agent_KB/_meta/index.md      (append project row if missing)
  agent_KB/00-首页.md           (append project wikilink if missing)

EOF
}

log() { printf '%s\n' "$*"; }
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY: $*"
    return 0
  fi
  "$@"
}

write_file() {
  # write_file <path>  (content on stdin)
  local path="$1"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY: write $path"
    cat >/dev/null
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  cat >"$path"
}

append_file() {
  local path="$1"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY: append $path"
    cat >/dev/null
    return 0
  fi
  cat >>"$path"
}

# --- parse args ---
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --name)
      [ $# -ge 2 ] || { log "error: --name needs value"; exit 1; }
      REPO_NAME="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      log "error: unknown flag: $1"
      usage
      exit 1
      ;;
    *)
      if [ -z "$PROJECT_DIR" ]; then
        PROJECT_DIR="$1"
      else
        log "error: unexpected arg: $1"
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$PROJECT_DIR" ]; then
  usage
  exit 1
fi

if [ ! -d "$AGENT_KB" ]; then
  log "error: agent_KB not found: $AGENT_KB"
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
if [ -z "$REPO_NAME" ]; then
  REPO_NAME="$(basename "$PROJECT_DIR")"
fi

# 知识库自身：只确保项目页存在，不写业务 pointer
if [ "$PROJECT_DIR" = "$AGENT_KB" ]; then
  log "note: target is agent_KB itself; only ensuring projects/${REPO_NAME}.md"
fi

POINTER="$PROJECT_DIR/.cursor/rules/agent_KB-pointer.mdc"
AGENTS_FILE="$PROJECT_DIR/AGENTS.md"
CLAUDE_FILE="$PROJECT_DIR/CLAUDE.md"
PROJECT_PAGE="$AGENT_KB/projects/${REPO_NAME}.md"
INDEX_FILE="$AGENT_KB/_meta/index.md"
HOME_FILE="$AGENT_KB/00-首页.md"
TEMPLATE="$AGENT_KB/_templates/project.md"
AGENTS_TEMPLATE="$AGENT_KB/_templates/project-agents.md"

KB_SECTION=$(cat <<EOF

## 个人知识库（agent_KB）

- 根目录：\`/Users/marui/Documents/code/agent_KB\`
- 协议：\`/Users/marui/Documents/code/agent_KB/AGENTS.md\`
- 本项目页：\`/Users/marui/Documents/code/agent_KB/projects/${REPO_NAME}.md\`
- 写入：仅 \`inbox/\`；正式区需用户确认晋升
EOF
)

POINTER_BODY=$(cat <<EOF
---
description: Personal agent_KB knowledge base pointer
alwaysApply: true
---

# 个人知识库（agent_KB）

会话涉及可复用结论、偏好、跨项目决策时，遵循：

\`/Users/marui/Documents/code/agent_KB/AGENTS.md\`

- 根目录：\`/Users/marui/Documents/code/agent_KB\`
- 本项目页：\`/Users/marui/Documents/code/agent_KB/projects/${REPO_NAME}.md\`
- 默认可写：仅 \`inbox/\`
- 正式区（memory / playbooks / profile）需用户确认后再晋升写入
- 开始任务可先读：\`profile/preferences.md\`、相关 \`playbooks/\`、本项目页
EOF
)

CLAUDE_BODY=$(cat <<EOF
# Claude Code

本仓库挂接个人 Agent 知识库。

请完整遵守：@/Users/marui/Documents/code/agent_KB/AGENTS.md

- 库根：\`/Users/marui/Documents/code/agent_KB\`
- 本项目页：\`/Users/marui/Documents/code/agent_KB/projects/${REPO_NAME}.md\`
- 默认可写：仅 \`inbox/\`
- 正式区写入需用户确认晋升
EOF
)

log "==> hook ${REPO_NAME}"
log "    project: $PROJECT_DIR"
log "    kb:      $AGENT_KB"

# 1) Cursor pointer
if [ "$PROJECT_DIR" != "$AGENT_KB" ]; then
  if [ -f "$POINTER" ]; then
    log "skip: pointer exists ($POINTER)"
  else
    printf '%s\n' "$POINTER_BODY" | write_file "$POINTER"
    log "ok:   wrote $POINTER"
  fi

  # 2) AGENTS.md — 缺失则用完整模板创建；已有则仅补 KB 段
  if [ -f "$AGENTS_FILE" ]; then
    if grep -q 'agent_KB' "$AGENTS_FILE" 2>/dev/null; then
      log "skip: AGENTS.md already mentions agent_KB"
    else
      printf '%s\n' "$KB_SECTION" | append_file "$AGENTS_FILE"
      log "ok:   appended KB section to AGENTS.md"
    fi
  else
    if [ -f "$AGENTS_TEMPLATE" ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        log "DRY: write $AGENTS_FILE from project-agents template"
      else
        sed -e "s/{{name}}/${REPO_NAME}/g" "$AGENTS_TEMPLATE" >"$AGENTS_FILE"
        log "ok:   created AGENTS.md from _templates/project-agents.md"
      fi
    else
      {
        printf '%s\n' "# Agent 指令"
        printf '%s\n' ""
        printf '%s\n' "本地规则优先于全局。完整 skill 路由见 \`global-agent-workflow.mdc\`。"
        printf '%s\n' "$KB_SECTION"
      } | write_file "$AGENTS_FILE"
      log "ok:   created AGENTS.md (fallback)"
    fi
  fi

  # 3) CLAUDE.md（缺失才建，不覆盖已有）
  if [ -f "$CLAUDE_FILE" ]; then
    if grep -q 'agent_KB' "$CLAUDE_FILE" 2>/dev/null; then
      log "skip: CLAUDE.md already mentions agent_KB"
    else
      printf '%s\n' "$KB_SECTION" | append_file "$CLAUDE_FILE"
      log "ok:   appended KB section to CLAUDE.md"
    fi
  else
    printf '%s\n' "$CLAUDE_BODY" | write_file "$CLAUDE_FILE"
    log "ok:   created CLAUDE.md"
  fi
fi

# 4) projects/<name>.md
if [ -f "$PROJECT_PAGE" ]; then
  log "skip: project page exists ($PROJECT_PAGE)"
else
  if [ -f "$TEMPLATE" ]; then
    # 简单替换 {{name}} / {{date}}
    if [ "$DRY_RUN" -eq 1 ]; then
      log "DRY: write $PROJECT_PAGE from template"
    else
      sed -e "s/{{name}}/${REPO_NAME}/g" -e "s/{{date}}/${TODAY}/g" "$TEMPLATE" \
        | sed "s|- 仓库路径：|- 仓库路径：\`${PROJECT_DIR}\`|" \
        >"$PROJECT_PAGE"
      # 若模板「目标与上下文」为空，补一行占位提示
      log "ok:   created $PROJECT_PAGE"
    fi
  else
    {
      cat <<EOF
---
type: project
status: canon
tags: [project]
project: "${REPO_NAME}"
updated: ${TODAY}
---

# 项目：${REPO_NAME}

## 指针

- 仓库路径：\`${PROJECT_DIR}\`
- 知识库协议：[[AGENTS]]
- 本页：\`projects/${REPO_NAME}.md\`

## 目标与上下文

（待补）

## 关键约定

- 业务规则以仓库内 \`AGENTS.md\` / \`.cursor/rules\` 为准
- 可复用结论写入知识库 \`inbox/\`，勿默认污染正式区

## 最近动态

- ${TODAY}：挂接个人知识库 agent_KB
EOF
    } | write_file "$PROJECT_PAGE"
    log "ok:   created $PROJECT_PAGE (fallback)"
  fi
fi

# 5) index 行
WIKI_LINK="[[projects/${REPO_NAME}]]"
if [ -f "$INDEX_FILE" ] && grep -q "projects/${REPO_NAME}" "$INDEX_FILE" 2>/dev/null; then
  log "skip: index already lists ${REPO_NAME}"
else
  ROW="| ${WIKI_LINK} | （待补一句话摘要；仓：\`${PROJECT_DIR}\`） |"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY: append index row for ${REPO_NAME}"
  else
    # 插在 Projects 表末尾：在「## Profile」之前插入
    if grep -q '^## Profile' "$INDEX_FILE" 2>/dev/null; then
      # macOS sed: 用临时文件
      tmp="${INDEX_FILE}.tmp.$$"
      awk -v row="$ROW" '
        /^## Profile/ && !done { print row; done=1 }
        { print }
      ' "$INDEX_FILE" >"$tmp" && mv "$tmp" "$INDEX_FILE"
      log "ok:   index += ${REPO_NAME}"
    else
      printf '%s\n' "$ROW" | append_file "$INDEX_FILE"
      log "ok:   index appended ${REPO_NAME} (no Profile section)"
    fi
  fi
fi

# 6) 首页项目列表
if [ -f "$HOME_FILE" ] && grep -q "projects/${REPO_NAME}" "$HOME_FILE" 2>/dev/null; then
  log "skip: home already lists ${REPO_NAME}"
else
  HOME_LINE="- [[projects/${REPO_NAME}]]"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY: append home link for ${REPO_NAME}"
  else
    if grep -q '^## 怎么用（人）' "$HOME_FILE" 2>/dev/null; then
      tmp="${HOME_FILE}.tmp.$$"
      awk -v line="$HOME_LINE" '
        /^## 怎么用（人）/ && !done { print line; print ""; done=1 }
        { print }
      ' "$HOME_FILE" >"$tmp" && mv "$tmp" "$HOME_FILE"
      log "ok:   home += ${REPO_NAME}"
    else
      printf '%s\n' "$HOME_LINE" | append_file "$HOME_FILE"
      log "ok:   home appended ${REPO_NAME}"
    fi
  fi
fi

log "==> done. Next: 编辑 projects/${REPO_NAME}.md 的「目标与上下文」；需要时更新 changelog。"
