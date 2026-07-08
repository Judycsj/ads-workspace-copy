<!-- ads-workspace-gdoc-sync: gdoc_id=1v28YK9HSoNLtpvDRh9BV41v7BEaHsSyXIa9REvCK6b4 gdoc_url=https://docs.google.com/document/d/1v28YK9HSoNLtpvDRh9BV41v7BEaHsSyXIa9REvCK6b4/edit -->

# mp_paidads.ads_advertise_take_rate_v2_1d

**分层**：ADS（应用数据服务层）
**主键**：`grass_region` + `grass_date` + `entry_point` + `pricing_type` + `is_cb_shop` + `seller_type_1p` + `seller_type` + `is_cb_sip_affiliated` + `is_local_sip_affiliated` + `sub_product_type` + `product_type` + `main_product_type` + `traffic_type`
**分区**：`grass_region`（地区）、`grass_date`（日期）
**更新频率**：每日（T+1）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是 Paid Ads 广告业务的核心宽表，用于衡量广告变现效率（Take Rate），即广告收入占平台 GMV 的渗透率。表中按入口点（entry_point）、计价类型（pricing_type）、广告产品线（product_type 层级）、卖家属性（CB/1P/SIP）等多维度聚合每日广告绩效指标，涵盖曝光、点击、订单、GMV、净收入、毛收入、免费广告收入、过期积分等全链路广告数据，同时附带平台大盘 GMV/NMV 以便直接计算渗透率。

本表同时汇入平台级 GMV 状态分布（反欺诈、已支付、已确认、已完成、取消、退货等）来自 `traffic_omni_oa` 的 NMV 指标，以及广告关联 ADS-ROI 卖家券（Seller Voucher）的 Shopee 承担成本，支持广告 ROI 成本穿透分析和 NMV 口径的 take rate 计算。

主要使用场景包括：广告 take rate 日报/周报/月报监控、广告产品线收入结构分析、跨境/本地卖家广告贡献分拆、SIP 卖家广告激励核算、直播广告专项分析、广告卖家券补贴成本归因，以及与平台大盘 GMV 进行对比分析等。各地区按本地时区参数化调度，覆盖 Shopee 全量市场。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 国家/地区分区键，如 `ID`、`MY`、`TH` 等 |
| `grass_date` | date | 日期分区键，数据统计日期 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `entry_point` | string | 广告入口点分类，如 `Global Search`、`You May Also Like`、`Daily Discover`、`Display`、`Live Ads` 等，由场景事件日志或入口映射表推导而来 |
| `pricing_type` | int | 广告计价类型，如 CPC（1）、CPM（9/10）、OCPM（14）、CPS（20）等 ⚠️ 不同 pricing_type 对应不同的点击口径（普通 click 或去重 click），聚合时需注意口径一致性 |
| `traffic_type` | string | 广告流量类型，按入口点归类，来自 `dim_entry_point_mapping_v2` |
| `main_product_type` | string | 广告主产品线（最高层级），由 `pricing_type + placement` 映射得到 |
| `product_type` | string | 广告产品线（中层级），由 `pricing_type + placement` 映射得到 |
| `sub_product_type` | string | 广告子产品线（最细层级），由 `pricing_type + placement` 映射得到 |
| `is_cb_shop` | tinyint | 是否跨境卖家（1=是，0=否），来自 `dim_advertiser` |
| `seller_type` | string | 卖家类型，如 `MYCB`、`CNCB`、`Local` 等，来自 `dim_advertiser` |
| `seller_type_1p` | string | 1P（一方）卖家类型，来自 `dim_advertiser` |
| `is_cb_sip_affiliated` | tinyint | 是否加入跨境 SIP（卖家激励计划），来自 `dim_shop_ext` |
| `is_local_sip_affiliated` | tinyint | 是否加入本地 SIP（卖家激励计划），1=是，0=否，来自 `dim_shop_ext` |

---

### 指标：广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_imp` | bigint | 广告展示次数（曝光量）。视频广告和直播暗投曝光已从常规广告曝光中剔除，避免重复计算；视频广告曝光由 `video_ads_imp` 单独汇入 ⚠️ 不同入口点口径不完全一致，跨入口点汇总时需确认是否需要去重 |
| `ads_click` | bigint | 广告点击数。OCPM（pricing_type=14）、CPM（9/10/19）等类型使用去重点击（`cps_dedup_click`），直播暗投置 0，直播明投使用 `raw_click`，其余使用普通 `click` ⚠️ 不同计价类型点击口径不同，不建议跨 pricing_type 直接 SUM 后计算 CTR |
| `ads_order` | bigint | 广告带来的订单量 |
| `ads_gmv_usd` | double | 广告带来的 GMV（美元），GMV 原始值除以 100000 归一化后再除以汇率换算 |
| `raw_ads_rev_usd` | double | 原始广告收入（美元），含税，为扣款流水的原始汇总值 |
| `ads_rev_usd` | double | 当天广告净收入（美元），已按 CB/Local 税率从 `raw_ads_rev_usd` 还原为不含税值（`raw_ads_rev_usd / (1 + tax_rate)`）⚠️ 为派生字段，若需跨行汇总请使用 `raw_ads_rev_usd` 和对应税率分别计算 |
| `net_ads_rev_usd` | double | 净广告收入扣除额（美元），口径参考净收入逻辑，来自 `dws_advertise_net_ads_revenue_1d` ⚠️ 为预聚合指标，不可直接与 `ads_rev_usd` 混用，具体口径见数据来源文档 |
| `gross_ads_rev_usd` | double | 毛广告收入（美元），口径参考毛收入逻辑，来自 `dws_advertise_net_ads_revenue_1d` ⚠️ 为预聚合指标，不可直接 SUM 后计算 take rate，需结合分子分母口径 |
| `net_ads_rev_excl_sip_usd_1d` | double | 净广告扣除额中不含 SIP 扣除部分（美元），用于剔除 SIP 激励后的收入分析 |
| `sip_free_credit_revenue_usd_1d` | double | SIP 免费积分对应的广告收入扣减金额（美元） |
| `expired_amt_usd_1d` | double | 当天过期积分对应的税后金额（美元），包括 SCS、SIP、Lovito、GOV 免费广告及付费广告过期积分 |
| `free_ads_rev_usd` | double | 免费广告额度对应的税前收入（美元），不含"免费转付费"的额度 |

---

### 指标：入口点曝光

| 字段 | 类型 | 说明 |
|------|------|------|
| `entry_point_imp` | bigint | 入口点展示次数（大盘曝光），来源为 BI 场景日志、商品曝光日志、视频曝光等多源合并 ⚠️ 不同入口点的曝光来源不同（场景事件/商品曝光/视频播放），跨入口点汇总 SUM 时需确认口径一致性 |
| `platform_imp` | bigint | 全平台广告展示次数汇总（不区分入口点），来自 `item_imp` 按地区聚合 |
| `live_total_entry_point_imp` | bigint | 直播广告入口总曝光量，来自 `ads_take_rate_livestream_performance_1d` 预计算表 ⚠️ 已在上游预计算，非行级加和字段，同一分区内有且仅有一行汇总值，直接引用即可 |
| `live_total_ads_imp` | bigint | 直播广告总曝光量，来自 `ads_take_rate_livestream_performance_1d` 预计算表 ⚠️ 同上，已预计算，勿在本表内再次 SUM |

---

### 指标：平台大盘 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_gmv` | double | 平台总 GMV（美元），计算公式：买家实付运费 + 商品小计 + 应税额 + 保险小计 + 买家手续费 + 买家服务费 - 促销费用 ⚠️ 为地区级汇总值，在本表中会随 entry_point/pricing_type 等维度重复出现在多行，不可直接 SUM；该字段为平台侧分母指标，会按 `grass_region` 聚合后再挂载到更细粒度行上，查询时不可直接跨行 SUM；应先按更高粒度（如 `grass_date + grass_region`）排重后，再取 `MAX` / `SUM(DISTINCT ...)` 或等价方式聚合。 |
| `platform_gmv_excl_testorder` | double | 平台 GMV（排除测试订单），用于 BI 口径的 take rate 计算 ⚠️ 为地区级汇总值，同 `platform_gmv`，不可直接 SUM；若需与 SBA tracker 等看板口径对齐、或对比例指标有较高精度要求，可用此字段替代 `platform_gmv`；该字段同样为平台侧分母指标，会按 `grass_region` 聚合后再挂载到更细粒度行上，查询时不可直接跨行 SUM；应先按更高粒度（如 `grass_date + grass_region`）排重后，再取 `MAX` / `SUM(DISTINCT ...)` 或等价方式聚合。 |
| `platform_nmv` | double | 平台净商品价值（NMV，本地货币），反映平台真实营收健康度 ⚠️ 为地区级汇总值，在本表多行重复，不可直接 SUM |

---

### 指标：平台大盘 NMV（Omni 口径）

| 字段 | 类型 | 说明 |
|------|------|------|
| `omni_platform_nmv` | double | 平台 NMV（本地货币），来自 `traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg`，按 `first_touchpoint_item * atc_prorate` 权重加权 ⚠️ 为地区级汇总值，本表多行重复，不可直接 SUM |
| `omni_platform_nmv_usd` | double | 平台 NMV（美元），同上，换算为 USD ⚠️ 为地区级汇总值，不可直接 SUM |
| `platform_paid_gmv` | double | 平台已支付 GMV（本地货币），来自 `traffic_omni_oa` ⚠️ 地区级汇总值，不可直接 SUM |
| `platform_paid_gmv_usd` | double | 平台已支付 GMV（美元）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_paid_order_fraction` | double | 平台已支付订单比例 ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |
| `platform_confirmed_gmv` | double | 平台已确认 GMV（本地货币），来自 `traffic_omni_oa` ⚠️ 地区级汇总值，不可直接 SUM |
| `platform_confirmed_gmv_usd` | double | 平台已确认 GMV（美元）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_confirmed_order_fraction` | double | 平台已确认订单比例 ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |
| `platform_complete_gmv` | double | 平台已完成 GMV（本地货币），来自 `traffic_omni_oa` ⚠️ 地区级汇总值，不可直接 SUM |
| `platform_complete_gmv_usd` | double | 平台已完成 GMV（美元）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_complete_order_fraction` | double | 平台已完成订单比例 ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |
| `platform_cancel_gmv` | double | 平台取消订单 GMV（本地货币），来自 `traffic_omni_oa` ⚠️ 地区级汇总值，不可直接 SUM |
| `platform_cancel_gmv_usd` | double | 平台取消订单 GMV（美元）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_cancel_order_fraction` | double | 平台取消订单比例 ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |
| `platform_return_gmv` | double | 平台退货 GMV（本地货币），来自 `traffic_omni_oa` ⚠️ 地区级汇总值，不可直接 SUM |
| `platform_return_gmv_usd` | double | 平台退货 GMV（美元）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_return_order_fraction` | double | 平台退货订单比例 ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |
| `platform_antifraud_gmv` | double | 平台反欺诈 GMV（本地货币），来自 `traffic_omni_oa` ⚠️ 地区级汇总值，不可直接 SUM |
| `platform_antifraud_gmv_usd` | double | 平台反欺诈 GMV（美元）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_antifraud_order_fraction` | double | 平台反欺诈订单比例 ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |
| `platform_net_order_fraction` | double | 平台净订单比例，来自 `traffic_omni_oa` ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |
| `platform_paid_with_placed_cod_gmv` | double | 平台已支付（含下单 COD）GMV（本地货币）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_paid_with_placed_cod_gmv_usd` | double | 平台已支付（含下单 COD）GMV（美元）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_paid_with_confirmed_cod_gmv` | double | 平台已支付（含确认 COD）GMV（本地货币）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_paid_with_confirmed_cod_gmv_usd` | double | 平台已支付（含确认 COD）GMV（美元）⚠️ 地区级汇总值，不可直接 SUM |
| `platform_paid_order_with_placed_cod_fraction` | double | 平台已支付订单（含下单 COD）比例 ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |
| `platform_paid_order_with_confirmed_cod_fraction` | double | 平台已支付订单（含确认 COD）比例 ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |

---

### 指标：广告关联卖家券成本

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_voucher_ads_nmv_cost` | double | 广告关联 ADS-ROI 卖家券中 Shopee 承担的净返利金额（本地货币），按广告维度（入口点/产品线/卖家属性）归因 ⚠️ 为净值，已受取消/无效/退货影响，不可简单与订单量对应计算 |
| `ads_voucher_ads_nmv_cost_usd` | double | 广告关联 ADS-ROI 卖家券 Shopee 承担净返利（美元）⚠️ 同上，为净值 |
| `ads_voucher_omni_platform_nmv_cost` | double | 平台全量 ADS-ROI 卖家券 Shopee 承担净返利（本地货币），地区级汇总 ⚠️ 为地区级汇总值，在本表多行重复，不可直接 SUM |
| `ads_voucher_omni_platform_nmv_cost_usd` | double | 平台全量 ADS-ROI 卖家券 Shopee 承担净返利（美元），地区级汇总 ⚠️ 为地区级汇总值，不可直接 SUM |
| `ads_voucher_ads_part_amt_usd` | double | 广告主实际承担的卖家券金额（美元），计算逻辑：`ads_voucher_amt_usd * (1 - voucher_cofund_ratio)`，按地区汇总 ⚠️ 为地区级汇总派生值，本表多行重复，不可直接 SUM |

---

### 指标：Omni 平台 NMV 补充

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order_cnt` | bigint | 广义订单量（宽口径），具体定义见上游 ETL 上下文 ⚠️ comment 为空，请以上游 `dws_advertise_net_ads_revenue_1d` 口径为准 |
| `broad_order_gmv_usd` | double | 广义订单 GMV（美元，宽口径）⚠️ comment 为空，请以上游口径为准 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_date`**：每次查询必须显式指定日期分区，例如 `WHERE grass_date = '2026-05-19'`。缺少该条件将触发全表扫描，导致资源消耗成倍增加。
2. **`grass_region`**：每次查询必须指定地区分区，例如 `AND grass_region = 'ID'`。缺少该条件将跨所有市场扫描，数据量极大。
3. **`tz_type`**：本表数据按本地时区参数化调度写入，查询时建议过滤 `tz_type = 'local'`（若该字段写入分区内），以避免因时区口径混用产生重复计数。

> ⚠️ 遗漏 `grass_date` 或 `grass_region` 任一分区条件，将造成全量分区扫描，严重影响查询性能及集群资源，请务必同时指定。

---

### 不可直接 SUM 的字段

以下字段在本表中存在**地区级汇总值跨多行重复**或**预计算比率**的情况，不可在行级聚合时直接 SUM：

| 字段 | 原因 | 正确做法 |
|------|------|----------|
| `platform_gmv` | 地区级汇总值，随广告维度组合重复出现 | 在 WHERE 中固定一个维度组合取一行值，或使用 MAX/MIN 取唯一值后除以地区行数 |
| `platform_gmv_excl_testorder` | 同上 | 同上 |
| `platform_nmv` | 同上 | 同上 |
| `omni_platform_nmv` | 同上 | 同上 |
| `omni_platform_nmv_usd` | 同上 | 同上 |
| `platform_paid_gmv` / `_usd` | 同上 | 同上 |
| `platform_confirmed_gmv` / `_usd` | 同上 | 同上 |
| `platform_complete_gmv` / `_usd` | 同上 | 同上 |
| `platform_cancel_gmv` / `_usd` | 同上 | 同上 |
| `platform_return_gmv` / `_usd` | 同上 | 同上 |
| `platform_antifraud_gmv` / `_usd` | 同上 | 同上 |
| `platform_paid_with_*_cod_gmv` / `_usd` | 同上 | 同上 |
| `platform_imp` | 地区级汇总值，多行重复 | 同上 |
| `live_total_entry_point_imp` | 预计算值，多行重复 | 取 MAX 或直接 WHERE 单行引用 |
| `live_total_ads_imp` | 预计算值，多行重复 | 同上 |
| `ads_voucher_omni_platform_nmv_cost` / `_usd` | 地区级汇总值，多行重复 | 同上 |
| `ads_voucher_ads_part_amt_usd` | 地区级派生汇总值，多行重复 | 同上 |
| `platform_*_order_fraction` | 预计算比率字段 | 不可 SUM，需重新以订单数分子/订单总数分母计算 |
| `ads_rev_usd` | 由 `raw_ads_rev_usd / (1 + tax_rate)` 派生，跨 CB/本地税率混合时不可直接加总 | 跨 CB/本地卖家汇总时，分别 SUM `raw_ads_rev_usd` 后再做税率还原 |

---

### 时效性说明

本表为每日（T+1）调度，数据通常反映前一天（`grass_date = CURRENT_DATE - 1`）的完整统计结果。以下字段具有特殊时效性注意事项：

- **`net_ads_rev_usd`、`gross_ads_rev_usd`、`net_ads_rev_excl_sip_usd_1d`、`sip_free_credit_revenue_usd_1d`**：来自 `dws_advertise_net_ads_revenue_1d`，若该上游表存在延迟，相关字段可能在当天分区中为空或偏低，建议在使用前确认上游分区就绪状态。
- **`ads_voucher_*_nmv_cost`**：来自订单净值口径，受订单取消/退货影响，历史分区数据可能随净值回溯而变化，建议以最新写入分区为准，避免使用过早拉取的快照。
- **`platform_*_order_fraction` / `platform_*_gmv`（Omni 口径）**：来自 `traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg`，该表按 ATC 旅程对订单进行权重分配，数据可能有 1~2 天额外延迟，请确认分区就绪后再使用。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_ads_report_hi__reg_s0_live` | 广告报告日志，提供原始点击、曝光、GMV、订单等广告绩效事件 |
| `mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live` | 广告净收入/毛收入/过期积分/SIP 收入的日汇总数据 |
| `mp_paidads.dwd_advertiser_deduction_di__reg_s0_live` | 广告主扣款明细，提供每日实际扣款金额 |
| `mp_paidads.dws_advertise_display_ads_revenue__reg_s0_live` | 展示广告（Display）收入和曝光点击数据 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告效果明细，含优惠券详情（voucher_details_json），用于 ADS-ROI 券归因 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主（店铺）维度信息，提供 CB/1P/卖家类型 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度信息，提供广告 ID 对应的产品类型和计价类型 |
| `mp_paidads.dim_entry_point_mapping_v2` | 入口点与流量类型的映射关系维表 |
| `mp_paidads.dim_product_type_mapping__reg_s0_live` | 计价类型与广告位到产品类型层级的映射维表 |
| `mp_paidads.ads_take_rate_livestream_performance_1d__reg_s0_live` | 直播广告预计算入口曝光和广告曝光指标 |
| `mp_paidads.ads_order_voucher_1d__reg_s0_live` | 广告订单关联的卖家券金额及广告主承担比例 |
| `mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live` | 平台订单明细，提供平台 GMV、NMV 及测试订单标识 |
| `mp_order.dwd_order_item_all_ent_df` | 全量订单明细，用于关联 ADS-ROI 卖家券净返利金额 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，用于本地货币转换为 USD |
| `mp_seller.dim_shop_ext__reg_s0_live` | 店铺扩展维度，提供 CB/本地 SIP 计划加入标识 |
| `mp_voucher.dim_voucher__reg_live` | 优惠券维表，过滤 ADS-ROI 券组的卖家券 ID |
| `traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg` | Omni ATC 旅程订单指标，提供加权 NMV 及各状态 GMV/订单分数 |
| `traffic_omni_oa.dwd_scenario_event_log_hi__reg` | 场景事件日志，用于 BI 入口点曝光量计算 |
| `video.video_mart_dws_user_watch_basic_aggr_1d` | 视频播放聚合数据，提供视频广告曝光及入口点分类 |
| `regbida_keyreports.dim_vat_rate` | VAT 税率维表，区分 CB/本地广告收入的税率 |

---

## ETL 逻辑摘要

### 数据流

```
广告绩效事件日志
ods_log_ads_report_hi                    维度关联
        │                    ┌── dim_entry_point_mapping_v2
        ▼                    ├── dim_product_type_mapping
  [performance_di]           └── dim_exchange_rate
        │
        │         广告收入汇总
        │    dws_advertise_net_ads_revenue_1d
        │             │
        │             ▼
        │       [net_revenue]
        │             │
        │    dwd_advertiser_deduction_di
        │             │
        │             ▼
        │       [deduction_di]
        │             │
        │             └──── FULL JOIN ──► [deduction_amt]
        │                                       │
        └──────────── FULL JOIN ───────────► [ads_performance]
                                                │
                          dim_advertiser ──────►│◄── dim_vat_rate [tax]
                                                ▼
                                          [ads_vat]
                                                │
        展示广告                                 │
  dws_advertise_display_ads_revenue             │
        │                                       │
        └──────── UNION ALL ─────────────► [ads_base]
                                           (Cache)
                                                │
        视频广告曝光                             │
  video_mart_dws_user_watch_basic_aggr_1d       │
        │                                       │
        ▼                                       │
  [video_vv]─►[video_ep_imp]                   │
        │                                       │
        └─►[video_ads_imp]                      │
                  │                             │
        ADS-ROI 卖家券                           │
  dwd_advertise_performance_di                  │
        │                                       │
        ▼                                       │
  [ads_order]                                   │
        │                                       │
  dwd_order_item_all_ent_df                     │
  + dim_voucher                                 │
        │                                       │
        ▼                                       │
  [net_order]──►[ads_voucher]                   │
                    │                           │
                    └── UNION ALL ──────────────┘
                                                │
                                                ▼
                                       [all_ads_metrics]
                                                │
        平台大盘曝光                             │
  [item_imp]──►[platform_imp]                   │
                                                │
        平台大盘 GMV                             │
  dwd_order_item_place_pay_complete_di          │
        │                                       │
        ▼                                       │
  [platform_gmv]                                │
                                                │
        BI 场景曝光                              │
  dwd_scenario_event_log_hi──►[bi_imp]          │
                                                │
  [item_imp/video_ep_imp]──►[entry_point_imp]   │
                                                │
        Omni NMV                                │
  dwd_order_item_atc_journey_ext_di             │
        │                                       │
        ▼                                       │
      [nmv]                                     │
                                                │
        直播曝光                                 │
  ads_take_rate_livestream_performance_1d       │
        │                                       │
        ▼                                       │
  [livestream_imp]                              │
                                                │
        广告主承担券金额                          │
  ads_order_voucher_1d──►[ads_voucher_info]     │
                                                │
                         ┌──────────────────────┘
                         │
                         ▼
      [all_ads_metrics] FULL OUTER JOIN [entry_point_imp]
                         │
              LEFT JOIN [platform_imp]
              LEFT JOIN [platform_gmv]
              LEFT JOIN [traffic_mapping]
              LEFT JOIN [nmv]
              LEFT JOIN [net_voucher]
              LEFT JOIN [livestream_imp]
              LEFT JOIN [ads_voucher_info]
                         │
                         ▼
                      [output]
                         │
                         ▼
     ads_advertise_take_rate_v2_1d__reg_s0_live
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `platform_imp` | `item_imp`（内部视图） | 按地区汇总全平台商品广告曝光总量 |
| `scenario_event` | `traffic_omni_oa.dwd_scenario_event_log_hi__reg` | 抽取有效用户的 impression 场景事件，缓存后用于 BI 入口点映射 |
| `bi_imp` | `scenario_event` | 通过多层 CASE WHEN 将场景字段映射为业务入口点，并聚合曝光量 |
| `platform_gmv` | `mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live` | 按地区聚合平台 GMV、NMV 及排除测试订单的 GMV |
| `entrance_mapping` | `mp_paidads.dim_entry_point_mapping_v2` | 过滤有效入口点与 entrance/traffic_type 的映射关系，去重缓存 |
| `traffic_mapping` | `entrance_mapping` | 从入口映射中提取 entry_point 与 traffic_type 的对应关系 |
| `product_type_mapping` | `mp_paidads.dim_product_type_mapping__reg_s0_live` | 计价类型与广告位到三级产品线的映射，去重备用 |
| `performance_di` | `ods_log_ads_report_hi` + 维度表 | 过滤有效广告日志，区分点击口径，换算 USD，按广告主/入口/产品线聚合绩效 |
| `net_revenue` | `dws_advertise_net_ads_revenue_1d` | 按广告主/入口/计价类型聚合各类净/毛收入，缓存备用 |
| `deduction_di` | `dwd_advertiser_deduction_di` | 按广告主/入口/计价类型聚合实际扣款金额 |
| `deduction_amt` | `deduction_di` FULL JOIN `net_revenue` | 全外连接扣款与净收入，关联入口和产品类型映射，统一口径 |
| `ads_performance` | `performance_di` FULL JOIN `deduction_amt` | 合并绩效指标与收入指标，形成广告主级宽表 |
| `tax` | `regbida_keyreports.dim_vat_rate` | 取最新 VAT 税率，区分 CB/Local 广告收入适用税率 |
| `dim_shop` | `mp_paidads.dim_advertiser__reg_s0_live` | 提取广告主 CB/1P/卖家类型维度 |
| `ads_vat` | `ads_performance` + `dim_shop` + `tax` | 按 CB/Local 税率还原含税收入为不含税 `ads_rev_usd` |
| `video_vv` | `video.video_mart_dws_user_watch_basic_aggr_1d` | 映射视频来源页为视频广告入口点，区分广告/非广告曝光 |
| `video_ep_imp` | `video_vv` | 过滤无效入口点，按入口聚合视频总曝光量 |
| `dim_advertise` | `mp_paidads.dim_advertise__reg_s0_live` | 按 ads_id 聚合广告产品类型和计价类型代表值 |
| `video_ads_imp` | `video_vv` + `dim_advertise` | 聚合视频广告曝光量，关联产品类型维度 |
| `display_ads_metrics` | `dws_advertise_display_ads_revenue` FULL JOIN `net_revenue`（entrance=6） | 专项处理展示广告，入口点固定为 'Display'，合并展示广告收入数据 |
| `dim_shop_ext` | `mp_seller.dim_shop_ext__reg_s0_live` | 提取店铺 CB/本地 SIP 计划加入标识 |
| `ads_base` | `ads_vat` UNION ALL `display_ads_metrics` + 维度关联 | 合并常规广告与展示广告，处理直播广告点击/曝光特殊口径，缓存为广告基础指标宽表 |
| `dim_voucher` | `mp_voucher.dim_voucher__reg_live` | 过滤 ADS-ROI 券组的卖家券 ID |
| `net_order` | `mp_order.dwd_order_item_all_ent_df` JOIN `dim_voucher` | 聚合 ADS-ROI 卖家券 Shopee 承担的净返利金额 |
| `ads_order` | `dwd_advertise_performance_di` + 维度表（LATERAL VIEW） | 展开广告订单优惠券详情，关联 ADS-ROI 券，提供广告订单与券的关联关系 |
| `ads_voucher` | `ads_order` JOIN `net_order` | 将广告订单与 ADS-ROI 券净返利关联，按广告维度聚合 Shopee 承担的券成本 |
| `all_ads_metrics` | `ads_base` UNION ALL `video_ads_imp` UNION ALL `ads_voucher` | 三路数据合并，形成广告完整指标宽表 |
| `entry_point_imp` | `bi_imp` UNION ALL `ads_base` UNION ALL `item_imp` UNION ALL `video_ep_imp` | 汇总所有来源的入口点展示量 |
| `nmv` | `traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg` | 按 ATC 旅程权重聚合各状态 GMV/订单分数及 NMV 指标 |
| `net_voucher` | `net_order` | 汇总全平台 ADS-ROI 卖家券 Shopee 承担成本（地区级） |
| `livestream_imp` | `mp_paidads.ads_take_rate_livestream_performance_1d__reg_s0_live` | 读取直播广告预计算的总入口曝光和广告曝光 |
| `ads_voucher_info` | `mp_paidads.ads_order_voucher_1d__reg_s0_live` + `dim_exchange_rate` | 计算广告主实际承担的卖家券金额（剔除平台共担部分） |
| `output` | `all_ads_metrics` FULL OUTER JOIN `entry_point_imp` + 多表 LEFT JOIN | 最终汇总，补充平台大盘指标、Omni NMV、直播曝光、卖家券成本，输出最终宽表 |

---

### 注意事项

1. **平台级汇总字段重复问题**：`platform_gmv`、`platform_imp`、`omni_platform_nmv`、`live_total_ads_imp`、`ads_voucher_omni_platform_nmv_cost` 等字段为地区级（`grass_region + grass_date`）的单一汇总值，在最终 `output` 步骤通过 LEFT JOIN 广播到每一行广告维度组合中，因此同一地区同一日期内这些字段值在所有行中完全相同。**查询时严禁对这些字段直接 SUM**，正确做法是在 GROUP BY `grass_region, grass_date` 后取 MAX 或 ANY_VALUE。

2. **广告点击口径差异**：不同 `pricing_type` 使用不同点击口径——OCPM（14）、CPM 类（9/10/19）使用去重点击（`deduplicated_click`），CPS（20）使用 `cps_dedup_click`，直播明投（`Live Ads`）使用 `raw_click`，直播暗投点击置 0，其余使用普通 `click`。跨计价类型计算 CTR 时需充分理解各口径含义。

3. **广告曝光去重逻辑**：`ads_imp` 在 `ads_base` 中已将视频广告和直播暗投的曝光排除，避免与 `video_ads_imp` 分支重复计算。视频广告曝光通过 `video_ads_imp` 单独计入。查询全量广告曝光时，需将 `ads_base` 来源行与 `video_ads_imp` 来源行分别取数后再加总，或直接对 `all_ads_metrics` 聚合。

4. **含税/不含税收入口径**：`raw_ads_rev_usd` 为含税原始收入，`ads_rev_usd` 为通过 VAT 税率还原后的不含税收入。两者之间按 `is_cb_shop` 选择不同税率（`cb_tax` 或 `local_tax`）。跨 CB 和本地卖家混合汇总时，不可直接 SUM `ads_rev_usd`，应分组还原。

5. **展示广告单独处理**：`entrance = 6` 对应 Display 展示广告，在 `deduction_amt` 中被排除（排除 `entrance = 6` 的记录），转由 `display_ads_metrics` 专门处理后通过 UNION ALL 合并，入口点固定为 `'Display'`。

6. **ADS-ROI 卖家券为净值口径**：`ads_voucher_ads_nmv_cost` 和 `ads_voucher_omni_platform_nmv_cost` 均为净值（已受取消、无效、退货影响），不等于发券时的金额，分析券补贴成本时需注意与订单状态对齐。

7. **参数化多地区调度**：本表通过 `${region}`、`${timezone}` 调度参数在所有 Shopee 市场分别执行，各地区按本地时区统计，SQL 中出现的具体地区代码和时区仅为调度模板的示例实例，不代表特定市场。

---

*文档生成时间：2026-05-20*