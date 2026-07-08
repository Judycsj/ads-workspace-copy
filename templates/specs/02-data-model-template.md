# {System} Data Model

> {一句话定位：定义 X 系统的数据模型和接口契约}

**权威依赖**：系统范围和工作流见 [`01-scope-and-workflow.md`](./01-scope-and-workflow.md)。

---

## {N}.1 Schema 概览/Schema Overview

<!-- 描述系统的数据存储和核心 schema -->

**数据存储**：{description of where data lives — Proto files, JSON schema, database tables, etc.}

**核心 schema 文件**：

| 文件/路径 | 用途 | 格式 |
| --- | --- | --- |
| {path-1} | {purpose} | {Proto / JSON / SQL DDL} |
| {path-2} | {purpose} | {format} |

## {N}.2 实体定义/Entity Definitions

<!-- 逐个定义核心实体 -->

### {Entity A}

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| {field-1} | {type} | {yes/no} | {description} |
| {field-2} | {type} | {yes/no} | {description} |

**约束/Constraints**：

- {constraint description}

### {Entity B}

<!-- 同上格式 -->

## {N}.3 状态机/State Machine

<!-- 如果系统有状态流转 -->

**状态枚举/State Enum**：

| 状态 | 值 | 含义 | 进入条件 |
| --- | --- | --- | --- |
| {state} | {value} | {meaning} | {entry condition} |

**转换规则/Transition Rules**：

```text
{state-A} -> {state-B}    条件：{condition}
```

## {N}.4 API 契约/API Contracts

<!-- 定义系统对外的接口 -->

### {API / RPC / Event}

| 项 | 内容 |
| --- | --- |
| 路径/方法 | {endpoint or RPC method} |
| 请求 | {request fields} |
| 响应 | {response fields} |
| 错误 | {error codes and handling} |

## {N}.5 消费者矩阵/Consumer Matrix

<!-- 可选：哪些下游消费哪些字段 -->

| 字段 | {Consumer A} | {Consumer B} | {Consumer C} |
| --- | --- | --- | --- |
| {field-1} | R | R/W | - |
| {field-2} | R | - | R |

## {N}.6 字段参考/Field Reference

<!-- 可选：完整字段表，适用于复杂 schema -->

| 字段路径 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| {path.to.field} | {type} | {default} | {description} |
