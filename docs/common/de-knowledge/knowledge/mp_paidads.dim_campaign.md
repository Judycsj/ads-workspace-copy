<!-- ads-workspace-gdoc-sync: gdoc_id=1NHPzuhRfuxUFWz2xsuG_uEetOuXF0JOIG9Ey7GLs6_c gdoc_url=https://docs.google.com/document/d/1NHPzuhRfuxUFWz2xsuG_uEetOuXF0JOIG9Ey7GLs6_c/edit -->

# mp_paidads.dim_campaign

**分层：** DIM（维度层）
**主键：** `campaign_id` + `grass_region` + `grass_date` + `tz_type`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日全量覆写（INSERT OVERWRITE）
**引用频次：** 10 次（候选表范围内）

---

## 业务描述

`dim_campaign` 是付费广告域的**广告活动（Campaign）核心维表**，存储各地区所有广告活动的完整属性快照，涵盖活动标识、状态、预算配置、时间信息、ROI 目标设置、NPA（新品广告）、CPS（按销售付费）、自动预算提升等关键维度。每日全量刷新，记录截止当日的最新活动状态，是广告分析、效果归因、预算管理等场景的基础维度表。

本表广泛用于：关联事实表进行广告活动维度下钻分析（如按活动类型、状态、GMV 类型分组统计广告花费与 ROI）；监控广告活动预算配置合理性（日预算、总预算、配额分配）；以及识别特定类型广告活动（NPA 新品广告、CPS 活动、自动广告解决方案等）的覆盖范围与启用情况。

本表通过 `${region}`、`${timezone}` 参数化调度，覆盖 Shopee 各地区市场，各地区按本地时区参数化调度，所有日期时间字段均已转换为对应地区本地时间。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型分区。当前写入值固定为 `'local'`，表示所有日期时间字段已转换为各地区本地时区。查询时须显式指定 `tz_type = 'local'` 以避免全表扫描。 |
| `grass_region` | string | 地区分区，大写国家/地区代码（如 `'MY'`、`'TH'`）。标识该广告活动所属的地理市场。 |
| `grass_date` | date | 日期分区，格式 `yyyy-MM-dd`。记录该快照对应的日期，通常取最新分区以获取当日最新活动状态。 |

---

### 维度：主键与店铺归属

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `campaign_id` | bigint | 广告活动唯一标识（主键）。对应源表 `campaignid`。 |
| `shop_id` | bigint | 广告活动所属店铺 ID。 |
| `user_id` | bigint | 广告活动所属用户 ID。 |

---

### 维度：活动状态

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `campaign_status` | tinyint | 广告活动当前状态码。枚举值：0=已删除、1=正常、2=已暂停、3=已关闭、4=临时保留、5=已取消、6=已封禁、7=删除隐藏。 |
| `campaign_status_text` | string | 广告活动当前状态的文字描述，由 `campaign_status` 映射生成。枚举值：`ADS_DELETED` / `ADS_NORMAL` / `ADS_PAUSED` / `ADS_CLOSED` / `ADS_TEMP_RESERVED` / `ADS_CANCELLED` / `ADS_BANNED` / `ADS_DELETED_HIDE` / `OTHERS`。 |

---

### 维度：活动时间信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `campaign_start_timestamp` | bigint | 广告活动开始的 Unix 时间戳（秒）。原始存储为新加坡时区，已在 ETL 中进行时区转换。 |
| `campaign_start_datetime` | string | 广告活动开始时间，格式 `yyyy-MM-dd HH:mm:ss`，已转换为各地区本地时区。 |
| `campaign_end_timestamp` | bigint | 广告活动结束的 Unix 时间戳（秒）。若 `end_time = 0` 或为 NULL 则表示无结束时间。 |
| `campaign_end_datetime` | string | 广告活动结束时间，格式 `yyyy-MM-dd HH:mm:ss`，已转换为各地区本地时区。若活动无结束时间则为 NULL。 |
| `campaign_create_timestamp` | bigint | 广告活动创建的 Unix 时间戳（秒）。 |
| `campaign_create_datetime` | string | 广告活动创建时间，格式 `yyyy-MM-dd HH:mm:ss`，已转换为各地区本地时区。 |
| `campaign_modify_timestamp` | bigint | 广告活动最后一次修改的 Unix 时间戳（秒）。 |
| `campaign_modify_datetime` | string | 广告活动最后一次修改时间，格式 `yyyy-MM-dd HH:mm:ss`，已转换为各地区本地时区。 |

---

### 维度：活动类型与标签

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `campaign_type` | int | 广告活动类型编码，区分不同的广告产品类型（如商品推广、店铺推广等）。 |
| `campaign_tag` | bigint | 活动标签。`campaign_tag = 1` 表示该 GMS 广告是通过 GMS 创建工具为本地市场创建的。 |
| `gmv_type` | int | GMV 类型标识。`0` = Place GMV（下单 GMV）；`1` = Paid GMV（支付 GMV）。 |
| `creation_entry_point` | int | 广告活动首次创建时的入口点编码，来源于 `extinfo.creation_entry_point`。 |
| `creation_platform` | int | 创建广告活动的平台编码，来源于 `extinfo.creation_platform`。 |

---

### 维度：预算配置

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `daily_quota_local` | double | 广告活动的每日预算上限（本地货币，单位：元/主币种）。原始值除以 100000 换算而来。值为 0 或 NULL 表示无每日支出限制。⚠️ 为存储层换算值，直接 SUM 在跨地区场景下无意义，因各地区货币不同，需结合 `grass_region` 或换算为 USD 后再聚合。 |
| `daily_quota_usd` | double | 广告活动的每日预算上限（USD）。由 `daily_quota_local` 除以汇率得出。⚠️ 汇率来自 `mp_order.dim_exchange_rate__reg_s0_live` 当日快照，若汇率表数据缺失则为 NULL。 |
| `total_quota_local` | double | 广告活动的总预算上限（本地货币，单位：元/主币种）。原始值除以 100000 换算而来。⚠️ 同 `daily_quota_local`，跨地区聚合需注意货币单位差异。 |
| `total_quota_usd` | double | 广告活动的总预算上限（USD）。由 `total_quota_local` 除以汇率得出。⚠️ 汇率来自 `mp_order.dim_exchange_rate__reg_s0_live` 当日快照，若汇率表数据缺失则为 NULL。 |
| `quota_splits` | array<struct<placement:int, daily_available_quota:string, version:int, placements:array<int>>> | Item Boost 广告的配额分配明细，按投放位置（placement）存储每日可用配额。即使活动配置的是总预算，配额分配也以每日预算形式存储。⚠️ 为复合嵌套类型，需使用 `LATERAL VIEW` 或 `EXPLODE` 展开后使用。 |
| `user_last_daily_quota` | double | 用户最后一次设置的每日预算值（本地货币）。原始值除以 100000 换算而来。 |

---

### 维度：ROI 目标设置（ROI 2.0）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `roi_two` | double | 目标 ROI 2.0 的目标值，原始整数除以 100000 换算而来。有助于衡量广告活动效果目标设定。⚠️ 为派生换算值，不可直接 SUM，如需聚合应使用加权平均或按业务口径处理。 |
| `roi_two_display_target_value` | double | ROI 2.0 的展示目标值，原始整数除以 100000 换算而来。与 `roi_two` 可能存在差异（展示值 vs 实际目标值）。⚠️ 同样为换算值，不可直接 SUM。 |
| `simple_roi_two_estimate` | struct<est_roi_lower_bound:double, est_roi_upper_bound:double, est_order_lower_bound:bigint, est_order_upper_bound:bigint> | 仅用于简单 ROI 2.0（即 `roi_two = 0`）场景下，系统估算的 ROI 区间和订单量区间。`est_roi_lower_bound`/`est_roi_upper_bound` 已除以 100000 换算。`has_est` 判断请参考 `product_gms_estimate`。⚠️ 为嵌套结构体，访问子字段需使用 `.` 语法。 |
| `final_value_list` | array<double> | 创建广告时系统推荐的目标 ROAS 候选值列表，数组包含三个候选值，均已除以 100000 换算。⚠️ 为数组类型，不可直接聚合，需 EXPLODE 展开使用；且为创建时快照值，不反映后续修改。 |
| `suggest_roi_entry_point` | int | 系统推荐目标 ROAS 的入口点，可区分卖家是否实际看到了推荐值。 |
| `suggest_roi_api_source` | int | 获取推荐值的 API 来源。对于量效互换模型（volume-effect exchange model）此字段不得为空。 |
| `is_upgraded` | tinyint | 广告活动是否已从历史版本升级。`1` = 已升级，`0` = 未升级，NULL = 未知。⚠️ 该字段仅在 2024 年 10 月 25 日之后创建或修改的活动中有效，早期数据可能为 NULL。 |

---

### 维度：新品广告（NPA）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `is_npa` | tinyint | 是否为新品广告（New Product Ads）。`1` = 是，`0` = 否，NULL = 未知。 |
| `npa_current_phase` | int | 新品广告当前所处阶段：Phase 1 或 Phase 2。`0` 为无效值。 |

---

### 维度：CPS（按销售付费）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `is_cps` | tinyint | 广告活动是否使用 CPS（Cost Per Sale）计费模式而非 CPC（Cost Per Click）。`1` = CPS，`0` = CPC，NULL = 未知。 |
| `last_cps_timestamp` | bigint | CPS 最后一次处于激活状态的 Unix 时间戳（秒）。仅在 CPS 开关从开切换为关时更新。⚠️ 具有时效性，仅记录最后一次关闭 CPS 时的时间点，不代表当前 CPS 状态。 |

---

### 维度：自动预算提升（Auto Budget Increase）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `auto_budget_increase_counter` | int | 自动预算提升的累计次数。⚠️ 该计数器为累积值，BE 不会每日重置，仅在每次预算触发提升时 +1；直接 SUM 或做日环比无意义，应作为维度属性使用。 |
| `last_increment_timestamp` | bigint | 最后一次预算自动提升的 Unix 时间戳（秒）。 |
| `last_daily_reset_timestamp` | bigint | 最后一次每日预算重置的 Unix 时间戳（秒）。 |

---

### 维度：其他功能开关

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `is_rapid_boost_on` | tinyint | 是否开启急速推广（Rapid Boost）功能。`1` = 开启，`0` = 关闭，NULL = 未知。 |
| `is_auto_ads_solution_on` | tinyint | 是否开启自动广告解决方案（Auto Ads Solution）。`1` = 开启，`0` = 关闭，NULL = 未知。来源于 `extinfo.auto_ads_solution.is_on`。 |
| `product_gms_estimate` | struct<has_est:boolean, roi_lower_bound:double, roi_upper_bound:double, bid_roi:double> | 平台对该商品 GMV 的最大估算 ROI 区间。若 `product_gms_estimate.has_est = false`，则其余子字段无意义，可忽略。`roi_lower_bound`、`roi_upper_bound`、`bid_roi` 已除以 100000 换算。⚠️ 为嵌套结构体，使用前须先判断 `has_est` 标志；访问子字段需使用 `.` 语法。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询均须显式指定以下分区字段，避免触发全表扫描：

| 过滤字段 | 推荐值 / 说明 | 遗漏后果 |
|----------|---------------|----------|
| `tz_type` | `tz_type = 'local'` | 当前表仅写入 `local` 分区，遗漏会导致分区裁剪失效，引发全表扫描 |
| `grass_region` | 指定具体地区代码，如 `grass_region = 'MY'` | 遗漏将扫描所有地区数据，严重影响查询性能 |
| `grass_date` | 通常取最新分区，如 `grass_date = '2026-05-19'` | 遗漏将扫描全部历史分区，造成数据重复计算及查询超时 |

**示例过滤：**
```sql
WHERE tz_type = 'local'
  AND grass_region = 'MY'
  AND grass_date = '2026-05-19'
```

### 不可直接 SUM 的字段

| 字段名 | 问题说明 | 正确使用方式 |
|--------|----------|-------------|
| `roi_two` | 预计算换算值（原始值 / 100000），直接 SUM 无业务意义 | 分析 ROI 目标分布时使用 `AVG`、分桶或作为过滤条件 |
| `roi_two_display_target_value` | 同上，为换算值 | 同 `roi_two` |
| `daily_quota_local` / `total_quota_local` | 各地区货币不同，跨地区 SUM 无意义 | 跨地区聚合须先换算为 USD（使用 `_usd` 字段或关联汇率表） |
| `daily_quota_usd` / `total_quota_usd` | 依赖汇率快照，汇率缺失时为 NULL | 聚合前过滤 NULL，并注意汇率数据来源时效性 |
| `auto_budget_increase_counter` | 累积值，不代表单日增量 | 若需分析单日提升次数，须计算相邻分区差值 |
| `final_value_list` | 数组类型，不可直接聚合 | 使用 `LATERAL VIEW EXPLODE` 展开后再做统计 |
| `quota_splits` | 嵌套数组结构体 | 使用 `LATERAL VIEW EXPLODE` 展开后访问子字段 |
| `product_gms_estimate` | 嵌套结构体，`has_est = false` 时子字段无意义 | 先过滤 `product_gms_estimate.has_est = true` 再使用子字段 |
| `simple_roi_two_estimate` | 仅对 `roi_two = 0` 的活动有效，嵌套结构体 | 先过滤 `roi_two = 0` 再访问子字段 |

### 时效性说明

- 本表为**每日全量快照**，每个 `grass_date` 分区记录当日调度截止时刻的活动状态。
- `is_upgraded` 字段**仅对 2024 年 10 月 25 日后的数据有效**，查询历史数据时该字段可能为 NULL，需做 NULL 值兜底处理。
- `last_cps_timestamp` 仅在 CPS 从开切换为关时更新，不应用于判断当前 CPS 是否激活（应使用 `is_cps` 字段）。
- `campaign_create_datetime` 等时间字段基于调度截止日期过滤（`ctime < 次日零点时间戳`），仅包含在 `grass_date` 当日 24:00 前已创建的活动。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_${region}_${db_type}__campaign_tab__reg_continuous_s0_live` | 广告活动主表，提供活动基础属性（状态、时间、预算、extinfo 扩展信息等）|
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日汇率，用于将本地货币预算换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.shopee_ads_${region}_${db_type}__campaign_tab__reg_continuous_s0_live
    │
    │  ① 过滤：ctime < 次日零点（本地时区转换）
    │  ② 解析 _decoded_extinfo JSON → 展开为结构化字段
    │  ③ 时间戳转换：Asia/Singapore → 本地时区（各地区参数化）
    │  ④ 地区标识：upper('${region}')
    ▼
[campaign_tab_df] (Temporary View, REPARTITION 200)
    │
    │  ⑤ 内层 SELECT：展开 extinfo 各子字段
    │     - auto_budget_increase.counter / last_increment_timestamp 等
    │     - roi_two.target_value / is_npa / is_upgraded / is_cps 等布尔→tinyint 转换
    │     - rapid_boost / auto_ads_solution / gmv_type 等功能开关解析
    ▼
[campaign 子查询]
    │                                            mp_order.dim_exchange_rate__reg_s0_live
    │                                                │
    │                                                │  WHERE grass_region = upper('${region}')
    │                                                │    AND grass_date = DATE('${grass_date}')
    │                                                ▼
    │  LEFT OUTER JOIN ON campaign.region = exrate.grass_region
    │
    │  ⑥ 货币换算：原始整数 / 100000 → 本地货币；/ 100000 / exchange_rate → USD
    │  ⑦ campaign_status 映射 → campaign_status_text 文字描述
    │  ⑧ 复合结构体重建：simple_roi_two_estimate / product_gms_estimate
    ▼
INSERT OVERWRITE TABLE mp_paidads.dim_campaign__reg_s0_live
    PARTITION (tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `campaign_tab_df` | `shopee_ads_${region}_${db_type}__campaign_tab__reg_continuous_s0_live` | 读取广告活动源表，执行时区转换、JSON 解析（`from_json` 解析 `_decoded_extinfo`）、地区标识赋值，并通过 `REPARTITION(200)` 优化后续处理并行度 |

### 注意事项

1. **时区转换链路**：源表时间戳存储以新加坡时区（`Asia/Singapore`）为参考基准，ETL 通过 `to_utc_timestamp(..., 'Asia/Singapore')` 先转为 UTC，再通过 `from_utc_timestamp(..., '${timezone}')` 转为各地区本地时区，最终写入 `datetime` 字符串字段。使用时勿误认为是 UTC 时间。

2. **货币单位换算**：源表所有金额字段（`daily_quota`、`total_quota`、`roi_two` 等）均以整数存储（乘以 100000 的定点数），ETL 中统一除以 100000.0 还原为实际金额。嵌套结构体内的金额子字段（如 `product_gms_estimate` 中的 ROI 字段）同样经过此换算。

3. **汇率 LEFT JOIN 风险**：汇率表关联为 `LEFT OUTER JOIN`，若当日汇率数据缺失（草地区或节假日延迟），则 `daily_quota_usd` 和 `total_quota_usd` 将为 NULL，请在 USD 预算相关分析中增加 NULL 值判断。

4. **extinfo 字段演进**：`_decoded_extinfo` 为扩展 JSON 字段，历史早期活动可能缺少部分子字段（如 `auto_ads_solution`、`rapid_boost` 等），对应字段解析结果为 NULL，属正常现象。

5. **布尔值到 tinyint 的转换**：`is_cps`、`is_upgraded`、`is_npa`、`is_rapid_boost_on`、`is_auto_ads_solution_on` 均通过 CASE WHEN 将 `true/false/NULL` 映射为 `1/0/NULL`，避免布尔类型在下游聚合中的歧义。

6. **`auto_budget_increase_counter` 累积性**：该字段记录历史累计预算提升次数，BE 侧不重置，因此同一活动在不同 `grass_date` 快照中该值单调递增。分析单日预算提升行为须对相邻日期快照做差值计算。

---

*文档生成时间：2026-05-20*