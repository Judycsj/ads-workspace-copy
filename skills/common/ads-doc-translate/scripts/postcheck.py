# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
Post-translation markdown structure parity check.

Compares zh and en markdown files to verify that all structural tokens
(code fences, tables, images, links, HTML tags, math blocks, etc.)
are consistent between the two versions.
"""

import argparse
import json
import re
import sys
from pathlib import Path


# Patterns for structural extraction (outside code blocks)
_TABLE_ROW_RE = re.compile(r"^\|.*\|$")
_TABLE_SEP_RE = re.compile(r"^\|[-:\s|]+\|$")
_IMAGE_RE = re.compile(r"!\[([^\]]*)\]\(([^)]+)\)")
_LINK_RE = re.compile(r"(?<!!)\[([^\]]*)\]\(([^)]+)\)")
_HTML_TAG_RE = re.compile(r"<(/?\w+)[^>]*>")
_INLINE_MATH_RE = re.compile(r"(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)")
_HR_RE = re.compile(r"^-{3,}$")
_METADATA_RE = re.compile(r'^>\s*\*\*(Contributors|Language|最后更新)')
_LAST_TRANSLATED_RE = re.compile(r"^<!--\s*last_translated:")


def extract_structure(filepath: Path) -> dict:
    """Extract markdown structural tokens from a file.

    Returns a dict with token sequences/counts for each check category.
    """
    text = filepath.read_text(encoding="utf-8")
    lines = text.split("\n")

    code_fences: list[str] = []  # each fence line (e.g. "```python", "```")
    code_langs: list[str] = []   # language labels in order
    table_groups: list[int] = []  # row count per table
    table_seps = 0
    image_urls: list[str] = []
    link_urls: list[str] = []
    html_tags: list[str] = []
    math_blocks = 0      # $$ line count
    inline_math = 0       # $...$ count
    blockquotes = 0
    hr_count = 0

    in_code_fence = False
    current_table_rows = 0
    in_table = False

    for line in lines:
        stripped = line.strip()

        # Skip metadata lines
        if _METADATA_RE.match(stripped):
            continue
        if _LAST_TRANSLATED_RE.match(stripped):
            continue

        # Code fence detection
        if stripped.startswith("```"):
            code_fences.append(stripped)
            if not in_code_fence:
                # Opening fence - extract language
                lang = stripped[3:].strip()
                code_langs.append(lang)
                in_code_fence = True
            else:
                in_code_fence = False
            # Flush any open table
            if in_table:
                table_groups.append(current_table_rows)
                current_table_rows = 0
                in_table = False
            continue

        # Inside code block - skip all structural checks
        if in_code_fence:
            continue

        # Math block $$
        if stripped == "$$":
            math_blocks += 1
            continue

        # Horizontal rule
        if _HR_RE.match(stripped):
            hr_count += 1
            if in_table:
                table_groups.append(current_table_rows)
                current_table_rows = 0
                in_table = False
            continue

        # Table rows
        if _TABLE_ROW_RE.match(stripped):
            if _TABLE_SEP_RE.match(stripped):
                table_seps += 1
            current_table_rows += 1
            in_table = True
        else:
            if in_table:
                table_groups.append(current_table_rows)
                current_table_rows = 0
                in_table = False

        # Images
        for m in _IMAGE_RE.finditer(line):
            image_urls.append(m.group(2))

        # Links (exclude images and anchor-only links which differ by language)
        for m in _LINK_RE.finditer(line):
            url = m.group(2)
            if not url.startswith("#"):
                link_urls.append(url)

        # HTML tags
        for m in _HTML_TAG_RE.finditer(line):
            html_tags.append(m.group(1).lower())

        # Inline math
        inline_math += len(_INLINE_MATH_RE.findall(line))

        # Blockquotes (exclude metadata)
        if stripped.startswith(">") and not _METADATA_RE.match(stripped):
            blockquotes += 1

    # Flush trailing table
    if in_table:
        table_groups.append(current_table_rows)

    return {
        "code_fences": code_fences,
        "code_fence_count": len(code_fences),
        "code_langs": code_langs,
        "table_groups": table_groups,
        "table_seps": table_seps,
        "image_urls": image_urls,
        "link_urls": link_urls,
        "html_tags": html_tags,
        "math_blocks": math_blocks,
        "inline_math": inline_math,
        "blockquotes": blockquotes,
        "hr_count": hr_count,
    }


def compare_structures(zh: dict, en: dict) -> list[dict]:
    """Compare two structure dicts and return list of differences."""
    errors: list[dict] = []

    # 1. Code fence count
    if zh["code_fence_count"] != en["code_fence_count"]:
        errors.append({
            "check": "code_fences",
            "zh": zh["code_fence_count"],
            "en": en["code_fence_count"],
            "detail": f"Code fence count mismatch: zh={zh['code_fence_count']}, en={en['code_fence_count']}",
        })

    # 2. Code fence language labels (ordered sequence)
    if zh["code_langs"] != en["code_langs"]:
        errors.append({
            "check": "code_langs",
            "zh": zh["code_langs"],
            "en": en["code_langs"],
            "detail": f"Code block language labels differ: zh={zh['code_langs']}, en={en['code_langs']}",
        })

    # 3. Table groups (row counts per table)
    if zh["table_groups"] != en["table_groups"]:
        errors.append({
            "check": "table_groups",
            "zh": zh["table_groups"],
            "en": en["table_groups"],
            "detail": f"Table row counts differ: zh={zh['table_groups']}, en={en['table_groups']}",
        })

    # 4. Table separator rows
    if zh["table_seps"] != en["table_seps"]:
        errors.append({
            "check": "table_seps",
            "zh": zh["table_seps"],
            "en": en["table_seps"],
            "detail": f"Table separator row count mismatch: zh={zh['table_seps']}, en={en['table_seps']}",
        })

    # 5. Image URLs (ordered)
    if zh["image_urls"] != en["image_urls"]:
        errors.append({
            "check": "image_urls",
            "zh": zh["image_urls"],
            "en": en["image_urls"],
            "detail": f"Image URLs differ: zh={zh['image_urls']}, en={en['image_urls']}",
        })

    # 6. Link URLs (ordered)
    if zh["link_urls"] != en["link_urls"]:
        errors.append({
            "check": "link_urls",
            "zh": zh["link_urls"],
            "en": en["link_urls"],
            "detail": f"Link URLs differ: zh={zh['link_urls']}, en={en['link_urls']}",
        })

    # 7. HTML tags (ordered)
    if zh["html_tags"] != en["html_tags"]:
        errors.append({
            "check": "html_tags",
            "zh": zh["html_tags"],
            "en": en["html_tags"],
            "detail": f"HTML tag sequence differs: zh={zh['html_tags']}, en={en['html_tags']}",
        })

    # 8. Math blocks $$
    if zh["math_blocks"] != en["math_blocks"]:
        errors.append({
            "check": "math_blocks",
            "zh": zh["math_blocks"],
            "en": en["math_blocks"],
            "detail": f"Math block ($$) count mismatch: zh={zh['math_blocks']}, en={en['math_blocks']}",
        })

    # 9. Inline math $...$
    if zh["inline_math"] != en["inline_math"]:
        errors.append({
            "check": "inline_math",
            "zh": zh["inline_math"],
            "en": en["inline_math"],
            "detail": f"Inline math ($...$) count mismatch: zh={zh['inline_math']}, en={en['inline_math']}",
        })

    # 10. Blockquotes
    if zh["blockquotes"] != en["blockquotes"]:
        errors.append({
            "check": "blockquotes",
            "zh": zh["blockquotes"],
            "en": en["blockquotes"],
            "detail": f"Blockquote count mismatch: zh={zh['blockquotes']}, en={en['blockquotes']}",
        })

    # 11. Horizontal rules
    if zh["hr_count"] != en["hr_count"]:
        errors.append({
            "check": "hr_count",
            "zh": zh["hr_count"],
            "en": en["hr_count"],
            "detail": f"Horizontal rule count mismatch: zh={zh['hr_count']}, en={en['hr_count']}",
        })

    return errors


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Check markdown structural parity between zh and en files"
    )
    parser.add_argument("--zh-file", type=Path, required=True, help="Chinese markdown file")
    parser.add_argument("--en-file", type=Path, required=True, help="English markdown file")
    args = parser.parse_args()

    for f in (args.zh_file, args.en_file):
        if not f.exists():
            print(json.dumps({"status": "error", "message": f"File not found: {f}"}))
            sys.exit(1)

    zh_struct = extract_structure(args.zh_file)
    en_struct = extract_structure(args.en_file)
    errors = compare_structures(zh_struct, en_struct)

    # Build check summary
    check_names = [
        "code_fences", "code_langs", "table_groups", "table_seps",
        "image_urls", "link_urls", "html_tags",
        "math_blocks", "inline_math", "blockquotes", "hr_count",
    ]
    checks = []
    error_keys = {e["check"] for e in errors}
    for name in check_names:
        checks.append({
            "check": name,
            "status": "fail" if name in error_keys else "ok",
        })

    result = {
        "status": "fail" if errors else "ok",
        "checks": checks,
        "errors": len(errors),
    }
    if errors:
        result["details"] = errors

    print(json.dumps(result, ensure_ascii=False))
    if errors:
        # Also print human-readable summary to stderr
        print(f"\n⚠ {len(errors)} structural difference(s) found:", file=sys.stderr)
        for e in errors:
            print(f"  - [{e['check']}] {e['detail']}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
