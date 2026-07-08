<!-- ads-workspace-gdoc-sync: gdoc_id=1_XWcyCQaIMD5hb8ONzB_aKvqZRkMlVVa7Kvf2CcUeHY gdoc_url=https://docs.google.com/document/d/1_XWcyCQaIMD5hb8ONzB_aKvqZRkMlVVa7Kvf2CcUeHY/edit -->

# Columns: mp_paidads.ads_advertise_take_rate_v2_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

跨 entry_point/pricing_type 聚合时必须用 SUM(DISTINCT)：
- `platform_gmv`, `platform_gmv_excl_testorder` — 平台 GMV 在所有 entry_point 共享同一个值
- `platform_imp` — 平台总曝光量
- `entry_point_imp` — 各入口曝光量（跨 pricing_type 时需 DISTINCT）
- `ads_voucher_omni_platform_nmv_cost_usd` — 全维度只有一个总值，只能 MAX 或 SUM(DISTINCT)

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| pricing_type | 1, 2 | Manual |
| pricing_type | 3, 4 | Simple |
| pricing_type | 7 | Autoboost |
| pricing_type | 8 | Target ROI1 |
| pricing_type | 9, 10, 14 | Live Ads |
| pricing_type | 11 | Target ROI2 |
| pricing_type | 13 | NPB |
| pricing_type | 15 | Simple ROI2 |
| pricing_type | 18 | ROI3 |
| entry_point | Shop / Shop Game / Display | Shop Ads 产品线 |
| traffic_type | Search | search 流量 |
| traffic_type | Video | video 流量 |
| traffic_type | Livestream | live 流量 |
| traffic_type | Daily Discover | dd 流量 |
| traffic_type | You May Also Like | ymal 流量 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: `'regional'` (~70% 查询) / `'local'` (ROI3/Live Ads)
- `pricing_type`: `9,10,14` (Live Ads) / `18` (ROI3) / `1,2` (Manual) / `11` (Target ROI2)
- `seller_type_1p`: OKR 排除 `'Local SCS'`, `'SCS'`, `'Lovito'`
- `grass_region`: 标准 8 区 `'ID','MY','PH','SG','TH','TW','VN','BR'`
- `entry_point`: Live Ads 入口 `'Livestream Discovery'`, `'Livestream For You'`, `'Livestream Homepage'`, `'Livestream PDP'`, `'Livestream Autolanding'`, `'Livestream Video Feed'`

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_region | string | grass_region ｜ 国家分区 [PARTITION] | 2519/5184/11114 |  |
| 2 | grass_date | date | grass_date &#124; 日期分区 [PARTITION] | 2519/5184/11114 |  |
| 3 | tz_type | string | tz_type [PARTITION] | 2519/5184/11113 |  |
| 4 | entry_point | string | This column categorizes the entry points  ｜ 对入口点进行分类。 | 1033/2887/6461 | You May Also Like |
| 5 | traffic_type | string | ads traffic type, split by entrance | 909/2605/5725 | You May Also Like |
| 6 | net_ads_rev_usd | double | net deduction amt, logic can refer to https://sites.google.com/shopee.com/paid-ads-data/ads-domain-knowledge/finance/net-revenue-gross-revenue | 1459/2781/5333 | 76954.60230999984 |
| 7 | entry_point_imp | bigint | This column counts the number of entry point impressions &#124; 此列统计入口点展示次数。 | 1012/2151/5107 | 147183632 |
| 8 | ads_rev_usd | double | net advertising revenue for the day，calculated after tax, In USD currency ｜ 当天广告净收入，含税，美元货币 | 1095/2083/4268 | 81346.9284249999 |
| 9 | ads_imp | bigint | ads impressions &#124; 广告展示次数 | 1227/2092/4184 | 6953281 |
| 10 | platform_gmv_excl_testorder | double | This column shows the Gross Merchandise Volume (GMV) from the platform, excluding test orders ｜ 此列显示平台商品交易总额 (GMV)，不包括测试订单。 | 1400/2177/4098 | 11603874.739964373 |
| 11 | gross_ads_rev_usd | double | gross rev, logic can refer to https://sites.google.com/shopee.com/paid-ads-data/ads-domain-knowledge/finance/net-revenue-gross-revenue ｜ 毛收入 | 1214/2380/3823 | 81346.92842499992 |
| 12 | ads_click | bigint | ads clicks &#124; 广告点击, computational logic： sum(case when pricing_type in (9,10,14,19) then ifnull (raw_click, 0)              when pricing_type = 20 then ifnull (cps_dedup_click, 0)  else ifnull (click, 0) end) | 1060/1822/3594 | 494849 |
| 13 | pricing_type | int | pricing type of ads | 603/1423/3298 | 27 |
| 14 | ads_gmv_usd | double | Covers the calculated gross merchandise value (GMV) for ads in USD, &#124; 广告总的GMV，以美元计价 | 934/1541/2994 | 581571.879529 |
| 15 | platform_gmv | double | The Gross Merchandise Value of the order expressed. Changing the payment method will change the buyer_txn_fee and hence affect the gmv collected from the buyer. GMV = buyer_paid_shipping_fee + merchandise_subtotal_amt + tax_payable + insurance_subtotal_amt + buyer_txn_fee + buyer_service_fee - promotion_fees. The data unit is USD. | 621/1188/2918 | 11617265.43800669 |
| 16 | sub_product_type | string | ads sub product line, split by pricing_type + placement | 334/1386/2698 | video_roi2.0 |
| 17 | ads_order | bigint | This column indicates the number of orders related to advertisements ｜ 广告产生的订单量 | 603/1178/2548 | 26572 |
| 18 | platform_imp | bigint | This column represents the number of impressions on the platform ｜ 平台大盘上的展示次数 | 562/1111/2535 | 251848181 |
| 19 | seller_type_1p | string | 1-party store type for shop | 541/1062/2388 | Unknown |
| 20 | net_ads_rev_excl_sip_usd_1d | double | net ads deduction amt exclude sip deduction amt ｜ 净广告扣除额不包括SIP扣除额 | 506/991/2232 | 76954.60230999984 |

### 查询频率分析

Top 20 高频字段可归纳为以下主题：

1. **分区键**（L30D 11k+）：`grass_date`、`grass_region`、`tz_type` — 几乎所有查询必带的过滤条件
2. **流量入口与产品线**（L30D 2.7k–6.5k）：`entry_point`、`traffic_type`、`sub_product_type`、`pricing_type` — 用于按广告产品维度切分分析
3. **广告收入指标**（L30D 2.2k–5.3k）：`net_ads_rev_usd`、`ads_rev_usd`、`gross_ads_rev_usd`、`net_ads_rev_excl_sip_usd_1d` — Take Rate 计算的核心分子
4. **广告效果指标**（L30D 2.5k–5.1k）：`ads_imp`、`ads_click`、`ads_order`、`entry_point_imp` — 广告漏斗分析
5. **平台大盘指标**（L30D 2.5k–4.1k）：`platform_gmv_excl_testorder`、`platform_gmv`、`platform_imp` — Take Rate 计算的分母（平台 GMV）
6. **卖家属性**（L30D 2.4k）：`seller_type_1p` — 用于区分 1P/3P 卖家的 Take Rate 差异

使用模式：该表是广告 Take Rate 分析的核心数据源，查询主要围绕"广告收入 / 平台 GMV"的 Take Rate 计算，按入口、产品线、卖家类型等维度拆解。高频查询同时包含广告侧和平台侧指标，体现了 Take Rate 分析需要同时关注分子（广告收入）和分母（平台 GMV）的特点。

> MAX(column): MAX() aggregated values from grass_date=2026-03-25, grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| entry_point | string | This column categorizes the entry points  ｜ 对入口点进行分类。 | 1033/2887/6461 | You May Also Like |
| entry_point_imp | bigint | This column counts the number of entry point impressions &#124; 此列统计入口点展示次数。 | 1012/2151/5107 | 147183632 |
| ads_imp | bigint | ads impressions &#124; 广告展示次数 | 1227/2092/4184 | 6953281 |
| ads_order | bigint | This column indicates the number of orders related to advertisements ｜ 广告产生的订单量 | 603/1178/2548 | 26572 |
| ads_click | bigint | ads clicks &#124; 广告点击, computational logic： sum(case when pricing_type in (9,10,14,19) then ifnull (raw_click, 0)              when pricing_type = 20 then ifnull (cps_dedup_click, 0)  else ifnull (click, 0) end) | 1060/1822/3594 | 494849 |
| raw_ads_rev_usd | double | This column represents the total raw advertising revenue generated in USD &#124; 表示以美元计算的原始广告总收入 | 296/568/1223 | 81346.9284249999 |
| ads_rev_usd | double | net advertising revenue for the day，calculated after tax, In USD currency ｜ 当天广告净收入，含税，美元货币 | 1095/2083/4268 | 81346.9284249999 |
| ads_gmv_usd | double | Covers the calculated gross merchandise value (GMV) for ads in USD, &#124; 广告总的GMV，以美元计价 | 934/1541/2994 | 581571.879529 |
| platform_imp | bigint | This column represents the number of impressions on the platform ｜ 平台大盘上的展示次数 | 562/1111/2535 | 251848181 |
| platform_gmv | double | The Gross Merchandise Value of the order expressed. Changing the payment method will change the buyer_txn_fee and hence affect the gmv collected from the buyer. GMV = buyer_paid_shipping_fee + merchandise_subtotal_amt + tax_payable + insurance_subtotal_amt + buyer_txn_fee + buyer_service_fee - promotion_fees. The data unit is USD. | 621/1188/2918 | 11617265.43800669 |
| platform_nmv | double | This column reflects the net marketplace value (NMV) generated on the platform, providing insights into the overall health of the marketplace revenue over the reporting period. | 197/386/853 | 10653704.28317182 |
| platform_gmv_excl_testorder | double | This column shows the Gross Merchandise Volume (GMV) from the platform, excluding test orders ｜ 此列显示平台商品交易总额 (GMV)，不包括测试订单。 | 1400/2177/4098 | 11603874.739964373 |
| pricing_type | int | pricing type of ads | 603/1423/3298 | 27 |
| is_cb_shop | tinyint | cb shop or not | 315/613/1331 | 1 |
| seller_type_1p | string | 1-party store type for shop | 541/1062/2388 | Unknown |
| net_ads_rev_usd | double | net deduction amt, logic can refer to https://sites.google.com/shopee.com/paid-ads-data/ads-domain-knowledge/finance/net-revenue-gross-revenue | 1459/2781/5333 | 76954.60230999984 |
| traffic_type | string | ads traffic type, split by entrance | 909/2605/5725 | You May Also Like |
| sub_product_type | string | ads sub product line, split by pricing_type + placement | 334/1386/2698 | video_roi2.0 |
| product_type | string | ads product line, split by pricing_type + placement | 351/855/1786 | others |
| main_product_type | string | ads main product line, split by pricing_type + placement | 405/794/1704 | Video Ads |
| seller_type | string | seller type of the shop i.e. MYCB,CNCB,Local | 201/390/848 | VNCB |
| gross_ads_rev_usd | double | gross rev, logic can refer to https://sites.google.com/shopee.com/paid-ads-data/ads-domain-knowledge/finance/net-revenue-gross-revenue ｜ 毛收入 | 1214/2380/3823 | 81346.92842499992 |
| expired_amt_usd_1d | double | This column records the amount associated calculated after tax with expired credits in USD for the day, include SCS, SIP, Lovito, and GOV free ads Expired Credit & Paid Ads Expired Credit &#124; 这一栏记录了当天以美元计算的过期积分的税后相关金额，包括SCS， SIP， Lovito和GOV免费广告过期积分和付费广告过期积分 | 197/386/844 | 1907.6032826 |
| free_ads_rev_usd | double | free credit before tax, exclude free to paid credit &#124; 税前免息额度，不包括转为付费额度 | 211/1157/2209 | 10724.668166 |
| net_ads_rev_excl_sip_usd_1d | double | net ads deduction amt exclude sip deduction amt ｜ 净广告扣除额不包括SIP扣除额 | 506/991/2232 | 76954.60230999984 |
| sip_free_credit_revenue_usd_1d | double | sip deduction amt | 197/386/844 | 6389.182796999995 |
| is_cb_sip_affiliated | tinyint | is_cb_sip_affiliated | 197/386/844 | 1 |
| is_local_sip_affiliated | tinyint | This indicator shows whether the seller is affiliated with local Sellers Incentive Programs (SIP), (1 for true, 0 for false). &#124; 卖方是否隶属于当地卖方激励计划（SIP），（1为真，0为假） | 197/386/844 | 1 |
| platform_antifraud_gmv_usd | double | platform_antifraud_gmv_usd from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 11603874.739964359 |
| platform_antifraud_gmv | double | platform_antifraud_gmv from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 14670198.639999893 |
| platform_antifraud_order_fraction | double | platform_antifraud_order_fraction from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 404599.99999996764 |
| platform_paid_gmv_usd | double | platform_paid_gmv_usd from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 88/172/367 | 10868083.116472231 |
| platform_paid_gmv | double | platform_paid_gmv from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 13739974.079999857 |
| platform_paid_order_fraction | double | platform_paid_order_fraction from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 390738.9999999669 |
| platform_confirmed_gmv_usd | double | platform_confirmed_gmv_usd from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 10868083.116472231 |
| platform_confirmed_gmv | double | Extracted from 'traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg', this column details the gross merchandise volume (GMV) that has been confirmed on the platform. | 81/158/337 | 13739974.079999857 |
| platform_confirmed_order_fraction | double | platform_confirmed_order_fraction from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 390738.9999999669 |
| platform_complete_gmv_usd | double | platform_complete_gmv_usd from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 140713.2845560553 |
| platform_complete_gmv | double | platform_complete_gmv from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 177896.76999999877 |
| platform_complete_order_fraction | double | platform_complete_order_fraction from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 3797.9999999999973 |
| platform_cancel_gmv_usd | double | As derived from 'traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg', this value indicates the gross merchandise volume (GMV) that was canceled, calculated in USD. | 81/158/337 | 961702.8435831405 |
| platform_cancel_gmv | double | platform_cancel_gmv from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 1215832.8199999973 |
| platform_cancel_order_fraction | double | platform_cancel_order_fraction from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 18835.99999999989 |
| platform_return_gmv_usd | double | platform_return_gmv_usd from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 8120.355418461099 |
| platform_return_gmv | double | platform_return_gmv from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 10266.1593377885 |
| platform_return_order_fraction | double | platform_return_order_fraction from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 187.58333333333334 |
| platform_net_order_fraction | double | platform_net_order_fraction from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 385731.9999999663 |
| omni_platform_nmv | double | platform_nmv from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 13452740.819999853 |
| omni_platform_nmv_usd | double | platform_nmv_usd from traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg | 81/158/337 | 10640886.549337551 |
| ads_voucher_omni_platform_nmv_cost | double | The net amount of rebates provided by Shopee to the buyer via seller voucher for the order item. This field would be influenced canceled, invalid, or returned. Because it is net value. The field's data unit is in the local currency &#124; Shopee通过卖家优惠券向买家提供的订单商品折扣净额。由于此字段为净值，因此可能会被取消、无效或退回。该字段的数据单位为当地货币。 | 81/158/337 | 18409.54 |
| ads_voucher_omni_platform_nmv_cost_usd | double | The net amount of rebates provided by Shopee to the buyer via seller voucher for the order item. This field would be influenced canceled, invalid, or returned. Because it is net value. The field's data unit is in USD &#124; Shopee通过卖家优惠券向买家提供的订单商品折扣净额。由于此字段为净值，因此可能会被取消、无效或退回。该字段的数据单位为美元 (USD) | 191/367/760 | 14561.6293 |
| ads_voucher_ads_nmv_cost | double | The net amount of rebates provided by Shopee to the buyer via seller voucher for the order item. This field would be influenced canceled, invalid, or returned. Because it is net value. The field's data unit is in the local currency &#124; Shopee通过卖家优惠券向买家提供的订单商品折扣净额。由于此字段为净值，因此可能会被取消、无效或退回。该字段的数据单位为当地货币。 | 81/158/337 | 2759.1 |
| ads_voucher_ads_nmv_cost_usd | double | The net amount of rebates provided by Shopee to the buyer via seller voucher for the order item. This field would be influenced canceled, invalid, or returned. Because it is net value. The field's data unit is in USD &#124; Shopee通过卖家优惠券向买家提供的订单商品折扣净额。由于此字段为净值，因此可能会被取消、无效或退回。该字段的数据单位为美元 (USD) | 81/158/344 | 2182.400597 |
| platform_paid_with_confirmed_cod_gmv_usd | double | - | 81/158/337 | 10868083.116472231 |
| platform_paid_with_confirmed_cod_gmv | double | - | 81/158/337 | 13739974.079999857 |
| platform_paid_order_with_confirmed_cod_fraction | double | - | 81/158/337 | 390738.9999999669 |
| platform_paid_with_placed_cod_gmv_usd | double | - | 184/351/748 | 10868083.116472231 |
| platform_paid_with_placed_cod_gmv | double | - | 81/158/338 | 13739974.079999857 |
| platform_paid_order_with_placed_cod_fraction | double | - | 81/158/337 | 390738.9999999669 |
| live_total_entry_point_imp | bigint | - | 216/423/929 | 3630962 |
| live_total_ads_imp | bigint | - | 216/423/929 | 498652 |
| ads_voucher_ads_part_amt_usd | double | - | 1091/1388/2108 | 95.84338500000004 |
| broad_order_gmv_usd | double | Broad order GMV in USD calculated from mp_paidads.ods_log_ads_report_hi__reg_s0_live ｜ 广义订单GMV，美元计价 | - | - |
| broad_order_cnt | bigint | Broad order count from mp_paidads.ods_log_ads_report_hi__reg_s0_live ｜ 广义订单数 | - | - |
| tz_type | string | tz_type [PARTITION] | 2519/5184/11113 |  |
| grass_region | string | grass_region ｜ 国家分区 [PARTITION] | 2519/5184/11114 |  |
| grass_date | date | grass_date &#124; 日期分区 [PARTITION] | 2519/5184/11114 |  |
