#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import hmac
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import time
from typing import Any

from learn_session import (
    DEFAULT_GITLAB_API_BASE,
    DEFAULT_GITLAB_PROJECT_ID,
    DEFAULT_PUBLISHER_DIR,
    build_file_content,
    default_repo_root,
    publish_learning_api,
    publish_learning_git,
)


SHA_TZ = dt.timezone(dt.timedelta(hours=8))
DEFAULT_MAX_BODY_BYTES = 2 * 1024 * 1024
DEFAULT_PORT = 19191


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def parse_bool(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "y", "on"}


def json_bytes(payload: dict[str, Any], status: int = 200) -> tuple[int, bytes]:
    return status, json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")


def verify_signature(secret: str, timestamp: str, signature: str, body: bytes, max_skew_seconds: int) -> None:
    if not secret:
        return
    if not timestamp or not signature:
        raise PermissionError("missing relay signature")
    try:
        ts = int(timestamp)
    except ValueError as exc:
        raise PermissionError("invalid relay timestamp") from exc
    if abs(int(time.time()) - ts) > max_skew_seconds:
        raise PermissionError("expired relay timestamp")
    expected = hmac.new(secret.encode("utf-8"), timestamp.encode("utf-8") + b"." + body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest("sha256=%s" % expected, signature):
        raise PermissionError("invalid relay signature")


def validate_payload(payload: Any) -> dict[str, Any]:
    if not isinstance(payload, dict):
        raise ValueError("payload must be a JSON object")
    analysis = payload.get("analysis")
    if not isinstance(analysis, dict):
        raise ValueError("analysis is required")
    relpath = str(payload.get("relpath") or "").strip()
    section = str(payload.get("section") or "").strip()
    if not relpath:
        raise ValueError("relpath is required")
    if relpath.startswith("/") or ".." in Path(relpath).parts:
        raise ValueError("relpath must be a safe repository-relative path")
    if not section:
        raise ValueError("section is required")
    if not analysis.get("title"):
        raise ValueError("analysis.title is required")
    if not analysis.get("confidence"):
        analysis["confidence"] = "medium"
    return payload


class RelayConfig:
    def __init__(self, args: argparse.Namespace):
        self.host = args.host
        self.port = args.port
        self.secret = args.secret
        self.max_skew_seconds = args.max_skew_seconds
        self.max_body_bytes = args.max_body_bytes
        self.repo_root = Path(args.repo_root).expanduser().resolve()
        self.publisher_dir = Path(args.publisher_dir).expanduser()
        self.publish_mode = args.publish_mode
        self.gitlab_api_base = args.gitlab_api_base
        self.gitlab_project_id = args.gitlab_project_id
        self.gitlab_token = args.gitlab_token
        self.dry_run = args.dry_run


class LearnPublishRelay(BaseHTTPRequestHandler):
    server_version = "SeatalkLearnRelay/1.0"

    @property
    def relay_config(self) -> RelayConfig:
        return self.server.relay_config  # type: ignore[attr-defined]

    def log_message(self, fmt: str, *args: Any) -> None:
        now = dt.datetime.now(SHA_TZ).strftime("%Y-%m-%d %H:%M:%S +08")
        print("%s %s - %s" % (now, self.client_address[0], fmt % args), flush=True)

    def _send_json(self, payload: dict[str, Any], status: int = 200) -> None:
        status, body = json_bytes(payload, status)
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        if self.path.rstrip("/") in {"", "/health"}:
            self._send_json(
                {
                    "status": "ok",
                    "service": "seatalkbot-learn-publish-relay",
                    "publish_mode": self.relay_config.publish_mode,
                    "dry_run": self.relay_config.dry_run,
                }
            )
            return
        self._send_json({"status": "error", "error": "not found"}, status=404)

    def do_POST(self) -> None:  # noqa: N802
        if self.path.rstrip("/") not in {"/seatalkbot/learn/publish", "/publish"}:
            self._send_json({"status": "error", "error": "not found"}, status=404)
            return

        config = self.relay_config
        try:
            length = int(self.headers.get("Content-Length") or "0")
            if length <= 0:
                raise ValueError("empty request body")
            if length > config.max_body_bytes:
                raise ValueError("request body too large")
            body = self.rfile.read(length)
            verify_signature(
                config.secret,
                self.headers.get("X-Seatalk-Learn-Timestamp", ""),
                self.headers.get("X-Seatalk-Learn-Signature", ""),
                body,
                config.max_skew_seconds,
            )
            payload = validate_payload(json.loads(body.decode("utf-8")))

            analysis = payload["analysis"]
            relpath = payload["relpath"]
            section = payload["section"]
            target_branch = str(payload.get("target_branch") or env("ADS_WORKSPACE_LEARN_TARGET_BRANCH", "master"))
            branch_prefix = str(payload.get("branch_prefix") or env("ADS_WORKSPACE_LEARN_BRANCH_PREFIX", "yangfn/chore/seatalkbot-learn"))

            if config.dry_run:
                self._send_json(
                    {
                        "status": "dry_run",
                        "branch": None,
                        "target_path": relpath,
                        "mr_url": None,
                        "commit_id": None,
                    }
                )
                return

            mode = config.publish_mode
            if mode == "auto":
                mode = "api" if config.gitlab_token else "git"
            if mode == "api":
                result = publish_learning_api(
                    api_base=config.gitlab_api_base,
                    project_id=config.gitlab_project_id,
                    token=config.gitlab_token,
                    target_branch=target_branch,
                    branch_prefix=branch_prefix,
                    relpath=relpath,
                    section=section,
                    analysis=analysis,
                )
            else:
                existing = None
                local_file = config.repo_root / relpath
                if local_file.exists():
                    existing = local_file.read_text(encoding="utf-8")
                content = build_file_content(existing, analysis, section)
                result = publish_learning_git(
                    repo_root=config.repo_root,
                    publisher_dir=config.publisher_dir,
                    target_branch=target_branch,
                    branch_prefix=branch_prefix,
                    relpath=relpath,
                    content=content,
                    title=analysis["title"],
                )
            self._send_json(result)
        except PermissionError as exc:
            self._send_json({"status": "error", "error": str(exc)}, status=401)
        except Exception as exc:  # noqa: BLE001
            self._send_json({"status": "error", "error": str(exc)}, status=500)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Devbox relay for Seatalkbot /learn MR publishing.")
    parser.add_argument("--host", default=env("ADS_WORKSPACE_LEARN_RELAY_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(env("ADS_WORKSPACE_LEARN_RELAY_PORT", str(DEFAULT_PORT))))
    parser.add_argument("--secret", default=env("ADS_WORKSPACE_LEARN_RELAY_SECRET", ""))
    parser.add_argument("--max-skew-seconds", type=int, default=int(env("ADS_WORKSPACE_LEARN_RELAY_MAX_SKEW_SECONDS", "300")))
    parser.add_argument("--max-body-bytes", type=int, default=int(env("ADS_WORKSPACE_LEARN_RELAY_MAX_BODY_BYTES", str(DEFAULT_MAX_BODY_BYTES))))
    parser.add_argument("--repo-root", default=env("ADS_WORKSPACE_LEARN_REPO_ROOT", str(default_repo_root())))
    parser.add_argument("--publisher-dir", default=env("ADS_WORKSPACE_LEARN_PUBLISHER_DIR", str(DEFAULT_PUBLISHER_DIR)))
    parser.add_argument("--publish-mode", choices=("api", "git", "auto"), default=env("ADS_WORKSPACE_LEARN_RELAY_PUBLISH_MODE", env("ADS_WORKSPACE_LEARN_PUBLISH_MODE", "auto")))
    parser.add_argument("--gitlab-api-base", default=env("ADS_WORKSPACE_LEARN_GITLAB_API_BASE", env("CI_API_V4_URL", DEFAULT_GITLAB_API_BASE)))
    parser.add_argument("--gitlab-project-id", default=env("ADS_WORKSPACE_LEARN_PROJECT_ID", env("CI_PROJECT_ID", DEFAULT_GITLAB_PROJECT_ID)))
    parser.add_argument("--gitlab-token", default=env("ADS_WORKSPACE_LEARN_GITLAB_TOKEN", env("GITLAB_TOKEN", "")))
    parser.add_argument("--dry-run", action="store_true", default=parse_bool(env("ADS_WORKSPACE_LEARN_RELAY_DRY_RUN", "")))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config = RelayConfig(args)
    server = ThreadingHTTPServer((config.host, config.port), LearnPublishRelay)
    server.relay_config = config  # type: ignore[attr-defined]
    print(
        "Seatalkbot learn relay listening on %s:%s mode=%s dry_run=%s repo_root=%s"
        % (config.host, config.port, config.publish_mode, config.dry_run, config.repo_root),
        flush=True,
    )
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
