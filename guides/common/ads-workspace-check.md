# Workspace Check (ads-workspace-check) Guide

> **Language**: [English](ads-workspace-check.md) | [中文](ads-workspace-check.zh-CN.md)

Full-repo audit of ads-workspace documentation consistency, directory structure, and naming conventions — then interactively fix found issues.

**Trigger keywords**: "check workspace", "workspace 检查", "文档一致性", "doc consistency", "readme audit", "检查文档", "naming check", "命名检查", "目录检查", "structure check"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with 7-step check workflow |

---

## Prerequisites

No external dependencies. Reads local files only.

---

## Workflow Overview

1. **Collect source of truth** — Read `CLAUDE.md`, scan actual directory structure
2. **Part A: Doc consistency** — Cross-check README, CLAUDE.md, skills/README for consistent descriptions
3. **Part B: Naming conventions** — Verify kebab-case, ≤30 chars, `name` matches dir, TRIGGER format, no abs paths
4. **Part C: Scope constraints** — Verify `ads-` prefix, guide files exist, tooling symlinks tracked
5. **Report issues** — Grouped by Part A / B / C with severity
6. **User selects fix scope** — All / Part A only / Part B only / Part C only / view only
7. **Apply fixes** — Edit files, create missing guides, prompt to run sync script

---

## Usage Example

> "/ads-workspace-check" or "帮我检查一下 workspace 规范"

The skill scans the full repo and presents a consolidated issue list before making any changes.

---

## Install via ads-workspace-skill-install

This is a common skill and is auto-loaded when the workspace is opened. No manual install needed.
