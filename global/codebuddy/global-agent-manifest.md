---
description: 跨 Agent 全局规范入口 — Cursor / Claude Code / Codex / Trae 路径与优先级
alwaysApply: true
---

# 跨 Agent 规范入口

## 规则路径（优先级：项目 > 全局）

| Agent | 全局规则 | 项目规则 |
|-------|----------|----------|
| **Cursor** | `~/.cursor/rules/global-*.mdc` | `<repo>/.cursor/rules/*.mdc`、`<repo>/AGENTS.md` |
| **Claude Code** | 读 `~/.cursor/rules/global-*.mdc` + User Rules | `<repo>/AGENTS.md`、`<repo>/.cursor/rules/` |
| **Codex** | `~/.codex/AGENTS.md`（指向下方） | `<repo>/AGENTS.md` |
| **Trae CN** | `~/.trae-cn/skills/` + 读 `~/.cursor/rules/` | `<repo>/AGENTS.md` |

## Skill 路径（canonical：`~/.claude/skills/`）

| Agent | 读取路径 |
|-------|----------|
| **Cursor** | `~/.claude/skills/<name>/SKILL.md` |
| **Claude Code** | `~/.claude/skills/<name>/SKILL.md` |
| **Codex** | `~/.agents/skills/<name>/SKILL.md` |
| **Trae CN** | `~/.trae-cn/skills/<name>/SKILL.md` |

安装/同步：运行 `~/.agents/sync-global-skills.sh`

## 本项目沉淀的规范 Skill

| Skill | 用途 |
|-------|------|
| `preview-first-sync` | 预览先展示、异步入库 |
| `shadcn-app-components` | 组件三层 + 模板 |
| `framer-motion-patterns` | lib/motion.ts 动效 |
| `nextjs-saas-feature-scaffold` | 新 feature 脚手架 |

## 全局规则清单

- `global-agent-workflow.mdc` — 工作流 + skill 路由
- `global-nextjs-saas-architecture.mdc` — 架构约束
- `global-security-baseline.mdc` — 安全基线
- `global-ui-conventions.mdc` — UI 交互
- `global-motion-conventions.mdc` — 动效约束
- `global-data-patterns.mdc` — 缓存模式指针
- `global-interaction-performance.mdc` — 交互性能（伪导航、DB 合并、乐观 UI）

## 会话启动

1. 遵循 `global-agent-workflow.mdc`
2. 读项目 `AGENTS.md` + `.cursor/rules/`
3. 按场景读对应 `SKILL.md`
