<!-- ads-workspace-gdoc-sync: gdoc_id=1942rf-7orb-f-AYaiSQozYBL8a_qkJoUoy-rFWmf4KM gdoc_url=https://docs.google.com/document/d/1942rf-7orb-f-AYaiSQozYBL8a_qkJoUoy-rFWmf4KM/edit -->

# mp_paidads.ads_advertiser_seller_all_metrics_1m

**分层**：ADS 层
**主键**：`shop_id` + `grass_date` + `grass_region` + `tz_type`
**分区**：`grass_date`（月末日期）、`grass_region`（地区）
**更新频率**：月度（每月末更新，覆盖全月汇总数据）
**引用频次**：0（末端 ADS 层宽表，未被其他候选表引用）

---

## 业务描述

本表是付费广告域广告主（卖家）维度的**月度全量宽表**，以店铺（`shop_id`）为粒度，汇总每家卖家在一个自然月内的广告投放全貌指标，涵盖广告活动管理、广告单元状态、商品参与度、广告绩效表现、充值余额及平台大盘 GMV 等六大主题域，共约 598 个字段。

本表的核心使用场景包括：广告主经营健康度分析、各广告类型（Search / Discovery / Shop / Itemboost / Autoboost / ROI2.0 等）月度对比、卖家分层运营（结合 `seller_tier`、`advertiser_tier`、`cluster` 等维度过滤）、月度充值与消耗趋势追踪、预算触达率与 ROI 健康度监控，以及广告生态大盘 GMV 贡献度分析。

表名后缀 `__reg_s0_live` 表明该表通过 `${region}`、`${timezone}` 参数化调度覆盖所有地区，ETL 中出现的具体地区代码或时区仅为调度实例示例，**本表实际覆盖全量地区**。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_date` | date | 分区日期，取当月最后一天（月末快照），查询时须指定具体月末日期 |
| `grass_region` | string | 地区分区键（如 `MY`、`TH`、`PH` 等），查询时须指定具体地区 |

---

### 维度：主键与卖家基础属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，主键维度 |
| `seller_name` | string | 店铺名称 |
| `seller_type` | string | 卖家类型 |
| `seller_status` | string | 卖家状态 |
| `seller_tier` | string | 卖家分层等级 |
| `advertiser_status` | string | 广告主状态 |
| `advertiser_tier` | string | 广告主分层等级 |
| `cluster` | string | 卖家所属运营集群 |
| `principal_type` | string | 主体类型 |
| `is_principal` | tinyint | 是否为主体账号（1=是，0=否） |
| `is_cb_seller` | tinyint | 是否跨境卖家（1=是，0=否） |
| `is_official_shop` | tinyint | 是否官方店铺（1=是，0=否） |
| `is_preferred_shop` | tinyint | 是否优选店铺（1=是，0=否） |
| `is_managed_seller` | tinyint | 是否托管卖家（1=是，0=否） |
| `key_seller_90` | tinyint | 是否关键卖家（90分位口径）（1=是，0=否） |
| `key_seller_95` | tinyint | 是否关键卖家（95分位口径）（1=是，0=否） |
| `account_create_datetime` | string | 广告主账号创建时间 |
| `tz_type` | string | 时区类型，正常取值为 `local`（本地时区口径） |
| `ads_type` | string | 广告类型标记 |
| `seller_ads_placement_type` | string | 卖家广告投放位类型标记 |

---

### 维度：店铺分类与采用标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_level1_global_be_category` | string | 店铺一级全球后端类目 |
| `shop_level2_global_be_category` | string | 店铺二级全球后端类目 |
| `seller_adoption_tag_m1` | string | 卖家广告采用标签（M1，上月） |
| `seller_adoption_tag_m2` | string | 卖家广告采用标签（M2，前两月） |
| `seller_auto_adoption_tag_m1` | string | 卖家自动广告采用标签（M1） |
| `seller_auto_adoption_tag_m2` | string | 卖家自动广告采用标签（M2） |
| `seller_manual_adoption_tag_m1` | string | 卖家手动广告采用标签（M1） |
| `seller_manual_adoption_tag_m2` | string | 卖家手动广告采用标签（M2） |
| `seller_simple2_adoption_tag_m1` | string | 卖家简易2代广告采用标签（M1） |
| `seller_simple2_adoption_tag_m2` | string | 卖家简易2代广告采用标签（M2） |
| `seller_target2_adoption_tag_m1` | string | 卖家定向2代广告采用标签（M1） |
| `seller_target2_adoption_tag_m2` | string | 卖家定向2代广告采用标签（M2） |
| `top_selling_item_id` | bigint | 当月销量（订单数）最高的商品 ID |

---

### 指标：广告计划（Campaign）管理

| 字段 | 类型 | 说明 |
|------|------|------|
| `ongoing_campaign_cnt` | bigint | 当前投放中的广告计划数（全类型） |
| `ongoing_campaign_cnt_search_manual_only` | bigint | 仅搜索手动广告计划数（投放中） |
| `ongoing_campaign_cnt_search_simple_only` | bigint | 仅搜索简易广告计划数（投放中） |
| `ongoing_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简易混合计划数（投放中） |
| `ongoing_campaign_cnt_discovery_manual` | bigint | Discovery 手动广告计划数（投放中） |
| `ongoing_campaign_cnt_discovery_simple` | bigint | Discovery 简易广告计划数（投放中） |
| `ongoing_campaign_cnt_roi_two` | bigint | ROI 2.0 广告计划数（投放中） |
| `pause_campaign_cnt` | bigint | 已暂停广告计划数（全类型） |
| `pause_campaign_cnt_search_manual_only` | bigint | 搜索手动广告计划数（已暂停） |
| `pause_campaign_cnt_search_simple_only` | bigint | 搜索简易广告计划数（已暂停） |
| `pause_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简易混合计划数（已暂停） |
| `pause_campaign_cnt_discovery_manual` | bigint | Discovery 手动广告计划数（已暂停） |
| `pause_campaign_cnt_discovery_simple` | bigint | Discovery 简易广告计划数（已暂停） |
| `pause_campaign_cnt_roi_two` | bigint | ROI 2.0 广告计划数（已暂停） |
| `closed_campaign_cnt` | bigint | 已关闭广告计划数（全类型） |
| `closed_campaign_cnt_search_manual_only` | bigint | 搜索手动广告计划数（已关闭） |
| `closed_campaign_cnt_search_simple_only` | bigint | 搜索简易广告计划数（已关闭） |
| `closed_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简易混合计划数（已关闭） |
| `closed_campaign_cnt_discovery_manual` | bigint | Discovery 手动广告计划数（已关闭） |
| `closed_campaign_cnt_discovery_simple` | bigint | Discovery 简易广告计划数（已关闭） |
| `closed_campaign_cnt_roi_two` | bigint | ROI 2.0 广告计划数（已关闭） |
| `deleted_campaign_cnt` | bigint | 已删除广告计划数（全类型） |
| `deleted_campaign_cnt_search_manual_only` | bigint | 搜索手动广告计划数（已删除） |
| `deleted_campaign_cnt_search_simple_only` | bigint | 搜索简易广告计划数（已删除） |
| `deleted_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简易混合计划数（已删除） |
| `deleted_campaign_cnt_discovery_manual` | bigint | Discovery 手动广告计划数（已删除） |
| `deleted_campaign_cnt_discovery_simple` | bigint | Discovery 简易广告计划数（已删除） |
| `deleted_campaign_cnt_roi_two` | bigint | ROI 2.0 广告计划数（已删除） |
| `create_campaign_cnt` | bigint | 当月新建广告计划数（全类型） |
| `create_campaign_cnt_search_manual_only` | bigint | 搜索手动广告当月新建计划数 |
| `create_campaign_cnt_search_simple_only` | bigint | 搜索简易广告当月新建计划数 |
| `create_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简易混合当月新建计划数 |
| `create_campaign_cnt_discovery_manual` | bigint | Discovery 手动广告当月新建计划数 |
| `create_campaign_cnt_discovery_simple` | bigint | Discovery 简易广告当月新建计划数 |
| `create_campaign_cnt_roi_two` | bigint | ROI 2.0 广告当月新建计划数 |
| `end_campaign_cnt` | bigint | 当月到期结束广告计划数（全类型） |
| `end_campaign_cnt_search_manual_only` | bigint | 搜索手动广告当月到期计划数 |
| `end_campaign_cnt_search_simple_only` | bigint | 搜索简易广告当月到期计划数 |
| `end_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简易混合当月到期计划数 |
| `end_campaign_cnt_discovery_manual` | bigint | Discovery 手动广告当月到期计划数 |
| `end_campaign_cnt_discovery_simple` | bigint | Discovery 简易广告当月到期计划数 |
| `end_campaign_cnt_roi_two` | bigint | ROI 2.0 广告当月到期计划数 |
| `avg_campaign_items` | double | 广告计划平均商品数（全类型）⚠️ 不可直接 SUM，为均值派生字段，跨行汇总需用 SUM(ads_item)/SUM(campaign_cnt) 重算 |
| `avg_campaign_items_search_manual_only` | double | 搜索手动广告计划平均商品数 ⚠️ 同上 |
| `avg_campaign_items_search_simple_only` | double | 搜索简易广告计划平均商品数 ⚠️ 同上 |
| `avg_campaign_items_search_manual_simple` | double | 搜索手动+简易混合计划平均商品数 ⚠️ 同上 |
| `avg_campaign_items_discovery_manual` | double | Discovery 手动广告计划平均商品数 ⚠️ 同上 |
| `avg_campaign_items_discovery_simple` | double | Discovery 简易广告计划平均商品数 ⚠️ 同上 |
| `avg_campaign_items_roi_two` | double | ROI 2.0 广告计划平均商品数 ⚠️ 同上 |

---

### 指标：广告预算管理

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_quota_usd` | double | 广告计划日预算总额（USD，全类型） |
| `daily_quota_usd_search_manual_only` | double | 搜索手动广告计划日预算总额（USD） |
| `daily_quota_usd_search_simple_only` | double | 搜索简易广告计划日预算总额（USD） |
| `daily_quota_usd_search_manual_simple` | double | 搜索手动+简易混合计划日预算总额（USD） |
| `daily_quota_usd_discovery_manual` | double | Discovery 手动广告计划日预算总额（USD） |
| `daily_quota_usd_discovery_simple` | double | Discovery 简易广告计划日预算总额（USD） |
| `daily_quota_usd_roi_two` | double | ROI 2.0 广告计划日预算总额（USD） |
| `total_quota_usd` | double | 广告计划总预算总额（USD，全类型） |
| `total_quota_usd_search_manual_only` | double | 搜索手动广告计划总预算总额（USD） |
| `total_quota_usd_search_simple_only` | double | 搜索简易广告计划总预算总额（USD） |
| `total_quota_usd_search_manual_simple` | double | 搜索手动+简易混合计划总预算总额（USD） |
| `total_quota_usd_discovery_manual` | double | Discovery 手动广告计划总预算总额（USD） |
| `total_quota_usd_discovery_simple` | double | Discovery 简易广告计划总预算总额（USD） |
| `total_quota_usd_roi_two` | double | ROI 2.0 广告计划总预算总额（USD） |
| `avg_campaign_budget` | double | 广告计划平均预算（USD）⚠️ 不可直接 SUM，为均值派生字段 |
| `hit_budget_campaign_cnt` | bigint | 当月触达预算上限的广告计划数（全类型） |
| `hit_budget_campaign_cnt_search_manual_only` | bigint | 搜索手动广告触达预算上限计划数 |
| `hit_budget_campaign_cnt_search_simple_only` | bigint | 搜索简易广告触达预算上限计划数 |
| `hit_budget_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简易混合触达预算上限计划数 |
| `hit_budget_campaign_cnt_discovery_manual` | bigint | Discovery 手动广告触达预算上限计划数 |
| `hit_budget_campaign_cnt_discovery_simple` | bigint | Discovery 简易广告触达预算上限计划数 |
| `hit_budget_campaign_cnt_roi_two` | bigint | ROI 2.0 广告触达预算上限计划数 |
| `hit_budget_campaign_per` | double | 触达预算上限计划占比（触达数/总计划数）⚠️ 不可直接 SUM，为比率字段，汇总需用 SUM(hit_budget_campaign_cnt)/SUM(ongoing_campaign_cnt) 重算 |
| `budget_cost_ratio` | double | 预算消耗比（实际花费/预算额）⚠️ 不可直接 SUM，为比率字段 |
| `avg_hit_budget_expense` | double | 触达预算计划的平均花费（USD）⚠️ 不可直接 SUM，为均值派生字段 |
| `daily_budget_campaign_cnt` | bigint | 设置日预算的广告计划数（全类型） |
| `daily_budget_campaign_cnt_search_manual_only` | bigint | 搜索手动广告设置日预算的计划数 |
| `daily_budget_campaign_cnt_search_simple_only` | bigint | 搜索简易广告设置日预算的计划数 |
| `daily_budget_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简易混合设置日预算的计划数 |
| `daily_budget_campaign_cnt_discovery_manual` | bigint | Discovery 手动广告设置日预算的计划数 |
| `daily_budget_campaign_cnt_discovery_simple` | bigint | Discovery 简易广告设置日预算的计划数 |
| `daily_budget_campaign_cnt_roi_two` | bigint | ROI 2.0 广告设置日预算的计划数 |
| `total_budget_campaign_cnt` | bigint | 设置总预算的广告计划数（全类型） |
| `total_budget_campaign_cnt_search_manual_only` | bigint | 搜索手动广告设置总预算的计划数 |
| `total_budget_campaign_cnt_search_simple_only` | bigint | 搜索简易广告设置总预算的计划数 |
| `total_budget_campaign_cnt_search_manual_simple` | bigint | 搜索手动+简易混合设置总预算的计划数 |
| `total_budget_campaign_cnt_discovery_manual` | bigint | Discovery 手动广告设置总预算的计划数 |
| `total_budget_campaign_cnt_discovery_simple` | bigint | Discovery 简易广告设置总预算的计划数 |
| `total_budget_campaign_cnt_roi_two` | bigint | ROI 2.0 广告设置总预算的计划数 |
| `limited_budget_cnt` | bigint | 有限额预算的广告计划数（全类型） |
| `limited_budget_cnt_search_manual_only` | bigint | 搜索手动广告有限额预算计划数 |
| `limited_budget_cnt_search_simple_only` | bigint | 搜索简易广告有限额预算计划数 |
| `limited_budget_cnt_search_manual_simple` | bigint | 搜索手动+简易混合有限额预算计划数 |
| `limited_budget_cnt_discovery_manual` | bigint | Discovery 手动广告有限额预算计划数 |
| `limited_budget_cnt_discovery_simple` | bigint | Discovery 简易广告有限额预算计划数 |
| `limited_budget_cnt_roi_two` | bigint | ROI 2.0 广告有限额预算计划数 |
| `unlimited_budget_cnt` | bigint | 无限额预算的广告计划数（全类型） |
| `unlimited_budget_cnt_search_manual_only` | bigint | 搜索手动广告无限额预算计划数 |
| `unlimited_budget_cnt_search_simple_only` | bigint | 搜索简易广告无限额预算计划数 |
| `unlimited_budget_cnt_search_manual_simple` | bigint | 搜索手动+简易混合无限额预算计划数 |
| `unlimited_budget_cnt_discovery_manual` | bigint | Discovery 手动广告无限额预算计划数 |
| `unlimited_budget_cnt_discovery_simple` | bigint | Discovery 简易广告无限额预算计划数 |
| `unlimited_budget_cnt_roi_two` | bigint | ROI 2.0 广告无限额预算计划数 |

---

### 指标：广告单元（Ad）状态管理

| 字段 | 类型 | 说明 |
|------|------|------|
| `active_ads_cnt` | bigint | 活跃广告单元数（全类型，`is_ads_active=1` 或 `has_performance=1`） |
| `active_ads_cnt_search` | bigint | 搜索广告活跃单元数 |
| `active_ads_cnt_search_manual` | bigint | 搜索手动广告活跃单元数 |
| `active_ads_cnt_search_simple` | bigint | 搜索简易广告活跃单元数 |
| `active_ads_cnt_discovery` | bigint | Discovery 广告活跃单元数 |
| `active_ads_cnt_dd_manual` | bigint | Discovery 手动广告活跃单元数 |
| `active_ads_cnt_dd_simple` | bigint | Discovery 简易广告活跃单元数 |
| `active_ads_cnt_ymal_manual` | bigint | YMAL 手动广告活跃单元数 |
| `active_ads_cnt_ymal_simple` | bigint | YMAL 简易广告活跃单元数 |
| `active_ads_cnt_shop` | bigint | 店铺广告活跃单元数 |
| `active_ads_cnt_itemboost` | bigint | Itemboost 广告活跃单元数 |
| `active_ads_cnt_autoboost` | bigint | Autoboost 广告活跃单元数 |
| `active_ads_cnt_roi_two` | bigint | ROI 2.0 广告活跃单元数 |
| `ongoing_ads_cnt` | bigint | 投放中广告单元数（全类型，`ads_status=1`） |
| `ongoing_ads_cnt_search` | bigint | 搜索广告投放中单元数 |
| `ongoing_ads_cnt_search_manual` | bigint | 搜索手动广告投放中单元数 |
| `ongoing_ads_cnt_search_simple` | bigint | 搜索简易广告投放中单元数 |
| `ongoing_ads_cnt_discovery` | bigint | Discovery 广告投放中单元数 |
| `ongoing_ads_cnt_dd_manual` | bigint | Discovery 手动广告投放中单元数 |
| `ongoing_ads_cnt_dd_simple` | bigint | Discovery 简易广告投放中单元数 |
| `ongoing_ads_cnt_ymal_manual` | bigint | YMAL 手动广告投放中单元数 |
| `ongoing_ads_cnt_ymal_simple` | bigint | YMAL 简易广告投放中单元数 |
| `ongoing_ads_cnt_shop` | bigint | 店铺广告投放中单元数 |
| `ongoing_ads_cnt_itemboost` | bigint | Itemboost 广告投放中单元数 |
| `ongoing_ads_cnt_autoboost` | bigint | Autoboost 广告投放中单元数 |
| `ongoing_ads_cnt_roi_two` | bigint | ROI 2.0 广告投放中单元数 |
| `pause_ads_cnt` | bigint | 已暂停广告单元数（全类型） |
| `pause_ads_cnt_search` | bigint | 搜索广告已暂停单元数 |
| `pause_ads_cnt_search_manual` | bigint | 搜索手动广告已暂停单元数 |
| `pause_ads_cnt_search_simple` | bigint | 搜索简易广告已暂停单元数 |
| `pause_ads_cnt_discovery` | bigint | Discovery 广告已暂停单元数 |
| `pause_ads_cnt_dd_manual` | bigint | Discovery 手动广告已暂停单元数 |
| `pause_ads_cnt_dd_simple` | bigint | Discovery 简易广告已暂停单元数 |
| `pause_ads_cnt_ymal_manual` | bigint | YMAL 手动广告已暂停单元数 |
| `pause_ads_cnt_ymal_simple` | bigint | YMAL 简易广告已暂停单元数 |
| `pause_ads_cnt_shop` | bigint | 店铺广告已暂停单元数 |
| `pause_ads_cnt_itemboost` | bigint | Itemboost 广告已暂停单元数 |
| `pause_ads_cnt_autoboost` | bigint | Autoboost 广告已暂停单元数 |
| `pause_ads_cnt_roi_two` | bigint | ROI 2.0 广告已暂停单元数 |
| `closed_ads_cnt` | bigint | 已关闭广告单元数（全类型） |
| `closed_ads_cnt_search` | bigint | 搜索广告已关闭单元数 |
| `closed_ads_cnt_search_manual` | bigint | 搜索手动广告已关闭单元数 |
| `closed_ads_cnt_search_simple` | bigint | 搜索简易广告已关闭单元数 |
| `closed_ads_cnt_discovery` | bigint | Discovery 广告已关闭单元数 |
| `closed_ads_cnt_dd_manual` | bigint | Discovery 手动广告已关闭单元数 |
| `closed_ads_cnt_dd_simple` | bigint | Discovery 简易广告已关闭单元数 |
| `closed_ads_cnt_ymal_manual` | bigint | YMAL 手动广告已关闭单元数 |
| `closed_ads_cnt_ymal_simple` | bigint | YMAL 简易广告已关闭单元数 |
| `closed_ads_cnt_shop` | bigint | 店铺广告已关闭单元数 |
| `closed_ads_cnt_itemboost` | bigint | Itemboost 广告已关闭单元数 |
| `closed_ads_cnt_autoboost` | bigint | Autoboost 广告已关闭单元数 |
| `closed_ads_cnt_roi_two` | bigint | ROI 2.0 广告已关闭单元数 |
| `deleted_ads_cnt` | bigint | 已删除广告单元数（全类型） |
| `deleted_ads_cnt_search` | bigint | 搜索广告已删除单元数 |
| `deleted_ads_cnt_search_manual` | bigint | 搜索手动广告已删除单元数 |
| `deleted_ads_cnt_search_simple` | bigint | 搜索简易广告已删除单元数 |
| `deleted_ads_cnt_discovery` | bigint | Discovery 广告已删除单元数 |
| `deleted_ads_cnt_dd_manual` | bigint | Discovery 手动广告已删除单元数 |
| `deleted_ads_cnt_dd_simple` | bigint | Discovery 简易广告已删除单元数 |
| `deleted_ads_cnt_ymal_manual` | bigint | YMAL 手动广告已删除单元数 |
| `deleted_ads_cnt_ymal_simple` | bigint | YMAL 简易广告已删除单元数 |
| `deleted_ads_cnt_shop` | bigint | 店铺广告已删除单元数 |
| `deleted_ads_cnt_itemboost` | bigint | Itemboost 广告已删除单元数 |
| `deleted_ads_cnt_autoboost` | bigint | Autoboost 广告已删除单元数 |
| `deleted_ads_cnt_roi_two` | bigint | ROI 2.0 广告已删除单元数 |
| `create_ads_cnt` | bigint | 当月新建广告单元数（全类型） |
| `create_ads_cnt_search` | bigint | 搜索广告当月新建单元数 |
| `create_ads_cnt_search_manual` | bigint | 搜索手动广告当月新建单元数 |
| `create_ads_cnt_search_simple` | bigint | 搜索简易广告当月新建单元数 |
| `create_ads_cnt_discovery` | bigint | Discovery 广告当月新建单元数 |
| `create_ads_cnt_dd_manual` | bigint | Discovery 手动广告当月新建单元数 |
| `create_ads_cnt_dd_simple` | bigint | Discovery 简易广告当月新建单元数 |
| `create_ads_cnt_ymal_manual` | bigint | YMAL 手动广告当月新建单元数 |
| `create_ads_cnt_ymal_simple` | bigint | YMAL 简易广告当月新建单元数 |
| `create_ads_cnt_shop` | bigint | 店铺广告当月新建单元数 |
| `create_ads_cnt_itemboost` | bigint | Itemboost 广告当月新建单元数 |
| `create_ads_cnt_autoboost` | bigint | Autoboost 广告当月新建单元数 |
| `create_ads_cnt_roi_two` | bigint | ROI 2.0 广告当月新建单元数 |
| `end_ads_cnt` | bigint | 当月到期结束广告单元数（全类型） |
| `end_ads_cnt_search` | bigint | 搜索广告当月到期单元数 |
| `end_ads_cnt_search_manual` | bigint | 搜索手动广告当月到期单元数 |
| `end_ads_cnt_search_simple` | bigint | 搜索简易广告当月到期单元数 |
| `end_ads_cnt_discovery` | bigint | Discovery 广告当月到期单元数 |
| `end_ads_cnt_dd_manual` | bigint | Discovery 手动广告当月到期单元数 |
| `end_ads_cnt_dd_simple` | bigint | Discovery 简易广告当月到期单元数 |
| `end_ads_cnt_ymal_manual` | bigint | YMAL 手动广告当月到期单元数 |
| `end_ads_cnt_ymal_simple` | bigint | YMAL 简易广告当月到期单元数 |
| `end_ads_cnt_shop` | bigint | 店铺广告当月到期单元数 |
| `end_ads_cnt_itemboost` | bigint | Itemboost 广告当月到期单元数 |
| `end_ads_cnt_autoboost` | bigint | Autoboost 广告当月到期单元数 |
| `end_ads_cnt_roi_two` | bigint | ROI 2.0 广告当月到期单元数 |
| `have_expenditure_ads_cnt` | bigint | 当月有花费的广告单元数（全类型，`ads_expenditure_amt_usd > 0`） |
| `have_expenditure_ads_cnt_search` | bigint | 搜索广告当月有花费单元数 |
| `have_expenditure_ads_cnt_search_manual` | bigint | 搜索手动广告当月有花费单元数 |
| `have_expenditure_ads_cnt_search_simple` | bigint | 搜索简易广告当月有花费单元数 |
| `have_expenditure_ads_cnt_discovery` | bigint | Discovery 广告当月有花费单元数 |
| `have_expenditure_ads_cnt_dd_manual` | bigint | Discovery 手动广告当月有花费单元数 |
| `have_expenditure_ads_cnt_dd_simple` | bigint | Discovery 简易广告当月有花费单元数 |
| `have_expenditure_ads_cnt_ymal_manual` | bigint | YMAL 手动广告当月有花费单元数 |
| `have_expenditure_ads_cnt_ymal_simple` | bigint | YMAL 简易广告当月有花费单元数 |
| `have_expenditure_ads_cnt_shop` | bigint | 店铺广告当月有花费单元数 |
| `have_expenditure_ads_cnt_itemboost` | bigint | Itemboost 广告当月有花费单元数 |
| `have_expenditure_ads_cnt_autoboost` | bigint | Autoboost 广告当月有花费单元数 |
| `have_expenditure_ads_cnt_roi_two` | bigint | ROI 2.0 广告当月有花费单元数 |

---

### 指标：广告商品（Item）维度

| 字段 | 类型 | 说明 |
|------|------|------|
| `have_ads_items_cnt` | bigint | 当前有有效广告的商品数（全类型，`is_ads_active=1`） |
| `have_ads_items_cnt_search` | bigint | 搜索广告有效商品数 |
| `have_ads_items_cnt_search_manual` | bigint | 搜索手动广告有效商品数 |
| `have_ads_items_cnt_search_simple` | bigint | 搜索简易广告有效商品数 |
| `have_ads_items_cnt_discovery` | bigint | Discovery 广告有效商品数 |
| `have_ads_items_cnt_dd_manual` | bigint | Discovery 手动广告有效商品数 |
| `have_ads_items_cnt_dd_simple` | bigint | Discovery 简易广告有效商品数 |
| `have_ads_items_cnt_ymal_manual` | bigint | YMAL 手动广告有效商品数 |
| `have_ads_items_cnt_ymal_simple` | bigint | YMAL 简易广告有效商品数 |
| `have_ads_items_cnt_shop` | bigint | 店铺广告有效商品数 |
| `have_ads_items_cnt_itemboost` | bigint | Itemboost 广告有效商品数 |
| `have_ads_items_cnt_autoboost` | bigint | Autoboost 广告有效商品数 |
| `have_ads_items_cnt_roi_two` | bigint | ROI 2.0 广告有效商品数 |
| `newly_create_ads_items_cnt` | bigint | 当月新建广告的商品数（全类型） |
| `newly_create_ads_items_cnt_search` | bigint | 搜索广告当月新建商品数 |
| `newly_create_ads_items_cnt_search_manual` | bigint | 搜索手动广告当月新建商品数 |
| `newly_create_ads_items_cnt_search_simple` | bigint | 搜索简易广告当月新建商品数 |
| `newly_create_ads_items_cnt_discovery` | bigint | Discovery 广告当月新建商品数 |
| `newly_create_ads_items_cnt_dd_manual` | bigint | Discovery 手动广告当月新建商品数 |
| `newly_create_ads_items_cnt_dd_simple` | bigint | Discovery 简易广告当月新建商品数 |
| `newly_create_ads_items_cnt_ymal_manual` | bigint | YMAL 手动广告当月新建商品数 |
| `newly_create_ads_items_cnt_ymal_simple` | bigint | YMAL 简易广告当月新建商品数 |
| `newly_create_ads_items_cnt_shop` | bigint | 店铺广告当月新建商品数 |
| `newly_create_ads_items_cnt_itemboost` | bigint | Itemboost 广告当月新建商品数 |
| `newly_create_ads_items_cnt_autoboost` | bigint | Autoboost 广告当月新建商品数 |
| `newly_create_ads_items_cnt_roi_two` | bigint | ROI 2.0 广告当月新建商品数 |
| `ongoing_ads_items_cnt` | bigint | 投放中广告的商品数（全类型） |
| `ongoing_ads_items_cnt_search` | bigint | 搜索广告投放中商品数 |
| `ongoing_ads_items_cnt_search_manual` | bigint | 搜索手动广告投放中商品数 |
| `ongoing_ads_items_cnt_search_simple` | bigint | 搜索简易广告投放中商品数 |
| `ongoing_ads_items_cnt_discovery` | bigint | Discovery 广告投放中商品数 |
| `ongoing_ads_items_cnt_dd_manual` | bigint | Discovery 手动广告投放中商品数 |
| `ongoing_ads_items_cnt_dd_simple` | bigint | Discovery 简易广告投放中商品数 |
| `ongoing_ads_items_cnt_ymal_manual` | bigint | YMAL 手动广告投放中商品数 |
| `ongoing_ads_items_cnt_ymal_simple` | bigint | YMAL 简易广告投放中商品数 |
| `ongoing_ads_items_cnt_shop` | bigint | 店铺广告投放中商品数 |
| `ongoing_ads_items_cnt_itemboost` | bigint | Itemboost 广告投放中商品数 |
| `ongoing_ads_items_cnt_autoboost` | bigint | Autoboost 广告投放中商品数 |
| `ongoing_ads_items_cnt_roi_two` | bigint | ROI 2.0 广告投放中商品数 |
| `closed_ads_items_cnt` | bigint | 已关闭广告的商品数（全类型） |
| `closed_ads_items_cnt_search` | bigint | 搜索广告已关闭商品数 |
| `closed_ads_items_cnt_search_manual` | bigint | 搜索手动广告已关闭商品数 |
| `closed_ads_items_cnt_search_simple` | bigint | 搜索简易广告已关闭商品数 |
| `closed_ads_items_cnt_discovery` | bigint | Discovery 广告已关闭商品数 |
| `closed_ads_items_cnt_dd_manual` | bigint | Discovery 手动广告已关闭商品数 |
| `closed_ads_items_cnt_dd_simple` | bigint | Discovery 简易广告已关闭商品数 |
| `closed_ads_items_cnt_ymal_manual` | bigint | YMAL 手动广告已关闭商品数 |
| `closed_ads_items_cnt_ymal_simple` | bigint | YMAL 简易广告已关闭商品数 |
| `closed_ads_items_cnt_shop` | bigint | 店铺广告已关闭商品数 |
| `closed_ads_items_cnt_itemboost` | bigint | Itemboost 广告已关闭商品数 |
| `closed_ads_items_cnt_autoboost` | bigint | Autoboost 广告已关闭商品数 |
| `closed_ads_items_cnt_roi_two` | bigint | ROI 2.0 广告已关闭商品数 |
| `end_campaign_items_cnt` | bigint | 当月广告计划到期的商品数（全类型） |
| `end_campaign_items_cnt_search` | bigint | 搜索广告当月到期计划商品数 |
| `end_campaign_items_cnt_search_manual` | bigint | 搜索手动广告当月到期计划商品数 |
| `end_campaign_items_cnt_search_simple` | bigint | 搜索简易广告当月到期计划商品数 |
| `end_campaign_items_cnt_discovery` | bigint | Discovery 广告当月到期计划商品数 |
| `end_campaign_items_cnt_dd_manual` | bigint | Discovery 手动广告当月到期计划商品数 |
| `end_campaign_items_cnt_dd_simple` | bigint | Discovery 简易广告当月到期计划商品数 |
| `end_campaign_items_cnt_ymal_manual` | bigint | YMAL 手动广告当月到期计划商品数 |
| `end_campaign_items_cnt_ymal_simple` | bigint | YMAL 简易广告当月到期计划商品数 |
| `end_campaign_items_cnt_shop` | bigint | 店铺广告当月到期计划商品数 |
| `end_campaign_items_cnt_itemboost` | bigint | Itemboost 广告当月到期计划商品数 |
| `end_campaign_items_cnt_autoboost` | bigint | Autoboost 广告当月到期计划商品数 |
| `end_campaign_items_cnt_roi_two` | bigint | ROI 2.0 广告当月到期计划商品数 |
| `have_expenditure_items_cnt` | bigint | 当月有广告花费的商品数（全类型） |
| `have_expenditure_items_cnt_search` | bigint | 搜索广告当月有花费商品数 |
| `have_expenditure_items_cnt_search_manual` | bigint | 搜索手动广告当月有花费商品数 |
| `have_expenditure_items_cnt_search_simple` | bigint | 搜索简易广告当月有花费商品数 |
| `have_expenditure_items_cnt_discovery` | bigint | Discovery 广告当月有花费商品数 |
| `have_expenditure_items_cnt_dd_manual` | bigint | Discovery 手动广告当月有花费商品数 |
| `have_expenditure_items_cnt_dd_simple` | bigint | Discovery 简易广告当月有花费商品数 |
| `have_expenditure_items_cnt_ymal_manual` | bigint | YMAL 手动广告当月有花费商品数 |
| `have_expenditure_items_cnt_ymal_simple` | bigint | YMAL 简易广告当月有花费商品数 |
| `have_expenditure_items_cnt_shop` | bigint | 店铺广告当月有花费商品数 |
| `have_expenditure_items_cnt_itemboost` | bigint | Itemboost 广告当月有花费商品数 |
| `have_expenditure_items_cnt_autoboost` | bigint | Autoboost 广告当月有花费商品数 |
| `have_expenditure_items_cnt_roi_two` | bigint | ROI 2.0 广告当月有花费商品数 |
| `have_ads_order_items_cnt` | bigint | 当月有广告带单的商品数（全类型） |
| `have_ads_order_items_cnt_search` | bigint | 搜索广告当月有带单商品数 |
| `have_ads_order_items_cnt_search_manual` | bigint | 搜索手动广告当月有带单商品数 |
| `have_ads_order_items_cnt_search_simple` | bigint | 搜索简易广告当月有带单商品数 |
| `have_ads_order_items_cnt_discovery` | bigint | Discovery 广告当月有带单商品数 |
| `have_ads_order_items_cnt_dd_manual` | bigint | Discovery 手动广告当月有带单商品数 |
| `have_ads_order_items_cnt_dd_simple` | bigint | Discovery 简易广告当月有带单商品数 |
| `have_ads_order_items_cnt_ymal_manual` | bigint | YMAL 手动广告当月有带单商品数 |
| `have_ads_order_items_cnt_ymal_simple` | bigint | YMAL 简易广告当月有带单商品数 |
| `have_ads_order_items_cnt_shop` | bigint | 店铺广告当月有带单商品数 |
| `have_ads_order_items_cnt_itemboost` | bigint | Itemboost 广告当月有带单商品数 |
| `have_ads_order_items_cnt_autoboost` | bigint | Autoboost 广告当月有带单商品数 |
| `have_ads_order_items_cnt_roi_two` | bigint | ROI 2.0 广告当月有带单商品数 |
| `total_items_cnt` | bigint | 店铺商品总数（月末快照） |
| `newly_items_cnt` | bigint | 当月新增商品数 |
| `active_items_cnt` | bigint | 近30日有成交的活跃商品数 |
| `have_imp_items_cnt` | bigint | 当月有广告曝光的商品数 |
| `have_click_items_cnt` | bigint | 当月有广告点击的商品数 |
| `have_order_items_cnt` | bigint | 当月有广告直接订单的商品数 |
| `shop_item_imp_cnt` | bigint | 店铺商品自然曝光次数 |
| `shop_item_click_cnt` | bigint | 店铺商品自然点击次数 |

---

### 指标：广告绩效（全量月度汇总）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_imp_cnt` | bigint | 广告总曝光次数（全类型，当月累计） |
| `ads_imp_cnt_search` | bigint | 搜索广告曝光次数 |
| `ads_imp_cnt_search_manual` | bigint | 搜索手动广告曝光次数 |
| `ads_imp_cnt_search_simple` | bigint | 搜索简易广告曝光次数 |
| `ads_imp_cnt_discovery` | bigint | Discovery 广告曝光次数 |
| `ads_imp_cnt_dd_manual` | bigint | Discovery 手动广告曝光次数 |
| `ads_imp_cnt_dd_simple` | bigint | Discovery 简易广告曝光次数 |
| `ads_imp_cnt_ymal_manual` | bigint | YMAL 手动广告曝光次数 |
| `ads_imp_cnt_ymal_simple` | bigint | YMAL 简易广告曝光次数 |
| `ads_imp_cnt_shop` | bigint | 店铺广告曝光次数 |
| `ads_imp_cnt_itemboost` | bigint | Itemboost 广告曝光次数 |
| `ads_imp_cnt_autoboost` | bigint | Autoboost 广告曝光次数 |
| `ads_imp_cnt_roi_two` | bigint | ROI 2.0 广告曝光次数 |
| `ads_click_cnt` | bigint | 广告总点击次数（全类型） |
| `ads_click_cnt_search` | bigint | 搜索广告点击次数 |
| `ads_click_cnt_search_manual` | bigint | 搜索手动广告点击次数 |
| `ads_click_cnt_search_simple` | bigint | 搜索简易广告点击次数 |
| `ads_click_cnt_discovery` | bigint | Discovery 广告点击次数 |
| `ads_click_cnt_dd_manual` | bigint | Discovery 手动广告点击次数 |
| `ads_click_cnt_dd_simple` | bigint | Discovery 简易广告点击次数 |
| `ads_click_cnt_ymal_manual` | bigint | YMAL 手动广告点击次数 |
| `ads_click_cnt_ymal_simple` | bigint | YMAL 简易广告点击次数 |
| `ads_click_cnt_shop` | bigint | 店铺广告点击次数 |
| `ads_click_cnt_itemboost` | bigint | Itemboost 广告点击次数 |
| `ads_click_cnt_autoboost` | bigint | Autoboost 广告点击次数 |
| `ads_click_cnt_roi_two` | bigint | ROI 2.0 广告点击次数 |
| `ads_direct_order_cnt` | bigint | 广告直接带单订单数（全类型） |
| `ads_direct_order_cnt_search` | bigint | 搜索广告直接带单订单数 |
| `ads_direct_order_cnt_search_manual` | bigint | 搜索手动广告直接带单订单数 |
| `ads_direct_order_cnt_search_simple` | bigint | 搜索简易广告直接带单订单数 |
| `ads_direct_order_cnt_discovery` | bigint | Discovery 广告直接带单订单数 |
| `ads_direct_order_cnt_dd_manual` | bigint | Discovery 手动广告直接带单订单数 |
| `ads_direct_order_cnt_dd_simple` | bigint | Discovery 简易广告直接带单订单数 |
| `ads_direct_order_cnt_ymal_manual` | bigint | YMAL 手动广告直接带单订单数 |
| `ads_direct_order_cnt_ymal_simple` | bigint | YMAL 简易广告直接带单订单数 |
| `ads_direct_order_cnt_shop` | bigint | 店铺广告直接带单订单数 |
| `ads_direct_order_cnt_itemboost` | bigint | Itemboost 广告直接带单订单数 |
| `ads_direct_order_cnt_autoboost` | bigint | Autoboost 广告直接带单订单数 |
| `ads_direct_order_cnt_roi_two` | bigint | ROI 2.0 广告直接带单订单数 |
| `ads_broad_order_cnt` | bigint | 广告宽口径带单订单数（全类型） |
| `ads_broad_order_cnt_search` | bigint | 搜索广告宽口径带单订单数 |
| `ads_broad_order_cnt_search_manual` | bigint | 搜索手动广告宽口径带单订单数 |
| `ads_broad_order_cnt_search_simple` | bigint | 搜索简易广告宽口径带单订单数 |
| `ads_broad_order_cnt_discovery` | bigint | Discovery 广告宽口径带单订单数 |
| `ads_broad_order_cnt_dd_manual` | bigint | Discovery 手动广告宽口径带单订单数 |
| `ads_broad_order_cnt_dd_simple` | bigint | Discovery 简易广告宽口径带单订单数 |
| `ads_broad_order_cnt_ymal_manual` | bigint | YMAL 手动广告宽口径带单订单数 |
| `ads_broad_order_cnt_ymal_simple` | bigint | YMAL 简易广告宽口径带单订单数 |
| `ads_broad_order_cnt_shop` | bigint | 店铺广告宽口径带单订单数 |
| `ads_broad_order_cnt_itemboost` | bigint | Itemboost 广告宽口径带单订单数 |
| `ads_broad_order_cnt_autoboost` | bigint | Autoboost 广告宽口径带单订单数 |
| `ads_broad_order_cnt_roi_two` | bigint | ROI 2.0 广告宽口径带单订单数 |
| `ads_platform_order_cnt` | bigint | 平台总订单数（广告归因口径，用于计算广告订单贡献） |
| `ads_direct_gmv_usd` | double | 广告直接带来的 GMV（USD，全类型） |
| `ads_direct_gmv_usd_search` | double | 搜索广告直接 GMV（USD） |
| `ads_direct_gmv_usd_search_manual` | double | 搜索手动广告直接 GMV（USD） |
| `ads_direct_gmv_usd_search_simple` | double | 搜索简易广告直接 GMV（USD） |
| `ads_direct_gmv_usd_discovery` | double | Discovery 广告直接 GMV（USD） |
| `ads_direct_gmv_usd_dd_manual` | double | Discovery 手动广告直接 GMV（USD） |
| `ads_direct_gmv_usd_dd_simple` | double | Discovery 简易广告直接 GMV（USD） |
| `ads_direct_gmv_usd_ymal_manual` | double | YMAL 手动广告直接 GMV（USD） |
| `ads_direct_gmv_usd_ymal_simple` | double | YMAL 简易广告直接 GMV（USD） |
| `ads_direct_gmv_usd_shop` | double | 店铺广告直接 GMV（USD） |
| `ads_direct_gmv_usd_itemboost` | double | Itemboost 广告直接 GMV（USD） |
| `ads_direct_gmv_usd_autoboost` | double | Autoboost 广告直接 GMV（USD） |
| `ads_direct_gmv_usd_roi_two` | double | ROI 2.0 广告直接 GMV（USD） |
| `ads_broad_gmv_usd` | double | 广告宽口径 GMV（USD，全类型） |
| `ads_broad_gmv_usd_search` | double | 搜索广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_search_manual` | double | 搜索手动广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_search_simple` | double | 搜索简易广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_discovery` | double | Discovery 广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_dd_manual` | double | Discovery 手动广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_dd_simple` | double | Discovery 简易广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_ymal_manual` | double | YMAL 手动广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_ymal_simple` | double | YMAL 简易广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_shop` | double | 店铺广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_itemboost` | double | Itemboost 广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_autoboost` | double | Autoboost 广告宽口径 GMV（USD） |
| `ads_broad_gmv_usd_roi_two` | double | ROI 2.0 广告宽口径 GMV（USD） |
| `ads_revenue_usd` | double | 广告花费（收入）总额（USD，全类型，当月日度累计） |
| `ads_revenue_usd_search` | double | 搜索广告花费（USD） |
| `ads_revenue_usd_search_manual` | double | 搜索手动广告花费（USD） |
| `ads_revenue_usd_search_simple` | double | 搜索简易广告花费（USD） |
| `ads_revenue_usd_discovery` | double | Discovery 广告花费（USD） |
| `ads_revenue_usd_dd_manual` | double | Discovery 手动广告花费（USD） |
| `ads_revenue_usd_dd_simple` | double | Discovery 简易广告花费（USD） |
| `ads_revenue_usd_ymal_manual` | double | YMAL 手动广告花费（USD） |
| `ads_revenue_usd_ymal_simple` | double | YMAL 简易广告花费（USD） |
| `ads_revenue_usd_shop` | double | 店铺广告花费（USD） |
| `ads_revenue_usd_itemboost` | double | Itemboost 广告花费（USD） |
| `ads_revenue_usd_autoboost` | double | Autoboost 广告花费（USD） |
| `ads_revenue_usd_roi_two` | double | ROI 2.0 广告花费（USD） |
| `ads_item_imp_cnt` | bigint | 商品级广告曝光次数 |
| `ads_item_click_cnt` | bigint | 商品级广告点击次数 |
| `ads_item_order_cnt` | bigint | 商品级广告带单订单数 |
| `ads_item_gmv_usd` | double | 商品级广告 GMV（USD） |
| `ads_imp_per` | double | 广告曝光占比（ads_imp/总曝光）⚠️ 不可直接 SUM，为比率字段 |
| `ads_direct_gmv_per` | double | 广告直接 GMV 占平台 GMV 比例 ⚠️ 不可直接 SUM，为比率字段 |
| `ads_direct_order_per` | double | 广告直接订单占平台订单比例 ⚠️ 不可直接 SUM，为比率字段 |
| `ads_ctr` | double | 广告点击率（click/imp）⚠️ 不可直接 SUM，为比率派生字段，汇总需用 SUM(click)/SUM(imp) 重算 |
| `ads_cr` | double | 广告转化率（direct_order/click）⚠️ 不可直接 SUM，为比率派生字段 |
| `ads_ctr_cr` | double | 广告曝光转化率（direct_order/imp）⚠️ 不可直接 SUM，为比率派生字段 |
| `ads_order_contribution` | double | 广告订单贡献率（ads_direct_order/platform_order）⚠️ 不可直接 SUM，为比率派生字段 |
| `ads_direct_order_roi` | double | 广告直接 ROI（direct_gmv/revenue）⚠️ 不可直接 SUM，为比率派生字段 |
| `ads_broad_order_roi` | double | 广告宽口径 ROI（broad_gmv/revenue）⚠️ 不可直接 SUM，为比率派生字段 |
| `ads_take_rate` | double | 广告变现率（revenue/platform_gmv）⚠️ 不可直接 SUM，为比率派生字段 |
| `ads_item_ctr` | double | 商品级广告点击率 ⚠️ 不可直接 SUM，为比率派生字段 |
| `ads_item_cr` | double | 商品级广告转化率 ⚠️ 不可直接 SUM，为比率派生字段 |
| `ads_item_ctr_cr` | double | 商品级广告曝光转化率 ⚠️ 不可直接 SUM，为比率派生字段 |

---

### 指标：广告绩效（月累计 TD 口径）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_revenue_usd_td` | double | 广告花费月累计（USD，全类型，来自 TD 宽表）⚠️ 该字段为截至月末的累计存储值，与 `ads_revenue_usd` 口径来源不同，请勿混用或重复叠加 |
| `ads_revenue_usd_td_search` | double | 搜索广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_search_manual` | double | 搜索手动广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_search_simple` | double | 搜索简易广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_discovery` | double | Discovery 广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_dd_manual` | double | Discovery 手动广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_dd_simple` | double | Discovery 简易广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_ymal_manual` | double | YMAL 手动广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_ymal_simple` | double | YMAL 简易广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_shop` | double | 店铺广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_itemboost` | double | Itemboost 广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_autoboost` | double | Autoboost 广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_revenue_usd_td_roi_two` | double | ROI 2.0 广告月累计花费（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td` | double | 广告 GMV 月累计（USD，全类型，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_search` | double | 搜索广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_search_manual` | double | 搜索手动广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_search_simple` | double | 搜索简易广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_discovery` | double | Discovery 广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_dd_manual` | double | Discovery 手动广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_dd_simple` | double | Discovery 简易广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_ymal_manual` | double | YMAL 手动广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_ymal_simple` | double | YMAL 简易广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_shop` | double | 店铺广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_itemboost` | double | Itemboost 广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_autoboost` | double | Autoboost 广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |
| `ads_gmv_usd_td_roi_two` | double | ROI 2.0 广告 GMV 月累计（USD，TD 口径）⚠️ 同上 |

---

### 指标：自然流量绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `org_imp_cnt` | bigint | 自然流量曝光次数（当月累计） |
| `org_click_cnt` | bigint | 自然流量点击次数 |
| `org_direct_order_cnt` | bigint | 自然流量直接带单订单数 |
| `org_broad_order_cnt` | bigint | 自然流量宽口径带单订单数 |
| `org_direct_gmv_usd` | double | 自然流量直接 GMV（USD） |
| `org_broad_gmv_usd` | double | 自然流量宽口径 GMV（USD） |
| `org_platform_order_cnt` | bigint | 平台总订单数（自然流量口径） |
| `org_ctr` | double | 自然流量点击率 ⚠️ 不可直接 SUM，为比率派生字段 |
| `org_cr` | double | 自然流量转化率 ⚠️ 不可直接 SUM，为比率派生字段 |
| `org_ctr_cr` | double | 自然流量曝光转化率 ⚠️ 不可直接 SUM，为比率派生字段 |
| `org_order_contribution` | double | 自然流量订单贡献率 ⚠️ 不可直接 SUM，为比率派生字段 |

---

### 指标：平台大盘 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_gmv_usd` | double | 平台 GMV 月度累计（USD，来自日度汇总） |
| `platform_gmv_usd_td` | double | 平台 GMV 月累计（USD，TD 口径，来自 `dws_item_gmv_td`）⚠️ 与 `platform_gmv_usd` 来源不同，TD 口径取月末当天截止累计值，请勿重复叠加 |

---

### 指标：充值（Topup）

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_topup_amt` | double | 当月充值总额（本地货币） |
| `total_topup_amt_usd` | double | 当月充值总额（USD） |
| `seller_topup_amt` | double | 卖家充值总额（本地货币，order_type in 2,4,6） |
| `seller_topup_amt_usd` | double | 卖家充值总额（USD） |
| `seller_one_time_topup_amt` | double | 卖家一次性充值额（本地货币，order_type in 2,6） |
| `seller_one_time_topup_amt_usd` | double | 卖家一次性充值额（USD） |
| `seller_auto_topup_amt` | double | 卖家自动充值额（本地货币，order_type=4） |
| `seller_auto_topup_amt_usd` | double | 卖家自动充值额（USD） |
| `admin_topup_amt` | double | 管理员充值总额（本地货币，order_type in 3,8,9,10） |
| `admin_topup_amt_usd` | double | 管理员充值总额（USD） |
| `admin_manual_topup_amt` | double | 管理员手动充值额（本地货币，order_type in 3,10） |
| `admin_manual_topup_amt_usd` | double | 管理员手动充值额（USD） |
| `admin_api_topup_amt` | double | 管理员 API 充值额（本地货币，order_type in 8,9） |
| `admin_api_topup_amt_usd` | double | 管理员 API 充值额（USD） |
| `free_credit_topup_amt` | double | 免费积分充值总额（本地货币，credit_topup_type in 3,4） |
| `free_credit_topup_amt_usd` | double | 免费积分充值总额（USD） |
| `paid_credit_topup_amt` | double | 付费积分充值总额（本地货币，credit_topup_type in 1,2） |
| `paid_credit_topup_amt_usd` | double | 付费积分充值总额（USD） |
| `voucher_topup_amt` | double | 优惠券充值总额（本地货币） |
| `voucher_topup_amt_usd` | double | 优惠券充值总额（USD） |
| `package_topup_amt` | double | 套餐充值总额（本地货币） |
| `package_topup_amt_usd` | double | 套餐充值总额（USD） |
| `seller_free_credit_topup_amt` | double | 卖家免费积分充值额（本地货币） |
| `seller_free_credit_topup_amt_usd` | double | 卖家免费积分充值额（USD） |
| `seller_paid_credit_topup_amt` | double | 卖家付费积分充值额（本地货币） |
| `seller_paid_credit_topup_amt_usd` | double | 卖家付费积分充值额（USD） |
| `seller_auto_paid_credit_topup_amt` | double | 卖家自动付费积分充值额（本地货币） |
| `seller_auto_fpaid_credit_topup_amt_usd` | double | 卖家自动付费积分充值额（USD）⚠️ 字段名含 `fpaid` 为历史命名，实际含义为自动付费积分充值额 USD |
| `seller_one_time_free_credit_topup_amt` | double | 卖家一次性免费积分充值额（本地货币） |
| `seller_one_time_free_credit_topup_amt_usd` | double | 卖家一次性免费积分充值额（USD） |
| `seller_one_time_paid_credit_topup_amt` | double | 卖家一次性付费积分充值额（本地货币） |
| `seller_one_time_paid_credit_topup_amt_usd` | double | 卖家一次性付费积分充值额（USD） |
| `admin_free_credit_topup_amt` | double | 管理员免费积分充值额（本地货币） |
| `admin_free_credit_topup_amt_usd` | double | 管理员免费积分充值额（USD） |
| `admin_paid_credit_topup_amt` | double | 管理员付费积分充值额（本地货币） |
| `admin_paid_credit_topup_amt_usd` | double | 管理员付费积分充值额（USD） |
| `admin_manual_free_credit_topup_amt` | double | 管理员手动免费积分充值额（本地货币） |
| `admin_manual_free_credit_topup_amt_usd` | double | 管理员手动免费积分充值额（USD） |
| `admin_manual_paid_credit_topup_amt` | double | 管理员手动付费积分充值额（本地货币） |
| `admin_manual_paid_credit_topup_amt_usd` | double | 管理员手动付费积分充值额（USD） |
| `admin_manual_adjust_topup_amt` | double | 管理员手动调整充值额（本地货币） |
| `admin_manual_topup_cb_amt_usd` | double | 管理员手动充值回调金额（USD） |
| `admin_manual_cb_topup_amt` | double | 管理员手动充值回调总额（本地货币） |
| `admin_api_free_credit_topup_amt` | double | 管理员 API 免费积分充值额（本地货币） |
| `admin_api_free_credit_topup_amt_usd` | double | 管理员 API 免费积分充值额（USD） |
| `admin_api_qss_free_credit_topup_amt` | double | 管理员 API QSS 免费积分充值额（本地货币） |
| `admin_api_qss_free_credit_topup_amt_usd` | double | 管理员 API QSS 免费积分充值额（USD） |
| `admin_api_qss_topup_amt` | double | 管理员 API QSS 充值总额（本地货币） |
| `admin_api_qss_topup_amt_usd` | double | 管理员 API QSS 充值总额（USD） |
| `admin_api_seller_mission_free_credit_topup_amt` | double | 管理员 API 卖家任务免费积分充值额（本地货币） |
| `admin_api_seller_mission_free_credit_topup_amt_usd` | double | 管理员 API 卖家任务免费积分充值额（USD） |
| `admin_api_seller_mission_topup_amt` | double | 管理员 API 卖家任务充值总额（本地货币） |
| `admin_api_seller_mission_topup_amt_usd` | double | 管理员 API 卖家任务充值总额（USD） |
| `voucher_free_credit_topup_amt` | double | 优惠券免费积分充值额（本地货币） |
| `voucher_free_credit_topup_amt_usd` | double | 优惠券免费积分充值额（USD） |
| `voucher_paid_credit_topup_amt` | double | 优惠券付费积分充值额（本地货币） |
| `voucher_paid_credit_topup_amt_usd` | double | 优惠券付费积分充值额（USD） |
| `package_free_credit_topup_amt` | double | 套餐免费积分充值额（本地货币） |
| `package_free_credit_topup_amt_usd` | double | 套餐免费积分充值额（USD） |
| `package_paid_credit_topup_amt` | double | 套餐付费积分充值额（本地货币） |
| `package_paid_credit_topup_amt_usd` | double | 套餐付费积分充值额（USD） |
| `seller_mission_free_credit_topup_amt`（注：表中字段名为`admin_api_seller_mission_free_credit_topup_amt`的分拆，原始DDL中此处实际对应`seller_free_credit_topup_amt`系列）<br>*以上充值字段均为当月范围内创建的充值记录汇总* | — | — |

> 注：`admin_manual_adjust_topup_amt` 无 USD 对应字段，查询时注意换算需手动关联汇率。

---

### 指标：扣款（Deduction）

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_deduction_amt` | double | 当月广告扣款总额（本地货币） |
| `total_deduction_amt_usd` | double | 当月广告扣款总额（USD） |
| `free_credit_deduction_amt` | double | 免费积分扣款额（本地货币） |
| `free_credit_deduction_amt_usd` | double | 免费积分扣款额（USD） |
| `paid_credit_deduction_amt` | double | 付费积分扣款额（本地货币） |
| `paid_credit_deduction_amt_usd` | double | 付费积分扣款额（USD） |
| `voucher_free_credit_deduction_amt` | double | 优惠券免费积分扣款额（本地货币） |
| `voucher_free_credit_deduction_amt_usd` | double | 优惠券免费积分扣款额（USD） |
| `package_free_credit_deduction_amt` | double | 套餐免费积分扣款额（本地货币） |
| `package_free_credit_deduction_amt_usd` | double | 套餐免费积分扣款额（USD） |
| `seller_mission_free_credit_deduction_amt` | double | 卖家任务免费积分扣款额（本地货币，order_type=8） |
| `seller_mission_free_credit_deduction_amt_usd` | double | 卖家任务免费积分扣款额（USD） |
| `manual_free_credit_deduction_amt` | double | 手动免费积分扣款额（本地货币，order_type=3） |
| `manual_free_credit_deduction_amt_usd` | double | 手动免费积分扣款额（USD） |
| `srm_free_credit_deduction_amt` | double | SRM 免费积分扣款额（本地货币，order_type=9） |
| `srm_free_credit_deduction_amt_usd` | double | SRM 免费积分扣款额（USD） |

---

### 指标：过期（Expiry）

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_credit_expiry_amt` | double | 当月到期失效积分总额（本地货币） |
| `total_credit_expiry_amt_usd` | double | 当月到期失效积分总额（USD） |
| `free_credit_expiry_amt` | double | 免费积分当月过期额（本地货币） |
| `free_credit_expiry_amt_usd` | double | 免费积分当月过期额（USD） |
| `paid_credit_expiry_amt` | double | 付费积分当月过期额（本地货币） |
| `paid_credit_expiry_amt_usd` | double | 付费积分当月过期额（USD） |
| `voucher_free_credit_expiry_amt` | double | 优惠券免费积分当月过期额（本地货币） |
| `voucher_free_credit_expiry_amt_usd` | double | 优惠券免费积分当月过期额（USD） |
| `package_free_credit_expiry_amt` | double | 套餐免费积分当月过期额（本地货币） |
| `package_free_credit_expiry_amt_usd` | double | 套餐免费积分当月过期额（USD） |
| `seller_mission_free_credit_expiry_amt` | double | 卖家任务免费积分当月过期额（本地货币） |
| `seller_mission_free_credit_expiry_amt_usd` | double | 卖家任务免费积分当月过期额（USD） |
| `manual_free_credit_expiry_amt` | double | 手动免费积分当月过期额（本地货币） |
| `manual_free_credit_expiry_amt_usd` | double | 手动免费积分当月过期额（USD） |
| `srm_free_credit_expiry_amt` | double | SRM 免费积分当月过期额（本地货币） |
| `srm_free_credit_expiry_amt_usd` | double | SRM 免费积分当月过期额（USD） |

---

### 指标：余额（Balance，月末快照）

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_balance_amt` | double | 月末账户总余额（本地货币）⚠️ 为月末时点快照，跨行 SUM 无业务意义 |
| `total_balance_amt_usd` | double | 月末账户总余额（USD）⚠️ 同上 |
| `free_credit_balance_amt` | double | 月末免费积分余额（本地货币）⚠️ 同上 |
| `free_credit_balance_amt_usd` | double | 月末免费积分余额（USD）⚠️ 同上 |
| `paid_credit_balance_amt` | double | 月末付费积分余额（本地货币）⚠️ 同上 |
| `paid_credit_balance_amt_usd` | double | 月末付费积分余额（USD）⚠️ 同上 |
| `voucher_free_balance_amt` | double | 月末优惠券免费积分余额（本地货币）⚠️ 同上 |
| `voucher_free_balance_amt_usd` | double | 月末优惠券免费积分余额（USD）⚠️ 同上 |
| `package_free_balance_amt` | double | 月末套餐免费积分余额（本地货币）⚠️ 同上 |
| `package_free_balance_amt_usd` | double | 月末套餐免费积分余额（USD）⚠️ 同上 |
| `seller_mission_free_balance_amt` | double | 月末卖家任务免费积分余额（本地货币）⚠️ 同上 |
| `seller_mission_free_balance_amt_usd` | double | 月末卖家任务免费积分余额（USD）⚠️ 同上 |
| `manual_free_balance_amt` | double | 月末手动免费积分余额（本地货币）⚠️ 同上 |
| `manual_free_balance_amt_usd` | double | 月末手动免费积分余额（USD）⚠️ 同上 |
| `srm_free_balance_amt` | double | 月末 SRM 免费积分余额（本地货币）⚠️ 同上 |
| `srm_free_balance_amt_usd` | double | 月末 SRM 免费积分余额（USD）⚠️ 同上 |
| `daily_quota_usd`（已列于预算管理节） | — | — |

---

## 查询使用须知

### 必须包含的过滤条件

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `grass_date` | `WHERE grass_date = '2024-11-30'`（指定月末日期） | 将扫描所有历史分区，严重增加计算成本且返回多月数据 |
| `grass_region` | `WHERE grass_region = 'MY'` | 将跨地区混合数据，指标因货币/时区不同无法对比 |
| `tz_type` | `WHERE tz_type = 'local'` | 表内可能包含多时区口径数据，不过滤将导致数据重复计算 |

### 不可直接 SUM 的字段

以下字段为**比率、均值或时点快照类型**，在跨行聚合时不可直接 `SUM`：

| 字段类型 | 代表字段 | 正确计算方式 |
|----------|----------|-------------|
| 点击率/转化率 | `ads_ctr`、`ads_cr`、`ads_ctr_cr`、`org_ctr`、`org_cr`、`org_ctr_cr`、`ads_item_ctr`、`ads_item_cr`、`ads_item_ctr_cr` | 分别对分子分母字段 SUM 后相除，如 `SUM(ads_click_cnt)/SUM(ads_imp_cnt)` |
| ROI / 贡献率 | `ads_direct_order_roi`、`ads_broad_order_roi`、`ads_take_rate`、`ads_order_contribution`、`org_order_contribution` | 同上，用原始分子分母字段重算 |
| 占比类 | `ads_imp_per`、`ads_direct_gmv_per`、`ads_direct_order_per`、`hit_budget_campaign_per`、`budget_cost_ratio` | 用原始计数/金额字段相除 |
| 均值类 | `avg_campaign_items`、`avg_campaign_items_*`、`avg_campaign_budget`、`avg_hit_budget_expense` | 用对应分子分母字段 SUM 后相除 |
| 余额快照 | `total_balance_amt`、`free_credit_balance_amt`、`paid_credit_balance_amt` 等所有 `_balance_amt` 字段 | 为月末时点存量，跨行 SUM 无业务意义，按 shop_id 单独取值 |

### 时效性说明

- **`_td` 后缀字段**（如 `ads_revenue_usd_td`、`ads_gmv_usd_td`、`platform_gmv_usd_td`）：来源为专属 To-Date 累计宽表（`dws_advertiser_placement_performance_td`、`dws_item_gmv_td`），取月末当天的截止累计值。在月中查询时，这些字段反映截至 `grass_date` 的累计口径，而非完整月度数据；仅当 `grass_date = 月末最后一天` 时才等价于完整月度数据。
- **余额字段**：为 `grass_date`（月末）时点快照，不反映月内动态变化。
- **本表为月度更新**：每月末数据写入后才可用，查询时请确保指定月份已完成调度。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_shop_info_monthly__reg_s0_live` | 卖家/店铺维度信息月末快照（seller_info） |
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 广告主积分充值流水（topup、expiry、balance 计算基础） |
| `mp_paidads.dwd_advertiser_deduction_di__reg_s0_live` | 广告主积分扣款日明细（deduction_di） |
| `mkplpaidads_data.dwd_advertiser_credit_di__reg_s0_live` | 广告主积分余额日快照（balance_df 第一部分） |
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 广告投放每日宽表（campaign/budget/ads_cnt 计算基础） |
| `mp_paidads.dws_campaign_deduction_budget_1d__reg_s0_live` | 广告计划每日预算扣款数据（campaign_budget） |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告单元维度日快照（ads_cnt、ads_item_cnt 计算基础） |
| `mp_paidads.ads_advertiser_seller_all_metrics_1d__reg_s0_live` | 广告主卖家每日全量指标表（month_performance/all_performance 聚合基础） |
| `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live` | 广告主按投放位 TD 累计绩效宽表（ads_performance_td） |
| `mp_item.dim_item__reg_s0_live` | 商品维度月末快照（seller_item_cnt） |
| `mp_paidads.dws_item_performance_1d__reg_s0_live` | 商品广告表现日明细（seller_item_cnt 中商品活跃状态） |
| `mp_order.dws_item_gmv_nd__reg_s0_live` | 商品 GMV N 日宽表（活跃商品数判断） |
| `mp_order.dws_item_gmv_td__reg_s0_live` | 商品 GMV TD 累计宽表（platform_gmv_td） |
| `mp_order.dws_item_gmv_1d__reg_s0_live` | 商品 GMV 日明细（top_selling_item） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表（本地货币转 USD） |

---

## ETL 逻辑摘要

### 数据流

本表以 `seller_info`（店铺维度月末快照）为主驱动，通过 LEFT JOIN 方式依次挂接充值/扣款/余额（topup/deduction/expiry/balance）、广告计划管理（campaign_cnt/campaign_budget）、广告单元状态（ads_cnt/have_expenditure_ads_cnt）、广告商品维度（ads_item_cnt）、月度绩效汇总（all_performance）、TD 累计绩效（ads_performance_td）、商品存量（seller_item_cnt）以及平台 GMV 和 top_selling_item 等共 15 个 CTE/临时视图，最终以 `(shop_id, grass_date, grass_region, tz_type)` 为粒度输出。所有上游数据均通过 `grass_region` 和 `tz_type = 'local'` 过滤保持口径一致。

### 关键 CTE 说明

| CTE | 说明 |
|-----|------|
| `seller_info` | 主驱动表，从 `dim_shop_info_monthly` 取月末卖家维度快照，所有指标均以此为基础 LEFT JOIN |
| `all_performance` | 对 `ads_advertiser_seller_all_metrics_1d`（日粒度）按店铺 SUM 月度汇总，并在外层计算 CTR/CR/ROI 等派生比率字段 |
| `ads_performance_td` | 从 `dws_advertiser_placement_performance_td` 取月末 TD 快照，按店铺聚合各广告位的月累计花费与 GMV |
| `campaign_budget` | 联合 `ads_advertise_mkt`、`dws_campaign_deduction_budget_1d` 和汇率表，按广告类型计算预算额、触达率、消耗比等 |
| `balance_df` | 将日余额快照与未到期充值记录 UNION ALL 后聚合，得到月末各积分类型的实际余额 |

### 注意事项

1. **TD 字段与非 TD 字段不可混用**：`ads_revenue_usd_td` / `ads_gmv_usd_td` 来自独立 TD 累计宽表，与日度累加所得的 `ads_revenue_usd` / `ads_broad_gmv_usd` 口径来源不同，同一分析中请勿混用或相减。
2. **余额字段为时点存量，禁止跨行 SUM**：所有 `_balance_amt` 字段均为月末快照，对多个 `shop_id` 求和可得地区汇总余额，但跨月份 SUM 无意义。
3. **Campaign 类型识别依赖 placement + ads_cnt 组合**：广告计划类型（Search Simple Only / Manual Only / Manual+Simple / Discovery Manual / Discovery Simple / ROI 2.0）由 `max_placement` 和 `ads_cnt` 组合推断，ETL 中不存在单一类型标记字段，分析时应以本表已计算的 `_search_simple_only` / `_discovery_manual` 等后缀字段为准，避免在下游二次推断。

---

*文档生成时间：2026-04-22*