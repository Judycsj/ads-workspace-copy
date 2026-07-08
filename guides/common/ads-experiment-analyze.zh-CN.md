# 广告实验分析（ads-experiment-analyze）使用指南

> **语言**：[English](ads-experiment-analyze.md) | [中文](ads-experiment-analyze.zh-CN.md)

用于 Ads AB 实验 daily 跟踪分析。该 skill 通过 `sp-ab` 获取 AB 平台 report 数据，再套用广告实验指标模板，输出中文风险报告，覆盖核心指标、guardrail、by-day 稳定性、单桶 vs 所有桶总和对比。

**唤醒词**：「ads experiment analysis」、「AB 实验分析」、「实验 daily」、「实验跟踪」、「guardrail」、「by day 波动」、「单桶大盘对比」、「出价实验」、「发券实验」、「精排实验」、「召回实验」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主工作流和报告解读规则 |
| `assets/monitor.example.yaml` | YAML 配置示例 |
| `references/config-schema.md` | 配置字段和指标 schema |
| `references/ads-metric-templates.md` | 出价和流量侧实验默认指标模板 |
| `references/risk-policy.md` | 波动、guardrail、红黄绿规则 |
| `scripts/analyze_experiment.py` | 分析 AB report JSON 的脚本 |
| `scripts/render_daily_report.py` | 从保存的 JSON 结果重新渲染 Markdown |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|------|------|------|
| `sp-ab` | Skill | 获取 AB 平台实验元信息和 report JSON |
| AB platform report token | 凭据 | `sp-ab get-report.py` 调用 Report Open API 所需 |
| `uv` | 运行时 | 运行脚本并解析 Python 依赖 |

---

## 基本用法

1. 优先只提供 AB report link；skill 会先自动推断统计口径。
2. 如果用户指定日期、桶号、region 或 filter，以用户指定为准。
3. 从 `assets/monitor.example.yaml` 准备或覆盖实验配置。
4. 用 `sp-ab` 拉取 period report：

```bash
uv run get-report.py --from-url "<AB_REPORT_URL>" --json > period_report.json
```

5. 如有 by-day tab，再拉取 by-day report：

```bash
uv run get-report.py --from-url "<AB_BY_DAY_REPORT_URL>" --json > by_day_report.json
```

6. 运行分析脚本：

```bash
uv run scripts/analyze_experiment.py \
  --config assets/monitor.example.yaml \
  --report-json period_report.json \
  --daily-json by_day_report.json \
  --output-json daily_report.json \
  --output-md daily_report.md
```

---

## 示例 Prompt

> 用 `/ads-experiment-analyze` 分析这个出价实验，report link 是 `...`，目标 pricing_type 是 `target_roas`。

> 帮我分析这个发券实验，重点看 guardrail_voucher、bad_query_rate，以及昨天 vs 前天有没有异常波动。

> 这个 recall 实验帮我做 daily 跟踪，输出 Markdown，并指出单桶相对所有桶总和有没有明显风险。

---

## 注意事项

- 默认 `0.5%` 以内认为是波动，不直接判断为真涨或真跌。
- 报告必须先展示统计口径：日期、平台实际返回天数、region、group id、bucket range、流量比例或尾号比例、base/exp 合并策略、AA 口径、tab、filter 和指标计算方式。
- 所有实验都要展示每个 group 的比例：流量侧展示 AB 平台 traffic percentage（最好按 region 展示）；出价尾号实验展示尾号/桶段和占比，例如 `1:10,51:60 = 20/100 = 20%`。如果平台数据拿不到，需要在统计口径中标注 `unknown`，不能省略。
- 所有方向（出价 / 发券 / 模型 / 召回 / 通用流量侧）的实验结果都采用统一的表格化展示：总体结论、核心指标、guardrail、by-day、by-region、分桶拆解、AA/波动判断、单桶 vs 大盘都优先用 Markdown 表格呈现。
- 如果实验周期包含大促日，需要拆分 normal/promo；大促日包括每月 15 号、25 号，以及月日相同的 double day。
- 如果用户指定桶号，以用户指定为准；否则从 AB link 自动推断。
- 默认不合并桶；如果 share 自身是组合桶，需要在统计口径中说明。
- 如果发现 AA 桶，自动加入 AA diff 作为波动判断；如果没有 AA，必须提示置信度风险。
- 出价实验默认分析 `all` 和 `target_roas 2.0`；如果用户给出目标 `pricing_type`，以用户输入为准。
- 出价侧尾号实验采用客户约束优先判断：核心先看 `cpm`、`advv_per_imp` 和 `fulfilled/underbid/overbid/no_gmv`，`rev_usd`、`net_rev_after_rebate`、raw `advv_cost` 作为辅助收益和尾号抢量诊断，不应单独决定实验成功。
- 需要指出业务方向：出价 / 发券 / 模型 / 召回 / 通用流量侧。
- 默认输出 overall 结论，并给出所有 region 的 by-region 情况。
- 出价达标率以 `fulfilled_rev_pct(1d)` 为主指标；`fulfilled_rev_pct(7d)` 作为 `guardrail_fulfill`，用实验桶 - base 桶的绝对百分点差判断，下降超过 `2pp` 才 hard fail。
- 出价实验尽量包含 `advv_999` / `advv_cost_999` 和 `imp_cnt`；analyzer 会计算 `advv_999_per_imp = advv_cost_999 / imp_cnt`，用于判断 raw `advv per imp` 变化是否受尾部样本拉动。
- 流量侧实验覆盖发券、精排模型、召回。精排 / 召回 / 通用流量侧的核心判断是 `rev` 与 `advv` 是否上涨，`gmv_995_v2` 是 guardrail，下降超过 `0.5%` 才 hard fail。
- 流量侧需要检查 `rev` 与 `advv` 的关系：如果 `rev` 明显高于 `advv`，需要提示可能超收；如果 `rev` 正向但 `advv` 不正向，不能作为 clean win。
- 流量侧总结必须包含 by-day 是否正向：如果只是某一天特别好导致整体好，或大部分天没有正向，不能标为 clean pass。
- checklist 需要补充 `search_gmv_995_v2` 和 `rcmd_unify_gmv_995_v2`，作为 GMV 细分 guardrail / 风险提示。
- Google Doc 和 SeaTalk 作为预留出口：先生成 Markdown，再通过可用 workspace 工具发布。
