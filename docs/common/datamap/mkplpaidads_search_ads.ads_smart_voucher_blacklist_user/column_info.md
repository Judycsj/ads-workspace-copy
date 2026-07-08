<!-- ads-workspace-gdoc-sync: gdoc_id=1PNP9hpZVHCZCXTNIfuNwH73t4wgYOSZML7X70Lz-GbQ gdoc_url=https://docs.google.com/document/d/1PNP9hpZVHCZCXTNIfuNwH73t4wgYOSZML7X70Lz-GbQ/edit -->

# Columns: mkplpaidads_search_ads.ads_smart_voucher_blacklist_user

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- 本表为维度表（用户-分群映射），无聚合指标字段
- `user_id` 在聚合查询中必须使用 `COUNT(DISTINCT user_id)` 去重计数

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| group_name | control | 对照组用户（不投放 Smart Voucher 广告） |
| group_name | mp_plus_ads | 实验组用户（投放 MP + Ads） |

**上游各区域原始标签到标准分组的映射**：

| Region | 原始来源标签 | 映射到 group_name |
|--------|------------|-------------------|
| BR | `Global Control` | control |
| BR | `ABT Group` | mp_plus_ads |
| ID | `Combo_Control`, `Combo_Local` | control |
| ID | `Combo_MP`, `Combo_Ads`, `Combo_Reg` | mp_plus_ads |
| SG | `Global Control`, `Local Sandbox` | control |
| SG | `Smart ABT Group` | mp_plus_ads |
| TH | `Control`, `TH Sandbox` | control |
| TH | `Reg Traffic`, `Reg - MP Traffic`, `Reg - Ads Traffic` | mp_plus_ads |
| VN | `Is_Target:false,Treatment_Group:C`, `Is_Target:false,Treatment_Group:A` | control |
| VN | `Is_Target:true,Treatment_Group:B` | mp_plus_ads |
| MY | `TG1`, `CG` | control |
| MY | `TG2` | mp_plus_ads |
| PH | `Manual MDV`, `Smart MDV` | control |
| PH | 其他 | mp_plus_ads |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 7个区域 'BR','ID','MY','PH','SG','TH','VN'
- `group_name`: 'control' (对照组) / 'mp_plus_ads' (实验组)
- `grass_date`: 通常范围过滤，如 `grass_date >= date '2026-06-01' and grass_date <= date '2026-06-30'`
- 分区监控检查 T/T+1/T+2/T+3 分区数据是否存在

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | 用户 ID（非累加，聚合用 COUNT DISTINCT） | - | - |
| group_name | string | 用户实验分组：control / mp_plus_ads | - | - |

### Partition Columns

| Column Name | Type | Description |
|-------------|------|-------------|
| grass_date | DATE | 数据日期分区 |
| grass_region | STRING | 区域分区：BR, ID, MY, PH, SG, TH, VN |
