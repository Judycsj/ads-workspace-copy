<!-- ads-workspace-gdoc-sync: gdoc_id=1yv44Bvor5sCZAcj7JTEltwG8CyKjzcKHh7KJnFAKSk8 gdoc_url=https://docs.google.com/document/d/1yv44Bvor5sCZAcj7JTEltwG8CyKjzcKHh7KJnFAKSk8/edit -->

# mp_paidads.ads_advertiser_mkt_1d

**分层**：ADS层（应用数据服务层）
**主键**：`shop_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表是 Shopee 付费广告（Paid Ads）体系的广告主营销宽表，以店铺（`shop_id`）为主体，按天粒度汇聚广告主在广告投放、平台交易、账户余额、充值行为等维度的全量核心指标。表中同时覆盖 1d/7d/30d/60d/90d 多周期滚动窗口指标，以及截至当天（`_td`）的累计指标，满足广告主运营分析、健康度评估、充值行为分析等多类场景的一站式取数需求。

本表支持两种时区视角（`tz_type = 'local'` 当地时区 / `'regional'` 新加坡时间），并通过 `${region}` 参数化调度覆盖所有上线地区，是广告业务日常监控报表、广告主分层运营、ROI 分析的核心底座表。

典型使用场景包括：广告主活跃度追踪（`is_active_ads_seller`）、广告 GMV 渗透率（`ads_gmv_amt_usd_Nd` / `platform_gmv_usd_Nd`）、充值漏斗分析（各类 `topup_amt`）、账户余额预警（`is_reach_low_threshold`）、宽泛归因 vs 直接归因订单对比（`ads_broad_order` vs `ads_order_cnt`）等。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_date` | date | 数据日期分区，每日调度写入 |
| `grass_region` | string | 地区分区，标识记录所属地区（如 ID、TH、MY 等），通过 `${region}` 参数化调度覆盖全部地区 |
| `tz_type` | string | 时区分区，`local`=当地时区，`regional`=新加坡时间（SGT）。**部分余额/_td 字段仅在 `local` 下有值** ⚠️ `tz_type='regional'` 时，所有 `_td` 余额/过期信用字段为 NULL，查询前需确认时区口径 |

### 维度：主键与广告主基本信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 卖家用户 ID（Shopee 账号维度主键） |
| `shop_id` | bigint | 店铺 ID（广告主维度主键） |
| `user_name` | string | 卖家名称 |
| `language` | string | 广告主语言，来源于 `paid_ads_dim_advertiser` |
| `status` | bigint | 广告账号状态 |
| `country` | string | 卖家所属地区（由 `grass_region` 赋值） |
| `create_datetime` | string | 用户账号创建时间 |
| `modify_datetime` | string | 用户账号最近修改时间 |
| `beetalk_userid` | bigint | Beetalk 用户 ID |
| `account_create_datetime` | string | 广告账户创建日期 |
| `account_modify_datetime` | string | 广告账户最近修改日期 |
| `account_status` | bigint | 广告账户当前状态 |

### 维度：卖家标签与资质

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_seller` | tinyint | 是否有活跃商品（0=无活跃 listing，1=至少 1 个活跃 listing） |
| `is_cb_seller` | tinyint | 是否跨境卖家 |
| `is_managed_seller` | tinyint | 是否由 RM（关系经理）托管的店铺 |
| `is_official_shop` | tinyint | 是否官方店铺 |
| `is_preferred_shop` | tinyint | 是否首选店铺（1=是，0=否） |
| `is_self_mcn` | tinyint | 广告主是否为 MCN |
| `is_auto_topup_enabled` | tinyint | 是否开启广告信用自动充值（1=开启） |
| `is_campaign_auto_bid_enabled` | tinyint | 是否为活跃关键词搜索广告开启自动出价 |

### 维度：广告活跃状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `has_active_ads` | tinyint | 当日是否有活跃广告（active_ads_cnt ≥ 1 则为 1） |
| `has_ads_performance` | tinyint | 当日是否有广告后链路表现（曝光/点击/订单/支出/GMV 任一 > 0） |
| `is_active_ads_seller` | tinyint | 广告卖家是否活跃（有活跃广告或有广告后链路表现均计为活跃） |
| `has_topup` | tinyint | 当日是否有充值行为（1=有，0=无） |
| `is_reach_low_threshold` | tinyint | 当日任意时刻账户余额是否触达预设低阈值 |
| `last_active_date` | date | 广告主最后活跃日期 |
| `first_mm_kw_ads_active_date` | date | 2020-10-01 起，关键词广告（标准模式）最早活跃日期 |
| `first_sm_kw_ads_active_date` | date | 2020-10-01 起，简单模式关键词广告最早活跃日期 |

### 维度：店铺类目

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_level1_global_be_category` | string | 店铺一级全球后端类目（由大区团队维护） |
| `shop_level1_fe_display_category` | string | 店铺一级前端展示类目（由本地团队维护） |
| `shop_level1_kpi_category` | string | 店铺一级 KPI 类目（用于分析报表） |
| `shop_level2_global_be_category` | string | 店铺二级全球后端类目 |
| `shop_level2_fe_display_category` | string | 店铺二级前端展示类目 |
| `shop_level2_kpi_category` | string | 店铺二级 KPI 类目 |

### 指标：广告绩效（曝光/点击）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_impression_1d` | bigint | 过去 1 天广告总曝光数 |
| `ads_impression_7d` | bigint | 过去 7 天广告总曝光数 |
| `ads_impression_30d` | bigint | 过去 30 天广告总曝光数 |
| `ads_impression_60d` | bigint | 过去 60 天广告总曝光数 |
| `ads_impression_90d` | bigint | 过去 90 天广告总曝光数 |
| `ads_click_cnt_1d` | bigint | 过去 1 天广告点击次数 |
| `ads_click_cnt_7d` | bigint | 过去 7 天广告点击次数 |
| `ads_click_cnt_30d` | bigint | 过去 30 天广告点击次数 |
| `ads_click_cnt_60d` | bigint | 过去 60 天广告点击次数 |
| `ads_click_cnt_90d` | bigint | 过去 90 天广告点击次数 |

### 指标：广告支出

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_expenditure_amt_local_1d` | double | 过去 1 天广告支出（本地货币） |
| `ads_expenditure_amt_local_7d` | double | 过去 7 天广告支出（本地货币） |
| `ads_expenditure_amt_local_30d` | double | 过去 30 天广告支出（本地货币） |
| `ads_expenditure_amt_local_60d` | double | 过去 60 天广告支出（本地货币） |
| `ads_expenditure_amt_local_90d` | double | 过去 90 天广告支出（本地货币） |
| `ads_expenditure_amt_usd_1d` | double | 过去 1 天广告支出（美元） |
| `ads_expenditure_amt_usd_7d` | double | 过去 7 天广告支出（美元） |
| `ads_expenditure_amt_usd_30d` | double | 过去 30 天广告支出（美元） |
| `ads_expenditure_amt_usd_60d` | double | 过去 60 天广告支出（美元） |
| `ads_expenditure_amt_usd_90d` | double | 过去 90 天广告支出（美元） |
| `paid_expenditure_wo_expiry_amt_local_1d` | double | 近 1 天付费广告支出—无到期期限（本地货币） |
| `paid_expenditure_wo_expiry_amt_usd_1d` | double | 近 1 天付费广告支出—无到期期限（美元） |
| `paid_expenditure_w_expiry_amt_local_1d` | double | 近 1 天付费广告支出—有到期期限（本地货币） |
| `paid_expenditure_w_expiry_amt_usd_1d` | double | 近 1 天付费广告支出—有到期期限（美元） |
| `free_expenditure_wo_expiry_amt_local_1d` | double | 近 1 天免费广告支出—无到期期限（本地货币） |
| `free_expenditure_wo_expiry_amt_usd_1d` | double | 近 1 天免费广告支出—无到期期限（美元） |
| `free_expenditure_w_expiry_amt_local_1d` | double | 近 1 天免费广告支出—有到期期限（本地货币） |
| `free_expenditure_w_expiry_amt_usd_1d` | double | 近 1 天免费广告支出—有到期期限（美元） |
| `paid_free_ads_expenditure_struct_1d` | string | 近 1 天付费/免费广告支出结构体（JSON 字符串格式，包含上述 8 个拆分字段） ⚠️ 该字段为 JSON 字符串，不可直接 SUM，需用 `get_json_object` 或解析后使用；注明为 `deprecated`，建议优先使用拆分字段 |

### 指标：广告订单与 GMV（直接归因）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_order_cnt_1d` | bigint | 近 1 天直接归因口径广告订单量 |
| `ads_order_cnt_7d` | bigint | 近 7 天直接归因口径广告订单量 |
| `ads_order_cnt_30d` | bigint | 近 30 天直接归因口径广告订单量 |
| `ads_order_cnt_60d` | bigint | 近 60 天直接归因口径广告订单量 |
| `ads_order_cnt_90d` | bigint | 近 90 天直接归因口径广告订单量 |
| `ads_items_sold_cnt_1d` | bigint | 近 1 天广告带动商品销售数量 |
| `ads_items_sold_cnt_7d` | bigint | 近 7 天广告带动商品销售数量 |
| `ads_items_sold_cnt_30d` | bigint | 近 30 天广告带动商品销售数量 |
| `ads_items_sold_cnt_60d` | bigint | 近 60 天广告带动商品销售数量 |
| `ads_items_sold_cnt_90d` | bigint | 近 90 天广告带动商品销售数量 |
| `ads_gmv_amt_local_1d` | double | 近 1 天广告 GMV（本地货币） |
| `ads_gmv_amt_local_7d` | double | 近 7 天广告 GMV（本地货币） |
| `ads_gmv_amt_local_30d` | double | 近 30 天广告 GMV（本地货币） |
| `ads_gmv_amt_local_60d` | double | 近 60 天广告 GMV（本地货币） |
| `ads_gmv_amt_local_90d` | double | 近 90 天广告 GMV（本地货币） |
| `ads_gmv_amt_usd_1d` | double | 近 1 天广告 GMV（美元） |
| `ads_gmv_amt_usd_7d` | double | 近 7 天广告 GMV（美元） |
| `ads_gmv_amt_usd_30d` | double | 近 30 天广告 GMV（美元） |
| `ads_gmv_amt_usd_60d` | double | 近 60 天广告 GMV（美元） |
| `ads_gmv_amt_usd_90d` | double | 近 90 天广告 GMV（美元） |

### 指标：广告订单（宽泛归因）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_broad_order_1d` | bigint | 近 1 天宽泛归因口径广告订单数 |
| `ads_broad_order_7d` | bigint | 近 7 天宽泛归因口径广告订单数 |
| `ads_broad_order_30d` | bigint | 近 30 天宽泛归因口径广告订单数 |
| `ads_broad_order_60d` | bigint | 近 60 天宽泛归因口径广告订单数 |
| `ads_broad_order_90d` | bigint | 近 90 天宽泛归因口径广告订单数 |
| `ads_broad_gmv_usd_1d` | double | 近 1 天宽泛归因口径广告 GMV（美元） |
| `ads_broad_gmv_usd_7d` | double | 近 7 天宽泛归因口径广告 GMV（美元） |
| `ads_broad_gmv_usd_30d` | double | 近 30 天宽泛归因口径广告 GMV（美元） |
| `ads_broad_gmv_usd_60d` | double | 近 60 天宽泛归因口径广告 GMV（美元） |
| `ads_broad_gmv_usd_90d` | double | 近 90 天宽泛归因口径广告 GMV（美元） |

### 指标：YTD 订单（跨分区汇总）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_paid_order_cnt_ytd_1d` | bigint | `grass_date - 1` 日的付费订单数，跨当日与前日分区汇总以补偿上游延迟 ⚠️ 口径为 `grass_date - 1` 而非当天，直接与当日其他指标对比会产生日期错位 |
| `ads_confirmed_order_cnt_ytd_1d` | bigint | `grass_date - 1` 日的确认订单数，跨当日与前日分区汇总以补偿上游延迟 ⚠️ 口径为 `grass_date - 1` 而非当天，直接与当日其他指标对比会产生日期错位 |

### 指标：类目维度广告支出与 GMV（1d）

| 字段 | 类型 | 说明 |
|------|------|------|
| `l1cat_ads_expenditure_amt_1d` | double | 近 1 天与店铺一级类目匹配的广告支出（本地货币） |
| `l1cat_ads_expenditure_amt_usd_1d` | double | 近 1 天与店铺一级类目匹配的广告支出（美元） |
| `l1cat_ads_gmv_amt_1d` | double | 近 1 天与店铺一级类目匹配的广告 GMV（本地货币） |
| `l1cat_ads_gmv_amt_usd_1d` | double | 近 1 天与店铺一级类目匹配的广告 GMV（美元） |
| `l2cat_ads_expenditure_amt_1d` | double | 近 1 天与店铺二级类目匹配的广告支出（本地货币） |
| `l2cat_ads_expenditure_amt_usd_1d` | double | 近 1 天与店铺二级类目匹配的广告支出（美元） |
| `l2cat_ads_gmv_amt_1d` | double | 近 1 天与店铺二级类目匹配的广告 GMV（本地货币） |
| `l2cat_ads_gmv_amt_usd_1d` | double | 近 1 天与店铺二级类目匹配的广告 GMV（美元） |

### 指标：平台大盘 GMV 与订单

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_order_cnt_1d` | bigint | 近 1 天平台订单数（去重） |
| `platform_order_cnt_7d` | bigint | 近 7 天平台订单数（去重） |
| `platform_order_cnt_30d` | bigint | 近 30 天平台订单数（去重） |
| `platform_order_cnt_60d` | bigint | 近 60 天平台订单数（去重） |
| `platform_order_cnt_90d` | bigint | 近 90 天平台订单数（去重） |
| `platform_items_sold_cnt_1d` | bigint | 近 1 天平台售出商品数 |
| `platform_items_sold_cnt_7d` | bigint | 近 7 天平台售出商品数 |
| `platform_items_sold_cnt_30d` | bigint | 近 30 天平台售出商品数 |
| `platform_items_sold_cnt_60d` | bigint | 近 60 天平台售出商品数 |
| `platform_items_sold_cnt_90d` | bigint | 近 90 天平台售出商品数 |
| `platform_gmv_1d` | double | 近 1 天平台 GMV（本地货币） |
| `platform_gmv_7d` | double | 近 7 天平台 GMV（本地货币） |
| `platform_gmv_30d` | double | 近 30 天平台 GMV（本地货币） |
| `platform_gmv_60d` | double | 近 60 天平台 GMV（本地货币） |
| `platform_gmv_90d` | double | 近 90 天平台 GMV（本地货币） |
| `platform_gmv_usd_1d` | double | 近 1 天平台 GMV（美元） |
| `platform_gmv_usd_7d` | double | 近 7 天平台 GMV（美元） |
| `platform_gmv_usd_30d` | double | 近 30 天平台 GMV（美元） |
| `platform_gmv_usd_60d` | double | 近 60 天平台 GMV（美元） |
| `platform_gmv_usd_90d` | double | 近 90 天平台 GMV（美元） |
| `checkout_cnt` | bigint | 按 `order_id` 去重统计的订单数（来源于广告 mkt 明细表） |

### 指标：账户余额（截至当日 _td）

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_eod_balance_td` | double | 当日结束时账户总余额（本地货币） ⚠️ 仅 `tz_type='local'` 有值 |
| `total_eod_balance_usd_td` | double | 当日结束时账户总余额（美元） ⚠️ 仅 `tz_type='local'` 有值 |
| `free_credit_w_expiry_eod_balance_amt_td` | double | 当日结束时有到期期限的免费信用余额（本地货币） ⚠️ 仅 `tz_type='local'` 有值 |
| `free_credit_w_expiry_eod_balance_amt_usd_td` | double | 当日结束时有到期期限的免费信用余额（美元） ⚠️ 仅 `tz_type='local'` 有值 |
| `free_credit_wo_expiry_eod_balance_amt_td` | double | 当日结束时无到期期限的免费信用余额（本地货币） ⚠️ 仅 `tz_type='local'` 有值 |
| `free_credit_wo_expiry_eod_balance_amt_usd_td` | double | 当日结束时无到期期限的免费信用余额（美元） ⚠️ 仅 `tz_type='local'` 有值 |
| `paid_credit_w_expiry_eod_balance_amt_td` | double | 当日结束时有到期期限的付费信用余额（本地货币） ⚠️ 仅 `tz_type='local'` 有值 |
| `paid_credit_w_expiry_eod_balance_amt_usd_td` | double | 当日结束时有到期期限的付费信用余额（美元） ⚠️ 仅 `tz_type='local'` 有值 |
| `paid_credit_wo_expiry_eod_balance_amt_td` | double | 当日结束时无到期期限的付费信用余额（本地货币） ⚠️ 仅 `tz_type='local'` 有值 |
| `paid_credit_wo_expiry_eod_balance_amt_usd_td` | double | 当日结束时无到期期限的付费信用余额（美元） ⚠️ 仅 `tz_type='local'` 有值 |
| `paid_credit_wo_expiry_sod_balance_amt_td` | double | 当日开始时无到期期限的付费信用余额（本地货币） ⚠️ 仅 `tz_type='local'` 有值 |
| `paid_credit_wo_expiry_sod_balance_amt_usd_td` | double | 当日开始时无到期期限的付费信用余额（美元） ⚠️ 仅 `tz_type='local'` 有值 |
| `low_threshold` | double | 账户余额预设低阈值（本地货币，因地区而异） |
| `low_threshold_usd` | double | 账户余额预设低阈值（美元，因地区而异） |

### 指标：信用过期（截至当日 _td）

| 字段 | 类型 | 说明 |
|------|------|------|
| `manual_free_credit_expired_amt_td` | double | 截至今日手动充值已过期的免费信用累计额（本地货币） ⚠️ 累计值，不可跨行 SUM 计算区间增量 |
| `manual_free_credit_expired_amt_usd_td` | double | 截至今日手动充值已过期的免费信用累计额（美元） ⚠️ 同上 |
| `manual_paid_credit_expired_amt_td` | double | 截至今日手动充值已过期的付费信用累计额（本地货币） ⚠️ 累计值 |
| `manual_paid_credit_expired_amt_usd_td` | double | 截至今日手动充值已过期的付费信用累计额（美元） ⚠️ 累计值 |
| `seller_mission_free_credit_expired_amt_td` | double | 截至今日卖家任务充值已过期的免费信用累计额（本地货币） ⚠️ 累计值 |
| `seller_mission_free_credit_expired_amt_usd_td` | double | 截至今日卖家任务充值已过期的免费信用累计额（美元） ⚠️ 累计值 |
| `seller_mission_paid_credit_expired_amt_td` | double | 截至今日卖家任务充值已过期的付费信用累计额（本地货币） ⚠️ 累计值 |
| `seller_mission_paid_credit_expired_amt_usd_td` | double | 截至今日卖家任务充值已过期的付费信用累计额（美元） ⚠️ 累计值 |
| `srm_free_credit_expired_amt_td` | double | 截至今日 SRM 充值已过期的免费信用累计额（本地货币） ⚠️ 累计值 |
| `srm_free_credit_expired_amt_usd_td` | double | 截至今日 SRM 充值已过期的免费信用累计额（美元） ⚠️ 累计值 |
| `srm_paid_credit_expired_amt_td` | double | 截至今日 SRM 充值已过期的付费信用累计额（本地货币） ⚠️ 累计值 |
| `srm_paid_credit_expired_amt_usd_td` | double | 截至今日 SRM 充值已过期的付费信用累计额（美元） ⚠️ 累计值 |
| `total_free_credit_expired_amt_td` | double | 截至今日各来源已过期免费信用合计（本地货币） ⚠️ 累计值 |
| `total_free_credit_expired_amt_usd_td` | double | 截至今日各来源已过期免费信用合计（美元） ⚠️ 累计值 |
| `total_paid_credit_expired_amt_td` | double | 截至今日各来源已过期付费信用合计（本地货币） ⚠️ 累计值 |
| `total_paid_credit_expired_amt_usd_td` | double | 截至今日各来源已过期付费信用合计（美元） ⚠️ 累计值 |

### 指标：充值金额（1d/7d/30d/60d）

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_topup_amt_1d` | double | 近 1 天总充值额（本地货币） |
| `total_topup_amt_7d` | double | 近 7 天总充值额（本地货币） |
| `total_topup_amt_30d` | double | 近 30 天总充值额（本地货币） |
| `total_topup_amt_60d` | double | 近 60 天总充值额（本地货币） |
| `total_topup_amt_usd_1d` | double | 近 1 天总充值额（美元） |
| `total_topup_amt_usd_7d` | double | 近 7 天总充值额（美元） |
| `total_topup_amt_usd_30d` | double | 近 30 天总充值额（美元） |
| `total_topup_amt_usd_60d` | double | 近 60 天总充值额（美元） |
| `manual_topup_amt_1d` | double | 近 1 天手动充值总额（本地货币） |
| `manual_topup_amt_7d` | double | 近 7 天手动充值总额（本地货币） |
| `manual_topup_amt_30d` | double | 近 30 天手动充值总额（本地货币） |
| `manual_topup_amt_60d` | double | 近 60 天手动充值总额（本地货币） |
| `manual_topup_amt_usd_1d` | double | 近 1 天手动充值总额（美元） |
| `manual_topup_amt_usd_7d` | double | 近 7 天手动充值总额（美元） |
| `manual_topup_amt_usd_30d` | double | 近 30 天手动充值总额（美元） |
| `manual_topup_amt_usd_60d` | double | 近 60 天手动充值总额（美元） |
| `manual_free_credit_topup_amt_1d` | double | 近 1 天手动免费信用充值额（本地货币） |
| `manual_free_credit_topup_amt_7d` | double | 近 7 天手动免费信用充值额（本地货币） |
| `manual_free_credit_topup_amt_30d` | double | 近 30 天手动免费信用充值额（本地货币） |
| `manual_free_credit_topup_amt_60d` | double | 近 60 天手动免费信用充值额（本地货币） |
| `manual_free_credit_topup_amt_usd_1d` | double | 近 1 天手动免费信用充值额（美元） |
| `manual_free_credit_topup_amt_usd_7d` | double | 近 7 天手动免费信用充值额（美元） |
| `manual_free_credit_topup_amt_usd_30d` | double | 近 30 天手动免费信用充值额（美元） |
| `manual_free_credit_topup_amt_usd_60d` | double | 近 60 天手动免费信用充值额（美元） |
| `manual_paid_credit_topup_amt_1d` | double | 近 1 天手动付费信用充值额（本地货币） |
| `manual_paid_credit_topup_amt_7d` | double | 近 7 天手动付费信用充值额（本地货币） |
| `manual_paid_credit_topup_amt_30d` | double | 近 30 天手动付费信用充值额（本地货币） |
| `manual_paid_credit_topup_amt_60d` | double | 近 60 天手动付费信用充值额（本地货币） |
| `manual_paid_credit_topup_amt_usd_1d` | double | 近 1 天手动付费信用充值额（美元） |
| `manual_paid_credit_topup_amt_usd_7d` | double | 近 7 天手动付费信用充值额（美元） |
| `manual_paid_credit_topup_amt_usd_30d` | double | 近 30 天手动付费信用充值额（美元） |
| `manual_paid_credit_topup_amt_usd_60d` | double | 近 60 天手动付费信用充值额（美元） |
| `auto_topup_amt_1d` | double | 近 1 天自动充值总额（本地货币） |
| `auto_topup_amt_7d` | double | 近 7 天自动充值总额（本地货币） |
| `auto_topup_amt_30d` | double | 近 30 天自动充值总额（本地货币） |
| `auto_topup_amt_60d` | double | 近 60 天自动充值总额（本地货币） |
| `auto_topup_amt_usd_1d` | double | 近 1 天自动充值总额（美元） |
| `auto_topup_amt_usd_7d` | double | 近 7 天自动充值总额（美元） |
| `auto_topup_amt_usd_30d` | double | 近 30 天自动充值总额（美元） |
| `auto_topup_amt_usd_60d` | double | 近 60 天自动充值总额（美元） |
| `normal_topup_amt_1d` | double | 近 1 天正常充值额（本地货币） |
| `normal_topup_amt_7d` | double | 近 7 天正常充值额（本地货币） |
| `normal_topup_amt_30d` | double | 近 30 天正常充值额（本地货币） |
| `normal_topup_amt_60d` | double | 近 60 天正常充值额（本地货币） |
| `normal_topup_amt_usd_1d` | double | 近 1 天正常充值额（美元） |
| `normal_topup_amt_usd_7d` | double | 近 7 天正常充值额（美元） |
| `normal_topup_amt_usd_30d` | double | 近 30 天正常充值额（美元） |
| `normal_topup_amt_usd_60d` | double | 近 60 天正常充值额（美元） |
| `seller_mission_topup_amt_1d` | double | 近 1 天卖家任务充值额（本地货币） |
| `seller_mission_topup_amt_7d` | double | 近 7 天卖家任务充值额（本地货币） |
| `seller_mission_topup_amt_30d` | double | 近 30 天卖家任务充值额（本地货币） |
| `seller_mission_topup_amt_60d` | double | 近 60 天卖家任务充值额（本地货币） |
| `seller_mission_topup_amt_usd_1d` | double | 近 1 天卖家任务充值额（美元） |
| `seller_mission_topup_amt_usd_7d` | double | 近 7 天卖家任务充值额（美元） |
| `seller_mission_topup_amt_usd_30d` | double | 近 30 天卖家任务充值额（美元） |
| `seller_mission_topup_amt_usd_60d` | double | 近 60 天卖家任务充值额（美元） |
| `srm_topup_amt_1d` | double | 近 1 天 SRM 充值额（本地货币） |
| `srm_topup_amt_7d` | double | 近 7 天 SRM 充值额（本地货币） |
| `srm_topup_amt_30d` | double | 近 30 天 SRM 充值额（本地货币） |
| `srm_topup_amt_60d` | double | 近 60 天 SRM 充值额（本地货币） |
| `srm_topup_amt_usd_1d` | double | 近 1 天 SRM 充值额（美元） |
| `srm_topup_amt_usd_7d` | double | 近 7 天 SRM 充值额（美元） |
| `srm_topup_amt_usd_30d` | double | 近 30 天 SRM 充值额（美元） |
| `srm_topup_amt_usd_60d` | double | 近 60 天 SRM 充值额（美元） |
| `neg_topup_amt_1d` | double | 近 1 天负充值额（本地货币，退款/冲正类） |
| `neg_topup_amt_7d` | double | 近 7 天负充值额（本地货币） |
| `neg_topup_amt_30d` | double | 近 30 天负充值额（本地货币） |
| `neg_topup_amt_60d` | double | 近 60 天负充值额（本地货币） |
| `neg_topup_amt_usd_1d` | double | 近 1 天负充值额（美元） |
| `neg_topup_amt_usd_7d` | double | 近 7 天负充值额（美元） |
| `neg_topup_amt_usd_30d` | double | 近 30 天负充值额（美元） |
| `neg_topup_amt_usd_60d` | double | 近 60 天负充值额（美元） |

---

## 查询使用须知

### 必须包含的过滤条件

| 过滤字段 | 推荐用法 | 遗漏后果 |
|----------|----------|----------|
| `grass_date` | `WHERE grass_date = DATE('${目标日期}')` | 未过滤会全量扫描所有历史分区，导致查询极慢或 OOM |
| `grass_region` | `AND grass_region = 'XX'`（大写，如 `'ID'`、`'TH'`） | 未过滤会返回所有地区数据，指标跨地区混合汇总失去意义 |
| `tz_type` | `AND tz_type = 'local'`（或 `'regional'`） | 未过滤会导致每个 shop_id 重复出现两行，所有指标 SUM 后翻倍 |

> **特别注意**：本表每个 `(shop_id, grass_date, grass_region)` 存在两行（`tz_type='local'` 和 `tz_type='regional'`），**必须固定 `tz_type`** 后再聚合，否则所有数值型指标均会被重复计算（×2）。

### 不可直接 SUM 的字段

| 字段 / 字段类型 | 原因 | 正确使用方式 |
|----------------|------|-------------|
| `_td` 系列（余额、信用过期累计） | 为截至当日的累计值（存量），跨行 SUM 无意义 | 取单个 shop_id 单天的值，或对 MAX 取快照；计算区间增量须用 `当天值 - N天前值` |
| `paid_free_ads_expenditure_struct_1d` | JSON 字符串格式 | 使用 `get_json_object(paid_free_ads_expenditure_struct_1d, '$.paid_expenditure_wo_expiry_amt_local')` 提取；优先使用已展开的独立字段 |
| `ads_paid_order_cnt_ytd_1d` / `ads_confirmed_order_cnt_ytd_1d` | 口径为 `grass_date - 1`，而非当天 | 与其他当日指标对比时，取前一天的行或明确说明日期偏移 |
| `has_active_ads`、`is_active_ads_seller`、`has_topup` 等 flag 字段 | 0/1 标志位，SUM 得到的是"有该属性的店铺数" | 用 `SUM` 统计满足条件的店铺数，或用 `AVG` 计算占比；不要误作指标金额使用 |

### 时效性说明

- 所有 `_td` 字段（余额、过期信用）反映的是数据日期（`grass_date`）截至当天 EOD/SOD 的快照，具有较强时效性，使用历史分区数据时需注意其代表的是**历史时点存量**。
- `ads_paid_order_cnt_ytd_1d` 和 `ads_confirmed_order_cnt_ytd_1d` 的实际业务日期为 `grass_date - 1`，存在 **1 天日期偏移**，跨表关联时需特别注意。
- 所有 `_td` 余额/信用字段**仅在 `tz_type='local'` 下有数据**，`tz_type='regional'` 对应值为 NULL。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主基础维度信息（用户、店铺、标签等） |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度信息，用于统计当日活跃广告数 |
| `mp_paidads.dws_advertiser_first_active_td__reg_s0_live` | 广告主首次活跃日期（关键词广告） |
| `mp_paidads.dws_advertiser_account_td__reg_s0_live` | 账户余额阈值与是否触达低阈值 |
| `mp_paidads.dws_advertiser_trd_order_gmv_nd__reg_s0_live` | 平台大盘订单量、售出商品数、GMV（多周期） |
| `mp_paidads.dws_advertiser_active_status_td__reg_s0_live` | 广告主最后活跃日期 |
| `mp_paidads.dws_advertiser_topup_1d__reg_s0_live` | 当日各类型充值金额 |
| `mp_paidads.dws_advertiser_topup_nd__reg_s0_live` | 7/30/60 天各类型充值金额 |
| `mp_paidads.dws_advertise_performance_nd__reg_s0_live` | 广告投放绩效（曝光、点击、订单、GMV、支出，多周期） |
| `mp_paidads.dws_advertiser_balance_td__reg_s0_live` | 账户各类余额快照（EOD/SOD） |
| `mp_paidads.dws_advertiser_credit_expiry_td__reg_s0_live` | 各来源信用过期累计金额 |
| `mp_paidads.dws_advertiser_deduction_1d__reg_s0_live` | 当日付费/免费广告支出拆分（有/无到期期限） |
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 广告明细，用于类目维度支出/GMV、checkout_cnt、宽泛归因订单 GMV |

---

## ETL 逻辑摘要

### 数据流

以 `dim_advertiser` 为驱动表（按 `grass_region` + `grass_date` 过滤，并通过 EXPLODE 展开为 `local`/`regional` 两行），再以 `shop_id` + `grass_region`（部分 CTE 还需匹配 `tz_type`）为 JOIN key，依次 LEFT OUTER JOIN 充值、绩效、余额、过期信用、平台大盘、类目汇总、宽泛归因等共 13 张 DWS/ADS 中间表，最终 INSERT OVERWRITE 按 `(tz_type, grass_region, grass_date)` 三级分区写入目标表。类目维度指标（`cat1`/`cat2`）通过额外匹配店铺一/二级类目字段确保口径对齐。

### 关键 CTE 说明

| CTE | 说明 |
|-----|------|
| `dim` | 基础维表，EXPLODE 时区生成 local/regional 双行，是所有 JOIN 的左表驱动源 |
| `ads_perf` | 汇总各广告的多周期曝光/点击/订单/GMV/支出，是广告绩效类指标的核心来源 |
| `ads_broad_nd` | 从 `ads_advertise_mkt_1d` 扫描最近 90 天，用 CASE WHEN 分桶计算宽泛归因各周期 GMV 和订单数 |
| `bal` + `credit` | 分别提供账户余额快照和信用过期累计值，JOIN 需同时匹配 `tz_type`（仅 local 有数据） |
| `cat1` / `cat2` | 按店铺一/二级类目聚合当日广告支出和 GMV，JOIN 时额外匹配类目字段 |

### 注意事项

1. **`tz_type` 双行问题**：`dim` CTE 通过 EXPLODE 将每个 shop 扩展为两行，查询时**必须固定 `tz_type`**，否则所有数值指标均翻倍。
2. **`_td` 字段的时区限制**：余额（`bal`）和信用过期（`credit`）的 JOIN 条件包含 `tz_type`，但上游 DWS 表仅在 `local` 时区写入实际数据，`regional` 行对应字段为 NULL，使用前需确认时区。
3. **`paid_free_ads_expenditure_struct_1d` 已废弃**：ETL 通过 `to_json(STRUCT(...))` 将 8 个支出拆分字段打包为 JSON 字符串写入该字段，注释标注 `deprecated`，建议直接使用已展开的 `paid_expenditure_*` 和 `free_expenditure_*` 独立字段。

---

*文档生成时间：2026-04-22*