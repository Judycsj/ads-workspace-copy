# Ads Biz Diagnose (ads-biz-diagnose) Guide

> **Language**: [English](ads-biz-diagnose.md) | [中文](ads-biz-diagnose.zh-CN.md)

Diagnose and attribute anomalies in ads business metrics. Given a time period, region, entrance, pricing type, and metric, query ClickHouse data for anomaly detection and multi-layer attribution analysis.

**Trigger keywords**: "diagnose", "attribution", "anomaly", "take_rate", "revenue drop", "ads dashboard", "大盘诊断", "归因分析", "异常诊断"

---

## Scenario 1: Diagnose take_rate drop for a specific region

> **You**: `2026-03-01~03-07 对比 2026-02-22~02-28, region=ID, entrance=ALL, pricingType=ALL, take_rate 下降`
>
> **AI**: Queries OVERALL table from ClickHouse for the two periods, detects O1 anomaly (take_rate decline), decomposes into rev/platform_gmv factors, performs multi-layer attribution (ecpm/adload/platform_imp), and outputs a structured diagnosis report with causal chain.

---

## Scenario 2: Region-level contribution analysis (region=ALL)

> **You**: `近一周 take_rate 相比上一周下降, region=ALL, entrance=ALL, pricingType=ALL`
>
> **AI**: First decomposes region-level contribution to the global metric change, identifies regions with >=10% contribution, then performs detailed attribution for each key region.

---

## Scenario 3: Entrance or pricingType drill-down

> **You**: `ID 的 rev 下降, 帮我按 entrance 拆分看看哪个入口贡献最大`
>
> **AI**: Queries the ClickHouse TAKE_RATE table to break down by entrance, calculates each entrance's contribution to the rev change.

---

## Scenario 4: Take rate deep dive by L0 category

> **You**: `ID MTD MoM take_rate deep dive, include L0 category analysis`
>
> **AI**: Reads the OVERALL ClickHouse table first, using pre-aggregated `cluster != 'ALL'` rows for L0 category breakdown and `cluster = 'ALL'` for total scope. The Google Sheet tracker is used afterward as a benchmark or fallback. The report separates L0 category GMV mix effect from L0 category own-rate effect for categories such as FMCG, Fashion, Lifestyle, and Electronics.

---

## Data Sources

| Table | Engine | Description |
|-------|--------|-------------|
| OVERALL (`ads_overall_key_metrics_daily`) | ClickHouse | Core metrics + attribution factors; primary L0 category breakdown via pre-aggregated `cluster` (`ALL` = total) |
| TAKE_RATE (`ads_advertise_take_rate_v2_1d`) | ClickHouse | Per entrance/pricingType/seller_type breakdown |
| UNION (`ads_union_key_metrics_daily`) | ClickHouse | Advertiser-level detail (campaign/ads/shop granularity) for Top Campaign drill-down |
| TR tracker (`MTD, YTD`, `daily_data_raw`) | Google Sheets | Benchmark / fallback for L0 category TR deep dive; `by cluster metrics trending` and daily raw category columns |

`UNION` category fields are ads-side proxies only; they should not be presented as production take-rate L0 category conclusions unless explicitly labeled as proxy.

## Attribution Formula Tree

```
rev = ecpm × adload × platform_imp
rev = advv × cost_ratio
rev = valid_budget × budget_usage
take_rate = rev / platform_gmv
```

For detailed anomaly type definitions (O1-O13) and attribution node definitions (OR1-OR14), see `skills/common/ads-biz-diagnose/references/factual_nodes.md`.
