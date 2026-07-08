<!-- ads-workspace-gdoc-sync: gdoc_id=1tJoUnHb7Xa0oMtENm9TtHnUPP5G0IyVP1dt-MRvJIC0 gdoc_url=https://docs.google.com/document/d/1tJoUnHb7Xa0oMtENm9TtHnUPP5G0IyVP1dt-MRvJIC0/edit -->

# mkplpaidads_search_ads.ads_smart_voucher_blacklist_user

## Description

- **Desc:** Smart Voucher 用户分群标签表，存储各区域 Smart Voucher AB 实验中每个用户的实验分组（control 或 mp_plus_ads），供下游 AB 实验效果分析使用。数据由各区域独立 workflow 分别写入，每个区域的上游来源表不同（BR 用 smart_abt_user_list，ID 用 fpa_spl_cashback_dim，SG 用 smart_abt_user_split，TH 用 dwd_shp_smart_voucher_user_pool，VN 用 dim_crm_user_task_view，MY 用 mpi_pi_smart_voucher_all_user_group_list，PH 用 smart_voucher_userlist_pc），统一聚合到本表。
- **Granularity:** daily x grass_region x user_id (每行一个用户在某天某区域的分组)
- **Use Case:**
  - User tag 分区完整性监控：检查 T/T+1/T+2/T+3 分区数据是否存在，缺失时通过 SeaTalk 告警
  - AB 实验效果分析：作为用户标签 join 到平台用户指标表/广告效果表/券消耗表，对比 control 与 mp_plus_ads 组在 GMV、广告消耗、券成本等指标上的差异
  - 用户分群分布查询：按 region + group_name 统计各组用户数
- **Update Frequency:** Daily (各 region workflow 独立调度，每日写入 T+1/T+2/T+3 预先分区)

## Key Metrics

本表为用户-分群映射表，无指标字段。所有列为维度/标签。

## Key Dimensions

- 分区: `grass_date` (数据日期), `grass_region` (区域)
- 业务: `group_name` — 用户实验分组，枚举值 `control` / `mp_plus_ads`
- 用户: `user_id` — 用户标识

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET (SNAPPY compression) |
| Partition Columns | grass_date DATE, grass_region STRING |
| HDFS Path | - |
| Retention | - |
| Column Count | 4 (2 data columns + 2 partition columns) |
| Region Coverage | BR, ID, MY, PH, SG, TH, VN (7 regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ADS |

## Popularity

- Studio Tasks References: 27 files (9 write, 18 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
