<!-- ads-workspace-gdoc-sync: gdoc_id=147K-LN_0SR41hwVgryKVApy7yyrg6PZ5mYswJTfl0M0 gdoc_url=https://docs.google.com/document/d/147K-LN_0SR41hwVgryKVApy7yyrg6PZ5mYswJTfl0M0/edit -->

# mp_paidads.dws_advertiser_trd_order_gmv_nd

**分层**：DWS（数据服务层 / 汇总宽表）
**主键**：`shop_id` + `user_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1），各地区按本地时区参数化调度
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表是广告主维度的交易订单 GMV 多滑动窗口汇总宽表，以店铺（`shop_id` / `user_id`）为粒度，按本地日期分区，预计算过去 1 天、7 天、30 天、60 天、90 天共五个滑动时间窗口内的核心电商交易指标，包括 GMV（本币及美元）、订单数、买家数、商品件数等。

本表的核心价值在于为付费广告（Paid Ads）业务的效果归因与投放决策提供高质量的卖家侧交易基础数据。下游可直接读取任意时间窗口的预聚合值，无需在查询层再做滑动窗口计算，显著降低查询复杂度与计算成本。典型使用场景包括：广告主绩效报表、ROAS 分析、广告投放策略优化、买家复购行为分析等。

数据来源于广告主维表（`mp_paidads.dim_advertiser`）与卖家/商品 GMV 事实表（`mp_order.dws_seller_gmv_1d`、`mp_order.dws_item_gmv_1d`）的关联结果，以广告主维表为驱动表做 LEFT JOIN，确保所有在册广告主均有记录（无交易数据的字段默认填充为 0）。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `tz_type` | string | 时区类型分区。ETL 固定写入 `'local'`（本地时区），查询时必须指定 `tz_type = 'local'` 以避免全表扫描。⚠️ 目前仅有 `local` 分区，若遗漏该过滤条件将扫描全量数据分区。 |
| `grass_region` | string | 地区分区，存储大写地区代码（如 `'MX'`、`'SG'` 等）。各地区通过 `${region}` 参数独立调度写入。⚠️ 查询时必须指定具体地区以避免跨区扫描。 |
| `grass_date` | date | 日期分区，格式为 `YYYY-MM-DD`，对应本地时区下的业务日期。⚠️ 查询时必须指定具体日期或日期范围，避免全分区扫描。 |

---

### 维度：主键与广告主属性

| 字段名 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID，联合主键之一。来源于 `mp_paidads.dim_advertiser`，为广告主维表中的注册店铺标识。 |
| `user_id` | bigint | 用户 ID（广告主账号 ID），联合主键之一。来源于 `mp_paidads.dim_advertiser`。 |

---

### 指标：买家数（滑动窗口）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `buyer_cnt_1d` | bigint | 过去 1 天内向该卖家下单的独立买家数（对应 `grass_date` 当天）。NULL 已被 COALESCE 替换为 0。 |
| `buyer_cnt_7d` | bigint | 过去 7 天内向该卖家下单的独立买家数（`grass_date` 往前滚动 6 天，共 7 天）。NULL 已被 COALESCE 替换为 0。⚠️ 本字段为时间窗口累计值，跨多个 `grass_date` 分区直接 SUM 会造成重复计算，应仅取单日分区值使用。 |
| `buyer_cnt_30d` | bigint | 过去 30 天内向该卖家下单的独立买家数。NULL 已被 COALESCE 替换为 0。⚠️ 同上，跨分区 SUM 会造成重复计算。 |
| `buyer_cnt_60d` | bigint | 过去 60 天内向该卖家下单的独立买家数。NULL 已被 COALESCE 替换为 0。⚠️ 同上，跨分区 SUM 会造成重复计算。 |
| `buyer_cnt_90d` | bigint | 过去 90 天内向该卖家下单的独立买家数。NULL 已被 COALESCE 替换为 0。⚠️ 同上，跨分区 SUM 会造成重复计算。 |

---

### 指标：订单数（滑动窗口）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `order_cnt_1d` | bigint | 过去 1 天内的订单数量（来源：`mp_order.dws_seller_gmv_1d`）。NULL 已被 COALESCE 替换为 0。 |
| `order_cnt_7d` | bigint | 过去 7 天内的订单数量。NULL 已被 COALESCE 替换为 0。⚠️ 为滑动窗口累计值，跨分区 SUM 会造成重复计算。 |
| `order_cnt_30d` | bigint | 过去 30 天内的订单数量。NULL 已被 COALESCE 替换为 0。⚠️ 同上。 |
| `order_cnt_60d` | bigint | 过去 60 天内的订单数量。NULL 已被 COALESCE 替换为 0。⚠️ 同上。 |
| `order_cnt_90d` | bigint | 过去 90 天内的订单数量。NULL 已被 COALESCE 替换为 0。⚠️ 同上。 |

---

### 指标：商品维度订单件数（滑动窗口）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `order_item_cnt_1d` | bigint | 过去 1 天内以 SKU/Item 为粒度的订单数汇总（来源：`mp_order.dws_item_gmv_1d.placed_order_cnt_1d` 按 `shop_id` 聚合）。与 `order_cnt_1d` 口径不同：前者以商品维度计，后者以订单维度计。NULL 已被 COALESCE 替换为 0。⚠️ 注意与 `order_cnt_*d` 的语义区别，两者数值不可互换。 |
| `order_item_cnt_7d` | bigint | 过去 7 天内以商品维度的订单数汇总。NULL 已被 COALESCE 替换为 0。⚠️ 滑动窗口累计值，跨分区 SUM 会造成重复计算。 |
| `order_item_cnt_30d` | bigint | 过去 30 天内以商品维度的订单数汇总。NULL 已被 COALESCE 替换为 0。⚠️ 同上。 |
| `order_item_cnt_60d` | bigint | 过去 60 天内以商品维度的订单数汇总。NULL 已被 COALESCE 替换为 0。⚠️ 同上。 |
| `order_item_cnt_90d` | bigint | 过去 90 天内以商品维度的订单数汇总。NULL 已被 COALESCE 替换为 0。⚠️ 同上。 |

---

### 指标：售出商品件数（滑动窗口）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `items_sold_cnt_1d` | bigint | 过去 1 天内顾客订单中的商品总件数（来源：`mp_order.dws_seller_gmv_1d.placed_item_cnt_1d`）。NULL 已被 COALESCE 替换为 0。 |
| `items_sold_cnt_7d` | bigint | 过去 7 天内商品售出总件数。NULL 已被 COALESCE 替换为 0。⚠️ 滑动窗口累计值，跨分区 SUM 会造成重复计算。 |
| `items_sold_cnt_30d` | bigint | 过去 30 天内商品售出总件数。NULL 已被 COALESCE 替换为 0。⚠️ 同上。 |
| `items_sold_cnt_60d` | bigint | 过去 60 天内商品售出总件数。NULL 已被 COALESCE 替换为 0。⚠️ 同上。 |
| `items_sold_cnt_90d` | bigint | 过去 90 天内商品售出总件数。NULL 已被 COALESCE 替换为 0。⚠️ 同上。 |

---

### 指标：本币 GMV（滑动窗口）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `gmv_1d` | double | 过去 1 天的总商品交易额（本地货币计价）。NULL 已被 COALESCE 替换为 0.0。 |
| `gmv_7d` | double | 过去 7 天的总 GMV（本地货币）。NULL 已被 COALESCE 替换为 0.0。⚠️ 滑动窗口累计值，跨分区 SUM 会造成重复计算，应仅取单一 `grass_date` 分区使用。 |
| `gmv_30d` | double | 过去 30 天的总 GMV（本地货币）。NULL 已被 COALESCE 替换为 0.0。⚠️ 同上。 |
| `gmv_60d` | double | 过去 60 天的总 GMV（本地货币）。NULL 已被 COALESCE 替换为 0.0。⚠️ 同上。 |
| `gmv_90d` | double | 过去 90 天的总 GMV（本地货币）。NULL 已被 COALESCE 替换为 0.0。⚠️ 同上。 |

---

### 指标：美元 GMV（滑动窗口）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `gmv_usd_1d` | double | 过去 1 天的总 GMV（美元计价）。NULL 已被 COALESCE 替换为 0.0。 |
| `gmv_usd_7d` | double | 过去 7 天的总 GMV（美元）。NULL 已被 COALESCE 替换为 0.0。⚠️ 滑动窗口累计值，跨分区 SUM 会造成重复计算。 |
| `gmv_usd_30d` | double | 过去 30 天的总 GMV（美元）。NULL 已被 COALESCE 替换为 0.0。⚠️ 同上。 |
| `gmv_usd_60d` | double | 过去 60 天的总 GMV（美元）。NULL 已被 COALESCE 替换为 0.0。⚠️ 同上。 |
| `gmv_usd_90d` | double | 过去 90 天的总 GMV（美元）。NULL 已被 COALESCE 替换为 0.0。⚠️ 同上。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区过滤条件，否则将触发全表扫描，产生极高的计算成本和无效的跨区数据混合：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|---|---|---|
| `tz_type` | `tz_type = 'local'` | 当前仅有 `local` 分区，遗漏不过滤会扫描所有 `tz_type` 分区（含可能的历史遗留分区） |
| `grass_region` | `grass_region = 'SG'`（具体地区代码，大写） | 混合多地区数据，货币单位不统一，`gmv_*d` 本币字段的数值将失去意义 |
| `grass_date` | `grass_date = DATE('2026-04-21')` | 扫描全量历史分区，性能极差；且由于字段为滑动窗口值，跨日期 SUM 会导致数据严重重复计算 |

```sql
-- ✅ 正确示例
SELECT shop_id, user_id, gmv_7d, gmv_usd_30d
FROM mp_paidads.dws_advertiser_trd_order_gmv_nd__reg_s0_live
WHERE tz_type = 'local'
  AND grass_region = 'SG'
  AND grass_date = DATE('2026-04-21');
```

### 不可直接 SUM 的字段

本表所有带 `_7d` / `_30d` / `_60d` / `_90d` 后缀的字段均为**滑动时间窗口预聚合值**，在某一 `grass_date` 分区下已包含过去 N 天的完整累计结果。

⚠️ **跨多个 `grass_date` 分区对这些字段 SUM，会造成严重的重复计算。**

| 错误用法 | 正确用法 |
|---|---|
| `SUM(gmv_30d)` over 多个 `grass_date` | 仅取**单一** `grass_date` 分区，直接读取 `gmv_30d` 值；如需趋势对比，对每个日期分别取值后在应用层计算 |
| `SUM(buyer_cnt_7d)` over 多个 `shop_id` | ✅ 可以：在**同一 `grass_date`** 下对不同 `shop_id` SUM，含义为该时间窗口内所有店铺的汇总值（注意 buyer 可能跨店铺重叠，`buyer_cnt_*d` 按店铺统计，跨店 SUM 无去重） |
| `SUM(order_cnt_30d)` over 多个 `grass_date` | 仅取目标日期单分区的 `order_cnt_30d` |

此外，`order_item_cnt_*d` 与 `order_cnt_*d` 口径不同（前者为商品维度订单聚合，后者为订单维度），**两者不可互换使用**，请根据业务需求选择合适字段。

### 时效性说明

本表各 `grass_date` 分区为 INSERT OVERWRITE 全量覆写，每日调度写入截止 `grass_date` 当天的滑动窗口数据。

- **读取最新数据**：查询时取 `grass_date = CURRENT_DATE - INTERVAL 1 DAY`（即昨日分区），因调度为 T+1，当天分区在调度完成前数据不完整。
- `_1d` 字段对应 `grass_date` 当天（即 `is_today = 1`），`_7d` 至 `_90d` 字段为从 `grass_date` 向前滚动对应天数的累计值。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维表，提供 `shop_id`、`user_id`、`grass_region` 等维度信息，作为驱动表确保所有广告主均有输出记录 |
| `mp_order.dws_seller_gmv_1d__reg_s0_live` | 卖家粒度每日 GMV 事实表，提供 `placed_order_cnt_1d`、`placed_buyer_cnt_1d`、`placed_item_cnt_1d`、`gmv_1d`、`gmv_usd_1d` 等核心指标（过去 90 天滚动读取） |
| `mp_order.dws_item_gmv_1d__reg_s0_live` | 商品粒度每日 GMV 事实表，提供商品维度的 `placed_order_cnt_1d`（按 `shop_id` + `grass_date` + `grass_region` 聚合后得到 `item_amount_1d`，对应 `order_item_cnt_*d`）（过去 90 天滚动读取） |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_advertiser__reg_s0_live
  (grass_date = ${grass_date}, grass_region = upper('${region}'))
              │
              │  LEFT JOIN（以广告主维表为驱动，保证无交易广告主也有记录）
              │
  ┌───────────┴──────────────────────────────────────┐
  │                  orders 子查询                    │
  │                                                  │
  │  mp_order.dws_seller_gmv_1d__reg_s0_live         │
  │  (grass_date BETWEEN -89d ~ ${grass_date},       │
  │   tz_type='local', grass_region=upper('${region}'))│
  │              │                                   │
  │              │  INNER JOIN（shop_id+grass_date+   │
  │              │              grass_region）         │
  │              │                                   │
  │  mp_order.dws_item_gmv_1d__reg_s0_live           │
  │  (grass_date BETWEEN -89d ~ ${grass_date},       │
  │   tz_type='local', grass_region=upper('${region}'))│
  │  → GROUP BY shop_id, grass_date, grass_region    │
  │    → item_amount_1d                              │
  │              │                                   │
  │  → 打标签（is_today/is_7d/is_30d/is_60d/is_90d）  │
  │  → GROUP BY shop_id, region                      │
  │  → CASE WHEN 条件聚合得到各窗口指标               │
  └───────────────────────────────────────────────────┘
              │
              ▼
  dws_advertiser_trd_order_gmv_nd__reg_s0_live
  PARTITION (tz_type='local', grass_region, grass_date)
  （INSERT OVERWRITE，按地区+日期参数化调度）
```

### 关键 CTE 说明

本 ETL 无显式 CTE（WITH 块），逻辑通过多层内联子查询实现，结构如下：

| 子查询层级 | 来源表 | 作用 |
|---|---|---|
| `dim`（第一层） | `mp_paidads.dim_advertiser__reg_s0_live` | 获取当日在册广告主的 `shop_id`、`user_id`、`grass_region`，作为 LEFT JOIN 驱动端 |
| 最内层子查询 `a` | `mp_order.dws_seller_gmv_1d__reg_s0_live` | 读取过去 90 天的卖家每日交易数据，并为每行打上时间窗口标签（`is_today`、`is_7d`、`is_30d`、`is_60d`、`is_90d`） |
| 最内层子查询 `b` | `mp_order.dws_item_gmv_1d__reg_s0_live` | 读取过去 90 天的商品维度订单数，按 `shop_id + grass_date + grass_region` 聚合得到每日商品维度订单件数 `item_amount_1d` |
| `a INNER JOIN b` | — | 将卖家维度与商品维度数据关联，以 `shop_id + grass_date + grass_region` 为键 |
| `orders`（外层聚合） | `a INNER JOIN b` 结果 | 使用 `SUM(CASE WHEN ...)` 模式按时间窗口标签聚合，将逐日数据折叠为单行的多窗口指标，GROUP BY `shop_id, region` |

### 注意事项

1. **LEFT JOIN 保全性**：以广告主维表 `dim_advertiser` 为驱动做 LEFT JOIN，当广告主在统计周期内无任何交易时，所有指标字段通过 `COALESCE(..., 0)` 填充为 0 而非 NULL，下游无需再做空值处理。

2. **INNER JOIN 的数据过滤风险**：`orders` 子查询中 `a`（seller 粒度）与 `b`（item 粒度）使用 `INNER JOIN`。若某 `shop_id` 在某天有卖家级别的交易记录但在 `dws_item_gmv_1d` 中无对应商品记录（或反之），该天的数据将被过滤丢失，进而导致该 `shop_id` 的各窗口指标偏低。请关注上游两张表的数据一致性。

3. **滑动窗口口径**：`_1d` 为单天（`= grass_date`），`_7d` 为含当天的 7 日窗口（`grass_date - 6 days` 至 `grass_date`），`_30d` 为含当天的 30 日窗口（`grass_date - 29 days`），`_60d` 含当天 60 日，`_90d` 含当天 90 日。上游读取 90 天数据一次扫描，通过打标签 + CASE WHEN 聚合同时产出全部窗口，计算效率较高。

4. **货币一致性**：`gmv_*d` 为本地货币（随 `grass_region` 不同而不同，单位含义不统一），`gmv_usd_*d` 为统一美元计价。跨地区汇总分析时，**只能使用 `gmv_usd_*d`** 字段，直接对不同 `grass_region` 的 `gmv_*d` 求和无意义。

5. **参数化调度**：ETL 通过 `${region}`、`${grass_date}`、`${timezone}` 参数化，各地区独立调度写入对应分区，表后缀 `__reg_s0_live` 表示实时/生产环境的参数化模板实例，覆盖所有运营地区。

---

*文档生成时间：2026-04-22*