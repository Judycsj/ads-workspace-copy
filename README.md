# ads-workspace-copy

A filtered private copy of Shopee Ads `ads-workspace`.

This repo is not intended to reproduce the full internal development environment. It keeps the **workspace architecture**, **basic ads knowledge base**, **selected AI-native modules**, and **personal reusable materials**, while removing most OKR, rollout, TD/PRD project-process documents, local credentials, and repo-local code projects.

## What this repo is for

- Understand how a large Ads AI workspace is structured
- Reuse Shopee Ads basic knowledge and terminology
- Learn how AI-native team workflows are organized in practice
- Keep a personal reference repo that can be adapted to a new company later

## What this repo is not

- Not a full internal production workspace
- Not a complete archive of all project docs
- Not a runnable replacement for the original internal repos under `projects/`

## How to use this repo

### 1. Start from the workspace structure

This repo is useful because the same theme is split by responsibility rather than stacked into one folder.

- `docs/`: knowledge content
- `guides/`: usage guides and working conventions
- `skills/`: AI skills and workflows
- `templates/`: reusable output templates
- `rules/`: shared behavior constraints
- `agents/`: agent specs and agent-facing role definitions

Read these first:
- [docs/README.md](docs/README.md)
- [agents/README.md](agents/README.md)
- [templates/README.md](templates/README.md)

### 2. Use it as an Ads knowledge base

The most important knowledge entry points are:

- [docs/common/core-knowledge](docs/common/core-knowledge)
  High-level ads overview, strategy, engine, platform, and data concepts
- [docs/common/datamap](docs/common/datamap)
  Table-level data and metric mapping
- [docs/common/de-knowledge](docs/common/de-knowledge)
  Metric and ETL-oriented knowledge
- [docs/common/skill-knowledge](docs/common/skill-knowledge)
  Skill-oriented operational knowledge
- [docs/common/sub-kb](docs/common/sub-kb)
  Topic-specific sub knowledge bases
- [docs/team/20.paid-ads-dpm/ads_knowledge_base](docs/team/20.paid-ads-dpm/ads_knowledge_base)
  Structured Ads business/module knowledge base

If the goal is to learn Shopee Ads product and system basics, start from:
1. `docs/common/core-knowledge`
2. `docs/team/20.paid-ads-dpm/ads_knowledge_base`
3. `docs/common/datamap`

### 3. Use it as an AI-native workspace reference

This repo shows how an AI-native team workspace can be layered.

The main reusable pieces are:

- `skills/common/`
  Generic skills for knowledge QA, diagnosis, SQL/data analysis, experiment analysis, documentation, and KB tooling
- `skills/team/...`
  Selected team-level examples that show how skills can encode recurring workflows
- `templates/`
  Standardized templates for OKR docs, case studies, rollout docs, reports, memories, and specs
- `docs/team/09.ads-dev-sharing-session/`
  Internal sharing materials that explain how the team builds and uses AI-native workflows

Recommended folders to inspect:
- `skills/common/ads-knowledge-qa`
- `skills/common/ads-biz-diagnose`
- `skills/common/ads-diagnose`
- `skills/common/ads-data-sql-executor`
- `skills/team/04.product-algo/ads-okr-epic-review`
- `skills/team/04.product-algo/ads-roi3-analysis`
- `skills/team/01.ads-engineering/ads-db-viewer`
- `skills/team/02.ads-platform/ads-platform-overview-doc-generate`

### 4. Use it as a personal migration base

This copy also keeps personal materials that are useful for migration:

- [docs/personal/shijing.chen](docs/personal/shijing.chen)
- [guides/personal/shijing.chen](guides/personal/shijing.chen)
- `skills/personal/shijing.chen/` if present

These are the right places to keep:
- personal rules
- reusable PM/analysis workflows
- personal AI collaboration conventions
- future-company starter materials

## Suggested reading order

If your goal is **understanding Shopee Ads**, read:
1. `docs/common/core-knowledge`
2. `docs/team/20.paid-ads-dpm/ads_knowledge_base`
3. `docs/common/datamap`

If your goal is **learning AI-native team setup**, read:
1. `docs/team/09.ads-dev-sharing-session`
2. `skills/common`
3. `skills/team`
4. `templates`

If your goal is **building your own future workspace**, read:
1. `docs/personal/shijing.chen`
2. `guides/personal/shijing.chen`
3. `skills/personal/shijing.chen`
4. selected `skills/common` and `templates`

## Kept scope of this copy

This copy intentionally keeps:
- workspace architecture
- common ads knowledge
- selected common/team skills
- selected AI-native sharing materials
- personal materials under `shijing.chen`

This copy intentionally removes or omits:
- most OKR / rollout / TD / project process docs
- daily/weekly operational reports
- other people's personal folders
- local/internal `projects/*`
- local credentials and ignored artifacts

## Practical reuse principle

The most valuable pattern in this repo is not any single document. It is the structure:

- separate `common`, `team`, and `personal`
- separate `knowledge`, `workflow`, `skill`, `template`, and `agent`
- keep reusable long-term assets, not just temporary project output

That structure is the main thing worth copying to a new company.
