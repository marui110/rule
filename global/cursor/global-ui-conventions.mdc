---
description: UI 设计交互规范 — token 命名、排版、hover、品牌色分离（跨项目通用）
alwaysApply: true
---

# UI 交互规范

## CSS 变量体系

- 用 shadcn + CSS 变量（`:root` / `.dark`）；Tailwind 通过 `@theme inline` 映射。
- 语义 token：`background`、`foreground`、`muted`、`accent`、`destructive`、`border`、`ring`。
- 表面层级：`surface-1/2/3` 或 `card` / `popover` 区分深度。

## 品牌色与状态色分离

- `accent` = 品牌主色；`destructive` = 独立红色，**不与品牌色混用**。
- 成功/警告/错误用独立 token，不硬编码在组件里。

## 排版工具类

- 统一命名：`ui-text-title` / `ui-text-section` / `ui-text-body` / `ui-text-caption`（或项目 `cp-text-*` 等价物）。
- 标题与正文用同一 sans 栈；指标/代码用 mono。

## 交互

- **菜单/下拉 hover 用 `muted`**，不用 `accent`（accent 留给主 CTA）。
- 卡片 hover：CSS `transform` + 轻阴影（200ms），不用 framer scale。
- 表单 focus：accent 色 10–15% 光晕环（`.ui-field` 或等价类）。
- 空状态：虚线边框 + `surface-2` 底 + 可选 icon/illustration。

## 组件选用

- 基元用 `components/ui/`；不重复造 Button/Input/Dialog。
- 跨页模式用 `components/shared/`；见 skill `shadcn-app-components`。
- **UI 任务入口**：先 `ui-skills-root` / `npx ui-skills start`（见 `global-ui-skills`），再 `design-taste-frontend` / `impeccable` / `baseline-ui`。

## 无障碍

- 交互元素有可见 focus ring。
- 图标按钮带 `aria-label`。
- 支持 `prefers-reduced-motion`（见 `global-motion-conventions`）。
