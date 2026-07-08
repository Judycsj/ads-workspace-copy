<!-- ads-workspace-gdoc-sync: gdoc_id=1SHaRda1ThbrJ0Nu86-I2crf_Gn63CQdWNvBKTtyEiOk gdoc_url=https://docs.google.com/document/d/1SHaRda1ThbrJ0Nu86-I2crf_Gn63CQdWNvBKTtyEiOk/edit -->

# srdi_mart.dwd_dispatch_log_for_item_expansion

**分层：** DWD（明细数据层）
**主键：** `request_id` + `original_item_id` + `expansion_strategy` + `candidate_item_id` + `regional_date` + `regional_hour` + `grass_region`
**分区：** `grass_region` / `regional_date` / `regional_hour`（三级分区）
**更新频率：** 按小时覆盖写入（INSERT OVERWRITE，每小时调度一次）
**引用频次 / 访问频次：** 206

---

## 业务描述

本表记录搜推系统（SRDI）**候选商品扩展（Item Expansion）** 环节的分发日志明细，来源于实时分发日志原始层（ODS），经解析、展开后落地为可分析的宽表。

**核心业务场景：**
- 追踪每次推荐请求中，原始商品（`original_item_id`）经过扩展策略（`expansion_strategy`）后，产生哪些候选商品（`candidate_item_id`），以及候选商品最终是否通过准入（Admittance）、候选筛选（Candidate）、扩展（Expansion）等各环节。
- 分析不同扩展策略的漏斗转化率（准入 → 候选 → 扩展）。
- 评估剪枝（Prune）原因分布，识别候选商品被过滤的主要原因。
- 支持 A/B 实验分组（`exp_group_id`）维度下的商品扩展效果对比分析。
- 分析探索模式（`exploration_mode`）对扩展结果的影响。

**适合回答的问题：**
- 某时间段内，各扩展策略的候选商品通过率如何？
- 特定用户或商品的扩展链路是什么（原始商品 → 候选商品 → 最终商品）？
- 不同地区（`grass_region`）的扩展策略效果是否存在差异？
- 候选商品被剪枝的主要原因是什么？
- 各 A/B 实验组的扩展命中率对比。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区标识，如 `SG`、`MY`、`TH` 等；查询时必须指定 |
| `regional_date` | date | 业务日期（按地区本地时间），格式 `yyyy-MM-dd`；查询时必须指定 |
| `regional_hour` | string | 业务小时（按地区本地时间），格式 `HH`（如 `"09"`）；查询时建议指定 |

---

### 维度：请求与用户信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 推荐请求唯一标识，解析自 `rcmd_request.requestid_v2.TraceID` |
| `user_id` | bigint | 发起请求的用户 ID |
| `bundle` | string | 请求来源应用包名（App Bundle） |
| `exp_group_id` | array\<int\> | A/B 实验分组 ID 列表，来源于 `abtest_group_ids` |

---

### 维度：商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `original_item_id` | bigint | 原始商品 ID。当扩展类型为 `ITEM_EXPANSION_TYPE_NONE` 时取 `runit_item_id`，否则取 `expansion_info.original_item.itemid` |
| `original_cspu_id` | array\<bigint\> | 原始商品对应的 CSPU（标准产品单元）ID 列表 |
| `candidate_item_id` | bigint | 候选扩展商品 ID |
| `candidate_cspu_id` | bigint | 候选商品对应的 CSPU ID |
| `final_itemid` | bigint | 扩展后最终确定的商品 ID |
| `winner_ritem_id` | bigint | 竞选胜出的推荐商品 ID |
| `roi_item_type` | string | 原始商品的 ROI 商品类型 |
| `ctx_item_type` | int | 上下文商品类型（Context Item Type） |

---

### 维度：扩展策略与流程

| 字段 | 类型 | 说明 |
|---|---|---|
| `expansion_strategy` | string | 本行对应的扩展策略名称（来源于 `strategies` Map 的 key，已 explode 展开） |
| `exploration_mode` | string | 探索模式标识，表示当前候选商品采用的探索策略 |
| `hashtag` | string | 候选商品关联的 Hashtag 标签 |
| `hashtag_statistic` | string | 候选商品 Hashtag 的统计信息（JSON 字符串） |

---

### 维度：扩展漏斗状态标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `has_admittance` | boolean | 是否经过准入（Admittance）环节 |
| `has_candidate` | boolean | 是否产生候选商品 |
| `has_expansion` | boolean | 是否最终完成扩展 |
| `has_prune` | boolean | 候选商品是否被剪枝（过滤） |

---

### 维度：扩展状态详情

| 字段 | 类型 | 说明 |
|---|---|---|
| `admittance_status` | string | 准入阶段的状态描述 |
| `candidate_status` | string | 候选商品筛选阶段的状态描述 |
| `expansion_status` | string | 扩展策略层面的扩展状态 |
| `candidate_expansion_status` | string | 单个候选商品维度的扩展状态 |
| `prune_reason` | string | 候选商品被剪枝的原因 |

---

### 指标：位置信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `before_swap_pos` | int | 商品扩展/替换前的排列位置（坑位） |
| `after_swap_pos` | int | 商品扩展/替换后的排列位置（坑位） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则全区扫描，成本极高。
- **`regional_date`**：必须指定，建议同时指定 `regional_hour` 缩小扫描范围。
- 推荐标准过滤写法：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2026-05-17'
    AND regional_hour = '10'
  ```

### 不可直接 SUM / AVG 的字段

- **`exp_group_id`（array\<int\>）**：数组类型，需先 `explode` 后再聚合，不可直接 COUNT/SUM。
- **`original_cspu_id`（array\<bigint\>）**：数组类型，需先 `explode` 后再聚合。
- **`before_swap_pos` / `after_swap_pos`**：位置信息，直接求均值前需确认业务口径，-1 或特殊值可能表示无效位置，需过滤。
- **`has_admittance` / `has_candidate` / `has_expansion` / `has_prune`**：布尔型，统计通过率时需 `COUNT(CASE WHEN ... THEN 1 END) / COUNT(*)` 方式计算，避免混淆 NULL 与 false。

### 粒度说明

- 本表已按 `expansion_strategy`（策略维度）和 `candidate_item_id`（候选商品维度）双重 explode，**同一个 `request_id` + `original_item_id` 组合会对应多行**，聚合时需注意去重。
- 若统计请求级别指标（如请求数），需对 `request_id` 去重（`COUNT(DISTINCT request_id)`）。

### 时效性说明

- 本表为**小时级分区表**，数据以小时为粒度覆盖写入（INSERT OVERWRITE），当前小时数据在该小时调度完成后可用。
- 无跨天聚合预计算字段，如需统计日级指标，需自行按 `regional_date` 聚合所有小时分区。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_rt.ods_dispatch_log_for_item_expansion` | 原始分发日志 ODS 层，提供 `rcmd_request`、`res_item`、`abtest_group_ids`、`bundle` 等原始 JSON 字段，按 `regional_date`、`regional_hour`、`grass_region` 分区对齐读取 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_dispatch_log_for_item_expansion
    │  （按 regional_date / regional_hour / grass_region 分区过滤）
    ▼
raw_data（JSON 解析：提取 request_id、user_id；展开 res_item sections[0] 的 items 数组）
    ▼
processed_data（LATERAL VIEW EXPLODE items：每个 item 一行，解析 item 内各扩展字段）
    ▼
explode_data（双重 LATERAL VIEW EXPLODE：
    1. 展开 strategies Map → 每个扩展策略一行
    2. OUTER EXPLODE strategies.candidates → 每个候选商品一行）
    ▼
srdi_mart.dwd_dispatch_log_for_item_expansion（INSERT OVERWRITE 按分区写入）
```

### 关键步骤

1. **`raw_data`（CTE）**
   - 从 ODS 层按分区条件读取原始日志。
   - 使用 `optimized_json_tuple` 解析 `rcmd_request` 提取 `request_id`、`user_id`。
   - 将 `res_item.sections[0].data` 解析为 `ARRAY<string>`，得到 `items` 列表。

2. **`processed_data`（CTE）**
   - `LATERAL VIEW EXPLODE(items)` 将每条请求的商品列表展开，每个商品一行。
   - 对每个 item JSON 解析出：`runit_item_id`、`expansion_type`、`original_item_id`、`roi_item_type`、`cspu_list`、`strategies`、`final_itemid`。

3. **`explode_data`（CTE）**
   - 将 `strategies`（JSON Map）解析并 `EXPLODE map_entries`，每个扩展策略 key-value 展开为一行，得到 `expansion_strategy` 和对应策略详情。
   - `LATERAL VIEW OUTER EXPLODE` 策略值中的 `candidates` 数组，每个候选商品展开为一行（使用 OUTER 保留无候选商品的策略行）。
   - 从策略 value 解析 `has_admittance`、`has_candidate`、`has_expansion`、`admittance_status`、`candidate_status`、`expansion_status`、`before_swap_pos`、`after_swap_pos`、`ctx_item_type`、`winner_ritem_id`、`exploration_mode`。
   - 从候选商品 JSON 解析 `candidate_item_id`、`candidate_cspu_id`、`has_prune`、`prune_reason`、`candidate_expansion_status`、`hashtag`、`hashtag_statistic`。
   - `original_cspu_id` 通过 `transform + from_json` 提取 `cspu_list` 中各元素的 `cspu_id` 字段，转换为 `ARRAY<bigint>`。

4. **`INSERT OVERWRITE`（最终写入）**
   - 从 `explode_data` 中 SELECT，对各字段进行类型显式 CAST（bigint、int、boolean）。
   - `original_item_id` 逻辑：若 `expansion_type = 'ITEM_EXPANSION_TYPE_NONE'` 则使用 `runit_item_id`，否则使用解析出的 `original_item_id`。
   - `abtest_group_ids` 直接映射为 `exp_group_id`（array\<int\>）。
   - 覆盖写入目标表指定分区（`regional_date`、`regional_hour`、`grass_region`）。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险，分区写入逻辑唯一。
- **LATERAL VIEW OUTER EXPLODE**：候选商品列表使用 `OUTER EXPLODE`，当某扩展策略无候选商品时，`candidate_*` 相关字段为 NULL，聚合时需注意区分"无候选"与"候选被剪枝"场景。
- **JSON 解析容错**：上游字段均为 JSON 字符串，若上游日志格式变更或字段缺失，相关字段解析结果可能为 NULL，使用前建议进行 NULL 值检查。
- **分区参数化**：ETL 使用 `${grass_region}`、`${regional_date}`、`${regional_hour}` 等变量参数化分区，CTE 命名也含变量后缀（如 `raw_data_${grass_region_without_quote}`），实际执行时由调度系统注入。
- **INSERT OVERWRITE 覆盖风险**：按小时分区覆盖写入，重跑历史分区时会覆盖原有数据，需确认重跑范围。

---

*文档生成时间：2026-05-17*