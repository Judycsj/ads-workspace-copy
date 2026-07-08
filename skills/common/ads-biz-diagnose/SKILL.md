---
name: ads-biz-diagnose
description: >
  广告大盘异常诊断与归因 (Ads business-level diagnosis & attribution) — 支持
  Detection（按 daily/wtd/weekly/mtd 周期扫描大盘异常生成 HTML 日报）和
  Attribution（对已知异常做多层归因生成 HTML 深度报告）两种模式。
  TRIGGER (Detection) when: user mentions "daily report", "日报", "wtd", "周报",
  "MTD 报告", "扫描大盘", "大盘巡检", "biz check", "大盘 review", "有没有异常",
  "看下今天大盘", "跑一下大盘异常", "大盘日报", "大盘扫描", or asks to scan
  overall ads metrics for anomalies on a periodic basis.
  TRIGGER (Attribution) when: user mentions "大盘诊断", "大盘归因", "大盘异常",
  "biz-diagnose", "ads-biz-diagnose", "take_rate 跌", "rev 跌", "advv 跌",
  "platform_gmv 异常", "budget 异常", "余额异常", "active advertiser 下滑",
  "hit budget", "hit balance", "激励影响", "TR miss", "TR tracker", "MTD MoM",
  "DOD", "gross TR", "net TR", "free credit", "L0 category", "达标率",
  "fulfillment", "overbid", "underbid", "大盘下降", "大盘上涨",
  "region 归因", "entrance 归因", "pricingType 归因", "广告大盘", or asks to diagnose a known overall ads
  metric anomaly.
  DO NOT TRIGGER when: diagnosing a specific ads_id/campaign_id/shop_id anomaly
  (use ads-diagnose), running ad-hoc SQL queries without anomaly context (use
  ads-text2da).
---

# 广告大盘诊断 Skill / Ads Biz Diagnose Skill

本 skill 承载两个相关但独立的工作流：**Detection**（主动扫描，预防线上问题）和 **Attribution**（对已知问题深度归因）。
两种模式在使用 `ads_rev` / `broad_gmv` / `take_rate` 做检测或归因前，必须先执行 macro data consistency check（大盘数据一致性检查）。默认 `consistencyMode=warn-only`：数据源差异只降级置信度，不阻断归因；用户明确要求 `consistencyMode=strict` / "strict mode" 时，数据一致性 `FAIL` 才阻断 confident attribution。

## 双模式速览 / Two-Mode Overview

| 模式          | 用途          | 输入                                        | 输出                             | 详细规范                        |
| ----------- | ----------- | ----------------------------------------- | ------------------------------ | --------------------------- |
| Detection   | 周期扫描，预防线上问题 | cycle (daily/wtd/weekly/mtd) + (可选) drill | Daily Detection Report (.html) | `references/detection.md`   |
| Attribution | 已知异常深度归因    | region/metric/period_a/period_b           | Attribution Report (.html)     | `references/attribution.md` |

通用数据一致性 gate 详见 `references/data_consistency.md`。

## 报告输出格式 / HTML Report Output

Detection 和 Attribution 默认都生成**独立 HTML 报告**，方便用户直接在浏览器打开查看。

- 默认保存为 `.html`，除非用户明确要求 Markdown，否则不要再生成 `.md` 报告。
- HTML 必须是完整文档：`<!doctype html>`、`<html lang="zh-CN">`、`<meta charset="utf-8">`、响应式 viewport、内联 CSS；不要依赖外部 CDN、图片或 JS。
- 报告正文用语义化 section + table 呈现：核心结论、配置、数据一致性、异常列表、归因链路、排查建议、SQL Appendix 都要有清晰标题。
- 指标对比必须使用真正的 `<table>`，数值列右对齐；状态使用稳定标签（PASS / WARNING / FAIL、高/中/低置信），不要只靠颜色表达。
- SQL、命令、公式链路放在 `<pre><code>` 或 `<details><summary>` 中，便于展开复查。
- `--save-to <path>` 若未显式给扩展名，自动追加 `.html`；若用户给了 `.md` 但没有明确要求 Markdown，改成同名 `.html` 并在回复中说明。
- 最终回复给用户可点击的本地 HTML 文件路径；如用户想直接看，可提示用 `open <path>` 打开。

## Mode 分发决策树 / Mode Dispatch

按以下顺序判断用户意图：

```
1. 用户输入是否包含"明确异常描述"？
   - 关键词：xx 跌/涨 X% / 分析 xx 异常 / 为什么 xx 下降 / xx 出问题
   - 是 → Attribution Mode

2. 用户输入是否包含"扫描/巡检"语义？
   - 关键词：日报 / 周报 / wtd / MTD / 扫描 / 巡检 / biz check / 大盘 review /
            看下今天大盘 / 有没有异常
   - 是 → Detection Mode

3. 用户是否提供了 attribution 的必要参数（period_a + period_b + metric）？
   - 是 → Attribution Mode

4. 都不满足 → 反问：
   "你是想：
    (a) 跑大盘异常扫描（不知道哪有问题，要日报/周报）
    (b) 对某个已知问题做深度归因（已知 xx 跌/涨，要找原因）"
```

### 模糊 case 示例 / Ambiguous Examples

| 用户输入 | 判定 | 理由 |
|---------|------|------|
| "跑下今天大盘日报" | Detection | 明确"日报" |
| "ID take_rate 跌了 1.2%, 分析下" | Attribution | 明确异常描述 + metric |
| "看下昨天大盘怎么样" | Detection | 没指定 metric/方向，扫描语义 |
| "对比下本周和上周大盘" | Attribution | 提供完整 period_a + period_b |
| "ID 区数据怎么样" | **反问** | 模糊 |
| "rev 怎么样" | **反问** | 没说时段也没说异常 |

## 核心公式关系 / Core Formulas

```
take_rate = rev / platform_gmv
rev = ecpm × adload × platform_imp
rev = advv × cost_ratio
rev = valid_budget × budget_usage
fulfillment_rate = fulfilled_revenue / fulfillment_base_revenue
ecpm = coef × pctr × pcr × item_price × sold_cnt / troi
advv = broad_gmv / troi
broad_gmv = direct_gmv + shop_gmv
direct_gmv = ctr × direct_cr × item_price × sold_cnt
broad_gmv = 投广seller_gmv占比 × 投广item_gmv占比 × ads_broad_gmv占比 × platform_gmv
```

## 通用约定 — 数据查询 / Common Conventions: Data Access

### ClickHouse 查询 / ClickHouse Query

使用 curl + Basic Auth 发送 SQL，SQL 末尾追加 `FORMAT TabSeparatedWithNames`。

**执行优先级 / Execution priority**：

1. 本 skill 查询 ClickHouse 表时，始终优先使用下方 direct `curl + Basic Auth` 方式。
2. 不要把 `ads-text2da/scripts/run_clickhouse_query.py`、DataSuite、Presto 或 Hive 作为首次尝试。
3. 只有 direct `curl` 因网络、认证或本地工具问题失败后，才允许切换到其他 ClickHouse 执行路径。
4. 不要把 ClickHouse 表查询 fallback 到 Presto / Hive，除非用户明确要求。

| 集群 | 适用范围 | URL | 数据库名 |
|------|---------|-----|---------|
| SG (默认) | OVERALL / TAKE_RATE / SUPPLY_BUDGET 表全部 8 region（含 BR）；UNION 表非 BR 部分 | `clickhouse-office-only-ytl.data-infra.shopee.io` | `mkplpaidads_search_ads_ads_debug` |
| US-VA2 | **仅 UNION 表的 BR 部分** | `clickhouse-office-only-us-va2.data-infra.shopee.io` | `mkplpaidads_search_ads_ads_diagnosis` |

**SG 集群**（默认）：

```bash
curl -s -u 'mkplpaidads_search_ads-cluster_mkplpaidads_mkplpaidads_search_ads_online:b46o8QVbhaN5' \
  --data-binary @- \
  'https://clickhouse-office-only-ytl.data-infra.shopee.io' <<'SQL'
YOUR_SQL_HERE
FORMAT TabSeparatedWithNames
SQL
```

**US-VA2 集群**（仅 UNION 表 BR 数据）：

```bash
curl -s -u 'mkplpaidads_search_ads-cluster_us_2replicas_online:b46o8QVbhaN5' \
  --data-binary @- \
  'https://clickhouse-office-only-us-va2.data-infra.shopee.io' <<'SQL'
YOUR_SQL_HERE
FORMAT TabSeparatedWithNames
SQL
```

TAKE_RATE 表已迁移到 ClickHouse：`mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live`。所有 take_rate、entrance / pricingType / seller_type 拆解、以及 Data Consistency Check 均使用 SG ClickHouse 查询，不再依赖其他查询引擎。

### 数据表速查 / Tables Quick Reference

`OVERALL`、`TAKE_RATE`、`UNION`、`SUPPLY_BUDGET` 是本 skill 使用的表别名。面向用户或管理层的报告中，首次出现时必须说明它们是表别名，并至少给出一次实际表名，之后再使用短别名。

| 别名 | 表名 | 引擎 | 维度粒度 | 用途 |
|------|------|------|---------|------|
| OVERALL | `mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live` | ClickHouse (SG，**覆盖全部 8 region 含 BR**) | `(grass_date, grass_region, entrance, pricing_type, cluster)`；`cluster='ALL'` 为总量 | 大盘核心 + 归因指标（收入/漏斗/出价/预估/GMV），含 L0 category 预聚合 |
| TAKE_RATE | `mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live` | ClickHouse (SG，**覆盖全部 8 region 含 BR**) | `(grass_date, grass_region, tz_type, entry_point, pricing_type, seller_type)` | 按 entrance/pricingType/seller_type 维度细分，含平台侧指标 |
| UNION | `{DB}.ads_union_key_metrics_daily__reg_s0_live` | ClickHouse (按 region) | `(grass_date, grass_region, entrance, pricing_type, ads_id/campaign_id/shop_id)` | 广告主维度明细（campaign/ads/shop 粒度），用于 Top Campaign 下钻 |
| SUPPLY_BUDGET | `mkplpaidads_search_ads_ads_debug.overall_supply_budget_metrics_daily__reg_s0_live` | ClickHouse (SG 集群，**含 BR 数据**) | `(grass_date, grass_region, pricing_type, budget_type)` | 供给侧 + 预算侧归因（OR7 / OR11）：active_ads_cnt、active_advertiser_cnt、daily_valid_budget、topup_amt_usd、account_balance_usd |

> `{DB}` 规则（**仅适用于 UNION 表**）：region ≠ BR → `mkplpaidads_search_ads_ads_debug`（SG 集群）；region = BR → `mkplpaidads_search_ads_ads_diagnosis`（US-VA2 集群）。OVERALL / SUPPLY_BUDGET 表统一在 SG 集群，不按 region 路由。

> **SUPPLY_BUDGET 表注意**：
> - 该表**仅在 SG 集群**，覆盖所有 region（含 BR）— 与 UNION 不同，不按 region 分集群（OVERALL 同样统一在 SG）。诊断任何 region 时统一走 SG 集群即可。
> - `pricing_type` 和 `budget_type` 均含 `'all'` 预聚合行；`budget_type` 取值 `limited` / `unlimited` / `all`，其中 `unlimited` 对应 `budget_usd=9999999999`。查询总量直接用 `WHERE pricing_type='all' AND budget_type='all'`，**不要**同时 SUM `'all'` 和具体值（会重复计算）。
> - 所有金额字段均为 **USD**。

> 完整 schema → `references/table_info.md`
> O1-O13 / OR1-OR15 节点定义 → `references/factual_nodes.md`
> TR 日常分析 tracker / 人工归因流程 → `references/tr_tracker_workflow.md`
> 供给侧与激励侧归因补充 → `references/supply_incentive_attribution.md`
> 命中 OR7 / OR11 / OR15 或 budget / balance / hit-budget / hit-balance / active-advertiser / 激励相关异常时，必须读取该补充文件后再写因果链。

## Detection 模式骨架 / Detection Skeleton

进入 Detection 模式后按以下高层流程执行（详细 SQL、客户端判定脚本、Daily Detection Report 模板见 `references/detection.md`）：

1. 解析 cycle（daily / wtd / weekly / mtd），按 Asia/Singapore 时区计算 Period A / B1 / B2 日期
2. **Freshness Check**：先 ping `max(grass_date)`；若 < period_a 最后一天 → **报错退出**（fail-fast，不用旧数据出报告）
3. **Data Consistency Check（数据一致性检查）**：按 `references/data_consistency.md` 对同一 date / region / entrance / pricingType / timezone / currency / grain，从 `OVERALL table` 与 `TAKE_RATE table` 拉 `ads_rev` / `broad_gmv` / `take_rate` 做 source A vs source B 比较
4. 一次性拉 `[B1_start, A_end]` 区间 OVERALL 全 region 数据（SG 集群单查询覆盖含 BR 在内的 8 个 region）；SUPPLY_BUDGET 按需拉
5. 通过 `uv run` 跑 PEP 723 inline-deps Python 脚本做客户端阈值判定（不允许 LLM 心算）；合并 consistency check 结果：默认 `warn-only` 下 `FAIL` 可继续列异常但必须标注置信度降级；`strict` 下受影响 metric/scope 不得标为高可信，只能标为数据源不一致
6. （可选）`--drill region=...` 时对指定 region 重拉按 entrance / pricing_type 拆分的数据
7. 组装 Daily Detection Report HTML，默认存到 `docs/team/00.paid-ads-dev/16.ads-daily-report/{periodA最后一天}-{cycle}.html`，支持 `--save-to <path>` 覆盖、`--no-save` 仅打印摘要
8. 报告中每条异常附可执行的 attribution 命令；不自动链式归因。默认 `warn-only` 下，即使 consistency gate 为 `FAIL` 也可附 attribution 命令，但命令和结论必须带数据一致性 warning；`strict` 下若 gate 为 `FAIL`，改附数据一致性复查建议，不附 confident attribution 命令

> **完整规范** → `references/detection.md`

## Attribution 模式骨架 / Attribution Skeleton

进入 Attribution 模式后按以下高层流程执行（详细 SQL、归因路径、Attribution Report 模板见 `references/attribution.md`）：

1. 解析参数 region / metric / period_a / period_b / entrance / pricingType / consistencyMode；direction 由数据自动判断；`consistencyMode` 默认 `warn-only`
   - **Scope discipline**: region / entrance / pricingType 是**硬边界**，不主动扩展。发现需要扩展（如跨 region 同步异常）时**反问用户**，不静默扩展。**唯一例外**：Step 4.A 时间扩展（因果链必需）
   - metric 为 `take_rate` / `TR` / `Net TR` / `Gross TR`，或用户提到 tracker、MTD MoM、DOD、free credit、L0 category、达标率、fulfillment、overbid / underbid 时，必须先读取 `references/tr_tracker_workflow.md`，按 TR 日常分析顺序补充对比口径和下钻维度。L0 category 指 FMCG / Fashion / Lifestyle / Electronics 等业务类目；优先使用 OVERALL ClickHouse 表中已预聚合的 `cluster` 字段（`cluster='ALL'` 为不按 cluster 拆分，`cluster!='ALL'` 为 L0 category breakdown）。若 OVERALL ClickHouse `cluster!='ALL'` 已覆盖目标 Period A/B、region、entrance、pricingType 且 `net_ads_rev` / `broad_gmv_usd` 可用于分解，不要读取 Google Sheet tracker；只有 ClickHouse L0 category 数据缺失/不完整、表权限失败，或用户明确要求 tracker benchmark / fallback 时才读取 tracker。不要实时 join `shop_id` 重算 cluster 聚合
2. **Data Consistency Check（数据一致性检查）**：先按 `references/data_consistency.md` 对 normalized scope 比较 `OVERALL table` vs `TAKE_RATE table` 的 `ads_rev` / `broad_gmv` / `take_rate`。默认 `warn-only` 下，若诊断指标或其核心分解指标为 `FAIL`，输出 warning 并继续归因但降级置信度；`strict` 下停止 confident attribution
3. （仅 region=ALL）Step 1：拉全 region OVERALL 计算 region 贡献度，筛选贡献度 ≥10% 的 region 进入下一步
4. Step 2：对目标 region 拉 OVERALL（核心）+ TAKE_RATE（entrance/pricingType 拆分）+ SUPPLY_BUDGET（OR7/OR11）；对照 `factual_nodes.md` OR1-OR15 标记命中归因节点；若命中 OR7 / OR11 / OR15 或供给/激励相关信号，读取 `references/supply_incentive_attribution.md` 做补充下钻
5. Step 3：按 entrance / pricingType 维度下钻，找出主要贡献维度；TR 归因额外按 gross vs net vs free credit、L0 category mix/rate、budget vs budget usage、达标率 / overbid-underbid、item order bucket 的顺序补充下钻。L0 category 报告必须写明 source label（overall-clickhouse-cluster / tracker-benchmark / tracker-raw-fallback / proxy only）；当 source label 为 `overall-clickhouse-cluster` 时，不要读取 tracker，也不要写 tracker unavailable；`ads_union_key_metrics_daily__reg_s0_live` category 字段只能作为 ads-side proxy，不能写成生产 TR L0 category 结论
6. **Step 4 因果链构建**（关键，决定报告价值）：
   - 4.A 扩展时间窗 (`period_b - 3d` ~ `period_a + 3d`)，找**最早**出现 ≥5% 方向性变化的因子（早触发 ≠ period_a）
   - 4.A.1 若诊断与 GMV 相关，必须单独输出 GMV-Based Holiday / Campaign Adjustment section（四选一 label + 依据表 + caveat），不要只写在 TL;DR 或 4.A 正文
   - 4.B 构建传导箭头（参考 3 个常见模板：上游数据异常 / 广告主预算 / 平台流量结构）
   - 4.C 拉 `period_a + 1d ~ +7d` 恢复数据验证假设（完全恢复 / over-shoot / 未恢复 → 排除/支持不同 trigger 假设）
   - 4.D 按 trigger / amplifier / direct cause / secondary 角色分类，**不要平铺独立发现**
7. 组装 Attribution Report HTML，含 Data Consistency Check、TL;DR、Step 4.A~D 显式 section、GMV 相关诊断的 Step 4.A.1 独立 section、公式分解表、按优先级的排查建议；若来自 Detection 报告则在头部标注来源行

> **完整规范** → `references/attribution.md`
