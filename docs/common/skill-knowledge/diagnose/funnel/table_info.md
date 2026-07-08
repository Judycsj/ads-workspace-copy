<!-- ads-workspace-gdoc-sync: gdoc_id=1ljlYRvpntGoqqSUp6MLVk-0HhUnyOOasbq-kAi1L4_M gdoc_url=https://docs.google.com/document/d/1ljlYRvpntGoqqSUp6MLVk-0HhUnyOOasbq-kAi1L4_M/edit -->

# R5 广告链路异常 — 相关表和字段定义/R5 Ads Pipeline Anomalies — Table & Field Definitions

> **Contributors**: luka.yang ｜ **最后更新**：2026-05-28 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/skill-knowledge/diagnose/funnel/table_info.md)

---

本文件定义 R5（广告链路异常）归因所需的表和字段信息。完整表定义见 `../overall/table_info.md`。

数据来源表：`mkplpaidads_search_ads.ads_union_key_metrics_daily__reg_s0_live`（ClickHouse）

> **约定说明**:
> - `_0` = 诊断日，`_1` = 前一天
> - 漏斗指标来源: `mkplpaidads_search_ads.full_link_funnel_metrics_daily__reg_s0_live`
> - JOIN 条件: `ads_id + regional_date + country + entrance`

---

## 全链路漏斗指标/Full-Link Funnel Metrics

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `request_cnt` | bigint | 参竞请求数 (10% 采样, ads recall 10%, full link 5%) |
| `after_recall_num` | bigint | 召回通过请求数, 包含 ads 和 organic 链路 |
| `ads_after_recall_num` | bigint | 广告召回通过请求数, 仅 ads 链路 |
| `org_after_recall_num` | bigint | 自然结果召回通过请求数, 仅 organic 链路 |
| `after_prerank_num` | bigint | 粗排通过请求数 |
| `after_rank_num` | bigint | 精排通过请求数 |
| `after_mixrank_num` | bigint | 混排通过请求数 |

---

## 出价系数字段/Bidding Coefficient Fields

R5.4/R5.8 需要出价系数数据来检测系数骤降/暴涨。

| 字段 | 类型 | 口径说明 |
|------|------|----------|
| `coef_sum_by_imp` | double | PID 系数之和（按曝光） |
| `final_coef` | double | 最终系数（来源 static_ads_info_metrics） |

---

## R5 常用衍生指标/R5 Common Derived Metrics

| 衍生指标 | 计算公式 | 用途 |
|----------|----------|------|
| 粗排通过率 | `after_prerank_num / after_recall_num` | R5.9/R5.10 检测 |
| 精排通过率 | `after_rank_num / after_prerank_num` | R5.11/R5.12 检测 |
| 混排通过率 | `after_mixrank_num / after_rank_num` | R5.13/R5.14 检测 |
| 召回率 | `ads_after_recall_num / request_cnt` | 辅助分析 |

---
