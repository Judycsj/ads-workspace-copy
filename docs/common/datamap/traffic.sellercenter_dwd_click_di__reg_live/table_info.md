<!-- ads-workspace-gdoc-sync: gdoc_id=1MM7pVXPl4SE9s-Ilzv45IWpfiOjGWYTK9GwscpLJQ88 gdoc_url=https://docs.google.com/document/d/1MM7pVXPl4SE9s-Ilzv45IWpfiOjGWYTK9GwscpLJQ88/edit -->

# traffic.sellercenter_dwd_click_di__reg_live

## Description

- **Desc:** Seller Center 前端点击事件埋点表 (DWD 层)，记录用户在 Seller Center 各页面的点击行为，含页面类型、页面区域、点击目标、事件时间戳及 JSON 格式的扩展数据字段。
- **Granularity:** event-level (每条记录为一个点击事件)
- **Use Case:**
  1. Seller Center 导航栏点击 → 落地页曝光分析（左侧导航栏 "Marketing Centre/Shopee Ads" 入口的点击到页面 view 延迟分析）
  2. Campaign 创建入口归因（将 campaign 创建事件归因到具体的点击入口埋点，通过 shop_id/user_id 关联）
  3. Rapid Boost Banner 点击率分析（seller_center_shopee_ads 页面 Rapid Boost banner 的 impression/click 对比）
  4. Seller Center 入口点击特征追踪（通过 page_type-page_section-target_type 组合追踪用户入口行为）
- **Update Frequency:** Daily (日增量分区表)

## Key Metrics

- 点击事件数：COUNT(DISTINCT event_id)
- 独立店铺数：COUNT(DISTINCT shop_id)
- 基于时间差的转化指标：首点后 3s/5s/10s/30s 内落地页曝光率

## Key Dimensions

- 分区：grass_date, grass_region, tz_type
- 页面类型：page_type (如 'seller_center_sidebar', 'seller_center_shopee_ads')
- 页面区域：page_section (array 类型，如 ['left_navigation'])
- 点击目标：target_type (如 'paid_ads', 'activate_now', 'my_orders_button' 等)
- 用户标识：shop_id, user_id
- 事件标识：event_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | - |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 13 files (0 write, 13 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
