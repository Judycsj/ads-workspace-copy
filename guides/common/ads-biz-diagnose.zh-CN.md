# 广告大盘异常诊断 (ads-biz-diagnose) 使用指南

> **Language**: [English](ads-biz-diagnose.md) | [中文](ads-biz-diagnose.zh-CN.md)

广告大盘异常诊断与归因。给定时间段、region、entrance、pricingType 和指标，通过查询 ClickHouse 数据进行异常检测和多层归因分析。

**触发关键词**: "诊断", "归因", "异常", "take_rate", "收入下降", "大盘诊断", "归因分析", "异常诊断", "diagnose", "attribution"

---

## 场景 1: 诊断指定 region 的 take_rate 下降

> **你**: `2026-03-01~03-07 对比 2026-02-22~02-28, region=ID, entrance=ALL, pricingType=ALL, take_rate 下降`
>
> **AI**: 查询 ClickHouse OVERALL 表两个时间段的数据，检测 O1 异常（take_rate 下降），分解 rev/platform_gmv 因子，执行多层归因（ecpm/adload/platform_imp），输出结构化诊断报告和因果链。

---

## 场景 2: Region 级贡献度分析（region=ALL）

> **你**: `近一周 take_rate 相比上一周下降, region=ALL, entrance=ALL, pricingType=ALL`
>
> **AI**: 先分解各 region 对全局指标变化的贡献度，筛选贡献度 ≥10% 的 region，再对每个关键 region 进行详细归因。

---

## 场景 3: 按 entrance 或 pricingType 下钻

> **你**: `ID 的 rev 下降, 帮我按 entrance 拆分看看哪个入口贡献最大`
>
> **AI**: 查询 ClickHouse TAKE_RATE 表按 entrance 拆分，计算各入口对 rev 变动的贡献度。

---

## 场景 4: 按 L0 category 做 take_rate 深度归因

> **你**: `ID MTD MoM take_rate deep dive, include L0 category analysis`
>
> **AI**: 优先读取 OVERALL ClickHouse 表，使用预聚合的 `cluster != 'ALL'` 行做 L0 category breakdown，并用 `cluster = 'ALL'` 做总量口径。Google Sheet tracker 作为 benchmark 或 fallback。报告会区分 FMCG、Fashion、Lifestyle、Electronics 等 L0 category 的 GMV mix effect 和 category own-rate effect。

---

## 数据源

| 表 | 引擎 | 说明 |
|----|------|------|
| OVERALL (`ads_overall_key_metrics_daily`) | ClickHouse | 核心指标 + 归因因子；通过预聚合 `cluster` 提供 L0 category breakdown（`ALL` = 总量） |
| TAKE_RATE (`ads_advertise_take_rate_v2_1d`) | ClickHouse | 按 entrance/pricingType/seller_type 维度细分 |
| UNION (`ads_union_key_metrics_daily`) | ClickHouse | 广告主维度明细（campaign/ads/shop 粒度），用于 Top Campaign 下钻 |
| TR tracker (`MTD, YTD`, `daily_data_raw`) | Google Sheets | L0 category TR 深度归因的 benchmark / fallback；包含 `by cluster metrics trending` 和 daily raw category 列 |

`UNION` 表的 category 字段只能作为 ads-side proxy；除非明确标注 proxy，不要写成生产 take-rate L0 category 结论。

## 归因公式树

```
rev = ecpm × adload × platform_imp
rev = advv × cost_ratio
rev = valid_budget × budget_usage
take_rate = rev / platform_gmv
```

详细异常类型定义（O1-O13）和归因节点定义（OR1-OR14），见 `skills/common/ads-biz-diagnose/references/factual_nodes.md`。
