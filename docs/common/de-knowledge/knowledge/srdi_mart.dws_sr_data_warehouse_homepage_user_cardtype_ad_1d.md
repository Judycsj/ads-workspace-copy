<!-- ads-workspace-gdoc-sync: gdoc_id=1Pw3YGwwJVI_zFcg7IPTEFxe1hekhWKbThRsY7NbIeKo gdoc_url=https://docs.google.com/document/d/1Pw3YGwwJVI_zFcg7IPTEFxe1hekhWKbThRsY7NbIeKo/edit -->

# srdi_mart.dws_sr_data_warehouse_homepage_user_cardtype_ad_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `user_id` + `card_type` + `is_ads`
**分区：** `grass_region`（地区）、`local_date`（业务日期）
**更新频率：** 每日全量覆盖写入（INSERT OVERWRITE）
**访问频次：** 811 次

---

## 业务描述

本表是首页 Daily Discover（每日发现）频道的**用户 × 卡片类型 × 是否广告**维度日粒度汇总宽表，记录每个用户在不同卡片类型（商品卡、视频卡、直播卡、Banner 等）及广告/自然流量维度下的全链路行为指标，涵盖曝光、点击、商品详情页访问、成交、时长、视频播放等核心漏斗节点。

**核心业务场景：**
- 首页 Daily Discover 各卡片类型的用户行为分析与漏斗分析
- 广告 vs. 自然流量的用户消费路径对比
- 用户购买类型、平台、版本等维度的分层人群分析
- 卡片位置（`location`）与各指标的相关性分析

**适合回答的问题：**
- 每日各卡片类型的曝光/点击/成交转化率是多少？
- 广告卡片与自然卡片的 GMV 贡献各占多少？
- 不同用户购买类型（`user_purchase_type`）在 Daily Discover 上的行为差异？
- 视频卡、直播卡的用户播放次数（VV）和停留时长分布？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区标识，如 ID、MY、TH 等，用于多区域分区隔离 |
| `local_date` | date | 业务日期（本地日期），每日一分区 |

### 维度：用户属性

| 字段名 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，来自 `dim_sr_data_warehouse_user_label` 关联 |
| `user_purchase_type` | string | 用户购买类型标签，如新用户、回流用户等，来源于用户标签维表 |
| `platform` | string | 用户使用平台，如 iOS、Android 等，来源于用户标签维表 |
| `app_version_prefix` | string | App 版本前缀，用于区分不同版本用户群体，来源于用户标签维表 |

### 维度：内容与流量类型

| 字段名 | 类型 | 说明 |
|---|---|---|
| `card_type` | string | 卡片类型，如 `item`、`video`、`LS`（直播）、`item_mix_feed_card`、`item_feed_card`、`banner`、`campaign`、`food`、`insurance`、`local service`、`DP` 等 |
| `is_ads` | bigint | 是否广告流量，1 表示广告，0 表示自然流量 |
| `location` | bigint | 卡片在 Daily Discover 中的展示位置编号，取该用户当日最大位置值 |

### 指标：曝光与点击

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 卡片曝光次数，来源于首页用户商品行为表，仅统计 `feature_detail like 'home-daily_discover-%'` 的记录 |
| `click_cnt` | bigint | 卡片点击次数，来源同上 |

### 指标：商品详情页访问

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 商品详情页（PDP）访问次数，来源于用户商品行为表（含归因链路追溯） |
| `minippv_cnt` | bigint | 广告/自然流量 mini PDP 访问次数，来源于 `dws_business_line_sales_funnel_metrics_1d` |

### 指标：成交与 GMV

| 字段名 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 订单数，排除 `shopeepay_near_me` 和 `digital_product` 品类的订单 |
| `gmv` | double | 成交金额（USD），排除 `shopeepay_near_me` 和 `digital_product` 品类 |
| `pc2_gmv` | double | PC2 口径 GMV，来源于用户商品行为表，含全品类 |

### 指标：视频与内容消费

| 字段名 | 类型 | 说明 |
|---|---|---|
| `vv` | bigint | 视频播放次数，来源于视频域 `video_mart_dws_external_dd_mixfeed_ssecid_user_1d`，限 `mix_feed_page`、`common_video_feed_page`、`dd_video_new_landing_page` 场景 |
| `internal_scroll_depth` | bigint | 用户在内容 Feed（视频卡/混合卡）内的最大滑动深度（`index`），取当日最大值 |

### 指标：用户停留时长

| 字段名 | 类型 | 说明 |
|---|---|---|
| `self_duration` | double | 用户在该卡片类型上的自身停留时长（秒），如商品卡封面停留时长 |
| `landing_page_duration` | double | 用户进入卡片落地页（视频页、直播间、mini feed 页等）的停留时长（秒） |
| `pdp_page_duration` | double | 用户在商品详情页（PDP）的停留时长（秒），区分广告与自然 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 为分区字段，**每次查询必须同时指定这两个分区条件**，否则将触发全表扫描，影响性能并产生高额费用。
- 例：`WHERE grass_region = 'ID' AND local_date = '2024-01-01'`

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `location` | 通过 `MAX` 聚合得出，表示该用户当日卡片最大位置编号，跨用户直接 SUM 无业务意义 |
| `internal_scroll_depth` | 通过 `MAX` 聚合得出，跨用户直接 SUM 无业务意义 |
| `self_duration` / `landing_page_duration` / `pdp_page_duration` | 为时长累加值，跨 `card_type` 或 `is_ads` 维度聚合前需确认口径一致性，避免重复计算 |
| `order_cnt` / `gmv` | 已排除 `shopeepay_near_me`、`digital_product` 品类，跨表对比时需注意口径差异 |

### 时效性说明

- 本表为 **日粒度（`_1d`）** 表，每日 T+1 全量覆盖写入当日分区。
- `internal_scroll_depth` 来源于 HiveInstant 明细表（`video_mart_dwd_external_dd_mixfeed_traffic_hi`），时效与视频域上游一致。
- `minippv_cnt` 来源于 `traffic_omni_oa` 域，如该域存在延迟则本表对应指标存在滞后风险。

### 数据口径注意事项

- `is_ads = 1` 表示广告流量，`is_ads = 0` 表示自然流量；`minippv_cnt` 通过广告/自然分别拆行写入，统计时需注意 `is_ads` 维度。
- `card_type` 的值来源于多个上游表，通过 UDF `get_dd_cardtype()` 映射，不同 UDF 版本可能影响分类结果。
- `order_cnt`、`gmv` 仅来自商品类目，不含本地服务（`shopeepay_near_me`）和数字商品（`digital_product`）；若需全品类成交，需结合 `dwm_dd_others_user_location` 口径补充。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_homepage_user_item` | 提供首页 Daily Discover 的用户商品曝光、点击、订单、GMV、PPV 及位置信息（使用两次，分别用于 imp/click 口径和订单归因口径） |
| `srdi_mart.dwm_sr_data_warehouse_dd_others_user_location` | 提供 food、insurance、banner、campaign、local service、DP 等特殊卡片类型的订单数、GMV 和 PPV |
| `srdi_mart.dws_sr_data_warehouse_homepage_user_duration_1d` | 提供用户在各 Daily Discover 卡片类型（商品卡、视频卡、直播卡、mini feed 卡、混合卡等）的停留时长 |
| `video.video_mart_dws_external_dd_mixfeed_ssecid_user_1d` | 提供视频卡、混合卡的用户视频播放次数（VV） |
| `video.video_mart_dwd_external_dd_mixfeed_traffic_hi` | 提供视频卡、混合卡内用户最大滑动深度（internal scroll depth） |
| `traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live` | 提供 Daily Discover 归因的 mini PDP 访问次数（广告/自然分拆） |
| `srdi_mart.dim_sr_data_warehouse_user_label` | 提供用户维度标签：`platform`、`app_version_prefix`、`user_purchase_type` |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_homepage_user_item （两次读取）
dwm_sr_data_warehouse_dd_others_user_location
dws_sr_data_warehouse_homepage_user_duration_1d
video_mart_dws_external_dd_mixfeed_ssecid_user_1d
video_mart_dwd_external_dd_mixfeed_traffic_hi
dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live
            ↓ 各自构建 Temporary View
            ↓ UNION ALL 合并为 union_data_result（按 user_id, card_type, is_ads 聚合）
            ↓ LEFT JOIN dim_sr_data_warehouse_user_label（补充用户属性）
            ↓ INSERT OVERWRITE 写入目标表分区
```

### 关键步骤

| 步骤 | Temporary View 名称 | 说明 |
|---|---|---|
| Step 1 | `dwm_homepage_user_item` | 从首页用户商品表读取曝光/点击数据，限定 `feature_detail like 'home-daily_discover-%'`，按卡片类型映射规则统一 `card_type` |
| Step 2 | `dwm_homepage_user_item_order_ppv` | 再次读取首页用户商品表，获取含归因链路（source1、source2）的订单、GMV、PPV，排除本地服务和数字商品品类 |
| Step 3 | `dwm_dd_others_user_location` | 从特殊卡片位置表读取 food、insurance 等品类的订单和 PPV |
| Step 4 | `dws_homepage_user_duration`（CACHE） | 缓存用户时长表（过滤 `user_id > 0`），供后续时长计算复用 |
| Step 5 | `dws_homepage_user_card_ads_duration` | 将缓存的时长表按卡片类型和广告标识拆解为多行，通过 UNION ALL 展开为 `(user_id, card_type, is_ads, self_duration, landing_page_duration, pdp_page_duration)` |
| Step 6 | `vv_data` | 从视频域汇总表读取 Daily Discover 视频/混合卡的用户播放次数 |
| Step 7 | `internal_scroll_depth` | 从视频域明细表解析 JSON 字段，提取用户在 Feed 内的最大滑动深度 |
| Step 8 | `minippv_data_base` | 从销售漏斗指标表读取 Daily Discover 归因的 mini PDP 曝光数，区分广告/自然 |
| Step 9 | `minippv_data_result` | 将 `minippv_data_base` 拆分为广告行（`is_ads=1`）和自然行（`is_ads=0`） |
| Step 10 | `union_data_result` | 将以上所有 Temporary View 通过 UNION ALL 合并，补 0 填充不适用指标列，再按 `(user_id, card_type, is_ads)` 聚合（SUM/MAX） |
| Step 11 | `dim_user` | 从用户标签维表读取 `platform`、`app_version_prefix`、`user_purchase_type` |
| Step 12 | INSERT OVERWRITE | `union_data_result` LEFT JOIN `dim_user`，写入目标表分区 `(grass_region, local_date)` |

### 注意事项

- **单 Writer，无并发写入风险：** 本表仅由单个 ETL 文件写入（`multi_writer = false`），不存在多 Writer 分区竞争问题。
- **分区覆盖写入：** 每次执行为 `INSERT OVERWRITE` 指定分区，历史分区数据会被完整替换，重跑安全。
- **`dwm_sr_data_warehouse_homepage_user_item` 被读取两次：** Step 1 用于曝光/点击口径（限 `feature_detail`），Step 2 用于订单/GMV/PPV 口径（含归因 source1/source2），两次过滤条件不同，需注意数据范围差异。
- **跨域依赖：** 本表依赖 `video` 域和 `traffic_omni_oa` 域的表，若这些上游域存在调度延迟或分区缺失，目标表对应指标将为 0 或空，需监控上游 SLA。
- **UDF 依赖：** `get_dd_cardtype()` 是关键映射 UDF，其版本更新会影响 `card_type` 的分类结果，排查数据异常时需关注 UDF 变更记录。
- **`location` 字段含义：** 使用 `MAX` 聚合，表示该用户当日在 Daily Discover 中触达的最大位置编号，非平均位置或唯一位置，使用时需注意语义。

---

*文档生成时间：2026-05-17*