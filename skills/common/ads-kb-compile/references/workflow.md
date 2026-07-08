# Smart Merge Workflow/智能合并工作流

> Detailed rules for how `ads-kb-compile` merges input content into target files referenced in `index-synthesis.md`.
> This reference is read by the skill at runtime to guide the merge process.

---

## 0. Scope Resolution/范围解析

合并前先确定目标文件是否在写入范围内：

1. 读取 `references/mapping-rules.md` 的 **Excluded Targets** 表
2. 若目标文件路径匹配任一排除 Path Pattern → **跳过**，在报告中提醒用户使用对应工具
3. 根据目标文件所属 index Section 确定 **Target Type**（见 `mapping-rules.md` Target Type Adaptation 表）
4. 按 Target Type 调整下方 §1 结构对齐规则的应用方式

---

## 1. Structural Alignment/结构对齐

### 1.1 Heading Hierarchy/标题层级

> **适用范围**: 以下 single-H2 规则适用于 Core Knowledge (Section 2.1) 的 Atomic Notes。
> 对于其他 Target Type（DPM、How-To、SOP），标题层级遵循目标文件已有结构，不强制 single-H2 约束。
> 合并时以目标文件现有的标题层级为准，将输入内容映射到最近匹配的层级。

Atomic Notes follow a strict heading hierarchy:
- **H2** (`##`): Section number + title (e.g., `## 2.1 Recall Channels & Supply Strategy`)
- **H3** (`###`): Sub-topic (e.g., `### Product Card Recall`)
- **H4** (`####`): Detail point (e.g., `#### Queue Implementation`)
- **H5** (`#####`): Rarely used, for fine-grained breakdowns

**Rules**:
- Map each input section to the nearest matching heading level in the target
- If an input H3 matches an existing H3, merge content under that heading
- If no matching heading exists, append as a new sub-section at the appropriate level
- New H3 sections go after the last existing H3 under the same H2
- Never create a new H2 — each Atomic Note file has exactly one H2 (Core Knowledge only)

### 1.2 Table Alignment/表格对齐

Many target files contain Markdown tables. When merging:
- Identify the key column(s) (typically the first column)
- Match input table rows by key column value
- **Existing row + matching input**: Update cell values that differ; preserve unchanged cells
- **New input row**: Append to the bottom of the table
- **Existing row + no input match**: Preserve as-is (never delete)
- Preserve table column order and header formatting

---

## 2. Diff Classification/差异分类

For each piece of information in the input, classify it:

### 2.1 New Facts/新信息

**Definition**: Information present in input but absent from the target file.

**Action**:
- Append under the most relevant existing sub-section
- If no relevant sub-section exists, create a new H3/H4 heading
- Use the same formatting style as surrounding content (bullets, tables, prose)

### 2.2 Updated Facts/更新信息

**Definition**: Information that conflicts with or supersedes existing content.

**Action**:
- Replace the outdated statement with the new information
- If the update is significant (architectural change, strategy shift), add a brief note: `(Updated YYYY-MM-DD: <reason>)`
- If uncertain whether it's truly an update vs. a different perspective, flag to user

### 2.3 Redundant Facts/重复信息

**Definition**: Information already present in the target (same meaning, possibly different wording).

**Action**: Skip entirely — do not duplicate.

### 2.4 Ambiguous Facts/模糊信息

**Definition**: Cannot determine if new, updated, or redundant without domain expertise.

**Action**: Present to user via `AskUserQuestion` with both the input snippet and existing content, asking them to decide.

---

## 3. Preservation Rules/保留规则

These are **hard constraints** — never violate:

1. **Never remove existing headings** or reorder sections
2. **Never delete existing content** unless explicitly replacing an outdated fact
3. **Preserve all existing source references** (links, citations)
4. **Preserve image references** (`![alt](./img/...)`) — do not modify image paths
5. **Preserve code blocks** — do not modify existing code snippets
6. **Preserve the metadata header** (`> **Contributors**:` line) — only update contributors and date
7. **Preserve the Language line** (`> **Language**:`) — never modify

---

## 4. Preview Before Write/写入前预览

Before making any changes, present a structured preview to the user:

```markdown
## Merge Preview/合并预览

**Target file**: `docs/common/core-knowledge/02.ads-strategy/01.recall-and-supply-strategy.md`
**Counterpart**: `docs/common/core-knowledge/02.ads-strategy/01.recall-and-supply-strategy.zh-CN.md`

### Changes:
| Section | Change Type | Description | ~Lines |
|---|---|---|---|
| §2.1 > Product Card Recall | New content | Added queue priority algorithm description | +15 |
| §2.1 > Launch & Evaluation | Update | Updated A/B test buckets table | ~5 |
| §2.1 > New: Video Recall | New section | Added new H3 section for video ad recall | +25 |

### Conflicts (need confirmation):
- §2.1 > Queue Implementation: Input says "3 queues" but existing says "2 queues"

Proceed with merge? [Yes / Modify / Cancel]
```

Wait for user confirmation via `AskUserQuestion` before writing.

---

## 5. Bilingual Handling/双语处理

### 5.1 Language Detection/语言检测

Detect input language:
- **Chinese-dominant**: > 50% CJK characters → primary target is `.zh-CN.md` (or `_cn.md`)
- **English-dominant**: < 10% CJK characters → primary target is `.md` (or `_en.md`, `.EN.md`)
- **Mixed**: Both significant → ask user which is primary

### 5.2 Translation Strategy/翻译策略

After writing the primary language file:
1. Read the existing counterpart file
2. Identify which sections were modified in the primary
3. Generate translations for only those sections
4. Merge translations into the counterpart following the same structural alignment rules

> **部分目标文件无双语对应**（如 DPM `_en.md` 独立文件、SOP 单语文件）。
> 若目标文件没有对应的双语文件 → 跳过翻译步骤。
> 检测方法：查找同目录下是否存在 `.zh-CN.md`、`.EN.md`、`_cn.md`、`_en.md` 等后缀的对应文件。

**Translation guidelines**:
- Keep technical terms consistent with existing translations in the file
- Domain-specific terms use bilingual format: `Recall (召回)`, `pGMV (预估GMV)`
- Do not translate proper nouns: Shopee, UniCR, BEM, GmvMax, etc.
- Tables: translate cell content but preserve structure
- Code blocks and URLs: never translate

---

## 6. Metadata Update/元数据更新

After successful merge, update the metadata line in both files:

```markdown
> **Contributors**: <current_user>, <prev_1>, <prev_2> ｜ **最后更新**：YYYY-MM-DD ｜ [GitLab](...)
```

- Add current user to front of Contributors list
- Keep max 3 contributors; drop the oldest if exceeding
- Update date to today
- Do not change the GitLab link

---

## 7. Git Change Mode/Git 变更模式特殊规则

当输入形式为 Git 变更时，以下特殊规则生效：

### 7.1 监控范围/Monitored Paths

Git 变更模式不仅扫描 `docs/`，还包括以下目录和文件：

| 路径 | 说明 | 变更处理方式 |
|------|------|-------------|
| `docs/` | 知识文档 | index 目标 → 直接编辑检测；非 index → 作为输入 compile |
| `skills/common/` | 共享技能 | 提取新增/变更的能力描述，映射到对应知识文档 |
| `guides/common/` | 技能使用指南 | 提取新增/变更的使用说明，映射到对应知识文档 |
| `scripts/` | 仓库级脚本 | 提取新增/变更的工具说明，映射到对应知识文档 |
| `templates/` | 模板文件 | 提取新增/变更的模板规范，映射到对应知识文档 |
| `CLAUDE.md` / `.zh-CN.md` | 项目指令 | 提取新增/变更的规范和约定，映射到对应知识文档 |
| `CLAUDE.local.md` / `.zh-CN.md` | 个人项目指令 | 同上 |
| `AGENTS.md` | Agent 定义 | 提取新增/变更的 agent 说明 |
| `README.md` / `.zh-CN.md` | 仓库 README | 提取仓库级变更说明 |

### 7.2 直接编辑检测/Direct Edit Detection

当 git 变更文件本身就是 index 中的目标文件时：
- **不执行合并**（文件已是最新状态）
- **仅更新 index-synthesis** 对应行：刷新 Summary、Last Updated、Updated By 列
- 生成 Summary 的方法：读取文件内容，用 H2/H3 标题 + 关键信息提取一句话摘要

### 7.3 非 docs 文件处理/Non-docs File Handling

`skills/common/`、`guides/common/`、`scripts/`、`templates/`、根目录配置文件的变更：
- 不做 index 交集过滤（这些文件不在 index-synthesis 表中）
- 读取变更文件内容，按 Step 2-3 主题识别和映射到对应的知识文档
- 典型映射：skill SKILL.md 变更 → 对应的 `guides/common/` 指南或 How-To 文档

### 7.4 批量处理顺序/Batch Processing Order

多文件变更时按以下顺序处理：
1. 先处理「目标文件直接编辑」类 → 快速更新 index
2. 再处理「技能/指南/脚本/模板变更」类 → 映射到知识文档后 compile
3. 再处理「输入源文件变更」类 → 完整 compile 流程（Step 1-6）
4. 最后统一更新 index-synthesis Section 1 活跃度统计

### 7.5 变更粒度/Change Granularity

- 默认读取整个变更文件作为输入（不做 diff 级别的增量）
- 对于大文件（>500 行），提示用户是否只处理变更部分

### 7.6 目录扫描同步/Directory Scan Sync

每次 compile 完成后，Step 7 执行目录扫描以保持 index-synthesis 与实际文件同步：

1. **扫描范围**：读取 §1 Overview 表的「目录路径」列，对每个目录执行 `Glob` 扫描（`**/*.md`，排除 `README*`）
2. **比对逻辑**：
   - 提取 §2 对应子节表格中所有「文件路径/File Path」列的值，还原为仓库相对路径
   - 将实际文件列表与表格文件列表做集合差异：
     - **新文件**（目录有、表格无）→ 读取文件前 50 行提取 H1/H2 标题生成摘要，用 `git log -1` 获取更新时间和作者，在 §2 表格末尾插入新行
     - **已删除文件**（表格有、目录无）→ 用 `Edit` 从 §2 表格中移除该行
     - **已有文件** → 不动
3. **双语文件配对**：扫描时按目录的双语约定过滤，同一文件的中英文版本分别列入对应语言的索引：
   - Core Knowledge / SOPs: `.md` ↔ `.zh-CN.md` → ZH 索引列 `.zh-CN.md`，EN 索引列 `.md`
   - DPM: `_en.md` ↔ `_cn.md` → 各自列入对应语言索引
   - How-Tos: `.md` ↔ `.EN.md` → ZH 索引列 `.md`，EN 索引列 `.EN.md`
4. **§1 文件数同步**：重新统计各目录的文件数（`find <dir> -name "*.md" ! -name "README*" | wc -l`），更新 §1 表格的「文件数」列和合计行
5. **报告格式**：

```
Index Sync:
- §2.1 Core Knowledge: +2 new, -0 removed (50 → 52)
- §2.5 How-Tos: +1 new, -0 removed (64 → 65)
- §1 file counts updated
```
