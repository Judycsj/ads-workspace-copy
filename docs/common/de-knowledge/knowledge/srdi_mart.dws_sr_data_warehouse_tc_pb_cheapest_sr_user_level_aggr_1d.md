<!-- ads-workspace-gdoc-sync: gdoc_id=1DUx-OUJJmw7zyO8xSsIAIt9xyncwj7idH6w4I0Xk434 gdoc_url=https://docs.google.com/document/d/1DUx-OUJJmw7zyO8xSsIAIt9xyncwj7idH6w4I0Xk434/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_cheapest_sr_user_level_aggr_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `user_id` + `mapping_general` + `is_ads`
**分区：** `grass_region`（站点区域）, `local_date`（业务日期）
**更新频率：** 每日一次（T+1，按天覆盖写入）
**引用频次 / 访问频次：** 44

---

## 业务描述

本表是搜推（Search & Recommend）场景下，**最低价（Cheapest）商品维度的用户级每日汇总表**，面向 TC（Tokopedia Commerce）PB（Product Browse）链路。

表中按用户（`user_id`）、场景（`mapping_general`）、广告标识（`is_ads`）三个维度，分别统计以下三类商品的曝光、订单、GMV 指标：

- **Cheapest Item**：全站最低价 SKU（item 粒度）
- **Cheapest Model**：全站最低价 Model 粒度
- **CSPU Cheapest**：CSPU（平台规格单元）口径的最低价 item / model

同时提供场景整体（Scene）汇总指标作为对照基准。

`is_ads` 字段通过 `GROUPING SETS` 预聚合，`__ALL__` 行同时覆盖广告与非广告流量，无需下游再次汇总。

**适合回答的典型问题：**
- 在 Search / Daily Discover 等场景中，最低价商品对某用户的曝光与转化贡献如何？
- 最低价 Model 的 GMV 在场景 GMV 中占比多少（用户粒度）？
- CSPU 最低价商品的曝光 UV 趋势如何变化？
- 广告位与自然位的最低价商品转化率差异如何（通过 `is_ads` 拆分）？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域（如 ID、MY 等），分区键 |
| `local_date` | date | 业务日期，分区键，格式 yyyy-MM-dd |

### 维度：用户与场景维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，行级粒度为单用户 |
| `mapping_general` | string | 流量场景，取值范围：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase` |
| `is_ads` | string | 广告标识；`__ALL__` 表示广告+自然位合计（由 GROUPING SETS 预聚合生成） |

### 指标：Cheapest Item（最低价 SKU）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cheapest_item_imp_pv` | bigint | 最低价 item 在该场景下的曝光 PV（impression count 求和，`is_cheapest_item=1`） |
| `cheapest_item_imp_uv` | bigint | 最低价 item 有曝光的用户数（`is_cheapest_item=1` 且 `imp_cnt>0` 的去重 user_id） |
| `cheapest_item_order_cnt` | double | 最低价 item 的订单数（`is_cheapest_item=1` 的 order_cnt 求和） |
| `cheapest_item_order_uv` | bigint | 最低价 item 有成单的用户数（`is_cheapest_item=1` 且 `order_cnt>0` 的去重 user_id） |
| `cheapest_item_gmv` | double | 最低价 item 的 GMV（美元，`is_cheapest_item=1` 的 gmv 求和） |
| `cheapest_item_gmv_local` | double | 最低价 item 的本地货币 GMV（`is_cheapest_item=1` 的 gmv_local 求和） |

### 指标：Cheapest Model（最低价 Model）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cheapest_model_order_cnt` | double | 最低价 model 的订单数（`is_cheapest_model=1` 的 order_cnt 求和） |
| `cheapest_model_order_uv` | bigint | 最低价 model 有成单的用户数（`is_cheapest_model=1` 且 `order_cnt>0` 的去重 user_id） |
| `cheapest_model_gmv` | double | 最低价 model 的 GMV（美元） |
| `cheapest_model_gmv_local` | double | 最低价 model 的本地货币 GMV |

### 指标：CSPU Cheapest（CSPU 口径最低价）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_item_imp_pv` | bigint | CSPU 最低价 item 的曝光 PV（`is_cheapest_cspu_all_item=1` 的 imp_cnt 求和） |
| `cspu_item_imp_uv` | bigint | CSPU 最低价 item 有曝光的用户数（`is_cheapest_cspu_all_item=1` 且 `imp_cnt>0` 的去重 user_id） |
| `cspu_model_order_cnt` | double | CSPU 最低价 model 的订单数（`is_cheapest_cspu_all_model=1` 的 order_cnt 求和） |
| `cspu_model_order_uv` | bigint | CSPU 最低价 model 有成单的用户数（`is_cheapest_cspu_all_model=1` 且 `order_cnt>0` 的去重 user_id） |
| `cspu_model_gmv` | double | CSPU 最低价 model 的 GMV（美元） |
| `cspu_model_gmv_local` | double | CSPU 最低价 model 的本地货币 GMV |

### 指标：场景整体（Scene 全量基准）

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_imp_pv` | bigint | 场景全量曝光 PV（该用户+场景+is_ads 组合下所有 imp_cnt 求和） |
| `scene_imp_uv` | bigint | 场景有曝光的用户数（`imp_cnt>0` 的去重 user_id） |
| `scene_order_cnt` | double | 场景全量订单数 |
| `scene_order_uv` | bigint | 场景有成单的用户数（`order_cnt>0` 的去重 user_id） |
| `scene_gmv` | double | 场景全量 GMV（美元） |
| `scene_gmv_local` | double | 场景全量本地货币 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤必须同时指定 `grass_region` 和 `local_date`**，否则触发全表扫描：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```
- `mapping_general` 取值固定为：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`，查询时可按需过滤。

### is_ads 汇总行使用规范

- `is_ads = '__ALL__'` 是由 GROUPING SETS 预聚合生成的广告+自然位合计行，**不可与其他 `is_ads` 值叠加 SUM**，否则产生重复计数。
- 若需广告/自然位拆分分析，应过滤 `is_ads != '__ALL__'`；若只需全量合计，应过滤 `is_ads = '__ALL__'`。

### 不可直接 SUM 的字段

以下字段为去重计数（`count(distinct ...)`），跨用户或跨分区聚合时**不可直接 SUM**，需回溯明细层重新计算：

- `cheapest_item_imp_uv`
- `cheapest_item_order_uv`
- `cheapest_model_order_uv`
- `cspu_item_imp_uv`
- `cspu_model_order_uv`
- `scene_imp_uv`
- `scene_order_uv`

### 时效性说明

- 本表为 **T+1 日刷新**，当天数据通常在次日产出。
- 每次以 `INSERT OVERWRITE` 按分区覆盖写入，历史分区数据不会被影响。
- 本表仅保留单日切片（`_1d` 后缀），**无滑动窗口或累计字段**，多日趋势分析需自行在查询层聚合多个 `local_date`。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_tag_aggr_1d` | 提供用户-商品-场景粒度的基础打标聚合数据，包含最低价标签（`is_cheapest_item`、`is_cheapest_model`、`is_cheapest_cspu_all_item`、`is_cheapest_cspu_all_model`）及曝光、订单、GMV 指标 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_pb_basic_tag_aggr_1d
    （按 grass_region + local_date 过滤，仅保留 4 个场景）
        ↓
Temporary View: traffic_data_${grass_region_without_quote}
    （按 user_id / shop_id / item_id / model_id / is_ads / mapping_general / cheapest 标签聚合）
        ↓
INSERT OVERWRITE → dws_sr_data_warehouse_tc_pb_cheapest_sr_user_level_aggr_1d
    （GROUPING SETS 生成 is_ads 拆分行 + __ALL__ 汇总行，输出用户级各维度指标）
```

### 关键步骤

**Step 1 — 创建 Temporary View `traffic_data_${grass_region_without_quote}`**

从上游 `dws_sr_data_warehouse_tc_pb_basic_tag_aggr_1d` 读取指定 `grass_region` 和 `local_date` 的数据，过滤 `mapping_general` 仅保留 `Search`、`Daily Discover`、`You May Also Like`、`Post Purchase` 四个场景。

按 `(user_id, shop_id, item_id, model_id, is_ads, mapping_general, is_cheapest_item, is_cheapest_cspu_all_item, is_cheapest_model, is_cheapest_cspu_all_model)` 聚合，汇总 `imp_cnt`、`order_cnt`、`gmv`、`gmv_local`，消除上游可能存在的行级重复。

**Step 2 — INSERT OVERWRITE 写目标表**

基于 Step 1 的 Temporary View，以 `(user_id, mapping_general, is_ads)` 为分组键，通过 `GROUPING SETS` 产出两类行：
- `(user_id, mapping_general, is_ads)`：广告/自然位拆分明细行
- `(user_id, mapping_general)`：`is_ads` 汇总行（输出为 `__ALL__`）

各指标使用条件聚合（`sum(if(cheapest_xxx=1, ..., 0))`）和条件去重计数（`count(distinct if(cheapest_xxx=1 and metric>0, user_id, null))`）分别计算 Cheapest Item、Cheapest Model、CSPU Cheapest 及场景全量四组指标。

以 `INSERT OVERWRITE` 按 `(grass_region, local_date)` 分区覆盖写入目标表。

### 注意事项

- **单一写入器**（`multi_writer: false`），目标表仅由单个 ETL 文件写入，无多路并发写入风险。
- `is_ads = '__ALL__'` 行由 `grouping()` 函数判断生成，下游查询时务必区分该汇总行与明细行，避免双重计数。
- Step 1 的 Temporary View 名称包含动态参数 `${grass_region_without_quote}`，实际运行时按站点替换，确保不同站点之间的中间视图隔离。
- 上游表 `dws_sr_data_warehouse_tc_pb_basic_tag_aggr_1d` 同样为分区表，需确保上游分区在本表 ETL 执行前已完成产出，否则将写入空分区。
- `cheapest_model` 口径**无曝光 PV / 曝光 UV 指标**，仅有订单和 GMV，查询时注意字段缺失，不可与 `cheapest_item` 口径对齐比较曝光漏斗。

---

*文档生成时间：2026-05-17*