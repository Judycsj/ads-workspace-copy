<!-- ads-workspace-gdoc-sync: gdoc_id=1jELikhCcFyTS9MtNE9LmvORb5PvG4qz_SLHCRy4D8oE gdoc_url=https://docs.google.com/document/d/1jELikhCcFyTS9MtNE9LmvORb5PvG4qz_SLHCRy4D8oE/edit -->

# mp_paidads.dws_shop_l2cat_potential_buyer__reg_s0_live

## Description

- **Desc:** 广告潜在买家定向表，基于最近 14 天的用户浏览(ppv)、加购(atc)和下单(orders)行为，在店铺二级类目(L2 category)粒度上对用户进行潜在买家分层。仅包含有 GMV 且状态有效的店铺。
- **Granularity:** user_id x l2_shop_cat x grass_region x grass_date
- **Use Case:**
  - 广告定向投放：筛选特定 L2 类目下高潜力买家作为目标受众
  - 受众规模评估：按地区和类目统计各级别潜在买家人数
  - 类目级 vs 店铺级受众覆盖对比：与 dws_target_audience_potential_new_buyer 联合分析覆盖差异
  - 全量潜在买家位图构建：作为上游表供 dws_target_audience_all_potential_buyer_bitmap 使用
- **Update Frequency:** Daily

## Key Metrics

- **用户行为计数**: ppv (浏览商品数), atc (加购数), orders (下单数)
- **潜在买家分级**: potential_buyer_type (0-3)
  - 3 (高潜力): ppv>=9 OR atc>=5 OR orders>=1
  - 2 (中高潜力): ppv>=6 OR atc>=3 OR orders>=1
  - 1 (中低潜力): ppv>=3 OR atc>=1 OR orders>=1
  - 0 (低潜力): 不满足上述条件

## Key Dimensions

- 分区: grass_region, grass_date
- 业务: l2_shop_cat (店铺二级类目ID), potential_buyer_type (买家分级)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | grass_region, grass_date |
| HDFS Path | ${HIVE_PATH}/dws_shop_l2cat_potential_buyer |
| Retention | - |
| Column Count | 5 (3 data + 2 partition) |
| Region Coverage | MX, CO, CL, BR |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 12 files (7 write, 5 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
