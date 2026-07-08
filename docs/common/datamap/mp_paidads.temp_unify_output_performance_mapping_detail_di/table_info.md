<!-- ads-workspace-gdoc-sync: gdoc_id=1iyDN2wAzbxRrPyBp-9lwf3j2IQ9y6BhXW8JR9RcXREc gdoc_url=https://docs.google.com/document/d/1iyDN2wAzbxRrPyBp-9lwf3j2IQ9y6BhXW8JR9RcXREc/edit -->

# mp_paidads.temp_unify_output_performance_mapping_detail_di

## Description

- **Desc:** 统一输出性能数据新旧对比明细表，将新数据源 (`temp_dwd_event_performance_di__reg_s0_live`) 与旧数据源 (`dwd_advertise_performance_di__reg_s0_live`) 按维度 JOIN 后存储明细级对比结果，每个字段保留新旧两列 (`_new` / `_old`)，用于数据迁移/重构过程中的差异分析和校验。
- **Granularity:** daily x region x diff_type x join_key（按 diff_type 不同，join_key 构成不同）
- **Use Case:**
  - Unify Output 项目的数据一致性校验（traffic / finance / attribution / attribution_atc 四个维度差异分析）
  - 新旧数据源字段级 diff 排查，定位具体差异行
  - Dashboard 表的数据源头，用于生成各字段的匹配率（match rate）汇总
  - Ad-hoc 扣费/财务记录差异排查（如 expense_rebate、item_price 差异分析）
- **Update Frequency:** Daily（按 grass_date 分区，每天覆盖写入）

## Key Metrics

所有列均为 string 类型，存储新旧值对比，无原始聚合语义。核心对比维度：

- 扣费/花费类: expenditure_amt_local, expenditure_amt_usd, raw_expense, expense_free_credit_with_expiry, expense_free_credit_without_expiry, expense_paid_credit_with_expiry, expense_paid_credit_without_expiry, expense_rebate_free_credit_without_expiry
- 订单/GMV类: order_cnt, order_gmv, ads_order_gmv_local, ads_order_gmv_usd, paid_order_gmv_local, paid_order_gmv_usd, broad_gmv_amt_local, broad_gmv_amt_usd
- 曝光/点击类: impression_cnt, click_cnt, raw_impression, raw_click_cnt, deduplicated_click, non_fraud_impression, non_fraud_click_cnt
- 转化类: add_to_cart_cnt, broad_add_to_cart_cnt, checkout_cnt, confirmed_order_cnt, paid_order_cnt
- 商品/店铺类: broad_item_cnt, broad_order_cnt, ads_item_sold_cnt, shop_item_click_cnt, shop_item_impression_cnt
- 视频/直播类: view, view_duration, video_view, video_play_complete, video_play_3s_cnt, video_play_5s_cnt, shop_video_play, shop_view
- 归因/Impression Attribution类: imp_attr_order_cnt, imp_attr_order_gmv, imp_attr_agent_order_cnt, imp_attr_paid_order_cnt

## Key Dimensions

- 分区: grass_region (8-9个站点), grass_date (天), type (traffic/finance/attribution/attribution_atc)
- 业务: entrance, ads_id, user_id, campaign_id, order_id, item_id, shop_id, deduct_unique_id, pricing_type, platform, location

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_region (string), grass_date (date), type (string) |
| HDFS Path | ${HIVE_PATH}/temp_unify_output_performance_mapping_detail_di |
| Retention | - |
| Column Count | 435 |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (及 MX) |
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

- Studio Tasks References: 72 files (32 write, 40 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
