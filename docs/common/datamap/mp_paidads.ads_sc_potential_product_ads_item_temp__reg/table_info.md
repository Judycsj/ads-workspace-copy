<!-- ads-workspace-gdoc-sync: gdoc_id=1khxsMCUrF0vB_LrAMoE_CZqlBbE7fGMUS0ECowDQ7eA gdoc_url=https://docs.google.com/document/d/1khxsMCUrF0vB_LrAMoE_CZqlBbE7fGMUS0ECowDQ7eA/edit -->

# mp_paidads.ads_sc_potential_product_ads_item_temp__reg

## Description

- **Desc:** 潜在商品广告推荐临时表（中间表），存储 item 粒度近 7 天 performance 指标，作为 `ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live` 生产 Pipeline 的中间步骤。上游从 OMNI sales funnel 取 item 级订单/GMV/impression/click 数据，JOIN item 维表补充类目层级，排除大促在投商品 (NPB) 和刷单商品后写入。
- **Granularity:** daily x item_id x grass_region
- **Use Case:**
  - 潜力商品推荐 Pipeline 中间步骤 — 为后续 scoring 提供 item 级基础特征
  - 类目分位数计算 — `category_data` temp view 基于此表计算 l1/l2/l3 类目级别的 ctrcr_p50 / gmv_p60/P90 / order_p80
  - 好货潜力评分 — 基于类目分位数 + item 特征筛选 "good potential" 商品
  - 低价潜力识别 — 从 `srdi_mart` 补充 One Variation Model 数据，排除已在投 NPB 商品
- **Update Frequency:** Daily（workflow 调度，以 `BIZ_YESTERDAY` 为分区日期）

## Key Metrics

- 收入类: gmv_usd_7d (7天GMV, USD)
- 订单类: order_cnt_7d (7天订单数), avg_order_7d (7天日均订单), avg_order_cnt_14d (对比期日均订单)
- 效果类: impression_7d (7天曝光), click_7d (7天点击), ctrcr_7d (点击转化率)
- 增长类: order_growth_rate (订单增长率 = avg_order_7d / avg_order_cnt_14d - 1)

## Key Dimensions

- 分区: grass_region, grass_date
- 商品: item_id, shop_id
- 类目: l1_cat (一级), l2_cat (二级), l3_cat (三级), final_cat (最终类目)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_region (string), grass_date (date) |
| HDFS Path | ${HIVE_PATH}/ads_sc_potential_product_ads_item_temp |
| Retention | - |
| Column Count | 14 (non-partition) + 2 (partition) |
| Region Coverage | vn, tw, th, sg, ph, my, mx, id, co, cl, br (11 regions) |
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

- Studio Tasks References: 11 files (all write + read, workflows/)
- L7D Query Count: -
- Completeness: -
- Popularity: -
