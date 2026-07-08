# Ads KB Compile (ads-kb-compile) 使用指南

> **Language**: [English](ads-kb-compile.md) | [中文](ads-kb-compile.zh-CN.md)

读取输入文档（本地 Markdown、Google Docs、内联文本或 workspace git 变更），匹配 `index-synthesis.md` 中引用的目标文件，智能合并增量信息并更新双语版本和索引。

**触发关键词**: "kb-compile", "知识入库", "编译知识", "compile to kb", "merge into knowledge base", "sync to core-knowledge", "入库到知识库", "ads-kb-compile", "git changes compile", "recent changes", "最近改动入库", "git 变更入库"

---

## 技能文件

| 文件 | 描述 |
|------|------|
| `SKILL.md` | 主技能定义，包含编译工作流（Step 1-7 + Step 1.5 Git 模式） |
| `references/mapping-rules.md` | 写入范围、排除目标、章节到文件的映射表、匹配算法、目标类型适配 |
| `references/workflow.md` | 范围解析、智能合并规则、差异分类、双语处理、Git 变更模式规则 |

---

## 前提条件

| 依赖 | 类型 | 用途 |
|------|------|------|
| `docs/common/index-synthesis.md` | 本地文件 | 主索引，用于映射输入到目标文件 |
| 目标目录 | 本地目录 | `index-synthesis.md` Section 2 中引用的所有目录 |
| `mcp__google-drive` | MCP 服务 | 输入为 Google Doc 时需要 |

---

## 写入范围

本 skill 可修改 `index-synthesis.md` Section 2 中引用的所有文件，**除非**该目录在 `references/mapping-rules.md` 的 Excluded Targets 表中被明确标注为排除。

当前排除项：
- `docs/common/readme/` → 使用 `ads-readme-generate`
- `docs/common/datamap/` → 使用 `sra-table-info-query`

其余索引文件（Core Knowledge、DPM、How-Tos、SOPs）均可写入。

---

## 使用方法

### 场景 1: 本地 Markdown 文件入库

> "把 `docs/personal/luka.yang/notes/new-recall-channel.md` 编译入库到知识库"

技能读取文件，识别 recall 领域，映射到 §2.1，合并到 `core-knowledge/02.ads-strategy/01.recall-and-supply-strategy.md` 并同步更新双语版本。

### 场景 2: Google Docs 入库

> "Compile this Google Doc into the KB: https://docs.google.com/document/d/1abc.../edit"

技能通过 MCP 读取 Doc，识别主题，映射到目标文件，合并并更新索引。

### 场景 3: Sub-KB 内容整合

> "把 `docs/common/sub-kb/2.1-recall/kb.md` 的内容 compile 到 core-knowledge"

技能将 sub-kb 文件作为输入读取，映射到对应的 core-knowledge 文件，智能合并并去重。

### 场景 4: 多章节文档

> "这个文档涵盖了召回和出价两部分，请入库"

技能按章节边界拆分输入，各段独立映射到对应文件，逐个合并。

### 场景 5: Git 变更入库

> "把最近 7 天的变更编译入库"

技能运行 `git log --since="7 days ago"` 扫描 `docs/`、`skills/common/`、`guides/common/`、`scripts/`、`templates/` 及根目录配置文件（`CLAUDE.md`、`README.md` 等），过滤范围内文件，分类处理（直接编辑 vs 技能/指南变更 vs 源文件变更）：直接编辑的文件仅刷新 index 行，其他变更走完整 compile 流程。

### 场景 6: 跨 Section 入库

> "把 DPM 的 deduction module 相关概念 compile 到核心知识"

技能读取 DPM deduction 文档，提取概念性内容，映射到 core-knowledge §5.4 合并 — 实现细节保留在 DPM 原文件。

---

## 工作流概览

1. **解析输入** — 读取本地 .md、Google Doc、内联文本或发现 git 变更；检测语言
2. **Git 变更发现** *（仅 git 模式）* — 运行 git log 扫描 `docs/`、`skills/common/`、`guides/common/`、`scripts/`、`templates/` 及根目录配置文件，过滤范围，分类变更，用户确认
3. **主题识别** — 分析领域关键词、章节引用、标题
4. **映射目标** — 通过映射表匹配（core-knowledge）或索引路径匹配（其他 Section）
5. **读取现有内容** — 读取目标文件和双语对应文件
6. **智能合并** — 范围检查、差异分类（新增/更新/重复），预览确认
7. **写入更新** — 合并主语言，存在对应文件时生成翻译，更新元数据
8. **更新索引** — 刷新 index-synthesis Section 2.x 对应行和 Section 1 覆盖统计

---

## 输出格式

编译完成后，技能输出结构化报告，包括：
- 处理的输入源
- 更新的目标文件及行数变化
- 直接编辑的文件（已刷新 index）
- 修改的章节
- 更新的索引统计
- 跳过的文件（排除目标）及推荐工具

---

## 相关技能

| 技能 | 何时使用 |
|------|---------|
| `ads-knowledge-qa` | 查询现有知识（只读） |
| `ads-readme-generate` | 自动生成代码仓库 README（本 skill 排除范围） |
| `sra-table-info-query` | 构建 Hive 表元数据 DataMap（本 skill 排除范围） |
| `ads-workspace-gdoc-sync` | 将 Markdown 同步到 Google Drive（反方向） |
| `ads-okr-memory-update` | 将会话笔记写入项目/个人记忆 |
| `ads-okr-memory-sync` | 将记忆文件同步到项目 epic 文件 |
