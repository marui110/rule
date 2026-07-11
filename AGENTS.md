# Agent 指令

| 层级 | 路径 |
|------|------|
| 全局（跨项目） | `~/.cursor/rules/global-*.mdc`（见 `global-agent-manifest.mdc`） |
| 全局 Skills（运行时） | `~/.claude/skills/` |
| codeskill 权威源 | `~/Documents/code/skill/codeskill/`（含 `evolve-skills`） |
| 规则镜像（本仓库） | `global/cursor/`、`global/trae-cn/`、`global/codebuddy/` |
| Slash 命令（本仓库） | `commands/*.md` → `~/.cursor/commands`、`~/.claude/commands` |
| Agent 模板 | `agents/*.md` → 部署至 `~/.codex/`、`~/.workbuddy/` 等 |
| 本项目 | `project/.cursor/rules/*.mdc` |

本地规则优先于全局。

**同步所有 Agent + 本仓库：**

```bash
~/Documents/code/rule/sync-global-agent-standards.sh
```

兼容旧路径：`~/.agents/sync-global-agent-standards.sh`（wrapper）

**同步 Slash 命令（Cursor / Claude Code）：**

```bash
~/Documents/code/rule/sync-global-commands.sh
```

**同步 MCP（Cursor / Trae CN → Claude / Codex / WorkBuddy）：**

```bash
~/Documents/code/rule/sync-global-mcp.sh --import   # 先从 Cursor/Trae 导入再部署
~/Documents/code/rule/sync-global-mcp.sh            # 仅按 mcp/canonical.json 部署
```

**统一 Python / Node 运行时：**

```bash
~/Documents/code/rule/sync-global-env.sh
```

- Python → Miniconda `base`（`python3.14`）
- Node.js → Homebrew（`/opt/homebrew/bin/node`）
- 详见 `env/README.md`

## Skills 自进化

- codeskill 权威源：`~/Documents/code/skill/codeskill/`（含 `evolve-skills`）
- 运行时：`~/.claude/skills/` → 各 Agent symlink
- Meta skill：`evolve-skills`
- 规则：`global-skills-evolution.mdc`
- 用户纠正 / 重复踩坑 → 读 `evolve-skills` → 改对应权威源 → 跑同步脚本
