<!-- ads-workspace-gdoc-sync: gdoc_id=1DHeIlUIa0P3pIVsLH_Jv9_1g-VQiUncsAHO0aq_iB7M gdoc_url=https://docs.google.com/document/d/1DHeIlUIa0P3pIVsLH_Jv9_1g-VQiUncsAHO0aq_iB7M/edit -->

# mp_paidads.ads_new_pc2_rate_exp_1d

**分层**：ADS（应用数据服务层）
**主键**：`scenario_tag` + `exp_group_id` + `domain` + `grass_region` + `grass_date`
**分区**：`grass_region`（地区）、`grass_date`（日期）
**更新频率**：每日调度（T+1）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表是付费广告（Paid Ads）团队用于 **A/B 实验分析**的核心 ADS 层宽表，记录各广告/推荐场景（`scenario_tag`）在不同实验分组（`exp_group_id`）下，以实验用户为粒度聚合后的每日 PC2（Platform Contribution to Profit）及相关收益、成本明细指标。各地区按本地时区参数化调度，覆盖全平台所有地区。

本表的核心使用场景是：**实验上线效果评估**——通过关联 A/B 实验分组信息，对比不同实验组在 GMV、MP Revenue、各类佣金、促销补贴、Paid Ads 广告收入及 PC2 利润等核心指标上的差异，支撑推荐/搜索/广告策略的数据决策。

数据覆盖多个聚合口径的推荐场景（如 Cart Unify、RCMD Unify、Search_RCMD、DD_PP Unify 等），同时支持原子场景（如 Daily Discover、Global Search、Me YMAL 等），并将平台大盘 PC2 相关字段（`local_pc2_usd_1d`、`true_pc2_usd_1d` 等）通过用户维度左关联挂载，使实验分析者可在同一张表中同时获取广告场景侧指标与平台大盘侧指标，极大简化下游分析 SQL 复杂度。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `grass_region` | string | 地区编码（大写），如 `MY`、`TH`、`ID` 等；各地区按本地时区参数化调度 |
| `grass_date` | date | 数据日期（本地时区），为对应地区的 grass_date |

---

### 维度：主键与实验属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `scenario_tag` | string | 推荐/广告场景标签，标识数据所属的业务场景或聚合口径。原子场景如 `Daily Discover`、`Global Search`、`Me YMAL` 等；聚合口径如 `Cart Unify`（购物车系列场景合集）、`RCMD Unify`（推荐系列场景合集）、`Search_RCMD`（搜索+推荐联合口径）、`DD_PP Unify`（Daily Discover & Post Purchase 合集）；部分场景名做了重命名处理（如 `Order Detail Page YMAL`、`SIP YMAL`）⚠️ 同一 `grass_date` 下同一用户可能同时出现在多个 `scenario_tag` 中（因各 Unify 口径存在场景重叠），跨场景 SUM 会重复计算，需明确场景口径后过滤 |
| `exp_group_id` | bigint | A/B 实验分组 ID，来自实验平台，标识用户所属的实验桶 |
| `domain` | string | 实验所属域，当前取值为 `RCMD_Ads`（推荐广告域）或 `Search`（搜索域） |

---

### 指标：平台大盘 GMV

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `omni_gmv_usd_1d` | double | 全渠道（Omni-channel）GMV，单位 USD，当日累计值；为该实验组下用户在对应场景的全渠道成交总额 |

---

### 指标：MP Revenue 及佣金明细

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `estimate_mp_revenue_usd_1d` | double | 估算 Marketplace Revenue，单位 USD，当日累计值；为平台整体收入估算 |
| `estimate_mandatory_commission_fee_usd_1d` | double | 估算强制性佣金（Mandatory Commission Fee）总额，单位 USD |
| `estimate_local_c2c_mandatory_commission_fee_usd_1d` | double | 估算本地 C2C 模式下的强制性佣金，单位 USD |
| `estimate_local_mall_mandatory_commission_fee_usd_1d` | double | 估算本地 Mall 模式下的强制性佣金，单位 USD |
| `estimate_cb_mandatory_commission_fee_usd_1d` | double | 估算跨境（Cross-Border）模式下的强制性佣金，单位 USD |
| `estimate_optional_commission_fee_usd_1d` | double | 估算可选性佣金（Optional Commission Fee）总额，单位 USD |
| `estimate_local_c2c_optional_commission_fee_usd_1d` | double | 估算本地 C2C 模式下的可选性佣金，单位 USD |
| `estimate_local_mall_optional_commission_fee_usd_1d` | double | 估算本地 Mall 模式下的可选性佣金，单位 USD |
| `estimate_cb_optional_commission_fee_usd_1d` | double | 估算跨境模式下的可选性佣金，单位 USD |
| `estimate_handling_fee_usd_1d` | double | 估算手续费（Handling Fee）总额，单位 USD |
| `estimate_seller_handling_fee_usd_1d` | double | 估算卖家侧手续费，单位 USD |
| `estimate_buyer_handling_fee_usd_1d` | double | 估算买家侧手续费，单位 USD |
| `gross_transaction_fee_usd_1d` | double | 毛交易手续费，单位 USD；来源于平台大盘用户 PC2 表（`dws_user_pc2_1d`），仅在 `scenario_tag = 'Platform'` 的行上有实际关联值，其余场景行可能为 NULL ⚠️ 仅对 `scenario_tag = 'Platform'` 行有效，其他场景行不可直接使用 |

---

### 指标：促销补贴明细

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `estimate_promotion_excl_3pl_usd_1d` | double | 估算促销费用（不含第三方物流，3PL），单位 USD |
| `estimate_logst_prm_usd_1d` | double | 估算物流补贴（Logistics Promotion）金额，单位 USD |
| `estimate_item_card_prm_usd_1d` | double | 估算商品卡片促销（Item Card Promotion）金额，单位 USD |
| `estimate_voucher_prm_usd_1d` | double | 估算优惠券促销（Voucher Promotion）金额，单位 USD |
| `estimate_coin_prm_usd_1d` | double | 估算金币促销（Coin Promotion）金额，单位 USD |

---

### 指标：PC2 利润

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `proxy_pc2_usd_1d` | double | 代理 PC2（Proxy PC2），单位 USD；基于可用估算字段合成的 PC2 近似值 |
| `adjusted_proxy_pc2_usd_1d` | double | 调整后的 Proxy PC2，单位 USD；在 proxy_pc2 基础上做口径修正后的值 |
| `adjusted_proxy_pc2_exp_usd_1d` | double | 实验维度的调整后 Proxy PC2，单位 USD；专为实验分析设计的 PC2 口径，与 `adjusted_proxy_pc2_usd_1d` 口径可能存在差异 ⚠️ 请与数据负责人确认该字段与 `adjusted_proxy_pc2_usd_1d` 的口径差异后使用 |
| `local_pc2_usd_1d` | double | 本地口径 PC2，单位 USD；来源于平台大盘用户 PC2 表（`dws_user_pc2_1d`），仅对 `scenario_tag = 'Platform'` 行通过用户维度关联填充，其余场景行为 NULL ⚠️ 仅对 `scenario_tag = 'Platform'` 行有效，其他场景行值为 NULL，不可直接 SUM 混用 |
| `estimate_3pl_margin_usd_1d` | double | 估算第三方物流（3PL）毛利，单位 USD；来源于平台大盘用户 PC2 表，仅对 `scenario_tag = 'Platform'` 行有效 ⚠️ 仅对 `scenario_tag = 'Platform'` 行有效 |
| `rsf_and_rts_usd_1d` | double | RSF（Revenue Share Fee）与 RTS（Return to Seller）合计，单位 USD；来源于平台大盘用户 PC2 表，仅对 `scenario_tag = 'Platform'` 行有效 ⚠️ 仅对 `scenario_tag = 'Platform'` 行有效 |
| `true_pc2_usd_1d` | double | True PC2，单位 USD；来源于平台大盘用户 PC2 表，为最终完整口径 PC2，仅对 `scenario_tag = 'Platform'` 行有效 ⚠️ 仅对 `scenario_tag = 'Platform'` 行有效，不可与其他场景的 PC2 字段混合 SUM |
| `other_revenue_usd_1d` | double | 其他收入，单位 USD；来源于平台大盘用户 PC2 表，仅对 `scenario_tag = 'Platform'` 行有效 ⚠️ 仅对 `scenario_tag = 'Platform'` 行有效 |

---

### 指标：Paid Ads 广告收益

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `paid_ads_revenue_usd_1d` | double | Paid Ads 广告收入（含所有口径），单位 USD |
| `paid_ads_broad_gmv_usd_1d` | double | Paid Ads 宽口径 GMV（Broad GMV，包含归因窗口内的所有相关成交），单位 USD |
| `paid_ads_voucher_ads_part_amt_usd_1d` | double | Paid Ads 中券（Voucher Ads）部分的金额，单位 USD |
| `paid_ads_net_revenue_usd_1d` | double | Paid Ads 净广告收入（扣除相关成本/补贴后），单位 USD |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区过滤（必须指定，避免全表扫描）**
   - 必须同时指定 `grass_region` 和 `grass_date`（或日期范围）：
     ```sql
     WHERE grass_region = 'MY'
       AND grass_date = '2026-04-21'
     ```
   - 若遗漏分区过滤，将触发全地区、全历史数据扫描，导致查询超时或产生极高计算成本。

2. **场景口径过滤（强烈建议）**
   - 查询前必须明确所需的 `scenario_tag`，不同场景间存在重叠（同一用户、同一天的数据会同时出现在多个 Unify 场景和原子场景中）：
     ```sql
     AND scenario_tag = 'RCMD Unify'  -- 根据实际分析口径选择
     ```
   - **跨 scenario_tag 的 SUM 会导致重复计算**，请勿在不过滤 `scenario_tag` 的情况下直接聚合指标字段。

3. **实验分组过滤（按需）**
   - 实验分析时需按 `exp_group_id` 和 `domain` 分组或过滤：
     ```sql
     AND domain = 'RCMD_Ads'
     GROUP BY exp_group_id
     ```

---

### 不可直接 SUM 的字段

以下字段存在使用限制，不可无条件直接 SUM：

| 字段名 | 问题原因 | 正确用法 |
|--------|----------|----------|
| `local_pc2_usd_1d`、`true_pc2_usd_1d`、`estimate_3pl_margin_usd_1d`、`rsf_and_rts_usd_1d`、`gross_transaction_fee_usd_1d`、`other_revenue_usd_1d` | 仅对 `scenario_tag = 'Platform'` 的行通过用户维度 LEFT JOIN 填充，其余场景行为 NULL | 使用前先过滤 `scenario_tag = 'Platform'`，或使用 `SUM(CASE WHEN scenario_tag = 'Platform' THEN field END)` |
| `adjusted_proxy_pc2_exp_usd_1d` | 专为实验口径设计，与 `adjusted_proxy_pc2_usd_1d` 口径存在差异，二者不可混加 | 明确口径后单独使用，不可与 `adjusted_proxy_pc2_usd_1d` 相加 |
| 所有 `estimate_*` 字段 | 均为估算值，非精确财务数据，同一用户在多个 `scenario_tag` 下会重复出现 | 必须在单一 `scenario_tag` 口径下聚合，不可跨场景 SUM |

---

### 时效性说明

- 本表每日 T+1 更新，`grass_date_7day` 至 `grass_date` 的 7 日滚动窗口数据每次全量覆盖写入（`INSERT OVERWRITE`）。
- 查询最新数据时，应取 **T-1 分区**（即昨日 `grass_date`）；当天（T+0）分区数据可能不存在或不完整。
- 本表存储的是 **每日（1d）** 粒度的绝对值指标（非累计），`_1d` 后缀表示当日数据，可直接在 `grass_date` 维度上 SUM 汇总多日。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live` | 主要事实数据来源，提供各推荐/广告场景下用户-商品粒度的 GMV、MP Revenue、佣金、促销、Paid Ads 及 Proxy PC2 等指标；按 `scenario_tag` 逻辑组合出 Cart Unify、RCMD Unify、Search_RCMD、DD_PP Unify 等多口径聚合 |
| `mp_paidads.dws_user_pc2_1d__reg_s0_live` | 平台大盘用户 PC2 数据来源，通过用户维度 LEFT JOIN 补充 `local_pc2_usd_1d`、`true_pc2_usd_1d`、`estimate_3pl_margin_usd_1d`、`rsf_and_rts_usd_1d`、`gross_transaction_fee_usd_1d`、`other_revenue_usd_1d` 等字段，仅对 `scenario_tag = 'Platform'` 生效 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验平台用户分组维表，提供用户-实验组（`exp_group_id`）及实验域（`domain`）的映射关系；分 RCMD_Ads（推荐广告白名单）和 Search（搜索白名单）两个维度筛选 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dim_sr_data_warehouse_abtest_user_group
  (is_rcmd_whitelist=1 → domain='RCMD_Ads')
  (is_search_whitelist=1 → domain='Search')
          │
          ▼
    [CTE: abtest_user_group]
    user_id + exp_group_id + domain + grass_date
          │
          │                    mp_paidads.dws_common_feature_user_item_pc2_1d
          │                    (tz_type='local', 7日滚动窗口)
          │                    ├── 原子场景: 各 common_feature 原始值（含名称重映射）
          │                    ├── Cart Unify: Cart Rec + Order Success + ODP YMAL + ...
          │                    ├── RCMD Unify: Cart Unify + You May Also Like + Daily Discover
          │                    ├── Search_RCMD: RCMD Unify + Global Search
          │                    └── DD_PP Unify: Cart Unify + Daily Discover
          │                          │
          │                          ▼
          │                  [CTE: common_feature_user_item_pc2]
          │                  按 scenario_tag + user_id + grass_date SUM 聚合
          │                  (UNION ALL 多口径，user_id 粒度)
          │                          │
          │          mp_paidads.dws_user_pc2_1d (tz_type='local', 7日滚动窗口)
          │                          │  LEFT JOIN on user_id + grass_date
          │                          │  (仅 scenario_tag='Platform' 场景生效)
          │                          ▼
          └──────────── JOIN (user_id + grass_date 维度) ──────────────┐
                                                                        ▼
                                    ads_new_pc2_rate_exp_1d__reg_s0_live
                                    按 scenario_tag + exp_group_id + domain + grass_date
                                    最终 SUM 聚合写入（INSERT OVERWRITE，按地区+日期分区）
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `abtest_user_group` | `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 从实验平台提取用户-实验组映射，分 `RCMD_Ads` 和 `Search` 两个域，取 7 日滚动窗口数据，用于最终与用户指标 JOIN |
| `common_feature_user_item_pc2` | `mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live` | 通过 UNION ALL 将上游用户-商品粒度数据展开为多个 `scenario_tag` 口径（原子场景 + 4 种 Unify 聚合口径），并按 `scenario_tag + user_id + grass_date` 聚合为用户粒度 |

---

### 注意事项

1. **场景重叠与重复计数风险**：`common_feature_user_item_pc2` CTE 通过 UNION ALL 构造多个 `scenario_tag`，同一用户同一天的数据会同时出现在原子场景和多个 Unify 口径中。最终表中**不同 `scenario_tag` 的行不可跨行 SUM**，否则会导致指标被重复累加。

2. **平台大盘字段仅对 `scenario_tag = 'Platform'` 有效**：`local_pc2_usd_1d`、`true_pc2_usd_1d`、`estimate_3pl_margin_usd_1d`、`rsf_and_rts_usd_1d`、`gross_transaction_fee_usd_1d`、`other_revenue_usd_1d` 这 6 个字段来源于 `dws_user_pc2_1d`，通过 `LEFT JOIN ... AND a.scenario_tag = 'Platform'` 条件关联，**非 Platform 场景行中这些字段值均为 NULL**。

3. **7 日滚动窗口覆盖写入**：ETL 每次调度处理 `grass_date_7day` 至 `grass_date` 共 7 天数据并执行 `INSERT OVERWRITE`，因此历史分区数据会被周期性刷新，下游不应依赖历史分区的不变性。

4. **A/B 实验用户取交集**：最终写入数据通过 `JOIN abtest_user_group` 实现，仅保留**在实验白名单中**的用户（RCMD_Ads 域要求 `is_rcmd_whitelist=1`，Search 域要求 `is_search_whitelist=1`，且 `user_id > 0`），非实验用户的指标不会出现在本表中。

5. **场景名称重映射**：ETL 中对部分 `common_feature` 值做了名称标准化处理，如 `'Order Detail Page Recommendation'` → `'Order Detail Page YMAL'`，`'Shipping Info Page YMAL'` → `'SIP YMAL'`，使用 `scenario_tag` 过滤时需注意使用重映射后的名称。

6. **tz_type 过滤**：上游表均过滤 `tz_type = 'local'`，本表数据统一使用各地区本地时区口径，不包含 UTC 口径数据。

---

*文档生成时间：2026-04-22*