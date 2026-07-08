<!-- ads-workspace-gdoc-sync: gdoc_id=1ycpBkVJAWRjFjj_reNwzFSN5uRua2n6BIG7N4GCwxFE gdoc_url=https://docs.google.com/document/d/1ycpBkVJAWRjFjj_reNwzFSN5uRua2n6BIG7N4GCwxFE/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_order_benchmark_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `platform` + `user_id` + `device_id` + `item_id` + `shop_id` + `order_id` + `is_ads` + `is_direct` + `feature_detail` + `page_type` + `page_section` + `target_type` + `keyword` + `sort_type` + `location` + `search_entrance` + `search_mid`
**分区：** `grass_region`（站点区域），`local_date`（本地日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 1366 次

---

## 业务描述

本表是搜推数仓（SRDI）平台订单基准宽表，以**订单归因粒度**沉淀每日搜索/推荐场景下的订单核心指标。

表的核心业务场景为：

- **多触点（Omni）归因分析**：每笔订单除直接归因来源（`is_direct = true`）外，还向上游追溯至 source1、source2 等间接引流场景（`is_direct = false`），从而支持订单在多个触点场景间的分摊与拆解；`dedup_scenario_tags` 字段用于去重计算，避免同一订单在多场景中被重复计数。
- **搜索/推荐场景 GMV & 订单量统计**：按平台、页面类型、场景标签、关键词、排序方式等维度统计下单 GMV 和订单量，作为北极星指标 benchmark 的基础。
- **ATC（加购转化）窗口分析**：提供当日及 3 日内加购后成单的 GMV 和订单量，辅助分析加购到转化的漏斗时效。
- **实验组归因**：通过 `exp_group_ids` 支持 A/B 实验效果评估。

**适合回答的典型问题：**
- 某区域/平台在搜索场景下某天的 GMV 和订单量是多少？
- 某关键词、某排序策略带来的直接/间接归因订单分布如何？
- 不同场景标签（`scenario_tags`）下的订单贡献有多少，去重后实际贡献（`dedup_scenario_tags`）如何？
- 加购后当日成单与 3 日内成单的 GMV 对比情况？
- 广告（`is_ads`）与自然流量的订单 GMV 差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 SG、MY、TH 等，分区键之一 |
| `local_date` | date | 本地日期，数据统计日期，分区键之一 |

### 维度：平台与用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 终端平台，如 iOS、Android、PC 等 |
| `user_id` | bigint | 用户 ID |
| `device_id` | string | 设备 ID |

### 维度：商品与订单标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID |
| `shop_id` | bigint | 店铺 ID |
| `order_id` | bigint | 订单 ID |

### 维度：归因与场景标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | boolean | 是否为广告流量归因订单 |
| `is_direct` | boolean | 是否为直接归因（`true`=直接触点，`false`=间接上游触点 source1/source2） |
| `scenario_tags` | array\<string\> | 当前归因触点的场景标签数组，由 `build_scenario_tags` UDF 基于业务线、模块、对象、feature group、algo tag、页面类型构建 |
| `dedup_scenario_tags` | array\<string\> | 去重后的场景标签数组；直接归因时与 `scenario_tags` 相同；间接归因时剔除已被直接或上游触点覆盖的标签，用于多场景汇总时防止订单重复计数 |
| `exp_group_ids` | array\<bigint\> | 命中的实验组 ID 列表，用于 A/B 实验分析 |

### 维度：页面与流量来源

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_type` | string | 归因触点的页面类型（经 Atlas 特征映射后的 mapped_page_type） |
| `original_page_type` | string | 归因触点的原始页面类型（映射前的 page_type），来源于 `dim_atlas_search_feature_map` |
| `page_section` | string | 页面区块/坑位标识，取 page_section 数组的第一个元素 |
| `target_type` | string | 归因目标类型，如商品、店铺等 |
| `search_entrance` | string | 搜索入口标识 |
| `search_mid` | string | 搜索中间标识（search mid），用于标记搜索会话 |
| `feature_detail` | string | 特征详情，标识具体的算法特征或推荐位标识符 |
| `keyword` | string | 搜索关键词 |
| `sort_type` | string | 排序方式，如综合、价格、销量等 |
| `location` | string | 地理位置信息 |

### 指标：订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 订单量（`operation='order'` 且 `operation_cnt > 0` 的汇总值；汇总结果 ≤ 0 时置 null） |
| `gmv` | double | 下单 GMV，美元（汇总结果 ≤ 0 时置 null） |
| `gmv_local` | double | 下单 GMV，本地货币（汇总结果 ≤ 0 时置 null） |
| `pc2_gmv` | double | PC2 口径 GMV，美元（汇总结果 ≤ 0 时置 null） |

### 指标：ATC 时间窗口订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `atc_same_day_order_cnt` | double | 加购后当日成单订单量（`window_day = 1`；汇总结果 ≤ 0 时置 null） |
| `atc_within_3day_order_cnt` | double | 加购后 3 日内成单订单量（`window_day` 在 1～4 之间，即含当日的3日窗口；汇总结果 ≤ 0 时置 null） |
| `atc_same_day_gmv` | double | 加购后当日成单 GMV，美元（汇总结果 ≤ 0 时置 null） |
| `atc_within_3day_gmv` | double | 加购后 3 日内成单 GMV，美元（汇总结果 ≤ 0 时置 null） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤**：查询时必须同时指定 `grass_region` 和 `local_date`，否则将触发全分区扫描，产生大量资源消耗。
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 如需多日汇总，使用 `local_date BETWEEN '2024-01-01' AND '2024-01-07'`，避免使用函数包裹分区字段。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `scenario_tags` / `dedup_scenario_tags` | array 类型，不可直接 SUM；汇总场景须展开（`EXPLODE`）后按 `dedup_scenario_tags` 统计，防止同一订单在多场景下重复计数 |
| `exp_group_ids` | array 类型，须 `EXPLODE` 后按实验组聚合 |
| `order_cnt` / `gmv` / `gmv_local` / `pc2_gmv` / `atc_*` | 本表已按维度预聚合，可跨维度 SUM，但须注意：**同一笔订单（`order_id`）可能同时存在 `is_direct=true` 和 `is_direct=false` 的多行**（多触点归因展开），直接 SUM 全表会导致订单重复计数。汇总实际订单量时须按业务目的选择是否过滤 `is_direct=true` 或使用 `dedup_scenario_tags` 口径 |
| `gmv_local` | 不同区域货币单位不同，跨 `grass_region` 汇总无业务意义 |

### 时效性说明

- 本表为 **T+1 日更新**，`local_date` 为数据所属业务日期，非写入日期。
- `atc_within_3day_*` 字段的 3 日窗口基于上游 DWD 表的 `window_day` 字段（`window_day BETWEEN 1 AND 4`），时间窗口在上游已固化，本表不做二次窗口计算。
- `is_direct = false` 的行为间接归因扩展行，订单发生时间仍为 `local_date`，但归因来源可能来自当日之前的浏览/加购行为。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 核心上游 DWD 表，提供订单归因明细数据，包含订单操作类型、GMV、window_day、多触点 feature_detail、页面信息、实验组等全量字段 |
| `traffic_omni_oa.dim_atlas_search_feature_map__reg_live` | Atlas 搜索特征映射维表，提供 `mapped_page_type` 到原始 `page_type` 的映射关系，用于填充 `original_page_type` 字段；取最新分区数据 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
    │  (过滤 operation='order', operation_cnt>0，按指定分区)
    ▼
[Temp View] dwd_omni_with_tag          ← 计算 scenario_tags、汇总订单指标、展开 source1/source2 字段
    │
    ├─ + traffic_omni_oa.dim_atlas_search_feature_map__reg_live
    │         (LEFT JOIN 获取 original_page_type)
    ▼
[Temp View] dwm_table                  ← 三路 UNION ALL：直接归因行 + source1 间接归因行 + source2 间接归因行
    ▼
[Temp View] dws_table                  ← 按维度 GROUP BY 二次聚合，指标结果 ≤ 0 时置 null
    ▼
srdi_mart.dws_sr_data_warehouse_platform_order_benchmark_1d
    (INSERT OVERWRITE 写入指定 grass_region + local_date 分区)
```

### 关键步骤

**Step 1 — `omni_search_mapping_scope`（Temp View）**
读取 `dim_atlas_search_feature_map__reg_live` 最新分区，构建 `mapped_page_type → original_page_type` 的映射表，用于后续 JOIN 还原原始页面类型。

**Step 2 — `dwd_omni_with_tag`（Temp View）**
从 DWD 表过滤当日指定区域的订单数据（`operation = 'order'` 且 `operation_cnt > 0`），按多维度 GROUP BY 聚合，同时：
- 调用 `build_scenario_tags` UDF 分别为直接归因（当前触点）、source1、source2 构建 `scenario_tags`；
- 汇总 `order_cnt`、`gmv`、`gmv_local`、`pc2_gmv` 及 ATC 时间窗口指标（`window_day = 1` 为当日，`window_day BETWEEN 1 AND 4` 为 3 日内）。

**Step 3 — `dwm_table`（Temp View）**
通过三路 UNION ALL 实现多触点归因展开：
- **Branch 1（直接归因，`is_direct = true`）**：使用当前触点的 feature_detail、page_type 等字段，`dedup_scenario_tags = scenario_tags`；
- **Branch 2（source1 间接归因，`is_direct = false`）**：使用 source1 系列字段，要求 `source1_feature_detail` 非空且不等于直接归因的 `feature_detail`；`dedup_scenario_tags` 剔除直接归因已覆盖的 scenario_tags；
- **Branch 3（source2 间接归因，`is_direct = false`）**：使用 source2 系列字段，要求 `source2_feature_detail` 非空且不等于 source1 及直接归因的 `feature_detail`；`dedup_scenario_tags` 同时剔除直接归因和 source1 覆盖的标签。
- 各分支均通过 LEFT JOIN `omni_search_mapping_scope` 填充 `original_page_type`。

**Step 4 — `dws_table`（Temp View）**
对 `dwm_table` 按全量维度字段（21 列）进行二次 GROUP BY 聚合，将同一维度组合下展开的多行合并；各指标使用 `IF(SUM(...) > 0, SUM(...), null)` 处理，避免写入零值行干扰下游统计。

**Step 5 — INSERT OVERWRITE（最终写入）**
将 `dws_table` 结果以 `INSERT OVERWRITE` 方式写入目标表指定分区（`grass_region` + `local_date`），全量覆盖当日数据，保证幂等性。

### 注意事项

- **单 writer，无 multi-writer 风险**：本表仅有一个 ETL 文件写入，不存在多 writer 并发覆盖问题；但 `grass_region` 参数化执行时需确保不同区域任务不并发写入同一分区。
- **分区覆盖策略**：使用 `INSERT OVERWRITE PARTITION(grass_region, local_date)`，重跑同一分区会完整替换历史数据，重跑安全。
- **`operation_cnt > 0` 过滤**：ETL 注释明确说明该过滤用于保留 first click 归因数据、剔除 last click 数据，下游分析需注意本表仅反映 first click 口径。
- **指标零值处理**：汇总后 ≤ 0 的指标值被置为 null，下游 SUM 时可直接忽略 null，但 COUNT 统计需区分 null 与零。
- **`build_scenario_tags` UDF**：为自定义函数，依赖当前环境注册，ETL 迁移或环境变更时需同步确认 UDF 可用性。
- **`page_section` 取数组首元素**：`page_section[0]`，若原始数组为空则该字段为 null，下游过滤时需注意。

---

*文档生成时间：2026-05-17*