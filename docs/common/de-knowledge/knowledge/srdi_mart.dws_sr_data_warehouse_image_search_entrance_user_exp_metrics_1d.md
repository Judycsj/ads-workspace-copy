<!-- ads-workspace-gdoc-sync: gdoc_id=1xa9vnofZSfQ_wWHpQ_UHSgE0AAndT-dxVMoBhDsvATM gdoc_url=https://docs.google.com/document/d/1xa9vnofZSfQ_wWHpQ_UHSgE0AAndT-dxVMoBhDsvATM/edit -->

# srdi_mart.dws_sr_data_warehouse_image_search_entrance_user_exp_metrics_1d

**分层：** dws_search
**主键：** user_id + exp_group_id + platform + search_entrance + image_source + is_ads + grass_region + local_date
**分区：** grass_region, local_date
**更新频率：** 每日一次（T+1 覆盖写）
**引用频次/访问频次：** 723

---

## 业务描述

本表为图搜（Image Search）入口维度的用户级实验指标宽表，按自然日聚合，面向 A/B 实验分析场景设计。

核心业务场景：
- **A/B 实验评估**：通过关联 AB 测试用户分组表，将每位命中实验的用户（scene_id 451/413/1361 或 experiment_id 193244/217258）的图搜行为与其所属实验分组（`exp_group_id`）关联，支持实验指标的对比分析。
- **图搜入口效果分析**：按搜索入口（`search_entrance`）、图片来源（`image_source`）、平台（`platform`）、是否广告（`is_ads`）等维度，追踪图搜按钮曝光/点击、图搜结果页曝光/点击、PDP 点赞、加购、下单、GMV 等核心链路指标。
- **图搜质量监控**：统计有结果/无结果的搜索次数（`image_search_result_volume` / `image_search_non_result_volume`）、Top1 相似度（`top1_similarity_sum`）、查询量（`query_cnt`）等，用于评估图搜召回与排序质量。

**适合回答的问题举例：**
- 不同实验组在某入口的图搜点击率、转化率、GMV 差异是多少？
- 拍照搜索（camera search）与图片上传搜索的用户行为有何区别？
- 图搜无结果率的变化趋势如何？
- 各平台（iOS/Android）图搜按钮曝光与点击情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域，如 PH、MY、TH 等，分区键之一 |
| `local_date` | date | 数据日期（本地时区），分区键之一 |

### 维度：用户与实验分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，来自 AB 测试用户分组表，仅包含命中实验的用户 |
| `exp_group_id` | bigint | 实验分组 ID，标识用户所属的 A/B 实验桶 |

### 维度：行为上下文

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台，如 iOS、Android 等 |
| `search_entrance` | string | 图搜入口来源，非空且非空字符串（ETL 已过滤），如首页、搜索页等 |
| `image_source` | string | 图片来源类型，如拍照、相册上传等 |
| `is_ads` | boolean | 是否为广告流量，空值默认补 false |

### 指标：图搜按钮曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `image_search_button_imp_cnt` | bigint | 图搜按钮曝光次数；统计 page_type 为 search/home/mall/pre_search/find_similar_products/shop_category_landing，target_type 为 image_search_button 或 try_image_search_button，operation 为 impression 的 imp_cnt 之和 |
| `image_search_button_click_cnt` | bigint | 图搜按钮点击次数；统计同上 page_type 与 target_type，operation 为 click 的 click_cnt 之和 |

### 指标：图搜结果页曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `image_search_item_imp_cnt` | bigint | 图搜结果页商品曝光次数；page_type=image_search，target_type=item，operation=impression 的 imp_cnt 之和 |
| `image_search_item_click_cnt` | bigint | 图搜结果页商品点击次数；page_type=image_search，target_type=item，operation=click 的 click_cnt 之和 |
| `image_search_pv` | double | 图搜结果页 PV；page_type=image_search，operation=view 的 view_cnt 之和 |
| `camera_search_pv` | double | 拍照搜索页 PV；page_type=camera_search，operation=view 的 view_cnt 之和 |

### 指标：图搜质量

| 字段 | 类型 | 说明 |
|---|---|---|
| `query_cnt` | bigint | 图搜查询次数（非去重）；page_type=image_search，operation=view 的 md5 行数（含重复），反映查询总量 |
| `image_search_result_volume` | bigint | 有结果的图搜会话数（去重）；page_type=image_search，target_type=item，operation=impression 的 md5 去重计数 |
| `image_search_non_result_volume` | double | 无结果的图搜会话数（去重）；page_type=image_search，target_type=take_new_photo_button，operation=impression 的 md5 去重计数，以 double 存储 |
| `top1_similarity_sum` | double | Top1 检索结果相似度之和；page_type=image_search，target_type=item 的 top1_similarity_sum 之和，需除以 top1_item_impression_cnt 得到均值 |
| `top1_item_impression_cnt` | bigint | Top1 商品曝光次数；page_type=image_search，target_type=item 的 top1_item_imp_cnt 之和，作为 top1_similarity_sum 的分母 |

### 指标：用户互动

| 字段 | 类型 | 说明 |
|---|---|---|
| `pdp_like_button_click_cnt` | bigint | PDP 页点赞按钮点击次数；page_type=product，target_type=like_button，operation=click 的 click_cnt 之和 |
| `click_location_sum` | bigint | 图搜商品点击位置之和；page_type=image_search，target_type=item，operation=click 的 click_location_sum 之和，可配合 image_search_item_click_cnt 计算平均点击位置 |
| `atc_location_sum` | bigint | 图搜加购位置之和；page_type=image_search，page_section[0] 为 'search' 或 NULL，target_type=item，operation=cart 的 atc_location_sum 之和 |

### 指标：电商转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `pdp_pv` | double | PDP 页 PV（PPV）；feature_detail 属于图搜相关类型，operation=ppv 的 ppv_cnt 之和（字段名在 DataMap 中为 pdp_pv，ETL 中间计算名为 ppv_pv） |
| `cart_cnt` | double | 加购次数；feature_detail 属于图搜相关类型（image_search-item/search-item/rcmd-item/original_item-item），operation=cart 的 cart_cnt 之和 |
| `order_cnt` | double | 下单次数；feature_detail 属于图搜相关类型，operation=order 的 order_cnt 之和 |
| `gmv` | double | 成交金额（美元或统一货币）；feature_detail 属于图搜相关类型，operation=order 的 gmv 之和 |
| `gmv_local` | double | 成交金额（本地货币）；feature_detail 属于图搜相关类型，operation=order 的 gmv_local 之和 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤（必填）**：查询时必须同时指定 `grass_region` 和 `local_date`，否则将触发全表扫描，严重影响性能。
  ```sql
  WHERE grass_region = 'PH'
    AND local_date = '2024-01-01'
  ```
- 本表仅包含命中特定 AB 实验（scene_id IN (451, 413, 1361) 或 experiment_id IN (193244, 217258)）且通过 `is_assignment_log = 1` 筛选的用户，分析时需注意样本范围。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确用法 |
|---|---|---|
| `top1_similarity_sum` | 分子，需配合分母使用 | `SUM(top1_similarity_sum) / SUM(top1_item_impression_cnt)` 得到平均 Top1 相似度 |
| `click_location_sum` | 位置分子 | `SUM(click_location_sum) / SUM(image_search_item_click_cnt)` 得到平均点击位置 |
| `atc_location_sum` | 位置分子 | `SUM(atc_location_sum) / SUM(cart_cnt)` 得到平均加购位置 |
| `image_search_result_volume` | 去重计数（COUNT DISTINCT md5），跨用户聚合会重复计数 | 只可 SUM 得到用户级别合计，跨更大维度需重新从 DWM 层计算 |
| `image_search_non_result_volume` | 同上，去重计数 | 同上 |
| `query_cnt` | 非去重 COUNT，用户级聚合后再 SUM 可能与预期含义不符 | 明确是否需要去重查询数 |

### 时效性说明

- 本表为 **T+1 日刷新**，每日通过 `INSERT OVERWRITE` 全量覆盖当天分区，当天数据通常在次日产出。
- 表名后缀 `_1d` 表示按自然日聚合，不含滚动窗口（无 `_nd` / `_td` 语义）。
- 历史分区数据一经写入一般不再回刷，如需修订需重新触发 ETL。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | AB 测试用户分组维表，提供 user_id → exp_group_id 映射，筛选条件为指定 scene_id 或 experiment_id、is_assignment_log=1 |
| `srdi_mart.dwm_sr_data_warehouse_image_search_user` | 图搜用户行为明细 DWM 层，包含曝光、点击、加购、下单、GMV 等原始事件聚合数据，按 user_id + 维度组合聚合 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──┐
  (实验用户分组，当日分区)                    │  INNER JOIN (user_id)
                                            ├──► INSERT OVERWRITE 目标表分区
dwm_sr_data_warehouse_image_search_user  ──┘
  (图搜用户行为，当日分区，过滤 search_entrance 非空)
```

### 关键步骤

**Step 1 — Temporary View：`user_exp_mapping_${grass_region_without_quote}`**

从 `dim_sr_data_warehouse_abtest_user_group` 读取当日、当区域、满足实验条件（scene_id IN (451, 413, 1361) 或 experiment_id IN (193244, 217258)）、且 `is_assignment_log = 1` 的用户分组记录，生成 `user_id → exp_group_id` 映射临时视图。

**Step 2 — Temporary View：`dwm_data_${grass_region_without_quote}`**

从 `dwm_sr_data_warehouse_image_search_user` 读取当日、当区域数据（过滤 `search_entrance` 非空），按 `user_id, search_entrance, image_source, platform, is_ads` 五个维度分组，通过条件聚合（`SUM(IF(...))` / `COUNT(DISTINCT IF(...))`）计算所有曝光、点击、加购、下单、GMV、相似度等指标，形成用户行为宽表临时视图。

**Step 3 — INSERT OVERWRITE：写入目标表**

以 `user_id` 为关联键，将 `user_exp_mapping` 与 `dwm_data` 进行 **INNER JOIN**（仅保留同时命中实验分组且有图搜行为的用户），将 `exp_group_id` 拼接至行为数据，按 `grass_region` 和 `local_date` 分区写入目标表。

> 注意：ETL 中间视图计算了 `ppv_pv`（PPV 页面浏览量），对应目标表字段 `pdp_pv`；中间视图计算了 `top1_item_imp_cnt`，对应目标表字段 `top1_item_impression_cnt`，字段名在中间层与目标层存在差异。

### 注意事项

- **INNER JOIN 语义**：仅命中 AB 实验且有图搜行为的用户才会写入本表，未命中实验或无图搜行为的用户数据被丢弃，分析时需注意样本偏差。
- **单一写入者**：本表为单 ETL 文件写入（`multi_writer: false`），无多写冲突风险。
- **分区覆盖写**：每次执行为 `INSERT OVERWRITE` 针对特定 `grass_region + local_date` 分区，不影响其他分区的历史数据。
- **参数化执行**：SQL 中 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}`、`${schema}` 均为运行时参数，临时视图名称与分区值在执行时动态替换，每个区域独立调度。
- **`is_ads` 空值处理**：原始数据中 `is_ads` 可能为 null，ETL 使用 `COALESCE(is_ads, false)` 将其补全为 false，目标表中不存在 null 值。

---

*文档生成时间：2026-05-17*