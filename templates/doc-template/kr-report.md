# 团队工作进展概览/Team Progress Overview

> **Language**: [English](kr-report.EN.md) | [中文](kr-report.md)

> 报告范围：${range_start} ~ ${range_end} | 涵盖 KP 数：${kp_count}

## 进度总览/Progress Summary

| KP                                         | 标题                                     | Owner    | Phase    | TDStep  | eta        | effort    | start    | update         | KA进度                         | 状态             | report                                                                      |
| ------------------------------------------ | -------------------------------------- | -------- | -------- | ------- | ---------- | --------- | -------- | -------------- | ---------------------------- | -------------- | --------------------------------------------------------------------------- |
| [${kp_dir_id}](${epic_file_relpath}) | [${kp_title}](${epic_file_gitlab_url}) | ${owner} | ${phase} | ${step} | ${final_eta} | ${effort} | ${start} | ${last_update} | ${done_count}/${total_count} | ${status_summary} | [epic-report](${epic_report_relpath}):[GitLab](${epic_report_gitlab_url}) |

## 关键进展/Key Progress

（${n}）【${type}】${kp_id_short}, ${kp_title}，${progress_description}

## 各 KP 简报/KP Briefs

状态图例：🟢 按计划 | 🟡 进行中 | 🔴 有延期 KA 或超 6 天未更新 | ✅ 全部完成

[${kp_dir_id}](${epic_file_relpath}): [${kp_title}](${epic_file_gitlab_url})，**类型**：${kp_type}

- **Owner**：${owner} | **Phase**：${phase} | **TDStep**：${step} | **ETA**：${final_eta} | **effort**：${effort} | **start**：${start} | **update**：${last_update} | **KA进度**：${done_count}/${total_count} | **状态**：${status_summary}
- **Why Do**：${why_do}
- **交付目标**：${deliverable}
- **关键进展**：${key_progress}
- **KA进度**：${ka_progress_summary}
- **实验**：${experiment_summary}
- **风险**：${risk_summary}
- **下一步**：${next_steps_summary}
- **Epic-File**：[Markdown](${epic_file_relpath}) / [GitLab](${epic_file_gitlab_url}) | **Epic-Report**：[Markdown](${epic_report_relpath}) / [GitLab](${epic_report_gitlab_url})

## 各KP 进展详细报告/KP Detail Progress Report

<!-- 以下内容由 Bash(cat) 拼接各 KP 的 epic-report.md 生成，KP 之间用 --- 分隔 -->
<!-- 各 KP 详细报告模板见 templates/doc-template/epic-report.md -->
