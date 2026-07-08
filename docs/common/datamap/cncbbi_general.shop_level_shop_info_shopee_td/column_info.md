<!-- ads-workspace-gdoc-sync: gdoc_id=10TTY99O_qf5-9iyLg3KnPk7w6nsB-C2pYf18f_H30TY gdoc_url=https://docs.google.com/document/d/10TTY99O_qf5-9iyLg3KnPk7w6nsB-C2pYf18f_H30TY/edit -->

# Columns: cncbbi_general.shop_level_shop_info_shopee_td

## Column Usage Notes

### 枚举值映射 (Value Mappings)

*Extracted from codebase CASE-WHEN patterns (2+ file occurrences).*

| Column | Value | Meaning |
|--------|-------|---------|
| is_cb_shop | 1 | CB (Cross-Border) shop |
| seller_type_1p | SCS | Self-operated (自营) |
| seller_type_1p | Lovito | Lovito brand shop |
| seller_type | Local | Local seller |
| seller_type | CB | Cross-Border seller |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: IN ('ID', 'MY', 'PH', 'SG', 'TH', 'TW', 'VN', 'BR') -- standard 8 regions (~95% of queries)
- `grass_region`: NOT IN ('IN','ES','FR','PL','CO','CL') -- exclude non-core regions (1 query)
- `is_cb_shop`: = 1 -- cross-border shop filter (16/21 files)
- `seller_type_1p`: IN ('SCS', 'Lovito') -- 1P shop exclusion filter (5/21 files)
- `shop_id`: cast to BIGINT when joining with ads tables

## All Columns

*Columns listed based on codebase references. Run `--source from-di` for full column list with descriptions and query frequency.*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_region | string | Region identifier (ID, MY, PH, SG, TH, TW, VN, BR) | - | - |
| shop_id | bigint | Shop unique identifier | - | - |
| is_cb_shop | int | Cross-border shop flag (1 = CB) | - | - |
| seller_type | string | Seller type (Local / CB) | - | - |
| seller_type_1p | string | 1P seller classification (SCS, Lovito, etc.) | - | - |
| is_1p | int | 1P seller indicator | - | - |
