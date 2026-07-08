<!-- ads-workspace-gdoc-sync: gdoc_id=1FjzGU6-zBTnUjoo7M8r-VCM8aq_7Msd3Go_gwu0xdNE gdoc_url=https://docs.google.com/document/d/1FjzGU6-zBTnUjoo7M8r-VCM8aq_7Msd3Go_gwu0xdNE/edit -->

# mp_paidads.dim_live_stream_abtest_group__reg_s0_live

## Description

- **Desc:** AB实验分流维度表，记录Live Ads场景下每天每个用户的实验分组(group_id)映射关系。数据来源于AB实验分配聚合表和Traffic AB实验命中日志，同时支持标准AB项目(project_id=10)和Live Ads自定义场景。
- **Granularity:** daily x user_id x group_id
- **Use Case:**
  1. Live Ads AB实验用户分组查询 — 通过 user_id JOIN 获取实验 group_id，用于用户级实验效果分析
  2. dws_advertise_user_exp_live_stream_performance_1d__reg_s0_live — Live Ads用户级实验效果DWS表，通过 user_id JOIN 获取分组后按 group_id + placement + entrance + pricing_type 聚合
  3. dws_advertise_user_exp_live_stream_group_performance_1d__reg_s0_live — Live Ads分组级实验效果DWS表，在用户级基础上进一步按 group_id 聚合
  4. 产品点击归因回刷 — 7天窗口内 product_click_order 的延迟归因，通过 user_id + grass_date JOIN 关联实验分组
- **Update Frequency:** Daily

## Key Metrics

N/A — 本表为维度表，仅存储 group_id 和 user_id 的映射关系，不包含指标字段。

## Key Dimensions

- **group_id** (bigint): AB实验用户分组ID，下游聚合的核心维度
- **user_id** (bigint): 用户标识，与效果数据表 JOIN 的关键字段
- **grass_date** (date, partition): 数据日期分区
- **grass_region** (string, partition): 国家/区域分区（ID, MY, PH, SG, TH, TW, VN, BR, CO, CL, MX）
- **tz_type** (string, partition): 时区类型，生产环境固定为 'local'

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (serde: ParquetHiveSerDe) |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | ${HIVE_PATH}/dim_live_stream_abtest_group |
| Retention | - |
| Column Count | 2 (data) + 3 (partition) = 5 |
| Region Coverage | SG, MY, PH, ID, TH, TW, VN, BR, CO, CL, MX (11 regions) |
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

- Studio Tasks References: 35 files (11 write, 24 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
