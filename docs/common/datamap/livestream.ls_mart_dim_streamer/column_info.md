<!-- ads-workspace-gdoc-sync: gdoc_id=1ihK6Enb-tTS-JZV3F5SnD1Vm41_jhFbwm-VHv1OJ9qA gdoc_url=https://docs.google.com/document/d/1ihK6Enb-tTS-JZV3F5SnD1Vm41_jhFbwm-VHv1OJ9qA/edit -->

# Columns: livestream.ls_mart_dim_streamer

## Column Usage Notes

### 枚举值映射 (Value Mappings)

*从代码库 CASE-WHEN / IF 模式中提取，已在 2+ 个文件中重复出现*

| Column | Value | Meaning |
|--------|-------|---------|
| streamer_type | 2,3 | KOL (KOL_LT / KOL_ST) |
| streamer_type | 4 | Mall |
| streamer_type | 5 | Managed |
| streamer_type | 1,6,7,0 | Seller (individual / others) |
| streamer_type | 111 | MCN Portal (affiliate, streamer_id != shop_id) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 几乎 100% 查询使用 `'local'`
- `grass_region`: 标准 7 区 `('ID','VN','TH','MY','PH','TW','SG')`
- `grass_date`: 单日 (`= ${biz_date}`) 或 日期范围 (`BETWEEN ... AND ...`)
- `streamer_type > 0`: 排除未知类型的 streamer
- `streamer_id > 0`: 排除无效 streamer

### 特殊说明

- `streamer_shop_id` 在 JOIN 时通常别名为 `shop_id`，通过 `streamer_id` + `grass_region` + `grass_date` 关联
- 当 `target_affiliate_id > 0` 且 `account_id <> target_affiliate_id` 时，部分 SQL 会将 streamer_type 硬编码为 111 (MCN)，而非使用本表的原始值
- 本表为维度表，每个 streamer_id 在同一 (grass_date, grass_region) 下应唯一

## All Columns

*类型为从 SQL 使用模式推断，未获取 DDL。建议运行 --source from-di 补充准确的列类型和描述。*

| Column Name | Type (Inferred) | Description | L7/14/30D Query | MAX(column) |
|-------------|-----------------|-------------|-----------------|-------------|
| grass_date | string/date | 分区日期 (partition column) | - | - |
| grass_region | string | 国家/地区代码 | - | - |
| tz_type | string | 时区类型 (分区列)，固定 'local' | - | - |
| streamer_type | int | 主播类型: 0/1/6/7=Sellers, 2/3=KOL, 4=Mall, 5=Managed, 111=MCN | - | - |
| streamer_id | bigint | 主播唯一标识 | - | - |
| streamer_shop_id | bigint | 主播对应的店铺 ID (通常作为 shop_id 使用) | - | - |
