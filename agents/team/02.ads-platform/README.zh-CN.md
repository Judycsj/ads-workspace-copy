# Ads Platform Agent Team 使用指南

本文说明如何在 Codex 或 Claude 中使用 Ads Platform FE agent team、每个角色负责什么，以及一次需求交付过程中哪些产物需要重点 review。

## 1. 基础概念

| 概念 | 含义 |
| --- | --- |
| Agent | 一个 AI 员工——具备角色 prompt、工具权限和输出 contract，专注做好一种工作（如 PRD 分析、方案规划、实现或 review）。 |
| Agent Team | 一个 AI 团队——一组共享同一交付流程的 agents，由 Main Agent 编排、sub 分工，协作完成 FE 需求的端到端交付（从 goal intake 到实现、可选 review，再到知识候选沉淀）。 |
| Main Agent | 负责编排完整流程的 agent。它创建 artifact 目录、执行人工确认 gate、记录决策，并派发 sub agents。 |
| Sub Agent | 由 Main Agent 在某个阶段调用的 agent。owner 通常应该先和 Main Agent 对话；Main Agent 会根据阶段、scope 和 artifact，把合适的上下文传给对应 sub agent。 |
| Block | PRD 或需求集合中的一个有边界的交付单元。Block 是 PRD Phase 2、TD/Solution 规划、实现、可选 review 和 `block-summary.md` 的处理单位。多区域 PRD 通常应按 block 逐个处理。 |
| Wave | 可以并行执行的一组 implementation tasks，因为这些 task 的依赖已经满足。Solution Architect 会根据 `TASK-NNN` 依赖图定义 dispatch waves。 |

**补充说明：**

1. **Block 的划分依据**：以需求本身的业务边界和交付边界为主，通常按独立页面/路由、独立业务项目、独立流程或彼此弱耦合的功能域来切分；如果需求之间共享核心上下文且需要一起决策，也应优先放在同一个 Block 内处理。
2. **Block 和 Wave 的区别和关系**：Block 是需求分析与交付编排的上层单位，决定“先处理哪一块需求”；Wave 是实现阶段的并行执行单位，决定“哪些任务可以一起做”。一个 Block 通常会对应一个或多个 Wave，但 Wave 只在单个 Block 内部按依赖关系切分，不跨 Block 运行。

## 2. 角色分工

| Role                     | Agent 类型   | 职责                                                                                                               | 主要输出                                                                              |
| ------------------------ | ---------- | ---------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `Owner`                  | Human      | 人类负责人，对话者，提供目标；在各人工确认 gate 审阅 / 编辑 / 放行；对 PRD 剪枝、选 active block；决定是否生成 TD / 运行 Reviewer；确认 task table 与产物。       | 人工确认与决策（无独立文件；决策由 Lead 记入 `decision-log.md`）                                      |
| `ads-platform-lead`      | Main Agent | 编排者，编排完整流程，创建 artifact 目录，执行 owner gate，记录决策，并派发 sub agents。                                                     | `decision-log.md`、`block-summary.md`、`knowledge-candidates.md`                    |
| `ads-platform-analyst`   | Sub Agent  | 分析师，两阶段分析输入：run 级 PRD summary 和 active-block PRD handoff。                                                      | `prd-summary.md`、`prd-analysis-handoff.md`、`tracking-bridge.json` |
| `ads-platform-architect` | Sub Agent  | 架构师，在 TD mode 下生成 TD 文档；在 handoff mode 下梳理 implementation impacts、Transify/i18n 上下文、task table 和 dispatch waves。 | `td-*.md`、`ads-platform-architect-handoff.md`，必要时输出 `transify/*.json`             |
| `ads-platform-engineer`  | Sub Agent  | 工程师，每次执行一个 `TASK-NNN`，并写入简洁 implementation handoff。                                                              | `ads-platform-engineer-<TASK-NNN>-handoff.md`                                     |
| `ads-platform-reviewer`  | Sub Agent  | 评审员，可选质量 gate，检查需求覆盖、代码质量、lint/type-check 证据和 retry request。                                                     | `ads-platform-reviewer-handoff.md`，可选 `review-coverage-full.md`                   |

## 3. 层级划分

设计采用三层模型：**Agent → Skill → Doc**。

```text
Agent 层          定义"谁来做什么"，角色职责与交接协议
  │
  ↓ 调用
Skill 层          定义"某类能力如何执行"，可复用的执行单元
  │
  ↓ 按需 Read
Doc 层            提供"执行所需的知识"，agent 运行时主动加载
```

三层各司其职，互不越界：Agent prompt 不承载知识，Skill 不承载完整流程编排，Doc 层只提供事实，不做决策。

### 3.1 Agent 层

Agent 层定义"谁来做什么"。本 team 的每个 agent 是 `agents/team/02.ads-platform/` 下的一个自描述 markdown 文件，各专注一种工作、用 frontmatter 声明工具与能力，不承载业务知识。

```text
agents/team/02.ads-platform/
├── ads-platform-lead.md
├── ads-platform-analyst.md
├── ads-platform-architect.md
├── ads-platform-engineer.md
└── ads-platform-reviewer.md
```

### 3.2 Skill 层

Skill 层只包含**能力型 skill**，定义"某类能力如何执行"。单个 skill 只负责一类稳定执行能力，不承担完整工作流编排职责；知识型内容不包装为 skill。这些 skill 不由 agent 直接编排，而是在实现阶段由 `ads-platform-engineer` 按任务的 `skill_hint` 与 Skill Invocation Decision Table 调用（`ads-platform-architect` 在生成 task 时负责匹配并写入 `skill_hint`）。

**codegen（代码生成）系列**——`ads-platform-codegen-*`，覆盖 Ads Platform 前/后端最常见的几类需求形态：

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

### 3.3 Doc 层

Doc 层为 agent 提供运行时所需的项目知识，agent 通过 Read 工具**按需加载**、不预加载进 prompt。知识存放在 `docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/knowledge-base/`（运行时经 `<projects-root>/.symlinks/docs` 访问），核心是**两级 `index.yml` 路由 + 领域知识 markdown**：

```text
docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/knowledge-base/
├── index.yml                           顶层路由入口
├── pas-common/index.yml
├── product-ad-creation/                feature-flow 领域
│   ├── index.yml                       领域路由：primary doc + companions
│   ├── creation.md                     主流程文档
│   ├── creation-product-selection.md   companion
│   └── creation-bidding-strategy.md    companion
├── product-ad-detail/
│   ├── index.yml
│   └── detail.md
└── rewards-center/                     cross-project 功能域
    ├── index.yml
    ├── rewards-program-landscape.md
    ├── rewards-data-flow-main-path.md
    ├── rewards-api-details-and-contracts.md
    ├── rewards-domain-models-and-enums.md
    ├── rewards-tracking-events-map.md
    └── ……
```


> 相邻的 `contracts/`（handoff / task-item / td 模板）与 `rules/`（claude / codex / common）同在 `ai-agent/` 下，但分别属于"交接协议"与"运行规则"，不属于知识层本身。

### 3.4 Lead 会话状态

为了解决长会话中的阶段漂移和断点恢复问题，本 team 采用一套持久化的 lead 会话状态机制，核心文件是：

- `<artifact_dir>/run-state.json`

配套的运行时模板位于：

- `docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/contracts/run-state-template.json`
- `docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/contracts/run-state-transition-template.md`
- `docs/team/02.ads-platform/00.ads-platform-fe/ai-agent/contracts/resume-run-template.md`

运行时职责划分如下：

- `run-state.json` 记录单次 run 的当前 stage、stage status、active block、已批准产物、owner 决策、dispatch 历史和下一步动作。
- `ads-platform-lead.md` 负责约束 turn-start 状态检查、subagent-only stage 和严格的恢复行为。
- `contracts/run-state-template.json` 定义 `run-state.json` 的初始结构。
- `contracts/run-state-transition-template.md` 定义每次阶段切换时哪些状态字段必须一起更新。
- `contracts/resume-run-template.md` 定义新 lead 会话恢复历史 run 时的标准入口 prompt 和响应格式。

维护边界：

- 运行时硬约束放在 `ads-platform-lead.md`。
- 可复用的状态与恢复模板放在 `contracts/`。
- 一旦 run 已开始，`ads-platform-lead` 不应再依赖对话记忆判断当前进度，而应先读取 `run-state.json`，再按状态机决定唯一允许的下一步动作，并把每次阶段切换持久化回状态文件。

## 4. 流程

下表按 `ads-platform-lead.md` 的权威 Stage 划分，列出**单个 active block** 的端到端路径（阶段编号与下方流程图一一对应）。标 ★ 的入口条件为人工确认 gate，须 owner 放行后才进入该阶段。

| 阶段                                | 入口条件                                                | 角色                                   | 做什么事 / 职责                                                                 | 产出物                                                              |
| --------------------------------- | --------------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Stage 0 — Goal Intake             | owner 提供了目标                                             | `ads-platform-lead`                  | 确认目标形态（input type / 语言 / 可执行性），初始化 run artifact 目录与决策日志                   | run artifact 目录、`decision-log.md`                                |
| Stage 1a — PRD Analyst Phase 1    | Intake 完成、目标可执行                                 | `ads-platform-analyst`               | 解析 PRD，或将纯 Prompt 描述归一化为最小 run 级需求摘要与 block split                         | `prd-summary.md`                                                 |
| Stage 1b — PRD Analyst Phase 2    | ★ owner 已 review / 编辑 `prd-summary.md` 并选定 active block | `ads-platform-analyst`               | 针对 active block 写单文件分析 handoff（内含 source appendix），初始化 tracking skeleton               | `prd-analysis-handoff.md`、`tracking-bridge.json` |
| Stage 1c — Tracking + TD 决策 Gate | ★ owner 一次性确认三个 gate：批准 PRD Phase 2 handoff、确认 `tracking_mode`、确认是否需要 TD | `ads-platform-lead`（+ Owner 决策）      | 展示 PRD Phase 2 handoff，收集合并后的 owner 决策包，并将流程分流到 TD mode 或 architect handoff mode | owner 决策包（记入 `decision-log.md`） |
| Stage 2a — Architect TD mode      | owner 选择 TD 生成 = `yes`                                  | `ads-platform-architect`             | 生成 active block TD 草稿；★ 生成后必须经 owner 确认 / 编辑才能继续                               | `td-<feature-slug>-<YYYY-MM-DD>.md`                              |
| Stage 2b — Architect handoff mode | owner 选择 TD = `no`，或已确认生成的 TD                           | `ads-platform-architect`             | 梳理 implementation impacts、解析 Transify/i18n、生成 `TASK-NNN` 与 dispatch waves | `ads-platform-architect-handoff.md`、必要时 `transify/*.json`        |
| Stage 3 — Implementation          | ★ owner 已确认 Solution handoff task table、至少有一个 task      | `ads-platform-engineer` × N（Lead 编排） | 按依赖 wave 并行派发 implementers，逐个执行 `TASK-NNN`                                | `ads-platform-engineer-<TASK-NNN>-handoff.md`                    |
| Stage 3b — Integration Wave       | 当前 engineering pass 的普通 implementation waves 全部返回 | `ads-platform-engineer`（Lead 编排） | 强制执行一次收尾 integration pass，检查并修复 wave 间整合问题 | integration wave 产出的标准 engineer handoff |
| Stage 4 — Reviewer（可选）            | Stage 3b integration wave 已完成、★ owner 确认运行 Reviewer                  | `ads-platform-reviewer`              | 可选质量 gate：检查需求覆盖与代码质量，必要时发 `retry_request`                                | `ads-platform-reviewer-handoff.md`、可选 `review-coverage-full.md`  |
| Stage 5 — Block closeout          | implementers 完成、Reviewer 已运行或被跳过                    | `ads-platform-lead`                  | 写 block 完结摘要，更新 `prd-summary.md` 的 `completed_blocks`                     | `block-summary.md`                                               |
| Stage 5R — Block rework decision  | ★ owner 明确表示已完成 block 仍需调整                              | `ads-platform-lead`（+ Owner 决策）      | 决定走 `implementation-rework` 还是 `architecture-rework`；以当前 `ads-platform-architect-handoff.md` 作为唯一权威返工方案载体重新派发后续阶段 | 更新后的实现 handoff，或更新后的 `ads-platform-architect-handoff.md` 与 follow-up tasks |
| Stage 6 — Knowledge candidates    | 所选 block 全部完成，或 owner 停止批次                               | `ads-platform-lead`                  | 汇总可复用知识候选，★ 人工确认是否沉淀入库                                                    | `knowledge-candidates.md`                                        |

上述各阶段是**单个 active block** 的端到端路径。分两种情况：

- **单 Block（正常路径）**：PRD 只涉及一个业务域，或输入本身是 direct prompt 时，**Stage 1a（PRD Analyst Phase 1）** 仍然会先写出 `prd-summary.md`，但默认不再继续拆分，随后这个 block 从 **Stage 0** 走到 **Stage 6**。
- **多 Block 顺序执行**：PRD 跨多个业务项目 / 页面 / 功能域时，**Stage 1a** 会做 **block split** 拆成多个 block（记录在 `prd-summary.md`）。一次只选一个 active block，完整走 **Stage 1b → Stage 1c → Stage 2a/2b → Stage 3 → Stage 3b → Stage 4/5**。在 **Stage 5（Block closeout）** 后，owner 可以先选择一个可选的 **Stage 5R（Block rework decision）** 来返工当前 block。若不需要返工且仍有未完成 block，Lead 再询问是否继续——选下一个 block 后**从 Stage 1b（PRD Analyst Phase 2）重新进入**（沿用已有 `prd-summary.md`，无需重跑 Stage 1a），逐个 block 重复，直到全部 block 完成，才在 **Stage 6（Knowledge candidates）** 生成 `knowledge-candidates.md`。默认按 block 顺序逐个完成、不并行多个 block。

流程图：

```text
owner 目标
  │
  ▼
[Stage 0 — Goal Intake]               接受任务目标，初始化 run artifact 目录     Lead
  │
  ▼
[Stage 1a — PRD Analyst Phase 1]      写入 prd-summary.md（摘要 + block split） Analyst
  │
  ▼  ★ 人工确认：review summary，选择 active block
  │
[Stage 1b — PRD Analyst Phase 2]      写入 prd-analysis-handoff.md   Analyst
  │
  ▼
[Stage 1c — Tracking + TD 决策 Gate]   ★ 批准 PRD handoff + 确认 tracking mode + 确认是否需要 TD   Lead
  │
  ├─ 是 ─→ [Stage 2a — Architect TD mode]   写入 td-*.md             Architect
  │              │
  │              ▼  ★ 人工确认：确认 / 编辑 TD（生成则必经）
  │              │
  ▼ ◄────────────┘
[Stage 2b — Architect handoff mode]   写入 ads-platform-architect-handoff.md   Architect
  │
  ▼  ★ 人工确认：确认 Solution handoff task table
  │
[Stage 3 — Implementation]            按依赖 wave 并行派发          Lead → Engineer × N
  │
  ▼
[Stage 3b — Integration Wave]         强制收尾 integration pass     Lead → Engineer
  │
  ▼  ★ 人工确认：是否运行 Reviewer？
  │
  ├─ 否 / skip ─────────────────────────────────────┐
  │                                                 │
  └─ 是 ─→ [Stage 4 — Reviewer（可选）]   可选质量 gate          Reviewer
                  │                                  │
                  ▼ ◄────────────────────────────────┘
[Stage 5 — Block closeout]            写入 block-summary.md                     Lead
  │
  ├─ 需要返工 → [Stage 5R — Block rework decision]                             Lead
  │               ├─ implementation-rework → 保持当前 architect handoff 不变，重新派发原 TASK-NNN
  │               └─ architecture-rework → 原地更新 ads-platform-architect-handoff.md，确认后派发新的 follow-up tasks
  ├─ 还有未完成 block → 选下一个 active block → 回到 [Stage 1b — PRD Analyst Phase 2]
  └─ 全部 block 完成 / done
       │
       ▼
[Stage 6 — Knowledge candidates]      生成 knowledge-candidates.md             Lead
  │
  ▼  ★ 人工确认：是否沉淀可复用知识入库
  │
结束
```

> ★ 为人工确认点，流程在此暂停，等待 owner 指令后才继续推进。

## 5. 快速开始

### 5.1 前置准备 (MCP/SKILL)

Ads Platform agents 可能需要读取 Confluence PRD/TD、Google Docs/Sheets
Transify 文档，以及 RAP API schema。对于依赖外部文档的需求，在运行完整流程前请先准备下面的工具。

#### 5.1.1 RAP 和 PAS MCP：`pas-mcp`

当 agents 需要使用 `get_confluence_page`、`get_rap_api_repo_version_name`、
`get_rap_api_repository_by_id`、`get_rap_api_json_schema` 等 MCP 工具时，使用
`pas-mcp`。

Codex 的本地 MCP server 配置通常位于：

```text
~/.codex/config.toml
```

Claude Code 的对应配置通常位于：

```text
~/.claude/settings.json
```

MCP server 需要注册 `@shopee/pas-mcp`，并配置必要的环境变量：

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

Claude Code 使用 `mcpServers` 写入同样的值：

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

RAP token 从 RAP repository detail page 创建：

```text
Settings -> Integration -> OpenAPI
```

`SPACE_TOKEN` 从 `https://space.shopee.io/` 的 profile -> copy user token 获取。
`RAP_ACCESS_TOKEN` 是推荐的默认 token 名；旧配置 `ACCESS_TOKEN` 仍可作为
fallback 使用，但新配置应使用 `RAP_ACCESS_TOKEN`。

当某个 RAP 工具必须使用 repo-specific token 时，传入 `rapAccessTokenName`，例如：

```text
rapAccessTokenName: "SELLER_CENTER_RAP_TOKEN"
```

修改 MCP 配置后需要重启 MCP client。不要把 token 值或生成的本地 MCP cache 提交到仓库。

#### 5.1.2 Google Workspace：`sp-gws`

当流程需要读取 Google Docs 或 Google Sheets（例如 PRD handoff 中引用的 Transify
sheet）时，使用 `sp-gws`。

安装或启用 skill：

```bash
npx --yes sra-skills skill add sp-gws
```

安装 `gws` CLI：

```bash
brew install googleworkspace-cli
```

如果没有 Homebrew，也可以使用：

```bash
npm install -g @googleworkspace/cli
```

`gws` 的配置目录为：

```text
~/.config/gws/
```

按本 agent team 需要的 scope 进行授权：

```bash
gws auth login -s drive,docs,sheets
```

如果缺少 OAuth credentials，在 Google Cloud 创建 application type 为
`Desktop app` 的 OAuth Client，并保存为：

```text
~/.config/gws/client_secret.json
```

验证访问：

```bash
gws --version
gws auth status
gws drive files list --params '{"pageSize": 3}'
```

#### 5.1.3 Figma MCP

开发流程需要通过 ads-platform-figma-inspect SKILL 来获得 Figma 节点的 UI 样式。请配置下边的 MCP 工具来使此 SKILL 可用。**注意，不要使用 Figma 官方插件。**

**Claude:**

在 `~/.claude/.mcp.json` 中写入以下内容：

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

在 `~/.codex/config.toml` 中新增以下内容：

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

此 Figma API Key 来自 @liqi.shi，在访问 Figma 节点链接时如果遇到 404 错误（通常因为没有权限），请联系 @liqi.shi 解决。


### 5.2. 在 Codex 或 Claude 中的推荐 Prompt

**不要在第一条消息里直接把 PRD 和详细需求正文发给某个随机 agent。第一步应该显式声明让当前会话扮演 `ads-platform-lead`；然后由 lead 编排 sub agents 完成后续交付流程。**

第一条 prompt 示例：

```text
你来扮演 ads-platform-lead 所声明的角色, 编排可调用的子 agent 来完成后续的任务。
```
当会话接受 lead role 后，再提供 goal、PRD link、issue link 或简短需求描述。Lead 应该先做 intake、创建 artifact 目录，并派发 PRD Analyst，而不是在 lead 对话里直接解析所有细节。

第二条 prompt 示例（Goal Intake 阶段）：

```text
PRD: [PRD 链接/本地文件路径/纯描述]
其他限定词如：只关注文档的 Requirement 章节、只关注 PC 端改动
```

**不推荐**此阶段在同一条 Prompt 中同时提供 PRD 和 TD 文档，可以会影响 Agent 的意图判断，导致 Agent 错误地将需求范围限定在 TD 描述的内容之内。
如果存在 TD 文档（如 API TD），建议在 Stage 1a 阶段生成 `prd-summary.md` 中补充说明，或在进入 Stage 2 时为 Architect 提供 TD 的额外信息，如：

```text
批准进入下一阶段。
关于 API 部分的额外补充：[TD 链接]，参考此文档的【某个章节】进行 API 修改，不要自行设计 API 修改方案。
```

<details>
如果用户在 Goal Intake 阶段同时提供了 PRD 和 TD，后续流程默认按以下规则执行：

- `ads-platform-analyst` 仍以 PRD 作为需求分析和 block 拆分的主依据。
- 用户提供的 TD 只作为 analyst 的补充设计上下文，不应覆盖或扩写 PRD 需求基线。
- `ads-platform-architect` 在生成 TD draft 和 solution handoff 时，都需要参考该 TD 中已有的设计方案；若其与已确认 PRD 或后续用户决策冲突，必须显式暴露冲突而不是静默覆盖。
</details>

### 5.3 最佳实践

#### 5.3.1 投入精力检查 AI 指定的计划

时刻保持一个观念：AI 只是辅助，为最终结果负责的始终是人类。Agent 的整体流程编排旨在让流程规范化和可追溯，但无法保证 AI 可以完全理解 PRD 意图并且按照人类预期产出代码。
在 Engineer 角色入场进行代码开发之前，所有的 handoff 文档都是最终实施计划的一部分，请关注这些计划文件以确保它们符合你的预期。

通常情况下，你不需要完整检查每一个 agent handoff 文件。请关注决定后续 scope 和代码工作的关键部分，确保后续任务不会偏离你的预期。

- `prd-summary.md`（由 Analyst 生成的 PRD 总结文档，需要**重点**人工检查）
  - 检查需求摘要、involved projects、block split，确定 AI 分析出正确的需要的修改的项目，根据需要调整 block 拆分。
  - 根据你的任务范围对 PRD 进行“剪枝”，例如移除 BE 需求、Tracking 需求，或其他本次不应该实现的工作。
  - 补充你想要强调或者 AI 不知道/难以正确推理的上下文信息，例如某些技术要求、特殊的业务逻辑，这些都能极大降低 AI 产出的不确定性，避免重复返工。
  - 如果涉及 UI 改动，在需求表格中为需要进行 UI 改动的需求提供尽可能精确的 Figma 节点链接（包含了此部分需求的**最小** Figma 节点，而非整个页面）。
- `prd-analysis-handoff.md`（由 Analyst 生成的阶段交付文档）
  - 检查 `Active-block Requirements` 部分，确认当前 block 的需求列表是否符合你的预期。
- `td-*.md`（当用户选择需要 TD 时，由 Architect 生成的 TD 文档）
  - 在要求 Architect 生成 TD 时，你可以通过 prompt 提供更多指引，例如 TD 范围、技术实现约束等。
  - 当 TD 涉及 API、共享组件、`pas-common`、数据模型、后端依赖或迁移/兼容行为时，请仔细 review。
- `ads-platform-architect-handoff.md` (由 Architect 生成的阶段交付文档)
  - 此文档是**最终实施计划**，请尽可能详细审查此文档，包括变更文件、任务列表、Transify key 映射结果。
  - 如果方案不符合你的预期，你可以直接要求 Agent 进行修改或手动调整。

**任何和你预期不符的计划偏差，都会导致后续 Engineer 输出不符合你预期的修改。请不要吝惜你的时间在计划制定上，否则可能将在后续花费更多的时间和精力进行后续调整。**

#### 5.3.2 如何在开发结束后进行后续调整

当某个 block 完成后，如果你发现结果不符合预期，不要把这件事理解成“随手再让 AI 改一下”，而应该把它当成 **Stage 5R（Block rework decision）** 的正式决策。判断你需要 AI 进行哪种程度的返工：

1. `implementation-rework`
   - 适用场景：Architect 方案本身仍然正确，只是 Engineer 的代码实现不符合预期。
   - 处理方式：保持当前 `ads-platform-architect-handoff.md` 不变，继续以其中已有的原始 `TASK-NNN` 定义为准，重新派发受影响的原 task。
   - 约束：这类返工是基于**当前代码状态**做 in-place 修改，不是把 task 当成全新开发重新做一遍。

2. `architecture-rework`
   - 适用场景：Architect 的任务拆分、变更边界、实现路径或整体方案本身需要调整。
   - 处理方式：由 Lead 让流程回到 Architect handoff 阶段，原地更新 `ads-platform-architect-handoff.md`，在其中追加 `Implementation Iteration History`，并生成新的 follow-up tasks；owner 重新确认 handoff 后，再派发新的 Engineer 任务。
   - 约束：这类返工不应继续复用旧 task 承载新的方案语义，而是通过新的 follow-up tasks 明确体现新增或重定义的工作。

返工时应始终把当前 `ads-platform-architect-handoff.md` 视为该 block 的**唯一权威方案载体**：

- `implementation-rework` 时，这个 handoff 保持不变，原 task 定义继续生效。
- `architecture-rework` 时，同一个 handoff 文件会原地追加迭代记录，并新增 follow-up tasks。

如果只是口头告诉 AI “帮我再改一下”，但没有明确当前属于哪类返工，那么后续容易出现：

- 代码实现和 Architect 方案出现偏离
- 旧 task 边界被静默扩展
- Reviewer 无法判断这是“原任务没做好”还是“方案已经变了”

因此，开发结束后的调整建议都通过 Lead 主会话发起，让其在 Stage 5 内完成 close / rework 的正式分流，而不是直接绕过流程在多个子会话里零散修补。
**谨慎选择：** 如果仅对某个 task 实现代码进行非逻辑细微修改（如命名、风格），也可以直接和对应 task 的 Engineer 子 Agent 对话，要求其进行对应调整。

#### 5.3.3 如何从某个前置阶段重新开始

Agent team 执行流程使用 `run-state.json` 来维护当前的执行状态。整个流程结束后，如果发现某些阶段出现了重大偏差，需要舍弃后续的修改从某个前置阶段重新开始。可以参考以下操作：

1. 在 `<projects-root>/.tmp/<run-slug>/` 中找到你本次执行的缓存文件，删除所需要舍弃阶段的中间产物（如 Architect/Engineer 的 handoff 文件）。
2. 撤销代码仓库的修改（如有）。
3. 有两种方式要求 Agent Team 从某个阶段重新开始：
   - （推荐）使用 AI 客户端（Codex/Claude）原生的分支功能，从某条消息回复后切出一个新的会话。
   - 通过 Prompt 要求 Lead 将 `run-state.json` 重置回某个阶段（例如 Analyst 阶段结束），开启一个新的会话要求 “扮演 ads-platform-lead 定义的角色，从 `<file-path-of-run-state-json> 恢复执行任务`”。

#### 5.3.4 直接和子 Agent 对话

推荐使用 GUI 版本的 AI 客户端而非 CLI 版本。在 Agent Team 的执行模式下，你可能需要频繁切换会话查看子 Agent 的思考和执行过程，必要时还需要和子 Agent 直接对话。使用 GUI 客户端可以让你更好地完成这些操作。

通常情况下，我们应该和 Main Agent（Lead）对话，然后由它负责进一步调用子 Agent 和分发任务。但这无疑增加了时间和 Token 的花费，在对主流程不产生明显破坏的情况下，我们可以选择直接和子 Agent 对话。例如以下场景：

- 需要调整 prd-summary.md 或者某个阶段的 handoff 文件
- 子 Agent 的实现不符合预期，需要对子 Agent 进行对话调试以查找原因

## 6. 查看执行产物

Agent Team 的整体流程保证了规范化和可追溯，Agent Team 会将其执行过程中输出的所有中间产物存储在 `<projects-root>/.tmp/<run-slug>/` 目录。
`<run-slug>` 目录的格式为 `日期-时间-需求摘要`，方便你快速定位到对应需求的中间产物。

Run 级产物通常包括：

```text
prd-summary.md
decision-log.md
knowledge-candidates.md
transify/*.json
```

每个 active block 会把文件写入：

```text
<projects-root>/.tmp/<run-slug>/block-<NNN>-<block-slug>/
```

Block 级产物通常包括：

```text
prd-analysis-handoff.md
td-<feature-slug>-<YYYY-MM-DD>.md
ads-platform-architect-handoff.md
ads-platform-engineer-<TASK-NNN>-handoff.md
ads-platform-reviewer-handoff.md
block-summary.md
```

你可以通过这些历史产物审计 agent 交互过程：

- 读取 `decision-log.md` 查看人工确认、编辑、跳过 review、scope 变化和 open questions 的回答。
- 读取 `prd-analysis-handoff.md` 中的 `Appendix — PRD Source Evidence`，确认后续阶段使用的是当前 active block 的 PRD 原文摘录，而不是完整 raw PRD。
- 读取每个 handoff frontmatter 查看 `gate_status`、`open_questions`、`risks`、`retry_request` 和下游路由信息。
- 将 `ads-platform-architect-handoff.md` 视为某个 block 唯一的权威返工方案载体。对于 `implementation-rework`，该 handoff 保持不变，原 task 定义继续生效；对于 `architecture-rework`，同一个 handoff 文件会原地追加 `Implementation Iteration History`，并生成新的 follow-up tasks。
- 在一个 block 完成后读取 `block-summary.md`，了解已完成工作、残余风险、返工历史，以及开始下一个 block 前的 follow-up。
