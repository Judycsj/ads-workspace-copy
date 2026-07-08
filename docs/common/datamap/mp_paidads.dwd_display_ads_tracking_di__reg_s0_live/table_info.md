<!-- ads-workspace-gdoc-sync: gdoc_id=1_js2AIIEwUDO7pnQH-xghFtOBo0CqqdeHljFuCkKq0w gdoc_url=https://docs.google.com/document/d/1_js2AIIEwUDO7pnQH-xghFtOBo0CqqdeHljFuCkKq0w/edit -->

# mp_paidads.dwd_display_ads_tracking_di__reg_s0_live

## Description

- **Desc:** Display Ads (Banner Ads) 的用户行为追踪 DWD 层明细表。从 ODS 原始日志 `ods_log_display_ads_tracking_hi` 清洗加工，解析 banner 嵌套结构，补充 ads_placement、ads_entrance 等信息，按当地时间分区存储。一条记录代表一次展示 (operation=1) 或点击 (operation=2) 事件的追踪日志。
- **Granularity:** event-level (per tracking impression/click event per user per ad)
- **Use Case:**
  1. `dws_display_ads_performance_di` 生产 — 计算 campaign 级别的 UV/PV、PDP/Shop 访问、60d reach 等指标
  2. `ads_tracking_report_ng_diff_1d` 数据差异对比 — 与 report_ng、tracking_item/tracking_shop 等数据源对比 imp/click 差异
  3. Display Ads AB 实验分析 — 按 slot_id、ab_sign 分组计算 CTR
  4. 广告曝光用户画像分析 — 关联用户标签（mpi_data_mart）分析广告受众
  5. 指定 banner/slot 的实时曝光量监控 — 按 slot_id 和 grass_date 统计曝光量
- **Update Frequency:** Daily (每个地区当地时间 00:00-23:59 的事件)

## Key Metrics

- 流量类: impression (operation=1), click (operation=2), CTR (click/impression)
- 用户类: UV (COUNT DISTINCT user_id), PV (COUNT user_id), banner-level UV

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 业务: ads_placement, ads_entrance, placement, slot_id, operation, source, banner_id, ads_id, banner_location, landing_url_type
- 用户: user_id, shop_id, device_id, platform, session_id, ab_sign

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET (inferred from write workflow: Spark INSERT OVERWRITE with PARQUET-based hive table) |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | `${HIVE_PATH}/dwd_display_ads_tracking_di__reg_s0_live` (inferred from standard DWD path pattern) |
| Retention | - |
| Column Count | ~34 (from INSERT SELECT columns) |
| Region Coverage | SG, MY, PH, TW, ID, TH, VN, BR, MX (9 regions + local variants) |
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

- Studio Tasks References: 34 files (8 write, 26 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
