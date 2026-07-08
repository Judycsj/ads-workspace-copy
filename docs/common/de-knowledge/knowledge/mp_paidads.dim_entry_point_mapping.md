<!-- ads-workspace-gdoc-sync: gdoc_id=1-OLHW4Z7fdRcOgY0a2teXtGcMWFMDVfOz9gkGI09DgU gdoc_url=https://docs.google.com/document/d/1-OLHW4Z7fdRcOgY0a2teXtGcMWFMDVfOz9gkGI09DgU/edit -->

# mp_paidads.dim_entry_point_mapping

**分层**：DIM（维度层）
**主键**：`entry_point` + `entrance` + `sub_entrance`
**分区**：无分区
**更新频率**：手工维护（Google Sheets 同步）
**引用频次**：12 次（候选表范围内）

---

## 业务描述

本表是付费广告域的**流量入口点（Entry Point）映射维表**，用于将广告系统中的原始 `entrance`（入口编码）和 `sub_entrance`（子入口编码）映射到可读的业务标签 `entry_point`，如 Search、Daily Discover、Livestream、Game 等。该表由业务团队在 Google Sheets 中手工维护，并通过数据管道同步至数仓，确保全链路报表对流量入口的口径统一。

在付费广告分析场景中，`entrance` 是广告曝光/点击/转化事件记录的原始维度编码，其数值本身不具备可读性；本表作为解码字典，下游事实表和汇总表通过 JOIN 本表完成入口维度的语义化，是广告流量来源分析、渠道效率对比等核心报表的基础依赖。

本表被下游 12 张候选表引用，属于高频核心维表。任何入口编码的新增、调整或废弃，须同步更新本 Google Sheets，以保证下游报表口径一致性。

---

## 字段列表

### 维度：入口点映射主键与标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `entry_point` | string | 入口点业务名称，如 `Search`、`Daily Discover`、`Livestream For You`、`Game` 等，供报表展示使用 |
| `entrance` | string | 广告入口编码（原始数值型字符串），对应事实表中的 `entrance` 字段，为主要关联键 ⚠️ 同一 `entrance` 可能对应多个 `entry_point`（需结合 `sub_entrance` 区分），关联时须同时使用 `entrance` + `sub_entrance`，否则可能产生扇出或错误映射 |
| `sub_entrance` | string | 子入口编码，用于在同一 `entrance` 下进一步细分流量场景（如 entrance=3 下以 sub_entrance=310103 区分 video mix feed 与 Daily Discover）；无需细分时为空 ⚠️ 空值与非空值共存，JOIN 时需注意空值匹配逻辑，建议使用 `COALESCE(sub_entrance, '')` 统一处理 |
| `comment` | string | 业务备注信息，说明该映射的特殊口径或范围限定，如 `excl. 310103`、`incl. shop ads and search brand ads`、`item mix feed` 等 ⚠️ 仅为人工注释，不参与计算，但反映重要的口径边界，使用前须阅读 |
| `ingestion_timestamp` | string | 数据从 Google Sheets 摄取入仓的时间戳，用于追溯数据同步时间，不代表业务发生时间 ⚠️ 为字符串类型存储，如需时间比较需显式转换 |

---

## 查询使用须知

本表为维表，直接 `SELECT` 或 `JOIN` 使用，无聚合场景。

> **关联注意事项**：由于同一 `entrance` 值可能对应不同 `entry_point`（通过 `sub_entrance` 区分），下游表与本表关联时**必须同时使用 `entrance` 和 `sub_entrance` 两个字段**作为连接条件，避免产生一对多扇出。建议关联写法：
> ```sql
> LEFT JOIN mp_paidads.dim_entry_point_mapping m
>   ON fact.entrance = m.entrance
>   AND COALESCE(fact.sub_entrance, '') = COALESCE(m.sub_entrance, '')
> ```

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets（手工维护） | 业务团队维护的入口编码与业务标签映射关系，通过 Sheets 连接器定期同步至本表 |

---

## ETL 逻辑摘要

### 维表说明

本表为 **Google Sheets 维表**，由付费广告业务团队在线上电子表格中直接维护，无自动化 ETL 转换逻辑。数据内容结构如下：

- **维护方式**：业务/分析团队在 Google Sheets 中手动新增、修改或废弃入口编码行，经数据接入管道（Sheets Connector / 定时同步任务）将最新快照写入本仓库表。
- **内容结构**：每行表示一条入口编码映射规则，由 `entry_point`（业务名称）、`entrance`（入口编码）、`sub_entrance`（子入口编码，可为空）、`comment`（口径备注）四个业务字段组成，`ingestion_timestamp` 由摄取管道自动附加。
- **当前映射范围**：覆盖 Search、Image Search、Video、Daily Discover、Cart Recommendation、Order 相关推荐、You May Also Like、Shop、Shop Game、Game（多个 entrance）、Livestream（Discovery / For You / Homepage / PDP / Autolanding / Video Feed / Game）、Me You May Also Like、Mini Feed Video、Homepage Banner 等主要付费广告流量入口，共约 43 条映射规则。

### 注意事项

1. **口径边界须参考 comment 字段**：部分映射存在包含/排除关系（如 entrance=3 在 sub_entrance=310103 时映射为 `video`，其余映射为 `Daily Discover`），须结合 `comment` 字段理解实际覆盖范围，避免重复统计。
2. **维表变更须通知下游**：如入口编码新增或调整，需同步更新 Google Sheets；由于下游 12 张表均依赖本表，变更后须验证所有下游报表口径是否受影响。
3. **同步延迟**：Google Sheets 到数仓存在同步延迟，`ingestion_timestamp` 可用于判断当前入仓版本时间；如发现下游报表出现未映射的入口（NULL entry_point），应检查 Sheets 是否已补录对应编码。
4. **字段类型**：`entrance` 和 `sub_entrance` 均以字符串类型存储，关联事实表时需确认事实表中对应字段类型一致，必要时显式 CAST。

---

*文档生成时间：2026-04-22*