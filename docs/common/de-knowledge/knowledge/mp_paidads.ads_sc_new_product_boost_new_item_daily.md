<!-- ads-workspace-gdoc-sync: gdoc_id=1DXqu0cd8EaEtEgkGIYAMukSTs6u4DL6sKHla8wCLiYI gdoc_url=https://docs.google.com/document/d/1DXqu0cd8EaEtEgkGIYAMukSTs6u4DL6sKHla8wCLiYI/edit -->

# mp_paidads.ads_sc_new_product_boost_new_item_daily

**分层**：ADS（应用数据层）
**主键**：`item_id`
**分区**：`grass_region`（地区）/ `grass_date`（业务日期）
**更新频率**：每日调度（T+1，覆盖前一业务日）
**引用频次**：0（末端 ADS 层表，本身作为下游表 `ads_sc_new_product_boost_high_quality_item_daily` 的直接数据源）

---

## 业务描述

本表为 **新品广告（New Product Boost / NPA）** 场景下的新商品候选池每日快照表，服务于 Shopee 付费广告智能投放体系。其数据范围限定为：**近 30 天内创建、商品状态为在售（item_status = 1）、且未被特定标签标记的商品**，并关联模型预测分与 CSPU 类型，形成每日最新的新品广告候选集合。

本表的核心价值在于对新品进行多维度质量分层：通过 `pred_score_final`（流量模型预测分）标记高质量商品（`is_high_quality_item`），通过 `cspu_type`（商品类型）与预测分组合判定高优先级商品（`is_high_priority_item`），并据此推导出三档优先级标签（`item_priority`：P0/P1/P2）。分层结果直接决定商品是否进入下游 Redis 缓存、是否参与广告自动投放。

本表定位为**分析用途**（SQL 注释中明确标注 `only for analysis`），下游消费者可基于本表开展新品广告覆盖率、质量分布、优先级结构等专题分析。高优先级商品会被进一步汇聚至 `ads_sc_new_product_boost_high_quality_item_daily` 及 `ads_sc_new_product_boost_high_quality_shop_daily`，经序列化后写入 Redis 供线上实时调用。各地区按本地时区参数化调度，全量覆盖 Shopee 各运营市场。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区编码（大写），如 `MY`、`TH`、`SG` 等，由调度参数 `${region}` 参数化生成，覆盖所有 Shopee 运营市场 |
| `grass_date` | date | 业务日期，取前一业务日（`${BIZ_YESTERDAY}`），每日刷新 |

### 维度：商品与店铺标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID，本表主键 |
| `shop_id` | bigint | 商品所属店铺 ID |
| `ctime` | bigint | 商品创建时间戳（Unix 毫秒级或秒级，来源于 `mp_item.rt_dim_item` 的 `create_timestamp`）⚠️ 具体时间精度依赖上游字段定义，使用前需确认单位（秒/毫秒），不可直接用于时间比较 |

### 维度：商品质量与优先级分层

| 字段 | 类型 | 说明 |
|------|------|------|
| `cspu_type` | bigint | 商品 CSPU 类型编码，来源于 `srdi_mart.dim_sr_data_warehouse_tc_ni_cspu_type`，决定商品基础优先级分层；若上游无匹配则为 `null` |
| `item_priority` | string | 商品优先级标签，由 `cspu_type` 推导：`cspu_type IN (1,4)` → `'P0'`；`cspu_type IN (3,6)` → `'P1'`；`cspu_type IN (2,8)` → `'P2'`；其余值返回 `null`⚠️ 为派生枚举字段，不可聚合统计时直接 SUM，应使用 `COUNT` + `GROUP BY` 做分布分析 |
| `is_high_quality_item` | tinyint | 是否为高质量商品：`pred_score_final >= 0.8` 时为 `1`，`< 0.8` 时为 `0`，若模型无评分（`b.pred_score_final IS NULL`）则为 `null`⚠️ 存在三值逻辑（0/1/null），过滤高质量商品时应写 `is_high_quality_item = 1`，而非 `is_high_quality_item != 0` |
| `is_high_priority_item` | tinyint | 是否为高优先级商品（决定是否写入 Redis 参与投放）：`cspu_type IN (1,4)` 或 `pred_score_final >= 0.8` 时为 `1`，否则为 `0`（缺失评分按 0 处理，通过 `COALESCE(b.pred_score_final, 0)` 兜底）⚠️ 此字段综合了 cspu_type 与 pred_score_final 两个维度，不等价于 `is_high_quality_item = 1`；P0 商品（cspu_type IN (1,4)）无论评分高低均为高优先级 |

### 指标：流量模型预测分

| 字段 | 类型 | 说明 |
|------|------|------|
| `pred_score_final` | double | 新品流量模型最终预测分，来源于 `szci_traffic.new_item_model_score_reg_live_for_ads`，取值范围通常为 `[0, 1]`；若上游模型无该商品评分则为 `null`⚠️ 为模型输出的连续概率值，不可直接 SUM；跨商品比较时应使用分位数或均值；聚合分析时需注意 null 值对 AVG 计算的影响 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下两个分区字段**，避免全表扫描导致性能问题和跨地区数据混用：

```sql
WHERE grass_region = 'SG'          -- 替换为目标地区大写编码
  AND grass_date = '2025-04-21'    -- 替换为目标业务日期
```

- **`grass_region`**：必须使用**大写**地区编码（ETL 通过 `upper('${region}')` 写入），若使用小写将命中空分区，返回空结果集。
- **`grass_date`**：每日全量覆盖写入，不加日期过滤将扫描全部历史分区，产生大量重复数据及额外计算开销。
- 遗漏任一分区过滤条件，将触发全表扫描（Hive PARQUET 格式），在大规模集群上可能引发资源超限或查询超时。

### 不可直接 SUM 的字段

| 字段 | 问题类型 | 正确使用方式 |
|------|----------|--------------|
| `pred_score_final` | 连续概率值 | 使用 `AVG(pred_score_final)`、`PERCENTILE_APPROX` 等，统计时需用 `WHERE pred_score_final IS NOT NULL` 或明确处理 null |
| `item_priority` | 枚举派生字段 | 使用 `COUNT(*)`、`COUNT(CASE WHEN item_priority = 'P0' THEN 1 END)` 做分布统计，不可 SUM |
| `is_high_quality_item` | 三值逻辑（0/1/null） | 统计高质量商品数用 `SUM(CASE WHEN is_high_quality_item = 1 THEN 1 ELSE 0 END)`，分母需排除 null（`WHERE is_high_quality_item IS NOT NULL`）后再计算比率 |
| `is_high_priority_item` | 派生标志位 | 统计高优先级商品数用 `SUM(is_high_priority_item)`（无 null，COALESCE 已兜底），但计算占比时分母应为全量商品数而非该字段的 SUM |
| `ctime` | 时间戳单位待确认 | 转换为可读时间前需先确认是秒级还是毫秒级，建议使用 `FROM_UNIXTIME(ctime)` 或 `FROM_UNIXTIME(ctime/1000)` 并与 `create_datetime` 原始字段比对验证 |

### 时效性说明

- 本表每日写入前一业务日（`${BIZ_YESTERDAY}`）数据，**查询当天最新候选池应使用前一日分区**（即 `grass_date = CURRENT_DATE - 1`），当日分区在调度完成前不可用。
- `pred_score_final` 来源于 `szci_traffic.new_item_model_score_reg_live_for_ads` 的对应分区，模型评分存在 T+1 延迟，新品在创建当天可能无模型分（`null`），需在分析中特别处理。
- 商品候选池基于**近 30 天创建**商品，历史分区中的商品在当日分区中可能因创建时间超出 30 天窗口而消失，历史分区对比时需注意此动态变化。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_item.rt_dim_item__reg_s0_live` | 商品基础维表，提供 `item_id`、`shop_id`、`create_timestamp`（ctime）、`status`、`grass_region` 等核心商品信息；过滤条件：`status = 1`、近 30 天创建 |
| `mp_item.dim_item_label_with_level__reg_s0_live` | 商品标签维表，用于排除携带特定标签（`label_id IN (841356053736030, 843249807227517, 298553329)`）的商品（LEFT ANTI JOIN） |
| `szci_traffic.new_item_model_score_reg_live_for_ads` | 新品流量模型评分表，提供 `pred_score_final`，用于商品质量分层 |
| `srdi_mart.dim_sr_data_warehouse_tc_ni_cspu_type` | CSPU 类型维表，提供 `cspu_type`，用于商品优先级分层（P0/P1/P2） |

---

## ETL 逻辑摘要

### 数据流

```
mp_item.rt_dim_item__reg_s0_live
  (status=1, 近30天创建)
          │
          │  LEFT ANTI JOIN（排除特定标签商品）
          │◄──────────────────────────────────────────
          │                                            │
          │                     mp_item.dim_item_label_with_level__reg_s0_live
          │                     (label_id IN (841356053736030,843249807227517,298553329))
          │
          │  [子查询 a: 新品候选集]
          │
          ├──── LEFT JOIN ────────────────────────────►
          │                szci_traffic.new_item_model_score_reg_live_for_ads
          │                (pred_score_final，按 item_id 关联)
          │
          ├──── LEFT JOIN ────────────────────────────►
          │                srdi_mart.dim_sr_data_warehouse_tc_ni_cspu_type
          │                (cspu_type，按 item_id 关联)
          │
          ▼
ads_sc_new_product_boost_new_item_daily__reg_s0_live
  [本表：新品候选池 + 质量/优先级分层]
          │
          │  WHERE is_high_priority_item = 1
          ▼
ads_sc_new_product_boost_high_quality_item_daily__reg_s0_live
  [高优先级商品表，含 Redis key/value 序列化]
          │
          │  GROUP BY shop_id, collect_list, row_number <= 500
          ▼
ads_sc_new_product_boost_high_quality_shop_daily__reg_s0_live
  [店铺级高质量商品汇总表，含 Redis key/value 序列化]
```

### 关键 CTE 说明

本 ETL 未使用命名 CTE，以内联子查询实现数据加工，关键子查询逻辑如下：

| 子查询别名 | 来源表 | 作用 |
|------------|--------|------|
| `a`（内联子查询） | `mp_item.rt_dim_item__reg_s0_live` LEFT ANTI JOIN `mp_item.dim_item_label_with_level__reg_s0_live` | 筛选近 30 天创建、状态为 1 且不携带特定排除标签的新品候选集 |
| `b`（LEFT JOIN） | `szci_traffic.new_item_model_score_reg_live_for_ads` | 按 `item_id` 关联模型预测分，无匹配则为 null |
| `c`（LEFT JOIN） | `srdi_mart.dim_sr_data_warehouse_tc_ni_cspu_type` | 按 `item_id` 关联 CSPU 商品类型，无匹配则为 null |

### 注意事项

1. **LEFT ANTI JOIN 排除逻辑**：ETL 通过 LEFT ANTI JOIN 排除携带 `label_id IN (841356053736030, 843249807227517, 298553329)` 的商品，这些标签对应特定业务标记（如违规、下架风险等）。分析时若发现商品缺失，应优先排查是否被标签过滤。

2. **`is_high_priority_item` 的 COALESCE 处理**：对于无模型评分（`pred_score_final IS NULL`）的商品，ETL 通过 `COALESCE(b.pred_score_final, 0)` 将缺失分数视为 0，因此此类商品 `is_high_priority_item = 0`（除非 `cspu_type IN (1,4)`）。这意味着新上架商品因无评分数据而默认被排除在高优先级之外。

3. **`is_high_quality_item` 与 `is_high_priority_item` 的口径差异**：
   - `is_high_quality_item`：纯粹基于 `pred_score_final >= 0.8`，无评分则为 `null`
   - `is_high_priority_item`：综合 cspu_type（P0 商品直接为 1）和评分（缺失按 0 兜底），无 null 值
   - P0 商品（cspu_type IN (1,4)）的 `is_high_quality_item` 可能为 0 或 null，但 `is_high_priority_item` 始终为 1，两字段不可互换使用。

4. **本表为分析表，下游 Redis 写入由子表完成**：本表注释明确为 `only for analysis`，实际的在线服务数据通过 `ads_sc_new_product_boost_high_quality_item_daily` 和 `ads_sc_new_product_boost_high_quality_shop_daily` 序列化写入 Redis，后两张表使用自定义 UDF（`MarshalNPAItem`、`MarshalNPAShop`）进行二进制序列化，key 格式分别为 `item_{region}_{item_id}:npa` 和 `shop_{region}_{shop_id}:npa`。

5. **店铺商品列表截断**：下游店铺表每个 `shop_id` 最多保留 **500 个商品**（按 `ctime ASC` 排序后取 `row_number <= 500`），即优先保留最早创建的高优先级商品，超出部分丢弃。

6. **参数化调度覆盖全地区**：ETL 通过 `${region}`、`${BIZ_YESTERDAY}`、`${PREV_30D}` 等调度参数驱动，各地区按本地时区参数化调度，全量覆盖 Shopee 各运营市场，SQL 中出现的具体地区代码仅为模板实例，不代表表的数据范围限于单一市场。

---

*文档生成时间：2026-04-22*