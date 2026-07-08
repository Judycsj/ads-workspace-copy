# Ads OKR Epic Dashboard 同步/Sync (ads-okr-xteam-dashboard-sync) 使用指南/Guide

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-03 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-okr-xteam-dashboard-sync.zh-CN.md)
> **Language**: [English](ads-okr-xteam-dashboard-sync.md) | [中文](ads-okr-xteam-dashboard-sync.zh-CN.md)

将 `dashboard-meta.json` 中的项目跟踪数据同步到 Google Sheet，按 A 列 Epic Key 逐行匹配写入。

**触发关键词**: "sync dashboard to gsheet"、"同步 dashboard 到表格"、"dashboard sync"、"dashboard 同步"

---

## 场景 1：同步整个 Sheet

> **你**: `/ads-okr-xteam-dashboard-sync --gsheet https://docs.google.com/spreadsheets/d/1t9tZcHIXGR1FuFrOjr8leMncLXdRLDY6EQRP7Qvyq0k/edit?gid=797823418`
>
> **AI**: 从链接提取 spreadsheetId 和 gid，读取 A 列 Epic Key，找到对应 `dashboard-meta.json`，将 B:O 列（阶段、PRD、角色、团队、PIC、epic 文件、待办进度等）写回 Sheet。报告成功/跳过数量。

---

## 场景 2：预览模式（不写入）

> **你**: `同步 dashboard 到表格 --gsheet <link> --dry-run`
>
> **AI**: 读取并提取数据，但不写入 Sheet。展示将要写入的内容供验证。

---

## 场景 3：指定季度同步

> **你**: `dashboard sync --gsheet <link> --quarter 2026q1`
>
> **AI**: 在 `docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q1/` 下查找 `dashboard-meta.json`，而非当前季度。

---

## 前提条件/Prerequisites

- Google Sheet 必须有 Epic Key 列（默认 A 列）
- 目标项目必须已生成 `dashboard-meta.json`（由 `ads-xteam-runner` / `ads-project-tracker-bot` 生成）
- Google OAuth `~/credentials.json` 已配置；token 缓存在 `~/.config/ads-workspace/token_sheets_rw.json`

## 列映射/Column Mapping

| 列 | 表头 | 数据来源 |
|----|------|---------|
| A | Epic Key | 输入（不覆盖） |
| B | Phase | `phase.current_step_name` |
| C | PRD | `prd_url` → HYPERLINK |
| D | PJM | `roles.pjm`（取邮箱前缀） |
| E | PM | `roles.pm`（取邮箱前缀） |
| F | QA | `roles.qa`（取邮箱前缀） |
| G | Teams | `participant_teams` |
| H | PICs | `roles.pics`（team: name 格式） |
| I | Leaders | `roles.leaders`（team: name 格式） |
| J | Epic File | `business_epic.main_file` → GitLab HYPERLINK |
| K | MR | `business_epic.mr_url` → HYPERLINK |
| L | PRD Issues | `prd_quality`（required/active） |
| M | Todo Progress | `todos`（done/total） |
| N | Todo Open | `todos.open` |
| O | Todo Blocked | `todos.blocked` |
