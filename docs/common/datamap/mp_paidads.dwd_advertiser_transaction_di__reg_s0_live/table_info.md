<!-- ads-workspace-gdoc-sync: gdoc_id=1uEC0CCpw9fpGtUdAyiMqcrgHH9HJZeFW8gAhGl3ueLI gdoc_url=https://docs.google.com/document/d/1uEC0CCpw9fpGtUdAyiMqcrgHH9HJZeFW8gAhGl3ueLI/edit -->

# mp_paidads.dwd_advertiser_transaction_di__reg_s0_live

## Description

- **Desc:** 广告主交易明细表 (Advertiser Transaction Detail)，记录每个广告每次扣费、充值操作的流水明细。数据来源于 translog 日志表，关联广告维表补充 campaign/ads_type/ads_status 等信息。是广告收入核算和账户余额监控的基础 DWD 层表。
- **Granularity:** 单次交易 (event) x ads_id x placement x grass_region x tz_type x grass_date
- **Use Case:**
  - 广告主账户余额监控与预警 (`dws_advertiser_account_1d`)：计算每日最低余额，判断是否触及阈值
  - 广告花费扣除明细分析 (`dwd_advertiser_deduction_di`)：按 paid/free、with/without expiry 分解广告花费
  - 广告作弊/欺诈检测 (`dwd_advertise_fraud_di`)：识别有扣费但无有效曝光的虚假流量
  - 广告花费汇总 (`dws_advertise_deduction_1d`)：按 ads 维度汇总 paid/free expenditure
  - 数据质量校验：新旧表数据一致性对比
- **Update Frequency:** Daily

## Key Metrics

- 扣费类: price_local (交易金额), 下游提取 deduction_price, voucher_deduction_price
- 余额类: acc_before_balance_local, acc_after_balance_local, dai_before_balance_local, dai_after_balance_local
- 竞价类: pctr (预估CTR), bid_price (出价), second_ads_ecpm (第二名eCPM)
- 花费分解 (from paid_free_expiry_summary JSON): 按 type=1/2/3/4 分解为 paid_wo_expiry / paid_w_expiry / free_wo_expiry / free_w_expiry
- CPS 指标 (from decoded_extinfo JSON): cps_total_expenditure_amt, cps_available_budget, valid_balance_amt, available_balance_amt

## Key Dimensions

- 分区: grass_date (日), grass_region (站点), tz_type (local/regional)
- 事件类型: event_code (1-11), event_type (deduction/topup_from_order/topup_manual/...)
- 广告维度: ads_id, campaign_id, placement, ads_type, ads_status, entrance, pricing_type
- 用户维度: user_id, shop_id
- 搜索维度: keywords, user_query, match_type, recall_type, sort_type, entrance

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (DDL not found in codebase) |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | - |
| Retention | - |
| Column Count | ~44 |
| Region Coverage | SG, MY, ID, PH, TH, TW, VN, BR, MX (Asia) + CO, CL, AR (US) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 126 files (11 write, 115 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
