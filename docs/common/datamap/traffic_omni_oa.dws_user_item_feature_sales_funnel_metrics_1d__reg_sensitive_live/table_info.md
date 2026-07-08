<!-- ads-workspace-gdoc-sync: gdoc_id=1ouhLwxnjdb4H_8PeUhX78srZllpUbJR3UsgZ9thtw1k gdoc_url=https://docs.google.com/document/d/1ouhLwxnjdb4H_8PeUhX78srZllpUbJR3UsgZ9thtw1k/edit -->

# traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live

## Description

- **Desc:** DWS 层 Omni OA user-item-feature 粒度销售漏斗指标表。该表汇总了从曝光、点击、商品页浏览、加购到下单的完整流量漏斗指标，同时包含用户维度和三级流量归因维度（主事件 / source1 / source2），支持 ads vs organic 的对比分析。是 Ads 算法团队机器学习特征工程、ROI分析、卖家诊断等场景的核心数据源。
- **Granularity:** user_id x device_id x platform x app_version x rn_version x item_id x shop_id x feature_group x feature x feature_detail x source{1,2}_business_line x source{1,2}_module x source{1,2}_object x source{1,2}_feature_group x source{1,2}_feature x source{1,2}_feature_detail x local_hour x regional_date x regional_hour x platform_implementation x item_location
- **Use Case:**
  1. ML 特征工程 -- 提取商品历史缺量/转化/GMV 作为 item selection 模型特征 (feature_gen, label_gen)
  2. Traffic Boost 特征提取 -- 计算 campaign item 的 7d/14d 缺量平台表现 (traffic_boost_hist_features)
  3. ROI3/Co-fund 效果监控 -- 计算平台 GMV 用于广告效果评估 (cofund_perf_scripts)
  4. 卖家诊断 -- 平台CTR/CVR/Target ROI 基准分析 (ads_sellercenter_diagnosis)
  5. 场景分析 -- Search/DD/YMAL 等场景维度的 GMV 聚合 (omni_diagnose)
  6. 品类定价分析 -- category-level price bucket 订单分布 (category_l2_ordercount)
  7. Rcmd数据管道 -- 推荐分数据准备 GMV 最大商品 (rcmd_score_data_pipeline)
  8. 激励策略 -- 新品GMV判定、卖家分层统计 (incentive_strategy)
- **Update Frequency:** Daily

## Key Metrics

- 曝光类: `impr_cnt_1d`, `item_impr_cnt_1d`, `impr_ads_cnt_1d`, `impr_organic_cnt_1d`, `item_impr_ads_cnt_1d`, `item_impr_organic_cnt_1d`
- 点击类: `click_cnt_1d`, `item_click_cnt_1d`, `click_ads_cnt_1d`, `click_organic_cnt_1d`, `item_click_ads_cnt_1d`, `item_click_organic_cnt_1d`
- 商详浏览: `ppv_cnt_1d`, `ppv_ads_cnt_1d`, `ppv_organic_cnt_1d`, `ppv_duration_1d`, `ppv_ads_duration_1d`, `ppv_organic_duration_1d`
- 加购: `atc_cnt_1d`, `atc_ads_cnt_1d`, `atc_organic_cnt_1d`
- 订单: `order_1d`, `order_ads_1d`, `order_organic_1d`
- GMV: `gmv_1d` (local), `gmv_ads_1d`, `gmv_organic_1d`, `gmv_usd_1d`, `gmv_usd_ads_1d`, `gmv_usd_organic_1d`
- Platform Cost: `pc2_1d`, `pc2_ads_1d`, `pc2_organic_1d`, `pc2_usd_1d`, `pc2_usd_ads_1d`, `pc2_usd_organic_1d`
- 卖家GMV: `place_sellergmv_1d`, `ads_place_sellergmv_1d`, `organic_place_sellergmv_1d`, `place_sellergmv_usd_1d`, `ads_place_sellergmv_usd_1d`, `organic_place_sellergmv_usd_1d`
- 数量: `item_qty_1d`, `item_qty_ads_1d`, `item_qty_organic_1d`

## Key Dimensions

- 分区: `grass_region`, `local_date`
- 实体: `user_id`, `device_id`, `item_id`, `shop_id`
- 时间: `local_hour`, `regional_date`, `regional_hour`
- 商品: `item_status`, `stock`, `price`, `price_usd`, `price_before_discount`, `price_before_discount_usd`, `rating_score`, `rating_total_cnt`, `comment_cnt`, `create_datetime`, `item_location`
- 品类: `level1_global_be_category_id`, `level2_global_be_category_id`, `level1_global_be_category`, `level2_global_be_category`
- 店铺: `shop_status`, `is_cb_shop`, `is_official_shop`, `is_preferred_shop`, `is_preferred_plus_shop`, `seller_type`, `seller_type_1p`, `is_cb_sip_affiliated`, `is_local_sip_affiliated`, `is_cb_seller`
- 用户: `platform`, `platform_implementation`, `app_version`, `rn_version`, `gender`, `placed_order_cnt_td`
- 流量归因 (main): `business_line`, `module`, `object`
- 流量归因 (source1): `source1_business_line`, `source1_module`, `source1_object`
- 流量归因 (source2): `source2_business_line`, `source2_module`, `source2_object`
- 特征归因 (main): `feature_group`, `feature`, `feature_detail`
- 特征归因 (source1): `source1_feature_group`, `source1_feature`, `source1_feature_detail`
- 特征归因 (source2): `source2_feature_group`, `source2_feature`, `source2_feature_detail`

## Technical Properties

| Property | Value |
|---|---|
| **Table Update Frequency** | Daily |
| **DQC Status** | - |
| **Table Size** | - |
| **LakeHouse Type** | Hive |
| **Table Type** | VIRTUAL_VIEW |
| **Retention** | Permanent |
| **Visibility** | Open |
| **Create Info** | traffic_omni_oa / Jun 14, 2023 05:02 PM |
| **Last Edited Info** | SYSTEM / Jan 30, 2026 12:00 PM |

## Business Properties

| Property | Value |
|---|---|
| **Business PIC** | jianqiao.ji@shopee.com |
| **Technical PIC** | yang.xiao@shopee.com fan.luo@shopee.com |
| **Team** | regdedw1 |
| **Project** | Omni Attribution Mart(traffic_omni_oa) |
| **Business Domain** | Marketplace - Core |
| **Data Mart** | Omni OA Mart |
| **Data Topic** | - |
| **DW Layer** | DWS |
| **Market Region** | REG |
| **Last 7 Days Query Count** | 11,333 |
| **Sensitivity Level** | - |

## Completeness & Popularity

- **Studio Tasks References:** 429 files (workflows: 50, scheduled_tasks: 46, manual_tasks/services: 333+)
- **Codebase Total References:** 628 files
- **Completeness**: 96.21
- **Popularity**: 100.00
