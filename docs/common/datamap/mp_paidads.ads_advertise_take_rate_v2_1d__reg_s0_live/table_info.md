<!-- ads-workspace-gdoc-sync: gdoc_id=1vIuIfRZc0DNcgK35ZUuSW-DGzcpRQvK6F2_rxwjrx1o gdoc_url=https://docs.google.com/document/d/1vIuIfRZc0DNcgK35ZUuSW-DGzcpRQvK6F2_rxwjrx1o/edit -->

# mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live

## Description

- **Desc:** 广告 Take Rate 日汇总表 — 按 entry_point x pricing_type x 卖家属性 聚合广告效果指标（impressions/clicks/orders/GMV）、收入指标（gross/net/SIP/voucher）和平台大盘指标（platform GMV/NMV/impressions）。是 Ads Take Rate 分析的核心事实表，用于计算"广告收入 / 平台 GMV"等运营效率指标。
- **Granularity:** daily x entry_point x pricing_type x seller_type_1p x is_cb_shop x product_type x grass_region x tz_type
- **Use Case:** OKR Take Rate 日报（按 region/entry_point/pricing_type 拆分）、效率指标拆解（CPM/CPC/CTR/CR/ROI/Ad Load）、大盘汇总表（GROUPING SETS 多维度聚合）、MTD 环比分析（entry_point take rate contribution）、ROI3 voucher 成本拆分、Live Ads tracker、收入结构分析（gross/net/1P/SIP/voucher）
- **Update Frequency:** Daily

## Key Metrics

- 收入类: `ads_rev_usd`, `net_ads_rev_usd`, `net_ads_rev_excl_sip_usd_1d`, `gross_ads_rev_usd`
- 平台类: `platform_gmv`, `platform_gmv_excl_testorder` (SUM DISTINCT), `platform_imp` (SUM DISTINCT)
- 效果类: `ads_imp`, `ads_click`, `ads_order`, `ads_gmv_usd`, `entry_point_imp` (SUM DISTINCT)
- 券成本: `ads_voucher_ads_nmv_cost_usd`, `ads_voucher_omni_platform_nmv_cost_usd` (MAX/SUM DISTINCT)

## Key Dimensions

- 分区: `grass_date`, `grass_region`, `tz_type`
- 业务: `entry_point`, `traffic_type`, `pricing_type`, `main_product_type`, `seller_type_1p`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string) / grass_region (string) / grass_date (date) — 三级分区 |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/ads_advertise_take_rate_v2_1d (US: hdfs://D2/...) |
| Retention | 3650 天 (10 年) |
| Column Count | 64 列 + 3 分区列 |
| Region Coverage | ID, VN, TH, SG, MY, PH, TW, BR, MX + Views: CO, CL |
| DQC Status | SUCCESS |
| Table Size | 1.49 GB |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | muyu.gao@shopee.com, renjie.xia@shopee.com |
| Team | mkplpaidads |
| Project | data_paidadsmart(data_paidadsmart) |
| Business Domain | Marketplace - Paid Ads |
| Data Mart | Paid Ads Mart |
| DW Layer | ADS |
| Market Region | REG |

## Popularity

- Studio Tasks References: 129 files
- L7D Query Count: 6,296
- Completeness: 71.57
- Popularity: 100.00
