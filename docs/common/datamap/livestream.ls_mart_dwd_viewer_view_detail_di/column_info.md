<!-- ads-workspace-gdoc-sync: gdoc_id=1snxS5aig_h99A5zCV8FXHaNSdaewKdA1jrMksWRNn3I gdoc_url=https://docs.google.com/document/d/1snxS5aig_h99A5zCV8FXHaNSdaewKdA1jrMksWRNn3I/edit -->

# Columns: livestream.ls_mart_dwd_viewer_view_detail_di

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为 event-level 明细表，每行代表一次独立观看事件。直接 `COUNT(1)` 即可获得正确计数。跨场景/主播聚合时注意：
- `user_id` — 计算 UV/DAU 需用 `COUNT(DISTINCT user_id)` 去重
- `streamer_id` — 计算主播数需用 `COUNT(DISTINCT streamer_id)`

### 枚举值映射 (Value Mappings)

#### scene (场景)

| Column | Value | Meaning |
|--------|-------|---------|
| scene | `''`, `non`, `livestream_pdp` | 非推荐场景 (需要排除) |
| scene | `livestream_game` | 直播游戏场景 (需要排除) |
| scene | `slide` | 全屏滑动模式 |
| scene | `livestream_home_landing` | 直播首页落地 |
| scene | `livestream_default_tab` | 自动落地 |
| scene | `livestream_fullscreen` | 全屏模式 |
| scene | `livestream_animation` | 动画模式 |
| scene | `livestream_video_trending` | 视频 trend 页 |
| scene | `livestream_video_dd` | 视频 dd 页 |
| scene | `livestream_video_home` | 视频首页 |

#### data.recommendation_info (推荐渠道)

| Column | Pattern | Meaning |
|--------|---------|---------|
| data.recommendation_info | `%CHAN:ADS%` | 广告推荐渠道 |
| data.recommendation_info | `%dispatch:ads%` | 广告分发渠道 |
| data.recommendation_info | `%QUE:ADS%` | 广告队列 (PDP) |
| data.recommendation_info | `%QUE%3AADS%` | 广告队列 URL 编码 (PDP) |
| data.recommendation_info | `%STREAM-SUPPORT-VIEW%` | 直播扶持/加推 |
| data.recommendation_info | `%STREAM-SUPPORT%` | 直播扶持 |
| data.recommendation_info | `%STREAM-ALLTAB-P2TOP%` | AllTab 置顶 |
| data.recommendation_info | `%STREAM-HOME-P2TOP%` | 首页置顶 |
| data.recommendation_info | `%STREAM-FULLSCREEN-P2TOP%` | 全屏置顶 |
| data.recommendation_info | `%STREAM-SLIDING-KOL-SPT-NEW%` | KOL 滑动推荐 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: `'local'` (100% 的查询使用)
- `grass_region`: `'ID','VN','TH','MY','PH','TW','SG'` (标准 7 区)
- `grass_date`: 通常取 `${biz_date}` 到 `${biz_date_substract_6}` 之间的 7 天范围
- `user_id > 0` (排除无效用户，100% 查询使用)
- `user_id IS NOT NULL` (排除空用户)
- Scene 排除子句: `scene NOT IN ('','non','livestream_pdp','livestream_game')` — 用于限定推荐场景

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | DATE | 分区字段：数据日期 | - | - |
| grass_region | STRING | 分区字段：区域/国家 | - | - |
| tz_type | STRING | 分区字段：时区类型 ('local') | - | - |
| ls_session_id | BIGINT | 直播场次 session ID | - | - |
| user_id | BIGINT | 观看用户 ID | - | - |
| streamer_id | BIGINT | 主播 ID | - | - |
| event_id | BIGINT | 观看事件 ID | - | - |
| event_time | STRING | 事件发生时间 (from take_rate_temp_query) | - | - |
| event_timestamp | BIGINT | 事件时间戳 (毫秒，需 /1000 转为秒) | - | - |
| data | STRING | JSON 格式的扩展数据，含 $.from_source 和 $.recommendation_info | - | - |
| scene | STRING | 观看场景/页面类型 | - | - |
