# Ads Data Analyze (ads-data-analyze) Guide

> **Language**: [English](ads-data-analyze.md) | [中文](ads-data-analyze.zh-CN.md)

Analyzes query results, generates insights, and produces structured analysis reports. Supports iterative analysis with sub-task result accumulation and extended actions like writing table documentation, exporting data, and suggesting follow-up queries.

**Trigger keywords**: "ads-data-analyze", "analyze results", "generate report", "数据洞察", "分析结果", "帮我分析数据"

---

## When to Use

- **Directly**: `/ads-data-analyze` + paste data — when you have query results and want analysis
- **Via delegation**: Called by `ads-data-text2da` after SQL execution completes
- **Iterative mode**: For multi-subtask analyses, accumulates findings across iterations

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Skill definition with analysis workflow, report templates, and extended actions |

---

## Analysis Capabilities

| Capability | Description |
|------------|-------------|
| Data validation | Check nulls, unexpected zeros, completeness |
| Pattern recognition | Trends, anomalies (DoD >50%, WoW >30%), outliers |
| Derived metrics | CTR, CVR, CPC, ROAS, CIR, DoD/WoW change rates |
| Cross-validation | Compare with prior sub-task findings |

---

## Extended Actions

| Action | Description |
|--------|-------------|
| Write table docs | Update table KB based on analysis findings |
| Export data | Save results as CSV to personal directory |
| Suggest follow-ups | Recommend further queries based on findings |

---

## Related Skills

| Skill | Relationship |
|-------|-------------|
| `ads-data-text2da` | Orchestrator that generates SQL and delegates analysis here |
| `ads-data-sql-executor` | Executes SQL and passes results to this skill |
