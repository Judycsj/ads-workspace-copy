# Ads PRD Quality Check Guide

> **Contributors**: shuo.zhao, luka.yang, zhikang.piao ｜ **最后更新**：2026-07-01 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-xteam-prd-quality-check.md)

> **Language**: [English](ads-xteam-prd-quality-check.md) | [中文](ads-xteam-prd-quality-check.zh-CN.md)

Review Ads PRDs for required content issues using the PRD body, comments, and suggestions as the default source of truth. An explicit docs-KB mode may use workspace-relative `docs/**` as background knowledge only.

If the PRD explicitly names Advertiser Strategy as a required participant, the review also checks whether the PRD defines the test scope they should validate, including environment, product type, acceptance fields, and the acceptance goal.

**Trigger keywords**: "ads-xteam-prd-quality-check", "PRD quality check", "PRD review", "review PRD", "需求质检", "PRD质检", "帮忙review PRD", "check PRD"

## Scenario 1: Review One PRD

> **You**: `Use /ads-xteam-prd-quality-check to review this PRD: <link>`
>
> **AI**: Reads the PRD body and available comments, then returns only required issues.

## Scenario 2: Platform PRD Review

> **You**: `这个 Ads Platform PRD 帮忙质检一下`
>
> **AI**: Focuses on scope, lifecycle, touchpoint parity, popup/banner/card priority, toggle/whitelist behavior, source of truth, fallback, and rollout gaps.

## Scenario 3: Data PRD Review

> **You**: `这个数据落表 PRD 看看缺什么`
>
> **AI**: Checks table scope, source of truth, field schema, grain, refresh cadence, backfill, retention, and data quality acceptance.

## Scenario 4: Docs-KB Enhanced Review

> **You**: `用 ads-workspace docs KB 帮忙质检这个 PRD`
>
> **AI**: Uses only workspace-relative `docs/**` as optional background knowledge, keeps issues grounded in the PRD, and returns only Required Issues.

## Scenario 5: Advertiser Strategy Validation Scope

> **You**: `这个 PRD 会找 Advertiser Strategy 一起验收，帮我看看还缺什么`
>
> **AI**: Checks whether the PRD clearly defines the validation environment, covered product type(s), acceptance fields, and acceptance goal for Advertiser Strategy sign-off.

## Scenario 6: Incentive Task Issuance / Seller Pre-Selection

> **You**: `Review this incentive / reward center task PRD`
>
> **AI**: Checks whether the PRD follows the standard incentive model: **pre-selected seller list → batch seller-level task creation → real-time events only activate existing tasks** (see incentive-preselect-lens). Skips voucher modules, FSS/escrow card whitelists, and feature toggles that are not task enrollment.

## Scenario 7: Suggested Amount / Platform Min-Max Bounds

> **You**: `这个 PRD 有建议充值/预算金额，帮忙质检一下`
>
> **AI**: Applies only when the PRD defines a **computed or displayed suggest amount**. Checks **min/max bound source**, **out-of-bound handling**, and **multi-touchpoint parity** when two+ surfaces each show amounts (see suggested-amount-bound-lens). Skips low-balance alert cards with CTA-only, reward credit usage rules, and data/algo docs.

## Output

The normal output is intentionally compact:

```text
Required Issues
1. ...
2. ...
```

In **discover** mode, host metadata now includes `prd_title` (string) and `prd_summary` (object with title, summary, background, goal, scope, non_goals, risks) fields for downstream Business Epic generation.

## Good Fit

- PRD readiness checks before review or development
- Content-focused requirement gap review
- SeaTalk bot PRD quality-check output

## Not a Good Fit

- TD/TRD review
- Code review or implementation debugging
- Full impact analysis that requires reading source code, repo README files, Jira, Sheet, Figma, TD, or TRD links
