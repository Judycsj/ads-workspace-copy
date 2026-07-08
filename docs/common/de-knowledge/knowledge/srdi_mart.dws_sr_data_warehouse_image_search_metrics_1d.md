<!-- ads-workspace-gdoc-sync: gdoc_id=1ChsqbIRkyqtub7KiNZIG2QwCA7RUf4jjy27BJ1XKDo8 gdoc_url=https://docs.google.com/document/d/1ChsqbIRkyqtub7KiNZIG2QwCA7RUf4jjy27BJ1XKDo8/edit -->

# srdi_mart.dws_sr_data_warehouse_image_search_metrics_1d

**分层：** DWS（数据服务层 / dws_search）
**主键：** `search_entrance` + `image_source` + `is_ads` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日（T+1，按天覆盖写入）
**引用频次 / 访问频次：** 83

---

## 业务描述

本表是图搜（以图搜物）业务的**日粒度聚合宽表**，汇总了图搜各入口、各图片来源、广告/非广告维度下的用户行为与转化核心指标。

**核心业务场景：**

- 监控图搜每日整体健康度：DAU、查询量、结果率等流量漏斗指标；
- 分析各搜索入口（`search_entrance`）的图搜使用深度与转化差异；
- 拆分图片来源（`image_source`）对图搜效果的影响；
- 区分广告（`is_ads`）与自然结果的转化表现对比；
- 追踪 GMV、加购、下单等电商转化链路的图搜贡献；
- 评估图搜算法质量：Top1 相似度均值、结果率（有结果/无结果查询量）。

**适合回答的问题举例：**

- 某大区某天图搜 DAU 是多少？各入口占比如何？
- 图搜查询中有多少比例没有返回结果（`image_search_non_result_volume`）？
- 广告图搜与自然图搜在加购率、成交率上有何差异？
- 来自相机拍照（`camera_uu`）vs 其他图片来源的用户转化对比？
- 图搜首位相似度（`avg_top1_similarity`）趋势是否在改善？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区（如 ID、TH、MY 等），分区键 |
| `local_date` | date | 业务日期（本地时间），分区键 |

### 维度：图搜入口 / 来源 / 广告标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_entrance` | string | 搜索入口，如 `SEARCH_RESULT`、`HOME`、`MALL` 等；当按 `image_source` 聚合时固定为 `__ALL__` |
| `image_source` | string | 图片来源（用户上传图的渠道/类型）；当按 `search_entrance` 聚合时固定为 `__ALL__` |
| `is_ads` | string | 是否广告：`true` / `false` / `__ALL__`（`__ALL__` 表示该行为不区分广告的全量汇总） |

### 指标：用户规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `dau` | bigint | 图搜日活用户数（当日发生图搜 PV 的去重用户数） |
| `camera_uu` | bigint | 点击图搜入口按钮（拍照/图搜触发）的去重用户数 |
| `landing_rate_dau` | bigint | 从指定主要入口（HOME、SEARCH_RESULT、MALL、PRESEARCH、NSRP、RCMD_SEARCH_RESULT）进入图搜的去重用户数，用于计算图搜落地率分母 |

### 指标：查询量与结果量

| 字段 | 类型 | 说明 |
|---|---|---|
| `query_cnt` | bigint | 图搜查询总次数 |
| `image_search_result_volume` | bigint | 有搜索结果的图搜查询次数 |
| `image_search_non_result_volume` | bigint | 无搜索结果的图搜查询次数 |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 图搜商品曝光总次数 |
| `imp_uu` | bigint | 发生图搜商品曝光的去重用户数 |

### 指标：转化漏斗（PDP / 加购 / 下单 / GMV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 图搜商品详情页（PDP）浏览总次数 |
| `ppv_uu` | bigint | 发生 PDP 浏览的去重用户数 |
| `cart_cnt` | double | 加购次数（SUM 汇总，来自上游用户粒度加购数） |
| `cart_uu` | bigint | 发生加购行为的去重用户数 |
| `order_cnt` | double | 下单次数（SUM 汇总，来自上游用户粒度订单数） |
| `order_uu` | bigint | 发生下单行为的去重用户数 |
| `gmv` | double | 图搜带来的成交金额（SUM 汇总） |
| `eff_trans_uu` | bigint | 有效转化去重用户数（点击商品、点赞或加购任一行为发生的用户） |

### 指标：算法质量与用户行为位置

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_top1_similarity` | double | 图搜首位结果的平均相似度分（= `SUM(top1_similarity_sum)` / `SUM(top1_item_impression_cnt)`），反映搜索算法匹配质量 |
| `avg_click_location` | double | 用户点击商品的平均位置（= `SUM(click_location_sum)` / `SUM(image_search_item_click_cnt)`），越小说明用户越倾向点击靠前结果 |
| `avg_atc_location` | double | 用户加购商品的平均位置（= `SUM(atc_location_sum)` / `SUM(cart_cnt)`），注意：ETL 中该字段别名为 `avg_cart_location`，DataMap 记录为 `avg_atc_location` |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date`**，否则将触发全量分区扫描，产生极大计算开销。

```sql
WHERE grass_region = 'ID'
  AND local_date = '2025-05-16'
```

### 维度组合说明（避免重复计数）

本表通过 `UNION ALL` + `GROUPING SETS` 生成**多粒度汇总行**，同一日期分区内存在以下维度组合：

| `search_entrance` | `image_source` | `is_ads` | 含义 |
|---|---|---|---|
| 具体值 | `__ALL__` | `true` / `false` | 按入口+广告细分 |
| 具体值 | `__ALL__` | `__ALL__` | 按入口全量汇总 |
| `__ALL__` | 具体值 | `true` / `false` | 按图片来源+广告细分 |
| `__ALL__` | 具体值 | `__ALL__` | 按图片来源全量汇总 |
| `__ALL__` | `__ALL__` | `true` / `false` | 全量按广告细分 |
| `__ALL__` | `__ALL__` | `__ALL__` | 全量汇总行 |

**查询时务必通过 `search_entrance`、`image_source`、`is_ads` 精确过滤，避免多维度行被 SUM 叠加导致重复计数。**

### 不可直接 SUM 的字段

以下字段为**派生比率/加权均值**，跨行 SUM 无意义，需回溯上游分子分母重新计算：

| 字段 | 原因 |
|---|---|
| `avg_top1_similarity` | 加权均值，= `SUM(top1_similarity_sum)` / `SUM(top1_item_impression_cnt)` |
| `avg_click_location` | 加权均值，= `SUM(click_location_sum)` / `SUM(item_click_cnt)` |
| `avg_atc_location` | 加权均值，= `SUM(atc_location_sum)` / `SUM(cart_cnt)` |

以下字段为**去重用户数（UV）**，跨行 SUM 会造成重复计数：

`dau`、`camera_uu`、`landing_rate_dau`、`imp_uu`、`ppv_uu`、`cart_uu`、`order_uu`、`eff_trans_uu`

### 时效性说明

- 本表为 **`_1d` 天级快照表**，每天覆盖写入（`INSERT OVERWRITE`），数据通常在 T+1 产出。
- 不包含滚动窗口（无 `_nd`、`_td` 后缀语义），如需多日汇总需自行按 `local_date` 范围聚合，且 UV 类指标不可直接 SUM。

### 数据清洗注意

- `image_source` 中过滤了格式为 `{%` 的脏数据，因此 `image_source` 维度的汇总行不含该类异常值。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_image_search_entrance_user_metrics_1d` | 图搜用户粒度行为明细宽表，提供每用户每入口每天的图搜 PV、曝光、点击、加购、下单、GMV、相似度等所有原始度量，本表在其基础上聚合至去重 UV + SUM 级别 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_image_search_entrance_user_metrics_1d
    （用户 × 入口 × 日期粒度）
        │
        ▼  Statement 1：CREATE TEMPORARY VIEW
    image_search_aggregated_${grass_region_without_quote}
    （多维度 GROUPING SETS + UNION ALL 聚合）
        │
        ▼  Statement 2：INSERT OVERWRITE
    srdi_mart.dws_sr_data_warehouse_image_search_metrics_1d
    （分区：grass_region + local_date）
```

### 关键步骤

**Statement 1 — 创建临时视图 `image_search_aggregated_*`**

通过 3 段 `UNION ALL` 生成多粒度聚合结果，每段使用不同的 `GROUPING SETS`：

1. **按 `search_entrance` 聚合**：`image_source` 固定为 `__ALL__`，`GROUPING SETS((search_entrance, is_ads), (search_entrance))`，生成入口维度的细分行与汇总行；
2. **按 `image_source` 聚合**：`search_entrance` 固定为 `__ALL__`，过滤 `image_source NOT LIKE '{%'` 脏数据，`GROUPING SETS((image_source, is_ads), (image_source))`，生成图片来源维度的细分行与汇总行；
3. **全量聚合**：`search_entrance` 与 `image_source` 均为 `__ALL__`，`GROUPING SETS((is_ads), ())`，生成全量广告维度细分行与总汇总行。

所有 UV 类指标通过 `COUNT(DISTINCT IF(condition, user_id, NULL))` 计算；均值类指标通过 `SUM(分子) / SUM(分母)` 计算。

**Statement 2 — INSERT OVERWRITE 写目标表**

从临时视图读取数据，对 `is_ads` 字段做类型转换（boolean → string：`true`/`false`/`__ALL__`），按 `grass_region`、`local_date` 分区覆盖写入目标表。注意：ETL 中 `avg_cart_location` 对应 DataMap 中的 `avg_atc_location` 字段。

### 注意事项

- **单一 writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险。
- **分区覆盖写入**：每次执行为 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)`，同分区历史数据会被全量替换，重跑安全。
- **UNION ALL 行膨胀**：临时视图中同一日期分区理论上包含 6 类维度组合行（详见查询须知），直接聚合前必须确认维度过滤逻辑正确，避免多行累加导致指标翻倍。
- **脏数据过滤仅在 `image_source` 段生效**：`image_source NOT LIKE '{%'` 过滤仅应用于第 2 段 UNION，`search_entrance` 汇总段和全量汇总段不含此过滤，因此按 `search_entrance` 维度统计的指标可能包含少量异常 `image_source` 数据。
- **注释说明**：SQL 注释明确指出由于上游表中存在 NULL 和空值，`is_ads` 的维度展开若用单一大 `GROUPING SETS` 会产生歧义，故拆分为 3 段 UNION ALL 分别处理。

---

*文档生成时间：2026-05-17*