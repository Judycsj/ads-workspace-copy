<!-- ads-workspace-gdoc-sync: gdoc_id=1nOSOK0sJsq6jSGIHdIYaGRzgtsDPyVxXCPnpbpPYDzY gdoc_url=https://docs.google.com/document/d/1nOSOK0sJsq6jSGIHdIYaGRzgtsDPyVxXCPnpbpPYDzY/edit -->

# mp_paidads.ads_advertise_alarm_key_metrics_1d__reg_s0_live

## Description

- **Desc:** 广告主告警核心指标表，聚合广告主每天的广告表现数据（收入、曝光、点击、订单、GMV）、预算信息（店铺/广告系列预算）和基础画像（分层、类目），用于生成告警日报/周报，以及下游发现广告 GMV uplift、低预算使用监控等分析场景。
- **Granularity:** daily x shop_id x campaign_id x ads_id x item_id x pricing_type x placement x main_product_type x product_type x sub_product_type x traffic_type x entry_point x entrance
- **Use Case:**
  - 广告主告警日报（ads_advertiser_alarm_daily_report）：按 shop 聚合 1d/1d ago/7d ago 对比
  - 广告主告警周报（ads_advertiser_alarm_weekly_report）：按 shop 聚合 3 周对比
  - 发现广告 GMV uplift 分析：商品维度广告前后 GMV 对比
  - 发现广告 GMV change 分析：首投商品 GMV 变化
  - 发现广告全链路诊断（full_link_diagnose_general_shop_metrics）：场景 x product_type 聚合预算/效果
  - 低预算使用率监控（low_budget_usage）：campaign 维度预算使用率
  - 搜索广告诊断系统（diagnostic_system）：PID coef 异常检测
  - 黑名单计算：豁免预算前五 ads
- **Update Frequency:** Daily (workflow by region, 12 region files)

## Key Metrics

- 收入类: ads_rev_usd_1d, shop_ads_rev_usd_1d, campaign_ads_rev_usd_1d
- 预算类: shop_valid_budget_usd_1d (SUM DISTINCT), campaign_valid_budget_usd_1d (MAX), account_balance_usd, budget_usd
- 效果类: ads_impression_1d, ads_click_1d, direct_order_1d, broad_order_1d, direct_gmv_usd_1d, broad_gmv_usd_1d
- 告警标记: if_campaign_hit (campaign 预算命中标记), if_campaign_waste (campaign 浪费标记)
- 其他: cps_dedup_click_cnt_1d

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 主体维度: shop_id, campaign_id, ads_id, item_id, seller_name
- 分层: advertiser_tier, seller_tier
- 类目: shop_level1_global_be_category, shop_level2_global_be_category
- 投放维度: pricing_type, placement, main_product_type, product_type, sub_product_type, traffic_type, entry_point, entrance

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string), grass_region (string), grass_date (DATE) |
| HDFS Path | `${HIVE_PATH}/ads_advertise_alarm_key_metrics_1d` |
| Retention | - |
| Column Count | 33 (+3 partition columns) |
| Region Coverage | 12 regions: BR, CL, CO, ID, MX, MY, PH, SG, TH, TW, VN + standard |
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

- Studio Tasks References: 155 files (12 write + 143 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
