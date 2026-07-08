<!-- ads-workspace-gdoc-sync: gdoc_id=1jgrw8YY2tfru2fTDfg1nAYmEMzbzuSXIupXA7FrwNfk gdoc_url=https://docs.google.com/document/d/1jgrw8YY2tfru2fTDfg1nAYmEMzbzuSXIupXA7FrwNfk/edit -->

# Columns: traffic_omni_oa.dwd_item_event_log_hi__reg_sensitive_live

> No DDL found in codebase. Columns below are inferred from SQL usage patterns. Run `--source from-di` to supplement with DataMap definitions.

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

> 未从代码库中识别到 SUM(DISTINCT) 模式，本表为明细事件日志，自然可累加。

### 枚举值映射 (Value Mappings)

#### operation

| Value | Meaning |
|--------|---------|
| impression | 曝光事件 |
| click | 点击事件 |

#### entry_point (CASE-WHEN 映射, 多文件重复出现)

| Mapping Rule | Output Value |
|--------|---------|
| feature_detail like 'video-mix_feed_page-%' and location_property.location > 0 and source1.feature_detail='home-daily_discover-item_mix_feed_card' | Daily Discover Mix Feed Internal |
| feature_detail = 'shop-you_may_also_like-item' | Shop You May Also Like |
| feature = 'voucher-voucher_landing' | Voucher Landing Recommendation |
| feature = 'crm_omni_attri-hot_deals_landing' | Hot Deals Landing Recommendation |
| feature_group = 'Video' and video_property.is_ymal_item = 1 | Video You May Also Like |
| feature_detail = 'order_shipping_info-you_may_also_like-item' | Shipping Info Page You May Also Like |
| page_type = 'search' and page_section is null and target_type in ('item','video','livestream','related_search') | Global Search |
| module = 'Image Search' | Image Search |
| feature_group = 'You May Also Like' | You May Also Like |
| feature_detail = 'me-you_may_also_like-item' | Me You May Also Like |
| feature_group = 'Order Successful Recommendation' | Order Successful Recommendation |
| feature = 'mpp_ymal-order_list' | My Purchase Page Recommendation |
| feature = 'odp_ymal-order_detail' | Order Detail Page Recommendation |
| feature_group = 'Cart Recommendation' | Cart Recommendation |
| module = 'Daily Discover' | Daily Discover External |
| else | Undefined |

#### tz_type

| Value | Meaning |
|--------|---------|
| local | Localtime-based (所有引用均使用此值) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: `BETWEEN DATE_SUB(DATE('${grass_date}'), 1) AND DATE('${grass_date}')` -- 包含前一天数据以捕获延迟事件; 或 `= date('${grass_date}')`
- `grass_region`: `upper('${region}')` -- 按区域过滤
- `tz_type`: `'local'` -- 所有引用均使用 local 时区
- `user_id`: `> 0` 且 `IS NOT NULL` -- 排除匿名用户
- `operation`: `in ('impression', 'click')` -- 曝光和点击; 或 `= 'impression'` (仅曝光)
- `common_property.is_ads`: `= true` 或 `= 1` -- 广告流量; `!= true or is null` -- 自然流量

### 小时级时区转换 (Hourly Timezone Conversion)

Regional 版本 (带 `_regional` 后缀) 使用 `grass_hour` 进行时区转换：

```sql
-- Regional variant: 精确到小时的时区过滤
AND FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(
    to_timestamp(concat(grass_date,' ',grass_hour),'yyyy-MM-dd H'),
    '${time_zone}'), 'Asia/Singapore') >= DATE('${grass_date}')
AND FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(
    to_timestamp(concat(grass_date,' ',grass_hour),'yyyy-MM-dd H'),
    '${time_zone}'), 'Asia/Singapore') < date_add(DATE('${grass_date}'), 1)
```

Non-regional 版本直接使用日期过滤，不依赖 grass_hour。

## All Columns

Columns inferred from SQL usage in codebase (no DDL available):

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | 分区日期 [PARTITION] | - | - |
| grass_hour | string | 分区小时 (格式 'H') [PARTITION] | - | - |
| grass_region | string | 分区区域 [PARTITION] | - | - |
| tz_type | string | 时区类型 (local/regional) [PARTITION] | - | - |
| operation | string | 事件操作类型 (impression/click) | - | - |
| user_id | bigint | 用户 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| ads_id | bigint | 广告 ID | - | - |
| app_version | string | App 版本号 | - | - |
| platform | string | 平台 (ios_app/android_app) | - | - |
| rn_version | string | React Native 版本 | - | - |
| page_type | string | 页面类型 (search/mix_feed_page 等) | - | - |
| page_section | string | 页面区域 | - | - |
| target_type | string | 目标类型 (item/video/livestream/related_search) | - | - |
| module | string | 上报模块 (Global Search/Image Search/Daily Discover 等) | - | - |
| feature | string | 具体功能标识 (mpp_ymal-order_list/voucher-voucher_landing 等) | - | - |
| feature_group | string | 功能分组 (You May Also Like/Live Streaming/Games/Video 等) | - | - |
| feature_detail | string | 功能详情 (video-mix_feed_page-*/shop-you_may_also_like-item 等) | - | - |
| object | string | 上报对象 | - | - |
| common_property | struct | 通用属性 (含 is_ads: boolean) | - | - |
| source1 | struct | Step1 归因数据 (含 common_property, location_property, module, feature_detail, feature_group, feature) | - | - |
| source2 | struct | Step2 归因数据 (同 source1 结构) | - | - |
| location_property | struct | 位置属性 (含 location: bigint) | - | - |
| search_property | struct | 搜索属性 (含 scenario: string) | - | - |
| video_property | struct | 视频属性 (含 is_ymal_item: int) | - | - |
| event_timestamp | timestamp | 事件时间戳 | - | - |
