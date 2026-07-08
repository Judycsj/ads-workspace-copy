# Code Standards

## Shell

- `set -euo pipefail`, quote variables, `[[ ]]` over `[ ]`

## Python Dependencies (uv + PEP 723)

- Entry-point scripts MUST use PEP 723 inline metadata:
  ```python
  # /// script
  # requires-python = ">=3.10"
  # dependencies = [
  #   "httpx>=0.27",
  # ]
  # ///
  ```
- Helper modules (no `__main__`) do not need PEP 723 headers
- Use `uv run script.py` (not `python3`); no `requirements.txt` for new skills
- Version constraints: use `>=`; bare package names without version not allowed

## Skill Code Review

- Validate with `scripts/validate.sh` before committing
- Verify all `references/`/`scripts/` paths exist, cross-skill imports use correct relative paths, no broken symlinks
