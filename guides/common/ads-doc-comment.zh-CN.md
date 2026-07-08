# Ads Doc Comment (ads-doc-comment) 使用指南

> **Language**: [English](ads-doc-comment.md) | [中文](ads-doc-comment.zh-CN.md)

为 `docs/` 下的 Markdown 文档添加类似 Google Docs 的内联评论功能。支持添加、回复、解决、列出和清理评论，以及 AI 辅助文档审查（含严重级别标记）。

**触发关键词**: "doc comment", "add comment", "review doc", "文档评论", "添加评论", "审查文档", "list comments", "resolve comment", "clean comments"

---

## 技能文件/Skill Files

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能定义，包含全部 8 个操作 |
| `references/format-spec.md` | 评论格式规范、放置规则、ID 生成、解析指南 |
| `references/review-guidelines.md` | AI 审查严重级别、审查重点、质量清单 |

---

## 前置依赖/Prerequisites

| 依赖 | 类型 | 用途 |
|------|------|------|
| Git | 系统 | 通过 `git config user.name` 检测作者 |
| `docs/` 目录 | 仓库 | 评论目标文档所在目录 |

无外部技能依赖。

---

## 使用场景/Usage

### 场景 1：在指定章节添加评论

> "给 docs/team/00.paid-ads-dev/03.sop/01.okr-sop.md 的 '评审流程' 添加评论：缺少频率说明"

技能读取文件，定位目标标题，在其后插入 HTML 注释块。评论在渲染的 Markdown 中不可见。

### 场景 2：AI 审查文档

> "review docs/.../epic-file.md --focus completeness"

技能读取整个文档，分析完整性缺口，在相关位置插入带 `[Blocker]`/`[Major]`/`[Minor]`/`[Suggestion]` 严重级别标记的评论，并输出汇总表。

### 场景 3：列出和管理评论

> "list comments in docs/common/ads-overview.md --status open"

输出所有打开状态评论的表格，包含 ID、严重级别、作者、日期、位置和摘要。

> "resolve c-20260509-0001 in docs/common/ads-overview.md"

将评论状态从 `open` 改为 `resolved`。

### 场景 4：清理已解决的评论

> "clean comments in docs/common/ads-overview.md"

移除文件中所有已解决的评论块，保留原始文档内容。执行前展示预览并确认。

### 场景 5：协作讨论

> "reply to c-20260509-0001 in docs/.../design.md: 同意，我会补充重试逻辑"

在已有评论线程中添加回复，创建类似 Google Docs 的评论讨论。

---

## 评论格式/Comment Format

评论以内联 HTML 注释形式存储，使用 `@doc-comment` 前缀。在渲染的 Markdown 中不可见，与 gdoc-sync 兼容（同步时静默跳过）。

```html
<!-- @doc-comment id="c-20260509-0001" author="luka.yang" date="2026-05-09" status="open" severity="major" -->
<!-- [Major] 缺少错误处理说明 → 添加重试策略章节 -->
<!-- @doc-reply author="john.doe" date="2026-05-10" -->
<!-- 好建议，下个版本会补充 -->
<!-- @/doc-comment -->
```

完整规范见 `references/format-spec.md`。

---

## 操作速查/Operations Quick Reference

| 操作 | 说明 |
|------|------|
| `add` | 在指定位置添加评论 |
| `reply` | 回复已有评论线程 |
| `resolve` | 标记评论为已解决 |
| `list` | 列出评论（支持过滤） |
| `delete` | 删除评论块 |
| `review` | AI 审查文档并插入评论 |
| `summary` | 显示所有打开评论的摘要 |
| `clean` | 清理已解决（或全部）评论块 |

---

## 相关技能/Downstream Skills

| 技能 | 关系 |
|------|------|
| `ads-workspace-gdoc-sync` | 评论在 Markdown → Google Docs 同步时被静默跳过 |
| `ads-workspace-commit-push` | 用于提交包含评论的文档 |
| `ads-okr-epic-td` | Epic TD 文档是常见的审查目标 |
