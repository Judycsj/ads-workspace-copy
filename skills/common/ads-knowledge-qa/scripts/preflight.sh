#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/common.sh"

code_search_dir="$(require_skill_dir "sra-code-search")"
confluence_dir="$(require_skill_dir "sra-confluence-kb")"
data_query_dir="$(require_skill_dir "sra-data-query")"

# sra-kb-query is optional: it only backs the L2c hosted-KB layer and is not
# vendored in the sra-toolkit submodule, so a fresh clone may not have it.
kb_query_status=""
if kb_query_dir="$(resolve_skill_dir "sra-kb-query")"; then
    kb_query_status="$kb_query_dir"
else
    kb_query_status="not found — skip the L2c hosted-KB layer (L2a/L2b/L4 unaffected)"
    kb_query_override_var="$(skill_override_var_name "sra-kb-query")"
    cat >&2 <<EOF
Warning: optional skill 'sra-kb-query' was not found; the L2c hosted-KB layer is unavailable.
L2a (local index/atomic notes), L2b (Confluence), and L4 (source code) still work — skip L2c and continue.
To enable L2c, install sra-kb-query (e.g. ~/.agents/skills/sra-kb-query) or export $kb_query_override_var=/abs/path/to/sra-kb-query.
EOF
fi
index_doc_zh="$(ads_workspace_root)/docs/common/index-synthesis.zh-CN.md"
index_doc_en="$(ads_workspace_root)/docs/common/index-synthesis.md"
workspace_doc="$(ads_workspace_root)/docs/common/core-knowledge/"
readme_doc="$(ads_workspace_root)/docs/common/readme/"

since_date="$(rolling_twelve_months_ago)"

if [[ ! -f "$index_doc_zh" ]]; then
    echo "ads-knowledge-qa preflight failed: local knowledge index not found at $index_doc_zh" >&2
    exit 1
fi
if [[ ! -f "$index_doc_en" ]]; then
    echo "ads-knowledge-qa preflight failed: local English knowledge index not found at $index_doc_en" >&2
    exit 1
fi
if [[ ! -d "$workspace_doc" ]]; then
    echo "ads-knowledge-qa preflight failed: local knowledge doc not found at $workspace_doc" >&2
    exit 1
fi
if [[ ! -d "$readme_doc" ]]; then
    echo "ads-knowledge-qa preflight failed: local README doc not found at $readme_doc" >&2
    exit 1
fi

cat <<EOF
ads-knowledge-qa preflight OK
- sra-code-search: $code_search_dir
- sra-confluence-kb: $confluence_dir
- sra-data-query: $data_query_dir
- sra-kb-query: $kb_query_status
- local ads knowledge index zh: $index_doc_zh
- local ads knowledge index en: $index_doc_en
- local ads core knowledge dir: $workspace_doc
- local ads README dir: $readme_doc
- rolling 12-month Confluence filter starts at: $since_date

Supported entrypoints:
- index-first lookup: rg -rn "<keyword>" "$index_doc_zh" "$index_doc_en"
- selected atomic note read: sed -n "<start>,<end>p" <path from index>
- fallback core knowledge search: rg -rn "<keyword>" "$workspace_doc"
- fallback repo README search: rg -rn "<keyword>" "$readme_doc"
- supporting docs search: rg -n "<keyword>" docs/common docs/team -g '*.md'
- data query delegation: use sra-data-query for actual DataSuite SQL/ad-hoc data analysis
- bash scripts/run_code_search.sh <endpoint> '<json_body>'
- bash scripts/search_confluence_recent.sh '<base_cql_without_lastModified>' [limit]
EOF
