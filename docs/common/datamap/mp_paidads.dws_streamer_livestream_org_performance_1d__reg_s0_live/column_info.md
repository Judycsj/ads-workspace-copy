<!-- ads-workspace-gdoc-sync: gdoc_id=1PQfOgNqr7Aa9CFHhF5g8vzn9QauggLJit2JsxGmAa40 gdoc_url=https://docs.google.com/document/d/1PQfOgNqr7Aa9CFHhF5g8vzn9QauggLJit2JsxGmAa40/edit -->

# Columns: mp_paidads.dws_streamer_livestream_org_performance_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

跨 streamer_id 聚合时必须用 MAX 或 COUNT(DISTINCT)：
- `dau`, `rcmd_dau`, `rcmd_ads_dau` -- 单日去重 UV 指标。从 viewer detail 和 impression 表按 streamer × user 去重后计算，直接 SUM 会重复计数同一用户。

### 枚举值映射 (Value Mappings)

未在代码库中找到 2+ 文件出现的枚举映射模式。

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (所有查询统一使用)
- `grass_region`: 'ID','MY','PH','SG','TH','TW','VN' (标准区域，每个区域一个独立调度任务)
- `grass_date`: 单日 `DATE('${grass_date}')`，或范围查询 `date_sub(DATE('${grass_date}'),6)` ~ `DATE('${grass_date}')`（近7天）
- `gmv_rcmd_usd > 0`: 用于过滤计算 streamer GMV 分位排名

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| streamer_id | bigint | - | - | - |
| streamer_type | int | - | - | - |
| shop_id | bigint | - | - | - |
| view_total_cnt | bigint | - | - | - |
| view_rcmd_cnt | bigint | - | - | - |
| view_rcmd_ads_cnt | bigint | - | - | - |
| time_total_cnt | bigint | - | - | - |
| time_rcmd_cnt | bigint | - | - | - |
| time_rcmd_ads_cnt | bigint | - | - | - |
| order_total_cnt | bigint | - | - | - |
| order_rcmd_cnt | bigint | - | - | - |
| order_rcmd_ads_cnt | bigint | - | - | - |
| gmv_total_usd | double | - | - | - |
| gmv_rcmd_usd | double | - | - | - |
| gmv_rcmd_ads_usd | double | - | - | - |
| gmv_total_local | double | - | - | - |
| org_imp_cnt | bigint | - | - | - |
| org_rcmd_imp_cnt | bigint | - | - | - |
| org_rcmd_ads_imp_cnt | bigint | - | - | - |
| org_click_cnt | bigint | - | - | - |
| org_rcmd_click_cnt | bigint | - | - | - |
| org_rcmd_ads_click_cnt | double | - | - | - |
| dau | bigint | - | - | - |
| rcmd_dau | bigint | - | - | - |
| rcmd_ads_dau | bigint | - | - | - |
| tz_type [PARTITION] | string | - | - | - |
| grass_region [PARTITION] | string | - | - | - |
| grass_date [PARTITION] | DATE | - | - | - |
