<!-- ads-workspace-gdoc-sync: gdoc_id=1zRSjO8UybrzwVHTcVSgCLbx5cuBf7FCPyay7q6RBwEQ gdoc_url=https://docs.google.com/document/d/1zRSjO8UybrzwVHTcVSgCLbx5cuBf7FCPyay7q6RBwEQ/edit -->

# mp_paidads.dws_advertise_user_exp_live_stream_performance_1d

**分层：** DWS（数据汇总层）
**主键：** `group_id` + `placement` + `entrance` + `pricing_type` + `streamer_type` + `ads_id` + `if_promote_others` + `tz_type` + `grass_region` + `grass_date`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日（T+1 调度；同时回刷过去 7 天的 `product_click_order` 归因数据）
**引用频次：** 0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表是直播广告用户实验（A/B Test）维度的日粒度汇总宽表，面向付费广告直播场景，记录各实验分组（`group_id`）在不同广告位（`placement`）、入口（`entrance`）、定价类型（`pricing_type`）、主播类型（`streamer_type`）、广告 ID（`ads_id`）等维度组合下的曝光、点击、观看、GMV、收入、归因订单等全套绩效指标，并按本地时区分区存储。

本表的核心使用场景是直播广告 A/B 实验效果评估：通过 `group_id` 区分实验组与对照组，对比各组在同一时间窗口内的广告效率（CPM、点击率、转化率）、GMV 贡献（direct / broad / daily / agent 多口径）以及收入结构（免费积分/付费积分拆分），为实验结论提供统一、可复现的数据底座。

本表还支持直播广告曝光位置分布分析（`view1_5` ~ `view30_plus`），帮助产品与运营团队判断不同曝光位对用户行为的影响，并提供多种 GMV 口径（含 $200/$500 单用户上限 cap）以支持抗异常值分析，具有较强的分析弹性。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型。当前写入值为 `'local'`（各地区按本地时区参数化调度）。查询时**必须**指定此字段，否则全表扫描。⚠️ 目前仅写入 `local` 分区，若未过滤将触发全表扫描且返回重复数据风险 |
| `grass_region` | string | 地区代码（大写，如 `'ID'`、`'TH'`、`'VN'`）。各地区由调度参数 `${region}` 参数化覆盖。 |
| `grass_date` | date | 广告绩效日期（本地时区）。 |

---

### 维度：主键与广告属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `group_id` | bigint | 用户实验分组 ID（A/B Test group），来源于 `mp_paidads.dim_live_stream_abtest_group__reg_s0_live`。⚠️ 本表仅包含能关联到实验分组的用户行为，未命中实验组的数据不在此表中 |
| `ads_id` | bigint | 广告 ID。 |
| `placement` | string | 广告位标识，表示广告在直播间内的展示位置（如 `40`、`50` 等）。 |
| `entrance` | string | 用户进入广告的入口标识（如 `27`、`28`、`37`、`39`、`48` 等）。 |
| `pricing_type` | int | 广告定价类型（如 CPM、CPC 等枚举值）。 |
| `streamer_type` | int | 主播类型，来源于 `livestream.ls_mart_dim_ls_session_ext`。 |
| `if_promote_others` | string | 是否推广他人商品标记，来源于 `livestream.ls_mart_dim_ls_session_ext`。⚠️ 该字段为维度过滤键之一，聚合时需注意是否需要按此字段分组，避免合并不同推广属性的数据 |

---

### 指标：曝光与观看行为

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_imp_cnt` | bigint | 广告曝光次数（impression count）。 |
| `ads_deduct_imp_cnt` | bigint | 扣费曝光次数（实际发生计费的曝光数）。 |
| `ads_view_cnt` | bigint | 广告观看次数（view count）。 |
| `ads_view_uu` | bigint | 有观看行为的独立用户数，通过 Bitmap UDF（`to_bitmap` / `bitmap_count`）计算去重。⚠️ 为预计算 UU，多行直接 SUM 会导致重复计数，跨维度聚合时需回溯明细层重新计算 |
| `ads_view_duration` | bigint | 用户观看总时长（单位：秒）。 |
| `view1_5` | bigint | 位于广告位 location 0~4 的观看次数（直播间展示位置区间 1-5）。 |
| `view6_10` | bigint | 位于广告位 location 5~9 的观看次数（直播间展示位置区间 6-10）。 |
| `view11_15` | bigint | 位于广告位 location 10~14 的观看次数（直播间展示位置区间 11-15）。 |
| `view16_20` | bigint | 位于广告位 location 15~19 的观看次数（直播间展示位置区间 16-20）。 |
| `view21_25` | bigint | 位于广告位 location 20~24 的观看次数（直播间展示位置区间 21-25）。 |
| `view26_30` | bigint | 位于广告位 location 25~29 的观看次数（直播间展示位置区间 26-30）。⚠️ 注意字段注释写的是"26~30"，但 ETL 实际逻辑为 `location between 25 and 29`，即闭区间 [25,29] |
| `view30_plus` | bigint | 广告位 location ≥ 30 的观看次数。 |

---

### 指标：点击行为

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_raw_click_cnt` | bigint | 原始点击次数（含重复点击）。 |
| `ads_raw_click_uu` | bigint | 有原始点击行为的独立用户数（Bitmap 去重）。⚠️ 为预计算 UU，跨维度聚合不可直接 SUM |
| `ads_product_clk_cnt` | bigint | 商品点击次数（product click）。 |
| `ads_product_clk_uu` | bigint | 有商品点击行为的独立用户数（Bitmap 去重）。⚠️ 为预计算 UU，跨维度聚合不可直接 SUM |

---

### 指标：广告费用与 CPM

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_revenue` | decimal(25,10) | 广告收入（本地货币），即广告主实际扣费金额。 |
| `ads_revenue_usd` | decimal(25,10) | 广告收入（USD），由本地货币除以汇率得出。⚠️ 依赖 `dim_exchange_rate` 当日汇率计算，跨日汇率不同时不可跨日直接 SUM |
| `expected_cpm` | decimal(25,10) | 预期千次展示费用（CPM），计算公式为 `expected_ads_rev / impression_cnt / 1000`。⚠️ 为派生比率字段，不可直接 SUM；多维度汇总需用 `SUM(ads_revenue) / SUM(ads_imp_cnt) * 1000` 重新计算 |
| `rev_free_credit_with_expiry` | decimal(25,10) | 使用有期限免费积分（free credit with expiry）的广告扣费金额。 |
| `rev_free_credit_without_expiry` | decimal(25,10) | 使用无期限免费积分（free credit without expiry）的广告扣费金额。 |
| `rev_paid_credit_with_expiry` | decimal(25,10) | 使用有期限付费积分（paid credit with expiry）的广告扣费金额。 |
| `rev_paid_credit_without_expiry` | decimal(25,10) | 使用无期限付费积分（paid credit without expiry）的广告扣费金额。 |

---

### 指标：直接归因订单（Direct）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_direct_order_cnt` | bigint | 直接归因订单数（用户点击广告后产生的订单）。来源：`mp_paidads.dwd_livestream_performance_di__reg_s0_live`。 |
| `ads_direct_order_uu` | bigint | 有直接归因订单的独立用户数（Bitmap 去重）。⚠️ 为预计算 UU，跨维度聚合不可直接 SUM |
| `ads_direct_item_sold_cnt` | bigint | 直接归因订单的商品销售件数。 |
| `ads_direct_item_sold_uu` | bigint | 有直接归因商品销售的独立用户数（Bitmap 去重）。⚠️ 为预计算 UU，跨维度聚合不可直接 SUM |
| `ads_direct_gmv` | decimal(25,10) | 直接归因订单 GMV（本地货币）。 |
| `ads_direct_gmv_usd` | decimal(25,10) | 直接归因订单 GMV（USD）。⚠️ 依赖当日汇率，跨日聚合请注意汇率一致性 |
| `ads_direct_gmv_usd_200` | decimal(25,10) | 直接归因 GMV（USD），单用户贡献上限 $200。⚠️ 为 cap 后的预计算值，不可直接 SUM 后作为未 cap 的 GMV 使用 |
| `ads_direct_gmv_usd_500` | decimal(25,10) | 直接归因 GMV（USD），单用户贡献上限 $500。⚠️ 为 cap 后的预计算值，不可直接 SUM 后作为未 cap 的 GMV 使用 |
| `product_click_order` | bigint | 商品点击当日产生的直接归因订单数（product_click_date = grass_date 的订单）。⚠️ 该字段有时效性：每次调度时会回刷过去 7 天的数据（`product_click_order_new + product_click_order` 累加），最终值包含跨天延迟归因；若只需当日点击当日下单，勿直接使用此字段做横向对比，需了解其 7 天滚动更新机制 |

---

### 指标：宽泛归因订单（Broad，7 天归因窗口）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_broad_order_cnt` | bigint | 宽泛归因订单数（L7D 广告点击窗口内的订单），来源：`mp_paidads.dwd_livestream_performance_di__reg_s0_live`。详见 [Confluence](https://confluence.shopee.io/x/XjJ0CQ)。 |
| `ads_broad_order_uu` | bigint | 有宽泛归因订单的独立用户数（Bitmap 去重）。⚠️ 为预计算 UU，跨维度聚合不可直接 SUM |
| `ads_broad_item_sold_cnt` | bigint | 宽泛归因订单的商品销售件数。详见 [Confluence](https://confluence.shopee.io/x/XjJ0CQ)。 |
| `ads_broad_item_sold_uu` | bigint | 有宽泛归因商品销售的独立用户数（Bitmap 去重）。⚠️ 为预计算 UU，跨维度聚合不可直接 SUM |
| `ads_broad_gmv` | decimal(25,10) | 宽泛归因订单 GMV（本地货币）。 |
| `ads_broad_gmv_usd` | decimal(25,10) | 宽泛归因订单 GMV（USD）。⚠️ 依赖当日汇率换算 |
| `ads_broad_gmv_usd_200` | decimal(25,10) | 宽泛归因 GMV（USD），单用户贡献上限 $200。⚠️ ETL 中在最终 INSERT 阶段由 `broad_gmv_amt_local / exchange_rate` 实时 cap 计算；为 cap 后预计算值，不可直接 SUM 后作为未 cap 的 GMV 使用 |
| `ads_broad_gmv_usd_500` | decimal(25,10) | 宽泛归因 GMV（USD），单用户贡献上限 $500。⚠️ 同上，为 cap 后预计算值 |
| `checkout_cnt` | bigint | 宽泛归因结账订单数（L7D 广告点击窗口内，按 `orderid` count distinct 计算）。 |

---

### 指标：当日归因订单（Daily）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_daily_item_sold_cnt` | bigint | 与点击同日产生的直接订单的商品销售件数（click 与 order 同一自然日）。 |
| `ads_daily_item_sold_uu` | bigint | 有当日归因商品销售的独立用户数（Bitmap 去重）。⚠️ 为预计算 UU，跨维度聚合不可直接 SUM |
| `ads_daily_gmv` | decimal(25,10) | 当日归因订单 GMV（本地货币），即点击与下单在同一天的 GMV。 |
| `ads_daily_gmv_usd` | decimal(25,10) | 当日归因订单 GMV（USD）。⚠️ 依赖当日汇率换算 |
| `ads_daily_gmv_usd_200` | decimal(25,10) | 当日归因 GMV（USD），单用户贡献上限 $200。⚠️ 为 cap 后预计算值，不可直接 SUM 后作为未 cap 的 GMV 使用 |
| `ads_daily_gmv_usd_500` | decimal(25,10) | 当日归因 GMV（USD），单用户贡献上限 $500。⚠️ 为 cap 后预计算值，不可直接 SUM 后作为未 cap 的 GMV 使用 |

---

### 指标：代理人归因订单（Agent）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `agent_order_cnt` | bigint | 代理人（agent）点击归因的总订单数（一日内有 agent 点击的订单）。详见 [Confluence](https://confluence.shopee.io/x/_wVjhw)。 |
| `agent_item_cnt` | bigint | 代理人归因订单的商品销售件数。 |
| `agent_checkout` | bigint | 代理人归因结账订单数（按 `orderid` count distinct，订单内任一商品有 agent 点击即计入）。 |
| `agent_gmv_amt_local` | decimal(25,10) | 代理人归因订单 GMV（本地货币）。⚠️ 仅来源于 `dwd_livestream_performance_di__reg_s0_live`；来自 `dwd_advertise_performance_di` 的数据此字段为 NULL |
| `agent_gmv_amt_usd` | decimal(25,10) | 代理人归因订单 GMV（USD）。⚠️ 依赖当日汇率换算；同样仅来源于直播 DWD 表，其他来源为 NULL |

---

### 指标：付费订单（Paid Order）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `paid_order_cnt` | bigint | 已付款订单数。 |
| `paid_order_item_sold_cnt` | bigint | 已付款订单的商品销售件数。 |
| `paid_order_gmv_local` | double | 已付款订单 GMV（本地货币）。 |
| `paid_order_gmv_usd` | double | 已付款订单 GMV（USD）。 |
| `paid_checkout_cnt` | bigint | 已付款结账订单数。 |

---

### 指标：曝光归因订单（Impression Attribution）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `imp_attr_order_cnt` | bigint | 曝光归因订单数（impression attributed orders）。 |
| `imp_attr_order_item_sold_cnt` | bigint | 曝光归因订单的商品销售件数。 |
| `imp_attr_order_gmv` | double | 曝光归因订单 GMV。 |
| `imp_attr_paid_order_cnt` | bigint | 曝光归因已付款订单数。 |
| `imp_attr_paid_order_item_sold_cnt` | bigint | 曝光归因已付款订单的商品销售件数。 |

---

### 指标：广告价值（ADVV）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `advv` | double | 直接归因 GMV 的广告价值（Advertiser Value，direct GMV 口径），计算公式为 `direct_gmv_usd * target_cir`（当 `order_gmv_usd > 0` 时才计算，否则为 NULL）。⚠️ 为派生字段，依赖 `target_cir` 参数；NULL 值不等于 0，聚合时注意 `SUM` 会忽略 NULL |
| `advv_broad` | double | 宽泛归因 GMV 的广告价值（Advertiser Value，broad GMV 口径），计算公式为 `broad_gmv_usd * target_cir`（当 `broad_gmv_usd > 0` 时才计算，否则为 NULL）。⚠️ 同上，NULL 值不等于 0 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**指定以下分区字段，否则将触发全表扫描，影响查询性能并可能产生错误结果：

| 字段 | 推荐过滤值 | 遗漏后果 |
|------|-----------|---------|
| `tz_type` | `= 'local'` | 目前仅写入 `local` 分区；若不过滤将扫描全部分区，在未来有新 tz_type 写入时会导致数据重复 |
| `grass_region` | 指定目标地区，如 `= 'ID'` | 不过滤将全区扫描，显著增加计算成本 |
| `grass_date` | 指定具体日期或区间，如 `= '2025-01-01'` | 不过滤将扫描所有历史分区，导致查询超时或费用激增 |

**标准过滤模板：**
```sql
WHERE tz_type = 'local'
  AND grass_region = 'ID'
  AND grass_date = '2025-01-01'
```

### 不可直接 SUM 的字段

以下字段在跨行聚合或跨维度上卷时不能直接使用 `SUM`，需按正确方式重新计算：

| 字段 | 类型 | 正确计算方式 |
|------|------|------------|
| `ads_view_uu`、`ads_raw_click_uu`、`ads_product_clk_uu`、`ads_direct_order_uu`、`ads_direct_item_sold_uu`、`ads_broad_order_uu`、`ads_broad_item_sold_uu`、`ads_daily_item_sold_uu` | 预计算 Bitmap UU | 跨维度聚合需回溯 DWD 明细层用 `COUNT(DISTINCT user_id)` 重新计算；本表内各维度组合的 UU 已固化，无法合并去重 |
| `expected_cpm` | 派生比率 | 使用 `SUM(ads_revenue) / SUM(ads_imp_cnt) * 1000` 重新计算 |
| `ads_direct_gmv_usd_200`、`ads_direct_gmv_usd_500`、`ads_daily_gmv_usd_200`、`ads_daily_gmv_usd_500`、`ads_broad_gmv_usd_200`、`ads_broad_gmv_usd_500` | 已 cap 的预计算值 | 直接 SUM 会低估真实 GMV；若需未 cap 值请使用对应 `_usd` 无后缀字段；如需重新 cap 需回溯明细层 |
| `advv`、`advv_broad` | 派生值，含 NULL | 直接 `SUM` 会跳过 NULL（NULL ≠ 0）；聚合前请确认 NULL 的业务含义，必要时用 `SUM(COALESCE(advv, 0))` |
| `ads_revenue_usd`、`ads_direct_gmv_usd`、`ads_broad_gmv_usd`、`ads_daily_gmv_usd`、`agent_gmv_amt_usd`、`paid_order_gmv_usd` | 汇率换算值 | 跨日聚合时各日汇率不同，`SUM` 不影响加法本身，但结果含多日汇率混合，需注意口径一致性 |

### 时效性说明

本表存在 **7 天滚动回刷机制**：

- **当日分区**（`grass_date = T`）在 T+1 调度写入后已包含当日点击当日下单的 `product_click_order`。
- **T-1 至 T-7 分区**会在 T+1 调度时被回刷，将跨天延迟到达的点击归因订单（`product_click_order_new`）追加到对应历史分区的 `product_click_order` 字段中（累加写入）。
- 因此，若需分析 `product_click_order` 的最终稳定值，建议取 **`grass_date <= T-7`** 的分区；取近 7 天数据时需注意该字段仍在持续更新，数值尚未稳定。
- 其他指标字段（非 `product_click_order`）在当日分区写入后不再回刷，数值稳定。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 直播广告绩效明细（主要来源），提供曝光、点击、观看、GMV、agent 等原始事件行 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 通用广告绩效明细（补充来源），过滤 `placement in (40,50)` 且 `entrance in (27,28,37,39,48)` 的直播相关行；agent 字段在此来源中为 NULL |
| `mp_paidads.dim_live_stream_abtest_group__reg_s0_live` | 直播广告 A/B 实验用户分组维表，提供 `user_id → group_id` 映射；INNER JOIN，未命中实验分组的用户数据被排除 |
| `livestream.ls_mart_dim_ls_session_ext` | 直播场次扩展维表，提供 `ls_session_id → streamer_type`、`if_promote_others` 属性 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对 USD 的汇率，用于本地货币 → USD 换算 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_livestream_performance_di__reg_s0_live  ──┐
                                                          │  UNION ALL
mp_paidads.dwd_advertise_performance_di__reg_s0_live   ──┘
  (placement IN (40,50), entrance IN (27,28,37,39,48))
                        │
                        │ LEFT JOIN
                        ▼
         livestream.ls_mart_dim_ls_session_ext
         (补充 streamer_type, if_promote_others)
                        │
                        ▼
              [cache: ads_performance_origin]
                    (用户行级明细)
                        │
          ┌─────────────┴─────────────────────────┐
          │                                       │
          ▼                                       ▼
[view: product_click_order_attribution]   LEFT JOIN mp_order.dim_exchange_rate
  (按维度+product_click_date 预聚合             (汇率换算 USD 字段及 cap 计算)
   点击归因订单数)                                │
                                                  ▼
                                       [view: ads_performance_base]
                                       (用户维度聚合 + Bitmap UU + cap GMV)
                                                  │
                                                  │ INNER JOIN
                                                  ▼
                                  mp_paidads.dim_live_stream_abtest_group
                                        (关联实验分组 group_id)
                                                  │
                                                  ▼
                                  [view: live_stream_group_performance]
                                  (实验组 × 广告维度聚合，含 Bitmap UU)
                                                  │
                                                  │ LEFT JOIN mp_order.dim_exchange_rate
                                                  ▼
                               ┌──────────────────────────────────────────┐
                               │  INSERT OVERWRITE (当日分区 T)           │
                               │  dws_advertise_user_exp_live_stream_     │
                               │  performance_1d__reg_s0_live             │
                               └──────────────────────────────────────────┘
                                                  │
                               ┌──────────────────┘
                               │  回刷：T-7 ~ T-1 分区
                               │  LEFT JOIN product_click_order_attribution
                               │  (product_click_date 在 [T-7, T-1] 的
                               │   跨天归因订单追加到历史分区 product_click_order)
                               │
                               ▼
                       INSERT OVERWRITE (历史分区 T-7 ~ T-1)
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `ads_performance_origin`（Cache Table） | `dwd_livestream_performance_di` + `dwd_advertise_performance_di` + `ls_mart_dim_ls_session_ext` | 合并两路 DWD 明细数据（UNION ALL），LEFT JOIN 直播场次维表补充主播类型和推广标记；输出用户行级事件明细 |
| `product_click_order_attribution`（Temp View） | `ads_performance_origin` | 按维度 + `product_click_date` 预聚合点击归因订单数，供回刷历史分区时使用 |
| `ads_performance_base`（Temp View） | `ads_performance_origin` + `dim_exchange_rate` | 在用户维度上汇总各指标（SUM），使用 Bitmap UDF 计算去重 UU，并完成 USD 换算及 $200/$500 cap 计算 |
| `live_stream_group_performance`（Temp View） | `ads_performance_base` + `dim_live_stream_abtest_group` | INNER JOIN 实验分组维表，将用户维度聚合提升为实验组维度聚合（引入 `group_id`）；同步计算 Bitmap UU |

### 注意事项

1. **实验组 INNER JOIN 过滤**：`live_stream_group_performance` 使用 INNER JOIN 关联 `dim_live_stream_abtest_group`，只有命中实验分组的用户数据才会写入本表。分析时需与全量数据对比时应注意覆盖口径差异。

2. **两路数据源的字段差异**：`dwd_advertise_performance_di` 来源的 agent 系列字段（`agent_gmv_amt_local`、`agent_order_cnt`、`agent_item_cnt`、`agent_checkout`）写入 NULL；分析 agent 指标时需确认数据来源结构。

3. **`product_click_order` 的累加回刷**：历史分区（T-7 ~ T-1）的 `product_click_order` 值通过 `product_click_order_new + product_click_order`（原值 + 增量）累加更新，而非替换；多次调度后该字段是累计归因订单数，请勿与其他每日快照字段混淆使用。

4. **Bitmap UDF 依赖**：本表 UU 类字段通过自定义 UDF `bitmap_count` + `to_bitmap`（JAR：`paidads-data-warehouse-udf-1.0.64.jar`）计算。已固化存储为整数，查询时无需特殊处理，但跨维度上卷时不能通过 SUM 合并。

5. **`expected_cpm` 为零值风险**：当 `impression_cnt = 0` 时，`expected_ads_rev / impression_cnt / 1000` 会产生除零异常或 NULL；查询时建议增加 `WHERE ads_imp_cnt > 0` 过滤或使用 `NULLIF(ads_imp_cnt, 0)` 保护。

6. **汇率口径一致性**：USD 类字段均使用 `grass_date` 当日汇率换算；跨日聚合 SUM USD 字段时，不同日期的汇率差异已固化在字段中，结果为混合汇率加总，在汇率波动明显的市场需谨慎解读。

7. **`view26_30` 字段口径**：字段注释描述为 "location between 26 and 30"，但 ETL 实际逻辑为 `location between 25 and 29`（闭区间 [25,29]），使用时以 ETL 代码为准。

---

*文档生成时间：2026-04-22*