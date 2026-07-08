# Ads Monitoring Reference (L5)

When the question involves **real-time or recent metrics** of Ads services, delegate to `sp-grafana` instead of searching docs or code.

**Trigger signals:** 延迟、监控、P99、QPS、错误率、抖动、是否正常、最近30分钟、dashboard、看一下监控、有没有告警、现在的指标、latency、metrics、monitoring

---

## Ads-Engine Dashboards

| Dashboard | UID | URL |
|-----------|-----|-----|
| [ADS ENGINE] Release SOP | `M0F-fJqHz` | https://monitoring.infra.sz.shopee.io/grafana/d/M0F-fJqHz/ads-engine-release-sop |
| ads engine core alarm | `aYnInjMDz` | https://monitoring.infra.sz.shopee.io/grafana/d/aYnInjMDz/ads-engine-core-alarm |
| Ads Engine (Ls Engine Migrated) | `xk-g0aeNz` | https://monitoring.infra.sz.shopee.io/grafana/d/xk-g0aeNz/ads-engine-ls-engine-migrated |
| ads engine release monitor | `3z01ToANk` | https://monitoring.infra.sz.shopee.io/grafana/d/3z01ToANk/ads-engine-release-monitor |

### Key Panel IDs (Release SOP dashboard)

| Panel | ID |
|-------|-----|
| API0 Latency (P99) | 24 |
| API1 Latency (P99) | 27 |
| API2 Latency (P99) | 35 |
| API3 Latency (P99) | 38 |
| API4 Latency (P99) | 46 |
| API1 QPS | 26 |
| API1 Error Rate | 28 |

---

## Example Commands

```bash
# Query API1 latency last 30 min, render chart
uv run <sp-grafana>/scripts/dashboard_inspect.py \
  "https://monitoring.infra.sz.shopee.io/grafana/d/M0F-fJqHz/ads-engine-release-sop?from=now-30m&to=now" \
  --render 27

# Query + data breakdown by country
uv run <sp-grafana>/scripts/dashboard_inspect.py \
  "https://monitoring.infra.sz.shopee.io/grafana/d/M0F-fJqHz/ads-engine-release-sop?from=now-30m&to=now" \
  --run-panels 27 --by-label country
```

---

## Response Template (monitoring)

```
**核心结论**
[One-sentence summary: e.g. "API1 P99 延迟当前约 45ms，过去 30 分钟整体平稳。"]

**分析**
[Trend description: peak value, anomaly time window, affected dimensions (country/entrance), comparison to baseline]

**Source**
- 监控面板: <Dashboard title> Panel <id> — <Grafana URL with time range>
- 指标表达式: `<PromQL expression>`
```
