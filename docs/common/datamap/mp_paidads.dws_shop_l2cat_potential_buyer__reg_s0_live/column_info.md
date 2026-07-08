<!-- ads-workspace-gdoc-sync: gdoc_id=1jXhOJ0BPsZ9fMFQWSyBTW7oJRuK9ozWi4mYLJeJf088 gdoc_url=https://docs.google.com/document/d/1jXhOJ0BPsZ9fMFQWSyBTW7oJRuK9ozWi4mYLJeJf088/edit -->

# Columns: mp_paidads.dws_shop_l2cat_potential_buyer__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| potential_buyer_type | 0 | 低潜力买家 |
| potential_buyer_type | 1 | 中低潜力买家 (ppv>=3 OR atc>=1 OR orders>=1) |
| potential_buyer_type | 2 | 中高潜力买家 (ppv>=6 OR atc>=3 OR orders>=1) |
| potential_buyer_type | 3 | 高潜力买家 (ppv>=9 OR atc>=5 OR orders>=1) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'TW', 'ID', 'SG', 'MX', 'CO', 'CL', 'BR' 等区域代码
- `potential_buyer_type >= 2`: 高潜力买家筛选（最常见的业务过滤条件）
- `l2_shop_cat`: 指定类目 ID（如 100737, 100664），用于定向特定品类的买家

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | 用户 ID | - | - |
| l2_shop_cat | bigint | 店铺二级类目 ID | - | - |
| potential_buyer_type | int | 潜在买家级别 (0-3) | - | - |
| grass_region | string | 地区分区列 [PARTITION] | - | - |
| grass_date | date | 日期分区列 [PARTITION] | - | - |
