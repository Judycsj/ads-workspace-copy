<!-- ads-workspace-gdoc-sync: gdoc_id=1-r6Zh_eG6PszWvwgkWesxN5fGY4AcEX3IG7NUCH-W4M gdoc_url=https://docs.google.com/document/d/1-r6Zh_eG6PszWvwgkWesxN5fGY4AcEX3IG7NUCH-W4M/edit -->

# mkplpaidads_offline.cr_train_data

## Description

- **Desc:** Search Ads 点击率（CR）模型训练数据表。每一行代表一次用户-广告点击交互，包含用户行为标签（下单、GMV、加购、券核销等）存储在 `action_info` MAP 列中，上下文元数据编码在 `debug_info` 字符串列中。该表是 Search Ads 和 Discovery Ads 算法团队进行模型训练、特征生产、样本质量监控、券 PCOC 分析的基础数据源。
- **Granularity:** 点击级别 (per user_id x item_id x request_id) x 小时 x 区域
- **Use Case:**
  1. **训练数据与生产数据一致性监控 (Performance Train Data Diff)**：对比 cr_train_data 与 dwd_ads_request_performance_di 的点击/订单/GMV 差异，按入口和广告位维度检测数据丢失率
  2. **特征生产 Label 源 (MOR Feature Production)**：为搜索 Query CVR/CTR 模型特征生产提供 request_id 和 labels，支持多种特征窗口 (1d/3d/7d/30d)
  3. **自然流量占比分析 (Organic Traffic Ratio)**：按 search/rcmd 和 organic/non-organic 分类统计训练样本分布
  4. **券 PCOC 与 UPC 分析 (Voucher PCOC & UPC)**：分析发券预估 (uplift pCR) 与实际核销/转化 (order/redeem/cost) 的校准度，支持券折扣分层 (discount bucket) 和窄口径归因
  5. **延迟反馈分析 (Delay Feedback Labeling)**：基于 clk_timestamp 和 unified_order_create_time 构造 1h/1d/7d 时间窗口标签，评估订单/核销延迟转化
  6. **样本重复检测 (Duplicate Analysis)**：按 user_id+item_id+request_id 聚合检测重复样本，评估训练权重膨胀
- **Update Frequency:** Hourly（离线 Spark 作业按小时写入分区，本表 `mkplpaidads_offline` 为 VIEW 或别名，物理表为 `mkplpaidads_search_ads.cr_train_data`）

## Key Metrics

- 点击类: `action_info.click`
- 订单类: `action_info.ads_direct_order_cnt`, `action_info.ads_shop_order_cnt`, `action_info.org_direct_order_cnt`, `action_info.org_shop_order_cnt`, `action_info.paid_ads_direct_order_cnt`, `action_info.paid_org_direct_order_cnt`
- GMV 类: `action_info.ads_direct_order_gmv`, `action_info.ads_direct_gmv_add`, `action_info.ads_shop_order_gmv`, `action_info.ads_broad_gmv_add` (单位: cent，需 /100000 转实际金额)
- 加购类: `action_info.ads_atc_cnt`, `action_info.ads_shop_atc_cnt`
- 统一口径下单: `action_info.unified_placed_order`
- 券核销类: `action_info.unified_is_redeemed`, `action_info.unified_is_redeemed_narrow_attribution`
- 券成本类: `action_info.unified_voucher_cost`, `action_info.unified_voucher_cost_narrow_attribution`
- 时间戳: `action_info.order_timestamp`, `action_info.update_timestamp`, `action_info.unified_order_create_time`

## Key Dimensions

- 分区维度: `region`, `grass_date`, `grass_hour`
- 入口解析 (debug_info): `ads_entrance`, `placement`, `ads_id`
- 流量类型 (debug_info): `search_info_item_type_str`, `rcmd_info_item_type_str`
- 券相关 (debug_info): `voucher_price`, `item_price`, `uplift_pcr_v`, `voucher_unpicked_reason`
- 时间戳 (debug_info): `clk_timestamp`
- 搜索 query (debug_info): `query` (base64编码)
- 模型标识 (debug_info): `uni_pcr_model_name`
- 用户/商品/请求标识: `user_id`, `item_id`, `request_id`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | region (STRING), grass_date (STRING), grass_hour (STRING) |
| HDFS Path | hdfs://R2/projects/mkplpaidads_search_ads/hdfs/prod/alg/ads/train_data_parquet/cr/all |
| Retention | - |
| Column Count | 7 (user_id, item_id, request_id, action_info, mio_info, dump_time, debug_info) + 3 partitions |
| Region Coverage | ID, SG, MY, TH, PH, TW, VN, BR |
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

- Studio Tasks References: 95 files (0 write, 95 read; 8 workflows + 7 scheduled_tasks + 80 manual_tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
