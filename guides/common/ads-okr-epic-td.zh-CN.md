# Epic TD 文档生成与审查（ads-okr-epic-td）使用指南

> **语言**：[English](ads-okr-epic-td.md) | [中文](ads-okr-epic-td.zh-CN.md)

KP owner 使用。从 OKR KP 上下文出发，按模板章节从上到下逐步推理讨论：背景目标 → 可行性分析（推导出 KA 列表）→ 实现方案（细化每个 KA）→ 时间线，生成或审查 Epic TD 文档。

**唤醒词**：「epic td」、「epic 文档」、「td 文档」、「ads-okr-epic-td」、「生成 td」、「写 epic」、「check epic td」、「审查 td」、「拆解 KA」、「KA 拆解」、「分解 KP」、「KP 拆解为 KA」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含生成/审查工作流和 KA 质量规则 |
| `templates/doc-template/epic-file-202xQx-Ox-KRx-KPx-epicTitle.md` | Epic TD 模板，含四种 KP 类型条件引导 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| OKR GSheet | 数据 | 读取 KP 元信息（标题、Why Do、交付目标） |
| Google Drive MCP | 工具 | 创建 Epic TD Google Doc |

---

## 使用场景

### 模式 1：生成 Epic TD（默认）

```
/ads-okr-epic-td [--kp "Ox-KRy-KPz"]
```

多轮对话工作流：
1. **Step 1**：收集 KP 元信息（编号、来源、类型、季度、标题）
2. **Step 2**：讨论章节一 — 项目背景和目标（KB Summary → 背景 → 验收标准 → 非目标）
3. **Step 3**：讨论章节二 — 可行性分析（分析思路 → 分析方案设计 → 方案思路 → **推导 KA 列表**）
4. **Step 4**：讨论章节三 — 实现方案和落地实施（系统现状 → 方案设计 → 示例 → 验证方案）
5. **Step 5**：生成章节四 — 项目时间线（每个 KA 分配 owner 和 deadline）
6. **Step 6-8**：完整性检查 → 创建 Google Doc + 本地 MD → 输出后续步骤

### 模式 2：审查已有 Epic TD

```
/ads-okr-epic-td --check <doc_url_or_path>
```

检查章节完整性、KA 质量（规则 1/3/5/6）、按 KP 类型检查内容质量、命名规范。

### KP 类型

| 类型 | 英文 | 适用场景 |
|------|------|----------|
| greenfield | 从无到有 | 构建当前不存在的能力或系统 |
| problem-driven | 问题驱动 | 解决已知问题或痛点 |
| incremental | 精益求精 | 在已运行系统上做边际优化 |
| refactor | 系统重构 | 统一/迁移/解耦分散或耦合的系统 |

---

## 相关 Skill

| Skill | 用途 |
|-------|------|
| `/ads-okr-planner` | 上游：KR→KP 规划（KR owner 使用） |
