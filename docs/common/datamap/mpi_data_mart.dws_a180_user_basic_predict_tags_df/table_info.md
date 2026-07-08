<!-- ads-workspace-gdoc-sync: gdoc_id=1YnzebNfnDp7K-6aAQaey1My5dxV7ykPx3TVdXO9s5gM gdoc_url=https://docs.google.com/document/d/1YnzebNfnDp7K-6aAQaey1My5dxV7ykPx3TVdXO9s5gM/edit -->

# mpi_data_mart.dws_a180_user_basic_predict_tags_df

## Description

- **Desc:** 用户基础预测标签表 — 存储用户人口统计学预测标签（年龄组、性别、收入水平、IP城市等），覆盖多区域用户。用于定向受众画像构建、受众标签生成、AB实验分析和展示广告用户标签。
- **Granularity:** daily x user_id x grass_region（每人每天一条记录的全量快照）
- **Use Case:**
  1. 受众用户画像构建 (dws_target_audience_user_profile) — 提取年龄、性别、活跃状态
  2. 受众定向标签生成 (ads_target_audience_tags) — 将预测标签转为bitmap编码的定向标签
  3. Discovery Ads 排序分析 — 用户标签维度的 CTR/AUC 分析
  4. AB 实验分析 — 按收入/性别维度分析广告效果
  5. 品牌/展示广告用户标签映射 — 用户画像标签与兴趣标签的融合
- **Update Frequency:** Daily（推测，所有下游任务均为日调度）

## Key Metrics

本表为标签表，不直接存储指标。下游使用的主要字段：

- **用户标识**: user_id
- **年龄标签**: predict_age_group (1=18-24, 2=25-34, 3/4=35+)
- **性别标签**: predict_gender ('Male', 'Female')
- **收入标签**: predict_income_level
- **城市标签**: predict_ip_city

## Key Dimensions

- 分区: grass_date, grass_region
- 业务维度: predict_age_group, predict_gender, predict_income_level, predict_ip_city

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date (date), grass_region (string) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, SG, MY, VN, TH, PH, TW, BR, CO, CL, MX |
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

- Studio Tasks References: 64 files (44 workflows, 15 playground, 3 manual_tasks, 2 discovery_ads)
- L7D Query Count: -
- Completeness: -
- Popularity: -
