# 广告诊断（ads-diagnose）使用指南

> **Contributors**: luka.yang, qianqian.pu ｜ **最后更新**：2026-06-02 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-diagnose.zh-CN.md)
> **Language**: [English](ads-diagnose.md) | [中文](ads-diagnose.zh-CN.md)

通过查询 ClickHouse 漏斗、出价和预估数据，诊断广告效果异常。用于排查 ads_id、campaign_id 或 shop_id 的效果问题。

**唤醒词**：「ads-diagnose」、「广告诊断」、「ads_id」、「campaign_id」、「shop_id」、「效果异常」、「广告排查」、「cost 骤降」、「超收」、「停投」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含诊断流水线和 SQL 模板 |
| `references/factual_nodes.md` | 异常类型定义（A1-A14、B1-B15）和归因节点定义（R1-R10） |
| `references/table_info.md` | ClickHouse 表结构和字段详情 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| ClickHouse 访问权限 | 网络 | 需要办公网络或 VPN 才能访问 ClickHouse 集群 |

---

## 使用场景

### 场景 1：单个 Campaign 诊断

> 「帮我诊断 campaign_id 12345，region ID」

Skill 会解析 ID、查询 campaign 级别 7 天数据、检测异常（A 系列）、构建因果链，然后下钻到 ad 级别数据。

### 场景 2：Shop 级别诊断

> 「shop 67890 昨天收入暴跌」

先识别该 shop 下的 Top Campaign，再逐个深入分析，避免聚合数据掩盖单 campaign 信号。

### 场景 3：广告零曝光排查

> 「ads_id 99999 今天零曝光」

查询 ad 级别漏斗数据和状态/停投原因表，定位广告停投原因。

## 诊断流程

1. **Step 0** — ID 识别：判断 ID 类型，解析 campaign_id、shop_id、region
2. **Step 0.5** —（仅 shop_id）按收入识别 Top Campaign
3. **Step 1** — Campaign 级别概览：每日指标、漏斗、出价、预算
4. **Step 2** — Ad 级别下钻：逐广告漏斗和趋势分析
5. **Step 3** — 状态和停投原因（针对零曝光广告）；同时查询 campaign 级别多广告操作日志（R1.1/R1.2 fallback），捕获可能不出现在 ad 级别日志中的批量操作
6. **Step 4** — 异常检测：分类异常（A 系列用于 campaign，B 系列用于 shop）
7. **Step 5** — L1 一级模块判定（R1-R10）：R1 交叉校验 UNION + STATUS 操作日志并按方向过滤；R3/R4 对超收和欠收两个方向均做方向感知过滤；R4 增加相对退化检查；R6 评估跨指标联合退化信号
8. **Step 6** — 桶路由：自身桶由主 skill 展开；R3/R4 命中时调度专属 sub-agent 做深入分析
9. **Step 7** — 合并报告，输出最终诊断结论

---

## 输出格式

所有回答统一采用结构化诊断报告：

- **上下文** — campaign/shop/region/时间段/计价类型
- **摘要** — 1-3 句概述检测到的异常和关键根因
- **异常检测** — 编号异常类型，附具体指标数值
- **根因归因** — 归因节点，附证据、角色标签和建议
- **PCOC & 漏斗汇总** — 每日指标表格
- **7 天聚合** — cost_7d、advv_7d、cost_ratio_7d、gmv_7d
