<!-- ads-workspace-gdoc-sync: gdoc_id=1rJ6yRf2f58OrCkzoa3yrtxxd9vxgiZlAM-8lyJzNJmE gdoc_url=https://docs.google.com/document/d/1rJ6yRf2f58OrCkzoa3yrtxxd9vxgiZlAM-8lyJzNJmE/edit -->

# srdi_mart.dwd_sr_data_warehouse_platform_nmv

**分层：** DWD（数据明细层）
**主键：** `grass_region` + `local_date` + `local_hour` + `item_id` + `user_id` + `model_id`（订单商品粒度明细）
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 每日按站点分区覆盖写入（INSERT OVERWRITE），数据延迟约 T+1
**访问频次：** 1585 次

---

## 业务描述

本表记录搜推平台（Search & Recommendation）维度下的**订单商品级 NMV（Net Merchandise Value）明细数据**，核心粒度为：每个站点（`grass_region`）、每笔订单的每件商品（`item_id` / `model_id`）、每个下单小时的 NMV 贡献。

数据来源于订单 ATC（Add-to-Cart）归因旅程表，通过 First-Touch 归因策略将 GMV/NMV 归属到对应的点击触点，并同时保留该触点的上溯来源（`source1_*`、`source2_*`），支持多级归因对比分析。

**核心业务场景：**

- 搜推各业务线、模块、版位的 NMV 收益统计与归因
- 广告（is_ads）与自然流量的 NMV 贡献拆分
- 算法标签（algo_tag）、特征分组（feature_group）维度的效果评估
- 搜索关键词（keyword）、入口（search_entrance）、排序方式（sort_type）对 GMV 的影响分析
- 跨站点 NMV 汇总（本地货币 vs USD 双口径）
- 多归因路径（当前触点 / source1 / source2）的归因对比

**适合回答的问题举例：**

- 某站点某天搜索广告带来的 NMV 是多少？
- 不同算法标签下的净订单量和 NMV 各占多少比例？
- 某关键词在推荐/搜索入口分别带来多少 NMV？
- 使用 First-Touch 归因时，source1 归因路径与当前触点的 NMV 差异有多大？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 站点区域代码（如 ID、MY、TH 等），所有查询必须指定此分区 |
| `local_date` | date | 订单下单时间对应的站点本地日期（按 `grass_region` 时区转换） |
| `local_hour` | int | 订单下单时间对应的站点本地小时（0–23） |
| `regional_date` | date | 订单下单时间对应的新加坡（SG）时区日期 |
| `regional_hour` | int | 订单下单时间对应的新加坡（SG）时区小时（0–23） |

---

### 维度：订单与商品标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 订单商品 ID（来源字段 `order_item_id`） |
| `model_id` | bigint | 订单商品型号 ID（来源字段 `order_model_id`） |
| `shop_id` | bigint | 店铺 ID |
| `user_id` | bigint | 下单用户 ID |
| `platform` | string | 下单平台（如 Android、iOS、Web 等） |

---

### 维度：当前触点搜推属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_ads` | boolean | 当前归因触点是否为广告流量（来源字段 `click_common_property.is_ads`） |
| `search_entrance` | string | 当前归因触点的搜索入口（来源字段 `click_search_property.search_entrance`） |
| `feature_detail` | string | 当前归因触点的特征明细（来源字段 `feature_detail_omni`） |
| `feature_group` | string | 当前归因触点的特征分组（来源字段 `feature_group_omni`；值为 'not found' / 'not found atc' / 'not found valid click' 时置为 NULL） |
| `reporting_business_line` | string | 当前触点对应的汇报业务线（来源字段 `business_line`） |
| `reporting_module` | string | 当前触点对应的汇报模块（来源字段 `module`） |
| `reporting_object` | string | 当前触点对应的汇报对象/版位（来源字段 `object`） |
| `algo_tag` | string | 当前触点算法标签（由 `get_all_tag` UDF 提取第 5 个元素，值为 'null' 时置为 NULL） |
| `sort_type` | string | 当前触点搜索排序方式（来源字段 `click_search_property.sort_by`） |
| `search_mid` | string | 当前触点搜索会话 ID（来源字段 `click_search_property.search_mid`） |
| `keyword` | string | 当前触点搜索关键词（来源字段 `click_search_property.keyword`） |

---

### 维度：归因来源 1（source1）搜推属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `source1_is_ads` | boolean | source1 触点是否为广告流量（来源字段 `source1_common_property.is_ads`） |
| `source1_search_entrance` | string | source1 触点搜索入口（来源字段 `source1_search_property.search_entrance`） |
| `source1_feature_detail` | string | source1 触点特征明细（来源字段 `source1_feature_detail_omni`） |
| `source1_feature_group` | string | source1 触点特征分组（值为 'not found' 系列时置为 NULL） |
| `source1_reporting_business_line` | string | source1 触点汇报业务线（来源字段 `source1_business_line`） |
| `source1_reporting_module` | string | source1 触点汇报模块（来源字段 `source1_module`） |
| `source1_reporting_object` | string | source1 触点汇报对象/版位（来源字段 `source1_object`） |
| `source1_algo_tag` | string | source1 触点算法标签（值为 'null' 时置为 NULL） |
| `source1_sort_type` | string | source1 触点搜索排序方式（来源字段 `source1_search_property.sort_by`） |
| `source1_search_mid` | string | source1 触点搜索会话 ID（来源字段 `source1_search_property.search_mid`） |
| `source1_keyword` | string | source1 触点搜索关键词（来源字段 `source1_search_property.keyword`） |

---

### 维度：归因来源 2（source2）搜推属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `source2_is_ads` | boolean | source2 触点是否为广告流量（来源字段 `source2_common_property.is_ads`） |
| `source2_search_entrance` | string | source2 触点搜索入口（来源字段 `source2_search_property.search_entrance`） |
| `source2_feature_detail` | string | source2 触点特征明细（来源字段 `source2_feature_detail_omni`） |
| `source2_feature_group` | string | source2 触点特征分组（值为 'not found' 系列时置为 NULL） |
| `source2_reporting_business_line` | string | source2 触点汇报业务线（来源字段 `source2_business_line`） |
| `source2_reporting_module` | string | source2 触点汇报模块（来源字段 `source2_module`） |
| `source2_reporting_object` | string | source2 触点汇报对象/版位（来源字段 `source2_object`） |
| `source2_algo_tag` | string | source2 触点算法标签（值为 'null' 时置为 NULL） |
| `source2_sort_type` | string | source2 触点搜索排序方式（来源字段 `source2_search_property.sort_by`） |
| `source2_search_mid` | string | source2 触点搜索会话 ID（来源字段 `source2_search_property.search_mid`） |
| `source2_keyword` | string | source2 触点搜索关键词（来源字段 `source2_search_property.keyword`） |

---

### 指标：NMV 与订单量

| 字段 | 类型 | 说明 |
|------|------|------|
| `net_order_cnt` | double | 净订单数（仅 `is_net_order=1` 时有值，计算公式：`order_fraction * atc_prorate * first_touchpoint_item`，否则为 0） |
| `nmv` | double | NMV（美元口径），计算公式：`first_touchpoint_item * nmv_usd * atc_prorate`，已按 ATC 比例和 First-Touch 权重分配 |
| `nmv_local` | double | NMV（站点本地货币口径），计算公式：`first_touchpoint_item * nmv * atc_prorate`，已按 ATC 比例和 First-Touch 权重分配 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，必须在 WHERE 子句中指定，否则将触发全表扫描，严重影响性能。
- **`local_date`**（或 `regional_date`）：日期分区字段，查询时务必限定日期范围，避免扫描无关分区。
- **`local_hour`** / **`regional_hour`**：小时级分区字段，按需使用；若只关心天级汇总，建议在 SELECT 中聚合全部 24 小时，不要随意丢弃某些小时分区。

### 不可直接 SUM 的字段

- **`nmv`、`nmv_local`、`net_order_cnt`**：字段本身已经过 `atc_prorate`（ATC 比例分摊）和 `first_touchpoint_item`（First-Touch 权重）加权，**可以直接 SUM 进行汇总**，但需注意：
  - 同一订单商品在 30 天滚动窗口内可能出现多条记录（取决于归因窗口过滤条件），聚合前须确认查询范围与归因逻辑一致。
  - 混用当前触点维度（无前缀）与 source1/source2 维度聚合时，归因口径不同，**不可将三套维度的 NMV 相加**，会导致重复计算。

### 时效性说明

- 表采用 **T+1 日更新**，每日覆盖写入对应分区，查询时请注意数据截止时间。
- 上游过滤条件为 `grass_date BETWEEN date_sub(local_date, 30) AND local_date`，即每次写入当天分区时，上游源表拉取的是**过去 30 天内的 ATC 旅程数据**，用于归因计算。这意味着：
  - 历史分区的数据**不会因新写入而被更新**（INSERT OVERWRITE 仅覆盖当天分区）。
  - 使用归因数据时，建议以最新写入分区为准，不建议跨长时间范围横向对比历史分区数据。
- 数据过滤条件 `tz_type='local'` 和 `first_touchpoint_item=1` 已在 ETL 层处理，消费侧无需重复过滤。

### 其他注意事项

- `feature_group` 中 'not found'、'not found atc'、'not found valid click' 已在 ETL 层归一化为 NULL，下游无需额外处理。
- `algo_tag`（及 source1/source2 同名字段）中 'null' 字符串已归一化为 NULL。
- `regional_date` / `regional_hour` 为新加坡时区，用于跨站点对齐时间口径时使用；单站点分析建议优先使用 `local_date` / `local_hour`。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg` | 订单 ATC 归因旅程明细表，提供订单商品信息、ATC 比例、归因触点的搜推属性（点击特征、搜索属性、广告标记等）、NMV 及时区转换所需字段 |

---

## ETL 逻辑摘要

### 数据流

```
traffic_omni_oa.dwd_order_item_atc_journey_ext_di__reg
    │  (过滤: grass_region、tz_type='local'、first_touchpoint_item=1、过去 30 天)
    ▼
TEMPORARY VIEW: nmv_add_all_tags_${grass_region_without_quote}
    │  (追加 all_tags / source1_all_tags / source2_all_tags，调用 get_all_tag UDF)
    ▼
INSERT OVERWRITE srdi_mart.dwd_sr_data_warehouse_platform_nmv
    (字段映射、NMV 计算、时区转换、feature_group/algo_tag 空值归一化)
```

### 关键步骤

**Step 1 — 创建 Temporary View `nmv_add_all_tags_*`**

- 从上游 ATC 旅程表筛选指定 `grass_region`、本地时区（`tz_type='local'`）、First-Touch 触点（`first_touchpoint_item=1`）、近 30 天数据。
- 调用 `get_all_tag` UDF，分别为当前触点、source1 触点、source2 触点生成标签数组（`all_tags`、`source1_all_tags`、`source2_all_tags`），其中第 5 个元素（index 4）为算法标签（`algo_tag`）。
- 调用 `get_feature_prefix` UDF，结合页面类型、`search_mid`、`search_entrance` 计算特征前缀，作为 `get_all_tag` 的入参。

**Step 2 — INSERT OVERWRITE 目标表**

- 从 Temporary View 进行字段映射，写入 `srdi_mart.dwd_sr_data_warehouse_platform_nmv`。
- **字段转换关键逻辑：**
  - `is_ads` 系列：强转 Boolean 类型。
  - `feature_group` 系列：将 'not found'、'not found atc'、'not found valid click' 置为 NULL。
  - `algo_tag` 系列：将 UDF 返回的 'null' 字符串置为 NULL。
  - `net_order_cnt`：仅净订单（`is_net_order=1`）时计算 `order_fraction * atc_prorate * first_touchpoint_item`，否则为 0。
  - `nmv`：`first_touchpoint_item * nmv_usd * atc_prorate`（美元）。
  - `nmv_local`：`first_touchpoint_item * nmv * atc_prorate`（本地货币）。
  - 分区字段 `local_date`/`local_hour`：通过 `timestamp_timezone_convert` UDF 将 `order_place_timestamp` 按 `grass_region` 时区转换。
  - 分区字段 `regional_date`/`regional_hour`：同上，固定转换为新加坡（SG）时区。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 并发冲突风险。
- **分区覆盖写入**：采用动态分区 INSERT OVERWRITE，每次执行仅覆盖当次 `grass_region` 对应的分区，历史分区不受影响。
- **站点参数化**：ETL SQL 使用 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 等参数，实际执行时由调度系统注入，每个站点独立运行一次。
- **UDF 依赖**：`get_all_tag`、`get_feature_prefix`、`timestamp_timezone_convert` 为自定义 UDF，若函数版本变更可能影响 `algo_tag`、`feature_group`、分区字段的计算结果，需关注 UDF 升级通知。
- **30 天滚动窗口**：上游数据过滤为近 30 天，归因旅程较长的订单在多个分区写入时，应注意避免与历史分区数据进行跨分区 SUM 导致重复计算。

---

*文档生成时间：2026-05-17*