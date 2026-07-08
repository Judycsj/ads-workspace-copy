<!-- ads-workspace-gdoc-sync: gdoc_id=1TyfhEQ5MpcavPn5iJJYRHhKiLmZ4t2erxqH-PrPwkHQ gdoc_url=https://docs.google.com/document/d/1TyfhEQ5MpcavPn5iJJYRHhKiLmZ4t2erxqH-PrPwkHQ/edit -->

# srdi_mart.dwd_sr_data_warehouse_tc_item_group_hi

**分层：** DWD（明细数据层）
**主键：** `item_id` + `rule_id` + `item_group_id` + `grass_region` + `regional_date` + `regional_hour`
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 小时级（逐小时覆盖写入）
**访问频次：** 42

---

## 业务描述

本表记录搜推流量调控（Traffic Control）任务维度下，**商品组（Item Group）与规则（Rule）的逐小时关联明细快照**，属于 SRDI 搜推数仓 DWD 层核心事实表之一。

数据来源于流量调控任务商品转储表，每小时覆盖写入最新可用分区，支持以下业务场景：

- **流量调控效果分析**：追踪实验组（`exp_test_ids`）与对照组（`exp_base_ids`）在不同场景（`scenes`）下的商品调控覆盖情况；
- **规则生命周期管理**：结合规则开始/结束时间（`rule_start_time` / `rule_end_time`）与任务状态（`task_status`），监控调控规则的存活与失效；
- **商品组状态审查**：判断商品组是否仍在有效调控中（`item_group_if_ongoing`），用于过滤历史失效组；
- **多场景拆分归因**：`scenes` 字段标准化处理后可区分 Search、Daily Discover、You May Also Like、Post Purchase、Shop 等渠道；
- **跨时区数据比对**：同时保留区域时间（`regional_date` / `regional_hour`）与本地时间（`local_date` / `local_hour`），方便多时区分析。

适合回答的典型问题：
- 某商品（`item_id`）在某小时处于哪些调控规则下？
- 某规则（`rule_id`）下有哪些有效商品组，当前是否仍在进行中？
- 某店铺（`shop_id`）在各搜推场景的调控覆盖范围？
- 某草区（`grass_region`）的调控任务实验分组情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 草区/大区标识，如 `SG`、`MY` 等，用于隔离不同区域数据 |
| `local_date` | date | 本地日期，由区域时间（SG）转换为对应草区本地时区的日期 |
| `local_hour` | int | 本地小时，由区域时间转换为对应草区本地时区的小时（0–23） |
| `regional_date` | date | 区域基准日期（SG 时区），ETL 调度参数直接写入 |
| `regional_hour` | int | 区域基准小时（SG 时区），ETL 调度参数直接写入（0–23） |

---

### 维度：商品与店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，调控任务作用的具体商品 |
| `shop_id` | bigint | 店铺 ID，商品所属店铺 |
| `item_group_id` | string | 商品组 ID；当 `target_type=5`（降权旧数据）时，填充为 `rule_id` 字符串以兜底去重 |

---

### 维度：规则信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `rule_id` | bigint | 调控规则 ID，关联 `dim_sr_data_warehouse_tc_rule` |
| `rule_start_time` | bigint | 规则生效开始时间（Unix 毫秒时间戳） |
| `rule_end_time` | bigint | 规则生效结束时间（Unix 毫秒时间戳） |
| `mtime` | bigint | 记录最后修改时间（Unix 毫秒时间戳） |
| `item_group_start_time` | bigint | 商品组开始生效时间（Unix 毫秒时间戳） |

---

### 维度：调控配置

| 字段 | 类型 | 说明 |
|---|---|---|
| `target_group` | int | 目标分组类型，标识商品组属于实验组或对照组等分类 |
| `target_type` | int | 目标类型，标识调控对象类型（如 5 表示降权旧数据场景） |
| `control_function` | int | 调控函数类型，来自规则维度表，标识具体的流量干预方式 |
| `value_type` | int | 值类型，来自规则维度表，标识调控值的表达形式 |
| `selection_type` | int | 选品类型，来自规则维度表，标识商品加入商品组的方式 |
| `is_individual_value` | int | 是否为个体化取值，来自规则维度表（0/1） |
| `scenes` | string | 调控生效场景列表（JSON 数组字符串），已标准化为英文名称：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`、`Shop`；原始枚举值（如 `search`、`dd`、`ymal` 等）映射处理，未识别值转为空字符串 |
| `item_group_target` | string | 商品组调控目标值，对应源表 `target` 字段 |

---

### 维度：实验分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_test_ids` | string | 实验组 ID 列表，来自规则维度表，标识该规则所属的实验处理组 |
| `exp_base_ids` | string | 对照组 ID 列表，来自规则维度表，标识该规则所属的实验对照组 |

---

### 指标：状态标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `task_status` | int | 调控任务当前状态码 |
| `item_group_if_ongoing` | int | 商品组是否仍在有效调控中（1=进行中，0=已失效）；当 `target_group=3` 且规则 `value_type=2` 且规则 `state=5` 时置为 0，否则为 1 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定 `grass_region`**：该字段为第一分区键，缺失将导致全区扫描，严重影响性能。
- **必须指定 `regional_date` 和 `regional_hour`**（或 `local_date` 和 `local_hour`）：本表为小时级快照，每小时均有独立分区，未指定时间分区将扫描全量历史数据。
- 推荐写法示例：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2024-06-01'
    AND regional_hour = 10
  ```

### 不可直接 SUM 的字段

- `item_group_if_ongoing`：状态标识位（0/1），跨小时聚合无业务意义，需结合时间分区过滤后使用。
- `scenes`：JSON 数组字符串，聚合前需先展开（`LATERAL VIEW explode`）再统计。
- `exp_test_ids` / `exp_base_ids`：字符串列表类型，不可直接聚合，需先解析。

### 时效性说明

- 本表为**小时级快照表**（`_hi` 后缀），每小时 INSERT OVERWRITE 覆盖对应分区。
- 上游源表 `szci_traffic.traffic_active_control_task_item_dump_h` **仅保留 7 天数据**，因此本表**不支持回溯超过 7 天**的历史重刷。
- ETL 写入时会自动寻找当前最大可用分区（兼容轻微延迟），但不保证与调度时间严格对齐，使用时注意数据时效。
- `local_date` / `local_hour` 为本地时区转换结果，跨时区分析请注意与 `regional_date` / `regional_hour` 的差异。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `szci_traffic.traffic_active_control_task_item_dump_h` | 主数据源，提供流量调控任务的商品维度明细（`item_id`、`shop_id`、`item_group_id`、`target_group`、`scenes`、`item_group_start_time`、`task_status`、`rule_id`、`target` 等字段） |
| `srdi_mart.dim_sr_data_warehouse_tc_rule` | 规则维度表，补充规则级属性（`exp_test_ids`、`exp_base_ids`、`value_type`、`selection_type`、`target_type`、`control_function`、`is_individual_value`、`state`、`rule_start_time`、`rule_end_time`） |

---

## ETL 逻辑摘要

### 数据流

```
szci_traffic.traffic_active_control_task_item_dump_h  (主事实流水)
        │
        │  LEFT JOIN（on rule_id）
        │
srdi_mart.dim_sr_data_warehouse_tc_rule              (规则维度快照)
        │
        ▼
srdi_mart.dwd_sr_data_warehouse_tc_item_group_hi     (INSERT OVERWRITE，小时分区)
```

### 关键步骤

**Step 1 — 创建规则维度临时视图**

```sql
CREATE TEMPORARY VIEW rule_data_<grass_region> AS
SELECT rule_id, state, exp_test_ids, exp_base_ids,
       value_type, selection_type, target_type,
       control_function, is_individual_value
FROM srdi_mart.dim_sr_data_warehouse_tc_rule
WHERE grass_region IN (${grass_region})
  AND regional_date = ${regional_date}
  AND regional_hour = ${regional_hour};
```

从规则维度表抽取当前小时对应分区的规则属性，供后续 JOIN 使用。

**Step 2 — 计算最大可用分区**

```sql
SET max_regional_date_hour_<grass_region> = (
    SELECT max(time_str) FROM (
        SELECT concat(grass_date,'_', ...) AS time_str
        FROM szci_traffic.traffic_active_control_task_item_dump_h
        WHERE grass_region IN (${grass_region})
          AND grass_date BETWEEN date_sub(${regional_date},1) AND ${regional_date}
        GROUP BY grass_date, hour
    ) a
    WHERE time_str <= concat(${regional_date},'_',${regional_hour})
);
```

查找上游表中不超过目标调度时间的最大可用 `grass_date + hour` 组合，兼容上游数据轻微延迟或回溯场景。

**Step 3 — INSERT OVERWRITE 写入目标分区**

- 从 `traffic_active_control_task_item_dump_h` 读取 Step 2 确定分区的数据；
- LEFT JOIN Step 1 临时视图，补充规则级维度字段；
- `item_group_id`：当 `target_type=5` 时替换为 `rule_id` 字符串（降权旧数据兜底逻辑）；
- `scenes`：对原始场景数组执行 `transform` + `array_distinct` + `to_json`，将内部枚举值映射为标准英文标签；
- `item_group_if_ongoing`：复合条件派生（`target_group=3 AND value_type=2 AND state=5` → 0，否则 1）；
- `local_date` / `local_hour`：通过 `date_timezone_convert` 将 SG 区域时间转换为目标草区本地时区；
- 写入分区：`grass_region`（静态）、`local_date`、`local_hour`、`regional_date`、`regional_hour`（动态）。

### 注意事项

- **单 Writer，无并发冲突**：`multi_writer=false`，同一分区不存在多文件并发写入风险。
- **上游数据保留窗口限制**：`traffic_active_control_task_item_dump_h` 仅保留 7 天，超出该窗口的历史分区无法重刷，需提前规划归档策略。
- **动态分区写入**：`local_date` 和 `local_hour` 由时区转换计算得出，极端情况下（跨日时区差）可能导致写入分区与 `regional_date` 不一致，查询时建议优先使用 `regional_date` / `regional_hour` 作为主过滤条件。
- **scenes 字段枚举映射不完整**：原始值若不在已定义枚举集合内，将映射为空字符串并保留在数组中，使用前建议过滤空值。
- **LEFT JOIN 可能引入 NULL**：若 `rule_id` 在规则维度表中无对应记录，所有来自 `rule_data` 的字段（`exp_test_ids`、`exp_base_ids` 等）将为 NULL，下游使用时需做判空处理。

---

*文档生成时间：2026-05-17*