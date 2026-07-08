<!-- ads-workspace-gdoc-sync: gdoc_id=1pbo4AKStjcIyOdPwXDlduP_Qsu1hVV1hZr0VVeljIR8 gdoc_url=https://docs.google.com/document/d/1pbo4AKStjcIyOdPwXDlduP_Qsu1hVV1hZr0VVeljIR8/edit -->

# traffic.shopee_traffic_dws_abtest_hit_log_di__reg_live

## Description

- **Desc:** AB 实验命中日志表，记录每天每个 region 下哪些 user 被分配到了哪个 experiment 的哪个 group。由 Traffic 团队维护，供 Ads 等下游团队读取做实验分析。
- **Granularity:** daily (grass_date) x region (grass_region) x experiment_id x group_id x user_id
- **Use Case:**
  - 实验用户列表提取：根据 experiment_id 获取实验期间各 group 的 user_id 分布
  - AB 实验效果分析：与 ads performance 表 JOIN 计算分组的广告效果指标（impression, click, revenue, GMV）
  - 实验 assignment 补全：与 abtest.abtest_mart_dws_assignment_agg_1d UNION，填补部分用户未命中实验日志的空白
  - 实验缓存过滤：通过 exp_version 过滤未清除缓存的用户，减少数据偏差
- **Update Frequency:** Daily (inferred from _di suffix)

## Key Metrics

该表为命中级日志，不直接存储业务指标。下游分析时通过 user_id 与效果表 JOIN 后计算：
- 实验用户数：COUNT(DISTINCT user_id)
- 广告展示/点击/收入：SUM(ads_imp), SUM(ads_clicks), SUM(ads_rev_usd)
- 广告 GMV/订单：SUM(ads_gmv_usd), SUM(ads_order_cnt)

## Key Dimensions

- 分区: grass_date
- 实验标识: experiment_id, group_id, exp_version
- 地域: grass_region
- 用户标识: user_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL not found in paidads-alg codebase) |
| Partition Columns | grass_date (inferred from WHERE usage) |
| HDFS Path | - |
| Retention | - |
| Column Count | - (DDL not found; at least 6 columns seen in SQL) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR (common 8 regions used in all references) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 4 read files (0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
