# Memory Update/记忆更新

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-02 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-okr-memory-update.md)
> **Language**: [English](ads-okr-memory-update.md) | [中文](ads-okr-memory-update.zh-CN.md)

Unified memory update skill — scan current or past sessions, extract key decisions, findings, and code changes, then write into project memory and/or personal memory systems.

---

## Trigger Keywords

`memory update`, `更新记忆`, `项目记忆`, `个人记忆`, `personal memory update`, `更新项目记忆`, `更新个人记忆`, `补录记忆`, `sync memory`, `记入个人记忆`, `创建个人记忆`, `ads-okr-memory-update`, `ads-personal-memory-update`

## Skill Files

| File | Description |
|------|-------------|
| `skills/common/ads-okr-memory-update/SKILL.md` | Skill definition |
| `skills/common/ads-okr-memory-update/scripts/scan_sessions.py` | Session scanner script (supports Claude Code and Codex) |
| `skills/common/ads-okr-memory-update/scripts/bind_project.py` | Project binding helper (list/resolve/bind/check-sync) |
| `skills/common/ads-okr-memory-update/scripts/memory_ops.py` | Memory operations helper (init/write-daily/update-index/finalize) |
| `skills/common/ads-okr-memory-update/references/schemas.md` | JSON schemas for recorded-epics/sessions, content-json, field paths |
| `skills/common/ads-okr-memory-update/references/directory-layout.md` | Directory structure for project/personal memory |

## Prerequisites

| Requirement | Description |
|-------------|-------------|
| Config directory | `docs/personal/<person>/config/` (auto-created if missing) |
| Project memory (optional) | Linked project with `epic-file.md` and `MEMORY.md` |
| Personal memory (optional) | `docs/personal/<person>/memory/` with `MEMORY.md` |
| Session history | `~/.claude/projects/` or `~/.codex/sessions/` with JSONL session files |

## Basic Usage

The skill has two independent functions:

### Function A: Project Binding

Bind the current session to an epic project. Triggered by keywords like `绑定项目`, `bind project`, `start project`.

1. Run the skill or say "绑定项目"
2. Select from recent epic candidates or enter a project path/KP ID manually
3. The skill updates `recorded-epics.json` and `recorded-sessions.json`
4. Checks if memory-sync is stale and prompts to run `/ads-okr-memory-sync` if needed

### Function B: Memory Update

Scan sessions and write memory entries. Triggered by keywords like `更新记忆`, `memory update`.

1. Run `/ads-okr-memory-update` or say "更新记忆"
2. Choose mode: **Single session** (current session only) or **Full session** (scan past sessions)
3. Choose scope: **Project + Personal** (recommended), **Project only**, or **Personal only**
4. For full session mode:
   - The skill reads the last update timestamp from `docs/personal/<person>/config/recorded-sessions.json`
   - A Python script scans session files modified since that timestamp (supports both Claude Code and Codex sessions)
   - Sessions are classified as new, reactivated, or skipped (automatic dedup)
   - Preview shows session count, date range, and matched stats
5. For each session:
   - **Step 1**: Project binding — match session to projects via KP/KR IDs, file paths, or explicit association (each new project requires user confirmation)
   - **Steps 2-3**: Memory write sub-flow — a unified parameterized flow for both project and personal memory, extracting content, confirming with user, writing daily files and updating indexes
6. All writes require user confirmation before execution (Confirm-Once pattern: content summary + optional supplement in one prompt)
7. Tracking file `recorded-sessions.json` is updated with processed session info

## Example Prompts

**Function A (Project Binding):**
- `绑定项目`
- `bind project`
- `start project`

**Function B (Memory Update):**
- `/ads-okr-memory-update`
- `更新记忆`
- `更新项目记忆`
- `更新个人记忆`
- `补录最近的记忆`
- `sync memory since last week`
- `personal memory update`

## Notes

- The current running session is automatically excluded
- Each session is processed once: project binding → project memory → personal memory
- Auto-triggered before context compression, before session end, and after git commit (single session mode, project + personal scope)
- For syncing memory into `epic-file.md`, use `ads-okr-memory-sync` instead
- Migration: old tracking files from `docs/personal/<person>/memory/.recorded-sessions.json` and `docs/personal/<person>/okr-memory/recorded-sessions.json` are auto-merged into the unified location
