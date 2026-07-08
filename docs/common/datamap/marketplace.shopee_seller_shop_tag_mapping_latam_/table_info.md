<!-- ads-workspace-gdoc-sync: gdoc_id=1PAQgDEU4KAGhDcczMCAan_LGavZZEIVInO_4eUACtc0 gdoc_url=https://docs.google.com/document/d/1PAQgDEU4KAGhDcczMCAan_LGavZZEIVInO_4eUACtc0/edit -->

# marketplace.shopee_seller_shop_tag_mapping_latam_

## Description

- **Desc:** Marketplace 侧卖家店铺-标签映射表（LatAm 区域），用于 feature toggle 白名单体系。该表通过 tag_id 连接 feature_toggle_tag_mapping，再通过 feature_id 连接 feature_toggle_info，形成 "功能 → 标签 → 店铺" 的三层白名单关系链。Ads 侧仅作只读查询，不负责写入。
- **Granularity:** shop_id x tag_id x region（每条记录为某一店铺在某一区域下关联的某一条标签）
- **Use Case:**
  - GMS/MPD Auto Rebate 白名单：通过 tag 查询有权自动返佣的店铺（feature_key: `product_ads_gms_auto_rebate`, `product_ads_gms_mpd_roas_protection`）
  - Shop CPS 白名单：查询有权使用 CPS 功能的店铺（feature_key: `cps_feature`）
  - Advertiser Escrow 白名单：查询自动托管白名单店铺（feature_key: `ads_atu_escrow`）
  - Livestream Simple Mode 白名单：查询直播简易模式白名单（feature_key: `ads_live_gmv_max_target_roas`, `ads_live_gmvmax_target_migrate`）
  - Livestream ROI2 白名单：同上，适用于 roi2 维度
  - Weekly Rebate Rules 白名单：查询活动返佣规则白名单（feature_key: `weekly_rebate_rules`）
- **Update Frequency:** Daily（集市配额写入，Ads 侧每日读取）

## Key Metrics

- 店铺标签映射数（按 shop_id, tag_id 去重）
- 活跃映射数（shop_tag_mapping_status = 1）

## Key Dimensions

- 分区: region (LatAm 国家，如 MX/BR/CO/CL)
- 业务:
  - shop_id — 店铺标识
  - tag_id — 标签标识（与 feature_toggle_tag_mapping_tab 关联）
  - shop_tag_mapping_status — 映射状态（1 = active）
  - region — 区域（LatAm 代码）

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | LatAm (MX, BR, CO, CL) |
| DQC Status | - |
| Table Size | - |

> Note: 该表为 marketplace 侧表，DDL 不在 ads 代码库中。Technical Properties 需运行 `--source from-di` 补充。

## Business Properties

> 未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 20 files (16 active workflows, 4 deprecated)
- L7D Query Count: -
- Completeness: -
- Popularity: -
