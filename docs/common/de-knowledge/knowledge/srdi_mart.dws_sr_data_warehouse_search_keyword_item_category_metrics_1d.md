<!-- ads-workspace-gdoc-sync: gdoc_id=1ZYoiVj---Wtx1k8bhN8dBqU6vkthTgIIY8JdAcNnMOM gdoc_url=https://docs.google.com/document/d/1ZYoiVj---Wtx1k8bhN8dBqU6vkthTgIIY8JdAcNnMOM/edit -->

# srdi_mart.dws_sr_data_warehouse_search_keyword_item_category_metrics_1d

**分层：** dws_search
**主键：** keyword + keyword_cluster + level1_category + level2_category + level3_category + is_ads + grass_region + local_date
**分区：** grass_region, local_date
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 455

---

## 业务描述

本表为搜索域宽表（DWS 层），以 **搜索关键词 × 商品类目 × 是否广告** 为分析粒度，统计每日各站点搜索场景下的曝光、PDP 访问、加购及下单相关指标。通过 `GROUPING SETS` 同时生成「按广告/自然流量细分」和「汇总全部流量」两种口径的数据，方便上层按需取用。

**核心业务场景：**

- 分析搜索关键词在不同商品类目下的转化漏斗（曝光 → PDP → 加购 → 下单）
- 对比广告流量与自然流量在各类目下的搜索表现差异
- 按关键词聚类（`keyword_cluster`）评估同类意图词的整体品类分布与 GMV 贡献
- 支持搜索推荐质量评估、品类运营分析及商业化效果衡量

**适合回答的问题示例：**

- 某关键词在一级/二级/三级品类下的每日曝光量与 GMV 是多少？
- 广告搜索结果与自然结果在某品类下的下单率差异如何？
- 某关键词聚类在各三级类目的加购次数分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点 / 区域标识，如 `ID`、`MY`、`TH` 等，所有查询必须指定此分区 |
| `local_date` | date | 业务日期（当地时区），格式 `yyyy-MM-dd`，所有查询必须指定此分区 |

### 维度：搜索关键词

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 用户搜索词；原始值经 `COALESCE(keyword, '')` 处理，空搜索词统一为空字符串 |
| `keyword_cluster` | string | 关键词一级类目聚类标签，来自 `global_category_cluster_mapping`，表示该搜索词映射到的类目簇 |

### 维度：商品类目

| 字段 | 类型 | 说明 |
|---|---|---|
| `level1_category` | string | 商品全球后端一级类目（`level1_global_be_category`） |
| `level2_category` | string | 商品全球后端二级类目（`level2_global_be_category`） |
| `level3_category` | string | 商品全球后端三级类目（`level3_global_be_category`） |

### 维度：流量类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | string | 是否广告流量；`'true'` 表示广告，`'false'` 表示自然流量，`'__ALL__'` 表示广告与自然汇总口径（由 `GROUPING SETS` 生成） |

### 指标：搜索行为漏斗

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_imp_cnt` | bigint | 商品曝光次数（operation = `impression`），已对 NULL 补 0 |
| `item_ppv_cnt` | bigint | 商品 PDP（详情页）访问次数（operation = `ppv`），已对 NULL 补 0 |
| `atc_cnt` | bigint | 加购次数（operation = `cart`），已对 NULL 补 0 |

### 指标：下单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `place_order_cnt` | double | 下单次数（operation = `order`），已对 NULL 补 0 |
| `place_gmv` | double | 下单 GMV（本地货币，`place_order_gmv_local`），已对 NULL 补 0 |
| `place_gmv_usd` | double | 下单 GMV（美元，`place_order_gmv`），已对 NULL 补 0 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**，否则将触发全表扫描，影响性能和成本：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-06-01'
  ```
- 若需要汇总多天数据，建议以 `local_date BETWEEN ... AND ...` 指定明确日期范围。

### `is_ads` 字段使用注意

- 本表同时存储两种聚合口径：
  - `is_ads IN ('true', 'false')`：广告/自然流量细分数据
  - `is_ads = '__ALL__'`：广告与自然的汇总数据
- **不可对同一 keyword + category 组合直接对全部 `is_ads` 值 SUM**，否则会导致重复计数。分析时须二选一：
  - 若需要细分：`WHERE is_ads IN ('true', 'false')`
  - 若需要汇总：`WHERE is_ads = '__ALL__'`

### 不可直接 SUM 的情形

- `place_gmv`、`place_gmv_usd`、`place_order_cnt` 等指标在不同 `is_ads` 值下存在重叠，跨 `is_ads` 维度聚合时必须先限定口径，再做 SUM。
- 各指标均为预聚合结果，可在同一 `is_ads` 口径内安全跨 keyword / category 做 SUM。

### 时效性说明

- 本表为 **T+1 日粒度**（`_1d` 后缀），每日凌晨刷写前一自然日数据，查询当日数据时注意时效延迟约为 1 天。
- 统计范围仅覆盖 `page_type IN ('global_search', 'search_in_pdp', 'search_prefill')`，不含其他页面来源。
- `page_section IS NULL` 为 ETL 过滤条件，非整站搜索数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细（曝光、PDP、加购、下单事件及 GMV），为核心事实来源 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，提供商品一/二/三级全球后端类目信息 |
| `mkplsearch_data_product.global_category_cluster_mapping` | 全球类目聚类映射表，提供一级类目对应的关键词聚类标签（`cluster`） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_search          dim_sr_data_warehouse_item
        │ (事件过滤 + 字段清洗)                │ (类目维度扩展)
        └────────────────JOIN────────────────┘
                         │
              global_category_cluster_mapping
                         │ (LEFT JOIN 补充聚类标签)
                         │
                  行级聚合 (row_metrics)
                         │
              GROUPING SETS 双口径聚合
                         │
      INSERT OVERWRITE 目标表（按 grass_region + local_date 分区）
```

### 关键步骤

**Step 1 — `category_cluster` 临时视图**
从 `global_category_cluster_mapping` 取 `tree_type = 'global'` 的记录，按一级类目取 `MAX(cluster)` 去重，生成一级类目与聚类标签的映射。

**Step 2 — `item_cats` 临时视图**
从商品维度表 `dim_sr_data_warehouse_item` 按 `grass_region` + `local_date` 过滤，提取各商品的三级全球类目信息。

**Step 3 — `parse_data` 临时视图**
从搜索行为宽表 `dwd_sr_data_warehouse_search` 过滤出目标场景的事件记录：
- 页面类型限定：`global_search`、`search_in_pdp`、`search_prefill`
- `page_section IS NULL`（排除模块内搜索）
- `target_type = 'item'`（商品结果）
- 行为类型：`impression`、`ppv`、`cart`、`order`
- `keyword` 空值处理为空字符串，`is_ads` 转为字符串类型

**Step 4 — `row_metrics` 临时视图**
将 `parse_data` 与 `item_cats`（INNER JOIN）及 `category_cluster`（LEFT JOIN）关联，按 keyword + cluster + 三级类目 + is_ads 分组，使用 CASE WHEN 将不同 operation 类型的指标横向展开为各聚合列（曝光、PDP、加购、下单次数、本地 GMV、美元 GMV）。

**Step 5 — 最终写入**
对 `row_metrics` 使用 `GROUPING SETS` 生成两种聚合口径：
- 完整维度组合（含 `is_ads`）：保留广告/自然细分
- 省略 `is_ads` 的组合：`is_ads` 填充为 `'__ALL__'`，表示全量汇总

最后以 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 写入目标表。

### 注意事项

- **单写入文件（multi_writer = false）**：本表由单个 ETL 文件写入，无多写竞争风险。
- **INSERT OVERWRITE 分区写入**：每次执行覆盖指定 `grass_region + local_date` 分区，重跑安全，不会影响其他分区数据。
- **GROUPING SETS 双行风险**：同一 keyword + category 组合在同一分区内会存在两条记录（`is_ads` 有具体值 vs `'__ALL__'`），下游使用时务必按 `is_ads` 条件过滤，避免重复计算。
- **INNER JOIN 数据丢失**：`parse_data` 与 `item_cats` 为内关联，无法匹配到商品维度的事件记录将被丢弃，类目维度不完整的商品不会进入统计。
- **`category_cluster` MAX 去重**：若同一一级类目在 mapping 表中存在多个 `cluster` 值，当前取 `MAX` 保留一个，可能导致聚类信息不完整，使用 `keyword_cluster` 时需知晓此限制。

---

*文档生成时间：2026-05-17*