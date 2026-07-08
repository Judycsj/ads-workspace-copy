# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "openai>=1.0",
#   "anthropic>=0.40",
# ]
# ///
"""
Multi-provider LLM translation script for ads-doc-translate skill.

Translates markdown content between Chinese and English using multiple
LLM providers (DeepSeek, OpenAI, GLM, Anthropic, Gemini, Kimi).

Operates on a JSON tree produced by preprocess.py:
  Step 3: Translate headings to bilingual format
  Step 4: Smart incremental translation of leaf node content
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

from openai import OpenAI

HEADING_PROMPTS = {
    "zh2en": (
        "You are a bilingual heading translator.\n"
        "Given a list of Chinese markdown headings (one per line), output the SAME number of lines.\n"
        "Each output line MUST keep the original Chinese text and append an English translation "
        "separated by ' / '.\n\n"
        "Format: <original Chinese heading> / <English translation>\n"
        "- Preserve the leading '#' markers exactly as-is.\n"
        "- If the heading already contains both Chinese and English (e.g. '## 结语/Conclusion'), "
        "just normalize to '## 结语 / Conclusion' (add spaces around '/').\n"
        "- Do NOT add any extra lines, explanations, or numbering.\n"
        "- IMPORTANT: Section numbers (e.g. '1.4', '1.4.2', '2.3') MUST stay at the very beginning, "
        "right after the '#' markers and before the Chinese text. Do NOT move, remove, or duplicate them.\n"
        "- The English part after ' / ' should contain ONLY the English translation, NO section number.\n\n"
        "Example input:\n"
        "# AI 时代的成长之路\n"
        "## Part 1 — 四段旅程\n"
        "### 1.0 序章：好奇心驱动的三次转向\n"
        "#### 1.0.1 学生时代的三次转向\n\n"
        "Example output:\n"
        "# AI 时代的成长之路 / The Path of Growth in the AI Era\n"
        "## Part 1 — 四段旅程 / Part 1 — Four Journeys\n"
        "### 1.0 序章：好奇心驱动的三次转向 / Prologue: Three Curiosity-Driven Pivots\n"
        "#### 1.0.1 学生时代的三次转向 / Three Pivots During Student Days"
    ),
    "en2zh": (
        "You are a bilingual heading translator.\n"
        "Given a list of English markdown headings (one per line), output the SAME number of lines.\n"
        "Each output line MUST prepend a Chinese translation before the original English text, "
        "separated by ' / '.\n\n"
        "Format: <#markers> <section-number> <Chinese translation> / <original English text without number>\n"
        "- Preserve the leading '#' markers exactly as-is.\n"
        "- If the heading already contains both languages, just normalize spacing around '/'.\n"
        "- Do NOT add any extra lines, explanations, or numbering.\n"
        "- IMPORTANT: Section numbers (e.g. '1.6', '1.6.1', '2.3') from the English heading MUST be "
        "moved to the very beginning (right after '#' markers), before the Chinese text. "
        "The English part after ' / ' should NOT repeat the section number.\n\n"
        "Example input:\n"
        "# The Path of Growth\n"
        "## Part 1 — Four Journeys\n"
        "### 1.6 Shopee Paid Ads Business Overview\n"
        "#### 1.6.1 Traffic Entry Points and Formats\n\n"
        "Example output:\n"
        "# 成长之路 / The Path of Growth\n"
        "## Part 1 — 四段旅程 / Part 1 — Four Journeys\n"
        "### 1.6 Shopee Paid Ads 业务介绍 / Shopee Paid Ads Business Overview\n"
        "#### 1.6.1 流量入口和形态 / Traffic Entry Points and Formats"
    ),
}

BODY_PROMPTS = {
    "full": {
        "zh2en": (
            "You are a professional technical document translator.\n"
            "Translate the following Chinese Markdown content into English.\n\n"
            "CRITICAL RULES:\n"
            "- Output English ONLY. Do NOT keep any Chinese text.\n"
            "- There are NO headings in the input — they have been removed. "
            "Do NOT generate any heading lines (lines starting with #).\n"
            "- Preserve ALL Markdown formatting: lists, tables, code blocks, links, images, blockquotes\n"
            "- Do NOT translate content inside code blocks with language tags (```python, ```bash, etc.) or inline `code`\n"
            "- Text between [PREFORMATTED_TEXT_START] and [PREFORMATTED_TEXT_END] is narrative text — "
            "DO translate it, preserving the whitespace layout (indentation, alignment, arrows like →)\n"
            "- Do NOT translate URLs, file paths, variable names, or HTML tags\n"
            "- Preserve HTML tags exactly as-is (e.g. <img .../>). Do NOT escape angle brackets.\n"
            "- For domain-specific proper nouns, use the established English term "
            "(e.g., '特征存储引擎' → 'Feature Store Engine')\n"
            "- Preserve metadata lines (> **Contributors**: ...) as-is\n"
            "- Output ONLY the translated content, no explanations or wrapping"
        ),
        "en2zh": (
            "You are a professional technical document translator.\n"
            "Translate the following English Markdown content into Chinese.\n\n"
            "CRITICAL RULES:\n"
            "- Output Chinese ONLY. Do NOT keep any English text.\n"
            "- There are NO headings in the input — they have been removed. "
            "Do NOT generate any heading lines (lines starting with #).\n"
            "- Preserve ALL Markdown formatting: lists, tables, code blocks, links, images, blockquotes\n"
            "- Do NOT translate content inside code blocks with language tags (```python, ```bash, etc.) or inline `code`\n"
            "- Text between [PREFORMATTED_TEXT_START] and [PREFORMATTED_TEXT_END] is narrative text — "
            "DO translate it, preserving the whitespace layout (indentation, alignment, arrows like →)\n"
            "- Do NOT translate URLs, file paths, variable names, or HTML tags\n"
            "- Preserve HTML tags exactly as-is. Do NOT escape angle brackets.\n"
            "- For domain-specific terms, add English in parentheses on first occurrence "
            "(e.g., 'Feature Store Engine' → '特征存储引擎 (Feature Store Engine)')\n"
            "- Preserve metadata lines (> **Contributors**: ...) as-is\n"
            "- Output ONLY the translated content, no explanations or wrapping"
        ),
    },
    "incremental": {
        "zh2en": (
            "You are a professional technical document translator.\n"
            "Translate the following MODIFIED SECTION of a Chinese Markdown document into English.\n\n"
            "CRITICAL RULES:\n"
            "- Output English ONLY. Do NOT keep any Chinese text.\n"
            "- There are NO headings in the input. Do NOT generate heading lines.\n"
            "- Preserve ALL Markdown formatting exactly\n"
            "- Do NOT translate code blocks with language tags, URLs, file paths, variable names, or HTML tags\n"
            "- Text between [PREFORMATTED_TEXT_START] and [PREFORMATTED_TEXT_END] is narrative text — "
            "DO translate it, preserving the whitespace layout\n"
            "- Match the style and terminology of the existing translation context provided\n"
            "- Output ONLY the translated section, no explanations or wrapping\n\n"
            "The EXISTING TRANSLATION CONTEXT (for style reference) is provided after '---CONTEXT---'.\n"
            "The SECTION TO TRANSLATE is provided after '---TRANSLATE---'."
        ),
        "en2zh": (
            "You are a professional technical document translator.\n"
            "Translate the following MODIFIED SECTION of an English Markdown document into Chinese.\n\n"
            "CRITICAL RULES:\n"
            "- Output Chinese ONLY. Do NOT keep any English text.\n"
            "- There are NO headings in the input. Do NOT generate heading lines.\n"
            "- Preserve ALL Markdown formatting exactly\n"
            "- Do NOT translate code blocks with language tags, URLs, file paths, variable names, or HTML tags\n"
            "- Text between [PREFORMATTED_TEXT_START] and [PREFORMATTED_TEXT_END] is narrative text — "
            "DO translate it, preserving the whitespace layout\n"
            "- Match the style and terminology of the existing translation context provided\n"
            "- Output ONLY the translated section, no explanations or wrapping\n\n"
            "The EXISTING TRANSLATION CONTEXT (for style reference) is provided after '---CONTEXT---'.\n"
            "The SECTION TO TRANSLATE is provided after '---TRANSLATE---'."
        ),
    },
}

# Alias for translate_text functions
SYSTEM_PROMPTS = {
    "full": BODY_PROMPTS["full"],
    "incremental": BODY_PROMPTS["incremental"],
}

PROVIDERS = {
    "deepseek": {
        "base_url": "https://api.deepseek.com",
        "env_var": "DEEPSEEK_API_KEY",
        "cred_key": "deepseek",
        "default_model": "deepseek-v4-pro",
        "sdk": "openai",
    },
    "openai": {
        "base_url": "https://api.openai.com/v1",
        "env_var": "OPENAI_API_KEY",
        "cred_key": "openai",
        "default_model": "gpt-4o-mini",
        "sdk": "openai",
    },
    "glm": {
        "base_url": "https://open.bigmodel.cn/api/paas/v4",
        "env_var": "GLM_API_KEY",
        "cred_key": "glm",
        "default_model": "glm-4-flash",
        "sdk": "openai",
    },
    "anthropic": {
        "base_url": "https://api.anthropic.com",
        "env_var": "ANTHROPIC_API_KEY",
        "cred_key": "anthropic",
        "default_model": "claude-sonnet-4-20250514",
        "sdk": "anthropic",
    },
    "gemini": {
        "base_url": "https://generativelanguage.googleapis.com/v1beta/openai/",
        "env_var": "GEMINI_API_KEY",
        "cred_key": "gemini",
        "default_model": "gemini-2.0-flash",
        "sdk": "openai",
    },
    "kimi": {
        "base_url": "https://api.moonshot.cn/v1",
        "env_var": "KIMI_API_KEY",
        "cred_key": "kimi",
        "default_model": "moonshot-v1-auto",
        "sdk": "openai",
    },
}


# --- Narrative code block handling ---
# Bare code blocks (``` without language tag) that contain mostly natural
# language text are "narrative blocks".  We replace their ``` markers with
# unique placeholders so the LLM translates them, then restore afterwards.

_NARRATIVE_START = "[PREFORMATTED_TEXT_START]"
_NARRATIVE_END = "[PREFORMATTED_TEXT_END]"


def _is_narrative_block(content: str, source_lang: str) -> bool:
    """Return True if a bare code block contains narrative text, not code."""
    text = content.strip()
    if not text:
        return False
    non_ws = re.sub(r"\s", "", text)
    if not non_ws:
        return False
    if source_lang == "zh":
        cjk_count = len(re.findall(r"[\u4e00-\u9fff]", non_ws))
        return cjk_count / len(non_ws) > 0.3
    else:
        alpha_count = sum(1 for c in non_ws if c.isalpha())
        return alpha_count / len(non_ws) > 0.7


def _mask_narrative_blocks(text: str, source_lang: str) -> str:
    """Replace bare ``` markers around narrative text with placeholders."""
    lines = text.split("\n")
    result: list[str] = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        if stripped == "```":
            block_lines: list[str] = []
            j = i + 1
            while j < len(lines) and lines[j].strip() != "```":
                block_lines.append(lines[j])
                j += 1
            if j < len(lines):
                if _is_narrative_block("\n".join(block_lines), source_lang):
                    result.append(_NARRATIVE_START)
                    result.extend(block_lines)
                    result.append(_NARRATIVE_END)
                else:
                    # Non-narrative code block: keep entire block as-is
                    result.append(lines[i])  # opening ```
                    result.extend(block_lines)
                    result.append(lines[j])  # closing ```
                i = j + 1
                continue
        result.append(lines[i])
        i += 1
    return "\n".join(result)


def _unmask_narrative_blocks(text: str) -> str:
    """Restore ``` markers from narrative block placeholders."""
    return text.replace(_NARRATIVE_START, "```").replace(_NARRATIVE_END, "```")


def _strip_code_fences(text: str) -> str:
    """Strip wrapping markdown code fences if the model adds them.

    Only strips when the entire output is wrapped in ```markdown ... ```
    (first line is opening fence, last line is closing fence) and the
    inner content does NOT contain additional ``` lines (which would
    indicate real code blocks rather than LLM wrapping).
    """
    lines = text.split("\n")
    if len(lines) >= 2 and re.match(r"^```(?:markdown)?$", lines[0]) and lines[-1].strip() == "```":
        inner = lines[1:-1]
        # If inner content contains ``` lines, it's real content not LLM wrapping
        if any(l.strip().startswith("```") for l in inner):
            return text
        return "\n".join(inner)
    return text


def translate_text_openai(
    client: OpenAI,
    text: str,
    source_lang: str,
    target_lang: str,
    model: str,
    context: str | None = None,
) -> str:
    """Translate text using an OpenAI-compatible API."""
    lang_key = f"{source_lang}2{target_lang}"
    mode = "incremental" if context else "full"
    system_prompt = SYSTEM_PROMPTS[mode][lang_key]

    if context:
        user_content = f"---CONTEXT---\n{context}\n\n---TRANSLATE---\n{text}"
    else:
        user_content = text

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content},
        ],
        temperature=0.3,
    )

    return _strip_code_fences(response.choices[0].message.content or "")


def translate_text_anthropic(
    client: "anthropic.Anthropic",  # noqa: F821
    text: str,
    source_lang: str,
    target_lang: str,
    model: str,
    context: str | None = None,
) -> str:
    """Translate text using Anthropic Messages API."""
    lang_key = f"{source_lang}2{target_lang}"
    mode = "incremental" if context else "full"
    system_prompt = SYSTEM_PROMPTS[mode][lang_key]

    if context:
        user_content = f"---CONTEXT---\n{context}\n\n---TRANSLATE---\n{text}"
    else:
        user_content = text

    response = client.messages.create(
        model=model,
        system=system_prompt,
        messages=[{"role": "user", "content": user_content}],
        max_tokens=8192,
        temperature=0.3,
    )

    return _strip_code_fences(response.content[0].text)


def translate_text(
    client,
    text: str,
    source_lang: str,
    target_lang: str,
    model: str,
    sdk_type: str,
    context: str | None = None,
) -> str:
    """Translate text, dispatching to the appropriate SDK.

    Masks narrative code blocks before translation and restores them after.
    """
    masked_text = _mask_narrative_blocks(text, source_lang)
    masked_context = _mask_narrative_blocks(context, source_lang) if context else None

    if sdk_type == "anthropic":
        result = translate_text_anthropic(
            client, masked_text, source_lang, target_lang, model, masked_context
        )
    else:
        result = translate_text_openai(
            client, masked_text, source_lang, target_lang, model, masked_context
        )

    return _unmask_narrative_blocks(result)


def _translate_headings(
    client,
    headings: list[str],
    source_lang: str,
    target_lang: str,
    model: str,
    sdk_type: str,
) -> list[str]:
    """Translate headings using the dedicated bilingual heading prompt."""
    if not headings:
        return []

    lang_key = f"{source_lang}2{target_lang}"
    system_prompt = HEADING_PROMPTS[lang_key]
    heading_text = "\n".join(headings)

    if sdk_type == "anthropic":
        import anthropic as anthropic_sdk  # noqa: F811

        response = client.messages.create(
            model=model,
            system=system_prompt,
            messages=[{"role": "user", "content": heading_text}],
            max_tokens=4096,
            temperature=0.3,
        )
        result = response.content[0].text
    else:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": heading_text},
            ],
            temperature=0.3,
        )
        result = response.choices[0].message.content or ""

    result = _strip_code_fences(result)
    translated = [line for line in result.strip().split("\n") if line.strip()]

    # Ensure same number of headings
    if len(translated) != len(headings):
        print(
            json.dumps({
                "warning": f"Heading count mismatch: expected {len(headings)}, got {len(translated)}. "
                "Padding with originals."
            }),
            file=sys.stderr,
        )
        while len(translated) < len(headings):
            translated.append(headings[len(translated)])
        translated = translated[: len(headings)]

    # Validate bilingual format, retry failures
    for attempt in range(2):
        failed_indices = []
        for i, (orig, trans) in enumerate(zip(headings, translated)):
            if " / " not in trans:
                failed_indices.append(i)
        if not failed_indices:
            break
        print(
            json.dumps({
                "warning": f"Heading bilingual validation failed for {len(failed_indices)} headings "
                f"(attempt {attempt + 1}), retrying individually..."
            }),
            file=sys.stderr,
        )
        retry_input = "\n".join(headings[i] for i in failed_indices)
        if sdk_type == "anthropic":
            resp = client.messages.create(
                model=model,
                system=system_prompt,
                messages=[{"role": "user", "content": retry_input}],
                max_tokens=4096,
                temperature=0.3,
            )
            retry_result = resp.content[0].text
        else:
            resp = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": retry_input},
                ],
                temperature=0.3,
            )
            retry_result = resp.choices[0].message.content or ""
        retry_lines = [line for line in _strip_code_fences(retry_result).strip().split("\n") if line.strip()]
        for j, idx in enumerate(failed_indices):
            if j < len(retry_lines) and " / " in retry_lines[j]:
                translated[idx] = retry_lines[j]

    # Post-process: strip duplicate leading numbering from translated part
    translated = [_dedup_heading_number(h) for h in translated]

    # Post-process: fix section number position (missing or on wrong side)
    translated = [
        _fix_heading_number_position(t, orig)
        for t, orig in zip(translated, headings)
    ]

    return translated


def _dedup_heading_number(title: str) -> str:
    """Remove duplicate leading numbering from bilingual heading.

    Handles both directions:
    - zh2en: '### 1.0.1 学生时代 / 1.0.1 Three Pivots' → '### 1.0.1 学生时代 / Three Pivots'
    - en2zh: '### 1.0 序章 / 1.0 Prologue' → '### 1.0 序章 / Prologue'

    The heading only needs the number once (in whichever side has the original text).
    We keep the number on the left side and strip it from the right if duplicated.
    """
    if " / " not in title:
        return title

    # Split off # markers
    m = re.match(r"^(#{1,6}\s+)(.*)", title)
    if not m:
        return title
    markers, rest = m.group(1), m.group(2)

    parts = rest.split(" / ", 1)
    if len(parts) != 2:
        return title

    left, right = parts

    # Extract leading numbering from left part (e.g. '1.0.1', '2.3')
    left_num_match = re.match(r"^(\d+(?:\.\d+)*)\s+", left.strip())
    if not left_num_match:
        return title

    leading_num = left_num_match.group(1)

    # Check if right part starts with the same numbering — strip it
    right_stripped = right.strip()
    right_num_match = re.match(r"^(\d+(?:\.\d+)*)\s+", right_stripped)
    if right_num_match and right_num_match.group(1) == leading_num:
        right = right_stripped[right_num_match.end():]

    return f"{markers}{left} / {right}"


def _fix_heading_number_position(translated: str, original: str) -> str:
    """Ensure section number stays on the left side of a bilingual heading.

    Compares translated heading against the original to detect and fix:
    1. Number completely missing from translated → restore to left side
    2. Number only on the right side → move to left side

    Examples:
        original:   '### 1.4.2 出价点与考核点的差距'
        translated: '### 出价点与考核点的差距 / Gap Between Bid Point and Assessment Point'
        result:     '### 1.4.2 出价点与考核点的差距 / Gap Between Bid Point and Assessment Point'

        original:   '### 1.6.1 Traffic Entry Points and Formats'
        translated: '### 流量入口和形态 / 1.6.1 Traffic Entry Points and Formats'
        result:     '### 1.6.1 流量入口和形态 / Traffic Entry Points and Formats'
    """
    if " / " not in translated:
        return translated

    # Extract number from original heading
    orig_text = re.sub(r"^#{1,6}\s+", "", original).strip()
    orig_num_match = re.match(r"^(\d+(?:\.\d+)*)\s+", orig_text)
    if not orig_num_match:
        return translated  # original has no number, nothing to fix

    number = orig_num_match.group(1)

    # Split translated heading
    m = re.match(r"^(#{1,6}\s+)(.*)", translated)
    if not m:
        return translated
    markers, rest = m.group(1), m.group(2)

    parts = rest.split(" / ", 1)
    if len(parts) != 2:
        return translated

    left, right = parts[0].strip(), parts[1].strip()

    # Check if left side already has the number
    left_num_match = re.match(r"^(\d+(?:\.\d+)*)\s+", left)
    if left_num_match and left_num_match.group(1) == number:
        return translated  # number already in correct position

    # Check if right side has the number → move it to left
    right_num_match = re.match(r"^(\d+(?:\.\d+)*)\s+", right)
    if right_num_match and right_num_match.group(1) == number:
        right = right[right_num_match.end():]

    # Remove any stale number from left side (different number)
    if left_num_match:
        left = left[left_num_match.end():]

    return f"{markers}{number} {left} / {right}"


def _ensure_number_on_left(title: str) -> str:
    """Ensure any section number in a bilingual heading is on the left side.

    Unlike _fix_heading_number_position which needs the original heading,
    this function works standalone by detecting the number from either side.

    Examples:
        '### 流量入口 / 1.6.1 Traffic Entry Points' → '### 1.6.1 流量入口 / Traffic Entry Points'
        '### 1.4 广告策略 / Ad Strategy' → unchanged (already correct)
    """
    if " / " not in title:
        return title

    m = re.match(r"^(#{1,6}\s+)(.*)", title)
    if not m:
        return title
    markers, rest = m.group(1), m.group(2)

    parts = rest.split(" / ", 1)
    if len(parts) != 2:
        return title

    left, right = parts[0].strip(), parts[1].strip()

    # Check if left already has a number
    left_num = re.match(r"^(\d+(?:\.\d+)*)\s+", left)
    if left_num:
        return title  # number already on left, nothing to do

    # Check if right has a number → move it to left
    right_num = re.match(r"^(\d+(?:\.\d+)*)\s+", right)
    if right_num:
        number = right_num.group(1)
        right = right[right_num.end():]
        return f"{markers}{number} {left} / {right}"

    return title


def validate_translation(text: str, source_lang: str) -> list[dict]:
    """Validate translated text for residual source language in body lines.

    Skips heading lines, code blocks, and metadata lines.
    Returns list of warning dicts with line number and content.
    """
    cjk_pattern = re.compile(r"[\u4e00-\u9fff]")
    heading_pattern = re.compile(r"^#{1,6}\s")
    metadata_pattern = re.compile(r"^>\s*\*\*")

    lines = text.split("\n")
    warnings = []
    in_code_block = False

    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("```"):
            in_code_block = not in_code_block
            continue
        if in_code_block:
            continue
        if heading_pattern.match(stripped):
            continue
        if metadata_pattern.match(stripped):
            continue
        if not stripped:
            continue

        non_ws = re.sub(r"\s", "", stripped)
        if not non_ws:
            continue

        if source_lang == "zh":
            cjk_count = len(cjk_pattern.findall(non_ws))
            ratio = cjk_count / len(non_ws)
            if ratio > 0.3:
                warnings.append({"line": i, "ratio": round(ratio, 2), "text": stripped[:80]})
        else:
            ascii_count = sum(1 for c in non_ws if c.isascii() and c.isalpha())
            ratio = ascii_count / len(non_ws)
            if ratio > 0.7:
                warnings.append({"line": i, "ratio": round(ratio, 2), "text": stripped[:80]})

    return warnings


# --- JSON tree translation functions (Steps 3 + 4) ---


def _detect_heading_lang(title: str) -> str:
    """Detect dominant language of a heading: 'zh' or 'en'."""
    text = re.sub(r"^#{1,6}\s+", "", title).strip()
    cjk_count = len(re.findall(r"[\u4e00-\u9fff]", text))
    non_ws = re.sub(r"\s", "", text)
    if non_ws and cjk_count / len(non_ws) > 0.3:
        return "zh"
    return "en"


def _is_bilingual_heading(title: str) -> bool:
    """Check if a heading is truly bilingual (has ' / ' separating two different languages).

    Returns True only if ' / ' splits the heading into a Chinese-dominant part
    and an English-dominant part. Headings like '重启：AI Agent 时代' that contain
    English words but are fundamentally Chinese are NOT bilingual.
    """
    if " / " not in title:
        return False

    # Strip # markers
    text = re.sub(r"^#{1,6}\s+", "", title).strip()
    parts = text.split(" / ", 1)
    if len(parts) != 2:
        return False

    left, right = parts
    left_cjk = len(re.findall(r"[\u4e00-\u9fff]", left))
    right_cjk = len(re.findall(r"[\u4e00-\u9fff]", right))
    left_non_ws = re.sub(r"\s", "", left)
    right_non_ws = re.sub(r"\s", "", right)

    if not left_non_ws or not right_non_ws:
        return False

    left_ratio = left_cjk / len(left_non_ws)
    right_ratio = right_cjk / len(right_non_ws)

    # One side should be Chinese-dominant (>30%) and the other English-dominant (<30%)
    return (left_ratio > 0.3) != (right_ratio > 0.3)


def translate_json_headings(
    client,
    sections: dict,
    model: str,
    sdk_type: str,
) -> dict:
    """Step 3: Translate all heading titles to bilingual format.

    Skips headings that already contain ' / ' (already bilingual).
    Detects source language from heading content.
    """
    # Collect headings that need translation
    to_translate_zh = []  # (section_id, title) for Chinese headings
    to_translate_en = []  # (section_id, title) for English headings
    sid_order_zh = []
    sid_order_en = []

    for sid, sec in sections.items():
        title = sec["title"]
        if title == "---":
            continue  # horizontal-rule separator, not a translatable heading
        if _is_bilingual_heading(title):
            continue  # already bilingual
        lang = _detect_heading_lang(title)
        if lang == "zh":
            to_translate_zh.append(title)
            sid_order_zh.append(sid)
        else:
            to_translate_en.append(title)
            sid_order_en.append(sid)

    # Translate Chinese headings → bilingual
    if to_translate_zh:
        print(
            json.dumps({"progress": f"Translating {len(to_translate_zh)} Chinese headings..."}),
            file=sys.stderr,
        )
        translated = _translate_headings(
            client, to_translate_zh, "zh", "en", model, sdk_type
        )
        for sid, new_title in zip(sid_order_zh, translated):
            sections[sid]["title"] = new_title

    # Translate English headings → bilingual
    if to_translate_en:
        print(
            json.dumps({"progress": f"Translating {len(to_translate_en)} English headings..."}),
            file=sys.stderr,
        )
        translated = _translate_headings(
            client, to_translate_en, "en", "zh", model, sdk_type
        )
        for sid, new_title in zip(sid_order_en, translated):
            sections[sid]["title"] = new_title

    # Final pass: ensure section numbers are on the left side for ALL headings
    for sid, sec in sections.items():
        title = sec["title"]
        if title == "---":
            continue
        if " / " in title:
            sections[sid]["title"] = _ensure_number_on_left(title)

    return sections


def translate_json_content(
    client,
    sections: dict,
    model: str,
    sdk_type: str,
    force: bool = False,
    max_workers: int = 10,
) -> tuple[dict, dict]:
    """Step 4: Smart incremental translation of leaf node content.

    For each leaf node:
    - If both timestamps equal and both contents non-empty: skip
    - If zh missing: translate en→zh
    - If en missing: translate zh→en
    - If zh newer: translate zh→en
    - If en newer: translate en→zh
    - If force: translate all regardless

    Translates up to max_workers leaves concurrently.
    Returns (updated_sections, stats_dict).
    """
    from concurrent.futures import ThreadPoolExecutor, as_completed

    stats = {"skipped": 0, "translated": 0, "warnings": 0}
    leaves = [(sid, sec) for sid, sec in sections.items() if sec.get("is_leaf")]
    total = len(leaves)

    # Phase 1: determine which leaves need translation and their direction
    tasks = []  # (sid, sec, source_lang, target_lang, source_content, context)
    for sid, sec in leaves:
        content_zh = sec.get("content_zh") or ""
        content_en = sec.get("content_en") or ""
        ts_zh = sec.get("last_update_time_zh")
        ts_en = sec.get("last_update_time_en")

        if not force:
            zh_empty = not content_zh.strip()
            en_empty = not content_en.strip()

            if not zh_empty and not en_empty and ts_zh == ts_en:
                stats["skipped"] += 1
                continue
            if zh_empty and en_empty:
                stats["skipped"] += 1
                continue

            if zh_empty:
                source_lang, target_lang = "en", "zh"
                source_content = content_en
                context = content_zh if content_zh.strip() else None
            elif en_empty:
                source_lang, target_lang = "zh", "en"
                source_content = content_zh
                context = content_en if content_en.strip() else None
            elif ts_zh and ts_en and ts_zh > ts_en:
                source_lang, target_lang = "zh", "en"
                source_content = content_zh
                context = content_en
            else:
                source_lang, target_lang = "en", "zh"
                source_content = content_en
                context = content_zh
        else:
            if content_zh.strip():
                source_lang, target_lang = "zh", "en"
                source_content = content_zh
                context = content_en if content_en.strip() else None
            elif content_en.strip():
                source_lang, target_lang = "en", "zh"
                source_content = content_en
                context = content_zh if content_zh.strip() else None
            else:
                stats["skipped"] += 1
                continue

        tasks.append((sid, sec, source_lang, target_lang, source_content, context))

    print(
        json.dumps({"progress": f"Translating {len(tasks)} leaves (concurrency={max_workers})..."}),
        file=sys.stderr,
    )

    # Phase 2: translate concurrently
    def _translate_one(task):
        sid, sec, src_lang, tgt_lang, src_content, ctx = task
        translated = translate_text(
            client, src_content, src_lang, tgt_lang, model, sdk_type, ctx
        )
        w = validate_translation(translated, src_lang)
        return sid, sec, tgt_lang, translated, w

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(_translate_one, t): t[0] for t in tasks}
        done_count = 0
        for future in as_completed(futures):
            sid = futures[future]
            done_count += 1
            try:
                sid, sec, tgt_lang, translated, w = future.result()
                now_iso = datetime.now(timezone.utc).isoformat()
                meta_line = f"<!-- last_translated: {now_iso} -->"
                sec[f"content_{tgt_lang}"] = f"{meta_line}\n\n{translated}"
                stats["translated"] += 1
                if w:
                    stats["warnings"] += len(w)
                    print(
                        json.dumps({"validation_warnings": w, "section": sid}),
                        file=sys.stderr,
                    )
                print(
                    json.dumps({"progress": f"[{done_count}/{len(tasks)}] Section {sid}: done"}),
                    file=sys.stderr,
                )
            except Exception as e:
                print(
                    json.dumps({"error": f"Section {sid} failed: {e}"}),
                    file=sys.stderr,
                )

    return sections, stats


def _resolve_api_key(provider_config: dict, explicit_key: str) -> str:
    """Resolve API key: explicit arg > env var > credentials.json."""
    if explicit_key:
        return explicit_key
    key = os.environ.get(provider_config["env_var"], "")
    if key:
        return key
    cred_path = Path.home() / ".config" / "sra" / "credentials.json"
    if cred_path.exists():
        creds = json.loads(cred_path.read_text())
        key = creds.get(provider_config["cred_key"], {}).get("api_key", "")
    return key


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Translate JSON tree via LLM API (multi-provider)"
    )
    parser.add_argument(
        "--provider",
        default="deepseek",
        choices=list(PROVIDERS.keys()),
        help="LLM provider (default: deepseek)",
    )
    parser.add_argument("--api-key", default="")
    parser.add_argument("--model", default=None, help="Model name (default: per-provider)")
    parser.add_argument("--input-json", type=Path, required=True, help="Input JSON tree from preprocess.py")
    parser.add_argument("--output-json", type=Path, required=True, help="Output JSON tree with translations")
    parser.add_argument("--force", action="store_true", help="Translate all leaves regardless of timestamps")
    args = parser.parse_args()

    provider_config = PROVIDERS[args.provider]
    model = args.model or provider_config["default_model"]

    api_key = _resolve_api_key(provider_config, args.api_key)
    if not api_key:
        print(
            json.dumps({
                "error": (
                    f"No API key for provider '{args.provider}'. "
                    f"Set {provider_config['env_var']} or configure "
                    f"~/.config/sra/credentials.json [{provider_config['cred_key']}.api_key]"
                )
            }),
            file=sys.stderr,
        )
        sys.exit(1)

    # Read input JSON tree
    tree = json.loads(args.input_json.read_text(encoding="utf-8"))
    sections = tree["sections"]

    # Create client
    sdk_type = provider_config["sdk"]
    if sdk_type == "anthropic":
        import anthropic as anthropic_sdk

        client = anthropic_sdk.Anthropic(api_key=api_key)
    else:
        client = OpenAI(api_key=api_key, base_url=provider_config["base_url"])

    # Step 3: Translate headings
    sections = translate_json_headings(client, sections, model, sdk_type)

    # Step 4: Translate leaf content
    sections, stats = translate_json_content(
        client, sections, model, sdk_type, force=args.force
    )

    # Write output
    tree["sections"] = sections
    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    args.output_json.write_text(
        json.dumps(tree, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    info = {
        "status": "ok",
        "provider": args.provider,
        "model": model,
        "translated": stats["translated"],
        "skipped": stats["skipped"],
        "validation_warnings": stats["warnings"],
    }
    print(json.dumps(info))


if __name__ == "__main__":
    main()
