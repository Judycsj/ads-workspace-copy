<!-- ads-workspace-gdoc-sync: gdoc_id=13WHH-VMn0a54zpXyiCkbh4Xd2MgI3Gqcfb_4uFVV9LI gdoc_url=https://docs.google.com/document/d/13WHH-VMn0a54zpXyiCkbh4Xd2MgI3Gqcfb_4uFVV9LI/edit -->

# Columns: mp_paidads.ods_shopee_ads_db__translog_tab_di__id_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无明显 SUM(DISTINCT) 模式 -- 此表为事务级明细表，通常不直接聚合，而是作为 DWD 层的数据源。`deduct_unique_id` 是去重键。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | 1 | CPC deduction (click) |
| operation | 2 | topup_from_order |
| operation | 3 | topup_manual |
| operation | 4 | topup_wallet |
| operation | 5 | deduct_order |
| operation | 6 | topup_svs |
| operation | 8 | topup_from_seller_mission |
| operation | 9 | topup_from_srm |
| operation | 10 | topup_negative |
| operation | 11 | CPM deduction (impression) |
| operation | 15 | CPS deduction (order) |
| extinfo: $.paidFreeExpirySummary.entries.type | 1 | Paid credit without expiry |
| extinfo: $.paidFreeExpirySummary.entries.type | 2 | Paid credit with expiry |
| extinfo: $.paidFreeExpirySummary.entries.type | 3 | Free credit without expiry |
| extinfo: $.paidFreeExpirySummary.entries.type | 4 | Free credit with expiry |
| extinfo: $.adsCredits.mainType | 2 | Paid credit |
| extinfo: $.adsCredits.mainType | 3 | Free credit |
| extinfo: $.adsCredits.mainType | 5 | Mixed credit |
| extinfo: $.adsCredits.orderType | 19 | Rebate free credit |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: Always filtered by specific date, e.g. `= date('${BIZ_YESTERDAY}')`, `= date('2024-09-25')`
- `operation`: `in (1, 11, 15)` (all deduction events), `in (1, 11)` (CPC/CPM), `= 11` (CPM only), `= 1` (CPC only)
- `deduct_unique_id`: Frequently used for investigation, e.g. `= 1879806788313350431`
- `placement`: `in (3342, 45)` (Common CPM placement comparison), `in (3, 2003)` (Shop ads)
- `shopid`: For shop-specific investigation
- `keyword`: `!= 'system_dummy_negative_deduction'` (exclude system dummy records)
- **Note: No `grass_region` filter** -- this is the ID-only variant. Region is always implicitly ID.

### decoded_extinfo JSON 关键字段

`decoded_extinfo` 是一个 JSON 字符串，通过 `get_json_object()` 或 `from_json()` 提取。下游常用字段：

| JSON Path | Type | Description |
|-----------|------|-------------|
| `$.campaignid` | bigint | Campaign ID |
| `$.entrance` | int | Entrance ID |
| `$.subEntrance` | int | Sub-entrance ID |
| `$.pricingType` | int | Pricing type |
| `$.matchType` | int | Match type (search) |
| `$.recallType` | int | Recall type |
| `$.bidType` | string | Bid type |
| `$.entryPoint` | string | Entry point |
| `$.requestId` | string | Request ID |
| `$.trafficSource` | int | Traffic source |
| `$.deductTimestamp` | bigint | Deduction timestamp |
| `$.clickTimestamp` | bigint | Click timestamp |
| `$.lsSessionId` | bigint | Livestream session ID |
| `$.batchCnt` | bigint | Batch count (CPM impression count) |
| `$.expectDeductPrice` | bigint | Expected deduction price |
| `$.deductionInfo.deductionPrice` | bigint | Deduction price (in 10^-5) |
| `$.voucherDeductionPrice` | bigint | Voucher deduction price (in 10^-5) |
| `$.validBalance` | bigint | Valid balance |
| `$.availableBalance` | bigint | Available balance |
| `$.query.keyword` | string | User search query keyword |
| `$.paidFreeExpirySummary.entries` | array | Credit type breakdown (type + amount) |
| `$.adsCredits` | array | Per-credit deduction details |
| `$.shopTraceInfo.clickArea` | int | Click area (shop ads) |

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| id | BIGINT | Transaction record ID | - | - |
| adsid | BIGINT | Ads ID | - | - |
| itemid | BIGINT | Item ID | - | - |
| shopid | BIGINT | Shop ID | - | - |
| operation | INT | Operation type (1=CPC deduct, 11=CPM deduct, 15=CPS deduct, 2-10=topup types) | - | - |
| timestamp | BIGINT | Event timestamp (unix epoch seconds) | - | - |
| client_ip | BIGINT | Client IP (encoded) | - | - |
| userid | BIGINT | User ID | - | - |
| price | BIGINT | Transaction amount (in 10^-5 currency units) | - | - |
| extinfo | STRING | Raw extinfo (base64 encoded binary) | - | - |
| status | INT | Transaction status | - | - |
| acc_before_balance | BIGINT | Account balance before transaction (in 10^-5) | - | - |
| acc_after_balance | BIGINT | Account balance after transaction (in 10^-5) | - | - |
| dai_before_balance | BIGINT | DAI balance before transaction (in 10^-5) | - | - |
| dai_after_balance | BIGINT | DAI balance after transaction (in 10^-5) | - | - |
| deviceid | STRING | Device ID | - | - |
| keyword | STRING | Ads keyword | - | - |
| placement | INT | Placement ID | - | - |
| deduct_unique_id | BIGINT | Unique deduction ID (primary key for dedup) | - | - |
| decoded_extinfo | STRING | Decoded extinfo (JSON string with rich metadata) | - | - |
| originid | BIGINT | Original ID (id changed to originid since 2022-01-01) | - | - |
| acc_user_id | BIGINT | Account user ID (streamer ID for livestream) | - | - |
| account_id | BIGINT | Account ID | - | - |
| grass_date | DATE | [PARTITION] Business date (yyyy-MM-dd) | - | - |

**Note:** `acc_user_id` and `account_id` columns may be present in the actual table schema (observed in production SQL for `__reg_s0_live` variant) but not in the original DDL. Schema is identical to `__reg_s0_live` except only `grass_date` partitioning (no `grass_region` or `tz_type` partitions).
