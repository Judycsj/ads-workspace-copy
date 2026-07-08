<!-- ads-workspace-gdoc-sync: gdoc_id=1DvXrIrE6LyJHq7_fBGk-1LL1eYSrPZPEX9enmwgCcf4 gdoc_url=https://docs.google.com/document/d/1DvXrIrE6LyJHq7_fBGk-1LL1eYSrPZPEX9enmwgCcf4/edit -->

# Columns: mkplpaidads_data.dim_common_shop__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

> 未在代码库中发现 SUM(DISTINCT) 使用模式。该表为维表 (VIEW)，通常用于 JOIN 获取店铺元信息，非聚合表。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| status | 1 | 活跃店铺 (Active shop) |

> 仅 status 在 2+ 文件中以固定值出现。其他枚举字段 (is_official_shop, is_shopee_verified, cb_option 等) 未在两个以上独立文件中出现相同映射。

### 常见 WHERE 值 (Common Filter Values)

- `dt`: 通常取最新快照 `${yesterday}` 或 `"${BIZ_YESTERDAY}"` (~70% 查询)
- `grass_region`: 按站点过滤，常见值 'SG', 'MY', 'PH', 'TW', 'ID', 'TH', 'VN', 'BR' (标准 8 区)
- `status`: 1 (活跃店铺，筛选可操作的店铺)
- 通过 `dim_common_shop_latest__reg_s0_live` 视图使用时，仅需 `dt` 过滤

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint? | 店铺 ID | - | - |
| user_id | bigint? | 店主 user ID | - | - |
| user_name | string | 店主用户名 | - | - |
| rating_good_cnt | bigint? | 好评数 | - | - |
| rating_normal_cnt | bigint? | 中评数 | - | - |
| rating_bad_cnt | bigint? | 差评数 | - | - |
| shop_follow_cnt | bigint? | 店铺关注数 | - | - |
| sold_total_cnt | bigint? | 累计销量 | - | - |
| item_cnt | bigint? | 在售商品数 | - | - |
| cb_option | bigint? | 跨境选项 (ALIAS: is_cb_shop from dim_fp_shop) | - | - |
| status | bigint? | 店铺状态 (1=Active) | - | - |
| create_timestamp | bigint? | 创建时间戳 (Unix timestamp) | - | - |
| create_datetime | string | 创建日期时间 | - | - |
| modify_timestamp | bigint? | 修改时间戳 (Unix timestamp) | - | - |
| modify_datetime | string | 修改日期时间 | - | - |
| latitude | double? | 纬度 | - | - |
| longitude | double? | 经度 | - | - |
| is_official_shop | bigint? | 是否官方店 | - | - |
| is_shopee_verified | bigint? | 是否优选卖家 | - | - |
| is_star_seller | bigint? | 是否星卖家 | - | - |
| is_auto_reply_on | bigint? | 是否开启自动回复 | - | - |
| is_ship_from_overseas | bigint? | 是否海外发货 | - | - |
| has_order | bigint? | 是否有过订单 (ALIAS: is_had_order from dim_fp_shop) | - | - |
| has_decoration | bigint? | 是否有装修 (ALIAS: is_decorated from dim_fp_shop) | - | - |
| response_rate | double? | 回复率 | - | - |
| response_time | string | 回复时间 | - | - |
| rating_star | double? | 评分星级 | - | - |
| cancellation_rate | double? | 取消率 | - | - |
| fulfillment_rate_flag | bigint? | 履约率标记 | - | - |
| late_shipment_rate_flag | bigint? | 延迟发货率标记 | - | - |
| rating_count | bigint? | 评分数量 | - | - |
| label_ids | array? | 标签 ID 列表 | - | - |
| pick_up_address | struct? | 发货地址 (含 level4.name 等嵌套字段) | - | - |
| grass_region | string | 站点区域代码 (ALIAS: country from dim_fp_shop) | - | - |
| dt | string | 分区日期 (格式: YYYY-MM-DD) [PARTITION] | - | - |

> 注意: 该表为 VIEW，列类型继承自上游 `mkplpaidads_data.dim_fp_shop`。以上类型标注 `?` 的列表示从 DDL 推断但未在 CREATE TABLE 语句中显式确认。请通过 `DESCRIBE` 或 `--source from-di` 获取精确类型。
