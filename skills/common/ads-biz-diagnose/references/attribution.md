# Attribution 模式 / Attribution Mode

> Attribution Report 生成规范。由 SKILL.md mode 分发后进入此流程。
> 复用：`factual_nodes.md`（O1-O13 + OR1-OR15）、`table_info.md`（表 schema）、`data_consistency.md`（大盘数据源一致性 gate）、`tr_tracker_workflow.md`（TR 日常 tracker / MTD / DOD / category workflow），以及按需使用的 `supply_incentive_attribution.md`（供给侧与激励侧归因补充）。

## 输入 / Input

支持两种入参方式，等价进入同一流程：

### 自然语言入参

例：`"分析 ID take_rate 昨天跌了 1.2%"` → LLM 解析为下方命令式参数。

### 命令式入参 / Command Form

```
/ads-biz-diagnose attribute region=<R> metric=<M> period_a=<YYYY-MM-DD> period_b=<YYYY-MM-DD> [comparisonMode=<mtd_mom|dod|similar_gmv|custom>] [entrance=<E>] [pricingType=<P>] [consistencyMode=<warn-only|strict>] [--save-to <path>] [--no-save]
```

| 参数 | 必填 | 取值 | 说明 |
|------|------|------|------|
| `region` | 是 | `ALL` / `ID` / `BR` / `TH` / `PH` / `VN` / `MY` / `TW` / `SG` | `ALL` 触发 Step 1 region 贡献度拆解；具体 region 跳过 Step 1 |
| `metric` | 是 | `take_rate` / `rev` / `advv` / `cpm` / `cpc` / `platform_gmv` / `达标率` / `预算` / `预算使用率` / `ads_seller_gmv占比` / `ads_item_gmv占比` / `broad_gmv占比` / `broad_roi` | 待诊断指标 |
| `period_a` | 是 | 起止日期对，如 `2026-04-26` 单日或 `2026-04-20:2026-04-26` 区间 | 诊断期 |
| `period_b` | 是 | 同上 | 基线期 |
| `comparisonMode` | 否 | `mtd_mom` / `dod` / `similar_gmv` / `custom` | 对比口径。自然语言中出现 MTD MoM、DOD、相似 GMV 时自动推断；未出现则为 `custom` |
| `entrance` | 否 | `ALL` / `Search` / `RCMD` / `DD` / `YMAL` / `Video` / `Live` / `PP` / `Game` / `Brand` | 默认 `ALL` |
| `pricingType` | 否 | `ALL` / `Target2.0` / `Simple2.0` / `Manual` / `GMS` / `AdGroup` / `ROI3` / `LiveAds` | 默认 `ALL` |
| `consistencyMode` | 否 | `warn-only` / `strict` | 默认 `warn-only`。`warn-only` 下数据一致性 `FAIL` 只降级置信度并继续归因；`strict` 下 `FAIL` 阻断 confident attribution |
| `--save-to <path>` | 否 | HTML 文件路径 | 覆盖默认存档路径；未给扩展名时自动补 `.html` |
| `--no-save` | 否 | flag | 仅打印摘要不存档 |

> **direction 不作为入参**。涨/跌方向由 period_a 与 period_b 数据自动判断。
> `entrance` 和 `pricingType` 是硬过滤条件，不是可省略条件。未传入时，OVERALL 查询必须使用 `entrance = 'ALL'` 和 `pricing_type = 'ALL'`。
> SQL 替换前，必须先将 `pricingType` 名称映射为 OVERALL 表中实际存储的 `pricing_type` 值；不要让 `pricing_type` 处于无边界状态。

> **注意**：`platform_gmv`、`ads_seller_gmv占比`、`ads_item_gmv占比`、`broad_gmv占比` 等蓝色指标**不按 entrance 拆分**。

## Step 0：问题解析 / Parse

解析输入参数，确定 region / entrance / pricingType / metric / period_a / period_b / comparisonMode。如有缺失，优先按下方规则推断；仍无法确定再反问用户补齐。

### TR-Specific Parse Rules

当 metric 是 `take_rate` / `TR` / `Net TR` / `Gross TR`，或用户提到 `TR tracker`、`MTD MoM`、`DOD`、`free credit`、`L0 category`、`达标率`、`fulfillment`、`overbid`、`underbid`、`similar GMV`、`GMV forecast` 时，必须读取 `tr_tracker_workflow.md` 并按其 period rules 推断对比口径：

| 用户语义 | comparisonMode | period_a | period_b |
|----------|----------------|----------|----------|
| `MTD MoM` / `MTD MOM` / `本月 MTD vs 上月 MTD` | `mtd_mom` | 本月 1 日至目标日 | 上月 1 日至上月同 day-of-month |
| `DOD` / `昨天 vs 前天` / `5/7 为什么比 5/6 低` | `dod` | 目标日 | 目标日前一天 |
| `相似 GMV` / `similar GMV` | `similar_gmv` | 目标日 | 用户给定 comparable day；若未给，按同 region GMV 最接近日选择并说明 |
| 用户显式给两个日期或区间 | `custom` | 用户输入 | 用户输入 |

TR 归因报告必须在“问题定义 / 对比口径设置”中写明 comparisonMode、日期、天数、数据缺失日期和 tracker benchmark 使用状态。若 ClickHouse L0 category 数据完整且用户未明确要求 tracker，写 `tracker benchmark: not used; ClickHouse L0 category data complete`。若 period 天数不同，加总指标必须同时展示 total 与 daily average，贡献度默认用 daily average。

### Scope Discipline / 严格边界规则

**用户传入的 `region` / `entrance` / `pricingType` 是查询的硬边界，不主动扩展。**

| 场景 | 行为 |
|------|------|
| 用户说 `region=ID` | 所有 SQL `WHERE grass_region = 'ID'`，不查 BR/TH/VN 等其他 region |
| 用户说 `region=ALL` | 进入 Step 1 全 region 贡献度拆解（这是 ALL 的预期行为） |
| 用户说 `entrance=Search` | 不主动按 entrance 拆分到其他入口 |
| 用户未传 `entrance` | 使用 `entrance = 'ALL'`；不要省略 entrance 谓词 |
| 用户未传 `pricingType` | 使用 `pricing_type = 'ALL'`；不要省略 pricing_type 谓词 |
| 分析中发现迹象暗示需要扩展（如同步阶跃、跨 region 同模式） | **反问用户**："发现 X 可能是跨 region 事件，是否扩展查询其他 region 验证？"，**不静默扩展** |

**为什么需要这条规则**：扩展查询会发散诊断范围、消耗额外 SQL、把简单问题写成复杂报告。用户已经表达了 scope，应该尊重。仅在用户明确确认时才扩展。

**反模式（不要做）**：
- ❌ 用户问 ID，自动 SELECT 8 个 region 做对比
- ❌ 用户问 search entrance，自动按 entrance 全维度拆分
- ❌ 用户问昨天数据，自动拉一周扩展时间窗 (注：Step 4.A 的时间扩展是**唯一**例外，因果链构建必需)

**唯一例外 — 时间维度**：Step 4.A 因果链回溯**必须**扩展时间窗（`period_b - 3d` ~ `period_a + 7d`），这是方法论必需，不需要反问。region / entrance / pricingType 没有此例外。

## Step 1：Region 贡献度拆解（仅 region=ALL 时执行）/ Region Contribution

**入口条件**：`region == ALL`。`region` 为具体国家时跳过本步，直接 Step 2。

设 `global_metric = SUM(region_weight × region_metric)`。

以 take_rate 为例：
- `region_weight` = 各 region 的 `rev`
- `region_metric` = 各 region 的 `take_rate`
- `region_metric_gap = region_metric - global_metric`

以 rev 为例：
- `region_weight` = 1（均等）
- `region_metric` = 各 region 的 `rev`

变动分解：

```
delta_global_metric = SUM(
    delta_region_weight × region_metric_gap
    + region_weight × delta_region_metric
)
```

各 region 贡献度 = `(delta_region_weight × region_metric_gap) / delta_global_metric` + `(region_weight × delta_region_metric) / delta_global_metric`

### Step 1 查询 SQL

```sql
SELECT
    grass_date, grass_region,
    SUM(revenue_usd) AS rev,
    SUM(net_ads_rev) AS sum_net_ads_rev,
    SUM(ads_imp) AS sum_ads_imp,
    SUM(ads_clk) AS sum_ads_clk,
    SUM(platform_gmv) AS sum_platform_gmv,
    SUM(net_ads_rev) / nullIf(SUM(platform_gmv), 0) AS take_rate,
    1000 * SUM(net_ads_rev) / nullIf(SUM(ads_imp), 0) AS cpm,
    SUM(net_ads_rev) / nullIf(SUM(ads_clk), 0) AS cpc
FROM mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live
WHERE grass_date BETWEEN toDate('{period_b_start}') AND toDate('{period_a_end}')
    AND entrance = 'ALL'
    AND pricing_type = 'ALL'
    AND grass_region != 'ALL'
GROUP BY grass_date, grass_region
ORDER BY grass_date ASC, grass_region ASC
```

### Step 1 输出

| region | region_weight | region_metric_gap | delta_weight 贡献 | delta_metric 贡献 |
|--------|---------------|-------------------|-------------------|-------------------|
| ID     | 0.25          | +0.02             | 15%               | 25%               |
| ...    | ...           | ...               | ...               | ...               |

筛选贡献度 ≥10% 的 region 进入 Step 2。

## Step 2：指定 Region 的指标变动归因 / Per-Region Attribution

对指定 region（或 Step 1 筛选出的高贡献 region），按以下子查询拆分进行归因。

### 2.0 Macro Data Consistency Check / 大盘数据一致性检查（必跑）

在使用任何 `ads_rev` / `broad_gmv` / `take_rate` 结论前，先执行 `data_consistency.md` 中的 gate：

1. 从 `OVERALL table` 与 `TAKE_RATE table` 拉取同一 normalized scope 下的 `ads_rev` / `broad_gmv` / `take_rate`。当请求指标或证据链使用 `cpm` / `cpc` 时，同时拉取对应条件检查指标；其他诊断不额外检查 CPM / CPC。
2. Scope 必须完全对齐：date、region、entrance、pricingType、timezone、currency、aggregation grain 都必须一致。
3. 输出 source A vs source B 值、relative diff、metric status。
4. 阈值固定，先生成 metric status：
   - `<= 1%`: `PASS`
   - `> 1%` and `<= 3%`: `WARNING`
   - `> 3%`: `FAIL`
5. 按 `consistencyMode` 决定行为：
   - `warn-only`（默认）：若诊断 metric、其核心分解 metric 为 `WARNING` / `FAIL`，或诊断 metric 在任一 source 不可用，继续归因，但在 数据一致性警告、核心结论摘要 和每个相关结论中标注"置信度降级"。根因必须表述为低置信度假设，而不是确定结论。
   - `strict`：若诊断 metric、其核心分解 metric 为 `FAIL`，或诊断 metric 在任一 source 不可用，停止 confident attribution。报告只输出 数据一致性检查 + 数据质量警告 + SQL 附录，不进入 Step 4 因果链。
6. 若为 `WARNING`，两种模式都可继续归因，但核心结论摘要和每个相关结论必须标注"置信度降级"。

> Example: 如果 `OVERALL table` 显示 ID `ads_rev` 下降 5%，但 `TAKE_RATE table` 显示基本持平或方向相反，先判定为 data-source inconsistency。默认 `warn-only` 下可以继续做 root-cause hypothesis，但必须显式标注方向冲突和低置信度；`strict` 下不要归因到 eCPM、budget、traffic、PID、model release 等原因。

### 2.0.1 TR Tracker Workflow Gate / TR 日常分析 Gate

当诊断 TR 时，在数据一致性检查后必须进入 `tr_tracker_workflow.md` 的标准顺序：

1. Freshness / completeness：检查 TAKE_RATE、OVERALL、SUPPLY_BUDGET 目标日期覆盖；列出缺失日期。
2. 毛收入 / 净收入 / Free Credit 拆解：先判断跌在 gross 还是 net；net 异常时继续看 ROI3 voucher、free credit、SIP / 1P 口径。
3. Core TR gap：`TR = net_rev / platform_gmv`，加总指标 period 天数不一致时用 daily average 做贡献度。
4. Entrance / PricingType：Search、DD、YMAL、Video、Live；Target2.0、Simple2.0、Manual、GMS/AdGroup。
5. L0 category GMV structure：按业务 L0 category（FMCG / Fashion / Lifestyle / Electronics 等）拆 GMV share mix effect 与 category own TR effect。优先使用 OVERALL ClickHouse 表的 `cluster != 'ALL'` 预聚合行；该粒度 `platform_gmv` 不可用，category TR、GMV share、mix effect、own-rate effect 必须统一使用 `broad_gmv_usd`，并在报告中标注 `overall-clickhouse-cluster / broad_gmv_usd diagnostic view`。如果 OVERALL ClickHouse L0 rows 覆盖 Period A/B、region、entrance、pricingType 且 `net_ads_rev` / `broad_gmv_usd` 可用，不要读取 TR tracker。只有 ClickHouse L0 category 数据缺失/不完整、表权限失败，或用户明确要求 tracker benchmark / fallback 时，才读取 TR tracker `MTD, YTD` tab 或 `daily_data_raw` tab；不要实时 join `shop_id` 重算 cluster 聚合。若 mix effect 为正但 rate effect 为负，必须写成 category 内部效率下降，不要误写成 GMV 往低 TR category 倾斜；数据源不可用时必须显式标记未检查。
6. 达标率 / overbid-underbid：当 category own rate effect 为负、budget usage 下降，或用户提到达标率时，必须展示 fulfillment rate、overbid revenue share、underbid revenue share、target ROI 分位；判断达标率下降到底来自 overbid、underbid 还是 no-GMV。
7. Item order bucket：当预算增长但 TR / usage 没跟上时，按 category × `ld_30dorder_tier`（A:0单、B:1-10单、C:10-100单、D:100单+）定位预算增量和效率下降集中在哪个 seller bucket。
8. 预算 / 预算使用率拆解：`rev = valid_budget * budget_usage`，判断是 budget 下降还是 budget_usage 下降，再看 balance / topup / hit budget seller revenue penetration。

Tracker 只作为 business benchmark、target、forecast 与 fallback；OVERALL ClickHouse 查询结果优先。对 L0 category，ClickHouse 数据完整时不要读取 tracker；无法读取 tracker 只在已触发 fallback / benchmark 条件时影响对应 section，并按 `tr_tracker_workflow.md` 输出 caveat。

### 2.1 查询 OVERALL 表（ClickHouse）/ Query OVERALL

获取大盘归因核心指标，按 `(grass_date, grass_region)` 聚合，或按 entrance/pricing_type/cluster 拆分：

总量 scope 查询必须显式绑定 OVERALL 的三个维度：

- `overall_entrance = entrance`，来自用户输入，默认 `ALL`。
- `overall_pricing_type = pricingType`，需先映射为 OVERALL 表实际存储值，默认 `ALL`。
- `overall_cluster = cluster`，总量默认 `ALL`；L0 category breakdown 使用 `cluster != 'ALL'`。
- 如果指标不支持 entrance 下钻，保持 `entrance = 'ALL'`；除非用户明确请求非 ALL entrance，且已确认该 scope 对该指标有效。
- 不要把 `cluster = 'ALL'` 与具体 cluster 行一起 SUM，否则会重复计算。

```sql
SELECT
    grass_date, grass_region,
    -- 效果
    SUM(revenue_usd) AS rev, SUM(advv_usd) AS advv,
    SUM(ads_clk) AS clicks, SUM(ads_imp) AS imp,
    SUM(direct_gmv_usd) AS direct_gmv, SUM(broad_gmv_usd) AS broad_gmv,
    SUM(ads_direct_order) AS direct_order, SUM(ads_broad_order) AS broad_order,
    -- 实际扣费效率（net revenue 口径）
    1000 * SUM(net_ads_rev) / nullIf(SUM(ads_imp), 0) AS cpm,
    SUM(net_ads_rev) / nullIf(SUM(ads_clk), 0) AS cpc,
    SUM(ads_clk) / nullIf(SUM(ads_imp), 0) AS ctr,
    SUM(ads_imp) / nullIf(SUM(total_imp), 0) AS adload,
    -- 预估（加权均值 = sum_by_imp / imp）
    SUM(ecpm_sum_by_imp) / nullIf(SUM(ads_imp), 0) AS avg_ecpm,
    SUM(bid_price_sum) / nullIf(SUM(ads_imp), 0) AS avg_bid,
    SUM(item_price_sum_by_imp) / nullIf(SUM(ads_imp), 0) AS avg_item_price,
    SUM(coef_sum_by_imp) / nullIf(SUM(ads_imp), 0) AS avg_coef,
    SUM(pctr_sum_by_imp) / nullIf(SUM(ads_imp), 0) AS avg_pctr,
    SUM(pcr_broad_sum_by_clk) / nullIf(SUM(ads_clk), 0) AS avg_pcr,
    SUM(troi_sum_by_imp) / nullIf(SUM(ads_imp), 0) AS avg_troi,
    SUM(sold_cnt_sum_by_imp) / nullIf(SUM(ads_imp), 0) AS avg_sold_cnt,
    -- 扣费
    SUM(net_deduction_price_sum) / nullIf(SUM(valid_deduction_cnt), 0) AS avg_net_deduct,
    SUM(gross_deduction_price_sum) / nullIf(SUM(raw_deduction_cnt), 0) AS avg_gross_deduct,
    -- 漏斗
    SUM(request_cnt) AS requests,
    SUM(after_recall_num) AS after_recall,
    SUM(after_prerank_num) AS after_prerank,
    SUM(after_rank_num) AS after_rank,
    SUM(after_mixrank_num) AS after_mixrank,
    -- 大盘
    SUM(net_ads_rev) AS sum_net_ads_rev,
    SUM(gross_rev_usd) AS gross_rev,
    SUM(platform_gmv) AS sum_platform_gmv,
    SUM(total_imp) AS sum_platform_imp,
    -- PCOC
    SUM(daily_pgmv_pcoc) AS daily_pgmv_pcoc,
    SUM(revenue_usd) / nullIf(SUM(advv_usd), 0) AS cost_ratio
FROM mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live
WHERE grass_date BETWEEN toDate('{period_b_start}') AND toDate('{period_a_end}')
    AND grass_region = '{region}'
    AND entrance = '{overall_entrance}'
    AND pricing_type = '{overall_pricing_type}'
    AND cluster = 'ALL'
GROUP BY grass_date, grass_region
ORDER BY grass_date ASC
```

### 2.2 查询 TAKE_RATE 表（ClickHouse）/ Query TAKE_RATE

按 entrance / pricingType 维度细分拆解（仅当需要按这些维度归因时查询）：

使用 SG ClickHouse 表 `mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live`。查询前先确认目标 `grass_date` / `grass_region` / `tz_type` partition 有数据；若缺失，在报告中作为数据源 freshness warning 处理，不切换到其他查询引擎补数。

```sql
SELECT grass_date, grass_region,
    CASE
        WHEN traffic_type = 'Search' THEN 'search'
        WHEN traffic_type = 'Daily Discover' THEN 'dd'
        WHEN traffic_type = 'You May Also Like' THEN 'ymal'
        WHEN traffic_type = 'Video' THEN 'video'
        WHEN traffic_type = 'Livestream' THEN 'live'
        ELSE 'other'
    END AS entrance,
    CASE
        WHEN pricing_type IN (11) THEN 'Target2.0'
        WHEN pricing_type IN (15) THEN 'Simple2.0'
        WHEN pricing_type IN (1,2) THEN 'Manual'
        WHEN pricing_type IN (18) THEN 'ROI3'
        WHEN pricing_type IN (9,10,14) THEN 'LiveAds'
        ELSE 'Others'
    END AS product,
    SUM(net_ads_rev_usd) AS net_ads_rev,
    SUM(gross_ads_rev_usd) AS gross_ads_rev,
    SUM(ads_rev_usd) AS ads_rev,
    SUM(free_ads_rev_usd) AS free_ads_rev,
    SUM(sip_free_credit_revenue_usd_1d) AS sip_free_credit_rev,
    SUM(ads_voucher_ads_nmv_cost_usd) AS ads_voucher_cost,
    SUM(ads_imp) AS ads_imp,
    SUM(ads_click) AS ads_click,
    1000 * SUM(net_ads_rev_usd) / nullIf(SUM(ads_imp), 0) AS cpm,
    SUM(net_ads_rev_usd) / nullIf(SUM(ads_click), 0) AS cpc,
    SUM(ads_click) / nullIf(SUM(ads_imp), 0) AS ctr,
    SUM(ads_order) AS ads_order,
    SUM(ads_gmv_usd) AS ads_gmv,
    SUM(DISTINCT platform_gmv) AS platform_gmv,
    SUM(DISTINCT platform_imp) AS platform_imp,
    SUM(DISTINCT entry_point_imp) AS entry_point_imp,
    SUM(ads_imp) / nullIf(SUM(DISTINCT entry_point_imp), 0) AS adload
FROM mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live
WHERE grass_date BETWEEN toDate('{period_b_start}') AND toDate('{period_a_end}')
    AND tz_type = 'regional'
    AND grass_region = '{region}'
GROUP BY 1, 2, 3, 4
```

> **平台指标去重**：`platform_gmv`、`platform_imp`、`entry_point_imp` 必须用 `SUM(DISTINCT ...)` 去重。
> **CPM 口径**：`cpm` 是 realized CPM（实际净收入 / 广告曝光 × 1000），不要用 `avg_ecpm` 代替。`avg_ecpm` 是排序预估信号，只能用于解释 realized CPM 的上游变化。

### 2.3 查询 SUPPLY_BUDGET 表（ClickHouse SG，OR7 / OR11 归因）/ Query SUPPLY_BUDGET

> 该表仅在 SG 集群，**包含全部 region（含 BR）数据** — 与 UNION 不同，所有 region 统一走 SG 集群查询（OVERALL 同样统一在 SG）。

按 `(grass_date, grass_region)` 取大盘总量（不区分 pricing_type / budget_type）：

```sql
SELECT
    grass_date, grass_region,
    SUM(active_ads_cnt) AS active_ads_cnt,
    SUM(active_advertiser_cnt) AS active_advertiser_cnt,
    SUM(daily_valid_budget) AS valid_budget_usd,
    SUM(topup_amt_usd) AS topup_amt_usd,
    SUM(account_balance_usd) AS account_balance_usd
FROM mkplpaidads_search_ads_ads_debug.overall_supply_budget_metrics_daily__reg_s0_live
WHERE grass_date BETWEEN toDate('{period_b_start}') AND toDate('{period_a_end}')
    AND grass_region = '{region}'
    AND pricing_type = 'all'
    AND budget_type = 'all'
GROUP BY grass_date, grass_region
ORDER BY grass_date ASC
```

按 pricing_type 拆分：`WHERE pricing_type != 'all' AND budget_type = 'all'` 并 `GROUP BY ..., pricing_type`。
按 budget_type（limited / unlimited）拆分：`WHERE pricing_type = 'all' AND budget_type != 'all'` 并 `GROUP BY ..., budget_type`。
**不要**同时包含 `'all'` 和具体值，会重复计算。

### 2.3.1 供给侧与激励侧补充归因 / Supply & Incentive Add-on

当 Step 2 命中 OR7 Budget、OR11 广告规模变化、OR15 激励任务影响，或异常涉及 platform GMV、active advertiser、valid budget、balance、hit budget、hit balance、Escrow/GMS/ABI 等供给与激励信号时，必须读取 `supply_incentive_attribution.md`。

该补充用于规范下钻顺序、hit budget / hit balance 口径、large advertiser 优先规则、top shop 贡献度、以及激励任务是否能进入主因链路。不要把激励任务仅因“同时存在”就写成 confirmed root cause；必须满足补充文件中的因果证据条件。

### 2.3.2 达标率与 item bucket 补充 / Fulfillment & Item Bucket Add-on

当 TR 下降存在以下任一信号时，必须补充达标率分析：

- L0 category 分解显示 `mix_effect_total >= 0` 但 `rate_effect_total < 0`，即 GMV mix 没拖累、category own TR / rate effect 拖累。
- Valid budget 增长但 budget utilization / net rev 没跟上 GMV。
- 用户或参考材料提到 `达标率`、`fulfillment`、`overbid`、`underbid`、`ROAS setting`。

优先从 tracker / raw sheet 或可用明细表读取以下字段；如果当前 ClickHouse 三张主表没有字段，报告必须标注 `fulfillment source unavailable`，不能假装已检查：

| 字段 | 含义 | 诊断用法 |
|------|------|----------|
| `ads_fulfillment_rate` / `fulfillment_rate` | 达标收入占 fulfillment base revenue 的比例 | 判断广告履约 / 调控效率是否变差 |
| `overbid_revenue_share` | overbid 收入占比 | 区分达标率下降是否来自 overbid 变多 |
| `underbid_revenue_share` | underbid 收入占比 | 区分是否因为 underbid 变多导致欠收 |
| `no_gmv_revenue_share` | no-GMV 收入占比 | 排查无 GMV 归因的异常收入结构 |
| `ld_30dorder_tier` | seller / item 近 30 天订单 bucket | 定位预算增量是否集中在 C/D 高订单 bucket |
| `target_roi_p50/p80/p90` | TROI / ROAS setting 分位数 | 验证 ROAS 设置是否足以解释效率下降 |

判断规则：

1. 达标率下降必须同时展示 overbid 与 underbid：如果 overbid share 上升、underbid share 下降，结论应写“达标率变差来自 overbid 变多”，不要写“underbid 变多”。
2. 如果 TROI 只是小幅上升，而 overbid share / fulfillment 变化更强，ROAS setting 只能作为次要因素。
3. 如果 hit budget / hit balance share 没有上升，不能把预算撞线或余额不足写成主因。
4. 对 category 内 rate effect，优先输出 category × item order bucket 表：budget 增量、budget utilization change、fulfillment change、overbid / underbid change。

### 2.4 归因分析逻辑 / Attribution Logic

根据异常指标，按公式树逐层分解变动来源。对照 `factual_nodes.md` 中的归因节点逐一检测。

**rev 下降归因路径**：

```
rev ↓
├── ecpm × adload × platform_imp 分解
│   ├── ecpm ↓ → coef ↓ / pctr ↓ / pcr ↓ / item_price ↓ / troi ↑
│   ├── adload ↓ → ads_imp/platform_imp ↓
│   └── platform_imp ↓ → 平台流量下降
├── advv × cost_ratio 分解
│   ├── advv ↓ → broad_gmv ↓ / troi ↑
│   └── cost_ratio ↓ → 达标率/PCOC/PID 调控
└── valid_budget × budget_usage 分解
    ├── valid_budget ↓ → 预算/余额减少
    └── budget_usage ↓ → 预算用不完
```

**take_rate 下降归因路径**：

```
take_rate = rev / platform_gmv ↓
├── rev ↓（同上）
├── platform_gmv ↑ → 平台增长但广告未同步增长
└── category own TR / rate effect ↓ → 继续查 budget utilization、达标率、overbid / underbid、item order bucket
```

**realized CPM 变化归因路径**：

```
cpm = 1000 * net_ads_rev / ads_imp
├── net_ads_rev 变化（同 rev 路径）
├── ads_imp 变化
│   ├── adload = ads_imp / platform_imp 变化
│   └── platform_imp 变化
└── 结构变化
    ├── entrance mix 变化（高 / 低 CPM 入口占比变化）
    └── pricingType mix 变化（高 / 低 CPM 产品线占比变化）
```

**realized CPC 变化归因路径**：

```
cpc = net_ads_rev / ads_clk = cpm / 1000 / ctr
├── cpm 变化（同 realized CPM 路径）
├── ctr = ads_clk / ads_imp 变化
│   ├── pCTR / 实际 CTR 偏离
│   └── 流量质量或入口结构变化
└── ads_clk 变化
    ├── ads_imp 变化
    └── CTR 变化
```

## Step 3：维度下钻（按 entrance / pricingType）/ Drill-down

当 Step 2 的归因不够具体时，进一步按 entrance 或 pricingType 拆分：

1. 按 entrance 拆分：计算各入口对 rev / TR gap 的贡献度，找到主要贡献入口
2. 按 pricingType 拆分：计算各产品线对 rev / TR gap 的贡献度
3. TR 诊断额外拆 gross vs net vs free credit，确认是 gross 侧下降还是 net / voucher / free-credit 口径变化
4. TR 诊断额外拆 L0 category：计算 category GMV share mix effect 与 category own TR effect；mix effect 为正时不要归因到 GMV 结构恶化
5. TR 诊断额外拆达标率：按 category / item order bucket 展示 fulfillment、overbid、underbid、TROI 分位，判断 category own rate effect 是否来自履约效率下降
6. TR / rev 诊断额外拆 budget vs budget_usage：判断预算下降还是预算用不完；budget 增长但 usage 下降时，必须联动达标率解释
7. 交叉维度：entrance × pricingType；仅在主要问题维度仍不清楚或用户明确要求时使用

> **注意**：`platform_gmv`、`ads_seller_gmv占比` 等指标**不按 entrance 拆分**，因为它们在广告维度上会重复。

下钻 SQL 必须保持粒度边界：

- Entrance 下钻：`WHERE pricing_type = '{overall_pricing_type}' AND entrance != 'ALL'`，然后 `GROUP BY ..., entrance`。
- PricingType 下钻：`WHERE entrance = '{overall_entrance}' AND pricing_type != 'ALL'`，然后 `GROUP BY ..., pricing_type`。
- 交叉下钻：仅在用户明确请求时使用 `WHERE entrance != 'ALL' AND pricing_type != 'ALL'`。
- 如果用户已经将 `entrance` 或 `pricingType` 限定为非 ALL 值，下钻时不要扩展该维度，除非用户确认。
- L0 category 下钻：优先使用 OVERALL ClickHouse 表中 `cluster != 'ALL'` 的预聚合行并 `GROUP BY cluster`；该粒度 `platform_gmv` 不可用，必须使用 `broad_gmv_usd` 计算 category TR、GMV share、mix effect、own-rate effect。总量生产 TR 对照仍使用 `cluster = 'ALL'` 的 `platform_gmv`，不要与具体 cluster 行重复 SUM。若 OVERALL cluster 数据完整，不要读取 tracker；报告写 `tracker benchmark: not used; ClickHouse L0 category data complete`。只有 OVERALL cluster 数据缺目标 period / region / scope、表权限失败，或用户明确要求 tracker benchmark / fallback 时，才读 Weekly MoM / MTD tracker 的 `MTD, YTD` tab，必要时读 `daily_data_raw` tab W 列以后复算。当前 ClickHouse TAKE_RATE 表无 L0 category 字段，不能假装已检查；不要实时 join `shop_id` 重算 cluster；`ads_union_key_metrics_daily__reg_s0_live` 的 category 字段只能作为 ads-side proxy，不能写成生产 TR L0 category 结论。
- 达标率下钻：若用户明确要求 fulfillment / overbid-underbid / item-order-bucket follow-up，才读取 tracker / raw sheet 中的 `ads_fulfillment_rate`、`overbid_revenue_share`、`underbid_revenue_share`、`ld_30dorder_tier`、target ROI 分位；不要仅因 L0 category ClickHouse own-rate effect 为负就自动读取 tracker。若源表重算，需要用 campaign / seller 明细表构造 fulfillment base revenue。当前 ClickHouse TAKE_RATE / OVERALL / SUPPLY_BUDGET 表没有完整 fulfillment bucket 字段，不能假装已检查；未显式下钻时写成 next step / source unavailable caveat。
- Budget / budget_usage 下钻：使用 SUPPLY_BUDGET 总量、`budget_type`、`pricing_type` 拆分；若需要 hit budget seller revenue penetration，必须按 `supply_incentive_attribution.md` 先确认可用数据源和字段，无法确认时只输出 proxy 与 caveat。

## Step 4：因果链构建方法论 / Causal Chain Methodology

> 单纯枚举命中的 OR 节点（OR1-OR15）是**机械列表**，不是诊断。真正的归因要构建一条**带时间顺序的因果链**，能解释"什么先动 → 怎么传播 → 是否恢复"。
> 这是 Step 1~3 完成后的**装配阶段**，决定 Attribution Report 的"因果链"和"归因分析"两个 section 的内容质量。

### Step 4.A: 找最早触发事件 / Find Earliest Trigger

**不要假设触发起点 = period_a**。扩展时间窗（`period_b - 3d` ~ `period_a + 3d`），按天看核心因子哪个**最早**出现 ≥5% 的方向性变化。

最常见的早触发因子（按业务高频度）：

- **PID coef 调控** (`coef_sum_by_imp / ads_imp`) — 系统反应上游数据异常
- **Target ROI 调整** (`troi_sum_by_imp / ads_imp`) — 客户/产品线主动调整
- **Valid budget 削减** (SUPPLY_BUDGET 表 `daily_valid_budget`) — 广告主端预算变化
- **平台流量阶跃** (`total_imp`) — 平台侧流量异常或大促
- **GMV demand shift** (`platform_gmv` / `broad_gmv`) — 节假日 / 大促 / 周末等市场需求变化；GMV 只能证明 demand pattern，不能单独证明日历原因
- **模型预估特征 lag/缺失** (pCTR / pCR / 计算 PCOC 看是否偏离 1) — 上游数据 pipeline 问题

**扩展时间窗查询模板**：

```sql
SELECT grass_date, grass_region, ...同 Step 2.1 全因子...
FROM mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live
WHERE grass_date BETWEEN toDate('{period_b - 3d}') AND toDate('{period_a + 3d}')
  AND grass_region IN ({高贡献 region 列表})
  AND entrance = '{overall_entrance}'
  AND pricing_type = '{overall_pricing_type}'
GROUP BY grass_date, grass_region
ORDER BY grass_region ASC, grass_date ASC
```

按天比较，找出**第一个**显著变化的因子。这往往不是 period_a 当天，而可能是 period_b 当天甚至更早。

### Step 4.A.1: GMV-Based Holiday / Campaign Adjustment

在 Step 4.A 的扩展时间窗内，用已拉取的 `platform_gmv`、`broad_gmv`、`ads_rev`、`take_rate` 做 GMV-based market-demand adjustment。不要新增 holiday calendar、外部数据源或命令参数；GMV movement 只能说明该日期存在 holiday / campaign / weekend-compatible 的市场需求变化，不能单独证明日历原因。

**强制包含规则**：只要诊断指标、触发因素、公式分解、异常节点或下钻证据中任一项涉及 GMV（例如 `take_rate`、`platform_gmv`、`broad_gmv`、`advv`、ROI、GMV 占比、OR4.3、OR6、GMV demand shift），Attribution Report 必须单独输出 `Step 4.A.1 GMV-Based Holiday / Campaign Adjustment` section。不要只把 label 写进 TL;DR、Step 4.A 或因果链正文。即使判定为 `not explained by GMV movement` 或 `insufficient evidence`，也要保留该 section 并说明原因。

优先使用 `platform_gmv` 判断市场大盘；如果 `platform_gmv` 缺失或不可比，再使用 `broad_gmv` 作为广告归因 GMV 的辅助判断。`material move` 默认沿用 Step 4.A 的显著变化阈值：`abs(delta) >= 5%`。`take_rate stable` 定义为未命中 O1/O2，即 `abs(take_rate_delta) <= 0.5%`。

| Label | 判定条件 | 报告处理 |
|-------|----------|----------|
| `market-demand effect, monetization normal` | `platform_gmv` 或 `broad_gmv` material move；`ads_rev` 与 GMV 同方向；`take_rate stable` | 将 holiday / campaign / weekend-compatible demand shift 作为 trigger 或 amplifier；降低"广告侧故障"置信度 |
| `market-demand/campaign effect, ads under-monetized` | GMV material increase；`ads_rev` 涨幅明显小于 GMV（差距 > 5pp）、持平或下降；或 `take_rate` 命中 O1 | 不要写成"只是节假日"；写成 market-demand spike + ads monetization underperformance，并继续检查 adload / eCPM / budget / traffic mix |
| `not explained by GMV movement` | GMV 未 material move，或 GMV 方向/幅度无法解释 ads metric 异常 | 不使用 holiday / campaign demand 作为解释；继续按常规广告侧归因 |
| `insufficient evidence` | GMV 缺失、不可比，或相关数据一致性 gate 为 FAIL | 不做 GMV-based adjustment；在报告中说明证据不足，并按 consistencyMode 降置信或停止 confident attribution |

报告用语必须区分"GMV-based market-demand adjustment"与"confirmed holiday cause"：前者是数据模式判断，后者需要外部日历或活动信息，本 skill 默认不引入。

### Step 4.B: 追踪下游传播 / Trace Propagation

构建 N → N+1 → ... 的传导箭头，每步标明**驱动因子 → 受影响因子 → 数值变化**。常见模板：

**模板 1: 上游数据异常型（最常见）**

```
上游调价用数据 lag/缺失 (broad_gmv / shop_gmv 实际回流偏差)
  → PID 系统检测到 cost-ratio 偏离目标
  → 系统下调 coef (-X%)
  → eCPM = coef × pCTR × pCR × item_price × sold_cnt / TROI 公式分子被压
  → eCPM ↓
  → CPC = rev/clk ↓ / rev ↓
```

**模板 2: 广告主端预算异常型**

```
广告主预算或余额下降明显
  → 大盘效果数据出现异常 (ROI 剧烈下降 / CPC 剧烈提升)
  → 广告主批量降低预算（恶性循环 / 自我强化）
  → valid_budget ↓ / cost_ratio ↓
  → rev ↓
```

**模板 3: 平台流量结构型**

```
节假日 / 大促 / 周末高峰 → platform_imp ↑↑
  → 流量结构变化（新流量入口未带广告 / ad_load 摊薄）
  → ads_clk 涨幅 < platform_imp 涨幅
  → CPC 摊薄；rev 涨幅有限
```

如果实际数据不匹配现有模板，构建新模板并记入 attribution report 的"因果链"section，便于后续案例归类。

### Step 4.C: 用恢复数据验证 / Recovery Validation

**这是最关键的反向验证步骤**。拉 `period_a + 1d` ~ `period_a + 7d` 数据：

```sql
SELECT grass_date, grass_region, ...同 Step 2.1 全因子...
WHERE grass_date BETWEEN toDate('{period_a + 1d}') AND toDate('{period_a + 7d}')
  AND grass_region IN ({高贡献 region})
  AND entrance = '{overall_entrance}'
  AND pricing_type = '{overall_pricing_type}'
GROUP BY grass_date, grass_region
```

**判定矩阵**：

| 异常指标 N+1 ~ N+7 表现 | 推论 | 触发假设 |
|------------------------|------|---------|
| 完全恢复至 baseline | **周期性 / 临时性触发**（周末效应、单日 PID 短期波动） | 根因偏 amplifier，trigger 是周期性事件 |
| 恢复并 over-shoot 反向超调 | **典型 PID 控制器响应**（先反应过度 → 再补偿） | 根因是上游输入数据 lag 或临时异常，**模型本身正常** |
| 完全不恢复 / 持续低迷 | **结构性变化** | 模型 release / 产品策略调整 / 客户长期变化；查变更管理 |
| 部分恢复 + 部分不恢复（region 分化） | 多因素叠加 | Region 级独立分析，区分周期性 vs 结构性 |

**关键反向推论**（重点）：

- 如果异常**完全恢复**（特别是 over-shoot），可以**排除**模型 release 类永久性问题假设
- 如果异常**完全不恢复**，需要**排除**周期性假设，重点查 release / 配置变更
- **不做 Step 4.C 直接下"模型 release"结论是高错误率行为** — 必须用恢复数据证伪/证实

### Step 4.D: 角色分类 / Role Classification

将命中的 OR 节点按以下三类标签整理（与 `factual_nodes.md` 中 `trigger / amplifier / structural` 标签语义对齐）：

- **触发因素 (Trigger)**: 时间上**最早**出现的、有明确驱动作用的变化（Step 4.A 找出的那个）
- **放大因素 (Amplifier)**: 加剧异常的次级因素，本身不是起点（如周末流量峰值）
- **直接原因 (Direct Cause / Mechanism)**: 与待诊断指标**最近端**的作用机制（通常是公式分解最底层的一项）

这三类在 Attribution Report 的"归因分析" + "因果链" section 中**显式分开列**。

**反模式（不要做）**：把 5 个 OR 节点平铺成 5 个独立发现 — 它们必须装配成一条因果链。

## 异常检测与归因 / Anomaly & Attribution Nodes

异常类型定义（O1-O13 大盘异常）和归因节点定义（OR1-OR15）详见 `factual_nodes.md`。

诊断时：

1. 每种异常类型独立判定，遍历所有异常类型
2. 异常的归因原因按照从前到后的顺序依次判断，符合条件则加入候选原因列表
3. 继续检查后续归因找到所有可能的候选原因
4. 归因节点的 `role` 标签（`trigger` / `amplifier` / `structural`）帮助构建因果链
5. **节点级判定后必须进入 Step 4 因果链构建** — 不要只做节点级 PASS/FAIL 列表交差

## 字段说明 / Field Reference

### OVERALL 表核心字段

> 完整字段定义参见 `ads-diagnose` skill 的 `references/table_info.md`（UNION 表与 OVERALL 表 schema 相同）。
> 来源：[广告大盘诊断底表字段说明 GSheet](https://docs.google.com/spreadsheets/d/1XiSNynN0uFVacvqqRrcrwokcdre9qEsLyJgSKmP4M54/edit?gid=135623426#gid=135623426)

| 分类 | 字段 | 含义 | 用法 |
|------|------|------|------|
| 效果 | `revenue_usd` / `advv_usd` | 广告收入 / ADVV (USD) | 直接 SUM |
| 效果 | `ads_imp` / `ads_clk` | 广告曝光 / 点击 | 直接 SUM |
| 效果 | derived `cpm` / `cpc` / `ctr` / `adload` | 实际 CPM / CPC / 点击率 / 广告曝光渗透率 | `cpm=1000*SUM(net_ads_rev)/nullIf(SUM(ads_imp),0)`, `cpc=SUM(net_ads_rev)/nullIf(SUM(ads_clk),0)`, `ctr=SUM(ads_clk)/nullIf(SUM(ads_imp),0)`, `adload=SUM(ads_imp)/nullIf(SUM(total_imp),0)` |
| 效果 | `direct_gmv_usd` / `broad_gmv_usd` | Direct/Broad GMV (USD) | 直接 SUM |
| 效果 | `ads_direct_order` / `ads_broad_order` | Direct/Broad 订单数 | 直接 SUM |
| 预估 | `ecpm_sum_by_imp` | eCPM 之和 (按曝光) | `SUM / SUM(ads_imp)` = avg_ecpm |
| 预估 | `bid_price_sum` | 出价之和 (按曝光) | `SUM / SUM(ads_imp)` = avg_bid |
| 预估 | `item_price_sum_by_imp` | 商品价格之和 (按曝光) | `SUM / SUM(ads_imp)` = avg_item_price |
| 预估 | `coef_sum_by_imp` | PID 系数之和 (按曝光) | `SUM / SUM(ads_imp)` = avg_coef |
| 预估 | `pctr_sum_by_imp` | pCTR 之和 (按曝光) | `SUM / SUM(ads_imp)` = avg_pctr |
| 预估 | `pcr_broad_sum_by_clk` | 宽口径 pCR 之和 (按点击) | `SUM / SUM(ads_clk)` = avg_pcr |
| 预估 | `troi_sum_by_imp` | TROI 之和 (按曝光) | `SUM / SUM(ads_imp)` = avg_troi |
| 预估 | `sold_cnt_sum_by_imp` | 销量之和 (按曝光) | `SUM / SUM(ads_imp)` = avg_sold_cnt |
| 扣费 | `net_deduction_price_sum` / `valid_deduction_cnt` | 净扣费额 / 有效扣费次数 | `SUM / SUM` = avg_net_deduct |
| 扣费 | `gross_deduction_price_sum` / `raw_deduction_cnt` | 毛扣费额 / 原始扣费次数 | `SUM / SUM` = avg_gross_deduct |
| 漏斗 | `request_cnt` | 参竞请求数 | 直接 SUM |
| 漏斗 | `after_recall_num` / `after_prerank_num` / `after_rank_num` / `after_mixrank_num` | 召回/粗排/精排/混排通过数 | 直接 SUM |
| 大盘 | `net_ads_rev` / `gross_rev_usd` | 净/毛广告收入 (USD) | 直接 SUM |
| 大盘 | `platform_gmv` | 平台 GMV | 直接 SUM |
| 大盘 | `total_imp` / `total_clk` | 平台总曝光 / 总点击 | 直接 SUM |
| 维度 | `cluster` | L0 category / cluster；`ALL` 为不按 cluster 拆分总量 | 总量查询过滤 `cluster='ALL'`；L0 breakdown 过滤 `cluster!='ALL'` |
| PCOC | `daily_pgmv_pcoc` | 校准后 PCOC | 直接 SUM |
| 7d | `revenue_usd_7d` / `advv_usd_7d` / `broad_gmv_usd_7d` | 近 7 日收入/ADVV/GMV | 直接 SUM |
| 7d | `ads_imp_7d` / `ads_clk_7d` / `ads_broad_order_7d` | 近 7 日曝光/点击/订单 | 直接 SUM |

### TAKE_RATE 表

详见 `table_info.md`。
来源：[Take Rate 表字段说明 GSheet](https://docs.google.com/spreadsheets/d/1ZrYRw-jdEhdIGxF-NuRcOpKswEvqK_bscvbFtoZW1rU/edit?gid=1594221342#gid=1594221342)

TR 日常分析常用字段：

| 分类 | 字段 | 含义 | 用法 |
|------|------|------|------|
| 收入 | `gross_ads_rev_usd` | 毛广告收入 | Gross TR 分子 |
| 收入 | `net_ads_rev_usd` | 净广告收入 | Net TR / FPA revised TR 分子 |
| 券 / free credit | `free_ads_rev_usd` | 免费券收入 | Net 异常时计算 free credit contribution |
| 券 / free credit | `sip_free_credit_revenue_usd_1d` | SIP 免费券扣费金额 | Net 异常时单独展示 SIP free credit |
| 券 / voucher | `ads_voucher_ads_nmv_cost_usd` | 广告 broad 归因券成本（USD） | ROI3 voucher / FPA 口径差异分析 |
| 平台 | `platform_gmv` | 平台 GMV（local currency） | TR 分母；按广告维度聚合时必须 `SUM(DISTINCT platform_gmv)` |

## Attribution Report 组装与存档 / Report Assembly & Archive

**默认存档路径**：

```
docs/team/00.paid-ads-dev/16.ads-daily-report/{period_a}-attribution-{region}-{metric}.html
```

- `region=ALL` 时文件名使用 `ALL`。
- `metric` 保留输入中的稳定字段名，例如 `take_rate`、`net_ads_rev`、`advv`。
- 文件已存在 → 追加 `-{N}` 后缀避免覆盖（`2026-05-10-attribution-SG-take_rate-2.html`）。
- `--save-to <path>` 若未给扩展名，自动补 `.html`。
- `--no-save` 仅打印摘要不存档；完整可视化报告需要保存为 HTML。

## 归因报告 HTML 模板 / 中文模块标题

生成完整、可直接浏览器打开的 HTML 文档，不再输出 Markdown 报告。建议结构如下。HTML 中展示给用户的模块标题必须以中文为主；英文缩写可保留在括号中作为口径标识（如 TL;DR、SQL、GMV）。稳定业务 / 字段 token（如 `region`、`take_rate`、`pricingType`、`entrance`、`GMV`、`Target2.0`）不需要强行翻译，避免影响口径复查。

```html
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ads 大盘归因报告 - {period_a} - {region} - {metric}</title>
  <style>
    /* 内联 CSS：定义 header、summary cards、section、table、status chip、timeline、code block */
  </style>
</head>
<body>
  <header>
    <h1>Ads 大盘归因报告 - {region} {metric}</h1>
    <p>{period_a} vs {period_b} · consistencyMode={warn-only|strict}</p>
    <p>来源：{Detection HTML path or user request}</p>
  </header>
  <main>
    <section id="problem-definition">问题定义</section>
    <section id="data-consistency">数据一致性检查</section>
    <section id="comparison-setup">对比口径设置（TR 诊断必填：MTD MoM / DOD / 相似 GMV / 自定义）</section>
    <section id="tldr">核心结论摘要（TL;DR）</section>
    <section id="region-contribution">区域贡献度分解，仅 region=ALL 时展示</section>
    <section id="anomaly-detection">异常检测</section>
    <section id="earliest-trigger">因果链 4.A：最早触发事件</section>
    <section id="gmv-adjustment">因果链 4.A.1：GMV 节假日 / 大促校正（GMV 相关诊断必填）</section>
    <section id="propagation">因果链 4.B：传播路径</section>
    <section id="recovery-validation">因果链 4.C：恢复验证</section>
    <section id="roles">因果链 4.D：角色分类</section>
    <section id="gross-net-free-credit">毛收入 / 净收入 / Free Credit 拆解（TR 诊断必填）</section>
    <section id="l0-category">L0 Category GMV 结构拆解（TR 诊断必填；不可用时说明）</section>
    <section id="fulfillment-overbid">达标率 / Overbid-Underbid 拆解（TR 诊断条件必填）</section>
    <section id="item-order-bucket">Item Order Bucket 拆解（预算增长但使用率下降时必填）</section>
    <section id="budget-usage">预算 / 预算使用率拆解（TR / rev 诊断必填）</section>
    <section id="formula-breakdown">公式分解</section>
    <section id="action-items">排查建议</section>
    <section id="sql-appendix">
      <h2>SQL 附录</h2>
      <details>
        <summary>归因 SQL</summary>
        <pre><code>{actual_sql}</code></pre>
      </details>
    </section>
  </main>
</body>
</html>
```

### HTML 内容要求

- **来源**：如来自 Detection 报告，头部写明 `Daily Detection Report {YYYY-MM-DD}-{cycle}.html → [O{N}] {metric} — {region}`，并在可行时链接到本地 HTML。
- **问题定义**：表格列出 Period A、Period B、扩展时间窗、region、entrance、pricingType、consistencyMode、metric、direction。
- **对比口径设置**：TR 诊断必填；列出 comparisonMode、Period A/B 日期与天数、tracker benchmark 使用状态、缺失日期、加总指标是否改用 daily average 计算贡献度。
- **数据一致性检查**：必须在核心结论摘要前展示；包含 source table、normalized scope、每个 metric 的 source A / source B 值、relative diff、PASS/WARNING/FAIL、Gate、Action。
- **数据一致性警告**：若 Gate=FAIL 且 `consistencyMode=warn-only`，在核心结论摘要前放置醒目的 warning block；后续 root cause 都标注"置信度降级"。
- **数据质量警告**：若 Gate=FAIL 且 `consistencyMode=strict`，报告仍生成 HTML，但只输出数据源不一致、复查建议和 SQL 附录；不要输出 confident attribution 或 Step 4 因果链。
- **核心结论摘要（TL;DR）**：2-3 句话总结 consistency gate、trigger、传播路径、恢复验证。若降置信，明确说是 hypothesis。
- **区域贡献度分解**：仅 `region=ALL` 时展示贡献度表，并列出贡献度 ≥10% 的重点 region。
- **异常检测**：列出 O 节点、指标值、变化率、阈值。
- **因果链 4.A~4.D**：必须显式分 section 展示，不能只平铺 OR 节点。
- **因果链 4.A.1：GMV 节假日 / 大促校正**：凡 GMV 相关诊断必须作为独立 section 展示，位置在因果链 4.A 与因果链 4.B 之间。section 必须包含四选一 label、判定依据表、是否使用 `platform_gmv` 或 `broad_gmv`、以及“GMV pattern 不等于 confirmed holiday/campaign cause”的 caveat。
- **毛收入 / 净收入 / Free Credit 拆解**：TR 诊断必填；展示 gross TR、net TR、FPA revised net TR（若可得）、ROI3 voucher、free credit / SIP free credit 对 gap 的贡献。
- **L0 Category GMV 结构拆解**：TR 诊断必填；展示 source label（overall-clickhouse-cluster / broad_gmv_usd diagnostic view / tracker-benchmark / tracker-raw-fallback / proxy only）、category TR、GMV share、mix effect、own-TR effect、total effect、residual / data gap；使用 OVERALL `cluster != 'ALL'` 时必须用 `broad_gmv_usd` 作为 L0 category denominator，并明确这不是生产口径 `platform_gmv` TR。必须明确 TR drop 是 mix effect 还是 category own rate effect。若数据源不可用，写清楚未检查原因与待跑 SQL / owner。
- **达标率 / Overbid-Underbid 拆解**：当 L0 category own rate effect 为负、budget usage 下降或用户提到达标率时必填；展示 fulfillment rate、overbid revenue share、underbid revenue share、no-GMV revenue share、target ROI p50/p80/p90。若不可用，写清楚未检查原因。
- **Item Order Bucket 拆解**：当预算增长但使用率 / 达标率下降时必填；按 category × `ld_30dorder_tier` 展示 valid budget 增量、budget utilization change、fulfillment change、overbid / underbid change。
- **预算 / 预算使用率拆解**：TR / rev 诊断必填；展示 valid budget、budget usage、balance、topup、hit budget seller revenue penetration（若可得）。
- **因果链传播**：用 `<pre><code>` 展示箭头链路，或用 HTML timeline；每一步都写清楚驱动因子、受影响因子、数值变化。
- **公式分解**：按 region 用 `<table>` 展示 Period B、Period A、变化率、贡献度。
- **排查建议**：按 P0 / P1 / P2 列出具体可执行动作，不要空话。
- **SQL 附录**：必填，所有实际跑过的 SQL 放入 `<details><summary>归因 SQL</summary><pre><code>...</code></pre></details>`。

### HTML 硬性规则

1. 输出文件必须是 `.html`，且可直接 `open <path>` 本地打开。
2. 不要依赖外部 CSS/JS/图片；所有样式写在 `<style>` 中。
3. 指标表必须使用 `<table>`；数值列右对齐；长表在移动端允许横向滚动。
4. 状态必须用文字标签表达（PASS / WARNING / FAIL、高/中/低置信），不要只靠颜色或图标。
5. 日期必须直显，例如 `2026-05-10`，不要只写 `Period A` / `Period B`。
6. 归因结论必须保留证据链：trigger → propagation → observed anomaly → recovery validation。
