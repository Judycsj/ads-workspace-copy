# Ads OKR Epic Report Sync (ads-okr-epic-report-sync) 使用指南

> **Contributors**: luka.yang ｜ **最后更新**：2026-05-28 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-okr-epic-report-sync.zh-CN.md)
> **Language**: [English](ads-okr-epic-report-sync.md) | [中文](ads-okr-epic-report-sync.zh-CN.md)

将 `epic-report-meta.json` 中的结构化数据同步写入 Google Sheet，按 Epic_File Key 逐行匹配。

**触发关键词**："sync epic report to gsheet"、"同步 epic 到表格"、"epic report sync"、"epic 报告同步"

---

## 场景 1：同步某个 sheet 的所有行

> **You**: `/ads-okr-epic-report-sync --gsheet https://docs.google.com/spreadsheets/d/1waq2gLBcfBRMBO7fRCYkkYei-j0Fbz9INcby29IEiAU/edit?gid=2034964463`
>
> **AI**：从链接提取 spreadsheetId 和 gid，读取 Epic_File Key 列，运行 `extract_epic_data.py` 读取每个 `epic-report-meta.json`，将 B:R 列写回表格。报告成功/跳过数。

---

## 场景 2：指定 sheet 名称同步

> **You**: `同步 epic 报告到表格 --gsheet 1waq2gLBcfBRMBO7fRCYkkYei-j0Fbz9INcby29IEiAU --sheet 平台出价`
>
> **AI**：直接使用指定的 sheet 名称，无需从 gid 解析。

---

## 场景 3：指定其他季度或团队

> **You**: `epic report sync --gsheet <link> --quarter 2026q1 --team 01.ads-engineering`
>
> **AI**：在 `docs/team/01.ads-engineering/10.trd-prd-td-list/2026q1/` 下查找 `epic-report-meta.json`。

---

## 前提条件

- Google Sheet 必须有 `Epic_File Key` 列（默认 A 列）
- 每个 KP 必须已运行 `ads-okr-epic-report` 生成 `epic-report-meta.json`
- MCP Google Drive 工具可用

## 列映射

| 列 | 表头 | 数据来源 |
|----|------|----------|
| A | Epic_File Key | 输入（不覆盖） |
| B | epic-name | `kp_title` |
| C | 交付目标 | `deliverable` |
| D | KA进展 | `key_progress` |
| E | 实验 | `experiment` |
| F | 风险 | `risk` |
| G | 下一步 | `next_steps` |
| H | epic-file | `epic_file_gitlab_url` → HYPERLINK |
| I | epic-report | `epic_report_gitlab_url` → HYPERLINK |
| J | Owner | `owner` |
| K | Contributor | `contributor` |
| L | TDStep | `step` |
| M | eta | `eta`（YYYYMMDD） |
| N | effort | `effort` |
| O | start | `start`（YYYYMMDD） |
| P | update | `last_update` |
| Q | KA进度 | `done_count/total_count` |
| R | 状态 | `status`（emoji） |
