<!-- ads-workspace-gdoc-sync: gdoc_id=1FNIhDiDnD9mYcgOpzSWAZPBGyVw8uiLvTxdw9_xw_nU gdoc_url=https://docs.google.com/document/d/1FNIhDiDnD9mYcgOpzSWAZPBGyVw8uiLvTxdw9_xw_nU/edit -->

# Columns: traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

跨 `order_item_id`/`order_id`/`step_type` 聚合时必须使用如下归因权重公式：
- 所有 GMV/订单指标: 必须乘以 `first_touchpoint_item * atc_prorate` 后再 SUM
- `platform_net_order_fraction`: `SUM(CASE WHEN is_net_order = 1 THEN order_fraction * first_touchpoint_item * atc_prorate ELSE 0 END)`

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | 'local' | 本地时区 (~100% 查询) |
| tz_type | 'regional' | 区域时区 (仅 dws_organic workflow 使用) |
| step_type | 'step0','step1','step2','stepall' | ATC旅程触点距离：直达/一跳/两跳/全路径 |
| is_cod | 0, 1 | 是否COD订单 |
| is_net_order | 0, 1 | 是否净订单 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~100% 查询)
- `user_id`: `user_id > 0` (所有查询均过滤)
- `grass_date`: `date('${grass_date}')` 单日；或 `BETWEEN DATE_SUB(date('${grass_date}'), 1) AND date('${grass_date}')` 两天（workflow hourly版本）
- `grass_region`: `upper('${region}')` 动态参数
- `order_place_timestamp`: `>= to_unix_timestamp(date('${grass_date}')) AND < to_unix_timestamp(date_add(date('${grass_date}'), 1))` (workflow版本)

## All Columns

> 注意: 表 DDL 未在 studio_tasks 代码库中，以下列出在查询中引用到的列。运行 `--source from-di` 可补全列描述和类型。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | 分区日期 | - | - |
| grass_region | string | 区域（SG/ID/MY/PH/TH/TW/VN/BR） | - | - |
| tz_type | string | 时区类型（local/regional） | - | - |
| user_id | bigint | 用户ID | - | - |
| device_id | string | 设备ID | - | - |
| platform | string | 平台（android/ios） | - | - |
| platform_implementation | string | 平台实现 | - | - |
| app_version | string | App版本 | - | - |
| session_id | string | 会话ID | - | - |
| shop_id | bigint | 店铺ID | - | - |
| order_id | bigint | 订单ID | - | - |
| order_item_id | bigint | 订单商品ID | - | - |
| order_model_id | bigint | 订单型号ID (别名为 model_id) | - | - |
| group_id | bigint | 组合ID | - | - |
| bundle_order_item_id | bigint | 捆绑订单商品ID | - | - |
| item_promotion_type_id | bigint | 商品促销类型ID | - | - |
| item_promotion_type | string | 商品促销类型 | - | - |
| atc_shop_id | bigint | ATC店铺ID | - | - |
| atc_item_id | bigint | ATC商品ID | - | - |
| atc_model_id | bigint | ATC型号ID | - | - |
| atc_event_id | string | ATC事件ID | - | - |
| atc_event_timestamp | bigint | ATC事件时间戳 | - | - |
| atc_property | struct | ATC属性 | - | - |
| click_event_id | string | 点击事件ID | - | - |
| click_event_timestamp | bigint | 点击事件时间戳 | - | - |
| click_item_id | bigint | 点击商品ID | - | - |
| click_shop_id | bigint | 点击店铺ID | - | - |
| click_content_id | string | 点击内容ID | - | - |
| click_last_view_event_id | string | 点击前最后浏览事件ID | - | - |
| click_data | string | 点击数据 | - | - |
| feature_prefix | string | 触点前缀 | - | - |
| feature_group_omni | string | 触点分组（Search/You May Also Like/Daily Discover/Video/Live Streaming etc.） | - | - |
| feature_omni | string | 触点特征 | - | - |
| feature_detail_omni | string | 触点特征详情 | - | - |
| business_line | string | 业务线 | - | - |
| module | string | 模块（Global Search/Image Search/Daily Discover etc.） | - | - |
| object | string | 对象 | - | - |
| is_item_touchpoint | boolean | 是否为商品触点 | - | - |
| step_num_item | int | 商品触点步骤数 | - | - |
| first_touchpoint_item | double | 首次商品触点标记（用于归因） | - | - |
| last_touchpoint_item | double | 最后商品触点标记 | - | - |
| step_num | int | 步骤数 | - | - |
| atc_prorate | double | ATC归因权重 | - | - |
| order_fraction | double | 订单份额 | - | - |
| order_place_timestamp | bigint | 下单时间戳 | - | - |
| gmv | double | GMV（本地币） | - | - |
| gmv_usd | double | GMV（美元） | - | - |
| is_net_order | int | 是否净订单 | - | - |
| nmv | double | NMV（本地币） | - | - |
| nmv_usd | double | NMV（美元） | - | - |
| item_amount | int | 商品数量 | - | - |
| antifraud_gmv_usd | double | 反欺诈GMV（USD） | - | - |
| antifraud_gmv | double | 反欺诈GMV（本地币） | - | - |
| antifraud_order_fraction | double | 反欺诈订单份额 | - | - |
| pay_gmv_usd | double | 支付GMV（USD） | - | - |
| pay_gmv | double | 支付GMV（本地币） | - | - |
| pay_order_fraction | double | 支付订单份额 | - | - |
| confirm_gmv_usd | double | 确认收货GMV（USD） | - | - |
| confirm_gmv | double | 确认收货GMV（本地币） | - | - |
| confirm_order_fraction | double | 确认收货订单份额 | - | - |
| complete_gmv_usd | double | 完成GMV（USD） | - | - |
| complete_gmv | double | 完成GMV（本地币） | - | - |
| complete_order_fraction | double | 完成订单份额 | - | - |
| cancel_gmv_usd | double | 取消GMV（USD） | - | - |
| cancel_gmv | double | 取消GMV（本地币） | - | - |
| cancel_order_fraction | double | 取消订单份额 | - | - |
| return_gmv_usd | double | 退货GMV（USD） | - | - |
| return_gmv | double | 退货GMV（本地币） | - | - |
| return_order_fraction | double | 退货订单份额 | - | - |
| is_cod | int | 是否COD订单（0/1） | - | - |
| spu_vsku_order_property | struct | SPU VSKU订单属性 | - | - |
| rn_version | string | RN版本 | - | - |
| ab_test | string | AB测试标识 | - | - |
| exp_version | string | 实验版本 | - | - |
| exp_group | string | 实验组 | - | - |
| page_type | string | 页面类型 | - | - |
| send_method | string | 发货方式 | - | - |
| click_page_type | string | 点击页面类型 | - | - |
| click_mapped_page_type | string | 点击映射页面类型 | - | - |
| click_page_section | string | 点击页面区块 | - | - |
| click_target_type | string | 点击目标类型 | - | - |
| click_ctx_itemid | bigint | 点击上下文商品ID | - | - |
| click_ctx_shopid | bigint | 点击上下文店铺ID | - | - |
| click_os | string | 点击OS | - | - |
| click_rn_version | string | 点击RN版本 | - | - |
| click_device_id | string | 点击设备ID | - | - |
| click_platform | string | 点击平台 | - | - |
| click_platform_implementation | string | 点击平台实现 | - | - |
| click_sequence_id | string | 点击序列ID | - | - |
| click_session_id | string | 点击会话ID | - | - |
| click_common_property | struct | 点击通用属性（含 is_ads） | - | - |
| click_video_property | struct | 点击视频属性 | - | - |
| click_live_property | struct | 点击直播属性 | - | - |
| click_search_property | struct | 点击搜索属性 | - | - |
| click_recommendation_property | struct | 点击推荐属性 | - | - |
| click_location_property | struct | 点击位置属性（含 location） | - | - |
| click_spu_vsku_property | struct | 点击SPU VSKU属性 | - | - |
| source1_event_id | string | 来源1事件ID | - | - |
| source1_page_type | string | 来源1页面类型 | - | - |
| source1_mapped_page_type | string | 来源1映射页面类型 | - | - |
| source1_page_section | string | 来源1页面区块 | - | - |
| source1_target_type | string | 来源1目标类型 | - | - |
| source1_operation | string | 来源1操作 | - | - |
| source1_last_view_event_id | string | 来源1最后浏览事件ID | - | - |
| source1_feature_prefix | string | 来源1触点前缀 | - | - |
| source1_feature_group_omni | string | 来源1触点分组 | - | - |
| source1_feature_omni | string | 来源1触点特征 | - | - |
| source1_feature_detail_omni | string | 来源1触点特征详情 | - | - |
| source1_business_line | string | 来源1业务线 | - | - |
| source1_module | string | 来源1模块 | - | - |
| source1_object | string | 来源1对象 | - | - |
| source1_common_property | struct | 来源1通用属性（含 is_ads） | - | - |
| source1_video_property | struct | 来源1视频属性 | - | - |
| source1_live_property | struct | 来源1直播属性 | - | - |
| source1_search_property | struct | 来源1搜索属性 | - | - |
| source1_recommendation_property | struct | 来源1推荐属性 | - | - |
| source1_location_property | struct | 来源1位置属性（含 location） | - | - |
| source1_ext | string | 来源1扩展信息 | - | - |
| source1_exp_version | string | 来源1实验版本 | - | - |
| source1_exp_group | string | 来源1实验组 | - | - |
| source2_event_id | string | 来源2事件ID | - | - |
| source2_page_type | string | 来源2页面类型 | - | - |
| source2_mapped_page_type | string | 来源2映射页面类型 | - | - |
| source2_page_section | string | 来源2页面区块 | - | - |
| source2_target_type | string | 来源2目标类型 | - | - |
| source2_operation | string | 来源2操作 | - | - |
| source2_last_view_event_id | string | 来源2最后浏览事件ID | - | - |
| source2_feature_prefix | string | 来源2触点前缀 | - | - |
| source2_feature_group_omni | string | 来源2触点分组 | - | - |
| source2_feature_omni | string | 来源2触点特征 | - | - |
| source2_feature_detail_omni | string | 来源2触点特征详情 | - | - |
| source2_business_line | string | 来源2业务线 | - | - |
| source2_module | string | 来源2模块 | - | - |
| source2_object | string | 来源2对象 | - | - |
| source2_common_property | struct | 来源2通用属性（含 is_ads） | - | - |
| source2_video_property | struct | 来源2视频属性 | - | - |
| source2_live_property | struct | 来源2直播属性 | - | - |
| source2_search_property | struct | 来源2搜索属性 | - | - |
| source2_recommendation_property | struct | 来源2推荐属性 | - | - |
| source2_location_property | struct | 来源2位置属性（含 location） | - | - |
| source2_ext | string | 来源2扩展信息 | - | - |
| source2_exp_version | string | 来源2实验版本 | - | - |
| source2_exp_group | string | 来源2实验组 | - | - |
| window_day | int | 窗口天数 | - | - |
