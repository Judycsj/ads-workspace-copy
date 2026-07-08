<!-- ads-workspace-gdoc-sync: gdoc_id=1omjis9236qyx_yWPwgSIGcZlftt2SQyfdI_43u0EKaw gdoc_url=https://docs.google.com/document/d/1omjis9236qyx_yWPwgSIGcZlftt2SQyfdI_43u0EKaw/edit -->

# Columns: mp_paidads.dws_advertiser_account_td__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

该表所有余额字段均为快照值，表示最新可用余额，**不可直接 SUM 跨 shop_id 聚合**。各 shop 的 balance 独立计算，跨 shop 聚合无业务意义：

- `acc_before_balance`, `acc_before_balance_usd` — 扣费前余额快照
- `acc_after_balance`, `acc_after_balance_usd` — 扣费后余额快照
- `low_threshold`, `low_threshold_usd` — 低余额告警阈值

如需跨维度聚合，应使用下游表 `ads_advertiser_mkt_1d__reg_s0_live` 或上游日表 `dws_advertiser_account_1d__reg_s0_live`。

### 枚举值映射 (Value Mappings)

从代码库未发现对该表字段的 CASE-WHEN 枚举映射。`is_reach_threshold` 字段说明：

| Column | Value | Meaning |
|--------|-------|---------|
| is_reach_threshold | 0 | 当日未触发低余额告警 |
| is_reach_threshold | 1 | 当日曾触发低余额告警 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 8 标准区 ('ID','MY','PH','SG','TH','TW','VN','BR') + MX/CO/CL（US local 场景）
- `tz_type`: 'local'（当前代码库中所有引用均为 local tz_type）
- `grass_date`: 按日分区，下游消费取当日分区 `grass_date = DATE('${grass_date}')`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | BIGINT | userid | - | - |
| shop_id | BIGINT | shopid | - | - |
| acc_before_balance | DOUBLE | the balance remains when acc before in local currency | - | - |
| acc_before_balance_usd | DOUBLE | the balance remains when acc before in usd currency | - | - |
| acc_after_balance | DOUBLE | the balance remains when acc after in local currency | - | - |
| acc_after_balance_usd | DOUBLE | the balance remains when acc after in usd currency | - | - |
| low_threshold | DOUBLE | low threshold in local | - | - |
| low_threshold_usd | DOUBLE | low threshold in usd | - | - |
| is_reach_threshold | TINYINT | ever reached today then will be set to 1 else 0 | - | - |
| grass_date | DATE | 分区列 - 数据日期 | - | - |
| tz_type | STRING | 分区列 - 时区类型 (local) | - | - |
| grass_region | STRING | 分区列 - 地区 | - | - |
