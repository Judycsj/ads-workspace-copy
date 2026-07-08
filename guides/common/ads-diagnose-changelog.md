# ads-diagnose Changelog (ads-diagnose-changelog) Guide

> **Language**: [English](ads-diagnose-changelog.md) | [中文](ads-diagnose-changelog.zh-CN.md)

Records the iteration history of the `ads-diagnose` skill (and its sub-agents) into a Google Sheet. It scans git for commits that touched the tracked files, parses commit date / type / developer (PIC) / merge-request link, drafts a "why" line for each change (AI-drafted, user-confirmed), and appends one row per commit to the `commit-history` tab. The first run backfills the full history; later runs deduplicate by commit SHA and append only new rows.

**Trigger keywords**: "ads-diagnose changelog", "ads-diagnose 迭代记录", "ads-diagnose 变更记录", "记录 ads-diagnose 迭代", "diagnose changelog", "更新诊断 changelog", "回填 ads-diagnose 历史", "sync ads-diagnose history"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition: constants, column layout, 5-step workflow |
| `scripts/extract_history.sh` | Git extractor — emits one TSV row per tracked non-merge commit |

---

## Tracked Surface

| Path | Notes |
|------|-------|
| `skills/common/ads-diagnose/**` | SKILL.md + references/ |
| `agents/common/ads-diagnose-*.md` | ads-diagnose sub-agents |

---

## Output Target

| Field | Value |
|-------|-------|
| Spreadsheet | `[Item Tracker]Ads策略` (`1waq2gLBcfBRMBO7fRCYkkYei-j0Fbz9INcby29IEiAU`) |
| Tab | `commit-history` |
| Columns | A Date · B Type · C Summary · D Why · E PIC · F Merge Request · G Commit SHA |

The sheet is the single source of truth; no changelog file is kept in the repo. Incremental progress is determined by the SHA values already present in column G.

---

## Usage

> "更新 ads-diagnose 迭代记录" / "sync ads-diagnose history"

1. Run `scripts/extract_history.sh` to extract the full git history (TSV).
2. Read column G from the sheet to find which commits are already recorded.
3. First run (empty sheet) → backfill all rows with a header; later runs → append only new commits.
4. The skill drafts column D ("why / what problem it solved") from each commit's body and diff, following the commit's language.
5. Review and confirm column D, then the rows are written to the sheet.

---

## Notes

- SHA deduplication makes the skill idempotent — re-running never writes duplicate rows.
- Commits pushed straight to master (no MR) leave column F blank and fall back to the commit author for PIC.
- The skill never modifies the `ads-diagnose` skill itself.
