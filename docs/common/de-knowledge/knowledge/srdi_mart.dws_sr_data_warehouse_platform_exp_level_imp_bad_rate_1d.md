<!-- ads-workspace-gdoc-sync: gdoc_id=1rAwtSp1O82EdcZfVpz5mOzBFQdIazS-s3MtjREoKcyk gdoc_url=https://docs.google.com/document/d/1rAwtSp1O82EdcZfVpz5mOzBFQdIazS-s3MtjREoKcyk/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_imp_bad_rate_1d

**分层：** DWS（数据服务层）
**主键：** `exp_group_id` + `scene_type` + `is_ads` + `grass_region` + `local_date`
**分区：** `grass_region`（地区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**引用频次 / 访问频次：** 710

---

## 业务描述

本表统计 **Daily Discover（每日发现）首页** A/B 实验各分组（`exp_group_id`）在不同场景和广告类型下的**曝光劣质率**，即针对同一内容簇（item_llm_cluster_id）被大量曝光但从未产生点击的行为，评估用户在实验组维度下的内容消费体验质量。

**核心业务场景：**
- A/B 实验效果评估：衡量各实验组是否存在内容重复曝光但用户不感兴趣（零点击高曝光）的问题。
- 推荐多样性 / 内容质量监控：通过不同阈值（20、30、40 次曝光）的劣质曝光率，识别推荐策略对用户体验的负面影响。
- 广告 vs 自然内容拆分分析：支持按 `is_ads` 区分广告流量与自然推荐流量的劣质曝光表现。

**适合回答的问题：**
- 各实验组的劣质曝光率是否存在显著差异，哪个实验组对用户体验影响最小？
- 广告内容与自然内容在不同阈值下劣质曝光率的对比如何？
- 某日某地区 Daily Discover 场景下，高阈值（≥40 次）零点击的曝光占比是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区分区，如 US、SG 等，用于多地区数据隔离 |
| `local_date` | date | 业务日期分区，对应数据所属的本地日期（T 日） |

### 维度：实验与场景维度

| 字段 | 类型 | 说明 |
|------|------|------|
| `exp_group_id` | int | A/B 实验分组 ID，关联 scene_id=142（Daily Discover 主场景）的实验组 |
| `scene_type` | string | 场景类型，当前仅包含 `DD`（Daily Discover 首页），其余场景归为 `Others` |
| `is_ads` | string | 是否为广告内容：`true`（广告）、`false`（自然推荐）、`__ALL__`（全量汇总，由 GROUPING SETS 生成） |

### 指标：曝光量指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_cnt` | bigint | 实验组内用户在该场景/广告类型下的总曝光次数（`omni_scenario_imp_cnt` 汇总） |
| `imp_bad_cnt_20` | bigint | 劣质曝光次数（阈值 20）：对某内容簇曝光 ≥20 次且零点击的全部曝光次数之和 |
| `imp_bad_cnt_30` | bigint | 劣质曝光次数（阈值 30）：对某内容簇曝光 ≥30 次且零点击的全部曝光次数之和 |
| `imp_bad_cnt_40` | bigint | 劣质曝光次数（阈值 40）：对某内容簇曝光 ≥40 次且零点击的全部曝光次数之和 |

### 指标：曝光劣质率指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_bad_rate_20` | double | 劣质曝光率（阈值 20）= `imp_bad_cnt_20` / `imp_cnt`，已预聚合，**不可直接 SUM** |
| `imp_bad_rate_30` | double | 劣质曝光率（阈值 30）= `imp_bad_cnt_30` / `imp_cnt`，已预聚合，**不可直接 SUM** |
| `imp_bad_rate_40` | double | 劣质曝光率（阈值 40）= `imp_bad_cnt_40` / `imp_cnt`，已预聚合，**不可直接 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，否则将全量扫描所有历史分区，严重影响性能。  
  示例：`WHERE local_date = '2025-05-16'`
- **`grass_region`**：必须指定，否则将跨地区扫描。  
  示例：`AND grass_region = 'US'`

### 不可直接 SUM 的字段（预聚合派生指标）

以下三个字段为预计算比率，**不能跨行直接累加**，若需跨 `exp_group_id`、`is_ads`、`scene_type` 等维度聚合比率，须返回 `imp_bad_cnt_*` 与 `imp_cnt` 后**手动重算**：

```sql
-- 错误写法（结果无意义）
SELECT SUM(imp_bad_rate_20) FROM ...;

-- 正确写法（跨维度聚合后重算比率）
SELECT SUM(imp_bad_cnt_20) / SUM(imp_cnt) AS imp_bad_rate_20
FROM srdi_mart.dws_sr_data_warehouse_platform_exp_level_imp_bad_rate_1d
WHERE grass_region = 'US' AND local_date = '2025-05-16';
```

- `imp_bad_rate_20`
- `imp_bad_rate_30`
- `imp_bad_rate_40`

### `is_ads` 字段的汇总行说明

- 本表通过 `GROUPING SETS` 生成两种粒度的数据：
  - `(exp_group_id, scene_type, is_ads)`：广告 / 自然内容拆分明细行
  - `(exp_group_id, scene_type)`：全量汇总行，此时 `is_ads = '__ALL__'`
- 若需避免重复计算，查询时须明确过滤 `is_ads`，例如：

```sql
-- 只取分广告类型明细行，排除汇总行
WHERE is_ads != '__ALL__'

-- 只取全量汇总行
WHERE is_ads = '__ALL__'
```

### 时效性说明

- 本表为 **`_1d` 每日快照表**，每天覆盖写入（INSERT OVERWRITE）当日分区，数据通常在 T+1 产出。
- 不包含滚动窗口或累计值，仅代表 `local_date` 当天的统计结果。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取 A/B 实验用户-分组映射（scene_id=142，Daily Discover 主场景，仅取已分配日志的用户） |
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 获取用户-内容簇级别的曝光与点击行为指标（仅统计 Daily Discover 首页场景的有效曝光/点击） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group   dwm_sr_data_warehouse_platform_user_item
          (用户实验组归属)                          (用户-内容簇行为数据)
                │                                          │
                ▼                                          ▼
      [TempView] user_exp                    [TempView] user_cluster_metrics
      过滤 scene_id=142 的                   过滤 DD 首页曝光/点击行为，
      实验组用户列表                          按 user_id / 内容簇 / is_ads / scene_type 聚合
                │                                          │
                │                          ┌───────────────┘
                │                          ▼
                │               [TempView] user_bad_imp
                │               按 user_id / is_ads / scene_type 聚合，
                │               计算各阈值（20/30/40）劣质曝光量
                │                          │
                └──────────────────────────┤
                        INNER JOIN (user_id)│
                                           ▼
                          目标表：dws_sr_data_warehouse_platform_exp_level_imp_bad_rate_1d
                          按 GROUPING SETS 输出实验组维度汇总及 is_ads 拆分明细
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|------|-----------------------|------|
| Step 1 | `user_exp_{region}` | 从 A/B 实验用户分组表中过滤指定日期、地区、scene_id=142 且已分配实验的用户，获取 `user_id → exp_group_id` 映射 |
| Step 2 | `user_cluster_metrics_{region}` | 从用户-内容行为表中过滤 Daily Discover 首页的曝光和点击行为，按 `user_id`、`item_llm_cluster_id`、`is_ads`、`scene_type` 聚合曝光次数与点击次数 |
| Step 3 | `user_bad_imp_{region}` | 在内容簇粒度上识别劣质曝光（零点击且曝光超阈值），按 `user_id`、`is_ads`、`scene_type` 聚合总曝光量及三档阈值的劣质曝光量 |
| Step 4 | INSERT OVERWRITE | 将 `user_bad_imp` 与 `user_exp` 通过 `user_id` INNER JOIN，按 `GROUPING SETS ((exp_group_id, scene_type, is_ads), (exp_group_id, scene_type))` 聚合，计算各组汇总指标及劣质率，覆盖写入目标分区 |

### 注意事项

- **single writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 并发冲突风险。
- **分区覆盖写入**：每次执行为 `INSERT OVERWRITE PARTITION (grass_region, local_date)`，同一分区重跑安全，不会产生重复数据。
- **INNER JOIN 过滤**：`user_bad_imp` 与 `user_exp` 以 `user_id` 做 INNER JOIN，仅保留命中实验分组的用户行为数据，未分配实验组的用户将被过滤。
- **`__ALL__` 汇总行**：`GROUPING SETS` 生成全量汇总行时，`is_ads` 由 `coalesce(is_ads, '__ALL__')` 填充，下游使用时需注意去重。
- **劣质曝光阈值语义**：阈值判断发生在内容簇（`item_llm_cluster_id`）粒度，即同一用户对同一内容簇的累计曝光 ≥ 阈值且零点击，则该簇的全部曝光量计入劣质曝光，而非仅超阈值部分。
- **场景覆盖范围**：当前 `scene_type` 仅实际产出 `DD`，`Others` 分类虽在 ETL 中定义但实际过滤条件已限制仅处理 DD 首页数据。

---

*文档生成时间：2026-05-17*