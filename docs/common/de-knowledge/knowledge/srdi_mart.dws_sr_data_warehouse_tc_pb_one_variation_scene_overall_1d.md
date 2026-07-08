<!-- ads-workspace-gdoc-sync: gdoc_id=1k6tN-s0bKJuE-fHD3W4EpoBFa9dYYgED1bIw588gLvY gdoc_url=https://docs.google.com/document/d/1k6tN-s0bKJuE-fHD3W4EpoBFa9dYYgED1bIw588gLvY/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_one_variation_scene_overall_1d

**分层：** DWS（数据汇总层）
**主键：** `model_id` + `item_id` + `is_item_card` + `mapping_general` + `is_ads` + `shop_scs_type` + `business_type` + `grass_region` + `local_date`
**分区：** `grass_region`（站点区域）/ `local_date`（业务日期）
**更新频率：** 每日（T+1）
**访问频次：** 45 次

---

## 业务描述

本表是 **搜推（SR）数仓 TC 端 PB（Price Book）单规格商品多场景综合汇总日表**，以 **CSPU 最低价 Model 为锚点**，整合了商品（item）、model、CSPU 三个粒度在各流量场景下的曝光、订单、GMV 及广告收入核心指标。

**核心业务场景：**
- 面向搜推算法团队和业务分析团队，评估单规格（one-variation）商品在搜索、推荐等多个流量场景下的流量分发效率与商业价值。
- 结合 SCS 店铺类型（`shop_scs_type`）和业务类型（`business_type`）维度，支持 SCS 专题分析与跨站点对比。
- 广告收入（`ads_revenue_*`）与自然流量指标并轨，支持广告 ROI 分析。

**适合回答的问题：**
- 某站点/日期下，特定搜索/推荐场景（`mapping_general`）中单规格商品的曝光与转化表现如何？
- CSPU 维度的 item 级、model 级订单量与 GMV 分布？
- SCS 店铺商品在各场景的流量占比与 GMV 贡献？
- 整体场景（`__ALL__`）的流量和广告收入汇总？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区，如 `MY`、`ID`、`TH`、`VN`、`PH`、`TW`、`BR` 等，每次查询必须指定 |
| `local_date` | date | 业务本地日期，格式 `yyyy-MM-dd`，每次查询必须指定 |

### 维度：商品与规格标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `model_id` | bigint | SKU（规格）ID，对应 CSPU 最低价 model |
| `item_id` | bigint | 商品 ID（SPU 级别） |

### 维度：场景与流量来源

| 字段名 | 类型 | 说明 |
|---|---|---|
| `mapping_general` | string | 流量场景，取值包括 `Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`、`Shop`、`S&R__ALL__`（搜推合计）、`__ALL__`（全场景合计） |
| `is_item_card` | string | 是否为商品卡片流量；含 `__ALL__`（所有类型合计，由 GROUPING SETS 生成） |
| `is_ads` | string | 是否为广告流量；含 `__ALL__`（所有类型合计，由 GROUPING SETS 生成） |

### 维度：店铺与业务类型

| 字段名 | 类型 | 说明 |
|---|---|---|
| `shop_scs_type` | string | 店铺 SCS 类型，取值 `scs-local`、`scs-cb`（跨境）或 `non-scs`（非 SCS 店铺） |
| `business_type` | int | 业务类型编码，如 2（TW/BR）、3、4（MY/PH/TH/VN 等）；来源于 PB model 分析维表 |

### 指标：Item 级流量与交易

| 字段名 | 类型 | 说明 |
|---|---|---|
| `item_imp_pv` | bigint | 商品曝光 PV（页面维度曝光次数），经 CSPU 最低价 item 去重后聚合 |
| `item_imp_uv` | bigint | 商品曝光 UV（去重用户数），对有曝光的 user 计数 |
| `item_order_cnt` | double | 商品订单量（item 粒度），经 CSPU 最低价 item 去重后聚合 |
| `item_order_uv` | bigint | 商品下单 UV（去重用户数），对有订单的 user 计数 |
| `item_gmv` | double | 商品 GMV（USD 计价） |
| `item_gmv_local` | double | 商品 GMV（本地货币计价） |

### 指标：Model 级交易

| 字段名 | 类型 | 说明 |
|---|---|---|
| `model_order_cnt` | double | model（SKU）订单量，仅限 `business_type in (2,3,4)` 的 model |
| `model_order_uv` | bigint | model 下单 UV（去重用户数） |
| `model_gmv` | double | model 维度 GMV（USD 计价） |
| `model_gmv_local` | double | model 维度 GMV（本地货币计价） |

### 指标：CSPU 级汇总

| 字段名 | 类型 | 说明 |
|---|---|---|
| `cspu_item_imp_pv` | bigint | CSPU 下所有关联 item 的曝光 PV 汇总 |
| `cspu_item_order_cnt` | double | CSPU 下所有关联 item 的订单量汇总 |
| `cspu_model_order_cnt` | double | CSPU 下所有关联 model 的订单量汇总 |

### 指标：场景整体流量与交易

| 字段名 | 类型 | 说明 |
|---|---|---|
| `scene_item_imp_pv` | bigint | 场景维度整体曝光 PV（不限于 CSPU 最低价，全流量口径） |
| `scene_item_imp_uv` | bigint | 场景维度整体曝光 UV（去重用户数） |
| `scene_order_cnt` | double | 场景维度整体订单量 |
| `scene_order_uv` | bigint | 场景维度整体下单 UV（去重用户数） |
| `scene_gmv` | double | 场景维度整体 GMV（USD 计价） |
| `scene_gmv_local` | double | 场景维度整体 GMV（本地货币计价） |

### 指标：广告收入

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ads_revenue_local` | double | 商品广告消耗（本地货币），仅在 `is_item_card = '__ALL__'` 且 `is_ads = '__ALL__'` 时有值，其余行为 NULL |
| `ads_revenue_usd` | double | 商品广告消耗（USD），同上，仅在全量维度汇总行时有值 |

---

## 查询使用须知

### 必须指定的过滤条件

- **`grass_region`**：物理分区键，查询时必须过滤，否则触发全表扫描。
- **`local_date`**：物理分区键，查询时必须过滤，建议精确指定日期或合理范围。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `item_imp_uv`、`item_order_uv` | 用户去重计数（UV），跨行/跨维度直接 SUM 会导致重复计数 |
| `model_order_uv` | 用户去重计数（UV），同上 |
| `scene_item_imp_uv`、`scene_order_uv` | 用户去重计数（UV），同上 |
| `ads_revenue_local`、`ads_revenue_usd` | 仅在 `is_item_card = '__ALL__' AND is_ads = '__ALL__'` 的行有值，跨维度 SUM 会计算多份 |
| `scene_*` 类指标 | 全场景口径数据，与 item/model 级指标口径不同，不应与后者混合 SUM |

### 维度汇总行说明（GROUPING SETS）

- `is_item_card = '__ALL__'`：对 `is_item_card` 做了 ROLLUP，表示所有卡片类型合计行。
- `is_ads = '__ALL__'`：对 `is_ads` 做了 ROLLUP，表示所有广告/自然流量合计行。
- 分析具体细分时须过滤排除 `__ALL__`，汇总分析时选取 `__ALL__` 行即可，**避免重复叠加**。

### 场景范围说明

- `mapping_general` 包含 `S&R__ALL__`（搜推场景合计）和 `__ALL__`（全场景合计）两类预聚合行，直接 SUM 所有 `mapping_general` 的行会导致重复计数。
- 广告收入数据仅覆盖 `Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`、`Shop` 五个场景及其聚合（`S&R__ALL__`、`__ALL__`），其余场景不含广告收入。

### 时效性说明

- 本表为 **日粒度（1d）** 表，每日 T+1 更新，不提供实时或小时级数据。
- 数据范围为当日（`local_date`）整天汇总。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | 获取 CSPU 最低价 model 列表，含 `cspu_id`、`model_id`、`item_id`、`shop_id`、`business_type`、`local_hour` |
| `regds_listing.dim_scs_shop_list_df` | 获取 SCS 店铺类型（`scs-local`、`scs-cb`），用于标注 `shop_scs_type` |
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | 获取 CSPU 与所有关联 model/item 的映射关系 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 提供 item/model 粒度的曝光（`imp_cnt`）、订单（`order_cnt`）、GMV 等基础流量指标，按场景和用户粒度 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 提供商品级广告消耗数据（`expenditure_amt_local`、`expenditure_amt_usd`），按 `entrance` 维度 |
| `mp_paidads.dim_entry_point_mapping_v2` | 广告 entrance 到流量场景（`traffic_type`）的映射维表 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_one_variation_model_analysis_hf
  + dim_scs_shop_list_df
        ↓ [cheapest_model_list]  — 最低价 model 维度（含 shop_scs_type, business_type）
        ↓ [cheapest_item_list]   — 最低价 item 集合

dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf
  + cheapest_model_list
        ↓ [cheapest_cspu_all_model] — CSPU 关联所有 model（经最低价 CSPU 过滤）
        ↓ [cheapest_cspu_all_item]  — CSPU 关联所有 item

dws_sr_data_warehouse_tc_pb_basic_aggr_1d
        ↓ [traffic_data]  — item/model/user 粒度流量明细

traffic_data + cheapest_cspu_all_model → [cspu_model_level_step1]
  → [cspu_model_level]   — CSPU model 级订单汇总（GROUPING SETS）

cspu_model_level_step1 + cheapest_model_list → [model_level]   — model 级指标汇总
traffic_data + cheapest_cspu_all_item  → [cspu_item_level_step1]
  → [cspu_item_level]    — CSPU item 级曝光/订单汇总（GROUPING SETS）

cspu_item_level_step1 + cheapest_item_list → [item_level]       — item 级指标汇总
traffic_data → [scene_data]                                      — 全场景整体汇总

dwd_advertise_performance_di + dim_entry_point_mapping_v2
  → [ads_raw_step1] → [ads_raw_step2] → [ads]                   — 广告收入汇总

model_level
  LEFT JOIN item_level        (by item_id, is_item_card, mapping_general, is_ads)
  LEFT JOIN cspu_model_level  (by cspu_id, is_item_card, mapping_general, is_ads)
  LEFT JOIN cspu_item_level   (by cspu_id, is_item_card, mapping_general, is_ads)
  LEFT JOIN ads               (by item_id, mapping_general, is_item_card='__ALL__', is_ads='__ALL__')
  LEFT JOIN scene_data        (by is_item_card, mapping_general, is_ads)
        ↓
INSERT OVERWRITE → dws_sr_data_warehouse_tc_pb_one_variation_scene_overall_1d
```

### 关键步骤

1. **`cheapest_model_list`**：从 PB model 分析维表读取当日最低价 model，LEFT JOIN SCS 店铺维表补充 `shop_scs_type`（无匹配则为 `non-scs`）。
2. **`cheapest_item_list`** / **`cheapest_cspu_all_model`** / **`cheapest_cspu_all_item`**：基于最低价 model 与 CSPU 全量映射表，构建 CSPU → item、CSPU → model 的关联集合。
3. **`traffic_data`**：从基础聚合日表读取用户粒度流量数据，过滤指定 `mapping_general` 场景，按 `local_hour` + `user_id` + `item_id` + `model_id` + 维度字段聚合。
4. **`cspu_model_level_step1` / `cspu_model_level`**：将流量数据 JOIN CSPU model 映射，使用 GROUPING SETS 生成 `is_item_card` × `is_ads` 四种维度组合的 CSPU 级 model 订单聚合。
5. **`model_level`**：在 `cspu_model_level_step1` 基础上进一步 JOIN `cheapest_model_list`，过滤 `business_type in (2,3,4)`，同样用 GROUPING SETS 生成四维度组合的 model 级指标（含 UV 去重）。
6. **`cspu_item_level_step1` / `cspu_item_level`**：流量数据 JOIN CSPU item 映射，聚合 CSPU item 级曝光和订单，GROUPING SETS 生成四维度组合。
7. **`item_level`**：对 `cspu_item_level_step1` JOIN `cheapest_item_list`，通过先 MAX 再 SUM 的两阶段聚合去除 CSPU 引入的 item 重复，生成 item 级曝光/订单/GMV/UV 指标，GROUPING SETS 生成四维度组合。
8. **`scene_data`**：直接从 `traffic_data` 汇总全场景用户维度指标（曝光/订单/GMV/UV），GROUPING SETS 生成四维度组合，口径与 item/model 无关。
9. **`ads_raw_step1/2` / `ads`**：从广告消耗明细表读取 item 级 expenditure，通过 `dim_entry_point_mapping_v2` 映射到 `traffic_type` 场景，分别输出分场景、`S&R__ALL__`、`__ALL__` 三份汇总。
10. **`INSERT OVERWRITE`**：以 `model_level` 为主表，LEFT JOIN 其余中间视图，写入目标分区。广告收入仅在 `is_item_card = '__ALL__' AND is_ads = '__ALL__'` 条件下 JOIN。

### 注意事项

- **Multi-Writer（多写入文件）**：共 2 个 ETL 文件。Source 1 为主 ETL，负责实际数据写入目标表；Source 2 为辅助文件，仅创建各站点的便捷视图（`_my`、`_ph`、`_th`、`_vn`、`_tw`、`_br`、`_id` 后缀），不写物理数据。
- **分区写入**：每次按 `grass_region` + `local_date` 单分区 INSERT OVERWRITE，不同站点/日期之间无干扰，但同一分区重跑会覆盖原有数据。
- **GROUPING SETS 重复行**：`is_item_card` 和 `is_ads` 各有 `__ALL__` 汇总行，直接对全表 SUM 会重复计算，使用时须明确过滤维度组合。
- **`item_level` 两阶段去重**：因同一 item 可能属于多个 CSPU，通过 `MAX` + `SUM` 两步聚合消除 CSPU 维度引入的 item 重复曝光计数。
- **`business_type` 过滤**：`model_level` 中限定 `business_type in (2,3,4)`，因此目标表中 model/item/CSPU 级指标仅覆盖这三类业务，`scene_data` 不受此限制。
- **广告收入 NULL**：未满足 `is_item_card = '__ALL__' AND is_ads = '__ALL__'` 的行，`ads_revenue_local` 和 `ads_revenue_usd` 为 NULL，勿误解为零消耗。
- **站点视图 `business_type` 差异**：TW、BR 视图过滤 `business_type = 2`；MY、PH、TH、VN 视图过滤 `business_type = 4`；ID 视图不过滤 `business_type`，查询时须注意与视图保持一致的过滤逻辑。

---

*文档生成时间：2026-05-17*