<!-- ads-workspace-gdoc-sync: gdoc_id=1stwl4OzXINf5Az3QXytIgplr_RC-V6r2-TTrs6-Rf2U gdoc_url=https://docs.google.com/document/d/1stwl4OzXINf5Az3QXytIgplr_RC-V6r2-TTrs6-Rf2U/edit -->

# marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__

## Description

- **Desc:** Feature Toggle 与 Seller Tag 的桥接映射表，来自 Marketplace 平台。将 feature toggle（由 feature_id 标识）与 seller tag（由 tag_id 标识）关联，标注了 mapped 店铺通过其 tag 继承了哪些 feature toggle 行为。这是按地域分片的表（后缀 `__{region}_df`），在 Ads 团队中用于构建自动返白名单和 ROAS 保护等功能的白名单。
- **Granularity:** feature_id + tag_id（每个 feature-tag 映射一行）
- **Use Case:**
  - ROI2/MPD auto-rebate whitelist 构建（通过 feature toggle -> tag -> shop 三级关联）
  - product_ads_gms_mpd_roas_protection 白名单构建
  - 基于 tag 的灰度/白名单功能激活
- **Update Frequency:** Continuous（快照表，`_df` 后缀表示每日全量 dump）

## Key Metrics

- 不适用（映射/配置表，无数值指标）

## Key Dimensions

- feature_id: Feature Toggle 唯一 ID，与 feature_toggle_info_tab 关联
- tag_id: Seller Tag ID，与 shop_tag_mapping_tab 关联
- feature_toggle_tag_mapping_status: 映射状态（3 = 已删除，查询时排除）
- ctime: 创建时间

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | -（按地域分片表，无标准分区） |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, CO, CL（从 workflow 地域推断） |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | Marketplace |
| Business Domain | Seller Feature Toggle |
| DW Layer | ODS（原始配置快照） |

## Popularity

- Studio Tasks References: 11 files (10 write + 1 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
