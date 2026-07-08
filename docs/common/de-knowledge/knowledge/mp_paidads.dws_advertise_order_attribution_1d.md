<!-- ads-workspace-gdoc-sync: gdoc_id=1FEcFrSjmV8TSzb8w_0Sjh1v-Lei186qdgDfPAmotnfk gdoc_url=https://docs.google.com/document/d/1FEcFrSjmV8TSzb8w_0Sjh1v-Lei186qdgDfPAmotnfk/edit -->

# mp_paidads.dws_advertise_order_attribution_1d

**分层**：DWS（数据汇总层）
**主键**：`order_id`, `request_id`, `ads_id`, `shop_id`, `item_id`, `placement`, `click_datetime`, `event_datetime`, `grass_date`, `grass_region`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：0（末端 ADS 层表，暂无下游候选表直接引用）

---

## 业务描述

本表为广告订单归因日汇总表，以广告点击事件为线索，将买家的下单行为归因到具体广告投放维度（广告 ID、广告位、关键词、搜索词等），记录直接归因订单与宽口径间接归因订单的核心绩效指标。适用于广告效果复盘、ROI 分析、关键词投放优化、广告位价值评估等场景。

本表同时覆盖**直接归因**（用户点击广告后在 7 天内直接购买被广告推广商品）与**宽口径归因**（Broad Attribution，用户点击广告后 7 天内在该店铺产生的间接订单），两套口径并行存储，满足不同业务分析视角的需求。

各地区按本地时区参数化调度，`tz_type = 'local'` 分区存储本地时区口径数据，保障各市场在统计周期对齐上的准确性。数据由明细层 `dwd_advertise_order_attribution_di` 按订单维度聚合而来，是广告营销团队进行日常运营分析的核心宽表之一。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。当前写入值为 `'local'`，表示各地区按本地时区统计。⚠️ 查询时**必须指定** `tz_type = 'local'`，否则可能触发全分区扫描 |
| `grass_region` | string | 国家/地区代码分区，如 `'BR'`、`'MX'`、`'TH'` 等。⚠️ 查询时**必须指定**，否则触发跨地区全量扫描 |
| `grass_date` | date | 日期分区，格式 `YYYY-MM-DD`。⚠️ 查询时**必须指定**，避免全表扫描 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_id` | bigint | 订单 ID，ETL 已过滤 `order_id IS NOT NULL` |
| `request_id` | string | 广告请求 ID，标识一次广告展示请求，用于关联原始展示日志 |
| `ads_id` | bigint | 广告 ID，对应广告主创建的广告计划 |
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `placement` | bigint | 广告位类型编码，如搜索广告、发现广告等，具体枚举值参见广告位字典表 |

---

### 维度：搜索词与关键词

| 字段 | 类型 | 说明 |
|------|------|------|
| `query` | string | 买家输入的搜索词，即触发本次广告展示的原始查询字符串 |
| `keywords` | string | 广告主配置的关键词，与买家搜索词匹配后触发广告展示 |

---

### 维度：时间信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `click_datetime` | string | 买家点击广告的时间，格式 `YYYY-MM-DD HH:MM:SS`。⚠️ 存储为 string 类型，范围过滤时需使用字符串比较或显式转换 |
| `event_datetime` | string | 订单事件（下单/付款/确认收货）发生时间，格式 `YYYY-MM-DD HH:MM:SS`。⚠️ 存储为 string 类型，范围过滤时需使用字符串比较或显式转换 |

---

### 指标：直接归因订单绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_order_cnt` | bigint | 当日直接归因订单数（点击与下单发生在同一天）|
| `order_cnt` | bigint | 直接归因订单总数（用户点击广告后 7 天内购买被推广商品的订单计数）|
| `ads_gmv_amt_local` | double | 直接归因 GMV（本地货币）。口径为 `order_price × 商品数量`，**仅含商品折扣与捆绑促销折扣**，不含运费、运费补贴、买家手续费、平台补贴、卖家券、银行/卡返现及金币抵扣。⚠️ 与 order_mart GMV（含全类型折扣）口径不同，跨系统对比时需注意 |
| `ads_gmv_amt_usd` | double | 直接归因 GMV（美元），换算口径同 `ads_gmv_amt_local` |
| `ads_items_sold_cnt` | bigint | 直接归因订单中售出的商品件数 |

---

### 指标：宽口径（Broad）归因绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order_cnt` | bigint | 宽口径间接归因订单数。买家在广告点击后 7 天内，在该店铺内产生的间接订单（订单级别计数）|
| `broad_order_gmv_amt_local` | double | 宽口径间接归因 GMV（本地货币），即点击后 7 天内间接产生的 GMV |
| `broad_order_gmv_amt_usd` | double | 宽口径间接归因 GMV（美元）|
| `broad_order_item_cnt` | bigint | 宽口径间接归因中，7 天内间接下单的商品件数 |
| `broad_shopitem_click_cnt` | bigint | 宽口径点击数。归因规则：若商品最近一次点击来源为关键词/定向广告，则归因到该广告；若最近点击为店铺广告直接商品点击，则归因到店铺广告宽口径展示 |
| `broad_shopitem_impression_cnt` | bigint | 宽口径展示数。归因规则：若商品最近一次曝光来源为关键词/定向广告，则归因到该广告；若最近曝光来源为店铺广告直接商品曝光，则归因到店铺广告宽口径；若订单无商品级广告展示，则检查 7 天内是否有店铺广告，若有则归因到店铺广告宽口径 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，避免全表扫描导致资源超支或数据混用：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描所有时区分区，返回重复数据 |
| `grass_region` | `grass_region = 'SG'`（按需替换） | 跨地区混算，结果严重失真 |
| `grass_date` | `grass_date = '2025-01-01'` 或范围过滤 | 全量历史扫描，资源消耗极大 |

示例：
```sql
SELECT *
FROM mp_paidads.dws_advertise_order_attribution_1d
WHERE tz_type = 'local'
  AND grass_region = 'SG'
  AND grass_date = '2025-01-01';
```

### 不可直接 SUM 的字段

本表所有指标字段均已在 ETL 中按 GROUP BY 维度汇聚，**但以下情况需特别注意**：

- **跨维度聚合时可以 SUM 数量/金额类指标**（`order_cnt`、`ads_gmv_amt_local` 等），但**不得对不同 `tz_type` 分区混合 SUM**，否则会造成重复计算。
- **`ads_gmv_amt_local` 与 `ads_gmv_amt_usd`** 口径仅含部分折扣，不等于平台 GMV 口径，**不可与其他系统 GMV 字段直接相加比较**。
- **`daily_order_cnt` 与 `order_cnt`** 统计口径不同（前者限当日，后者含 7 天窗口），**不可混用或相加**作为同一业务口径的指标。
- **宽口径指标**（`broad_order_cnt` 等）与直接归因指标（`order_cnt` 等）存在重叠，**不可将两者直接相加**计算总归因订单数，需根据业务口径选其一。

### 时效性说明

- 本表为每日 T+1 调度，`grass_date` 分区对应前一自然日数据。
- `click_datetime` 与 `event_datetime` 均为字符串类型，涉及时间范围过滤时建议使用 `CAST(click_datetime AS TIMESTAMP)` 进行转换，或使用字符串前缀比较（如 `click_datetime LIKE '2025-01-%'`），避免隐式转换错误。
- 宽口径归因（Broad）基于 **7 天滑动窗口**，因此较新日期（如 T-1）的宽口径数据可能因窗口尚未完整而偏低，分析时应关注数据时效性。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_order_attribution_di__reg_s0_live` | 广告订单归因明细层日表，提供订单级别的归因原始数据，本表通过 GROUP BY 在其基础上汇总直接与宽口径归因指标 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_order_attribution_di__reg_s0_live
  │
  │  过滤条件：
  │  - grass_region = upper('${region}')   ← 参数化地区
  │  - grass_date  = DATE('${grass_date}') ← 参数化日期
  │  - order_id IS NOT NULL                ← 排除无效订单
  │
  │  聚合维度（GROUP BY）：
  │  order_id, request_id, query, keywords,
  │  ads_id, shop_id, item_id, placement,
  │  click_datetime, event_datetime,
  │  grass_region, grass_date
  │
  │  聚合操作：SUM 所有数量/金额指标
  │
  ▼
mp_paidads.dws_advertise_order_attribution_1d__reg_s0_live
  PARTITION (tz_type='local', grass_region='${region}', grass_date='${grass_date}')
  （INSERT OVERWRITE，每日全量覆盖当日分区）
```

### 注意事项

1. **参数化调度**：ETL SQL 中出现的 `upper('${region}')`、`DATE('${grass_date}')` 均为调度系统参数，表覆盖全部地区，并非固定某一地区。各地区按本地时区独立调度写入对应 `grass_region` 分区。

2. **INSERT OVERWRITE 机制**：每次调度对当日分区执行覆盖写入，若上游数据在当日重跑，历史分区数据会被替换。如需对比历史快照，应在分区写入后及时固化下游数据。

3. **`order_id IS NOT NULL` 过滤**：ETL 层已在 WHERE 条件中排除 `order_id` 为 NULL 的记录，本表中所有数据均有有效订单 ID。

4. **GMV 口径差异**：`ads_gmv_amt_local` / `ads_gmv_amt_usd` 使用 `order_price`（仅含商品折扣与捆绑促销），与平台 order_mart GMV（使用 `total_price`，含全类型折扣/补贴）口径存在系统性差异，跨系统对比务必统一口径。

5. **宽口径归因窗口**：Broad 归因基于 7 天滑动点击窗口，指标含义与直接归因（直接点击后购买）有本质区别，两者不可混用或叠加。

6. **分区动态添加**：ETL 最后一步通过 `ALTER TABLE ... ADD IF NOT EXISTS PARTITION` 确保新日期分区注册到元数据，避免查询不可见的情况。

---

*文档生成时间：2026-04-22*