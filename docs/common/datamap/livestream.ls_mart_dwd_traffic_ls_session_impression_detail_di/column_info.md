<!-- ads-workspace-gdoc-sync: gdoc_id=14oNVEfXJVkVSXNhF1RCRSil8So6XLQaP89ObvzTJhC0 gdoc_url=https://docs.google.com/document/d/14oNVEfXJVkVSXNhF1RCRSil8So6XLQaP89ObvzTJhC0/edit -->

# Columns: livestream.ls_mart_dwd_traffic_ls_session_impression_detail_di

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

暂无 SUM(DISTINCT) 模式识别到的非累加字段。该表为事件级明细表，count(1) 即为曝光次数。

### 枚举值映射 (Value Mappings)

#### page_type

| Value | Meaning |
|-------|---------|
| live_landing | 直播落地页 |
| live_explore | 直播发现页 |
| home | 首页 |
| product | 商品详情页 (PDP) |
| content_mix_discover | 内容混合发现页 |

#### page_section[0]

| Value | Meaning |
|-------|---------|
| live_now | 直播"正在直播"tab |
| shopee_live | 首页 shopee_live 模块 |
| streamer_recommend | 直播 landing 页推荐主播 |
| daily_discover | 首页 daily_discover 模块 |
| live_video_merge_module | 首页视频混合模块 |
| cover_feed | 内容混合发现页 cover_feed |

#### target_type

| Value | Meaning |
|-------|---------|
| streaming | 直播间卡片（tab 内） |
| live_banner | 直播横幅（首页） |
| streamer_icon | 主播图标（landing 页） |
| livestream | 直播卡片（daily_discover） |
| live_card | 直播卡片（首页视频混合模块） |
| live_stream_floating_preview | 直播浮动预览（PDP） |
| streaming_card | 直播卡片（内容混合发现页） |

#### operation

| Value | Meaning |
|-------|---------|
| impression | 曝光事件（本表仅用于 impression） |

### 常见 WHERE 值 (Common Filter Values)

- **tz_type**: 'local' (所有查询)
- **grass_region**: 'ID','VN','TH','MY','PH','TW','SG' (标准 7 区, 有时仅部分)
- **operation**: 'impression' (always, 区别于 click 表)
- **user_id**: != 0 AND IS NOT NULL (所有 workflow), > 0 (manual_tasks)
- **page_type**: 'live_landing','live_explore','home' (workflows); 另含 'product','content_mix_discover' (manual_tasks)
- **page_section[0]**: 'live_now','shopee_live','streamer_recommend','daily_discover' (workflows); 另含 'live_video_merge_module','cover_feed' (manual_tasks)
- **target_type**: 'streaming','live_banner','streamer_icon','livestream' (workflows); 另含 'live_card','live_stream_floating_preview','streaming_card' (manual_tasks)

### JSON 字段说明 (data column)

`data` 列为 JSON 格式，常用提取：

| JSON Path | 用途 | 示例值 |
|-----------|------|--------|
| `$.recommendation_info` | 推荐/广告渠道标识 | `%CHAN:ADS%`, `%dispatch:ads%` |
| `$.ls_track_id` | 直播跟踪 ID（含广告标识） | `%QUE:ADS%`, `%QUE%3AADS%` |
| `$.type` | 内容类型 | `live_ongoing` |
| `$.from_source` | 来源入口（仅 view 表使用，impression 表未直接使用） | - |
| `RNKMOD:` (regexp) | 推荐模型分值串，包含 ctr/cvr/wd_10/wd_30/wd_60/aov 等 | `ctr=0.05\|cvr=0.01\|wd_10=0.1\|...` |
| `BND:` (regexp) | 模型版本标识 | `livestream_v1` |

## All Columns

> **Note**: DDL 未在代码库中找到，以下列为从 SQL 使用中推断。运行 `--source from-di` 可补充完整的列列表和 description。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| tz_type | string (PARTITION) | 时区类型 | - | - |
| grass_region | string (PARTITION) | 地区 | - | - |
| grass_date | DATE (PARTITION) | 数据日期 | - | - |
| streamer_id | bigint | 主播 ID | - | - |
| user_id | bigint | 用户 ID | - | - |
| ls_session_id | bigint | 直播 session ID | - | - |
| page_type | string | 页面类型 | - | - |
| page_section | array\<string\> | 页面区块（取 [0] 为主） | - | - |
| target_type | string | 目标类型（卡片/横幅/图标等） | - | - |
| operation | string | 事件类型（impression） | - | - |
| data | string (JSON) | 事件附加数据（recommendation_info, ls_track_id, type 等） | - | - |
