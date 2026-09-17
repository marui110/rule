# Agent 指令

| 层级 | 路径 |
|------|------|
| 全局（跨项目） | `~/.cursor/rules/global-*.mdc`（见 `global-agent-manifest.mdc`） |
| 本项目 | `.cursor/rules/*.mdc` |

本地规则优先于全局。完整 skill 路由 → `global-agent-workflow.mdc`。

同步（权威）：`~/Documents/code/rule/sync-global-agent-standards.sh`

> 本文件只写**跨工具通用**的项目增量（技术栈 / 目录 / 路径 / 命令）。  
> 代码级规范放 `.cursor/rules/*.mdc`，勿在此复述长文。

---

## 技术栈

- （待补：语言 / 框架 / 包管理器 / 运行时）

## 项目结构

```
（待补：顶层目录说明）
```

## 验证

```bash
# （待补：test / lint / typecheck）
```

## 个人知识库（agent_KB）

- 根目录：`/Users/marui/Documents/code/agent_KB`
- 协议：`/Users/marui/Documents/code/agent_KB/AGENTS.md`
- 本项目页：`/Users/marui/Documents/code/agent_KB/projects/{{name}}.md`
- 写入：默认可写 `inbox/`；通用 → memory 可同轮自动晋升；新建 playbook / profile / 项目级须确认
