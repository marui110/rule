# MCP 跨 Agent 同步

各 Agent 的 MCP 配置格式不同，本目录用 **canonical JSON** 做中转，再转换成各平台格式。

## 数据源

| 角色 | 路径 |
|------|------|
| Canonical（Git 镜像） | `mcp/canonical.json` |
| 导入源 Cursor | `~/.cursor/mcp.json` |

## 部署目标

| Agent | 路径 | 格式说明 |
|-------|------|----------|
| Cursor | `~/.cursor/mcp.json` | `{ "url" }` 或 `{ "command", "args" }` |
| Claude Code | `~/.claude.json` → `mcpServers` | `{ "type": "http\|stdio", ... }` |
| Codex | `~/.codex/config.toml` → `[mcp_servers.*]` | TOML，HTTP / stdio |

## 用法

```bash
# 从 Cursor 导入到 canonical，再部署到全部 Agent
~/Documents/code/rule/sync-global-mcp.sh --import

# 仅按 mcp/canonical.json 部署（不改 canonical）
~/Documents/code/rule/sync-global-mcp.sh
```

也可随技能/规则一起同步：

```bash
~/Documents/code/rule/sync-global-agent-standards.sh
```

## 新增 MCP

1. 在 Cursor 中添加 MCP
2. 运行 `sync-global-mcp.sh --import`
3. 或手动编辑 `mcp/canonical.json` 后运行 `sync-global-mcp.sh`

### canonical 示例

```json
{
  "mcpServers": {
    "vercel": {
      "transport": "http",
      "url": "https://mcp.vercel.com"
    }
  }
}
```

## 注意

- Claude Code 的 MCP **必须**写在 `~/.claude.json`，写在 `~/.claude/settings.json` 无效
- Codex OAuth 类 MCP（如 Vercel）需在 Codex 内单独登录一次
- 本地密钥（如 `FIRECRAWL_API_KEY`）**不放** `mcp/canonical.json`，放 `mcp/secrets.local.json`（已 `.gitignore`）。同步时自动注入对应 server 的 `env`
