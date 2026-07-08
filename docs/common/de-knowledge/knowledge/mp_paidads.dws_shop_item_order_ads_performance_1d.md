<!-- ads-workspace-gdoc-sync: gdoc_id=1Y-A5YyfGF7280usPkh_FZAxHe82wiS4q3AnTfwH0FxU gdoc_url=https://docs.google.com/document/d/1Y-A5YyfGF7280usPkh_FZAxHe82wiS4q3AnTfwH0FxU/edit -->

# mp_paidads.dws_shop_item_order_ads_performance_1d

**分层**：DWS（数据服务层 / ADS 宽表）
**主键**：`shop_id`, `item_id`（联合主键，分区内唯一）
**分区**：`grass_region`（地区）, `grass_date`（业务日期）
**更新频率**：每日一次（T+1，写入前一业务日数据）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是付费广告域的商品维度订单绩效宽表，以「店铺 × 商品 × 地区 × 业务日期」为粒度，汇总商品在广告投放场景下的订单侧核心指标，并预留广告侧指标字段（当前以 NULL 占位，由其他 ETL 任务回填）。表名中的 `1d` 表示指标口径为自然日（单日）维度。

本表的核心价值在于将订单层（`mp_order`）的实际成交数据与广告绩效字段在同一粒度下打通，为广告 ROI 分析、店铺/商品投放效果评估、平台大盘 GMV 归因等场景提供标准化的数据底座。广告分析师和商业智能团队可基于本表快速计算 ROAS（广告支出回报率）、广告直接/泛广告 GMV 占比等核心投放指标。

各地区按本地时区参数化调度，确保不同市场的业务日期口径与当地运营时间对齐；订单侧指标（`seller_gmv_amt_1d`、`order_id_bitmap_base64_1d`）每日由订单明细表聚合写入，广告侧指标字段在当前版本中以 NULL 占位，需关注后续回填任务的写入状态。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | STRING | 地区编码，大写，如 `MX`、`TH`、`PH` 等。各地区独立分区，查询时**必须指定**，否则触发全表扫描。 |
| `grass_date` | STRING | 业务日期（本地时区），格式 `yyyy-MM-dd`，对应前一业务自然日（`BIZ_YESTERDAY`）。查询时**必须指定**，否则触发全表扫描。 |

---

### 维度：主键与商品属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | STRING | 店铺 ID，唯一标识一个商家店铺，为联合主键之一。源表过滤 `shop_id IS NOT NULL`，保证非空。 |
| `item_id` | STRING | 商品 ID，唯一标识店铺下的一个 SKU/SPU，为联合主键之一。源表过滤 `item_id IS NOT NULL`，保证非空。 |

---

### 指标：广告绩效（广告侧，当前版本 NULL 占位）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_sequence_timestamp` | TIMESTAMP | 广告数据最近一次写入/更新时间戳。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认该字段已被回填，否则相关广告指标无效。 |
| `click_cnt_1d` | BIGINT | 当日广告点击次数（单日）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。 |
| `impression_cnt_1d` | BIGINT | 当日广告曝光次数（单日）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。 |
| `expenditure_amt_1d` | DECIMAL(20,4) | 当日广告总花费金额（单日，含搜索广告与发现广告）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。 |
| `checkout_cnt_1d` | BIGINT | 当日广告带来的结账次数（单日）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。 |
| `direct_order_cnt_1d` | BIGINT | 当日广告直接带来的订单数（单日，严格归因）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。 |
| `direct_order_gmv_amt_1d` | DECIMAL(20,4) | 当日广告直接带来的 GMV 金额（单日，严格归因）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。 |
| `broad_order_cnt_1d` | BIGINT | 当日广告泛归因订单数（单日，宽口径归因）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。 |
| `broad_order_gmv_amt_1d` | DECIMAL(20,4) | 当日广告泛归因 GMV 金额（单日，宽口径归因）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。 |
| `search_expenditure_amt_1d` | DECIMAL(20,4) | 当日搜索广告花费金额（单日）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。`expenditure_amt_1d = search_expenditure_amt_1d + discovery_expenditure_amt_1d`，不可重复累加。 |
| `discovery_expenditure_amt_1d` | DECIMAL(20,4) | 当日发现广告（推荐流广告）花费金额（单日）。⚠️ 当前版本为 `NULL`，由广告侧回填任务写入，使用前需确认已回填。`expenditure_amt_1d = search_expenditure_amt_1d + discovery_expenditure_amt_1d`，不可重复累加。 |

---

### 指标：订单侧绩效

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_sequence_timestamp` | TIMESTAMP | 订单数据本次写入时间戳，由 `current_timestamp()` 在 ETL 执行时生成。⚠️ 为 ETL 执行时刻的系统时间，不代表业务时间，不可用于业务时序分析；多次重跑时该字段会更新为最新执行时间。 |
| `order_id_bitmap_base64_1d` | STRING | 当日该店铺商品的去重订单 ID 集合，以 Bitmap 序列化后 Base64 编码存储（使用 StarRocks Hive UDF `bitmap_agg` + `bitmap_to_base64` 生成）。⚠️ 存储格式为 Bitmap Base64 字符串，**不可直接 COUNT / SUM**；如需计算去重订单数，须在支持 StarRocks Bitmap 函数的引擎中使用 `bitmap_count(base64_to_bitmap(...))` 解码后统计，或在上游明细层重新聚合。 |
| `seller_gmv_amt_1d` | DECIMAL(20,4) | 当日该店铺商品的卖家口径 GMV 合计（单日，`SUM(seller_gmv)`）。来源为订单明细表，仅统计 `is_placed = 1`（已下单）且本地时区（`tz_type = 'local'`）的记录。跨日期或跨地区聚合时可直接 SUM。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下两个分区字段，否则将触发全表全分区扫描，导致查询极慢并消耗大量计算资源：

```sql
-- 正确示例
WHERE grass_region = 'MX'
  AND grass_date = '2025-04-21'
```

| 过滤字段 | 推荐写法 | 遗漏后果 |
|---|---|---|
| `grass_region` | `grass_region = '<大写地区码>'`，如 `'MX'`、`'TH'` | 扫描所有地区分区，资源浪费，结果错误（跨地区混合） |
| `grass_date` | `grass_date = 'yyyy-MM-dd'`，精确日期或范围 | 扫描全量历史分区，查询极慢，结果含历史数据 |

> 本表**无需**额外过滤 `tz_type`，订单侧 ETL 已在写入时固定过滤 `tz_type = 'local'`，表内数据均为本地时区口径。

---

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确处理方式 |
|---|---|---|
| `order_id_bitmap_base64_1d` | Bitmap Base64 编码，字符串无法直接聚合 | 在 StarRocks 中使用 `bitmap_count(base64_to_bitmap(order_id_bitmap_base64_1d))` 解码后统计去重数；或回溯 `dwd_order_item_place_pay_complete_di` 明细层重新 `COUNT(DISTINCT order_id)` |
| `search_expenditure_amt_1d` + `discovery_expenditure_amt_1d` | 二者之和等于 `expenditure_amt_1d`，若与后者同时 SUM 将导致重复计算 | 计算总花费时三选一，勿同时 SUM `expenditure_amt_1d` 与两个子渠道字段 |
| 所有广告侧指标（`click_cnt_1d` 等） | 当前版本为 NULL，直接 SUM 结果为 NULL | 使用前先确认广告回填任务已完成，可通过 `ads_sequence_timestamp IS NOT NULL` 判断是否已回填 |

---

### 时效性说明

- 本表写入的是 **`BIZ_YESTERDAY`（前一业务日）** 的数据，每日 T+1 调度写入。
- 查询"昨日数据"时，`grass_date` 应取**当前日期减 1**（按各地区本地时区换算）。
- 广告侧指标字段（`ads_sequence_timestamp`、`click_cnt_1d` 等）的时效性**独立于**订单侧，取决于广告回填任务的完成时间；建议使用 `ads_sequence_timestamp IS NOT NULL` 作为广告数据就绪的判断条件，避免在回填完成前读取广告指标产生误导性结果。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_order.dwd_order_item_place_pay_complete_di__{region}_s0_live` | 订单明细宽表，提供订单维度的 `seller_gmv`、`order_id`，按 `shop_id`、`item_id` 聚合后写入本表订单侧指标 |

> 广告侧指标字段（`click_cnt_1d`、`impression_cnt_1d`、`expenditure_amt_1d` 等）由独立的广告数据回填任务写入，上游来源待补充。

---

## ETL 逻辑摘要

### 数据流

```
mp_order.dwd_order_item_place_pay_complete_di__{region}_s0_live
  │
  │  过滤条件：
  │    tz_type = 'local'
  │    grass_region = upper('${region}')
  │    grass_date = '${BIZ_YESTERDAY}'
  │    is_placed = 1
  │    shop_id IS NOT NULL
  │    item_id IS NOT NULL
  │
  │  聚合维度：shop_id, item_id
  │
  ├─ SUM(seller_gmv)              → seller_gmv_amt_1d
  ├─ bitmap_agg(order_id)
  │    └─ bitmap_to_base64(...)   → order_id_bitmap_base64_1d
  ├─ current_timestamp()          → order_sequence_timestamp
  └─ CAST(NULL AS ...)            → 广告侧指标字段（占位，待回填）
          │
          ▼
mp_paidads.dws_shop_item_order_ads_performance_1d__{region}_s0_live
  PARTITION (grass_region = '${upper_region}', grass_date = '${BIZ_YESTERDAY}')

────────────────────────────────────────────
  [独立广告回填任务，上游待确认]
          │
          └─ 回填广告侧指标字段（click_cnt_1d / impression_cnt_1d /
             expenditure_amt_1d / checkout_cnt_1d /
             direct_order_cnt_1d / direct_order_gmv_amt_1d /
             broad_order_cnt_1d / broad_order_gmv_amt_1d /
             search_expenditure_amt_1d / discovery_expenditure_amt_1d /
             ads_sequence_timestamp）
```

### 注意事项

1. **广告侧字段 NULL 占位机制**：ETL SQL 中广告侧所有指标均以 `CAST(NULL AS <type>)` 写入，目的是先由订单侧任务占据分区行，再由广告侧回填任务 UPDATE/覆盖写入，形成"两阶段写入"模式。分析时务必确认两个任务均已完成。

2. **Bitmap UDF 依赖**：本表使用 StarRocks Hive UDF（`bitmap_agg`、`bitmap_to_base64`），执行环境需加载 `hive-udf-1.0.0.jar`。`order_id_bitmap_base64_1d` 字段在非 StarRocks 引擎（如 Hive、Spark）中读取为普通字符串，无法直接使用 Bitmap 函数解码，需注意引擎兼容性。

3. **`is_placed = 1` 口径**：订单侧仅统计已下单（`is_placed = 1`）的订单，未支付/取消订单不计入，`seller_gmv_amt_1d` 为已下单口径 GMV，非最终成交 GMV，使用时需与业务方确认口径一致性。

4. **参数化调度**：表名后缀 `__{region}_s0_live` 及 SQL 中的 `${region}`、`${upper_region}`、`${BIZ_YESTERDAY}` 均为调度系统参数，各地区独立调度实例运行，最终覆盖所有支持地区，各地区按本地时区参数化调度。

5. **`order_sequence_timestamp` 重跑稳定性**：该字段使用 `current_timestamp()` 生成，每次 ETL 重跑均会更新为重跑时刻，非幂等字段，不可用于判断数据的业务时间。

---

*文档生成时间：2026-04-22*