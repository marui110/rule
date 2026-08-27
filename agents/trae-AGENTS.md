# Global Agent Standards (Trae Code CN)

> 参考文档，非部署文件。Trae Code CN 无 home 目录级全局入口文件；项目级 `AGENTS.md`/`CLAUDE.md` 需在设置中开启 toggle 才生效。

规则：`~/.trae-cn/user_rules/global-*.md`（由同步脚本从 `~/.cursor/rules/global-*.mdc` 拷贝）  
Skills：`~/.trae-cn/skills/`（symlink → `~/.claude/skills/`；另镜像 `~/.agents/skills/`、`~/.cursor/skills/`、`~/.codex/skills/`）  
Git 全量备份：`~/Documents/code/skill/global/`  
场景路由：`~/Documents/code/skill/SKILL_ROUTER.md`  
全量目录：`~/Documents/code/skill/SKILLS_INDEX.md`

项目本地：`AGENTS.md`、`.trae/rules/` 优先于全局。

同步：`~/Documents/code/rule/sync-global-agent-standards.sh`

## Trae Code CN 路径

| 类型 | 路径 |
|------|------|
| 全局规则 | `~/.trae-cn/user_rules/global-*.md` |
| 全局技能 | `~/.trae-cn/skills/<name>/SKILL.md`（symlink） |
| 项目规则 | `<repo>/.trae/rules/*.md`（递归 ≤3 层，frontmatter `alwaysApply`/`description`/`globs`/`scene`） |
| 项目技能 | `<repo>/.trae/skills/<name>/SKILL.md` |
| 内置技能 | `~/.trae-cn/builtin_skills/`、`~/.trae-cn/builtin/global/skills/`（与全局技能分开，无冲突） |

## AGENTS.md / CLAUDE.md toggle

Trae 兼容项目根目录的 `AGENTS.md`、`CLAUDE.md`、`CLAUDE.local.md`，但**默认关闭**。需在设置中开启：

设置 → 规则 → 导入设置 → 打开「将 AGENTS.md 包含在上下文中」和「将 CLAUDE.md 包含在上下文中」开关。

开启后智能体读取项目根目录的这些文件并加入上下文。亦支持 `.agents/skills/` 目录（需开启「启用 .agents 技能目录」）。

## Skills 自进化

- codeskill 权威源：`~/Documents/code/skill/codeskill/`（含 `evolve-skills`）
- ui-skills：`~/Documents/code/skill/ui-skills/skills/`
- 运行时：`~/.claude/skills/` → 本端 `~/.trae-cn/skills/`
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
读 skill：`~/.trae-cn/skills/<name>/SKILL.md`。

**同主题优先**：`test-driven-development`（非短 `tdd`）；`design-taste-frontend`（非 `-v1`）；UI 先 ui-skills。

## 内置技能命名冲突注意

Trae 内置技能（`TRAE-debugger`、`TRAE-code-review`、`dynamic-ui`、`skill-creator` 等）与全局技能分属不同目录，当前无重名。若未来全局技能与内置技能重名，优先级未文档化，需留意。项目级 `.trae/skills/` 在重名时优先于 `.agents/skills/`。

## 个人知识库（agent_KB）

@/Users/marui/Documents/code/agent_KB/AGENTS.md

所有会话均挂载：`/Users/marui/Documents/code/agent_KB`（协议：`AGENTS.md`）。  
默认可写仅 `inbox/`；正式区需用户确认。业务仓指针：`.cursor/rules/agent_KB-pointer.mdc`。
