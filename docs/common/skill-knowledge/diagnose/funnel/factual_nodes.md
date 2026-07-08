<!-- ads-workspace-gdoc-sync: gdoc_id=1N5-9z2CTJ4vDjMeetmhXI_iOA0cU3J5Yfhkxe33ejBU gdoc_url=https://docs.google.com/document/d/1N5-9z2CTJ4vDjMeetmhXI_iOA0cU3J5Yfhkxe33ejBU/edit -->

# R5 广告链路异常归因节点/R5 Ads Pipeline Anomaly Attribution Nodes

> **Contributors**: luka.yang ｜ **最后更新**：2026-05-28 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/skill-knowledge/diagnose/funnel/factual_nodes.md)

---

本文件定义 R5（广告链路异常）的二级归因叶子节点，供 funnel subagent 使用。
一级 R5 定义见 `../overall/factual_nodes.md`。

---

## 下降方向（掉量）/Drop Direction (Volume Loss)

### R5.1: 召回骤降
- **检测**: `after_recall_num_0 / after_recall_num_1 - 1 < -0.5`
- **含义**: 召回阶段通过数量环比下降超 50%，上游召回策略可能变更
- **备注**: `role: direct`

### R5.2: 粗排骤降
- **检测**: `after_prerank_num_0 / after_prerank_num_1 - 1 < -0.5`
- **含义**: 粗排阶段通过数量环比下降超 50%
- **备注**: `role: direct`

### R5.3: 精排骤降
- **检测**: `after_rank_num_0 / after_rank_num_1 - 1 < -0.5`
- **含义**: 精排阶段通过数量环比下降超 50%
- **备注**: `role: direct`

### R5.4: 出价系数骤降 (pid_coef)
- **检测**: `final_coef_0 / final_coef_1 - 1 < -0.5`
- **含义**: 出价系数环比下降超 50%，直接降低 eCPM 竞争力
- **备注**: `role: direct`

---

## 暴涨方向（爆量）/Spike Direction (Volume Surge)

### R5.5: 召回暴涨
- **检测**: `after_recall_num_0 / after_recall_num_1 > 1.5`
- **含义**: 召回阶段通过数量环比上涨超 50%
- **备注**: `role: direct`

### R5.6: 粗排暴涨
- **检测**: `after_prerank_num_0 / after_prerank_num_1 > 1.5`
- **含义**: 粗排阶段通过数量环比上涨超 50%
- **备注**: `role: direct`

### R5.7: 精排暴涨
- **检测**: `after_rank_num_0 / after_rank_num_1 > 1.5`
- **含义**: 精排阶段通过数量环比上涨超 50%
- **备注**: `role: direct`

### R5.8: 出价系数暴涨
- **检测**: `final_coef_0 / final_coef_1 > 1.5`
- **含义**: 出价系数环比上涨超 50%，直接提升 eCPM 竞争力
- **备注**: `role: direct`

---

## 漏斗通过率/Funnel Pass-Through Rate

按天计算通过率：
- `prerank_rate = after_prerank_num / after_recall_num`
- `rank_rate = after_rank_num / after_prerank_num`
- `mixrank_rate = after_mixrank_num / after_rank_num`

### R5.9: 粗排通过率骤降
- **检测**: `prerank_rate_0 / prerank_rate_1 < 0.5`
- **含义**: 召回量未降但粗排大量过滤，可能因粗排模型变更或质量分下降
- **备注**: `role: direct`

### R5.10: 粗排通过率骤涨
- **检测**: `prerank_rate_0 / prerank_rate_1 > 1.5`
- **含义**: 粗排过滤放松，可能导致低质量广告进入精排
- **备注**: `role: direct`

### R5.11: 精排通过率骤降
- **检测**: `rank_rate_0 / rank_rate_1 < 0.5`
- **含义**: 粗排量未降但精排大量过滤，可能因精排模型变更、eCPM 竞争力下降或质量阈值调整
- **备注**: `role: direct`

### R5.12: 精排通过率骤涨
- **检测**: `rank_rate_0 / rank_rate_1 > 1.5`
- **含义**: 精排过滤放松，可能导致低质量广告获得曝光
- **备注**: `role: direct`

### R5.13: 混排通过率骤降
- **检测**: `mixrank_rate_0 / mixrank_rate_1 < 0.5`
- **含义**: 精排通过但混排大量淘汰，常见于广告位竞争力不足（与 R6 广告位质量坍塌相关）
- **备注**: `role: direct`

### R5.14: 混排通过率骤涨
- **检测**: `mixrank_rate_0 / mixrank_rate_1 > 1.5`
- **含义**: 混排过滤放松，可能因竞争环境变化或混排策略调整
- **备注**: `role: direct`

---
