<!-- ads-workspace-gdoc-sync: gdoc_id=1zKfVlxwAvF-oc__fRSKqu6gkLyFyJOWje9lDIHWcHLk gdoc_url=https://docs.google.com/document/d/1zKfVlxwAvF-oc__fRSKqu6gkLyFyJOWje9lDIHWcHLk/edit -->

# Columns: mp_paidads.ads_advertiser_mkt_1d__reg_s0_live

## Top 20 Most Queried Columns

| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|---|
| 1 | grass_date | date | date partition for data organization [PARTITION] | 2090/4196/9349 |  |
| 2 | shop_id | bigint | ID of a shop &#124; 店铺ID | 2084/4190/9330 | 1783751696 |
| 3 | tz_type | string | timezone partition [PARTITION] | 2054/4114/9192 |  |
| 4 | grass_region | string | country partition for each record [PARTITION] | 1937/3855/8683 |  |
| 5 | ads_expenditure_amt_usd_1d | double | total expenditure on ads over one day in USD | 1146/2071/5121 | 11815.056531540453 |
| 6 | total_eod_balance_usd_td | double | End of day total balance in USD | 671/1316/2402 | 427564.68544987147 |
| 7 | ads_impression_1d | bigint | total impressions for ads over the last day | 509/937/1889 | 1460607 |
| 8 | paid_expenditure_wo_expiry_amt_usd_1d | double | 1d paid ads expenditure without expiry in USD | 489/998/1884 | 3765.749274273284 |
| 9 | free_credit_wo_expiry_eod_balance_amt_usd_td | double | End of day balance of free credit without expiry in USD | 410/927/1882 | 424856.191086 |
| 10 | free_expenditure_wo_expiry_amt_usd_1d | double | 1d free ads expenditure without expiry in USD | 461/940/1790 | 6899.99076923077 |
| 11 | free_expenditure_w_expiry_amt_usd_1d | double | 1d free ads expenditure with expiry in USD | 461/940/1789 | 4915.0657623096695 |
| 12 | paid_expenditure_w_expiry_amt_usd_1d | double | 1d paid ads expenditure with expiry in USD | 454/928/1758 | 4479.345548744314 |
| 13 | free_credit_w_expiry_eod_balance_amt_usd_td | double | End of day balance of free credit with expiry in USD | 388/868/1751 | 38582.44779909037 |
| 14 | ads_broad_gmv_usd_1d | double | broad ads GMV in USD 1d | 456/855/1713 | 149500.810757366 |
| 15 | ads_click_cnt_1d | bigint | count of clicks on ads over the last day | 422/774/1547 | 35767 |
| 16 | ads_order_cnt_1d | bigint | direct order volume brought by ads in past day | 350/731/1529 | 2451 |
| 17 | ads_gmv_amt_usd_1d | double | ads GMV over the last day in USD | 432/785/1521 | 114861.83112517303 |
| 18 | paid_credit_wo_expiry_eod_balance_amt_usd_td | double | End of day balance of paid credit without expiry in USD | 334/747/1499 | 83500.750722 |
| 19 | paid_credit_w_expiry_eod_balance_amt_usd_td | double | End of day balance of paid credit with expiry in USD | 327/729/1463 | 82703.3456041131 |
| 20 | ads_expenditure_amt_local_1d | double | total expenditure on ads over one day in local currency | 326/670/1418 | 14937.185219999998 |

### 查询频率分析

Top 20 高频查询字段可归纳为以下主题：

1. **分区键**（#1 grass_date, #3 tz_type, #4 grass_region）：几乎所有查询都需要的过滤条件，查询量最高
2. **核心标识**（#2 shop_id）：广告主维度的主键，JOIN 必备字段
3. **广告支出**（#5 ads_expenditure_amt_usd_1d, #8-#12 paid/free expenditure 拆分, #20 ads_expenditure_amt_local_1d）：支出分析是最高频场景，按 paid/free、w/wo expiry 四象限拆分
4. **广告效果**（#7 impression, #15 click, #16 order, #17 GMV, #14 broad GMV）：漏斗各环节指标，以 1d 粒度为主
5. **账户余额**（#6 total_eod_balance_usd_td, #9 free_credit_wo_expiry, #13 free_credit_w_expiry, #18-#19 paid_credit）：EOD 余额按 free/paid × w/wo expiry 四维拆分，用于预算预警和健康度分析

使用模式：绝大多数查询聚焦于 **1d 粒度 + USD 币种**，反映日常监控和短期分析需求。7d/30d/60d/90d 窗口的查询量显著下降。

> MAX(column): MAX() aggregated values from grass_date=2026-03-25, grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~70% 查询, incentive/seller 分析) / 'regional' (ROI/全局指标)
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')
- `ads_expenditure_amt_usd_7d > 0`: 活跃广告主筛选
- `is_active_ads_seller = 1`: 有活跃广告或有广告效果
- `has_active_ads = 1`: 至少 1 个激活广告 (pricing_type != 29)
- `ads_expenditure_amt_usd_1d > 0`: 当日有消耗（hit balance 检测、advertiser growth 分析）
- `grass_date BETWEEN DATE_SUB('${BIZ_PRE_DAY}', 6) AND '${BIZ_PRE_DAY}'`: 7 天滚动窗口聚合（LTV 监控、ROI vs category 对比）
- `grass_date BETWEEN DATE_SUB('${date}', 89) AND '${date}'`: 90 天滚动窗口（traffic boost 特征工程、broad order 聚合）

### 派生字段逻辑 (Derived Field Logic)

以下字段由生产 SQL 的 CASE WHEN 逻辑派生，非直接来自上游表：

| Column | Derivation Logic |
|--------|-----------------|
| has_topup | `1 if topup1d.shop_id IS NOT NULL, else 0` |
| has_active_ads | `1 if COUNT(DISTINCT ads_id) >= 1 from dim_advertise (is_ads_active=1, pricing_type!=29)` |
| has_ads_performance | `1 if impression + click + expenditure + gmv + order > 0` |
| is_active_ads_seller | `1 if has_active_ads OR has_ads_performance` |
| country | 直接取 `grass_region`，与 grass_region 值相同 |
| paid_free_ads_expenditure_struct_1d | JSON struct: `{paid_wo_expiry, paid_w_expiry, free_wo_expiry, free_w_expiry}` (deprecated) |

### 下游常见派生指标 (Common Downstream Derived Metrics)

以下指标在多个下游任务中通过相同公式计算，虽不存于表中但值得记录：

| Derived Metric | Formula | Seen In |
|--------|---------|---------|
| take_rate | `ads_expenditure_amt_usd_30d / platform_gmv_usd_30d` | incentive strategy (low TR seller list) |
| sod_balance | `total_eod_balance_td + ads_expenditure_amt_local_1d` | shop ads budget suggestion |
| is_hit_balance | `ads_expenditure_amt_usd_1d >= (ads_expenditure_amt_usd_1d + total_eod_balance_usd_td) * 0.90` | incentive engine (hit balance) |
| paid_spend | `paid_expenditure_w_expiry_amt_local_1d + paid_expenditure_wo_expiry_amt_local_1d` | traffic boost features |
| shop_roi_vs_cate_diff_l7d | `SUM(ads_broad_gmv_usd_1d) / SUM(ads_expenditure_amt_usd_1d)` / `SUM(l1cat_ads_gmv_amt_usd_1d) / SUM(l1cat_ads_expenditure_amt_usd_1d)` over 7d | incentive wide table (shop advertiser) |
| actual_ltv | `SUM(ads_expenditure_amt_usd_1d)` over 7-day window | LTV monitoring |

### tz_type 影响的字段

- 以下字段按 tz_type 产出不同值（因为上游 dws 表按 tz_type 分区）：topup 系列、expenditure 系列、balance 系列、credit expiry 系列、performance 系列、checkout_cnt
- 以下字段与 tz_type 无关（来自 dim_advertiser LATERAL VIEW EXPLODE 复制到两个 tz）：user_id, user_name, shop_id, language, status, country, is_cb_seller, shop_level*_category 等维度字段

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|---|---|---|---|---|
| user_id | bigint | seller id &#124; 卖家ID | 37/75/163 | 8589516161 |
| user_name | string | seller name &#124;卖家名称 | 9/18/41 | zzzzzzzzzzz003.sg |
| shop_id | bigint | ID of a shop &#124; 店铺ID | 2084/4190/9330 | 1783751696 |
| language | string | This column indicates the language of the advertiser as recorded in 'shopee.paid_ads_dim_advertiser'. ｜ 代表shopee.paid_ads_dim_advertiser记录的广告商语言 | 2/4/5 | NULL |
| status | bigint | The account status of the advertiser &#124; 广告账号状态 | 9/18/35 | 3 |
| country | string | This column denotes the country of the seller, &#124; seller 所属地区 | 2/4/6 | SG |
| create_datetime | string | User account creation time &#124; 用户账号创建时间 | 2/4/5 | 2026-03-25 23:30:47 |
| modify_datetime | string | Latest date that user account got modified from shopee.paid_ads_dim_advertiser &#124; 用户帐户最近一次修改日期 | 2/4/5 | 2026-03-26 00:00:57 |
| beetalk_userid | bigint | Beetalk user id from shopee.paid_ads_dim_advertiser | 2/4/5 | NULL |
| account_create_datetime | string | The creation date of the advertising account &#124; Ads帐户创建日期 | 17/40/64 | 2026-03-25 23:46:15 |
| account_modify_datetime | string | This column records the latest date the Ads account was modified ｜ Ads帐户修改的最新日期 | 2/4/5 | 2026-03-26 02:09:18 |
| account_status | bigint | This column indicates the current status of the advertiser's account &#124; Ads账号广告状态 | 2/5/6 | 1 |
| is_seller | tinyint | Every advertiser is a seller. Does the seller have any active products | 2/4/5 | 1 |
| is_cb_seller | tinyint | This flag indicates whether the seller is a cross-border seller | 47/107/214 | 1 |
| is_managed_seller | tinyint | This flag indicates if the shop is managed by a relationship manager (RM) | 16/32/66 | 1 |
| is_official_shop | tinyint | Official shop flag | 16/35/67 | 1 |
| is_preferred_shop | tinyint | Whether shop is a preferred shop | 2/7/8 | 1 |
| has_topup | tinyint | This column denotes whether the seller has made a topup on that specific day | 16/32/67 | 1 |
| total_topup_amt_1d | double | total amount of top-ups made in one day in local currency | 33/63/145 | 400944.25 |
| total_topup_amt_7d | double | total amount topped up over the last 7 days in local currency | 2/4/5 | 400944.25 |
| total_topup_amt_30d | double | total amount topped up over the last 30 days in local currency | 2/4/5 | 801439.61 |
| total_topup_amt_60d | double | total amount topped up over the last 60 days in local currency | 2/4/5 | 1130323.59456 |
| total_topup_amt_usd_1d | double | total amount of top-ups made in one day in USD | 125/252/554 | 317140.003958 |
| total_topup_amt_usd_7d | double | total amount topped up over the last 7 days in USD | 9/18/35 | 317140.003958 |
| total_topup_amt_usd_30d | double | total amount topped up over the last 30 days in USD | 2/4/5 | 633175.008892 |
| total_topup_amt_usd_60d | double | total amount topped up over the last 60 days in USD | 2/4/5 | 892700.7414330001 |
| manual_topup_amt_1d | double | Total manual topup amount 1d in local currency | 2/4/5 | 400944.25 |
| manual_topup_amt_7d | double | Total manual topup amount 7d in local currency | 2/4/5 | 400944.25 |
| manual_topup_amt_30d | double | Total manual topup amount 30d in local currency | 2/4/5 | 801439.61 |
| manual_topup_amt_60d | double | Total manual topup amount 60d in local currency | 2/4/5 | 1130323.59456 |
| manual_topup_amt_usd_1d | double | Total manual topup amount 1d in USD | 9/18/35 | 317140.003958 |
| manual_topup_amt_usd_7d | double | Total manual topup amount 7d in USD | 2/4/5 | 317140.003958 |
| manual_topup_amt_usd_30d | double | Total manual topup amount 30d in USD | 2/4/5 | 633175.008892 |
| manual_topup_amt_usd_60d | double | Total manual topup amount 60d in USD | 2/4/5 | 892700.7414330001 |
| manual_free_credit_topup_amt_1d | double | manual free credit top-up 1d in local currency | 2/4/40 | 400944.25 |
| manual_free_credit_topup_amt_7d | double | manual free credit top-up 7d in local currency | 2/4/5 | 400944.25 |
| manual_free_credit_topup_amt_30d | double | manual free credit top-up 30d in local currency | 2/4/5 | 801439.61 |
| manual_free_credit_topup_amt_60d | double | manual free credit top-up 60d in local currency | 2/4/5 | 1130323.59456 |
| manual_free_credit_topup_amt_usd_1d | double | manual free credit top-up 1d in USD | 20/40/89 | 317140.003958 |
| manual_free_credit_topup_amt_usd_7d | double | manual free credit top-up 7d in USD | 2/4/5 | 317140.003958 |
| manual_free_credit_topup_amt_usd_30d | double | manual free credit top-up 30d in USD | 2/4/5 | 633175.008892 |
| manual_free_credit_topup_amt_usd_60d | double | manual free credit top-up 60d in USD | 2/4/5 | 892700.7414330001 |
| manual_paid_credit_topup_amt_1d | double | manual paid credit topups 1d in local currency | 9/15/34 | 3000.0 |
| manual_paid_credit_topup_amt_7d | double | manual paid credit topups 7d in local currency | 2/4/5 | 57279.0 |
| manual_paid_credit_topup_amt_30d | double | manual paid credit topups 30d in local currency | 2/4/5 | 85893.0 |
| manual_paid_credit_topup_amt_60d | double | manual paid credit topups 60d in local currency | 2/4/5 | 94100.0 |
| manual_paid_credit_topup_amt_usd_1d | double | manual paid credit top-up 1d in USD | 13/26/59 | 2372.948388 |
| manual_paid_credit_topup_amt_usd_7d | double | manual paid credit top-up 7d in USD | 2/4/5 | 45306.703579 |
| manual_paid_credit_topup_amt_usd_30d | double | manual paid credit top-up 30d in USD | 2/4/5 | 67939.885307 |
| manual_paid_credit_topup_amt_usd_60d | double | manual paid credit top-up 60d in USD | 2/4/5 | 74416.11336 |
| auto_topup_amt_1d | double | auto top-up amount 1d in local currency | 9/15/34 | 4000.0 |
| auto_topup_amt_7d | double | auto top-up amount 7d in local currency | 2/4/5 | 22400.0 |
| auto_topup_amt_30d | double | auto top-up amount 30d in local currency | 2/4/5 | 109600.0 |
| auto_topup_amt_60d | double | auto top-up amount 60d in local currency | 2/4/5 | 229900.0 |
| auto_topup_amt_usd_1d | double | auto top-up amount 1d in USD | 20/40/87 | 3163.9312000000027 |
| auto_topup_amt_usd_7d | double | auto top-up amount 7d in USD | 2/4/5 | 17718.01472 |
| auto_topup_amt_usd_30d | double | auto top-up amount 30d in USD | 2/4/5 | 86658.384024 |
| auto_topup_amt_usd_60d | double | auto top-up amount 60d in USD | 2/4/5 | 181282.22654 |
| normal_topup_amt_1d | double | normal top-ups 1d in local currency | 9/15/34 | 16000.0 |
| normal_topup_amt_7d | double | normal topups 7d in local currency | 2/4/5 | 20000.0 |
| normal_topup_amt_30d | double | normal topups 30d in local currency | 2/4/5 | 61300.0 |
| normal_topup_amt_60d | double | normal topups 60d in local currency | 2/4/5 | 105000.0 |
| normal_topup_amt_usd_1d | double | normal top-up amount 1d in USD | 9/18/35 | 12655.7247381 |
| normal_topup_amt_usd_7d | double | normal top-up amount 7d in USD | 2/4/5 | 15819.655922099999 |
| normal_topup_amt_usd_30d | double | normal topups 30d in USD | 2/4/5 | 48473.2015141 |
| normal_topup_amt_usd_60d | double | normal top-ups 60d in USD | 2/4/5 | 82894.4374864 |
| seller_mission_topup_amt_1d | double | seller mission top-up 1d in local currency | 2/4/5 | 0.5 |
| seller_mission_topup_amt_7d | double | seller mission top-up 7d in local currency | 2/4/5 | 0.5 |
| seller_mission_topup_amt_30d | double | seller mission top-up 30d in local currency | 2/4/5 | 10.0 |
| seller_mission_topup_amt_60d | double | seller mission top-up 60d in local currency | 2/4/5 | 10.0 |
| seller_mission_topup_amt_usd_1d | double | seller mission top-up 1d in USD | 9/18/35 | 0.395491 |
| seller_mission_topup_amt_usd_7d | double | seller mission top-up 7d in USD | 2/4/5 | 0.395491 |
| seller_mission_topup_amt_usd_30d | double | seller mission top-up 30d in USD | 2/4/5 | 7.891103 |
| seller_mission_topup_amt_usd_60d | double | seller mission top-up 60d in USD | 2/4/5 | 7.891103 |
| srm_topup_amt_1d | double | SRM topups 1d in local currency | 2/4/5 | 93.0 |
| srm_topup_amt_7d | double | SRM topups 7d in local currency | 2/4/5 | 200.0 |
| srm_topup_amt_30d | double | SRM topups 30d in local currency | 2/4/5 | 200.0 |
| srm_topup_amt_60d | double | SRM topups 60d in local currency | 2/4/5 | 200.0 |
| srm_topup_amt_usd_1d | double | SRM topups 1d in USD | 9/18/35 | 73.56139999999999 |
| srm_topup_amt_usd_7d | double | SRM topups 7d in USD | 2/4/5 | 158.196559 |
| srm_topup_amt_usd_30d | double | SRM topups 30d in USD | 2/4/5 | 158.196559 |
| srm_topup_amt_usd_60d | double | SRM topups 60d in USD | 2/4/5 | 158.196559 |
| neg_topup_amt_1d | double | negative topup 1d in local currency | 2/4/5 | 0.0 |
| neg_topup_amt_7d | double | negative top-up 7d in local currency | 2/4/5 | 0.0 |
| neg_topup_amt_30d | double | negative top-up 30d in local currency | 2/4/5 | 0.0 |
| neg_topup_amt_60d | double | negative topup 60d in local currency | 2/4/5 | 0.0 |
| neg_topup_amt_usd_1d | double | negative top-up 1d in USD | 20/40/87 | 0.0 |
| neg_topup_amt_usd_7d | double | negative topup 7d in USD | 2/4/5 | 0.0 |
| neg_topup_amt_usd_30d | double | negative top-ups 30d in USD | 2/4/5 | 0.0 |
| neg_topup_amt_usd_60d | double | negative top-ups 60d in USD | 2/4/5 | 0.0 |
| has_active_ads | tinyint | If seller have active ads flag | 416/679/1173 | 1 |
| has_ads_performance | tinyint | Is there any performance of the advertising post-link | 147/340/719 | 1 |
| is_active_ads_seller | tinyint | whether ads seller is active or not | 370/532/861 | 1 |
| low_threshold | double | Pre-defined threshold limits, differs for every country | 2/4/5 | 0.2 |
| low_threshold_usd | double | Pre-defined threshold limits in USD | 2/4/5 | 0.15819655922483686 |
| is_reach_low_threshold | tinyint | whether the account balance has hit a defined low threshold | 9/18/35 | 1 |
| ads_impression_1d | bigint | total impressions for ads over the last day | 509/937/1889 | 1460607 |
| ads_impression_7d | bigint | total impressions for ads over the last 7 days | 90/179/386 | 10061001 |
| ads_impression_30d | bigint | total impressions for ads over the last 30 days | 130/297/587 | 44129036 |
| ads_impression_60d | bigint | total impressions for ads over the last 60 days | 2/4/5 | 97069879 |
| ads_impression_90d | bigint | total impressions for ads over the last 90 days | 2/4/5 | 166992146 |
| ads_click_cnt_1d | bigint | count of clicks on ads over the last day | 422/774/1547 | 35767 |
| ads_click_cnt_7d | bigint | total clicks on ads in the last 7 days | 9/18/35 | 379875 |
| ads_click_cnt_30d | bigint | total clicks on ads in the last 30 days | 2/4/5 | 1121677 |
| ads_click_cnt_60d | bigint | total clicks on ads in the last 60 days | 2/4/5 | 1752387 |
| ads_click_cnt_90d | bigint | total clicks on ads in the last 90 days | 2/4/5 | 2340309 |
| ads_expenditure_amt_local_1d | double | total expenditure on ads over one day in local currency | 326/670/1418 | 14937.185219999998 |
| ads_expenditure_amt_local_7d | double | total expenditure on ads over 7 days in local currency | 75/147/308 | 87266.53558000005 |
| ads_expenditure_amt_local_30d | double | total expenditure on ads over 30 days in local currency | 65/130/275 | 401621.65375999996 |
| ads_expenditure_amt_local_60d | double | total expenditure on ads over 60 days in local currency | 2/4/5 | 793423.7666499999 |
| ads_expenditure_amt_local_90d | double | total expenditure on ads over 90 days in local currency | 2/4/5 | 1297413.6809199995 |
| ads_expenditure_amt_usd_1d | double | total expenditure on ads over one day in USD | 1146/2071/5121 | 11815.056531540453 |
| ads_expenditure_amt_usd_7d | double | total expenditure on ads over 7 days in USD | 111/229/504 | 69026.32855699878 |
| ads_expenditure_amt_usd_30d | double | total expenditure on ads over 30 days in USD | 204/367/739 | 317575.14414699876 |
| ads_expenditure_amt_usd_60d | double | total expenditure on ads over 60 days in USD | 2/4/5 | 625483.3441269987 |
| ads_expenditure_amt_usd_90d | double | total expenditure on ads over 90 days in USD | 2/4/5 | 1016898.5446546043 |
| ads_gmv_amt_local_1d | double | ads GMV over the last day in local currency | 79/161/339 | 145214.07 |
| ads_gmv_amt_local_7d | double | ads GMV over the last 7 days in local currency | 2/4/5 | 280603.07 |
| ads_gmv_amt_local_30d | double | ads GMV over the last 30 days in local currency | 2/4/5 | 2874597.4300000006 |
| ads_gmv_amt_local_60d | double | ads GMV over the last 60 days in local currency | 2/4/5 | 3760907.68 |
| ads_gmv_amt_local_90d | double | ads GMV over the last 90 days in local currency | 2/4/5 | 4102353.6900000004 |
| ads_gmv_amt_usd_1d | double | ads GMV over the last day in USD | 432/785/1521 | 114861.83112517303 |
| ads_gmv_amt_usd_7d | double | ads GMV over the last 7 days in USD | 9/18/35 | 221952.2009096302 |
| ads_gmv_amt_usd_30d | double | ads GMV over the last 30 days in USD | 17/28/45 | 2272580.0546751833 |
| ads_gmv_amt_usd_60d | double | ads GMV over the last 60 days in USD | 2/4/5 | 2970054.1299694353 |
| ads_gmv_amt_usd_90d | double | ads GMV over the last 90 days in USD | 2/4/5 | 3235453.8376305206 |
| ads_order_cnt_1d | bigint | direct order volume brought by ads in past day | 350/731/1529 | 2451 |
| ads_order_cnt_7d | bigint | direct order volume brought by ads in past 7 days | 9/18/35 | 14654 |
| ads_order_cnt_30d | bigint | direct order volume brought by ads in past 30 days | 10/21/38 | 74047 |
| ads_order_cnt_60d | bigint | direct order volume brought by ads in past 60 days | 2/4/5 | 149167 |
| ads_order_cnt_90d | bigint | direct order volume brought by ads in past 90 days | 2/4/5 | 214808 |
| ads_paid_order_cnt_ytd_1d | bigint | total paid order of grass_date minus 1 date | 2/4/5 | 83919 |
| ads_confirmed_order_cnt_ytd_1d | bigint | total confirm order of grass_date minus 1 date | 2/4/5 | 0 |
| platform_order_cnt_1d | bigint | distinct number of orders from the platform 1d | 45/99/194 | 0 |
| platform_order_cnt_7d | bigint | distinct number of orders from the platform 7d | 2/4/5 | 35530 |
| platform_order_cnt_30d | bigint | distinct number of orders from the platform 30d | 2/4/5 | 200939 |
| platform_order_cnt_60d | bigint | distinct number of orders from the platform 60d | 2/4/5 | 403750 |
| platform_order_cnt_90d | bigint | distinct number of orders from the platform 90d | 2/4/5 | 607643 |
| ads_items_sold_cnt_1d | bigint | total items sold as a result of ads 1d | 230/388/725 | 6897 |
| ads_items_sold_cnt_7d | bigint | total items sold as a result of ads 7d | 2/4/5 | 30614 |
| ads_items_sold_cnt_30d | bigint | total items sold as a result of ads 30d | 2/4/5 | 191641 |
| ads_items_sold_cnt_60d | bigint | total items sold as a result of ads 60d | 2/4/5 | 404732 |
| ads_items_sold_cnt_90d | bigint | total items sold as a result of ads 90d | 2/4/5 | 645631 |
| platform_items_sold_cnt_1d | bigint | distinct number of items sold from the platform 1d | 45/97/192 | 0 |
| platform_items_sold_cnt_7d | bigint | distinct number of items sold from the platform 7d | 2/4/5 | 16612 |
| platform_items_sold_cnt_30d | bigint | distinct number of items sold from the platform 30d | 9/18/35 | 90616 |
| platform_items_sold_cnt_60d | bigint | distinct number of items sold from the platform 60d | 2/4/5 | 183253 |
| platform_items_sold_cnt_90d | bigint | distinct number of items sold from the platform 90d | 2/4/5 | 277898 |
| platform_gmv_1d | double | total GMV from the platform in local currency 1d | 109/120/128 | 0.0 |
| platform_gmv_7d | double | total GMV from the platform in local currency 7d | 9/18/41 | 1319459.12 |
| platform_gmv_30d | double | total GMV from the platform in local currency 30d | 2/4/5 | 10490960.59 |
| platform_gmv_60d | double | total GMV from the platform in local currency 60d | 2/4/5 | 21927060.72 |
| platform_gmv_90d | double | total GMV from the platform in local currency 90d | 2/4/5 | 33972352.86 |
| platform_gmv_usd_1d | double | total GMV from the platform in USD 1d | 60/119/219 | 0.0 |
| platform_gmv_usd_7d | double | total GMV from the platform in USD 7d | 2/4/5 | 1043669.4641091658 |
| platform_gmv_usd_30d | double | total GMV from the platform in USD 30d | 24/33/52 | 8295617.031083016 |
| platform_gmv_usd_60d | double | total GMV from the platform in USD 60d | 2/4/5 | 17298960.585265048 |
| platform_gmv_usd_90d | double | total GMV from the platform in USD 90d | 2/4/5 | 26661413.211785953 |
| l1cat_ads_expenditure_amt_1d | double | ads expenditure for L1 item categories in local currency 1d | 2/4/5 | 6894.963489999998 |
| l1cat_ads_expenditure_amt_usd_1d | double | ads expenditure for L1 item categories in USD 1d | 9/18/35 | 5453.797500494364 |
| l1cat_ads_gmv_amt_1d | double | ads GMV for L1 item categories in local currency 1d | 2/4/5 | 123574.06999999999 |
| l1cat_ads_gmv_amt_usd_1d | double | ads GMV for L1 item categories in USD 1d | 9/18/35 | 97744.96341704567 |
| l2cat_ads_expenditure_amt_1d | double | ads expenditure for L2 item categories in local currency 1d | 2/4/5 | 5424.983040000001 |
| l2cat_ads_expenditure_amt_usd_1d | double | ads expenditure for L2 item categories in USD 1d | 2/4/5 | 4291.068253905478 |
| l2cat_ads_gmv_amt_1d | double | ads GMV for L2 item categories in local currency 1d | 2/4/5 | 37877.060000000005 |
| l2cat_ads_gmv_amt_usd_1d | double | ads GMV for L2 item categories in USD 1d | 2/4/5 | 29960.1028277635 |
| free_credit_w_expiry_eod_balance_amt_td | double | End of day balance of free credit with expiry in Local Currency | 100/203/443 | 48777.85963 |
| free_credit_w_expiry_eod_balance_amt_usd_td | double | End of day balance of free credit with expiry in USD | 388/868/1751 | 38582.44779909037 |
| free_credit_wo_expiry_eod_balance_amt_td | double | End of day balance of free credit without expiry in Local Currency | 100/203/444 | 537124.43958 |
| free_credit_wo_expiry_eod_balance_amt_usd_td | double | End of day balance of free credit without expiry in USD | 410/927/1882 | 424856.191086 |
| paid_credit_w_expiry_eod_balance_amt_td | double | End of day balance of paid credit with expiry in Local Currency | 101/213/453 | 104557.70468 |
| paid_credit_w_expiry_eod_balance_amt_usd_td | double | End of day balance of paid credit with expiry in USD | 327/729/1463 | 82703.3456041131 |
| paid_credit_wo_expiry_eod_balance_amt_td | double | End of day balance of paid credit without expiry in Local Currency | 101/213/454 | 105565.8241 |
| paid_credit_wo_expiry_eod_balance_amt_usd_td | double | End of day balance of paid credit without expiry in USD | 334/747/1499 | 83500.750722 |
| paid_credit_wo_expiry_sod_balance_amt_td | double | Start of day balance of paid credit without expiry in Local Currency | 2/4/5 | 105942.81931 |
| paid_credit_wo_expiry_sod_balance_amt_usd_td | double | Start of day balance of paid credit without expiry in USD | 2/4/5 | 83798.947447 |
| total_eod_balance_td | double | End of day total balance in Local Currency | 198/399/872 | 540548.65358 |
| total_eod_balance_usd_td | double | End of day total balance in USD | 671/1316/2402 | 427564.68544987147 |
| manual_free_credit_expired_amt_td | double | free credit expired for manual topups in local currency | 2/4/5 | 90714.91216 |
| manual_free_credit_expired_amt_usd_td | double | free credit expired for manual topups in USD | 2/4/5 | 71753.93487040001 |
| manual_paid_credit_expired_amt_td | double | paid credit expired for manual topups in local currency | 2/4/5 | 67874.45865 |
| manual_paid_credit_expired_amt_usd_td | double | paid credit expired for manual topups in USD | 2/4/5 | 53687.5290884 |
| seller_mission_free_credit_expired_amt_td | double | free credit expired for seller mission topups in local currency | 2/4/5 | 10.0 |
| seller_mission_free_credit_expired_amt_usd_td | double | free credit expired for seller mission topups in USD | 2/4/5 | 7.909828 |
| seller_mission_paid_credit_expired_amt_td | double | paid credit expired for seller mission topups in local currency | 2/4/5 | 0.0 |
| seller_mission_paid_credit_expired_amt_usd_td | double | paid credit expired for seller mission topups in USD | 2/4/5 | 0.0 |
| srm_free_credit_expired_amt_td | double | free credit expired for srm topups in local currency | 2/4/5 | 179.92000000000002 |
| srm_free_credit_expired_amt_usd_td | double | free credit expired for srm topups in USD | 2/4/5 | 142.3136247 |
| srm_paid_credit_expired_amt_td | double | paid credit expired for srm topups in local currency | 2/4/5 | 0.0 |
| srm_paid_credit_expired_amt_usd_td | double | paid credit expired for srm topups in USD | 2/4/5 | 0.0 |
| total_free_credit_expired_amt_td | double | total free credit expired in local currency | 2/4/5 | 90714.91216 |
| total_free_credit_expired_amt_usd_td | double | total free credit expired in USD | 2/4/5 | 71753.93487040001 |
| total_paid_credit_expired_amt_td | double | total paid credits expired in local currency | 2/4/5 | 67874.45865 |
| total_paid_credit_expired_amt_usd_td | double | total paid credits expired in USD | 2/4/5 | 53687.5290884 |
| last_active_date | date | last date an advertiser was active | 2/4/5 | 2026-03-25 |
| first_mm_kw_ads_active_date | date | earliest grass_date where keyword ads become active since 1 Oct 2020 | 2/4/5 | 2026-03-24 |
| first_sm_kw_ads_active_date | date | earliest grass_date where simple mode keyword ads become active | 2/4/5 | 2025-02-17 |
| is_auto_topup_enabled | tinyint | whether the seller has enabled auto wallet top-up | 52/105/227 | 1 |
| is_campaign_auto_bid_enabled | tinyint | whether the seller has activated auto bid for keyword search ads | 2/19/24 | 1 |
| shop_level1_global_be_category | string | shop primary global backend category | 135/274/602 | Women Shoes |
| shop_level1_fe_display_category | string | shop level 1 frontend display category | 2/4/5 | Women's Shoes |
| shop_level1_kpi_category | string | shop_level1_kpi_category | 2/5/6 | Women's Shoes |
| shop_level2_global_be_category | string | shop level 2 global backend category | 58/116/266 | Writing & Correction |
| shop_level2_fe_display_category | string | shop level 2 frontend display category | 2/4/5 | Yoga Equipment |
| shop_level2_kpi_category | string | shop level 2 KPI categories | 2/4/5 | Yoga Equipment |
| checkout_cnt | bigint | The number of duplicate orders based on the order id | 97/193/417 | 3476 |
| paid_free_ads_expenditure_struct_1d | string | deprecated | 2/4/5 | {"paid_expenditure_wo_expiry_amt_local":99.98473,"paid_expenditure_wo_expiry_amt_usd":79.0862013051216,"paid_expenditure_w_expiry_amt_local":0.0,"paid_expenditure_w_expiry_amt_usd":0.0,"free_expenditure_wo_expiry_amt_local":2.60854,"free_expenditure_wo_expiry_amt_usd":2.0633102630017794,"free_expenditure_w_expiry_amt_local":0.0,"free_expenditure_w_expiry_amt_usd":0.0} |
| paid_expenditure_wo_expiry_amt_local_1d | double | 1d paid ads expenditure without expiry in local currency | 66/131/276 | 4760.84852 |
| paid_expenditure_wo_expiry_amt_usd_1d | double | 1d paid ads expenditure without expiry in USD | 489/998/1884 | 3765.749274273284 |
| paid_expenditure_w_expiry_amt_local_1d | double | 1d paid ads expenditure with expiry in local currency | 66/131/276 | 5663.01261 |
| paid_expenditure_w_expiry_amt_usd_1d | double | 1d paid ads expenditure with expiry in USD | 454/928/1758 | 4479.345548744314 |
| free_expenditure_wo_expiry_amt_local_1d | double | 1d free ads expenditure without expiry in local currency | 2/4/5 | 8723.31333 |
| free_expenditure_wo_expiry_amt_usd_1d | double | 1d free ads expenditure without expiry in USD | 461/940/1790 | 6899.99076923077 |
| free_expenditure_w_expiry_amt_local_1d | double | 1d free ads expenditure with expiry in local currency | 2/4/5 | 6213.87189 |
| free_expenditure_w_expiry_amt_usd_1d | double | 1d free ads expenditure with expiry in USD | 461/940/1789 | 4915.0657623096695 |
| ads_broad_gmv_usd_1d | double | broad ads GMV in USD 1d | 456/855/1713 | 149500.810757366 |
| ads_broad_gmv_usd_7d | double | broad ads GMV in USD 7d | 65/130/275 | 349135.6613960845 |
| ads_broad_gmv_usd_30d | double | broad ads GMV in USD 30d | 63/81/117 | 4238413.632180443 |
| ads_broad_gmv_usd_60d | double | broad ads GMV in USD 60d | 2/4/5 | 5212033.039464219 |
| ads_broad_gmv_usd_90d | double | broad ads GMV in USD 90d | 2/4/5 | 5661654.346588596 |
| ads_broad_order_1d | bigint | ads broad orders 1d | 247/519/1085 | 4467 |
| ads_broad_order_7d | bigint | ads broad orders 7d | 74/146/310 | 24436 |
| ads_broad_order_30d | bigint | ads broad orders 30d | 104/186/368 | 123420 |
| ads_broad_order_60d | bigint | ads broad orders 60d | 2/4/5 | 246338 |
| ads_broad_order_90d | bigint | ads broad orders 90d | 2/4/5 | 358400 |
| is_self_mcn | tinyint | whether the advertiser is MCN | 2/4/5 | 1 |
| tz_type | string | timezone partition [PARTITION] | 2054/4114/9192 |  |
| grass_region | string | country partition for each record [PARTITION] | 1937/3855/8683 |  |
| grass_date | date | date partition for data organization [PARTITION] | 2090/4196/9349 |  |
