<!-- ads-workspace-gdoc-sync: gdoc_id=1OZEnl4qrR1Hcuxq_kbpbNtpnNg0Qcp9e3v4llRk0oK0 gdoc_url=https://docs.google.com/document/d/1OZEnl4qrR1Hcuxq_kbpbNtpnNg0Qcp9e3v4llRk0oK0/edit -->

# mkplpaidads_search_ads.omni_core_key_metrics_merge_daily__reg_s0_live

## Description

- **Desc:** Omni（全渠道）商品-店铺-入口场景维度的核心指标汇总中间表。聚合了搜索广告+推荐广告+直播+视频+游戏等全渠道流量下每个 item-shop-common_feature 组合的表现数据（曝光/点击/订单/GMV），区分广告与非广告贡献。
- **Granularity:** daily × grass_region × item_id × shop_id × common_feature
- **Use Case:**
  1. 作为 ads_diagnosis 下游最终表（ads_seller/item/advertise_key_metrics_daily）补充全渠道对比数据（ads vs total）
  2. 作为 dim_omni_item_shop_attr_daily 的 key source（提取有广告表现的 item-shop 组合）
  3. 支持 omni metrics add_metric 流程（为已有 ads 维度表补充全渠道数据）
  4. 用于按 entrance/scene 维度分析广告投放vs自然流量的占比
- **Update Frequency:** Daily（每个 region 独立 INSERT INTO，分区覆盖）

## Key Metrics

- 曝光类: ads_imp_cnt (广告曝光), total_imp (总曝光含自然)
- 点击类: ads_click_cnt (广告点击), total_click (总点击含自然)
- 订单类: ads_order_cnt (广告订单数), total_order (总订单数含自然)
- GMV 类: ads_gmv_usd (广告 GMV USD), total_gmv (总 GMV USD)
- 加购类: total_atc (总加购数)

## Key Dimensions

- 分区: grass_date, grass_region
- 业务:
  - item_id (商品 ID), shop_id (店铺 ID)
  - common_feature (入口场景特征，如 Daily Discover / Global Search / Live Streaming 等)
- 覆盖地区: ID, PH, SG, TH, TW, MY, VN, BR

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | grass_date, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | 14 (12 data + 2 partition) |
| Region Coverage | ID, PH, SG, TH, TW, MY, VN, BR |
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

- Studio Tasks References: 56 files (9 write, 47 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
