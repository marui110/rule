---
description: 动效约束 — reduced motion、CSS vs framer 分工（跨项目通用）
alwaysApply: true
---

# 动效约束

## 分工

| 场景 | 用 |
|------|-----|
| 按钮 hover/active | **CSS only**（不用 scale/brightness 动画） |
| 卡片 hover lift | **CSS** `transition` + `translateY` + `box-shadow` |
| 列表/页面入场 | **framer-motion** stagger |
| 数字计数 | **framer-motion** `useSpring` |
| 布局宽度/侧边栏 | **framer-motion** `layout` |
| Dialog/Sheet | shadcn + motion 或 Radix 内置 |

## 必须

- 所有 motion 组件检查 `useReducedMotion()`；为 true 时跳过动画、直接终态。
- `globals.css` 加 `@media (prefers-reduced-motion: reduce)` 降级。
- duration/ease/variants **集中**在 `lib/motion.ts`（或项目等价文件），不散落在组件。

## 禁止

- 按钮 `whileHover={{ scale }}`。
- 无 reduced-motion 处理的无限循环动画（除 skeleton shimmer 且需降级）。
- 在列表每项上套独立 `AnimatePresence` 导致性能问题（用容器 stagger）。

## 实现时

- 读 skill `framer-motion-patterns` 获取 `motion.ts` 模板与 variants。
