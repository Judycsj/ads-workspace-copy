---
name: ads-kb-eval
description: >
  KB Quality Evaluation（知识库质量评测）。
  评测知识库文档对给定问题的回答质量，支持单题和批量评测。
  TRIGGER when: 用户提到"评测KB"、"知识库质量"、"KB eval"、"评估知识库"、"KB 评分"、"知识库覆盖率"
  DO NOT TRIGGER when: 用户要编译入库（→ ads-kb-compile）、用户要问答（→ ads-knowledge-qa）
category: knowledge
tags: [kb, eval, quality, scoring, routing]
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent]
---

# Ads KB Eval/知识库质量评测

评测知识库文档对给定问题的回答质量。支持两种输入模式：

| 模式 | 触发条件 | 说明 |
|------|---------|------|
| **模式 A: 新增问题** | 用户提供新问题（单题/列表/文件） | 对新问题做预处理（去重→范围检查→分类）→ 路由 → 评分 → 写入 |
| **模式 B: 模块评测** | 用户指定模块或不带问题调用 | 选择模块 → 提取该模块已有问题 → 对所有问题重新评分 → 覆盖更新 |

---

## 前提条件/Prerequisites

| 条件             | 说明                                                                                               |
| -------------- | ------------------------------------------------------------------------------------------------ |
| Index 文件       | `docs/common/index-synthesis.zh-CN.md` 存在                                                        |
| Core Knowledge | `docs/common/core-knowledge/` 目录包含知识文档                                                           |
| 问题集（可选）        | `docs/common/question-list.md` 为默认问题集                                                            |
| 输出目录           | `docs/common/ops-log/questions/` — 路由结果和评测结果写入此目录                                                        |
| 技能路由表          | `docs/team/00.paid-ads-dev/04.how-tos/01.getting-started/03.skill-routing.md` 存在（Task 类问题匹配执行技能） |

---

## 启动前/Before First Use

读取以下参考文件以了解详细规则：

1. [references/routing-rules.md](references/routing-rules.md) — 问题到文件的路由规则和完整文件映射表
2. [references/scoring-rubric.md](references/scoring-rubric.md) — 1-5 分评分标准和低分理由模板
3. [references/question-classification.md](references/question-classification.md) — 问题分类判定规则、信号词和典型案例

---

## Step 0: 模式判定与输入解析/Mode Detection & Input Resolution

### 0a. 模式判定/Mode Detection

根据用户输入判定模式：

- **模式 A（新增问题）**：用户提供了新问题内容（单个问题文本、Markdown 列表、问题集文件路径）
- **模式 B（模块评测）**：用户指定了模块名（如 "评估 2.1 召回"、"评测 Chapter1 核心知识"），或不带任何问题直接调用 `/ads-kb-eval`

### 0b. 模式 A 输入解析/Mode A: New Questions Input

接受以下输入形式：
- **单个问题**: 用户直接提出一个 KB question
- **问题列表**: 用户在消息中列出多个问题（Markdown list）
- **问题集文件**: 用户指定文件路径 → `Read` 工具读取（默认 `docs/common/question-list.md`）

**QID 分配**：每个新问题分配永久唯一 ID，格式 `YYYYMMDDHHMMSS`（基于入库时刻，同批按秒递增）。QID 一经分配永不变更。

解析完成后进入 **Step 1 预处理**。

### 0c. 模式 B 输入解析/Mode B: Module Eval Input

**触发条件**：用户输入包含 "指定模块"、"评测模块"、"评估 Chapter"、"评估 §"，或不带问题直接调用 `/ads-kb-eval`。

**模块选择器流程**：

1. 读取 `docs/common/ops-log/questions/questions-list.zh-CN.md` 的 `## 汇总统计/Summary` 表格
2. 提取所有模块行（排除合计行），构建带统计信息的模块列表
3. 用 `AskUserQuestion` 两级选择确定目标模块：

**第一级 — 选 Chapter**（4 个选项）：

| 选项 | 内容 |
|------|------|
| 1 | Chapter 1 核心知识（在线广告基础 + 策略层 + 工程层 + 平台层 + 数据层） |
| 2 | Chapter 2 DPM 核心知识 |
| 3 | Chapter 3-4 代码仓库 & 数据表 |
| 4 | Chapter 5-6 使用指南 & 团队 SOP |

**第二级 — 选子模块**（选定 Chapter 后展示其下 `##` 子模块，每个选项附问题数）

**第三级 — 如需细分**（当子模块问题数 > 50 时可进一步按 `###` 拆分）

**直接指定**：如用户已明确模块名（如 "评估 2.1 召回"），跳过选择器直接匹配。

4. 选中模块后，从 `questions-list.zh-CN.md` 中该 section 下所有表格中提取已有问题（保留原 QID）
5. **跳过 Step 1 预处理**，直接进入 **Step 2 路由与评分**

---

## Step 1: 预处理/Preprocessing（仅模式 A）

> 模式 B 跳过此步骤，直接进入 Step 2。

### 1a. 去重检查/Deduplication Check

1. 读取 `docs/common/ops-log/questions/questions-list.md`（不存在则跳过）
2. 提取所有已有表格行中的 "问题/Question" 列
3. 归一化比较：去除前后空格、去除标点符号、转小写
4. 归一化后完全匹配 → 标记为重叠
5. **向用户报告重叠问题**（列出跳过的问题文本），仅对非重叠问题继续
6. 全部重叠则终止

### 1b. 范围检查与拆分/Scope Detection & Splitting

检查问题是否 scope 过大（跨多个不相关模块），并**交互式**拆分。

**Scope 过大信号**（满足任一）：
- 包含多个不同模块的领域关键词（如"召回"+"出价"+"ranking"）
- 用连词连接不相关子话题
- 涉及 3+ 个 pipeline 阶段且无聚焦点
- **注意**：对比类问题不算 scope 过大

用 `AskUserQuestion` 呈现拆分建议，用户接受/拒绝/修改后继续。

### 1c. 问题分类/Question Classification

按 `references/question-classification.md` 中的判定流程对每个问题分类。按以下顺序依次检测，**命中即停**：

1. **研究/分析任务检测** → 含"评估是否最优"、"识别缺少的"、"分析 X 对 Y 的影响"、"提出解决方案"等动词信号 → **无效问题**
2. **动态数据检测** → 含"最近一周"、"统计 X 数量"、"资源利用率"等时效性信号 → **指标查询**
3. **操作性/SOP 检测** → 含"诊断方法"、"如何排查"、"如何自动生成"等操作信号 → **task**（须从 `03.skill-routing.md` 匹配执行技能）
4. **KB 范畴检测** → 问题涉及训练平台/EGO、论文对比、项目历史等非 KB 范畴 → **无效问题**
5. **默认** → **kb**

| 类别 | 定义 | 后续处理 | 评分 |
|------|------|---------|------|
| **kb** | 概念、原理、架构、流程、配置等可从 KB 静态文档回答的知识型问题 | → Step 2 路由 + 评分 | 1-5 分 |
| **指标查询** | 问动态变化的指标数值或统计数据，KB 应提供指标定义 + 查询方式 | → Step 2 路由 + 指标查询标准评分 | 1-5 分（双维度） |
| **task** | 需要执行操作、诊断排查、或属于 SOP/Runbook 内容 | → 匹配执行技能，跳过评分 | N/A |
| **无效问题** | 表述不清、超出 KB 范畴、或本质上是研究/分析任务而非知识查询 | → 标记原因，跳过评分 | N/A |

**核心判断原则**：KB 知识型问题的回答应当可以从文档中**查找事实**获得。如果回答需要**独立推理、实验设计、方案探索或创造性分析**，则不是 kb 类。

分类完成后报告各类别数量，仅 **kb** 和**指标查询**类进入 Step 2。

---

## Step 2: 路由与评分/Routing & Scoring

### 模式 A: 新问题路由与评分

1. 读取 `docs/common/index-synthesis.zh-CN.md` §2 和 `references/routing-rules.md`
2. 按优先级路由（**§2.1 Core Knowledge 优先**），确定主路由文件（1 个）+ 辅助路由文件（0-4 个）
3. 路由逻辑：关键词匹配 → 主题分类 → 多文件路由（最多 5 个）→ 歧义全部纳入
4. 读取路由文件评分（多题同文件只读一次，>500 行用 `Grep` 定位）

### 模式 B: 已有问题重新评分

1. 已有问题保留原 QID 和原路由信息
2. 重新读取每个问题的主路由文件和辅助路由文件的**最新内容**
3. 按最新 KB 内容重新评分，更新评分和低分理由
4. 同时更新理由/Reason 列（如之前为 `—` 则补充分类理由）

### 评分标准/Scoring Rubric

按 `references/scoring-rubric.md` 打分：
- **kb 类**：通用 1-5 分标准（5=完全覆盖 → 1=未覆盖）
- **指标查询类**：双维度标准（现状描述 + 查询方式）

**非 5 分时必须给出**：具体缺失内容 + 建议补充的文件/章节。指标查询类还须标明缺哪个维度。

Step 2 完成后，每个问题已有：QID、问题文本、类别、理由、主路由文件、辅助路由文件、评分、低分理由。

---

## Step 3: 写入结果/Write Results

### 3a. 写入 questions-list.md/Write to Questions List

将评测结果**按主路由文件展开**写入 `docs/common/ops-log/questions/questions-list.md`。

**文件结构**：按 `index-synthesis.zh-CN.md` §2 展开为三级目录骨架：
- `#` = Chapter（如 `# Chapter 1、核心知识索引/Core Knowledge Index`）
- `##` = 次类别（如 `## 1 在线广告基础/Online Advertising Fundamentals`）
- `###` = 文件（如 `### 1.1 前言 — [filepath](link)`）

**表格格式**（9 列）：

```markdown
| QID | 问题/Question | 类别/Type | 理由/Reason | 主路由文件/Primary File | 辅助路由/Secondary Files | 评分/Score | 低分理由/Low Score Reason | 备注/Note |
|---|------|------|------|---------|---------|------|---------|---------|
```

**汇总统计**：文件头部 `## 汇总统计/Summary` 按模块拆分表格（模板参见 `questions-list.md` 当前文件），Chapter1 策略层按 2.1-2.6 拆分 6 行、工程层按 3.1-3.6 拆分 6 行。

**问题分类统计**：`### 问题分类/Question Classification` 表格包含 4 类（KB/指标查询/Task/无效问题）。

**写入逻辑**：
- **模式 A**：文件不存在 → `Write` 创建；已存在 → `Edit` 追加新问题到对应 section
- **模式 B**：用 `Edit` 覆盖更新该模块下所有问题行的评分和低分理由列
- **写入/更新问题行后，运行脚本刷新统计表**：
  ```bash
  uv run skills/common/ads-kb-eval/scripts/refresh_summary.py
  ```
  脚本自动处理 zh-CN 和 EN 两个文件的 `汇总统计/Summary` 和 `问题分类/Question Classification` 表格

### 3b. 对话输出/Console Output

```
模式: A（新增问题）/ B（模块评测: <模块名>）
Step 1: 预处理完毕（跳过 M 个重复）[仅模式 A]
- 分类: KB 知识型 X 题 | 指标查询 P 题 | Task 任务型 Y 题 | 无效问题 Z 题
Step 2: 路由与评分完毕，共 N 题
Step 3: 结果写入 docs/common/ops-log/questions/questions-list.md
- KB 评测: X 题 | 平均分: X.X / 5 | 非满分: K 题
- 指标查询评测: P 题 | 平均分: Y.Y / 5 | 非满分: J 题
→ 非满分问题 K 题，可执行 Step 4 KB 文档优化（将提示确认）
```

---

## Step 4: KB 文档优化/KB Doc Optimization（可选）

> Step 3 完成后触发。用 `AskUserQuestion` 询问用户是否执行，用户确认后才执行。

### 4a. 确认与准备/Confirmation & Preparation

1. 从 Step 2/3 结果中提取所有评分 < 5/5 的 **kb** 和**指标查询**类问题
2. 按**主路由文件（Primary File）**分组
3. 用 `AskUserQuestion` 展示优化摘要并请求确认：
   - 非满分问题总数
   - 涉及 KB 文件数
   - 按文件列出问题数分布（前 10 个文件）
   - 选项: **[1] 全部优化** / **[2] 选择文件优化** / **[3] 跳过**
4. 用户选 [2] 时，展示文件列表让用户勾选目标文件

### 4b. 按文件分组优化/Per-File Optimization via Subagent

对每个待优化的 KB 文件，使用 `Agent` 工具 spawn 子 agent。**同一主路由文件的所有非满分问题由同一个子 agent 统一处理**，避免编辑冲突。

**子 agent 输入（通过 Agent prompt 传递）**：
- KB 文件绝对路径
- 该文件的非满分问题列表（QID、问题文本、当前评分、低分理由）
- 辅助路由文件列表（如有）
- 评分标准摘要（来自 `references/scoring-rubric.md`）

**子 agent 工作流**：
1. `Read` 主路由 KB 文件全文 + 辅助路由文件
2. 对每个问题，按 `ads-knowledge-qa` 方式基于 KB 内容回答，识别回答中的缺失
3. 对比低分理由，确认需要补充的具体内容
4. 合并同类缺失（多个问题缺同一段落的不同细节 → 合并为一次编辑）
5. 用 `Edit` 工具补充内容到 KB 文件合适章节：
   - 已有相关 H3/H4 → 在该节下扩展
   - 无相关章节 → 在最合适的位置新增 H3/H4
6. **不编造业务数据** — 只基于文件中已有内容做结构化补全和扩展；如果低分理由要求的信息在文件中完全无线索，标记为"需人工补充"并跳过
7. 返回优化报告：每个 QID 的处理结果（已补全 / 部分补全 / 需人工补充）

**处理顺序**: 按文件在 `index-synthesis` 中的出现顺序依次处理

### 4c. 重新评分/Re-Scoring

所有文件优化完成后：
1. 对所有被优化的问题，重新读取其主路由文件和辅助路由文件的**最新内容**
2. 按 Step 2 评分标准重新打分
3. 更新评分和低分理由

### 4d. 写入更新/Write Updated Results

1. 用 `Edit` 更新 `questions-list.md` 和 `questions-list.zh-CN.md` 中受影响问题行的 Score、Low Score Reason、Note 列
2. Note/备注列更新规则：
   - 评分达到 5/5 → `—`
   - 评分提升但未达 5/5 → `已优化`
   - 标记为"需人工补充"的问题 → `需人工`
3. 运行 `uv run skills/common/ads-kb-eval/scripts/refresh_summary.py` 刷新统计表
4. 双语同步：两个文件必须同步更新（Hard Rule 13）

### 4e. 对话输出/Console Output

在 Step 3 输出之后追加：

```
Step 4: KB 文档优化完毕
- 优化文件数: F 个 | 优化问题数: K 题
- 评分提升: 平均 X.X → Y.Y | 达到满分: M 题 | 仍需人工: N 题
```

---

## 使用示例/Usage Examples

### 模式 A: 新增问题/Mode A: New Questions

> "/ads-kb-eval docs/common/question-list.md"

→ 读取全部问题 → 去重 → 分类 → 路由评分 → 写入结果

> "评测 KB：召回双塔模型的训练范式是什么？"

→ 单题 → 路由到 §2.1 recall 文件 → 评分 → 写入结果

### 模式 B: 模块评测/Mode B: Module Eval

> "/ads-kb-eval 评测模块"

→ 列出全部模块及问题统计 → 用户两级选择 → 提取已有问题 → 重新评分 → 覆盖更新

> "评估 Chapter1 核心知识 - 2.1 召回"

→ 直接匹配 §2.1 → 提取 67 题 → 重新读取 KB 文件评分 → 覆盖更新

### Step 4: KB 文档优化/KB Doc Optimization

> Step 3 完成后提示"是否执行 Step 4 KB 文档优化？"

→ 用户选择"全部优化" → 对 12 个 KB 文件依次 spawn 子 agent 优化 → 重新评分 → 更新结果

> 优化前: 45 题非满分，平均 3.4 → 优化后: 12 题非满分，平均 4.7

---

## 硬规则/Hard Rules

1. **先评后写**: Step 2 先完成路由+评分，Step 3 再写入文件
2. **按主路由文件展开**: questions-list.md 按 `index-synthesis.zh-CN.md` §2 的 KB 文件组织
3. **评测结果内嵌**: questions-list.md 表格包含评分列（Score、Low Score Reason）
4. **单文件输出**: 评测结果仅写入 questions-list.md（历史对比通过 git diff 追溯）
5. **QID 不可变**: 问题 ID 一经分配永不变更
6. **不修改输入**: 不修改输入问题集文件
7. **重叠必告知**: 重叠问题必须列出告知用户（仅模式 A）
8. **不编造**: 评分必须基于实际文件内容，不基于模型自身知识
9. **非满分必有理由**: 分数非 5/5 时必须给出具体缺失内容和补充建议
10. **路由透明**: 报告中必须列出每个问题路由到的具体文件路径
11. **先 §2.1 再其他**: 路由时 Core Knowledge 优先
12. **批量效率**: 多个问题路由到同一文件时只读取一次
13. **双语同步**: `questions-list.md` 和 `questions-list.zh-CN.md` 必须同步更新
14. **分类先于路由**: 必须先完成分类，仅 kb 和指标查询类进入路由（仅模式 A）
15. **Task 类必须匹配技能**: 从 `03.skill-routing.md` 匹配具体技能命令（仅模式 A）
16. **范围拆分必须交互**: scope 过大检测结果必须呈现给用户确认（仅模式 A）
17. **指标查询双维度评分**: 必须同时评估"现状描述"和"查询方式"两个维度
18. **备注列占位**: 非 5/5 的行备注列填 `待处理`，5/5 或 N/A 填 `—`
19. **统计表必刷新**: 每次写入/更新表格内容后，运行 `uv run skills/common/ads-kb-eval/scripts/refresh_summary.py` 刷新统计表（不要手动计算）
20. **模块选择器必交互**: 模块选择必须通过 `AskUserQuestion` 让用户确认，不可自动选定（仅模式 B）
21. **优化前必确认**: Step 4 执行前必须通过 `AskUserQuestion` 获得用户确认，不可自动执行
22. **按文件分组优化**: 同一 KB 文件的所有非满分问题由同一个子 agent 统一处理，避免编辑冲突
23. **不编造补全**: 子 agent 只能基于文件已有内容做结构化扩展和补全，不可编造业务数据；无线索时标记为"需人工补充"
24. **优化后必重新评分**: KB 文件编辑完成后必须重新评分，不可假设优化后一定满分
25. **备注列标记优化状态**: 经过 Step 4 的问题，备注列标记为 `已优化`（达到 5/5 时改回 `—`，需人工时标 `需人工`）
