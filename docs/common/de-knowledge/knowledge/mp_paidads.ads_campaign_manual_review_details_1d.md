<!-- ads-workspace-gdoc-sync: gdoc_id=1aGtr1TwpZ4AS1vYz8ygAwTbdO956jUykRjn4m8ooykA gdoc_url=https://docs.google.com/document/d/1aGtr1TwpZ4AS1vYz8ygAwTbdO956jUykRjn4m8ooykA/edit -->

# mp_paidads.ads_campaign_manual_review_details_1d

**分层**：ADS（应用数据服务层）
**主键**：`shop_id` + `campaign_id` + `rebate_generated_date` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日全量覆写（按地区参数化调度）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表记录广告活动（Campaign）维度的返佣人工审核明细，面向付费广告返佣核算场景。每行表示某个广告活动在某一返佣生成日期的完整核算记录，涵盖返佣状态、人工审核标记、宽口径 GMV/消耗金额、预期返佣与最终返佣等核心指标，是追踪返佣全链路（从自动计算到人工复核再到最终落地）的主要数据源。

本表的核心使用场景包括：① 返佣审核运营——筛选经历人工审核的广告活动，分析审核通过率与审核原因分布；② 返佣核对与对账——对比 `original_rebate_amt`（原始返佣）、`expected_rebate_amt`（预期返佣）与 `final_rebate_amt`（最终返佣）三层金额，识别经过人工干预的差异；③ ROI 分析与平台大盘——结合消耗、GMV、ADVV 及 ROI 比率，评估广告主投放效益与返佣合理性。

各地区按本地时区参数化调度，覆盖所有已上线地区，每日更新一次，数据以"返佣记录最后修改日期"（`mtime`）为过滤口径，确保每日刷新可及时捕获返佣状态变更。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型标识，固定写入值为 `'local'`，表示按各地区本地时区统计。⚠️ 查询时必须指定 `tz_type = 'local'` 以避免全表扫描 |
| `grass_region` | string | 地区编码（大写），如 `'MY'`、`'TH'`，由调度参数 `${region}` 注入。⚠️ 查询时应指定具体地区，避免跨地区混算 |
| `grass_date` | date | 数据日期（本地时区），表示本行数据的统计基准日，即返佣记录 `mtime` 对应的业务日期 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，标识广告主所属店铺 |
| `campaign_id` | bigint | 广告活动 ID，标识具体广告计划 |
| `rebate_generated_date` | string | 返佣生成日期（格式 `yyyy-MM-dd`），来源于返佣记录的 `log_date` 字段，表示该条返佣记录实际产生的日期，可能早于 `grass_date` |

---

### 维度：返佣审核状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_manual_review` | tinyint | 是否经历人工审核，`1` = 是，`0` = 否；来源于返佣记录扩展信息中的 `had_manual_review` 字段 |
| `no_rebate_type` | int | 不参与返佣的原因类型编码，对应平台定义的无返佣枚举值；仅在无返佣场景下有意义，其他场景为 NULL 或 0 |
| `final_rebate_status` | int | 最终返佣状态编码（来源字段 `rebate_history_status`），反映当前返佣流程所处阶段（如待审核、已通过、已拒绝等） |

---

### 指标：返佣金额

| 字段 | 类型 | 说明 |
|------|------|------|
| `original_rebate_amt` | bigint | 原始返佣金额（本地货币），计算口径为 `expenditure - advv / 0.9`，单位：本地货币 × 10⁵。⚠️ 存储已放大 10⁵ 倍，展示或计算时需除以 100000 |
| `original_rebate_amt_usd` | double | 原始返佣金额（美元），由自动返佣明细表直接继承 |
| `expected_rebate_amt` | bigint | 预期返佣金额（本地货币），单位：本地货币 × 10⁵。⚠️ 存储已放大 10⁵ 倍 |
| `expected_rebate_amt_usd` | double | 预期返佣金额（美元） |
| `final_rebate_amt` | bigint | 最终返佣金额（本地货币），经人工审核或系统最终确认后的落地金额，单位：本地货币 × 10⁵。⚠️ 存储已放大 10⁵ 倍；USD 转换由 ETL 实时计算：`final_rebate_amt / (100000.0 × exchange_rate)` |
| `final_rebate_amt_usd` | double | 最终返佣金额（美元），由 ETL 通过当日汇率实时换算得出。⚠️ 换算依赖 `grass_date` 当日汇率，历史分区数据的汇率已固化，不随汇率变动更新 |
| `region_expected_rebate_amt_usd` | double | 地区层级汇总的预期返佣金额（美元），为地区维度的预计算聚合值。⚠️ 为预计算聚合指标，不可与 campaign 级别的 `expected_rebate_amt_usd` 直接叠加求和 |

---

### 指标：广告消耗与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `expenditure_amt` | bigint | 广告消耗金额（本地货币），单位：本地货币 × 10⁵。⚠️ 存储已放大 10⁵ 倍 |
| `expenditure_amt_usd` | double | 广告消耗金额（美元） |
| `advv_amt` | bigint | 广告带来的商品价值（Ads-Driven Value，ADVV），本地货币，单位：本地货币 × 10⁵。⚠️ 存储已放大 10⁵ 倍 |
| `advv_amt_usd` | double | ADVV 金额（美元） |
| `broad_gmv_amt` | bigint | 宽口径 GMV（本地货币），包含广告归因窗口内的更广范围成交额，单位：本地货币 × 10⁵。⚠️ 存储已放大 10⁵ 倍 |
| `broad_gmv_amt_usd` | double | 宽口径 GMV（美元） |
| `broad_order_cnt` | bigint | 宽口径订单数，与 `broad_gmv_amt` 口径一致 |

---

### 指标：ROI 与平台大盘

| 字段 | 类型 | 说明 |
|------|------|------|
| `roi_ratio` | double | ROI 比率，来源于自动返佣明细表的预计算值。⚠️ 为预计算比率，不可直接 SUM，如需汇总 ROI 应使用 `advv_amt_usd / expenditure_amt_usd` 重新计算 |
| `target_roi2_region_net_ads_expenditure_amt_usd` | double | 地区目标 ROI2 对应的净广告消耗金额（美元），为平台大盘层级的预计算参考值。⚠️ 为地区级预计算聚合指标，不代表单条 campaign 的净消耗，不可直接 SUM |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，导致资源浪费和查询超时：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 无其他 tz_type 值，但省略仍会扫描分区元数据，且结构不稳定时存在风险 |
| `grass_region` | `grass_region = 'MY'`（按需指定） | 全地区扫描，数据量成倍增加，且不同地区汇率与货币单位不同，混合后指标无意义 |
| `grass_date` | `grass_date = '2026-04-21'` 或指定日期范围 | 扫描所有历史分区，严重影响查询性能 |

> 推荐过滤写法示例：
> ```sql
> WHERE tz_type = 'local'
>   AND grass_region = 'MY'
>   AND grass_date = '2026-04-21'
> ```

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确计算方式 |
|------|------|-------------|
| `roi_ratio` | 预计算比率，直接 SUM 无意义 | 汇总后使用 `SUM(advv_amt_usd) / NULLIF(SUM(expenditure_amt_usd), 0)` 重新计算 |
| `region_expected_rebate_amt_usd` | 地区级预计算聚合值，与 campaign 行并存时会重复计数 | 仅取地区维度单行使用，不与 campaign 级明细混合聚合 |
| `target_roi2_region_net_ads_expenditure_amt_usd` | 地区级预计算聚合值，同上 | 同上，勿对多行 SUM |
| `final_rebate_amt` / `broad_gmv_amt` 等 bigint 本地货币字段 | 数值已放大 10⁵ 倍 | 展示时需 `/ 100000.0`；跨地区汇总需先换算为 USD |
| `final_rebate_amt_usd` | 汇率已按写入日 `grass_date` 固化 | 跨日期范围汇总时注意汇率差异，不建议直接跨多个 `grass_date` SUM |

### 时效性说明

- 本表以返佣记录的 **`mtime`（最后修改时间）** 作为分区写入依据，而非返佣的业务发生日。`rebate_generated_date` 可能早于 `grass_date`，即历史返佣记录若发生状态变更，将在变更当日的 `grass_date` 分区中更新。
- 查询**当前最新返佣状态**时，应取**最近一个已完成调度的 `grass_date`** 分区，并按 `campaign_id` + `rebate_generated_date` 去重（取最大 `grass_date` 对应行）。
- 若需分析某一返佣生成日的返佣情况，应使用 `rebate_generated_date` 过滤，而非 `grass_date`。
- ETL 在 `grass_date` 当天拉取最近 10 天（`grass_date - 10` 至 `grass_date`）的自动返佣明细进行 JOIN，因此 `auto_rebate_detail` 的关联存在 **10 天回溯窗口**，返佣生成日期超出此窗口的记录将无法匹配消耗/GMV 指标（指标字段为 NULL）。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_rebate_${region}_db__campaign_rebate_history_tab__reg_continuous_s0_live` | 返佣历史记录源表，提供返佣状态、金额、人工审核标记等维度字段 |
| `mp_paidads.ads_campaign_auto_rebate_details_1d__reg_s0_live` | 自动返佣计算明细表，提供 GMV、消耗、ADVV、ROI、预期返佣等指标字段 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供当日地区汇率，用于本地货币 → USD 的换算（仅用于 `final_rebate_amt_usd` 的实时计算） |

---

## ETL 逻辑摘要

### 数据流

```
campaign_rebate_history_tab（返佣历史）
  [按 mtime = grass_date 过滤当日变更记录]
              │
              │  CTE: manual_review
              │  (shop_id, campaign_id, rebate_generated_date,
              │   final_rebate_status, final_rebate_amt,
              │   is_manual_review, no_rebate_type)
              │
              ▼
     LEFT JOIN  ◄─────────────────────────────────────────────────────┐
              │                                                        │
              │                        ads_campaign_auto_rebate_details_1d
              │                          [grass_date 在回溯10天窗口内]
              │                                CTE: auto_rebate_detail
              │                          (campaign_id, gmv, expenditure,
              │                           advv, roi_ratio, rebate 金额等)
              │
              ▼
     LEFT JOIN  ◄──────────────────────────────────────────────────────┐
              │                                                         │
              │                              dim_exchange_rate
              │                          [grass_date 当日 + grass_region]
              │                                CTE: rate
              │                             (grass_region, exchange_rate)
              │
              ▼
  INSERT OVERWRITE
  ads_campaign_manual_review_details_1d__reg_s0_live
  PARTITION (tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `manual_review` | `shopee_ads_rebate_${region}_db__campaign_rebate_history_tab__reg_continuous_s0_live` | 按 `mtime = grass_date` 筛选当日有变更的返佣记录，解析 `_decoded_extinfo` JSON 提取人工审核标记与无返佣类型，并将 `log_date` 转换为 `rebate_generated_date` |
| `auto_rebate_detail` | `mp_paidads.ads_campaign_auto_rebate_details_1d__reg_s0_live` | 拉取近 10 天内（含当日）的自动返佣计算结果，提供 GMV、消耗、ADVV、ROI、预期返佣等指标，以 `campaign_id + grass_date` 与返佣记录关联 |
| `rate` | `mp_order.dim_exchange_rate__reg_s0_live` | 获取当日地区汇率，用于将 `final_rebate_amt` 换算为 USD |

### 注意事项

1. **JOIN 逻辑均为 LEFT JOIN**：`manual_review` 为驱动表，自动返佣明细和汇率均为左连接，因此当 `auto_rebate_detail` 中无匹配记录时（如返佣生成日超出 10 天窗口），消耗/GMV/ROI 等字段将为 NULL，`final_rebate_amt_usd` 同样为 NULL（汇率缺失导致）。

2. **10 天回溯窗口限制**：`auto_rebate_detail` 仅取 `grass_date - 10` 至 `grass_date` 范围内的数据。若 `rebate_generated_date` 早于此窗口（如历史补录场景），该行的绩效指标字段将全部为 NULL，需特别注意。

3. **金额字段放大 10⁵ 倍**：所有 bigint 本地货币字段（`final_rebate_amt`、`broad_gmv_amt`、`expenditure_amt`、`advv_amt`、`original_rebate_amt`、`expected_rebate_amt`）均已乘以 10⁵ 存储，与平台下游系统对接规范一致，使用时务必除以 100000。

4. **`final_rebate_amt_usd` 汇率固化**：该字段在 ETL 写入时按 `grass_date` 当日汇率实时换算并固化存储，后续汇率波动不会更新历史分区。跨日期范围对比 USD 金额时应注意汇率口径差异。

5. **`rebate_generated_date` vs `grass_date`**：两者含义不同，前者是返佣计划产生的业务日期，后者是本行数据被写入的日期。一条返佣记录可能因状态更新而在多个 `grass_date` 分区中出现（每次 INSERT OVERWRITE 覆盖当日分区），使用时需明确分析目的后选择合适的日期字段。

6. **参数化多地区调度**：ETL SQL 中的 `${region}`、`${timezone}`、`${grass_date}` 均为调度模板变量，各地区独立调度，写入各自的 `grass_region` 分区，本表覆盖所有已配置地区。

---

*文档生成时间：2026-04-22*