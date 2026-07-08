<!-- ads-workspace-gdoc-sync: gdoc_id=1nbz6yVx5C7mKTuizNt9HAnlQcc4EN4DBoovbpEPA3Zw gdoc_url=https://docs.google.com/document/d/1nbz6yVx5C7mKTuizNt9HAnlQcc4EN4DBoovbpEPA3Zw/edit -->

# mp_paidads.dwd_log_translog_unsuccessful_event_deduction_di__reg_s0_live

## Description

- **Desc:** 存储 translog 扣费不成功事件明细。记录 CPC/CPM 计费模式下扣费失败或部分调整的事件，包含预期扣费金额（price）和实际调整后成本（adjusted_cost），金额以本地货币分为单位。
- **Granularity:** daily x event (每条记录为一个扣费失败事件，包含 campaign/user/placement/entrance 维度)
- **Use Case:**
  1. Search Ads 扣费失败 AB 实验分析 — 按实验分桶对比 CPC/CPM 扣费失败金额和失败率
  2. CPC 未成功扣费收入归因 — 作为 metric_source UNION ALL 的一支，提供 unsuccessful deduction 视角的预期/实际收入
  3. 扣费失败率监控 — 结合广告效果数据计算 fail_rate = deduct_fail / (deduct_fail + ads_rev)
- **Update Frequency:** Daily

## Key Metrics

- 扣费失败次数: deduct_fail_cpc_cnt, deduct_fail_cpm_cnt (按 deduct_type 条件计数)
- 扣费失败金额: deduct_fail_cpc_amt_usd, deduct_fail_cpm_amt_usd = SUM(IF(deduct_type, (price - adjusted_cost) / 100000.0 / exchange_rate, 0))
- 单行核心字段: price (预期扣费, 分), adjusted_cost (实际调整成本, 分), status (扣费状态)
- campaign_balance_by_date (struct): 包含 daily_balance (当日余额)
- daily_quota: 当日预算配额

## Key Dimensions

- 分区: grass_date, grass_region
- 业务: pricing_type, deduct_type, user_id, campaign_id, shop_id, entrance, placement

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | - |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 2 files (manual_tasks/debug, read-only)
- L7D Query Count: -
- Completeness: -
- Popularity: -
