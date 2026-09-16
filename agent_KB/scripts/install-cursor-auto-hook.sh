#!/usr/bin/env bash
# 安装 Cursor 用户级自动挂接：打开 ~/Documents/code 下未挂接仓库时创建 AGENTS.md
# 用法: ~/Documents/code/agent_KB/scripts/install-cursor-auto-hook.sh [--uninstall]
set -euo pipefail

AGENT_KB="${AGENT_KB:-$HOME/Documents/code/agent_KB}"
SRC="$AGENT_KB/scripts/cursor-auto-hook-agent-kb.sh"
HOOK_DIR="$HOME/.cursor/hooks"
LINK="$HOOK_DIR/auto-hook-agent-kb.sh"
HOOKS_JSON="$HOME/.cursor/hooks.json"

if [ "${1:-}" = "--uninstall" ]; then
  rm -f "$LINK"
  python3 - "$HOOKS_JSON" <<'PY'
import json, sys, os
path = sys.argv[1]
if not os.path.isfile(path):
  raise SystemExit(0)
with open(path) as f:
  data = json.load(f)
hooks = data.get("hooks") or {}
for event in list(hooks):
  hooks[event] = [e for e in hooks[event] if "auto-hook-agent-kb" not in str(e.get("command", ""))]
  if not hooks[event]:
    del hooks[event]
data["hooks"] = hooks
with open(path, "w") as f:
  json.dump(data, f, indent=2)
  f.write("\n")
print("uninstalled auto-hook-agent-kb from", path)
PY
  echo "done (uninstall)"
  exit 0
fi

[ -f "$SRC" ] || { echo "missing $SRC"; exit 1; }
chmod +x "$SRC" "$AGENT_KB/scripts/hook-project.sh"
mkdir -p "$HOOK_DIR"
ln -sfn "$SRC" "$LINK"

python3 - "$HOOKS_JSON" <<'PY'
import json, os, sys
path = sys.argv[1]
desired = {"command": "./hooks/auto-hook-agent-kb.sh", "timeout": 30}
data = {"version": 1, "hooks": {}}
if os.path.isfile(path):
  with open(path) as f:
    data = json.load(f)
data.setdefault("version", 1)
data.setdefault("hooks", {})
for event in ("workspaceOpen", "sessionStart"):
  entries = data["hooks"].setdefault(event, [])
  entries[:] = [e for e in entries if "auto-hook-agent-kb" not in str(e.get("command", ""))]
  entries.append(dict(desired))
with open(path, "w") as f:
  json.dump(data, f, indent=2)
  f.write("\n")
print("installed ->", path)
PY

echo "OK. 打开新仓或新开 Agent 会话时会自动创建/补全 AGENTS.md。"
echo "日志: \${TMPDIR:-/tmp}/cursor-agent-kb-hooks/auto-hook.log"
echo "卸载: $0 --uninstall"
