<!-- ads-workspace-gdoc-sync: gdoc_id=1sCzDAyUGzZoOvQgbOojrQWDvvR0c-LCEJpf_4aLkcN4 gdoc_url=https://docs.google.com/document/d/1sCzDAyUGzZoOvQgbOojrQWDvvR0c-LCEJpf_4aLkcN4/edit -->

# Columns: mp_paidads.dim_campaign_days_1y__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| campaign_type | 1 | Palindrome date (01-01, 02-02, ..., 12-12) — applies to all 9 regions (ID/MY/SG/TH/VN/TW/PH/BR/MX) |
| campaign_type | 2 | Day 1 of month — region ID only |
| campaign_type | 3 | Day 15 of month — regions MY/PH/SG/TH/VN |
| campaign_type | 4 | Day 18 of month — region TW only |
| campaign_type | 5 | Day 25 of month — regions ID/MY/SG/TH/VN/TW |
| campaign_type | 6 | Day 30 of month — region PH only |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: Always filtered to a single upper-case region code — `upper('${region}')` or `'${region}'` (100% of queries)
- `campaign_day`:
  - `>= date('${NEXT_2D}')` for upcoming campaign day detection
  - `<= date('${BIZ_YESTERDAY}')` for historical campaign days
  - LEFT JOIN with `campaign_date is null` to exclude campaign days from analysis windows

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_region | string | Region code (ID, MY, PH, SG, TH, VN, TW, BR, MX) | - | - |
| campaign_day | date | Calendar date of the campaign day | - | - |
| campaign_type | tinyint | Campaign schedule type (1-6), see value mapping above | - | - |
