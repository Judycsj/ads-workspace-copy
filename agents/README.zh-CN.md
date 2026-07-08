# Agents

Agents 是带有受限权限和明确职责的专用子代理。与 skills 不同，agent 会作为
独立实体运行，并拥有自己的系统提示词和工具访问范围。

## 跨工具兼容

Agent 文件在 Claude Code、Cursor、Codex 中共用同一套 `.md` 格式。

### 存储路径

| 范围 | Claude Code | Cursor | Codex |
|------|-------------|--------|-------|
| 用户级 | `~/.claude/agents/` | `~/.cursor/agents/` | `~/.codex/agents/` |
| 项目级 | `.claude/agents/` | `.cursor/agents/` | `.codex/agents/` |

优先级：项目级高于用户级。

`sra add` 会自动把 agent 安装到这三类用户级目录。

### Frontmatter 字段

| 字段 | 必需 | Claude Code | Cursor | Codex | 说明 |
|------|------|-------------|--------|-------|------|
| `name` | 否 | 是 | 是 | 是 | 默认取文件名，需 kebab-case |
| `description` | 否 | 是 | 是 | 是 | 用于自动委派 |
| `tools` | 否 | 是 | 忽略 | 忽略 | Claude Code 的工具白名单 |
| `model` | 否 | `opus`/`sonnet` | `fast`/`inherit`/model ID | 忽略 | 各工具模型语义不同 |
| `readonly` | 否 | 忽略 | 是 | 是 | Cursor/Codex 的写权限限制 |

兼容策略：同一文件中同时写 `tools` 和 `readonly`，各工具只读取自己认识的字段。

## 设计原则

1. **最小权限**：分析类 agent 默认只读
2. **单一职责**：一个 agent 只做一件事
3. **模型匹配任务**：复杂推理使用更强模型，高吞吐任务使用更快模型

## 可用 Agents

| Agent | 用途 | Tools (Claude Code) | Model | Readonly |
|-------|------|---------------------|-------|----------|
| `ads-diagnosis-module-reviewer` | 评审 ads-diagnose 单个或批量 case 输出的一级 R 模块归因是否正确，并给出模型/出价下钻路由 | `Read`, `Grep`, `Glob` | `opus` | `true` |
| `ads-diagnose-bidding-deepdive` | 由 ads-diagnose 主技能在 R4 命中时调度，对 R4 出价调控进行叶节点归因深挖；补充查询 ClickHouse 获取 final_coef / MPC / 数据采集等指标 | `Bash`, `Read`, `Grep`, `Glob` | `opus` | `true` |
| `ads-diagnose-model-deepdive-hb` | 由 ads-diagnose 主技能在 R3 命中时调度，对模型侧 PCOC 做深度归因；拆分 UniCR 覆盖、到达点击分桶和延迟反馈机制 | `Bash`, `Read`, `Grep`, `Glob` | `opus` | `true` |
| `ads-xteam-runner` | 从 SeaTalk/OpenClaw 消息执行 Ads PRD/TRD 到验收 SOP，并返回结构化通知动作 | `Read`, `Grep`, `Glob` | `opus` | `true` |
| `bid-sense-api-dev` | Bid Sense configurable service 全流程 API 开发：TD 设计、YAML config + biz_logic 代码生成、本地单测、Redis mock 数据写入、测试请求生成 | `Read`, `Write`, `Bash`, `Glob`, `Grep` | `opus` | `false` |
| `ads-platform-planner` | 旧版 Ads Platform planner agent 的兼容入口 | `Read`, `Grep`, `Glob`, `SemanticSearch` | `opus` | `true` |
| `ads-roi3-analysis-runner` | ROI3 分析执行体，由 ads-roi3-analysis hub 派发：吃已确认计划卡，自主跑 preflight→路由→内联调 spoke→合成→出报告+案底；不交互、不再派子代理 | `Read`, `Glob`, `Grep`, `Bash`, `Skill`, `Write`, `Edit` | `opus` | `false` |

## 新建 Agent

1. 在当前目录创建一个新的 `.md` 文件
2. 补充 frontmatter：

```yaml
---
name: agent-name
description: >
  One-line description of when this agent should be used.
tools:
  - Read
  - Grep
  - Glob
model: sonnet
readonly: true
---
```

3. 在 body 中写清楚角色、流程和输出要求
4. 默认按只读设计，确有必要再放开写权限
