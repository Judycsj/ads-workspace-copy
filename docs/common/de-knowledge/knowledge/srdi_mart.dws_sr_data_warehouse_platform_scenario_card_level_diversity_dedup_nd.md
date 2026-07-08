<!-- ads-workspace-gdoc-sync: gdoc_id=1OYWw7-cDRfsDqeqGxNrz_E23C0jBGrw-Q7AbVAP0xLg gdoc_url=https://docs.google.com/document/d/1OYWw7-cDRfsDqeqGxNrz_E23C0jBGrw-Q7AbVAP0xLg/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_card_level_diversity_dedup_nd

**分层**：DWS（数据汇总层）
**主键**：`grass_region` + `local_date` + `num_day` + `scene_type` + `card_type` + `is_ads`
**分区**：`grass_region`（区域）/ `local_date`（统计截止日期）/ `num_day`（滑动窗口天数）
**更新频率**：每日调度，按区域分区覆盖写入（INSERT OVERWRITE）
**引用频次 / 访问频次**：1809

---

## 业务描述

本表用于衡量**搜推数仓平台（SRDI）在不同场景、卡片类型、广告属性维度下的曝光多样性**。核心业务目标是统计用户在最近 N 天（滑动窗口）内看到的 LLM 虚拟品类（`item_llm_cluster_id`）去重数量，以及去重曝光 UV、曝光总次数，供推荐多样性指标的监控与分析使用。

**核心业务场景**：
- Daily Discover（首页每日发现，`scene_type = 'DD'`）多样性分析
- Post Purchase（购后推荐，`scene_type = 'PP'`）多样性分析
- 按卡片类型（商品、视频、混合等）与广告/自然流量拆分的多样性对比

**适合回答的典型问题**：
- 过去 N 天内，某区域在 DD 场景下，自然流量用户平均看到多少个不同 LLM 品类？
- 不同卡片类型（item + mixfeed vs video）的多样性指标走势如何？
- 广告曝光与非广告曝光在品类多样性上有何差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区/市场代码，如 `TW`、`ID`、`SG` 等；每次写入覆盖当前分区 |
| `local_date` | date | 统计截止日期（本地日期），即滑动窗口的最后一天 |
| `num_day` | int | 滑动窗口天数，值为 `date_offset + 1`，表示统计最近 N 天的数据 |

### 维度：场景与卡片分类

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_type` | string | 推荐场景类型：`DD`（首页每日发现）、`PP`（购后推荐）、`Others`（其余场景，当前过滤后实际仅含前两者） |
| `card_type` | string | 卡片类型聚合维度，枚举值见下方说明：`item + mixfeed`（商品及混合 Feed 卡片）、`video`（视频卡片）、`item + mixfeed + video`（商品/混合/视频去重合并）、`item + mixfeed + video - no dedup`（视频 cluster 加前缀 `v#` 以避免跨类型 cluster 合并，不去重）、`others`（其余类型）、`__ALL__`（所有类型汇总） |
| `is_ads` | string | 是否广告流量：`'true'`（广告曝光）、`'false'`（自然曝光）、`'__ALL__'`（广告+自然汇总，由 CUBE 产生） |

### 指标：曝光与多样性度量

| 字段 | 类型 | 说明 |
|---|---|---|
| `dedup_imp_cnt` | bigint | 最近 N 天内，该维度组合下的（request 级别）去重曝光总次数；同一 user × request × item 仅计一次 |
| `imp_uu` | bigint | 最近 N 天内，`dedup_imp_cnt > 0` 的有效曝光用户数（去重 UV） |
| `imp_llm_cat_cnt` | bigint | 最近 N 天内，所有用户在该维度组合下看到的 LLM 虚拟品类去重数之和（各用户 per-user 品类去重数的累加）；反映品类多样性总量 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则全表扫描所有区域分区，代价极高。
- **`local_date`**：必须指定，否则扫描所有历史分区。建议结合业务需求指定精确日期或日期范围。
- **`num_day`**：建议同时指定，因为同一 `local_date` 下可能存在多个 `num_day` 分区（如 7 天窗口、14 天窗口等）。未指定时将返回所有窗口数据，导致重复计算。

```sql
-- 推荐写法示例
WHERE grass_region = 'ID'
  AND local_date = '2025-05-10'
  AND num_day = 7
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_llm_cat_cnt` | 该字段是各用户 per-user 品类去重数的加总，跨维度聚合（如跨 `card_type`）后无法直接相加；不同 `card_type` 行之间存在用户重叠，直接 SUM 会重复计算 |
| `imp_uu` | 不同 `card_type`、`is_ads` 组合间存在用户重叠，跨行 SUM 会高估 UV |
| `dedup_imp_cnt` | 本表中已存在 `card_type = '__ALL__'` 和 `is_ads = '__ALL__'` 的汇总行，对非汇总行直接 SUM 再与汇总行对比将导致口径错乱 |

> ⚠️ 由于表中同时存在 `is_ads = '__ALL__'`（CUBE 汇总行）与明细行，查询时必须明确过滤 `is_ads`，避免同一指标被重复统计。

### 时效性说明

- 表名后缀 `_nd` 表示**最近 N 天滑动窗口**聚合表，`num_day` 决定窗口长度，并非单日快照。
- 数据每日 T+1 更新，当日数据通常于次日调度完成后可见。
- ETL 使用 INSERT OVERWRITE 按分区覆盖写入，历史分区不会自动修正，如需重跑历史需手动触发回刷。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 主事实表，提供用户-请求-商品粒度的曝光明细，过滤 `operation = 'impression'`，限定最近 N 天日期范围，作为聚合基础 |
| `mpi_data_mart.adm_sr_item_llm_virtual_category_tags_reg_v2_df` | 商品 LLM 虚拟品类标签表，按区域和 cluster 版本取最新分区，用于将 `item_id` 映射到 `item_llm_cluster_id` |

---

## ETL 逻辑摘要

### 数据流

```
llm_cluster_version_config（版本配置）
        │
        ▼
item_llm_cluster（item_id → llm_cluster_id 映射）
        │
srdi_mart.dwd_sr_data_warehouse_platform
        │
        ▼
user_item_raw（用户-请求-商品去重曝光，过滤 DD/PP 场景）
        │
        ▼（LEFT JOIN item_llm_cluster）
user_item_with_cluster（附加 llm_cluster_id）
        │
        ▼
user_item_processed（标准化 card_type）
        │
        ▼
user_cluster_agg（用户×cluster 级别多维聚合，UNION ALL 展开 card_type 组合）
        │
        ▼
cubed_data（用户级 CUBE(is_ads)，计算 per-user 品类去重数与曝光次数）
        │
        ▼
INSERT OVERWRITE → dws_sr_data_warehouse_platform_scenario_card_level_diversity_dedup_nd
```

### 关键步骤

1. **Statement 1 — `llm_cluster_version_config`**：静态配置视图，定义各区域对应的 LLM cluster 版本号（如 `ID → v3.0`、`TW → v2.4`）。

2. **Statement 2 — `item_llm_cluster`**：从 `mpi_data_mart.adm_sr_item_llm_virtual_category_tags_reg_v2_df` 按区域和版本取最新分区，构建 `item_id → item_llm_cluster_id` 映射。

3. **Statement 3 — `user_item_raw`**：从 DWD 事实表读取最近 N 天（`local_date` 前 `date_offset` 天到 `local_date`）的曝光明细；过滤 `operation = 'impression'`、有效 user/item，仅保留 DD 和 PP 场景；以 `(user_id, is_ads, target_type, scene_type, request_id, item_id)` 为粒度去重，赋 `dedup_imp_cnt = 1`。

4. **Statement 4 — `user_item_with_cluster`**：LEFT JOIN 将 `item_llm_cluster_id` 附加到 `user_item_raw`，无法匹配商品的 cluster_id 为 NULL。

5. **Statement 5 — `user_item_processed`**：将原始 `target_type` 归并为标准 `card_type`：
   - `item` / `item_mix_feed_card` → `item + mixfeed`
   - `video` → `video`
   - 空值 → `null`
   - 其余 → `others`

6. **Statement 6 — `user_cluster_agg`**：UNION ALL 展开四种 `card_type` 计算口径：
   - `__ALL__`：所有卡片类型合并（cluster 不区分卡片类型）
   - `item + mixfeed` / `video`：单类型明细
   - `item + mixfeed + video`：两类合并（cluster 去重，不区分卡片）
   - `item + mixfeed + video - no dedup`：视频 cluster 加 `v#` 前缀，避免与商品 cluster 合并，仅限 DD/PP 场景

7. **Statement 7 — `cubed_data`**：对 `user_cluster_agg` 按 `(user_id, CUBE(is_ads), card_type, scene_type)` 聚合，计算：
   - `dedup_imp_cnt`：用户在该维度下的曝光次数
   - `imp_llm_cat_count_per_uu`：用户看到的 LLM 品类去重数（`COUNT DISTINCT item_llm_cluster_id WHERE dedup_imp_cnt > 0`）
   - `CUBE(is_ads)` 自动生成 `is_ads` 汇总行（值为 NULL，后续 COALESCE 为 `__ALL__`）

8. **Statement 8 — INSERT OVERWRITE**：对 `cubed_data` 按 `(scene_type, card_type, is_ads)` 聚合，SUM 各用户指标，写入目标表；`num_day = date_offset + 1` 作为动态分区值。

### 注意事项

- **单 ETL 写入，无 multi-writer 风险**：本表仅由一个 SQL 文件写入，不存在多文件并发写入同一分区的竞争问题。
- **动态分区 `num_day`**：`num_day` 由 `${date_offset} + 1` 在运行时决定，调度参数变更会写入不同 `num_day` 分区，历史分区不会被自动清理。
- **NULL cluster 处理**：无法匹配 LLM 品类的商品其 `item_llm_cluster_id` 为 NULL，在 `imp_llm_cat_count_per_uu` 的 COUNT DISTINCT 中 NULL 不计入，不影响多样性计数。
- **`is_ads = '__ALL__'` 汇总行**：CUBE 展开产生的汇总行已包含在表中，查询时应显式过滤 `is_ads` 避免与明细行重复叠加。
- **LLM cluster 版本依赖**：各区域使用不同版本的 cluster 配置，版本变更时 cluster 含义可能发生变化，跨版本时间段的多样性指标需谨慎纵向比较。

---

*文档生成时间：2026-05-17*