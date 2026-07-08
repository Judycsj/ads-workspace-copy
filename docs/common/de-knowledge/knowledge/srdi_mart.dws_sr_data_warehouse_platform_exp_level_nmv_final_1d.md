<!-- ads-workspace-gdoc-sync: gdoc_id=1YY44EY1bLqJJRbdtXMnTnZ5pRNAGcj6ucAIt58ya4rs gdoc_url=https://docs.google.com/document/d/1YY44EY1bLqJJRbdtXMnTnZ5pRNAGcj6ucAIt58ya4rs/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_nmv_final_1d

**分层：** DWS（数据汇总层）
**主键：** `exp_group_id` + `platform` + `is_ads` + `feature_detail` + `scenario_tag` + `target_type` + `exp_type` + `grass_region` + `local_date`
**分区：** `exp_type` / `grass_region` / `local_date`（三级分区）
**更新频率：** 每日（T-31 滚动回刷，按天全量覆盖写入）
**引用频次 / 访问频次：** 50

---

## 业务描述

本表是搜推（SR）数仓平台在**实验分组（A/B Test）维度**下的每日 NMV 汇总宽表，服务于搜推各业务线的**实验效果归因与商业价值评估**。

核心业务场景：
- 按实验分组（`exp_group_id`）、平台（`platform`）、是否广告（`is_ads`）、展示入口（`feature_detail`）、场景标签（`scenario_tag`）、目标类型（`target_type`）等多维度切片，统计各 A/B 实验组的净订单量、下单 UU 数及 NMV（Net Merchandise Value）。
- 覆盖搜索、推荐、首页、私域等多条业务线，支持对 DPM（数据产品矩阵）中各 reporting business line / module / object 归因链路的实验效果拆解。
- 通过 `grouping sets` 预聚合多维组合（含汇总行 `__ALL__`），减少下游查询计算量。

适合回答的问题：
- 某实验组在特定平台/入口/场景下相比对照组的 NMV 差异是多少？
- 搜索/推荐各模块在 A/B 实验中的下单 UU 数和净订单量表现如何？
- 某 feature 入口在广告与非广告流量下的实验效果对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_type` | string | 实验数据写入类型，当前 ETL 固定写入分区值为 `'dim_join'`，代表维度关联模式 |
| `grass_region` | string | 业务大区（如 MY、TH、PH 等），对应 Shopee 各本地化市场 |
| `local_date` | date | 业务日期，即数据所属的本地时区日期，格式 `yyyy-MM-dd` |

### 维度：实验与业务维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验分组 ID，来源于实验平台用户分组表，用于区分实验组与对照组 |
| `platform` | string | 用户访问平台（如 Android、iOS、Web 等）；`__ALL__` 表示全平台汇总 |
| `is_ads` | string | 是否广告流量（`true`/`false`）；`__ALL__` 表示广告与非广告合并汇总 |
| `feature_detail` | string | 展示入口标识，格式通常为 `页面-模块-目标类型`；`__ALL__` 表示全入口汇总 |
| `scenario_tag` | string | 场景标签，来源于 DPM 维度体系（如 business line、module、reporting object、mapping group、algo_tag、page type 等），经过滤保留 DA_ 前缀或指定场景；`__ALL__` 表示全场景汇总 |
| `target_type` | string | 目标类型，从 `feature_detail` 中解析（取第 3 段，不存在则取第 2 段）；`__ALL__` 表示全类型汇总 |

### 指标：实验组交易核心指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `net_order_uu` | bigint | 净下单 UU 数（去重用户数），计算规则：`net_order_cnt > 0 AND user_id > 0` 时计为 1，再经 `exp_sum` UDAF 按实验分组聚合 |
| `net_order_cnt` | double | 净订单数（退款后净值），经 `exp_sum` UDAF 按实验分组聚合 |
| `nmv` | double | 净商品交易额（Net Merchandise Value），经 `exp_sum` UDAF 按实验分组聚合 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，否则全分区扫描，严重影响性能。示例：`WHERE local_date = '2024-01-01'`。
- **`grass_region`**：必须指定目标大区，各大区数据独立存储于不同分区。
- **`exp_type`**：当前唯一值为 `'dim_join'`，建议显式过滤以利用分区裁剪。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `net_order_uu` | 去重用户数，已通过 `exp_sum` UDAF 在实验分组维度预聚合，跨 `exp_group_id` 或跨 `scenario_tag` 直接 SUM 会导致重复计数 |
| `net_order_cnt` / `nmv` | 本表存在 `grouping sets` 预聚合的汇总行（`__ALL__`），若未过滤 `__ALL__` 行直接 SUM 将产生多重计数 |

### 汇总行说明

- `feature_detail = '__ALL__'`、`scenario_tag = '__ALL__'`、`platform = '__ALL__'`、`is_ads = '__ALL__'`、`target_type = '__ALL__'` 均为预聚合的全维度汇总行，查询明细时需过滤排除。
- 多 source（source1/source2）的 feature_detail 已合并 UNION 写入，同一笔交易在不同归因入口下可能被计入多次，跨 `feature_detail` 聚合时需注意去重。

### 时效性说明

- 本表为 **T+1 日刷新**，每日覆盖写入（INSERT OVERWRITE），当天数据通常于次日产出。
- ETL 注释表明该表与同逻辑的 `dws_sr_data_warehouse_platform_exp_level_nmv_1d` 相同，但专门用于 **T-31 天**的每日回刷（即对过去 31 天历史数据做滚动重刷）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维度表，提供用户与实验分组的映射关系（`user_id` → `exp_group_ids`），过滤赋值日志有效用户及推荐白名单用户 |
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 平台级 NMV 明细事实表，提供用户级订单数（`net_order_cnt`）、NMV，以及多级 DPM 维度标签（feature_detail、reporting_business_line、reporting_module、reporting_object、feature_group、algo_tag 等） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──┐
                                           ├──► metric_table（exp_sum UDAF聚合）
dwd_sr_data_warehouse_platform_nmv ──►      │
  └─► 维度标签构建 ──► 场景过滤 ──►          │
      grouping sets 预聚合 ──► UU标记 ──────┘
                                           │
                                           ▼
                              explode_metric_table
                                           │
                                           ▼
            dws_sr_data_warehouse_platform_exp_level_nmv_final_1d
                       (PARTITION: exp_type='dim_join', grass_region, local_date)
```

### 关键步骤

1. **`user_exp`（临时视图）**：从实验分组维度表按 `grass_region`、`local_date` 过滤，保留有效赋值日志且在推荐白名单中的用户，按 `user_id` 收集所属实验分组列表 `exp_group_ids`。

2. **`dwd_raw`（临时视图）**：从 NMV 明细表读取当日当区数据，对 DPM 各层级字段（business_line、module、reporting_object、feature_group、algo_tag）拼接为带标识前缀的标准化标签字符串，同时处理 source1/source2 两级归因链路字段，并从 `feature_detail` 解析 `mapped_page_type`。

3. **`concat_data_raw` / `concat_data`（临时视图）**：将各维度标签用逗号拼接为字符串，再 `split` 为数组，形成 `scenario_tags`（当前入口）、`source1_scenario_tags`、`source2_scenario_tags` 三路场景标签数组。

4. **`base_table`（临时视图）**：对三路 `scenario_tags` 数组执行 `FILTER`，仅保留名称含 `DA_` 前缀或属于指定白名单场景（全局搜索、你可能喜欢、购后推荐、每日发现、私域等）的标签，过滤无关场景噪音。

5. **`raw_data`（临时视图）**：将当前入口、source1 入口、source2 入口三路数据分别 `GROUP BY` 后 `UNION ALL`，同时去重重叠入口（source1 ≠ feature_detail，source2 ≠ source1 且 ≠ feature_detail），实现多归因链路展开。

6. **`dws_all_tag` / `dws_tag`（临时视图）**：生成 `feature_detail='__ALL__'` 的全汇总行，`dws_all_tag` 用于整体汇总，`dws_tag` 用于按 `union_scenario_tags`（三路标签合并去重）展开的场景汇总。

7. **`filter_tag_data`（临时视图）**：从 `feature_detail` 中解析 `target_type`（取 `-` 分隔第 3 段，不存在取第 2 段）。

8. **`cube_table`（临时视图）**：通过 `GROUPING SETS` 对 `feature_detail`、`is_ads`、`platform`、`target_type`、`user_id`、`scenario_tag` 做多维预聚合（8 种维度组合），同时 UNION ALL `dws_all_tag` 和 `dws_tag` 的汇总行，生成含汇总维度的完整 Cube 数据。

9. **`uu_data`（临时视图）**：在 cube_table 基础上打标 `net_order_uu`（`net_order_cnt > 0 AND user_id > 0` 时为 1，否则为 0）。

10. **`map_data`（临时视图）**：将三个指标（`net_order_uu`、`net_order_cnt`、`nmv`）打包为数组 `metrics`，为 `exp_sum` UDAF 调用做准备。

11. **`metric_table`（临时视图）**：与实验分组视图 `user_exp` 做 `INNER JOIN`（user_id 关联），调用自定义 UDAF `exp_sum` 按实验分组对 metrics 进行向量聚合，输出各维度组合下各实验组的指标向量。

12. **`explode_metric_table`（临时视图）**：通过 `LATERAL VIEW EXPLODE` 将 `exp_metrics` 数组展开，每行对应一个 `exp_group_id`，解包各指标字段。

13. **`INSERT OVERWRITE`（目标写入）**：按 `PARTITION (exp_type='dim_join', grass_region, local_date)` 覆盖写入目标表，输出最终实验分组级 NMV 汇总数据。

### 注意事项

- **单 Writer，无 multi-writer 风险**：本表仅由一个 ETL 文件写入，不存在多写竞争问题。
- **分区覆盖写入**：采用 `INSERT OVERWRITE PARTITION` 模式，重跑同一分区时会全量替换，需确保上游表当日数据已就绪再触发调度。
- **参数化模板**：SQL 中 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}` 为运行时参数，需由调度框架正确注入，`grass_region_without_quote` 用于临时视图命名（避免引号冲突），`grass_region` 带引号用于 WHERE 条件过滤。
- **INNER JOIN 导致的数据过滤**：`metric_table` 步骤使用 INNER JOIN 关联实验用户，不在实验分组中的用户（未命中白名单或未被赋值）的 NMV 数据将被排除，本表指标仅代表**实验覆盖用户**的贡献，不等于全量平台 NMV。
- **`exp_sum` UDAF 依赖**：该自定义聚合函数负责将用户级指标按实验分组向量累加，下游使用指标时需了解其已完成分组内聚合，不得在分组维度之外再次 SUM `net_order_uu`。
- **多归因重叠**：同一笔订单可能同时归因于 `feature_detail`、`source1_feature_detail`、`source2_feature_detail` 三个入口，跨 `feature_detail` 聚合时存在重复计算风险。

---

*文档生成时间：2026-05-17*