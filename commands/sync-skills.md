# Sync Global Skills

将 codeskill / ui-skills 部署到 `~/.claude/skills/`，链接到所有 Agent，并镜像到 `~/Documents/code/skill/global/`。

```bash
~/Documents/code/rule/sync-global-agent-standards.sh
```

完成后确认：

- `~/Documents/code/skill/codeskill/` 已部署到 `~/.claude/skills/`
- `~/Documents/code/skill/ui-skills/skills/` 已链接到 `~/.claude/skills/`
- Cursor / Codex / Agents 的 skill 数量与权威源一致
- `~/Documents/code/skill/global/` 含全量镜像
- `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md` 已更新
