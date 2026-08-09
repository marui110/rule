---
description: UI Skills（ibelick/ui-skills）— 识别到设计意图时自动启动路由，适用于 code 下全项目
alwaysApply: true
---

# UI Skills（ibelick/ui-skills）

适用于 `~/Documents/code/` 下**所有项目**的 UI / 前端界面工作。

源仓库：https://github.com/ibelick/ui-skills  
本机备份：`~/Documents/code/skill/ui-skills/`  
运行时 skill：`ui-skills-root`、`baseline-ui`、`improve-ui`、`create-design-md`、`fixing-accessibility`、`fixing-metadata`、`fixing-motion-performance`

## 自动启动（设计意图检测）

**不要等用户说「跑 ui-skills」。** 分析用户意图后，只要命中下方任一信号，**本轮第一个动作**必须启动路由：

1. 执行 `npx ui-skills start`（优先；可再 `categories` / `list` / `get`），**或**
2. 直接读 `~/.claude/skills/ui-skills-root/SKILL.md`（CLI 不可用时）

然后按输出加载 ≤3 个 skill，再读代码 / 实现。

### 设计意图信号（命中即自动启动）

- 明确 UI 词：界面、页面、组件、布局、样式、视觉、品牌、落地页、Dashboard、表单、弹窗、导航、主题、配色、字体、间距、动效、动画、无障碍、polish、好看、丑、改版、重设计、DESIGN.md
- 设计动词：设计、美化、润色、去 AI 味、对齐稿、还原 Figma/MasterGo、做一版视觉
- 隐含 UI：改 Header/Hero/卡片外观、换 banner、调 token/主题色、做空状态/加载态、交互反馈
- 用户 @ 了设计稿、截图、或要求「按设计规范」

### 不自动启动

- 纯后端 / DB / 鉴权 / CI / 与界面无关的 bugfix
- 用户明确说跳过 UI Skills / 只要逻辑不要样式
- 本会话已对**同一 UI 子任务**完成过路由且意图未变（换新页面/新视觉目标则重新跑）

## 协议（先路由再实现）

```bash
npx ui-skills start
npx ui-skills categories
npx ui-skills list --category <category>
npx ui-skills get <slug>
```

1. 意图检测 → 自动启动（见上）
2. 加载选出的 1–3 个 skill（优先具体、按栈）
3. 再实现；禁止先写大段 UI 再补 skill

## 与本仓库既有规范的优先级

1. **项目本地** `AGENTS.md` / `.cursor/rules/` / 设计 token（最高）
2. 全局 `global-ui-conventions` / `global-motion-conventions`
3. **ui-skills** 路由出的 skill（含 `baseline-ui` 等）
4. 其它视觉 skill（`design-taste-frontend`、`impeccable`、`frontend-ui-engineering` 等）

冲突时：不引入与项目栈冲突的新基元（例如项目已是 Radix/shadcn，不要强行换成 Base UI）；动效仍遵守 `global-motion-conventions`（集中 `lib/motion.ts`、reduced-motion）。

## 常用 skill 速查

| 场景 | Skill |
|------|--------|
| UI 任务入口 / 路由 | `ui-skills-root` 或 `npx ui-skills start` |
| 快速去 AI 味 / 间距层级 | `baseline-ui` |
| 审计现有界面并出计划 | `improve-ui` |
| 生成 DESIGN.md | `create-design-md` |
| 无障碍修复 | `fixing-accessibility` |
| SEO / metadata | `fixing-metadata` |
| 动效性能 | `fixing-motion-performance` |

## 安装与同步

```bash
npx skills add ibelick/ui-skills -g -y
~/Documents/code/rule/sync-global-agent-standards.sh
```

权威副本：`~/Documents/code/skill/ui-skills/skills/<name>` → `~/.claude/skills/`。
