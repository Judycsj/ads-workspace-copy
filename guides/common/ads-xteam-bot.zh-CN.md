# Ads XTeam Bot (ads-xteam-bot) 使用指南

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-29 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-xteam-bot.zh-CN.md)
> **Language**: [English](ads-xteam-bot.md) | [中文](ads-xteam-bot.zh-CN.md)

Ads 跨团队项目跟踪系统的 NLU 层。解析用户自然语言命令，通过多轮对话确认结构化参数，然后将所有写操作委托给 `meta_json_edit.py`。

**触发关键词**: "project start"、"project status"、"todo done"、"T001 done"、"skip"、"block"、"todo add"、"进度"、"status"

---

## 场景 1：查看项目状态

> **你**: `project status`
>
> **AI**: 读取 `runner_meta.json`，渲染 Dashboard 展示当前阶段、待办事项、阻塞项和团队进度。

---

## 场景 2：完成一个 TODO

> **你**: `T003 done`
>
> **AI**: 解析 TODO ID，确认目标，通过 `meta_json_edit.py` 标记为完成，触发依赖链状态机流转（如阶段推进），渲染更新后的状态。

---

## 场景 3：新增手动 TODO

> **你**: `todo add: 和 PM 团队 Review PRD`
>
> **AI**: 创建新的手动 TODO 项，分配到当前阶段，确认新增结果。

---

## 场景 4：更新 TODO 元数据

> **你**: `T005 eta 2026-07-15`
>
> **AI**: 更新指定 TODO 的 ETA 字段，确认变更。

---

## 前提条件

- 目标项目必须已存在 `runner_meta.json`（由项目 intake 创建）
- 通过 SeaTalk bot 使用时，bot proxy 按 `project_id` 路由消息

## 架构

详见 `specs/common/xteam/01-scope-and-workflow.md`（完整工具架构）和 `03-ads-xteam-bot-spec.md`（NLU 规范）。
