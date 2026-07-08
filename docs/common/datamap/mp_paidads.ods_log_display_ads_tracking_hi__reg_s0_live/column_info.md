<!-- ads-workspace-gdoc-sync: gdoc_id=1ONtYTAGMiTKzWqimirwi1LKR_Pc0iHI6SjlDE-DJz64 gdoc_url=https://docs.google.com/document/d/1ONtYTAGMiTKzWqimirwi1LKR_Pc0iHI6SjlDE-DJz64/edit -->

# Columns: mp_paidads.ods_log_display_ads_tracking_hi__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为 ODS 埋点日志表，不含计算类累加字段。下游聚合时需注意：

- `unique_id` -- 去重统计时必须用 `COUNT(DISTINCT unique_id)`，直接 COUNT 会因重复上报而偏高
- `banner` / `items` / `shops` / `videos` 等 struct/array 字段 -- 不可直接跨行聚合，需先 lateral view explode 展开

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | 1 | IMPRESSION |
| operation | 2 | CLICK |
| operation | 3 | VIEW |
| operation | 4 | ADD_TO_CART |
| operation | 5 | PLACE_ORDER |
| operation | 6 | CLOSE_BANNER |
| operation | 7 | REPORT_DISLIKE |
| operation | 8 | REPORT_INAPPROPRIATE |
| operation | 9 | REPORT_IRRELEVANT |
| operation | 10 | REPORT_IMPRESSION |
| operation | 1001 | SHOP_IMPRESSION |
| operation | 1002 | SHOP_CLICK |
| platform | 1 | IOS_WEB / rweb_ios |
| platform | 2 | IOS_APP / ios |
| platform | 3 | ANDROID_WEB / rweb_android |
| platform | 4 | ANDROID_APP / android |
| platform | 5 | PC_MALL / pc |
| platform | 6 | IOS_LITE |
| platform | 7 | ANDROID_LITE |
| platform | 8 | PLATFORM_RESERVED |
| platform | 9 | ANDROID_APP_LITE |
| platform | 99 | XIAPI |
| platform | 128 | OTHERS |
| banner.source | 2 | 广告 banner (ads_id = banner.bannerid) |
| banner.source | !=2 | 非广告 banner (banner_id = banner.bannerid) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: in ('ID','MY','PH','SG','TH','TW','VN','BR','MX')
- `grass_date`: 单个日期过滤 `date'YYYY-MM-DD'`
- `h`: `${TODAY_HOUR}` 小时级过滤
- `get_json_object(banner.json_data, '$.entrance') in (5, 60)`: 筛选 banner 类型 tracking
- `get_json_object(banner.json_data, '$.entrance') in (6, 59)`: 另一组 banner 入口
- `operation != 15`: 排除特定操作类型（livestream 场景）
- `get_json_object(banner.json_data, '$.entrance') in (5,60) and if(dre_ver regexp '\\.',regexp_replace(dre_ver,'\\.',''),dre_ver) >= '1780'`: 按版本号过滤 banner 入口
- `get_json_object(banner.dl_json_data,'$.space_group_id') like '6'`: Brand Ads 特定空间组

## All Columns

<!-- ANALYSIS_PLACEHOLDER -->

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| userid | bigint | 用户 ID | - | - |
| sessionid | string | 会话 ID | - | - |
| deviceid | string | 设备 ID | - | - |
| client_ip | string | 客户端 IP | - | - |
| platform | bigint | 平台类型 (1=iOS Web/2=iOS App/3=Android Web/4=Android App/5=PC Mall/...) | - | - |
| operation | bigint | 埋点操作类型 (1=曝光/2=点击/3=浏览/4=加购/5=下单/...) | - | - |
| items | array<struct<...>> | 商品级 tracking 数据数组 (含 itemid, shopid, discount, json_data, unique_id 等) | - | - |
| timestamp | bigint | 客户端时间戳 | - | - |
| country | string | 国家 | - | - |
| token | string | 请求 token | - | - |
| from | string | 来源标识 | - | - |
| shops | array<struct<...>> | 店铺级 tracking 数据数组 (含 shopid, location, json_data, unique_id 等) | - | - |
| placement | bigint | 广告位 ID | - | - |
| json_data | string | 原始 JSON 数据 | - | - |
| fe_ab_sign | string | 前端 AB 实验签名 | - | - |
| internal_label | struct<...> | 内部标签 (含 frauds, sessionid, adsinfo_extract_label, dfp_device_id, risk_tags) | - | - |
| banner | struct<...> | Banner 广告信息 struct (含 bannerid, source, campaign_unitid, slotid, json_data, image_hash, target_url, dl_json_data, unique_id, target_type 等) | - | - |
| app_ver | string | App 版本号 | - | - |
| rn_ver | string | RN 版本号 | - | - |
| entrance | bigint | 入口 ID | - | - |
| view_session_id | string | 浏览会话 ID | - | - |
| sub_entrance | bigint | 子入口 ID | - | - |
| dfp | string | 设备指纹 | - | - |
| vv_id | string | VV ID | - | - |
| sdk_version | string | SDK 版本 | - | - |
| sdk_type | string | SDK 类型 | - | - |
| page_type | string | 页面类型 | - | - |
| page_section | string | 页面区域 | - | - |
| target_type | string | 目标类型 | - | - |
| search_props | struct<...> | 搜索属性 (含 sort_by, scenario, search_entrance, search_mid, search_session_id, global_session_id, prefill_keyword) | - | - |
| video_props | struct<...> | 视频属性 (含 current_page, content_type, content_id, trigger_mode, sv_source_page) | - | - |
| videos | array<struct<...>> | 视频级 tracking 数据数组 (含 video_id, user_id, creator_id, shop_id, ads_id, location, json_data, unique_id, items 等) | - | - |
| version | string | 协议版本 | - | - |
| event_timestamp | bigint | 事件时间戳 | - | - |
| log_timestamp | bigint | 日志服务端接收时间戳 | - | - |
| platform_implementation | string | 平台实现标识 | - | - |
| sequence_id | bigint | 序列号 | - | - |
| tms_session_id | string | TMS 会话 ID | - | - |
| last_view_event_id | string | 上一次浏览事件 ID | - | - |
| domain | string | 域名 | - | - |
| type | string | 类型 | - | - |
| de_device_id | string | DE 设备 ID | - | - |
| exp_version | int | 实验版本 | - | - |
| env | string | 环境标识 | - | - |
| unique_id | string | 事件唯一标识 | - | - |
| dre_ver | string | DRE 版本号 | - | - |
| referer | struct<...> | 引荐来源信息 (含 ads_id, referer_type, track_json_data, referer_data) | - | - |
| livestream_props | struct<...> | 直播属性 (含 ls_session_id, streamer_id, streaming_room_source, if_mini_ls) | - | - |
| conversion_type | int | 转化类型 | - | - |
| grass_region | string | [PARTITION] 区域 (MY/SG/TH/ID/VN/PH/TW/BR/MX) | - | - |
| grass_date | date | [PARTITION] 日期分区 | - | - |
| h | int | [PARTITION] 小时分区 | - | - |
