<!-- ads-workspace-gdoc-sync: gdoc_id=1YgSLWkad7WXviirHEF7OhfMDGbzGg4QzJB7CH8Ivesc gdoc_url=https://docs.google.com/document/d/1YgSLWkad7WXviirHEF7OhfMDGbzGg4QzJB7CH8Ivesc/edit -->

# Columns: mp_paidads.dim_shop_info__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为维度表（a shop_id per partition），以 shop_id 为业务主键。跨分区聚合时注意：
- `seller_revenue_for_tier_usd` — 来自广告花费汇总，跨维度聚合需注意去重
- `seller_platform_gmv_for_tier_usd` — 来自平台 GMV 汇总，跨维度聚合需注意去重
- `key_seller_90`, `key_seller_95` — 基于 PERCENT_RANK 计算，属于分类标签不可累加

### 枚举值映射 (Value Mappings)

#### seller_type

| Value | Meaning |
|-------|---------|
| Official Store | 官方店铺 (is_official_shop = 1) |
| Cross Border | 跨境卖家 (is_cb_seller = 1) |
| Managed Seller | 管理卖家 (is_managed_seller = 1) |
| Preferred Seller | 优选卖家 (is_preferred_shop = 1) |
| Preferred Plus Seller | 优选+卖家 (is_preferred_plus_shop = 1) |
| Others | 其他 |

#### cluster (一级类目聚类)

| Value | Meaning |
|-------|---------|
| EL | 电子类 (Audio, Cameras & Drones, Computers, Gaming, Home Appliances, Mobile & Gadgets) |
| Fashion | 时尚类 (Clothes, Shoes, Bags, Watches, Accessories, Muslim Fashion) |
| FMCG | 快消类 (Beauty, Food & Beverages, Health, Mom & Baby, Pets) |
| Lifestyle | 生活类 (Automobiles, Books, Hobbies, Home & Living, Sports, Stationery, Vouchers) |

#### seller_status

| Value | Meaning |
|-------|---------|
| new | 新卖家 (上月无GMV，本月有) |
| existing | 活跃卖家 (上月有GMV且本月有增长) |
| churn | 流失卖家 (上月有GMV但本月无) |
| reactivated | 复活的卖家 (上月无但上上月有，本月有增长) |
| churned_before | 已流失或从未存在 |

#### advertiser_status

| Value | Meaning |
|-------|---------|
| new | 新广告主 |
| existing | 活跃广告主 |
| churn | 流失广告主 |
| reactivated | 复活广告主 |
| churned_before | 已流失 |
| never_activated | 从未激活 (default) |

#### seller_tier

| Value | Meaning |
|-------|---------|
| large_seller | 大卖家 |
| medium_seller | 中卖家 |
| small_seller | 小卖家 |
| micro_seller | 微卖家 (default) |

#### advertiser_tier

| Value | Meaning |
|-------|---------|
| large_advertiser | 大广告主 |
| medium_advertiser | 中广告主 |
| small_advertiser | 小广告主 |
| micro_advertiser | 微广告主 (default) |

#### principal_type

| Value | Meaning |
|-------|---------|
| Cross Border | 跨境卖家 (is_cb_seller=1 且无 msbenchmark principal_type) |
| Local Brand | 本地品牌 (default) |

#### seller_type_1p

| Value | Meaning |
|-------|---------|
| Lovito | Lovito 品牌 |
| SCS | Flock project / SCS |
| Local SCS | 本地 SCS 店铺列表 |
| Others | CB 类型为 CNCB |
| Unknown | 未识别 (default) |

#### ads_placement_type (31 种组合)

| Value | Meaning |
|-------|---------|
| full_ads | 全量广告 (search + discovery + shop + item + auto) |
| search_discovery_shop_auto | 搜索+发现+店铺+自动 |
| search_discovery_shop_item | 搜索+发现+店铺+商品 |
| search_discovery_item_auto | 搜索+发现+商品+自动 |
| search_shop_item_auto | 搜索+店铺+商品+自动 |
| discovery_shop_item_auto | 发现+店铺+商品+自动 |
| search_discovery_shop | 搜索+发现+店铺 |
| search_discovery_item | 搜索+发现+商品 |
| search_discovery_auto | 搜索+发现+自动 |
| search_shop_item | 搜索+店铺+商品 |
| search_shop_auto | 搜索+店铺+自动 |
| search_item_auto | 搜索+商品+自动 |
| discovery_shop_item | 发现+店铺+商品 |
| discovery_shop_auto | 发现+店铺+自动 |
| discovery_item_auto | 发现+商品+自动 |
| shop_item_auto | 店铺+商品+自动 |
| search_discovery | 搜索+发现 |
| search_shop | 搜索+店铺 |
| search_item | 搜索+商品 |
| search_auto | 搜索+自动 |
| search_only | 仅搜索 |
| discovery_shop | 发现+店铺 |
| discovery_item | 发现+商品 |
| discovery_auto | 发现+自动 |
| discovery_only | 仅发现 |
| shop_item | 店铺+商品 |
| shop_auto | 店铺+自动 |
| shop_only | 仅店铺 |
| item_auto | 商品+自动 |
| item_only | 仅商品 |
| auto_only | 仅自动 |
| no_related_ads | 无相关广告 (default) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 总是 `'local'`（所有生产/消费场景使用 local 时区）
- `grass_region`: 标准 9 区 (`'ID','MY','PH','SG','TH','TW','VN','BR','MX'`)，需 `upper(${region})` 匹配
- `grass_date`: `date('${BIZ_YESTERDAY}')` (~60% 查询) / `date('${PREV_2D}')` (~20%) / `date('${grass_date}')` (~20%)
- `shop_id`: 通常 `shop_id > 0` 过滤无效店铺
- `shop_level1_global_be_category is not null`: 过滤类目缺失的店铺

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | Shop ID (业务主键) | - | - |
| seller_name | string | 卖家名称 (来自 mp_user.dim_shop) | - | - |
| shop_level1_global_be_category | string | 一级全球BE类目 (来自 dws_shop_listing_td) | - | - |
| shop_level2_global_be_category | string | 二级全球BE类目 (来自 dws_shop_listing_td) | - | - |
| seller_type | string | 卖家类型 (Official Store/Cross Border/Managed Seller/Preferred Seller/Preferred Plus Seller/Others) | - | - |
| cluster | string | 一级类目聚类 (EL/Fashion/FMCG/Lifestyle) | - | - |
| is_principal | tinyint | 是否主店铺 (固定为 1) | - | - |
| principal_type | string | 主店铺类型 (Cross Border/Local Brand) | - | - |
| is_cb_seller | tinyint | 是否跨境卖家 | - | - |
| account_create_datetime | string | 广告账户创建时间 | - | - |
| is_official_shop | tinyint | 是否官方店铺 | - | - |
| is_preferred_shop | tinyint | 是否优选店铺 | - | - |
| is_managed_seller | tinyint | 是否管理卖家 | - | - |
| seller_status | string | 卖家状态 (new/existing/churn/reactivated/churned_before) | - | - |
| seller_tier | string | 卖家分层 (large_seller/medium_seller/small_seller/micro_seller) | - | - |
| advertiser_status | string | 广告主状态 (new/existing/churn/reactivated/churned_before/never_activated) | - | - |
| advertiser_tier | string | 广告主分层 (large_advertiser/medium_advertiser/small_advertiser/micro_advertiser) | - | - |
| ads_placement_type | string | 广告投放类型组合 (31种组合值) | - | - |
| key_seller_90 | tinyint | Top 10% GMV 关键卖家 (按一级类目 PERCENT_RANK) | - | - |
| key_seller_95 | tinyint | Top 5% GMV 关键卖家 (按一级类目 PERCENT_RANK) | - | - |
| is_cb_sip_affiliated | tinyint | 是否 CB SIP 关联 | - | - |
| is_local_sip_affiliated | tinyint | 是否本地 SIP 关联 | - | - |
| is_sip_primary | tinyint | 是否 SIP 主店铺 | - | - |
| cb_seller_type | string | CB 卖家类型 (来自 mp_cb.dim_shop_ext) | - | - |
| seller_type_1p | string | 1P 卖家类型标签 (Lovito/SCS/Local SCS/Others/Unknown) | - | - |
| seller_active_ads_placement_type | array\<string\> | 卖家活跃广告投放类型列表 | - | - |
| seller_revenue_for_tier_usd | double | 卖家广告花费 ($USD)，用于分层计算 | - | - |
| seller_platform_gmv_for_tier_usd | double | 卖家平台 GMV ($USD)，用于分层计算 | - | - |
| shop_level1_fe_display_category_id | bigint | 前端展示一级类目 ID | - | - |
| user_id | bigint | 用户 ID | - | - |
| tz_type | string | 时区类型 [PARTITION] | - | - |
| grass_region | string | 区域 [PARTITION] | - | - |
| grass_date | DATE | 数据日期 [PARTITION] | - | - |
