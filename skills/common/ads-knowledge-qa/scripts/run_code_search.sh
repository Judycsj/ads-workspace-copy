#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

endpoint="${1:-}"
json_body="${2:-}"

if [[ -z "$endpoint" ]]; then
    echo "Usage: $0 <endpoint> ['<json_body>']" >&2
    exit 1
fi

code_search_dir="$(require_skill_dir "sra-code-search")"
args=("$endpoint")
if [[ -n "$json_body" ]]; then
    args+=("$json_body")
fi

exec bash "$code_search_dir/scripts/code_search.sh" "${args[@]}"
