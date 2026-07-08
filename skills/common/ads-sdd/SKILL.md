---
name: ads-sdd
description: >
  Spec-Driven Development 工具链 — 规约目录脚手架、组件规约编写、结构校验、规约驱动实现生成、Delta Spec 变更提案与合并归档。
  (SDD toolchain — scaffold spec directories, author component specs, validate structure, generate implementations from specs, propose/apply/archive delta spec changes)
  TRIGGER when: "sdd", "spec-driven", "scaffold spec", "spec init", "ads-sdd",
  "create spec", "spec review", "spec implement", "规约", "脚手架",
  "spec 目录", "写 spec", "spec 校验", "spec 实现", "初始化 spec",
  "propose", "delta spec", "apply delta", "archive change", "变更提案", "合并 delta".
  DO NOT TRIGGER when: 查阅现有 spec 内容（直接 Read）、SDD 方法论概念问答（用 ads-knowledge-qa）。
user-invocable: true
skill_dependencies: []
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# ads-sdd — Spec-Driven Development 工具链

> **Spec**: `specs/common/sdd/`
> **Core Concepts**: `specs/common/sdd/02-core-concepts.md`
> 执行时按需读取对应章节，不把完整规范一次性塞进上下文。

将 SDD 方法论落地为可执行的工具链。支持三种开发类型（skill/code/docs），覆盖从 spec 目录创建到实现生成的完整生命周期，以及结构化增量变更（Delta Spec）的提案、合并和归档。

## 使用方式

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

## Mode Detection

从用户输入中提取 mode 和参数：

| 关键词 | Mode | 参数 |
| --- | --- | --- |
| `init` | init | domain-name, --type |
| `spec` | spec | domain/component-name, --contract |
| `review` / `校验` / `check` | review | domain |
| `implement` / `实现` / `generate` | implement | domain, --diff |
| `propose` / `变更提案` / `delta` | propose | domain/change-name, --scope |
| `apply` / `合并` / `merge delta` | apply | domain/change-name |
| `archive` / `归档` | archive | domain/change-name |

如果无法识别 mode，用 AskUserQuestion 提供七个选项让用户选择。

---

## Mode A: init

> **Spec**: `specs/common/sdd/03-ads-sdd-init-spec.md`

创建新 domain 的 spec 目录骨架，引导用户完成基础文件。

### 执行流程

1. **类型分类**
   - 如果 --type 未提供，用 AskUserQuestion 展示三个选项：
     - `skill` — 最终产出是 SKILL.md / Agent 定义
     - `code` — 最终产出是代码文件 / Proto / 配置
     - `docs` — 最终产出是文档模板 / 流程规范

2. **Domain-name 校验**
   - 必须是 kebab-case（匹配 `^[a-z][a-z0-9-]*[a-z0-9]$`，2-30 字符）
   - 检查 `specs/common/{domain}/` 是否已存在
   - 已存在 → 报错，建议使用 `ads-sdd spec` 添加组件

3. **创建目录**
   ```bash
   mkdir -p specs/common/{domain}/
   ```

4. **复制并初始化模板**
   - Read `templates/specs/01-scope-and-workflow-template.md` → 替换 `{Domain}` placeholder → Write 为 01 文件
   - 按类型读取 02 模板：
     - `skill` → `02-core-concepts-template.md`
     - `code` → `02-data-model-template.md`
     - `docs` → `02-core-concepts-template.md`（输出命名为 `02-document-system.md`）
   - 替换 placeholder → Write 为 02 文件

5. **交互式引导 01**
   - 引导问题详见 `references/init-questions.md`
   - 核心问题：系统做什么？生命周期有几个阶段？有哪些组件？
   - 至少完成：权威边界、生命周期 arrow chain、接口表

6. **交互式引导 02**
   - 引导问题详见 `references/init-questions.md`
   - skill: 层级模型、状态枚举
   - code: schema 概览、核心实体
   - docs: 文档结构、章节定义

7. **生成 README**
   - 从已填充的 01+02 提取文件信息
   - 使用 `templates/specs/README-template.md` 格式
   - 包含 Documents 表（01 和 02 两行）和 Reference Rule

8. **输出下一步**
   - 提示：`使用 /ads-sdd spec {domain}/{component} 逐个编写组件 spec`
   - 列出接口表中待编写的组件

---

## Mode B: spec

> **Spec**: `specs/common/sdd/04-ads-sdd-spec-spec.md`

为 domain 中的单个组件编写 spec 文件。

### 前置检查

1. domain 目录存在？→ 不存在则报错，建议先 `init`
2. 01 和 02 文件存在？→ 不存在则报错
3. 同名 spec 文件不存在？→ 已存在则报错，提示直接编辑

### 执行流程

1. **读取上下文**
   - Read `{domain}/01-scope-and-workflow.md` — 提取接口表中该组件的行
   - Read `{domain}/02-*.md` — 获取共享概念

2. **分配编号**
   - Glob `{domain}/[0-9][0-9]-*.md`，扫描已有编号
   - 编号规则详见 `references/spec-section-prompts.md`
   - 01/02 是 foundation；如果 02 不是 core-concepts 且无 03-core-concepts，03 保留
   - contract（--contract）编号放在 component spec 之后

3. **选择模板**
   - 无 --contract → Read `templates/specs/NN-component-spec-template.md`
   - 有 --contract → Read `templates/specs/NN-contract-template.md`

4. **创建并预填**
   - 替换 placeholder：`{N}`, `{component-name}`, `{foundational}`
   - 从接口表预填目标表（阶段/输入/输出/上游/下游）

5. **交互式填充**
   - 引导问题详见 `references/spec-section-prompts.md`
   - 逐章节与用户对齐：
     - **输入契约**: 这个组件接收什么？格式是什么？
     - **输出契约**: 它产出什么？必需字段有哪些？
     - **执行流程**: 它按什么步骤工作？
     - **规则执行**: 有哪些必须检查的规则？失败如何处理？
     - **变更护栏**: 改这个 spec 需要同步更新哪些文件？

6. **更新 README**
   - 在 `{domain}/README.md` 的 Documents 表追加一行

7. **输出下一步**
   - 检查接口表中尚无 spec 的组件，提示编写下一个
   - 如果全部完成，提示执行 `ads-sdd review {domain}`

---

## Mode C: review

> **Spec**: `specs/common/sdd/05-ads-sdd-review-spec.md`

校验 spec 目录的结构完整性，输出结构化报告。**只报告不修改。**

### 执行流程

1. **列出文件**
   ```bash
   ls specs/common/{domain}/
   ```

2. **结构检查**
   - 01-scope-and-workflow.md 存在？
   - 02-*.md 存在？
   - README.md 存在？
   - 编号连续？（提取编号，检查跳号）

3. **交叉引用检查**
   - README Documents 表中每个链接 → 文件存在？
   - 每个 spec 的权威依赖链接 → 文件存在？
   - spec 内部 `[text](./path)` 链接 → 文件存在？

4. **完整度检查**
   - Read 01 的接口表，提取组件列表
   - 对每个组件，检查对应 spec 文件是否存在
   - 接口表为空 → WARNING

5. **Placeholder 检查**
   - Grep `\{[^}]+\}` 所有 md 文件
   - 排除 code block 内的 placeholder
   - 排除已知安全 pattern

6. **判定状态**
   - 按 `02-core-concepts.md` 的 2.3 节判定：scaffolded / authoring / complete / implemented
   - 校验规则详见 `references/validation-rules.md`

7. **输出报告**
   ```
   ## SDD Review Report: {domain}
   
   ### 结构检查 (Structure)
   - [PASS/FAIL] ...
   
   ### 交叉引用检查 (Cross-Reference)
   - [PASS/FAIL] ...
   
   ### 完整度检查 (Completeness)
   - [PASS/FAIL] ...
   
   ### Placeholder 检查 (Placeholders)
   - [PASS/FAIL] ...
   
   ### 总结
   - 通过：N/total
   - 状态：{state}
   - 建议操作：{next steps}
   ```

---

## Mode D: implement

> **Spec**: `specs/common/sdd/06-ads-sdd-implement-spec.md`

从全量 spec 生成实现文件，或从 spec diff 增量更新。

### Sub-mode A: 全量构建（无 --diff）

1. **读取全量 spec**
   - Read domain 目录下所有 md 文件

2. **确定开发类型**
   - 从 02 文件名推断：core-concepts → skill, data-model → code, document-system → docs

3. **为每个 component spec 生成实现**
   - 提取组件目标、I/O 契约、执行流程、规则
   - 按开发类型生成：
     - **skill**: `skills/common/ads-{domain}/SKILL.md`
       - Frontmatter: name, description (含 TRIGGER/DO NOT TRIGGER), allowed-tools
       - 头部 Pointer+Lazy-Load 引用声明
       - 从执行流程推导步骤
     - **code**: 代码骨架（接口定义、handler、类型）
     - **docs**: 文档模板
   - 生成模式详见 `references/implement-patterns.md`

4. **500 行约束**
   - SKILL.md body ≤ 500 行
   - 超出部分拆到 `references/` 子目录

5. **呈现并确认**
   - 每个文件写入前展示给用户确认

### Sub-mode B: Spec-diff 迭代（--diff）

1. **获取 spec diff**
   ```bash
   git diff HEAD -- specs/common/{domain}/
   ```

2. **解析变更范围**
   - 识别修改的 spec 文件
   - 读变更 spec 的「变更护栏」章节，识别受影响的实现文件

3. **读取全量上下文**
   - Read 01+02 获取共享概念

4. **定向生成变更**
   - 读取每个受影响实现文件的当前内容
   - 基于 spec diff + 全量上下文生成变更
   - 只修改 diff 影响的部分

5. **呈现变更**
   - 展示每个文件的变更（diff 格式），用户确认后写入

---

## Mode E: propose

> **Spec**: `specs/common/sdd/08-ads-sdd-propose-spec.md`

创建结构化变更提案和 delta spec 文件。

### 输入解析

- 从用户输入提取 `domain/change-name`（如 `sdd/add-lint-mode`）
- domain 目录必须存在且至少有 01+02
- change-name 必须是 kebab-case，`changes/{change-name}/` 不能已存在
- 可选 `--scope NN,NN` 指定受影响的 spec 文件编号

### 执行流程

1. **校验 domain**
   - `specs/common/{domain}/` 存在？01+02 存在？
   - `changes/{change-name}/` 不存在？→ 已存在则报错

2. **创建 change 目录**
   ```bash
   mkdir -p specs/common/{domain}/changes/{change-name}/
   ```

3. **确定变更范围**
   - 如果有 --scope：按编号读取指定 spec 文件
   - 如果无 --scope：列出所有 NN-spec，用 AskUserQuestion 让用户多选受影响的文件

4. **生成 delta 模板**
   - 对每个受影响的 spec，Read `templates/specs/delta-NN-component-spec-template.md`
   - 替换 placeholder：`{component-name}`, `{domain}`, `{NN}`, `{change-name}`, `{date}`
   - 文件命名：`delta-{NN}-{component-name}-spec.md`（镜像全量 spec 文件名）

5. **生成 proposal**
   - Read `templates/specs/proposal-template.md`
   - 预填 Domain、Scope 表（已选文件）、Delta Specs 表
   - Write 为 `proposal.md`

6. **引导填写 delta**
   - 对每个 delta 文件，逐个引导用户填写：
     - Read 对应的全量 spec（提供上下文）
     - 问：这个 spec 中需要新增什么？(ADDED)
     - 问：需要修改哪些现有内容？(MODIFIED)
     - 问：需要删除什么？(REMOVED)
     - 问：需要重命名什么概念？(RENAMED)
   - 未使用的标记 section 可以留空或删除
   - 详细填写指南见 `references/propose-apply-archive-patterns.md`

7. **引导填写 proposal**
   - Motivation（变更原因）
   - Impact Assessment（影响评估）

8. **输出下一步**
   - 提示：review delta spec 内容，确认后执行 `/ads-sdd apply {domain}/{change-name}`

---

## Mode F: apply

> **Spec**: `specs/common/sdd/09-ads-sdd-apply-spec.md`

将 delta spec 合并进全量 spec，生成 `.applied` 标记。

### 前置检查

1. `{domain}/changes/{change-name}/` 存在？→ 不存在则报错
2. `.applied` 不存在？→ 已存在则报错（已经 apply 过）
3. `git status` 检查 target spec 文件无未提交修改？→ 有则报错，要求先 commit/stash

### 执行流程

1. **读取 delta spec**
   - Glob `{domain}/changes/{change-name}/delta-*.md`
   - 按文件名中的 NN 排序

2. **对每个 delta 文件执行合并**（按 NN 顺序）
   - 读取对应全量 spec `{domain}/{NN}-*.md`
   - 按确定性顺序合并：
     1. **RENAMED**: 全文替换旧名 → 新名（影响 target 及同 domain 下其他引用文件）
     2. **REMOVED**: 定位章节引用，删除对应内容
     3. **MODIFIED**: 定位 ~~旧内容~~，替换为 **新内容**。定位失败 → 报错暂停
     4. **ADDED**: 按声明的章节编号插入内容
   - 合并算法细节见 `references/propose-apply-archive-patterns.md`

3. **预览变更**
   - 以 diff 格式展示每个全量 spec 的变更
   - 用户确认后写入

4. **标记已应用**
   - Write `{domain}/changes/{change-name}/.applied`（内容为当前时间戳）

5. **输出下一步**
   - 提示执行 `/ads-sdd implement {domain} --diff` 生成实现变更
   - 提示实现完成后执行 `/ads-sdd archive {domain}/{change-name}` 归档

---

## Mode G: archive

> **Spec**: `specs/common/sdd/10-ads-sdd-archive-spec.md`

归档已应用的变更提案。

### 前置检查

1. `{domain}/changes/{change-name}/` 存在？
2. `.applied` 标记存在？→ 不存在则报错，提示先执行 apply

### 执行流程

1. **创建归档目录**
   - 路径：`{domain}/changes/archive/{YYYY-MM-DD}-{change-name}/`
   - 同名已存在 → 追加 `-2`, `-3` 后缀

2. **移动文件**
   - 将 change 目录下所有文件（proposal.md, delta-*.md, .applied）移动到归档目录

3. **清理**
   - 删除空的 `{domain}/changes/{change-name}/` 目录

4. **输出总结**
   - 显示归档路径和文件列表

---

## 通用约束

1. **三层权威架构**
   - Layer 1（`specs/common/sdd/`）→ Layer 2（本 SKILL.md）→ Layer 3（guides/）
   - 本 SKILL.md 不引入 spec 未定义的规则

2. **Pointer + Lazy-Load**
   - 运行时按需 Read spec 文件，不在上下文中保持全部 spec 内容

3. **用户确认**
   - 创建目录、写入文件、更新索引前均需用户确认

4. **语言跟随**
   - 按用户语言回复（中文/英文）
