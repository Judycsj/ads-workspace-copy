<!-- ads-workspace-gdoc-sync: gdoc_id=1nDDXbIr3GrtIu3OaNFAC46JxByH33TotPQmj0quLfGI gdoc_url=https://docs.google.com/document/d/1nDDXbIr3GrtIu3OaNFAC46JxByH33TotPQmj0quLfGI/edit -->

# mkplpaidads_search_ads.dws_training_data_with_cluster

## Description

- **Desc:** Traffic Boost (budget2x) 模型训练数据表，存储从 replay log 提取的广告效果指标，并附带了商户预算、商品类目等上下文信息。用于训练预算与订单/GMV 之间的饱和度曲线模型（exponential saturation, power law, hill, gompertz 等），是 budget2x 流量放大算法的核心输入表。
- **Granularity:** daily x campaign_id x coef x grass_region（每天每个地区每个广告系列在每个预算乘数下的效果数据）
- **Use Case:**
  - Budget2x 预算-订单/GMV 曲线拟合训练（t-30 至 t-1 作为训练窗口）
  - 曲线拟合效果评估（对比预测 vs replay log / 实际效果数据）
  - Budget2x 候选 campaign 覆盖度检查（LEFT JOIN 判断已建模/未建模）
  - Cluster 级别数据分布分析（按 shop_id x l2_cat_id 分组统计）
  - PCOC 校准因子计算（14 天历史数据窗口）
- **Update Frequency:** Daily（t-1 分区写入，由 `add_cluster` / `add_cluster_us` 工作流执行）

## Key Metrics

- 效果类: porder (predicted orders), pgmv (predicted GMV)
- 成本类: ecpm2 (eCPM cost)
- 预算类: seller_budget_local (商户本地币日预算), ecpm2_increase_factor (相对基线的 eCPM 放大系数)
- 派生指标: budget = ROUND(ecpm2_increase_factor, 8) * seller_budget_local

## Key Dimensions

- 分区: grass_date, grass_region
- 身份: ads_id, campaign_id, shop_id
- 类目: l1_cat_id, l2_cat_id
- 参数: coef (预算乘数，10000 为基线)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_date (date), grass_region (string) |
| HDFS Path | - |
| Retention | - |
| Column Count | 13 (11 data + 2 partition) |
| Region Coverage | ID, TH, PH, VN, TW, SG, MY, BR (8 区；add_cluster 写东南亚 7 区，add_cluster_us 写 BR) |
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

- Studio Tasks References: 42 files (2 write, 40 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
