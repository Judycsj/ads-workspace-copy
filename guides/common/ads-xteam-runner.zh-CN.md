# Ads XTeam Runner 使用指南

> **Language**: [English](ads-xteam-runner.md) | [中文](ads-xteam-runner.zh-CN.md)

Ads 跨团队 PRD 到验收流程的语义 runner，包含 testing 前的 demo review、
验收前的 release on live、可选 rollout 和最终 biz result review。它负责从
SeaTalk 或测试 harness 消息中提取 intent 和 facts；项目路由、状态流转、
gate 校验、副作用和用户可见回复模板都由 host 系统负责。

**触发关键词**: "ads-xteam-runner", "PRD signed off", "TD signed off",
"coding done", "demo review", "test done", "QA done", "acceptance done",
"release on live", "rollout", "biz result", "participant teams", "PIC",
"effort", "PRD quality check", "TD quality check"

## 典型用法

这个 runner 通常由 Ads Project Tracker 调用，不建议用户直接调用：

```text
@Ads Project Tracker PRD: <link>
@Ads Project Tracker platform BE participates, effort 2.5d
@Ads Project Tracker PRD signed off
```

## 职责

- 从自然语言中提取流程 intent 和可持久化 facts。
- 需要 PRD Required Issues 时调用 `ads-xteam-prd-quality-check`。
- 需要 TD 质检时调用 `ads-xteam-td-quality-check`。
- 返回结构化 JSON，交给 host 做最终校验。

## 边界

- 不拥有、不直接修改 project state。
- 不创建 Jira issue，不流转 Jira 状态。
- 不在 host 未委托时创建 Business Epic 文件。
- 没有当前消息中的显式证据时，不推进 hard gate。
