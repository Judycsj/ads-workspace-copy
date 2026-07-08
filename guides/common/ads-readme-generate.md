# README Generator for Ads Projects (ads-readme-generate) Guide

> **Contributors**: fengjiao.wang ｜ **最后更新**：2026-06-03 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-readme-generate.md)
> **Language**: [English](ads-readme-generate.md) | [中文](ads-readme-generate.zh-CN.md)

Automatically generates or updates Chinese and English versions of README files for Ads-related projects by analyzing the codebase and referencing local core-knowledge docs.

**Trigger keywords**: "generate README", "update README", "ads-readme", "生成 README", "更新文档"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition and generation workflow |
| `references/readme-spec.md` | Built-in spec: Part 1 skeleton (output location & languages, TOC, marker, terminology) + Part 2 methodology (skip_dirs read-scope, business areas, per-section mining, **service-topology recipe**, **delegation map**) |
| `references/repos.md` | Repo registry (`category | project_name | repository_url | PIC`) — project-name → URL source, shared with the overview generators and CI |
| Local `docs/common/core-knowledge/` | Business-context source (selected by domain); the only external reference — no off-site fetching |
| `scripts/` | Helper scripts (changed-files detection for incremental mode) |

Generation principles live in `SKILL.md` (single source, not duplicated in references).

Repo-specific facts (`project_name`, `repository_url`, `skip_dirs`, terminology, topology) are derived from code + git at generation time; stable cross-repo skeleton and methods live in `references/`.

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| Git repository | Local | Source code for analysis |
| Local `docs/common/core-knowledge/` | Local | Business-context reference |

This skill reads **code + local core-knowledge only** — it fetches no off-site documentation and needs no MCP / token. Live data (Kafka / monitoring / Config Center, etc.) is delegated to sibling skills on demand, degrading gracefully when a token is missing.

---

## Usage

### Basic Usage

> Current working directory is **ads-workspace**; always run from the ads-workspace root.

```bash
# Give the bare project name → resolves URL from repos.md, clones to projects/gitlab/<name>/, then analyzes
# (if that dir already exists, pull the latest code of the default branch)
/ads-readme-generate bidding-store-cpp
```

### Scenario 1: First-time README generation

> "Generate README for my-service project"

The skill will:
1. **Repo setup (Step 0)** — clone/pull the repo, then derive `project_name`, `repository_url`, `skip_dirs`, terminology, and business area per readme-spec's "Repo Profiling"
2. **Decide strategy (Step 1)** — no README means full generation; this step uses git/local files only, zero external dependency
3. **Generate README (Step 2)** — analyze with code as the source of truth and produce the README; local `docs/common/core-knowledge/` is only a business-context reference; delegate to sibling skills for live facts (topology, monitoring, glossary)
4. Write both files to `docs/common/readme/<project_name>/` in ads-workspace: `README.md` (English) and `README.zh-CN.md` (Chinese)

### Scenario 2: Update existing README

> "Update the README for our service"

The skill will:
1. Detect the generation marker at the end of existing README
2. Re-analyze only changed sections
3. Preserve manual edits outside the generation marker
4. Update both language versions keeping them in sync

### Scenario 3: Custom or framework-specific structure

> "Generate README with the right structure for this service"

The structure adapts automatically:
- The TOC skeleton in `references/readme-spec.md` (Part 1) provides the stable top-level sections
- Sub-sections expand from code facts (e.g. a BRPC service gets an API section; an FE repo gets a build/release section)
- To change a *cross-repo* convention (a new common section, a new delegation), edit the relevant `references/` file once — it applies to all repos

---

## Built-in Spec vs Runtime Derivation

Inputs come from two sources:

**Built-in (stable, cross-repo)** — in `references/`:
- `readme-spec.md` — Part 1 (output location & languages, TOC skeleton, generation marker, terminology) + Part 2 (skip_dirs read-scope, business areas, per-section mining, **service-topology recipe**, **skill delegation map**)
- `repos.md` — repo registry (category, repo, full URL, PIC)

**Business context** — local `docs/common/core-knowledge/`: relevant docs selected by domain (the only external reference).

**Runtime-derived (per repo, never stale)** — computed during generation:

| Field | Derived from |
|-------|--------------|
| `project_name` | bare project-name arg → `projects/gitlab/<name>/` |
| `repository_url` | `URL` column in `repos.md` |
| `skip_dirs` | Build-tool detection (`MODULE.bazel`/`go.mod`/`package.json`/…) + common fallback |
| terminology | Common list + core types/classes/services mined from code |
| service topology | Topology recipe: static mining of RPC/MQ/store/config deps + delegated fill-in |
| domain | Inferred from `repository_url` / code features → selects core-knowledge docs |

---

## Delegated Sibling Skills

To keep facts current, generation delegates to sibling skills — **delegate as much as possible for the most complete info**; skip and degrade gracefully when a platform token is unavailable (e.g. in CI):

| Content | Skill |
|---------|-------|
| Kafka / Pulsar topics, consumer groups | `ads-kafka-info` |
| Redis / cache cluster info | `ads-cachecloud-info` |
| Config Center namespaces / keys | `ads-config-center-compare-export` |
| Deployment / SDU / service tree | `sp-space` |
| Monitoring dashboards | `sp-grafana` |
| Business glossary | `sra-glossary` |
| Third-party dependency source | `sra-code-search` |

---

## Generation Workflow

### Step 0: Repo Setup

1. **Set up the repo**: take `<project_name>` → look up its `URL` in `repos.md` (this is `repository_url`) → clone to `projects/gitlab/<name>/` (pull the default branch if it already exists; error if not registered)
2. **README blueprint**: per `readme-spec.md`, understand the README's skeleton spec (Part 1) and per-section mining guide (Part 2)

### Step 1: Decide Strategy & Change Scope (zero external dependency, first)

Check whether the target README exists with a generation marker, then choose A/B and compute the **affected-section scope**. This step uses git and local files only:

- **Exists (Incremental A)**: affected sections = union of "code changes ∪ spec changes".
  - Code changes: CI uses `.readme_changed_files` at the repo root (written by `scripts/get_changed_files_since_readme.sh`, baselined on README's last commit); local uses `git diff`. `deleted:` lines must have their docs removed from the README.
  - Spec changes: `readme-spec.md` spec hash ≠ the marker's `spec:` hash.
  - **No change at all** → just refresh the marker / stop; skip the later steps.
- **Absent (Full B)**: affected sections = all; read the entire repo (skipping `skip_dirs`).

### Step 2: Generate / Update README (the skill's focus)

Analyze affected sections with **code as the source of truth** and produce the README; local `docs/common/core-knowledge/` is only a **business-context reference** (read by domain), and code always wins on technical-fact conflicts.

- Write/update `README.md` (English) and `README.zh-CN.md` (Chinese) into `docs/common/readme/<project_name>/` (created if absent) per the spec's language config
- B (full): follow the TOC skeleton, expand sub-sections from code facts; A (incremental): update only affected sections in place, keep the rest
- For each section, mine facts per `readme-spec.md` (Part 2) and delegate to sibling skills for live data (topology/monitoring/glossary, degrade gracefully if a token is missing); build the Architecture section per the **topology recipe** (static mining → delegated fill-in → Mermaid diagram + upstream/downstream/dependency tables); code wins on conflicts
- Middleware dependencies must include **concrete instance names plus read/write direction**: Kafka topic / producer config / consumer group, Redis cluster/host/key/TTL, FSE table/scene/namespace, DB/table/DSN, Vespa schema/index, Hive table, S3 bucket/path, and so on. Do not write only "writes Kafka", "reads Redis", or "uses FSE". If the repository does not directly access middleware, say that explicitly.
- If automatic scanning finds no middleware instance information, the README must include the fixed marker `未能自动化检出中间件信息`. After the owner manually confirms there is no middleware, they should change it to `已人工确认没有中间件信息`. Future generations skip middleware-instance scanning for that repo when the manual-confirmation marker is present.
- Refresh the generation marker (`checked` HEAD hash + `spec` hash) at the end

> Side note (not the focus): if a core-knowledge doc clearly conflicts with / lags the code, you may list it briefly at the end for manual review; this skill only produces README and never modifies core-knowledge.

---

## Output Format

Each language file contains:

1. **Project Overview** — Purpose, repository link, quick start
2. **Architecture / Architecture** — System design, service topology (if applicable)
3. **Features** — Key capabilities with code references
4. **Installation / Setup** — Dependencies, build steps (from actual Makefile/configs)
5. **Usage / API** — Actual commands and examples (from codebase)
6. **Development** — Contribution guidelines, testing
7. **References** — Repo link, related repos, stable manual/protocol links kept from the old README

All technical details (functions, APIs, file paths) must be traceable to actual code or local core-knowledge docs.

---

## Key Principles

- **Accuracy over completeness** — Only document verified code/configs; skip uncertain content
- **No placeholders** — All commands, URLs, paths must be from actual project files
- **Eliminate duplication** — Merge repeated concepts into appropriate sections
- **Traceable sources** — Every statement must reference specific files, lines, or local core-knowledge docs
- **No generic middleware wording** — Redis/Kafka/FSE/DB dependencies must include concrete instance names and direction; naming only the middleware type is not sufficient
- **Respect manual confirmation** — `已人工确认没有中间件信息` means the owner has reviewed the repo; future generations must not overwrite it automatically
- **Code is the source of truth** — core-knowledge is only a business-context reference; code wins on conflict; this skill only produces README and never modifies core-knowledge (a brief stale-doc reminder is fine)
- **Terminology consistency** — Use `terminology` dict uniformly across both language versions
- **Chinese-English sync** — Both files must have identical sections, information, and technical details (only language differs)
- **No speculation on failed delegation** — If a sibling-skill delegation fails / has no token, don't invent content; write only from code analysis, local core-knowledge, and successful delegations

---

## Downstream Skills

| Skill | Purpose |
|-------|---------|
| `/ads-workspace-check` | Validate generated documentation consistency |
| `/ads-knowledge-qa` | Reference generated README in knowledge base queries |
| `/ads-doc-generate` | Generate related technical documents (TD/PRD/Rollout) |
