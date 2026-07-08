#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "PyYAML>=6.0",
# ]
# ///
"""Render Markdown from an ads-experiment-analyze JSON result."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from analyze_experiment import render_markdown


def main() -> None:
    parser = argparse.ArgumentParser(description="Render Ads experiment analysis JSON as Markdown.")
    parser.add_argument("--input-json", required=True, type=Path)
    parser.add_argument("--output-md", type=Path)
    args = parser.parse_args()

    report = json.loads(args.input_json.read_text(encoding="utf-8"))
    markdown = render_markdown(report)
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(markdown, encoding="utf-8")
    else:
        print(markdown)


if __name__ == "__main__":
    main()
