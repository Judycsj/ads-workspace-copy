<!-- ads-workspace-gdoc-sync: gdoc_id=1-kTFTHl5U-9dhe_q4jPw0qtS0XAEIxditaCGOP2VUq8 gdoc_url=https://docs.google.com/document/d/1-kTFTHl5U-9dhe_q4jPw0qtS0XAEIxditaCGOP2VUq8/edit -->

# R3 模型预估异常 — 相关表和字段定义/R3 Model Estimation — Table & Field Definitions

> **Contributors**: luka.yang ｜ **最后更新**：2026-05-28 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/skill-knowledge/diagnose/rank-model/table_info.md)

---

本文件定义 R3（模型预估异常）归因所需的表和字段信息。完整表定义见 `../overall/table_info.md`。

数据来源表：`mkplpaidads_search_ads.ads_union_key_metrics_daily__reg_s0_live`（ClickHouse）

> **约定说明**:
> - `_by_imp` 后缀表示按曝光粒度聚合（条件 `impression_cnt > 0`）
> - `_by_clk` 后缀表示按点击粒度聚合（条件 `deduplicated_click > 0`）
> - `_7d` 后缀表示最近 7 天聚合
> - 金额类字段在上游 `perf` 表中为本地币*100000，产出时除以 `exchange_rate` 转为 USD

---

## 核心效果指标/Core Performance Metrics

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `ads_imp` | bigint | 去重后的 impression |
| `ads_clk` | bigint | 去重后点击数 |
| `broad_gmv_usd` | double | Broad 口径 GMV (USD), 同 shop 下单订单 |
| `broad_gmv_usd_7d` | double | 近 7 日宽口径 GMV |

---

## 出价预估字段（按曝光聚合）/Bid & Prediction Metrics (by Impression)

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `pctr_sum_by_imp` | double | pCTR 之和（按曝光），到达口径，校准后值 |
| `pcr_direct_sum_by_imp` | double | 直接 pCR 之和（按曝光），到达口径，校准后值 |
| `pcr_broad_sum_by_imp` | double | 宽口径 pCR 之和（按曝光），broad pcr = direct_pcr_7d + shop_pcr_7d |
| `pcr_direct_fail_imp_cnt` | bigint | 直接 pCR 为空或 <=0 的曝光次数 |
| `pgmv_direct_sum_by_imp` | double | 直接 pGMV 之和 (USD, 按曝光) |
| `pgmv_broad_sum_by_imp` | double | 宽口径 pGMV 之和 (USD, 按曝光) |
| `final_pgmv_sum_by_imp` | double | 最终 pGMV 之和 (USD, 按曝光) |
| `item_price_sum_by_imp` | double | 商品价格之和 (USD, 按曝光) |

---

## 出价预估字段（按点击聚合）/Bid & Prediction Metrics (by Click)

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `pcr_direct_sum_by_clk` | double | 直接转化率预估之和（按点击） |
| `pgmv_direct_sum_by_clk` | double | 直接 pGMV 之和 (USD, 按点击) |
| `pgmv_broad_sum_by_clk` | double | 宽口径 pGMV 之和 (USD, 按点击) |
| `final_pgmv_sum_by_clk` | double | 最终 pGMV 之和 (USD, 按点击) |

---

## PCOC 校准指标/PCOC Calibration Metrics

> 校准逻辑: `pgmv / 100000.0 * cali_ratio_daily(hour, feedback_ratio_1h/3h/24h/72h)[day_offset]`
> 窗口: 最近 8 天数据, 仅有点击的行, 排除 `uni_pcr_model_name='gpu_newdatav1_id'`

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `daily_pgmv_sum_last_7d_clk` | double | 近 7 日校准后 pGMV 之和 (USD) |
| `daily_padvv_sum_last_7d_clk` | double | 近 7 日校准后 pADVV 之和 (USD) |

---

## R3 常用衍生指标/R3 Common Derived Metrics

| 衍生指标 | 计算公式 | 用途 |
|----------|----------|------|
| PCOC (pGMV) | `daily_pgmv_sum_last_7d_clk / broad_gmv_usd` | R3.1.1/R3.1.2 检测 |
| pCTR PCOC | `pctr_sum_by_imp / ads_clk` | R3.2.1/R3.2.2 检测 |
| pCR 失败率 | `pcr_direct_fail_imp_cnt / ads_imp` | R3.4.1 检测 |
| 平均 pCTR | `pctr_sum_by_imp / ads_imp` | 辅助分析 |

---
