<!-- ads-workspace-gdoc-sync: gdoc_id=17kwH2zrvgIjhjvA6b-lykXW90wLam5o5ro0QaH7Zz8Q gdoc_url=https://docs.google.com/document/d/17kwH2zrvgIjhjvA6b-lykXW90wLam5o5ro0QaH7Zz8Q/edit -->

# srdi_mart.dim_sr_data_warehouse_tc_exp_rule

**分层：** dim（维度层）
**主键：** `exp_group_id`（实验分组 ID）
**分区：** `regional_date`（按日期分区）
**更新频率：** 每日全量覆写（INSERT OVERWRITE）
**访问频次：** 485 次

---

## 业务描述

本表为搜推数仓（SR Data Warehouse）流量控制实验（Traffic Control，TC）的维度表，用于描述 **A/B 实验分组与实验规则的映射关系**。

核心业务场景：
- 记录各实验分组（Experiment Group）的分组类型（实验组、对照组、全局对照组）以及该分组所关联的所有规则 ID 集合。
- 支持实验分析时快速定位某个实验分组属于何种实验角色（treatment / control / global control），以及该分组覆盖哪些流量规则。

适合回答的问题举例：
- 某实验分组（`exp_group_id`）是实验组还是对照组？
- 某实验分组在某日绑定了哪些流量规则（`rule_ids`）？
- 哪些实验分组归属于全局对照组（`exp_group_type = 3`）？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `regional_date` | date | 数据日期分区，表示该记录所属的业务日期，每次按日全量覆写 |

### 维度：实验分组信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | 实验分组 ID（`abtest_group_id`），来源于流量管理系统中的 Layer 配置，唯一标识一个实验分组 |
| `exp_group_type` | int | 实验分组类型。枚举值：`1` = GROUP_TYPE_TREATMENT（实验组）；`2` = GROUP_TYPE_CONTROL（对照组）；`3` = GLOBAL_GROUP_CONTROL（全局对照组）。当 `layer_type` 为 3 或 4 时直接使用 `layer_type` 作为分组类型，否则取 JSON 字段中的 `type` 值 |
| `rule_ids` | string | 该实验分组关联的所有规则 ID 集合，以英文逗号分隔（如 `"101,205,308"`）。来源于流量规则表中与该分组绑定的规则；若该分组无对应规则，则该字段为 null |

---

## 查询使用须知

**必须包含的过滤条件：**
- 查询时**必须指定 `regional_date`** 分区，避免全表扫描。例如：
  ```sql
  WHERE regional_date = '2024-01-01'
  ```
- 若需获取最新快照，使用最近可用日期，建议通过调度日期参数传入，不要使用 `MAX(regional_date)` 进行全分区扫描。

**不可直接聚合的字段：**
- `rule_ids` 是已经通过 `collect_set` + `concat_ws` 预聚合的字符串，存储的是规则 ID 的集合。**不可直接 SUM / COUNT，** 如需统计规则数量，需先使用 `split(rule_ids, ',')` 拆分后再做处理。

**时效性说明：**
- 本表为每日全量维度快照，每日覆写当天分区。数据反映调度日当天从上游实时数据源同步的最新状态，无历史累积，不同日期分区间数据可能存在差异（实验配置变更）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `szci_traffic.shopee_traffic_mangement_db__layer_tab__reg_continuous_s0_live` | 实验分层配置表，提供实验分组 ID（`abtest_group_id`）及分组类型（`type` / `layer_type`） |
| `szci_traffic.shopee_traffic_mangement_db__rule_tab__reg_continuous_s0_live` | 流量规则配置表，提供规则 ID（`id`）及规则下关联的实验分组信息（通过 `abtest.layers.groups` 嵌套 JSON 解析） |

---

## ETL 逻辑摘要

### 数据流

```
layer_tab (实验分层表)
    └─ 解析 abtest_groups JSON 数组
           └─ 提取 exp_group_id、exp_group_type
                  └─ temporary view: exp_type

rule_tab (流量规则表)
    └─ 解析 abtest.layers JSON 数组 → 获取 groups
           └─ 解析 groups JSON 数组 → 提取 rule_id + exp_group_id
                  └─ temporary view: rule_group
                         └─ 按 exp_group_id 聚合 rule_id 集合
                                └─ temporary view: exp_rule_ids

exp_type LEFT JOIN exp_rule_ids ON exp_group_id
    └─ INSERT OVERWRITE dim_sr_data_warehouse_tc_exp_rule PARTITION(regional_date)
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `exp_type` | 对 `layer_tab` 的 `abtest_groups` 字段做 JSON 数组展开（`explode` + `from_json`），提取每个实验分组的 `abtest_group_id` 作为 `exp_group_id`；分组类型优先取 `layer_type`（当值为 3 或 4 时），否则取 JSON 中的 `type` 字段 |
| Step 2 | `layers` | 对 `rule_tab` 的 `abtest` 字段解析 `layers` JSON 数组，展开后提取规则 ID（`id`）及每层的 `groups` JSON 字符串 |
| Step 3 | `rule_group` | 对 `layers` 中的 `groups` 字段再次做 JSON 数组展开，得到规则 ID 与实验分组 ID 的明细映射关系（rule_id × exp_group_id） |
| Step 4 | `exp_rule_ids` | 以 `exp_group_id` 为维度，通过 `collect_set(rule_id)` 去重聚合所有关联规则 ID，并用 `concat_ws(',', ...)` 拼接为逗号分隔的字符串 |
| Step 5 | INSERT OVERWRITE | 以 `exp_type` 为主表，左连接 `exp_rule_ids`，写入目标表的指定日期分区（`regional_date = ${local_date}`） |

### 注意事项

- **Multi-writer：** 本表仅有单个 ETL 文件写入，无多 writer 并发冲突风险。
- **分区写入：** 采用 `INSERT OVERWRITE ... PARTITION (regional_date = ${local_date})` 方式，每次调度仅覆写当日分区，不影响历史分区数据。
- **LEFT JOIN 导致 null：** 若某实验分组在规则表中无任何关联规则，`rule_ids` 字段将为 null，查询时需注意空值处理。
- **JSON 多层嵌套解析：** 上游数据为多层嵌套 JSON 结构，ETL 通过多次 `explode` + `from_json` + `get_json_object` 逐层解析，若上游 JSON 格式发生变更，可能导致字段解析失败或返回 null，需关注上游 schema 稳定性。
- **`exp_group_type` 优先级逻辑：** `layer_type in (3,4)` 时使用 `layer_type` 值覆盖 JSON 中的 `type`，需与业务方确认该优先级规则是否持续有效。

---

*文档生成时间：2026-05-17*