<!-- ads-workspace-gdoc-sync: gdoc_id=10qtguoddJ00IeSMlvQLE8ghgPB2bgh_0tgAyC91CJF4 gdoc_url=https://docs.google.com/document/d/10qtguoddJ00IeSMlvQLE8ghgPB2bgh_0tgAyC91CJF4/edit -->

# srdi_mart.dwd_sr_data_warehouse_rcmd_unify_full_link_log_1h

## Description

- **Desc:** 推荐（Rcmd）统一全链路日志小时表，记录每次推荐请求在召回(recall)->粗排(prerank)->精排(rank)->混排(mixrank)->分发(dispatch)各阶段的明细数据，包含各阶段的分数、位置、出价等特征及 JSON 扩展字段。与 Search 版本 (`dwd_sr_data_warehouse_search_unify_full_link_log_1h`) 并列，覆盖 discovery ads（DD/YMAL/PP）场景。
- **Granularity:** hourly (regional_hour) x request_id x ads_id x item_id
- **Sibling Table:** `srdi_mart.dwd_sr_data_warehouse_search_unify_full_link_log_1h` (Search 广告全链路日志)
- **Use Case:**
  - 全链路漏斗分析 (COUNT DISTINCT request_id 计算各阶段通过量)
  - 小时级广告指标聚合 (DD/Search 场景分场景聚合，产出 `ads_full_hourly_metrics` 等下游表)
  - DQC 数据质量监控 (四种 JSON Ext 字段填充率检查，产出 `unify_rcmd_ext_dqc_metrics`)
  - 出价/混排 pacing/deboost 效果分析 (json_extract ads_bid_ext 中的 pacing 系数、deboost 值)
  - 召回样本抽取 (random 采样写入 `full_link_rcmd_unify_sample_log`)
  - PBPR 回放特征提取 (获取 request_id + mixrank_score 用于回放分析)
  - 全链路填充率监控 (四大 JSON Ext 字段子字段覆盖率检查，产出 DQC 指标报警)
  - Video 场景全链路漏斗分析 (entrance=29/33/34 场景)
- **Update Frequency:** Hourly (日志表，按小时分区写入)

## Key Metrics

- 漏斗量级类: cnt, recall_num, ads_recall_num, org_recall_num, prerank_num, rank_num, mixrank_num, dispatch_num
- 漏斗请求级: request_cnt (COUNT DISTINCT request_id), after_recall_num, after_prerank_num, after_rank_num, after_mixrank_num
- 预估分数类: prerank_score, rank_score, mixrank_score, rank_relevance_score
- 转化率类: prerank_pctr, prerank_pcr, rank_pctr, rank_pcr, rank_broad_pcr
- 出价/ECPM 类: rank_ecpm, rank_bid_price, prerank_bidprice, mixrank_bid_price, rank_item_price
- 混排/扣费类: mixrank_estimated_gmv, deduction_price, mixrank_porg
- 商品特征 (从 JSON ext 提取): avg_sold_count, pid_coef, target_cir, target_roi, pgmv, padvv, direct_pcr, shop_pcr, broad_pcr_v, cold_start_boost
- 扩展字段填充率: 四大 ext (ads_recall_ext, ads_info_ext, ads_bid_ext, ads_deduct_ext) 子字段覆盖率

## Key Dimensions

- 分区: regional_date, regional_hour, country
- 请求标识: request_id, session_id, user_id
- 广告实体: ads_id, item_id, shop_id, entrance (场景入口), item_type (出价类型)
- 漏斗标记: is_recall, is_prerank, is_rank, is_mixrank, is_dispatch, is_sampled
- 召回维度: recall_type (1=ads/3=both vs 2=org), recall_queues
- 移除原因: recall_remove_reason, prerank_remove_reason, rank_remove_reason, mixrank_remove_reason

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL 未在代码库中找到) |
| Partition Columns | - (DDL 未在代码库中找到) |
| HDFS Path | - (DDL 未在代码库中找到) |
| Retention | - (DDL 未在代码库中找到) |
| Column Count | ~60+ (从下游建表语句推断) |
| Region Coverage | ID, TH, PH, VN, MY, TW, SG, BR (从 WHERE country 过滤推断) |
| DQC Status | - (未抓取 DataMap，请运行 --source from-di 补充) |
| Table Size | - (未抓取 DataMap，请运行 --source from-di 补充) |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 139 files (27 workflows, 112 manual_tasks)
- L7D Query Count: - (未抓取 DataMap，请运行 --source from-di 补充)
- Completeness: - (未抓取 DataMap，请运行 --source from-di 补充)
- Popularity: - (未抓取 DataMap，请运行 --source from-di 补充)
