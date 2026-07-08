# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
Preprocess Chinese and English markdown files into a structured JSON tree.

Parses heading hierarchy, extracts content per section, and uses git blame
to determine last update timestamps for each leaf section.
"""

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


HR_SEPARATOR = "---"
HR_LEVEL = 99  # special level for horizontal-rule sections


def _split_by_hr(lines: list[str]) -> list[dict]:
    """Split lines by '---' horizontal rules when no heading structure exists.

    Each '---' becomes a section with heading='---', level=99.
    Content before the first '---' becomes preamble (heading=None, level=0).
    """
    hr_positions = [i for i, line in enumerate(lines) if line.strip() == HR_SEPARATOR]

    if not hr_positions:
        return [{"heading": None, "level": 0, "body": "\n".join(lines),
                 "line_start": 1, "line_end": len(lines)}]

    sections = []

    # Preamble: content before first '---'
    first_hr = hr_positions[0]
    if first_hr > 0:
        sections.append({
            "heading": None,
            "level": 0,
            "body": "\n".join(lines[:first_hr]),
            "line_start": 1,
            "line_end": first_hr,
        })

    # Each '---' section: '---' line + body until next '---' or EOF
    for idx, hr_pos in enumerate(hr_positions):
        if idx + 1 < len(hr_positions):
            next_pos = hr_positions[idx + 1]
        else:
            next_pos = len(lines)

        body_lines = lines[hr_pos + 1 : next_pos]
        sections.append({
            "heading": HR_SEPARATOR,
            "level": HR_LEVEL,
            "body": "\n".join(body_lines),
            "line_start": hr_pos + 1,  # 1-based
            "line_end": next_pos,
        })

    return sections


def parse_markdown_sections(text: str) -> list[dict]:
    """Parse markdown into ordered list of sections.

    Returns: [{heading, level, body, line_start, line_end}]
    - heading: full heading line including # markers, '---', or None for preamble
    - level: 1-6 for headings, 99 for '---' separators, or 0 for preamble
    - body: text between this heading and the next heading (excluding heading line itself)
    - line_start: 1-based line number of heading (or 1 for preamble)
    - line_end: 1-based line number of last line before next heading

    When the document has <=1 heading but multiple '---' separators,
    falls back to splitting by '---' (treated as level-99 pseudo-headings).
    """
    lines = text.split("\n")
    heading_re = re.compile(r"^(#{1,6})\s+.+$")

    # Find all heading line positions (skip lines inside code fences)
    heading_positions = []
    in_code_fence = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("```"):
            in_code_fence = not in_code_fence
            continue
        if in_code_fence:
            continue
        m = heading_re.match(line)
        if m:
            heading_positions.append((i, len(m.group(1)), line))

    # Fallback: if <=1 heading but multiple '---', split by '---'
    hr_count = sum(1 for line in lines if line.strip() == HR_SEPARATOR)
    if len(heading_positions) <= 1 and hr_count >= 2:
        return _split_by_hr(lines)

    sections = []

    # Preamble: content before first heading
    if not heading_positions:
        return [{"heading": None, "level": 0, "body": text,
                 "line_start": 1, "line_end": len(lines)}]

    first_pos = heading_positions[0][0]
    if first_pos > 0:
        preamble_lines = lines[:first_pos]
        sections.append({
            "heading": None,
            "level": 0,
            "body": "\n".join(preamble_lines),
            "line_start": 1,
            "line_end": first_pos,  # 1-based, exclusive of heading
        })

    # Each heading section
    for idx, (pos, level, heading_line) in enumerate(heading_positions):
        if idx + 1 < len(heading_positions):
            next_pos = heading_positions[idx + 1][0]
        else:
            next_pos = len(lines)

        body_lines = lines[pos + 1 : next_pos]
        sections.append({
            "heading": heading_line,
            "level": level,
            "body": "\n".join(body_lines),
            "line_start": pos + 1,  # 1-based
            "line_end": next_pos,   # 1-based, exclusive
        })

    return sections


def assign_section_ids(sections: list[dict]) -> dict:
    """Assign flat key IDs and determine leaf status.

    Returns dict keyed by section ID ("1", "1.1", "1.1.1", etc.)
    with is_leaf and parent fields added.

    A leaf node has no child headings (no deeper level before next same-or-higher level).

    For '---' separated documents (level=HR_LEVEL), all sections are flat leaves
    with sequential IDs ("1", "2", "3", ...) and no parent hierarchy.
    """
    # Filter out preamble for ID assignment
    heading_sections = [s for s in sections if s["heading"] is not None]

    if not heading_sections:
        return {}

    # Fast path: all '---' sections → flat sequential IDs, all leaves
    if all(s["level"] == HR_LEVEL for s in heading_sections):
        result = {}
        for i, section in enumerate(heading_sections, start=1):
            result[str(i)] = {
                "title": section["heading"],
                "level": section["level"],
                "parent": None,
                "line_start": section["line_start"],
                "line_end": section["line_end"],
                "body": section["body"],
                "is_leaf": True,
            }
        return result

    # Assign sequential IDs based on heading hierarchy
    result = {}
    counters = {}  # level -> current count at that level
    id_stack = []  # stack of (level, id_part)

    for i, section in enumerate(heading_sections):
        level = section["level"]

        # Pop stack until we find parent level
        while id_stack and id_stack[-1][0] >= level:
            id_stack.pop()

        # Determine parent ID
        parent_id = ".".join(str(x[1]) for x in id_stack) if id_stack else None

        # Counter key is the parent path + level
        counter_key = (parent_id or "", level)
        counters[counter_key] = counters.get(counter_key, 0) + 1

        # Build section ID
        id_part = counters[counter_key]
        if parent_id:
            section_id = f"{parent_id}.{id_part}"
        else:
            section_id = str(id_part)

        id_stack.append((level, id_part))

        result[section_id] = {
            "title": section["heading"],
            "level": level,
            "parent": parent_id,
            "line_start": section["line_start"],
            "line_end": section["line_end"],
            "body": section["body"],
        }

    # Determine leaf status: a section is a leaf if no section has it as parent prefix
    all_ids = set(result.keys())
    for sid in all_ids:
        has_children = any(
            other_id.startswith(sid + ".") for other_id in all_ids if other_id != sid
        )
        result[sid]["is_leaf"] = not has_children

    return result


def get_blame_timestamps(filepath: str) -> dict[int, int]:
    """Run git blame on file, return {1-based line_number: unix_timestamp}.

    Returns empty dict if file is not tracked by git.
    """
    try:
        result = subprocess.run(
            ["git", "blame", "-t", "--porcelain", filepath],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            return {}
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return {}

    # Parse porcelain format: build commit→timestamp map, then line→commit map
    commit_timestamps: dict[str, int] = {}
    line_commits: dict[int, str] = {}

    header_re = re.compile(r"^([0-9a-f]{40})\s+(\d+)\s+(\d+)")
    time_re = re.compile(r"^author-time\s+(\d+)")

    current_commit = ""
    current_line = 0

    for raw_line in result.stdout.split("\n"):
        m = header_re.match(raw_line)
        if m:
            current_commit = m.group(1)
            current_line = int(m.group(3))  # final line number
            line_commits[current_line] = current_commit
            continue
        m = time_re.match(raw_line)
        if m:
            commit_timestamps[current_commit] = int(m.group(1))

    # Build line→timestamp from the two maps
    timestamps = {}
    for line_num, commit_hash in line_commits.items():
        if commit_hash in commit_timestamps:
            timestamps[line_num] = commit_timestamps[commit_hash]

    return timestamps


def max_timestamp_for_range(
    blame: dict[int, int], start: int, end: int
) -> str | None:
    """Get max timestamp in [start, end) line range, return ISO 8601 or None."""
    if not blame:
        return None

    max_ts = 0
    for line_num in range(start, end):
        ts = blame.get(line_num, 0)
        if ts > max_ts:
            max_ts = ts

    if max_ts == 0:
        return None

    dt = datetime.fromtimestamp(max_ts, tz=timezone.utc)
    return dt.isoformat()


_LAST_TRANSLATED_RE = re.compile(r'<!--\s*last_translated:\s*(\S+)\s*-->')


def _extract_last_translated(body: str) -> tuple[str, str | None]:
    """Extract and strip <!-- last_translated: ... --> from body.

    Returns (cleaned_body, iso_timestamp_or_None).
    """
    m = _LAST_TRANSLATED_RE.search(body)
    if not m:
        return body, None

    ts = m.group(1)
    # Remove the entire line containing the comment
    cleaned = re.sub(r'^\s*<!--\s*last_translated:\s*\S+\s*-->\s*\n?', '', body, count=1, flags=re.MULTILINE)
    return cleaned, ts


def _max_iso_timestamp(ts1: str | None, ts2: str | None) -> str | None:
    """Return the later of two ISO 8601 timestamps (string comparison works for ISO)."""
    if ts1 is None:
        return ts2
    if ts2 is None:
        return ts1
    return max(ts1, ts2)


def _normalize_heading(heading: str) -> str:
    """Strip # markers and normalize whitespace for comparison."""
    return re.sub(r"^#{1,6}\s+", "", heading).strip().lower()


def _heading_level(heading: str) -> int:
    """Extract heading level from a heading line."""
    m = re.match(r"^(#{1,6})\s", heading)
    return len(m.group(1)) if m else 0


def match_sections(
    zh_sections: dict, en_sections: dict
) -> dict:
    """Match sections between ZH and EN files, merge into unified tree.

    Matching strategy:
    1. Exact normalized heading match
    2. Bilingual heading split match (before/after ' / ')
    3. Positional match by level and order

    Returns merged sections dict with content_zh, content_en, timestamps.
    """
    merged = {}

    # Build lookup for EN sections by normalized heading
    en_by_heading = {}
    en_by_position = {}
    for eid, esec in en_sections.items():
        norm = _normalize_heading(esec["title"])
        en_by_heading[norm] = (eid, esec)
        # Also index by split parts for bilingual headings
        if " / " in esec["title"]:
            parts = esec["title"].split(" / ", 1)
            for part in parts:
                en_by_heading[_normalize_heading(part)] = (eid, esec)

    # Track which EN sections have been matched
    matched_en = set()

    # Build position-based index for EN
    en_by_level_order = {}
    level_counters_en = {}
    for eid in sorted(en_sections.keys(), key=_section_sort_key):
        esec = en_sections[eid]
        level = esec["level"]
        level_counters_en[level] = level_counters_en.get(level, 0) + 1
        en_by_level_order[(level, level_counters_en[level])] = (eid, esec)

    # Match ZH sections to EN sections
    level_counters_zh = {}
    for zid in sorted(zh_sections.keys(), key=_section_sort_key):
        zsec = zh_sections[zid]
        level = zsec["level"]
        level_counters_zh[level] = level_counters_zh.get(level, 0) + 1

        en_match = None
        en_match_id = None

        # Strategy 1: exact normalized match
        norm_zh = _normalize_heading(zsec["title"])
        if norm_zh in en_by_heading:
            en_match_id, en_match = en_by_heading[norm_zh]

        # Strategy 2: bilingual split match
        if en_match is None and " / " in zsec["title"]:
            parts = zsec["title"].split(" / ", 1)
            for part in parts:
                norm_part = _normalize_heading(part)
                if norm_part in en_by_heading:
                    en_match_id, en_match = en_by_heading[norm_part]
                    break

        # Strategy 3: positional match
        if en_match is None:
            pos_key = (level, level_counters_zh[level])
            if pos_key in en_by_level_order:
                en_match_id, en_match = en_by_level_order[pos_key]

        # Build merged section
        section = {
            "title": zsec["title"],
            "level": zsec["level"],
            "is_leaf": zsec["is_leaf"],
            "parent": zsec["parent"],
        }

        # Track match for all sections (leaf and non-leaf)
        if en_match and en_match_id not in matched_en:
            matched_en.add(en_match_id)

        if zsec["is_leaf"]:
            section["content_zh"] = zsec.get("body", "")
            section["last_update_time_zh"] = zsec.get("last_update_time")
            if en_match and en_match_id in matched_en:
                section["content_en"] = en_match.get("body", "")
                section["last_update_time_en"] = en_match.get("last_update_time")
            else:
                section["content_en"] = None
                section["last_update_time_en"] = None

        merged[zid] = section

    # Add unmatched EN sections
    for eid in sorted(en_sections.keys(), key=_section_sort_key):
        if eid not in matched_en:
            esec = en_sections[eid]
            # Generate a new ID to avoid collision
            new_id = f"en_{eid}"
            section = {
                "title": esec["title"],
                "level": esec["level"],
                "is_leaf": esec["is_leaf"],
                "parent": esec.get("parent"),
            }
            if esec["is_leaf"]:
                section["content_zh"] = None
                section["last_update_time_zh"] = None
                section["content_en"] = esec.get("body", "")
                section["last_update_time_en"] = esec.get("last_update_time")
            merged[new_id] = section

    return merged


def _section_sort_key(section_id: str) -> list:
    """Sort key for section IDs: '1' < '1.1' < '1.2' < '2'."""
    # Handle en_ prefix for unmatched EN sections
    if section_id.startswith("en_"):
        section_id = section_id[3:]
    parts = section_id.split(".")
    return [int(p) for p in parts]


def _process_single_file(filepath: str) -> tuple[str | None, dict]:
    """Process a single markdown file: parse sections, git blame, assign IDs.

    Returns (preamble_text, sections_dict_with_timestamps).
    """
    path = Path(filepath)
    if not path.exists():
        return None, {}

    text = path.read_text(encoding="utf-8")
    sections = parse_markdown_sections(text)
    id_map = assign_section_ids(sections)

    # Get git blame timestamps
    blame = get_blame_timestamps(filepath)

    # Extract preamble
    preamble = None
    for s in sections:
        if s["heading"] is None:
            preamble = s["body"]
            break

    # Assign timestamps to leaf sections
    for sid, sec in id_map.items():
        if sec["is_leaf"]:
            blame_ts = max_timestamp_for_range(blame, sec["line_start"], sec["line_end"])
            # Extract <!-- last_translated: ... --> from body, strip it, take max
            cleaned_body, translated_ts = _extract_last_translated(sec["body"])
            sec["body"] = cleaned_body
            sec["last_update_time"] = _max_iso_timestamp(blame_ts, translated_ts)

    return preamble, id_map


def build_json_tree(
    zh_file: str | None,
    en_file: str | None,
) -> dict:
    """Main entry point: parse both files, match sections, build JSON tree."""
    zh_preamble, zh_sections = (None, {})
    en_preamble, en_sections = (None, {})

    if zh_file:
        zh_preamble, zh_sections = _process_single_file(zh_file)
    if en_file:
        en_preamble, en_sections = _process_single_file(en_file)

    # Match and merge sections
    if zh_sections and en_sections:
        merged = match_sections(zh_sections, en_sections)
    elif zh_sections:
        # Only ZH exists
        merged = {}
        for sid, sec in zh_sections.items():
            entry = {
                "title": sec["title"],
                "level": sec["level"],
                "is_leaf": sec["is_leaf"],
                "parent": sec["parent"],
            }
            if sec["is_leaf"]:
                entry["content_zh"] = sec.get("body", "")
                entry["last_update_time_zh"] = sec.get("last_update_time")
                entry["content_en"] = None
                entry["last_update_time_en"] = None
            merged[sid] = entry
    else:
        # Only EN exists
        merged = {}
        for sid, sec in en_sections.items():
            entry = {
                "title": sec["title"],
                "level": sec["level"],
                "is_leaf": sec["is_leaf"],
                "parent": sec["parent"],
            }
            if sec["is_leaf"]:
                entry["content_zh"] = None
                entry["last_update_time_zh"] = None
                entry["content_en"] = sec.get("body", "")
                entry["last_update_time_en"] = sec.get("last_update_time")
            merged[sid] = entry

    tree = {
        "meta": {
            "source_file_zh": zh_file,
            "source_file_en": en_file,
            "zh_exists": zh_file is not None and Path(zh_file).exists(),
            "en_exists": en_file is not None and Path(en_file).exists(),
        },
        "preamble_zh": zh_preamble,
        "preamble_en": en_preamble,
        "sections": merged,
    }

    # Compute diff_leaves: leaves where timestamps differ and both contents exist
    diff_leaves = []
    for sid in sorted(merged.keys(), key=_section_sort_key):
        sec = merged[sid]
        if not sec.get("is_leaf"):
            continue
        ts_zh = sec.get("last_update_time_zh")
        ts_en = sec.get("last_update_time_en")
        content_zh = sec.get("content_zh") or ""
        content_en = sec.get("content_en") or ""

        # Determine direction and whether translation is needed
        zh_empty = not content_zh.strip()
        en_empty = not content_en.strip()

        if zh_empty and en_empty:
            continue

        if zh_empty:
            diff_leaves.append({
                "id": sid, "title": sec["title"],
                "ts_zh": ts_zh, "ts_en": ts_en, "direction": "en→zh",
            })
        elif en_empty:
            diff_leaves.append({
                "id": sid, "title": sec["title"],
                "ts_zh": ts_zh, "ts_en": ts_en, "direction": "zh→en",
            })
        elif ts_zh != ts_en:
            direction = "zh→en" if (ts_zh and ts_en and ts_zh > ts_en) or (ts_zh and not ts_en) else "en→zh"
            diff_leaves.append({
                "id": sid, "title": sec["title"],
                "ts_zh": ts_zh, "ts_en": ts_en, "direction": direction,
            })
        # else: timestamps equal and both non-empty → synced, skip

    tree["diff_leaves"] = diff_leaves

    return tree


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Preprocess markdown files into structured JSON tree"
    )
    parser.add_argument("--zh-file", type=str, default=None, help="Chinese markdown file path")
    parser.add_argument("--en-file", type=str, default=None, help="English markdown file path")
    parser.add_argument("--output", type=Path, required=True, help="Output JSON file path")
    args = parser.parse_args()

    if not args.zh_file and not args.en_file:
        print(json.dumps({"error": "At least one of --zh-file or --en-file must be provided"}),
              file=sys.stderr)
        sys.exit(1)

    tree = build_json_tree(args.zh_file, args.en_file)

    # Count sections and leaves
    sections = tree["sections"]
    n_sections = len(sections)
    n_leaves = sum(1 for s in sections.values() if s.get("is_leaf", False))
    diff_leaves = tree.get("diff_leaves", [])

    # Write output
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(tree, ensure_ascii=False, indent=2), encoding="utf-8")

    print(json.dumps({
        "status": "ok",
        "sections": n_sections,
        "leaves": n_leaves,
        "diff_leaves": len(diff_leaves),
        "needs_translate": diff_leaves,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
