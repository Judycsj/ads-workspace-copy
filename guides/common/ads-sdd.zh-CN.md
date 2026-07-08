# ads-sdd 技能使用指南 / ads-sdd Skill Guide

> **Contributors**: luka.yang ｜ **最后更新**：2026-07-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-sdd.zh-CN.md)

`ads-sdd` 是 Spec-Driven Development 工具链。覆盖从 spec 目录创建到实现生成的完整生命周期，同时支持通过 Delta Spec（propose → apply → archive）进行结构化增量变更。

---

## 前提条件 / Prerequisites

- 工作目录为 `ads-workspace` 根目录
- `init`：目标 domain 尚无 spec 目录
- `spec` / `review` / `implement`：domain 目录下至少有 `01-scope-and-workflow.md` 和 `02-*.md`
- `propose` / `apply` / `archive`：已有完成的全量 spec

---

## 何时使用 / When to use

| Mode | 使用场景 |
| --- | --- |
| `init` | 新模块/系统起步——需要创建 spec 目录骨架 |
| `spec` | 为已有 domain 添加组件 spec 或跨组件契约 |
| `review` | 实现前或编辑后检查结构完整性 |
| `implement` | 从 spec 生成 SKILL.md / 代码 / 文档模板（全量构建或 diff 增量） |
| `propose` | 规划结构化变更——创建带 ADDED/MODIFIED/REMOVED/RENAMED 标记的 delta spec |
| `apply` | 将审核通过的 delta spec 合并进全量 spec |
| `archive` | 实现完成后将已应用的变更归档到 `changes/archive/` |

---

## 快速开始 / Quick Start

```
/ads-sdd init my-domain --type skill      # 创建 spec 目录骨架
/ads-sdd spec my-domain/my-component      # 为组件编写 spec
/ads-sdd spec my-domain/shared --contract # 编写跨组件契约
/ads-sdd review my-domain                 # 校验 spec 结构完整性
/ads-sdd implement my-domain              # 从 spec 生成实现
/ads-sdd implement my-domain --diff       # 从 spec diff 增量更新实现
/ads-sdd propose my-domain/change-name    # 创建 delta spec 变更提案
/ads-sdd apply my-domain/change-name      # 将 delta 合并进全量 spec
/ads-sdd archive my-domain/change-name    # 归档已应用的变更
```

---

## 两种增量变更路径 / Two Incremental Change Paths

- **路径 A（Spec-Diff）**：直接编辑全量 spec 文件，通过 `implement --diff` 用 git diff 传导变更。适合快速、小范围修改。
- **路径 B（Delta Spec）**：先 `propose` 创建结构化 delta spec，再 `apply` 合并到全量 spec，最后 `implement --diff` 生成实现。适合需要 review 的多文件变更。

---

## 使用建议 / Tips

- Spec 存放在 `specs/common/{domain}/`——这是权威源（Layer 1）
- SKILL.md 使用 **Pointer + Lazy-Load** 模式——声明 spec 路径，运行时按需读取
- SKILL.md body 必须 **≤ 500 行**；超出部分拆到 `references/`
- Delta spec 使用 `delta-` 前缀，不占主编号序列
- 先 `propose` 再 `apply`——apply 要求 change 目录下已有 delta 文件
- 先 `apply` 再 `archive`——archive 要求存在 `.applied` 标记
