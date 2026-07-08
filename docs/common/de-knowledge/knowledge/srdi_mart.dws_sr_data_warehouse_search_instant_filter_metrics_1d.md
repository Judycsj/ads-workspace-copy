<!-- ads-workspace-gdoc-sync: gdoc_id=18WTuMdIsTHfhgTLVWwq8E-05u7aangJN71IIPOSEKx8 gdoc_url=https://docs.google.com/document/d/18WTuMdIsTHfhgTLVWwq8E-05u7aangJN71IIPOSEKx8/edit -->

# srdi_mart.dws_sr_data_warehouse_search_instant_filter_metrics_1d

**分层：** dws_search
**主键：** `grass_region` + `local_date` + `user_id` + `device_id` + `search_session_id` + `request_id` + `keyword` + `address_id` + `search_filter` + `card_type` + `layout_type` + `item_id` + `shop_id` + `local_hour`
**分区：** `grass_region`（站点）/ `local_date`（业务日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**引用频次 / 访问频次：** 58

---

## 业务描述

本表聚焦于**即时配送筛选器（Instant Delivery / Fast Delivery Filter）**场景下的搜索行为分析，记录用户在全站搜索（`global_search`）、PDP 内搜索（`search_in_pdp`）及预填搜索（`search_prefill`）中使用"即时配送"或"极速配送"筛选条件时的每日明细级汇总指标。

**核心业务场景：**
- 衡量即时配送筛选器的曝光、点击、成单及 GMV 转化效果；
- 分析筛选器在不同地址（`address_id` / `address_state`）、卡片类型（`card_type`）、布局类型（`layout_type`）等维度下的表现；
- 追踪因启用即时配送筛选后无结果返回（`no_results_cnt`）的情况，辅助召回质量评估；
- 结合广告收入（`ads_rev`）和平均预计送达时间（`avg_edt`）评估筛选器对商业化和用户体验的影响。

**适合回答的问题：**
- 即时配送筛选器的整体点击率（CTR）和转化率（CVR）是多少？
- 哪些站点 / 地址州 / 关键词使用即时配送筛选后无结果的比例最高？
- 使用即时配送筛选后带来的广告收入贡献如何？
- 即时配送筛选场景下订单的平均承诺送达天数（avg_edt）是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 站点/区域标识，如 `ID`、`TH` 等，作为分区键 |
| `local_date` | date | 业务本地日期，作为分区键 |

### 维度：用户与设备标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 用户 ID；ETL 过滤 `user_id > 0`，排除未登录用户 |
| `device_id` | string | 设备 ID，用于补充无用户 ID 场景的设备维度分析 |

### 维度：地址信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `address_id` | bigint | 用户选择的地址 ID，来源于搜索筛选器携带的 `address_id` 字段（通过 EXPLODE 展开） |
| `address_state` | string | 地址所属州/省级行政区，通过 `user_id + address_id` 关联用户地址维表获得 |

### 维度：搜索请求标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `search_session_id` | string | 搜索会话 ID，标识一次完整的搜索会话 |
| `request_id` | string | 单次搜索请求 ID，关联广告收入时作为匹配键 |
| `keyword` | string | 用户搜索关键词 |
| `local_hour` | int | 事件发生的本地小时（0–23），支持小时级粒度分析 |

### 维度：搜索结果与筛选器

| 字段 | 类型 | 说明 |
|------|------|------|
| `search_filter` | array\<struct\<filter_group_name:string, filter_name:string, filter_option:string, is_shortcut:boolean\>\> | 本次搜索中激活的筛选器列表，仅保留 `filter_name` 为 `instant_delivery` 或 `fast_delivery` 的筛选器；结构体中 `address_id` 已被提取为独立字段，不再包含在此数组中 |
| `card_type` | string | 搜索结果卡片类型，取值包括 `item`（商品）、`video`（视频）、`livestream`（直播）、`results-shop`（店铺）；无结果场景下为 `no_recall_general`、`no_recall_with_filter`、`try_diff_address` |
| `layout_type` | string | 搜索结果布局类型，原始值为数字字符串，缺失时默认填充 `'2'` |
| `item_id` | array\<bigint\> | 搜索结果中关联的商品 ID 列表；店铺卡片时取 `shop_layout_item_list`，普通商品卡时取 `ARRAY(item_id)` |
| `shop_id` | bigint | 搜索结果中关联的店铺 ID |

### 指标：搜索行为指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_cnt` | bigint | 曝光次数（`operation = 'impression'`），仅统计有效卡片类型（item/video/livestream/results-shop）；无结果场景下为 NULL |
| `click_cnt` | bigint | 点击次数（`operation = 'click'`），仅统计有效卡片类型；无结果场景下为 NULL |
| `no_results_cnt` | bigint | 无结果曝光次数，仅在 `card_type` 为 `no_recall_general`、`no_recall_with_filter`、`try_diff_address` 且 `operation = 'impression'` 时统计；有效卡片类型行为该字段为 NULL |

### 指标：成交指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt` | double | 下单次数（`operation = 'order'`），来源含主路径及 source1、source2 归因路径 |
| `gmv` | double | 下单 GMV（`place_order_gmv`），单位与上游表一致 |

### 指标：广告与物流指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_rev` | double | 广告收入（USD），通过 `request_id + item_id` 关联广告消耗表 `mp_paidads.dwd_advertise_performance_di__reg_s0_live` 汇总的 `expenditure_amt_usd`；无广告匹配时为 NULL |
| `avg_edt` | double | 平均预计送达天数（`edtmax_in_days`），通过 `order_id` 关联 `sls_mart.dwd_edt_order_info_df` 计算 AVG；仅针对有订单行为的维度组合填充，其余行为 NULL |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤必须同时指定 `grass_region` 和 `local_date`**，否则将触发全表扫描，造成严重性能问题：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```
- 如需分析多天数据，务必显式列出日期范围：`local_date BETWEEN '2024-01-01' AND '2024-01-07'`。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确用法 |
|------|------|----------|
| `avg_edt` | 均值指标，直接 SUM 无意义 | 需回溯原始订单数据加权计算，或仅用于行级展示 |
| `ads_rev` | 预聚合至维度组合粒度，跨行 SUM 时注意去重维度 | 按需过滤维度后 SUM，避免重复计算 |
| `order_cnt` | 类型为 double（含小数归因），聚合时需注意精度 | `SUM` 可用，但需知晓含多路径归因的潜在重复 |
| `item_id` | 数组类型，不可直接聚合 | 需先 EXPLODE 再关联分析 |
| `search_filter` | 复杂嵌套数组类型，不可直接聚合 | 需先 EXPLODE / FILTER 展开后使用 |

### 时效性说明

- 本表为 **T+1 日级表**，当天数据次日产出。
- 数据时效受上游 `srdi_mart.dwd_sr_data_warehouse_search` 和 `sls_mart.dwd_edt_order_info_df` 影响；其中 EDT 表使用最新可用 `grass_date` 分区数据，存在轻微时效延迟。

### 其他注意事项

- `imp_cnt`、`click_cnt`、`order_cnt`、`gmv` 与 `no_results_cnt` 存在**互斥关系**：正常卡片行类的 `no_results_cnt` 为 NULL，无结果行类的前四个指标为 NULL，汇总时需分别处理。
- `avg_edt` 和 `ads_rev` 仅在满足特定条件的维度组合行中有值，大量行为 NULL，统计时应使用 `SUM` / `AVG` 的 NULL 安全聚合函数。
- 本表中 `search_filter` 数组已被过滤，**仅保留 `instant_delivery` 或 `fast_delivery` 筛选项**，不代表用户全部筛选条件。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dwd_sr_data_warehouse_search` | 主数据源，提供搜索事件明细（曝光、点击、下单），含主路径及 source1、source2 多归因路径 |
| `mp_user.dim_user_address__reg_s0_live` | 用户地址维表，通过 `user_id + address_id` 获取 `address_state`（州/省） |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告消耗明细，通过 `raw_request_id + item_id` 关联计算广告收入（`expenditure_amt_usd`） |
| `sls_mart.dwd_edt_order_info_df_{grass_region}` | 订单预计送达时间明细，通过 `order_id` 获取 `edtmax_in_days`，用于计算 `avg_edt` |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_search          mp_user.dim_user_address__reg_s0_live
         │                                                     │
         ▼                                                     │
  dwd_raw_data（三路 UNION：主路径 impression/click/order       │
               + source1 order + source2 order）               │
         │                                                     │
         ▼                                                     │
  dwd_raw_data_filter_search_filter（仅保留 instant/fast 筛选）  │
         │                                                     │
         ▼                                                     │
  dwd_filtered_data_explode_address_id（EXPLODE address_id）    │
         │                                  ┌──────────────────┘
         ├──────────────────────────────────►│ user_address_state_mapping
         │                                  │
         ├──► dws_main_metrics（imp/click/order/gmv/no_results）
         │
         ├──► dwm_ads_revenue_link ──► JOIN mp_paidads ──► dws_ads_revenue（ads_rev）
         │
         └──► dwm_avg_edt_link ──► JOIN sls_mart.dwd_edt_order_info_df ──► dws_avg_edt（avg_edt）
                                                    │
                                                    ▼
                              INSERT OVERWRITE 目标表（三路 LEFT JOIN 合并）
```

### 关键步骤

| 步骤 | Temporary View | 描述 |
|------|---------------|------|
| 1 | `user_address_state_mapping` | 从用户地址维表提取 `user_id + address_id → address_state` 映射，限定本地日期和时区 |
| 2 | `dwd_raw_data` | 从 DWD 搜索事件表三路 UNION ALL：① 主路径 impression/click/order；② source1 归因路径 order；③ source2 归因路径 order；统一过滤 `page_type`、`target_type`、`operation` 等条件 |
| 3 | `dwd_raw_data_filter_search_filter` | 过滤保留 `search_filter` 中含 `instant_delivery` 或 `fast_delivery` 的记录，并截取对应筛选项 |
| 4 | `dwd_filtered_data_explode_address_id` | LATERAL VIEW EXPLODE `search_filter`，将每个筛选器的 `address_id` 提取为独立字段，同时重建不含 `address_id` 的 `search_filter` 结构体数组 |
| 5 | `dws_main_metrics` | LEFT JOIN 地址映射，按维度组合分组聚合 `imp_cnt`、`click_cnt`、`order_cnt`、`gmv`（有效卡片）和 `no_results_cnt`（无结果曝光），两类指标 UNION ALL 合并 |
| 6 | `dwm_ads_revenue_link` | 从过滤后数据提取广告关联维度（`request_id + item_id`），用于后续广告收入匹配 |
| 7 | `dwd_ads_revenue` | 从广告消耗表按 `raw_request_id + item_id` 聚合 `expenditure_amt_usd`（参考视图，实际写入通过步骤 8） |
| 8 | `dws_ads_revenue` | LEFT JOIN 广告消耗表与地址映射，按全维度组合聚合 `ads_rev` |
| 9 | `dwd_edt_order_info` | 从 EDT 订单表取最新可用分区，过滤当日创单记录，获取 `order_id → edtmax_in_days` |
| 10 | `dwm_avg_edt_link` | 从过滤后数据提取有订单行为（`operation = 'order'`）的维度 + `order_id`，用于 EDT 关联 |
| 11 | `dws_avg_edt` | LEFT JOIN 地址映射和 EDT 订单信息，按维度组合计算 `AVG(edtmax_in_days)` |
| 12 | **INSERT OVERWRITE** | 以 `dws_main_metrics` 为主表，LEFT JOIN `dws_ads_revenue` 和 `dws_avg_edt`，按完整维度组合（12 个字段）匹配，写入目标表分区 |

### 注意事项

- **单文件单写入**：本表仅有 1 个 ETL 文件、1 个写入目标，不存在 multi-writer 风险。
- **INSERT OVERWRITE 全量覆盖**：每次执行覆盖指定 `grass_region + local_date` 分区，重跑幂等。
- **NULL-safe JOIN（`<=>`）**：最终写入阶段使用 NULL-safe 等值比较（`<=>`），保证维度字段含 NULL 时仍能正确匹配，避免数据丢失。
- **EDT 表时效性**：`sls_mart.dwd_edt_order_info_df` 使用动态最新分区（`MAX(grass_date)`），若该表存在延迟，`avg_edt` 可能出现空值偏多的情况。
- **`no_results_cnt` 与其他指标互斥**：两类记录通过 UNION ALL 合并，同一行不会同时存在有效指标和无结果指标；下游使用时需注意分别聚合。
- **`ads_rev` 的 `user_id` 过滤**：广告消耗表原始 SQL 中曾有 `user_id > 0` 过滤，但最终 `dws_ads_revenue` view 使用 LEFT JOIN 不再强制该条件，以避免遗漏匹配。
- **`item_id` 为数组类型**：广告收入匹配使用 `ARRAY_CONTAINS(b.item_id, a.item_id)`，跨多个商品 ID 时可能存在一对多匹配，需关注广告收入是否重复计入。

---

*文档生成时间：2026-05-17*