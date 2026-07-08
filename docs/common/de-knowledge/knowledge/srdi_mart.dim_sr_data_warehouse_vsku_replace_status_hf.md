<!-- ads-workspace-gdoc-sync: gdoc_id=1ahHgUIoTIlBqvlQ--ztZ0v0RLhIP80kaIsAL7XF0ikU gdoc_url=https://docs.google.com/document/d/1ahHgUIoTIlBqvlQ--ztZ0v0RLhIP80kaIsAL7XF0ikU/edit -->

# srdi_mart.dim_sr_data_warehouse_vsku_replace_status_hf

**分层：** DIM（维度层）
**主键：** `vitem_id` + `cspu_id` + `exp_tag` + `grass_region` + `regional_date` + `regional_hour`
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 小时级（Hourly）
**访问频次：** 12,669 次

---

## 业务描述

本表用于维护 **vSKU 替换（Replace）流水线中各 vitem-cspu 组合的状态快照**，是搜推数仓 vSKU 替换模块的核心维表。表中以实验策略标签（`exp_tag`）为维度对每个 vitem-cspu 映射关系进行多份复制，支持 A/B 实验对照分析。

**核心业务场景：**
- 跟踪每个 vitem 在不同替换实验策略下的当前状态（`prepare` / `explore` / `filtered`），支撑线上 vSKU 替换策略的状态流转管理；
- 记录 vitem 的质检结果（`is_qualified`）、版本日期（`version_date`）及过滤原因（`filtered_reason`），供下游决策使用；
- 通过累积历史分区与当前最新分区进行全外连接，保障全量 vitem-cspu 映射不丢失（兜底设计）；
- 每小时覆盖写入，维护准实时的 vitem 替换状态快照。

**适合回答的问题：**
- 当前某 region 下，各 vitem 在指定实验策略中处于什么替换状态？
- 哪些 vitem 未通过质检，过滤原因是什么？
- 某 vitem 的版本日期是什么，是否需要升级版本？
- 各实验策略（T1/T2/T3/T5）下 vitem 的覆盖范围和状态分布如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区标识，如 TH、VN、MY、PH、BR、TW 等 |
| `local_date` | date | 本地时区日期，由 `regional_date` 和 `regional_hour` 经时区转换（以 SG 为基准）得到 |
| `local_hour` | int | 本地时区小时，由 `regional_date` 和 `regional_hour` 经时区转换得到 |
| `regional_date` | date | 区域基准日期（新加坡时区），任务调度参数 |
| `regional_hour` | int | 区域基准小时（新加坡时区），任务调度参数 |

### 维度：vitem-cspu 映射标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `vitem_id` | bigint | 虚拟商品 ID（vitem），替换策略的核心粒度 |
| `cspu_id` | bigint | 候选 SPU ID，与 `vitem_id` 构成替换映射关系 |
| `exp_tag` | string | 实验策略标签，取值范围依 region 而定：TH 支持 T1/T2/T3，VN/MY 支持 T1/T2，PH 支持 T1/T2/T5，BR/TW 仅支持 T1 |

### 维度：vitem 替换状态与质检信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `vitem_status` | string | vitem 当前替换状态，取值：`prepare`（质检中/无质检信息）、`explore`（通过质检）、`filtered`（未通过质检）|
| `is_exempted` | int | 是否豁免标志，当前阶段（Phase 1）固定写入 0，暂未接入 MPI 逻辑 |
| `is_qualified` | int | 质检结果：1 表示通过，0 表示不通过，null 表示尚无质检信息 |
| `version_date` | string | vitem 当前版本日期（格式 yyyyMMdd），用于线上版本流转判断；若质检信息缺失则为 null |
| `filtered_reason` | string | 质检不通过的原因说明，通过质检时值为 `sucess`（注：原始拼写错误，保持与上游一致以避免影响下游） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤为强制要求**，查询时必须指定 `grass_region`、`regional_date`、`regional_hour`（或等价的 `local_date`、`local_hour`），否则将全量扫描所有历史分区，造成严重性能问题。
- 推荐优先使用 `grass_region` + `regional_date` + `regional_hour` 组合定位目标分区，与 ETL 调度参数对齐。
- 若使用本地时区过滤，需使用 `local_date` + `local_hour`，但需注意跨时区偏差（部分 region 与 SG 存在时差）。

### 不可直接聚合的字段

- **`is_qualified`**：取值为 0/1/null，跨 cspu_id 聚合时需使用 `MAX` 或 `MIN`，不可直接 `SUM`（ETL 中即采用 `MAX` 聚合到 vitem 粒度）。
- **`version_date`**：字符串类型（yyyyMMdd），用于版本比较时需注意类型转换，不可进行数值 SUM。
- **`is_exempted`**：当前固定值 0，无统计意义，不应参与聚合计算。

### 时效性说明

- 本表为**小时级快照表**（`_hf` 后缀），每小时覆盖写入（`INSERT OVERWRITE`）当前分区。
- ETL 设计包含**兜底逻辑**：若当前分区写入失败，会回溯最近 7 天内最新可用分区的历史数据进行累积，确保数据连续性；极端情况下 7×24 个小时内大概率有一次成功写入。
- 取最新状态时，建议按 `regional_date DESC, regional_hour DESC` 取最新分区，而非依赖 `local_date/local_hour` 排序。
- 上游版本标签数据（`version_label`）取自前一天（`date_sub(regional_date, 1)`），存在约 1 天的版本信息延迟。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_vsku_model_mapping_hf` | 获取当前 vitem-cspu 全量映射关系，作为当前分区的新增/存量数据基础 |
| `srdi_mart.dim_sr_data_warehouse_vsku_replace_status_hf`（自身历史分区） | 回溯最近 7 天内最新可用历史分区，用于状态累积和兜底 |
| `srdi_mart.dwd_sr_data_warehouse_vsku_replace_update_version_nd` | 获取前一日版本升级信号（`version_date`），驱动 vitem 版本更新判断 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_vsku_model_mapping_hf  ──► vitem_cspu（当前全量映射 × exp_tag 展开）
                                                            │
dim_sr_data_warehouse_vsku_replace_status_hf ──► last_vitem_cspu（最近7天内最新可用历史分区）
（自身历史分区）                                             │
                                                            ▼
                                               accumulated_vitem_cspu（全外连接，取并集）
                                                            │
last_vitem_cspu ──► last_vitem（vitem 粒度聚合历史状态）    │
dwd_sr_..._version_nd ──► version_label（版本升级信号）     │
                                                            ▼
                                            INSERT OVERWRITE → dim_sr_data_warehouse_vsku_replace_status_hf
```

### 关键步骤

1. **Statement 1 — `vitem_cspu`（Temporary View）**
   从 `dim_sr_data_warehouse_vsku_model_mapping_hf` 获取当前 regional 分区下所有 vitem-cspu 映射，通过 `LATERAL VIEW EXPLODE` 按实验策略列表（T1/T2/T3/T5）进行维表复制，并根据 `grass_region` 过滤各 region 实际支持的 exp_tag 组合。

2. **Statement 2 — 查找最近可用历史分区（SET 变量）**
   查询自身表近 7 天内、时间早于当前调度参数的最大分区标识（格式 `regional_date_HH`），作为历史状态回溯的兜底来源。

3. **Statement 3 — `last_vitem_cspu`（Temporary View）**
   从自身历史分区（由 Statement 2 确定的最新可用分区）读取上一次写入的 vitem-cspu 状态数据，包含 status、is_qualified、version_date、filtered_reason。

4. **Statement 4 — `accumulated_vitem_cspu`（Temporary View）**
   对 `last_vitem_cspu`（历史）与 `vitem_cspu`（当前）执行 FULL OUTER JOIN，取两侧 vitem-cspu-exp_tag 三元组的并集，确保无数据丢失。

5. **Statement 5 — `last_vitem`（Temporary View）**
   将 `last_vitem_cspu` 聚合到 vitem 粒度（`GROUP BY exp_tag, vitem_id`），对 `vitem_status`、`is_qualified`、`version_date`、`filtered_reason` 取 MAX，消除因新增 rmodel_id 导致的重复版本问题。

6. **Statement 6 — `version_label`（Temporary View）**
   从 `dwd_sr_data_warehouse_vsku_replace_update_version_nd` 读取前一日（`date_sub(regional_date, 1)`）的版本升级信号，获取各 vitem 的 `new_version_date`。

7. **Statement 7 — INSERT OVERWRITE（目标写入）**
   以 `accumulated_vitem_cspu` 为主体，LEFT JOIN `version_label` 和 `last_vitem`，按以下规则决定是否触发状态更新（`update_flag`）：
   - 触发更新：`new_version_date` 不为 null 且大于历史 `version_date`，或历史 `version_date` 为 null（新增或历史无质检信息）；
   - 更新时：`vitem_status` 由 `new_is_qualified`（固定为 1）推导为 `explore`，`version_date` 更新为当前 regional_date（yyyyMMdd 格式），`filtered_reason` 置为 `sucess`；
   - 不更新时：保持历史字段值不变；
   - `is_exempted` 固定写入 0；
   - `local_date`/`local_hour` 由 `regional_date`/`regional_hour` 经时区转换函数 `date_timezone_convert` 计算得到。

### 注意事项

- **Multi-writer：** 本表仅由单一 ETL 文件写入（`multi_writer: false`），无并发写入冲突风险。
- **自引用风险：** ETL 同时读写同一张表（读历史分区、写当前分区），需确保调度参数 `regional_date`/`regional_hour` 与目标写入分区精确对应，避免读写分区重叠导致数据污染。
- **兜底分区查找依赖自身数据：** 若目标表首次初始化或近 7 天内完全无数据，`last_partition` 变量将为 null，`last_vitem_cspu` 视图将为空，此时 ETL 仅写入当前新增 vitem-cspu 数据，无历史累积。
- **`filtered_reason` 拼写错误：** 原始值 `sucess` 为已知拼写错误，ETL 注释明确说明为保持与下游一致而维持原样，下游使用时需以 `'sucess'` 为准，勿按 `'success'` 过滤。
- **`is_qualified` 质检逻辑简化：** 当前 Phase 1 版本中，通过版本升级信号的 vitem `new_is_qualified` 固定赋值为 1（通过质检），独立质检模块（`qualify_label`）已注释掉，实际质检仅依赖版本升级驱动。
- **版本升级数据时效：** `version_label` 来源表仅包含每天增量数据，若上游 23 点附近才产出，存在本小时 ETL 运行时获取不到最新版本信号的风险（ETL 注释中已说明约 99% 情况不会错过）。

---

*文档生成时间：2026-05-17*