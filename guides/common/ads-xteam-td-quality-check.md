# Ads XTeam TD Quality Check Guide/Ads XTeam TD 质量检测使用指南
> **Contributors**: shuo.zhao ｜ **最后更新**：2026-06-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-xteam-td-quality-check.md)
> **Language**: [English](ads-xteam-td-quality-check.md) | [中文](ads-xteam-td-quality-check.zh-CN.md)

Review an Ads Tech Design against its PRD business goals and identify TD issues that require modification. The skill has two modes: analysis mode discovers TD issues using the normal PRD-to-TD review logic, while recheck mode verifies an existing issue list without adding new issues. The two mode contracts live in separate rule files under the skill's `references/` directory to avoid mixing discovery and verification behavior. The default result language is English unless the user explicitly asks for Chinese.

Both modes now return JSON. `td_summary` must be exactly one sentence and no more than 30 words. Analysis mode returns `td_summary`, `eta`, `pd`, and `modification_issues`. Recheck mode returns `td_summary`, `eta`, `pd`, `issue_verdicts`, and `overall`. If the TD does not state an explicit overall ETA, analysis mode reports that as a required modification issue.

**Trigger keywords**: "ads-xteam-td-quality-check", "$ads-xteam-td-quality-check", "TD quality check", "quality verify", "TD verify", "Tech Design review", "review Tech Design", "TD review", "review TD", "check TD", "check Tech Design", "帮忙review TD", "技术方案质检", "TD质检", "TD评审", "技术方案评审", "技术设计评审", "复查TD", "复查TD问题", "TD问题复查", "verify TD", "verify TD issues", "check whether these TD issues are fixed"

## Typical Usage/典型用法

Analysis mode:

```text
Use $ads-xteam-td-quality-check to review this PRD and TD: <PRD link/content> <TD link/content>
```

Recheck mode:

```text
Use $ads-xteam-td-quality-check to verify whether these existing TD issues are fixed: <issue list> <PRD link/content> <updated TD link/content>
```

Provide both PRD and TD content whenever possible. For recheck mode, also provide the frozen issue list. If one required input is missing, the skill should ask for the missing content instead of guessing.

## Output/输出内容

Analysis mode output is in English by default and returns one JSON object:

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

Recheck mode output is one JSON object by default:

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

In analysis mode, each item in `modification_issues` must be one sentence that explains the concrete problem, not a fix instruction. `PD` is computed only from explicit TD effort estimates; if the effort is absent or too ambiguous to sum, the output should use `null` instead of guessing. In recheck mode, `pass` means the current TD clearly fixes the input issue, `fail` means the issue remains or is only partially fixed, and `unclear` means the available PRD/TD content cannot prove the fix. `overall` is `passed` only when every issue passes; otherwise it is `blocked`.

## Boundaries/边界

- It uses only PRD, TD, comments/suggestions, and explicit user-provided context.
- It does not infer issues from common engineering practice or personal preference.
- In recheck mode, it verifies only the provided issue list and does not raise new TD issues.
- It does not inspect code, production systems, Jira, Sheets, Figma, or external docs unless explicitly requested.
- It does not generate or rewrite the TD unless the user asks for a separate editing task.
