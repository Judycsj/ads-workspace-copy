# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
Reassemble translated JSON tree back into Chinese and English markdown files.

Reads the JSON tree produced by translate.py and outputs two markdown files
with bilingual headings, monolingual content, and file-level metadata
(Contributors, Language interlinks).
"""

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

GITLAB_BASE = (
    "https://git.garena.com/shopee/search_recommend/ai-copilot/"
    "ads-workspace/-/blob/master/"
)


def _section_sort_key(section_id: str) -> list:
    """Sort key for section IDs: '1' < '1.1' < '1.2' < '2'.

    Handles 'en_' prefix for unmatched EN sections.
    """
    sid = section_id
    if sid.startswith("en_"):
        sid = sid[3:]
    parts = sid.split(".")
    result = []
    for p in parts:
        try:
            result.append(int(p))
        except ValueError:
            result.append(0)
    return result


def _find_repo_root(start: Path) -> Path:
    """Walk up to find .git directory."""
    current = start.resolve()
    for parent in [current, *current.parents]:
        if (parent / ".git").exists():
            return parent
    return Path.cwd()


def _repo_relative(filepath: Path, repo_root: Path) -> str:
    """Get repo-relative path for a file."""
    try:
        return str(filepath.resolve().relative_to(repo_root))
    except ValueError:
        return str(filepath)


def _build_contributors_line(
    source_content: str, target_path: Path, repo_root: Path,
) -> str:
    """Build Contributors line, extracting author from source if present."""
    contributors = "luka.yang"
    for line in source_content.split("\n"):
        if line.startswith("> **Contributors**:"):
            match = re.search(r"\*\*Contributors\*\*:\s*(.+?)(?:\s*[｜|])", line)
            if match:
                contributors = match.group(1).strip()
            break

    today = date.today().strftime("%Y-%m-%d")
    rel_path = _repo_relative(target_path, repo_root)
    gitlab_url = GITLAB_BASE + rel_path

    return (
        f"> **Contributors**: {contributors} ｜ "
        f"**最后更新**：{today} ｜ "
        f"[GitLab]({gitlab_url})"
    )


def _build_language_line(zh_path: Path, en_path: Path) -> str:
    """Build Language interlink line."""
    return f"> **Language**: [English]({en_path.name}) | [中文]({zh_path.name})"


def _read_source_content(tree: dict) -> str:
    """Read source file content for extracting existing Contributors info."""
    meta = tree.get("meta", {})
    for key in ("source_file_zh", "source_file_en"):
        fpath = meta.get(key)
        if fpath and Path(fpath).exists():
            return Path(fpath).read_text(encoding="utf-8")
    return ""


def reassemble_markdown(tree: dict, lang: str) -> str:
    """Convert JSON tree back into a markdown file for one language.

    Args:
        tree: The full JSON tree with meta, preamble, sections.
        lang: 'zh' or 'en'.

    Returns:
        Complete markdown content as a string.
    """
    parts = []

    # Preamble
    preamble_key = f"preamble_{lang}"
    preamble = tree.get(preamble_key)
    if preamble and preamble.strip():
        parts.append(preamble.rstrip())

    # Sections in order
    sections = tree.get("sections", {})
    sorted_ids = sorted(sections.keys(), key=_section_sort_key)

    for sid in sorted_ids:
        sec = sections[sid]
        title = sec.get("title", "")

        # Emit heading: '---' separators are output as-is (no bilingual title)
        if title == "---":
            parts.append("---")
        else:
            parts.append(title)

        # For leaf nodes: emit content (already contains <!-- last_translated --> from translate.py)
        if sec.get("is_leaf"):
            content_key = f"content_{lang}"
            content = sec.get(content_key) or ""
            if content.strip():
                parts.append(content.rstrip())

    return "\n\n".join(parts) + "\n"


def insert_metadata(
    content: str,
    contributors_line: str,
    language_line: str,
) -> str:
    """Insert Contributors and Language lines after the first # heading."""
    lines = content.split("\n")
    result = []
    heading_found = False

    for line in lines:
        # Skip any existing metadata lines
        if line.startswith("> **Contributors**:") or line.startswith("> **Language**:"):
            continue
        result.append(line)
        if not heading_found and line.startswith("# "):
            heading_found = True
            result.append("")
            result.append(contributors_line)
            result.append(language_line)

    if not heading_found:
        result = [contributors_line, language_line, ""] + result

    return "\n".join(result)


def ensure_source_language_line(source_path: Path, other_path: Path) -> str | None:
    """Add Language line to source file if missing. Returns action message or None."""
    if not source_path.exists():
        return None
    content = source_path.read_text(encoding="utf-8")
    if "> **Language**:" in content:
        return None

    # Determine zh/en paths
    name = source_path.name
    if ".EN." in name or ".EN.md" in name:
        lang_line = _build_language_line(other_path, source_path)
    else:
        lang_line = _build_language_line(source_path, other_path)

    lines = content.split("\n")
    for i, line in enumerate(lines):
        if line.startswith("> **Contributors**:"):
            lines.insert(i + 1, lang_line)
            source_path.write_text("\n".join(lines), encoding="utf-8")
            return f"Added Language line to source: {source_path.name}"

    return None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Reassemble JSON tree into Chinese and English markdown files"
    )
    parser.add_argument("--input-json", type=Path, required=True, help="Input JSON tree")
    parser.add_argument("--zh-output", type=Path, help="Output Chinese markdown file")
    parser.add_argument("--en-output", type=Path, help="Output English markdown file")
    args = parser.parse_args()

    if not args.zh_output and not args.en_output:
        print(json.dumps({"error": "At least one of --zh-output or --en-output must be provided"}),
              file=sys.stderr)
        sys.exit(1)

    tree = json.loads(args.input_json.read_text(encoding="utf-8"))
    meta = tree.get("meta", {})

    # Determine file paths for metadata
    zh_path = args.zh_output or (Path(meta["source_file_zh"]) if meta.get("source_file_zh") else None)
    en_path = args.en_output or (Path(meta["source_file_en"]) if meta.get("source_file_en") else None)

    # Read source content for Contributors extraction
    source_content = _read_source_content(tree)

    # Find repo root for GitLab links
    ref_path = zh_path or en_path or Path.cwd()
    repo_root = _find_repo_root(ref_path)

    result = {"status": "ok", "actions": []}

    if args.zh_output:
        zh_content = reassemble_markdown(tree, "zh")
        if en_path:
            contributors = _build_contributors_line(source_content, args.zh_output, repo_root)
            lang_line = _build_language_line(args.zh_output, en_path)
            zh_content = insert_metadata(zh_content, contributors, lang_line)
        args.zh_output.parent.mkdir(parents=True, exist_ok=True)
        args.zh_output.write_text(zh_content, encoding="utf-8")
        result["zh_chars"] = len(zh_content)

    if args.en_output:
        en_content = reassemble_markdown(tree, "en")
        if zh_path:
            contributors = _build_contributors_line(source_content, args.en_output, repo_root)
            lang_line = _build_language_line(zh_path, args.en_output)
            en_content = insert_metadata(en_content, contributors, lang_line)
        args.en_output.parent.mkdir(parents=True, exist_ok=True)
        args.en_output.write_text(en_content, encoding="utf-8")
        result["en_chars"] = len(en_content)

    # Ensure source files have Language line
    if args.zh_output and args.en_output:
        for src_key in ("source_file_zh", "source_file_en"):
            src = meta.get(src_key)
            if src and Path(src).exists():
                other = args.en_output if "zh" in src_key else args.zh_output
                action = ensure_source_language_line(Path(src), other)
                if action:
                    result["actions"].append(action)

    print(json.dumps(result))


if __name__ == "__main__":
    main()
