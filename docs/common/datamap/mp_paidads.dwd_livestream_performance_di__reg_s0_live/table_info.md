<!-- ads-workspace-gdoc-sync: gdoc_id=1MpUjzKC12hL0h5LUfF-8gbiHiakIS7yA68z-Am0Durs gdoc_url=https://docs.google.com/document/d/1MpUjzKC12hL0h5LUfF-8gbiHiakIS7yA68z-Am0Durs/edit -->

# mp_paidads.dwd_livestream_performance_di__reg_s0_live

## Description

- **Desc:** DWD-layer daily livestream ads performance fact table. Each row is an individual livestream ad event (impression, CPM deduction, click, order, view) combining livestream report events (`ods_log_ads_report_livestream_hi`) and CPM translog deduction records (`ods_shopee_ads_db__translog_tab_di`) with dimension enrichment from dim_advertise, ls_session, exchange_rate, dim_shop, and VAT rate tables. Covers Live Ads (pricing_type 9,10,14,19,22) only.
- **Granularity:** Event-level (per ads_id x user_id x request_id x ls_session_id x event_timestamp x placement x grass_date x grass_region). NOT pre-aggregated -- one row per raw event.
- **Use Case:** Live Ads tracker daily metrics, livestream revenue/expenditure reporting, streamer-level ROAS and ECR/AOV feature generation for bidding, order attribution analysis, budget utilization analysis, Live Ads AB experiment analysis.
- **Update Frequency:** Daily (per-region partitioned writes, each region runs independently via separate workflow tasks).

## Key Metrics

- Revenue/Spend: `ads_expenditure`, `ads_expenditure_usd`, `ads_expenditure_vat`, `ads_expenditure_usd_vat`
- CPM Revenue: `expense_by_cpm`, `cpm`
- Credit breakdown: `expense_paid_credit_without_expiry`, `expense_paid_credit_with_expiry`, `expense_free_credit_without_expiry`, `expense_free_credit_with_expiry`
- GMV (Direct): `order_gmv`, `order_gmv_usd`
- GMV (Broad): `broad_gmv`, `broad_gmv_usd`
- GMV (Agent): `agent_gmv`, `agent_gmv_usd`
- GMV (Daily): `daily_gmv_amt_local`, `daily_gmv_amt_usd`
- GMV (Impression Attributed): `imp_attr_order_gmv`, `imp_attr_order_gmv_usd`, `imp_attr_agent_order_gmv`, `imp_attr_agent_order_gmv_usd`
- GMV (Paid Order): `paid_order_gmv`, `paid_order_gmv_usd`
- Impressions: `impression`, `non_fraud_impression`, `deduct_impression`
- Clicks: `click`, `raw_click`, `product_click`
- Orders (Direct): `order`, `checkout`, `item_sold_cnt`
- Orders (Broad): `broad_order`, `broad_item_sold_cnt`
- Orders (Paid/Confirmed): `paid_order`, `confirmed_order`, `paid_checkout_cnt`
- Orders (Agent): `agent_order`, `agent_item_sold_cnt`, `agent_checkout`
- Orders (Daily): `daily_order`, `daily_item_sold_cnt`
- Orders (Impression Attributed): `imp_attr_order`, `imp_attr_order_amount`, `imp_attr_agent_order`, `imp_attr_agent_order_amount`, `imp_attr_paid_order_cnt`, `imp_attr_paid_order_amount`
- Engagement: `view`, `view_duration`, `add_to_cart`

## Key Dimensions

- Partition: `grass_date`, `grass_region`, `tz_type` (always 'local')
- Ad entity: `ads_id`, `campaign_id`, `shop_id`, `account_id`, `item_id`
- User: `user_id`
- Livestream: `ls_session_id`, `streamer_id`, `streamer_type`, `streamer_shop_id`
- Session timing: `ls_session_start_timestamp`, `ls_session_end_timestamp`, `ls_session_duration`
- Placement: `placement`, `entrance`, `sub_entrance`, `location`, `location_in_ads`, `slot_id`
- Page context: `page_type`, `page_section`, `platform`
- Pricing/Billing: `pricing_type`
- Attribution: `request_id`, `click_event_id`, `order_id`
- Targeting: `target_type`, `target_affiliate_id`, `target_cir`
- Traffic: `traffic_source`, `recall_source`, `source`, `content_mix_frame_tab_name`
- Experiment: `bid_rerank_trace`, `shop_exp_tag`
- Item: `origin_item_id`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | `tz_type`, `grass_region`, `grass_date` |
| HDFS Path | `${HIVE_PATH}/dwd_livestream_performance_di/` |
| Retention | - |
| Column Count | ~90 (DDL has ~88 data columns + 3 partition columns) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN (7 regions, no BR) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | data_paidadsmart |
| Business Domain | Marketplace - Paid Ads |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 518 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
