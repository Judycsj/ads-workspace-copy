<!-- ads-workspace-gdoc-sync: gdoc_id=1xpb6mX5xkUgk4YlZoTeswXI8qjh6QmOawLi6lrFu96o gdoc_url=https://docs.google.com/document/d/1xpb6mX5xkUgk4YlZoTeswXI8qjh6QmOawLi6lrFu96o/edit -->

# srdi_mart.dim_sr_data_warehouse_abtest_scene_layer_exp_whitelist

**分层**：DIM（维度层）
**主键**：`type` + `scene_id` / `layer_id` / `experiment_id`（三者依 `type` 值互斥非空）
**分区**：`local_date`（日期分区）、`type`（实体类型分区，取值：`scene` / `layer` / `exp`）
**更新频率**：每日全量覆写（`INSERT OVERWRITE`）
**访问频次**：129 次

---

## 业务描述

本表是搜推数仓 A/B 测试白名单的**跨业务线汇总维度表**，将推荐（rcmd）、搜索（search）、首页（homepage）、首页其他（homepage_other）、广告（ads）五条业务线各自的白名单维度表整合为统一视图。

表以 `type` 分区区分实体粒度：

- **`type = 'scene'`**：以 `scene_id` 为主键，记录场景级白名单归属；
- **`type = 'layer'`**：以 `layer_id` 为主键，记录分层（Layer）级白名单归属；
- **`type = 'exp'`**：以 `experiment_id` 为主键，记录实验（Experiment）级白名单归属。

五个 `is_*_whitelist` 标志位标明该实体是否属于对应业务线的白名单，便于下游在单张表中完成跨业务线的白名单判断，无需分别 JOIN 多张原始白名单表。

**适合回答的典型问题**：
- 某个 `experiment_id` 是否同时属于推荐和搜索白名单？
- 某个 `scene_id` 属于哪些业务线的白名单？
- 某个 `layer_id` 是否在广告白名单中？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `local_date` | date | 数据日期分区，每日全量刷写，查询时必须显式指定 |
| `type` | string | 实体类型分区，枚举值：`scene`（场景）/ `layer`（分层）/ `exp`（实验） |

### 维度：实体标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_id` | bigint | 场景 ID；`type = 'scene'` 时有值，其余分区为 NULL |
| `layer_id` | bigint | 分层 ID；`type = 'layer'` 时有值，其余分区为 NULL |
| `experiment_id` | bigint | 实验 ID；`type = 'exp'` 时有值，其余分区为 NULL；搜索业务线的场景/分层白名单不含实验粒度，该字段可能为 NULL |

### 维度：业务线白名单标志

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_rcmd_whitelist` | bigint | 是否属于推荐（Rcmd）业务线白名单；1 = 是，0 = 否；取自推荐白名单表的 `max` 聚合结果 |
| `is_search_whitelist` | bigint | 是否属于搜索（Search）业务线白名单；1 = 是，0 = 否；搜索白名单仅有 scene/layer 粒度，exp 粒度恒为 0 |
| `is_homepage_whitelist` | bigint | 是否属于首页（Homepage）业务线白名单；1 = 是，0 = 否 |
| `is_homepage_other_whitelist` | bigint | 是否属于首页其他（Homepage Other）业务线白名单；1 = 是，0 = 否 |
| `is_ads_whitelist` | bigint | 是否属于广告（Ads）业务线白名单；1 = 是，0 = 否 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`local_date`**：必须显式指定，否则触发全分区扫描，例如：
   ```sql
   WHERE local_date = '2024-06-01'
   ```
2. **`type`**：建议同时指定，避免跨场景/分层/实验粒度的数据混用：
   ```sql
   WHERE local_date = '2024-06-01' AND type = 'exp'
   ```

### 不可直接 SUM 的字段

- `is_rcmd_whitelist`、`is_search_whitelist`、`is_homepage_whitelist`、`is_homepage_other_whitelist`、`is_ads_whitelist` 均为 **0/1 标志位**，在同一 `type` 分区内每行语义唯一，直接 `SUM` 具有统计意义（等同于计数），但**跨 `type` 分区混合 SUM 无业务意义**，应先按 `type` 过滤。

### 实体互斥性

- `scene_id`、`layer_id`、`experiment_id` 三列依 `type` 分区严格互斥：同一分区内仅对应字段有值，其余均为 NULL。跨 `type` JOIN 时注意 NULL 处理。

### 搜索白名单的特殊性

- 搜索业务线（`is_search_whitelist = 1`）的原始白名单表（`dim_sr_data_warehouse_search_scene_layer_whitelist`）不含 `experiment_id`，因此在 `type = 'exp'` 分区中搜索白名单数据不会出现。

### 时效性

- 本表为**日维度全量快照表**，每日 T+1 刷写，数据反映截至 `local_date` 当天的白名单配置状态，不具备实时性。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_rcmd_scene_layer_exp_whitelist` | 推荐业务线场景/分层/实验白名单，含 `scene_id`、`layer_id`、`experiment_id` |
| `srdi_mart.dim_sr_data_warehouse_search_scene_layer_whitelist` | 搜索业务线场景/分层白名单，不含实验粒度 |
| `srdi_mart.dim_sr_data_warehouse_homepage_scene_layer_exp_whitelist` | 首页业务线场景/分层/实验白名单 |
| `srdi_mart.dim_sr_data_warehouse_homepage_other_scene_layer_exp_whitelist` | 首页其他业务线场景/分层/实验白名单 |
| `srdi_mart.dim_sr_data_warehouse_ads_scene_layer_exp_whitelist` | 广告业务线场景/分层/实验白名单 |

---

## ETL 逻辑摘要

### 数据流

五张业务线白名单表 → `UNION ALL` 拼接为扁平宽表（含业务线标志位）→ 按 `scene_id` / `layer_id` / `experiment_id` 三个维度分别聚合并打 `type` 标签 → `INSERT OVERWRITE` 写入目标表按 `local_date` + `type` 双分区。

### 关键步骤

**Step 1 — Temporary View `abtest_whitelist_<region>`**

将五张业务线白名单表通过 `UNION ALL` 合并为统一的扁平结构，每条记录包含 `scene_id`、`layer_id`、`experiment_id` 以及五个互斥的业务线标志位（`is_rcmd` / `is_search` / `is_homepage` / `is_homepage_other` / `is_ads`），每张源表对应的标志位置 1，其余置 0。搜索白名单的 `experiment_id` 赋为 NULL。

**Step 2 — Temporary View `abtest_scene_layer_exp_whitelist_<region>`**

基于 Step 1 的结果，按三种粒度分别聚合并 `UNION ALL`：
- **scene 粒度**：`WHERE scene_id > 0 GROUP BY scene_id`，`layer_id` 和 `experiment_id` 置 NULL，`type = 'scene'`；
- **layer 粒度**：`WHERE layer_id > 0 GROUP BY layer_id`，`scene_id` 和 `experiment_id` 置 NULL，`type = 'layer'`；
- **exp 粒度**：`WHERE experiment_id > 0 GROUP BY experiment_id`，`scene_id` 和 `layer_id` 置 NULL，`type = 'exp'`。

五个业务线标志位均取 `MAX` 聚合，保证同一实体属于多条白名单记录时标志位取并集。

**Step 3 — INSERT OVERWRITE 写目标表**

从 Step 2 的临时视图中读取数据，字段重命名（`is_rcmd` → `is_rcmd_whitelist` 等），以 `local_date`（外部参数 `${local_date}`）和 `type`（动态分区）写入目标表，覆盖对应分区。

### 注意事项

- **单文件单写**：本表仅有 1 个 ETL 文件，无多写入方（`multi_writer = false`），分区写入风险较低。
- **动态分区**：`type` 为动态分区列，每次运行同时写入 `scene` / `layer` / `exp` 三个子分区，若任一业务线源表数据异常可能导致对应 `type` 分区数据缺失或清空，需关注源表数据完整性。
- **`scene_id > 0` / `layer_id > 0` / `experiment_id > 0` 过滤**：ETL 中对三个 ID 字段均有大于 0 的过滤，ID 为 NULL 或 0 的脏数据会被丢弃，不会写入目标表。
- **搜索白名单无 `experiment_id`**：搜索场景下实验粒度数据天然缺失，`type = 'exp'` 分区中 `is_search_whitelist` 恒为 0，下游使用时需注意。
- **区域参数化**：SQL 中使用 `${grass_region_without_quote}` 参数化临时视图名，支持多区域并行执行，临时视图彼此隔离，不影响最终写入。

---

*文档生成时间：2026-05-17*