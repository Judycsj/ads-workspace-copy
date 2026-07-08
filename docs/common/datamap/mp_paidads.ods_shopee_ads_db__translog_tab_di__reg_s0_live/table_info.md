<!-- ads-workspace-gdoc-sync: gdoc_id=1KEVrpMwGy5lhwGePJ9OHKxeZRr1_YMOFVmuIeKIhMvM gdoc_url=https://docs.google.com/document/d/1KEVrpMwGy5lhwGePJ9OHKxeZRr1_YMOFVmuIeKIhMvM/edit -->

# mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live

## Description

- **Desc:** ODS-layer daily snapshot of the ads translog (transaction log) table. Records every financial transaction event in the ads system -- deductions (CPC click, CPM impression, CPS order), top-ups, and balance adjustments. Each row represents a single translog entry with raw fields from the ads billing DB, plus a decoded extinfo JSON blob containing rich billing/auction metadata.
- **Granularity:** per-transaction (one row per deduct_unique_id + adsid + operation)
- **Use Case:** DWD deduction pipeline (dwd_advertiser_deduction_di), DWD transaction pipeline (dwd_advertiser_transaction_di), DWD performance pipeline (dwd_advertise_performance_di), DWD livestream performance pipeline (dwd_livestream_performance_di / dwd_advertise_livestream_ads_performance_di), seller report diff check, translog data investigation/backfill, revenue reconciliation
- **Update Frequency:** Daily

## Key Metrics

- Revenue/Cost: `price` (raw deduction amount, in 10^-5 units), `dai_after_balance - dai_before_balance` (total cost per transaction), `acc_before_balance / acc_after_balance` (account balance before/after)
- Decoded extinfo fields: `$.deductionInfo.deductionPrice`, `$.voucherDeductionPrice`, `$.expectDeductPrice`, `$.cpsTotalExpense`, `$.cpsAvailableBudget`, `$.validBalance`, `$.availableBalance`
- Credit breakdown: `$.paidFreeExpirySummary.entries` (type 1=paid without expiry, 2=paid with expiry, 3=free without expiry, 4=free with expiry), `$.adsCredits` (per-credit-order deduction details)

## Key Dimensions

- Partition: `grass_date`, `grass_region`, `tz_type`
- Transaction: `operation` (1=CPC deduction, 2=topup from order, 3=manual topup, 4=wallet topup, 5=deduct order, 6=SVS topup, 8=seller mission topup, 9=SRM topup, 10=negative topup, 11=CPM deduction, 15=CPS deduction)
- Ads: `adsid`, `shopid`, `userid`, `placement`, `itemid`, `deduct_unique_id`
- Decoded extinfo: `$.pricingType`, `$.entrance`, `$.subEntrance`, `$.campaignid`, `$.entryPoint`, `$.bidType`, `$.matchType`, `$.recallType`, `$.trafficSource`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type (STRING), grass_region (STRING), grass_date (DATE) |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/ods_shopee_ads_db__translog_tab_di__reg_s0_live |
| Retention | - |
| Column Count | 24 (DDL) + 2 undocumented (acc_user_id, account_id) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, AR, CL, CO |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 211 files (193 read + 18 write/DDL)
- L7D Query Count: -
- Completeness: -
- Popularity: -
