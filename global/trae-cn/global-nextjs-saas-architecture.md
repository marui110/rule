---
description: Next.js SaaS 应用架构约束 — Server Component、Action、lib 分层（跨项目通用）
alwaysApply: true
---

# Next.js SaaS 架构

## 分层

- **Server Components 优先**；数据获取在 Server Component / Server Action。
- **Server Actions 优先于 API 路由**（Webhook、Cron、第三方回调除外）。
- **纯函数进 `lib/`**；Client 组件只保留交互、状态、浏览器 API。
- **组件三层**：`components/ui/`（shadcn 基元）→ `components/shared/`（跨页复用）→ `components/{domain}/`（领域 UI）。

## Server Action 铁律

1. 文件顶行 `"use server"`。
2. **禁止接收 `userId`**；从 session 派生。
3. **第一行鉴权**（`getAuthenticatedUser()` 或项目等价物）。
4. Zod 校验所有输入。
5. DB 查询必须带 `userId` 过滤（应用层 + RLS 双保险）。
6. 变更后 `revalidatePath` / `revalidateTag`（按项目约定）。
7. 副作用（埋点、通知）用 `void` 异步，不阻塞响应。

## 页面缓存

- 用户个性化页面（dashboard、设置、用户数据）设 `export const dynamic = "force-dynamic"`。
- 禁止缓存含用户数据的 RSC payload。

## 错误处理

- 业务错误抛带 code 的 `ActionError`（或项目等价物），Client 用 i18n 映射展示。
- 不向客户端泄露堆栈或内部 ID。

## 实现时

- 读 `node_modules/next/dist/docs/` 确认框架版本 API。
- 新 feature 用 skill `nextjs-saas-feature-scaffold`。
