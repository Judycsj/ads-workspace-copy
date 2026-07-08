<!-- ads-workspace-gdoc-sync: gdoc_id=1Tjfm926dKu7lwZooYbfoST8sm3HXLsySCBAzzf9qm8A gdoc_url=https://docs.google.com/document/d/1Tjfm926dKu7lwZooYbfoST8sm3HXLsySCBAzzf9qm8A/edit -->

# mkplpaidads_search_ads_ads_debug.full_link_diagnose_general_ads_metrics

## Description

- **Desc:** 广告全链路诊断通用指标表，存储每条广告（ads_id）在各个场景（scene）下的完整漏斗数据、模型预估分、预算消耗和效果指标，用于广告诊断系统（ads-diagnose）的日常分析和异常检测。Hive 表实际存储于 `mkplpaidads_discovery_ads` 库，`mkplpaidads_search_ads_ads_debug` 为其 ClickHouse 镜像副本。
- **Granularity:** daily x ads_id x scene x product_type x grass_region
- **Use Case:**
  - 广告诊断日报（daily metrics）：获取单条广告近 60 天按天指标趋势
  - 广告诊断周报（weekly metrics）：按周聚合 + 同品类 percentile 对比
  - 广告健康度检查（check value）：广告消耗/预算在同品类中的分位数定位
  - 全场景基础信息（base info）：多 scene 加权聚合 + 层级汇总
  - 低预算治理监控（low budget usage monitor）：按 campaign 聚合预算使用率
  - Case 筛选标注（case filter metrics）：前后天指标对比 + delta_cost/cpa 计算
- **Update Frequency:** Daily (T+1, via `${1_DAYS_AGO}`)

## Key Metrics

- 预算消耗类: shop_valid_budget_usd_1d, shop_ads_rev_usd_1d, campaign_valid_budget_usd_1d, campaign_ads_rev_usd_1d, ads_rev_usd_1d
- 预算使用率: shop_budget_used_ratio, campaign_budget_used_ratio
- 效果指标: ads_impression_1d, ads_click_1d, direct_order_1d, broad_order_1d, direct_gmv_usd_1d, broad_gmv_usd_1d
- 点击/转化率: ctr, cr
- 漏斗计数: ad_recall_cnt, ad_recall_info_cnt, ad_recall_prerank_cnt, recall_num, ads_recall_num, org_recall_num, prerank_num, rank_num, mixrank_num, dispatch_num, cnt
- 漏斗通过率: ads_recall_info_passrate, ads_prerank_passrate, prerank_passrate, rank_passrate, mixrank_passrate, dispatch_passrate
- 模型预估分 (prerank): ads_prerank_score, ads_prerank_pctr, ads_prerank_pcr, ads_prerank_position, ads_prerank_bidprice, prerank_score, prerank_pctr, prerank_pcr, prerank_position, prerank_bidprice
- 模型预估分 (rank): rank_pctr, rank_pcr, rank_broad_pcr, rank_relevance_score, rank_ecpm, rank_score, rank_position, rank_bid_price, rank_item_price
- 模型预估分 (mixrank): mixrank_score, mixrank_pctr, mixrank_pcr, mixrank_position, mixrank_bid_price, mixrank_estimated_gmv, mixrank_target_roi
- 其他特征: direct_pcr, direct_pcr_1d, direct_pgmv_7d, shop_pcr, shop_pcr_1d, shop_pgmv_7d, broad_pcr_v, broad_pgmv_7d, avg_sold_count, pid_coef, cold_start_boost, target_cir, target_roi, padvv, deduction_price
- 索引状态: idx_status (reason), reason_with_cnt, if_campaign_waste, if_campaign_hit
- (manual variant only) 活跃小时: active_hour; pgmv

## Key Dimensions

- 分区: grass_date, grass_region
- 主键: ads_id, scene, product_type
- 关联键: item_id, shop_id, campaign_id
- 品类: shop_level1_global_be_category, shop_level2_global_be_category
- 状态: idx_status

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (Hive) / ClickHouse ReplicatedMergeTree (CK mirror) |
| Partition Columns | grass_date, grass_region |
| HDFS Path | mkplpaidads_discovery_ads.full_link_diagnose_general_ads_metrics |
| Retention | - |
| Column Count | 88 (DDL) / 90 (manual variant with active_hour, pgmv) |
| Region Coverage | BR, ID, MY, PH, SG, TH, TW, VN |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 35 files (Write: 4, Read: 31)
- L7D Query Count: -
- Completeness: -
- Popularity: -
