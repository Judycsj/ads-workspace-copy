# Product Ads Epic Status Check (ads-okr-epic-status-check-pa) Guide

> **Language**: [English](ads-okr-epic-status-check-pa.md) | [中文](ads-okr-epic-status-check-pa.zh-CN.md)

Check Product Ads epic-file section 5 for execution-status completeness, freshness, experiment metric coverage, and milestone date order. In this skill name, `pa` means Product Ads.

**Trigger keywords**: "ads-okr-epic-status-check-pa", "Product Ads epic status check", "检查 epic 状态", "检查 epic file 完整性", "PA epic checker"

---

## Skill Files

| File | Description |
| --- | --- |
| `SKILL.md` | Main workflow and boundaries |
| `references/check-contract.md` | Complete check rules and output contract |
| `scripts/epic_status_check_pa.py` | Testable checker implementation |

---

## Usage

Check one epic file:

```text
/ads-okr-epic-status-check-pa docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1/kr4-kp6-202605061800/epic-file.md
```

Check one KP:

```text
/ads-okr-epic-status-check-pa O1-KR4-KP6
```

Check a directory:

```text
/ads-okr-epic-status-check-pa docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1
```

Set the freshness window:

```text
/ads-okr-epic-status-check-pa --range 7d O1-KR4-KP6
```

Direct script run:

```bash
uv run skills/common/ads-okr-epic-status-check-pa/scripts/epic_status_check_pa.py --range 7d O1-KR4-KP6
```

---

## Checks

| Check | What It Catches |
| --- | --- |
| Four elements | `5.3 KA progress`, `5.4 risk`, and `5.5 next step` are missing or stale for non-Done KAs; `5.2 experiment` is checked only after UAT / online experiment starts or 5.2 has a real experiment / rollout link, date, or data; issue text includes the section label |
| Experiment | For online-experiment KAs in 5.1, or KAs whose 5.2 row already has an experiment platform link: UAT has started for more than 2 days but experiment link or inferred-bucket core metrics are missing; metrics may be in the KA experiment row or a 5.2 KA supplemental block / table |
| Milestone | Owner / ETA / Effort missing, invalid stage date, `TD <= Dev <= Int <= UAT <= Done` violation, ETA already due with all stage dates empty, or 5.2 / 5.3 / 5.5 progress that has not been synced into 5.1 stage dates |

Traffic and Item metric contracts are defined in `references/check-contract.md`.

---

## Output

The output is grouped by KR:

```md
## Epic Status Check Issues

### O1-KR4

| KP | 项目名 | PIC | 检查项 | 问题 | 证据 | 建议补充 |
| --- | --- | --- | --- | --- | --- | --- |
| KP6 | PCOC Calibration | quan.zheng | 四要素检查 | 5.3 KA 进度 过去 7 天无更新 | 2026-05-13 | 补充最近 7 天内的 5.3 KA 进度 更新 |
```

`ads-okr-meeting-doc --draft` can use the same table as Topic context and creates one Topic per KR.

---

## Boundaries

- Read-only. It does not modify epic-file.
- It does not judge experiment uplift, statistical significance, or rollout readiness.
- It infers bucket type from synced experiment data; bidding-related experiments default to Item, other experiments default to Traffic.
- Use `ads-okr-epic-review` for Epic TD design quality review.
- Use `ads-okr-epic-report` for progress reports.
