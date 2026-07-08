<!-- ads-workspace-gdoc-sync: gdoc_id=197uzAntChjxDtW_1fKMiXM2toYskb-TWr4xDiG5al-8 gdoc_url=https://docs.google.com/document/d/197uzAntChjxDtW_1fKMiXM2toYskb-TWr4xDiG5al-8/edit -->

# mp_paidads.dws_advertise_net_ads_revenue_1d

**分层：** DWS（数据服务层）
**主键：** `grass_region` + `grass_date` + `tz_type` + `shop_id` + `ads_id` + `campaign_id` + `item_id` + `entrance` + `sub_entrance` + `placement` + `pricing_type` + `ab_sign` + `credit_order_type` + `credit_topup_sub_type` + `sub_push_type` + `new_boost`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日调度（T+1）
**引用频次：** 6 次（候选表范围内）

---

## 业务描述

本表是付费广告域的核心日粒度宽表，汇总各地区广告主在每个自然日内的全量广告收入明细，覆盖付费积分扣费、免费积分扣费（含 SCS、SIP、Lovito、GOV 等细分项目）、展示广告收入、积分到期等多种收入来源，并按含税口径统一换算为 USD。各地区依本地时区参数化调度，确保日期归属与当地业务节奏一致。

本表适用于广告业务的日常经营监控、广告收入归因分析、买量效率评估及 FP&A 对账等场景。通过丰富的维度字段（广告主、广告位、流量类型、产品类型、充值来源等），支持多角度下钻分析，同时提供 `net_ads_revenue_usd_1d`、`gross_ads_revenue_usd_1d` 等口径对齐财务的聚合指标，是广告收入相关报表和下游 DWS/ADS 层的核心数据来源。

本表同时承接广告积分到期（Expiry Credit）、展示广告（Display Ads）的独立数据链路，在最终写入时通过 UNION ALL 将多路数据源归一处理，并在 `product_type_mapping`、`push_type_mapping`、`dim_advertiser`、`dim_shop_ext` 等维表的辅助下完成产品类型、推送类型及店铺属性的补全，为下游提供即用型的广告收入宽表。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，固定为 `'local'`（按本地时区分区）。⚠️ 查询时必须指定 `tz_type = 'local'`，否则将全扫所有时区分区导致数据重复或性能劣化。 |
| `grass_region` | string | 地区分区，标识数据所属市场（如 `ID`、`TH`、`MY` 等），各地区通过参数化调度独立写入。⚠️ 查询时必须指定，否则触发全表扫描。 |
| `grass_date` | date | 日期分区，表示数据所属的本地日期（T+1 更新）。⚠️ 查询时必须指定，否则触发全表扫描。 |

---

### 维度：主键与广告标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 广告主店铺 ID |
| `ads_id` | bigint | 广告 ID |
| `campaign_id` | bigint | 广告计划 ID |
| `item_id` | bigint | 广告扣费关联的商品 ID |
| `ab_sign` | string | AB 实验标识，用于区分不同实验分组 |

---

### 维度：广告位与流量属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `entrance` | int | 广告入口（枚举值），标识广告流量来源入口；枚举定义见 beeshop_ads.proto `AdsEntrance` |
| `sub_entrance` | bigint | 次级广告入口，是 `entrance` 的二级细分，主要应用于 Daily Discover 和 Search 流量 |
| `placement` | int | 广告展位，标识广告展示的具体位置 |
| `pricing_type` | int | 广告计价模式（枚举值），如 CPC、CPM 等；枚举定义见 beeshop_ads.proto `AdsPricingType` |
| `new_boost` | int | 是否为新 Boost 流量（流量来源=4 且 placement 属于特定展位则为 1） |
| `entry_point` | string | 广告入口类型（文本描述），由 `entrance` + `sub_entrance` 关联 `dim_entry_point_mapping` 映射得出 |
| `entry_point_v2` | string | 广告入口类型（V2 版本），由 `dim_entry_point_mapping_v2` 映射得出；详见关联 Google Sheet |
| `traffic_type` | string | 流量类型，如 `Search`、`Daily Discover`、`You May Also Like`、`Brand`、`Game`、`Post Purchase` 等 |

---

### 维度：广告产品类型

| 字段 | 类型 | 说明 |
|------|------|------|
| `main_product_type` | string | 广告产品主要类型，由 `pricing_type` + `placement` 关联 `dim_product_type_mapping` 映射得出；详见关联 Google Sheet |
| `product_type` | string | 广告产品类型，`main_product_type` 的细分；详见关联 Google Sheet |
| `sub_product_type` | string | 广告产品细分类型，`product_type` 的进一步细分；详见关联 Google Sheet |
| `brand_max_ads_type` | int | 品牌广告类型标识（最大广告类型值） |

---

### 维度：充值与积分来源

| 字段 | 类型 | 说明 |
|------|------|------|
| `credit_order_type` | bigint | 充值/扣费订单类型枚举值，完整枚举见 `TransOperation`（如 `DEDUCT_CLICK=1`、`TOPUP=2`、`DEDUCT_IMP=11` 等共 23 种） |
| `credit_order_type_name` | string | 充值/扣费订单类型名称（`credit_order_type` 的文本描述） |
| `credit_topup_sub_type` | bigint | 充值子类别，描述充值属于某个小型或特定项目 |
| `credit_topup_sub_type_name` | string | 充值子类别名称（`credit_topup_sub_type` 的文本描述） |
| `credit_topup_type_name` | string | 充值类型名称，枚举：`paid credit without expiry`（1）/ `paid credit with expiry`（2）/ `free credit without expiry`（3）/ `free credit with expiry`（4） |
| `credit_program_id` | bigint | 本次充值归属的活动/项目 ID（主要用于免费积分发放） |
| `credit_program_name` | string | 本次充值归属的活动/项目名称 |
| `credit_reason` | string | 人工充值（Manual Credit）的审批原因 |
| `credit_operator` | string | 人工上传操作员标识 |
| `push_type` | string | 推送类型，若 `push_type_mapping` 中存在匹配则为 `'ads_push'`，否则为 `'non_ads_push'` |
| `sub_push_type` | string | 充值子推送类型，由 `topup_df` 中的充值子类型展示名派生 |
| `is_package_topup` | tinyint | 是否为套餐充值（1=是，0=否） |
| `is_voucher_topup` | tinyint | 是否为优惠券充值（1=是，0=否） |

---

### 维度：优惠券信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `voucher_id` | bigint | 优惠券 ID |
| `voucher_name` | string | 优惠券名称，关联 `shopee_seller_valueadded_voucher` 表获取 |

---

### 维度：卖家与店铺属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_type` | string | 卖家类型，如 `MYCB`、`CNCB`、`Local` 等，来自 `dim_advertiser` |
| `seller_type_1p` | string | 平台自营（1P）店铺类型，来自 `dim_advertiser` |
| `is_cb_shop` | tinyint | 是否跨境店铺或有跨境商品（1=是，0=否） |
| `is_cb_sip_affiliated` | tinyint | 是否为跨境 SIP 关联店铺（父店为跨境店时子店标记为 1），来自 `dim_shop_ext` |
| `is_local_sip_affiliated` | tinyint | 是否为本地 SIP 关联店铺（父店为本地店时子店标记为 1），来自 `dim_shop_ext` |

---

### 指标：广告净收入与总收入

| 字段 | 类型 | 说明 |
|------|------|------|
| `net_ads_revenue_usd_1d` | double | 广告净收入（含税，USD）。计算逻辑：`paid_credit_revenue_usd_1d + display_ads_revenue_usd_1d + others_free_credit_revenue_usd_1d + paid_credit_expire_amt_usd_1d + others_free_credit_expired_amt_usd_1d - tax_paid_on_free_credit_revenue_usd_1d`。⚠️ 为预计算派生字段，不可直接 SUM 后与分量加减混用，需用分量字段重新组合计算。 |
| `gross_ads_revenue_usd_1d` | double | 广告总收入（含税，USD）。计算逻辑：`net_ads_revenue_usd_1d + free_ads_revenue_amt_usd_1d`；亦等于 `raw_gross_ads_revenue_usd_1d + paid_credit_expire_amt_usd_1d + others_free_credit_expired_amt_usd_1d - tax`（TW 5%、PH 12%、BR CB 2.899%/Local 12.15%）。⚠️ FP&A 口径包含 `paid_credit_expire_amt_usd_1d` 和 `others_free_credit_expired_amt_usd_1d`，但 Ads 口径不包含，使用前请确认所需口径。 |
| `raw_gross_ads_revenue_usd_1d` | double | 原始广告总收入（税前，不含到期积分，USD）。⚠️ 为税前口径，与 `gross_ads_revenue_usd_1d` 口径不同，不可混用。 |
| `free_ads_revenue_amt_usd_1d` | double | 免费广告收入（含税，USD）。计算逻辑：`free_credit_deduction_amt_usd_1d + tax_paid_on_free_credit_revenue_usd_1d`。⚠️ 为预计算派生字段，不可直接 SUM 后拆分。 |

---

### 指标：付费积分收入

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_credit_revenue_usd_1d` | double | 来自付费余额的广告扣费（含税，USD） |
| `paid_credit_expire_amt_usd_1d` | double | 付费余额当日到期未使用金额（含税，USD） |

---

### 指标：展示广告收入

| 字段 | 类型 | 说明 |
|------|------|------|
| `display_ads_revenue_usd_1d` | double | 展示广告收入（含税，USD），来源固定为 `entrance=6`、`placement=9`、`pricing_type=6` |
| `deduction_price_usd` | double | 广告扣费定价金额（USD），来自扣费明细原始价格 |
| `voucher_deduction_price_usd` | double | 优惠券抵扣金额（USD） |

---

### 指标：免费积分收入（汇总）

| 字段 | 类型 | 说明 |
|------|------|------|
| `others_free_credit_revenue_usd_1d` | double | SCS、SIP、Lovito、GOV 四类项目免费积分扣费收入汇总（含税，USD）。计算逻辑：`scs_free_credit_revenue_usd_1d + sip_free_credit_revenue_usd_1d + lovito_free_credit_revenue_usd_1d + gov_free_credit_revenue_usd_1d`。⚠️ 为预计算汇总值，若需拆分分析请使用各明细字段。 |
| `others_free_credit_expired_amt_usd_1d` | double | SCS、SIP、Lovito、GOV 四类项目免费积分到期汇总（含税，USD）。计算逻辑：`scs_free_credit_expired_amt_usd_1d + sip_free_credit_expired_amt_usd_1d + lovito_free_credit_expired_amt_usd_1d + gov_free_credit_expired_amt_usd_1d`。⚠️ 为预计算汇总值，若需拆分分析请使用各明细字段。 |
| `free_credit_deduction_amt_usd_1d` | double | 普通免费余额的广告扣费总额（税前，USD），不含由免费转为付费的收入，也排除 SCS/SIP/Lovito/GOV 项目 |
| `tax_paid_on_free_credit_revenue_usd_1d` | double | 免费广告收入对应的税额（含税，USD），仅适用于泰国（TH）和印尼（ID），不含由免费转为付费的收入及 others 类项目 |

---

### 指标：SCS 项目免费积分

| 字段 | 类型 | 说明 |
|------|------|------|
| `scs_free_credit_revenue_usd_1d` | double | SCS 广告花费从免费额度中扣除的金额（含税，USD） |
| `scs_free_credit_expired_amt_usd_1d` | double | SCS 广告免费积分当日到期余额（含税，USD） |

---

### 指标：SIP 项目免费积分

| 字段 | 类型 | 说明 |
|------|------|------|
| `sip_free_credit_revenue_usd_1d` | double | SIP 广告花费从免费额度中扣除的金额（含税，USD） |
| `sip_free_credit_expired_amt_usd_1d` | double | SIP 广告免费积分当日到期余额（含税，USD） |

---

### 指标：Lovito 项目免费积分

| 字段 | 类型 | 说明 |
|------|------|------|
| `lovito_free_credit_revenue_usd_1d` | double | Lovito 广告花费从免费额度中扣除的金额（含税，USD） |
| `lovito_free_credit_expired_amt_usd_1d` | double | Lovito 广告免费积分当日到期余额（含税，USD） |

---

### 指标：GOV 项目免费积分

| 字段 | 类型 | 说明 |
|------|------|------|
| `gov_free_credit_revenue_usd_1d` | double | GOV 广告花费从免费额度中扣除的金额（含税，USD） |
| `gov_free_credit_expired_amt_usd_1d` | double | GOV 广告免费积分当日到期余额（含税，USD） |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，导致严重性能问题并可能拉取到多时区重复数据：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 当前数据均以本地时区写入，若不过滤将扫描所有时区分区（当前仅 local 有数据，但仍触发全量扫描） |
| `grass_region` | `grass_region = 'ID'`（按需替换） | 触发全地区扫描，数据量激增，跨地区数据混入 |
| `grass_date` | `grass_date = '2025-01-01'`（按需指定范围） | 触发全历史扫描，性能极差 |

示例：
```sql
SELECT shop_id, net_ads_revenue_usd_1d
FROM mp_paidads.dws_advertise_net_ads_revenue_1d
WHERE tz_type = 'local'
  AND grass_region = 'ID'
  AND grass_date = '2025-01-01';
```

---

### 不可直接 SUM 的字段

以下字段为预计算派生指标，多行 SUM 时需注意口径一致性，**不建议对 SUM 结果再做跨字段加减**；若需重新计算合计值，应使用各分量字段：

| 字段 | 问题说明 | 正确计算方式 |
|------|----------|-------------|
| `net_ads_revenue_usd_1d` | 由多分量预计算，跨维度聚合后分量间关系仍成立，但不可与分量字段混合加减 | 用分量字段：`paid_credit_revenue_usd_1d + display_ads_revenue_usd_1d + others_free_credit_revenue_usd_1d + paid_credit_expire_amt_usd_1d + others_free_credit_expired_amt_usd_1d - tax_paid_on_free_credit_revenue_usd_1d` |
| `gross_ads_revenue_usd_1d` | FP&A 口径与 Ads 口径存在差异（到期积分处理方式不同）| 确认口径后，FP&A 口径用 `net_ads_revenue_usd_1d + free_ads_revenue_amt_usd_1d`；Ads 口径用 `raw_gross_ads_revenue_usd_1d + paid_credit_expire_amt_usd_1d + others_free_credit_expired_amt_usd_1d - tax` |
| `free_ads_revenue_amt_usd_1d` | 为 `free_credit_deduction_amt_usd_1d + tax_paid_on_free_credit_revenue_usd_1d` 预计算之和 | 若需拆分免费扣费与税额，使用 `free_credit_deduction_amt_usd_1d` 和 `tax_paid_on_free_credit_revenue_usd_1d` |
| `others_free_credit_revenue_usd_1d` | SCS/SIP/Lovito/GOV 四类汇总，已含多路数据的聚合 | 若需分项分析，使用 `scs_free_credit_revenue_usd_1d`、`sip_free_credit_revenue_usd_1d`、`lovito_free_credit_revenue_usd_1d`、`gov_free_credit_revenue_usd_1d` |
| `others_free_credit_expired_amt_usd_1d` | 同上，为四类到期余额汇总 | 使用 `scs_free_credit_expired_amt_usd_1d`、`sip_free_credit_expired_amt_usd_1d`、`lovito_free_credit_expired_amt_usd_1d`、`gov_free_credit_expired_amt_usd_1d` |
| `raw_gross_ads_revenue_usd_1d` | 为税前口径，不含到期积分，与其他含税字段不可直接相加比较 | 仅用于税前口径对账，勿与 `gross_ads_revenue_usd_1d` 混用 |
| `tax_paid_on_free_credit_revenue_usd_1d` | 仅覆盖 TH、ID 市场，其他地区该字段为 0，跨地区 SUM 时需知晓此口径限制 | 跨地区汇总时注意该字段仅在特定地区有值 |

---

### 时效性说明

本表为 T+1 日粒度数据，每日调度写入前一自然日（本地时区）的数据。查询最新数据时，应使用 `grass_date = current_date - 1`（即昨日分区）。各地区因本地时区不同，数据就绪时间存在差异，建议在调度依赖确认完成后再消费。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertiser_deduction_di__reg_s0_live` | 广告扣费明细，提供每笔广告扣费的金额、广告位、充值订单关联键等核心事实数据 |
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 广告主充值快照，提供充值订单维度及积分到期标识，用于计算到期积分和关联充值属性 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维度表，提供卖家类型、是否跨境店铺等属性 |
| `mp_paidads.dim_entry_point_mapping` | 广告入口点映射表（V1），`entrance` + `sub_entrance` → `entry_point` |
| `mp_paidads.dim_entry_point_mapping_v2` | 广告入口点映射表（V2），`entrance` → `entry_point_v2` + `traffic_type` |
| `mp_paidads.dim_product_type_mapping__reg_s0_live` | 广告产品类型映射表，`pricing_type` + `placement` → 产品类型层级 |
| `mp_paidads.dim_push_type_mapping__reg_s0_live` | 推送类型映射表，`sub_push_type` → `push_type` |
| `mp_paidads.dws_advertise_display_ads_revenue__reg_s0_live` | 展示广告原始收入，提供展示广告税前金额 |
| `brbi_bdseller.mks_bp_fpa_daily` | FP&A 日报数据，提供展示广告税后净收入（2023 年起） |
| `mp_seller.dim_shop_ext__reg_s0_live` | 店铺扩展属性，提供 SIP 关联标识（`is_cb_sip_affiliated`、`is_local_sip_affiliated`） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供本地货币换算汇率（当前 ETL 中预备，未见显式引用） |
| `regbida_keyreports.dim_vat_rate` | VAT 税率维表，提供各地区付费/免费广告的增值税率 |
| `marketplace.shopee_seller_valueadded_voucher_${grass_region}_db__voucher_tab__reg_continuous_s0_live` | 优惠券信息，提供券 ID 与券名称的关联 |

---

## ETL 逻辑摘要

### 数据流

```
regbida_keyreports.dim_vat_rate
        │  (tax: 各类VAT税率)
        ▼
marketplace.shopee_seller_valueadded_voucher_*
        │  (voucher: 券名称)
        ▼
mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live ──► topup_df ──► gov_order (订单粒度归并)
        │                                                       │
        │                                                       ▼
        │                                               expiry_credit (到期积分 × tax × dim_advertiser)
        │
mp_paidads.dwd_advertiser_deduction_di__reg_s0_live ──► deduction_di
        │
        ▼
deduction_di × gov_order × dim_advertiser × tax ──► deduction_amt (扣费各类收入)
        │
brbi_bdseller.mks_bp_fpa_daily × dim_advertiser × tax ──► display_ads_reveune (展示广告税后)
        │
mp_paidads.dws_advertise_display_ads_revenue__reg_s0_live ──► raw_display_ads_reveune (展示广告原始)
        │
        ▼
deduction_amt
  UNION ALL expiry_credit
  UNION ALL display_ads_reveune
  UNION ALL raw_display_ads_reveune
        │
        ▼  (base: 四路合并聚合)
        │
base × sub_entrance_mapping × entrance_mapping × entrance_mapping_v2 ──► output
        │
output × product_type_mapping × dim_advertiser × push_type_mapping × dim_shop_ext
        │
        ▼
dws_advertise_net_ads_revenue_1d__reg_s0_live
(分区: tz_type='local' / grass_region / grass_date)
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `tax` | `regbida_keyreports.dim_vat_rate` | 透视出付费/免费 × 跨境/本地四类 VAT 税率，供后续所有含税计算使用 |
| `voucher` | `shopee_seller_valueadded_voucher_*` | 提取截止当日有效的券 ID 与券名称，关联至充值记录 |
| `topup_df` | `dwd_advertiser_credit_topup_df` + `voucher` | 筛选当日充值记录，派生 `is_taxable_ads`（是否应税）、`gov_order_type`（项目来源分类）等关键维度 |
| `gov_order` | `topup_df` | 将充值订单聚合为订单粒度唯一映射，供扣费明细关联 |
| `dim_advertiser` | `mp_paidads.dim_advertiser__reg_s0_live` | 提供卖家类型、是否跨境店铺，用于税率分支选择 |
| `expiry_credit` | `topup_df` + `dim_advertiser` + `tax` | 计算当日到期的付费/免费积分（含税），按项目分类拆分 |
| `deduction_di` | `dwd_advertiser_deduction_di` | 筛选当日扣费明细，派生 `new_boost` 标识，统一时间格式 |
| `deduction_amt` | `deduction_di` + `gov_order` + `dim_advertiser` + `tax` | 结合税率和跨境属性，计算各类付费/免费积分扣费的税后收入，按广告维度聚合 |
| `display_ads_reveune` | `brbi_bdseller.mks_bp_fpa_daily` + `dim_advertiser` + `tax` | 计算 2023 年起展示广告税后净收入，固定 `entrance=6`、`placement=9`、`pricing_type=6` |
| `raw_display_ads_reveune` | `dws_advertise_display_ads_revenue__reg_s0_live` | 汇总展示广告原始（税前）收入，处理 2022-10-26 前后精度差异 |
| `base` | `deduction_amt` UNION ALL `expiry_credit` UNION ALL `display_ads_reveune` UNION ALL `raw_display_ads_reveune` | 将四路数据源合并为统一结构，按 24 个维度聚合 |
| `sub_entrance_mapping` | `mp_paidads.dim_entry_point_mapping` | 提供 `entrance` + `sub_entrance` → `entry_point` 的二级映射 |
| `entrance_mapping` | `mp_paidads.dim_entry_point_mapping` | 提供 `entrance` → `entry_point` 的主入口映射（无子入口） |
| `entrance_mapping_v2` | `mp_paidads.dim_entry_point_mapping_v2` | 提供 `entrance` → `entry_point_v2` + `traffic_type` 的 V2 版本映射 |
| `product_type_mapping` | `mp_paidads.dim_product_type_mapping__reg_s0_live` | 提供 `pricing_type` + `placement` → 产品类型三级层级映射 |
| `push_type_mapping` | `mp_paidads.dim_push_type_mapping__reg_s0_live` | 提供 `sub_push_type` → `push_type` 映射 |
| `output` | `base` + 三张入口映射表 | 补全入口点和流量类型字段，按 27 个维度聚合输出最终宽表 |
| `dim_shop_ext` | `mp_seller.dim_shop_ext__reg_s0_live` | 提供 SIP 跨境/本地关联店铺标识，最终写入时关联 |
| `dim_shop`（已废弃） | `mp_user.dim_shop__reg_s0_live` | 原店铺属性来源，当前已注释，由 `dim_advertiser` 替代，**实际不生效** |
| `dim_exchange` | `mp_order.dim_exchange_rate__reg_s0_live` | 汇率预备字段，当前 ETL 中未见显式引用，**可能已废弃** |

---

### 注意事项

1. **收入口径区分**：`net_ads_revenue_usd_1d` 为广告平台（Ads）定义的净收入口径；`gross_ads_revenue_usd_1d` 在 FP&A 口径下包含到期积分，但在 Ads 口径下不包含，对账时务必确认口径来源。

2. **税率应用**：所有含税指标均依据 `is_cb_shop`（跨境/本地）选择对应税率（`cb_paid_tax` / `local_paid_tax` / `cb_free_tax` / `local_free_tax`），税率本身随日期变化，来自 `dim_vat_rate`。TW（5%）、PH（12%）、BR（CB 2.899% / Local 12.15%）税率为已知差异地区。

3. **`tax_paid_on_free_credit_revenue_usd_1d` 地区限制**：该税额字段仅在 TH 和 ID 市场有值，其他地区为 0，跨地区汇总时不影响合计但需知悉此口径。

4. **展示广告数据起始日期**：`display_ads_reveune` CTE 中硬编码 `grass_date >= '2023-01-01'`，2023 年以前的展示广告税后收入不在此链路，历史数据对账需注意。

5. **`dim_shop` CTE 已废弃**：ETL 中该 CTE 体内代码已全部注释，不产生任何数据，店铺属性已由 `dim_advertiser` 提供，避免误解。

6. **`dim_exchange` 未被引用**：汇率 CTE 已定义但在后续步骤中未见显式使用，疑似预备字段或历史遗留，当前汇率换算逻辑已内嵌于各源表。

7. **`entry_point` / `entry_point_v2` 未匹配时的默认值**：若入口点映射表无对应记录，两个字段均默认填充为 `'Undefined'`，下游过滤时需注意此类缺失情况。

8. **`push_type` 派生规则**：最终写入时，若 `push_type_mapping` 无匹配（`push_type IS NULL`），则标记为 `'non_ads_push'`；有匹配则标记为 `'ads_push'`，并非存储原始推送类型枚举值。

9. **参数化调度**：ETL SQL 中出现的具体地区代码和时区均为调度模板的参数化实例，本表通过 `${region}`、`${timezone}` 参数覆盖全量地区，各地区按本地时区独立调度写入。

---

*文档生成时间：2026-05-20*