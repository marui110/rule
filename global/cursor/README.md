# 全局 Cursor 规则

跨项目 Agent 规范，不绑定任何单一仓库。

## 命名约定

| 层级 | 路径 | 命名 |
|------|------|------|
| 全局 | `~/.cursor/rules/` | `global-<主题>.mdc` |
| 项目 | `<repo>/.cursor/rules/` | `<职责>.mdc`（不用品牌名） |

## 全局规则清单

| 文件 | 作用 |
|------|------|
| `global-agent-workflow.mdc` | 工作流 + skill 路由 |
| `global-agent-manifest.mdc` | 跨 Agent 路径入口 |
| `global-skills-evolution.mdc` | Skills 自进化权威源与同步 |
| `global-codex-project-structure.mdc` | Codex / Agent 项目脚手架结构 |
| `global-nextjs-saas-architecture.mdc` | Next.js SaaS 架构 |
| `global-security-baseline.mdc` | 安全基线 |
| `global-ui-conventions.mdc` | UI 交互规范 |
| `global-motion-conventions.mdc` | 动效约束 |
| `global-data-patterns.mdc` | 预览优先缓存指针 |
| `global-interaction-performance.mdc` | 交互性能 |

## 全局 Skills

| 类型 | 路径 |
|------|------|
| **codeskill 权威源** | `~/Documents/code/skill/codeskill/`（含 `evolve-skills` 及 SaaS 沉淀 skill） |
| **运行时** | `~/.claude/skills/` → 各 Agent symlink |

| Skill | 用途 |
|-------|------|
| `evolve-skills` | 全局 skill 自进化 |
| `preview-first-sync` | 预览先展示、异步入库 |
| `shadcn-app-components` | 组件三层 + 模板 |
| `framer-motion-patterns` | lib/motion.ts 动效 |
| `nextjs-saas-feature-scaffold` | 新 feature 脚手架 |

同步至所有 Agent：

```bash
~/Documents/code/rule/sync-global-agent-standards.sh
```

| Agent | 规则 | Skills |
|-------|------|--------|
| Cursor | `~/.cursor/rules/global-*.mdc` | `~/.cursor/skills/`、`~/.claude/skills/` |
| Claude Code | 同上 | `~/.claude/skills/` |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/skills/` |

MCP 同步：`~/Documents/code/rule/sync-global-mcp.sh --import`（详见 `~/Documents/code/rule/mcp/README.md`）。

旧脚本 `~/.agents/sync-global-skills.sh` 已弃用，请用 `~/Documents/code/rule/sync-global-agent-standards.sh`。

优先级：**项目 `.cursor/rules/` > 全局 `global-*.mdc`**。

## User Rules 引导（若 global-*.mdc 未自动加载）

```
会话启动遵循 ~/.cursor/rules/global-agent-workflow.mdc 与 global-agent-manifest.mdc。
进入项目后读 <repo>/AGENTS.md 与 .cursor/rules/；本地优先于全局。
codeskill 改 ~/Documents/code/skill/codeskill/；其余全局 skill 改 ~/.claude/skills/；跑 sync-global-agent-standards.sh。
SaaS 实现读 preview-first-sync、shadcn-app-components、framer-motion-patterns、nextjs-saas-feature-scaffold。
```
