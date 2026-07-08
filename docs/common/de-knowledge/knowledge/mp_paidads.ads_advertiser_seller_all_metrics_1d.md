<!-- ads-workspace-gdoc-sync: gdoc_id=1-N13fJF2kIxHergUr-zDUfW4v5koAaRhEAlaSb4tp8Q gdoc_url=https://docs.google.com/document/d/1-N13fJF2kIxHergUr-zDUfW4v5koAaRhEAlaSb4tp8Q/edit -->

# mp_paidads.ads_advertiser_seller_all_metrics_1d

**分层：** ADS层（应用数据服务层）
**主键：** `grass_region` + `grass_date` + `shop_id`
**分区：** `grass_date`（日期分区），`grass_region`（地区分区）
**更新频率：** 每日一次（T+1 调度）
**引用频次：** 0（末端 ADS 层宽表，未被其他候选表直接引用）

---

## 业务描述

本表是面向付费广告业务的**卖家维度全量指标宽表**，以店铺（`shop_id`）为最小粒度，将卖家基础属性、广告投放状态、多广告位绩效指标、广告信用充值/扣费/余额、活动预算管理及平台大盘 GMV 等核心数据整合于一张宽表中，覆盖全部地区的每日快照。

本表主要服务于广告运营分析、卖家分层管理、广告主健康度监控等场景，支持按广告位类型（搜索/发现/店铺/ROI等）横向拆分分析。下游消费方可直接基于本表构建仪表盘、卖家分析报告及异常预警模型，无需再跨多张宽表关联。

本表同时提供当日（Daily）与截至今日累计（TD，to-date）两种口径的广告消耗与 GMV 指标，以及过去 7 天滑动窗口维度的广告状态计数，可满足不同时间粒度的对比分析需求。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_date` | date | 数据日期分区，格式 `YYYY-MM-DD`，对应本地时区自然日 |
| `grass_region` | string | 地区分区，如 `MY`、`TH`、`PH` 等，全大写 |

---

### 维度：卖家与店铺基础属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺唯一标识，主键之一 |
| `seller_name` | string | 卖家名称 |
| `seller_type` | string | 卖家类型（如本土/跨境） |
| `seller_status` | string | 卖家账号状态 |
| `seller_tier` | string | 卖家分层级别 |
| `advertiser_status` | string | 广告主账号状态 |
| `advertiser_tier` | string | 广告主分层级别 |
| `cluster` | string | 卖家所属集群/运营分组 |
| `principal_type` | string | 主账号类型 |
| `seller_ads_placement_type` | string | 卖家广告位类型标签 |
| `account_create_datetime` | string | 店铺账号创建时间 |
| `shop_level1_global_be_category` | string | 店铺一级全球类目 |
| `shop_level2_global_be_category` | string | 店铺二级全球类目 |
| `top_selling_item_id` | bigint | 当日销量最高商品 ID（窗口函数取各店铺最大销量商品）⚠️ 该字段为单一商品 ID，不可 SUM；仅代表当日快照最畅销商品 |
| `ads_type` | string | 广告类型标签 |
| `tz_type` | string | 时区类型，本表固定为 `local`（本地时区） |

---

### 维度：卖家标签与标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_principal` | tinyint | 是否主账号，1=是，0=否 |
| `is_cb_seller` | tinyint | 是否跨境卖家，1=是，0=否 |
| `is_official_shop` | tinyint | 是否官方店铺，1=是，0=否 |
| `is_preferred_shop` | tinyint | 是否优选店铺，1=是，0=否 |
| `is_managed_seller` | tinyint | 是否托管卖家，1=是，0=否 |
| `key_seller_90` | tinyint | 是否为90分位关键卖家，1=是，0=否 |
| `key_seller_95` | tinyint | 是否为95分位关键卖家，1=是，0=否 |

---

### 指标：广告活动（Campaign）管理

| 字段 | 类型 | 说明 |
|------|------|------|
| `ongoing_campaign_cnt` | bigint | 当日进行中活动数（全部广告位） |
| `ongoing_campaign_cnt_search_manual_only` | bigint | 仅含搜索手动广告位的进行中活动数 |
| `ongoing_campaign_cnt_search_simple_only` | bigint | 仅含搜索简单广告位的进行中活动数 |
| `ongoing_campaign_cnt_search_manual_simple` | bigint | 同时含搜索手动+简单广告位的进行中活动数 |
| `ongoing_campaign_cnt_discovery_manual` | bigint | 发现位手动广告进行中活动数 |
| `ongoing_campaign_cnt_discovery_simple` | bigint | 发现位简单广告进行中活动数 |
| `ongoing_campaign_cnt_roi_two` | bigint | ROI 二代广告进行中活动数 |
| `pause_campaign_cnt` | bigint | 当日暂停活动数（全部广告位） |
| `pause_campaign_cnt_search_manual_only` | bigint | 仅含搜索手动广告位的暂停活动数 |
| `pause_campaign_cnt_search_simple_only` | bigint | 仅含搜索简单广告位的暂停活动数 |
| `pause_campaign_cnt_search_manual_simple` | bigint | 同时含搜索手动+简单广告位的暂停活动数 |
| `pause_campaign_cnt_discovery_manual` | bigint | 发现位手动广告暂停活动数 |
| `pause_campaign_cnt_discovery_simple` | bigint | 发现位简单广告暂停活动数 |
| `pause_campaign_cnt_roi_two` | bigint | ROI 二代广告暂停活动数 |
| `closed_campaign_cnt` | bigint | 当日已关闭活动数（全部广告位） |
| `closed_campaign_cnt_search_manual_only` | bigint | 仅含搜索手动广告位的已关闭活动数 |
| `closed_campaign_cnt_search_simple_only` | bigint | 仅含搜索简单广告位的已关闭活动数 |
| `closed_campaign_cnt_search_manual_simple` | bigint | 同时含搜索手动+简单广告位的已关闭活动数 |
| `closed_campaign_cnt_discovery_manual` | bigint | 发现位手动广告已关闭活动数 |
| `closed_campaign_cnt_discovery_simple` | bigint | 发现位简单广告已关闭活动数 |
| `closed_campaign_cnt_roi_two` | bigint | ROI 二代广告已关闭活动数 |
| `deleted_campaign_cnt` | bigint | 当日已删除活动数（全部广告位） |
| `deleted_campaign_cnt_search_manual_only` | bigint | 仅含搜索手动广告位的已删除活动数 |
| `deleted_campaign_cnt_search_simple_only` | bigint | 仅含搜索简单广告位的已删除活动数 |
| `deleted_campaign_cnt_search_manual_simple` | bigint | 同时含搜索手动+简单广告位的已删除活动数 |
| `deleted_campaign_cnt_discovery_manual` | bigint | 发现位手动广告已删除活动数 |
| `deleted_campaign_cnt_discovery_simple` | bigint | 发现位简单广告已删除活动数 |
| `deleted_campaign_cnt_roi_two` | bigint | ROI 二代广告已删除活动数 |
| `create_campaign_cnt` | bigint | 当日新建活动数（全部广告位） |
| `create_campaign_cnt_search_manual_only` | bigint | 仅含搜索手动广告位的当日新建活动数 |
| `create_campaign_cnt_search_simple_only` | bigint | 仅含搜索简单广告位的当日新建活动数 |
| `create_campaign_cnt_search_manual_simple` | bigint | 同时含搜索手动+简单广告位的当日新建活动数 |
| `create_campaign_cnt_discovery_manual` | bigint | 发现位手动广告当日新建活动数 |
| `create_campaign_cnt_discovery_simple` | bigint | 发现位简单广告当日新建活动数 |
| `create_campaign_cnt_roi_two` | bigint | ROI 二代广告当日新建活动数 |
| `end_campaign_cnt` | bigint | 当日到期/结束活动数（全部广告位） |
| `end_campaign_cnt_search_manual_only` | bigint | 仅含搜索手动广告位的当日到期活动数 |
| `end_campaign_cnt_search_simple_only` | bigint | 仅含搜索简单广告位的当日到期活动数 |
| `end_campaign_cnt_search_manual_simple` | bigint | 同时含搜索手动+简单广告位的当日到期活动数 |
| `end_campaign_cnt_discovery_manual` | bigint | 发现位手动广告当日到期活动数 |
| `end_campaign_cnt_discovery_simple` | bigint | 发现位简单广告当日到期活动数 |
| `end_campaign_cnt_roi_two` | bigint | ROI 二代广告当日到期活动数 |
| `avg_campaign_items` | double | 平均活动商品数（全部广告位）⚠️ 派生比率字段，不可直接 SUM，需用分子/分母重新计算 |
| `avg_campaign_items_search_manual_only` | double | 仅含搜索手动广告位的平均活动商品数 ⚠️ 同上 |
| `avg_campaign_items_search_simple_only` | double | 仅含搜索简单广告位的平均活动商品数 ⚠️ 同上 |
| `avg_campaign_items_search_manual_simple` | double | 同时含搜索手动+简单广告位的平均活动商品数 ⚠️ 同上 |
| `avg_campaign_items_discovery_manual` | double | 发现位手动广告平均活动商品数 ⚠️ 同上 |
| `avg_campaign_items_discovery_simple` | double | 发现位简单广告平均活动商品数 ⚠️ 同上 |
| `avg_campaign_items_roi_two` | double | ROI 二代广告平均活动商品数 ⚠️ 同上 |

---

### 指标：活动预算管理

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_quota_usd` | double | 店铺所有活动的日预算合计（USD） |
| `daily_quota_usd_search_manual_only` | double | 仅搜索手动广告位活动的日预算合计（USD） |
| `daily_quota_usd_search_simple_only` | double | 仅搜索简单广告位活动的日预算合计（USD） |
| `daily_quota_usd_search_manual_simple` | double | 搜索手动+简单广告位活动的日预算合计（USD） |
| `daily_quota_usd_discovery_manual` | double | 发现位手动广告活动日预算合计（USD） |
| `daily_quota_usd_discovery_simple` | double | 发现位简单广告活动日预算合计（USD） |
| `daily_quota_usd_roi_two` | double | ROI 二代广告活动日预算合计（USD） |
| `total_quota_usd` | double | 店铺所有活动的总预算合计（USD） |
| `total_quota_usd_search_manual_only` | double | 仅搜索手动广告位活动总预算合计（USD） |
| `total_quota_usd_search_simple_only` | double | 仅搜索简单广告位活动总预算合计（USD） |
| `total_quota_usd_search_manual_simple` | double | 搜索手动+简单广告位活动总预算合计（USD） |
| `total_quota_usd_discovery_manual` | double | 发现位手动广告活动总预算合计（USD） |
| `total_quota_usd_discovery_simple` | double | 发现位简单广告活动总预算合计（USD） |
| `total_quota_usd_roi_two` | double | ROI 二代广告活动总预算合计（USD） |
| `avg_campaign_budget` | double | 平均活动预算（USD）⚠️ 派生比率字段，不可直接 SUM，需用分子/分母重新计算 |
| `avg_hit_budget_expense` | double | 触达预算活动的平均消耗⚠️ 派生比率字段，不可直接 SUM |
| `budget_cost_ratio` | double | 预算消耗比率（`daily_deduction / daily_quota_local`）⚠️ 比率字段，不可直接 SUM，聚合时需重新计算：SUM(消耗) / SUM(预算) |
| `hit_budget_campaign_cnt` | bigint | 触达日预算上限的活动数（全部广告位） |
| `hit_budget_campaign_cnt_search_manual_only` | bigint | 仅搜索手动广告位活动触达预算数 |
| `hit_budget_campaign_cnt_search_simple_only` | bigint | 仅搜索简单广告位活动触达预算数 |
| `hit_budget_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简单广告位活动触达预算数 |
| `hit_budget_campaign_cnt_discovery_manual` | bigint | 发现位手动广告活动触达预算数 |
| `hit_budget_campaign_cnt_discovery_simple` | bigint | 发现位简单广告活动触达预算数 |
| `hit_budget_campaign_cnt_roi_two` | bigint | ROI 二代广告活动触达预算数 |
| `hit_budget_campaign_per` | double | 触达预算活动占比⚠️ 比率字段，不可直接 SUM，聚合时需重新计算：SUM(hit_budget_campaign_cnt) / SUM(总活动数) |
| `limited_budget_cnt` | bigint | 设置有限预算的活动数（全部广告位） |
| `limited_budget_cnt_search_manual_only` | bigint | 仅搜索手动广告位的有限预算活动数 |
| `limited_budget_cnt_search_simple_only` | bigint | 仅搜索简单广告位的有限预算活动数 |
| `limited_budget_cnt_search_manual_simple` | bigint | 搜索手动+简单广告位的有限预算活动数 |
| `limited_budget_cnt_discovery_manual` | bigint | 发现位手动广告有限预算活动数 |
| `limited_budget_cnt_discovery_simple` | bigint | 发现位简单广告有限预算活动数 |
| `limited_budget_cnt_roi_two` | bigint | ROI 二代广告有限预算活动数 |
| `unlimited_budget_cnt` | bigint | 设置无限预算的活动数（全部广告位） |
| `unlimited_budget_cnt_search_manual_only` | bigint | 仅搜索手动广告位的无限预算活动数 |
| `unlimited_budget_cnt_search_simple_only` | bigint | 仅搜索简单广告位的无限预算活动数 |
| `unlimited_budget_cnt_search_manual_simple` | bigint | 搜索手动+简单广告位的无限预算活动数 |
| `unlimited_budget_cnt_discovery_manual` | bigint | 发现位手动广告无限预算活动数 |
| `unlimited_budget_cnt_discovery_simple` | bigint | 发现位简单广告无限预算活动数 |
| `unlimited_budget_cnt_roi_two` | bigint | ROI 二代广告无限预算活动数 |
| `daily_budget_campaign_cnt` | bigint | 设置日预算的活动数（全部广告位） |
| `daily_budget_campaign_cnt_search_manual_only` | bigint | 仅搜索手动广告位设置日预算的活动数 |
| `daily_budget_campaign_cnt_search_simple_only` | bigint | 仅搜索简单广告位设置日预算的活动数 |
| `daily_budget_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简单广告位设置日预算的活动数 |
| `daily_budget_campaign_cnt_discovery_manual` | bigint | 发现位手动广告设置日预算的活动数 |
| `daily_budget_campaign_cnt_discovery_simple` | bigint | 发现位简单广告设置日预算的活动数 |
| `daily_budget_campaign_cnt_roi_two` | bigint | ROI 二代广告设置日预算的活动数 |
| `total_budget_campaign_cnt` | bigint | 设置总预算的活动数（全部广告位） |
| `total_budget_campaign_cnt_search_manual_only` | bigint | 仅搜索手动广告位设置总预算的活动数 |
| `total_budget_campaign_cnt_search_simple_only` | bigint | 仅搜索简单广告位设置总预算的活动数 |
| `total_budget_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简单广告位设置总预算的活动数 |
| `total_budget_campaign_cnt_discovery_manual` | bigint | 发现位手动广告设置总预算的活动数 |
| `total_budget_campaign_cnt_discovery_simple` | bigint | 发现位简单广告设置总预算的活动数 |
| `total_budget_campaign_cnt_roi_two` | bigint | ROI 二代广告设置总预算的活动数 |

---

### 指标：广告（Ads）状态计数（当日快照）

| 字段 | 类型 | 说明 |
|------|------|------|
| `active_ads_cnt` | bigint | 当日活跃广告数（全部广告位） |
| `active_ads_cnt_search` | bigint | 搜索广告活跃数 |
| `active_ads_cnt_search_manual` | bigint | 搜索手动广告活跃数 |
| `active_ads_cnt_search_simple` | bigint | 搜索简单广告活跃数 |
| `active_ads_cnt_discovery` | bigint | 发现位广告活跃数 |
| `active_ads_cnt_dd_manual` | bigint | 发现位手动广告活跃数 |
| `active_ads_cnt_dd_simple` | bigint | 发现位简单广告活跃数 |
| `active_ads_cnt_ymal_manual` | bigint | YMAL手动广告活跃数 |
| `active_ads_cnt_ymal_simple` | bigint | YMAL简单广告活跃数 |
| `active_ads_cnt_itemboost` | bigint | ItemBoost广告活跃数 |
| `active_ads_cnt_autoboost` | bigint | AutoBoost广告活跃数 |
| `active_ads_cnt_shop` | bigint | 店铺广告活跃数 |
| `active_ads_cnt_roi_two` | bigint | ROI二代广告活跃数 |
| `ongoing_ads_cnt` | bigint | 当日进行中广告数（全部广告位） |
| `ongoing_ads_cnt_search` | bigint | 搜索广告进行中数 |
| `ongoing_ads_cnt_search_manual` | bigint | 搜索手动广告进行中数 |
| `ongoing_ads_cnt_search_simple` | bigint | 搜索简单广告进行中数 |
| `ongoing_ads_cnt_discovery` | bigint | 发现位广告进行中数 |
| `ongoing_ads_cnt_dd_manual` | bigint | 发现位手动广告进行中数 |
| `ongoing_ads_cnt_dd_simple` | bigint | 发现位简单广告进行中数 |
| `ongoing_ads_cnt_ymal_manual` | bigint | YMAL手动广告进行中数 |
| `ongoing_ads_cnt_ymal_simple` | bigint | YMAL简单广告进行中数 |
| `ongoing_ads_cnt_itemboost` | bigint | ItemBoost广告进行中数 |
| `ongoing_ads_cnt_autoboost` | bigint | AutoBoost广告进行中数 |
| `ongoing_ads_cnt_shop` | bigint | 店铺广告进行中数 |
| `ongoing_ads_cnt_roi_two` | bigint | ROI二代广告进行中数 |
| `pause_ads_cnt` | bigint | 当日暂停广告数（全部广告位） |
| `pause_ads_cnt_search` | bigint | 搜索广告暂停数 |
| `pause_ads_cnt_search_manual` | bigint | 搜索手动广告暂停数 |
| `pause_ads_cnt_search_simple` | bigint | 搜索简单广告暂停数 |
| `pause_ads_cnt_discovery` | bigint | 发现位广告暂停数 |
| `pause_ads_cnt_dd_manual` | bigint | 发现位手动广告暂停数 |
| `pause_ads_cnt_dd_simple` | bigint | 发现位简单广告暂停数 |
| `pause_ads_cnt_ymal_manual` | bigint | YMAL手动广告暂停数 |
| `pause_ads_cnt_ymal_simple` | bigint | YMAL简单广告暂停数 |
| `pause_ads_cnt_itemboost` | bigint | ItemBoost广告暂停数 |
| `pause_ads_cnt_autoboost` | bigint | AutoBoost广告暂停数 |
| `pause_ads_cnt_shop` | bigint | 店铺广告暂停数 |
| `pause_ads_cnt_roi_two` | bigint | ROI二代广告暂停数 |
| `closed_ads_cnt` | bigint | 当日已关闭广告数（全部广告位） |
| `closed_ads_cnt_search` | bigint | 搜索广告已关闭数 |
| `closed_ads_cnt_search_manual` | bigint | 搜索手动广告已关闭数 |
| `closed_ads_cnt_search_simple` | bigint | 搜索简单广告已关闭数 |
| `closed_ads_cnt_discovery` | bigint | 发现位广告已关闭数 |
| `closed_ads_cnt_dd_manual` | bigint | 发现位手动广告已关闭数 |
| `closed_ads_cnt_dd_simple` | bigint | 发现位简单广告已关闭数 |
| `closed_ads_cnt_ymal_manual` | bigint | YMAL手动广告已关闭数 |
| `closed_ads_cnt_ymal_simple` | bigint | YMAL简单广告已关闭数 |
| `closed_ads_cnt_itemboost` | bigint | ItemBoost广告已关闭数 |
| `closed_ads_cnt_autoboost` | bigint | AutoBoost广告已关闭数 |
| `closed_ads_cnt_shop` | bigint | 店铺广告已关闭数 |
| `closed_ads_cnt_roi_two` | bigint | ROI二代广告已关闭数 |
| `deleted_ads_cnt` | bigint | 当日已删除广告数（全部广告位） |
| `deleted_ads_cnt_search` | bigint | 搜索广告已删除数 |
| `deleted_ads_cnt_search_manual` | bigint | 搜索手动广告已删除数 |
| `deleted_ads_cnt_search_simple` | bigint | 搜索简单广告已删除数 |
| `deleted_ads_cnt_discovery` | bigint | 发现位广告已删除数 |
| `deleted_ads_cnt_dd_manual` | bigint | 发现位手动广告已删除数 |
| `deleted_ads_cnt_dd_simple` | bigint | 发现位简单广告已删除数 |
| `deleted_ads_cnt_ymal_manual` | bigint | YMAL手动广告已删除数 |
| `deleted_ads_cnt_ymal_simple` | bigint | YMAL简单广告已删除数 |
| `deleted_ads_cnt_itemboost` | bigint | ItemBoost广告已删除数 |
| `deleted_ads_cnt_autoboost` | bigint | AutoBoost广告已删除数 |
| `deleted_ads_cnt_shop` | bigint | 店铺广告已删除数 |
| `deleted_ads_cnt_roi_two` | bigint | ROI二代广告已删除数 |
| `create_ads_cnt` | bigint | 当日新建广告数（全部广告位） |
| `create_ads_cnt_search` | bigint | 搜索广告当日新建数 |
| `create_ads_cnt_search_manual` | bigint | 搜索手动广告当日新建数 |
| `create_ads_cnt_search_simple` | bigint | 搜索简单广告当日新建数 |
| `create_ads_cnt_discovery` | bigint | 发现位广告当日新建数 |
| `create_ads_cnt_dd_manual` | bigint | 发现位手动广告当日新建数 |
| `create_ads_cnt_dd_simple` | bigint | 发现位简单广告当日新建数 |
| `create_ads_cnt_ymal_manual` | bigint | YMAL手动广告当日新建数 |
| `create_ads_cnt_ymal_simple` | bigint | YMAL简单广告当日新建数 |
| `create_ads_cnt_itemboost` | bigint | ItemBoost广告当日新建数 |
| `create_ads_cnt_autoboost` | bigint | AutoBoost广告当日新建数 |
| `create_ads_cnt_shop` | bigint | 店铺广告当日新建数 |
| `create_ads_cnt_roi_two` | bigint | ROI二代广告当日新建数 |
| `end_ads_cnt` | bigint | 当日到期广告数（全部广告位） |
| `end_ads_cnt_search` | bigint | 搜索广告当日到期数 |
| `end_ads_cnt_search_manual` | bigint | 搜索手动广告当日到期数 |
| `end_ads_cnt_search_simple` | bigint | 搜索简单广告当日到期数 |
| `end_ads_cnt_discovery` | bigint | 发现位广告当日到期数 |
| `end_ads_cnt_dd_manual` | bigint | 发现位手动广告当日到期数 |
| `end_ads_cnt_dd_simple` | bigint | 发现位简单广告当日到期数 |
| `end_ads_cnt_ymal_manual` | bigint | YMAL手动广告当日到期数 |
| `end_ads_cnt_ymal_simple` | bigint | YMAL简单广告当日到期数 |
| `end_ads_cnt_itemboost` | bigint | ItemBoost广告当日到期数 |
| `end_ads_cnt_autoboost` | bigint | AutoBoost广告当日到期数 |
| `end_ads_cnt_shop` | bigint | 店铺广告当日到期数 |
| `end_ads_cnt_roi_two` | bigint | ROI二代广告当日到期数 |

---

### 指标：广告（Ads）状态计数（近7日滑动窗口）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ongoing_ads_cnt_7d` | bigint | 近7日进行中广告数（全部广告位）⚠️ 时效性字段，含过去7天窗口数据，不能与当日字段直接相加 |
| `ongoing_ads_cnt_search_7d` | bigint | 搜索广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_search_manual_7d` | bigint | 搜索手动广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_search_simple_7d` | bigint | 搜索简单广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_discovery_7d` | bigint | 发现位广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_dd_manual_7d` | bigint | 发现位手动广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_dd_simple_7d` | bigint | 发现位简单广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_ymal_manual_7d` | bigint | YMAL手动广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_ymal_simple_7d` | bigint | YMAL简单广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_itemboost_7d` | bigint | ItemBoost广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_autoboost_7d` | bigint | AutoBoost广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_shop_7d` | bigint | 店铺广告近7日进行中数 ⚠️ 同上 |
| `ongoing_ads_cnt_roi_two_7d` | bigint | ROI二代广告近7日进行中数 ⚠️ 同上 |
| `pause_ads_cnt_7d` | bigint | 近7日暂停广告数（全部广告位）⚠️ 同上 |
| `pause_ads_cnt_search_7d` | bigint | 搜索广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_search_manual_7d` | bigint | 搜索手动广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_search_simple_7d` | bigint | 搜索简单广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_discovery_7d` | bigint | 发现位广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_dd_manual_7d` | bigint | 发现位手动广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_dd_simple_7d` | bigint | 发现位简单广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_ymal_manual_7d` | bigint | YMAL手动广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_ymal_simple_7d` | bigint | YMAL简单广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_itemboost_7d` | bigint | ItemBoost广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_autoboost_7d` | bigint | AutoBoost广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_shop_7d` | bigint | 店铺广告近7日暂停数 ⚠️ 同上 |
| `pause_ads_cnt_roi_two_7d` | bigint | ROI二代广告近7日暂停数 ⚠️ 同上 |
| `closed_ads_cnt_7d` | bigint | 近7日已关闭广告数（全部广告位）⚠️ 同上 |
| `closed_ads_cnt_search_7d` | bigint | 搜索广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_search_manual_7d` | bigint | 搜索手动广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_search_simple_7d` | bigint | 搜索简单广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_discovery_7d` | bigint | 发现位广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_dd_manual_7d` | bigint | 发现位手动广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_dd_simple_7d` | bigint | 发现位简单广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_ymal_manual_7d` | bigint | YMAL手动广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_ymal_simple_7d` | bigint | YMAL简单广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_itemboost_7d` | bigint | ItemBoost广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_autoboost_7d` | bigint | AutoBoost广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_shop_7d` | bigint | 店铺广告近7日已关闭数 ⚠️ 同上 |
| `closed_ads_cnt_roi_two_7d` | bigint | ROI二代广告近7日已关闭数 ⚠️ 同上 |
| `deleted_ads_cnt_7d` | bigint | 近7日已删除广告数（全部广告位）⚠️ 同上 |
| `deleted_ads_cnt_search_7d` | bigint | 搜索广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_search_manual_7d` | bigint | 搜索手动广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_search_simple_7d` | bigint | 搜索简单广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_discovery_7d` | bigint | 发现位广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_dd_manual_7d` | bigint | 发现位手动广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_dd_simple_7d` | bigint | 发现位简单广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_ymal_manual_7d` | bigint | YMAL手动广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_ymal_simple_7d` | bigint | YMAL简单广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_itemboost_7d` | bigint | ItemBoost广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_autoboost_7d` | bigint | AutoBoost广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_shop_7d` | bigint | 店铺广告近7日已删除数 ⚠️ 同上 |
| `deleted_ads_cnt_roi_two_7d` | bigint | ROI二代广告近7日已删除数 ⚠️ 同上 |
| `create_ads_cnt_7d` | bigint | 近7日新建广告数（全部广告位）⚠️ 同上 |
| `create_ads_cnt_search_7d` | bigint | 搜索广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_search_manual_7d` | bigint | 搜索手动广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_search_simple_7d` | bigint | 搜索简单广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_discovery_7d` | bigint | 发现位广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_dd_manual_7d` | bigint | 发现位手动广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_dd_simple_7d` | bigint | 发现位简单广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_ymal_manual_7d` | bigint | YMAL手动广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_ymal_simple_7d` | bigint | YMAL简单广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_itemboost_7d` | bigint | ItemBoost广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_autoboost_7d` | bigint | AutoBoost广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_shop_7d` | bigint | 店铺广告近7日新建数 ⚠️ 同上 |
| `create_ads_cnt_roi_two_7d` | bigint | ROI二代广告近7日新建数 ⚠️ 同上 |
| `end_ads_cnt_7d` | bigint | 近7日到期广告数（全部广告位）⚠️ 同上 |
| `end_ads_cnt_search_7d` | bigint | 搜索广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_search_manual_7d` | bigint | 搜索手动广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_search_simple_7d` | bigint | 搜索简单广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_discovery_7d` | bigint | 发现位广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_dd_manual_7d` | bigint | 发现位手动广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_dd_simple_7d` | bigint | 发现位简单广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_ymal_manual_7d` | bigint | YMAL手动广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_ymal_simple_7d` | bigint | YMAL简单广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_itemboost_7d` | bigint | ItemBoost广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_autoboost_7d` | bigint | AutoBoost广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_shop_7d` | bigint | 店铺广告近7日到期数 ⚠️ 同上 |
| `end_ads_cnt_roi_two_7d` | bigint | ROI二代广告近7日到期数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_7d` | bigint | 近7日有实际花费的广告数（全部广告位）⚠️ 滑动窗口字段，不可与当日字段直接加和 |
| `have_expenditure_ads_cnt_search_7d` | bigint | 搜索广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_search_manual_7d` | bigint | 搜索手动广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_search_simple_7d` | bigint | 搜索简单广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_discovery_7d` | bigint | 发现位广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_dd_manual_7d` | bigint | 发现位手动广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_dd_simple_7d` | bigint | 发现位简单广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_ymal_manual_7d` | bigint | YMAL手动广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_ymal_simple_7d` | bigint | YMAL简单广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_itemboost_7d` | bigint | ItemBoost广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_autoboost_7d` | bigint | AutoBoost广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_shop_7d` | bigint | 店铺广告近7日有花费数 ⚠️ 同上 |
| `have_expenditure_ads_cnt_roi_two_7d` | bigint | ROI二代广告近7日有花费数 ⚠️ 同上 |

---

### 指标：广告绩效（当日日维度）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_imp_cnt` | bigint | 当日广告曝光次数（全部广告位） |
| `ads_imp_cnt_search` | bigint | 搜索广告曝光次数 |
| `ads_imp_cnt_search_manual` | bigint | 搜索手动广告曝光次数 |
| `ads_imp_cnt_search_simple` | bigint | 搜索简单广告曝光次数 |
| `ads_imp_cnt_discovery` | bigint | 发现位广告曝光次数 |
| `ads_imp_cnt_dd_manual` | bigint | 发现位手动广告曝光次数 |
| `ads_imp_cnt_dd_simple` | bigint | 发现位简单广告曝光次数 |
| `ads_imp_cnt_ymal_manual` | bigint | YMAL手动广告曝光次数 |
| `ads_imp_cnt_ymal_simple` | bigint | YMAL简单广告曝光次数 |
| `ads_imp_cnt_itemboost` | bigint | ItemBoost广告曝光次数 |
| `ads_imp_cnt_autoboost` | bigint | AutoBoost广告曝光次数 |
| `ads_imp_cnt_shop` | bigint | 店铺广告曝光次数 |
| `ads_imp_cnt_roi_two` | bigint | ROI二代广告曝光次数 |
| `ads_click_cnt` | bigint | 当日广告点击次数（全部广告位） |
| `ads_click_cnt_search` | bigint | 搜索广告点击次数 |
| `ads_click_cnt_search_manual` | bigint | 搜索手动广告点击次数 |
| `ads_click_cnt_search_simple` | bigint | 搜索简单广告点击次数 |
| `ads_click_cnt_discovery` | bigint | 发现位广告点击次数 |
| `ads_click_cnt_dd_manual` | bigint | 发现位手动广告点击次数 |
| `ads_click_cnt_dd_simple` | bigint | 发现位简单广告点击次数 |
| `ads_click_cnt_ymal_manual` | bigint | YMAL手动广告点击次数 |
| `ads_click_cnt_ymal_simple` | bigint | YMAL简单广告点击次数 |
| `ads_click_cnt_itemboost` | bigint | ItemBoost广告点击次数 |
| `ads_click_cnt_autoboost` | bigint | AutoBoost广告点击次数 |
| `ads_click_cnt_shop` | bigint | 店铺广告点击次数 |
| `ads_click_cnt_roi_two` | bigint | ROI二代广告点击次数 |
| `ads_direct_order_cnt` | bigint | 当日广告直接归因订单数（全部广告位） |
| `ads_direct_order_cnt_search` | bigint | 搜索广告直接归因订单数 |
| `ads_direct_order_cnt_search_manual` | bigint | 搜索手动广告直接归因订单数 |
| `ads_direct_order_cnt_search_simple` | bigint | 搜索简单广告直接归因订单数 |
| `ads_direct_order_cnt_discovery` | bigint | 发现位广告直接归因订单数 |
| `ads_direct_order_cnt_dd_manual` | bigint | 发现位手动广告直接归因订单数 |
| `ads_direct_order_cnt_dd_simple` | bigint | 发现位简单广告直接归因订单数 |
| `ads_direct_order_cnt_ymal_manual` | bigint | YMAL手动广告直接归因订单数 |
| `ads_direct_order_cnt_ymal_simple` | bigint | YMAL简单广告直接归因订单数 |
| `ads_direct_order_cnt_itemboost` | bigint | ItemBoost广告直接归因订单数 |
| `ads_direct_order_cnt_autoboost` | bigint | AutoBoost广告直接归因订单数 |
| `ads_direct_order_cnt_shop` | bigint | 店铺广告直接归因订单数 |
| `ads_direct_order_cnt_roi_two` | bigint | ROI二代广告直接归因订单数 |
| `ads_broad_order_cnt` | bigint | 当日广告宽泛归因订单数（全部广告位） |
| `ads_broad_order_cnt_search` | bigint | 搜索广告宽泛归因订单数 |
| `ads_broad_order_cnt_search_manual` | bigint | 搜索手动广告宽泛归因订单数 |
| `ads_broad_order_cnt_search_simple` | bigint | 搜索简单广告宽泛归因订单数 |
| `ads_broad_order_cnt_discovery` | bigint | 发现位广告宽泛归因订单数 |
| `ads_broad_order_cnt_dd_manual` | bigint | 发现位手动广告宽泛归因订单数 |
| `ads_broad_order_cnt_dd_simple` | bigint | 发现位简单广告宽泛归因订单数 |
| `ads_broad_order_cnt_ymal_manual` | bigint | YMAL手动广告宽泛归因订单数 |
| `ads_broad_order_cnt_ymal_simple` | bigint | YMAL简单广告宽泛归因订单数 |
| `ads_broad_order_cnt_itemboost` | bigint | ItemBoost广告宽泛归因订单数 |
| `ads_broad_order_cnt_autoboost` | bigint | AutoBoost广告宽泛归因订单数 |
| `ads_broad_order_cnt_shop` | bigint | 店铺广告宽泛归因订单数 |
| `ads_broad_order_cnt_roi_two` | bigint | ROI二代广告宽泛归因订单数 |
| `ads_direct_gmv_usd` | double | 当日广告直接归因GMV（USD，全部广告位） |
| `ads_direct_gmv_usd_search` | double | 搜索广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_search_manual` | double | 搜索手动广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_search_simple` | double | 搜索简单广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_discovery` | double | 发现位广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_dd_manual` | double | 发现位手动广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_dd_simple` | double | 发现位简单广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_ymal_manual` | double | YMAL手动广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_ymal_simple` | double | YMAL简单广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_itemboost` | double | ItemBoost广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_autoboost` | double | AutoBoost广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_shop` | double | 店铺广告直接归因GMV（USD） |
| `ads_direct_gmv_usd_roi_two` | double | ROI二代广告直接归因GMV（USD） |
| `ads_broad_gmv_usd` | double | 当日广告宽泛归因GMV（USD，全部广告位） |
| `ads_broad_gmv_usd_search` | double | 搜索广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_search_manual` | double | 搜索手动广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_search_simple` | double | 搜索简单广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_discovery` | double | 发现位广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_dd_manual` | double | 发现位手动广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_dd_simple` | double | 发现位简单广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_ymal_manual` | double | YMAL手动广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_ymal_simple` | double | YMAL简单广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_itemboost` | double | ItemBoost广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_autoboost` | double | AutoBoost广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_shop` | double | 店铺广告宽泛归因GMV（USD） |
| `ads_broad_gmv_usd_roi_two` | double | ROI二代广告宽泛归因GMV（USD） |
| `ads_revenue_usd` | double | 当日广告花费/消耗（USD，全部广告位） |
| `ads_revenue_usd_search` | double | 搜索广告当日花费（USD） |
| `ads_revenue_usd_search_manual` | double | 搜索手动广告当日花费（USD） |
| `ads_revenue_usd_search_simple` | double | 搜索简单广告当日花费（USD） |
| `ads_revenue_usd_discovery` | double | 发现位广告当日花费（USD） |
| `ads_revenue_usd_dd_manual` | double | 发现位手动广告当日花费（USD） |
| `ads_revenue_usd_dd_simple` | double | 发现位简单广告当日花费（USD） |
| `ads_revenue_usd_ymal_manual` | double | YMAL手动广告当日花费（USD） |
| `ads_revenue_usd_ymal_simple` | double | YMAL简单广告当日花费（USD） |
| `ads_revenue_usd_itemboost` | double | ItemBoost广告当日花费（USD） |
| `ads_revenue_usd_autoboost` | double | AutoBoost广告当日花费（USD） |
| `ads_revenue_usd_shop` | double | 店铺广告当日花费（USD） |
| `ads_revenue_usd_roi_two` | double | ROI二代广告当日花费（USD） |
| `have_expenditure_ads_cnt` | bigint | 当日有实际花费的广告数（全部广告位） |
| `have_expenditure_ads_cnt_search` | bigint | 搜索广告当日有花费数 |
| `have_expenditure_ads_cnt_search_manual` | bigint | 搜索手动广告当日有花费数 |
| `have_expenditure_ads_cnt_search_simple` | bigint | 搜索简单广告当日有花费数 |
| `have_expenditure_ads_cnt_discovery` | bigint | 发现位广告当日有花费数 |
| `have_expenditure_ads_cnt_dd_manual` | bigint | 发现位手动广告当日有花费数 |
| `have_expenditure_ads_cnt_dd_simple` | bigint | 发现位简单广告当日有花费数 |
| `have_expenditure_ads_cnt_ymal_manual` | bigint | YMAL手动广告当日有花费数 |
| `have_expenditure_ads_cnt_ymal_simple` | bigint | YMAL简单广告当日有花费数 |
| `have_expenditure_ads_cnt_itemboost` | bigint | ItemBoost广告当日有花费数 |
| `have_expenditure_ads_cnt_autoboost` | bigint | AutoBoost广告当日有花费数 |
| `have_expenditure_ads_cnt_shop` | bigint | 店铺广告当日有花费数 |
| `have_expenditure_ads_cnt_roi_two` | bigint | ROI二代广告当日有花费数 |

---

### 指标：广告绩效衍生比率（当日）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_ctr` | double | 广告点击率（CTR = 点击/曝光）⚠️ 比率字段，不可直接 SUM，多行聚合请用 SUM(ads_click_cnt)/SUM(ads_imp_cnt) |
| `ads_cr` | double | 广告转化率（CR = 直接订单/点击）⚠️ 同上，聚合请用 SUM(ads_direct_order_cnt)/SUM(ads_click_cnt) |
| `ads_ctr_cr` | double | CTR×CR 综合指标⚠️ 派生字段，不可直接 SUM |
| `ads_direct_order_roi` | double | 广告直接订单ROI（直接GMV/花费）⚠️ 比率字段，不可直接 SUM，聚合请用 SUM(ads_direct_gmv_usd)/SUM(ads_revenue_usd) |
| `ads_broad_order_roi` | double | 广告宽泛订单ROI（宽泛GMV/花费）⚠️ 比率字段，不可直接 SUM，聚合请用 SUM(ads_broad_gmv_usd)/SUM(ads_revenue_usd) |
| `ads_take_rate` | double | 广告变现率（广告收入/平台GMV）⚠️ 比率字段，不可直接 SUM |
| `ads_imp_per` | double | 广告曝光占比（广告曝光/总曝光）⚠️ 比率字段，不可直接 SUM |
| `ads_direct_gmv_per` | double | 广告直接GMV占平台GMV比例⚠️ 比率字段，不可直接 SUM |
| `ads_direct_order_per` | double | 广告直接订单占平台总订单比例⚠️ 比率字段，不可直接 SUM |
| `ads_order_contribution` | double | 广告订单贡献度⚠️ 派生字段，不可直接 SUM |
| `ads_item_ctr` | double | 广告商品点击率⚠️ 比率字段，不可直接 SUM |
| `ads_item_cr` | double | 广告商品转化率⚠️ 比率字段，不可直接 SUM |
| `ads_item_ctr_cr` | double | 广告商品CTR×CR⚠️ 派生字段，不可直接 SUM |

---

### 指标：广告绩效 TD（截至今日累计）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_revenue_usd_td` | double | 广告花费月累计（USD，全部广告位）⚠️ TD字段为当月截至当日累计值，跨多天查询时不可直接 SUM，需仅取最新日期数据 |
| `ads_revenue_usd_td_search` | double | 搜索广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_search_manual` | double | 搜索手动广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_search_simple` | double | 搜索简单广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_discovery` | double | 发现位广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_dd_manual` | double | 发现位手动广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_dd_simple` | double | 发现位简单广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_ymal_manual` | double | YMAL手动广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_ymal_simple` | double | YMAL简单广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_itemboost` | double | ItemBoost广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_autoboost` | double | AutoBoost广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_shop` | double | 店铺广告花费月累计（USD）⚠️ 同上 |
| `ads_revenue_usd_td_roi_two` | double | ROI二代广告花费月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td` | double | 广告GMV月累计（USD，全部广告位）⚠️ 同上 |
| `ads_gmv_usd_td_search` | double | 搜索广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_search_manual` | double | 搜索手动广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_search_simple` | double | 搜索简单广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_discovery` | double | 发现位广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_dd_manual` | double | 发现位手动广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_dd_simple` | double | 发现位简单广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_ymal_manual` | double | YMAL手动广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_ymal_simple` | double | YMAL简单广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_itemboost` | double | ItemBoost广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_autoboost` | double | AutoBoost广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_shop` | double | 店铺广告GMV月累计（USD）⚠️ 同上 |
| `ads_gmv_usd_td_roi_two` | double | ROI二代广告GMV月累计（USD）⚠️ 同上 |

---

### 指标：商品维度广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_item_imp_cnt` | bigint | 广告商品曝光次数（有活跃广告的商品，来自商品跟踪数据） |
| `ads_item_click_cnt` | bigint | 广告商品点击次数 |
| `ads_item_order_cnt` | bigint | 广告商品订单数 |
| `ads_item_gmv_usd` | double | 广告商品GMV（USD） |
| `shop_item_imp_cnt` | bigint | 店铺商品总曝光次数（含广告+自然） |
| `shop_item_click_cnt` | bigint | 店铺商品总点击次数（含广告+自然） |
| `have_ads_items_cnt` | bigint | 有活跃广告的商品数（全部广告位） |
| `have_ads_items_cnt_search` | bigint | 搜索广告下有活跃广告的商品数 |
| `have_ads_items_cnt_search_manual` | bigint | 搜索手动广告下有活跃广告的商品数 |
| `have_ads_items_cnt_search_simple` | bigint | 搜索简单广告下有活跃广告的商品数 |
| `have_ads_items_cnt_discovery` | bigint | 发现位广告下有活跃广告的商品数 |
| `have_ads_items_cnt_dd_manual` | bigint | 发现位手动广告下有活跃广告的商品数 |
| `have_ads_items_cnt_dd_simple` | bigint | 发现位简单广告下有活跃广告的商品数 |
| `have_ads_items_cnt_ymal_manual` | bigint | YMAL手动广告下有活跃广告的商品数 |
| `have_ads_items_cnt_ymal_simple` | bigint | YMAL简单广告下有活跃广告的商品数 |
| `have_ads_items_cnt_itemboost` | bigint | ItemBoost广告下有活跃广告的商品数 |
| `have_ads_items_cnt_autoboost` | bigint | AutoBoost广告下有活跃广告的商品数 |
| `have_ads_items_cnt_shop` | bigint | 店铺广告下有活跃广告的商品数 |
| `have_ads_items_cnt_roi_two` | bigint | ROI二代广告下有活跃广告的商品数 |
| `have_ads_order_items_cnt` | bigint | 有广告订单的商品数（全部广告位） |
| `have_ads_order_items_cnt_search` | bigint | 搜索广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_search_manual` | bigint | 搜索手动广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_search_simple` | bigint | 搜索简单广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_discovery` | bigint | 发现位广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_dd_manual` | bigint | 发现位手动广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_dd_simple` | bigint | 发现位简单广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_ymal_manual` | bigint | YMAL手动广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_ymal_simple` | bigint | YMAL简单广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_itemboost` | bigint | ItemBoost广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_autoboost` | bigint | AutoBoost广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_shop` | bigint | 店铺广告下有广告订单的商品数 |
| `have_ads_order_items_cnt_roi_two` | bigint | ROI二代广告下有广告订单的商品数 |
| `newly_create_ads_items_cnt` | bigint | 当日新建广告的商品数（全部广告位） |
| `newly_create_ads_items_cnt_search` | bigint | 搜索广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_search_manual` | bigint | 搜索手动广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_search_simple` | bigint | 搜索简单广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_discovery` | bigint | 发现位广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_dd_manual` | bigint | 发现位手动广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_dd_simple` | bigint | 发现位简单广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_ymal_manual` | bigint | YMAL手动广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_ymal_simple` | bigint | YMAL简单广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_itemboost` | bigint | ItemBoost广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_autoboost` | bigint | AutoBoost广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_shop` | bigint | 店铺广告当日新建广告的商品数 |
| `newly_create_ads_items_cnt_roi_two` | bigint | ROI二代广告当日新建广告的商品数 |
| `ongoing_ads_items_cnt` | bigint | 进行中广告的商品数（全部广告位） |
| `ongoing_ads_items_cnt_search` | bigint | 搜索广告进行中商品数 |
| `ongoing_ads_items_cnt_search_manual` | bigint | 搜索手动广告进行中商品数 |
| `ongoing_ads_items_cnt_search_simple` | bigint | 搜索简单广告进行中商品数 |
| `ongoing_ads_items_cnt_discovery` | bigint | 发现位广告进行中商品数 |
| `ongoing_ads_items_cnt_dd_manual` | bigint | 发现位手动广告进行中商品数 |
| `ongoing_ads_items_cnt_dd_simple` | bigint | 发现位简单广告进行中商品数 |
| `ongoing_ads_items_cnt_ymal_manual` | bigint | YMAL手动广告进行中商品数 |
| `ongoing_ads_items_cnt_ymal_simple` | bigint | YMAL简单广告进行中商品数 |
| `ongoing_ads_items_cnt_itemboost` | bigint | ItemBoost广告进行中商品数 |
| `ongoing_ads_items_cnt_autoboost` | bigint | AutoBoost广告进行中商品数 |
| `ongoing_ads_items_cnt_shop` | bigint | 店铺广告进行中商品数 |
| `ongoing_ads_items_cnt_roi_two` | bigint | ROI二代广告进行中商品数 |
| `closed_ads_items_cnt` | bigint | 已关闭广告的商品数（全部广告位） |
| `closed_ads_items_cnt_search` | bigint | 搜索广告已关闭商品数 |
| `closed_ads_items_cnt_search_manual` | bigint | 搜索手动广告已关闭商品数 |
| `closed_ads_items_cnt_search_simple` | bigint | 搜索简单广告已关闭商品数 |
| `closed_ads_items_cnt_discovery` | bigint | 发现位广告已关闭商品数 |
| `closed_ads_items_cnt_dd_manual` | bigint | 发现位手动广告已关闭商品数 |
| `closed_ads_items_cnt_dd_simple` | bigint | 发现位简单广告已关闭商品数 |
| `closed_ads_items_cnt_ymal_manual` | bigint | YMAL手动广告已关闭商品数 |
| `closed_ads_items_cnt_ymal_simple` | bigint | YMAL简单广告已关闭商品数 |
| `closed_ads_items_cnt_itemboost` | bigint | ItemBoost广告已关闭商品数 |
| `closed_ads_items_cnt_autoboost` | bigint | AutoBoost广告已关闭商品数 |
| `closed_ads_items_cnt_shop` | bigint | 店铺广告已关闭商品数 |
| `closed_ads_items_cnt_roi_two` | bigint | ROI二代广告已关闭商品数 |
| `end_campaign_items_cnt` | bigint | 活动到期的商品数（全部广告位） |
| `end_campaign_items_cnt_search` | bigint | 搜索广告活动到期商品数 |
| `end_campaign_items_cnt_search_manual` | bigint | 搜索手动广告活动到期商品数 |
| `end_campaign_items_cnt_search_simple` | bigint | 搜索简单广告活动到期商品数 |
| `end_campaign_items_cnt_discovery` | bigint | 发现位广告活动到期商品数 |
| `end_campaign_items_cnt_dd_manual` | bigint | 发现位手动广告活动到期商品数 |
| `end_campaign_items_cnt_dd_simple` | bigint | 发现位简单广告活动到期商品数 |
| `end_campaign_items_cnt_ymal_manual` | bigint | YMAL手动广告活动到期商品数 |
| `end_campaign_items_cnt_ymal_simple` | bigint | YMAL简单广告活动到期商品数 |
| `end_campaign_items_cnt_itemboost` | bigint | ItemBoost广告活动到期商品数 |
| `end_campaign_items_cnt_autoboost` | bigint | AutoBoost广告活动到期商品数 |
| `end_campaign_items_cnt_shop` | bigint | 店铺广告活动到期商品数 |
| `end_campaign_items_cnt_roi_two` | bigint | ROI二代广告活动到期商品数 |
| `have_expenditure_items_cnt` | bigint | 有广告花费的商品数（全部广告位） |
| `have_expenditure_items_cnt_search` | bigint | 搜索广告有花费的商品数 |
| `have_expenditure_items_cnt_search_manual` | bigint | 搜索手动广告有花费的商品数 |
| `have_expenditure_items_cnt_search_simple` | bigint | 搜索简单广告有花费的商品数 |
| `have_expenditure_items_cnt_discovery` | bigint | 发现位广告有花费的商品数 |
| `have_expenditure_items_cnt_dd_manual` | bigint | 发现位手动广告有花费的商品数 |
| `have_expenditure_items_cnt_dd_simple` | bigint | 发现位简单广告有花费的商品数 |
| `have_expenditure_items_cnt_ymal_manual` | bigint | YMAL手动广告有花费的商品数 |
| `have_expenditure_items_cnt_ymal_simple` | bigint | YMAL简单广告有花费的商品数 |
| `have_expenditure_items_cnt_itemboost` | bigint | ItemBoost广告有花费的商品数 |
| `have_expenditure_items_cnt_autoboost` | bigint | AutoBoost广告有花费的商品数 |
| `have_expenditure_items_cnt_shop` | bigint | 店铺广告有花费的商品数 |
| `have_expenditure_items_cnt_roi_two` | bigint | ROI二代广告有花费的商品数 |

---

### 指标：平台大盘与自然流量

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_gmv_usd` | double | 店铺当日平台总GMV（USD，含广告+自然） |
| `platform_gmv_usd_td` | double | 店铺当日平台GMV月累计（USD）⚠️ TD字段，跨多天查询时不可直接 SUM，需仅取最新日期数据 |
| `ads_platform_order_cnt` | bigint | 广告商品贡献的平台订单数 |
| `org_platform_order_cnt` | bigint | 自然商品贡献的平台订单数 |
| `org_imp_cnt` | bigint | 自然流量曝光次数（店铺维度） |
| `org_click_cnt` | bigint | 自然流量点击次数 |
| `org_direct_order_cnt` | bigint | 自然流量直接归因订单数 |
| `org_broad_order_cnt` | bigint | 自然流量宽泛归因订单数 |
| `org_direct_gmv_usd` | double | 自然流量直接归因GMV（USD） |
| `org_broad_gmv_usd` | double | 自然流量宽泛归因GMV（USD） |
| `org_ctr` | double | 自然流量点击率（CTR）⚠️ 比率字段，不可直接 SUM |
| `org_cr` | double | 自然流量转化率（CR）⚠️ 比率字段，不可直接 SUM |
| `org_ctr_cr` | double | 自然流量CTR×CR⚠️ 派生字段，不可直接 SUM |
| `org_order_contribution` | double | 自然流量订单贡献度⚠️ 派生字段，不可直接 SUM |

---

### 指标：店铺商品库存与活跃度

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_items_cnt` | bigint | 店铺总商品数 |
| `newly_items_cnt` | bigint | 当日新建商品数 |
| `active_items_cnt` | bigint | 近30天有订单的活跃商品数 |
| `have_imp_items_cnt` | bigint | 当日有曝光的商品数 |
| `have_click_items_cnt` | bigint | 当日有点击的商品数 |
| `have_order_items_cnt` | bigint | 当日有订单的商品数 |

---

### 指标：广告信用充值

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_topup_amt` | double | 当日总充值金额（本地货币） |
| `total_topup_amt_usd` | double | 当日总充值金额（USD） |
| `seller_topup_amt` | double | 卖家主动充值金额（本地货币） |
| `seller_topup_amt_usd` | double | 卖家主动充值金额（USD） |
| `seller_one_time_topup_amt` | double | 卖家一次性充值金额（本地货币） |
| `seller_one_time_topup_amt_usd` | double | 卖家一次性充值金额（USD） |
| `seller_auto_topup_amt` | double | 卖家自动续充金额（本地货币） |
| `seller_auto_topup_amt_usd` | double | 卖家自动续充金额（USD） |
| `seller_auto_fpaid_credit_topup_amt_usd` | double | 卖家自动续充付费信用金额（USD） |
| `seller_auto_paid_credit_topup_amt` | double | 卖家自动续充付费信用金额（本地货币） |
| `seller_free_credit_topup_amt` | double | 卖家获得的免费信用充值金额（本地货币） |
| `seller_free_credit_topup_amt_usd` | double | 卖家获得的免费信用充值金额（USD） |
| `seller_one_time_free_credit_topup_amt` | double | 卖家一次性免费信用充值（本地货币） |
| `seller_one_time_free_credit_topup_amt_usd` | double | 卖家一次性免费信用充值（USD） |
| `seller_one_time_paid_credit_topup_amt` | double | 卖家一次性付费信用充值（本地货币） |
| `seller_one_time_paid_credit_topup_amt_usd` | double | 卖家一次性付费信用充值（USD） |
| `seller_paid_credit_topup_amt` | double | 卖家付费信用充值总额（本地货币） |
| `seller_paid_credit_topup_amt_usd` | double | 卖家付费信用充值总额（USD） |
| `free_credit_topup_amt` | double | 免费信用充值总额（本地货币，含所有来源） |
| `free_credit_topup_amt_usd` | double | 免费信用充值总额（USD） |
| `paid_credit_topup_amt` | double | 付费信用充值总额（本地货币，含所有来源） |
| `paid_credit_topup_amt_usd` | double | 付费信用充值总额（USD） |
| `voucher_topup_amt` | double | 券充值金额（本地货币） |
| `voucher_topup_amt_usd` | double | 券充值金额（USD） |
| `voucher_free_credit_topup_amt` | double | 券免费信用充值金额（本地货币） |
| `voucher_free_credit_topup_amt_usd` | double | 券免费信用充值金额（USD） |
| `voucher_paid_credit_topup_amt` | double | 券付费信用充值金额（本地货币） |
| `voucher_paid_credit_topup_amt_usd` | double | 券付费信用充值金额（USD） |
| `package_topup_amt` | double | 套餐充值金额（本地货币） |
| `package_topup_amt_usd` | double | 套餐充值金额（USD） |
| `package_free_credit_topup_amt` | double | 套餐免费信用充值金额（本地货币） |
| `package_free_credit_topup_amt_usd` | double | 套餐免费信用充值金额（USD） |
| `package_paid_credit_topup_amt` | double | 套餐付费信用充值金额（本地货币） |
| `package_paid_credit_topup_amt_usd` | double | 套餐付费信用充值金额（USD） |
| `admin_topup_amt` | double | 管理员充值总额（本地货币） |
| `admin_topup_amt_usd` | double | 管理员充值总额（USD） |
| `admin_manual_topup_amt` | double | 管理员手动充值金额（本地货币） |
| `admin_manual_topup_amt_usd` | double | 管理员手动充值金额（USD） |
| `admin_manual_topup_cb_amt_usd` | double | 管理员手动充值回调金额（USD） |
| `admin_manual_cb_topup_amt` | double | 管理员手动充值回调金额（本地货币） |
| `admin_manual_adjust_topup_amt` | double | 管理员手动调整充值金额（本地货币） |
| `admin_manual_adjust_topup_amt_usd` | double | 管理员手动调整充值金额（USD） |
| `admin_manual_free_credit_topup_amt` | double | 管理员手动免费信用充值（本地货币） |
| `admin_manual_free_credit_topup_amt_usd` | double | 管理员手动免费信用充值（USD） |
| `admin_manual_paid_credit_topup_amt` | double | 管理员手动付费信用充值（本地货币） |
| `admin_manual_paid_credit_topup_amt_usd` | double | 管理员手动付费信用充值（USD） |
| `admin_api_topup_amt` | double | 管理员API充值金额（本地货币） |
| `admin_api_topup_amt_usd` | double | 管理员API充值金额（USD） |
| `admin_api_free_credit_topup_amt` | double | 管理员API免费信用充值（本地货币） |
| `admin_api_free_credit_topup_amt_usd` | double | 管理员API免费信用充值（USD） |
| `admin_api_seller_mission_topup_amt` | double | 任务奖励充值金额（本地货币） |
| `admin_api_seller_mission_topup_amt_usd` | double | 任务奖励充值金额（USD） |
| `admin_api_seller_mission_free_credit_topup_amt` | double | 任务奖励免费信用充值（本地货币） |
| `admin_api_seller_mission_free_credit_topup_amt_usd` | double | 任务奖励免费信用充值（USD） |
| `admin_api_qss_topup_amt` | double | QSS渠道充值金额（本地货币） |
| `admin_api_qss_topup_amt_usd` | double | QSS渠道充值金额（USD） |
| `admin_api_qss_free_credit_topup_amt` | double | QSS渠道免费信用充值（本地货币） |
| `admin_api_qss_free_credit_topup_amt_usd` | double | QSS渠道免费信用充值（USD） |
| `admin_free_credit_topup_amt` | double | 管理员免费信用充值总额（本地货币） |
| `admin_free_credit_topup_amt_usd` | double | 管理员免费信用充值总额（USD） |
| `admin_paid_credit_topup_amt` | double | 管理员付费信用充值总额（本地货币） |
| `admin_paid_credit_topup_amt_usd` | double | 管理员付费信用充值总额（USD） |

---

### 指标：广告信用扣费

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_deduction_amt` | double | 当日广告总扣费金额（本地货币） |
| `total_deduction_amt_usd` | double | 当日广告总扣费金额（USD） |
| `free_credit_deduction_amt` | double | 免费信用扣费金额（本地货币） |
| `free_credit_deduction_amt_usd` | double | 免费信用扣费金额（USD） |
| `paid_credit_deduction_amt` | double | 付费信用扣费金额（本地货币） |
| `paid_credit_deduction_amt_usd` | double | 付费信用扣费金额（USD） |
| `voucher_free_credit_deduction_amt` | double | 券免费信用扣费金额（本地货币） |
| `voucher_free_credit_deduction_amt_usd` | double | 券免费信用扣费金额（USD） |
| `package_free_credit_deduction_amt` | double | 套餐免费信用扣费金额（本地货币） |
| `package_free_credit_deduction_amt_usd` | double | 套餐免费信用扣费金额（USD） |
| `seller_mission_free_credit_deduction_amt` | double | 任务奖励免费信用扣费金额（本地货币） |
| `seller_mission_free_credit_deduction_amt_usd` | double | 任务奖励免费信用扣费金额（USD） |
| `manual_free_credit_deduction_amt` | double | 手动免费信用扣费金额（本地货币） |
| `manual_free_credit_deduction_amt_usd` | double | 手动免费信用扣费金额（USD） |
| `srm_free_credit_deduction_amt` | double | SRM免费信用扣费金额（本地货币） |
| `srm_free_credit_deduction_amt_usd` | double | SRM免费信用扣费金额（USD） |

---

### 指标：广告信用过期

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_credit_expiry_amt` | double | 当日信用过期总金额（本地货币） |
| `total_credit_expiry_amt_usd` | double | 当日信用过期总金额（USD） |
| `free_credit_expiry_amt` | double | 免费信用过期金额（本地货币） |
| `free_credit_expiry_amt_usd` | double | 免费信用过期金额（USD） |
| `paid_credit_expiry_amt` | double | 付费信用过期金额（本地货币） |
| `paid_credit_expiry_amt_usd` | double | 付费信用过期金额（USD） |
| `voucher_free_credit_expiry_amt` | double | 券免费信用过期金额（本地货币） |
| `voucher_free_credit_expiry_amt_usd` | double | 券免费信用过期金额（USD） |
| `package_free_credit_expiry_amt` | double | 套餐免费信用过期金额（本地货币） |
| `package_free_credit_expiry_amt_usd` | double | 套餐免费信用过期金额（USD） |
| `seller_mission_free_credit_expiry_amt` | double | 任务奖励免费信用过期金额（本地货币） |
| `seller_mission_free_credit_expiry_amt_usd` | double | 任务奖励免费信用过期金额（USD） |
| `manual_free_credit_expiry_amt` | double | 手动免费信用过期金额（本地货币） |
| `manual_free_credit_expiry_amt_usd` | double | 手动免费信用过期金额（USD） |
| `srm_free_credit_expiry_amt` | double | SRM免费信用过期金额（本地货币） |
| `srm_free_credit_expiry_amt_usd` | double | SRM免费信用过期金额（USD） |

---

### 指标：广告信用余额（日终快照）

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_balance_amt` | double | 日终总信用余额（本地货币）⚠️ 快照值，不同日期记录不可直接 SUM，应取最新日期单条记录 |
| `total_balance_amt_usd` | double | 日终总信用余额（USD）⚠️ 同上 |
| `free_credit_balance_amt` | double | 日终免费信用余额（本地货币）⚠️ 同上 |
| `free_credit_balance_amt_usd` | double | 日终免费信用余额（USD）⚠️ 同上 |
| `paid_credit_balance_amt` | double | 日终付费信用余额（本地货币）⚠️ 同上 |
| `paid_credit_balance_amt_usd` | double | 日终付费信用余额（USD）⚠️ 同上 |
| `voucher_free_balance_amt` | double | 日终券免费信用余额（本地货币）⚠️ 同上 |
| `voucher_free_balance_amt_usd` | double | 日终券免费信用余额（USD）⚠️ 同上 |
| `package_free_balance_amt` | double | 日终套餐免费信用余额（本地货币）⚠️ 同上 |
| `package_free_balance_amt_usd` | double | 日终套餐免费信用余额（USD）⚠️ 同上 |
| `seller_mission_free_balance_amt` | double | 日终任务奖励免费信用余额（本地货币）⚠️ 同上 |
| `seller_mission_free_balance_amt_usd` | double | 日终任务奖励免费信用余额（USD）⚠️ 同上 |
| `manual_free_balance_amt` | double | 日终手动免费信用余额（本地货币）⚠️ 同上 |
| `manual_free_balance_amt_usd` | double | 日终手动免费信用余额（USD）⚠️ 同上 |
| `srm_free_balance_amt` | double | 日终SRM免费信用余额（本地货币）⚠️ 同上 |
| `srm_free_balance_amt_usd` | double | 日终SRM免费信用余额（USD）⚠️ 同上 |

---

## 查询使用须知

### 必须包含的过滤条件

查询本表时**必须同时过滤** `grass_date` 和 `grass_region`，否则将全量扫描所有地区和历史数据，造成性能严重下降或结果错误：

```sql
WHERE grass_date = '2026-04-21'
  AND grass_region = 'MY'   -- 按需替换为目标地区
```

- `grass_region` 为全大写国家/地区代码（如 `MY`、`TH`、`PH`、`SG`、`ID`、`VN`、`BR`、`MX`、`CO`、`CL`）；遗漏该过滤将导致多地区数据重复混合。
- `grass_date` 为分区键，遗漏将触发全表扫描。
- 本表所有数据均为**本地时区（`tz_type='local'`）**快照，无需再过滤 `tz_type`。

### 不可直接 SUM 的字段

以下类型字段在多行聚合时**不可直接 SUM**，需按正确方式计算：

| 字段类型 | 典型字段 | 正确聚合方式 |
|----------|----------|-------------|
| 比率/ROI 字段 | `ads_ctr`、`ads_cr`、`ads_ctr_cr`、`ads_direct_order_roi`、`ads_broad_order_roi`、`ads_take_rate`、`ads_imp_per`、`ads_direct_gmv_per`、`ads_direct_order_per`、`org_ctr`、`org_cr`、`hit_budget_campaign_per`、`budget_cost_ratio` | 用分子字段 SUM / 分母字段 SUM 重新计算 |
| 派生平均值 | `avg_campaign_items`（系列）、`avg_campaign_budget`、`avg_hit_budget_expense` | 用原始计数/金额字段重新推算 |
| 余额快照字段 | `total_balance_amt`（系列）、`free_credit_balance_amt`（系列）等 `_balance_amt` 字段 | 取特定日期单行值，不得跨日 SUM |
| TD（截至今日累计）字段 | `ads_revenue_usd_td`（系列）、`ads_gmv_usd_td`（系列）、`platform_gmv_usd_td` | 仅取目标日期最新一行，跨多天不得 SUM |
| 窗口快照字段 | `top_selling_item_id` | 为单一 ID 值，不可做聚合运算 |

### 时效性说明

- **`_td` 字段**（如 `ads_revenue_usd_td`、`platform_gmv_usd_td`）：为当月截至当日的**月度累计值**（month-to-date），每日刷新覆盖写入。若查询多日数据并聚合，应取 `MAX(grass_date)` 所对应的单日行，而非对多行直接 SUM。
- **`_7d` 字段**（如 `create_ads_cnt_7d`）：统计窗口为过去7天（不含当日），与当日字段口径不同，**不可与当日同名字段直接相加**。
- 数据延迟：本表为 T+1 调度，当日数据于次日凌晨写入，查询当日实时数据请使用对应上游 live 表。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_shop_info__reg_s0_live` | 提供卖家/店铺基础维度信息（分层、标签、状态等） |
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 广告信用充值明细（充值来源、金额、类型） |
| `mp_paidads.dwd_advertiser_deduction_di__reg_s0_live` | 广告信用扣费明细（按信用类型、渠道分类） |
| `mkplpaidads_data.dwd_advertiser_credit_di__reg_s0_live` | 广告主信用日终余额（付费信用部分） |
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 广告活动及广告位维度当日绩效明细（曝光/点击/GMV/花费） |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度快照（广告状态、商品、广告位信息） |
| `mp_paidads.dws_campaign_deduction_budget_1d__reg_s0_live` | 活动预算消耗日汇总（日预算/总预算/实际消耗） |
| `mp_paidads.dws_item_performance_1d__reg_s0_live` | 商品级别广告与自然流量绩效指标 |
| `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live` | 广告主按广告位的月累计（TD）绩效指标 |
| `mp_order.dws_item_gmv_1d__reg_s0_live` | 商品维度日GMV与订单量（平台大盘） |
| `mp_order.dws_item_gmv_nd__reg_s0_live` | 商品近N天订单量（用于判断活跃商品） |
| `mp_order.dws_item_gmv_td__reg_s0_live` | 商品维度月累计GMV（TD） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率表（本地货币转USD） |
| `mp_item.dim_item__reg_s0_live` | 店铺商品维度信息（用于统计总商品数、新建商品数等） |

---

## ETL 逻辑摘要

### 数据流

本表以 `seller_info`（店铺维度快照）为基础驱动表，通过 LEFT JOIN 方式依次关联：广告信用充值/扣费/过期/余额（来自信用明细流水表）、广告活动计数与预算分析（来自广告活动明细与预算消耗表）、广告位绩效指标（来自广告绩效宽表）、商品维度指标（来自商品GMV与商品维表）以及月累计TD指标（来自广告主placement性能TD表），最终写入目标宽表。所有上游数据均通过 `grass_region`、`grass_date`、`tz_type='local'` 三联过滤，保证数据口径对齐到各地区本地时区单日粒度。

### 关键 CTE 说明

| CTE 名称 | 说明 |
|----------|------|
| `seller_info` | 店铺维度主表，驱动全表 LEFT JOIN，提供卖家属性、分层、标签等维度字段 |
| `credit_df` | 信用明细公共缓存，供 `topup`、`expiry`、`balance_df` 三个 CTE 共用，避免重复扫描原始流水表 |
| `balance_df` | 日终信用余额，通过 UNION ALL 合并付费信用日终余额（来自 `dwd_advertiser_credit_di`）与未过期免费信用余额（来自 `credit_df`），按 `shop_id` 聚合 |
| `campaign_budget` | 活动预算管理指标，JOIN 预算消耗表与汇率表，计算各广告位类型下的日/总预算、触达预算活动数、预算消耗率等 |
| `ads_performance_td` | 从广告主月累计性能表拉取各广告位的 TD 消耗与 GMV，作为最终 INSERT 中 TD 字段的来源 |

### 注意事项

1. **充值/扣费/余额三套字段口径不同**：充值（`topup`）和扣费（`deduction`）为当日流量字段，可跨日 SUM；余额（`balance`）为日终快照字段，不同日期值不可累加，应取特定日期单行数据。
2. **TD 字段为月度累计，非日增量**：所有 `_td` 后缀字段（`ads_revenue_usd_td`、`platform_gmv_usd_td` 等）记录当月截至该日的累计值，若需统计某月区间总量，应取区间最后一日的 TD 值，而非 SUM 多日 TD 值。
3. **7d 字段时间窗口为过去7天（不含当日）**：`_7d` 后缀字段（如 `create_ads_cnt_7d`）与同名无后缀字段（当日值）统计口径不同，不可混用或相加；需同时对比趋势时，请明确区分两类字段含义。

---

*文档生成时间：2026-04-22*