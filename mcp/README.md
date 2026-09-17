# MCP 跨 Agent 同步

各 Agent 的 MCP 配置格式不同，本目录用 **canonical JSON** 做中转，再转换成各平台格式。

## 数据源

| 角色 | 路径 |
|------|------|
| Canonical（Git 镜像 / 备份） | `mcp/canonical.json` |
| 本地密钥（不进 Git） | `mcp/secrets.local.json` |
| 导入源 Cursor | `~/.cursor/mcp.json` |

## 部署目标

| Agent | 路径 | 格式说明 |
|-------|------|----------|
| Cursor | `~/.cursor/mcp.json` | `{ "url" }` 或 `{ "command", "args" }` |
| Claude Code | `~/.claude.json` → `mcpServers` | `{ "type": "http\|stdio", ... }` |
| Codex | `~/.codex/config.toml` → `[mcp_servers.*]` | TOML，HTTP / stdio |
| VS Code Copilot | `~/Library/Application Support/Code/User/mcp.json` | `{ "servers": { ... } }`（合并保留本地项如 pencil） |

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

1. 编辑 `mcp/canonical.json`（推荐，便于 Git 备份），或在 Cursor 中添加后 `--import`
2. 需要密钥时写入 `mcp/secrets.local.json`（已 `.gitignore`）
3. 运行 `sync-global-mcp.sh`

### canonical 示例

```json
{
  "mcpServers": {
    "vercel": {
      "transport": "http",
      "url": "https://mcp.vercel.com"
    },
    "chrome-devtools": {
      "transport": "stdio",
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest", "--no-usage-statistics"]
    }
  }
}
```

### 当前已备份服务器

| Name | 说明 |
|------|------|
| `vercel` | Vercel HTTP MCP |
| `supabase` | Supabase HTTP MCP |
| `firecrawl-mcp` | Firecrawl stdio（密钥在 secrets.local） |
| `chrome-devtools` | [Chrome DevTools MCP](https://github.com/ChromeDevTools/chrome-devtools-mcp)（`npx chrome-devtools-mcp@latest`） |
| `context-mode` | [mksglu/context-mode](https://github.com/mksglu/context-mode)（`npx context-mode`；配套 skill `context-mode` / `ctx-*`） |

## 注意

- Claude Code 的 MCP **必须**写在 `~/.claude.json`，写在 `~/.claude/settings.json` 无效
- Codex OAuth 类 MCP（如 Vercel）需在 Codex 内单独登录一次
- 本地密钥（如 `FIRECRAWL_API_KEY`）**不放** `mcp/canonical.json`，放 `mcp/secrets.local.json`。同步时自动注入对应 server 的 `env`
- `chrome-devtools` 默认带 `--no-usage-statistics`；需要完整浏览器调试时确保本机已装 Chrome
- `context-mode` skill 依赖同名 MCP；重装 skill 后务必再跑一次 `sync-global-mcp.sh` / `sync-global-agent-standards.sh`