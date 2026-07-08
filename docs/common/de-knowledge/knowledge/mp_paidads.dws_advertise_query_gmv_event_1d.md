<!-- ads-workspace-gdoc-sync: gdoc_id=1J3H74lPZtwgMeAeAlGOQIND1MO1HnkL0M-NXl5enjfU gdoc_url=https://docs.google.com/document/d/1J3H74lPZtwgMeAeAlGOQIND1MO1HnkL0M-NXl5enjfU/edit -->

# mp_paidads.dws_advertise_query_gmv_event_1d

**分层**：DWS（数据服务层）
**主键**：`tz_type` + `grass_region` + `grass_date` + `ads_id` + `placement` + `item_id` + `shop_id` + `query` + `keywords` + `match_type` + `matched_premium_segment_value` + `entrance` + `pricing_type`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1 调度）
**引用频次**：43 次（候选表范围内）

---

## 业务描述

本表是广告查询维度的日粒度汇总宽表，以"广告 × 用户搜索词（query）× 投放位置 × 商品"为核心分析单元，整合了曝光、点击、消耗、下单、支付、加购、GMV 等全链路广告绩效指标。它是 Paid Ads 业务分析最核心的服务层表之一，支撑广告效果归因、ROI 分析、搜索词报告、广告位分析等高频分析场景。

本表提供两套时区口径的数据：`tz_type='local'` 按各地区本地时区统计事件，适用于面向卖家的报告；`tz_type='regional'` 按新加坡时间（SGT，UTC+8）对齐统计，适用于跨地区横向比对。两套数据通过 `tz_type` 分区隔离，互不混淆。各地区通过 `${region}` 和 `${timezone}` 参数化调度，覆盖所有运营市场。

本表在下游被引用 43 次，是广告数据域使用频次最高的宽表之一，广泛服务于 BI 看板、营销效果归因报告、商家后台数据展示及广告算法特征工程等场景。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。`local` = 各地区本地时区口径；`regional` = 新加坡时间（SGT）口径。**每次查询必须指定此字段**，否则数据量翻倍。⚠️ `tz_type='regional'` 分区下 `paid_order_cnt`、`paid_order_cnt_ytd`、`confirmed_order_cnt`、`confirmed_order_cnt_ytd` 恒为 NULL，不可使用。 |
| `grass_region` | string | 国家/地区分区，大写字母，如 `'TW'`、`'ID'`、`'VN'` 等。**每次查询必须指定此字段**，避免全表扫描。 |
| `grass_date` | date | 日期分区，格式 `yyyy-MM-dd`。**每次查询必须指定此字段**。注意 `paid_order_cnt`、`confirmed_order_cnt` 等指标在当日分区存在上游延迟，需使用次日分区的 YTD 字段获取最终值（详见查询使用须知）。 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，唯一标识一条广告。 |
| `placement` | bigint | 广告投放位置编码。不同 placement 对应不同广告位（如搜索结果、猜你喜欢等）。⚠️ match_type 的计算逻辑依赖 placement 取值范围（如 placement IN (0,3,4,1000,1200) 才生效），跨 placement 聚合时需注意口径差异。 |
| `ads_type` | string | 广告类型，枚举值：`targeting:similar_product`、`keyword:search`、`targeting:daily_discover`、`keyword:simple_mode`、`targeting:ymal`、`targeting:simple_mode_ymal`、`targeting:simple_mode_sp`、`targeting:simple_mode_dd`。 |
| `pricing_type` | int | 广告计价类型编码，来源于广告维表。 |
| `product_placement` | int | 产品投放类型：`1`=搜索位（SEARCH）；`2`=定向位（TARGET）；`3`=全部（ALL，即 SEARCH ∨ TARGET）。来源于 `dim_product_campaign`。 |
| `new_boost` | bigint | 是否为新品广告，1 表示是，0 表示否。 |
| `entrance` | bigint | 广告入口标识。 |

---

### 维度：商品与卖家属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 广告商品 ID。⚠️ ETL 中对 NULL 做了 `COALESCE(item_id, 0)` 处理，0 表示无具体商品，过滤真实商品时需排除 `item_id = 0`。 |
| `item_name` | string | 商品名称，来源于广告维表。 |
| `shop_id` | bigint | 店铺 ID。 |
| `seller_id` | bigint | 卖家 ID。 |
| `seller_name` | string | 卖家用户名。 |

---

### 维度：搜索词与定向属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `query` | string | 用户搜索词，触发广告的原始 query。 |
| `keywords` | string | 广告主设置的关键词，用于匹配用户 query。 |
| `match_type` | bigint | 关键词匹配类型。仅在 `placement IN (0,3,4,1000,1200)`（local 口径）或 `placement IN (0,3,4)`（regional 口径）时有效，其余 placement 强制置 0。 |
| `matched_premium_segment_value` | string | 高级定向受众分群标签，由 `matched_premium_segment_value_id` 映射而来：`0`→`buyer_segment_behaviour_general_audience`，`1`→`view_in_shop`，`2`→`cart_in_shop`，`3`→`order_in_shop`，`4`→`like_in_shop`，`10`→`view_similar_item`。 |
| `location` | bigint | 广告商品在整个数据流中的位置，从 0 开始计数。⚠️ 该字段为行级别的位置值，不可直接 SUM 作为汇总排名，需结合 `location_in_ads` 和 `impression_cnt` 计算平均排名（即 `avg_ads_ranks`）。 |

---

### 维度：受众筛选条件

| 字段 | 类型 | 说明 |
|------|------|------|
| `filter_segments_age_start` | bigint | 广告受众年龄筛选条件的起始值，由 `filter_segments_age_list` 数组的最小值解析而来。 |
| `filter_segments_age_end` | bigint | 广告受众年龄筛选条件的终止值，由 `filter_segments_age_list` 数组的最大值解析而来。 |
| `filter_segments_gender_list` | string | 广告受众性别筛选条件列表。⚠️ 存储为列表/数组格式，直接字符串比较时需注意格式，建议使用 LIKE 或 JSON 解析函数处理。 |
| `filter_segments_location_list` | string | 广告受众地理位置筛选条件列表。⚠️ 同上，存储为列表格式。 |
| `filter_segments_category_list` | string | 广告受众类目筛选条件列表。⚠️ 同上，存储为列表格式。 |
| `premium_segments_behavior_list` | string | 高级定向行为分群列表，来源于广告维表。⚠️ 存储为列表格式，查询时需注意解析方式。 |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt` | bigint | 广告去重曝光次数（已去重，但可能包含作弊流量）。 |
| `click_cnt` | bigint | 成功扣费的有效点击次数（已去除作弊点击）。⚠️ 对于 placement IN (3327, 3328, 3337, 3338, 3339)，ETL 中使用 `raw_click_cnt` 替代 `click_cnt`，跨 placement 汇总时需注意口径统一性。 |
| `click_before_deduction_cnt` | bigint | 扣费前的原始点击次数（未过滤作弊）。 |
| `shopitem_impression_cnt` | bigint | 店铺广告商品曝光次数。 |
| `shopitem_click_cnt` | bigint | 店铺广告商品点击次数。 |
| `broad_shopitem_impression_cnt` | bigint | 广泛归因下店铺广告商品曝光次数（近一天内）。 |
| `broad_shopitem_click_cnt` | bigint | 广泛归因下店铺广告商品点击次数（近一天内）。 |
| `avg_ads_ranks` | double | 广告平均排名，计算公式为 `location_in_ads / impression_cnt + 1`。⚠️ 为预计算比率，**不可直接 SUM**，多行聚合时需用原始分子（`location_in_ads` 之和）除以原始分母（`impression_cnt` 之和）再加 1 重新计算；`location_in_ads` 字段未输出至本表，需从上游获取。 |
| `view_cnt` | bigint | 广告浏览次数（view）。 |
| `product_click_cnt` | bigint | 产品点击次数（已去重），**仅针对视频广告**。⚠️ 非视频广告该字段为 NULL 或 0，跨广告类型聚合时需注意。 |

---

### 指标：消耗

| 字段 | 类型 | 说明 |
|------|------|------|
| `expenditure_amt_local` | double | 广告扣费金额（本地货币）。 |
| `expenditure_amt_usd` | double | 广告扣费金额（美元），由本地货币除以汇率换算得到。⚠️ 汇率为当日快照值，历史跨期汇总时汇率可能不一致，不建议跨日直接 SUM USD 字段后再对比本地货币。 |

---

### 指标：直接归因订单（Direct Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt` | bigint | 直接广告归因订单商品数（placed order-item count），统计 grass_date 当天下单量。 |
| `daily_order_cnt` | bigint | 与点击发生在同一天的直接广告归因订单数。 |
| `checkout_cnt` | bigint | 宽泛归因下的结算笔数（按 orderid 去重），订单内任意商品在 L7D 内有广告点击即计入。 |
| `ads_items_sold_cnt` | bigint | 直接归因订单销售商品数量。 |
| `ads_gmv_amt_local` | double | 直接归因订单 GMV（本地货币）。 |
| `ads_gmv_amt_usd` | double | 直接归因订单 GMV（美元），由本地货币除以汇率换算。⚠️ 同 `expenditure_amt_usd`，跨日汇总时汇率快照不同，不建议直接跨日 SUM。 |
| `add_to_cart_cnt` | bigint | 直接归因加购/立即购买次数：仅广告商品被成功加购，且归因至 1 天窗口内最近一次非作弊广告点击（同商品）。 |
| `add_to_cart_without_clicks_cnt` | bigint | 超出 1 天点击窗口但仍属广告商品的加购次数（无法归因至点击的广告商品加购）。 |

---

### 指标：支付归因订单（Paid Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_order_cnt` | bigint | 支付归因订单数（当日 grass_date 的支付事件）。⚠️ **非最终值**，因上游支付验证延迟，grass_date 当日分区数据可能不完整。如需某日最终值，应取 grass_date+1 分区的 `paid_order_cnt_ytd`。`tz_type='regional'` 分区下此字段恒为 NULL。 |
| `paid_order_cnt_ytd` | bigint | grass_date 前一天的最终支付归因订单数（汇总了 grass_date-1 和 grass_date 两个分区的数据以覆盖延迟）。⚠️ 若要获取某日（如 2021-06-05）的最终支付订单数，应查询 grass_date=2021-06-06 的此字段。`tz_type='regional'` 分区下此字段恒为 NULL。 |
| `paid_order_item_sold_cnt` | bigint | 直接支付归因订单的商品销售数量（用户点击广告后 7 天内支付）。 |
| `paid_broad_order_cnt` | bigint | 广泛支付归因订单数：用户点击广告商品后，在同一店铺 7 天内支付的订单（含非广告商品）。 |
| `paid_broad_order_gmv` | double | 广泛支付归因订单 GMV（本地货币）。⚠️ 同 USD 换算字段，跨日汇率不同。 |
| `paid_broad_order_gmv_usd` | double | 广泛支付归因订单 GMV（美元）。⚠️ 由本地货币除以汇率换算，跨日直接 SUM 时汇率不一致。 |
| `paid_broad_order_item_sold_cnt` | bigint | 广泛支付归因订单商品销售数量。 |
| `paid_checkout_cnt` | bigint | 广泛支付归因结算笔数（按支付 orderid 去重，订单内任意商品在 L7D 内有广告点击）。 |

---

### 指标：确认归因订单（Confirmed Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `confirmed_order_cnt` | bigint | 确认归因订单数（当日 grass_date 的确认事件）。⚠️ **非最终值**，因上游确认验证延迟，当日分区数据可能不完整。如需某日最终值，应取 grass_date+1 分区的 `confirmed_order_cnt_ytd`。`tz_type='regional'` 分区下此字段恒为 NULL。 |
| `confirmed_order_cnt_ytd` | bigint | grass_date 前一天的最终确认归因订单数（汇总了 grass_date-1 和 grass_date 两个分区的数据）。⚠️ 使用方式同 `paid_order_cnt_ytd`，取次日分区才是完整数据。`tz_type='regional'` 分区下此字段恒为 NULL。 |

---

### 指标：广泛归因订单（Broad Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order_cnt` | bigint | 广泛归因订单数（参考 confluence 口径定义）。 |
| `broad_order_item_cnt` | bigint | 广泛归因订单商品销售数量。 |
| `broad_order_gmv_amt_local` | double | 广泛归因订单 GMV（本地货币）。 |
| `broad_order_gmv_amt_usd` | double | 广泛归因订单 GMV（美元）。⚠️ 由本地货币除以汇率换算，跨日直接 SUM 时汇率不一致。 |
| `broad_add_to_cart_cnt` | bigint | 广泛归因下加购总次数。 |

---

### 指标：曝光归因订单（Impression Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_attr_paid_order_cnt` | bigint | 曝光归因支付订单数：无广告点击但有广告曝光，且命中 shop_exp_tag 的广泛支付订单数。 |
| `imp_attr_paid_order_gmv` | double | 曝光归因支付订单 GMV（本地货币）。 |
| `imp_attr_paid_order_gmv_usd` | double | 曝光归因支付订单 GMV（美元）。⚠️ 由本地货币除以汇率换算，跨日直接 SUM 时汇率不一致。 |
| `imp_attr_paid_order_item_sold_cnt` | bigint | 曝光归因支付订单商品销售数量。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全分区扫描，导致严重性能问题和数据量倍增：

| 过滤条件 | 推荐写法示例 | 遗漏后果 |
|----------|-------------|---------|
| `tz_type` | `tz_type = 'local'`（面向卖家报告）或 `tz_type = 'regional'`（跨地区对比） | 数据量翻倍，两套时区口径混合，指标失准 |
| `grass_region` | `grass_region = 'TW'` | 扫描所有地区分区，性能极差，且混入多地区数据 |
| `grass_date` | `grass_date = '2024-01-01'` 或 `grass_date BETWEEN ... AND ...` | 全量历史扫描，资源消耗极大 |

**时区口径选择建议**：
- 分析面向卖家的广告报告、单地区效果分析：使用 `tz_type = 'local'`
- 跨地区横向对比、与平台整体大盘对齐：使用 `tz_type = 'regional'`
- **注意**：`tz_type = 'regional'` 分区下，`paid_order_cnt`、`paid_order_cnt_ytd`、`confirmed_order_cnt`、`confirmed_order_cnt_ytd` 均为 NULL，不可在该口径下使用这四个字段

---

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确计算方式 |
|------|---------|-------------|
| `avg_ads_ranks` | 预计算比率（`location_in_ads / impression_cnt + 1`），直接 SUM 无意义 | 需从上游获取 `location_in_ads` 汇总后除以 `impression_cnt` 汇总再加 1：`SUM(location_in_ads) / SUM(impression_cnt) + 1` |
| `ads_gmv_amt_usd` | 由本地货币除以当日汇率快照换算，跨日汇率不同 | 跨日聚合时应先 SUM 本地货币（`ads_gmv_amt_local`），再统一用目标日期汇率换算；或接受近似值直接 SUM |
| `expenditure_amt_usd` | 同上，跨日汇率不同 | 同上，建议先 SUM 本地货币再统一换算 |
| `broad_order_gmv_amt_usd` | 同上 | 同上 |
| `paid_broad_order_gmv_usd` | 同上 | 同上 |
| `imp_attr_paid_order_gmv_usd` | 同上 | 同上 |
| `location` | 行级位置值，直接 SUM 无业务含义 | 计算平均排名请使用 `avg_ads_ranks`，或用 `SUM(location_in_ads) / SUM(impression_cnt) + 1` 重算（`location_in_ads` 需从上游获取） |

---

### 时效性说明

以下四个字段存在**上游数据延迟**，当日分区值**不完整**，不可直接使用当日分区值作为最终数据：

| 字段 | 所在分区 | 问题 | 正确用法 |
|------|---------|------|---------|
| `paid_order_cnt` | `grass_date = D` | 支付验证延迟，D 日事件会同时落入 D 和 D+1 分区，当日值偏低 | 若需 D 日最终值，查 `grass_date = D+1` 的 `paid_order_cnt_ytd` |
| `paid_order_cnt_ytd` | `grass_date = D+1` | 记录的是 D 日的最终汇总值（D 和 D+1 两个分区合计） | 取 `grass_date = D+1` 的此字段即为 D 日完整数据 |
| `confirmed_order_cnt` | `grass_date = D` | 确认事件延迟，同 paid_order_cnt | 若需 D 日最终值，查 `grass_date = D+1` 的 `confirmed_order_cnt_ytd` |
| `confirmed_order_cnt_ytd` | `grass_date = D+1` | 记录的是 D 日的最终汇总值 | 取 `grass_date = D+1` 的此字段即为 D 日完整数据 |

> **示例**：如需 2024-06-05 的最终支付归因订单数，应执行：
> ```sql
> SELECT paid_order_cnt_ytd
> FROM mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live
> WHERE tz_type = 'local'
>   AND grass_region = 'XX'
>   AND grass_date = '2024-06-06'  -- 目标日期 +1
> ```

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 核心事件明细表，提供曝光、点击、消耗、直接归因订单、加购、GMV 等行级别性能指标 |
| `mp_paidads.dwd_advertise_order_attribution_di__reg_s0_live` | 订单归因明细表，提供支付归因（`paid_order_cnt`）和确认归因（`confirmed_order_cnt`）的 YTD 计算源数据 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维表，提供 `ads_type`、`item_name`、`seller_id`、`seller_name`、`pricing_type`、受众筛选条件等维度属性 |
| `mp_paidads.dim_product_campaign__reg_s0_live` | 产品投放活动维表，提供 `product_placement` 字段（按 campaign_id + shop_id 去重取最早记录） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供当日本地货币对美元汇率，用于将本地货币指标换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_advertise__reg_s0_live ──────────────────┐
mp_order.dim_exchange_rate__reg_s0_live ─────────────────┤
                                                          ▼
                                                    [CTE: dim]
                                                          │
mp_paidads.dwd_advertise_performance_di__reg_s0_live ────┤
    (grass_date = ${grass_date}, local tz)               │
                                                          ▼
                                                   [CTE: base]
                                                   (本地时区聚合)
                                                          │
mp_paidads.dwd_advertise_performance_di__reg_s0_live ────┤
    (grass_date D-1~D, 按事件时间戳过滤至D日, regional)  │
                                                          ▼
                                                 [CTE: base_reg]
                                                 (Regional时区聚合)
                                                          │
mp_paidads.dwd_advertise_order_attribution_di            │
    __reg_s0_live ───────────────────────────────────────┤
    (grass_date D-1~D, paid/confirmed事件)               │
                                                          ▼
                                               [CTE: oa → oa1/oa2]
                                               (paid/confirmed YTD拆分)
                                                          │
mp_paidads.dim_product_campaign__reg_s0_live ────────────┤
    (去重取最早记录)                                       │
mp_order.dim_exchange_rate__reg_s0_live ─────────────────┤
    (当日汇率，用于USD换算)                               │
                                                          ▼
                              ┌───────────────────────────┤
                              │                           │
                              ▼                           ▼
              INSERT OVERWRITE                  INSERT OVERWRITE
              tz_type='local'                  tz_type='regional'
              (base + dim + oa1 +              (base_reg + dim +
               oa2 + dim_product_campaign       dim_product_campaign
               + ex)                           + ex)
                              │                           │
                              └───────────────────────────┘
                                              │
                                              ▼
              mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `dim` | `dim_advertise__reg_s0_live` + `dim_exchange_rate__reg_s0_live` | 关联广告维表与汇率表，解析受众年龄列表为 start/end，构建广告维度属性快照 |
| `dim_product_campaign` | `dim_product_campaign__reg_s0_live` | 按 (campaign_id, shop_id) 去重，取 `campaign_modify_datetime` 最早的记录，获取 `product_placement` |
| `oa` | `dwd_advertise_order_attribution_di__reg_s0_live` | 读取 D-1 和 D 两日的归因订单数据，关联 dim 补充维度，映射 premium segment 标签 |
| `base` | `dwd_advertise_performance_di__reg_s0_live` + `dim` | 按本地时区口径聚合 D 日广告性能事件，关联维表补充 pricing_type 等字段 |
| `base_reg` | `dwd_advertise_performance_di__reg_s0_live` + `dim` | 按 Regional 时区口径（取 D-1~D 分区，按事件时间戳过滤至 D 日本地时间范围）聚合广告性能事件 |
| `oa1`（内联子查询） | `oa` | 按 paid_datetime 拆分为当日 `paid_order_cnt`（D 日）和 YTD `paid_order_cnt_ytd`（D-1 日），分组聚合 |
| `oa2`（内联子查询） | `oa` | 按 confirmed_datetime 拆分为当日 `confirmed_order_cnt`（D 日）和 YTD `confirmed_order_cnt_ytd`（D-1 日），分组聚合 |
| `ex`（内联子查询） | `dim_exchange_rate__reg_s0_live` | 获取当日汇率用于 USD 字段换算 |

---

### 注意事项

1. **双写分区机制**：ETL 通过两条独立的 `INSERT OVERWRITE` 语句分别写入 `tz_type='local'` 和 `tz_type='regional'` 分区。`local` 分区使用 `base`（按 grass_date 过滤的本地时区数据）；`regional` 分区使用 `base_reg`（按事件 Unix 时间戳二次过滤，跨 D-1/D 两日分区取 D 日 SGT 时间范围的事件）。

2. **Regional 分区的 YTD 字段为 NULL**：`tz_type='regional'` 分区下，`paid_order_cnt`、`paid_order_cnt_ytd`、`confirmed_order_cnt`、`confirmed_order_cnt_ytd` 在 ETL 中直接写入 `null`（无 oa1/oa2 关联），**不可在该口径下使用这四个指标**。

3. **click_cnt 口径差异**：对于 `placement IN (3327, 3328, 3337, 3338, 3339)` 的广告位，ETL 使用 `raw_click_cnt`（原始点击数）替代 `click_cnt`（扣费后点击数），原因是这些广告位的扣费逻辑不同。跨广告位汇总分析时应注意此口径不一致。

4. **match_type 有效范围不同**：`local` 口径（CTE `base`）中 match_type 在 `placement IN (0,3,4,1000,1200)` 时生效；`regional` 口径（CTE `base_reg`）中仅在 `placement IN (0,3,4)` 时生效（不含 1000、1200），两套口径存在细微差异，跨 tz_type 对比 match_type 分布时需注意。

5. **item_id = 0 的含义**：ETL 中对 `item_id` 做了 `COALESCE(item_id, 0)` 处理，`item_id = 0` 代表无具体商品归属的广告事件，过滤特定商品时需显式排除 `item_id = 0`。

6. **汇率为当日快照**：USD 换算字段（`ads_gmv_amt_usd`、`expenditure_amt_usd`、`broad_order_gmv_amt_usd`、`paid_broad_order_gmv_usd`、`imp_attr_paid_order_gmv_usd`）均使用当日 `dim_exchange_rate` 快照值换算，跨日期聚合时各日汇率不同，直接 SUM USD 字段会因汇率差异引入误差，建议先聚合本地货币再统一换算。

7. **参数化多地区调度**：表名后缀 `__reg_s0_live` 表示通过 `${region}`、`${grass_date}` 参数化调度，覆盖所有运营地区，各地区按本地时区参数化调度执行。ETL SQL 中出现的具体地区代码和时区值均为调度模板的实例示例，不代表数据仅覆盖单一地区。

---

*文档生成时间：2026-04-22*