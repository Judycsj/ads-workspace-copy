# Ads Doc Comment (ads-doc-comment) Guide

> **Language**: [English](ads-doc-comment.md) | [中文](ads-doc-comment.zh-CN.md)

Adds Google Docs-like inline commenting to Markdown documents under `docs/`. Supports adding, replying, resolving, listing, and cleaning comments, plus AI-assisted document review with severity markers.

**Trigger keywords**: "doc comment", "add comment", "review doc", "文档评论", "添加评论", "审查文档", "list comments", "resolve comment", "clean comments"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with all 8 operations |
| `references/format-spec.md` | Comment format spec, placement rules, ID generation, parsing guide |
| `references/review-guidelines.md` | AI review severity levels, focus areas, quality checklist |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| Git | System | Author detection via `git config user.name` |
| `docs/` directory | Repo | Target directory for commented documents |

No external skill dependencies.

---

## Usage

### Scenario 1: Add a comment to a specific section

> "给 docs/team/00.paid-ads-dev/03.sop/01.okr-sop.md 的 '评审流程' 添加评论：缺少频率说明"

The skill reads the file, locates the target heading, and inserts an HTML comment block immediately after it. The comment is invisible in rendered Markdown.

### Scenario 2: AI review a document

> "review docs/.../epic-file.md --focus completeness"

The skill reads the entire document, analyzes it for completeness gaps, inserts inline comments at relevant locations with `[Blocker]`/`[Major]`/`[Minor]`/`[Suggestion]` severity markers, and outputs a summary table.

### Scenario 3: List and manage comments

> "list comments in docs/common/ads-overview.md --status open"

Outputs a table of all open comments with ID, severity, author, date, location, and summary.

> "resolve c-20260509-0001 in docs/common/ads-overview.md"

Changes the comment's status from `open` to `resolved`.

### Scenario 4: Clean up resolved comments

> "clean comments in docs/common/ads-overview.md"

Removes all resolved comment blocks from the file, preserving the original document content. Shows a preview before confirmation.

### Scenario 5: Collaborative discussion

> "reply to c-20260509-0001 in docs/.../design.md: 同意，我会补充重试逻辑"

Adds a reply to an existing comment thread, creating a discussion similar to Google Docs comment threads.

---

## Comment Format

Comments are stored as inline HTML comments with a `@doc-comment` prefix. They are invisible in rendered Markdown and compatible with gdoc-sync (silently dropped during sync).

```html
<!-- @doc-comment id="c-20260509-0001" author="luka.yang" date="2026-05-09" status="open" severity="major" -->
<!-- [Major] Missing error handling description → Add retry strategy section -->
<!-- @doc-reply author="john.doe" date="2026-05-10" -->
<!-- Good point, will add in next revision -->
<!-- @/doc-comment -->
```

See `references/format-spec.md` for the complete specification.

---

## Operations Quick Reference

| Operation | Description |
|-----------|-------------|
| `add` | Add a comment at a specific location |
| `reply` | Reply to an existing comment thread |
| `resolve` | Mark a comment as resolved |
| `list` | List comments with optional filters |
| `delete` | Remove a comment block |
| `review` | AI reviews document and adds inline comments |
| `summary` | Show summary of all open comments |
| `clean` | Remove resolved (or all) comment blocks |

---

## Downstream Skills

| Skill | Relationship |
|-------|-------------|
| `ads-workspace-gdoc-sync` | Comments are silently dropped during Markdown → Google Docs sync |
| `ads-workspace-commit-push` | Use to commit documents with comments |
| `ads-okr-epic-td` | Epic TD documents are common review targets |
