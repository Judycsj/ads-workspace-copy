<!-- ads-workspace-gdoc-sync: gdoc_id=1rKiuiY20b8zAEOrwrmxDW_FKFA0O04CrJpu6ZZsxPsQ gdoc_url=https://docs.google.com/document/d/1rKiuiY20b8zAEOrwrmxDW_FKFA0O04CrJpu6ZZsxPsQ/edit -->

# mp_paidads.dwd_advertiser_audit_di

**分层**：DWD（明细数据层）
**主键**：`id`（审计记录唯一标识）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（覆盖写入，`INSERT OVERWRITE`）
**引用频次**：0（末端 ADS 层表，当前无下游候选表直接引用）

---

## 业务描述

本表记录广告主账户（Advertiser Account）的全量审计日志明细，来源于底层 Shopee Ads 数据库的 `ads_account_audit_tab`。每一行对应账户发生的一次状态变更事件，涵盖账户状态变更、自动充值设置（Auto Top-up）、每日推送通知设置（Daily PN）、广告活动日设置（Campaign Day）、自动预算递增设置（Auto Budget Increase）等关键配置的历史快照，同时保留变更前后的原始 JSON 数据（`old_data` / `new_data`）用于审计追溯。

本表的核心价值在于支撑广告账户运营分析与合规审计场景。分析师可通过本表还原任意账户在任意时间点的配置状态，识别异常操作（如操作员邮件、IP 地址变更频率异常），以及监控自动充值、预算递增等自动化功能的开启率与参数变化趋势。各地区按本地时区参数化调度，`tz_type = 'local'` 分区对应各地区本地时间口径。

对于需要 USD 标准化比较的场景，本表通过关联汇率维表（`dim_exchange_rate`）将本地货币金额字段自动换算为 USD，便于跨地区对比分析。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区键，当前写入值固定为 `'local'`，表示按各地区本地时区统计 |
| `grass_region` | string | 地区编码分区键，如 `ID`、`MY`、`TH` 等，由调度参数 `${region}` 大写转换而来 |
| `grass_date` | date | 业务日期分区键，对应审计事件所在的本地日期（`event_timestamp` 落在 `[grass_date, grass_date+1)` 范围内） |

---

### 维度：主键与账户标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | bigint | 审计记录唯一 ID，对应源表 `ads_account_audit_tab` 的主键 |
| `user_id` | bigint | 广告主用户 ID（对应源表 `userid`） |
| `account_id` | bigint | 广告账户 ID（对应源表 `accountid`） |
| `operator_email` | string | 执行本次变更操作的操作员邮箱地址 |
| `client_ip` | bigint | 操作客户端 IP（以整型存储）⚠️ 为整型编码的 IP 地址，如需展示请转换为点分十进制格式 |
| `platform` | bigint | 操作平台标识（枚举值，含义参见平台枚举定义） |

---

### 维度：事件时间信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `event_timestamp` | bigint | 审计事件发生的 Unix 时间戳（秒），对应源表 `timestamp` 字段 |
| `event_datetime` | string | 审计事件发生时间的格式化字符串（`yyyy-MM-dd HH:mm:ss`），按所在地区本地时区转换 |
| `create_timestamp` | bigint | 账户记录创建时间戳（Unix 秒），从 `new_data.ctime` 解析 |
| `create_datetime` | string | 账户记录创建时间格式化字符串（`yyyy-MM-dd HH:mm:ss`） |
| `modify_timestamp` | bigint | 账户记录最近修改时间戳（Unix 秒），从 `new_data.mtime` 解析 |
| `modify_datetime` | string | 账户记录最近修改时间格式化字符串（`yyyy-MM-dd HH:mm:ss`） |

---

### 维度：审计事件类型与状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `audit_event` | int | 审计事件类型枚举值，含义参见 `AdsAccountAuditEvent` 枚举定义 |
| `status` | bigint | 账户状态，从 `new_data.status` 解析（枚举值） |

---

### 维度：原始数据快照

| 字段 | 类型 | 说明 |
|------|------|------|
| `old_data` | string | 变更前的账户数据（JSON 格式字符串） |
| `new_data` | string | 变更后的账户数据（JSON 格式字符串） |
| `old_data_extinfo` | string | 变更前账户扩展信息（由 Protobuf 解码后的 JSON 字符串，从 `old_data.extinfo` 解析）⚠️ 为 Protobuf 解码结果，内容结构依赖 proto 版本，直接字符串匹配可能不稳定，建议使用 `get_json_object` 提取子字段 |
| `new_data_extinfo` | string | 变更后账户扩展信息（由 Protobuf 解码后的 JSON 字符串，从 `new_data.extinfo` 解析）⚠️ 同上，为 Protobuf 解码结果 |
| `ads_account_audit_extinfo` | string | 源表 `ads_account_audit_tab` 的额外扩展信息字段（`_decoded_extinfo`） |

---

### 维度：每日推送通知（Daily PN）设置

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_pn_setting_is_off` | tinyint | 每日推送通知是否关闭：1=已关闭，0=已开启，NULL=设置不存在。从 `new_data_extinfo.dailyPnSetting.isOff` 解析 |
| `daily_pn_last_sending_hour` | bigint | 每日推送通知最近发送时间戳（Unix 秒），从 `new_data_extinfo.dailyPnSetting.timestamp` 解析 |

---

### 维度：自动充值（Auto Top-up）设置

| 字段 | 类型 | 说明 |
|------|------|------|
| `auto_topup_setting_is_on` | tinyint | 自动充值是否开启：1=开启，0=关闭，NULL=设置不存在。从 `new_data_extinfo.autoTopupSetting.on` 解析 |
| `campaign_day_setting_is_on` | tinyint | 活动日设置是否开启：1=开启，0=关闭，NULL=设置不存在。从 `new_data_extinfo.campaignDaySetting.on` 解析 |

---

### 维度：自动预算递增（Auto Budget Increase）设置

| 字段 | 类型 | 说明 |
|------|------|------|
| `auto_budget_increase_setting` | string | 自动预算递增设置的原始 JSON 字符串（从 `new_data_extinfo.autoBudgetIncreaseSetting` 解析） |
| `auto_budget_increase_setting_is_on` | tinyint | 自动预算递增是否开启：1=开启，0=关闭，NULL=设置不存在 |
| `auto_budget_increase_setting_is_daily_reset` | tinyint | 自动预算递增是否每日重置：1=是，0=否，NULL=设置不存在 |
| `auto_budget_increase_effective_types` | array\<int\> | 自动预算递增生效类型列表，含义参见 `AutoBudgetIncreaseEffectiveType` 枚举⚠️ 为数组类型，聚合统计时需先 `EXPLODE` 展开，不可直接聚合 |
| `auto_budget_increase_latest_is_daily_reset_timestamp` | bigint | 最新"每日重置"设置生效时间戳（Unix 秒）；若当天日期与此时间戳匹配，则使用 `is_daily_reset_setting_on_timestamp` 的值，否则使用 `is_daily_reset` 的值 |
| `auto_budget_increase_is_daily_reset_setting_on_timestamp` | tinyint | 在 `latest_is_daily_reset_timestamp` 时刻生效的"每日重置"逻辑值（1=true，0=false）；用于处理 12:00am 边界时的设置竞争问题⚠️ 需与 `auto_budget_increase_latest_is_daily_reset_timestamp` 配合使用，不可单独解读 |

---

### 指标：每日推送通知余额金额

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_pn_balance_amt` | double | 每日推送通知余额（本地货币，单位：元）。源数据除以 100000 换算⚠️ 从 protobuf 扩展字段解析，原始值以 1/100000 为单位，已在 ETL 中换算；多行 SUM 无业务意义（为某次事件的账户余额快照，非流量型指标） |
| `daily_pn_balance_amt_usd` | double | 每日推送通知余额（USD）。由 `daily_pn_balance_amt / exchange_rate` 计算⚠️ 为派生字段，不可重复 SUM；汇率来自 `grass_date` 当日汇率，历史追溯时汇率已固化 |

---

### 指标：自动充值金额

| 字段 | 类型 | 说明 |
|------|------|------|
| `auto_topup_threshold_amt` | double | 自动充值触发余额阈值（本地货币，单位：元）。源数据除以 100000 换算⚠️ 为事件快照值，多行 SUM 无业务意义 |
| `auto_topup_threshold_amt_usd` | double | 自动充值触发余额阈值（USD）⚠️ 为派生字段（`threshold_amt / exchange_rate`），不可直接 SUM |
| `auto_topup_amt` | double | 每次自动充值金额（本地货币，单位：元）。源数据除以 100000 换算⚠️ 为事件快照值，多行 SUM 无业务意义 |
| `auto_topup_amt_usd` | double | 每次自动充值金额（USD）⚠️ 为派生字段（`amt / exchange_rate`），不可直接 SUM |
| `auto_topup_daily_cap_amt` | double | 自动充值每日上限金额（本地货币，单位：元）。源数据除以 100000 换算⚠️ 为事件快照值，多行 SUM 无业务意义 |
| `auto_topup_daily_cap_amt_usd` | double | 自动充值每日上限金额（USD）⚠️ 为派生字段（`daily_cap_amt / exchange_rate`），不可直接 SUM |

---

### 指标：自动预算递增参数

| 字段 | 类型 | 说明 |
|------|------|------|
| `auto_budget_increase_daily_cap` | int | 自动预算递增每日最大触发次数上限（含活动日子项），对应 `autoBudgetIncreaseSetting.dailyCap` |
| `auto_budget_increase_campaign_days_daily_cap` | int | 活动日的自动预算递增每日触发次数上限（可选字段）；若为 NULL，则使用 `auto_budget_increase_daily_cap` 作为活动日上限⚠️ 为可选参数，NULL 表示与通用 daily_cap 共用，业务判断时需注意回退逻辑 |
| `auto_budget_increase_percentage` | double | 自动预算递增幅度（比率，范围约 0.01~3.00）。源数据（整数，1~300000）除以 100000 换算⚠️ 为预计算比率，不可直接 SUM；若需汇总平均幅度，需按事件数加权平均 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**显式指定以下分区条件，否则将触发全表扫描，产生大量计算资源浪费：

```sql
-- 推荐过滤写法
WHERE tz_type = 'local'          -- 当前仅写入 'local' 分区，缺少此条件将无效扫描未来可能新增的分区
  AND grass_region = 'ID'        -- 替换为目标地区编码（大写）
  AND grass_date = '2025-01-01'  -- 替换为目标业务日期
```

| 条件 | 推荐值 | 遗漏后果 |
|------|--------|---------|
| `tz_type` | `'local'` | 全分区扫描，当前等价但未来扩展时会拉取错误数据 |
| `grass_region` | 目标地区大写编码 | 跨地区混合计算，数据量膨胀且结果错误 |
| `grass_date` | 具体日期或日期范围 | 扫描全量历史分区，极大增加计算耗时与资源消耗 |

---

### 不可直接 SUM 的字段

以下字段为**快照型或派生型**，直接 `SUM` 无业务意义或结果错误：

| 字段 | 原因 | 正确使用方式 |
|------|------|------------|
| `daily_pn_balance_amt` | 账户余额快照，非流量型指标 | 取最新一条记录的值（`LAST_VALUE` 或按 `event_timestamp` 取最新） |
| `daily_pn_balance_amt_usd` | 同上，且为除汇率派生字段 | 同上；如需 USD 汇总，用本地货币除以当日汇率重算 |
| `auto_topup_threshold_amt` / `_usd` | 触发阈值配置快照 | 统计开启率或分析阈值分布时使用，不做跨行 SUM |
| `auto_topup_amt` / `_usd` | 配置的充值金额快照，非实际充值流水 | 分析充值配置分布；实际充值流水需查专用流水表 |
| `auto_topup_daily_cap_amt` / `_usd` | 配置上限快照 | 同上 |
| `auto_budget_increase_percentage` | 预计算比率（`increasePct / 100000`） | 统计平均幅度时按事件数加权：`SUM(pct * n) / SUM(n)` |
| `auto_budget_increase_effective_types` | `ARRAY<INT>` 类型 | 先 `LATERAL VIEW EXPLODE` 展开后再聚合 |

---

### 时效性说明

本表为**日增量覆盖写入**，每个 `grass_date` 分区包含该自然日内（本地时区 00:00:00 ~ 23:59:59）发生的所有审计事件。

- 查询**最新账户配置状态**时，应取最近已产出分区（通常为 T-1），并在该分区内按 `account_id` 取 `event_timestamp` 最大的一条记录。
- `auto_budget_increase_latest_is_daily_reset_timestamp` 与 `auto_budget_increase_is_daily_reset_setting_on_timestamp` 两个字段存在**跨日时效性依赖**（用于处理 00:00am 边界竞争），使用时需结合事件发生时间与该时间戳所在日是否一致来判断生效逻辑，不可脱离时间上下文直接使用。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_${region}_${db_type}__ads_account_audit_tab__reg_continuous_s0_live` | 核心数据源，提供广告账户审计日志原始数据（按 `event_timestamp` 过滤当日数据） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对 USD 的汇率，用于将本地货币金额字段换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.shopee_ads_${region}_${db_type}
    __ads_account_audit_tab__reg_continuous_s0_live
        │
        │  过滤: event_timestamp ∈ [grass_date, grass_date+1)
        │  解析: new_data / old_data (JSON)
        │  解码: new_data.extinfo / old_data.extinfo (Protobuf → JSON)
        │  展开: dailyPnSetting / autoTopupSetting /
        │        campaignDaySetting / autoBudgetIncreaseSetting
        │  换算: 金额字段 / 100000 → 本地货币（元）
        ▼
    [CTE: ads_account_audit]
        │
        │  字段计算：CASE WHEN 解析各配置开关 / 金额
        ├──────────────────────────────────────────┐
        │                                          │
        │                              mp_order.dim_exchange_rate
        │                                  __reg_s0_live
        │                              (grass_region + grass_date 过滤)
        │                                          │
        └──────── LEFT JOIN on grass_region ───────┘
        │
        │  派生: _amt_usd = _amt / exchange_rate
        │  写入: INSERT OVERWRITE PARTITION
        │        (tz_type='local', grass_region, grass_date)
        ▼
mp_paidads.dwd_advertiser_audit_di__reg_s0_live
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `ads_account_audit`（临时视图） | `shopee_ads_${region}_${db_type}__ads_account_audit_tab__reg_continuous_s0_live` | 三层嵌套子查询：①过滤当日数据、列类型转换；②从 `new_data` JSON 解析账户核心字段，调用 `json_from_protobuf` UDF 解码 extinfo；③从解码后 extinfo 提取各子配置 JSON 字符串，并 `from_json` 解析 `autoBudgetIncreaseSetting` 为结构体 |

---

### 注意事项

1. **金额单位换算**：源表所有金额字段以整数形式存储（最小单位为本地货币的 1/100000），ETL 中统一除以 `100000.0` 换算为"元"级别，已换算后的字段直接存入本表。查询时无需再次换算。

2. **Protobuf UDF 依赖**：`new_data_extinfo` 和 `old_data_extinfo` 依赖 `json_from_protobuf` UDF（`com.shopee.deepdata.warehouse.hive.udf.DecodeProtobuf`）解码，解码结果以 JSON 字符串形式存储。proto schema 版本升级时，字段含义可能变化，使用时建议核对当前 proto 定义。

3. **LEFT JOIN 汇率缺失场景**：若 `dim_exchange_rate` 中某地区某日无汇率数据，`exchange_rate` 为 NULL，导致所有 `_usd` 字段为 NULL。查询 USD 汇总时需注意过滤或做 NULL 处理。

4. **事件重复写入风险**：本表使用 `INSERT OVERWRITE` 按日分区覆盖写入，同一 `grass_date` 分区每日重刷一次。若上游 continuous 流表在调度窗口内存在补数，可能导致当日分区被覆盖为更完整的数据，历史分区数据以最后一次写入为准。

5. **多分区组合唯一性**：`id` 在同一 `(grass_region, grass_date)` 分区内唯一，但理论上同一 `id` 不会跨日出现（事件时间决定分区），可将 `(id, grass_region, grass_date)` 作为业务主键使用。

6. **参数化调度**：ETL SQL 中 `${region}`、`${timezone}`、`${grass_date}`、`${db_type}` 均为调度参数，各地区独立调度，各地区按本地时区参数化执行，表内数据覆盖所有已接入地区。

---

*文档生成时间：2026-04-22*