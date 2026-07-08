<!-- ads-workspace-gdoc-sync: gdoc_id=1ssk2Q90VwBpTmgGMqL2qgQoLnFc_7B3MjeBEzO5Ejj8 gdoc_url=https://docs.google.com/document/d/1ssk2Q90VwBpTmgGMqL2qgQoLnFc_7B3MjeBEzO5Ejj8/edit -->

# 诊断事实性节点定义（总览）/Diagnosis Factual Node Definitions (Overall)

> **Contributors**: luka.yang ｜ **最后更新**：2026-05-28 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/skill-knowledge/diagnose/overall/factual_nodes.md)

---

本文件定义诊断中所有事实性节点，包括**异常类型节点**和**一级归因节点**。
对于有独立 subagent 的归因模块（R3/R4/R5），本文件仅包含一级定义和判定条件，二级及以下叶子节点由各模块的 `factual_nodes.md` 维护。

## 使用说明/Usage Notes

- **编号规则**: Campaign/Ads 异常 `A{N}`，Shop 异常 `B{N}`，归因 `R{一级}.{二级}`
- **归因节点 role 标签**: `trigger`（触发因素）/ `amplifier`（放大因素）/ `direct`（直接原因）
- **天偏移约定**: `_0` = 诊断日，`_1` = 前一天，... `_7` = 7 天前
- **归因输出要求**: 诊断报告必须先评估所有叶子 R 节点，再汇总 R1-R10 一级归因模块；一级模块和叶子节点都要输出 `命中` / `未命中` / `证据不足` / `不适用` 及数字依据
- **无二级节点模块**: 若一级模块没有二级子节点（如 R6/R7），该模块自身同时作为叶子节点判定
- **有 subagent 的模块**: R3/R4/R5 的二级节点定义见各模块目录下的 `factual_nodes.md`

---

## Campaign/Ads 异常类型节点 / Campaign & Ads Anomaly Type Nodes

### A1: 7d 超收/7d Overbidding
- **检测**: `cost_ratio_7d > 1.25`
- **公式**: `cost_ratio_7d = SUM(revenue_usd 近 7 天) / SUM(advv_usd 近 7 天)`
- **含义**: 近 7 天实际花费显著超过目标花费

### A2: 7d 欠收/7d Underbidding
- **检测**: `cost_ratio_7d < 0.75`
- **公式**: `cost_ratio_7d = SUM(revenue_usd 近 7 天) / SUM(advv_usd 近 7 天)`
- **含义**: 近 7 天实际花费显著低于目标花费

### A3: 1d 超收/1d Overbidding
- **检测**: `cost_ratio_1d > 1.25`
- **公式**: `cost_ratio_1d = revenue_usd_0 / advv_usd_0`
- **含义**: 当日实际花费显著超过目标花费

### A4: 1d 欠收/1d Underbidding
- **检测**: `cost_ratio_1d < 0.75`
- **公式**: `cost_ratio_1d = revenue_usd_0 / advv_usd_0`
- **含义**: 当日实际花费显著低于目标花费

### A5: 广告 ROI 骤降/Ads ROI Sudden Drop
- **检测**: `roi_0 / roi_1 < 0.5`，或 `roi_7d / roi_prev_7d < 0.7`
- **公式**: `roi = broad_gmv_usd / revenue_usd`
- **含义**: 广告投入产出比环比大幅下降

### A6: advv 骤降/advv Sudden Drop
- **检测**: `advv_usd_0 / advv_usd_1 < 0.5`
- **含义**: 广告主价值（预期消耗）环比大幅下降

### A7: 广告 gmv/order 骤降 / Ads gmv & order Sudden Drop
- **检测**: `broad_gmv_usd_0 / broad_gmv_usd_1 < 0.5` 或 `ads_broad_order_0 / ads_broad_order_1 < 0.5`
- **含义**: 广告 GMV 或订单数环比下降超 50%

### A8: 广告 cost 骤降（掉量）/Ads Cost Sudden Drop (Volume Loss)
- **检测**: `revenue_usd_0 / revenue_usd_1 < 0.5`
- **含义**: 广告花费环比下降超 50%，流量大幅减少

### A9: 广告 cost 骤涨（爆量）/Ads Cost Sudden Spike (Volume Surge)
- **检测**: `revenue_usd_0 / revenue_usd_1 > 2.0`
- **含义**: 广告花费环比上涨超 100%，流量异常增长

### A10: 不起量低消耗/No Volume
- **检测**: `SUM(revenue_usd 近 7 天) < 1 * cpa`
- **公式**: `cpa = avg_item_price / target_roi_by_imp_0`，`avg_item_price = item_price_sum_by_imp / ads_imp`（除以 1e5 转本币），`target_roi_by_imp = troi_sum_by_imp / ads_imp`
- **含义**: 广告 7 天内消耗极低，未能起量

### A11: CVR 转换效率低/Click-no-Order
- **检测**: `ads_clk > 100 AND ads_broad_order < ads_clk*0.01` 连续 2 天+
- **含义**: 有流量但零/极低转化，常见根因为广告位质量坍塌或店铺问题或商品问题

### A12: CTR 转换效率低/Imp-no-Click
- **检测**: `ads_imp > 100 AND ads_clk < ads_imp*0.01` 连续 2 天+
- **含义**: 有曝光流量但零/极低点击，常见根因为广告位质量坍塌或店铺问题或商品问题

### A13: CVR 转换效率骤降/CVR Sudden Drop
- **检测**: `cvr_0 / cvr_1 < 0.5`（环比下降 >50%）
- **公式**: `cvr = ads_broad_order / ads_clk`
- **含义**: 点击到转化的效率大幅下降，可能因广告位质量变差、商品竞争力下降、价格变动或模型预估偏差导致流量质量恶化
- **备注**: 与 A11 区分：A11 是绝对值低（CVR 持续极低），A13 是相对变化（CVR 骤降）

### A14: CTR 转换效率骤降/CTR Sudden Drop
- **检测**: `ctr_0 / ctr_1 < 0.5`（环比下降 >50%）
- **公式**: `ctr = ads_clk / ads_imp`
- **含义**: 曝光到点击的效率大幅下降，可能因广告创意/素材质量下降、广告位变差、商品图片/标题吸引力降低或竞争对手素材优化
- **备注**: 与 A12 区分：A12 是绝对值低（CTR 持续极低），A14 是相对变化（CTR 骤降）

---

## Shop 异常类型节点/Shop Anomaly Type Nodes

Shop 级别异常基于店铺下所有 campaign 的聚合数据。数据来源：UNION 表按 `shop_id + grass_region` 聚合，`type = 'campaign'`。以下所有聚合公式中 `SUM(...)` 均指 `SUM(...) WHERE shop_id = {shop_id} AND grass_region = '{region}' AND grass_date = {date}`。

### B1: 店铺 7d 超收/Shop 7d Overbidding
- **检测**: `cost_ratio_7d > 1.25`
- **公式**: `cost_ratio_7d = SUM(revenue_usd 近 7 天) / SUM(advv_usd 近 7 天)`
- **含义**: 店铺整体实际花费显著超过目标花费

### B2: 店铺 7d 欠收/Shop 7d Underbidding
- **检测**: `cost_ratio_7d < 0.75`
- **公式**: `cost_ratio_7d = SUM(revenue_usd 近 7 天) / SUM(advv_usd 近 7 天)`
- **含义**: 店铺整体实际花费显著低于目标花费

### B3: 店铺 1d 超收/Shop 1d Overbidding
- **检测**: `cost_ratio_1d > 1.25`
- **公式**: `cost_ratio_1d = SUM(revenue_usd 诊断日) / SUM(advv_usd 诊断日)`
- **含义**: 店铺当日实际花费显著超过目标花费

### B4: 店铺 1d 欠收/Shop 1d Underbidding
- **检测**: `cost_ratio_1d < 0.75`
- **公式**: `cost_ratio_1d = SUM(revenue_usd 诊断日) / SUM(advv_usd 诊断日)`
- **含义**: 店铺当日实际花费显著低于目标花费

### B5: 店铺广告 ROI 骤降/Shop Ads ROI Sudden Drop
- **检测**: `roi_0 / roi_1 < 0.5`，或 `roi_7d / roi_prev_7d < 0.7`
- **公式**: `roi = SUM(broad_gmv_usd) / SUM(revenue_usd)`
- **含义**: 店铺广告投入产出比大幅下降

### B6: 店铺 advv 骤降/Shop advv Sudden Drop
- **检测**: `advv_0 / advv_1 < 0.5`，或 `SUM(advv_usd 近 3 天) / SUM(advv_usd 前 3 天) < 0.5`
- **含义**: 店铺广告主价值环比大幅下降

### B7: 店铺平台 gmv/order 骤降 / Shop Platform gmv & order Sudden Drop
- **检测**: `gmv_0 / gmv_1 < 0.5` 或 `order_0 / order_1 < 0.5`
- **公式**: `gmv = SUM(broad_gmv_usd)`，`order = SUM(ads_broad_order)`
- **含义**: 店铺平台侧 GMV 或订单环比大幅下降
- **备注**: 反映平台侧数据；与 B8 对比可判断问题源头

### B8: 店铺广告 gmv/order 骤降 / Shop Ads gmv & order Sudden Drop
- **检测**: `ads_gmv_0 / ads_gmv_1 < 0.5` 或 `ads_order_0 / ads_order_1 < 0.5`
- **公式**: `ads_gmv = SUM(direct_gmv_usd)`，`ads_order = SUM(ads_direct_order)`
- **含义**: 店铺广告 GMV 或订单环比下降超 50%
- **备注**: B8↓ + B7 正常 → 广告竞争力/出价问题；B7 + B8 同降 → 店铺/平台整体问题

### B9: 店铺广告 cost 骤降（掉量）/Shop Ads Cost Sudden Drop (Volume Loss)
- **检测**: `cost_0 / cost_1 < 0.5`
- **公式**: `cost = SUM(revenue_usd)`
- **含义**: 店铺广告花费环比下降超 50%

### B10: 店铺广告 cost 骤涨（爆量）/Shop Ads Cost Sudden Spike (Volume Surge)
- **检测**: `cost_0 / cost_1 > 2.0`
- **公式**: `cost = SUM(revenue_usd)`
- **含义**: 店铺广告花费环比上涨超 100%

### B11: 店铺不起量低消耗/Shop No Volume
- **检测**: 店铺所有 campaign 7 天总 `SUM(revenue_usd) < N * avg_cpa`
- **含义**: 整个店铺广告无法起量

### B12: 店铺 CVR 转换效率低/Shop Click-no-Order
- **检测**: `SUM(ads_broad_order) < SUM(ads_clk) * 0.01` 连续 2 天+，且 `SUM(ads_clk) > 200`
- **含义**: 店铺级别流量正常但零/极低转化

### B13: 店铺 CTR 转换效率低/Shop Imp-no-Click
- **检测**: `SUM(ads_clk) < SUM(ads_imp) * 0.01` 连续 2 天+，且 `SUM(ads_imp) > 500`
- **含义**: 店铺级别曝光正常但零/极低点击

### B14: 店铺 CVR 转换效率骤降/Shop CVR Sudden Drop
- **检测**: `cvr_0 / cvr_1 < 0.5`
- **公式**: `cvr = SUM(ads_broad_order) / SUM(ads_clk)`
- **含义**: 店铺点击到转化效率环比大幅下降

### B15: 店铺 CTR 转换效率骤降/Shop CTR Sudden Drop
- **检测**: `ctr_0 / ctr_1 < 0.5`
- **公式**: `ctr = SUM(ads_clk) / SUM(ads_imp)`
- **含义**: 店铺曝光到点击效率环比大幅下降

---

## 归因类型节点/Attribution Type Nodes

按一级分类组织。对于有独立 subagent 的模块（R3/R4/R5），此处仅列出一级定义和判定条件，二级叶子节点见各模块目录。

### R1: Campaign/Ads 自身原因 / Campaign & Ads Internal Causes

#### R1.1 TROI 变更/TROI Change

**R1.1.1 大幅提高 TROI（出价更保守）** `role: trigger`
- **检测**: Target (pricing_type=11): `target_roi_by_imp_0 / target_roi_by_imp_1 > 1.3`；Simple (pricing_type=15): `idx_roi_upperbound_0 / idx_roi_upperbound_1 > 1.3`；若 UNION 日聚合字段缺失、为 0、或与广告主操作日志明显不一致，则使用 STATUS 表 `reason` 中 `change roi` / `target roi` 操作作为兜底证据：同一诊断日或主贡献日前后 1 天内，按 `old -> new` 或日志数值出现顺序解析，存在 `new_roi / old_roi > 1.3` 即命中
- **含义**: ROI 目标提高导致出价更保守，获量能力下降

**R1.1.2 大幅降低 TROI（出价更激进）** `role: trigger`
- **检测**: Target (pricing_type=11): `target_roi_by_imp_0 / target_roi_by_imp_1 < 0.7`；Simple (pricing_type=15): `idx_roi_upperbound_0 / idx_roi_upperbound_1 < 0.7`；若 UNION 日聚合字段缺失、为 0、或与广告主操作日志明显不一致，则使用 STATUS 表 `reason` 中 `change roi` / `target roi` 操作作为兜底证据：同一诊断日或主贡献日前后 1 天内，按 `old -> new` 或日志数值出现顺序解析，存在 `new_roi / old_roi < 0.7` 即命中
- **含义**: ROI 目标降低导致出价更激进，可能导致超收

**R1.1.3 TROI 绝对值过高** `role: trigger`
- **检测**: `target_roi_by_imp_0 > category_p75`
- **含义**: 目标 ROI 在品类中偏高，出价过于保守，导致难以获量
- **备注**: 需品类分位数据支持；TROI 没有变更但绝对值偏高

#### R1.2 Budget 变更/Budget Change

**R1.2.1 大幅提高 Budget** `role: trigger`
- **检测**: `daily_budget_0 / daily_budget_1 > 1.5`；若 UNION `daily_budget` 缺失、为 0（无限制/未同步）或明显滞后，则使用 STATUS 表 `reason LIKE '%change_budget%'` 兜底：同一诊断日或主贡献日前后 1 天内，按 `old -> new` 或日志数值出现顺序解析，存在 `new_budget / old_budget > 1.5` 即命中
- **含义**: 预算大幅提升，可能释放更多获量空间

**R1.2.2 大幅降低 Budget** `role: trigger`
- **检测**: `daily_budget_0 / daily_budget_1 < 0.5`；若 UNION `daily_budget` 缺失、为 0（无限制/未同步）或明显滞后，则使用 STATUS 表 `reason LIKE '%change_budget%'` 兜底：同一诊断日或主贡献日前后 1 天内，按 `old -> new` 或日志数值出现顺序解析，存在 `new_budget / old_budget < 0.5` 即命中
- **含义**: 预算大幅缩减，直接限制花费上限

**R1.2.3 预算过小** `role: trigger`
- **检测**: `SUM(daily_budget 近 7 天) < 1 * cpa`
- **公式**: `cpa = avg_item_price / target_roi_by_imp_0`，`avg_item_price = item_price_sum_by_imp / ads_imp`（除以 1e5 转本币），`target_roi_by_imp = troi_sum_by_imp / ads_imp`
- **含义**: 预算不足以获取一个转化

**R1.2.4 预算撞线** `role: direct`
- **检测**: `revenue_usd_0 / rt_daily_budget_min_by_imp_v2_0 > 0.97` AND `rt_daily_budget_min_by_imp_v2_0 > 0`
- **含义**: 当日花费已接近或达到日预算上限

#### R1.3 账户余额/Account Balance

**R1.3.1 账户余额耗尽** `role: trigger`
- **检测**: `account_balance_shop_0 = 0`
- **含义**: 账户余额为零，广告无法继续投放

**R1.3.2 账户余额大幅下降** `role: trigger`
- **检测**: `account_balance_shop_0 / account_balance_shop_1 < 0.5`
- **含义**: 余额下降可能触发系统自动砍 campaign 预算（有效预算降低）

**R1.3.3 账户余额增加（充值）** `role: trigger`
- **检测**: `account_balance_shop_0 > account_balance_shop_1 * 1.5`
- **含义**: 充值后释放之前受余额约束的 campaign 预算，可能导致爆量

#### R1.4 Campaign 投放状态/Campaign Status

**R1.4.1 Campaign 停投** `role: direct`
- **检测**: `active_hour_0 = 0`
- **含义**: Campaign 当日未在索引中投放

**R1.4.2 Campaign 投放时长减少** `role: trigger`
- **检测**: `active_hour_0 < active_hour_1`
- **含义**: 投放时长缩短，获量窗口减少

**R1.4.3 Campaign 投放时长增加** `role: trigger`
- **检测**: `active_hour_0 > active_hour_1`
- **含义**: 投放时长增加，获量窗口扩大

#### R1.5 Ads 投放状态/Ads Status

**R1.5.1 Ads 停投** `role: direct`
- **检测**: STATUS 表: `visible = 0` 或 `status` 为非投放状态；INACTIVE 表: 存在 `ads_id` 对应的停投记录
- **含义**: 广告因审核、违规或系统限制等原因被停投
- **备注**: 数据来源: `dwd_ads_index_status_live`（STATUS）、`unactive_ads_reason_metrics`（INACTIVE）

**R1.5.2 Ads 投放时长减少** `role: trigger`
- **检测**: Ad 级别 `active_hour_0 < active_hour_1`，或 STATUS 表中当日 `visible = 1` 的小时数少于前一天
- **含义**: 广告实际投放时长缩短

#### R1.6 广告质量过低/Low Ad Quality

**R1.6.1 广告质量过低** `role: direct`
- **检测**: CTR、CVR 在同品类 P25 以下；漏斗各阶段通过率显著低于品类均值
- **含义**: 广告素材/创意质量不足，竞争力弱
- **备注**: 需品类分位数据支持；主要与不起量场景相关

#### R1 操作日志兜底规则/STATUS Operation Fallback

- **适用范围**: R1.1 TROI 变更、R1.2 Budget 变更。
- **数据源**: `mkplpaidads_search_ads_ads_debug.dwd_ads_index_status_live`，字段 `grass_date / hour / id / operation / reason / visible / status`。STATUS 表始终在 SG ClickHouse，`grass_date` 为 string 口径。
- **判定优先级**: UNION 日聚合字段可用且方向明确时优先使用 UNION；当 UNION 字段缺失、为 0、无限制值、或未反映广告主同日操作时，STATUS 操作日志可以作为 R1 命中证据，但报告必须同时写明这是 `STATUS operation fallback`。
- **方向过滤**:
  - 超收/爆量方向（A1/A3/A9/B1/B3/B10）：只接受 `change_budget` 增加、`change roi` / `target roi` 降低。
  - 欠收/掉量方向（A2/A4/A7/A8/B2/B4/B8/B9）：只接受 `change_budget` 降低、`change roi` / `target roi` 提高。
- **数值解析**: 对 `reason` 中能解析出的数值按 `old -> new` 或出现顺序比较相邻值；同一天多次操作时，只要存在与主异常方向一致且达到阈值的相邻变更，即可作为触发因素；若只能判断方向但无法解析比例，节点为 `证据不足`，不得直接写 `命中`。

---

### R2: 商品自身原因/Item Internal Causes

**R2.1 提高 itemPrice** `role: trigger`
- **检测**: 通用: `item_price_0 / item_price_avg_7d > 1.2`；超收场景: `item_price_0 / item_price_avg_7d > 1.5`
- **公式**: `item_price = item_price_sum_by_imp / ads_imp`
- **含义**: 商品提价导致 pGMV 上升，可能引起超收

**R2.2 降低 itemPrice** `role: trigger`
- **检测**: `item_price_0 / item_price_avg_7d < 0.8`
- **含义**: 商品降价导致 pGMV 下降，可能引起欠收

**R2.3 商品质量/评价/库存异常** `role: trigger`
- **检测**: 需人工检查 Seller Center（差评增多、库存为 0、商品被下架等）
- **含义**: 商品自身问题导致转化率下降
- **备注**: `requires_manual_check`，UNION 表无此数据

---

### R3: 模型预估异常/Model Estimation Anomalies

- **PIC**: haibo
- **subagent**: `rank-model/factual_nodes.md`（R3 当前二级节点，节点集合以该文件最新定义为准）
- **宽口径判定条件**: 当 `broad_gmv_usd > 0` 时，`daily_pgmv_sum_last_7d_clk / broad_gmv_usd` 命中以下阈值则判定为 R3 异常
  - 低估: `daily_pgmv_sum_last_7d_clk / broad_gmv_usd < 0.8`
  - 高估: `daily_pgmv_sum_last_7d_clk / broad_gmv_usd > 1.2`
- **方向过滤规则**:
  - 超收/爆量方向（A1/A3/A9/B1/B3/B10）：只将"高估"类节点计入 R3 命中
  - 欠收/掉量方向（A2/A4/A7/A8/B2/B4/B8/B9）：只将"低估"类节点计入 R3 命中
  - 无固定方向的节点只有在能解释当前主异常方向时才计入

---

### R4: 出价调控策略异常/Bidding Control Strategy Anomalies

- **PIC**: xinyu
- **subagent**: `bidding/factual_nodes.md`（R4 当前二级节点，节点集合以该文件最新定义为准）
- **宽口径判定条件**: 命中以下阈值则判定为 R4 异常
  - 超收: `coef_sum_by_imp / ads_imp > 1.5` 或 `final_coef > 1.2`
  - 欠收: `coef_sum_by_imp / ads_imp < 1.0` 或 `final_coef < 1.2`
- **方向过滤规则**:
  - 超收/爆量方向（A1/A3/A9/B1/B3/B10）：只将"出价放大/系数偏高/预算消耗加速"类节点或宽口径超收阈值计入 R4 命中
  - 欠收/掉量方向（A2/A4/A7/A8/B2/B4/B8/B9）：只将"出价收缩/系数偏低/预算消耗受限"类节点或宽口径欠收阈值计入 R4 命中
  - 无固定方向的节点只有在能解释当前主异常方向时才计入


---

### R5: 广告链路异常/Ads Pipeline Anomalies

- **subagent**: `funnel/factual_nodes.md`（R5.1-R5.14 二级节点）
- **一级判定条件**: R5 下任意二级叶子节点命中，则 R5 一级模块命中

---

### R6: 广告位质量坍塌/Ad Slot Quality Collapse

`role: direct`

- **检测**:
  - CTR 保持稳定（ads_clk/ads_imp 比率与基线相近）AND CVR → 0 → 强信号
  - `mixrank_rate`（after_mixrank_num / after_rank_num）相比基线下降 >40%
  - `final_coef < 0.5` 连续 2 天以上
  - `ecpm_sum_by_imp / ads_imp` 相比基线下降 >50%
  - `coef_sum_by_imp / ads_imp`（每次曝光的平均 coef）< 0.5
  - **联合退化信号**（用于 A7/A8/B8/B9 掉量场景）: GMV 或 revenue `0/1 < 0.5`，同时 `(coef_sum_by_imp / ads_imp)_0 / (coef_sum_by_imp / ads_imp)_1 < 0.7` 且 `mixrank_rate_0 / mixrank_rate_1 < 0.8`。该组合表示出价系数相对收缩 + 混排通过率同步退化，即使单个指标未达到极端阈值，也可判定为 R6 候选命中
- **含义**: 低 coef → 低 eCPM → 竞价失败 → 只能赢得最差广告位 → CTR 不变但 CVR → 0
- **备注**: CTR 稳定但 CVR 为零 → 广告位问题，非店铺问题

---

### R7: Shop 级别问题/Shop-Level Issues

`role: direct`

- **检测**:
  - R6 的条件未满足（coef 正常、eCPM 正常、mixrank_rate 正常）
  - 所有场景同时 CVR = 0
  - 恢复期在 coef/预算恢复正常后订单仍未恢复
- **含义**: 排除广告位质量坍塌后，店铺可能存在处罚/限制
- **备注**: 前提：仅在排除 R6 后才考虑；看到所有场景 CVR=0 时不要急于得出"店铺被处罚"的结论，需先排除 R6

---

### R8: 外部/环境因素 / External & Environmental Factors

**R8.1 平台整体流量变化** `role: trigger`
- **检测**: shop 流量变化趋势与同品类/地区平台大盘一致
- **含义**: 平台侧流量波动，非广告独有问题
- **备注**: 需对比 B7（店铺平台 gmv/order）变化趋势

**R8.2 竞争环境变化** `role: trigger`
- **检测**: eCPM 上升但自身 coef 未变；impression share 下降但出价稳定
- **含义**: 竞争对手出价提升或新竞争者进入

---

### R9: Shop 级别聚合归因/Shop-Level Aggregate Attribution

**R9.1 多 Campaign 聚合效应** `role: trigger`
- **检测**: >50% 活跃 campaign 同方向异常（如同时掉量或同时爆量）
- **含义**: 广告主进行了 shop 级别的批量操作（批量调 TROI、批量改预算等）

**R9.2 单 Campaign 主导** `role: direct`
- **检测**: 一个 campaign 占 >60% shop revenue 且该 campaign 存在异常
- **含义**: shop 级异常实际由单个 campaign 驱动，应聚焦该 campaign 排查

**R9.3 平台 vs 广告区分** `role: direct`
- **检测**: B7↓ + B8↓ 同比例 → 平台/店铺整体问题；B8↓ + B7 正常 → 广告侧问题（竞争力/出价）
- **含义**: 区分问题源头在平台侧还是广告侧

---

### R10: 场景维度异常/Scenario-Dimension Anomalies

**R10.1 特定场景超收** `role: direct`
- **检测**: 按 entrance 拆分，某场景 `revenue_usd / advv_usd > 3`，按照用户指定日期和检测窗口聚合数据进行综合判定
- **含义**: 异常集中在特定流量场景（如 Search/DD/YMAL/PP/Game），有助于定位链路问题
- **备注**: 数据来源: Ad 级别数据，按 `(grass_date, entrance)` 聚合 `revenue_usd` 和 `advv_usd`

**R10.2 特定场景欠收** `role: direct`
- **检测**: 按 entrance 拆分，某场景 `revenue_usd / advv_usd < 0.3`，按照用户指定日期和检测窗口聚合数据进行综合判定
- **含义**: 特定场景的出价或流量分配异常

---
