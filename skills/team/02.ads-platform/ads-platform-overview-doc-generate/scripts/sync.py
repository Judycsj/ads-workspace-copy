#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

import argparse
import json
import re
import shutil
from pathlib import Path


def _find_repo_root() -> Path:
    p = Path(__file__).resolve().parent
    while p != p.parent:
        if (p / "docs" / "common").is_dir():
            return p
        p = p.parent
    raise RuntimeError("Could not find repo root (docs/common not found)")


SCRIPT_ROOT = Path(__file__).resolve().parent
REPO_ROOT = _find_repo_root()
DEFAULT_RESULTS_DIR = SCRIPT_ROOT / ".tmp"
DEFAULT_ROUTES_FILE = SCRIPT_ROOT / "routes.json"
DEFAULT_RESULTS_FILE = DEFAULT_RESULTS_DIR / "latest" / "results.json"
DEFAULT_DOC_FILES = [
    REPO_ROOT / "docs/common/core-knowledge/04.ads-platform/01.platform-frontend.md",
    REPO_ROOT / "docs/common/core-knowledge/04.ads-platform/01.platform-frontend.zh-CN.md",
]
DEFAULT_DOC_IMAGES_DIR = REPO_ROOT / "docs/common/core-knowledge/img"
MARKER_PREFIX = "ADS_INTRO_4_1"
IMAGE_MARKER_PREFIX = f"{MARKER_PREFIX}:image:"
AUTO_START = "AUTO_SCREENSHOT_START"
AUTO_END = "AUTO_SCREENSHOT_END"
INDENT = "  "


def slugify(value: str) -> str:
    raw = str(value or "").strip().lower()
    replaced = re.sub(r"[^a-z0-9._-]+", "-", raw)
    replaced = re.sub(r"-+", "-", replaced).strip("-")
    return replaced or "unnamed"


def build_platform_image_name(route_name: str, section_id: str, source: str, ext: str) -> str:
    route_slug = slugify(route_name)
    section_slug = slugify(section_id)
    source_slug = slugify(source)
    return f"platform_{route_slug}-{section_slug}-{source_slug}{ext}"


def escape_re(s: str) -> str:
    return re.escape(s)


def load_routes_config(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Route config not found: {path}")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def parse_routes(payload: dict) -> list:
    if not isinstance(payload, dict):
        raise ValueError("Invalid routes config: root must be an object.")
    routes = payload.get("routes", [])
    if not isinstance(routes, list):
        raise ValueError("Invalid routes config: 'routes' must be an array.")
    result = []
    for item in routes:
        if not isinstance(item, dict):
            continue
        name = str(item.get("name") or "").strip()
        if not name:
            continue
        doc = item.get("doc")
        if not isinstance(doc, dict):
            continue
        result.append({"name": name, "doc": doc})
    return result


def heading_level(line: str) -> int:
    m = re.match(r"^(#{1,6})\s+", line)
    return len(m.group(1)) if m else 7


def find_section_by_id(lines: list, section_id: str):
    pattern = re.compile(r"^(#{1,6})\s+" + escape_re(section_id) + r"(?:\b|\s|$)")
    for i, line in enumerate(lines):
        if pattern.match(line):
            level = heading_level(line)
            return {"start": i, "level": level, "heading": line}
    return None


def find_section_range(lines: list, section_node: dict) -> dict:
    start = section_node["start"]
    level = section_node["level"]
    end = next(
        (i for i in range(start + 1, len(lines)) if re.match(r"^#{1,6}\s+", lines[i]) and heading_level(lines[i]) <= level),
        len(lines),
    )
    return {"start": start, "end": end}


def list_by_priority(route_result: dict) -> list:
    detail = route_result.get("screenshots_detail") or []
    planned = route_result.get("planned_screenshots") or []
    seen = set()
    out = []
    for item in list(detail) + list(planned):
        if not isinstance(item, dict) or not isinstance(item.get("name"), str):
            continue
        name = item["name"].strip()
        if name in seen:
            continue
        seen.add(name)
        out.append({**item, "name": name, "path": str(item.get("path") or "").strip()})
    return out


def resolve_screenshot(route_result: dict, source: str, route_name: str, warnings: list):
    normalized = str(source or "").strip()
    if not normalized:
        return None
    lookup = re.sub(r"^step:", "", normalized, flags=re.IGNORECASE)
    for item in list_by_priority(route_result):
        if item["name"] == lookup:
            if item["path"] and Path(item["path"]).exists():
                return item["path"]
            break
    warnings.append({"route": route_name, "source": normalized, "reason": "no matching screenshot item or file missing"})
    return None


def copy_and_resolve_image(src: str, target_name: str, images_dir: Path, dry_run: bool, actions: list) -> str:
    target = images_dir / target_name
    actions.append(f"Copy screenshot to {target}")
    if not dry_run:
        images_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, target)
    return f"./img/{target_name}"


def cleanup_legacy_images(images_dir: Path, synced_targets: list, dry_run: bool, actions: list) -> int:
    if not synced_targets or not images_dir.exists():
        return 0
    files = {f.name for f in images_dir.iterdir() if f.is_file()}
    to_delete = []
    seen_keys = set()
    for t in synced_targets:
        route_slug = slugify(t["routeName"])
        section_slug = slugify(t["sectionId"])
        source_slug = slugify(t["source"])
        ext = t["ext"] if t["ext"].startswith(".") else f".{t['ext']}"
        key = f"{route_slug}|{section_slug}|{source_slug}|{ext}"
        if key in seen_keys:
            continue
        seen_keys.add(key)
        pattern = re.compile(
            r"^platform_" + escape_re(route_slug) + r"-" + escape_re(section_slug) + r"-" + escape_re(source_slug) + r"(?:-\d+)?"
            + escape_re(ext) + r"$",
            re.IGNORECASE,
        )
        for f in files:
            if f != t["newName"] and pattern.match(f):
                to_delete.append(f)
    dedup = list(dict.fromkeys(to_delete))
    for name in dedup:
        full = images_dir / name
        actions.append(f"Delete legacy screenshot: {full}")
        if not dry_run:
            full.unlink(missing_ok=True)
    return len(dedup)


def collect_section_image_plans(docs_plan: list, images_dir: Path, dry_run: bool, summary: dict) -> list:
    warnings = summary["warnings"]
    summary.setdefault("syncedImageTargets", [])
    summary.setdefault("imageNameByKey", {})
    image_plans = []

    for item in docs_plan:
        route_name = item["route"]["name"]
        mapping = item["route"]["doc"]
        images = mapping.get("images") if isinstance(mapping, dict) else []
        if not isinstance(images, list):
            images = []
        route_result = item["result"]
        section_id = item["sectionId"]

        for idx, spec in enumerate(images):
            if not isinstance(spec, dict):
                continue
            source = str(spec.get("source") or "").strip() or "initial"
            caption = str(spec.get("caption") or spec.get("name") or source).strip() or f"Screenshot {idx+1}"
            screenshot_path = resolve_screenshot(route_result, source, route_name, warnings)
            lines = []
            has_screenshot = False

            if not screenshot_path:
                warnings.append({"route": route_name, "source": source, "reason": "screenshot not found, keeping existing doc image"})
            else:
                has_screenshot = True
                ext = Path(screenshot_path).suffix or ".png"
                counter_key = f"{route_name}|{section_id}|{source}"
                safe_name = summary["imageNameByKey"].get(counter_key)
                if not safe_name:
                    safe_name = build_platform_image_name(route_name, section_id, source, ext)
                    summary["imageNameByKey"][counter_key] = safe_name
                rel_path = copy_and_resolve_image(screenshot_path, safe_name, images_dir, dry_run, summary["actions"])
                summary["syncedImageTargets"].append({
                    "routeName": route_name, "sectionId": section_id,
                    "source": source, "ext": ext, "newName": safe_name,
                })
                lines += [caption, "", f"![{caption}]({rel_path})", ""]

            image_plans.append({"source": source, "lines": lines, "routeName": route_name, "sectionId": section_id, "hasScreenshot": has_screenshot})

    return image_plans


def make_image_slot_marker(section_id: str, source: str) -> str:
    source_part = str(source or "").strip()
    if not source_part:
        return f"<!-- {AUTO_START} {IMAGE_MARKER_PREFIX}unknown -->"
    payload = f"{section_id}:{source_part}" if section_id else source_part
    return f"<!-- {AUTO_START} {IMAGE_MARKER_PREFIX}{payload} -->"


def build_image_entry_lines(section_id: str, plan: dict) -> list:
    lines = [make_image_slot_marker(section_id, plan["source"]), ""]
    lines += plan["lines"]
    while lines and lines[-1] == "":
        lines.pop()
    lines.append(f"<!-- {AUTO_END} -->")
    return lines


def build_section_image_block(section_id: str, plans: list) -> list:
    lines = []
    for plan in plans:
        if not plan.get("hasScreenshot", False):
            continue
        lines += build_image_entry_lines(section_id, plan)
    while lines and lines[-1] == "":
        lines.pop()
    return lines


def parse_start_marker(line: str, section_id: str):
    m = re.match(r"^\s*<!--\s*" + escape_re(AUTO_START) + r"\s+(.+?)\s*-->\s*$", str(line))
    if not m:
        return None
    payload = m.group(1).strip()
    if not payload.startswith(IMAGE_MARKER_PREFIX):
        return None
    payload = payload[len(IMAGE_MARKER_PREFIX):].strip()
    if not payload:
        return None
    if section_id:
        prefix = f"{section_id}:"
        if payload.startswith(prefix):
            payload = payload[len(prefix):]
    return payload or None


def is_end_marker(line: str) -> bool:
    return bool(re.match(r"^\s*<!--\s*" + escape_re(AUTO_END) + r"\s*-->\s*$", str(line or "")))


def find_block_end(lines: list, start: int) -> int:
    i = start
    while i < len(lines) and not is_end_marker(lines[i]):
        i += 1
    return i if i < len(lines) else len(lines) - 1


def resolve_marker_source(payload: str, section_id: str):
    if not section_id:
        return payload
    parts = str(payload).split(":", 1)
    if len(parts) == 1:
        return payload
    if parts[0] == section_id:
        return parts[1]
    return None


def inject_image_slots(section_lines: list, section_id: str, plans: list, warnings: list) -> dict:
    source_queue: dict = {}
    for entry in plans:
        source_queue.setdefault(entry["source"], []).append(entry)

    remaining = set(id(p) for p in plans)
    output = []
    has_slot = False

    i = 0
    while i < len(section_lines):
        line = section_lines[i]
        raw_marker = parse_start_marker(line, section_id)
        if raw_marker is None:
            output.append(line)
            i += 1
            continue

        payload = resolve_marker_source(raw_marker, section_id)
        if not payload:
            warnings.append({"section": section_id, "source": raw_marker, "reason": "marker section mismatch"})
            end = find_block_end(section_lines, i + 1)
            output += section_lines[i : end + 1]
            i = end + 1
            continue

        has_slot = True
        queue = source_queue.get(payload, [])
        if not queue:
            warnings.append({"section": section_id, "source": payload, "reason": "no mapped image spec for marker"})
            end = find_block_end(section_lines, i + 1)
            output += section_lines[i : end + 1]
            i = end + 1
            continue

        next_plan = queue.pop(0)
        remaining.discard(id(next_plan))
        if not next_plan.get("hasScreenshot", False):
            warning_suffix = next_plan.get("source") or payload
            warnings.append({"section": section_id, "source": warning_suffix, "reason": "screenshot not found, preserve existing section image"})
            end = find_block_end(section_lines, i + 1)
            output += section_lines[i : end + 1]
            i = end + 1
            continue

        full_payload = f"{section_id}:{payload}" if section_id else payload
        output += [f"<!-- {AUTO_START} {IMAGE_MARKER_PREFIX}{full_payload} -->", ""] + next_plan["lines"] + ["", f"<!-- {AUTO_END} -->"]
        i = find_block_end(section_lines, i + 1) + 1

    if not has_slot:
        return {"hasSlotMarker": False, "replacedLines": None}

    remainder = [p for p in plans if id(p) in remaining]
    if remainder:
        if output and output[-1] != "":
            output.append("")
        for plan in remainder:
            if not plan.get("hasScreenshot", False):
                continue
            output += build_image_entry_lines(section_id, plan)
            if output[-1] != "":
                output.append("")

    while output and output[-1] == "":
        output.pop()

    return {"hasSlotMarker": True, "replacedLines": output}


def replace_section_block(lines: list, section_node: dict, section_id: str, plans: list, summary: dict) -> list:
    rng = find_section_range(lines, section_node)
    sec_start = rng["start"] + 1
    sec_end = rng["end"]
    section_lines = lines[sec_start:sec_end]
    slot_result = inject_image_slots(section_lines, section_id, plans, summary["warnings"])

    if slot_result["hasSlotMarker"]:
        return lines[:sec_start] + (slot_result["replacedLines"] or []) + lines[sec_end:]

    block = build_section_image_block(section_id, plans)
    insertion = block if plans else []
    return lines[:sec_start] + insertion + lines[sec_start:]


def group_by_section(routes_with_docs: list, route_results: list, include_failed: bool) -> dict:
    result_by_name = {r["route"]: r for r in route_results}
    grouped: dict = {}
    for item in routes_with_docs:
        name = item["name"]
        result = result_by_name.get(name)
        if not result:
            continue
        if not include_failed and result.get("status") != "success":
            continue
        section_id = str((item["doc"] or {}).get("section_id") or "").strip()
        if not section_id:
            continue
        grouped.setdefault(section_id, []).append({"route": item, "result": result, "sectionId": section_id})
    return grouped


def update_document(file_path: Path, grouped_sections: dict, images_dir: Path, dry_run: bool, skip_cleanup: bool = False) -> dict:
    content = file_path.read_text(encoding="utf-8")
    lines = content.split("\n")
    summary = {"actions": [], "warnings": [], "syncedImageTargets": [], "updatedSections": 0, "skippedSections": 0, "removedLegacyImages": 0}

    updated = list(lines)
    for section_id, entries in grouped_sections.items():
        node = find_section_by_id(updated, section_id)
        if not node:
            summary["warnings"].append({"section": section_id, "reason": "section heading not found"})
            summary["skippedSections"] += 1
            continue

        plans = collect_section_image_plans(entries, images_dir, dry_run, summary)
        if not plans:
            summary["skippedSections"] += 1
            continue

        block = build_section_image_block(section_id, plans)
        if not block:
            summary["skippedSections"] += 1
            continue

        updated = replace_section_block(updated, node, section_id, plans, summary)
        summary["updatedSections"] += 1
        route_names = ", ".join(e["route"]["name"] for e in entries)
        summary["actions"].append(f"Update section {section_id} from route(s): {route_names}")

    if not skip_cleanup:
        summary["removedLegacyImages"] = cleanup_legacy_images(images_dir, summary["syncedImageTargets"], dry_run, summary["actions"])

    new_content = "\n".join(updated)
    if not new_content.endswith("\n"):
        new_content += "\n"
    return {"summary": summary, "content": new_content}


def run(args) -> None:
    routes_file = Path(args.routes_file)
    results_file = Path(args.results)
    doc_paths = [Path(p) for p in args.docs]
    images_dir = Path(args.images_dir)

    if not routes_file.exists():
        raise FileNotFoundError(f"Route config not found: {routes_file}")
    if not results_file.exists():
        raise FileNotFoundError(f"Results not found: {results_file}")
    for p in doc_paths:
        if not p.exists():
            raise FileNotFoundError(f"Doc file not found: {p}")

    routes_payload = load_routes_config(routes_file)
    routes_with_docs = parse_routes(routes_payload)
    results = json.loads(results_file.read_text(encoding="utf-8")).get("results") or []

    if not results:
        raise ValueError("No route results found in results.json.")

    grouped = group_by_section(routes_with_docs, results, args.include_failed)
    if not grouped:
        raise ValueError("No valid route docs mapping found. Ensure routes with `doc` section are configured.")

    merged = {"updatedSections": 0, "skippedSections": 0, "removedLegacyImages": 0, "actions": [], "warnings": []}

    for i, doc_path in enumerate(doc_paths):
        is_primary = i == 0
        out = update_document(doc_path, grouped, images_dir, args.dry_run, skip_cleanup=not is_primary)
        summary = out["summary"]

        if not args.dry_run:
            doc_path.write_text(out["content"], encoding="utf-8")

        merged["updatedSections"] += summary["updatedSections"]
        merged["skippedSections"] += summary["skippedSections"]
        if is_primary:
            merged["removedLegacyImages"] += summary["removedLegacyImages"]
        merged["actions"].append(f"[{doc_path.name}] {'; '.join(summary['actions'])}".strip())
        merged["warnings"] += [{"docsPath": str(doc_path), **w} for w in summary["warnings"]]

    print(f"Docs synced: {len(doc_paths)}")
    print(f"Route docs sections: {merged['updatedSections']}")
    print(f"Skipped sections: {merged['skippedSections']}")
    print(f"Legacy images removed: {merged['removedLegacyImages']}")
    for w in merged["warnings"]:
        print(f"{INDENT}Warning [{Path(w.get('docsPath', 'unknown')).name}]: route={w.get('route', '')} source={w.get('source', '')} reason={w.get('reason', '')}")
    if args.dry_run:
        for action in merged["actions"]:
            if action:
                print(f"{INDENT}{action}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync generated screenshots into platform frontend docs.")
    parser.add_argument("--run-id", default="latest", metavar="ID", help="Use .tmp/<id>/results.json. Default: latest")
    parser.add_argument("--results", default=str(DEFAULT_RESULTS_FILE), metavar="FILE", help="Override results.json path.")
    parser.add_argument("--routes-file", default=str(DEFAULT_ROUTES_FILE), metavar="FILE", help="Route config path.")
    parser.add_argument("--docs", action="append", default=[str(p) for p in DEFAULT_DOC_FILES], metavar="FILE", help="Target doc path (repeatable).")
    parser.add_argument("--images-dir", default=str(DEFAULT_DOC_IMAGES_DIR), metavar="DIR", help="Target image directory.")
    parser.add_argument("--include-failed", action="store_true", help="Also sync failed routes if screenshots exist.")
    parser.add_argument("--dry-run", action="store_true", help="Print planned actions without writing files.")
    args = parser.parse_args()

    if args.run_id != "latest":
        args.results = str(DEFAULT_RESULTS_DIR / args.run_id / "results.json")

    try:
        run(args)
    except Exception as e:
        print(f"Error: {e}", flush=True)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
