<!-- ads-workspace-gdoc-sync: gdoc_id=1Q9D11mAZrVJGfozAAwkgDWGTX-EzVYEEleGzZkn4XPE gdoc_url=https://docs.google.com/document/d/1Q9D11mAZrVJGfozAAwkgDWGTX-EzVYEEleGzZkn4XPE/edit -->

# Columns: mp_foa.dwd_eventid_impress_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

该表为事件级明细表，每条记录代表一次曝光事件。在当前 from-code 分析中未发现明显的非累加字段（无 SUM(DISTINCT) 模式）。

注意：`impress_cnt_direct_lead` 和 `impress_cnt_complete_lead` 是直接 SUM 的预聚合值，无需 DISTINCT。跨 `step1_feature_group` 聚合时，注意同一条曝光事件可能在不同 feature_group 视角下重复计算（多步跳转场景）。

### 枚举值映射 (Value Mappings)

#### step1_feature_group (入口/特征组) -- 出现在 15+ 文件中

| Value | Meaning | 典型流量 |
|-------|---------|---------|
| Search | 搜索入口 | 搜索广告 |
| Similar Products | 相似商品推荐 | 推荐/Discovery |
| You May Also Like | 看了又看 | 推荐/Discovery |
| Daily Discover | 每日发现 | 推荐/Discovery |
| Cart Recommendation | 购物车推荐 | 交易后推荐 |
| Order Successful Recommendation | 下单成功推荐 | 交易后推荐 |
| Rcmd Others | 其他推荐位 | My Purchase Page YMAL, Order Detail Page YMAL |

#### step1_feature_detail (入口详情 - Search) -- 出现在 5+ 文件中

| Value | Meaning |
|-------|---------|
| global_search-item | 全局搜索-商品结果 |
| search_in_pdp-item | 商品详情页内搜索-商品 |
| search_in_subcategory-item | 子类目内搜索-商品 |
| search_in_mall-item | 商场内搜索-商品 |
| search-item | 搜索-商品 |
| image_search-item | 图片搜索-商品结果 |
| image_search-original_item-item | 图片搜同款-商品 |
| image_search-rcmd-item | 图片搜索推荐-商品 |
| image_search-search-item | 图片搜索-搜索商品 |

#### step1_feature_detail (入口详情 - Rcmd Others) -- 出现在 2+ 文件中

| Value | Meaning |
|-------|---------|
| order_list-you_may_also_like-item | 订单列表-看了又看 |
| order_detail-you_may_also_like-item | 订单详情-看了又看 |

#### page_type -- 出现在 2+ 文件中

| Value | Meaning |
|-------|---------|
| search | 搜索结果页 |
| product | 商品详情页 |
| home | 首页 |
| fruit_store | 水果商店游戏 |
| game_candy_grocery_store | 糖果杂货店游戏 |

#### page_section -- 出现在 2+ 文件中

| Value | Meaning |
|-------|---------|
| you_may_also_like | 看了又看区块 |
| daily_discover | 每日发现区块 |

#### target_type -- 出现在 ~90% 查询中

| Value | Meaning | 出现频率 |
|-------|---------|:---:|
| item | 商品 | ~100% |

#### Traffic Type Classification (derived, 出现在 3+ 文件中)

| traffic_type | step1_feature_group 范围 |
|-------------|--------------------------|
| search | Search (with step1_feature = 'global_search') |
| rcmd | Similar Products, You May Also Like, Daily Discover, Cart Recommendation, Order Successful Recommendation, Rcmd Others |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: `'local'` (~95% 查询)
- `target_type`: `'item'` (~90% 查询)
- `grass_region`: 标准8区 `('ID','MY','PH','SG','TH','TW','VN','BR')` (~80%), 有时扩展 `'MX','CO','CL'`
- `platform`: `'ios_app'`, `'android_app'` (限定移动端场景)
- `user_id > 0`: 排除未登录用户 (~90%)
- `step1_feature_group IN ('Search')` -- 搜索场景
- `step1_feature_group IN ('Similar Products', 'You May Also Like', 'Daily Discover')` -- Discovery 场景
- `step1_feature_detail IN ('global_search-item','search_in_pdp-item','search_in_subcategory-item')` -- 标准搜索
- `page_type NOT IN ('game_candy_grocery_store', 'fruit_store')` -- 排除游戏页面
- `get_full_signature_udf(split(ab_test, '@')[1]) != 'DS2'` -- 排除特定 AB 实验组

### JSON 字段提取要点

`step1_data` 和 `step1_data_property` 是核心 JSON 字段，常用提取路径：

| 提取目标 | JSON 路径 | 使用方式 |
|----------|-----------|----------|
| item_id | `$.itemid` 或 `$.item.itemid` | `COALESCE(get_json_object(step1_data,'$.itemid'), get_json_object(step1_data,'$.item.itemid'))` |
| shop_id | `$.shopid` 或 `$.item.shopid` | 类似 item_id |
| is_ads (搜索) | `$.common_params.is_ads` (优先) 或 `$.search_params.search_info.is_ads` (fallback) | `COALESCE(json_extract(json_extract(step1_data_property,'$.common_params'),'$.is_ads'), json_extract(json_extract(step1_data_property,'$.search_params.search_info'), '$.is_ads'), 'false')` |
| is_ads (推荐) | `$.common_params.is_ads` (优先) 或 `$.is_ads` (fallback) | `COALESCE(json_extract(json_extract(step1_data_property,'$.common_params'),'$.is_ads'), json_extract(step1_data,'$.is_ads'), 'false')` |
| keyword (搜索词) | `$.search_FE.search_params.keyword` | `get_json_object(get_json_object(step1_data, '$.search_FE.search_params'), '$.keyword')` |
| location | `$.search_params.location` | `cast(get_json_object(get_json_object(step1_data_property, '$.search_params'), '$.location') as int)` |
| request_id (搜索) | `$.search_info.request_id` | `get_json_object(get_json_object(step1_data, '$.search_info'), '$.request_id')` |
| request_id (推荐) | `$.rcmd_params.recommendation_info` (REQID regexp) | `regexp_extract(cast(json_extract_scalar(step1_data_property, '$.rcmd_params.recommendation_info') as varchar), 'REQID:(.*?),', 1)` |
| AB signature (推荐) | `$.recommendation_info` (AB regexp) | `regexp_extract(cast(json_extract_scalar(step1_data, '$.recommendation_info') as varchar), 'AB:(.*?),', 1)` |
| mixer (AB 组标识) | `$.rcmd_params.recommendation_info` (AB regexp) | `regexp_extract(get_json_object(step1_data_property, '$.rcmd_params.recommendation_info'), 'AB:(.*?),', 1)` |
| pdp_itemid | `$.rcmd_params.ctx_itemid` | `cast(json_extract_scalar(step1_data_property, '$.rcmd_params.ctx_itemid') as bigint)` |
| search_scenario | `$.search_params.search_scenario` | `get_json_object(step1_data_property, '$.search_params.search_scenario')` |

## All Columns

*注：无 DDL，列名和类型从 SQL 使用模式推断。Description/Query Frequency/MAX 需 from-di 补充。*

| Column Name | Type (推断) | Description | L7/14/30D Query | MAX(column) |
|-------------|-------------|-------------|-----------------|-------------|
| grass_date | DATE (分区) | 当地日期分区 | - | - |
| grass_region | STRING (分区) | 地区/国家代码 | - | - |
| tz_type | STRING (分区) | 时区类型 (local/utc) | - | - |
| impress_event_id | STRING | 曝光事件唯一标识 | - | - |
| user_id | BIGINT | 用户 ID | - | - |
| item_id | BIGINT | 商品 ID | - | - |
| target_type | STRING | 目标类型 (item/shop) | - | - |
| step1_feature_group | STRING | 第1步特征组 (Search/Similar Products/YMAL/Daily Discover等) | - | - |
| step1_feature_detail | STRING | 第1步特征详情 (搜索类型/页面) | - | - |
| step1_feature | STRING | 第1步基础特征名 (global_search, My Purchase Page YMAL等) | - | - |
| step2_feature_group | STRING | 第2步特征组 (多步跳转场景) | - | - |
| step_count | INT | 跳转步数 | - | - |
| step1_data | STRING (JSON) | 第1步数据 JSON (itemid/shopid/keyword/is_ads/location/request_id) | - | - |
| step1_data_property | STRING (JSON) | 第1步属性 JSON (common_params/rcmd_params/search_params) | - | - |
| impress_cnt_direct_lead | BIGINT | 直接引导曝光量 (核心指标) | - | - |
| impress_cnt_complete_lead | BIGINT | 完整链路曝光量 (多步场景) | - | - |
| impress_timestamp | BIGINT | 曝光时间戳 (unix epoch) | - | - |
| platform | STRING | 平台类型 (ios_app/android_app) | - | - |
| page_type | STRING | 页面类型 (search/product/home/fruit_store/game_candy_grocery_store) | - | - |
| page_section | STRING | 页面区块 (you_may_also_like/daily_discover) | - | - |
| mapped_page_type | STRING | 映射页面类型 | - | - |
| session_id | STRING | 会话 ID | - | - |
| device_id | STRING | 设备 ID | - | - |
| ab_test | STRING | AB 实验签名 (格式: xxx@DSyyyy) | - | - |
