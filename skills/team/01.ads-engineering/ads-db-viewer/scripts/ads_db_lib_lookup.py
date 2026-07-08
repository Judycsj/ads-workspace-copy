#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

from __future__ import annotations

import argparse
import json
import os
import re
from pathlib import Path
from typing import Any


SKIP_DIRS = {".git", "vendor", "node_modules"}
SKIP_FILE_PARTS = ("mocked_", ".pb.go")


def find_ads_db_lib(cli_repo: str | None) -> Path:
    if cli_repo:
        repo = Path(cli_repo).expanduser().resolve()
        if repo.exists():
            return repo
        raise FileNotFoundError(repo)

    env_repo = os.environ.get("ADS_DB_LIB_DIR")
    if env_repo:
        repo = Path(env_repo).expanduser().resolve()
        if repo.exists():
            return repo

    starts = [Path.cwd(), Path(__file__).resolve()]
    for start in starts:
        for parent in [start, *start.parents]:
            candidate = parent / "ads-db-lib"
            if (candidate / "go.mod").exists():
                return candidate.resolve()
            sibling = parent.parent / "ads-db-lib"
            if (sibling / "go.mod").exists():
                return sibling.resolve()

    raise RuntimeError("Cannot find ads-db-lib. Pass --repo or set ADS_DB_LIB_DIR.")


def camel_case(value: str) -> str:
    parts = re.split(r"[^a-zA-Z0-9]+", value)
    return "".join(part[:1].upper() + part[1:] for part in parts if part)


def build_terms(query: str) -> list[str]:
    raw = query.strip()
    stripped = re.sub(r"_tab_(%0?\d*d|\d+)$", "", raw)
    stripped = re.sub(r"_tab_\*$", "", stripped)
    terms = [raw]
    if stripped != raw:
        terms.append(stripped)
    terms.extend(
        [
            stripped.replace("_", ""),
            camel_case(stripped),
            camel_case(stripped) + "Table",
        ]
    )
    seen: set[str] = set()
    out: list[str] = []
    for term in terms:
        if term and term not in seen:
            seen.add(term)
            out.append(term)
    return out


def iter_go_files(repo: Path):
    for path in repo.rglob("*.go"):
        rel = path.relative_to(repo)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if any(part in path.name for part in SKIP_FILE_PARTS):
            continue
        yield path


DECL_RE = re.compile(r"^\s*(func|type|const|var)\s+([A-Za-z0-9_]+)?")


def nearest_decl(lines: list[str], index: int) -> str | None:
    for i in range(index, max(-1, index - 80), -1):
        match = DECL_RE.match(lines[i])
        if match:
            return lines[i].strip()
    return None


def search_repo(repo: Path, terms: list[str], max_matches: int) -> list[dict[str, Any]]:
    lowered = [term.lower() for term in terms]
    matches: list[dict[str, Any]] = []
    for path in iter_go_files(repo):
        try:
            lines = path.read_text(errors="replace").splitlines()
        except OSError:
            continue
        for idx, line in enumerate(lines):
            line_lower = line.lower()
            if any(term in line_lower for term in lowered):
                matches.append(
                    {
                        "path": str(path.relative_to(repo)),
                        "line": idx + 1,
                        "text": line.strip(),
                        "nearest_decl": nearest_decl(lines, idx),
                    }
                )
                if len(matches) >= max_matches:
                    return matches
    return matches


def main() -> int:
    parser = argparse.ArgumentParser(description="Search ads-db-lib for Ads DB table/code semantics")
    parser.add_argument("--query", required=True, help="Table name, table format, symbol, or keyword")
    parser.add_argument("--repo", help="Path to ads-db-lib; defaults to workspace discovery")
    parser.add_argument("--max-matches", type=int, default=80)
    args = parser.parse_args()

    repo = find_ads_db_lib(args.repo)
    terms = build_terms(args.query)
    payload = {
        "repo": str(repo),
        "query": args.query,
        "terms": terms,
        "matches": search_repo(repo, terms, args.max_matches),
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
