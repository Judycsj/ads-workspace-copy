<!-- ads-workspace-gdoc-sync: gdoc_id=1dE00dKJRmhAAUp0jFBg3fFnoOaqgr2oO10gLZbgU8Cg gdoc_url=https://docs.google.com/document/d/1dE00dKJRmhAAUp0jFBg3fFnoOaqgr2oO10gLZbgU8Cg/edit -->

# mp_paidads.dwd_advertise_performance_di

**分层**：DWD（数据明细层）
**主键**：`deduct_unique_id`（扣费事件唯一标识）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日全量覆盖写入（INSERT OVERWRITE）
**引用频次**：24 次（候选表范围内下游引用）

---

## 业务描述

本表是广告投放绩效的核心明细宽表，汇聚了 Shopee 广告平台（PaidAds）在各地区每日产生的全量广告事件数据，涵盖展示（Impression）、点击（Click）、CPM/CPC/CPS 扣费、订单归因（直接订单、宽泛订单、曝光归因订单、无点击订单）、直播广告互动等五类事件流，并通过多维度字段将广告属性、用户行为、费用明细、商品信息、受众定向等统一整合到单行记录中。

本表是广告报表系统（Report-NG）的基础数据源，支持广告主在不同口径下（place/paid/confirmed 订单、直接/宽泛归因、agent OA 链路等）统计消耗、GMV、ROAS、点击率、转化率等核心业务指标；同时也是下游 DWS/ADS 层聚合表、广告效果分析报告、AB 实验评估的主要来源。各地区通过 `${region}` / `${timezone}` 参数化调度，统一由本表覆盖全球所有上线市场。

由于本表同时记录扣费事件与归因事件，单行数据并非全字段填充——展示类行中的订单字段为 NULL，扣费类行中的部分维度字段为 NULL。使用时需根据业务分析目的选择合适的事件类型过滤条件，避免重复计算或指标错位。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区，当前写入固定为 `'local'`（本地时区）。⚠️ 每次查询必须指定 `tz_type = 'local'`，否则触发全分区扫描 |
| `grass_region` | string | 地区编码分区（大写，如 `'MY'`、`'TH'`、`'PH'` 等）。各地区按本地时区参数化调度写入。⚠️ 每次查询必须指定目标地区，否则触发全地区扫描 |
| `grass_date` | date | 日期分区，对应广告事件发生的本地日期。⚠️ 每次查询必须指定日期范围 |

---

### 维度：主键与广告标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `deduct_unique_id` | bigint | 扣费事件唯一标识，本表主键 |
| `original_deduct_unique_id` | bigint | CPS 补充扣费场景下，对应首次扣费的 `deduct_unique_id` |
| `click_event_id` | string | 点击事件唯一标识 |
| `request_id` | string | 广告请求 ID，由 BFF 在每次新请求时生成 |
| `raw_request_id` | string | 原始请求 ID |
| `unique_id` | string | 记录级唯一标识 |
| `ads_id` | bigint | 广告 ID |
| `campaign_id` | bigint | 广告计划 ID |
| `account_id` | bigint | 广告账户 ID |
| `shop_id` | bigint | 店铺 ID（由 `COALESCE(a.shop_id, c.shop_id)` 修复，优先取事件流中的值，缺失时回退到广告维度表） |
| `item_id` | bigint | 广告推广商品 ID |
| `model_id` | bigint | 真实商品规格 ID |
| `v_item_id` | bigint | 虚拟商品 ID |
| `v_model_id` | bigint | 虚拟商品规格 ID |
| `original_itemid` | bigint | 映射前的原始商品 ID，仅适用于 ROI2 暗投/直播广告场景 |
| `mapped_ads_itemid` | bigint | ROI2 产品广告（暗投/直播）中，非胜出商品需映射到的目标 ROI2 商品 ID |
| `user_id` | bigint | 用户 ID（买家） |
| `order_id` | bigint | 订单 ID |
| `origin_item_id` | bigint | 订单行真实商品 ID |

---

### 维度：时间信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `timestamp` | bigint | 记录进入 Report-NG 处理器的时间戳（Unix 秒） |
| `click_timestamp` | bigint | 点击事件发生时间戳（Unix 秒） |
| `click_datetime` | string | 点击事件日期时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `event_timestamp` | bigint | 对应行的事件时间戳（下单/付款/确认订单），Unix 秒 |
| `event_datetime` | string | 事件日期时间（下单/付款/确认），格式 `YYYY-MM-DD HH:MM:SS` |
| `paid_timestamp` | bigint | 订单付款时间戳，Unix 秒 |
| `paid_datetime` | string | 订单付款日期时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `confirmed_timestamp` | bigint | 发货确认时间戳，Unix 秒；COD 订单为下单时间，非 COD 为付款时间 |
| `confirmed_datetime` | string | 发货确认日期时间，格式 `YYYY-MM-DD HH:MM:SS`；COD 订单为下单时间，非 COD 为付款时间 |
| `deduct_timestamp` | bigint | 实际扣费时间戳，Unix 秒 |
| `deduct_datetime` | string | 扣费日期时间，格式 `YYYY-MM-DD HH:MM:SS`，由 `from_unixtime(deduct_timestamp)` 派生 |
| `imp_timestamp` | bigint | 用于曝光归因订单的展示时间戳 |
| `original_order_timestamp` | bigint | CPS 广告首次扣费时间戳 |
| `response_timestamp` | bigint | 广告响应时间戳 |

---

### 维度：投放属性与页面场景

| 字段 | 类型 | 说明 |
|------|------|------|
| `placement` | bigint | 广告投放位置 ID |
| `pricing_type` | int | 广告计费类型（CPC/CPM/CPS 等） |
| `target_type` | string | 投放目标类型（如 `item` 等） |
| `match_type` | bigint | 关键词匹配类型；当 `placement in (0,3,4,1000,1200)` 时 COALESCE 为 0 |
| `entrance` | bigint | 广告入口位置（买家点击或曝光的来源位置） |
| `entrance_group` | string | 入口分组 |
| `sub_entrance` | bigint | 二级入口 |
| `platform` | bigint | 用户平台类型（iOS/Android/Web 等） |
| `app_version` | string | 用户客户端版本号，已标准化为 `X.XX.XX` 格式（纯 5 位数字转换）或保留原格式 |
| `location` | bigint | 用户地理位置 |
| `location_in_ads` | double | 广告展示中的商品排列位置 |
| `page_type` | string | 广告发生的页面类型（如 `image_search`、`search`、`shop` 等） |
| `page_section` | string | 页面区块（如 `search`、`rcmd`、`you_may_also_like` 等） |
| `search_scenario` | string | 搜索场景（`page_global_search` / `page_prefill_search`） |
| `search_entrance` | string | 搜索入口来源（如 `shop_search_bar`、`srp_search_bar` 等） |
| `search_mid` | string | 搜索中间页（如 `sdp_prefill`、`sub_history`） |
| `sort_by` | string | 排序方式（如 `price`、`sales`、`relevancy`、`ctime`、`pop`） |
| `click_area` | int | 用户点击区域位置（0=未知；1=访店文字；2=访店；3=商品；4=优惠券） |
| `keyword` | string | 关键词（部分 placement 下固定值或置空，详见 ETL 注意事项） |
| `query` | string | 用户搜索信息（搜索词、价格区间等） |
| `slot_id` | int | 展示广告的版位 ID |
| `landing_url_type` | int | 落地页类型 |
| `report_type` | int | 报告类型 |
| `deduction_reason` | int | 扣费原因（0=正常；1=预算耗尽不扣费；2=SBA 套餐关键词不扣费；3=领券不扣费） |
| `duplicate_label` | int | 重复标签类型，用于标记不同维度的去重逻辑（枚举值 1-8） |
| `shop_exp_tag` | int | 店铺实验标记（1=命中实验；0=未命中） |
| `traffic_source` | int | 流量来源（org/roi1/roi2 等） |
| `ctx_item_type` | int | 广告上下文商品类型（1=真实商品；2=虚拟商品） |
| `display_ads_tag` | int | 广告展示给用户时是否带有广告标签 |

---

### 维度：商品与素材

| 字段 | 类型 | 说明 |
|------|------|------|
| `creative_id` | bigint | 素材复合 ID，由 `ads_id`、`item_id`、`image_id` 派生 |
| `image_id` | string | 广告图片 ID |
| `video_id` | string | 视频 ID（原始编码） |
| `decoded_video_id` | bigint | 解码后的视频 ID，由 `decode_video_id(video_id)` 派生 |
| `display_video_id` | bigint | 已废弃（deprecated） |
| `vv_id` | string | 视频观看 ID |
| `creator_id` | bigint | 发布视频的用户 ID |
| `creative_algo` | int | 素材算法（0=无；1=随机探索；2=EGreedy 择优；3=ThompsonSample） |
| `item_price` | bigint | 商品价格，单位：本地货币 × 10⁵。⚠️ 原始存储为整型且放大 10⁵，使用时需除以 100000 转换为实际金额 |
| `item_price_shop` | double | 模型估算的店铺内商品平均价格（已 /100000 转换） |

---

### 维度：直播相关

| 字段 | 类型 | 说明 |
|------|------|------|
| `ls_session_id` | bigint | 直播会话 ID |
| `streamer_id` | bigint | 主播 ID |
| `shop_recall_type` | bigint | 店铺广告召回类型（枚举值含普通广告、闪购、优惠券、直播模板等多种） |

---

### 维度：受众定向

| 字段 | 类型 | 说明 |
|------|------|------|
| `ta_group_id` | bigint | 目标受众分组 ID，与 `campaign_id` + `shop_id` 唯一关联 |
| `tag_ids` | array\<int\> | 目标受众分组展平后的标签 ID 数组，来自 `target_audience_group_tab` JSON 解析 |
| `ta_matched_tag_ids` | array\<int\> | 广告实际命中的受众标签 ID 列表；未命中时为 null |
| `ta_premium_rate` | bigint | 命中目标受众分组时的溢价率 |
| `matched_premium_segment` | string | 命中的买家细分信息（JSON 格式，含 `segment_type_id` 与 `BuyerSegment_Info` 数组） |
| `matched_premium_segment_type_id` | bigint | 命中的买家细分 `segment_type_id` |
| `matched_premium_segment_value_id` | string | 命中的买家细分 `segment_value_id` |

---

### 维度：算法与实验

| 字段 | 类型 | 说明 |
|------|------|------|
| `ab_sign` | string | AB 实验签名，标识用户所属实验桶 |
| `plan_bucket_list` | array\<bigint\> | 广告计划所属实验组 ID 列表 |
| `traffic_bucket_list` | array\<bigint\> | 流量分桶列表 |
| `algo_json_data` | string | 传递给算法侧的 JSON 字段包 |
| `uni_pcr_model_name` | string | UNI PCR 模型名称 |
| `bid_rerank_trace` | string | 在线出价中间值记录（JSON，含模型估算分数），已由 `bid_info_decode_func` 解码。⚠️ 为 JSON 字符串，需使用 `get_json_object` 提取子字段 |
| `roi_upper_bound` | double | ROI 上界，从 `bid_rerank_trace` 中解析 `$.idx_roi_upper_bound` 得到。⚠️ 为派生计算字段，不可直接 SUM |
| `attr_data_type` | int | 位掩码（int32），第一位为 1 表示简单模式 Boosting 的 Boosted 商品 |
| `new_product_boost_coef` | double | 新品加速系数 |
| `new_product_boost_stage` | int | 新品加速阶段 |
| `avg_sold_cnt_item` | double | 模型估算的商品平均销量 |
| `avg_sold_cnt_shop` | double | 模型估算的店铺内商品平均销量 |
| `keywords_group_type` | int | 关键词分组类型 |
| `brand_max_ads_type` | int | 品牌广告最大类型 |
| `brand_max_target_type` | int | 品牌广告目标位置类型（枚举：0=未知；1=弹窗 Banner；2=细条 Banner；3=DD；4=浮动；5=搜索预填；6=首页轮播 Banner；7=首页轮播细条） |
| `is_ocpm` | boolean | 是否为 oCPM 计费模式 |
| `is_preselected_vmodel` | boolean | 是否为预选虚拟规格模型 |
| `ad_tag` | bigint | 广告属性位掩码，用整数位运算表示多个广告属性标志（含 `rapid_boost`、`campaign_surge` 等）。⚠️ 不可直接用于条件过滤，需按位运算提取具体标志位 |

---

### 维度：促销与优惠券

| 字段 | 类型 | 说明 |
|------|------|------|
| `bid_voucher_id` | bigint | 出价关联的优惠券 ID |
| `voucher_details` | array\<struct\<...\>\> | 已废弃，固定写入 NULL，请使用 `voucher_details_json` |
| `voucher_details_json` | string | 优惠券详情 JSON，含 `promotion_id`、`voucher_code`、`groups`、`reward_discount`；静态值不受退款影响。⚠️ 为 JSON 字符串，需 `get_json_object` 解析 |
| `ads_voucher_auto_claimed` | bigint | 广告优惠券是否被自动领取 |
| `rapid_boost_toggle` | boolean | 是否开启极速冲量，由 `(ad_tag & 140737488355328) > 0` 位运算派生 |
| `rapid_boost_state` | string | 极速冲量状态（`'cold start'` 冷起期 / `'mature'` 成熟期），由 `ad_tag` 位运算派生 |
| `campaign_surge_toggle` | boolean | 是否开启计划冲量，由 `(ad_tag & 2097152) > 0` 位运算派生 |
| `new_boost` | bigint | 新品推广标记 |

---

### 维度：其他标记

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_cod` | tinyint | 是否为货到付款订单（1=是；0=否） |
| `order_item_has_spu_vmodel` | boolean | 订单行是否包含至少一件从 SPU 店铺购买的商品，仅适用于订单相关指标 |
| `search_bid_type` | bigint | 已废弃（deprecated） |
| `search_capped_price` | double | 已废弃（deprecated） |
| `search_origin_bid_price_local` | double | 已废弃（deprecated） |
| `deduction_price` | double | 已废弃（deprecated）；原含义为优惠券抵扣价，现由 `voucher_deduction_price` 替代 |
| `voucher_deduction_price` | double | 已废弃（deprecated）；优惠券抵扣价（本地货币），原计算为 `deduction_price - deduction_price_0` |

---

### 指标：展示与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt` | bigint | 有效展示次数 |
| `raw_impression` | bigint | 原始展示次数，可能含重复。⚠️ 包含重复，不可与 `impression_cnt` 混用 |
| `non_fraud_impression` | bigint | 非欺诈展示次数 |
| `deduct_impression` | bigint | 已扣量的展示次数（CPM 计费时每条扣费记录对应的展示数） |
| `click_cnt` | bigint | 成功扣费后的有效点击数 |
| `click_before_deduction_cnt` | bigint | 扣费前的原始点击次数 |
| `raw_click_cnt` | bigint | 原始点击次数（含重复）。⚠️ 含重复，不可与 `click_cnt` 混用 |
| `non_fraud_click_cnt` | bigint | 非欺诈点击次数 |
| `deduplicated_click` | bigint | 去重后点击次数 |
| `cps_dedup_click` | bigint | CPS 专项去重点击数 |
| `product_click` | bigint | 视频广告专项去重商品点击数 |
| `raw_product_click` | bigint | 视频广告原始商品点击数（可能含重复）。⚠️ 含重复，不可与 `product_click` 混用 |
| `page_view` | bigint | 商品详情页浏览次数（PDP View） |
| `view` | bigint | 广告展示浏览数 |

---

### 指标：视频互动

| 字段 | 类型 | 说明 |
|------|------|------|
| `video_view` | bigint | 视频广告播放次数 |
| `view_duration` | bigint | 视频播放时长，单位：毫秒 |
| `video_play_3s_cnt` | int | 视频播放超过 3 秒的次数，由 `IF(view_duration/1000 >= 3, 1, 0)` 派生。⚠️ 为行级 0/1 标记，SUM 才得总数，不可直接用作比率 |
| `video_play_5s_cnt` | int | 视频播放超过 5 秒的次数，由 `IF(view_duration/1000 >= 5, 1, 0)` 派生。⚠️ 为行级 0/1 标记，SUM 才得总数 |
| `video_play_complete` | bigint | 视频完整播放次数 |
| `shop_view` | bigint | SRP 店铺浏览次数（operation=12） |
| `shop_video_play` | bigint | SRP 店铺视频播放次数（operation=27） |
| `shop_video_play_complete` | bigint | SRP 店铺视频完整播放次数（operation=28） |
| `shop_video_play_time` | bigint | SRP 店铺视频播放时长，operation=29。⚠️ 字段与 operation 枚举对应关系特殊，注意与其他视频时长字段区分 |
| `shop_video_click` | bigint | SRP 店铺视频点击次数（operation=1002，click_area=17） |

---

### 指标：费用与出价

| 字段 | 类型 | 说明 |
|------|------|------|
| `expenditure_amt_local` | double | 广告扣费金额（本地货币），由原始整型 `/100000.0` 转换得到 |
| `expenditure_amt_usd` | double | 广告扣费金额（USD），由 `expenditure_amt_local / exchange_rate` 派生。⚠️ 为派生汇率换算字段，跨地区汇总时不可直接 SUM，应以本地金额汇总后统一换算 |
| `raw_expense` | bigint | 预期扣费金额（比实际扣费更大，来自原始追踪计算），单位：本地货币 × 10⁵。⚠️ 原始整型放大 10⁵，使用需除以 100000 |
| `expected_revenue` | bigint | `dai_after_balance - dai_before_balance`，账户余额变化量，单位：本地货币 × 10⁵。⚠️ 原始整型放大 10⁵ |
| `receivable_revenue` | bigint | `expected_revenue - 已实现收入`，待收金额，单位：本地货币 × 10⁵。⚠️ 原始整型放大 10⁵ |
| `expense_by_cpm` | bigint | CPM 展示事件的预期收入（CPM/1000），单位：本地货币 × 10⁵。⚠️ 原始整型放大 10⁵ |
| `cpm` | bigint | 每千次展示成本（CPM），单位：本地货币 × 10⁵。⚠️ 原始整型放大 10⁵，不可直接用于 AVG，需用分子分母重新计算 |
| `origin_bid_price` | double | 原始出价 |
| `boost_deduction_price` | double | Boost 加速扣费价格 |
| `click_time_daily_budget` | bigint | 点击时刻对应的日预算 |
| `target_cir` | double | 目标成本收益比（CIR），用户自定义或算法填充。⚠️ 为比率字段，不可直接 SUM |
| `expense_free_credit_without_expiry` | bigint | 无期限免费广告额度扣费，单位：本地货币 × 10⁵ |
| `expense_free_credit_with_expiry` | bigint | 有期限免费广告额度扣费，单位：本地货币 × 10⁵ |
| `expense_paid_credit_without_expiry` | bigint | 无期限付费广告额度扣费，单位：本地货币 × 10⁵ |
| `expense_paid_credit_with_expiry` | bigint | 有期限付费广告额度扣费，单位：本地货币 × 10⁵ |
| `expense_rebate_free_credit_without_expiry` | bigint | 平台 Auto Rebate 产生的无期限免费广告额度扣费，单位：本地货币 × 10⁵ |

---

### 指标：直接订单（Direct Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt` | bigint | 直接广告订单数（用户点击广告商品后 7 天内下单） |
| `ads_item_sold_cnt` | bigint | 直接订单的商品销量 |
| `ads_order_gmv_local` | double | 直接订单 GMV（本地货币）；仅含商品折扣和捆绑促销，不含运费、平台返利、优惠券等 |
| `ads_order_gmv_usd` | double | 直接订单 GMV（USD），由汇率换算派生。⚠️ 跨地区不可直接 SUM |
| `daily_order_cnt` | bigint | 与点击事件同日下单的直接订单数 |
| `daily_order_amount` | bigint | 与点击事件同日下单的直接订单金额 |
| `daily_gmv_amt_local` | double | 与点击事件同日下单产生的直接订单 GMV（本地货币） |

---

### 指标：付款订单（Paid Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_order_cnt` | bigint | 30 天内已付款的广告订单数 |
| `paid_order_item_sold_cnt` | bigint | 用户点击广告后 7 天内产生的直接付款订单数 |
| `paid_order_gmv_local` | double | 已付款订单 GMV（本地货币） |
| `paid_order_gmv_usd` | double | 已付款订单 GMV（USD）。⚠️ 汇率换算派生，跨地区不可直接 SUM |
| `confirmed_order_cnt` | bigint | 下单后 30 天内已付款或确认的广告订单数 |
| `deduct_order` | bigint | CPS 首次扣费订单标记（1=是），由窗口函数 `ROW_NUMBER()` 取分组首条派生。⚠️ 为行级标记，SUM 才得订单数，不可直接用作计数字段 |
| `checkout_cnt` | bigint | 宽泛归因下 7 天内有广告点击的去重付款订单数 |
| `paid_checkout_cnt` | bigint | 宽泛归因下去重付款订单数（paid 口径） |

---

### 指标：宽泛订单（Broad Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order_cnt` | bigint | 宽泛广告订单数 |
| `broad_order_1d` | bigint | 与点击事件发生在同日的宽泛广告订单数 |
| `broad_item_cnt` | bigint | 宽泛广告订单中的商品销量 |
| `broad_gmv_amt_local` | double | 宽泛广告订单 GMV（本地货币） |
| `broad_gmv_amt_usd` | double | 宽泛广告订单 GMV（USD）。⚠️ 汇率换算派生，跨地区不可直接 SUM |
| `paid_broad_order_cnt` | bigint | 宽泛付款订单数（用户点击广告商品后 7 天内在同一店铺付款） |
| `paid_broad_order_item_sold_cnt` | bigint | 宽泛付款订单商品数 |
| `paid_broad_order_gmv` | double | 宽泛付款订单 GMV（本地货币） |
| `paid_broad_gmv_usd` | double | 宽泛付款订单 GMV（USD）。⚠️ 汇率换算派生，跨地区不可直接 SUM |
| `add_to_cart_cnt` | bigint | 直接归因的加购/立即购买次数（1 天点击窗口内，仅广告商品） |
| `add_to_cart_without_clicks_cnt` | bigint | 超 1 天但商品为广告商品的加购次数（非直接归因） |
| `broad_add_to_cart_cnt` | bigint | 宽泛口径加购总数（`add_to_cart + add_to_cart_without_clicks + broad_add_to_cart_other`）。⚠️ 为多字段合计，不可拆分后二次合计 |
| `broad_shop_item_click_cnt` | bigint | 店铺广告 7 天内宽泛点击数（含直接商品点击和店铺点击归因） |
| `broad_shop_item_impression_cnt` | bigint | 店铺广告 7 天内宽泛展示数 |
| `shop_item_click_cnt` | bigint | 买家跳转到其他入口前，店铺广告 1 天内的商品点击数 |
| `shop_item_impression_cnt` | bigint | 店铺广告点击后 1 天内的商品展示数 |

---

### 指标：曝光归因订单（Impression Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_attr_order_cnt` | bigint | 无广告点击但有广告曝光的归因订单数 |
| `imp_attr_order_amount` | bigint | 无广告点击但有广告曝光的归因订单商品数 |
| `imp_attr_order_gmv` | double | 无广告点击但有广告曝光的归因订单 GMV（本地货币） |
| `imp_attr_order_gmv_usd` | double | 无广告点击但有广告曝光的归因订单 GMV（USD）。⚠️ 汇率换算派生 |
| `imp_attr_paid_order_cnt` | bigint | 宽泛付款的曝光归因订单数（无点击有曝光，且命中 `shop_exp_tag`） |
| `imp_attr_paid_order_gmv` | double | 宽泛付款曝光归因订单 GMV（本地货币） |
| `imp_attr_paid_order_gmv_usd` | double | 宽泛付款曝光归因订单 GMV（USD）。⚠️ 汇率换算派生 |
| `imp_attr_paid_order_item_sold_cnt` | bigint | 宽泛付款曝光归因订单商品数 |

---

### 指标：无点击订单（No-Click Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `no_click_order` | bigint | 无广告点击和曝光但命中 `order_exp_tag` 的下单订单数 |
| `no_click_gmv` | bigint | 无点击无曝光但命中 `order_exp_tag` 的订单 GMV，单位：本地货币 × 10⁵。⚠️ 原始整型放大 10⁵，使用需除以 100000 |
| `no_click_gmv_usd` | double | 无点击无曝光订单 GMV（USD，下单口径） |
| `no_click_item_count` | bigint | 无点击无曝光但命中 `order_exp_tag` 的商品数 |
| `paid_no_click_order_cnt` | bigint | 无广告点击和曝光但命中 `order_exp_tag` 的付款订单数 |
| `paid_no_click_order_gmv` | double | 无点击无曝光付款订单 GMV（本地货币） |
| `paid_no_click_order_gmv_usd` | double | 无点击无曝光付款订单 GMV（USD）。⚠️ 汇率换算派生 |
| `paid_no_click_order_item_sold_cnt` | bigint | 无点击无曝光付款订单商品数 |

---

### 指标：Agent OA 链路订单（直播代理）

| 字段 | 类型 | 说明 |
|------|------|------|
| `agent_order_cnt` | bigint | 有 agent 点击的 place 口径订单数 |
| `agent_order_item_sold_cnt` | bigint | 有 agent 点击的 place 口径订单商品数 |
| `agent_order_gmv` | double | 有 agent 点击的 place 口径订单 GMV（本地货币） |
| `agent_order_gmv_usd` | double | 有 agent 点击的 place 口径订单 GMV（USD）。⚠️ 汇率换算派生 |
| `agent_checkout_cnt` | bigint | 有 agent 点击的 place 口径去重结算订单数 |
| `paid_agent_order_cnt` | bigint | 有 agent 点击的 paid 口径订单数 |
| `paid_agent_order_item_sold_cnt` | bigint | 有 agent 点击的 paid 口径订单商品数 |
| `paid_agent_order_gmv` | double | 有 agent 点击的 paid 口径订单 GMV（本地货币） |
| `paid_agent_order_gmv_usd` | double | 有 agent 点击的 paid 口径订单 GMV（USD）。⚠️ 汇率换算派生 |
| `paid_agent_checkout_cnt` | bigint | 有 agent 点击的 paid 口径去重结算订单数 |
| `imp_attr_agent_order_cnt` | bigint | 无 agent 点击但有 agent 曝光的订单数 |
| `imp_attr_agent_order_amount` | bigint | 无 agent 点击但有 agent 曝光的订单商品数 |
| `imp_attr_agent_order_gmv` | double | 无 agent 点击但有 agent 曝光的订单 GMV（本地货币） |
| `imp_attr_agent_order_gmv_usd` | double | 无 agent 点击但有 agent 曝光的订单 GMV（USD）。⚠️ 汇率换算派生 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询必须同时指定以下三个分区字段，否则将触发全表扫描，造成严重资源浪费：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `WHERE tz_type = 'local'` | 扫描所有时区分区（当前仅写入 local，但分区扫描仍有开销） |
| `grass_region` | `WHERE grass_region = 'MY'`（示例） | 扫描所有地区分区，数据量成倍放大 |
| `grass_date` | `WHERE grass_date BETWEEN '2025-01-01' AND '2025-01-07'` | 全量历史数据扫描，极易超时 |

### 不可直接 SUM 的字段

| 字段 | 问题类型 | 正确计算方式 |
|------|----------|-------------|
| `expenditure_amt_usd`、`ads_order_gmv_usd`、所有 `_usd` 后缀 GMV 字段 | 汇率派生，跨地区汇率不一致 | 先 SUM 本地货币金额，再统一除以基准汇率换算；或以单一地区查询 |
| `cpm` | 比率/放大存储，不可均值 | 计算 CPM 均值应用 `SUM(expenditure_amt_local) / SUM(impression_cnt) * 1000` |
| `target_cir` | 比率字段 | 使用消耗 / GMV 重新计算 CIR，不可对 `target_cir` SUM 或 AVG |
| `roi_upper_bound` | 算法派生比率 | 不可 SUM，需按业务需求取 MAX 或按曝光加权 |
| `item_price`、`raw_expense`、`expected_revenue`、`receivable_revenue`、`no_click_gmv`、`expense_by_cpm`、`cpm`（bigint 类） | 原始值放大 10⁵ 存储 | 查询时需 `/100000.0` 转换为实际金额 |
| `video_play_3s_cnt`、`video_play_5s_cnt` | 行级 0/1 标记 | 必须 SUM 才能得到总播放次数，不可直接用作计数 |
| `deduct_order` | 行级标记 | SUM 才得 CPS 首次扣费订单数 |
| `broad_add_to_cart_cnt` | 多子项合计字段 | 已含 `add_to_cart_cnt + add_to_cart_without_clicks_cnt + broad_add_to_cart_other`，勿与子项重复叠加 |
| `ad_tag` | 位掩码字段 | 需按位运算（`&`）提取具体标志位，不可直接 SUM 或比较大小 |
| `bid_rerank_trace`、`voucher_details_json`、`matched_premium_segment` | JSON 字符串 | 需使用 `get_json_object` 或 `json_parse` 提取子字段后使用 |

### 时效性说明

- 本表为每日全量覆盖写入（INSERT OVERWRITE），取最新分区 `grass_date = <目标日期>` 即为当日最终数据，无历史版本覆盖问题。
- 订单归因字段存在不同时间窗口（1 天、7 天、30 天），字段注释中已标明，查询时注意区分 `daily_*`（同日）、`order_*`（7 天直接归因）、`paid_*`（30 天付款归因）等口径，避免口径混用导致重复计算。
- CPM 扣费记录中若 `translog_event` 存在丢失，由 `cpm_deduction_issue_fix` 补丁数据覆盖，但补丁行不含事件级维度字段（页面类型、商品信息、算法字段等均为 NULL），按维度下钻分析时需注意此类空值行可能稀释指标。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_ads_report_hi__reg_s0_live` | 普通广告（非直播）的曝光、点击、订单事件原始日志 |
| `mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live` | 直播广告的曝光、点击、订单事件原始日志 |
| `mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live` | 广告扣费流水主表，提供 CPM/CPC/CPS 扣款记录及余额变化 |
| `mp_paidads.ods_log_translog_event_hi__reg_s0_live` | 扣费事件日志，提供点击/展示事件维度信息（页面、商品、算法等） |
| `mp_paidads.shopee_ads_${region}_shard_db__advertisement_tab__reg_continuous_s0_live` | 广告维度表，提供广告 ID 与店铺 ID 映射（用于修复缺失的 `shop_id`） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 各地区每日汇率维表，用于本地货币换算为 USD |
| `mp_paidads.shopee_ads_${region}_shard_db__target_audience_group_tab__reg_continuous_s0_live` | 目标受众分组配置表，提供展平后的 `tag_ids` |

---

## ETL 逻辑摘要

### 数据流

```
ods_log_ads_report_hi                    ─┐
  (非直播广告日志)                          │  report_ng_view (过滤非直播 placement)
                                           │
ods_log_ads_report_livestream_hi         ─┤  livestream_report_ng (过滤直播 placement)
  (直播广告日志)                            │
                                           │
ods_shopee_ads_db__translog_tab_di       ─┤
  + ods_log_translog_event_hi             │  cpm_deduction (CPM 扣费明细，事件对齐)
  (CPM 扣费 + 事件日志)                    │  cpm_deduction_issue_fix (事件丢失补丁)
                                           │
ods_shopee_ads_db__translog_tab_di       ─┤
  + ods_log_translog_event_hi             │  cpc_cps_deduction (CPC/CPS 扣费明细)
  (CPC/CPS 扣费 + 事件日志)               │
                                           ↓
                              ┌─────────────────────────┐
                              │     base (UNION ALL)     │
                              │  ①report_ng_view         │
                              │  ②livestream_report_ng   │
                              │  ③cpm_deduction          │
                              │  ④cpm_deduction_fix      │
                              │  ⑤cpc_cps_deduction      │
                              └────────────┬────────────┘
                                           │ LEFT JOIN
                              advertisement_tab ──→ dim (ads_id→shop_id + 汇率)
                                           │ LEFT JOIN
                              target_audience_group_tab → target_audience_info (tag_ids)
                                           │
                                           ↓
                    dwd_advertise_performance_di__reg_s0_live
                    (INSERT OVERWRITE, 分区: tz_type/grass_region/grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `report_ng_view` | `ods_log_ads_report_hi` | 过滤非直播 placement，保留 `cost IS NULL` 的展示记录，全字段透传 |
| `livestream_report_ng` | `ods_log_ads_report_livestream_hi` | 过滤直播 placement，保留 `deduct_impression IS NULL` 的记录，全字段透传 |
| `cpm_deduction` | `translog_tab_di` + `translog_event_hi` | 通过 `POSEXPLODE` 对齐 CPM 事件明细与扣款明细，按比例分摊各类额度费用，输出事件级维度 |
| `cpm_deduction_issue_fix` | `translog_tab_di` + `cpm_deduction`聚合 | 修复 `translog_event` 记录缺失或成本不完整的 CPM 扣费行，用余额差值补全展示数和费用，但不携带维度字段 |
| `cpc_cps_deduction` | `translog_tab_di` + `translog_event_hi` | CPC（operation=1）和 CPS（operation=15）扣费明细；对 CPS 用窗口函数标记首次扣费（`deduct_order=1`）；解析受众细分 `buyer_segments` |
| `base` | 上述 5 个 CTE（UNION ALL） | 统一 schema，金额 /100000 转换为实际金额，时间戳转日期时间字符串，展开 `buyer_segments`，修正 `match_type` |
| `dim` | `advertisement_tab` + `dim_exchange_rate` | 获取 ads_id→shop_id 映射及当日汇率，用于修复 `shop_id` 和计算 USD 指标 |
| `target_audience_info` | `target_audience_group_tab` | JSON 解析受众分组配置，展平 `tag_ids` 数组 |

### 注意事项

1. **事件类型混存**：本表同时存储展示、点击、扣费、订单归因等多类事件行，不同事件行的字段填充率差异显著。分析时必须明确事件类型范围（如仅分析扣费行则过滤 `deduct_timestamp IS NOT NULL`），避免指标因跨事件类型汇聚而失真。

2. **CPM 扣费双轨道**：`cpm_deduction` 依赖 `translog_event` 提供细粒度维度；当事件日志丢失时由 `cpm_deduction_issue_fix` 补丁覆盖。补丁行中页面类型、商品信息、算法字段等均为 NULL，按维度下钻时会出现 NULL 分组，需在业务层决定是否剔除或单独处理。

3. **金额字段单位不统一**：部分 bigint 金额字段（`item_price`、`raw_expense`、`expected_revenue`、`receivable_revenue`、`cpm`、`no_click_gmv`、`expense_*` 系列）单位为本地货币 × 10⁵，而 double 类型的 `expenditure_amt_local`、`ads_order_gmv_local` 等已转换为实际金额。混用前需确认字段单位。

4. **keyword 字段特殊处理**：`placement IN (4)` 时 keyword 为固定混淆字符串，`placement IN (20, 2003, 2030)` 时为空字符串，其他 placement 取原始值。按关键词维度分析时需过滤无意义的 placement 类型。

5. **shop_id Bug 修复**：最终写入时 `shop_id = COALESCE(a.shop_id, c.shop_id)`，即优先取事件流中的 `shop_id`，缺失时回退到广告维度表。若下游关联出现 `shop_id` 为空的情况，可能源于广告维度表也缺失该广告记录。

6. **USD 字段跨地区汇总**：各 `_usd` 字段按各自地区当日汇率换算，不同地区汇率不同。跨地区汇总 USD 金额时，应对本地货币字段求和后再换算，而非对 `_usd` 字段直接 SUM。

7. **`voucher_details` 已废弃**：该字段固定写入 NULL，实际优惠券信息请使用 `voucher_details_json`，并通过 `get_json_object` 解析所需字段。

8. **地区参数化调度**：ETL SQL 中出现的具体地区代码与时区值均为调度模板的参数化实例，本表通过参数化调度覆盖所有上线市场，各地区按本地时区独立执行。

---

*文档生成时间：2026-05-20*