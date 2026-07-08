<!-- ads-workspace-gdoc-sync: gdoc_id=1MDqdJgQ_cTLptELez-dCoSd29AiAYZhJ9Y4UteKxR08 gdoc_url=https://docs.google.com/document/d/1MDqdJgQ_cTLptELez-dCoSd29AiAYZhJ9Y4UteKxR08/edit -->

# mp_paidads.dws_advertiser_livestream_revenue_td__reg_s0_live

## Description

- **Desc:** 直播广告主累计收入（To Date）宽表，记录每个广告主的历史累计消耗（total_expenditure_amt_usd_td）、首次/最近直播广告日期等核心指标。数据每日更新，每个分区为截至当日的累计快照。属于 DWS 汇总层，为下游直播广告主分层、新老客标签、ROI 指标计算等提供数据源。
- **Granularity:** daily x shop_id x grass_region（每个 shop 每天一条记录）
- **Use Case:**
  - 直播广告主收入分层（按收入百分位划分 Rev Tier）
  - 直播广告主新老客标签计算（today_new_advertiser_status, month_new_advertiser_status）
  - 计算不同时间窗口的累计消耗（365天、当月、上月、过去12个月）：通过 self-join 多快照差值
  - 追踪广告主首次和最近直播广告日期
  - 广告主直播广告今天是否有消耗（is_rev_today）判断
- **Update Frequency:** Daily

## Key Metrics

从实际 SQL 使用场景归纳：

- 累计消耗类: `total_expenditure_amt_usd_td` (累计消耗 USD，To Date)
- 广告主日期标记: `streamer_first_live_ads_date` (首次直播广告日期), `streamer_last_live_ads_date` (最近直播广告日期)

## Key Dimensions

- 分区: `grass_date`, `grass_region`, `tz_type`
- 业务主键: `shop_id`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | VN, TW, TH, SG, PH, MY, ID (7 regions from codebase usage) |
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

- Studio Tasks References: 14 files (all in deprecated workflows)
- L7D Query Count: -
- Completeness: -
- Popularity: -
