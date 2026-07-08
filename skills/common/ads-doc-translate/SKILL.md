---
name: ads-doc-translate
description: >
  Markdown document translator (文档翻译) — translate docs between Chinese and English
  using multiple LLM providers (DeepSeek, OpenAI, GLM, Anthropic, Gemini, Kimi),
  with heading-level smart incremental translation via git blame timestamps.
  TRIGGER when: user mentions "翻译文档", "translate doc", "翻译成英文", "翻译成中文",
  "incremental translate", "增量翻译", "ads-doc-translate"
  DO NOT TRIGGER when: user asks about Transify key lookup (→ ads-platform-transify-lookup),
  user asks KB questions (→ ads-knowledge-qa)
credentials:
  - name: deepseek.api_key
    description: "DeepSeek API Key — create at platform.deepseek.com/api_keys"
  - name: openai.api_key
    description: "OpenAI API Key — create at platform.openai.com/api-keys"
  - name: glm.api_key
    description: "GLM (Zhipu) API Key — create at open.bigmodel.cn/usercenter/apikeys"
  - name: anthropic.api_key
    description: "Anthropic API Key — create at console.anthropic.com/settings/keys"
  - name: gemini.api_key
    description: "Gemini API Key — create at aistudio.google.com/apikey"
  - name: kimi.api_key
    description: "Kimi (Moonshot) API Key — create at platform.moonshot.cn/console/api-keys"
---

# ads-doc-translate/文档翻译

使用多种 LLM API（DeepSeek、OpenAI、GLM、Anthropic、Gemini、Kimi）将 Markdown 文档翻译为对应语言版本。基于 JSON 中间格式和 git blame 时间戳，实现章节级别的智能增量翻译。标题和正文分离翻译，标题双语、正文单语。默认使用 DeepSeek。

---

## 前提条件/Prerequisites

| 条件 | 说明 |
|------|------|
| LLM API Key | 至少配置一个提供商的 API Key（环境变量或 `~/.config/sra/credentials.json`），默认使用 DeepSeek |
| 翻译脚本 | `scripts/preprocess.py`、`scripts/translate.py`、`scripts/reassemble.py`（通过 `uv run` 执行） |
| Git | 源文件需被 git 追踪（用于 `git blame` 时间戳） |

支持 6 个提供商（deepseek/openai/glm/anthropic/gemini/kimi），详见 [references/providers.md](references/providers.md)。

---

## 启动前/Before First Use

读取以下参考文件：

1. [references/prompt-templates.md](references/prompt-templates.md) — 翻译 prompt 模板和质量要求
2. [references/providers.md](references/providers.md) — 提供商列表、API Key 配置和使用示例

---

## 工作流/Workflow

### Step 1: 解析输入，确定语言对/Parse Input & Detect Language Pair

1. 用户提供源文档路径（如 `docs/common/core-knowledge/01.ads-overview/01.preface.zh-CN.md`）
2. 根据文件名后缀自动检测语言方向：

| 源文件后缀                    | 源语言     | 目标语言    | 目标文件规则                                |
| ------------------------ | ------- | ------- | ------------------------------------- |
| `*.zh-CN.md`             | 中文 (zh) | 英文 (en) | 去掉 `.zh-CN` → `*.md`；若不存在尝试 `*.EN.md` |
| `*.EN.md`                | 英文 (en) | 中文 (zh) | 替换 `.EN.md` → `.md`（同目录）              |
| `*.md`（无 `.zh-CN`/`.EN`） | 自动检测   | 自动检测  | 见下方检测逻辑                               |

**`*.md` 语言检测逻辑**：当文件后缀为 `*.md` 且无 `.zh-CN`/`.EN` 标记时，用 `Read` 读取文件前 20 行，统计中文字符（Unicode `\u4e00-\u9fff`）占非空白字符的比例：
- 中文字符占比 > 30% → 判定为中文文档，源语言 zh，目标文件添加 `.EN` → `*.EN.md`
- 否则 → 判定为英文文档，源语言 en，目标文件添加 `.zh-CN` → `*.zh-CN.md`

3. 用 `Glob` 检查同目录下是否存在目标文件
4. 向用户确认语言方向和目标文件路径

### Step 2: 预处理/Preprocess

将中英文两个文件解析为结构化 JSON 中间格式：

```bash
uv run skills/common/ads-doc-translate/scripts/preprocess.py \
  --zh-file <zh-file-path> \
  --en-file <en-file-path> \
  --output /tmp/ads-translate-tree.json
```

- 如果目标文件不存在，省略对应的 `--zh-file` 或 `--en-file` 参数
- 脚本自动完成：解析 heading 层级 → 标记叶子节点 → `git blame` + `<!-- last_translated -->` 取较新时间戳 → 匹配中英文对应章节 → 输出 JSON
- **`---` 分隔符回退**：当文档只有 0-1 个 heading 但有 ≥2 个 `---` 水平分隔线时，自动以 `---` 作为段落切分依据（level=99 的伪标题），每个 `---` 段落作为独立叶子节点翻译。输出文件中 `---` 原样保留，不做双语标题翻译
- 成功：stdout 输出 `{"status":"ok","sections":N,"leaves":M,"diff_leaves":K,"needs_translate":[...]}`
- `needs_translate` 数组列出所有时间戳不一致（需要翻译同步）的叶子节点

**JSON 中间格式**（扁平 key）：

```json
{
  "meta": { "source_file_zh": "...", "source_file_en": "...", "zh_exists": true, "en_exists": true },
  "preamble_zh": "文件开头到第一个 heading 的内容",
  "preamble_en": "...",
  "sections": {
    "1":   { "title": "## 标题", "level": 2, "is_leaf": false, "parent": null },
    "1.1": { "title": "### 子标题", "level": 3, "is_leaf": true, "parent": "1",
             "last_update_time_zh": "2026-06-04T14:20:22+00:00",
             "last_update_time_en": "2026-06-01T10:30:00+00:00",
             "content_zh": "中文正文...", "content_en": "English body..." },
    "2":   { "title": "---", "level": 99, "is_leaf": true, "parent": null,
             "content_zh": "无 heading 文档的段落...", "content_en": null }
  }
}
```

### Step 2.5: 确认翻译范围/Confirm Translation Scope

读取 preprocess.py stdout 中的 `needs_translate` 数组：

- **列表为空** → 提示"所有叶子节点已同步，无需翻译"，结束流程
- **列表非空** → 用表格展示需要翻译的叶子节点，用 `AskUserQuestion` 询问用户是否继续：

```
预处理发现以下叶子节点需要翻译同步：

| # | Section | 标题 | 方向 | 中文更新时间 | 英文更新时间 |
|---|---------|------|------|------------|------------|
| 1 | 1.1     | 百度入行 | zh→en | 2026-06-05 04:35 | 2026-06-04 10:00 |

是否继续翻译这 N 个叶子节点？
```

- 用户可选择"翻译全部"、"跳过"或"使用 --force 翻译所有叶子节点"

### Step 3+4: 翻译/Translate

标题翻译（双语）和内容翻译（智能增量）在同一次调用中完成：

```bash
uv run skills/common/ads-doc-translate/scripts/translate.py \
  --provider <provider> \
  --input-json /tmp/ads-translate-tree.json \
  --output-json /tmp/ads-translate-tree-translated.json \
  [--force]
```

**Step 3 — 标题翻译**：
- 收集所有非双语标题（不含 ` / ` 的标题），跳过 `---` 伪标题
- 按语言分组，批量调用 LLM 翻译为双语格式（`中文 / English`）
- 含验证和 retry 机制

**Step 4 — 内容翻译**（智能增量）：
- 遍历每个叶子节点，比较 `last_update_time_zh` 和 `last_update_time_en`：
  - 时间戳相同且两侧内容都非空 → 跳过（已同步）
  - 中文侧为空 → 翻译 en→zh
  - 英文侧为空 → 翻译 zh→en
  - 中文更新 → 翻译 zh→en（使用旧英文作为风格参考）
  - 英文更新 → 翻译 en→zh
- `--force`：忽略时间戳，强制翻译所有叶子节点
- 每个翻译结果自动运行 `validate_translation()` 检查残留源语言

成功：stdout 输出 `{"status":"ok","provider":"...","model":"...","translated":N,"skipped":M,"validation_warnings":W}`

### Step 5: 重组/Reassemble

将 JSON 中间格式还原为中英文两个 markdown 文件：

```bash
uv run skills/common/ads-doc-translate/scripts/reassemble.py \
  --input-json /tmp/ads-translate-tree-translated.json \
  --zh-output <zh-file-path> \
  --en-output <en-file-path>
```

- 按 section key 数值排序，输出双语标题行（`---` 伪标题原样输出为 `---`）
- 叶子节点内容包含 `<!-- last_translated: ... -->` 注释行（由 translate.py 插入）
- 在第一个 `#` heading 后自动插入 Contributors 行和 Language 互链行
- 若源文件缺少 Language 行则自动补上
- 中文文件和英文文件标题相同（双语），正文各自对应语言
- preamble 直接输出，不翻译

成功：stdout 输出 `{"status":"ok","zh_chars":N,"en_chars":M}`

### Step 5.5: 结构一致性检查/Structural Parity Check

检查中英文文件的 markdown 结构符号是否一致：

```bash
uv run skills/common/ads-doc-translate/scripts/postcheck.py \
  --zh-file <zh-file-path> --en-file <en-file-path>
```

- 检查项：代码块围栏、语言标签、表格行数、图片/链接 URL、HTML 标签、数学块、blockquote、水平分隔线
- `status: "ok"` → 所有结构检查通过，继续 Step 6
- `status: "fail"` → 在 Step 6 报告中展示不一致项，提醒用户检查

### Step 6: 展示结果/Show Results

输出翻译摘要：

```
翻译完成/Translation complete:
- 方向/Direction: 双向同步 (bidirectional sync)
- 中文文件/ZH file: <zh-path>
- 英文文件/EN file: <en-path>
- 叶子节点/Leaves: <total>（翻译 <translated>，跳过 <skipped>）
- 质量检查/Validation: <N> warnings
- 结构一致性/Structural parity: <ok|N errors>
- 模型/Model: <model-name>
- 提供商/Provider: <provider-name>
```

---

## 硬规则/Hard Rules

1. **格式保真**: Markdown 格式必须 100% 保留（表格、代码块、链接、图片）
2. **代码不翻译，叙事代码块除外**: 带语言标签的代码块（```python 等）、`inline` 代码、命令行、文件路径、URL 不翻译；无语言标签的代码块若内容为叙事文字（CJK 占比 > 30%）则翻译，保留空白布局
3. **标题双语**: 所有 heading 使用 `中文 / English` 双语格式
4. **正文单语**: 正文只保留目标语言，不保留源语言
5. **增量优先**: 通过 git blame 时间戳判断，只翻译有更新的章节
6. **确认后写入**: 写入前向用户展示翻译模式和目标文件路径
7. **临时文件清理**: 翻译完成后清理 `/tmp/ads-translate-*.json`
8. **API Key 安全**: 不在日志或输出中暴露 API Key
