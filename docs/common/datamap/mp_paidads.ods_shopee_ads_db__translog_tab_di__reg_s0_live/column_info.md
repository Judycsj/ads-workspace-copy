<!-- ads-workspace-gdoc-sync: gdoc_id=1TzKCbxj2R8ftogmaoILphA-7ykj5F2us-4hKaxdSuuk gdoc_url=https://docs.google.com/document/d/1TzKCbxj2R8ftogmaoILphA-7ykj5F2us-4hKaxdSuuk/edit -->

# Columns: mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无明显 SUM(DISTINCT) 模式 -- 此表为事务级明细表，通常不直接聚合，而是作为 DWD 层的数据源。

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
| tz_type | 'local' | Local timezone (used in ~100% of queries) |
| tz_type | 'regional' | Regional timezone (rarely used for this table) |
| extinfo: $.pricingType | 9,10,14 | Live Ads |
| extinfo: $.pricingType | 19 | Live Ads (extended) |
| extinfo: $.pricingType | 22 | Live Ads (extended) |
| extinfo: $.pricingType | 20 | CPS |
| extinfo: $.paidFreeExpirySummary.entries.type | 1 | Paid credit without expiry |
| extinfo: $.paidFreeExpirySummary.entries.type | 2 | Paid credit with expiry |
| extinfo: $.paidFreeExpirySummary.entries.type | 3 | Free credit without expiry |
| extinfo: $.paidFreeExpirySummary.entries.type | 4 | Free credit with expiry |
| extinfo: $.adsCredits.mainType | 2 | Paid credit |
| extinfo: $.adsCredits.mainType | 3 | Free credit |
| extinfo: $.adsCredits.mainType | 5 | Mixed credit |
| extinfo: $.adsCredits.orderType | 19 | Rebate free credit |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~100% of queries on this table)
- `operation`: `in (1, 11, 15)` (deduction events -- CPC/CPM/CPS), `= 11` (CPM only), `in (1, 15)` (CPC/CPS only)
- `grass_region`: Standard regions -- 'ID','MY','PH','SG','TH','TW','VN','BR','MX','AR','CL','CO'
- `grass_date`: Always filtered by specific date, e.g. `= date('${grass_date}')`
- `keyword`: `!= 'system_dummy_negative_deduction'` (exclude system dummy records)
- `extinfo: $.pricingType`: `in (9,10,14,19,22)` (Live Ads pricing types)

### decoded_extinfo JSON 关键字段

`decoded_extinfo` 是一个 JSON 字符串，通过 `get_json_object()` 提取。下游常用字段：

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
| `$.targetAffiliateUserId` | bigint | Target affiliate user ID |
| `$.batchCnt` | bigint | Batch count (CPM impression count) |
| `$.orderId` | bigint | Order ID (CPS) |
| `$.orderItemId` | bigint | Order item ID (CPS) |
| `$.expectDeductPrice` | bigint | Expected deduction price |
| `$.deductionInfo.quality` | double | PCTR (predicted click-through rate) |
| `$.deductionInfo.bidprice` | bigint | Bid price |
| `$.deductionInfo.nextScore` | double | Second ads eCPM |
| `$.deductionInfo.nextAdsid` | bigint | Second ads ID |
| `$.deductionInfo.algoName` | string | AB sign / algorithm name |
| `$.deductionInfo.deductionPrice` | bigint | Deduction price (in 10^-5) |
| `$.voucherDeductionPrice` | bigint | Voucher deduction price (in 10^-5) |
| `$.cpsTotalExpense` | bigint | CPS total expenditure |
| `$.cpsAvailableBudget` | bigint | CPS available budget |
| `$.validBalance` | bigint | Valid balance |
| `$.availableBalance` | bigint | Available balance |
| `$.query.keyword` | string | User search query keyword |
| `$.query.sorttype` | int | Search sort type |
| `$.query.itemid` | bigint | PDP item ID |
| `$.query.shopid` | bigint | PDP shop ID |
| `$.paidFreeExpirySummary.entries` | array | Credit type breakdown (type + amount) |
| `$.adsCredits` | array | Per-credit deduction details |
| `$.frozen.adsCredits` | array | Frozen credit deduction details |
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
| tz_type | STRING | [PARTITION] Timezone type ('local' / 'regional') | - | - |
| grass_region | STRING | [PARTITION] Region code (e.g. 'SG', 'ID', 'VN') | - | - |
| grass_date | DATE | [PARTITION] Business date (yyyy-MM-dd) | - | - |

**Note:** `acc_user_id` and `account_id` columns are present in the actual table schema (observed in production SQL) but not in the original DDL. They were likely added via ALTER TABLE.
