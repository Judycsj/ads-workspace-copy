<!-- ads-workspace-gdoc-sync: gdoc_id=10_Hl1rwGzzcIVBZ627KON7YqanmfcxOCHQue8WguVR0 gdoc_url=https://docs.google.com/document/d/10_Hl1rwGzzcIVBZ627KON7YqanmfcxOCHQue8WguVR0/edit -->

# Columns: mkplpaidads_search_ads.omni_core_key_metrics_merge_daily__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

（未从代码库检测到 SUM(DISTINCT) 或 MAX 非累加模式）

### 枚举值映射 (Value Mappings)

common_feature（入口场景）→ scene（场景缩写）映射，在所有 7+ 个下游读文件中一致使用：

| common_feature | scene |
|--------|---------|
| Daily Discover | DD |
| You May Also Like | YMAL |
| Cart Recommendation, Hot Deals Landing Recommendation, My Purchase Page Recommendation, Order Detail Page Recommendation, Order Successful Recommendation, Shipping Info Page YMAL, Shop YMAL, Video YMAL, Voucher Landing Recommendation | PP |
| Global Search, Image Search | SEARCH |
| Games, Voucher Master | GAME |
| Live Streaming, Livestream Game | LIVESTREAM |
| Search Shop | SHOP |
| Shop Game | SHOP_GAME |
| From the Same Shop, Shop Main Browsing, Shop Other Recommendations, Shop Product Tab, Shop Recommended For You | IN_SHOP |
| Video | VIDEO |
| NULL or other | other |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID','PH','SG','TH','TW','MY','VN' (标准7区) / 'BR' (巴西)
- `grass_date`: `date('${ISO_YESTERDAY}')` (几乎所有读/写都按 T-1 分区)
- 写文件 (BR): 额外过滤 `common_feature != 'Platform'`
- dim_omni_item_shop_attr 用法: 额外过滤 `item_id IS NOT NULL AND shop_id IS NOT NULL`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| item_id | bigint | 商品ID | - | - |
| shop_id | bigint | 店铺ID | - | - |
| common_feature | string | 入口场景特征（如 Daily Discover / Global Search / Live Streaming 等） | - | - |
| ads_imp_cnt | bigint | 广告曝光数 | - | - |
| total_imp | bigint | 总曝光数（含自然流量） | - | - |
| ads_click_cnt | bigint | 广告点击数 | - | - |
| total_click | bigint | 总点击数（含自然流量） | - | - |
| ads_order_cnt | double | 广告订单数 | - | - |
| total_order | double | 总订单数（含自然流量） | - | - |
| ads_gmv_usd | double | 广告 GMV (USD) | - | - |
| total_gmv | double | 总 GMV (USD，含自然流量) | - | - |
| total_atc | bigint | 总加购数 | - | - |
| grass_date | date | 日期分区 | - | - |
| grass_region | string | 地区分区 | - | - |
