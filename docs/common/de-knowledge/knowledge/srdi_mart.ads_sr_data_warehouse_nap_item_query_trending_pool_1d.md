<!-- ads-workspace-gdoc-sync: gdoc_id=1u7Wm8jxSgJCLwXBMiCQ2j4QQ4Ptb2f6fWhzC89WIRYI gdoc_url=https://docs.google.com/document/d/1u7Wm8jxSgJCLwXBMiCQ2j4QQ4Ptb2f6fWhzC89WIRYI/edit -->

# srdi_mart.ads_sr_data_warehouse_nap_item_query_trending_pool_1d

**分层：** ADS（应用数据层）
**主键：** `item_id`（联合分区字段 `grass_region`、`local_date`）
**分区：** `grass_region`（大区）/ `local_date`（日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 181 次

---

## 业务描述

本表为搜推数仓 NAP（New Arrival Product / 新品）场景下的**商品查询趋势候选池**日快照表，记录各大区每日通过搜索行为识别出的趋势商品及其关联的热门查询词。

**核心业务场景：**
- 将趋势查询词（Trending Keywords）与具体商品（Item）进行关联，构建趋势商品候选池，供搜索/推荐排序、运营选品、趋势洞察等下游场景消费。
- 融合已通过质量审核（`qc_status = 'pass'`）的趋势查询数据与长期趋势商品池维度数据，保证候选池覆盖度的同时过滤低质量信号。

**适合回答的问题：**
- 某大区某日哪些商品关联了趋势查询词？这些商品分别属于哪些类目？
- 某商品在当日趋势查询词列表中的排名如何？
- 用户搜索了哪些关键词后命中了该趋势商品？
- 某趋势类型（`trending_type`）下有哪些商品进入了候选池？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 TW、TH、VN 等，用于数据分区隔离 |
| `local_date` | date | 数据业务日期（本地日期），每日分区 |

### 维度：商品与店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，主体标识；来自趋势查询表或趋势商品池维度表（FULL OUTER JOIN，取 COALESCE） |
| `shop_id` | bigint | 商品所属店铺 ID |
| `original_item_title` | string | 商品原始标题 |

### 维度：类目

| 字段 | 类型 | 说明 |
|---|---|---|
| `global_be_category` | string | 商品全局后端类目名称 |
| `global_be_category_id` | bigint | 商品全局后端类目 ID |

### 指标：趋势查询词信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_query_list` | array\<string\> | 关联该商品的用户搜索查询词列表，来自趋势查询 DWD 层 |
| `trending_keyword` | array\<string\> | 命中的趋势关键词列表，与 `trending_keyword_rank` 一一对应 |
| `trending_keyword_rank` | array\<int\> | 趋势关键词对应的排名列表，数值越小排名越靠前 |
| `trending_type` | string | 趋势类型标识，用于区分不同趋势判定策略或来源（如上升趋势、新兴趋势等） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须指定**，否则将触发全表扫描，严重影响性能：
  ```sql
  WHERE grass_region = 'TH'
    AND local_date = '2024-01-01'
  ```
- 建议同时指定 `grass_region` 和 `local_date` 两个分区字段，二者均为分区列。

### 不可直接 SUM / 聚合的字段

| 字段 | 原因 |
|---|---|
| `trending_keyword_rank` | Array 类型，表示各关键词排名，不可直接 SUM；需先 `EXPLODE` 展开后按业务逻辑处理 |
| `trending_keyword` | Array 类型，需先 `EXPLODE` 展开后再聚合统计 |
| `search_query_list` | Array 类型，需先 `EXPLODE` 展开后再聚合统计 |

**展开示例：**
```sql
SELECT item_id, kw, rnk
FROM srdi_mart.ads_sr_data_warehouse_nap_item_query_trending_pool_1d
LATERAL VIEW POSEXPLODE(trending_keyword) t AS pos, kw
LATERAL VIEW POSEXPLODE(trending_keyword_rank) r AS pos2, rnk
WHERE grass_region = 'TH'
  AND local_date = '2024-01-01'
  AND pos = pos2  -- 保持 keyword 与 rank 对齐
```

### 时效性说明

- 本表为 **`_1d` 日粒度快照表**，每日通过调度任务以 `INSERT OVERWRITE` 方式覆写指定 `grass_region + local_date` 分区。
- 数据通常在 T+1 产出，使用时需关注上游 DWD 层（`dwd_sr_data_warehouse_nap_query_trending_1d`）和维度表（`dim_sr_data_warehouse_nap_trending_pool_df`）的产出时效。
- 历史分区数据一经写入不会自动修正，如需最新数据请使用当前业务日期分区。

### 其他注意事项

- 本表通过 **FULL OUTER JOIN** 构建，`item_id` 可能仅来自 DWD 趋势查询层（有查询行为但不在维度池中）或仅来自维度池（在候选池中但当日无查询通过 QC）。查询时需注意部分字段可能为 NULL。
- `original_item_title`、`search_query_list`、`trending_keyword`、`trending_keyword_rank`、`trending_type` 字段仅在商品存在于 DWD 层（且 `qc_status = 'pass'`）时有值，否则为 NULL。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_nap_query_trending_1d` | DWD 层 NAP 趋势查询日表，提供商品与查询词的关联关系及趋势词信息；仅取 `qc_status = 'pass'` 的数据 |
| `srdi_mart.dim_sr_data_warehouse_nap_trending_pool_df` | NAP 趋势商品池维度表，提供趋势商品的 `item_id`、`shop_id`、类目等基础维度信息，扩充候选池覆盖度 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_nap_query_trending_1d  (QC 过滤: qc_status='pass')
        |
        |  FULL OUTER JOIN on item_id
        |
dim_sr_data_warehouse_nap_trending_pool_df   (维度补充)
        |
        ▼
ads_sr_data_warehouse_nap_item_query_trending_pool_1d
(INSERT OVERWRITE partition: grass_region + local_date)
```

### 关键步骤

1. **DWD 数据过滤（子查询 T1）**
   从 `dwd_sr_data_warehouse_nap_query_trending_1d` 中按 `grass_region` 和 `local_date` 分区过滤，同时限制 `qc_status = 'pass'`，确保只有质量合格的趋势查询记录进入候选池。

2. **维度数据获取（子查询 T2）**
   从 `dim_sr_data_warehouse_nap_trending_pool_df` 中按 `grass_region` 和 `local_date` 过滤，获取趋势商品池的基础维度信息（`item_id`、`shop_id`、`global_be_category_id`、`global_be_category`）。

3. **FULL OUTER JOIN 融合**
   以 `item_id` 为连接键对 T1 和 T2 做全外连接，使用 `COALESCE(T1.item_id, T2.item_id)` 确保来自任一侧的商品均保留，最大化候选池覆盖度。

4. **分区覆写写入目标表**
   使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 将结果写入目标表对应分区，实现幂等刷新。

### 注意事项

- **单 Writer：** 本表仅有 1 个 ETL 文件写入，不存在多 Writer 并发写同一分区的风险。
- **分区覆写：** 使用 `INSERT OVERWRITE` + 动态分区参数（`${grass_region}`、`${local_date}`），重跑时会覆盖对应分区，具有幂等性。
- **QC 过滤依赖：** DWD 层 `qc_status` 字段的质量直接决定本表数据覆盖度，若上游 QC 逻辑变化，本表数据量可能出现显著波动。
- **FULL OUTER JOIN NULL 风险：** 当商品仅存在于维度表而不存在于当日 DWD 趋势数据时，`search_query_list`、`trending_keyword` 等字段将为 NULL，下游使用时需做 NULL 判断。

---

*文档生成时间：2026-05-17*