---
id: advertiser_agent_kb
title: Advertiser Agent 知识库
domain: advertiser-strategy
owner: Brand Ads / Seller Agent
source_refs:
  - https://git.garena.com/shopee/deep/brand-ads/seller-agent/
  - https://git.garena.com/pengjc/shopee-ads-agent
last_updated: 2026-05-05
last_verified_at: 2026-05-05
confidence: low
---
<!-- ads-workspace-gdoc-sync: gdoc_id=18TVBtXP3sBX5wY9TJ4Yh5mKFoe7QzEJkMLUtbTmH1xM gdoc_url=https://docs.google.com/document/d/18TVBtXP3sBX5wY9TJ4Yh5mKFoe7QzEJkMLUtbTmH1xM/edit -->

# Advertiser Agent 知识库

## KB 必要信息索引

| 类别          | 当前索引                                           |
| ----------- | ---------------------------------------------- |
| 后端 repo     | `shopee/deep/brand-ads/seller-agent`           |
| Skills repo | `pengjc/shopee-ads-agent`（后续合并至 ads-workspace） |
| 技术栈         | Python + Claude Code SDK                       |
| 当前阶段        | Phase 1：GMS/SAC HTML 报告                        |

## 范围

本文汇总 `Advertiser Agent`（商家 Agent 平台）的业务背景、技术方案和工程信息。

正文按以下顺序组织：

1. `Business`
2. `Technical`
3. `Engineering`

附录包含：

1. 术语表
2. 资料来源登记

本文不展开以下内容：

- 广告诊断底层数据字段细节
- Claude Code SDK 底层 API 细节

## Business

### 1. 业务背景与目标

#### 1.1 平台定位

`Advertiser Agent` 是面向商家的智能分析与对话平台。

目标是基于商家相关广告数据和大盘数据，综合分析商家在平台的表现情况，并给出优化建议。

#### 1.2 Phase 规划

| Phase | 目标 | 当前状态 |
|---|---|---|
| `Phase 1` | 输出 GMS/SAC 报告，展示在商家平台，让商家能从报告获取信息 | 进行中 |
| `Phase 2` | 建立多轮对话系统，提供平台广告知识答疑、政策咨询、广告质量分析及建议 | TBD |

## Technical

### 1. 技术方案

#### 1.1 核心思路

基于广告诊断的丰富底层数据，结合 Claude Code SDK 建立后端服务，产品侧通过 skill 方式来进行输出的约束。

#### 1.2 Phase 1 实现

前端页面调取后端服务，后端返回渲染的 GMS/SAC HTML 报告，展示给商家。

主要组成：

- 后端服务：基于 Claude Code Python SDK 搭建
- 输出形态：渲染的 HTML 报告（GMS 报告 + SAC 报告）
- 产品约束：通过 skill 定义输出规范

#### 1.3 Phase 2 方案

TBD

## Engineering

### 1. 代码仓库

| 仓库 | 用途 |
|---|---|
| `shopee/deep/brand-ads/seller-agent` | 后端服务，基于 Claude Code Python SDK 搭建 |
| `pengjc/shopee-ads-agent` | Skills，由产品侧主要负责更新和维护，后续合并至 ads-workspace |

## 附录

### 1. 术语表

`GMS 报告`

- 展示商家 GMV 表现的汇总报告

`SAC 报告`

- 展示广告效果与花费的汇总报告（Smart Ads Campaign）

`Skill`

- 产品侧定义的输出规范，用于约束 Agent 的输出格式与内容

### 2. 资料来源登记

#### 说明

可信级别：

- `L1`：代码、接口定义、配置、运行入口
- `L2`：仓库内 README / 正式 markdown
- `L3`：Google Doc
- `L4`：背景理论或历史材料

状态：

- `used`：已进入正文
- `indexed`：已登记但未进入正文
- `todo`：待阅读或待补充

#### 清单

| 来源标识 | 类型 | 主题 | 可信级别 | 状态 | 作用 |
|---|---|---|---|---|---|
| `shopee/deep/brand-ads/seller-agent` repo | 代码 | 后端服务实现 | `L1` | `indexed` | 工程索引 |
| `pengjc/shopee-ads-agent` repo | 代码/配置 | Skills 定义 | `L1` | `indexed` | 工程索引 |
