<!-- ads-workspace-gdoc-sync: gdoc_id=1T-2Frwg6yT9qcIQwkl_7o5InJUCL5e_KTRstb45qAgc gdoc_url=https://docs.google.com/document/d/1T-2Frwg6yT9qcIQwkl_7o5InJUCL5e_KTRstb45qAgc/edit -->

# traffic.dwd_position_lead_atc_di__reg_live

## Description

- **Desc:** 用户加购（Lead ATC）事件明细表，记录 user 对 shop + item 的加购行为。由 traffic 团队生产，ads 侧主要用于潜在买家识别（dws_l2cat_potential_buyer）。
- **Granularity:** daily x user_id x shop_id x item_id（加购事件级）
- **Use Case:**
  1. L2 类目潜在买家计算 — 统计近 14 天用户对二类目下有效店铺及商品的加购次数（atc），与 ppv、orders 组合计算 potential_buyer_type
  2. 目标受众构建 — 识别对特定 shop_l2/item_l2 有加购行为的用户群
- **Update Frequency:** Daily（di 后缀，workflow 每日调度，滚动 14 天窗口）

## Key Metrics

- **atc** (Add to Cart count): `COUNT(*)` 按 user_id / shop_l2 / item_l2 聚合的加购次数

## Key Dimensions

- 分区: grass_region, grass_date
- 用户: user_id
- 店铺: shop_id（JOIN dim_shop 获取 shop_level2_global_be_category_id）
- 商品: item_id（JOIN dim_item 获取 level2_global_be_category_id）

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG, MY, PH, TH, TW, VN, MX, CO, CL, BR (10 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

*未抓取 DataMap，请运行 --source from-di 补充*

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 21 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
