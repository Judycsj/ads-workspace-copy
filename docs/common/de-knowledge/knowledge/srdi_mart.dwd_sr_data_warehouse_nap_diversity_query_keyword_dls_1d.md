<!-- ads-workspace-gdoc-sync: gdoc_id=1AyIA5SYKTV8joHV8A5fZQp0q70QW0lTOshji_cBaKAs gdoc_url=https://docs.google.com/document/d/1AyIA5SYKTV8joHV8A5fZQp0q70QW0lTOshji_cBaKAs/edit -->

# srdi_mart.dwd_sr_data_warehouse_nap_diversity_query_keyword_dls_1d

**分层：** DWD（明细数据层）
**主键：** `keyword` + `level1_global_be_category_id` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）、`local_date`（日期）
**更新频率：** 每日一次（全量覆盖写入，`INSERT OVERWRITE`）
**引用频次 / 访问频次：** 126

---

## 业务描述

本表记录搜推（Search & Recommendation）NAP（Now & Predictive）多样性质量评估中，针对各大区 **趋势查询关键词（Trending Query Keyword）** 的人工标注打标结果。

数据来源于内部人工标注任务系统，每个关键词经过人工审核后会得到一个是否保留（Keep / Not Keep）的决策，并关联到对应的一级全球业务类目（L1 Global BE Category）。

**核心业务场景：**

- NAP 多样性关键词筛选：评估趋势关键词是否适合保留在多样性候选池中；
- 趋势话题质量管控：结合类目维度分析各区保留 / 剔除关键词的分布；
- 人工标注结果归档：为下游模型训练、规则校验提供标注基准数据。

**适合回答的问题：**

- 某大区某日期下，哪些关键词被标注为保留（Y）或不保留（N）？
- 各一级类目下，关键词的保留比例如何？
- 趋势查询关键词在不同大区的标注分布情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 US、SEA 等），写入时由调度参数 `${grass_region}` 指定 |
| `local_date` | date | 数据日期，由调度参数 `${local_date}` 指定，通常对应标注数据的业务日期 |

### 维度：关键词及类目信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 趋势查询关键词，来源于标注任务中的 `task_data_keyword` |
| `level1_global_be_category_id` | bigint | 关键词对应的一级全球业务类目 ID，来源于 `task_data_level1_global_be_category_id` |
| `level1_global_be_category` | string | 关键词对应的一级全球业务类目名称，来源于 `task_data_level1_global_be_category` |

### 指标：标注结论

| 字段 | 类型 | 说明 |
|---|---|---|
| `keep_or_not` | string | 关键词是否保留的标注结论。`'Y'` 表示保留（原始值 `'Keep'`），`'N'` 表示不保留（原始值 `'Not Keep'`），其余情况为 `null` |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时过滤分区字段 `grass_region` 和 `local_date`**，否则将触发全分区扫描，严重影响查询性能：
  ```sql
  WHERE grass_region = 'US'
    AND local_date = '2024-01-01'
  ```

### 不可直接 SUM 的字段

- `keep_or_not` 为枚举字符串（`'Y'` / `'N'` / `null`），**不可直接聚合求和**，统计保留率时需先用 `COUNT` 或 `CASE WHEN` 转换：
  ```sql
  -- 正确示例
  COUNT(CASE WHEN keep_or_not = 'Y' THEN 1 END) / COUNT(*) AS keep_rate
  ```

### 去重说明

- ETL 通过 `GROUP BY keyword, level1_global_be_category_id, level1_global_be_category, keep_or_not` 对源数据做了去重处理，同一关键词在同一区、同一类目下理论上为一条记录，但需注意同一关键词可能对应多个类目或多条标注决策，**不可在未 GROUP BY 时直接假设关键词唯一**。

### 时效性说明

- 本表每日全量覆盖（`INSERT OVERWRITE`）对应分区，数据时效为 **T+1**；
- ETL 从上游取的是 `grass_date` 最大值（即最新一次打标结果），**并非累计历史全量**，每日分区只反映截至当天最新的标注状态；
- 若当日上游标注任务未完成或未产出数据，对应分区可能为空或延迟产出。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `video_bi.trending_page_trending_query_marking_result` | 趋势页查询关键词人工打标结果，提供关键词、类目、标注决策等原始字段 |

---

## ETL 逻辑摘要

### 数据流

```
video_bi.trending_page_trending_query_marking_result
    │
    │  过滤：grass_date = MAX(grass_date) 且 task_data_grass_region = ${grass_region}
    │  转换：keep_or_not 枚举映射（Keep→Y，Not Keep→N，其他→null）
    │  去重：GROUP BY keyword, category_id, category, keep_or_not
    ▼
srdi_mart.dwd_sr_data_warehouse_nap_diversity_query_keyword_dls_1d
    partition(grass_region=${grass_region}, local_date=${local_date})
```

### 关键步骤

1. **分区过滤（最新标注）**
   - 从 `video_bi.trending_page_trending_query_marking_result` 中，仅取 `grass_date` 等于全表最大日期的记录，确保使用最新一批标注结果。
   - 同时过滤 `task_data_grass_region = ${grass_region}`，限定大区范围。

2. **字段映射与标注转换**
   - `task_data_keyword` → `keyword`
   - `task_data_level1_global_be_category_id` → `level1_global_be_category_id`
   - `task_data_level1_global_be_category` → `level1_global_be_category`
   - `completion_data_keep_decision`：通过 `CASE WHEN` 将 `'Keep'` 映射为 `'Y'`，`'Not Keep'` 映射为 `'N'`，其余为 `null`，输出为 `keep_or_not`

3. **去重聚合**
   - 对上述四个输出字段执行 `GROUP BY`，消除源表中可能存在的重复标注记录。

4. **分区覆盖写入**
   - 以 `INSERT OVERWRITE` 方式写入目标表指定分区 `(grass_region, local_date)`，保证幂等性。

### 注意事项

- **单 Writer**：本表仅有一个 ETL 文件写入，无 multi-writer 并发风险。
- **`INSERT OVERWRITE` 幂等性**：每次执行会完整覆盖对应 `(grass_region, local_date)` 分区，重跑安全，但会丢失同分区内的历史中间态数据。
- **上游依赖单点**：ETL 使用子查询 `select max(grass_date) from ...` 动态确定最新标注批次，若上游表在 ETL 执行期间持续写入，可能存在 `max(grass_date)` 不稳定的风险，建议调度时确保上游数据已完整落地。
- **分区字段不来自源表字段**：`local_date` 由调度参数注入，与源表的 `grass_date` 存在语义差异，需注意两者的对应关系以避免分区错位。

---

*文档生成时间：2026-05-17*