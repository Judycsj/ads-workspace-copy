<!-- ads-workspace-gdoc-sync: gdoc_id=1f0WQ-LRfvELGM83CkJzfe1tht6nZUMiXVdBnDv2WMIk gdoc_url=https://docs.google.com/document/d/1f0WQ-LRfvELGM83CkJzfe1tht6nZUMiXVdBnDv2WMIk/edit -->

# mp_paidads.dwd_advertise_seller_report_hi__reg_s0_live

## Description

- **Desc:** 广告卖家报告明细层 DWD 表，按小时粒度汇总 tracking、translog、reportng 等多个数据源的广告表现数据。将不同来源（展示追踪、直播追踪、商品/店铺/视频追踪、交易日志、Reportng）的原始事件统一为标准化 schema，供下游聚合分析。
- **Granularity:** hourly x grass_region x placement x pricing_type x handler
- **Use Case:**
  - 按 placement + region 比较不同数据源（ods_log_ads_report_hi vs dwd）的 cpm / cost_by_cpm / raw_expense 指标差异
  - 作为 ODS 层的标准化的下一步，为更高层聚合表（如 dwd_advertise_performance_di）提供统一的明细数据基础
  - 多数据源全量广告事件（曝光、点击、消耗、订单等）的逐小时归因和校验
- **Update Frequency:** Hourly（通过 ${BIZ_DT} 和 ${BIZ_H} 参数调度）

## Key Metrics

- 追踪类 (tracking): raw_click, raw_imp, non_fraud_click, non_fraud_impression, dedup_click, video_view, view, product_click, view_duration, location_in_ads
- 计费类 (tracking): cpm, cost_by_cpm, raw_expense, deduction_price
- OCPM扣费类 (tracking): click (deduplicated ocpm click)
- 交易类 (translog): click, cost, impression, expected_revenue, expense_paid_credit_without_expiry, expense_paid_credit_with_expiry, expense_free_credit_without_expiry, expense_free_credit_with_expiry
- 报表类 (reportng): shop_item_impression, shop_item_click, pageview, broad_shop_item_imp, broad_shop_item_click, add_to_cart, `order`, order_amount, order_gmv, broad_order, broad_item_count, broad_gmv, checkout, daily_order, daily_gmv, paid_broad_gmv, paid_order_gmv, paid_broad_order, paid_order, paid_checkout, paid_broad_order_amount, paid_order_amount

## Key Dimensions

- 分区: grass_region, grass_date, h (hour)
- 来源标识: source (0=tracking, 1=translog, 3=display_tracking, 4=livestream_tracking, 5=reportng), sub_source
- 业务维度: entrance, placement, pricing_type, handler (e.g. "tracking-keyword", "translog-roi2", "reportng")
- 广告实体: user_id, ads_id, item_id, campaign_id, shop_id, account_id, affiliate_id
- 关键词: keyword, match_type, query
- 其他: group_id (ta_group_id), new_boost, ls_session_id, operation

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_region, grass_date, h |
| HDFS Path | - |
| Retention | - |
| Column Count | 61 (inferred from INSERT SELECT) |
| Region Coverage | SG, MY, TH, ID, VN, PH, TW, BR, MX, CO, CL, AR |
| DQC Status | - |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 2 files (1 write, 1 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
