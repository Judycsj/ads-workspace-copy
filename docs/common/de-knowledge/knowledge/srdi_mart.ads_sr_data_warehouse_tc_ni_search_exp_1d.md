<!-- ads-workspace-gdoc-sync: gdoc_id=1ahuTzgeqKnJvu1DCX-emnfMzeoFFLRyZlRmR0LEcoJk gdoc_url=https://docs.google.com/document/d/1ahuTzgeqKnJvu1DCX-emnfMzeoFFLRyZlRmR0LEcoJk/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_ni_search_exp_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `mapping_general` + `target_type` + `is_ads` + `is_vsku`
**分区：** `grass_region`（区域）、`local_date`（业务日期）
**更新频率：** 每日更新（T+1）
**访问频次：** 920 次

---

## 业务描述

本表为搜索场景 A/B 实验（搜推数仓）的**新品曝光日粒度指标聚合表**，聚焦于全球搜索（Global Search）业务线。

核心业务场景：
- 统计各实验组（`exp_group_id`）在搜索场景下的整体用户行为漏斗指标（曝光→点击→详情页浏览→加购→下单→GMV）；
- 区分**新品**（30日内上架、90日内上架）与全量商品的行为差异，支持新品扶持策略的 A/B 效果评估；
- 支持按是否广告（`is_ads`）、是否虚拟 SKU（`is_vsku`）、流量来源类型（`target_type`）等维度拆分分析；
- 所有指标均包含 Count（次数）与 UU（去重用户数）两个口径，方便同时衡量曝光量级和用户覆盖。

适合回答的问题示例：
- 某实验组相比对照组，搜索场景下的新品（30日/90日）GMV 和 CTR 是否存在显著差异？
- 在广告流量与自然流量中，新品的加购率和下单率分别如何？
- 虚拟 SKU 商品在不同实验组中的曝光和转化表现如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 区域分区，如 `SG`、`MY` 等，对应业务大区 |
| `local_date` | date | 业务日期分区，数据对应的本地日历日期 |

### 维度：实验与场景维度

| 字段 | 类型 | 说明 |
|------|------|------|
| `exp_group_id` | bigint | A/B 实验组 ID，标识具体的实验桶，来源于白名单过滤后的实验分组 |
| `mapping_general` | string | 场景映射标识，当前固定为 `'Search'`（对应 `dpm module Global Search business line Search`） |
| `target_type` | string | 流量来源类型，由 `feature_detail` 字段末段（`-` 分隔）提取，无法解析时为 `'others'`；汇总行为 `'__ALL__'` |
| `is_ads` | string | 是否广告流量，`'true'`/`'false'`；汇总行为 `'__ALL__'` |
| `is_vsku` | string | 是否虚拟 SKU（VSKU）商品，`1`/`0`；汇总行为 `'__ALL__'` |

### 指标：搜索场景整体行为漏斗（全量商品）

| 字段 | 类型 | 说明 |
|------|------|------|
| `scene_imp_cnt` | bigint | 搜索场景曝光次数 |
| `scene_imp_uu` | bigint | 搜索场景有曝光的去重用户数 |
| `scene_click_cnt` | bigint | 搜索场景点击次数 |
| `scene_click_uu` | bigint | 搜索场景有点击的去重用户数 |
| `scene_ppv_cnt` | double | 搜索场景商品详情页浏览（PPV）次数 |
| `scene_ppv_uu` | bigint | 搜索场景有 PPV 的去重用户数 |
| `scene_cart_cnt` | double | 搜索场景加购次数 |
| `scene_cart_uu` | bigint | 搜索场景有加购的去重用户数 |
| `scene_order_cnt` | double | 搜索场景下单次数 |
| `scene_order_uu` | bigint | 搜索场景有下单的去重用户数 |
| `scene_gmv` | double | 搜索场景 GMV（成交金额） |
| `scene_pc2_gmv` | double | 搜索场景 PC2 口径 GMV（二次归因成交金额） |

### 指标：30日内新品行为漏斗

| 字段 | 类型 | 说明 |
|------|------|------|
| `new_item_30d_imp_cnt` | bigint | 30日内上架新品的曝光次数 |
| `new_item_30d_imp_uu` | bigint | 30日内上架新品有曝光的去重用户数 |
| `new_item_30d_click_cnt` | bigint | 30日内上架新品的点击次数 |
| `new_item_30d_click_uu` | bigint | 30日内上架新品有点击的去重用户数 |
| `new_item_30d_ppv_cnt` | double | 30日内上架新品的 PPV 次数 |
| `new_item_30d_ppv_uu` | bigint | 30日内上架新品有 PPV 的去重用户数 |
| `new_item_30d_cart_cnt` | double | 30日内上架新品的加购次数 |
| `new_item_30d_cart_uu` | bigint | 30日内上架新品有加购的去重用户数 |
| `new_item_30d_order_cnt` | double | 30日内上架新品的下单次数 |
| `new_item_30d_order_uu` | bigint | 30日内上架新品有下单的去重用户数 |
| `new_item_30d_gmv` | double | 30日内上架新品的 GMV |
| `new_item_30d_pc2_gmv` | double | 30日内上架新品的 PC2 口径 GMV |

### 指标：90日内新品行为漏斗

| 字段 | 类型 | 说明 |
|------|------|------|
| `new_item_90d_imp_cnt` | bigint | 90日内上架新品的曝光次数（包含 30日内，即 0~90 天） |
| `new_item_90d_imp_uu` | bigint | 90日内上架新品有曝光的去重用户数 |
| `new_item_90d_click_cnt` | bigint | 90日内上架新品的点击次数 |
| `new_item_90d_click_uu` | bigint | 90日内上架新品有点击的去重用户数 |
| `new_item_90d_ppv_cnt` | double | 90日内上架新品的 PPV 次数 |
| `new_item_90d_ppv_uu` | bigint | 90日内上架新品有 PPV 的去重用户数 |
| `new_item_90d_cart_cnt` | double | 90日内上架新品的加购次数 |
| `new_item_90d_cart_uu` | bigint | 90日内上架新品有加购的去重用户数 |
| `new_item_90d_order_cnt` | double | 90日内上架新品的下单次数 |
| `new_item_90d_order_uu` | bigint | 90日内上架新品有下单的去重用户数 |
| `new_item_90d_gmv` | double | 90日内上架新品的 GMV |
| `new_item_90d_pc2_gmv` | double | 90日内上架新品的 PC2 口径 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段为必须过滤条件**，查询时务必同时指定 `grass_region` 和 `local_date`，否则将触发全表扫描，造成严重资源浪费：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-01-01'
  ```
- 若需要分析特定实验组，请同时过滤 `exp_group_id`。

### 维度汇总行值说明

- `target_type`、`is_ads`、`is_vsku` 三个维度均存在汇总行（值为 `'__ALL__'`），由 `GROUPING SETS` 生成，代表该维度的全量合计。
- **查询时若不区分维度，需显式过滤 `= '__ALL__'`；若需要拆分分析，需排除 `'__ALL__'` 行**，避免重复计算。

### 不可直接 SUM 的字段

以下字段是**预聚合后的去重用户数（UU）**，跨行直接 SUM 会导致重复统计，**不可对多行直接求和**：

- `scene_imp_uu`、`scene_click_uu`、`scene_ppv_uu`、`scene_cart_uu`、`scene_order_uu`
- `new_item_30d_imp_uu`、`new_item_30d_click_uu`、`new_item_30d_ppv_uu`、`new_item_30d_cart_uu`、`new_item_30d_order_uu`
- `new_item_90d_imp_uu`、`new_item_90d_click_uu`、`new_item_90d_ppv_uu`、`new_item_90d_cart_uu`、`new_item_90d_order_uu`

如需跨维度/跨分组求 UU，须回溯至用户粒度明细表重新计算。

### 派生比率字段

本表不存储 CTR、CVR、ARPU 等比率字段，需由使用方自行计算（如 `scene_click_cnt / scene_imp_cnt`），但须保证分子分母来自**同一 GROUPING SETS 维度组合**的行。

### 时效性说明

- 本表为 **`_1d` 日粒度表**，数据为 T+1 更新，反映前一自然日的搜索行为。
- `local_date` 表示行为发生的本地日期，**不代表写入时间**。
- 新品判断基准为数据分区的 `local_date`，新品窗口（30日/90日）随日期动态滚动。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 提供用户-商品粒度的曝光、点击、PPV、加购、下单、GMV 等行为事件明细，为核心指标来源 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 提供 A/B 实验用户分组信息，过滤搜索白名单内的有效实验用户及对应 `exp_group_id` |
| `srdi_mart.dim_sr_data_warehouse_item` | 提供商品维度信息，用于计算商品上架时长，判断是否为 30日/90日新品 |
| `srdi_mart.dim_sr_data_warehouse_vsku_vitem` | 提供虚拟 SKU（VSKU）的 `vitem_id` 列表，用于打标 `is_vsku` 字段 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item   ──┐
                                              ├──► user_item_raw（过滤 Global Search 场景）
                                              │
                                              ▼
                                      user_item_union（合并直接行为 + source1/source2 归因行为）
                                              │
dim_sr_data_warehouse_abtest_user_group ──► exp_filter（白名单实验用户过滤）
                                              │
                                              ▼
                                      base_exp（JOIN 实验用户，提取 target_type）
                                              │
dim_sr_data_warehouse_item ──────────────► item_tag（新品标签：0d_30d / 30d_90d）
dim_sr_data_warehouse_vsku_vitem ────────► vitem（VSKU 列表）
                                              │
                                              ▼
                                    base_exp_explode（GROUPING SETS 多维展开，user 粒度）
                                              │
                                              ▼
                                    base_aggr（按实验组+维度聚合，计算 cnt + UU）
                                              │
                                              ▼
                          INSERT OVERWRITE → ads_sr_data_warehouse_tc_ni_search_exp_1d
```

### 关键步骤

1. **`user_item_raw`（Statement 1）**
   - 从 `dwm_sr_data_warehouse_platform_user_item` 读取当日指定区域数据；
   - 通过 `FILTER` 函数保留 `scenario_tags`、`source1_scenario_tags`、`source2_scenario_tags` 中含 `'dpm module Global Search business line Search'` 标签的记录；
   - 商品 ID 优先取虚拟流量 SKU ID（`traffic_vsku_item_id`），回退为 `item_id`；
   - 仅保留 `operation in ('impression','click','ppv','cart','order')` 的行为类型。

2. **`user_item_union`（Statement 2）**
   - 通过三路 `UNION ALL` 合并行为来源：
     - **主路径**：直接场景标签匹配，包含全部行为操作；
     - **source1 归因路径**：仅取 `ppv/cart/order`，`source1_feature_detail` 与主路径不同时计入；
     - **source2 归因路径**：仅取 `ppv/cart/order`，`source2_feature_detail` 与 source1 及主路径均不同时计入；
   - 归因路径的 `imp_cnt` 和 `click_cnt` 置为 0，避免重复统计曝光和点击。

3. **`exp_filter`（Statement 3）**
   - 从实验分组维度表中筛选 `is_assignment_log = 1`（已分配日志）且 `is_search_whitelist = 1`（搜索白名单）的有效实验用户，用于后续 JOIN 过滤。

4. **`base_exp`（Statement 4）**
   - 将 `user_item_union` 与 `exp_filter` 做 INNER JOIN，仅保留在实验白名单内的用户行为；
   - 通过 `ELEMENT_AT(SPLIT(feature_detail, '-'), -1)` 提取 `target_type`（取 `-` 分隔的末段）。

5. **`item_tag`（Statement 5）**
   - 从商品维度表中计算商品相对于 `local_date` 的上架天数；
   - 打标：≤30 天为 `'0d_30d'`，31~90 天为 `'30d_90d'`，超过 90 天的商品不在此表中（不参与新品判定）。

6. **`vitem`（Statement 6）**
   - 从 VSKU-VITEM 维度表中获取当日有效的虚拟商品 ID 列表。

7. **`base_exp_explode`（Statement 7）**
   - 将 `base_exp` 与 `item_tag`（LEFT JOIN）、`vitem`（LEFT JOIN）关联，打标新品类型和 VSKU 标识；
   - 通过 `LATERAL VIEW EXPLODE(scenario_tags)` 将场景标签数组拆平为单行；
   - 通过 `GROUPING SETS` 生成 8 种维度组合（`target_type`、`is_ads`、`is_vsku` 的不同组合），`'__ALL__'` 表示汇总；
   - 在此步骤保留 `user_id` 粒度，供后续 UU 计算使用。

8. **`base_aggr`（Statement 8）**
   - 按 `exp_group_id`、`mapping_general`、`target_type`、`is_ads`、`is_vsku` 聚合；
   - `mapping_general` 通过 `CASE WHEN` 将场景标签映射为 `'Search'`；
   - Count 类指标直接 `SUM`；UU 类指标通过 `SUM(IF(xxx_cnt > 0 AND user_id > 0, 1, 0))` 在 user 粒度上统计去重用户数。

9. **`INSERT OVERWRITE`（Statement 9）**
   - 将 `base_aggr` 结果以 `OVERWRITE` 方式写入目标表对应分区（`grass_region`、`local_date`）。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，不存在多 Writer 并发写入风险。
- **GROUPING SETS 导致行膨胀**：`target_type`、`is_ads`、`is_vsku` 存在 `'__ALL__'` 汇总行，查询时必须明确过滤维度值，否则会产生重复统计。
- **三路归因合并（source1/source2）**：`ppv`、`cart`、`order` 存在多路归因，归因路径的曝光和点击不重复计入，但转化指标（GMV 等）会在各归因路径下分别统计，需注意场景口径与归因链路的一致性。
- **新品标签为动态窗口**：新品判断基于分区 `local_date` 实时计算，历史分区的新品范围不会随时间更新，历史分析需注意此特性。
- **INNER JOIN 实验白名单**：仅白名单内用户的行为进入本表，数据量小于全量用户行为，不可用于计算全站绝对量级指标。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 用户-商品行为事件明细，核心指标来源 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验分组及搜索白名单过滤 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品上架时间，用于判定新品窗口 |
| `srdi_mart.dim_sr_data_warehouse_vsku_vitem` | 虚拟 SKU 商品列表，用于打标 `is_vsku` |

*文档生成时间：2026-05-17*