# {component-name} Spec

> {一句话定位：本文件是 X 组件行为的权威规约}

**权威依赖**：核心概念见 [`02-{foundational}.md`](./02-{foundational}.md)，工作流见 [`01-scope-and-workflow.md`](./01-scope-and-workflow.md)。本文件不重复定义 {shared concepts}，仅定义 {component} 的 {specific behavior}。

---

## {N}.1 组件目标/Component Objective

{一段话描述组件职责边界：做什么、不做什么}

| 项 | 内容 |
| --- | --- |
| 阶段 | {lifecycle phase} |
| 输入 | {what it consumes} |
| 输出 | {what it produces} |
| 上游 | {upstream component/skill} |
| 下游 | {downstream component/skill} |
| 必须执行 | {mandatory checks/rules} |
| 必须避免 | {anti-patterns} |

## {N}.2 输入契约/Input Contract

支持以下输入组合：

| 输入 | 组件重点 |
| --- | --- |
| {input-A} | {what the component does with it} |
| {input-A + input-B} | {what the component does with both} |

**解析规则/Parsing Rules**：

- {rule 1}
- {rule 2}

## {N}.3 输出契约/Output Contract

{描述输出格式}

**必需字段/Required Fields**：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| {field-1} | {type} | {description} |
| {field-2} | {type} | {description} |

**输出格式示例/Output Format Example**：

```text
{example output}
```

## {N}.4 执行流程/Execution Flow

1. **{Step 1 Name}**：{description}
2. **{Step 2 Name}**：{description}
3. **{Step 3 Name}**：{description}
4. **{Step 4 Name}**：{description}

## {N}.5 规则执行/Rule Enforcement

| 规则 | 检查时机 | 失败处理 |
| --- | --- | --- |
| {rule-1} | {when to check} | {what to do on failure} |
| {rule-2} | {when to check} | {what to do on failure} |

<!-- 按需展开每条规则的详细定义 -->

### Rule {X}: {Rule Name}

{规则详细描述}

**正例/Positive Example**：

```text
{good example}
```

**反例/Negative Example**：

```text
{bad example}
```

## {N}.6 上下游契约/Upstream-Downstream Contract

<!-- 可选：定义本组件对上下游的承诺 -->

**对上游的要求/Requirements from Upstream**：

- {requirement}

**对下游的承诺/Promises to Downstream**：

- {promise}

## {N}.7 变更护栏/Change Guardrails

<!-- 可选：修改本 spec 时需要同步变更的文件 -->

| 修改内容 | 需同步 |
| --- | --- |
| {what changes} | {files/components to update} |
