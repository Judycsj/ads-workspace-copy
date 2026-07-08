<!-- ads-workspace-gdoc-sync: gdoc_id=1d1Got4snA0iCMx8u-KTotqZJyzWzGxWAiInC6C5XmnY gdoc_url=https://docs.google.com/document/d/1d1Got4snA0iCMx8u-KTotqZJyzWzGxWAiInC6C5XmnY/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_scene_995_threshold_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `mapping_general` + `is_ads` + `is_item_card`
**分区：** `grass_region`（大区）, `local_date`（业务日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**访问频次：** 540

---

## 业务描述

本表用于存储搜推（Search & Recommendation）业务中，**各场景下 GPO（每单平均 GMV）的 99.5% 分位数阈值**，即"995 阈值"。GPO 阈值常用于异常订单过滤、GMV 去极值处理等数据清洗场景，保障下游指标计算的稳健性。

**核心业务场景：**
- 按业务场景（Search、Daily Discover、You May Also Like、Post Purchase、Shop、S&R 全量、RCMD 汇总、全平台）分别计算用户维度 GPO 的 99.5% 分位值；
- 支持按是否为广告（`is_ads`）、是否为商品卡（`is_item_card`）的维度组合（含 `__ALL__` 汇总维度）拆分计算；
- 涵盖直接归因（主归因）和间接归因（source1/source2 多路归因）的订单数据。

**适合回答的问题：**
- 某大区某天，Search 场景下非广告用户的 GPO 995 阈值是多少？
- 全平台（`mapping_general = '__ALL__'`）广告与非广告的 GPO 极值阈值分别是多少？
- S&R 整体（Search + Recommendation）场景下商品卡订单的 GPO 阈值是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区，如 `ID`、`MY`、`TH` 等，用于数据分区隔离 |
| `local_date` | date | 业务日期，数据统计的自然日，格式 `yyyy-MM-dd` |

### 维度：场景与广告分类

| 字段 | 类型 | 说明 |
|---|---|---|
| `mapping_general` | string | 业务场景归类。取值包括：`Search`（全局搜索）、`Daily Discover`（每日发现）、`You May Also Like`（猜你喜欢）、`Post Purchase`（购后推荐）、`Shop`（店铺场景）、`S&R__ALL__`（Search & Recommendation 整体）、`RCMD`（推荐汇总，含 Daily Discover / You May Also Like / Post Purchase）、`__ALL__`（全平台汇总）|
| `is_ads` | string | 是否为广告流量。取值：`true`（广告）、`false`（非广告）、`__ALL__`（不区分广告/非广告的汇总维度） |
| `is_item_card` | string | 是否为商品卡。取值：`true`（商品卡）、`false`（非商品卡）、`__ALL__`（不区分商品卡/非商品卡的汇总维度） |

### 指标：GPO 分位阈值

| 字段 | 类型 | 说明 |
|---|---|---|
| `gpo_pct` | double | 指定场景 + 维度组合下，用户粒度 GPO（= GMV / 订单量）的 99.5% 近似分位数阈值（`approx_percentile(gpo, 0.995)`）。用于下游极值过滤和数据清洗 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：本表按大区分区，查询时必须指定 `grass_region`，否则将触发全分区扫描，严重影响性能；
- **`local_date`**：本表为日粒度快照表，查询时必须指定具体日期，避免跨天扫描；
- 示例：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```

### 不可直接 SUM 的字段

- **`gpo_pct`**：该字段为 99.5% 近似分位数（`approx_percentile`），是预聚合派生统计量，**不能跨行 SUM、AVG 或再次聚合**。如需跨场景/跨大区合并阈值，须回溯明细数据重新计算分位数；
- 跨 `mapping_general` 聚合时，注意 `S&R__ALL__`、`RCMD`、`__ALL__` 等汇总口径与细分场景存在数据重叠，**不可直接合并相加**。

### 时效性说明

- 本表为 **`_1d` 日粒度表**，每日 ETL 全量覆盖写入当日分区；
- 数据通常 T+1 产出，查询最新数据时以前一自然日为准；
- 表内无滚动窗口（无 `_nd` / `_td` 语义），每个 `local_date` 分区仅代表当日数据。

### `mapping_general` 取值说明

| 取值 | 来源视图 | 口径说明 |
|---|---|---|
| `Search` / `Daily Discover` / `You May Also Like` / `Post Purchase` / `Shop` | `every_scene_995` | 按细分场景规则归因的 GPO 阈值 |
| `S&R__ALL__` | `sr_995` | Search（含图搜）+ Homepage Daily Discover + Rcmd User Scenario 的合并口径 |
| `RCMD` | `rcmd_995` | Daily Discover + You May Also Like + Post Purchase 的推荐汇总口径 |
| `__ALL__` | `platform_995` | 全平台所有订单，不限场景 |

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` | 提供用户粒度的订单数（`order_cnt`）和 GMV（`gmv`），包含归因场景字段（`reporting_business_line`、`reporting_module`、`reporting_object`）及多路归因来源字段（`source1_*`、`source2_*`），过滤 `operation = 'order'` 后作为计算基础 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_tc_ab_all_cards
        │  (过滤 operation='order'，按用户聚合)
        ▼
log_data_raw（原始日志汇总，用户 + 场景维度）
        │
        ├──► every_scene_995_step1 → every_scene_995_step2 → every_scene_995
        │      （细分场景：Search / Daily Discover / YMAL / Post Purchase / Shop）
        │
        ├──► sr_995_step1 → sr_995_step2 → sr_995
        │      （S&R 整体合并场景）
        │
        ├──► platform_995
        │      （全平台，不限场景）
        │
        └──► rcmd_995（复用 every_scene_995_step2）
               （推荐汇总：Daily Discover + YMAL + Post Purchase）
                │
                ▼
dws_sr_data_warehouse_tc_scene_995_threshold_1d（UNION ALL 写入）
```

### 关键步骤

1. **`log_data_raw`（Temporary View）**
   - 从上游 DWM 表读取指定大区和日期的订单数据，过滤 `operation = 'order'`；
   - 将 `is_ads`、`source1_is_ads`、`source2_is_ads` 由 boolean 转换为字符串 `'true'`/`'false'`；
   - 按用户、归因场景字段及广告标识聚合，得到用户粒度的 `order_cnt` 和 `gmv`。

2. **`every_scene_995_step1`（Temporary View）**
   - 对 `log_data_raw` 应用场景映射规则，将 `reporting_*` 字段映射为 `mapping_general`（主归因场景），同样处理 `source1_*`、`source2_*` 的归因场景。

3. **`every_scene_995_step2`（Temporary View）**
   - UNION ALL 三路数据：主归因（`mapping_general != ''`）、source1 归因（场景不为空且与主归因不同）、source2 归因（场景不为空且与主归因、source1 归因均不同），实现多路归因去重合并。

4. **`every_scene_995`（Temporary View）**
   - 先在用户粒度计算 GPO（`GMV / order_cnt`），使用 `GROUPING SETS` 生成 `is_ads`、`is_item_card` 的全维度组合（含 `__ALL__`）；
   - 再对用户 GPO 计算 `approx_percentile(gpo, 0.995)` 得到场景 995 阈值。

5. **`sr_995_step1` → `sr_995_step2` → `sr_995`（Temporary View）**
   - 逻辑与 `every_scene_995` 链路相似，但场景归类规则宽泛（Search 含图搜、Homepage Daily Discover、Rcmd User Scenario 均归入 `S&R__ALL__`），代表 Search & Recommendation 的整体汇总口径。

6. **`platform_995`（Temporary View）**
   - 直接在 `log_data_raw` 全量数据上计算用户 GPO 并求 995 分位数，场景固定为 `__ALL__`，代表全平台口径。

7. **`rcmd_995`（Temporary View）**
   - 复用 `every_scene_995_step2`，过滤 `mapping_general in ('Daily Discover','You May Also Like','Post Purchase')` 后计算推荐汇总（`RCMD`）口径的 995 阈值。

8. **INSERT OVERWRITE（目标表写入）**
   - 将 `every_scene_995`、`sr_995`、`platform_995`、`rcmd_995` 四个视图的结果 UNION ALL 后，以 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 写入目标表对应分区。

### 注意事项

- **单 Writer**：本表仅有一个 ETL 文件写入，无多 Writer 并发风险；
- **分区覆盖写入**：采用 `INSERT OVERWRITE` 按 `grass_region` + `local_date` 分区覆盖，重跑幂等安全；
- **`approx_percentile` 近似性**：`gpo_pct` 使用 Spark 内置近似分位数算法，结果为近似值，不同 Spark 版本或数据分布变化可能导致微小差异，不建议与精确分位数结果直接对比；
- **`GROUPING SETS` 生成 `__ALL__` 维度**：`is_ads` 和 `is_item_card` 取值为 `__ALL__` 的行是通过 `GROUPING SETS` 汇总产生，查询时需注意与具体取值行的区分，避免重复计数；
- **多路归因去重逻辑**：source1/source2 归因数据仅在与主归因场景不重复时才纳入，需理解此去重规则后再设计下游关联逻辑；
- **参数化执行**：SQL 中 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 为运行时参数，ETL 按大区逐一调度执行。

---

*文档生成时间：2026-05-17*