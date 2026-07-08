<!-- ads-workspace-gdoc-sync: gdoc_id=1wa4ChbWuizjf0b-nkJPv0lwXX7NPjpBpoGa4t3XKt-o gdoc_url=https://docs.google.com/document/d/1wa4ChbWuizjf0b-nkJPv0lwXX7NPjpBpoGa4t3XKt-o/edit -->

# mp_paidads.ods_log_trace_shop_ads_hi__reg_s0_live

## Description

- **Desc:** Shop Ads 搜索广告的在线请求 Trace 日志 ODS 表。记录每次搜索广告请求的完整链路信息，包括请求上下文、召回广告列表（ads array）、AB 实验签名等。是 Shop Ads 算法分析的核心基础表，用于分析广告召回、排序、定价、CTR/CVR 预估等在线链路行为。
- **Granularity:** hourly x request_id (每条记录对应一次搜索广告请求，按 grass_region + grass_date + h 分区)
- **Use Case:**
  - Shop Ads AB 实验效果分析（出价分布、CTR/CVR、Target ROI 达成率）
  - I2I 召回覆盖率统计与 CTR 修正分析
  - 冷启动卖家识别（pid_status=2 为冷启动状态）
  - 潜在曝光增量分析（按 reason 分类统计 picked/unpicked 广告）
  - 出价改写与价格分布分析（bid_price、deduction_price、init_bid_price）
  - 广告排序状态分析（score、rank、reason）
- **Update Frequency:** Hourly（从 SG IDC 每小时同步到统一分区表）

## Key Metrics

*trace log 为事件日志表，主要指标为计数类：*

- 请求量: COUNT(DISTINCT request_id)
- 召回广告数: COUNT(*) after LATERAL VIEW EXPLODE(ads)
- Picked 广告量: COUNT(*) WHERE reason in (1)
- I2I 召回请求数: COUNT(*) WHERE has_i2i = 1
- 出价指标: AVG(bid_price), AVG(deduction_price), APPROX_PERCENTILE(bid_price, ...)
- 预估指标 (from ext_info JSON): AVG(pctr), AVG(pcr), AVG(target_roi)
- 冷启动店铺数: COUNT(DISTINCT shop_id) WHERE pid_status = 2

## Key Dimensions

- 分区: grass_region, grass_date, h
- 请求级: request_id, session_id, user_id, platform
- 广告级 (ads struct): placement, reason, match_type, rank, recall_queue
- AB 分组: ab_sign (原始签名), bucket_id (from ext_info JSON, AB bucket ID)
- 搜索上下文: query, proc_query

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (mergeSchema enabled) |
| Partition Columns | grass_region (string), grass_date (date), h (int) |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/ods_log_shop_ads_hi__reg_s0_live |
| Retention | - |
| Column Count | 13 (11 data columns + 3 partition columns, 2 of which also appear as data columns) |
| Region Coverage | SG (prod) -- 数据源来自 SG IDC (`ods_log_trace_shop_ads_hi_sgidc__reg_s0_live`)，US IDC 数据线已被注释 |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 166 files (1 write, 165 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
