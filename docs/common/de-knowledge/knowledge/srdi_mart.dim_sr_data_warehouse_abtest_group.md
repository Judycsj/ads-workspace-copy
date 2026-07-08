<!-- ads-workspace-gdoc-sync: gdoc_id=1Zej-Xxyp6SrYZ0n7KsNXHu95lcDdrFaFMGyZgZ4fVBM gdoc_url=https://docs.google.com/document/d/1Zej-Xxyp6SrYZ0n7KsNXHu95lcDdrFaFMGyZgZ4fVBM/edit -->

# srdi_mart.dim_sr_data_warehouse_abtest_group

**分层：** DIM（维度层）
**主键：** `exp_group_id`（实验分组 ID，取 end_time 最新一条去重）
**分区：** `local_date`（date 类型，按天分区）
**更新频率：** 每日一次（INSERT OVERWRITE 全量覆盖当天分区）
**引用频次 / 访问频次：** 5,229 次

---

## 业务描述

本表是搜推 A/B 实验平台的**实验分组（Group）维度表**，每日快照记录实验分组的完整属性信息，包括分组所属的实验、层、场景、项目层级结构，以及该分组在各业务场景下的白名单标记。

**核心业务场景：**

- 为搜推 A/B 实验分析提供分组维度标签，支持按实验分组下钻分析各项业务指标。
- 通过多层白名单标记（推荐、搜索、首页、广告等），快速筛选参与特定业务线实验的分组，减少下游重复计算。
- 记录分组有效期（`start_datetime` / `end_datetime`）及算法标签（`exp_algo_tags`），支持实验生命周期管理和算法归因。

**适合回答的问题：**

- 某实验分组属于哪个实验、哪个层、哪个场景、哪个项目？
- 某分组是否在推荐 / 搜索 / 首页 / 广告白名单中？
- 某分组关联的算法标签有哪些？
- 某分组的实验开始和结束时间是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `local_date` | date | 数据分区日期，每日全量覆盖写入，查询时必须指定 |

### 维度：实验分组标识与层级结构

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | 实验分组 ID，主键；当同一 group_id 存在多条记录时，取 end_time 最大（最新）的一条 |
| `exp_group_name` | string | 实验分组名称 |
| `experiment_id` | bigint | 分组所属实验 ID |
| `experiment_name` | string | 分组所属实验名称 |
| `layer_id` | bigint | 分组所属实验层 ID |
| `layer_name` | string | 分组所属实验层名称 |
| `scene_id` | bigint | 分组所属实验场景 ID |
| `scene_name` | string | 分组所属实验场景名称 |
| `project_id` | bigint | 分组所属项目 ID |
| `project_name` | string | 分组所属项目名称，`'MKP RCMD'` 表示商城推荐项目，会直接影响推荐白名单判断逻辑 |

### 维度：实验有效期

| 字段 | 类型 | 说明 |
|---|---|---|
| `start_datetime` | string | 实验分组生效开始时间，格式 `yyyy-MM-dd HH:mm:ss`；原始值为毫秒时间戳，`start_time <= 0` 时置为 null |
| `end_datetime` | string | 实验分组生效结束时间，格式 `yyyy-MM-dd HH:mm:ss`；原始值为毫秒时间戳，`end_time <= 0` 时置为 null |

### 维度：算法标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_algo_tags` | array\<string\> | 实验关联的算法标签列表，来源于 `dim_sr_data_warehouse_abtest_experiment`，通过 `experiment_id` 关联；无匹配时为 null |

### 维度：业务场景白名单标记

> 各白名单字段取值为 1（在白名单内）或 0（不在白名单内），通过 scene / layer / experiment 三级白名单配置的并集合并计算得出。

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_rcmd_whitelist` | bigint | 推荐白名单标记；`project_name = 'MKP RCMD'` 或 scene/layer/exp 任一层推荐白名单为 1 时置 1 |
| `is_search_whitelist` | bigint | 搜索白名单标记；scene/layer/exp 任一层搜索白名单为 1 时置 1 |
| `is_rcmd_search_whitelist` | bigint | 推荐或搜索白名单的并集标记；`is_rcmd_whitelist = 1` 或 `is_search_whitelist = 1` 时置 1，供推荐与搜索联合场景使用 |
| `is_homepage_whitelist` | bigint | 首页白名单标记；scene/layer/exp 任一层首页白名单为 1 时置 1 |
| `is_homepage_other_whitelist` | bigint | 首页其他白名单标记；scene/layer/exp 任一层对应白名单为 1 时置 1 |
| `is_rcmd_scene_whitelist` | bigint | 推荐场景级白名单标记（仅合并 scene 层和 project_name 判断，不含 layer/exp 层），专供部分下游推荐 A/B 实验表使用 |
| `is_ads_whitelist` | bigint | 广告白名单标记；scene/layer/exp 任一层广告白名单为 1 时置 1 |

---

## 查询使用须知

### 必须指定的过滤条件

- **`local_date`**：分区字段，查询时**必须**显式指定，否则将触发全表扫描，严重影响性能。示例：
  ```sql
  where local_date = '2024-01-01'
  ```
- 本表已按 `exp_group_id` + `end_time desc` 取 `row_number = 1` 去重，无需在查询侧再做去重处理。

### 不可直接 SUM / 聚合的字段

- **`exp_algo_tags`**：array 类型，不支持直接 SUM，需使用 `explode` 或 `array_contains` 展开或过滤。
- **`start_datetime` / `end_datetime`**：字符串类型时间，不可直接做数值加减，比较时需 `cast` 为 timestamp。
- **白名单标记字段**（`is_*_whitelist`）：布尔语义的 0/1 标记，用于过滤和 JOIN，SUM 求和在业务上无实际意义，应使用 `where` 或 `case when` 处理。

### 时效性说明

- 本表为**每日全量快照表**，`local_date` 分区对应当天快照数据。
- 白名单标记依赖 `dim_sr_data_warehouse_abtest_scene_layer_exp_whitelist` 同日分区，若上游白名单表当日数据缺失，对应分组白名单字段将全部置 0。
- 算法标签 `exp_algo_tags` 依赖 `dim_sr_data_warehouse_abtest_experiment` 同日分区，若上游实验表当日数据缺失，该字段将为 null。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `abtest.shopee_experiment_admin_db__group_dimension_tab__reg_continuous_s0_live` | 实验分组基础信息来源，提供分组 ID、名称、实验/层/场景/项目层级关系及开始/结束时间戳；按 `group_id` 取 end_time 最大的最新记录 |
| `srdi_mart.dim_sr_data_warehouse_abtest_experiment` | 提供实验维度的算法标签（`exp_algo_tags`），通过 `experiment_id` 关联 |
| `srdi_mart.dim_sr_data_warehouse_abtest_scene_layer_exp_whitelist` | 提供 scene / layer / experiment 三个粒度的各业务场景白名单配置，通过 `type` 字段区分；当日分区数据 |

---

## ETL 逻辑摘要

### 数据流

```
shopee_experiment_admin_db__group_dimension_tab（实时 live 表）
        │  去重取最新分组记录
        ▼
abtest_group（临时视图）
        │
        ├── LEFT JOIN abtest_experiment（临时视图，来自 dim_sr_data_warehouse_abtest_experiment）
        │       → 补充 exp_algo_tags
        │
        ├── LEFT JOIN abtest_scene_whitelist（临时视图，type='scene'）
        │       → 补充 scene 粒度白名单标记
        │
        ├── LEFT JOIN abtest_layer_exp_whitelist（临时视图，type='layer'）
        │       → 补充 layer 粒度白名单标记
        │
        └── LEFT JOIN abtest_exp_whitelist（临时视图，type='exp'）
                → 补充 experiment 粒度白名单标记
                │
                ▼
        INSERT OVERWRITE dim_sr_data_warehouse_abtest_group
        partition(local_date = ${local_date})
```

### 关键步骤

| 步骤 | 临时视图 / 操作 | 说明 |
|---|---|---|
| Step 1 | `abtest_group_${region}` | 从实验平台 live 表读取分组基础信息，使用 `row_number() over(partition by group_id order by end_time desc)` 取最新记录，毫秒时间戳转换为可读时间字符串 |
| Step 2 | `abtest_experiment_${region}` | 从 `dim_sr_data_warehouse_abtest_experiment` 读取当日 `regional_date` 分区的实验算法标签 |
| Step 3 | `abtest_scene_whitelist_${region}` | 从白名单表过滤 `type = 'scene'`，提取 scene 粒度各业务线白名单标记 |
| Step 4 | `abtest_layer_exp_whitelist_${region}` | 从白名单表过滤 `type = 'layer'`，提取 layer 粒度各业务线白名单标记 |
| Step 5 | `abtest_exp_whitelist_${region}` | 从白名单表过滤 `type = 'exp'`，提取 experiment 粒度各业务线白名单标记 |
| Step 6 | `INSERT OVERWRITE` | 以 t1（分组基础）为主表，依次 LEFT JOIN t2~t5，合并算法标签，并通过 `CASE WHEN` 对 scene/layer/exp 三层白名单取并集，计算最终各白名单标记，全量覆盖写入目标表当日分区 |

### 注意事项

1. **单 writer、无并发冲突**：本表仅有 1 个 ETL 文件写入（`multi_writer = false`），不存在多 writer 分区覆盖竞争问题。
2. **INSERT OVERWRITE 全量覆盖**：每次运行对目标分区全量重写，若上游数据异常（如白名单表缺数、实验表缺数），对应字段将降级为 0 或 null，**不会保留上一日的历史值**。
3. **白名单三级合并逻辑**：`is_rcmd_whitelist`、`is_search_whitelist` 等字段是 scene / layer / experiment 三个维度白名单的**逻辑 OR 合并**；`is_rcmd_scene_whitelist` 例外，仅合并 scene 层和 `project_name` 判断，不包含 layer/exp 层，专供特定下游推荐 A/B 表使用，**与 `is_rcmd_whitelist` 语义不同，不可混用**。
4. **参数化 region 后缀**：临时视图名称含 `${grass_region_without_quote}` 参数，表明该 ETL 支持多地区部署，同一逻辑按 region 参数独立运行，分区写入不同地区数据。
5. **分区键类型对齐**：上游 `dim_sr_data_warehouse_abtest_experiment` 使用 `regional_date`，上游白名单表使用 `local_date`，目标表使用 `local_date`，下游查询时应统一使用 `local_date` 过滤。

---

*文档生成时间：2026-05-17*