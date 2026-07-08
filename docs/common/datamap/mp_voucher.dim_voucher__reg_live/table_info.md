<!-- ads-workspace-gdoc-sync: gdoc_id=1a0qGInWuLSRMmgn-qdqUICltBHiVKz7kWDGj_BpYnlU gdoc_url=https://docs.google.com/document/d/1a0qGInWuLSRMmgn-qdqUICltBHiVKz7kWDGj_BpYnlU/edit -->

# mp_voucher.dim_voucher__reg_live

> **Contributors**: roger.li ｜ **最后更新**：2026-06-10 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/datamap/mp_voucher.dim_voucher__reg_live/table_info.md)

## Description / 表说明

Voucher dimension table（券维表）—— 记录每个 voucher promotion 的完整定义（分类、出资方、折扣规则、配额预算、使用规则等，共 **69 字段**）。

**这是识别「MP 平台券 vs 广告券」的权威维表。** 通过 `promotion_id` 与 unified order 的 `pv_promotion_id` / `sv_promotion_id` join，即可把订单端 pv/sv rebate 成本归类到具体券类型（MP 中心化 smart / local BAU / 我们的 ads 券）。

**分地域物理表 / Region-specific（一个地域一张）**

`__reg_live` 里的 `reg` 是地域占位符，实际是 `dim_voucher__id_live`、`__vn_live`、`__th_live`、`__sg_live`、`__ph_live` …… 查某地域用对应表，**没有 `grass_region` 过滤的必要**（表本身已按地域物理切分，但仍保留 `grass_region` 列）。

**Aliases / Search Keywords**

| Alias | Meaning |
|---|---|
| `dim_voucher` | 券维表（MP voucher dimension） |
| `mp_voucher dim` | MP 券维表 |
| `voucher 维表` / `券维表` | 同上 |

## Access / 权限（重要）

- **表级授权**：仅对 `dim_voucher__{reg}_live` 单表开 READ；`mp_voucher` 整 schema 不可枚举。
- DataMap 未收录本表；`SHOW TABLES` 被网关拒（非只读）；`hive.information_schema.tables` 亦无权限。
- 取字段只能用 `SELECT * FROM mp_voucher.dim_voucher__id_live WHERE grass_date = date '...' LIMIT 1`。
- **网关不支持 lambda `x -> ...`**（`filter(arr, x -> ...)` 报 `mismatched input '>'`）；用 `cross join unnest(voucher_groups) AS g(grp)` 或 `array_join(voucher_groups, '|')` 代替。

## Key Classification / 关键分类标志位（核心结论）

| 标志位 | 含义 | 实测（ID 2026-06-09） |
|---|---|---|
| `is_smart_reg_voucher = 1` | **MP 中心化（reg）smart 券 =「他们的」非 local 券** | 671,540 promo；**100% `mp_voucher_type=PV` + `is_mp_plaform_voucher=1` + `is_shopee_absorbed=1`** |
| `is_smart_ads_voucher = 1` | **广告 smart 券 =「我们的」ads 券**（ROI3） | `mp_voucher_type=SV` |
| `is_smart_seller_voucher = 1` | seller smart 券 | `SV` |
| `is_smart_voucher` | smart 券总标志 | |
| `voucher_groups`（array&lt;string&gt;）| 文本分组标签 | `'Reg Smart Voucher*'` **≡** `is_smart_reg_voucher=1`（实测 671,540 完全相等，0 偏差）→ **优先用 flag，别用字符串** |

**出资方（`mp_voucher_settings`）**：MP reg smart 券 100% `is_shopee_absorbed=1`（无 seller / cofund）→ 成本口径就是 `pv_rebate_by_shopee`，无出资方泄漏。

## Caliber: 券实际成本口径（已验证）

实际花费（后验）**不在本维表**，需 join unified order 的 rebate：

- **MP 非 local smart 券（pv）成本** = `mp_paidads.ods_log_unified_order_event_hi__{reg}_s0_live` 中 `pv_promotion_id ∈ {is_smart_reg_voucher=1 的 promotion_id}` 的 `sum(pv_rebate_by_shopee_amt_usd)/1e5`。**Join key 实测 100% 命中。**
- **PV 平台券 = reg smart（MP 非local）+ 非reg（local BAU）**。local 券普发于全实验组（Global_Control / MP_CONTROL / MP_Treatment），用 DiD（MP_Treatment − MP_CONTROL）亦可自动抵消 local。
- **广告券（sv）成本** = `sv_promotion_id ∈ {is_smart_ads_voucher=1}` 的 `sv_rebate_by_shopee_amt_usd`。

**Planned vs Actual / 计划 vs 实际**：`voucher_quota_settings.max_cost_of_voucher_promotion` 是券的**预算上限（planned）**，与订单端**实际 redeem 成本（actual）**不等。外部「PRM spending 计划表」与本口径反推的实际值**逐日不会相等（合计接近）**，对比时勿混用。

## Technical Properties

| Property | Value |
|---|---|
| **Storage Type** | Hive |
| **Database** | `mp_voucher` |
| **Table** | `dim_voucher__{reg}_live`（reg = id / vn / th / sg / ph / my / tw …） |
| **Partition Keys** | `grass_date`（每日快照），物理按地域分表 |
| **Grain** | 1 行 = 1 个 voucher promotion（`promotion_id`）/ 天 |
| **Timezone** | `tz_type = 'local'` |
| **Join Key** | `promotion_id` ↔ unified order `pv_promotion_id` / `sv_promotion_id` |

## Business Properties

| Property | Value |
|---|---|
| **Owner Team** | MP / Marketplace Voucher（非 Ads；Ads 侧只读） |
| **Business Domain** | `BUSINESS_DOMAIN_MARKETPLACE` / `BUSINESS_LINE_MP` |
| **Data Topic** | Voucher 定义与分类、MP vs Ads 券口径 |
| **Use Case** | MP 平台券 vs 广告券效率对比；非local smart 券识别；券成本归类 |

## Popularity (from-code, 2026-06-15)

- **Studio Tasks References**: 172 files (0 write, 172 read)
  - workflows: 76 (data_paidadsmart 55 + mkplpaidads_data 3 + mkplpaidads_search_ads 18)
  - scheduled_tasks: 26
  - manual_tasks: 70
- **L7D Query Count**: -
- **Completeness**: -
