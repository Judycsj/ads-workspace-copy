# Ads OKR Epic Report (ads-okr-epic-report) Guide

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-02 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-okr-epic-report.md)
> **Language**: [English](ads-okr-epic-report.md) | [中文](ads-okr-epic-report.zh-CN.md)

Generate structured progress reports from Epic TD files (section 5) by specifying a KR identifier, KP identifier, Objective identifier, or epic-file.md path.

Four-phase pipeline: Phase 0 (pre-check) → Phase 1 (`epic-report-meta.json` + `epic-report.md`) → Phase 2 (`kr-report.md`) → Phase 3 (`okr-report.md`). Phases are automatically selected based on target granularity.

**Trigger keywords**: "epic report", "项目报告", "进展报告", "ads-okr-epic-report", "KP 报告", "生成报告", "团队进展", "team progress", "project report"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with unified report format (brief overview + detail per KP) |
| `references/phase1-epic-report.md` | Phase 1 Step 3/4 complete generation rules, data extraction rules, metadata field specs, and key progress classification |
| `scripts/extract_epic_data.py` | Phase 1 Step 3a: mechanical extraction of metadata, VN Info, and section 5 changed rows from epic-file.md |
| `scripts/check_freshness.py` | Phase 0: freshness detection, outputs structured JSON |
| `scripts/generate_epic_overview.py` | Phase 1 Step 4b: generates project overview markdown from JSON |
| `scripts/generate_kr_report.py` | Phase 2: assembles kr-report from JSON + epic-report.md |
| `scripts/generate_okr_report.py` | Phase 3: generates okr-report.md + README.md from JSON |
| `epic-report-meta.json` (per KP dir) | Structured JSON metadata with bilingual fields, consumed by Phase 2/3 scripts |
| `epic-report.md` (per KP dir) | Intermediate per-KP detail report, generated alongside epic-file |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| Epic TD files | Data | Read KP status from section 5 of each Epic TD file under the specified KR |

---

## Usage

### Quick start

```
# KP level: process only the specified KP (→ Phase 1)
/ads-okr-epic-report o1-kr5-kp3

# KR level: process all KPs under the KR (→ Phase 1 + 2)
/ads-okr-epic-report o1-kr5

# O level or omit: process all KPs under the Objective (→ Phase 0 + 1 + 3)
/ads-okr-epic-report o1
/ads-okr-epic-report

# File path: directly specify an epic-file.md (→ Phase 1)
/ads-okr-epic-report docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1/kr5-kp3-202605061814/epic-file.md
```

Phases are automatically selected based on the target granularity — no `--phase` parameter needed.

### Custom range

```
/ads-okr-epic-report --range 1m o4-kr3
```

Generates a report with findings/issues from the last month.

### Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `<target>` | KP ID / KR ID / O ID / file path / (omit) | (omit = all) | Target granularity determines which phases run: KP → Phase 1, KR → Phase 1+2, O or omit → Phase 0+1+3 |
| `--range` | `1w`, `2w`, `1m`, `all` | `2w` | Time range for filtering 5.3/5.4 date columns |
| `--quarter` | e.g. `2026q2` | (auto-detect from date) | Quarter directory name |

### Output files

KP-level outputs (per KP directory):
```
{kp-dir}/epic-report-meta.json   (structured JSON)
{kp-dir}/epic-report.md          (detail report)
```

KR reports (bilingual):
```
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/o{x}/kr{y}/{yyyy-mm-dd}-{range}.md
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/o{x}/kr{y}/{yyyy-mm-dd}-{range}.EN.md
```

KP List Index (progress summary table updated per KR):
```
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/README.md
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/README.EN.md
```

OKR summary report (bilingual):
```
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/okr-report.md
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/okr-report.EN.md
```

OKR list (authoritative O/KR enumeration source):
```
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/okr-list.md
```

---

## Four-Phase Data Pipeline

Phases are automatically selected based on target granularity:

| Target | Phases Executed |
|--------|----------------|
| KP (`o1-kr5-kp3` or file path) | Phase 1 only |
| KR (`o1-kr5`) | Phase 1 + 2 |
| O (`o1`) or omitted | Phase 0 + 1 + 3 (skips Phase 2) |

```
Phase 0: Pre-check — freshness scan + user confirmation
Phase 1: epic-file.md → epic-report-meta.json + epic-report.md  (per KP, parallel subagents)
Phase 2: epic-report-meta.json → kr-report.md + .EN.md          (Python script)
Phase 3: epic-report-meta.json → okr-report.md + .EN.md         (Python script, full regeneration)
```

### Phase 0: Pre-check (centralized freshness scan)

- **Script**: `scripts/check_freshness.py`
- Scans all target KPs and checks freshness of both `epic-report-meta.json` and `epic-report.md` against `epic-file.md` (default 12-hour staleness threshold, configurable via `--stale-days`)
- Presents freshness results to the user with update strategy options before proceeding
- Only runs for O-level or omitted targets

### Phase 1: Generate epic-report-meta.json + epic-report.md (per KP, parallel subagents)

- **Input**: `epic-file.md` (each KP's Epic TD file)
- **Output**: `epic-report-meta.json` (structured JSON with bilingual fields) + `epic-report.md` (detail report)
- **Does NOT read**: `kr-report.md`, `okr-report.md`

Each KP produces two files: a machine-readable `epic-report-meta.json` containing all summary fields (owner, contributor, step, vn_info, status, etc.) with `_en` suffix English translations, and an `epic-report.md` with the full detail report body.

**Parallel dispatch**: All stale KPs are processed via independent Agent subagents in parallel — one per KP. Each subagent uses the agent definition file `agents/common/ads-okr-epic-report-phase1.md` and is dispatched in a single message. The skill waits for all subagents to complete, then summarizes results to the user.

### Phase 2: Generate kr-report.md (Python script)

- **Input**: `epic-report-meta.json` + `epic-report.md` (all KPs)
- **Output**: `kr-report.md` + `.EN.md` (bilingual KR-level reports)
- **Script**: `scripts/generate_kr_report.py`

A single Python script call reads `epic-report-meta.json` from each KP to generate the header (Key Progress, Progress Summary table, KP Briefs, Risk Summary), then assembles header + all `epic-report.md` into the final report. Produces both Chinese and English versions. README updates are handled by Phase 3.

### Phase 3: Generate okr-report.md (Python script, full regeneration)

- **Input**: `epic-report-meta.json` (all KPs) + `okr-list.md` (authoritative O/KR enumeration)
- **Output**: `okr-report.md` + `.EN.md` + `README.md` + `README.EN.md`
- **Script**: `scripts/generate_okr_report.py`
- **Does NOT read**: `kr-report.md` for content (only for generating links)

Phase 3 performs a full regeneration from scratch. It reads `okr-list.md` to enumerate all Objectives and KRs, reads `epic-report-meta.json` from each KP for content, and generates the complete `okr-report.md` and `okr-report.EN.md`. Includes a backup/restore safety mechanism: existing files are backed up as `.bak` before generation, restored on failure, removed on success.

---

## Incremental Processing & Resume

Phase 1 generates per-KP detail reports incrementally to avoid large single writes that can stall subagents.

### How it works

1. Each KP's output is written to `epic-report-meta.json` + `epic-report.md` in the KP's epic-file directory
2. Before generating, the skill compares both `epic-report-meta.json` and `epic-report.md` mtime vs `epic-file.md` mtime (default 12-hour staleness threshold)
3. If both outputs are newer than `epic-file.md` (data source unchanged), the KP is **skipped**
4. The freshness check is centralized in Phase 0 via `check_freshness.py` for O-level targets

### Resume after interruption

If generation is interrupted mid-way (e.g., 3 of 7 KPs completed):
1. Re-invoke the same command
2. Completed KPs are automatically skipped (their outputs are already newer than `epic-file.md`)
3. Remaining KPs are generated

To force regeneration of a specific KP, `touch` its `epic-file.md` to update the mtime, then re-invoke the command.

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `/ads-okr-epic-td` | Epic TD document generation and review |
| `/ads-okr-planner` | OKR KR→KP planning and quality review |
| `/ads-okr-meeting-doc` | Meeting doc drafting, post-meeting record & write-back |
