<!-- ads-workspace-gdoc-sync: gdoc_id=11_d93wBqh9S41j-LeDycR0x9qsRyX2Ic585ZuDHAh5c gdoc_url=https://docs.google.com/document/d/11_d93wBqh9S41j-LeDycR0x9qsRyX2Ic585ZuDHAh5c/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_page_level_metrics_1d

**分层**：dws_search（数据仓库服务层 - 搜索域）
**主键**：`grass_region` + `local_date` + `experiment_id` + `exp_group_id` + `page_type`
**分区**：`grass_region`（大区）/ `local_date`（本地日期）
**更新频率**：每日一次（T+1 全量覆写，`INSERT OVERWRITE`）
**引用频次 / 访问频次**：707

---

## 业务描述

本表为搜索 A/B 实验的**页面级日粒度汇总宽表**，记录各实验分组在不同搜索相关页面类型下的用户规模与时长消耗情况。

核心业务场景：

- **搜索 A/B 实验效果评估**：按实验（`experiment_id`）和实验分组（`exp_group_id`）拆分，衡量不同策略对用户在搜索页面上停留时长与活跃用户数的影响。
- **页面类型维度分析**：支持对搜索结果页（`search`）、预搜索页（`pre_search`）、搜索建议页（`search_suggest_page`）、图片搜索页（`image_search`）以及商品详情页（`product`，来自搜索入口跳转）等页面分别进行指标拆解。
- **大区级对比**：通过 `grass_region` 分区支持多市场独立分析。

适合回答的典型问题：

- 实验组与对照组用户在搜索相关页面的日活跃用户数（DAU）差异是多少？
- 各实验分组在搜索结果页的平均停留时长（小时）如何变化？
- 某大区某日各搜索页面类型的实验组用户规模分布情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 `ID`、`TH`、`MY` 等），用于分区隔离多市场数据 |
| `local_date` | date | 本地日期（用户所在时区），对应数据统计的自然日 |

### 维度：实验与页面标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | A/B 实验 ID，标识具体的搜索实验 |
| `exp_group_id` | bigint | 实验分组 ID，标识实验组或对照组 |
| `page_type` | string | 页面类型，枚举值包括：`search`（搜索结果页）、`pre_search`（预搜索页）、`search_suggest_page`（搜索建议页）、`image_search`（图片搜索页）、`product`（来自搜索/图片搜索入口的商品详情页） |

### 指标：用户行为汇总

| 字段 | 类型 | 说明 |
|---|---|---|
| `dau` | bigint | 日活跃用户数（Distinct Active Users），统计当日在该实验分组 × 页面类型下产生浏览行为的去重用户数（`COUNT(DISTINCT user_id)`） |
| `duration` | double | 总停留时长（单位：**小时**），由页面浏览时长（毫秒）累加后除以 3,600,000 换算而来（`SUM(page_duration) / 3600000`） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定 `grass_region`**：该字段为一级分区，不加过滤将触发全表扫描，严重影响查询性能。
- **必须指定 `local_date`**：该字段为二级分区，建议使用精确日期或有界范围，避免多分区大量扫描。

```sql
-- 正确示例
WHERE grass_region = 'ID'
  AND local_date = '2025-05-16'
```

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确处理方式 |
|---|---|---|
| `dau` | 去重指标（按 `user_id` COUNT DISTINCT），跨实验组或跨页面类型相加会导致重复计数 | 不可跨 `exp_group_id` 或 `page_type` 直接累加；如需汇总需回溯明细层或使用 HLL 估算 |
| `duration` | 预聚合求和值，本身可以按维度累加；但若与 `dau` 计算人均时长，须在同一维度粒度内进行 | `SUM(duration) / SUM(dau)` 需确保分子分母维度一致 |

### 时效性说明

- 本表为 **T+1** 日粒度表（`_1d` 后缀），每日调度完成后数据覆盖前一自然日分区，**不包含当日实时数据**。
- 采用 `INSERT OVERWRITE PARTITION` 模式，每次调度对目标分区做全量覆写，支持重跑幂等。
- 仅纳入 **iOS / Android** 移动端用户行为，Web 端及其他平台不在统计范围内。
- 用户需满足**搜索白名单**（`is_search_whitelist = 1`）且为**命中分流日志**（`is_assignment_log = 1`）的实验成员，未被纳入实验的用户行为不计入本表。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 搜索 A/B 实验用户分组维表，提供用户与实验/分组的映射关系；过滤搜索白名单用户和有效分流记录 |
| `traffic.dwd_view_di__reg_live` | 流量域页面浏览明细事实表，提供用户维度的页面类型及停留时长（毫秒）原始数据 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dim_sr_data_warehouse_abtest_user_group   ──┐
                                                       ├─► exp_group_metrics（JOIN + GROUP BY）──► 目标表分区写入
traffic.dwd_view_di__reg_live                        ──┘
```

### 关键步骤

**Step 1 — Temporary View：`user_exp_mapping_${grass_region_without_quote}`**

从实验用户分组维表中提取当日、当大区、命中搜索白名单（`is_search_whitelist = 1`）且有有效分流记录（`is_assignment_log = 1`）的用户，获取 `user_id → experiment_id + exp_group_id` 映射。

**Step 2 — Temporary View：`traffic_view_data_${grass_region_without_quote}`**

从页面浏览明细表中过滤出当日、当大区、本地时区（`tz_type = 'local'`）、已登录（`user_id > 0`）、移动端（iOS / Android）用户的搜索相关页面浏览记录，覆盖以下页面类型：

- `search`：场景键须为 `PAGE_GLOBAL_SEARCH`、`PAGE_PDP_SEARCH` 或 `PAGE_PREFILL_SEARCH`
- `pre_search`、`search_suggest_page`、`image_search`：直接按页面类型过滤
- `product`：上一页来源为搜索相关页（`pre_position_code like 'search.%'` 且对应场景键）或图片搜索（`pre_position_code like 'image_search.%'`）

**Step 3 — Temporary View：`exp_group_metrics_${grass_region_without_quote}`**

将 Step 1（实验分组映射）与 Step 2（页面浏览流量）按 `user_id` 内连接（INNER JOIN），按 `experiment_id + exp_group_id + page_type` 分组聚合：

- `duration = SUM(page_duration) / 3600000`（毫秒转小时）
- `dau = COUNT(DISTINCT user_id)`

**Step 4 — INSERT OVERWRITE（目标表写入）**

将 Step 3 聚合结果以 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 方式全量覆写目标表对应分区，字段按序写入 `experiment_id`、`exp_group_id`、`page_type`、`duration`、`dau`。

### 注意事项

- **单 ETL 文件、单 Writer**：本表仅由一个 ETL 文件驱动，无 multi-writer 风险，各大区通过参数化 `${grass_region}` 隔离写入不同分区。
- **INNER JOIN 语义**：Step 3 使用内连接，只有同时出现在实验分组维表和流量明细表中的用户才会被计入指标，纯流量用户或未命中实验的用户均被排除。
- **`duration` 精度**：原始 `page_duration` 单位为毫秒（bigint），除以 3,600,000 后得到 double 类型小时值，查询时注意单位换算。
- **分区覆写幂等性**：每次调度对目标分区执行全量 `OVERWRITE`，支持安全重跑，无需手动清理历史分区数据。

---

*文档生成时间：2026-05-17*