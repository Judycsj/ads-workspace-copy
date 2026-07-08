<!-- ads-workspace-gdoc-sync: gdoc_id=1o87xHF1ens5T-SptqeJV1tefK185O_ltzSDcrO58XC8 gdoc_url=https://docs.google.com/document/d/1o87xHF1ens5T-SptqeJV1tefK185O_ltzSDcrO58XC8/edit -->

# srdi_mart.dwd_sr_data_warehouse_search_unify_full_link_log_1h

## Description

- **Desc:** Search Ads 统一全链路日志表（小时粒度）。记录 Search 场景下每条广告从召回(Recall)、预排序(PreRank)、排序(Rank)、混排(MixRank)到分发(Dispatch)的全链路漏斗数据。每行代表一次广告检索事件，包含各阶段的打分、CTR/CVR 预估、出价、扣费等详细信息。JSON 扩展字段（ads_recall_ext / ads_info_ext / ads_bid_ext / ads_deduct_ext）携带各阶段的原始特征数据。
- **Granularity:** hourly x country x (item_id + ads_id + shop_id + entrance)
- **Use Case:**
  - DQC 数据质量监控：检查各漏斗阶段 JSON 扩展字段的填充率（fill rate）
  - 全链路漏斗分析：统计 recall -> prerank -> rank -> mixrank -> dispatch 各阶段通过率
  - 出价/扣费分析：分析 bid、ecpm、deduction_price、boost/deboost 系数
  - 推荐 vs 搜索效果对比：联合 rcmd_unify_full_link_log 做 search/rcmd Union 分析
  - 分国家/分入口 AB 实验分析：按 ab_sign 分流分析实验效果
  - 广告 Ranking 模型特征分析：提取 pctr、pcr、broad_pcr、pgmv 等 ranking 特征
- **Update Frequency:** Hourly

## Key Metrics

- 漏斗计数类: cnt, recall_num, ads_recall_num, org_recall_num, prerank_num, rank_num, mixrank_num, dispatch_num
- 预估打分: prerank_score, prerank_pctr, prerank_pcr, rank_pctr, rank_pcr, rank_broad_pcr, rank_ecpm, rank_score, rank_relevance_score
- 混排打分: mixrank_score, mixrank_pctr, mixrank_pcr, mixrank_estimated_gmv
- 出价/成本: rank_bid_price, prerank_bidprice, deduction_price, rank_item_price
- 定价/ROI: target_cir, target_roi, pid_coef
- 商品价值: pgmv, padvv, direct_pgmv_7d, shop_pgmv_7d
- JSON 填充率（DQC 导出）: recall_*_fill_rate, info_*_fill_rate, bid_*_fill_rate, deduct_*_fill_rate

## Key Dimensions

- 分区: regional_date, regional_hour, country
- 漏斗阶段: is_recall, is_prerank, is_rank, is_mixrank, is_dispatch
- 召回类型: recall_type (1=ads-only, 2=organic-only, 3=both)
- 投放类型: item_type (TARGET_ROI2, SIMPLE_ROI2, ROI1)
- 入口: entrance (daily_discover_main→dd, product_detail_page→ymal, orderpaid_discover/shoppingcart/me_page_ymal等→pp)
- 广告标识: ads_id, shop_id, item_id / ads_real_item_id
- 用户标识: user_id, request_id, session_id
- AB 分流: ab_sign
- 采样标记: is_sampled

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG, ID, MY, PH, TH, TW, VN (Southeast Asia + Taiwan) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 70 files (20 workflows, 48 manual_tasks, 2 other)
- L7D Query Count: -
- Completeness: -
- Popularity: -
