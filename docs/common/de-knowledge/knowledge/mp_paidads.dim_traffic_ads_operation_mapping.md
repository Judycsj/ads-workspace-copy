<!-- ads-workspace-gdoc-sync: gdoc_id=1bTz1aaiVJDZwIZ6BoxYoEl4_0G4DA5Yw_TwsHUXcY2A gdoc_url=https://docs.google.com/document/d/1bTz1aaiVJDZwIZ6BoxYoEl4_0G4DA5Yw_TwsHUXcY2A/edit -->

# mp_paidads.dim_traffic_ads_operation_mapping

**分层**：DIM（维度层）
**主键**：`main_product_type` + `ads_operation` + `page_type` + `page_section` + `target_type`（联合唯一）
**分区**：无分区字段
**更新频率**：手工维护，按需更新（最近修改日期见 `modify_date` 字段）
**引用频次**：本表为末端 ADS 层维表，在候选表 ETL SQL 中未被其他候选表直接引用

---

## 业务描述

本表是广告流量埋点事件的操作映射维表，用于将广告系统底层的数字化操作码（`ads_operation`）翻译为业务可读的行为类型（`operation`）与流量维度组合（`page_type`、`page_section`、`target_type`）。其核心价值在于打通广告后端事件协议与前端埋点语义，使下游分析师和数据工程师能以统一的业务语言描述广告曝光、点击、观看等行为，而无需关心底层枚举编码细节。

本表覆盖 Shopee 平台所有主要广告产品类型，包括 Product Ads（商品广告）、Brand Ads（品牌广告）、Video Ads（视频广告）、Live Ads（直播广告）和 Shop Ads（店铺广告）。典型使用场景包括：在流量事件宽表中 JOIN 本表以补全广告操作语义、过滤特定页面或行为类型的广告事件、以及判断某条事件是否为重复计数记录。

本表由运营/产品团队通过 Google Sheets 手工维护，数据量约 226 行，结构轻量且稳定，通常作为 LEFT JOIN 的右表使用。使用时须关注 `if_duplicate` 字段（标记重复记录），以及 `modify_date` 字段以追踪最新变更内容。

---

## 字段列表

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `main_product_type` | string | 广告产品大类，枚举值：`Product Ads`、`Brand Ads`、`Video Ads`、`Live Ads`、`Shop Ads`。映射规则参见 [维护文档](https://docs.google.com/spreadsheets/d/142y9-AkwK_dpM7vqvmnyvhTfdaJw1virV23KAdnJQY4/edit?gid=0#gid=0) |
| `ads_operation` | string | 广告操作事件的数字枚举码，对应后端协议中定义的事件类型（如 `1`=impression、`2`=click、`13`=view、`14`=click_in_room 等）。完整枚举定义参见 [beeshop_ads.proto#L55](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L55)。⚠️ 该字段为字符串类型存储的数字码，相同数字码在不同 `main_product_type` 下语义可能不同，不可单独作为事件类型过滤条件，需结合 `main_product_type` 使用 |
| `operation` | string | 事件动作的语义描述，来自前端（FE），枚举值：`impression`（曝光）、`click`（点击）、`view`（观看）、`action_video`（视频动作）、`action_video_start`、`action_video_stop`、`action_video_end`、`action_exit_streaming`（退出直播间）、`action_view_pdp`（查看商品详情页） |

### 维度：流量事件定位

| 字段 | 类型 | 说明 |
|------|------|------|
| `page_type` | string | 流量事件归属的页面类型，标识用户所在的一级页面（如 `search`=搜索页、`home`=首页、`product`=商品详情页、`shop`=店铺页、`video`=视频页、`streaming_room`=直播间等）。`/` 表示未指定或通用场景 |
| `page_section` | string | 流量事件归属的页面区域，标识页面内的具体版块（如 `you_may_also_like`=猜你喜欢、`daily_discover`=每日发现、`related_product_list`=相关商品列表等）。`/` 表示未指定 |
| `target_type` | string | 流量事件对应的目标类型，标识用户操作的具体元素（如 `item`=商品卡片、`shop`=店铺、`streaming`=直播流、`video_play`=视频播放等）。`/` 表示未指定 |

### 维度：数据质量与维护信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `if_duplicate` | string | 是否为重复记录标记，用于在聚合统计时剔除重复计数的事件组合。⚠️ 当前样本数据中该字段均为空，使用时须以实际维表最新值为准；若为非空则该行应在去重统计中排除 |
| `modify_date` | string | 本条映射规则的最近修改日期（格式：`YYYY-MM-DD`），用于追踪维表变更历史，不代表数据同步时间 |
| `ingestion_timestamp` | string | DataHub 写入本表的时间戳，记录 Google Sheets 快照同步至数仓的时刻。⚠️ 该字段反映的是 ETL 同步时间而非业务数据时间，不可用于业务口径的时间过滤 |

---

## 查询使用须知

本表为维表，直接 SELECT 使用，无聚合场景。JOIN 时建议以 `main_product_type + ads_operation + page_type + page_section + target_type` 作为联合关联键，并注意过滤 `if_duplicate` 非空的行以避免重复计数。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets（`1VXm5FNicgqer8mft-nuC-cAcd8MPUcE2Fg9fnG9dOE4` / Sheet: `ads operation mapping` / gid: `451695571`） | 运营/产品团队手工维护的广告操作映射原始数据，通过 DataHub gws 接口（`sheets.spreadsheets.values.get`）定期快照同步至数仓 |

---

## 维表说明

### 维护方式

本表为 **Google Sheets 手工维护维表**，原始数据存储于 Google Sheets（Sheet 名：`ads operation mapping`），由广告运营或产品团队直接编辑维护。数仓通过 DataHub 的 `gws sheets.spreadsheets.values.get` 接口定期拉取快照并写入 Hive 表，写入时附加 `ingestion_timestamp` 字段记录同步时刻。

### 内容结构

维表共 226 行、8 列，每一行表示一种广告操作事件的完整语义组合，即：

```
(main_product_type, ads_operation) → (operation, page_type, page_section, target_type, if_duplicate)
```

各广告产品类型覆盖的事件类型和页面场景各有侧重：
- **Product Ads**：覆盖搜索、首页、商品详情页、店铺、直播间、视频等几乎所有页面场景
- **Brand Ads**：覆盖搜索页品牌展位、首页 Banner、店铺页浏览事件及视频互动动作
- **Video Ads**：主要覆盖视频播放、浮窗展示等视频广告专属场景
- **Live Ads**：覆盖直播入口曝光/点击及直播间内的多种互动行为
- **Shop Ads**：覆盖搜索页店铺广告展示与点击行为

### 注意事项

- 同一 `ads_operation` 编码在不同 `main_product_type` 下可能对应不同的业务行为（如 `ads_operation=14` 在 Live Ads 中为直播间内点击，在 Video Ads 中为视频广告点击），**务必以 `(main_product_type, ads_operation)` 联合键进行关联**，切勿单独用 `ads_operation` 过滤。
- `if_duplicate` 字段当前多为空值，但含义为标记重复计数行，接入下游统计时须确认该字段的最新填充状态。
- 维表内容随业务新增广告位而持续扩展，`modify_date` 可作为变更监控字段，建议定期核查最近修改的行以评估对下游逻辑的影响。

---

*文档生成时间：2026-05-20*