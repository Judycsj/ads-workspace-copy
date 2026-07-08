<!-- ads-workspace-gdoc-sync: gdoc_id=10qhYA_POrMaRCCPIuxQh41H9jtaoTMfA8qAwuVrIicY gdoc_url=https://docs.google.com/document/d/10qhYA_POrMaRCCPIuxQh41H9jtaoTMfA8qAwuVrIicY/edit -->

# Columns: traffic.dwd_view_di__reg_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| page_type | my_ads_homepage | App Ads homepage view |
| page_type | seller_center_shopee_ads | PC Seller Center Ads page (used via `sellercenter_traffic_dwd_event_stream_di`, not this table directly) |
| domain_type | other | Non-game, non-live domain (used in conjunction with `my_ads_homepage`) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: `= 'local'` (all queries use local timezone)
- `grass_region`: `= upper('${region}')`, covers SEA 8 regions (ID/MY/PH/SG/TH/TW/VN/BR) + MX/CO/CL
- `page_type`: `= 'my_ads_homepage'` (for app-based advertiser activity tracking)
- `domain_type`: `= 'other'` (combined with `page_type = 'my_ads_homepage'` for ads activity views)
- `user_id`: `IS NOT NULL` (filter invalid records in potential buyer generation)

### 注意事项

- 此表仅记录 **App 端**的 view 事件。PC 端的 page view 数据在 `traffic.sellercenter_traffic_dwd_event_stream_di__reg_s1_live` 表中，使用 `page_type IN ('seller_center_shopee_ads')` 过滤。
- 在 `dim_advertiser_tier_tag` 工作流中，App view 和 PC view 通过 `UNION ALL` 合并成统一的 view activity 统计。

## All Columns

> DDL 未在代码库中找到，以下列名来源于 SQL 使用模式推断。运行 `--source from-di` 可补充完整的列信息。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | User identifier | - | - |
| shop_id | bigint | Shop identifier | - | - |
| item_id | bigint | Item identifier | - | - |
| page_type | string | Page type (e.g., 'my_ads_homepage') | - | - |
| domain_type | string | Domain type (e.g., 'other') | - | - |
| grass_date | date | Partition: date of the view event | - | - |
| grass_region | string | Partition: region of the view event | - | - |
| tz_type | string | Partition: timezone type ('local', 'regional') | - | - |

> 注：表中可能包含更多列（如 timestamp, platform, session_id 等），以上仅列出在代码库 SQL 中实际引用的列。运行 `from-di` 可获取完整列清单。
