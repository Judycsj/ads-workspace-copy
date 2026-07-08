<!-- ads-workspace-gdoc-sync: gdoc_id=1VsJsyLgVNjy7mr9qzawFnhSdukWmFt509yTIB26TBK0 gdoc_url=https://docs.google.com/document/d/1VsJsyLgVNjy7mr9qzawFnhSdukWmFt509yTIB26TBK0/edit -->

# mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live

## Description

- **Desc:** DWD-layer fact table recording all advertiser credit top-up transactions, including wallet topups, SVS package topups, manual credits, seller mission credits, SRM credits, voucher topups, and negative adjustments. Each row represents a single topup order enriched with credit metadata (paid/free type, expiry, balance, program info). Package and voucher topups are split into paid and free credit rows.
- **Granularity:** daily x order_id x credit_topup_type x region (one row per topup order per credit type split)
- **Use Case:** Downstream aggregation for advertiser daily topup summaries (`dws_advertiser_topup_1d`), net ads revenue calculation (`dws_advertise_net_ads_revenue_1d`), credit expiry tracking (`dws_advertiser_credit_expiry_td`), advertiser balance snapshots (`dws_advertiser_balance_td`), deduction-to-topup attribution (`dwd_advertiser_deduction_di`), topup funnel analysis, incentive experiment analysis
- **Update Frequency:** Daily

## Key Metrics

- Topup amount: `topup_amt` (local currency), `topup_amt_usd`
- Package amount: `pckg_original_amt`, `pckg_original_amt_usd`, `pckg_paid_amt`, `pckg_paid_amt_usd`
- Voucher discount: `voucher_discount_amt`, `voucher_discount_amt_usd`
- Credit balance: `credit_balance_amt`, `credit_balance_amt_usd`
- Topup timing: `topup_create_timestamp`, `is_topup_today`
- Credit expiry: `is_credit_topup_expired`, `is_credit_topup_expired_today`

## Key Dimensions

- Partition: `grass_region`, `grass_date`, `tz_type`
- Business: `order_type` / `order_type_name`, `credit_topup_type` / `credit_topup_type_name`, `credit_topup_main_type` / `credit_topup_main_type_name`
- Entity: `shop_id`, `user_id`, `order_id`
- Credit detail: `credit_topup_sub_type`, `credit_topup_sub_type_name`, `credit_program_name`, `credit_reason`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | `tz_type` (string), `grass_region` (string), `grass_date` (date) |
| HDFS Path | `hdfs://R2/...` (mkplpaidads_data) / `hdfs://D2/...` (data_paidadsmart) |
| Retention | - |
| Column Count | 52 (base) + partition columns; newer workflow adds ~20 extra columns (e.g. `topup_amt_usd_his`, `notified`, `svs_entity_type`, `ads_credit_extinfo`, `effective_type`, `consumption_type`, `ads_package_id`, `operator`, `action_type`) |
| Region Coverage | ID, TH, VN, PH, SG, TW, MY, MX, BR, AR, CO, CL |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 134 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
