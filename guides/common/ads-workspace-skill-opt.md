# ads-workspace-skill-opt — Skill Audit & Optimization

Scan skills across 10 quality dimensions, generate optimization plans, and execute improvements.

## Quick Start

```
/ads-workspace-skill-opt           # Interactive mode
审查 ads-okr-memory-update        # Audit a specific skill
批量扫描 common skills             # Batch scan all common skills
```

## 10 Audit Dimensions

| # | Dimension | Auto Check | LLM Review |
|---|-----------|-----------|------------|
| D1 | Readability | Line count, duplicates | Phase/Step structure |
| D2 | Interaction Efficiency | AskUserQuestion count | Confirm-Once opportunities |
| D3 | Scriptification | scripts/ existence, PEP 723 | Scriptable file I/O |
| D4 | Reuse & Dedup | Common patterns | Cross-skill sharing |
| D5 | Error Handling | Error pattern count | Action mapping completeness |
| D6 | Frontmatter | Required fields | Minimal permissions |
| D7 | Token Efficiency | Body size, code blocks | references/ split |
| D8 | Security | Hardcoded secrets | Destructive operations |
| D9 | Testability | argparse usage | Independent test entry |
| D10 | Documentation | Guide existence | Example coverage |

## Script Usage

```bash
# Scan single skill
uv run skills/common/ads-workspace-skill-opt/scripts/audit.py scan \
  --skill-dir "skills/common/ads-xxx/" --project-cwd "$(pwd)"

# Batch scan
uv run skills/common/ads-workspace-skill-opt/scripts/audit.py batch-scan \
  --scope common --top 10 --project-cwd "$(pwd)"
```

## Optimization Priority

1. **Quick Wins** (≤10 min): Frontmatter fixes, PEP 723 headers
2. **Medium Effort** (1-2h): Confirm-Once, body split to references/
3. **Large Refactor** (half day+): Full scriptification, shared library extraction
