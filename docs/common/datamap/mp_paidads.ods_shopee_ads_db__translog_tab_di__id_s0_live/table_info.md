<!-- ads-workspace-gdoc-sync: gdoc_id=1BL3xBMWQlbd2pWiveDpSyebIT0hv8gUWRwZH-IiPdf0 gdoc_url=https://docs.google.com/document/d/1BL3xBMWQlbd2pWiveDpSyebIT0hv8gUWRwZH-IiPdf0/edit -->

# mp_paidads.ods_shopee_ads_db__translog_tab_di__id_s0_live

## Description

- **Desc:** ODS-layer daily snapshot of the ads translog (transaction log) table, Indonesia-only variant. Records every financial transaction event in the ads system -- deductions (CPC click, CPM impression, CPS order), top-ups, and balance adjustments. Each row represents a single translog entry with raw fields from the ads billing DB, plus a decoded extinfo JSON blob containing rich billing/auction metadata. Single partition (`grass_date`) only; region is implicitly ID.
- **Granularity:** per-transaction (one row per deduct_unique_id + adsid + operation)
- **Use Case:** Revenue reconciliation for ID market (comparing translog against report_ng / dwd_advertise_performance_di), translog data investigation/DDL inspection, credit breakdown analysis (paidFreeExpirySummary), CPM/CPC deduction verification
- **Update Frequency:** Daily

## Key Metrics

- Revenue/Cost: `price` (raw deduction amount, in 10^-5 units), `dai_after_balance - dai_before_balance` (total cost per transaction), `acc_before_balance / acc_after_balance` (account balance before/after)
- Decoded extinfo fields: `$.deductionInfo.deductionPrice`, `$.voucherDeductionPrice`, `$.expectDeductPrice`, `$.cpsTotalExpense`, `$.cpsAvailableBudget`, `$.validBalance`, `$.availableBalance`
- Credit breakdown: `$.paidFreeExpirySummary.entries` (type 1=paid without expiry, 2=paid with expiry, 3=free without expiry, 4=free with expiry), `$.adsCredits` (per-credit-order deduction details)
- Reconciliation: `SUM(entry.amount) / 100000` (total deduction from extinfo) vs `dai_after_balance - dai_before_balance` or `expenditure_amt_local` from dwd_advertise_performance_di

## Key Dimensions

- Partition: `grass_date` (DATE)
- Transaction: `operation` (1=CPC deduction, 2=topup from order, 3=manual topup, 4=wallet topup, 5=deduct order, 6=SVS topup, 8=seller mission topup, 9=SRM topup, 10=negative topup, 11=CPM deduction, 15=CPS deduction)
- Ads: `adsid`, `shopid`, `userid`, `placement`, `itemid`, `deduct_unique_id`
- Decoded extinfo: `$.pricingType`, `$.entrance`, `$.subEntrance`, `$.campaignid`, `$.entryPoint`, `$.bidType`, `$.matchType`, `$.recallType`, `$.trafficSource`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_date (DATE) |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/ods_shopee_ads_db__translog_tab_di__id_s0_live |
| Retention | - |
| Column Count | 24 (DDL) + 2 undocumented (acc_user_id, account_id) |
| Region Coverage | ID only |
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

- Studio Tasks References: 15 files (14 read + 1 write/DDL)
- L7D Query Count: -
- Completeness: -
- Popularity: -
