# 会议文档生成助手（ads-okr-meeting-doc）使用指南

> **语言**：[English](ads-okr-meeting-doc.md) | [中文](ads-okr-meeting-doc.zh-CN.md)

生成、整理和审查 Ads 团队会议文档。支持 adhoc / 例会两种类型和起草 / 整理 / 审查三种模式。

**唤醒词**：「meeting doc」、「会议文档」、「会议记录」、「起草会议」、「整理会议」、「会议纪要」、「填写讨论记录」、「填行动项」、「check meeting doc」、「生成会议文档」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含 `--draft`、`--record`、`--check` 三种模式 |

---

## 会议类型

| 类型 | 适用场景 | 文档结构 |
|------|----------|----------|
| **adhoc** | 专项讨论、评审、Kickoff、复盘 | 会议信息 + 会前摘要 + Topics + 行动项汇总 |
| **例会** | 定期同步（双周会、周会等） | 会议信息 + 会前摘要（含报告链接）+ Topics + 行动项汇总 |

**两种类型均有会前摘要**（参会人必须会前阅读）：
1. **Topics 摘要**：N 个 Topic 的一句话摘要
2. **会前必读**：从 Topic Context 提取的相关文档链接（无则省略）
3. **项目进展报告链接**：KR/OKR 报告的本地跳转链接和 GitLab 链接（仅例会）

---

## 使用场景

### 模式 1：会前起草

```
/ads-okr-meeting-doc --draft
```

交互式收集会议信息和 Topics → 生成会议文档草稿并保存到会议文档目录。

> **例会注意**：运行 `--draft` 前，请先通过 `/ads-okr-epic-report --range 2w <kr_id>` 生成最新 KR 报告。会议文档会在会前摘要中链接该报告。

### 模式 2：会后整理

```
/ads-okr-meeting-doc --record <doc-path>
/ads-okr-meeting-doc --record <doc-path> <feishu-minutes-url>
```

读取飞书妙记录音 URL（或粘贴文字稿）→ 填写每个 Topic 的讨论记录、结论和行动项汇总。

### 模式 3：格式审查

```
/ads-okr-meeting-doc --check <doc-path>
```

检查会议文档是否格式达标，按严重程度输出问题（🔴 必须修复 / 🟡 建议改进）。

---

## 文件存储规范

```
docs/team/00.paid-ads-dev/18.meeting-docs-list/
└── {quarter}/                        # 如 2026q2
    ├── 00.adhoc-meetings/            # 所有 adhoc 会议统一存放
    │   └── YYYY-MM-DD-{title-slug}-{person}.md
    └── {nn}.{meeting-series}/        # 每个例会系列独立目录
        └── YYYY-MM-DD-{person}.md   # 如 01.ads-dev-biweekly
```

| 类型 | 文件名格式 | 示例 |
|------|----------|------|
| 例会 | `YYYY-MM-DD-{person}.md` | `2026-05-06-luka.yang.md` |
| adhoc | `YYYY-MM-DD-{title-slug}-{person}.md` | `2026-05-07-kickoff-ads-workspace-luka.yang.md` |

---

## 相关 Skill

| Skill | 用途 |
|-------|------|
| `ads-okr-epic-report` | **前置步骤** — 生成 kr-report/okr-report 作为例会起草的输入 |
| `ads-okr-epic-td` | 创建或审查 Epic TD 文档 |
