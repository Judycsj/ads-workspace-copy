<!-- ads-workspace-gdoc-sync: gdoc_id=12B4Ao5Z2--ZD4SPto3oBmdWFF8_jhBIFYo-ib25vp2c gdoc_url=https://docs.google.com/document/d/12B4Ao5Z2--ZD4SPto3oBmdWFF8_jhBIFYo-ib25vp2c/edit -->

# mp_paidads.ads_category_performance_1d__reg_s0_live

## Description

- **Desc:** 按三级品类体系（Global BE / FE Display / KPI）汇总广告效果指标。从 `ads_advertise_mkt_1d` 通过 LATERAL VIEW OUTER EXPLODE 展开品类数组列，将单一广告行的多品类标签打散为每品类一行，再按品类聚合指标。
- **Granularity:** daily x tz_type x grass_region x (one category level per row across 3 hierarchies x 3 levels = 9 permutations)
- **Use Case:**
  - Campaign Surge 大促日品类放大系数计算 (campaign_boost_for_l3cat)
  - Seller Center ROI2 Campaign 出价建议 (suggest_roi_daily)
  - Seller Center ROI2 Campaign 预算建议 (budget_rcmd_daily)
  - 品类级别广告数据校验 (table data check)
- **Update Frequency:** Daily (每 region 独立 workflow, 变量调度: `grass_date`, `region`)

## Key Metrics

- 消耗类: category_ads_expenditure_amt_1d, category_ads_expenditure_amt_usd_1d
- 效果类: category_ads_click_cnt_1d, category_ads_impression_cnt_1d
- 订单类: category_ads_order_cnt_1d, category_ads_broad_order_cnt_1d
- GMV类: category_ads_gmv_amt_1d, category_ads_gmv_amt_usd_1d, category_ads_broad_gmv_amt_1d, category_ads_broad_gmv_amt_usd_1d

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 品类: 三级品类体系 (Global BE / FE Display / KPI) x 三级层级 (L1/L2/L3)，每行只有一个品类维度非空
  - level1~3_global_be_category_id/name
  - level1~3_fe_display_category_id/name
  - level1~3_kpi_category_id/name

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | `${HIVE_PATH}/ads_category_performance_1d__reg_s0_live/` |
| Retention | - |
| Column Count | 31 |
| Region Coverage | VN, TW, TH, SG, PH, MY, MX, ID, BR (含 MX_local, BR_local) |
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

- Studio Tasks References: 28 files (11 write, 17 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
