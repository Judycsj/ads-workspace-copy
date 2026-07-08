<!-- ads-workspace-gdoc-sync: gdoc_id=1USzr0nooUA6zWT1Z38fFyaqQ7pQZWr4mhh3fo7cgGW0 gdoc_url=https://docs.google.com/document/d/1USzr0nooUA6zWT1Z38fFyaqQ7pQZWr4mhh3fo7cgGW0/edit -->

# mkplpaidads_search_ads.dwd_uplift_click_conversion_hi

## Description

- **Desc:** Uplift 模型点击-转化小时明细宽表，解码 ODS 日志中的 bid_rerank_trace JSON 字段，提取 pCR 输出（`uplift_pcr0` + `uplift_pcr_ratio1~6` 映射为 pcr_0~pcr_20）、platform GMV 输出、redeem_rate 输出、ROI3 traffic bucket、voucher 信息和 AB signature，并关联 1 小时内 direct order 转化标签。为 uplift 建模/评估/监控链路提供 click-level 样本。
- **Granularity:** hourly x grass_region x request_id (click-level)
- **Use Case:**
  - Uplift 模型 RCT PCOC / AUUC 评估（cr_uplift_rct_pcoc, cr_uplift_rct_auuc）
  - L2 Category / Item / Shop 三级 response prior 特征生产（uplift_l2_item_shop_response_prior_new）
  - 用户券敏感度画像（dws_uplift_user_sensitivity_daily_di → dws_uplift_user_sensitivity_portrait_di）
  - 按小时/券桶聚合的 voucher 与 uplift score 监控（cr_uplift_model_*_by_hour）
  - Continuous discount 在线评估（cr_uplift_continuous_discount_eval_detail_di）
- **Update Frequency:** Hourly (T+1h), per-region parallel

## Key Metrics

- 点击类: deduplicated_click (去重点击, 0/1)
- 转化类: direct_order_1h (1小时内 direct order 数, 0/1)
- 模型 pCR 预测: pcr_0 (baseline), pcr_02/pcr_05/pcr_08/pcr_12/pcr_15/pcr_20 (各折扣档 uplift 预测), pcr_v (strategy-adjusted)
- 模型 GMV 预测: platform_gmv_0, platform_gmv_ratio_1~platform_gmv_ratio_7
- 模型券核销率预测: redeem_rate_1~redeem_rate_7
- 券信息: voucher_price (面额 x 1e5), pgmv (预估 GMV x 1e5), discount_ratio, voucher_unpicked_reason, is_ads_voucher_redeemed, reward_discount
- 流量/实验标识: roi3_traffic_bucket, model_roi3_bucket, signature

## Key Dimensions

- 分区: grass_region, grass_date, h
- 主键: request_id, user_id, item_id
- 广告标识: ads_id, entrance, pricing_type
- AB 标识: signature (AB signature from ods_log_ads_report_hi)
- 券实验: voucher_unpicked_reason (17/99=control, 18=treatment, 其他=strategy), discount_ratio → voucher_bucket

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | grass_region, grass_date, h |
| HDFS Path | hdfs://R2/projects/data_paidadsmart/ (推断) |
| Retention | - |
| Column Count | 44 (41 data + 3 partition) |
| Region Coverage | ID, MY, PH, TH, SG, TW, VN, BR (8 regions) |
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

- Studio Tasks References: 38 files (15 workflows, 2 scheduled, 21 manual)
- L7D Query Count: -
- Completeness: -
- Popularity: -
