#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "playwright>=1.44",
#   "python-dotenv>=1.0",
# ]
# ///

import argparse
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

SCRIPT_ROOT = Path(__file__).resolve().parent
DEFAULT_OUTPUT_DIR = SCRIPT_ROOT / ".tmp"
DEFAULT_ENV_FILE = SCRIPT_ROOT / ".env"
DEFAULT_ROUTES_FILE = SCRIPT_ROOT / "routes.json"
WAIT_SELECTOR_TIMEOUT_MS = 15_000
NAVIGATION_TIMEOUT_MS = 60_000
LOGIN_SETTLE_TIMEOUT_MS = 30_000
ROUTE_CUSTOM_STYLE_ID = "pc-route-custom-style"
HIGHLIGHT_BORDER_COLOR = "#ff4d4f"
HIGHLIGHT_LABEL_COLOR = "#ffffff"
HIGHLIGHT_BORDER_WIDTH = 2
HIGHLIGHT_BORDER_STYLE = "solid"
ROUTE_HIDDEN_SELECTOR_LIST = ["devtool-kit", ".eds-toasts"]
ROUTE_HIDDEN_STYLE_ID = "pc-route-hidden-elements"
ALLOWED_STEP_TYPES = {"screenshot", "click", "fill", "navigate", "wait"}

_HIGHLIGHT_ADD_JS = """({markers, style}) => {
    const missingSelectors = [];
    markers.forEach(({ selector, markerId, label }) => {
        const target = document.querySelector(selector);
        if (!target) { missingSelectors.push(selector); return; }
        const computedPosition = window.getComputedStyle(target).position;
        const previous = {
            outline: target.style.outline || '',
            boxShadow: target.style.boxShadow || '',
            position: target.style.position || '',
            overflow: target.style.overflow || '',
        };
        target.dataset.playwrightHighlightId = markerId;
        target.dataset.playwrightHighlightPrevious = JSON.stringify(previous);
        if (!target.style.position && computedPosition === 'static') {
            target.style.position = 'relative';
        }
        target.style.outline = `${style.borderWidth}px ${style.borderStyle} ${style.borderColor}`;
        target.style.overflow = 'visible';
        if (label) {
            const labelNode = document.createElement('span');
            labelNode.textContent = label;
            labelNode.setAttribute('data-playwright-highlight-label', markerId);
            labelNode.style.cssText = [
                'position: absolute', 'left: 0', 'top: 0',
                'transform: translate(-2px, -100%)', 'padding: 2px 6px',
                'background: ' + style.borderColor,
                'color: ' + style.labelColor,
                'font-size: 11px', 'font-weight: 700', 'line-height: 1.1',
                'white-space: nowrap', 'border-radius: 4px', 'pointer-events: none',
                'z-index: 2147483647',
                "font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
            ].join('; ');
            target.appendChild(labelNode);
        }
    });
    if (missingSelectors.length > 0) {
        throw new Error('Highlight target not found: ' + missingSelectors.join(', '));
    }
}"""

_HIGHLIGHT_CLEANUP_JS = """(markerIds) => {
    const ids = Array.isArray(markerIds) ? markerIds : (markerIds ? [markerIds] : []);
    ids.forEach(id => {
        document.querySelectorAll(`[data-playwright-highlight-label="${id}"]`).forEach(n => n.remove());
        const target = document.querySelector(`[data-playwright-highlight-id="${id}"]`);
        if (!target) return;
        const previous = target.dataset.playwrightHighlightPrevious;
        if (previous) {
            try {
                const parsed = JSON.parse(previous);
                target.style.outline = parsed.outline;
                target.style.boxShadow = parsed.boxShadow;
                target.style.position = parsed.position;
                target.style.overflow = parsed.overflow;
            } catch {}
        }
        target.removeAttribute('data-playwright-highlight-id');
        target.removeAttribute('data-playwright-highlight-previous');
    });
}"""


def ensure_chromium() -> None:
    subprocess.run(
        [sys.executable, "-m", "playwright", "install", "chromium"],
        check=True,
    )


def load_env_file(path: Path) -> None:
    if not path or not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        item = re.sub(r"^export\s+", "", line)
        eq = item.find("=")
        if eq < 0:
            continue
        key = item[:eq].strip()
        val_raw = item[eq + 1:].strip()
        if (val_raw.startswith('"') and val_raw.endswith('"')) or \
           (val_raw.startswith("'") and val_raw.endswith("'")):
            val = val_raw[1:-1]
        else:
            val = val_raw.split("#")[0].strip()
        if key:
            os.environ[key] = val


def slugify(value: str) -> str:
    raw = str(value or "").strip().lower()
    replaced = re.sub(r"[^a-z0-9._-]+", "-", raw)
    replaced = re.sub(r"-+", "-", replaced).strip("-")
    return replaced or "unnamed"


def to_positive_int(value, default: int) -> int:
    try:
        return max(0, int(float(str(value))))
    except (ValueError, TypeError):
        return default


def load_routes_config(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Route config not found: {path}")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def normalize_highlight(raw) -> list | None:
    def normalize_item(item):
        if item is None or item is False:
            return None
        if isinstance(item, str):
            label = item.strip()
            return {"selector": "", "label": label, "enabled": True} if label else None
        if isinstance(item, bool):
            return {"selector": "", "label": "", "enabled": True} if item else None
        if not isinstance(item, dict):
            return None
        config = {
            "selector": str(item.get("selector") or "").strip(),
            "label": str(item.get("label") or "").strip(),
            "enabled": item.get("enabled", True) is not False,
        }
        return config if config["selector"] or config["label"] else None

    if raw is None or raw is False:
        return None
    if isinstance(raw, list):
        result = [normalize_item(e) for e in raw]
        result = [e for e in result if e]
        return result if result else None
    item = normalize_item(raw)
    return [item] if item else None


def normalize_step(raw: dict) -> dict:
    if not isinstance(raw, dict):
        raw = {}
    return {
        "name": str(raw.get("name") or ""),
        "type": str(raw.get("type") or "screenshot").lower(),
        "selector": str(raw.get("selector") or ""),
        "value": str(raw.get("value") or ""),
        "url": str(raw.get("url") or ""),
        "screenshot": bool(raw.get("screenshot")),
        "screenshot_name": str(raw.get("screenshot_name") or ""),
        "screenshot_height": to_positive_int(raw.get("screenshot_height"), 0),
        "description": str(raw.get("description") or ""),
        "wait_ms": to_positive_int(raw.get("wait_ms"), 0),
        "wait_for": str(raw.get("wait_for") or ""),
        "highlight": normalize_highlight(raw.get("highlight")),
    }


def parse_route_config(payload: dict) -> dict:
    if not isinstance(payload, dict):
        raise ValueError("Route config must be an object with login and routes.")
    if not isinstance(payload.get("login"), dict):
        raise ValueError("Route config missing root-level login.")
    if not isinstance(payload.get("routes"), list):
        raise ValueError("Route config routes must be an array.")

    routes = []
    for i, item in enumerate(payload["routes"]):
        if not isinstance(item, dict):
            raise ValueError(f"Route #{i+1} must be an object.")
        if "login" in item:
            raise ValueError(f"Route \"{item.get('name', i+1)}\" should not contain login.")
        name = str(item.get("name") or "").strip()
        if not name:
            raise ValueError(f"Route #{i+1} must have a non-empty name.")
        url = str(item.get("url") or "").strip()
        if not url:
            raise ValueError(f"Route {name} missing required 'url'.")
        steps = item.get("steps")
        if steps is not None and not isinstance(steps, list):
            raise ValueError(f"Route {name} 'steps' must be an array.")
        routes.append({
            "name": name,
            "url": url,
            "description": str(item.get("description") or ""),
            "custom_css": str(item.get("custom_css") or ""),
            "doc": item.get("doc"),
            "steps": [normalize_step(s) for s in (steps or [])],
            "notes": str(item.get("notes") or ""),
        })
    return {"login": payload["login"], "routes": routes}


def select_routes(routes: list, names: list) -> list:
    if not names:
        return routes
    lookup = {r["name"]: r for r in routes}
    missing = [n for n in names if n not in lookup]
    if missing:
        available = ", ".join(sorted(lookup))
        raise ValueError(f"Unknown route(s): {', '.join(missing)}. Available: {available}")
    return [lookup[n] for n in names]


def resolve_step_screenshot_filename(step: dict) -> str:
    raw = step.get("screenshot_name") or step.get("name") or step.get("type") or "screenshot"
    normalized = str(raw).strip().lower()
    if not Path(normalized).suffix:
        normalized = f"{normalized}.png"
    return slugify(normalized)


def planned_screenshots(route: dict, route_root: Path) -> list:
    items = []
    for i, step in enumerate(route.get("steps", [])):
        if not step.get("screenshot") and step.get("type") != "screenshot":
            continue
        items.append({
            "name": step.get("name") or f"step_{i+1}",
            "action": step.get("description") or f"Step {i+1}: {step.get('type')}",
            "description": step.get("description") or "",
            "path": str(route_root / resolve_step_screenshot_filename(step)),
        })
    return items


def capture_screenshot(page, screenshot_path: str, selector: str, height: int = 0) -> None:
    if not selector:
        if height > 0:
            clip = page.evaluate("""(h) => {
                const doc = document.documentElement, body = document.body;
                const pageHeight = Math.max(doc.scrollHeight, body.scrollHeight, doc.offsetHeight, body.offsetHeight, window.innerHeight);
                const left = Math.max(0, window.scrollX || 0);
                const top = Math.min(Math.max(0, window.scrollY || 0), Math.max(0, pageHeight - 1));
                return { x: left, y: top, width: Math.max(1, window.innerWidth), height: Math.max(1, Math.min(h, Math.max(1, pageHeight - top))) };
            }""", height)
            page.screenshot(path=screenshot_path, clip=clip, full_page=True)
        else:
            page.screenshot(path=screenshot_path)
        return

    locator = page.locator(selector)
    locator.wait_for(state="visible", timeout=WAIT_SELECTOR_TIMEOUT_MS)

    if height > 0:
        clip = page.evaluate("""({sel, h}) => {
            const el = document.querySelector(sel);
            if (!el) return null;
            const rect = el.getBoundingClientRect();
            const doc = document.documentElement, body = document.body;
            const pageHeight = Math.max(doc.scrollHeight, body.scrollHeight, doc.offsetHeight, body.offsetHeight, window.innerHeight);
            const x = Math.max(0, Math.floor(rect.left + window.scrollX));
            const y = Math.max(0, Math.floor(rect.top + window.scrollY));
            const w = Math.max(1, Math.floor(rect.width));
            const elH = Math.max(1, Math.floor(rect.height));
            const maxH = Math.max(1, pageHeight - y);
            return { x, y, width: w, height: Math.min(Math.max(elH, h), maxH) };
        }""", {"sel": selector, "h": height})
        if not clip:
            raise ValueError(f"Unable to resolve screenshot target: {selector}")
        page.screenshot(path=screenshot_path, clip=clip, full_page=True)
    else:
        locator.screenshot(path=screenshot_path)


def with_temporary_highlights(page, target_selector: str, highlight_configs, capture_fn):
    configs = highlight_configs if isinstance(highlight_configs, list) else []
    active = [
        {"selector": str(c.get("selector") or target_selector or "").strip(), "label": str(c.get("label") or "").strip()}
        for c in configs
        if c and c.get("enabled", True) is not False
        and str(c.get("selector") or target_selector or "").strip()
    ]
    if not active:
        return capture_fn()

    base = f"pc-marker-{int(time.time() * 1000)}"
    marker_ids = [f"{base}-{i}" for i in range(len(active))]
    markers = [{"selector": c["selector"], "markerId": mid, "label": c["label"]} for c, mid in zip(active, marker_ids)]

    try:
        page.evaluate(_HIGHLIGHT_ADD_JS, {
            "markers": markers,
            "style": {
                "borderWidth": HIGHLIGHT_BORDER_WIDTH,
                "borderStyle": HIGHLIGHT_BORDER_STYLE,
                "borderColor": HIGHLIGHT_BORDER_COLOR,
                "labelColor": HIGHLIGHT_LABEL_COLOR,
            },
        })
    except Exception as exc:
        print(f"[WARN] Highlight failed for route step; skipping highlight and continue. details={exc}")
    try:
        return capture_fn()
    finally:
        page.evaluate(_HIGHLIGHT_CLEANUP_JS, marker_ids)


def apply_route_hidden_selectors(page, selectors: list) -> None:
    clean = [str(s).strip() for s in selectors if str(s).strip()]
    if not clean:
        return
    page.evaluate("""({styleId, selectors}) => {
        const el = document.getElementById(styleId) || document.createElement('style');
        el.id = styleId; el.type = 'text/css';
        el.textContent = selectors.map(s => `${s} { display: none !important; }`).join('\\n');
        const c = document.head || document.documentElement || document.body;
        if (!el.isConnected) c.appendChild(el);
    }""", {"styleId": ROUTE_HIDDEN_STYLE_ID, "selectors": clean})


def apply_route_custom_css(page, css_text: str) -> None:
    if not css_text:
        return
    page.evaluate("""(payload) => {
        const cssText = String(payload || "").trim();
        if (!cssText) return;
        const existing = document.getElementById('""" + ROUTE_CUSTOM_STYLE_ID + """');
        const el = existing || document.createElement('style');
        el.id = '""" + ROUTE_CUSTOM_STYLE_ID + """';
        el.type = 'text/css';
        el.textContent = cssText;
        const c = document.head || document.documentElement || document.body;
        if (!el.isConnected) {
            c.appendChild(el);
        }
    }""", css_text)


def wait_for_login_settlement(page, login_cfg: dict) -> None:
    delay_ms = to_positive_int(login_cfg.get("post_login_wait_ms"), 0)
    if delay_ms > 0:
        time.sleep(delay_ms / 1000)

    success_selector = str(login_cfg.get("login_success_selector") or "").strip()
    timeout_ms = to_positive_int(login_cfg.get("post_login_wait_timeout_ms"), LOGIN_SETTLE_TIMEOUT_MS)

    if success_selector:
        page.wait_for_selector(success_selector, state="visible", timeout=timeout_ms)

    raw = login_cfg.get("post_login_url_not_contains")
    if isinstance(raw, list):
        url_not_contains = [str(s).strip() for s in raw if str(s).strip()]
    else:
        url_not_contains = [s.strip() for s in str(raw or "").split(",") if s.strip()]

    if url_not_contains:
        page.wait_for_function(
            "fragments => !fragments.some(f => window.location.href.includes(f))",
            arg=url_not_contains,
            timeout=timeout_ms,
        )


def ensure_login(page, login_cfg: dict) -> dict:
    account = str(login_cfg.get("account") or os.environ.get(str(login_cfg.get("account_env") or ""), "") or "").strip()
    password = str(login_cfg.get("password") or os.environ.get(str(login_cfg.get("password_env") or ""), "") or "").strip()

    if not account and not password:
        return {"success": True, "status": "skipped", "message": "No login configuration."}

    missing = (["`account`"] if not account else []) + (["`password`"] if not password else [])
    if missing:
        raise ValueError(f"Login config missing: {', '.join(missing)}")

    account_selector = str(login_cfg.get("account_selector") or "").strip()
    password_selector = str(login_cfg.get("password_selector") or "").strip()
    submit_selector = str(login_cfg.get("submit_selector") or "").strip()
    if not account_selector or not password_selector or not submit_selector:
        raise ValueError("Login config invalid: account_selector/password_selector/submit_selector required.")

    login_url = str(login_cfg.get("login_url") or "").strip()
    if login_url and login_url not in page.url:
        page.goto(login_url, wait_until="domcontentloaded", timeout=NAVIGATION_TIMEOUT_MS)

    page.wait_for_selector(account_selector, state="visible", timeout=WAIT_SELECTOR_TIMEOUT_MS)
    page.fill(account_selector, account)
    page.fill(password_selector, password)
    page.click(submit_selector)

    result = {"success": True, "status": "attempted", "waited": False}
    try:
        wait_for_login_settlement(page, login_cfg)
        result.update({"waited": True, "status": "success"})
    except Exception as e:
        result.update({"success": False, "status": "failed", "error": str(e)})
    return result


def resolve_highlight_config(step: dict):
    raw = step.get("highlight")
    if not raw:
        return None
    highlights = raw if isinstance(raw, list) else [raw]
    filtered = []
    for h in highlights:
        if not h or h.get("enabled") is False:
            continue
        sel = str(h.get("selector") or step.get("selector") or "").strip()
        label = str(h.get("label") or "").strip()
        if not sel and not label:
            continue
        filtered.append({**h, "selector": sel})
    return filtered if filtered else None


def run_step(page, step: dict, route_root: Path, index: int) -> dict:
    detail = {
        "name": step.get("name") or f"step_{index}",
        "type": step.get("type"),
        "action": (step.get("description") or f"{str(step.get('type', '')).upper()} {step.get('selector') or step.get('url') or ''}").strip(),
        "path": "",
        "status": "success",
    }

    if step.get("wait_ms", 0) > 0:
        time.sleep(step["wait_ms"] / 1000)

    step_type = step.get("type")

    def do_screenshot(sel, h):
        fname = resolve_step_screenshot_filename(step)
        fpath = str(route_root / fname)
        with_temporary_highlights(page, sel, resolve_highlight_config(step), lambda: capture_screenshot(page, fpath, sel, h))
        return fpath

    if step_type == "screenshot":
        detail["path"] = do_screenshot(step.get("selector") or "", step.get("screenshot_height") or 0)
        return detail

    if step_type == "click":
        if not step.get("selector"):
            raise ValueError(f"Step \"{detail['name']}\" requires selector.")
        page.click(step["selector"], timeout=WAIT_SELECTOR_TIMEOUT_MS)
    elif step_type == "fill":
        if not step.get("selector"):
            raise ValueError(f"Step \"{detail['name']}\" requires selector.")
        page.fill(step["selector"], step.get("value") or "")
    elif step_type == "navigate":
        if not step.get("url"):
            raise ValueError(f"Step \"{detail['name']}\" requires url.")
        page.goto(step["url"], wait_until="domcontentloaded", timeout=NAVIGATION_TIMEOUT_MS)
    elif step_type == "wait":
        if step.get("wait_for"):
            page.wait_for_selector(step["wait_for"], state="visible", timeout=WAIT_SELECTOR_TIMEOUT_MS)
    else:
        raise ValueError(f"Unsupported step type: {step_type}")

    if step.get("wait_for") and step_type != "wait":
        page.wait_for_selector(step["wait_for"], state="visible", timeout=WAIT_SELECTOR_TIMEOUT_MS)

    if step.get("screenshot"):
        detail["path"] = do_screenshot(step.get("selector") or "", step.get("screenshot_height") or 0)

    return detail


def execute_route(page, route: dict, run_root: Path, shared_login_result=None) -> dict:
    started_at = datetime.now(timezone.utc).isoformat()
    route_root = run_root / slugify(route["name"])
    route_root.mkdir(parents=True, exist_ok=True)

    result = {
        "route": route["name"],
        "description": route.get("description", ""),
        "url": route["url"],
        "status": "success",
        "screenshots": 0,
        "started_at": started_at,
        "planned_screenshots": [],
        "screenshots_detail": [],
        "notes": route.get("notes", ""),
    }
    if shared_login_result:
        result["login"] = {**shared_login_result, "scope": "shared"}

    entries = []
    try:
        for step in route.get("steps", []):
            if step.get("type") not in ALLOWED_STEP_TYPES:
                raise ValueError(f"Route \"{route['name']}\" unsupported step type: {step.get('type')}")

        page.goto(route["url"], wait_until="domcontentloaded", timeout=NAVIGATION_TIMEOUT_MS)
        apply_route_hidden_selectors(page, ROUTE_HIDDEN_SELECTOR_LIST)
        apply_route_custom_css(page, route.get("custom_css"))

        for i, step in enumerate(route.get("steps", [])):
            try:
                sr = run_step(page, step, route_root, i + 1)
                if sr.get("path"):
                    entries.append({"name": sr["name"], "action": sr["action"], "status": sr["status"], "path": sr["path"], "type": sr["type"]})
            except Exception as e:
                result["status"] = "failed"
                result["error"] = f"Step \"{step.get('name') or step.get('type') or i+1}\" failed: {e}"
                break

        result["navigation"] = {"url": page.url, "title": ""}
        try:
            result["navigation"]["title"] = page.title()
        except Exception:
            pass
    except Exception as e:
        result["status"] = "failed"
        result["error"] = str(e)

    result["completed_at"] = datetime.now(timezone.utc).isoformat()
    result["screenshots_detail"] = entries
    result["screenshots"] = len(entries)
    result["planned_screenshots"] = entries
    return result


def make_plan(route: dict, run_root: Path) -> dict:
    route_root = run_root / slugify(route["name"])
    shots = planned_screenshots(route, route_root)
    return {
        "route": route["name"],
        "description": route.get("description", ""),
        "url": route["url"],
        "status": "planned",
        "screenshots": len(shots),
        "started_at": datetime.now(timezone.utc).isoformat(),
        "planned_screenshots": shots,
        "screenshots_detail": [],
        "login": {"mode": "shared-env", "scope": "shared"},
        "notes": route.get("notes") or "Execute route via Playwright implementation.",
    }


def write_json(file_path: Path, payload: dict) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def run_all(args) -> dict:
    routes_payload = load_routes_config(Path(args.routes_file))
    route_config = parse_route_config(routes_payload)
    routes = select_routes(route_config["routes"], args.route or [])

    run_root = DEFAULT_OUTPUT_DIR / args.run_id
    run_root.mkdir(parents=True, exist_ok=True)

    automation = {
        "run_id": args.run_id,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "mode": "dry-run" if args.dry_run else "execute",
        "output_dir": str(run_root),
        "summary": {"total_routes": len(routes), "status_counts": {}, "planned_screenshots": 0},
        "results": [],
        "routes_path": str(args.routes_file),
        "login": {"scope": "shared"},
    }

    if args.dry_run:
        for route in routes:
            plan = make_plan(route, run_root)
            automation["results"].append(plan)
            automation["summary"]["planned_screenshots"] += plan["screenshots"]
            s = plan["status"]
            automation["summary"]["status_counts"][s] = automation["summary"]["status_counts"].get(s, 0) + 1
        write_json(run_root / "results.json", automation)
        return automation

    from playwright.sync_api import sync_playwright

    launch_opts: dict = {"headless": not (args.headed or args.debug)}
    if args.debug:
        launch_opts.update({"slow_mo": 250, "devtools": True})

    with sync_playwright() as p:
        browser = p.chromium.launch(**launch_opts)
        context = browser.new_context(viewport={"width": 1440, "height": 900})
        try:
            page = context.new_page()
            try:
                shared_login_result = None
                try:
                    shared_login_result = ensure_login(page, route_config["login"])
                except Exception as e:
                    shared_login_result = {"success": False, "status": "failed", "error": str(e)}

                automation["login"]["result"] = shared_login_result

                if shared_login_result and not shared_login_result.get("success"):
                    now = datetime.now(timezone.utc).isoformat()
                    for route in routes:
                        automation["results"].append({
                            "route": route["name"], "description": route.get("description", ""),
                            "url": route["url"], "status": "failed", "screenshots": 0,
                            "started_at": now, "completed_at": now,
                            "planned_screenshots": [], "screenshots_detail": [],
                            "login": {**shared_login_result, "scope": "shared"},
                            "error": shared_login_result.get("error") or "Shared login failed.",
                            "notes": route.get("notes", ""),
                        })
                    automation["summary"]["status_counts"]["failed"] = len(routes)
                else:
                    for route in routes:
                        rr = execute_route(page, route, run_root, shared_login_result)
                        automation["results"].append(rr)
                        s = rr["status"]
                        automation["summary"]["status_counts"][s] = automation["summary"]["status_counts"].get(s, 0) + 1
                        automation["summary"]["planned_screenshots"] += rr["screenshots"]
            finally:
                page.close()
        finally:
            context.close()
            browser.close()

    write_json(run_root / "results.json", automation)
    return automation


def main() -> None:
    parser = argparse.ArgumentParser(description="Playwright executor for Seller Center Shopee Ads route automation.")
    parser.add_argument("--route", action="append", metavar="NAME", help="Route name (repeatable). Default: all routes.")
    parser.add_argument("--run-id", default="latest", metavar="ID", help="Run folder under .tmp/. Default: latest")
    parser.add_argument("--env-file", default=str(DEFAULT_ENV_FILE), metavar="FILE", help="Env file for credentials.")
    parser.add_argument("--routes-file", default=str(DEFAULT_ROUTES_FILE), metavar="FILE", help="Routes config JSON file.")
    parser.add_argument("--dry-run", action="store_true", help="Plan only, do not execute.")
    parser.add_argument("--headed", action="store_true", help="Launch browser in headed mode.")
    parser.add_argument("--debug", action="store_true", help="Headed + devtools + slow_mo.")
    args = parser.parse_args()

    load_env_file(Path(args.env_file))

    if not args.dry_run:
        ensure_chromium()

    result = run_all(args)
    print(f"Mode: {result['mode']}")
    print(f"Routes: {result['summary']['total_routes']}")
    print(f"Planned screenshots: {result['summary']['planned_screenshots']}")
    print(f"Results: {Path(result['output_dir']) / 'results.json'}")


if __name__ == "__main__":
    main()
