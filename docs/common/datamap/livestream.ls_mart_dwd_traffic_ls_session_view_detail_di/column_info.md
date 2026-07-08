<!-- ads-workspace-gdoc-sync: gdoc_id=1PaLxFPQhsfxoI3H0Nooa2iJPGRvgfFKSsiJlsY8vnO0 gdoc_url=https://docs.google.com/document/d/1PaLxFPQhsfxoI3H0Nooa2iJPGRvgfFKSsiJlsY8vnO0/edit -->

# Columns: livestream.ls_mart_dwd_traffic_ls_session_view_detail_di

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为事件级别明细表，每条记录代表一次用户操作。聚合时需注意：
- `event_id` — 唯一事件ID，跨维度去重计数必须用 COUNT(DISTINCT event_id)
- 下游 view/click 指标聚合使用 COUNT(DISTINCT CASE WHEN ... THEN event_id END)

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| page_type | streaming_room | 直播间页面 |
| operation | view | 浏览/曝光 |
| operation | click | 点击 |
| tz_type | local | 本地时区 |
| scene | livestream_fullscreen | 直播全屏 |
| scene | slide | 滑动 |
| scene | livestream_v1 | 直播V1 |
| scene | livestream_default_tab | 直播默认Tab |
| scene | livestream_home | 直播首页 |
| scene | livestream_topscroll | 直播顶部滑动 |
| scene | livestream_dd | 直播DD |
| scene | pnar | PNAR |
| scene | livestream_endpage | 直播结束页 |
| scene | livestream_ymal | 直播YMAL |
| scene | livestream_animation | 直播动画 |
| scene | livestream_video_trending | 直播视频热门 |
| scene | livestream_sliding_search | 直播滑动搜索 |
| scene | livestream_video_home | 直播视频首页 |
| scene | livestream_video_dd | 直播视频DD |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询使用 local 时区)
- `grass_region`: 'ID' (CVR模型训练) / upper('${region}') (全量归因)
- `operation`: 'view' (所有查询均过滤 view 事件)
- `page_type`: 'streaming_room' (所有查询均限制直播间页面)
- `user_id`: `<> 0` 或 `is not null` 或 `> 0` (排除无效用户)

## All Columns

*DDL 未在代码库中找到。以下列从 SQL 引用推断。运行 from-di 可补充完整列清单及 description/query frequency/MAX。*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | string | 分区日期 | - | - |
| grass_region | string | 分区区域 | - | - |
| tz_type | string | 时区类型 | - | - |
| user_id | bigint | 用户ID | - | - |
| ls_session_id | int/string | 直播会话ID | - | - |
| streamer_id | int/string | 主播ID | - | - |
| shop_id | int/string | 店铺ID | - | - |
| event_id | string | 事件ID | - | - |
| operation | string | 操作类型 (view/click) | - | - |
| page_type | string | 页面类型 | - | - |
| scene | string | 场景来源 | - | - |
| target_type | string | 目标类型 | - | - |
| page_section | array<string> | 页面区域 | - | - |
| data | string | 原始数据字段 (含 REQID/RNKMOD/ADSRNKMOD/CHAN) | - | - |
| platform | string | 平台 | - | - |
| app_version | string | App版本 | - | - |
| log_time | timestamp | 日志时间 | - | - |
