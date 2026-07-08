<!-- ads-workspace-gdoc-sync: gdoc_id=1sEIN-2z-oxTPtzaIsOiZ8ybUQoNthuMjFUYD5VbntM4 gdoc_url=https://docs.google.com/document/d/1sEIN-2z-oxTPtzaIsOiZ8ybUQoNthuMjFUYD5VbntM4/edit -->

# mp_paidads.dwd_display_ads_tracking_di

**分层**：DWD（数据明细层）
**主键**：`request_id` + `session_id` + `event_timestamp`（事件级别唯一标识）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（Daily Incremental，覆盖当日分区）
**引用频次**：0（末端 ADS 层表，暂无下游候选表引用）

---

## 业务描述

本表是展示广告（Display Ads）用户交互行为的明细宽表，记录每一条来自买家端的广告曝光、点击等 Tracking 事件的原始信息，涵盖用户身份、设备信息、广告位、广告素材、Banner 详情及用户操作类型等核心维度。数据来源于 ODS 层的小时级 Tracking 日志，经过字段清洗、结构体解析及时区对齐后写入本层，是展示广告行为分析的标准明细数据源。

本表的核心价值在于将 ODS 层的半结构化 JSON 字段（`banner.json_data`）解析为可直接查询的结构化字段，并通过 `ads_id` / `banner_id` 的分流逻辑区分「付费展示广告（Ads，`source=2`）」与「普通首页 Banner」两类曝光，便于下游按业务类型分别聚合分析。

典型使用场景包括：广告曝光/点击漏斗分析、广告主 ROI 归因、Banner 效果对比、用户设备与地区分布统计，以及 AB 实验效果评估（通过 `ab_sign` 字段）。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区分区标识。当前写入值固定为 `'local'`，表示按各地区本地时区对齐日期。⚠️ 查询时必须指定 `tz_type = 'local'`，否则将触发全分区扫描，严重影响查询性能。 |
| `grass_region` | string | 卖家与用户所在国家/地区代码（大写，如 `'MX'`、`'BR'`）。各地区通过 `${region}` 参数化调度覆盖所有市场。⚠️ 查询时必须指定具体地区，避免全表扫描。 |
| `grass_date` | date | Tracking 事件所属的本地日期（按本地时区截断）。⚠️ 查询时必须指定具体日期范围，避免全分区扫描。 |

---

### 维度：主键与用户身份

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 与展示广告发生交互的买家用户 ID。 |
| `device_id` | string | 用户设备 ID，用于设备级别去重与行为关联。 |
| `client_ip` | string | 买家端 IP 地址，可用于地理位置辅助判断或风控场景。 |
| `session_id` | string | 用户与展示广告交互的会话 ID，标识一次完整的用户交互会话周期。 |
| `token` | string | 与 `session_id` 配合使用的校验令牌，用于验证会话有效性。 |
| `request_id` | string | 本次 Tracking 请求的唯一标识，从 `banner.json_data.request_id` 解析而来，可用于与广告请求侧数据进行关联。 |

---

### 维度：广告属性与素材

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 付费展示广告 ID。仅当 `banner.source = 2` 时有值，否则为 NULL。`ads_id` 非 NULL 表示该事件属于付费展示广告；NULL 表示普通首页 Banner。⚠️ 不可与 `banner_id` 混用，两者互斥。 |
| `banner_id` | bigint | 普通首页滚动 Banner 的 ID。仅当 `banner.source ≠ 2` 时有值，否则为 NULL。⚠️ 与 `ads_id` 互斥，统计时需注意区分。 |
| `source` | bigint | Banner 来源枚举值，用于区分流量来源（如 `2` = 付费 Ads，其他值 = DL/普通 Banner 等）。 |
| `shop_id` | bigint | 广告关联的店铺 ID，从 `banner.json_data.shop_id` 解析而来。 |
| `slot_id` | bigint | 首页 Banner 广告的广告位 ID，标识展示位置。 |
| `placement` | bigint | 广告展示位置编号（原始字段，来自 ODS 日志）。 |
| `ads_placement` | int | 广告展示位置（从 `banner.json_data` 的 `placement` 字段解析而来）。⚠️ 与 `placement` 字段含义相近但来源不同，使用前需确认业务口径选择哪个字段。 |
| `ads_entrance` | int | 广告入口位置，表示买家点击或曝光发生的入口（从 `banner.json_data` 的 `entrance` 字段解析而来）。 |
| `ab_sign` | string | AB 实验分组标识，从 `banner.json_data.ab_sign` 解析而来，用于 AB Test 实验效果分层分析。 |

---

### 维度：事件属性与平台

| 字段 | 类型 | 说明 |
|------|------|------|
| `operation` | bigint | 用户操作类型枚举值，标识本次 Tracking 事件的行为类型（如曝光、点击等）。 |
| `platform` | string | 触发事件的客户端平台类型（TrackingPlatformType），如 iOS、Android、Web 等。 |
| `from` | string | Tracking 数据来源标识，由 Tracking Server 填写，区分来源为 coreserver 还是 client。 |
| `event_datetime` | string | Tracking 事件的本地时间，格式为 `YYYY-MM-DD HH:MM:SS`，由 `event_timestamp` 通过 `from_unixtime` 按本地时区转换而来。⚠️ 存储为字符串类型，时间范围过滤建议优先使用 `grass_date` 分区字段；如需精确时间过滤，需注意字符串比较行为。 |
| `event_timestamp` | bigint | Tracking 事件的 Unix 时间戳（秒级），为事件发生的原始时间戳。⚠️ ETL 中已通过 `event_timestamp` 进行日期对齐过滤（`>= grass_date` 且 `< grass_date + 1`），确保写入记录与分区日期一致。 |

---

### 维度：原始结构体与 JSON 扩展

| 字段 | 类型 | 说明 |
|------|------|------|
| `banner` | struct<banner_id:bigint, campaign_unit_id:bigint, image_hash:string, slot_id:bigint, source:bigint, target_url:string, json_data:struct<request_id:string, ab_sign:string, generated_time:bigint, l1_cat_id:bigint, shop_id:bigint, track_id:string>> | Banner 详情结构体，包含 banner_id、campaign_unit_id、图片 hash、slot_id、来源、目标 URL 及嵌套的 json_data（含 request_id、ab_sign、L1 类目 ID、shop_id、track_id 等）。⚠️ 为嵌套结构体，访问子字段需使用点语法（如 `banner.json_data.shop_id`）；大部分常用子字段已在其他列中解析，优先使用解析后的字段。 |
| `json_data` | string | 从 `beeshop_search.ResponseSearchItem` 或 `beeshop_search.ResponseSearchUser` 接收的原始 JSON 字符串，保存额外的扩展信息。⚠️ 为原始 JSON 字符串，查询时需配合 `get_json_object` 函数解析特定字段，不可直接用于聚合。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，导致资源浪费和超时风险：

| 分区字段 | 推荐过滤写法 | 说明 |
|----------|-------------|------|
| `tz_type` | `tz_type = 'local'` | 当前仅写入 `local` 分区；缺少此条件将扫描所有 tz_type 分区 |
| `grass_region` | `grass_region = 'MX'`（按需替换） | 必须指定目标市场，缺少此条件将扫描所有地区数据 |
| `grass_date` | `grass_date = '2026-04-21'` 或范围过滤 | 必须指定日期，缺少此条件将全量扫描历史分区 |

**最小安全查询模板**：
```sql
SELECT ...
FROM mp_paidads.dwd_display_ads_tracking_di
WHERE tz_type = 'local'
  AND grass_region = '${region}'
  AND grass_date = '${grass_date}'
```

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确使用方式 |
|------|---------|-------------|
| `ads_placement` | 为枚举/位置编号，直接 SUM 无业务意义 | 用于 `GROUP BY` 或 `COUNT` 聚合，不可 SUM |
| `placement` | 同上，为广告位枚举值 | 用于 `GROUP BY` 或 `COUNT` 聚合，不可 SUM |
| `ads_entrance` | 为枚举/位置编号，直接 SUM 无业务意义 | 用于 `GROUP BY` 或 `COUNT` 聚合，不可 SUM |
| `operation` | 为操作类型枚举值 | 用于 `GROUP BY` 或条件过滤，不可 SUM |
| `source` | 为来源枚举值 | 用于 `GROUP BY` 或条件过滤，不可 SUM |
| `json_data` | 原始 JSON 字符串 | 需用 `get_json_object(json_data, '$.key')` 提取后使用 |
| `banner` | 嵌套结构体 | 需用点语法访问子字段（如 `banner.json_data.shop_id`），优先使用已解析的平铺字段 |
| `event_datetime` | 字符串类型，不支持数值聚合 | 仅用于展示或字符串比较；时间范围过滤优先用 `grass_date` 分区字段或 `event_timestamp` |

### 时效性说明

- 本表为**每日全量覆写当日分区**（INSERT OVERWRITE），每日调度完成后分区数据即为当日最终值。
- ETL 已通过 `event_timestamp` 范围过滤（`>= grass_date` 且 `< grass_date + 1`）确保分区内数据与 `grass_date` 对齐，但由于依赖 ODS 小时级日志（`where grass_date='${grass_date}' or grass_date='${today_date}'`），存在**跨日日志补录**场景，建议使用 **T+1 分区**（即昨日分区）进行正式统计，以确保数据完整性。
- 各地区按本地时区独立调度，`grass_date` 含义为各地区本地日期，跨地区对比时注意时区差异。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_display_ads_tracking_hi__reg_s0_live` | 展示广告 Tracking 原始小时级日志，提供所有事件字段的原始值，包括半结构化的 `banner` 结构体和 `json_data` 字符串 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ods_log_display_ads_tracking_hi__reg_s0_live
  │  过滤条件：grass_date = '${grass_date}' OR grass_date = '${today_date}'
  │            AND country = upper('${region}')
  │
  ▼
[CTE: display_ads_tracking]
  │  - 读取原始字段
  │  - 保留 banner（半结构化）、json_data（JSON 字符串）
  │
  ▼
[内层子查询：字段清洗与结构体重建]
  │  - userid → user_id
  │  - deviceid → device_id
  │  - sessionid → session_id
  │  - timestamp → event_timestamp
  │  - from_unixtime(timestamp) → event_datetime
  │  - 解析 banner 各子字段，重建 STRUCT 类型 banner
  │  - 保留原始 banner 为 origin_banner（用于提取 ads_placement / ads_entrance）
  │
  ▼
[外层子查询：日期范围过滤]
  │  - event_timestamp 对齐到 grass_date（过滤跨日数据）
  │
  ▼
[主 SELECT：业务字段派生]
  │  - ads_id：banner.source = 2 时取 banner.banner_id，否则为 NULL
  │  - banner_id：banner.source ≠ 2 时取 banner.banner_id，否则为 NULL
  │  - ads_placement：get_json_object(origin_banner.json_data, '$.placement')
  │  - ads_entrance：get_json_object(origin_banner.json_data, '$.entrance')
  │
  ▼
INSERT OVERWRITE
mp_paidads.dwd_display_ads_tracking_di__reg_s0_live
  PARTITION (tz_type='local', grass_region='${upper_region}', grass_date='${grass_date}')
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `display_ads_tracking` | `mp_paidads.ods_log_display_ads_tracking_hi__reg_s0_live` | 按地区和日期过滤原始 Tracking 日志，读取当日及次日凌晨补录数据（`grass_date = today OR grass_date = today+1`），作为后续清洗的基础数据集 |

### 注意事项

1. **`ads_id` 与 `banner_id` 互斥逻辑**：ETL 通过 `banner.source = 2` 判断是否为付费展示广告。`source = 2` 时 `ads_id` 有值、`banner_id` 为 NULL；反之 `banner_id` 有值、`ads_id` 为 NULL。统计展示广告效果时需过滤 `ads_id IS NOT NULL` 或 `source = 2`。

2. **`banner` 结构体重建**：ETL 对 ODS 层原始 `banner` 结构体进行了字段重命名（`bannerid → banner_id`、`slotid → slot_id`、`campaign_unitid → campaign_unit_id`）并将 `json_data` 从 JSON 字符串解析为嵌套 STRUCT，与 ODS 层结构不完全一致，关联上游数据时需注意字段名映射。

3. **`ads_placement` 与 `placement` 的区别**：`placement` 来自 ODS 原始日志的顶层字段；`ads_placement` 从 `origin_banner.json_data` 中的 `$.placement` 解析而来，代表广告侧记录的位置信息。两者语义来源不同，使用时需根据业务需求明确选择。

4. **跨日日志兼容**：ODS 层读取时同时包含 `grass_date = today` 和 `grass_date = today_date`（即允许前一日补录数据），但写入本表时通过 `event_timestamp` 进行严格的日期过滤，只保留属于 `grass_date` 当日的事件，确保分区数据准确。

5. **参数化多地区调度**：ETL SQL 中出现的 `'America/Mexico_City'`、`upper('mx')` 等为调度模板的参数化示例，实际生产中通过 `${region}`、`${timezone}`、`${upper_region}` 等变量覆盖所有市场，各地区按本地时区独立调度。

---

*文档生成时间：2026-04-22*