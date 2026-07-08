<!-- ads-workspace-gdoc-sync: gdoc_id=1Kf_-92OdvDTgymsU7IQOcHy_JI4hwqcXLL_Kasbb2Vs gdoc_url=https://docs.google.com/document/d/1Kf_-92OdvDTgymsU7IQOcHy_JI4hwqcXLL_Kasbb2Vs/edit -->

# mp_paidads.dim_roi2_auto_rebate_blacklist__reg_s0_live

## Description

- **Desc:** ROI2 自动返佣黑名单维度表，记录被标记为 '1P_SIP' 标签的 Shop，用于在自动返佣计算中排除这些店铺。数据来源 `mp_seller.dim_seller_tag_entity__reg_live`。
- **Granularity:** shop_id x blacklist_date per grass_region x grass_date
- **Use Case:**
  1. Daily ROI2 自动返佣 — 排除黑名单店铺，构建 `dim_whitelist_roi2`（ads_campaign_auto_rebate_details_1d）
  2. Weekly ROI2 自动返佣 — 排除黑名单期间店铺的返佣资格（ads_campaign_auto_rebate_details_1w）
  3. GMS/MPD 白名单构建 — 在赋予 GMS 自动返佣和 Escrow 白名单前排除黑名单店铺（dim_gmsmpd_auto_rebate_whitelist）
  4. 返佣状态 Ad-hoc 排查 — 手动查询特定地区店铺是否在黑名单中（manual_tasks）
- **Update Frequency:** Daily

## Key Metrics

N/A — 纯维度表，不含业务指标。

## Key Dimensions

- 分区: grass_region, grass_date
- 业务: shop_id, blacklist_date

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | grass_region (STRING), grass_date (DATE) |
| HDFS Path | `${HIVE_PATH}/dim_roi2_auto_rebate_blacklist__reg_s0_live` |
| Retention | - |
| Column Count | 4 (2 data + 2 partition) |
| Region Coverage | VN, TW, TH, SG, PH, MY, MX, ID, CO, CL, BR (11 regions) |
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

- Studio Tasks References: 53 files (22 write + 31 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
