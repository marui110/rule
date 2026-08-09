---
description: 全局 Skills 自进化 — 权威源、同步、何时写回 skill
alwaysApply: true
---

# Skills 自进化

## 权威源

| 类型 | 路径 |
|------|------|
| codeskill（含 evolve-skills） | `~/Documents/code/skill/codeskill/<name>/` |
| ui-skills | `~/Documents/code/skill/ui-skills/skills/<name>/` |
| 其余全局 skill | `~/.claude/skills/<name>/` |
| Git 全量镜像（只读备份） | `~/Documents/code/skill/global/<name>/` |
| 场景路由 / 目录 | `~/Documents/code/skill/SKILL_ROUTER.md`、`SKILLS_INDEX.md` |
| Agent 入口模板 | `~/Documents/code/rule/agents/` → Claude `CLAUDE.md` / Codex·Trae `AGENTS.md` |
| 规则（唯一可写） | `~/.cursor/rules/global-*.mdc` |

各 Agent 通过 symlink 读取 Skills，**不要**直接改 `~/.codex/skills`、`~/.trae-cn/skills`、`~/.agents/skills`、`~/.cursor/skills`。  
**不要**把 `global/` 当作主编辑源（下次同步会覆盖）。

## 何时进化

- 用户纠正流程 / 偏好
- 同类失败重复出现
- 用户要求「写进 skill / 沉淀 / 进化」
- 发现跨项目可复用且现有 skill 未覆盖

执行 skill：`evolve-skills`（源：`~/Documents/code/skill/codeskill/evolve-skills/SKILL.md`）

## 同步命令

```bash
# codeskill + ui-skills → runtime → 四端 symlink → global/ 镜像 + rules + agents 入口
~/Documents/code/rule/sync-global-agent-standards.sh

# Slash 命令（Cursor / Claude Code）
~/Documents/code/rule/sync-global-commands.sh
```

## 约束

- codeskill 改 `~/Documents/code/skill/codeskill/`；ui-skills 改 `~/Documents/code/skill/ui-skills/skills/`；其余改 `~/.claude/skills/`
- 改完后必须跑同步脚本（会刷新 `global/` 镜像与各端入口）
- 不写密钥、不写一次性项目细节到全局 skill
- 保持 `SKILL.md` < 500 行；细则放 `references/`
- 进化后向用户简要说明：改了什么、为何改
- 若场景路由变化：同步更新 `SKILL_ROUTER.md` / `global-agent-workflow.mdc`
