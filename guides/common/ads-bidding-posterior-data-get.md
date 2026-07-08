# Ads Bidding Posterior Data Get Guide

> **Language**: [English](ads-bidding-posterior-data-get.md) | [中文](ads-bidding-posterior-data-get.zh-CN.md)

Query Ads posterior data through the `ultrav-data-aggregator` Spex API. The skill is read-only: it calls the API with curl and does not connect to Redis directly.

**Trigger keywords**: "posterior data", "get_posterior_data", "get_content_posterior_data", "后验数据", "查 Redis 后验", "metric_type", "time_level"

---

## Scenario 1: Query Product Ads posterior data

> **You**: `Query Product Ads TW IMP count for campaign_id=176715825, placement=40, pricing_type=11, yesterday hourly window excluding current bucket.`
>
> **AI**: Confirms the time window, converts it to `time_span`, then generates a curl for `get_posterior_data`.

```bash
curl -v -X POST 'https://http-gateway.spex.shopee.sg/sprpc/adsbidding.ultravdataaggregator.get_posterior_data' \
  --header 'x-sp-servicekey: 597268a496a5b34c085b9b1e183f744c' \
  --header 'x-sp-timeout: 3000' \
  --header 'x-sp-sdu: adsbidding.ultravdataaggregator.global.live.master.default' \
  --header 'shopee-baggage: CID=tw' \
  --header 'Content-Type: application/json' \
  --data '{
    "request_id": "test_sjdoijcds",
    "biz_type": "product_ads",
    "metric_name": "IMP",
    "group_key_map": {
      "country": "TW",
      "placement": "40",
      "pricing_type": "11",
      "campaign_id": "176715825"
    },
    "time_span": {
      "time_level": 2,
      "end_time_unix_millis": 1782378000000,
      "window": 1,
      "is_current_included": false
    },
    "metric_type": 1
  }'
```

## Scenario 2: Query Content Ads posterior data

Use the same payload schema, but call the content endpoint and use a real content biz type.

```bash
curl -v -X POST 'https://http-gateway.spex.shopee.sg/sprpc/adsbidding.ultravdataaggregator.get_content_posterior_data' \
  --header 'x-sp-servicekey: aec9fb275576bca09c07a6d0b13057c5' \
  --header 'x-sp-timeout: 3000' \
  --header 'x-sp-sdu: contentads.ultravdataaggregator.global.live.master.default' \
  --header 'shopee-baggage: CID=sg' \
  --header 'Content-Type: application/json' \
  --data '{
    "request_id": "test_content",
    "biz_type": "shop_ads",
    "metric_name": "IMP",
    "group_key_map": {
      "country": "SG"
    },
    "time_span": {
      "time_level": 1,
      "end_time_unix_millis": 1782355693000,
      "window": 1,
      "is_current_included": false
    },
    "metric_type": 1
  }'
```

Valid content biz types are `shop_ads`, `live_ads`, `video_ads`, and `brand_max`. Do not use `content_ads`. Content Ads calls must use service key `aec9fb275576bca09c07a6d0b13057c5` and SDU `contentads.ultravdataaggregator.global.live.master.default`.

---

## Required confirmations

Before producing a real debugging query, confirm:

| Field | Meaning |
|-------|---------|
| Product line | `product` uses `get_posterior_data`; `content` uses `get_content_posterior_data` |
| `biz_type` | Backend route, for example `product_ads`, `shop_ads`, `live_ads`, `video_ads`, `brand_max` |
| `metric_name` | Metric name such as `IMP` |
| `group_key_map` | Dimension map; keep values as strings unless the user provides another API payload |
| `time_level` | Bucket granularity |
| `end_time_unix_millis` | UTC Unix timestamp in milliseconds |
| `window` | Number of previous buckets to include |
| `is_current_included` | Whether to include the aligned current bucket |
| `metric_type` | Count, scalar, or all |

Include `country` in `group_key_map`; common post-data validation requires it.

## Metric Type

| Value | Meaning | API read |
|-------|---------|----------|
| `0` | All supported reads | Count, scalar count, scalar sum |
| `1` | Count metric | `GetCount`, returned in `result.count` |
| `2` | Scalar metric | `GetScalarCount` and `GetScalarSum`, returned in `result.scalar_count` and `result.scalar_sum` |

If the user says the metric is scalar, use `metric_type=2`. If scalar queries return Redis wrong-type errors but count succeeds, call out that the metric may be stored as count data.

## Time Level

| Value | Granularity | Redis time window |
|-------|-------------|-------------------|
| `1` | Daily | `yyyyMMdd` |
| `2` | Hourly | `yyyyMMddHH` |
| `3` | 5-minute bucket | `yyyyMMddHHmm@5` |
| `4` | 15-minute bucket | `yyyyMMddHHmm@15` |
| `5` | 1-minute bucket | `yyyyMMddHHmm` |
| `6` | History | `ALL` |

`end_time_unix_millis` is a UTC millisecond timestamp. The API converts it to the query country's local timezone and aligns it left to the selected `time_level`.

When `custom_time_unix_millis` is not provided:

- `is_current_included=true`: query the aligned bucket plus previous buckets, total `window + 1` buckets.
- `is_current_included=false`: skip the aligned bucket and query only previous buckets, total `window` buckets.

For `time_level=6`, the common validator does not require `end_time_unix_millis` or `window`; it queries the `ALL` bucket.

## Output Checklist

When presenting results, include:

- Top-level `code` and `msg`
- `result.count`, `result.scalar_count`, and `result.scalar_sum`
- Each value's `ok`, `value`, and `error_message`
- The exact curl if the gateway returns an error such as `403`
