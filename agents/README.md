# Agents

Agents are **specialized sub-agents** with scoped tool permissions and focused expertise. Unlike skills (knowledge loaded into the main conversation), agents run as separate entities with their own system prompt and restricted tool access.

## Cross-Tool Compatibility

Agent files use a **unified format** recognized by Claude Code, Cursor, and Codex. Each tool reads from its own directory but shares the same `.md` file format.

### Storage Paths

| Scope | Claude Code | Cursor | Codex |
|-------|------------|--------|-------|
| User-level | `~/.claude/agents/` | `~/.cursor/agents/` | `~/.codex/agents/` |
| Project-level | `.claude/agents/` | `.cursor/agents/` | `.codex/agents/` |

Priority: project-level > user-level.

The `sra add` installer symlinks agents to **all three** user-level directories automatically.

### Frontmatter Fields

| Field | Required | Claude Code | Cursor | Codex | Notes |
|-------|----------|-------------|--------|-------|-------|
| `name` | No | Yes | Yes | Yes | Defaults to filename; kebab-case |
| `description` | No | Yes | Yes | Yes | Guides automatic delegation |
| `tools` | No | **Yes** | Ignored | Ignored | Claude Code restricts tool access per agent |
| `model` | No | `opus`/`sonnet` | `fast`/`inherit`/model ID | Ignored | Each tool has its own model vocabulary |
| `readonly` | No | Ignored | **Yes** | **Yes** | Cursor/Codex restrict write permissions |

**Compatibility strategy**: include both `tools` (for Claude Code) and `readonly` (for Cursor/Codex) in the same file. Each tool uses the fields it understands and ignores the rest.

## Design Principles

1. **Least privilege** — Analysis agents get read-only access. Use `tools: [Read, Grep, Glob]` (Claude Code) + `readonly: true` (Cursor/Codex).
2. **Single responsibility** — Each agent has one clear job. A planner plans, a reviewer reviews.
3. **Model selection** — Complex reasoning tasks use `opus`/slower models. High-throughput tasks use `sonnet`/`fast`.

## Available Agents

| Agent | Purpose | Tools (Claude Code) | Model | Readonly |
|-------|---------|---------------------|-------|----------|
| `ads-diagnosis-module-reviewer` | Reviews single or batch ads-diagnose case outputs and judges first-level R module attribution correctness, including model/bidding drilldown routing | `Read`, `Grep`, `Glob` | `opus` | `true` |
| `ads-diagnose-bidding-deepdive` | Deep-dive R4 出价调控 leaf attribution dispatched by ads-diagnose main skill when R4 hits; runs supplementary ClickHouse queries for final_coef / MPC / data collection | `Bash`, `Read`, `Grep`, `Glob` | `opus` | `true` |
| `ads-diagnose-model-deepdive-hb` | Deep-dive R3 model-side PCOC attribution dispatched by ads-diagnose main skill when R3 hits; separates UniCR coverage, arrival buckets, and delayed-feedback mechanisms | `Bash`, `Read`, `Grep`, `Glob` | `opus` | `true` |
| `ads-xteam-runner` | Runs the Ads PRD/TRD-to-acceptance SOP from SeaTalk/OpenClaw messages and returns structured notification actions | `Read`, `Grep`, `Glob` | `opus` | `true` |
| `bid-sense-api-dev` | Full-cycle API development on Bid Sense configurable service: TD design, YAML config + biz_logic code generation, local unit tests, Redis mock data setup, test request generation | `Read`, `Write`, `Bash`, `Glob`, `Grep` | `opus` | `false` |
| `ads-platform-planner` | Deprecated compatibility wrapper for the old Ads Platform planner agent | `Read`, `Grep`, `Glob`, `SemanticSearch` | `opus` | `true` |
| `ads-roi3-analysis-runner` | ROI3 analysis executor dispatched by the ads-roi3-analysis hub: takes a confirmed plan card, runs preflight → routing → inline spoke execution → synthesis → report + repro; non-interactive, no nested subagents | `Read`, `Glob`, `Grep`, `Bash`, `Skill`, `Write`, `Edit` | `opus` | `false` |

## Creating New Agents

1. Create a `.md` file in this directory
2. Add frontmatter with cross-tool compatible fields:

```yaml
---
name: agent-name
description: >
  One-line description of when this agent should be used.
tools:             # Claude Code: restrict available tools
  - Read
  - Grep
  - Glob
  # - Edit        # only if agent needs to modify files
  # - Bash        # only if agent needs shell access
model: sonnet      # Claude Code: opus for complex reasoning, sonnet for throughput
readonly: true     # Cursor/Codex: restrict write permissions
---
```

3. Write clear instructions in the body: role, process, output format
4. Follow least-privilege: start read-only, add write tools only if truly needed

## Installation

Agents are **auto-installed** by `sra add` to all detected tools:

```
~/.claude/agents/<name>.md  -> agents/<name>.md
~/.cursor/agents/<name>.md  -> agents/<name>.md
~/.codex/agents/<name>.md   -> agents/<name>.md
```
