<!-- ads-workspace-gdoc-sync: gdoc_id=1sgSiq2GLPMK2aHYIoHQw2cjn9p9KPwuP-QTkFjVz3BU gdoc_url=https://docs.google.com/document/d/1sgSiq2GLPMK2aHYIoHQw2cjn9p9KPwuP-QTkFjVz3BU/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_queue_level_metrics_1d

**分层**: DWS（数据服务层）
**主键**: `grass_region` + `local_date` + `exp_type` + `exp_group_id` + `queue` + `scenario_tag` + `is_ads` + `source_level`
**分区**: `grass_region`（大区）/ `local_date`（本地日期）/ `exp_type`（实验类型，枚举值：`traffic` | `assign_log_join`）
**更新频率**: 每日全量覆盖（T+1）
**引用频次 / 访问频次**: 1451

---

## 业务描述

本表为搜推数仓（SRDI）A/B 实验分析的**实验组 × Queue × 场景标签**日级汇总宽表，面向推荐系统实验效果评估场景。表中以实验分组（`exp_group_id`）、推荐 Queue（`queue`）、场景标签（`scenario_tag`）为核心维度，沉淀曝光、点击、商品详情页浏览（PPV）、加购、成单、GMV 等关键漏斗指标，并区分用户数（UU）和行为次数（CNT）两种口径，同时支持以 ATC 归因（当日 / 3 日内）的二次成单指标。

表中存在两种 `exp_type` 分区，对应不同的实验用户圈定逻辑：

- **`traffic`**：基于曝光流量上携带的 `exp_group_ids` 信息，覆盖全流量实验，并支持多级 source（`source_level` = 0/1/2）以及按 is_ads 维度的下钻。
- **`assign_log_join`**：以 assignment log（场景 ID = 678，新品推荐实验）Join 用户行为数据，适用于部分流量未携带实验标的场景；该分区 `is_ads` 固定为 `__ALL__`，`source_level` 固定为 `0`。

**典型业务问题举例**：
- 某实验组在指定区域、日期下，特定推荐 Queue 的点击率、加购率、GMV 表现如何？
- 不同场景标签（如 Daily Discover、You May Also Like）下各实验组的漏斗转化对比。
- 广告与非广告流量（`is_ads`）的实验指标分层分析。
- 使用 assignment log 对齐新品推荐实验曝光与成单的归因分析。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 ID、MY、TH 等；每次写入按单一大区覆盖 |
| `local_date` | date | 本地日期，事件发生的业务日期 |
| `exp_type` | string | 实验数据来源类型：`traffic`（基于曝光流量实验标）或 `assign_log_join`（基于 assignment log Join）|

### 维度：实验 & 推荐标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | 实验分组 ID，来自 A/B 实验框架，仅保留在白名单（`dim_sr_data_warehouse_abtest_group.is_rcmd_scene_whitelist = 1`）中的实验组 |
| `queue` | string | 推荐 Queue 名称，取曝光数据中 queues 字段以逗号分割后的第一个值；`source_level` > 0 时对应 source1/source2 的 queue |
| `scenario_tag` | string | 推荐场景标签，由行级 scenario_tags 数组 EXPLODE 展开；覆盖范围：DA_Cart_Unify、DA_Buy Again (Me Page)、DA_Cart Recommendation、DA_mpp_ymal-order_list、DA_odp_ymal-order_detail、DA_Order Successful Recommendation、DA_Daily Discover、DA_You May Also Like（`assign_log_join` 分区额外包含 dpm mapping group New Arrival）|
| `is_ads` | string | 是否广告流量：`true` / `false` / `__ALL__`（聚合全量）；`assign_log_join` 分区固定为 `__ALL__` |
| `source_level` | string | 曝光来源层级：`0`（主 queue）、`1`（source1 queue，且与主 queue 不同）、`2`（source2 queue，且与主/source1 queue 均不同）、`__ALL__`（跨 source 聚合）；`assign_log_join` 分区固定为 `0` |

### 指标：曝光漏斗（去重用户数）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_uu` | bigint | 有曝光行为的去重用户数（`imp_cnt > 0` 的用户计数）|
| `click_uu` | bigint | 有点击行为的去重用户数 |
| `ppv_uu` | bigint | 有 PPV（商品详情页浏览）行为的去重用户数；回跳行为（`is_back = true`）的 PPV 不计入 |
| `cart_uu` | bigint | 有加购行为的去重用户数 |
| `order_uu` | bigint | 有成单行为的去重用户数 |

### 指标：曝光漏斗（行为次数）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数汇总 |
| `click_cnt` | bigint | 点击次数汇总 |
| `ppv_cnt` | double | PPV 次数汇总；回跳（`is_back = true`）不计入 |
| `cart_cnt` | double | 加购次数汇总 |
| `order_cnt` | double | 成单笔数汇总 |

### 指标：GMV 与收入

| 字段名 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 成单 GMV，单位与上游一致（通常为本地货币，经汇率换算后的聚合值）|
| `avg_imp_price_usd` | double | 曝光商品均价（USD），计算方式为加权平均：`SUM(avg_imp_price_usd × imp_cnt) / SUM(有效 imp_cnt)`；价格优先取曝光记录中的 `avg_imp_price_local / exchange_rate`，为空时回退到商品维表 `price_usd` |

### 指标：ATC 归因成单

| 字段名 | 类型 | 说明 |
|---|---|---|
| `atc_same_day_gmv` | double | 加购当日归因 GMV |
| `atc_within_3day_gmv` | double | 加购 3 日内归因 GMV |
| `atc_same_day_order_cnt` | double | 加购当日归因成单笔数 |
| `atc_within_3day_order_cnt` | double | 加购 3 日内归因成单笔数 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区字段必须全部指定**，否则将触发全表扫描，影响性能：
   ```sql
   WHERE grass_region = 'ID'
     AND local_date = '2024-01-01'
     AND exp_type = 'traffic'   -- 或 'assign_log_join'
   ```
2. **`exp_type` 选择须与业务口径匹配**：
   - 使用全流量实验指标时选 `exp_type = 'traffic'`；
   - 使用新品推荐 assignment log 对齐指标时选 `exp_type = 'assign_log_join'`。
3. 避免跨 `exp_type` 混合聚合，两种分区的实验用户圈定逻辑不同，直接 UNION 或 SUM 会导致重复计数。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确用法 |
|---|---|---|
| `avg_imp_price_usd` | 预计算的加权均值，不同行的权重（imp_cnt）不同 | 需用 `SUM(avg_imp_price_usd * imp_cnt) / SUM(imp_cnt)` 重新加权 |
| `imp_uu` / `click_uu` / `ppv_uu` / `cart_uu` / `order_uu` | 去重用户数，跨 `scenario_tag`、`queue`、`is_ads`、`source_level` 维度存在同一用户被多行计算的情况 | 应在同一维度组合下使用，跨维度聚合需回溯明细或使用 `APPROX_COUNT_DISTINCT` |
| `ppv_cnt` / `cart_cnt` / `order_cnt` / `gmv` 等 | 在 `source_level = 0/1/2` 与 `__ALL__` 同时存在时直接 SUM 会重复计算 | 需先过滤 `source_level`（或 `is_ads`）到单一值后再聚合 |

### `source_level` 与 `is_ads` 组合说明（`exp_type = 'traffic'`）

本表使用 `GROUPING SETS` 生成多种维度组合，同一 `exp_group_id + queue + scenario_tag` 下存在以下多行：

| source_level | is_ads | 含义 |
|---|---|---|
| `0` / `1` / `2` | `__ALL__` | 按 source 层级聚合，不区分广告 |
| `__ALL__` | `true` / `false` | 按广告标聚合，不区分 source 层级 |
| `__ALL__` | `__ALL__` | 全量聚合 |

使用时必须明确指定 `source_level` 和 `is_ads` 的值，避免重复计算。

### 时效性说明

- 本表为 **T+1 日级**汇总表，命名后缀 `_1d` 表示单日快照，不包含滚动窗口。
- 每次写入为 `INSERT OVERWRITE` 按分区覆盖，数据以当日任务完成时间为准，通常在次日业务时间产出。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 核心行为明细表，提供用户 × 商品粒度的曝光/点击/PPV/加购/成单事件及实验标、Queue、场景标签信息 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验组白名单维表，过滤出推荐场景白名单中的 `exp_group_id`（`is_rcmd_scene_whitelist = 1`）|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户实验分组维表，用于 `assign_log_join` 分区，按 assignment log 圈定新品推荐实验（scene_id = 678）用户 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，将本地货币曝光价格转换为 USD |
| `mp_item.dim_item__reg_s0_live` | 商品维表，提供商品 `price_usd`，作为曝光价格缺失时的兜底值 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item
        │
        ▼
  [行为过滤 & Queue/场景标签提取]
        │
        ├─── [ETL 1: traffic 分区]
        │        │
        │        ├── 汇率换算 (fx_rate) + 商品价格补全 (dim_item_price)
        │        ├── 按 source_level (0/1/2) 展开 queue 维度
        │        ├── INNER JOIN 实验组白名单 (exp_filter)
        │        ├── EXPLODE exp_group_ids → 单实验组粒度
        │        ├── EXPLODE scenario_tags → 单场景标签粒度
        │        ├── GROUPING SETS 生成 source_level × is_ads 多维组合
        │        └── INSERT OVERWRITE PARTITION(exp_type = 'traffic')
        │
        └─── [ETL 2: assign_log_join 分区]
                 │
                 ├── INNER JOIN assignment log 用户圈（scene_id=678）
                 ├── 汇率换算 + 商品价格补全
                 ├── EXPLODE scenario_tags → 单场景标签粒度
                 └── INSERT OVERWRITE PARTITION(exp_type = 'assign_log_join')
```

### 关键步骤

**ETL 1（`exp_type = 'traffic'`）**，共 11 个 Spark SQL statement：

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `fx_rate_*` | 从汇率维表取指定日期、大区的汇率（FIRST 聚合）|
| 2 | `dim_item_price_*` | 从商品维表取商品 USD 价格，`price_usd` 为空时补 0 |
| 3 | `exp_filter_*` | 从实验组维表取推荐场景白名单实验组 ID 列表 |
| 4 | `dwm_raw_*` | 过滤行为明细：指定大区/日期/操作类型，要求有实验标（`size(exp_group_ids) > 0`），场景标签和 queue 至少有一组非空匹配；提取主/source1/source2 的 queue 和 scenario_tags，换算曝光价格 USD |
| 5 | `dwm_user_exp_base_*` | Join 商品价格补全 `avg_imp_price_usd`，item_id 为 null 的行跳过 Join 直接 UNION ALL（占比约 0.6%）|
| 6 | `dwm_user_exp_*` | 按 source_level（0/1/2）分别聚合，source1/source2 去重（避免与主 queue 重复），用户 × 实验组 × queue 粒度；加权计算均价 |
| 7 | `dwm_explode_exp_*` | EXPLODE `exp_group_ids` 数组，展开为单实验组行 |
| 8 | `dwm_filter_table_*` | INNER JOIN 实验组白名单（BROADCAST 小表），过滤非白名单实验组 |
| 9 | `dwm_explode_tag_*` | LATERAL VIEW EXPLODE `scenario_tags`，展开为单场景标签行；使用 `GROUPING SETS` 生成 source_level（0/1/2）、is_ads（true/false）、全量 三类维度组合 |
| 10 | `res_data_*` | 汇总为 exp_group_id × scenario_tag × queue × is_ads × source_level 粒度，计算 UU 数和 CNT 汇总；过滤排除 `source_level IN ('1', '2')`（仅保留 source_level=0 和 __ALL__）|
| 11 | INSERT | `INSERT OVERWRITE PARTITION(exp_type = 'traffic')` 写入目标表 |

**ETL 2（`exp_type = 'assign_log_join'`）**，共 10 个 Spark SQL statement：

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `user_exp_*` | 从用户实验分组维表取 assignment log 用户（scene_id=678，新品推荐实验）|
| 2 | `fx_rate_*` | 汇率（同 ETL 1）|
| 3 | `dim_item_price_*` | 商品价格（同 ETL 1）|
| 4 | `dwm_raw_*` | 过滤行为明细：不依赖 `exp_group_ids` 字段，仅要求 queues 非空且场景标签匹配（额外包含 `dpm mapping group New Arrival`）|
| 5 | `dwm_raw_user_exp_*` | INNER JOIN assignment log 用户圈，提前缩小数据集规模 |
| 6 | `dwm_raw_user_exp_usd_*` | Left Join 汇率，换算曝光价格为 USD |
| 7 | `dwm_user_exp_base_*` | Left Join 商品价格补全，item_id 为 null 的行跳过 Join 直接 UNION ALL |
| 8 | `dwm_explode_tag_*` | LATERAL VIEW EXPLODE `scenario_tags`，按 user_id × exp_group_id × scenario_tag × queue 聚合 |
| 9 | `res_data_*` | 汇总为 exp_group_id × scenario_tag × queue 粒度，计算 UU 数和 CNT 汇总 |
| 10 | INSERT | `INSERT OVERWRITE PARTITION(exp_type = 'assign_log_join')` 写入目标表；`is_ads` 固定写 `'__ALL__'`，`source_level` 固定写 `0` |

### 注意事项

1. **Multi-writer 并发写入**：本表由两个独立 ETL 文件分别写入不同 `exp_type` 分区（`traffic` 和 `assign_log_join`），两个任务可能并发执行。由于写入分区不同，正常情况下不存在数据互相覆盖风险，但需确保调度依赖配置正确，避免同一 `exp_type` 分区被重复触发。
2. **`avg_imp_price_usd` 为加权均值**：该字段在每个聚合层都通过 `SUM(price × cnt) / SUM(cnt)` 重新计算，查询时直接跨行 SUM 会得到错误结果，应按上述加权公式重聚合。
3. **`source_level` 过滤逻辑**：ETL 1 在 `res_data` 阶段主动过滤掉 `source_level IN ('1', '2')`，即目标表中 `exp_type = 'traffic'` 分区实际不包含 source_level 为 `1` 或 `2` 的行，仅包含 `0` 和 `__ALL__`。
4. **`ppv_cnt` 回跳过滤**：上游已将 `is_back = true` 的 PPV 置为 0，本表的 `ppv_cnt` / `ppv_uu` 均为去除回跳后的有效 PPV 指标。
5. **实验组白名单过滤**：`exp_type = 'traffic'` 分区数据仅包含在 `dim_sr_data_warehouse_abtest_group` 白名单中的实验组，查询时无需额外 Join 白名单表；`assign_log_join` 分区通过 assignment log Join 圈定用户，无独立白名单过滤步骤。
6. **GROUPING SETS 多维度展开**：`exp_type = 'traffic'` 分区因使用 GROUPING SETS，同一业务组合（exp_group_id + queue + scenario_tag）在表中存在多行，查询时务必精确指定 `is_ads` 和 `source_level` 的值，否则会造成重复计算。

---

*文档生成时间：2026-05-17*