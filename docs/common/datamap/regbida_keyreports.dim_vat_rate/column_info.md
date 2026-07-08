<!-- ads-workspace-gdoc-sync: gdoc_id=1Ru0oD48eMB8RPFMyzN8zooxEpd1JCj9Fi6bvTFuWDhs gdoc_url=https://docs.google.com/document/d/1Ru0oD48eMB8RPFMyzN8zooxEpd1JCj9Fi6bvTFuWDhs/edit -->

# Columns: regbida_keyreports.dim_vat_rate

## Column Usage Notes

### 枚举值映射 (Value Mappings)

从代码库中 CASE-WHEN 模式提取的 metric_type 枚举映射：

| Column | Value | Meaning |
|--------|-------|---------|
| metric_type | cb_paid_ads_revenue | 跨境付费广告收入 VAT 税率 |
| metric_type | local_paid_ads_revenue | 本地付费广告收入 VAT 税率 |
| metric_type | cb_free_ads_revenue | 跨境免费广告收入 VAT 税率 |
| metric_type | local_free_ads_revenue | 本地免费广告收入 VAT 税率 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: `upper('${region}')` / `upper('${grass_region}')` (所有查询都按 region 过滤)
- `metric_type`: `('cb_paid_ads_revenue', 'local_paid_ads_revenue')` (~90% 查询) / `('cb_paid_ads_revenue', 'local_paid_ads_revenue', 'local_free_ads_revenue', 'cb_free_ads_revenue')` (~10% 查询，仅 net_ads_revenue)
- `grass_date`:
  - 直接匹配模式: `= '${grass_date}'` (~70% 查询)
  - 最大分区模式: `in (select max(grass_date) from regbida_keyreports.dim_vat_rate where grass_region = upper('${region}'))` (~30% 查询，livestream 及 playground)

## All Columns

> 以下列名从代码库 SQL 使用模式推断，未从 DDL 或 DataMap 获取。运行 `--source from-di` 可补充完整列清单、描述、查询频率和 MAX 采样。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | string | 分区日期，税率生效日期 | - | - |
| grass_region | string | 地区，如 ID/MY/PH/SG/TH/TW/VN/BR 等 | - | - |
| metric_type | string | 收入类型，决定税率类别 | - | - |
| vat_rate | double/decimal | VAT 税率值 (如 0.1 表示 10%) | - | - |

> 注意：此表可能还有更多列，以上仅根据 paidads-alg 代码库中的 SQL 使用模式推断。运行 `--source from-di` 可补充完整列信息。
