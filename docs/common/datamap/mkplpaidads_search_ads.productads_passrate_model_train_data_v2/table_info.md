<!-- ads-workspace-gdoc-sync: gdoc_id=1WmiT-3UceK1V6Vd2f09wnvL9C24BwVbXJuH97uc4wTI gdoc_url=https://docs.google.com/document/d/1WmiT-3UceK1V6Vd2f09wnvL9C24BwVbXJuH97uc4wTI/edit -->

# mkplpaidads_search_ads.productads_passrate_model_train_data_v2

## Description

- **Desc:** Product Ads 通过率模型训练数据表。包含每个广告-商品对（ads_id x item_id）的多维度特征（商品特征、平台后验特征、广告后验特征、出价特征、预估特征）和未来 7 天直接订单数标签（order_7d_cnt），用于训练 LightGBM Ranker（Lambdarank）和 Classifier（Binary）模型，预测广告获得订单的可能性。
- **Granularity:** daily x region x ads_id x item_id
- **Use Case:**
  - 训练 LightGBM Ranker 模型（7d1o / 7d3o label），预测广告排名
  - 训练 LightGBM Classifier 分类模型（7d1o / 7d3o label）
  - 超参数网格搜索交叉验证（classifier_cv）
  - 多实验并行训练与评估（ranker_cs）
- **Update Frequency:** Daily（8 天滞后期：第 T 天训练用 T-8 天的特征数据 + T-1 到 T-7 天的订单 label）

## Key Metrics

- **Label 指标**: order_7d_cnt — 接下来 7 天直接订单数（核心 label）
- **商品后验 (Platform)**: platform_impression/click/atc/order_cnt (7d/14d/30d), platform_ctr/cr/atc_cr/ctcvr (7d/14d/30d)
- **广告后验 (Ads)**: ads_total_impression/click/atc/order_cnt (7d/14d/30d), ads_ctr/atc_cr/cr/ctcvr (7d/14d/30d)
- **出价特征**: campaign_daily_quota_usd, price_usd, target_roi, cpa（及其 l1/l1_l2 百分位）
- **预估特征**: avg_pctr/pcr/pctcvr (7d/14d), ads_total_p_ctcvr_7d
- **商品描述**: discount, free_shipping, stock, creation_elapsed_duration, cspu_type, is_p0_cspu_type

## Key Dimensions

- **分区**: grass_date, grass_region
- **标识**: ads_id, shop_id, item_id, campaign_id
- **分类**: pricing_type, item_type, l1_cat, l2_cat, cspu_type
- **筛选维度**:
  - `item_type`: "npb"（普通商品，7d1o 模型）/ "cold_start", "empty_order_expand"（冷启/无订单扩展，7d3o 模型）
  - `grass_region`: 'ID','TH','MY','VN','PH','SG','TW'（亚洲 7 区）+ 'BR'（巴西）

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_date, grass_region |
| HDFS Path | - |
| Retention | 保留 21 天分区（DROP PARTITION grass_date < 21 days ago） |
| Column Count | 85 |
| Region Coverage | ID, TH, MY, VN, PH, SG, TW, BR |
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

- Studio Tasks References: 9 files (2 write, 7 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
