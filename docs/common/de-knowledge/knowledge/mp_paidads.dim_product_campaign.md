<!-- ads-workspace-gdoc-sync: gdoc_id=1MqxvGJulpjog7IfzcYUO2Wmw4QO3F1HL8pxQJky5X7U gdoc_url=https://docs.google.com/document/d/1MqxvGJulpjog7IfzcYUO2Wmw4QO3F1HL8pxQJky5X7U/edit -->

# mp_paidads.dim_product_campaign

**分层：** DIM（维度层）
**主键：** `campaign_id`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日全量覆写（INSERT OVERWRITE）
**引用频次：** 4 次（候选表范围内）

---

## 业务描述

本表是付费广告域的**商品广告系列（Product Campaign）维度表**，存储各地区商家在 Shopee 商品广告平台上创建的广告系列的完整属性快照。每条记录代表截至当日已创建的一个广告系列，涵盖归属店铺与用户、竞价策略、商品投放范围、搜索关键词配置及定向配置等核心属性。

本表是付费广告分析体系的基础维度之一，广泛用于广告系列的属性下钻分析（如按竞价策略、投放位置分类统计），以及与绩效事实表（曝光、点击、GMV 等）进行维度关联，支撑广告主运营洞察和平台策略评估。

表中的时间字段（`campaign_create_datetime`、`campaign_modify_datetime`）已按各地区本地时区转换，方便本地化报表使用。`search` 和 `target` 为复合结构体字段，包含关键词广告配置及定向出价明细，需通过点操作符展开使用。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型标识。当前写入值固定为 `'local'`，表示日期字段已按各地区本地时区对齐。查询时**必须**指定此分区字段以避免全表扫描。 |
| `grass_region` | string | 地区编码（大写），如 `'MY'`、`'TH'`、`'PH'` 等。各地区通过参数化调度独立写入，覆盖所有上线地区。 |
| `grass_date` | date | 数据快照日期，格式 `yyyy-MM-dd`。含义为"截至该日已存在的广告系列"，即过滤条件为 `ctime < 次日零点（本地时间）`。 |

---

### 维度：主键与归属信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_id` | bigint | 广告系列唯一标识符，本表主键。对应源表中的 `campaignid`。 |
| `shop_id` | bigint | 广告系列所属店铺 ID。对应源表中的 `shopid`。 |
| `user_id` | bigint | 广告系列所属用户（卖家）ID。对应源表中的 `userid`。 |

---

### 维度：广告系列时间属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_create_datetime` | string | 广告系列创建时间，格式 `yyyy-MM-dd HH:mm:ss`，已按各地区本地时区转换。由源表 `ctime`（Unix 秒级时间戳，原始时区为 `Asia/Singapore`）转换而来。⚠️ 为字符串类型，范围过滤时请使用 `campaign_create_timestamp` 或显式 CAST，避免字典序比较错误。 |
| `campaign_create_timestamp` | bigint | 广告系列创建时间的 Unix 时间戳（秒级），对应源表 `ctime`，未做时区转换。适合精确时间范围筛选。 |
| `campaign_modify_datetime` | string | 广告系列最近一次修改时间，格式 `yyyy-MM-dd HH:mm:ss`，已按各地区本地时区转换。⚠️ 同 `campaign_create_datetime`，为字符串类型，时间比较建议使用 `campaign_modify_timestamp`。 |
| `campaign_modify_timestamp` | bigint | 广告系列最近修改时间的 Unix 时间戳（秒级），对应源表 `mtime`。 |

---

### 维度：广告策略配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `product_selection` | int | 商品选择方式枚举值。`1` = `PRODUCT_SELECTION_AUTO`（自动选品）；`2` = `PRODUCT_SELECTION_MANUAL`（手动选品）。 |
| `product_placement` | int | 广告投放位置枚举值。`1` = `PRODUCT_PLACEMENT_SEARCH`（搜索页）；`2` = `PRODUCT_PLACEMENT_TARGET`（定向推荐页）；`3` = `PRODUCT_PLACEMENT_ALL`（全部位置，即 SEARCH XOR TARGET 的联合值）。⚠️ 值 `3` 为位运算组合值（`1 XOR 2`），过滤"含搜索位置"时请使用 `product_placement IN (1, 3)` 而非 `= 1`。 |
| `bidding_strategy` | int | 广告系列竞价策略枚举值，枚举含义包括自动竞价、手动竞价和基于 ROI 的竞价方式。具体枚举映射请参考业务代码表。⚠️ 枚举值定义可能随产品迭代扩展，使用时建议与业务方确认最新映射关系。 |
| `ecpc` | boolean | 是否启用增强型每次点击费用（eCPC）出价策略。`true` 表示已开启 eCPC。从源表 `_decoded_extinfo` JSON 解析而来。 |
| `creative` | boolean | 是否为创意广告（Creative Ads）。`true` 表示该广告系列为创意广告类型。从源表 `_decoded_extinfo` JSON 解析而来。 |

---

### 维度：搜索与定向结构体配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `search` | struct<keyword_ads_id:bigint> | 搜索广告配置结构体，包含关联的关键词广告 ID（`keyword_ads_id`）。从源表 `_decoded_extinfo` JSON 解析而来。使用时通过点操作符访问子字段，如 `search.keyword_ads_id`。⚠️ 字段可能为 NULL（非搜索类广告系列不含此配置）。 |
| `target` | struct<daily_discover:struct<price:bigint,status:int>, you_may_also_like:struct<price:bigint,status:int>> | 定向广告配置结构体，包含两种定向方式的出价与状态：`daily_discover`（每日发现）和 `you_may_also_like`（猜你喜欢）。子字段 `price` 为出价金额（单位需与业务确认，通常为分），`status` 为该定向的开启状态。从源表 `_decoded_extinfo` JSON 解析而来。⚠️ 字段可能为 NULL（非定向类广告系列不含此配置）；`price` 字段为 bigint，直接 SUM 无业务意义，应结合 `status` 过滤后按需使用。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**指定以下三个分区字段，否则将触发全分区扫描，导致查询性能严重下降及跨地区数据混入：

| 分区字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 当前表仅写入 `'local'` 分区，此条件为必选；若遗漏将仍扫描全部 tz_type 分区（兼容性冗余）。 |
| `grass_region` | `grass_region = 'MY'`（按需替换） | 指定目标地区，避免跨地区数据聚合错误。 |
| `grass_date` | `grass_date = '2026-04-21'`（按需替换） | 指定快照日期；本表为每日全量快照，同一 `campaign_id` 在不同日期均有记录，**不指定日期将导致数据重复计数**。 |

**示例：**
```sql
SELECT campaign_id, shop_id, bidding_strategy
FROM mp_paidads.dim_product_campaign__reg_s0_live
WHERE tz_type = 'local'
  AND grass_region = 'MY'
  AND grass_date = '2026-04-21';
```

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确使用方式 |
|------|------|------|
| `product_placement` | 枚举值 `3` 为位运算组合（`SEARCH=1 XOR TARGET=2`），直接聚合无语义 | 使用 `COUNT` + `WHERE product_placement IN (...)` 分类统计；判断"含搜索"用 `product_placement IN (1, 3)` |
| `target.daily_discover.price` / `target.you_may_also_like.price` | 为单个广告系列的出价配置值，SUM 无实际业务意义 | 应结合 `status` 过滤有效出价后，按业务需求取均值或分布分析 |
| `campaign_create_datetime` / `campaign_modify_datetime` | 字符串类型，直接用于时间范围比较会退化为字典序 | 时间范围过滤请使用对应 timestamp 字段（`campaign_create_timestamp`、`campaign_modify_timestamp`）或显式 `CAST(... AS TIMESTAMP)` |

### 时效性说明

本表为**每日全量快照**，每次 INSERT OVERWRITE 覆写当日分区，包含截至 `grass_date` 次日零点（本地时间）之前创建的所有广告系列。

- 获取**最新广告系列属性**：取最新可用 `grass_date` 分区（通常为 T-1 日）；
- 分析**历史存量**：指定对应历史 `grass_date` 即可，各日分区独立存储，可做时间序列对比；
- **注意**：`campaign_modify_datetime` 记录系列最近修改时间，但本表是快照表，某一日分区的数据不包含该日之后的修改——如需追踪变更，应对比不同日期分区。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_${region}_db__product_campaign_tab__reg_continuous_s0_live` | 各地区商品广告系列原始业务表（分地区部署），提供广告系列的全量属性数据，包括 `campaignid`、`shopid`、`userid`、`ctime`、`mtime`、`product_selection`、`product_placement`、`bidding_strategy` 及 JSON 格式的扩展信息 `_decoded_extinfo` |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.shopee_ads_${region}_db__product_campaign_tab__reg_continuous_s0_live
    │
    │  过滤：ctime < 次日00:00:00（本地时区转换为 SGT）
    │  字段映射：campaignid→campaign_id, shopid→shop_id, userid→user_id
    │  时间转换：ctime/mtime (SGT Unix ts) → 本地时区 datetime 字符串
    │  JSON 解析：_decoded_extinfo → decoded_extinfo struct
    │            └─ .creative, .ecpc, .search, .target
    ▼
[Temp View] product_campaign_tab_df
    │
    │  INSERT OVERWRITE PARTITION (tz_type='local', grass_region, grass_date)
    │  grass_region = upper('${region}')
    │  grass_date   = DATE('${grass_date}')
    ▼
mp_paidads.dim_product_campaign__reg_s0_live
    │
    └─ ALTER TABLE ADD PARTITION（补充元数据注册）
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `product_campaign_tab_df` | `shopee_ads_${region}_db__product_campaign_tab__reg_continuous_s0_live` | 对原始业务表进行字段重命名、时间戳转本地时区 datetime 字符串、JSON 字段解析（`_decoded_extinfo` → struct），并过滤出截至目标日期已创建的全量广告系列记录 |

### 注意事项

1. **时区转换链路**：源表时间戳 `ctime`/`mtime` 的原始时区为 `Asia/Singapore`（SGT，UTC+8）；ETL 先将其解释为 SGT，再转换为目标地区本地时区（`${timezone}` 参数），最终格式化为 `yyyy-MM-dd HH:mm:ss` 字符串写入 `campaign_create_datetime` / `campaign_modify_datetime`。各地区按本地时区参数化调度，时区处理逻辑一致。

2. **数据截止逻辑**：过滤条件为 `ctime < UNIX_TIMESTAMP(次日00:00:00_本地时间_转回SGT)`，即快照包含"截至 `grass_date` 本地时区结束前已创建"的全部广告系列，是存量维度快照而非增量。

3. **JSON 解析字段**：`creative`、`ecpc`、`search`、`target` 均从 `_decoded_extinfo` JSON 字段解析而来（`from_json` + struct schema 推断）。源数据中该 JSON 字段若缺失对应 key，解析结果为 NULL，查询时需注意 NULL 处理。

4. **`product_placement` 枚举的位运算特性**：值 `3`（`PRODUCT_PLACEMENT_ALL`）由 `1` 和 `2` 通过 XOR 组合得到，代表同时覆盖搜索和定向位置。筛选"含搜索位置投放"时应使用 `product_placement IN (1, 3)`，而非等值比较。

5. **调度参数化**：SQL 中出现的 `${region}`、`${timezone}`、`${grass_date}`、`${HIVE_PATH}` 均为调度系统注入的运行时参数，本表通过参数化模板覆盖所有上线地区，各地区独立分区存储。

---

*文档生成时间：2026-04-22*