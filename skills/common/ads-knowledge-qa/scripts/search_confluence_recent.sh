#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

base_cql="${1:-}"
limit="${2:-5}"

if [[ -z "$base_cql" ]]; then
    echo "Usage: $0 '<base_cql_without_lastModified>' [limit]" >&2
    exit 1
fi

confluence_dir="$(require_skill_dir "sra-confluence-kb")"

if [[ "$base_cql" == *"lastModified"* ]]; then
    final_cql="$base_cql"
else
    since_date="$(rolling_twelve_months_ago)"
    final_cql="$base_cql AND lastModified >= \"$since_date\""
fi

exec bash "$confluence_dir/scripts/search_confluence.sh" "$final_cql" "$limit"
