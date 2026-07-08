<!-- ads-workspace-gdoc-sync: gdoc_id=1u8ADx1uXbBCkv9cXLI8zj19ZeKa7jbBSw2LTnTemXio gdoc_url=https://docs.google.com/document/d/1u8ADx1uXbBCkv9cXLI8zj19ZeKa7jbBSw2LTnTemXio/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_one_variation_model_hour_level_analysis_1d

**分层：** DWS（数据仓库服务层）
**主键：** `grass_region` + `local_date` + `local_hour` + `model_id` + `cspu_id` + `item_id` + `shop_id`
**分区：** `grass_region`（站点大区）、`local_date`（本地日期）、`local_hour`（本地小时）
**更新频率：** 每小时更新，覆盖写入当日各小时分区（`INSERT OVERWRITE`）
**访问频次：** 6,407 次

---

## 业务描述

本表为搜推数仓（SRDI）搜索与推荐场景下，**以小时粒度**聚合的一变体（One Variation）模型级别分析宽表，统计范围固定为全渠道汇总口径（`mapping_general = 'S&R__ALL__'`）。

核心业务场景：
- 分析搜推页面（PB）各 **Model**（商品模型）在不同站点、不同小时段的曝光、订单、GMV 等核心指标表现；
- 支持按 **CSPU**（标准商品单元）、**Shop**（店铺）、**业务类型**（普通/跨境/本地 SCS 等）维度做交叉分析；
- 识别 **Buybox**（购物车优选）模型，辅助 Buybox 策略评估；
- 结合前一日 CSPU 下单量（`cspu_l1d_order_cnt`），支持商品热度与实时流量的联合分析。

适合回答的问题示例：
- 某站点某日各小时内，各 Model 的曝光量、自然曝光量趋势如何？
- 某 CSPU 下各 Model 的 GMV 在不同业务类型（SCS-CB / SCS-Local / 普通）中的分布？
- 哪些 Model 在当前小时是 Buybox 模型，其下单率与非 Buybox 模型相比如何？
- 某店铺（SCS / 非 SCS）在不同小时段的订单量和本地 GMV 表现？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识，如 `ID`、`TH`、`VN` 等，所有查询必须指定此字段 |
| `local_date` | date | 本地日期（数据所属自然日），所有查询必须指定此字段 |
| `local_hour` | int | 本地小时（0–23），数据按小时粒度聚合写入 |

---

### 维度：商品与模型标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | 标准商品单元 ID（CSPU），一个 CSPU 可对应多个 Model |
| `model_id` | bigint | 商品模型 ID（One Variation Model），分析的核心粒度 |
| `item_id` | bigint | 商品 Item ID，通常对应某个具体 SKU/Listing |
| `mapping_general` | string | 渠道汇总标识，本表固定为 `'S&R__ALL__'`，代表搜索与推荐全渠道口径 |

---

### 维度：店铺与业务分类

| 字段名 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID |
| `shop_scs_type` | string | 店铺 SCS 类型：`scs-local`（本地 SCS）、`scs-cb`（跨境 SCS）、`non-scs`（非 SCS 店铺） |
| `business_type` | int | 业务类型编码，来源于 Model 维度表，区分普通、SCS 等不同经营模式 |
| `cspu_type` | array\<double\> | CSPU 在当前小时下聚合的 Model 类型列表，枚举值含义：`1.1`=业务类型1、`2.1`=SCS-CB业务类型2、`2.2`=SCS-Local业务类型2、`3.1`=业务类型3、`4.1`=SCS-CB业务类型4、`4.2`=SCS-Local业务类型4 |
| `is_buybox` | int | 是否为 Buybox 模型：`1`=是，`0`=否；依据 vsku model mapping 维度表判断 |

---

### 指标：曝光类

| 字段名 | 类型 | 说明 |
|---|---|---|
| `item_imp_cnt` | bigint | Item 粒度总曝光次数（含广告曝光） |
| `item_org_imp_cnt` | bigint | Item 粒度自然曝光次数（排除广告曝光，`is_ads='false'`） |

---

### 指标：订单类

| 字段名 | 类型 | 说明 |
|---|---|---|
| `model_order_cnt` | double | Model 粒度总下单量（含广告订单） |
| `model_org_order_cnt` | double | Model 粒度自然下单量（排除广告订单，`is_ads='false'`） |
| `cspu_l1d_order_cnt` | double | CSPU 前一自然日（T-1）的总下单量，反映商品历史热度 |

---

### 指标：GMV 类

| 字段名 | 类型 | 说明 |
|---|---|---|
| `model_gmv` | double | Model 粒度总 GMV（美元，含广告） |
| `model_org_gmv` | double | Model 粒度自然 GMV（美元，排除广告） |
| `model_gmv_local` | double | Model 粒度总 GMV（本地货币，含广告） |
| `model_org_gmv_local` | double | Model 粒度自然 GMV（本地货币，排除广告） |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：必须指定，该字段为分区键，不过滤将触发全表扫描。
2. **`local_date`**：必须指定，该字段为分区键，建议使用等值过滤（`local_date = 'YYYY-MM-DD'`）。
3. **`local_hour`**：可选，但若只需分析特定小时段应显式过滤以裁剪分区。
4. 本表 `mapping_general` 固定为 `'S&R__ALL__'`，无需额外过滤渠道，但若与其他含多 `mapping_general` 值的表 JOIN 时需注意对齐。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `item_imp_cnt` / `item_org_imp_cnt` | Item 级曝光已在 Model 粒度展开，跨 Model 汇总同一 Item 会导致重复计数 |
| `cspu_l1d_order_cnt` | 为 CSPU 级别前日订单预聚合值，跨 Model/Item 行 SUM 会重复计算同一 CSPU |
| `cspu_type` | `array<double>` 类型，不可直接聚合，需先 explode 后再分析 |
| `is_buybox` | 标志位（0/1），SUM 无业务意义，应使用 `MAX` 或 `COUNT(CASE WHEN is_buybox=1)` |

### 时效性说明

- 本表为**小时级**数据表（`_hour_level`），每小时调度写入，时效性为准实时（T+0 小时粒度）。
- `local_date` 分区代表本地时区日期，跨时区对比时注意时区换算。
- `cspu_l1d_order_cnt` 反映的是 **`local_date - 1`** 的汇总值，属于历史快照字段，不随当日实时数据变动。
- 表按 `INSERT OVERWRITE` 写入，各小时分区数据在每次调度执行时会被完整覆盖，无增量追加风险。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | 基础维度：CSPU-Model-Item-Shop 关联关系，按小时粒度展开 |
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | 业务类型维度：提供 Model 级别 `business_type` |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 指标来源：Model/Item 粒度曝光、订单、GMV 聚合事实数据，过滤 `mapping_general = 'S&R__ALL__'` |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_cspu_level_1d` | CSPU 前一日下单量（T-1），用于计算 `cspu_l1d_order_cnt` |
| `srdi_mart.dim_sr_data_warehouse_vsku_model_mapping_hf` | Buybox 标识：判断 Model 是否为 vsku（Buybox）模型 |
| `regds_listing.dim_scs_shop_list_df` | SCS 店铺类型维度：区分 `scs-local`、`scs-cb` 店铺，用于 `shop_scs_type` 和 `cspu_type` 计算 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf  ──┐
dim_scs_shop_list_df (shop_scs_type)                 ──┤→ base_table（基础维度主干）
                                                        │
dim_sr_data_warehouse_pb_one_variation_model_analysis_hf → biz_type（business_type）
                                                        │
biz_type + dim_scs_shop_list_df                      ──→ cspu_type（CSPU 类型聚合）
                                                        │
dws_sr_data_warehouse_tc_pb_basic_aggr_1d            ──→ basic_aggr_model（Model 指标）
basic_aggr_model                                     ──→ basic_aggr_item（Item 曝光聚合）
                                                        │
dws_sr_data_warehouse_tc_pb_cspu_level_1d（T-1）      ──→ cspul1d_table（CSPU 历史订单）
                                                        │
dim_sr_data_warehouse_vsku_model_mapping_hf          ──→ vmodel（Buybox 标识）
                                                        │
base_table LEFT JOIN 以上所有中间视图                  ──→ final_table
                                                        │
final_table                                          ──→ INSERT OVERWRITE 目标表
```

### 关键步骤

1. **`base_table`**：以 `dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` 为主干，LEFT JOIN `dim_scs_shop_list_df` 获取店铺 SCS 类型，构建 `(local_hour, cspu_id, model_id, item_id, shop_id, shop_scs_type)` 关联基础。

2. **`biz_type`**：从 `dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` 提取当日各小时 Model 维度的 `business_type`。

3. **`cspu_type`**：基于 `biz_type` 与 `dim_scs_shop_list_df` 做 LEFT JOIN，将 `business_type` + SCS 类型映射为细粒度枚举值（1.1/2.1/2.2/3.1/4.1/4.2），再按 `(local_hour, cspu_id)` 使用 `collect_list` 聚合为数组。

4. **`basic_aggr_model`**：从 `dws_sr_data_warehouse_tc_pb_basic_aggr_1d` 过滤 `mapping_general = 'S&R__ALL__'`，按 `(local_hour, item_id, model_id)` 聚合曝光（总量/自然）、订单（总量/自然）、GMV（美元/本地，总量/自然）共 8 个指标。

5. **`basic_aggr_item`**：在 `basic_aggr_model` 基础上，按 `(local_hour, item_id)` 进一步聚合得到 Item 级曝光量（`item_imp_cnt`、`item_org_imp_cnt`）。

6. **`cspul1d_table`**：从 `dws_sr_data_warehouse_tc_pb_cspu_level_1d` 读取 **`date_sub(local_date, 1)`** 分区数据，按 `cspu_id` 汇总前一日下单量。

7. **`vmodel`**：从 `dim_sr_data_warehouse_vsku_model_mapping_hf` 获取当日各小时 Buybox（vsku）Model 列表，去重后用于 `is_buybox` 标志判断。

8. **`final_table`**：以 `base_table` 为驱动，依次 LEFT JOIN `basic_aggr_model`（按 `local_hour + model_id`）、`basic_aggr_item`（按 `local_hour + item_id`）、`cspul1d_table`（按 `cspu_id`）、`biz_type`（按 `local_hour + model_id + cspu_id`）、`cspu_type`（按 `local_hour + cspu_id`）、`vmodel`（按 `local_hour + model_id`），所有数值字段以 `COALESCE(..., 0)` 防止 NULL，`is_buybox` 通过 `IF(vmodel.model_id IS NOT NULL, 1, 0)` 赋值。

9. **`INSERT OVERWRITE`**：将 `final_table` 结果写入目标表，补充固定字段 `mapping_general = 'S&R__ALL__'`，按 `(grass_region, local_date, local_hour)` 三级分区覆盖写入。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，无多 Writer 并发分区冲突风险。
- **动态分区写入**：`local_hour` 为动态分区列，需确保 Spark 开启动态分区支持；一次调度写入当日所有小时分区，若中途失败可能导致部分小时数据缺失。
- **T-1 快照依赖**：`cspu_l1d_order_cnt` 依赖前一日 `dws_sr_data_warehouse_tc_pb_cspu_level_1d` 数据，若上游 T-1 分区数据延迟或为空，该字段将填充为 0，不会报错但会影响分析准确性。
- **参数化变量**：SQL 中使用 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 等模板变量，实际执行时由调度系统注入；临时视图名称带站点后缀，以支持多站点并行调度隔离。
- **LEFT JOIN 扇出风险**：`base_table` 与 `biz_type` 的 JOIN 条件为 `local_hour + model_id + cspu_id`，若维度表存在一对多关联，可能导致行膨胀，使用前需确认维度表唯一性约束。
- **`cspu_type` 数组字段**：使用前需 `LATERAL VIEW EXPLODE` 展开，直接聚合该字段无实际意义。

---

*文档生成时间：2026-05-17*