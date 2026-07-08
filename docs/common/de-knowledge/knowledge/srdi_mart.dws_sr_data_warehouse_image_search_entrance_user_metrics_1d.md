<!-- ads-workspace-gdoc-sync: gdoc_id=1bTqNUlTNMsabyJo9VS4BbvYRYkiiNgPNFQDKocyLMmg gdoc_url=https://docs.google.com/document/d/1bTqNUlTNMsabyJo9VS4BbvYRYkiiNgPNFQDKocyLMmg/edit -->

# srdi_mart.dws_sr_data_warehouse_image_search_entrance_user_metrics_1d

**分层：** dws / dws_search
**主键：** `user_id` + `search_entrance` + `image_source` + `platform` + `is_ads` + `grass_region` + `local_date`
**分区：** `grass_region`（站点区域），`local_date`（业务日期）
**更新频率：** 每日（T+1 覆盖写入，`INSERT OVERWRITE` 按分区刷新）
**引用频次 / 访问频次：** 1686

---

## 业务描述

本表是**图搜（Image Search）入口维度的用户粒度日汇总宽表**，面向搜推数仓（SRDI）图搜业务。

表中每行记录在某一天、某一站点（`grass_region`）、某一搜索入口（`search_entrance`）、图片来源（`image_source`）、终端平台（`platform`）、是否广告（`is_ads`）组合下，单个用户（`user_id`）的图搜全链路行为与业务结果指标。

**核心业务场景：**
- 分析不同图搜入口（首页、搜索页、商品详情页等）的用户行为漏斗（曝光 → 点击 → 浏览 → 加购 → 下单）
- 评估图搜结果质量（有结果搜索量 vs 无结果搜索量、Top1 相似度）
- 衡量图搜对 GMV、订单量的贡献，支持广告与自然流量拆分分析
- 追踪拍照搜索（camera search）与图片搜索（image search）的渗透与使用趋势
- 支持用户级别的图搜行为下钻分析

**适合回答的问题举例：**
- 各图搜入口的按钮曝光、点击及 CTR 如何？
- 图搜用户的查询次数（`query_cnt`）、有/无结果率分布如何？
- 图搜带来的加购量（`cart_cnt`）、订单量（`order_cnt`）、GMV 是多少？
- 拍照搜索 PV（`camera_search_pv`）与图搜 PV（`image_search_pv`）的趋势对比？
- 广告图搜（`is_ads = true`）与自然图搜的效果差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域（如 ID、MY、TH 等），用于多站点分区隔离 |
| `local_date` | date | 业务日期（本地时区），每日一个分区 |

---

### 维度：用户与入口标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户唯一标识，聚合粒度之一 |
| `search_entrance` | string | 图搜触发入口（非空过滤保证），如首页、搜索页、商品详情页等 |
| `image_source` | string | 图片来源类型，标识用户上传图片的渠道来源 |
| `platform` | string | 终端平台，如 Android、iOS、Web 等 |
| `is_ads` | boolean | 是否为广告场景（上游为 null 时默认为 false） |

---

### 指标：入口曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `image_search_button_imp_cnt` | bigint | 图搜按钮（`image_search_button` / `try_image_search_button`）在搜索页、首页、商场页、预搜索页、找相似页、店铺分类落地页的曝光次数之和 |
| `image_search_button_click_cnt` | bigint | 上述页面图搜按钮的点击次数之和 |

---

### 指标：图搜结果页商品曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `image_search_item_imp_cnt` | bigint | 图搜结果页（`page_type = 'image_search'`）商品曝光次数 |
| `image_search_item_click_cnt` | bigint | 图搜结果页商品点击次数 |
| `click_location_sum` | bigint | 图搜结果页商品点击位置之和，可用于计算平均点击位置 |
| `top1_item_impression_cnt` | bigint | 图搜结果页 Top1 商品的曝光次数之和（来源字段 `top1_item_imp_cnt`） |
| `top1_similarity_sum` | double | 图搜结果页 Top1 商品的相似度得分累加值，配合 `top1_item_impression_cnt` 可计算平均相似度 |

---

### 指标：PV 与查询量

| 字段 | 类型 | 说明 |
|---|---|---|
| `image_search_pv` | double | 图搜结果页（`page_type = 'image_search'`）的 view 事件次数（页面浏览量） |
| `camera_search_pv` | double | 拍照搜索页（`page_type = 'camera_search'`）的 view 事件次数 |
| `query_cnt` | bigint | 图搜查询次数，统计图搜结果页 view 事件中的 md5 数量（每次搜图对应一个 md5） |
| `pdp_like_button_click_cnt` | bigint | 商品详情页（PDP）收藏按钮点击次数 |

---

### 指标：搜索结果质量

| 字段 | 类型 | 说明 |
|---|---|---|
| `image_search_result_volume` | bigint | 有搜索结果的图搜次数（图搜结果页商品有曝光时，对 `(user_id, md5)` 去重计数） |
| `image_search_non_result_volume` | double | 无搜索结果的图搜次数（图搜结果页出现"重新拍照"按钮曝光时，对 `(user_id, md5)` 去重计数） |

---

### 指标：加购、订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `atc_location_sum` | bigint | 图搜结果页（主搜 section）商品加购位置之和，用于计算平均加购位置 |
| `cart_cnt` | double | 图搜相关商品的加购次数（`feature_detail` 为 `image_search-item` 或 `image_search-search-item`，operation 为 `cart` 的 ppv 加购计数） |
| `order_cnt` | double | 图搜归因订单数（`feature_detail` 匹配图搜特征，operation 为 `order`） |
| `gmv` | double | 图搜归因 GMV（美元或统一货币），`order` 事件下的 gmv 累加值 |
| `gmv_local` | double | 图搜归因本地货币 GMV，`order` 事件下的 gmv_local 累加值 |
| `pdp_pv` | double | 商品详情页 PV（DataMap 中存在该字段，ETL SQL 中未显式输出，实际值为 0 或由其他逻辑补充） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，否则触发全分区扫描，严重影响性能。建议使用等值或范围过滤，例如：
  ```sql
  WHERE grass_region = 'ID' AND local_date = '2025-05-01'
  ```
- **`grass_region`**：必须指定，数据按站点独立分区存储，跨站点 UNION 需显式枚举。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `top1_similarity_sum` | 位置之和，需配合 `top1_item_impression_cnt` 计算平均相似度（`top1_similarity_sum / top1_item_impression_cnt`） |
| `click_location_sum` | 位置之和，需配合 `image_search_item_click_cnt` 计算平均点击位置 |
| `atc_location_sum` | 位置之和，需配合 `cart_cnt` 计算平均加购位置 |
| `image_search_result_volume` | 基于 `(user_id, md5)` 去重计数，跨用户 SUM 时需注意语义（已是用户级别聚合，再 SUM 不存在重复去重问题，但含义需明确） |
| `image_search_non_result_volume` | 同上，去重计数，类型为 double（来自 `count(DISTINCT ...)`） |
| `pdp_pv` | 该字段在 ETL SQL 中无对应计算逻辑，使用前需确认实际产出是否为 0 |

### 时效性说明

- 本表为 **T+1 日表**（`_1d` 后缀），每天覆盖写入前一自然日数据，通常 T+1 早间可用。
- 分区为 `INSERT OVERWRITE`，同一分区每次执行均会全量替换，无需担心数据重复，但需注意调度时间窗口内的数据可用性。

### 其他注意事项

- `search_entrance` 在上游已过滤 `IS NOT NULL`，该字段无空值。
- `is_ads` 为 `boolean` 类型，上游 null 值已被 `coalesce` 处理为 `false`，过滤时请使用 `is_ads = true` 而非 `is_ads = 1`。
- `pdp_pv` 字段存在于 DataMap 中，但 ETL INSERT 列表中未见对应计算字段，实际写入值需验证。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_image_search_user` | 图搜用户行为明细中间层，提供用户级别的曝光、点击、加购、订单、GMV 等原始事件数据，按 `local_date` 和 `grass_region` 分区读取 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_image_search_user
    ↓（按 local_date + grass_region 过滤，search_entrance IS NOT NULL）
临时视图 dwm_image_search_aggregated_${grass_region_without_quote}
    ↓（多维度聚合，sum/count distinct 计算各指标）
srdi_mart.dws_sr_data_warehouse_image_search_entrance_user_metrics_1d
    （INSERT OVERWRITE，按 grass_region + local_date 分区写入）
```

### 关键步骤

**Step 1：创建临时聚合视图（Statement 1）**

从 `dwm_sr_data_warehouse_image_search_user` 中按 `local_date` 和 `grass_region` 过滤，以 `(user_id, search_entrance, image_source, platform, is_ads)` 为聚合粒度，使用条件聚合（`sum(if(...))`）分别计算：

- 图搜按钮曝光 / 点击（多页面类型条件过滤）
- 图搜结果页商品曝光 / 点击 / 点击位置
- 拍照搜索 PV、图搜 PV
- 加购位置（仅限主搜 section，`page_section[0] = 'search'` 或为 NULL）
- PDP 收藏按钮点击
- PPV 加购、归因订单量、本地 GMV、GMV（`feature_detail` 匹配图搜特征）
- 有结果 / 无结果图搜量（`count(DISTINCT (user_id, md5))`）
- 图搜查询次数（`count(md5)` on view 事件）
- Top1 商品曝光量及相似度总和

**Step 2：写入目标表（Statement 2）**

从临时视图中选取所有指标字段，执行 `INSERT OVERWRITE` 写入目标表对应的 `grass_region` + `local_date` 分区，覆盖该分区历史数据。

### 注意事项

- **单文件写入，无 multi-writer 风险**：ETL 仅有 1 个 SQL 文件，`multi_writer = false`，同一分区不存在并发写入竞争。
- **分区覆盖写入**：每次调度均执行 `INSERT OVERWRITE`，若重跑需确认上游 dwm 层数据已就绪，否则可能覆盖为空数据。
- **`is_ads` null 处理**：上游字段可能为 null，ETL 已通过 `coalesce(is_ads, false)` 统一为 false，下游无需再处理 null。
- **`ppv_pv` 字段**：临时视图中计算了 `ppv_pv` 字段，但目标表 DataMap 中无对应字段，INSERT 列表中已包含，需关注 DDL 与实际写入是否一致。
- **`pdp_pv` 字段**：DataMap 中存在该字段，但 ETL INSERT 列表中未见对应写入，存在字段与 DDL 不一致的风险，建议核实。

---

*文档生成时间：2026-05-17*