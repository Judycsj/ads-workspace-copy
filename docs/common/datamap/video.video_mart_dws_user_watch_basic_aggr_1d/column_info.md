<!-- ads-workspace-gdoc-sync: gdoc_id=1po5_u7kfqyx6syY8795NeV500X-0oiDFYuSKsQCc4SY gdoc_url=https://docs.google.com/document/d/1po5_u7kfqyx6syY8795NeV500X-0oiDFYuSKsQCc4SY/edit -->

# Columns: video.video_mart_dws_user_watch_basic_aggr_1d

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

`video_play_cnt_ntl_1d` 需要在用户级别去重后聚合（先 `MAX(video_play_cnt_ntl_1d) GROUP BY video_id, user_id, grass_date`，再外层 `SUM`），不能直接跨 user_id 维度 SUM。

### 枚举值映射 (Value Mappings)

`entry_point` 通过 CASE-WHEN 从 `sv_source_page` + `current_page` + `video_flow_type` + `content_type` 派生：

| Source Columns | Condition | entry_point Value |
|--------|-------|---------|
| sv_source_page | iaa_dd_video_card | DD Internal Video |
| sv_source_page | home_video_module | HP Internal Video |
| sv_source_page | video_tab | Video Trending Tab |
| sv_source_page | iaa_srp_video_card | SRP Internal Video |
| sv_source_page | iaa_dd_mix_item | Daily Discover Mix Feed Video Internal |
| sv_source_page | iaa_ymal_video_card | YMAL_FEED_VIDEO_ADS |

> 注：上表为简化版，实际 CASE 条件还包含 current_page / video_flow_type / content_type 组合判断。

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID' (多见于 Content Ads / Search Ads 场景) / `upper('${region}')` (参数化查询)
- `grass_date`: `date('${grass_date}')` (单日) / `date('${DAYS_AGO_N}')` (相对日期)
- `tz_type`: 'local' (几乎 100% 的查询)
- `content_type`: 'shopee_video' (过滤只取电商视频内容)
- `video_play_cnt_ntl_1d`: > 0 (过滤无播放记录)
- `video_view_duration_ntl_1d`: > 0 (过滤无观看时长)
- `user_id`: > 0 (排除未登录用户)

## All Columns

> 列信息基于 from-code SQL 推理，未包含 DDL。运行 `--source from-di` 可补充完整列清单、description、query frequency 和 MAX 采样。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | string | 数据日期分区 | - | - |
| grass_region | string | 地域分区 | - | - |
| user_id | bigint | 用户 ID | - | - |
| video_id | bigint | 视频 ID | - | - |
| content_type | string | 内容类型（如 shopee_video） | - | - |
| tz_type | string | 时区类型（local/regional） | - | - |
| sv_source_page | string | 视频来源页面 | - | - |
| current_page | string | 当前所在页面 | - | - |
| video_flow_type | string | 视频流量类型（internal/external） | - | - |
| video_play_cnt_ntl_1d | bigint | 当日视频播放次数（⚠ 非累加） | - | - |
| video_view_duration_ntl_1d | bigint | 当日视频观看时长 | - | - |
| is_item_ads | int | 是否为商品广告 | - | - |
| video_ads_type | string | 视频广告类型（product_ads/video_ads） | - | - |
