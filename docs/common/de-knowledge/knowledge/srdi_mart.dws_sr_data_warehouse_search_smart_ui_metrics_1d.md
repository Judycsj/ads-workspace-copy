<!-- ads-workspace-gdoc-sync: gdoc_id=1bwnJR2ZHuud5WrESDZUXI6HheNWf_vvLJYalhSsDTSg gdoc_url=https://docs.google.com/document/d/1bwnJR2ZHuud5WrESDZUXI6HheNWf_vvLJYalhSsDTSg/edit -->

# srdi_mart.dws_sr_data_warehouse_search_smart_ui_metrics_1d

**分层：** dws_search（数据仓库服务层 - 搜索域）
**主键：** `grass_region` + `local_date` + `user_id` + `item_id` + `image_id` + `target_type`
**分区：** `grass_region`（站点大区）、`local_date`（本地日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 1444 次

---

## 业务描述

本表聚合搜索场景下智能 UI（Smart UI / XUI）维度的每日用户-商品-图片级行为指标，覆盖曝光、点击、加购、下单、GMV 及短视频（HLV）播放等核心电商行为。

**核心业务场景：**
- 评估搜索结果页不同 UI 样式（图片比例、图片阶段、标签、标题样式、前端组件库）对用户行为的影响；
- 分析短视频卡片（HLV）在搜索场景下的播放率与转化表现；
- 对比广告（is_ads）与自然流量在不同 UI 配置下的 CTR、CVR 差异；
- 支持 XUI 实验效果评估及 Smart UI 特征工程数据输出。

**适合回答的问题（示例）：**
- 某站点某天不同 `image_aspect_ratio` 下，点击率与转化率分别是多少？
- HLV 卡片的播放完成数（`hlv_played_cnt`）与曝光数之间的比例如何随时间变化？
- 在 `xui_image_stage` 不同阶段，广告商品和自然商品的 GMV 贡献各占多少？
- 特定标签（`labels_info`）在搜索页对商品点击的促进效果如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识（如 SG、MY、TH 等），查询时必须指定 |
| `local_date` | date | 本地日期（自然日），数据统计基准日，查询时必须指定 |

### 维度：用户与商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID |
| `item_id` | bigint | 商品 ID；对 Buybox 或 SPU/vSKU 场景，已映射至 `spu_vsku_item_id` |
| `image_id` | string | 图片或视频 ID；当存在 HLV 视频时取 `hlv_info.video_id`，否则取原始 `image_id` |
| `target_type` | string | 曝光目标类型，取值范围：`item`、`ai_minifeed_card` |

### 维度：UI 样式与展示特征

| 字段 | 类型 | 说明 |
|---|---|---|
| `xui_item_status` | int | XUI 商品状态枚举值，标记商品在智能 UI 框架下的当前状态 |
| `xui_image_stage` | int | XUI 图片阶段枚举值，标识图片在 Smart UI 流水线中所处阶段 |
| `image_aspect_ratio` | string | 图片宽高比，如 `1:1`、`3:4` 等 |
| `title_text` | string | 商品标题文本，来源于 `title_info.title_text` |
| `title_source` | string | 标题来源标识，标记标题由哪个模块或策略生成 |
| `labels_info` | array\<string\> | 标签信息数组，每个元素为 JSON 字符串，包含 `label_text`、`label_type`、`label_location`、`label_source` 四个属性 |
| `library_name_fe` | string | 前端组件库名称（来源字段 `library_name`），标识渲染该卡片所用的前端 UI 库 |
| `is_ads` | boolean | 是否为广告商品；`true` 表示广告流量，`false` 表示自然流量 |
| `is_hlv` | boolean | 是否为短视频（HLV）卡片；当 `hlv_info.video_id` 非空时为 `true` |
| `can_video_play` | boolean | HLV 视频是否可播放，来源于 `ai_search_info.hlv_info.can_video_play` |

### 指标：核心行为指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数，统计 `operation = 'impression'` 的事件数 |
| `click_cnt` | bigint | 点击次数，统计 `operation = 'click'` 的事件数 |
| `cart_cnt` | bigint | 加购次数，统计 `operation = 'cart'` 的事件数 |
| `order_cnt` | double | 下单次数，统计 `operation = 'order'` 的事件数 |
| `gmv` | double | 下单 GMV（货币单位与上游保持一致），统计 `operation = 'order'` 时的 `place_order_gmv` 之和 |
| `hlv_played_cnt` | bigint | HLV 视频播放次数，来源于 `dwd_sr_data_warehouse_platform` 表中 `original_operation = 'action_video_start'` 的点击事件数，按 `(user_id, item_id, image_id)` 关联后左联入 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪**：查询时必须同时指定 `grass_region` 和 `local_date`，否则将触发全表扫描，产生巨大资源消耗。

```sql
WHERE grass_region = 'SG'
  AND local_date = '2025-01-01'
```

- 如需查询多天数据，使用 `local_date BETWEEN '2025-01-01' AND '2025-01-07'`，并确保 `grass_region` 始终指定。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `order_cnt` | 类型为 `double`，上游已为预聚合值，跨分组 SUM 需注意精度及重复计数问题 |
| `gmv` | 类型为 `double`，为预聚合 GMV，直接跨维度 SUM 可能导致重复统计 |
| `hlv_played_cnt` | 为 LEFT JOIN 后补充的聚合值，NULL 行代表无播放事件，SUM 前需 `COALESCE(hlv_played_cnt, 0)` |
| `labels_info` | 数组类型，不可直接聚合，需使用 `EXPLODE` 展开后再分析 |
| `can_video_play` / `is_hlv` / `is_ads` | 布尔维度字段，统计比率时需使用 `COUNT(IF(is_hlv, 1, NULL))` 等方式 |

### 时效性说明

- 本表为 **T+1 日级表**（`_1d` 后缀），每日产出前一自然日数据。
- 数据就绪时间取决于上游 `dwd_sr_data_warehouse_search` 和 `dwd_sr_data_warehouse_platform` 的完成情况，通常在次日早间完成写入。
- 不适用于实时或准实时查询场景。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 主数据源，提供搜索页 impression/click/order/cart 行为事件及 UI 特征字段（图片、标签、标题、XUI 属性等） |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 辅助数据源，用于统计 HLV 视频播放次数（`action_video_start` 事件），通过 `(user_id, item_id, image_id)` 关联至主数据 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_platform
    → [过滤 action_video_start click 事件]
    → hlv_play_count (Temporary View)
                                            ↘
dwd_sr_data_warehouse_search                  LEFT JOIN on (user_id, item_id, image_id)
    → [过滤搜索页事件 + UI 字段处理]          ↗
    → dwd_search (Temporary View)
                                            ↓
                    dws_sr_data_warehouse_search_smart_ui_metrics_1d
```

### 关键步骤

**Step 1 — Temporary View `hlv_play_count`**

从 `dwd_sr_data_warehouse_platform` 过滤出搜索页（`page_type IN ('search_prefill', 'search_in_pdp', 'global_search')`）中用户触发 HLV 视频播放（`operation = 'click'` + `original_operation = 'action_video_start'`）的事件，按 `(user_id, item_id, video_id)` 聚合计算 `hlv_played_cnt`。仅保留 `page_section IS NULL` 且 `target_type = 'item'` 且 `video_id` 非空的记录。

**Step 2 — Temporary View `dwd_search`**

从 `dwd_sr_data_warehouse_search` 过滤搜索页（`page_type IN ('global_search', 'search_in_pdp', 'search_prefill')`、`page_section IS NULL`、`target_type IN ('item', 'ai_minifeed_card')`）的四类行为事件（impression / click / order / cart），进行以下字段处理：
- **item_id 映射**：对 Buybox 商品（`ctx_item_type = 2` 或 `feature_group = 'Buybox'`），order/cart/ppv 操作分别取对应的 `spu_vsku_item_id`；
- **image_id 映射**：HLV 卡片（`hlv_info.video_id` 非空）取 video_id，否则取原始 `image_id`；
- **labels_info 构建**：通过 `TRANSFORM` 将 `labels` 数组转换为包含 `label_text`、`label_type`、`label_location`、`label_source` 的 JSON 字符串数组；
- **指标聚合**：按全部维度字段 GROUP BY，分别 SUM 各操作类型的 `operation_cnt` 及 GMV。

**Step 3 — INSERT OVERWRITE 写目标表**

将 `dwd_search` 与 `hlv_play_count` 按 `(user_id, item_id, image_id)` LEFT JOIN，合并 `hlv_played_cnt`，最终以 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 写入目标表。

### 注意事项

- **单写入器**：本表仅有一个 ETL 文件，不存在多写（multi-writer）风险，分区覆盖写入是安全的。
- **LEFT JOIN 产生 NULL**：`hlv_played_cnt` 来自 LEFT JOIN，对于非 HLV 商品或无播放事件的行，该字段为 `NULL`，下游查询须使用 `COALESCE(hlv_played_cnt, 0)` 处理。
- **item_id 映射逻辑**：Buybox 场景下 item_id 已被替换为 `spu_vsku_item_id`，与其他维度表 JOIN 时需注意口径一致性。
- **分区覆盖**：每次运行以 `INSERT OVERWRITE` 写入指定 `(grass_region, local_date)` 分区，同一分区数据幂等覆盖，重跑安全。
- **page_section 过滤**：两个上游临时视图均要求 `page_section IS NULL`，表示仅统计主搜索版位，排除推荐版块等插入场景。

---

*文档生成时间：2026-05-17*