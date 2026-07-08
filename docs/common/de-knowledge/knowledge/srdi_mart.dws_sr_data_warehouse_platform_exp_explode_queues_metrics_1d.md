<!-- ads-workspace-gdoc-sync: gdoc_id=1KkfJIsjv6lUS4Bmo7c_89XIkOk9rVU0QncjMdTHFCRg gdoc_url=https://docs.google.com/document/d/1KkfJIsjv6lUS4Bmo7c_89XIkOk9rVU0QncjMdTHFCRg/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_explode_queues_metrics_1d

**分层:** DWS（数据汇总层）
**主键:** `grass_region` + `local_date` + `exp_type` + `exp_group_id` + `recall_queue` + `scenario_tag`
**分区:** `grass_region` / `local_date` / `exp_type`
**更新频率:** 每日（T+1）
**引用频次/访问频次:** 788

---

## 业务描述

本表为搜索推荐（SR）数据仓库平台的实验召回队列（Recall Queue）日粒度汇总宽表，服务于 A/B 实验效果评估场景。

核心业务场景：
- **实验组 × 召回队列的多维度指标下钻**：将每个实验组（`exp_group_id`）的流量，按召回队列（`recall_queue`）和业务场景（`scenario_tag`）展开，便于逐队列分析其曝光、点击、转化及 GMV 贡献。
- **召回队列独占性分析**：通过 `queue_exclusive_*` 系列指标，识别某条召回队列独自覆盖（即该商品仅由该队列召回）的流量与转化质量，评估队列的不可替代性。
- **多实验类型对比**：通过分区字段 `exp_type` 区分不同实验归因方式（`traffic` 基于曝光流量归因、`assign_log_join` 基于用户分配日志关联），支持多维实验分析。

适合回答的典型问题：
- 某实验组中，哪条召回队列的点击率/GMV 贡献最高？
- 某召回队列在特定业务场景下的独占曝光比例是多少？
- 不同召回策略在新用户（New Arrival）场景下的转化效果如何？
- 相同实验组在 `traffic` 和 `assign_log_join` 两种归因口径下，指标是否存在显著差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区，如 `SG`、`MY`、`TH` 等，每次写入针对单一 region |
| `local_date` | date | 数据日期（本地时区），格式 `yyyy-MM-dd` |
| `exp_type` | string | 实验归因类型：`traffic`（基于曝光流量归因）或 `assign_log_join`（基于用户实验分配日志关联，当前主要用于 New Arrival 场景） |

### 维度：实验与场景标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验组 ID，来源于实验平台白名单或用户分配日志；`exp_type=traffic` 时通过 `exp_group_ids` 数组 explode 展开，`exp_type=assign_log_join` 时通过用户维度 join 获取 |
| `recall_queue` | string | 召回队列名称，由商品曝光时的 `queues` 字段（逗号分隔）explode 展开，每行代表一个独立队列 |
| `scenario_tag` | string | 业务场景标签，由 `scenario_tags` 数组 explode 展开，限定于推荐场景白名单，如 `DA_Daily Discover`、`DA_You May Also Like`、`DA_Cart_Unify`、`dpm mapping group New Arrival`（仅 `assign_log_join` 类型包含） 等 |

### 指标：总量行为指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_cnt` | bigint | 该队列下的去重商品数（`COUNT(DISTINCT item_id)`），**不可直接 SUM 跨队列汇总**（同一商品可能属于多个队列） |
| `imp_cnt` | bigint | 曝光次数之和 |
| `click_cnt` | bigint | 点击次数之和 |
| `ppv_cnt` | bigint | 商品详情页访问次数之和（已过滤 `is_back=true` 的返回行为，仅计正向 PPV） |
| `cart_cnt` | double | 加购次数之和 |
| `order_cnt` | double | 下单次数之和 |
| `gmv` | double | 成交总额（本地货币，原始 GMV） |
| `pc2_gmv` | double | PC2 口径 GMV（付款确认 2 阶段 GMV，具体口径以上游 `dwm_sr_data_warehouse_platform_user_item` 定义为准） |
| `avg_imp_price_usd` | double | 曝光商品的加权平均价格（USD），计算公式为 `SUM(avg_imp_price_usd × imp_cnt) / SUM(imp_cnt)`，`avg_imp_price_usd` 为空时使用商品维表中的 `price_usd` 兜底，**属于加权均值，不可直接 SUM** |

### 指标：队列独占性指标

> 独占（exclusive）定义：某条商品在当次曝光中仅由唯一一条召回队列召回（即 `queues` 字段仅包含一个队列，`is_exclusive=1`）。

| 字段 | 类型 | 说明 |
|---|---|---|
| `queue_exclusive_item_cnt` | double | 该队列独占召回的去重商品数（`COUNT(DISTINCT item_id) WHERE is_exclusive=1`），**不可直接 SUM 跨队列汇总** |
| `queue_exclusive_imp_cnt` | double | 该队列独占召回的曝光次数之和 |
| `queue_exclusive_click_cnt` | double | 该队列独占召回的点击次数之和 |
| `queue_exclusive_ppv_cnt` | double | 该队列独占召回的 PPV 次数之和 |
| `queue_exclusive_cart_cnt` | double | 该队列独占召回的加购次数之和 |
| `queue_exclusive_order_cnt` | double | 该队列独占召回的下单次数之和 |
| `queue_exclusive_gmv` | double | 该队列独占召回的 GMV 之和 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则会触发全分区扫描，严重影响性能。
- **`local_date`**：必须指定，推荐使用等值过滤或短范围过滤（如最近 7 天）。
- **`exp_type`**：建议明确指定；`traffic` 与 `assign_log_join` 是两套完全独立的归因口径，混用会导致数据重复计算。示例：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-05-16'
    AND exp_type = 'traffic'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `avg_imp_price_usd` | 加权均值，跨行 SUM 无业务意义；如需汇总，须用 `SUM(avg_imp_price_usd × imp_cnt) / SUM(imp_cnt)` 重新计算 |
| `item_cnt` | 去重商品数（`COUNT DISTINCT`），同一商品在多个 `recall_queue` 行中均被计入，跨队列 SUM 存在重复计算 |
| `queue_exclusive_item_cnt` | 同上，去重商品数，不可跨行 SUM |

### 时效性说明

- 本表为 **T+1 日粒度**（`_1d` 后缀）快照表，每天全量覆写对应分区（`INSERT OVERWRITE`）。
- `exp_type = 'assign_log_join'` 分区由独立 ETL Job 写入，与 `exp_type = 'traffic'` 分区并行调度，二者无依赖关系，上线时间可能存在分钟级差异。
- `exp_type = 'traffic'` 分区存在两个 ETL Job（`traffic` 全量版与 `less_exp` 精简版）同时写入，**两个 Job 均为 `INSERT OVERWRITE` 同一分区**，存在写覆盖竞争风险（详见注意事项）。

### 其他注意事项

- `recall_queue` 是由 `queues` 字段 explode 展开后的单值，同一条曝光记录的多个队列会分拆成多行，因此 **跨 `recall_queue` 聚合时，非独占指标会重复计算**，应使用独占指标（`queue_exclusive_*`）或明确业务口径进行过滤。
- 当前 `less_exp` ETL 仅覆盖特定实验组 ID（`11716, 11717, 11718, 11719, 135119, 135120, 88521, 88522`），分析其他实验组时请以 `traffic` 全量版数据为准。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 核心行为明细源表，提供用户维度的曝光/点击/PPV/加购/下单等原始行为数据，含实验组 ID 数组、召回队列、场景标签等信息 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | A/B 实验组白名单维表，过滤推荐场景有效实验组（`exp_type=traffic` 使用） |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户实验分配日志维表，用于 New Arrival 等特定场景（`scene_id=678`）下通过用户 ID 关联实验组（`exp_type=assign_log_join` 使用） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，将本地货币价格（`avg_imp_price_local`）转换为 USD |
| `mp_item.dim_item__reg_s0_live` | 商品维表，提供 `price_usd` 作为 `avg_imp_price_usd` 为空时的兜底价格 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item  ──┐
dim_sr_data_warehouse_abtest_group        ──┤（traffic / less_exp）
dim_sr_data_warehouse_abtest_user_group   ──┤（assign_log_join）
dim_exchange_rate__reg_s0_live            ──┤──→ [多个 Temporary View] ──→ INSERT OVERWRITE (exp_type 分区)
dim_item__reg_s0_live                     ──┘
```

本表由 3 个独立 ETL 文件共同写入不同 `exp_type` 分区：

| ETL 文件 | 写入分区 `exp_type` | 说明 |
|---|---|---|
| 文件 1（主 traffic） | `traffic` | 全量实验组，通过白名单维表过滤 |
| 文件 2（assign_log_join） | `assign_log_join` | New Arrival 等特定场景，通过用户分配日志 join |
| 文件 3（less_exp） | `traffic` | 仅覆盖少量指定实验组 ID，为降低运行时长的精简版 |

### 关键步骤

以文件 1（`traffic` 全量版）为例，各 Statement 依次执行：

1. **`exp_filter`（临时视图）**：从实验组白名单维表读取推荐场景有效实验组 ID（`is_rcmd_scene_whitelist=1`）。
2. **`fx_rate`（临时视图）**：读取当日汇率，取 `FIRST` 值作为单一汇率系数。
3. **`dim_item_price`（临时视图）**：读取商品 USD 价格，作为兜底价格来源。
4. **`dwm_raw`（临时视图）**：从行为明细表过滤当日指定 region 的有效行为数据（`operation IN ('impression','click','ppv','cart','order')`），要求 `queues` 非空、`exp_group_ids` 非空、场景标签含 `DA_` 前缀，同时完成汇率换算（本地价格 → USD）和队列解析（`split`+`array_sort`+`array_distinct`），并标记是否独占（`is_exclusive`）。
5. **`dwm_user_exp_base`（临时视图）**：LEFT JOIN 商品价格维表补全 `avg_imp_price_usd`（空时兜底为 `price_usd`）；`item_id` 为 NULL 的行（约 0.6%）跳过 JOIN，直接 UNION ALL 合并，避免数据丢失。
6. **`dwm_user_exp`（临时视图）**：按 `(exp_group_ids, scenario_tags, queues, item_id, queue, is_exclusive)` 分组聚合，合并同一 item 的多次行为，同时以加权方式计算 `avg_imp_price_usd`。
7. **`dwm_explode_data`（临时视图）**：对 `exp_group_ids` 数组执行 `lateral view explode`，将实验组数组展开为单行，每个实验组 ID 独立一行。
8. **`dwm_filter_exp`（临时视图）**：INNER JOIN 白名单过滤，仅保留在推荐场景白名单内的实验组数据（`less_exp` 版本跳过此步骤，改为在上游直接硬编码过滤实验组 ID）。
9. **`dwm_filter_tag`（CACHE TABLE，DISK_ONLY）**：对 `scenario_tags` 数组执行 `lateral view explode`，展开后过滤保留白名单内的业务场景标签（8 个 `DA_` 场景，`assign_log_join` 版本额外含 `dpm mapping group New Arrival`）。结果缓存至磁盘供后续两个视图复用。
10. **`exclusive_data`（临时视图）**：基于缓存数据，按 `(exp_group_id, scenario_tag, queue)` 聚合，计算 `is_exclusive=1` 条件下的独占指标（`COUNT DISTINCT item_id` 及各行为 SUM）。
11. **`dws_queue_table`（临时视图）**：对 `queues` 数组执行 `lateral view explode`，将每条曝光记录按所有关联队列展开，按 `(exp_group_id, scenario_tag, recall_queue)` 聚合计算总量指标。
12. **`INSERT OVERWRITE`（写目标表）**：将 `dws_queue_table` LEFT JOIN `exclusive_data`，合并总量指标与独占指标，写入目标表对应 `exp_type` 分区，输出文件数限制为 2（`REPARTITION(2)`）。

`assign_log_join` 版本（文件 2）的差异：在步骤 4 之前，额外读取用户实验分配维表（`scene_id=678`），通过 INNER JOIN 用户 ID 来确定实验组归属，替代基于 `exp_group_ids` 数组的白名单过滤方式，其余步骤与文件 1 基本一致。

### 注意事项

1. **Multi-writer 写覆盖风险**：文件 1（`traffic` 全量版）与文件 3（`less_exp` 精简版）均向 `exp_type='traffic'` 分区执行 `INSERT OVERWRITE`。若两个 Job 并发执行，后完成的 Job 将覆盖先完成 Job 的数据；需在调度层确保两者串行执行或明确取舍，不可同时运行。
2. **`less_exp` 实验组范围限制**：文件 3 当前硬编码仅处理 8 个实验组 ID（源码注释标注于 2025-03-27 为降低运行时长的临时方案），后续若扩大实验范围需同步修改过滤条件并恢复白名单过滤逻辑。
3. **汇率精度**：`fx_rate` 使用 `FIRST(exchange_rate)` 取值，若源表存在多行则取到的汇率可能不确定，需关注上游汇率表数据质量。
4. **`avg_imp_price_usd` 兜底逻辑**：当行为数据中的曝光价格为空时，使用商品维表的当日 `price_usd` 兜底，两者可能存在时效性差异（曝光时价格 vs 当日结算价格），在价格敏感分析场景需注意。
5. **PPV 过滤**：`ppv_cnt` 在 ETL 中已过滤返回行为（`is_back=false`），与原始行为表中的 `ppv_cnt` 口径不同。
6. **分区写入方式**：所有 INSERT 均为 `INSERT OVERWRITE`，每次执行会全量覆写对应 `(grass_region, local_date, exp_type)` 三级分区，无增量追加逻辑。

---

*文档生成时间：2026-05-17*