# Ads DQC 周报（ads-dqc-report）使用指南

> **语言**：[English](ads-dqc-report.md) | [中文](ads-dqc-report.zh-CN.md)

基于 SG ClickHouse 生成周级 DQC 报告，覆盖 Performance DQC 和 Union Ads DQC。Skill 会对比本周与上周，识别覆盖率下降不少于 5pp、均值下降不少于 10% 的异常字段。

**触发关键词**：「DQC report」、「dqc 周报」、「DQC 周报」、「weekly dqc」、「performance dqc report」、「union ads dqc report」、「覆盖率周报」、「均值周报」、「DQC 异常字段」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含日期解析、ClickHouse 查询流程、异常判定规则、字段排除规则和报告模板 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| ClickHouse 访问权限 | 网络 | 需要办公网络或 VPN 才能访问 SG ClickHouse 集群 |
| ads-diagnose 配置 | 本地 skill 上下文 | 复用 `ads-diagnose` 中的 SG ClickHouse 连接配置 |

---

## 使用场景

### 场景 1：生成完整 DQC 周报

> 「生成 week_end=2026-04-28 的 DQC 周报」

Skill 会查询最新可用数据，构造本周 7 天窗口和上周 7 天窗口，并输出 Performance DQC 与 Union Ads DQC 两部分。

### 场景 2：只生成 Performance DQC 报告

> 「生成 TH、ID、BR 的 performance dqc report，截止 2026-04-28」

只查询 Performance DQC 表，输出指定 region 的数据完整性、覆盖率异常和均值异常。

### 场景 3：指定明确周窗口

> 「DQC 周报，week_start=2026-04-22, week_end=2026-04-28, region=ALL」

本周使用用户指定的日期窗口，上周按同等天数整体向前平移得到。

### 场景 4：保存到默认目录

> 「生成 weekly dqc 并保存」

如果用户没有指定路径，报告默认保存到 `docs/team/00.paid-ads-dev/17.ads-dqc-report/`，文件名为 `{cur_end}-weekly-dqc-report.md`。

---

## 数据源

| Report | ClickHouse 表 |
|--------|---------------|
| Performance DQC | `mkplpaidads_search_ads_ads_debug.performance_dqc_daily_metrics` |
| Union Ads DQC | `mkplpaidads_search_ads_ads_debug.union_ads_dqc_daily_metrics` |

所有 region，包括 BR，都从 SG ClickHouse 集群查询。Skill 不使用 Hive/DataSuite 作为周报生成入口。

---

## 判定规则

| 规则 | 指标字段 | 条件 |
|------|----------|------|
| 覆盖率异常 | 以 `_fill_rate` 结尾的字段 | 本周均值相对上周下降不少于 5pp |
| 均值异常 | 以 `_avg` 结尾的字段 | 上周值大于 0，且本周均值相对上周下降不少于 10% |

异常判定前，Skill 会按 `grass_region + grass_date` 检查每日数据完整性。若某个 region 缺少本周或上周日期，会列入 `Data Missing`，并默认跳过该 region 的异常判定，避免因缺数产生误报。

---

## 输出格式

生成的 Markdown 报告包含：

- **Summary** — 每类报告的异常数量和最严重字段
- **Performance DQC Report** — 数据缺失、覆盖率异常、均值异常
- **Union Ads DQC Report** — 数据缺失、覆盖率异常、均值异常
- **Notes** — 阈值、聚合口径、取消校验字段排除逻辑和数据源

如果没有发现显著下降，报告会明确说明本周未发现 DQC 覆盖率或均值显著下降异常。
