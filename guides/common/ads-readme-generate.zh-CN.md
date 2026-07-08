# Ads 项目 README 生成器（ads-readme-generate）使用指南

> **Contributors**: fengjiao.wang ｜ **最后更新**：2026-06-03 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-readme-generate.zh-CN.md)
> **语言**：[English](ads-readme-generate.md) | [中文](ads-readme-generate.zh-CN.md)

通过分析代码库并参考本地 core-knowledge 文档，为 Ads 相关项目自动生成或更新中英文版本的 README 文件。

**唤醒词**：「生成 README」、「更新文档」、「ads-readme」、「generate README」、「update README」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义与生成流程 |
| `references/readme-spec.md` | 内置规范：Part 1 骨架（输出位置与语言、TOC、生成标记、通用术语）+ Part 2 方法（读码范围 skip_dirs、业务板块分类、各章节挖掘、**上下游拓扑推导配方**、**兄弟 skill 委托补全**） |
| `references/repos.md` | 仓库登记表（`category | project_name | repository_url | PIC`）——项目名 → URL 来源，与 overview 生成器、CI 共用 |
| 本地 `docs/common/core-knowledge/` | 业务上下文来源（按业务板块选取），唯一外部参考，不再拉取站外文档 |
| `scripts/` | 辅助脚本（增量模式的变更文件检测） |

生成原则统一放在 `SKILL.md`（唯一来源，references 不重复）。

仓库专有事实（`project_name`、`repository_url`、`skip_dirs`、术语、拓扑）在生成时从代码 + git 当场推导；稳定的跨仓库骨架与方法落在 `references/`。

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| Git 仓库 | 本地 | 代码库源文件分析 |
| 本地 `docs/common/core-knowledge/` | 本地 | 业务上下文参考 |

本技能**只读代码 + 本地 core-knowledge**，不拉取任何站外文档，无需 MCP / token。活数据（Kafka/监控/Config Center 等）按需委托兄弟 skill，缺 token 则降级跳过。

---

## 使用场景

### 基本用法

> 当前工作目录为 **ads-workspace**，始终从 ads-workspace 根目录运行。

```bash
# 直接给项目名 → 在 repos.md 查到 URL，克隆到 projects/gitlab/<name>/ 后分析
# （该目录已存在则拉取默认分支的最新代码）
/ads-readme-generate bidding-store-cpp
```

### 场景 1：首次生成项目 README

> 「为 my-service 项目生成 README」

Skill 会：
1. **仓库就位** — 克隆/拉取仓库，确定 `project_name`、`repository_url`
2. **判定策略** — 无 README 即全量；本步只用 git/本地文件，零外部依赖
3. **生成 README** — 以代码为准分析并产出 README，本地 `docs/common/core-knowledge/` 仅作业务背景参考；委托兄弟 skill 取活数据（拓扑、监控、术语）
4. 将两份文件写入 ads-workspace 的 `docs/common/readme/<project_name>/`：`README.md`（英文）和 `README.zh-CN.md`（中文）

### 场景 2：更新现有 README

> 「更新我们服务的 README」

Skill 会：
1. 检测现有 README 末尾的生成标记
2. 重新分析仅有变化的章节
3. 保留标记外的手工编辑内容
4. 更新两个语言版本，保持内容同步

### 场景 3：自定义/框架特定结构

> 「为这个服务生成合适结构的 README」

结构自动适配：
- `references/readme-spec.md`（Part 1）的 TOC 骨架提供稳定的顶层章节
- 子章节按代码事实扩展（如 BRPC 服务自动得到 API 章节；FE 仓库得到构建/发布章节）
- 若要改**跨仓库**约定（新增通用章节、委托项），改一次对应的 `references/` 文件即可，对所有仓库生效

---

## 内置规范 vs 运行时推导

输入来自两类来源：

**内置（稳定、跨仓库）** — 位于 `references/`：
- `readme-spec.md` — Part 1（输出位置与语言、TOC 骨架、生成标记、通用术语）+ Part 2（读码范围 skip_dirs、业务板块分类、各章节挖什么、**拓扑推导配方**、**委托补全**）
- `repos.md` — 仓库登记表（category、project_name、repository_url、PIC）

**业务上下文** — 本地 `docs/common/core-knowledge/`：按业务板块选取相关文档（唯一外部参考）。

**运行时推导（每仓库、永不过期）** — 生成时计算：

| 字段 | 推导来源 |
|------|----------|
| `project_name` | 入参裸项目名 → `projects/gitlab/<name>/` |
| `repository_url` | `repos.md` 的 `URL` |
| `skip_dirs` | 构建工具探测（`MODULE.bazel`/`go.mod`/`package.json`/…）+ 通用兜底 |
| 术语 | 通用列表 + 从代码挖出的核心类型/类/服务 |
| 服务拓扑 | 拓扑配方：静态挖掘 RPC/MQ/存储/配置依赖 + 委托增强 |
| 业务板块 | 从 `repository_url` / 代码特征推断（engine / recall / bidding / index / data / platform / platform-pc）→ 选取 core-knowledge 文档 |

---

## 委托的兄弟 Skill

为保持事实最新，生成时委托兄弟 skill——**尽量委托、追求信息最全**；缺少平台 token 时（如 CI 环境）跳过并优雅降级：

| 内容 | Skill |
|------|-------|
| Kafka / Pulsar topic、consumer group | `ads-kafka-info` |
| Redis / 缓存集群信息 | `ads-cachecloud-info` |
| Config Center namespace / key | `ads-config-center-compare-export` |
| 部署 / SDU / service tree | `sp-space` |
| 监控大盘 | `sp-grafana` |
| 业务术语 | `sra-glossary` |
| 第三方依赖源码 | `sra-code-search` |

---

## 生成工作流

### 第零步：仓库就位

1. **仓库就位**：取 `<project_name>` → 在 `repos.md` 查到 `URL`（即 `repository_url`）→ 克隆到 `projects/gitlab/<name>/`（已存在则拉默认分支最新；查不到则报错提示先登记）
2. **README 画像**：参考 `readme-spec.md` 了解 README 的骨架规范（Part 1）与各章节挖掘要点（Part 2）

### 第一步：判定策略与变更范围（零外部依赖，先做）

检查目标 README 是否已存在且带生成标记，决定走 A/B 并算出**受影响章节范围**。本步只用 git 与本地文件：

- **存在（增量 A）**：按"代码变更 ∪ 规范变更"取并集算受影响章节。
  - 代码变更：CI 用仓库根 `.readme_changed_files`（`scripts/get_changed_files_since_readme.sh` 写入，以 README 最新提交为基线）；本地用 `git diff`。`deleted:` 行须从 README 移除其描述。
  - 规范变更：`readme-spec.md` 的 spec 哈希 ≠ 标记里的 `spec:`。
  - **都无变化** → 只刷新标记 / 停止，不进后续步骤。
- **不存在（全量 B）**：受影响章节 = 全部，完整阅读仓库（跳过 `skip_dirs`）。

### 第二步：生成 / 更新 README（本技能重点）

以**代码为准**分析受影响章节并产出 README；本地 `docs/common/core-knowledge/` 仅作业务背景参考（按业务板块选读），技术事实冲突时一律以代码为准。

- 按 spec 语言配置，在 `docs/common/readme/<project_name>/`（不存在则创建）生成/更新 `README.md`（英文）与 `README.zh-CN.md`（中文）
- B 全量：遵循 TOC 骨架、子章节按代码事实扩展；A 增量：只就地更新受影响章节，其余保留
- 每章按 `readme-spec.md`（Part 2）挖事实并委托兄弟 skill 补活数据（拓扑/监控/术语，缺 token 则降级跳过）；项目架构章节按**拓扑推导配方**生成（静态挖掘 → 委托增强 → Mermaid 图 + 上游/下游/依赖三表；依赖相关代码有变更则整段重挖、不打补丁）；与代码矛盾时以代码为准
- 中间件依赖必须写到**具体实例名 + 读写方向**：例如 Kafka topic / producer config / consumer group，Redis cluster/host/key/TTL，FSE table/scene/namespace，DB/table/DSN，Vespa schema/index，Hive table，S3 bucket/path。不能只写"写 Kafka"、"读 Redis"、"访问 FSE"。若仓库不直接访问中间件，README 也要显式说明。
- 如果自动检索没有发现任何中间件实例信息，README 必须写入固定标识 `未能自动化检出中间件信息`；人工确认无中间件后，将其改为 `已人工确认没有中间件信息`。后续生成看到人工确认标识后，会跳过该 repo 的中间件实例检索。
- 末尾刷新生成标记（`checked` HEAD 哈希 + `spec` 哈希）

> 顺带提醒（非重点）：若发现 core-knowledge 与代码明显不符 / 过时，可在输出末尾简短列出供人工核对；本技能只生产 README，不修改 core-knowledge。

---

## 输出格式

每份语言文件包含：

1. **项目概述** — 功能说明、仓库链接、快速开始
2. **项目架构** — 系统设计、服务拓扑（如有）
3. **主要功能** — 核心特性及代码参考
4. **安装 / 环境搭建** — 依赖、编译步骤（来自实际 Makefile/配置）
5. **使用 / API 文档** — 实际命令和示例（来自代码库）
6. **开发指南** — 贡献规范、测试方式
7. **参考资料** — 仓库链接、相关仓库、旧 README 中稳定的手册/协议链接

所有技术细节（函数、API、文件路径）必须能追溯到实际代码或本地 core-knowledge 文档。

---

## 核心原则

- **准确优于完整** — 仅记录代码/配置中已验证的内容，遇到不确定进一步查证或直接省略
- **不用占位符** — 命令、URL、路径均须来自实际项目文件
- **消除重复** — 相同概念在多处出现时，合并到最合适的章节统一说明
- **有据可查** — README 中每一个说法都应能追溯到仓库中的具体文件、代码行、配置项，或本地 core-knowledge 文档
- **中间件不可泛称** — Redis/Kafka/FSE/DB 等依赖必须写明具体实例名与方向；只写中间件类型不算合格
- **尊重人工确认标识** — `已人工确认没有中间件信息` 表示 owner 已审核，后续生成不得自动覆盖
- **以代码为准** — core-knowledge 仅作业务背景参考，与代码冲突时以代码为准；本技能只生产 README，不修改 core-knowledge（如发现明显过时可顺带提醒）
- **专有术语一致** — `terminology` 中的术语在整份文档中始终使用相同写法
- **中英文严格对应** — 两份语言文件的章节、信息点、技术细节完全一致（仅语言不同）
- **委托失败时不编造** — 若兄弟 skill 委托失败 / 无 token，不要凭记忆补充，仅基于代码分析、本地 core-knowledge 与成功的委托结果撰写

---

## 下游 Skill 编排

| Skill | 用途 |
|-------|------|
| `/ads-workspace-check` | 验证生成的文档一致性 |
| `/ads-knowledge-qa` | 在知识库查询中引用生成的 README |
| `/ads-doc-generate` | 生成相关技术文档（TD/PRD/Rollout） |
