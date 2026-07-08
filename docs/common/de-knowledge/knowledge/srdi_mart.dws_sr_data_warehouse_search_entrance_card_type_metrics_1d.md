<!-- ads-workspace-gdoc-sync: gdoc_id=1pDj_9WShKn9dZX13tSJ5o9MuVqsq5eJOyV4T3GXz5XY gdoc_url=https://docs.google.com/document/d/1pDj_9WShKn9dZX13tSJ5o9MuVqsq5eJOyV4T3GXz5XY/edit -->

# srdi_mart.dws_sr_data_warehouse_search_entrance_card_type_metrics_1d

**分层：** dws_search  
**主键：** card_type, search_entrance, is_ads, location, with_item, grass_region, local_date  
**分区：** grass_region, local_date  
**更新频率：** 每日一次（T+1）  
**引用频次/访问频次：** 1353  

---

## 业务描述

本表是搜索域的核心宽表，面向**全球搜索（Global Search）**业务，按照「搜索入口 × 卡片类型 × 广告标识 × 位置区间 × 是否携带商品」的多维组合，聚合每日搜索场景下的曝光、点击、购买转化、GMV、广告表现、视频/直播侧指标、留存、搜索量及无召回率等全链路核心指标。

**核心业务场景：**
- 搜索各入口（普通搜索、直播搜索、视频搜索、内容混搜等）的流量与转化表现分析
- 商品卡（item）、视频卡（video）、直播卡（livestream）及混合卡类型的对比分析
- 广告（is_ads=true）与自然流量（is_ads=false）的指标拆分
- 搜索驱动的直播/视频侧 GMV、时长等内容电商指标分析
- 关键词无召回率、搜索成功率等搜索质量评估
- 广告负载（ads_load）、广告营收（ads_rev）等广告健康度指标

**适合回答的问题：**
- 某地区某日各搜索入口的曝光、点击、转化漏斗表现如何？
- 视频卡/直播卡相较于商品卡的用户行为差异？
- 广告搜索 session 占比及广告负载情况？
- 搜索引发的直播/视频观看时长、成单量及 GMV 贡献？
- 用户次日/7日留存及搜索量趋势？
- 去异常值后（995 截断）的 GMV 及 PC2 GMV 表现？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/国家标识，如 SG、MY、TH 等，分区键 |
| `local_date` | date | 业务日期（本地时区），分区键 |

---

### 维度：搜索行为维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_entrance` | string | 搜索入口，如 `live_search`、`video_search`、`content_mix_search`、`NA`；`all_content_search` 为内容搜索汇总；`not_content_search` 为非内容搜索汇总；`__ALL__` 为全入口汇总 |
| `card_type` | string | 搜索结果卡片类型，取值：`item`（商品卡）、`video`（视频卡）、`livestream`（直播卡）、`item+video+live`（全类型汇总） |
| `is_ads` | string | 是否广告流量，`true`/`false`；`__ALL__` 为全量汇总 |
| `location` | string | 搜索结果位置区间，取值：具体位置编号（0~99）、`0~3`、`0~9`、`0~19`、`NA`（位置超出范围）、`__ALL__`（全位置汇总） |
| `with_item` | string | 该用户-关键词组合是否有商品级别数据，`true`/`false`；`__ALL__` 为全量汇总 |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 搜索结果曝光次数（PV） |
| `imp_uu` | bigint | 曝光独立用户数（UV），imp_cnt > 0 的去重用户数 |
| `click_cnt` | bigint | 点击次数（PV） |
| `click_uu` | bigint | 点击独立用户数（UV） |
| `ppv_cnt` | bigint | 商品详情页浏览次数（PDP PV） |
| `ppv_uu` | bigint | 商品详情页浏览独立用户数 |
| `search_scene_imp_cnt` | bigint | 涵盖更广搜索场景（含站内搜索、主分类等）的曝光总次数；仅在 `card_type='item+video+live'`、`location='__ALL__'`、`with_item='__ALL__'`、`is_ads='__ALL__'` 时有值 |
| `paidads_imp_cnt` | bigint | 付费广告曝光次数；来自广告投放系统，仅在 `card_type='item+video+live'`、`is_ads='__ALL__'` 时有值 |

---

### 指标：购物转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数 |
| `cart_uu` | bigint | 加购独立用户数 |
| `order_cnt` | double | 订单数（含分拆订单，支持小数） |
| `order_uu` | bigint | 下单独立用户数 |
| `gmv` | double | 搜索归因 GMV（美元） |
| `pc2_gmv` | double | 搜索归因 PC2 GMV（美元，PC2 口径） |

---

### 指标：广告表现

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_load` | double | 广告负载率 = `paidads_imp_cnt` / `ads_load_denom_imp_cnt`（分母为更宽口径搜索页曝光数）；派生比率，不可直接 SUM；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'` 时有值 |
| `ads_rev` | double | 广告营收（美元），来自付费广告投放系统（`expenditure_amt_usd`）；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'` 时有值 |
| `all_ads_session_cnt` | bigint | 所有曝光均为广告的 session 数量（全广告 session 数）；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'` 时有值 |
| `search_session_cnt` | bigint | 搜索 session 总数；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'` 时有值 |

---

### 指标：GMV 去异常值（995 截断 v1）

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv_995` | double | 按用户级别 ABS（平均订单价值）过滤 99.5 分位数异常值后的 GMV；仅在 `location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `gmv_uu_995` | double | 去异常值后 GMV 除以符合条件的曝光用户数；派生比率，不可直接 SUM |
| `pc2_gmv_995` | double | 去异常值后的 PC2 GMV |
| `pc2_gmv_uu_995` | double | 去异常值后 PC2 GMV 除以符合条件的曝光用户数；派生比率，不可直接 SUM |

---

### 指标：GMV 去异常值（995 截断 v2，按品类分层）

| 字段 | 类型 | 说明 |
|---|---|---|
| `high_gmv_995_v2` | double | 高 GMV 品类（`category_tag='high gmv'`）按订单级 995 分位截断后的 GMV；仅在 `location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `high_gmv_order_cnt_995_v2` | double | 高 GMV 品类 995 截断后的订单数 |
| `high_pc2_gmv_995_v2` | double | 高 GMV 品类 995 截断后的 PC2 GMV |
| `low_gmv_995_v2` | double | 低 GMV 品类（`category_tag='low gmv'`）按订单级 995 分位截断后的 GMV；仅在 `location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `low_gmv_order_cnt_995_v2` | double | 低 GMV 品类 995 截断后的订单数 |
| `low_pc2_gmv_995_v2` | double | 低 GMV 品类 995 截断后的 PC2 GMV |

---

### 指标：搜索量与搜索质量

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_volume` | bigint | 有效搜索量（`(user_id, device_id, keyword)` 去重，需 view_cnt > 0）；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `direct_search_success_volume` | bigint | 直接搜索成功量（点击了商品/视频/直播卡的关键词去重数）；同上条件下有值 |
| `broad_search_success_volume` | bigint | 广义搜索成功量（含店铺/创作者等更宽口径点击的关键词去重数）；同上条件下有值 |
| `norecall_rate` | double | 无召回率 = 无召回关键词数 / 有效关键词总数；派生比率，不可直接 SUM；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `search_uu` | bigint | 当日有搜索行为（view_cnt > 0）的独立用户数；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值 |

---

### 指标：用户留存

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_uu_1d` | bigint | 前 1 日有搜索行为的用户数（留存分母）；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `retention_uu_1d` | bigint | 前 1 日有搜索且当日也有搜索行为的用户数（1 日留存分子）；同上条件 |
| `search_uu_7d` | bigint | 前 7 日有搜索行为的用户数（7 日留存分母）；同上条件 |
| `retention_uu_7d` | bigint | 前 7 日有搜索且当日也有搜索行为的用户数（7 日留存分子）；同上条件 |

---

### 指标：时长（人均，派生比率）

| 字段 | 类型 | 说明 |
|---|---|---|
| `srp_duration_per_uu` | double | 搜索结果页（SRP）人均停留时长（毫秒/人），= srp_duration / search_uu；派生比率，不可直接 SUM；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `pdp_duration_per_uu` | double | 商品详情页（PDP）人均停留时长（毫秒/人），= pdp_duration / search_uu；派生比率，不可直接 SUM；同上条件 |
| `video_duration_per_uu` | double | 视频人均观看时长（毫秒/人），= video_duration / search_uu；派生比率，不可直接 SUM；仅在 `is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `live_duration_per_uu` | double | 直播人均观看时长（秒/人），= search_to_live_duration_time / search_uu；派生比率，不可直接 SUM；仅在 `is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值 |

---

### 指标：搜索结果位置分布

| 字段 | 类型 | 说明 |
|---|---|---|
| `first_click_location_avg` | double | session 内首次点击位置均值；仅在 `card_type='item+video+live'`、`is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值；派生均值，不可直接 SUM |
| `first_click_location_p50` | double | session 内首次点击位置中位数（P50）；同上条件；分位数，不可直接 SUM |
| `max_imp_location_avg` | double | session 内最大曝光位置均值；同上条件；派生均值，不可直接 SUM |
| `max_imp_location_p50` | double | session 内最大曝光位置中位数（P50）；同上条件；分位数，不可直接 SUM |

---

### 指标：搜索引导视频侧

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_to_video_viewer` | bigint | 通过搜索触达视频的独立观看用户数；仅在 `search_entrance='__ALL__'`、`is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `search_to_video_vv` | bigint | 通过搜索触达视频的播放次数（VV） |
| `search_to_video_duration_time` | bigint | 通过搜索触达视频的总观看时长（毫秒） |
| `search_to_video_order` | double | 通过搜索触达视频产生的订单数 |
| `search_to_video_gmv` | double | 通过搜索触达视频产生的 GMV（美元） |
| `all_video_side_viewer` | bigint | 视频侧全量独立观看用户数（不限搜索来源） |
| `all_video_side_vv` | bigint | 视频侧全量播放次数（VV） |
| `all_video_side_duration_time` | bigint | 视频侧全量观看时长（毫秒） |
| `all_video_side_order` | double | 视频侧全量订单数 |
| `all_video_side_gmv` | double | 视频侧全量 GMV（美元） |

---

### 指标：搜索引导直播侧

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_to_live_viewer` | bigint | 通过搜索进入直播间的独立用户数；仅在 `is_ads='__ALL__'`、`location='__ALL__'`、`with_item='__ALL__'` 时有值 |
| `search_to_live_view_pv` | bigint | 通过搜索进入直播间的观看 PV |
| `search_to_live_duration_time` | bigint | 通过搜索进入直播间的总观看时长（秒） |
| `search_to_live_order` | double | 通过搜索进入直播间产生的订单数 |
| `search_to_live_gmv` | double | 通过搜索进入直播间产生的 GMV（美元） |
| `all_live_side_viewer` | bigint | 直播侧全量独立观看用户数 |
| `all_live_side_view_pv` | bigint | 直播侧全量观看 PV |
| `all_live_side_duration_time` | bigint | 直播侧全量观看时长（秒） |
| `all_live_side_order` | double | 直播侧全量订单数 |
| `all_live_side_gmv` | double | 直播侧全量 GMV（美元） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定两个分区字段**：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-05-16'
  ```
- 若仅需分析全量汇总数据，应额外过滤：`card_type = 'item+video+live'`、`search_entrance = '__ALL__'`、`is_ads = '__ALL__'`、`location = '__ALL__'`、`with_item = '__ALL__'`。
- 各维度的 `__ALL__` 值为该维度下的全量预聚合，**不要对含 `__ALL__` 和具体维度值的数据混合进行 SUM**，否则会导致重复计算。

### 不可直接 SUM 的字段

以下字段为派生比率、均值或分位数，跨行聚合需重新用原始分子/分母计算：

| 字段 | 原因 |
|---|---|
| `ads_load` | 派生比率，= paidads_imp_cnt / ads_load_denom_imp_cnt |
| `norecall_rate` | 派生比率 |
| `gmv_uu_995` | 派生比率，= gmv_995 / 去重用户数 |
| `pc2_gmv_uu_995` | 派生比率 |
| `srp_duration_per_uu` | 派生均值，= srp_duration / search_uu |
| `pdp_duration_per_uu` | 派生均值 |
| `video_duration_per_uu` | 派生均值 |
| `live_duration_per_uu` | 派生均值 |
| `first_click_location_avg` | 均值，不可累加 |
| `first_click_location_p50` | 分位数，不可累加 |
| `max_imp_location_avg` | 均值，不可累加 |
| `max_imp_location_p50` | 分位数，不可累加 |

### 维度组合的值域约束（稀疏性说明）

部分指标仅在特定维度组合下有值，跨组合查询时将为 NULL：

| 指标组 | 有效维度约束 |
|---|---|
| 搜索量、留存、norecall_rate、srp/pdp 时长 | `card_type='item+video+live'`, `is_ads='__ALL__'`, `location='__ALL__'`, `with_item='__ALL__'` |
| gmv_995 系列（v1/v2） | `location='__ALL__'`, `with_item='__ALL__'` |
| 视频侧指标（search_to_video_*、all_video_side_*）| `search_entrance='__ALL__'`, `is_ads='__ALL__'`, `location='__ALL__'`, `with_item='__ALL__'` |
| 直播侧指标（search_to_live_*、all_live_side_*）| `is_ads='__ALL__'`, `location='__ALL__'`, `with_item='__ALL__'` |
| ads_load、ads_rev、session 指标 | `card_type='item+video+live'`, `is_ads='__ALL__'` |

### 时效性说明

- 本表为 **每日快照表（`_1d`）**，每个分区存储一天的汇总数据。
- 留存指标（`retention_uu_1d`、`retention_uu_7d`）依赖 T-1 和 T-7 的历史数据，需确保上游历史分区数据完整。
- 表数据在 T+1 日产出，当日实时数据请勿使用本表。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 用户-商品-关键词级别搜索行为基准数据，提供主指标（曝光、点击、加购、订单、GMV 等）及广告负载分母 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 原始搜索事件流水，用于计算搜索 session 级别统计（all_ads_session_cnt、search_session_cnt） |
| `srdi_mart.dws_sr_data_warehouse_platform_order_benchmark_1d` | 订单级别基准数据，用于 GMV 995 v2 截断指标计算 |
| `srdi_mart.dim_sr_data_warehouse_category_gmv_outlier` | 品类 GMV 异常值分位数参考表，提供 high/low gmv 品类的 995 分位截断阈值 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，关联品类标签（category_tag），用于 GMV 995 v2 品类分层 |
| `srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d` | 更宽口径搜索场景曝光数据，用于计算 search_scene_imp_cnt |
| `srdi_mart.dws_sr_data_warehouse_search_session_level_metircs_1d` | 搜索 session 级别指标，用于计算首次点击位置、最大曝光位置分布 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 付费广告投放绩效数据，提供广告曝光数（paidads_imp_cnt）和广告营收（ads_rev） |
| `traffic.shopee_traffic_dwd_click_hi__reg_s1_live` | 流量点击明细数据，用于计算 SRP 停留时长、PDP 停留时长（需 session + item_id 关联） |
| `video.video_mart_ads_bi_content_userid_cp_fs_ssp_vft_1d` | 广告视频内容用户播放数据，提供视频 VV 和观看时长 |
| `video.video_mart_dws_ls_content_minils_userid_cp_ssp_vft_aggr_1d` | 直播中视频（mini livestream）用户播放数据 |
| `mp_content_oa.dwd_video_order_omni_local_content_direct_final_detail_di` | 视频侧订单数据，提供搜索归因视频 GMV 和订单 |
| `livestream.ls_mart_dwd_view_streaming_detail_di` | 直播流观看时长明细，用于计算用户直播观看时长 |
| `livestream.ls_mart_dwd_viewer_view_detail_di` | 直播观看行为明细，关联搜索入口，提供直播观看 PV 和时长 |
| `mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di` | 直播侧订单数据，提供搜索归因直播 GMV 和订单 |

---

## ETL 逻辑摘要

### 数据流

```
搜索行为基准数据 (user_item_keyword_benchmark_1d)
  └─► 原始搜索明细 (dwm_search_raw)
        ├─► 主指标聚合 (main_metrics) → 多维 EXPLODE → UU/PV 聚合 → dws_search_main_metrics [主干]
        └─► 其他指标 (other_metrics)
              ├─► 995 v1 指标 (dws_995_metrics)
              ├─► 无召回率 (dws_norecall_rate)
              ├─► 搜索量 (dws_search_volume)
              └─► 留存 (dws_retention)

广告投放数据 (dwd_advertise_performance) + 广告负载分母
  └─► 广告指标 (dws_ads_performance)

流量点击数据 (shopee_traffic_dwd_click)
  ├─► SRP 停留时长 (dws_srp_duration)
  └─► PDP 停留时长 (dws_pdp_duration)

视频/直播内容数据
  ├─► 视频指标 (dws_video_metrics, dws_video_duration)
  └─► 直播指标 (dws_live_duration, dws_live_order)

Session 级别数据
  ├─► 搜索 session 统计 (dws_search_session_count)
  ├─► 首次点击位置 (dws_first_location)
  └─► 最大曝光位置 (dws_max_imp_location)

广搜索场景 (search_srp_user_benchmark)
  └─► search_scene_imp_cnt (dws_search_scene)

品类 995 v2 异常值 + 订单基准数据
  └─► GMV 995 v2 指标 (gmv995_v2_metrics)

所有中间视图 ──LEFT JOIN──► INSERT OVERWRITE 目标表
```

### 关键步骤

1. **`dwm_search_raw`**：从 `platform_user_item_keyword_benchmark_1d` 过滤 global_search/search_in_pdp/search_prefill 三种 page_type，同时拉取当日、T-1、T-7 三天数据（用于留存计算），标准化 search_entrance、is_ads、location、with_item 等维度。

2. **主指标多维展开（EXPLODE）**：对 card_type、is_ads、search_entrance、location、with_item 五个维度分别构造数组后 LATERAL VIEW EXPLODE，将单行原始数据展开为多行，实现预聚合的多维度组合覆盖，再按 user_id + 维度 GROUP BY 汇总 PV 指标和 UU 去重。

3. **session 统计**：从 `dwd_sr_data_warehouse_platform` 原始事件流，识别全广告 session（所有曝光均为广告）和搜索 session 总数，维度为 search_entrance × location。

4. **995 v1 截断**：以全局（`search_entrance='__ALL__'`, `card_type='item+video+live'`）的 ABS 99.5 分位数为阈值，过滤高价值异常用户，计算截断后 GMV 和 PC2 GMV 及人均值。

5. **995 v2 截断**：基于订单粒度，关联品类维度表获取 high/low gmv 品类的各自 995 分位阈值，对每笔订单的 GMV 进行截断，再分品类汇总，产出 `high_gmv_995_v2`、`low_gmv_995_v2` 等字段。

6. **时长指标计算**：
   - SRP 时长：解析 traffic 点击表中 `stay_view` 事件的 duration 字段，限制单次停留 > 0 且 < 10 小时。
   - PDP 时长：通过 item_id + session_id 关联 SRP 点击事件与 PDP stay_view 事件（时间窗口为点击后 10 分钟内）。
   - 视频时长：合并广告视频和 mini livestream 两条播放链路。
   - 直播时长：关联 view_detail 和 streaming_detail，区分搜索 SRP 直播卡入口（source_type=1）与其他搜索入口（source_type=2）。

7. **广告指标**：广告曝光数和营收来自 `mp_paidads` 表（entrance=1 限制搜索入口），与搜索侧广告负载分母 FULL JOIN 后多维展开。

8. **最终 INSERT OVERWRITE**：以 `dws_search_main_metrics` 为主表，通过多个（约 16 个）LEFT JOIN 将各专题中间视图拼接，计算派生字段（`ads_load`、`srp_duration_per_uu` 等），按 `grass_region` 和 `local_date` 分区覆盖写入目标表。

### 注意事项

- **单 writer**：本表仅有一个 ETL 文件写入，不存在 multi-writer 并发写入风险。
- **维度稀疏性**：多数专题指标（留存、搜索量、时长、直播/视频侧等）均通过 JOIN 条件限制仅在特定维度组合下填充，其他组合行对应列值为 NULL，查询时需注意过滤条件的完整性，避免误认为数据缺失。
- **EXPLODE 导致行数膨胀**：原始数据在 ETL 内部已按维度数组展开（card_type × is_ads × search_entrance × location × with_item），目标表行数远大于原始事件行数，切勿对已含 `__ALL__` 汇总行的结果集直接 SUM 求总量。
- **留存窗口数据依赖**：`dwm_search_raw` 过滤了 T、T-1、T-7 三天数据，若上游历史分区缺失，留存指标将出现低估。
- **广播 JOIN 优化**：ETL 中大量使用 `BROADCASTJOIN` hint，说明多数专题 view 行数较少，适合广播；若专题数据量增长导致内存不足，需关注执行计划变化。
- **时区一致性**：所有上游表均使用 `tz_type='local'` 过滤，确保与目标表 `local_date` 分区的时区口径一致。

---

*文档生成时间：2026-05-17*