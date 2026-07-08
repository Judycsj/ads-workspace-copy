<!-- ads-workspace-gdoc-sync: gdoc_id=1ihdj0cSOyb0Ew7-Ba5iOCe2GPLQa5VaDYZizIVHtfdY gdoc_url=https://docs.google.com/document/d/1ihdj0cSOyb0Ew7-Ba5iOCe2GPLQa5VaDYZizIVHtfdY/edit -->

# mp_paidads.dws_advertise_performance_nd__reg_s0_live

## Description

- **Desc:** Ads 广告滚动窗口性能汇总表 (N-Day)，基于 1d 表聚合 1d/7d/30d/60d/90d 滑动窗口指标。粒度到 ads_id + placement + ads_type + shop_id + seller_id。包含基础效果指标、衍生比率指标(CTR/CIR/CR/CPC/ROI)、broad GMV 和 deduct impression。
- **Granularity:** daily x ads_id x placement x ads_type x shop_id x seller_id x tz_type
- **Use Case:**
  1. Seller 近 N 日广告消耗查询 (shop_expenditure_l7d, ads_rm_shop_info_di)
  2. 广告主新老客标签 (advertiser_lifecycle_type) 依赖近 30/60 天支出
  3. 广告主营销日报 (ads_advertiser_mkt_1d) 的 shop 级基础效果指标聚合
  4. Brand Ads 店铺分析 (各类 shop 维度 ROI/支出分析)
  5. Placement 维度效果对比 (Brand Ads 按 Shop Simple / Manual Shop / Manual Search 拆分)
  6. 数据校验 (prod vs dev 表对比)
- **Update Frequency:** Daily (workflow 调度, 按 region 写入)

## Key Metrics

- 基础效果类: impression_cnt_{1d,7d,30d,60d,90d}, click_cnt_{1d,7d,30d,60d,90d}, order_cnt_{1d,7d,30d,60d,90d}
- 收入类: ads_gmv_amt_local_{1d,7d,30d,60d,90d}, ads_gmv_amt_usd_{1d,7d,30d,60d,90d}
- 消耗类: expenditure_amt_local_{1d,7d,30d,60d,90d}, expenditure_amt_usd_{1d,7d,30d,60d,90d}
- 商品类: ads_items_sold_cnt_{1d,7d,30d,60d,90d}
- 订单类: paid_order_cnt_ytd_1d, confirmed_order_cnt_ytd_1d
- Broad 类: broad_gmv_amt_local_{1d,7d,30d,60d,90d}, broad_gmv_amt_usd_{1d,7d,30d,60d,90d}, broad_order_cnt_{1d,7d,30d,60d,90d}
- Deduct 类: ads_deduct_impression_cnt_{1d,7d,30d,60d,90d}
- 衍生比率 (COALESCE 计算, 不可直接 SUM): ctr_, cir_, cr_, cpc_local_, cpc_usd_, roi_, broad_roi_ 各窗口

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 广告标识: ads_id, placement, ads_type (if placement=20 then 'shop_simple' else ads_type)
- 店铺标识: shop_id, seller_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/dws_advertise_performance_nd/ |
| Retention | - |
| Column Count | ~110 (含分区列) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap, 请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 106 files (13 write, 93 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
