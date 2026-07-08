<!-- ads-workspace-gdoc-sync: gdoc_id=1BkmBlzQ2RDoUfHzRHqJb6gi6VbxpJ4_tQYQ13yDLbaY gdoc_url=https://docs.google.com/document/d/1BkmBlzQ2RDoUfHzRHqJb6gi6VbxpJ4_tQYQ13yDLbaY/edit -->

# mp_paidads.dws_advertise_display_ads_revenue__reg_s0_live

## Description

- **Desc:** Display Ads 广告效果收入明细表，记录每日每个 display ad 的展示、点击、预估 CPM 和消耗金额。数据来源于实时竞价日志（ods_log_ads_report_hi），按 placement=9（Display Ads）过滤，关联 display ads 维表获取 shop 和预算信息，并通过汇率表转换为 USD。是下游净收入计算和 Display Ads 效果报表的核心上游表。
- **Granularity:** daily x ads_id x entrance x pricing_type x placement x tz_type x grass_region
- **Use Case:**
  1. Display Ads 净收入计算 -- `dws_advertise_net_ads_revenue_1d` 读入 raw_display_ads_revenue_usd_1d
  2. Display Ads campaign 效果报表 -- `dws_display_ads_performance_di` 读入 expense_before_tax / expense_after_tax
  3. Display Ads 实时竞价费用追踪 -- 按 ads_id + placement=9 维度查询每日消耗
  4. 汇率换算 -- 通过关联 `dim_exchange_rate` 提供 local 和 USD 双币种金额
  5. Display Ads cost per metric 计算 -- 用于 ROI 和 eCPM/eCPC 派生指标
- **Update Frequency:** Daily (schedule via studio workflow, regional + local tz_type partitions)
- **Owner:** Data Warehouse Team (data_paidadsmart)

## Key Metrics

- **曝光效果**: `impression_cnt` (总曝光数), `click_cnt` (总点击数)
- **出价与消耗**: `estimate_cpm_local` (预估 CPM-本币), `estimate_cpm_usd` (预估 CPM-USD), `expense_amt_local` (消耗金额-本币), `expense_amt_usd` (消耗金额-USD)

## Key Dimensions

- **分区**: `grass_date` (日期), `tz_type` (时区类型: regional/local), `grass_region` (地区)
- **广告标识**: `ads_id`, `campaign_id`, `shop_id`
- **广告属性**: `entrance` (入口), `pricing_type` (出价类型), `placement` (广告位, 固定=9 Display Ads)
- **预算窗口**: `budget_start_datetime`, `budget_end_datetime`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | `${HIVE_PATH}/dws_advertise_display_ads_revenue` |
| Retention | - |
| Column Count | 15 (12 data + 3 partition) |
| Region Coverage | BR, ID, MX, MY, PH, SG, TH, TW, VN |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWS |

## Popularity

- Studio Tasks References: 58 files (16 write, 42 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
