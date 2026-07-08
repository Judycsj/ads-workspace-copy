# 数据分析助手（ads-data-text2da）使用指南

> **语言**：[English](ads-data-text2da.md) | [中文](ads-data-text2da.zh-CN.md)

将数据分析任务拆解为子查询，通过智能选表和 LLM 校验生成 SQL，根据用户意图、SQL 和表元数据选择指定引擎（Presto 或 ClickHouse），通过匹配的 runner 或 DataSuite fallback 执行，然后分析结果并生成洞察报告。

**唤醒词**：「ads-data-text2da」、「text2da」、「text2sql」、「数据分析」、「分析一下」、「帮我分析」、「查数据」、「写SQL」、「帮我查」、「跑个SQL」、「生成SQL」

---

## 相对 ads-text2da 的核心改进

1. **智能选表**: 4 阶段检索流程（关键词提取 → 索引扫描 → 候选评估 → 多表对比）替代暴力遍历
2. **多表对比**: 当多张表都能回答查询时，展示粒度、存储类型、热度、维度/指标覆盖度、查询复杂度对比表
3. **SQL 存档**: 生成的 SQL 保存到 `docs/personal/{user}/sql/`，方便长期检索和复用
4. **LLM SQL 校验**: 执行前自动校验语法、字段存在性、分区过滤、JOIN 正确性、聚合逻辑、LIMIT

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含完整 6 阶段工作流 |
| `references/setup.md` | 内置 personal-presto 执行器的安装指南 |
| `references/config.example.json` | Personal-presto 配置示例 |
| `references/datasuite-ui-guide.md` | DataSuite UI 操作说明（回退路径） |
| `scripts/run_personal_presto_query.py` | 内置 personal-presto 执行脚本 |
| `scripts/run_clickhouse_query.py` | ClickHouse 执行脚本，支持 DataSuite ClickHouse fallback |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| `docs/common/datamap/` | 本地知识库 | 表元数据（table_info、column_info、sql_patterns） |
| `docs/common/de-knowledge/` | 本地知识库 | 本体（dim_synonyms、检索术语）、rerank profiles、业务文档 |
| `docs/common/index-synthesis.md` | 本地知识库 | DataMap 索引，用于关键词快速选表 |
| `~/.config/text2da/config.json` | 配置文件 | Personal-presto 以及可选 ClickHouse 直连 runner 配置 |
| Playwright MCP | MCP | DataSuite UI 自动化（回退执行路径） |
| 办公网络 / VPN | 网络 | 访问 Presto 集群和 DataSuite |

---

## 使用场景

### 场景 1：简单查询

> 「查一下昨天各 region 的广告主数量」

判定为简单任务 — 智能选表找到最合适的表，生成单条 SQL，自动校验，保存到个人 SQL 目录，直接执行，返回结果并附简要洞察。

### 场景 2：复杂分析

> 「分析上周 SG CTR 下降的原因」

判定为复杂任务 — 拆解为子任务（T1: 整体趋势、T2: 维度下钻、T3: 根因验证），展示分析计划待确认，迭代执行。

### 场景 3：多表选择

> 「查 shop 维度的 revenue，带归因拆分」

发现多张候选表 — 展示对比表，显示粒度、覆盖度和权衡取舍，用户确认后再生成 SQL。

---

## 工作流概览

| 阶段 | 步骤 | 说明 |
|------|------|------|
| Phase 1 | Steps 1-3 | 理解任务，智能选表（4 阶段），读取 DataMap + DE-Knowledge KB |
| Phase 2 | Step 4 | 评估复杂度（简单 vs 复杂） |
| Phase 3 | Steps 5-6 | （仅复杂任务）拆解为子任务，确认分析计划 |
| Phase 4 | Steps 7-12 | 生成 SQL，LLM 校验，保存到个人目录，选引擎，执行，提取结果 |
| Phase 5 | Steps 13-14 | 分析结果，决定下一步（迭代或结束） |
| Phase 6 | Step 15 | 生成结构化分析报告 |

---

## 执行策略

执行引擎由使用方、SQL 语义和 KB `Storage Type` 决定。ClickHouse 与 Presto 是并列路径，不是优先级关系；使用方显式指定优先于自动判断：

1. **Presto** — 保持原有 Presto 执行语义：配置可用时使用内置 personal-presto 脚本；personal-presto 配置/环境/运行不可用或任务不适合时，回退到 DataSuite Playwright 的 Presto engine。
2. **ClickHouse** — 当使用方指定 ClickHouse 时，执行引擎必须保持 ClickHouse。优先使用 `scripts/run_clickhouse_query.py`；如果直连 ClickHouse auth/HTTP 失败，runner 自动走 DataSuite ClickHouse engine 34。如果 runner 路径不可用，可以回退到 DataSuite Playwright，但 DataSuite 中必须选择 ClickHouse engine。这个路径不能变成 Hive 或 Presto。
3. **SparkSQL / 其它只能走 DataSuite 的场景** — 任务明确需要时直接使用 DataSuite Playwright。

---

## 输出格式

**简单任务**：结果表格 + 1-2 句关键发现。

**复杂任务**：结构化分析报告，包含：
- **分析背景** — 主题、数据范围、使用的表
- **数据概览** — 关键指标汇总表
- **核心发现** — 编号发现，附数据证据
- **关键结论** — 2-3 句回答用户最初的分析问题
- **建议 & 后续** — 可操作建议和后续分析方向
