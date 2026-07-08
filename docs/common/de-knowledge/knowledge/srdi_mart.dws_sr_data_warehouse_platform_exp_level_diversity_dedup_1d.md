<!-- ads-workspace-gdoc-sync: gdoc_id=1cshlktufmgISEU74QRax8VG5ckPJVkc11FB-a9cdagc gdoc_url=https://docs.google.com/document/d/1cshlktufmgISEU74QRax8VG5ckPJVkc11FB-a9cdagc/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_diversity_dedup_1d

**分层**: DWS（数据汇总层）
**主键**: `grass_region` + `local_date` + `scene_type` + `card_type` + `exp_group_id`
**分区**: `grass_region`（地区）, `local_date`（日期）
**更新频率**: 每日一次（T+1）
**访问频次**: 45 次

---

## 业务描述

本表用于衡量搜推平台曝光维度下**内容多样性**的实验分组指标，服务于 A/B 实验效果分析。

核心业务场景：
- **实验多样性评估**：按实验分组（`exp_group_id`）统计各组用户曝光的 LLM 虚拟类目数量，衡量推荐结果在语义品类层面的多样性表现。
- **场景与卡片类型分析**：支持按 `scene_type`（DD 首页日发现、PP 购后推荐）和 `card_type`（普通商品、有机商品、视频、混合）拆分对比。
- **用户级去重曝光汇总**：以 user × request 粒度去重后汇总，避免同一 request 多次计数带来的统计偏差。

适合回答的典型问题：
- 实验组与对照组相比，用户曝光覆盖的 LLM 类目数量是否更多？
- 在日发现场景下，各实验组的有效曝光用户数（UU）和人均曝光类目数如何？
- 不同卡片类型（商品 / 视频）在各实验组的多样性指标差异如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区，如 TW、TH、SG、MY、PH、VN、BR、ID 等 |
| `local_date` | date | 数据日期（本地时间），格式 yyyy-MM-dd |

### 维度：场景与实验分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_type` | string | 曝光场景类型。`DD`：首页日发现（Daily Discover / Homepage）；`PP`：购后推荐（post purchase / Rcmd）；`Others`：其他场景 |
| `card_type` | string | 卡片聚合类型。`Aggregated Organic Item`：自然排序商品卡；`Aggregated Item`：全量商品卡（含广告）；`Aggregated Video`：视频卡；`Aggregated Item + Video`：商品与视频合并统计（视频类目 ID 加 `v#` 前缀区分） |
| `exp_group_id` | int | A/B 实验分组 ID，来自实验用户分组表，仅保留指定 scene_id 下有效的分组 |

### 指标：曝光与多样性

| 字段 | 类型 | 说明 |
|---|---|---|
| `dedup_imp_cnt` | bigint | 去重曝光次数。以 user × request_id × item 粒度去重后，按分组维度汇总的曝光总量 |
| `imp_uu` | bigint | 有效曝光用户数（UU）。统计在该分组维度下 `dedup_imp_cnt > 0` 的用户数，即有实际曝光记录的独立用户数 |
| `imp_llm_cat_cnt` | bigint | 各用户曝光的 LLM 虚拟类目数之和（人均类目数的累加）。单用户层面统计其曝光覆盖的不同 `item_llm_cluster_id` 数量后再加总，**不可直接用于计算全局平均值，需除以 `imp_uu`** |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**：查询时务必同时过滤 `grass_region` 和 `local_date`，避免全表扫描。
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-05-16'
  ```
- `exp_group_id` 来自特定实验场景（scene_id 范围：142、373、132、368、1718、1605、2065），跨实验对比时需确认 `exp_group_id` 归属。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_llm_cat_cnt` | 为用户粒度人均曝光类目数的加总，跨行 SUM 后需除以对应 `imp_uu` 才能得到正确的人均值；不可直接对多个 `card_type` 或 `scene_type` 行求和后再计算均值 |
| `imp_uu` | 为预聚合的去重 UU，跨不同 `card_type` 行加总可能导致重复计数（同一用户可能同时出现在多个 `card_type` 分组中） |

### 时效性说明

- 本表为 **日粒度快照表**（`_1d` 后缀），每日覆盖写入，查询时指定具体 `local_date` 获取当日数据。
- 不包含滚动窗口或累计值，如需 N 日趋势需手动跨多个 `local_date` 聚合。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 原始曝光明细，提取 impression 事件、item/video 卡片的 user × request × item 记录 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 实验用户分组，关联 `exp_group_id`，过滤指定 scene_id 下的有效分配日志 |
| `mpi_data_mart.adm_sr_item_llm_virtual_category_tags_reg_v2_df` | 商品 LLM 虚拟类目标签，提供 item → `item_llm_cluster_id` 的映射，按地区选取对应版本（如 ID 用 v3.0，TW 用 v2.4） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_platform（曝光明细）
    ↓ 过滤 impression + 指定场景 + user/item 有效
dim_sr_data_warehouse_abtest_user_group（实验分组）
    ↓ inner join 保留在实验中的用户
adm_sr_item_llm_virtual_category_tags_reg_v2_df（LLM 类目）
    ↓ left join 关联类目 ID
    ↓ 按 card_type × scene_type 四路 UNION ALL 聚合
    ↓ 用户粒度汇总 dedup_imp_cnt 与 imp_llm_cat_count
    ↓ 分组维度（exp_group_id × card_type × scene_type）最终聚合
目标表：dws_sr_data_warehouse_platform_exp_level_diversity_dedup_1d
```

### 关键步骤

1. **`user_exp`（临时视图）**：从实验分组维表中提取当日指定 scene_id 下已分配日志的用户与实验分组映射。

2. **`llm_cluster_version_config`（临时视图）**：硬编码各地区对应的 LLM 类目版本号（如 ID→v3.0，TW→v2.4），用于后续查询对应版本的类目数据。

3. **`item_llm_cluster`（临时视图）**：从 LLM 虚拟类目表中取当前地区、对应版本、最新分区的商品类目映射（`item_id` → `item_llm_cluster_id`）。

4. **`user_item_raw`（临时视图）**：从曝光明细表提取当日有效 impression 记录，按 user × is_ads × target_type × scene_type × request_id × item_id 去重，标记 `scene_type`（DD / PP）和 `target_type`（item / item_mix_feed_card / video）。

5. **`user_item_with_cluster`（临时视图）**：将曝光记录与 LLM 类目 left join，关联 `item_llm_cluster_id`。

6. **`user_cluster_agg`（临时视图）**：按四种 `card_type` 口径做 UNION ALL 聚合：
   - `Aggregated Organic Item`：自然排序商品（非广告，target_type 含 item/item_mix_feed_card）
   - `Aggregated Item`：全量商品（含广告）
   - `Aggregated Video`：视频卡（仅 DD/PP 场景）
   - `Aggregated Item + Video`：商品与视频合并，视频类目 ID 加 `v#` 前缀以示区别

7. **`user_cluster_exp`（临时视图）**：将上述聚合结果与实验分组 inner join，仅保留在实验中的用户记录。

8. **`cubed_data`（临时视图）**：在 user × exp_group_id × card_type × scene_type 粒度上，汇总 `dedup_imp_cnt` 并统计每用户覆盖的不同 LLM 类目数（`imp_llm_cat_count_per_uu`）。

9. **INSERT OVERWRITE（最终写入）**：按 `grass_region`、`local_date` 分区覆盖写入目标表，将 user 粒度的 cubed_data 进一步聚合至 scene_type × card_type × exp_group_id 维度，输出 `dedup_imp_cnt`、`imp_uu`、`imp_llm_cat_cnt` 三个指标。

### 注意事项

- **单文件写入**：本表仅由一个 ETL 文件写入，无 multi-writer 风险。
- **分区覆盖写入**：使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)`，同一分区重跑时会完整覆盖，补数时需注意避免误覆盖其他地区分区。
- **LLM 类目版本硬编码**：各地区对应的 `cluster_version` 在 SQL 中以静态 UNION ALL 方式配置，新增地区或版本升级时需同步更新 ETL 逻辑。
- **部分地区无实际数据**：MX、CL、CO、AR、KH、MM、LA 当前标注为无实际数据，查询这些地区分区时结果可能为空或数据量极少。
- **`item_llm_cluster_id` 为 NULL 的情况**：left join 关联类目时，若 item 未命中 LLM 类目表，`item_llm_cluster_id` 为 NULL；统计 `imp_llm_cat_cnt` 时 NULL 值不计入 `count(distinct)`，不影响有效类目数统计。
- **scene_type 过滤**：`Others` 场景仅出现在 `Aggregated Organic Item` 和 `Aggregated Item` 口径中，视频相关口径（`Aggregated Video`、`Aggregated Item + Video`）仅包含 DD 和 PP 场景。

---

*文档生成时间：2026-05-17*