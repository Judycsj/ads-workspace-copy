# Docs / 文档

> **Contributors**: luka.yang ｜ **Last Updated**: 2026-05-13 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/README.md)
> **Language**: [English](README.md) | [中文](README.zh-CN.md)

Team knowledge base — Markdown documents organized by scope and kept directly readable by `/ads-knowledge-qa` and other agents.

## Layout

```
docs/common/           Cross-team docs: business overviews, SOPs, data specs
docs/team/<team>/      Team-specific docs: OKRs, TDs, how-tos, case studies, postmortems
docs/personal/<email>/ Personal docs: notes, drafts, research
```

Current team scopes: `00.paid-ads-dev`, `01.ads-engineering`, `02.ads-platform`, `03.content-algo`, `04.product-algo`, `05.recall-algo`, `09.ads-dev-sharing-session`, `10.paid-ads-pm`, `20.paid-ads-dpm`, `30.paid-ads-da`.

## What Goes Here

| Type              | Examples                                          |
| ----------------- | ------------------------------------------------- |
| Business overview | Ads introduction, bidding strategy, product specs |
| SOP / How-to      | Skill usage SOP, Claude Code setup guide          |
| Technical design  | TDs, architecture decisions (ADRs)                |
| OKR / Reports     | Quarterly OKRs, monthly/weekly reports            |
| Case study        | Optimization experiments, postmortems             |
| Data reference    | DataMap field lists, table schemas                |

## What Doesn't Go Here

* Skill-specific reference material → put it in `skills/<scope>/<skill>/references/`

* Skill usage guides → put them in `guides/<scope>/`

## Common Docs

| File                               | Description                                                                                      |
| ---------------------------------- | ------------------------------------------------------------------------------------------------ |
| `common/core-knowledge/`           | Ads core knowledge (split by section, bilingual) — see [index](common/core-knowledge/README.md)  |
| `team/00.paid-ads-dev/04.how-tos/` | Workspace usage manuals (how-tos) — see [index](team/00.paid-ads-dev/04.how-tos/README.md) |

## Naming Convention

* Lowercase kebab-case: `ads-bidding-overview.md`

* Match the document language: suffix `.zh-CN.md` for Chinese, no suffix for English

* Group related files in subdirectories when a topic has 3+ documents

## Why Keep Docs Here

`/ads-knowledge-qa` and other agents can read `docs/` directly as workspace context. The more complete and up-to-date the docs, the higher the answer quality.
