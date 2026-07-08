# {Domain} Scope and Workflow

> {一句话定位：本文件是 X 的工作流和技能接口的权威来源}

---

## 1.1 权威边界/Authority Boundary

{Domain} 采用三层架构：

```text
Layer 1: Skill Knowledge (本目录)
    定义 {concepts/models/contracts}
    -> 引用
Layer 2: {Skills / 代码实现}
    实现层，引用 Layer 1 获取规则和契约
    -> 引用
Layer 3: {Guides / Templates / 用户文档}
    面向用户的指南和模板
```

**修改传导规则**：任何规则变更必须先进入 Layer 1，再向 Layer 2、Layer 3 传导。Layer 2/3 不应引入 Layer 1 未定义的规则或概念。

**信息管理原则**：

- **单一权威来源**：每个概念只在一处定义
- **引用优于复制**：实现层引用 spec 文件，不内联复制大段定义
- **受控例外**：自包含场景（如 Bot Agent）可受控复制规则，但必须声明权威源

## 1.2 人视角生命周期/Human Workflow Lifecycle

{描述端到端生命周期，分为 N 个阶段}：

```text
{起点}
    -> [{阶段 1}] {描述产出}
    -> [{阶段 2}] {描述产出}
    -> [{阶段 N}] {描述产出}
```

<!-- 各阶段详细说明（按需） -->

## 1.3 工具/技能链路/Tool Workflow Chain

```text
{起点} --> [{tool/skill 1}] --> {产出文件/数据}
                                    |
                             [{tool/skill 2}]
                                    |
                             {产出文件/数据}
                                    |
                         +----------+----------+
                         |                     |
              [{tool/skill 3}]      [{tool/skill 4}]
              {产出}                {产出}
```

<!-- ASCII art 展示工具/技能之间的数据流 -->

## 1.4 组件接口/Component Interfaces

| 组件/技能 | 阶段 | 输入 | 输出 | 上游 | 下游 | 适用规则 |
| --- | --- | --- | --- | --- | --- | --- |
| {component-1} | {stage} | {input} | {output} | {upstream} | {downstream} | {rules} |
| {component-2} | {stage} | {input} | {output} | {upstream} | {downstream} | {rules} |

## 1.5 未覆盖阶段与外部依赖/Uncovered Stages and External Dependencies

<!-- 可选：记录当前未被工具/技能覆盖的生命周期阶段，以及与外部系统的交互 -->

| 阶段/外部系统 | 说明 | 当前状态 |
| --- | --- | --- |
| {uncovered-stage} | {description} | {manual / planned / N/A} |
