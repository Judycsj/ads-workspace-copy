<!-- ads-workspace-gdoc-sync: gdoc_id=1Py2O6z4Zt9hLx5uCEyDpsOL4NvT6C270O23ePULsWtc gdoc_url=https://docs.google.com/document/d/1Py2O6z4Zt9hLx5uCEyDpsOL4NvT6C270O23ePULsWtc/edit -->

# mp_paidads.dim_advertiser_tier_threshold__reg_s0_live

## Description

- **Desc:** 广告主分层阈值配置表，定义各站点/地区下广告主按花费金额划分层级的收入门槛（USD）。每个地区每条记录对应一个广告主层级及该层级的最低花费阈值。
- **Granularity:** one row per region x advertiser tier
- **Use Case:**
  - dim_shop_info / dim_shop_info_daily 每日广告主分层打标 -- 根据广告主过去3个月的花费变化判定 advertiser_tier（large/medium/small/micro）
  - dim_shop_info_monthly / dim_shop_info_1m 月度广告主分层打标 -- 同上逻辑按月聚合
  - 跨站点分层一致性：各站点独立维护阈值，通过 grass_region 区分
- **Update Frequency:** 手动配置（非调度任务产出，代码库中未找到生产逻辑）

## Key Metrics

- 配置类：`min_value_usd` — 广告主层级最低花费阈值（USD）

## Key Dimensions

- 配置维度：`advertiser_tier` (large_advertiser / medium_advertiser / small_advertiser)
- 分区：`grass_region` — 站点区分（ID, MY, PH, SG, TH, TW, VN, BR, MX）

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_region (inferred from WHERE clause; no grass_date partition) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX (9 regions from read references) |
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

- Studio Tasks References: 40 files (0 write, 40 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
