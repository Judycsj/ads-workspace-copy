<!-- ads-workspace-gdoc-sync: gdoc_id=1k8aXbzXrTu78arFQY0ld4klsZYtY5rP1dZbvszZdvrY gdoc_url=https://docs.google.com/document/d/1k8aXbzXrTu78arFQY0ld4klsZYtY5rP1dZbvszZdvrY/edit -->

# Columns: mp_paidads.dim_streamer_new_old_tag__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为维度表，以下字段跨维度聚合时不可直接 SUM：
- `today_new_advertiser_status`、`month_new_advertiser_status`、`new_ls_streamer_status` -- 状态标签字段，跨 streamer 聚合时使用 COUNT(DISTINCT streamer_id) 统计数量
- `advertiser_gmv_tier`、`advertiser_ls_gmv_tier`、`advertiser_rev_tier` -- 分层标签字段，使用 MAX() 或按分层 GROUP BY 后 COUNT(DISTINCT)
- `is_streaming_today`、`is_rev_today` -- 0/1 标识，跨 streamer 聚合时使用 SUM() 统计当日活跃数

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| today_new_advertiser_status | 0 | 老广告主（过去 365 天有投广收入） |
| today_new_advertiser_status | 1 | 当日新广告主（过去 365 天无投广，当日有） |
| today_new_advertiser_status | Not Applicable Today | 当日无投广收入 |
| month_new_advertiser_status | 0 | 当月老广告主（上月和当月均有投广） |
| month_new_advertiser_status | 1 | 当月新广告主（过去 12 月有投广但上月无、当月有） |
| month_new_advertiser_status | 2 | 全新广告主（过去 12 月均无投广、当月有） |
| month_new_advertiser_status | 3 | 当月无投广收入 |
| new_ls_streamer_status | 0 | 当日新开播（当日开播，过去 90 天未开播） |
| new_ls_streamer_status | 1 | 当月有开播 |
| new_ls_streamer_status | 2 | 当月未开播 |
| advertiser_gmv_tier | large_seller | GMV >= 25000 USD/30d |
| advertiser_gmv_tier | medium_seller | GMV 10000-25000 USD/30d |
| advertiser_gmv_tier | small_seller | GMV 5000-10000 USD/30d |
| advertiser_gmv_tier | micro seller | GMV < 5000 USD/30d |
| advertiser_ls_gmv_tier | Top 1% | 直播 GMV 排名前 1% |
| advertiser_ls_gmv_tier | Top 5% | 直播 GMV 排名 1%-5% |
| advertiser_ls_gmv_tier | Top 10% | 直播 GMV 排名 5%-10% |
| advertiser_ls_gmv_tier | Top 20% | 直播 GMV 排名 10%-20% |
| advertiser_ls_gmv_tier | Top 30% | 直播 GMV 排名 20%-30% |
| advertiser_ls_gmv_tier | Top 40% | 直播 GMV 排名 30%-40% |
| advertiser_ls_gmv_tier | Top 50% | 直播 GMV 排名 40%-50% |
| advertiser_ls_gmv_tier | Other | 直播 GMV 排名 50% 以后 |
| advertiser_rev_tier | 1% percentile | 投广收入排名 top 1% |
| advertiser_rev_tier | 10% percentile | 投广收入排名 1%-10% |
| advertiser_rev_tier | 25% percentile | 投广收入排名 10%-25% |
| advertiser_rev_tier | 50% percentile | 投广收入排名 25%-50% |
| advertiser_rev_tier | 75% percentile | 投广收入排名 50%-75% |
| advertiser_rev_tier | Other | 投广收入排名 75% 以后 |
| tz_type | local | 所有查询均使用 local 时区 |
| is_streaming_today | 0 | 当日未开播 |
| is_streaming_today | 1 | 当日有开播 |
| is_rev_today | 0 | 当日无投广收入 |
| is_rev_today | 1 | 当日有投广收入 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询)
- `grass_region`: 标准 7 区 ('ID','MY','PH','SG','TH','TW','VN')，使用 `upper('${region}')` 格式
- `shop_id is not null`: 过滤无效店铺（下游 JOIN 条件）
- `streamer_id is not null`: 过滤无效直播主（下游 GROUP BY 条件）
- Date range (14-day rolling): `grass_date >= date_sub(DATE('${grass_date}'), 13) AND grass_date <= DATE('${grass_date}')`
- Date range (7-day look-ahead): `grass_date > DATE('${grass_date}') AND grass_date <= date_add(DATE('${grass_date}'), 7)`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| streamer_id | bigint | 直播主 ID | - | - |
| streamer_type | int | 直播主类型 | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| shop_level1_global_be_category | string | 店铺一级 BE 品类 | - | - |
| shop_level2_global_be_category | string | 店铺二级 BE 品类 | - | - |
| today_new_advertiser_status | int | 当日新广告主状态 (0=老/1=新) | - | - |
| month_new_advertiser_status | int | 当月新广告主状态 (0=老/1=新/2=全新/3=无收入) | - | - |
| new_ls_streamer_status | int | 新直播主状态 (0=当日新开播/1=当月有开播/2=当月未开播) | - | - |
| advertiser_gmv_tier | string | 广告主 GMV 分层 | - | - |
| advertiser_ls_gmv_tier | string | 广告主直播 GMV 分层（按直播 GMV 分位数） | - | - |
| advertiser_rev_tier | string | 广告主投广收入分层（按收入分位数） | - | - |
| streamer_first_streaming_date | string | 首次开播日期 | - | - |
| streamer_last_streaming_date | string | 最近开播日期 | - | - |
| streamer_first_live_ads_date | string | 首次投直播广告日期 | - | - |
| streamer_last_live_ads_date | string | 最近投直播广告日期 | - | - |
| is_streaming_today | tinyint | 当日是否开播 (0/1) | - | - |
| is_rev_today | tinyint | 当日是否有投广收入 (0/1) | - | - |
| tz_type | string | 时区类型 [PARTITION] | - | - |
| grass_region | string | 地域 [PARTITION] | - | - |
| grass_date | date | 数据日期 [PARTITION] | - | - |
