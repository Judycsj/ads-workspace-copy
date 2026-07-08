<!-- ads-workspace-gdoc-sync: gdoc_id=1eCywnUD7YUDsN6Qtd5fFISMgWnvTP66rjJW7UeZhWzk gdoc_url=https://docs.google.com/document/d/1eCywnUD7YUDsN6Qtd5fFISMgWnvTP66rjJW7UeZhWzk/edit -->

# mp_paidads.dws_advertise_user_exp_common_feature_performance_1d

**分层：** DWS（数据服务层）
**主键：** `grass_region` + `grass_date` + `tz_type` + `user_id` + `item_id` + `shop_id` + `location` + `common_feature` + `app_version`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日（T+1 调度）
**引用频次：** 0（末端 ADS 层输出表，未被其他候选表直接引用）

---

## 业务描述

本表是付费广告（Paid Ads）用户体验层的核心宽表，以**用户 × 商品 × 功能入口特征（common_feature）× App 版本 × 日期**为粒度，整合了广告投放绩效、Omni 全链路用户行为及直播内容带货三大数据域的度量指标，是广告效果归因分析、ROI 核算与平台大盘洞察的基础数据源。

表中的 `common_feature` 字段将平台各类广告入口（搜索、发现流、直播间、短视频等）统一映射至标准功能场景分类，并额外保留一个 `common_feature = 'Platform'` 的全量汇总口径，便于跨渠道横向对比。Omni 全链路指标则覆盖曝光→点击→商详页浏览（PPV）→加购（ATC）→下单→成交 GMV 的完整转化漏斗，并按广告（ads）/ 自然（organic）/ 全量（total）三种归因视角分别存储，支持广告增量价值（Incrementality）的精细化分析。

典型使用场景包括：广告主 ROI 报表（直接归因与宽泛归因对比）、平台各入口广告效率看板、商品维度的广告/自然流量结构分析、直播带货广告专项分析，以及以 `common_feature = 'Platform'` 为口径的全平台大盘 GMV 核算。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型标识，各地区按本地时区参数化调度，常规查询应过滤 `tz_type = 'local'`。⚠️ 遗漏此过滤条件将导致跨时区重复计算。 |
| `grass_region` | string | 地区标识（大写，如 `'MX'`、`'TH'`），表通过 `${region}` 参数化覆盖所有运营地区，必须指定以避免全表扫描。 |
| `grass_date` | date | 广告绩效所属日期（按本地时区），必须指定以缩小扫描范围。 |

---

### 维度：主键与用户商品属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 用户 ID；ETL 过滤 `user_id > 0`，无效用户已排除。 |
| `item_id` | bigint | 商品 ID；NULL 已兜底为 `-1`（如直播场景下无特定商品时）。 |
| `shop_id` | bigint | 店铺 ID。 |
| `location` | bigint | 商品位置信息；NULL 已兜底为 `-1`。 |
| `common_feature` | string | 标准化功能入口分类（如 `'Search Shop'`、`'Daily Discover'`、`'Live Streaming'`、`'Platform'` 等）；`'Platform'` 为跨渠道全量汇总口径，`'Others'` 已在写出前过滤。⚠️ 同一用户在同一天可能同时存在 `'Platform'` 行与具体渠道行，对 `'Platform'` 和具体渠道行直接 SUM 会造成重复计算。 |
| `app_version` | string | 客户端版本号，NULL 已转为 `'null'`，短版本号已补全为 `x.xx.xx` 格式。 |

---

### 维度：商品广告类型标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `if_ads_item` | int | 当日该商品在对应 `common_feature` 下是否有广告曝光：`1`=有，`0`=无。⚠️ 不可 SUM，为 0/1 标志位，需用 `SUM(IF(if_ads_item=1,1,0))` 统计有曝光的商品数。 |
| `if_roi1_item` | int | 该商品在对应 `common_feature` 下是否有 ROI1 类广告曝光（`pricing_type IN (1,2,3,4,7,8)`）：`1`=有，`0`=无。⚠️ 同上，不可直接 SUM。 |
| `if_roi2_item` | int | 该商品在对应 `common_feature` 下是否有 ROI2 类广告曝光（`placement = 40`）：`1`=有，`0`=无。⚠️ 同上，不可直接 SUM。 |
| `if_new_product_boost` | int | 该商品在对应 `common_feature` 下是否有新品加速（NPB）广告曝光（`pricing_type=13` 或 `new_product_boost_stage IN (1,2)`）：`1`=有，`0`=无。⚠️ 同上，不可直接 SUM。 |
| `if_simple2_item` | int | 该商品在对应 `common_feature` 下是否有 Simple ROI2 广告曝光（`pricing_type=15`）：`1`=有，`0`=无。⚠️ 同上，不可直接 SUM。 |

---

### 指标：付费广告曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_impr_cnt` | bigint | 广告曝光次数（含扣费与非扣费），来源：`dwd_advertise_performance_di.impression_cnt`。 |
| `ads_deduction_impression_cnt` | bigint | 扣费曝光次数，来源：`dwd_advertise_performance_di.deduct_impression`。 |
| `ads_click_cnt` | bigint | 原始点击次数（raw_click），来源：`dwd_advertise_performance_di`。 |
| `ads_deduction_click_cnt` | bigint | 扣费点击次数，来源：`dwd_advertise_performance_di.click_cnt`。 |
| `ads_atc_cnt` | bigint | 广告带来的加购次数，为 `add_to_cart_cnt` 与 `add_to_cart_without_clicks_cnt` 之和，来源：`dwd_advertise_performance_di`。 |

---

### 指标：付费广告直接归因订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_direct_order_cnt` | bigint | 直接归因订单数，来源：`dwd_advertise_performance_di.order_cnt`。 |
| `ads_direct_gmv` | decimal(25,10) | 直接归因 GMV（本地货币），来源：`dwd_advertise_performance_di.ads_order_gmv_local`。 |
| `ads_gmv_usd` | decimal(25,10) | 直接归因 GMV（USD），由本地货币除以汇率换算。 |
| `ads_gmv_200_cap_usd` | decimal(25,10) | 直接归因 GMV（USD），单笔上限截断为 200 USD。⚠️ 为预处理截断值，不可与 `ads_gmv_usd` 混用，仅用于特定 ROI 模型中的防异常值场景。 |
| `ads_gmv_500_cap_usd` | decimal(25,10) | 直接归因 GMV（USD），单笔上限截断为 500 USD。⚠️ 同上，仅用于特定 ROI 模型。 |
| `ads_direct_item_sold_cnt` | bigint | 直接归因售出商品件数，来源：`dwd_advertise_performance_di.ads_item_sold_cnt`。 |

---

### 指标：付费广告宽泛归因订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_broad_order_cnt` | bigint | 宽泛归因订单数（含间接转化），来源：`dwd_advertise_performance_di.broad_order_cnt`。 |
| `ads_broad_gmv` | decimal(25,10) | 宽泛归因 GMV（本地货币），来源：`dwd_advertise_performance_di.broad_gmv_amt_local`。 |
| `ads_broad_gmv_usd` | decimal(25,10) | 宽泛归因 GMV（USD）。 |
| `ads_broad_gmv_200_cap_usd` | decimal(25,10) | 宽泛归因 GMV（USD），单笔上限截断为 200 USD。⚠️ 同 `ads_gmv_200_cap_usd`，仅用于特定模型。 |
| `ads_broad_gmv_500_cap_usd` | decimal(25,10) | 宽泛归因 GMV（USD），单笔上限截断为 500 USD。⚠️ 同上。 |
| `ads_broad_item_sold_cnt` | bigint | 宽泛归因售出商品件数，来源：`dwd_advertise_performance_di.broad_item_cnt`。 |

---

### 指标：付费广告收入（花费）与佣金

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_revenue` | decimal(25,10) | 广告花费（本地货币），即从交易流水扣除的广告费用，来源：`dwd_advertise_performance_di.expenditure_amt_local`。 |
| `ads_revenue_usd` | decimal(25,10) | 广告花费（USD），由本地货币除以汇率换算。 |
| `ads_revenue_roi2` | decimal(25,10) | ROI2 口径广告花费（本地货币），仅统计 `placement=40` 的记录。⚠️ 为特定投放类型的子集，与 `ads_revenue` 口径不同，不可混用。 |
| `ads_revenue_usd_roi2` | decimal(25,10) | ROI2 口径广告花费（USD）。⚠️ 同上。 |
| `ads_commision_fee` | decimal(25,10) | 广告带来订单的平台佣金（本地货币），按订单 GMV 占比从 `mp_order.dwd_order_item_place_pay_complete_di` 分摊。⚠️ 已按 GMV 比例预分摊，不可直接 SUM 后与其他口径佣金叠加。 |
| `ads_commision_fee_usd` | decimal(25,10) | 广告带来订单的平台佣金（USD）。⚠️ 同上。 |

---

### 指标：付费广告直播专项

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_live_view_cnt` | bigint | 广告带来的直播观看次数，来源：`dwd_advertise_performance_di.view`。 |
| `ads_live_view_duration` | bigint | 广告带来的直播观看时长（秒），来源：`dwd_advertise_performance_di.view_duration`。 |
| `ads_live_item_click_cnt` | bigint | 广告带来的直播间商品点击次数，来源：`dwd_advertise_performance_di.product_click`。 |

---

### 指标：内容直播广告订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `content_live_ads_direct_order_cnt` | bigint | 内容直播广告直接归因订单数，来源：`mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di`，限 `from_source_page='streaming_room'` 且 `is_content_directly_related=1`。 |
| `content_live_ads_direct_item_sold_cnt` | bigint | 内容直播广告直接归因售出件数。 |
| `content_live_ads_direct_gmv` | decimal(25,10) | 内容直播广告直接归因 GMV（本地货币）。 |
| `content_live_ads_direct_gmv_usd` | decimal(25,10) | 内容直播广告直接归因 GMV（USD）。 |
| `content_live_ads_broad_order_cnt` | bigint | 内容直播广告宽泛归因订单数（含直接+间接）。 |
| `content_live_ads_broad_item_sold_cnt` | bigint | 内容直播广告宽泛归因售出件数。 |
| `content_live_ads_broad_gmv` | decimal(25,10) | 内容直播广告宽泛归因 GMV（本地货币）。 |
| `content_live_ads_broad_gmv_usd` | decimal(25,10) | 内容直播广告宽泛归因 GMV（USD）。 |
| `content_live_ads_view_cnt` | bigint | 内容直播广告观看次数，来源：`livestream.ls_mart_dwd_traffic_ls_session_view_detail_di`。 |
| `content_live_ads_item_click_cnt` | bigint | 内容直播广告商品点击次数（含 buy_now、atc、item_card、display_window 等入口），来源：`livestream.ls_mart_dwd_traffic_ls_session_view_detail_di`。 |
| `content_live_ads_view_duration` | bigint | 内容直播广告累计观看时长（秒），来源：`livestream.ls_mart_dwd_view_streaming_detail_di.duration_b`。 |

---

### 指标：Omni 全链路入口曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `omni_entry_impr_cnt` | bigint | Omni 渠道入口总曝光数，来源：`traffic_omni_oa.dwd_scenario_event_log_di`。 |
| `omni_entry_impr_ads_cnt` | bigint | Omni 渠道入口广告曝光数。 |
| `omni_entry_impr_organic_cnt` | bigint | Omni 渠道入口自然曝光数。 |
| `omni_entry_click_cnt` | bigint | Omni 渠道入口总点击数。 |
| `omni_entry_click_ads_cnt` | bigint | Omni 渠道入口广告点击数。 |
| `omni_entry_click_organic_cnt` | bigint | Omni 渠道入口自然点击数。 |

---

### 指标：Omni 全链路商品曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `omni_item_impr_cnt` | bigint | Omni 渠道商品总曝光数，来源：`traffic_omni_oa.dwd_item_event_log_di`，含多层归因路径（step 0/1/2/Platform）聚合。 |
| `omni_item_impr_ads_cnt` | bigint | Omni 渠道商品广告曝光数。 |
| `omni_item_impr_organic_cnt` | bigint | Omni 渠道商品自然曝光数。 |
| `omni_item_click_cnt` | bigint | Omni 渠道商品总点击数。 |
| `omni_item_click_ads_cnt` | bigint | Omni 渠道商品广告点击数。 |
| `omni_item_click_organic_cnt` | bigint | Omni 渠道商品自然点击数。 |

---

### 指标：Omni 全链路商详页浏览（PPV）与停留时长

| 字段 | 类型 | 说明 |
|------|------|------|
| `omni_ppv_cnt` | bigint | Omni 渠道商品详情页总浏览次数，来源：`traffic_omni_oa.dwd_product_page_view_di`，已排除返回页（`is_back=false`）。 |
| `omni_ads_ppv_cnt` | bigint | Omni 渠道广告带来的商品详情页浏览次数。 |
| `omni_organic_ppv_cnt` | bigint | Omni 渠道自然流量带来的商品详情页浏览次数。 |
| `omni_stay_time` | bigint | Omni 渠道商品详情页总停留时长（秒）。 |
| `omni_ads_stay_time` | bigint | Omni 渠道广告带来的商品详情页停留时长（秒）。 |
| `omni_organic_stay_time` | bigint | Omni 渠道自然流量带来的商品详情页停留时长（秒）。 |

---

### 指标：Omni 全链路加购（ATC）

| 字段 | 类型 | 说明 |
|------|------|------|
| `omni_atc_cnt` | bigint | Omni 渠道加购成功总次数，来源：`traffic_omni_oa.dwd_atc_event_di`，限 `operation='action_add_to_cart_success'`。 |
| `omni_ads_atc_cnt` | bigint | Omni 渠道广告带来的加购成功次数。 |
| `omni_organic_atc_cnt` | bigint | Omni 渠道自然流量带来的加购成功次数。 |

---

### 指标：Omni 全链路订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `omni_order_cnt` | decimal(25,10) | Omni 渠道总订单量（加权值），按 `order_fraction × atc_prorate × first_touchpoint_item` 加权计算，来源：`traffic_omni_oa.dwd_order_item_atc_journey_di`。⚠️ 为分摊加权后的非整数值（decimal 类型），不等同于实际订单数量，SUM 后结果可能为小数。 |
| `omni_ads_order_cnt` | decimal(25,10) | Omni 渠道广告归因订单量（加权）。⚠️ 同上。 |
| `omni_organic_order_cnt` | decimal(25,10) | Omni 渠道自然归因订单量（加权）。⚠️ 同上。 |
| `omni_gmv` | decimal(25,10) | Omni 渠道总 GMV（本地货币），按 `gmv × atc_prorate × first_touchpoint_item` 加权，来源：`traffic_omni_oa.dwd_order_item_atc_journey_di`。⚠️ 为分摊加权 GMV，口径与 `ads_direct_gmv` 不同，不可混合 SUM。 |
| `omni_ads_gmv` | decimal(25,10) | Omni 渠道广告归因 GMV（本地货币）。⚠️ 同上。 |
| `omni_organic_gmv` | decimal(25,10) | Omni 渠道自然归因 GMV（本地货币）。⚠️ 同上。 |
| `omni_gmv_usd` | decimal(25,10) | Omni 渠道总 GMV（USD）。⚠️ 同上。 |
| `omni_ads_gmv_usd` | decimal(25,10) | Omni 渠道广告归因 GMV（USD）。⚠️ 同上。 |
| `omni_organic_gmv_usd` | decimal(25,10) | Omni 渠道自然归因 GMV（USD）。⚠️ 同上。 |
| `omni_item_sold_cnt` | bigint | Omni 渠道总售出件数，来源：`traffic_omni_oa.dwd_order_item_atc_journey_di`。 |
| `omni_ads_item_sold_cnt` | bigint | Omni 渠道广告归因售出件数。 |
| `omni_organic_item_sold_cnt` | bigint | Omni 渠道自然归因售出件数。 |

---

### 指标：Omni 全链路佣金

| 字段 | 类型 | 说明 |
|------|------|------|
| `omni_commission_fee` | decimal(25,10) | Omni 渠道总佣金（本地货币），按 GMV 占比分摊，来源：`traffic_omni_oa.dwd_order_item_atc_journey_di`。⚠️ 已预分摊，口径与 `ads_commision_fee` 独立，不可叠加。 |
| `omni_ads_commission_fee` | decimal(25,10) | Omni 渠道广告归因佣金（本地货币），仅含 `is_ads=true` 的记录。⚠️ 同上。 |
| `omni_organic_commission_fee` | decimal(25,10) | Omni 渠道自然归因佣金（本地货币），仅含 `is_ads=false` 或 NULL 的记录。⚠️ 同上。 |
| `omni_commission_fee_usd` | decimal(25,10) | Omni 渠道总佣金（USD）。⚠️ 同上。 |
| `omni_ads_commission_fee_usd` | decimal(25,10) | Omni 渠道广告归因佣金（USD）。⚠️ 同上。 |
| `omni_organic_commission_fee_usd` | decimal(25,10) | Omni 渠道自然归因佣金（USD）。⚠️ 同上。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全表扫描，导致资源超限或查询超时：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 同一天数据按不同时区口径重复存储，遗漏将导致指标翻倍计算 |
| `grass_region` | `grass_region = 'XX'`（具体地区代码，如 `'TH'`、`'MX'`） | 全地区扫描，数据量极大且结果混合多地区货币，直接 SUM 无业务意义 |
| `grass_date` | `grass_date = '2025-01-01'` 或日期范围 | 全量历史扫描，严重影响查询性能 |

此外，若需聚合特定渠道数据，建议同时指定 `common_feature` 过滤条件。**特别注意**：`common_feature = 'Platform'` 已包含所有渠道的全量数据，与各具体渠道行存在重叠，不可在同一 SUM 中混合使用。

---

### 不可直接 SUM 的字段

| 字段 | 问题类型 | 正确使用方式 |
|------|----------|--------------|
| `common_feature = 'Platform'` 行与具体渠道行 | 数据重叠 | 二选一口径：要么过滤 `common_feature = 'Platform'` 取全平台汇总，要么过滤具体渠道后 SUM，不可混合 |
| `omni_order_cnt` / `omni_ads_order_cnt` / `omni_organic_order_cnt` | 分摊加权 decimal，非整数 | 可 SUM 但结果为加权订单量，理解为"归因分摊订单数"，不等于实际成交笔数 |
| `omni_gmv` / `omni_ads_gmv` / `omni_organic_gmv`（及 USD 版本） | 分摊加权 GMV，口径与 `ads_direct_gmv` 不同 | 同一分析中选定一种 GMV 口径（ads 直接归因 vs omni 加权归因），不可相加 |
| `ads_gmv_200_cap_usd` / `ads_gmv_500_cap_usd` / `ads_broad_gmv_200_cap_usd` / `ads_broad_gmv_500_cap_usd` | 经过截断的预计算值 | 仅用于特定 ROI 防异常模型，不可替代 `ads_gmv_usd` / `ads_broad_gmv_usd` 作为常规 GMV 度量 |
| `ads_revenue_roi2` / `ads_revenue_usd_roi2` | 仅含 `placement=40` 子集 | 仅用于 ROI2 专项分析，不可与 `ads_revenue` 叠加 |
| `ads_commision_fee` / `ads_commision_fee_usd` | 按 GMV 比例预分摊 | 可 SUM，但注意其与 `omni_commission_fee` 系列来源不同、不可叠加 |
| `if_ads_item` / `if_roi1_item` / `if_roi2_item` / `if_new_product_boost` / `if_simple2_item` | 0/1 标志位 | 统计有标签的商品数量应使用 `COUNT(DISTINCT item_id) WHERE if_xxx_item = 1` 或 `SUM(IF(if_xxx_item=1,1,0))`，直接 SUM 无意义 |

---

### 时效性说明

本表为 T+1 调度，每日产出前一自然日（按本地时区）的数据。查询时应取 **已完成调度的最新 `grass_date`**，避免查询当日未完成写入的分区。若业务需要近实时数据，请结合 `_live` 后缀上游表自行加工。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告投放明细，提供曝光、点击、订单、GMV、花费等核心广告绩效指标 |
| `mp_paidads.dim_common_feature_mapping_v2__reg_s0_live` | 广告入口（entrance）到标准功能场景（common_feature）的映射维表 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，用于本地货币与 USD 之间的换算 |
| `mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live` | 订单商品成交明细，提供广告订单佣金（commission_fee）数据 |
| `mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di` | 内容直播订单 Omni 归因明细，提供直播广告直接/宽泛归因 GMV 与订单 |
| `livestream.ls_mart_dwd_traffic_ls_session_view_detail_di` | 直播流量会话明细，提供直播观看次数与商品点击数 |
| `livestream.ls_mart_dwd_view_streaming_detail_di` | 直播观看时长明细，提供 `duration_b` 观看时长 |
| `traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live` | 场景级事件日志，提供 Omni 渠道入口曝光与点击（区分 ads/organic） |
| `traffic_omni_oa.dwd_item_event_log_di__reg_sensitive_live` | 商品级事件日志，提供 Omni 渠道商品曝光与点击（多层归因路径） |
| `traffic_omni_oa.dwd_product_page_view_di__reg_sensitive_live` | 商品详情页浏览事件，提供 PPV 次数与停留时长（区分 ads/organic） |
| `traffic_omni_oa.dwd_atc_event_di__reg_sensitive_live` | 加购事件日志，提供加购成功次数（区分 ads/organic） |
| `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live` | 订单商品加购路径表，提供 Omni 渠道多层归因订单量、GMV、佣金、件数 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di
    └─► ads_base_info（格式标准化、佣金关联）
            └─► ads_performance_base [CACHE]（汇率换算、common_feature 映射、GMV Cap、ROI2 拆分）
                    ├─► ads_item_flag [CACHE]（商品广告曝光标志）
                    └─► [写出主干 - 付费广告侧]

mp_paidads.dim_common_feature_mapping_v2 ──────► ads_performance_base / ads_item_type_flag

mp_paidads.dwd_advertise_performance_di
    └─► ads_item_type_flag [CACHE]（ROI1/ROI2/NPB/Simple2 商品类型打标）

mp_order.dim_exchange_rate ────────────────────► ads_performance_base
mp_order.dwd_order_item_place_pay_complete_di ─► ads_base_info（order_commission_base）

mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di
    └─► content_live_details ─────────────────────────────────────────────┐
livestream.ls_mart_dwd_traffic_ls_session_view_detail_di                  │
    └─► content_user_view_click ──────────────────────────────────────────┤
livestream.ls_mart_dwd_view_streaming_detail_di                           │
ls_mart_dwd_traffic_ls_session_view_detail_di                             │
    └─► content_user_view_duration ───────────────────────────────────────┤
                                    content_live_metrics_all [CACHE] ◄────┘

traffic_omni_oa.dwd_scenario_event_log_di
    └─► omni_entry_point_operation [CACHE] ──────────────────────────────┐
traffic_omni_oa.dwd_item_event_log_di                                    │
    └─► omni_item_operation_base [CACHE] ────────────────────────────────┤
                                              omni_imp_clk ◄─────────────┘

traffic_omni_oa.dwd_product_page_view_di
    └─► omni_ppv_stay_time_base [CACHE] ─────────────────────────────────┐
traffic_omni_oa.dwd_atc_event_di                                         │
    └─► omni_atc_base [CACHE] ───────────────────────────────────────────┤
                                              omni_ppv_atc ◄─────────────┤
                                              （含 content_live_metrics_all）

traffic_omni_oa.dwd_order_item_atc_journey_di
mp_order.dwd_order_item_place_pay_complete_di
    └─► omni_order_gmv_base [CACHE] ─────────────────────────────────────┐
                                                                         │
omni_imp_clk + omni_ppv_atc + omni_order_gmv_base                       │
    └─► omni_imp_clk_ppv_atc_order_gmv（Omni 全链路汇总）◄──────────────┘

ads_performance_base  ─────────────────────────────────────────┐
omni_imp_clk_ppv_atc_order_gmv ────────────────────────────────┤ FULL JOIN
ads_item_flag ─────────────────────────────────────────────────┤ LEFT JOIN
ads_item_type_flag ────────────────────────────────────────────┘ LEFT JOIN
    └─► INSERT OVERWRITE
        dws_advertise_user_exp_common_feature_performance_1d
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `ads_base_info` | `dwd_advertise_performance_di`、`order_commission_base`（订单佣金子查询） | 广告投放明细格式标准化：NULL 值兜底、app_version 格式补全、佣金字段 LEFT JOIN 补充；UNION ALL 分有/无 order_id 两路处理 |
| `ads_performance_base` [CACHE] | `ads_base_info`、`dim_common_feature_mapping_v2`、`dim_exchange_rate` | 核心聚合：entrance → common_feature 映射（含 Platform 全量口径）、汇率换算、GMV 200/500 Cap、ROI2 收入拆分，按用户×商品×功能维度 GROUP BY |
| `ads_item_flag` [CACHE] | `ads_performance_base` | 按 `common_feature × item_id` 打广告曝光标志（`if_ads_item=1`），过滤 `impr > 0` |
| `ads_item_type_flag` [CACHE] | `dwd_advertise_performance_di`、`dim_common_feature_mapping_v2` | 按 `pricing_type` / `placement` / `new_product_boost_stage` 对商品打 ROI1/ROI2/NPB/Simple2 四类广告类型标志 |
| `omni_entry_point_operation` [CACHE] | `dwd_scenario_event_log_di` | 场景级入口曝光/点击统计，按 feature_group 等字段映射 common_feature，区分 ads/organic |
| `omni_item_operation_base` [CACHE] | `dwd_item_event_log_di` | 商品级曝光/点击统计，UNION ALL 分 step 0/1/2/Platform 四层归因路径 |
| `omni_ppv_stay_time_base` [CACHE] | `dwd_product_page_view_di` | 商品详情页 PPV 与停留时长，排除返回页，同样分四层归因路径处理 |
| `omni_atc_base` [CACHE] | `dwd_atc_event_di` | 加购成功次数，限 `action_add_to_cart_success`，分四层归因路径 |
| `omni_order_gmv_base` [CACHE] | `dwd_order_item_atc_journey_di`、`order_commission_base` | Omni 订单/GMV/佣金/件数，按 `order_fraction × atc_prorate × first_touchpoint_item` 加权分摊，分四层归因路径 |
| `content_live_details` | `dwd_ls_order_omni_local_content_final_detail_di` | 直播间广告订单/GMV，区分直接归因（direct）与宽泛归因（broad） |
| `content_user_view_click` | `ls_mart_dwd_traffic_ls_session_view_detail_di` | 直播观看次数与商品点击次数（多种点击入口） |
| `content_user_view_duration` | `ls_mart_dwd_view_streaming_detail_di` + `ls_mart_dwd_traffic_ls_session_view_detail_di` | 直播累计观看时长，通过 `view_event_id = event_id` 关联两表后聚合 `duration_b` |
| `content_live_metrics_all` [CACHE] | 上述三个 content CTE（FULL JOIN） | 直播内容全量指标宽表：观看、时长、点击、订单、GMV 整合 |
| `omni_imp_clk` | `omni_entry_point_operation` + `omni_item_operation_base`（FULL JOIN） | Omni 入口级 + 商品级曝光/点击合并 |
| `omni_ppv_atc` | `omni_ppv_stay_time_base` + `omni_atc_base` + `content_live_metrics_all`（FULL JOIN） | Omni PPV/ATC/停留时长 + 直播全量指标合并 |
| `omni_imp_clk_ppv_atc_order_gmv` | `omni_imp_clk` + `omni_ppv_atc` + `omni_order_gmv_base`（FULL JOIN） | Omni 全链路漏斗汇总：曝光→点击→PPV→ATC→订单→GMV，含直播指标 |

---

### 注意事项

1. **`common_feature` 双口径共存**：ETL 使用 `UNION ALL` 分两路写出，一路按 entrance 映射具体 `common_feature`，另一路固定写 `'Platform'`。因此，对任意用户×商品组合，同一天同时存在多行，各具体渠道行之和等于 `'Platform'` 行。查询时**必须明确选择一种口径**，不可混合 GROUP BY。

2. **Omni GMV/订单为加权分摊值**：`omni_order_cnt`、`omni_gmv` 等字段经 `order_fraction × atc_prorate × first_touchpoint_item` 加权，与广告直接归因的 `ads_direct_order_cnt`、`ads_direct_gmv` 统计口径完全不同，**不可在同一指标体系中混合计算 ROI**。

3. **多层归因路径（step 0/1/2/Platform）**：Omni 系列商品级指标基于 ATC journey 中的多层来源（`source1`、`source2`）反向归因，同一商品的曝光/点击/订单可能被归因至不同 `common_feature`，与广告侧的 entrance 映射逻辑不完全一致，跨系列对比时需留意口径差异。

4. **GMV Cap 字段的用途限制**：`ads_gmv_200_cap_usd`、`ads_gmv_500_cap_usd` 等截断字段仅供特定 ROI 计算模型（防异常高价订单）使用，常规报表和大盘指标应使用未截断的 `ads_gmv_usd` / `ads_broad_gmv_usd`。

5. **直播指标数据来源独立**：`content_live_ads_*` 系列来自内容直播专属数仓（`mp_content_oa`、`livestream` schema），与 `ads_live_*` 系列（来自 `dwd_advertise_performance_di`）统计口径和归因逻辑不同，前者为内容侧 Omni 归因，后者为广告投放侧直接归因，不可直接相加。

6. **地区参数化调度**：ETL SQL 中的具体地区代码和时区均为调度模板的参数实例，本表通过 `${region}`、`${timezone}` 参数化覆盖所有地区，各地区数据独立写入对应 `grass_region` 分区。

---

*文档生成时间：2026-05-20*