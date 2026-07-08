# 文档翻译 (ads-doc-translate) 使用指南

> **Language**: [English](ads-doc-translate.md) | [中文](ads-doc-translate.zh-CN.md)

使用多种 LLM API（DeepSeek、OpenAI、GLM、Anthropic、Gemini、Kimi）将 Markdown 文档翻译为对应语言版本。支持全量翻译和基于 git diff 的增量翻译。默认使用 DeepSeek。

**触发关键词**: "translate doc", "翻译文档", "translate markdown", "文档翻译", "中译英", "英译中", "translate to English", "translate to Chinese"

---

## 技能文件

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 技能定义，包含全量/增量翻译工作流 |
| `scripts/translate.py` | 多提供商 LLM 翻译脚本（OpenAI 兼容 + Anthropic） |
| `scripts/update_metadata.py` | 翻译后 metadata 更新器（Contributors、Language 互链） |
| `references/prompt-templates.md` | 翻译 prompt 模板和质量要求 |
| `references/providers.md` | 支持的提供商、API Key 配置和使用示例 |

## 快速开始

```
/ads-doc-translate docs/common/core-knowledge/01.ads-overview/01.preface.zh-CN.md
```

技能会自动根据文件后缀检测语言方向，检查目标文件是否存在，并选择全量或增量模式。

## 功能特性

- **自动语言检测**：`.zh-CN.md` → 中→英，`.EN.md` → 英→中，普通 `.md` → 按内容检测
- **增量翻译**：仅重新翻译 git diff 中变更的 section
- **并行翻译**：超过 300 行的文档按 `##` heading 拆分并行翻译
- **双语标题**：heading 行使用 `中文/English` 格式，正文仅保留目标语言
- **6 个 LLM 提供商**：DeepSeek（默认）、OpenAI、GLM、Anthropic、Gemini、Kimi
