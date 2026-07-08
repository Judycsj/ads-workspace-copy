<!-- ads-workspace-gdoc-sync: gdoc_id=1TEmDJEYd44MjDZ3qUOfKSkEmBLs_XrhmbXRD7LB6Jmo gdoc_url=https://docs.google.com/document/d/1TEmDJEYd44MjDZ3qUOfKSkEmBLs_XrhmbXRD7LB6Jmo/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_pb_qc_model_level_1d

**分层：** ADS（应用数据层）
**主键：** `cspu_id` + `item_id` + `model_id` + `shop_id` + `grass_region` + `local_date`
**分区：** `grass_region`（站点）、`local_date`（日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 388 次

---

## 业务描述

本表用于搜推数仓 **价格竞争力（Price Competitiveness，PB）模块** 的质量管控（QC），以 **model（商品规格/SKU）** 为核心粒度，汇总以下三类分析视角：

1. **最低价模型识别**：基于 `dim_sr_data_warehouse_pb_one_variation_model_analysis_hf`，识别当日各 CSPU 下的最低价 model，并标记其是否属于 SCS（Shopee Choice / Shopee Mall Cross-border）商家。
2. **订单量基准**：提供模型近 7 天平均日订单量（`avg_model_order_cnt_7d`）和 CSPU 近 7 天平均日订单量（`avg_cspu_order_cnt_7d`），用于衡量最低价模型的销量健康度。
3. **A/B 实验质量评估**：结合实验分组数据，计算最低价商品在实验组（treatment）与对照组（control）下的点击转化率（CTR-CR），并输出两组 CTR-CR 之差比（`item_ctrcr_vs_control`），用于评估 PB 策略效果。

**适合回答的问题：**
- 当日各站点最低价模型的销量表现如何？
- SCS 商家 vs 非 SCS 商家的最低价模型分布情况？
- A/B 实验中，PB 模型在实验组与对照组的转化率差异有多大？
- 哪些 CSPU / model 的 CTR-CR 提升显著，哪些出现下降？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/国家区域，如 `ID`、`TH`、`MY` 等，每次查询必须指定 |
| `local_date` | date | 数据日期（本地时间），每次查询必须指定 |

### 维度：商品与模型维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（标准商品单元）ID，标识一个标准化商品聚合单元 |
| `shop_id` | bigint | 商家 ID |
| `item_id` | bigint | 商品 ID（listing 级别） |
| `model_id` | bigint | 商品规格 ID（SKU 级别），即当日被识别为最低价的 model |
| `model_type` | string | 最低价模型的商家类型，取值为 `scs cheapest`（SCS 商家）或 `non-scs cheapest`（非 SCS 商家） |

### 指标：订单量基准

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_model_order_cnt_7d` | double | 当前 model 近 7 天平均日订单量（来自 `dws_sr_data_warehouse_tc_pb_one_variation_model_day_level_analysis_1d`，按 `date_sub(local_date, 6)` 至 `local_date` 窗口计算） |
| `avg_cspu_order_cnt_7d` | double | 当前 CSPU 近 7 天平均日订单量（来自 `dws_sr_data_warehouse_tc_pb_cspu_level_1d`，按最新可用日期往前推 7 天窗口计算） |

### 指标：A/B 实验转化率

| 字段 | 类型 | 说明 |
|---|---|---|
| `treatment_imp_cnt` | bigint | 实验组（treatment）中该 item 的曝光量，用于判断实验覆盖度 |
| `item_ctrcr_trmt` | double | 实验组（treatment）中最低价商品的 CTR-CR（点击转化率），计算方式：`treatment_cheapest_order_cnt / treatment_cheapest_imp_cnt` |
| `item_ctrcr_control` | double | 对照组（control）中最低价商品的 CTR-CR（点击转化率），计算方式：`control_cheapest_order_cnt / control_cheapest_imp_cnt` |
| `item_ctrcr_vs_control` | double | 实验组相对对照组的 CTR-CR 提升率，计算方式：`(item_ctrcr_trmt / item_ctrcr_control) - 1`；当对照组 CTR-CR 为 0 时取 0 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date`**，否则将触发全分区扫描，造成资源浪费和性能问题：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-06-01'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `item_ctrcr_trmt` | 比率指标，跨行 SUM 无意义；如需汇总需重新用分子/分母原始值计算 |
| `item_ctrcr_control` | 同上，比率指标 |
| `item_ctrcr_vs_control` | 派生比率（相对提升率），不可累加；汇总需回溯实验原始曝光/订单数 |
| `avg_model_order_cnt_7d` | 预聚合均值（7 天窗口平均），跨行 SUM 无意义 |
| `avg_cspu_order_cnt_7d` | 预聚合均值（7 天窗口平均），跨行 SUM 无意义 |

### 时效性说明

- 本表为 **日粒度表（`_1d`）**，每日产出一个分区，通常在 T+1 完成写入。
- `avg_model_order_cnt_7d` 的时间窗口为 `[local_date - 6, local_date]`（滚动 7 天）。
- `avg_cspu_order_cnt_7d` 的时间窗口以 `dws_sr_data_warehouse_tc_pb_cspu_level_1d` 的 **最新可用日期** 为基准往前推 7 天，若上游数据存在延迟，该指标的窗口终点可能滞后于当日 `local_date`。
- A/B 实验分组数据（`dim_sr_data_warehouse_abtest_user_group`）仅取 `is_assignment_log = 1` 的有效分配记录，未被分配到实验的 item 其 `treatment_imp_cnt`、`item_ctrcr_trmt`、`item_ctrcr_control` 均填充为 0。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | 获取当日最低价 model 列表（含 cspu_id、model_id、item_id、shop_id、local_hour） |
| `regds_listing.dim_scs_shop_list_df` | 获取 SCS 商家类型（`scs-local` / `scs-cb`），用于标记 `model_type` |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_cspu_level_1d` | 获取 CSPU 近 7 天订单量，计算 `avg_cspu_order_cnt_7d` |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_one_variation_model_day_level_analysis_1d` | 获取 model 近 7 天日订单量，计算 `avg_model_order_cnt_7d` |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 获取用户级别的曝光、点击、订单行为数据，用于 A/B 实验指标计算 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取 A/B 实验用户分组（实验组/对照组），用于拆分实验指标 |
| `abtest.shopee_experiment_admin_db__group_dimension_tab__reg_continuous_s0_live` | 获取实验分组元数据（group_id → exp_group_type 映射） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_one_variation_model_analysis_hf  ──┐
dim_scs_shop_list_df                                        ──┼──> cheapest_model_list / cheapest_item_list
                                                              │
dws_sr_data_warehouse_tc_pb_cspu_level_1d                  ──> cspu_label_avg（CSPU 7 日均值）
                                                              │
dws_sr_data_warehouse_tc_pb_basic_aggr_1d                  ──┐
dim_sr_data_warehouse_abtest_user_group                    ──┼──> traffic_data_item ──> model_exp_result（A/B 实验 CTR-CR）
shopee_experiment_admin_db__group_dimension_tab            ──┘
                                                              │
dws_sr_data_warehouse_tc_pb_one_variation_model_day_level_analysis_1d ──> avg_model_order_cnt（Model 7 日均值）
                                                              │
                                                              └──> INSERT OVERWRITE ads_sr_data_warehouse_tc_pb_qc_model_level_1d
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 0 | SET `cspu_max_dt` | 获取 `dws_sr_data_warehouse_tc_pb_cspu_level_1d` 的最新数据日期，作为 CSPU 7 日窗口的终点 |
| Step 1 | `shop_type_<region>` | 从 SCS 商家维表中过滤出目标站点的 SCS 商家及其类型（`scs-local` / `scs-cb`） |
| Step 2 | `cheapest_model_list_<region>` | 关联最低价 model 分析表与 SCS 商家表，得到当日最低价 model 列表（含商家类型） |
| Step 3 | `cheapest_item_list_<region>` | 从 cheapest_model_list 聚合到 item 粒度，用于后续 A/B 实验中标记最低价 item |
| Step 4 | `dim_user_exp_<region>` | 关联实验 group 元数据与用户分组表，得到各用户所属实验组（treatment / control），过滤 `is_assignment_log = 1` |
| Step 5 | `cspu_label_avg_<region>` | 按 CSPU 聚合近 7 天（`cspu_max_dt - 6` 至 `cspu_max_dt`）的日均订单量 |
| Step 6 | `traffic_data_item_<region>` | 将用户行为数据（曝光/点击/订单）与最低价 item/model 列表关联，标记 `is_cheapest_item` 和 `is_cheapest_model` |
| Step 7 | `model_exp_result_<region>` | 按 item 聚合实验组与对照组的曝光、点击、订单及最低价子集的 CTR-CR |
| Step 8 | INSERT OVERWRITE | 以 cheapest_model_list 为主表，依次 LEFT JOIN CSPU 均值、model 7 日均值、实验结果，写入目标分区 |

### 注意事项

- **单 Writer**：本表仅有一个 ETL 文件写入，不存在多 Writer 并发冲突风险。
- **分区写入**：采用 `INSERT OVERWRITE ... PARTITION (grass_region = ${grass_region}, local_date = ${local_date})` 方式，每次按站点和日期覆盖写入对应分区，重跑幂等。
- **CSPU 7 日窗口基准日期漂移**：`avg_cspu_order_cnt_7d` 使用 `cspu_max_dt`（上游最新日期）而非当日 `local_date` 作为窗口终点，若上游数据存在延迟，该指标窗口与 `local_date` 可能不对齐，使用时需注意。
- **实验 group_id 硬编码**：实验分组 ID（`452526`～`452543`，`40252`）在 SQL 中硬编码，如实验配置变更需同步修改 ETL。
- **非最低价商品数据缺失**：目标表仅包含被识别为最低价的 model，非最低价 model 不会出现在本表中；A/B 实验指标（CTR-CR 等）若实验组无覆盖则以 0 填充，需结合 `treatment_imp_cnt` 判断数据有效性。
- **`model_type` 聚合方式**：最终取 `max(model_type)`，若同一 model 同时存在 `scs cheapest` 和 `non-scs cheapest`（理论上不应出现），以字典序较大值为准。

---

*文档生成时间：2026-05-17*