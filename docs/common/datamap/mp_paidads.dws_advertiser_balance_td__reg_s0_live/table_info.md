<!-- ads-workspace-gdoc-sync: gdoc_id=1_ArGdqE3GRIkuPVHR4q4WiuNDeyHGuZuLM-5y306GHs gdoc_url=https://docs.google.com/document/d/1_ArGdqE3GRIkuPVHR4q4WiuNDeyHGuZuLM-5y306GHs/edit -->

# mp_paidads.dws_advertiser_balance_td__reg_s0_live

## Description

- **Desc:** 广告主账户日末余额快照表（TD = To-Date），按信用额度类型（免费/付费、有期限/无期限）和产品线（ROI2、直播、搜索品牌广告）细分，展示每个店铺当日可用的广告信用额度。
- **Granularity:** daily x shop_id x tz_type x grass_region
- **Use Case:**
  1. 广告主市场营销日报（ads_advertiser_mkt_1d） — JOIN 补充广告主快照的余额字段
  2. 扣费损失分析（ads_deduction_loss） — JOIN 分析扣费损失与可用余额的关系
  3. 余额对账 — 对比信用余额与预期扣费
  4. 广告主余额调试 — 查询特定店铺的当前余额
- **Update Frequency:** Daily（按 region 调度运行）

## Key Metrics

- 总余额类: total_eod_balance_td, total_eod_balance_usd_td
- 免费额度(有期限): free_credit_w_expiry_eod_balance_amt_td, free_credit_w_expiry_eod_balance_amt_usd_td
- 免费额度(无期限): free_credit_wo_expiry_eod_balance_amt_td, free_credit_wo_expiry_eod_balance_amt_usd_td
- 付费额度(有期限): paid_credit_w_expiry_eod_balance_amt_td, paid_credit_w_expiry_eod_balance_amt_usd_td
- 付费额度(无期限): paid_credit_wo_expiry_eod_balance_amt_td, paid_credit_wo_expiry_eod_balance_amt_usd_td
- 期初余额: paid_credit_wo_expiry_sod_balance_amt_td, paid_credit_wo_expiry_sod_balance_amt_usd_td
- 产品线余额: roi2_eod_balance_amt_td/usd, livestream_eod_balance_amt_td/usd, search_brand_eod_balance_amt_td/usd

## Key Dimensions

- 分区: tz_type (STRING), grass_region (STRING), grass_date (DATE)
- 业务主键: shop_id (BIGINT)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/dws_advertiser_balance_td |
| Retention | - |
| Column Count | 22 (16 columns in DDL + 6 product-line columns in INSERT) |
| Region Coverage | SG, MY, PH, TH, TW, VN, ID, BR, MX, CO, CL, AR + US sub-regions (MX, BR, AR, CO, CL) |
| DQC Status | - |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 35 files (18 write, 17 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
