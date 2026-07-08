# implement mode 生成模式

> 供 implement mode 使用的实现生成模板和代码生成模式。

## Skill 类型生成模式

### SKILL.md 骨架

```yaml
---
name: ads-{domain}
description: >
  {从 01 的首行描述提取}
  TRIGGER when: {从 01 提取关键触发词}
  DO NOT TRIGGER when: {从 01 提取排除场景}
user-invocable: true
skill_dependencies: [{从 01 上下游关系提取}]
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---
```

### 引用声明（必须在 frontmatter 之后）

```md
# ads-{domain} — {标题}

> **Spec**: `specs/common/{domain}/`
> **Core Concepts**: `specs/common/{domain}/02-{foundational}.md`
> 执行时按需读取对应章节，不把完整规范一次性塞进上下文。
```

### 步骤推导规则

1. 每个 component spec 的执行流程 → SKILL.md 中的一个 Section
2. 执行流程的每个 Step → SKILL.md 中的一个子步骤
3. 规则执行表 → 内联在对应步骤中或独立 Section
4. 如果 spec 中有多个 mode → 按 Mode A / Mode B 格式组织

### 500 行拆分策略

当 SKILL.md 预计超过 500 行时：

1. 优先拆分到 `references/` 的内容：
   - 详细引导问题 → `references/{mode}-questions.md`
   - 详细校验规则 → `references/{mode}-rules.md`
   - 模板/格式定义 → `references/{mode}-templates.md`
2. 主文件保留：
   - frontmatter
   - 引用声明
   - mode detection 表
   - 每个 mode 的执行流程概要
   - 通用约束
3. 拆分引用格式：
   ```md
   > 详见 `references/{name}.md`
   ```

## Code 类型生成模式

### 代码骨架生成规则

1. 从 02 的实体定义 → 生成 Proto/Schema 文件
   - 每个实体 → 一个 message/struct/interface
   - 每个字段 → 一个 field 定义
2. 从 component spec 的 API 契约 → 生成 handler 骨架
   - 每个 API → 一个 handler 函数
   - 请求/响应 → 参数和返回类型
3. 从 component spec 的执行流程 → 生成函数内部 TODO 注释
4. 从 component spec 的规则执行 → 生成 validation 函数骨架

### 代码文件组织

```text
projects/gitlab/{repo}/
  {按 spec 的 API 契约组织目录}
  proto/
    {entity}.proto                  -- 从 02 实体定义生成
  handler/
    {component}_handler.go          -- 从 component spec 生成
  service/
    {component}_service.go          -- 业务逻辑骨架
```

## Docs 类型生成模式

### 文档模板生成规则

1. 从 02 的文档结构 → 生成模板文件
   - 每个章节 → 模板中的一个 Section
   - 必填章节 → 标记 `<!-- 必填 -->`
   - 可选章节 → 标记 `<!-- 可选 -->`
2. 从 component spec 的输出契约 → 预填模板中的表格结构
3. 从 component spec 的规则执行 → 生成模板中的校验提示

### 文档文件组织

```text
templates/{domain}/
  {document-type}-template.md       -- 主模板
  sections/
    {section}-template.md           -- 可复用章节模板（可选）
```

## Spec-diff 增量模式

### 变更映射规则

1. spec 文件的 `变更护栏` 章节声明了修改本 spec 时需要同步的文件
2. 增量模式按以下步骤映射变更：
   - 读 spec diff → 识别修改了哪些 spec 文件
   - 对每个修改的 spec → 读其「变更护栏」章节
   - 构建 spec-file → implementation-file 映射
   - 对每个受影响的实现文件，读当前内容，基于 diff 生成变更

### 变更粒度

- spec 的执行流程步骤变更 → 实现中对应步骤的变更
- spec 的规则表变更 → 实现中对应校验逻辑的变更
- spec 的 I/O 契约变更 → 实现中参数/返回值的变更
- 02 的共享概念变更 → 所有引用该概念的实现文件变更
