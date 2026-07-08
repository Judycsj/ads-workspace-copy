<!-- ads-workspace-gdoc-sync: gdoc_id=14vJ0iQ2t8Rweu6XG1fKCSQHI50tT5CI9ZMidFIbbkG0 gdoc_url=https://docs.google.com/document/d/14vJ0iQ2t8Rweu6XG1fKCSQHI50tT5CI9ZMidFIbbkG0/edit -->

# Columns: mkplpaidads_search_ads.dws_traffic_boost_campaign_targets

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `target`: 统一目标值，跨 tag_bit 聚合无意义（不同 tag_bit 对应不同业务场景的目标）
- `days_remaining` / `orders_remaining`: 为时间点快照值，跨 grass_date 聚合无意义
- `ad_tag_contain_biz_tag`: 布尔值，跨 campaign 聚合为命中率可用 AVG

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| target_type | broad_order | 基于 Broad Order 的订单数目标 |
| target_type | direct_order | 基于 Direct Order 的订单数目标 |
| target_type | gmv | 基于 GMV 的目标 |
| ad_tag_contain_biz_tag | TRUE | campaign 的 ad_tag 命中了该 tag_bit 对应的 bitmask (ad_tag & (1 << (tag_bit-1)) != 0) |
| ad_tag_contain_biz_tag | FALSE | 未命中 |

### tag_bit 业务含义映射 (from tagConfig in target_calculation.py)

| tag_bit | target_type | days | date_type | orders | description |
|---------|-------------|------|-----------|--------|-------------|
| 35 | broad_order | 7 | first_delivery | 5 | 冷启动 Broad Order 7天 (ColdStartBroad8dLt5Ad) |
| 18 | direct_order | 7 | first_delivery | 3 | 冷启动 Direct Order 7天 (ColdStartDirect8dLt3Ad) |
| 51 | broad_order | 30 | item_create | 1 | 新品 Broad Order 30天 (NewItemAdsBreakOrderPhase) |
| 20 | direct_order | 30 | item_create | 1 | 新品 Direct Order 30天 (NewItemBoostDirect30dLt1Ad) |
| 54 | broad_order | 14 | first_delivery | 7 | 新 ROI2 冷启动 (NewRoi2ItemColdStartAd) |
| 62 | broad_order | 7 | fixed | 3 | 空单 Broad Order (EmptyOrderAds) |
| 19 | direct_order | 7 | fixed | 3 | 空单 Direct Order (EmptyOrderDirect8dLt3Ad) |
| 63 | gmv | 1 | - | - | GMV Boost (uplift 1.1x, baseline=avg_broad_gmv_local) |
| 23 | gmv | 1 | - | - | GMV Boost (uplift 1.2x, baseline=avg_broad_gmv_local) |
| 8 | direct_order | 7 | fixed | 3 | Direct Order |
| 12 | direct_order | 1 | fixed | 1 | Direct Order (fixed target, 1 order, no subtraction) |
| 21 | direct_order | 30 | item_create | 1 | Direct Order |
| 25 | order | 1 | - | - | (from TAG_LOOKBACK_MAP in reward model) |

**date_type 说明**:
- `first_delivery`: 以首次投放时间为窗口起点
- `item_create`: 以商品创建时间为窗口起点
- `fixed`: 固定时间点，从 midnight_ts 开始倒推

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'SG','TH','MY','ID','PH','TW','VN','BR' (标准 8 区)
- `tag_bit`: 8, 12, 18, 19, 20, 21, 23, 35, 51, 54, 62, 63 (全部 biz_tag)
- `target_type`: 'broad_order' (最常用), 'direct_order', 'gmv'
- `ad_tag_contain_biz_tag = TRUE`: 绝大多数查询的必选过滤 (100% 工作流查询)
- `days_remaining > 0`: 只查询活跃 campaign
- `target > 0`: 只查询有目标的 campaign
- `grass_date = date'...'` / `grass_date = 'YYYY-MM-DD'`: 按 T-1 snapshot 查询

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | STRING/DATE | 分区列，snapshot 日期 (T-1) | - | - |
| campaign_id | BIGINT | Campaign ID | - | - |
| shop_id | BIGINT | Shop ID | - | - |
| grass_region | STRING | 地区 (国家代码) | - | - |
| tag_bit | BIGINT | Biz Tag bit 值，对应业务场景标识 | - | - |
| target_type | STRING | 目标类型: broad_order / direct_order / gmv | - | - |
| orders_target | BIGINT/DECIMAL | 目标订单数 (原始配置) | - | - |
| days_target | BIGINT/DECIMAL | 目标天数 (原始配置) | - | - |
| gmv_target | DOUBLE | GMV 目标值 (baseline_gmv * uplift_ratio) | - | - |
| target | DOUBLE | 统一目标值: order类型=orders_remaining, gmv类型=gmv_target | - | - |
| orders_remaining | DOUBLE | 剩余订单数 (max(orders_target - 已达成订单, 0)) | - | - |
| days_remaining | DOUBLE | 剩余天数 (days_target - 已过去天数, min 0) | - | - |
| ad_tag_contain_biz_tag | BOOLEAN | ad_tag 位运算是否包含对应的 tag_bit | - | - |
| ad_tag | BIGINT | Campaign 下 ads 的 ad_tag 位掩码 | - | - |
| first_delivery_time | BIGINT | 首次投放时间 (Unix timestamp in seconds) | - | - |
| item_create_time | BIGINT | 商品创建时间 (Unix timestamp in seconds) | - | - |
| rev_local | DOUBLE | L7d 本地币支出 (expenditure_amt_local_1d) | - | - |
| rev_usd | DOUBLE | L7d USD 支出 (expenditure_amt_usd_1d) | - | - |
| broad_order_cnt | BIGINT/DECIMAL | L7d Broad Order 订单数 | - | - |
| direct_order_cnt | BIGINT/DECIMAL | L7d Direct Order 订单数 | - | - |
| l14d_broad_order_cnt | BIGINT/DECIMAL | L14d Broad Order 订单数 | - | - |
| l14d_direct_order_cnt | BIGINT/DECIMAL | L14d Direct Order 订单数 | - | - |
| avg_direct_gmv_local | DOUBLE | L7d 日均 Direct GMV (本地币) | - | - |
| avg_broad_gmv_local | DOUBLE | L7d 日均 Broad GMV (本地币) | - | - |
| avg_direct_gmv_usd | DOUBLE | L7d 日均 Direct GMV (USD) | - | - |
| avg_broad_gmv_amt_usd | DOUBLE | L7d 日均 Broad GMV (USD) | - | - |

> 注: 列类型从 Python DataFrame 推断，无显式 DDL。Description/L7-30D Query/MAX 需通过 `--source from-di` 补充。
