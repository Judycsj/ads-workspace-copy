# ads-diagnose 迭代记录（ads-diagnose-changelog）使用指南

> **语言**：[English](ads-diagnose-changelog.md) | [中文](ads-diagnose-changelog.zh-CN.md)

将 `ads-diagnose` 技能（及其 sub-agent）的迭代历史沉淀到 Google Sheet。扫描 git 中触碰追踪文件的提交，解析 提交日期 / 类型 / 开发者(PIC) / MR 链接，由 AI 草拟每次改动的「为什么」（用户确认），按每个 commit 一行追加到 `commit-history` 标签页。首次运行回填全部历史，之后按 commit SHA 去重，只追加新行。

**唤醒词**：「ads-diagnose changelog」、「ads-diagnose 迭代记录」、「ads-diagnose 变更记录」、「记录 ads-diagnose 迭代」、「diagnose changelog」、「更新诊断 changelog」、「回填 ads-diagnose 历史」、「sync ads-diagnose history」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 技能主定义：常量、列结构、5 步工作流 |
| `scripts/extract_history.sh` | Git 提取脚本——每个追踪的非 merge commit 输出一行 TSV |

---

## 追踪文件面

| 路径 | 说明 |
|------|------|
| `skills/common/ads-diagnose/**` | SKILL.md + references/ |
| `agents/common/ads-diagnose-*.md` | ads-diagnose 的 sub-agent |

---

## 写入目标

| 字段 | 值 |
|------|------|
| 表格 | `[Item Tracker]Ads策略`（`1waq2gLBcfBRMBO7fRCYkkYei-j0Fbz9INcby29IEiAU`） |
| 标签页 | `commit-history` |
| 列 | A 日期 · B 类型 · C Summary · D Why · E PIC · F Merge Request · G Commit SHA |

Sheet 为唯一真相源，repo 内不另存 changelog；增量进度由 G 列已有的 SHA 决定。

---

## 使用方式

> 「更新 ads-diagnose 迭代记录」/「sync ads-diagnose history」

1. 运行 `scripts/extract_history.sh` 提取全量 git 历史（TSV）。
2. 读取 sheet 的 G 列，确定哪些 commit 已记录。
3. 首次（空表）→ 回填全部并写表头；之后 → 仅追加新 commit。
4. 技能从每个 commit 的 body 与 diff 草拟 D 列「为什么/解决了什么」，跟随 commit 语言。
5. 用户审阅确认 D 列后写入 sheet。

---

## 说明

- SHA 去重保证幂等——重复运行不会写重复行。
- 直推 master（无 MR）的 commit：F 列留空，PIC 回退为 commit author。
- 技能不修改 `ads-diagnose` 本身。
