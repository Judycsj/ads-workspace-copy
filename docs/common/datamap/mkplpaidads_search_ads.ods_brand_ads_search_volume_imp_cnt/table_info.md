<!-- ads-workspace-gdoc-sync: gdoc_id=1ZHc7J3uk9jVRzA5oXO1yQoqHxcGAJVD1_Pt9T4iYOlA gdoc_url=https://docs.google.com/document/d/1ZHc7J3uk9jVRzA5oXO1yQoqHxcGAJVD1_Pt9T4iYOlA/edit -->

# mkplpaidads_search_ads.ods_brand_ads_search_volume_imp_cnt

## Description

- **Desc:** ODS 表，存储每日各区域的 Search 搜索量（Search Volume Impression Count）。从原始 traffic 曝光日志 `traffic.shopee_traffic_dwd_impression_hi__reg_s1_live` 聚合生成，仅统计自然搜索结果页（relevancy 排序、无搜索过滤）的搜索曝光量，用于 Brand Ads 和 Traffic Boost 的流量建模与预算分配。
- **Granularity:** daily x grass_region
- **Use Case:**
  1. **Brand Ads 关键词级别曝光预测**: 作为训练数据源，提供历史 `imp_count` 训练预测模型
  2. **Traffic Boost 预算分配**: 计算 `env_t = forecast_imp / avg_imp` 作为环境归一化因子，用于出价/预算调整
  3. **Budget Function 权重计算**: 结合 forecast 数据计算各 ads_id 的权重参数 (w, k, sigma_squared)
  4. **Black Box 特征工程**: 为 ML 训练和推理准备流量特征数据
  5. **Subsidy Target 校准**: 计算区域平均曝光量用于奖励/补贴目标校准
  6. **Display Ads 曝光数据**: 作为 Display Ads 曝光量计算的上游数据源
- **Update Frequency:** Daily (T+1)

## Key Metrics

- **流量类**: `imp_count` — 每日每区域自然搜索曝光总量

## Key Dimensions

- **分区**: `grass_date` (日分区), `grass_region` (区域分区)
- **分析维度**: `grass_region` (8 个标准区域: ID, TH, PH, VN, TW, SG, MY, BR)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Hive Partitioned Table (Spark Dynamic Partition Overwrite) |
| Partition Columns | `grass_date` (string), `grass_region` (string) |
| HDFS Path | - |
| Retention | - |
| Column Count | 3 (1 data + 2 partition) |
| Region Coverage | 8 标准区域: ID, TH, PH, VN, TW, SG, MY, BR |
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

- Studio Tasks References: 126 files (2 write, 124 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
