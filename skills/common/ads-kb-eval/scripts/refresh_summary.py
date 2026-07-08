#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
Refresh summary statistics tables in questions-list files.

Parses all question rows from questions-list.md / questions-list.zh-CN.md,
computes per-module stats and question classification counts, then overwrites
the summary tables in-place.

Usage:
    uv run scripts/refresh_summary.py                          # both files
    uv run scripts/refresh_summary.py --file path/to/file.md   # single file
"""

import argparse
import os
import re
import sys

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

QUESTIONS_DIR = "docs/common/ops-log/questions"
ZH_FILE = "questions-list.zh-CN.md"
EN_FILE = "questions-list.md"

QID_RE = re.compile(r"^\|\s*\d{14}\s*\|")
SCORE_RE = re.compile(r"(\d)/5")

# Module definitions: (key, zh_name, en_name, match_rule)
#   match_rule is a tuple: (level, pattern)
#     level = "section" for ## headings, "subsection" for ### headings
#     pattern = regex to match the heading text (after ## or ###)
#   Questions under matching headings (and all sub-headings until next same-level)
#   are aggregated into this module.

MODULE_DEFS = [
    # Chapter 1 — split granularly
    ("ch1-fundamentals", "Chapter1 核心知识 - 1、在线广告基础",
     "Chapter1 Core Knowledge - 1. Fundamentals",
     ("section", r"^1\s")),
    ("ch1-2.1", "Chapter1 核心知识 - 2.1 召回通路和供给策略",
     "Chapter1 Core Knowledge - 2.1 Recall & Supply",
     ("subsection", r"^2\.1\s")),
    ("ch1-2.2", "Chapter1 核心知识 - 2.2 CXR & PGMV 模型和校准",
     "Chapter1 Core Knowledge - 2.2 CXR & PGMV",
     ("subsection", r"^2\.2\s")),
    ("ch1-2.3", "Chapter1 核心知识 - 2.3 出价产品和算法",
     "Chapter1 Core Knowledge - 2.3 Bidding Products",
     ("subsection", r"^2\.3\s")),
    ("ch1-2.4", "Chapter1 核心知识 - 2.4 流量策略和广告计费",
     "Chapter1 Core Knowledge - 2.4 Traffic & Billing",
     ("subsection", r"^2\.4\s")),
    ("ch1-2.5", "Chapter1 核心知识 - 2.5 广告智能优惠券",
     "Chapter1 Core Knowledge - 2.5 Smart Voucher",
     ("subsection", r"^2\.5\s")),
    ("ch1-2.6", "Chapter1 核心知识 - 2.6 广告主策略",
     "Chapter1 Core Knowledge - 2.6 Advertiser Strategy",
     ("subsection", r"^2\.6\s")),
    ("ch1-3.1", "Chapter1 核心知识 - 3.1 广告系统架构总览",
     "Chapter1 Core Knowledge - 3.1 System Architecture",
     ("subsection", r"^3\.1\s")),
    ("ch1-3.2", "Chapter1 核心知识 - 3.2 广告引擎",
     "Chapter1 Core Knowledge - 3.2 Ads Engine",
     ("subsection", r"^3\.2\s")),
    ("ch1-3.3", "Chapter1 核心知识 - 3.3 召回服务",
     "Chapter1 Core Knowledge - 3.3 Recall Service",
     ("subsection", r"^3\.3\s")),
    ("ch1-3.4", "Chapter1 核心知识 - 3.4 出价服务",
     "Chapter1 Core Knowledge - 3.4 Bidding Service",
     ("subsection", r"^3\.4\s")),
    ("ch1-3.5", "Chapter1 核心知识 - 3.5 广告索引",
     "Chapter1 Core Knowledge - 3.5 Ads Index",
     ("subsection", r"^3\.5\s")),
    ("ch1-3.6", "Chapter1 核心知识 - 3.6 广告数据",
     "Chapter1 Core Knowledge - 3.6 Ads Data",
     ("subsection", r"^3\.6\s")),
    ("ch1-platform", "Chapter1 核心知识 - 4、平台层",
     "Chapter1 Core Knowledge - 4. Platform Layer",
     ("section", r"^4\s")),
    ("ch1-data", "Chapter1 核心知识 - 5、数据层",
     "Chapter1 Core Knowledge - 5. Data Layer",
     ("section", r"^5\s")),
    # Chapters 2-6 — aggregate per chapter
    ("ch2", "Chapter2 DPM 核心知识",
     "Chapter2 DPM Core Knowledge",
     ("chapter", r"2")),
    ("ch3", "Chapter3 代码仓库 README",
     "Chapter3 Code Repo README",
     ("chapter", r"3")),
    ("ch4", "Chapter4 数据表参考 DataMap",
     "Chapter4 DataMap Reference",
     ("chapter", r"4")),
    ("ch5", "Chapter5 Workspace 使用指南",
     "Chapter5 Workspace How-Tos",
     ("chapter", r"5")),
    ("ch6", "Chapter6 团队信息与 SOP",
     "Chapter6 Team Info & SOPs",
     ("chapter", r"6")),
]

# Classification type normalization
TYPE_ALIASES = {
    "kb": "kb",
    "指标查询": "metric-query",
    "metric-query": "metric-query",
    "task": "task",
    "无效问题": "invalid",
    "invalid": "invalid",
}

# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------


def parse_file(text: str) -> list[dict]:
    """Parse questions-list file into structured sections with question rows."""
    lines = text.split("\n")
    sections = []  # list of {chapter, section_level, heading, questions}

    current_chapter = 0
    current_section = ""  # ## heading text
    current_subsection = ""  # ### heading text

    for line in lines:
        # Detect # Chapter N
        m = re.match(r"^#\s+Chapter\s*(\d+)", line)
        if m:
            current_chapter = int(m.group(1))
            current_section = ""
            current_subsection = ""
            continue

        # Detect ## heading
        m = re.match(r"^##\s+(?!#)(.+)$", line)
        if m:
            current_section = m.group(1).strip()
            current_subsection = ""
            continue

        # Detect ### heading
        m = re.match(r"^###\s+(?!#)(.+)$", line)
        if m:
            current_subsection = m.group(1).strip()
            continue

        # Detect question row
        if QID_RE.match(line):
            cols = [c.strip() for c in line.split("|")]
            # cols[0] is empty (before first |), cols[1]=QID, ...
            if len(cols) < 8:
                continue
            qtype = cols[3].lower().strip() if len(cols) > 3 else "kb"
            score_str = cols[7] if len(cols) > 7 else ""
            score_m = SCORE_RE.search(score_str)
            score = int(score_m.group(1)) if score_m else 0

            sections.append({
                "chapter": current_chapter,
                "section": current_section,
                "subsection": current_subsection,
                "type": TYPE_ALIASES.get(qtype, qtype),
                "score": score,
            })

    return sections


def assign_modules(questions: list[dict]) -> dict[str, list[int]]:
    """Assign each question to a module, return {module_key: [scores]}."""
    result = {m[0]: [] for m in MODULE_DEFS}

    for q in questions:
        assigned = False
        for key, _zh, _en, (level, pattern) in MODULE_DEFS:
            if level == "chapter":
                if q["chapter"] == int(pattern) and q["chapter"] != 1:
                    result[key].append(q["score"])
                    assigned = True
                    break
            elif level == "section":
                if q["chapter"] == 1 and re.search(pattern, q["section"]):
                    result[key].append(q["score"])
                    assigned = True
                    break
            elif level == "subsection":
                if q["chapter"] == 1 and re.search(pattern, q["subsection"]):
                    result[key].append(q["score"])
                    assigned = True
                    break

        if not assigned and q["chapter"] == 1:
            # Fallback: try section-level aggregation for ch1 sections 2/3
            sec_num = re.match(r"^(\d+)", q["section"] or "")
            if sec_num:
                n = int(sec_num.group(1))
                if n == 4:
                    result["ch1-platform"].append(q["score"])
                elif n == 5:
                    result["ch1-data"].append(q["score"])

    return result


def classify_questions(questions: list[dict]) -> dict[str, int]:
    """Count questions by classification type."""
    counts = {"kb": 0, "metric-query": 0, "task": 0, "invalid": 0}
    for q in questions:
        t = q["type"]
        if t in counts:
            counts[t] += 1
        else:
            counts["kb"] += 1  # default
    return counts


# ---------------------------------------------------------------------------
# Table generation
# ---------------------------------------------------------------------------


def compute_stats(scores: list[int]) -> tuple[int, float, int, int, int, int]:
    """Return (count, avg, s5, s4, s3, lt3)."""
    n = len(scores)
    if n == 0:
        return (0, 0.0, 0, 0, 0, 0)
    avg = round(sum(scores) / n, 1)
    s5 = sum(1 for s in scores if s == 5)
    s4 = sum(1 for s in scores if s == 4)
    s3 = sum(1 for s in scores if s == 3)
    lt3 = sum(1 for s in scores if s < 3)
    return (n, avg, s5, s4, s3, lt3)


def gen_summary_table(module_scores: dict[str, list[int]], is_zh: bool) -> str:
    """Generate the summary statistics table."""
    if is_zh:
        header = (
            "| 模块/Module                            "
            "| 问题数/# Questions | 平均分/Avg | 5 分     | 4 分     | 3 分    | < 3 分  |"
        )
        sep = (
            "| ------------------------------------ "
            "| --------------- | ------- | ------- | ------- | ------ | ------ |"
        )
    else:
        header = (
            "| Module                                              "
            "| # Questions | Avg   | 5 pts | 4 pts | 3 pts | < 3 pts |"
        )
        sep = (
            "| --------------------------------------------------- "
            "| ----------- | ----- | ----- | ----- | ----- | ------- |"
        )

    rows = [header, sep]
    all_scores = []

    for key, zh_name, en_name, _ in MODULE_DEFS:
        scores = module_scores.get(key, [])
        all_scores.extend(scores)
        name = zh_name if is_zh else en_name
        n, avg, s5, s4, s3, lt3 = compute_stats(scores)

        if is_zh:
            row = (
                f"| {name:<38}"
                f" | {n:<15} | {avg:<7.1f} | {s5:<7} | {s4:<7} | {s3:<6} | {lt3:<6} |"
            )
        else:
            row = (
                f"| {name:<51}"
                f" | {n:<11} | {avg:<5.1f} | {s5:<5} | {s4:<5} | {s3:<5} | {lt3:<7} |"
            )
        rows.append(row)

    # Total row
    n, avg, s5, s4, s3, lt3 = compute_stats(all_scores)
    if is_zh:
        rows.append(
            f"| {'**合计/Total**':<38}"
            f" | **{n}**{' ' * max(0, 13 - len(str(n)))} "
            f"| **{avg:.1f}** | **{s5}**{' ' * max(0, 5 - len(str(s5)))} "
            f"| **{s4}**{' ' * max(0, 5 - len(str(s4)))} "
            f"| **{s3}**{' ' * max(0, 4 - len(str(s3)))} "
            f"| **{lt3}**{' ' * max(0, 4 - len(str(lt3)))} |"
        )
    else:
        rows.append(
            f"| {'**Total**':<51}"
            f" | **{n}**{' ' * max(0, 9 - len(str(n)))} "
            f"| **{avg:.1f}** | **{s5}**{' ' * max(0, 3 - len(str(s5)))} "
            f"| **{s4}**{' ' * max(0, 3 - len(str(s4)))} "
            f"| **{s3}**{' ' * max(0, 3 - len(str(s3)))} "
            f"| **{lt3}**{' ' * max(0, 5 - len(str(lt3)))} |"
        )

    return "\n".join(rows)


def gen_classification_table(counts: dict[str, int], is_zh: bool) -> str:
    """Generate the question classification table."""
    total = sum(counts.values()) or 1

    if is_zh:
        header = "| 类别/Type           | 数量/Count | 占比/% |"
        sep = "| ----------------- | -------- | ---- |"
        labels = {
            "kb": "KB 知识型",
            "metric-query": "指标查询 Metric-Query",
            "task": "Task 任务型",
            "invalid": "无效问题 Invalid",
        }
    else:
        header = "| Type | Count | % |"
        sep = "|------|-------|---|"
        labels = {
            "kb": "KB Knowledge",
            "metric-query": "Metric-Query",
            "task": "Task Action",
            "invalid": "Invalid",
        }

    rows = [header, sep]
    for key in ["kb", "metric-query", "task", "invalid"]:
        c = counts.get(key, 0)
        pct = round(c / total * 100) if total else 0
        label = labels[key]
        if is_zh:
            rows.append(f"| {label:<17} | {c:<8} | {pct}%{' ' * max(0, 2 - len(str(pct)))} |")
        else:
            rows.append(f"| {label} | {c} | {pct}% |")

    return "\n".join(rows)


# ---------------------------------------------------------------------------
# File rewriting
# ---------------------------------------------------------------------------


def replace_summary_block(text: str, new_summary: str, new_classification: str,
                          is_zh: bool) -> str:
    """Replace the summary and classification tables in the file text."""
    summary_heading = "## 汇总统计/Summary" if is_zh else "## Summary"
    class_heading = ("### 问题分类/Question Classification" if is_zh
                     else "### Question Classification")

    lines = text.split("\n")
    out = []
    i = 0
    n = len(lines)

    while i < n:
        line = lines[i]

        # Detect summary heading
        if line.strip() == summary_heading:
            out.append(line)
            out.append("")
            # Skip old summary table until classification heading or ---
            i += 1
            while i < n:
                if lines[i].strip() == class_heading:
                    break
                if lines[i].strip() == "---":
                    break
                i += 1
            out.append(new_summary)
            out.append("")
            # Now handle classification
            if i < n and lines[i].strip() == class_heading:
                out.append(lines[i])  # ### heading
                i += 1
                out.append("")
                # Skip old classification table until ---
                while i < n and lines[i].strip() != "---":
                    i += 1
                out.append(new_classification)
                out.append("")
                # Keep the ---
                if i < n:
                    out.append(lines[i])
                    i += 1
            continue

        out.append(line)
        i += 1

    return "\n".join(out)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def process_file(filepath: str) -> None:
    """Process a single questions-list file."""
    with open(filepath, encoding="utf-8") as f:
        text = f.read()

    is_zh = filepath.endswith(".zh-CN.md")
    questions = parse_file(text)

    if not questions:
        print(f"  No questions found in {filepath}, skipping.")
        return

    module_scores = assign_modules(questions)
    counts = classify_questions(questions)

    summary_table = gen_summary_table(module_scores, is_zh)
    class_table = gen_classification_table(counts, is_zh)

    new_text = replace_summary_block(text, summary_table, class_table, is_zh)

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(new_text)

    total = len(questions)
    avg = round(sum(q["score"] for q in questions) / total, 1) if total else 0
    print(f"  {filepath}: {total} questions, avg {avg}/5")


def main():
    parser = argparse.ArgumentParser(
        description="Refresh summary statistics in questions-list files."
    )
    parser.add_argument(
        "--file", type=str, default=None,
        help="Path to a single questions-list file. If omitted, processes both zh-CN and EN."
    )
    args = parser.parse_args()

    # Resolve base directory (script is at skills/common/ads-kb-eval/scripts/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, "..", "..", "..", ".."))

    if args.file:
        filepath = os.path.abspath(args.file)
        if not os.path.isfile(filepath):
            print(f"Error: {filepath} not found", file=sys.stderr)
            sys.exit(1)
        print("Refreshing summary tables...")
        process_file(filepath)
    else:
        q_dir = os.path.join(repo_root, QUESTIONS_DIR)
        files = [
            os.path.join(q_dir, ZH_FILE),
            os.path.join(q_dir, EN_FILE),
        ]
        print("Refreshing summary tables...")
        for fp in files:
            if os.path.isfile(fp):
                process_file(fp)
            else:
                print(f"  {fp}: not found, skipping.")

    print("Done.")


if __name__ == "__main__":
    main()
