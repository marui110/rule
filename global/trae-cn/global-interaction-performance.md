---
description: 交互性能 — 避免伪导航、减少 DB 往返、即时反馈（跨项目通用）
alwaysApply: true
---

# 交互性能

慢交互优先查**应用层**，不要先假设 SQL/索引是瓶颈。典型链路：

```
用户操作 → 鉴权/中间件 → RSC 整页渲染 → 多次 DB 往返 → 客户端重绘
```

## 禁止

- **同页筛选/Tab/分页/选日期** 用 `router.push` / 整页导航触发 RSC 重渲染。
- 中间件每次请求都远程 `getUser()`（Supabase Auth 等），token 仍有效时不读本地 session。
- Server Action 串行多次 DB 往返（update → query max → insert），可合并却拆开。
- 写操作等 Server Action 完成才更新 UI；无 pending / 乐观反馈。
- 列表页 N+1：先查列表再按 id 批量查关联表（可合并为单次 SQL / CTE）。
- 菜单路由无预取、无 loading 边界，切换时白屏。

## 必须

| 场景 | 做法 |
|------|------|
| 同页 UI 状态（Tab、日期、分页、筛选） | 客户端 `setState` + `history.replaceState` 同步 URL；**跨月/跨模块**才 `router.push` |
| 同页数据刷新 | Server Action 或 fetch 拉片段；`useTransition` + 局部 loading |
| 写操作（接受、删除、状态变更） | 乐观 UI → Action 持久化 → 失败回滚 |
| 多次 DB 读 | 合并为单次查询（`Promise.all` 或 CTE `json_agg`） |
| 鉴权中间件 | 本地 session 快路径；仅 token 临期时远程刷新 |
| App 主导航 | 空闲时 `router.prefetch`；`<Suspense>` + skeleton；导航 pending 态 |
| 个性化页面 | `force-dynamic` 可接受；仍避免**不必要的** layout/整页重拉 |

## 诊断顺序

1. 复现路径是否触发**整页 RSC**（Network 里 `_rsc` / Flight）。
2. 查 middleware 是否每次打 Auth API。
3. `EXPLAIN ANALYZE` + `pg_stat_statements` 确认 DB 是否真瓶颈。
4. 数清单次交互的 **DB round-trip 次数**。

## 与现有规则关系

- 预览/写入：`global-data-patterns.mdc`（Preview-First）
- Next.js 分层：`global-nextjs-saas-architecture.mdc`
- 鉴权安全：`global-security-baseline.mdc`（快路径不得跳过服务端写操作鉴权）
