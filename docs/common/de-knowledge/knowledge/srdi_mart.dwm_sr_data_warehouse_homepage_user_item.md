<!-- ads-workspace-gdoc-sync: gdoc_id=1Zuze3ZKseAv7s7k1zhtDo9Nljb4J5lxeXLQ2XtXVprs gdoc_url=https://docs.google.com/document/d/1Zuze3ZKseAv7s7k1zhtDo9Nljb4J5lxeXLQ2XtXVprs/edit -->

# srdi_mart.dwm_sr_data_warehouse_homepage_user_item

**分层：** DWM（数据集市中间层）
**主键：** `grass_region` + `local_date` + `operation` + `platform` + `user_id` + `item_id` + `feature_detail` + `source1_feature_detail` + `source2_feature_detail` + `card_type` + `module` + `source1_module` + `source2_module` + `object` + `source1_object` + `source2_object` + `is_ads` + `app_version`
**分区：** `grass_region` / `local_date` / `operation`
**更新频率：** 每日分区覆盖写（INSERT OVERWRITE），按 `grass_region` + `local_date` + `operation` 分区调度
**引用频次 / 访问频次：** 763

---

## 业务描述

本表是搜推数仓（SRDI）首页场景下的**用户 × 商品**粒度中间宽表，从 DWD 层平台事件明细表（`dwd_sr_data_warehouse_platform`）中过滤出**首页相关事件**（`page_type = 'home'` 或一级/二级来源页面为首页），并按用户、商品及多维度特征聚合各类行为与成交指标。

**核心业务场景：**
- 首页推荐模块的商品曝光、点击、成交效果分析
- 首页停留时长、滚动行为等用户体验指标分析
- 广告与自然流量（`is_ads`）的分层效果对比
- 按 App 版本、平台、卡片类型等维度下钻的首页商品表现评估
- 商品详情页停留时长（从首页引流的 product page）分析

**适合回答的问题示例：**
- 某天某大区首页各模块/位置的商品曝光量、点击率是多少？
- 广告商品与自然商品的 GMV 贡献对比如何？
- 不同 App 版本用户在首页的停留时长和滚动深度有何差异？
- 某商品在首页被哪些用户曝光、点击并下单？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区（Region），如 ID、TH、MY 等；分区键，**查询必须指定** |
| `local_date` | date | 本地日期；分区键，**查询必须指定** |
| `operation` | string | 行为事件类型，如 `view`、`impression`、`click`、`order` 等；分区键，同时作为 GROUP BY 维度写入数据 |

### 维度：用户与设备

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID |
| `platform` | string | 客户端平台，如 `android`、`ios` |
| `app_version` | string | 完整 App 版本号，如 `3.12.5` |
| `major_app_version` | string | 主版本号（通过正则 `regexp_extract(app_version, '(.+)(\\.)(.+)', 1)` 提取，即去掉最后一位次版本号的前缀部分） |

### 维度：商品与广告

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID |
| `is_ads` | boolean | 是否为广告商品（`true` = 广告，`false` = 自然流量） |
| `card_type` | string | 卡片类型，标识商品在首页中展示的卡片形态 |
| `location` | bigint | 商品在页面中的展示位置（取 `max(location)`，代表该聚合粒度下的最大位置值） |

### 维度：归因链路（事件特征与模块）

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_detail` | string | 当前事件的特征详情，用于标识推荐策略、实验等信息 |
| `source1_feature_detail` | string | 一级来源事件的特征详情（归因链路第一跳） |
| `source2_feature_detail` | string | 二级来源事件的特征详情（归因链路第二跳） |
| `module` | string | 当前事件所属模块（来自 `reporting_module`） |
| `source1_module` | string | 一级来源事件所属模块（来自 `source1_reporting_module`） |
| `source2_module` | string | 二级来源事件所属模块（来自 `source2_reporting_module`） |
| `object` | string | 当前事件的 object 标识（来自 `reporting_object`） |
| `source1_object` | string | 一级来源事件的 object 标识（来自 `source1_reporting_object`） |
| `source2_object` | string | 二级来源事件的 object 标识（来自 `source2_reporting_object`） |

### 指标：行为计数

| 字段 | 类型 | 说明 |
|---|---|---|
| `view_cnt` | bigint | `operation='view'` 的事件次数之和 |
| `imp_cnt` | bigint | `operation='impression'` 的事件次数之和（全类型曝光） |
| `click_cnt` | bigint | `operation='click'` 的事件次数之和（全类型点击） |
| `omni_imp_cnt` | bigint | `operation='omni_impression'` 的事件次数之和（全域曝光） |
| `omni_click_cnt` | bigint | `operation='omni_click'` 的事件次数之和（全域点击） |
| `ppv_cnt` | bigint | `operation='ppv'` 且非返回行为（`is_back=FALSE`）的事件次数之和（Product Page View） |
| `cart_cnt` | bigint | `operation='cart'` 的加购事件次数之和 |
| `order_cnt` | double | `operation='order'` 的下单事件次数之和 |

### 指标：首页专项行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `hp_imp_cnt` | bigint | 首页曝光数（`operation='impression'` 且 `page_type='home'` 且 `target_type <> 'animation_text'`） |
| `hp_view_cnt` | bigint | 首页浏览数（`operation='view'` 且 `page_type='home'`） |
| `hp_duration` | double | 首页停留时长之和（`original_operation='stay_view'` 且 `page_type='home'` 时累加 `page_stay_duration`） |
| `hp_is_scrolldown` | bigint | 首页向下滚动次数（`original_operation='action_scroll_down'` 且 `page_type='home'` 时计数） |
| `item_imp_cnt` | bigint | 商品卡曝光数（`operation='impression'` 且 `get_eventtype_and_cardtype(feature_detail, operation)[1]='1'` 的事件次数之和，过滤出商品类卡片） |
| `item_click_cnt` | bigint | 商品卡点击数（`operation='click'` 且 `get_eventtype_and_cardtype(feature_detail, operation)[1]='1'` 的事件次数之和，过滤出商品类卡片） |

### 指标：成交金额

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 成交总额（美元或标准货币，`place_order_gmv` 累加） |
| `gmv_local` | double | 成交总额（本地货币，`place_order_gmv_local` 累加） |
| `pc2_gmv` | double | PC2 口径成交总额（美元或标准货币，`pc2_gmv` 累加） |
| `pc2_gmv_local` | double | PC2 口径成交总额（本地货币，`pc2_gmv_local` 累加） |

### 指标：停留时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_stay_duration` | bigint | 页面停留时长之和（全场景，`page_stay_duration` 累加） |
| `product_page_stay_duration` | double | 商品详情页停留时长之和（`original_page_type='product'` 时累加 `page_stay_duration`） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则触发全分区扫描，代价极高。
- **`local_date`**：必须指定具体日期（或合理范围），本表为每日分区表，无历史滚动窗口字段，跨天分析需在调用层自行 UNION 或聚合。
- **`operation`**：强烈建议指定，`operation` 是分区键，不同 operation 分区数据行代表不同行为类型。**注意：同一 `user_id` + `item_id` 的记录在不同 `operation` 分区中均独立存在**，跨 operation 分区联合分析时需注意避免重复计算。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `location` | 由 `max(location)` 聚合得到，代表位置最大值，多行 SUM 无业务意义 |
| `major_app_version` | 维度字段，不可聚合 |
| `hp_duration` / `product_page_stay_duration` | 虽可 SUM，但注意这两个字段来源于特定 `original_operation` 条件，与 `page_stay_duration` 存在口径差异，不可混用 |
| `gmv` / `gmv_local` / `pc2_gmv` / `pc2_gmv_local` | 跨 `operation` 分区 SUM 会导致重复计算（GMV 仅在 `operation='order'` 分区有实际值，其他分区该字段可能为 0 或 NULL，但需确认后再决定是否跨分区 SUM） |
| `order_cnt` | 类型为 `double`，跨 `operation` 分区 SUM 时同上，需限定 `operation='order'` 分区 |

### 时效性说明

- 本表为 **T+1 每日刷新**表，数据反映当日（`local_date`）内的行为汇总。
- 无内置滑动窗口（`*_nd`、`*_td`）字段，近 N 天窗口需在查询层自行处理。
- 写入方式为 `INSERT OVERWRITE`，同一 `(grass_region, local_date, operation)` 分区每次调度均全量覆盖，无增量历史累积风险。

### 其他注意事项

- `item_imp_cnt` 和 `item_click_cnt` 依赖 UDF `get_eventtype_and_cardtype`，该函数以 `feature_detail` 和 `operation` 为入参，`[1]='1'` 表示商品类卡片。与 `imp_cnt`、`click_cnt` 口径不同，前者仅统计商品卡，后者为全类型。
- `hp_imp_cnt` 排除了 `target_type='animation_text'` 的曝光，与 `imp_cnt` 存在口径差异。
- `hp_duration` 与 `page_stay_duration` 来源于不同的 `original_operation` 条件，不可直接相互替代。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | DWD 层平台事件明细表，提供用户行为事件的全量字段，包括 `page_type`、`original_operation`、`operation_cnt`、`place_order_gmv`、`page_stay_duration` 等原始指标及归因链路字段 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
    │
    │  过滤：grass_region + local_date + operation IN (...) + 首页条件
    │  （page_type='home' OR source1_page_type='home' OR source2_page_type='home'）
    │
    ▼
  [聚合层]
  GROUP BY：platform, user_id, app_version, item_id, is_ads,
            feature_detail, source*_feature_detail, operation, card_type,
            reporting_module*, reporting_object*
    │
    ▼
srdi_mart.dwm_sr_data_warehouse_homepage_user_item
PARTITION (grass_region, local_date, operation)
```

### 关键步骤

1. **分区过滤**：从 DWD 表按 `grass_region`、`local_date`、`operation IN (${operation})` 过滤，同时要求当前页面或归因来源页面为首页（`page_type='home'` / `source1_page_type='home'` / `source2_page_type='home'`）。
2. **维度派生**：
   - `major_app_version`：通过 `regexp_extract(app_version, '(.+)(\\.)(.+)', 1)` 从完整版本号提取主版本。
   - `module` / `source1_module` / `source2_module`：分别由 `reporting_module` / `source1_reporting_module` / `source2_reporting_module` 重命名。
   - `object` / `source1_object` / `source2_object`：同上，由 `reporting_object` 系列字段重命名。
3. **条件聚合**：对各行为计数字段使用 `SUM(if(operation=..., operation_cnt, 0))` 模式分别统计各行为类型；首页专项指标按 `page_type`、`original_operation`、`target_type` 等附加条件过滤后聚合；`item_imp_cnt` 和 `item_click_cnt` 借助 UDF `get_eventtype_and_cardtype` 识别商品类卡片。
4. **位置取最大值**：`location` 字段使用 `max(location)` 聚合，保留该维度组合下的最大位置。
5. **分区写入**：使用 `INSERT OVERWRITE ... PARTITION (grass_region=..., local_date=..., operation)` 动态分区写入，`operation` 由 SELECT 列中的 `operation` 字段值决定写入哪个子分区。

### 注意事项

- **单 Writer**：`etl_file_count=1`，无多路写入，无分区竞争风险。
- **动态分区**：`operation` 为动态分区列，单次 ETL 任务可能写入多个 `operation` 子分区，需确保 Spark 动态分区参数已开启（`hive.exec.dynamic.partition.mode=nonstrict`）。
- **参数化调度**：`${grass_region}`、`${local_date}`、`${operation}` 均为调度参数，生产调度时需确认 `operation` 参数枚举值完整，避免遗漏行为类型分区。
- **UDF 依赖**：`get_eventtype_and_cardtype` 为自定义 UDF，跨环境迁移或 SQL 复用时需确保该 UDF 已注册。
- **覆盖写风险**：`INSERT OVERWRITE` 模式下，若调度重跑时 `${operation}` 参数范围缩小，历史已写入的 operation 子分区不会被清除，可能导致分区间数据不一致，需关注重跑策略。

---

*文档生成时间：2026-05-17*