# Macro Data Consistency Check / 大盘数据一致性检查

在 Detection 或 Attribution 使用大盘指标前，必须先执行本检查。它的作用是衡量不同数据源的指标值是否一致，并据此控制异常判断和根因归因的置信度。

## Table Alias Legend / 表别名说明

`OVERALL`、`TAKE_RATE`、`UNION`、`SUPPLY_BUDGET` 是本 skill 使用的表别名。面向用户或管理层的报告中，不要假设读者知道这些是表；首次 Data Consistency Check 前必须加一段简短说明：

```markdown
数据源 / Table sources:
- OVERALL table = `mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live` (ClickHouse)
- TAKE_RATE table = `mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live` (ClickHouse)
```

说明之后，报告表格和正文都使用 `OVERALL table` / `TAKE_RATE table` 这类明确标签，不要直接写裸别名 `OVERALL` / `TAKE_RATE`。例如，写 `TAKE_RATE table broad GMV moved +5.25%`，不要写 `TAKE_RATE broad GMV moved +5.25%`。

## Consistency Modes / 一致性模式

`consistencyMode` 控制 workflow 如何处理数据源差异。默认值是 `warn-only`。

| Mode / 模式 | Default / 默认 | Behavior / 行为 |
|------|---------|----------|
| `warn-only` | Yes | Data Consistency Check 后继续 detection 或 attribution。若任一检查指标为 `WARNING` 或 `FAIL`，保留原始 metric status，展示醒目 warning，并将所有受影响的异常 / 根因结论标注为"置信度降级"。 |
| `strict` | No | 阻断模式。若诊断指标或核心分解指标为 `FAIL`，则停止该 scope 下的 confident attribution，输出 Data Quality Warning，不继续做 root-cause attribution。 |

在 `warn-only` 模式下，`FAIL` 不是被忽略。报告必须说明大盘数据源存在差异，列出受影响指标，并将后续根因表述为基于主分析数据源的低置信度假设。若两个数据源方向冲突，或某个数据源缺失诊断指标，继续前必须明确标注为严重一致性 warning。

在 `strict` 模式下，保留历史 fail-fast 行为：`FAIL` 会阻断 confident attribution，且受影响的 Detection finding 不能标为高可信。

## Gate Rule / Gate 规则

大盘诊断开始前必须先完成本检查。

默认必检指标为 `ads_rev`、`broad_gmv`、`take_rate`。`cpm` 和 `cpc` 是条件必检指标：仅当用户请求诊断 `metric=cpm` / `metric=cpc`，或 attribution / detection 结论使用 CPM / CPC 作为核心证据时才加入本检查。与 CPM / CPC 无关的 take_rate、advv、platform_gmv 等诊断不需要额外执行 CPM / CPC consistency check。

下面的阈值用于生成 metric status；workflow 行为由 `consistencyMode` 决定。

| Gate status | Meaning / 含义 | Warn-only behavior | Strict behavior |
|-------------|---------|--------------------|-----------------|
| `PASS` | 所有检查指标都在 PASS 阈值内。 | 正常继续 detection 或 attribution。 | 正常继续 detection 或 attribution。 |
| `WARNING` | 至少一个非目标辅助指标差异在 1%-3%，或某个非目标可比指标在一个数据源中不可用。 | 继续分析，但降级置信度，并在每个受影响结论旁标注 caveat。 | 继续分析，但降级置信度，并在每个受影响结论旁标注 caveat。 |
| `FAIL` | 任一检查指标差异超过 3%，两个数据源对诊断指标方向冲突，或诊断指标在某个数据源不可用。 | 继续分析，但必须展示醒目的数据源 warning。根因结论必须标注为置信度降级的 hypothesis。 | 停止 affected metric/scope 的 confident attribution。报告数据源不一致，并给出 data-quality next steps，不继续 root-cause attribution。 |

如果 source A 显示某指标下降，而 source B 显示持平或反向变化，即使绝对值差异接近边界，也要将该指标标为 `FAIL`。在 `warn-only` 模式下，必须先显式说明方向冲突，再继续归因。

## Scope Normalization / Scope 对齐

比较数值前，所有数据源查询必须对齐到完全相同的 comparison scope。

| Scope field | Required normalization / 对齐要求 |
|-------------|------------------------|
| Date | 使用相同的 `period_a` 与 `period_b` calendar dates。多日周期先按天聚合，处理好 platform-side 重复行后，再比较 period totals。 |
| Region | 使用相同的 `grass_region`。`region=ALL` 时，先比较各具体 region，再过滤 `OVERALL table` 的 `ALL` 预聚合重复行后汇总全 region。 |
| Entrance | 用户 scope 为 all entrances 时，`OVERALL table` 使用 `entrance = 'ALL'`。非 ALL entrance 时，将 `TAKE_RATE table` 的 `traffic_type` / `entry_point` 映射到同一入口，不混入其他入口。 |
| Pricing type | 用户 scope 为 all pricing types 时，`OVERALL table` 使用 `pricing_type = 'ALL'`。非 ALL pricing type 时，将 `TAKE_RATE table` 的 integer `pricing_type` 映射到同一产品线。 |
| Timezone | 默认使用 `TAKE_RATE table` 的 `tz_type = 'regional'`，除非用户明确要求 local-time product-specific view。报告中必须说明使用的 timezone。 |
| Currency | 只比较同币种值。`ads_rev` 和 `broad_gmv` 默认使用 USD。计算 `take_rate` 时不要把 USD revenue 与 local-currency denominator 当成同币种比较；若缺少同币种分母，将该指标标为 `WARNING`，note 写 `not_comparable`。 |
| Aggregation grain | 在最终诊断粒度上比较：date 或 period、region、entrance、pricing type。不要把明细行和 `ALL` 预聚合行混在同一次比较中。 |

## Metric Mapping / 指标映射

一致性检查输出中使用稳定 alias。

| Normalized metric | Source A: OVERALL table (ClickHouse) | Source B: TAKE_RATE table (ClickHouse) | Notes / 备注 |
|-------------------|------------------------------|----------------------------------|-------|
| `ads_rev` | 主业务行按天去重后的 `net_ads_rev` | `SUM(net_ads_rev_usd)` | 保持 net revenue 口径一致。不要拿 `OVERALL table` 的 net revenue 和 `TAKE_RATE table` 的 gross revenue 比较。`OVERALL table` 在 `entrance='ALL' AND pricing_type='ALL'` 下可能有 supplemental duplicate rows；未按天去重前不要直接 `SUM(net_ads_rev)`。 |
| `broad_gmv` | 主业务行按天去重后的 `broad_gmv_usd` | `SUM(broad_order_gmv_usd)` | 用它做跨数据源 value check，而不是直接校验 ADVV。两边都必须是 USD broad-attribution GMV；不要与 local-currency GMV 或 direct GMV 比较。 |
| `take_rate` | 去重后的 `net_ads_rev / platform_gmv` | `SUM(net_ads_rev_usd) / SUM(DISTINCT platform_gmv)` | 校验当前生产 take-rate 定义。注意 `TAKE_RATE table` 的 `platform_gmv` 是 local currency，报告 note 写 `currency_mixed_definition`。若用户要求真正同币种 USD ratio，而 `OVERALL table` 没有可比 USD platform GMV 字段，则标为 `WARNING`，note 写 `not_comparable_usd_denominator`。 |
| `cpm` | `1000 * 去重后的 net_ads_rev / nullIf(去重后的 ads_imp, 0)` | `1000 * SUM(net_ads_rev_usd) / nullIf(SUM(ads_imp), 0)` | 条件检查。使用 net revenue，保持与 normalized `ads_rev` 一致。不要用 `avg_ecpm` 代替 realized CPM。 |
| `cpc` | `去重后的 net_ads_rev / nullIf(去重后的 ads_clk, 0)` | `SUM(net_ads_rev_usd) / nullIf(SUM(ads_click), 0)` | 条件检查。使用 net revenue，保持与 normalized `ads_rev` 一致。点击字段口径必须对齐为去重点击。 |

## Thresholds / 阈值

relative difference 计算方式：

```
relative_diff = abs(source_a_value - source_b_value) / max(abs(source_a_value), abs(source_b_value))
```

零值处理：

- 合法 no-data scope 下两边都是 `0` 或 `NULL`：`PASS`，note 写 `both_zero`；
- 一边为 `0`、另一边非零：`FAIL`；
- 两边都非零但 denominator 很小：展示绝对值，并至少标为 `WARNING`。

状态阈值：

| Relative diff | Status |
|---------------|--------|
| `<= 1%` | `PASS` |
| `> 1%` and `<= 3%` | `WARNING` |
| `> 3%` | `FAIL` |

## Source A SQL: OVERALL Table

`OVERALL table` 使用 SG ClickHouse 集群：`mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live`。

`OVERALL table` 在同一个 `(grass_date, grass_region, entrance, pricing_type)` normalized scope 下可能有多行。实际数据中，`entrance='ALL' AND pricing_type='ALL'` 可能同时存在 primary row 和 supplemental row，且两行 `platform_gmv` 相同。因此 period 聚合前必须先按天去重。

```sql
WITH daily AS (
    SELECT
        multiIf(
            grass_date BETWEEN toDate('{period_a_start}') AND toDate('{period_a_end}'), 'period_a',
            grass_date BETWEEN toDate('{period_b_start}') AND toDate('{period_b_end}'), 'period_b',
            'other'
        ) AS period_label,
        grass_date,
        grass_region,
        -- 选择 primary business row。观察到 supplemental duplicate row 的 gross_rev_usd = 0；
        -- 对合法全零 scope，argMax 也保持定义良好。
        argMax(net_ads_rev, gross_rev_usd) AS ads_rev,
        argMax(broad_gmv_usd, gross_rev_usd) AS broad_gmv,
        argMax(ads_imp, gross_rev_usd) AS ads_imp,
        argMax(ads_clk, gross_rev_usd) AS ads_clk,
        max(platform_gmv) AS platform_gmv,
        count() AS raw_row_count
    FROM mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live
    WHERE (
            grass_date BETWEEN toDate('{period_a_start}') AND toDate('{period_a_end}')
            OR grass_date BETWEEN toDate('{period_b_start}') AND toDate('{period_b_end}')
        )
        AND grass_region = '{region}'
        AND entrance = '{overall_entrance}'
        AND pricing_type = '{overall_pricing_type}'
    GROUP BY period_label, grass_date, grass_region
)
SELECT
    period_label,
    grass_region,
    SUM(ads_rev) AS ads_rev,
    SUM(broad_gmv) AS broad_gmv,
    SUM(ads_imp) AS ads_imp,
    SUM(ads_clk) AS ads_clk,
    SUM(platform_gmv) AS platform_gmv,
    SUM(ads_rev) / nullIf(SUM(platform_gmv), 0) AS take_rate,
    1000 * SUM(ads_rev) / nullIf(SUM(ads_imp), 0) AS cpm,
    SUM(ads_rev) / nullIf(SUM(ads_clk), 0) AS cpc,
    max(raw_row_count) AS max_raw_rows_per_day
FROM daily
WHERE period_label != 'other'
GROUP BY period_label, grass_region
ORDER BY period_label, grass_region
```

Detection 场景若包含 `period_a`、`b1` 和可选 `b2`，扩展 `multiIf` label，并将 `period_a` 分别与每个 baseline 比较。

`region=ALL` 时，将 `grass_region = '{region}'` 替换为 `grass_region != 'ALL'`，先比较每个具体 region，再从这些具体 region 汇总全 region。不要直接与 `OVERALL table` 的预聚合 `ALL` 行比较，除非所有数据源都有定义一致的同类预聚合行。

## Source B SQL: TAKE_RATE Table

`TAKE_RATE table` 使用 SG ClickHouse 集群：`mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live`。`daily` CTE 用于避免 `SUM(DISTINCT platform_gmv)` 在不同日期 GMV 数值相等时误去重。

查询前先做 partition freshness check：对目标 `grass_date` / `grass_region` / `tz_type` 检查 `count() > 0`。若目标 partition 缺失，不要切换到其他查询引擎补数；在 `warn-only` 下输出 Data Consistency Warning 并继续低置信度分析，在 `strict` 下停止 confident attribution。

```sql
WITH daily AS (
    SELECT
        grass_date,
        grass_region,
        SUM(net_ads_rev_usd) AS ads_rev,
        SUM(broad_order_gmv_usd) AS broad_gmv,
        SUM(ads_imp) AS ads_imp,
        SUM(ads_click) AS ads_clk,
        -- platform_gmv 是 local currency。它匹配当前生产 take_rate 定义，
        -- 但报告中必须标注 currency_mixed_definition。
        SUM(DISTINCT platform_gmv) AS platform_gmv
    FROM mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live
    WHERE (
            grass_date BETWEEN toDate('{period_a_start}') AND toDate('{period_a_end}')
            OR grass_date BETWEEN toDate('{period_b_start}') AND toDate('{period_b_end}')
        )
        AND tz_type = 'regional'
        AND grass_region = '{region}'
        -- 用户 scope 非 ALL 时，在这里增加 normalized entrance / pricing_type 过滤。
    GROUP BY 1, 2
),
labeled AS (
    SELECT
        CASE
            WHEN grass_date BETWEEN toDate('{period_a_start}') AND toDate('{period_a_end}') THEN 'period_a'
            WHEN grass_date BETWEEN toDate('{period_b_start}') AND toDate('{period_b_end}') THEN 'period_b'
        END AS period_label,
        grass_region,
        ads_rev,
        broad_gmv,
        ads_imp,
        ads_clk,
        platform_gmv
    FROM daily
)
SELECT
    period_label,
    grass_region,
    SUM(ads_rev) AS ads_rev,
    SUM(broad_gmv) AS broad_gmv,
    SUM(ads_imp) AS ads_imp,
    SUM(ads_clk) AS ads_clk,
    SUM(platform_gmv) AS platform_gmv,
    SUM(ads_rev) / nullIf(SUM(platform_gmv), 0) AS take_rate,
    1000 * SUM(ads_rev) / nullIf(SUM(ads_imp), 0) AS cpm,
    SUM(ads_rev) / nullIf(SUM(ads_clk), 0) AS cpc
FROM labeled
WHERE period_label IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2
```

## Comparison Output / 对比输出

每份 Detection 或 Attribution 报告都必须在大盘诊断结论前包含本 section。

```markdown
### Data Consistency Check / 数据一致性检查

Mode / 模式: {warn-only|strict}; Scope / 范围: date={period_a} vs {period_b}; region={region}; entrance={entrance}; pricingType={pricingType}; timezone=regional; currency={USD revenue/broad_gmv, local platform_gmv for production take_rate}; grain={daily|period}

数据源 / Table sources:
- OVERALL table = `mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live` (ClickHouse)
- TAKE_RATE table = `mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live` (ClickHouse)

| Metric / 指标 | OVERALL table | TAKE_RATE table | Relative diff / 相对差异 | Status / 状态 | Note / 备注 |
|--------|---------|-----------|---------------|--------|------|
| ads_rev | ... | ... | ... | PASS/WARNING/FAIL | ... |
| broad_gmv | ... | ... | ... | PASS/WARNING/FAIL | ... |
| take_rate | ... | ... | ... | PASS/WARNING/FAIL | ... |
| cpm | ... | ... | ... | PASS/WARNING/FAIL | 条件检查：仅当请求或证据使用 CPM |
| cpc | ... | ... | ... | PASS/WARNING/FAIL | 条件检查：仅当请求或证据使用 CPC |

Gate / 结论: {PASS/WARNING/FAIL}; Action / 动作: {continue|continue_with_warning|strict_stop}
```

当 `Gate: FAIL` 且 `consistencyMode=warn-only` 时，下一段必须先输出 warning，然后才可继续归因：

```markdown
### Data Consistency Warning / 数据一致性 Warning

上述 normalized scope 下，{metric} 的大盘数据源存在差异。由于 `consistencyMode=warn-only`，本报告会继续归因，但受影响的根因结论均需要标注"置信度降级"，在数据源差异解决前只能视为假设。

建议复查：
1. 确认两个数据源在 {period_a} 和 {period_b} 的 pipeline 都已完成。
2. 确认 TAKE_RATE table 在目标 date / region / tz_type partition 下有数据，且 revenue net/gross、broad GMV 字段映射、voucher、timezone、currency、platform GMV 分母定义一致。
3. 数据 owner 确认正确口径后，用 appendix 中同 scope SQL 重新拉数。
```

当 `Gate: FAIL` 且 `consistencyMode=strict` 时，下一段必须是 data-quality warning，不进入 root-cause attribution：

```markdown
### Data Quality Warning / 数据质量 Warning

上述 normalized scope 下，{metric} 的大盘数据源存在差异。由于 `consistencyMode=strict`，本报告不输出 confident attribution。

建议复查：
1. 确认两个数据源在 {period_a} 和 {period_b} 的 pipeline 都已完成。
2. 确认 TAKE_RATE table 在目标 date / region / tz_type partition 下有数据，且 revenue net/gross、broad GMV 字段映射、voucher、timezone、currency、platform GMV 分母定义一致。
3. 数据 owner 确认正确口径后，用 appendix 中同 scope SQL 重新拉数。
```
