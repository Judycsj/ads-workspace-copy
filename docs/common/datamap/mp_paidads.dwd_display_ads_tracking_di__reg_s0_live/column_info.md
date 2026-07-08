<!-- ads-workspace-gdoc-sync: gdoc_id=1QZw-Z7G2wIUQhZOPx0tqLU9CSZMQvEjmWhZzKjnOtUk gdoc_url=https://docs.google.com/document/d/1QZw-Z7G2wIUQhZOPx0tqLU9CSZMQvEjmWhZzKjnOtUk/edit -->

# Columns: mp_paidads.dwd_display_ads_tracking_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为事件级明细表，每条记录独立，不存在跨维度的非累加字段。所有聚合均使用标准 SUM(IF(operation=N, 1, 0)) 模式。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | 1 | Impression (展示) |
| operation | 2 | Click (点击) |
| tz_type | local | 当地时间分区 (唯一值) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询使用此值过滤)
- `placement`: 9 (Display Ads Banner — 最常用过滤)
- `grass_region`: 'ID','MY','PH','SG','TH','TW','VN','BR','MX' (9 个市场)
- `ads_id > 0`: 过滤无效 ads (高频使用)
- `user_id > 0`: 过滤匿名用户 (高频使用)
- `ads_id is not null`: JOIN 前过滤
- `operation`: 1 (展示) / 2 (点击)
- `slot_id`: 1, 2, 8, 9, 10 (常用 slot 过滤)
- `banner.source`: 2 (特定广告源)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | 用户ID (from ODS userid) | - | - |
| shop_id | bigint | 店铺ID (from banner.json_data.shop_id) | - | - |
| ads_id | bigint | 广告ID (from banner.bannerid for source 2,4; else from json_data.ads_id) | - | - |
| banner_id | bigint | Banner创意ID (null when source=2) | - | - |
| source | int | 广告来源类型 (from banner.source) | - | - |
| device_id | string | 设备ID | - | - |
| request_id | string | 请求ID (from banner.json_data.request_id) | - | - |
| placement | int | 广告位类型 (原始 ODS 字段) | - | - |
| operation | int | 事件类型: 1=展示, 2=点击 | - | - |
| platform | string | 平台 (iOS/Android) | - | - |
| slot_id | bigint | Banner位ID (from banner.slotid) | - | - |
| session_id | string | 会话ID | - | - |
| client_ip | string | 客户端IP | - | - |
| ab_sign | string | AB实验签名 (from banner.json_data.ab_sign) | - | - |
| event_timestamp | bigint | 事件时间戳 (unix seconds, 原始) | - | - |
| event_datetime | string | 事件时间 (formatted: yyyy-MM-dd HH:mm:ss) | - | - |
| banner | struct | Banner完整信息 (含 banner_id, campaign_unit_id, image_hash, slot_id, source, target_url, json_data) | - | - |
| from_ | string | 来源页面标识 | - | - |
| json_data | string | 原始 JSON 数据 (event-level extra data) | - | - |
| token | string | 会话 token | - | - |
| ads_placement | bigint | 广告位 (from banner.json_data.placement) | - | - |
| ads_entrance | int | 入口标识 (from origin_banner.json_data.entrance) | - | - |
| banner_internal | string | Banner内部元数据 (JSON format) | - | - |
| landing_url_type | string | 落地页类型 | - | - |
| banner_location | string | Banner展示位置 | - | - |
| banner_json_data_tms | string | Banner JSON 数据时间戳 | - | - |
| unique_id | string | Banner 唯一标识 | - | - |
| target_type | string | 广告目标类型 | - | - |
| prefill_keyword | string | 搜索预填关键词 | - | - |
| global_session_id | string | 全局会话ID | - | - |
| referer_type | string | 来源类型 | - | - |
| referer_data | string | 来源数据 | - | - |
| grass_date | date | 分区日期 (当地时间, yyyy-MM-dd) [PARTITION] | - | - |
| grass_region | string | 分区分区键 (大写地区代码, 如 'ID') [PARTITION] | - | - |
| tz_type | string | 时区类型: 'local' [PARTITION] | - | - |
