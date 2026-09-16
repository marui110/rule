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
3. 再读 `SKILL_ROUTER.md` 命中的 **1 个**主 skill（同一轮最多一个 L1）
4. 细则以 `SKILL.md` 为准；完整表与自动调用协议见 `SKILL_ROUTER.md`

## 自动触发表（高频）

| 意图信号 | 先加载 |
|----------|--------|
| 界面 / 页面 / 组件 / 去 AI 味 / 设计稿 | `ui-skills-root` → `baseline-ui` / `improve-ui` / `design-taste-frontend` |
| 修 bug / 测试红 | `systematic-debugging` → `test-driven-development` |
| 新功能 / 大改 | `brainstorming` 或 `spec-driven-development` → `writing-plans` |
| 合入前审查 | `code-review-and-quality` |
| 写回 / 进化 skill | `evolve-skills` |
| 极简口语 / caveman | `caveman`（`caveman-help` / `caveman-compress` / `cavecrew`） |
| 部署 Vercel | `deploy-to-vercel` |
| 压力测试方案 | `grilling` |
| Matt 流程 implement/handoff | `implement` / `handoff` / `ask-matt` |

**同主题优先**：TDD → `test-driven-development`；设计默认 `design-taste-frontend`（非 `-v1`）；UI 先 ui-skills 再叠其他视觉 skill。

项目本地 `AGENTS.md` / `.cursor/rules/` 优先于本文件。

## 个人知识库（agent_KB）

@/Users/marui/Documents/code/agent_KB/AGENTS.md

所有会话均挂载：`/Users/marui/Documents/code/agent_KB`（协议：`AGENTS.md` 为唯一行为源）。

- 默认可写仅 `inbox/`；正式区需用户确认晋升
- 查询先读 `_meta/index.md`；有价值结论回写 `inbox/`
- 体检：用户说「体检 wiki」→ `playbooks/wiki-lint`
- 业务仓指针：`.cursor/rules/agent_KB-pointer.mdc`
- **在 `~/Documents/code/` 新建或打开未挂接仓库时**：立即执行  
  `~/Documents/code/agent_KB/scripts/hook-project.sh <绝对路径>`  
  （自动创建完整 `AGENTS.md`，不必先问）
- 工具备份 / 手动安装：`~/Documents/code/rule/agent_KB/README.md`
- 全量同步：`~/Documents/code/rule/sync-global-agent-standards.sh`
