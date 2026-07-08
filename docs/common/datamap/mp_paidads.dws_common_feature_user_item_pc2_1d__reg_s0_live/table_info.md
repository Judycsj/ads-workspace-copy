<!-- ads-workspace-gdoc-sync: gdoc_id=13iKvMjbXNyyqtgqCLhiKfs2e-FUpYeDelg0_cqkjkXk gdoc_url=https://docs.google.com/document/d/13iKvMjbXNyyqtgqCLhiKfs2e-FUpYeDelg0_cqkjkXk/edit -->

# mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live

## Description

- **Desc:** PC2 (Platform Contribution 2.0) 用户-商品级按 common_feature 细分表，包含 GMV、佣金、手续费、补贴、付费广告收入和券成本等全链路利润指标。通过 omni 流量归因将订单归因到具体推荐场景 (common_feature)，并汇总 MP (Marketplace) 佣金和补贴、付费广告消耗/GMV/券成本，计算最终 PC2 和 adjusted proxy PC2。
- **Granularity:** daily x region x common_feature x user_id x item_id
- **Use Case:**
  - PC2 利润分析：按场景/类目/商品/用户维度拆解利润构成
  - 推荐场景贡献拆解 (Platform / Search / YMAL / Daily Discover 等)
  - 与 `dws_user_pc2_1d__reg_s0_live` (用户级 PK 不准确) 做数据验证对比
  - 作为 `item_pc2_commission_fee_14d` 的上游表提供 commissions fee 按场景拆解数据
  - 付费广告利润 ROI 分析
- **Update Frequency:** Daily

## Key Metrics

- GMV 类: omni_gmv_usd_1d
- 佣金类: estimate_mandatory_commission_fee_usd_1d, estimate_optional_commission_fee_usd_1d (含 local_c2c/local_mall/cb 细分)
- 手续费类: estimate_handling_fee_usd_1d, estimate_seller_handling_fee_usd_1d, estimate_buyer_handling_fee_usd_1d
- MP 收入: estimate_mp_revenue_usd_1d (commissions + handling + paid_ads_revenue)
- 补贴/返利类: estimate_promotion_excl_3pl_usd_1d, estimate_logst_prm_usd_1d, estimate_item_card_prm_usd_1d, estimate_voucher_prm_usd_1d, estimate_coin_prm_usd_1d
- 利润类: proxy_pc2_usd_1d (PC2 = mandatory + optional + handling + paid_ads_revenue - paid_ads_voucher), adjusted_proxy_pc2_usd_1d (adjusted by local category PC2 rate)
- 付费广告类: paid_ads_revenue_usd_1d, paid_ads_broad_gmv_usd_1d, paid_ads_voucher_amt_usd_1d

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 核心维度: common_feature, user_id, item_id
- 关联维度: level1/2_global_be_category_id (via dim_item, 不在表中但写流程中关联)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET (Hive SerDe) |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | ${HIVE_PATH}/dws_common_feature_user_item_pc2_1d__reg_s0_live |
| Retention | - |
| Column Count | 29 (DDL) + 1 (added 2026-05 via ALTER) = 30 |
| Region Coverage | SG, MY, PH, TW, ID, TH, VN, BR (+ CO, CL, MX possibly) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 7 files (2 write, 5 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
