<!-- ads-workspace-gdoc-sync: gdoc_id=1Ajklb-P6MpecF1OM0cnyDHtvZFq0_rIih1z5yBJthfk gdoc_url=https://docs.google.com/document/d/1Ajklb-P6MpecF1OM0cnyDHtvZFq0_rIih1z5yBJthfk/edit -->

# mp_paidads.dws_advertiser_account_td__reg_s0_live

## Description

- **Desc:** 广告主账户余额累计全量表 (to-date)。每日将当日快照 (`dws_advertiser_account_1d`) 与前一日的 to-date 记录做 FULL OUTER JOIN，通过 COALESCE 优先取当日值，当日无数据时保留历史值，确保每个广告主的最新余额信息始终可用。
- **Granularity:** daily x grass_region x shop_id
- **Use Case:**
  - ads_advertiser_mkt_1d 报表构建 — 提供 low_threshold / is_reach_threshold 余额预警字段
  - 广告主余额状态追踪 — 查询任意广告主最新余额（含 dormant 账户的历史余额）
  - 余额预警触发判断 — 通过 is_reach_threshold 标记当日是否触发过低余额告警
- **Update Frequency:** Daily (INSERT OVERWRITE partition，按 grass_date 逐日覆盖)

## Key Metrics

- 余额类: acc_before_balance, acc_before_balance_usd, acc_after_balance, acc_after_balance_usd
- 阈值类: low_threshold, low_threshold_usd
- 状态类: is_reach_threshold (当日是否触发过低余额告警)

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 业务: user_id, shop_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | `${HIVE_PATH}/dws_advertiser_account_td/tz_type=local/grass_region=${upper_region}` |
| Retention | - |
| Column Count | 10 data columns + 3 partition columns |
| Region Coverage | All 8 regions (ID, MY, PH, SG, TH, TW, VN, BR) + MX/CO/CL (US local) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 26 files (22 write, 4 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
