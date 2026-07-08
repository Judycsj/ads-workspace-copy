#!/usr/bin/env bash

set -euo pipefail

ads_knowledge_qa_root() {
    (cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
}

ads_workspace_root() {
    local root
    root="$(ads_knowledge_qa_root)"
    (cd "$root/../../.." && pwd -P)
}

skill_override_var_name() {
    local skill_name="$1"
    local normalized="${skill_name//-/_}"
    normalized="$(printf '%s' "$normalized" | tr '[:lower:]' '[:upper:]')"
    printf 'ADS_KNOWLEDGE_QA_%s_DIR' "$normalized"
}

resolve_skill_dir() {
    local skill_name="$1"
    local override_var
    override_var="$(skill_override_var_name "$skill_name")"
    local override_value="${!override_var:-}"

    local -a candidates=()
    if [[ -n "$override_value" ]]; then
        candidates+=("$override_value")
    fi

    local root
    root="$(ads_knowledge_qa_root)"
    local repo_root
    repo_root="$(ads_workspace_root)"

    candidates+=(
        "$repo_root/skills/common/$skill_name"
        "$repo_root/sra-toolkit/skills/$skill_name"
        "$HOME/.agents/skills/$skill_name"
        "$HOME/.claude/skills/$skill_name"
        "$HOME/.cursor/skills/$skill_name"
        "${CODEX_HOME:-$HOME/.codex}/skills/$skill_name"
    )

    local team_dir
    for team_dir in "$repo_root"/skills/team/*; do
        [[ -d "$team_dir" ]] || continue
        candidates+=("$team_dir/$skill_name")
    done

    local owner_dir
    for owner_dir in "$repo_root"/skills/personal/*; do
        [[ -d "$owner_dir" ]] || continue
        candidates+=("$owner_dir/$skill_name")
    done

    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate/SKILL.md" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

require_skill_dir() {
    local skill_name="$1"
    local resolved
    if resolved="$(resolve_skill_dir "$skill_name")"; then
        printf '%s\n' "$resolved"
        return 0
    fi

    local override_var
    override_var="$(skill_override_var_name "$skill_name")"
    cat >&2 <<EOF
Error: required skill '$skill_name' was not found.
Checked ads-workspace common/team/personal scopes, vendored sra-toolkit skills, plus ~/.agents/skills, ~/.claude/skills, ~/.cursor/skills, and \$CODEX_HOME/skills.
If it is installed elsewhere, export $override_var=/abs/path/to/$skill_name and retry.
EOF
    return 1
}

rolling_twelve_months_ago() {
    python3 - <<'PY'
from datetime import date

today = date.today()
try:
    start = today.replace(year=today.year - 1)
except ValueError:
    start = today.replace(year=today.year - 1, day=28)
print(start.isoformat())
PY
}
