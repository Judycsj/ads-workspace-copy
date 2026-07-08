<!-- ads-workspace-gdoc-sync: gdoc_id=1t-Ggf1AMdoZQkPP4PKV7yb0Kqb2UOiJjtYaxqYB06qU gdoc_url=https://docs.google.com/document/d/1t-Ggf1AMdoZQkPP4PKV7yb0Kqb2UOiJjtYaxqYB06qU/edit -->

# ROI3 Recent Data Snapshot 2026-06-03

> 这是动态数据快照，不是长期稳定口径。若要回答“当前/最近”的问题，应按下方 skill route 重新拉数。

## 查询范围

| 项 | 取值 |
| --- | --- |
| 执行日期 | 2026-06-05 |
| ClickHouse 最新可用数据日 | 2026-06-03 |
| Weekly 窗口 | 2026-05-28 至 2026-06-03 vs 2026-05-21 至 2026-05-27 |
| Trend 可用日期 | 2026-05-28、2026-05-29、2026-05-30、2026-05-31、2026-06-01、2026-06-03 |
| 缺失提醒 | 2026-06-02 在本次 trend rows 中未返回，不应解读为 0 |

## Skill Route

本快照使用以下 ROI3 skill 拉数：

| 场景 | Skill | 输出 |
| --- | --- | --- |
| 周度效果、PC2、Voucher Profit、GMV Diff、Revenue Diff | `ads-roi3-weekly-sync` | `/tmp/ads-workspace/roi3-weekly/roi3-weekly-2026-05-28_2026-06-03.md` |
| ROI3 main experiment 日报、Guardrail、ROAS、base vs exp | `ads-roi3-monitoring-report` | `/tmp/ads-workspace/roi3-data-refresh/roi3-monitoring-latest-2026-06-03-with-budget.md` |
| 近 7 个可用日大盘趋势 | `ads-roi3-monitoring-report` | `/tmp/ads-workspace/roi3-data-refresh/roi3-trend-all-2026-05-28_2026-06-03.md` |
| Region/bucket 预算使用率 | `ads-roi3-monitoring-report` + ultra-core trace | `/tmp/ads-workspace/roi3-data-refresh/budget_rows_2026-06-03.json` |

关键命令：

```bash
uv run --with pycookiecheat skills/team/04.product-algo/ads-roi3-monitoring-report/scripts/roi3_clickhouse.py \
  --latest --use-latest-available \
  --output /tmp/ads-workspace/roi3-data-refresh/latest_rows.json

uv run --with pycookiecheat skills/team/04.product-algo/ads-roi3-monitoring-report/scripts/roi3_clickhouse.py \
  --latest --trend --trend-days 7 --exp-tags all \
  --output /tmp/ads-workspace/roi3-data-refresh/trend_all_rows.json

uv run --with urllib3 --with requests --with pycookiecheat \
  skills/team/04.product-algo/ads-roi3-monitoring-report/scripts/roi3_budget_usage.py \
  --data-date 2026-06-03 \
  --output /tmp/ads-workspace/roi3-data-refresh/budget_rows_2026-06-03.json
```

小时级 trace 查询按 `ads-roi3-budget-control-analysis` 的 hourly curve SQL 提交过一次，DataStudio executionId 为 `72378866`，本地轮询超时，未产出可用 hourly rows。

## Budget Usage

口径：algorithm buckets `656433~656440`，`controller_spend_usd / pacing_target_usd`；pacing target 使用 `coalesce(AdjustBudget, DailyBudget)`。

| Scope | Budget usage | Usage vs expected | 判断 |
| --- | ---: | ---: | --- |
| ALL | 110.21% | 112.44% | 超过 110%，Risk |
| ID | 112.21% | 114.59% | Risk |
| VN | 113.70% | 117.37% | Risk |
| PH | 109.38% | 109.39% | Watch |
| TW | 107.03% | 107.11% | Watch |
| SG | 105.90% | 105.90% | Watch |
| TH | 103.28% | 106.05% | Healthy/Watch |
| MY | 99.85% | 99.87% | Healthy |

### Bucket Matrix

| Region | 656433 | 656434 | 656435 | 656436 | 656437 | 656438 | 656439 | 656440 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| ID | 114.3% | 114.0% | 113.6% | 114.1% | 114.6% | 109.5% | 106.2% | 111.4% |
| MY | 100.6% | 100.6% | 98.6% | 100.2% | 100.6% | 99.9% | 98.1% | 100.2% |
| PH | 109.7% | 108.5% | 108.7% | 109.3% | 109.7% | 109.2% | 109.9% | 109.9% |
| SG | 106.0% | 105.4% | 105.3% | 106.2% | 106.3% | 105.9% | 106.2% | 105.8% |
| TH | 103.4% | 103.2% | 102.5% | 103.3% | 102.9% | 104.1% | 103.0% | 103.8% |
| TW | 108.0% | 107.9% | 106.0% | 106.2% | 107.0% | 106.6% | 106.9% | 107.6% |
| VN | 113.7% | 113.6% | 113.4% | 113.6% | 113.5% | 114.2% | 114.0% | 113.5% |

Top risk buckets：ID `656437/656433/656436/656434/656435` 和 VN `656438/656439/656433/656434/656436/656437/656440` 均在 113.5% 以上。

## Weekly Effect

周报结论：2026-05-28 至 2026-06-03 窗口有 7 个风险信号，涉及 ALL、ID、MY、PH、TH、TW。

| Metric | This week Diff | Last week Diff | WoW | 状态 |
| --- | ---: | ---: | ---: | --- |
| Voucher Profit | 427,819 | 240,194 | +78.11% | Healthy |
| PC2 New | 454,482 | 223,028 | 绝对变化 +231,454 | Healthy |
| GMV / GMV 995 v2 | 2,298,081 | 2,465,267 | -6.78% | Risk |
| Revenue-new ads net rev | 2,661,256 | 2,254,206 | +18.06% | Healthy |
| Ads Voucher Cost | 2,807,957 | 2,630,329 | +6.75% | Watch |

Focus region 风险：

| Region | 主要读数 |
| --- | --- |
| ID | GMV Diff WoW -7.00%，Risk；Ads Voucher Cost -6.40%，Healthy |
| TH | Voucher Profit 从 39,008 变为 -95,024，Risk；Ads Voucher Cost +93.34%，Watch |
| VN | Voucher Profit 仍为负但改善；GMV Diff WoW -4.00%，未触发 Risk |

## Daily Experiment Readout

ROI3 main experiment，data_date=2026-06-03：

| Scope | Guardrail | Budget usage | Broad ROAS base | Broad ROAS exp |
| --- | ---: | ---: | ---: | ---: |
| ALL | -1,276,108.45 | 110.21% | 11.71 | 9.69 |
| ID | -410,264.70 | 112.21% | 13.57 | 10.54 |
| TH | -481,824.26 | 103.28% | 12.24 | 10.07 |
| VN | -320,677.99 | 113.70% | 12.45 | 10.38 |
| PH | -130,820.72 | 109.38% | 11.27 | 9.18 |
| TW | -137,578.88 | 107.03% | 8.46 | 7.16 |
| SG | 56,983.31 | 105.90% | 6.65 | 6.04 |
| MY | 148,074.79 | 99.85% | 11.03 | 10.07 |

日报异常摘要：

- Overall Guardrail 为负，且 ADVV 增长但 Guardrail 为负。
- Overall Broad ROAS base 11.71、exp 9.69，exp 侧低 17.28%。
- ID、TH、VN、PH、TW Guardrail 为负；SG、MY Guardrail 为正。

## Big Picture Trend

`exp_tag=all`，不计算实验 lift；2026-06-02 未返回，表内省略。

| Date | ADVV | Platform GMV | Broad GMV | Ads voucher cost | Broad ROAS |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2026-05-28 | 13,026,491 | 273,254,248 | 121,927,270 | 2,795,015 | 9.66 |
| 2026-05-29 | 12,973,243 | 273,063,431 | 121,114,793 | 2,287,975 | 9.71 |
| 2026-05-30 | 13,185,842 | 272,106,880 | 123,953,149 | 2,755,803 | 9.73 |
| 2026-05-31 | 12,905,127 | 265,222,663 | 120,735,035 | 2,817,242 | 9.50 |
| 2026-06-01 | 15,389,767 | 336,494,791 | 147,528,309 | 2,700,326 | 10.39 |
| 2026-06-03 | 14,455,835 | 302,764,709 | 136,591,502 | 3,021,208 | 9.99 |

## 未覆盖项

- 小时级预算曲线：本次 DataStudio 轮询超时，需重跑或等 executionId 返回后补结果。
- Coverage / funnel rate：本次只跑了 ROI3 P0 指标和 ultra-core budget trace，未跑 tracking + omni 的覆盖率与漏斗 SQL。
- 发券分类比例：本次未跑 `pricing_type=29`、`deduction_reason=1`、regular ads 三分类 SQL。
- 最近一周策略功能变更：当前 KB 只有实验索引，没有系统 changelog。
