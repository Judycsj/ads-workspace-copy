# Document Translator (ads-doc-translate) Guide

> **Language**: [English](ads-doc-translate.md) | [中文](ads-doc-translate.zh-CN.md)

Translate Markdown documents between Chinese and English using multiple LLM APIs (DeepSeek, OpenAI, GLM, Anthropic, Gemini, Kimi). Supports full translation and incremental translation based on git diff. Defaults to DeepSeek.

**Trigger keywords**: "translate doc", "翻译文档", "translate markdown", "文档翻译", "中译英", "英译中", "translate to English", "translate to Chinese"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with full/incremental translation workflow |
| `scripts/translate.py` | Multi-provider LLM translation script (OpenAI-compatible + Anthropic) |
| `scripts/update_metadata.py` | Post-translation metadata updater (Contributors, Language links) |
| `references/prompt-templates.md` | Translation prompt templates and quality requirements |
| `references/providers.md` | Supported providers, API key config, and usage examples |

## Quick Start

```
/ads-doc-translate docs/common/core-knowledge/01.ads-overview/01.preface.zh-CN.md
```

The skill auto-detects language direction from file suffix, checks for existing target file, and chooses full or incremental mode accordingly.

## Features

- **Auto language detection**: `.zh-CN.md` → zh→en, `.EN.md` → en→zh, plain `.md` → detect by content
- **Incremental translation**: Only re-translates sections changed in git diff
- **Parallel translation**: Documents over 300 lines are split by `##` headings and translated in parallel
- **Bilingual headings**: Heading lines use `中文/English` format; body content is target-language only
- **6 LLM providers**: DeepSeek (default), OpenAI, GLM, Anthropic, Gemini, Kimi
