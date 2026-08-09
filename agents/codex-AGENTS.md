# Global Agent Standards (Codex)

规则：`~/.trae-cn/rules/global-*.md`（与 `~/.cursor/rules/global-*.mdc` 同步）  
Skills：`~/.codex/skills/`（symlink → `~/.claude/skills/`；另镜像 `~/.agents/skills/`、`~/.cursor/skills/`、`~/.trae-cn/skills/`）  
Git 全量备份：`~/Documents/code/skill/global/`  
场景路由：`~/Documents/code/skill/SKILL_ROUTER.md`  
全量目录：`~/Documents/code/skill/SKILLS_INDEX.md`

项目本地：`AGENTS.md`、`.cursor/rules/`、`.trae/rules/` 优先于全局。

同步：`~/Documents/code/rule/sync-global-agent-standards.sh`

## Skills 自进化

- codeskill 权威源：`~/Documents/code/skill/codeskill/`（含 `evolve-skills`）
- ui-skills：`~/Documents/code/skill/ui-skills/skills/`
- 运行时：`~/.claude/skills/` → 本机 `~/.codex/skills/`
- Meta：`evolve-skills`、`using-agent-skills`

## 自动触发（命中意图先读 SKILL.md）

| 意图信号 | 先加载 |
|----------|--------|
| 会话启动 / 不知用哪个 skill | `using-agent-skills` |
| 界面 / 去 AI 味 / 设计 | `ui-skills-root`（或 `npx ui-skills start`） |
| 修 bug | `systematic-debugging` → `test-driven-development` |
| 新功能 | `spec-driven-development` / `writing-plans` |
| Remotion | `remotion-best-practices` |
| GSAP | `gsap-core` |
| 合入前审查 | `code-review-and-quality` |
| 写回 skill | `evolve-skills` |
| caveman | `caveman` |
| Vercel 部署 | `deploy-to-vercel` |
| grilling | `grilling` |

细则与完整场景表：`~/Documents/code/skill/SKILL_ROUTER.md`。  
读 skill：`~/.codex/skills/<name>/SKILL.md`。

**同主题优先**：`test-driven-development`（非短 `tdd`）；`design-taste-frontend`（非 `-v1`）；UI 先 ui-skills。

## Codex 项目脚手架

新建 / 初始化 Codex 类项目时遵循 `global-codex-project-structure`（`~/.cursor/rules/global-codex-project-structure.mdc`）：

```
<project>/
├── README.md, CODEX.md, .gitignore, .env.example
├── codex.config.json, package.json
├── scripts/          # 运维：run / init / deploy
├── commands/         # 自定义命令 .md
├── skills/<name>/skill.md
├── agents/*.md       # 专职 Agent
├── memory/           # rules.md, decisions.md, context.json
└── output/           # reports/, charts/, logs/（生成物）
```

职责分离：运维 → `scripts/`；命令 → `commands/`；能力 → `skills/`；角色 → `agents/`；治理 → `memory/`；产物 → `output/`。勿把生成物散落在源码树。
