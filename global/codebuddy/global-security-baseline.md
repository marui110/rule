---
description: SaaS 安全基线 — 鉴权、RLS、校验、限流、CSP（跨项目通用）
alwaysApply: true
---

# 安全基线

## 鉴权

- 所有受保护路由在 middleware/proxy 层拦截未登录请求。
- Server Action / API 不信任客户端传入的身份字段。
- Dev 环境 bypass（如有）**仅** `NODE_ENV === "development"` 且显式 env 开关；生产绝不可用。

## 数据访问

- 数据库启用 **RLS**；应用层查询仍带 `userId` 过滤（双保险）。
- `webhook_events`、`rate_limit_events` 等系统表拒绝客户端直连。
- 删除/更新前校验资源归属当前用户。

## 输入校验

- 所有外部输入经 **Zod**（或等价 schema）校验后再入库。
- 字符串设 `max()`；URL、UUID、日期格式用 regex/内置校验。
- 枚举字段用 `z.enum()`，不用裸 string。

## 速率限制

- 高成本操作（AI 生成、批量导入）按 `userId` + 操作类型限流。
- 限流状态存 DB 或 Redis，不纯内存（多实例部署）。

## AI 配额

- **成功后再扣配额**；生成失败不写 `usage_tracking`。
- 配额检查在 AI 调用前；记录在 AI 成功后。

## HTTP 安全头

- 生产：`Strict-Transport-Security`、`X-Frame-Options: DENY`、`X-Content-Type-Options: nosniff`。
- CSP 白名单最小化；`connect-src` 仅列实际需要的域名。

## 密钥

- API key / webhook secret 走 env 或密钥管理服务；不进代码、不进客户端。
- 集成凭证加密存储，查询时解密。

## 审查时

- 用 skill `security-and-hardening` 或 Cursor `review-security`。
