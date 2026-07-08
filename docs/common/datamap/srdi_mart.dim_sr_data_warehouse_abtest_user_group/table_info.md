<!-- ads-workspace-gdoc-sync: gdoc_id=1HkgzoX5AkHkZ1yhv1FxJIMgvOoSBjSEsWYQbVR6dgxc gdoc_url=https://docs.google.com/document/d/1HkgzoX5AkHkZ1yhv1FxJIMgvOoSBjSEsWYQbVR6dgxc/edit -->

# srdi_mart.dim_sr_data_warehouse_abtest_user_group

## Description

- **Desc:** AB测试用户实验组分配维表，记录用户在各实验层中的实验组（group_id/bucket）映射关系。由上游 Data Warehouse (SRDI) 系统生产，供下游 AB Test 性能分析和报表使用。
- **Granularity:** user_id x local_date x grass_region（单用户同一天在某区域可能命中多个实验层/场景，因此实际使用中通常按 user_id, exp_group_id GROUP BY 或取 MAX(exp_group_id) 去重）
- **Use Case:**
  - Search/Discovery AB Test 性能指标聚合（曝光/点击/订单/GMV/收入/ADVV）
  - RCMD D&D/YMAL 实验组特征性能分析（按 common_feature 分桶）
  - ROI3 券策略实验指标评估（voucher cost、platform GMV、ads revenue）
  - Revenue PC2 rate 实验分组计算（estimate 收入指标）
  - 全量实验指标大盘（overall metrics）
- **Update Frequency:** Daily（由上游 Data Warehouse 每日更新）

## Key Metrics

本表为维表，本身不含指标。下游通过 JOIN 用户行为表后聚合得到 AB 实验指标：
- **收入类**: ads_revenue_usd, net_ads_rev_usd, paid_ads_revenue_usd_1d, expenditure_amt_usd
- **GMV类**: plt_gmv, ads_gmv_usd, broad_gmv_usd, omni_gmv_usd_1d
- **效果类**: ads_imp_cnt, ads_click_cnt, ads_order_cnt, ads_broad_order_cnt
- **券成本**: voucher_cost, roi3_voucher_usd
- **ADVV类**: broad_advv_cost, deepadvv, padvv

## Key Dimensions

- **分区列**: local_date (date 类型分区), grass_region
- **核心维度**: user_id, exp_group_id
- **过滤维度**: is_assignment_log, is_dim_join, is_search_whitelist, is_rcmd_whitelist, is_rcmd_service, is_ads_whitelist
- **实验元信息**: project_name, scene_id, layer_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - (上游表，未在代码库找到 DDL) |
| HDFS Path | - |
| Retention | - |
| Column Count | 15+ (按使用推断) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | AB Test / Experimentation |
| DW Layer | dim (Dimension) |

## Popularity

- Studio Tasks References: 190 files (0 write, 190 read)
- L7D Query Count: -
- Completeness: -
- Popularity: High — 覆盖 workflows/scheduled_tasks/manual_tasks 几乎所有 AB Test 场景
