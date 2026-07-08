<!-- ads-workspace-gdoc-sync: gdoc_id=1M13osS4s0hjnhCfSs0c2MPLnzgyORZpzkDurylYsZzM gdoc_url=https://docs.google.com/document/d/1M13osS4s0hjnhCfSs0c2MPLnzgyORZpzkDurylYsZzM/edit -->

# mp_paidads.dws_item_performance_1d__reg_s0_live

## Description

- **Desc:** DWS 层 item 维度商品流量漏斗数据（日报），记录每个 shop_id × item_id 在自然流量和广告流量下的曝光、点击、下单、GMV 指标。支持区分 direct attribution 和 broad attribution 两类归因窗口。所有指标基于 tz_type='local'（本地时区）。
- **Granularity:** daily × shop_id × item_id × grass_region × tz_type
- **Use Case:**
  1. Seller Metrics 日报/月报 — 按 shop 维度汇总 ads vs organic item 表现，用于广告卖家健康度分析
  2. Item 级广告效果分析 — 通过 ads_item (dim_advertise) 标签区分广告商品 vs 自然商品，统计 ads/org 各自的曝光、点击、下单、GMV
  3. Platform Order 交叉参考 — 与 mp_order.dws_item_gmv_1d 关联，对比平台侧和广告侧的 GMV 数据
  4. 卖家月度汇总 — 按月聚合 item 级别指标 (imp/click/order) 用于月度报表
- **Update Frequency:** Daily (by workflow, per grass_date)

## Key Metrics

- 曝光类: item_imp_cnt (商品总曝光), org_item_imp_cnt (自然流量商品曝光)
- 点击类: item_click_cnt (商品总点击), org_item_click_cnt (自然流量商品点击)
- 下单类 (Direct): item_direct_order_cnt, org_direct_order_cnt
- 下单类 (Broad): item_broad_order_cnt, org_broad_order_cnt
- GMV 类 (Direct): item_direct_gmv_usd, org_direct_gmv_usd
- GMV 类 (Broad): item_broad_gmv_usd, org_broad_gmv_usd

> org_ 前缀 = 自然流量（非广告）；不带前缀的 item_ 指标 = 广告 + 自然合计

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 粒度: shop_id, item_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | ${path} (workflow variable) |
| Retention | - |
| Column Count | 14 (non-partition) + 3 (partition) = 17 total |
| Region Coverage | BR, ID, MX, MY, PH, SG, TH, TW, VN |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWS |

## Popularity

- Studio Tasks References: 55 files (9 write, 46 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
