<!-- ads-workspace-gdoc-sync: gdoc_id=1kUsQRaUNB5EjmaM6DGUYfvfPdNOj1zEyeKTofQIMNB4 gdoc_url=https://docs.google.com/document/d/1kUsQRaUNB5EjmaM6DGUYfvfPdNOj1zEyeKTofQIMNB4/edit -->

# mp_paidads.dim_advertise__reg_s0_live

## Description

- **Desc:** 广告维度表，存储每个广告（ads_id x placement）的全量属性快照，包括广告状态、卖家信息、商品信息、Campaign 配额、出价策略、产品类型、品类分类等。是广告系统最核心的维度表，几乎所有广告分析/算法/诊断任务都以此表作为广告属性的 lookup 源。
- **Granularity:** daily x ads_id x placement x region
- **Use Case:** 广告召回/竞价/出价模型训练数据构建、广告诊断（dim_omni_item/campaign_attr）、目标 ROAS/CIR 策略、最小预算策略、流量扶持特征、广告实验分析、广告属性 lookup（JOIN 到效果表）
- **Update Frequency:** Daily

## Key Metrics

此表为维度表（dim），不含聚合指标。核心属性字段：
- 广告状态: ads_status, is_ads_active, campaign_status
- 出价: pricing_type, target_price, target_roi, target_base_price, target_premium_rate
- 预算: total_quota_usd, daily_quota_usd, daily_available_quota, is_budget_split
- Boost: boost_id, boost_price, boost_days, boost_est_views

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 广告: ads_id, placement, ads_type, ads_status, is_ads_active
- Campaign: campaign_id, campaign_status, pricing_type
- 卖家: shop_id, seller_id, seller_name
- 商品: item_id, item_name
- 品类: level1/2/3_global_be_category, level1/2/3_fe_display_category_list, level1/2/3_kpi_category_list
- 产品类型: main_product_type, product_type, sub_product_type
- 受众: ta_group_id, ta_premium_rate, tag_ids, is_segment_ad

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | - |
| Retention | - |
| Column Count | ~80+ (含 struct/array 复杂类型) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, AR, MX |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DIM |

## Popularity

- Studio Tasks References: 1650 files (read) + 17 files (write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
