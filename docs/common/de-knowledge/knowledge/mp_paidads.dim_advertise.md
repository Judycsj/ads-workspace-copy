<!-- ads-workspace-gdoc-sync: gdoc_id=1MrtV6jM7TFFILnHNTKQ0welhHfLu7fbDLFDxZwu9_Qg gdoc_url=https://docs.google.com/document/d/1MrtV6jM7TFFILnHNTKQ0welhHfLu7fbDLFDxZwu9_Qg/edit -->

# mp_paidads.dim_advertise

**分层**：DIM（维度层）
**主键**：`ads_id` + `placement`（联合主键，同一广告在不同广告位展开为多行）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日全量覆盖写入（INSERT OVERWRITE），各地区按本地时区参数化调度
**引用频次**：174 次（候选表范围内）

---

## 业务描述

`mp_paidads.dim_advertise` 是付费广告域的核心广告维度表，以 **广告 ID（`ads_id`）× 广告位（`placement`）** 为粒度，整合了广告基础属性、所属 Campaign 信息、商品与品类信息、卖家信息、受众定向信息、出价与预算信息，以及广告所属的产品类型标签，是面向广告分析、报表生成、运营决策的一站式广告维表。

本表覆盖商品推广、店铺广告、品牌广告、直播广告、视频广告、Boost 广告、Auto-Boost 等全品类广告形态。由于同一广告（`ads_id`）可在多个广告位（`placement`）同时投放，ETL 对部分 placement 进行了枚举展开，因此同一 `ads_id` 在同一 `grass_date` 分区内会有多行记录，**以 `ads_id + placement` 作为逻辑主键**。

本表在下游被广泛引用（174 次），是广告绩效报表、品类投放分析、ROI 核算、卖家运营看板等场景不可或缺的基础维表。查询时务必按需过滤 `tz_type`、`grass_region`、`grass_date` 三个分区字段，以避免全表扫描和数据重复计算。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型分区。ETL 固定写入 `'local'`（本地时区），查询时**必须过滤 `tz_type = 'local'`**，否则将重复计算数据 ⚠️ 当前写入值仅为 `local`，若不过滤将导致全分区扫描 |
| `grass_region` | string | 地区分区，如 `'MY'`、`'TH'`、`'PH'` 等，存储为大写。各地区按本地时区参数化调度独立写入 |
| `grass_date` | date | 日期分区，格式 `yyyy-MM-dd`，每日全量覆盖。代表数据快照日期 |

---

### 维度：主键与广告属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_id` | bigint | 广告 ID，与 `placement` 共同构成联合主键 ⚠️ 同一 `ads_id` 因 placement 展开可能存在多行，不可直接以 `ads_id` 做唯一性假设 |
| `placement` | bigint | 广告位枚举值。ETL 对 placement=8/10/12/20/33/44 进行了子位拆分（如 placement=33 展开为 33、3327、3328 等多行），完整枚举值含义见字段描述中的 `TrackingPlacement` 枚举定义 ⚠️ 聚合时需注意 placement 展开导致的重复计数 |
| `ads_type` | string | 广告类型文本，由 ETL 根据 placement 值映射生成，枚举值包括：`keyword:search`、`targeting:similar_product`、`targeting:daily_discover`、`keyword:simple_mode`、`targeting:ymal`、`targeting:simple_mode_ymal`、`targeting:simple_mode_sp`、`targeting:simple_mode_dd` 等；部分 placement 无对应映射时为 NULL |
| `ads_status` | bigint | 广告当前状态（枚举整数），反映广告记录的状态值 |
| `is_ads_active` | tinyint | 广告是否有效（1=有效，0=无效）。由 ETL 综合判断：需在投放索引中存在有效记录，且当前日期在 campaign 有效期内 ⚠️ 该字段是基于快照日期计算的派生字段，反映 `grass_date` 当日的状态，跨日使用需重新取对应日期分区 |
| `ads_create_datetime` | string | 广告创建时间，格式 `yyyy-MM-dd HH:mm:ss`，按本地时区转换 |
| `ads_create_timestamp` | bigint | 广告创建时间戳（Unix 秒级），源自原始表 `ctime` 字段 |
| `ads_modify_datetime` | string | 广告最近修改时间，格式 `yyyy-MM-dd HH:mm:ss`，按本地时区转换 |
| `ads_modify_timestamp` | bigint | 广告最近修改时间戳（Unix 秒级），源自原始表 `mtime` 字段 |
| `pricing_type` | int | 广告计价模式枚举值。完整枚举见字段描述中 `AdsPricingType` 定义，常见值：1=手动 CPC、3=Boost、4=Simple Mode、7=Auto-Boost、9=直播最大观看、10=直播最大 GMV 等；ETL 中对 NULL 做了 `COALESCE(pricing_type, 0)` 处理 |
| `potential_product_type` | int | 广告创建时标识的潜在产品类型 |
| `first_delivery_datetime` | string | 广告首次可投放的本地时间，格式 `yyyy-MM-dd HH:mm:ss` |
| `first_delivery_timestamp` | bigint | 广告首次可投放时间戳（Unix 秒级） |

---

### 维度：Campaign 属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `campaign_id` | bigint | 广告活动 ID |
| `campaign_status` | tinyint | Campaign 当前状态枚举值，来源于 `mp_paidads.dim_campaign__reg_s0_live` |
| `campaign_status_text` | string | Campaign 当前状态的文本表示 |
| `campaign_start_datetime` | string | Campaign 开始时间，格式 `yyyy-MM-dd HH:mm:ss` |
| `campaign_end_datetime` | string | Campaign 结束时间，格式 `yyyy-MM-dd HH:mm:ss` |

---

### 维度：卖家与店铺

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_id` | bigint | 店铺 ID |
| `seller_id` | bigint | 卖家用户 ID |
| `seller_name` | string | 卖家用户名，来源于 `mp_user.dim_user__reg_s0_live` |
| `language` | string | 卖家语言偏好，ETL 中当前以 NULL 占位（原始字段暂未填充） ⚠️ 当前 ETL 固定输出 NULL，不可用于实际语言筛选 |

---

### 维度：商品与品类

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `item_id` | bigint | 商品 ID |
| `item_name` | string | 商品名称，来源于 `mp_item.dim_item__reg_s0_live` |
| `item_create_datetime` | string | 商品创建时间，格式 `yyyy-MM-dd HH:mm:ss`，来源于 `mp_item.dim_item__reg_s0_live` |
| `level1_global_be_category` | struct<level1_global_be_category_id:bigint, level1_global_be_category:string> | 全局后台一级品类（struct 结构），含品类 ID 与名称 ⚠️ 为嵌套 struct 类型，使用时需用 `.` 操作符访问子字段，不可直接聚合 |
| `level2_global_be_category` | struct<level2_global_be_category_id:bigint, level2_global_be_category:string> | 全局后台二级品类（struct 结构），含品类 ID 与名称 ⚠️ 同上，嵌套 struct 类型 |
| `level3_global_be_category` | struct<level3_global_be_category_id:bigint, level3_global_be_category:string> | 全局后台三级品类（struct 结构），含品类 ID 与名称 ⚠️ 同上，嵌套 struct 类型 |
| `level1_fe_display_category_list` | array<struct<level1_fe_display_category_id:bigint, level1_fe_display_category:string, level1_fe_display_category_fraction_factor:double>> | 前端展示一级品类列表（含分配因子），来源于 `mp_item.dwd_item_fe_display_category_factor_df__reg_s0_live` ⚠️ 为 array<struct> 类型，需用 `EXPLODE` 展开后使用；`fraction_factor` 为权重系数，不可直接 SUM |
| `level2_fe_display_category_list` | array<struct<level2_fe_display_category_id:bigint, level2_fe_display_category:string, level2_fe_display_category_fraction_factor:double>> | 前端展示二级品类列表（含分配因子）⚠️ 同上，array<struct> 类型，fraction_factor 为权重，不可直接 SUM |
| `level3_fe_display_category_list` | array<struct<level3_fe_display_category_id:bigint, level3_fe_display_category:string, level3_fe_display_category_fraction_factor:double>> | 前端展示三级品类列表（含分配因子）⚠️ 同上，array<struct> 类型，fraction_factor 为权重，不可直接 SUM |
| `level1_kpi_category_list` | array<struct<level1_kpi_category_id:bigint, level1_kpi_category:string, level1_kpi_category_fraction_factor:double>> | KPI 一级品类列表（含分配因子），来源于 `mp_item.dwd_item_kpi_category_factor_df__reg_s0_live` ⚠️ array<struct> 类型，fraction_factor 为权重，不可直接 SUM |
| `level2_kpi_category_list` | array<struct<level2_kpi_category_id:bigint, level2_kpi_category:string, level2_kpi_category_fraction_factor:double>> | KPI 二级品类列表（含分配因子）⚠️ 同上，array<struct> 类型，fraction_factor 为权重，不可直接 SUM |
| `level3_kpi_category_list` | array<struct<level3_kpi_category_id:bigint, level3_kpi_category:string, level3_kpi_category_fraction_factor:double>> | KPI 三级品类列表（含分配因子）⚠️ 同上，array<struct> 类型，fraction_factor 为权重，不可直接 SUM |

---

### 维度：产品类型标签

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `main_product_type` | string | 主产品类型，由 `pricing_type + placement` 从 `dim_product_type_mapping` 映射得出，NULL 时填充为 `'Others'`。详细映射见 [GoogleSheets](https://docs.google.com/spreadsheets/d/142y9-AkwK_dpM7vqvmnyvhTfdaJw1virV23KAdnJQY4) |
| `product_type` | string | 产品类型，同上映射逻辑，NULL 时填充为 `'others'` |
| `sub_product_type` | string | 产品子类型，同上映射逻辑，NULL 时填充为 `'others'` |

---

### 维度：预算与配额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `daily_quota_local` | double | Campaign 每日预算配额（本地货币）⚠️ 为 Campaign 级别字段，不代表单个广告的预算，多 placement 展开后直接 SUM 会重复计算 |
| `daily_quota_usd` | double | Campaign 每日预算配额（USD）⚠️ 同上，Campaign 级别字段，不可在 placement 展开后直接 SUM |
| `total_quota_local` | double | Campaign 总预算配额（本地货币）⚠️ Campaign 级别字段，不可在 placement 展开后直接 SUM |
| `total_quota_usd` | double | Campaign 总预算配额（USD）⚠️ Campaign 级别字段，不可在 placement 展开后直接 SUM |
| `daily_available_quota` | bigint | 当日可用配额，仅对 placement in (1000, 1002, 1005) 的分裂预算广告有值，其余为 NULL |
| `is_budget_split` | int | 预算是否拆分：1=已拆分，0=未拆分 |
| `split_budget_version` | int | 预算拆分版本号；version=0 视为未拆分 |

---

### 维度：出价与定向

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `target_price` | double | 广告目标出价，原始值 / 100000.0 转换（分→元）|
| `target_base_price` | double | 广告目标基准价格，原始值 / 100000.0 转换 |
| `target_premium_rate` | bigint | 目标溢价率 |
| `target_roi` | int | 目标 ROI 值 |
| `target_roi_type` | int | 目标 ROI 类型：`target_roi=0` 时为 1，否则为 0（表示是否使用默认 ROI）⚠️ 为派生字段，不可直接 SUM |
| `ta_group_id` | bigint | 目标受众群体 ID，与特定 `campaign_id` 绑定，来源于 `target_audience_group_tab` |
| `ta_premium_rate` | bigint | 广告匹配目标受众时的溢价率 |
| `tag_ids` | array<int> | 标签 ID 列表，当前 ETL 以 NULL 占位 ⚠️ 当前固定为 NULL，不可用于实际筛选 |
| `is_segment_ad` | tinyint | 是否为分层受众广告，当前 ETL 固定输出 0 ⚠️ 当前固定为 0，暂未启用 |
| `filter_segments_age_list` | string | 年龄筛选分层列表，当前 ETL 固定输出 NULL ⚠️ 当前固定为 NULL |
| `filter_segments_gender_list` | string | 性别筛选分层列表，当前 ETL 固定输出 NULL ⚠️ 当前固定为 NULL |
| `filter_segments_location_list` | string | 地区筛选分层列表，当前 ETL 固定输出 NULL ⚠️ 当前固定为 NULL |
| `filter_segments_category_list` | string | 品类筛选分层列表，当前 ETL 固定输出 NULL ⚠️ 当前固定为 NULL |
| `premium_segments_behavior_list` | string | 高溢价行为分层列表，当前 ETL 固定输出 NULL ⚠️ 当前固定为 NULL |

---

### 维度：关键词与素材

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `keywords` | string | 广告关联关键词列表（JSON 字符串），含关键词文本、出价、状态、匹配类型、算法等信息 ⚠️ 存储为 JSON 字符串，需用 `from_json` 或 `get_json_object` 解析后使用 |
| `auto_boost_algo_status` | int | Auto-Boost 算法状态枚举值 |

---

### 维度：品牌广告与 Banner

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `banner_image_image_uri_app` | string | 品牌广告横幅图片 APP 端 URI |
| `banner_image_uri_pc` | string | 品牌广告横幅图片 PC 端 URI |
| `banner_keywords` | string | 品牌广告横幅关联关键词（逗号分隔字符串） |
| `banner_landing_page_url` | string | 品牌广告横幅落地页链接 |
| `search_brand_package_order_id` | string | 品牌搜索广告包订单 ID，对应 `shopee_ads_xx_db.searchbrand_package_tab` 中的 `package_order_id` |
| `brand_max_type` | int | Brand Max 广告类型：0=单品 Brand Max，1=套餐 Brand Max |
| `brand_max_package_request_id` | bigint | Brand Max 广告套餐请求 ID，可关联 `mp_seller.dwd_campaign_package_order_package_df__reg_s0_live` 的 `order_package_id` 获取套餐信息 |

---

### 维度：店铺定制

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_customisation_display_title` | string | 店铺广告定制展示标题 |
| `shop_customisation_image_url` | string | 店铺广告定制图片链接 |
| `shop_customisation_collection_id` | bigint | 店铺广告定制系列 ID |

---

### 维度：Boost 广告属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `boost_id` | bigint | Boost 广告 ID；非 NULL 时表示 placement=10（商品 Boost）；0=卖家使用预定义套餐；1=卖家自定义 Boost 套餐 |
| `boost_package_id` | bigint | Boost 套餐 ID；NULL 表示卖家自定义设置，非 NULL 表示使用特定套餐 |
| `boost_price` | double | 卖家购买 Boost 套餐支付金额 |
| `boost_days` | int | Boost 广告投放天数 |
| `boost_est_views` | bigint | Boost 广告预估曝光量 |

---

### 维度：视频与直播广告

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `post_id` | bigint | 视频广告的帖子 ID |
| `video_id` | string | 视频广告的视频 ID |
| `video_status` | int | 视频状态：0=私有/初始化，1=已发布/正常，2=用户删除，3=管理员删除，4=管理员屏蔽（已废弃），5=仅作者可见；来源于 `video.video_mart_dim_content`，仅视频广告有值 |
| `target_affiliate_user_id` | bigint | 仅限直播广告，用于区分 MCN 机构创建的广告 |

---

### 维度：有机/套餐非广告标识

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `is_nominated_for_package_non_ads` | tinyint | 是否被提名为套餐非付费广告（1=是）。当 `is_nominated_for_package_non_ads=1` 且 `pricing_type=29` 且当前日期在 campaign 有效期内时，该广告为套餐广告 ⚠️ 需结合 `pricing_type` 和 campaign 时间范围联合判断，不可单独使用 |
| `is_organic_non_ads` | tinyint | 是否为有机非付费广告（1=是）。当 `is_organic_non_ads=1` 且 `pricing_type=29` 时，该广告为有机广告。优先级：套餐非广告 > 有机非广告 > 普通广告 ⚠️ 需结合 `pricing_type` 联合判断 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，缺少任何一个将导致全分区扫描，引发性能问题或数据重复：

| 过滤条件 | 推荐值 | 遗漏后果 |
|----------|--------|----------|
| `tz_type = 'local'` | `'local'`（当前 ETL 唯一写入值） | 触发全 tz_type 分区扫描，数据重复 |
| `grass_region = '<地区代码>'` | 如 `'MY'`、`'TH'`、`'PH'`（大写） | 跨地区全量扫描，性能极差且结果混杂 |
| `grass_date = DATE('yyyy-MM-dd')` | 目标快照日期 | 读取所有历史分区，数据膨胀 |

示例过滤写法：
```sql
WHERE tz_type = 'local'
  AND grass_region = 'MY'
  AND grass_date = DATE('2025-01-01')
```

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确使用方式 |
|------|----------|-------------|
| `daily_quota_local` / `daily_quota_usd` | Campaign 级别字段，placement 展开后每行均携带相同值，直接 SUM 会重复计算 | 先按 `campaign_id` 去重后再聚合，或限定单一 placement 维度统计 |
| `total_quota_local` / `total_quota_usd` | 同上，Campaign 级别，placement 展开重复 | 同上 |
| `target_roi_type` | 由 `target_roi=0` 派生的 0/1 标记字段 | 仅作过滤条件使用，不可 SUM |
| `is_ads_active` | 快照日期的派生状态字段，跨日聚合无意义 | 按单一 `grass_date` 分区使用，不可跨日累加 |
| `level*_fe_display_category_list` / `level*_kpi_category_list` | array<struct> 类型，含权重 `fraction_factor` | 需先 `EXPLODE` 展开，再按 `fraction_factor` 加权计算，不可直接聚合 |
| `keywords` | JSON 字符串存储 | 需用 `from_json` / `get_json_object` 解析后使用 |
| `level*_global_be_category` | struct 嵌套类型 | 用 `.` 操作符访问子字段，如 `.level1_global_be_category_id` |

### 时效性说明

- 本表为**每日全量快照**，每个 `grass_date` 分区存储当日截止时刻的广告状态快照。
- `is_ads_active` 字段仅对 **`grass_date` 当日**有意义，代表该日该广告是否处于活跃状态，跨日对比须各取对应日期分区。
- `campaign_start_datetime` / `campaign_end_datetime` 为字符串类型，若需判断当日是否在有效期内，应与 `grass_date` 比较（ETL 中已体现该逻辑）。
- 广告状态（`ads_status`、`campaign_status`）为快照时刻状态，分析趋势时应按日分区拉取。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_${region}_${db_type}__advertisement_tab__reg_continuous_s0_live` | 广告主表，提供广告基础字段、extinfo 扩展信息（JSON 解码）、placement、出价等核心属性 |
| `mp_paidads.dim_campaign__reg_s0_live` | Campaign 维表，提供 campaign 状态、预算配额、时间范围及 placement 级分裂配额 |
| `mp_user.dim_user__reg_s0_live` | 用户维表，提供卖家用户名（`seller_name`） |
| `mp_item.dim_item__reg_s0_live` | 商品维表，提供商品名称、创建时间、全局后台品类（global_be_category）信息 |
| `mp_item.dwd_item_fe_display_category_factor_df__reg_s0_live` | 前端展示品类因子表，提供各层级 FE 展示品类及分配因子 |
| `mp_item.dwd_item_kpi_category_factor_df__reg_s0_live` | KPI 品类因子表，提供各层级 KPI 品类及分配因子 |
| `mp_paidads.dim_product_type_mapping__reg_s0_live` | 产品类型映射表，按 `pricing_type + placement` 映射 `main_product_type`、`product_type`、`sub_product_type` |
| `mp_paidads.shopee_ads_${region}_${db_type}__target_audience_group_tab__reg_continuous_s0_live` | 目标受众群组表，提供 `ta_group_id`、`ta_premium_rate` |
| `mp_paidads.ods_shopee_paidads_index_log` | 付费广告投放索引日志，用于判断广告是否有有效投放记录（`is_ads_active` 计算依据之一） |
| `mp_paidads.ods_log_shop_ads_index_hi__reg_s0_live` | 店铺广告与直播广告实时投放索引日志，补充 `is_ads_active` 计算，含直播广告特殊逻辑 |
| `video.video_mart_dim_content` | 视频内容维表，提供视频状态（`video_status`） |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.shopee_ads_${region}_${db_type}__advertisement_tab__reg_continuous_s0_live
    │
    ├── [JSON 解码 extinfo] → 提取 keywords/boost/banner/live_stream/video/brand_max 等扩展字段
    ├── [placement 枚举展开] → placement 8/10/12/20/33/44 各自展开为子位数组（LATERAL VIEW EXPLODE）
    └── CTE: advertise_tab_df
           │
           ├── LEFT JOIN mp_user.dim_user__reg_s0_live → seller_name
           │
           ├── LEFT JOIN fe_display_category（来自 dwd_item_fe_display_category_factor_df）→ level*_fe_display_category_list
           │
           ├── LEFT JOIN kpi_category（来自 dwd_item_kpi_category_factor_df）→ level*_kpi_category_list
           │
           └── CTE: ads_item_info
                  │
                  ├── LEFT JOIN mp_paidads.dim_campaign__reg_s0_live → campaign 状态/预算/时间
                  ├── LEFT JOIN dim_campaign（EXPLODE quota_splits）→ daily_available_quota / is_budget_split
                  │
                  └── CTE: ads_campaign_info
                         │
                         ├── LEFT JOIN mp_paidads.ods_shopee_paidads_index_log  ─┐
                         ├── LEFT JOIN shop_index（ods_log_shop_ads_index_hi）   ─┤→ is_ads_active
                         │   (含直播广告特殊 session_id / LIVE_STREAM_STREAMER_ONLINE 逻辑)
                         │
                         ├── LEFT JOIN mp_item.dim_item__reg_s0_live → item_name / item_create_datetime / global_be_category
                         │
                         ├── LEFT JOIN target_audience_group_tab → ta_group_id / ta_premium_rate
                         │
                         ├── LEFT JOIN dim_product_type_mapping → main/product/sub_product_type
                         │
                         └── LEFT JOIN video.video_mart_dim_content → video_status
                                │
                                ▼
                         CTE: dim_advertise_temp
                                │
                         GROUP BY ads_id, placement（FIRST 聚合去重）
                                │
                                ▼
                  INSERT OVERWRITE dim_advertise__reg_s0_live
                  PARTITION (tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `advertise_tab_df` | `advertisement_tab__reg_continuous_s0_live` | 解码 extinfo JSON，展开 placement 数组，生成广告基础字段宽表 |
| `ads_item_ids`（cache） | `advertisement_tab__reg_continuous_s0_live` | 缓存当日所有不重复 `item_id`，用于品类信息的过滤 JOIN，提升性能 |
| `fe_display_category` | `dwd_item_fe_display_category_factor_df__reg_s0_live` | 按 item 聚合三级 FE 展示品类列表（COLLECT_LIST + FILTER） |
| `kpi_category` | `dwd_item_kpi_category_factor_df__reg_s0_live` | 按 item 聚合三级 KPI 品类列表（COLLECT_LIST + FILTER） |
| `ads_item_info` | advertise_tab_df + dim_user + fe/kpi_category | 合并卖家信息与品类信息，生成广告+商品宽表 |
| `ads_campaign_info` | ads_item_info + dim_campaign | 补充 campaign 状态、预算及分裂配额信息 |
| `shop_index`（cache） | `ods_log_shop_ads_index_hi__reg_s0_live` | 缓存店铺广告/直播广告当日投放索引日志，用于 `is_ads_active` 计算 |
| `product_type_mapping` | `dim_product_type_mapping__reg_s0_live` | 按 `pricing_type + placement` 映射产品类型三级标签 |
| `dim_video_state` | `video.video_mart_dim_content` | 获取视频广告当日状态 |
| `dim_advertise_temp` | ads_campaign_info + 多个 JOIN | 汇总所有维度字段，形成最终输出前的宽表 |

### 注意事项

1. **placement 展开导致多行**：ETL 对 placement=8、10、12、20、33、44 进行了子位数组展开（`LATERAL VIEW EXPLODE`），因此同一 `ads_id` 在同一分区内可能存在多行。**以 `ads_id + placement` 作为联合主键**，聚合时务必包含 `placement` 维度或先在 `ads_id` 粒度去重。

2. **最终写入使用 FIRST 聚合**：`INSERT OVERWRITE` 阶段对 `GROUP BY ads_id, placement` 后的所有非主键字段使用 `FIRST()` 聚合取值，理论上同组内应只有一行，若发现异常重复需检查上游数据质量。

3. **`is_ads_active` 判断逻辑复杂**：该字段综合了三个来源的投放索引记录（`ods_shopee_paidads_index_log` 历史日志、`shop_index` 当日实时日志、直播广告特殊 session 判断），同时要求 `grass_date` 落在 campaign 有效期内。若字段值异常，需核查三个来源的数据是否完整。

4. **直播广告特殊逻辑**：直播广告（`kind = 'LiveStreamAds'`）的 `is_ads_active` 判断额外区分了两种情形：① 来源为 `INDEX_TOOL_BATCH_TRIGGER`/`GDS_*` 且 `session_id != '0'`；② 来源为 `LIVE_STREAM_STREAMER_ONLINE` 且 `start_time <= timestamp`，两种情形均会将 placement=33 展开为 7 个子位。

5. **`pricing_type` NULL 处理**：ETL 对 `pricing_type` 做了 `COALESCE(pricing_type, 0)` 处理，NULL 值统一替换为 0（`DEFAULT_PRICING`），下游过滤时需注意。

6. **部分字段当前为 NULL 占位**：`language`、`tag_ids`、`is_segment_ad`、`filter_segments_*`、`premium_segments_behavior_list` 在当前 ETL 版本中固定输出 NULL 或 0，为预留字段，不可用于实际分析。

7. **时区转换机制**：时间类字段（`ads_create_datetime`、`ads_modify_datetime`、`first_delivery_datetime` 等）均经过 `SGT → UTC → 本地时区` 的二次转换（`from_utc_timestamp(to_utc_timestamp(..., 'Asia/Singapore'), '${timezone}')`），各地区按本地时区参数化调度，`tz_type='local'` 分区存储的均为本地时间。

8. **`refresh table` 前置操作**：ETL 开头对 `ods_log_shop_ads_index_hi__reg_s0_live` 执行了 `REFRESH TABLE`，以防止小文件合并导致的文件不存在问题，属于工程健壮性处理。

---

*文档生成时间：2026-04-22*