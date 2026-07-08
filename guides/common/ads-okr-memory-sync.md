# Ads Project Memory Sync (ads-project-memory-sync) Guide

> **Language**: English | [中文](./ads-project-memory-sync.zh-CN.md)

Syncs accumulated project memory files (`memory/YYYY-MM-DD-person.md`) into the epic-file's section 5 (KP Execution & Status). Two-phase workflow: memory files are accumulated automatically during sessions (via CLAUDE.md rules), then this skill merges them into the epic-file with user confirmation.

**Trigger keywords**: sync memory, 同步记忆, memory to epic, 记忆同步, project sync, 项目同步

---

## Skill Files

| File | Purpose |
| --- | --- |
| `skills/common/ads-project-memory-sync/SKILL.md` | Skill definition and workflow |

## Prerequisites

| Dependency | Type | Notes |
| --- | --- | --- |
| Project directory with `epic-file.md` + `MEMORY.md` + `memory/` | Structure | See `templates/doc-template/project-memory.md` for template |

## Basic Usage

1. Run `/ads-project-memory-sync` or say "同步项目记忆"
2. The skill identifies the target project (from active project or user input)
3. Reads all unsynced memory files under `memory/`
4. Classifies entries into epic-file sections 5.1–5.5
5. Shows diff-style update suggestions
6. Write to epic-file after user confirmation
7. Marks synced entries with `<!-- [synced @YYYY-MM-DD] -->`
8. Records sync timestamp as `<!-- memory-sync: last=... -->` in epic-file header

## Example Prompts

- `/ads-project-memory-sync`
- `同步项目记忆到 epic-file`
- `sync memory for kr3-kp4`

## Notes

- Incremental updates only — never overwrites manual edits in epic-file
- Section 5.5 (Next Steps) is replaced rather than appended (it's a living document)
- Ambiguous entries prompt user for classification
- Requires at least one unsynced memory file to proceed
- On session binding ("start project xxx"), staleness is auto-checked — if >24h since last sync, you'll be prompted
