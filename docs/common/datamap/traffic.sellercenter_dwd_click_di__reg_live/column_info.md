<!-- ads-workspace-gdoc-sync: gdoc_id=1Wy2HB99x8CjMbT3NSUuNpw28BmyOgX6fDIRRqDaFeVM gdoc_url=https://docs.google.com/document/d/1Wy2HB99x8CjMbT3NSUuNpw28BmyOgX6fDIRRqDaFeVM/edit -->

# Columns: traffic.sellercenter_dwd_click_di__reg_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未在代码库中发现 SUM(DISTINCT) 模式应用于该表的字段。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| target_type | paid_ads | Marketing Centre/Shopee Ads (导航栏广告入口) |
| target_type | activate_now | Rapid Boost Banner"Activate Now"按钮 |
| page_type | seller_center_sidebar | Seller Center 侧边导航栏页面 |
| page_type | seller_center_shopee_ads | Seller Center Shopee Ads 主页面 |
| tz_type | local | 本地时区查询 (100% of references) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: `date_add('day', -1, current_date)` (~70% 查询昨日数据) / 或参数化日期范围
- `page_type`: 'seller_center_sidebar' (侧边栏分析) / 'seller_center_shopee_ads' (主页分析)
- `page_section[1]`: 'left_navigation' (左侧导航栏) / 'rapid_boost_banner' / 'rapid_boost_toggle_prompt' / 'resource_fetched' / 'module_enter' / 'homepage_enter' / 'white_screen'
- `target_type`: 'paid_ads' (导航栏广告入口分析) / 'activate_now' (Rapid Boost 分析)
- `grass_region`: IN ('ID', 'MY', 'PH', 'SG', 'TH', 'TW', 'VN', 'BR', 'OTHER') — 标准 8 区 + OTHER
- `tz_type`: 'local' (所有引用均使用 local)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| event_id | - | - | - | - |
| event_timestamp | - | - | - | - |
| shop_id | - | - | - | - |
| user_id | - | - | - | - |
| grass_date | - | - | - | - |
| grass_region | - | - | - | - |
| tz_type | - | - | - | - |
| page_type | - | - | - | - |
| page_section | - | - | - | - |
| target_type | - | - | - | - |
| data | - | - | - | - |
