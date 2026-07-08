<!-- ads-workspace-gdoc-sync: gdoc_id=17ybbZ208qWNZC9UBbQ6qlMG_IujFaPGOZrI2SQUy_vA gdoc_url=https://docs.google.com/document/d/17ybbZ208qWNZC9UBbQ6qlMG_IujFaPGOZrI2SQUy_vA/edit -->

# mp_paidads.dim_deduction_cost_cap__reg_s0_live

## Description

- **Desc:** 扣费成本上限维度表（Cost Cap Dimension）。存储按 region x pricing_type x placement 维度的单次扣费金额上限（cost_cap_max），通过 date_type 区分 campaign_day（广告计划日，每月15/25/月末）和 normal_day（普通日），用于扣费流程中识别 cost cap 导致的 partial deduction 场景。
- **Granularity:** region x pricing_type x placement x date_type
- **Use Case:**
  - 扣费流水构建 — dwd_click_deduction_di / dwd_ads_deduction_loss_event_di 中识别 cost_cap_click/cost_cap_impression（扣费金额达到 cap 上限的点击/展示）
  - temp_click_deduction_di 临时扣费表 — 同上用途
- **Update Frequency:** 未在代码库找到生产逻辑（推测外部系统维护）

## Key Metrics

- cost_cap_max — 单次扣费金额上限（本地货币 x 10^5）

## Key Dimensions

- 分区: grass_region
- 业务: pricing_type, placement, date_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | 5 (from usage inference: grass_region, pricing_type, placement, date_type, cost_cap_max) |
| Region Coverage | 8 regions (ID, MY, PH, SG, TH, TW, VN, BR) |
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

- Studio Tasks References: 47 files (5 workflows)
- L7D Query Count: -
- Completeness: -
- Popularity: -
