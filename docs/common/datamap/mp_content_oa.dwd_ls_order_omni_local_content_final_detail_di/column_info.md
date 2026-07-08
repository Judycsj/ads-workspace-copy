<!-- ads-workspace-gdoc-sync: gdoc_id=1AuBCO1T4WmTrfHeSoZtESPgM7uFwauZ2BxeL1J0zUSg gdoc_url=https://docs.google.com/document/d/1AuBCO1T4WmTrfHeSoZtESPgM7uFwauZ2BxeL1J0zUSg/edit -->

# Columns: mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

from-code 提取自 4 个读引用文件（一致模式）：

- `tz_type`: 'local' (100% 查询)
- `from_source_page`: 'streaming_room' (Live Streaming 来源页面)
- `is_content_directly_related`: 1 (直接内容相关订单)
- `order_cal_type`: 'direct' (用于直播广告归因) / 'indirect' (间接归因)
- `order_other_supply`: 'omni'
- `grass_date`: date('${grass_date}') 或 between ${biz_date_substract_6} and ${biz_date}

### 非累加字段 (Non-Additive Fields)

from-code 分析：未在代码库中识别到 SUM(DISTINCT) 模式。该表为 order-level 明细表，指标字段在 order_id 粒度上直接可累加。

## All Columns

> DDL 未在 paidads-alg 代码库中找到。以下列名为 from-code 从 SQL 引用中提取的字段列表。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | - | 分区日期 | - | - |
| grass_region | - | 区域 (ID/MY/PH/SG/TH/TW/VN/BR) | - | - |
| tz_type | - | 时区类型 (local/regional) | - | - |
| order_id | - | 订单 ID | - | - |
| order_platform | - | 订单平台 | - | - |
| app_version | - | App 版本 | - | - |
| order_item_id | - | 订单商品 ID | - | - |
| order_buyer_id | - | 买家 ID | - | - |
| order_shop_id | - | 订单店铺 ID | - | - |
| order_cal_type | - | 归因计算类型 (direct/indirect) | - | - |
| order_other_supply | - | 其他供给来源 (omni) | - | - |
| ls_order_fraction | - | 直播订单份额 | - | - |
| item_amount | - | 商品数量 | - | - |
| gmv | - | GMV (本币) | - | - |
| gmv_usd | - | GMV (美元) | - | - |
| from_source_page | - | 来源页面 (如 streaming_room) | - | - |
| is_content_directly_related | - | 是否内容直接相关 (0/1) | - | - |
| order_ls_streamer_id | - | 直播主播 ID | - | - |
| order_ls_session_id | - | 直播会话 ID | - | - |
| streamer_shop_id | - | 主播店铺 ID | - | - |
| seller_shop_id | - | 卖家店铺 ID | - | - |
| entry_point | - | 入口点 | - | - |
| scene | - | 场景 | - | - |
| ls_view_data | - | 直播观看数据 (JSON) | - | - |
| total_ls_order_fraction | - | 总直播订单份额 | - | - |
