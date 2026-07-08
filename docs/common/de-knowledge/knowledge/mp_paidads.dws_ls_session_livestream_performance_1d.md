<!-- ads-workspace-gdoc-sync: gdoc_id=1erVj6OY8J-ri34AJ4sH5zWb7aPDK9NeWkQm-GcqMy3Y gdoc_url=https://docs.google.com/document/d/1erVj6OY8J-ri34AJ4sH5zWb7aPDK9NeWkQm-GcqMy3Y/edit -->

# mp_paidads.dws_ls_session_livestream_performance_1d

**分层**：DWS（数据汇总层）
**主键**：`ls_session_id` + `ads_id` + `pricing_type` + `campaign_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1），按地区参数化分区写入
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表以**直播场次（Live Stream Session）× 广告（Ads）× 日期**为粒度，汇总直播带货场景下付费广告在单个直播场次内的全链路绩效数据，涵盖曝光、点击、加车、下单、GMV 及广告花费等核心指标。数据来源于明细层事件表与收入汇总表，经过 JOIN 整合后，形成兼具行为漏斗与财务口径的一站式分析宽表。

本表的主要使用场景包括：直播广告 ROI 分析（ROAS = GMV / 花费）、场次级广告效率排名、广告主/主播的直播投放复盘，以及与平台大盘指标的对比分析。BI 报表、广告效果看板及运营策略评估均可直接以本表为基础层进行聚合查询。

各地区通过 `${region}` 与 `${timezone}` 参数化调度，统一写入 `tz_type = 'local'`（本地时区）分区，确保不同市场的数据按本地自然日口径对齐。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前写入值固定为 `'local'`（本地时区），各地区按本地时区参数化调度。⚠️ 查询时**必须指定** `tz_type = 'local'`，否则将触发全分区扫描，造成资源浪费或结果重复 |
| `grass_region` | string | 地区代码（大写），如 `'ID'`、`'TH'`、`'VN'` 等。⚠️ 查询时**必须指定**具体地区，避免跨地区汇总导致数据重复计算 |
| `grass_date` | date | 数据日期（本地时区自然日）。⚠️ 查询时**必须指定**，避免全表扫描 |

---

### 维度：直播场次与主播属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ls_session_id` | bigint | 直播场次唯一标识，主键之一 |
| `streamer_id` | bigint | 主播 ID |
| `streamer_type` | int | 主播类型（枚举值，如自播、达人播等，具体编码参见维度表） |
| `ls_session_start_datetime` | string | 直播场次开始时间（字符串格式，含时区信息，需按需转换为 timestamp） |
| `ls_session_end_datetime` | string | 直播场次结束时间（字符串格式，含时区信息，需按需转换为 timestamp） |

---

### 维度：广告与店铺属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告计划唯一标识，主键之一 |
| `shop_id` | bigint | 店铺 ID，广告所属店铺 |
| `pricing_type` | int | 广告计费类型（枚举值，如 CPM、CPC 等，具体编码参见维度表），主键之一 |

---

### 维度：推广计划属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_id` | bigint | 广告活动（Campaign）唯一标识，主键之一 |
| `campaign_start_datetime` | string | Campaign 开始时间（字符串格式，需按需转换为 timestamp） |
| `campaign_end_datetime` | string | Campaign 结束时间（字符串格式，需按需转换为 timestamp） |

---

### 指标：曝光与流量

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt` | bigint | 广告总曝光次数（含扣量前） |
| `deduct_impression_cnt` | bigint | 被扣除的曝光次数（无效流量扣量） |
| `non_fraud_impression_cnt` | bigint | 非欺诈曝光次数（= impression_cnt - 扣量后有效曝光，具体口径以上游定义为准） |
| `view_cnt` | bigint | 广告视频/内容观看次数 |
| `effective_view_cnt` | bigint | 有效观看次数，通过 `count(distinct case when view > 0 then concat(request_id, ads_id))` 计算，去重后的有效观看请求数。⚠️ 由 `COUNT DISTINCT` 聚合而来，多分区/分组 SUM 时需注意去重逻辑可能被破坏，应回溯明细层重新计算 |
| `click_cnt` | bigint | 广告点击次数（原始点击，未去重） |
| `product_click_cnt` | bigint | 商品点击次数（用户点击广告内商品链接的次数） |

---

### 指标：购买漏斗

| 字段 | 类型 | 说明 |
|------|------|------|
| `add_to_cart_cnt` | bigint | 加购物车次数 |
| `checkout_cnt` | bigint | 发起结算次数 |
| `order_cnt` | bigint | 下单数（归因到该广告的总订单数） |
| `paid_order_cnt` | bigint | 已付款订单数 |
| `confirmed_order_cnt` | bigint | 已确认收货订单数 |
| `ads_items_sold_cnt` | bigint | 广告直接归因的商品售出件数（直接归因口径） |
| `broad_order_cnt` | bigint | 宽泛归因订单数（包含间接归因，归因窗口更宽） |
| `broad_item_sold_cnt` | bigint | 宽泛归因商品售出件数 |

---

### 指标：GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_gmv_amt_local` | double | 广告直接归因 GMV（本地货币，直接归因口径） |
| `ads_gmv_amt_usd` | double | 广告直接归因 GMV（美元） |
| `broad_ads_gmv_amt_local` | double | 宽泛归因 GMV（本地货币，归因窗口更宽，涵盖间接转化） |
| `broad_ads_gmv_amt_usd` | double | 宽泛归因 GMV（美元） |

---

### 指标：广告花费

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_expenditure_local` | double | 广告实际花费（本地货币，不含税），来源于 `dws_ls_session_livestream_revenue_1d`（`total_expenditure_amt_local_1d`） |
| `ads_expenditure_usd` | double | 广告实际花费（美元，不含税），来源于 `dws_ls_session_livestream_revenue_1d`（`total_expenditure_amt_usd_1d`） |
| `ads_expenditure_vat_local` | double | 广告花费含税金额（本地货币，含 VAT） |
| `ads_expenditure_vat_usd` | double | 广告花费含税金额（美元，含 VAT） |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，消耗大量计算资源，并可能返回跨地区重复数据：

| 过滤字段 | 推荐写法示例 | 遗漏后果 |
|----------|-------------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描所有时区分区；当前有效分区仅为 `local`，但仍会造成无效 IO |
| `grass_region` | `grass_region = 'ID'` | 跨地区全量扫描，数据量成倍放大，汇总结果错误 |
| `grass_date` | `grass_date = '2024-01-01'` 或 `grass_date BETWEEN ... AND ...` | 全历史数据扫描，性能极差 |

**推荐过滤模板：**
```sql
WHERE tz_type = 'local'
  AND grass_region = '<YOUR_REGION>'
  AND grass_date = '<YOUR_DATE>'
```

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确处理方式 |
|------|----------|-------------|
| `effective_view_cnt` | 由明细层 `COUNT(DISTINCT concat(request_id, ads_id))` 计算而来；跨分区/多行 SUM 会重复计数，不满足可加性 | 若需跨日期或跨 session 汇总，回溯 `mp_paidads.dwd_livestream_performance_di__reg_s0_live` 明细层重新 COUNT DISTINCT |
| `ads_expenditure_local` / `ads_expenditure_usd` | 来自 Revenue 表的日维度预聚合值，在同一 `(ls_session_id, ads_id, campaign_id, pricing_type)` 组合下唯一；若 JOIN 其他维度后出现行扩展，直接 SUM 会重复计算花费 | 聚合前先确认主键粒度，必要时在子查询中先做主键级 DISTINCT |
| `ads_expenditure_vat_local` / `ads_expenditure_vat_usd` | 同上，含税花费同样来自预聚合，存在相同风险 | 同上 |
| `campaign_start_datetime` / `campaign_end_datetime` / `ls_session_start_datetime` / `ls_session_end_datetime` | 存储为 string 类型，不可直接做时间比较或聚合 | 使用 `CAST(... AS TIMESTAMP)` 或 `TO_TIMESTAMP()` 转换后再使用 |

### 时效性说明

本表按自然日（`grass_date`）分区，T+1 调度写入。查询昨日数据时，应使用 `grass_date = CURRENT_DATE - 1`（或对应的调度日期参数）。`ads_expenditure_local/usd` 字段来源于 Revenue 汇总表的 `*_1d` 字段，代表当日累计花费，**不是实时数据**，当天数据需等待次日调度完成后方可使用。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 直播广告行为明细表（DWD 层），提供曝光、点击、加车、下单、GMV、观看等全链路行为事件数据，按 `ls_session_id + ads_id` 粒度聚合后作为性能指标主体 |
| `mp_paidads.dws_ls_session_livestream_revenue_1d__reg_s0_live` | 直播广告收入汇总表（DWS 层），提供场次级广告实际花费（不含税/含税，本地货币/美元），以 `tz_type = 'local'` 口径 LEFT JOIN 到主表 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_livestream_performance_di__reg_s0_live
  (grass_region = ${REGION}, grass_date = ${grass_date})
           │
           │  GROUP BY ls_session_id, streamer_id, ads_id, shop_id,
           │           pricing_type, campaign_id, ...
           │  SUM(impression, click, order, gmv, ...)
           │  COUNT DISTINCT(effective_view)
           ▼
       CTE: ls_performance
           │
           │  LEFT JOIN ON (ads_id, pricing_type, campaign_id, ls_session_id)
           │
mp_paidads.dws_ls_session_livestream_revenue_1d__reg_s0_live
  (grass_region = ${REGION}, grass_date = ${grass_date}, tz_type = 'local')
           │
           │  取 total_expenditure_amt_local_1d / _usd_1d
           ▼
       CTE: ls_rev
           │
           ▼
      CACHE TABLE output
      (拼接 grass_region, grass_date 常量列)
           │
           ▼
INSERT OVERWRITE dws_ls_session_livestream_performance_1d__reg_s0_live
  PARTITION (tz_type = 'local', grass_region, grass_date)
           │
           ▼
ALTER TABLE dws_ls_session_livestream_performance_1d__${region}_s0_live
  ADD PARTITION (grass_date = ${grass_date})
  [指向地区级 location，提供单地区快速访问入口]
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `ls_performance` | `dwd_livestream_performance_di__reg_s0_live` | 将直播广告行为明细按场次 × 广告维度聚合，汇总曝光、点击、下单、GMV 等所有行为漏斗指标；其中 `effective_view_cnt` 使用 `COUNT DISTINCT` 计算有效观看去重数 |
| `ls_rev` | `dws_ls_session_livestream_revenue_1d__reg_s0_live` | 提取当日、本地时区口径下各场次广告的不含税与含税花费（本地货币 + 美元），作为花费指标的唯一数据源 |
| `output`（cached） | `ls_performance` LEFT JOIN `ls_rev` | 主结果集，以 `ls_performance` 为左表，LEFT JOIN `ls_rev` 补充花费字段（LEFT JOIN 保留无花费记录的行），并附加 `grass_region`、`grass_date` 常量列，缓存以供多次写入使用 |

### 注意事项

1. **花费字段可能为 NULL**：`ads_expenditure_local`、`ads_expenditure_usd`、`ads_expenditure_vat_local`、`ads_expenditure_vat_usd` 来自 LEFT JOIN 的右表 `ls_rev`；若某广告场次在 Revenue 表中无对应记录，这四个字段将为 `NULL`，聚合时需使用 `COALESCE(..., 0)`。

2. **双写机制**：ETL 同时维护两张物理表——`__reg_s0_live`（全地区统一表，含 `tz_type` + `grass_region` 双分区）和 `__${region}_s0_live`（单地区视图表，仅含 `grass_date` 分区，location 指向全区表的子路径）。两者数据完全一致，后者为单地区查询提供更简洁的访问路径，无需额外过滤 `tz_type` 和 `grass_region`。

3. **参数化调度**：SQL 中出现的 `upper('${region}')`、`date('${grass_date}')` 均为调度模板参数，ETL 引擎在各地区调度时分别替换，本表覆盖所有上线地区，各地区按本地时区参数化调度，**不限于任何单一市场**。

4. **`tz_type` 当前仅写入 `local`**：ETL 固定写入 `tz_type = 'local'` 分区，暂无 `utc` 等其他时区分区。如未来新增时区口径，查询过滤条件需相应调整。

5. **`effective_view_cnt` 的不可加性**：该指标在 ETL 中通过 `COUNT DISTINCT` 在明细行级别计算，一旦写入本表即为预聚合值。跨日期或跨场次 SUM 时存在重复计数风险，如需精确去重，应回溯 DWD 明细层。

6. **GMV 归因口径区分**：`ads_gmv_amt_*` 为**直接归因**（严格归因窗口），`broad_ads_gmv_amt_*` 为**宽泛归因**（含间接转化），两者口径不同，不可混用于同一分析场景，报表中需明确标注归因类型。

---

*文档生成时间：2026-04-22*