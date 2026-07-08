---
name: ads-kb-compile
description: >
  Ads KB Compile (知识库编译入库) — read input from local Markdown, Google Docs,
  inline text, or workspace git changes, map to target files referenced in
  index-synthesis.md, smart-merge incremental content, update bilingual
  counterparts and index.
  TRIGGER when: user mentions "kb-compile", "知识入库", "编译知识", "compile to kb",
  "merge into knowledge base", "sync to core-knowledge", "入库到知识库",
  "ads-kb-compile", "git changes compile", "recent changes", "最近改动入库",
  "git 变更入库".
  DO NOT TRIGGER when: answering Ads questions (use ads-knowledge-qa),
  syncing markdown to Google Drive (use ads-workspace-gdoc-sync),
  or updating project/personal memory (use ads-okr-memory-update / ads-okr-memory-sync).
category: knowledge
tags: [knowledge, compile, merge, bilingual, atomic-notes, git-changes]
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - mcp__google-drive__readGoogleDoc
  - mcp__google-drive__getGoogleDocContent
---

# Ads KB Compile/知识库编译入库

读取输入文档（本地 Markdown、Google Docs、内联文本或 workspace git 变更），匹配 `index-synthesis.md` 中引用的目标文件，智能合并增量信息并更新双语版本和索引。

---

## 前提条件/Prerequisites

| 条件 | 说明 |
|------|------|
| Index 文件 | `docs/common/index-synthesis.md` 和 `.zh-CN.md` 存在 |
| 目标目录 | `index-synthesis.md` Section 2 中引用的目标目录存在 |
| Google Drive MCP | 当输入为 Google Doc 时需要 `mcp__google-drive` 可用 |

### 修改范围/Scope

本 skill 可修改 `index-synthesis.md` Section 2 中引用的所有文件，**除非**该目录在 `references/mapping-rules.md` 的 Excluded Targets 表中被明确标注为排除。

当前排除项：
- `docs/common/readme/` → 使用 `ads-readme-generate`
- `docs/common/datamap/` → 使用 `sra-table-info-query`

输入中属于被排除目录的内容会被跳过，并在报告中提醒用户使用对应工具。

---

## 启动前/Before First Use

读取以下参考文件以了解详细规则：

1. [references/mapping-rules.md](references/mapping-rules.md) — 写入范围、排除目标、章节到文件的映射表和匹配算法、目标类型适配
2. [references/workflow.md](references/workflow.md) — 范围解析、智能合并的详细规则、Git 变更模式

---

## 工作流/Workflow

### Step 1: 解析输入/Parse Input

接受以下输入形式：

- **本地 Markdown 文件**: 用户提供文件路径 → `Read` 工具读取
- **Google Doc**: 用户提供 URL 或 Doc ID → 提取 ID，用 `mcp__google-drive__readGoogleDoc(format: "markdown")` 读取
- **内联文本**: 用户直接在消息中粘贴内容
- **Sub-KB 文件**: `docs/common/sub-kb/` 下的文件也可作为输入，其内容将被 compile 到对应的目标文件
- **Git 变更**: 用户指定时间范围（如 "last 7 days"、"since 2026-05-20"）或分支名 → 进入 Step 1.5 Git Change Discovery

**语言检测**: 判断输入是中文为主、英文为主还是混合。

### Step 1.5: Git 变更发现/Git Change Discovery（仅 Git 变更模式）

当输入形式为 Git 变更时：

1. **获取变更文件列表**:
   ```bash
   git log --since="<user-specified-date>" --name-only --pretty=format:"" -- \
     'docs/' 'skills/common/' 'guides/common/' 'scripts/' 'templates/' \
     'AGENTS.md' 'CLAUDE.md' 'CLAUDE.zh-CN.md' 'CLAUDE.local.md' 'CLAUDE.local.zh-CN.md' \
     'README.md' 'README.zh-CN.md' \
     | sort -u | grep -v '^$'
   ```
   若用户指定分支名，改用：
   ```bash
   git diff --name-only <base-branch>...HEAD -- \
     'docs/' 'skills/common/' 'guides/common/' 'scripts/' 'templates/' \
     'AGENTS.md' 'CLAUDE.md' 'CLAUDE.zh-CN.md' 'CLAUDE.local.md' 'CLAUDE.local.zh-CN.md' \
     'README.md' 'README.zh-CN.md'
   ```

   **监控目录/文件完整列表**：

   | 路径 | 说明 |
   |------|------|
   | `docs/` | 所有知识文档（core-knowledge、DPM、How-Tos、SOPs 等） |
   | `skills/common/` | 共享技能定义（SKILL.md、references/、scripts/） |
   | `guides/common/` | 共享技能使用指南 |
   | `scripts/` | 仓库级脚本（validate、sync、install 等） |
   | `templates/` | 文档和技能模板 |
   | `CLAUDE.md` / `CLAUDE.zh-CN.md` | 项目指令（双语） |
   | `CLAUDE.local.md` / `CLAUDE.local.zh-CN.md` | 个人项目指令（双语） |
   | `AGENTS.md` | Agent 定义文件 |
   | `README.md` / `README.zh-CN.md` | 仓库 README（双语） |

2. **过滤范围内文件**:
   - 读取 `index-synthesis.md` Section 2 所有表格，提取所有 File Path 列的值（还原为仓库相对路径）
   - 对于 `docs/` 下的文件：将 git 变更文件列表与 index scope 取交集
   - 对于非 `docs/` 目录的文件（skills/common/、guides/common/、scripts/、templates/、根目录文件）：直接纳入变更列表，不做 index 交集过滤
   - 排除 Excluded Targets 中匹配的文件（见 `references/mapping-rules.md`）
   - 排除 index-synthesis 本身

3. **分类变更文件**:
   - **目标文件直接编辑**: 变更文件本身就是 index 中的目标文件 → 跳过合并，仅更新 index 行（见 `references/workflow.md` §7.1）
   - **技能/指南/脚本/模板变更**: 变更文件在 `skills/common/`、`guides/common/`、`scripts/`、`templates/` 或根目录配置文件 → 作为输入，尝试映射到对应的 core-knowledge 或 index 目标文件
   - **输入源文件变更**: 变更文件在 `docs/` 下但不在 index 目标列表中（如 sub-kb 文件）→ 作为输入执行完整 compile 流程
   - **新文件**: 变更文件不属于以上任何分类 → 提示用户是否需要加入 index 或作为输入 compile

4. **展示变更摘要**:
   用 `AskUserQuestion` 展示发现的文件列表（分三类），让用户确认要处理哪些文件

5. 确认后按批量处理顺序执行（见 `references/workflow.md` §7.2）：
   - 先处理「目标文件直接编辑」→ 快速更新 index
   - 再对每个「输入源文件变更」执行 Step 2-6

### Step 2: 主题识别/Topic Identification

分析输入内容，识别：
- 领域关键词（recall, bidding, voucher, engine 等）
- 章节引用（§X.Y 或 Section X.Y）
- H2/H3 标题与已知结构的映射关系

### Step 3: 映射目标文件/Map to Target Files

1. 读取 `docs/common/index-synthesis.md` Section 2（全部子节 2.1-2.6）
2. 读取 `references/mapping-rules.md` 获取完整映射表、排除目标和**目标类型适配**规则
3. 按优先级匹配（见 `references/mapping-rules.md` Matching Algorithm）：
   - **显式章节号**: §X.Y → 直接匹配（仅 Core Knowledge）
   - **文件路径匹配**: 输入文件路径与 index 中目标文件匹配 → 直接定位（所有 Section）
   - **标题匹配**: 输入 H2/H3 标题 → 目标文件 H2 标题
   - **关键词匹配**: 统计各章节关键词命中数 → 命中最多的章节（仅 Core Knowledge）
4. **多章节输入**: 按 H2/H3 边界拆分，各段独立映射
5. **歧义处理**: 如前 2 名命中数相近，用 `AskUserQuestion` 让用户选择
6. **范围过滤**: 目标文件在 Excluded Targets 中的 → 跳过并在报告中提醒

**目标文件可在 index-synthesis Section 2 引用的任何非排除目录下。**

### Step 4: 读取现有内容/Read Existing Content

对每个匹配的目标文件：
1. 读取主语言文件
2. 查找并读取双语对应文件（若存在）
3. 解析标题层级（H2 → H3 → H4）
4. 记录各子章节的内容边界

### Step 5: 智能合并/Smart Merge

按 `references/workflow.md` 中的规则执行合并：

#### 5a. 范围解析
- 检查目标文件是否在 Excluded Targets 中（§0）
- 确定 Target Type 并适配结构对齐规则

#### 5b. 结构对齐
- 将输入的标题层级映射到目标文件的标题层级
- 匹配现有子章节 → 合并到该章节
- 无匹配 → 在合适位置创建新子章节

#### 5c. 差异分类
- **新信息**: 输入有、目标无 → 追加到对应子章节
- **更新信息**: 与现有内容冲突 → 替换并标注更新原因
- **重复信息**: 目标已有 → 跳过
- **模糊信息**: 无法判断 → 用 `AskUserQuestion` 让用户决定

#### 5d. 保留规则（硬约束）
- 绝不删除现有标题或重排章节顺序
- 保留现有表格结构（按 key 列匹配行，新行追加到底部）
- 保留所有现有引用链接和图片引用
- 保留代码块不变

#### 5e. 预览确认
写入前向用户展示结构化预览：

```
## 合并预览

**目标文件**: `core-knowledge/02.ads-strategy/01.recall-and-supply-strategy.md`
**双语对应**: `...01.recall-and-supply-strategy.zh-CN.md`

| 章节 | 变更类型 | 说明 | 预估行数 |
|------|---------|------|---------|
| §2.1 > Product Card Recall | 新增内容 | 添加队列优先级算法描述 | +15 |
| §2.1 > New: Video Recall | 新增章节 | 视频广告召回 H3 章节 | +25 |

超出范围（已跳过）：
| 内容 | 建议工具 |
|------|---------|
| DAG 节点配置与参数（15 行） | ads-readme-generate → paidads-recall README |

冲突（需确认）：...
```

用 `AskUserQuestion` 确认后才执行写入。

### Step 6: 写入更新/Write Updates

1. **先写主语言**: 根据输入语言写入对应的文件
2. **生成对应语言**: 若目标文件有双语对应文件，为另一语言文件生成翻译并合并
   - 技术术语与文件中已有翻译保持一致
   - 专有名词不翻译：Shopee, UniCR, BEM, GmvMax 等
   - 表格翻译内容但保留结构
   - 若目标文件无双语对应 → 跳过翻译步骤
3. **更新元数据**: Contributors（当前用户置前，最多 3 人）和日期
4. 优先用 `Edit` 工具做精确修改；仅新建内容时用 `Write`

### Step 7: 更新索引/Update Index Synthesis

更新 `docs/common/index-synthesis.md` 和 `docs/common/index-synthesis.zh-CN.md`：

索引采用两层结构：
- **Section 1 (全景概览/Overview)**: 按主类别汇总的活跃度表
- **Section 2 (文件 list 总览/File List)**: 按类别分 6 个子节的详细文件表

更新步骤：

1. **§2.x 行更新**: 在表格中找到被修改文件对应的行，更新 `内容摘要`、`上次更新日期`、`上次更新人` 列
   - 用 `Edit` 精确替换表格行
   - 如新增了目标文件，在对应子节的合适位置插入新行
2. **§2 目录扫描同步**: 保持 §2 文件列表与实际目录同步
   a. 读取 §1 Overview 表，提取每个主类别的「目录路径」
   b. 用 `Glob` 扫描每个目录下的实际 `.md` 文件（排除 `README*`）
   c. 与 §2 对应子节的表格做差异比对：
      - **新文件**（目录有、表格无）→ 在 §2 对应子节表格末尾插入新行
      - **已删除文件**（表格有、目录无）→ 从 §2 表格中移除该行
      - **已有文件** → 不动（Summary/Date 已在步骤 1 处理）
   d. 新行的内容摘要：读取文件前 50 行，提取 H1/H2 标题生成一句话摘要
   e. 新行的 Last Updated / Updated By：用 `git log -1 --format="%as %an"` 获取
   f. **双语文件配对**：扫描时按目录的双语约定过滤，避免中英文版本被重复计数：
      - Core Knowledge / SOPs: `.md` + `.zh-CN.md` → ZH 索引列 `.zh-CN.md`，EN 索引列 `.md`
      - DPM: `_en.md` + `_cn.md` → 分别列入
      - How-Tos: `.md` + `.EN.md` → ZH 索引列 `.md`，EN 索引列 `.EN.md`
3. **§1 文件数更新**: 重新统计各目录的文件数
   - 文件数 = `find <目录> -name "*.md" ! -name "README*" | wc -l`
   - 更新 §1 表格的「文件数」列和合计行
4. **§1 活跃度更新**: 用 `git log --since="14 days ago"` 重新统计各目录的活跃文件数，更新 `最近14天更新数` 和 `更新率` 列
   - 更新率 = 最近14天更新数 / 文件数（百分比，取整）
5. **元数据 + 双语同步**: 更新索引文件头部的 Contributors 和日期；以上步骤在 `.md` 和 `.zh-CN.md` 两个索引文件中同步执行

### 输出报告/Output Report

打印结构化总结：

```
## KB Compile Report

- **Input**: <source path or Google Doc title or "git changes since YYYY-MM-DD">
- **Language**: <detected language>
- **Target files updated**:
  - `core-knowledge/02.ads-strategy/01.recall-and-supply-strategy.md` (+15 lines)
  - `core-knowledge/02.ads-strategy/01.recall-and-supply-strategy.zh-CN.md` (+15 lines)
- **Direct edits (index refreshed)**:
  - `team/00.paid-ads-dev/03.sop/01.okr-sop.md` (index summary updated)
- **Sections modified**: §2.1 > Product Card Recall, §2.1 > Video Recall (new)
- **Index updated**: Summary for §2.1, §SOP updated
- **Index sync**:
  - §2.5 How-Tos: +1 new, -0 removed (64 → 65)
  - §1 file counts updated
- **Skipped (excluded)**: 2 files in docs/common/readme/ (use ads-readme-generate)
```

---

## 使用示例/Usage Examples

### Scenario 1: 本地 Markdown 入库

> "把 `docs/personal/luka.yang/notes/new-recall-channel.md` 编译入库到知识库"

→ Skill 读取文件 → 识别 recall 主题 → 映射到 §2.1 → 合并到 `01.recall-and-supply-strategy.md`

### Scenario 2: Google Doc 入库

> "Compile this Google Doc into the KB: https://docs.google.com/document/d/1abc.../edit"

→ Skill 读取 Doc → 识别主题 → 映射 → 合并 → 更新索引

### Scenario 3: Sub-KB 内容迁移

> "把 `docs/common/sub-kb/2.1-recall/kb.md` 的内容 compile 到 core-knowledge"

→ Skill 读取 sub-kb → 映射到 §2.1 core-knowledge 文件 → 智能合并去重

### Scenario 4: 多章节文档

> "这个文档涵盖了召回和出价两部分，请入库"

→ Skill 拆分为两段 → 分别映射到 §2.1 和 §2.3 → 逐个合并 → 更新两个文件

### Scenario 5: Git 变更入库

> "把最近 7 天的变更编译入库"

→ Skill 运行 `git log --since="7 days ago"` 扫描 `docs/`、`skills/common/`、`guides/common/`、`scripts/`、`templates/`、根目录配置文件
→ 发现 3 个 core-knowledge 文件被直接编辑 + 2 个 sub-kb 文件变更 + 1 个 skill SKILL.md 更新
→ 对 core-knowledge 文件：直接更新 index 行（Summary/Date/By）
→ 对 sub-kb 文件：读取内容，映射到对应 core-knowledge 目标，合并
→ 对 skill 文件：提取新增能力描述，映射到对应 How-To 或 core-knowledge 文件
→ 更新 index-synthesis Section 1 活跃度统计

### Scenario 6: 跨 Section 入库

> "把 DPM 的 deduction module 相关概念 compile 到核心知识"

→ Skill 读取 DPM `deduction_en.md` → 识别计费扣费主题 → 映射到 core-knowledge §5.4
→ 仅提取概念性内容合并，实现细节保留在 DPM 原文件

---

## 注意事项/Notes

- **图片处理**: 本 skill 不处理图片文件。如输入包含图片引用，会保留引用但用户需手动将图片文件放到目标目录的 `img/`
- **大文档**: 如输入超过 500 行，建议分段输入或指定要 compile 的章节范围
- **翻译质量**: 自动生成的翻译需用户 review 领域专有术语的准确性
- **不修改 Sub-KB**: 本 skill 只从 Sub-KB 读取，不会修改 Sub-KB 文件
- **排除目标管理**: 如需调整排除范围，编辑 `references/mapping-rules.md` 的 Excluded Targets 表
