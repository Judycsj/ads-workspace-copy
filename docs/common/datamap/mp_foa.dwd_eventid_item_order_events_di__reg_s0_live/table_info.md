<!-- ads-workspace-gdoc-sync: gdoc_id=1ku2hk3cK9NMlPdsiGtYJgwsx_mqRWOnFi1nbnU0a-6M gdoc_url=https://docs.google.com/document/d/1ku2hk3cK9NMlPdsiGtYJgwsx_mqRWOnFi1nbnU0a-6M/edit -->

# mp_foa.dwd_eventid_item_order_events_di__reg_s0_live

## Description

- **Desc:** Feed/Organic Ads (FOA) 商品下单事件明细表 (DWD 层)，记录用户通过推荐/自然流量入口产生的下单行为。每行是一个 user-item 的下单事件，包含推荐入口 (step1_feature_group)、平台、AB 实验、位置等信息，支持按 direct_lead（第一步归因）和 complete_lead（完整归因）两种口径统计单量和 GMV。
- **Granularity:** event × grass_date × grass_region（事件级明细，每行为一个 user-item-place_order 事件）
- **Use Case:**
  - Discovery Ads 自然/广告下单数据提取 (dynamic_slot, organic_ad_order_data)
  - 商品历史价格计算 (avg_item_price_hist_Ndays)
  - 潜客建模 (potential_buyer: 按 l2_cat 统计用户下单行为)
  - 推荐位效果分析 (HPP 实验：按 entry_point 拆分 Imp→Click→ATC→Order 漏斗)
  - Keyword fill rate 分析（搜索场景下单归因）
  - 广告平台参数统计 (ads_advertise_params_1d)
  - 定位竞价分析 (position_bidprice_analysis)
- **Update Frequency:** Daily（per-region 分区覆写，FOA 团队维护）

## Key Metrics

- 下单量类: place_order_cnt_direct_lead, place_order_cnt_complete_lead
- GMV 类: place_gmv_usd_direct_lead, place_gmv_usd_complete_lead
- 当日加购下单: orders_td_atc (CASE WHEN atc_event_timestamp = grass_date), gmv_usd_td_atc
- 商品均价: avg_item_price = SUM(gmv) / SUM(orders)
- 商品中位价: approx_percentile(item_price_local_by_req, 0.5)

## Key Dimensions

- 分区: grass_date, grass_region
- 时区: tz_type (regional / local)
- 推荐入口: step1_feature_group, step1_feature, step1_feature_detail
- 实体: user_id, item_id, shop_id
- 平台: platform (ios_app / android_app / mobile)
- 实验: ab_test, ab_sign (从 step1_data.recommendation_info 提取)
- 广告标记: is_ads (从 step1_data 或 step1_data_property JSON 提取)
- 位置: location (从 step1_data JSON 提取)
- 二级归因: step2_feature_group (step_count > 1 时有值)
- 加购时间: atc_event_timestamp

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (未在 paidads-alg 代码库中找到 DDL，FOA 团队维护) |
| Partition Columns | grass_date, grass_region (推断自 WHERE 过滤模式) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG, MY, PH, ID, TH, TW, VN, BR, MX (推断自 WHERE 过滤) |
| DQC Status | - |
| Table Size | - |
| Table Type | - |
| LakeHouse Type | Hive |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Business PIC | - |
| Technical PIC | - |
| Team | mp_foa |
| Project | Feed/Organic Ads |
| Business Domain | - |
| DW Layer | DWD |
| Market Region | REG |

## Popularity

- Studio Tasks References: 35 files (0 write, 35 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
