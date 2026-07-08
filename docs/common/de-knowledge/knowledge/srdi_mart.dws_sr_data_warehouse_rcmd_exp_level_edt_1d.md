<!-- ads-workspace-gdoc-sync: gdoc_id=1O-MIyE605Yq_bKM3Ps-2ldqK3nQEEZyfxwMjbscBS_U gdoc_url=https://docs.google.com/document/d/1O-MIyE605Yq_bKM3Ps-2ldqK3nQEEZyfxwMjbscBS_U/edit -->

# srdi_mart.dws_sr_data_warehouse_rcmd_exp_level_edt_1d

**分层**：DWS（数据汇总层）
**主键**：`exp_type` + `source` + `grass_region` + `local_date` + `exp_group_id` + `edt_category` + `edt_min` + `edt_max` + `is_ads` + `feature_detail` + `target_type` + `scenario_tag`
**分区**：`exp_type` / `source` / `grass_region` / `local_date`
**更新频率**：每日（T+1）
**访问频次**：603

---

## 业务描述

本表为推荐（RCMD）域 A/B 实验分析的核心 DWS 宽表，以**实验组（exp_group_id）× EDT（预计达到时间）分级 × 多维度组合**为粒度，汇聚曝光、点击、下单及 GMV 等核心电商指标，支持对推荐算法实验效果的精细化归因分析。

**核心业务场景**：
- 按 A/B 实验组对比各推荐场景（YMAL、购物车推荐、Daily Discover 等）的曝光、点击、转化及 GMV 表现
- 分析 EDT（预计送达时间）对用户点击率、转化率的影响，区分"今日达"、"明日达"、"多日达"、"无 EDT"等层级
- 支持按商品类型（`target_type`）、特征维度（`feature_detail`）、广告/自然流量（`is_ads`）、场景标签（`scenario_tag`）等多维度下钻分析

**适合回答的典型问题**：
- 实验组 A 与对照组 B 在"今日达"商品上的 CTR 和 GMV 差异是多少？
- 各推荐场景在不同 EDT 分级下的曝光 UU 和下单 UU 分别是多少？
- 广告商品与自然推荐商品在不同实验组中的转化率对比如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `exp_type` | string | 实验维度关联类型，固定写入值为 `dim_join`，表示通过维度表关联方式归因 |
| `source` | string | 数据来源标识；`be` 表示后端（Backend）事件数据，`fe` 表示前端（Frontend）事件数据 |
| `grass_region` | string | 站点/大区标识，如 `ID`、`MY`、`BR` 等，用于区分不同国家/地区 |
| `local_date` | date | 数据日期（本地日期），格式 `YYYY-MM-DD`，每日分区字段 |

### 维度：实验与商品维度

| 字段 | 类型 | 说明 |
|------|------|------|
| `exp_group_id` | int | A/B 实验组 ID，来源于实验分组表，标识用户所属的具体实验分桶 |
| `is_ads` | string | 是否为广告商品；`true` 表示广告流量，`false` 表示自然推荐流量，`__ALL__` 表示不区分 |
| `target_type` | string | 推荐目标类型，如 `item`（商品）、`item_mix_feed_card`（混合卡片）；`__ALL__` 表示汇总 |
| `feature_detail` | string | 特征维度明细，用于标识推荐特征组合；`__ALL__` 表示不按该维度拆分的汇总行 |
| `scenario_tag` | string | 推荐场景标签，取值为特定场景标识（如 `DA_You May Also Like`、`DA_Daily Discover`、`dpm reporting object ...` 等）或 `__ALL__`（全场景汇总） |

### 维度：EDT（预计达到时间）分级

| 字段 | 类型 | 说明 |
|------|------|------|
| `edt_category` | string | EDT 分级标签；`a.today`=今日达，`b.tomorrow`=明日达，`c.days`=多日达，`d.no_edt`=无 EDT 信息 |
| `edt_min` | int | EDT 区间最小天数（仅 `edt_category = 'c.days'` 时有效）；其余分级填充 `-999` |
| `edt_max` | int | EDT 区间最大天数（仅 `edt_category = 'c.days'` 时有效）；其余分级填充 `-999` |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_cnt` | bigint | 曝光次数，统计 `operation = 'impression'` 的 `operation_cnt` 之和 |
| `imp_uu` | bigint | 曝光 UU 数，`imp_cnt > 0` 且有效用户的行数加和（每用户-维度组合计 1） |
| `click_cnt` | bigint | 点击次数，统计 `operation = 'click'` 的 `operation_cnt` 之和 |
| `click_uu` | bigint | 点击 UU 数，`click_cnt > 0` 且有效用户的行数加和 |

### 指标：下单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt` | double | 下单件数，统计 `operation = 'order'` 的 `operation_cnt` 之和 |
| `order_uu` | bigint | 下单 UU 数，`order_cnt > 0` 且有效用户的行数加和 |
| `gmv` | double | 下单 GMV，统计 `operation = 'order'` 时的 `place_order_gmv` 之和 |
| `pc2_gmv` | double | PC2 口径 GMV，统计 `operation = 'order'` 时的 `pc2_gmv` 之和，为特定结算口径的 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，避免全量扫描。示例：`WHERE local_date = '2025-05-16'`
- **`grass_region`**：必须指定具体站点，不同站点数据量差异较大，混合查询无业务意义
- **`source`**：必须区分 `be`（后端数据）和 `fe`（前端数据），两者来源不同，**不可混合聚合**，否则指标重复计数
- **`exp_type`**：当前仅有 `dim_join` 值写入，查询时建议显式过滤以保证语义清晰

### 不可直接 SUM 的字段

| 字段 | 原因 |
|------|------|
| `imp_uu`、`click_uu`、`order_uu` | 去重 UU 指标，在实验组-维度粒度下预聚合，跨维度直接 SUM 会导致重复计数 |
| `edt_min`、`edt_max` | 维度属性字段，非累加指标；仅在 `edt_category = 'c.days'` 时具有语义，其余场景值为 `-999` |

### 多维汇总行说明

- ETL 使用 `GROUPING SETS` 生成多粒度汇总行，`is_ads`、`feature_detail`、`target_type`、`scenario_tag` 中出现 `__ALL__` 的行为该维度的汇总行，**与明细行存在包含关系，直接 SUM 所有行会导致重复计数**
- 查询时应明确选定某一维度组合（例如固定 `scenario_tag != '__ALL__'`），避免与汇总行混用

### 时效性说明

- 本表为 `_1d` 日粒度快照表，**每日全量覆写对应分区**（`INSERT OVERWRITE PARTITION`）
- 数据通常在 T+1 日产出，查询时建议使用前一日日期

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dwd_sr_data_warehouse_platform_fe_join_be` | BE 路径（`source='be'`）的事件明细数据，包含用户行为（曝光/点击/下单）及 EDT 数值信息（`features_edt` JSON 字段）、DPM 模块/对象信息 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | FE 路径（`source='fe'`）的事件明细数据，包含用户行为及 EDT 字符串类型（`edt_string_type`）、算法标签、DPM 模块/对象信息 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维度表，提供用户与实验组的映射关系（仅取 `is_assignment_log=1` 且 `is_rcmd_whitelist=1` 的推荐白名单用户） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_platform_fe_join_be (BE)  ──┐
                                                    ├──► [多步骤 Temporary View 处理] ──► exp_sum 实验归因 ──► 目标表 partition(source='be')
dwd_sr_data_warehouse_platform (FE)            ──┘
                                                         ↑
                    dim_sr_data_warehouse_abtest_user_group (用户-实验组映射)
                                                         ↑
                                                    同样写入 partition(source='fe')
```

两条 ETL pipeline（BE/FE）结构完全对称，各自独立运行并写入不同 `source` 分区。

### 关键步骤

**Step 1：构建用户实验组映射（`user_exp`）**
- 从 `dim_sr_data_warehouse_abtest_user_group` 读取指定 `grass_region` 和 `local_date` 的推荐白名单用户，按 `user_id` 聚合为 `exp_group_ids` 数组

**Step 2：读取事件明细并解析 EDT（`dwd_raw`）**
- BE 路径：从 `dwd_sr_data_warehouse_platform_fe_join_be` 读取，通过 `get_json_object` 解析 `features_edt` 获取 `edt_min`/`edt_max` 数值，并组装 DPM 模块/对象字符串及 `algo_tag`
- FE 路径：从 `dwd_sr_data_warehouse_platform` 读取，直接使用 `edt_string_type` 字符串字段，多语言解析 EDT 分级

**Step 3：构建场景标签数组（`dwd_concat_data`）**
- 将 `reporting_module`、`reporting_object`、`algo_tag` 以逗号拼接为 `scenario_tags_str`，再 `split` 为数组 `scenario_tags`

**Step 4：过滤场景标签并计算 EDT 分级（`dwd_filtered`）**
- 使用 `filter()` 保留白名单场景标签（含 DA 系列及 DPM 系列特定场景）
- 依据 EDT 信息映射 `edt_category`（`a.today` / `b.tomorrow` / `c.days` / `d.no_edt`）

**Step 5：用户级预聚合（`base_table`，DISK_ONLY 缓存）**
- 按用户、维度、`edt_category`、`edt_min`/`edt_max` 分组，聚合曝光/点击/下单次数及 GMV；非 `c.days` 分级的 EDT 数值统一置 `-999`

**Step 6：多维度 GROUPING SETS 展开（`dws_cube`）**
- 分三段 UNION ALL 生成多粒度汇总行：
  1. 按 `scenario_tags` 展开后，以 `feature_detail`/`target_type`/`scenario_tag` × `is_ads` 做 GROUPING SETS
  2. 全场景汇总（`__ALL__`）按 `feature_detail`/`target_type` × `is_ads` 做 GROUPING SETS
  3. 跨 `scenario_tags` 展开仅按 `scenario_tag` × `is_ads` 做 GROUPING SETS
- `is_ads`、`feature_detail`、`target_type` 为 NULL 时代表该维度汇总（最终输出替换为 `__ALL__`）

**Step 7：用户级 UU 标记（`dws_uu`）**
- 对每行打标：`imp_uu`、`click_uu`、`order_uu`（值为 0 或 1）

**Step 8：实验归因聚合（`explode_metric_table`）**
- 将各指标打包为 `metrics` 数组，与 `user_exp` 按 `user_id` INNER JOIN
- 调用自定义函数 `exp_sum(exp_group_ids, metrics)` 按实验组展开累加，生成 `exp_metrics` 数组

**Step 9：INSERT OVERWRITE 写目标表**
- 从 `exp_metrics` lateral view explode 展开每个 `exp_group_id` 对应的指标行
- BE 写入 `partition(exp_type='dim_join', source='be', grass_region=..., local_date=...)`
- FE 写入 `partition(exp_type='dim_join', source='fe', grass_region=..., local_date=...)`

### 注意事项

- **Multi-writer 风险**：本表由 BE 和 FE 两个 ETL job 并发写入不同 `source` 分区，若调度配置不当出现同分区并发写入，存在数据覆盖风险，需确保两个 job 写入的 `source` 分区不重叠
- **`__ALL__` 汇总行与明细行共存**：`is_ads`、`feature_detail`、`target_type`、`scenario_tag` 均存在 `__ALL__` 汇总行，下游查询需明确过滤维度层级，避免重复计数
- **UU 指标不可跨 `exp_group_id` 直接 SUM**：`imp_uu`/`click_uu`/`order_uu` 在用户-维度级别已预聚合，跨实验组合并时需重新去重，不可简单累加
- **BE 与 FE 的 EDT 计算逻辑不同**：BE 基于 `edt_min`/`edt_max` 数值分级，FE 基于多语言 `edt_string_type` 字符串正则匹配分级，两者 `edt_category` 含义对齐但计算路径有差异，跨 `source` 对比需注意
- **`exp_sum` 为 UDAF**：实验归因依赖自定义聚合函数，若环境未注册该函数，ETL 将直接报错

---

*文档生成时间：2026-05-17*