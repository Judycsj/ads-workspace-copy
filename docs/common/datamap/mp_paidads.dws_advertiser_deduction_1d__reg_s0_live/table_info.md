<!-- ads-workspace-gdoc-sync: gdoc_id=1xCwsyN9RWbNEBvGaawsarn2L5YildWTQvQmGToMRLX4 gdoc_url=https://docs.google.com/document/d/1xCwsyN9RWbNEBvGaawsarn2L5YildWTQvQmGToMRLX4/edit -->

# mp_paidads.dws_advertiser_deduction_1d__reg_s0_live

## Description

- **Desc:** Advertiser daily deduction (expenditure) summary table. Aggregates paid/free credit deductions from transaction events per shop per day, categorized by paid/free and with/without expiry. Output is in local currency then converted to USD via exchange rate.
- **Granularity:** daily x shop_id x tz_type x grass_region
- **Use Case:**
  - Downstream input to `ads_advertiser_mkt_1d__reg_s0_live` (advertiser marketing 1d summary) -- all 8 metrics + struct
  - Computing `ads_rev_usd` metric in `dim_advertiser_tier_tag__reg_s0_live` (advertiser tier classification by revenue)
  - Computing gross/net expenditure and revenue in `dws_advertiser_ads_rev_1d__reg_s0_live` (deprecated)
  - Data quality checks comparing with dev table
  - Take rate computation (search ads)
- **Update Frequency:** Daily

## Key Metrics

- 支出类 (Expenditure):
  - `paid_expenditure_wo_expiry_amt_local_1d` / `paid_expenditure_wo_expiry_amt_usd_1d` -- Paid deduction without expiry
  - `paid_expenditure_w_expiry_amt_local_1d` / `paid_expenditure_w_expiry_amt_usd_1d` -- Paid deduction with expiry
  - `free_expenditure_wo_expiry_amt_local_1d` / `free_expenditure_wo_expiry_amt_usd_1d` -- Free credit deduction without expiry
  - `free_expenditure_w_expiry_amt_local_1d` / `free_expenditure_w_expiry_amt_usd_1d` -- Free credit deduction with expiry

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 业务: shop_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/dws_advertiser_deduction_1d |
| Retention | - |
| Column Count | 12 |
| Region Coverage | MX, CO, CL, BR, AR (Latin America + Mexico) |
| DQC Status | - |
| Table Size | - |

## Business Properties

Not captured from DataMap. Run `--source from-di` to supplement.

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 33 files (5 write, 28 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
