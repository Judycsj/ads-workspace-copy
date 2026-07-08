<!-- ads-workspace-gdoc-sync: gdoc_id=1SQhxMX9Hpb68ID4LGQnE1eMqtAN7AghLR98sqcqQ8eA gdoc_url=https://docs.google.com/document/d/1SQhxMX9Hpb68ID4LGQnE1eMqtAN7AghLR98sqcqQ8eA/edit -->

# regbida_keyreports.dim_vat_rate

## Description

- **Desc:** VAT税率维表，由 regbida_keyreports 团队维护。存储不同地区(grass_region)、不同收入类型(metric_type)按日期(grass_date)的增值税率。在广告收入计算中用于将含税收入还原为税前收入。
- **Granularity:** daily x grass_region x metric_type (每日 × 地区 × 收入类型)
- **Use Case:**
  - 广告净收入计算：在 `dws_advertise_net_ads_revenue_1d` 等生产任务中，通过 JOIN 获取对应日期的 VAT 税率，将含税金额还原为税前净收入
  - 直播广告效果分析：在 `dwd_livestream_performance_di` 和 `dwd_advertise_livestream_ads_performance_di` 中获取税率用于收入计算
  - Take Rate 计算：在 playground 中的 take_rate 测试任务中用于税率换算
  - 广告主/订单级净收入：deprecated 的 `dws_advertiser_net_ads_revenue_1d` 和 `dws_advertise_order_net_revenue_1d` 中也使用该表
- **Update Frequency:** Daily (推测，由 regbida_keyreports 团队维护)

## Key Metrics

- **vat_rate**: VAT 税率值，核心指标，不同 metric_type 对应不同税率
  - `cb_paid_ads_revenue`: 跨境付费广告收入 VAT 税率
  - `local_paid_ads_revenue`: 本地付费广告收入 VAT 税率
  - `cb_free_ads_revenue`: 跨境免费广告收入 VAT 税率
  - `local_free_ads_revenue`: 本地免费广告收入 VAT 税率

## Key Dimensions

- 分区: grass_date, grass_region
- 业务: metric_type (收入类型，决定使用哪个税率)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (未在 paidads-alg 代码库中找到 DDL) |
| Partition Columns | grass_date, grass_region (从 SQL 使用模式推断) |
| HDFS Path | - |
| Retention | - |
| Column Count | - (未在 paidads-alg 代码库中找到 DDL) |
| Region Coverage | Multi-region (SG/PH/MY/TW/TH/VN/ID/BR/MX/AR/CO/CL) |
| DQC Status | - |
| Table Size | - |

## Business Properties

> 未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 52 files (0 write, 52 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
