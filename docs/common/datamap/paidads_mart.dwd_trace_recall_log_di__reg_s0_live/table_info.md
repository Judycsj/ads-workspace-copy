<!-- ads-workspace-gdoc-sync: gdoc_id=1vvvioJfx9y2JCG_UQxc_TMjvw2bSLvgegKHqmLsIkJ0 gdoc_url=https://docs.google.com/document/d/1vvvioJfx9y2JCG_UQxc_TMjvw2bSLvgegKHqmLsIkJ0/edit -->

# paidads_mart.dwd_trace_recall_log_di__reg_s0_live

## Description

- **Desc:** 搜索广告 Recall Log 日增量明细表（DWD 层），记录每条广告在召回阶段的全链路 trace 数据，包括召回原因 (`reason`)、召回分数 (`ecpm_score`, `pctr`, `pcr`, `es_score`)、出价 (`bid_price`)、队列标签 (`queue_tag`, `queue_tags`, `delivery_item_tags`)、AB 实验号 (`ab_test_sign`)、场景 (`biz_type`, `entrance`) 等。是召回效果分析、AB 实验监控、漏斗分析、队列覆盖率分析的核心数据源。
- **Granularity:** daily x recall event (每条一行，request_id × item_id 粒度)
- **Use Case:** AB 实验召回监控 Dashboard、召回漏斗分析（召回→prerank→rank→mixrank→dispatch）、队列独占/覆盖率分析、召回原因分布分析、离线 Q2I 召回效果评估、Video Ads 召回分析
- **Update Frequency:** Daily

## Key Metrics

- 召回计数: `COUNT(*)` / `COUNT(DISTINCT request_id, item_id)` — 召回量 / 召回请求数
- ab_group: 从 `ab_test_sign` 中解析实验分组（CASE WHEN 映射）
- 漏斗指标: `COUNT_IF(reason IN (...))` — 各阶段通过/淘汰数
- 分数指标: `AVG(bid_price)`, `AVG(ecpm_score)`, `AVG(pctr)`, `AVG(pcr)` — 平均出价/分数
- 独占指标: `size(queue_tags)=1` → 队列独占召回
- 采纳率: `SUM(impression_cnt) / COUNT(DISTINCT request_id, item_id)` — 召回采纳率
- 覆盖率: `COUNT(DISTINCT request_id) WHERE queue_tag = xxx / COUNT(DISTINCT request_id)` — 队列覆盖率

## Key Dimensions

- 分区: `local_date` (date partition)
- 地域: `grass_region` — 8 国: ID, PH, MY, TH, VN, TW, SG, BR
- 业务场景: `biz_type` (1=search, 2=dd, 3=ymal, 4=cart_unify, 5=game, 6=video, 7=shop), `entrance`
- 召回阶段: `reason` (RECALL_REASON_PICKED, RECALL_REASON_UNPICKED_LOW_ECPM, ... 30+ 枚举值)
- 队列标识: `queue_tag`, `queue_tags`, `delivery_item_tags` (array<string>)
- 实验: `ab_test_sign` (pipe-separated experiment IDs)
- 广告主: `ads_id`, `item_id`, `placement`, `shop_id`
- 用户/请求: `user_id`, `request_id`
- 全量标识: `is_full_sample`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 205 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
