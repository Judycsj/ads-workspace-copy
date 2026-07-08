<!-- ads-workspace-gdoc-sync: gdoc_id=1mYgA4qxWG5aOpvHzpLO6xrXlpju-xTHCV5IaVBt1CrE gdoc_url=https://docs.google.com/document/d/1mYgA4qxWG5aOpvHzpLO6xrXlpju-xTHCV5IaVBt1CrE/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_level_count_statistics_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `platform` + `is_ads` + `scenario_tag`
**分区：** `grass_region`（大区）, `local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 4,094 次

---

## 业务描述

本表为搜推（SR）数仓平台维度下、**场景粒度**的每日用户行为去重统计宽表，覆盖曝光、点击、PPV（商品详情页浏览）、加购、下单、内容浏览等核心电商行为的**去重用户数（UU）**指标。

**核心业务场景：**
- 按平台（`platform`）、是否广告（`is_ads`）、场景标签（`scenario_tag`）多维度下钻，评估各推荐/搜索场景的流量质量与用户规模。
- 区分商品级曝光/点击（`item_imp_uu` / `item_click_uu`）与整体曝光/点击（`imp_uu` / `click_uu`），支持商品与非商品内容的分层分析。
- 支持广告与自然流量的对比分析（`is_ads` 维度）。
- `scenario_tag = '__ALL__'` 行为全场景汇总数据，可直接用于平台整体指标读取，无需手动聚合各场景。

**适合回答的问题：**
- 某大区、某平台在指定日期内，各推荐场景（如首页推荐、搜索结果页等）的日活用户数（DAU）是多少？
- 广告与自然流量在曝光、点击、加购、下单 UU 上的差异如何？
- 商品维度的曝光/点击用户规模与整体有何差异？
- 各场景的用户转化漏斗（曝光→点击→详情页→加购→下单）中，每层去重用户数为多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 SG、MY、TH 等，ETL 通过参数 `${grass_region}` 传入，每次覆写对应分区 |
| `local_date` | date | 业务日期（本地时区），ETL 通过参数 `${local_date}` 传入，每日全量覆写当日分区 |

### 维度：平台与场景属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 终端平台类型，如 android、ios、pc 等，来源于上游 DWM 表 |
| `is_ads` | string | 是否广告流量，`'true'` 表示广告，`'false'` 表示自然流量；由上游布尔字段转换为字符串 |
| `scenario_tag` | string | 场景标签，由上游 `scenario_tags` 数组展开（EXPLODE）得到单值；特殊值 `'__ALL__'` 代表全场景汇总行 |

### 指标：整体行为去重用户数

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uu` | bigint | 当日发生曝光行为的去重用户数（`imp_cnt > 0` 的 user_id 去重计数） |
| `click_uu` | bigint | 当日发生点击行为的去重用户数（`click_cnt > 0` 的 user_id 去重计数） |
| `ppv_uu` | bigint | 当日发生 PPV（商品详情页浏览）行为的去重用户数（`ppv_cnt > 0` 的 user_id 去重计数） |
| `cart_uu` | bigint | 当日发生加购行为的去重用户数（`cart_cnt > 0` 的 user_id 去重计数） |
| `order_uu` | bigint | 当日发生下单行为的去重用户数（`order_cnt > 0` 的 user_id 去重计数） |
| `view_uu` | bigint | 当日发生内容浏览行为的去重用户数（`view_cnt > 0` 的 user_id 去重计数） |

### 指标：商品维度行为去重用户数

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_imp_uu` | bigint | 当日对商品（`target_type = 'item'`）产生曝光行为的去重用户数（`item_imp_cnt > 0` 的 user_id 去重计数） |
| `item_click_uu` | bigint | 当日对商品（`target_type = 'item'`）产生点击行为的去重用户数（`item_click_cnt > 0` 的 user_id 去重计数） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则触发全分区扫描，严重影响性能并可能返回多区域混合数据。
- **`local_date`**：必须指定具体日期或日期范围，本表为每日分区，不加日期过滤会扫描全量历史数据。

```sql
-- 推荐写法
WHERE grass_region = 'SG'
  AND local_date = '2024-01-01'
```

### 不可直接 SUM 的字段

- **所有 `*_uu` 指标（`imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`order_uu`、`view_uu`、`item_imp_uu`、`item_click_uu`）** 均为预聚合的去重用户数（COUNT DISTINCT），**跨 `scenario_tag` / `platform` / `is_ads` 维度直接 SUM 会产生重复计数**，因为同一用户可能出现在多个场景行中。
  - 若需跨场景汇总全平台 UU，应使用 `scenario_tag = '__ALL__'` 行，而非对所有 `scenario_tag` 求和。
  - 若需跨 `platform` 或 `is_ads` 聚合，需回溯上游明细表重新计算去重。

### 场景标签特殊值说明

- `scenario_tag = '__ALL__'`：该行为同一 `platform` + `is_ads` 组合下的**全场景汇总**，所有 UU 指标已在上游按用户去重。可直接用于"不区分场景"的整体指标读取。
- `scenario_tag = ''`（空字符串）：上游 `scenario_tags` 数组为 NULL 或空时，LATERAL VIEW OUTER EXPLODE 展开后用 `nvl` 填充为空字符串，代表未命中任何场景标签的流量。

### 时效性说明

- 本表为 `_1d` 后缀的日粒度表，T+1 产出，通常在次日业务时间可用。
- 不可用于实时或准实时查询需求。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 核心上游明细表，提供用户粒度的平台、是否广告、场景标签、行为类型（impression/click/ppv/cart/order/view）及各行为计数，支持主场景标签（`scenario_tags`/`feature_detail`）、来源1（`source1_scenario_tags`/`source1_feature_detail`）、来源2（`source2_scenario_tags`/`source2_feature_detail`）三路场景归因 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_platform_user_item
    │
    ├─ [三路 UNION ALL 场景归因] ──► Temporary View: raw_data
    │       主场景路 (scenario_tags / feature_detail)
    │       来源1路 (source1_scenario_tags / source1_feature_detail, 过滤非 NULL)
    │       来源2路 (source2_scenario_tags / source2_feature_detail, 过滤非 NULL)
    │
    ▼
CACHE TABLE: base_table（用户粒度聚合 + scenario_tag EXPLODE）
    │
    ├─ LATERAL VIEW OUTER EXPLODE(scenario_tags) → 各场景标签行
    └─ '__ALL__' 汇总行（不展开，直接聚合）
    │
    ▼
INSERT OVERWRITE（COUNT DISTINCT 去重，写目标表分区）
srdi_mart.dws_sr_data_warehouse_platform_scenario_level_count_statistics_1d
PARTITION (grass_region, local_date)
```

### 关键步骤

**Step 1 — 创建临时视图 `raw_data`（三路 UNION ALL）**

从上游 DWM 表按 `grass_region` + `local_date` 过滤，对 `impression / click / ppv / cart / order / view` 六类行为进行用户粒度预聚合，分三路读取：
- **主路**：使用 `scenario_tags` 和 `feature_detail`，无额外过滤
- **来源1路**：使用 `source1_scenario_tags` 和 `source1_feature_detail`，仅处理 `source1_feature_detail IS NOT NULL` 的记录
- **来源2路**：使用 `source2_scenario_tags` 和 `source2_feature_detail`，仅处理 `source2_feature_detail IS NOT NULL` 的记录

`target_type` 字段通过解析 `feature_detail`（按 `-` 分割取第3段，若无则取第2段）获得，用于后续区分商品与非商品行为。

**Step 2 — 构建缓存中间表 `base_table`（场景展开 + 用户聚合）**

将 Step 1 的结果通过 `LATERAL VIEW OUTER EXPLODE(scenario_tags)` 将场景标签数组展开为单行，`nvl(scenario_tag, '')` 处理空值；同时追加 `scenario_tag = '__ALL__'` 的全场景汇总行（不展开，直接按 `platform / is_ads / user_id` 聚合）。在本步骤计算 `item_imp_cnt`（仅当 `imp_cnt > 0` 且 `target_type = 'item'`）和 `item_click_cnt`（仅当 `click_cnt > 0` 且 `target_type = 'item'`）。结果缓存至内存+磁盘（`MEMORY_AND_DISK_SER`）以提升后续多次扫描效率。

**Step 3 — INSERT OVERWRITE 写目标分区**

在 `base_table` 上按 `scenario_tag` + `platform` + `is_ads` 分组，通过 `COUNT(DISTINCT IF(行为计数>0, user_id, NULL))` 计算各行为去重用户数，覆写写入目标表对应的 `grass_region` + `local_date` 分区。

### 注意事项

- **非 multi-writer**：本表仅有一个 ETL 文件写入，不存在多任务并发写同一物理表的风险。
- **分区覆写（INSERT OVERWRITE）**：每次运行会覆盖对应 `grass_region` + `local_date` 分区的全部数据，重跑幂等安全。
- **三路场景归因导致用户行为计数放大**：同一用户的同一次行为若同时命中主路、来源1路、来源2路，会在 `raw_data` 中出现最多三行，最终在 `base_table` 合并聚合时会被累加。这是有意为之的多归因设计，分析时需理解其含义，避免与单归因口径混用。
- **`target_type` 解析依赖 `feature_detail` 格式**：若上游 `feature_detail` 格式变更（`-` 分隔符位置变化），`item_imp_uu` / `item_click_uu` 指标会受影响。
- **`is_ads` 类型转换**：上游为布尔型，ETL 转换为字符串 `'true'` / `'false'`，查询时注意使用字符串比较。

---

*文档生成时间：2026-05-17*