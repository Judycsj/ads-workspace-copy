<!-- ads-workspace-gdoc-sync: gdoc_id=1Mw2wf1PmTioqhpG65HSo4YVZIsrA6yz7f98smx588wU gdoc_url=https://docs.google.com/document/d/1Mw2wf1PmTioqhpG65HSo4YVZIsrA6yz7f98smx588wU/edit -->

# Columns: mp_paidads.dim_roi2_auto_rebate_blacklist__reg_s0_live

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 所有查询均通过 `upper('${region}')` 按地区过滤，覆盖 11 个地区（VN/TW/TH/SG/PH/MY/MX/ID/CO/CL/BR）
- `grass_date`: 日报场景用 `= DATE('${grass_date}')`，周报场景用 `BETWEEN DATE('${start_date}') AND DATE('${grass_date}')`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | BIGINT | Shop ID，店铺唯一标识 | - | - |
| blacklist_date | DATE | 黑名单日期，来自 `dim_seller_tag_entity` 的 create_datetime | - | - |
| grass_region | STRING | 地区分区 (PARTITION) | - | - |
| grass_date | DATE | 日期分区 (PARTITION) | - | - |
