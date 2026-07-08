<!-- ads-workspace-gdoc-sync: gdoc_id=1V1w8-Jau-xxwwmfoGXK1G4Oy-Xy5Z-NB-vIc5gcTiJY gdoc_url=https://docs.google.com/document/d/1V1w8-Jau-xxwwmfoGXK1G4Oy-Xy5Z-NB-vIc5gcTiJY/edit -->

# mp_paidads.ods_shopee_paidads_keyword_ad_search_log

## Description

- **Desc:** 搜索广告关键词广告请求日志表 (ODS层)。从 `ods_log_search_package_hi` ODS raw package 表中通过 LATERAL VIEW OUTER explode(ads) 展开，每一行代表一次搜索请求中单条广告的竞价和预估信息。是搜索广告系统的核心原始日志表，记录广告在召回、粗排、精排各阶段的信号。
- **Granularity:** request_id × ads_id × placement (request-ad level)
- **Use Case:**
  1. Search Ads DWD 生产: 与 `dwd_advertise_performance_di` (效果报表) JOIN 生成 `dwd_advertise_search_ads_performance_di`，回填搜索侧竞价、预估信息
  2. AB 实验分析: 通过 ab_sign 解析实验分组，计算 pCTR/pCR bias、hit rate、ranking 分析
  3. 出价与预算分析: bid2cost、ECPC、GMV boost 策略效果评估
  4. 广告召回分析: recall_source 分布、recall → rank 命中率分析
  5. Creative 分析: extra_json 中创意 ID 和算法版本追踪
  6. 模型训练数据: 离线提取训练样本 (pCTR/pCR/ECPM/recall score 等特征)
- **Update Frequency:** Daily (按天写入，每个 region 每小时从 SG raws 写入)

## Key Metrics

本表为日志级原始表，无预聚合指标。下游常用派生指标：

- **竞价类**: pctr, pcr, ecpm, bid_price, capped_price, deduction_price, ecr
- **召回类**: recall_rank, recall_score, recall_type, recall_source
- **排序类**: rank, ecpm, rele_score
- **身份类**: ads_id, item_id, user_id, request_id, session_id

## Key Dimensions

- **分区**: tz_type, grass_region, grass_date
- **业务**: placement, reason, recall_source, recall_source_name, match_type
- **用户/请求**: user_id, session_id, request_id, ab_sign
- **区域**: country (原始 country 字段), grass_region (分区)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/ods_shopee_event_data__paidads_keyword_ad_search_log_di__reg_s0_live |
| Retention | - |
| Column Count | 38 |
| Region Coverage | SG, ID, MY, PH, TH, TW, VN, BR, MX, CO, CL |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 397 files (1 write, 396 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
