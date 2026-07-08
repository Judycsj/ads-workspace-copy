# review mode 校验规则

> 供 review mode 使用的详细校验规则和判定逻辑。

## 结构检查规则

### S1: Foundation 文件存在

- 检查 `01-scope-and-workflow.md` 存在
- 检查 `02-*.md` 存在（匹配 `02-` 前缀的任意文件）
- 检查 `README.md` 存在
- 严重级别：FAIL

### S2: 编号连续

- 从所有 `[0-9][0-9]-*.md` 文件名提取编号
- 检查从 01 到最大编号之间是否有跳号
- 例外：如果 02 不是 core-concepts 且不存在 03-core-concepts，03 跳号是允许的
- 严重级别：WARNING

## 交叉引用检查规则

### X1: README 链接有效

- 解析 README.md 的 Documents 表中所有 `[text](./path)` 链接
- 检查每个链接指向的文件是否存在
- 严重级别：FAIL

### X2: 权威依赖链接有效

- 每个 spec 文件开头应有 `**权威依赖**` 声明
- 解析声明中的 `[text](./path)` 链接
- 检查链接文件是否存在
- 严重级别：FAIL

### X3: 内部链接有效

- 扫描所有 spec 文件中的 `[text](./path)` 链接（排除外部 URL）
- 检查链接文件是否存在
- 严重级别：WARNING

## 完整度检查规则

### C1: 接口表组件覆盖

- 读 01 文件，查找「技能接口」/「Skill Interfaces」/「Component Interfaces」标题下的表格
- 提取第一列作为组件列表
- 对每个组件名，检查是否存在 `*-{component}*.md` 文件
- 如果找不到接口表：输出 WARNING
- 严重级别：FAIL（有组件缺 spec）/ WARNING（无接口表）

## Placeholder 检查规则

### P1: 无残留 Placeholder

- Grep 所有 md 文件中的 `\{[^}]+\}` 模式
- 排除规则：
  - 在 ``` code block ``` 内的不算
  - 在 `{domain}`, `{N}`, `{component-name}` 等 reference 上下文中的不算
  - 在 inline code `` ` `` 内的不算
- 严重级别：WARNING

## 状态判定逻辑

按以下顺序判定 Spec 完整度状态：

1. 目录不存在 → 无状态
2. 有 01+02+README 但无 NN-spec（编号 ≥ 03）→ **scaffolded**
3. 有 NN-spec 但 C1 检查失败（有组件缺 spec）→ **authoring**
4. 有 NN-spec 且 C1 通过且 P1 通过 → **complete**
5. complete 且对应实现文件存在 → **implemented**

实现文件判定：
- skill 类型：`skills/common/ads-{domain}/SKILL.md` 存在
- code 类型：由 spec 中的输出路径声明决定
- docs 类型：`templates/{domain}/` 目录存在

## 报告格式

```text
## SDD Review Report: {domain}

### 结构检查 (Structure)
- [PASS] 01-scope-and-workflow.md 存在
- [PASS] 02-core-concepts.md 存在
- [PASS] README.md 存在
- [PASS] 编号连续

### 交叉引用检查 (Cross-Reference)
- [PASS] README 链接全部有效 (7/7)
- [PASS] 权威依赖链接全部有效 (5/5)
- [WARNING] 内部链接 2 处无效
  - 05-review-spec.md:L10 → ./03-nonexistent.md

### 完整度检查 (Completeness)
- [PASS] 接口表中 4/4 组件已有 spec

### Placeholder 检查 (Placeholders)
- [WARNING] 发现 1 处残留 placeholder
  - 04-spec-spec.md:L42: {description of parsing rules}

### 总结
- 通过：3/4 (结构 ✓ 交叉引用 ✓ 完整度 ✓ Placeholder ✗)
- 状态：authoring
- 建议操作：
  1. 补充 04-spec-spec.md L42 的 placeholder 内容
  2. 修复 05-review-spec.md L10 的无效链接
```
