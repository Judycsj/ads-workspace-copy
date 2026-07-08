<!-- ads-workspace-gdoc-sync: gdoc_id=1AiyJ3wS_sHaumxlyUY8bvMB4LDubOoRhsdvxqzolxVU gdoc_url=https://docs.google.com/document/d/1AiyJ3wS_sHaumxlyUY8bvMB4LDubOoRhsdvxqzolxVU/edit -->

# mp_paidads.dwd_log_translog_unsuccessful_event_deduction_di

**分层**：DWD（明细数据层）
**主键**：`unique_id`
**分区**：`grass_region`，`grass_date`
**更新频率**：每日调度（T+1，覆盖前一业务日数据）
**引用频次**：0（末端 ADS 层输出表，未被其他候选表直接引用）

---

## 业务描述

本表记录付费广告系统中**扣费失败（unsuccessful）的事件明细**，来源于 ODS 层小时级扣费流水日志，经过清洗、字段补全与自定义 UDF 解析后落地为天级 DWD 明细表。每一行代表一次广告扣费尝试中最终未能完全成功的事件，涵盖账户余额不足、Campaign 日预算耗尽、Campaign 总预算耗尽、广告状态异常、信用额度临期等多种失败类型，通过 `status` 字段枚举区分。

本表是**广告预算管控分析、扣费失败归因、账户健康度监控**的核心明细来源。典型使用场景包括：统计各地区/广告主每日扣费失败率、定位因预算撞线导致的曝光损失、分析 Placement 级别预算分配策略的有效性、以及排查账户或广告位状态异常引起的投放中断。

表中保留了账户快照（`account`）、Campaign 当日累计扣费快照（`campaign_balance`、`campaign_balance_by_date`）、Credit 信息数组（`ads_credits`）以及通过 UDF 解析的 Placement 级别扣费明细（`campaign_balance_by_date_extinfo`），为深度归因分析提供完整上下文。各地区按本地时区参数化调度，`grass_region` 与 `grass_date` 共同标识数据归属的地区与业务日期。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 业务地区标识（如 `ID`、`TH`、`MY` 等），通过 `${region}` 参数化调度，覆盖所有运营地区 |
| `grass_date` | date | 业务日期（本地时区），分区键，每次调度写入前一业务日数据 |

---

### 维度：主键与广告核心属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `unique_id` | bigint | 本次扣费事件的唯一 ID，表主键 |
| `ads_id` | bigint | 广告 ID |
| `campaign_id` | bigint | Campaign ID |
| `account_id` | bigint | 广告账户 ID |
| `seller_user_id` | bigint | 卖家用户 ID，与 `account_id` 值相同 |
| `user_id` | bigint | 用户 ID（从上游 ODS 透传，口径与 `seller_user_id` 可能存在差异，以 `seller_user_id` 为主） |
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `order_id` | bigint | 关联订单 ID |
| `ls_session_id` | bigint | 直播间 ID（直播广告场景有值，其他场景为空） |
| `country` | string | 国家/地区代码（从上游原始日志透传，与 `grass_region` 含义类似但格式可能不同） |

---

### 维度：投放配置属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `deduct_type` | int | 扣费类型：1 = CPC，2 = CPM |
| `pricing_type` | int | 定价类型（从上游透传，具体枚举值见广告系统定义） |
| `entrance` | int | 流量入口类型 |
| `sub_entrance` | int | 流量子入口类型（与 `entrance` 配合使用） |
| `placement` | int | 广告位标识（如 805、802 等，对应不同版位） |
| `platform` | int | 投放平台标识 |
| `recall_source` | int | 召回来源标识 |
| `operation` | int | 操作类型；注释说明基本全为空，无实际业务意义，可忽略 ⚠️ 字段实际无效，查询中无需依赖此字段做过滤或聚合 |
| `is_seller` | boolean | 是否为卖家广告 |
| `deduct_date` | string | 扣费日期字符串（日志原始时间中提取，格式为 `YYYY-MM-DD`；与 `grass_date` 一般一致，但跨午夜边界时可能有偏差） ⚠️ 请优先使用分区字段 `grass_date` 作为日期过滤，避免依赖此字段导致结果偏差 |
| `event_time` | bigint | 事件发生时间戳（Unix 毫秒或秒级，需结合业务确认精度） |
| `version` | int | 记录版本号 |

---

### 维度：扣费失败状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `status` | int | 扣费结果状态码：0=未知，1=部分成功(StatusOK)，2=失败(StatusFail)，3=账户余额耗尽(StatusAccountNoMoney)，4=账户余额低(StatusAccountLowBalance)，5=Campaign 日预算耗尽(StatusCampaignDailyNoMoney)，6=Campaign 总预算耗尽(StatusCampaignTotalNoMoney)，7=账户状态异常(StatusAccountNoNormal)，8=Campaign 状态异常(StatusCampaignNoNormal)，9=广告状态异常(StatusAdsNoNormal)，10=信用额度临期(StatusAdsCreditExpiring)，11=重复(StatusDuplicated)，12=无效(StatusInvalid)，13=预重复(StatusPreDuplicated)，14=Campaign Placement 日预算耗尽(StatusCampaignPlacementDailyNoMoney) |

---

### 维度：预算配置快照

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_quota` | bigint | Campaign 日预算上限（金额单位为平台最小货币单位，通常为分） |
| `total_quota` | bigint | Campaign 总预算上限；Item Boost 类广告支持设置总预算，其他广告类型通常仅设置日预算 |
| `quota_split` | struct\<placement:int, daily_available_quota:bigint, version:int, placements:array\<int\>\> | 预算分配后的 Placement 级别可用预算信息；仅对启用了预算分配策略（Quota Split）的 Campaign 有值 ⚠️ 为 struct 嵌套类型，查询时需使用 `quota_split.daily_available_quota` 等子字段访问，不可直接聚合 |

---

### 维度：账户与 Campaign 状态快照

| 字段 | 类型 | 说明 |
|------|------|------|
| `account` | struct\<accountid:bigint, userid:bigint, balance:bigint, ctime:bigint, mtime:bigint, status:int, overdue_limit:bigint, extinfo:binary, display_ads_balance:bigint\> | 账户快照：`balance` 为扣费后当前账户余额（已含本次扣费）；`overdue_limit` 为余额降至 0 后允许的超支上限，0 表示不允许超支；`display_ads_balance` 为展示广告余额 ⚠️ 为事件发生时刻的账户快照，`balance` 已包含本次扣费，不可直接与其他行累加用于余额统计 |
| `campaign_balance` | struct\<campaignid:bigint, daily_balance:bigint, mtime:bigint, history_balance:bigint, userid:bigint\> | Campaign 预算消耗快照：`daily_balance` 为当日累计扣费（含本次）；`history_balance` 为 Campaign 历史累计扣费 ⚠️ 均为截至事件时刻的累计值快照，同一 campaign_id 下多行不可直接 SUM |
| `campaign_balance_by_date` | struct\<campaignid:bigint, userid:bigint, daily_balance:bigint, mtime:bigint, ctime:bigint, extinfo:binary\> | Campaign 按日期维度的预算消耗快照：`daily_balance` 为当日累计扣费（含本次）；`extinfo` 为 JSON binary，含 Placement 级别累计扣费及初始预算，已通过 UDF 解析至 `campaign_balance_by_date_extinfo` ⚠️ 累计快照字段，不可直接 SUM；`extinfo` 为 binary 编码，应使用解析后的 `campaign_balance_by_date_extinfo` 字段 |
| `campaign_balance_by_date_extinfo` | struct\<placement_expenses:array\<struct\<placement:int, expense:bigint\>\>, initial_balance:bigint\> | 由 UDF `campaign_daily_balance_ext_info` 解析 `campaign_balance_by_date.extinfo` 得到：`placement_expenses` 为各 Placement 的当日累计扣费列表（仅对启用 Quota Split 的 Campaign 有值）；`initial_balance` 为初始预算 ⚠️ `placement_expenses` 为数组，查询时需 LATERAL VIEW EXPLODE 展开；各 expense 值为累计快照，不可跨行 SUM |
| `ads_credits` | array\<struct\<order_id:bigint, order_type:int, user_id:bigint, shop_id:int, amount:bigint, balance:bigint, main_type:int, subtype:bigint, start_time:bigint, end_time:bigint, ctime:bigint, mtime:bigint, extinfo:binary\>\> | 广告 Credit 信息数组，记录本次事件涉及的所有 credit 订单快照，含 credit 金额、余额、有效期等 ⚠️ 为数组类型，查询时需 LATERAL VIEW EXPLODE 展开；`balance` 为快照值，不可直接 SUM |

---

### 指标：扣费金额

| 字段 | 类型 | 说明 |
|------|------|------|
| `price` | bigint | 本次事件尝试扣费的总金额（= Credit 扣费 + 现金扣费，单位为平台最小货币单位） |
| `adjusted_cost` | bigint | 调整后实际扣费总额（在 `price` 基础上经业务规则调整后的最终扣费金额） |
| `credit_cost` | bigint | 调整后实际 Credit 扣费金额 |
| `balance_cost` | bigint | 调整后实际现金余额扣费金额 |
| `valid_balance` | bigint | 有效余额（扣费时账户可用于扣费的余额，具体口径以业务系统定义为准） |
| `available_balance` | bigint | 可用余额（含 overdue 额度的可用余额，与 `valid_balance` 口径不同） ⚠️ `valid_balance` 与 `available_balance` 含义相近但口径不同，使用前需确认业务定义，避免混用 |

---

### 维度：原始扩展数据

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_json_data` | string | 商品维度扩展信息（JSON 字符串格式，具体字段结构由上游日志定义） ⚠️ 为 JSON 字符串，查询特定字段需使用 `get_json_object` 或 `json_tuple` 解析 |
| `shop_json_data` | string | 店铺维度扩展信息（JSON 字符串格式） ⚠️ 同上，需 JSON 解析后使用 |
| `tracking_json_data` | string | 追踪维度扩展信息（JSON 字符串格式，含点击/展示 tracking 上下文） ⚠️ 同上，需 JSON 解析后使用 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定** `grass_region` 和 `grass_date` 分区过滤条件，否则将触发全表扫描，导致资源浪费和查询超时：

```sql
WHERE grass_region = 'ID'          -- 必须指定目标地区
  AND grass_date = '2026-04-21'    -- 必须指定业务日期（或使用日期范围）
```

- 遗漏 `grass_region` 将扫描所有地区分区，数据量成倍放大；
- 遗漏 `grass_date` 将扫描全量历史数据，极易导致 OOM 或任务超时；
- 如需多地区或日期范围分析，建议使用 `grass_region IN (...)` 或 `grass_date BETWEEN ... AND ...` 明确约束范围。

---

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确使用方式 |
|------|------|-------------|
| `account.balance` | 为每次事件时刻的账户余额快照（已含本次扣费），同一账户多次事件余额会重复计入 | 取同一账户最新一条记录的余额（按 `event_time` 取最大值对应的快照）|
| `campaign_balance.daily_balance` | 为截至事件时刻的当日累计扣费快照，多行 SUM 会重复累加 | 按 campaign_id 取 `event_time` 最大的一行的 `daily_balance` |
| `campaign_balance.history_balance` | 同上，为历史累计快照 | 同上，取最新快照值 |
| `campaign_balance_by_date.daily_balance` | 同上，为按日期维度的当日累计快照 | 按 campaign_id + deduct_date 取最新快照 |
| `campaign_balance_by_date_extinfo.placement_expenses[*].expense` | 为 Placement 级别当日累计扣费快照，且为数组元素 | 展开数组后按 placement 取最新快照值 |
| `quota_split`、`ads_credits` | 复杂嵌套类型（struct/array），不支持直接聚合 | 需先 LATERAL VIEW EXPLODE 展开数组或使用子字段访问 |
| `valid_balance`、`available_balance` | 为事件时刻快照余额，直接 SUM 无业务含义 | 根据分析目的取特定时刻的快照值 |
| `price` | 本次尝试扣费总额，在扣费失败场景下实际扣除金额应以 `adjusted_cost` 为准 | 统计实际扣费损失时使用 `SUM(adjusted_cost)`，而非 `SUM(price)` |

---

### 时效性说明

- 本表为 **T+1 调度**，每日写入前一业务日（`BIZ_YESTERDAY`）数据。查询最新数据时，`grass_date` 应取当前日期减 1。
- `deduct_date` 为日志原始字段，在跨午夜边界场景下可能与 `grass_date` 存在 ±1 天偏差，**建议始终以 `grass_date` 作为日期过滤的权威分区字段**。
- `event_time` 为事件发生时的原始时间戳，各地区按本地时区参数化调度，跨地区对比时需注意时区换算。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_translog_unsuccessful_event_deduction_hi__reg_s0_live` | 唯一上游数据源，小时级扣费失败事件原始日志，提供本表所有字段的原始值 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ods_log_translog_unsuccessful_event_deduction_hi__reg_s0_live
  （小时级 ODS 扣费失败日志，覆盖 grass_date = BIZ_YESTERDAY）
                │
                │  过滤：grass_date = '${BIZ_YESTERDAY}'
                │  字段透传：大部分字段直接 SELECT
                │  UDF 解析：campaign_daily_balance_ext_info(campaign_balance_by_date.extinfo)
                │            → campaign_balance_by_date_extinfo
                ▼
mp_paidads.dwd_log_translog_unsuccessful_event_deduction_di__reg_s0_live
  （天级 DWD 扣费失败明细表，按 grass_region + grass_date 分区写入）
```

> 计算引擎：Hive（注册临时 UDF `campaign_daily_balance_ext_info`，类路径 `com.shopee.deepdata.warehouse.hive.udf.CampaignDailyBalanceExtInfoUDF`）；写入方式：`INSERT OVERWRITE ... PARTITION (grass_region, grass_date)` 动态分区覆盖写。

---

### 关键 CTE 说明

本 ETL 无 CTE，为单层 `INSERT OVERWRITE SELECT` 结构，逻辑简洁。

---

### 注意事项

1. **UDF 解析字段**：`campaign_balance_by_date_extinfo` 由自定义 UDF `campaign_daily_balance_ext_info` 解析 `campaign_balance_by_date.extinfo`（binary 格式）得到，是分析 Placement 级别预算撞线的核心字段。若发现该字段为 null，需检查上游 extinfo 是否为空（仅 Quota Split 类 Campaign 有值）。

2. **覆盖写入幂等性**：ETL 使用动态分区 `INSERT OVERWRITE`，每次调度仅覆盖 `grass_date = BIZ_YESTERDAY` 对应的分区，历史分区不受影响。重跑历史日期时需手动指定对应的 `BIZ_YESTERDAY` 参数。

3. **`operation` 字段无效**：DDL 注释明确标注该字段"Basically all empty, no practical significance, can be ignored"，查询中不应依赖此字段做任何过滤或分组。

4. **`status` 字段含义**：本表存储的是扣费**未完全成功**的事件，但 `status=1`（StatusOK，部分成功）的记录也会出现在本表中（表示有部分广告扣费成功，但整体判定为 unsuccessful）。分析完全失败事件时建议排除 `status=1`，或根据具体业务目标选择状态码范围。

5. **金额单位**：所有金额字段（`price`、`adjusted_cost`、`credit_cost`、`balance_cost`、`daily_quota`、`total_quota` 等）均为平台最小货币单位（通常为分或等值最小单位），换算为标准货币单位时需除以对应地区的精度因子。

6. **多地区调度隔离**：各地区数据通过 `grass_region` 分区物理隔离，跨地区聚合时需注意货币单位、时区及业务规则差异。

---

*文档生成时间：2026-04-22*