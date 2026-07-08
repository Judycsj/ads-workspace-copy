# ads-epic-experiment-summary

Generate a Markdown summary for ongoing experiments recorded in Epic files.

## Quick Start

```bash
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py O1-KR1
```

Default output:

```text
docs/personal/<user>/ads-epic-experiment-summary/<date>-<scope>-experiment-summary.md
```

## Selection Rule

A KA is included when:

- `5.1` has `UAT`.
- `5.1` has no `Done`.
- `5.2` has an experiment link for the same KA.

## Options

```bash
# Use a fixed window
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py \
  --date-range 2026-05-20:2026-05-24 O1-KR1

# Summarize an entire Objective
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py \
  --scope objective O1

# Use fixture/provider JSON
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py \
  --ab-data-dir tmp/ads-epic-summary-fixture O1-KR1

# Optional Epic 5.2 write-back
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py \
  --write-back-5-2 --ab-data-dir tmp/ads-epic-summary-fixture path/to/epic-file.md
```

## Risk Rule

The report flags only rev/advv risks when traffic is at least 10% and relative uplift is worse than two times the rollout guardrail threshold.
