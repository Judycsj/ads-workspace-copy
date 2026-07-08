<!-- ads-workspace-gdoc-sync: gdoc_id=1HuBHOLTNqACjJXNbQnic4kPg_xwf5VQ2NKcD4c0Kjjs gdoc_url=https://docs.google.com/document/d/1HuBHOLTNqACjJXNbQnic4kPg_xwf5VQ2NKcD4c0Kjjs/edit -->

# Columns: mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无。该表所有指标均为按 shop_id + placement 粒度的 SUM 聚合，可直接 SUM 上卷。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| placement | 0 | Search Manual |
| placement | 4 | Search Simple |
| placement | 2 | Discovery Daily (DD) Manual |
| placement | 802 | Discovery Daily (DD) Simple |
| placement | 5 | You May Also Like (YMAL) Manual |
| placement | 805 | You May Also Like (YMAL) Simple |
| placement | 3 | Shop Ads |
| placement | 1000, 1002, 1005 | Itemboost |
| placement | 1200, 1202, 1205 | Autoboost |
| placement | 40 | ROI2 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 所有写文件和绝大多数读文件固定使用 'local'
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR') + 'MX'
- `grass_date`: 读文件通常为当天 `${grass_date}`，advertiser_tier 计算使用 `date_trunc('month', ...) - interval '1' day`（月末）
- `placement`: 查询时常拆分为 Search(0,4) / Discovery(2,5,802,805) / Shop(3) / Itemboost(1000,1002,1005) / Autoboost(1200,1202,1205) / ROI2(40)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | 卖家 ID | - | - |
| placement | bigint | 广告位（见枚举值映射） | - | - |
| impression_cnt_td | bigint | 累计曝光数 | - | - |
| click_cnt_td | bigint | 累计点击数 | - | - |
| order_cnt_td | bigint | 累计订单数 | - | - |
| ads_items_sold_cnt_td | bigint | 累计销量（件数） | - | - |
| ads_gmv_amt_local_td | double | 累计广告 GMV（本币） | - | - |
| ads_gmv_amt_usd_td | double | 累计广告 GMV（USD） | - | - |
| expenditure_amt_local_td | double | 累计花费（本币） | - | - |
| expenditure_amt_usd_td | double | 累计花费（USD） | - | - |
| broad_gmv_amt_usd_td | double | 累计 Broad GMV（USD） | - | - |
| tz_type | string | 时区类型 [PARTITION] | - | - |
| grass_region | string | 地区 [PARTITION] | - | - |
| grass_date | DATE | 数据日期 [PARTITION] | - | - |
