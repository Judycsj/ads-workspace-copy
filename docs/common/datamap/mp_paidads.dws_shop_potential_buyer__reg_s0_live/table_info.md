<!-- ads-workspace-gdoc-sync: gdoc_id=10elNnvtROYWvU3xEaQjxNuOm_smZwX3d4HORBrv-YtE gdoc_url=https://docs.google.com/document/d/10elNnvtROYWvU3xEaQjxNuOm_smZwX3d4HORBrv-YtE/edit -->

# mp_paidads.dws_shop_potential_buyer__reg_s0_live

## Description

- **Desc:** 店铺潜在买家识别中间表。基于用户近30天店铺浏览、商品浏览、加购行为标签，计算用户对每个有效店铺的潜在购买意向分（0-3）。作为定向广告人群标签体系的数据源。
- **Granularity:** daily x grass_region x shop_id x user_id
- **Use Case:**
  1. 定向广告-潜在新买家识别: `dws_target_audience_potential_new_buyer__reg_s0_live` 从本表取 `potential_buyer_type>=2` 的高意向用户，结合类目相似买家，排除历史订单用户，生成店铺潜在新买家列表
  2. 定向广告-人群标签生成: `ads_target_audience_tags__reg_s0_live` 从本表取 `potential_buyer_type>=2` 的高意向用户，按店铺生成 buyer_type 标签位图
- **Update Frequency:** Daily

## Key Metrics

- 用户分层: `potential_buyer_type` (0-3, 基于近14-30天 shop view / pdp view / ATC 行为综合评分)

## Key Dimensions

- 分区: `grass_region`, `grass_date`
- 业务: `user_id` (买家), `shop_id` (店铺), `potential_buyer_type` (意向分层)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | grass_region (string), grass_date (DATE) |
| HDFS Path | `${HIVE_PATH}/dws_shop_potential_buyer` |
| Retention | - |
| Column Count | 3 (user_id, shop_id, potential_buyer_type) |
| Region Coverage | VN, TW, TH, SG, PH, MY, MX, ID, CO, CL, BR |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 69 files (24 write, 41 read, 4 playground)
- L7D Query Count: -
- Completeness: -
- Popularity: -
