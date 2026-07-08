# Ads OKR Meeting Doc (ads-okr-meeting-doc) Guide

> **Language**: [English](ads-okr-meeting-doc.md) | [中文](ads-okr-meeting-doc.zh-CN.md)

Generate, fill, and review Ads team meeting documents. Supports two meeting types (adhoc / regular) and three modes (draft / record / check).

**Trigger keywords**: "meeting doc", "会议文档", "会议记录", "起草会议", "整理会议", "会议纪要", "填写讨论记录", "填行动项", "check meeting doc", "生成会议文档"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with three modes: `--draft`, `--record`, `--check` |

---

## Meeting Types

| Type | Use Case | Document Structure |
|------|----------|--------------------|
| **adhoc** | Ad-hoc discussion, review, kickoff, retrospective | Meeting Info + Pre-meeting Brief + Topics + Action Items |
| **例会** | Regular sync meeting (biweekly, weekly, etc.) | Meeting Info + Pre-meeting Brief (with report links) + Topics + Action Items |

**Pre-meeting Brief** is required for both types (all attendees must read before the meeting):
1. **Topic summaries**: one-line summary per Topic
2. **Pre-reading**: linked documents extracted from Topic Context (omit if none)
3. **Project progress report links**: links to KR/OKR reports — local markdown link + GitLab link (例会 only)

---

## Usage

### Mode 1: Draft before meeting

```
/ads-okr-meeting-doc --draft
```

Interactively collect meeting info and topics → generate a meeting doc draft and save to the meeting docs directory.

> **Note for 例会**: Before running `--draft`, generate the latest KR report first by running `/ads-okr-epic-report --range 2w <kr_id>`. The meeting doc will link to this report in the Pre-meeting Brief.

### Mode 2: Fill in after meeting

```
/ads-okr-meeting-doc --record <doc-path>
/ads-okr-meeting-doc --record <doc-path> <feishu-minutes-url>
```

Read a Feishu Minutes recording URL (or paste transcript) → fill in Discussion Notes, Conclusion, and Action Items for each topic.

### Mode 3: Review format compliance

```
/ads-okr-meeting-doc --check <doc-path>
```

Check whether the meeting doc meets the required format, with severity-based findings (🔴 must fix / 🟡 suggested).

---

## File Storage Convention

```
docs/team/00.paid-ads-dev/18.meeting-docs-list/
└── {quarter}/                        # e.g. 2026q2
    ├── 00.adhoc-meetings/            # all adhoc meetings in one directory
    │   └── YYYY-MM-DD-{title-slug}-{person}.md
    └── {nn}.{meeting-series}/        # one directory per regular meeting series
        └── YYYY-MM-DD-{person}.md   # e.g. 01.ads-dev-biweekly
```

| Type | File name format | Example |
|------|-----------------|---------|
| 例会 | `YYYY-MM-DD-{person}.md` | `2026-05-06-luka.yang.md` |
| adhoc | `YYYY-MM-DD-{title-slug}-{person}.md` | `2026-05-07-kickoff-ads-workspace-luka.yang.md` |

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `ads-okr-epic-report` | **Prerequisite** — generate kr-report/okr-report as input for 例会 draft |
| `ads-okr-epic-td` | Create or review Epic TD documents |
