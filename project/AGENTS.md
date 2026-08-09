# Agent 指令

| 层级 | 路径 |
|------|------|
| 全局（跨项目） | `~/.cursor/rules/global-*.mdc`（见 `global-agent-manifest.mdc`） |
| 全局 Skills | `preview-first-sync`、`shadcn-app-components`、`framer-motion-patterns`、`nextjs-saas-feature-scaffold` |
| UI Skills（ibelick） | `ui-skills-root` / `npx ui-skills start`（见 `global-ui-skills`） |
| 本项目 | `.cursor/rules/*.mdc` |

本地规则优先于全局。同步：`~/Documents/code/rule/sync-global-agent-standards.sh`

## UI 任务

新建 / 升级界面前先 `npx ui-skills start`（或 `ui-skills-root`），再叠加本仓 design-system。
