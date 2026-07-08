<!-- ads-workspace-gdoc-sync: gdoc_id=1kfhoZ8mo2WqacPatTwtF9pfTmNjmeWr8mO81ZSGk1Z8 gdoc_url=https://docs.google.com/document/d/1kfhoZ8mo2WqacPatTwtF9pfTmNjmeWr8mO81ZSGk1Z8/edit -->

# mp_paidads.ads_advertise_mkt_1d

**分层**：ADS（应用数据服务层）  
**主键**：`ads_id` + `placement` + `entrance` + `new_boost` + `tz_type` + `grass_region` + `grass_date`  
**分区**：`tz_type` / `grass_region` / `grass_date`  
**更新频率**：每日（T+1 调度，覆盖前一自然日数据）
**引用频次**：10 次（候选表范围内）

---

## 业务描述

本表是 Shopee 付费广告域的核心 ADS 层宽表，以**广告（ads_id）× 广告位（placement）× 入口（entrance）× 是否新商品推广（new_boost）× 时区类型（tz_type）× 日期（grass_date）**为粒度，聚合每日广告绩效、归因订单、收入及广告主画像等全量指标，供报表、看板、分析模型和运营策略直接消费。

本表的核心价值在于将分散在多个 DWS 层表中的广告曝光、点击、订单归因（直接归因 / 广义归因 / 印象归因）、支出与收入数据，与广告维度（广告主、商品、类目、定价模式、投放状态）深度 JOIN，形成一张"一站式"的广告营销分析宽表。下游常见使用场景包括：日常广告主健康度监控、广告产品 ROI 分析、冷启动状态追踪、广告主/卖家分层运营，以及平台广告收入口径核对。

各地区按本地时区参数化调度，所有地区统一写入同一张表，通过 `grass_region` 分区进行隔离；`tz_type` 分区进一步区分本地时区（`local`）与 UTC 口径，日常分析应以 `tz_type = 'local'` 为准。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。`'local'` 表示各地区本地时区口径，`'utc'` 表示 UTC 口径。⚠️ 日常分析必须指定 `tz_type = 'local'`，否则会重复统计两套时区数据 |
| `grass_region` | string | 地区分区，大写地区代码（如 `'ID'`、`'TH'`）。各地区通过 `${region}` 参数化调度写入，覆盖所有 Shopee 运营地区 |
| `grass_date` | date | 日期分区，格式 `yyyy-MM-dd`，表示数据所属的业务日期（本地时区） |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，来源于 `mp_paidads.dim_advertise` |
| `ads_status` | bigint | 广告状态枚举：0=已删除、1=正常、2=暂停、3=已关闭、4=临时保留、5=已取消、6=已封禁、7=删除隐藏 |
| `ads_type` | string | 广告类型文本，枚举值如 `targeting:similar_product`、`keyword:search` 等，来源于 `dim_advertise` |
| `ads_create_datetime` | string | 广告创建时间 |
| `is_ads_active` | tinyint | 广告活跃状态标志（1=活跃）。活跃广告是参与广告投放选择流程的广告池，若被选中则展示给用户 |
| `placement` | bigint | 广告位枚举（取值见字段描述中的 `TrackingPlacement` 枚举定义），标识广告展示的具体位置，如关键词搜索（0）、相似商品推荐（1）、直播（33）、视频流（34）等 |
| `entrance` | bigint | 广告入口枚举（取值见 `AdsEntrance` 枚举定义），标识用户进入广告的渠道入口，如关键词搜索（1）、直播发现（27）、视频流（29）等 |
| `entry_point` | string | 广告入口类型文本，由 `dim_entry_point_mapping_v2` 映射，无匹配时填充为 `'Undefined'` |
| `traffic_type` | string | 流量来源类型，由 `dim_entry_point_mapping_v2` 映射，无匹配时填充为 `'Undefined'` |
| `pricing_type` | int | 广告计价模式枚举：1=手动CPC、2=增强CPC、3=Boost计价、4=简单模式、5=CPT、6=CPM、7=自动Boost、8=目标广义ROAS、9=直播最大观看、10=直播最大GMV、11=ROI2.0 等；`placement` 为 45/46 时，NULL 值会被替换为 0 |
| `new_boost` | bigint | 广告是否为新商品推广类型（1=是） |
| `rapid_boost_toggle` | boolean | 急速推广开关状态 |
| `is_ocpm` | boolean | 是否为 oCPM（目标千次展示成本）计价模式 |
| `potential_product_type` | int | 广告创建时的潜在产品类型枚举，标识低价或高潜力商品 |
| `tag_ids` | array\<int\> | 广告关联的标签 ID 数组 |
| `ta_group_id` | bigint | 目标受众群体 ID，与特定 `campaign_id` 绑定，对特定卖家和活动唯一 |
| `ta_premium_rate` | bigint | 广告与目标受众群体匹配时的溢价率（对应 ETL 中的 `target_premium_rate`）|
| `has_performance` | tinyint | 广告是否有可衡量表现的标志（1=是）。当 `impression_cnt + click_cnt + cps_dedup_click_cnt + expenditure_amt_local + order_cnt + ads_gmv_local > 0` 时置为 1，否则为 0 |
| `hit_daily_budget` | tinyint | **已废弃（deprecated）**，当前恒为 NULL ⚠️ 请勿依赖此字段 |
| `hit_total_budget` | tinyint | **已废弃（deprecated）**，当前恒为 NULL ⚠️ 请勿依赖此字段 |

---

### 维度：活动（Campaign）属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_id` | bigint | 营销活动 ID |
| `campaign_status` | tinyint | 营销活动当前状态枚举 |
| `campaign_status_text` | string | 营销活动状态文本描述 |
| `campaign_start_datetime` | string | 营销活动开始时间 |
| `campaign_end_datetime` | string | 营销活动结束时间 |
| `campaign_total_quota_local` | double | 活动总预算（本地货币）|
| `campaign_total_quota_usd` | double | 活动总预算（USD）|
| `campaign_daily_quota_local` | double | 活动日预算（本地货币）|
| `campaign_daily_quota_usd` | double | 活动日预算（USD）|

---

### 维度：卖家与商店属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 商店 ID，来源于 `dim_advertise` |
| `seller_id` | bigint | 卖家 ID，与广告关联的卖家唯一标识 |
| `seller_type` | string | 卖家类型，如 MYCB、CNCB、Local 等；无匹配时填充为 `'Unknown'` |
| `seller_type_1p` | string | 一方卖家类型标识（如内部品牌等特定卖家分类）；无匹配时填充为 `'Unknown'` |
| `seller_tier` | string | 卖家分层标签：`large_seller`、`medium_seller`、`small_seller`、`micro_seller`。基于当月至昨日的累计 GMV 环比上月同期增量计算；无匹配时填充为 `'micro_seller'` ⚠️ 为派生分类字段，不可 SUM，仅用于分组过滤 |
| `advertiser_tier` | string | 广告主分层标签：`large_advertiser`、`medium_advertiser`、`small_advertiser`、`micro_advertiser`。基于当月至昨日的累计广告支出环比上月同期增量计算；无匹配时填充为 `'micro_advertiser'` ⚠️ 为派生分类字段，不可 SUM，仅用于分组过滤 |
| `is_cb_seller` | tinyint | 是否跨境卖家标志（1=是）。数据从 2021-05-01 起可用，此前为 NULL |
| `is_cb_sip_affiliated` | tinyint | SIP 标签：父商店为跨境商店时，子商店标记为 1；无匹配时填充为 0 |
| `is_local_sip_affiliated` | tinyint | SIP 标签：父商店为本地商店时，子商店标记为 1；无匹配时填充为 0 |

---

### 维度：商品与类目属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID |
| `item_name` | string | 商品名称 |
| `price_usd` | double | 商品价格（USD），来源于 `dim_item` |
| `product_type` | string | 广告产品类型，无匹配时填充为 `'others'`；枚举定义见内部文档 |
| `sub_product_type` | string | 广告子产品类型，无匹配时填充为 `'others'` |
| `main_product_type` | string | 广告主产品类型，无匹配时填充为 `'Others'` |
| `level1_global_be_category` | struct\<level1_global_be_category_id:bigint, level1_global_be_category:string\> | 商品一级全球后台类目 |
| `level2_global_be_category` | struct\<level2_global_be_category_id:bigint, level2_global_be_category:string\> | 商品二级全球后台类目 |
| `level3_global_be_category` | struct\<level3_global_be_category_id:bigint, level3_global_be_category:string\> | 商品三级全球后台类目 |
| `level4_global_be_category` | string | 商品四级全球后台类目（字符串，来源于 `dim_item`）|
| `level1_fe_display_category_list` | array\<struct\<level1_fe_display_category_id:bigint, level1_fe_display_category:string, level1_fe_display_category_fraction_factor:double\>\> | 商品一级前端展示类目列表（含分配因子）⚠️ 为数组结构，需展开（LATERAL VIEW EXPLODE）后使用；`fraction_factor` 为权重系数，不可直接 SUM 指标，需乘以对应权重 |
| `level2_fe_display_category_list` | array\<struct\<level2_fe_display_category_id:bigint, level2_fe_display_category:string, level2_fe_display_category_fraction_factor:double\>\> | 商品二级前端展示类目列表（含分配因子）⚠️ 同上，需展开后结合权重使用 |
| `level3_fe_display_category_list` | array\<struct\<level3_fe_display_category_id:bigint, level3_fe_display_category:string, level3_fe_display_category_fraction_factor:double\>\> | 商品三级前端展示类目列表（含分配因子）⚠️ 同上，需展开后结合权重使用 |
| `level1_kpi_category_list` | array\<struct\<level1_kpi_category_id:bigint, level1_kpi_category:string, level1_kpi_category_fraction_factor:double\>\> | 一级 KPI 类目列表（含分配因子）⚠️ 同上，需展开后结合权重使用 |
| `level2_kpi_category_list` | array\<struct\<level2_kpi_category_id:bigint, level2_kpi_category:string, level2_kpi_category_fraction_factor:double\>\> | 二级 KPI 类目列表（含分配因子）⚠️ 同上，需展开后结合权重使用 |
| `level3_kpi_category_list` | array\<struct\<level3_kpi_category_id:bigint, level3_kpi_category:string, level3_kpi_category_fraction_factor:double\>\> | 三级 KPI 类目列表（含分配因子）⚠️ 同上，需展开后结合权重使用 |
| `shop_level1_global_be_category` | string | 商店一级全球后台类目 |
| `shop_level1_fe_display_category` | string | 商店一级前端展示类目 |
| `shop_level1_kpi_category` | string | 商店一级 KPI 类目 |

---

### 指标：广告曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt` | bigint | 广告原始曝光量（raw impression count） |
| `click_cnt` | bigint | 成功扣费的点击次数 |
| `deduplicated_click_cnt` | bigint | 去重后的点击数 |
| `cps_dedup_click_cnt` | bigint | CPS（每次销售成本）模型下去重的点击数 |
| `avg_ads_ranks` | double | 广告在页面上的平均位置。ETL 中为 `SUM(avg_ads_ranks × impression_cnt) / impression_cnt` 计算得出 ⚠️ 为预计算加权均值，不可直接 SUM；若需跨行聚合，须用 `SUM(avg_ads_ranks × impression_cnt) / SUM(impression_cnt)` 重新计算 |
| `shopitem_impression_cnt` | bigint | 直接归因口径下广告商店商品曝光量（对应 ETL 中 `direct_shop_item_impression_cnt_1d`）|
| `shopitem_click_cnt` | bigint | 直接归因口径下广告商店商品点击数 |
| `broad_shopitem_impression_cnt` | bigint | 广义归因口径下广告商店商品曝光量（来源于 `dws_advertise_performance_1d` 的 `broad_shop_item_impression_cnt_1d`）|
| `broad_shopitem_click_cnt` | bigint | 广义归因口径下广告商店商品点击数 |
| `view_cnt` | bigint | PDP（商品详情页）浏览量，指已登录用户点击广告后进入详情页的次数 |

---

### 指标：视频广告专项

| 字段 | 类型 | 说明 |
|------|------|------|
| `video_view` | bigint | 视频播放次数（VV）。视频首帧播放时计数，但并非每次首帧播放都计为新 VV |
| `video_play_3s_cnt` | bigint | 视频播放时长超过 3 秒的次数 |
| `video_play_5s_cnt` | bigint | 视频播放时长超过 5 秒的次数 |
| `video_play_complete` | bigint | 视频完整播放次数 |
| `view_duration` | bigint | 广告被观看的总时长（单位依上游定义） |
| `product_click_cnt` | bigint | 商品点击数（去重），仅适用于视频广告 |

---

### 指标：广告支出

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_expenditure_amt_local` | double | 广告总支出（本地货币） |
| `ads_expenditure_amt_usd` | double | 广告总支出（USD）|
| `expense_rebate_free_credit_without_expiry` | decimal(25,10) | 平台 auto rebate 产生的无过期时间的免费广告金金额 |

---

### 指标：广告收入

| 字段 | 类型 | 说明 |
|------|------|------|
| `net_ads_revenue_usd_1d` | double | 当日净广告收入（USD），来源于 `dws_advertise_net_ads_revenue_1d` |
| `free_ads_revenue_amt_usd_1d` | double | 当日免费广告收入（USD），来源于净广告收入表 |
| `gross_ads_revenue_usd_1d` | double | 当日毛广告收入（USD）= `net_ads_revenue_usd_1d` + `free_ads_revenue_amt_usd_1d`（扣税后）。税率因地区而异（TW 5%、PH 12%、BR 各口径不同）⚠️ 口径复杂，含税及信用额度到期处理，跨口径对比前请确认计算逻辑 |

---

### 指标：直接归因订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt` | bigint | 直接归因口径下广告产生的订单数 |
| `ads_items_sold_cnt` | bigint | 直接归因订单中的商品 item 数量 |
| `ads_gmv_local` | double | 直接归因口径下订单 GMV（本地货币）。GMV = 商品单价 × 数量，仅含商品折扣/捆绑促销，不含运费、平台返利、买家费、优惠券、银行/卡返利及积分返利 |
| `ads_gmv_usd` | double | 直接归因口径下订单 GMV（USD）|
| `add_to_cart_cnt` | bigint | 广告产生的加入购物车次数（直接归因，对应 `direct_add_to_cart_cnt_1d`）|
| `checkout_cnt` | bigint | 直接归因口径下结算订单数（按 `order_id` 去重） |

---

### 指标：广义归因订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order_cnt` | bigint | 广义归因口径下广告产生的订单数 |
| `broad_order_item_cnt` | bigint | 广义归因口径下广告 item 量 |
| `broad_order_gmv_amt_local` | double | 广义归因口径下订单 GMV（本地货币）|
| `broad_order_gmv_amt_usd` | double | 广义归因口径下订单 GMV（USD）|
| `broad_add_to_cart_cnt` | bigint | 广义归因加入购物车次数 = `add_to_cart_cnt` + `add_to_cart_without_clicks_cnt` + broad_add_to_cart_other（用户点击广告商品 A 后，其他商品 B 被加购的情况）|
| `add_to_cart_without_clicks_cnt` | bigint | 无点击加入购物车次数（一日内汇总）|
| `broad_roi` | double | 广义归因 ROI = `broad_order_gmv_amt_local / ads_expenditure_amt_local`，分母为 0 时取 0.0 ⚠️ 为预计算比率，不可直接 SUM；跨行聚合须用 `SUM(broad_order_gmv_amt_local) / SUM(ads_expenditure_amt_local)` 重新计算 |

---

### 指标：付费订单归因（Paid Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_order_cnt` | bigint | 付费订单数（当日分区值）。⚠️ **非最终确认值**，因上游支付核验存在延迟，当日分区数据可能变动。若需准确值，请使用 `grass_date+1` 分区中的 `paid_order_cnt_ytd` 字段 |
| `paid_order_cnt_ytd` | bigint | `grass_date - 1` 日的最终付费订单数（跨越两个分区汇总）。例如 `grass_date=2021-06-06` 时，此字段表示 2021-06-05 的最终付费订单数 ⚠️ 时效性字段，查询时需取 **目标日期+1** 的分区数据 |
| `paid_order_item_sold_cnt` | bigint | 直接付费订单中的商品 item 数量（用户在广告点击后 7 天内付款）|
| `paid_broad_order_cnt` | bigint | 广义付费订单数（用户点击广告商品后，在同一商店 7 天内下单付款）|
| `paid_broad_order_gmv` | double | 广义付费订单 GMV（本地货币）|
| `paid_broad_order_gmv_usd` | double | 广义付费订单 GMV（USD）|
| `paid_broad_order_item_sold_cnt` | bigint | 广义付费订单 item 数量 |
| `paid_checkout_cnt` | bigint | 付费结算订单数（订单中任意 item 在近 7 天有广义广告点击，按 `order_id` 去重）|
| `paid_agent_checkout_cnt` | bigint | 代理付费结算订单数（按代理付费 `order_id` 去重）|

---

### 指标：确认订单归因（Confirmed Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `confirmed_order_cnt` | bigint | 确认订单数（当日分区值）⚠️ **非最终确认值**，因上游数据延迟可能变动。准确值请使用 `grass_date+1` 分区中的 `confirmed_order_cnt_ytd` 字段 |
| `confirmed_order_cnt_ytd` | bigint | `grass_date - 1` 日的最终确认订单数（跨分区汇总）⚠️ 时效性字段，需取 **目标日期+1** 的分区数据 |
| `deduct_order_cnt` | bigint | CPS 模型下被扣除的订单数 |

---

### 指标：印象归因订单（Impression Attribution）

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_attr_paid_order_cnt` | bigint | 印象归因付费订单数（无广告点击但有广告曝光，命中 shop_exp_tag 的广义付费订单）|
| `imp_attr_paid_order_gmv` | double | 印象归因付费订单 GMV（本地货币）|
| `imp_attr_paid_order_gmv_usd` | double | 印象归因付费订单 GMV（USD）|
| `imp_attr_paid_order_item_sold_cnt` | bigint | 印象归因付费订单 item 数量 |

---

### 指标：无点击无曝光归因订单（No-Click Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_no_click_order_cnt` | bigint | 无广告点击且无广告曝光但命中 order_exp_tag 的付费订单数 |
| `paid_no_click_order_gmv` | double | 无点击付费订单 GMV（本地货币）|
| `paid_no_click_order_gmv_usd` | double | 无点击付费订单 GMV（USD）|
| `paid_no_click_order_item_sold_cnt` | bigint | 无点击付费订单 item 数量 |
| `no_click_gmv_usd` | double | 无点击且无曝光但命中 order_exp_tag 的订单 GMV（USD，place order 口径）|

---

### 指标：广告冷启动状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `cold_start_status_7d` | string | 广告创建后 7 天冷启动状态：`Order success`（有直接订单）/ `Broad order success`（仅有广义订单）/ `In progress`（无订单且曝光≤3000）/ `Unsuccess`（无订单且曝光≤9000）/ `Low quality`（无订单且曝光>9000）⚠️ 基于过去 7 天窗口期计算，仅适用于创建日期在近 7~14 天内的广告 |
| `cold_start_status_14d` | string | 广告创建后 14 天冷启动状态，分类逻辑同上，统计窗口扩展至 14 天 ⚠️ 同上，时效性限制同 `cold_start_status_7d` |
| `first_7d_order_count` | bigint | 广告创建后前 7 天内产生的订单数 |
| `first_14d_order_count` | bigint | 广告创建后前 14 天内产生的订单数 |
| `first_order_date` | date | 广告创建后第一个订单的日期。通过自引用（前一天分区的历史值）与当日新产生首单取 COALESCE 得出 ⚠️ 仅覆盖 `ads_create_datetime >= '2023-03-10'` 的广告，更早广告此字段为 NULL |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区条件**，否则将触发全表扫描，导致资源浪费和性能问题：

| 分区字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `grass_date` | `grass_date = '2024-06-10'` 或范围过滤 | 全量历史数据扫描，查询极慢且成本极高 |
| `grass_region` | `grass_region = 'ID'` | 扫描所有地区数据，结果可能包含多地区重复计算 |
| `tz_type` | `tz_type = 'local'`（日常分析标准） | 数据量翻倍，同一业务事件被 local 和 utc 两套时区各计一次，导致指标虚高 |

**示例**：
```sql
SELECT ads_id, SUM(ads_expenditure_amt_usd)
FROM mp_paidads.ads_advertise_mkt_1d
WHERE grass_date = '2024-06-10'
  AND grass_region = 'ID'
  AND tz_type = 'local'
GROUP BY ads_id;
```

### 不可直接 SUM 的字段

以下字段**不能跨行直接 SUM 聚合**，需按正确方式重新计算：

| 字段 | 问题类型 | 正确计算方式 |
|------|----------|-------------|
| `avg_ads_ranks` | 加权均值，已预计算 | `SUM(avg_ads_ranks * impression_cnt) / NULLIF(SUM(impression_cnt), 0)` |
| `broad_roi` | 预计算比率（GMV/支出）| `SUM(broad_order_gmv_amt_local) / NULLIF(SUM(ads_expenditure_amt_local), 0)` |
| `seller_tier` | 派生分类字段 | 仅用于 GROUP BY / WHERE 过滤，不参与数值聚合 |
| `advertiser_tier` | 派生分类字段 | 仅用于 GROUP BY / WHERE 过滤，不参与数值聚合 |
| `level*_*_category_list`（array 类型）| 数组结构含权重分配因子 | 需 `LATERAL VIEW EXPLODE` 展开后，用 `fraction_factor` 加权计算各类目下指标 |
| `gross_ads_revenue_usd_1d` | 含复杂口径调整（税率、信用额度）| 跨口径对比前须确认包含/排除项（paid credit expire、free credit expired 等）|

### 时效性说明

本表含两类时效性敏感字段，**切勿直接使用当日分区的"当日值"作为最终统计结果**：

| 场景 | 错误做法 | 正确做法 |
|------|----------|----------|
| 获取 **2024-06-05** 的最终付费订单数 | `WHERE grass_date='2024-06-05'` 取 `paid_order_cnt` | `WHERE grass_date='2024-06-06'` 取 `paid_order_cnt_ytd` |
| 获取 **2024-06-05** 的最终确认订单数 | `WHERE grass_date='2024-06-05'` 取 `confirmed_order_cnt` | `WHERE grass_date='2024-06-06'` 取 `confirmed_order_cnt_ytd` |

**原因**：付款核验和订单确认事件存在上游延迟，部分 T 日发生的事件会在 T+1 日分区中才能完整落库。`*_ytd` 字段通过合并 T 日和 T+1 日的数据得到最终值，代表 T 日的最终口径。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertise__reg_s0_live` | 广告主维度表，提供广告基础属性（ads_id、placement、ads_type、campaign 信息、类目、定价类型等），为本表驱动表 |
| `mp_paidads.dws_advertise_performance_1d__reg_s0_live` | 广告每日绩效事实表，提供曝光、点击、订单、GMV、加购等核心指标，以及冷启动状态计算的历史窗口数据 |
| `mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live` | 广告净收入每日表，提供净收入、免费广告收入、毛收入指标 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维度表，提供商店级属性（是否跨境卖家、商店类目、卖家类型等）|
| `mp_paidads.dim_advertiser_tier_threshold__reg_s0_live` | 广告主分层阈值维表，定义 large/medium/small advertiser 的 USD 支出门槛 |
| `mp_paidads.dim_seller_tier_threshold__reg_s0_live` | 卖家分层阈值维表，定义 large/medium/small seller 的 GMV 门槛 |
| `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live` | 广告主广告位累计绩效表（td=to-date），用于计算当月至今的广告支出，进而判断广告主分层 |
| `mp_order.dws_seller_gmv_td__reg_s0_live` | 卖家 GMV 累计表（td=to-date），用于计算当月至今的卖家 GMV，进而判断卖家分层 |
| `mp_paidads.dim_entry_point_mapping_v2` | 入口点映射维表，将 `entrance` 枚举映射为 `entry_point` 和 `traffic_type` 文本 |
| `mp_seller.dim_shop_ext__reg_s0_live` | 商店扩展维表，提供 SIP 关联标签（`is_cb_sip_affiliated`、`is_local_sip_affiliated`）|
| `mp_item.dim_item__reg_s0_live` | 商品维表，提供商品价格（USD）和四级全球后台类目 |
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live`（自引用）| 读取前一日（T-2）分区的历史 `first_order_date`，实现首单日期的增量维护 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_advertise (驱动表，当日全量广告)
    │
    ├──► [ads_info CTE] ◄── mp_paidads.dws_advertise_performance_1d (当日绩效)
    │         │ 按 ads_id, placement, new_boost, entrance, tz_type 聚合
    │
    ├──► [net_revenue CTE] ◄── mp_paidads.dws_advertise_net_ads_revenue_1d (当日收入)
    │         │ 按 ads_id, placement, new_boost, entrance, tz_type 聚合
    │
    ├──► [ads_create_within_14d CTE] ◄── dim_advertise (近14日窗口)
    │         │                   ◄── dws_advertise_performance_1d (近14日绩效)
    │         │
    │    ├──► [cold_start_7d CTE]   → cold_start_status_7d, first_7d_order_count
    │    └──► [cold_start_14d CTE]  → cold_start_status_14d, first_14d_order_count
    │
    ├──► [first_order CTE] ◄── mp_paidads.ads_advertise_mkt_1d (T-2日自引用，历史首单)
    │         │          ◄── dws_advertise_performance_1d (当日新增首单)
    │         │ COALESCE(历史首单日期, 当日首单日期)
    │
    ├──► [traffic_mapping CTE] ◄── mp_paidads.dim_entry_point_mapping_v2
    │
    ├──► [dim_shop_ext CTE] ◄── mp_seller.dim_shop_ext (SIP 标签)
    │
    ├──► [dim_item CTE] ◄── mp_item.dim_item (商品价格与四级类目)
    │
    ├──► [advertiser_tier CTE] ◄── dws_advertiser_placement_performance_td (月累计支出)
    │         │                ◄── dim_advertiser_tier_threshold (分层阈值)
    │         │ 月环比增量支出判断分层
    │
    └──► [seller_tier CTE] ◄── mp_order.dws_seller_gmv_td (月累计 GMV)
              │             ◄── dim_seller_tier_threshold (分层阈值)
              │ 月环比增量 GMV 判断分层
              │
              ▼
    ════════════════════════════════
     INSERT OVERWRITE
     ads_advertise_mkt_1d__reg_s0_live
     PARTITION(tz_type, grass_region, grass_date)
    ════════════════════════════════
    （以 dim_advertise 为驱动，LEFT JOIN 所有 CTE，过滤 pricing_type != 29）
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `ads_create_within_14d` | `dim_advertise`、`dws_advertise_performance_1d` | 筛选近 14 天内创建的广告及其绩效，为冷启动状态计算提供基础数据窗口 |
| `cold_start_7d` | `ads_create_within_14d` | 在近 7 天窗口内，按订单数/曝光量对广告进行冷启动状态分类，并输出前 7 天订单数 |
| `cold_start_14d` | `ads_create_within_14d` | 在近 14 天窗口内，执行同上冷启动分类逻辑，并输出前 14 天订单数 |
| `first_order` | `ads_advertise_mkt_1d`（T-2自引用）、`dws_advertise_performance_1d` | 增量维护首单日期：优先继承 T-2 日已记录的历史首单日期，若无则以当日首次出现订单的日期填充 |
| `ads_info` | `dws_advertise_performance_1d` | 聚合当日广告绩效核心指标（曝光、点击、订单、GMV、加购、视频、付费订单等），维度粒度为 ads_id × placement × new_boost × entrance × tz_type |
| `traffic_mapping` | `dim_entry_point_mapping_v2` | 映射 entrance 枚举到 entry_point 和 traffic_type 文本 |
| `dim_shop_ext` | `mp_seller.dim_shop_ext` | 获取当日商店 SIP 关联标签 |
| `dim_item` | `mp_item.dim_item` | 获取当日商品价格（USD）和四级全球后台类目 |
| `advertiser_tier_threshold` | `dim_advertiser_tier_threshold` | 获取当前地区广告主各分层的最低支出门槛（USD）|
| `seller_tier_threshold` | `dim_seller_tier_threshold` | 获取当前地区卖家各分层的最低 GMV 门槛（USD）|
| `advertiser_tier` | `dws_advertiser_placement_performance_td`、`advertiser_tier_threshold` | 基于月初至昨日 vs 上月同期广告支出增量，对每个商店计算广告主分层 |
| `seller_tier` | `mp_order.dws_seller_gmv_td`、`seller_tier_threshold` | 基于月初至昨日 vs 上月同期 GMV 增量，对每个商店计算卖家分层 |
| `net_revenue` | `dws_advertise_net_ads_revenue_1d` | 聚合当日广告净收入、免费广告收入、毛收入指标 |

### 注意事项

1. **驱动表与过滤**：主查询以 `dim_advertise` 为驱动表，所有绩效表均为 LEFT JOIN，因此即使当日无绩效的广告也会出现在结果中（指标字段为 NULL 或 0）。`pricing_type = 29` 的广告被显式过滤排除。

2. **`first_order_date` 的覆盖范围**：增量维护逻辑中，自引用 T-2 分区时加了 `ads_create_datetime >= '2023-03-10'` 的过滤条件，因此 2023-03-10 之前创建的广告此字段将为 NULL（历史一次性回填逻辑已注释掉）。

3. **广告主/卖家分层的时效性**：`advertiser_tier` 和 `seller_tier` 使用"当月初至昨日"vs"上月同期"的 **to-date 累计值之差**衡量，并非当日单日数据；分层会随月份变化而变化，不可用于跨月横向对比。

4. **`avg_ads_ranks` 的还原**：ETL 中先计算 `SUM(avg_ads_ranks × impression_cnt)` 存储，在最终 SELECT 时除以 `impression_cnt` 恢复为均值。若对本表做二次聚合，不能直接 `SUM(avg_ads_ranks)`，必须用加权方式重算。

5. **`broad_roi` 的空值处理**：当 `ads_expenditure_amt_local = 0` 时，ETL 将 `broad_roi` 置为 0.0（而非 NULL），聚合时需注意此类记录不应参与 ROI 的分母统计。

6. **付费/确认订单的最终值口径**：`paid_order_cnt` 和 `confirmed_order_cnt` 为当日分区的**临时值**，最终准确值须从 **T+1 日分区**的 `_ytd` 字段获取，这是由于上游支付和订单核验存在跨日延迟所致。

7. **`hit_daily_budget` / `hit_total_budget`**：两字段已废弃，ETL 中写入 `null`，请勿依赖。

8. **NULL 填充约定**：`entry_point`、`traffic_type` 无匹配时填 `'Undefined'`；`product_type`、`sub_product_type` 填 `'others'`；`main_product_type` 填 `'Others'`；`seller_type`、`seller_type_1p` 填 `'Unknown'`；`is_cb_sip_affiliated`、`is_local_sip_affiliated` 填 `0`；分层字段填各自的 `micro_*` 默认值。

---

## 数据来源（上游汇总）

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertise__reg_s0_live` | 驱动表，广告全量维度属性 |
| `mp_paidads.dws_advertise_performance_1d__reg_s0_live` | 广告每日绩效事实（曝光/点击/订单/GMV 等） |
| `mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live` | 广告每日净/毛收入 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主（商店级）维度（跨境标签、类目、卖家类型）|
| `mp_paidads.dim_advertiser_tier_threshold__reg_s0_live` | 广告主分层阈值 |
| `mp_paidads.dim_seller_tier_threshold__reg_s0_live` | 卖家分层阈值 |
| `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live` | 广告主月累计广告支出（用于广告主分层）|
| `mp_paidads.dim_entry_point_mapping_v2` | entrance 枚举到 entry_point/traffic_type 的映射 |
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live`（自引用）| 历史首单日期增量继承 |
| `mp_order.dws_seller_gmv_td__reg_s0_live` | 卖家月累计 GMV（用于卖家分层）|
| `mp_seller.dim_shop_ext__reg_s0_live` | 商店 SIP 关联标签 |
| `mp_item.dim_item__reg_s0_live` | 商品价格与四级全球后台类目 |

---

*文档生成时间：2026-05-20*
