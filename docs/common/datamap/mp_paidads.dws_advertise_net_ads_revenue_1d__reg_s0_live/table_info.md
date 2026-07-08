<!-- ads-workspace-gdoc-sync: gdoc_id=182vyPi5hlEVmM603vMb9TiudxkcDdoRO1jY6AQrUuhk gdoc_url=https://docs.google.com/document/d/182vyPi5hlEVmM603vMb9TiudxkcDdoRO1jY6AQrUuhk/edit -->

# mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live

## Description

- **Desc:** 广告净收入日表（DWS层），记录每个 shop/ads/entry_point/pricing_type 维度下的广告收入明细，包括付费充值收入、展示广告收入、免费信用收入、过期和税费，并拆到 SCS/SIP/Lovito/Gov 四类免费信用来源。核心净收入公式：`net_ads_revenue = paid + display + free_revenue + paid_expire + free_expired - tax_on_free`
- **Granularity:** daily x shop_id x ads_id x entrance x placement x pricing_type x sub_push_type x credit_order_type (含付费/免费信用拆解)
- **Use Case:**
  - Take Rate 日报：按 shop_id 聚合计算净广告收入 take rate（`net_ads_revenue / platform_gmv`）
  - OKR 收入追踪：分 entry_point/pricing_type 的净收入
  - Incentive/返利分析：按 shop 汇总收入，评估激励活动效果
  - 收入对账与数据质量校验：对比 raw_gross vs net/gross 口径差异
  - 搜索广告效果分析：按 traffic_type/product_type 分析搜索/发现等场景
- **Update Frequency:** Daily

## Key Metrics

- 净收入: `net_ads_revenue_usd_1d`
- 毛收入: `gross_ads_revenue_usd_1d`, `raw_gross_ads_revenue_usd_1d`
- 付费充值: `paid_credit_revenue_usd_1d`, `paid_credit_expire_amt_usd_1d`
- 展示广告: `display_ads_revenue_usd_1d`
- 免费信用收入: `others_free_credit_revenue_usd_1d`, `free_credit_deduction_amt_usd_1d`, `free_ads_revenue_amt_usd_1d`
- 免费信用过期: `others_free_credit_expired_amt_usd_1d`
- 税费: `tax_paid_on_free_credit_revenue_usd_1d`
- SCS 免费信用: `scs_free_credit_revenue_usd_1d`, `scs_free_credit_expired_amt_usd_1d`
- SIP 免费信用: `sip_free_credit_revenue_usd_1d`, `sip_free_credit_expired_amt_usd_1d`
- Lovito 免费信用: `lovito_free_credit_revenue_usd_1d`, `lovito_free_credit_expired_amt_usd_1d`
- Gov 免费信用: `gov_free_credit_revenue_usd_1d`, `gov_free_credit_expired_amt_usd_1d`
- 抵扣价: `deduction_price_usd`, `voucher_deduction_price_usd`

## Key Dimensions

- 分区: `tz_type`, `grass_region`, `grass_date`
- 广告主体: `shop_id`, `ads_id`, `campaign_id`, `item_id`, `ab_sign`
- 入口/流量: `entry_point`, `entry_point_v2`, `entrance`, `sub_entrance`, `placement`, `traffic_type`, `new_boost`
- 出价类型: `pricing_type`
- 产品分类: `sub_product_type`, `product_type`, `main_product_type`
- 卖家属性: `seller_type`, `seller_type_1p`, `is_cb_shop`, `is_cb_sip_affiliated`, `is_local_sip_affiliated`
- 信用维度: `sub_push_type`, `push_type`, `credit_order_type`, `credit_order_type_name`, `credit_reason`, `credit_topup_sub_type`, `credit_topup_sub_type_name`, `is_package_topup`, `is_voucher_topup`, `credit_program_id`, `credit_program_name`, `credit_operator`, `voucher_name`, `credit_topup_type_name`, `voucher_id`, `brand_max_ads_type`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (STRING), grass_region (STRING), grass_date (DATE) |
| HDFS Path | `${HIVE_PATH}/dws_advertise_net_ads_revenue_1d` |
| Retention | - |
| Column Count | 57 |
| Region Coverage | BR, ID, MY, PH, SG, TH, TW, VN, CO, CL, AR, MX, US (via separate region workflows) |
| DQC Status | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 111 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
