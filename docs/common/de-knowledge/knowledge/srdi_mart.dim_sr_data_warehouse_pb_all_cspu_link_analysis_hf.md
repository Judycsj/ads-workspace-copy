<!-- ads-workspace-gdoc-sync: gdoc_id=15DNnhswCut_ocdVwdeEPmaVgVwBq_LEEYtMynbGbtxs gdoc_url=https://docs.google.com/document/d/15DNnhswCut_ocdVwdeEPmaVgVwBq_LEEYtMynbGbtxs/edit -->

# srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf

**分层：** dim（维度层）
**主键：** `cspu_id` + `grass_region` + `local_date` + `local_hour`
**分区：** `grass_region` / `local_date` / `local_hour`
**更新频率：** 小时级（hf = hourly frequency）
**访问频次：** 2,958 次
**Multi-writer：** 是（2 个 ETL 文件写入不同分区场景）

---

## 业务描述

本表是搜推（SR）数仓中 **CSPU 粒度商品链路分析** 的小时级维度表，用于记录每个 CSPU（内容商品单元）在指定区域、指定日期、指定小时下的完整关联链路信息，包括其对应的 model、商品（item）、店铺（shop）及业务标签（biz_tag）。

**核心业务场景：**
- 支持对搜推 PB（Price Book）全量 CSPU 在各区域各小时的商品链路分析；
- 通过小时补全机制（complement hour），在某小时无真实 dump 数据时，以最近有效小时数据兜底，保证全天 24 小时分区数据连续性；
- 亚洲区域通过主 ETL 逻辑生成，非亚洲区域通过独立导入文件写入对应分区。

**适合回答的问题：**
- 某区域某日某小时，哪些 CSPU 参与了搜推 PB 链路？
- 指定 CSPU 在某天各小时的 model / item / shop 关联情况如何？
- 某 biz_tag 下的 CSPU 链路分布在各区域各时段如何变化？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 区域标识，如 `SG`、`MY`、`US` 等；每个分区写入一个区域 |
| `local_date` | date | 本地日期（按区域时区），格式 `yyyy-MM-dd` |
| `local_hour` | int | 本地小时（0–23）；主 ETL 会将实际有数据的小时映射至全 24 小时，缺失小时用最近有效小时数据补全 |

### 维度：CSPU 商品链路标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（内容商品单元）ID，为本表核心分析粒度 |
| `model_id` | bigint | 商品 Model ID，CSPU 所属的 model 维度标识 |
| `item_id` | bigint | 商品 Item ID，CSPU 对应的 SKU/商品 ID |
| `shop_id` | bigint | 店铺 ID，商品所属的店铺维度标识 |

### 维度：业务标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `biz_tag` | bigint | 业务标签；上游同一（cspu_id, model_id, item_id, shop_id, local_hour）组合可能存在多行，ETL 取 `max(biz_tag)` 聚合后写入 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region`、`local_date`**，否则将触发全分区扫描，消耗大量计算资源。
- 若只关注特定小时，需同时过滤 `local_hour`。
- 示例：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-05-17'
    AND local_hour = 12
  ```

### 不可直接 SUM 的字段

- **`biz_tag`**：为业务枚举标签（ETL 使用 `max` 聚合得出），无数值求和含义，不可对其执行 `SUM`/均值等聚合。
- **`local_hour` 补全数据**：本表存在小时补全逻辑（以最近真实小时数据填充缺失小时），对补全小时的数据做计数/求和时需注意可能存在重复计入的情况，建议结合原始 dwd 层数据交叉验证。

### 时效性说明

- 本表为**小时级更新**（hf 后缀），每小时触发一次调度，写入当日对应小时分区。
- 由于存在小时补全机制，查询当天尚未产出的小时分区时，可能读取到以最近已落盘小时复制的数据，而非该小时的真实数据。
- 非亚洲区域数据来自独立导入流程，与亚洲区域调度时间可能存在差异。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_pb_all_cspu_link_hf` | 主数据源（亚洲区域），提供 CSPU 维度商品链路明细，按 grass_region + local_date 过滤后聚合使用 |
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf_import_nonasian` | 非亚洲区域独立导入源，直接按 grass_region + local_date 过滤后写入目标表对应分区 |

---

## ETL 逻辑摘要

### 数据流

```
[亚洲区域]
srdi_mart.dwd_sr_data_warehouse_pb_all_cspu_link_hf
    → (按 region + date 过滤 + group by 聚合 biz_tag)
    → Temp View: cspu_{region}
    → Cross Join 24小时列表 + 已有小时列表
    → (最近小时补全算法)
    → Temp View: complement_hour_list_{region}
    → INSERT OVERWRITE 目标表（24小时全覆盖）

[非亚洲区域]
srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf_import_nonasian
    → (按 region + date 过滤)
    → INSERT OVERWRITE 目标表（对应分区）
```

### 关键步骤

**ETL Source 1（亚洲区域，共 5 个 Statement）：**

1. **`cspu_{region}`（Temporary View）**
   从 `dwd_sr_data_warehouse_pb_all_cspu_link_hf` 读取指定 `grass_region` + `local_date` 的数据，按 `(cspu_id, model_id, item_id, shop_id, local_hour)` 分组，取 `max(biz_tag)` 去重聚合。

2. **`flag_hour_list_{region}`（Temporary View）**
   通过 `lateral view explode(array(0..23))` 生成 0–23 共 24 个虚拟小时序列，作为目标小时补全基准。

3. **`real_hour_list_{region}`（Temporary View）**
   从 `cspu_{region}` 中提取当天实际已有数据的小时列表（`group by local_hour`）。

4. **`complement_hour_list_{region}`（Temporary View）**
   将 24 小时序列与实际小时列表 cross join，计算每个虚拟小时（`flag_hour`）与所有真实小时的差值 `|real_hour - flag_hour|`，取差值最小者（`row_number = 1`），得到每个 flag_hour 对应的最近真实小时（`real_hour`）。

5. **INSERT OVERWRITE（目标写入）**
   将 `cspu_{region}` 与 `complement_hour_list_{region}` 按 `local_hour = real_hour` 左连接，以 `flag_hour` 作为输出的 `local_hour` 分区值写入目标表，实现全 24 小时分区覆盖。

**ETL Source 2（非亚洲区域，共 1 个 Statement）：**

6. **INSERT OVERWRITE（直接导入）**
   从 `dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf_import_nonasian` 按 `grass_region` + `local_date` 过滤后，直接写入目标表对应分区，字段含义与 Source 1 保持一致。

### 注意事项

- **Multi-writer 风险：** 两个 ETL 文件并发写入同一物理表的不同 `grass_region` 分区，需确保调度层面按区域维度隔离，避免同一分区被两个文件同时 `INSERT OVERWRITE` 导致数据覆盖。
- **小时补全语义：** `complement_hour_list` 补全逻辑假定当天至少存在一个小时的真实 dump 数据；若某区域某天完全无数据，该算法将无法产出任何结果，下游依赖此表的任务需做好容错处理。
- **biz_tag 聚合方式：** 上游 dwd 层同一 CSPU + 小时粒度可能存在多个 biz_tag 值，ETL 通过 `max(biz_tag)` 取最大值，业务使用时需了解此聚合语义。
- **分区写入模式：** 两个 ETL 均使用 `INSERT OVERWRITE ... PARTITION(grass_region=..., local_date=..., local_hour)` 动态分区模式写入，每次执行覆盖该 region + date 下的全部小时分区。

---

*文档生成时间：2026-05-17*