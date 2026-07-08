# Ads Diagnose (ads-diagnose) Guide

> **Contributors**: luka.yang, qianqian.pu ｜ **最后更新**：2026-06-02 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-diagnose.md)
> **Language**: [English](ads-diagnose.md) | [中文](ads-diagnose.zh-CN.md)

Diagnoses ad performance anomalies by querying ClickHouse funnel, bidding, and estimation data for a given ads_id, campaign_id, or shop_id.

**Trigger keywords**: "ads-diagnose", "广告诊断", "ads_id", "campaign_id", "shop_id", "效果异常", "广告排查", "cost 骤降", "超收", "停投"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with diagnostic pipeline and SQL templates |
| `references/factual_nodes.md` | Anomaly type definitions (A1-A14, B1-B15) and attribution nodes (R1-R10) |
| `references/table_info.md` | ClickHouse table schemas and field details |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| ClickHouse access | Network | Office network or VPN required to reach ClickHouse clusters |

---

## Usage

### Scenario 1: Single campaign diagnosis

> "Help me diagnose campaign_id 12345, region ID"

The skill resolves the ID, queries campaign-level metrics over 7 days, detects anomalies (A-series), builds causal chains, then drills down to ad-level data.

### Scenario 2: Shop-level diagnosis

> "Shop 67890 revenue dropped sharply yesterday"

Identifies Top Campaigns under the shop first, then analyzes each top campaign individually to avoid masking single-campaign signals.

### Scenario 3: Ad-level zero impression check

> "ads_id 99999 has zero impressions today"

Queries ad-level funnel data and status/inactive reason tables to identify why the ad stopped serving.

## Diagnostic Flow

1. **Step 0** — ID resolution: determine ID type and resolve campaign_id, shop_id, region
2. **Step 0.5** — (shop_id only) Identify Top Campaigns by revenue
3. **Step 1** — Campaign-level overview: daily metrics, funnel, bidding, budget
4. **Step 2** — Ad-level drill-down: per-ad funnel and trend analysis
5. **Step 3** — Status & inactive reasons for zero-impression ads; also checks campaign-level multi-ads operation logs (R1.1/R1.2 fallback) to capture bulk operations that may not appear in ad-level logs
6. **Step 4** — Anomaly detection: classify anomalies (A-series for campaign, B-series for shop)
7. **Step 5** — L1 module triage (R1-R10): R1 cross-checks UNION + STATUS operation logs with direction filtering; R3/R4 apply direction-aware filtering for both over-delivery and under-delivery; R4 includes relative degradation checks; R6 evaluates joint degradation signals across metrics
8. **Step 6** — Bucket routing: self-owned buckets expand in main skill; R3/R4 hits dispatch to specialized sub-agents for deep-dive
9. **Step 7** — Merge reports and output final diagnosis

---

## Output Format

All responses follow a structured diagnostic report:

- **Context** — campaign/shop/region/time range/pricing type
- **Summary** — 1-3 sentence overview of detected anomalies and root cause
- **Anomaly Detection** — numbered anomaly types with specific metric values
- **Root Cause Attribution** — attribution nodes with evidence, role tags, and recommendations
- **PCOC & Funnel Summary** — daily metrics table
- **7-day Aggregation** — cost_7d, advv_7d, cost_ratio_7d, gmv_7d
