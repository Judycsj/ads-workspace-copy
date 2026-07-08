# Prompt Templates/翻译 Prompt 模板

本文件定义翻译脚本使用的 prompt 模板。已内嵌在 `translate.py` 中，此处作为参考文档。

---

## 架构概览/Architecture Overview

翻译流水线将标题和正文分离处理，避免 LLM 在长文本中混淆双语指令：

```
preprocess.py → translate.py (headings + content) → reassemble.py
```

- **标题**：使用 `HEADING_PROMPTS`，批量翻译为双语格式 `中文 / English`
- **正文**：使用 `BODY_PROMPTS`，每个叶子节点独立翻译，输出仅目标语言

---

## 标题翻译/Heading Translation (HEADING_PROMPTS)

标题单独翻译为双语格式，与正文分离处理。

### 中文 → 双语

```
You are a bilingual heading translator.
Given a list of Chinese markdown headings (one per line), output the SAME number of lines.
Each output line MUST keep the original Chinese text and append an English translation
separated by ' / '.

Format: <original Chinese heading> / <English translation>
- Preserve the leading '#' markers exactly as-is.
- If the heading already contains both languages, just normalize spacing around '/'.
- IMPORTANT: Section numbers (e.g. '1.4', '1.4.2', '2.3') MUST stay at the very beginning,
  right after the '#' markers and before the Chinese text. Do NOT move, remove, or duplicate them.
- The English part after ' / ' should contain ONLY the English translation, NO section number.

Example:
  Input:  ### 1.0.1 学生时代的三次转向
  Output: ### 1.0.1 学生时代的三次转向 / Three Pivots During Student Days
```

### 英文 → 双语

```
Format: <#markers> <section-number> <Chinese translation> / <original English text without number>
- IMPORTANT: Section numbers (e.g. '1.6', '1.6.1', '2.3') from the English heading MUST be
  moved to the very beginning (right after '#' markers), before the Chinese text.
  The English part after ' / ' should NOT repeat the section number.

Example:
  Input:  ### 1.6 Shopee Paid Ads Business Overview
  Output: ### 1.6 Shopee Paid Ads 业务介绍 / Shopee Paid Ads Business Overview
```

---

## 正文翻译/Body Translation (BODY_PROMPTS)

正文不含标题，输出仅目标语言。

### 中文 → 英文（全量）

```
CRITICAL RULES:
- Output English ONLY. Do NOT keep any Chinese text.
- There are NO headings in the input — they have been removed.
  Do NOT generate any heading lines (lines starting with #).
- Preserve ALL Markdown formatting: lists, tables, code blocks, links, images, blockquotes
- Do NOT translate content inside code blocks with language tags (```python, ```bash, etc.) or inline `code`
- Text between [PREFORMATTED_TEXT_START] and [PREFORMATTED_TEXT_END] is narrative text —
  DO translate it, preserving the whitespace layout (indentation, alignment, arrows like →)
- Do NOT translate URLs, file paths, variable names, or HTML tags
- Preserve HTML tags exactly as-is
- Output ONLY the translated content, no explanations or wrapping
```

### 英文 → 中文（全量）

对称规则，输出中文 ONLY。

### 增量模式

增量模式额外附加指令：
- `Match the style and terminology of the existing translation context provided`
- 使用 `---CONTEXT---` / `---TRANSLATE---` 分隔已有翻译和待翻译内容

---

## 智能增量逻辑/Smart Incremental Logic

`translate.py` Step 4 中的增量判断基于 `git blame` 时间戳：

| 条件 | 动作 |
|------|------|
| `ts_zh == ts_en` 且两侧内容非空 | 跳过（已同步） |
| `content_zh` 为空 | 翻译 en→zh |
| `content_en` 为空 | 翻译 zh→en |
| `ts_zh > ts_en` | 翻译 zh→en（使用旧 en 作为风格参考） |
| `ts_en > ts_zh` | 翻译 en→zh（使用旧 zh 作为风格参考） |

使用 `--force` 参数可忽略时间戳，强制翻译所有叶子节点。

---

## 翻译后验证/Post-translation Validation

`translate.py` 内置 `validate_translation()` 函数，在每个叶子节点翻译后自动检查：

- 跳过 heading 行、code block、metadata 行
- 对剩余正文行检测源语言字符占比
- zh→en：如果某行中文字符 > 30%，输出 warning
- en→zh：如果某行 ASCII 字母 > 70%，输出 warning
- Warning 通过 stderr JSON 输出，不阻断流程

---

## 翻译质量要求/Quality Requirements

| 维度 | 要求 |
|------|------|
| 标题双语 | 所有 heading 使用 `中文 / English` 双语格式 |
| 正文单语 | 正文只保留目标语言，不保留源语言 |
| 格式保真 | Markdown 格式 100% 保留，包括表格对齐、列表层级、链接 |
| 代码保护 | 带语言标签的代码块、内联代码、命令行示例不翻译；无语言标签的叙事代码块翻译并保留空白布局 |
| 术语一致 | 领域术语使用已建立的对应词，不创造新翻译 |
| 元数据保留 | Contributors、日期、GitLab 链接行原样保留 |
| 路径保留 | 文件路径、URL、变量名不翻译 |
