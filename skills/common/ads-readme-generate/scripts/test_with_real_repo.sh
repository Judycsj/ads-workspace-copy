#!/usr/bin/env bash
# test_with_real_repo.sh
# Test get_changed_files_since_readme.sh against a real GitLab repository.
#
# Usage (run from ads-workspace root):
#   bash skills/common/ads-readme-generate/scripts/test_with_real_repo.sh
#     → tests against the default repo (pas-index); no baseline → expects full scan (exit 10)
#
#   bash skills/common/ads-readme-generate/scripts/test_with_real_repo.sh <repo_url> [baseline_commit]
#     → tests against any GitLab repo; pass a baseline commit (e.g. HEAD~20 or a real
#       `checked:` hash) to exercise the incremental diff path

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/get_changed_files_since_readme.sh"

REPO_URL="${1:-https://git.garena.com/shopee/isfe/ao/pas-index}"
BASELINE="${2:-}"
REPO_NAME=$(basename "$REPO_URL" .git)
CLONE_DIR="/tmp/readme-test-${REPO_NAME}"

# Clean up on exit
trap 'echo ""; echo "Cleaning up $CLONE_DIR..."; rm -rf "$CLONE_DIR"' EXIT

echo "=== Cloning $REPO_URL ==="
git clone "$REPO_URL" "$CLONE_DIR" 2>&1 | tail -2
echo ""

echo "=== Running get_changed_files_since_readme.sh (baseline: ${BASELINE:-<none>}) ==="
CHANGED_FILES=""
STATUS=0
CHANGED_FILES=$(bash "$SCRIPT" "$CLONE_DIR" "$BASELINE") || STATUS=$?
echo ""

if [ "$STATUS" -eq 10 ]; then
  echo "Result: No usable baseline — first-time generation needed (full scan)"
  exit 0
fi

if [ "$STATUS" -ne 0 ]; then
  echo "Result: Script error (exit $STATUS)"
  exit 1
fi

if [ -z "$CHANGED_FILES" ]; then
  echo "Result: README is already up-to-date — no AI run needed"
  exit 0
fi

FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
echo "Result: $FILE_COUNT file(s) changed since last README update"
echo ""
echo "$CHANGED_FILES"
