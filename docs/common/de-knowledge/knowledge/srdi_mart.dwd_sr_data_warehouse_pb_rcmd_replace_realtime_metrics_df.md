<!-- ads-workspace-gdoc-sync: gdoc_id=1Svq7w-eowt5QpDJWjLd_z6u-FkR7midwQq8ZOhRhuzc gdoc_url=https://docs.google.com/document/d/1Svq7w-eowt5QpDJWjLd_z6u-FkR7midwQq8ZOhRhuzc/edit -->

# srdi_mart.dwd_sr_data_warehouse_pb_rcmd_replace_realtime_metrics_df

**分层：** DWD（明细数据层）
**主键：** `item_id`、`cspu_id`、`grass_region`、`regional_date`（联合唯一标识一条记录）
**分区：** `grass_region`（大区）、`regional_date`（业务日期）
**更新频率：** 每日全量覆盖写入（`INSERT OVERWRITE`）
**引用频次 / 访问频次：** 0

---

## 业务描述

本表属于搜推数仓（SRDI）DWD 层，存储**商品推荐替换（Replace Recommendation）实时指标**的每日快照明细数据。

数据来源于 Paimon ODS 实时层，经过大区过滤后按日分区落地为离线明细表，保留了商品在不同推荐版本、不同标签维度下的曝光次数和点击次数数组，供下游聚合分析使用。

**核心业务场景：**
- 追踪推荐替换策略下各商品（`item_id` / `cspu_id`）在不同版本（`version_array`）和标签（`tag_array`）分组下的实时曝光与点击表现。
- 支持按大区、日期切片，分析推荐替换效果的区域差异与时间趋势。

**适合回答的问题：**
- 某大区某日期下，各商品在各推荐替换版本中的曝光量和点击量分布如何？
- 某商品在哪些推荐标签下点击率更高？
- 推荐替换策略在不同版本迭代间的效果对比。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY 等），作为第一级分区，查询时必须指定 |
| `regional_date` | date | 业务日期，数据对应的本地日期，作为第二级分区，查询时必须指定 |

### 维度：商品与推荐标签标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，推荐场景下的商品唯一标识 |
| `cspu_id` | bigint | CSPU ID，商品标准化 SKU 标识，与 `item_id` 共同定位一个推荐商品实体 |
| `version_array` | array\<bigint\> | 推荐版本号数组，记录该商品在当前快照内出现的所有推荐替换版本，与 `imp_cnt_array`、`clk_cnt_array` 等数组下标一一对应 |
| `tag_array` | array\<string\> | 推荐标签数组，标记商品在推荐替换策略中所属的标签分类，与其他数组下标对齐 |

### 指标：曝光与点击计数（数组形式）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_array` | array\<bigint\> | 曝光次数数组，与 `version_array`、`tag_array` 下标对应，记录各版本/标签下商品的曝光量；**不可直接 SUM，需先 EXPLODE 展开后再聚合** |
| `clk_cnt_array` | array\<bigint\> | 点击次数数组，与 `version_array`、`tag_array` 下标对应，记录各版本/标签下商品的点击量；**不可直接 SUM，需先 EXPLODE 展开后再聚合** |

---

## 查询使用须知

1. **必须指定分区过滤条件**
   - 查询时**必须同时指定** `grass_region` 和 `regional_date`，否则将触发全分区扫描，导致性能严重下降甚至超时。
   - 示例：
     ```sql
     WHERE grass_region = 'SG'
       AND regional_date = '2024-06-01'
     ```

2. **数组字段不可直接聚合**
   - `imp_cnt_array`、`clk_cnt_array`、`version_array`、`tag_array` 均为数组类型，**不可直接对数组字段执行 SUM / COUNT** 等聚合操作。
   - 需先使用 `POSEXPLODE` 或 `ARRAYS_ZIP` 展开为行级数据后，再进行聚合。
   - 示例：
     ```sql
     SELECT item_id, cspu_id, version, tag, imp_cnt, clk_cnt
     FROM srdi_mart.dwd_sr_data_warehouse_pb_rcmd_replace_realtime_metrics_df
     LATERAL VIEW POSEXPLODE(version_array) t1 AS pos, version
     LATERAL VIEW POSEXPLODE(tag_array)     t2 AS pos2, tag
     LATERAL VIEW POSEXPLODE(imp_cnt_array) t3 AS pos3, imp_cnt
     LATERAL VIEW POSEXPLODE(clk_cnt_array) t4 AS pos4, clk_cnt
     WHERE grass_region = 'SG'
       AND regional_date = '2024-06-01'
       AND pos = pos2 AND pos = pos3 AND pos = pos4
     ```

3. **时效性说明**
   - 本表数据来源于 Paimon 实时 ODS 层（`ods_sr_data_warehouse_pb_rcmd_replace_realtime_metrics`），具有**准实时**特性，但 DWD 层以**每日覆盖**方式落地，当天数据以调度完成时刻为准，非严格实时可查。
   - `regional_date` 为**各大区本地日期**，跨大区对比时需注意时区差异。

4. **点击率（CTR）计算**
   - 不要直接相除数组字段，需展开后逐元素计算 `clk_cnt / imp_cnt`，并注意 `imp_cnt = 0` 时的除零保护。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.srdi_mart.ods_sr_data_warehouse_pb_rcmd_replace_realtime_metrics` | 商品推荐替换实时指标 ODS 源表（Paimon 格式），提供全量实时指标明细，经大区过滤后写入本 DWD 表 |

---

## ETL 逻辑摘要

### 数据流

```
paimon.srdi_mart.ods_sr_data_warehouse_pb_rcmd_replace_realtime_metrics
    └─ 按 grass_region 过滤
        └─ INSERT OVERWRITE
            └─ srdi_mart.dwd_sr_data_warehouse_pb_rcmd_replace_realtime_metrics_df
               PARTITION (grass_region = ${grass_region}, regional_date = ${local_date})
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| Step 1 | Final INSERT | 直接从 Paimon ODS 实时表读取数据，按参数化大区（`${grass_region}`）过滤，将 `item_id`、`cspu_id`、`version_array`、`tag_array`、`imp_cnt_array`、`clk_cnt_array` 六个字段写入目标表对应分区，采用 `INSERT OVERWRITE` 全量替换当日分区数据 |

### 注意事项

1. **单 writer 全量覆盖**：本表为单 ETL 文件写入（`multi_writer = false`），每次调度以 `INSERT OVERWRITE PARTITION` 方式覆盖指定 `grass_region` + `regional_date` 分区，不存在多文件并发写入冲突风险。
2. **参数化分区**：目标分区由调度参数 `${grass_region}` 和 `${local_date}` 动态注入，重跑历史分区时需确认参数与预期日期一致，避免覆盖错误分区。
3. **无中间视图**：ETL 逻辑极简，无临时视图或中间表，ODS → DWD 直通，字段原样透传，无转换加工逻辑。
4. **Paimon 依赖**：上游为 Paimon 格式实时表，调度时需确保 Paimon catalog 连通性及 ODS 数据已完整落地，否则可能导致 DWD 数据不全。

---

*文档生成时间：2026-05-18*