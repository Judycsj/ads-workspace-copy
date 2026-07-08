# Ads DB Map/广告 DB 地图

This is a compact orientation map. Verify table-level details with DB Viewer metadata and `ads-db-lib` before answering precise questions.

## Logical Domains/逻辑域

| DB enum | Domain | Typical content | ads-db-lib client/code |
|---:|---|---|---|
| 1 | Ads Core DB | accounts, campaigns, advertisements, keywords, credits, translogs, product/shop/item indexes | `AdsClient`, `ads.go`, `ads_*_v2.go`, `ads_*_v3.go` |
| 2 | Archive DB | archived or historical Ads data | archive-related config/code paths |
| 3 | Buyer Segment DB | buyer segment data | `BuyerSegmentClient`, `buyer_segment.go` |
| 4 | SRM DB | segments, programs, incentives, trackers | `SRMClient`, `srm.go`, `srm_*.go` |
| 5 | Buyer Segment By Region DB | region-split buyer segment data | buyer segment region config |
| 6 | Ads Marketing DB | marketing flags, campaign-day, daily budget, marketing tools | `AdsMarketingClient`, `ads_marketing.go` |
| 7 | Rebate DB | rebate records and related accounting | `RebateClient`, `rebate.go` |

## ads-db-lib Roles/ads-db-lib 作用

`ads-db-lib` is the shared Go library for Paid Ads DB access. Use it to correct or enrich:

- table constants and logical table names
- sharding and region routing
- client ownership, such as `AdsClient`, `SRMClient`, `RebateClient`
- query methods and required IDs, such as user ID based shard routing
- sentinel values and business-specific conversions when visible in code

Run:

```bash
uv run skills/team/01.ads-engineering/ads-db-viewer/scripts/ads_db_lib_lookup.py \
  --query ads_account
```

## Common Interpretation Hints/常见解释提示

- Ads Core tables are often region-aware and may be sharded by user/account/campaign identifiers.
- A physical table like `*_tab_00000000` is usually one shard/example; the logical table is represented in metadata/code by a table format.
- Timestamp fields such as `ctime` and `mtime` often store Unix seconds, but verify per table before converting.
- Money/budget fields may use scaled integer units. Confirm scale in code or documentation before presenting human currency.
- `extinfo`-like fields usually require protobuf/JSON-specific code evidence before interpretation.
