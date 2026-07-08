<!-- ads-workspace-gdoc-sync: gdoc_id=1Be8jsp523zzDicuP53hSKM7SxmreiLLuHYisd97gn6Y gdoc_url=https://docs.google.com/document/d/1Be8jsp523zzDicuP53hSKM7SxmreiLLuHYisd97gn6Y/edit -->

# Columns: mp_foa.dwd_eventid_click_last_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为事件级日志表，除 `user_id` 外各事件独立，聚合时直接 `COUNT(*)` 即可，无需特殊处理。

跨 user_id 聚合时，COUNT DISTINCT 相关：
- `user_id` — 去重统计用户数时需要 `COUNT(DISTINCT user_id)`

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| target_type | item | 商品 |
| feature_group | Search | 搜索入口 |
| feature_group | Daily Discover | 每日发现 |
| feature_group | You May Also Like | 看了又看 |
| feature_detail | global_search-item | 全局搜索-商品 |
| feature_detail | search_in_pdp-item | 商详页搜索-商品 |
| feature_detail | search_in_subcategory-item | 类目搜索-商品 |
| feature_detail | search_in_mall-item | 商城搜索-商品 |
| feature_detail | search-item | 搜索-商品 |
| platform | ios_app | iOS App |
| platform | android_app | Android App |
| tz_type | local | 本地时区（几乎所有查询使用） |
| is_ads (JSON) | true / false | 是否广告点击（从 data_property JSON 提取） |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~95% 查询)
- `target_type`: 'item' (~90% 查询)
- `user_id > 0` (~90% 查询，过滤未登录用户)
- `platform`: ('ios_app', 'android_app') (~40% 查询)
- `feature_detail`: ('global_search-item', 'search_in_pdp-item', 'search_in_subcategory-item') (~35% 查询)
- `feature_group`: 'Search' (~25% 查询)
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR') + 'MX','CO','CL'
- `request_id is not null` + `location >= 0 AND location <= 300` (fill_rate/recall_rate 场景，用于 LEFT JOIN ads_slot 计算 adslot 覆盖)
- `coalesce(..., ..., 'false') = 'false'` (提取自然流量点击，滤除广告点击)

### 核心 JSON 提取模式

| JSON Path | 列来源 | 提取内容 | 用途 |
|-----------|--------|----------|------|
| `$.item.itemid` / `$.itemid` | data | 商品ID | 关联商品维度 |
| `$.item.shopid` / `$.shopid` | data | 店铺ID | 关联店铺维度（rcmd表使用） |
| `$.search_FE.search_params.keyword` | data | 搜索关键词 | 关键词填充率/召回率分析 |
| `$.search_FE.item.location` | data | 搜索结果位置 | 自然流量商品位置分析 |
| `$.search_info.is_ads` | data | 是否广告 | 广告分流 (CVR分析场景，直接从data提取) |
| `$.search_info.request_id` | data | 请求ID | 关联请求级别指标 |
| `$.common_params.is_ads` | data_property | 是否广告 | 分流 ads vs organic (主路径) |
| `$.search_params.search_info.is_ads` | data_property | 是否广告 | 广告分流 fallback (搜索路径) |
| `$.search_params.location` | data_property | 搜索结果位置 | 填充率/召回率计算 (fill_rate/recall_rate) |
| `$.inhouse_params.shop_id` | data_property | 店铺ID | 旧版 dws_item_performance 任务使用 |

## All Columns

DDL 未在 paidads-alg 代码库中找到（上游 FOA 团队产出）。以下为 SQL 模式中推断的列：

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | DATE | 分区日期 (PARTITION) | - | - |
| grass_region | STRING | 国家地区 (PARTITION) | - | - |
| tz_type | STRING | 时区类型 (PARTITION) | - | - |
| user_id | BIGINT | 用户ID | - | - |
| target_type | STRING | 目标类型 (主要为 item) | - | - |
| feature_group | STRING | 功能入口组 (Search/Daily Discover/...) | - | - |
| feature_detail | STRING | 功能入口详情 | - | - |
| platform | STRING | 平台 (ios_app/android_app) | - | - |
| data | STRING (JSON) | 事件数据体 (含 item, search_FE, search_info 等) | - | - |
| data_property | STRING (JSON) | 事件属性 (含 common_params, search_params 等) | - | - |
| click_timestamp | BIGINT | 点击时间戳 (unix timestamp) | - | - |
| ab_test | STRING | AB实验标识 | - | - |
| event_id | STRING | 事件ID | - | - |
