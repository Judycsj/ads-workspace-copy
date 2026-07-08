<!-- ads-workspace-gdoc-sync: gdoc_id=1d8oWFh1id5dFo4O_aHc5WLJZaNcDO368RmGdPpixwb0 gdoc_url=https://docs.google.com/document/d/1d8oWFh1id5dFo4O_aHc5WLJZaNcDO368RmGdPpixwb0/edit -->

# mkplpaidads_search_ads.productads_pass_rate_model_predictions_daily_v0

## Description

- **Desc:** Product Ads 出坡率模型每日预测结果表。存储 LightGBM Ranker 和 Classifier 模型对每条广告的预测分数（pass rate prediction），以及 SHAP 特征重要性、分类概率等模型解释信息。用于 Reserve 策略（NPB/冷启动）的 item 选择、模型效果评估 Dashboard、以及流量扶持出坡率分析。
- **Granularity:** daily x grass_region x model_type x ads_id (每行 = 一个 ads_id 在特定日期/地区/模型下的预测)
- **Use Case:**
  1. **Reserve 选品**: NPB 和冷启动策略根据 prediction 排名选择 Top-K items 加入 reserve
  2. **模型效果 Dashboard**: 按 prediction 分位数统计广告表现指标（展示/收入/订单 lift）
  3. **阈值标定**: 基于历史预测和实际订单计算 MAP@K 和 Recall，确定最优 k_cutoff 阈值
  4. **CSPU 分布分析**: 分析不同 prediction 分位段内 P0 CSPU 类型商品占比
  5. **流量扶持出坡率分析**: 用于 TW 出坡率分析，判定潜力品和 kernel 广告
  6. **核标数据生成**: 为 calibration 流程生成标定数据（预测 vs 7天实际订单）
- **Update Frequency:** Daily (through passrate_single_product_productads_data_1d_bidding workflow)

## Key Metrics

{Model prediction scores; not a metrics table itself, but feeds into downstream metrics}

- **prediction**: 模型预测分数（ranker 输出 ranking score，classifier 输出 pass probability）
- **cls_proba**: 分类器预测的获胜类别概率（仅 classifier 模型有值，ranker 恒为 0.0）
- **feature_shaps_map**: SHAP 特征重要性数组，按 shap_value 降序排列

## Key Dimensions

- 分区列: `grass_date`, `grass_region`, `model_type`
- 主键: `ads_id`, `shop_id`, `item_id`
- 分组: `rank_group_keys` (格式如 `{cate}-{subcate}-{keyword}` 或 `{pricing_type}-{model_indicator}`)
- 模型类型: `model_type` (`lightgbm_ranker_7d1o_v1`, `lightgbm_ranker_7d3o`, `lightgbm_classifier_7d3o_v2` 等)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET (SNAPPY compression) |
| Partition Columns | grass_date (DATE), grass_region (STRING), model_type (STRING) |
| HDFS Path | - |
| Retention | 21 days (partition dropped via `DROP IF EXISTS PARTITION (grass_date=date'${ISO_21DAY_AGO}')`) |
| Column Count | 10 |
| Region Coverage | ID, TH, MY, VN, PH, SG, TW, BR (Asian regions + Brazil) |
| DQC Status | - |
| Table Size | - |

## Business Properties

{未抓取 DataMap，请运行 --source from-di 补充}

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 47 files (1 write, 46 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
