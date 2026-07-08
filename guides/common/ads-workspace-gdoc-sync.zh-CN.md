# Ads Workspace GDoc Sync 使用指南

> **语言**：[English](ads-workspace-gdoc-sync.md) | [中文](ads-workspace-gdoc-sync.zh-CN.md)

将 `ads-workspace` 中 `docs/common`、`docs/personal`、`docs/team` 下的 Markdown 文档按目录层级同步到 Google Drive / Google Docs。

**唤醒词**：「sync md to gdoc」、「ads-workspace docs」、「Google Drive sync」、「增量同步 markdown 到 gdoc」、「同步 workspace 文档」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义与命令入口 |
| `README.md` | 面向操作者的使用说明 |
| `WORKFLOW.md` | 状态机、manifest 与同步策略说明 |
| `scripts/sync_ads_workspace_docs.py` | 主同步脚本 |
| `scripts/check_md_invalid_chars.py` | 非法字符检查与源文件修复辅助脚本 |
| `scripts/rollback_gdoc_revision.py` | 基于 `pre_sync.revision_id` 的最小回退脚本 |

---

## 前置依赖

- `uv`
- 可访问 `ads-workspace` 的 Git 凭据
- Google Workspace OAuth 凭据文件：`~/.google_workspace_mcp/credentials/<email>.json`
- 从 `config.example.yaml` 复制出来的本地 `config.yaml`

---

## 流程概览

1. **选择基线分支** — 默认 `master`，也可通过 `--branch` 显式指定
2. **选择执行模式** — `dry-run` 预演，`apply` 真实执行
3. **选择扫描模式** — `full` 或 `incremental-since-last-sync`
4. **确定处理集合** — 增量模式下使用 `diff(last_attempted_repo_head..current_head) + pending_failures`
5. **准备临时副本** — 按策略清洗 XML 非法字符，并尽量把仓库内 `.md` 相对链接重写成已知 GDoc 链接
6. **逐文件同步** — create / overwrite / unchanged / report
7. **写出报告** — 输出 markdown 报告，并在 `apply` 时更新 manifest

---

## 使用示例

> 「请用 ads-workspace-gdoc-sync 跑一次 sync：branch master，dry-run，incremental-since-last-sync，scope 是 docs/personal」

推荐的例行预演命令：

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

## 安装方式

本 skill 属于 common scope，打开 workspace 时自动加载，无需手动安装。
