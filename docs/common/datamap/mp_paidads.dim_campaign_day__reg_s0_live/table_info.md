<!-- ads-workspace-gdoc-sync: gdoc_id=1G5BKAT6nYzIkDdzR9btnE0BUCrKfPGle3SNXZtHw74A gdoc_url=https://docs.google.com/document/d/1G5BKAT6nYzIkDdzR9btnE0BUCrKfPGle3SNXZtHw74A/edit -->

# mp_paidads.dim_campaign_day__reg_s0_live

## Description

- **Desc:** 广告大促日维表，记录每个 Campaign 在活跃期间内每一天的日期。通过将 campaign 的 `start_time` 到 `end_time` 展开为逐日记录，供下游任务排除大促日对日常指标的干扰。
- **Granularity:** daily x campaign x region (+ tz_type)
- **Use Case:**
  - 排除大促日计算日常指标（ROI、GMV、转化率等）：LEFT JOIN 后 WHERE campaign_day IS NULL 或 NOT IN
  - 诊断分析中排除大促日计算基线订单量
  - 正向操作提升效果分析中标记当天是否为 campaign day
  - 潜在商品推荐中统计各窗口期的大促天数用于指标归一化
  - 广告效果数据分析中，区分 campaign 日和普通日的绩效数据
- **Update Frequency:** Daily

## Key Metrics

N/A (维度表，不包含业务指标)

## Key Dimensions

- **业务主键:** id (campaign_day_tab ID), campaign_name
- **分区:** tz_type, grass_region, grass_date
- **时间:** start_time, end_time, campaign_day

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | `${HIVE_PATH}/dim_campaign_day__reg_s0_live/` |
| Retention | - |
| Column Count | 5 data columns + 3 partition columns |
| Region Coverage | Multi-region (SG, MY, ID, TH, VN, PH, TW, BR, MX, CO, CL) |
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

- Studio Tasks References: 95 read, 11 write
- L7D Query Count: -
- Completeness: -
- Popularity: -
