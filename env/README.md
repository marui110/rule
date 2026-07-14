# 跨 Agent 运行时环境统一

## Canonical

| 工具 | 路径 |
|------|------|
| Python | Miniconda `base`：`/opt/homebrew/Caskroom/miniconda/base/bin/python3.14` |
| Node.js | Homebrew：`/opt/homebrew/bin/node` |
| PATH | miniconda/base → homebrew → 系统路径 |

`terminal.integrated.env.osx` 仅同步 PATH，不写入代理变量。

配置源：`env/canonical.json`

## 部署目标

| Agent | 写入位置 |
|-------|----------|
| Cursor | `~/Library/Application Support/Cursor/User/settings.json` |
| Trae CN | `~/Library/Application Support/Trae CN/User/settings.json` |
| Claude Code | `~/.claude/settings.json` → `env.PATH` |
| Codex | `~/.codex/config.toml` → `[shell_environment_policy]` |
| Login shell | `~/.zprofile` |

## 用法

```bash
~/Documents/code/rule/sync-global-env.sh
```

也可随总同步脚本一起运行：

```bash
~/Documents/code/rule/sync-global-agent-standards.sh
```
