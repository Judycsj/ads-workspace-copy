---
name: ads-data-analyze
description: >
  Analyze query results, generate insights, and produce structured analysis reports.
  Supports iterative analysis with sub-task result accumulation and extended actions
  like writing table documentation, exporting data, and suggesting follow-up queries.
  (数据分析报告 — 结果分析与洞察生成)
  TRIGGER when: user mentions "ads-data-analyze", "analyze results", "分析结果",
  "analyze this data", "generate report", "生成报告", "数据洞察", "insight report",
  "帮我分析数据", "分析一下结果", or provides query results and asks for analysis.
  DO NOT TRIGGER when: user is writing SQL (use ads-data-text2da), executing SQL (use ads-data-sql-executor),
  or doing general data exploration without existing query results.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# Data Analyze: 结果分析与洞察生成

接收查询结果，进行数据分析，生成洞察报告。支持迭代分析（多子任务逐步深入）和独立分析（用户直接提供数据）。

## 使用方式

```
/ads-data-analyze 分析以下查询结果：{粘贴数据或文件路径}
/ads-data-analyze 帮我看看这组数据有什么异常
```

**被 ads-data-text2da 调用时**：接收查询结果 + 子任务上下文 + 前序发现，进行分析并更新会话文件。

## 输入契约

| 参数 | 必选 | 说明 |
|------|------|------|
| `results` | 是 | 查询结果（Markdown 表格、JSON、或文件路径） |
| `task_context` | 否 | 子任务描述和分析目标（由 text2da 传入） |
| `prior_findings` | 否 | 前序子任务的发现（迭代分析时由 text2da 传入） |
| `mode` | 否 | `single`（默认）/ `iterative`（多子任务迭代模式） |
| `session_file` | 否 | 分析会话文件路径（由 text2da 传入，分析后更新 §3-§5） |

## Phase 1: 结果分析

### Step 1: 数据验证

检查数据质量：

- **完整性**: null 值比例、缺失的维度或时间段
- **合理性**: 意外的零值、负值、超大值
- **一致性**: 汇总值与明细加总是否一致

如发现数据质量问题，先报告给用户再继续分析。

### Step 2: 模式识别

1. **趋势识别**:
   - 上升、下降、平稳、周期性波动
   - 变化拐点定位（从哪天/哪周开始变化）

2. **异常检测**:
   - DoD 变化 >50% 的指标
   - WoW 变化 >30% 的指标
   - 偏离均值 2 个标准差以上的离群值

3. **对比分析**:
   - 跨维度对比（哪个 region/campaign type 贡献最大）
   - 跨时间对比（环比、同比）
   - 占比分析（各维度的份额变化）

### Step 3: 派生指标计算

计算原始数据中不存在但分析需要的指标：

| 派生指标 | 公式 | 适用场景 |
|----------|------|---------|
| CTR | clicks / impressions × 100% | 广告效果 |
| CVR | orders / clicks × 100% | 转化分析 |
| CPC | cost / clicks | 成本分析 |
| ROAS | gmv / cost | ROI 分析 |
| CIR | cost / gmv × 100% | 费效分析 |
| DoD 变化率 | (today - yesterday) / yesterday × 100% | 日环比 |
| WoW 变化率 | (this_week - last_week) / last_week × 100% | 周环比 |

### Step 4: 交叉验证

当 `prior_findings` 存在时：

- 与前序子任务发现的趋势/异常进行比对
- 验证或推翻前序假设
- 识别跨子任务的关联模式

## Phase 2: 决定下一步

分析完当前结果后，根据 `mode` 决定输出：

### iterative 模式（多子任务）

- **还有后续子任务** → 返回当前发现摘要，供 text2da 用于设计下一个子任务的 SQL
- **发现新假设** → 向用户提议追加子任务（说明原因和查询方向）
- **全部完成** → 进入 Phase 3 生成最终报告

### single 模式（独立分析）

- 直接进入 Phase 3 生成报告

## Phase 3: 生成报告

### 简单任务

直接展示：
- 结果数据（Markdown 表格）
- 1-2 句关键发现

### 复杂任务

生成完整分析报告：

```
## 数据分析报告

### 分析背景
- **分析主题**: {topic}
- **数据范围**: {时间范围、地区、实体}
- **数据表**: {使用的表}

### 数据概览
{关键指标汇总表，含格式化的数字}

### 核心发现
1. **{发现 1 标题}**: {描述，附具体数值}
   - 数据支撑: {相关表格或数据}
2. **{发现 2 标题}**: ...
3. ...

### 关键结论
{2-3 句综合性结论，回答用户最初的分析问题}

### 建议 & 后续
- {可操作建议 1}
- {可操作建议 2}
- {如需要，建议的后续分析方向}
```

## Phase 4: 更新会话文件

如果传入了 `session_file` 路径，用 Edit 更新对应 section：

- §3 当前子任务的**关键发现**
- §4 **分析结论**（最终报告完成时）
- §5 **后续建议**（最终报告完成时）

## Phase 5: 扩展动作

分析完成后，根据用户需求或主动建议执行扩展动作：

### 动作 A: 写表使用文档

当分析过程中积累了对某张表的深入理解时，可以将发现写入表的知识库文档：

1. 更新 `docs/common/datamap/{table}/table_info.md` 的 Description 或 Notes
2. 更新 `docs/common/datamap/{table}/sql_patterns.md` 添加本次使用的有效 SQL 模式
3. 需用 AskUserQuestion 确认后再写入

### 动作 B: 导出数据

- 将分析结果导出为 CSV: `docs/personal/{user}/analysis/` 下
- 将报告导出为 Markdown 文件

### 动作 C: 建议后续查询

基于分析发现，建议：
- 需要进一步验证的假设和对应的查询方向
- 可以深入分析的维度
- 相关的其他数据表

## 输出契约

### iterative 模式输出

```
{findings: "当前发现摘要", suggested_next_actions: ["建议1", ...], data_issues: ["问题1", ...]}
```

### single / final 模式输出

格式化的 Markdown 分析报告。
