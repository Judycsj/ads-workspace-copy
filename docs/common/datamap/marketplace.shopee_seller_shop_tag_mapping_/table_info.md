<!-- ads-workspace-gdoc-sync: gdoc_id=1Moo9XLCWw3-EF34z927rfBe09YmxDLA5GXSPaLztBDc gdoc_url=https://docs.google.com/document/d/1Moo9XLCWw3-EF34z927rfBe09YmxDLA5GXSPaLztBDc/edit -->

# marketplace.shopee_seller_shop_tag_mapping_

> **实际表名**: `marketplace.shopee_seller_shop_tag_mapping_${region}_db__shop_tag_mapping_tab__reg_continuous_s0_live`，按 region 分表。

## Description

- **Desc:** Shop Tag 映射表 — Marketplace 卖家侧的 Feature Toggle 统一管理表中，负责维护 shop_id 与 tag_id 的多对多映射关系。通过该表，feature toggle 配置（feature_key -> feature_id -> tag_id）最终映射到具体店铺，实现按店铺粒度的功能开关放量/黑名单控制。
- **Granularity:** shop_id x tag_id（每行一个 shop-tag 映射对）
- **Use Case:**
  1. **GMS/MPD 自动返点白名单** — 通过 `product_ads_gms_auto_rebate`、`ads_atu_escrow`、`weekly_rebate_rules` 等 feature_key 提取对应店铺白/黑名单
  2. **直播广告简易模式白名单** — 通过 `ads_live_ads_gmv_max_simple` / `ads_live_gmvmax_simple_migrate` 控制直播 GMV Max 简易模式放量
  3. **直播广告 ROI2 白名单** — 通过 `ads_live_gmv_max_target_roas` / `ads_live_gmvmax_target_migrate` 控制 ROI2 模式放量
  4. **CPS 功能白名单** — 通过 `cps_feature` 控制 CPS 分佣功能开放
  5. **ROI2 自动返点保护白名单** — 通过 `product_ads_gms_mpd_roas_protection` 控制
- **Update Frequency:** 由 Marketplace 侧产出，广告侧为 Daily 消费
- **Production Owner:** Marketplace（卖家侧），非 Ads 团队
- **Is Ads Table:** No（该表为卖家侧维度表，广告系统只读消费）

## Key Metrics

> 无度量字段。该表为纯映射表，仅含 shop_id、tag_id、region、status 等维度和状态字段。

## Key Dimensions

- **shop_id** — 店铺 ID，映射的最终目标
- **tag_id** — 标签 ID，与 `feature_toggle_tag_mapping` 的 tag_id JOIN
- **region** — 大区，如 ID/MY/PH/SG/TH/TW/VN/BR/MX/CO/CL
- **shop_tag_mapping_status** — 映射状态，1 = 生效中

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (非 Ads 侧建表，DDL 未在代码库中找到) |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL（按 region 分表） |
| DQC Status | - |
| Table Size | - |

## Business Properties

> 未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 89 files (0 write, 89 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
