# 供给侧与激励侧归因补充

本补充用于增强 `ads-biz-diagnose` 在预算、余额、广告主规模、平台 GMV、投广渗透、激励任务影响等方向的异常归因能力。

## 触发场景

当大盘诊断命中以下信号时，必须进入本补充流程：

- OR7：Budget / 预算变化
- OR11：广告规模变化
- OR15：激励任务影响
- Platform GMV 异常，且广告侧没有同步变化
- Rev / Take Rate 异常且疑似由供给侧驱动
- Active advertiser / active ads / active campaign 下滑
- Hit budget rate / hit balance rate 异常
- GMS / Escrow / ABI / 其他激励任务可能影响预算或投放行为

## 数据来源

### 1. 大盘与供给侧主表

优先使用 `ads-biz-diagnose` 已有 ClickHouse 表，保证和大盘异常诊断口径一致。

| 诊断对象 | 表 | 关键字段 / 口径 | 用途 |
|---------|----|----------------|------|
| Rev / Take Rate / Platform GMV / Broad GMV | `mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live` | `net_ads_rev`, `revenue_usd`, `platform_gmv`, `broad_gmv_usd`, `advv_usd`; 固定 `entrance='ALL'`、`pricing_type='ALL'` 做总量 | O1-O7、rev/take_rate/GMV 主链路 |
| entrance / pricing type / seller_type 拆分 | `mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live` | `net_ads_rev_usd`, `ads_rev_usd`, `ads_gmv_usd`, `platform_gmv`, `traffic_type`, `pricing_type`, `seller_type`; 平台指标需去重 | OR12 / OR13 维度定位 |
| 预算、余额、active advertiser | `mkplpaidads_search_ads_ads_debug.overall_supply_budget_metrics_daily__reg_s0_live` | `daily_valid_budget`, `topup_amt_usd`, `account_balance_usd`, `active_ads_cnt`, `active_advertiser_cnt`; `pricing_type` / `budget_type` 含 `'all'` 预聚合行 | OR7 / OR11 基础供给归因 |

`overall_supply_budget_metrics_daily__reg_s0_live` 查询总量时必须使用：

```sql
WHERE pricing_type = 'all'
  AND budget_type = 'all'
```

按产品拆分时使用：

```sql
WHERE pricing_type != 'all'
  AND budget_type = 'all'
```

按 limited / unlimited 拆分时使用：

```sql
WHERE pricing_type = 'all'
  AND budget_type != 'all'
```

不要同时汇总 `'all'` 和具体值，否则会重复计算。

### 2. 供给侧细粒度补充表

当 `SUPPLY_BUDGET` 表无法解释到 campaign / shop / tier 粒度时，再使用以下 Hive 表补充。预算总量、limited / unlimited 拆分、budget usage 默认仍以 `SUPPLY_BUDGET` 为准；不要为追求 campaign 粒度而切换到未确认口径的预算字段。

| 诊断对象 | 表 | 关键字段 / 口径 | 用途 |
|---------|----|----------------|------|
| ads revenue / broad GMV / active ads item / active campaign / active seller / GMS running | `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | `ads_expenditure_amt_usd`, `net_ads_revenue_usd_1d`, `broad_order_gmv_amt_usd`, `is_ads_active`, `has_performance`, `pricing_type` | 产品 / pricing type / GMS adoption 及 active supply 拆分 |
| hit balance / balance / seller-day 状态 | `mp_paidads.ads_advertiser_mkt_1d__reg_s0_live` | `ads_expenditure_amt_usd_1d`, `total_eod_balance_usd_td`, `is_active_ads_seller`, `has_active_ads`, `is_auto_topup_enabled` | hit balance、余额不足、ATU 相关判断 |
| advertiser tier / seller 属性 | `mp_paidads.ads_advertiser_seller_all_metrics_1d__reg_s0_live` | `advertiser_tier` 等 seller-day 属性 | large / medium / small / micro advertiser 下钻 |
| seller tier / CB / 1PSIP / seller type | `mp_paidads.dim_shop_info__reg_s0_live` | `seller_tier`, `is_cb_seller`, `is_cb_sip_affiliated`, `is_local_sip_affiliated`, `seller_type_1p` | seller tier、CB / non-CB、1PSIP / non-1PSIP 拆分 |
| Escrow enable 状态 | `mp_paidads.dim_advertiser__reg_s0_live` | `is_auto_escrow_enabled` | Escrow adoption / participation proxy |

Hit budget 默认不再由本 skill 直接用 campaign 预算字段计算。先用 `SUPPLY_BUDGET` 的 `budget_type='limited'`、`daily_valid_budget`、`budget_usage = net_ads_rev / daily_valid_budget` 作为高层 proxy；如果用户明确要求 campaign-level hit-budget rate，必须先确认当前可用数据源和字段，再在报告中标注口径 caveat。

Hit balance 默认 seller-day 口径：

```sql
coalesce(ads_expenditure_amt_usd_1d, 0)
>= (coalesce(ads_expenditure_amt_usd_1d, 0) + coalesce(total_eod_balance_usd_td, 0)) * 0.97
```

### 3. 激励任务与效果表

激励侧数据来自 incentive analytics 表，不从大盘 ClickHouse 表里硬推。

| 诊断对象 | 表 | 关键字段 / 口径 | 用途 |
|---------|----|----------------|------|
| 任务下发、曝光、完成、task funnel、task credit | `mkplpaidads_analytics.dwd_ads_incentive_seller_program_lvl_table` | `program_type_name`, `program_create_date`, `program_start_date`, `shop_id`, `grass_region`, `granted_credit_amount_usd`, task status / exposure / completion 字段 | issued / exposed / completed task、credit spend、Escrow/GMS task population |
| AA / AB 效果、grouping、覆盖链路、completed-task uplift / ROI | `mkplpaidads_analytics.dwd_ads_incentive_dashboard_daily_performance` | `grass_month`, `grass_date`, `grass_region`, `shop_id`, `seller_type`, `group_name`, `group_id`, `advertiser_tier`, `shop_level1_global_be_category`, `total_net_rev`, `valid_budget`, `granted_credit_amount_usd_algo`, `has_reward_center_view`, `has_hit_target`, `is_auto_escrow_enabled`, `is_gms_active` | incentive coverage、valid exposure、completed task rev%、AB/AA uplift、ROI |

Program type 常用映射：

| `program_type_name` | 含义 |
|---------------------|------|
| `sustained_auto_escrow` | Escrow 激励 |
| `simple_fixed_reward` | GMS 激励 |
| `campaign_optimization` | 正向行为 |
| `signup_spending` | 手动报名消耗任务 |
| `target_product_spending` | item spending 激励 |

### 4. Adoption 特殊来源

Escrow 和 GMS adoption 不要混用口径。

- Escrow adoption：
  - group / experiment population：`dwd_ads_incentive_dashboard_daily_performance`
  - enable status：优先用 `is_auto_escrow_enabled`；如需按任务开始日判断 participation proxy，可 join `mp_paidads.dim_advertiser__reg_s0_live`
- GMS adoption：
  - group / experiment population：`dwd_ads_incentive_dashboard_daily_performance`
  - running status：`mp_paidads.ads_advertise_mkt_1d__reg_s0_live`
  - 判定：`pricing_type in (24, 27)` 且 `(has_performance > 0 or is_ads_active > 0)`

周报 / MTD 诊断默认使用 window adoption：窗口内任一天 adopted / running 即计为 adopted。只有用户明确要求当天快照时，才切换为 latest-day snapshot。

## 核心判断思路

供给侧异常不要只看预算是否下降，而要比较预算、GMV、余额、广告主规模之间的相对变化。

默认优先看：

1. `Budget MoM`
2. `Platform GMV MoM`
3. `Diff = Budget MoM - GMV MoM`
4. `Large Advertiser Budget MoM`
5. `Large Advertiser GMV MoM`
6. `Large Diff = Large Budget MoM - Large GMV MoM`
7. `Balance MoM`
8. `Hit Budget Rate`
9. `Hit Balance Rate`
10. `Active Advertiser Count`
11. `Budget Utilization`
12. `Fulfillment / 达标率`
13. `Overbid / Underbid Revenue Share`

如果 `Budget MoM - GMV MoM < 0`，说明预算增长落后于 GMV，可能存在供给不足。

如果 `Large Budget MoM - Large GMV MoM < 0`，优先判断大广告主是否是主因。

如果 `Budget MoM >= GMV MoM` 但 `Budget Utilization` 下降，不要写成预算不足；应继续检查达标率、overbid / underbid、item order bucket 和 advertiser tier。Robin BR case 中预算增长集中在 C/D 高订单 bucket，但 utilization 和 fulfillment 下降，主因应写成“预算扩张后的可消耗 / 履约效率下降”。

## 默认下钻顺序

供给侧归因默认按以下顺序下钻：

1. Region
2. Limited / Unlimited budget
3. Advertiser tier
4. Seller tier
5. Pricing type / Product type
6. CB / non-CB
7. 1PSIP / non-1PSIP
8. Top declining shops
9. Daily abrupt-shift check

不要一开始就查 top shop。必须先确认 region、tier、budget type 是否能解释主要变化。

## 预算与余额归因

### Limited / Unlimited

先区分预算受限和预算无限：

- `limited`：广告主设置了有效预算，预算不足可能直接限制投放。
- `unlimited`：预算不是主要限制，若投放下降，需要继续看余额、广告主活跃、产品结构或 GMV 变化。

如果 limited 预算下降明显，优先归因为预算供给不足。

如果 unlimited 预算或消耗下降明显，需要继续检查：

- balance 是否下降
- active advertiser 是否下降
- top advertiser 是否停止投放
- pricing type 是否结构变化
- fulfillment / 达标率是否下降，以及 overbid / underbid share 是否变化

如果 limited / unlimited 预算均上涨，但 revenue 或 TR 没有同步上涨，优先检查 budget usage 与 fulfillment，不要把 budget 增长本身当作正向结论直接结束。

### Hit Budget / Hit Balance

当 hit budget rate 上升时，说明更多广告主被预算限制。

当 hit balance rate 上升时，说明更多广告主被账户余额限制。

余额相关结论默认使用 gross rev 口径；不要用 net rev 解释 hit balance。

## 大广告主优先规则

供给侧异常必须优先检查 large advertiser。

判断逻辑：

- 如果整体 `Diff < 0`，且 large advertiser `Large Diff < 0`，则 large advertiser 是第一候选根因。
- 如果 large advertiser 不解释，再继续看 medium / small / micro。
- 不要只看整体 budget；大广告主结构变化经常会掩盖在整体指标里。

## Top Shop 贡献度

只有当 region / tier / product 维度已经定位到问题后，才进入 top shop 归因。

贡献度计算：

- 如果 region budget delta < 0：

```text
top shop contribution = abs(shop_delta) / abs(region_delta)
```

- 如果 region budget 仍为正，但预算增长落后于 GMV：

```text
top shop contribution = abs(shop_delta) / abs(negative_delta_pool)
```

输出 top shop 时，需要同时给出：

- shop_id
- budget delta
- GMV delta
- balance delta
- advertiser tier
- pricing type
- 是否 limited / unlimited
- 是否 hit budget / hit balance（仅在已有确认口径时输出；否则写 proxy 与 caveat）

## 激励侧归因

当异常可能与激励任务相关时，补充检查以下指标：

- incentive coverage rev%
- valid exposure rev%
- completed task rev%
- issued task count
- exposed task count
- completed task count
- granted credit amount
- adoption rate
- completed-task seller rev uplift
- completed-task seller budget uplift
- ROI

### Escrow / GMS

如果异常和 Escrow / GMS 有关，默认检查：

1. adoption 是否变化
2. treatment vs control 是否存在 uplift
3. region split 是否一致
4. task issued / exposed / completed funnel 是否断层
5. credit 是否足够解释 rev / budget 变化
6. completed-task seller uplift 是否为正

### 激励任务作为可能根因

只有满足以下至少一项，才把激励任务写入主因链路：

- 激励覆盖 rev% 明显变化
- completed task rev% 明显变化
- adoption rate 在对应 region / seller tier 明显变化
- credit spend 变化和 budget / rev 变化方向一致
- AB / AA 显示 treatment 或 completed seller 有显著 uplift
- 异常发生时间与激励任务上线、下发、结束时间吻合

否则只能写成 supporting factor，不能写成 confirmed root cause。

## 因果链写法

供给侧和激励侧归因必须写成链路，不要平铺发现。

推荐格式：

```text
Trigger:
  Large advertiser budget dropped in ID.

Propagation:
  Large advertiser valid budget -X%, while platform GMV +Y%, causing Budget-GMV Diff < 0.
  Hit budget rate increased, indicating budget constraint.

Direct impact:
  Active ads / advertiser scale dropped, leading to rev / advv decline.

Supporting evidence:
  Top N shops contributed Z% of the negative budget pool.
  Escrow/GMS incentive coverage did not offset the budget decline.

Confidence:
  High / Medium / Low, based on data consistency and metric alignment.
```
