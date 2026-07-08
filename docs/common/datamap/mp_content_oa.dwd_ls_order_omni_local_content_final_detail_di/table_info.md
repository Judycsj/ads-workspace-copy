<!-- ads-workspace-gdoc-sync: gdoc_id=1yZqehxRhij3hKjsslthx2V1MFWVtPTR7Qdn4dQSKW8k gdoc_url=https://docs.google.com/document/d/1yZqehxRhij3hKjsslthx2V1MFWVtPTR7Qdn4dQSKW8k/edit -->

# mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di

## Description

- **Desc:** Live Streaming 内容归因订单明细表（DWD 层）。记录通过 Live Streaming (直播) 会话产生的内容相关订单，按 order 粒度提供 omni-channel 归因数据，包含订单金额、order fraction、主播/店铺/买家信息、归因类型（direct/indirect）等字段。
- **Granularity:** order x grass_date x grass_region x tz_type
- **Use Case:**
  - Live Ads 订单归因：提取 Live Streaming 内容直接/间接带来的订单数和 GMV (`content_live_details` CTE)
  - Omni-channel 效果分析：区分 ads vs organic 归因，按 common_feature 维度 (Live Streaming/Global Search/YMAL/DD等) 分析效果
  - 主播级直播效果评估：按 order_ls_streamer_id 汇总订单和 GMV (`order_base` CTE)
- **Update Frequency:** Daily (推测，基于 di 后缀和 tz_type='local' 过滤)
- **Data Source:** Live Streaming 内容团队 (mp_content_oa 库) 生产，不在 paidads-alg 代码库中维护

## Key Metrics

from-code 提取自 `content_live_details` 和 `order_base` CTE 的派生指标：

- **订单类**: total_ls_order_fraction (订单份额), ls_order_fraction (直播订单份额)
- **金额类**: gmv (本币), gmv_usd (美元)
- **数量类**: item_amount (商品数量)
- **归因维度**: order_cal_type (direct/indirect), order_other_supply (omni)

## Key Dimensions

from-code 提取自 WHERE/GROUP BY 子句：

- **分区**: grass_date, grass_region, tz_type
- **内容维度**: from_source_page (来源页面，如 'streaming_room'), is_content_directly_related (是否内容直接相关)
- **订单维度**: order_platform, app_version, order_item_id, order_buyer_id, order_shop_id, order_ls_streamer_id, order_ls_session_id
- **归因维度**: order_cal_type (direct/indirect), order_other_supply, entry_point, scene

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL 未在 paidads-alg 代码库中找到) |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | 多区域 (from-code: upper('${region}') 模式，支持 multi-region) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 4 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
