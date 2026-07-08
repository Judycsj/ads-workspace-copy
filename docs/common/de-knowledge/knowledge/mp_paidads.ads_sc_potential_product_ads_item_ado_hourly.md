<!-- ads-workspace-gdoc-sync: gdoc_id=1pQkaek6f4Dfaws4D5RD-qB9iX1lQMKEBvWEklM1NbC8 gdoc_url=https://docs.google.com/document/d/1pQkaek6f4Dfaws4D5RD-qB9iX1lQMKEBvWEklM1NbC8/edit -->

# mp_paidads.ads_sc_potential_product_ads_item_ado_hourly

**分层**：ADS（应用数据层）
**主键**：`grass_region` + `grass_date` + `h` + `item_id`
**分区**：`grass_region` / `grass_date` / `h`
**更新频率**：每小时更新（Hourly）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表用于存储**潜力商品（Potential Product）** 维度下各商品在大盘平台的近 7 天订单量（L7D Platform Order Count），以小时为粒度持续更新。数据来源融合了实时订单流与离线订单宽表，确保每个整点均能输出相对准确、时效性强的商品下单量信号。

本表的核心使用场景是**广告智能投放（Smart Campaign）** 中的潜力商品推荐与排序决策。系统通过读取当前小时的 L7D 订单量，辅助广告策略模块（ADO，Ads Decision Optimization）判断哪些商品具备更强的转化潜力，从而优化广告资源的分配。

表中 `key` 字段采用统一编码规则（`item_ado_data:{region}_{item_id}`），便于广告后台服务通过 Key-Value 方式快速检索商品指标，具备较强的工程适用性。各地区按本地时区参数化调度，覆盖所有已上线地区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区编码（如 SG、MY、PH、TW、ID、TH、VN、BR 等），各地区独立分区存储 |
| `grass_date` | date | 业务日期，对应调度参数 `${BIZ_DT}` 所指定的日期 |
| `h` | tinyint | 业务小时（0~23），对应调度参数 `${BIZ_H}`，与 `grass_date` 共同定位数据时间点 |

---

### 维度：主键与商品属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `key` | string | 复合业务主键，格式为 `item_ado_data:{grass_region}_{item_id}`，供广告后台服务以 KV 方式快速检索使用 ⚠️ 该字段为拼接生成的字符串标识符，不具备数值计算意义，查询时请勿对其做聚合或比较运算，作为检索 Key 使用 |
| `item_id` | bigint | 商品 ID，标识具体商品，与 `grass_region` 联合构成业务唯一标识 |

---

### 指标：平台大盘近 7 天订单量

| 字段 | 类型 | 说明 |
|------|------|------|
| `l7d` | bigint | 截至当前分区时间点（`grass_date` + `h`）的近 7 天平台大盘订单量（去重 `order_id` 后累计），融合实时订单（近 2 天）与离线订单（2~7 天前），`NULL` 时以 0 填充 ⚠️ 该指标为已聚合的累计值，**不可跨分区直接 SUM**；若需对比不同时点，应分别取对应分区的单行值；此外，因混合实时与离线数据，最近 2 天数据存在与最终离线值的口径差异，建议使用时结合数据时效性说明 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下分区字段**，避免全分区扫描导致性能问题或数据重复：

| 过滤字段 | 示例值 | 说明 |
|----------|--------|------|
| `grass_region` | `'SG'` | 地区分区，必须指定，否则将扫描全部地区数据 |
| `grass_date` | `current_date()` | 日期分区，必须指定；通常取最新业务日期 |
| `h` | `date_format(now(), 'HH')` | 小时分区，必须指定；通常取最新完整小时 |

**遗漏后果**：表按地区 × 日期 × 小时三级分区，若缺少任一分区过滤，查询将全量扫描历史数据，造成大量冗余读取和数据重复聚合，结果将严重失真（同一商品在多个小时分区均有记录）。

推荐写法示例：

```sql
SELECT item_id, l7d
FROM mp_paidads.ads_sc_potential_product_ads_item_ado_hourly__reg_s0_live
WHERE grass_region = 'SG'
  AND grass_date   = date('2026-04-22')
  AND h            = 14;
```

---

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确使用方式 |
|------|----------|--------------|
| `l7d` | 已为截至当前时点的 7 天累计值，每个小时分区均存储完整的 L7D 累计数，**跨小时 SUM 会多倍计算** | 仅取单一 `(grass_region, grass_date, h)` 分区的值；若需汇总多商品，在**同一分区**内 SUM `l7d` 方可 |
| `key` | 字符串拼接标识符，无数值意义 | 仅用于 KV 检索或 JOIN 条件，不做任何聚合 |

---

### 时效性说明

- **近 2 天订单**（`create_timestamp > unix_timestamp(date_sub(grass_date, 2))`）来自实时订单表 `rt_dwd_order_item_all_ent_rf`，数据为实时摄入，存在轻微延迟，且在离线日终结算前口径可能与最终值存在差异。
- **2~7 天前订单**来自离线宽表 `ads_simple_roi2_npb_item_last_order_di`，口径稳定但仅更新至 `PREV_2D`（当前日期 -2 天）。
- 因此，**当天最新小时分区**的 `l7d` 值最为实时，但实时部分（近 2 天）在当天内仍为估算值；如需口径最终稳定的历史数据，建议取 `grass_date = current_date - 1` 且 `h = 23` 的分区值作为前日完整数据。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live` | 潜力商品推荐列表，提供待计算的 `(grass_region, item_id)` 维度集合，取最近 7 天内最新日期分区 |
| `mp_order.rt_dwd_order_item_all_ent_rf__reg_s0_live` | 实时订单明细宽表，提供近 2 天的实时下单记录，用于计算 L7D 中实时部分的去重订单量 |
| `mp_paidads.ads_simple_roi2_npb_item_last_order_di__reg_s0_temp` | 离线订单汇总宽表，提供 2~7 天前的稳定订单记录，补全 L7D 中离线部分的去重订单量 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live
   │
   │  取各地区最新日期分区（近7天内），得到潜力商品集合
   ▼
[CTE: product_item_rcmd]  ←── 维度驱动（item_id × grass_region）
   │
   │  LEFT JOIN 订单汇总
   │
   ├──── mp_order.rt_dwd_order_item_all_ent_rf__reg_s0_live
   │         （实时订单，近2天，按 order_id 去重）
   │         ↓ UNION ALL
   └──── mp_paidads.ads_simple_roi2_npb_item_last_order_di__reg_s0_temp
             （离线订单，grass_date = PREV_2D，create_timestamp 在 [BIZ_DT-7, BIZ_DT-2) 范围内）
                   │
                   ▼
             [inline subquery: 订单聚合]
             sum(platform_order_cnt) → platform_order_cnt_7d
                   │
                   ▼
   ads_sc_potential_product_ads_item_ado_hourly__reg_s0_live
   （INSERT OVERWRITE，按 grass_region / grass_date / h 分区写入）
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `product_item_rcmd` | `ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live` | 从潜力商品推荐日表中，通过子查询取各地区近 7 天内最新日期分区的商品列表，作为本次计算的商品维度驱动集合 |

### 注意事项

1. **实时 + 离线双流拼接**：L7D 订单量由两段数据 UNION 后聚合：
   - **实时段**：`create_timestamp ∈ (BIZ_DT-2天的零点, BIZ_DT BIZ_H:00:00]`，来自实时订单表，每小时滚动更新。
   - **离线段**：`grass_date = PREV_2D`，`create_timestamp ∈ [BIZ_DT-7天 BIZ_H:00, BIZ_DT-2天的零点)`，来自离线宽表，确保 2 天前数据口径稳定。
   - 两段时间窗口拼接后覆盖完整的近 7 天，但时间边界处（BIZ_DT-2 天附近）存在口径切换，可能导致轻微的数量级波动。

2. **订单状态过滤**：实时订单仅计入 `order_be_status_id in (1,2,4,6,7,8,9,10,11,12,13,14,15,16)` 的有效状态订单，离线表已预先按同口径过滤，两者保持一致。

3. **INSERT OVERWRITE 机制**：每小时以 `grass_region + grass_date + h` 为分区键做覆盖写入，同一分区的历史数据会被最新计算结果替换，无历史累积问题，但旧小时分区一旦被新调度覆盖则不可恢复。

4. **商品范围由推荐表驱动**：本表仅计算出现在 `ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live` 最新分区中的商品，若某商品在推荐表中被下线，下一小时起将不再出现在本表中。

5. **各地区按本地时区参数化调度**：`${BIZ_DT}`、`${BIZ_H}`、`${PREV_7D}`、`${PREV_2D}` 均为调度模板参数，各地区独立实例化，覆盖所有已上线地区，文档中出现的具体地区代码仅为参数化调度实例示例。

---

*文档生成时间：2026-04-22*