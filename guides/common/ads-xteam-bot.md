# Ads XTeam Bot (ads-xteam-bot) Guide

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-29 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-xteam-bot.md)
> **Language**: [English](ads-xteam-bot.md) | [中文](ads-xteam-bot.zh-CN.md)

NLU layer for the Ads cross-team project tracking system. Parses user commands in natural language, confirms structured parameters via multi-turn dialogue, then delegates all writes to `meta_json_edit.py`.

**Trigger keywords**: "project start", "project status", "todo done", "T001 done", "skip", "block", "todo add", "进度", "status"

---

## Scenario 1: Check project status

> **You**: `project status`
>
> **AI**: Reads `runner_meta.json`, renders a Dashboard showing current phase, open TODOs, blockers, and team progress.

---

## Scenario 2: Complete a TODO

> **You**: `T003 done`
>
> **AI**: Parses the TODO ID, confirms the target, marks it as done via `meta_json_edit.py`, triggers any dependent state machine transitions (e.g., phase advance), and renders the updated status.

---

## Scenario 3: Add a manual TODO

> **You**: `todo add: Review PRD with PM team`
>
> **AI**: Creates a new manual TODO item, assigns it to the current phase, and confirms the addition.

---

## Scenario 4: Update TODO metadata

> **You**: `T005 eta 2026-07-15`
>
> **AI**: Updates the ETA field for the specified TODO and confirms the change.

---

## Prerequisites

- `runner_meta.json` must exist for the target project (created by project intake)
- When used via SeaTalk bot, the bot proxy handles message routing by `project_id`

## Architecture

See `specs/common/xteam/01-scope-and-workflow.md` for the full tool architecture and `03-ads-xteam-bot-spec.md` for the NLU specification.
