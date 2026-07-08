<!-- ads-workspace-gdoc-sync: gdoc_id=1UNvwebEBD19orAqqHi2YG8H88UfDYGIsRTX0FSkLtcw gdoc_url=https://docs.google.com/document/d/1UNvwebEBD19orAqqHi2YG8H88UfDYGIsRTX0FSkLtcw/edit -->

# srdi_mart.dim_sr_data_warehouse_abtest_experiment

**分层**：DIM（维度层）
**主键**：`experiment_id`（联合 `layer_id`、`scene_id`、`regional_date` 唯一定位一条记录）
**分区**：`regional_date`（按日期分区，类型 date）
**更新频率**：每日全量覆盖写入（INSERT OVERWRITE）
**引用频次 / 访问频次**：203

---

## 业务描述

本表是搜推（SR）数据仓库 A/B 实验实验信息维度表，每日对实验快照进行全量刷新，沉淀各实验在特定日期下的静态属性与场景归属关系。

**核心业务场景**

- **实验元信息管理**：记录每个实验的所属项目、所在层（Layer）、所属场景（Scene），以及实验的生命周期（起止时间、状态）、模式、日志开关等配置属性。
- **RCMD 场景识别**：标记实验是否属于推荐（RCMD）普通场景或优先层（Priority Layer）场景，便于过滤非推荐体系的实验。
- **Bundle → Algo Tag 映射**：将实验配置的 bundle（参数 Tab 粒度、Layer 流量条件粒度、场景默认绑定粒度）统一转换为对应的算法标签（algo\_tag），支持多层次 bundle 来源的优先级合并。
- **场景差异度量**：通过 `scenarios_diff` 反映实验实际生效的 algo\_tag 相对于场景全量 algo\_tag 的覆盖差异，用于评估实验的流量精细化程度。

**适合回答的问题**

- 某实验（`experiment_id`）属于哪个项目/层/场景？当前状态如何？
- 某日期下，推荐体系中处于活跃状态的实验有哪些？
- 某实验生效的 algo\_tag 是通过哪种 bundle 来源（parameter\_tab / layer\_traffic\_condition / scene 默认）决定的？
- 某实验是否属于优先层场景，其实际覆盖的 algo\_tag 与场景全量 algo\_tag 的差距是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `regional_date` | date | 分区日期，对应数据所属的大区业务日期，每日全量覆盖 |

### 维度：实验标识与归属

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | 实验唯一 ID，来自 A/B 实验平台 experiment 表的主键 |
| `project_id` | bigint | 实验所属项目 ID |
| `layer_id` | bigint | 实验所在实验层（Layer）ID |
| `scene_id` | bigint | 实验所属场景 ID |
| `local_date` | date | 本地业务日期（对应上游 ODS 快照的 `grass_date`） |

### 维度：实验基本属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `start_time` | bigint | 实验开始时间（Unix 时间戳，毫秒） |
| `end_time` | bigint | 实验结束时间（Unix 时间戳，毫秒） |
| `experiment_status` | int | 实验状态码，来自实验平台（如草稿、运行中、已结束等） |
| `experiment_mode` | int | 实验模式，来自实验平台配置 |
| `log_switch` | int | 实验日志开关（0=关闭，1=开启） |
| `valid` | int | 实验有效性标记（1=有效，0=无效） |
| `creator` | string | 实验创建人 |
| `update_pic` | string | 实验最近更新负责人（PIC） |

### 维度：实验参数配置

| 字段 | 类型 | 说明 |
|---|---|---|
| `use_parameter_tabs` | int | 是否启用参数 Tab 配置（1=启用，0=未启用） |
| `parameter_tabs` | string | 实验参数 Tab 配置的原始 JSON 字符串，包含 `fmt_filter_expression` 等信息 |

### 维度：RCMD 场景归属标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_rcmd_normal_scene` | int | 是否属于 RCMD 普通场景（1=是，0=否）；由 `normal_scene` 临时视图 left join 命中结果派生 |
| `is_rcmd_priority_layer` | int | 是否属于 RCMD 优先层场景（1=是，0=否）；由 `priority_layer_related_scene` 临时视图 left join 命中结果派生 |

### 维度：Bundle 来源信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `parameter_tab_bundles` | array\<string\> | 从实验 parameter\_tabs JSON 中解析出的 bundle 列表（通过正则提取 `bundle == "..."` 的值并去重） |
| `layer_traffic_condition_bundles` | array\<string\> | 从 Layer 流量条件表达式（`fmt_filter_expression`）中解析出的 bundle 列表 |

### 维度：Bundle → Algo Tag 映射

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_bundle_algo_tag_map` | map\<string,string\> | 场景级别的 bundle → algo\_tag 映射；优先层场景取 `priority_layer_related_scene_algo_tag_map`，普通场景取 `normal_scene_bundle_algo_tag_map` |
| `parameter_tab_algo_tags` | array\<string\> | `parameter_tab_bundles` 中在 `scene_bundle_algo_tag_map` 有映射的 bundle 对应的 algo\_tag 列表 |
| `layer_traffic_condition_algo_tags` | array\<string\> | `layer_traffic_condition_bundles` 中在 `scene_bundle_algo_tag_map` 有映射的 bundle 对应的 algo\_tag 列表 |
| `scene_algo_tags` | array\<string\> | 场景所有 bundle 对应的 algo\_tag 列表（取 `scene_bundle_algo_tag_map` 所有 value） |
| `exp_algo_tags` | array\<string\> | 实验最终生效的 algo\_tag 列表；仅对 RCMD 场景（`is_rcmd_normal_scene=1` 或 `is_rcmd_priority_layer=1`）填充，按优先级：`parameter_tab_algo_tags` > `layer_traffic_condition_algo_tags` > `scene_algo_tags`；非 RCMD 场景为 null |
| `feature_names` | array\<string\> | 实验关联的特征名称列表（字段存在于 DataMap，ETL 中未显式计算，可能来自上游扩展或后续补充） |

### 指标：场景覆盖差异

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenarios_diff` | int | 实验生效 algo\_tag 数量与场景全量 algo\_tag 数量之差，反映实验流量精细化程度；计算逻辑：`size(scene_algo_tags) - size(实际生效的 algo_tags)`；非 RCMD 场景固定为 0 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须指定**：每次查询必须带上 `regional_date` 过滤条件，避免全表扫描：
  ```sql
  WHERE regional_date = '2026-05-17'
  ```
- 若需查询某一天的最新快照，直接使用该业务日期对应的分区即可；表为每日全量覆盖，无需额外去重。

### 不可直接 SUM 的字段

- `exp_algo_tags`、`parameter_tab_algo_tags`、`layer_traffic_condition_algo_tags`、`scene_algo_tags`、`feature_names` 均为 `array<string>` 类型，**不可直接聚合求和**，需配合 `EXPLODE` / `ARRAY_CONTAINS` / `SIZE` 等函数使用。
- `scene_bundle_algo_tag_map` 为 `map<string,string>` 类型，需使用 `MAP_KEYS`、`MAP_VALUES`、`ELEMENT_AT` 等函数访问。
- `scenarios_diff` 为派生差值指标，跨实验直接 SUM 无业务意义，应按业务语义选择 AVG 或分组统计。
- `start_time` / `end_time` 为 Unix 毫秒时间戳，直接比较前需转换为可读时间格式：`FROM_UNIXTIME(start_time / 1000)`。

### 时效性说明

- 本表为**每日全量快照**维度表，数据反映 `regional_date` 当天上游快照的状态。
- 历史分区数据一经写入即固定，支持回溯查询特定日期的实验配置。
- 上游实验平台表（`abtest.shopee_experiment_admin_db__experiment_tab__reg_continuous_s0_live`）为准实时表，本表每日 ETL 完成后方可获取当天最新状态，存在数小时延迟。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.ods_sr_data_warehouse_abtest_rcmd_scene_bundle_mapping` | RCMD 场景 bundle 映射关系快照，提供 scene\_id → bundle → algo\_tag 的基础映射，同时处理 mixrank 等特殊 cover\_scene 绑定逻辑 |
| `srdi_mart.ods_sr_data_warehouse_abtest_rcmd_scene_layer` | RCMD 场景与优先层的绑定关系快照，标识哪些场景属于优先层 |
| `srdi_mart.ods_sr_data_warehouse_priority_layer_relation_tab` | 优先层与关联场景的绑定关系快照，用于解析优先层场景实际绑定的 bundle → algo\_tag |
| `abtest.shopee_experiment_admin_db__experiment_tab__reg_continuous_s0_live` | A/B 实验平台实验主表（准实时），提供实验的核心元信息：ID、场景、层、项目、状态、时间、参数 Tab 等 |
| `srdi_mart.ods_sr_data_warehouse_experiment_layer_tab` | 实验层信息 ODS 快照表，提供 Layer 的流量条件（`fmt_filter_expression`），用于解析 `layer_traffic_condition_bundles` |

---

## ETL 逻辑摘要

### 数据流

```
ods_sr_data_warehouse_abtest_rcmd_scene_bundle_mapping
    └─► bundle_mapping (临时视图)
            └─► rcmd_scene_bundle_mapping (处理 cover_scene 特殊绑定)

ods_sr_data_warehouse_abtest_rcmd_scene_layer
    └─► rcmd_scene_layer (临时视图)
            ├─► normal_scene (普通场景 bundle→algo_tag map)
            └─► priority_layer_related_scene (优先层 bundle→algo_tag map)
                    └── 关联 ods_sr_data_warehouse_priority_layer_relation_tab

abtest.shopee_experiment_admin_db__experiment_tab__reg_continuous_s0_live
    └─► experiment_info (实验元信息 + parameter_tab_bundles 解析)

ods_sr_data_warehouse_experiment_layer_tab
    └─► layer_info (layer_traffic_condition_bundles 解析)

experiment_info + normal_scene + priority_layer_related_scene + layer_info
    └─► join_all_info (汇总所有 bundle 来源，派生 algo_tag 列表)
            └─► INSERT OVERWRITE dim_sr_data_warehouse_abtest_experiment
```

### 关键步骤

| 步骤 | Spark SQL Statement | 说明 |
|---|---|---|
| 1 | `CREATE TEMPORARY VIEW bundle_mapping` | 从 ODS bundle 映射表取当日最新 ingestion\_timestamp 快照，获取 scene\_id / bundle / algo\_tag / cover\_scene\_id |
| 2 | `CREATE TEMPORARY VIEW rcmd_scene_bundle_mapping` | 处理 cover\_scene 特殊逻辑（如 mixrank），将 cover\_scene\_id 指向的普通场景 bundle 合并到当前 scene，形成统一的 `bundle_algo_tag_struct` |
| 3 | `CREATE TEMPORARY VIEW rcmd_scene_layer` | 从 ODS 场景层关系表取当日快照，获取 scene\_id 与 priority\_layer\_id 的绑定关系 |
| 4 | `CREATE TEMPORARY VIEW normal_scene` | 筛选非优先层场景（`priority_layer_id IS NULL`），left join bundle 映射，聚合生成 `normal_scene_bundle_algo_tag_map` |
| 5 | `CREATE TEMPORARY VIEW priority_layer_related_scene` | 筛选优先层场景，通过 `ods_sr_data_warehouse_priority_layer_relation_tab` 获取关联 scene 的 bundle，聚合生成 `priority_layer_related_scene_algo_tag_map` |
| 6 | `CREATE TEMPORARY VIEW experiment_info` | 从实验平台准实时表读取实验元信息，正则解析 `parameter_tabs` JSON 提取 `parameter_tab_bundles` |
| 7 | `CREATE TEMPORARY VIEW layer_info` | 从 ODS layer 表取当日快照，正则解析 `fmt_filter_expression` 提取 `layer_traffic_condition_bundles` |
| 8 | `CREATE TEMPORARY VIEW join_all_info` | 将实验信息与 normal\_scene、priority\_layer\_related\_scene、layer\_info 四路 left join 合并，派生 `is_rcmd_normal_scene`、`is_rcmd_priority_layer`、`scene_bundle_algo_tag_map`，并通过 map 查找将 bundle 列表转换为 `parameter_tab_algo_tags`、`layer_traffic_condition_algo_tags`、`scene_algo_tags` |
| 9 | `INSERT OVERWRITE TABLE ... PARTITION(regional_date)` | 从 `join_all_info` 按优先级（parameter\_tab > layer\_traffic\_condition > scene）计算最终 `exp_algo_tags` 和 `scenarios_diff`，写入目标分区 |

### 注意事项

1. **ODS 快照一致性**：步骤 1、3 的 ODS 表通过 `ingestion_timestamp = MAX(ingestion_timestamp)` 取当日最新快照，若上游当日有多次 ingestion，以最后一次为准；step 5 的 `ods_sr_data_warehouse_priority_layer_relation_tab` 通过 `valid = 1` + `GROUP BY` 去重，防止重复关联记录干扰聚合。
2. **实验平台表非快照**：`abtest.shopee_experiment_admin_db__experiment_tab__reg_continuous_s0_live` 为准实时表，未做 ODS 快照，历史回刷时该表数据可能已发生变化，导致历史分区回刷结果与当时状态不一致；其余上游均已做 ODS 快照以保障回刷稳定性。
3. **非 RCMD 实验字段为 null/0**：`exp_algo_tags` 对非 RCMD 场景（`is_rcmd_normal_scene=0` 且 `is_rcmd_priority_layer=0`）固定为 null，`scenarios_diff` 固定为 0，下游使用时需注意过滤逻辑。
4. **feature\_names 字段**：该字段存在于 DataMap schema 中，但当前 ETL SQL 未显式写入，可能为后续扩展预留或由其他流程补充，查询时应注意可能为空。
5. **单写入文件**：本表仅由单个 ETL 文件驱动（`multi_writer=false`），无多写入竞争风险，但每次执行为全量 OVERWRITE，调度时需保障上游 ODS 数据已就绪。

---

*文档生成时间：2026-05-17*