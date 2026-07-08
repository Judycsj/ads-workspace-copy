<!-- ads-workspace-gdoc-sync: gdoc_id=1KdwlnVzIc4TFoSHApaJF6XshgcDr6FtBOjdTLPI-AWU gdoc_url=https://docs.google.com/document/d/1KdwlnVzIc4TFoSHApaJF6XshgcDr6FtBOjdTLPI-AWU/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d

**分层**：DWS（数据汇总层）
**主键**：`grass_region` + `local_date` + `platform` + `user_id` + `device_id` + `item_id` + `shop_id` + `is_ads` + `is_direct` + `keyword` + `feature_detail` + `scenario_tags` + `dedup_scenario_tags` + `search_entrance` + `search_mid` + `sort_type` + `location` + `page_type` + `page_section` + `target_type` + `original_page_type` + `is_llm_deepthinking`
**分区**：`grass_region`（大区）, `local_date`（业务日期）
**更新频率**：每日一次（T+1）
**引用频次 / 访问频次**：5,233 次

---

## 业务描述

本表是搜推（SR）数仓平台的用户-商品-关键词维度基准宽表，按自然日（`1d`）粒度聚合搜索场景下各链路行为数据。

**核心业务场景**：

- **搜索漏斗分析**：覆盖从曝光（impression）→ 点击（click）→ 商详浏览（ppv/view）→ 加购（cart）→ 下单（order）的完整行为链路，支持各环节转化率计算。
- **全域（Omni）搜索归因**：通过 `omni_imp_cnt` / `omni_click_cnt` 及 `is_direct` 标记，支持直接归因与间接归因（source1/source2 溯源）的双路径分析。
- **ATC 归因窗口分析**：提供同日归因（`atc_same_day_*`）和 3 日窗口归因（`atc_within_3day_*`）的订单及 GMV 指标，支持短周期购买行为评估。
- **场景标签分析**：通过 `scenario_tags` / `dedup_scenario_tags` 对搜索场景（业务线、模块、算法标签等）进行多维透视，支持去重归因逻辑。
- **LLM 深度思考功能评估**：通过 `is_llm_deepthinking` 标记，支持 AI 搜索新功能的效果追踪。

**适合回答的问题**：

- 特定关键词/商品在某大区某日的曝光、点击、转化表现如何？
- 直接归因与间接归因的 GMV 各占多少？
- 搜索引导的加购行为在同日和 3 日内的订单转化率分别是多少？
- 特定平台/入口/排序方式的搜索效果对比？
- LLM 深度思考功能开启后对点击率和转化率的影响？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 SG、MY、TH 等，用于物理分区隔离 |
| `local_date` | date | 业务本地日期，数据的自然日分区键 |

### 维度：用户与设备

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID |
| `device_id` | string | 设备 ID，未登录用户的匿名标识 |
| `platform` | string | 平台类型，如 iOS、Android、Web 等 |

### 维度：商品与店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID |
| `shop_id` | bigint | 店铺 ID |

### 维度：搜索上下文

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词 |
| `search_entrance` | string | 搜索入口，如主搜、店铺搜等 |
| `search_mid` | string | 搜索会话中间标识，用于关联同一次搜索的行为序列 |
| `sort_type` | string | 搜索结果排序方式，如综合排序、销量排序等 |
| `location` | string | 搜索发生时的地理位置信息 |
| `feature_detail` | string | 特征详情，用于标识具体的算法特征组合或实验分组 |

### 维度：页面与场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_type` | string | 当前页面类型（经过 Omni 映射后的 mapped_page_type） |
| `original_page_type` | string | 原始页面类型，来自 `dim_atlas_search_feature_map` 的 page_type，当映射不存在时回退为 page_type |
| `page_section` | string | 页面版块，取 page_section 数组的第一个元素 |
| `target_type` | string | 目标类型，标识曝光/点击对象的类型 |
| `scenario_tags` | array\<string\> | 场景标签数组，由业务线、模块、对象、特征组、算法标签、页面类型综合构建 |
| `dedup_scenario_tags` | array\<string\> | 去重后的场景标签数组；直接归因行（`is_direct=true`）与 `scenario_tags` 相同；间接归因行剔除了更直接来源已覆盖的标签 |

### 维度：归因与标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | boolean | 是否为广告流量 |
| `is_direct` | boolean | 是否为直接归因；`true` 表示该行为发生在当前曝光/点击直接触达的页面，`false` 表示通过 source1/source2 链路间接归因 |
| `is_llm_deepthinking` | boolean | 是否触发了 LLM 深度思考功能 |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | int | 普通曝光次数；仅来源于 impression 事件行，omni 行为行置 NULL |
| `click_cnt` | int | 普通点击次数；仅来源于 click 事件行，omni 行为行置 NULL |
| `omni_imp_cnt` | int | 全域曝光次数（omni_impression 事件）；仅来源于 omni 行为行，普通曝光行置 NULL |
| `omni_click_cnt` | int | 全域点击次数（omni_click 事件）；仅来源于 omni 行为行，普通点击行置 NULL |

### 指标：浏览行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `view_cnt` | int | 商详页浏览次数（view 事件总计，含返回）；仅来源于普通行为行，omni 行为行置 NULL |
| `view_not_back_cnt` | int | 商详页浏览次数（排除回退行为，`is_back=false`）；仅来源于普通行为行 |
| `ppv_cnt` | int | PPV（Product Page View）次数，排除回退（`is_back=false`）；仅来源于 omni 行为行 |
| `ppv_include_isback_cnt` | int | PPV 次数（含回退行为）；仅来源于 omni 行为行 |

### 指标：加购与订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | int | 加购次数（cart 事件）；仅来源于 omni 行为行 |
| `order_cnt` | double | 下单次数（order 事件）；仅来源于 omni 行为行 |

### 指标：GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 下单 GMV（美元/平台默认货币，`place_order_gmv`）；仅来源于 omni 行为行 |
| `gmv_local` | double | 下单 GMV（本地货币，`place_order_gmv_local`）；仅来源于 omni 行为行 |
| `pc2_gmv` | double | PC2 口径 GMV（`pc2_gmv`，特定归因口径）；仅来源于 omni 行为行 |

### 指标：ATC 归因窗口

| 字段 | 类型 | 说明 |
|---|---|---|
| `atc_same_day_order_cnt` | double | 加购当日（`window_day=1`）归因订单数；仅来源于 omni 行为行 |
| `atc_within_3day_order_cnt` | double | 加购后 3 日内（`window_day` 在 1~4 之间）归因订单数；仅来源于 omni 行为行 |
| `atc_same_day_gmv` | double | 加购当日归因 GMV；仅来源于 omni 行为行 |
| `atc_within_3day_gmv` | double | 加购后 3 日内归因 GMV；仅来源于 omni 行为行 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，为物理分区键。缺少该条件将触发全分区扫描，产生极大资源消耗。
- **`local_date`**：必须指定，为物理分区键。建议使用精确日期或有界日期范围，避免全量扫描。
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-05-16'
  ```

### 不可直接 SUM 的字段

- **`scenario_tags` / `dedup_scenario_tags`**：数组类型，不支持直接聚合，需先 EXPLODE 展开后按标签分组统计。
- **`feature_detail`**：字符串维度，存在维度拼接含义，聚合前请确认业务语义。
- **指标列的 NULL 值语义**：本表各指标列存在业务性 NULL（非缺失，而是该行为类型不适用），例如 `imp_cnt` 在 omni 行为行为 NULL，`ppv_cnt` 在普通行为行为 NULL。**直接 SUM 时 NULL 会被忽略，跨类型合并时需特别注意避免重复计数**。
- **`order_cnt` / `gmv` 等订单指标**：来源于 omni 行为链路，`is_direct=true` 和 `is_direct=false` 的行均包含订单数据，**直接对全表 SUM 会导致重复计数**。需结合 `is_direct` 或 `dedup_scenario_tags` 进行去重归因计算。
- **`atc_*` 系列字段**：为预聚合的归因窗口指标，不可与 `order_cnt` 简单叠加，两者归因窗口定义不同。

### 时效性说明

- 本表为 **每日全量覆写**（`INSERT OVERWRITE PARTITION`），数据对应 `local_date` 所在自然日，通常于次日（T+1）完成更新。
- 不包含跨日累计指标（无 `_nd`、`_td` 后缀逻辑），如需多日汇总需在查询层聚合多个 `local_date` 分区。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 核心明细事件数据源，提供 impression、click、view、omni_impression、omni_click、ppv、cart、order 等所有行为事件及归因字段 |
| `traffic_omni_oa.dim_atlas_search_feature_map__reg_live` | 搜索页面类型映射维表，用于将 omni 场景的 mapped_page_type 回溯到原始 original_page_type |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
          │
          ├─── [operation IN ('impression','click','view')]
          │          └─→ dwd_imp_clk_view（普通曝光/点击/浏览汇总）
          │
          └─── [operation IN ('omni_impression','omni_click','ppv','cart','order')]
                     └─→ dwd_omni_with_tag（全域行为汇总，含 source1/source2 归因链路）

traffic_omni_oa.dim_atlas_search_feature_map__reg_live
          └─→ omni_search_mapping_scope（页面类型映射）

dwd_omni_with_tag ⊕ omni_search_mapping_scope
          └─→ dwm_table（直接归因 + source1 间接归因 + source2 间接归因 UNION ALL 普通行为）
                     └─→ dws_table（GROUP BY 去重 + 零值转 NULL）
                                └─→ INSERT OVERWRITE 目标表
```

### 关键步骤

1. **Statement 1 — `omni_search_mapping_scope`**：从维表 `dim_atlas_search_feature_map__reg_live` 取最新分区数据，构建 `mapped_page_type → original_page_type` 的映射关系。

2. **Statement 2 — `dwd_imp_clk_view`**：从 DWD 层过滤普通行为事件（impression / click / view），按完整维度 GROUP BY，聚合 `imp_cnt`、`click_cnt`、`view_cnt`、`view_not_back_cnt`，并通过 `build_scenario_tags` UDF 构建 `scenario_tags`。

3. **Statement 3 — `dwd_omni_with_tag`**：从 DWD 层过滤全域行为事件（omni_impression / omni_click / ppv / cart / order），按完整维度（含 source1/source2 归因链路字段）GROUP BY，聚合全域行为指标及 ATC 归因窗口指标，并分别为主路径、source1、source2 构建 `scenario_tags`。

4. **Statement 4 — `dwm_table`**：通过 4 路 UNION ALL 展开归因层次：
   - **第 1 路**：omni 直接归因行（`is_direct=true`），`dedup_scenario_tags = scenario_tags`；
   - **第 2 路**：source1 间接归因行（`is_direct=false`，`source1_feature_detail` 非空且不等于主 feature_detail），`dedup_scenario_tags` 剔除主路径已覆盖标签；
   - **第 3 路**：source2 间接归因行（`is_direct=false`，`source2_feature_detail` 非空且不等于 source1/主 feature_detail），`dedup_scenario_tags` 剔除 source1 和主路径已覆盖标签；
   - **第 4 路**：普通行为（impression/click/view）行（`is_direct=true`），omni 相关指标置 NULL。
   - 各路 omni 行为行的 `original_page_type` 通过 LEFT JOIN `omni_search_mapping_scope` 补全，找不到映射时回退为 `page_type` 本身。

5. **Statement 5 — `dws_table`**：对 `dwm_table` 按所有维度 GROUP BY，对各指标执行 `IF(SUM > 0, SUM, NULL)` 模式聚合——即汇总为零时保持 NULL，避免引入误导性的零值。

6. **Statement 6 — INSERT OVERWRITE**：将 `dws_table` 以 `OVERWRITE` 方式写入目标表，按 `(grass_region, local_date)` 分区覆盖。

### 注意事项

- **单 Writer，无多写冲突**：本表仅有 1 个 ETL 文件，`multi_writer=false`，无分区并发写入风险。
- **零值转 NULL 语义**：`dws_table` 层对所有指标使用 `IF(SUM > 0, SUM, NULL)` 处理，下游查询需使用 `COALESCE` 或 `SUM(COALESCE(col, 0))` 防止意外过滤零值数据。
- **omni 行为与普通行为指标互斥**：`imp_cnt`/`click_cnt`/`view_cnt`/`view_not_back_cnt` 仅在普通行为行有值；`ppv_cnt`/`cart_cnt`/`order_cnt`/`gmv*`/`atc_*`/`omni_*` 仅在 omni 行为行有值，两类指标在同一行中不会同时存在非 NULL 值，跨类型聚合时须分开处理。
- **间接归因重复计数风险**：`is_direct=false` 的 source1/source2 行与 `is_direct=true` 的主路径行共享相同的订单/GMV 指标值，全表 SUM 时会产生多倍计数，**务必按 `is_direct` 或 `dedup_scenario_tags` 进行归因口径选择**。
- **`dim_atlas_search_feature_map__reg_live` 取最新分区**：使用 `MAX(grass_date)` 动态获取最新维表数据，若维表更新延迟可能影响 `original_page_type` 映射准确性。

---

*文档生成时间：2026-05-17*