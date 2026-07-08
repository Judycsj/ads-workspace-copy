<!-- ads-workspace-gdoc-sync: gdoc_id=1pexXjH6UXMtxud4wOHfQiNrcuVBb9IzTe8iLLIMmsQw gdoc_url=https://docs.google.com/document/d/1pexXjH6UXMtxud4wOHfQiNrcuVBb9IzTe8iLLIMmsQw/edit -->

# mp_paidads.dwd_advertise_audit_di

**分层**：DWD（明细数据层）
**主键**：`id`（audit event_id）、`ads_id`、`grass_region`、`grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1），各地区按本地时区参数化调度
**引用频次**：18 次（候选表范围内）

---

## 业务描述

本表记录广告投放系统中每一条广告（Ad）的审计事件明细，数据来源于广告审计日志、关键词审计日志及广告事件日志的多表整合，涵盖广告的创建、暂停、恢复、系统停止、预算调整、关键词变更、竞价出价变动等全生命周期操作行为。每行记录对应一次广告相关的审计事件，包含触发该事件的用户、操作平台、事件类型、广告出价及关键词信息。

本表是广告运营分析与合规审计的核心基础表，可用于追溯广告策略变更历史（如出价调整路径、状态变更原因）、监控广告主操作行为分布（如各平台操作频次、操作人员来源）以及支撑关键词竞价分析（如关键词出价水位、匹配类型分布）。

作为 DWD 层明细表，本表保留了原始 JSON 格式的 `old_data`、`new_data` 及 extinfo 字段，供下游数仓层做进一步解析与聚合，同时提供了预计算的本地货币及 USD 双币种出价字段，方便跨地区横向对比分析。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区，固定写入值为 `'local'`，各地区按本地时区参数化调度 |
| `grass_region` | string | 地区分区，如 `'MY'`、`'TH'` 等，通过 `${region}` 参数化覆盖所有地区 |
| `grass_date` | date | 日期分区，格式 `yyyy-MM-dd`，按事件发生的本地时区日期归档 |

---

### 维度：主键与广告基本属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | bigint | 审计事件 ID（event_id），来源于 `s_advertise_audit_tab`，作为本表核心主键 |
| `ads_id` | bigint | 广告 ID，来源于 `s_advertise_audit_tab` |
| `item_id` | bigint | 广告关联的商品 ID |
| `shop_id` | bigint | 广告所属店铺 ID，来源于 `s_account_tab` |
| `user_id` | bigint | 触发本次审计事件的用户 ID |
| `placement` | bigint | 广告位类型，来源于 `s_advertise_audit_tab` audit 字段 |
| `status` | bigint | 事件发生后广告的最新状态值（取自 new_data 中的 status 字段） |
| `pricing_type` | int | 广告计价类型，从 `new_data_extinfo` 中的 `pricingType` 字段解析 ⚠️ 来源为 JSON 反序列化字段，历史数据中可能存在空值 |

---

### 维度：操作事件与平台

| 字段 | 类型 | 说明 |
|------|------|------|
| `audit_event` | bigint | 审计事件类型枚举值，来源于 `s_advertise_audit_tab` |
| `audit_event_text` | string | 审计事件类型文本描述，由 `audit_event` 枚举值映射：1=PAUSE、2=RESUME、3=START、4=CREATE、5=STOP、6=RESTART、7=CHANGE_SCHEDULE、8=CHANGE_BUDGET、9=SYSTEM_PAUSE、10=SYSTEM_END、11=SHOP_CUSTOMISATION_ADDED、12=SHOP_CUSTOMISATION_CHANGED、13=SHOP_CUSTOMISATION_REMOVED、14=CREATE_BANNER_ADS、15=MODIFY_BANNER_ADS、16=OFF_ALL_ADS、17=TOGGLE_SIMPLE_MODE，其余映射为 UNKNOWN |
| `platform` | int | 操作平台枚举值：0=Unknown、1=PC、2=APP、3=SRM |
| `platform_name` | string | 操作平台文本描述，由 `platform` 枚举值映射生成 |
| `operator` | string | 操作人标识，来源于审计事件日志 |
| `operator_id` | bigint | 操作人 ID，来源于审计事件日志 |
| `is_changed` | tinyint | 是否发生出价变更：当 `create_timestamp = event_timestamp` 时为 0（未变更），否则为 1（已变更）⚠️ 仅判断广告创建时间与事件时间是否相同，不反映所有字段变更情况，语义较为受限 |

---

### 维度：时间信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `create_timestamp` | bigint | 广告创建时的 Unix 时间戳（秒），从 `new_data` 或 `old_data` 的 `ctime` 字段解析 |
| `create_datetime` | string | 广告创建时间的本地时间字符串，格式 `yyyy-MM-dd HH:mm:ss` |
| `event_timestamp` | bigint | 审计事件发生时的 Unix 时间戳（秒），来源于 `s_advertise_audit_tab` |
| `event_datetime` | string | 审计事件发生的本地时间字符串，格式 `yyyy-MM-dd HH:mm:ss` |
| `keyword_audit_timestamp` | bigint | 关键词审计事件的 Unix 时间戳（秒），无关键词事件时为 NULL |
| `keyword_audit_datetime` | string | 关键词审计事件的本地时间字符串，格式 `yyyy-MM-dd HH:mm:ss`，无关键词事件时为 NULL |

---

### 维度：关键词属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `keyword` | string | 广告主为该广告选择的关键词文本，从关键词审计日志 `new_data.term` 字段解析 |
| `keyword_md5` | tinyint | 关键词的 MD5 加密值（经 `cast(md5(keyword) as tinyint)` 处理）⚠️ 存储类型为 tinyint，MD5 结果截断精度损失严重，不可用于精确去重或关键词唯一性校验 |
| `keyword_status` | tinyint | 关键词活跃状态，从 `new_data.kw_status` 字段解析 |
| `match_type` | tinyint | 关键词匹配类型，从关键词审计日志 `new_data.match_type` 字段解析 |
| `keyword_update_flags` | bigint | 关键词更新标志位，来源于关键词审计日志的 `update_flags` 字段，用于标识本次更新涉及的属性范围 ⚠️ 为 bitmap 标志位字段，不可直接作为数值进行 SUM/AVG 聚合，需按位解析 |

---

### 指标：广告出价

| 字段 | 类型 | 说明 |
|------|------|------|
| `target_bid_price_local` | double | 定向广告竞价出价（本地货币），由 `new_data_extinfo.target.price / 100000` 计算得出 ⚠️ 为预计算派生字段，跨行聚合需回溯分子字段；不同地区货币单位不同，跨地区 SUM 无意义 |
| `target_bid_price_usd` | double | 定向广告竞价出价（USD），由 `target_bid_price_local / exchange_rate` 计算得出 ⚠️ 依赖当日汇率表，汇率缺失时为 NULL；不可直接 SUM 后再除汇率，需以 `target_bid_price_local` 重新计算 |
| `keyword_bid_price_local` | double | 关键词竞价出价（本地货币），由关键词审计日志 `new_data.price / 100000` 计算得出 ⚠️ 无关键词事件的审计记录该字段为 NULL；跨地区 SUM 无意义 |
| `keyword_bid_price_usd` | double | 关键词竞价出价（USD），由 `keyword_bid_price_local / exchange_rate` 计算得出 ⚠️ 依赖当日汇率表，汇率缺失时为 NULL；计算逻辑同 `target_bid_price_usd` |

---

### 维度：原始 JSON 数据

| 字段 | 类型 | 说明 |
|------|------|------|
| `old_data` | string | 变更前的广告数据，JSON 字符串格式，来源于审计日志原始字段 ⚠️ 为原始 JSON 字符串，查询时需使用 `get_json_object` 解析，直接作为字符串使用无业务意义 |
| `new_data` | string | 变更后的广告数据，JSON 字符串格式，来源于审计日志原始字段 ⚠️ 为原始 JSON 字符串，查询时需使用 `get_json_object` 解析 |
| `old_data_extinfo` | string | 变更前广告扩展信息，经 `json_from_protobuf` UDF 解码后的 JSON 字符串（对应 `old_data.extinfo`）⚠️ 为 Protobuf 反序列化后的 JSON，结构依赖 protobuf schema 版本，历史数据可能存在结构差异 |
| `new_data_extinfo` | string | 变更后广告扩展信息，经 `json_from_protobuf` UDF 解码后的 JSON 字符串（对应 `new_data.extinfo`）⚠️ 同 `old_data_extinfo`，为 Protobuf 解码结果，使用前需确认字段 schema |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下分区过滤条件，否则将触发全表扫描，导致计算资源浪费、查询超时：

| 过滤字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 本表仅写入 `local` 分区，省略此条件将产生无效扫描 |
| `grass_region` | `grass_region = 'MY'`（按需替换） | 地区分区，务必指定目标地区 |
| `grass_date` | `grass_date = '2024-01-01'` 或范围过滤 | 日期分区，务必指定范围，避免全量历史扫描 |

> ⚠️ 遗漏任一分区条件将导致 Spark 扫描全部分区数据，在数据量较大时会造成严重的性能问题，并可能因资源占用过高导致任务失败。

---

### 不可直接 SUM 的字段

| 字段 | 问题描述 | 正确计算方式 |
|------|----------|--------------|
| `target_bid_price_usd` | 预计算汇率换算字段，直接 SUM 会引入多行平均汇率误差 | 使用 `SUM(target_bid_price_local) / MAX(exchange_rate)` 或关联汇率表重新换算 |
| `keyword_bid_price_usd` | 同上，预计算汇率换算字段 | 使用 `SUM(keyword_bid_price_local) / MAX(exchange_rate)` 重新计算 |
| `target_bid_price_local` / `keyword_bid_price_local` | 跨地区 SUM 无业务意义（不同地区货币不同） | 必须在单一 `grass_region` 范围内聚合，或统一换算为 USD 后跨地区汇总 |
| `keyword_update_flags` | Bitmap 标志位字段，数值本身不具备加和语义 | 按需进行位运算（如 `keyword_update_flags & 1`）判断具体更新类型 |
| `keyword_md5` | MD5 截断为 tinyint，数值无统计意义 | 仅用于模糊关键词分组，不可用于精确去重或数值运算 |
| `is_changed` | 判断逻辑仅比较 create_timestamp 与 event_timestamp，不代表全字段变更 | 作为标志位使用（`= 0` / `= 1`），不可直接 SUM 作为变更量指标 |

---

### 时效性说明

本表为每日 T+1 调度，分区按 `grass_date` 存储事件发生日期的数据。`old_data` / `new_data` 及 extinfo 字段中的 JSON 内容反映事件发生时刻的广告状态快照，**不代表当前最新广告状态**。若需获取广告最新状态，请勿直接使用本表，应查询对应的广告主数据快照表。各地区数据按本地时区完成当日调度后方可查询，建议使用 `grass_date = current_date - 1` 获取最新完整数据。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_${region}_db__advertisement_audit_tab__reg_continuous_s0_live` | 广告审计主表，提供广告 ID、商品 ID、店铺 ID、状态、出价、extinfo 等核心审计字段 |
| `mp_paidads.shopee_ads_${region}_db__ad_audit_event_tab__reg_continuous_s0_live` | 广告事件日志表，提供审计事件类型（audit_event）、操作人、操作平台、事件时间戳等信息 |
| `mp_paidads.shopee_ads_${region}_db__ad_keyword_audit_tab__reg_continuous_s0_live` | 关键词审计日志表，提供关键词文本、关键词出价、匹配类型、关键词状态等信息 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 每日汇率维表，提供各地区本地货币兑 USD 汇率，用于计算 USD 出价字段 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.shopee_ads_${region}_db__advertisement_audit_tab__reg_continuous_s0_live
    │  过滤: ctime 在当日时间范围内
    │  解析: new_data/old_data JSON + Protobuf extinfo 解码
    ▼
[CTE: advertisement_audit]
    │
    ├──────────────────────────────────────────────────────────────┐
    │                                                              │
mp_paidads.shopee_ads_${region}_db__ad_audit_event_tab__reg_continuous_s0_live
    │  过滤: ctime 在当日时间范围内                                │
    ▼                                                              │
[CTE: ad_audit_event_di]                                          │
    │  LEFT JOIN on grass_region & event_id                        │
    │                                                              │
mp_paidads.shopee_ads_${region}_db__ad_keyword_audit_tab__reg_continuous_s0_live
    │  过滤: ctime 在当日时间范围内                                │
    │  解析: new_data JSON → keyword/price/status/match_type        │
    ▼                                                              │
[CTE: ad_kw_audit_di]                                             │
    │  LEFT JOIN on grass_region & event_id & ads_id               │
    │                                                              ▼
mp_order.dim_exchange_rate__reg_s0_live ──────────────────────────┤
    │  过滤: grass_region & grass_date                              │
    │  BROADCAST JOIN on grass_region                              │
    ▼                                                              │
    └──────────────────────────────── 最终 INSERT OVERWRITE ───────┘
                                              │
                                              ▼
              dwd_advertise_audit_di__reg_s0_live
              partition(tz_type='local', grass_region, grass_date)
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `advertisement_audit` | `advertisement_audit_tab__reg_continuous_s0_live` | 广告审计主数据：解析 new_data/old_data JSON 提取商品、店铺、状态、出价等字段；使用 `json_from_protobuf` UDF 解码 extinfo（Protobuf 格式）为可读 JSON；过滤当日 ctime 范围 |
| `ad_audit_event_di` | `ad_audit_event_tab__reg_continuous_s0_live` | 审计事件数据：提供 audit_event 类型、操作人、操作平台、extinfo 中的广告状态数组；过滤当日 ctime 范围 |
| `ad_kw_audit_di` | `ad_keyword_audit_tab__reg_continuous_s0_live` | 关键词审计数据：解析 new_data JSON 提取关键词文本、竞价价格（除以 100000 还原真实值）、关键词状态、匹配类型；过滤当日 ctime 范围 |

---

### 注意事项

1. **三表 LEFT JOIN 设计**：`advertisement_audit` 为主驱动表，`ad_audit_event_di` 与 `ad_kw_audit_di` 均为 LEFT JOIN。这意味着：当某条广告审计记录在事件日志或关键词日志中无对应条目时，相关字段（如 `audit_event`、`keyword`、`operator` 等）将为 NULL，查询时需注意 NULL 过滤。

2. **价格字段单位换算**：原始出价字段存储时以 1/100000 货币单位存储（即存储值 = 实际金额 × 100000），ETL 中已除以 100000.00 还原真实出价金额。下游使用时无需再次换算，但注意原始 `old_data`/`new_data` JSON 中的 `price` 字段仍为未换算的原始值。

3. **Protobuf UDF 依赖**：`json_from_protobuf` 为自定义 UDF（`com.shopee.deepdata.warehouse.hive.udf.AuditDecodeProtoBuf`），`old_data_extinfo` 和 `new_data_extinfo` 字段的内容依赖该 UDF 的 schema 版本。若 protobuf 结构变更，历史数据与新数据的 JSON 键名可能不一致，使用前需验证字段结构。

4. **汇率 BROADCAST JOIN**：ETL 中对汇率表使用了 `BROADCAST` hint，说明汇率表数据量较小。汇率为当日汇率（`grass_date` 分区），若汇率表当日数据缺失，所有 USD 出价字段将为 NULL。

5. **`keyword_md5` 精度问题**：ETL 中对 `md5(keyword)` 的结果进行了 `cast as bigint`，但 DDL 字段类型为 `tinyint`，存在二次截断，实际存储精度极低，该字段不可用于关键词唯一性判断或精确去重。

6. **`is_changed` 语义说明**：该字段通过比较广告的 `create_timestamp`（广告本身的 ctime，从 new_data/old_data 解析）与 `event_timestamp`（事件发生时间）是否相同来判断，并非通过对比 old_data 与 new_data 内容得出，语义为"事件是否发生在广告创建之后"，而非"广告出价是否发生变化"，使用时需注意区分。

7. **时区与分区对齐**：ETL 通过 `SET TIME ZONE '${timezone}'` 设置会话时区，`from_unixtime` 函数输出的时间字符串均基于各地区本地时区，与 `grass_date` 分区保持一致。跨地区联合查询时需注意各地区时区不同导致的时间对比问题。

---

*文档生成时间：2026-04-22*