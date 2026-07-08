<!-- ads-workspace-gdoc-sync: gdoc_id=1m4Xxgyo2KSTGhOuTOOSs3UOadDcdQGhlIdd7emd5IC4 gdoc_url=https://docs.google.com/document/d/1m4Xxgyo2KSTGhOuTOOSs3UOadDcdQGhlIdd7emd5IC4/edit -->

# Columns: mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段跨事件/广告维度聚合时需注意：
- `internal.deduction_info.deduction_price` — 使用 row_number() 按 (grass_region, grass_date, ads_entrance, ads_id, shop_id, ads_request_id, campaign_id, ads_placement, timestamp) partition + order by deduction_price desc 取 rn=1 去重
- `item_voucher.display_ads_voucher_label` — voucher 展示标签，按 ads_id 去重后使用
- `item_json_data` 中的预估字段 (pCTR, pCR, pCVR) — 同一 ads_request_id+ads_id 下多 item 时需用 MAX 聚合后使用

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | 1 | Impression |
| operation | 2 | Click |
| operation | 3 | View |
| operation | 4 | ADD_TO_CART |
| operation | 5 | PLACE_ORDER |
| operation | 1001 | SHOP_IMPRESSION |
| operation | 1002 | SHOP_CLICK |
| platform | 1 | ios_web |
| platform | 2 | ios_app |
| platform | 3 | android_web |
| platform | 4 | android_app |
| platform | 5 | pc_web |
| platform | 6 | ios_lite |
| platform | 7 | android_lite |
| platform | 9 | android_app_lite |
| platform | 99 | XIAPI |
| platform | 128 | OTHERS |

### Placement 派生逻辑

代码库中常见的 placement 归一化逻辑：
```sql
CASE
    WHEN tracking_placement IN (0, 1, 2, 3, 5) THEN coalesce(ads_placement, tracking_placement)
    ELSE coalesce(tracking_placement, 0)
END AS placement
```

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 8 区 ('ID', 'MY', 'PH', 'SG', 'TH', 'TW', 'VN', 'BR')，部分地区扩展含 'MX', 'CO', 'CL'
- `operation`: 1 (Impression), 2 (Click) 是最常见的过滤条件
- `ads_id > 0` — 过滤非广告流量
- `user_id > 0` — 过滤无效用户
- `item_id > 0` — 过滤无效商品
- `fraud_type is null or fraud_type = '' or fraud_type = ' '` — 过滤反作弊
- `duplicate_label is null or duplicate_label = '' or duplicate_label = ' '` — 去重
- `pricing_type = 11` — ROI3 目标 CPC
- `ads_placement = 40` — 搜索/发现广告位
- `bid_voucher_id > 0` — 有券曝光/点击
- `ads_placement in (40, 50, 0, 3, 2003)` — 常用广告位集合
- `campaign_id % 100 >= 60 and campaign_id % 100 < 80` — 流控实验组

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | 用户 ID | - | - |
| session_id | string | 会话 ID | - | - |
| device_id | string | 设备 ID | - | - |
| client_ip | string | 客户端 IP | - | - |
| platform | int | 平台类型 (1=ios_web, 2=ios_app, 3=android_web, 4=android_app, 5=pc_web, 9=android_app_lite) | - | - |
| timestamp | bigint | 事件时间戳（Unix epoch, UTC+08:00） | - | - |
| token | string | Token | - | - |
| source | string | 来源 | - | - |
| item_id | bigint | 商品 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| discount | string | 折扣信息 | - | - |
| is_free_shipping | string | 是否免邮 | - | - |
| is_prefered | string | 是否优选 | - | - |
| algorithm | string | 算法 | - | - |
| organic_location | int | 自然位置 (location) | - | - |
| refer_urls | string | 来源 URL | - | - |
| item_model_id | string | 商品模型 ID | - | - |
| list_type | string | 列表类型 | - | - |
| ads_id | bigint | 广告 ID | - | - |
| location_in_ads | int | 广告内位置 | - | - |
| campaign_id | bigint | 计划 ID | - | - |
| ads_keyword | string | 广告关键词 | - | - |
| match_type | string | 匹配类型 | - | - |
| query | struct | 搜索 query 信息（含 keyword 等） | - | - |
| abtest_sign | string | AB 实验标识 | - | - |
| item_json_data | string | 商品 JSON 数据（含 pCTR, pCR, pCVR, target_cir, padvv, rank_score, entrance 等算法预估字段） | - | - |
| tracking_json_data | string | Tracking JSON 数据 | - | - |
| ads_request_id | string | 广告请求 ID | - | - |
| fe_ab_sign | string | 前端 AB 标识 | - | - |
| add_cart_item_amount | string | 加购数量 | - | - |
| add_cart_item_price | string | 加购价格 | - | - |
| product_card | string | 商品卡片 | - | - |
| raw_request_id | string | 原始请求 ID | - | - |
| organic_request_id | string | 自然请求 ID | - | - |
| internal_label | string | 内部标签 | - | - |
| ads_entrance | string | 广告入口 | - | - |
| tracking_placement | int | Tracking 广告位 | - | - |
| inner_placement | int | 内部广告位 | - | - |
| ads_placement | int | 广告位 | - | - |
| internal | struct | 内部信息（含 deduction_info.deduction_price, deduction_info.bidprice 等扣费数据） | - | - |
| operation | int | 操作类型 (1=Impression, 2=Click, 3=View, 4=AddToCart, 5=PlaceOrder, 1001=ShopImp, 1002=ShopClick) | - | - |
| pricing_type | int | 出价类型 | - | - |
| operation_desc | string | 操作描述 | - | - |
| platform_desc | string | 平台描述 | - | - |
| tracking_queue_name | string | Tracking 队列名 | - | - |
| fraud_type | string | 反作弊类型 | - | - |
| search_page_sort_type | string | 搜索结果页排序类型 | - | - |
| matched_premium_segments | string | 匹配的 Premium segments | - | - |
| ab_sign | string | AB 标识 | - | - |
| app_ver | string | App 版本 | - | - |
| rn_ver | string | RN 版本 | - | - |
| view_session_id | string | 浏览会话 ID | - | - |
| sub_entrance | int | 子入口 | - | - |
| dfp | string | DFP | - | - |
| click_area | string | 点击区域 | - | - |
| display_video_id | string | 展示视频 ID | - | - |
| ta_group_id | string | TA 组 ID | - | - |
| ta_matched_tag_ids | string | TA 匹配标签 ID | - | - |
| ta_premium_rate | string | TA 溢价率 | - | - |
| vv_id | string | VV ID | - | - |
| sdk_version | string | SDK 版本 | - | - |
| sdk_type | string | SDK 类型 | - | - |
| page_type | string | 页面类型 | - | - |
| page_section | string | 页面区块 | - | - |
| target_type | string | 目标类型 | - | - |
| sort_by | string | 排序方式 | - | - |
| scenario | string | 场景 | - | - |
| search_entrance | string | 搜索入口 | - | - |
| search_mid | string | 搜索 mid | - | - |
| search_session_id | string | 搜索会话 ID | - | - |
| global_session_id | string | 全局会话 ID | - | - |
| current_page | string | 当前页面 | - | - |
| content_type | string | 内容类型 | - | - |
| content_id | string | 内容 ID | - | - |
| trigger_mode | string | 触发模式 | - | - |
| sv_source_page | string | SV 来源页 | - | - |
| display_ad_tag | string | 展示广告标签 | - | - |
| card_type | string | 卡片类型 | - | - |
| video_id | string | 视频 ID | - | - |
| be_ab | string | BE AB | - | - |
| item_price | string | 商品价格 | - | - |
| target_cir | string | 目标 CIR | - | - |
| sold_cnt_per_order | string | 每订单销量 | - | - |
| duplicate_label | string | 去重标签 | - | - |
| click_event_id | string | 点击事件 ID | - | - |
| sold_cnt_per_order_double | string | 每订单销量（double） | - | - |
| bid_deduction_price | string | Bid 扣费价格 | - | - |
| new_product_boost_stage | string | 新品 Boost 阶段 | - | - |
| item_voucher | struct | 商品券信息（含 display_ads_voucher_label） | - | - |
| bid_voucher_id | bigint | Bid 券 ID | - | - |
| voucher_deduction_price | string | 券扣费价格 | - | - |
| is_auto_claimed_just_now | string | 是否刚刚自动领取 | - | - |
| is_roi3_best_voucher | int | 是否 ROI3 best voucher | - | - |
| v_model_id | string | V 模型 ID | - | - |
| v_item_id | string | V 商品 ID | - | - |
| ctx_item_type | string | 上下文商品类型 | - | - |
| algo_json_data | string | 算法 JSON 数据 | - | - |
| unique_id | string | 唯一 ID | - | - |
| event_timestamp | bigint | 事件时间戳 | - | - |
| sequence_id | string | 序列 ID | - | - |
| bid_rerank_trace | string | Bid 重排 trace（含 adjusted_bid_price, pctr, bid_voucher_id） | - | - |
| uni_pcr_model_name | string | 统一 PCR 模型名 | - | - |
| item_price_shop | string | 商品店铺价格 | - | - |
| avg_sold_cnt_shop | string | 店铺平均销量 | - | - |
| avg_sold_cnt_item | string | 商品平均销量 | - | - |
| is_ocpm | boolean | 是否 OCPM | - | - |
| attribute_reason | string | 归因原因 | - | - |
| model_id | string | 模型 ID | - | - |
| rsku_list_infos_json | string | RSKU 列表 JSON | - | - |
| is_preselected_vmodel | boolean | 是否预设 V 模型 | - | - |
| shop_voucher_json | string | 店铺券 JSON | - | - |
| grass_region | string | 区域（ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL） | - | - |
| grass_date | date | 日期（经时区转换后的本地日期） | - | - |
| bz_type | string | 业务类型 | - | - |
