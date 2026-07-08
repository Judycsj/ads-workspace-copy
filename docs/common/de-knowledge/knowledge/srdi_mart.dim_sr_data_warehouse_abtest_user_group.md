<!-- ads-workspace-gdoc-sync: gdoc_id=1n1rZJY-oOfzjLIs7F6CMUTd1ubllNd7JMy2JxwC-ijE gdoc_url=https://docs.google.com/document/d/1n1rZJY-oOfzjLIs7F6CMUTd1ubllNd7JMy2JxwC-ijE/edit -->

# srdi_mart.dim_sr_data_warehouse_abtest_user_group

**分层：** DIM（维度层）
**主键：** `user_id` + `exp_group_id` + `grass_region` + `local_date`
**分区：** `grass_region`（地区）、`local_date`（本地日期）
**更新频率：** 每日全量覆写（INSERT OVERWRITE）
**引用频次 / 访问频次：** 39,947 次

---

## 业务描述

本表是搜推数仓（SRDI）A/B 实验用户分组维度表，记录每个用户（`user_id`）在每个实验分组（`exp_group_id`）下的命中情况及其关联的实验元数据。

**核心业务场景：**
- 分析某实验分组在特定日期、地区下的用户命中来源（流量埋点 / 分配日志 / 推荐服务）。
- 将用户行为数据与 A/B 实验分组打通，支持实验效果评估（搜索、推荐、广告、首页等各场景）。
- 提供白名单标记，用于过滤特定场景下的实验流量，如推荐、搜索、广告、首页等。
- 标识是否适合与下游维度表 JOIN（`is_dim_join`），辅助数据治理与分析准确性保障。

**适合回答的问题：**
- 某实验分组在某天、某地区有哪些用户命中？
- 某用户在特定日期参与了哪些推荐/搜索/广告实验？
- 某实验的流量来自流量埋点还是分配系统？是否由推荐服务产生？
- 哪些实验分组属于推荐白名单 / 搜索白名单 / 广告白名单？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区/站点标识，如 `SG`、`MY` 等，用于多地区数据分区隔离 |
| `local_date` | date | 本地日期，数据统计日期，格式 `YYYY-MM-DD` |

### 维度：用户与实验分组标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，来源流量 / 分配日志，仅保留 `user_id > 0` 的有效用户 |
| `exp_group_id` | bigint | 实验分组 ID，仅保留 `exp_group_id > 0` 的有效分组 |
| `experiment_id` | bigint | 实验 ID，由 `dim_sr_data_warehouse_abtest_group` 关联补充 |
| `scene_id` | bigint | 实验场景 ID，由实验分组维度表关联补充 |
| `layer_id` | bigint | 实验层 ID，由实验分组维度表关联补充 |
| `project_name` | string | 实验所属项目名称，由实验分组维度表关联补充 |
| `exp_algo_tags` | array\<string\> | 实验算法标签列表，由实验分组维度表关联补充 |

### 维度：用户命中来源标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_trffic_log` | bigint | 是否来自流量埋点日志（`dwm_sr_data_warehouse_abtest_traffic_user_group`），1 = 是，0 = 否 |
| `is_assignment_log` | bigint | 是否来自分配日志（`shopee_traffic_dws_abtest_hit_log_di` 或 `abtest_mart_dws_assignment_agg_1d`），1 = 是，0 = 否；三路数据源取 `max` 合并 |
| `is_rcmd_service` | bigint | 是否由推荐服务（`recommendation_mixer` 或 `recommend-bff`）产生的分配日志，1 = 是，0 = 否；仅从 `abtest_mart_dws_assignment_agg_1d` 中的 `servers` 字段推断 |
| `is_dim_join` | bigint | 是否适合与下游维度表 JOIN 的标记，1 = 适合，0 = 不适合；逻辑：来自分配日志且为广告白名单实验，或来自流量埋点且非广告实验（同时排除特定 `exp_group_id`：63960、63961、452746、453033） |

### 维度：实验场景白名单标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_rcmd_whitelist` | bigint | 是否属于推荐白名单实验分组，由实验分组维度表关联补充，1 = 是，0 = 否 |
| `is_search_whitelist` | bigint | 是否属于搜索白名单实验分组，由实验分组维度表关联补充，1 = 是，0 = 否 |
| `is_rcmd_search_whitelist` | bigint | 是否属于推荐搜索联合白名单实验分组，由实验分组维度表关联补充，1 = 是，0 = 否 |
| `is_homepage_whitelist` | bigint | 是否属于首页白名单实验分组，由实验分组维度表关联补充，1 = 是，0 = 否 |
| `is_homepage_other_whitelist` | bigint | 是否属于首页其他场景白名单实验分组，由实验分组维度表关联补充，1 = 是，0 = 否 |
| `is_rcmd_scene_whitelist` | bigint | 是否属于推荐场景白名单实验分组，由实验分组维度表关联补充，1 = 是，0 = 否 |
| `is_ads_whitelist` | bigint | 是否属于广告白名单实验分组，由实验分组维度表关联补充，1 = 是，0 = 否 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：本表每日全量覆写，查询时必须指定 `local_date`，否则将扫描所有历史分区，导致性能严重劣化。
- **`grass_region`**：本表按地区分区，查询时应明确指定目标地区，避免跨地区全量扫描。

```sql
-- 推荐写法示例
WHERE grass_region = 'SG'
  AND local_date = '2026-05-16'
```

### 不可直接聚合的字段说明

- **`is_trffic_log`、`is_assignment_log`、`is_rcmd_service`、`is_dim_join`、各 `is_*_whitelist` 字段**：均为 0/1 标记字段，对同一 `user_id` + `exp_group_id` 已在 ETL 内通过 `MAX` 聚合去重，在本表粒度上每行唯一，可直接用于 `SUM` 统计命中人数，但需注意同一用户可能命中多个实验分组，跨分组统计用户数时须先 `DISTINCT user_id`。
- **`exp_algo_tags`**：数组类型，不可直接聚合，需使用 `EXPLODE` 或数组函数展开后使用。
- 通过 LEFT JOIN 关联的实验维度字段（`experiment_id`、`scene_id`、`layer_id`、`project_name`、`exp_algo_tags`、各白名单标记）：若 `exp_group_id` 在维度表中不存在，这些字段将为 `NULL`，使用前需注意 `COALESCE` 或 `IS NOT NULL` 过滤。

### 时效性说明

- 本表为 **T+1 日更新**，每日生产，数据反映前一自然日的实验分组命中情况。
- 来源之一 `abtest_mart_dws_assignment_agg_1d` 已排除 `scene_id = 235` 的数据，查询时需知晓此过滤口径。
- 前端实验（来自 `shopee_traffic_dws_abtest_hit_log_di__reg_live`）在本表中 `is_rcmd_service` 固定为 0，DA 场景不使用前端实验，如需分析前端实验须单独处理。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_abtest_traffic_user_group` | 提供来自流量埋点的用户实验分组命中数据（`is_trffic_log=1`） |
| `traffic.shopee_traffic_dws_abtest_hit_log_di__reg_live` | 提供来自前端流量分配日志的用户实验分组命中数据（`is_assignment_log=1`，`is_rcmd_service` 固定为 0） |
| `abtest.abtest_mart_dws_assignment_agg_1d` | 提供来自后端 A/B 分配系统的用户实验分组命中数据，通过 `servers` 字段判断是否为推荐服务产生（`is_rcmd_service`） |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验分组维度表，关联补充实验元数据（`experiment_id`、`scene_id`、`layer_id`、`project_name`、`exp_algo_tags`）及各场景白名单标记 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_abtest_traffic_user_group  ┐
traffic.shopee_traffic_dws_abtest_hit_log_di__reg_live     ├─ UNION ALL → abtest_user_group_union_all（按 grass_region, user_id, exp_group_id 聚合）
abtest.abtest_mart_dws_assignment_agg_1d                   ┘
                                                                    │
                                                                    ↓ LEFT JOIN
srdi_mart.dim_sr_data_warehouse_abtest_group ──────────── abtest_exp_group（实验分组维度）
                                                                    │
                                                                    ↓
                              srdi_mart.dim_sr_data_warehouse_abtest_user_group（INSERT OVERWRITE）
```

### 关键步骤

**Step 1 — Temporary View `abtest_user_group_union_all_${grass_region_without_quote}`**

将三路用户实验分组来源通过 `UNION ALL` 合并，并按 `(grass_region, user_id, exp_group_id)` 分组，通过 `MAX` 聚合各来源标记：
- 来源一：`dwm_sr_data_warehouse_abtest_traffic_user_group`，打标 `is_trffic_log=1`。
- 来源二：`shopee_traffic_dws_abtest_hit_log_di__reg_live`（前端分配日志），打标 `is_assignment_log=1`，`is_rcmd_service=0`（硬编码）。
- 来源三：`abtest_mart_dws_assignment_agg_1d`（后端分配日志），打标 `is_assignment_log=1`，`is_rcmd_service` 由 `servers` 数组是否包含 `recommendation_mixer` 或 `recommend-bff` 决定；排除 `scene_id=235`。

**Step 2 — Temporary View `abtest_exp_group_${grass_region_without_quote}`**

从 `dim_sr_data_warehouse_abtest_group` 按当日 `local_date` 取出实验分组的完整维度信息，包括实验 ID、场景、层、项目名、算法标签及各场景白名单标记。

**Step 3 — INSERT OVERWRITE 写入目标表**

将 Step 1 的用户分组结果与 Step 2 的实验维度信息按 `exp_group_id` LEFT JOIN，并计算 `is_dim_join` 字段：
- `is_assignment_log=1` 且 `is_ads_whitelist=1`：标记为 1（广告白名单分配日志）。
- `is_trffic_log=1` 且 `is_ads_whitelist` 为 0 或 NULL，且 `exp_group_id` 不在排除列表（63960、63961、452746、453033）：标记为 1。
- 其余情况标记为 0。

最终按 `(grass_region, local_date)` 分区写入目标表。

### 注意事项

- **单一写入文件**：本表仅有一个 ETL 文件（`multi_writer=false`），无多路并发写入风险，分区安全。
- **参数化执行**：ETL SQL 使用 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 等运行时参数，实际执行时按地区和日期动态替换，每次运行覆写对应分区。
- **前端实验 `is_rcmd_service` 硬编码为 0**：来源二（前端分配日志）的 `is_rcmd_service` 直接写死为 0，这是业务上的主动决策（DA 侧不关注前端实验），并非数据缺失，修改前需评估影响。
- **排除特定 `exp_group_id`**：`is_dim_join` 计算中硬编码排除了 `exp_group_id IN (63960, 63961, 452746, 453033)`，这些分组为广告实验相关，维护时需关注是否需要更新此列表。
- **LEFT JOIN 导致维度字段可能为 NULL**：若 `exp_group_id` 在 `dim_sr_data_warehouse_abtest_group` 中无对应记录（维度表未覆盖），则 `experiment_id`、`scene_id` 等字段均为 NULL，下游使用时需注意过滤或 `COALESCE` 处理。

---

*文档生成时间：2026-05-17*