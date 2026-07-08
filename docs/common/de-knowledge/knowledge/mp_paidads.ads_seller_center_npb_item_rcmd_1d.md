<!-- ads-workspace-gdoc-sync: gdoc_id=1sxgNZ0YDE8H1U7w_IUmMUdxaAiX6ck3CAGFIGHE6hL0 gdoc_url=https://docs.google.com/document/d/1sxgNZ0YDE8H1U7w_IUmMUdxaAiX6ck3CAGFIGHE6hL0/edit -->

# mp_paidads.ads_seller_center_npb_item_rcmd_1d

**分层**：ADS（应用数据层）
**主键**：`shop_id` + `item_id`（在同一分区内唯一标识一条商品推荐记录）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1 刷新，覆盖当日分区）
**引用频次**：0（末端 ADS 层表，通常由业务系统或下游服务直接消费）

---

## 业务描述

本表是卖家中心（Seller Center）**新品加速（New Product Boost，NPB）**功能的每日商品推荐结果表。ETL 每天从平台商品库中筛选出近 90 天内上架的新品，结合 NPB 预测评分模型、历史平台订单表现、库存与价格信息，为每个符合条件的商品计算推荐类型（`rcmd_npb_type`）和推荐得分（`rcmd_npb_score`），并将结构化字段序列化为 `value` 字符串，以供下游推荐服务快速读取和分发。

本表的核心价值在于：将多源异构数据（商品基础信息、机器学习预测分、订单统计、库存价格）聚合为一张"开箱即用"的推荐候选集，使推荐服务只需按地区和日期分区扫描本表即可获得当天所有 NPB 候选商品及其完整特征，无需在线实时 JOIN。`key` 字段遵循统一的 Redis/缓存 key 格式，可直接用于推荐系统的批量写入场景。

各地区按本地时区参数化调度，实现全球多市场的一致化生产；`tz_type='local'` 分区确保时间口径与各地区业务日期对齐，避免跨时区数据错位。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `tz_type` | string | 时区类型标识。当前 ETL 仅写入 `'local'`（各地区本地时区），查询时**必须过滤** `tz_type = 'local'` 以避免全表扫描或逻辑错误。 |
| `grass_region` | string | 地区/市场代码，大写，如 `'MX'`、`'TH'`、`'VN'` 等；各地区独立分区存储，查询时应指定目标地区。 |
| `grass_date` | date | 业务日期（各地区本地时区），格式 `YYYY-MM-DD`；对应 ETL 调度的 `${grass_date}` 参数，每日覆盖写入。 |

---

### 维度：主键与推荐标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID，与 `item_id` 共同构成表内主键。 |
| `item_id` | bigint | 商品 ID，与 `shop_id` 共同构成表内主键。 |
| `key` | string | 推荐系统缓存/Redis Key，格式为 `item_{REGION}_{item_id}:new_product_boost`。⚠️ 为派生拼接字段，仅用于系统写入，不应用于业务聚合统计。 |
| `value` | string | 序列化的商品推荐特征字符串，由自定义 UDF `marshal_item` 将 `(item_id, l30d_sold, stock, time_added, price, rcmd_npb_type)` 编码生成。⚠️ 为二进制序列化结果，不可直接解读或 SUM，如需明细请使用同行的原始字段。 |

---

### 维度：商品推荐分类

| 字段名 | 类型 | 说明 |
|---|---|---|
| `rcmd_npb_type` | int | NPB 推荐类型，区分商品所处的新品成长阶段：**1** = 新品零单（上架 ≤10 天且累计平台订单为 0，NPB 评分 ≥0.5）；**2** = 新品起量（上架 ≤20 天且累计平台订单 1~20 单、日均订单 ≥0.3，NPB 评分 ≥0.5）；**3** = 其他。⚠️ 枚举值含义由业务规则硬编码，若规则变更需同步更新下游消费逻辑。 |

---

### 指标：NPB 评分与订单表现

| 字段名 | 类型 | 说明 |
|---|---|---|
| `rcmd_npb_score` | double | NPB 推荐预测评分，来源于机器学习模型（`new_item_card_online_item_predict_score_10d_replace_rcmd`），取近 20 天内最新预测分。⚠️ 为模型输出的预测概率/评分，不可直接 SUM，跨商品比较时需注意模型版本一致性。 |
| `ado` | double | 平台日均订单量（Average Daily Orders），来源于 `ads_simple_roi2_npb_item_hi` 的 `platform_order_avg` 字段，取当日 `h=1`（小时粒度）快照。⚠️ 为预计算均值，不可直接 SUM 求多商品合计，需用原始订单数据重新汇总。 |
| `create_day_cnt` | double | 商品上架至调度执行日的天数（含小数，精确到 4 位小数），基于本地时区零点计算。⚠️ 为派生计算字段，不可直接 SUM；该值在每日 ETL 写入时固化，反映写入当天的"商品年龄"。 |

---

### 指标：商品库存与交易

| 字段名 | 类型 | 说明 |
|---|---|---|
| `l30d_sold` | bigint | 近 30 天商品销售量，来源于 `rcmd_score_stats`。⚠️ 该值为上游表快照统计值，口径以 `rcmd_score_stats` 的计算逻辑为准，直接 SUM 多行时需确认商品不重复。 |
| `stock` | bigint | 当前商品库存数量，来源于 `rcmd_score_stats`。反映调度日的库存快照，存在一定数据延迟。 |
| `price` | bigint | 商品价格（单位由上游表 `rcmd_score_stats` 决定，通常为各地区最小货币单位，如分/分币）。⚠️ 存储为整型，使用时需确认货币单位换算比例。 |
| `time_added` | bigint | 商品上架时间戳（Unix 时间戳，秒级），来源于 `mp_item.rt_dim_item` 的 `create_timestamp` 字段。⚠️ 为 Unix 时间戳，展示时需转换为可读日期，注意时区换算。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全表扫描，造成巨大的计算资源浪费：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|---|---|---|
| `tz_type` | `tz_type = 'local'` | ETL 目前仅写入 `local` 分区，不过滤仍会扫描所有 tz_type 分区（含历史潜在分区），且无业务意义 |
| `grass_region` | `grass_region = 'TH'`（替换为目标地区） | 返回全球所有市场数据，结果混杂，通常无意义 |
| `grass_date` | `grass_date = DATE('2026-04-21')` | 扫描全量历史分区，性能极差，且 NPB 推荐结果有强时效性，历史数据无参考价值 |

**示例（正确写法）**：
```sql
SELECT *
FROM mp_paidads.ads_seller_center_npb_item_rcmd_1d
WHERE tz_type = 'local'
  AND grass_region = 'TH'
  AND grass_date = DATE('2026-04-21');
```

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确处理方式 |
|---|---|---|
| `rcmd_npb_score` | 模型预测评分，无加和业务含义 | 用于排序（`ORDER BY rcmd_npb_score DESC`）或分布统计（`AVG`、`PERCENTILE`） |
| `ado` | 预计算的日均订单均值，直接 SUM 无意义 | 如需汇总多商品订单量，回溯上游 `ads_simple_roi2_npb_item_hi` 原始订单数据 |
| `create_day_cnt` | 派生的"商品年龄"天数，SUM 无实际意义 | 用于条件过滤（如 `create_day_cnt <= 20`）或分布分析 |
| `value` | 序列化二进制字符串 | 直接透传给推荐系统，不做 SQL 层聚合 |
| `key` | 拼接的缓存 Key 字符串 | 直接透传给推荐系统，不做 SQL 层聚合 |
| `price` | 整型存储的价格，单位为最小货币单位 | 展示时除以对应倍率（如 100）转换为标准货币单位 |

### 时效性说明

- 本表为**每日全量覆盖写入**，每个 `(tz_type, grass_region, grass_date)` 分区仅代表当天的 NPB 候选商品快照，历史分区不会追溯更新。
- `ado` 字段来源于 `ads_simple_roi2_npb_item_hi` 的 `h=1` 快照（当日最早小时粒度），可能与全天最终值存在偏差。
- `stock`、`price`、`l30d_sold` 来源于 `rcmd_score_stats`，以上游表的数据延迟为准，通常为 T+1 快照。
- 推荐使用最新 `grass_date` 分区（即最近一个已完成调度的日期）获取最新推荐候选集。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_item.rt_dim_item__reg_s0_live` | 商品基础信息来源：筛选近 90 天内状态有效（`status=1`）的新品，获取 `item_id`、`shop_id`、`create_timestamp`，并过滤特定标签商品 |
| `mp_item.dim_item_label_with_level__reg_s0_live` | 商品标签黑名单：排除持有特定 `label_id`（841356053736030、843249807227517、298553329）的商品，确保推荐质量 |
| `szci_traffic.new_item_card_online_item_predict_score_10d_replace_rcmd` | NPB 机器学习预测评分来源：取近 20 天内最新一条 `pred_score` 作为 `rcmd_npb_score` |
| `mp_paidads.ads_simple_roi2_npb_item_hi__reg_s0_live` | 商品平台订单表现来源：提供 `platform_order_avg`（日均订单，即 `ado`）和 `platform_order_acc`（累计订单），用于 `rcmd_npb_type` 分类判断 |
| `mkplpaidads_data.rcmd_score_stats` | 商品库存与交易快照来源：提供 `stock`（库存）、`price`（价格）、`l30d_sold`（近 30 天销量） |

---

## ETL 逻辑摘要

### 数据流

```
mp_item.rt_dim_item__reg_s0_live
  (近90天新品, status=1)
          │
          │  排除黑名单标签
mp_item.dim_item_label_with_level__reg_s0_live
  (label_id黑名单过滤)
          │
          ▼
     [base_a: 商品基础信息]
     item_id, shop_id, create_timestamp,
     create_day_cnt (本地时区计算)
          │
          ├──────────────────────────────────────┐
          │                                      │
          │  LEFT JOIN on item_id, shop_id       │  LEFT JOIN on item_id
          ▼                                      ▼
szci_traffic.                         mp_paidads.
new_item_card_online_item_            ads_simple_roi2_npb_item_hi
predict_score_10d_replace_rcmd        (tz_type='local', h=1)
  (取最新 pred_score → npb_score)       platform_order_avg → ado
                                        platform_order_acc
          │                                      │
          └──────────────┬───────────────────────┘
                         │
                         │  LEFT JOIN on shop_id, item_id
                         ▼
               mkplpaidads_data.rcmd_score_stats
               (stock, price, l30d_sold)
                         │
                         ▼
              [base_item_90: 完整特征集]
              计算 rcmd_npb_type (1/2/3)
                         │
                         │  marshal_item UDF 序列化 → value
                         │  拼接 key 字符串
                         ▼
ads_seller_center_npb_item_rcmd_1d__reg_s0_live
  PARTITION(tz_type='local', grass_region, grass_date)
  INSERT OVERWRITE（全量覆盖当日分区）
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|---|---|---|
| `base_item_90`（临时视图） | `mp_item.rt_dim_item`（主）+ `dim_item_label_with_level`（黑名单）+ `new_item_card_online_item_predict_score_10d_replace_rcmd`（NPB 评分）+ `ads_simple_roi2_npb_item_hi`（订单表现）+ `rcmd_score_stats`（库存价格） | 核心宽表视图：筛选近 90 天新品、关联所有特征维度、计算 `create_day_cnt` 和 `rcmd_npb_type` 分类规则，为最终 INSERT 提供完整行数据 |

### 注意事项

1. **黑名单过滤**：ETL 使用 `NOT IN` 子查询排除特定 `label_id` 商品（841356053736030、843249807227517、298553329），这些标签对应平台定义的不宜参与 NPB 的商品类型。若黑名单标签 ID 发生变更，需同步修改 ETL 逻辑。

2. **NPB 评分 LEFT JOIN 的空值风险**：`rcmd_npb_score` 来源于评分表的 LEFT JOIN，若某商品近 20 天内无预测记录，则 `rcmd_npb_score` 为 NULL。`rcmd_npb_type` 的分类判断依赖 `npb_score >= 0.5`，NULL 值将导致该商品归入 `type=3`（其他）分支，属于预期行为。

3. **`rcmd_npb_type` 分类规则硬编码**：三类商品的划分逻辑（上架天数、累计订单、日均订单、评分阈值）直接写在 ETL SQL 的 CASE WHEN 中，业务规则调整需修改 SQL 并重新调度历史分区。

4. **`value` 字段的 UDF 序列化**：`marshal_item` 为自定义 Hive UDF（`com.shopee.deepdata.warehouse.hive.udf.MarshalNpbItem`），序列化格式与推荐系统强耦合。若 UDF 版本升级，需确认下游服务的反序列化兼容性。

5. **`create_day_cnt` 的时区计算**：天数基于 SGT（新加坡时间）转换为各地区本地时区后的零点计算，确保"商品年龄"与业务日期定义一致，各地区按本地时区参数化调度。

6. **INSERT OVERWRITE 覆盖写入**：每次调度对 `(tz_type='local', grass_region, grass_date)` 分区执行全量覆盖，历史分区数据不会追溯修改。若当日调度失败需补数，需手动触发重跑。

---

*文档生成时间：2026-04-22*