<!-- ads-workspace-gdoc-sync: gdoc_id=1jUt9IZIiLLU28QtbqeThDYFdUi5RpfD_A_B7lqCEuxY gdoc_url=https://docs.google.com/document/d/1jUt9IZIiLLU28QtbqeThDYFdUi5RpfD_A_B7lqCEuxY/edit -->

# mp_paidads.ods_shopee_ads_db__topup_translog_tab_df__reg_s0_live

## Description

- **Desc:** ODS 层表，从 MySQL `shopee_ads_db.topup_translog_tab` 全量同步至 Hive。记录所有广告充值/信用金交易流水，包括普通充值、套餐购买、代金券、免费信用金、SVS 充值等。每行代表一笔充值交易订单。
- **Granularity:** 单笔交易订单 (order_id)
- **Use Case:**
  1. **dwd_advertiser_credit_topup_df**: 构建广告主充值信用金全量表 (DWD)，关联 credit subtype、manual credit、ads credit、汇率等维度表，按 region 拆分写入
  2. **dwd_order_escrow_di**: 订单托管流水关联，查找 order_type=28 (自动托管) 的充值交易记录
  3. **SVS 充值异常分析**: ad-hoc 查询分析 SVS 充值 (order_type=6) 的用户频次和金额分层
  4. **Credit 来源追踪**: 查询特定 account 的充值来源、金额、订单类型 (topup wallet, SVS, SRM 等)
  5. **Rebate/返利关联**: 查询特定 shop 的 topup 记录用于返利对账
- **Update Frequency:** Daily (按日分区全量快照, `df` = daily full)

## Key Metrics

- 充值交易类: amount (本地货币 x100000), order_type, status, notified
- 充值金额 (推导): topup_amt = amount/100000.0 (local currency), topup_amt_usd = topup_amt / exchange_rate
- 套餐相关: original_price, discount_price, package_id, package_expiry
- 代金券相关: voucher_id, voucher_amount, voucher_expiry
- SVS 实体: svs_entity_type, svs_entity_id (从 decoded_extinfo JSON 解析, schema-evolved 字段)
- 广告套餐: ads_package_id (schema-evolved 字段)

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 业务: order_type, order_id, userid, shopid, status
- 时间: order_time (unix timestamp), create_datetime (推导)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (spark.sql.parquet.mergeSchema=true) |
| Partition Columns | tz_type (STRING), grass_region (STRING), grass_date (DATE) |
| HDFS Path (SG/R2) | hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/ods_shopee_ads_db__topup_translog_tab_df__reg_s0_live |
| HDFS Path (US/D2) | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/ods_shopee_ads_db__topup_translog_tab_df__reg_s0_live |
| DDL Column Count | 15 (explicit) + 3 partition, evolved to ~17+ via mergeSchema |
| Retention | - |
| Region Coverage | SG, MY, PH, VN, ID, TH, TW, BR (标准 8 区) + MX, CO, CL, AR (US 集群附加区) |
| Table Comment | "table for keyword audit" (from DDL) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | Ads Credit/Topup |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: ~60 files (~25 ODS DDL, ~25 workflow reads, ~15 ad-hoc reads)
- L7D Query Count: -
- Completeness: -
- Popularity: -
