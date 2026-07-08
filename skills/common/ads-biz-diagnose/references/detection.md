# Detection 模式 / Detection Mode

> Daily Detection Report 生成规范。由 SKILL.md mode 分发后进入此流程。
> 复用：`factual_nodes.md`（O1-O17 阈值规则）、`table_info.md`（表 schema）、`data_consistency.md`（大盘数据源一致性 gate）。

## 输入 / Input

支持两种入参方式：

### 自然语言入参

例：`"跑下今天大盘日报"` / `"看下昨天有没有异常"` → LLM 解析为 cycle=daily（默认）。

### 命令式入参 / Command Form

```
/ads-biz-diagnose detect cycle=<C> [consistencyMode=<warn-only|strict>] [--drill region=<R1,R2,...|all>] [--save-to <path>] [--no-save]
```

| 参数 | 必填 | 取值 | 说明 |
|------|------|------|------|
| `cycle` | 是（默认 `daily`） | `daily` / `wtd` / `weekly` / `mtd` | 扫描周期 |
| `consistencyMode` | 否 | `warn-only` / `strict` | 默认 `warn-only`。`warn-only` 下 consistency `FAIL` 只降级置信度并继续输出异常；`strict` 下受影响 metric/scope 不标高可信、不附 confident attribution 命令 |
| `--drill region=<list>` | 否 | 单 region / 逗号分隔多 region / `all`（命中异常的 region） | 触发 entrance + pricing_type 拆分子流程 |
| `--save-to <path>` | 否 | HTML 文件路径 | 覆盖默认存档路径；未给扩展名时自动补 `.html` |
| `--no-save` | 否 | flag | 仅打印摘要不存档 |

## 时区约定 / Timezone

所有"昨日 / 本周一 / 本月 1 号 / 上月同日"等相对日期统一按 **Asia/Singapore (UTC+8)** 计算，与 ClickHouse `toDate()` 和团队报表习惯一致。

## 周期与基线 / Cycle & Baselines

| 周期 | Period A (当前) | B1 主基线 | B2 次基线 | 判定模式 |
|------|----------------|----------|----------|---------|
| **daily** | 昨日 | 上周同日 (WoW DoD) | 前天 (DoD) | 双命中分级 |
| **wtd** | 本周一 → 昨日 | 上周一 → 上周对应日 | (无) | 单基线，命中即列出 |
| **weekly** | 上完整周 (周一~周日) | 前一周 (WoW) | 4 周前同期 (4WoW) | 双命中分级 |
| **mtd** | 本月 1 号 → 昨日 | 上月 1 号 → 上月同日 | (无) | 单基线，命中即列出 |

**为什么 daily 主基线选 WoW DoD 而非 DoD**：广告大盘有强星期效应（周末 vs 工作日），DoD 直接比会被周期性误报；WoW DoD 消除星期效应。DoD 作为次基线捕捉真实突变。

**双命中分级规则**（仅 daily / weekly）：

- A vs B1 命中阈值 **且** A vs B2 命中**同一 O 节点** → **高可信异常**
- 仅一条命中 → **待观察**

**单基线模式**（wtd / mtd）：所有命中归为"异常"，不做高/低分级。

## 边界处理 / Edge Cases

| 场景 | 处理 |
|------|------|
| WTD 周一调用 | A=仅周一，B=上周一（等同 daily WoW，但保留 wtd 命名让用户知道意图） |
| MTD 月初 1 号调用 | A 无数据，跳过并提示用户改用 daily/wtd |
| daily 月初调用（如 2026-05-01） | A=2026-04-30（上月末），B1=上周同日、B2=前天（跨月正常）。日期算法不区分月份，跨月不特殊处理 |
| 指定 drill region 不存在 | 报错提示，不静默跳过 |
| ClickHouse 查询失败 | 报告中显式标注 "数据获取失败"，列出失败的 region/集群，**不**在汇总中作"正常"处理 |
| OVERALL 表 Period A 数据未 ready (max_date < period_a_last_date) | **报错退出，不生成报告**。错误信息须包含 max_date / 期望 period_a / cycle / 延迟天数。这是有意的 fail-fast — 强制暴露 pipeline 延迟问题，避免静默用旧数据骗用户 |
| Macro consistency check FAIL | 报告中先展示 Data Consistency Check。默认 `warn-only`：继续输出异常并附 attribution 命令，但 status / notes 必须标注"因数据源一致性 FAIL，置信度降级"；`strict`：受影响 metric/scope 不得标为高可信异常，也不附 confident attribution 命令，改为 data-source inconsistency 和复查建议 |

## 拉数策略 / Data Fetch (Once-and-Done)

### Step 0: Freshness Check（必跑，先于任何 OVERALL 查询）

拉数前**必须先**探测一次 OVERALL 表的最新可用日期，与 cycle 期望的 Period A 最后一天对齐：

```bash
curl -s -u 'mkplpaidads_search_ads-cluster_mkplpaidads_mkplpaidads_search_ads_online:b46o8QVbhaN5' \
  --data-binary "SELECT max(grass_date) AS max_date FROM mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live WHERE grass_date >= today() - 30 FORMAT TabSeparatedWithNames" \
  'https://clickhouse-office-only-ytl.data-infra.shopee.io'
```

期望 Period A 最后一天（按 cycle 计算，Asia/Singapore 时区）：

| Cycle | period_a_last_date |
|-------|---------------------|
| daily | 昨日 |
| wtd   | 昨日 |
| weekly | 上周日 |
| mtd   | 昨日 |

判定规则：

- `max_date >= period_a_last_date` → 通过，继续拉数
- `max_date < period_a_last_date` → **报错退出**，不再发任何 OVERALL 查询，不生成报告

错误消息模板：

```
❌ Data not ready: ads_overall_key_metrics_daily__reg_s0_live
   - 最新可用日期 (max_date): {max_date}
   - cycle={cycle} 期望 Period A 最后一天: {period_a_last_date}
   - 延迟天数: {today - max_date}

跑 daily report 需要 Period A 数据已 ready。skill 不会用更旧的数据生成报告。
建议：
1. 联系 ads data team 排查 ads_overall_key_metrics_daily 表 pipeline 延迟
2. 等数据 ready 后重跑
```

### SG 集群单查询（覆盖全部 8 region 含 BR）

**Step 0 Freshness Check 通过后**，先执行 `data_consistency.md` 的 macro data consistency check（大盘数据一致性检查），再一次性拉 `[B1_start, A_end]` 区间全 region 数据。不在 SQL 里写阈值，避免 N+1 查询。

> OVERALL 表在 SG 集群完整覆盖 ID / TH / PH / VN / MY / TW / SG / **BR** 全部 8 个 region，**不需要**为 BR 单独走 US-VA2 集群。US-VA2 集群只承载 UNION 表的 BR 数据。
```bash
curl -s -u 'mkplpaidads_search_ads-cluster_mkplpaidads_mkplpaidads_search_ads_online:b46o8QVbhaN5' \
  --data-binary @- \
  'https://clickhouse-office-only-ytl.data-infra.shopee.io' <<'SQL'
SELECT grass_date, grass_region,
    SUM(net_ads_rev) AS sum_net_ads_rev,
    SUM(advv_usd) AS sum_advv,
    SUM(platform_gmv) AS sum_platform_gmv,
    SUM(total_imp) AS sum_platform_imp,
    SUM(ads_imp) AS sum_ads_imp,
    SUM(ads_clk) AS sum_ads_clk,
    SUM(direct_gmv_usd) AS sum_direct_gmv,
    SUM(broad_gmv_usd) AS sum_broad_gmv,
    SUM(ads_direct_order) AS sum_direct_order,
    SUM(ads_broad_order) AS sum_broad_order,
    SUM(net_ads_rev) / nullIf(SUM(platform_gmv), 0) AS take_rate,
    1000 * SUM(net_ads_rev) / nullIf(SUM(ads_imp), 0) AS cpm,
    SUM(net_ads_rev) / nullIf(SUM(ads_clk), 0) AS cpc,
    SUM(ads_clk) / nullIf(SUM(ads_imp), 0) AS ctr,
    SUM(ads_imp) / nullIf(SUM(total_imp), 0) AS adload
FROM mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live
WHERE grass_date BETWEEN toDate('{B1_start}') AND toDate('{A_end}')
    AND entrance = 'ALL'
    AND pricing_type = 'ALL'
GROUP BY grass_date, grass_region
ORDER BY grass_date ASC, grass_region ASC
FORMAT TabSeparatedWithNames
SQL
```

> 结果集会包含一个 `grass_region = 'ALL'` 的预聚合行，客户端判定时需 **过滤掉**（避免与 8 个具体 region 重复计算）。
### SUPPLY_BUDGET 表（按需拉取，OR7 / OR11 涉及时）

仅在 SG 集群，覆盖全部 region（含 BR）。查询模板见 `table_info.md` 第 10 节。

## 客户端判定 / Client-Side Judgment

不允许 LLM 心算 — 阈值比较涉及多 region × 多节点 × 多基线，手算容易出错且不可复现。

客户端判定必须合并 consistency gate：

- 对 `PASS` scope：正常判定 O1-O17。
- 对 `WARNING` scope：可列异常，但 status / notes 必须写"因数据源一致性 WARNING，置信度降级"。
- 对 `FAIL` scope：
  - `warn-only`（默认）：可列异常和 attribution command，但 status / notes 必须写"因数据源一致性 FAIL，置信度降级"。
  - `strict`：受影响 metric 不得进入"高可信异常"；将该行列入 Data Consistency Check / Data Quality Warning，不生成 confident attribution command。

LLM 拿到 `TabSeparatedWithNames` 结果后，**通过 `uv run` 跑一段 PEP 723 inline-deps Python 脚本**做同环比与阈值比较。脚本片段示例（不存档到 `scripts/`，每次运行临时生成）：

```python
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "pandas>=2.0",
# ]
# ///
import pandas as pd
import sys, json
from io import StringIO

# 输入：通过 stdin 传入 TabSeparatedWithNames 结果
df = pd.read_csv(StringIO(sys.stdin.read()), sep="\t")

# O1-O17 阈值表（与 factual_nodes.md 严格一致）
# 列名与上面 SQL 的 alias 对齐（sum_* 前缀避免与原列同名导致 ILLEGAL_AGGREGATION）
THRESHOLDS = {
    "O1_take_rate_down": ("take_rate", "down", -0.005),
    "O2_take_rate_up":   ("take_rate", "up",   +0.005),
    "O3_rev_down":       ("sum_net_ads_rev", "down", -0.01),
    "O4_rev_up":         ("sum_net_ads_rev", "up",   +0.01),
    "O5_advv_down":      ("sum_advv", "down", -0.05),
    "O6_advv_up":        ("sum_advv", "up",   +0.05),
    "O7_platform_gmv_down": ("sum_platform_gmv", "down", -0.02),
    # ... O8-O13 详见 factual_nodes.md
    "O14_cpm_down":      ("cpm", "down", -0.05),
    "O15_cpm_up":        ("cpm", "up",   +0.05),
    "O16_cpc_down":      ("cpc", "down", -0.05),
    "O17_cpc_up":        ("cpc", "up",   +0.05),
}

period_a_date = sys.argv[1]
b1_date = sys.argv[2]
b2_date = sys.argv[3] if len(sys.argv) > 3 else None

results = []
for region, g in df.groupby("grass_region"):
    if region == "ALL":
        continue  # 跳过预聚合行，避免与 8 个具体 region 重复计算
    a_row = g[g["grass_date"] == period_a_date].iloc[0]
    b1_row = g[g["grass_date"] == b1_date].iloc[0]
    b2_row = g[g["grass_date"] == b2_date].iloc[0] if b2_date else None
    for o_id, (col, direction, thr) in THRESHOLDS.items():
        delta_b1 = a_row[col] / b1_row[col] - 1
        hit_b1 = (direction == "down" and delta_b1 < thr) or \
                 (direction == "up"   and delta_b1 > thr)
        delta_b2 = None
        hit_b2 = False
        if b2_row is not None:
            delta_b2 = a_row[col] / b2_row[col] - 1
            hit_b2 = (direction == "down" and delta_b2 < thr) or \
                     (direction == "up"   and delta_b2 > thr)
            grade = "high" if (hit_b1 and hit_b2) else ("watch" if (hit_b1 or hit_b2) else None)
        else:
            grade = "anomaly" if hit_b1 else None
        if grade:
            results.append({
                "region": region, "node": o_id, "metric": col,
                "a_value": float(a_row[col]),
                "b1_value": float(b1_row[col]),
                "delta_b1_pct": round(delta_b1 * 100, 2),
                "b2_value": float(b2_row[col]) if b2_row is not None else None,
                "delta_b2_pct": round(delta_b2 * 100, 2) if b2_row is not None else None,
                "threshold_pct": round(thr * 100, 2),
                "grade": grade,
            })

print(json.dumps(results, indent=2))
```

调用：

```bash
echo "$CH_RESULT" | uv run /tmp/judge.py 2026-04-26 2026-04-19 2026-04-25
```

LLM 解析 JSON 输出后组装报告。

## Drill 子流程 / Drill Sub-flow

`--drill region=...` 时触发，对指定 region 重新拉一次按 `(entrance)` 和 `(pricing_type)` 分组的 OVERALL 数据，重跑 O1-O17 判定。

**蓝色指标跳过 entrance 拆分**：`O7 platform_gmv`、`O11 ads_seller_gmv占比`、`O12 ads_item_gmv占比`、`O13 broad_gmv占比` 在广告维度重复，不参与 entrance 拆分。

下钻粒度规则：

- 总量报告：`entrance = 'ALL' AND pricing_type = 'ALL'`。
- Entrance 下钻：`pricing_type = 'ALL'`，`entrance != 'ALL'`，按 `entrance` 分组。
- Pricing-type 下钻：`entrance = 'ALL'`，`pricing_type != 'ALL'`，按 `pricing_type` 分组。
- 交叉下钻：仅在用户明确请求时使用 `entrance != 'ALL' AND pricing_type != 'ALL'`。
- 不要在同一个分组结果中混合 `ALL` 行和明细行。

drill 形式：

- `--drill region=ID` — 单 region
- `--drill region=ID,TH,VN` — 多 region（逗号分隔）
- `--drill all` — 对所有"命中异常的 region"下钻（不命中的不浪费 SQL）

drill 结果以子节形式附在主报告对应 region 下方（见报告模板）。

## 报告组装与存档 / Report Assembly & Archive

**默认存档路径**：

```
docs/team/00.paid-ads-dev/16.ads-daily-report/{periodA最后一天}-{cycle}.html
```

- `daily` / `wtd` / `mtd` → 用昨日日期
- `weekly` → 用上周日日期
- 文件已存在 → 追加 `-{N}` 后缀避免覆盖（`2026-04-26-daily-2.html`）

**入参覆盖**：

- `--save-to <path>` — 覆盖默认路径；若未给扩展名，自动补 `.html`
- `--no-save` — 仅打印摘要不存档；完整可视化报告需要保存为 HTML

## Daily Detection Report HTML 模板 / Output Template

生成完整、可直接浏览器打开的 HTML 文档，不再输出 Markdown 报告。建议结构如下：

```html
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ads 大盘异常日报 - {periodA_last_date}</title>
  <style>
    /* 内联 CSS：定义页面宽度、section、table、status chip、数值右对齐、移动端横向滚动表格 */
  </style>
</head>
<body>
  <header>
    <h1>Ads 大盘异常日报 - {periodA_last_date}</h1>
    <p>Daily Detection · {cycle} · Skill ads-biz-diagnose @ {commit-sha}</p>
  </header>
  <main>
    <section id="core-summary">核心结论 + 关键 KPI 卡片</section>
    <section id="scan-config">扫描配置表</section>
    <section id="data-consistency">Data Consistency Check 表 + Gate 说明</section>
    <section id="global-result">Global 大盘结果表</section>
    <section id="high-confidence-findings">高可信异常表</section>
    <section id="watch-list">待观察异常表</section>
    <section id="normal-regions">正常 region</section>
    <section id="drill-result">可选 drill 结果</section>
    <section id="next-actions">每条异常对应的可执行 attribution 命令</section>
    <section id="sql-appendix">
      <details>
        <summary>扫描 SQL</summary>
        <pre><code>{actual_sql}</code></pre>
      </details>
    </section>
  </main>
</body>
</html>
```

### HTML 内容要求

- **Core Summary**：用 2-4 句话先讲业务结论，说明是收入型异常、效率型异常、结构稀释，还是数据一致性风险。
- **Scan Configuration**：表格列出 cycle、具体日期、基线、region、consistencyMode、drill、生成时间、commit sha。日期必须直显，例如 `2026-04-23`，不要只写 `A / B1 / B2`。
- **Data Consistency Check**：必须在大盘结论前展示；包含 source table、scope、每个 region/metric 的 PASS/WARNING/FAIL、Gate、Action。若 `FAIL` 且 `warn-only`，后续所有受影响结论标注"置信度降级"。
- **Summary / Global Result**：用 KPI 卡片或总览表展示核心指标当前值、WoW、DoD 和命中节点。
- **High Confidence Findings**：双基线命中才进入该 section；每条异常给 O 节点、指标值、WoW、DoD、阈值、置信度、attribution 命令。
- **Watch List**：单基线命中进入该 section，固定说明："单基线命中可能是周中波动，建议观察后续数据"。
- **Drill Result**：仅 `--drill` 时展示，按 region 分组展示 entrance / pricing_type 拆分表。
- **Appendix SQL**：必填，放入 `<details><summary>扫描 SQL</summary><pre><code>...</code></pre></details>`，便于人工复跑 verify。

**模板硬性规则**：

1. 输出文件必须是 `.html`，且可直接 `open <path>` 本地打开。
2. 不要依赖外部 CSS/JS/图片；所有样式写在 `<style>` 中。
3. 指标表必须使用 `<table>`；数值列右对齐；长表在移动端允许横向滚动。
4. 状态必须用文字标签表达（PASS / WARNING / FAIL、高/中/低置信），不要只靠颜色或图标。
5. **"待观察"建议语为固定模板话术**："单基线命中可能是周中波动，建议观察后续数据"。LLM 只填数值，**不**自由发挥。
6. Appendix SQL **必填**，便于人工复跑 verify。
7. 若 cycle ∈ {wtd, mtd}（单基线模式），将"高可信异常"和"待观察"两个 section 合并为单一"异常"section；标题模板话术中"双基线命中"改为"单基线命中"。
8. **日期直显**：表头和 Scan Configuration 必须使用具体日期（如 `2026-04-23`），**不**使用 `A / B1 / B2` 等抽象代号；保留 `WoW` / `DoD` 等基线性质标签辅助阅读。
