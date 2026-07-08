<!-- Template version: 1.4 | Updated: 2026-06-17 -->

# ${YYYYMMDD}-${Biz}-${Entrance}-${BiddingType}-${Module}-Rollout

> **Language**: [English](rollout-doc.EN.md) | [中文](rollout-doc.md)

## 一、项目信息/Project Info

### 1.1 背景/Background

<!-- 有 Epic TD 则附链接《一、项目背景和目标》；否则回答：为什么做？方案思路？关键改动？各 1-3 句 -->

${background}

### 1.2 方法/策略优化点/Method & Strategy

<!-- 有 Epic TD 则附链接《三、实现方案和落地实施》 -->

${method}

### 1.3 Epic File

<!-- 无 Epic File 需说明原因 -->

详情请见 Epic File：${epic_file_link}

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

<!-- 列名缩写：VPR = Voucher_Profit_Rate, Mo. = Monthly, Ent. = Entrance, Rel. = Relative Uplift -->
<!-- abs = 绝对值提升, Rel. = 相对值提升, 单位 w usd = 万美元 -->
<!-- *. Rel. 紧跟对应 Mo.* 列后，从同源 raw absolute base / treatment 计算；不直接使用 AB relative_diff -->
<!-- item / plan bucket 的 Rev达标率 abs / Rel. 固定使用 fulfilled_rev_pct(1d)，需与 2.3 的 1d达标率对齐；不要用 7d达标率 -->

| Region | VPR abs | VPR abs 995 | Rev达标率 abs | Mo. Rev (w usd) | Rev Rel. | Mo. Advv (w usd) | Advv 1d Rel. | Mo. Advv 7d (w usd) | Advv 7d Rel. | Mo. Broad GMV (w usd) | Broad GMV Rel. | Mo. Broad GMV 999 (w usd) | Broad GMV 999 Rel. | Mo. Rev by CPM (w usd) | Mo. Advv by Imp (w usd) | Mo. Broad GMV by Imp (w usd) | Mo. Broad GMV 999 by Imp (w usd) | Rev达标率 Rel. | Rev Adj. Rel. | Advv 999 Adj. Rel. | Advv Adj. Rel. | Ent. Rev Rel. | Ent. Advv Rel. | Ent. GMV Rel. | exp days | Rollout Date | Ticket |
| ------ | ------- | ----------- | ---------- | --------------- | -------- | ---------------- | ------------ | ------------------- | ------------ | --------------------- | -------------- | ------------------------- | ------------------ | ---------------------- | ----------------------- | ---------------------------- | -------------------------------- | ----------- | ------------- | ------------------- | -------------- | ------------- | -------------- | ------------- | -------- | ------------ | ------ |
| ID     |         |             |            |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |             |               |                     |                |               |                |               |          |              |        |
| MY     |         |             |            |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |             |               |                     |                |               |                |               |          |              |        |
| PH     |         |             |            |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |             |               |                     |                |               |                |               |          |              |        |
| TH     |         |             |            |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |             |               |                     |                |               |                |               |          |              |        |
| VN     |         |             |            |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |             |               |                     |                |               |                |               |          |              |        |
| SG     |         |             |            |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |             |               |                     |                |               |                |               |          |              |        |
| TW     |         |             |            |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |             |               |                     |                |               |                |               |          |              |        |
| BR     |         |             |            |                 |          |                  |              |                     |              |                       |                |                           |                    |                        |                         |                              |                                  |             |               |                     |                |               |                |               |          |              |        |

### 2.3 Key Metrics List

<!-- 逐个分析 check failed 指标，分析方向见附录 C -->
<!-- 每个 region 一组表格（Traffic-Bucket-Exp + Item-Bucket-Exp）；仅填写实验涉及的 region -->
<!-- search 比 platform 多 bad_query_rate -->
<!-- voucher_profit / voucher_profit_rate_uplift 公式见附录 B -->
<!-- 置信度分析-by day 对 traffic-bucket 和 item-bucket 都必须输出 x/n；有 period metric 时不能填 '-' -->

#### ID

**Traffic-Bucket-Exp：**

| Entrance              | order_cnt | gmv | gmv_995 | gmv_995_v2 | revenue_usd | advv_cost_1d | advv_cost_7d | advv_cost_1d_999 | broad_gmv | broad_gmv_999 | cost_ratio_1d | imp_cnt | rev/imp | advv/imp | bad_query_rate | ads_voucher_cost | voucher_profit | voucher_profit_rate_uplift |
| --------------------- | --------- | --- | ------- | ---------- | ----------- | ------------ | ------------ | ---------------- | --------- | ------------- | ------------- | ------- | ------- | -------- | -------------- | ---------------- | -------------- | -------------------------- |
| platform              |           |     |         |            |             |              |              |                  |           |               |               |         |         |          | —              |                  |                |                            |
| search                |           |     |         |            |             |              |              |                  |           |               |               |         |         |          |                |                  |                |                            |
| rcmd_unify            |           |     |         |            |             |              |              |                  |           |               |               |         |         |          | —              |                  |                |                            |
| dd                    |           |     |         |            |             |              |              |                  |           |               |               |         |         |          | —              |                  |                |                            |
| ymal                  |           |     |         |            |             |              |              |                  |           |               |               |         |         |          | —              |                  |                |                            |
| cart                  |           |     |         |            |             |              |              |                  |           |               |               |         |         |          | —              |                  |                |                            |
| game                  | —         | —   | —       | —          |             |              |              |                  |           |               |               |         |         |          | —              | —                | —              |                            |
| **Guardrail Summary** |           |     |         |            |             |              |              |                  |           |               |               |         |         |          |                |                  |                |                            |
| **置信度分析-by day**      |           |     |         |            |             |              |              |                  |           |               |               |         |         |          |                |                  |                |                            |
| **置信度分析-AA negative risk** |           |     |         |            |             |              |              |                  |           |               |               |         |         |          |                |                  |                |                            |
| **置信度分析-AA positive sig**  |           |     |         |            |             |              |              |                  |           |               |               |         |         |          |                |                  |                |                            |

**Item-Bucket-Exp：**

| BiddingType           | rev | advv | broad_gmv | 1d达标率 | 1d超收率 | 1d欠收率 | cost_ratio | imp_cnt | rev/imp | advv/imp |
| --------------------- | --- | ---- | --------- | ----- | ----- | ----- | ---------- | ------- | ------- | -------- |
| platform              |     |      |           |       |       |       |            |         |         |          |
| Target2.0             |     |      |           |       |       |       |            |         |         |          |
| Simple2.0             |     |      |           |       |       |       |            |         |         |          |
| GMS&Adgroup           |     |      |           |       |       |       |            |         |         |          |
| **Guardrail Summary** |     |      |           |       |       |       |            |         |         |          |
| **置信度分析-by day**      |     |      |           |       |       |       |            |         |         |          |
| **置信度分析-AA negative risk** |     |      |           |       |       |       |            |         |         |          |
| **置信度分析-AA positive sig**  |     |      |           |       |       |       |            |         |         |          |

<!-- 其余 region 按需复制上方 ID 的表格模板，替换 #### 标题即可 -->
<!-- Copy the ID tables above for each additional region as needed -->

#### MY

#### PH

#### TH

#### VN

#### SG

#### TW

#### BR

### 2.4 Guardrail 分析结论/Guardrail Analysis

<!-- 汇总 2.3 中 check failed 的指标，逐个给出分析结论。分析方向见附录 C。 -->
<!-- Summarize analysis for each check-failed metric from 2.3. See Appendix C for analysis guidance. -->

| Region | 指标          | 分析结论    | 类型          |
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

**Voucher Profit Rate Uplift：**

```
voucher_profit = advv_cost_1d_uplift + gmv_995_v2_uplift / 4 - voucher_cost_uplift
voucher_profit_rate_uplift = voucher_profit / base_voucher_cost_norm
voucher_profit uses gmv_995_v2, not gmv / broad_gmv
```

**Voucher Profit Rate 995 Uplift：**

```
VPR_995 = (advv_cost_1d_999_uplift + gmv_995_v2_uplift / 4 - voucher_cost_uplift) / base_voucher_cost_norm
```

**Relative Reference（*. Rel.）：**

```
base_full = base_abs_raw / base_traffic_share
exp_full = exp_abs_raw / exp_traffic_share
rel_reference = exp_full / base_full - 1
*. Rel. 必须与对应 Mo.* 使用同源 raw absolute base / treatment
不直接取 AB relative_diff；不从月化后 Mo.* 反推
```

**减 AA 相对提升/AA-Adjusted Relative Uplift：**

```
base_pre_full = base_pre_raw / base_traffic_share
treatment_pre_full = treatment_pre_raw / treatment_traffic_share
pre_aa = treatment_pre_full / base_pre_full - 1

base_post_full = base_post_raw / base_traffic_share
treatment_post_full = treatment_post_raw / treatment_traffic_share
post_lift = treatment_post_full / base_post_full - 1

adjusted_lift = post_lift - pre_aa
```

`adjusted_lift` 只能作为稳定化参考，必须与 raw lift 同时展示；pre window 内 base / treatment 桶位可用性未确认时，填 `**【待确认】Pre AA Bucket Availability**`。

**Region=ALL Relative Reference：**

```
all_base_full = sum(region_base_abs_raw / region_base_traffic_share)
all_exp_full = sum(region_exp_abs_raw / region_exp_traffic_share)
all_rel_reference = all_exp_full / all_base_full - 1
不对 region 百分比求和或平均
```

### C. Guardrail Check Failed 分析方向

1. **非策略导致**（可 offline 沟通）：流量小致波动（AA > AB diff）；异常值拉偏（gmv↓ 但 gmv_995↑）；负向来自非策略 entrance
2. **符合策略预期**（需上 launch review）：解释策略核心目的，说明为何接受负向
