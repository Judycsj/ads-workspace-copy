<!-- ads-workspace-gdoc-sync: gdoc_id=1LZtlHOiwIu2PaS5EncVfVs44w2uXRMfybtE0RU2Trok gdoc_url=https://docs.google.com/document/d/1LZtlHOiwIu2PaS5EncVfVs44w2uXRMfybtE0RU2Trok/edit -->

# mp_paidads.dim_shop_info__reg_s0_live

## Description

- **Desc:** 广告店铺维度表，按天/区域维护每个 shop 的卖家属性、分层标签、广告投放类型、平台排名等维表信息。是 Ads 业务最核心的维度表之一，用作各种报表和策略分析的基础宽表。
- **Granularity:** daily x grass_region x shop_id
- **Use Case:**
  - Take Rate 日报与月报（叠加广告收入与订单 GMV 计算 take rate）
  - 商家分层分析（seller_tier / advertiser_tier 分组聚合）
  - GMV Max 出价策略建议（建议预算/ROI，按类目+分层取分位数）
  - 广告诊断与大盘分析（sellercenter diagnosis、overall table）
  - 激励策略卖家筛选（incentive seller list、wide table）
  - 智能券支持卖家标签（smart voucher support eligibility）
  - 搜索/品牌广告供应增长（supply growth exclude shops）
- **Update Frequency:** Daily (每月初基于上月数据刷新 seller_tier 和 advertiser_tier)

## Key Metrics

本表为维度表，不包含指标数据。下游使用的主要维度字段：

- 卖家分层: seller_tier, advertiser_tier
- 卖家类型: seller_type, cluster, principal_type, seller_type_1p, cb_seller_type
- 卖家状态: seller_status, advertiser_status
- 广告投放类型: ads_placement_type, seller_active_ads_placement_type
- 关键卖家标识: key_seller_90, key_seller_95
- 类目: shop_level1_global_be_category, shop_level2_global_be_category
- SIP 相关: is_cb_sip_affiliated, is_local_sip_affiliated, is_sip_primary

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 主键: shop_id
- 业务维度: seller_type, cluster, shop_level1_global_be_category, seller_tier, advertiser_tier, seller_status, advertiser_status, ads_placement_type, seller_type_1p

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string), grass_region (string), grass_date (DATE) |
| HDFS Path | `${path}` (per-region: `${HIVE_PATH}/dim_shop_info__reg_s0_live`) |
| Retention | - |
| Column Count | 32 (29 data + 3 partition) |
| Region Coverage | VN, TW, TH, SG, PH, MY, MX, ID, BR (9 区域) |
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

- Studio Tasks References: 204 files (181 workflows, 2 scheduled_tasks, 21 manual_tasks, 2 playground)
- L7D Query Count: -
- Completeness: -
- Popularity: -
