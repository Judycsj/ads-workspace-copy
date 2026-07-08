<!-- ads-workspace-gdoc-sync: gdoc_id=1eNQvyMHj_W67FvPUw_EiamCisTFxn0b2GeBis0nRdsQ gdoc_url=https://docs.google.com/document/d/1eNQvyMHj_W67FvPUw_EiamCisTFxn0b2GeBis0nRdsQ/edit -->

# mp_paidads.ods_log_display_ads_tracking_hi__reg_s0_live

## Description

- **Desc:** ODS 层原始埋点日志表，记录 Display Ads (Banner/展示广告) 的 tracking 数据。数据源为客户端埋点 Kafka 日志，按 region + 日期 + 小时分区小时级入库。是 `dwd_display_ads_tracking_hi__reg_s0_live` DWD 表的上游，也是 banner 类型 TMS 数据去重分析的核心数据源。
- **Granularity:** 单条埋点事件级（event-level），每条记录对应一次客户端上报的 Display Ads tracking 事件（如曝光、点击、加购、下单等）。
- **Use Case:**
  - Display Ads (Banner) 效果追踪：曝光/点击/加购/下单等行为日志分析
  - DWD 层 ETL：解析 banner 内嵌 JSON 字段，生成结构化 DWD 表
  - TMS 数据去重对比：与 UBTA 埋点数据 JOIN 对比，分析 tracking 数据重复率和空值率
  - Brand Ads 展示广告曝光监控：按 region/slot 统计曝光量并与 TMS 数据对比
  - 入口（entrance）维度分析：通过 dim_entry_point_mapping_v2 映射到 entry_point 场景
- **Update Frequency:** 每小时（Hourly），按 `grass_date` + `h` 分区追加

## Key Metrics

- 曝光类: `operation=1` 计数（IMPRESSION）
- 点击类: `operation=2` 计数（CLICK）
- 加购类: `operation=4` 计数（ADD_TO_CART）
- 下单类: `operation=5` 计数（PLACE_ORDER）
- 去重指标: `COUNT(DISTINCT unique_id)` 用于去重人数统计
- 重复率: `(COUNT(unique_id) - COUNT(DISTINCT unique_id)) / COUNT(unique_id)` where unique_id not null

## Key Dimensions

- 分区: `grass_region`, `grass_date`, `h`
- 入口: `entrance`, `sub_entrance`（通过 `dim_entry_point_mapping_v2` 映射到 `entry_point`）
- 操作类型: `operation`（1=曝光/2=点击/3=浏览/4=加购/5=下单/6=关闭/1001=店铺曝光/1002=店铺点击）
- 平台: `platform`（1=iOS Web/2=iOS App/3=Android Web/4=Android App/5=PC）
- 页面上下文: `page_type`, `page_section`, `target_type`
- Banner 维度: `banner.bannerid`, `banner.slotid`, `banner.source`, `banner.campaign_unitid`, `get_json_object(banner.json_data, '$.entrance')`
- 用户标识: `userid`, `deviceid`, `sessionid`, `unique_id`
- 版本: `app_ver`, `rn_ver`, `dre_ver`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (USING PARQUET) |
| Partition Columns | `grass_region` (string), `grass_date` (date), `h` (int) |
| HDFS Path | `hdfs://R2/projects/data_paidadsmart/hdfs/prod/logs/ods_log_display_ads_tracking_hi__reg_s0_live` |
| Retention | `grass_date` 保留 30d |
| Column Count | ~60+ 顶层列（含大量嵌套 struct/array 子字段） |
| Region Coverage | MY, SG, TH, ID, VN, PH, TW, BR, MX (9 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 32 files (20 read + 2 write + 2 view + 8 region variants)
- L7D Query Count: -
- Completeness: -
- Popularity: -
