<!-- ads-workspace-gdoc-sync: gdoc_id=183GvXpZVR8Rqc5mxNv3_Cr8dxR9nLchKciPlVnBSR2I gdoc_url=https://docs.google.com/document/d/183GvXpZVR8Rqc5mxNv3_Cr8dxR9nLchKciPlVnBSR2I/edit -->

# mp_paidads.ods_log_seller_center_report_hi__reg_s0_live

## Description

- **Desc:** Seller Center 实时上报数据 ODS 层，接收客户端（tracking）和服务端（reporting、translog、order）多维度的广告效果原始日志数据，是卖家中心报表链路的数据源基础表。
- **Granularity:** hourly (h) x grass_region — 每条记录对应一个事件上报（event_timestamp），无唯一业务主键
- **Use Case:**
  - Seller Center 实时报表产出（Advertise / TA Group / Query / Brand Ads / Live Video Ads，15 分钟粒度）
  - Seller Report 离线批处理与实时流 diff 校验（batch vs realtime）
  - 结算/扣费数据核对（translog_db vs translog_event vs seller_center_report）
  - OKR 指标追踪（cost、order、gmv 等核心指标）
- **Update Frequency:** Hourly（日志流实时入湖，按 h 分区增量追加）

## Key Metrics

- 展示类: raw_imp, raw_impression, non_fraud_impression, impression, location_in_ads
- 点击类: raw_click, non_fraud_click, dedup_click, click, product_click
- 费用类: cost, cpm, cost_by_cpm, raw_expense, expected_revenue
- 费用拆分类: expense_free_credit_with_expiry, expense_free_credit_without_expiry, expense_paid_credit_with_expiry, expense_paid_credit_without_expiry
- 订单类: order, order_amount, order_gmv, broad_order, broad_item_count, broad_gmv, checkout, daily_order, daily_gmv
- 付费订单: paid_broad_gmv, paid_order_gmv, paid_broad_order, paid_order, paid_checkout, paid_broad_order_amount, paid_order_amount
- Shop Item: shop_item_impression, shop_item_click, broad_shop_item_imp, broad_shop_item_click
- 互动类: video_view, view, view_duration, pageview, add_to_cart

## Key Dimensions

- 分区: grass_region, grass_date, h (hour)
- 业务维度: placement, pricing_type, shop_id, ads_id, item_id, campaign_id, account_id
- 扩展维度: group_id (ta_group), new_boost, affiliate_id, ls_session_id, match_type, keyword, query
- 其他: operation, source, sub_source, user_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Spark Parquet (mergeSchema enabled) |
| Partition Columns | grass_region (string), grass_date (date), h (int) |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hdfs/prod/logs/ods_log_seller_center_report_hi__reg_s0_live |
| Retention | - |
| Column Count | ~50+ (schema-inferred from Parquet, DDL 无列定义) |
| Region Coverage | MY, SG, TH, ID, VN, PH, TW, BR, MX (CO/CL/AR 已注释下线) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 69 files (1 write, 68 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
