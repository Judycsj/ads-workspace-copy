<!-- ads-workspace-gdoc-sync: gdoc_id=1yci9nIKU-1PhjTHuIl_P8JUHktVkeL08CKz4sbM1V6U gdoc_url=https://docs.google.com/document/d/1yci9nIKU-1PhjTHuIl_P8JUHktVkeL08CKz4sbM1V6U/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_retention_30d

**分层：** DWS（数据服务层）
**主键：** `grass_region` + `local_date` + `scenario_tag`
**分区：** `grass_region`（大区）, `local_date`（日期）
**更新频率：** 每日一次（T+1 跑批）
**引用频次 / 访问频次：** 1052

---

## 业务描述

本表记录搜推数仓平台各**业务场景**（`scenario_tag`）维度下，不同留存周期（1 日、3 日、7 日、14 日、30 日）的**用户留存率**，粒度为：大区 × 场景 × 留存基准日期。

**核心业务场景：**
- 评估各搜推场景（如搜索、推荐、广告等子场景）的用户粘性与留存健康度。
- 对比不同场景在 1/3/7/14/30 日留存率上的差异，辅助产品迭代和运营决策。
- 监控长短周期留存趋势，识别留存异常的场景或大区。

**适合回答的问题举例：**
- 某大区某场景今天的 7 日留存率是多少？
- 过去一个月各场景的 30 日留存率走势如何？
- 不同场景之间的 1 日留存率差异有多大？

> **存储设计说明：** 每条留存指标以"基准日期"作为 `local_date` 分区写入，同一次跑批（以运行日期 `D` 为基准）会写入 5 个不同的 `local_date` 分区（D-1、D-3、D-7、D-14、D-30），且每行仅有一个留存率字段非 NULL，其余为 NULL。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 业务大区标识（如 US、BR 等），同时作为分区列；查询时必须指定 |
| `local_date` | date | 留存基准日期（即"N 天前"的那一天），作为分区列；每次跑批写入 D-1、D-3、D-7、D-14、D-30 共 5 个分区 |

### 维度：场景标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario_tag` | string | 业务场景标签，标识搜索、推荐等不同产品场景；与 `grass_region`、`local_date` 共同构成记录唯一键 |

### 指标：用户留存率

| 字段 | 类型 | 说明 |
|---|---|---|
| `retention_rate_a1` | double | 1 日留存率：`local_date` 当天有曝光的用户中，1 天后（即跑批日）仍有曝光的用户占比。对应 `local_date = D-1` 的分区行非 NULL |
| `retention_rate_a3` | double | 3 日留存率：`local_date` 当天有曝光的用户中，3 天后仍有曝光的用户占比。对应 `local_date = D-3` 的分区行非 NULL |
| `retention_rate_a7` | double | 7 日留存率：`local_date` 当天有曝光的用户中，7 天后仍有曝光的用户占比。对应 `local_date = D-7` 的分区行非 NULL |
| `retention_rate_a14` | double | 14 日留存率：`local_date` 当天有曝光的用户中，14 天后仍有曝光的用户占比。对应 `local_date = D-14` 的分区行非 NULL |
| `retention_rate_a30` | double | 30 日留存率：`local_date` 当天有曝光的用户中，30 天后仍有曝光的用户占比。对应 `local_date = D-30` 的分区行非 NULL |

### Hoodie 元数据字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `_hoodie_commit_seqno` | string | Hudi 提交序列号，框架自动维护，业务查询不使用 |
| `_hoodie_commit_time` | string | Hudi 提交时间戳，框架自动维护，业务查询不使用 |
| `_hoodie_file_name` | string | Hudi 数据文件名，框架自动维护，业务查询不使用 |
| `_hoodie_partition_path` | string | Hudi 分区路径，框架自动维护，业务查询不使用 |
| `_hoodie_record_key` | string | Hudi 记录主键，框架自动维护，业务查询不使用 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：必须指定，否则触发全分区扫描，严重影响性能。
2. **`local_date`**：建议同时指定，避免跨多个历史日期分区扫描。示例：
   ```sql
   where grass_region = 'US'
     and local_date = '2024-03-20'
   ```

### 不可直接 SUM 的字段

- **`retention_rate_a1` / `retention_rate_a3` / `retention_rate_a7` / `retention_rate_a14` / `retention_rate_a30`**：均为预计算**比率**，不可对多行直接 `SUM` 或 `AVG` 获取汇总留存率，否则结果无业务意义。如需跨场景汇总留存率，须回溯上游用户粒度表重新聚合。

### NULL 值设计说明

- 本表采用"一行一留存周期"的稀疏存储模式：同一 `local_date` 分区的每行中，**仅有一个留存率字段非 NULL**，其余四个字段均为 NULL。查询时务必注意 NULL 过滤逻辑，避免误将 NULL 计入统计。
- 推荐使用 `COALESCE` 或明确的 `IS NOT NULL` 过滤，例如：
  ```sql
  where grass_region = 'US'
    and local_date = '2024-03-13'   -- 取 D-7 的 7 日留存
    and retention_rate_a7 is not null
  ```

### 时效性说明

- 本表为 **T+1 日增量覆写**，每日跑批日期（`D`）写入对应的 5 个历史 `local_date` 分区（D-1、D-3、D-7、D-14、D-30），数据通常在每日凌晨产出，时效性约为 **T+1**。
- `local_date` 含义为留存计算的**起始基准日期**，而非数据产出日期，读取时需注意语义转换。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_user_level_benchmark_1d` | 用户级别日粒度曝光基准表，提供各场景下用户每日的曝光次数（`imp_cnt`），是计算留存率的核心上游数据源 |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_platform_user_level_benchmark_1d
  （过滤指定 grass_region + 6 个关键日期 + imp_cnt > 0 + 有效 user_id）
        │
        ▼
  Temporary View: dws_user_mapping_general_${grass_region}
  （用户 × 场景粒度，透视各关键日期是否有曝光，生成 imp_a0/a1/a3/a7/a14/a30 标记）
        │
        ▼
  Cached Table: retention_result_data_${grass_region}
  （场景粒度汇总，计算各留存率 = 同时在基准日和N天后有曝光的用户数 / 基准日有曝光的用户数）
        │
        ▼
  INSERT INTO dws_sr_data_warehouse_platform_scenario_retention_30d
  （UNION ALL 拆分为 5 行，每行写入对应 local_date 分区，仅保留当期非 NULL 的留存率字段）
```

### 关键步骤

**Step 1 — Temporary View `dws_user_mapping_general_${grass_region}`**
- 从上游用户日粒度表抽取 6 个关键日期（跑批日 D 及 D-1、D-3、D-7、D-14、D-30）的有效曝光记录（`imp_cnt > 0`，`user_id > 0`）。
- 以 `(scenario_tag, user_id)` 为粒度，用 `MAX(CASE WHEN local_date = X THEN 1 ELSE 0 END)` 透视生成各日期的曝光标记字段（`imp_a0` 为当天 D，`imp_a1` 为 D-1，依此类推）。

**Step 2 — Cached Table `retention_result_data_${grass_region}`**
- 在 Step 1 结果上，先按 `(user_id, scenario_tag)` 去重取 MAX，确保用户维度唯一。
- 再按 `scenario_tag` 聚合，计算各留存率：
  - `retention_rate_aN = SUM(imp_aN = 1 AND imp_a0 = 1) / SUM(imp_aN)`
  - 即：在 N 天前有曝光的用户中，N 天后（即跑批当天）仍有曝光的比例。
- 结果缓存（`CACHE TABLE`）以供后续多次 UNION ALL 复用。

**Step 3 — INSERT INTO 目标表**
- 将 Step 2 的缓存结果通过 5 路 `UNION ALL` 展开：每路对应一个留存周期，仅保留该周期的留存率字段为非 NULL，其余置为 NULL。
- 各路写入的 `local_date` 分区值：
  - `retention_rate_a1` → `local_date = D-1`
  - `retention_rate_a3` → `local_date = D-3`
  - `retention_rate_a7` → `local_date = D-7`
  - `retention_rate_a14` → `local_date = D-14`
  - `retention_rate_a30` → `local_date = D-30`
- 每路均加有 `WHERE retention_rate_aN IS NOT NULL` 过滤，避免写入无效行。
- 写入方式为 `INSERT INTO ... PARTITION (grass_region = ${grass_region}, local_date)`，动态分区覆盖对应历史日期。

### 注意事项

1. **单一 Writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 并发冲突风险。
2. **多分区覆写**：单次跑批同时覆写 5 个历史 `local_date` 分区（D-1、D-3、D-7、D-14、D-30），需确保 Spark 动态分区配置开启（`hive.exec.dynamic.partition.mode=nonstrict`），并注意 Hudi 表的并发写入兼容性。
3. **稀疏 NULL 设计**：每行仅一个留存率字段非 NULL 的设计在提升写入灵活性的同时，增加了查询复杂度，使用时须根据 `local_date` 对应的留存周期选取正确字段。
4. **`local_date` 语义为基准日期**：该字段表示"N 天前的起始曝光日期"，而非数据产出日，与常规日增量表的 `local_date` 含义不同，需特别注意。
5. **留存率分母为 0 的风险**：若某场景在基准日无任何有曝光用户，分母 `SUM(imp_aN)` 为 0，计算结果为 NULL，通过 `WHERE retention_rate_aN IS NOT NULL` 过滤后不会写入，属正常设计。

---

*文档生成时间：2026-05-17*