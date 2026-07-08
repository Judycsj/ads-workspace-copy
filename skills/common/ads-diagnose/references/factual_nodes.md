# 诊断事实性节点定义/Diagnosis Factual Node Definitions

本文件定义诊断中所有事实性节点，包括**异常类型节点**和**归因类型节点**。归因节点独立定义，不绑定特定异常类型；诊断时由模型根据数据特征自行推理适用的归因节点。

## 使用说明/Usage Notes

- **编号规则**: Campaign/Ads 异常 `A{N}`，Shop 异常 `B{N}`，归因 `R{一级}.{二级}` 或 `R{一级}.{二级}.{三级}`
- **归因节点 role 标签**: `trigger`（触发因素）/ `amplifier`（放大因素）/ `direct`（直接原因）
- **天偏移约定**: `_0` = 诊断日，`_1` = 前一天，... `_7` = 7 天前
- **归因输出要求**: 诊断报告必须先评估所有叶子 R 节点，再汇总 R1-R10 一级归因模块；一级模块和叶子节点都要输出 `命中` / `未命中` / `证据不足` / `不适用` 及数字依据
- **无二级节点模块**: 若一级模块没有二级子节点（如 R6/R7），该模块自身同时作为叶子节点判定

---

## Campaign/Ads 异常类型节点 / Campaign & Ads Anomaly Type Nodes

### A1: 7d 超收/7d Overbidding

- **检测**: `cost_ratio_7d > 1.25`
- **公式**: `cost_ratio_7d = SUM(revenue_usd 近 7 天) / SUM(advv_usd 近 7 天)`

### A2: 7d 欠收/7d Underbidding

- **检测**: `cost_ratio_7d < 0.75`
- **公式**: `cost_ratio_7d = SUM(revenue_usd 近 7 天) / SUM(advv_usd 近 7 天)`

### A3: 1d 超收/1d Overbidding

- **检测**: `cost_ratio_1d > 1.25`
- **公式**: `cost_ratio_1d = revenue_usd_0 / advv_usd_0`

### A4: 1d 欠收/1d Underbidding

- **检测**: `cost_ratio_1d < 0.75`
- **公式**: `cost_ratio_1d = revenue_usd_0 / advv_usd_0`

### A5: 广告 ROI 骤降/Ads ROI Sudden Drop

- **检测**: `roi_0 / roi_1 < 0.5`，或 `roi_7d / roi_prev_7d < 0.7`
- **公式**: `roi = broad_gmv_usd / revenue_usd`

### A6: advv 骤降/advv Sudden Drop

- **检测**: `advv_usd_0 / advv_usd_1 < 0.5`

### A7: 广告 gmv/order 骤降 / Ads gmv & order Sudden Drop

- **检测**: `broad_gmv_usd_0 / broad_gmv_usd_1 < 0.5` 或 `ads_broad_order_0 / ads_broad_order_1 < 0.5`

### A8: 广告 cost 骤降（掉量）/Ads Cost Sudden Drop (Volume Loss)

- **检测**: `revenue_usd_0 / revenue_usd_1 < 0.5`

### A9: 广告 cost 骤涨（爆量）/Ads Cost Sudden Spike (Volume Surge)

- **检测**: `revenue_usd_0 / revenue_usd_1 > 2.0`

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
- **与 A11 区分**: A11 是绝对值低（CVR 持续极低），A13 是相对变化（CVR 骤降）

### A14: CTR 转换效率骤降/CTR Sudden Drop

- **检测**: `ctr_0 / ctr_1 < 0.5`（环比下降 >50%）
- **公式**: `ctr = ads_clk / ads_imp`
- **含义**: 曝光到点击的效率大幅下降，可能因广告创意/素材质量下降、广告位变差、商品图片/标题吸引力降低或竞争对手素材优化
- **与 A12 区分**: A12 是绝对值低（CTR 持续极低），A14 是相对变化（CTR 骤降）

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

### B6: 店铺 advv 骤降/Shop advv Sudden Drop

- **检测**: `advv_0 / advv_1 < 0.5`，或 `SUM(advv_usd 近 3 天) / SUM(advv_usd 前 3 天) < 0.5`

### B7: 店铺平台 gmv/order 骤降 / Shop Platform gmv & order Sudden Drop

- **检测**: `gmv_0 / gmv_1 < 0.5` 或 `order_0 / order_1 < 0.5`
- **公式**: `gmv = SUM(broad_gmv_usd)`，`order = SUM(ads_broad_order)`
- **备注**: 反映平台侧数据；与 B8 对比可判断问题源头

### B8: 店铺广告 gmv/order 骤降 / Shop Ads gmv & order Sudden Drop

- **检测**: `ads_gmv_0 / ads_gmv_1 < 0.5` 或 `ads_order_0 / ads_order_1 < 0.5`
- **公式**: `ads_gmv = SUM(direct_gmv_usd)`，`ads_order = SUM(ads_direct_order)`
- **备注**: B8↓ + B7 正常 → 广告竞争力/出价问题；B7 + B8 同降 → 店铺/平台整体问题

### B9: 店铺广告 cost 骤降（掉量）/Shop Ads Cost Sudden Drop (Volume Loss)

- **检测**: `cost_0 / cost_1 < 0.5`
- **公式**: `cost = SUM(revenue_usd)`

### B10: 店铺广告 cost 骤涨（爆量）/Shop Ads Cost Sudden Spike (Volume Surge)

- **检测**: `cost_0 / cost_1 > 2.0`
- **公式**: `cost = SUM(revenue_usd)`

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

### B15: 店铺 CTR 转换效率骤降/Shop CTR Sudden Drop

- **检测**: `ctr_0 / ctr_1 < 0.5`
- **公式**: `ctr = SUM(ads_clk) / SUM(ads_imp)`

---

## 归因类型节点/Attribution Type Nodes

按一级分类组织，每个归因节点独立定义。诊断时由模型根据检测到的异常和数据自行推理适用的归因节点。

### R1: Campaign/Ads 自身原因 / Campaign & Ads Internal Causes

#### R1.1 TROI 变更/TROI Change

**R1.1.1 大幅提高 TROI（出价更保守）** `role: trigger`
- Target (pricing_type=11): `target_roi_by_imp_0 / target_roi_by_imp_1 > 1.3`（ROI 目标提高 = 出价更保守）
- Simple (pricing_type=15): `idx_roi_upperbound_0 / idx_roi_upperbound_1 > 1.3`

**R1.1.2 大幅降低 TROI（出价更激进）** `role: trigger`
- Target (pricing_type=11): `target_roi_by_imp_0 / target_roi_by_imp_1 < 0.7`
- Simple (pricing_type=15): `idx_roi_upperbound_0 / idx_roi_upperbound_1 < 0.7`

**R1.1.3 TROI 绝对值过高** `role: trigger`
- `target_roi_by_imp_0 > category_p75`（目标 ROI 在品类中偏高，出价过于保守）
- TROI 没有变更但绝对值偏高，导致出价保守、难以获量
- 备注: 需品类分位数据支持

#### R1.2 Budget 变更/Budget Change

**R1.2.1 大幅提高 Budget** `role: trigger`
- `daily_budget_0 / daily_budget_1 > 1.5`

**R1.2.2 大幅降低 Budget** `role: trigger`
- `daily_budget_0 / daily_budget_1 < 0.5`

**R1.2.3 预算过小** `role: trigger`
- `SUM(daily_budget 近 7 天) < 1 * cpa`
- `cpa = avg_item_price / target_roi_by_imp_0`，`avg_item_price = item_price_sum_by_imp / ads_imp`（除以 1e5 转本币），`target_roi_by_imp = troi_sum_by_imp / ads_imp`

**R1.2.4 预算撞线** `role: direct`
- `revenue_usd_0 / rt_daily_budget_min_by_imp_v2_0 > 0.97` AND `rt_daily_budget_min_by_imp_v2_0 > 0`

#### R1.3 账户余额/Account Balance

**R1.3.1 账户余额耗尽** `role: trigger`
- `account_balance_shop_0 = 0`

**R1.3.2 账户余额大幅下降** `role: trigger`
- `account_balance_shop_0 / account_balance_shop_1 < 0.5`
- 余额下降可能触发系统自动砍 campaign 预算（有效预算降低）

**R1.3.3 账户余额增加（充值）** `role: trigger`
- `account_balance_shop_0 > account_balance_shop_1 * 1.5`
- 充值后释放之前受余额约束的 campaign 预算，可能导致爆量

#### R1.4 Campaign 投放状态/Campaign Status

**R1.4.1 Campaign 停投** `role: direct`
- `active_hour_0 = 0`

**R1.4.2 Campaign 投放时长减少** `role: trigger`
- `active_hour_0 < active_hour_1`

**R1.4.3 Campaign 投放时长增加** `role: trigger`
- `active_hour_0 > active_hour_1`

#### R1.5 Ads 投放状态/Ads Status

**R1.5.1 Ads 停投** `role: direct`
- STATUS 表: `visible = 0` 或 `status` 为非投放状态
- INACTIVE 表: 存在 `ads_id` 对应的停投记录，`reason` 字段标明具体原因
- 数据来源: `dwd_ads_index_status_live`（STATUS）、`unactive_ads_reason_metrics`（INACTIVE）

**R1.5.2 Ads 投放时长减少** `role: trigger`
- Ad 级别 `active_hour_0 < active_hour_1`
- 或 STATUS 表中当日 `visible = 1` 的小时数少于前一天

#### R1.6 广告质量过低/Low Ad Quality

**R1.6.1 广告质量过低** `role: direct`
- CTR、CVR 在同品类 P25 以下
- 漏斗各阶段通过率显著低于品类均值
- 备注: 需品类分位数据支持；主要与不起量场景相关

---

### R2: 商品自身原因/Item Internal Causes

**R2.1 提高 itemPrice** `role: trigger`
- 通用检测: `item_price_0 / item_price_avg_7d > 1.2`
- 超收场景: `item_price_0 / item_price_avg_7d > 1.5`
- `item_price = item_price_sum_by_imp / ads_imp`

**R2.2 降低 itemPrice** `role: trigger`
- `item_price_0 / item_price_avg_7d < 0.8`

**R2.3 商品质量/评价/库存异常** `role: trigger`
- 检测: 需人工检查 Seller Center（差评增多、库存为 0、商品被下架等）
- 备注: `requires_manual_check`，UNION 表无此数据

---

### R3: 模型预估异常/Model Estimation Anomalies
- **PIC**: haibo

R3 需要按主异常方向过滤后再计入一级模块归因：

- 超收方向（A1/A3/B1/B3）：只将"高估"类节点计入 R3 一级模块命中和最终总结；低估类节点即使公式命中，也只能作为方向不匹配旁证，不计入一级模块归因。
- 欠收方向（A2/A4/B2/B4）：只将"低估"类节点计入 R3 一级模块命中和最终总结；高估类节点即使公式命中，也只能作为方向不匹配旁证，不计入一级模块归因。
- 无固定方向的 R3 节点（如 R3.1.5、R3.4.1）只有在能解释当前主异常方向时才计入 R3 一级模块。

#### R3.1 pGMV PCOC 偏差/pGMV PCOC Deviation

**R3.1.1 final_pgmv PCOC 低估（欠收方向）** `role: amplifier`
- `daily_pgmv_sum_last_7d_clk / broad_gmv_usd < 0.8`

**R3.1.2 final_pgmv PCOC 高估（超收方向）** `role: amplifier`
- `daily_pgmv_sum_last_7d_clk / broad_gmv_usd > 1.2`

**R3.1.3 model_pgmv PCOC 低估（校准前，欠收方向）** `role: amplifier`
- `daily_model_pgmv_sum_last_7d_clk / broad_gmv_usd < 0.8`

**R3.1.4 model_pgmv PCOC 高估（校准前，超收方向）** `role: amplifier`
- `daily_model_pgmv_sum_last_7d_clk / broad_gmv_usd > 1.2`

**R3.1.5 有 order 无 gmv** `role: amplifier`
- `broad_gmv_usd_7d < ads_broad_order_7d * avg_item_price`

#### R3.2 pCTR PCOC 偏差/pCTR PCOC Deviation

**R3.2.1 pCTR PCOC 高估（模型高估 CTR，超收方向）** `role: amplifier`
- `pctr_pcoc = pctr_sum_by_imp / ads_clk > 1.2`

**R3.2.2 pCTR PCOC 低估（模型低估 CTR，欠收方向）** `role: amplifier`
- `pctr_pcoc = pctr_sum_by_imp / ads_clk < 0.8`

#### R3.3 pCR PCOC 偏差/pCR PCOC Deviation

**R3.3.1 pCR PCOC 高估（模型高估转化率，超收方向）** `role: amplifier`
- `pcr_pcoc = pcr_broad_sum_by_clk / ads_broad_order > 1.2`

**R3.3.2 pCR PCOC 低估（模型低估转化率，欠收方向）** `role: amplifier`
- `pcr_pcoc = pcr_broad_sum_by_clk / ads_broad_order < 0.8`

#### R3.4 模型预估失败/Model Estimation Failure

**R3.4.1 模型预估失败率高** `role: amplifier`
- `pcr_direct_fail_imp_cnt / ads_imp > 0.05`（失败率 >5%）
- 大量曝光缺少 pCR 预估值，导致出价不准

---

### R4: 出价调控策略异常/Bidding Control Strategy Anomalies
- **PIC**: xinyu

**R4.1 调控滑动窗口导致（超收方向）** `role: direct`
- 计算每天 `delta_cost = revenue_usd - advv_usd`
- `delta_cost_7 < 0` AND `SUM(delta_cost_6..delta_cost_1) > 0` AND `delta_cost_0 < 0`

**R4.2 调控滑动窗口导致(欠收方向)** `role: direct`
- `delta_cost_7 > 0` AND `SUM(delta_cost_6..delta_cost_1) < 0` AND `delta_cost_0 > 0`

**R4.3 数据收集异常（超收方向）** `role: direct`
- `revenue_usd_0 > 1.1 * ultra_core_rev_0` OR `1.1 * advv_usd_0 < ultra_core_advv_0`

**R4.4 数据收集异常（欠收方向）** `role: direct`
- `revenue_usd_0 < 0.9 * ultra_core_rev_0` OR `0.9 * advv_usd_0 > ultra_core_advv_0`

**R4.5 出价调控速度过慢（超收方向）** `role: direct`
- `final_coef_0 > 0.7` OR `final_coef_avg_7d > 1`

**R4.6 出价调控速度过慢（欠收方向）** `role: direct`
- `final_coef_0 < 3` OR `final_coef_avg_7d < 2`

**R4.7 MPC ROI 高估** `role: direct`
- `mpc_e_gmv_0 / mpc_e_cost_0 > (broad_gmv_usd_0 / revenue_usd_0) * 1.5`

**R4.8 MPC ROI 低估** `role: direct`
- `mpc_e_gmv_0 / mpc_e_cost_0 < (broad_gmv_usd_0 / revenue_usd_0) * 0.7`

**R4.9 出价系数死亡螺旋 (Coef Death Spiral)** `role: direct`
- **检测**: `final_coef` 连续 3 天以上持续下降且达到 < 0.5，或在 3 天内从 >1 跌至 <0.5
- **机制**: coef↓ → eCPM↓ → 竞价失败 → 最差广告位 → 零订单 → ROI 无定义 → 系统继续压低 coef → 自我强化循环
- **特征**: 不会自行恢复，需要外部干预（降低真实 target ROI / TROI，即 `target_roi_by_imp`、充值或手动重置 coef）

**R4.10 出价系数死亡螺旋（反向）** `role: direct`
- **检测**: `final_coef` 连续 3 天以上持续上升且达到 > 3
- **机制**: coef↑ → 出价过高 → 高 cost 低 ROI → 系统尝试补偿但过度

---

### R5: 广告链路异常/Ads Pipeline Anomalies

#### 下降方向（掉量）/Drop Direction (Volume Loss)

**R5.1 召回骤降** `role: direct`
- `after_recall_num_0 / after_recall_num_1 - 1 < -0.5`

**R5.2 粗排骤降** `role: direct`
- `after_prerank_num_0 / after_prerank_num_1 - 1 < -0.5`

**R5.3 精排骤降** `role: direct`
- `after_rank_num_0 / after_rank_num_1 - 1 < -0.5`

**R5.4 出价系数骤降 (pid_coef)** `role: direct`
- `final_coef_0 / final_coef_1 - 1 < -0.5`

#### 暴涨方向（爆量）/Spike Direction (Volume Surge)

**R5.5 召回暴涨** `role: direct`
- `after_recall_num_0 / after_recall_num_1 > 1.5`

**R5.6 粗排暴涨** `role: direct`
- `after_prerank_num_0 / after_prerank_num_1 > 1.5`

**R5.7 精排暴涨** `role: direct`
- `after_rank_num_0 / after_rank_num_1 > 1.5`

**R5.8 出价系数暴涨** `role: direct`
- `final_coef_0 / final_coef_1 > 1.5`

#### 漏斗通过率/Funnel Pass-Through Rate

按天计算：
- `prerank_rate = after_prerank_num / after_recall_num`
- `rank_rate = after_rank_num / after_prerank_num`
- `mixrank_rate = after_mixrank_num / after_rank_num`

**R5.9 粗排通过率骤降** `role: direct`
- `prerank_rate_0 / prerank_rate_1 < 0.5`
- 召回量未降但粗排大量过滤，可能因粗排模型变更或质量分下降

**R5.10 粗排通过率骤涨** `role: direct`
- `prerank_rate_0 / prerank_rate_1 > 1.5`
- 粗排过滤放松，可能导致低质量广告进入精排

**R5.11 精排通过率骤降** `role: direct`
- `rank_rate_0 / rank_rate_1 < 0.5`
- 粗排量未降但精排大量过滤，可能因精排模型变更、eCPM 竞争力下降或质量阈值调整

**R5.12 精排通过率骤涨** `role: direct`
- `rank_rate_0 / rank_rate_1 > 1.5`
- 精排过滤放松，可能导致低质量广告获得曝光

**R5.13 混排通过率骤降** `role: direct`
- `mixrank_rate_0 / mixrank_rate_1 < 0.5`
- 精排通过但混排大量淘汰，常见于广告位竞争力不足（与 R6 广告位质量坍塌相关）

**R5.14 混排通过率骤涨** `role: direct`
- `mixrank_rate_0 / mixrank_rate_1 > 1.5`
- 混排过滤放松，可能因竞争环境变化或混排策略调整

---

### R6: 广告位质量坍塌/Ad Slot Quality Collapse

`role: direct`

- **机制**: 低 coef → 低 eCPM → 竞价失败 → 只能赢得最差广告位 → CTR 不变但 CVR → 0
- **检测清单**:
  - CTR 保持稳定（ads_clk/ads_imp 比率与基线相近）AND CVR → 0 → 强信号
  - `mixrank_rate`（after_mixrank_num / after_rank_num）相比基线下降 >40%
  - `final_coef < 0.5` 连续 2 天以上
  - `ecpm_sum_by_imp / ads_imp` 相比基线下降 >50%
  - `coef_sum_by_imp / ads_imp`（每次曝光的平均 coef）< 0.5
- **核心洞察**: CTR 稳定但 CVR 为零 → 广告位问题，非店铺问题

---

### R7: Shop 级别问题/Shop-Level Issues

`role: direct`

- **前提**: 仅在排除 R6（广告位质量坍塌）后才考虑，是最后手段
- **检测条件**:
  - R6 的条件未满足（coef 正常、eCPM 正常、mixrank_rate 正常）
  - 所有场景同时 CVR = 0
  - 恢复期在 coef/预算恢复正常后订单仍未恢复
- **建议**: 检查 Seller Center 是否有处罚/限制
- **关键规则**: 看到所有场景 CVR=0 时不要急于得出"店铺被处罚"的结论，需先排除 R6

---

### R8: 外部/环境因素 / External & Environmental Factors

**R8.1 平台整体流量变化** `role: trigger`
- **检测**: shop 流量变化趋势与同品类/地区平台大盘一致
- **意义**: 平台侧流量波动，非广告独有问题
- **备注**: 需对比 B7（店铺平台 gmv/order）变化趋势

**R8.2 竞争环境变化** `role: trigger`
- **检测**: eCPM 上升但自身 coef 未变；impression share 下降但出价稳定
- **意义**: 竞争对手出价提升或新竞争者进入

---

### R9: Shop 级别聚合归因/Shop-Level Aggregate Attribution

**R9.1 多 Campaign 聚合效应** `role: trigger`
- **检测**: >50% 活跃 campaign 同方向异常（如同时掉量或同时爆量）
- **意义**: 广告主进行了 shop 级别的批量操作（批量调 TROI、批量改预算等）

**R9.2 单 Campaign 主导** `role: direct`
- **检测**: 一个 campaign 占 >60% shop revenue 且该 campaign 存在异常
- **意义**: shop 级异常实际由单个 campaign 驱动，应聚焦该 campaign 排查

**R9.3 平台 vs 广告区分** `role: direct`
- **检测**:
  - B7↓ + B8↓ 同比例 → 平台/店铺整体问题
  - B8↓ + B7 正常 → 广告侧问题（竞争力/出价）
- **意义**: 区分问题源头在平台侧还是广告侧

---

### R10: 场景维度异常/Scenario-Dimension Anomalies

**R10.1 特定场景超收** `role: direct`
- **检测**: 按 entrance 拆分，某场景 `revenue_usd / advv_usd > 3`， 按照用户指定日期和检测窗口聚合数据进行综合判定
- **数据来源**: Ad 级别数据，按 `(grass_date, entrance)` 聚合 `revenue_usd` 和 `advv_usd`
- **意义**: 异常集中在特定流量场景（如 Search/DD/YMAL/PP/Game），有助于定位链路问题

**R10.2 特定场景欠收** `role: direct`
- **检测**: 按 entrance 拆分，某场景 `revenue_usd / advv_usd < 0.3`，按照用户指定日期和检测窗口聚合数据进行综合判定
- **意义**: 特定场景的出价或流量分配异常

---
