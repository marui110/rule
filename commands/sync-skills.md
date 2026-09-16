# Sync Global Skills

拉取上游 skill 源，部署到 `~/.claude/skills/`，链接到所有 Agent，并镜像到 `~/Documents/code/skill/global/`。

**推荐（含上游拉取）：**

```bash
~/Documents/code/rule/daily-sync-agent-standards.sh
```

仅部署（不拉上游）：

```bash
~/Documents/code/rule/sync-global-agent-standards.sh
```

定时：每天 09:00 LaunchAgent `com.user.agent-standards-daily-sync`（安装：`scripts/install-daily-sync.sh`）。

完成后确认：

- ui-skills `skills/` 已相对 ibelick 上游更新（经 `.git-upstream`）
- `~/Documents/code/skill/codeskill/` 已部署到 `~/.claude/skills/`
- `~/Documents/code/skill/ui-skills/skills/` 已链接到 `~/.claude/skills/`
- Cursor / Codex / Agents 的 skill 数量与权威源一致
- 日志：`~/Library/Logs/agent-standards-sync/`
