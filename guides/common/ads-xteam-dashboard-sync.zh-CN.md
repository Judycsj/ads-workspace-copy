# Ads Dashboard 同步 (ads-xteam-dashboard-sync) 使用指南

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-29 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-xteam-dashboard-sync.zh-CN.md)
> **Language**: [English](ads-xteam-dashboard-sync.md) | [中文](ads-xteam-dashboard-sync.zh-CN.md)

将 `dashboard-meta.json` 中的项目跟踪数据同步到 Google Sheet。自动发现季度目录下所有项目，新项目自动新增行，按 Epic Key 时间戳排序。

**触发关键词**: "sync dashboard to gsheet"、"同步 dashboard 到表格"、"dashboard sync"、"dashboard 同步"

---

## 场景 1：同步整个 Sheet

> **你**: `/ads-xteam-dashboard-sync --gsheet https://docs.google.com/spreadsheets/d/1t9tZcHIXGR1FuFrOjr8leMncLXdRLDY6EQRP7Qvyq0k/edit?gid=797823418`
>
> **AI**: 从链接提取 spreadsheetId 和 gid，读取 A 列 Epic Key，找到对应 `dashboard-meta.json`，将 B:AD 列（项目 ID、名称、优先级、阶段进度、角色、团队、PIC、epic 文件、TD 审核、待办进度、阻塞项、TODO 详情等）写回 Sheet，并应用 section 分色格式。报告成功/跳过数量。

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

## 前提条件

- Google Sheet 必须已创建（脚本自动管理 A 列 Epic Key 和 B:AD 数据列）
- 目标项目必须已生成 `dashboard-meta.json`（由 `ads-xteam-runner` / `ads-project-tracker-bot` 生成）
- Google OAuth `~/credentials.json` 已配置；token 缓存在 `~/.config/ads-workspace/token_sheets_rw.json`

## 列映射

| 列 | 表头 | 数据来源 |
|----|------|---------|
| A | Epic Key | 输入（不覆盖） |
| B | Project ID | `project_id` |
| C | Summary | `summary` |
| D | Priority | `priority` |
| E | PRD | `prd_url` → HYPERLINK |
| F | Epic | `business_epic.root` → GitLab tree HYPERLINK |
| G | Deadline | 固定 "N/A"（JSON 中无此字段） |
| H | PJM | `roles.pjm`（取邮箱前缀） |
| I | PM | `roles.pm`（取邮箱前缀） |
| J | QA | `roles.qa`（取邮箱前缀） |
| K | Teams | `participant_teams` |
| L | Dev PICs | `roles.pics`（team: name 格式） |
| M | Leaders | `roles.leaders`（team: name 格式） |
| N | Phase | `phase.current_step_name` |
| O | Progress | `phase.current_step` → N/11 (XX%) |
| P | Epic File | `business_epic.main_file` → GitLab HYPERLINK |
| Q | Team Files | `business_epic.team_files` → 各团队 GitLab 链接 |
| R | MR | `business_epic.mr_url` → HYPERLINK |
| S | PRD Issues | `prd_quality`（required/active） |
| T | TD Status | `td_quality.overall_status` |
| U | TD Details | `td_quality.sides`（team: status(issues)） |
| V | Todo Progress | `todos`（done/total） |
| W | Todo Open | `todos.open` |
| X | Todo Blocked | `todos.blocked` |
| Y | Todo Pending | `todos.pending` |
| Z | Todo InProgress | `todos.in_progress` |
| AA | Todo Skipped | `todos.skipped` |
| AB | Blockers | `todos.items`（blocking=true，多行文本） |
| AC | Open TODOs | `todos.items`（open，多行文本） |
| AD | Updated At | `updated_at` |
