# Workspace Commit Log (ads-workspace-commit-log) 使用指南

> **Language**: [English](ads-workspace-commit-log.md) | [中文](ads-workspace-commit-log.zh-CN.md)

Workspace 级 git commit 记忆系统。在向 master 创建 MR 后自动生成 release log 文件并更新索引，方便跨 session 回溯历史变更。

**触发关键词**: 由 `ads-workspace-commit-push` 自动调用，不直接触发

---

## 技能文件

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 技能定义：输入参数、工作流、硬规则 |

---

## 前提条件

| 依赖 | 类型 | 用途 |
|------|------|------|
| `glab` CLI | 工具 | 获取 MR 元数据（URL、title、branch） |
| `docs/common/ops-log/release-log/01.MEMORY.md` | 文件 | Release log 索引文件 |

---

## 使用方式

### 由 ads-workspace-commit-push 自动调用

当 `/ads-workspace-commit-push master` 创建新 MR 后，自动调用本技能：

```
Skill("ads-workspace-commit-log", args="<mr-iid>")
```

### 输入参数

仅需 MR 编号（IID），其余信息自动获取：
- MR URL、title、branch → `glab mr view`
- 提交者 → `git config user.name`

### 输出文件

- **Release log**: `docs/common/ops-log/release-log/02.mr<iid>-YYYYMMDD-<person>.md`
- **索引更新**: `docs/common/ops-log/release-log/01.MEMORY.md` 顶部插入新行

### 工作流

1. 收集 MR 元数据 + 变更数据（`git diff origin/master..HEAD`）
2. 生成 release log 文件（按主题分组的变更描述 + 文件清单 + commit 列表）
3. 更新索引（最新在前）
4. Commit 并 push
5. 由 `ads-workspace-commit-push` 执行 squash + force push，合入 MR 的单一 commit

---

## 相关技能

| 技能 | 用途 |
|------|------|
| `/ads-workspace-commit-push` | 标准提交推送流程，在创建 master MR 后自动调用本技能 |
| `/ads-okr-memory-update` | 项目/个人记忆更新（不同层级的记忆系统） |
