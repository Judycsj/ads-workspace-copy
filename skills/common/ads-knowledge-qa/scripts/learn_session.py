#!/usr/bin/env python3
from __future__ import annotations

import argparse
import asyncio
import base64
import datetime as dt
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from typing import Any
import urllib.error
import urllib.parse
import urllib.request


SHA_TZ = dt.timezone(dt.timedelta(hours=8))
DEFAULT_TARGET_ROOT = "docs/common/ops-log/knowledge-bot-learnings"
DEFAULT_PUBLISHER_DIR = Path("~/.cache/ads-workspace-learn-session/publisher").expanduser()
DEFAULT_GITLAB_API_BASE = "https://git.garena.com/api/v4"
DEFAULT_GITLAB_PROJECT_ID = "shopee/search_recommend/ai-copilot/ads-workspace"
DEFAULT_RELAY_TIMEOUT_SECONDS = 120
MAX_TRANSCRIPT_CHARS = 30000
MAX_MESSAGE_CHARS = 5000


SECRET_PATTERNS = [
    (re.compile(r"(?i)\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+"), r"\1 [REDACTED]"),
    (re.compile(r"(?i)\b(token|secret|password|api[_-]?key|credential)\s*[:=]\s*[^\s,;]+"), r"\1=[REDACTED]"),
    (re.compile(r"\bya29\.[A-Za-z0-9._-]+"), "[REDACTED]"),
    (re.compile(r"\bGOCSPX-[A-Za-z0-9_-]+"), "[REDACTED]"),
    (re.compile(r"\bmcp-sk-[A-Za-z0-9]+"), "[REDACTED]"),
    (re.compile(r"\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b"), "[REDACTED]"),
    (re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b"), "[REDACTED_IP]"),
]


def default_repo_root() -> Path:
    script_path = Path(__file__).resolve()
    for parent in script_path.parents:
        if (parent / ".git").exists() and (parent / "skills").is_dir():
            return parent
    return Path.cwd()


def run(cmd: list[str], *, cwd: Path | None = None, input_text: str | None = None) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        input=input_text,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or "exit=%s" % result.returncode
        raise RuntimeError("Command failed: %s\n%s" % (" ".join(cmd), detail))
    return result


def redact(text: str) -> str:
    out = text
    for pattern, replacement in SECRET_PATTERNS:
        out = pattern.sub(replacement, out)
    return out


def load_json_file(path: str | Path) -> Any:
    return json.loads(Path(path).expanduser().read_text(encoding="utf-8"))


def safe_slug(value: str, fallback: str = "misc") -> str:
    value = value.strip().lower()
    value = value.encode("ascii", errors="ignore").decode("ascii")
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-+", "-", value).strip("-")
    if not value:
        value = fallback
    return value[:72].strip("-") or fallback


def learn_branch_name(branch_prefix: str, stamp: str, title: str, topic_slug: str | None = None) -> str:
    prefix = branch_prefix.rstrip("/")
    slug = safe_slug(topic_slug or title, fallback="learning")
    separator = "-" if prefix.count("/") >= 2 else "/"
    return "%s%s%s-%s" % (prefix, separator, stamp, slug)


def message_content(message: dict[str, Any]) -> str:
    content = message.get("content")
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, bytes):
        return content.decode("utf-8", errors="replace")
    return str(content)


def format_ts(raw_ts: Any) -> str:
    if raw_ts is None:
        return ""
    try:
        ts = int(raw_ts)
    except (TypeError, ValueError):
        return ""
    return dt.datetime.fromtimestamp(ts, dt.timezone.utc).astimezone(SHA_TZ).strftime("%Y-%m-%d %H:%M:%S +08")


def build_transcript(session: dict[str, Any]) -> str:
    lines: list[str] = []
    for idx, message in enumerate(session.get("messages") or [], 1):
        role = str(message.get("role") or "unknown")
        msg_type = str(message.get("type") or "unknown")
        if role == "system":
            continue
        if msg_type not in {"text", "action"}:
            lines.append("[%s] %s/%s: <non-text content omitted>" % (idx, role, msg_type))
            continue
        content = redact(message_content(message)).strip()
        if not content:
            continue
        if len(content) > MAX_MESSAGE_CHARS:
            content = content[:MAX_MESSAGE_CHARS] + "\n...[truncated]"
        ts = format_ts(message.get("created_at"))
        prefix = "[%s] %s" % (idx, role)
        if msg_type == "action":
            prefix += "/feedback"
        if ts:
            prefix += " @ %s" % ts
        lines.append("%s:\n%s" % (prefix, content))

    transcript = "\n\n".join(lines).strip()
    if len(transcript) > MAX_TRANSCRIPT_CHARS:
        transcript = transcript[-MAX_TRANSCRIPT_CHARS:]
        transcript = "[transcript truncated to latest context]\n" + transcript
    return transcript


def extract_tagged_block(text: str, name: str) -> str:
    pattern = re.compile(
        r"<<<?%s>>>?\s*\n(.*?)\n<<<?END_%s>>>?" % (re.escape(name), re.escape(name)),
        re.DOTALL,
    )
    match = pattern.search(text)
    if not match:
        return ""
    return match.group(1).strip()


def extract_tagged_value(text: str, name: str) -> str:
    pattern = re.compile(r"^%s:\s*(.+)$" % re.escape(name), re.MULTILINE)
    match = pattern.search(text)
    if not match:
        return ""
    return match.group(1).strip()


def parse_tagged_analysis(text: str) -> dict[str, Any]:
    should_write_raw = extract_tagged_value(text, "SHOULD_WRITE").lower()
    if should_write_raw in {"true", "yes", "y", "1"}:
        should_write = True
    elif should_write_raw in {"false", "no", "n", "0"}:
        should_write = False
    else:
        raise RuntimeError("Claude returned invalid SHOULD_WRITE value: %s" % should_write_raw)

    return {
        "should_write": should_write,
        "title": extract_tagged_value(text, "TITLE"),
        "topic_slug": extract_tagged_value(text, "TOPIC_SLUG"),
        "summary_for_user": extract_tagged_block(text, "SUMMARY"),
        "knowledge_markdown": extract_tagged_block(text, "KNOWLEDGE_MARKDOWN"),
        "confidence": extract_tagged_value(text, "CONFIDENCE"),
    }


async def call_claude_analysis(session: dict[str, Any], transcript: str) -> dict[str, Any]:
    try:
        from claude_agent_sdk import AssistantMessage, ClaudeAgentOptions, query
    except Exception as exc:  # noqa: BLE001
        raise RuntimeError("claude-agent-sdk is required to analyze /learn sessions: %s" % exc) from exc

    instruction = str(session.get("command_text") or "").strip()
    prompt = """
你是 Shopee Paid Ads 知识沉淀助手。请分析下面 SeaTalk session，提取可复用、可验证、适合写入 ads-workspace 的知识。

只沉淀长期有效的广告系统知识、排查经验、口径澄清、产品/数据/代码事实。忽略寒暄、纯任务进度、无证据猜测、一次性个人请求。
如果 session 包含用户纠正 bot 的内容，要学习“纠正后的事实”，并在 knowledge_markdown 中明确错误口径和正确口径。
如果没有足够可靠的知识，返回 SHOULD_WRITE: false。
不要输出密钥、token、IP、主机名、Redis key、trace id 等敏感或内部标识；必要时写成 [REDACTED]。
用中文输出。不要返回 JSON，不要 Markdown code fence，严格按下面模板输出。

输出模板:
SHOULD_WRITE: true|false
TITLE: 短标题
TOPIC_SLUG: ascii-lower-kebab-case-topic
CONFIDENCE: high|medium|low
<<<SUMMARY>>>
给 SeaTalk 用户看的 2-4 句概要
<<<END_SUMMARY>>>
<<<KNOWLEDGE_MARKDOWN>>>
可直接写入文档的 Markdown 片段，包含结论、适用场景、证据/来源、注意事项
<<<END_KNOWLEDGE_MARKDOWN>>>

要求:
- 即使 SHOULD_WRITE=false，也要填 TITLE、TOPIC_SLUG、CONFIDENCE 和 SUMMARY。
- 当 SHOULD_WRITE=false 时，KNOWLEDGE_MARKDOWN 留空块即可。
- SUMMARY 和 KNOWLEDGE_MARKDOWN 内可以换行、列点、写 Markdown。
- 除上述模板外不要输出任何解释性文字。

用户 /learn 附加要求:
%s

Session transcript:
%s
""".strip() % (instruction or "(none)", transcript)

    options = ClaudeAgentOptions(
        system_prompt=(
            "You extract durable Paid Ads knowledge. Return only the exact tagged text template "
            "requested by the user prompt. Never return JSON, Markdown fences, or extra commentary."
        ),
        allowed_tools=[],
    )
    response = ""
    async for message in query(prompt=prompt, options=options):
        if isinstance(message, AssistantMessage):
            for block in message.content:
                if hasattr(block, "text"):
                    response += block.text
    try:
        return parse_tagged_analysis(response)
    except Exception as exc:
        snippet = redact(response).strip().replace("\n", "\\n")[:1000]
        raise RuntimeError(
            "Claude did not return the required tagged learn analysis format: %s" % snippet
        ) from exc


def normalize_analysis(raw: dict[str, Any]) -> dict[str, Any]:
    should_write = bool(raw.get("should_write"))
    title = str(raw.get("title") or "SeaTalk session learning").strip()
    topic_slug = safe_slug(str(raw.get("topic_slug") or title))
    summary_for_user = redact(str(raw.get("summary_for_user") or "").strip())
    knowledge_markdown = redact(str(raw.get("knowledge_markdown") or "").strip())
    confidence = str(raw.get("confidence") or "medium").strip().lower()
    if confidence not in {"high", "medium", "low"}:
        confidence = "medium"

    if should_write and (not summary_for_user or not knowledge_markdown):
        raise RuntimeError("Analysis requested write but summary_for_user or knowledge_markdown is empty")

    return {
        "should_write": should_write,
        "title": title,
        "topic_slug": topic_slug,
        "summary_for_user": summary_for_user,
        "knowledge_markdown": knowledge_markdown,
        "confidence": confidence,
    }


def render_learning_section(analysis: dict[str, Any], session: dict[str, Any]) -> str:
    now = dt.datetime.now(SHA_TZ)
    lines = [
        "## %s - %s" % (now.strftime("%Y-%m-%d"), analysis["title"]),
        "",
        "- Source: SeaTalk `/learn` session",
        "- Generated at: %s" % now.strftime("%Y-%m-%d %H:%M:%S +08"),
        "- Confidence: `%s`" % analysis["confidence"],
        "",
        analysis["knowledge_markdown"].strip(),
        "",
    ]
    return "\n".join(lines)


def target_relpath(analysis: dict[str, Any], target_root: str) -> str:
    return "%s/%s.md" % (target_root.strip("/"), analysis["topic_slug"])


def build_file_content(existing: str | None, analysis: dict[str, Any], section: str) -> str:
    if existing and existing.strip():
        return existing.rstrip() + "\n\n" + section.rstrip() + "\n"
    title = analysis["title"]
    return "# %s\n\n%s\n" % (title, section.rstrip())


def remote_web_base(remote_url: str) -> str:
    match = re.match(r"gitlab@([^:]+):(.+)\.git$", remote_url)
    if match:
        return "https://%s/%s" % (match.group(1), match.group(2))
    if remote_url.startswith("http") and remote_url.endswith(".git"):
        return remote_url[:-4]
    return remote_url


def quote_path(value: str) -> str:
    return urllib.parse.quote(value, safe="")


def api_url(api_base: str, project_id: str, suffix: str, query: dict[str, str] | None = None) -> str:
    url = "%s/projects/%s/%s" % (api_base.rstrip("/"), quote_path(project_id), suffix.lstrip("/"))
    if query:
        url += "?" + urllib.parse.urlencode(query)
    return url


def json_request(
    method: str,
    url: str,
    *,
    token: str | None = None,
    payload: dict[str, Any] | None = None,
    ok_statuses: tuple[int, ...] = (200,),
) -> tuple[int, Any]:
    data = None
    headers = {"Accept": "application/json", "User-Agent": "ads-workspace-seatalkbot-learn/1.0"}
    if token:
        headers["PRIVATE-TOKEN"] = token
    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            body = response.read().decode("utf-8")
            status = response.status
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        if exc.code not in ok_statuses:
            raise RuntimeError("%s %s failed with HTTP %s: %s" % (method, url, exc.code, body)) from exc
        status = exc.code

    if status not in ok_statuses:
        raise RuntimeError("%s %s returned HTTP %s: %s" % (method, url, status, body))
    if not body:
        return status, None
    return status, json.loads(body)


def gitlab_file_content(api_base: str, project_id: str, token: str, file_path: str, ref: str) -> str | None:
    url = api_url(
        api_base,
        project_id,
        "repository/files/%s" % quote_path(file_path),
        {"ref": ref},
    )
    try:
        _, response = json_request("GET", url, token=token)
    except RuntimeError as exc:
        if "HTTP 404" in str(exc):
            return None
        raise

    content = response.get("content") if isinstance(response, dict) else None
    if content is None:
        raise RuntimeError("GitLab file response did not include content for %s" % file_path)
    if response.get("encoding") == "base64":
        return base64.b64decode(content).decode("utf-8")
    return str(content)


def create_commit_api(
    api_base: str,
    project_id: str,
    token: str,
    *,
    branch: str,
    target_branch: str,
    file_path: str,
    content: str,
    commit_message: str,
    action: str,
) -> str:
    payload: dict[str, Any] = {
        "branch": branch,
        "start_branch": target_branch,
        "commit_message": commit_message,
        "actions": [
            {
                "action": action,
                "file_path": file_path,
                "content": content,
            }
        ],
    }
    url = api_url(api_base, project_id, "repository/commits")
    _, response = json_request("POST", url, token=token, payload=payload, ok_statuses=(200, 201))
    commit_id = response.get("id") if isinstance(response, dict) else None
    if not commit_id:
        raise RuntimeError("GitLab commit response did not include id: %s" % response)
    return commit_id


def find_open_mr_api(api_base: str, project_id: str, token: str, branch: str) -> str | None:
    url = api_url(
        api_base,
        project_id,
        "merge_requests",
        {"state": "opened", "source_branch": branch, "per_page": "1"},
    )
    _, response = json_request("GET", url, token=token)
    if isinstance(response, list) and response:
        return response[0].get("web_url")
    return None


def create_mr_api(
    api_base: str,
    project_id: str,
    token: str,
    *,
    branch: str,
    target_branch: str,
    title: str,
    description: str,
) -> str:
    existing = find_open_mr_api(api_base, project_id, token, branch)
    if existing:
        return existing

    payload: dict[str, Any] = {
        "source_branch": branch,
        "target_branch": target_branch,
        "title": title,
        "description": description,
        "remove_source_branch": True,
    }
    url = api_url(api_base, project_id, "merge_requests")
    _, response = json_request("POST", url, token=token, payload=payload, ok_statuses=(200, 201))
    mr_url = response.get("web_url") if isinstance(response, dict) else None
    if not mr_url:
        raise RuntimeError("GitLab MR response did not include web_url: %s" % response)
    return mr_url


def publish_learning_api(
    api_base: str,
    project_id: str,
    token: str,
    target_branch: str,
    branch_prefix: str,
    relpath: str,
    section: str,
    analysis: dict[str, Any],
) -> dict[str, Any]:
    if not token:
        raise RuntimeError("GitLab token is required for API publishing. Set ADS_WORKSPACE_LEARN_GITLAB_TOKEN or GITLAB_TOKEN.")

    existing = gitlab_file_content(api_base, project_id, token, relpath, target_branch)
    content = build_file_content(existing, analysis, section)
    action = "update" if existing is not None else "create"
    stamp = dt.datetime.now(SHA_TZ).strftime("%Y%m%d%H%M%S")
    title = analysis["title"]
    branch = learn_branch_name(branch_prefix, stamp, title, analysis.get("topic_slug"))
    mr_title = "docs: learn ads knowledge - %s" % title
    commit_message = (
        "docs: learn ads knowledge from seatalk session\n\n"
        "- Target path: `%s`\n"
        "- Confidence: `%s`\n"
    ) % (relpath, analysis["confidence"])
    description = (
        "Automated knowledge update generated from a SeaTalk `/learn` session.\n\n"
        "- Target path: `%s`\n"
        "- Confidence: `%s`\n"
    ) % (relpath, analysis["confidence"])

    commit_id = create_commit_api(
        api_base,
        project_id,
        token,
        branch=branch,
        target_branch=target_branch,
        file_path=relpath,
        content=content,
        commit_message=commit_message,
        action=action,
    )
    mr_url = create_mr_api(
        api_base,
        project_id,
        token,
        branch=branch,
        target_branch=target_branch,
        title=mr_title,
        description=description,
    )
    return {
        "status": "published",
        "branch": branch,
        "target_path": relpath,
        "mr_url": mr_url,
        "commit_id": commit_id,
    }


def relay_signature(secret: str, timestamp: str, body: bytes) -> str:
    signed = timestamp.encode("utf-8") + b"." + body
    digest = hmac.new(secret.encode("utf-8"), signed, hashlib.sha256).hexdigest()
    return "sha256=%s" % digest


def publish_learning_relay(
    relay_url: str,
    relay_secret: str,
    target_branch: str,
    branch_prefix: str,
    relpath: str,
    section: str,
    analysis: dict[str, Any],
    timeout_seconds: int,
) -> dict[str, Any]:
    if not relay_url:
        raise RuntimeError("Relay URL is required for relay publishing. Set ADS_WORKSPACE_LEARN_RELAY_URL.")

    payload = {
        "target_branch": target_branch,
        "branch_prefix": branch_prefix,
        "relpath": relpath,
        "section": section,
        "analysis": analysis,
    }
    body = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "ads-workspace-seatalkbot-learn/1.0",
    }
    if relay_secret:
        timestamp = str(int(time.time()))
        headers["X-Seatalk-Learn-Timestamp"] = timestamp
        headers["X-Seatalk-Learn-Signature"] = relay_signature(relay_secret, timestamp, body)

    request = urllib.request.Request(relay_url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
            response_body = response.read().decode("utf-8")
            status = response.status
    except urllib.error.HTTPError as exc:
        response_body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError("Relay publish failed with HTTP %s: %s" % (exc.code, response_body)) from exc
    if status < 200 or status >= 300:
        raise RuntimeError("Relay publish returned HTTP %s: %s" % (status, response_body))
    relay_response = json.loads(response_body) if response_body else {}
    if relay_response.get("status") == "error":
        raise RuntimeError("Relay publish failed: %s" % relay_response.get("error"))
    return relay_response


def ensure_publisher_repo(repo_root: Path, publisher_dir: Path, target_branch: str) -> tuple[Path, str]:
    remote_url = run(["git", "-C", str(repo_root), "config", "--get", "remote.origin.url"]).stdout.strip()
    if not remote_url:
        raise RuntimeError("Cannot resolve remote.origin.url from %s" % repo_root)
    publisher_dir.parent.mkdir(parents=True, exist_ok=True)
    if not (publisher_dir / ".git").is_dir():
        if publisher_dir.exists():
            shutil.rmtree(publisher_dir)
        run(["git", "clone", remote_url, str(publisher_dir)])
    run(["git", "fetch", "origin", target_branch], cwd=publisher_dir)
    return publisher_dir, remote_url


def publish_learning_git(
    repo_root: Path,
    publisher_dir: Path,
    target_branch: str,
    branch_prefix: str,
    relpath: str,
    content: str,
    title: str,
    topic_slug: str | None = None,
) -> dict[str, Any]:
    publisher, remote_url = ensure_publisher_repo(repo_root, publisher_dir, target_branch)
    stamp = dt.datetime.now(SHA_TZ).strftime("%Y%m%d%H%M%S")
    branch = learn_branch_name(branch_prefix, stamp, title, topic_slug)
    run(["git", "checkout", "-B", branch, "origin/%s" % target_branch], cwd=publisher)
    run(["git", "config", "user.name", os.environ.get("GIT_AUTHOR_NAME", "Seatalkbot Learning Bot")], cwd=publisher)
    run(["git", "config", "user.email", os.environ.get("GIT_AUTHOR_EMAIL", "seatalkbot-learning@shopee.com")], cwd=publisher)

    output = publisher / relpath
    output.parent.mkdir(parents=True, exist_ok=True)
    existing = output.read_text(encoding="utf-8") if output.exists() else None
    output.write_text(content if existing is None else content, encoding="utf-8")

    run(["git", "add", relpath], cwd=publisher)
    diff_check = subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=str(publisher), check=False)
    if diff_check.returncode == 0:
        return {
            "status": "no_changes",
            "branch": branch,
            "target_path": relpath,
            "mr_url": None,
            "commit_id": None,
        }

    commit_message = "docs: learn ads knowledge from seatalk session"
    run(["git", "commit", "-m", commit_message], cwd=publisher)
    commit_id = run(["git", "rev-parse", "HEAD"], cwd=publisher).stdout.strip()
    mr_title = "docs: learn ads knowledge - %s" % title
    push = run(
        [
            "git",
            "push",
            "origin",
            "HEAD:%s" % branch,
            "-o",
            "merge_request.create",
            "-o",
            "merge_request.target=%s" % target_branch,
            "-o",
            "merge_request.title=%s" % mr_title,
        ],
        cwd=publisher,
    )
    match = re.search(r"https://\S+/-/merge_requests/\d+", push.stdout + "\n" + push.stderr)
    mr_url = match.group(0) if match else "%s/-/merge_requests/new?merge_request%%5Bsource_branch%%5D=%s" % (
        remote_web_base(remote_url),
        urllib.parse.quote(branch, safe=""),
    )
    return {
        "status": "published",
        "branch": branch,
        "target_path": relpath,
        "mr_url": mr_url,
        "commit_id": commit_id,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Learn durable Ads knowledge from a Seatalkbot session.")
    parser.add_argument("--session-json", required=True, help="Path to session payload JSON.")
    parser.add_argument("--repo-root", default=str(default_repo_root()), help="ads-workspace repo root.")
    parser.add_argument("--publisher-dir", default=str(DEFAULT_PUBLISHER_DIR), help="Cache clone used for publishing.")
    parser.add_argument("--target-branch", default=os.environ.get("ADS_WORKSPACE_LEARN_TARGET_BRANCH", "master"))
    parser.add_argument("--branch-prefix", default=os.environ.get("ADS_WORKSPACE_LEARN_BRANCH_PREFIX", "yangfn/chore/seatalkbot-learn"))
    parser.add_argument("--target-root", default=os.environ.get("ADS_WORKSPACE_LEARN_TARGET_ROOT", DEFAULT_TARGET_ROOT))
    parser.add_argument("--publish-mode", choices=("api", "git", "relay", "auto"), default=os.environ.get("ADS_WORKSPACE_LEARN_PUBLISH_MODE", "api"))
    parser.add_argument("--relay-url", default=os.environ.get("ADS_WORKSPACE_LEARN_RELAY_URL", ""))
    parser.add_argument("--relay-secret", default=os.environ.get("ADS_WORKSPACE_LEARN_RELAY_SECRET", ""))
    parser.add_argument("--relay-timeout-seconds", type=int, default=int(os.environ.get("ADS_WORKSPACE_LEARN_RELAY_TIMEOUT_SECONDS", DEFAULT_RELAY_TIMEOUT_SECONDS)))
    parser.add_argument(
        "--gitlab-api-base",
        default=os.environ.get("ADS_WORKSPACE_LEARN_GITLAB_API_BASE") or os.environ.get("CI_API_V4_URL") or DEFAULT_GITLAB_API_BASE,
    )
    parser.add_argument(
        "--gitlab-project-id",
        default=os.environ.get("ADS_WORKSPACE_LEARN_PROJECT_ID") or os.environ.get("CI_PROJECT_ID") or DEFAULT_GITLAB_PROJECT_ID,
    )
    parser.add_argument("--gitlab-token", default=os.environ.get("ADS_WORKSPACE_LEARN_GITLAB_TOKEN") or os.environ.get("GITLAB_TOKEN") or "")
    parser.add_argument("--requester-email", default="")
    parser.add_argument("--analysis-json", help="Bypass Claude analysis with a JSON file. Useful for tests.")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    session = load_json_file(args.session_json)
    if args.requester_email and not session.get("requester_email"):
        session["requester_email"] = args.requester_email

    transcript = build_transcript(session)
    if not transcript:
        print(
            json.dumps(
                {
                    "status": "skipped",
                    "reason": "empty_session",
                    "summary_for_user": "这个 session 里还没有可学习的文字问答内容。",
                },
                ensure_ascii=False,
            )
        )
        return 0

    if args.analysis_json:
        raw_analysis = load_json_file(args.analysis_json)
    else:
        raw_analysis = asyncio.run(call_claude_analysis(session, transcript))
    analysis = normalize_analysis(raw_analysis)

    if not analysis["should_write"]:
        print(
            json.dumps(
                {
                    "status": "skipped",
                    "reason": "no_durable_knowledge",
                    "summary_for_user": analysis["summary_for_user"] or "这段 session 没有足够可靠、适合沉淀到 ads-workspace 的长期知识。",
                    "analysis": analysis,
                },
                ensure_ascii=False,
            )
        )
        return 0

    relpath = target_relpath(analysis, args.target_root)
    section = render_learning_section(analysis, session)
    repo_root = Path(args.repo_root).expanduser().resolve()

    existing = None
    if (repo_root / relpath).exists():
        existing = (repo_root / relpath).read_text(encoding="utf-8")
    content = build_file_content(existing, analysis, section)

    if args.dry_run:
        result = {
            "status": "dry_run",
            "summary_for_user": analysis["summary_for_user"],
            "target_path": relpath,
            "branch": None,
            "mr_url": None,
            "analysis": analysis,
            "rendered_markdown": content,
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    use_api = args.publish_mode == "api" or (args.publish_mode == "auto" and bool(args.gitlab_token))
    use_relay = args.publish_mode == "relay" or (args.publish_mode == "auto" and not args.gitlab_token and bool(args.relay_url))
    if use_relay:
        publish = publish_learning_relay(
            relay_url=args.relay_url,
            relay_secret=args.relay_secret,
            target_branch=args.target_branch,
            branch_prefix=args.branch_prefix,
            relpath=relpath,
            section=section,
            analysis=analysis,
            timeout_seconds=args.relay_timeout_seconds,
        )
    elif use_api:
        publish = publish_learning_api(
            api_base=args.gitlab_api_base,
            project_id=args.gitlab_project_id,
            token=args.gitlab_token,
            target_branch=args.target_branch,
            branch_prefix=args.branch_prefix,
            relpath=relpath,
            section=section,
            analysis=analysis,
        )
    else:
        publish = publish_learning_git(
            repo_root=repo_root,
            publisher_dir=Path(args.publisher_dir).expanduser(),
            target_branch=args.target_branch,
            branch_prefix=args.branch_prefix,
            relpath=relpath,
            content=content,
            title=analysis["title"],
            topic_slug=analysis.get("topic_slug"),
        )
    result = {
        **publish,
        "summary_for_user": analysis["summary_for_user"],
        "analysis": analysis,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"status": "error", "error": str(exc)}, ensure_ascii=False), file=sys.stderr)
        raise SystemExit(1)
