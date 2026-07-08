# Config Center Directory-to-PR (ads-config-center-dir-to-pr) Guide

> **Language**: [English](ads-config-center-dir-to-pr.md) | [中文](ads-config-center-dir-to-pr.zh-CN.md)

Generate a Config Center `create-pr --from-file` draft from a local directory of JSON files, or from a specified directory in a Git repository, then create a publish request through `sp-config-center`.

**Trigger keywords**: "Config Center", "create PR from directory", "目录生成PR", "from_file", "本地配置生成发布单", "git 目录生成发布单", "config publish request", "目录转 draft", "create config pr"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition and usage workflow |
| `scripts/create_pr_from_dir.py` | Helper script that scans local or Git-hosted JSON files, builds a per-zone draft, and calls `sp-config-center create-pr` |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| `uv` | Tool | Run the helper script |
| `space.bearer_token` | Credential | Authenticate with Config Center APIs |
| `sra-toolkit/skills/sp-config-center` | Skill dependency | Provides the underlying `create-pr` CLI |

**Required `sp-config-center` capabilities**:
- multi-zone `create-pr`
- per-zone `--from-file` top-level structure such as `global` / `latam`

If `sra-toolkit` was updated recently, refresh `.tooling/skills` before using this skill.

---

## Usage

### Scenario 1: Preview the generated draft from a local directory

> "Build the draft from this directory and show me what will be sent"

Use `--dry-run` first:

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-dir-to-pr/scripts/create_pr_from_dir.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --strategy-id 670 \
  --title "sync product_ads configs" \
  --input-dir paidads_git/ultrav-core-timewindow/agent_exp_configs/product_ads \
  --exclude-keys aggregation_config,group_key,metric_info \
  --dry-run
```

The script will:
1. Load the current namespace state across all zones
2. Scan top-level `*.json` files directly under `input_dir`
3. Convert each filename stem into a Config Center key
4. Skip any keys listed in `--exclude-keys`
5. Build a per-zone `from_file` draft
6. Print a summary and the generated draft file path

### Scenario 2: Create a live publish request from a local directory

> "Create a Config Center PR from this directory"

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-dir-to-pr/scripts/create_pr_from_dir.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --strategy-id 670 \
  --title "sync product_ads configs" \
  --input-dir paidads_git/ultrav-core-timewindow/agent_exp_configs/product_ads \
  --exclude-keys aggregation_config,group_key,metric_info \
  --yes \
  --yes-live
```

This creates a publish request through `sp-config-center create-pr`.

### Scenario 3: Reuse Config Center export output

> "Turn the files exported earlier from Config Center back into a publish draft"

This skill pairs naturally with `ads-config-center-compare-export`:
- `ads-config-center-compare-export` exports one file per config item
- `ads-config-center-dir-to-pr` turns that directory back into a per-zone draft and creates a PR

### Scenario 4: Preview the generated draft from a Git directory

> "Fetch this repo path and show me the draft from the JSON files there"

Use `--git-repo`, `--git-ref`, and `--git-path` instead of `--input-dir`:

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-dir-to-pr/scripts/create_pr_from_dir.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --strategy-id 670 \
  --title "sync product_ads configs" \
  --git-repo gitlab@git.garena.com:shopee/deep/paidads-bidding/ultrav-core-timewindow.git \
  --git-ref master \
  --git-path agent_exp_configs/product_ads \
  --exclude-keys aggregation_config,group_key,metric_info \
  --dry-run
```

For Git input, the script materializes the requested repo directory under `/tmp`, prints the resolved commit SHA, and automatically appends the Git source metadata to the publish request description in create mode.

### Scenario 5: Create a live publish request from a Git directory

> "Fetch this repo path and create a live Config Center PR from the JSON files there"

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-dir-to-pr/scripts/create_pr_from_dir.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --strategy-id 670 \
  --title "sync product_ads configs" \
  --git-repo gitlab@git.garena.com:shopee/deep/paidads-bidding/ultrav-core-timewindow.git \
  --git-ref master \
  --git-path agent_exp_configs/product_ads \
  --exclude-keys aggregation_config,group_key,metric_info \
  --yes \
  --yes-live
```

For live requests, `--yes-live` is required. Without it, the script builds the draft but refuses to create the live publish request.

---

## Draft Generation Rules

- One input file maps to one Config Center item.
- Only top-level files matching `*.json` are included; nested directories are ignored.
- Hidden files are ignored.
- Files whose stems appear in `--exclude-keys` are skipped.
- The same input file content is applied to every zone.
- The script wraps the result into a **per-zone** draft automatically.
- Git input is materialized into `/tmp` with sparse checkout when `--git-path` is not `.`.
- `--input-dir` cannot be combined with Git source arguments.
- Git source mode requires all of `--git-repo`, `--git-ref`, and `--git-path`.
- The generated draft is incremental: files in the input directory add or update items, but remote items missing from the input directory are kept.

Generated `from_file` shape:

```json
{
  "global": {
    "config_key": {
      "type": "JSON",
      "text_value": "{...}",
      "sensitive": false
    }
  },
  "latam": {
    "config_key": {
      "type": "JSON",
      "text_value": "{...}",
      "sensitive": false
    }
  }
}
```

For each zone:
- if a key already exists online, the script reuses that zone's `type` and `sensitive`
- if a key does not exist online, the script falls back to `--default-type` and `sensitive=false`
- if all files are excluded, the script exits instead of building an empty draft

---

## Output

During execution, the script prints:
- a summary including project / namespace / env / strategy / excluded keys (when provided) / draft size
- the generated draft file path
- for Git input, the masked repo URL, requested ref, resolved commit, repo path, and materialized directory

In `--dry-run` mode:
- no PR is created
- draft keys are printed for inspection

In create mode:
- the script calls `sp-config-center create-pr`
- on success it prints the PR id and status

---

## Important Notes

- This skill assumes **one directory = same intended content for all zones**.
- Use `--exclude-keys aggregation_config,group_key,metric_info` when those three files should not be part of the draft.
- If you need different content per zone, use `sp-config-center create-pr --from-file` directly with a hand-authored per-zone draft.
- `--dry-run` is strongly recommended before creating a live PR.
- For live create mode, include `--yes-live`; otherwise the script builds the draft but refuses to create the live publish request.
- The generated draft file is kept on disk and its path is printed for debugging.
- For Git sources, prefer SSH URLs or local git credentials. If an HTTPS URL contains credentials, the summary masks them.
- This skill does not talk to `config.shopee.io` directly; it reuses `sp-config-center`.

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `ads-config-center-compare-export` | Compare zone configs and export Config Center items to local JSON files |
| `sp-config-center` | Read config state, create PRs, approve, publish, close, and revert |
