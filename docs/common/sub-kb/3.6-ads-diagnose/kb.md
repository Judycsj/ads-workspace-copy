---
id: ads_diagnose_kb
title: Ads Diagnosis 诊断知识库
domain: diagnosis
owner: Ads Strategy / Ads Diagnosis
source_refs:
  - https://docs.google.com/document/d/16h4flvP0QqUavXm6Qj3-ZxtuHJ2_oUpCNi9MX79t0Ss/edit?tab=t.0#heading=h.nz7h3c8ub5zq
  - https://docs.google.com/document/d/16h4flvP0QqUavXm6Qj3-ZxtuHJ2_oUpCNi9MX79t0Ss/edit?tab=t.99bxjjdo4nam#heading=h.rcgimi4vua9y
  - https://docs.google.com/spreadsheets/d/1XiSNynN0uFVacvqqRrcrwokcdre9qEsLyJgSKmP4M54/edit?pli=1&gid=135623426#gid=135623426
  - https://docs.google.com/spreadsheets/d/1ZrYRw-jdEhdIGxF-NuRcOpKswEvqK_bscvbFtoZW1rU/edit?gid=1594221342#gid=1594221342
  - https://docs.google.com/spreadsheets/d/1Cnop5beSDfF-JOZbmCk7HnWi8H1HHECNUJImyPsG7Do/edit?gid=394519611#gid=394519611
  - https://docs.google.com/spreadsheets/d/11kUvqDCyiKdeaDYTWM4yK2NTiwJVAtnLEHd177BkldQ/edit?usp=sharing
  - https://docs.google.com/spreadsheets/d/1AiT7Kh71SUfFi4cUPradQFNbP6kBbC5A0XhGqmSh-tM/edit?gid=4452961#gid=4452961
  - skills/common/ads-diagnose/SKILL.md
  - skills/common/ads-diagnose/references/factual_nodes.md
  - skills/common/ads-diagnose/references/table_info.md
  - skills/common/ads-biz-diagnose/SKILL.md
  - skills/common/ads-biz-diagnose/references/detection.md
  - skills/common/ads-biz-diagnose/references/attribution.md
  - skills/common/ads-biz-diagnose/references/factual_nodes.md
  - skills/common/ads-biz-diagnose/references/table_info.md
  - skills/common/ads-dqc-report/SKILL.md
  - skills/personal/qianqian.pu/ads-diagnose-batch-top1/SKILL.md
  - skills/personal/qianqian.pu/ads-diagnose-batch-top1/scripts/batch_top1_to_gsheet.py
  - https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/merge_requests/1237/diffs
  - https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/skills/common/ads-dqc-report
  - https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/schedules
  - https://git.garena.com/shopee/deep/paidads-alg/-/blob/qq-diag/services/ads_diagnosis/services/daily_overbidding_report.py
  - https://git.garena.com/shopee/deep/paidads-alg/-/blob/qq-diag/services/ads_diagnosis/services/dod_schedule.py
  - https://git.garena.com/shopee/deep/paidads-alg/-/blob/qq-diag/services/ads_diagnosis/services/overbidding_monitor_service.py
  - https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.ads_engine.common_tool.ads_diagnosis
  - https://datasuite.shopee.io/dashboard/dashboard/b71b276a-2275-4b61-9cd1-6f735f0cdba0/normal?page=1766542130070_15p4s
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11275107
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10957251
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10957266
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10852061
  - https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11117076
last_updated: 2026-05-21
last_verified_at: 2026-05-21
confidence: medium
---
<!-- ads-workspace-gdoc-sync: gdoc_id=191JQyhGWFn1Vu6yMJBOwNBwqEqexv00BeE-RcgXKLnY gdoc_url=https://docs.google.com/document/d/191JQyhGWFn1Vu6yMJBOwNBwqEqexv00BeE-RcgXKLnY/edit -->

# Ads Diagnosis 诊断知识库

> **Contributors**: qianqian.pu ｜ **最后更新**：2026-05-21 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/sub-kb/3.6-ads-diagnose/kb.md)

## KB 必要信息索引

| 类别 | 当前索引 |
|---|---|
| 代码仓库 GitLab 路径 | `shopee/search_recommend/ai-copilot/ads-workspace`（诊断 skill / KB / 批量 top1 case GSheet）；[shopee/deep/paidads-alg qq-diag](https://git.garena.com/shopee/deep/paidads-alg/-/tree/qq-diag)（Bot、每日推送、历史 Ads diagnosis manual SOP） |
| 核心服务 SDU 路径 | 诊断 Bot 通过 Space 发布，deployment 路径为 `shopee.mp_search_recommendation_ads.paidads.ads_engine.common_tool.ads_diagnosis`，入口：https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.ads_engine.common_tool.ads_diagnosis；已知生产域名 `diagnosis-bot.shopee.io`，测试域名 `diagnosis-bot.test.shopee.io` |
| ConfigCenter namespace | `ads-diagnose` skill 本身以本地 Markdown 规则和 ClickHouse 查询为主** |
| DataSuite Dashboard / DQC | 诊断 Dashboard：[DataSuite Dashboard](https://datasuite.shopee.io/dashboard/dashboard/b71b276a-2275-4b61-9cd1-6f735f0cdba0/normal?page=1766542130070_15p4s)；full link DQC 产表入口为 `Workflows/ads_algo/ads_diagnosis/monitor/unify_full_link_table_dqc/` 和 [DataSuite 10957251](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10957251) / [DataSuite 10957266](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10957266)，performance / union ads DQC 产表入口分别为 [DataSuite 10852061](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10852061) / [DataSuite 11117076](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11117076)；DQC 告警逻辑入口为 [DataSuite 11275107](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11275107) |
| DQC 阈值与告警群 | Full link DQC 阈值：[GSheet full link DQC 阈值配置](https://docs.google.com/spreadsheets/d/11kUvqDCyiKdeaDYTWM4yK2NTiwJVAtnLEHd177BkldQ/edit?usp=sharing)，告警群 `Unify S&R&A Full Link Log`；Performance / Union Ads DQC 阈值：[GSheet performance / union ads DQC 阈值配置](https://docs.google.com/spreadsheets/d/1AiT7Kh71SUfFi4cUPradQFNbP6kBbC5A0XhGqmSh-tM/edit?gid=4452961#gid=4452961)，告警群 `【ADKP】广告诊断建设` |
| 关键 Kafka topic | 诊断宽表不直接消费 Kafka；原始效果、扣费、订单、tracking 事件链路请转 `3.5-ads-data/kb.md`。本 KB 只沉淀诊断聚合表和 ClickHouse 查询入口 |
| 核心 Hive / ClickHouse 表名 | `mkplpaidads_search_ads.ads_union_key_metrics_daily__reg_s0_live`；`mkplpaidads_search_ads_ads_debug.ads_union_key_metrics_daily__reg_s0_live`；`mkplpaidads_search_ads_ads_diagnosis.ads_union_key_metrics_daily__reg_s0_live`（BR）；`mkplpaidads_search_ads_ads_debug.dwd_ads_index_status_live`；`mkplpaidads_search_ads_ads_debug.unactive_ads_reason_metrics`；`mkplpaidads_search_ads.static_ads_info_metrics`；`mkplpaidads_search_ads.full_link_funnel_metrics_daily__reg_s0_live`；`mkplpaidads_search_ads.ultra_core_bidding_log_ads_merge_hourly`；`mkplpaidads_search_ads.unify_search_ext_dqc_metrics`；`mkplpaidads_search_ads.unify_rcmd_ext_dqc_metrics`；`mkplpaidads_search_ads_ads_debug.performance_dqc_daily_metrics`；`mkplpaidads_search_ads_ads_debug.union_ads_dqc_daily_metrics`；`mkplpaidads_search_ads.ads_overall_key_metrics_daily__reg_s0_live`；`mkplpaidads_search_ads.overall_supply_budget_metrics_daily__reg_s0_live`；`mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live` |
| 字段描述文档 | 诊断宽表字段描述：[GSheet 诊断宽表字段说明](https://docs.google.com/spreadsheets/d/1XiSNynN0uFVacvqqRrcrwokcdre9qEsLyJgSKmP4M54/edit?pli=1&gid=135623426#gid=135623426)；takerate 底表字段描述：[GSheet takerate 底表字段说明](https://docs.google.com/spreadsheets/d/1ZrYRw-jdEhdIGxF-NuRcOpKswEvqK_bscvbFtoZW1rU/edit?gid=1594221342#gid=1594221342) |
| 诊断 skill 入口 | Case 诊断：`skills/common/ads-diagnose/SKILL.md`，支持 ID 诊断、异常类型 top case 诊断、已知异常归因；大盘诊断：`skills/common/ads-biz-diagnose/SKILL.md`（Detection 大盘日报 / 周报扫描，Attribution 已知大盘异常归因）；DQC 周报：`skills/common/ads-dqc-report/SKILL.md` |
| Weekly case 记录 | [GSheet weekly case 记录](https://docs.google.com/spreadsheets/d/1Cnop5beSDfF-JOZbmCk7HnWi8H1HHECNUJImyPsG7Do/edit?gid=394519611#gid=394519611)，用于周级 top case review、人工标注和历史 case 回归沉淀 |
| Bot / 批量产出代码入口 | 超收 Bot / 每日报告：[daily_overbidding_report.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/qq-diag/services/ads_diagnosis/services/daily_overbidding_report.py)；批量 top1 case GSheet：`skills/personal/qianqian.pu/ads-diagnose-batch-top1/SKILL.md` / `scripts/batch_top1_to_gsheet.py`（实现来源：[MR 1237](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/merge_requests/1237/diffs)）；当前服务器定时链路还涉及 [dod_schedule.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/qq-diag/services/ads_diagnosis/services/dod_schedule.py) 和 [overbidding_monitor_service.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/qq-diag/services/ads_diagnosis/services/overbidding_monitor_service.py) |
| DQC 周报 skill | `skills/common/ads-dqc-report/SKILL.md`，基于 SG ClickHouse 的 `performance_dqc_daily_metrics` 和 `union_ads_dqc_daily_metrics` 生成周级覆盖率 / 均值对比报告，默认保存到 `docs/team/00.paid-ads-dev/17.ads-dqc-report/` |
| 定时任务配置 | ads-workspace 统一定时任务配置目录为 [`schedules/`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/schedules)，用于配置 Ads DQC 周报等例行任务；新增大盘或其他诊断任务时，也应同步补齐对应 schedule 配置 |
| 底表生产任务索引 | 相关 DataSuite / Workflow 产表和 OneData 导 CK 入口整理在 §13，来源为 TD 的 [相关数据底表生产任务](https://docs.google.com/document/d/16h4flvP0QqUavXm6Qj3-ZxtuHJ2_oUpCNi9MX79t0Ss/edit?tab=t.99bxjjdo4nam#heading=h.rcgimi4vua9y) tab |

## 阅读指引

本文档是 Ads 诊断体系的知识入口，覆盖单 case 诊断和大盘诊断的目标、数据契约、异常口径、归因模块、报告格式和持续评估方式。

- `§0-§2` 说明诊断体系是什么、为什么做、和当前 `ads-diagnose` / `ads-biz-diagnose` skill 的边界。
- `§3-§5` 是数据层和指标层：实体层级、底表血缘、核心字段、T-1 数据与 DQC。
- `§6-§7` 是诊断逻辑层：A/B 异常类型、R 归因节点、方向过滤、因果链。
- `§8-§10` 是执行层：ID 诊断、异常类型诊断、已知异常归因、大盘诊断、报告输出契约。
- `§11-§15` 是运营层：Bot 推送、批量 GSheet / 会议材料、DQC、case 反馈、自演化、常见问答和待补充事项。

Agent 默认处理顺序：

1. 用户要查单个 `ads_id` / `campaign_id` / `shop_id` / `item_id` 的效果异常时，优先使用 `ads-diagnose` skill。
2. 用户给出 A/B 异常类型，要求“top case / 找 case / 某天某类异常 top1”时，也使用 `ads-diagnose` skill 的异常类型诊断流程。
3. 用户要查 region / entrance / 广告大盘的异常日报、预算、TR 维度大盘归因或大盘 top contributing segment 时，优先使用 `ads-biz-diagnose` skill。
4. 用户只问诊断体系、口径、底表、字段、报告结构时，先用本 KB 回答；涉及当前线上数值时必须重新查表。
5. 本 KB 写稳定口径和查询路径，不保存某天 case 的静态诊断结论；历史 case 只能作为 few-shot，不应当作当前 truth。
6. Bot / GSheet / DQC 代码中可能包含凭据或环境配置；KB 只记录职责、调用链和路径。

## 0. 一句话摘要

Ads Diagnosis 是面向广告投放异常的可复用诊断归因体系：通过统一诊断宽表、DQC、Dashboard 和 skill 规则，把单个广告 / campaign / shop 或大盘指标的异常拆解为“异常是否成立、异常发生在哪个链路环节、哪些 R 归因节点命中、应优先修什么”。

当前落地分两层：

- **Case 诊断**：围绕单个广告实体做 ID 诊断，或按 A/B 异常类型筛选 top case 后归因；也支持已知异常归因。核心执行入口是 `skills/common/ads-diagnose/SKILL.md`。
- **大盘诊断**：围绕 region / entrance / business aggregate 做异常检测和归因，目标覆盖预算、TR、场景维度异常和年周期聚合数据，核心执行入口是 `ads-biz-diagnose/SKILL.md`。

## 1. 背景与目标

广告实际投放中常见问题包括预算消耗缓慢、超收 / 欠收、转化效果不佳、生命周期短、突然掉量或爆量。这些问题会影响业务收入、广告主满意度和排查效率。诊断体系的目标不是只给一个“可能原因”，而是建立可复用的事实节点和归因树，让人工与 agent 在同一口径下定位问题。

TD 中定义的建设目标分三类：

| 目标 | 说明 |
|---|---|
| 自定义 skills | 基于算法自定义 skill 的诊断和归因条件，对 campaign / ads / shop 做问题诊断，输出细化指标展示 |
| 底表数据监控报警 | 建立统一底表，监控底表及上游关键字段覆盖率，维护数据稳定可用，便于 case 分析对齐口径 |
| Dashboard 看板展示 | 维护看板数据稳定 T-1 更新，支持快速查询 case，减少人工反复跑 SQL 的成本 |

验收标准：

- 完善底层数据建设。
- Dashboard 数据稳定 T-1 更新。
- Ads Bot 诊断准确率达到 `>=80%`。

## 2. 项目分层与职责边界

TD 将诊断能力拆成 KA1-KA5：

| KA | 主题 | 目标 | KB 落点 |
|---|---|---|---|
| KA1 | 底表建设与字段定义 | 完善统一宽表，接入 Seller Agent 需要的基础数据，对新增字段接入 DQC 和覆盖率报警 | `§4`、`§5`、`§11` |
| KA2 | 完善case归因， 定义各类主因case的逻辑诊断树，丰富诊断skill | 定义异常 case 类型和判定标准，梳理诊断逻辑树，沉淀叶子归因节点，适配 ads / campaign / shop 粒度 | `§6`、`§7`、`§8` |
| KA3 | Case 反馈评估与自演化 | 批量诊断 top case 到 GSheet，周级人工 review，按历史 case 回归测试并优化 skill | `§11`、`§12` |
| KA4 | 大盘诊断底表 | 大盘 ad load 包含未投广部分的平台数据，补齐年周期聚合表 | `§9`、`§12` |
| KA5 | 大盘归因 | 定义大盘异常类型和逻辑树，增加预算、TR、场景维度异常检测和展示形式 | `§9`、`§11` |

边界说明：

- `ads-diagnose` 关注 case 级诊断，既支持具体 ID 诊断，也支持给定 A/B 异常类型后筛 top case 并归因；必须以具体 ID / 日期 / 异常类型为中心取证。
- `ads-biz-diagnose` 关注大盘异常，不应把单 case 的 R 节点直接套到 region 大盘上。
- 涉及订单归因、tracking、扣费原始链路时，需要转到 Ads Data / Deduction / Tracking 侧知识库继续深挖。

## 3. 广告实体层级

诊断时先识别 ID 属于哪一层，否则后续聚合口径会错位。

| 层级 | 实体 | 常见 ID | 核心职责 |
|---|---|---|---|
| L1 | Account / Shop | `shop_id` | 账户余额、店铺级聚合、多个 campaign 共享账户余额 |
| L2 | Campaign | `campaign_id` | 日预算、出价方式、Target ROI / Simple ROI 区间、投放策略 |
| L3 | Ads | `ads_id` | 参与竞价的最小广告单元，继承 campaign 策略 |
| L4 | 投广载体 | `item_id` / shop / video / stream room | 实际展示对象；Product Ads 对应 item，Shop / Video / Live 有各自载体 |

诊断下钻默认路径：

```text
input id
  -> 识别 id 层级、region、shop_id、campaign_id、ads_id、item_id
  -> campaign / shop 聚合异常判断
  -> ads 粒度定位主贡献广告
  -> entrance 场景拆分
  -> status / inactive / budget / model / bidding / funnel 归因
```

## 4. 数据层：统一宽表与关键依赖

### 4.1 主宽表

单 case 诊断以 `ads_union_key_metrics_daily__reg_s0_live` 为主。该表是四种粒度的 UNION ALL：

字段描述文档：[GSheet 诊断宽表字段说明](https://docs.google.com/spreadsheets/d/1XiSNynN0uFVacvqqRrcrwokcdre9qEsLyJgSKmP4M54/edit?pli=1&gid=135623426#gid=135623426)

| `type` | 粒度 | 用途 |
|---|---|---|
| `ads` | ads 粒度 | 逐广告下钻、entrance 拆分、模型 / 漏斗 / 出价指标定位 |
| `campaign` | campaign 粒度 | campaign 级异常检测、预算 / TROI / cost_ratio 归因 |
| `item` | item 粒度 | item 级效果和价格变化辅助判断 |
| `shop` | shop 粒度 | shop 级异常聚合；部分 B 系列也可由 campaign 聚合得到 |

生产血缘简化如下：

```text
mp_paidads.dwd_advertise_performance_di__reg_s0_live
  + full_link_funnel_metrics_daily__reg_s0_live
  + static_ads_info_metrics
  + dim_entry_point_mapping_v2
  + dim_exchange_rate
      -> ads_advertise_key_metrics_daily
      -> ads_campaign_key_metrics_daily / ads_item_key_metrics_daily / ads_seller_key_metrics_daily
      -> ads_union_key_metrics_daily
      -> ClickHouse ads_union_key_metrics_daily__reg_s0_live
```

ClickHouse 查询入口：

| Region | ClickHouse DB | 说明 |
|---|---|---|
| ID / TH / PH / VN / MY / TW / SG | `mkplpaidads_search_ads_ads_debug` | 默认 SG 集群 |
| BR | `mkplpaidads_search_ads_ads_diagnosis` | US-VA2 集群，表名前缀不同 |

### 4.2 状态与停投表

| 表 | 用途 |
|---|---|
| `mkplpaidads_search_ads_ads_debug.dwd_ads_index_status_live` | 查询广告可见性、状态、操作事件，如 `OK`、`change_budget`、`DELETE`、索引操作等 |
| `mkplpaidads_search_ads_ads_debug.unactive_ads_reason_metrics` | 查询不在投广告原因，辅助判断 R1.5 Ads 停投 / 投放时长减少 |

### 4.3 出价与 DQC 相关表

| 表 | 用途 |
|---|---|
| `mkplpaidads_search_ads.ultra_core_bidding_log_ads_merge_hourly` | Ultra Core 小时 / 15min 证据，支持数据收集异常、超投专项和 MPC / bidding 排查 |
| `mkplpaidads_search_ads_ads_debug.performance_dqc_daily_metrics` | performance DQC 日级指标 |
| `mkplpaidads_search_ads_ads_debug.union_ads_dqc_daily_metrics` | union 宽表 DQC 日级指标 |

### 4.4 大盘诊断表

| 表 | 用途 |
|---|---|
| `mkplpaidads_search_ads.ads_overall_key_metrics_daily__reg_s0_live` | 大盘核心指标表 |
| `mkplpaidads_search_ads.overall_supply_budget_metrics_daily__reg_s0_live` | supply / budget 大盘归因 |
| `mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live` | takerate 底表，支持按 entrance / pricingType / seller_type 等维度拆解平台侧 GMV、net ads rev 和 take rate |

takerate 底表字段描述文档：[GSheet takerate 底表字段说明](https://docs.google.com/spreadsheets/d/1ZrYRw-jdEhdIGxF-NuRcOpKswEvqK_bscvbFtoZW1rU/edit?gid=1594221342#gid=1594221342)

## 5. 核心指标语义

| 指标 | 语义 | 常见用途 |
|---|---|---|
| `revenue_usd` | 广告花费，诊断报告中通常称为 `cost` | 超收 / 欠收、cost 掉量 / 爆量 |
| `advv_usd` | 目标 GMV 对应的目标消耗，CPA 类由 `broad_gmv * target_cir` 得到 | Target 类 cost_ratio |
| `broad_gmv_usd` | 宽口径 GMV | ROI、Simple 类超欠收、GMV 掉量 |
| `direct_gmv_usd` | 直接归因 GMV | ads vs platform 问题区分 |
| `ads_imp` / `ads_clk` / `ads_broad_order` | 曝光 / 点击 / 宽口径订单 | CTR、CVR、漏斗质量 |
| `target_roi` / `idx_roi_upperbound` | Target / Simple 的 ROI 目标或上界 | R1.1 TROI 变化 |
| `daily_budget` / `rt_daily_budget_min_by_imp_v2` / `account_balance_shop` | 日预算、实时预算约束、账户余额 | R1.2 / R1.3 预算余额归因 |
| `final_coef` / `coef_sum_by_imp` | 出价系数 | R4/R5/R6 调控、死亡螺旋、广告位质量 |
| `after_recall_num` / `after_prerank_num` / `after_rank_num` / `after_mixrank_num` | 全链路漏斗数量 | R5 漏斗突变 |
| `pctr_sum_by_imp` / `pcr_broad_sum_by_clk` / `daily_pgmv_sum_last_7d_clk` | 预估值聚合 | R3 PCOC 偏差 |
| `pcr_direct_fail_imp_cnt` | pCR 预估失败曝光数 | R3.4 模型预估失败 |
| `ultra_core_rev` / `ultra_core_advv` | Ultra Core 收集口径 | R4.3/R4.4 数据收集异常 |
| `mpc_e_gmv` / `mpc_e_cost` | MPC 预估 GMV / cost | R4.7/R4.8 MPC ROI 高低估 |

常用派生口径：

| 口径 | 公式 |
|---|---|
| `cost_ratio_1d` | `revenue_usd_0 / advv_usd_0` |
| `cost_ratio_7d` | `SUM(revenue_usd 近 7 天) / SUM(advv_usd 近 7 天)` |
| `roi` | `broad_gmv_usd / revenue_usd` |
| `ctr` | `ads_clk / ads_imp` |
| `cvr` | `ads_broad_order / ads_clk` |
| `prerank_rate` | `after_prerank_num / after_recall_num` |
| `rank_rate` | `after_rank_num / after_prerank_num` |
| `mixrank_rate` | `after_mixrank_num / after_rank_num` |
| `pctr_pcoc` | `pctr_sum_by_imp / ads_clk` |
| `pcr_pcoc` | `pcr_broad_sum_by_clk / ads_broad_order` |
| `pgmv_pcoc` | `daily_pgmv_sum_last_7d_clk / broad_gmv_usd` |

## 6. 异常类型节点

### 6.1 Campaign / Ads 级 A 系列

| 编号 | 名称 | 检测口径 |
|---|---|---|
| A1 | 7d 超收 | `cost_ratio_7d > 1.25` |
| A2 | 7d 欠收 | `cost_ratio_7d < 0.75` |
| A3 | 1d 超收 | `cost_ratio_1d > 1.25` |
| A4 | 1d 欠收 | `cost_ratio_1d < 0.75` |
| A5 | 广告 ROI 骤降 | `roi_0 / roi_1 < 0.5` 或 `roi_7d / roi_prev_7d < 0.7` |
| A6 | advv 骤降 | `advv_usd_0 / advv_usd_1 < 0.5` |
| A7 | 广告 GMV / order 骤降 | `broad_gmv_usd_0 / broad_gmv_usd_1 < 0.5` 或 `ads_broad_order_0 / ads_broad_order_1 < 0.5` |
| A8 | 广告 cost 骤降 | `revenue_usd_0 / revenue_usd_1 < 0.5` |
| A9 | 广告 cost 骤涨 | `revenue_usd_0 / revenue_usd_1 > 2.0` |
| A10 | 不起量低消耗 | 近 7 天 `revenue_usd < 1 * cpa` |
| A11 | CVR 转换效率低 | `ads_clk > 100 AND ads_broad_order < ads_clk * 0.01` 连续 2 天+ |
| A12 | CTR 转换效率低 | `ads_imp > 100 AND ads_clk < ads_imp * 0.01` 连续 2 天+ |
| A13 | CVR 转换效率骤降 | `cvr_0 / cvr_1 < 0.5` |
| A14 | CTR 转换效率骤降 | `ctr_0 / ctr_1 < 0.5` |
| A15 | 超投 loss / Rev Loss | `rev_loss_ratio > 0.2`；R11 仅在 A15 成立后使用 |

### 6.2 Shop 级 B 系列

Shop 级异常基于 `shop_id + grass_region` 下所有 campaign 聚合后判断。

| 编号 | 名称 | 检测口径 |
|---|---|---|
| B1-B4 | 店铺 7d / 1d 超收或欠收 | 同 A1-A4，但对 shop 下 campaign 聚合 |
| B5 | 店铺广告 ROI 骤降 | `roi_0 / roi_1 < 0.5` 或 `roi_7d / roi_prev_7d < 0.7` |
| B6 | 店铺 advv 骤降 | `advv_0 / advv_1 < 0.5` 或近 3 天 / 前 3 天 `<0.5` |
| B7 | 店铺平台 GMV / order 骤降 | 平台侧 GMV 或 order 环比 `<0.5` |
| B8 | 店铺广告 GMV / order 骤降 | 广告侧 GMV 或 order 环比 `<0.5` |
| B9-B10 | 店铺广告 cost 骤降 / 骤涨 | cost 环比 `<0.5` 或 `>2.0` |
| B11 | 店铺不起量低消耗 | 店铺所有 campaign 近 7 天总 cost 低于 `N * avg_cpa` |
| B12-B15 | 店铺 CTR / CVR 低或骤降 | 同 A11-A14，但对 shop 聚合 |

### 6.3 TD 中的日报类异常口径

TD 的 case 异常日报重点关注以下 top case 类型：

| 类型 | 口径 |
|---|---|
| 超收赔付 | Target / GMS Target / AdGroup：`advv_1d < cost_1d * 0.8` 或 `advv_7d < cost_7d * 0.8`；Simple / GMS Simple：`broad_gmv < cost * roi_lower_bound` |
| 超投 Loss | `rev_loss_ratio = (expect_deduction_price_sum_valid - gross_deduction_price_sum) / expect_deduction_price_sum_valid > 20%` |
| 未撞线欠收 | Target：`advv > cost * 1.2 AND budget_usage < 90%`；Simple：`broad_gmv > cost * roi_upper_bound AND budget_usage < 90%` |
| GMV 掉量 50%+ | `gmv_coef / gmv_overall_coef < 50%`，即自身 GMV 跌幅显著大于大盘 |
| Cost 暴涨 100%+ | `ads_coef / overall_coef > 200%`，即自身 cost 增幅显著大于大盘 |

## 7. 归因节点体系

归因节点使用 `R{一级}.{二级}`。每个节点有 `role`：

- `trigger`：触发因素，如预算、TROI、余额、投放时长变化。
- `amplifier`：放大因素，如模型高估 / 低估、预估失败。
- `direct`：直接原因，如停投、预算撞线、出价调控、特定场景异常。

一级模块如下：

| 模块 | 名称 | 主要判断 |
|---|---|---|
| R1 | Campaign / Ads 自身原因 | TROI、budget、账户余额、campaign / ads 状态、广告质量 |
| R2 | 商品自身原因 | item price 变化、商品质量 / 评价 / 库存人工检查 |
| R3 | 模型预估异常 | pGMV / pCTR / pCR PCOC 偏差、预估失败率 |
| R4 | 出价调控策略异常 | 滑动窗口、Ultra Core 数据收集、调控速度、MPC ROI、coef 死亡螺旋 |
| R5 | 广告链路异常 | recall / prerank / rank / mixrank 数量和通过率突变 |
| R6 | 广告位质量坍塌 | 低 coef / 低 eCPM / mixrank 下滑，CTR 稳定但 CVR 接近 0 |
| R7 | Shop 级别问题 | 排除广告位问题后，所有场景 CVR=0 或 Seller Center 侧限制 |
| R8 | 外部 / 环境因素 | 平台整体流量、竞争环境变化 |
| R9 | Shop 级别聚合归因 | 多 campaign 聚合效应、单 campaign 主导、平台 vs 广告区分 |
| R10 | 场景维度异常 | 某 entrance 明显超收 / 欠收 |
| R11 | 超投专项归因 | A15 成立后才看剩余预算跳变和 15min 流量尖峰 |

方向过滤是诊断准确率的关键：

- 超收方向只把高估类 R3 节点计入 R3 一级模块，例如 `pGMV 高估`、`pCTR 高估`、`pCR 高估`。
- 欠收方向只把低估类 R3 节点计入 R3 一级模块。
- 方向不匹配但公式命中的节点可以作为旁证展示，但不能进入主因果链和一级模块总结。
- R11 不是通用诊断步骤；只有 A15 成立，或用户明确要求排查超投 loss 且数据验证成立时，才执行 R11。

## 8. Case 诊断工作流

### 8.1 模式判定

| 用户输入 | 模式 | 行为 |
|---|---|---|
| 给出 ID，要求诊断 / 排查 / 看异常 | ID 诊断 | 识别 ID -> 查询窗口数据 -> 自动检测 A/B 异常 -> 对命中异常归因 |
| 给出异常类型，要求 top case | 异常类型诊断 | 按指定异常公式筛 top case -> 对 top case 归因 |
| 给出 ID + 日期 + 已知异常类型，问原因 | 已知异常归因 | 只验证指定异常是否成立 -> 围绕该异常归因 |

### 8.2 标准查询窗口

| 输入 | 查询窗口 |
|---|---|
| 给定日期 D | 建议 `D-7 ~ D+5`，至少覆盖异常日前后趋势 |
| 给定日期范围 `[D1, D2]` | 建议 `D1-3 ~ D2+5` |
| 未给日期 | 默认 `today()-7 ~ today()`，但必须说明数据最新分区 |

原因：只看诊断日附近 1-2 天容易漏掉余额触底、coef 死亡螺旋、恢复期和大盘基线。

### 8.3 诊断步骤

1. **ID 识别**：查询 UNION 表，识别输入 ID 是 `ads_id`、`campaign_id`、`item_id` 还是 `shop_id`，并确定 region、shop、campaign、ads、item。
2. **基础趋势**：按天聚合 cost、advv、GMV、imp、clk、order、ROI、CTR、CVR、budget、balance、coef。
3. **异常判断**：ID 诊断遍历 A/B 异常；异常类型诊断和已知异常归因只验证指定异常。
4. **Ads 下钻**：campaign 或 shop 异常必须定位主贡献 ads / campaign，避免把聚合异常误归因到所有子对象。
5. **Entrance 拆分**：按入口拆 `revenue_usd / advv_usd`、GMV、imp、clk、order，识别 R10 场景维度异常。
6. **状态与停投**：查 STATUS 和 INACTIVE 表，关联投放状态、操作时间和效果变化。
7. **归因节点判定**：逐个评估 R 叶子节点，再汇总一级模块。
8. **因果链**：只用命中且方向匹配的节点串联或并联成因果链。
9. **修复建议**：按主根因给修复优先级，且摘要、因果链、P0 修复建议三处力度保持一致。

## 9. 大盘诊断工作流

大盘诊断面向 region / entrance / pricing type / ad load / supply budget / take rate 等聚合对象，不能直接套单 case 的 ID 诊断逻辑。

正式执行入口为 `skills/common/ads-biz-diagnose/SKILL.md`。该 skill 分为两个模式：

| 模式 | 触发场景 | 输出 |
|---|---|---|
| Detection | 用户要“日报 / 周报 / WTD / MTD / 大盘巡检 / 有没有异常”时，按周期主动扫描大盘指标 | Daily Detection Report，默认存到 `docs/team/00.paid-ads-dev/16.ads-daily-report/` |
| Attribution | 用户已知某个大盘指标异常，例如 `take_rate`、`rev`、`advv`、`platform_gmv`、预算或达标率涨跌，要找原因 | Attribution Report，按 region / entrance / pricingType / 预算 / TR 等维度深度归因 |

详细规则分别见 `skills/common/ads-biz-diagnose/references/detection.md` 和 `skills/common/ads-biz-diagnose/references/attribution.md`；表结构与 O/OR 节点定义见同目录的 `table_info.md`、`factual_nodes.md`。

TD 对大盘方向的要求：

- ad load 需要包含未投广部分的平台数据。
- 年周期数据需要新产出聚合表。
- 大盘异常需要定义独立的异常类型和判定标准。
- 大盘归因需要覆盖预算、TR、by 场景异常检测。
- 展示形式复用 case 异常日报，但增加大盘异常视图。

推荐大盘诊断路径：

```text
region / date / metric
  -> 查询 ads_overall_key_metrics_daily / supply_budget / take rate / DQC
  -> 与历史窗口、周同比、年周期或大盘基线对比
  -> 按 entrance / pricing_type / campaign_type / budget/TR 切片
  -> 找 top contributing segment
  -> 回到 case 级 skill 抽样验证 top contributors
```

## 10. 报告输出契约

诊断报告必须包含：

| 模块 | 要求 |
|---|---|
| 上下文 | 模式、指定异常、ID 识别、region、时间窗、pricing type、目标 ROI |
| 摘要 | 1-3 句说明异常是否成立、主根因是什么、影响方向 |
| 异常检测 | 列出命中异常；未命中异常可合并，但必须有关键排除数值 |
| 根因归因合表 | 一级模块 R1-R11 必须全覆盖；模块汇总行 + 命中叶子节点；四态为命中 / 未命中 / 证据不足 / 不适用 |
| 命中根因与因果链 | 只使用方向匹配且计入一级模块的命中节点 |
| PCOC & 漏斗汇总 | 覆盖完整查询窗口，不只贴诊断日前后少量样本 |
| 7 天聚合 | cost_7d、advv_7d、cost_ratio_7d、GMV、orders 等 |
| 一级模块归因总结 | 只汇总命中的一级模块，按 R 编号升序 |

四态判定原则：

- **命中**：节点公式满足，数字依据必须写成实际值与阈值的比较。
- **未命中**：字段可计算但不满足，也要给关键排除数值。
- **证据不足**：缺字段、缺查询或缺外部基准，必须写清楚缺什么。
- **不适用**：前提不成立，例如 single campaign 诊断中的 R9，或 A15 未成立时的 R11。

## 11. Bot 推送与报告产出

### 11.1 超收 Bot 推送

超收告警已部署在服务器上，面向 SeaTalk 群推送每日超收监控。Bot 服务通过 Space 发布：

```text
https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.ads_engine.common_tool.ads_diagnosis
```

对应 deployment 路径：

```text
shopee.mp_search_recommendation_ads.paidads.ads_engine.common_tool.ads_diagnosis
```

用户指定的代码入口为 [daily_overbidding_report.py](https://git.garena.com/shopee/deep/paidads-alg/-/blob/qq-diag/services/ads_diagnosis/services/daily_overbidding_report.py)。

当前本地代码中，服务器定时链路还涉及：

| 文件 | 职责 |
|---|---|
| `services/dod_schedule.py` | 定时任务入口；`env=live` 且 `INDEX=0` 时每天执行统计任务和超收监控任务 |
| `services/overbidding_monitor_service.py` | 超收监控实际推送链路：查 top case、生成 HTML、发 SeaTalk markdown |
| `services/html_service.py` | 生成可点击的 HTML 详情页，生产域名为 `diagnosis-bot.shopee.io/static/`，测试域名为 `diagnosis-bot.test.shopee.io/static/` |

定时行为：

| 任务 | 触发 | 输出 |
|---|---|---|
| Bot 使用统计 | `dod_schedule.py` 中 `schedule.every().day.at("10:00")` | SeaTalk markdown，包含统计时间范围、总使用用户数、总查询次数、最近一天使用量 |
| 超收监控 | `dod_schedule.py` 中 `schedule.every().day.at("10:10")` | SeaTalk markdown，包含超收监控日报、统计周期、各 region top case 超收金额汇总、HTML 详情链接 |

超收监控口径：

- 数据源：`ads_case_key_metrics_daily`。
- 告警群：`【ADKP】广告诊断建设`。
- 默认监控 region：`ID / TH / PH / VN / BR / MY / TW / SG`。
- BR 查询 US-VA2 集群 `mkplpaidads_search_ads_ads_diagnosis`，其他 region 查询默认 YTL 集群 `mkplpaidads_search_ads_ads_debug`。
- 诊断日默认取“所有监控 region 数据都齐全”的最新日期；如果 BR 与非 BR 日期不齐，会取更保守的 fallback 日期。
- 判定标准：`cost_ratio_7d = cost_7d / advv_7d > 1.25`，且 `over_amount_7d = cost_7d - advv_7d > 0`。
- 排序：每个 region 取 top N，`overbidding_monitor_service.py` 默认 `top_n = 5`。
- 详情页：对每个 case 继续查询近 7 天基础信息，包括 cost、advv、gmv、order、recall/prerank/rank、pid_coef、item_price、imp、active_hour，并生成 HTML 报告。

### 11.2 批量 top1 case 产出 GSheet

批量 case 产出用于周会材料、归因 review、历史 case 回归和 skill 迭代验证。当前主入口以 [MR 1237](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/merge_requests/1237/diffs) 新增的 `ads-diagnose-batch-top1` 为准：

```bash
PYTHONPYCACHEPREFIX=/tmp/pycache \
/tmp/ads-diagnose-gsheet-venv/bin/python \
skills/personal/qianqian.pu/ads-diagnose-batch-top1/scripts/batch_top1_to_gsheet.py \
  --date 2026-05-02
```

对应 skill 文档：

```text
skills/personal/qianqian.pu/ads-diagnose-batch-top1/SKILL.md
```

默认写入周度 case GSheet；使用 `--date 2026-05-02` 时，默认 tab 为 `skill_2026-05-02`。

常用参数：

| 参数 | 说明 |
|---|---|
| `--date` / `DATE` | 所有 region 使用同一个诊断日期；除非同时指定 `--sg-date` 和 `--br-date`，否则必填 |
| `--sg-date` / `SG_DATE` | 覆盖非 BR region 的诊断日期 |
| `--br-date` / `BR_DATE` | 覆盖 BR 的诊断日期 |
| `--sheet-id` / `SHEET_ID` | 目标 GSheet ID；默认写入周度 case sheet |
| `--tab-name` / `TAB_NAME` | 目标 tab 名；不指定时根据日期生成 |
| `--regions` / `REGIONS` | region 过滤，逗号分隔，例如 `ID` 或 `ID,TH`；默认跑全部 region |
| `--anomalies` / `ANOMALIES` | 异常类型过滤，逗号分隔，例如 `A1` 或 `超收`；默认 `A1,A2,A7,A9` |
| `--model` / `ADS_DIAGNOSE_MODEL` | Compass Claude 模型，默认 `claude-sonnet-4-6` |
| `--max-cases` / `MAX_CASES` | 调试用 case 数限制；`0` 表示跑全部 top case |
| `MAX_AGENT_ITERATIONS` / `MAX_OUTPUT_TOKENS` | 单 case tool-calling 最大轮数和单轮最大输出 token |

诊断执行逻辑：

- 脚本只用 SQL 筛 top case，不在脚本中新增本地规则归因逻辑。
- 默认异常集合为 `A1 7d超收`、`A2 7d欠收`、`A7 广告 gmv/order 骤降（掉量）`、`A9 cost 骤涨（爆量）`。
- 基于 `ads_union_key_metrics_daily__reg_s0_live` 按 `(anomaly_type, region)` 选 top1 campaign；BR 走 US-VA2 / `mkplpaidads_search_ads_ads_diagnosis`，其他 region 走 SG / `mkplpaidads_search_ads_ads_debug`。
- 每个 case 的归因必须来自 `skills/common/ads-diagnose/SKILL.md`、`factual_nodes.md`、`triage_routing.md`、`table_info.md` 和 R3/R4 deep-dive agent contract。
- 批量脚本没有 Claude Code Agent 工具；R3 / R4 命中时在当前 LLM 调用内按 `agents/ads-diagnose-model-deepdive-hb.md` / `agents/ads-diagnose-bidding-deepdive.md` inline 展开二级归因，不声称 dispatch sub-agent。
- R3 必须按主异常方向过滤；方向不匹配的 PCOC 命中只能作为旁证，不能计入一级模块归因总结。
- 只输出当前 `factual_nodes.md` 定义的 R1-R10，不输出 legacy / unsupported 模块。

写入 GSheet 的列顺序：

```text
异常类型, grass_region, campaign_id, 异常指标值, 摘要, 异常检测, 根因归因,
一级模块归因总结, 因果链, cost_ratio_7d, cost_ratio_1d, pctr_pcoc, pcr_pcoc,
final_pgmv_pcoc, 一级 归因是否正确 Qianqian Pu, 二级模块归因总结,
一级 归因是否正确, 二级 归因是否正确, 二级 归因 错误原因, 二级 归因 错误ToDO
```

格式要求：

- 同一异常类型的多 region 行，只在第一行展示异常类型，后续行留空，以匹配周度复盘 GSheet 格式。
- `异常指标值` 写纯数字，不拼接 `absolute_delta=` 或 ratio 文案。
- `异常检测`、`根因归因`、`一级模块归因总结`、`二级模块归因总结` 等诊断列写解析后的多行文本，不把原始 JSON object / list 直接写入单元格。
- 人工 review 列默认留空，供周会 / case review 后补标注。

这类 GSheet 适合在周会 / case review 中作为会议材料：先看异常类型与 region 分布，再看一级模块归因总结，最后挑争议 case 回到 HTML / SQL 细节深挖。

Weekly case 固定记录表：[GSheet weekly case 记录](https://docs.google.com/spreadsheets/d/1Cnop5beSDfF-JOZbmCk7HnWi8H1HHECNUJImyPsG7Do/edit?gid=394519611#gid=394519611)。该表用于承接周级 top case review、人工结论标注、争议 case 跟进和后续回归测试集沉淀。

### 11.3 DQC 底表生产与告警逻辑

DQC 分为三条产表链路和对应监控告警链路。产表逻辑以 DataSuite / workflow 目录为准，告警逻辑以 monitor 目录为准。

| DQC 主题 | 产表逻辑入口 | 产出表 | 监控 / 告警入口 |
|---|---|---|---|
| Full link DQC | `Workflows/ads_algo/ads_diagnosis/monitor/unify_full_link_table_dqc/`；[DataSuite 10957251](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10957251) / [DataSuite 10957266](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10957266) | `mkplpaidads_search_ads.unify_search_ext_dqc_metrics`、`mkplpaidads_search_ads.unify_rcmd_ext_dqc_metrics` | `Workflows/ads_algo/ads_diagnosis/monitor/fulllink_monitor_dqc/Resources/fulllink_dqc_monitor.py`；[DataSuite 11275107](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11275107) |
| Performance DQC | [DataSuite 10852061](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10852061) | `mkplpaidads_search_ads.performance_dqc_daily_metrics`，导入 CK 后为 `mkplpaidads_search_ads_ads_debug.performance_dqc_daily_metrics` | `Workflows/ads_algo/ads_diagnosis/monitor/performance_monitor_dqc/Resources/performance_dqc_monitor.py`；[DataSuite 11275107](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11275107) |
| Union Ads DQC | [DataSuite 11117076](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11117076) | `mkplpaidads_search_ads.union_ads_dqc_daily_metrics`，导入 CK 后为 `mkplpaidads_search_ads_ads_debug.union_ads_dqc_daily_metrics` | `Workflows/ads_algo/ads_diagnosis/monitor/union_ads_monitor_dqc/Resources/union_ads_dqc_monitor.py`；[DataSuite 11275107](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11275107) |

阈值与告警路由：

| DQC 类型 | 阈值配置 | 告警群 |
|---|---|---|
| Full link DQC | [GSheet full link DQC 阈值配置](https://docs.google.com/spreadsheets/d/11kUvqDCyiKdeaDYTWM4yK2NTiwJVAtnLEHd177BkldQ/edit?usp=sharing) | `Unify S&R&A Full Link Log` |
| Performance DQC | [GSheet performance / union ads DQC 阈值配置](https://docs.google.com/spreadsheets/d/1AiT7Kh71SUfFi4cUPradQFNbP6kBbC5A0XhGqmSh-tM/edit?gid=4452961#gid=4452961) | `【ADKP】广告诊断建设` |
| Union Ads DQC | [GSheet performance / union ads DQC 阈值配置](https://docs.google.com/spreadsheets/d/1AiT7Kh71SUfFi4cUPradQFNbP6kBbC5A0XhGqmSh-tM/edit?gid=4452961#gid=4452961) | `【ADKP】广告诊断建设` |

Full link DQC 的 workflow 目录按 search / rcmd 与 US / 非 US 拆分：

| 子目录 | 上游 full link log | 产出 |
|---|---|---|
| `unify_search_dqc` | `srdi_mart.dwd_sr_data_warehouse_search_unify_full_link_log_1h` | `unify_search_ext_dqc_metrics` |
| `unify_search_dqc_us` | `srdi_mart.dwd_sr_data_warehouse_search_unify_full_link_log_1h` | `unify_search_ext_dqc_metrics` |
| `unify_rcmd_dqc` | `srdi_mart.dwd_sr_data_warehouse_rcmd_unify_full_link_log_1h` | `unify_rcmd_ext_dqc_metrics` |
| `unify_rcmd_dqc_us` | `srdi_mart.dwd_sr_data_warehouse_rcmd_unify_full_link_log_1h` | `unify_rcmd_ext_dqc_metrics` |

KB 当前不复制该目录内 SQL 全文，只沉淀使用原则：

- DQC 目标是监控诊断底表及上游关键字段覆盖率，避免 case 归因建立在缺字段或脏数据上。
- 新增诊断字段必须同步接入 DQC，至少覆盖字段非空率、行数、region / date 覆盖、关键指标异常波动。
- DQC 输出需要能支撑 full link、performance、union ads 三类检查表；其中 performance / union ads 是诊断宽表核心依赖，full link DQC 是漏斗字段可信度的前置保障。
- DQC 异常时，诊断报告应降级为“证据不足”或明确标注“目标日期底表 / 字段覆盖异常”，不能强行输出确定根因。
- 告警应能路由到指定群，便于底表 owner 和 skill owner 在 case review 前发现数据问题。

维护建议：

- 每次新增 UNION 字段、case 表字段、metrics_info JSON 字段时，同步更新对应产表逻辑和 [DataSuite 11275107](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11275107) 的字段覆盖率检查。
- DQC 告警阈值通过对应 GSheet 维护更新；调整阈值时应同步确认告警群是否仍正确。
- 每次调整 A/B/R 节点依赖字段时，同步检查 DQC 是否覆盖新字段。
- 周会 GSheet 中若出现大面积空值、region 缺失、异常数量突然为 0，应先查 DQC，再判断是否真实业务恢复。

### 11.4 DQC 周报 skill

DQC 周报不是产表逻辑，也不是实时告警逻辑，而是对已产出的 DQC 日表做周级消费分析。Skill 入口：

```text
skills/common/ads-dqc-report/SKILL.md
```

适用场景：

| 用户需求 | 使用方式 |
|---|---|
| 生成 DQC 周报 / weekly DQC report | 使用 `ads-dqc-report`，默认同时生成 Performance DQC 与 Union Ads DQC |
| 只看 performance 或 union ads | 指定 `report_type=performance` 或 `report_type=union` |
| 指定周窗口 | 提供 `week_start + week_end`，或只提供 `week_end` 使用最近 7 天滚动窗口 |
| 指定 region | 传入单个或多个 region；默认 `TH, PH, VN, MY, TW, SG, ID, BR` |

数据源固定为 SG ClickHouse：

| Report | ClickHouse table |
|---|---|
| Performance DQC Report | `mkplpaidads_search_ads_ads_debug.performance_dqc_daily_metrics` |
| Union Ads DQC Report | `mkplpaidads_search_ads_ads_debug.union_ads_dqc_daily_metrics` |

注意：即使 `grass_region = 'BR'`，DQC 周报也从 SG ClickHouse 读取，不切 US-VA2。

核心判定：

- 覆盖率字段：列名以 `_fill_rate` 结尾；本周均值相对上周下降 `>= 5pp` 判为异常。
- 均值字段：列名以 `_avg` 结尾；本周均值相对上周下降 `>= 10%` 判为异常。
- `grass_date` / `grass_region` / count 类字段 / 非数值字段不参与异常判定。
- 有缺失日期的 `report_type + grass_region` 默认不参与异常判定，报告必须列出具体缺失 `grass_date`。
- Performance DQC 中不含 `usd` 且命中 price / gmv / expense / budget / deduction / cost 等金额关键词的 `_avg` 字段，需要先除以 `100000` 再展示和计算 diff。

默认保存规则：

```text
docs/team/00.paid-ads-dev/17.ads-dqc-report/{cur_end}-weekly-dqc-report.md
```

报告结构：

```text
Ads DQC Weekly Report
  -> Summary
  -> Performance DQC Report
      -> Data Missing
      -> Coverage Anomalies
      -> Average Anomalies
  -> Union Ads DQC Report
      -> Data Missing
      -> Coverage Anomalies
      -> Average Anomalies
  -> Notes
```

取消校验字段：

- 周报 skill 使用固定清单排除 GSheet 中标记为 `取消校验` 的字段。
- 固定配置来源为 [GSheet DQC 取消校验字段配置](https://docs.google.com/spreadsheets/d/1AiT7Kh71SUfFi4cUPradQFNbP6kBbC5A0XhGqmSh-tM/edit?gid=4452961#gid=4452961)。
- 生成周报时默认不重新拉 GSheet；只有用户明确要求刷新取消校验清单时才更新。

### 11.5 Ads 粒度监控流程/Ads-Level Monitoring Workflow

Ads 粒度的稳定监控推荐按“底表 → ClickHouse → skill → schedule”链路建设，避免只有一次性脚本、没有例行检查和可复用报告入口。

当前 ads / performance DQC 的周级消费入口是 [`ads-dqc-report`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/skills/common/ads-dqc-report) skill：

```text
skills/common/ads-dqc-report/SKILL.md
```

例行任务配置入口是 ads-workspace 的 [`schedules/`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/schedules) 目录。该目录用于配置定时运行的诊断 / DQC 任务，例如 Ads DQC 周报定时产出与通知。

新增 ads 粒度或其他诊断监控任务时，默认流程如下：

| 步骤 | 要求 | 说明 |
|---|---|---|
| 1 | 明确监控对象和底表 | 先确定要监控 ads / campaign / shop / 大盘哪一层，以及依赖哪些 Hive / CK 表、字段和分区 |
| 2 | 底表稳定产出并导入 ClickHouse | 如果大盘或其他任务需要新底表，必须先建设产表链路，并把诊断 / skill 查询需要的数据导入 ClickHouse |
| 3 | 写可复用 skill | 监控逻辑不应只停留在临时 SQL；需要沉淀到 `skills/common/` 或合适 scope 的 skill 中，写清数据源、指标口径、异常阈值、输出格式和降级规则 |
| 4 | 配置定时任务 | 在 `schedules/` 下补齐例行任务配置，定义触发时间、运行参数、输出路径和通知方式 |
| 5 | 接入 DQC / 告警 | 新增字段或底表应同步纳入覆盖率、行数、region / date 分区、关键指标波动检查；异常时报告要标注证据不足或数据异常 |

维护原则：

- `ads-dqc-report` 负责消费 `performance_dqc_daily_metrics` / `union_ads_dqc_daily_metrics` 这类已进入 ClickHouse 的 DQC 日表，并生成周级报告；它不是底表产表逻辑本身。
- 大盘诊断或新监控任务如果依赖 Hive-only 数据，需先确认是否需要导 CK；只要 skill / schedule 需要稳定查询，优先把对应底表导入 ClickHouse。
- 新增 schedule 时，应在任务说明中写清 report 类型、默认 region、时间窗口、输出目录和通知群，避免后续只看到 CI 任务但不知道业务语义。
- 若新增大盘 / ads 粒度任务复用现有 DQC 日表，需确认字段已在阈值配置和取消校验清单中正确维护。

## 12. 评估与自演化

TD 中 KA3 要求建设 case 反馈评估链路：

Weekly case 记录固定 GSheet：[GSheet weekly case 记录](https://docs.google.com/spreadsheets/d/1Cnop5beSDfF-JOZbmCk7HnWi8H1HHECNUJImyPsG7Do/edit?gid=394519611#gid=394519611)

| 环节 | 做法 |
|---|---|
| 批量产出 | 初版 skill 批量诊断各异常类型 top case 到 GSheet |
| 人工 review | 周级 top case 由对应 case PIC 在 weekly case GSheet 中审核归因正确性 |
| 回归测试 | 定期用历史 case 回归测试，防止 skill prompt / 节点逻辑修改造成诊断结论退化 |
| 准确率目标 | Ads Bot 诊断准确率 `>=80%` |

DQC 重点：

- 新增字段必须接入覆盖率监控和报警。
- UNION 宽表与 performance DQC 表需稳定 T-1 更新。
- 诊断前建议先确认目标日期不晚于表的最新可用分区。
- 字段覆盖率异常时，报告中应输出“数据证据不足”，不要强行归因。

## 13. 数据生产任务索引

TD 中登记的关键任务按最终表名去重如下。DataSuite / Workflow 列表示产表逻辑入口；OneData 列只记录导入 ClickHouse 的任务链接，`-` 表示 TD 未登记独立导 CK 任务。

| 表名 | DataSuite / Workflow 产表链接 | OneData 导 CK 链接 | 备注 |
|---|---|---|---|
| `mkplpaidads_search_ads.ads_overall_key_metrics_daily__reg_s0_live` | [DataSuite 11278376](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11278376) | [OneData 1105](http://onedata.video.shopee.io/task/detail/1105?project-id=7&tab=1) | 大盘诊断核心指标表 |
| `mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live` | - | [OneData 1283](http://onedata.video.shopee.io/task/detail/1283?project-id=7&tab=1) | takerate 底表导 CK；字段说明见 §4.4 |
| `mkplpaidads_search_ads.overall_supply_budget_metrics_daily__reg_s0_live` | [Workflow 11524097](https://datasuite.shopee.io/scheduler/workflow/mkplpaidads_search_ads_11524097/matrix) | [OneData 1286](http://onedata.video.shopee.io/task/detail/1286?project-id=7&tab=1) | supply / budget 大盘归因表 |
| `mkplpaidads_search_ads_ads_debug.performance_dqc_daily_metrics` | [DataSuite 10852061](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10852061) | [OneData 1233](http://onedata.video.shopee.io/task/detail/1233?project-id=7&tab=1) | Performance DQC 日表；告警逻辑见 [DataSuite 11275107](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11275107) |
| `mkplpaidads_search_ads_ads_debug.union_ads_dqc_daily_metrics` | [DataSuite 11117076](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11117076) | [OneData 1240](http://onedata.video.shopee.io/task/detail/1240?project-id=7&tab=1) | Union Ads DQC 日表；告警逻辑见 [DataSuite 11275107](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11275107) |
| `mkplpaidads_search_ads_ads_debug.dwd_ads_index_status_live` | [DataSuite 11673749](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11673749)；[11673691](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11673691)；[11673716](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11673716)；[11673708](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11673708)；[11673697](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11673697)；[11673726](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11673726)；[11673741](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11673741)；[11673735](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=11673735) | [OneData 1309](http://onedata.video.shopee.io/task/detail/1309?project-id=7&tab=1) | Ads index status 底表导 CK，支撑 R1.5 状态 / 停投 / 索引操作归因 |
| `mkplpaidads_search_ads_ads_debug.unactive_ads_reason_metrics` | - | [OneData 1027](http://onedata.video.shopee.io/task/detail/1027?project-id=7&tab=1) | 不在投广告原因表|
| `mkplpaidads_search_ads.unify_search_ext_dqc_metrics` | [DataSuite 10957251](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10957251) | - | Full link search DQC；本地 workflow：`Workflows/ads_algo/ads_diagnosis/monitor/unify_full_link_table_dqc/` |
| `mkplpaidads_search_ads.unify_rcmd_ext_dqc_metrics` | [DataSuite 10957266](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10957266) | - | Full link rcmd DQC；本地 workflow：`Workflows/ads_algo/ads_diagnosis/monitor/unify_full_link_table_dqc/` |
| `mkplpaidads_search_ads.ads_case_key_metrics_daily` | [Workflow 10705363](https://datasuite.shopee.io/scheduler/workflow/mkplpaidads_search_ads_10705363/matrix) | [OneData 1149](http://onedata.video.shopee.io/task/detail/1149?project-id=7&tab=1)；[拆 region 导 CK 1215](http://onedata.video.shopee.io/task/detail/1215?project-id=7&tab=1) | 新 case 底表，供超收 Bot / weekly case 使用 |
| `mkplpaidads_search_ads.shop_gms_single_multi_non_metrics_daily` | [Workflow 10708079](https://datasuite.shopee.io/scheduler/workflow/mkplpaidads_search_ads_10708079/matrix) | [OneData 1119](http://onedata.video.shopee.io/task/detail/1119?project-id=7&tab=1) | 货款打通 / GMS single multi non 相关诊断表 |
| `mkplpaidads_search_ads.ads_union_key_metrics_daily__reg_s0_live` | [Workflow 10559627](https://datasuite.shopee.io/scheduler/workflow/mkplpaidads_search_ads_10559627/matrix)；分粒度产表：[ads 10531513](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10531513) / [campaign 10552159](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10552159) / [item 10552889](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10552889) / [seller 10553178](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10553178) | [OneData 1091](http://onedata.video.shopee.io/task/detail/1091?project-id=7&tab=1) | 四合一主宽表 |
| `mkplpaidads_search_ads_ads_debug.ads_union_key_metrics_daily__reg_s0_live` | [Workflow 10559627](https://datasuite.shopee.io/scheduler/workflow/mkplpaidads_search_ads_10559627/matrix) | [拆 region 导 CK 1226](http://onedata.video.shopee.io/task/detail/1226?project-id=7&tab=1) | ClickHouse debug 库主宽表，不含 omni 阶段 |
| `mkplpaidads_search_ads_ads_debug.ads_union_key_metrics_daily__reg_s0_live_with_omni` | [Workflow 10559627](https://datasuite.shopee.io/scheduler/workflow/mkplpaidads_search_ads_10559627/matrix) | [OneData 1219](http://onedata.video.shopee.io/task/detail/1219?tab=1&project-id=7) | ClickHouse debug 库 omni 阶段表 |
| `mkplpaidads_search_ads.static_ads_info_metrics` | [DataSuite 10530702](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10530702) | [OneData 1089](http://onedata.video.shopee.io/task/detail/1089?project-id=7&tab=1) | 静态信息表；`mkplpaidads_discovery_ads.static_ads_info_metrics` 为历史废弃表 |
| `mkplpaidads_search_ads.ultra_core_bidding_log_ads_merge_hourly` | [Workflow 10688182](https://datasuite.shopee.io/scheduler/workflow/mkplpaidads_search_ads_10688182/matrix?project_code=mkplpaidads_search_ads) | [OneData 1258](http://onedata.video.shopee.io/task/detail/1258?project-id=7&tab=1) | Ultra Core bidding log 小时聚合表；上游 `mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live` |
| `mkplpaidads_search_ads.ultra_core_monitor_sub_metrics` | [DataSuite 10536715](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10536715)；[DataSuite 10536721](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10536721)；[DataSuite 10530836](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10530836) | - | Ultra Core 聚合中间表 |
| `mkplpaidads_search_ads.full_link_funnel_metrics_daily__reg_s0_live` | [DataSuite 10532168](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10532168)；[DataSuite 10532155](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10532155)；[DataSuite 10532174](https://datasuite.shopee.io/studio?project_code=mkplpaidads_search_ads&asset_id=10532174) | - | Full link funnel 中间表 |

## 14. 常见问题回答卡

| 问题 | 推荐回答路径 |
|---|---|
| “为什么某个 campaign 7d 超收？” | 用 `ads-diagnose` 已知异常归因：验证 A1 -> 查 campaign/ads/entrance/status -> 输出 R1-R11 合表和因果链 |
| “某天 7d 超收 top1 是谁？” | 使用 `ads-diagnose` 异常类型诊断：按 A1 公式筛选 region / level 的 top case，再对 top case 归因 |
| “cost 突然掉一半是什么原因？” | ID 诊断或 A8 异常类型诊断；重点看 R1 状态/预算余额、R4 coef、R5 漏斗、R6 广告位质量 |
| “所有场景 CVR 都是 0，是不是店铺被处罚？” | 先排 R6：coef、eCPM、mixrank_rate、广告位质量；R6 排除后再考虑 R7 店铺级问题 |
| “为什么诊断报告里有公式命中的节点却没进根因总结？” | 因为方向不匹配。例如超收方向只把高估类 R3 节点计入一级模块，低估类只能作为旁证 |
| “能不能直接用 KB 的历史数值回答当前线上问题？” | 不能。KB 只保存稳定口径和查询路径，当前线上数值必须重新查表，并确认最新分区和 DQC |
| “生成 DQC 周报 / 覆盖率周报” | 使用 `ads-dqc-report` skill，从 SG ClickHouse 的 performance / union ads DQC 日表做上周 vs 本周对比，输出覆盖率下降、均值下降和 Data Missing |
