<!-- ads-workspace-gdoc-sync: gdoc_id=196LSs_-QMb4rvZbrCzfEWqvoPyAw2ifjSObXDvZYMtQ gdoc_url=https://docs.google.com/document/d/196LSs_-QMb4rvZbrCzfEWqvoPyAw2ifjSObXDvZYMtQ/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_ni_category_channel_exp_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `layer_id` + `exp_group_id` + `level1_global_be_category_id` + `level2_global_be_category_id` + `shipping_channel_id`
**分区：** `grass_region`（站点）, `local_date`（业务日期）
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 0

---

## 业务描述

本表服务于搜索推荐（SR）数据仓库中 **TC（Top Category）新品实验（New Item，简称 NI）** 分析场景，以 **A/B 实验分组 × 品类 × 物流渠道** 为粒度，汇总每日曝光、点击、订单及 GMV 等核心指标。

**核心业务场景：**

1. **A/B 实验效果评估：** 针对特定实验层（`layer_id`）和实验分组（`exp_group_id`），分析新品在不同实验组的表现差异；支持混合对照组（`exp_group_id = -99999`）与具体实验组的对比。
2. **品类维度分析：** 按一级、二级全球后台品类拆解曝光、点击、成交数据，识别新品在不同品类下的实验收益。
3. **物流渠道维度分析：** 结合订单维度的物流渠道（`shipping_channel_id`），分析不同渠道下新品的订单量与 GMV 表现；当 `shipping_channel_id = '__ALL__'` 时，代表全渠道汇总行（来自曝光流量侧）。

**适合回答的典型问题：**

- 某实验组相比对照组，在一级品类 X 下新品的曝光量、点击率、GMV 差异是多少？
- 实验层 Y 在各二级品类下，新品订单数在不同物流渠道的分布情况如何？
- 各实验组的曝光商品数（`exposed_item_cnt`）在品类维度的分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 `ID`、`MY` 等，分区键 |
| `local_date` | date | 业务日期（本地时区），分区键 |

### 维度：实验分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `layer_id` | bigint | A/B 实验层 ID，对应 abtest 系统中的实验层，当前覆盖层：114215、114572、115980、115981、115983、149987 |
| `exp_group_id` | bigint | A/B 实验分组 ID；`-99999` 为 group2～group8 的混合实验组合并行；来源于实验流量分配表 |

### 维度：商品品类

| 字段 | 类型 | 说明 |
|---|---|---|
| `level1_global_be_category_id` | bigint | 全球后台一级品类 ID |
| `level1_global_be_category` | string | 全球后台一级品类名称 |
| `level2_global_be_category_id` | bigint | 全球后台二级品类 ID |
| `level2_global_be_category` | string | 全球后台二级品类名称 |

### 维度：物流渠道

| 字段 | 类型 | 说明 |
|---|---|---|
| `shipping_channel_id` | string | 物流渠道 ID；特殊值 `'__ALL__'` 表示全渠道汇总，对应曝光流量侧数据行；具体渠道值来源于订单侧数据行 |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `exposed_item_cnt` | bigint | 曝光商品去重数（`COUNT(DISTINCT item_id)`）；仅曝光流量侧（`shipping_channel_id = '__ALL__'`）有效，订单渠道侧固定为 `0`，**不可直接跨行 SUM** |
| `imp_cnt` | bigint | 曝光次数（`SUM(imp_cnt)`）；仅曝光流量侧有效，订单渠道侧固定为 `0` |
| `click_cnt` | bigint | 点击次数（`SUM(click_cnt)`）；仅曝光流量侧有效，订单渠道侧固定为 `0` |

### 指标：成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 订单数（按 `order_fraction` 分摊）；曝光流量侧来源于 `dwm_sr_data_warehouse_tc_ab_all_cards`，渠道侧来源于 `dwd_order_item_all_ent_df__reg_s0_live` |
| `gmv` | double | GMV（美元），曝光流量侧来源于 `dwm_sr_data_warehouse_tc_ab_all_cards`，渠道侧对应字段为 `gmv_usd` |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤（强制）：** 查询时必须同时指定 `grass_region` 和 `local_date`，否则会触发全量分区扫描，影响性能。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```

### 数据行语义区分

本表由两部分 UNION ALL 合并写入，**两种行语义不同，务必在查询时根据 `shipping_channel_id` 区分：**

| 行类型 | `shipping_channel_id` 取值 | 有效指标 | 无效指标（固定为 0） |
|---|---|---|---|
| 曝光流量汇总行 | `'__ALL__'` | `exposed_item_cnt`、`imp_cnt`、`click_cnt`、`order_cnt`、`gmv` | 无 |
| 订单渠道明细行 | 具体渠道 ID | `order_cnt`、`gmv` | `exposed_item_cnt`（=0）、`imp_cnt`（=0）、`click_cnt`（=0） |

### 不可直接 SUM 的字段

- **`exposed_item_cnt`：** 为 `COUNT(DISTINCT item_id)` 的预聚合结果，**跨分组直接 SUM 会导致重复计数**，不能对多个分组/品类求和后作为全量去重数。
- **`order_cnt`：** 基于 `order_fraction` 分摊，为 double 类型，跨行求和时注意语义对齐（勿混合两种行类型求和）。
- **点击率、转化率等比率指标：** 本表未直接存储，需用 `click_cnt / imp_cnt` 等自行计算，不可对比率直接 SUM。
- **混合实验组（`exp_group_id = -99999`）** 与具体实验组存在用户重叠，**不可将两者直接加总**，需分开分析。

### 时效性说明

- 本表为 **1d（每日）** 快照表，`local_date` 对应业务本地时间日期。
- 数据覆盖范围：仅统计**创建日期在当前 `local_date` 前 90 天以内**的新品（`datediff(local_date, date(item_create_datetime)) <= 90`）。
- 实验分组覆盖范围受限于 `layer_id` 和 `experiment_id` 白名单，**不是全量用户数据**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `abtest.shopee_experiment_admin_db__group_dimension_tab__reg_continuous_s0_live` | 获取实验层、实验分组元数据，过滤指定 `scene_id=527` 及实验 ID 白名单 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取用户与实验分组的对应关系（Assignment 日志） |
| `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` | 提供商品维度的曝光、点击、订单、GMV 等流量指标（全卡片类型） |
| `srdi_mart.dim_sr_data_warehouse_item` | 提供商品的品类信息及商品创建时间（用于新品过滤：90天内） |
| `mp_order.dwd_order_item_all_ent_df__reg_s0_live` | 提供订单维度的物流渠道、订单分摊数、GMV（美元），用于渠道明细行写入 |

---

## ETL 逻辑摘要

### 数据流

```
abtest 实验元数据
       ↓
dim_sr_data_warehouse_abtest_user_group（用户-分组关系）
       ↓
user_exp（用户实验分组，含混合组 -99999）
       ↓
dwm_sr_data_warehouse_tc_ab_all_cards（曝光/点击/订单/GMV）
  + dim_sr_data_warehouse_item（新品过滤 90d + 品类信息）
  + user_exp → basic_scene_data（曝光侧，含品类）
       ↓
dwd_order_item_all_ent_df__reg_s0_live（订单渠道数据）
  + dim_sr_data_warehouse_item（新品过滤 90d）
  + user_exp → basic_shiping_channel（订单渠道侧）
       ↓
UNION ALL → INSERT OVERWRITE 目标表（按 grass_region + local_date 分区写入）
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `exp_traffic_info` | 从 abtest 系统获取实验层与分组映射，过滤 `scene_id=527`、指定 `layer_id` 与 `experiment_id` 白名单 |
| Step 2 | `user_exp_raw` | 从用户分组表获取当日 `grass_region` 的 Assignment 日志（`is_assignment_log=1`） |
| Step 3 | `user_exp` | 将 `user_exp_raw` 与 `exp_traffic_info` JOIN，得到用户的实验分组与层信息；并额外 UNION ALL 生成 `exp_group_id=-99999` 的混合实验组行（group2～group8 合并） |
| Step 4 | `traffic_data_item` | 从曝光宽表按 `user_id + item_id + is_ads` 聚合曝光、点击、订单、GMV 指标 |
| Step 5 | `item_category` | 从商品维表获取品类信息，过滤有效 `item_id > 0` |
| Step 6 | `basic_scene_data` | 将流量数据与**90天内新品**过滤后的商品维表 JOIN（保留新品），再关联用户实验分组、品类信息，形成曝光侧宽表 |
| Step 7 | `basic_shiping_channel` | 从订单宽表按买家、商品、品类、渠道聚合订单量和 GMV，同样过滤 90 天内新品，再关联用户实验分组 |
| Step 8 | INSERT OVERWRITE | 对 `basic_scene_data` 按层/分组/品类聚合，`shipping_channel_id='__ALL__'`，`exposed_item_cnt=COUNT(DISTINCT item_id)`；UNION ALL `basic_shiping_channel` 按层/分组/品类/渠道聚合，曝光点击指标补 0；写入目标表对应分区 |

### 注意事项

- **单 Writer：** `multi_writer = false`，仅一个 ETL 文件写入本表，无并发写入冲突风险。
- **INSERT OVERWRITE 分区覆盖：** 每次执行覆盖 `grass_region + local_date` 单分区，历史分区数据不受影响，重跑安全。
- **UNION ALL 行语义混合：** 目标表同一分区内混合了两种语义的行（曝光汇总行和订单渠道明细行），查询时必须通过 `shipping_channel_id` 进行区分，避免指标混用（尤其是 `exposed_item_cnt`、`imp_cnt`、`click_cnt` 在渠道明细行中为 0）。
- **新品限定：** ETL 中对曝光侧和订单侧均只保留创建时间在 `local_date` 前 90 天以内的商品，分析结论仅代表新品范畴，不适用于全量商品分析。
- **混合实验组：** `exp_group_id = -99999` 为人工构造行，代表 group2～group8 用户的汇总对照组，与具体分组 ID 存在用户重叠，使用时注意避免重复计算。
- **变量参数化：** SQL 中使用 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 等模板变量，ETL 框架在执行时动态替换，每次执行针对单一站点单一日期。

---

*文档生成时间：2026-05-18*