<!-- ads-workspace-gdoc-sync: gdoc_id=1GehtcJKviDwKayb_UneNY5yPE0lLQT9fpo1WKJgwqvc gdoc_url=https://docs.google.com/document/d/1GehtcJKviDwKayb_UneNY5yPE0lLQT9fpo1WKJgwqvc/edit -->

# mp_paidads.dws_item_simple_roi2_first_adopted_td__reg_s0_live

## Description

- **Desc:** Simple ROI2 商品首次采纳日期维表。记录每个商品首次以 Simple (pricing_type=3) 或 Simple2 (placement=50) 方式投放广告的日期，以及是否为迁移商品。
- **Granularity:** daily x grass_region x item_id (tz_type='local' only)
- **Use Case:**
  1. Simple ROI2 商品迁移前后效果对比分析 (simple2_before_after)
  2. 判定商品是否为新采纳的 Simple/Simple2 广告商品
  3. 按商品首次采纳日期进行 Cohort 分析
- **Update Frequency:** Daily (8 regions parallel)

## Key Metrics

- 维度表，无聚合指标。核心信息为:
  - item_first_adopted_date: 商品首次采纳日期
  - is_migrated_item: 是否从 Simple 迁移到 Simple2 的商品

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 业务: item_id, shop_id, seller_id
- 类目: level1/2/3_global_be_category (ID + name)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | `${HIVE_PATH}/dws_item_simple_roi2_first_adopted_td__reg_s0_live/` |
| Retention | - |
| Column Count | 11 (non-partition) + 3 (partition) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR |
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

- Studio Tasks References: 9 files (8 write + 1 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
