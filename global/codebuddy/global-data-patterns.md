---
description: 数据展示模式 — 预览先展示、异步入库（跨项目通用指针）
alwaysApply: true
---

# 数据展示模式

## 预览优先（Preview-First）

AI 生成或高延迟内容，用户应**立即看到结果**，DB 写入后台完成：

```
generate → setPreviewCache(server) → return to client
client: sessionStorage + setState()     // 立即渲染
void syncToDb() → delete preview      // 异步持久化
syncState: cached → syncing → synced | failed
```

## 何时用

- AI 批量生成（话题、洞察、草稿）。
- 生成耗时 > 500ms 且用户需即时反馈。
- 允许短暂「待同步」状态 UI。

## 何时不用

- 金融/订单等强一致写入（必须等 DB 确认）。
- 简单 CRUD（直接写库 + revalidate 即可）。

## 缓存层

| 层 | 用途 | TTL |
|----|------|-----|
| 服务端预览 | 跨请求暂存 batch | 1h 典型 |
| 客户端 sessionStorage | 刷新后恢复展示 | 会话级 |
| AI 去重 | 相同 prompt 复用 | 1h 典型 |

存储后端：Redis（生产）/ Memory（开发），通过 `CacheStore` 接口切换。

## 实现时

- **必须**读 skill `preview-first-sync` 并按 checklist 落地。
