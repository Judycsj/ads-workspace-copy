<!-- ads-workspace-gdoc-sync: gdoc_id=1sBuI9grb6uH6VJVvQ9RAobGEvhMpS0aNlwfiDTe7Mk0 gdoc_url=https://docs.google.com/document/d/1sBuI9grb6uH6VJVvQ9RAobGEvhMpS0aNlwfiDTe7Mk0/edit -->

# Columns: mp_paidads.ods_log_ads_order_attribution_hi__reg_s0_live

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID' (最常用), 'SG', 'TH', 'VN', 'BR', 'PH', 'MY', 'TW', 'MX', 'CO', 'CL'
- `grass_date`: 单个分区日期 `date 'YYYY-MM-DD'` 或范围 `between date 'xxx' and date 'xxx'`
- `h`: 按小时过滤，如 h = 10, h in (3, 4, 5)
- `click.ads_id > 0`: 过滤已归因到广告的订单
- `click is not null`: 过滤有广告点击的归因记录
- `timestamp` range: 按时间戳范围过滤，通常配合时区转换（如 `timestamp >= UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(...))`）

### 核心字段说明 (Key Fields)

**订单信息 (item struct)**:
- `item.orderid` — 订单 ID
- `item.userid` — 用户 ID
- `item.itemid` — 商品 ID
- `item.shopid` — 店铺 ID
- `item.amount` — 购买件数
- `item.price` (also `price` top-level) — 商品单价（local cent 单位），GMV = price * amount

**归因标记**:
- `new` — 是否为新归因（true 表示此订单商品归因于此广告点击）
- `broad` — 是否为 broad match（true 表示宽泛归因，false 为 direct）
- `checkout` — 是否已结算（订单支付确认）

**广告点击信息 (click struct)**:
- `click.ads_id` — 广告 ID
- `click.campaign_id` — 广告系列 ID
- `click.request_id` — 请求 ID（用于关联 tracking_item 表）
- `click.placement` — 广告位类型
- `click.pricing_type` — 出价类型
- `click.entrance` / `click.entry_point` — 入口类型
- `click.shop_id` — 广告店铺 ID
- `click.item_id` — 广告商品 ID
- `click.timestamp` — 广告点击时间戳

**枚举值映射 (Value Mappings)** — 以下为单个文件中出现的映射，仅供参考：

| Column | Value | Meaning | Source |
|--------|-------|---------|--------|
| click.placement | 3327,3328,33,3337,3338,3339,3342,3348 | Agent Ads | workflow attribution |
| click.entrance | 1,23 | Search | manual tasks |
| click.entrance | 3,25,30,31,32 | Discover/Daily Deals | manual tasks |
| click.entrance | 4,51 | YMAL (You May Also Like) | manual tasks |
| click.pricing_type | 11,15 | ROI2/R+- based pricing | manual tasks |

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_region | string | [PARTITION] 地区分区 | - | - |
| grass_date | date | [PARTITION] 日期分区 | - | - |
| h | int | [PARTITION] 小时分区 | - | - |
| item | struct<userid:bigint, orderid:bigint, shopid:bigint, itemid:bigint, modelid:bigint, amount:int, item_price:bigint, order_price:bigint, currency:string, status:int, chatid:bigint, snapshotid:bigint, offerid:bigint, extinfo:binary, groupid:bigint> | 订单商品信息结构体 | - | - |
| country | string | 国家/地区 | - | - |
| timestamp | bigint | 订单事件时间戳 (unix seconds) | - | - |
| click | struct<...> | 广告点击详情结构体 (含 70+ 字段) | - | - |
| new | boolean | 是否新归因 (此订单由此广告点击产生) | - | - |
| broad | boolean | 是否为 broad match 归因 | - | - |
| checkout | boolean | 是否已结算 | - | - |
| item_id | bigint | 商品 ID (冗余) | - | - |
| model_id | bigint | 型号 ID (冗余) | - | - |
| price | bigint | 商品单价 (local cent) | - | - |
| amount | bigint | 购买件数 | - | - |
| index | int | 索引位 | - | - |

### click struct 关键子字段

| Sub-field | Type | Description |
|-----------|------|-------------|
| click.country | string | 点击来源国家 |
| click.user_id | bigint | 点击用户 ID |
| click.ads_timestamp | bigint | 广告点击时间戳 |
| click.timestamp | bigint | 广告事件时间戳 |
| click.placement | int | 广告位类型 |
| click.ads_id | bigint | 广告 ID |
| click.campaign_id | bigint | 广告系列 ID |
| click.shop_id | bigint | 广告店铺 ID |
| click.item_id | bigint | 广告商品 ID |
| click.request_id | string | 请求 ID (关联 tracking) |
| click.raw_request_id | string | 原始请求 ID |
| click.organic_request_id | string | 自然请求 ID |
| click.entrance | int | 入口类型 |
| click.entry_point | int | 入口点 |
| click.pricing_type | int | 出价类型 |
| click.target_cir | double | 目标 CIR |
| click.account_id | bigint | 广告主账户 ID |
| click.signature | string | AB 实验签名 |
| click.unique_id | string | 唯一标识 |
| click.traffic_source | int | 流量来源 |
