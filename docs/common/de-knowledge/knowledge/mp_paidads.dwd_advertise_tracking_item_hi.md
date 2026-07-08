<!-- ads-workspace-gdoc-sync: gdoc_id=1QwDoKLiXHV4NEYJmwaPQdPkDig3ZXFO-R8n7jWlQBZ8 gdoc_url=https://docs.google.com/document/d/1QwDoKLiXHV4NEYJmwaPQdPkDig3ZXFO-R8n7jWlQBZ8/edit -->

# mp_paidads.dwd_advertise_tracking_item_hi

**分层**：DWD（数据明细层）
**主键**：`unique_id`（单条追踪事件唯一标识）
**分区**：`grass_region` / `grass_date` / `h` / `bz_type`
**更新频率**：逐小时覆盖写入（`insert overwrite partition`）
**引用频次**：54 次（候选表范围内）

---

## 业务描述

本表是 Shopee 付费广告平台（PaidAds）**商品级广告追踪明细表**，记录广告系统对每一次商品广告事件（曝光、点击、加购、下单等）的完整上报日志。数据来源于上游 ODS 层原始 Kafka 日志，经过字段规范化、价格单位转换（原始分 / 100000 → 本地货币单位）、枚举值解码（platform/operation 中文映射）以及欺诈标签提取等 ETL 处理后写入本表。

本表是付费广告数据仓库中**使用最广泛的 DWD 基础表**（下游引用 54 次），是构建广告绩效报表（曝光量、点击率、CTR、ROI）、出价分析、商品投放监控、A/B 测试评估、定向人群分析等所有下游 DWM/ADS 层的核心数据源。每行代表一个广告系统中商品维度的追踪事件，包含完整的用户上下文、设备信息、广告归因链路（ads_id → campaign_id）、出价与扣费信息以及商品卡片属性。

本表通过 `bz_type` 字段将流量划分为 **Search（搜索）** 和 **Discovery（发现）** 两大业务场景，支持按场景拆分分析；同时保留 `internal`、`item_json_data` 等结构化/半结构化字段，供算法团队进行深度特征回溯与调试。各地区按本地时区参数化调度，统一覆盖全球各运营市场。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区编码，如 `ID`、`MY`、`TH`、`MX` 等，各地区独立调度写入 |
| `grass_date` | date | 事件日期（按各地区本地时区对齐） |
| `h` | int | 事件小时（0–23，按各地区本地时区对齐） |
| `bz_type` | string | 业务类型，`placement` 属于 `(0, 29)` 时为 `'Search'`，否则为 `'Discovery'`；⚠️ 由 `placement` 派生，不可直接修改或单独聚合，过滤时需与 `tracking_placement` 联合理解 |

---

### 维度：主键与用户身份

| 字段 | 类型 | 说明 |
|------|------|------|
| `unique_id` | string | 事件唯一标识，全局唯一，可用于去重 |
| `sequence_id` | string | 序列号，用于事件顺序标识 |
| `user_id` | bigint | 用户 ID（来源字段 `userid`） |
| `session_id` | string | 用户会话 ID |
| `view_session_id` | string | 浏览会话 ID |
| `search_session_id` | string | 搜索会话 ID |
| `global_session_id` | string | 全局会话 ID |
| `device_id` | string | 设备 ID |
| `client_ip` | string | 客户端 IP |
| `dfp` | string | 设备指纹（Device Fingerprint），用于设备识别与反欺诈 |
| `token` | string | 请求鉴权 Token |
| `vv_id` | string | 视频浏览 ID |

---

### 维度：广告与投放属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID |
| `campaign_id` | bigint | 广告计划 ID |
| `ads_keyword` | string | 广告关键词（搜索广告场景） |
| `match_type` | bigint | 关键词匹配类型（精确/广泛/短语等） |
| `target_type` | string | 定向类型 |
| `ta_group_id` | bigint | 定向人群组 ID，从 `item.json_data` 中解析 |
| `ta_matched_tag_ids` | array\<int\> | 命中的定向标签 ID 列表，从 `item.json_data` 中解析 |
| `ta_premium_rate` | bigint | 定向溢价比率；⚠️ 为比率字段，不可直接 SUM，聚合时需结合分子/分母计算加权平均 |
| `matched_premium_segments` | string | 命中的高价值买家分群信息（JSON 字符串），从 `item.json_data.buyer_segments` 解析 |
| `ads_placement` | bigint | 广告实际投放位置，来自 `internal.deduction_info.placement` |
| `tracking_placement` | bigint | 追踪日志中的 placement 字段（原始值） |
| `inner_placement` | bigint | 内部 placement，从 `item.json_data.placement` 解析 |
| `location_in_ads` | bigint | 广告位中的位置序号 |
| `organic_location` | bigint | 自然搜索位置 |
| `ads_entrance` | string | 广告入口标识，优先取 `item.json_data.entrance`，回退取 `json_data.entrance` |
| `pricing_type` | string | 广告计费类型（如 CPC/OCPM），从 `item.json_data.pricing_type` 解析 |
| `is_ocpm` | boolean | 是否为 OCPM（目标转化出价）广告，来自 `internal.deduction_info.is_ocpm` |
| `algorithm` | string | 广告排序算法标识 |
| `model_id` | bigint | 广告模型 ID |
| `display_ad_tag` | int | 展示广告标签 |
| `new_product_boost_stage` | int | 新品加速阶段，从 `item.json_data.new_product_boost_stage` 解析 |
| `tracking_queue_name` | string | 追踪队列名称；⚠️ 仅在特定 placement 下有值：`placement in (0,4,1000,1200)` 取 `recall_source`，`placement in (1,2,5,801...)` 取 `queue_name`，其余为 NULL |
| `attribute_reason` | int | 归因原因标识，从 `item.json_data.attribute_reason` 解析 |
| `uni_pcr_model_name` | string | 统一 PCR 模型名称，从 `item.json_data.uni_pcr_model_name` 解析 |
| `algo_json_data` | string | 算法 JSON 数据，来自 `item.internal.algo_json_data` |

---

### 维度：商品与店铺属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID |
| `shop_id` | bigint | 店铺 ID |
| `item_model_id` | bigint | 商品 SKU 模型 ID |
| `model_id` | bigint | 商品模型 ID（来自 `item.modelid`） |
| `v_item_id` | bigint | 虚拟商品 ID（来自 `item.vitemid`） |
| `v_model_id` | bigint | 虚拟商品模型 ID（来自 `item.vmodelid`） |
| `ctx_item_type` | int | 商品上下文类型 |
| `list_type` | string | 列表类型（如搜索列表、推荐列表等） |
| `discount` | bigint | 折扣信息（原始值，单位：分） |
| `is_free_shipping` | int | 是否免运费，`1` = 是，`0` = 否 |
| `is_prefered` | int | 是否为优选商品，`1` = 是，`0` = 否 |
| `rsku_list_infos_json` | string | RSKU 列表信息 JSON 字符串，由 `item.rsku_list_infos` 序列化而来；⚠️ 结构化数据以 JSON 字符串存储，需使用 `from_json` / `get_json_object` 解析 |

---

### 维度：商品卡片属性（product_card）

| 字段 | 类型 | 说明 |
|------|------|------|
| `product_card` | struct\<...\> | 商品卡片完整属性结构体，包含以下子字段：`campaign_label_ids`（营销标签 ID 列表）、`has_video`（是否有视频）、`item_discount`（商品折扣）、`shop_type`（店铺类型）、`is_service_by_shopee`（是否 SBS）、`image_flag_ids`（图片标识）、`price_before_discount` / `price` / `price_max` / `price_min`（各档价格，单位已转换为本地货币）、`bundle_deal_label`（捆绑销售标签）、`is_wholesale`（是否批发）、`addon_deal_label`（加购标签）、`is_cashback`（是否返现）、`is_groupbuy`（是否团购）、`other_promotion_label_id`（其他促销标签）、`rating_star` / `rating_star_rounded`（评分）、`sold_count`（销量）、`is_free_shipping`（免运费）、`other_icon_in_price_id`（价格区域其他图标）、`is_sold_out`（是否售罄）；⚠️ 价格子字段已除以 100000 完成单位转换，直接使用即为本地货币单位 |

---

### 维度：优惠券属性（item_voucher）

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_voucher` | struct\<...\> | 商品优惠券结构体，包含 `display_ads_voucher_label`（展示标签）、`best_vouchers`（最优券列表，含 promotion_id / voucher_code / voucher_discount / minimum_spend / 有效时间 / groups / is_auto_claimed_just_now 等）、`initial_price`（初始价格）、`final_price`（最终价格） |
| `is_auto_claimed_just_now` | tinyint | 是否刚被自动领取的 ADS-ROI 券，`1` = 是，`0` = 否；由 `item_voucher.best_vouchers` 中 `groups` 含 `'ADS-ROI'` 且 `is_auto_claimed_just_now=true` 派生 |
| `is_roi3_best_voucher` | tinyint | 是否存在 ADS-ROI 最优券，`1` = 是，`0` = 否；由 `item_voucher.best_vouchers` 中 `groups` 含 `'ADS-ROI'` 派生 |
| `bid_voucher_id` | bigint | 出价关联的优惠券 ID，通过 `bid_info_decode_fuc` 解析 `bid_rerank_trace` 获得 |
| `voucher_deduction_price` | bigint | 优惠券抵扣金额（单位：分），优先取 `item.json_data`，回退取 `json_data` |

---

### 维度：用户行为与事件

| 字段 | 类型 | 说明 |
|------|------|------|
| `operation` | bigint | 事件类型编码：1=曝光、2=点击、3=浏览、4=加购、5=下单、6=关闭 Banner、7=举报不喜欢、8=举报不当、9=举报不相关、10=举报曝光、1001=店铺曝光、1002=店铺点击 |
| `operation_desc` | string | 事件类型文字描述（由 `operation` 派生），如 `'IMPRESSION'`、`'CLICK'` 等；⚠️ 为派生字段，不可作为聚合 key 的唯一依据，应以 `operation` 为准 |
| `timestamp` | bigint | 事件时间戳（毫秒级 Unix 时间戳） |
| `event_timestamp` | bigint | 事件时间戳（可能与 `timestamp` 来源不同，为系统处理层时间戳） |
| `click_event_id` | string | 点击事件唯一 ID，来自 `item.internal.event_id` |
| `click_area` | int | 点击区域标识 |
| `add_cart_item_amount` | bigint | 加购商品数量 |
| `add_cart_item_price` | decimal(25,10) | 加购时商品价格（已除以 100000，单位为本地货币）；⚠️ 价格已完成单位转换 |

---

### 维度：请求链路与索引

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_request_id` | string | 广告请求 ID，优先取 `item.json_data.request_id`，回退取 `json_data.request_id` |
| `raw_request_id` | string | 原始请求 ID，来自 `item.request_id` |
| `organic_request_id` | string | 自然搜索请求 ID；⚠️ 提取逻辑因 placement 而异：`placement in (2,5,13,14,15,16)` 时从 `abtest_sign` 解析，否则从 `item.json_data` 的 `search_data.request_id` 或 `request_id` 获取 |
| `search_mid` | string | 搜索会话中间 ID |
| `sequence_id` | string | 事件序列 ID |

---

### 维度：平台与客户端

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform` | bigint | 平台编码：1=IOS_WEB、2=IOS_APP、3=ANDROID_WEB、4=ANDROID_APP、5=PC_MALL、6=IOS_LITE、7=ANDROID_LITE、8=PLATFORM_RESERVED、9=ANDROID_APP_LITE、99=XIAPI、128=OTHERS |
| `platform_desc` | string | 平台文字描述（由 `platform` 派生）；⚠️ 为派生字段，聚合应以 `platform` 为主 |
| `app_ver` | string | App 版本号 |
| `rn_ver` | string | React Native 版本号 |
| `sdk_version` | string | SDK 版本号 |
| `sdk_type` | string | SDK 类型 |
| `page_type` | string | 页面类型 |
| `page_section` | string | 页面分区 |

---

### 维度：搜索上下文（search_props）

| 字段 | 类型 | 说明 |
|------|------|------|
| `sort_by` | string | 搜索排序方式 |
| `scenario` | string | 搜索场景标识 |
| `search_entrance` | string | 搜索入口 |
| `search_page_sort_type` | bigint | 搜索结果页排序类型（来自 `item.query.sorttype`） |
| `query` | struct\<...\> | 搜索请求结构体，含 `keyword`（关键词）、`sorttype`（排序类型）、`colorful_blocks`（色彩块）、`filter_price_min/max`（价格筛选）、`filter_include_sf`（是否含官方物流）、`filter_with_discount`（是否有折扣）、`filter_attribute`（属性筛选）、`filter_item_condition`（商品成色）、`filter_user_verified`（认证筛选）、`filters`（多维筛选列表）、`item_id`、`shop_id` |
| `sub_entrance` | bigint | 子入口标识 |

---

### 维度：视频上下文（video_props）

| 字段 | 类型 | 说明 |
|------|------|------|
| `current_page` | string | 当前页面标识 |
| `content_type` | string | 内容类型（视频场景） |
| `content_id` | string | 内容 ID（视频场景） |
| `trigger_mode` | string | 触发模式 |
| `sv_source_page` | string | 短视频来源页面 |
| `display_video_id` | bigint | 展示视频 ID（来自 `item.item_video.display_video_id`） |

---

### 维度：推荐卡片属性（item_rcmd_props）

| 字段 | 类型 | 说明 |
|------|------|------|
| `card_type` | string | 推荐卡片类型，来自 `item.item_rcmd_props.card_type` |
| `video_id` | string | 推荐卡片关联的视频 ID，来自 `item.item_rcmd_props.video_id` |
| `be_ab` | array\<bigint\> | BE 侧 A/B 实验分组 ID 列表，来自 `item.item_rcmd_props.be_ab` |

---

### 维度：A/B 实验与欺诈标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `abtest_sign` | string | A/B 实验签名（来自 `item.abtest_sign`） |
| `fe_ab_sign` | string | 前端 A/B 实验签名 |
| `ab_sign` | string | A/B 实验签名，优先取 `item.json_data.ab_sign`，回退取 `json_data.ab_sign` |
| `internal_label` | struct\<...\> | 内部标签结构体，含 `frauds`（欺诈列表）、`sessionid`、`adsinfo_extract_label`、`dfp_device_id`、`risk_tags`（风险标签列表） |
| `fraud_type` | string | 欺诈类型字符串，由 `proc_arr(to_json(internal_label))` UDF 提取；⚠️ 通过自定义 UDF 处理，格式依赖 UDF 实现，直接字符串比较时需注意格式 |
| `duplicate_label` | int | 重复事件标签，来自 `item.internal.duplicate_label`；⚠️ 过滤无效/重复事件时通常需要结合此字段 |

---

### 维度：原始 JSON 数据（调试用）

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_json_data` | string | 商品维度原始 JSON 数据（`item.json_data`）；⚠️ 包含多个字段的原始来源，体积较大，避免在大规模聚合查询中 SELECT，仅用于调试或字段回溯 |
| `tracking_json_data` | string | 追踪日志原始 JSON 数据（行级 `json_data`）；⚠️ 同上，仅用于调试 |
| `refer_urls` | array\<string\> | 来源 URL 列表 |

---

### 指标：出价与扣费

| 字段 | 类型 | 说明 |
|------|------|------|
| `bid_deduction_price` | bigint | 出价扣费金额（单位：分），来自 `item.internal.deduction_info.bid_deduction_price`；⚠️ 单位为分，与 `internal.deduction_info.deduction_price`（已转换）不同，不可混用 |
| `bid_rerank_trace` | string | 出价重排序追踪信息，经 `bid_info_decode_fuc` UDF 解码后存储为 JSON 字符串；⚠️ 通过自定义 UDF 解码，内容为 JSON，需用 `get_json_object` 进一步解析 |
| `internal` | struct\<...\> | 内部出价信息结构体，`deduction_info` 子结构包含：`quality`（质量分）、`bidprice`（出价，已除以 100000）、`next_score`（竞争者得分）、`next_ads_id`（竞争者广告 ID）、`next_ads_keyword`（竞争者关键词）、`algo_name`（算法名）、`boost_status`（加速状态）、`deduction_price`（实际扣费价，已除以 100000）、`ads_id`、`placement`；⚠️ `bidprice` 和 `deduction_price` 已完成单位转换（÷100000），直接使用即为本地货币单位 |

---

### 指标：商品价格

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_price` | decimal(25,10) | 商品价格（已除以 100000，单位为本地货币）；优先取 `item.json_data.item_price`，回退从 `extra_json.bid-infos` 解析；⚠️ 价格已完成单位转换，不可再除以 100000 |
| `item_price_shop` | double | 店铺维度商品价格（已除以 100000），从 `item.json_data.item_price_shop` 解析 |

---

### 指标：销量预测与 ROI 参数

| 字段 | 类型 | 说明 |
|------|------|------|
| `target_cir` | double | 目标 CIR（Cost-Income Ratio，广告费用收益比），从 `item.json_data.target_cir` 解析，回退从 `extra_json.bid-infos` 解析；⚠️ 为比率字段，不可直接 SUM，聚合时需加权平均 |
| `sold_cnt_per_order` | bigint | 每单销售件数（已标注 deprecated，仍以 double 逻辑存储）；⚠️ ETL 注释标注为 deprecated，实际以 `avg_sold_cnt` 兜底填充，请勿在新需求中依赖此字段 |
| `sold_cnt_per_order_double` | double | 每单销售件数（double 类型，与 `sold_cnt_per_order` 逻辑相同，deprecated）；⚠️ 同上，ETL 注释标注为 deprecated |
| `avg_sold_cnt_item` | double | 商品维度平均每单销售件数，从 `item.json_data.avg_sold_cnt_item` 解析 |
| `avg_sold_cnt_shop` | double | 店铺维度平均每单销售件数，从 `item.json_data.avg_sold_cnt_shop` 解析 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须指定全部分区字段**，否则将触发全表扫描，导致资源浪费甚至查询超时：

| 过滤字段 | 说明 | 遗漏后果 |
|----------|------|----------|
| `grass_region` | 必须指定，如 `grass_region = 'ID'` | 扫描所有地区分区，数据量成倍放大 |
| `grass_date` | 必须指定，如 `grass_date = '2024-01-01'` 或日期范围 | 全量历史扫描，极易 OOM 或超时 |
| `h` | 分析日粒度时可使用 `h between 0 and 23` 或不限制（但建议在 ADS/DWM 层已聚合的表中使用，DWD 层若不限制小时会扫描 24 个分区） | 重复扫描全天 24 小时分区 |
| `bz_type` | 按业务场景分析时指定，如 `bz_type = 'Search'` 或 `bz_type = 'Discovery'` | 混合两类流量，指标口径失准 |

**强烈建议**同时过滤 `duplicate_label = 0`（过滤重复事件）和 `item_id > 0`（ETL 已过滤，但下游二次校验推荐保留）。

---

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确计算方式 |
|------|------|-------------|
| `ta_premium_rate` | 比率字段 | 按曝光量加权平均：`SUM(ta_premium_rate * 曝光数) / SUM(曝光数)` |
| `target_cir` | 比率字段（Cost-Income Ratio） | 按实际费用与收入加权：`SUM(cost) / SUM(income)` 重新计算 |
| `bz_type` | 由 `tracking_placement` 派生，不代表独立度量 | 作为分组维度使用，不做数值聚合 |
| `operation_desc` | 由 `operation` 派生的文字描述 | 聚合或过滤请使用 `operation` 数值字段 |
| `platform_desc` | 由 `platform` 派生的文字描述 | 聚合或过滤请使用 `platform` 数值字段 |
| `sold_cnt_per_order` / `sold_cnt_per_order_double` | 标注为 deprecated，且实际值为 `avg_sold_cnt` 回退填充，非真实每单件数 | 使用 `avg_sold_cnt_item` 或 `avg_sold_cnt_shop` 替代 |
| `item_price`、`add_cart_item_price`、`item_price_shop` | 已完成 ÷100000 单位转换，聚合前须确认口径一致 | 直接 SUM 金额字段时需注意与 `bid_deduction_price`（单位仍为分）的混用 |
| `bid_deduction_price` | 单位为分（未做 ÷100000 转换），与 `internal.deduction_info.deduction_price`（已转换）单位不同 | 需先除以 100000 再与价格类字段对比 |
| `internal.deduction_info.bidprice` / `deduction_price` | 已除以 100000，但为嵌套 struct 字段 | 使用 `internal.deduction_info.deduction_price` 访问，不可与 `bid_deduction_price` 直接相加 |

---

### 时效性说明

本表为**小时级覆盖写入**（`insert overwrite partition(grass_date, h)`），每小时数据在当前小时结束后约延迟 N 分钟写入。

- 分析**当天实时数据**：取 `grass_date = current_date` 且 `h <= current_hour - 1`（最新完整小时）；
- 分析**历史完整天数据**：取 `grass_date = target_date` 且 `h between 0 and 23`；
- **不建议**直接查询当前正在写入的小时分区（`h = current_hour`），数据未完整，聚合结果偏低。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_ads_tracking_hi__reg_s0_live` | 广告追踪原始 Kafka 日志（ODS 层），本表的唯一上游数据源，通过 `LATERAL VIEW EXPLODE(items)` 将行级日志展开为商品级明细 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ods_log_ads_tracking_hi__reg_s0_live
  （行级追踪日志，items 为数组）
          │
          │ LATERAL VIEW EXPLODE(items) AS item
          │ WHERE grass_date = '${TODAY_DATE}'
          │   AND h = ${TODAY_HOUR}
          │   AND item.itemid > 0
          │
          ▼
   字段规范化 & 类型转换
   ├── 价格字段 ÷ 100000（分 → 本地货币）
   ├── Boolean → int（is_free_shipping / is_prefered 等）
   ├── operation / platform 枚举解码（→ _desc 字段）
   ├── bz_type 派生（placement in (0,29) → 'Search'，否则 'Discovery'）
   ├── UDF 处理：
   │   ├── proc_arr(to_json(internal_label)) → fraud_type
   │   └── bid_info_decode_fuc(bid_rerank_trace) → bid_rerank_trace / bid_voucher_id
   ├── JSON 解析：get_json_object / from_json 提取多个字段
   │   （ads_request_id / organic_request_id / ta_group_id 等）
   ├── COALESCE 兜底逻辑（优先取 item.json_data，回退取行级 json_data）
   └── struct 重建（query / product_card / internal 规范化）
          │
          ▼
   INSERT OVERWRITE PARTITION(grass_region, grass_date, h, bz_type)
          │
          ▼
mp_paidads.dwd_advertise_tracking_item_hi__reg_s0_live
```

### 注意事项

1. **行列转换**：上游 ODS 表一行代表一次广告请求（含多个商品），本表通过 `LATERAL VIEW EXPLODE(items)` 展开为商品粒度，**下游聚合时需注意行数已膨胀**，不可将行级指标（如 request 级别的 UV）直接在本表上 COUNT。
2. **价格单位**：原始日志价格以 **1/100000 本地货币**（即"厘"）存储。ETL 中 `product_card`、`internal.deduction_info`、`item_price`、`add_cart_item_price` 等字段已完成 ÷100000 转换；但 `bid_deduction_price`、`voucher_deduction_price`、`discount` 等字段**仍为原始分单位**，使用时需注意区分。
3. **deprecated 字段**：`sold_cnt_per_order` 和 `sold_cnt_per_order_double` 在 ETL SQL 中已标注 `--deprecated`，其实际赋值逻辑已由 `avg_sold_cnt` 兜底。新开发的分析任务应使用 `avg_sold_cnt_item` / `avg_sold_cnt_shop` 替代。
4. **organic_request_id 口径差异**：根据 `placement` 值不同，提取逻辑不一致（从 `abtest_sign` 解析 vs 从 `json_data` 解析），跨 placement 对比时需注意口径对齐。
5. **UDF 依赖**：ETL 依赖 `bid_info_decode_fuc` 和 `proc_arr` 两个自定义 UDF（JAR 包来自 `hdfs://D2/projects/data_paidadsmart/...`），下游若需在临时查询中复现这两个字段逻辑，需手动加载相同 JAR 并注册 UDF。
6. **地区参数化调度**：`${TODAY_DATE}`、`${TODAY_HOUR}`、`${region}` 均为调度模板参数，各地区独立调度，写入对应 `grass_region` 分区。
7. **item_id 过滤**：ETL 已过滤 `item.itemid > 0`（排除无效商品），但 `shop_id` 未强制过滤，下游若需过滤无店铺数据应自行添加 `shop_id > 0`。

---

*文档生成时间：2026-04-22*