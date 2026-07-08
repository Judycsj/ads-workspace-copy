<!-- ads-workspace-gdoc-sync: gdoc_id=19SJQVsMLC_xOo6kGkaxRqq577a7iQMPL9boJ7r15Xjs gdoc_url=https://docs.google.com/document/d/19SJQVsMLC_xOo6kGkaxRqq577a7iQMPL9boJ7r15Xjs/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_explode_queues_level_diversity_1d

**分层：** DWS（数据汇总层）
**主键：** `scene_type` + `card_type` + `exp_group_id` + `recall_queue` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）, `local_date`（业务日期）
**更新频率：** 每日全量覆盖（`INSERT OVERWRITE`）
**访问频次：** 733 次

---

## 业务描述

本表服务于搜推平台（SR Data Warehouse Platform）的**实验组多样性分析**场景。其核心目标是：在 A/B 实验框架下，按实验组、召回队列（recall queue）、卡片类型、业务场景，汇总每日曝光量、曝光用户数及 LLM 类目多样性指标，用以衡量不同召回策略在各实验组中的内容覆盖广度与多样性表现。

**覆盖业务场景：**
- **Daily Discover (DD)**：首页每日发现主场景（scene_id = 142）
- **Post Purchase Rcmd (PP)**：购后推荐场景（scene_id = 368）

**适合回答的典型问题：**
1. 某实验组相较于对照组，各召回队列的曝光量与触达用户数有何差异？
2. 各召回队列在实验组维度下的 LLM 类目多样性（`imp_llm_cat_cnt`）如何，是否优于随机基线？
3. 不同卡片类型（含/不含广告）在特定场景下的召回队列表现对比？
4. 随机队列基线指标（`*_random`）与实际 explode 队列指标的差距分析，用于评估多样性增益。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 US、SG 等，用于分区隔离各地区数据 |
| `local_date` | date | 业务日期（本地时间），每日一分区 |

### 维度：实验与场景标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验分组 ID，来源于 `dim_sr_data_warehouse_abtest_user_group`，用于区分实验组与对照组 |
| `scene_type` | string | 业务场景类型：`DD`（Daily Discover / 首页每日发现）或 `PP`（Post Purchase Rcmd / 购后推荐） |
| `card_type` | string | 卡片聚合类型：`Aggregated Organic Item`（仅自然流量 item）或 `Aggregated Item`（含广告的全量 item） |
| `recall_queue` | string | 召回队列名称。`explode_queue` 指标通过对用户命中的队列数组展开（`LATERAL VIEW EXPLODE`）得到，覆盖用户实际经过的全部召回队列；`random_queue` 基线则为每用户随机抽取一条队列（`shuffle(queues)[0]`） |

### 指标：Explode 队列曝光指标（实际归因）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 按 explode 队列归因后的曝光总次数（`omni_scenario_imp_cnt` 求和），每个用户的曝光量按其所属全部队列重复计入 |
| `imp_uu` | bigint | 按 explode 队列归因后产生曝光的去重用户数（`COUNT DISTINCT user_id WHERE has_imp=true`） |
| `imp_llm_cat_cnt` | bigint | 按 explode 队列归因后，各用户曝光 LLM 类目去重数的汇总求和（`SUM(imp_llm_cat_count_per_uu)`），反映召回队列维度的内容多样性 |

### 指标：Random 队列曝光基线指标（随机对照）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_random` | bigint | 随机单队列基线的曝光总次数；每用户仅随机取一条队列（`shuffle(queues)[0]`）后汇总，`NULL` 时填 0 |
| `imp_uu_random` | bigint | 随机单队列基线的去重曝光用户数，`NULL` 时填 0 |
| `imp_llm_cat_cnt_random` | bigint | 随机单队列基线下各用户 LLM 类目去重数的汇总求和，用于与 `imp_llm_cat_cnt` 对比评估多样性增益，`NULL` 时填 0 |

---

## 查询使用须知

### 必须包含的过滤条件

- **务必同时指定 `grass_region` 和 `local_date`**，两者均为物理分区键，缺失任一均会触发全表扫描，造成严重性能问题。
  ```sql
  WHERE grass_region = 'US'
    AND local_date = '2024-01-01'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu` | 去重用户数，跨 `recall_queue` 或 `card_type` 直接相加会重复计数同一用户（同一用户可能命中多个队列） |
| `imp_uu_random` | 同上，去重用户数，不可跨维度直接累加 |
| `imp_llm_cat_cnt` | 为各用户 LLM 类目去重数的 SUM，跨维度汇总时需注意分母口径一致性，不等同于全局去重类目数 |
| `imp_llm_cat_cnt_random` | 同上 |

> **特别注意：** `imp_cnt` / `imp_cnt_random` 由于 EXPLODE 展开，同一曝光事件会按命中队列数重复计入，跨队列对 `imp_cnt` 做 SUM 存在重复计算风险，**不代表真实总曝光量**，只适合在固定 `recall_queue` 维度下做横向对比。

### 时效性说明

- 本表为 **`_1d` 日粒度表**，每日 T+1 全量覆盖目标分区，通常反映前一个自然日数据。
- 无历史累计（无 `_td`）或滑动窗口（无 `_nd`）逻辑，每个 `local_date` 分区仅代表当日数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取用户实验分组信息（`user_id` → `exp_group_id`），筛选 scene_id 142/368 的分配日志 |
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 获取用户-商品维度的曝光事件，含场景标签、召回队列、LLM 类目 ID、曝光次数等原始明细 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──→ user_exp（实验分组）
                                                         ↓
dwm_sr_data_warehouse_platform_user_item ──→ user_item_raw（曝光明细过滤）
                                              ↓
                                         user_cluster_agg（用户-队列-类目聚合）
                                              ↓
                                         user_cluster_exp（JOIN 实验分组）
                                           ↙              ↘
                          user_level_explode_queue    user_level_random_queue
                          （EXPLODE 全量队列展开）       （随机抽取单队列基线）
                                ↓                           ↓
                        explode_queue_metrics         random_queue_metrics
                                 ↘                   ↙
                              LEFT JOIN（on scene_type + card_type + exp_group_id + recall_queue）
                                          ↓
                     INSERT OVERWRITE 目标表（按 grass_region + local_date 分区）
```

### 关键步骤

1. **`user_exp`（Temporary View）**
   从 A/B 实验用户分组表中筛选指定 `grass_region`、`local_date`、已分配（`is_assignment_log=1`）、且属于 DD 或 PP 场景（scene_id 142/368）的用户及其实验分组 ID。

2. **`user_item_raw`（Temporary View）**
   从用户-商品曝光明细表中过滤：仅保留 DD / PP 场景标签的曝光事件，且卡片类型为 `item` 或 `item_mix_feed_card`，队列不为空，曝光次数 > 0，有效用户（`user_id > 0`）。将场景标签转换为 `DD`/`PP` 枚举值，队列字段去重切分为数组。

3. **`user_cluster_agg`（Temporary View）**
   对 `user_item_raw` 按 `user_id + scene_type + queues + item_llm_cluster_id + is_ads` 分组聚合曝光次数，消除商品级别的重复。

4. **`user_cluster_exp`（Temporary View）**
   将 `user_cluster_agg` 与 `user_exp` INNER JOIN，筛选出参与实验的用户，附加 `exp_group_id`。

5. **`user_level_explode_queue`（Temporary View）**
   对 `user_cluster_exp` 中的队列数组做 `LATERAL VIEW EXPLODE`，每个用户的每条队列生成独立行；分别对 `Aggregated Organic Item`（排除广告）和 `Aggregated Item`（全量）两种卡片类型聚合，计算用户级曝光量（`omni_scenario_imp_cnt`）、是否有曝光（`has_imp`）及 LLM 类目去重数。

6. **`user_level_random_queue`（Temporary View）**
   构建随机基线：对每用户队列数组随机打乱后取第一个队列（`shuffle(queues)[0]`），同样区分两种卡片类型聚合，计算对应用户级指标。

7. **`explode_queue_metrics`（Temporary View）**
   对 `user_level_explode_queue` 按 `scene_type + card_type + exp_group_id + recall_queue` 聚合，得到 `imp_cnt`、`imp_uu`、`imp_llm_cat_cnt`。

8. **`random_queue_metrics`（Temporary View）**
   对 `user_level_random_queue` 按相同维度聚合，得到 `imp_cnt_random`、`imp_uu_random`、`imp_llm_cat_cnt_random`。

9. **`INSERT OVERWRITE`（目标表写入）**
   以 `explode_queue_metrics` 为主表，LEFT JOIN `random_queue_metrics`（随机基线可能无对应 recall_queue 组合），`NULL` 值用 `COALESCE` 补 0，写入目标表对应 `grass_region` + `local_date` 分区。

### 注意事项

- **单 Writer 无并发冲突：** 本表仅有一个 ETL 文件写入（`multi_writer = false`），无多路写入风险。
- **EXPLODE 导致曝光量放大：** 由于对队列数组做了展开，同一曝光事件会被计入用户命中的每一条召回队列，`imp_cnt` 跨队列求和远大于真实总曝光量，使用时须在 `recall_queue` 维度固定后再做对比，切勿对所有队列的 `imp_cnt` 直接累加解读为总量。
- **随机基线覆盖不完整：** `random_queue_metrics` 使用 `shuffle` 随机抽取单队列，其 `recall_queue` 组合不一定覆盖 `explode_queue_metrics` 的全部组合，LEFT JOIN 后 `*_random` 字段可能为 0（已 COALESCE 处理）。
- **`shuffle` 不确定性：** `shuffle(queues)[0]` 每次执行结果不同，随机基线指标在重跑时存在轻微波动，属预期设计。
- **场景标签过滤：** `scene_type` 枚举逻辑硬编码于 `user_item_raw`（基于 `scenario_tags` 数组内容匹配），上游场景标签规则变更时需同步评估 ETL 影响。

---

*文档生成时间：2026-05-17*