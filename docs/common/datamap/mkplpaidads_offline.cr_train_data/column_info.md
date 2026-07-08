<!-- ads-workspace-gdoc-sync: gdoc_id=1lTDRSKuYeiZM9OmRN1sH_o0IH4-bGy8MKJQ1ZmR7OL0 gdoc_url=https://docs.google.com/document/d/1lTDRSKuYeiZM9OmRN1sH_o0IH4-bGy8MKJQ1ZmR7OL0/edit -->

# Columns: mkplpaidads_offline.cr_train_data

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

`action_info` MAP 中的值均为单次点击级别，天然非累加：
- `ads_direct_order_cnt`, `ads_shop_order_cnt` -- 单次点击产生的直接/间接订单数
- `ads_direct_order_gmv`, `ads_direct_gmv_add`, `ads_shop_order_gmv`, `ads_broad_gmv_add` -- GMV 子项 (单位 cent)
- `click`, `ads_atc_cnt`, `ads_shop_atc_cnt` -- 点击/加购行为
- `unified_placed_order`, `unified_is_redeemed` -- 统一口径下单/核销标志
- `unified_voucher_cost`, `unified_voucher_cost_narrow_attribution` -- 券成本 (宽口径/窄口径)
- `unified_is_redeemed_narrow_attribution` -- 窄口径归因核销标志

跨 request_id 聚合时需使用 SUM，跨更粗粒度需注意去重逻辑。`unified_*` 系列字段为统一口径，跨多行去重时需谨慎。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| ads_entrance | 1 | search (搜索广告) |
| ads_entrance | 3 | dd (发现广告) |
| ads_entrance | 4 | ymal (看了又看) |
| ads_entrance | 8,9,10,11 | pp (其他入口) |
| placement | 40 | 搜索广告位 |
| placement | 50 | 发现广告位 |
| search_info_item_type_str | 'organic' | 自然搜索流量 |
| rcmd_info_item_type_str | 'organic_non_roi' | 自然推荐 (非ROI) |
| rcmd_info_item_type_str | 'organic_recall_roi1' | 自然推荐 (ROI1召回) |
| voucher_unpicked_reason | 17 | 随机不发券 (对照组) |
| voucher_unpicked_reason | 18 | 发券 (实验组) |

### 常见 WHERE 值 (Common Filter Values)

- `region`: IN ('ID','SG','MY','TH','PH','TW','VN') -- 标准 7 区; <> 'BR' -- 排除巴西; IN ('BR') -- 仅巴西 (US 市场专用 workflow)
- `ads_entrance`: IN (1,3,4) -- 三大主入口; IN (1,3,4,8,9,10,11) -- 全量入口; = 1 -- 仅搜索入口 (特征生产)
- `placement`: IN (40,50) -- 搜索+发现广告位
- `ads_id` > 0 -- 过滤非广告样本
- `grass_date`: 单日 = 或 BETWEEN 区间; CAST 为 DATE 类型
- `ads_entrance` != 0 / != '0' -- 排除无入口样本
- `user_id > 0` / `item_id > 0` -- 过滤无效用户/商品
- `request_id IS NOT NULL AND request_id <> 'UNKNOWN'` -- 排除无效请求
- `voucher_price > 0 AND item_price > 0` -- 券分析中过滤无券/无价格样本

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | BIGINT | 用户ID | - | - |
| item_id | BIGINT | 商品ID | - | - |
| request_id | STRING | 请求唯一标识 (可能存在重复，需按 user_id+item_id+request_id 去重) | - | - |
| action_info | MAP<STRING, BIGINT> | 行为标签映射。<br>基本行为: click, ads_atc_cnt, ads_shop_atc_cnt<br>订单计数: ads_direct_order_cnt, ads_shop_order_cnt, org_direct_order_cnt, org_shop_order_cnt, paid_ads_direct_order_cnt, paid_org_direct_order_cnt<br>GMV (cent): ads_direct_order_gmv, ads_direct_gmv_add, ads_shop_order_gmv, ads_broad_gmv_add<br>统一口径下单: unified_placed_order<br>统一口径券: unified_is_redeemed, unified_voucher_cost, unified_is_redeemed_narrow_attribution, unified_voucher_cost_narrow_attribution<br>时间戳: order_timestamp, update_timestamp, unified_order_create_time | - | - |
| mio_info | STRING | MIO 模型信息 (用途待补充) | - | - |
| dump_time | BIGINT | 数据落盘时间戳 | - | - |
| debug_info | STRING | 调试元数据字符串，逗号分隔的 key:value 对。<br>入口/广告位: ads_entrance, placement, ads_id<br>流量类型: search_info_item_type_str, rcmd_info_item_type_str<br>券相关: voucher_price, item_price, uplift_pcr_v, voucher_unpicked_reason<br>时间: clk_timestamp<br>搜索: query (base64编码)<br>模型: uni_pcr_model_name<br>其他: DEBUG_INFO__country | - | - |
| region | STRING | 区域分区列 [PARTITION] | - | - |
| grass_date | STRING | 日期分区列 (yyyy-MM-dd) [PARTITION] | - | - |
| grass_hour | STRING | 小时分区列 [PARTITION] | - | - |
