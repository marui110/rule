# 业务项目挂接模板

## 推荐：一键 / 自动

```bash
# 手动挂接任意仓
~/Documents/code/agent_KB/scripts/hook-project.sh <project_dir>

# 安装 Cursor 用户 hook（打开未挂接的 code/ 仓 → 自动创建 AGENTS.md）
~/Documents/code/agent_KB/scripts/install-cursor-auto-hook.sh
```

缺失 `AGENTS.md` 时用 `_templates/project-agents.md` 生成完整骨架（技术栈/结构占位 + agent_KB）。Agent 新建项目时须直接跑 `hook-project.sh`，不必再问。

## 手动片段（脚本不可用时）

将以下片段写入业务项目的 `CLAUDE.md`、`AGENTS.md` 或 `.cursor/rules/agent_KB-pointer.mdc`：

```markdown
## 个人知识库（agent_KB）

- 根目录：`/Users/marui/Documents/code/agent_KB`
- 协议：`/Users/marui/Documents/code/agent_KB/AGENTS.md`
- 本项目页：`/Users/marui/Documents/code/agent_KB/projects/<repo-name>.md`
- 写入：仅 `inbox/`；正式区需用户确认晋升
```

首次挂接时，在知识库用 `_templates/project.md` 创建对应 `projects/<repo-name>.md`，并更新 [[_meta/index]]。

> 唯一路径：`agent_KB`。勿再使用其它别名或 symlink。
