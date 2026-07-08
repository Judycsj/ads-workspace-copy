<!-- ads-workspace-gdoc-sync: gdoc_id=1GSqWgKA4ezSReoG6HEFD5K9ko6OdKwWkce07YnReeD0 gdoc_url=https://docs.google.com/document/d/1GSqWgKA4ezSReoG6HEFD5K9ko6OdKwWkce07YnReeD0/edit -->

# mkplpaidads_data.dwd_advertise_tracking_shop_hi__reg_s0_live

## Description

- **Desc:** Shop Ads 曝光/点击埋点日志表，记录用户在搜索和推荐场景中对 Shop Ads 的交互行为（曝光、点击），同时包含模型预估分数（pCR/pCTR）和特征数据（bid_rerank_trace, shop_json_data）。属于事件级（request-level）追踪表，按小时增量更新。
- **Granularity:** event-level (per request_id x operation x ads_id x ads_placement)
- **Use Case:**
  - Shop Ads 日常指标计算（CTR/CVR/pCR 统计）— 与 `dwd_advertise_performance_di` 通过 request_id 关联
  - Shop Ads 模型 AUC 评估（按 AB 分桶对比 pCR 排序性能）
  - Game Ads 迁移效果评估（pCOC/AUC/ctcvr/bid 分析）
  - 关键词相关性训练样本生成（过滤 shop_item_id、keywords）
  - 特征质量监控（slot_id null rate/avg_len/overlap_rate 检查）
- **Update Frequency:** Hourly (`_hi` suffix)

## Key Metrics

无直接业务指标列（该表为事件追踪表），核心提取字段包括：
- 预估分数: pCR, pCTR（从 `shop_json_data` JSON 提取）, pcr_0（从 `bid_rerank_trace` JSON 提取）
- 事件计数: 通过 `operation` / `operation_desc` 区分曝光 (1001/SHOP_IMPRESSION) 和点击 (1002/SHOP_CLICK)
- 出价信息: adjusted_bid_price（从 `bid_rerank_trace` JSON 提取）

## Key Dimensions

- 分区: grass_date, grass_region
- 业务: ads_placement (3/20/2003=Shop Ads, 2030=Game Ads, 45), operation (1001=impression, 1002=click), operation_desc (SHOP_IMPRESSION, SHOP_CLICK)
- 实体: shop_id, ads_id, ads_request_id, user_id
- AB实验: ab_sign（实验标签管道符分隔）, ads_entrance

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region (推断) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG, TW, MY, ID, VN, PH, TH, BR (推断) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 40 files (0 write, 40 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
