<!-- ads-workspace-gdoc-sync: gdoc_id=1HRsv9dHfv4IWflECylb4LInveGLrPsItkrkrk0uFmUk gdoc_url=https://docs.google.com/document/d/1HRsv9dHfv4IWflECylb4LInveGLrPsItkrkrk0uFmUk/edit -->

# Columns: mkplpaidads_data.dwd_advertise_tracking_shop_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

该表为事件级追踪表，所有行为事件独立记录，不存在跨维度 SUM(DISTINCT) 模式。聚合时使用 `COUNT(*)` 或 `SUM(IF(operation=N, 1, 0))` 即可。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | 1 | IMPRESSION |
| operation | 2 | CLICK |
| operation | 3 | VIEW |
| operation | 4 | ADD_TO_CART |
| operation | 5 | PLACE_ORDER |
| operation | 1001 | SHOP_IMPRESSION |
| operation | 1002 | SHOP_CLICK |

> 注: operation 枚举映射在 dwd_advertise_fraud_di (8 个区域文件) 和 ads_adstype_baseline_mkt (11 个区域文件) 的 CASE WHEN 中重复出现。

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准 11 区 ('ID','MY','PH','SG','TH','TW','VN','BR','MX','CO','CL')
- `operation`: 1001 (Shop 曝光) / 1002 (Shop 点击)
- `coalesce(ads_id, 0) > 0` -- 过滤无效广告
- `user_id > 0` -- 过滤无效用户
- `grass_date` -- 日期分区，通常用 `DATE('${bizdate}')` 或 `DATE('${grass_date}')`

## All Columns

*列类型根据 VIEW 定义及上游 hi 表推理，部分类型未确认。* `[PARTITION]` 标注为分区列。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | 用户 ID | - | - |
| session_id | string | 会话 ID | - | - |
| device_id | string | 设备 ID | - | - |
| client_ip | string | 客户端 IP，逗号分隔 | - | - |
| platform | string | 平台类型 | - | - |
| timestamp | bigint | Unix 事件时间戳 | - | - |
| token | string | 请求 token | - | - |
| source | string | 来源 | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| algorithm | string | 算法标识 | - | - |
| organic_location | string | 自然位次 | - | - |
| refer_urls | string | 来源 URL | - | - |
| list_type | string | 列表类型 | - | - |
| query | string | 搜索关键词（struct，含 .keyword 字段） | - | - |
| shop_json_data | string | 店铺 JSON 数据 | - | - |
| tracking_json_data | string | 追踪 JSON 数据 | - | - |
| ads_request_id | string | 广告请求 ID | - | - |
| fe_ab_sign | string | 前端 AB 实验标签 | - | - |
| internal_label | string | 内部标签 | - | - |
| ads_entrance | string | 广告入口 | - | - |
| tracking_placement | int | 追踪 placement | - | - |
| inner_placement | string | 内部 placement | - | - |
| ads_placement | int | 广告 placement | - | - |
| internal | string | 内部标识 | - | - |
| ads_id | bigint | 广告 ID | - | - |
| click_area | string | 点击区域 | - | - |
| items | string | 商品信息（JSON） | - | - |
| vouchers | string | 券信息 | - | - |
| pricing_type | string | 出价类型 | - | - |
| operation | int | 操作类型: 1001=SHOP_IMPRESSION, 1002=SHOP_CLICK | - | - |
| fraud_type | string | 反作弊类型 | - | - |
| operation_desc | string | 操作描述文本 | - | - |
| platform_desc | string | 平台描述文本 | - | - |
| shop_voucher_promotion_id | string | 店铺券活动 ID | - | - |
| shop_voucher_code | string | 店铺券码 | - | - |
| shop_item_id_1 | bigint | 店铺商品 ID 1 | - | - |
| shop_item_id_2 | bigint | 店铺商品 ID 2 | - | - |
| shop_item_id_3 | bigint | 店铺商品 ID 3 | - | - |
| shop_item_id_4 | bigint | 店铺商品 ID 4 | - | - |
| shop_clicked_item_id | bigint | 店铺被点击商品 ID | - | - |
| ab_sign | string | AB 实验标签 | - | - |
| app_ver | string | App 版本 | - | - |
| rn_ver | string | RN 版本 | - | - |
| view_session_id | string | 浏览会话 ID | - | - |
| sub_entrance | string | 子入口 | - | - |
| dfp | string | DFP 标识 | - | - |
| ls_session_id | bigint | Live Streaming 会话 ID | - | - |
| bid_deduction_price | double | 出价扣减价格 | - | - |
| shop_recall_type | string | 店铺召回类型 | - | - |
| duration | int | 时长 | - | - |
| sdk_version | string | SDK 版本 | - | - |
| sdk_type | string | SDK 类型 | - | - |
| scenario | string | 场景 | - | - |
| search_mid | string | 搜索 mid | - | - |
| search_entrance | string | 搜索入口 | - | - |
| landing_url_type | string | 落地页 URL 类型 | - | - |
| banner_location | string | Banner 位置 | - | - |
| target_url | string | 目标 URL | - | - |
| landing_page_url | string | 落地页 URL | - | - |
| banner_cnt | int | Banner 数量 | - | - |
| dre_ver | string | DRE 版本 | - | - |
| banner_id | bigint | Banner ID | - | - |
| slot_id | int | 广告位 ID | - | - |
| banner_json_data | string | Banner JSON 数据 | - | - |
| banner_json_data_tms | string | Banner JSON 数据 (tms) | - | - |
| unique_id | string | 唯一 ID | - | - |
| target_type | string | 目标类型 | - | - |
| prefill_keyword | string | 预填充关键词 | - | - |
| global_session_id | string | 全局会话 ID | - | - |
| referer_type | int | 来源类型 | - | - |
| referer_data | string | 来源数据 | - | - |
| display_video_id_encoded | string | 编码的展示视频 ID | - | - |
| material_ratio | string | 素材比例 | - | - |
| location_type | string | 位置类型 | - | - |
| bid_rerank_trace | string | 出价重排追踪数据（JSON） | - | - |
| grass_region | string | 区域 (SG,MY,ID,PH,TH,VN,TW,BR,MX,CO,CL) | - | - |
| grass_date | string | 本地日期 (根据 grass_region 时区转换) | - | - |
| bz_type | string | 业务类型 | - | - |
