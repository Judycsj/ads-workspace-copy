<!-- ads-workspace-gdoc-sync: gdoc_id=1bgEW50tWhoPnFvCv6D7LCF_rvUpF4sHIv_SGVmFl-YE gdoc_url=https://docs.google.com/document/d/1bgEW50tWhoPnFvCv6D7LCF_rvUpF4sHIv_SGVmFl-YE/edit -->

# mp_paidads.ads_campaign_auto_rebate_details_1d

**分层**：ADS（应用数据服务层）
**主键**：`campaign_id` + `item_id` + `shop_id` + `grass_region` + `grass_date` + `tz_type`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表记录广告平台（Paid Ads）中 ROI 目标型广告（Target ROI2，pricing_type=11/24/25，placement=40）的**每日自动返佣（Auto Rebate）明细数据**，以广告系列（Campaign）维度汇聚广告绩效与返佣计算结果，支撑广告运营团队对自动返佣策略的监控、核查与下游结算流程。

表中涵盖广告消耗、宽口径 GMV、广告价值量（ADVV）、实际应退佣金额及其上限约束后的预期退佣金额等核心指标，同时记录欺诈标记、申诉状态、无需返佣原因等风控属性。通过对白名单商家（ROI2 白名单、GMS 白名单、MPD 白名单）过滤及上限控制（`rebate_amt_cap`、`manual_review_threshold`），确保返佣计算口径与业务规则一致。

该表同时提供"含结算周期（paid）"与"全量宽口径（broad）"两套指标，帮助团队区分已支付口径与全量口径的差异，为返佣争议处理、人工审核触发及大盘收益分析提供数据依据。各地区按本地时区参数化调度，覆盖所有运营地区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，固定写入值为 `'local'`（按各地区本地时区统计）。查询时**必须**指定此分区字段以避免全表扫描 |
| `grass_region` | string | 大写地区代码，如 `'MX'`、`'TH'` 等，与调度参数 `${region}` 对应 |
| `grass_date` | date | 数据日期（本地时区），格式 `YYYY-MM-DD` |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID；对于 GMS（pricing_type=24）/MPD（pricing_type=25）类型的广告系列，该字段为 NULL |
| `campaign_id` | bigint | 广告系列 ID |
| `pricing_type` | int | 广告计价类型：11=ROI Target（ROI2 shop 级），24=GMS Target，25=MPD Target |

---

### 维度：返佣状态与风控标记

| 字段 | 类型 | 说明 |
|------|------|------|
| `auto_rebate_status` | string | 自动返佣状态，当前版本 ETL 写入 NULL，由下游或其他流程回填 |
| `no_rebate_needed_type` | int | 无需返佣的原因类型。**1**=订单数不足（pricing_type=11 时 broad_order_cnt<5；pricing_type=24 时<10；pricing_type=25 时<5），**2**=广告消耗为零或 ADVV 比率≥1（即 ROI 已达标无需补贴），NULL=需要返佣 |
| `is_need_manual_review` | tinyint | 是否需要人工审核；当地区级预期退佣总额超过地区净广告收入的 `manual_review_threshold` 倍时置 1，否则置 0 |
| `fraud_tag` | tinyint | 欺诈标记，当前版本 ETL 写入 NULL，由下游风控流程回填 |
| `if_has_seller_negative_behavior` | tinyint | 是否存在卖家负面行为，当前版本 ETL 写入 NULL，由下游流程回填 |
| `if_appeal_success` | tinyint | 最近一次申诉是否成功（1=成功，0=失败），当前版本 ETL 写入 NULL，由下游流程回填 |
| `last_appeal_date` | string | 最近一次申诉日期，当前版本 ETL 写入 NULL，由下游流程回填 |
| `last_fraud_date` | string | 最近一次欺诈判定日期，当前版本 ETL 写入 NULL，由下游流程回填 |
| `fraud_explanation` | string | 欺诈说明文字，当前版本 ETL 写入 NULL，由下游流程回填 |
| `fraud_effect_start_time` | string | 欺诈生效开始时间，当前版本 ETL 写入 NULL，由下游流程回填 |
| `fraud_effect_end_time` | string | 欺诈生效结束时间，当前版本 ETL 写入 NULL，由下游流程回填 |
| `invalid_reason` | array\<int\> | 无效原因码列表，当前版本 ETL 写入 NULL，由下游流程回填 |

---

### 指标：宽口径广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order_cnt` | bigint | 宽口径订单数（仅统计 broad_gmv>0 的订单） |
| `broad_gmv_amt` | bigint | 宽口径 GMV，**本地货币，已乘以 10^5 存储**。⚠️ 读取时需除以 100,000 还原为实际金额，不可与未放大字段直接混用 |
| `broad_gmv_usd` | double | 宽口径 GMV（美元） |
| `expenditure_amt` | bigint | 广告消耗额，**本地货币，已乘以 10^5 存储**。⚠️ 读取时需除以 100,000 还原为实际金额 |
| `expenditure_amt_usd` | double | 广告消耗额（美元） |
| `advv_amt` | bigint | 广告价值量（ADVV = broad_gmv × target_cir），**本地货币，已乘以 10^5 存储**。⚠️ 读取时需除以 100,000 还原为实际金额 |
| `advv_amt_usd` | double | 广告价值量（美元） |
| `advv_with_rapid_amt_local` | bigint | 含急速提升（rapid boost）/Campaign Surge 加成的 ADVV，**本地货币，已乘以 10^5 存储**。⚠️ 读取时需除以 100,000 还原为实际金额；rapid/surge 场景下不除以 0.9，非 rapid 场景下除以 0.9 |
| `advv_with_rapid_amt_usd` | double | 含 rapid/surge 加成的 ADVV（美元） |
| `roi_ratio` | double | ROI 比率 = advv / expenditure（本地货币口径），保留两位小数。⚠️ 为预计算比率，不可直接 SUM，跨 campaign 汇总需用 `SUM(advv_amt)/SUM(expenditure_amt)` 重新计算 |

---

### 指标：宽口径返佣金额

| 字段 | 类型 | 说明 |
|------|------|------|
| `original_rebate_amt` | bigint | 原始应退佣金额 = expenditure - advv_with_rapid（本地货币，**已乘以 10^5 存储**）。⚠️ 读取时需除以 100,000；此字段不受订单数门槛和上限约束，表示理论应退总额 |
| `original_rebate_usd` | double | 原始应退佣金额（美元），未受上限约束 |
| `expected_rebate_amt` | bigint | 预期实际退佣金额（本地货币，**已乘以 10^5 存储**）：在满足订单数门槛、ROI 未达标的前提下，取 `min(original_rebate, expenditure × rebate_amt_cap)` 上限约束后的结果。⚠️ 读取时需除以 100,000 |
| `expected_rebate_usd` | double | 预期实际退佣金额（美元），已施加上限约束 |
| `region_expected_rebate_amt_usd` | double | 地区级预期退佣总额（美元），为该地区所有 campaign 的 `expected_rebate_amt_usd` 之和（地区粒度汇总值，每条记录值相同）。⚠️ 不可对本字段 SUM 聚合，否则会重复计数；需直接取任意一行值或与地区维度关联使用 |

---

### 指标：大盘基准

| 字段 | 类型 | 说明 |
|------|------|------|
| `target_roi2_region_net_ads_expenditure_amt_usd` | double | 地区级净广告收入（美元），来源于 `dws_advertise_net_ads_revenue_1d`，用于与 `region_expected_rebate_amt_usd` 比较以判断是否触发人工审核阈值（地区粒度汇总值，每条记录值相同）。⚠️ 不可对本字段 SUM 聚合，同地区多行值相同，汇总会重复计数 |

---

### 指标：已结算（paid）口径广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_broad_order_cnt` | bigint | 已结算宽口径订单数（仅统计 paid_broad_gmv>0 的订单） |
| `paid_broad_order_gmv_local` | bigint | 已结算宽口径 GMV（本地货币，**已乘以 10^5 存储**）。⚠️ 读取时需除以 100,000 |
| `paid_broad_order_gmv_usd` | double | 已结算宽口径 GMV（美元） |
| `paid_advv_amt_local` | bigint | 已结算口径 ADVV（本地货币，**已乘以 10^5 存储**）。⚠️ 读取时需除以 100,000 |
| `paid_advv_amt_usd` | double | 已结算口径 ADVV（美元） |
| `paid_advv_with_rapid_amt_local` | bigint | 已结算口径含 rapid/surge 加成的 ADVV（本地货币，**已乘以 10^5 存储**）。⚠️ 读取时需除以 100,000 |
| `paid_advv_with_rapid_amt_usd` | double | 已结算口径含 rapid/surge 加成的 ADVV（美元） |
| `paid_roi_ratio` | double | 已结算口径 ROI 比率 = paid_advv / expenditure（本地货币口径），保留两位小数。⚠️ 为预计算比率，不可直接 SUM，跨 campaign 汇总需用分子/分母重新计算 |

---

### 指标：已结算（paid）口径返佣金额

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_original_rebate_amt` | bigint | 已结算口径原始应退佣金额（本地货币，**已乘以 10^5 存储**）= expenditure - paid_advv_with_rapid。⚠️ 读取时需除以 100,000 |
| `paid_original_rebate_usd` | double | 已结算口径原始应退佣金额（美元） |
| `paid_expected_rebate_amt` | bigint | 已结算口径预期实际退佣金额（本地货币，**已乘以 10^5 存储**），已施加上限约束。⚠️ 读取时需除以 100,000 |
| `paid_expected_rebate_usd` | double | 已结算口径预期实际退佣金额（美元），已施加上限约束 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，避免全表扫描造成性能问题与多倍计数：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | ETL 仅写入 `local` 分区，缺失此条件将导致逻辑等价的全分区扫描 |
| `grass_region` | `grass_region = 'XX'`（大写地区码） | 缺失将跨地区混合计算，金额汇总结果无意义 |
| `grass_date` | `grass_date = '2024-01-01'` | 缺失将跨多日累计，导致数据膨胀 |

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确计算方式 |
|------|------|-------------|
| `roi_ratio` | 预计算比率（`ROUND(advv/expenditure, 2)`），SUM 无业务意义 | `SUM(advv_amt) / SUM(expenditure_amt)`（注意单位还原） |
| `paid_roi_ratio` | 同上，基于 paid 口径的预计算比率 | `SUM(paid_advv_amt_local) / SUM(expenditure_amt)`（注意单位还原） |
| `region_expected_rebate_amt_usd` | 地区级汇总值，每条 campaign 行均持有相同值，SUM 将重复计数 | 按 `grass_region` 取 `MAX()` 或 `ANY_VALUE()` 即可 |
| `target_roi2_region_net_ads_expenditure_amt_usd` | 地区级汇总值，每条 campaign 行均持有相同值，SUM 将重复计数 | 按 `grass_region` 取 `MAX()` 或 `ANY_VALUE()` 即可 |
| `broad_gmv_amt`、`expenditure_amt`、`advv_amt`、`advv_with_rapid_amt_local`、`original_rebate_amt`、`expected_rebate_amt`、`paid_broad_order_gmv_local`、`paid_advv_amt_local`、`paid_advv_with_rapid_amt_local`、`paid_original_rebate_amt`、`paid_expected_rebate_amt` | 存储格式为实际金额 × 10^5（bigint），直接 SUM 后需除以 100,000 还原，与 USD 字段（double 类型，未放大）混用时需注意单位对齐 | `SUM(字段) / 100000.0` 还原为本地货币实际值 |

### 时效性说明

- 本表为 **T+1** 日更新，每日凌晨完成前一自然日（本地时区）的数据写入。
- 查询最新数据时，应取 `grass_date = CURRENT_DATE - 1`（或已知的最新分区日期），避免读取到未完成写入的当日分区。
- `fraud_tag`、`auto_rebate_status`、`if_appeal_success` 等风控及申诉字段当前版本写入为 NULL，若下游有回填逻辑，应关注对应分区的数据版本。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertise__reg_s0_live` | 获取 Target ROI2（placement=40，pricing_type=11/24/25）的活跃 campaign 列表，以及前一日已删除 campaign 列表（用于排除） |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 提供 campaign 维度的广告消耗、宽口径 GMV、ADVV、paid 口径绩效等核心指标 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 提供合法广告主（shop）列表，用于构建 ROI2 返佣白名单 |
| `mp_paidads.dim_roi2_auto_rebate_blacklist__reg_s0_live` | ROI2 自动返佣黑名单，与广告主表做 LEFT JOIN 后排除黑名单商家 |
| `mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live` | GMS（type=1）和 MPD（type=2）自动返佣白名单，限定参与返佣计算的商家范围 |
| `mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live` | 提供地区级净广告收入，用于计算是否触发人工审核阈值 |
| `mp_paidads.dim_auto_rebate_cap__reg_s0_live` | 返佣上限配置（`rebate_amt_cap`）和人工审核触发比例（`manual_review_threshold`） |

---

## ETL 逻辑摘要

### 数据流

```
dim_advertise__reg_s0_live ──────────────────────────────────────┐
  (placement=40, pricing_type in 11/24/25, ads_status=1)         │
  (当日活跃 campaign + item_id)                                   ├──► [target2_campaign]
  (pricing_type in 24,25 时 item_id=NULL)                        │
                                                                  │
dwd_advertise_performance_di__reg_s0_live ──────────────────────►│
  (消耗/GMV/ADVV/paid 口径绩效，按 campaign 聚合)                 ├──► [ads_perf]
dim_advertise__reg_s0_live (补全 shop_id/pricing_type) ─────────►│
                                                                  │
dim_advertise__reg_s0_live ──────────────────────────────────────►[delete_campaign]
  (前一日 campaign_status in 0/7 的已删除 campaign)              │
                                                                  │
[target2_campaign] ─────────────────────────────────────────────►│
[ads_perf]          ──── FULL JOIN ─────────────────────────────►├──► [active_campaign]
[delete_campaign]   ──── LEFT JOIN 排除 ────────────────────────►│
                                                                  │
dim_advertiser__reg_s0_live ─────────────────────────────────────►│
dim_roi2_auto_rebate_blacklist__reg_s0_live (黑名单排除) ─────────►├──► [dim_whitelist_roi2]
                                                                  │
dim_gmsmpd_auto_rebate_whitelist__reg_s0_live (type=1) ──────────►[dim_whitelist_gms]
dim_gmsmpd_auto_rebate_whitelist__reg_s0_live (type=2) ──────────►[dim_whitelist_mpd]
                                                                  │
[dim_whitelist_roi2] JOIN [active_campaign] (pricing_type=11) ───►│
[dim_whitelist_mpd]  JOIN [active_campaign] (pricing_type=25) ───►├──► [auto_rebate]（UNION ALL，计算
[dim_whitelist_gms]  JOIN [active_campaign] (pricing_type=24) ───►│    no_rebate_needed_type/roi_ratio/
                                                                  │    original_rebate/expected_rebate 等）
dws_advertise_net_ads_revenue_1d__reg_s0_live ───────────────────►[net_rev]（地区净广告收入汇总）
[auto_rebate] ───────────────────────────────────────────────────►[total_rebate]（地区预期退佣汇总）
dim_auto_rebate_cap__reg_s0_live ────────────────────────────────►[cap]（上限配置）
                                                                  │
[auto_rebate] LEFT JOIN [total_rebate] LEFT JOIN [net_rev]        │
              LEFT JOIN [cap] ────────────────────────────────────►
                                                                  ▼
                               ads_campaign_auto_rebate_details_1d__reg_s0_live
                               (INSERT OVERWRITE, partition: tz_type='local'/grass_region/grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `target2_campaign` | `dim_advertise__reg_s0_live` | 获取当日活跃的 Target ROI2 campaign 列表（pricing_type=11 保留 item_id；24/25 置 NULL） |
| `ads_perf` | `dwd_advertise_performance_di__reg_s0_live`、`dim_advertise__reg_s0_live` | 按 campaign 聚合广告消耗、宽口径 GMV、ADVV（含 rapid）、paid 口径全套绩效指标 |
| `delete_campaign` | `dim_advertise__reg_s0_live` | 取前一日 campaign_status in (0,7) 的已删除/暂停 campaign，用于在 active_campaign 中排除 |
| `dim_whitelist_roi2` | `dim_advertiser__reg_s0_live`、`dim_roi2_auto_rebate_blacklist__reg_s0_live` | 构建 ROI2（pricing_type=11）可参与返佣的 shop 白名单（广告主全集减去黑名单） |
| `dim_whitelist_gms` | `dim_gmsmpd_auto_rebate_whitelist__reg_s0_live` | 构建 GMS（pricing_type=24，type=1）返佣白名单 |
| `dim_whitelist_mpd` | `dim_gmsmpd_auto_rebate_whitelist__reg_s0_live` | 构建 MPD（pricing_type=25，type=2）返佣白名单 |
| `active_campaign` | `target2_campaign`、`ads_perf`、`delete_campaign` | 合并活跃 campaign 信息与绩效数据，排除已删除 campaign，作为返佣计算的主体数据集 |
| `auto_rebate` | `active_campaign`、三个 whitelist CTE | 按 pricing_type 分支（11/24/25）计算 no_rebate_needed_type、roi_ratio、original_rebate、expected_rebate 等核心返佣字段；三路 UNION ALL 合并（缓存为 MEMORY_AND_DISK） |
| `net_rev` | `dws_advertise_net_ads_revenue_1d__reg_s0_live` | 汇总地区级净广告收入，用于人工审核阈值判断 |
| `total_rebate` | `auto_rebate` | 汇总地区级预期退佣总额（`region_expected_rebate_amt_usd`） |
| `cap` | `dim_auto_rebate_cap__reg_s0_live` | 读取各地区的返佣上限比例（`rebate_amt_cap`）和人工审核触发比例（`manual_review_threshold`） |

### 注意事项

1. **金额单位放大存储**：本地货币金额字段（bigint 类型）在写入时统一乘以 100,000（`round(金额 * 100000)`）存储，读取时需除以 100,000 还原。USD 字段（double 类型）未做放大处理，两类字段**不可直接做数值比较或混合聚合**。

2. **expected_rebate 已含上限约束**：`expected_rebate_amt` / `expected_rebate_usd` 的实际写入值为 `MIN(原始应退额, expenditure × rebate_amt_cap)`，即已经过上限裁剪，与 `original_rebate_amt` 存在差异，两者含义不同，不可互换。

3. **风控与申诉字段均为 NULL**：`fraud_tag`、`auto_rebate_status`、`if_appeal_success`、`last_appeal_date`、`last_fraud_date`、`fraud_explanation`、`fraud_effect_start_time`、`fraud_effect_end_time`、`invalid_reason` 等字段在当前 ETL 中全部写入 NULL，由下游系统或人工流程回填，查询时不可依赖这些字段做过滤。

4. **地区粒度汇总字段的重复计数风险**：`region_expected_rebate_amt_usd` 和 `target_roi2_region_net_ads_expenditure_amt_usd` 是地区级聚合值，在表中每条 campaign 行均重复存储相同值，聚合查询时须使用 `MAX()` / `ANY_VALUE()` 而非 `SUM()`。

5. **delete_campaign 使用前一日快照**：已删除 campaign 的判断逻辑基于 `grass_date - 1` 的快照（`campaign_status in (0,7)`），若某 campaign 在当日新增并当日删除，可能不会被排除，存在极少量边界场景数据。

6. **ROI2 白名单采用排除法**：`dim_whitelist_roi2` 的构建方式为"广告主全集 LEFT JOIN 黑名单，取黑名单为 NULL 的部分"，即默认所有广告主均可参与，仅排除明确列入黑名单的商家；GMS/MPD 白名单则采用正向包含法，仅白名单内商家可参与。

7. **rapid boost / Campaign Surge 对 ADVV 的影响**：`advv_with_rapid_amt` 系列字段在 rapid_boost 或 campaign_surge 开启时直接使用 `broad_gmv × target_cir`；未开启时则除以 0.9（即相当于折扣因子处理），该差异会影响 `original_rebate` 和 `expected_rebate` 的计算结果。

---

*文档生成时间：2026-04-22*