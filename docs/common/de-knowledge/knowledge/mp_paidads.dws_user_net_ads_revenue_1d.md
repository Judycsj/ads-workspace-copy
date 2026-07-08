<!-- ads-workspace-gdoc-sync: gdoc_id=1ee5HGme85I9sPj3L2JVoy8ShmT4CwaoREg_TS78gy9g gdoc_url=https://docs.google.com/document/d/1ee5HGme85I9sPj3L2JVoy8ShmT4CwaoREg_TS78gy9g/edit -->

# mp_paidads.dws_user_net_ads_revenue_1d

**分层**：DWS（数据汇总层）
**主键**：`shop_id` + `user_id` + `ads_id` + `item_id` + `campaign_id` + `entrance` + `placement` + `pricing_type` + `sub_entrance` + `credit_order_type` + `credit_topup_type` + `credit_program_id`（联合维度粒度）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：2 次（候选表范围内）

---

## 业务描述

本表是广告收入核心汇总表，以"广告主 × 广告 × 充值订单属性 × 广告位"为最细粒度，记录每自然日内广告主在付费 credit、免费 credit 及展示广告（Display Ads）三条路径下的广告花费与收入，并通过含税/不含税口径、付费/免费来源拆分、以及 SCS / SIP / Lovito / GOV 等专项项目细分，满足财务（FP&A）与广告业务双口径的对账需求。

本表是广告收入报表、广告业务大盘监控、ROI 分析及跨地区财务汇总的核心数据源。下游可按 `product_type`、`main_product_type`、`traffic_type`、`entry_point_v2` 等维度进行多维切片分析，也可按 `credit_topup_type` 区分付费与免费 credit 口径，或按 `grass_region` 比较各地区广告规模。

本表通过参数化调度覆盖所有地区，各地区按本地时区（`tz_type = 'local'`）独立写入分区，税率、跨境（CB）汇率比例等地区差异均在 ETL 中动态计算，确保各地区收入数据口径一致且可横向对比。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，当前写入值固定为 `'local'`（按各地区本地时区统计）。⚠️ 查询时必须指定此字段，否则触发全表扫描，且不同 tz_type 数据不能混合聚合 |
| `grass_region` | string | 地区编码（大写，如 `ID`、`TH`、`MY` 等），各地区独立分区写入 |
| `grass_date` | date | 统计日期（本地时区自然日），格式 `yyyy-MM-dd` |

---

### 维度：主键与广告实体

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID；展示广告（Display Ads）及过期 credit 部分行可能为 NULL |
| `user_id` | bigint | 广告主用户 ID；Display Ads 数据行可能为 NULL |
| `ads_id` | bigint | 广告 ID；展示广告与过期 credit 行可能为 NULL |
| `item_id` | bigint | 商品 ID；非商品关联的广告行可能为 NULL |
| `campaign_id` | bigint | 广告计划 ID；部分数据行可能为 NULL |

---

### 维度：广告位与计价

| 字段 | 类型 | 说明 |
|------|------|------|
| `entrance` | int | 广告入口枚举值，具体枚举定义见 `beeshop_ads.proto#L317` |
| `sub_entrance` | bigint | 广告子入口枚举值；Display Ads 固定为 0 |
| `placement` | int | 广告版位枚举值，见 `beeshop_ads.proto#L148`；Display Ads 固定为 9 |
| `pricing_type` | int | 广告计价模式枚举值（如 CPC、CPM 等），见 `beeshop_ads.proto#L269`；Display Ads 固定为 6 |
| `entry_point` | string | 广告入口类型文字标签，由 `dim_entry_point_mapping` 关联映射；无匹配时为 `'Undefined'` |
| `entry_point_v2` | string | 广告入口类型文字标签（v2 版本），映射规则见 [Google Sheets](https://docs.google.com/spreadsheets/d/1KGiRo6fHws19BqdryeUXN1OU3oPN8JIrlUgR7wCARYk)；无匹配时为 `'Undefined'` |
| `traffic_type` | string | 流量类型（如 `Search`、`Daily Discover`、`You May Also Like`、`Brand`、`Game`、`Post Purchase`）；由 `dim_entry_point_mapping_v2` 映射，无匹配时为 `'Undefined'` |

---

### 维度：广告产品类型

| 字段 | 类型 | 说明 |
|------|------|------|
| `main_product_type` | string | 广告产品主要类型，映射自 `dim_product_type_mapping`；无匹配时为 `'Others'`。详见 [Google Sheets](https://docs.google.com/spreadsheets/d/142y9-AkwK_dpM7vqvmnyvhTfdaJw1virV23KAdnJQY4) |
| `product_type` | string | 广告产品类型，映射自 `dim_product_type_mapping`；无匹配时为 `'others'` |
| `sub_product_type` | string | 广告产品细分类型，映射自 `dim_product_type_mapping`；无匹配时为 `'others'` |

---

### 维度：充值订单属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `credit_order_type` | bigint | 充值/扣费操作类型枚举值（TransOperation），完整枚举见字段描述。常用值：1=扣费点击、2=充值订单、5=联盟广告扣费、11=CPM 扣费等 |
| `credit_order_type_name` | string | 充值/扣费操作类型名称，与 `credit_order_type` 对应 |
| `credit_topup_type` | int | Credit 充值类型：1=付费无期限、2=付费有期限、3=免费无期限、4=免费有期限。⚠️ 此字段是区分付费与免费口径的关键，聚合时须结合此字段做条件过滤 |
| `credit_topup_type_name` | string | Credit 充值类型名称，与 `credit_topup_type` 对应 |
| `credit_topup_sub_type` | bigint | 充值子类别枚举值，用于区分特定小型/专项活动的 credit |
| `credit_topup_sub_type_name` | string | 充值子类别名称，与 `credit_topup_sub_type` 对应 |
| `credit_program_id` | bigint | 免费 credit 所属活动/项目 ID |
| `credit_program_name` | string | 免费 credit 所属活动/项目名称（如 SCS、SIP、Lovito 等项目） |
| `credit_reason` | string | Manual credit 审批原因，用于 GOV 专项认定等 |

---

### 指标：综合广告收入（含税，USD）

| 字段 | 类型 | 说明 |
|------|------|------|
| `gross_ads_revenue_usd_1d` | double | **总广告收入（含税，USD）**。计算公式：`net_ads_revenue_usd_1d + free_ads_revenue_amt_usd_1d`，等价于 `paid_credit_revenue_usd_1d + display_ads_revenue_usd_1d + others_free_credit_revenue_usd_1d + paid_credit_expired_amt_usd_1d + others_free_credit_expired_amt_usd_1d + free_credit_deduction_amt_usd_1d`。⚠️ 此字段为预计算派生值，包含过期 credit（`paid_credit_expired_amt_usd_1d`、`others_free_credit_expired_amt_usd_1d`），与 Ads 业务口径（不含过期）不同，FP&A 口径含过期，使用前请确认所需口径 |
| `net_ads_revenue_usd_1d` | double | **净广告收入（含税，USD）**。计算公式：`paid_credit_revenue_usd_1d + display_ads_revenue_usd_1d + others_free_credit_revenue_usd_1d + paid_credit_expired_amt_usd_1d + others_free_credit_expired_amt_usd_1d - tax_paid_on_free_credit_revenue_usd_1d`。⚠️ 为预计算派生值，直接 SUM 可用于汇总，但不得拆分重构后再相加，过期 credit 已含在内 |
| `raw_gross_ads_revenue_usd_1d` | double | **原始总广告收入（不含税，USD）**。计算公式：`raw_paid_credit_revenue_usd_1d + raw_display_ads_revenue_usd_1d + raw_others_free_credit_revenue_usd_1d + free_credit_deduction_amt_usd_1d`。不含过期 credit，税前口径 |

---

### 指标：付费 Credit 收入（USD）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_credit_revenue_usd_1d` | double | 来自付费 credit（`credit_topup_type` in 1,2）的广告扣费，含税（已扣 VAT），USD。CB 卖家按 CB/Local 比例加权税后计算 |
| `raw_paid_credit_revenue_usd_1d` | double | 来自付费 credit 的广告扣费，**不含税**，USD，即原始扣费金额 |
| `paid_credit_expired_amt_usd_1d` | double | 有期限付费 credit（`credit_topup_type = 2`）过期未使用金额，含税，USD。⚠️ 过期 credit 在 ETL 中按当日活跃 `user_id` 数均摊写入多行（`/count(*) over()`），对此字段 SUM 时须在正确聚合粒度下操作，避免重复计算；仅在 `user_id` 维度行有值，其余维度为 NULL |

---

### 指标：免费 Credit 收入（USD）

| 字段 | 类型 | 说明 |
|------|------|------|
| `free_ads_revenue_amt_usd_1d` | double | 免费广告总收入，含税，USD。计算公式：`free_credit_deduction_amt_usd_1d + tax_paid_on_free_credit_revenue_usd_1d`。⚠️ 为预计算派生值，不可直接 SUM 后再与分量相加，需用分子分量重建 |
| `free_credit_deduction_amt_usd_1d` | double | 来自普通免费 credit（非 SCS/SIP/Lovito/GOV）的广告扣费，**不含税**，USD。不含由免费转付费的收入 |
| `tax_paid_on_free_credit_revenue_usd_1d` | double | 普通免费广告收入对应的税额（仅适用于 ID、TH 特定历史时段），USD。不含 SCS/SIP/Lovito/GOV 及由免费转付费部分 |
| `others_free_credit_revenue_usd_1d` | double | SCS、SIP、Lovito 和 GOV 专项免费 credit 广告扣费之和，含税，USD。计算公式：`scs + sip + lovito + gov` |
| `raw_others_free_credit_revenue_usd_1d` | double | SCS、SIP、Lovito 和 GOV 专项免费 credit 广告扣费之和，**不含税**，USD |
| `others_free_credit_expired_amt_usd_1d` | double | SCS、SIP、Lovito 和 GOV 专项有期限免费 credit 过期金额之和，含税，USD。计算公式：`scs_expired + sip_expired + lovito_expired + gov_expired`。⚠️ 同 `paid_credit_expired_amt_usd_1d`，在 ETL 中按活跃用户数均摊写入，聚合时需注意避免重复计算 |

---

### 指标：专项免费 Credit 收入明细（USD）

| 字段 | 类型 | 说明 |
|------|------|------|
| `scs_free_credit_revenue_usd_1d` | double | SCS（Shopee Co-funded Subsidy）专项免费 credit 广告扣费，含税，USD |
| `sip_free_credit_revenue_usd_1d` | double | SIP（Shopee International Platform）专项免费 credit 广告扣费，含税，USD |
| `lovito_free_credit_revenue_usd_1d` | double | Lovito 专项免费 credit 广告扣费，含税，USD |
| `gov_free_credit_revenue_usd_1d` | double | GOV（政府/官方）专项免费 credit 广告扣费，含税，USD |

---

### 指标：展示广告收入（Display Ads，USD）

| 字段 | 类型 | 说明 |
|------|------|------|
| `display_ads_revenue_usd_1d` | double | 展示广告（Display Ads）扣费，含税，USD。数据源为 `brbi_bdseller.mks_bp_fpa_daily`（巴西地区）及标准 CPM 计算路径 |
| `raw_display_ads_revenue_usd_1d` | double | 展示广告扣费，**含税**，USD（注：字段注释标注含税，与其他 raw 字段不含税的命名惯例不同）。计算公式：`cpm_local × impression_cnt / 100000 / exchange_rate`（2022-10-26 后除以 1000，之前除以 100,000,000）。⚠️ 命名带 `raw_` 但实际为含税值，与 `raw_paid_credit_revenue_usd_1d`（不含税）的命名惯例不同，使用时注意区分 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，缺少任何一个都会触发全量分区扫描，导致计算资源大量消耗且结果可能混入多地区、多时区数据：

```sql
WHERE tz_type     = 'local'           -- 必须指定，当前唯一写入值
  AND grass_region = '<目标地区>'      -- 必须指定，如 'ID'、'TH'、'MY' 等（大写）
  AND grass_date   = DATE('2025-01-01') -- 必须指定具体日期或日期范围
```

- `tz_type` 当前唯一写入值为 `'local'`，**不得省略**，否则无法利用分区裁剪
- `grass_region` 须使用大写地区编码，与 ETL 写入格式保持一致
- 跨地区汇总时，`grass_region` 可用 `IN (...)` 形式指定多个值，但仍需显式列出，不得省略

### 不可直接 SUM 的字段

以下字段为**预计算派生值或均摊值**，跨行聚合前需理解其计算逻辑：

| 字段 | 问题 | 正确计算方式 |
|------|------|------------|
| `gross_ads_revenue_usd_1d` | 含过期 credit，与 Ads 业务口径不同 | 明确口径后，按需用分量字段重建：广告口径排除 `paid_credit_expired_amt_usd_1d` 和 `others_free_credit_expired_amt_usd_1d` |
| `net_ads_revenue_usd_1d` | 含过期 credit（已含在计算公式中） | 按 SUM 聚合可用；但若需排除过期 credit，须用分量字段重建 |
| `free_ads_revenue_amt_usd_1d` | 派生值：`= free_credit_deduction_amt_usd_1d + tax_paid_on_free_credit_revenue_usd_1d` | 直接 SUM 聚合可用；若需拆分，取分量字段 `free_credit_deduction_amt_usd_1d` 和 `tax_paid_on_free_credit_revenue_usd_1d` 分别 SUM 再相加 |
| `paid_credit_expired_amt_usd_1d` | ETL 中按当日活跃用户数均摊后写入多行（`/count(*) over()`），每行仅为均摊后值 | 在 `user_id` 粒度 SUM 全量数据即可还原当日总过期金额；**不得在非用户粒度筛选后再 SUM**，会造成漏计 |
| `others_free_credit_expired_amt_usd_1d` | 同上，按活跃用户数均摊写入 | 同上，在 `user_id` 全量粒度 SUM |
| `raw_display_ads_revenue_usd_1d` | 字段名带 `raw_` 但实际为含税值，与其他 `raw_` 字段不含税的惯例不同 | 需含税展示广告收入时直接 SUM；勿与其他 `raw_` 字段混合进行含税/不含税口径推断 |

### 时效性说明

- 本表为每日调度（T+1），查询应取 **最新已完成写入的 `grass_date`**，即昨日分区
- 过期 credit 字段（`paid_credit_expired_amt_usd_1d`、`others_free_credit_expired_amt_usd_1d`）仅记录**当日过期**的金额，无累计语义，直接按日期范围 SUM 即可获得区间过期总额

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertiser_deduction_di__reg_s0_live` | 广告扣费明细，提供每笔 credit 扣费的核心字段（shop_id、ads_id、deduction_amt_usd、topup_order_id 等） |
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 广告主 credit 充值快照，提供充值类型、充值项目、过期标识、是否 GOV 等分类所需字段 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维表，提供 `is_cb_seller`（是否跨境卖家）字段，用于税率路径选择 |
| `mp_order.dwd_order_item_all_ent_df__br_s0_live` | 巴西订单明细，用于计算 CB（跨境）与 Local 订单的 GMV 比例（`cb_citi_ratio`），作为 BR 税率加权权重 |
| `regbida_keyreports.dim_vat_rate` | VAT 税率维表，按地区和收入类型（paid/free × cb/local）提供对应税率 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告曝光绩效明细，用于计算 Display Ads（placement=9）的原始 CPM 收入 |
| `mkplpaidads_data.dim_display_ads__reg_s3_live` | Display Ads 维表，提供广告预算起止时间，用于过滤有效投放期内的曝光数据 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，用于 Display Ads CPM 收入的本地货币→USD 换算 |
| `brbi_bdseller.mks_bp_fpa_daily` | 巴西 Display Ads FP&A 数据源（`asset_type = 'display ads'`），提供巴西展示广告的税后收入 |
| `mp_paidads.dim_entry_point_mapping` | 入口映射维表（v1），提供 `entrance`/`sub_entrance` → `entry_point` 文字标签映射 |
| `mp_paidads.dim_entry_point_mapping_v2` | 入口映射维表（v2），提供 `entrance` → `entry_point_v2` 及 `traffic_type` 映射 |
| `mp_paidads.dim_product_type_mapping__reg_s0_live` | 产品类型映射维表，提供 `pricing_type`/`placement` → `sub_product_type`/`product_type`/`main_product_type` 映射 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_advertiser_deduction_di         dwd_advertiser_credit_topup_df
        │                                       │
        │ (shop_id, topup_order_id,              │ (order_id, gov_order_type分类,
        │  credit_order_type, ...)               │  is_taxable_ads, 过期标识...)
        └─────────────────────┬─────────────────┘
                              │ LEFT JOIN (topup_order_id = order_id)
                              ▼
                        deduction_amt
                   (按18个维度GROUP BY，
                    分拆 paid / free / SCS / SIP /
                    lovito / gov / display_ads 各口径收入)
                              │
              ┌───────────────┼───────────────────────────┐
              │               │                           │
       expiry_credit    display_ads_reveune      raw_display_ads_reveune
     (过期credit均摊       (BR FP&A口径            (CPM绩效口径
      到活跃用户)           含税展示广告)             原始展示广告)
              │               │                           │
              └───────────────┴──────────┬────────────────┘
                                         │ UNION ALL (4路合并)
                                         ▼
                                        base
                                   (GROUP BY 汇总)
                                         │
              ┌──────────────────────────┼───────────────────────────┐
              │ LEFT JOIN                │ LEFT JOIN                  │ LEFT JOIN
     sub_entrance_mapping          entrance_mapping           entrance_mapping_v2
     (entrance+sub_entrance           (entrance                (entrance → entry_point_v2
      → entry_point)                   → entry_point)           + traffic_type)
              └──────────────────────────┼───────────────────────────┘
                                         │ LEFT JOIN
                                  product_type_mapping
                             (pricing_type+placement → product_type层级)
                                         │
                                         ▼
                      ┌─────────────────────────────────┐
                      │  dws_user_net_ads_revenue_1d    │
                      │  (INSERT OVERWRITE, 分区写入)    │
                      └─────────────────────────────────┘

辅助输入（参与税率/汇率/CB比例计算，贯穿 deduction_amt 与 expiry_credit 两个 CTE）：
  dim_advertiser ──── is_cb_shop 标识
  dim_vat_rate ─────── cb/local × paid/free 四路税率
  ratio_citi ─────────── BR CB/Local GMV 比例（仅 BR 生效）
  dim_exchange_rate ─── CPM → USD 汇率
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `deduction_di` | `dwd_advertiser_deduction_di` | 按日期/地区/tz_type 过滤当日扣费明细，提供每笔广告扣费的基础字段 |
| `ratio_citi` | `dwd_order_item_all_ent_df__br_s0_live` | 计算 BR 地区当日 CB 与 Local 订单的 GMV 占比（`cb_citi_ratio`），用于 BR 广告主税率加权 |
| `tax` | `dim_vat_rate` | 按地区和收入类型透视出四路税率：`cb_paid_tax`、`local_paid_tax`、`cb_free_tax`、`local_free_tax` |
| `dim_advertiser` | `dim_advertiser__reg_s0_live` | 提供 `is_cb_shop` 标识，用于区分跨境与本地税率路径 |
| `topup_df` | `dwd_advertiser_credit_topup_df` | 加载当日充值快照，并通过一系列 `credit_program_name` / `credit_reason` 规则打标 `gov_order_type`（gov/lovito/SIP/SCS/others）和 `is_taxable_ads` |
| `gov_order` | `topup_df` | 对 `topup_df` 按 `order_id` + 充值属性 GROUP BY 去重，形成充值订单级维表 |
| `deduction_amt` | `deduction_di` + `gov_order` + `dim_advertiser` + `tax` + `ratio_citi` | 核心计算 CTE：将扣费与充值订单关联，按 18 个维度 GROUP BY，分别计算 paid/free/SCS/SIP/lovito/gov 各口径含税/不含税收入 |
| `expiry_credit_cal` | `topup_df` + `dim_advertiser` + `tax` + `ratio_citi` | 汇总当日过期 credit（`is_credit_topup_expired_today = 1`）的含税金额，区分付费过期与专项免费过期 |
| `expiry_credit` | `expiry_credit_cal` + `deduction_di` | 将过期 credit 总额按当日活跃广告主（`user_id`）均摊，通过 CROSS JOIN + 窗口函数 `/count(*) over()` 实现 |
| `raw_display_ads_reveune` | `dwd_advertise_performance_di` + `dim_display_ads` + `dim_exchange_rate` | 基于 CPM 曝光数据计算 Display Ads 原始含税 USD 收入（placement=9，自然日内有效投放） |
| `display_ads_reveune` | `brbi_bdseller.mks_bp_fpa_daily` + `dim_advertiser` + `tax` | 巴西 FP&A 口径 Display Ads 含税 USD 收入，按 is_cb_shop 选取对应税率 |
| `base` | 上述4路 UNION ALL | 将扣费收入、过期 credit、BR Display Ads、原始 Display Ads 四路数据 UNION ALL 后 GROUP BY 汇总，形成最终计算宽表 |
| `sub_entrance_mapping` | `dim_entry_point_mapping` | `sub_entrance > 0` 场景下的 `entrance + sub_entrance → entry_point` 映射 |
| `entrance_mapping` | `dim_entry_point_mapping` | `sub_entrance` 为空/0 场景下的 `entrance → entry_point` 映射 |
| `entrance_mapping_v2` | `dim_entry_point_mapping_v2` | `entrance → entry_point_v2 + traffic_type` 映射（v2 口径） |
| `product_type_mapping` | `dim_product_type_mapping` | `pricing_type + placement → sub_product_type + product_type + main_product_type` 三级产品类型映射 |

### 注意事项

1. **过期 credit 均摊机制**：`paid_credit_expired_amt_usd_1d` 和 `others_free_credit_expired_amt_usd_1d` 在 ETL 中通过 `CROSS JOIN expiry_credit_cal` + 窗口函数 `/count(*) over()` 将当日过期总额均摊到所有当日有扣费行为的 `user_id`。这意味着**单行值为均摊后的片段值**，只有对该日所有 `user_id` 行 SUM 才能还原当日真实过期总额。在对特定 `shop_id`、`ads_id` 等子集过滤后 SUM，结果**不代表该子集的过期金额**。

2. **Display Ads 数据双路径**：展示广告（placement=9）存在两条写入路径——`raw_display_ads_reveune`（CPM 绩效口径）和 `display_ads_reveune`（巴西 FP&A 口径），两者在 `base` 中通过 UNION ALL 合并，最终 `display_ads_revenue_usd_1d` 为两路之和。`raw_display_ads_revenue_usd_1d` 仅来源于 CPM 绩效口径，巴西 FP&A 行写入值为 0。

3. **GOV 专项认定规则复杂**：`gov_order_type` 的打标依赖 `credit_program_name` 的模糊匹配（`like '%[gov fund]%'`）、`credit_reason` 关键词匹配及多个白名单列表，历史项目名称可能随业务变更导致边界漂移，如需精确统计 GOV 收入应与广告业务方确认最新规则。

4. **税率逻辑地区差异**：`tax_paid_on_free_credit_revenue_usd_1d` 仅对印尼（ID）全量应用，对泰国（TH）仅在 `topup_create_datetime < '2022-05-01'` 前有值，其他地区恒为 0。聚合多地区数据时此字段会出现大量 0，汇总结果正常。

5. **`raw_display_ads_revenue_usd_1d` 含税问题**：字段注释和字段名均表示"含税"（after tax），与同命名前缀 `raw_paid_credit_revenue_usd_1d`（不含税）不一致，使用时需格外注意，勿基于 `raw_` 前缀假设该字段为税前值。

6. **ETL 模板参数化**：SQL 中出现的 `'${upper_region}'`、`'${grass_date}'`、`'${timezone}'` 均为调度参数，各地区按独立参数调度，文档描述适用于所有地区，不局限于任何单一地区。

---

*文档生成时间：2026-05-20*