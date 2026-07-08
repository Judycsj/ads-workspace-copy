<!-- ads-workspace-gdoc-sync: gdoc_id=1xe9EtTFafumzYnZeDdj2F-Cq5tQElX8T2bsotWmKOOk gdoc_url=https://docs.google.com/document/d/1xe9EtTFafumzYnZeDdj2F-Cq5tQElX8T2bsotWmKOOk/edit -->

# mp_paidads.dws_user_net_ads_revenue_1d__reg_s0_live

## Description

- **Desc:** 用户维度广告净收入日表。从广告扣款明细和展示广告流水出发，计算每个 (user_id, item_id, ads_id, campaign_id) 粒度的收入拆解，包含付费/免费/过期 credit 收入、展示广告收入、各类免费 credit 专项收入（SCS/SIP/Lovito/Gov），以及税费处理。数据源包含广告扣款、充值、VAT 税率、展示广告流量、汇率换算等，经 tax/topup/deduction/expiry 多个临时视图加工后 UNION ALL 汇总写入。
- **Granularity:** daily x user_id x item_id x ads_id x campaign_id x entrance x placement x pricing_type x tz_type x grass_region x credit_topup_type
- **Use Case:**
  - 用户×商品粒度广告净收入计算，用于 PC2（Profit Contribution 2）模型训练和离线评估
  - 按 common_feature_group 聚合的广告净收入分析（dws_common_feature_user_item_pc2_1d）
  - 广告收入对账校验（raw_gross_ads_revenue 与 translog 扣款对比）
  - 按 seller_type/seller_type_1p 维度拆分 CB 卖家收入看板
  - 免费 credit 各子类型（SCS/SIP/Lovito/Gov）收入专项分析
- **Update Frequency:** Daily (workflow 调度，按 grass_region 分区覆盖写入)

## Key Metrics

- 总收入类: raw_gross_ads_revenue_usd_1d, gross_ads_revenue_usd_1d, net_ads_revenue_usd_1d
- 付费收入: paid_credit_revenue_usd_1d, raw_paid_credit_revenue_usd_1d
- 展示广告收入: display_ads_revenue_usd_1d, raw_display_ads_revenue_usd_1d
- 免费 credit 收入: others_free_credit_revenue_usd_1d, raw_others_free_credit_revenue_usd_1d, free_ads_revenue_amt_usd_1d
- 免费 credit 抵扣: free_credit_deduction_amt_usd_1d
- 税费: tax_paid_on_free_credit_revenue_usd_1d
- 免费 credit 子项: sip_free_credit_revenue_usd_1d, scs_free_credit_revenue_usd_1d, lovito_free_credit_revenue_usd_1d, gov_free_credit_revenue_usd_1d
- 过期 credit: paid_credit_expired_amt_usd_1d (注意: 全维度统一分摊值，不可直接 SUM), others_free_credit_expired_amt_usd_1d (同上)

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 用户/商品: user_id, item_id, shop_id
- 广告: ads_id, campaign_id, entrance, placement, sub_entrance, pricing_type
- 流量分类: entry_point, entry_point_v2, traffic_type, sub_product_type, product_type, main_product_type
- Credit 维度: credit_order_type, credit_topup_type, credit_topup_sub_type, credit_program_id, credit_program_name, credit_reason

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | `${HIVE_PATH}/dws_user_net_ads_revenue_1d` |
| Retention | - |
| Column Count | 47 |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, MX, BR (9 regions); US (独立 workflow) |
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

- Studio Tasks References: 58 files (20 write, 38 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
