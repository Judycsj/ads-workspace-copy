# Ads Workspace GDoc Sync Guide

> **Language**: [English](ads-workspace-gdoc-sync.md) | [中文](ads-workspace-gdoc-sync.zh-CN.md)

Incrementally sync `ads-workspace` Markdown documents from `docs/common`, `docs/personal`, and `docs/team` into Google Drive / Google Docs with folder hierarchy preserved.

**Trigger keywords**: "sync md to gdoc", "ads-workspace docs", "Google Drive sync", "增量同步 markdown 到 gdoc", "同步 workspace 文档", "docs/common personal team"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition and command entrypoints |
| `README.md` | Operator-facing usage guide |
| `WORKFLOW.md` | State machine, manifest, and sync policy details |
| `scripts/sync_ads_workspace_docs.py` | Main sync engine |
| `scripts/check_md_invalid_chars.py` | Invalid-character inspection and source cleanup helper |
| `scripts/rollback_gdoc_revision.py` | Minimal rollback helper using `pre_sync.revision_id` |

---

## Prerequisites

- `uv`
- Git access to `ads-workspace`
- Google Workspace OAuth credential file at `~/.google_workspace_mcp/credentials/<email>.json`
- Local `config.yaml` copied from `config.example.yaml`

---

## Workflow Overview

1. **Choose baseline branch** — default `master`, can be overridden with `--branch`
2. **Choose execution mode** — `dry-run` for preview, `apply` for real sync
3. **Choose scan mode** — `full` or `incremental-since-last-sync`
4. **Resolve processing set** — `diff(last_attempted_repo_head..current_head) + pending_failures` for incremental mode
5. **Prepare temporary source** — sanitize invalid XML chars if enabled and rewrite internal `.md` links to known GDoc links
6. **Sync each file** — create / overwrite / unchanged / report
7. **Write report** — output markdown report and update manifest when execution mode is `apply`

---

## Usage Example

> "请用 ads-workspace-gdoc-sync 跑一次 sync：branch master，dry-run，incremental-since-last-sync，scope 是 docs/personal"

Recommended routine preview:

```bash
uv run skills/common/ads-workspace-gdoc-sync/scripts/sync_ads_workspace_docs.py \
  --config skills/common/ads-workspace-gdoc-sync/config.yaml \
  --branch master \
  --execution-mode dry-run \
  --sync-scan-mode incremental-since-last-sync \
  --allow-remote-overwrite yes \
  --invalid-char-policy sanitize \
  --section personal \
  --path-prefix docs/personal
```

---

## Install via ads-workspace-skill-install

This is a common skill and is auto-loaded when the workspace is opened. No manual install needed.
