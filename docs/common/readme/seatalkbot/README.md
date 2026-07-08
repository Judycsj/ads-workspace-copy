<!-- ads-workspace-gdoc-sync: gdoc_id=11SSITG-xZnZlRRMS8Vt_v9Atgg9_fQgtEH1gQepeTSQ gdoc_url=https://docs.google.com/document/d/11SSITG-xZnZlRRMS8Vt_v9Atgg9_fQgtEH1gQepeTSQ/edit -->

# seatalkbot


## Preparation

```bash
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
pip install sccclient --force-reinstall --index-url=https://pypi.garenanow.com

# 1. Run with local config.json

# fill the config.json with your APP_ID and APP_SECRET
cp config.json.example config.json # update it
python start.py --port 10086 --config config.json

# 2. Run with spex config
python start.py --port 10086 \
    --spex-project="[sp]paidads" \
    --spex-name=seatalkbot \
    --spex-secret=xxx \
    --spex-config-key=config
```

`config` 仍然存放主 runtime 配置；检索 taxonomy 会默认从同一 namespace 的 `retrieval_taxonomy`
key 读取，并在运行时合并到 `RETRIEVAL_TAXONOMY`。如需覆盖 key 名，可额外传
`--spex-taxonomy-key=<key>`.

Agent 访问策略会默认从同一 namespace 的 `agent_access_policy` key 读取，并在运行时合并到
`AGENT_ACCESS_POLICY`。当前主要用于管理按用户 email 的 QA quota，例如：

```json
{
  "user_quota": {
    "enabled": true,
    "period": "weekly",
    "limit": 15,
    "whitelist": [
      "alice@shopee.com",
      "bob@shopee.com"
    ]
  }
}
```

如需覆盖该 key 名，可额外传 `--spex-agent-access-policy-key=<key>`.

## Development

1. develop your own handler (ref to [DemoHandler](src/handler/demo_handler.py))
2. change the `HANDLER` in `config.json` file
3. restart the service

## Report API

`/admin/feedback_stats` now returns a Markdown report in the API response under `data.report_markdown`.

Example:

```bash
python start.py --port 10086 --config config.json
curl "http://127.0.0.1:10086/admin/feedback_stats?days=7"
```

Optional Google Doc append:

```bash
curl "http://127.0.0.1:10086/admin/feedback_stats?days=7&write_gdoc=true"
```

The report includes:

- window-level scanned requests, cost-recorded requests, total cost, average cost among cost-recorded requests, elapsed time, and usage totals
- request asker email
- feedback submitter email
- request / answer / feedback timestamps when available
- response elapsed time
- response total cost
- `<details>` wrapped answers for each Not Helpful case

## Standalone Report Service

You can run the report API as a dedicated service:

```bash
pip install -r requirements-report-service.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
python report_service_start.py --port 18081 --config config.json
```

Or with SPEX:

```bash
python report_service_start.py --port 18081 \
    --spex-project="[sp]paidads" \
    --spex-name=seatalkbot \
    --spex-secret=xxx \
    --spex-config-key=config
```

Report service 与主 bot 服务使用相同的 SPEX taxonomy merge 逻辑，也会默认读取
`retrieval_taxonomy` key，并支持同样的 `agent_access_policy` key merge 逻辑。

## Devbox Routine Task

Use the devbox task to call the report API, write the Markdown report into `ads-workspace`, and create a merge request from `master`:

```bash
python -m src.startup_tasks feedback-report-mr \
  --report-api-url http://127.0.0.1:18081/admin/feedback_stats \
  --days 7 \
  --ads-workspace-dir ~/devbox-workspaces/ads-workspace-feedback-report
```

The generated routine report includes the same window-level request and cost summary from the report API. Cost totals and averages are calculated only from requests with cost records. The task then writes the Markdown file into `ads-workspace` and creates a report MR.

Dry run:

```bash
python -m src.startup_tasks feedback-report-mr \
  --report-api-url http://127.0.0.1:18081/admin/feedback_stats \
  --days 7 \
  --ads-workspace-dir ~/devbox-workspaces/ads-workspace-feedback-report \
  --dry-run
```

## Bot Platform

the callback url is `http://ip:port/callback`
