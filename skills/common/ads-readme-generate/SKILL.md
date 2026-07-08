---
name: ads-readme-generate
description: >
  通过分析代码库并参考本地 core-knowledge 文档，为 Ads 相关项目生成或更新中英文版本的 README 文件。
  TRIGGER when: user asks to generate, create, or update README for an Ads project, or mentions "生成 README"、"更新文档".
  DO NOT TRIGGER when: general documentation edits unrelated to Ads README generation.
version: 1.0.0
category: workflow
tags: [readme, documentation, generate, ads]
layer: 1
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
---

# README 生成器 — Ads 项目通用

## 运行环境

- **本地运行**：未提供项目名时通过 AskUserQuestion 询问。
- **CI 环境运行**：必须明确指定项目名 `<project_name>`，不支持交互式询问，缺少参数时报错。

> 本技能只读**代码**与 **`docs/common/core-knowledge/`**，不拉取任何站外文档、不依赖额外 MCP；活数据按需委托兄弟 skill（缺 token 则降级跳过）。

---

## 使用方式

> 当前工作目录为 **ads-workspace**，始终从 ads-workspace 根目录运行本技能。

`/ads-readme-generate <project_name>` — 直接给**项目名**即可（须已在 `references/repos.md` 登记）。例：`/ads-readme-generate sku-selector`

**输出位置**：生成的 README 写入 ads-workspace 下的 `docs/common/readme/<project_name>/`。

---

## 依赖来源 / Inputs & Sources

- **当前仓库的 README** — `docs/common/readme/<project_name>/` 下已有的两份 README（若存在）：作增量更新的基线，并保留其中仍可验证的有价值内容。
- **README 规范** — `references/readme-spec.md`（跨仓库通用、可编辑）：Part 1 骨架（输出语言、TOC、生成标记、通用术语）+ Part 2 方法（读码范围 `skip_dirs`、业务板块分类、各章节挖掘要点、**上下游拓扑推导配方**、**兄弟 skill 委托补全**）。
- **代码** — 被分析仓库的源码与配置，所有技术事实的**唯一权威来源**；
- **业务上下文** — 本地 `docs/common/core-knowledge/`：按业务板块选取相关文档，提供代码里读不出的业务背景与全局语义；**唯一外部参考，不拉取任何站外文档**。

> 核心理念：SKILL 只存"方法/骨架"；**技术事实从代码当场得到，业务上下文从本地 core-knowledge 参考**，活数据从兄弟 skill 委托，确保内容不过期。

## 执行步骤

### 第零步 — 仓库就位 / Repo Setup

把目标仓库就位，并对齐 README 规范：

1. **仓库就位**：取参数 `<project_name>`（裸项目名）即 `project_name`；在 `references/repos.md` 查到该行、取 `repository_url`，克隆到 `projects/gitlab/<project_name>/` 作为代码输入（该目录已存在则拉取默认分支的最新代码；查不到则报错并提示先在 `repos.md` 登记）。
2. **README 画像**：参考 `references/readme-spec.md`，了解 README 的骨架规范（Part 1）与各章节挖掘要点（Part 2）。

---

### 第一步 — 判定策略与变更范围

**先看目标产物 `docs/common/readme/<project_name>/README.md` 是否已存在、且末尾带生成标记 `<!-- ... checked: <commit> | spec: <hash> -->`。** 据此走 A 或 B，并算出本次的**受影响章节范围**。

#### A. 已存在且带标记 → 增量更新（默认；**禁止无依据地整篇重写**）

更新范围由**两个条件共同决定，取并集**：

1. **代码变更**：被分析仓库自上次生成以来改了哪些源文件。
   - CI 下直接用仓库根的 `.readme_changed_files`（无前缀=存在需读；`deleted:`=已删、须从 README 移除其描述）。
   - 本地自行计算：`git -C <repo> diff --name-only <标记的 checked commit> <HEAD>`（跳过 `skip_dirs`、生成目录、`_test`）。
   - 把变更文件映射到**受影响的章节**。
2. **Skill 规范变更**：当前 `references/readme-spec.md` 的 spec 哈希是否 ≠ 标记里的 `spec:` 哈希。哈希 = `sha256(references/readme-spec.md)` 取前 16 位（`shasum -a 256` / `sha256sum`）。不同 → 受该规则约束的章节（乃至整体结构）需按新规范对齐。

按并集决定受影响章节：

- **两者都无变化** → 不改任何章节，只把标记的 `checked`/`spec` 刷新为当前值（若都已是最新可直接停止）；**不进第二、三步**。
- **仅代码变更** → 受影响章节 = 代码变更映射到的章节。
- **仅规范变更** → 受影响章节 = 受新规范约束的章节；**代码事实未变之处尽量保留已验证内容**（上游调用方、枚举、错误码、配置项等），只做结构与口径对齐。
- **两者都变** → 取并集。

> ⚠️ README 已存在且带标记就**永远走 A**；本地缺 `.readme_changed_files` 用 `git diff` 自己算，不是重写整篇的理由。任何重写都须能归因到「代码变更」或「规范变更」。

#### B. 不存在或无标记 → 全量生成

受影响章节 = 全部章节，完整阅读代码库（跳过 `skip_dirs`）。

---

### 第二步 — 生成 / 更新 README

以**代码为准**分析受影响章节并产出 README，按 `references/readme-spec.md` Part 1 的语言配置写入 `docs/common/readme/<project_name>/`（不存在则创建）：`README.md`（英文，主文件）与 `README.zh-CN.md`（中文）。本地 `docs/common/core-knowledge/` 仅作**业务背景参考**（按业务板块选读），技术事实冲突时一律以代码为准。

- **B（全量）**：从头生成两份 README，顶层章节遵循 TOC 骨架，子章节按代码事实动态扩展；每章按 readme-spec.md Part 2「各章节挖掘要点」从代码挖事实、按「委托补全」补充活数据（`ads-kafka-info`、`sp-grafana`、`ads-config-center-compare-export`、`sp-space`、`sra-glossary` 等，缺 token / 失败则降级跳过、不编造）；所有描述落到实际 API/类/服务/repo 名上。
- **A（增量）**：只就地更新第一步算出的受影响章节，其余原样保留；**架构/拓扑章节一旦受影响，整段重挖、不在旧拓扑上打补丁**；更新只读取变更文件 + 现有两份 README（基线）+ `references/readme-spec.md` +（如需）相关 core-knowledge 文档。
- **上下游调用拓扑**：在「项目架构 / Architecture」下，严格按 readme-spec.md Part 2「拓扑推导配方」生成——静态挖掘四类邻居 → 委托增强 → Mermaid 图 + 上游/下游/依赖三表；与代码矛盾时以代码为准。
- **中间件实例必须具名**：凡是 README 提到 Redis / Kafka / Pulsar / FSE / Vespa / DB / Hive / S3 / ClickHouse / MQ 等中间件，必须按 readme-spec.md 的「中间件实例命名要求」写明具体实例名与读写方向，例如 topic、consumer group、Redis cluster/host/key、FSE table/scene、DB/table/DSN。不能只写"读 Redis"、"写 Kafka"、"访问 FSE"。代码中找不到具体名称时，要写明"未在代码/配置中发现"并在输出日志提醒人工补充。
- **中间件实例获取方法**：按 readme-spec.md 的「中间件实例检索方法」执行：先从代码入口确认真实服务名 / Spex name / Config Center namespace，再追 `InitConfig` / config key / 配置结构字段，最后用可用的 Config Center / Kafka / Redis 委托补全 live 实例。禁止用 repo 名、SDU 名、目录名或垂类名称猜 namespace；若代码显示 content 多垂类合并在同一个 Spex 进程中，必须写同一个 namespace 下的不同 config key / field，而不是拆成不存在的 per-vertical namespace。
- **未检出与人工确认标识**：如果自动检索没有发现任何中间件实例信息，必须在「中间件实例明细 / Middleware Instance Details」小节写入固定标识 `未能自动化检出中间件信息`。人工 owner 确认无中间件后，可把它改为 `已人工确认没有中间件信息`。后续生成若发现现有 README 已包含 `已人工确认没有中间件信息`，则跳过该 repo 的中间件实例检索，不覆盖该标识；如依赖相关代码变更，仅在输出日志提醒人工删除标识后重跑。
- 英文 `README.md`：标题与内容用英文（主文件）。中文 `README.zh-CN.md`：结构完全一致、翻译为中文，`terminology` 专有名词保留英文原名。

- 末尾按 `references/readme-spec.md` Part 1「生成标记」写入并刷新生成标记的两个字段（`checked` = 被分析仓库 HEAD 哈希；`spec` = readme-spec 哈希）；第一步据此判断代码 / 规范是否变化。

> 若分析中发现 core-knowledge 文档与代码明显不符 / 过时，可在输出末尾列出供人工核对；

---

## 输出格式

写完所有文件后，在输出日志中附上**数据来源报告**：
- 仓库信息：`category`、`project_name`、`repository_url`。
- 生成策略：走 A / B、受影响章节范围（无变化则注明"已是最新"）。
- 参考与委托：用到的 core-knowledge 文档、兄弟 skill 委托结果（成功 / 跳过原因，如缺 token）。
- core-knowledge 过时提醒：如分析中发现明显不符可简短列出，无则不写。

---

## 原则

- **准确优于完整。** 只记录在代码或配置中已验证的内容。遇到不确定的地方，进一步查证或直接省略，不要用"通常"、"一般"来填充。
- **不用占位符。** 所有命令、URL、路径和示例均须来自实际项目（Makefile、依赖管理文件、config/ 目录等）。
- **消除重复。** 同一概念在多处出现时，合并到最合适的章节统一说明。
- **有据可查。** README 中的每一个说法，都应能追溯到仓库中的具体文件、代码行、配置项，或本地 core-knowledge 文档内容。
- **中间件不可泛称。** 中间件依赖必须写到具体实例名和方向；"写 Kafka"、"读 Redis"、"依赖 FSE"这类描述不算合格。若项目不直接访问中间件，也要显式说明"本仓库不直接读写 Redis/Kafka/FSE/DB"及可验证的间接调用边界。
- **尊重人工确认标识。** `已人工确认没有中间件信息` 是人工审核结果，生成器不得自动删除或覆盖；只有人工删除该标识后，才重新生成该 repo 的中间件实例明细。
- **以代码为准。** core-knowledge 仅作业务背景参考；与代码冲突时一律以代码为准。本技能只生产 README，不修改 core-knowledge（如发现明显过时可顺带提醒）。
- **专有术语一致。** `terminology` 中列出的术语在整份文档中始终使用相同写法。
- **中英文严格对应。** 两份语言文件的章节、信息点和技术细节必须完全一致，不得一方有而另一方缺失，也不得出现翻译偏差导致的含义不同。
- **委托失败时不编造。** 若某个兄弟 skill 委托失败 / 无 token，不要凭记忆或推测补充其内容，仅基于代码分析、本地 core-knowledge 与成功的委托结果撰写。
