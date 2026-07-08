<!-- ads-workspace-gdoc-sync: gdoc_id=1lLd5ap16rzc9gBpRdy2yOAq-bHYsRoOArcqu4efiwx8 gdoc_url=https://docs.google.com/document/d/1lLd5ap16rzc9gBpRdy2yOAq-bHYsRoOArcqu4efiwx8/edit -->

# mp_paidads.temp_unify_output_performance_info_di

## Description

- **Desc:** 统一输出广告效果对比临时表。将旧版效果数据（dwd_advertise_performance_di__reg_s0_live）与新版效果数据（paidads_mart.dwd_event_performance_hi__reg_s0_live）按 join_key 关联后，存储每条记录的新旧字段值对（*_old / *_new），用于对比新旧数据流的字段一致性和差异分析。
- **Granularity:** row-level (per join_key) x type x grass_region x grass_date
- **Use Case:**
  - 新旧广告效果数据流一致性对比（attribution_order / attribution_addtocart_imp / traffic 三种 type）
  - 新旧字段值差异排查（如 location_in_ads、model_id、match_type 等）
  - Join rate 计算（通过 new_join_key IS NULL 识别未匹配记录）
  - 漏斗各环节数据差异分析（下单、支付、ATC、流量）
- **Update Frequency:** On-demand（按需生产，非例行调度表）

## Key Metrics

- 字段一致率类：各 *_rate 字段（如 ads_id_rate, item_id_rate 等）表示新旧值不一致比例
- Join 指标：new_join_key IS NOT NULL（新旧能关联上），join_rate（关联率）

## Key Dimensions

- 分区：grass_region, grass_date, type
- type（数据来源分类）：traffic / attribution_order / attribution_addtocart_imp / finance
- entrance（入口）
- join_key / new_join_key（关联键）

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | parquet |
| Partition Columns | grass_region (string), grass_date (date), type (string) |
| HDFS Path | ${HIVE_PATH}/temp_unify_output_performance_info_di |
| Retention | - |
| Column Count | ~300 (150 paired _old/_new columns + 3 non-partition columns) |
| Region Coverage | Regional level (grass_region = PH tested in code) |
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

- Studio Tasks References: 9 files (3 write, 6 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
