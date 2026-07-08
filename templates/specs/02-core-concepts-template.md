# {Domain} Core Concepts

> {一句话定位：定义 X 领域的核心模型和共享概念}

**权威依赖**：领域范围和工作流见 [`01-scope-and-workflow.md`](./01-scope-and-workflow.md)。

---

## {N}.1 层级模型/Hierarchy Model

<!-- 定义领域的核心层级结构 -->

| 层级 | 含义 | 产出物 | 关键问题 |
| --- | --- | --- | --- |
| {Level 1} | {description} | {artifact} | {key question} |
| {Level 2} | {description} | {artifact} | {key question} |
| {Level 3} | {description} | {artifact} | {key question} |

## {N}.2 类型体系/Type System

<!-- 定义领域的分类枚举 -->

| 类型 | 含义 | 适用场景 | 影响 |
| --- | --- | --- | --- |
| {type-1} | {description} | {when to use} | {impact on downstream} |
| {type-2} | {description} | {when to use} | {impact on downstream} |

## {N}.3 状态模型/State Model

<!-- 定义状态机：状态枚举 + 转换规则 -->

**状态枚举/State Enum**：

| 状态 | 含义 | 进入条件 | 退出条件 |
| --- | --- | --- | --- |
| {state-1} | {description} | {entry condition} | {exit condition} |
| {state-2} | {description} | {entry condition} | {exit condition} |

**状态转换规则/Transition Rules**：

<!-- 描述哪些状态转换合法，哪些不合法 -->

```text
{state-1} -> {state-2}    合法：{condition}
{state-2} -> {state-3}    合法：{condition}
{state-3} -> {state-1}    非法：{reason}
```

## {N}.4 评估/计算模型/Evaluation Model

<!-- 可选：定义评分标准、计算规则、优先级等 -->

| 维度 | 规则 | 说明 |
| --- | --- | --- |
| {dimension-1} | {rule} | {explanation} |
| {dimension-2} | {rule} | {explanation} |

## {N}.5 术语表/Glossary

<!-- 可选：领域特定术语的明确定义 -->

| 术语 | 定义 | 示例 |
| --- | --- | --- |
| {term} | {definition} | {example} |
