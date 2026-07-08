<!-- ads-workspace-gdoc-sync: gdoc_id=1NmxYUljJIFAFfKV_FkbjuDxlt7CQrczVzkhGnDJrkHY gdoc_url=https://docs.google.com/document/d/1NmxYUljJIFAFfKV_FkbjuDxlt7CQrczVzkhGnDJrkHY/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_item_level_ppv_layer_30d

**分层**：DWS（数据汇总层）
**主键**：`item_id` + `local_date` + `grass_region`
**分区**：`local_date`（日期分区）、`grass_region`（大区分区）
**更新频率**：每日一次（T+1 全量覆盖写入，`INSERT OVERWRITE` 按分区）
**引用频次 / 访问频次**：18,781 次
**字段数**：19
**ETL 文件数**：1（单 writer，无多路写入）

---

## 业务描述

本表面向**搜索与推荐（SRDI）数据仓库平台**，以**商品（item）为粒度**，汇总最近 7 天与最近 30 天的曝光流量（PPV）及订单数，并在 7 日全量商品中按 PPV 总量进行**流量分层（Decile 分层）**，将商品划分至 10%～100% 十个流量层级。

**核心业务场景：**
- 平台流量健康度监控：识别头部、腰部、尾部商品的流量分布结构。
- 商品流量分层治理：根据 `ppv_percent` 分层标签对商品进行差异化运营策略制定。
- 品类流量分析：结合五级类目维度，分析各类目下商品流量集中度与转化情况。
- 历史对比分析：同时提供 7 日与 30 日滚动窗口，便于短期波动与趋势对比。

**适合回答的问题：**
- 某大区 / 类目下，近 30 天流量最高的 Top N 商品有哪些？
- 近 7 天流量属于前 10% 的商品（`ppv_percent = '10%'`）在各类目如何分布？
- 某商品近 7 天 PPV 与 30 天 PPV 的变化趋势？
- 各流量层级商品的平均订单转化率是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `local_date` | date | 数据日期（业务分区日期），表示该分区数据的统计截止日期（当天） |
| `grass_region` | string | 大区标识，如 ID、TH、MY 等，用于区分不同市场的数据分区 |

### 维度：商品与店铺标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，主键之一；仅包含 7 日内有有效曝光（PPV > 0）的商品 |
| `shop_id` | bigint | 商品所属店铺 ID，取该商品最新一天（`local_date` 最大）的店铺信息 |

### 维度：全球后端类目（五级）

| 字段 | 类型 | 说明 |
|---|---|---|
| `level1_global_be_category_id` | bigint | 一级全球后端类目 ID |
| `level1_global_be_category` | string | 一级全球后端类目名称 |
| `level2_global_be_category_id` | bigint | 二级全球后端类目 ID |
| `level2_global_be_category` | string | 二级全球后端类目名称 |
| `level3_global_be_category_id` | bigint | 三级全球后端类目 ID |
| `level3_global_be_category` | string | 三级全球后端类目名称 |
| `level4_global_be_category_id` | bigint | 四级全球后端类目 ID |
| `level4_global_be_category` | string | 四级全球后端类目名称 |
| `level5_global_be_category_id` | bigint | 五级全球后端类目 ID |
| `level5_global_be_category` | string | 五级全球后端类目名称 |

> 类目维度取商品在统计窗口内最近一日（`rn = 1`）的类目快照，非历史加权。

### 指标：曝光流量与订单（近 7 天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `total_ppv_l7d` | bigint | 近 7 天（含当日）商品 PPV 总量，排除 isback 回退流量；仅统计 `feature_detail = '__ALL__'` 且 `scenario_tag = '__ALL__'` 的汇总行 |
| `order_counts_l7d` | double | 近 7 天商品订单数汇总 |

### 指标：曝光流量与订单（近 30 天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `total_ppv_l30d` | bigint | 近 30 天（含当日）商品 PPV 总量，排除 isback 回退流量；来源同上游汇总行过滤逻辑 |
| `order_counts_l30d` | double | 近 30 天商品订单数汇总 |

### 指标：流量分层标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_percent` | string | 商品 PPV 流量分层标签，基于近 7 天全站（该大区）PPV 累计占比（从高到低）将商品分入 10 个等级：`'10%'` 表示累计 PPV 占全站前 10% 的头部商品，`'100%'` 表示尾部商品。采用窗口函数 `sum(total_ppv_l7d) over(order by total_ppv_l7d desc)` 计算 running total 后与全站 PPV 总量比较得出 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定大区，否则将跨分区扫描所有市场数据，严重影响性能且结果无意义。
- **`local_date`**：必须指定具体日期（或日期范围），该表按日期分区，不过滤将触发全量扫描。

```sql
-- 推荐写法示例
WHERE grass_region = 'ID'
  AND local_date = '2025-05-16'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `ppv_percent` | 分层标签（字符串），不可聚合；跨日期比较时分层基准不同，需各日独立解读 |
| `order_counts_l7d` / `order_counts_l30d` | 滚动窗口预聚合指标，跨多个 `local_date` 分区叠加 SUM 会产生**重复计算**（窗口期数据重叠） |
| `total_ppv_l7d` / `total_ppv_l30d` | 同上，滚动 N 日预聚合，跨分区 SUM 会导致多日重复累加 |

### 时效性说明

- 本表为**近 N 日滚动窗口**表（后缀 `_30d`），每日产出当天截止的最近 7 日和最近 30 日汇总。
- 数据以 **T+1** 节奏写入，当日分区数据反映前一天及过去 7/30 天的累积情况。
- `ppv_percent` 流量分层**仅基于近 7 日**数据计算，与 `total_ppv_l30d` 窗口不同，使用时注意区分。
- 每次写入为 `INSERT OVERWRITE`，同一 `(local_date, grass_region)` 分区内数据完整覆盖，无增量追加。

### 其他注意事项

- 本表**不包含** `total_ppv_l7d = 0` 的商品（ETL 中 `having total_ppv_l7d > 0` 过滤），尾部零曝光商品不在此表中。
- 类目维度（`levelN_global_be_category`）和 `shop_id` 取的是近 7 天中**最新一日**的快照，历史分区中的类目值可能与当前归属不一致，跨日期分析类目时请注意。
- `ppv_percent` 的分层是在**大区内**全站商品范围内计算，不同大区之间分层不可横向比较。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_item_level_benchmark_1d` | 提供商品粒度日级 PPV（排除 isback）、订单数及类目维度信息，作为近 7 日和近 30 日窗口汇总的数据源 |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_platform_item_level_benchmark_1d
    ├─ [近7日] ──→ item_level_benchmark_7d (临时视图，日期范围过滤)
    │               ├─→ item_info_7d       (取最新日类目/店铺维度快照)
    │               ├─→ item_metrics_7d    (商品级7日PPV/订单汇总，过滤零曝光)
    │               │       └─→ item_metrics_7d_window (附加running_total_ppv窗口列)
    │               └─→ all_item_metrics_7d (全站7日PPV总量，用于分层基准)
    └─ [近30日] ──→ item_metrics_30d      (商品级30日PPV/订单汇总)

[JOIN 组合] → INSERT OVERWRITE 目标表分区
```

### 关键步骤

| 步骤 | 临时视图 / 操作 | 说明 |
|---|---|---|
| Step 1 | `item_level_benchmark_7d_{region}` | 从上游日表读取近 7 日数据，过滤指定大区、`item_id IS NOT NULL`、`feature_detail = '__ALL__'`、`scenario_tag = '__ALL__'`（全量汇总行） |
| Step 2 | `item_info_7d_{region}` | 对 Step 1 按 `item_id` 分区、`local_date` 降序排名，用于后续取最新日类目/店铺信息（`rn = 1`） |
| Step 3 | `item_metrics_7d_{region}` | 对 Step 1 按 `item_id` 聚合，计算 `total_ppv_l7d`、`order_counts_l7d`；`HAVING total_ppv_l7d > 0` 过滤零曝光商品 |
| Step 4 | `item_metrics_7d_window_{region}` | 对 Step 3 按 `total_ppv_l7d DESC` 排序，计算 `running_total_ppv`（累计 PPV 窗口函数），用于 `ppv_percent` 分层计算 |
| Step 5 | `all_item_metrics_7d_{region}` | 对 Step 1 全表求和 `ppv_cnt_exclude_isback`，得到全站 7 日 PPV 基准总量；使用 `REPARTITION(1)` 提示收敛为单分区 |
| Step 6 | `item_metrics_30d_{region}` | 直接读取上游日表近 30 日数据，按 `item_id` 聚合计算 `total_ppv_l30d`、`order_counts_l30d`，过滤逻辑同 Step 1 |
| Step 7 | `INSERT OVERWRITE` | 以 Step 4（`item_metrics_7d_window`）为主驱动表，CROSS JOIN Step 5（全站基准，单行），LEFT JOIN Step 6（30 日指标），LEFT JOIN Step 2（取 `rn=1` 维度快照），按 `ppv_percent` 逻辑分箱后写入目标表分区 `(local_date, grass_region)` |

### 注意事项

- **`ppv_percent` 分箱逻辑**：使用 `running_total_ppv`（累计 PPV）与 `all_item_total_ppv_cnt / 10 * N` 的比较进行十分位分层，为**开区间**判断（`<`），最后兜底为 `'100%'`；`running_total_ppv` 基于 7 日数据，与 30 日指标窗口不一致，需注意混用场景。
- **CROSS JOIN 风险**：Step 5（`all_item_metrics_7d`）与主表为无条件 JOIN，若 `REPARTITION(1)` 未生效或上游数据异常导致多行输出，将产生笛卡尔积，需监控该视图行数恒为 1。
- **30 日商品范围差异**：Step 6 未做 `total_ppv_l30d > 0` 的过滤，且主驱动表为 7 日有曝光商品，因此对于 7 日内有曝光但 30 日汇总表中不存在的商品，`total_ppv_l30d` 和 `order_counts_l30d` 将为 NULL，查询时需做 `COALESCE` 处理。
- **单 writer，无多路写入**：该表仅有 1 个 ETL 文件，不存在并发写入同一分区的风险。
- **参数化执行**：SQL 中 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}`、`${schema}` 均为调度参数，每次按大区和日期单独触发，一次运行仅写入一个 `(local_date, grass_region)` 分区。

---

*文档生成时间：2026-05-17*