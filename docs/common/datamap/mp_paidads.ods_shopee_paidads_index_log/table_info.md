<!-- ads-workspace-gdoc-sync: gdoc_id=10-8cg3ur0KAX47xIIJ6WaE2k481NpfR2F6BaFzxOlN0 gdoc_url=https://docs.google.com/document/d/10-8cg3ur0KAX47xIIJ6WaE2k481NpfR2F6BaFzxOlN0/edit -->

# mp_paidads.ods_shopee_paidads_index_log

## Description

- **Desc:** 广告索引日志原始表（ODS层），记录每次广告索引事件（INDEX/UPDATE/DELETE等）的完整快照信息。包含广告基本属性（ads_id, item_id, shop_id, campaign_id）、出价信息（bidding_price, pctr, ecr, cir）、定向过滤条件、商品特征、以及索引结果（reason, operation, visible）。是广告系统召回、全链路诊断、冷启动识别等下游任务的核心数据源。
- **Granularity:** per-index-event (ads_id x timestamp x grass_region x tz_type)
- **Use Case:**
  - 全链路诊断（Full Link Diagnosis）：关联召回漏斗和预算数据，分析广告各阶段通过率
  - 冷启动识别：通过 item_create_time 判断新品/老品，识别冷启动广告
  - 广告池统计：按 placement 统计有效广告数和店铺数
  - 召回评估（Recall Evaluation）：构造 ground truth 用于 i2i/u2i 召回效果评估
  - ROI 一致性校验：对比 index_log 中的 ROI 与 audit 表/dim_campaign 的一致性
  - 非活跃广告分析：找出未成功索引的广告并分析原因
  - 商品特征抽取：提取索引中的 item_id/shop_id 用于负采样或特征工程
- **Update Frequency:** Daily（上游数据接入）

## Key Metrics

- 索引量：`COUNT(*)` / `COUNT(DISTINCT ads_id)` — 活跃广告数量
- 广告池大小：`approx_distinct(ads_id)`, `approx_distinct(shop_id)` — 按 placement 统计
- 商品数：`COUNT(DISTINCT item_id)` — 在投商品数量

## Key Dimensions

- 分区: grass_date（日分区）, grass_region（地区）, tz_type（时区类型）
- 广告标识: ads_id, campaign_id, item_id, shop_id
- 出价类型: pricing_type（1=Manual, 2=Manual+eCPC, 11=Target ROI, 15=Simple ROI, 24/25=ROI变体, 27=GMS）
- 投放位: placement（0/1/2/5=Manual, 4/1000/1200=Search Manual, 40=ROI2, 50=Simple ROI2, 802/805/1002/1005/1202/1205=Discovery Ads）
- 操作类型: operation（INDEX/UPDATE/DELETE）
- 索引状态: reason（OK=成功索引）, visible（1=可见/有效）

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/ods_shopee_event_data__paidads_index_log_di__reg_s0_live |
| Retention | - |
| Column Count | 70+ |
| Region Coverage | 8 regions (ID, MY, PH, SG, TH, TW, VN, BR) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 474 files (77 workflow, 28 scheduled_tasks, remaining manual_tasks/playground)
- L7D Query Count: -
- Completeness: -
- Popularity: -
