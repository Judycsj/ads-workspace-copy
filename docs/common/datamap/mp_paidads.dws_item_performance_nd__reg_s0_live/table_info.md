<!-- ads-workspace-gdoc-sync: gdoc_id=1w_if3HscsV9AWklUas2agQkpREtqTBqE3tcUJFp7QK0 gdoc_url=https://docs.google.com/document/d/1w_if3HscsV9AWklUas2agQkpREtqTBqE3tcUJFp7QK0/edit -->

# mp_paidads.dws_item_performance_nd__reg_s0_live

## Description

- **Desc:** Item-level multi-day rolling metrics table (商品多日滚动指标表). Aggregates platform sales funnel metrics, ads performance data, and item attributes into 1d/7d/14d/30d time windows. Each row represents one item's performance snapshot for a given day and region, with 30-day lookback for all rolling windows.
- **Granularity:** daily x grass_region x tz_type (one row per item per day per region)
- **Use Case:**
  1. GMS Bidding Suggest ROI: compute shop-level item prices (org/ads/shop tiers) and price range bins for ROI bidding strategy
  2. Platform All Item Voucher: identify eligible non-ads items meeting 30d10o criteria (platform_order_cnt_30d >= 10)
  3. Item performance monitoring: track platform funnel and ads metrics across rolling time windows for individual items
- **Update Frequency:** Daily (workflow scheduled, writes partition grass_date = BIZ_YESTERDAY)

## Key Metrics

- 平台漏斗指标 (Platform Funnel): platform_impression_cnt, platform_click_cnt, platform_order_cnt, platform_gmv_usd, platform_gmv_local (1d / 7d / 14d / 30d)
- 广告效果指标 (Ads Performance): ads_impression_cnt, ads_click_cnt, ads_broad_order_cnt, ads_expenditure_amt (local / usd, 1d / 7d / 30d)
- 广告宽口径GMV (Ads Broad GMV): ads_broad_gmv_amt (local / usd, 1d / 7d / 30d)
- 付费宽口径 (Paid Broad): ads_paid_broad_order_cnt, ads_paid_broad_order_gmv (local / usd, 1d / 7d / 30d)
- 广告收入 (Ads Revenue): gross_ads_revenue_usd (1d / 7d / 30d)
- 商品标记 (Item Flags): is_ads_item_1d, is_ads_item_7d, is_gms_ads_item_1d, is_new_item_30d
- 算法定价 (Algo Pricing): algo_item_price, algo_item_price_usd, algo_paid_item_price, algo_paid_item_price_usd

## Key Dimensions

- 分区: grass_date, grass_region, tz_type (固定为 'local')
- 商品维度: item_id, shop_id
- 类目维度: level1_category_id/name, level2_category_id/name, level3_category_id/name
- 时间属性: item_create_timestamp, item_create_datetime

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET (External Table) |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | `${HIVE_PATH}/dws_item_performance_nd__reg_s0_live/` |
| Retention | - |
| Column Count | 72 (69 non-partition + 3 partition) |
| Region Coverage | SG, MY, PH, TH, VN, ID, BR, MX, AR |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWS |

## Popularity

- Studio Tasks References: 11 files (9 write + 2 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
