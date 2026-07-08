<!-- ads-workspace-gdoc-sync: gdoc_id=1rT5T0TElM1_JVCfLZwabYeXiysg17X39NsndChxCTgE gdoc_url=https://docs.google.com/document/d/1rT5T0TElM1_JVCfLZwabYeXiysg17X39NsndChxCTgE/edit -->

# mkplpaidads_search_ads.productads_passrate_model_wide_table_daily_v1

## Description

- **Desc:** Product Ads Passrate Model unified wide table for feature assembly. Combines item features, ads features, valid items metadata, and score model predictions into a single table via LEFT JOINs from valid_items (anchor). Serves as the single source of features for passrate model training, inference, and reserve strategy item selection. Primary key: campaign_id x pricing_type x ads_id x shop_id x item_id x item_type.
- **Granularity:** daily x grass_region x campaign_id x pricing_type x ads_id x shop_id x item_id x item_type
- **Use Case:**
  - Passrate model training data generation (get_train_samples / get_train_samples_us)
  - Passrate model inference data generation (get_infer_samples / get_infer_samples_us)
  - Reserve strategy: NPB (non-performing budget) and Cold Start calibration history computation
  - Reserve strategy: Item selection via hdfs_io.py (cold_start / empty_order_expand)
  - GMS multiproduct model bid EDA and feature analysis
- **Update Frequency:** Daily (workflow scheduled, dynamic partition INSERT, 21-day retention)

## Key Metrics

- 商品描述特征: discount, free_shipping, creation_elapsed_duration, stock, cspu_type, is_p0_cspu_type
- 商品后验特征 (7d/14d/30d): platform_impression_cnt, platform_click_cnt, platform_atc_cnt, platform_order_cnt
- 商品率指标 (7d/14d/30d): platform_ctr, platform_cr, platform_atc_cr, platform_ctcvr
- 广告出价/预算: campaign_daily_quota_usd, price_usd, target_roi, cpa
- 品类分位特征 (L1 + L1_L2): campaign_daily_quota/price/troi/cpa percentile
- 广告后验特征 (7d/14d/30d): ads_total_impression_cnt, ads_total_click_cnt, ads_total_add_to_cart_cnt, ads_total_order_cnt
- 广告率指标 (7d/14d/30d): ads_ctr, ads_atc_cr, ads_cr, ads_ctcvr
- 广告元数据: ads_first_delivery_date, delivery_elapsed_duration
- 模型预估分 (7d/14d): avg_pctr, avg_pcr, avg_pctcvr
- 有效商品元数据: item_type (cold_start / empty_order_expand), campaign_id

## Key Dimensions

- 分区: grass_date (date), grass_region (string)
- 商品维度: ads_id, shop_id, item_id, l1_cat, l2_cat, cspu_type, is_p0_cspu_type
- 广告维度: pricing_type, campaign_id, item_type
- 商品属性: discount, free_shipping, stock, creation_elapsed_duration

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_date (date), grass_region (string) |
| HDFS Path | ${SCHEMA}.productads_passrate_model_wide_table_daily_v1 |
| Retention | 21 days (DROP PARTITION for ISO_21DAY_AGO) |
| Column Count | 83 data columns + 2 partition columns (85 total) |
| Region Coverage | Asian: ID, TH, MY, VN, SG, PH, TW + BR (via get_wide_table_us) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 31 files (2 write, 29 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
