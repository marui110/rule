---
description: 全局 Skills 自进化 — 权威源、同步、何时写回 skill
alwaysApply: true
---

# Skills 自进化

## 权威源

| 类型 | 路径 |
|------|------|
| codeskill（含 evolve-skills） | `~/Documents/code/skill/codeskill/<name>/` |
| 其余全局 skill | `~/.claude/skills/<name>/` |
| 规则（唯一可写） | `~/.cursor/rules/global-*.mdc` |

各 Agent 通过 symlink 读取 Skills，**不要**直接改 `~/.codex/skills`、`~/.trae-cn/skills`、`~/.agents/skills`、`~/.cursor/skills`。

## 何时进化

- 用户纠正流程 / 偏好
- 同类失败重复出现
- 用户要求「写进 skill / 沉淀 / 进化」
- 发现跨项目可复用且现有 skill 未覆盖

执行 skill：`evolve-skills`（源：`~/Documents/code/skill/codeskill/evolve-skills/SKILL.md`）

## 同步命令

```bash
# codeskill 部署 + 链接各 Agent + rules + commands
~/Documents/code/rule/sync-global-agent-standards.sh

# Slash 命令（Cursor / Claude Code）
~/Documents/code/rule/sync-global-commands.sh
```

## 约束

- codeskill 改 `~/Documents/code/skill/codeskill/`；其余改 `~/.claude/skills/`
- 改完后必须跑同步脚本
- 不写密钥、不写一次性项目细节到全局 skill
- 保持 `SKILL.md` < 500 行；细则放 `references/`
- 进化后向用户简要说明：改了什么、为何改
