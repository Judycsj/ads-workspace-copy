<!-- ads-workspace-gdoc-sync: gdoc_id=1rgIE6xUx8fgrLkvD6lq108SQ-LO6xUeusF1M_mvaLeU gdoc_url=https://docs.google.com/document/d/1rgIE6xUx8fgrLkvD6lq108SQ-LO6xUeusF1M_mvaLeU/edit -->

# traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live

## Description

- **Desc:** DWS 层业务线级销售漏斗指标天表，覆盖从曝光、点击到下单、GMV 的完整用户行为漏斗。按业务线 (business_line)、模块 (module)、对象 (object)、特征详情 (feature_detail) 等多级维度聚合，并保留 user_id 用于用户级去重统计。支持 source1/source2 两级来源归因链路分析。
- **Granularity:** daily × grass_region × business_line × module × object × feature_detail × user_id
- **Use Case:**
  - AB 实验有机流量效果分析（Search/DD/YMAL 入口的 organic imp, click, order, GMV）
  - 业务线流量订单日报（Homepage/Search/Rcmd/Platform/Others 的 feature 级漏斗拆解）
  - 流量导流归因分析（如 YMAL 导 Image Search/Live/Global Search 的下单与 GMV）
  - 首页模块（Daily Discover/Flash Sale）及 Rcmd 场景（Private Domain/User Scenario）的子模块下钻
- **Update Frequency:** Daily

## Key Metrics

- **流量曝光类:** impr_cnt_1d, impr_organic_cnt_1d, impr_ads_cnt_1d, item_impr_cnt_1d, item_impr_organic_cnt_1d, item_impr_ads_cnt_1d
- **用户去重(UV)类:** impr_uu_cnt_1d, impr_organic_uu_cnt_1d, impr_ads_uu_cnt_1d, item_impr_uu_cnt_1d, item_impr_organic_uu_cnt_1d, item_impr_ads_uu_cnt_1d
- **点击类:** click_cnt_1d, click_organic_cnt_1d, click_ads_cnt_1d, item_click_cnt_1d, item_click_organic_cnt_1d, item_click_ads_cnt_1d
- **下单类:** order_1d, order_organic_1d, order_ads_1d
- **GMV类:** gmv_usd_1d, gmv_usd_organic_1d, gmv_usd_ads_1d

## Key Dimensions

- **分区:** grass_date (date) — 同时存在 regional_date / local_date 两种分区列名，不同任务使用不同名称
- **地域:** grass_region
- **业务维度:** business_line, module, object, feature_group, feature, feature_detail
- **来源归因:** source1_business_line, source1_module, source1_object, source1_feature, source1_feature_group, source1_feature_detail, source2_business_line, source2_module, source2_object, source2_feature, source2_feature_group, source2_feature_detail
- **用户:** user_id
- **时区:** tz_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | reg_sensitive_live |
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

- Studio Tasks References: 13 files (12 read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
