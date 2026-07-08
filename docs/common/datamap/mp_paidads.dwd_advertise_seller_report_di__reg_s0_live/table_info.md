<!-- ads-workspace-gdoc-sync: gdoc_id=1qVQ58ejjReNOKSeI00_P7b5kZtueAcCTFkjQjoxG7ug gdoc_url=https://docs.google.com/document/d/1qVQ58ejjReNOKSeI00_P7b5kZtueAcCTFkjQjoxG7ug/edit -->

# mp_paidads.dwd_advertise_seller_report_di__reg_s0_live

## Description

- **Desc:** 广告卖家中心报表 DWD 明细表，存储按天+地区的广告事件级别明细数据。数据来源融合多个上游系统：tracking（行为跟踪）、reporting（报表数据）、translog（交易流水）、order（订单系统）。是 Seller Center 所有离线报表的统一数据源。
- **Granularity:** event-level (single event row) x grass_region x grass_date x tz_type
- **Use Case:**
  - Seller Center 广告效果离线报表（15 分钟粒度聚合）
  - TA Group 广告效果报表（按 group_id 维度）
  - 搜索词/关键词广告报表（按 query/keyword 维度）
  - Live/Video 广告效果报表（按 affiliate/ls_session 维度）
  - Brand Ads 品牌广告效果报表（含 UV 去重指标）
  - Realtime vs Batch 数据一致性问题排查
- **Update Frequency:** Daily (批处理产出，下游 15 分钟调度消费)

## Key Metrics

*来源归类基于业务语义注释：*

- **Tracking 指标（行为跟踪）**:
  - raw_imp, raw_click, non_fraud_click, non_fraud_impression, dedup_click, product_click, video_view, view, view_duration
  - cpm, cost_by_cpm, location_in_ads, raw_expense

- **Reporting 指标（报表）**:
  - shop_item_impression, shop_item_click, pageview, broad_shop_item_imp, broad_shop_item_click, add_to_cart

- **Transaction 指标（计费）**:
  - click, cost, impression, deduct_order, expected_revenue
  - expense_free_credit_with_expiry, expense_free_credit_without_expiry
  - expense_paid_credit_with_expiry, expense_paid_credit_without_expiry

- **Order 指标（转化）**:
  - `order`, order_amount, order_gmv, broad_order, broad_item_count, broad_gmv, checkout, daily_order, daily_gmv
  - paid_broad_gmv, paid_order_gmv, paid_broad_order, paid_order, paid_checkout, paid_broad_order_amount, paid_order_amount

## Key Dimensions

- **分区**: grass_date, grass_region, tz_type (固定 'local')
- **广告实体**: placement, pricing_type, shop_id, ads_id, item_id, campaign_id
- **业务扩展**: account_id, group_id (ta_group_id), new_boost, affiliate_id, ls_session_id
- **搜索维度**: match_type, keyword, query
- **数据溯源**: source, sub_source, handler, user_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL 未在代码库中找到，请运行 --source from-di 补充) |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | - |
| Retention | - |
| Column Count | ~60 (按 SQL 使用推断，待 from-di 确认) |
| Region Coverage | ID, TH, VN, SG, MY, PH, TW, MX, CO, CL, BR (11 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD (Detail) |

## Popularity

- Studio Tasks References: 113 files (108 workflows + 2 manual_tasks + 1 diff_check + 2 exploration)
- L7D Query Count: -
- Completeness: -
- Popularity: -
