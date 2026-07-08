<!-- ads-workspace-gdoc-sync: gdoc_id=1ZTJf4RL_Gx1lWht8JkmhcA7IOOeqctjWNlh6vVbiNhI gdoc_url=https://docs.google.com/document/d/1ZTJf4RL_Gx1lWht8JkmhcA7IOOeqctjWNlh6vVbiNhI/edit -->

# Columns: mp_user.dim_shop__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

This is a dimension table — all fields are non-additive attributes. No SUM/aggregation patterns detected on this table's own columns.

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| is_official_shop | 1 | Official Store / Mall seller |
| is_official_shop | 0 | Non-official shop |
| is_preferred_shop | 1 | Preferred seller |
| is_preferred_plus_shop | 1 | Preferred Plus seller |
| is_managed_shop | 1 | Managed seller |
| is_cb_shop | 1 | Cross-border seller |
| status | 1 | Active shop |
| user_status | 1 | Active user account |
| is_holiday_mode | 1 | Shop in holiday mode |
| tz_type | 'local' | Local timezone (most common in Ads queries) |
| tz_type | 'regional' | Regional timezone |

**Seller type classification (derived, used in 5+ files):**

```sql
CASE
    WHEN is_official_shop = 1 THEN 'Mall' / 'Official Store'
    WHEN is_preferred_plus_shop = 1 THEN 'Preferred Plus Seller'
    WHEN is_preferred_shop = 1 THEN 'Preferred' / 'Preferred Seller'
    WHEN is_cb_shop = 1 THEN 'Cross Border'
    WHEN is_managed_shop = 1 / is_managed_seller = 1 THEN 'Managed Seller'
    ELSE 'Others' / 'MP'
END AS seller_type
```

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~80% of queries) / also used without tz_type filter in some cases
- `grass_region`: standard 8+1 regions ('ID','MY','PH','SG','TH','TW','VN','BR') + 'MX' in some US workflows + 'OTHER'
- `grass_date`: typically `'${BIZ_YESTERDAY}'` or `'${BIZ_PRE_DAY}'` or `date_add(current_date(), -1)`
- `status`: 1 (active shops, used in target audience pipelines)
- `user_status`: 1 (active users, used in target audience pipelines)
- `is_official_shop`: 1 (filter official shops for brand ads keyword relevance)
- `shop_id <> 0`: exclude invalid shop IDs

## All Columns

*Note: Column list below is inferred from SQL usage across 218 files. No DDL found in Ads codebase. Run `--source from-di` to get complete column list with types and descriptions.*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | - | - | - |
| user_id | bigint | - | - | - |
| shop_name | string | - | - | - |
| status | bigint | Shop status (1=active) | - | - |
| user_status | bigint | User account status | - | - |
| is_official_shop | int/boolean | - | - | - |
| is_preferred_shop | int/boolean | - | - | - |
| is_preferred_plus_shop | int/boolean | - | - | - |
| is_managed_shop | int/boolean | - | - | - |
| is_cb_shop | int/boolean | Cross-border shop flag | - | - |
| is_holiday_mode | int/boolean | Holiday mode flag | - | - |
| rating_star | double | Shop rating score | - | - |
| create_datetime | string | Shop creation datetime | - | - |
| modify_datetime | string | Shop modification datetime | - | - |
| grass_date | date | Partition: business date | - | - |
| grass_region | string | Partition: region code | - | - |
| tz_type | string | Partition: timezone type | - | - |

<!-- ANALYSIS_PLACEHOLDER -->
