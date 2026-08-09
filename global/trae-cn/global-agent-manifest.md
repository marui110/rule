---
description: 跨 Agent 全局规范入口 — Cursor / Claude Code / Codex / Trae 路径与优先级
alwaysApply: true
---

# 跨 Agent 规范入口

## 规则路径（优先级：项目 > 全局）

| Agent | 全局规则 | 项目规则 |
|-------|----------|----------|
| **Cursor** | `~/.cursor/rules/global-*.mdc` | `<repo>/.cursor/rules/*.mdc`、`<repo>/AGENTS.md` |
| **Claude Code** | `~/.claude/CLAUDE.md` + 读 `~/.cursor/rules/global-*.mdc` | `<repo>/AGENTS.md`、`<repo>/CLAUDE.md`、`<repo>/.cursor/rules/` |
| **Codex** | `~/.codex/AGENTS.md` | `<repo>/AGENTS.md` |
| **Trae CN** | `~/.trae-cn/rules/global-*.md` + `~/.trae-cn/AGENTS.md` | `<repo>/AGENTS.md` |

入口模板权威源：`~/Documents/code/rule/agents/`（`claude-CLAUDE.md` / `codex-AGENTS.md` / `trae-AGENTS.md`），由同步脚本部署。

## Skill 路径

| 角色 | 路径 |
|------|------|
| **codeskill 权威源** | `~/Documents/code/skill/codeskill/<name>/` |
| **ui-skills 权威源** | `~/Documents/code/skill/ui-skills/skills/<name>/` |
| **运行时 canonical** | `~/.claude/skills/<name>/` |
| **Git 全量镜像** | `~/Documents/code/skill/global/<name>/` |
| **场景路由** | `~/Documents/code/skill/SKILL_ROUTER.md` |
| **全量目录** | `~/Documents/code/skill/SKILLS_INDEX.md` |

| Agent | 读取路径 |
|-------|----------|
| **Cursor** | `~/.cursor/skills/`（symlink） |
| **Claude Code** | `~/.claude/skills/<name>/SKILL.md` |
| **Codex** | `~/.codex/skills/`（symlink） |
| **Trae CN** | `~/.trae-cn/skills/<name>/SKILL.md` |
| **Agents 镜像** | `~/.agents/skills/`（symlink） |

安装/同步：

```bash
~/Documents/code/rule/sync-global-agent-standards.sh   # codeskill + ui-skills + skills + global镜像 + rules + agents入口
~/Documents/code/rule/sync-global-commands.sh          # slash 命令
```

## 本项目沉淀的规范 Skill

| Skill | 用途 |
|-------|------|
| `preview-first-sync` | 预览先展示、异步入库 |
| `shadcn-app-components` | 组件三层 + 模板 |
| `framer-motion-patterns` | lib/motion.ts 动效 |
| `nextjs-saas-feature-scaffold` | 新 feature 脚手架 |
| `saas-tenant-membership` | 租户成员关系 |
| `evolve-skills` | 全局 skill 自进化（纠正 / 踩坑写回） |

## UI Skills（ibelick/ui-skills）

| Skill | 用途 |
|-------|------|
| `ui-skills-root` | UI 任务路由入口（或 `npx ui-skills start`） |
| `baseline-ui` | 快速去 AI 味 / 间距层级 |
| `improve-ui` | 审计界面并写实现计划 |
| `create-design-md` | 生成 DESIGN.md |
| `fixing-accessibility` / `fixing-metadata` / `fixing-motion-performance` | 专项修复 |

本机备份：`~/Documents/code/skill/ui-skills/`。细则：`global-ui-skills.mdc`。

## 全局规则清单

- `global-skills-evolution.mdc` — Skills 自进化权威源与同步
- `global-agent-workflow.mdc` — 工作流 + skill 路由（自动触发）
- `global-codex-project-structure.mdc` — Codex / Agent 项目脚手架结构
- `global-nextjs-saas-architecture.mdc` — 架构约束
- `global-security-baseline.mdc` — 安全基线
- `global-ui-conventions.mdc` — UI 交互
- `global-ui-skills.mdc` — ibelick/ui-skills 路由（code 下全项目）
- `global-motion-conventions.mdc` — 动效约束
- `global-data-patterns.mdc` — 缓存模式指针
- `global-interaction-performance.mdc` — 交互性能（伪导航、DB 合并、乐观 UI）

## 会话启动

0. **按用户意图自动读对应 `SKILL.md`**（见 `SKILL_ROUTER.md` / `global-agent-workflow`），不必等用户点名
1. 遵循 `global-agent-workflow.mdc`
2. 读项目 `AGENTS.md` / `CLAUDE.md` + `.cursor/rules/`
3. **识别到设计意图时自动**走 `global-ui-skills`（`npx ui-skills start` / `ui-skills-root`）
4. 按场景读对应 `SKILL.md`
