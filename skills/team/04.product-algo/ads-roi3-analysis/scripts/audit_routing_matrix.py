# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "pyyaml>=6.0",
# ]
# ///
"""Audit the ROI3 routing matrix for broken entrypoints and weak contracts."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

import yaml


SKILL_ALIASES = {
    "ads-text2da": "ads-data-text2da",
}


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise ValueError("routing matrix must be a YAML mapping")
    return data


def skill_paths(repo_root: Path, name: str) -> list[Path]:
    real_name = SKILL_ALIASES.get(name, name)
    roots = [
        repo_root / "skills" / "common",
        repo_root / "skills" / "team",
        repo_root / "skills" / "personal",
        repo_root / "sra-toolkit" / "skills",
    ]
    matches: list[Path] = []
    for root in roots:
        if not root.exists():
            continue
        if root.name == "skills" and (root / real_name / "SKILL.md").exists():
            matches.append(root / real_name / "SKILL.md")
            continue
        for skill_file in root.glob(f"**/{real_name}/SKILL.md"):
            matches.append(skill_file)
    return matches


def is_playbook(entrypoint: str) -> bool:
    return entrypoint.endswith(".md") or entrypoint.startswith("skills/") or entrypoint.startswith("docs/")


def audit_entry(repo_root: Path, entry: dict[str, Any]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    entry_id = entry.get("id", "<missing id>")
    maturity = entry.get("maturity")
    entrypoint = entry.get("entrypoint")

    for field in ["id", "match", "maturity", "entrypoint", "owner", "output_contract", "known_failures"]:
        if field not in entry and maturity != "超域":
            errors.append(f"{entry_id}: missing {field}")

    if maturity in {"skill", "playbook", "手工"} and "required_inputs" not in entry:
        warnings.append(f"{entry_id}: missing required_inputs")

    if maturity == "skill" and isinstance(entrypoint, str):
        if not skill_paths(repo_root, entrypoint):
            errors.append(f"{entry_id}: skill entrypoint not found: {entrypoint}")
    elif maturity == "playbook" and isinstance(entrypoint, str):
        path = repo_root / entrypoint
        if not path.exists():
            errors.append(f"{entry_id}: playbook path not found: {entrypoint}")
    elif maturity == "手工" and isinstance(entrypoint, str):
        if is_playbook(entrypoint):
            path = repo_root / entrypoint
            if not path.exists():
                errors.append(f"{entry_id}: manual playbook path not found: {entrypoint}")
        elif not skill_paths(repo_root, entrypoint):
            warnings.append(f"{entry_id}: manual entrypoint not found as skill: {entrypoint}")

    if "route_priority" not in entry and entry_id not in {"manual-fallback"}:
        warnings.append(f"{entry_id}: route_priority not set")
    if "trigger_keywords" not in entry and maturity not in {"超域", "手工"}:
        warnings.append(f"{entry_id}: trigger_keywords not set")

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--matrix",
        type=Path,
        default=Path("skills/team/04.product-algo/ads-roi3-analysis/references/routing-matrix.yaml"),
    )
    args = parser.parse_args()

    repo_root = Path.cwd()
    try:
        data = load_yaml(args.matrix)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    entries = data.get("entries")
    if not isinstance(entries, list):
        print("ERROR: entries must be a list", file=sys.stderr)
        return 1

    errors: list[str] = []
    warnings: list[str] = []
    seen: set[str] = set()
    for entry in entries:
        if not isinstance(entry, dict):
            errors.append("entry must be a mapping")
            continue
        entry_id = str(entry.get("id", ""))
        if entry_id in seen:
            errors.append(f"duplicate id: {entry_id}")
        seen.add(entry_id)
        entry_errors, entry_warnings = audit_entry(repo_root, entry)
        errors.extend(entry_errors)
        warnings.extend(entry_warnings)

    for warning in warnings:
        print(f"WARN: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"OK: {args.matrix} ({len(entries)} entries)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
