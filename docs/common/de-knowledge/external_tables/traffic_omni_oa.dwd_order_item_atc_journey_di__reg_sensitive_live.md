<!-- ads-workspace-gdoc-sync: gdoc_id=107hGXfWvfAxUAG13fhOENVjitiApk7MjbI_iUD4eZQo gdoc_url=https://docs.google.com/document/d/107hGXfWvfAxUAG13fhOENVjitiApk7MjbI_iUD4eZQo/edit -->

# traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live

## 外部表状态

- status: `resolved`
- requested_table: `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live`
- canonical_table: `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live`
- resolution: `exact`
- source: `https://sradata.shopee.io/admin/api/datamap/table/info`
- business_docs: `pc2_metrics`

## 使用边界

- 这张表只在命中的业务文档显式声明时作为外部表使用。
- 字段、类型和分区过滤以本文件记录的 DataMap/DESCRIBE 元数据为准。
- 不要把这张表自动加入广告数仓主候选表集合；它只补充业务链路排查。

## 表说明

This table contains order attribution details, supporting detailed queries for order items and tracking item click and source click information. The business event captures the linkage of all matching add-to-cart (ATC) events from the last 7 days for each order item. If no ATC is found in 7 days, it searches for the latest ATC in days 8-30. If no ATC is found in last 30 days, it records that ATC is not found. It identifies the first and last click events within 24 hours of the ATC event, and source1 and source2 clicks within 2 hours of their preceding events.  The primary key is order_id, order_item_id, order_model_id, group_id, bundle_order_item_id, atc_event_id, click_event_id . The update frequeny is Daily incremental updates.

## 分区和过滤

- inferred_partition_keys: `grass_date`, `grass_region`, `tz_type`
- required_filters: `grass_date`, `grass_region`, `tz_type`

## 字段列表

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `ab_test` | `string` | The `ab_test` column indicates the A/B testing group or variant associated with the traffic event. |
| `app_version` | `string` | The `app_version` column specifies the version of the application used during user interaction. |
| `atc_event_id` | `string` | The `atc_event_id` column identifies the "Add to Cart" event that leads to order placement. |
| `atc_event_timestamp` | `bigint` | The `atc_event_timestamp` column records the unix epoch when the add-to-cart (ATC) event occurred. |
| `atc_item_id` | `bigint` | The `atc_item_id` column uniquely identifies the item that was added to the cart. |
| `atc_model_id` | `bigint` | The `atc_model_id` column identifies the product model of an item that was added to cart by a user. |
| `atc_property` | `struct<video_tracker_id:struct<event_name:string,current_page:string>,snack_click_id:string,is_from_snack:boolean,snack_video_id:int,bn_atc_source:int,chatgpt_info:string,migoo_...` | The `atc_property` column contains add-to-cart-specific attributes of the ATC event. |
| `atc_prorate` | `double` | The `atc_prorate` column represents the proportionate evenly-split factor used in calculating order metrics when an order item can be linked to multiple ATC events. |
| `atc_shop_id` | `bigint` | The `atc_shop_id` column identifies the shop associated with the 'Add to Cart' event that leads to order placement. This identifier is essential for linking the event to the specific shop, enabling analysis of cart activity at the shop level. |
| `bundle_order_item_id` | `bigint` | The `bundle_order_item_id` column represents a unique identifier for the order items within a bundle, allowing for tracking and management of items sold together as part of a promotional offer or package. |
| `business_line` | `string` | The `business_line` column represents the business line of the main click/impression event, mapped based on its mapped page type, page section, target type, data, and operation. |
| `click_chat_property` | `struct<chatbot_dialogue_id:string,chatbot_session_id:string,message_id:string,conversation_id:string,convo_userid:string,entry_point_id:string,view_session_id:string,business_id...` |  |
| `click_common_property` | `struct<tab_name:string,is_avatar_live:boolean,is_livestreaming:boolean,is_ads:boolean,card_type:string,is_mini_module:boolean,ads_ab_sign:string,ui_type:string,is_tp:boolean,lik...` | The `click_common_property` column contains structured common attributes of the item click event. |
| `click_content_id` | `string` | The `click_content_id` column is a decoded value (video id or livestream session id) based on the video or livestream business related to the item click event. |
| `click_ctx_itemid` | `bigint` | The `click_ctx_itemid` column identifies the item in the current context of an item click event, which may differ from the item directly related to this event. E.g. when a user clicks item B in the "you may also like" section inside the product detail page of item A, item_id identifies item B since it direcly relates to this item click event, and ctx_item... |
| `click_ctx_shopid` | `bigint` | The `click_ctx_shopid` column identifies the shop in the current context of a item click event, which may differ from the shop directly related to this event. E.g. when a user clicks item B in the "you may also like" section inside the product detail page of item A, shop_id identifies item B's shop since it direcly relates to this item click event, and ct... |
| `click_data` | `string` | The `click_data` column copies data of item click event from traffic mart. |
| `click_device_id` | `string` | The `click_device_id` column identifies the user device involved in click events. |
| `click_event_id` | `string` | The `click_event_id` column identifies the item click event that leads to order placement. |
| `click_event_timestamp` | `bigint` | The `click_event_timestamp` column records the unix epoch of when an item click event occurred. |
| `click_item_id` | `bigint` | The `click_item_id` column identifies an item that was clicked by a user, and this item click event eventually leads to an order placement. |
| `click_last_view_event_id` | `string` | The `click_last_view_event_id` column identifies the unique event ID of the last page view prior to the item click event. |
| `click_live_property` | `struct<itemid:bigint,shopid:bigint,location:int,ctx_streaming_id:int,ctx_from_source:string,is_dp_product:boolean,is_vertical_screen:boolean,is_streaming_price:boolean,has_asked...` | The `click_live_property` column contains structured livestream-related attributes of the item click event. |
| `click_location_property` | `struct<location:int>` | The `click_location_property` column contains structured data representing location-related attributes of the item click event. |
| `click_mapped_page_type` | `string` | The `click_mapped_page_type` column is the adjusted page type of a search-related item click event based on search feature mappings, or the original page type of a non-search-related item click event. |
| `click_os` | `string` | The `click_os` column indicates the operating system of the device used during the item click event. |
| `click_page_section` | `string` | The `click_page_section` column specifies the page section of the item click event. |
| `click_page_type` | `string` |  |
| `click_platform` | `string` | The `click_platform` column specifies the platform on which the click event occurred. |
| `click_platform_implementation` | `string` | The `click_platform_implementation` column specifies the platform implementation of the user's Shopee application when the item click event happened. |
| `click_recommendation_property` | `struct<bundle:string,bundle_option:string,section:string,slot:string,collection_id:string,queue:string,recommendation_algorithm:string,recommendation_info:string,item_config:str...` | The `click_recommendation_property` column contains structured recommendation-related attributes of the item click event. |
| `click_rn_version` | `string` | The `rn_version` column specifies the react native version on user's device. |
| `click_search_property` | `struct<keyword:string,sort_by:string,sort_order:string,queue:string,algorithm:string,input_type:string,location:int,search_prefill_id:string,view_md5:string,image_md5:string,img...` | The `click_search_property` column contains structured search-related attributes of the item click event. |
| `click_sequence_id` | `bigint` | The `click_sequence_id` column is a unique identifier for the sequence of a click event in a user session. |
| `click_session_id` | `string` | The `click_session_id` column identifies the user session when an item click event happened. |
| `click_shop_id` | `bigint` | The `click_shop_id` column identifies the shop associated with a particular item click event that leads to order placement. |
| `click_spu_vsku_property` | `struct<ctx_item_type:int,spu_vsku_model_id:bigint,spu_vsku_item_id:bigint,spu_vsku_shop_id:bigint,rsku_full_list:array<struct<rmodel_id:bigint,ritem_id:bigint,rshop_id:bigint>>,...` |  |
| `click_target_type` | `string` | The `click_target_type` column identifies the target type of the item click event. |
| `click_video_property` | `struct<video_id:string,trigger_mode:string,creator_id:string,request_id:string,vv_id:string,link_source:string,item_id:string,shop_id:string,video_source:string,click_position:s...` | The `click_video_property` column contains video-related attributes extracted from the data of an item click event. |
| `device_id` | `string` | The `device_id` column identifies the user device involved in traffic and/or order events. |
| `exp_group` | `array<int>` | The `exp_group` column identifies the experiment groups the item click event belong to for the purpose of ab test analysis. |
| `exp_version` | `int` | The `exp_version` column identifies the version of the experiment which the item click event belongs to (if applicable). |
| `feature_detail_omni` | `string` | The `feature_detail_omni` column represents the feature detail of the item click event linked to an order placement. How the detail is constructed based on event traffic info is determined by business feature mappings as defined in dim_atlas_feature_business_details_map. If no ATC within 30 days of order placement can be found, the value will be 'not foun... |
| `feature_group_omni` | `string` | The `feature_group_omni` column represents the group classification of the item click event based on mapped page type, page section, target type, data, and operation. |
| `feature_omni` | `string` | The `feature_omni` column represents the feature of the item click event linked to an order placement. How feature is constructed based on event traffic info is determined by business feature mappings as defined in dim_atlas_feature_business_details_map. If no ATC within 30 days of order placement can be found, the value will be 'not found atc'. If ATC ca... |
| `feature_prefix` | `string` | The `feature_prefix` column represents the mapping prefix of search related item click events based on search mappings. |
| `first_touchpoint_item` | `int` | The `first_touchpoint_item` column indicates whether the item click in this record is the first item click that leads to an ATC event. To ensure consistency in order metric sum, first_touchpoint_item = 1 when no item click can be found. |
| `gmv` | `double` | The `gmv` column represents the gross merchandise value of the order item in local currency. For more info, please see order mart user guide |
| `gmv_usd` | `double` | The `gmv_usd` column represents the gross merchandise value of the order item in USD. For more info, please see order mart user guide |
| `grass_date` | `date` | The `grass_date` column represents the date in local timezone when the main traffic event happened or the order was placed. |
| `grass_region` | `string` | The `grass_region` column specifies the region where the traffic/order events happened. |
| `group_id` | `bigint` | The `group_id` column identifies the group to which an order item belongs (if applicable) |
| `is_item_touchpoint` | `boolean` | The `is_item_touchpoint` column indicates whether the item click event can be found for the order item. |
| `item_amount` | `bigint` | The `item_amount` column indicates the number of quantities purchased by the user for a particular order item. |
| `item_promotion_type` | `string` | The `item_promotion_type` column specifies the type of promotion applied to the order item, indicating the nature of the discount or offer available to the buyer. |
| `item_promotion_type_id` | `bigint` | The `item_promotion_type_id` column identifies the type of promotion applied to an order item. |
| `last_touchpoint_item` | `int` | The `last_touchpoint_item` column indicates whether the item click in this record is the last item click that leads to an ATC event. To ensure consistency in order metric sum, last_touchpoint_item = 1 when no item click can be found. |
| `module` | `string` | The `module` column represents the reporting module of a main click/impression event, mapped based on the mapped page type, page section, target type, data, and operation. |
| `object` | `string` | The `object` column represents the reporting object of last item click event, mapped based on its mapped page type, page section, target type, data, and operation. |
| `order_fraction` | `double` | The `order_fraction` column represents the fraction of the order shared by the order item. |
| `order_id` | `bigint` | The `order_id` column stores the unique identifier for each order. This identifier is crucial for linking order-related information across various datasets and tables, facilitating comprehensive analysis of order details and transactions. |
| `order_item_id` | `bigint` | The `order_item_id` column identifies an item in a placed order. |
| `order_model_id` | `bigint` | The `order_model_id` column identifies the product model associated with an ordered item. |
| `order_place_timestamp` | `bigint` | The `order_place_timestamp` column records the unix epoch when an order is placed. |
| `page_type` | `string` | The `page_type` column identifies the page type of the main traffic event. |
| `pc2` | `double` | The `pc2` column represents the pc2 (level 2 profit contribution) value of an order item. |
| `pc2_usd` | `double` | The `pc2_usd` column represents the sum of atc_prorated pc2 (level2 profit contribution) value in USD of all item orders in 1 day. |
| `place_sellergmv` | `double` |  |
| `place_sellergmv_usd` | `double` |  |
| `platform` | `string` | The `platform` column specifies the platform through which user interactions or transactions occurred. |
| `platform_implementation` | `string` | The `platform_implementation` column specifies the platform implementation of the user's Shopee application. |
| `rn_version` | `string` | The `rn_version` column specifies the react native version on user's device. |
| `send_method` | `string` | The `send_method` column specifies how an add-to-cart event is triggered. |
| `session_id` | `string` | The `session_id` column uniquely identifies a user session. This field is crucial for tracking user behavior across different sessions, enabling detailed analysis of user engagement and activity patterns. |
| `shop_id` | `bigint` | The `shop_id` column identifies the shop which an item belongs to. |
| `source1_business_line` | `string` | The `source1_business_line` column represents the business line of the 1st-step source click event, mapped based on its mapped page type, page section, target type, data, and operation. |
| `source1_chat_property` | `struct<chatbot_dialogue_id:string,chatbot_session_id:string,message_id:string,conversation_id:string,convo_userid:string,entry_point_id:string,view_session_id:string,business_id...` |  |
| `source1_common_property` | `struct<tab_name:string,is_avatar_live:boolean,is_livestreaming:boolean,is_ads:boolean,card_type:string,is_mini_module:boolean,ads_ab_sign:string,ui_type:string,is_tp:boolean,lik...` | The `source1_common_property` column contains structured common attributes of the 1st-step source click event. |
| `source1_event_id` | `string` | The `source1_event_id` column identifies the event ID associated with the first-step source click in the omni-channel order item journey. This field is crucial for tracking the sequence of user interactions leading to an order, aiding in the analysis of user behavior and source attribution. |
| `source1_exp_group` | `array<int>` | The `source1_exp_group` column identifies the experiment groups the 1st-step source click event belongs to for the purpose of ab test analysis. |
| `source1_exp_version` | `int` | The `source1_exp_version` column identifies the version of the experiment which the source1 click event belongs to (if applicable). |
| `source1_ext` | `struct<item_id:bigint,shop_id:bigint,platform:string,rn_version:string,app_version:string>` | The `source1_ext` column contains extended information about source1 click event, which include item_id, shop_id, platform, react-native version, and application verion. |
| `source1_feature_detail_omni` | `string` | The `source1_feature_detail_omni` column represents detailed feature attributes related to the 1st-step source click event based on the mapped page type, page section, target type, data, and operation. |
| `source1_feature_group_omni` | `string` | The `source1_feature_group_omni` column categorizes the feature group of source1 events based on mapped page type, page section, target type, data, and operation. |
| `source1_feature_omni` | `string` | The `source1_feature_omni` column represents the feature of the 1st-step source click event linked to an item click which is further linked to an order placement. |
| `source1_feature_prefix` | `string` | The `source1_feature_prefix` column represents the mapping prefix of search related 1st-step source click event based on search mappings. |
| `source1_last_view_event_id` | `string` | The `source1_last_view_event_id` column identifies the unique event ID of the last page view prior to the 1st-step source click event. |
| `source1_live_property` | `struct<itemid:bigint,shopid:bigint,location:int,ctx_streaming_id:int,ctx_from_source:string,is_dp_product:boolean,is_vertical_screen:boolean,is_streaming_price:boolean,has_asked...` | The `source1_live_property` column contains structured livestream-related attributes of the 1st-step source click event. |
| `source1_location_property` | `struct<location:int>` | The `source1_location_property` column contains structured data representing location-related attributes of the 1st-step source click event. |
| `source1_mapped_page_type` | `string` | The `source1_mapped_page_type` column is the adjusted page type of a search-related 1st-step source click event based on search feature mappings, or the original page type of a non-search-related 1st-step source click event. |
| `source1_module` | `string` | The `source1_module` column represents the reporting module of a 1st-step source click event, mapped based on the mapped page type, page section, target type, data, and operation. |
| `source1_object` | `string` | The `source1_object` column represents the reporting object of 1st-step source click event, mapped based on its mapped page type, page section, target type, data, and operation. This field is essential for understanding the context and details of source 1 click events, aiding in traffic analysis and sales funnel optimization. |
| `source1_operation` | `string` | The `source1_operation` column specifies the operation of the 1st-step source click event, which should be "click" in all cases. |
| `source1_page_section` | `string` | The `source1_page_section` column identifies the page section of the 1st-step source click event. |
| `source1_page_type` | `string` | The `source1_page_type` column identifies the page type of the 1st-step source click event. |
| `source1_recommendation_property` | `struct<bundle:string,bundle_option:string,section:string,slot:string,collection_id:string,queue:string,recommendation_algorithm:string,recommendation_info:string,item_config:str...` | The `source1_recommendation_property` column contains structured recommendation-related attributes of the 1st-step source click event. |
| `source1_search_property` | `struct<keyword:string,sort_by:string,sort_order:string,queue:string,algorithm:string,input_type:string,location:int,search_prefill_id:string,view_md5:string,image_md5:string,img...` | The `source1_search_property` column contains structured search-related attributes of the 1st-step source click event. |
| `source1_target_type` | `string` | The `source1_target_type` column identifies the target type of the 1st-step source click event. |
| `source1_video_property` | `struct<video_id:string,trigger_mode:string,creator_id:string,request_id:string,vv_id:string,link_source:string,item_id:string,shop_id:string,video_source:string,click_position:s...` | The `source1_video_property` column contains video-related attributes extracted from the data of a 1st-step source click event. |
| `source2_business_line` | `string` | The `source2_business_line` column represents the business line of the 2nd-step source click event, mapped based on its mapped page type, page section, target type, data, and operation. |
| `source2_chat_property` | `struct<chatbot_dialogue_id:string,chatbot_session_id:string,message_id:string,conversation_id:string,convo_userid:string,entry_point_id:string,view_session_id:string,business_id...` |  |
| `source2_common_property` | `struct<tab_name:string,is_avatar_live:boolean,is_livestreaming:boolean,is_ads:boolean,card_type:string,is_mini_module:boolean,ads_ab_sign:string,ui_type:string,is_tp:boolean,lik...` | The `source2_common_property` column contains structured common attributes of the 2nd-step source click event. |
| `source2_event_id` | `string` | The `source2_event_id` column identifies the event ID associated with the second-step source click in the omni-channel order item journey. This field is crucial for tracking the sequence of user interactions leading to an order, aiding in the analysis of user behavior and source attribution. |
| `source2_exp_group` | `array<int>` | The `source2_exp_group` column identifies the experiment groups the 2nd-step source click event belongs to for the purpose of ab test analysis. |
| `source2_exp_version` | `int` | The `source2_exp_version` column identifies the version of the experiment which the source2 click event belongs to (if applicable). |
| `source2_ext` | `struct<item_id:bigint,shop_id:bigint,platform:string,rn_version:string,app_version:string>` | The `source2_ext` column contains extended information about source2 click event, which include item_id, shop_id, platform, react-native version, and application verion. |
| `source2_feature_detail_omni` | `string` | The `source2_feature_detail_omni` column represents detailed feature attributes related to the 2nd-step source click event based on the mapped page type, page section, target type, data, and operation. |
| `source2_feature_group_omni` | `string` | The `source2_feature_group` column categorizes the feature group of source2 events based on mapped page type, page section, target type, data, and operation. |
| `source2_feature_omni` | `string` | The `source2_feature_omni` column represents the feature of the 2nd-step source click event linked to an item click which is further linked to an order placement. |
| `source2_feature_prefix` | `string` | The `source2_feature_prefix` column represents the mapping prefix of search related 2nd-step source click event based on search mappings. |
| `source2_last_view_event_id` | `string` | The `source2_last_view_event_id` column identifies the unique event ID of the last page view prior to the 2nd-step source click event. |
| `source2_live_property` | `struct<itemid:bigint,shopid:bigint,location:int,ctx_streaming_id:int,ctx_from_source:string,is_dp_product:boolean,is_vertical_screen:boolean,is_streaming_price:boolean,has_asked...` | The `source2_live_property` column contains structured livestream-related attributes of the 2nd-step source click event. |
| `source2_location_property` | `struct<location:int>` | The `source2_location_property` column contains contains structured data representing location-related attributes of the 2nd-step source click event. |
| `source2_mapped_page_type` | `string` | The `source2_mapped_page_type` column is the adjusted page type of a search-related 2nd-step source click event based on search feature mappings, or the original page type of a non-search-related 2nd-step source click event. |
| `source2_module` | `string` | The `source2_module` column represents the reporting module of a 2nd-step source click event, mapped based on the mapped page type, page section, target type, data, and operation. |
| `source2_object` | `string` | The `source2_object` column represents the reporting object of 2nd-step source click event, mapped based on its mapped page type, page section, target type, data, and operation. This field is essential for understanding the context and details of source 2 click events, aiding in traffic analysis and sales funnel optimization. |
| `source2_operation` | `string` | The `source2_operation` column specifies the operation of the 2nd-step source click event, which should be "click" in all cases. |
| `source2_page_section` | `string` | The `source2_page_section` column identifies the page section of the 2nd-step source click event. |
| `source2_page_type` | `string` | The `source2_page_type` column identifies the page type of the 2nd-step source click event. |
| `source2_recommendation_property` | `struct<bundle:string,bundle_option:string,section:string,slot:string,collection_id:string,queue:string,recommendation_algorithm:string,recommendation_info:string,item_config:str...` | The `source2_recommendation_property` column contains structured recommendation-related attributes of the 2nd-step source click event. |
| `source2_search_property` | `struct<keyword:string,sort_by:string,sort_order:string,queue:string,algorithm:string,input_type:string,location:int,search_prefill_id:string,view_md5:string,image_md5:string,img...` | The `source2_search_property` column contains structured search-related attributes of the 2nd-step source click event. |
| `source2_target_type` | `string` | The `source2_target_type` column identifies the target type of the 2nd-step source click event. |
| `source2_video_property` | `struct<video_id:string,trigger_mode:string,creator_id:string,request_id:string,vv_id:string,link_source:string,item_id:string,shop_id:string,video_source:string,click_position:s...` | The `source2_video_property` column contains video-related attributes extracted from the data of a 2nd-step source click event. |
| `spu_vsku_order_property` | `struct<has_spu_vsku:boolean,display_spu_vsku:boolean,initial_vsku_cnt:int,updated_vsku_cnt:int,initial_rsku_cnt:int,updated_rsku_cnt:int,spu_vsku_item_id:bigint,spu_vsku_model_i...` |  |
| `step_num` | `int` | The `step_num` column represents the distance of an item click event from the atc event. When click is last touchpoint click, step_num=1. When click is first touchpoint, step_num=2. When no item click can be found, step_num=1. |
| `step_num_item` | `int` | The `step_num_item` column represents the distance of a item click event from the atc event by considering only item touchpoints. When no click found, step_num_item=-1 |
| `tz_type` | `string` | The `tz_type` column specifies the type of time zone associated with the order item journey. This field is used to identify and manage time zone differences in order processing and reporting. |
| `user_id` | `bigint` | The `user_id` column stores the unique identifier of the buyer involved in the order and add-to-cart (ATC) journey. This field is essential for associating purchase activities with specific users and analyzing buyer behavior. |
| `window_day` | `int` | The `window_day` column specifies the number of day between order placement and add-to-cart event (date diff +1), and window_day = 0 denotes no add-to-cart event within 30 days can be found. |
