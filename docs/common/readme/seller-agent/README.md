<!-- ads-workspace-gdoc-sync: gdoc_id=1GZcba51b0YfWuOqhm6MwXZxhcvYLriYD2NzpjXZkM3A gdoc_url=https://docs.google.com/document/d/1GZcba51b0YfWuOqhm6MwXZxhcvYLriYD2NzpjXZkM3A/edit -->

# seller-agent

HTTP service layer for the Shopee Ads seller-facing bot. Deployed to CMDB at `selleragent.shopee.io` / `selleragent.test.shopee.io`.

Skills, MCP tool bodies, and knowledge assets live in the `shopee-ads-agent` repo and are consumed here via a git submodule at `deps/shopee-ads-agent/`. See [CLAUDE.md](CLAUDE.md) for the service model, multi-tenant contract, and local dev steps.

CMDB: https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.ads_engine.llm_application.seller_agent/?env=live

## Request Schema

Every `/query` call is stateless with respect to seller identity — `shop_id`, `seller_id`, `region`, `locale` must be sent per request.

```bash
# live env
curl --location 'https://selleragent.shopee.io/query' \
  --header 'Content-Type: application/json' \
  --data '{
    "query": "帮我看下最近一周的广告表现",
    "shop_id": "<shop_id>",
    "seller_id": "<seller_id>",
    "region": "my",
    "locale": "CN"
  }'

# test env
curl --location 'https://selleragent.test.shopee.io/query' \
  --header 'Content-Type: application/json' \
  --data '{
    "query": "1+1=?",
    "shop_id": "<shop_id>",
    "seller_id": "<seller_id>",
    "region": "my",
    "locale": "CN"
  }'
```

Optional `session_id` (from a prior response) resumes the Claude SDK conversation.

## Response Schema

```json
{
  "session_id": "<claude-sdk-session-id>",
  "report_id": "<per-request-uuid>",
  "response": "<seller-facing answer>",
  "html_url": "/reports/<report_id>/latest.html",
  "html_available": true,
  "err_msg": null
}
```

`html_url` is a relative path served by the same service under `/reports/`. HTML sidecars are written to `.tmp/reports/<report_id>/latest.html` and are currently ephemeral (container restart loses them).

## Deployment Notes

- The Claude key is currently set in `Deployment` / `Configuration` / `Environment Variables` and is shared with the ads Q&A bot. Replace with a dedicated key before broader rollout.
- Additional required env vars on the deployment: `MARKETING_API_TOKEN`, `CLICKHOUSE_PASSWORD`, and `SHOPEE_AGENT_LIVE_ONLY=1` (so MCP tools return live-only errors instead of local mock fixtures).
- The build step installs the broad skill allowlist; audit and tighten before production use beyond the demo bot.
- The build step initializes the `deps/shopee-ads-agent` submodule and `pip install -e`s its MCP package.

## AppV2

```bash
# submit task
curl --location 'https://selleragent.shopee.io/report/submit' \
--header 'Content-Type: application/json' \
--data '{
    "preset": "GMS", // GMS|SAC
    "seller_id": "{seller_id}",
    "shop_id": "{shop_id}",
    "region": "my",
    "locale": "CN",
    "mode": "async" // sync|async
}'

# response:
# {"report_id":"{report_id}","status":"pending"}

# get status
curl --location 'https://selleragent.shopee.io/report/status' \
--header 'Content-Type: application/json' \
--data '{
    "preset": "GMS",
    "shop_id": "{shop_id}"
}'

# get status via report_id
curl --location 'https://selleragent.shopee.io/report/status' \
--header 'Content-Type: application/json' \
--data '{
    "report_id": "GMS_2026w22_17492625"
}'

# response:
# {"report_id":"{report_id}","status":"done","summary":"the JSON summary data"}

# get report content
curl --location 'https://selleragent.shopee.io/report/page/GMS_2026w22_17492625'

# feedback
curl --location 'https://selleragent.test.shopee.io/report/feedback' \
--header 'Content-Type: application/json' \
--data '{
    "report_id": "GMS_2026w22_17492625",
    "shop_id": "17492625",
    "feedback": "this is the feedback data, shoule be the form data, prefer JSON",
    "extra": "user extra feedback"
}'

# get feedback
curl --location 'https://selleragent.test.shopee.io/report/feedback/GMS_2026w22_17492625'
```