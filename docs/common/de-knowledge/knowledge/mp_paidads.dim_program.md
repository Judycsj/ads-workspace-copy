<!-- ads-workspace-gdoc-sync: gdoc_id=1YgDsUMRhrBOOmKsit3Uid3Ll8oxS2OWjz_HugVUITe0 gdoc_url=https://docs.google.com/document/d/1YgDsUMRhrBOOmKsit3Uid3Ll8oxS2OWjz_HugVUITe0/edit -->

# mp_paidads.dim_program

**分层**：DIM（维度层）
**主键**：`program_id`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（Daily）
**引用频次**：37 次（候选表范围内）

---

## 业务描述

本表是 Shopee 广告 SRM（Seller Relationship Management）项目维度表，记录各地区卖家激励计划（Program）的完整属性快照。表中涵盖计划的基本信息（名称、状态、类型）、时间节点（创建/开始/结束/展示）、激励参数（免费广告金、最低充值金额、返现配置等）以及操作权限配置，是分析 SRM 计划运营效果、覆盖规模与参与状态的核心维度表。

本表同时整合两条数据源：其一来自 `program_tab`（存量 SRM 计划，含 QSS、充值激励、固定消耗激励、返现消耗激励等类型），通过解析 `extinfo` JSON 提取精细化参数；其二来自 `program_v2_tab`（新版计划表），通过关联计划类型表补充 `program_type_name`。两路数据通过 `UNION ALL` 合并，确保计划维度的完整覆盖。

下游使用方（如广告绩效报表、卖家画像、计划状态追踪等场景）可通过 `program_id` 与事实表关联，结合 `program_status`、`program_type`、`grass_region`、`grass_date` 等字段进行计划维度分析。各地区按本地时区参数化调度，`tz_type = 'local'` 为标准过滤条件。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型，当前写入值固定为 `'local'`，查询时须过滤 `tz_type = 'local'` 以避免重复数据 ⚠️ 表中仅存 `local` 分区，若不过滤不会返回重复值，但建议显式指定以保证语义明确并利用分区裁剪 |
| `grass_region` | string | 国家/地区代码（大写），如 `TW`、`ID`、`MY` 等，由调度参数 `${region}` 参数化注入 |
| `grass_date` | date | 数据日期，格式 `yyyy-MM-dd`，分区键；来源于调度参数 `${grass_date}` |

---

### 维度：主键与计划基本属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `program_id` | bigint | 计划唯一标识（主键），来源于 `program_tab.id` 或 `program_v2_tab.id` |
| `program_name` | string | 计划名称 |
| `program_status` | bigint | 计划状态枚举值：`0` 未开始、`1` 就绪、`2` 已完成、`3` 失败、`4` 已移除、`5` 广告创建成功、`6` 广告创建失败、`7` 信用注入成功、`8` 信用注入失败、`9` 广告创建成功并结束、`10` 信用注入成功并结束、`11` 加入其他计划、`12` 奖励领取失败、`100` 回滚到上一状态 ⚠️ 为枚举编码，业务查询时需对照枚举含义过滤，勿直接数值比较而忽略枚举语义 |
| `program_type` | string | 计划类型枚举：`1` QSS（Quick Start Service）、`2` 充值激励、`3` 固定消耗激励、`4` 返现消耗激励；来自 `program_tab`，`program_v2_tab` 数据此字段为 `NULL` ⚠️ `program_v2_tab` 分支中该字段为 NULL，需结合 `program_type_name` 联合判断 |
| `program_type_name` | string | 计划类型名称；仅 `program_v2_tab` 分支通过关联 `program_type_tab` 获得，`program_tab` 分支中固定为 `NULL` ⚠️ 两条数据来源下该字段互斥填充，使用时需注意来源差异 |
| `segment_id` | bigint | 卖家分群 ID，代表一组 `shop_id`；`program_v2_tab` 分支中为 `NULL` |
| `program_quota` | bigint | 计划配额（名额上限）；`program_v2_tab` 分支中为 `NULL` |
| `extinfo` | string | 扩展信息，原始 JSON 字符串（已解码为 UTF-8）；包含 QSS 参数、激励参数、访问控制等多层嵌套结构 ⚠️ 为 JSON 格式，直接使用需通过 `get_json_object` 解析，不可直接过滤字符串 |

---

### 维度：计划时间节点

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `program_create_timestamp` | bigint | 计划创建时间，Unix 时间戳（秒），来源于 `ctime` |
| `program_create_datetime` | string | 计划创建时间，格式 `yyyy-MM-dd HH:mm:ss`，由 `ctime` 经 `from_unixtime` 转换 ⚠️ 时区受调度参数 `${timezone}` 影响，各地区按本地时区转换，跨地区对比需注意时区一致性 |
| `program_start_timestamp` | bigint | 计划开始时间，Unix 时间戳（秒），来源于 `start_time` |
| `program_start_datetime` | string | 计划开始时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 同上，受本地时区影响 |
| `program_end_timestamp` | bigint | 计划结束时间，Unix 时间戳（秒），来源于 `end_time` |
| `program_end_datetime` | string | 计划结束时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 同上，受本地时区影响 |
| `program_last_modified_timestamp` | bigint | 计划最后修改时间，Unix 时间戳（秒），来源于 `mtime` |
| `program_last_modified_datetime` | string | 计划最后修改时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 同上，受本地时区影响 |
| `display_timestamp` | bigint | 激励计划展示时间，Unix 时间戳（秒），从 `extinfo.incentive.display_time` 解析；`program_v2_tab` 分支中为 `NULL` |
| `display_datetime` | string | 激励计划展示时间，格式 `yyyy-MM-dd HH:mm:ss`，由 `display_timestamp` 转换；为 NULL 时输出 NULL ⚠️ 受本地时区影响 |
| `topup_deadline_timestamp` | bigint | 充值截止时间，Unix 时间戳（秒），从 `extinfo.qss.topup_deadline` 解析；`program_v2_tab` 分支中为 `NULL` |
| `topup_deadline_datetime` | string | 充值截止时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 受本地时区影响 |

---

### 维度：激励参数（金额类）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `free_credit_amt` | double | 免费广告金额度，本地货币，从 `extinfo.qss.free_credit` 解析，原始值除以 `100000.0` 还原为货币单位；`program_v2_tab` 分支中为 `NULL` ⚠️ 已做单位换算（÷100000），注意与原始存储值区分 |
| `free_credit_amt_usd` | double | 免费广告金额度，美元，由 `free_credit_amt` 除以当日汇率（`dim_exchange_rate`）得出；`program_v2_tab` 分支中为 `NULL` ⚠️ 依赖汇率表当日数据，若汇率缺失则为 NULL；为派生字段，不可直接 SUM 后再做跨货币比较 |
| `min_topup_amt` | double | 最低充值金额，本地货币，从 `extinfo.qss.min_topup` 解析，除以 `100000.0` 还原；`program_v2_tab` 分支中为 `NULL` ⚠️ 已做单位换算（÷100000） |
| `min_topup_amt_usd` | double | 最低充值金额，美元，由 `min_topup_amt` 除以汇率得出；`program_v2_tab` 分支中为 `NULL` ⚠️ 依赖汇率，为派生字段，不可直接 SUM 后跨货币汇总 |
| `min_item_price_amt` | double | 商品最低价格门槛，本地货币，从 `extinfo.qss.item_price_floor` 解析，除以 `100000.0`；`program_v2_tab` 分支中为 `NULL` ⚠️ 已做单位换算（÷100000） |
| `min_item_price_amt_usd` | double | 商品最低价格门槛，美元，由 `min_item_price_amt` 除以汇率得出；`program_v2_tab` 分支中为 `NULL` ⚠️ 依赖汇率，为派生字段 |
| `default_daily_budget` | double | 默认日预算，本地货币，从 `extinfo.qss.default_daily_budget` 解析，除以 `100000.0`；`program_v2_tab` 分支中为 `NULL` ⚠️ 已做单位换算（÷100000） |

---

### 维度：激励参数（时间与数量类）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `topup_window` | bigint | 充值窗口期，从 `extinfo.qss.topup_window` 解析；`program_v2_tab` 分支中为 `NULL` |
| `min_topup_amt` | double | （见激励参数金额类，此处已列出） | 
| `credit_expiry_days_cnt` | bigint | 广告金有效天数，从 `extinfo.qss.credit_expiry_duation` 解析（注意原始字段名拼写为 `credit_expiry_duation`，已映射为本字段）；`program_v2_tab` 分支中为 `NULL` ⚠️ 原始 JSON key 存在拼写错误（`duation`），与 `credit_expiry_duration` 字段含义不同，注意区分 |
| `credit_expiry_duration` | bigint | 广告金有效时长，单位秒，从 `extinfo.incentive.credit_expiry_duration` 解析；`program_v2_tab` 分支中为 `NULL` ⚠️ 与 `credit_expiry_days_cnt` 来源路径不同（一个来自 `qss`，一个来自 `incentive`），单位也不同（天 vs 秒），勿混用 |
| `credit_claim_period` | bigint | 广告金领取有效期，单位秒，从 `extinfo.incentive.credit_claim_period` 解析；`program_v2_tab` 分支中为 `NULL` |
| `sku_number` | bigint | QSS 计划关联的 SKU 数量，从 `extinfo.qss.sku_number` 解析；`program_v2_tab` 分支中为 `NULL` |

---

### 维度：激励配置详情

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `cashback_onboarding` | string | 新手返现激励配置信息（JSON 字符串），对应 SRM 类型 `SRM_PROGRAM_TYPE_CASHBACK_ONBOARDING_INCENTIVE`，从 `extinfo.cashback_onboarding` 提取；`program_v2_tab` 分支中为 `NULL` ⚠️ 为 JSON 格式，需用 `get_json_object` 进一步解析 |
| `cashback_multi` | string | 多阶段返现激励配置信息（JSON 字符串），对应 `SRM_PROGRAM_TYPE_CASHBACK_MULTI_INCENTIVE`，从 `extinfo.cashback_multi` 提取；`program_v2_tab` 分支中为 `NULL` ⚠️ 为 JSON 格式，需用 `get_json_object` 进一步解析 |
| `fixed_multi` | string | 多阶段固定激励配置信息（JSON 字符串），对应 `SRM_PROGRAM_TYPE_FIXED_MULTI_INCENTIVE`，从 `extinfo.fixed_multi` 提取；`program_v2_tab` 分支中为 `NULL` ⚠️ 为 JSON 格式，需用 `get_json_object` 进一步解析 |
| `learn_more_link` | string | 激励计划详情页链接，从 `extinfo.incentive.learn_more_link` 提取；`program_v2_tab` 分支中为 `NULL` |
| `is_auto_claim` | boolean | 是否自动领取广告金，从 `extinfo.incentive.is_auto_claim` 解析；`program_v2_tab` 分支中为 `NULL` |

---

### 维度：操作员与权限

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `operator_id` | bigint | 操作员 ID；`program_v2_tab` 分支中为 `NULL` |
| `operator` | string | 操作员标识；`program_v2_tab` 分支中为 `NULL` |
| `owner_operator_type` | int | 计划归属操作方类型，控制哪一方可编辑计划：`0` 任何人均可编辑/操作；`1` 系统（system）可编辑任意计划；其他值表示须与 owner 类型匹配方可操作。背景：QSS 计划可由 local 端和 algo 端同时创建，此字段用于管控编辑权限。从 `extinfo.access_control.owner_operator_type` 解析；`program_v2_tab` 分支中为 `NULL` |

---

## 查询使用须知

### 必须包含的过滤条件

| 过滤字段 | 推荐值/说明 | 遗漏后果 |
|----------|-------------|----------|
| `tz_type` | `= 'local'` | 当前仅写入 `local` 分区，但显式指定可确保分区裁剪生效，避免全表扫描 |
| `grass_region` | 指定目标地区，如 `= 'ID'` | 若不过滤将扫描所有地区分区，性能极差 |
| `grass_date` | 指定具体日期或范围，如 `= '2026-04-21'` | 缺少日期过滤将扫描全历史分区，导致查询超时或费用激增 |

**推荐最小过滤模板：**
```sql
WHERE tz_type = 'local'
  AND grass_region = '<TARGET_REGION>'
  AND grass_date = '<TARGET_DATE>'
```

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确处理方式 |
|------|----------|-------------|
| `free_credit_amt_usd` | 由本地货币金额除以汇率派生，汇率因日因地而异，跨地区/跨日 SUM 无意义 | 按地区分别汇总本地货币金额，或统一使用同一时间节点的汇率重新换算 |
| `min_topup_amt_usd` | 同上，依赖当日汇率派生 | 同上 |
| `min_item_price_amt_usd` | 同上，依赖当日汇率派生 | 同上 |
| `program_status` | 为枚举整型，直接 SUM 无业务含义 | 作为过滤条件或 GROUP BY 分组使用 |
| `program_type` | 为枚举字符串，直接聚合无意义 | 作为过滤或分组条件 |
| `credit_expiry_days_cnt` vs `credit_expiry_duration` | 两字段来源路径不同，单位不同（天 vs 秒），不可混合聚合 | 明确区分字段语义后单独使用 |

### 时效性说明

本表为每日全量快照，每个 `grass_date` 分区记录截至当日的 **所有历史创建计划**（`ctime < DATE_ADD(grass_date, 1)` 即创建时间早于次日零点的计划均被纳入）。

- 分析**当前在跑计划**时，取最新 `grass_date` 分区并结合 `program_status` 过滤（如 `program_status IN (1, 5, 7)`）。
- 分析**计划历史状态变化**时，需关联多个 `grass_date` 分区追踪状态流转，注意每次查询需同时指定 `tz_type` 和 `grass_region` 分区条件。
- `program_v2_tab` 来源的计划（`program_type` 为 NULL、`program_type_name` 不为 NULL）在多数激励参数字段上均为 `NULL`，时序分析时需区分两类来源数据。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_srm_${region}_db__program_tab__reg_daily_s0_live` | 主数据源（Branch 1）：存量 SRM 计划基本属性及 `extinfo` JSON，提供 QSS 参数、激励参数等详细配置 |
| `mp_paidads.shopee_ads_srm_${region}_db__program_v2_tab__reg_continuous_s0_live` | 主数据源（Branch 2）：新版计划表，提供 `program_v2` 体系下的计划基本属性 |
| `mp_paidads.shopee_ads_srm_${region}_db__program_type_tab__reg_continuous_s0_live` | 参考表：计划类型维表，通过 `program_type_id` 关联补充 `program_type_name` |
| `mp_order.dim_exchange_rate__reg_s0_live` | 参考表：汇率维表，按 `grass_region` + `grass_date` 关联，用于将本地货币金额换算为美元 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.shopee_ads_srm_${region}_db__program_tab__reg_daily_s0_live
  │
  ├─ [内层 SELECT] 字段重命名 + extinfo 解码(UTF-8) + 时间戳转 datetime
  │
  ├─ [中层 SELECT] get_json_object 解析 extinfo 各 JSON 路径
  │    ├─ $.qss.sku_number / topup_window / min_topup / topup_deadline
  │    ├─ $.qss.free_credit / credit_expiry_duation / item_price_floor
  │    ├─ $.qss.default_daily_budget
  │    ├─ $.incentive.display_time / learn_more_link
  │    ├─ $.incentive.credit_expiry_duration / credit_claim_period / is_auto_claim
  │    ├─ $.cashback_onboarding / cashback_multi / fixed_multi
  │    └─ $.access_control.owner_operator_type
  │
  ├─ LEFT JOIN mp_order.dim_exchange_rate__reg_s0_live
  │    ON grass_region + grass_date → 获取 exchange_rate
  │    └─ 计算 *_amt_usd 字段（本地金额 ÷ exchange_rate）
  │
  └─ [Branch 1 输出] → UNION ALL
                              │
mp_paidads.shopee_ads_srm_${region}_db__program_v2_tab__reg_continuous_s0_live
  │
  └─ LEFT JOIN shopee_ads_srm_${region}_db__program_type_tab__reg_continuous_s0_live
       ON program_type_id = id → 获取 program_type_name
       │
       └─ [Branch 2 输出，激励参数字段均为 NULL]
                              │
                         UNION ALL
                              │
                              ▼
          INSERT OVERWRITE dim_program__reg_s0_live
          PARTITION (tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

本 ETL 无显式命名 CTE，采用嵌套子查询（Subquery）结构，逻辑层次如下：

| 层级 | 来源 | 作用 |
|------|------|------|
| 内层子查询（Branch 1） | `program_tab` | 字段重命名、`extinfo` UTF-8 解码、时间戳转 datetime 字符串、截止条件过滤（`ctime < 次日零点`） |
| 中层子查询（Branch 1） | 内层子查询 | 从 `extinfo` JSON 逐一提取 QSS 参数、激励参数、访问控制参数，单位还原（÷100000） |
| 汇率 JOIN（Branch 1） | `dim_exchange_rate` | 补充当日汇率，计算美元金额字段 |
| 直接 SELECT（Branch 2） | `program_v2_tab` LEFT JOIN `program_type_tab` | 获取新版计划基本字段与类型名称，激励参数置 NULL |
| UNION ALL | Branch 1 + Branch 2 | 合并两条数据链路，写入目标分区 |

### 注意事项

1. **两路数据来源字段不对称**：`program_tab`（Branch 1）提供完整的激励参数（`free_credit_amt`、`cashback_multi` 等），而 `program_v2_tab`（Branch 2）这些字段全部为 `NULL`，仅有 `program_type_name` 非空。下游使用时应根据字段是否为 NULL 区分数据来源。

2. **金额字段单位换算**：原始 `extinfo` 中的金额以整数最小单位存储，ETL 中统一除以 `100000.0` 还原为标准货币单位。若直接读取 `extinfo` 原始 JSON 字段（如 `extinfo` 列），金额值与 `*_amt` 字段差 10 万倍。

3. **`credit_expiry_days_cnt` 拼写来源问题**：该字段从 `extinfo.qss.credit_expiry_duation`（原始 JSON key 拼写错误，缺少字母 `r`）解析，单位为**天**；而 `credit_expiry_duration` 从 `extinfo.incentive.credit_expiry_duration` 解析，单位为**秒**。两字段语义、路径、单位均不同，严禁混用。

4. **汇率缺失风险**：`*_amt_usd` 字段依赖 `dim_exchange_rate` 当日数据，若某地区某日汇率表无记录（LEFT JOIN 后 `exchange_rate` 为 NULL），所有美元金额字段将为 `NULL`，下游需做 NULL 处理。

5. **`program_tab` 时间过滤口径**：Branch 1 过滤条件为 `ctime < UNIX_TIMESTAMP(DATE_ADD(grass_date, 1))`，即仅包含在 `grass_date` 当日结束前已创建的计划，为存量全量快照，并非仅当日新增。

6. **`program_type` 字段类型**：DDL 中 `program_type` 为 `string` 类型，但注释中枚举值为整数（1/2/3/4），过滤时需使用字符串格式，如 `program_type = '1'`。

7. **各地区按本地时区参数化调度**：所有 datetime 字段（`*_datetime`）均在调度时按 `${timezone}` 参数转换，不同地区的 datetime 值反映各地区本地时间，跨地区对比时需注意时区差异。

---

*文档生成时间：2026-04-22*