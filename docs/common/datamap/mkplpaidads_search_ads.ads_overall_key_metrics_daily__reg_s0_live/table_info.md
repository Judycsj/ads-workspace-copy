<!-- ads-workspace-gdoc-sync: gdoc_id=1vQ11sR2NRNoh33WVpUwkQmtCOTj70-QQe0cSALoTy7A gdoc_url=https://docs.google.com/document/d/1vQ11sR2NRNoh33WVpUwkQmtCOTj70-QQe0cSALoTy7A/edit -->

# mkplpaidads_search_ads.ads_overall_key_metrics_daily__reg_s0_live

## Description

- **Desc:** 搜索广告大盘关键指标日聚合表，从 campaign 粒度聚合到大盘维度。整合广告收入（revenue/advv/GMV）、计费（bid/deduction）、投中预估（pCTR/pCR/pGMV/pADVV）、链路漏斗（request→recall→prerank→rank→mixrank）、omni 渠道（ads vs total）和 take rate（gross_rev/net_ads_rev/platform_gmv）数据，支持按 entrance × pricing_type × cluster × region 多维切片。使用 GROUPING SETS 生成 16 种维度组合（含 ALL 汇总行）。
- **Granularity:** daily × entrance × pricing_type × cluster × grass_region（含 GROUPING SETS 汇总行，NULL→'ALL'）
- **Use Case:** 搜索广告大盘日常监控、pGMV pCOC 告警（daily_pgmv_pcoc 阈值 0.9~1.2）、收入/GMV/漏斗趋势分析、entrance/pricing_type 切片对比
- **Update Frequency:** Daily（动态分区覆写）

## Key Metrics

- 收入类: revenue_usd, gross_rev_usd, net_ads_rev, advv_usd
- GMV 类: direct_gmv_usd, broad_gmv_usd, platform_gmv (⚠️ SUM DISTINCT)
- 效率类: ads_direct_order, ads_broad_order, ads_imp, ads_clk
- 7d 回溯: revenue_usd_7d, advv_usd_7d, ads_broad_order_7d, broad_gmv_usd_7d
- 计费类: bid_price_sum, gross_deduction_price_sum, net_deduction_price_sum
- 投中预估: pctr_sum_by_imp, pcr_direct/broad_sum_by_imp, pgmv_direct/broad_sum_by_imp, padvv_sum_by_imp
- 漏斗类: request_cnt, after_recall_num, ads_after_recall_num, after_prerank_num, after_rank_num, after_mixrank_num
- 模型校准: daily_pgmv_pcoc = sum(daily_pgmv_sum_last_7d_clk) / nullif(sum(broad_gmv_usd), 0)
- omni 渠道: ads_imp_cnt, ads_clk_cnt, ads_order_cnt, ads_gmv_usd, total_imp, total_clk, total_order, total_gmv

## Key Dimensions

- 分区: grass_date, grass_region
- 业务: entrance, pricing_type, cluster
- GROUPING SETS 汇总: 维度值为 'ALL' 表示该维度的汇总行

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (USING parquet) |
| Partition Columns | grass_date (date), grass_region (string) |
| HDFS Path | hdfs://R2/projects/mkplpaidads_search_ads/hive/mkplpaidads_search_ads/ads_overall_key_metrics_daily__reg_s0_live |
| Retention | Permanent |
| Column Count | 63 (61 data + 2 partition) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (含 ALL 汇总) |
| DQC Status | - |
| Table Size | 20.75 MB |
| Table Type | MANAGED_TABLE |
| LakeHouse Type | Hive |

## Business Properties

| Property | Value |
|----------|-------|
| Business PIC | - |
| Technical PIC | qianqian.pu@shopee.com |
| Team | mkplpaidads |
| Project | Search Ads (mkplpaidads_search_ads) |
| Business Domain | - |
| DW Layer | ADS |
| Market Region | REG |

## Popularity

- Studio Tasks References: 17 files
- L7D Query Count: 23
- Completeness: 12.00
- Popularity: 56.40
