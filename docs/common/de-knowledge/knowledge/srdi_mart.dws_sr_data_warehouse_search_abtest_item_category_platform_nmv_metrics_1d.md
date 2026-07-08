<!-- ads-workspace-gdoc-sync: gdoc_id=1WCX548uAyyfi4ijosodBSH1wZlbiAnlOvK7wbYfiTgg gdoc_url=https://docs.google.com/document/d/1WCX548uAyyfi4ijosodBSH1wZlbiAnlOvK7wbYfiTgg/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_item_category_platform_nmv_metrics_1d

**分层：** dws_search
**主键：** experiment_id + exp_group_id + platform + level1_global_be_category_id + level2_global_be_category_id + grass_region + local_date
**分区：** grass_region, local_date
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 722

---

## 业务描述

本表为搜索 A/B 实验（ABTest）维度下，按**商品品类 × 平台 × 实验组**汇总的每日 NMV（Net Merchandise Value）及净订单量指标宽表，属于搜索数仓 DWS 层。

**核心业务场景：**

- 搜索 A/B 实验效果评估：在实验组粒度下，分析不同实验方案对 GMV/NMV 及订单量的影响。
- 多维下钻分析：支持按一级/二级全球品类（Global BE Category）和平台（android_app、ios_app 等）进行交叉分析，同时保留跨维度聚合记录（`__ALL__`）。
- 搜索渠道归因：仅统计来源于 Global Search 业务线的订单，过滤非搜索渠道数据。

**适合回答的问题举例：**

- 某实验组在 Android App 上各一级品类的 NMV 较对照组提升了多少？
- 搜索实验在特定品类下的净订单数趋势如何？
- 跨平台维度下某实验的整体 NMV 表现？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区标识，如 SG、BR 等，用于多地区分区隔离 |
| `local_date` | date | 业务日期（本地日期），数据统计当天，格式 yyyy-MM-dd |

### 维度：实验信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | A/B 实验 ID，标识具体实验 |
| `exp_group_id` | bigint | 实验组 ID，标识实验内的对照组或实验组 |

### 维度：平台

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 用户下单平台，枚举值包括 `android_app`、`ios_app`、`android_app_lite`、`pc_web`、`android_web`、`ios_web`、`other`；跨平台聚合时取值为 `__ALL__` |

### 维度：商品品类

| 字段 | 类型 | 说明 |
|---|---|---|
| `level1_global_be_category_id` | string | 全球后端一级品类 ID；当该维度被 GROUPING SETS 聚合跨越时取值为 `__ALL__`；商品无品类时为 `NA` |
| `level1_global_be_category` | string | 全球后端一级品类名称；聚合跨越时为 `__ALL__`；无品类时为 `NA` |
| `level2_global_be_category_id` | string | 全球后端二级品类 ID；聚合跨越时为 `__ALL__`；无品类时为 `NA` |
| `level2_global_be_category` | string | 全球后端二级品类名称；聚合跨越时为 `__ALL__`；无品类时为 `NA` |

### 指标：订单与 NMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `net_order_cnt` | double | 净订单数（已扣除取消/退款等负向订单），来源于搜索渠道 Global Search 的归因订单 |
| `nmv` | double | 净商品交易额（Net Merchandise Value），单位 USD，来源于搜索渠道 Global Search 的归因 NMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤（必填）**：查询时必须同时指定 `grass_region` 和 `local_date`，避免全表扫描。示例：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 如需多日汇总，使用 `local_date BETWEEN ... AND ...` 而非省略分区条件。

### 不可直接 SUM 的字段说明

- **`net_order_cnt` 和 `nmv`**：本表已通过 `GROUPING SETS` 生成多粒度聚合行（含 `__ALL__` 维度占位行），**同一实验/日期下各维度组合之间存在重叠记录**，直接跨行 SUM 将导致重复计算。使用时须明确指定各维度的具体值或统一在同一粒度层级下汇总。
- **`platform = '__ALL__'`、`level1_global_be_category_id = '__ALL__'`、`level2_global_be_category_id = '__ALL__'`** 均为预聚合结果行，查询时需根据分析粒度选择一种聚合层级，切勿与具体维度值混合求和。

### 时效性说明

- 本表为 `_1d` 后缀的日粒度快照表，每日 T+1 全量覆盖写入对应分区。
- ETL 逻辑读取上游过去 7 天（`DATE_SUB(local_date, 7) ~ local_date`）数据进行用户-实验映射匹配，但最终写入目标表时按 `local_date` 分区存储，**每个分区仅反映当日聚合口径**，不存在滚动窗口叠加。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 提供用户与实验组的映射关系，过滤搜索白名单用户（`is_search_whitelist = 1`）及有效分配日志（`is_assignment_log = 1`） |
| `srdi_mart.dim_sr_data_warehouse_item` | 提供商品的一级、二级全球品类信息，与订单数据关联获取品类维度 |
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 搜索渠道平台级订单 NMV 明细，提供用户、平台、订单量、NMV 等原始指标，按 Global Search 业务线过滤 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──┐
                                           ├──► user_exp_mapping_7d (temp view)
                                           │
dim_sr_data_warehouse_item ────────────────► dim_item (temp view)
                                           │
dwd_sr_data_warehouse_platform_nmv ────────► dwm_order_nmv_platform (temp view)
       └──── JOIN dim_item ─────────────────┘
                                           │
user_exp_mapping_7d ───────────────────────► dws_order_nmv_platform (temp view, GROUPING SETS 多粒度聚合)
                                           │
                                           └──► INSERT OVERWRITE 目标表分区
```

### 关键步骤

1. **Statement 1 — `user_exp_mapping_7d`（temp view）**
   从 `dim_sr_data_warehouse_abtest_user_group` 读取指定 `grass_region` 近 7 天内，有效实验分配且在搜索白名单中的用户-实验组映射关系。

2. **Statement 2 — `dim_item`（temp view）**
   从 `dim_sr_data_warehouse_item` 读取对应 `grass_region` 近 7 天的商品品类信息（一级、二级全球 BE 品类 ID 及名称）。

3. **Statement 3 — `dwm_order_nmv_platform`（temp view）**
   从 `dwd_sr_data_warehouse_platform_nmv` 读取 Global Search 业务线（通过 `reporting_business_line` / `reporting_module` 及 source1/source2 字段过滤）的订单明细，LEFT JOIN 商品品类维度表补充品类信息。平台字段归一化（非主流平台归为 `other`），品类为空时填充 `NA`，按用户+日期+平台+品类分组聚合净订单数和 NMV。

4. **Statement 4 — `dws_order_nmv_platform`（temp view）**
   将订单数据与用户-实验组映射 JOIN，通过 `GROUPING SETS` 生成 8 种维度组合的预聚合结果，覆盖：品类+平台、仅品类、仅平台、全聚合等层级。非当前 GROUPING SET 包含的维度用 `__ALL__` 填充（`COALESCE(col, '__ALL__')`）。

5. **Statement 5 — INSERT OVERWRITE（目标表写入）**
   以 `PARTITION (grass_region=..., local_date)` 动态分区写入目标表，将 `nmv_usd` 重命名为 `nmv` 输出，覆盖当前分区全量数据。

### 注意事项

- **单 writer**：本表仅有 1 个 ETL 文件写入，不存在 multi-writer 并发冲突风险。
- **多粒度 `__ALL__` 行**：GROUPING SETS 产生 8 种聚合组合，同一分区内存在维度重叠的预聚合行，下游查询必须在单一粒度层级内使用，否则指标将被重复累加。
- **7 天回溯窗口匹配**：上游实验分配与订单数据均取近 7 天进行 JOIN，以覆盖实验用户在分配后数天内产生的转化订单；最终按订单自然日分区写入，不影响分区含义。
- **搜索渠道三路归因过滤**：订单通过 `reporting_business_line`、`source1_reporting_business_line`、`source2_reporting_business_line` 三个字段的 OR 逻辑过滤，确保多归因场景下的搜索订单均被纳入统计。
- **动态分区写入**：`local_date` 为动态分区列，每次 ETL 运行将覆盖对应 `grass_region` + `local_date` 的分区数据，重跑时幂等安全。

---

*文档生成时间：2026-05-17*