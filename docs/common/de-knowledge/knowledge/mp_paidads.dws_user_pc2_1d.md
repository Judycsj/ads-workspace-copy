<!-- ads-workspace-gdoc-sync: gdoc_id=1LPOD9A2-OV2tdFC2Jb6VByMm8ZZ1NM0zpoy4sfimRoU gdoc_url=https://docs.google.com/document/d/1LPOD9A2-OV2tdFC2Jb6VByMm8ZZ1NM0zpoy4sfimRoU/edit -->

# mp_paidads.dws_user_pc2_1d

**分层**：DWS（数据服务层）
**主键**：`user_id` + `grass_region` + `grass_date`（在 `tz_type = 'local'` 下唯一）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（Daily，覆盖近 30 天滚动窗口，insert overwrite 方式写入）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表是付费广告域面向**买家维度**的每日宽表，以 `(user_id, grass_date, grass_region)` 为粒度，整合了每位买家在单日内的 GMV、各类 MP 收入、促销成本（PRM）、付费广告收入及 PC2（平台二级利润）等核心财务指标。表名中的 `pc2` 即 Platform Contribution 2，是衡量平台盈利能力的关键财务指标。

核心使用场景包括：付费广告对平台 PC2 贡献分析、买家价值分层（按广告 GMV 与真实 PC2 排序）、广告 ROI 归因分析（ROI3/ROI4）、以及跨业务线的收入与成本拆解。数据同时提供代理 PC2（`proxy_pc2_usd_1d`）、本地 PC2（`local_pc2_usd_1d`）和调整后代理 PC2（`adjusted_proxy_pc2_usd_1d`）三套 PC2 口径，满足不同分析场景下的核算需求。

各地区按本地时区参数化调度，`tz_type = 'local'` 分区存储的是基于各地区本地时区定义的订单创建日期口径数据，为日常分析的标准口径。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型标识。当前有效分区值为 `'local'`（本地时区口径），查询时**必须**过滤 `tz_type = 'local'`，否则将触发全分区扫描。⚠️ 目前仅 `local` 分区有数据，遗漏该过滤条件将导致重复或全表扫描。 |
| `grass_region` | string | 订单所属地区编码（大写，如 `'SG'`、`'ID'`），作为分区列用于数据组织。查询时必须指定目标地区。 |
| `grass_date` | date | 基于本地时区的订单创建日期，作为分区列。覆盖近 30 天滚动数据，每日 insert overwrite 重刷。 |

### 维度：主键与用户属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 买家唯一标识符。ETL 中过滤了 `user_id > 0`，排除匿名/无效用户。 |

### 指标：GMV 与本地 PC2

| 字段 | 类型 | 说明 |
|------|------|------|
| `omni_gmv_usd_1d` | double | 该买家当日在全渠道（omni）归因下的 GMV（美元），基于 ATC journey 的 `atc_prorate * first_touchpoint_item` 加权计算得出。⚠️ 为归因加权值，非原始订单 GMV，跨用户直接 SUM 需理解归因口径。 |
| `local_pc2_usd_1d` | double | 本地团队确认的固定口径 PC2（美元），来源于 omni journey 中的 `pc2_usd` 经 `atc_prorate * first_touchpoint_item` 加权。⚠️ 为"本地确认口径"，与 `proxy_pc2_usd_1d` 和 `true_pc2_usd_1d` 存在口径差异，勿混用。 |

### 指标：MP 收入明细

| 字段 | 类型 | 说明 |
|------|------|------|
| `estimate_mp_revenue_usd_1d` | double | 预估市场平台佣金收入（美元），不含 VAT。计算公式：强制佣金 + 可选佣金 + 手续费 + 其他 MP 收入（other_revenue，仅在 omni_gmv_usd > 0 时计入）。⚠️ 为派生字段，不可直接与子项 SUM 后对比，需用公式重新计算。 |
| `estimate_mandatory_commission_fee_usd_1d` | double | 预估净强制佣金收入（美元），不含 VAT，合计所有店铺类型。 |
| `estimate_local_c2c_mandatory_commission_fee_usd_1d` | double | 预估净强制佣金收入（美元），不含 VAT，来自本地非官方店（C2C）。 |
| `estimate_local_mall_mandatory_commission_fee_usd_1d` | double | 预估净强制佣金收入（美元），不含 VAT，来自本地官方店（Mall）。 |
| `estimate_cb_mandatory_commission_fee_usd_1d` | double | 预估净强制佣金收入（美元），不含 VAT，来自跨境店（CB Shop）。 |
| `estimate_optional_commission_fee_usd_1d` | double | 预估净可选佣金收入（美元），不含 VAT，合计所有店铺类型。 |
| `estimate_local_c2c_optional_commission_fee_usd_1d` | double | 预估净可选佣金收入（美元），不含 VAT，来自本地非官方店（C2C）。 |
| `estimate_local_mall_optional_commission_fee_usd_1d` | double | 预估净可选佣金收入（美元），不含 VAT，来自本地官方店（Mall）。 |
| `estimate_cb_optional_commission_fee_usd_1d` | double | 预估净可选佣金收入（美元），不含 VAT，来自跨境店（CB Shop）。 |
| `estimate_handling_fee_usd_1d` | double | 预估净卖家+买家手续费收入（美元），不含 VAT。等于 `estimate_seller_handling_fee_usd_1d + estimate_buyer_handling_fee_usd_1d`。⚠️ 为两项子字段之和，直接 SUM 与子项之和一致，但注意该字段在 ETL 中以 `handling_fee_usd` 命名输出，对应目标表字段。 |
| `estimate_seller_handling_fee_usd_1d` | double | 预估净卖家手续费收入（美元），不含 VAT。 |
| `estimate_buyer_handling_fee_usd_1d` | double | 预估净买家手续费收入（美元），不含 VAT。 |
| `other_revenue_usd_1d` | double | 营销收入 + 净付费广告收入 + DP 收入（美元），不含 VAT。⚠️ 该字段为地区大盘值按有效买家均摊所得（`other_revenue_usd_1d / valid_user_cnt`），仅在 `omni_gmv_usd > 0` 的用户中分配，跨用户 SUM 可还原地区合计，但不可作为个体精确值解读。 |

### 指标：促销成本（PRM）

| 字段 | 类型 | 说明 |
|------|------|------|
| `estimate_promotion_excl_3pl_usd_1d` | double | 不含 3PL 的预估净促销成本合计（美元），对应 ETL 中的 `estimate_net__total_item_voucher_logst_prm_usd_level1`，包含商品券+物流券+商品卡促销等。⚠️ 字段名含"excl_3pl"，即已剔除 3PL 物流保证金部分，与 `estimate_logst_prm_usd_1d` 口径不同。 |
| `estimate_logst_prm_usd_1d` | double | 预估净物流促销成本合计（美元）。 |
| `estimate_item_card_prm_usd_1d` | double | 预估净商品卡促销价值（美元）。 |
| `estimate_voucher_prm_usd_1d` | double | 预估净券促销价值合计（美元）。 |
| `estimate_coin_prm_usd_1d` | double | 预估净金币奖励相关成本合计（美元）。 |

### 指标：PC2 核算

| 字段 | 类型 | 说明 |
|------|------|------|
| `proxy_pc2_usd_1d` | double | 代理 PC2（美元），口径：强制佣金 + 可选佣金 + 手续费 + 其他 MP 收入 + 付费广告净收入 - 付费广告券（广告分担部分）。仅计入 ROI3 和 ROI4 口径的广告收入。⚠️ 为派生加总字段，不可拆分子项后直接 SUM，需用各子项重新计算。 |
| `adjusted_proxy_pc2_usd_1d` | double | 调整后代理 PC2（美元），计算公式：`item_proxy_pc2% × (category_local_pc2% / category_proxy_pc2%) × omni_gmv_usd`。通过品类本地 PC2 率对代理率进行校正，得到与本地口径更接近的 PC2 估算值。⚠️ 为多级比率乘积后与 GMV 相乘的派生值，分子分母均在品类层聚合，不可对此字段直接跨用户 SUM 后再除以 GMV 得出比率，需回溯原始品类口径重新计算。 |
| `true_pc2_usd_1d` | double | 真实 PC2（美元），最完整的 PC2 口径。公式：MP收入 - PRM（不含3PL）+ 3PL净利润 - RSF/RTS - 总交易手续费。具体：(强制佣金 + 可选佣金 + 手续费 + 其他MP收入) - 不含3PL促销成本 + 3PL净利润 - RSF/RTS - 总交易手续费。⚠️ 为多项相加减的派生字段，其中 RSF/RTS 和 gross_transaction_fee 均为均摊值（按有效用户均摊），对单用户解读需注意精度。 |

### 指标：3PL 与交易成本

| 字段 | 类型 | 说明 |
|------|------|------|
| `estimate_3pl_margin_usd_1d` | double | 预估净第三方物流（3PL）利润（美元），支持物流盈利能力的财务分析。来源于 `mp_mgmt.dws_order_3pl_margin_di__reg_s1_live`，按买家维度汇总。 |
| `rsf_and_rts_usd_1d` | double | 逆向物流费用（RSF）和退货给卖家（RTS）费用合计（美元）。⚠️ 来自地区大盘月度数据按天均摊、再按有效买家均摊，仅在 `omni_gmv_usd > 0` 时分配给用户，是均摊估算值而非精确个体值，跨用户 SUM 可近似还原地区合计。 |
| `gross_transaction_fee_usd_1d` | double | 总交易手续费（美元）。⚠️ 同 `rsf_and_rts_usd_1d`，为地区大盘月度数据按天、按有效买家均摊所得，仅对 `omni_gmv_usd > 0` 的用户分配，是均摊估算值。 |

### 指标：付费广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_ads_revenue_usd_1d` | double | 付费广告收入（美元），来源于广告投放消耗（expenditure_amt_usd），对应广告主支付金额。 |
| `paid_ads_net_revenue_usd_1d` | double | 付费广告净收入（美元），从 `dws_user_net_ads_revenue_1d` 获取，去除折扣/抵扣后的实际净收入。 |
| `paid_ads_broad_gmv_usd_1d` | double | 广告宽口径（Broad）归因 GMV（美元），含 ROI3、ROI4 等所有广告归因订单。 |
| `paid_ads_voucher_ads_part_amt_usd_1d` | double | 付费广告券费用中由广告主承担的部分（美元）。ROI3 口径计入全部金额，联合补贴（cofund）口径仅计入广告分担部分（`ads_voucher_amt_usd × (1 - voucher_cofund_ratio)`）。⚠️ 金额口径依赖 `voucher_cofund_ratio` 的准确性，不同归因场景下含义有差异，使用时需确认分析口径。 |

---

## 查询使用须知

### 必须包含的过滤条件

| 过滤字段 | 推荐值 / 说明 | 遗漏后果 |
|----------|--------------|---------|
| `tz_type` | 必须指定 `tz_type = 'local'` | 遗漏将触发所有 tz_type 分区扫描，产生数据重复或扫描量暴增 |
| `grass_region` | 指定目标地区，如 `grass_region = 'SG'` | 遗漏将扫描所有地区分区，数据量极大且结果混入多地区 |
| `grass_date` | 指定具体日期或日期范围，如 `grass_date = '2026-04-21'` | 遗漏将触发全量历史分区扫描（表保留近 30 天数据，但每次仍可能扫描大量分区） |

**标准查询模板**：
```sql
SELECT ...
FROM mp_paidads.dws_user_pc2_1d
WHERE tz_type = 'local'
  AND grass_region = 'SG'
  AND grass_date = '2026-04-21'
```

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确计算方式 |
|------|---------|-------------|
| `adjusted_proxy_pc2_usd_1d` | 通过品类级别多重比率派生，`item_pc2_rate × (local_category_pc2_rate / category_pc2_rate) × omni_gmv_usd`，品类比率在聚合层计算，对此字段 SUM 后再除以 GMV 会产生误差 | 如需品类或地区整体的 adjusted_proxy_pc2 比率，应回溯 `item_pc2` / `category_pc2` / `local_category_pc2` 层级重新计算 |
| `other_revenue_usd_1d` | 地区大盘 other_revenue 按有效买家数均摊，是估算分摊值 | 若需地区合计 other_revenue，直接 SUM 本字段（仅对有 GMV 的用户）近似可用；若需精确值，应查询 `mp_mgmt.ads_mgmtview_pl_1d__reg_live` 原表 |
| `rsf_and_rts_usd_1d` | 月度 RSF/RTS 按天数均摊后再按有效用户均摊，是双重均摊估算值 | 地区合计可 SUM 近似使用；精确地区合计应查询 `mp_paidads.dim_rsf_rts_transaction_fee_mf__reg_s0_live` 原表 |
| `gross_transaction_fee_usd_1d` | 同 `rsf_and_rts_usd_1d`，月度数据按天、按有效用户双重均摊 | 同上，精确值需回溯维度表 |
| `estimate_mp_revenue_usd_1d` | 派生字段，等于强制佣金 + 可选佣金 + 手续费 + other_revenue | 验证时用子项相加，注意 `other_revenue_usd_1d` 的均摊特性 |
| `true_pc2_usd_1d` | 多项加减派生，部分子项（RSF/RTS、交易费）为均摊值 | 不可对此字段进行比率计算后与其他指标比较，需清楚各子项口径 |
| `proxy_pc2_usd_1d` | 派生加总字段，包含广告净收入和广告券抵扣 | 验证时需用 ETL 公式：强制佣金 + 可选佣金 + 手续费 + 其他 MP 收入 + 付费广告净收入 - 广告券广告分担额 |

### 时效性说明

本表采用**近 30 天滚动覆盖**机制（`grass_date between grass_date_30day and grass_date`），每日 insert overwrite 重刷分区。查询时：
- 建议取**最新可用分区日期**（通常为昨日，T-1）获取完整数据；
- `rsf_and_rts_usd_1d` 和 `gross_transaction_fee_usd_1d` 来源于月度维度表，取最近一个月的值（按 `month_rank = 1`），月初时可能使用上月数据，存在一定时滞，跨月分析时需注意。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live` | 提供全渠道订单归因 GMV（`gmv_usd`）和本地 PC2（`pc2_usd`），基于 ATC journey 加权 |
| `mp_mgmt.dws_order_item_rev_di__reg_s0_live` | 提供订单级佣金（强制/可选）、手续费（卖家/买家）及其他收入的估算值 |
| `mp_mgmt.dws_order_item_rebate_di__reg_s0_live` | 提供订单级促销成本（物流券、商品券、商品卡、代金券、金币）的估算值 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 提供付费广告消耗（expenditure）和宽口径归因 GMV（broad_gmv） |
| `mp_paidads.dws_user_net_ads_revenue_1d__reg_s0_live` | 提供买家维度付费广告净收入 |
| `mp_paidads.ads_order_voucher_1d__reg_s0_live` | 提供广告券金额及广告/联合补贴分摊比例 |
| `mp_item.dim_item__reg_s0_live` | 提供商品品类信息（`level2_global_be_category_id`），用于品类 PC2 率计算 |
| `traffic_omni_oa.dim_item_pc2_rate_map__reg_live` | 提供本地品类 PC2 率（`pc2_rate`），用于调整代理 PC2 |
| `mp_mgmt.dws_order_3pl_margin_di__reg_s1_live` | 提供买家维度的 3PL 净利润估算 |
| `mp_mgmt.ads_mgmtview_pl_1d__reg_live` | 提供地区大盘其他收入（other_revenue），含营销收入、DP 收入等 |
| `mp_paidads.dim_rsf_rts_transaction_fee_mf__reg_s0_live` | 提供月度 RSF/RTS 及总交易手续费，用于均摊至用户层 |

---

## ETL 逻辑摘要

### 数据流

```
traffic_omni_oa.dwd_order_item_atc_journey_di         mp_mgmt.dws_order_item_rev_di
           │ (omni GMV / local PC2)                              │ (佣金/手续费)
           └──────────────────────┬──────────────────────────────┘
                                  │                   mp_mgmt.dws_order_item_rebate_di
                                  │                              │ (PRM成本)
                                  ▼                              │
                           [omni_base]                           │
                                  │                              │
                                  └──────────────────────────────┘
                                  │  LEFT JOIN (order/item/model/group/bundle维度)
                                  ▼
                      [omni_central_rebate_base]
                      (user_id × grass_date × item_id 粒度)
                                  │
        ┌─────────────────────────┼──────────────────────────────────┐
        │                         │                                  │
[ads_base]                 [net_rev_base]                   [ads_voucher_base]
mp_paidads.dwd_advertise   mp_paidads.dws_user_net         mp_paidads.ads_order_voucher_1d
_performance_di            _ads_revenue_1d                  (广告券/cofund比例)
(广告消耗/broad GMV)        (净广告收入)
        │                         │                                  │
        └─────────────────────────┴──────────────────────────────────┘
                     UNION ALL → 按 (grass_date, user_id, item_id) GROUP BY
                                  │
                                  ▼
                             [real_pc2]  ◄── mp_item.dim_item (品类ID)
                             (含 pc2 计算)
                                  │
              ┌───────────────────┼────────────────────────┐
              ▼                   ▼                         ▼
        [item_pc2]        [category_pc2]          [local_category_pc2]
        (商品PC2率)        (品类代理PC2率)     traffic_omni_oa.dim_item_pc2_rate_map
              │                   │                         │
              └───────────────────┴─────────────────────────┘
                                  ▼
                         [adjusted_item_pc2]
                         (调整后品类PC2率)
                                  │
                                  ▼
                    [real_pc2] LEFT JOIN [adjusted_item_pc2]
                    → 按 user_id 聚合 → [user_base]
                                  │
        ┌─────────────────────────┼────────────────────────┐
        │                         │                        │
[rsf_rts_base]            [margin_base]            [other_rev_base]
mp_paidads.dim_rsf_rts     mp_mgmt.dws_order        mp_mgmt.ads_mgmtview_pl_1d
_transaction_fee_mf        _3pl_margin_di           (地区大盘other_revenue)
(月度均摊 RSF/GTF)          (3PL净利润)
        │                         │                        │
        └─────────────────────────┴────────────────────────┘
                      LEFT JOIN → [output]
                                  │
                                  ▼
          INSERT OVERWRITE dws_user_pc2_1d partition(tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `central_base` | `mp_mgmt.dws_order_item_rev_di__reg_s0_live` | 提取订单级佣金（强制/可选/按店铺类型拆分）和手续费，`COALESCE` 空值为 0，过滤 `is_bi_excluded_rev_prm=0` |
| `rebate_base` | `mp_mgmt.dws_order_item_rebate_di__reg_s0_live` | 提取订单级各类促销成本（物流/商品卡/券/金币），过滤 `is_bi_excluded_rev_prm=0` |
| `omni_base` | `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live` | 计算归因加权 GMV 和 PC2（`atc_prorate × first_touchpoint_item`），过滤有效买家（`user_id > 0`，`tz_type = 'local'`） |
| `omni_central_rebate_base` | `omni_base` LEFT JOIN `central_base` / `rebate_base` | 以订单×商品×型号×分组×捆绑订单为 JOIN key，聚合到 `(grass_date, user_id, item_id)` 粒度 |
| `ads_base` | `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 按买家和商品汇总广告消耗和宽口径归因 GMV，过滤 expenditure 或 broad GMV 有值的记录 |
| `net_rev_base` | `mp_paidads.dws_user_net_ads_revenue_1d__reg_s0_live` | 按买家和商品汇总广告净收入（`tz_type = 'local'`） |
| `ads_voucher_base` | `mp_paidads.ads_order_voucher_1d__reg_s0_live` | 计算广告券中广告主分担金额：`ads_voucher_amt_usd × (1 - voucher_cofund_ratio)`，按买家和商品汇总 |
| `real_pc2` | UNION ALL：`omni_central_rebate_base` + `ads_base` + `net_rev_base` + `ads_voucher_base` | 合并所有来源，计算 `pc2 = 强制佣金 + 可选佣金 + 手续费 + 广告净收入 - 广告券广告分担`；LEFT JOIN `dim_item` 获取品类 ID，CACHE 以供后续多次使用 |
| `item_pc2` | `real_pc2` | 计算商品级 PC2 率：`SUM(pc2) / SUM(omni_gmv_usd)`，粒度为 `(grass_date, item_id, category_id)` |
| `category_pc2` | `real_pc2` | 计算品类级代理 PC2 率：`SUM(pc2) / SUM(omni_gmv_usd)`，粒度为 `(grass_date, category_id)` |
| `local_category_pc2` | `traffic_omni_oa.dim_item_pc2_rate_map__reg_live` | 获取本地团队确认的品类 PC2 率，用 `SUM(DISTINCT pc2_rate)` 去重聚合 |
| `adjusted_item_pc2` | `item_pc2` LEFT JOIN `category_pc2` / `local_category_pc2` | 计算调整后商品 PC2 率：`item_pc2_rate × (local_category_pc2_rate / category_pc2_rate)` |
| `margin_base` | `mp_mgmt.dws_order_3pl_margin_di__reg_s1_live` | 按买家汇总 3PL 净利润 |
| `other_rev_base` | `mp_mgmt.ads_mgmtview_pl_1d__reg_live` | 按地区、日期汇总 other_revenue（仅 shopee 业务线，`tz_type = 'local'`） |
| `rsf_rts_base` | `other_rev_base` + `real_pc2`（用于统计有效用户数）+ `dim_rsf_rts_transaction_fee_mf` | 将月度 RSF/RTS、交易手续费和 other_revenue 按天、按有效买家数均摊；取最近一个有数据月份（`month_rank = 1`）的数据 |
| `output` | `user_base`（real_pc2聚合至用户）LEFT JOIN `adjusted_item_pc2` / `rsf_rts_base` / `margin_base` | 最终组装所有指标，计算 `true_pc2`、`estimate_mp_revenue`，写入目标表 |

### 注意事项

1. **三套 PC2 口径并存**：本表同时存储 `local_pc2_usd_1d`（本地确认固定值）、`proxy_pc2_usd_1d`（代理估算，仅含ROI3/ROI4广告）和 `adjusted_proxy_pc2_usd_1d`（经品类本地率校正的代理值）、`true_pc2_usd_1d`（最完整口径，含所有成本项），使用前必须明确分析场景对应口径。

2. **RSF/RTS 和交易手续费为均摊值**：`rsf_and_rts_usd_1d` 和 `gross_transaction_fee_usd_1d` 均来自月度维表按天均摊、再按当日有效买家数均摊，属于统计估算而非精确到个人的计算值。月初跨月时，ETL 取最近有记录的月份（`month_rank = 1`），可能使用上月数据，存在约 0~30 天的时滞。

3. **other_revenue 均摊逻辑**：`other_revenue_usd_1d` 为地区级大盘数值按当日有效买家（`omni_gmv_usd > 0` 的用户）平均分配，仅出现在有 GMV 的用户行中。全地区聚合时 SUM 可近似还原总量，但对单用户无精确含义。

4. **UNION ALL 合并策略**：ETL 采用 UNION ALL 方式将 omni/central/rebate 与广告侧数据在 `(grass_date, user_id, item_id)` 粒度合并，各来源互不重叠字段置 0，最终 GROUP BY 聚合。如出现某用户既无 GMV 又无广告消耗的情况，该用户不会出现在本表。

5. **`local_category_pc2` 使用 `SUM(DISTINCT pc2_rate)`**：该写法用于在维度表中对同一品类去重后取唯一比率值，若 `dim_item_pc2_rate_map` 中存在同品类多条记录（不同 item_id 但 pc2_rate 相同），结果正确；若确实存在同品类多个不同比率，`SUM(DISTINCT)` 会将其加总，需关注上游维表数据质量。

6. **`is_bi_excluded_rev_prm = 0` 过滤**：`central_base` 和 `rebate_base` 均过滤了此标记，表示已排除 BI 口径下不计入收入/促销的特殊订单，确保财务口径一致。

---

*文档生成时间：2026-04-22*