---
description: 全局 Agent 工作流 — skill 路由、Phase A/B/C/G 开发治理流程（跨项目通用）
alwaysApply: true
---

# 全局 Agent 工作流

你是主协调 Agent。按用户任务与验收标准执行；非平凡改动先走 spec / plan，再实现与验证。

## 项目上下文优先

进入任何仓库后，先扫描并遵循**项目本地**约束（优先级高于本规则）：

- 根目录或子目录的 `AGENTS.md`、`CLAUDE.md`、`README.md`
- `.cursor/rules/*.mdc`、`.cursorrules`（遗留）
- `package.json` / `Makefile` / `pyproject.toml` 等中的 scripts 与工具链
- 框架官方文档（如 `node_modules/<pkg>/dist/docs/`、项目内 `docs/`）

**不写细则**：各 skill 的完整步骤以对应 `SKILL.md` 为准；本文只写**何时用、与谁配合**。

## 技能来源

| 来源 | 路径 | 说明 |
|------|------|------|
| 本机全局 | `~/.claude/skills/` | Cursor / Claude Code 主路径 |
| 本机全局 | `~/.agents/skills/` | 同步安装；`npx skills add <owner/repo> -g -y -a cursor` |
| Cursor 内置 | `~/.cursor/skills-cursor/` | 系统管理；**禁止**手动写入 |

完整场景表：`~/Documents/code/skill/SKILL_ROUTER.md`。全量目录：`~/Documents/code/skill/SKILLS_INDEX.md`。

**meta**：`using-agent-skills`、`evolve-skills`、`brainstorming`、`writing-plans`、`executing-plans`、`subagent-driven-development`、`dispatching-parallel-agents`、`test-driven-development`、`systematic-debugging`、`verification-before-completion`、`using-git-worktrees`、`requesting-code-review`、`receiving-code-review`、`finishing-a-development-branch`、`writing-skills`。

**工程生命周期**：`interview-me`、`idea-refine`、`spec-driven-development`、`planning-and-task-breakdown`、`incremental-implementation`、`context-engineering`、`source-driven-development`、`doubt-driven-development`、`debugging-and-error-recovery`、`diagnosing-bugs`、`frontend-ui-engineering`、`frontend-design`、`api-and-interface-design`、`code-review-and-quality`、`code-review-skill`、`code-review`、`code-simplification`、`security-and-hardening`、`performance-optimization`、`git-workflow-and-versioning`、`ci-cd-and-automation`、`deprecation-and-migration`、`documentation-and-adrs`、`observability-and-instrumentation`、`shipping-and-launch`、`codebase-design`、`domain-modeling`、`improve-codebase-architecture`、`deploy-to-vercel`。

**视觉 / 设计**：`ui-skills-root`（ibelick/ui-skills 路由）、`baseline-ui`、`improve-ui`、`create-design-md`、`fixing-accessibility`、`fixing-metadata`、`fixing-motion-performance`、`design-taste-frontend`、`design-taste-frontend-v1`、`high-end-visual-design`、`redesign-existing-projects`、`minimalist-ui`、`industrial-brutalist-ui`、`gpt-taste`、`brandkit`、`imagegen-frontend-web`、`imagegen-frontend-mobile`、`image-to-code`、`stitch-design-taste`、`impeccable`、`theme-factory`、`full-output-enforcement`、`apple-design`、`animate`、`improve-animations`、`find-animation-opportunities`。

**GSAP**：`gsap-core`、`gsap-frameworks`、`gsap-performance`、`gsap-plugins`、`gsap-react`、`gsap-scrolltrigger`、`gsap-timeline`、`gsap-utils`。

**Remotion**：`remotion-best-practices`、`remotion-create`、`remotion-docs`、`remotion-studio`、`remotion-render`、`remotion-captions`、`remotion-multimedia`、`remotion-maps`、`remotion-markup`、`remotion-interactivity`、`remotion-saas`、`remotion-upgrade`。

**Caveman**：`caveman`、`caveman-help`、`caveman-commit`、`caveman-review`、`caveman-stats`、`caveman-compress`、`cavecrew`。

**Matt / grill**：`grilling`、`grill-me`、`grill-with-docs`、`implement`、`handoff`、`ask-matt`、`teach`、`to-spec`、`to-tickets`、`triage`、`wayfinder`。

**测试 / 工具 / 极简**：`playwright-skill`、`webapp-testing`、`browser-testing-with-devtools`、`web-artifacts-builder`、`ponytail`、`ponytail-review`、`ponytail-audit`、`ponytail-debt`、`ponytail-gain`、`ponytail-help`、`apple-notes`、`pptx`。

**SaaS 沉淀（全局，见 `global-agent-manifest`）**：`preview-first-sync`、`shadcn-app-components`、`framer-motion-patterns`、`nextjs-saas-feature-scaffold`、`saas-tenant-membership`。

**Cursor 内置**：`review-bugbot`、`review-security`、`babysit`、`split-to-prs`、`canvas`、`create-rule`、`create-skill`、`create-hook`、`create-subagent`、`automate`、`loop`、`shell`、`sdk`、`statusline`、`update-cursor-settings`、`update-cli-config`、`onboard`、`migrate-to-skills`、`review`。

## 技能选用（按场景）

| 场景 | 技能 |
|------|------|
| 会话启动、查找 skill | `using-agent-skills` → `SKILL_ROUTER.md` |
| 纠正 / 踩坑写回 skill | `evolve-skills` → 跑 `sync-global-agent-standards.sh` |
| 需求尚不清晰 | `interview-me` |
| 概念发散 / 收敛 | `idea-refine` |
| 新功能 / 大改前探索 | `brainstorming` |
| 非平凡功能写 spec | `spec-driven-development` |
| 多步骤写实现计划 | `writing-plans` |
| 独立会话执行计划 | `executing-plans` |
| 任务分解 | `planning-and-task-breakdown` |
| 派发 implementer | `subagent-driven-development` |
| 2+ 独立任务并行 | `dispatching-parallel-agents` |
| 薄切片实现 | `incremental-implementation` |
| 加载 / 裁剪上下文 | `context-engineering` |
| 对照官方文档实现 | `source-driven-development` |
| 高风险决策对抗审查 | `doubt-driven-development` |
| 行为变更 / 修 bug | `test-driven-development`（优先于短版 `tdd`） |
| bug / 测试失败先调查 | `systematic-debugging` 或 `debugging-and-error-recovery` |
| 声称完成 / 提交 / PR 前验证 | `verification-before-completion` |
| 隔离分支开发 | `using-git-worktrees` |
| 合并 / PR 决策 | `finishing-a-development-branch` |
| 请求 / 处理代码审查 | `requesting-code-review` / `receiving-code-review` |
| 五轴质量审查（合入前） | `code-review-and-quality` |
| since-point 双轴审查 | `code-review` |
| PR / 多语言细则审查 | `code-review-skill` |
| 完成后精简去重 | `code-simplification` |
| 过度工程扫描 | `ponytail-review` / `ponytail-audit` |
| 刻意最简实现 | `ponytail` |
| 安全审查 | `security-and-hardening` 或 `review-security` |
| Bug 审查（子 Agent） | `review-bugbot` |
| 性能问题 | `performance-optimization` |
| 架构 / 领域建模 | `codebase-design` / `domain-modeling` |
| UI 任务入口（必做） | `ui-skills-root` 或 `npx ui-skills start`（见 `global-ui-skills`） |
| 新建 UI | 先 ui-skills 路由，再 `design-taste-frontend`（非 `-v1`）/ `frontend-design` |
| 生产级 UI | 先 ui-skills 路由，再 `frontend-ui-engineering` |
| 快速去 AI 味 / 间距 | `baseline-ui` |
| 审计现有界面 | `improve-ui` |
| 现有页面升级 | `redesign-existing-projects` → `impeccable`（可叠加 ui-skills） |
| GSAP / ScrollTrigger | `gsap-core` → `gsap-scrolltrigger` / `gsap-react` |
| Remotion / 视频合成 | `remotion-best-practices` → `remotion-create` 等专项 |
| Caveman 口语 / 压缩输出 | `caveman` / `caveman-compress` |
| Grill 压力测试方案 | `grilling` |
| Matt implement / handoff | `implement` / `handoff` / `ask-matt` |
| Apple Notes | `apple-notes` |
| 部署 Vercel | `deploy-to-vercel` |
| 浏览器冒烟 | `playwright-skill` / `webapp-testing` |
| API 设计 | `api-and-interface-design` |
| 提交 / CI / 上线 | `git-workflow-and-versioning` / `ci-cd-and-automation` / `shipping-and-launch` |
| PR 保活 / 修 CI | `babysit` |
| 拆分 PR | `split-to-prs` |
| 预览先展示 + 异步入库 | `preview-first-sync` |
| 组件模板 / 三层结构 | `shadcn-app-components` |
| 动效实现 | `framer-motion-patterns` |
| 新 feature 脚手架 | `nextjs-saas-feature-scaffold` |

**选用原则**：

1. 命中意图 → **自动**读对应 `SKILL.md`（先 `SKILL_ROUTER.md` / `using-agent-skills`）。
2. 同一轮**最多一个主流程 skill**（Phase A/B/C 或 Phase G）；审查类可末尾叠加。
3. 全局 skill 读 `~/.claude/skills/<name>/SKILL.md`（或各端 symlink）。
4. Cursor 内置读 `~/.cursor/skills-cursor/<name>/SKILL.md`。
5. **Process skills 优先**：`brainstorming` / `systematic-debugging` 定方法，再叠加实现类。

## 启动（每次会话）

0. **按意图自动加载 skill**（不必等用户点名）；路由见 `~/Documents/code/skill/SKILL_ROUTER.md`。
1. 场景不明时读 `using-agent-skills`。
2. 扫描项目本地 `AGENTS.md` / `CLAUDE.md` / `.cursor/rules/` / README。
3. 明确任务、验收标准与范围；有歧义时 `interview-me` 或一次性向用户确认。
4. **意图含设计/UI**：按 `global-ui-skills` **自动**跑 `npx ui-skills start`（或读 `ui-skills-root`），无需用户点名。
5. 判断类型：**新功能 / 修 bug** → Phase A/B/C；**架构整理 / 重构** → Phase G。
6. 非平凡任务：先 `spec-driven-development` 或 `writing-plans`。

## Phase A — 规划

| 步骤 | 技能 | 说明 |
|------|------|------|
| A0 意图探索 | `brainstorming` / `interview-me` | 新功能、UI、行为变更前探索 |
| A1 写 spec | `spec-driven-development` | 非平凡任务写验收标准 |
| A2 任务分解 | `planning-and-task-breakdown` | 可验收子任务 |
| A3 写计划 | `writing-plans` | 跨模块任务；简单改动可跳过 |
| A4 标注 TDD | — | 标哪些子任务必须 TDD |
| A5 输出 Todo | — | 结构化清单 |

## Phase B — 实现

1. `subagent-driven-development`（2+ 独立子任务用 `dispatching-parallel-agents`）。
2. `incremental-implementation`：每次交付可验证的一小步。
3. `test-driven-development`：失败测试 → 最小实现 → 全绿 → 重构。
4. UI 子任务：**先** `ui-skills-root` / `npx ui-skills start`，再按需叠加 `frontend-ui-engineering` / `design-taste-frontend` / `redesign-existing-projects` / `baseline-ui`。
5. 修 bug：先 `systematic-debugging`，再 TDD。
6. GREEN 后 `code-simplification`；过度抽象叠加 `ponytail-review`。
7. 非平凡决策 `doubt-driven-development`。
8. Task review：`code-review-skill`。

## Phase C — 审查

1. 对照 spec / 验收标准核对。
2. `code-review-and-quality`；零 Critical 未解决。
3. UI 变更对照项目设计 token / 样式规范审计。
4. `verification-before-completion`：跑项目标准验证命令（从 `package.json` scripts、Makefile、CI 配置等推断）。
5. 只输出审查报告，不自动应用修复（除非用户明确要求）。
6. 用户显式要求时 → `review-bugbot` / `review-security`。
7. 合并前 → `requesting-code-review` → `receiving-code-review` → `finishing-a-development-branch`。

## Phase G — 代码治理

| 步骤 | 技能 | 产出 |
|------|------|------|
| G1 诊断 | `code-review-and-quality` / `ponytail-audit` | 摩擦点 / 可删项 |
| G2 计划 | `planning-and-task-breakdown` + `writing-plans` | 小步提交顺序 |
| G3 执行 | `code-simplification` + `ponytail` | 抽取 helper、删死代码 |
| G4 验收 | TDD + `verification-before-completion` + `code-review-and-quality` | 验证全绿；零 Critical |

**治理约束（通用）**：遵循项目既有分层；删代码前确认无引用；只改任务范围内文件。

## 交付物

任务与验收对照、文件清单、验证结果、审查摘要、阻塞项。

## 快速启动

- **功能开发**：`A0 → A1 → A2 → B（TDD + 薄切片）→ C → 验证通过再交付`
- **代码治理**：`G1 → G2（如需）→ G3 → G4 → 行为不变`
- **极简模式**：`/ponytail` + 完成后 `ponytail-review`
