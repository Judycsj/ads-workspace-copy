<!-- ads-workspace-gdoc-sync: gdoc_id=1RJvGNXnQbU7-mw0unoo0pkKD7OWRv20Q7Q_aVa_lGVU gdoc_url=https://docs.google.com/document/d/1RJvGNXnQbU7-mw0unoo0pkKD7OWRv20Q7Q_aVa_lGVU/edit -->

# srdi_mart.dim_sr_data_warehouse_tc_ni_cspu_type

**分层：** dim（维度层）
**主键：** `item_id`（分区内唯一）
**分区：** `grass_region`（大区）/ `local_date`（本地日期）
**更新频率：** 每日一次（按大区按天覆盖写入）
**访问频次：** 3,848 次

---

## 业务描述

本表为**新品（New Item）CSPU 类型维度表**，面向搜索与推荐（SR）数仓体系，记录近 90 天内上架的活跃新品商品（item）在当前 CSPU（商品池单元）维度下的类型分类。

**核心业务场景：**
- 新品运营：区分新品在 CSPU 链路中所处的质量与活跃层级，为搜推策略提供商品类型标签。
- 搜推召回 / 排序：依据 `cspu_type` 字段区分新品中的"强新新品"、"无模型关联新品"、"高/低订单密度 CSPU 新品"等，支撑差异化的流量分配策略。
- 数据质量监控：识别无有效 CSPU 挂载或订单数据异常的新品。

**适合回答的问题：**
- 某大区某天，新品商品的 CSPU 类型分布情况如何？
- 哪些新品属于"新新 CSPU"（即 CSPU 中新品占比 ≥ 80%）？
- 新品商品是否有活跃模型关联，以及关联 CSPU 的订单密度处于何种档位？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 ID、MY、TH 等），ETL 按大区独立计算并分区写入 |
| `local_date` | date | 本地日期，与大区时区对齐，ETL 执行日对应的业务日期 |

### 维度：商品 CSPU 类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，分区内唯一主键，仅覆盖近 90 天内创建的非 VSKU 活跃新品 |
| `cspu_type` | bigint | 新品的 CSPU 类型编码，取值含义见下方说明；若无法匹配则默认为 8 |

**`cspu_type` 取值说明：**

| 取值 | 含义 |
|---|---|
| 1 | 新新 CSPU 新品：商品所在 CSPU 中新品占比 ≥ 80% |
| 2 | 无活跃模型关联新品：商品在近期无有效的 model 挂载 |
| 3 | 极低订单 CSPU 新品：所在 CSPU 近 7 天订单数 ≤ 1 |
| 4 | 低店铺数或高订单密度 CSPU 新品：CSPU 关联店铺数 ≤ 5，或订单数 / 店铺数 ≥ 1 |
| 6 | 低订单密度 CSPU 新品：CSPU 订单数 / 店铺数 < 1 |
| 8 | 兜底类型：无法归入上述任何类型（含无 CSPU 挂载、CSPU 类型比例未达阈值等情况） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须显式指定**，查询时务必同时过滤 `grass_region` 和 `local_date`，避免全量扫描：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-15'
  ```
- 不得省略 `grass_region`，该表按大区独立产出，跨大区数据不可混用。

### 不可直接聚合的字段

- `cspu_type` 为**分类编码**，不具备数值加减意义，禁止直接 `SUM` 或 `AVG`；分析时应使用 `COUNT` + `GROUP BY` 做分布统计。
- 该表不含比率、均值等预聚合指标字段，但 `cspu_type` 本身是多步骤规则派生的结果标签，不应做二次数值运算。

### 时效性说明

- 表按天产出，当天分区数据代表**截至 ETL 执行时刻**的新品 CSPU 类型快照。
- CSPU 链路数据来源（`dwd_sr_data_warehouse_ni_all_cspu_link_hf` / `dwd_sr_data_warehouse_pb_all_cspu_link_hf`）为小时级分区表，ETL 取近 7 天内**最新可用分区**，非严格对齐当天 0 点，存在数小时延迟。
- 平台订单数据同样取近 7 天内最新分区，订单统计窗口为最新分区日期往前 7 天（含），非固定自然日。
- 新品定义：商品创建日期在最新数据日期往前 90 天以内，且商品状态 / 模型状态均为有效。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_item.dim_model__reg_s0_live` | 获取 model-item 关联关系及商品创建时间，用于识别新品的活跃 model 挂载 |
| `mp_item.dim_item__reg_s0_live` | 获取商品基础信息，用于确定近 90 天新品范围（排除 VSKU） |
| `srdi_mart.dwd_sr_data_warehouse_ni_all_cspu_link_hf` | NI（New Item）链路的 CSPU-model-shop 关联关系，小时级分区，取最新分区 |
| `srdi_mart.dwd_sr_data_warehouse_pb_all_cspu_link_hf` | PB（Price Benchmark）链路的 CSPU-model-shop 关联关系，小时级分区，取最新分区 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 平台行为数据（operation='order'），用于统计 model 近 7 天订单量 |

---

## ETL 逻辑摘要

### 数据流

```
mp_item.dim_item__reg_s0_live          →  新品 item 集合（近90天）
mp_item.dim_model__reg_s0_live         →  新品活跃 model 集合
dwd_sr_data_warehouse_ni_all_cspu_link_hf  ┐
dwd_sr_data_warehouse_pb_all_cspu_link_hf  ┘ → 合并 CSPU-model-shop 关联
dwd_sr_data_warehouse_platform         →  model 近7天订单量
                                           ↓
                              CSPU 类型分级计算（step1~step4）
                                           ↓
              dim_sr_data_warehouse_tc_ni_cspu_type（分区覆盖写入）
```

### 关键步骤

| 步骤 | 临时视图 / 操作 | 说明 |
|---|---|---|
| Step 1-a | `model_max_pt_step1` | 从 `dim_model__reg_s0_live` 取近 7 天有效 model-item 数据 |
| Step 1-b | `item_max_pt_step1` | 从 `dim_item__reg_s0_live` 取近 7 天有效非 VSKU 商品数据 |
| Step 2 | `new_item_active_model` | 取最新分区中，商品创建日期在近 90 天内的 model-item 关联（新品活跃 model） |
| Step 3 | `new_item` | 取最新分区中，商品创建日期在近 90 天内的 item 集合（新品主集合） |
| Step 4 | SET 变量 | 分别确定 NI CSPU 链路、PB CSPU 链路、平台订单数据的最新可用分区时间戳 |
| Step 5 | `new_new_cspu` | 从 NI CSPU 链路取最新分区，计算各 CSPU 中新品 item 占比，筛选比例 ≥ 80% 的 CSPU（"新新 CSPU"） |
| Step 6 | `model_order` | 从平台数据统计各 model 在最新7天窗口内的订单量 |
| Step 7 | `all_cspu_link` | 合并 PB 和 NI 两条链路的最新分区 CSPU-model-shop 关联（UNION ALL + GROUP BY 去重） |
| Step 8 | `cspu_level_step1` | 基于 CSPU 关联的店铺数和订单量，按规则计算 CSPU 级别（type 3/4/6） |
| Step 9 | `cspu_level_step2` | 以新品 item 为主体，依次 LEFT JOIN 活跃 model、CSPU 链路、新新 CSPU、CSPU 级别，按优先级规则赋予每行 `cspu_type`（1/2/type/8） |
| Step 10 | `cspu_level_step3` | 计算每个 item 在各 `cspu_type` 下关联 model 的比例（model_ratio） |
| Step 11 | `cspu_level_step4` | 保留 model_ratio ≥ 0.5 的 cspu_type，用 ROW_NUMBER 取优先级最高（type 值最小）的唯一类型 |
| 最终写入 | `INSERT OVERWRITE` | 以新品 item 为主，LEFT JOIN step4 结果，`cspu_type` 兜底填 8，覆盖写入目标分区 |

### 注意事项

1. **CSPU 链路分区非严格对齐当天**：ETL 通过 `SET` 变量动态查找近 7 天内最新可用小时分区（`concat(local_date,'_',local_hour)`），若上游小时表延迟较大，实际使用的 CSPU 数据可能落后于业务日期数小时，需关注上游小时表的产出时效。
2. **平台订单窗口动态对齐**：订单统计窗口基于平台数据最新可用日期往前 7 天，与 `local_date` 参数无直接绑定，窗口起止日期可能因上游延迟而偏移。
3. **单 Writer 无并发风险**：`multi_writer = false`，单个 ETL 文件写入，无多 Writer 竞争问题，但每个大区作为独立参数执行，不同大区之间天然隔离。
4. **VSKU 已过滤**：`is_spu_vsku=0` 限制确保表中不含虚拟 SKU 商品，下游使用时无需再次过滤。
5. **新品范围为近 90 天**：item 的创建日期须在最新数据日期 -90 天至最新日期区间内，超出该范围的商品不会出现在本表，不代表"无类型"而是"不在新品范围"。
6. **`cspu_type` 赋值优先级**：type=1（新新 CSPU）> type=2（无活跃 model）> type=3/4/6（CSPU 级别规则）> type=8（兜底），最终通过 model_ratio ≥ 0.5 阈值 + ROW_NUMBER 取最小 type 值实现唯一确定。

---

*文档生成时间：2026-05-17*