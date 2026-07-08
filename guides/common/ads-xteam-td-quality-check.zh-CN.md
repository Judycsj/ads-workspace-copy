# Ads XTeam TD 质量检测使用指南/Ads XTeam TD Quality Check Guide
> **Contributors**: shuo.zhao ｜ **最后更新**：2026-06-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-xteam-td-quality-check.zh-CN.md)
> **Language**: [English](ads-xteam-td-quality-check.md) | [中文](ads-xteam-td-quality-check.zh-CN.md)

基于 PRD 业务目标检查 Ads Tech Design，并识别需要修改的 TD 问题。skill 有两种模式：分析模式会按原有 PRD-to-TD 评审逻辑发现 TD 问题；复查模式会验证已有问题列表是否修复，不再提出新问题。两种模式的契约分别放在 skill 的 `references/` 目录下，避免发现问题和复查问题的行为混用。默认输出英文结果，只有用户明确要求中文时才输出中文。

两种模式现在都输出 JSON。`td_summary` 必须是单句且不超过 30 词。分析模式输出 `td_summary`、`eta`、`pd`、`modification_issues`；复查模式输出 `td_summary`、`eta`、`pd`、`issue_verdicts`、`overall`。如果 TD 没有明确写 overall ETA，分析模式会把它当成缺少必要信息的必报问题。

**触发关键词/Trigger keywords**: "ads-xteam-td-quality-check", "$ads-xteam-td-quality-check", "TD quality check", "quality verify", "TD verify", "Tech Design review", "review Tech Design", "TD review", "review TD", "check TD", "check Tech Design", "帮忙review TD", "技术方案质检", "TD质检", "TD评审", "技术方案评审", "技术设计评审", "复查TD", "复查TD问题", "TD问题复查", "verify TD", "verify TD issues", "check whether these TD issues are fixed"

## 典型用法/Typical Usage

分析模式：

```text
使用 $ads-xteam-td-quality-check 检查这个 PRD 和 TD: <PRD 链接或内容> <TD 链接或内容>
```

复查模式：

```text
使用 $ads-xteam-td-quality-check 复查这些 TD 问题是否已经修复: <已有问题列表> <PRD 链接或内容> <更新后的 TD 链接或内容>
```

尽量同时提供 PRD 和 TD 内容。复查模式还需要提供冻结的已有问题列表。如果缺少必要输入，skill 应先要求补充缺失内容，而不是凭经验猜测。

## 输出内容/Output

分析模式默认输出英文，并返回一个 JSON 对象：

```json
{
  "td_summary": "one sentence, <=30 words",
  "eta": "explicit overall ETA string or null",
  "pd": 10,
  "modification_issues": [
    "one-sentence issue explaining the concrete problem"
  ]
}
```

复查模式默认输出一个 JSON 对象：

```json
{
  "td_summary": "one sentence, <=30 words",
  "eta": "explicit overall ETA string or null",
  "pd": 10,
  "issue_verdicts": [
    {
      "id": "Q1",
      "verdict": "pass|fail|unclear",
      "evidence_quote": "short excerpt",
      "pic_action": "one line if fail/unclear"
    }
  ],
  "overall": "passed|blocked"
}
```

分析模式下，`modification_issues` 里的每个问题都必须用一句话说明具体问题本身，而不是写成修复指令。`PD` 只基于 TD 里明确写出的 effort 计算；如果 effort 缺失或无法安全汇总，就输出 `null`，不允许猜测。复查模式下，`pass` 表示当前 TD 已清楚修复该输入问题，`fail` 表示问题仍存在或只部分修复，`unclear` 表示现有 PRD/TD 内容无法证明是否已修复。只有所有问题都是 `pass` 时 `overall` 才是 `passed`，否则为 `blocked`。

## 边界/Boundaries

- 只使用 PRD、TD、评论/建议和用户明确提供的上下文。
- 不基于通用工程经验或个人偏好推断问题。
- 复查模式只验证输入的已有问题列表，不提出新的 TD 问题。
- 默认不检查代码、生产系统、Jira、Sheet、Figma 或外部文档，除非用户明确要求。
- 不生成或改写 TD，除非用户另行提出编辑任务。
