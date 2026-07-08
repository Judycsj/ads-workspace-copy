# Schedule Create (ads-workspace-schedule-create) 使用指南

> **Contributors**: boonhing.tan ｜ **最后更新**：2026-06-18 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-workspace-schedule-create.zh-CN.md)
> **Language**: [English](ads-workspace-schedule-create.md) | [中文](ads-workspace-schedule-create.zh-CN.md)

为 `ads-workspace` 创建或更新 GitLab Pipeline 定时任务，无需编写任何 CI yml 文件。
所有配置通过 Schedule 变量注入，Claude 自动完成其余操作。

**输出/Output**：创建后可在
[`-/pipeline_schedules`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/pipeline_schedules)
查看定时任务，Schedule 将按配置的 cron 周期自动触发 CI 流水线。

**触发关键词**："ads-workspace schedule"、"pipeline schedule"、"scheduled task"、
"schedule a skill"、"schedule a script"、
"创建定时任务"、"创建例行任务"、"配置定时流水线"

---

## 两种任务类型/Two Task Types

| 类型 | 适用场景 | 示例 |
|------|----------|------|
| **AI** (`run-skill`) | 定期执行 Claude Skill 或提示词 | 每日 DQC 报告、每周摘要 |
| **Script** (`run-script`) | 执行 Python / Shell / JS 文件或原始命令 | 数据同步、缓存清理、通知脚本 |

### 简单任务 vs. 复杂任务/Simple vs. Complex Tasks

**优先使用 Claude Code CLI**（`run-skill` / `run-script`）— 支持 MCP Server、Google Workspace 凭证、前置脚本、Skill 安装及 Artifact 上传，均可通过 Schedule 变量配置，大多数任务无需新建 yml 文件。

**简单任务** — 不需要新建 yml：

| 场景 | 操作方式 |
|---|---|
| 按 cron 执行提示词、Skill 或脚本 | 通过 Schedule 变量配置，Claude 全程处理 |
| 自定义超时时间 | 使用预设：`RUN_STAGE=run-skill-30m`、`run-skill-1h`、`run-skill-3h` |
| 自定义超时 + artifact 保留期组合 | Claude 在现有模板 yml 中添加新的 `extends` 块，提交后创建 Schedule |

**复杂任务** — Claude 创建专属 `schedules/.gitlab-ci-your-task.yml`：

| 示例 | 为何需要新 yml |
|---|---|
| 多仓库并发 | 隐藏 job 模板 + generate/trigger 两文件模式 — 参考 `.gitlab-ci-update-readme-job-cc.yml` + `.gitlab-ci-update-readme-cc.yml` |
| 大量预置默认变量 | 任务专属变量较多，不适合每次手动配置 — 参考 `.gitlab-ci-ads-workspace-gdoc-sync.yml` |

复杂任务只需描述你的需求，Claude 会自动创建 yml 文件、更新 `.gitlab-ci.yml`、提交变更并创建 Schedule。如有需要用户操作的步骤（如合并 MR 后才能进行冒烟测试），Claude 会明确告知。

---

## 使用流程

直接描述你想定时执行的任务来触发 Skill：

> "帮我把 `/ads-dqc-report` Skill 设置为每周一早上 9 点自动运行"

> "把 `scripts/sync_data.py` 设置为每晚定时执行"

Claude 会引导你完成 **6 个步骤**：

1. **确认信息** — 确认任务类型、描述和所需变量
2. **目标分支** — 使用当前分支（用于测试）或 `master`（用于正式定时任务）
3. **建议时间** — 执行 `glab schedule list`，分析现有调度，推荐 2–3 个合适时间段并说明理由
4. **重复检查** — 若已存在同名 Schedule，提前告警
5. **创建/更新** — 通过 `glab` 完成 Upsert，并验证 Schedule 已出现在列表中
6. **冒烟测试** *(可选)* — 立即触发，上报 Pipeline URL，后台轮询，完成后汇报结果

---

## 时间建议策略

Claude 在建议时间前会先查看现有调度，采用三种策略：

- **归组** — 与同类任务集中在同一时间窗口（如所有报告任务统一在 09:00 SGT）
- **复用** — 如果你已有合适的 cron，直接复用
- **避峰** — 低峰时段：维护任务选 01:00–05:00 SGT，摘要任务选 10:00–11:00 SGT

可以接受建议，也可以自己提供 cron 表达式。

---

## 常见用法

直接输入 `/ads-workspace-schedule-create`，Claude 会逐步询问所有必要信息。

也可以一次提供更多细节，跳过部分问答：

```
/ads-workspace-schedule-create 把 /ads-dqc-report 设置为每周一上午 9 点运行

/ads-workspace-schedule-create 每天凌晨 2 点执行 scripts/flush_cache.sh

/ads-workspace-schedule-create 按顺序执行两个提示词：先 /ads-dqc-report，再 /ads-knowledge-qa weekly digest，每个工作日 9 点

/ads-workspace-schedule-create 为 scripts/sync.py 创建定时任务，先用我当前的分支测试
```

---

## 冒烟测试

创建 Schedule 后，Claude 可以立即触发并监控 Pipeline：

- 立即上报 Pipeline URL，方便实时查看进度
- 后台轮询，完成后通知你结果
- 成功时：展示任务输出摘要
- 失败时：区分是 Runner 临时故障还是配置/脚本问题，并给出修复建议

---

## 提示与注意事项

- **密钥安全**：不要将密码或 Token 直接写入 Schedule 变量，应使用项目级 Masked CI/CD 变量，在脚本中按名称引用。
- **目标分支**：新脚本上线前先选当前分支做冒烟测试，确认无误后切换为 `master` 正式运行。
- **更新已有 Schedule**：用相同的 description 再次触发 Skill 即可，Claude 会自动删除旧的并重建，确保变量同步。
- **多步骤执行**：支持链式执行多个提示词（`AI_PROMPT_1`、`AI_PROMPT_2`……）或多个脚本（`SCRIPT_1`、`SCRIPT_2`……），任一步骤失败即停止。
- **脚本语言**：Script 类型任务会根据文件扩展名自动识别运行时（`.py` → python3，`.sh` → bash，`.js` → node），也可以直接传入原始 Shell 命令。
