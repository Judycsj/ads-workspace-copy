<!-- ads-workspace-gdoc-sync: gdoc_id=1vwvtChpxHw88fdk0S9ALvV4Wzf19TtDBDmLIcH__jr4 gdoc_url=https://docs.google.com/document/d/1vwvtChpxHw88fdk0S9ALvV4Wzf19TtDBDmLIcH__jr4/edit -->

# mp_paidads.dws_advertise_performance_1d

**分层**：DWS（数据汇总层）
**主键**：`ads_id` + `placement` + `entrance` + `item_id` + `pricing_type` + `campaign_id` + `traffic_source` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：4 次（候选表范围内）

---

## 业务描述

本表是广告投放绩效的**日粒度汇总宽表**，整合了广告曝光、点击、订单转化、GMV、广告花费、视频互动、加购等全链路核心指标，是付费广告分析的核心 DWS 层资产。每行记录代表特定广告（`ads_id`）在某一投放位（`placement`）、流量来源（`traffic_source`）、计价方式（`pricing_type`）等多维组合下，某一自然日内的全量绩效汇总。

本表同时覆盖**直接归因**（广告点击后直接下单）与**广泛归因**（broad，用户点击广告商品后在同一店铺内7天内购买的任意商品）两套口径，以及**曝光归因**（imp_attr）和**已支付订单归因**（paid）维度，满足广告主 ROAS 分析、投放优化、平台广告收益核算等多种使用场景。

表通过 `tz_type` 分区同时提供本地时区（`local`）和区域时区（`regional`）两个口径的数据，各地区按本地时区参数化调度，覆盖 Shopee 所有运营地区。下游报表、看板及广告效果评估系统均以本表为核心数据源。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。`local` = 本地自然日口径；`regional` = 区域/UTC 时间戳对齐口径。⚠️ 每次查询必须指定该字段，否则同一天数据会被重复统计两次 |
| `grass_region` | string | 国家/地区分区，大写字母代码（如 `'TW'`、`'MY'`）。⚠️ 必须指定以避免全表扫描 |
| `grass_date` | date | 数据日期分区（本地日历日）。⚠️ 必须指定以避免全表扫描 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，唯一标识一条广告投放记录 |
| `campaign_id` | bigint | 广告活动 ID |
| `placement` | bigint | 广告投放位标识（如搜索页、发现页、YMAL 等） |
| `entrance` | bigint | 广告入口标识 |
| `ads_type` | string | 广告类型，枚举值包括：`targeting:similar_product`、`keyword:search`、`targeting:daily_discover`、`keyword:simple_mode`、`targeting:ymal`、`targeting:simple_mode_ymal`、`targeting:simple_mode_sp`、`targeting:simple_mode_dd` |
| `pricing_type` | bigint | 广告计价方式（如 CPC、CPM、CPS 等编码值） |
| `traffic_source` | int | 流量来源类型（org、roi1、roi2 等）；原始值为 0 时在 ETL 中已置为 null |
| `is_ocpm` | boolean | 是否为 oCPM 广告 |
| `rapid_boost_toggle` | boolean | 是否开启 Rapid Boost 开关 |
| `new_boost` | bigint | 是否属于 New Product Boost 广告位（placement ∈ {44,4400,4401,4402,4405} 且 traffic_source = 4 时为 1，否则为 0）。⚠️ 为派生标记字段，不可直接 SUM，用于 WHERE/GROUP BY 过滤分组 |

### 维度：商品与卖家

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 广告关联商品 ID |
| `shop_id` | bigint | 店铺 ID |
| `seller_id` | bigint | 卖家 ID |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt_1d` | bigint | 近一天广告曝光次数（去重，可能含作弊流量） |
| `click_cnt_1d` | bigint | 近一天成功扣费点击次数。⚠️ 特定 placement（3327/3328/3337/3338/3339）使用 `raw_click_cnt` 替代，与其他 placement 口径略有差异 |
| `view_cnt_1d` | bigint | 近一天 View 总量 |
| `product_click_cnt_1d` | bigint | 近一天视频广告商品点击去重数 |
| `deduplicated_click_cnt` | bigint | 去重后的点击次数 |
| `cps_dedup_click_cnt` | bigint | CPS 模型下的去重点击数 |
| `avg_ads_ranks` | bigint | 广告平均排名，由 `location_in_ads / impression_cnt + 1` 预计算得出。⚠️ 为预计算派生值，不可直接 SUM，跨广告汇总时需用原始的 `location_in_ads` 和 `impression_cnt` 重新计算加权平均 |
| `direct_shop_item_impression_cnt_1d` | bigint | 一天内直接归因的店铺商品曝光数 |
| `direct_shop_item_click_cnt_1d` | bigint | 一天内直接归因的店铺商品点击数 |

### 指标：直接归因订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt_1d` | bigint | 过去一天直接广告订单数量 |
| `ads_items_sold_cnt_1d` | bigint | 一天内直接订单售出商品总数 |
| `ads_gmv_amt_local_1d` | double | 过去一天直接订单 GMV（本地货币） |
| `ads_gmv_amt_usd_1d` | double | 过去一天直接订单 GMV（USD，由本地货币 / 当日汇率换算）。⚠️ 汇率换算结果，跨日对比时注意汇率波动影响 |
| `direct_add_to_cart_cnt_1d` | bigint | 一天内直接归因加购数 |
| `add_to_cart_without_clicks_cnt_1d` | bigint | 一天内无点击行为的加购操作总数 |
| `checkout_cnt_1d` | bigint | 含广泛归因点击（L7D）的结账订单数（按 order_id 去重）。⚠️ 含 broad 口径，非纯直接归因，与 `order_cnt_1d` 口径不同，不可混用 |

### 指标：付款/确认订单（含 YTD 前日对比）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_order_cnt_1d` | bigint | 一天内广告订单中 30 天内完成付款的订单数 |
| `paid_order_cnt_ytd_1d` | bigint | 前一日已付款订单数（`paid_datetime = grass_date - 1`）。⚠️ 为前日数据，取当日分区时该值代表昨日，勿与 `paid_order_cnt_1d` 直接叠加 |
| `confirmed_order_cnt_1d` | bigint | 一天内广告订单中 30 天内付款或确认的订单数 |
| `confirmed_order_cnt_ytd_1d` | bigint | 前一日已确认订单数（`confirmed_datetime = grass_date - 1`）。⚠️ 含义同上，为前日数据，不可与当日字段直接叠加 |
| `deduct_order_cnt` | bigint | CPS 模型下被扣除的订单数 |

### 指标：广泛归因（Broad Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order_cnt_1d` | bigint | 近一天广泛归因订单数（用户点击广告后 7 天内在同一店铺购买任意商品） |
| `broad_order_item_cnt_1d` | bigint | 广泛归因订单下的商品销售数量 |
| `broad_gmv_amt_local_1d` | double | 近一天广泛归因订单 GMV（本地货币） |
| `broad_gmv_amt_usd_1d` | double | 近一天广泛归因订单 GMV（USD）。⚠️ 由本地货币 / 当日汇率换算，跨日对比需注意汇率影响 |
| `broad_add_to_cart_cnt_1d` | bigint | 近一天广泛归因加购次数（所有品类） |
| `broad_shop_item_click_cnt_1d` | bigint | 近一天广泛归因店铺商品点击数 |
| `broad_shop_item_impression_cnt_1d` | bigint | 近一天广泛归因店铺商品曝光数 |

### 指标：已支付 Broad 归因（Paid Broad）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_broad_order_cnt` | bigint | 已支付广泛归因订单数（用户点击广告后 7 天内在同一店铺购买并完成支付） |
| `paid_broad_order_item_sold_cnt` | bigint | 已支付广泛归因订单下的商品售出数 |
| `paid_broad_order_gmv` | double | 已支付广泛归因订单 GMV（本地货币） |
| `paid_broad_order_gmv_usd` | double | 已支付广泛归因订单 GMV（USD）。⚠️ 汇率换算结果，跨日对比需注意汇率波动 |
| `paid_order_item_sold_cnt` | bigint | 已支付直接广告订单的商品售出数 |
| `paid_checkout_cnt` | bigint | 含广泛归因点击（L7D）的已支付结账订单数（按 paid order_id 去重） |
| `paid_agent_checkout_cnt` | bigint | 已支付代理结账订单数 |

### 指标：无点击归因（No-Click Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_no_click_order_cnt` | bigint | 已支付的无点击归因订单数 |
| `paid_no_click_order_item_sold_cnt` | bigint | 已支付无点击归因订单的商品售出数 |
| `paid_no_click_order_gmv` | double | 已支付无点击归因订单 GMV（本地货币） |
| `paid_no_click_order_gmv_usd` | double | 已支付无点击归因订单 GMV（USD）。⚠️ 汇率换算结果 |
| `no_click_gmv_usd` | double | 无点击 GMV（USD，含义参见上游 ETL 上下文） |

### 指标：曝光归因（Impression Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_attr_paid_order_cnt` | bigint | 曝光归因的已支付订单数（有广告曝光但无点击、符合 shop_exp_tag 条件的 broad 订单） |
| `imp_attr_paid_order_item_sold_cnt` | bigint | 曝光归因已支付订单的商品售出数 |
| `imp_attr_paid_order_gmv` | double | 曝光归因已支付订单 GMV（本地货币） |
| `imp_attr_paid_order_gmv_usd` | double | 曝光归因已支付订单 GMV（USD）。⚠️ 汇率换算结果 |

### 指标：广告花费

| 字段 | 类型 | 说明 |
|------|------|------|
| `expenditure_amt_local_1d` | double | 近一天广告扣费总额（本地货币） |
| `expenditure_amt_usd_1d` | double | 近一天广告扣费总额（USD）。⚠️ 汇率换算结果，跨日汇总需注意汇率一致性 |
| `expense_rebate_free_credit_without_expiry` | decimal(25,10) | 平台自动返利产生的无过期时间免费广告金额。⚠️ ETL 中已除以 100000.0 做单位换算，存储单位与原始数据不同，使用时注意单位确认 |

### 指标：视频互动

| 字段 | 类型 | 说明 |
|------|------|------|
| `video_view` | bigint | 视频观看次数 |
| `video_play_3s_cnt` | bigint | 播放时长超过 3 秒的视频数 |
| `video_play_5s_cnt` | bigint | 播放时长超过 5 秒的视频数 |
| `video_play_complete` | bigint | 完整播放完成的视频次数 |
| `view_duration` | bigint | 视频播放总时长（毫秒）。⚠️ 单位为毫秒，展示时需换算为秒或分钟 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，造成严重性能问题并引起数据重复：

| 过滤字段 | 推荐写法示例 | 遗漏后果 |
|----------|-------------|----------|
| `tz_type` | `tz_type = 'local'`（日常业务分析推荐）或 `tz_type = 'regional'` | 同一天数据被双倍统计，所有指标虚增 2 倍 |
| `grass_region` | `grass_region = 'TW'` | 混入所有地区数据，扫描量暴增 |
| `grass_date` | `grass_date = '2025-01-01'` 或 `grass_date BETWEEN ... AND ...` | 全量历史数据扫描，性能极差 |

**时区口径选择建议**：
- 日常广告效果分析、对接广告主报表 → 使用 `tz_type = 'local'`（按本地自然日统计）
- 平台级跨地区汇总、UTC 对齐场景 → 使用 `tz_type = 'regional'`
- 两种口径**不可混合 UNION / SUM**，否则数据重复

**推荐查询模板**：
```sql
SELECT ...
FROM mp_paidads.dws_advertise_performance_1d
WHERE tz_type     = 'local'
  AND grass_region = 'TW'
  AND grass_date   = '2025-01-01'
```

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确计算方式 |
|------|----------|-------------|
| `avg_ads_ranks` | 预计算的加权平均排名（`location_in_ads / impression_cnt + 1`），直接 SUM 无意义 | 回溯上游 `dwd_advertise_performance_di` 取原始 `location_in_ads` 和 `impression_cnt`，按 `SUM(location_in_ads) / SUM(impression_cnt) + 1` 重新计算 |
| `new_boost` | 派生标记字段（0/1），SUM 得到的是广告数量计数而非业务指标 | 仅用于 `WHERE new_boost = 1` 或 `GROUP BY new_boost` 过滤/分组 |
| `paid_order_cnt_ytd_1d` | 存储的是前一日（`grass_date - 1`）的数据，与当日字段语义不同 | 勿与 `paid_order_cnt_1d` 直接相加；如需日环比，用 `paid_order_cnt_ytd_1d` 作为对比基准值 |
| `confirmed_order_cnt_ytd_1d` | 同上，存储前一日确认订单数 | 同上，仅用于环比对比，不可叠加 |
| `expenditure_amt_usd_1d`、`ads_gmv_amt_usd_1d`、`broad_gmv_amt_usd_1d` 等 USD 字段 | 由本地货币按当日汇率换算，跨日 SUM 时汇率基准不同 | 跨日汇总建议统一使用本地货币字段，或确保汇率口径一致 |
| `expense_rebate_free_credit_without_expiry` | ETL 中已做 `/100000.0` 单位换算，与原始数据单位不同 | 直接使用表中存储值即可，但与其他系统对账时需确认单位换算一致性 |
| `checkout_cnt_1d`、`paid_checkout_cnt` | 含广泛归因 L7D 口径，非纯直接归因 | 勿与 `order_cnt_1d`（直接归因）混合汇总计算转化率，需按归因口径分开分析 |

### 时效性说明

- `paid_order_cnt_ytd_1d` 与 `confirmed_order_cnt_ytd_1d`：这两个字段在当日分区（`grass_date = T`）中存储的是 **T-1 日**的数据，用于广告后台的日环比展示。取某天的当日数据时，这两个字段代表前一天，**不代表当天**，请勿与当日指标字段叠加求和。
- 本表为 T+1 调度，`grass_date = T` 的数据在 T+1 日调度完成后可用，分析最新数据时请以调度完成时间为准。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度主表，提供广告类型、商品、店铺、卖家、定向人群等维度信息 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 每日汇率表，用于本地货币 → USD 的 GMV 和花费换算 |
| `mp_paidads.dws_advertise_revenue_1d__reg_s0_live` | 广告收入日汇总表，提供广告花费（expenditure）数据 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告表现明细事实表，提供曝光、点击、订单、GMV、视频等全量明细事件数据 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_advertise                mp_order.dim_exchange_rate
        │                                         │
        └──────────────── LEFT JOIN ──────────────┘
                                │
                              [dim]  ←── 广告维度 + 汇率
                                │
          ┌─────────────────────┼─────────────────────────┐
          │                     │                         │
          ▼                     ▼                         ▼
   [base_local]          [base_regional]           [revenue]
  (当日本地分区           (区域时区 Unix            (广告花费，
   精确过滤)              timestamp 对齐)           来自 dws_revenue)
          │                     │
          │ LEFT JOIN dim        │ LEFT JOIN dim
          ▼                     ▼
  [full_oa_local]       [full_oa_regional]
  (补全维度、            (补全维度、
   GMV USD 换算、         GMV USD 换算、
   avg_ads_ranks)         avg_ads_ranks)
          │                     │
     LEFT JOIN [oa]             │
     (oa1: paid_order_cnt       │
      oa2: confirmed_order_cnt  │
      当日/前日拆分)             │
          │                     │
          ▼                     ▼
       聚合(SUM/_1d)         聚合(SUM/_1d)
          │                     │
          └─────── FULL JOIN revenue ───────┘
                       │
                       ▼
        INSERT OVERWRITE dws_advertise_performance_1d
        PARTITION(tz_type='local'/'regional', grass_region, grass_date)


上游明细来源：
mp_paidads.dwd_advertise_performance_di  →  [base_oa] → [oa]
                                                          ↑
                                         (提供 paid/confirmed 订单当日/前日拆分)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `dim` | `dim_advertise` + `dim_exchange_rate` | 构建广告维度宽表，解析 JSON 人群定向字段，关联当日汇率供后续 USD 换算 |
| `revenue` | `dws_advertise_revenue_1d` + `dim` | 按维度汇总广告花费（本地货币 + USD），traffic_source=0 置 null |
| `base_oa` | `dwd_advertise_performance_di` + `dim_exchange_rate` | 过滤有成交行为的明细记录，做 GMV 的 USD 换算，保留明细粒度（取两天数据支持跨日归因） |
| `oa` | `base_oa` + `dim` | 在 base_oa 基础上补全维度，映射 match_type / premium_segment 可读枚举，供 paid/confirmed 订单当日与前日拆分 |
| `base_local` | `dwd_advertise_performance_di` + `dim` | 按本地 grass_date 精确过滤当日数据，14 维度分组聚合全量指标（local 口径） |
| `base_regional` | `dwd_advertise_performance_di` + `dim` | 与 base_local 相同聚合逻辑，但按 Unix timestamp 精确截取区域时区当日边界（取两天分区）（regional 口径） |
| `full_oa_local` | `base_local` + `dim` + `oa`（子查询 oa1/oa2） | 补全维度、换算 USD GMV、计算 avg_ads_ranks，关联 oa 拆分 paid/confirmed 订单当日与前日计数（local 口径） |
| `full_oa_regional` | `base_regional` + `dim` | 与 full_oa_local 相同逻辑，paid/confirmed 字段置 null（regional 口径） |

### 注意事项

1. **双时区写入**：每次调度同时写入 `tz_type='local'` 和 `tz_type='regional'` 两个分区，查询时必须指定其中之一，否则数据翻倍。

2. **FULL JOIN 花费与表现数据**：OA 侧（曝光/点击/订单）与 Revenue 侧（花费）通过 FULL JOIN 合并，两侧均可能单独存在记录。当某广告有花费但无曝光/点击时，OA 侧字段为 null；反之亦然。汇总 ROAS 等比率指标时，需用 `NULLIF` 处理分母为 null 的情况。

3. **`avg_ads_ranks` 预计算陷阱**：该字段由 `location_in_ads / impression_cnt + 1` 在 CTE 层计算，已聚合为日粒度，**不可跨行 SUM 后再用于排名分析**，需回溯明细层重新计算。

4. **特定 placement 的点击口径差异**：placement ∈ `{3327, 3328, 3337, 3338, 3339}` 的 `click_cnt_1d` 使用 `raw_click_cnt` 而非标准 `click_cnt`，与其他 placement 口径不完全一致，跨 placement 汇总点击数时需注意。

5. **`traffic_source` 的 null 处理**：原始值为 0 的 `traffic_source` 在 revenue CTE 中已被替换为 null，以与 report_ng 对齐，GROUP BY 时注意 null 的聚合行为。

6. **跨日归因设计**：`base_oa` 和 `base_regional` 均取两天（`grass_date - 1` 至 `grass_date`）的明细数据，通过时间戳过滤对齐到当日边界，以保证跨自然日的订单归因完整性。

7. **`expense_rebate_free_credit_without_expiry` 单位**：ETL 中已将原始值除以 100000.0，表中存储为换算后值，与其他系统对账时需确认单位一致。

8. **参数化多地区调度**：ETL SQL 中的 `upper('mx')`、`America/Mexico_City` 等均为调度模板的参数化实例示例，实际通过 `${region}`、`${timezone}`、`${grass_date}` 参数覆盖所有 Shopee 运营地区，各地区按本地时区独立调度执行。

---

*文档生成时间：2026-05-20*