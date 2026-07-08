<!-- ads-workspace-gdoc-sync: gdoc_id=1UnZ1oa3Jsx8jic66TQAY8ZbiRz5ANU0HuWbzDEH8ETw gdoc_url=https://docs.google.com/document/d/1UnZ1oa3Jsx8jic66TQAY8ZbiRz5ANU0HuWbzDEH8ETw/edit -->

# mp_paidads.ods_shopee_paidads_suggest_log

## Description

- **Desc:** 搜索广告 suggest bid 原始日志表 (ODS 层)。记录每次 suggest bid 推荐事件，包含出价建议、bid 版本（V1/V2）、阶段（suggest/applied）、bid 价格组成（impression/order 价格、ECR、目标 CIR、item 价格）等信息。数据由上游 suggest bid 服务写入。
- **Granularity:** event-level（每条记录为一个 suggest bid 事件）
- **Use Case:**
  - Suggest bid V1 vs V2 版本出价分布对比
  - Suggest bid whitelist 灰度效果评估（before/after bid price 对比）
  - 关键词级 suggest bid 异常排查（最小 bid、零 bid、order price > impr price）
  - shopper 行为分析（adoption rate、overbid/underbid）
  - 作为 base table JOIN 到 performance 表做 campaign 级分析
- **Update Frequency:** 实时写入（上游 suggest bid 服务触发）

## Key Metrics

- Suggest bid 价格: `price`（本地货币 * 100000），转换公式 `price * 1.0 / 100000`
- bid_price_for_impr: `json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.bid_price_for_impr')` * 1.0 / 100000
- bid_price_for_order: `json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.bid_price_for_order')` * 1.0 / 100000
- ecr: `json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.ecr')`
- item_price: `json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.item_price')` * 1.0 / 100000
- target_cir: `json_extract_scalar(extinfo_v2, '$.bid_price_extinfo.target_cir')`

## Key Dimensions

- 分区: grass_date, grass_region
- 业务: bid_version (v1/v2), stage (0=suggest, 1=applied), page, placement, keyword, shop_id, ads_id, item_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | Multi-region: SG, MY, TH, TW, ID, VN, PH, BR, MX, CO, CL |
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

- Studio Tasks References: 20 files (20 read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
