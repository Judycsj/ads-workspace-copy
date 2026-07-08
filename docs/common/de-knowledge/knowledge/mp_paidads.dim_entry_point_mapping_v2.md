<!-- ads-workspace-gdoc-sync: gdoc_id=1Gqfe2Cwpgdc2wmrWCEjHyNd8dcjy69aBA98Vf-3yMW4 gdoc_url=https://docs.google.com/document/d/1Gqfe2Cwpgdc2wmrWCEjHyNd8dcjy69aBA98Vf-3yMW4/edit -->

# mp_paidads.dim_entry_point_mapping_v2

**分层**：DIM（维度层）
**主键**：`entry_point`（流量入口 ID）
**分区**：无分区字段
**更新频率**：按需手工维护（Google Sheets 维表）
**引用频次**：9 次（候选表范围内）

---

## 业务描述

本表是付费广告域的**流量入口（Entry Point）标准映射维表**，维护了 Shopee 平台各流量入口 ID（`entry_point`）与其对应业务标签之间的对应关系，包括入口名称、流量分类（`traffic_type`）、主流量类型（`main_taffic_type`）以及通用特征标签（`common_feature`）等维度信息。该表以 Google Sheets 方式手工维护，由业务团队负责更新，数据工程团队定期将其同步至数仓。

本表是各付费广告分析报表的核心 JOIN 表，下游报表通过关联 `entry_point` 字段，将原始曝光、点击、GMV 等事实数据按流量类型进行分类汇总，支持搜索（Search）、发现（Discovery）、直播（Livestream）、游戏（Game）、品牌（Brand）、视频（Video）、复购推荐（Post Purchase）等多种流量形态的拆分分析。由于下游引用频次高达 9 次，本表是付费广告数仓中**使用频率最高的维度参照基准**之一。

该表覆盖从早期基础入口（如全局搜索、每日发现）到持续迭代新增的入口（如 Shop Private Domain、Video PDP 等新场景），通过 `comment` 字段中的日期标注（如 `20240906_new`）记录各入口的首次上线时间，便于追溯业务演进历史。使用方在进行跨时间维度分析时，需关注历史数据中可能存在的入口缺失情况。

---

## 字段列表

### 维度：主键与入口标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `entry_point` | string | 流量入口 ID，为数字字符串（如 `"1"`、`"25"`），是本表主键，下游通过此字段与事实表 JOIN。⚠️ 存储为 string 类型，JOIN 时需注意事实表中对应字段的类型是否一致，避免隐式转换导致 JOIN 失败或性能下降 |
| `entrance` | string | 入口编号，与 `entry_point` 含义相近，为 Google Sheets 中的原始列，部分记录下两者数值相同；可用于与历史版本维表对齐 |
| `sub_entrance` | string | 子入口编号，当前版本数据中均为空，保留字段，预留用于后续更细粒度入口拆分 |

### 维度：入口名称与分类标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `main_taffic_type` | string | 主流量类型，粗粒度分类，当前取值包括：`Search`（搜索）、`Discovery`（发现）、`Others`（其他）、`Shop`（店铺）。⚠️ 字段名存在拼写错误（`taffic` 而非 `traffic`），下游 SQL 引用时须使用原始拼写 |
| `traffic_type` | string | 细粒度流量类型，取值示例：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`、`Game`、`Livestream`、`Video`、`Brand`、`Promotion Recommendation`、`Shop Private Domain` 等，是流量分类分析的核心字段 |
| `common_feature` | string | 通用特征标签，用于在同一 `traffic_type` 下进一步聚合相似入口，例如多个 Game 入口（entrance 14~43 等）均归属 `"Games"`，多个 Daily Discover 相关入口归属 `"Daily Discover"`。⚠️ 部分新增入口（如 entry_point 52、53、54、55、59、60）此字段为空，聚合时需注意空值处理 |
| `comment` | string | 备注信息，通常记录入口的新增日期（格式 `YYYYMMDD_new`，如 `20240906_new`）或补充说明（如 `item mix feed`），由业务团队手工填写，不保证格式统一。⚠️ 此字段为非结构化文本，不适合用于程序化逻辑判断，仅供人工参考 |

### 维度：元数据

| 字段 | 类型 | 说明 |
|------|------|------|
| `ingestion_timestamp` | string | 数据同步时间戳，记录该条记录从 Google Sheets 摄入数仓的时间，格式为时间戳字符串。⚠️ 此字段反映的是 ETL 写入时间而非业务发生时间，不可用于业务时间筛选；同一批次同步的记录该值相同 |

---

## 查询使用须知

本表为维表，直接 `SELECT` 使用，无聚合场景。下游通常以 `entry_point` 字段与事实表进行 LEFT JOIN，并使用 `traffic_type`、`main_taffic_type`、`common_feature` 等字段对结果进行分组或过滤。JOIN 时注意 `entry_point` 为 string 类型，需与事实表中对应字段类型保持一致；引用 `main_taffic_type` 时注意字段名拼写（`taffic` 非 `traffic`）；`common_feature` 存在空值，聚合时建议使用 `COALESCE(common_feature, traffic_type)` 兜底处理。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets（人工维护表格） | 业务团队手工录入并维护各流量入口的分类映射关系，作为本维表的唯一数据来源 |

---

## ETL 逻辑摘要

### 维表说明

本表为 **Google Sheets 维表**，由付费广告业务团队在共享电子表格中手工维护各流量入口的分类标签信息。数据工程团队通过定期同步任务（Gsheet Ingestion Pipeline）将最新版本的 Sheets 数据读取并写入 Hive 表 `mp_paidads.dim_entry_point_mapping_v2`，同步时会记录 `ingestion_timestamp` 作为写入时间戳。

**内容结构**：每行对应一个唯一的流量入口编号（`entry_point`），记录该入口的展示名称（`entrance` 列对应的业务名称）、子入口（`sub_entrance`）、流量类型分层（`traffic_type` / `main_taffic_type`）、通用特征归组（`common_feature`）及新增备注（`comment`）。同一业务入口名称（如 `Game`、`Shop Private Domain`）可能对应多个不同的 `entry_point` ID，属于正常的一对多映射关系。

**维护规范**：新入口上线时，业务团队在 Sheets 中新增一行，并在 `comment` 列注明新增日期（格式 `YYYYMMDD_new`）；如需废弃某入口，当前版本采用保留记录但不删除的方式，历史入口持续存在于维表中。

### 注意事项

- `main_taffic_type` 字段名存在**拼写错误**（`taffic`），这是 Google Sheets 原始列名的历史遗留问题，下游引用时**必须使用该拼写**，不可自行修正为 `traffic`，否则将导致字段找不到报错。
- 同一 `entry_point` ID 在维表中应唯一，但由于人工维护存在误操作风险，建议下游在 JOIN 前通过 `SELECT entry_point, COUNT(1) FROM mp_paidads.dim_entry_point_mapping_v2 GROUP BY entry_point HAVING COUNT(1) > 1` 校验主键唯一性。
- 新业务入口从实际上线到同步至本维表之间存在**时间差**，期间事实表中的 `entry_point` JOIN 本维表将得到 NULL 值，下游 SQL 中建议使用 `LEFT JOIN` 并对 NULL 情况进行兜底处理。
- `common_feature` 字段在部分较新的入口（entry_point 52、53、54、55、59、60 等）为空，进行以 `common_feature` 为维度的汇总分析时需特别注意空值的影响。

---

*文档生成时间：2026-04-22*