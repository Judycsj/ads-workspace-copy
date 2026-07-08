<!-- ads-workspace-gdoc-sync: gdoc_id=196L1v1Zn4gf_h5cX2An2_xXBHH8TyDpg0sIaIwduwsE gdoc_url=https://docs.google.com/document/d/196L1v1Zn4gf_h5cX2An2_xXBHH8TyDpg0sIaIwduwsE/edit -->

# mp_paidads.dws_campaign_deduction_budget_1d__reg_s0_live

## Description

- **Desc:** 广告 Campaign 每日预算消耗与撞线状态表。记录每个 campaign 的总预算配额、累计消耗、每日预算配额和每日消耗，并基于配额与消耗的差值计算总预算撞线和日预算撞线状态。数据按 region 维度合成到全局分区表。
- **Granularity:** daily x campaign_id x tz_type x grass_region
- **Use Case:**
  - OKR 商家全量指标报表 — 计算每个 shop 下撞线 campaign 数、有限/无限预算 campaign 数、预算利用率
  - 预算利用率分析 — 按日预算分桶统计 campaign 的撞线率和预算利用率
  - 广告主 EDA 分析 — 计算 campaign 剩余预算（daily_quota_local - daily_deduction）、撞线统计
  - 搜索广告 uplift 分析 — 统计每月撞预算的 campaign 数量，按 shop 聚合
- **Update Frequency:** Daily

## Key Metrics

- 预算配额: total_quota_local (总预算), daily_quota_local (日预算)
- 消耗: total_deduction (累计消耗), daily_deduction (日消耗)
- 撞线状态: hit_total_budget (总预算撞线), hit_daily_budget (日预算撞线)
- 派生指标:
  - budget_util = SUM(daily_deduction) / SUM(daily_quota_local) (预算利用率)
  - budget_hit_rate = SUM(hit_daily_budget) / COUNT(DISTINCT campaign_id) (撞线率)
  - remain = daily_quota_local - daily_deduction (剩余预算)

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 业务: campaign_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string), grass_region (string), grass_date (DATE) |
| HDFS Path | ${path} (region-split sub-tables at ${path}/tz_type=local/grass_region=${upper_region}) |
| Retention | - |
| Column Count | 7 |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 59 files (13 write, 46 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
