<!-- ads-workspace-gdoc-sync: gdoc_id=1zAQj1_LuL6sIn5PGrj86KW-gWT8kCQmUsTrOpOLGLk4 gdoc_url=https://docs.google.com/document/d/1zAQj1_LuL6sIn5PGrj86KW-gWT8kCQmUsTrOpOLGLk4/edit -->

# mkplpaidads_brand_ads.search_brand_ads_impression_forecast

## Description

- **Desc:** Search Brand Ads 关键词展现实时预测数据，由 Data Intelligence 平台按日生成，提供按 region x forecast_date 粒度的总展现量预测。下游用于将大盘展现预测按关键词历史占比分配到 keyword/shop 级别，支撑 Search Brand Ads 的投放策略和流量预估。
- **Granularity:** daily x region x forecast_date（每条记录为一个 region 在未来某日期的展现量预测快照）
- **Use Case:**
  1. 关键词级展现预测 (Keyword-level Impression Forecast)：将 region 级预测按历史关键词占比分解到 keyword/shop 级别，用于 recall 场景（forecast horizon +730d）
  2. 关键词组日展现预测 (KW Group Daily Impression Forecast)：按 group_type 聚合，为 SBA bidding 策略提供每日预期展现量
  3. 流量 boost 饱和度计算：将预测展现与实际展现对比得到 env_t 乘数，驱动 traffic boost budget allocation
  4. 预测准确度评估 (Forecast Accuracy Evaluation)：对比预测展现 vs 实际展现，计算 WAPE，支持 1d/3d/7d 滚动窗口评估
- **Update Frequency:** Daily（每天产出当天的最新预测快照）

## Key Metrics

- 预测类: forecast_impression_count — region 级别每日展现量预测值

## Key Dimensions

- 分区: dt（预测生成日期，格式 yyyy-MM-dd）
- 地域: country_name = grass_region（8 个标准市场：ID, TH, PH, VN, TW, BR, SG, MY）
- 时间: forecast_date（被预测的目标日期）

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | dt (string, format 'yyyy-MM-dd') |
| HDFS Path | - |
| Retention | - |
| Column Count | 4 (country_name, dt, forecast_date, forecast_impression_count) |
| Region Coverage | ID, TH, PH, VN, TW, BR, SG, MY (8 markets) |
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

- Studio Tasks References: 38 files (4 workflows, 34 manual_tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
