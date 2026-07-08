<!-- Template version: 1.1 | Updated: 2026-05-04 -->

# ${YYYYMMDD}-${Biz}-${Entrance}-${BiddingType}-${Module}-Rollout

> **Language**: [English](rollout-doc.EN.md) | [中文](rollout-doc.md)

## 一、项目信息/Project Info

### 1.1 背景/Background

<!-- If there is an Epic TD, attach link to '1. Project Background and Objectives'; otherwise answer: Why do it? Approach? Key changes? 1-3 sentences each -->

${background}

### 1.2 方法/策略优化点/Method & Strategy

<!-- If there is an Epic TD, attach link to '3. Implementation Plan and Deployment' -->

${method}

### 1.3 Epic File

<!-- If no Epic File, explain the reason -->

For details, please see Epic File: ${epic_file_link}

### 1.4 参与者/Participants

- **Algo Dev**：${algo_dev}
- **BE**：${be_dev}
- **Indexer**：${indexer}

---

## 二、全量申请数据/Rollout Data

### 2.1 Experiment Info

- **Experiment Link**：${experiment_link}
- **Rollout Entrance**：${All | Search | RCMD_Unify | YMAL | DD | PP | Game}
- **Rollout BiddingType**：${All | Target2 | Simple2 | ManualMode | GMS&Adgroup}
- **Bucket Traffic Share**：${5%}

### 2.2 Core Metric Uplift Summary

<!-- Column abbreviations: VPR = Voucher_Profit_Rate, Mo. = Monthly, Ent. = Entrance, Rel. = Relative Uplift -->
<!-- abs = absolute uplift, Rel. = relative uplift, unit w usd = ten thousand USD -->
<!-- *. Rel. columns follow the corresponding Mo.* column and are computed from same-source raw absolute base / treatment, not directly from AB relative_diff -->
<!-- item / plan bucket Rev Achievement Rate abs / Rel. uses fulfilled_rev_pct(1d), aligned with 2.3 1d达标率; do not use 7d达标率 -->

| Region | VPR abs | VPR abs 995 | Rev Achievement Rate abs | Mo. Rev (w usd) | Rev Rel. | Mo. Advv (w usd) | Advv 1d Rel. | Mo. Advv 7d (w usd) | Advv 7d Rel. | Mo. Broad GMV (w usd) | Broad GMV Rel. | Mo. Broad GMV 999 (w usd) | Broad GMV 999 Rel. | Mo. Rev by CPM (w usd) | Mo. Advv by Imp (w usd) | Mo. Broad GMV by Imp (w usd) | Mo. Broad GMV 999 by Imp (w usd) | Rev Achievement Rate Rel. | Rev Adj. Rel. | Advv 999 Adj. Rel. | Advv Adj. Rel. | Ent. Rev Rel. | Ent. Advv Rel. | Ent. GMV Rel. | exp days | Rollout Date | Ticket |
| ------ | ------- | ----------- | ------------------------ | --------------- | -------- | ---------------- | ------------ | ------------------- | ------------ | --------------------- | -------------- | ------------------------- | ------------------ | ---------------------- | ----------------------- | ---------------------------- | -------------------------------- | ------------------------- | ------------- | ------------------- | -------------- | ------------- | -------------- | ------------- | -------- | ------------ | ------ |
| ID     |         |             |                          |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |                           |               |                     |                |               |                |               |          |              |        |
| MY     |         |             |                          |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |                           |               |                     |                |               |                |               |          |              |        |
| PH     |         |             |                          |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |                           |               |                     |                |               |                |               |          |              |        |
| TH     |         |             |                          |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |                           |               |                     |                |               |                |               |          |              |        |
| VN     |         |             |                          |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |                           |               |                     |                |               |                |               |          |              |        |
| SG     |         |             |                          |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |                           |               |                     |                |               |                |               |          |              |        |
| TW     |         |             |                          |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |                           |               |                     |                |               |                |               |          |              |        |
| BR     |         |             |                          |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |                           |               |                     |                |               |                |               |          |              |        |

### 2.3 Key Metrics List

<!-- Analyze each check failed metric one by one, analysis direction see Appendix C -->
<!-- One set of tables per region (Traffic-Bucket-Exp + Item-Bucket-Exp); only fill in regions involved in the experiment -->
<!-- Search has bad_query_rate compared to platform -->
<!-- voucher_profit_rate_uplift formula see Appendix B -->

#### ID

**Traffic-Bucket-Exp：**

| Entrance              | order_cnt | gmv | gmv_995 | gmv_995_v2 | revenue_usd | advv_cost_1d | broad_gmv | cost_ratio_1d | imp_cnt | rev/imp | advv/imp | bad_query_rate | ads_voucher_cost | voucher_profit_rate_uplift |
| --------------------- | --------- | --- | ------- | ---------- | ----------- | ------------ | --------- | ------------- | ------- | ------- | -------- | -------------- | ---------------- | -------------------------- |
| platform              |           |     |         |            |             |              |           |               |         |         |          | —              |                  |                            |
| search                |           |     |         |            |             |              |           |               |         |         |          |                |                  |                            |
| rcmd_unify            |           |     |         |            |             |              |           |               |         |         |          | —              |                  |                            |
| dd                    |           |     |         |            |             |              |           |               |         |         |          | —              |                  |                            |
| ymal                  |           |     |         |            |             |              |           |               |         |         |          | —              |                  |                            |
| cart                  |           |     |         |            |             |              |           |               |         |         |          | —              |                  |                            |
| game                  | —         | —   | —       | —          |             |              |           |               |         |         |          | —              | —                |                            |
| **Guardrail Summary** |           |     |         |            |             |              |           |               |         |         |          |                |                  |                            |
| **置信度分析-by day/Confidence Analysis-by day**      |           |     |         |            |             |              |           |               |         |         |          |                |                  |                            |
| **置信度分析-AA/Confidence Analysis-AA**          |           |     |         |            |             |              |           |               |         |         |          |                |                  |                            |

**Item-Bucket-Exp：**

| BiddingType           | rev | advv | broad_gmv | 1d达标率 | 1d超收率 | 1d欠收率 | cost_ratio | imp_cnt | rev/imp | advv/imp |
| --------------------- | --- | ---- | --------- | ----- | ----- | ----- | ---------- | ------- | ------- | -------- |
| platform              |     |      |           |       |       |       |            |         |         |          |
| Target2.0             |     |      |           |       |       |       |            |         |         |          |
| Simple2.0             |     |      |           |       |       |       |            |         |         |          |
| GMS&Adgroup           |     |      |           |       |       |       |            |         |         |          |
| **Guardrail Summary** |     |      |           |       |       |       |            |         |         |          |
| **置信度分析-by day/Confidence Analysis-by day**      |     |      |           |       |       |       |            |         |         |          |
| **置信度分析-AA/Confidence Analysis-AA**          |     |      |           |       |       |       |            |         |         |          |

<!-- Copy the ID tables above for each additional region as needed -->

#### MY

#### PH

#### TH

#### VN

#### SG

#### TW

#### BR

### 2.4 Guardrail 分析结论/Guardrail Analysis

<!-- Summarize analysis for each check-failed metric from 2.3. See Appendix C for analysis guidance. -->

| Region | Metric          | Analysis Conclusion    | Type          |
| ------ | ----------- | ------- | ----------- |
| ${RG}  | ${failed指标} | ${分析结论} | ${非策略/策略预期} |

---

## 附录/Appendix

### A. 标题字段枚举值/Title Field Values

| Field       | Options                                                                |
| ----------- | ---------------------------------------------------------------------- |
| Date        | YYYYMMDD                                                               |
| Biz         | ProductAds \| LiveAds \| VideoAds \| ShopAds \| BrandAds              |
| Entrance    | All \| Search \| RCMD_Unify \| YMAL \| DD \| PP \| Game \| Video \| Live |
| BiddingType | All \| Target2 \| Simple2 \| ManualMode \| GMS&Adgroup               |
| Module      | Recall \| Prerank \| Rank \| Bidding \| MixRank \| Deduction          |

### B. 计算公式/Formulas

**Monthly Uplift：**

```
uplift_abs_per_full_traffic = exp_abs_raw / exp_traffic_share - base_abs_raw / base_traffic_share
monthly_abs_uplift = uplift_abs_per_full_traffic × 30 / exp_days
monthly_abs_uplift_w_usd = monthly_abs_uplift / 10000
```

**Item-Bucket CPM/Imp Monthly Uplift：**

```
base_imp_norm = base_imp_raw / base_bucket_traffic_share
monthly_by_imp_w_usd = (exp_metric_per_imp - base_metric_per_imp) × base_imp_norm × 30 / exp_days / 10000
mo_rev_by_cpm_w_usd = (exp_rev_cpm - base_rev_cpm) / 1000 × base_imp_norm × 30 / exp_days / 10000
```

**AA-Adjusted Relative Uplift：**

```
base_pre_full = base_pre_raw / base_traffic_share
treatment_pre_full = treatment_pre_raw / treatment_traffic_share
pre_aa = treatment_pre_full / base_pre_full - 1

base_post_full = base_post_raw / base_traffic_share
treatment_post_full = treatment_post_raw / treatment_traffic_share
post_lift = treatment_post_full / base_post_full - 1

adjusted_lift = post_lift - pre_aa
```

`adjusted_lift` is a stability reference only and must be shown together with raw lift. If pre-window bucket availability is unconfirmed, render `**【待确认】Pre AA Bucket Availability**`.

**Voucher Profit Rate Uplift：**

```
voucher_profit_rate_uplift = (advv_uplift + platform_gmv_uplift / 4 - voucher_cost_uplift) / base_voucher_cost_norm
platform_gmv_uplift uses gmv_995_v2
```

### C. Guardrail Check Failed 分析方向/Guardrail Check Failed Analysis Directions

1. **Caused by non-strategy factors** (can be communicated offline): small traffic causing fluctuations (AA > AB diff); outliers skewing results (gmv↓ but gmv_995↑); negative impact from non-strategy entrances.
2. **Consistent with strategy expectations** (requires launch review): explain the core purpose of the strategy and why negative impact is acceptable.
