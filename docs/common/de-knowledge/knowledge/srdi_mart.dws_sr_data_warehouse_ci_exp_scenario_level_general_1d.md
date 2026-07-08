<!-- ads-workspace-gdoc-sync: gdoc_id=1qobzkDGCSsrLSN3EsRZxR1uqKq1-W4d5Wd4DdaYn10A gdoc_url=https://docs.google.com/document/d/1qobzkDGCSsrLSN3EsRZxR1uqKq1-W4d5Wd4DdaYn10A/edit -->

# srdi_mart.dws_sr_data_warehouse_ci_exp_scenario_level_general_1d

**分层**：DWS（数据汇总层）
**主键**：`content` + `grass_region` + `local_date` + `exp_group_id` + `scenario_tag`
**分区**：`content`（内容类型）/ `grass_region`（区域）/ `local_date`（本地日期）
**更新频率**：每日更新（T+1）
**引用频次 / 访问频次**：46

---

## 业务描述

本表用于支撑**搜推（Search & Recommendation）数据仓库**中的 **A/B 实验（CI Experiment）场景级通用指标**汇总，以天为粒度，按实验组、展示场景、内容类型及区域维度汇总卡片曝光与点击数据。

**核心业务场景**：
- 评估直播（livestream）和短视频（video）两大内容域在不同 A/B 实验组下的推荐效果；
- 按场景标签（`scenario_tag`）拆分不同推荐入口（如首页每日发现、首页视频卡等）的流量表现；
- 提供实验组粒度的去重用户数（UU），用于准确衡量实验覆盖与触达。

**适合回答的典型问题**：
- 某实验组在特定区域、特定日期的卡片曝光量和点击量是多少？
- 直播 vs 短视频内容域在同一实验组下的点击率差异？
- 各场景（`video_dd_all`、`homepage_video_all`、`another`）的曝光 UU 和点击 UU 分别是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `content` | string | 内容类型分区，当前取值为 `livestream`（直播）或 `video`（短视频），由两个独立 ETL 文件分别写入 |
| `grass_region` | string | 国家/地区分区，如 `SG`、`MY`、`TH` 等，与 A/B 实验用户分组表的 `grass_region` 对齐 |
| `local_date` | date | 本地日期分区，对应用户行为发生的本地化日期 |

### 维度：实验与场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验组 ID，对应实验分组表中的 `experiment_group_id`（直播域）或 `abtest_group`（视频域），强转为 INT |
| `scenario_tag` | string | 场景标签，标识用户行为发生的推荐入口。取值：`video_dd_all`（首页每日发现视频）、`homepage_video_all`（首页视频卡）、`another`（其他场景） |

### 指标：卡片曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `card_imp_cnt` | bigint | 卡片曝光次数，由实验组内所有用户的 `imp_cnt` 累加得到，可按维度直接 SUM |
| `card_imp_uu` | bigint | 卡片曝光去重用户数，统计曝光次数 >0 的独立用户数（`COUNT(DISTINCT IF(imp_cnt>0, user_id, NULL))`），**不可直接 SUM** |
| `card_click_cnt` | bigint | 卡片点击次数，由实验组内所有用户的 `click_cnt` 累加得到，可按维度直接 SUM |
| `card_click_uu` | bigint | 卡片点击去重用户数，统计点击次数 >0 的独立用户数（`COUNT(DISTINCT IF(click_cnt>0, user_id, NULL))`），**不可直接 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，否则触发全分区扫描，严重影响性能。建议使用精确日期，如 `local_date = '2025-01-01'`。
- **`content`**：建议明确指定（`'livestream'` 或 `'video'`），避免跨内容域混合汇总造成语义混乱。
- **`grass_region`**：建议指定，不同区域的实验组 ID 相互独立，混合查询无业务意义。

示例：
```sql
SELECT scenario_tag, exp_group_id, card_imp_cnt, card_click_cnt
FROM srdi_mart.dws_sr_data_warehouse_ci_exp_scenario_level_general_1d
WHERE local_date = '2025-01-01'
  AND content = 'video'
  AND grass_region = 'SG';
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `card_imp_uu` | 去重用户数，跨实验组或跨场景 SUM 会导致用户重复计算 |
| `card_click_uu` | 同上，跨维度聚合无意义，需回溯明细层重新去重 |

### 时效性说明

- 本表为 **每日全量覆写**（`INSERT OVERWRITE`）表，每次写入会覆盖对应 `(content, grass_region, local_date)` 分区的数据。
- 数据通常在 **T+1** 产出，查询当天数据时需确认分区已就绪。
- 表名后缀 `_1d` 表示统计粒度为单日，不含滚动窗口或累计指标。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `livestream.ls_mart_dim_abtest_user_group` | 直播域 A/B 实验用户分组信息，提供 `user_id`、`experiment_group_id`、`grass_region`（仅 `content=livestream` 分区使用） |
| `video.video_mart_dim_abtest_user_group_di` | 短视频域 A/B 实验用户分组信息，提供 `user_id`、`abtest_group`、`grass_region`，过滤 `scene_key='video_union'` 且已分配日志（仅 `content=video` 分区使用） |
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 平台用户-商品行为明细中间层，提供用户粒度的曝光次数（`imp_cnt`）、点击次数（`click_cnt`）及场景特征字段（`feature_detail`、`source1_feature_detail`、`source2_feature_detail`），两个分区均使用 |

---

## ETL 逻辑摘要

### 数据流

```
livestream.ls_mart_dim_abtest_user_group          ──┐
                                                     ├─► (LEFT JOIN on user_id & grass_region) ─► 聚合 ─► content='livestream' 分区
srdi_mart.dwm_sr_data_warehouse_platform_user_item ─┤
                                                     ├─► (LEFT JOIN on user_id & grass_region) ─► 聚合 ─► content='video' 分区
video.video_mart_dim_abtest_user_group_di          ──┘
```

两个 ETL 文件逻辑对称，分别独立写入 `content='livestream'` 和 `content='video'` 分区。

### 关键步骤

以下步骤在两个 ETL 文件中结构完全一致，仅 A/B 实验分组来源表不同：

1. **`abtest_table`（CTE）**：从对应域的实验分组表中读取当日、指定区域的用户实验组信息，过滤 `tz_type='local'`；视频域额外过滤 `scene_key='video_union'` 且 `is_assigment_log=1`。

2. **`civ_pre_table`（CTE）**：从 `srdi_mart.dwm_sr_data_warehouse_platform_user_item` 读取用户行为明细，按 `(user_id, feature_detail, source1_feature_detail, source2_feature_detail, grass_region)` 分组聚合，同时通过 `CASE WHEN` 将场景特征映射为 `scenario_tag`：
   - `feature_detail` 系列字段中包含 `'home-daily_discover-video'` → `video_dd_all`
   - `feature_detail` 系列字段中包含 `'home-shopee_video-video_card'` → `homepage_video_all`
   - 其他 → `another`

3. **`civ_table`（CTE）**：对 `civ_pre_table` 按 `(user_id, scenario_tag, grass_region)` 二次聚合，合并同一用户在同一场景下的曝光和点击。

4. **`joined_data`（CTE）**：以 `abtest_table` 为左表，LEFT JOIN `civ_table`（关联条件：`user_id` 和 `grass_region`），保留所有实验组用户，行为数据不存在时为 NULL。

5. **`final_data`（CTE）**：按 `(scenario_tag, abtest_group)` 聚合，计算：
   - `card_imp_cnt`：`SUM(imp_cnt)`
   - `card_click_cnt`：`SUM(click_cnt)`
   - `card_imp_uu`：`COUNT(DISTINCT IF(imp_cnt > 0, user_id, NULL))`
   - `card_click_uu`：`COUNT(DISTINCT IF(click_cnt > 0, user_id, NULL))`

6. **`INSERT OVERWRITE`**：将 `final_data` 写入目标表对应分区（`content` 由各文件静态指定）。

### 注意事项

- **Multi-writer 风险**：本表由两个独立 ETL Job 并发写入不同 `content` 分区，若调度时序不当或分区参数配置错误，存在分区互相覆盖的风险，需确保两个 Job 写入的 `content` 值严格不同。
- **LEFT JOIN 语义**：以实验组用户为基准做 LEFT JOIN，未发生行为的实验组用户会保留在 `joined_data` 中（行为字段为 NULL），但在 `final_data` 聚合时 `SUM(NULL)=NULL`，`COUNT(DISTINCT IF(NULL>0,...))` 不计入，因此 `card_imp_uu`/`card_click_uu` 仅统计有实际行为的用户。
- **`scenario_tag` 优先级**：`CASE WHEN` 采用顺序匹配，`video_dd_all` 优先于 `homepage_video_all`，两个场景特征同时命中时取前者。
- **分区覆写**：每次执行均为 `INSERT OVERWRITE`，目标分区数据将被完全替换，历史数据不累积。
- **`exp_uu` 字段**：ETL SQL 中 `count(DISTINCT user_id) AS exp_uu` 被注释掉，该指标未输出到目标表，如需实验总触达 UU 须另行计算。

---

*文档生成时间：2026-05-17*