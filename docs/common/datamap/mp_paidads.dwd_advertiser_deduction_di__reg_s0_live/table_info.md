<!-- ads-workspace-gdoc-sync: gdoc_id=1AFNyK1siElMU3ECn0HqserdmT78m86Ta1szamzbMTsg gdoc_url=https://docs.google.com/document/d/1AFNyK1siElMU3ECn0HqserdmT78m86Ta1szamzbMTsg/edit -->

# mp_paidads.dwd_advertiser_deduction_di__reg_s0_live

## Description

- **Desc:** DWD layer table recording per-deduction (click/CPS/CPR) transaction details for advertisers. Splits each transaction event into rows by credit type (paid/free/SIP/SCS/gov) with deduction amounts in local currency and USD. Combines transaction data with credit topup metadata and exchange rates.
- **Granularity:** daily x per-deduction-event x credit-type x region
- **Use Case:** Net ads revenue calculation (dws_advertise_net_ads_revenue_1d), budget hit analysis (shop_ads_budget_suggestion), hourly deduction pacing for budget optimization, credit type breakdown (paid vs free vs gov), advertiser-level spending analysis
- **Update Frequency:** Daily

## Key Metrics

- 扣费类: deduction_amt (local), deduction_amt_usd, deduction_price, deduction_price_usd, voucher_deduction_price, voucher_deduction_price_usd
- 余额类: acc_before_balance, acc_after_balance, credit_amt_before_deduct, credit_amt_after_deduct, valid_balance_amt, available_balance_amt
- CPS 类: cps_total_expenditure_amt, cps_available_budget
- 充值类: original_topup_credit_amt

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 广告: ads_id, campaign_id, shop_id, placement, pricing_type, entrance, sub_entrance
- 信用类型: credit_topup_type, credit_topup_type_name, credit_order_type, credit_order_type_name, credit_topup_sub_type_name
- 卖家: seller_type_1p, seller_type
- 事件: operation (event_code), effective_type, traffic_source, consumption_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | - |
| Retention | - |
| Column Count | ~60 |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, AR |
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

- Studio Tasks References: 30 files (11 write, 19 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
