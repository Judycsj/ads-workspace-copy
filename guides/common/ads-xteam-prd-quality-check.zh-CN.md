# Ads PRD 质检使用指南

> **Contributors**: shuo.zhao, luka.yang, zhikang.piao ｜ **最后更新**：2026-07-01 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-xteam-prd-quality-check.zh-CN.md)

> **Language**: [English](ads-xteam-prd-quality-check.md) | [中文](ads-xteam-prd-quality-check.zh-CN.md)

基于 PRD 正文、评论和 suggestions 做内容质检，找出真正会阻塞 PRD review、TD 准备或工程推进的 Required Issues。显式开启 docs-KB 模式时，可以只读取 workspace 相对路径 `docs/**` 作为背景知识。

如果 PRD 明确把 Advertiser Strategy 列为必要参与方、reviewer 或验收方，质检时还会检查 PRD 是否写清楚他们要验证的测试范围，包括环境、产品类型、验收字段，以及验收目标。

**触发关键词**: "ads-xteam-prd-quality-check", "PRD quality check", "PRD review", "review PRD", "需求质检", "PRD质检", "帮忙review PRD", "check PRD"

## 场景一：质检单个 PRD

> **你**: `Use /ads-xteam-prd-quality-check to review this PRD: <link>`
>
> **AI**: 读取 PRD 正文和可用评论，只输出 Required Issues。

## 场景二：平台侧 PRD 质检

> **你**: `这个 Ads Platform PRD 帮忙质检一下`
>
> **AI**: 重点检查 scope、生命周期、触点一致性、popup/banner/card 优先级、toggle/whitelist、source of truth、fallback 和 rollout 缺口。

## 场景三：数据 PRD 质检

> **你**: `这个数据落表 PRD 看看缺什么`
>
> **AI**: 检查表范围、数据源、字段 schema、粒度、刷新频率、回填、保留周期和数据质量验收。

## 场景四：docs-KB 增强质检

> **你**: `用 ads-workspace docs KB 帮忙质检这个 PRD`
>
> **AI**: 只把 workspace 相对路径 `docs/**` 当作可选背景知识，Required Issues 仍然落回 PRD 内容缺口，输出只包含 Required Issues。

## 场景五：Advertiser Strategy 验收范围检查

> **你**: `这个 PRD 会找 Advertiser Strategy 一起验收，帮我看看还缺什么`
>
> **AI**: 检查 PRD 是否明确写出 Advertiser Strategy 验收所需的验证环境、覆盖产品类型、验收字段，以及验收目标。

## 场景六：Incentive 任务下发 / Seller 预圈选

> **你**: `这个 incentive / reward center 任务下发 PRD 帮忙质检一下`
>
> **AI**: 检查 PRD 是否符合平台常规 incentive 模式：**预圈选 seller 名单 → 批量建 seller 级任务 → 实时事件只激活已建任务**（见 incentive-preselect-lens）。Smart Voucher、FSS/escrow 卡片 whitelist、功能 toggle 等非 task 下发场景不适用。

## 场景七：建议金额 / 平台 min-max 边界

> **你**: `这个 PRD 有建议充值/预算金额，帮忙质检一下`
>
> **AI**: 仅当 PRD 定义**可展示/可执行的建议金额**时适用。检查 **min/max 边界来源**、raw 建议值 **低于 min 或高于 max 时的处理**，以及**两个及以上入口各自展示金额时**的 touchpoint 一致性（见 suggested-amount-bound-lens）。low balance 告警卡（仅 Top Up CTA）、奖励金 1:1 充值规则、数据/算法文档不适用。

## 输出

默认输出保持精简：

```text
Required Issues
1. ...
2. ...
```

在 **discover** 模式下，host metadata 新增 `prd_title`（字符串）和 `prd_summary`（包含 title、summary、background、goal、scope、non_goals、risks 的对象）字段，用于下游 Business Epic 生成。

## 适合的场景

- PRD review 或开发前的 readiness check
- 聚焦内容缺口的需求质检
- SeaTalk bot 的 PRD quality-check 输出

## 不适合的场景

- TD/TRD review
- 代码 review 或实现排障
- 需要读源码、repo README、Jira、Sheet、Figma、TD 或 TRD 的完整 impact analysis
