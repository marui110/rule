#!/usr/bin/env bash
# Cursor user hook: 打开 ~/Documents/code 下未挂接仓库时，自动创建 AGENTS.md 并挂接 agent_KB。
# 事件: workspaceOpen / sessionStart
# 依赖: python3（解析 stdin JSON）、agent_KB/scripts/hook-project.sh
#
# 兼容 macOS bash 3.2。

set -euo pipefail

AGENT_KB="${AGENT_KB:-$HOME/Documents/code/agent_KB}"
HOOK_SCRIPT="$AGENT_KB/scripts/hook-project.sh"
CODE_ROOT="$HOME/Documents/code"
LOG_DIR="${TMPDIR:-/tmp}/cursor-agent-kb-hooks"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/auto-hook.log"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >>"$LOG_FILE" 2>/dev/null || true
}

emit_session_ctx() {
  # sessionStart: 可选 additional_context（可能因竞态未注入，文件写入仍生效）
  local msg="$1"
  python3 -c 'import json,sys; print(json.dumps({"additional_context": sys.argv[1]}, ensure_ascii=False))' "$msg"
}

emit_workspace_ok() {
  # workspaceOpen: 仅 pluginPaths 有意义；空对象即可
  printf '%s\n' '{}'
}

needs_hook() {
  local dir="$1"
  [ -d "$dir" ] || return 1
  # 仅 code 下业务仓；排除知识库与纯镜像目录
  case "$dir" in
    "$AGENT_KB"|"$CODE_ROOT/agent_KB") return 1 ;;
    "$CODE_ROOT/skill"|"$CODE_ROOT/skill"/*) return 1 ;;
  esac
  case "$dir" in
    "$CODE_ROOT"/*) ;;
    *) return 1 ;;
  esac
  # 跳过非项目噪音（无 .git 且无常见清单）
  if [ ! -d "$dir/.git" ] \
    && [ ! -f "$dir/package.json" ] \
    && [ ! -f "$dir/pyproject.toml" ] \
    && [ ! -f "$dir/Cargo.toml" ] \
    && [ ! -f "$dir/go.mod" ] \
    && [ ! -f "$dir/AGENTS.md" ]; then
    # 全新空仓：若用户刚 create_project（常有 .git），上面会命中；
    # 若完全空目录且无 git，仍允许挂接（用户明确打开了该文件夹）
    :
  fi

  local pointer="$dir/.cursor/rules/agent_KB-pointer.mdc"
  local agents="$dir/AGENTS.md"
  if [ -f "$pointer" ] && [ -f "$agents" ] && grep -q 'agent_KB' "$agents" 2>/dev/null; then
    return 1
  fi
  return 0
}

INPUT="$(cat || true)"
EVENT="$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  d={}
print(d.get("hook_event_name") or "")' 2>/dev/null || true)"

ROOTS="$(printf '%s' "$INPUT" | python3 -c 'import json,sys,os
try:
  d=json.load(sys.stdin)
except Exception:
  d={}
roots=d.get("workspace_roots") or []
env=os.environ.get("CURSOR_PROJECT_DIR") or ""
if not roots and env:
  roots=[env]
for r in roots:
  if r:
    print(r)' 2>/dev/null || true)"

if [ ! -x "$HOOK_SCRIPT" ] && [ -f "$HOOK_SCRIPT" ]; then
  chmod +x "$HOOK_SCRIPT" 2>/dev/null || true
fi

HOOKED=""
MISSING_SCRIPT=0
if [ ! -f "$HOOK_SCRIPT" ]; then
  MISSING_SCRIPT=1
  log "error: missing $HOOK_SCRIPT"
else
  OLDIFS=$IFS
  IFS='
'
  for root in $ROOTS; do
    IFS=$OLDIFS
    [ -n "$root" ] || continue
    if needs_hook "$root"; then
      log "hooking: $root"
      if "$HOOK_SCRIPT" "$root" >>"$LOG_FILE" 2>&1; then
        HOOKED="${HOOKED}${HOOKED:+, }$(basename "$root")"
      else
        log "error: hook-project failed for $root"
      fi
    else
      log "skip: $root"
    fi
    IFS='
'
  done
  IFS=$OLDIFS
fi

CTX=""
if [ "$MISSING_SCRIPT" -eq 1 ]; then
  CTX="agent_KB auto-hook: 未找到 scripts/hook-project.sh，无法自动创建 AGENTS.md。"
elif [ -n "$HOOKED" ]; then
  CTX="已自动挂接 agent_KB 并创建/补全 AGENTS.md：${HOOKED}。请补全「技术栈 / 项目结构」占位，并编辑 agent_KB/projects/<name>.md。"
fi

case "$EVENT" in
  sessionStart)
    if [ -n "$CTX" ]; then
      emit_session_ctx "$CTX"
    else
      printf '%s\n' '{}'
    fi
    ;;
  workspaceOpen|*)
    emit_workspace_ok
    ;;
esac
exit 0
