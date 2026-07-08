<!-- ads-workspace-gdoc-sync: gdoc_id=1eyUxgsTqfypq1hFyRg2lc27230FSjSZH0n3odcdGcjk gdoc_url=https://docs.google.com/document/d/1eyUxgsTqfypq1hFyRg2lc27230FSjSZH0n3odcdGcjk/edit -->

# mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live

## Description

- **Desc:** 自动返利白名单维度表，记录各区域中符合 GMS（商品广告自动返利）、MPD（多商品展示广告自动返利）、campaign_tag、自动托管(escrow)和 Weekly Rebate Rules 五种类型的店铺白名单。通过 feature toggle 系统管理白名单/黑名单/灰度状态。
- **Granularity:** daily x shop_id x type x region (每个shop在每个region每天每种whitelist type最多一行)
- **Use Case:**
  - 广告自动返利资格判定（GMS / MPD 白名单查询）
  - Weekly Rebate Rules 白名单规则管理
  - Campaign Tag 自动返利白名单维护
  - 自动托管(escrow)白名单管理
  - 返利相关数据质量排查（结合 `ads_campaign_auto_rebate_details_1w` 等表）
- **Update Frequency:** Daily (workflow 调度)

## Key Metrics

本表为维度表（dim），无核心指标。查询时通常使用 `count(*)` 聚合统计白名单店铺数量。

## Key Dimensions

- 分区: grass_region, grass_date
- 业务: shop_id, type (白名单类型), feature_mode (白名单模式), whitelist_date (开白日期)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (external table) |
| Partition Columns | grass_region (STRING), grass_date (DATE) |
| HDFS Path | `${HIVE_PATH}/dim_gmsmpd_auto_rebate_whitelist__reg_s0_live` |
| Retention | - |
| Column Count | 6 (4 data columns + 2 partition columns) |
| Region Coverage | VN, TW, TH, SG, MY, MX, ID, BR (8 regions) |
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

- Studio Tasks References: 18 files (1 read, 17 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
