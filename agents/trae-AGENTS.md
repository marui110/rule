# Trae CN — 全局 Skills 入口

规则：`~/.trae-cn/rules/global-*.md`（由 `~/.cursor/rules/global-*.mdc` 同步）  
Skills：`~/.trae-cn/skills/<name>/SKILL.md`（symlink → `~/.claude/skills/`）  
路由表：`~/Documents/code/skill/SKILL_ROUTER.md`  
全量目录：`~/Documents/code/skill/SKILLS_INDEX.md`  
Git 镜像：`~/Documents/code/skill/global/`

同步：`~/Documents/code/rule/sync-global-agent-standards.sh`

## 自动触发

命中意图时本轮先读对应 skill（不必等用户点名）：

| 意图 | Skill |
|------|--------|
| 不知用哪个 | `using-agent-skills` |
| UI / 设计 | `ui-skills-root` |
| Bug | `systematic-debugging` |
| 新功能 | `spec-driven-development` / `writing-plans` |
| Remotion | `remotion-best-practices` |
| GSAP | `gsap-core` |
| 审查合入 | `code-review-and-quality` |
| 写回 skill | `evolve-skills` |
| caveman | `caveman` |

项目本地 `AGENTS.md` / 规则优先。细则见 `SKILL_ROUTER.md` 与 Cursor 侧 `global-agent-workflow`。
