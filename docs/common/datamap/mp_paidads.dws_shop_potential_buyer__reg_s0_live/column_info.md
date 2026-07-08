<!-- ads-workspace-gdoc-sync: gdoc_id=1dxUdcQ15eFIErhLR1Fw1_zPlZjbsFRlzR-I79ED5uy0 gdoc_url=https://docs.google.com/document/d/1dxUdcQ15eFIErhLR1Fw1_zPlZjbsFRlzR-I79ED5uy0/edit -->

# Columns: mp_paidads.dws_shop_potential_buyer__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| potential_buyer_type | 3 | Highest: viewshop_30>=2 OR viewpdp_30>=3 OR atc_14>=1 |
| potential_buyer_type | 2 | High: viewshop_30>=2 OR viewpdp_30>=2 OR atc_14>=1 |
| potential_buyer_type | 1 | Medium: viewshop_30>=1 OR viewpdp_30>=1 OR atc_14>=1 |
| potential_buyer_type | 0 | Low/None: 不满足以上任一条件 |

### 常见 WHERE 值 (Common Filter Values)

- `potential_buyer_type`: >=2 (所有下游消费者均只取高意向用户)
- `grass_region`: 标准12区 ('VN','TW','TH','SG','PH','MY','MX','ID','CO','CL','BR' 等)
- `grass_date`: 通常取 `date'${yesterday}'`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | 买家用户ID | - | - |
| shop_id | bigint | 店铺ID | - | - |
| potential_buyer_type | int | 潜在购买意向分级 (0-3), 3为最高 | - | - |
| grass_region | string | 分区: 地区 (如 SG, MY, BR) | - | - |
| grass_date | DATE | 分区: 数据日期 | - | - |
