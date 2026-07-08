# Schedule Create (ads-workspace-schedule-create) Guide

> **Contributors**: boonhing.tan ｜ **最后更新**：2026-06-18 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-workspace-schedule-create.md)
> **Language**: [English](ads-workspace-schedule-create.md) | [中文](ads-workspace-schedule-create.zh-CN.md)

Create or update a GitLab Pipeline Schedule for `ads-workspace` without writing any CI yml files.
All configuration is injected as schedule variables — Claude handles the rest.

**Output**: Creates a schedule visible at
[`-/pipeline_schedules`](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/pipeline_schedules).
The schedule runs CI jobs automatically on the configured cron cadence.

**Trigger keywords**: "ads-workspace schedule", "pipeline schedule", "scheduled task",
"schedule a skill", "schedule a script", "schedule an AI prompt",
"创建定时任务", "配置定时流水线"

---

## Two Task Types

| Type | When to use | Example |
|------|-------------|---------|
| **AI** (`run-skill`) | Run a Claude skill or prompt on a schedule | Daily DQC report, weekly digest |
| **Script** (`run-script`) | Run a Python / shell / JS file or raw command | Data sync, cache flush, notification script |

### Simple vs. Complex Tasks

**Prefer Claude Code CLI** (`run-skill` / `run-script`) — it handles MCP servers, Google Workspace credentials, pre-scripts, skill installs, and artifact uploads via schedule variables. No new yml needed for most tasks.

**Simple** — no new yml file needed:

| Scenario | How |
|---|---|
| Run a prompt/skill/script on a cron | Configure via schedule variables — Claude handles it all |
| Custom timeout | Use a preset: `RUN_STAGE=run-skill-30m`, `run-skill-1h`, `run-skill-3h` |
| Custom timeout + artifact expiry combo | Claude adds a new `extends` block to the existing template yml, commits it, then creates the schedule |

**Complex** — Claude creates a dedicated `schedules/.gitlab-ci-your-task.yml`:

| Example | Why a new yml is needed |
|---|---|
| Multi-repo fan-out | Hidden job template + generate/trigger yml — see `.gitlab-ci-update-readme-job-cc.yml` + `.gitlab-ci-update-readme-cc.yml` |
| Many pre-set defaults | Too many task-specific variables to set manually each run — see `.gitlab-ci-ads-workspace-gdoc-sync.yml` |

For complex tasks, just describe what you need — Claude will create the yml file, update `.gitlab-ci.yml`, commit the changes, and create the schedule. If any step requires your action (e.g. merging an MR before the smoke test can run), Claude will tell you explicitly.

---

## How It Works

Invoke the skill by describing what you want to schedule:

> "Help me schedule the `/ads-dqc-report` skill to run every Monday at 9am"

> "Schedule `scripts/sync_data.py` to run nightly"

Claude will guide you through **6 steps**:

1. **Clarify** — Confirm task type, description, and variables needed
2. **Target branch** — Use your current branch (for testing) or `master` (for permanent tasks)
3. **Suggest timing** — Run `glab schedule list`, analyse existing schedules, and propose 2–3 good time slots with reasons
4. **Check for duplicates** — Warn if a schedule with the same description already exists
5. **Create / update** — Upsert the schedule via `glab`; verify it appears in the list
6. **Smoke test** *(optional)* — Trigger immediately, report the pipeline URL, poll in background, and summarise the result when done

---

## Timing Suggestions

Claude always checks existing schedules before suggesting a time. Three strategies:

- **Group** — Add your task near other similar tasks (e.g. all report jobs at 09:00 SGT)
- **Reuse** — Reuse a cron you already own if the timing fits
- **Off-peak** — Quiet slots: 01:00–05:00 SGT for maintenance, 10:00–11:00 SGT for digests

You can accept a suggestion or provide your own cron expression.

---

## Common Invocations

Just type `/ads-workspace-schedule-create` and Claude will ask all the needed questions interactively.

You can also provide details upfront to skip some steps:

```
/ads-workspace-schedule-create schedule /ads-dqc-report to run every Monday at 9am

/ads-workspace-schedule-create set up a nightly schedule to run scripts/flush_cache.sh at 2am

/ads-workspace-schedule-create schedule two prompts in sequence: first /ads-dqc-report, then /ads-knowledge-qa weekly digest, every weekday at 9am

/ads-workspace-schedule-create create a scheduled task for scripts/sync.py — run it daily and use my current branch for testing first
```

---

## Smoke Test

After creating the schedule, Claude can trigger it immediately and watch the pipeline:

- The pipeline URL is reported right away so you can follow along
- Claude polls in the background and notifies you when it finishes
- On success: shows a summary of the job output
- On failure: classifies the error (transient runner issue vs config/script bug) and suggests fixes

---

## Tips and Gotchas

- **Secrets**: Never put passwords or tokens in schedule variables — use project-level masked CI/CD variables instead, then reference them by name in your script.
- **Branch**: Choose your current branch for smoke-testing a new script before merging. Switch to `master` for permanent recurring tasks.
- **Updating a schedule**: Just run the skill again with the same description — Claude will delete and recreate it so all variables stay in sync.
- **Multiple steps**: You can chain prompts (`AI_PROMPT_1`, `AI_PROMPT_2`, …) or scripts (`SCRIPT_1`, `SCRIPT_2`, …) in one schedule. Any failure stops the sequence.
- **Script language**: For script tasks, Claude auto-detects the runtime from the file extension (`.py` → python3, `.sh` → bash, `.js` → node). You can also pass a raw shell command instead of a file path.
