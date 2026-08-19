# Copilot Instructions — Global Agent Standards

> 本文件聚合 Cursor / Claude Code / Codex 共享的全局规则、Skills 路由与 agent_KB 协议，供 GitHub Copilot (VSCode) 使用。
> 权威源：`~/.cursor/rules/global-*.mdc`、`~/Documents/code/skill/SKILL_ROUTER.md`、`~/Documents/code/agent_KB/AGENTS.md`

## 资源路径

| 资源 | 路径 | 说明 |
|------|------|------|
| 全局规则 | `~/.vscode/rules/` → `~/.cursor/rules/global-*.mdc` | 12 个 `.mdc` 规则文件 |
| Skills 目录 | `~/.vscode/skills/` → `~/.claude/skills/` | 150+ skills，每个含 `SKILL.md` |
| 场景路由 | `~/Documents/code/skill/SKILL_ROUTER.md` | 意图 → Skill 映射表 |
| 全量目录 | `~/Documents/code/skill/SKILLS_INDEX.md` | 所有 skill 索引 |
| 知识库 | `~/.vscode/agent_KB/` → `~/Documents/code/agent_KB/` | 协议见 `AGENTS.md` |

## 全局规则摘要

### Agent 工作流

- **项目本地规则优先**于全局：先扫 `AGENTS.md`、`CLAUDE.md`、`.cursor/rules/`、`README.md`、`package.json` scripts。
- 非平凡改动先 spec / plan，再实现与验证。
- **Phase A（规划）**：意图探索 → spec → 任务分解 → 计划 → Todo
- **Phase B（实现）**：TDD（失败测试 → 最小实现 → 全绿 → 重构）+ 薄切片交付；UI 先走 ui-skills 路由
- **Phase C（审查）**：对照验收标准 → code-review-and-quality → verification-before-completion
- **Phase G（治理）**：诊断 → 计划 → 简化/删死代码 → 验证（行为不变）

### Next.js SaaS 架构

- Server Components 优先；Server Actions 优先于 API 路由（Webhook/Cron 除外）
- 纯函数进 `lib/`；组件三层：`components/ui/` → `components/shared/` → `components/{domain}/`
- Server Action 铁律：`"use server"` 顶行、禁止接收 `userId`（从 session 派生）、第一行鉴权、Zod 校验、DB 查询带 `userId`、变更后 revalidate
- 个性化页面 `force-dynamic`；禁止缓存含用户数据的 RSC payload

### 安全基线

- 所有受保护路由在 middleware/proxy 层拦截
- DB 启用 RLS；应用层查询仍带 `userId`（双保险）
- 所有外部输入经 Zod 校验
- 高成本操作按 `userId` + 类型限流；限流状态存 DB/Redis
- AI 配额：成功后再扣；生成失败不写 usage_tracking
- 密钥走 env / 密钥管理服务，不进代码

### 交互性能

- 同页 UI 状态（Tab/日期/分页/筛选）用客户端 `setState` + `history.replaceState`，**禁止** `router.push` 整页导航
- 写操作用乐观 UI → Action 持久化 → 失败回滚
- 多次 DB 读合并为单次查询（`Promise.all` 或 CTE）
- 鉴权中间件用本地 session 快路径；仅 token 临期时远程刷新

### UI 交互规范

- shadcn + CSS 变量（`:root` / `.dark`）；Tailwind 通过 `@theme inline` 映射
- 语义 token：`background`、`foreground`、`muted`、`accent`、`destructive`、`border`、`ring`
- `accent` = 品牌主色；`destructive` = 独立红色，不混用
- 菜单/下拉 hover 用 `muted` 不用 `accent`
- 排版统一命名：`ui-text-title` / `ui-text-section` / `ui-text-body` / `ui-text-caption`
- 交互元素有可见 focus ring；图标按钮带 `aria-label`；支持 `prefers-reduced-motion`

### 动效约束

| 场景 | 用 |
|------|-----|
| 按钮 hover/active | CSS only（不用 scale/brightness 动画） |
| 卡片 hover lift | CSS `transition` + `translateY` + `box-shadow` |
| 列表/页面入场 | framer-motion stagger |
| 数字计数 | framer-motion `useSpring` |
| 布局宽度/侧边栏 | framer-motion `layout` |

- 所有 motion 组件检查 `useReducedMotion()`
- `globals.css` 加 `@media (prefers-reduced-motion: reduce)` 降级
- duration/ease/variants 集中在 `lib/motion.ts`

### 数据展示模式（Preview-First）

- AI 生成或高延迟内容：`generate → setPreviewCache → return to client → void syncToDb → delete preview`
- 客户端：`sessionStorage + setState()` 立即渲染；`syncState: cached → syncing → synced | failed`
- 不用于金融/订单等强一致写入

### Codex 项目脚手架

```
<project>/
├── README.md, CODEX.md, .gitignore, .env.example
├── codex.config.json, package.json
├── scripts/          # 运维
├── commands/         # 自定义命令 .md
├── skills/<name>/skill.md
├── agents/*.md
├── memory/           # rules.md, decisions.md, context.json
└── output/           # reports/, charts/, logs/
```

职责分离：运维 → `scripts/`；命令 → `commands/`；能力 → `skills/`；角色 → `agents/`；治理 → `memory/`；产物 → `output/`。

## Skills 路由（按意图自动匹配）

命中意图时读 `~/.vscode/skills/<name>/SKILL.md`。同主题优先级：`test-driven-development`（非 `tdd`）、`design-taste-frontend`（非 `-v1`）、UI 先 `ui-skills-root`。

| 意图 | Skill |
|------|-------|
| 会话启动 / 选 skill | `using-agent-skills` |
| 需求不清 | `interview-me` |
| 概念发散 | `idea-refine` / `brainstorming` |
| 写 spec | `spec-driven-development` |
| 写计划 | `writing-plans` / `executing-plans` |
| 任务分解 | `planning-and-task-breakdown` |
| 子代理执行 | `subagent-driven-development` / `dispatching-parallel-agents` |
| 薄切片实现 | `incremental-implementation` |
| TDD | `test-driven-development` |
| Bug 调查 | `systematic-debugging` / `debugging-and-error-recovery` |
| 验证完成 | `verification-before-completion` |
| 五轴审查 | `code-review-and-quality` |
| since-point 审查 | `code-review` |
| 简化 | `code-simplification` / `ponytail` |
| 安全审查 | `security-and-hardening` |
| 性能优化 | `performance-optimization` |
| 架构 / 领域 | `codebase-design` / `domain-modeling` |
| API 设计 | `api-and-interface-design` |
| UI 入口（必做） | `ui-skills-root` / `npx ui-skills start` |
| 去 AI 味 | `baseline-ui` |
| 审计界面 | `improve-ui` |
| 新建品味 UI | `design-taste-frontend` |
| 生产级 UI | `frontend-ui-engineering` |
| 改版 | `redesign-existing-projects` / `impeccable` |
| GSAP | `gsap-core` → `gsap-scrolltrigger` / `gsap-react` |
| Remotion | `remotion-best-practices` → 专项 |
| Framer Motion | `framer-motion-patterns` |
| 部署 Vercel | `deploy-to-vercel` / `vercel-post-deploy-verify` |
| 浏览器测试 | `playwright-skill` / `webapp-testing` |
| SaaS 脚手架 | `nextjs-saas-feature-scaffold` |
| 组件模板 | `shadcn-app-components` |
| 预览先展示 | `preview-first-sync` |
| Supabase | `supabase` / `supabase-postgres-best-practices` |

选用原则：
1. 命中意图 → 读对应 `SKILL.md`
2. 同一轮最多一个主流程 skill；审查类可末尾叠加
3. Process skill（brainstorming / systematic-debugging）先于实现类
4. UI 任务：先 `ui-skills-root` 路由，再叠加实现类

## agent_KB 协议

- 根目录：`~/.vscode/agent_KB/`（→ `~/Documents/code/agent_KB`）
- 协议文件：`AGENTS.md`
- **默认可写仅 `inbox/`**；正式区（memory / playbooks / profile）需用户确认
- 分区：`inbox/`（草稿）、`memory/`（决策/踩坑/复盘）、`playbooks/`（可复用流程）、`profile/`（偏好）、`projects/`（项目索引）
- 会话开始：读 `profile/preferences.md`、相关 `playbooks/`、对应 `projects/*.md`
- 有价值结论写入 `inbox/`（除非用户禁止）

## UI Skills 自动启动

识别到以下意图时，自动加载 UI skills（不等用户点名）：
- UI 词：界面、页面、组件、布局、样式、视觉、品牌、落地页、Dashboard、表单、配色、字体、间距、动效
- 设计动词：设计、美化、润色、去 AI 味、改版、重设计
- 隐含 UI：改 Header/Hero/卡片外观、换 banner、调 token/主题色

不自动启动：纯后端 / DB / 鉴权 / CI / 与界面无关的 bugfix。
