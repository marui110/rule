@RTK.md

# Claude Code — Skills 自动触发

## 路径

| 角色 | 路径 |
|------|------|
| Runtime skills | `~/.claude/skills/<name>/SKILL.md` |
| 场景路由表 | `~/Documents/code/skill/SKILL_ROUTER.md` |
| 全量目录 | `~/Documents/code/skill/SKILLS_INDEX.md` |
| Git 镜像 | `~/Documents/code/skill/global/` |
| codeskill 源 | `~/Documents/code/skill/codeskill/` |
| ui-skills 源 | `~/Documents/code/skill/ui-skills/skills/` |

同步：`~/Documents/code/rule/sync-global-agent-standards.sh`

## 会话启动（自动）

命中意图时**本轮先读**对应 `SKILL.md`，不必等用户点名 skill：

1. 场景不明 → 读 `using-agent-skills`
2. 设计 / UI → `ui-skills-root`（或 `npx ui-skills start`）
3. 再读场景表命中的主 skill（同一轮最多一个主流程 skill）
4. 细则以 `SKILL.md` 为准；完整表见 `SKILL_ROUTER.md`

## 自动触发表（高频）

| 意图信号 | 先加载 |
|----------|--------|
| 界面 / 页面 / 组件 / 去 AI 味 / 设计稿 | `ui-skills-root` → `baseline-ui` / `improve-ui` / `design-taste-frontend` |
| 修 bug / 测试红 | `systematic-debugging` → `test-driven-development` |
| 新功能 / 大改 | `brainstorming` 或 `spec-driven-development` → `writing-plans` |
| Remotion / 视频合成 | `remotion-best-practices` → `remotion-create` / 专项 |
| GSAP / ScrollTrigger | `gsap-core` → `gsap-scrolltrigger` / `gsap-react` |
| 合入前审查 | `code-review-and-quality` |
| since-point 双轴审查 | `code-review` |
| 写回 / 进化 skill | `evolve-skills` |
| 极简口语 / caveman | `caveman`（help/review/commit 见套件） |
| Apple Notes | `apple-notes` |
| 部署 Vercel | `deploy-to-vercel` |
| 压力测试方案 | `grilling` |
| Matt 流程 implement/handoff | `implement` / `handoff` / `ask-matt` |

**同主题优先**：TDD → `test-driven-development`；设计默认 `design-taste-frontend`（非 `-v1`）；UI 先 ui-skills 再叠其他视觉 skill。

项目本地 `AGENTS.md` / `.cursor/rules/` 优先于本文件。
