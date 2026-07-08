# 记忆更新/Memory Update

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-02 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-okr-memory-update.zh-CN.md)
> **Language**: [English](ads-okr-memory-update.md) | [中文](ads-okr-memory-update.zh-CN.md)

统一记忆更新 skill — 扫描当前或历史会话，提取关键决策、发现和代码变更，写入项目记忆和/或个人记忆系统。

---

## 触发关键词

`memory update`, `更新记忆`, `项目记忆`, `个人记忆`, `personal memory update`, `更新项目记忆`, `更新个人记忆`, `补录记忆`, `sync memory`, `记入个人记忆`, `创建个人记忆`, `ads-okr-memory-update`, `ads-personal-memory-update`

## 技能文件

| 文件 | 说明 |
|------|------|
| `skills/common/ads-okr-memory-update/SKILL.md` | 技能定义 |
| `skills/common/ads-okr-memory-update/scripts/scan_sessions.py` | 会话扫描脚本（支持 Claude Code 和 Codex） |
| `skills/common/ads-okr-memory-update/scripts/bind_project.py` | 项目绑定助手（list/resolve/bind/check-sync） |
| `skills/common/ads-okr-memory-update/scripts/memory_ops.py` | 记忆操作助手（init/write-daily/update-index/finalize） |
| `skills/common/ads-okr-memory-update/references/schemas.md` | JSON schema（recorded-epics/sessions、content-json、字段路径） |
| `skills/common/ads-okr-memory-update/references/directory-layout.md` | 项目/个人记忆目录结构 |

## 前提条件

| 条件 | 说明 |
|------|------|
| 配置目录 | `docs/personal/<person>/config/`（不存在时自动创建） |
| 项目记忆（可选） | 已关联项目且项目目录包含 `epic-file.md` 和 `MEMORY.md` |
| 个人记忆（可选） | `docs/personal/<person>/memory/` 已存在且包含 `MEMORY.md` |
| 会话历史 | `~/.claude/projects/` 或 `~/.codex/sessions/` 下有 JSONL 会话文件 |

## 基本用法

技能提供两个独立功能：

### 功能 A：项目绑定

将当前 session 绑定到一个 epic 项目。触发词：`绑定项目`、`bind project`、`start project`。

1. 运行技能或输入「绑定项目」
2. 从最近的 epic 候选列表中选择，或手动输入项目路径/KP ID
3. 技能更新 `recorded-epics.json` 和 `recorded-sessions.json`
4. 检查 memory-sync 是否过期，过期则提示运行 `/ads-okr-memory-sync`

### 功能 B：记忆更新

扫描会话并写入记忆条目。触发词：`更新记忆`、`memory update`。

1. 运行 `/ads-okr-memory-update` 或输入「更新记忆」
2. 选择模式：**Single session**（仅当前会话）或 **Full session**（扫描历史会话）
3. 选择范围：**项目 + 个人**（推荐）、**仅项目**、或 **仅个人**
4. Full session 模式下：
   - 技能从 `docs/personal/<person>/config/recorded-sessions.json` 读取上次更新时间
   - Python 脚本扫描该时间后修改的会话文件（同时支持 Claude Code 和 Codex 会话）
   - 会话自动分类为全新、重新活跃、已跳过（自动去重）
   - 预览展示会话数量、时间范围、匹配统计
5. 对每个会话依次执行：
   - **Step 1**：项目绑定 — 通过 KP/KR ID、文件路径或显式关联匹配项目（每个新增项目需用户确认）
   - **Steps 2-3**：记忆写入子流程 — 项目/个人记忆的统一参数化流程，提取内容、用户确认、写入 daily 文件并更新索引
6. 所有写入均需用户确认后执行（Confirm-Once 模式：内容摘要 + 可选补充合为一个提示）
7. 追踪文件 `recorded-sessions.json` 更新已处理的会话信息

## 示例命令

**功能 A（项目绑定）：**
- `绑定项目`
- `bind project`
- `start project`

**功能 B（记忆更新）：**
- `/ads-okr-memory-update`
- `更新记忆`
- `更新项目记忆`
- `更新个人记忆`
- `补录最近的记忆`
- `sync memory since last week`
- `personal memory update`

## 注意事项

- 当前正在运行的会话会被自动排除
- 每个会话统一处理：项目绑定 → 项目记忆 → 个人记忆
- 自动触发时机：上下文压缩前、会话结束前、git commit 后（均为 single session 模式，默认项目+个人范围）
- 将记忆同步到 `epic-file.md` 请使用 `ads-okr-memory-sync`
- 迁移：旧追踪文件 `docs/personal/<person>/memory/.recorded-sessions.json` 和 `docs/personal/<person>/okr-memory/recorded-sessions.json` 会自动合并到统一位置
