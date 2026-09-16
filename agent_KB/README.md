# agent_KB 挂接工具备份（rule 仓）

本目录是 `~/Documents/code/agent_KB` 挂接/自动创建 `AGENTS.md` 相关脚本与模板的 **Git 备份**，便于换机或手动安装。

## 权威源 vs 备份

| 角色 | 路径 |
|------|------|
| **运行时权威** | `~/Documents/code/agent_KB/scripts/`、`_templates/`、`AGENTS.md` |
| **本仓备份** | `~/Documents/code/rule/agent_KB/`（由 `sync-global-agent-standards.sh` 镜像） |
| **协议** | `~/Documents/code/agent_KB/AGENTS.md`（各 Agent 入口均 `@` / 引用） |

日常改脚本：先改 `agent_KB/`，再跑同步 → 回写本目录。

## 目录

```
agent_KB/
├── README.md                 # 本文件
├── hooks.json.snippet        # Cursor 用户 hook 片段
├── scripts/
│   ├── hook-project.sh                 # 挂接业务仓（创建完整 AGENTS.md）
│   ├── cursor-auto-hook-agent-kb.sh    # workspaceOpen / sessionStart 执行体
│   └── install-cursor-auto-hook.sh     # 安装/卸载 ~/.cursor hooks
└── templates/
    ├── project-agents.md     # 新项目 AGENTS.md 骨架
    ├── project.md            # agent_KB projects/<name>.md 模板
    └── POINTER_TEMPLATE.md   # 业务仓手动挂接说明
```

## 手动安装（新机器）

```bash
# 1. 确保知识库存在
#    ~/Documents/code/agent_KB

# 2. 从本备份恢复脚本（若 agent_KB 缺脚本）
rsync -a ~/Documents/code/rule/agent_KB/scripts/ ~/Documents/code/agent_KB/scripts/
rsync -a ~/Documents/code/rule/agent_KB/templates/project-agents.md \
  ~/Documents/code/agent_KB/_templates/project-agents.md
chmod +x ~/Documents/code/agent_KB/scripts/*.sh

# 3. 安装 Cursor 自动挂接
~/Documents/code/agent_KB/scripts/install-cursor-auto-hook.sh

# 4. 全量同步各 Agent 规则/入口
~/Documents/code/rule/sync-global-agent-standards.sh
```

或只跑同步脚本（会镜像备份 + 部署 Cursor hook）：

```bash
~/Documents/code/rule/sync-global-agent-standards.sh
```

## 手动挂接单个项目

```bash
~/Documents/code/agent_KB/scripts/hook-project.sh ~/Documents/code/<repo>
~/Documents/code/agent_KB/scripts/hook-project.sh ~/Documents/code/<repo> --name <page-name>
~/Documents/code/agent_KB/scripts/hook-project.sh ~/Documents/code/<repo> --dry-run
```

## 各智能体如何生效

| Agent | 如何拿到本规则 |
|-------|----------------|
| Cursor | `global-agent-manifest.mdc` + 用户 hook + 项目 `AGENTS.md` |
| Claude Code | `~/.claude/CLAUDE.md` → `@agent_KB/AGENTS.md` |
| Codex | `~/.codex/AGENTS.md` → `@agent_KB/AGENTS.md` |
| VSCode Copilot | `~/.vscode/copilot-instructions.md` + symlink `agent_KB` |
| 任意 Agent | 协议以 `agent_KB/AGENTS.md` 为准（Query 回写、Lint、新项目强制 hook） |

卸载 Cursor 自动挂接：

```bash
~/Documents/code/agent_KB/scripts/install-cursor-auto-hook.sh --uninstall
```
