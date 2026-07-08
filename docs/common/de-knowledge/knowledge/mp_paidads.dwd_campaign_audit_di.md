<!-- ads-workspace-gdoc-sync: gdoc_id=1t26E29qoRQIjp2FHV3gr4wC_7VFD07CyREqY0Gbvva4 gdoc_url=https://docs.google.com/document/d/1t26E29qoRQIjp2FHV3gr4wC_7VFD07CyREqY0Gbvva4/edit -->

# mp_paidads.dwd_campaign_audit_di

**分层**：DWD（数据明细层）
**主键**：`id`（审计记录主键）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（Daily Insert Overwrite）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表记录广告活动（Campaign）的全量审计日志明细，整合了广告系统中两类 Campaign 对象（普通 Campaign 与 Product Campaign）的变更快照，以及对应的审计事件元信息（操作人、操作时间、操作平台等）。每条记录代表一次 Campaign 配置变更事件，包含变更前后的原始数据快照（`old_data` / `new_data`）及解码后的扩展信息。

本表是广告运营审计、合规追溯、投放策略还原的核心数据源，适用于以下场景：追踪 Campaign 状态变更历史、分析 ROI 目标调整行为（含智能预算增加逻辑触发的自动调整）、统计操作员变更行为频次、以及复盘特定时段内广告策略调整记录。

作为 DWD 层明细表，本表保留了较高的原始粒度，不做跨事件聚合，下游 ADS 层可按业务口径灵活汇总；各地区按本地时区参数化调度，数据天级覆盖全地区市场。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型标识，当前写入值固定为 `'local'`，表示按各地区本地时区划分自然日；查询时**必须过滤** `tz_type = 'local'` 以避免全表扫描 |
| `grass_region` | string | 地区代码（大写），如 `ID`、`MY`、`TH` 等；由调度参数 `${region}` 参数化驱动，覆盖所有上线地区 |
| `grass_date` | date | 数据日期（按本地时区划分的自然日），格式 `yyyy-MM-dd` |

---

### 维度：主键与事件标识

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `id` | bigint | 审计记录主键，来源于原始 audit 表的 `id` 字段 |
| `event_id` | bigint | 审计事件 ID，用于关联 `campaign_audit` 与 `ad_audit_event` 两张源表；JOIN Key |
| `audit_event` | bigint | 审计事件类型码，来源于 `ad_audit_event` 表；可参考官方枚举文档获取业务含义 |

---

### 维度：广告实体

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `campaign_id` | bigint | Campaign ID，广告活动唯一标识 |
| `user_id` | bigint | 广告主 User ID |
| `shop_id` | bigint | 广告主 Shop ID |
| `campaign_status` | bigint | 变更后（new_data）的 Campaign 状态码；枚举值见[官方文档](https://sites.google.com/shopee.com/paid-ads-data/general-data-useful-tips/field-corresponding-enum-value) |

---

### 维度：操作信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `operator` | string | 操作人名称（人工操作时为账号名，系统自动操作时可能为系统标识） |
| `operator_id` | bigint | 操作人 ID |
| `platform` | int | 操作来源平台枚举值：`0=PLATFORM_UNKNOWN`、`1=PLATFORM_PC`、`2=PLATFORM_APP`、`3=PLATFORM_SRM`、`12=PLATFORM_ADS_STATUS_SYNCER`；完整枚举见[官方文档](https://sites.google.com/shopee.com/paid-ads-data/general-data-useful-tips/field-corresponding-enum-value#h.306lfzryzbke) |
| `event_timestamp` | bigint | 事件发生时间，Unix 时间戳（秒），原始字段 `ctime`；时区基准为新加坡时间（SGT） |
| `event_datetime` | string | 事件发生时间，已转换为各地区本地时区的可读字符串，由 `from_utc_timestamp(to_utc_timestamp(..., 'Asia/Singapore'), '${timezone}')` 计算得出 ⚠️ 为派生字段，仅供展示，时区依赖调度参数，跨地区比较时请统一换算至 UTC |

---

### 维度：变更快照

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `old_data` | string | 变更前 Campaign 数据的 JSON 原文快照 ⚠️ 为 JSON 字符串，需用 `get_json_object` 解析具体字段，不可直接聚合 |
| `new_data` | string | 变更后 Campaign 数据的 JSON 原文快照 ⚠️ 为 JSON 字符串，需用 `get_json_object` 解析具体字段，不可直接聚合 |
| `old_data_extinfo` | string | 变更前 extinfo 字段经 Protobuf 解码后的 JSON 字符串；对于普通 Campaign 使用 `campaign_protobuf` UDF 解析，Product Campaign 使用 `product_campaign_protobuf` UDF 解析 ⚠️ 为 JSON 字符串，需按需解析子字段 |
| `new_data_extinfo` | string | 变更后 extinfo 字段经 Protobuf 解码后的 JSON 字符串，解析方式同 `old_data_extinfo` ⚠️ 为 JSON 字符串，需按需解析子字段 |
| `ad_audit_event_extinfo` | string | 审计事件扩展信息，来源于 `ad_audit_event_tab` 表的 `extinfo` 字段（UTF-8 解码后的原文），包含自动预算增加等系统行为的详细参数 ⚠️ 为 JSON 字符串，需用 `get_json_object` 解析子字段，如 `$.auto_budget_increase.*` |

---

### 指标：ROI 目标设置

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `target_broad_roi` | double | Ultimate Setup Flow 专用的广泛 ROI 目标值；原始值已除以 100000.0 换算为实际倍率 ⚠️ 仅适用于 Ultimate Setup Flow，非此流程的记录该值为 NULL；为原始整型除以 100000 的比率值，不可直接 SUM |
| `roi_two_target_value_old` | double | 变更前的双 ROI 目标值（`$.roiTwo.targetValue`），来源于 `old_data_extinfo`；原始值已除以 100000.0 换算 ⚠️ 为比率类指标，不可直接 SUM，如需聚合请回溯原始整型值重新计算 |
| `roi_two_target_value_new` | double | 变更后的双 ROI 目标值（`$.roiTwo.targetValue`），来源于 `new_data_extinfo`；原始值已除以 100000.0 换算 ⚠️ 为比率类指标，不可直接 SUM，如需聚合请回溯原始整型值重新计算 |
| `current_target_roi` | double | 触发自动预算增加时的当前 ROI 目标值（`$.auto_budget_increase.current_target_roi`），来源于 `ad_audit_event_extinfo`；原始值已除以 100000.0 换算 ⚠️ 仅在系统自动触发预算增加的事件中有值；为比率类指标，不可直接 SUM |
| `last1_day_target_roi` | double | 自动预算增加逻辑中，过去 1 天的 ROI 参考值（`$.auto_budget_increase.float_last1_day_target_roi`）；原始值已除以 100000 换算 ⚠️ 仅在系统自动触发预算增加的事件中有值；为比率类指标，不可直接 SUM |
| `last7_day_target_roi` | double | 自动预算增加逻辑中，过去 7 天的 ROI 参考值（`$.auto_budget_increase.float_last7_day_target_roi`）；原始值已除以 100000 换算 ⚠️ 仅在系统自动触发预算增加的事件中有值；为比率类指标，不可直接 SUM |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，造成计算资源浪费及查询超时：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 当前仅写入 `local` 分区，但不过滤会扫描全部 tz_type 分区（含未来可能扩展的分区） |
| `grass_region` | `grass_region = 'ID'`（按需指定） | 扫描所有地区数据，数据量成倍放大 |
| `grass_date` | `grass_date = '2026-04-21'` 或范围过滤 | 扫描全量历史数据，严重影响性能 |

**推荐最小过滤模板**：
```sql
WHERE tz_type = 'local'
  AND grass_region = '${region}'
  AND grass_date = '${grass_date}'
```

### 不可直接 SUM 的字段

以下字段均为**经过单位换算的比率类指标**（原始整型 ÷ 100000），直接 SUM 无业务意义，如需跨记录聚合，须结合分子/分母业务逻辑重新设计计算方式：

| 字段 | 错误用法 | 正确处理建议 |
|------|----------|--------------|
| `target_broad_roi` | `SUM(target_broad_roi)` | 按 Campaign 取最新值，或计算加权平均时以预算为权重 |
| `roi_two_target_value_old` | `SUM(roi_two_target_value_old)` | 取单条记录值用于前后对比，不做跨记录求和 |
| `roi_two_target_value_new` | `SUM(roi_two_target_value_new)` | 同上 |
| `current_target_roi` | `SUM(current_target_roi)` | 取单事件值，如需趋势分析按 `campaign_id + grass_date` 聚合取 AVG |
| `last1_day_target_roi` | `SUM(last1_day_target_roi)` | 仅作为系统决策参考值使用，不做跨记录求和 |
| `last7_day_target_roi` | `SUM(last7_day_target_roi)` | 同上 |

此外，以下字段为 **JSON 字符串**，不可直接聚合，使用前需先用 `get_json_object` 提取所需子字段：
`old_data`、`new_data`、`old_data_extinfo`、`new_data_extinfo`、`ad_audit_event_extinfo`

### 时效性说明

- 本表为每日覆盖写入（Insert Overwrite），`grass_date` 分区对应各地区本地时区的自然日数据。
- 若分析当日（T+0）数据，可能因调度尚未完成而出现数据缺失；建议优先查询 **T-1** 分区，即 `grass_date = CURRENT_DATE - 1`，以确保数据完整性。
- `event_datetime` 已按本地时区转换，跨地区对比时注意时区差异，建议统一换算至 UTC（参考 `event_timestamp` 字段）。
- `last1_day_target_roi` / `last7_day_target_roi` 为事件触发时系统回溯的历史 ROI 快照，不代表查询当日的实时 ROI。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_${region}_db__campaign_audit_tab__reg_continuous_s0_live` | 普通 Campaign 审计变更记录，提供 `old_data` / `new_data` 快照及 extinfo（Protobuf 编码） |
| `mp_paidads.shopee_ads_${region}_db__product_campaign_audit_tab__reg_continuous_s0_live` | Product Campaign 审计变更记录，字段结构与 campaign_audit_tab 类似，使用独立 Protobuf UDF 解码 |
| `mp_paidads.shopee_ads_${region}_db__ad_audit_event_tab__reg_continuous_s0_live` | 审计事件主表，提供操作人、操作平台、事件类型、事件时间及扩展信息（含自动预算增加 ROI 参数） |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.shopee_ads_${region}_db__campaign_audit_tab__reg_continuous_s0_live
    │  (按本地时区过滤 grass_date 对应的 ctime 范围)
    │  campaign_protobuf UDF 解码 extinfo
    ▼
┌─────────────────────┐
│  CTE: campaign_audit │ ◄── UNION ALL
└─────────────────────┘
    ▲
mp_paidads.shopee_ads_${region}_db__product_campaign_audit_tab__reg_continuous_s0_live
    (product_campaign_protobuf UDF 解码 extinfo)

mp_paidads.shopee_ads_${region}_db__ad_audit_event_tab__reg_continuous_s0_live
    │  (按本地时区过滤 grass_date 对应的 ctime 范围)
    │  decode extinfo (UTF-8), 提取 auto_budget_increase 子字段
    ▼
┌──────────────────────┐
│  CTE: ad_audit_event │
└──────────────────────┘

CTE: campaign_audit  LEFT JOIN  CTE: ad_audit_event
        ON a.event_id = b.event_id
                │
                │  ROI 字段 ÷ 100000 换算
                │  INSERT OVERWRITE PARTITION(tz_type='local', grass_region, grass_date)
                ▼
   dwd_campaign_audit_di__reg_s0_live
   （Parquet，分区：tz_type / grass_region / grass_date）
                │
                │  ALTER TABLE ADD PARTITION
                ▼
   dwd_campaign_audit_di__${region}_s0_live
   （指向同一 HIVE_PATH 下的地区子目录，分区：grass_date）
```

> **计算引擎**：Hive SQL，使用自定义 UDF `CampaignAuditDecodeProtoBuf` 和 `ProductCampaignAuditDecodeProtoBuf` 进行 Protobuf 反序列化。

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `campaign_audit` | `campaign_audit_tab` + `product_campaign_audit_tab` | UNION ALL 合并两类 Campaign 的审计快照，提取 campaign_id、shop_id、user_id、变更状态及 ROI 扩展字段；使用各自 Protobuf UDF 解码 extinfo |
| `ad_audit_event` | `ad_audit_event_tab` | 提取事件元信息（操作人、平台、时间、audit_event 类型）及 auto_budget_increase 相关 ROI 参数；event_datetime 已转换为本地时区 |

### 注意事项

1. **LEFT JOIN 导致的 NULL 值**：主表为 `campaign_audit`，`ad_audit_event` 以 `event_id` LEFT JOIN，若 `ad_audit_event_tab` 中不存在对应 `event_id`，则 `audit_event`、`operator`、`platform`、`event_timestamp`、`event_datetime` 及所有 ROI 指标字段均为 NULL。查询时需注意 NULL 处理，避免错误过滤。

2. **ROI 字段单位换算**：所有 ROI 相关字段（`target_broad_roi`、`roi_two_target_value_old`、`roi_two_target_value_new`、`current_target_roi`、`last1_day_target_roi`、`last7_day_target_roi`）在 ETL 中均已由整型除以 100000（或 100000.0）换算为实际倍率，存储值即为最终业务值，**不需要在查询层再次换算**。

3. **双表结构设计**：ETL 同时维护两张表：`dwd_campaign_audit_di__reg_s0_live`（三级分区：tz_type / grass_region / grass_date，全地区统一存储）和 `dwd_campaign_audit_di__${region}_s0_live`（一级分区：grass_date，按地区独立视图）。后者通过 `ALTER TABLE ADD PARTITION` 指向前者的子目录，本质上是同一份 Parquet 数据的不同元数据视图，**避免在同一作业中同时查询两张表造成重复计数**。

4. **ctime 时区转换逻辑**：源表 `ctime` 基准为新加坡时间（SGT，UTC+8），ETL 通过 `TO_UTC_TIMESTAMP(DATE'${grass_date}', '${timezone}')` 将本地自然日边界转换为 SGT Unix 时间戳进行过滤，确保 `grass_date` 对应各地区本地时区的完整自然日，而非 SGT 自然日。

5. **Product Campaign 的 `campaign_status`**：Product Campaign 分支在 SQL 中 `new_data_status` 取 `null`，因此来源于 Product Campaign 的记录其 `campaign_status` 字段为 NULL，使用时需注意区分数据来源。

6. **`target_broad_roi` 适用范围**：该字段仅在 Ultimate Setup Flow 配置的 Campaign 中有值，其他 Campaign 类型为 NULL，聚合分析前务必过滤。

---

*文档生成时间：2026-04-22*