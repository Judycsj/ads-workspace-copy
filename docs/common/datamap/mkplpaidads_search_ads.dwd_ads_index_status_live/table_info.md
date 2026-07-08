<!-- ads-workspace-gdoc-sync: gdoc_id=1JrTYIHSDpWetRltSdwVhCk-mvkMiDgpnH2Sn2V65IJo gdoc_url=https://docs.google.com/document/d/1JrTYIHSDpWetRltSdwVhCk-mvkMiDgpnH2Sn2V65IJo/edit -->

# mkplpaidads_search_ads.dwd_ads_index_status_live

## Description

- **Desc:** 广告投放状态明细表，记录广告在索引中的状态变更事件。整合 index_log（索引操作日志）、campaign_audit（计划审核事件）和 index_ads_info_log（流量控制异常）三个数据源，按 ads/item/campaign/shop 四种粒度输出状态变更时间线。
- **Granularity:** daily × id × type × status × timestamp × grass_region（事件级明细，每条记录为一次状态变更事件）
- **Use Case:** 广告诊断 seller operation 特征构建（dws_seller_operation_agg_daily）、广告异常排查、预算/TROI 变更分析、campaign 暂停/停止统计
- **Update Frequency:** Daily（per-region 分区覆写）

## Key Metrics

- 本表为事件明细表，不含聚合指标
- 下游常用聚合：campaign_pause_cnt, campaign_stop_cnt, troi_increase/decrease_cnt, budget_increase/decrease_cnt

## Key Dimensions

- 分区: grass_date, grass_region
- 业务: type (1=ads, 2=item, 3=campaign, 4=shop), status (0-8), operation (INDEX/DELETE)
- 实体: id (多义字段，含义取决于 type)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (PySpark insertInto) |
| Partition Columns | grass_date, grass_region |
| HDFS Path | hdfs://R2/projects/mkplpaidads_search_ads/hive/mkplpaidads_search_ads/dwd_ads_index_status_live |
| Retention | Permanent |
| Column Count | 10 |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR |
| DQC Status | - |
| Table Size | 92.56 GB |
| Table Type | MANAGED_TABLE |
| LakeHouse Type | Hive |

## Business Properties

| Property | Value |
|----------|-------|
| Business PIC | qianqian.pu@shopee.com |
| Technical PIC | qianqian.pu@shopee.com |
| Team | mkplpaidads |
| Project | Search Ads (mkplpaidads_search_ads) |
| Business Domain | - |
| DW Layer | DWD |
| Market Region | REG |

## Popularity

- Studio Tasks References: 23 files
- L7D Query Count: 112
- Completeness: 12.00
- Popularity: 83.60
