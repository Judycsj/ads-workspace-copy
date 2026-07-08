# Propose / Apply / Archive Patterns

> 供 SKILL.md Mode E/F/G 按需读取的详细参考。

## Delta Spec 填写指南

### 标记语法

Delta spec 使用四种 H2 标记描述变更：

| 标记 | 含义 | 填写要求 |
| --- | --- | --- |
| `## ADDED Requirements` | 新增需求/规则/接口 | 标注所属章节编号，描述新增内容 |
| `## MODIFIED Requirements` | 修改现有内容 | 引用现有章节，~~旧内容~~ → **新内容** |
| `## REMOVED Requirements` | 删除内容 | 标注章节编号，描述被删除的内容 |
| `## RENAMED Requirements` | 重命名概念/术语 | `旧名` → `新名`，列出所有受影响文件 |

### MODIFIED 格式约定

每条 MODIFIED 项须引用原文以消除歧义：

```md
- **5.4 执行流程 Step 3**: ~~只检查 README 链接~~ → **同时检查 changes/ 子目录的活跃提案**
```

### 填写原则

1. 一个 delta 文件对应一个全量 spec 文件（文件名镜像：`delta-05-ads-sdd-review-spec.md` 对应 `05-ads-sdd-review-spec.md`）
2. 未使用的标记 section 保留空白或删除均可
3. ADDED 的内容要写到可以直接粘贴进全量 spec 的程度
4. REMOVED 只需标注位置和摘要，不需要复制全文

## 合并算法

Apply mode 按以下顺序执行合并，确保确定性：

```text
for each delta file (sorted by NN):
  target = read full spec file (NN-*.md)

  1. RENAMED: 全文替换旧名 → 新名
     - 范围：target 文件全文 + 同 domain 下所有引用该名称的文件
     - 逐条按声明顺序执行

  2. REMOVED: 定位并删除目标内容
     - 按章节引用定位
     - 删除后修复周围空行（不留连续空行）

  3. MODIFIED: 定位旧内容，替换为新内容
     - 用 ~~旧内容~~ 定位原文位置
     - 如果定位失败（原文已变），报错并暂停，要求用户手动解决

  4. ADDED: 在指定章节位置插入新内容
     - 按声明的章节编号确定插入位置
     - 如果目标章节不存在，追加到文件末尾并发出警告

  write updated target
```

## 冲突检测

Apply 前执行以下启发式检查：

| 检查项 | 触发条件 | 处理 |
| --- | --- | --- |
| 未提交变更 | `git status` 显示 target spec 有未提交修改 | 报错，要求先 commit 或 stash |
| MODIFIED 定位失败 | ~~旧内容~~ 在 target 中找不到匹配 | 报错，展示 delta 和 target 相关段落，要求手动解决 |
| 多个活跃 change 修改同一文件 | 同一 NN-spec 在多个 change 目录有 delta | 警告，建议按顺序逐个 apply |
| RENAMED 影响范围 | 旧名在多个文件中出现 | 列出所有匹配，确认后批量替换 |

## 示例

### 场景：为 SDD 工具链新增 lint mode

**1. Propose**

```bash
/ads-sdd propose sdd/add-lint-mode
```

产出目录结构：
```text
sdd/changes/add-lint-mode/
  proposal.md
  delta-01-scope-and-workflow.md    # 接口表新增 lint 行
  delta-02-core-concepts.md         # （如果不涉及概念变更则无此文件）
```

**2. Delta 内容示例** (`delta-01-scope-and-workflow.md`)

```md
## ADDED Requirements

- **1.4 接口表**: 新增一行：
  | lint | domain | 格式问题列表（stdout） | review | - | 可选 |

## MODIFIED Requirements

- **1.5 未覆盖**: ~~Delta spec 冲突检测 | Planned~~ → **自动修复模式 | Planned**
```

**3. Apply → Implement → Archive**

```bash
/ads-sdd apply sdd/add-lint-mode       # 合并 delta 到全量 spec
/ads-sdd implement sdd --diff           # 从合并后的 spec 生成 SKILL.md 变更
/ads-sdd archive sdd/add-lint-mode      # 归档到 changes/archive/2026-07-05-add-lint-mode/
```
