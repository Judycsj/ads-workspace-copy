# Config Center Compare-and-Export (ads-config-center-compare-export) Guide

> **Language**: [English](ads-config-center-compare-export.md) | [中文](ads-config-center-compare-export.zh-CN.md)

Compare the latest Config Center namespace state across one or more zones and, only when the compared content is consistent, export one zone's config items into local JSON files.

**Trigger keywords**: "Config Center", "compare zones", "zone compare", "global latam compare", "export config", "compare and export", "导出配置"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition and usage workflow |
| `scripts/compare_export.py` | Helper script that fetches latest zone states, compares them, and exports per-item JSON files |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| `uv` | Tool | Run the helper script |
| `space.bearer_token` | Credential | Authenticate with Config Center APIs |
| `sra-toolkit/skills/sp-config-center` | Skill dependency | Provides the underlying Config Center read CLI |

This skill reuses `sp-config-center` instead of talking to `config.shopee.io` directly.

---

## Usage

### Scenario 1: Compare with a temporary output directory

> "Compare `global` and `latam` first, and use a temporary directory for export if they are consistent."

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-compare-export/scripts/compare_export.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --zones global,latam \
  --output-dir /tmp/ads-config-center-compare-export-check \
  --exclude-keys aggregation_config,group_key,metric_info
```

The script will:
1. Ask `sp-config-center` for the latest version of each requested zone
2. Fetch the exact versioned state for each zone
3. Remove any item keys listed in `--exclude-keys`
4. Compare the remaining state across zones
5. Print either `CONSISTENT` or `MISMATCH`
6. If consistent, export files into the provided output directory

### Scenario 2: Compare and export

> "If they are consistent, export the chosen zone into local JSON files."

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-compare-export/scripts/compare_export.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --zones global,latam \
  --exclude-keys aggregation_config,group_key,metric_info \
  --output-dir paidads_git/ultrav-core-timewindow/agent_exp_configs/product_ads
```

This command exports one file per config item only if the compared zones are consistent.
If `global` is included in `--zones`, export uses `global`; otherwise it uses the first zone in `--zones`.

### Scenario 3: Machine-readable output

> "Give me the structured compare result for automation or scripting."

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-compare-export/scripts/compare_export.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --zones global,latam \
  --output-dir /tmp/ads-config-center-compare-export-check \
  --exclude-keys aggregation_config,group_key,metric_info \
  --json
```

---

## Compare Rules

- The script compares the latest state of each requested zone.
- `--zones` may contain one zone or multiple zones.
- If `--exclude-keys` is provided, those item keys are removed before compare and export.
- Equality checks include:
  - zone latest `status`
  - per-item key set
  - per-item `type`
  - per-item `sensitive`
  - per-item `text_value`
- Zone `version` is shown in the summary, but version differences alone do **not** make the result a mismatch.
- If only one zone is provided, cross-zone comparison is skipped and the run behaves like a single-zone export flow.

If a mismatch is found:
- no files are exported
- the script lists the mismatched zones and item-level reasons

If all compared zones are consistent:
- only the auto-selected export zone is exported
- one JSON file is written per config item

---

## Export Rules

- One exported file corresponds to one Config Center item.
- The output directory is created automatically if needed.
- Exported files do **not** include Config Center meta fields such as:
  - `version`
  - `status`
  - `type`
  - `sensitive`
  - `key`
- If an item's `text_value` is valid JSON, the script writes parsed JSON.
- If an item's `text_value` is not valid JSON, the script writes it as a JSON string so the output file remains valid JSON.
- After export, the script verifies that the output directory exists and that the file count matches the expected item count.

---

## Output

The script prints:
- a zone summary with `version`, `status`, and `item_count`
- `excluded_keys` when `--exclude-keys` is used
- a compare result:
  - `CONSISTENT`
  - `Comparison Skipped: only one zone provided`
  - or `MISMATCH`
- export path and written file count when export succeeds

In `--json` mode, the script returns structured JSON including:
- `zone_summaries`
- `comparison_mode`
- `consistent`
- `zone_diffs`
- `exclude_keys`
- `written_files`

---

## Important Notes

- `--exclude-keys` filters items inside `ads-config-center-compare-export`; `sp-config-center` still fetches the full zone state first.
- Export happens only after consistency is confirmed.
- `--output-dir` is now required. If the compared zones are consistent, export runs automatically into that directory.
- Export zone is derived from `--zones`: `global` if present, otherwise the first zone.
- With a single zone such as `--zones global`, the script prints `Comparison Skipped: only one zone provided` and then exports that zone if possible.
- This skill pairs naturally with `ads-config-center-dir-to-pr`:
  - compare/export from Config Center with this skill
  - turn the exported directory back into a Config Center draft with `ads-config-center-dir-to-pr`

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `ads-config-center-dir-to-pr` | Turn a local directory of config JSON files into a Config Center create-pr draft |
| `sp-config-center` | Read config state, query versions, and manage publish requests |
