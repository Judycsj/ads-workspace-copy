<!-- ads-workspace-gdoc-sync: gdoc_id=1zGGoxqExKNsRiE28Mg8xVLUYoJapus6Y4hMmzz8xgqE gdoc_url=https://docs.google.com/document/d/1zGGoxqExKNsRiE28Mg8xVLUYoJapus6Y4hMmzz8xgqE/edit -->

# mp_paidads.dwd_request_tracking_video_hi

**分层**：DWD（数据明细层）
**主键**：`grass_region` + `grass_date` + `h` + `ads_request_id` / `raw_request_id` + `ads_id` + `operation` + `user_id`（联合标识一条追踪事件）
**分区**：`grass_region`（地区）、`grass_date`（日期）、`h`（小时）
**更新频率**：逐小时写入（`h` 分区粒度，增量覆盖写）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表记录 Shopee 视频广告（Video Ads）场景下的全量请求追踪明细事件，涵盖**曝光（IMPRESSION）、点击（CLICK）、视频观看（VIDEO_VIEW）、播放时长（VIDEO_PLAY_TIME）、播放完成（VIDEO_PLAY_COMPLETE）、商品点击（PRODUCT_CLICK）**等核心行为。数据来源于原始追踪日志 ODS 层，经解析、拆解与字段标准化后沉淀至本层，是视频广告效果分析链路中最基础的明细宽表。

本表同时支持两类投放方式：**明投（mingtou，`delivery_type=0`）** 和 **暗投（antou，`delivery_type=1`）**。明投数据从 `videos` 结构体展开而来，暗投数据从 `items` 结构体展开而来，两者通过 `UNION ALL` 合并写入同一张表。这一设计使得下游分析可以在统一口径下对比不同投放方式的广告效果，同时保留了各自的广告位（`ads_placement`）、竞价价格（`bid_price`）等关键维度。

本表是视频广告 ROI 分析、流量漏斗分析、广告创意效果评估、平台大盘视频广告监控等场景的核心数据来源，也是构建 DWS/ADS 聚合指标的主要上游输入之一。各地区按本地时区参数化调度，覆盖所有已上线的 Shopee 市场。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `grass_region` | varchar(10) | 地区编码，如 `ID`、`MY`、`SG` 等；**每次查询必须指定此分区字段** |
| `grass_date` | date | DWD 表生成日期，格式 `yyyy-MM-dd`；**每次查询必须指定此分区字段** |
| `h` | int | DWD 表生成小时，格式 `H`（0~23）；指定后可精确到小时粒度 |

---

### 维度：用户与设备标识

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `user_id` | bigint | 用户 ID，来源于 `mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live` |
| `session_id` | string | 会话 ID，与 `token` 联合用于合法性校验，来源于 ODS 追踪日志 |
| `token` | string | 请求令牌，与 `session_id` 联合用于合法性校验，来源于 ODS 追踪日志 |
| `device_id` | string | 设备 ID，用于反作弊检测，来源于 ODS 追踪日志 |
| `dfp` | string | 设备指纹（Device Fingerprint），用于欺诈分析 |
| `unique_id` | string | 唯一标识符（来源于 ODS 追踪日志顶层字段） |
| `platform` | bigint | 用户平台类型数值编码，来源于 ODS 追踪日志；具体映射见 `platform_desc` |
| `platform_desc` | string | 平台类型描述，由 `platform` 派生：`IOS_APP`、`ANDROID_APP`、`PC_MALL` 等 ⚠️ 为派生字段，由 ETL CASE WHEN 计算，不可再用于 GROUP BY 后 SUM 统计平台独立用户数，应以 `platform` 原始值为准 |
| `app_ver` | string | App 版本号 |
| `rn_ver` | string | React Native 版本号 |
| `sdk_version` | string | SDK 版本号 |
| `sdk_type` | string | SDK 类型 |
| `country` | string | 来源应用上报的国家码，如 `VN`、`ID`，由前端上报，与 `grass_region` 可能存在差异 ⚠️ 此字段由前端上报，可能存在缺失或不一致，不建议用于地区过滤，应使用分区字段 `grass_region` |

---

### 维度：请求标识

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_request_id` | string | 广告请求 ID。若命中缓存则为缓存的请求 ID，否则为原始请求 ID。搜索广告缓存在 ads engine 侧，发现广告缓存在 organic 侧。详见：https://confluence.shopee.io/x/6ZLmg ⚠️ 同一 `raw_request_id` 可能对应不同 `ads_request_id`（缓存命中场景），去重分析时需注意 |
| `raw_request_id` | string | 原始请求 ID，由 BFF 在每次新请求时生成，不受缓存影响。详见：https://confluence.shopee.io/x/6ZLmg |
| `vv_id` | string | 视频 View ID，用于标识一次视频观看会话 |
| `timestamp` | bigint | 前端生成追踪事件时的 Unix 时间戳（毫秒级），来源于 ODS 追踪日志 ⚠️ 为前端上报时间，非服务端写入时间，可能存在客户端时钟偏差 |

---

### 维度：广告主体标识

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_id` | bigint | 广告 ID，明投从 `video.json_data` 中解析，暗投取 `item.adsid` |
| `campaign_id` | bigint | 广告计划 ID。**已废弃（deprecated）**，请勿用于业务分析 ⚠️ 字段已标注 deprecated，数据可能不准确或不完整 |
| `shop_id` | bigint | 广告主店铺 ID。明投场景取 `video.shop_id`，暗投场景为 `null` ⚠️ 暗投（`delivery_type=1`）下此字段为空，需结合 `item_shop_id` 使用 |
| `account_id` | bigint | 广告账户 ID，从 `video.json_data` 中解析。暗投场景为 `null` ⚠️ 暗投场景下为空 |
| `item_id` | bigint | 商品 ID |
| `item_shop_id` | bigint | 商品归属店铺 ID |
| `creator_id` | bigint | 视频创作者用户 ID |
| `video_id` | string | 视频 ID，经 `decode_video_id` UDF 解码后的明文 ID ⚠️ 原始字段经过编码，ETL 已调用自定义 UDF `decode_video_id` 解码；如需回溯原始编码值，需查 ODS 层 |

---

### 维度：广告位与流量来源

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_placement` | bigint | 广告位 ID（最终计费口径），明投优先取 `internal.cpm_deduction_info.placement`，否则取 `placement`；暗投取 `item.internal.deduction_info.placement`。字段映射关系详见：https://docs.google.com/spreadsheets/d/142y9-AkwK_dpM7vqvmnyvhTfdaJw1virV23KAdnJQY4 ⚠️ 与 `tracking_placement` 含义不同，`ads_placement` 是广告系统内部计费用的广告位，应以此字段做广告位维度分析 |
| `tracking_placement` | bigint | 前端上报的流量来源广告位，与 `ads_entrance` 一一对应，为原始埋点值，未经广告系统修正 ⚠️ 此为前端原始值，不保证与 `ads_placement` 一致，两者含义不同 |
| `ads_entrance` | bigint | 广告流量入口编码，优先从 `json_data` 中解析 `$.entrance`，否则取顶层 `entrance` 字段 |
| `sub_entrance` | bigint | 广告流量二级入口，对 DD 和搜索流量的 entrance 做进一步细分 |
| `traffic_source` | int | 流量来源（TrackingTrafficSource 枚举值） |
| `delivery_type` | int | 投放类型：`0` = 明投（mingtou），`1` = 暗投（antou）⚠️ 明投和暗投的字段填充规则存在差异（如 `shop_id`、`account_id`、`pctr`、`pcr` 等字段暗投下为空），分析时需区分 |
| `video_ads_type` | int | 视频广告类型：`0` = product_ads，`1` = video_ads。暗投场景为 `null` ⚠️ 暗投场景下为空 |
| `display_ad_tag` | int | 是否展示广告标签的标记位 |

---

### 维度：页面与内容上下文

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `page_type` | string | 页面类型，如 `image_search`、`search`、`shop`、`me` 等 |
| `page_section` | string | 页面分区，如 `search`、`rcmd`、`you_may_also_like` 等 |
| `current_page` | string | 当前页面标识，如 `content_mix_feed`、`common_video_trending_page`、`dd_video_new_landing_page`，来源于 `video_props` |
| `content_type` | string | 内容类型，如 `shopee_video`、`item`，来源于 `video_props` |
| `content_id` | string | 内容 ID，来源于 `video_props` |
| `content_mix_frame_tab_name` | int | 内容混合帧 Tab 枚举值：`0`=Unknown，`1`=LiveTab，`2`=ForYouTab，`3`=VideoTab，`4`=DiscoverTab，来源于 `video_props` |
| `sv_source_page` | string | 短视频来源页面，如 `video_tab`、`iaa_srp_video_card`、`app_auto_streaming`，来源于 `video_props` |
| `trigger_mode` | string | 触发模式，如 `anchor_product`、`comment_product`，来源于 `video_props` |
| `target_type` | string | 广告目标类型，如 `item`、`video`。`PRODUCT_CLICK`（operation=14）时优先取 `video_item.target_type`，否则取 `video.target_type` |
| `search_entrance` | string | 搜索入口标识 ⚠️ ETL SQL 中未显式赋值此字段，可能来自 ODS 层顶层字段透传，实际值需核查 ODS 层 |

---

### 维度：广告行为事件

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `operation` | bigint | 追踪事件操作类型数值：`1`=IMPRESSION，`2`=CLICK，`14`=PRODUCT_CLICK，`21`=VIDEO_VIEW，`22`=VIDEO_PLAY_TIME，`23`=VIDEO_PLAY_COMPLETE |
| `operation_desc` | string | 操作类型描述，由 `operation` 派生的 CASE WHEN 字段 ⚠️ 为派生字段，与 `operation` 完全对应，不可独立 COUNT DISTINCT |
| `click_area` | bigint | 用户点击区域：`0`=UNKNOWN，`1`=ITEM，`2`=BUY_NOW，`3`=ADD_TO_CART |

---

### 维度：商品与视频属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `organic_location` | bigint | 本商品/视频在整体列表（包含广告和自然结果）中的索引位置，从 0 开始 |
| `location_in_ads` | bigint | 本商品在广告返回列表中的索引位置，从 0 开始 |
| `item_price` | bigint | 商品价格。明投从 `json_data` 中解析；暗投根据 entrance 和 placement 做条件判断，从 `extra_json` 的 `bid-infos` 或 `json_data` 中提取，并除以 100000 换算 ⚠️ 明投和暗投的取值逻辑不同，暗投已除以 100000 换算为标准单位；明投未做换算。跨 delivery_type 对比时需注意单位一致性 |
| `sold_cnt` | bigint | 商品已售数量，明投从 `json_data` 解析，暗投取 `item.product_card.sold_count` |
| `video_duration` | bigint | 视频时长，明投取 `video.duration`，暗投场景为 `null` ⚠️ 暗投场景下为空 |
| `video_json_data` | string | 视频附加信息 JSON 字符串，明投取 `video.json_data`，暗投为 `null` ⚠️ 暗投场景下为空；JSON 内容为半结构化，需用 `get_json_object` 解析指定字段 |
| `internal` | struct<cpm_deduction_info:struct<cpm:bigint,ads_id:bigint,placement:int>,event_id:string,duplicate_label:int> | 视频广告内部信息结构体，包含 CPM 扣费信息（cpm、ads_id、placement）、事件 ID、去重标签 ⚠️ 嵌套 struct 类型，查询时需用点号访问子字段，如 `internal.cpm_deduction_info.cpm`；`duplicate_label` 可用于过滤重复事件 |

---

### 维度：A/B 测试与实验

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ab_sign` | string | 后端 A/B 实验签名，明投从 `json_data` 中解析 |
| `fe_ab_sign` | string | 前端 A/B 实验签名，仅存储前端侧 A/B 结果 ⚠️ 后端实验分析请使用 `ab_sign`，此字段仅用于前端实验，两者含义不同，请勿混用 |

---

### 维度：定价与竞价策略

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `pricing_type` | int | 广告计费类型：`0`=DEFAULT_PRICING，`1`=MANUAL_MODE_CPC，`2`=ENHANCED_CPC，`3`=BOOST_ADS_PRICING，`4`=SIMPLE_MODE_PRICING，`5`=COST_PER_TIME，`6`=COST_PER_MILE，`7`=AUTO_BOOST_PRICING |
| `bid_rerank_trace` | string | 竞价重排序追踪信息，经 `bid_info_decode_fuc` UDF 解码后的字符串 ⚠️ 原始数据经自定义 UDF `bid_info_decode_fuc` 解码，内部格式需结合 UDF 文档理解 |

---

### 指标：竞价与预估模型指标

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `bid_price` | decimal(25,10) | 广告出价。明投从 `json_data.$.bid_price` 解析；暗投取 `item.internal.deduction_info.bidprice / 100000` ⚠️ 明投和暗投的单位换算逻辑不同，暗投已做 /100000 换算，跨 delivery_type 聚合时需确认口径一致性；此为请求时刻快照值，不可直接 AVG 作为账户维度均价 |
| `initial_cpm` | bigint | 初始 CPM，明投从 `json_data` 解析，暗投为 `null` ⚠️ 暗投场景下为空 |
| `pctr` | decimal(25,10) | 预估点击率（predict Click-Through Rate），明投从 `json_data` 解析，暗投为 `null` ⚠️ 为模型预测值，不可直接 SUM/AVG 作为实际 CTR，需结合实际点击数和曝光数重新计算；暗投场景下为空 |
| `pcr` | decimal(25,10) | 预估转化率（predict Conversion Rate），明投从 `json_data` 解析，暗投为 `null` ⚠️ 为模型预测值，不可直接 SUM/AVG 作为实际转化率；暗投场景下为空 |
| `broad_pcr` | decimal(25,10) | 宽口径预估转化率（broad predict Conversion Rate），明投从 `json_data` 解析，暗投为 `null` ⚠️ 为模型预测值，不可直接 SUM/AVG；暗投场景下为空 |
| `target_cir` | decimal(25,10) | 目标投产比（target Cost-Income Rate）。暗投根据 entrance 和 placement 条件判断来源字段 ⚠️ 为广告系统目标设定值，非实际投产比；不可直接 SUM |
| `pid_coef` | decimal(25,10) | PID 调控系数，明投从 `json_data` 解析，暗投为 `null` ⚠️ 为广告系统内部调控参数，不可直接 SUM/AVG，暗投场景下为空 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下分区字段**，否则将触发全表扫描，导致资源浪费和查询超时：

| 分区字段 | 类型 | 说明 |
|----------|------|------|
| `grass_region` | varchar(10) | 必须指定，如 `grass_region = 'ID'` 或 `grass_region IN ('ID', 'MY', 'SG')` |
| `grass_date` | date | 必须指定，如 `grass_date = '2026-03-31'` 或 `grass_date BETWEEN '2026-03-01' AND '2026-03-31'` |
| `h` | int | 若分析整天数据可省略；若需小时粒度，务必指定，如 `h = 15` |

**遗漏后果**：本表为 hi（小时级）分区宽表，全表数据量极大，未指定分区直接查询将扫描所有地区所有日期所有小时的历史数据，极有可能导致集群资源耗尽或任务被 kill。

**补充推荐过滤条件**：
- 使用 `delivery_type` 区分明投/暗投，避免口径混淆：`delivery_type = 0`（明投）或 `delivery_type = 1`（暗投）
- 使用 `operation` 过滤关注的事件类型，如仅统计曝光：`operation = 1`，仅统计点击：`operation = 2`
- 使用 `internal.duplicate_label` 过滤重复事件（具体过滤逻辑请结合业务口径确认）

---

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确计算方式 |
|------|----------|--------------|
| `pctr` | 模型预测值，每条事件的预估值含义不同，直接 SUM/AVG 无实际意义 | 用实际点击数 ÷ 实际曝光数重新计算实际 CTR |
| `pcr` | 同上，为预估转化率 | 用实际转化数 ÷ 实际点击数或曝光数重新计算 |
| `broad_pcr` | 同上，为宽口径预估转化率 | 同上 |
| `target_cir` | 为广告系统目标设定值，非实际度量值 | 结合实际 GMV 和消耗数据计算实际 CIR |
| `pid_coef` | 为广告系统内部调控参数，非可加指标 | 仅用于调试分析，不适合聚合 |
| `bid_price` | 为单次请求时刻的出价快照，跨 delivery_type 单位不一致 | 明投和暗投需分别分析；如需均价，应先确认单位后再做 AVG |
| `item_price` | 明投未除以 100000，暗投已除以 100000，单位不一致 | 跨 delivery_type 聚合前必须统一单位换算 |
| `platform_desc` | 由 `platform` 派生的描述字段 | 分组过滤应使用 `platform` 原始值，`platform_desc` 仅用于展示 |
| `operation_desc` | 由 `operation` 派生的描述字段 | 分组过滤应使用 `operation` 数值 |

---

### 时效性说明

本表为小时级增量覆盖写入，每个 `(grass_region, grass_date, h)` 分区在对应调度周期完成后即可用。若需分析某一天的完整数据，应确保 `h` 的所有分区（0~23）均已写入完成，或取 `grass_date < CURRENT_DATE` 的历史日期以避免读取到未完成写入的当日数据。

`timestamp` 字段为前端事件产生时间，与 `grass_date + h` 分区时间存在调度延迟，不可将其等同于分区时间。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live` | 核心上游原始追踪日志 ODS 表，提供所有追踪事件的原始字段（`userid`、`sessionid`、`deviceid`、`platform`、`timestamp`、`token`、`videos`、`items`、`operation`、`placement` 等），明投和暗投数据均来源于此表 |

---

## ETL 逻辑摘要

### 数据流

```
mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
         │
         ├─── [明投分支] LATERAL VIEW EXPLODE(videos) AS video
         │         │
         │         └─── LATERAL VIEW OUTER EXPLODE(video_items) AS video_item
         │                   │
         │         temporary view: tracking_table_video_mingtou
         │                   │
         │              SELECT + 字段解析（json_data / struct 字段展开）
         │              delivery_type = 0
         │
         └─── [暗投分支] LATERAL VIEW EXPLODE(items) AS item
                   │
         temporary view: tracking_table_video_antou
                   │
              SELECT + 字段解析（json_data / extra_json / internal struct）
              delivery_type = 1

         明投结果 UNION ALL 暗投结果
                   │
                   ▼
     [Hive Parquet 外部表]
     mp_paidads.dwd_request_tracking_video_hi__reg_s0_live
     INSERT OVERWRITE PARTITION (grass_region, grass_date, h)
     存储路径: hdfs://R2/projects/data_paidadsmart/hive/mp_paidads/dwd_request_tracking_video_hi
```

### 关键 CTE 说明

| 临时视图 | 来源表 | 作用 |
|----------|--------|------|
| `tracking_table_video_mingtou` | `ods_log_ads_tracking_hi__reg_s0_live` | 明投（mingtou）数据分支：展开 `videos` 数组，再对每条 video 展开 `video.items` 数组，过滤 `operation IN (1,2,14,21,22,23)` 且 `size(videos) > 0` |
| `tracking_table_video_antou` | `ods_log_ads_tracking_hi__reg_s0_live` | 暗投（antou）数据分支：展开 `items` 数组，过滤 `operation IN (1,2,21,22,23)`，并按 entrance（29,33,34,50,54,55,56,58,62,63,64 或 entrance IN(1,3) 且 `target_type='video'`）筛选视频广告流量，排除 `internal.deduction_info.placement = 54` |

### 注意事项

1. **明投与暗投数据口径差异**：两个分支通过 `UNION ALL` 合并，但字段填充规则存在明显差异。暗投（`delivery_type=1`）下，`shop_id`、`account_id`、`video_json_data`、`pctr`、`pcr`、`broad_pcr`、`initial_cpm`、`pid_coef`、`video_ads_type`、`video_duration` 均为 `null`。分析时务必先用 `delivery_type` 区分，避免 null 值影响聚合结果。

2. **价格字段单位不一致**：`item_price` 和 `bid_price` 在暗投分支中已做 `/100000` 换算，而明投分支直接取 `json_data` 原始值。跨 `delivery_type` 聚合前必须确认单位口径一致性。

3. **ads_placement 过滤规则**：暗投分支 ETL 中已过滤 `item.internal.deduction_info.placement NOT IN (54)`，即排除了 placement=54 的流量。明投分支无此过滤。

4. **UDF 依赖**：ETL 使用两个自定义 UDF：`decode_video_id`（解码视频 ID）和 `bid_info_decode_fuc`（解码竞价重排序信息）。这两个字段的原始值存储在 ODS 层，如需原始编码值需查询上游。

5. **PRODUCT_CLICK（operation=14）特殊处理**：`target_type` 字段在 `operation=14` 时优先使用 `video_item.target_type`，其他场景取 `video.target_type`，分析商品点击行为时需注意此逻辑。

6. **video_id 来源差异**：明投取 `video.video_id` 经 UDF 解码；暗投取 `COALESCE(item.item_rcmd_props.video_id, item.item_video.display_video_id_encoded)` 经 UDF 解码，两个来源字段不同，关联分析时注意。

7. **ads_entrance 解析优先级**：两个分支均优先从 `json_data` 中取 `$.entrance`，降级取顶层 `entrance` 字段，存在数据优先级差异。

8. **参数化调度**：ETL SQL 中出现的具体地区（`AR`、`BR`、`ID` 等）和日期（`2026-03-31`）、小时（`15`）均为调度模板的参数化实例，实际生产调度通过 `${region}`、`${grass_date}`、`${h}` 参数覆盖所有地区和时间分区，各地区按本地时区参数化调度。

---

*文档生成时间：2026-05-20*