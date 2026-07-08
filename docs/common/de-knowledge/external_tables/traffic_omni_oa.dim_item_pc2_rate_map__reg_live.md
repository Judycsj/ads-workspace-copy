<!-- ads-workspace-gdoc-sync: gdoc_id=1Mhqgcsj-4LAOd8YWW7V7axp9nWZGAgE48dVHLCErCDE gdoc_url=https://docs.google.com/document/d/1Mhqgcsj-4LAOd8YWW7V7axp9nWZGAgE48dVHLCErCDE/edit -->

# traffic_omni_oa.dim_item_pc2_rate_map__reg_live

## 外部表状态

- status: `resolved`
- requested_table: `traffic_omni_oa.dim_item_pc2_rate_map__reg_live`
- canonical_table: `traffic_omni_oa.dim_item_pc2_rate_map__reg_live`
- resolution: `exact`
- source: `https://sradata.shopee.io/admin/api/datamap/table/info`
- business_docs: `pc2_metrics`

## 使用边界

- 这张表只在命中的业务文档显式声明时作为外部表使用。
- 字段、类型和分区过滤以本文件记录的 DataMap/DESCRIBE 元数据为准。
- 不要把这张表自动加入广告数仓主候选表集合；它只补充业务链路排查。

## 表说明

This table contains data related to pc2 rates for items, which are internally ingested from a Google sheet maintained by local teams. It is primarily used for mapping item categories to their respective pc2 rates as part of a business event.  The primary key is item_id . The update frequeny is Daily snapshot

## 分区和过滤

- inferred_partition_keys: `grass_date`, `grass_region`, `tz_type`
- required_filters: `grass_date`, `grass_region`, `tz_type`

## 字段列表

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `grass_date` | `date` | The `grass_date` column represents the date in local time zone. |
| `grass_region` | `string` | The `grass_region` column specifies the region where the traffic/order events happened. |
| `item_id` | `bigint` | The `item_id` column is a unique identifier assigned to each item in the inventory, used to distinguish between different products. |
| `level1_global_be_category` | `string` | The `level1_global_be_category` column contains the name of the Level 1 global backend category associated with the item. |
| `level1_global_be_category_id` | `bigint` | The `level1_global_be_category_id` column represents the identifier for the main global backend category of an item. |
| `level2_global_be_category` | `string` | The `level2_global_be_category` column represents the name of the Level 2 global backend category associated with an item. |
| `level2_global_be_category_id` | `bigint` | The `level2_global_be_category_id` column identifies the Level 2 global backend category ID of the item, providing a more detailed categorization within the broader Level 1 category. |
| `level3_global_be_category` | `string` | The `level3_global_be_category` column represents the name of the Level 3 global backend category associated with an item. |
| `level3_global_be_category_id` | `bigint` | The `level3_global_be_category_id` column represents the unique identifier for the third-level global backend category associated with an item. |
| `pc2_rate` | `double` | The `pc2_rate` column represents the estimated/assumed ratio between pc2 (level2 profit contribution) and gmv of an item. This field is essential for estimating order profit and loss. |
| `pc2_rate_exp` | `double` |  |
| `pc2_rate_exp_v1` | `double` | [NOT IN USE] item pc2 |
| `pc2_rate_exp_v2` | `double` |  |
| `tz_type` | `string` | The `tz_type` column specifies the type of time zone associated with the data partition, which is essential for ensuring accurate time-based data processing and analysis. |
