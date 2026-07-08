#!/usr/bin/env bash
# get_changed_files_since_readme.sh
# Find source files changed in the target repo since the last README generation.
#
# Usage: get_changed_files_since_readme.sh [REPO_PATH] [BASELINE_COMMIT]
#
# REPO_PATH        Path to the git repository (default: current directory)
# BASELINE_COMMIT  The target-repo commit recorded in the existing generated
#                  README's marker (<!-- ... checked: <hash> -->). The generated
#                  README lives OUTSIDE the repo (ads-workspace
#                  docs/common/readme/<project>/), so this is the only meaningful
#                  baseline. When omitted (no generated README yet), the script
#                  reports a full scan is required (exit 10) — there is no in-repo
#                  README to fall back to.
#
# Stdout: newline-separated source file paths changed since the baseline commit.
#         Lines without a prefix  → file exists in HEAD; agent should read it.
#         Lines with "deleted:" prefix → file was removed; agent cannot read it
#           but should remove stale documentation from README.
# Stderr: diagnostic/status messages for CI logs.
#
# Exit codes:
#   0  — success; changed files on stdout (empty = README is up-to-date, skip AI)
#   10 — no baseline supplied, or baseline not found in repo (run full scan)
#   1  — error (bad path, not a git repo, no commits, etc.)

set -euo pipefail

REPO_PATH="${1:-.}"
BASELINE_OVERRIDE="${2:-}"

cd "$REPO_PATH" || { echo "ERROR: cannot access path: $REPO_PATH" >&2; exit 1; }

git rev-parse --git-dir > /dev/null 2>&1 \
  || { echo "ERROR: not a git repository: $(pwd)" >&2; exit 1; }

HEAD=$(git rev-parse HEAD 2>/dev/null || echo "")
[[ -z "$HEAD" ]] && { echo "ERROR: repository has no commits" >&2; exit 1; }

if [[ -n "$BASELINE_OVERRIDE" ]]; then
  if git cat-file -e "${BASELINE_OVERRIDE}^{commit}" 2>/dev/null; then
    BASELINE="$BASELINE_OVERRIDE"
  else
    echo "Baseline commit $BASELINE_OVERRIDE not found in repo — full scan required" >&2
    exit 10
  fi
else
  echo "No baseline commit supplied — first-time generation, full scan required" >&2
  exit 10
fi

BASELINE_DATE=$(git show -s --format="%ci" "$BASELINE" 2>/dev/null || echo "unknown")
echo "Baseline commit: $BASELINE ($BASELINE_DATE)" >&2

if [[ "$BASELINE" == "$HEAD" ]]; then
  echo "Baseline is at HEAD — no changes since last generation" >&2
  exit 0
fi

COMMIT_COUNT=$(git rev-list --count "$BASELINE".."$HEAD" 2>/dev/null || echo "?")
echo "HEAD is $COMMIT_COUNT commit(s) ahead of baseline" >&2

# Changed/added files — agent reads these.
git diff --name-only --diff-filter=d "$BASELINE" "$HEAD" \
  | grep -v -E '^README' \
  || true

# Deleted files — agent cannot read these but should remove stale README docs.
DELETED=$(git diff --name-only --diff-filter=D "$BASELINE" "$HEAD" \
  | grep -v -E '^README' \
  || true)
if [[ -n "$DELETED" ]]; then
  while IFS= read -r f; do
    echo "deleted:$f"
  done <<< "$DELETED"
fi
