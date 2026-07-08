<!-- ads-workspace-gdoc-sync: gdoc_id=1o5suQ-H_qMHvW2UKzPuNWla509uTsT7NhX-UOax3BbI gdoc_url=https://docs.google.com/document/d/1o5suQ-H_qMHvW2UKzPuNWla509uTsT7NhX-UOax3BbI/edit -->

# Columns: mp_paidads.ads_category_performance_1d__reg_s0_live

## Column Usage Notes

### 品类维度说明 (Category Dimension Pattern)

每行数据只有**一个品类维度非空**，其他品类列的 ID 和 name 均为 NULL。数据由 3 个品类体系 x 3 个层级 = 9 种组合 UNION ALL 而成：

- **Global BE Category**: L1/L2/L3 (如 `level1_global_be_category_id > 0` 表示该行是 Global BE 一级品类)
- **FE Display Category**: L1/L2/L3 (从前端展示分类展开)
- **KPI Category**: L1/L2/L3 (从 KPI 分类展开)

查询特定品类时需同时指定 ID 和过滤 NULL，如:
```sql
WHERE level1_global_be_category_id IS NOT NULL
WHERE level1_global_be_category_id > 0
WHERE level3_kpi_category_id IS NOT NULL
```

### 非累加字段 (Non-Additive Fields)

暂无（所有指标均为 SUM 聚合，可跨维度累加）。注意跨 tz_type 聚合时需确认业务需求。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | regional | Standard timezone (多时区) |
| tz_type | local | Local timezone (Campaign Surge 场景必须用) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (Campaign Surge 场景必须用, ~90% 下游查询) / 'regional'
- `level3_global_be_category_id > 0`: 过滤有效的三级品类 (Campaign Surge)
- `grass_region`: 标准 11 区 ('SG','MY','PH','ID','TH','TW','VN','MX','BR','MX_local','BR_local')
- `grass_date`: 精确日期过滤，常用于 `= DATE('${BIZ_YESTERDAY}')`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| level1_global_be_category_id | bigint | Global BE 一级品类ID | - | - |
| level1_global_be_category | string | Global BE 一级品类名 | - | - |
| level2_global_be_category_id | bigint | Global BE 二级品类ID | - | - |
| level2_global_be_category | string | Global BE 二级品类名 | - | - |
| level3_global_be_category_id | bigint | Global BE 三级品类ID (Campaign Surge 核心维度) | - | - |
| level3_global_be_category | string | Global BE 三级品类名 | - | - |
| level1_fe_display_category_id | bigint | FE Display 一级品类ID | - | - |
| level1_fe_display_category | string | FE Display 一级品类名 | - | - |
| level2_fe_display_category_id | bigint | FE Display 二级品类ID | - | - |
| level2_fe_display_category | string | FE Display 二级品类名 | - | - |
| level3_fe_display_category_id | bigint | FE Display 三级品类ID | - | - |
| level3_fe_display_category | string | FE Display 三级品类名 | - | - |
| level1_kpi_category_id | bigint | KPI 一级品类ID | - | - |
| level1_kpi_category | string | KPI 一级品类名 | - | - |
| level2_kpi_category_id | bigint | KPI 二级品类ID | - | - |
| level2_kpi_category | string | KPI 二级品类名 | - | - |
| level3_kpi_category_id | bigint | KPI 三级品类ID | - | - |
| level3_kpi_category | string | KPI 三级品类名 | - | - |
| category_ads_expenditure_amt_1d | double | 品类广告消耗(本币) | - | - |
| category_ads_expenditure_amt_usd_1d | double | 品类广告消耗(USD) | - | - |
| category_ads_click_cnt_1d | bigint | 品类广告点击数 | - | - |
| category_ads_impression_cnt_1d | bigint | 品类广告曝光数 | - | - |
| category_ads_order_cnt_1d | bigint | 品类广告订单数(归因) | - | - |
| category_ads_broad_order_cnt_1d | bigint | 品类广告订单数(广义) | - | - |
| category_ads_gmv_amt_1d | double | 品类广告GMV(本币) | - | - |
| category_ads_gmv_amt_usd_1d | double | 品类广告GMV(USD) | - | - |
| category_ads_broad_gmv_amt_1d | double | 品类广告广义GMV(本币, Campaign Surge 核心指标) | - | - |
| category_ads_broad_gmv_amt_usd_1d | double | 品类广告广义GMV(USD) | - | - |
| tz_type | string | 时区类型 [PARTITION] | - | - |
| grass_region | string | 地区 [PARTITION] | - | - |
| grass_date | date | 数据日期 [PARTITION] | - | - |
