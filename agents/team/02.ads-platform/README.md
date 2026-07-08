# Ads Platform Agent Team Guide

This guide explains how to use the Ads Platform FE agent team from Codex or
Claude, what each role does, and which artifacts should be reviewed during a
delivery run.

## 1. Core Concepts

| Concept | Meaning |
| --- | --- |
| Agent | An AI worker — has a role prompt, tool permissions, and output contract, and focuses on doing one kind of work well (e.g., PRD analysis, solution planning, implementation, or review). |
| Agent Team | An AI team — a set of agents sharing one delivery workflow, orchestrated by the main agent with sub agents dividing the work, collaborating to deliver FE requirements end to end (from goal intake to implementation, optional review, and knowledge candidates). |
| Main Agent | The agent that orchestrates the full workflow, creates artifact directories, enforces owner gates, records decisions, and dispatches sub agents. |
| Sub Agent | An agent invoked by the main agent during a stage. Owners should normally talk to the main role first; the main agent then dispatches sub agents with the right artifacts and scope. |
| Block | A bounded delivery unit within the PRD or requirement set. A block is the unit for PRD Phase 2, TD/Solution planning, implementation, optional review, and `block-summary.md`. Multi-area PRDs should be processed block by block. |
| Wave | A dispatch group of implementation tasks that can run in parallel because their dependencies are already satisfied. Solution Architect defines waves from the `TASK-NNN` dependency graph. |

**Supplementary Notes:**

1. **How blocks are split**: block splitting is driven mainly by business boundaries and delivery boundaries in the requirement itself. In practice, split by independent pages/routes, independent business projects, independent flows, or weakly coupled functional domains. If multiple requirements share core context and should be decided together, they should usually stay in the same block.
2. **Difference and relationship between Block and Wave**: a Block is the upper-level requirement analysis and delivery orchestration unit, deciding "which requirement slice to handle first"; a Wave is the implementation-stage parallel execution unit, deciding "which tasks can be executed together". One Block usually maps to one or more Waves, but Waves are only defined inside a single Block based on task dependencies and do not run across Blocks.

## 2. Roles

| Role | Agent Type | Responsibility | Main Output |
| --- | --- | --- | --- |
| `Owner` | Human | Human owner, conversant — provides the goal; reviews / edits / approves at each manual-confirmation gate; prunes the PRD and selects the active block; decides whether to generate a TD or run Reviewer; approves the task table and artifacts. | Manual confirmations and decisions (no own files; decisions recorded by Lead in `decision-log.md`) |
| `ads-platform-lead` | Main Agent | Orchestrator — orchestrates the full workflow, creates artifact directories, enforces owner gates, records decisions, and dispatches sub agents. | `decision-log.md`, `block-summary.md`, `knowledge-candidates.md` |
| `ads-platform-analyst` | Sub Agent | Analyst — analyzes the input in two phases: run-level PRD summary and active-block PRD handoff. | `prd-summary.md`, `prd-analysis-handoff.md`, `tracking-bridge.json` |
| `ads-platform-architect` | Sub Agent | Architect — in TD mode, generates the TD document. In handoff mode, resolves implementation impacts, Transify/i18n context, task table, and dispatch waves. | `td-*.md`, `ads-platform-architect-handoff.md`, `transify/*.json` when needed |
| `ads-platform-engineer` | Sub Agent | Engineer — executes one `TASK-NNN` at a time and writes a concise implementation handoff. | `ads-platform-engineer-<TASK-NNN>-handoff.md` |
| `ads-platform-reviewer` | Sub Agent | Reviewer — optional quality gate for requirement coverage, code quality, lint/type-check evidence, and retry requests. | `ads-platform-reviewer-handoff.md`, optional `review-coverage-full.md` |

## 3. Layering

The design uses a three-layer model: **Agent → Skill → Doc**.

```text
Agent layer          defines "who does what" — role responsibilities and handoff protocol
  │
  ↓ invokes
Skill layer          defines "how a kind of capability is executed" — reusable execution units
  │
  ↓ reads on demand
Doc layer            provides "the knowledge needed to execute" — loaded by the agent at runtime
```

The three layers stay in their lanes: an Agent prompt carries no knowledge, a Skill carries no full-workflow orchestration, and Doc layer only provides facts, not decisions.

### 3.1 Agent layer

The Agent layer defines "who does what". Each agent in this team is a self-describing markdown file under `agents/team/02.ads-platform/`, focused on one kind of work, declaring its tools and capabilities via frontmatter, and carrying no business knowledge.

```text
agents/team/02.ads-platform/
├── ads-platform-lead.md
├── ads-platform-analyst.md
├── ads-platform-architect.md
├── ads-platform-engineer.md
└── ads-platform-reviewer.md
```

### 3.2 Skill layer

The Skill layer contains only **capability skills**, defining "how a kind of capability is executed". A single skill is responsible for one stable kind of execution capability and does not take on full-workflow orchestration; knowledge-type content is not packaged as a skill. These skills are not orchestrated by agents directly — during implementation, `ads-platform-engineer` invokes them per the task's `skill_hint` and the Skill Invocation Decision Table (`ads-platform-architect` matches and writes the `skill_hint` when generating tasks).

The **codegen series** — `ads-platform-codegen-*` — covers the most common request shapes across Ads Platform front end / back end:

```text
skills/team/02.ads-platform/
├── ads-platform-codegen-api/
├── ads-platform-codegen-config-center/
├── ads-platform-codegen-feature-toggle/
├── ads-platform-codegen-modal/
├── ads-platform-codegen-rewards-center/
├── ads-platform-codegen-todo-card/
└── ads-platform-codegen-tracking/
```

### 3.3 Doc layer

The Doc layer provides the project knowledge an agent needs at runtime; the agent loads it **on demand** via the Read tool and does not preload it into the prompt. The knowledge lives under `docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/knowledge-base/` (accessed at runtime via `<projects-root>/.symlinks/docs`), and its core is a **two-level `index.yml` routing system + domain knowledge markdown**:

```text
docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/knowledge-base/
├── index.yml                           top-level routing entry
├── pas-common/index.yml
├── product-ad-creation/                feature-flow domain
│   ├── index.yml                       domain router: primary doc + companions
│   ├── creation.md                     main-flow doc
│   ├── creation-product-selection.md   companion
│   └── creation-bidding-strategy.md    companion
├── product-ad-detail/
│   ├── index.yml
│   └── detail.md
└── rewards-center/                     cross-project functional domain
    ├── index.yml
    ├── rewards-program-landscape.md
    ├── rewards-data-flow-main-path.md
    ├── rewards-api-details-and-contracts.md
    ├── rewards-domain-models-and-enums.md
    ├── rewards-tracking-events-map.md
    └── …
```

**Top-level `index.yml`** — a lightweight router that does not duplicate README/wiki/skill content. Its `how_to_use` defines the lookup order: match `functional_modules` first (cross-project domains such as rewards-center / product-ad-creation / product-ad-detail), fall back to `modules` (project-level: pas-common / pas-index / pas-product / pas-display / pas-livestream / pas-mcn / pas-shop / ads-remote / ads-marketing / pas-e2e-tests), then read the domain's `entry_docs`; if the task is a codegen workflow, match the matching skill from the `skills` section.

**Domain `index.yml`** (e.g. `product-ad-creation/index.yml`) — a flow router pointing to one primary doc (`path`) plus several `companions`, each gated by `applies_when` / `read_when` (file_globs + keywords) so the agent **matches first, then reads precisely** instead of scanning the whole folder.

The domain knowledge markdown (e.g. rewards-center's program-landscape / data-flow / api-contracts / domain-models / tracking-events) only provides facts, not decisions; it is read on demand by the architect / engineer to understand a given business flow or a block of shared assets.

> The adjacent `contracts/` (handoff / task-item / td templates) and `rules/` (claude / codex / common) also live under `ai-agent/`, but they are the "handoff protocol" and "runtime rules" respectively — not the knowledge layer itself.

## 3.4 Lead Session State

To make long-running lead sessions deterministic and resumable, the team uses a persisted lead session state centered on:

- `<artifact_dir>/run-state.json`

The supporting runtime templates live under:

- `docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/contracts/run-state-template.json`
- `docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/contracts/run-state-transition-template.md`
- `docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/contracts/resume-run-template.md`

Runtime responsibilities are split as follows:

- `run-state.json` stores the current stage, stage status, active block, approved artifacts, owner decisions, dispatch history, and next required action for one run.
- `ads-platform-lead.md` enforces turn-start state checks, subagent-only stages, and strict recovery behavior.
- `contracts/run-state-template.json` defines the initial structure of `run-state.json`.
- `contracts/run-state-transition-template.md` defines which state fields must be updated together during each stage transition.
- `contracts/resume-run-template.md` defines the strict recovery entry prompt and expected recovery response shape for a fresh lead session.

Maintenance boundary:

- Put runtime enforcement in `ads-platform-lead.md`.
- Put reusable state and recovery templates in `contracts/`.
- Do not rely on conversational memory once a run has started; `ads-platform-lead` should read `run-state.json`, decide the only allowed next action, and persist every stage transition back to the state file.

## 4. Workflow

The table below follows the authoritative Stage breakdown in `ads-platform-lead.md`, listing the end-to-end path for **a single active block** (stage numbers map one-to-one to the flow diagram below). A ★ entry criterion is a manual-confirmation gate that requires owner approval before entering that stage.

| Stage | Entry criteria | Role | Responsibility | Output |
| --- | --- | --- | --- | --- |
| Stage 0 — Goal Intake | Owner has provided a goal | `ads-platform-lead` | Confirm the goal shape (input type / language / actionability), initialize the run artifact directory and decision log | run artifact directory, `decision-log.md` |
| Stage 1a — PRD Analyst Phase 1 | Intake done; goal actionable | `ads-platform-analyst` | Parse the PRD, or normalize a plain prompt into a minimal run-level requirement summary and block split | `prd-summary.md` |
| Stage 1b — PRD Analyst Phase 2 | ★ Owner has reviewed / edited `prd-summary.md` and selected the active block | `ads-platform-analyst` | For the active block, write the single-file analysis handoff (including the source appendix), initialize the tracking skeleton | `prd-analysis-handoff.md`, `tracking-bridge.json` |
| Stage 1c — Tracking + TD Decision Gate | ★ Owner resolves all three gates together: approve the PRD Phase 2 handoff, choose `tracking_mode`, and choose whether TD is required | `ads-platform-lead` (+ Owner decision) | Present the PRD Phase 2 handoff, collect the combined owner decision package, and route the run to TD mode or architect handoff mode | owner decision package (recorded in `decision-log.md`) |
| Stage 2a — Architect TD mode | Owner chose TD generation = `yes` | `ads-platform-architect` | Generate the active-block TD draft; ★ must be confirmed / edited by the owner before continuing | `td-<feature-slug>-<YYYY-MM-DD>.md` |
| Stage 2b — Architect handoff mode | Owner chose TD = `no`, or confirmed the generated TD | `ads-platform-architect` | Resolve implementation impacts, Transify/i18n, generate `TASK-NNN` and dispatch waves | `ads-platform-architect-handoff.md`, `transify/*.json` when needed |
| Stage 3 — Implementation | ★ Owner has approved the Solution handoff task table; at least one task exists | `ads-platform-engineer` × N (Lead orchestrates) | Dispatch implementers by dependency wave, execute each `TASK-NNN` | `ads-platform-engineer-<TASK-NNN>-handoff.md` |
| Stage 3b — Integration Wave | all ordinary implementation waves for the current engineering pass returned | `ads-platform-engineer` (Lead orchestrates) | Run one mandatory post-wave integration pass to check and fix cross-wave integration gaps | standard engineer handoff(s) from the integration wave |
| Stage 4 — Reviewer (optional) | Stage 3b integration wave completed; ★ Owner confirmed running Reviewer | `ads-platform-reviewer` | Optional quality gate: check requirement coverage and code quality, emit `retry_request` if needed | `ads-platform-reviewer-handoff.md`, optional `review-coverage-full.md` |
| Stage 5 — Block closeout | implementers done, Reviewer ran or was skipped | `ads-platform-lead` | Write the block closeout summary, update `completed_blocks` in `prd-summary.md` | `block-summary.md` |
| Stage 5R — Block rework decision | ★ Owner says the completed block still needs changes | `ads-platform-lead` (+ Owner decision) | Decide whether to do `implementation-rework` or `architecture-rework`; re-dispatch the affected stage using the current `ads-platform-architect-handoff.md` as the only authoritative rework plan artifact | updated implementation handoffs, or updated `ads-platform-architect-handoff.md` plus follow-up tasks |
| Stage 6 — Knowledge candidates | all selected blocks done, or the owner stopped the batch | `ads-platform-lead` | Aggregate reusable knowledge candidates, ★ owner confirms whether to persist | `knowledge-candidates.md` |

The stages above are the end-to-end path for **a single active block**. Two cases:

- **Single block (normal path)**: when the PRD covers only one business area,
  or the source is a direct prompt, **Stage 1a (PRD Analyst Phase 1)** still
  writes `prd-summary.md` but does not split it further by default; the block
  then goes straight from **Stage 0** to **Stage 6**.
- **Multi-block sequential execution**: when the PRD spans multiple business
  projects / pages / feature domains, **Stage 1a** performs a **block split** into
  several blocks (recorded in `prd-summary.md`). Only one active block is processed
  at a time through **Stage 1b → Stage 1c → Stage 2a/2b → Stage 3 → Stage 3b → Stage 4/5**. After **Stage 5 (Block closeout)**,
  the owner may first choose an optional **Stage 5R (Block rework decision)** to
  rework the current block. If no rework is needed and blocks remain, Lead asks
  whether to continue — once the next block is chosen, the flow **re-enters at
  Stage 1b (PRD Analyst Phase 2)** (reusing the existing `prd-summary.md`, no
  need to rerun Stage 1a) and repeats per block until all blocks are done, then
  generates `knowledge-candidates.md` at **Stage 6 (Knowledge candidates)**.
  Blocks are completed one by one in order by default, not in parallel.

Flow diagram:

```text
Owner goal
  │
  ▼
[Stage 0 — Goal Intake]               initialize the run artifact directory   Lead
  │
  ▼
[Stage 1a — PRD Analyst Phase 1]      write prd-summary.md (summary + block split)   Analyst
  │
  ▼  ★ owner gate: review summary, choose the active block
  │
[Stage 1b — PRD Analyst Phase 2]      write prd-analysis-handoff.md   Analyst
  │
  ▼
[Stage 1c — Tracking + TD Decision Gate]   ★ approve PRD handoff + choose tracking mode + decide whether TD is required   Lead
  │
  ├─ yes ─→ [Stage 2a — Architect TD mode]   write td-*.md          Architect
  │              │
  │              ▼  ★ owner gate: confirm / edit TD (mandatory once generated)
  │              │
  ▼ ◄────────────┘
[Stage 2b — Architect handoff mode]   write ads-platform-architect-handoff.md   Architect
  │
  ▼  ★ owner gate: approve the Solution handoff task table
  │
[Stage 3 — Implementation]            dispatch by dependency wave   Lead → Engineer × N
  │
  ▼
[Stage 3b — Integration Wave]         mandatory post-wave integration pass   Lead → Engineer
  │
  ▼  ★ owner gate: run Reviewer?
  │
  ├─ no / skip ─────────────────────────────────────┐
  │                                                  │
  └─ yes ─→ [Stage 4 — Reviewer (optional)]   optional quality gate   Reviewer
                   │                                  │
                   ▼ ◄─────────────────────────────────┘
[Stage 5 — Block closeout]            write block-summary.md                    Lead
  │
  ├─ rework needed → [Stage 5R — Block rework decision]                        Lead
  │                    ├─ implementation-rework → re-dispatch original TASK-NNN with current architect handoff
  │                    └─ architecture-rework → update current ads-platform-architect-handoff.md, approve, then dispatch follow-up tasks
  ├─ blocks remain → choose next active block → back to [Stage 1b — PRD Analyst Phase 2]
  └─ all blocks done / done
       │
       ▼
[Stage 6 — Knowledge candidates]      generate knowledge-candidates.md          Lead
  │
  ▼  ★ owner gate: persist reusable knowledge?
  │
end
```

> ★ marks an owner-confirmation gate; the flow pauses here until the owner gives
> instructions.

## 5. Quick Start

### 5.1 Prerequisites (MCP/SKILL)

Ads Platform agents may need to read Confluence PRDs/TDs, Google Docs/Sheets,
Transify documents, and RAP API schemas. For requirements that depend on
external documents, prepare the following tools before running the full
workflow.

#### 5.1.1 RAP and PAS MCP: `pas-mcp`

Use `pas-mcp` when agents need MCP tools such as
`get_confluence_page`, `get_rap_api_repo_version_name`,
`get_rap_api_repository_by_id`, and `get_rap_api_json_schema`.

For Codex, the local MCP server configuration is usually located at:

```text
~/.codex/config.toml
```

For Claude Code, the equivalent configuration is usually located at:

```text
~/.claude/settings.json
```

The MCP server should register `@shopee/pas-mcp` and configure the required
environment variables:

```toml
[mcp_servers.pas-mcp]
command = "npx"
args = ["-y", "@shopee/pas-mcp@latest"]

[mcp_servers.pas-mcp.env]
RAP_ACCESS_TOKEN = "your_default_rap_openapi_token"
SPACE_TOKEN = "your_space_user_token"
CONFLUENCE_TOKEN = "your_confluence_personal_access_token"
GITLAB_TOKEN = "your_gitlab_personal_access_token"
SELLER_CENTER_RAP_TOKEN = "optional_repo_specific_rap_token"
PAID_ADS_ADMIN_RAP_TOKEN = "optional_repo_specific_rap_token"
```

Claude Code should write the same values under `mcpServers`:

```json
{
  "mcpServers": {
    "pas-mcp": {
      "command": "npx",
      "args": ["-y", "@shopee/pas-mcp@latest"],
      "env": {
        "RAP_ACCESS_TOKEN": "your_default_rap_openapi_token",
        "SPACE_TOKEN": "your_space_user_token",
        "CONFLUENCE_TOKEN": "your_confluence_personal_access_token",
        "GITLAB_TOKEN": "your_gitlab_personal_access_token",
        "SELLER_CENTER_RAP_TOKEN": "optional_repo_specific_rap_token",
        "PAID_ADS_ADMIN_RAP_TOKEN": "optional_repo_specific_rap_token"
      }
    }
  }
}
```

Create RAP tokens from the RAP repository detail page:

```text
Settings -> Integration -> OpenAPI
```

`SPACE_TOKEN` can be obtained from `https://space.shopee.io/` via
profile -> copy user token. `RAP_ACCESS_TOKEN` is the recommended default token
name; the older `ACCESS_TOKEN` configuration still works as a fallback, but new
setups should use `RAP_ACCESS_TOKEN`.

When a RAP tool must use a repo-specific token, pass
`rapAccessTokenName`, for example:

```text
rapAccessTokenName: "SELLER_CENTER_RAP_TOKEN"
```

After editing the MCP configuration, restart the MCP client. Do not commit
token values or generated local MCP caches to the repository.

#### 5.1.2 Google Workspace: `sp-gws`

Use `sp-gws` when the workflow needs to read Google Docs or Google Sheets, such
as Transify sheets referenced in PRD handoffs.

Install or enable the skill:

```bash
npx --yes sra-skills skill add sp-gws
```

Install the `gws` CLI:

```bash
brew install googleworkspace-cli
```

If Homebrew is not available, you can also use:

```bash
npm install -g @googleworkspace/cli
```

The `gws` configuration directory is:

```text
~/.config/gws/
```

Authenticate with the scopes required by this agent team:

```bash
gws auth login -s drive,docs,sheets
```

If OAuth credentials are missing, create a Google Cloud OAuth Client with
application type `Desktop app` and save it as:

```text
~/.config/gws/client_secret.json
```

Verify access:

```bash
gws --version
gws auth status
gws drive files list --params '{"pageSize": 3}'
```

#### 5.1.3 Figma MCP

The development workflow needs the `ads-platform-figma-inspect` skill to obtain
UI styles from Figma nodes. Configure the MCP tool below to make this skill
available. Do not use the official Figma plugin.

**Claude:**

Add the following to `~/.claude/.mcp.json`:

```json
{
  "mcpServers": {
    "Framelink_Figma_MCP": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "figma-developer-mcp",
        "--figma-api-key=figd_fyqC1jGSaMuu8ukZgXg0Idj5WTP9q7ED_uKfhPto",
        "--stdio"
      ],
      "env": {}
    }
  }
}
```

**Codex:**

Add the following to `~/.codex/config.toml`:

```text
[mcp_servers.Figma-Context-MCP]
command = "npx"
args = [
  "-y",
  "figma-developer-mcp",
  "--figma-api-key=figd_fyqC1jGSaMuu8ukZgXg0Idj5WTP9q7ED_uKfhPto",
  "--stdio"
]
enabled = true
```

This Figma API key is from `@liqi.shi`. If you encounter a 404 error when
opening a Figma node link, it usually means you do not have permission. Contact
`@liqi.shi` to resolve access.

### 5.2 Recommended Prompts In Codex Or Claude

**Do not send the PRD and detailed requirement body directly to a random agent
in the first message. First explicitly tell the current session to act as
`ads-platform-lead`; then let the lead orchestrate sub agents for the rest of
the delivery workflow.**

Example first prompt:

```text
Please play the role declared by ads-platform-lead and orchestrate the callable sub agents to complete the follow-up task.
```

After the session has accepted the lead role, provide the goal, PRD link, issue
link, or a short requirement description. The Lead should first run intake,
create the artifact directory, and dispatch PRD Analyst, rather than parsing
all details directly inside the lead conversation.

Example second prompt (Goal Intake stage):

```text
PRD: [PRD link/local file path/plain description]
Additional constraints, for example: only focus on the Requirement section, only focus on PC-side changes
```

It is **not recommended** to provide both PRD and TD in the same prompt during
this stage, because it may affect the agent's intent judgment and cause it to
incorrectly constrain requirement scope to only what is described in the TD. If
a TD document exists, such as an API TD, it is better to add it as supplementary
context in `prd-summary.md` during Stage 1a, or provide it to Architect as
additional guidance in Stage 2, for example:

```text
Approved to enter the next stage.
Additional context for the API part: [TD link]. Refer to [a specific section] in this document for API changes, and do not design API changes on your own.
```

<details>
If the user provides both a PRD and a TD during Goal Intake, the downstream
workflow should follow these rules by default:

- `ads-platform-analyst` still uses the PRD as the main basis for requirement analysis and block splitting.
- The user-provided TD is only supplementary design context for the analyst and should not override or extend the PRD requirement baseline.
- `ads-platform-architect` should reference the existing design in the TD when generating both the TD draft and the solution handoff. If it conflicts with the confirmed PRD or later user decisions, the conflict must be surfaced explicitly rather than silently overridden.
</details>

### 5.3 Best Practices

#### 5.3.1 Spend Time Checking The AI-Defined Plan

Keep one principle in mind: AI is only an assistant, while the human remains
responsible for the final result. The agent workflow is designed to make the
process standardized and traceable, but it cannot guarantee that AI fully
understands PRD intent or produces code exactly as expected. Before the
Engineer role starts coding, all handoff documents are already part of the
final execution plan, so review these planning artifacts to ensure they match
your expectations.

In most cases, you do not need to review every agent handoff file in full.
Focus on the key parts that determine downstream scope and code work, so later
tasks do not drift away from your intent.

- `prd-summary.md` (the PRD summary generated by Analyst, requires **special attention**)
  Check the requirement summary, involved projects, and block split to confirm that AI identified the correct projects to change, and adjust the block split when needed. Prune the PRD according to your task scope, for example by removing BE requirements, Tracking requirements, or any work that should not be implemented in this run. Add context you want to emphasize or that AI is unlikely to infer correctly, such as technical constraints or special business logic. If UI changes are involved, provide the most precise possible Figma node links for the relevant requirements in the requirement table, using the **smallest** Figma node covering that requirement rather than the entire page.
- `prd-analysis-handoff.md` (the stage handoff generated by Analyst)
  Review the `Active-block Requirements` section and confirm that the current block's requirement list matches your expectation.
- `td-*.md` (the TD document generated by Architect when the user chooses TD mode)
  When asking Architect to generate a TD, you can provide more guidance through the prompt, such as TD scope or implementation constraints. Review carefully whenever the TD touches APIs, shared components, `pas-common`, data models, backend dependencies, or migration/compatibility behavior.
- `ads-platform-architect-handoff.md` (the stage handoff generated by Architect)
  This is the **final execution plan**. Review it as thoroughly as possible, including changed files, task list, and Transify key mapping results. If the solution does not match your expectation, you can ask the agent to revise it directly or adjust it manually.

**Any plan deviation from your expectation will cause later Engineer output to
deviate as well. Do not hesitate to spend time on planning, otherwise you may
spend more time and effort fixing issues later.**

#### 5.3.2 How To Adjust Things After Development Ends

When a block has completed but the result still does not match your
expectation, do not treat it as an ad hoc “ask the AI to tweak it again”
request. Treat it as a formal decision inside **Stage 5R (Block rework decision)**,
and decide what level of rework you actually need:

1. `implementation-rework`
   - Use this when the Architect plan is still correct, but the Engineer code
     implementation is not.
   - Keep the current `ads-platform-architect-handoff.md` unchanged and
     continue using the original `TASK-NNN` definitions already recorded there.
     Re-dispatch only the affected original tasks.
   - This rework is an in-place fix based on the **current code state**. It is
     not a fresh re-implementation of the task from scratch.

2. `architecture-rework`
   - Use this when the Architect task split, change boundary, implementation
     path, or overall solution itself needs to change.
   - Lead should route the flow back to the Architect handoff stage, update the
     existing `ads-platform-architect-handoff.md` in place, append
     `Implementation Iteration History`, and generate new follow-up tasks.
     After the owner re-confirms the updated handoff, dispatch the new Engineer
     tasks.
   - This rework must not keep reusing old tasks to carry new plan semantics.
     New or redefined work should be represented explicitly by new follow-up
     tasks.

During rework, always treat the current `ads-platform-architect-handoff.md` as
the **only authoritative plan artifact** for that block:

- In `implementation-rework`, the handoff stays unchanged and the original task
  definition continues to apply.
- In `architecture-rework`, the same handoff file is updated in place with
  iteration history and new follow-up tasks.

If you only tell the AI “please adjust this again” without making the rework
type explicit, the workflow is likely to drift:

- code implementation may diverge from the Architect plan
- old task boundaries may silently expand
- Reviewer may be unable to tell whether the original task was wrong or whether
  the plan itself has changed

For that reason, post-development adjustments should usually be initiated
through the Lead main session, so Stage 5 can perform a formal close / rework
split instead of having multiple sub-sessions patch things informally.

**Use judgment:** if you only need a tiny, non-semantic implementation change
for one task, such as naming or style cleanup, you may also talk directly to
that task's Engineer sub-agent and ask for the adjustment there.

#### 5.3.3 How To Restart From An Earlier Stage

The Agent team execution process uses `run-state.json` to maintain the current execution
state. After the entire process is completed, if significant deviations are found in
certain stages, subsequent modifications need to be abandoned and the process started
anew from a previous stage. The following operations can be referred to:

1. Find the cache file you are executing this time in `<projects-root>/.tmp/<run-slug>/`, and delete 
   the intermediate products of the stage you need to discard (such as the handoff file of Architect/Engineer).
2. Undo any modifications to the code repository (if any).
3. There are two ways to require the Agent Team to start over from a certain stage:
   - (Recommended) Use the native branching feature of the AI client (Codex/Claude) to cut out a new session
     after replying to a certain message.
   - Request the Lead to reset 'run-state.json' back to a certain stage (such as the end of the Analyst stage)
     through the Prompt, and start a new session via prompt like: "play the role defined by ads-platform-lead,
     Resume the execution task from `<file-path-of-run-state-json>`".

#### 5.3.4 Talk Directly To A Sub Agent

Using the GUI version of the AI client is recommended over the CLI version. In
Agent Team execution mode, you may need to switch between sessions frequently
to inspect sub-agent reasoning and execution, and in some cases talk directly
to a sub agent. The GUI client makes these operations easier.

In normal use, you should talk to the Main Agent (Lead), and let it invoke sub
agents and dispatch work. However, this does increase time and token cost. When
it does not materially disrupt the main workflow, you can choose to talk
directly to a sub agent, for example in these scenarios:

- You need to adjust `prd-summary.md` or a handoff file from a certain stage.
- A sub agent's implementation does not match expectations, and you want to
  debug by talking to that sub agent directly.

## 6. Inspecting Execution Artifacts

The Agent Team workflow is designed to be standardized and traceable. It stores
all intermediate artifacts produced during execution under
`<projects-root>/.tmp/<run-slug>/`. The `<run-slug>` directory format is
`date-time-requirement-summary`, so you can quickly locate the artifacts for a
specific run.

Run-level artifacts usually include:

```text
prd-summary.md
decision-log.md
knowledge-candidates.md
transify/*.json
```

Each active block writes files under:

```text
<projects-root>/.tmp/<run-slug>/block-<NNN>-<block-slug>/
```

Block-level artifacts usually include:

```text
prd-analysis-handoff.md
td-<feature-slug>-<YYYY-MM-DD>.md
ads-platform-architect-handoff.md
ads-platform-engineer-<TASK-NNN>-handoff.md
ads-platform-reviewer-handoff.md
block-summary.md
```

You can audit the agent interaction process through these historical artifacts:

- Read `decision-log.md` to inspect manual approvals, edits, skipped review
  decisions, scope changes, and answers to open questions.
- Read `Appendix — PRD Source Evidence` in `prd-analysis-handoff.md` to confirm
  that later stages used the source excerpts for the current active block,
  rather than the full raw PRD.
- Read each handoff frontmatter to inspect `gate_status`, `open_questions`,
  `risks`, `retry_request`, and downstream routing information.
- Treat `ads-platform-architect-handoff.md` as the only authoritative rework
  plan artifact for a block. For `implementation-rework`, the handoff stays
  unchanged and the original task definition remains authoritative. For
  `architecture-rework`, the same handoff file is updated in place with
  `Implementation Iteration History` and new follow-up tasks.
- Read `block-summary.md` after a block is completed to understand completed
  work, residual risks, rework history, and follow-up items before starting the
  next block.
