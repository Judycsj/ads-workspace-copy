# TR 日常分析 Tracker Workflow

本文件沉淀日常人工分析 take rate / TR 的 tracker 来源、常用对比口径和标准下钻顺序。进入 Attribution Mode 且用户诊断 `take_rate` / `TR` / `Net TR` / `Gross TR` / `TR miss`，或提到 `MTD MoM`、`DOD`、`free credit`、`L0 category`、`GMV forecast` 时，必须按本文件补充分析。

## 适用范围

- 已知 region / date / period 的 TR 下降、miss target、DOD 异常、MTD MoM 异常。
- 需要解释“相似 GMV 下为什么某天 TR 更低”。
- 需要预测未来 TR：用 local GMV forecast 作为未来 platform GMV / demand pattern 的外部输入。
- 需要复刻人工 sheet 的分析路径：gross vs net、L0 category、budget vs budget usage。

## Source Priority And Tracker Sources

TR deep dive 的主数据源优先使用 ClickHouse。Google Sheet 是人工分析参考来源，用于确认业务口径、target、forecast，或在 ClickHouse 目标 period / region 不完整时 fallback。L0 category deep dive 有更严格的读取门槛：只要 OVERALL ClickHouse `cluster != 'ALL'` 覆盖目标 Period A/B、region、entrance、pricingType 且 `net_ads_rev` / `broad_gmv_usd` 可用于分解，就不要读取 Google Sheet tracker。不要写回这些 tracker。

固定优先级：

1. `overall-clickhouse-cluster`：OVERALL ClickHouse 表 `mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live` 的 `cluster` 字段。`cluster = 'ALL'` 表示不按 cluster 拆分；`cluster != 'ALL'` 是已预聚合的 L0 category / cluster breakdown。
2. `tracker-benchmark`：Weekly MoM / MTD tracker 的 `MTD, YTD` tab 中 `by cluster metrics trending` 区块，仅在 OVERALL ClickHouse L0 category 数据缺失/不完整、表权限失败，或用户明确要求 tracker benchmark 时读取。
3. `tracker-raw-fallback`：同一 tracker 的 `daily_data_raw` tab W 列及以后，用于 ClickHouse cluster 数据不可用或缺目标 period 时复算。
4. `proxy only`：仅当上述来源都不可用且明确使用非生产 proxy 字段时标注；不得写成生产 TR L0 category 结论。

| 用途 | Sheet | 关键 tab / 样例结构 | 使用方式 |
|------|-------|---------------------|----------|
| Weekly 刷新的 MoM / MTD 对比 | `https://docs.google.com/spreadsheets/d/1f3gAnX35x2ktoTVUVHkO4gvhLlzc5nLgbotEvnXHiv4/edit?copiedFromTrash=&gid=809018247#gid=809018247` | `MTD, YTD`，包含 Net TR、TR Target、Net Rev、Platform GMV、Budget、Balance、Ads item GMV penetration、Hit budget seller revenue penetration；`by cluster metrics trending` 提供 L0 category MTD/YTD 分解；`daily_data_raw` 的 W 列以后提供 daily category raw metrics | MTD MoM / target miss 的 benchmark；ClickHouse cluster 数据不可用时的 fallback；对齐 `MTD as of`、`Start of Month`、`Last month to date` |
| By-day region Ads TR tracker | `https://docs.google.com/spreadsheets/d/1c_TNRDGmv0E8UD4VrS-Vdfq1bd-7fXHmPRd_8P90VvU/edit?gid=277281501#gid=277281501` | tabs: `Global`、`ID`、`TH`、`VN`、`PH`、`BR`、`SG`、`TW`、`MY`；包含 Gross Rev/TR、Net Rev/TR、FPA revised Net TR、ROI3 voucher cost、entrypoint TR | DOD、by-region、gross/net/FPA 口径核对；入口拆分 benchmark |
| Local GMV forecast | `https://docs.google.com/spreadsheets/d/1KDkVP_DxflxlK9HQMWpUNJgBc5shPTY1ipVrPLpyir4/edit?gid=1662615395#gid=1662615395` | `2026 GMV projection by day`，列为 date + BR/ID/MY/PH/SG/TW/TH/VN/Total + forecast TR / net rev | 仅用于未来 TR 预测或 holiday / campaign demand pattern；报告必须标注 forecast，不当成实际发生数据 |


## Period Rules

如果用户没有显式给 `period_a` / `period_b`，按语义推断并在报告的“问题定义”中写明。

| 用户语义 | Period A | Period B | 说明 |
|----------|----------|----------|------|
| `MTD MoM` / `MTD MOM` / `本月 MTD vs 上月 MTD` | 本月 1 日至目标日 | 上月 1 日至上月同 day-of-month | 日常最常用。若上月无同 day-of-month，取上月最后一天 |
| `MTD vs last month` / `本月 MTD vs 上月全月` | 本月 1 日至目标日 | 上月整月 | 只有用户明确说“上月全月”或 example 指定时使用 |
| `DOD` / `昨天 vs 前天` / `5/7 为什么比 5/6 低` | 目标日 | 目标日前一天 | 单日对比必须使用 by-day freshness check |
| `相似 GMV day` / `为什么和 5/4 相似 GMV 下更低` | 目标日 | 用户给定的相似 GMV 日期；若未给，选 forecast/actual GMV 最接近且业务可比日期 | 不要自动跨 region；只在目标 region 内找 comparable day |
| `四月` / `April` 且未说明 MTD | 目标年份的 4 月整月 | 默认上月同口径整月；若用户上下文是 MTD tracker，则改用 MTD MoM | 必须在报告中写明选择理由 |

对加总指标（rev、GMV、budget、balance）：

- 如果 Period A / B 天数不同，优先展示 **daily average** 和 **period total** 两套数。归因贡献用 daily average，避免 29 天 vs 31 天误判。
- 如果任一源表缺日期，报告必须列出缺失日期，并将相关 period-level 结论降置信。
- 对 ratio 指标（TR、budget utilization、adload、ROI）直接按 period 聚合后的分子 / 分母计算，不要平均每日 ratio。

## Standard TR Triage Order

### 1. Freshness / completeness first

先检查 TAKE_RATE table、OVERALL table、SUPPLY_BUDGET table 的目标日期覆盖：

- `max(grass_date)` 是否覆盖 Period A 最后一天。
- `countDistinct(grass_date)` 是否等于 period 天数。
- 若用户明确要求 tracker benchmark，且 tracker 与 ClickHouse 数值冲突，报告同时列出 tracker benchmark 与 ClickHouse value，以 ClickHouse 为主，tracker 作为 business reference。未明确要求 tracker 且 ClickHouse L0 category 数据完整时，不要为了 benchmark 读取 tracker。

### 2. Gross vs Net vs Free Credit

先判断 TR 下降发生在 gross 还是 net：

| 检查项 | 公式 / 字段 | 判定 |
|--------|-------------|------|
| Gross TR | `SUM(gross_ads_rev_usd) / SUM(DISTINCT platform_gmv)` | Gross TR 下降说明扣费/收入本身走弱 |
| Net TR | `SUM(net_ads_rev_usd) / SUM(DISTINCT platform_gmv)` | Net TR 下降且 Gross TR 稳定，优先查 refund / voucher / free credit / SIP / 1P |
| FPA revised Net TR | tracker 中 `Net Take Rate (revised on FPA logic)` 或源表复刻口径 | 日常管理口径优先展示 |
| ROI3 voucher cost | `ads_voucher_ads_nmv_cost_usd` / tracker `ROI3 voucher cost - ads part` | 若差异由 ROI3 voucher 解释，写成 voucher / FPA 口径变化，不写成广告投放效率下降 |
| Free credit | `free_ads_rev_usd`、`sip_free_credit_revenue_usd_1d` | Net 口径异常时必须展示 free credit contribution |

建议输出 `gross_rev_delta`、`net_rev_delta`、`free_credit_delta`、`voucher_delta` 对 `net TR` gap 的贡献。不要只展示 Net TR。

### 3. L0 category GMV structure

当 TR 下降无法由 gross/net/free-credit 或入口/产品线解释，或者用户明确提到 `L0 category` / `GMV structure` / `MTD MoM`，必须做 L0 category 结构拆解。这里的 category 指 FMCG、Fashion、Lifestyle、Electronics 等业务类目，不是 ClickHouse / Kafka / Redis 等基础设施 cluster。

#### L0 category source priority

优先级固定如下，报告必须写清实际使用的 source label：

1. **OVERALL ClickHouse primary (`overall-clickhouse-cluster`)**：查询 OVERALL 表的 `cluster != 'ALL'` 行。该表已经按 L0 category / cluster 预聚合，不需要实时 join `shop_id` 或 `dim_shop_info` 重算。
2. **Tracker benchmark (`tracker-benchmark`)**：仅当 OVERALL ClickHouse L0 category 数据缺失/不完整、表权限失败，或用户明确要求 tracker benchmark 时，读取 Weekly MoM / MTD tracker 的 `MTD, YTD` tab 中 `by cluster metrics trending` 区块。
3. **Tracker raw fallback (`tracker-raw-fallback`)**：若 OVERALL cluster 数据缺目标日期 / region / 对比口径，读取同一 spreadsheet 的 `daily_data_raw` tab，W 列及以后为 daily category raw metrics，用于复算 category TR、GMV share、mix effect、own-rate effect。

只有触发 tracker fallback / benchmark 条件时，才使用当前环境可用的任意 Google Sheets 只读能力（例如 MCP、Google API client、CLI、已授权导出等）。不要把读取方式写死为某个工具；只需要固定 spreadsheet / tab / range：

- Spreadsheet ID：`1bWYzI0QYr8E5U7eYBCX9YbIz-Jscami-5E1E80lTyMQ`
- Primary tab：`MTD, YTD`
- Raw fallback range：`daily_data_raw!W:AZ`

如果 OVERALL ClickHouse L0 category 数据完整，不要读取 Google Sheet，也不要标注 tracker benchmark unavailable；报告写 `tracker benchmark: not used; ClickHouse L0 category data complete` 即可。若 OVERALL cluster 数据缺失/不完整且当前环境无法读取 Google Sheet，报告写 `L0 category source unavailable`，列出缺失工具 / 权限 / 待跑 SQL，不要假装已检查。

人工 example 使用 `shop_level0_global_be_category`，典型列包括：

```
shop_level0_global_be_category, Period B TR, Period A TR,
GMV share B, GMV share A, share MoM, TR impact
```

推荐分解：

```
category_TR = category_net_ads_rev / category_broad_gmv_usd
category_gmv_share = category_broad_gmv_usd / SUM(category_broad_gmv_usd)
total_TR = SUM(category_gmv_share * category_TR)
mix_effect_category = (share_A - share_B) * (tr_B_category - tr_B_total)
rate_effect_category = share_A * (tr_A_category - tr_B_category)
total_effect_category = mix_effect_category + rate_effect_category
```

使用 OVERALL ClickHouse `cluster != 'ALL'` 行时，`platform_gmv` 不可用；上述 category_TR、GMV share、mix effect、own-rate effect 必须统一使用 `broad_gmv_usd`。报告中 source label 写 `overall-clickhouse-cluster / broad_gmv_usd diagnostic view`，不要把它表述为生产口径 `platform_gmv` TR。

报告必须区分：

- **GMV structure / mix effect**：低 TR category 的 GMV share 上升，或高 TR category 的 GMV share 下降。
- **Category own TR effect**：category 内自身 TR 下降。
- **Residual / data gap**：category 分解无法解释的部分。

解释顺序必须先问两个问题：

1. `mix_effect_total` 是否为负？如果为正，不能把 TR 下降归因成“GMV 往低 TR category 倾斜”。
2. `rate_effect_total` 是否为负？如果 category own TR / rate effect 是主负向，必须继续下钻 category 内部效率，而不是停在 GMV mix。

当拆解结果显示 `mix_effect_total > 0` 且 `rate_effect_total < 0`：

- 不能写成“GMV 向低 TR category 倾斜”。
- 结论应写成“GMV mix 没有拖累 TR，真正拖累是 category 内部 TR / efficiency 下降”。

不要为了 L0 category breakdown 实时 join `shop_id` 或 `mp_paidads.dim_shop_info__reg_s0_live.cluster` 重算；OVERALL 表已经提供预聚合 cluster 行。`ads_union_key_metrics_daily__reg_s0_live` 中的 `shop_level1_global_be_category` / `shop_level2_global_be_category` 只能作为 ads-side category proxy；除非明确标注 `proxy only`，不得把它写成生产 take-rate L0 category 结论。

### 4. Item order bucket + Fulfillment / 达标率

当 L0 category 显示 rate effect 为主，或 budget 增长但 TR / usage 没跟上时，必须继续按 category × item order bucket 拆：

| 维度 | 推荐字段 / 口径 | 用途 |
|------|----------------|------|
| Item order bucket | `ld_30dorder_tier`，如 A: 0单、B: 1-10单、C: 10-100单、D: 100单+ | 判断预算增长是否集中在高订单 / 低订单 seller bucket |
| Budget | `avg_daily_valid_budget_usd` | 判断预算增量集中在哪里 |
| Budget utilization | `ads_expenditure_usd / valid_budget` 或 raw sheet 预计算 `budget_utilization` | 判断预算是否被有效消耗 |
| Fulfillment / 达标率 | `ads_fulfillment_rate` 或 `fulfilled_revenue / fulfillment_base_revenue` | 判断广告履约 / 调控效率是否变差 |
| Overbid / underbid share | `overbid_revenue_share`、`underbid_revenue_share`、`no_gmv_revenue_share` | 区分达标率下降来自 overbid 变多、underbid 变多，还是 no-GMV |
| TROI / ROAS setting | target ROI p50 / p80 / p90 | 验证是否是 seller 提高 ROAS setting 导致 |

判断规则：

1. 如果 budget 明显增长但 spend / revenue 增长明显更慢，先写成“预算扩张快于可消耗能力”，不要直接写“预算不足”。
2. 如果 fulfillment / 达标率下降，必须同时看 overbid 与 underbid share；不要默认等同于 underbid 变多，也不要默认等同于 ROAS setting 提高。
3. 如果 TROI p50 小幅上升但 overbid share / fulfillment 变化更强，ROAS setting 只能写为次要因素。
4. 如果 hit budget / hit balance share 没有上升，不要把预算撞线或余额不足写成主因。

可复用归因模式：

```
TR 下降
  → GMV mix effect 为正，category rate effect 为负
  → Lifestyle / Fashion 等 category 内部 TR 下降
  → C/D 高订单 bucket valid budget 增长
  → budget utilization 下降 + fulfillment 下降
  → overbid revenue share 上升
  → 收入没有跟上 GMV / budget 增长
```

### 5. Budget vs Budget Utilization

TR / rev 异常必须拆成预算和预算使用率：

```
rev = valid_budget * budget_usage
budget_usage = net_ads_rev / valid_budget
```

按以下顺序判断：

1. `valid_budget` 是否下降。
2. `budget_usage` 是否下降。
3. `balance` / `topup` 是否解释 budget 变化。
4. `hit budget seller revenue penetration` 是否上升。
5. 若 budget 不是主因，或 budget 增长但 usage 下降，再看 fulfillment / 达标率、overbid / underbid、ROAS setting / target ROI、adload、pCR、eCPM。

对于 MTD 对比，budget 和 balance 同样要同时展示 total 与 daily average。若 budget / balance tracker 存在 T-1 或 T-2 延迟，报告需写 freshness caveat。

## Required Report Sections For TR Attribution

在 Attribution Report HTML 中，TR 诊断除通用 section 外必须包含：

1. **Comparison Setup**：MTD MoM / DOD / similar-GMV / custom，列出 Period A、Period B、天数、缺失日期、tracker benchmark 使用状态。若 ClickHouse L0 category 数据完整且未显式使用 tracker，写 `tracker benchmark: not used; ClickHouse L0 category data complete`。
2. **Gross vs Net / Free Credit**：Gross TR、Net TR、FPA revised Net TR、ROI3 voucher、free credit 贡献。
3. **Core TR Gap Decomposition**：`TR = net_rev / platform_gmv`，列出 rev、GMV、daily average、ratio gap。
4. **Entrance / PricingType Contribution**：Search、DD、YMAL、Video、Live 等入口；Target2.0、Simple2.0、Manual、GMS/AdGroup 等产品线。
5. **L0 Category GMV Structure**：若可用，展示 category TR、GMV share、mix effect、own-TR effect；若不可用，明确说明未检查原因。
6. **达标率 / Overbid-Underbid**：当 category own rate effect、budget usage 下降或用户提到达标率时必填；展示 fulfillment rate、overbid revenue share、underbid revenue share、no-GMV revenue share、target ROI p50/p80/p90。
7. **Item Order Bucket Contribution**：当预算增长但使用率 / 达标率下降时必填；按 category × `ld_30dorder_tier` 展示 budget 增量、usage change、fulfillment change。
8. **Budget / Budget Utilization**：budget、budget_usage、balance、hit budget seller revenue penetration。
9. **Forecast / GMV Projection**：只有用户要求预测未来 TR 时展示；标注 forecast source 和不确定性。

## Common Conclusion Patterns

- `Gross TR down, Net TR down similarly`：收入 / 投放效率真实下降，继续看 entrance / pricingType / eCPM / budget。
- `Gross TR stable, Net TR down`：优先查 free credit、voucher、refund、SIP / 1P 排除口径。
- `Net rev grows slower than platform GMV`：典型 TR gap，继续拆 adload、CPC/eCPM、budget usage。
- `Low-TR L0 category GMV share up`：GMV structure trigger；如果 category own TR 不降，结论应写成 mix effect 而不是广告系统故障。
- `GMV mix effect positive, category own rate effect negative`：不要归因到 GMV 结构恶化；继续看 category 内部 budget utilization、fulfillment / 达标率、overbid / underbid。
- `Budget down but usage stable`：预算供给不足；继续看 balance/topup/hit budget。
- `Budget stable/up but usage down`：预算用不完；继续看流量、竞争力、TROI/ROAS setting、eCPM、adload。
- `Budget up, usage down, fulfillment down, overbid share up`：预算扩张后的广告履约 / 调控效率下降；优先按 category × item order bucket 定位，不要写成 free credit 或预算不足。
- `Fulfillment down but underbid share down, overbid share up`：达标率变差来自 overbid 增多，不是 underbid 变多；ROAS setting 只有在 target ROI 分位明显上升且与负向 bucket 一致时才可作为主因。
