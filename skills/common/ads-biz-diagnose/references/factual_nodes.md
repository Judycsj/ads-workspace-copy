# 大盘诊断事实性节点定义

本文件定义大盘诊断中所有事实性节点，包括**异常类型节点**（O 系列）和**归因类型节点**（OR 系列）。

## 使用说明

- **编号规则**: 大盘异常 `O{N}`，归因 `OR{一级}.{二级}`
- **归因节点 role 标签**: `trigger`（触发因素）/ `amplifier`（放大因素）/ `structural`（结构性变化）
- **数据粒度**: 大盘诊断的最小粒度为 `(grass_date, grass_region, scene)`，而非单个 campaign/ads

---

## 大盘异常类型节点

### O1: Take Rate 下降

- **检测**: `take_rate_A / take_rate_B - 1 < -0.5%`
- **公式**: `take_rate = net_ads_rev / platform_gmv`
- **数据源**: OVERALL 表 / TAKE_RATE 表
- **含义**: 广告变现效率下降，每单位平台 GMV 产生的广告收入减少

### O2: Take Rate 上涨

- **检测**: `take_rate_A / take_rate_B - 1 > 0.5%`
- **公式**: `take_rate = net_ads_rev / platform_gmv`
- **含义**: 广告变现效率提升

### O3: Rev（净收入）下降

- **检测**: `net_ads_rev_A / net_ads_rev_B - 1 < -1%`
- **公式**: `rev = ecpm × adload × platform_imp = advv × cost_ratio = valid_budget × budget_usage`
- **数据源**: OVERALL 表 + DIAGNOSE 表
- **含义**: 广告整体收入下降

### O4: Rev（净收入）上涨

- **检测**: `net_ads_rev_A / net_ads_rev_B - 1 > 1%`
- **含义**: 广告整体收入上涨

### O5: Advv（目标花费）下降

- **检测**: `advv_A / advv_B - 1 < -5%`
- **公式**: `advv = broad_gmv / troi`
- **数据源**: DIAGNOSE 表 `advv_sum_diff`
- **含义**: 广告主目标花费预算意愿降低，驱动因素可能是 GMV 下降或 TROI 提高

### O6: Advv（目标花费）上涨

- **检测**: `advv_A / advv_B - 1 > 5%`
- **含义**: 广告主目标花费意愿增加

### O7: Platform GMV 下降

- **检测**: `platform_gmv_A / platform_gmv_B - 1 < -2%`
- **数据源**: DIAGNOSE 表 `platform_gmv`
- **含义**: 平台整体 GMV 下降，影响 take_rate 分母
- **注意**: 此指标**不按 entrance 拆分**

### O8: 达标率下降

- **检测**: `campaign_hit_rate_A / campaign_hit_rate_B - 1 < -5%`，或 raw / tracker 中 `ads_fulfillment_rate_A - ads_fulfillment_rate_B <= -3pp`
- **公式**: `达标率 = campaign_hit_cnt / (campaign_hit_cnt + campaign_waste_cnt)`；在 TR tracker / raw data 中也可用 `ads_fulfillment_rate = fulfilled_revenue / fulfillment_base_revenue`
- **数据源**: DIAGNOSE 表；或 TR raw sheet / 明细表中的 `ads_fulfillment_rate`、`overbid_revenue_share`、`underbid_revenue_share`
- **含义**: 达标（cost_ratio 在合理范围内）的 Campaign / revenue 占比下降，意味着出价调控或广告履约效率变差；必须继续区分 overbid 变多、underbid 变多还是 no-GMV 变多

### O9: 预算使用率下降

- **检测**: `budget_usage_A / budget_usage_B - 1 < -5%`
- **公式**: `budget_usage = campaign_ads_rev_usd_1d / campaign_valid_budget_usd_1d`
- **数据源**: DIAGNOSE 表
- **含义**: 广告主预算用不完，可能因竞争力不足、出价保守或流量不足

### O10: Broad ROI 下降

- **检测**: `roi_A / roi_B - 1 < -5%`
- **公式**: `roi = broad_gmv_usd_1d / ads_rev_usd_1d`
- **数据源**: DIAGNOSE 表
- **含义**: 广告投资回报率下降

### O11: 投广 Seller GMV 占比下降

- **检测**: `ads_seller_gmv_ratio_A / ads_seller_gmv_ratio_B - 1 < -3%`
- **公式**: `ads_seller_gmv_ratio = ads_seller_gmv / platform_gmv`
- **数据源**: DIAGNOSE 表
- **含义**: 投广卖家在平台 GMV 中的份额下降
- **注意**: 此指标**不按 entrance 拆分**

### O12: 投广 Item GMV 占比下降

- **检测**: `ads_item_gmv_ratio_A / ads_item_gmv_ratio_B - 1 < -3%`
- **公式**: `ads_item_gmv_ratio = ads_item_gmv / ads_seller_gmv`
- **数据源**: DIAGNOSE 表
- **含义**: 投广商品在投广卖家 GMV 中的份额下降
- **注意**: 此指标**不按 entrance 拆分**

### O13: Broad GMV 占比下降

- **检测**: `ads_broad_gmv_ratio_ads_A / ads_broad_gmv_ratio_ads_B - 1 < -3%`
- **公式**: `ads_broad_gmv_ratio_ads = ads_broad_gmv / ads_item_gmv`
- **数据源**: DIAGNOSE 表
- **含义**: 广告 Broad GMV 在投广商品 GMV 中的归因份额下降
- **注意**: 此指标**不按 entrance 拆分**

### O14: Realized CPM 下降

- **检测**: `cpm_A / cpm_B - 1 < -5%`
- **公式**: `cpm = 1000 * net_ads_rev / ads_imp`
- **数据源**: OVERALL 表 / TAKE_RATE 表
- **含义**: 每千次广告曝光产生的实际净收入下降，可能来自变现质量下降、广告曝光扩张快于收入、或流量 / 产品线结构变化
- **注意**: realized CPM 不是 `avg_ecpm`。`avg_ecpm = ecpm_sum_by_imp / ads_imp` 是排序预估信号，不能直接当作实际扣费 CPM

### O15: Realized CPM 上涨

- **检测**: `cpm_A / cpm_B - 1 > 5%`
- **公式**: `cpm = 1000 * net_ads_rev / ads_imp`
- **数据源**: OVERALL 表 / TAKE_RATE 表
- **含义**: 每千次广告曝光产生的实际净收入上涨，可能来自出价竞争增强、广告曝光减少、或高 CPM 流量 / 产品线占比提升

### O16: Realized CPC 下降

- **检测**: `cpc_A / cpc_B - 1 < -5%`
- **公式**: `cpc = net_ads_rev / ads_clk = cpm / 1000 / ctr`
- **数据源**: OVERALL 表 / TAKE_RATE 表
- **含义**: 每次广告点击产生的实际净收入下降，可能来自 realized CPM 下降、CTR 上升带来的点击分母扩张、或低 CPC 流量 / 产品线占比提升

### O17: Realized CPC 上涨

- **检测**: `cpc_A / cpc_B - 1 > 5%`
- **公式**: `cpc = net_ads_rev / ads_clk = cpm / 1000 / ctr`
- **数据源**: OVERALL 表 / TAKE_RATE 表
- **含义**: 每次广告点击产生的实际净收入上涨，可能来自 realized CPM 上涨、CTR 下滑导致点击分母收缩、或高 CPC 流量 / 产品线占比提升

---

## 归因类型节点

按一级分类组织。诊断时根据检测到的异常和数据自行推理适用的归因节点。

### OR1: Region 结构性变化

`role: structural`

当 region=ALL 时，全局指标变化可能来自 region 权重变化（结构性）而非各 region 自身指标变化。

**OR1.1 Region 权重偏移** `role: structural`
- **检测**: `|delta_region_weight × region_metric_gap| / |delta_global_metric| > 10%`
- **含义**: 某 region 的收入占比变化（而非该 region 本身指标变化）导致全局指标变动
- **例**: 高 take_rate 的 region（如 ID）收入占比下降，拉低全局 take_rate

**OR1.2 Region 指标变化** `role: trigger`
- **检测**: `|region_weight × delta_region_metric| / |delta_global_metric| > 10%`
- **含义**: 某 region 自身的指标变化是全局变动的主因
- **操作**: 对该 region 进入 Step 2 深入归因

---

### OR2: eCPM 变化

eCPM 是 rev 的核心驱动因素之一（`rev = ecpm × adload × platform_imp`）。

**OR2.1 eCPM 下降** `role: trigger`
- **检测**: `rank_ecpm_A / rank_ecpm_B < 0.9`
- **数据源**: DIAGNOSE 表 `rank_ecpm`
- **下钻**: eCPM = coef × pctr × pcr × item_price × sold_cnt / troi，需进一步拆解哪个因子驱动

**OR2.2 eCPM 上涨** `role: trigger`
- **检测**: `rank_ecpm_A / rank_ecpm_B > 1.1`

**OR2.3 PID Coef 下降** `role: trigger`
- **检测**: `pid_coef_A / pid_coef_B < 0.9`
- **数据源**: DIAGNOSE 表 `pid_coef`
- **含义**: 出价系数下降直接压低 eCPM

**OR2.4 pCTR 下降** `role: amplifier`
- **检测**: `rank_pctr_A / rank_pctr_B < 0.9`
- **含义**: 点击率预估下降

**OR2.5 pCR 下降** `role: amplifier`
- **检测**: `rank_pcr_A / rank_pcr_B < 0.9` 或 `rank_broad_pcr_A / rank_broad_pcr_B < 0.9`
- **含义**: 转化率预估下降

**OR2.6 Item Price 变化** `role: trigger`
- **检测**: `rank_item_price_A / rank_item_price_B` 偏离 1 超过 10%
- **含义**: 商品均价变化影响 eCPM

**OR2.7 Target ROI 上调** `role: trigger`
- **检测**: `target_roi_A / target_roi_B > 1.1`
- **含义**: 广告主提高 ROI 目标 → TROI↑ → eCPM↓（公式分母增大）

**OR2.8 Sold Count 下降** `role: amplifier`
- **检测**: `avg_sold_count_A / avg_sold_count_B < 0.9`
- **含义**: 商品销量下降影响 eCPM

---

### OR3: Ad Load 变化

Ad Load = ads_imp / platform_imp，反映广告对流量的渗透率。

**OR3.1 Ad Load 下降** `role: trigger`
- **检测**: `(ads_imp_A / platform_imp_A) / (ads_imp_B / platform_imp_B) < 0.95`
- **数据源**: DIAGNOSE 表 `ads_imp` / `platform_imp`
- **含义**: 广告曝光渗透率下降

**OR3.2 Ad Load 上涨** `role: trigger`
- **检测**: `(ads_imp_A / platform_imp_A) / (ads_imp_B / platform_imp_B) > 1.05`

---

### OR4: Platform 流量变化

**OR4.1 Platform Imp 下降** `role: trigger`
- **检测**: `platform_imp_A / platform_imp_B < 0.95`
- **数据源**: DIAGNOSE 表 `platform_imp`
- **含义**: 平台整体流量下降，非广告侧问题

**OR4.2 Platform Imp 上涨** `role: trigger`
- **检测**: `platform_imp_A / platform_imp_B > 1.05`
- **含义**: 平台流量增长但广告未同步增长时可能稀释 ad load

**OR4.3 Platform GMV 上涨（分母增大）** `role: structural`
- **检测**: `platform_gmv_A / platform_gmv_B > 1.02` 且 take_rate 下降
- **含义**: 平台 GMV 增长快于广告收入增长，机械性压低 take_rate

---

### OR5: Cost Ratio 变化

Cost Ratio = rev / advv，反映广告系统对目标花费的达成程度。

**OR5.1 Cost Ratio 下降（欠收方向）** `role: trigger`
- **检测**: `(ads_rev_usd_A / advv_A) / (ads_rev_usd_B / advv_B) < 0.9`
- **含义**: 实际花费相对目标花费比例下降，意味着出价调控偏保守或竞争力不足
- **下钻**: 关联 OR2（eCPM）、OR8（达标率）、OR9（PCOC）

**OR5.2 Cost Ratio 上涨（超收方向）** `role: trigger`
- **检测**: `(ads_rev_usd_A / advv_A) / (ads_rev_usd_B / advv_B) > 1.1`
- **含义**: 实际花费超过目标花费

---

### OR6: Advv / GMV 驱动

**OR6.1 Broad GMV 下降** `role: trigger`
- **检测**: `broad_gmv_A / broad_gmv_B < 0.9`
- **数据源**: DIAGNOSE 表 `broad_gmv_usd_1d`
- **公式**: `advv = broad_gmv / troi`，GMV↓ → advv↓ → rev↓

**OR6.2 Direct GMV 下降** `role: trigger`
- **检测**: `ads_direct_gmv_A / ads_direct_gmv_B < 0.9`
- **公式**: `direct_gmv = ctr × direct_cr × item_price × sold_cnt`

**OR6.3 GMV 渗透链下降** `role: structural`
- **检测**: `ads_seller_gmv_ratio` 或 `ads_item_gmv_ratio` 或 `ads_broad_gmv_ratio_ads` 下降
- **公式**: `broad_gmv = 投广seller_gmv占比 × 投广item_gmv占比 × ads_broad_gmv占比 × platform_gmv`
- **含义**: GMV 渗透链条中某一环节占比下降
- **注意**: 此归因**不按 entrance 拆分**

---

### OR7: Budget / 预算变化

**OR7.1 Campaign 有效预算下降** `role: trigger`
- **检测**: `campaign_valid_budget_A / campaign_valid_budget_B < 0.9`
- **数据源**: DIAGNOSE 表 `campaign_valid_budget_usd_1d`
- **含义**: 广告主削减预算或系统因余额不足自动砍预算

**OR7.2 Campaign 预算使用率下降** `role: trigger`
- **检测**: `campaign_budget_used_ratio_A / campaign_budget_used_ratio_B < 0.9`
- **含义**: 预算用不完，可能因竞争力不足、流量不足或出价保守

**OR7.3 Shop 余额下降** `role: trigger`
- **检测**: `account_balance_A / account_balance_B < 0.5`
- **数据源**: DIAGNOSE 表 `account_balance_usd`
- **含义**: 大量广告主余额不足，触发系统砍预算

**OR7.4 预算撞线率上升** `role: amplifier`
- **检测**: `campaign_budget_used_ratio > 0.95` 的 Campaign 占比上升
- **含义**: 更多 Campaign 花完预算被限量

---

### OR8: 达标率 / 出价调控

**OR8.1 达标率下降** `role: trigger`
- **检测**: `campaign_hit_rate_A / campaign_hit_rate_B < 0.95`，或 `fulfillment_rate_A - fulfillment_rate_B <= -3pp`
- **公式**: `hit_rate = campaign_hit_cnt / (campaign_hit_cnt + campaign_waste_cnt)`；或 `fulfillment_rate = fulfilled_revenue / fulfillment_base_revenue`
- **含义**: 超收或欠收的 Campaign / revenue 占比增多，出价调控整体偏差增大。TR 归因中若 L0 category own rate effect 为负，必须优先检查本节点。

**OR8.2 Overbid revenue share 上升（超收方向）** `role: trigger`
- **检测**: `overbid_revenue_share_A - overbid_revenue_share_B >= 3pp`，或 `campaign_waste_rate_A > campaign_waste_rate_B * 1.1`
- **含义**: 更多 revenue 处于 overbid / 超收区间。Robin BR case 中，达标率下降主要来自 overbid share 上升，而不是 underbid 增多；报告必须明确这个方向。

**OR8.3 Underbid revenue share 上升（欠收方向）** `role: trigger`
- **检测**: `underbid_revenue_share_A - underbid_revenue_share_B >= 3pp`
- **含义**: 更多 revenue 处于 underbid / 欠收区间，可能解释 budget utilization 下降或收入跟不上 GMV。

**OR8.4 No-GMV revenue share 上升** `role: amplifier`
- **检测**: `no_gmv_revenue_share_A - no_gmv_revenue_share_B >= 3pp`
- **含义**: 无 GMV 归因的收入占比上升，可能污染 fulfillment / cost_ratio 解读。

**OR8.5 MPC 预估偏差** `role: amplifier`
- **检测**: `|mpc_e_roi_pcoc - 1| > 0.2`
- **数据源**: DIAGNOSE 表 `mpc_e_roi_pcoc`
- **含义**: MPC 模型预估 ROI 与实际偏差过大，导致出价调控方向错误

---

### OR9: 模型预估 PCOC 异常

**OR9.1 Reach PCOC 高估** `role: amplifier`
- **检测**: `reach_final_pcoc_A > 1.2` 或 `reach_final_pcoc_A / reach_final_pcoc_B > 1.1`
- **数据源**: DIAGNOSE 表 `reach_final_pcoc`
- **含义**: Reach 维度 pGMV 预估偏高

**OR9.2 Reach PCOC 低估** `role: amplifier`
- **检测**: `reach_final_pcoc_A < 0.8`
- **含义**: Reach 维度 pGMV 预估偏低

**OR9.3 Click PCOC 高估** `role: amplifier`
- **检测**: `clk_final_pcoc_A > 1.2`
- **数据源**: DIAGNOSE 表 `clk_final_pcoc`

**OR9.4 Click PCOC 低估** `role: amplifier`
- **检测**: `clk_final_pcoc_A < 0.8`

**OR9.5 pCTR PCOC 异常** `role: amplifier`
- **检测**: `ads_pctr = ads_click / pctr_sum` 偏离 1 超过 20%
- **含义**: 点击率模型预估整体偏差

**OR9.6 pCR PCOC 异常** `role: amplifier`
- **检测**: `ads_pcr` 或 `ads_broad_pcr` 偏离 1 超过 20%
- **含义**: 转化率模型预估整体偏差

---

### OR10: 漏斗通过率变化

**OR10.1 粗排通过率下降** `role: trigger`
- **检测**: `prerank_passrate_A / prerank_passrate_B < 0.9`
- **数据源**: DIAGNOSE 表 `prerank_passrate`
- **含义**: 粗排过滤更严，可能因模型更新或质量阈值调整

**OR10.2 精排通过率下降** `role: trigger`
- **检测**: `rank_passrate_A / rank_passrate_B < 0.9`
- **含义**: 精排阶段过滤增多

**OR10.3 混排通过率下降** `role: trigger`
- **检测**: `mixrank_passrate_A / mixrank_passrate_B < 0.9`
- **含义**: 混排阶段过滤增多，广告位竞争力下降

**OR10.4 出价通过率下降 (dispatch_passrate)** `role: trigger`
- **检测**: `dispatch_passrate_A / dispatch_passrate_B < 0.9`
- **含义**: 出价阶段过滤增多

**OR10.5 广告召回量下降** `role: trigger`
- **检测**: `ad_recall_cnt_A / ad_recall_cnt_B < 0.9`
- **数据源**: DIAGNOSE 表 `ad_recall_cnt`
- **含义**: 可参与竞价的广告数减少（可能因广告数减少或召回策略变化）

---

### OR11: 广告规模变化

**OR11.1 活跃广告数下降** `role: trigger`
- **检测**: `active_ads_num_A / active_ads_num_B < 0.9`
- **数据源**: DIAGNOSE 表 `active_ads_num`
- **含义**: 在投广告数量减少，供给侧萎缩

**OR11.2 投广 Item 数下降** `role: trigger`
- **检测**: `item_count_A / item_count_B < 0.9`
- **数据源**: DIAGNOSE 表 `item_count`
- **含义**: 投广商品数减少

**OR11.3 广告总数下降** `role: trigger`
- **检测**: `ads_count_A / ads_count_B < 0.9`
- **含义**: 广告创建数量整体下降

---

### OR12: Entrance (场景) 维度变化

`role: structural`

**OR12.1 特定 Entrance Rev 贡献下降** `role: structural`
- **检测**: 按 entrance 拆分 rev，某入口对 delta_rev 的贡献度 > 30%
- **数据源**: TAKE_RATE 表按 entrance 聚合
- **含义**: 收入变动集中在特定流量入口

**OR12.2 Entrance 结构偏移** `role: structural`
- **检测**: 各 entrance 的 rev 占比发生显著变化（>5pp）
- **含义**: 流量结构变化（如 Search 占比下降、DD 占比上升）影响整体指标

---

### OR13: PricingType (产品线) 维度变化

`role: structural`

**OR13.1 特定产品线 Rev 贡献下降** `role: structural`
- **检测**: 按 pricingType 拆分，某产品线对 delta_rev 的贡献度 > 30%
- **数据源**: TAKE_RATE 表按 pricingType 聚合

**OR13.2 产品线迁移** `role: structural`
- **检测**: 产品线 rev 占比变化 >5pp（如 Manual→Target 迁移）
- **含义**: 产品线结构变化影响整体 cost_ratio 和 take_rate

---

### OR14: 出价调控差值异常

**OR14.1 Rev 差值异常（超收方向）** `role: trigger`
- **检测**: `revenue_sum_diff_A > 0` 且绝对值显著增大
- **数据源**: DIAGNOSE 表 `revenue_sum_diff`
- **含义**: 系统级 Rev 超出目标，调控偏差增大

**OR14.2 Rev 差值异常（欠收方向）** `role: trigger`
- **检测**: `revenue_sum_diff_A < 0` 且绝对值显著增大

**OR14.3 GMV 差值异常** `role: amplifier`
- **检测**: `broad_gmv_sum_diff` 变化显著
- **含义**: 实际 GMV 与预估 GMV 偏差增大

**OR14.4 Advv 差值异常** `role: amplifier`
- **检测**: `advv_sum_diff` 变化显著
- **含义**: 实际 Advv 与预估偏差增大

---

### OR15: 激励任务影响

激励任务通常作为供给侧变化的触发因素或放大因素使用。只有当激励覆盖、曝光、完成、credit、adoption 或 uplift 与异常指标在时间和方向上对齐时，才能写入主因链路。

**OR15.1 激励覆盖下降** `role: trigger`
- **检测**: `incentive_coverage_rev_ratio_A / incentive_coverage_rev_ratio_B < 0.9`，或覆盖 rev% 明显下降且与 rev / budget / active advertiser 下滑同向
- **含义**: 被激励覆盖的广告收入或供给规模下降，可能削弱预算与投放意愿

**OR15.2 激励有效曝光或完成漏斗断层** `role: amplifier`
- **检测**: `valid_exposure_rev_ratio`、`completed_task_rev_ratio`、task exposed / issued、completed / exposed 等漏斗指标明显下降
- **含义**: 任务下发未有效转化为卖家看到、参与或完成，激励对供给的拉动减弱

**OR15.3 Credit spend 变化** `role: trigger`
- **检测**: `granted_credit_amount_A / granted_credit_amount_B` 显著变化，且与 budget / rev / active advertiser 变化方向一致
- **含义**: 激励强度变化可能影响广告主预算、余额或投放行为

**OR15.4 Escrow / GMS adoption 变化** `role: trigger`
- **检测**: Escrow 或 GMS adoption rate 显著变化；AB 中 Treatment vs Control 的 uplift 可解释目标 region / seller tier 的供给变化
- **含义**: 托管类产品 adoption 变化可能影响预算配置、投放稳定性与供给规模

**OR15.5 Completed-task seller uplift / ROI 异常** `role: amplifier`
- **检测**: completed-task seller rev uplift、budget uplift 或 ROI 明显转弱，或 credit ROI 无法支撑 observed supply / rev change
- **含义**: 激励完成群体没有产生预期增量，不能有效抵消供给下滑

**使用规则**
- 命中 OR15 时必须读取 `supply_incentive_attribution.md` 后再写因果链。
- 激励任务只能在证据满足时间对齐、方向一致、覆盖规模足够三项条件时写为 confirmed root cause。
- 若只看到激励任务存在但无法解释异常规模，最多写为 supporting factor。
