<!-- ads-workspace-gdoc-sync: gdoc_id=1I-_pbj6esFTsUACQSXandVJns9l5DKg-Gsg4jVjAcEY gdoc_url=https://docs.google.com/document/d/1I-_pbj6esFTsUACQSXandVJns9l5DKg-Gsg4jVjAcEY/edit -->

# mp_foa.dwd_eventid_impress_di__reg_s0_live

## Description

- **Desc:** FOA (Feed/Organic Ads) BI 追踪曝光事件明细表。记录用户在 Shopee 各流量入口（Search, Discovery, Recommendation 等）的商品级曝光行为。`_di` 后缀表示日增量 (daily incremental) 数据。该表是 ads organic 分析和广告密度计算的核心 DWD 层基础表。
- **Granularity:** event_id x item_id x user_id x grass_date（事件级 x 日分区）
- **Use Case:**
  - **Keyword Fill Rate 计算**：搜索关键词级别的广告填充率（ads_imp_in_adslot / ads_slot_imp），用于评估搜索广告密度
  - **Search Volume 分析**：关键词搜索量统计和广告渗透率（req_w_ads / total reqs）
  - **Discovery Ads 曝光分析**：推荐流量（Daily Discover, You May Also Like, Similar Products）的 organic vs ads 曝光占比
  - **Organic Item Performance**：商品维度的 organic 曝光量，用于 DWS 层的商品指标宽表（dws_item_1d）
  - **预算推荐 (Budget Rcmd)**：基于曝光量的 item-level 特征工程，生成 rcmd_v2_imp 表
  - **Traffic Group / AB 实验分析**：按 traffic_type + placement + AB test 分组的曝光、PDP PV、下单等指标（ads_advertise_params）
  - **User-Level OPM 分析**：用户粒度 OPM (Orders Per Mille)，用于 campaign surge 分析
  - **Entry Point 分布分析**：各流量入口的曝光分布、商品价格分布等
- **Update Frequency:** Daily (from FOA tracking pipeline)

## Key Metrics

- 曝光类: `impress_cnt_direct_lead` (直接引导曝光量 -- 核心指标), `impress_cnt_complete_lead` (完整链路曝光量 -- 多步跳转场景)
- 衍生: `ads_imp` (广告曝光, 从 JSON is_ads flag 析出), `ads_slot_imp` (广告位总曝光), `search_volume` (COUNT DISTINCT request_id)

## Key Dimensions

- 分区: `grass_date` (DATE), `grass_region` (STRING), `tz_type` (STRING)
- 流量来源: `step1_feature_group` (入口特征组), `step1_feature_detail` (入口详情), `step1_feature` (基础特征), `step2_feature_group` (第二步特征组 -- 多步场景), `step_count` (跳转步数)
- 用户/商品: `user_id`, `item_id`, `target_type` (几乎总是 'item')
- 平台: `platform` (ios_app/android_app), `page_type` (search/product/home/fruit_store), `page_section` (you_may_also_like/daily_discover)
- 广告标识: `is_ads` (从 step1_data_property JSON 提取), `ab_test` (AB 实验签名)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL 未在 paidads-alg 代码库中找到，该表由 FOA 团队生产) |
| Partition Columns | grass_date (DATE), grass_region (STRING), tz_type (STRING) -- 从 WHERE 子句推断 |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | 全区域 (ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL 等) |
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

- Studio Tasks References: 79 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
