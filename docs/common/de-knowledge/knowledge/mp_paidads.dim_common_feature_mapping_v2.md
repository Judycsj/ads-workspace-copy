<!-- ads-workspace-gdoc-sync: gdoc_id=1nnmLAkQueAZwUJKmhKZw5CiwWR3Cm6aCQaMnobWPa48 gdoc_url=https://docs.google.com/document/d/1nnmLAkQueAZwUJKmhKZw5CiwWR3Cm6aCQaMnobWPa48/edit -->

# mp_paidads.dim_common_feature_mapping_v2

**分层**：DIM（维度层）
**主键**：`entrance`
**分区**：无分区
**更新频率**：按需手工更新（Google Sheets 维表）
**引用频次**：2 次

---

## 业务描述

本表是广告投放分析中用于映射流量入口（`entrance`）与业务场景名称（`common_feature`）的维度映射表，数据来源为人工维护的 Google Sheets。表中记录了 Shopee 平台各类广告流量入口的数字编码与其对应的业务场景语义标签，例如将 `entrance = 1` 映射为 `Global Search`，将 `entrance = 27/28` 映射为 `Live Streaming` 等。

该表主要用于在广告效果分析、BI 看板及下游 ETL 任务中，将原始的数字型入口编码翻译为可读的业务场景名称，从而支持按投放场景（搜索、直播、视频、游戏、推荐位等）对广告绩效进行分类汇总与对比分析。

随着平台持续拓展流量场景（如直播游戏、店铺主页推荐、视频 YMAL 等），本表由业务 Owner 持续扩展维护，是广告数据分析链路中不可缺少的场景元数据基础维表。

---

## 字段列表

### 维度：入口映射核心字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `entrance` | string | 广告流量入口编码，为数字型字符串（如 `"1"`、`"27"`），是本表的业务主键，唯一标识一个广告投放场景入口。⚠️ 同一 `common_feature` 可对应多个 `entrance` 编码（如 `Games` 对应 7、14–22 等多个入口），关联时不可反向以 `common_feature` 作为唯一键使用 |
| `common_feature` | string | 入口对应的业务场景名称（英文），如 `Global Search`、`Live Streaming`、`Daily Discover`、`Video`、`Games` 等，供下游报表及分析使用的可读标签 |
| `update_date` | string | 本条映射记录最近一次在 Google Sheets 中更新的日期（格式 `YYYY-MM-DD`），用于追踪映射关系的版本变更时间。⚠️ 该字段为手工填写，仅反映 Sheets 录入时间，不代表系统数据摄入时间 |
| `remarks` | string | 备注信息，通常记录本次更新的负责人（邮件前缀），部分记录为空。⚠️ 内容格式不固定，仅供人工参考，不建议用于程序逻辑判断 |

### 维度：数据摄入字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `ingestion_timestamp` | string | 数据从 Google Sheets 摄入至数仓的时间戳，由摄入框架自动写入，格式为字符串型时间戳。⚠️ 非业务时间，不代表映射关系的生效时间，仅用于数据新鲜度排查 |

---

## 查询使用须知

本表为维表，直接 `SELECT` 使用，无聚合场景。

> 使用时注意：`common_feature` 与 `entrance` 为一对多关系，若需按场景分组，应以 `common_feature` 分组；若需精确匹配某一入口，应以 `entrance` 关联，避免因多对一关系导致事实表数据重复计算。

---

## 数据来源

| 上游表 / 来源 | 用途 |
|--------------|------|
| Google Sheets（人工维护） | 提供 `entrance` 编码与 `common_feature` 场景名称的映射关系，由业务 Owner 按需录入和更新 |

---

## ETL 逻辑摘要

### 维表说明

本表为 **Google Sheets 维表**，通过 Shopee 数仓的 GSheet 自动摄入框架定期将 Google Sheets 内容同步至 Hive/数仓表中。数据完全由业务人员手工维护，无自动化 ETL 计算逻辑。

**维表内容结构说明：**

- 每行记录一个 `entrance`（入口编码）与 `common_feature`（业务场景名称）的对应关系；
- 同一 `common_feature` 可映射多个 `entrance`（如 `Games` 场景包含 10 个以上入口编码，`Daily Discover` 包含多个不同日期添加的入口）；
- 表中目前共覆盖 **60 余条**入口映射记录，涵盖搜索、推荐、直播、视频、游戏、店铺主页等主要广告流量场景；
- 新增流量场景时，由对应业务 Owner（见 `remarks` 字段）在 Google Sheets 中追加记录，系统定期同步至数仓，`update_date` 记录该次变更日期。

**维护负责方**：广告数据分析团队，历史更新负责人包括 tiantian.xu、jianqiao.ji、ella.yuan、jingzhi.luo、jimmy.lu 等。

### 注意事项

1. **映射完整性**：如下游分析发现新的 `entrance` 编码无法在本表中找到对应的 `common_feature`，说明该入口尚未录入维表，需联系业务 Owner 补录；
2. **一对多关系**：`common_feature → entrance` 为一对多，关联事实表时务必以 `entrance` 作为 JOIN Key，避免笛卡尔积；
3. **数据延迟**：Google Sheets 更新后需等待摄入框架下次调度才能在数仓中生效，若有紧急变更需关注同步延迟；
4. **字段类型**：`entrance` 存储为 string 类型，关联事实表时注意对齐数据类型，避免隐式类型转换导致关联失败。

---

*文档生成时间：2026-04-22*