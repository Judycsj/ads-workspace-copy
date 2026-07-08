# OKR 规划助手（ads-okr-planner）使用指南

> **语言**：[English](ads-okr-planner.md) | [中文](ads-okr-planner.zh-CN.md)

KR owner 使用。给定 KR 拆解为 KP，或审查 KR/KP 内容质量。不负责 KA 拆解（KA 由 KP owner 通过 `/ads-okr-epic-td` 完成）。

**唤醒词**：「okr planner」、「okr 规划」、「拆解 KR」、「KP 拆解」、「ads-okr-planner」、「KP 质量」、「check KP」、「审查 KP」、「审查 OKR」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含生成/审查/精化三种模式和 KP 质量规则 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| OKR GSheet | 数据 | 读写 KR/KP 数据 |
| Google Drive MCP | 工具 | 读取 Epic File Link 提取 KA |

---

## 使用场景

### 模式 1：从 KR 生成 KP（默认）

```
/ads-okr-planner
```

多轮对话，将 KR 按 SOP 质量规则拆解为 KP。

### 模式 2：审查 KR/KP 质量

```
/ads-okr-planner --check [rowX]
```

审查指定 GSheet 行的内容质量，从 Epic File Link 提取 KA 写回 D 列。

### 模式 3：单 KP 精化

```
/ads-okr-planner --refine <KP>
```

对单个 KP 做质量审查和知识增强精化。

---

## 相关 Skill

| Skill | 用途 |
|-------|------|
| `/ads-okr-epic-td` | 下游：KP→KA 拆解（KP owner 使用） |
