<!-- ads-workspace-gdoc-sync: gdoc_id=1DfQ0bZY9Ww5h1JIdTA-lnxbvJRuCHqCiT1o-SGZbhpw gdoc_url=https://docs.google.com/document/d/1DfQ0bZY9Ww5h1JIdTA-lnxbvJRuCHqCiT1o-SGZbhpw/edit -->

# mp_paidads.dws_item_l2cat_potential_buyer__reg_s0_live

## Description

- **Desc:** 商品二级类目潜在买家标签表。基于近14天用户在商品二级类目维度的浏览(ppv)、加购(atc)、下单(orders)行为信号，计算用户对每个item L2类目的潜在购买意向等级(potential_buyer_type: 0-3)，为Target Audience广告召回提供定向人群。同时产出一份shop L2类目维度的姐妹表(dws_shop_l2cat_potential_buyer__reg_s0_live)，逻辑相同但以店铺二级类目为维度。
- **Granularity:** daily x region x user_id x l2_item_cat（每个用户在每个商品二级类目每天一条记录）
- **Use Case:**
  - Target Audience (TA) 广告潜在买家召回 — 下游 dws_target_audience_potential_new_buyer 表读取 potential_buyer_type >= 2 的用户，按L2类目匹配开通TA广告的店铺
  - TA 广告 bitmap 压缩版潜在买家召回 — dws_target_audience_all_potential_buyer_bitmap 使用 RoaringBitmap 压缩高潜用户
  - 潜在买家规模监控 — 按 region/date 统计各类型潜在买家量级
  - Target Audience 定向人群覆盖度分析 — 对比类目级潜在买家与店铺级定向人群的覆盖差异
- **Update Frequency:** Daily (workflow 调度，每个 region 独立产出)

## Key Metrics

此表为标签/特征表，非指标聚合表。核心字段：

- **potential_buyer_type**: 潜在买家等级（0=非潜在, 1=低, 2=中, 3=高）
  - 判定阈值（item维度）：
    - Type 3 (高潜): ppv >= 24 OR atc >= 5 OR orders >= 1
    - Type 2 (中潜): ppv >= 16 OR atc >= 3 OR orders >= 1
    - Type 1 (低潜): ppv >= 8 OR atc >= 1 OR orders >= 1
    - Type 0: 不满足以上任一条件

## Key Dimensions

- 分区: grass_region, grass_date
- 业务: l2_item_cat (商品二级类目), potential_buyer_type (潜在等级), user_id (用户ID)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | grass_region (string), grass_date (DATE) |
| HDFS Path | ${HIVE_PATH}/dws_item_l2cat_potential_buyer |
| Retention | - |
| Column Count | 3 data columns + 2 partition columns = 5 total |
| Region Coverage | SG, MY, ID, PH, VN, TH, TW, MX, CO, CL, BR (Standard 11 regions) |
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

- Studio Tasks References: 39 files (22 write, 17 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
