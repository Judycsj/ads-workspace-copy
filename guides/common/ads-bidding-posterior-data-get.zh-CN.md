# Ads Bidding 后验数据查询 (ads-bidding-posterior-data-get) 使用指南

> **Language**: [English](ads-bidding-posterior-data-get.md) | [中文](ads-bidding-posterior-data-get.zh-CN.md)

通过 `ultrav-data-aggregator` Spex API 查询 Ads 后验数据。这个 skill 只读：用 curl 调 API，不直连 Redis。

**触发关键词**: "posterior data", "get_posterior_data", "get_content_posterior_data", "后验数据", "查 Redis 后验", "metric_type", "time_level"

---

## 场景 1：查询 Product Ads 后验数据

> **你**: `查 Product Ads TW 的 IMP count，campaign_id=176715825，placement=40，pricing_type=11，小时级，昨天窗口，不包含当前 bucket。`
>
> **AI**: 先确认时间窗口，把时间转换成 `time_span`，再生成 `get_posterior_data` 的 curl。

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

## 场景 2：查询 Content Ads 后验数据

Content Ads 使用相同 payload schema，但 endpoint 和 `biz_type` 不同。

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

Content Ads 的合法 `biz_type` 是 `shop_ads`、`live_ads`、`video_ads`、`brand_max`，不要用 `content_ads`。Content Ads 请求必须使用 service key `aec9fb275576bca09c07a6d0b13057c5` 和 SDU `contentads.ultravdataaggregator.global.live.master.default`。

---

## 必须确认的字段

真实排障前要确认：

| 字段 | 含义 |
|------|------|
| 产品线 | `product` 走 `get_posterior_data`；`content` 走 `get_content_posterior_data` |
| `biz_type` | 后端路由，例如 `product_ads`、`shop_ads`、`live_ads`、`video_ads`、`brand_max` |
| `metric_name` | 指标名，例如 `IMP` |
| `group_key_map` | 维度 map；除非用户给了别的 payload，值默认用字符串 |
| `time_level` | 时间粒度 |
| `end_time_unix_millis` | UTC 毫秒时间戳 |
| `window` | 向前查询多少个 bucket |
| `is_current_included` | 是否包含对齐后的当前 bucket |
| `metric_type` | count、scalar 或 all |

`group_key_map` 里要包含 `country`，common post-data 校验依赖它。

## Metric Type

| 值 | 含义 | API 读取方式 |
|----|------|--------------|
| `0` | 查询所有支持读法 | Count、scalar count、scalar sum |
| `1` | Count 指标 | `GetCount`，返回到 `result.count` |
| `2` | Scalar 指标 | `GetScalarCount` 和 `GetScalarSum`，返回到 `result.scalar_count` 和 `result.scalar_sum` |

如果用户说指标是 scalar，用 `metric_type=2`。如果 scalar 查询返回 Redis wrong-type，但 count 能查到数，要提示该指标可能实际按 count 数据存储。

## Time Level

| 值 | 粒度 | Redis time window |
|----|------|-------------------|
| `1` | 天级 | `yyyyMMdd` |
| `2` | 小时级 | `yyyyMMddHH` |
| `3` | 5 分钟 bucket | `yyyyMMddHHmm@5` |
| `4` | 15 分钟 bucket | `yyyyMMddHHmm@15` |
| `5` | 1 分钟 bucket | `yyyyMMddHHmm` |
| `6` | 历史 | `ALL` |

`end_time_unix_millis` 是 UTC 毫秒时间戳。API 会按查询国家转成本地时区，并按 `time_level` 向左对齐。

未传 `custom_time_unix_millis` 时：

- `is_current_included=true`：查询对齐后的当前 bucket 和前序 bucket，总共 `window + 1` 个 bucket。
- `is_current_included=false`：跳过对齐后的当前 bucket，只查询前序 bucket，总共 `window` 个 bucket。

`time_level=6` 时，common validator 不要求 `end_time_unix_millis` 或 `window`，它查询 `ALL` bucket。

## 输出检查

展示结果时包含：

- 顶层 `code` 和 `msg`
- `result.count`、`result.scalar_count`、`result.scalar_sum`
- 每个值的 `ok`、`value`、`error_message`
- 如果网关返回 `403` 等错误，附上实际使用的 curl
