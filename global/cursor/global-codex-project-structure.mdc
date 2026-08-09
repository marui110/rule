---
description: Codex / Agent 项目脚手架结构 — 新建 Codex 类项目时的目录、职责分离与交付约定
alwaysApply: true
---

# Codex 项目创建结构

**适用**：用户要求「创建 / 初始化 Codex 项目」「搭 Agent 工作区脚手架」，或仓库以 Codex/多 Agent 编排为主（含 `codex.config.json`、`CODEX.md`、本地 `skills/` + `agents/`）。

**不适用**：普通应用仓库（Next.js / 纯库等）— 用现有 `global-nextjs-saas-*` 与项目本地规则。

## 标准树

```
my-codex-project/
├── README.md              # 项目说明（快速理解）
├── CODEX.md               # Codex 用法与约定
├── .gitignore
├── .env.example           # 环境变量模板（无密钥）
├── codex.config.json      # 模型、权限、路径等配置
├── package.json           # 依赖与 scripts
├── scripts/               # 运维脚本
│   ├── run_codex.sh
│   ├── init_project.sh
│   └── deploy.sh
├── commands/              # 自定义命令（.md）
│   ├── analyze.md
│   ├── dashboard.md
│   └── report.md
├── skills/                # 可复用能力（每技能一目录）
│   ├── <skill-name>/
│   │   └── skill.md
│   └── ...
├── agents/                # 专职 Agent 定义
│   ├── data-agent.md
│   ├── research-agent.md
│   └── report-agent.md
├── memory/                # 治理与长期状态
│   ├── rules.md           # 项目规则与约定
│   ├── decisions.md       # 关键决策记录
│   └── context.json       # 上下文缓存
└── output/                # 生成物（保持源码树干净）
    ├── reports/
    ├── charts/
    └── logs/
```

示例技能名按领域命名（如 `data-analysis`、`visualization`、`nlp`）；按项目实际增删，勿堆空目录。

## 职责分离（硬规则）

| 目录 | 放什么 | 不放什么 |
|------|--------|----------|
| `scripts/` | 启动、初始化、部署等可执行运维 | 业务逻辑、Agent 提示词 |
| `commands/` | 可调用的命令说明 / prompt 片段 | 长期规则、生成报告成品 |
| `skills/` | 模块化能力定义（可被多 Agent 复用） | 一次性任务输出 |
| `agents/` | 角色边界、工具权限、工作流 | 通用 skill 正文（引用 skills） |
| `memory/` | 规则、决策、可持久上下文 | 临时日志、大文件产物 |
| `output/` | 报告、图表、运行日志等生成物 | 源码、配置、skills |

## 创建时必须做

1. 建齐根文件与六大目录；`output/` 子目录写入 `.gitignore` 策略（可忽略内容、保留 `.gitkeep`）。
2. `CODEX.md` 写清：如何跑 `scripts/run_codex.sh`、命令入口、skills/agents 约定。
3. `memory/rules.md` 写项目级约定；关键决策追加到 `memory/decisions.md`。
4. `.env.example` 只列变量名与说明；真实密钥不进仓库。
5. 生成物一律进 `output/`，禁止散落在根目录或 `skills/` 旁。

## 与本机全局规范的关系

- 本机全局 skills / rules 仍走 `global-agent-manifest` / `global-skills-evolution`。
- 项目内 `skills/`、`agents/`、`memory/` 是**仓库本地**编排层；不替代 `~/.claude/skills`。
- 同步全局标准：`~/Documents/code/rule/sync-global-agent-standards.sh`
