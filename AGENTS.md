# Agent 指令

| 层级 | 路径 |
|------|------|
| 全局（跨项目） | `~/.cursor/rules/global-*.mdc`（见 `global-agent-manifest.mdc`） |
| 全局 Skills（运行时） | `~/.claude/skills/` |
| Git 全量镜像 | `~/Documents/code/skill/global/` |
| 场景路由 / 目录 | `~/Documents/code/skill/SKILL_ROUTER.md`、`SKILLS_INDEX.md` |
| codeskill 权威源 | `~/Documents/code/skill/codeskill/`（含 `evolve-skills`） |
| UI Skills（ibelick） | `~/Documents/code/skill/ui-skills/` → `ui-skills-root` 等；规则 `global-ui-skills.mdc` |
| Agent 入口模板 | `agents/claude-CLAUDE.md` → `~/.claude/CLAUDE.md`；`agents/codex-AGENTS.md` → `~/.codex/AGENTS.md`；`agents/trae-AGENTS.md` → `~/.trae-cn/AGENTS.md` |
| Codex 脚手架 | `global-codex-project-structure.mdc`（新建 Codex/Agent 项目时） |
| 规则镜像（本仓库） | `global/cursor/`、`global/trae-cn/` |
| Slash 命令（本仓库） | `commands/*.md` → `~/.cursor/commands`、`~/.claude/commands` |
| 本项目 | `project/.cursor/rules/*.mdc` |

本地规则优先于全局。命中意图时**自动**读对应 skill（见 `SKILL_ROUTER.md` / `global-agent-workflow`）。

**同步所有 Agent + 本仓库：**

```bash
~/Documents/code/rule/sync-global-agent-standards.sh
```

兼容旧路径：`~/.agents/sync-global-agent-standards.sh`（wrapper）

**同步 Slash 命令（Cursor / Claude Code）：**

```bash
~/Documents/code/rule/sync-global-commands.sh
```

**同步 MCP（Cursor / Trae CN → Claude / Codex）：**

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

## UI Skills

`~/Documents/code/` 下所有项目的 UI 任务：

1. `npx ui-skills start` 或读 `ui-skills-root`
2. 再加载选出的 skill（≤3）
3. 细则见 `global-ui-skills.mdc`

更新：

```bash
npx skills add ibelick/ui-skills -g -y
# 或 git -C ~/Documents/code/skill/ui-skills pull
~/Documents/code/rule/sync-global-agent-standards.sh
```

## Skills 自进化

- codeskill 权威源：`~/Documents/code/skill/codeskill/`（含 `evolve-skills`）
- ui-skills：`~/Documents/code/skill/ui-skills/skills/`
- 运行时：`~/.claude/skills/` → 各 Agent symlink
- Git 镜像：`~/Documents/code/skill/global/`
- Meta skill：`evolve-skills`
- 规则：`global-skills-evolution.mdc`
- 用户纠正 / 重复踩坑 → 读 `evolve-skills` → 改对应权威源 → 跑同步脚本
