# 广告系统知识问答（ads-knowledge-qa）使用指南

> **语言**：[English](ads-knowledge-qa.md) | [中文](ads-knowledge-qa.zh-CN.md)

通过带 guardrail 的分层检索（ads-workspace index → atomic note → Confluence → sra-kb-query → 代码）回答 Shopee Paid Ads 架构、策略和实现问题，并通过本地 wrapper 固定 code search 与 Confluence freshness filter 的调用方式。

**唤醒词**：「ads-knowledge-qa」、「广告知识问答助手」、「广告系统」、「ads-engine」、「online-bidding」、「paidads-recall」、「eCPM」、「ROI」、「CTR」、「CVR」、「ocpx」、「双出价」、「出价策略」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含 guardrail 检索流水线 |
| `references/workflow.md` | 分层检索策略与 worked examples |
| `references/security-rules.md` | 脱敏与安全输出规则 |
| `references/repos.md` | `core-knowledge/03.ads-engine/01.system-architecture-overview.md` repo 路由、code-search 查询词与索引状态说明 |
| `scripts/preflight.sh` | 代码搜索 / Confluence wrapper 依赖检查 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| `sra-code-search` | Skill | wrapper 背后的 repo search / zgrep / hyper-search 能力 |
| `sra-confluence-kb` | Skill | wrapper 背后的 Confluence 新鲜度检索能力 |
| `sra-kb-query` | Skill | 托管 S&R&A 知识库问答 fallback |
| `sp-grafana` | Skill | 实时监控查询 |
| `ads-okr-epic-report` | Skill | OKR/KR/KP 进展与项目报告生成 |
| GitLab 访问权限 | 网络 | 当检索路径进入源码仓库时读取 Ads 文档、README 与代码 |
| ads-workspace 文档 | 本地文件 | 主知识来源：先查 `docs/common/index-synthesis*.md`，再读其指向的 atomic note，包括 `docs/common/core-knowledge/`、`docs/common/readme/<repo>/`，以及补充 `docs/common/**` / `docs/team/**` Markdown |

---

## 使用场景

### 场景 1：概念 / 架构问题

> 「eCPM 是怎么计算的？」

归类为通用知识。先查 `docs/common/index-synthesis*.md` 定位 atomic note，再读对应 `docs/common/core-knowledge/` 文件，返回公式和 Shopee 特定上下文。

### 场景 2：架构与业务问题

> 「ads-engine 的召回是怎么工作的？」

先查 `docs/common/index-synthesis*.md`；如果明确到 repo，再读 index 指向的 `docs/common/readme/<repo>/`；仍不足时再补 Confluence / `sra-kb-query`。

### 场景 3：数据表与 SQL 问题

> 「哪个表有 campaign 级别的每日指标？」

这类不是目标主路径。应转给 `sra-data-query` 做 DataSuite ad-hoc 查数与 SQL 执行，而不是强行走文档 / 代码检索。

### 场景 4：代码实现问题

> 「online-bidding 的最终出价是怎么算出来的？」

归类为实现型问题。skill 会更快进入源码层；需要 repo 概览时先读 `docs/common/readme/<repo>/`，并通过 `bash scripts/run_code_search.sh ...` wrapper 调用 code search，而不是写死安装路径。

进入 code search 前，skill 会先从 `docs/common/core-knowledge/03.ads-engine/01.system-architecture-overview.md` 解析目标 repo，再调用 `search-repo`，并使用返回结果里的 repo `name`；静态或猜测出来的 `gitlab/...` slug 不能直接作为参数。

### 场景 5：OKR / KP 进展问题

> 「O3 KP2 进展怎么样？」

这类不是知识检索路径。精确到 KP 时，应转给 `/ads-okr-epic-report --query <kp>`，让结果直接输出到对话且不写文件。如果目标有歧义，例如 `O3 KP2` 可能对应多个 KR，先列出候选 KP 标题并让用户选择，再运行报告。

---

## 检索流水线

1. **Preflight** — 每个 session 可先执行一次 `bash scripts/preflight.sh`
2. **L1** — 识别 intent，判断是概念 / 架构 / 实现 / 监控
3. **L2** — 先查 `docs/common/index-synthesis*.md`，再读命中的 atomic note（`docs/common/core-knowledge/` 或 `docs/common/readme/<repo>/`），然后查其他 ads-workspace Markdown、Confluence 和 `sra-kb-query`
4. **可选 source-repo docs fallback** — 用 `core-knowledge/03.ads-engine/01.system-architecture-overview.md` 选择候选 repo；只有集中化 README 不足时才读取源码仓库 docs
5. **L4** — 需要实现细节时，再通过本地 wrapper 搜代码事实
6. **L5** — 监控类问题直接委派给 `sp-grafana`
7. **项目进展** — 精确 KP 进展请求委派给 `/ads-okr-epic-report --query`；KR/O 报告生成使用普通 `ads-okr-epic-report`

---

## 输出格式

回答应满足：

- 在第一层足够回答时就停止，不做过度检索
- 找不到文档时明确写“无相关文档”，找不到代码时明确写“无相关代码”
- 关键事实都带来源
- 文档与实现冲突时以代码为准
- 输出前应用 `references/security-rules.md` 的脱敏规则

---

## 下游 Skill 编排

| Skill | 用途 |
|-------|------|
| `sra-data-query` | DataSuite ad-hoc 数据分析与 SQL 执行 |
| `/ads-text2da` | 自然语言数据分析与 SQL 执行 |
| `/ads-diagnose` | 诊断广告效果异常 |
| `sp-grafana` | 监控与 dashboard 查询 |
| `ads-okr-epic-report` | 用 `--query` 在对话中查询 KP 进展，或从 Epic 文件生成 KR/O 项目报告 |
