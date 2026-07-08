# Ads XTeam Runner Guide

> **Language**: [English](ads-xteam-runner.md) | [中文](ads-xteam-runner.zh-CN.md)

Semantic runner for the Ads cross-team PRD-to-acceptance workflow, including
demo review before testing, release on live before acceptance, optional rollout,
and final biz result review. It extracts intent and facts from SeaTalk or
harness messages while the host system owns project routing, state transitions,
gate checks, side effects, and user-visible reply templates.

**Trigger keywords**: "ads-xteam-runner", "PRD signed off", "TD signed off",
"coding done", "demo review", "test done", "QA done", "acceptance done",
"release on live", "rollout", "biz result", "participant teams", "PIC",
"effort", "PRD quality check", "TD quality check"

## Typical Usage

The runner is normally invoked by Ads Project Tracker rather than directly by a
human:

```text
@Ads Project Tracker PRD: <link>
@Ads Project Tracker platform BE participates, effort 2.5d
@Ads Project Tracker PRD signed off
```

## Responsibilities

- Extract workflow intent and durable facts from natural language.
- Use `ads-xteam-prd-quality-check` for PRD required issues when asked.
- Use `ads-xteam-td-quality-check` for TD quality issues when asked.
- Return structured JSON for the host to validate.

## Boundaries

- Do not own or mutate project state.
- Do not create Jira issues or transition Jira status.
- Do not create Business Epic files unless the host delegates it.
- Do not decide hard gates without explicit evidence from the current message.
