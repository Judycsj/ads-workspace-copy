<!-- ads-workspace-gdoc-sync: gdoc_id=1jSgDPTRc9DwK5bu3QJH1o0EnwklEI5GK_ddhVSMDSXc gdoc_url=https://docs.google.com/document/d/1jSgDPTRc9DwK5bu3QJH1o0EnwklEI5GK_ddhVSMDSXc/edit -->

# mp_foa.dwd_eventid_click_last_di__reg_s0_live

## Description

- **Desc:** FOA (Feed One Ads) 全站点击事件日志表，记录用户在所有入口点（Search, Discovery, YMAL 等）对商品的点击行为。每行代表一个点击事件，包含用户ID、商品ID、点击上下文（JSON 格式的 data/data_property），用于分流广告点击与自然流量点击、追踪点击归因路径。
- **Granularity:** event-level (one row per click event)
- **Use Case:**
  - 商品曝光-点击转化分析（配合 dwd_eventid_impress_di 追踪 Imp→Click→Order 漏斗）
  - Search 广告关键词填充率/召回率计算（提取 keyword + request_id + is_ads 标记，JOIN ads_slot_mapping 计算 adslot 覆盖）
  - 广告 / 自然流量 CVR 拆解（按 is_ads 标记区分 organic vs ads 点击贡献，按小时粒度分析）
  - 预算推荐（rcmd）数据准备：提取 item_id + shop_id 构建 rcmd_v2_click 表
  - 广告标题匹配效果分析（query → title desc 对应关系）
  - 商品性能分析（配合 traffic、order_events 表计算 item-level imp/click/order 漏斗）
- **Update Frequency:** Daily

## Key Metrics

- 点击量: click_cnt (`COUNT(*)` or `COUNT(event_id)`)
- 自然点击量: organic_click_cnt (`COUNT(CASE WHEN is_ads = 'false' THEN 1 END)`)
- 广告点击量: ads_click_cnt (`COUNT(CASE WHEN is_ads = 'true' THEN 1 END)`)

## Key Dimensions

- 分区: grass_date, grass_region, tz_type
- 业务: target_type (主要 'item'), feature_group (Search / Daily Discover / YMAL ...), feature_detail (global_search-item / search_in_pdp-item ...), platform (ios_app / android_app)
- JSON提取: user_id, shop_id, item_id, keyword, request_id, is_ads, location

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date (DATE), grass_region (STRING), tz_type (STRING) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG, ID, MY, PH, TH, TW, VN, BR, MX, CO, CL |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | FOA (Feed One Ads) |
| Business Domain | Traffic / Click Event Tracking |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 51 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
