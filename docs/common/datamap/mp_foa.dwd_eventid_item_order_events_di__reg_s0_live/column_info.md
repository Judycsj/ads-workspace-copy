<!-- ads-workspace-gdoc-sync: gdoc_id=1i1vZlDpQ22Nna_l4hqaJY1ePizPn-JNwjxzVcWLGIP0 gdoc_url=https://docs.google.com/document/d/1i1vZlDpQ22Nna_l4hqaJY1ePizPn-JNwjxzVcWLGIP0/edit -->

# Columns: mp_foa.dwd_eventid_item_order_events_di__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

#### step1_feature_group (entry_point 映射)

| Value | Meaning | 出现文件数 |
|-------|---------|-----------|
| Cart Recommendation | 购物车推荐 | 10+ |
| Order Successful Recommendation | 下单成功推荐 | 10+ |
| You May Also Like | 猜你喜欢 | 15+ |
| Daily Discover | 每日发现 | 15+ |
| Similar Products | 相似商品 | 10+ |
| Search | 搜索 | 10+ |
| Rcmd Others | 其他推荐 | 8+ |

#### step1_feature_group -> placement (广告位映射)

| step1_feature_group | step1_feature (可选) | placement |
|---------------------|---------------------|-----------|
| Similar Products | - | 1 |
| Daily Discover | - | 2 |
| You May Also Like | - | 5 |
| Cart Recommendation | - | 8 |
| Order Successful Recommendation | - | 9 |
| Rcmd Others | 'Order Detail Page YMAL' | 10 |
| Rcmd Others | 'My Purchase Page YMAL' | 11 |

#### is_ads 取值

| Value | Meaning | 来源 |
|-------|---------|------|
| 'true' | 广告商品 | JSON 字段 `$.is_ads` 或 `$.common_params.is_ads` |
| 'false' | 自然/有机商品 | 同上 |

#### 归因字段后缀说明

| 后缀 | 含义 |
|-----|------|
| `_direct_lead` | 仅第一步归因 (step1)，不包含二级页面 (step2) |
| `_complete_lead` | 完整归因 (step1 + step2) |

### 非累加字段 (Non-Additive Fields)

本表为事件明细表，所有字段均为事件级，跨维度聚合时使用 SUM()：

- `place_order_cnt_direct_lead` / `place_order_cnt_complete_lead` — 下单量，SUM 聚合
- `place_gmv_usd_direct_lead` / `place_gmv_usd_complete_lead` — GMV (USD)，SUM 聚合

注意区分 `_direct_lead` 和 `_complete_lead` 后缀：
- 分析推荐位直接效果用 `_direct_lead`
- 分析全链路效果（包含从推荐位点击后在二级页面下单的场景）用 `_complete_lead`

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (几乎所有查询) / 'regional' (极少)
- `grass_region`: 常见 9 区 — 'ID','MY','PH','SG','TH','TW','VN','BR','MX'
- `grass_date`: 按日期范围过滤，常见 7d/14d/30d 滑动窗口
- `platform`: 'ios_app', 'android_app' (搜索/广告场景) / `is not null` (推荐场景)
- `step1_feature_group`: 按入口过滤，最常用 'Cart Recommendation','Order Successful Recommendation','You May Also Like','Daily Discover'
- `user_id > 0`: 过滤未登录用户
- `place_order_cnt_direct_lead > 0`: 过滤有效订单
- `month(grass_date) <> day(grass_date)` 和 `25 <> day(grass_date)`: 排除大促日（如每月 25 号）
- `coalesce(cast(json_extract_scalar(step1_data, '$.location') as int), -1) >= 0`: 过滤无效位置
- 搜索场景: `step1_feature_detail in ('global_search-item', 'search_in_pdp-item', 'search_in_subcategory-item')`

## All Columns

以下列名从 SQL 引用中提取（无 DDL，来源为代码推断）：

| Column Name | Type (推断) | Description | L7/14/30D Query | MAX(column) |
|-------------|------------|-------------|-----------------|-------------|
| grass_date | date | [PARTITION] 日期分区 | - | - |
| grass_region | string | [PARTITION] 地域分区 | - | - |
| tz_type | string | 时区类型 (regional/local) | - | - |
| user_id | bigint | 用户 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| step1_feature_group | string | 第一步归因入口 (entry_point) | - | - |
| step1_feature | string | 第一步归因子入口 | - | - |
| step1_feature_detail | string | 第一步归因详情 (如 global_search-item) | - | - |
| step1_data | string | 第一步事件 JSON 数据 (含 is_ads, location, recommendation_info 等) | - | - |
| step1_data_property | string | 第一步事件属性 JSON 数据 (含 common_params.is_ads, rcmd_params, search_params 等) | - | - |
| step2_feature_group | string | 第二步归因入口 (step_count > 1 时有值) | - | - |
| step_count | int | 归因步骤数 | - | - |
| platform | string | 平台 (ios_app/android_app) | - | - |
| device_id | string | 设备 ID | - | - |
| ab_test | string | AB 实验签名 | - | - |
| place_order_cnt_direct_lead | bigint/double | 第一步归因下单数 | - | - |
| place_gmv_usd_direct_lead | double | 第一步归因 GMV (USD) | - | - |
| place_order_cnt_complete_lead | bigint/double | 完整归因下单数 (step1+step2) | - | - |
| place_gmv_usd_complete_lead | double | 完整归因 GMV (USD) (step1+step2) | - | - |
| atc_event_timestamp | bigint | 加购事件时间戳 (unixtime, 用于 td_atc 当天归因) | - | - |
