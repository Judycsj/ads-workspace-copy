<!-- ads-workspace-gdoc-sync: gdoc_id=1oXHz6h-qHJgZPg3K-VKqsUijxJ-iTjVeYY9NumToK0I gdoc_url=https://docs.google.com/document/d/1oXHz6h-qHJgZPg3K-VKqsUijxJ-iTjVeYY9NumToK0I/edit -->

# mp_paidads.ads_simple_roi2_npb_item_hi__reg_s0_live

## Description

- **Desc:** Simple ROI2 New Product Boost (NPB) 商品级累计表现数据表，存储各商品自创建以来的平台曝光、点击、订单等累计指标，用于冷启动商品的分阶段 (stage) 和分层 (tier) 分类，为搜索广告 NPB 策略提供数据基础。
- **Granularity:** item_id x grass_region x grass_date x h（每小时 × 商品 × 地区）
- **Use Case:**
  - Simple ROI2 NPB 商品分阶段分类：按创建天数和累计订单数将商品划分为 stage 1（新商品无订单）/ stage 2（新商品有少量订单）/ stage 0（其他）
  - NPB 商品分层分类：基于曝光量、CTR、日均订单量 (ADO) 的百分位阈值将商品划分为 tier 1/2/3
  - 搜索广告 NPB Redis 缓存刷新：stage 和 tier 结果写入 Redis（simpleRoi2_stage_tier），供在线广告投放策略查询
- **Update Frequency:** Hourly（按 h 分区，每小时更新）

## Key Metrics

- 曝光类: platform_impression_acc（平台累计曝光）
- 点击类: platform_click_acc（平台累计点击）
- 订单类: platform_order_acc（平台累计订单数）, platform_order_avg（平台日均订单数, ⚠️ 不可累加）
- 商品属性: create_day_cnt（商品创建天数）

## Key Dimensions

- 分区: grass_region, grass_date, h
- 商品: item_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_region, grass_date, h（从 SHOW PARTITIONS 解析推断） |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, CL, CO, MX, BR（从 workflow 逻辑推断） |
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

- Studio Tasks References: 7 files (0 write, 7 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
